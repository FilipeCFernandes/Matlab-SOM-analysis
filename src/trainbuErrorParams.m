function [out1,out2] = trainbuErrorParams(varargin)
%TRAINBU Unsupervised batch training with weight & bias learning rules.
%
%  <a href="matlab:doc trainbu">trainbu</a> trains a network with unsupervised weight and bias learning
%  rules with batch updates. The weights and biases are updated at the end
%  of an entire pass through the input data.
%
%  Syntax:
%       net.trainFcn = 'trainbu';
%       [net,tr] = <a href="matlab:doc train">train</a>(net,...)
%
%  Training occurs according to training parameters, listed here with their
%  default values:
%    epochs            1000  Maximum number of epochs to train
%    show                25  Epochs between displays
%    showCommandLine  false  Generate command-line output
%    showWindow        true  Show training GUI
%    time               inf  Maximum time to train in seconds
%
%  To make this the default training function for a network, and view
%  and/or change parameter settings, use these two properties:
%
%    net.<a href="matlab:doc nnproperty.net_trainFcn">trainFcn</a> = 'trainbu';
%    net.<a href="matlab:doc nnproperty.net_trainParam">trainParam</a>
%
%  See also SELFORGMAP, TRAIN.

% Copyright 2007-2021 The MathWorks, Inc.

%% =======================================================
%  BOILERPLATE_START
%  This code is the same for all Training Functions.

if nargin > 0
    [varargin{:}] = convertStringsToChars(varargin{:});
end

persistent INFO;
if isempty(INFO),
    INFO = get_info;
end
nnassert.minargs(nargin,1);
in1 = varargin{1};
if ischar(in1)
    switch (in1)
        case 'info'
            out1 = INFO;
        case 'apply'
            [out1,out2] = train_network(varargin{2:end});
        case 'formatNet'
            out1 = formatNet(varargin{2});
        case 'check_param'
            param = varargin{2};
            err = nntest.param(INFO.parameters,param);
            if isempty(err)
                err = check_param(param);
            end
            if nargout > 0
                out1 = err;
            elseif ~isempty(err)
                nnerr.throw('Type',err);
            end
        otherwise,
            try
                out1 = eval(['INFO.' in1]);
            catch me, nnerr.throw(['Unrecognized first argument: ''' in1 ''''])
            end
    end
else
    net = varargin{1};
    oldTrainFcn = net.trainFcn;
    oldTrainParam = net.trainParam;
    if ~strcmp(net.trainFcn,mfilename)
        net.trainFcn = mfilename;
        net.trainParam = INFO.defaultParam;
    end
    [out1,out2] = train(net,varargin{2:end});
    net.trainFcn = oldTrainFcn;
    net.trainParam = oldTrainParam;
end
end

%  BOILERPLATE_END
%% =======================================================

function info = get_info
isSupervised = false;
usesGradient = false;
usesJacobian = false;
usesValidation = false;
supportsCalcModes = false;
showWindow = ~isdeployed; % showWindow must be false if network is deployed
info = nnfcnTraining(mfilename,getString(message('nnet:NNTrain:TrainbName')),8.0,...
    isSupervised,usesGradient,usesJacobian,usesValidation,supportsCalcModes,...
    [ ...
    nnetParamInfo('showWindow','Show Training Window Feedback','nntype.traintoolmodel_bool_scalar',showWindow,...
    'Display training window during training.'), ...
    nnetParamInfo('showCommandLine','Show Command Line Feedback','nntype.bool_scalar',false,...
    'Generate command line output during training.') ...
    nnetParamInfo('show','Command Line Frequency','nntype.strict_pos_int_inf_scalar',25,...
    'Frequency to update command line.'), ...
    ...
    nnetParamInfo('epochs','Maximum Epochs','nntype.pos_scalar',1000,...
    'Maximum number of training iterations before training is stopped.') ...
    nnetParamInfo('time','Maximum Training Time','nntype.pos_inf_scalar',inf,...
    'Maximum time in seconds before training is stopped.') ...
    ], ...
    []);
end

function err = check_param(param)
err = '';
end

function net = formatNet(net)
end

function [net,tr] = train_network(net,tr,data,options,fcns,param)

%% setup
numLayers = net.numLayers;
numInputs = net.numInputs;
numLayerDelays = net.numLayerDelays;
layer2output = num2cell(cumsum(net.outputConnect));
layer2output(~net.outputConnect) = {[]};

% Signals
BP = ones(1,data.Q);
IWLS = cell(numLayers,numInputs);
LWLS = cell(numLayers,numLayers);
BLS = cell(numLayers,1);

%% Initialize
startTime = clock;
original_net = net;

%% Training Record
tr.best_epoch = 0;
tr.goal = NaN;
tr.states = {'epoch','time'};

%% Status
status = ...
    [ ...
    nntraining.status(iEpochTitle(),iIterationsName(),'linear','discrete',0,param.epochs,0,false), ...
    nntraining.status(iTimeTitle(),iSecondsName(),'linear','discrete',0,param.time,0,false), ...
    ];

feedback = nnet.train.createFeedback(net);

feedback.start(false,data,net,tr,options,status);

% Make sure to remove the TrainToolModel from the network if it has been
% injected
if isa(net.trainParam.showWindow, "nnet.guis.TrainToolModel")
    net.trainParam.showWindow = true;
end

try
    %% Train
    for epoch=0:param.epochs
        
        % Simulation
        data = nn7.y_all(net,data,fcns);
        
        % Stopping Criteria
        current_time = etime(clock,startTime);
        
        [javaUserStop,userCancel] = nntraining.stop_or_cancel();
        userStopped = javaUserStop || feedback.UserStopped;
        
        if userStopped
            tr.stop = message('nnet:trainingStop:UserStop');
        elseif userCancel
            tr.stop = message('nnet:trainingStop:UserCancel');
            net = original_net;
        elseif (epoch == param.epochs)
            tr.stop = message('nnet:trainingStop:MaximumEpochReached');
            idx = iGetIdxOfNameFromStatus(iEpochTitle(), status);
            status(idx).stop = true;
        elseif (current_time > param.time)
            tr.stop = message('nnet:trainingStop:MaximumTimeElapsed');
            idx = iGetIdxOfNameFromStatus(iTimeTitle(), status);
            status(idx).stop = true;
        end
        
        % Training record & feedback
        tr = nnet.trainingRecord.update(tr,[epoch current_time]);
        statusValues = [epoch,current_time];
        
        feedback.update(net,tr,options,data,[],[],net,status,statusValues);
        
        % Stop
        if ~isempty(tr.stop)
            break
        end
        
        % Update with Weight and Bias Learning Functions
        for ts=1:data.TS
            for i=1:numLayers
                
                % Update Input Weight Values
                for j=find(net.inputConnect(i,:))
                    fcn = fcns.inputWeights(i,j).learn;
                    if fcn.exist
                        Pd = nntraining.pd(net,data.Q,data.Pc,data.Pd,i,j,ts);
                        [dw,IWLS{i,j}] = fcn.apply(net.IW{i,j}, ...
                            Pd,data.Zi{i,j},data.N{i},data.Ac{i,ts+numLayerDelays},[],[],[],...
                            [],net.layers{i}.distances,fcn.param,IWLS{i,j});
                        net.IW{i,j} = net.IW{i,j} + dw;
                    end
                end
                
                % Update Layer Weight Values
                for j=find(net.layerConnect(i,:))
                    fcn = fcns.layerWeights(i,j).learn;
                    if fcn.exist
                        Ad = cell2mat(data.Ac(j,ts+numLayerDelays-net.layerWeights{i,j}.delays)');
                        [dw,LWLS{i,j}] = fcn.apply(net.LW{i,j}, ...
                            Ad,data.Zl{i,j},data.N{i},data.Ac{i,ts+numLayerDelays},data.Tl{i,ts},[],[],...
                            [],net.layers{i}.distances,fcn.param,LWLS{i,j});
                        net.LW{i,j} = net.LW{i,j} + dw;
                    end
                end
                
                % Update Bias Values
                if net.biasConnect(i)
                    fcn = fcns.biases(i).learn;
                    if fcn.exist
                        [db,BLS{i}] = fcn.apply(net.b{i}, ...
                            BP,data.Zb{i},data.N{i},data.Ac{i,ts+numLayerDelays},[],[],[],...
                            [],net.layers{i}.distances,fcn.param,BLS{i});
                        net.b{i} = net.b{i} + db;
                    end
                end
            end
        end
    end
    
    % Finish
    tr.best_epoch = param.epochs;
catch ex
    feedback.notifyErrorOccurred();
    rethrow(ex);
end
end

function idxOfName = iGetIdxOfNameFromStatus(name, status)
cellOfNames = {status.name};
idxOfName = cellfun(@(x)any(strcmp(x,name)),cellOfNames);
end


function str = iEpochTitle()
str = getString(message('nnet:NNTrain:EpochTitle'));
end

function str = iTimeTitle()
str = getString(message('nnet:NNTrain:TimeTitle'));
end

function str = iIterationsName()
str = getString(message('nnet:NNTrain:IterationsName'));
end

function str = iSecondsName()
str = getString(message('nnet:NNTrain:SecondsName'));
end
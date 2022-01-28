classdef somStats < handle
%   SOMSTATS are a class that help to plot the errors along the training
%   epochs
% 

  properties
    netName       = []
    path          = []
    netAttributs  = struct('size',       [], ...
                           'dimensions', [], ...
                           'epochs',     [], ...
                           'tau',        [])
    trainingIndex = []
    errors        = struct('topologicError',    [], ...
                           'quantizationError', [], ...
                           'neuronUtilization', [])
    trainingTime  = [];
  end
  
  methods
    function obj = somStats(path, netName, index)
      if isValidParameters(path, netName)
        obj.path = path;        
        obj.netName = netName;
        obj.trainingIndex = index;
        
        obj.setNetAttributs();
        obj.setErros();
      else 
        error('No file %s find in path %s', netName, path)
      end
    end
    
    function bol = lt(obj,other)
      
      bol = false;
      [ehIgual, equalParam] = objEquality(obj, other);
      if ehIgual & obj.trainingIndex ~= other.trainingIndex
        bol = obj.trainingIndex < other.trainingIndex;
      elseif ~ehIgual
        if ~isTheSameSize(obj, other)
          bol = obj.netAttributs.size < other.netAttributs.size;
        elseif ~isTheSameEpoch(obj,other)
          bol = obj.netAttributs.epochs < other.netAttributs.epochs;
        
        elseif ~isTheSameTau(obj, other)
          bol = obj.netAttributs.tau < other.netAttributs.tau;
        end
      end
    end

    function bol = eq(obj, other)
%   Overload the equal == operator 

      bol = objEquality(obj, other);
    end

    function [net, tr] = loadNet(obj)
%   LOADNET load the network in path/netName
%   It will load the net and te tr variables 

      trainingVariable = load(fullfile(obj.path, obj.netName));
      net = trainingVariable.net;
      tr = trainingVariable.tr;      
    end
    
    function plotTopologicError(obj, varargin)
%   PLOTTOPOLOGICERROR plot the topologic error to the obj
% 

      obj.lackOfVariablesWarning(obj.errors.topologicError, ...
                                 'Topological Error')
      
      fig = isThereAFigure(varargin{:})

      obj.plotError(obj.errors.topologicError, 'Topological Error', ...
                    'Topological error', fig)
    end
    
    function plotQuantizationError(obj, varargin)
%   PLOTQUANTIZATIONERROR  as the name says, this function plots the
%   quantization error. 
% 
      obj.lackOfVariablesWarning(obj.errors.quantizationError, ...
                                 'Quantization error')
      
      fig = isThereAFigure(varargin{:})

      obj.plotError(obj.errors.quantizationError, 'Quantization Error', ...
                    'Quantization error', fig)
    end
    
    function plotNeuronUtilization(obj, varargin)

      obj.lackOfVariablesWarning(obj.errors.neuronUtilization, 'Neuron utilization')
      
      fig = isThereAFigure(varargin{:})

      obj.plotError(obj.errors.quantizationError, 'Quantization Error', ...
                    'Quantization error', fig)
    end 
    

  end

  methods(Access = protected)
    function lackOfVariablesWarning(obj, variable, variableName)
%   LACKOFVARIABLESWARNING It will warning if one of the errors array is
%   missing every time the operator try to plot this error.

      if isempty(variable)
        error('There is no %s in this object', variableName)
      end
    end
    
    function plotError(obj, err, titleStr, errorType, fig)
      if isempty(fig)  
          fig = figure(); 
      end
      
      set(0, 'CurrentFigure', fig)

      plot(err, 'lineWidth', 2)
      title(titleStr)
      xlabel('epochs')
      ylabel(errorType)
    end
    
    function setNetAttributs(obj)
      [net, ~] = obj.loadNet();
      
      obj.netAttributs.size        = net.layers{:}.size;
      obj.netAttributs.dimensions  = [net.layers{:}.dimensions];
      obj.netAttributs.epochs      = net.trainParam.epochs;
      obj.netAttributs.tau         = net.inputWeights{:}.learnParam.steps;
      
    end
    
    function setErros(obj)
      [~, tr] = obj.loadNet();
      obj.errors.topologicError = tr.Te;
      obj.errors.quantizationError = tr.QE;
      if isfield(tr,'Nu') obj.errors.neuronUtilization = tr.Nu; end
      obj.trainingTime = tr.time(end);
    end
  end
end


function out = isValidParameters(path, netName)
% ISVALIDPARAMETERS very if the input parameters are valid parameters. this
% function will return true if the parameters are valid or false if ther
% are not.
  if isempty(path)
    error('Variable path is missing')
  elseif isempty(netName)
    error('Variable netName is missing')
  end

  out =  existFolder(path) && existFileInFolder(path,netName);

end

function out = existFolder(path)    
% EXISTFOLDER is a function that checks if the path is valid
  out = exist(path) == 7;
end

function out = existFileInFolder(path, netName)
% EXUSTFILEINFOLER is a function that checks if the netName are a file. It
% not checks if is a mat file or if is a network file. 

  out = exist(fullfile(path, netName)) == 2;
end

function fig = isThereAFigure(varargin)
    if length(varargin) == 1 & isa(varargin{:}, 'handle')
        fig = varargin{:};
    else
        fig = [];
    end
end

%% Verifications 
function bol = isTheSameSize(obj, other)
  bol = obj.netAttributs.size == other.netAttributs.size;
end

function bol = isTheSameDimension(obj, other)
  bol = length( find((obj.netAttributs.dimensions == other.netAttributs.dimensions)...
        == 1)) == 2;
end

function bol = isTheSameEpoch(obj, other)
  bol = obj.netAttributs.epochs == other.netAttributs.epochs;
end

function bol = isTheSameTau(obj, other)
  bol = obj.netAttributs.tau == other.netAttributs.tau;
end

function varargout = objEquality(obj, other)
      
%     Verify if this two objects have the same size
      bolSize = isTheSameSize(obj, other);
      
%     Verify if this two objects have the same dimenssion
%       bolDimension = isTheSameDimension(obj, other);

%     Verify if this two objects have the same epoch
      bolEpochs = isTheSameEpoch(obj, other);

%     Verify if this two objects have the same tau
      bolTau = isTheSameTau(obj, other);

%     Two objecs can only be the save if they match all the preview
%     verifications
%       bol = bolSize & bolDimension & bolEpochs & bolTau;
      bol = bolSize & bolEpochs & bolTau;

      if nargout == 1
        varargout = {bol};
      else
%         varargout = {bol [bolSize, bolDimension, bolEpochs, bolTau]};
        varargout = {bol [bolSize, bolEpochs, bolTau]};
      end
end













classdef groupAnalysis < handle
  
  properties
    date    
    nets    
    bestNet 
    trainPath
    errors = struct('topologicalError',  [], ...
                    'quantizationError', [], ...
                    'neuronUtilization', [], ...
                    'errorProd',         [])
  end

  methods
    function obj = groupAnalysis(date,index)

      dateString = datestr(datetime(date));
      if isempty(index)
        trainPath = fullfile('..',"resultados",dateString);
      else
        trainPath = fullfile('..',"resultados",[dateString '_' num2str(index)]);
      end

      obj.date = dateString;
      obj.trainPath = trainPath;
      obj.loadNets;
      obj.setBestNet;
    end

  end
  methods(Access = protected)
    function loadNets(obj)
      rootPath = fullfile(obj.trainPath, 'Nets');
      files = dir(fullfile(rootPath, '*.mat'));
      cont = 1;
      splited = split(files(1).name, '_');
      obj.nets = somStats(rootPath, files(1).name, str2num(splited{2}));
      for fileName = {files.name}
        splited = split(fileName{:}, '_');
        obj.nets(cont) = somStats(rootPath, fileName{:}, str2num(splited{2}));
        cont = cont + 1;
      end
      obj.nets = quicksort(obj.nets);
    end
    
    function setBestNet(obj)
      net = obj.nets;
      for n = 1:length(net)
        topologicalError(n) = net(n).errors.topologicError(end);
        quantizationError(n) = net(n).errors.quantizationError(end);
        neuronUtilization(n) = net(n).errors.neuronUtilization(end);
        errorProd(n) = net(n).errors.prodErr;         
      end
      obj.errors.topologicalError  = topologicalError;
      obj.errors.quantizationError = quantizationError;
      obj.errors.neuronUtilization = neuronUtilization;
      obj.errors.errorProd = errorProd;
      obj.bestNet = obj.nets(find(errorProd == min(errorProd)));
    end
    
%     function quickSort(obj)
%       obj = quicksort(obj);
%     end
  end

  methods
    function bol = lt(obj,other)
      bol = obj.nets(end) < other.nets(end);
    end
    
    function bol = gt(obj,other)
      bol = obj.nets(end) > other.nets(end);
    end

    function bol = eq(obj, other)
      bol = obj.nets(end) == other.nets(end);
    end
    
    function bol = le(obj, other)
      bol = obj.nets(end) <= other.nets(end);
    end
    
    function bol = ge(obj, other)
      bol = obj.nets(end) >= other.nets(end);
    end

    function bol = ne(obj, other)
      bol = obj.nets(end) ~= other.nets(end);
    end

  end

end

function out = permuta(arr, ind1, ind2)
  var = arr(ind1);
  arr(ind1) = arr(ind2);
  arr(ind2) = var;
  out = arr;
end

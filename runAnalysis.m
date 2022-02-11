% Comaração entre diferentes redes 
cd('/home/fernandes/Documentos/PPGEE/prpd/Matlab-SOM-analysis')
addpath('src/')

redesASeremAnalisadas = {{[2022 01 29] []}
                         {[2022 01 20] []}
                         {[2022 01 29] [1]}
                         {[2022 01 29] [2]}
                         {[2022 01 30] []}
                         {[2022 01 30] [1]}
                         {[2022 01 31] []}
                         {[2022 02  1] []}
                         {[2022 02  2] []}
                         {[2022 02  3] []}
                         {[2021 12 03] []}};

for n = 1 : length(redesASeremAnalisadas)
  disp(redesASeremAnalisadas{n}{1})
  obj(n) = groupAnalysis(redesASeremAnalisadas{n}{1}, ...
                         redesASeremAnalisadas{n}{2});
  Te(n,:) = obj(n).errors.topologicalError;
  Qe(n,:) = obj(n).errors.quantizationError;
  U(n,:)  = obj(n).errors.neuronUtilization;
end

%% 










% Add JIDT jar library to the path, and disable warnings that it's already there:
warning('off','MATLAB:Java:DuplicateClass');
javaaddpath('/Volumes/homes/DevilbissLab/SourceCode/Cerridwen/ExternalToolBoxes/infodynamics/infodynamics.jar');
% Add utilities to the path
addpath('/Volumes/homes/DevilbissLab/SourceCode/Cerridwen/ExternalToolBoxes/infodynamics/demos/octave');

% 0. Load/prepare the data:
data = load('/Volumes/homes/DevilbissLab/SourceCode/Cerridwen/ExternalToolBoxes/infodynamics/demos/AutoAnalyser/../data/SFI-heartRate_breathVol_bloodOx-extract.txt');
% Column indices start from 1 in Matlab:
source = octaveToJavaDoubleArray(data(:,1));
destination = octaveToJavaDoubleArray(data(:,1));

% 1. Construct the calculator:
calc = javaObject('infodynamics.measures.continuous.kraskov.TransferEntropyCalculatorKraskov');
% 2. Set any properties to non-default values:
calc.setProperty('DELAY', '2');
% 3. Initialise the calculator for (re-)use:
calc.initialise();
% 4. Supply the sample data:
calc.setObservations(source, destination);
% 5. Compute the estimate:
result = calc.computeAverageLocalOfObservations();

fprintf('TE_Kraskov (KSG)(col_0 -> col_0) = %.4f nats\n', ...
	result);

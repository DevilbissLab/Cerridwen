function parms = NSB_ParameterFile()
% NSB_ParameterFile() - Parameter file for all NSB software
%
% Inputs: none
%
% Outputs:
%   parms               - (struct) parameter Structure
%
% ToDo: May store db credentials in mat file
%
% Written By David M. Devilbiss
% NexStep Biomarkers, LLC. (info@nexstepbiomarkers.com)
% Febuary 27 2012, Version 0.87 First Beta Release (Biogen Idec Recieved this)
% Febuary 29 2012, Version 0.88 Fixes in DSI reader and optimization of Artifact detection code
% March 3 2012, Version 0.89 Fixes in Spectral output Band and ratio calculation, added DSI GMT offset.
% March 18 2012, Version 0.90 Fixes in Spectral analysis and Dynamic Parameter Gui
% March 30 2012, Version 0.91-0.95 Addition of Sleep Scoring and prelim EDF writer
% April 1 2012, Version 0.96 DynGui Features requested by Biogen
% April 20 2012, Version 1.01 Final release and more DynGui Features requested by Biogen
% April 23 2012, Version 1.02-1.03 Bug Fixes across the board (DynGui labeling, heatmap, artifact detection plot colors)
% April 24 2012, Version 1.04 added EDF writer
% April 25 2012, Version 1.05 1) Two major fixes in code Spectral analysis now
%                   has hidden feature to ignore DC component, handles fractional
%                   frequendies, uses 10x frequency resolution for FFT then de resolves. 2)
%                   normalization now ignores DC component.
% April 29 2012, Version 1.06 forced all spectral output to exponential notation
% May 2 2012, Version 1.07 Numerous bug fixes, Gui resetting artifact
% detection, asthetic issues with GUI, etc.
% July 29 2012, version 1.08 TDTR writes data files using entire path as
% subject ID and will cause components to fail. Fixed issues by eliminating
% special characters in edf reader.
% August 31 2012 ver. 1.09 BioBook export and excel is based on 1900 date
% system wheras std output is based on 0-Jan-0000 as pivot date
% Oct 5th 2012 ver. 1.091 Added debugging to address 32 bit MCR 7.14 issues
% Nov 14 2012 ver 1.10 Added more logging and addressed time stamp issues
% with DSI files and Biobook output
% Dec 09 2012 ver 1.11 Added new Parm Gui and allowed save before dynamic
% toolbox
% January 10 2013 ver 1.20 Changed Licencing Structure.
% Febuary 10 2013 ver 1.25 Added fif importer
% Febuary 25 2013 ver 1.26 Number of bug fixes (see Release notes)
% March 10 2013 ver 1.27 FIF import selection Auto and Manual Windowing and Number of bug fixes (see Release notes)
% March 10 2013 ver 1.28 Quick fix dealing with import of old .xml parameter files and 2012a guide crap
% March 10 2013 ver 1.29 Number of bug fixes (see Release notes)
% April 15 2013 ver 1.3x Added Map FIF file channel locations and re-Reference to a particular Channel
% April 15 2013 ver 1.40 Added Statistical Table Generation
% April 20 2013 ver 1.41 Fix for "Analysis Channel" column header or
% nonexistant animal/Subject ID in study design xls
% June 6 2013 ver 1.43 Fix for Stats table failing when no sleep scoring
% was performed
% ver 1.5
% Oct 9 2013 ver 1.51 added GUI
% June 19 2014 ver 1.54
% Sept 04 2015 ver 1.55 Merged changes over last year (minimal)
% Sept 29 2015 ver 1.60 Updated ParameterGui XML save
% Nov 15 2016 ver 1.70 Updated EDF reader and compiled against 2014b
% Nov 30 2016 ver 1.71 Added pre RMS threshold to artifact detection to weed  out spuroius large artifacts
% Feb 28 2017 ver 2.00 Updated to handle Matlab2016 (9.1.0) Ths includes TinyXML2
% July 19 2017 ver 2.10 Finished adding GUI interface for Seizure module,
% data resampling, and referencing. Added more user friendly canceling of analyses. Multiple bug fixes. 
% Added ICELUS and Blackrock importer, validated EDF exporter, Handles deployeddata directory better and allws user to 
% select output directory.
% July 22 2017 ver 2.11 Bug Fixes in Blackrock importer and in Sleep scoring modules.
% July 22 2017 ver 2.12 , updated GUI image, fixed potential bug in EDF writer.
% July 26 2017 ver 2.20. Updated EDF writer and EDF+ writer (still Issues). Added debuggin in NSReader, added more information to 
%  Software updater, Updated Param editorGUI, Reworked NS emulated Sleep Scoring.
% July 26 2017 ver 2.21. Updated Temporary Licensing Logic, Fixed bug in Import Module, forced SubjectID to be filename in ns2 files.
% August 7 2017 ver 2.22 Added Debugging to XMLload, Added PGI DecisionTree signal envelope signal feature
% April 20 2021 ver 3.00 Codebase brought into DevilbissLab at Rowan and will be further developed v2.22
% April 27 2021 ver 3.01 Small bug fixes with figure naming and file naming
% June 14 2022 ver 3.02 Fixed LIMS issue with file specific parameters
% Feb 13 2024 ver 3.10 Forcing signal detrend before artifact detection. Started to cleanup code and parameter handling.
%
%
% NSB Data Format
%
% DataStruct.Client = 'Client Name'
% DataStruct.DataFormatVersion = 101
% DataStruct.Comment = ''
% DataStruct.RecordingDates(1).Date = '12Nov2011'
% DataStruct.RecordingDates(1).Animal.ID = 'TM124'
% DataStruct.RecordingDates(1).Animal(1).Manipulation(1).Name = 'Baseline'
% DataStruct.RecordingDates(1).Animal(1).Manipulation(1).RecordingStartTime = '12:00:00.0000'
% DataStruct.RecordingDates(1).Animal(1).Manipulation(1).Channel(1).Name = 'EEG1'
% DataStruct.RecordingDates(1).Animal(1).Manipulation(1).Channel(1).Fs = 1000 %samples per second
% DataStruct.RecordingDates(1).Animal(1).Manipulation(1).Channel(1).nTrials = 'EEG1'
% DataStruct.RecordingDates(1).Animal(1).Manipulation(1).Channel(1).Trial.n = 1
% DataStruct.RecordingDates(1).Animal(1).Manipulation(1).Channel(1).Trial.Data = [1:1000]

%DataStruct.FunctionalGroup.Compound.StudyID.Manipulation(curfile)

% NSB file Structure
%
%Root_Data_Dir
%   Client/Company
%       FunctionalGroup/subclient
%           Project/compound
%               StudyID (unique)
%                   Manipulation/Dose
%                      Date(can be missing)
%                        Animal (as part of filename)
% So this will be compatable with DSI file Format (N4ETS2Rat45016.1191) as
% well as EDF and other file formats
% we will also know who is in each group

%% DataSpider Parameters 
parms.DataSpider.GUI.Title = 'DevilbissLab Data Spider v.0.1';
parms.DataSpider.GUI.Licence = 'DMD';
parms.DataSpider.StartDirs = {'C:\Data'}; %,'S:\Temp\CeroraDecrypt'};
parms.DataSpider.PollPeriod = 10; %Seconds
parms.DataSpider.curDir = cd; %<< Maynot work in compiled function
parms.DataSpider.dbFN = 'NSB_AnalysisDatabase.xml';
parms.DataSpider.XMLdbFile = fullfile(parms.DataSpider.curDir,parms.DataSpider.dbFN);
parms.DataSpider.HIPAA.ScrubIDinfo = true;
parms.DataSpider.HIPAA.ShredPartial = true;

%% PreclinicalFramework Parameters 
parms.PreClinicalFramework.Name = 'Cerridwen EEG Framework';
parms.PreClinicalFramework.Version = 'v.3.10';
parms.PreClinicalFramework.MatlabVersion = version;
parms.PreClinicalFramework.HomeDir = cd; %Where is this exe (or working dir) located
if isdeployed
    parms.PreClinicalFramework.OutputDir = 'C:\NexStepBiomarkers\AnalysesResults';
    if exist(parms.PreClinicalFramework.OutputDir,'dir') ~= 7
        mkdir(parms.PreClinicalFramework.OutputDir);
    end
else
    parms.PreClinicalFramework.OutputDir = parms.PreClinicalFramework.HomeDir;
end
parms.PreClinicalFramework.LogFile = fullfile(parms.PreClinicalFramework.OutputDir,['LOG',num2str(now),'.log']);
parms.PreClinicalFramework.useWaitBar = true;
parms.PreClinicalFramework.StatusLines = 19;
parms.PreClinicalFramework.XLSoutput = false;
parms.PreClinicalFramework.BioBookoutput = true;

curMatVersion = regexp(version,'\s','split'); curMatVersion = cellfun(@str2num,regexp(curMatVersion{1},'\.','split') );
if any(curMatVersion >= [8,4,0,150421])
    parms.PreClinicalFramework.MatlabPost2014 = true;
else
    parms.PreClinicalFramework.MatlabPost2014 = false;
end

%Filetype specific parameters
parms.PreClinicalFramework.File.DSIoffset = 0; %GMT offset for DSI data
parms.PreClinicalFramework.File.FIFtype = 'All'; %Data type to import from fif
parms.PreClinicalFramework.File.FIF.ChanLocFiles_Dir = fullfile(parms.PreClinicalFramework.HomeDir,'ChanLocFiles');
parms.PreClinicalFramework.File.FIF.assumeTemplateChOrderCorrect = false;
parms.PreClinicalFramework.File.FIF.showHeadPlot = false;

%Referencing specific parameters
parms.PreClinicalFramework.Reference.doReRef = false;
parms.PreClinicalFramework.Reference.ReRefAlgorithm = 'None';
parms.PreClinicalFramework.Reference.ReRefChan = '';

%Resampling specific parameters
parms.PreClinicalFramework.Resample.doResample = true;
parms.PreClinicalFramework.Resample.newSampleRate = 250; %Hz
parms.PreClinicalFramework.Resample.InterpSamples = 50; 
parms.PreClinicalFramework.Resample.Detrend = true;

%StatsTable specific parameters
parms.PreClinicalFramework.StatsTable.doMeanBaseline = false;
parms.PreClinicalFramework.StatsTable.BaselineMeanTimeStart = [];
parms.PreClinicalFramework.StatsTable.BaselineMeanTimeEnd = [];

% Artifact Detection default parameters
parms.PreClinicalFramework.ArtifactDetection.SampleRate = 100;
parms.PreClinicalFramework.ArtifactDetection.IndexedOutput = true;
parms.PreClinicalFramework.ArtifactDetection.algorithm = 'FULL';
parms.PreClinicalFramework.ArtifactDetection.logfile = '';
parms.PreClinicalFramework.ArtifactDetection.DCvalue = 100; %mV DC hard limit
parms.PreClinicalFramework.ArtifactDetection.RMSMultiplier = 5; %Detect > X times RMS;(Default 5)
parms.PreClinicalFramework.ArtifactDetection.rm2Zero = true;
parms.PreClinicalFramework.ArtifactDetection.plot = false;
parms.PreClinicalFramework.ArtifactDetection.full.DCcalculation = 'scaled'; %mv (DC hard limit) or std calculation
parms.PreClinicalFramework.ArtifactDetection.full.DCvalue = 100; %mV DC hard limit
parms.PreClinicalFramework.ArtifactDetection.full.STDMultiplier = 1.67; %Detect > X times Standard deviations.
parms.PreClinicalFramework.ArtifactDetection.full.minFlatSigLength = 0.1; %Seconds.
parms.PreClinicalFramework.ArtifactDetection.full.dvValMultiplier = .8; %Original 0.45%Jump DC limit as a function of: dvValMultiplier*DClimitValue or std(signal) << this wants to be a fraction of DC Threshold
parms.PreClinicalFramework.ArtifactDetection.full.MaxDT = 4; %Maximum duration (change in time (samples)) that it takes signal to artifact
parms.PreClinicalFramework.ArtifactDetection.full.MinArtifactDuration = 0.25; % in seconds >>>  code will expand all artifacts to have at least this length
parms.PreClinicalFramework.ArtifactDetection.full.CombineArtifactTimeThreshold = 0.2; %in Seconds. Combine artifacts that occur less than this time window
parms.PreClinicalFramework.ArtifactDetection.full.MuscleArtifactMultiplier = 3; %gain for EMGThreshold as a function of options.full.STDMultiplier * options.full.dvValMultiplier + medFiltData *3;

%SeizureAnalysis default parameters
parms.PreClinicalFramework.SeizureAnalysis.RMSMultiplier = 35;    %25 (TSA) Multiplier for RMS (dmd changed from 10 on 2014Jul16)
parms.PreClinicalFramework.SeizureAnalysis.plot = true;

parms.PreClinicalFramework.SeizureAnalysis.filter.persist = true;  %(false) Make filter persistent %%
parms.PreClinicalFramework.SeizureAnalysis.filter.Fstop1 = 9;    % First Stopband Frequency
parms.PreClinicalFramework.SeizureAnalysis.filter.Fpass1 = 10;    % First Passband Frequency
parms.PreClinicalFramework.SeizureAnalysis.filter.Fpass2 = 40;   % Second Passband Frequency
parms.PreClinicalFramework.SeizureAnalysis.filter.Fstop2 = 50;   % Second Stopband Frequency
parms.PreClinicalFramework.SeizureAnalysis.filter.Astop1 = 50;  % First Stopband Attenuation (dB)
parms.PreClinicalFramework.SeizureAnalysis.filter.Apass  = 1;    % Passband Ripple (dB) %%
parms.PreClinicalFramework.SeizureAnalysis.filter.Astop2 = 50;  % Second Stopband Attenuation (dB)
parms.PreClinicalFramework.SeizureAnalysis.detector.Hzlow = 4.5;    % in Hz
parms.PreClinicalFramework.SeizureAnalysis.detector.Hzhigh = 80;   % in Hz
parms.PreClinicalFramework.SeizureAnalysis.detector.minSpikeInt = 0.05; %in sec
parms.PreClinicalFramework.SeizureAnalysis.detector.maxSpikeInt = 0.750; %in sec 0.5
parms.PreClinicalFramework.SeizureAnalysis.detector.minTrainDur = 10; %(3) in sec 0.4
parms.PreClinicalFramework.SeizureAnalysis.detector.minTrainGap = 10; %(5) in sec
parms.PreClinicalFramework.SeizureAnalysis.detector.minSpikes = 10; %in sec 2

parms.PreClinicalFramework.SeizureAnalysis.doSeizureReport = true;
if isdeployed
    parms.PreClinicalFramework.SeizureAnalysis.SeizureReport_Template = fullfile(parms.PreClinicalFramework.HomeDir,'Templates','SeizureReport_Template.doc');
else
    parms.PreClinicalFramework.SeizureAnalysis.SeizureReport_Template = 'X:\NSB_AnalyticFramework\ObjectCode\InstallerFiles\Templates\SeizureReport_Template.doc';
end

%SpectralAnalysis default parameters
parms.PreClinicalFramework.SpectralAnalysis.SPTmethod = 'FFT'; %{mtm,welch,FFT}
parms.PreClinicalFramework.SpectralAnalysis.WindowType = 'Hamming'; % can be {'none',Hamming, Hann, Blackman}
parms.PreClinicalFramework.SpectralAnalysis.FinalFreqResolution = 1.0; %in Hz
parms.PreClinicalFramework.SpectralAnalysis.FinalTimeResolution = 10; %in seconds
parms.PreClinicalFramework.SpectralAnalysis.nanMean = false; %Use nanMean instead of nanSum 
%parms.PreClinicalFramework.SpectralAnalysis.Freqs = []; % vector of frequencies to return
parms.PreClinicalFramework.SpectralAnalysis.FFTWindowSizeMethod = 'Manual';
parms.PreClinicalFramework.SpectralAnalysis.FFTWindowSize = 10; %Change Mar 1 2013 from []. %in seconds divide into 8 segments
parms.PreClinicalFramework.SpectralAnalysis.FFTWindowOverlap = []; %percent (default (50%))
parms.PreClinicalFramework.SpectralAnalysis.TimeBW = 4;
parms.PreClinicalFramework.SpectralAnalysis.SpectralBands(1).Start = 0.5;
parms.PreClinicalFramework.SpectralAnalysis.SpectralBands(1).Stop = 4;
parms.PreClinicalFramework.SpectralAnalysis.SpectralBands(2).Start = 5;
parms.PreClinicalFramework.SpectralAnalysis.SpectralBands(2).Stop = 8;
parms.PreClinicalFramework.SpectralAnalysis.SpectralBands(3).Start = 9;
parms.PreClinicalFramework.SpectralAnalysis.SpectralBands(3).Stop = 12;
parms.PreClinicalFramework.SpectralAnalysis.SpectralBands(4).Start = 15;
parms.PreClinicalFramework.SpectralAnalysis.SpectralBands(4).Stop = 30;
parms.PreClinicalFramework.SpectralAnalysis.SpectralBands(5).Start = 31;
parms.PreClinicalFramework.SpectralAnalysis.SpectralBands(5).Stop = 40;

parms.PreClinicalFramework.SpectralAnalysis.SpectralRatio(1).num = 1;
parms.PreClinicalFramework.SpectralAnalysis.SpectralRatio(1).den = NaN;
parms.PreClinicalFramework.SpectralAnalysis.SpectralRatio(2).num = 2;
parms.PreClinicalFramework.SpectralAnalysis.SpectralRatio(2).den = NaN;
parms.PreClinicalFramework.SpectralAnalysis.SpectralRatio(3).num = 3;
parms.PreClinicalFramework.SpectralAnalysis.SpectralRatio(3).den = NaN;
parms.PreClinicalFramework.SpectralAnalysis.SpectralRatio(4).num = 4;
parms.PreClinicalFramework.SpectralAnalysis.SpectralRatio(4).den = NaN;
parms.PreClinicalFramework.SpectralAnalysis.SpectralRatio(5).num = 5;
parms.PreClinicalFramework.SpectralAnalysis.SpectralRatio(5).den = NaN;

parms.PreClinicalFramework.SpectralAnalysis.normSpectaTotalPower = true;
parms.PreClinicalFramework.SpectralAnalysis.nanDC = true; %This is for future expansion. is still hardcoded in DynamicParameterGUI

%SleepScore Detection Parameters
parms.PreClinicalFramework.Scoring.ScoringType = 'GMMLOGSPECTRUM'; %{'Delta','DECISIONTREE','ICA','GMMRatio','GMMlogSpectrum'}
parms.PreClinicalFramework.Scoring.force5GMMclusters = false; %if using GMM then it forces 5 clusters 
parms.PreClinicalFramework.Scoring.FFTEpoch = 0.5; %0.5  used as Seconds to score data Sleep score interval %Ning Leng Changes it to 6
parms.PreClinicalFramework.Scoring.WinOffset = 0; % as Seconds for sliding window/FFT overlap 
parms.PreClinicalFramework.Scoring.HzDiv = 0.5; %Hz divisions/bins in spectrum. Slightly slower than nexpow2 but we know what each bin is
parms.PreClinicalFramework.Scoring.useGlobalEpoch = true;
parms.PreClinicalFramework.Scoring.StageEpoch = 30; % 5, 10 (Seconds) Final sleep Stage output 
parms.PreClinicalFramework.Scoring.zDeltaThreshold = 0.1; %used for Delta scoring (This is the alpha of the signal power: i.e. 0.05)
%parms.PreClinicalFramework.Scoring.minStateLength = 1;
%parms.PreClinicalFramework.Scoring.maxStateAnnealDist = 0.0033; %<< not used
parms.PreClinicalFramework.Scoring.FFTvalidData = 50; % Cutoff for percent of cvalid data after artifacts removed
parms.PreClinicalFramework.Scoring.plot = false; %[default off]
parms.PreClinicalFramework.Scoring.doSomnogramReport = false;
if isdeployed
    parms.PreClinicalFramework.Scoring.SomnogramReport_Template = fullfile(parms.PreClinicalFramework.HomeDir,'Templates','HypnogramReport_Template.doc');
else
    parms.PreClinicalFramework.Scoring.SomnogramReport_Template = 'X:\NSB_AnalyticFramework\ObjectCode\InstallerFiles\Templates\HypnogramReport_Template.doc';
end
% SleepScore Logical Rules
parms.PreClinicalFramework.rules.ApplyArchitectureRules = false; %<< Something funky here
parms.PreClinicalFramework.rules.SWS2.PercentOfStageEpoch = 45; %>= percent of FFTEpocs to be scored in a Stage Epoch to be called SWS2
parms.PreClinicalFramework.rules.SWS1.PercentOfStageEpoch = 30; 
parms.PreClinicalFramework.rules.QW.PercentOfStageEpoch = 60; 
parms.PreClinicalFramework.rules.AW.PercentOfStageEpoch = 80; 
parms.PreClinicalFramework.rules.PS.PercentOfStageEpoch = 80; 
parms.PreClinicalFramework.rules.UNK.PercentOfStageEpoch = 80;
parms.PreClinicalFramework.rules.minStateLength = 10; %(seconds) this is rounded to the nearest parms.PreClinicalFramework.Scoring.StageEpoch

% GMM starting point 
parms.PreClinicalFramework.Scoring.useGMMinit = false;
parms.PreClinicalFramework.Scoring.GMMinit.mu = [0.00802268820916561,0.0114622729146903,0.0105372978208205,0.00633325276537176,0.00245281481355860,0.000898388901829252,0.000344317457898417,8.19093289475575e-05,2.77466542131724e-05;0.00612710215919150,0.00842113360997373,0.00741269537558056,0.00506371167533013,0.00263993952476115,0.00141476201202206,0.000518775749153345,0.000122638853652757,3.36616207792511e-05;0.00387572956534682,0.00550674951897079,0.00528816437703585,0.00370719098924763,0.00184967109074868,0.000596894200262122,0.000244287900238998,7.90518400876359e-05,2.75418068501420e-05;0.00302181133604580,0.00383043507728869,0.00283533226572688,0.00143266216765922,0.000821879016943202,0.000549130748059079,0.000291073199862022,8.15262531437940e-05,3.03672612551106e-05;0.00142023316734775,0.00152633650467722,0.00120564378855674,0.000763197666309891,0.000444202422621778,0.000224641670804853,0.000127498966129053,7.15812342263568e-05,3.30426645292311e-05;];
parms.PreClinicalFramework.Scoring.GMMinit.Sigma(:,:,1) = [8.49134570309226e-06,8.79247259830608e-06,5.63239973225528e-06,1.88337208897390e-06,2.12258789120385e-07,-4.46183307295150e-08,-3.74286319541469e-08,-1.83353708258278e-08,-6.50723895430486e-09;8.79247259830608e-06,1.39843975500343e-05,1.26457347474393e-05,5.65599972112293e-06,6.24326229527427e-07,5.33245879872988e-08,2.45317627605678e-08,-2.70880097127942e-10,-7.79796414772792e-09;5.63239973225528e-06,1.26457347474393e-05,1.47077101518528e-05,8.56423578463074e-06,1.18494751442821e-06,2.47619313661288e-07,9.33697917988097e-08,2.05657796579360e-08,-4.27522483087467e-09;1.88337208897390e-06,5.65599972112293e-06,8.56423578463074e-06,6.88879074461757e-06,1.34515130431724e-06,3.14278113357813e-07,8.10974345956598e-08,1.80626432768132e-08,2.15529507338017e-10;2.12258789120385e-07,6.24326229527427e-07,1.18494751442821e-06,1.34515130431724e-06,5.86392234180100e-07,1.24165347397166e-07,2.51097452307202e-08,3.88360723034101e-09,6.11508280223123e-10;-4.46183307295150e-08,5.33245879872988e-08,2.47619313661288e-07,3.14278113357813e-07,1.24165347397166e-07,7.05537715918140e-08,2.07160288048118e-08,3.36837105702531e-09,3.58090445393848e-10;-3.74286319541469e-08,2.45317627605678e-08,9.33697917988097e-08,8.10974345956598e-08,2.51097452307202e-08,2.07160288048118e-08,1.58045996710376e-08,2.10644818576211e-09,2.36058743960409e-10;-1.83353708258278e-08,-2.70880097127942e-10,2.05657796579360e-08,1.80626432768132e-08,3.88360723034101e-09,3.36837105702531e-09,2.10644818576211e-09,4.97021063478905e-10,4.56992034783108e-11;-6.50723895430486e-09,-7.79796414772792e-09,-4.27522483087467e-09,2.15529507338017e-10,6.11508280223123e-10,3.58090445393848e-10,2.36058743960409e-10,4.56992034783108e-11,2.27730099763230e-11;];
parms.PreClinicalFramework.Scoring.GMMinit.Sigma(:,:,2) = [8.30263344303104e-06,9.09389170376479e-06,5.38822741003025e-06,1.25833799807154e-06,5.41684509192906e-08,-1.12286140455011e-07,2.78581857989797e-07,6.87372513266446e-09,6.64946016817322e-09;9.09389170376479e-06,1.25472757347223e-05,9.84540918739503e-06,4.56155896148924e-06,1.13823659083932e-06,2.33452256192066e-07,4.04921507083701e-07,8.29144233897335e-09,7.82990379169414e-09;5.38822741003025e-06,9.84540918739503e-06,1.02388869949781e-05,6.69248962896967e-06,2.08436236378601e-06,6.38040262646296e-07,3.25857589723290e-07,-4.08980718140652e-09,7.18698411730893e-09;1.25833799807154e-06,4.56155896148924e-06,6.69248962896967e-06,6.46322844562182e-06,2.87604087749877e-06,7.10668293838993e-07,1.18016189160370e-07,-1.91098155912902e-08,1.98789622991242e-09;5.41684509192906e-08,1.13823659083932e-06,2.08436236378601e-06,2.87604087749877e-06,2.05067683019371e-06,4.00806138505491e-07,7.77721288006628e-09,-1.33603840836071e-08,-1.16929891653326e-09;-1.12286140455011e-07,2.33452256192066e-07,6.38040262646296e-07,7.10668293838993e-07,4.00806138505491e-07,4.28696339281615e-07,9.32717440982032e-08,-6.05348724103567e-09,-1.13534762388112e-09;2.78581857989797e-07,4.04921507083701e-07,3.25857589723290e-07,1.18016189160370e-07,7.77721288006628e-09,9.32717440982032e-08,7.28634988898956e-08,2.14539410208032e-09,1.52714357825710e-10;6.87372513266446e-09,8.29144233897335e-09,-4.08980718140652e-09,-1.91098155912902e-08,-1.33603840836071e-08,-6.05348724103567e-09,2.14539410208032e-09,1.23821426118759e-09,7.45169413427268e-11;6.64946016817322e-09,7.82990379169414e-09,7.18698411730893e-09,1.98789622991242e-09,-1.16929891653326e-09,-1.13534762388112e-09,1.52714357825710e-10,7.45169413427268e-11,6.18833204777446e-11;];
parms.PreClinicalFramework.Scoring.GMMinit.Sigma(:,:,3) = [3.36750430381250e-06,3.65213084654735e-06,2.48120164482384e-06,1.08072643597787e-06,6.15062544742349e-07,3.01722082759326e-07,9.09101101100596e-08,7.13226536233542e-09,-1.91160904149773e-09;3.65213084654735e-06,5.10205822345995e-06,4.35548336489569e-06,2.18302439043424e-06,8.95175259670608e-07,3.22945806888098e-07,8.94204203627126e-08,8.66501262981553e-09,-3.61694759374164e-09;2.48120164482384e-06,4.35548336489569e-06,4.45838414237463e-06,2.65786488689568e-06,1.01336319154902e-06,2.76750251625232e-07,7.03012584504661e-08,9.55912991777685e-09,-3.52428088645900e-09;1.08072643597787e-06,2.18302439043424e-06,2.65786488689568e-06,2.34255553290755e-06,1.23327128802898e-06,2.62613072651603e-07,5.54084958657510e-08,5.12445290470492e-09,-1.87123549287140e-09;6.15062544742349e-07,8.95175259670608e-07,1.01336319154902e-06,1.23327128802898e-06,1.08727403476043e-06,2.46135986329531e-07,4.22627038227679e-08,2.20431951198204e-10,-7.95979308097672e-10;3.01722082759326e-07,3.22945806888098e-07,2.76750251625232e-07,2.62613072651603e-07,2.46135986329531e-07,8.50887557986818e-08,1.63365407316538e-08,1.14848642696054e-09,-2.89682825022552e-10;9.09101101100596e-08,8.94204203627126e-08,7.03012584504661e-08,5.54084958657510e-08,4.22627038227679e-08,1.63365407316538e-08,7.16518636118017e-09,8.71599608363612e-10,-1.08344092130150e-12;7.13226536233542e-09,8.66501262981553e-09,9.55912991777685e-09,5.12445290470492e-09,2.20431951198204e-10,1.14848642696054e-09,8.71599608363612e-10,3.00947586648809e-10,5.79265648340309e-12;-1.91160904149773e-09,-3.61694759374164e-09,-3.52428088645900e-09,-1.87123549287140e-09,-7.95979308097672e-10,-2.89682825022552e-10,-1.08344092130150e-12,5.79265648340309e-12,2.51921867670278e-11;];
parms.PreClinicalFramework.Scoring.GMMinit.Sigma(:,:,4) = [1.70180913340868e-06,2.06668261992355e-06,1.39030510555493e-06,3.81882669748959e-07,1.05703434699407e-07,1.27292292344418e-07,5.17848140087307e-08,4.10988499380924e-09,1.83041107685045e-09;2.06668261992355e-06,2.83658970372891e-06,2.02875472778582e-06,5.90495051726248e-07,1.30986140476431e-07,1.42025566486389e-07,5.02480293308325e-08,4.70850404341096e-09,2.00163797722505e-09;1.39030510555493e-06,2.02875472778582e-06,1.63616289162828e-06,6.17503487968503e-07,1.72206804678260e-07,1.26616288875042e-07,5.19166373148613e-08,4.06970678708567e-09,1.93407876728527e-09;3.81882669748959e-07,5.90495051726248e-07,6.17503487968503e-07,4.03536611903962e-07,1.55390598700990e-07,7.47436568947615e-08,4.10397663310454e-08,2.26858013949286e-09,1.60652475171420e-09;1.05703434699407e-07,1.30986140476431e-07,1.72206804678260e-07,1.55390598700990e-07,1.04391164628062e-07,4.22572154461785e-08,2.28482952640550e-08,1.52127790470014e-09,4.67161353487853e-10;1.27292292344418e-07,1.42025566486389e-07,1.26616288875042e-07,7.47436568947615e-08,4.22572154461785e-08,7.29273553235032e-08,1.73584330903472e-08,-7.03173764814625e-11,3.09753704601737e-10;5.17848140087307e-08,5.02480293308325e-08,5.19166373148613e-08,4.10397663310454e-08,2.28482952640550e-08,1.73584330903472e-08,1.64405809242393e-08,5.47275112557947e-10,2.37023626328318e-10;4.10988499380924e-09,4.70850404341096e-09,4.06970678708567e-09,2.26858013949286e-09,1.52127790470014e-09,-7.03173764814625e-11,5.47275112557947e-10,2.61416052000545e-10,2.45030487719594e-11;1.83041107685045e-09,2.00163797722505e-09,1.93407876728527e-09,1.60652475171420e-09,4.67161353487853e-10,3.09753704601737e-10,2.37023626328318e-10,2.45030487719594e-11,4.35725495404241e-11;];
parms.PreClinicalFramework.Scoring.GMMinit.Sigma(:,:,5) = [8.42939036651693e-07,7.09145690975517e-07,4.10585358955498e-07,1.63618832372541e-07,8.74205065188283e-08,5.70560204110209e-08,2.32091287993437e-08,1.15231573694948e-09,-1.08890833623145e-09;7.09145690975517e-07,6.99106536970443e-07,4.69158910553646e-07,2.06737628456819e-07,8.66008807739507e-08,4.97522229548945e-08,1.84865562765128e-08,7.87305670702298e-10,-1.11767557305384e-09;4.10585358955498e-07,4.69158910553646e-07,3.76520271051432e-07,1.98778865897984e-07,7.85510477511286e-08,3.67531808068001e-08,1.10542474013834e-08,1.04365478542216e-09,-7.81055275651684e-10;1.63618832372541e-07,2.06737628456819e-07,1.98778865897984e-07,1.40347008247962e-07,6.69732994210836e-08,2.23551034090265e-08,4.23487581415079e-09,1.10835490367842e-09,-3.05646368794882e-10;8.74205065188283e-08,8.66008807739507e-08,7.85510477511286e-08,6.69732994210836e-08,4.94013116684990e-08,1.55335100000672e-08,3.01762632677479e-09,1.22821614193164e-09,7.72440956114671e-11;5.70560204110209e-08,4.97522229548945e-08,3.67531808068001e-08,2.23551034090265e-08,1.55335100000672e-08,8.81815852829659e-09,2.45367675941356e-09,3.49454900026674e-10,1.25236201150300e-11;2.32091287993437e-08,1.84865562765128e-08,1.10542474013834e-08,4.23487581415079e-09,3.01762632677479e-09,2.45367675941356e-09,1.49132718560993e-09,4.40358115178234e-11,-2.47101704163432e-11;1.15231573694948e-09,7.87305670702298e-10,1.04365478542216e-09,1.10835490367842e-09,1.22821614193164e-09,3.49454900026674e-10,4.40358115178234e-11,2.06742290386408e-10,2.81093522220064e-11;-1.08890833623145e-09,-1.11767557305384e-09,-7.81055275651684e-10,-3.05646368794882e-10,7.72440956114671e-11,1.25236201150300e-11,-2.47101704163432e-11,2.81093522220064e-11,3.69580816851926e-11;];
parms.PreClinicalFramework.Scoring.GMMinit.PComponents = [0.235582791083435,0.148067298852050,0.211981813086952,0.181918787462418,0.222449309515145;];
% GMM end point
parms.PreClinicalFramework.Scoring.GMMclust = [0.00812009526019139,0.0116251246161410,0.0107005973439480,0.00642379351659442,0.00248666219147668,0.000909618995051502,0.000347570749139938,8.22293693144029e-05,2.78707749365036e-05;0.00609425588594097,0.00837007337968675,0.00736420061759011,0.00503299529104573,0.00262960863924286,0.00142115868405853,0.000520439275225559,0.000123448049611899,3.35926228938710e-05;0.00388239903392241,0.00549942558751268,0.00526923196027110,0.00370482741349266,0.00184319537069624,0.000589332117020189,0.000242618622361572,7.83648706786513e-05,2.74784534048178e-05;0.00302265928862588,0.00382732636834386,0.00282730203741678,0.00142570071172277,0.000824317086962886,0.000554314278975743,0.000292771847839603,8.18324925891467e-05,3.03697448524823e-05;0.00142194216410385,0.00152793022913160,0.00120679155733946,0.000763746178368655,0.000443906801604746,0.000224456547831827,0.000127254040425521,7.15534909763699e-05,3.30384286088583e-05;];

%Licences contained
%1) fuf()
% Copyright (c) 2002, Francesco di Pierro
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without 
% modification, are permitted provided that the following conditions are 
% met:
% 
%     * Redistributions of source code must retain the above copyright 
%       notice, this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright 
%       notice, this list of conditions and the following disclaimer in 
%       the documentation and/or other materials provided with the distribution
%       
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
% POSSIBILITY OF SUCH DAMAGE.

% 2) xml_toolbox
% Copyright (c) 2004, Geodise Project, University of Southampton
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with 
% or without modification, are permitted provided that the 
% following conditions are met:
% 
%  * Redistributions of source code must retain the above 
%    copyright notice, this list of conditions and the 
%    following disclaimer.
% 
%  * Redistributions in binary form must reproduce the above 
%    copyright notice, this list of conditions and the following 
%    disclaimer in the documentation and/or other materials 
%    provided with the distribution.
% 
%  * Neither the name of the University of Southampton nor the 
%    names of its contributors may be used to endorse or promote 
%    products derived from this software without specific prior 
%    written permission.
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
% POSSIBILITY OF SUCH DAMAGE.

% 3) Word Toolbox
% Copyright (c) 2010, Ivar Eskerud Smith
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without 
% modification, are permitted provided that the following conditions are 
% met:
% 
%     * Redistributions of source code must retain the above copyright 
%       notice, this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright 
%       notice, this list of conditions and the following disclaimer in 
%       the documentation and/or other materials provided with the distribution
%       
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
% POSSIBILITY OF SUCH DAMAGE.

% 4) TinyXML2
% TinyXML2_wrap
% Copyright (c) 2016, Ladislav Dobrovsky
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are
% met:
% 
%     * Redistributions of source code must retain the above copyright
%       notice, this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright
%       notice, this list of conditions and the following disclaimer in
%       the documentation and/or other materials provided with the distribution
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% POSSIBILITY OF SUCH DAMAGE.
% 
% TinyXML2
% Original code by Lee Thomason (www.grinninglizard.com)
% 
% This software is provided 'as-is', without any express or implied
% warranty. In no event will the authors be held liable for any
% damages arising from the use of this software.
% 
% Permission is granted to anyone to use this software for any
% purpose, including commercial applications, and to alter it and
% redistribute it freely, subject to the following restrictions:
% 
% 1. The origin of this software must not be misrepresented; you must
% not claim that you wrote the original software. If you use this
% software in a product, an acknowledgment in the product documentation
% would be appreciated but is not required.
% 
% 2. Altered source versions must be plainly marked as such, and
% must not be misrepresented as being the original software.
% 
% 3. This notice may not be removed or altered from any source
% distribution.



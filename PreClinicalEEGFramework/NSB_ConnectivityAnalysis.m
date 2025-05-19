function [status,DataStruct] = NSB_ConnectivityAnalysis(DataStruct, options)
% NSB_ConnectivityAnalysis() -
%
% Inputs:
%   data:               NSB DataStruct
%                       formed to (matrix) multivariate data, indexed by time, variableNumber, and possibly trialNumber.
%   options:            - (struct) parameter Structure
%                           options.logfile
%                           options.FinalTimeBinSize
%                           options.FinalFreqRes
%                           options.fs
%                           options.JIDT.UnivariateAnalysis (logical or int{ch number})
%                           options.JIDT.AnalysisChannels (int, vector)
%                           options.JIDT.calcType: which estimator type to use, from options 'discrete', 'gaussian', 'ksg'
%                           options.JIDT.calculator: which calculator to use, from options 'MutualInformationCalculator',
%                           'ConditionalMutualInformationCalculator','EntropyRateCalculator','ActiveInformationCalculator',
%                           'PredictiveInformationCalculator','TransferEntropyCalculator','ConditionalTransferEntropyCalculator',
%                           'SeparableInfoCalculator'. More are avalable from JIDT and IDLxL just need to code them up
%                           options.JIDT.k_history: [] or int for all/specific target embedding length, can be 'auto'
%                           to indicate auto-embedding (i.e. embedding length k of the past history vector (1 by default)).
%                           options.JIDT.k_max: max target embedding length to use when parameters.k == 'auto' (default 10)
%                           options.JIDT.numSurrogates: number of surrogates to run, or 0 for analytic surrogates (default 1000)
%                           options.JIDT.maxDynCorrExclLags: maximum length of dynamic correlation exclusion, which will be auto-fitted (default 50)
%
% Outputs:
%   status               - (logical)
%
% ToDo: May store db credentials in mat file
%
% Written By David M. Devilbiss
% NexStep Biomarkers, LLC. (info@nexstepbiomarkers.com)
% April 1 2025, Version 0.01
%
% See:
%https://www.ncbi.nlm.nih.gov/pmc/articles/PMC10044923/
%
%https://www.nature.com/articles/s41598-019-45289-7#Sec2
% weighted Phase Lag Index (wPLI1) and the weighted Symbolic Mutual Information (wSMI4), represent examples of spectral (wPLI) and information-theoretic (wSMI) connectivity estimation methods
%
% https://github.com/jlizier/jidt
% https://github.com/jlizier/jidt/wiki/Documentation
% https://lizier.me/joseph/software/jidt/javadocs/v1.6.1/
% https://github.com/pwollstadt/IDTxl
%
% https://www.mathworks.com/help/matlab/matlab_external/java-heap-memory-preferences.html
% % Furure T-F analysis
% https://pmc.ncbi.nlm.nih.gov/articles/PMC10635047
%
%Definitions:
% Mutual information - the expected reduction in uncertainty about x that results from learning the value of y, or vice versa.
% Measures of information dynamics:
% Effective Measure Complexity or Excess Entropy quantifes the total amount of structure or memory in the process X, and
%       is computed in terms of the slowness of the approach of the conditional entropy rate estimates to their limiting
%       value.
% Predictive Information - highlights that the excess entropy captures the information in a systems past which can also
%       be found in its future. the excess entropy can be viewed in this formulation as measuring information from the
%       past of the process that is stored potentially in a distributed fashion in external variables and is used at some
%       point in the future of the process.
% Active Information Storage - AIS is the mutual information between the past state of a time-series process X and its next value.
%       The past state at time n is represented by an embedding vector of k values from X_n backwards, each separated by \tau steps,
%       giving X^k_n = [ X_{n-(k-1)\tau}, ... , X_{n-\tau}, X_n]. We call k the embedding dimension, and \tau the embedding delay.
%       AIS is then the mutual information between X^k_n and X_{n+1}.
%
% Estimation techniques:
% Discrete - Mathematical defnitions may be used directly, by counting the matching con gurations in the available data to obtain
%               the relevant plug-in probability estimates (e.g. p(x y) and p(x) for MI).
% Continuous - discretise or bin the data and apply the discrete estimators << OR >> use an estimator that harnesses the
%               continuous nature of the variables, dealing with the diferential entropy and probability density functions.
%       Multivariate Gaussian model
%       Kernel estimation
%       Kraskov-Stogbauer-Grassberger (KSG) technique (2 algorithms). algorithm 1 is more accurate for smaller
%               numbers of samples but is more biased, while algorithm 2 is more accurate for very large sample sizes.
%
% % To Do -------
% Critical warnings:
% options.PreClinicalFramework.Reference.doReRef << shouldn't be re-referenced
% options.PreClinicalFramework.Resample.Detrend %ok if detrended
% options.PreClinicalFramework.Resample.doResample %ok if detrended
%
% should run after artifact detection
% all file or by segments
% todo w/Lags

status = false;
ConnectivityStruct = [];

% Check for JIDT jar file
if exist('infodynamics.jar','file') == 0
    logstr = ['The Java Information Dynamics Toolkit (JIDT) Copyright (C) 2012, Joseph T. Lizier is not installed. Please see: https://github.com/jlizier/'];
    disp(logstr);
    NSBlog(options.logfile,logstr);
    return;
else
    logstr = 'NSB_ConnectivityAnalysis - Running...';
    disp(logstr);
    NSBlog(options.logfile,logstr);
end

% Validate inputs
% Set Default calc and type for JIDT analysis class name
[options.JIDT,~] = setJIDTdefaults(options.JIDT);
if ~isfield(options.JIDT, 'calcType')
    options.JIDT.calcType = 'ksg';
end
if ~isfield(options.JIDT, 'calculator')
    options.JIDT.calculator = 'EntropyRateCalculator';
end
calcString = setCalculatorName(options.JIDT.calcType, options.JIDT.calculator);

%Begin Processing
%% Univariate Analysis
if options.JIDT.UnivariateAnalysis
    %treat all channels independently
    runtic = tic;
    logstr = 'NSB_ConnectivityAnalysis - Running JIDT.UnivariateAnalysis ...';
    disp(logstr);
    NSBlog(options.logfile,logstr);
    for curChan = options.JIDT.AnalysisChannels

        logstr = ['NSB_ConnectivityAnalysis - Analyzing Channel ',DataStruct.Channel(curChan).Name];
        disp(logstr);
        NSBlog(options.logfile,logstr);

        % 1st remove artifact
        Signal = DataStruct.Channel(curChan).Data(:); %force to column vector (but dosn't really matter)
        if islogical(DataStruct.Channel(curChan).Artifacts)
            Signal(DataStruct.Channel(curChan).Artifacts) = NaN;
        elseif isfield(DataStruct.Channel(curChan).Artifacts,'intStarts')
            %Convert Intervals 2 Logical
            Artifact_IDX = NSB_interval2IDX(DataStruct.Channel(curChan).Artifacts,length(Signal),options.fs);
            Signal(Artifact_IDX) = NaN;
            clear Artifact_IDX;
        end

        %Bin Data into time epochs
        BinnedData = buffer(Signal,round(options.FinalTimeBinSize*options.fs),0,'nodelay'); %BinSize = round(BinSize*fs);
        validBins = ~any(isnan(BinnedData));

        calc = javaObject(calcString);
        [options.JIDT,calc] = setJIDTdefaults(options.JIDT,calc);
        % calc.setProperty('AUTO_EMBED_METHOD', 'max_corr_AIS');
        % calc.setProperty('AUTO_EMBED_K_SEARCH_MAX', sprintf("%d", 10));
        % calc.setProperty('AUTO_EMBED_MAX_CORR_AIS_SURROGATES', sprintf("%d", 1000));
        % calc.setProperty('AUTO_EMBED_MAX_CORR_SURROGATES', sprintf("%d", 1000));
        % calc.setProperty('NORMALISE', 'true');

        waitdlg = waitbar(0,'Processing Channel 00 : Segment 00','Name','Connectivity Analysis');
       
        totalValidBins = length(validBins);
        for curbuffer = 1:totalValidBins %could run in a ParFor but obj is an issue!
            %runtic = tic;
            % Update progress, report current estimate
            waitbar(curbuffer/totalValidBins,waitdlg,sprintf('Processing Channel %02d : Segment %02d of %d',curChan,curbuffer,totalValidBins));
            drawnow;
            if validBins(curbuffer)

                calc.initialise();
                calc.setObservations(octaveToJavaDoubleArray(BinnedData(:,curbuffer)));
                ConnectivityStruct.Univariate(curChan).mean(curbuffer) = calc.computeAverageLocalOfObservations();
                ConnectivityStruct.Univariate(curChan).optimal_k_history(curbuffer) = str2num(calc.getProperty('k_HISTORY'));
                %ConnectivityStruct.AIS(n).local = calc.computeLocalOfPreviousObservations();
                %ConnectivityStruct.AIS(n).NullDist = calc.computeSignificance(100);
                AIS_NullDist = calc.computeSignificance(options.JIDT.numSurrogates); % Major time sync
                ConnectivityStruct.Univariate(curChan).NullMean(curbuffer) = AIS_NullDist.getMeanOfDistribution();
                ConnectivityStruct.Univariate(curChan).NullStd(curbuffer)  = AIS_NullDist.getStdOfDistribution();
                ConnectivityStruct.Univariate(curChan).Nullp(curbuffer)    = AIS_NullDist.pValue;
                ConnectivityStruct.Univariate(curChan).validBins(curbuffer)= true;
            else
                ConnectivityStruct.Univariate(curChan).mean(curbuffer) = NaN;
                ConnectivityStruct.Univariate(curChan).optimal_k_history(curbuffer) = NaN;
                ConnectivityStruct.Univariate(curChan).NullMean(curbuffer) = NaN;
                ConnectivityStruct.Univariate(curChan).NullStd(curbuffer)  = NaN;
                ConnectivityStruct.Univariate(curChan).Nullp(curbuffer)    = NaN;
                ConnectivityStruct.Univariate(curChan).validBins(curbuffer)= false;
            end
        end
        ConnectivityStruct.Mvariate.name = DataStruct.Channel(curChan).Name;
        DataStruct.Channel(curChan).(options.JIDT.calculator) = ConnectivityStruct.Univariate(curChan);
        
        try, delete(waitdlg); end
    end %chan for loop
    logstr = sprintf('Elapsed Time(s) %f',toc(runtic));
    disp(logstr);
    NSBlog(options.logfile,logstr);
    
else % multivariate analysis
    if length(options.JIDT.AnalysisChannels) == 2
        runtic = tic;
        logstr = 'NSB_ConnectivityAnalysis - Running JIDT.MultivariateAnalysis ...';
        disp(logstr);
        NSBlog(options.logfile,logstr);
        logstr = ['NSB_ConnectivityAnalysis - Analyzing Channels ',DataStruct.Channel(options.JIDT.AnalysisChannels(1)).Name,' - ',DataStruct.Channel(options.JIDT.AnalysisChannels(2)).Name];
        disp(logstr);
        NSBlog(options.logfile,logstr);

        % 1st remove artifact(s)
        Signal1 = DataStruct.Channel(options.JIDT.AnalysisChannels(1)).Data(:); %force to column vector (but dosn't really matter)
        Signal2 = DataStruct.Channel(options.JIDT.AnalysisChannels(2)).Data(:); %force to column vector (but dosn't really matter)

        if islogical(DataStruct.Channel(options.JIDT.AnalysisChannels(1)).Artifacts)
            Signal1(DataStruct.Channel(options.JIDT.AnalysisChannels(1)).Artifacts) = NaN;
        elseif isfield(DataStruct.Channel(options.JIDT.AnalysisChannels(1)).Artifacts,'intStarts')
            %Convert Intervals 2 Logical
            Artifact_IDX = NSB_interval2IDX(DataStruct.Channel(options.JIDT.AnalysisChannels(1)).Artifacts,length(Signal1),options.fs);
            Signal(Artifact_IDX) = NaN;
            clear Artifact_IDX;
        end
        if islogical(DataStruct.Channel(options.JIDT.AnalysisChannels(2)).Artifacts)
            Signal1(DataStruct.Channel(options.JIDT.AnalysisChannels(2)).Artifacts) = NaN;
        elseif isfield(DataStruct.Channel(options.JIDT.AnalysisChannels(2)).Artifacts,'intStarts')
            %Convert Intervals 2 Logical
            Artifact_IDX = NSB_interval2IDX(DataStruct.Channel(options.JIDT.AnalysisChannels(2)).Artifacts,length(Signal2),options.fs);
            Signal(Artifact_IDX) = NaN;
            clear Artifact_IDX;
        end
      
        %Bin Data into time epochs
        BinnedData1 = buffer(Signal1,round(options.FinalTimeBinSize*options.fs),0,'nodelay'); %BinSize = round(BinSize*fs);
        validBins1 = ~any(isnan(BinnedData1));
        BinnedData2 = buffer(Signal2,round(options.FinalTimeBinSize*options.fs),0,'nodelay'); %BinSize = round(BinSize*fs);
        validBins2 = ~any(isnan(BinnedData2));

        calc = javaObject(calcString);
        [options.JIDT,calc] = setJIDTdefaults(options.JIDT,calc);

        waitdlg = waitbar(0,'Processing Channel 00 : Segment 00','Name','Connectivity Analysis');
       
        totalValidBins = max(length(validBins1), length(validBins1));
        for curbuffer = 1:totalValidBins %could run in a ParFor but obj is an issue!
            % Update progress, report current estimate
            waitbar(curbuffer/totalValidBins,waitdlg,sprintf('Processing Channels %02d - %02d : Segment %02d of %d',options.JIDT.AnalysisChannels(1),options.JIDT.AnalysisChannels(2),curbuffer,totalValidBins));
            drawnow;
            if validBins1(curbuffer) && validBins2(curbuffer)

                calc.initialise();
                calc.setObservations(octaveToJavaDoubleArray(BinnedData1(:,curbuffer)), octaveToJavaDoubleArray(BinnedData2(:,curbuffer)) );
                ConnectivityStruct.Mvariate.mean(curbuffer) = calc.computeAverageLocalOfObservations();
                ConnectivityStruct.Mvariate.optimal_k_history(curbuffer) = str2num(calc.getProperty('k_HISTORY'));
                %ConnectivityStruct.AIS(n).local = calc.computeLocalOfPreviousObservations();
                %ConnectivityStruct.AIS(n).NullDist = calc.computeSignificance(100);
                AIS_NullDist = calc.computeSignificance(options.JIDT.numSurrogates); % Major time sync
                ConnectivityStruct.Mvariate.NullMean(curbuffer) = AIS_NullDist.getMeanOfDistribution();
                ConnectivityStruct.Mvariate.NullStd(curbuffer)  = AIS_NullDist.getStdOfDistribution();
                ConnectivityStruct.Mvariate.Nullp(curbuffer)    = AIS_NullDist.pValue;
                ConnectivityStruct.Mvariate.validBins(curbuffer)= true;
            else
                ConnectivityStruct.Mvariate.validBins(curbuffer)= false;
            end
        end
        logstr = sprintf('Elapsed Time(s) %f',toc(runtic));
        disp(logstr);
        NSBlog(options.logfile,logstr);

        ConnectivityStruct.Mvariate.name = [DataStruct.Channel(options.JIDT.AnalysisChannels(1)).Name,':',DataStruct.Channel(options.JIDT.AnalysisChannels(2)).Name];

        DataStruct.Channel(options.JIDT.AnalysisChannels(1)).(options.JIDT.calculator) = ConnectivityStruct.Mvariate; %add to lowest channel
        DataStruct.Channel(options.JIDT.AnalysisChannels(2)).(options.JIDT.calculator) = 'Mvariate';
        try, delete(waitdlg); end

    elseif length(options.JIDT.AnalysisChannels) > 2

        logstr = ['NSB_ConnectivityAnalysis - Cannot perform Multivariate TE on more than 2 channels.'];
        disp(logstr);
        NSBlog(options.logfile,logstr);

    else
        %univariate
        % error
        %logstr = ['NSB_ConnectivityAnalysis - Analyzing Channel ',DataStruct.Channel(options.JIDT.AnalysisChannels(1)).Name];
        logstr = ['NSB_ConnectivityAnalysis - Cannot perform Multivariate TE on one channel ',DataStruct.Channel(options.JIDT.AnalysisChannels(1)).Name];
        disp(logstr);
        NSBlog(options.logfile,logstr);
    end


end
end
function [JIDT,calc] = setJIDTdefaults(JIDT,calc)
% Property List
% infodynamics.measures.continuous.ActiveInfoStorageCalculator
%   k_HISTORY - embedding length k of the past history vector
%   TAU - embedding delay between each of the k points in the past history vector
%           1,1,1,1,1,1,1 vs 1,.,1,.,1,.,1 or 1,.,.,1,.,.,1,.,.,1
% infodynamics.measures.continuous.ActiveInfoStorageCalculatorMultiVariate
%   DIMENSIONS
%
% infodynamics.measures.continuous.ActiveInfoStorageCalculatorViaMutualInfo
%   AUTO_EMBED_METHOD {
%       NONE - no auto embedding should be done (i.e. to use manually supplied parameters)
%       RAGWITZ - Ragwitz optimisation technique should be used for automatic embedding
%       MAX_CORR_AIS - automatic embedding should be done by maximising the bias corrected AIS (as per Garland et al.)}
%   AUTO_EMBED_K_SEARCH_MAX - maximum embedding length to search up to for automating the parameters.
%   AUTO_EMBED_RAGWITZ_NUM_NNS - number of nearest neighbours to use for the auto-embedding search (Ragwitz criteria)
%          Defaults to match the value in use for MutualInfoCalculatorMultiVariateKraskov.PROP_K
%   AUTO_EMBED_TAU_SEARCH_MAX - maximum tau (embedding delay) for the auto-embedding search.
%
% infodynamics.measures.continuous.ConditionalMutualInfoCalculatorMultiVariate
%   NOISE_LEVEL_TO_ADD
%   NORMALISE
%
% infodynamics.measures.continuous.ConditionalTransferEntropyCalculator
%   COND_DELAYS
%   COND_TAUS
%   COND_EMBED_LENGTHS
%   DELAY
%   k_TAU
%   l_HISTORY
%   l_TAU
%
% infodynamics.measures.continuous.kraskov.MultiInfoCalculatorKraskov
%   NOISE_LEVEL_TO_ADD
%   DYN_CORR_EXCL
%   k - number of K nearest neighbours used in the KSG algorithm in the full joint space (default 4).
%   NORM_TYPE
%   NUM_THREADS {n, USE_ALL)
%
% For more see: https://lizier.me/joseph/software/jidt/javadocs/v1.6.1/constant-values.html
if nargin < 1
    JIDT = [];
    calc = [];
elseif nargin < 2
    calc = [];
end

% Set parameter defaults:
% The past state at time n is represented by an embedding vector of k values from X_n backwards, each separated by \tau steps
% this updates automatically using AUTO embedding
if ~isfield(JIDT, 'k_history')
    JIDT.k_history = 1;
elseif ~isempty(calc)
    if isnumeric(JIDT.k_history) && str2double(calc.getProperty('k_HISTORY')) ~= JIDT.k_history
        calc.setProperty('k_HISTORY', sprintf("%d", JIDT.k_history));
    else
        JIDT.AutoEmbedding = 'max_corr_AIS';
    end
end
if ~isfield(JIDT, 'tau')
    JIDT.tau = 1;
elseif ~isempty(calc) && str2double(calc.getProperty('TAU')) ~= JIDT.tau
    calc.setProperty('TAU', sprintf("%d", JIDT.tau));
end

% ActiveInfoStorageCalculatorMultiVariate
% number of dimensions in the multivariate data.
if ~isfield(JIDT, 'AIS_dimensions')
    JIDT.AIS_dimensions = 1;
elseif ~isempty(calc) && ...
        ( str2double(calc.getProperty('DIMENSIONS')) ~= JIDT.AIS_dimensions || isempty(calc.getProperty('DIMENSIONS')) )
    calc.setProperty('DIMENSIONS', sprintf("%d", JIDT.AIS_dimensions));
end

% CalculatorViaMutualInfo
% AutoEmbeding k_history
if ~isfield(JIDT, 'AutoEmbedding')
    JIDT.AutoEmbedding = 'none'; % {'none', 'ragwitz', 'max_corr_AIS'}
elseif ~isempty(calc) && calc.getProperty('AUTO_EMBED_METHOD') ~= JIDT.AutoEmbedding
    calc.setProperty('AUTO_EMBED_METHOD', sprintf("%s", JIDT.AutoEmbedding));
end
if ~isfield(JIDT, 'k_search_max')
    JIDT.k_search_max = 1;
elseif ~isempty(calc) && str2double(calc.getProperty('AUTO_EMBED_K_SEARCH_MAX')) ~= JIDT.k_search_max
    calc.setProperty('AUTO_EMBED_K_SEARCH_MAX', sprintf("%d", JIDT.k_search_max));
end
if ~isfield(JIDT, 'tau_search_max')
    JIDT.tau_search_max = 1;
elseif ~isempty(calc) && str2double(calc.getProperty('AUTO_EMBED_RAGWITZ_NUM_NNS')) ~= JIDT.tau_search_max
    calc.setProperty('AUTO_EMBED_RAGWITZ_NUM_NNS', sprintf("%d", JIDT.tau_search_max));
end
if ~isfield(JIDT, 'ragwitz_NNS')
    JIDT.ragwitz_NNS = 4;
elseif ~isempty(calc) && str2double(calc.getProperty('AUTO_EMBED_TAU_SEARCH_MAX')) ~= JIDT.ragwitz_NNS
    calc.setProperty('AUTO_EMBED_TAU_SEARCH_MAX', sprintf("%d", JIDT.ragwitz_NNS));
end
if ~isfield(JIDT, 'numSurrogates')
    JIDT.numSurrogates = 1000;
elseif ~isempty(calc) && ...
        ( str2double(calc.getProperty('AUTO_EMBED_MAX_CORR_SURROGATES')) ~= JIDT.numSurrogates || isempty(calc.getProperty('AUTO_EMBED_MAX_CORR_SURROGATES')) )
    calc.setProperty('AUTO_EMBED_MAX_CORR_SURROGATES', sprintf("%d", JIDT.numSurrogates));
    calc.setProperty('AUTO_EMBED_MAX_CORR_AIS_SURROGATES', sprintf("%d", JIDT.numSurrogates)); %<< NOTE using the same for both
end

% ConditionalMutualInfo
if ~isfield(JIDT, 'noise_level_to_add')
    JIDT.noise_level_to_add = 1.0e-8;
elseif ~isempty(calc) && str2double(calc.getProperty('NOISE_LEVEL_TO_ADD')) ~= JIDT.noise_level_to_add
    calc.setProperty('NOISE_LEVEL_TO_ADD', sprintf("%d", JIDT.noise_level_to_add));
end
if ~isfield(JIDT, 'normalize')
    JIDT.normalize = true;
elseif ~isempty(calc)
    if JIDT.normalize
        calc.setProperty('NORMALISE', 'true');
    else
        calc.setProperty('NORMALISE', 'false');
    end
end


%illdefined and may have more later...
if ~isfield(JIDT, 'verbose')
    JIDT.verbose = true;
end
if ~isfield(JIDT, 'timePointsToSkipAtStart')
    JIDT.timePointsToSkipAtStart = 0;
end
if ~isfield(JIDT, 'timePointsToSkipAtEnd')
    JIDT.timePointsToSkipAtEnd = 0;
end
if ~isfield(JIDT, 'maxDynCorrExclLags')
    JIDT.maxDynCorrExclLags = 50;
end
if ~isfield(JIDT, 'numDiscreteBins')
    JIDT.numDiscreteBins = 2;
end
end

function javaString = setCalculatorName(calcType, calculator)
% Entropy
% Joint entropy
% Conditional entropy
% Mutual information
% Multi-information
% Conditional MI
% Entropy rate
% Active information storage
% Predictive information
% Transfer entropy
% Conditional TE
javaString = 'infodynamics.measures.';
switch lower(calcType)
    case 'discrete'
        javaString = strcat(javaString, 'discrete.');
    case 'gaussian'
        javaString = strcat(javaString, 'continuous.gaussian.');
    case 'ksg'
        javaString = strcat(javaString, 'continuous.kraskov.');
    otherwise
        %throw warning
end

switch lower(calculator)
    case 'mutualinformationcalculator'
        javaString = strcat(javaString, 'MutualInformationCalculator');
    case 'conditionalmutualinformationcalculator'
        javaString = strcat(javaString, 'ConditionalMutualInformationCalculator');
    case 'entropyratecalculator'
        javaString = strcat(javaString, 'EntropyRateCalculator');
    case 'activeinformationcalculator'
        javaString = strcat(javaString, 'ActiveInfoStorageCalculator');
        % initialise​(int k, int tau)
        % Parameters:
        % k - embedding length of past history vector
        % tau - embedding delay of past history vector
    case 'predictiveinformationcalculator'
        javaString = strcat(javaString, 'PredictiveInformationCalculator');
    case 'transferentropycalculator'
        javaString = strcat(javaString, 'TransferEntropyCalculator');
    case 'conditionaltransferentropycalculator'
        javaString = strcat(javaString, 'ConditionalTransferEntropyCalculator');
    case 'separableinfocalculator'
        javaString = strcat(javaString, 'SeparableInfoCalculator');
end

switch lower(calcType)
    case 'discrete'
        javaString = strcat(javaString, 'Discrete');
    case 'gaussian'
        javaString = strcat(javaString, 'Gaussian');
    case 'ksg'
        javaString = strcat(javaString, 'Kraskov');
        % setProperty
        % ALG_NUM -- which Kraskov algorithm number to use (1 or 2).
        % K -- number of k nearest neighbours to use in joint kernel space in the KSG algorithm (default is 4).
        % NORM_TYPE -- normalization type to apply to working out the norms between the points in each marginal space. either NORM_EUCLIDEAN, NORM_EUCLIDEAN_SQUARED or NORM_MAX_NORM Default is EuclideanUtils.NORM_MAX_NORM.
        % DYN_CORR_EXCL_TIME -- a dynamics exclusion time window, also known as Theiler window (see Kantz and Schreiber); default is 0 which means no dynamic exclusion window
        % NUM_THREADS -- the integer number of parallel threads to use in the computation. Can be passed as a string "USE_ALL" to use all available processors on the machine. Default is "USE_ALL".
    otherwise
        %throw warning
end
end


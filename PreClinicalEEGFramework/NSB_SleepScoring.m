function [ScoreChannel, status] = NSB_SleepScoring(EEG, EMG, Activity, options)
% NSB_SleepScoring() - Sleep Scoring on Single EEG channel or use multiple channels
%
% Inputs:
%   EEG            - (struct) struture of data channel
%   EMG            - (struct) struture of data channel (can be empty)
%   Activity       - (struct) struture of data channel (can be empty)
%   options           - (struct) of options
%               (string) options.Scoring.ScoringType (specify which processing algorithm {'Delta','DECISIONTREE','GMMLOGSPECTRUM'}
% 
%         
%         options.Scoring.FFTEpoch = 0.5;
%         options.Scoring.WinOffset = 0;
%         options.Scoring.HzDiv = 0.5;
%         options.Scoring.StageEpoch = 10;
%         options.Scoring.zDeltaThreshold = 0.1;
%         options.Scoring.FFTvalidData = 50;
%         options.Scoring.plot = true;
%         % GMM starting point
%         options.Scoring.useGMMinit = true;
%         
%         % SleepScore Logical Rules
%         options.rules.ApplyArchitectureRules = false;
%         options.rules.SWS2.PercentOfStageEpoch = 45;
%         options.rules.SWS1.PercentOfStageEpoch = 30;
%         options.rules.QW.PercentOfStageEpoch = 60;
%         options.rules.AW.PercentOfStageEpoch = 80;
%         options.rules.PS.PercentOfStageEpoch = 80;
%         options.rules.UNK.PercentOfStageEpoch = 80;
%         options.rules.minStateLength = 10;
% 
%                           (double)    options.SampleRate
%                           (logical)   options.IndexedOutput (assign logical or index output)
%                           (string)    options.algorithm (specify which processing algorithm
%                                       'DC' - use a simple DC threshold
%                                       'RMS' - use the rms of the signal as the simple DC threshold
%                                       'FULL' - fully process signal using several simultaneous approaches
%                           (string)    options.LogFile (file path and name)
%                           (double)    options.DCvalue (simple DC threshold value - mV)
%                           (double)    options.RMSMultiplier (multiply RMS value by this number for simple DC threshold)
%                           (logical)   options.rm2Zero (expand artifacts to zero crossings)
%                           (logical)   options.plot (turn on plotting)
%                           (string)    options.full.DCcalculation (when using 'FULL' type processing, use a 'DC' or 'scaled' simple DC threshold)
%                           (double)    options.full.DCvalue (simple DC threshold value - mV)
%                           (double)    options.full.STDMultiplier (multiply 'scaled' detection by this number for simple DC threshold)
%                           (double)    options.full.minFlatSigLength (Min time in Seconds permitted for signal to be flat)
%                           (double)    options.full.dvValMultiplier (scaline for change in time (samples)) that it takes signal to artifact)
%                           (double)    options.full.MaxDT (Maximum duration (change in time (samples)) that it takes signal to artifact)
%                           (double)    options.full.MinArtifactDuration (In Seconds. All artifacts must have at least this length)
%                           (double)    options.full.CombineArtifactTimeThreshold (in Seconds. Combine artifacts that occur less than this time window)
%
% Outputs:
%   ScoreChannel         - (struct) Channel structure of SleepStages
%       .Name            - (String) Channel Name
%       .Units           - (String) Channel Units (not relevane - Dummey)
%       .nSamples        - (double) Number of Samples
%       .Hz          	 - (double) Sampling Frequency
%       .Data            - (double) Vector of SleepStages (previously called ScoreIndex)
%       .ts              - (double) Vector of timestamps
%       .Lables          - (cell array) vector of lables
%     Possible values of .Data and .Lables are: (new values as of v 2.0)
%     value 5 = 'WAKE-ACTIVE';
%     value 4 = 'WAKE';
%     value 3 = 'SWS1';
%     value 2 = 'SWS2';
%     value 1 = 'PS';
%     value 0 = 'UNSPECIFIED';
%   status              - (logical) return value
%
% Dependencies:
% NSBlog
% Requires:
%   FuzzClust toolbox [http://www.fmt.vein.hu/softcomp/fclusttoolbox/]
%
% ToDo:
% - line 152 time mismatch between FFTEpoch and FinalBinTimeResolution
% - line 167 it would be nice to use NSB_spectral Analysis instesad of
% SSM_Spectrogram
% - segments w/ artifact have less power than full segments. Power needs to be
%   normalized by segment length
% - Line 243,478: combineFFTEpoch needs to combine time as well
% - Add Other Sleep Scoring Methods
% - Return Time Stamp in Score struct
% - add EMG to GMM
% - include delta/theta scoring etc
% - allow DataStruct as inoput and sort out EEG/EMG/Activity channels
% here..
% - include which channel was analyzed
%
%   one of the major problems not dealt with by nLeng is segments w/
%   artifact have less power than full segments. Power needs to be
%   normalized by segment length -or- use Jun Shui approach
%
%   check useage of FFTepoch and Stage Epoch ! << OK
%       Delta = Stage
%       ICA = fft epoch
%
% << figure out which cluster artifact data goes into ...and do we want to
% NaN data aand do a nansum for scorefftepoch
%
%  Better Plotting options;
%
% Written By David M. Devilbiss
% NexStep Biomarkers, LLC. (info@nexstepbiomarkers.com)
% December 8 2011, Version 1.0
% June 28 2013, v 2.0 - Complete redo of many outputs etc.
% Internally scoring vaues remain the same
% Aug 24 2016 v 2.1 - updated for Matlab 2014 new plotting objects

status = false;
DeltaPower = [];
ThetaPower = [];
EMGPower = [];
ScoreChannel = [];

switch nargin
    case {1, 2, 3}
        %SleepScore Detection Parameters (see parm file for description)
        options.Scoring.ScoringType = 'Delta';
        options.Scoring.FFTEpoch = 0.5;
        options.Scoring.WinOffset = 0;
        options.Scoring.HzDiv = 0.5;
        options.Scoring.StageEpoch = 10;
        options.Scoring.zDeltaThreshold = 0.1;
        options.Scoring.FFTvalidData = 50;
        options.Scoring.plot = true;
        options.Scoring.plotTitle = '';
        % GMM starting point
        options.Scoring.useGMMinit = true;
        options.Scoring.force5GMMclusters = false;
        
        % SleepScore Logical Rules
        options.rules.ApplyArchitectureRules = false;
        options.rules.SWS2.PercentOfStageEpoch = 45;
        options.rules.SWS1.PercentOfStageEpoch = 30;
        options.rules.QW.PercentOfStageEpoch = 60;
        options.rules.AW.PercentOfStageEpoch = 80;
        options.rules.PS.PercentOfStageEpoch = 80;
        options.rules.UNK.PercentOfStageEpoch = 80;
        options.rules.minStateLength = 10;
    case 4
        %Check options
        inputError = false;
        %plotting options
        if ~isfield(options,'MatlabPost2014'), options.MatlabPost2014 = false;inputError = true; end
        
        %SleepScore Detection Parameters (see parm file for description)
        if ~isfield(options.Scoring,'ScoringType'), options.Scoring.ScoringType = 'Delta';inputError = true; end
        if ~isfield(options.Scoring,'FFTEpoch'), options.Scoring.FFTEpoch = 0.5;inputError = true; end
        if ~isfield(options.Scoring,'WinOffset'), options.Scoring.WinOffset = 0;inputError = true; end
        if ~isfield(options.Scoring,'HzDiv'), options.Scoring.HzDiv = 0.5;inputError = true; end
        if ~isfield(options.Scoring,'StageEpoch'), options.Scoring.StageEpoch = 10;inputError = true; end
        if ~isfield(options.Scoring,'zDeltaThreshold'), options.Scoring.zDeltaThreshold = 0.1;inputError = true; end
        if ~isfield(options.Scoring,'FFTvalidData'), options.Scoring.FFTvalidData = 50;inputError = true; end
        if ~isfield(options.Scoring,'plot'), options.Scoring.plot = true;inputError = true; end
        if ~isfield(options.Scoring,'plotTitle')
            if ~isfield(options.ArtifactDetection,'plotTitle')
                options.Scoring.plotTitle = '';inputError = true;
            else
                [~, fName,fExt] = fileparts(options.ArtifactDetection.plotTitle{1}); options.Scoring.plotTitle = strcat(fName,fExt); end
        else [~, fName,fExt] = fileparts(options.Scoring.plotTitle{1}); options.Scoring.plotTitle = strcat(fName,fExt); end
        % GMM starting point
        if ~isfield(options.Scoring,'useGMMinit'), options.Scoring.useGMMinit = true;inputError = true; end
        if ~isfield(options.Scoring,'force5GMMclusters'), options.Scoring.force5GMMclusters = false;inputError = true; end
        
        % SleepScore Logical Rules
        if ~isfield(options.rules,'ApplyArchitectureRules'), options.rules.ApplyArchitectureRules = false;inputError = true; end
        if ~isfield(options.rules.SWS2,'PercentOfStageEpoch'), options.rules.SWS2.PercentOfStageEpoch = 45;inputError = true; end
        if ~isfield(options.rules.SWS1,'PercentOfStageEpoch'), options.rules.SWS1.PercentOfStageEpoch = 30;inputError = true; end
        if ~isfield(options.rules.QW,'PercentOfStageEpoch'), options.rules.QW.PercentOfStageEpoch = 60;inputError = true; end
        if ~isfield(options.rules.AW,'PercentOfStageEpoch'), options.rules.AW.PercentOfStageEpoch = 80;inputError = true; end
        if ~isfield(options.rules.PS,'PercentOfStageEpoch'), options.rules.PS.PercentOfStageEpoch = 80;inputError = true; end
        if ~isfield(options.rules.UNK,'PercentOfStageEpoch'), options.rules.UNK.PercentOfStageEpoch = 80;inputError = true; end
        if ~isfield(options.rules,'minStateLength'), options.rules.minStateLength = 10;inputError = true; end
        if inputError
            errorstr = ['Warning: NSB_SleepScoring >> Missing at least 1 options: Missing were set to default(s)'];
            if ~isempty(options.LogFile)
                NSBlog(options.LogFile,errorstr);
            else
                errordlg(errorstr,'NSB_SleepScoring');
            end
        end
    otherwise
        errorstr = 'ERROR: NSB_SleepScoring >> Incorrect number of input parameters';
        errordlg(errorstr,'NSB_SleepScoring');
        return;
end

%check scoring type validity
ScoringType = options.Scoring.ScoringType;
if isempty(EMG) && any(strcmp(upper(ScoringType),'DECISIONTREE'));
    errorstr = ['Warning: NSB_SleepScoring >> Cannot use DECISIONTREE ScoringType with no EMG'];
    if ~isempty(options.LogFile)
        NSBlog(options.LogFile,errorstr);
    else
        errordlg(errorstr,'NSB_SleepScoring');
    end
    return;
end
if options.Scoring.WinOffset > options.Scoring.FFTEpoch
    errorstr = ['Warning: NSBbt_ScoreEngine >> options.Scoring.WinOffset cannot exceed options.Scoring.FFTEpoch. Setting options.Scoring.WinOffset = 0'];
            if ~isempty(options.LogFile)
                NSBlog(options.LogFile,errorstr);
                msg = errorstr;
            else
                msg = errorstr;
            end
     options.Scoring.WinOffset = 0;
end
%If rules are not applied, assign scoring interval to Stage epoch (removed in v1.5
% if ~options.rules.ApplyArchitectureRules
%     options.Scoring.StageEpoch = options.rules.minStateLength;
% end
if options.rules.minStateLength <= options.Scoring.StageEpoch
    %make sure that min state length is at least double so you can examine
    %transitions
    options.rules.minStateLength = options.Scoring.StageEpoch*2;
end

%check if EEG already run (this only works if FFTEpoch == SpectralAnalysis.FinalTimeResolution, which is rare)
if isfield(EEG,'Spectrum') && options.Scoring.FFTEpoch == options.SpectralAnalysis.FinalTimeResolution  %<<< Broken FFTEpoch in min? FinalTime in sec?
    P = EEG.Spectrum;
    T = EEG.Spectrum_ts;
    F = EEG.Spectrum_freqs;
    validBins = EEG.Spectrum_validBins;
else
    %run spectrogram
        
    %broke for now
%     options.SpectralAnalysis.SPTmethod = 'FFT';
%     options.SpectralAnalysis.WindowType = 'Hamming';
%     options.SpectralAnalysis.FinalFreqResolution = options.Scoring.HzDiv;
%     options.SpectralAnalysis.FinalTimeResolution = options.Scoring.FFTEpoch;
%     options.SpectralAnalysis.FFTWindowSize = options.Scoring.FFTEpoch;
%     options.SpectralAnalysis.FFTWindowOverlap = options.Scoring.WinOffset;
%     options.SpectralAnalysis.Artifacts = EEG.Artifacts;
%         [P,CI,T,F,validBins,status] = NSB_SpectralAnalysis(EEG.Data, options.Scoring.FFTEpoch,...
%             options.Scoring.HzDiv, EEG.Hz, options.SpectralAnalysis);
    
    %SSM_Spectrogram can take NaN's as unwanted data and has other nice properties
    %NOTE: P is transposed
    %create artifact IDX vector
    if islogical(EEG.Artifacts) || isempty(EEG.Artifacts)
        Artifact_IDX = EEG.Artifacts;
    elseif isfield(EEG.Artifacts,'intStarts')
        Artifact_IDX = NSB_interval2IDX(EEG.Artifacts,length(EEG.Data),EEG.Hz);
    end
    
    % remove artifact from signal
    EEG.Data(Artifact_IDX) = NaN;

    [F,T,P,validBins] = SSM_Spectrogram(EEG.Data,...
        options.Scoring.FFTEpoch*EEG.Hz,...
        options.Scoring.WinOffset*EEG.Hz,...
        EEG.Hz,...
        options.Scoring.HzDiv);
    
end
options.Scoreindex.freqs = F;
options.Scoreindex.ts = T;

% extract some data before we clear the EEG data
options.File.SampleHz = EEG.Hz;
if islogical(EEG.Artifacts)
    Artifact_IDX = EEG.Artifacts;
elseif isfield(EEG.Artifacts,'intStarts')
    %Convert Intervals 2 Logical
    Artifact_IDX = NSB_interval2IDX(EEG.Artifacts,length(EEG.Data),EEG.Hz);
end

%prep for filtering
numSamplesInFilterWin = ceil(options.Scoring.StageEpoch / options.Scoring.FFTEpoch);

%Get smoothed signal envelope
% sigEnv is of length P
sigEnv = median(buffer(abs(EEG.Data),options.Scoring.FFTEpoch*EEG.Hz),1,'omitnan');
sigEnv(isnan(sigEnv)) = 0;
b = ones(1,numSamplesInFilterWin)./numSamplesInFilterWin;
a = 1;
sigEnv = filtfilt(b,a,sigEnv);

%plot EEG before we clear the data
if options.Scoring.plot
    %Create Spectrogram
    h_fig = figure;
    ax(1) = subplot(2,1,1);
    ph_sig = plot(ax(1),EEG.Data);
    ts = 0:EEG.Hz:length(EEG.Data) / EEG.Hz / 60;
    set(ax(1),'XLim',[0 length(EEG.Data)]);
    if ts(end) <= 60
        if options.MatlabPost2014
            xlabel(ax(1),'Time (mins)');
        else
            xlabel(ph_sig,'String','Time (mins)');
        end
        set(ax(1),'XTick',ts*60*EEG.Hz)
        set(ax(1),'XTickLabel',ts);
    else
        ts = ts/60;
        if options.MatlabPost2014
            xlabel(ax(1),'Time (hours)');
        else
            xlabel(ph_sig,'String','Time (hours)');
        end
        set(ax(1),'XTick',ts*60*60*EEG.Hz)
        set(ax(1),'XTickLabel',ts);
    end
    title(options.Scoring.plotTitle,'FontWeight','bold','Interpreter', 'none');
    if ~isempty(EMG)
        hold on;
        plot(ax(1),EMG.Data + 3);
        legend('EEG','EMG');
        title(ax(1),{'Hypnogram'; options.Scoring.plotTitle; ['EEG-Ch',num2str(EEG.ChNumber), ' ',EEG.Name,...
            ' EMG-Ch',num2str(EMG.ChNumber), ' ',EMG.Name]},'Interpreter', 'none');
    else
        title(ax(1),{'Hypnogram'; options.Scoring.plotTitle; ['EEG-Ch',num2str(EEG.ChNumber), ' ',EEG.Name,...
            ' No EMG Found.']},'Interpreter', 'none');
    end
    if options.MatlabPost2014
        ylabel(ax(1),EEG.Units);
    else
        ylabel(ph_sig,'String',EEG.Units);
    end
end

%% clear EEG Data
clear EEG;

%% Check for over artifacted data
if nnz(validBins)/length(validBins)*100 < options.Scoring.FFTvalidData
    errorstr = ['WARNING>> NSB_SleepScoring: Only ',num2str(nnz(validBins)/length(validBins)*100),' percent of data is valid'];
    if ~isempty(options.LogFile)
        NSBlog(options.LogFile,errorstr);
    else
        errordlg(errorstr,'NSB_SpectralAnalysis');
    end
end

%Generate Spectral norm (total power) << there are other ways to do this i.e. l_1 norm
SpectralNorm = sum(P,2); %get sum for each row (i.e. each time slice)
%OR
%SpectralNorm = norm(P);
NormSpectralMatrix = bsxfun(@rdivide, P, SpectralNorm);
%equivalant to
%   [r,c] = size(P);
%   NormSpectralMatrix = P./(repmat(SpectralNorm,1,c));

%Tramspose P (time in columns)
NormSpectralMatrix = NormSpectralMatrix';


%% Run Sleep Scoring
switch upper(ScoringType)
    
    case 'DELTA' %OK
        %% Delta Scoring of EEG Data (Requires EEG)
        %Build Spectrograms for EEG and EMG signals without artifact
        % [S,F,T,P] = spectrogram(EEG,options.Scoring.FFTEpoch*options.File.SampleHz,0,2*options.File.SampleHz,options.File.SampleHz); %5 sec win/0 sec overlap/0.5 Hz increments/1000Hz SampleRate can send NaN
        DeltaPower = sum(NormSpectralMatrix(2:9,:)); %Delta NormSpectralMatrixower 0.5 - 4 << this is hard coded
        
        %zero out or use average to replace NaN's for filtering
        %Create Indexes of thresholded power
        DeltaPower(~validBins) = mean(DeltaPower(validBins));
        
        
        %Design multirate box filter and smooth
        %2000 Hz 20 data points = resolution of 100 Hz or 0.01 Sec
        %numSamplesInFilterWin = ceil(options.Scoring.StageEpoch / options.Scoring.FFTEpoch);
        b = ones(1,numSamplesInFilterWin)./numSamplesInFilterWin;
        a = 1;
        DeltaPower = filtfilt(b,a,DeltaPower); %eFiltFilt cannot handle NaN or inf. 
        
        
        % run scoring
        ScoreIndex = ones(1,length(1:length(DeltaPower)))*4; %pallette is the length/binned the same as FFT (i.e. 5sec)
        
        %Create Indexes of Delta
        [lambdahat,lambdaci] = poissfit(DeltaPower(validBins),options.Scoring.zDeltaThreshold);
        %if no toolbox, then use:
        %gamStats = NSB_gamfit(DeltaPower(validBins),options.Scoring.zDeltaThreshold);
        DeltaupperPowerIndex = find(DeltaPower > lambdaci(end));
        
        %now mark all as 2 for sws2
        ScoreIndex(DeltaupperPowerIndex) = 2;
        % and not valid bins as unknown
        ScoreIndex(~validBins) = 0;
        
        %Combine FFTEpochs into StageEpochs Using Archetecture Rules
        [ScoreIndex,ScoreIndexTS] = combineFFTEpoch(ScoreIndex,options);
        
        % plot if requested
%         if options.Scoring.plot
%             ssh = figure;
%             plot(T,DeltaPower);
%             hold on;
%             plot(repmat(lambdaci(end),1,ceil(T(end))),'g');
%             plot(0:options.Scoring.StageEpoch:T(end),ScoreIndex,'r');
%             legend('DeltaPower','DeltaThreshold','Somnogram');
%             xlabel('Time (Seconds)');
%         end
        
    case 'DECISIONTREE'
        % Remove Artifact from EMG signal and replace with with zeros instead of artifact
        % EEG was done above
        %EMG(BlankIDX) = 0;
        
        %Build Spectrograms for EEG and EMG signals without artifact
        %         [S,F,T,P] = spectrogram(EEG,options.Scoring.FFTEpoch*options.File.SampleHz,0,2*options.File.SampleHz,options.File.SampleHz); %5 sec win/0 sec overlap/0.5 Hz increments/500Hz SampleRate can send NaN
        DeltaPower = sum(NormSpectralMatrix(2:9,:)); %Delta Power 0.5 - 4
        ThetaPower = sum(NormSpectralMatrix(10:27,:)); %Theta Power 4.5-13
        
        %Spectrum of EMG
         [F,T,P,~] = SSM_Spectrogram(EMG.Data,...
        options.Scoring.FFTEpoch*EMG.Hz,...
        options.Scoring.WinOffset*EMG.Hz,...
        EMG.Hz,...
        options.Scoring.HzDiv);
    
        %Tramspose P (time in columns)
        P = P';
    
       % [S,F,T,P] = spectrogram(EMG,options.Scoring.FFTEpoch*options.File.SampleHz,0,2*options.File.SampleHz,options.File.SampleHz);
        EMGPower = [EMGPower, sum(P(21:91,:))];%EMG Range 10-45
        
        % run scoring
        ScoringIndexPallette = zeros(1,length(1:length(DeltaPower))); %pallette is the length/binned the same as FFT (i.e. 5sec)
        
        %Create Indexes of thresholded power
        DeltaPower(~validBins) = mean(DeltaPower(validBins));
        ThetaPower(~validBins) = mean(ThetaPower(validBins));
        
        % Possibly Smooth
%              b = ones(1,ceil(numSamplesInFilterWin/4))./ceil(numSamplesInFilterWin/4);
              b = ones(1,3)./3;
              a = 1;
              DeltaPower = filtfilt(b,a,DeltaPower);
              ThetaPower = filtfilt(b,a,ThetaPower);
              EMGPower = filtfilt(b,a,EMGPower);
             
        DeltaUpperPowerIndex = find(zscore(DeltaPower) > 0.2*(0-min(zscore(DeltaPower))));   %5sec bins - TRUE above threshold  <--- Make Dynamic
        ThetaUpperPowerIndex = find(zscore(ThetaPower) > 0.5*(0-min(zscore(ThetaPower))));   %5sec bins - TRUE above threshold  <--- Make Dynamic
        UpperThetaDeltaIndex = find(zscore(ThetaPower) > zscore(DeltaPower));                %5sec bins - TRUE Theta above Delta
        UpperEMGPowerIndex = find(zscore(EMGPower) > (min(zscore(EMGPower)))/1.5);           %5sec bins - TRUE above threshold  <--- Make Dynamic
        
        DeltaLowerPowerIndex = find(zscore(DeltaPower) < 0.2*(min(zscore(DeltaPower))) );   %5sec bins - TRUE above threshold  <--- Make Dynamic
        %ThetaLowerPowerIndex = find(zscore(ThetaPower) < 1.5*(min(zscore(ThetaPower))) );   %5sec bins - TRUE above threshold  <--- Make Dynamic
        LowerEMGPowerIndex = find(zscore(EMGPower) < (min(zscore(EMGPower)))/1.1 );           %5sec bins - TRUE above threshold  <--- Make Dynamic
        psEMGPowerIndex = find( zscore(EMGPower) <= (min(zscore(EMGPower)) - min(zscore(EMGPower)) * 0.1) );
        
        sigEnvIndex = find( sigEnv > (max(sigEnv) - min(sigEnv)) /2 );
        
        
        %Build vector of 30 second scoring using some stragity of a
        %Decision Tree of a given state
        ScoreIndex = [];
        windowSize = options.Scoring.StageEpoch/options.Scoring.FFTEpoch;
        
        EpochScoreMat = [];
        for i = 1:windowSize:length(ScoringIndexPallette)
            %Build EpochScore [how many FFTEpochs are there in a StageEpoch]
            ArtifactIDX_Start = (i-1)*options.Scoring.FFTEpoch*options.File.SampleHz+1;
            ArtifactIDX_End = (i-1+windowSize)*options.Scoring.FFTEpoch*options.File.SampleHz;
            if ArtifactIDX_End > length(Artifact_IDX), ArtifactIDX_End = length(Artifact_IDX); end

            EpochScore = [ ...
                length(find(Artifact_IDX(ArtifactIDX_Start:ArtifactIDX_End) == true)), ...
                length(find(i <= UpperEMGPowerIndex & UpperEMGPowerIndex < i+windowSize)),...
                length(find(i <= UpperThetaDeltaIndex & UpperThetaDeltaIndex <= i+windowSize)),...
                length(find(i <= ThetaUpperPowerIndex & ThetaUpperPowerIndex <= i+windowSize)),...
                length(find(i <= DeltaUpperPowerIndex & DeltaUpperPowerIndex <= i+windowSize)),...
                length(find(i <= LowerEMGPowerIndex & LowerEMGPowerIndex < i+windowSize)),...
                length(find(i <= psEMGPowerIndex & psEMGPowerIndex <= i+windowSize)),...
                length(find(i <= DeltaLowerPowerIndex & DeltaLowerPowerIndex <= i+windowSize)),... 
                length(find(i <= sigEnvIndex & sigEnvIndex <= i+windowSize)),...
                ];
            EpochScoreMat = [EpochScoreMat; EpochScore];
            
             %Test for Active Wake
             % if there is more than 20% artifact or High EMG > 50% or the
             % time AND less than 50% high delta (1500, 30, 30)
             if (EpochScore(1) > options.File.SampleHz * options.Scoring.StageEpoch*0.2 ...
                     || EpochScore(2) > windowSize*options.rules.AW.PercentOfStageEpoch/100) ...
                     && (EpochScore(5) < windowSize*0.5 || EpochScore(8) > 0)
                tempScoreIndex = 5;
                ScoreIndex = [ScoreIndex tempScoreIndex];                                  %Concatinate Latest score
                continue;
             end
            
            %Test for SWS2
            %High Delta >= 50% of the time AND Low muscle tone
            % (SWS2 = High Delta >= 50% of the
            %time) and 10% EMG
            if EpochScore(5) >= windowSize*options.rules.SWS2.PercentOfStageEpoch/100 && ...
                    (EpochScore(2) < windowSize*0.1 || EpochScore(6) > windowSize*0.5)      %stable and low EMG
                tempScoreIndex = 2;                                                         %Epoch 19
                ScoreIndex = [ScoreIndex tempScoreIndex];                                  %Concatinate Latest score
                continue;
            end
            
            %Test for REM (difinitive (lowest 10% EMG AND Theta > Delta AND Low Delta
            if ~isempty(ScoreIndex)
                if EpochScore(7) > windowSize*0.25 && EpochScore(3) > windowSize*options.rules.PS.PercentOfStageEpoch/100
                    if EpochScore(8) > windowSize*options.rules.QW.PercentOfStageEpoch/100
                         tempScoreIndex = 1;
                         ScoreIndex = [ScoreIndex tempScoreIndex];                                  %Concatinate Latest score
                    continue;
                    end
                end
            end
                
            
            %Test for REM = Low Delta and Theta Power (10%) and previous score (how many) was not wake
            if ~isempty(ScoreIndex)
                if (EpochScore(4) <= 1 && EpochScore(5) <= 1) &&  (ScoreIndex(end) < 5 && ScoreIndex(end) ~= 0)
                    if length(find(ScoreIndex(end-1:end) <= 3)) == 2
                        tempScoreIndex = 1;
                    else
                        tempScoreIndex = 4;
                    end
                    ScoreIndex = [ScoreIndex tempScoreIndex];                                  %Concatinate Latest score
                    continue;
                end
            end
            
            %Test for SWS1 = High Delta OR Theta Power >= 50% of the time
            if EpochScore(4) >= windowSize*0.5 || EpochScore(5) >= windowSize*0.5
                if EpochScore(2) < windowSize*0.1   %without movement
                    tempScoreIndex = 2;
                elseif EpochScore(2) > windowSize*0.5
                    tempScoreIndex = 5;
                else                                %with movement
                    tempScoreIndex = 4;
                end
                ScoreIndex = [ScoreIndex tempScoreIndex];                                  %Concatinate Latest score
                continue;
            end
            
            %Test for QW
            if ((EpochScore(4) + EpochScore(5)) > 1) && (EpochScore(3) >= 2*EpochScore(4)) %All based on Spectral power
                if ~isempty(ScoreIndex)
                if ScoreIndex(end) == 5                                                %push up to QW if previous was AW
                    tempScoreIndex = 4;
                elseif EpochScore(2) > 0 || EpochScore(9) < windowSize*0.5             %any above average EMG = QW
                    tempScoreIndex = 4;
                else
                    tempScoreIndex = 3;                 %epoch 12, 16, 17 SWS1
                end
                ScoreIndex = [ScoreIndex tempScoreIndex];                                  %Concatinate Latest score
                continue;
                else
                if all(EpochScore([6,8]) < 1)             %there is some general activity
                    tempScoreIndex = 4;
                    ScoreIndex = [ScoreIndex tempScoreIndex];                                  %Concatinate Latest score
                    continue;
                end
                end
            end
            
            %Test for QW = High Theta/Delta Ratio >= 50% of the time
            if EpochScore(3) > windowSize*0.5
                tempScoreIndex = 4;
                ScoreIndex = [ScoreIndex tempScoreIndex];                                  %Concatinate Latest score
                continue;
            end
            if ((EpochScore(4) + EpochScore(5)) <= 1) && (EpochScore(3) >= 1)   %QW (< to <=)
                tempScoreIndex = 4;
                ScoreIndex = [ScoreIndex tempScoreIndex];                                  %Concatinate Latest score
                continue;
            end
            if ((EpochScore(4) + EpochScore(5)) <= 1) && (EpochScore(2) >= 0)   %QW (< to <=) some muscle tone but average spectra power
                tempScoreIndex = 4;
                ScoreIndex = [ScoreIndex tempScoreIndex];                                  %Concatinate Latest score
                continue;
            end
            
            
            if EpochScore(9) < windowSize*0.25
                tempScoreIndex = 4;%QW
                ScoreIndex = [ScoreIndex tempScoreIndex];                                  %Concatinate Latest score
            else
            % Unknown
            tempScoreIndex = 0;
            ScoreIndex = [ScoreIndex tempScoreIndex];                                  %Concatinate Latest score
            end
        end
        
         if ~isempty(options.Scoreindex.ts)
         ScoreIndexTS = options.Scoreindex.ts(1:windowSize:end);
         %check Length
         if length(ScoreIndexTS) ~= length(ScoreIndex)
             ScoreIndexTS = NaN;
         end
         end

%Archived Version (Version 1)
%             %Test for Active Wake = Active OR 20%Artifact OR 50% High EMG
%             if (EpochScore(1) > options.File.SampleHz*options.Scoring.StageEpoch*0.2 ...
%                     || EpochScore(2) > windowSize/2) &&  EpochScore(5) < windowSize*0.5
%                 tempScoreIndex = 5;
%                 
%                 %Test for Low muscle tone (SWS2 = High Delta >= 50% of the time)
%             else
%                 %Test for SWS2 = High Delta >= 50% of the time
%                 if EpochScore(5) >= windowSize*0.5 && EpochScore(1) < options.File.SampleHz*options.Scoring.StageEpoch*0.2 ...
%                     && EpochScore(2) < windowSize/2
%                     tempScoreIndex = 2;
%                     %Test for REM = Low Delta and Theta Power (10%) and previous score (how many) was not wake
%                 elseif (EpochScore(4) <= 1 & EpochScore(5) <= 1) &&  (ScoreIndex(end) < 5 & ScoreIndex(end) ~= 0)
%                     if length(find(ScoreIndex(end-1:end) <= 3)) == 2
%                         tempScoreIndex = 1;
%                     else
%                         tempScoreIndex = 4;
%                     end
%                     %Test for SWS1 = High Delta OR Theta Power >= 50% of the time
%                 elseif EpochScore(4) >= windowSize*0.5 | EpochScore(5) >= windowSize*0.5
%                     tempScoreIndex = 3;
%                     %Test for
%                 elseif ((EpochScore(4) + EpochScore(5)) > 1) && (EpochScore(3) >= 2*EpochScore(4)) %
%                     if ScoreIndex(end) == 5                                                %push up to QW if previous was AW
%                         tempScoreIndex = 4;
%                     else
%                         tempScoreIndex = 3;
%                     end
%                     %Test for QW = High Theta/Delta Ratio >= 50% of the time
%                 elseif EpochScore(3) > windowSize*0.5
%                     tempScoreIndex = 4;
%                 elseif ((EpochScore(4) + EpochScore(5)) <= 1) && (EpochScore(3) >= 1)   %QW (< to <=)
%                     tempScoreIndex = 4;
%                 else
%                     tempScoreIndex = 0;                                                    %Unknown
%                 end
%             end
%             ScoreIndex = [ScoreIndex tempScoreIndex];                                  %Concatinate Latest score
%         end
        
        %Combine FFTEpochs into StageEpochs
        %[ScoreIndex,ScoreIndexTS] = combineFFTEpoch(ScoreIndex,options);
        %Do not perform - already combined !!!
        
    case 'GMMLOGSPECTRUM'
        disp('Running GMM log Spectrum');
        %% logarithmically bin spectrum and use as input for GMM clustering
        
        %clean up PSD
        NormSpectralMatrix(1,:) = []; %Remove DC component
        F(1) = [];
        
        %truncate to 50 Hz
        NormSpectralMatrix = NormSpectralMatrix(1:find(F <= 50,1, 'last'),:);
        F = F(1:find(F <= 50,1, 'last'));
        
        %Do some temporal smoothing
        % Method 1 (3x faster unvalidated)
        %     b = ones(1,numSamplesInFilterWin)./numSamplesInFilterWin;
        %     a = 1;
        % for curHz = 1:size(P,1);
        %     smP(curHz,:) = filtfilt(b,a,P(curHz,:));
        % end
        %Method 2
        disp('... Temporal Smoothing LogSpectra');
        if rem(numSamplesInFilterWin,2)==0
            numSamplesInFilterWin=numSamplesInFilterWin-1;
        end
        Startbin = ceil(numSamplesInFilterWin/2);
        for curHz=1:size(NormSpectralMatrix,1)
            ConvMat = convmtx(NormSpectralMatrix(curHz,:),numSamplesInFilterWin);
            smP(curHz,:) = mean(ConvMat(:, Startbin:end-Startbin+1));
        end
        
        % generate logarithmic binning
        X = floor(logspace(0,log10(50),10)) +1;
        %   [0,2,3,4,6,9,14,21, 33,50]
        %X = floor(logspace(F(1),log10(50),10));
        %forced divisions
        %X = [0,2,3,4,5,7,12,16,30,50];

        Xoffset = [0,-1,0,0.5,0.5,-0.5,-1.5, -3, -3, 0];
        X = X + Xoffset;
        X(1) = F(1);
        counter = 1;
        for n = 1:length(X)-1
            fStart = find(F == X(n),1);
            fEnd = find(F == X(n+1),1);
            rebinPSD(counter,:) = mean(smP(fStart:fEnd,:),1); %average smooth power (i.e. Bin 1 = 0.5-2 hz) 
            rebinFreq(counter) = F(fStart);
            counter = counter +1;
        end
        
        %Transpose PSD so time is in rows
        rebinPSD = rebinPSD';
        
        %do GMM clustering
        disp('... Running GMM Clustering');
        fitOpts = statset('Display','final');
        
        % get optimal number of clusters with all the data ???
        %sequentially fit data with increasing numbers of clusters.
        % stop if second cluster is not sig diferent
        % ToDo add breakpoint analysis from previous code
        
        warning off;
        TotalNumClusters = 5;
        ChiCDF = []; idx = [];
        BIC=ones(1,TotalNumClusters) * NaN;
        if options.Scoring.useGMMinit %< Option 1 using initialization parameters for 5 states
            try
                minnumComponents = length(options.Scoring.GMMinit.PComponents);
                obj = gmdistribution.fit(rebinPSD(validBins,:), minnumComponents, 'Start', options.Scoring.GMMinit);
                warning on;
                disp(['Final Number of Clusters = ',num2str(minnumComponents)]);
                [idx,nlogl,NormSpectralMatrix] = cluster(obj,rebinPSD);
            catch ME
                errorstr = ['Warning: NSB_SleepScoring >> GMM Clustering Failed ',ME.message];
                if ~isempty(options.LogFile)
                    NSBlog(options.LogFile,errorstr);
                else
                    errordlg(errorstr,'NSB_SleepScoring');
                end
            end
        else
            if options.Scoring.force5GMMclusters %< Option 2 force 5 states w/o initial starting point
                try
                    minnumComponents = 5;
                    obj{minnumComponents} = gmdistribution.fit(rebinPSD(validBins,:), 5, 'Start', 'randSample', 'Replicates', 5);
                catch ME
                    errorstr = ['Warning: NSB_SleepScoring >> GMM Clustering Failed ',ME.message];
                    if ~isempty(options.LogFile)
                        NSBlog(options.LogFile,errorstr);
                    else
                        errordlg(errorstr,'NSB_SleepScoring');
                    end
                    disp(ME);
                end
                
            else
                for n=1:TotalNumClusters %< Option 3 iterate and find the number of states w/o initial starting point
                    disp(['... Running GMM Cluster Size: ',num2str(n)]);
                    try
                        obj{n} = gmdistribution.fit(rebinPSD(validBins,:), n, 'Start', 'randSample', 'Replicates', 5);
                        BIC(n) = obj{n}.BIC;
                        if n == 2
                            %do deviance test to see if 1st 2 clusters are truely diferent
                            difdev = abs(obj{n}.NlogL - obj{n-1}.NlogL);
                            df = n - (n-1);
                            ChiCDF = 1 - chi2cdf(difdev, df);
                            if ChiCDF >= 0.01 || max(rebinPSD(validBins,3)) <= 2* mean(rebinPSD(validBins,3)) % << soft code this !!
                                % no Wake and Sleep
                                break;
                            end
                        end
                    catch ME
                        errorstr = ['Warning: NSB_SleepScoring >> GMM Clustering Failed ',ME.message];
                        if ~isempty(options.LogFile)
                            NSBlog(options.LogFile,errorstr);
                        else
                            errordlg(errorstr,'NSB_SleepScoring');
                        end
                        disp(ME);
                        BIC(n)=NaN;
                    end
                end
            end

            if ~isempty(ChiCDF)
                [minBIC,minnumComponents] = min(BIC);
                disp(['Final GMM Cluster Size = ',num2str(minnumComponents)]);
                if minnumComponents > 5         % <<<< finds break point in BIC curve (Scree test) to choose the number of states when over 5 states
                    for j=2:TotalNumClusters
                        if length(BIC) >= 10
                            ypredict=detrend(BIC(2:10),'linear',[j-1]);
                        else
                            ypredict=detrend(BIC(2:end),'linear',[j-1]);
                        end
                        SumSquare(j-1)=sum(ypredict.^2);
                    end
                    [MinSS,breakPt]=min(SumSquare);
                    minBIC = BIC(breakPt +1);
                    minnumComponents = breakPt +1;
                end
            elseif ~options.Scoring.force5GMMclusters
                minBIC = NaN;
                minnumComponents = 1;
            end
            warning on;
            disp(['Final Number of Clusters = ',num2str(minnumComponents)]);
            try
                [idx,nlogl,NormSpectralMatrix] = cluster(obj{minnumComponents},rebinPSD); %n=1 obj unrecognized
            catch ME
                errorstr = ['Error: NSB_SleepScoring >> GMM cannot generate even 1 Cluster - Failed ',ME.message];
                if ~isempty(options.LogFile)
                    NSBlog(options.LogFile,errorstr); 
                    disp(errorstr);
                else
                    errordlg(errorstr,'NSB_SleepScoring');
                end
                %idx = zeros(1,size(rebinPSD,1));
                %return; %Scoring a dead channel has issues and throws errors
            end
        end
        
        %ToDo: incorporate probabilities

        %Now identify clusters
        % 1st Gather spectra means
        for n = 1:minnumComponents
            meanSpectra(n,:) = mean(rebinPSD(idx == n,:));
        end
        % identify empty clusters and remove
        isNaN_idx = isnan(meanSpectra(:,1));
        meanSpectra = meanSpectra(~isNaN_idx,:);

        % 2nd apply simple classification (labeling) scheme
        % assign each cluster an internal state value to be used by archetecture rules and to combine epochs
        % rowIdx = [N3idx,N1idx,QWidx,Widx,Ridx]; %orders the clusters by state
        % scoringSet = [2,3,4,5,1]; %scoring order sws2, sws1, wake, aw, ps

        StateLookup = cell(6,3); % State name; scoringSet; cluster number
        StateLookup(:,1) = {'SWS2'; 'SWS1'; 'QW'; 'AW'; 'PS'; 'UNK'};
        StateLookup(:,2) = {2;3;4;5;1;0};
        StateLookup(:,3) = num2cell(ones(1,6)*NaN);

        % AASM 2026 v3
        if ~isempty(meanSpectra)
        %[N3idx,N1idx,QWidx,Widx,Ridx] = deal(NaN);
        %N3 0.5-2Hz that are > 20% of the 30 sec epoch
        [~, N3idx] = sortrows(meanSpectra,[-2 -3],'MissingPlacement','last'); %N3 sort in decending order by delta power
        if sum(meanSpectra(N3idx(1),2:3),2) > sum(meanSpectra(N3idx(1),5:6),2)
            %Then it really is SWS2/N3
            %N3idx = N3idx(1);
            StateLookup{1,3} = N3idx(1);
        else
            LogStr = ['Warning: NSB_SleepScoring >> GMM Cannot find N3/SWS'];
            disp(LogStr);
            NSBlog(options.LogFile,LogStr);
        end

        % Rem Sawtooth waves 2-6 Hz,LAMF w/o spindles or K-complexes
        [~, Ridx] =sortrows(sum(meanSpectra(:,4:5),2),[-1],'MissingPlacement','last'); %R sort in decending order by Theta power (4.5-8.5Hz)
        %Ridx = Ridx(1);
        StateLookup{5,3} = Ridx(1);

        %N1 LAMF 4-7 Hz > 50% of the epoch + more power in slow Hz
        %N2 K-complex, Sleep Spindle 11-16 Hz > 50% of the epoch
        % Waking alpha activity 8-13 Hz
        [~, rowIdx] = sortrows(meanSpectra,[-4],'MissingPlacement','last'); %decending order by low Theta power (4.5-6.5Hz)
        rowIdx(find(rowIdx==StateLookup{1,3} | rowIdx==StateLookup{5,3})) = [];

        if sum(~isNaN_idx) == 5 %All 5 states exist

            %N1 LAMF 4-7 Hz > 50% of the epoch + more power in slow Hz
            %Delta 2+3 / Beta 6+7 (Ratio)
            [~, N12idx] =sortrows(sum(meanSpectra(rowIdx,2:3),2)./sum(meanSpectra(rowIdx,6:7),2),[-1],'MissingPlacement','last'); %N1 sort in decending order by delta/beta power
            %N1idx = rowIdx(N12idx(1));
            StateLookup{2,3} = rowIdx(N12idx(1));

            % Waking alpha activity 8-13 Hz (with Theta)
            %Widx = rowIdx(N12idx(end));
            StateLookup{4,3} = rowIdx(N12idx(end));

            %Quiet waking
            QWidx = 1:n;
            %QWidx([Widx,N1idx,N3idx,Ridx]) = [];
            temp = cell2mat(StateLookup(:,3));  temp(isnan(temp))=[];
            QWidx(temp) = [];
            StateLookup{3,3} = QWidx; 
            if length(QWidx) > 1
                StateLookup{3,3} = QWidx(1); %Use only the first cluster and set the second to unknown
                LogStr = ['Warning: NSB_SleepScoring >> GMM Cannot find a single QW state'];
                disp(LogStr);
                NSBlog(options.LogFile,LogStr);
            end


        elseif sum(~isNaN_idx) == 4 % Only 4 states exist
            %N1 LAMF 4-7 Hz > 50% of the epoch + more power in slow Hz
            %Delta 2+3 / Beta 6+7 (Ratio)
            [~, N12idx] =sortrows(sum(meanSpectra(rowIdx,2:3),2)./sum(meanSpectra(rowIdx,6:7),2),[-1],'MissingPlacement','last'); %N1 sort in decending order by delta/beta power
            %N1idx = rowIdx(N12idx(1));
            StateLookup{2,3} = rowIdx(N12idx(1));

            % Waking alpha activity 8-13 Hz (with Theta)
            %Widx = rowIdx(N12idx(end));
            StateLookup{4,3} = rowIdx(N12idx(end));

            LogStr = ['Warning: NSB_SleepScoring >> GMM only found 4 states'];
            disp(LogStr);
            NSBlog(options.LogFile,LogStr);

        elseif sum(~isNaN_idx) == 3 % Only 3 states exist
            %Final states are SWS2, AW/PS, QW/N1
            %QWidx = rowIdx;
            StateLookup{3,3} = rowIdx;

            LogStr = ['Warning: NSB_SleepScoring >> GMM only found 3 states'];
            disp(LogStr);
            NSBlog(options.LogFile,LogStr);
        else
            LogStr = ['Warning: NSB_SleepScoring >> GMM only found 2 states'];
            disp(LogStr);
            NSBlog(options.LogFile,LogStr);
        end

        % rowIdx = [N3idx,N1idx,QWidx,Widx,Ridx]; %orders the clusters by state
        % scoringSet = [2,3,4,5,1]; %scoring order sws2, sws1, wake, aw, ps
        % 
        % %old
        % %[DeltaSort, rowIdx] = sortrows(meanSpectra,[-2 -3]); %sort in decending order by delta power
        % %isNaN_idx = isnan(DeltaSort(:,1));
        % 
        % switch minnumComponents
        %     case 1
        %         if ~isnan(N3idx)
        %             scoringSet = [2];
        %         elseif ~isnan(Ridx)
        %             scoringSet = [4];
        %         else
        %             scoringSet = [0];
        %         end
        %     case 2
        %         scoringSet = [2,4];
        %     case 3
        %         scoringSet = [2,3,5];
        %     case 4
        %         scoringSet = [2,3,4,5];
        %     case 5
        %         scoringSet = [2,3,4,5,1]; %scoring order sws2, sws1, wake, aw, ps
        %     otherwise
        %         scoringSet = [2,3,4,5,1]; %scoring order sws2, sws1, wake, aw, ps
        % end
        % 
        % %rowIdx(isNaN_idx,:) = [];
        % %DeltaSort(isNaN_idx,:) = [];
        
        % plot if requested
        if options.Scoring.plot
            fh = figure('Units','inches','ToolBar','none');
            fh.Position = [fh.Position(1), -0.1, 8, 10.5];
            t = tiledlayout('flow','TileSpacing','Compact');
            CurAxis(n) = nexttile(1,[2 2]);
            switch sum(~isNaN_idx)
                case 1
                   ph_spect = plot(meanSpectra');
                   %CurAxis = get(fh,'Children');
                   if ~isnan(StateLookup{1,3})
                    legend(CurAxis(n), 'SWS2');
                   else
                   legend(CurAxis(n), 'QW/AW/PS'); 
                   end
                case 2
                   ph_spect = plot(meanSpectra([StateLookup{1,3},StateLookup{5,3}],:)');
                   %CurAxis = get(fh,'Children');
                   legend(CurAxis(n),'SWS2','QW/AW/PS'); 
                case 3
                    ph_spect = plot(meanSpectra([StateLookup{1,3},StateLookup{3,3},StateLookup{5,3}],:)');
                    %CurAxis = get(fh,'Children');
                   legend(CurAxis(n),'SWS2','QW/SWS1','AW/PS'); 
                case 4
                    ph_spect = plot(meanSpectra([StateLookup{1,3},StateLookup{2,3},StateLookup{4,3},StateLookup{5,3}],:)');
                    %CurAxis = get(fh,'Children');
                   legend(CurAxis(n),'SWS2','SWS1','AW','PS'); 
                otherwise
                    ph1_rows = [StateLookup{:,3}]; ph1_rows = ph1_rows(~isnan(ph1_rows));
                    ph_spect = plot(meanSpectra(ph1_rows,:)');
                    legend(CurAxis(n),StateLookup{ph1_rows,1});
            end
            title(CurAxis(n),{'GMMlogSpectrum Cluster Profiles'; options.Scoring.plotTitle; ['EEG-Ch',num2str(EEG.ChNumber), ' ',EEG.Name]},...
                'Interpreter', 'none');

            if options.MatlabPost2014
                xlabel(CurAxis(n),'Frequency (Hz)');
                ylabel(CurAxis(n),'Normalized Power');
            else
                xlabel(ph_spect,'String','Frequency (Hz)');
                ylabel(ph_spect,'String','Normalized Power');
            end
            set(CurAxis(n),'XTickLabel',rebinFreq);

            for n = 1:size(StateLookup,1)
                CurAxis(n+1) = nexttile;
                plotdata = decimate(ph_sig.YData, ceil(length(ph_sig.YData) / length(idx)),'fir');
                plotts = decimate(ph_sig.XData, ceil(length(ph_sig.YData) / length(idx)),'fir');
                plot(plotts,plotdata,'Color',[0.8,0.8,0.8]); hold on;
                plotdata(idx ~= n) = NaN;
                plot(plotts,plotdata,'color','b');
                try
                title(CurAxis(n+1),StateLookup{cell2mat(StateLookup(:,3)) == n,1});
                catch
                  title(CurAxis(n+1),'UNK');
                end
                set(CurAxis(n+1),'XTick',ax(1).XTick)
                set(CurAxis(n+1),'XTickLabel',ax(1).XTickLabel);
                if options.MatlabPost2014
                    set(CurAxis(n+1),'XLabel',ax(1).XLabel);
                    set(CurAxis(n+1),'YLabel',ax(1).YLabel);
                else
                    set(CurAxis(n+1),'XLabel',ph_sig.XLabel);
                    set(CurAxis(n+1),'YLabel',ph_sig.YLabel);
                end
            end
            linkaxes(CurAxis(2:end),'xy');



            disp(['NSB_SleepScoring - Saving GMMlogSpectrum Cluster Profiles Plot...']);
            hgsave(h_fig, fullfile(logpath,['GMMlogSpectrumClusterProfileFig_',num2str(now),'.fig']), '-v7.3');
            if ~isempty(options.LogFile)
                print(fh,'-dpdf', fullfile(fileparts(options.LogFile),['GMMlogSpectrumClusterProfileFig_',num2str(now),'.pdf']) );
            else
                print(fh,'-dpdf', fullfile(cd,['GMMlogSpectrumClusterProfileFig_',num2str(now),'.pdf']) );
            end
            close(fh);
        end
        
        %assign scoring to clusters
        ScoreIndex = zeros(1,size(rebinPSD,1)); %scoring pallette is the length/binned the same as FFT (i.e. 5sec)
        for n = 1:size(StateLookup,1)
            % 
            if any(cell2mat(StateLookup(:,3)) == n) % did we assign a state to cluster n?
                ScoreIndex(idx == n) = StateLookup{cell2mat(StateLookup(:,3)) == n,2}; %find cluster in StateLookup and return the scoringSet and assign to ScoreIndex
            end
        end
        else 
        ScoreIndex = zeros(1,size(rebinPSD,1)); %scoring pallette is the length/binned the same as FFT (i.e. 5sec)
        end
          
        %debug
        %save testFile
        
        %Combine FFTEpochs into StageEpochs
        [ScoreIndex,ScoreIndexTS] = combineFFTEpoch(ScoreIndex,options); %<<< Need to combine time and rebin << here is where we need to return new .ts  << F and T are idnetial to ScoreIndex here
        
    otherwise
        errorstr = ['Warning: NSB_SleepScoring >> Incorrect Analyses'];
        if ~isempty(options.LogFile)
            NSBlog(options.LogFile,errorstr);
        else
            errordlg(errorstr,'NSB_SleepScoring');
        end
        return;
end

% %Archtecture Rules
if options.rules.ApplyArchitectureRules
    disp('Applying Architecture Rules...');
    ScoreIndex = ArchitectureRules(ScoreIndex, options);
end

% Generate Sleep Score Channel

ScoreChannel.Name = 'Hypnogram';
ScoreChannel.Units = 'Categorical';
ScoreChannel.nSamples = length(ScoreIndex);
ScoreChannel.Hz = 1/options.Scoring.StageEpoch;
ScoreChannel.ts = ScoreIndexTS;
% ScoreChannel.Data = ScoreIndex(:);
% ScoreChannel.DigMin = -32768;
% ScoreChannel.DigMax = 32767;
% ScoreChannel.PhysMin = 0;
% ScoreChannel.PhysMax = 10;

%  If a hypnogram is stored as an ordinary signal,
%sleep stages W,1,2,3,4,R,M should be coded in the data records as the
%integer numbers 0,1,2,3,4,5,6 respectively. Unscored epochs should be
%coded as the integer number 9. ... So this is wrong..

%This is terribly inneficient, will fix later
for n = 1:length(ScoreIndex)
    %there are 6 possible states [0:5] each representing a sleepstage
    switch ScoreIndex(n)
        case 0 %unspecified State
            label = 'UNSPECIFIED';
            ScoreChannel.Data(n,1) = 9;
        case 1 %paradoxical sleep
            label = 'PS';
            ScoreChannel.Data(n,1) = 5;
        case 2 %SW sleep (2)
            label = 'SWS2';
            ScoreChannel.Data(n,1) = 4;
        case 3 %SW sleep (1)
            label = 'SWS1';
            ScoreChannel.Data(n,1) = 2;
        case 4 %waking
            label = 'WAKE';
            ScoreChannel.Data(n,1) = 1;
        case 5 %active wake
            label = 'WAKE-ACTIVE';
            ScoreChannel.Data(n,1) = 0;
        otherwise %unspecified State
            label = 'Unknown';
            ScoreChannel.Data(n,1) = 9;
    end
    ScoreChannel.Labels{n,1} = label;
end
clear ScoreIndex;

if options.Scoring.plot
    %Create Hypnogram
    ax(2) = subplot(2,1,2);
    hold on;
    ph_hyp = plot(ax(2),ScoreChannel.Data,'k');
    psIDX = NaN(length(ScoreChannel.Data),1);
    psIDX(ScoreChannel.Data == 5) = 5;
    ph{3} = plot(ax(2),psIDX,'r','LineWidth',5);
    set(ax(2),'YTick',0:5);
    set(ax(2),'YTickLabel',{'WAKE-ACTIVE','WAKE','SWS1','','SWS2','PS'});
    set(ax(2),'YLim',[-1 6])
    ts =  (0:options.Scoring.StageEpoch:(length(ScoreChannel.Data)*options.Scoring.StageEpoch)) /60; %in minutes
    set(ax(2),'XLim',[0 length(ts)]);
    if ts(end) <= 60
        if options.MatlabPost2014
            xlabel(ax(2),'Time (mins)');
        else
            xlabel(ph_hyp,'String','Time (mins)');
        end
        set(ax(2),'XTick',ts(1:find(ts==60)-1:end)+1);
        set(ax(2),'XTickLabel',ts(1:find(ts==60)-1:end)/(60*60));
    else
        ts = ts/60;
        if options.MatlabPost2014
            xlabel(ax(2),'Time (hours)');
        else
            xlabel(ph_hyp,'String','Time (hours)');
        end
        set(ax(2),'XTick',1:find(ts==1)-1:length(ts));
        set(ax(2),'XTickLabel',ts(1:find(ts==1)-1:end));
    end
    disp(['NSB_SleepScoring - Saving Hypnogram Plot...']);
    hgsave(h_fig, fullfile(logpath,['Hypnogram-Fig_',num2str(now),'.fig']), '-v7.3');
    if ~isempty(options.LogFile)
        print(h_fig,'-dpdf', fullfile(fileparts(options.LogFile),['Hypnogram-Fig_',num2str(now),'.pdf']) );
    else
        print(h_fig,'-dpdf', fullfile(cd,['Hypnogram-Fig_',num2str(now),'.pdf']) );
    end
    close(h_fig);
end

status = true;

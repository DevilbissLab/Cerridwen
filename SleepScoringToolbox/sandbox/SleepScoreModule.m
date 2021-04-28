function [ScoreIndex, ValidScoreIndex] = SleepScoreModule(EEG,EMG,params)
%
% SleepScoreModule - Main Sleep Scoring Engine
%
% Usage:
%  >> [ScoreStruct,ScoreIndex,BlankIDX,ArtifactStruct] =
%  SleepScoreModule(EEG,EMG,params,ArtifactStruct,StimulusStruct)
%
% Inputs:
%   EEG             - vector of analog values (i.e. EEG);
%   EMG             - vector of analog values (empty indicates no EMG);
%   params          - struct of parameters from ParamaterFile;
%
% Outputs:
%   ScoreIndex      - vector of Sleep Stages of size params.Scoring.StageEpoch
%
% See also:
%   ParameterFile for framework settings.
%   RodentSleepScoring (caller)
%
% Requires:
%   FastICA toolbox [http://www.cis.hut.fi/projects/ica/fastica]
%   FuzzClust toolbox [http://www.fmt.vein.hu/softcomp/fclusttoolbox/]
%
% Copyright (C) 2010 by David Devilbiss <ddevilbiss@wisc.edu>
%
% ToDo:
%   ICA without EMG more clusters than with EMG i.e. 3 vs 5 clusters
%   ICA not working, Check nLeng fail
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
%returns a vector of numbers
%Quick function to generate new text from numeric values
% function [ScoreStr] = getNewScores(NewScore)
% switch NewScore
%     case 5
%         ScoreStr =  'ANIMAL-WAKE-ACTIVE';
%     case 4
%         ScoreStr =  'ANIMAL-WAKE';
%     case 3
%         ScoreStr =  'ANIMAL-SWS1';
%     case 2
%         ScoreStr =  'ANIMAL-SWS2';
%     case 1
%         ScoreStr =  'ANIMAL-PS';
%     otherwise
%         ScoreStr =  'ANIMAL-UNSPECIFIED';
% end
%
ScoringType = params.Scoring.ScoringType;
if isempty(EMG) & any(...
        strcmp(upper(ScoringType),'DECISIONTREE'));
    error 'cannot use this ScoringType with no EMG'
    return;
end

DeltaPower = [];
ThetaPower = [];
EMGPower = [];
ScoreIndex = [];
%params.Scoring.HzDiv = 0.5; %hz division sin spectrum. Slightly slower than nexpow2 We know what each bin is
numSamplesInFilterWin = ceil(params.Scoring.StageEpoch / params.Scoring.FFTEpoch);


%every case is based on FFT so do this up front;
%SSM_Spectrogram can take NaN's as unwanted data and has other nice properties 
%NOTE: P is transposed
[F,T,P,validBins] = SSM_Spectrogram(EEG,...
    params.Scoring.FFTEpoch*params.File.SampleHz,...
    params.Scoring.WinOffset*params.File.SampleHz,...
    params.File.SampleHz,...
    params.Scoring.HzDiv);

if nnz(validBins)/length(validBins)*100 < params.Scoring.FFTvalidData
    disp(['WARNING>> SleepScoreModule: Only ',num2str(nnz(validBins)/length(validBins)*100),' percent of data is valid']);
end

switch upper(ScoringType)
    
    case 'DELTA' %OK
    %% Delta Scoring of EEG Data (Requires EEG)
    %Normalize and Transpose P
if params.Scoring.useNormByEpoch 
% P = bsxfun(@ldivide, P, nansum(P,2)); %functionally the NOT the same this is matrix divide NOT Array right division 
P = (P ./ repmat(nansum(P,2),1,size(P,2)))'; %DMD Moment by Moment Normalization using L1
else
P = (P/norm(P))';  %to retun in a similar manner to spectrogram;
end
        %Build Spectrograms for EEG and EMG signals without artifact
        % [S,F,T,P] = spectrogram(EEG,params.Scoring.FFTEpoch*params.File.SampleHz,0,2*params.File.SampleHz,params.File.SampleHz); %5 sec win/0 sec overlap/0.5 Hz increments/1000Hz SampleRate can send NaN
        DeltaPower = sum(P(2:9,:)); %Delta Power 0.5 - 4
        
        %Design multirate box filter
        %2000 Hz 20 data points = resolution of 100 Hz or 0.01 Sec
        %numSamplesInFilterWin = ceil(params.Scoring.StageEpoch / params.Scoring.FFTEpoch);
        b = ones(1,numSamplesInFilterWin)./numSamplesInFilterWin;
        a = 1;
        DeltaPower = filtfilt(b,a,DeltaPower);
        
        % run scoring
        ScoreIndex = ones(1,length(1:length(DeltaPower))); %pallette is the length/binned the same as FFT (i.e. 5sec)
        
        %Create Indexes of Delta
        [lambdahat,lambdaci] = poissfit(DeltaPower(validBins),params.Scoring.zDeltaThreshold);
        DeltaPowerIndex = find(DeltaPower > lambdaci(end));
        
        %now mark all as 2 for sws2
        ScoreIndex(DeltaPowerIndex) = 2;
        % and not valid bins as unknown
        ScoreIndex(~validBins) = 0;
        
        % plot if requested
        if params.Scoring.plot
            figure;
            plot(T,DeltaPower);
            hold on;
            plot(repmat(lambdaci(end),1,ceil(T(end))),'r');
        end
        
        %Combine FFTEpochs into StageEpochs
        ScoreIndex = combineFFTEpoch(ScoreIndex,params);
        
                
    case 'DECISIONTREE'
        % Remove Artifact from EMG signal and replace with with zeros instead of artifact
        % EEG was done above
        %Normalize and Transpose P
if params.Scoring.useNormByEpoch 
% P = bsxfun(@ldivide, P, nansum(P,2)); %functionally the NOT the same this is matrix divide NOT Array right division 
P = (P ./ repmat(nansum(P,2),1,size(P,2)))'; %DMD Moment by Moment Normalization using L1
else
P = (P/norm(P))';  %to retun in a similar manner to spectrogram;
end

        EMG(BlankIDX) = 0;
        
        %Build Spectrograms for EEG and EMG signals without artifact
%         [S,F,T,P] = spectrogram(EEG,params.Scoring.FFTEpoch*params.File.SampleHz,0,2*params.File.SampleHz,params.File.SampleHz); %5 sec win/0 sec overlap/0.5 Hz increments/500Hz SampleRate can send NaN
        DeltaPower = [DeltaPower, sum(P(2:9,:))]; %Delta Power 0.5 - 4
        ThetaPower = [ThetaPower, sum(P(10:27,:))]; %Theta Power 4.5-13
        
        [S,F,T,P] = spectrogram(EMG,params.Scoring.FFTEpoch*params.File.SampleHz,0,2*params.File.SampleHz,params.File.SampleHz);
        EMGPower = [EMGPower, sum(P(21:91,:))];%EMG Range 10-45
        
        % run scoring
        ScoringIndexPallette = zeros(1,length(1:length(DeltaPower))); %pallette is the length/binned the same as FFT (i.e. 5sec)
        
        %Create Indexes of
        DeltaPowerIndex = find(zscore(DeltaPower) > 0.2*(0-min(zscore(DeltaPower))));   %5sec bins - TRUE above threshold  <--- Make Dynamic
        ThetaPowerIndex = find(zscore(ThetaPower) > 0.5*(0-min(zscore(ThetaPower))));   %5sec bins - TRUE above threshold  <--- Make Dynamic
        ThetaDeltaIndex = find(zscore(ThetaPower) > zscore(DeltaPower));                %5sec bins - TRUE Theta above Delta
        EMGPowerIndex = find(zscore(EMGPower) > (min(zscore(EMGPower)))/1.5);           %5sec bins - TRUE above threshold  <--- Make Dynamic
        
        %Build vector of 30 second scoring using some stragity of a
        %Decision Tree of a given state
        ScoreIndex = [];
        windowSize = params.Scoring.StageEpoch/params.Scoring.FFTEpoch;
        
        for i = 1:windowSize:length(ScoringIndexPallette)
            %Build EpochScore [how many FFTEpochs are there in a StageEpoch]
            EpochScore = [ ...
                length(find(Artifact_IDX(((i-1)*params.Scoring.FFTEpoch*params.File.SampleHz+1):((i-1+windowSize)*params.Scoring.FFTEpoch*params.File.SampleHz)) == true)), ...
                length(find(i <= EMGPowerIndex & EMGPowerIndex < i+windowSize)),...
                length(find(i <= ThetaDeltaIndex & ThetaDeltaIndex <= i+windowSize)),...
                length(find(i <= ThetaPowerIndex & ThetaPowerIndex <= i+windowSize)),...
                length(find(i <= DeltaPowerIndex & DeltaPowerIndex <= i+windowSize)),...
                ];
            %Test for Active Wake = Active OR 20%Artifact OR 50% High EMG
            if (EpochScore(1) > params.File.SampleHz*params.Scoring.StageEpoch*0.2 ...
                    | EpochScore(2) > windowSize/2) &  EpochScore(5) < windowSize*0.5
                tempScoreIndex = 5;
                
                %Test for Low muscle tone (SWS2 = High Delta >= 50% of the time)
            else
                %Test for SWS2 = High Delta >= 50% of the time
                if EpochScore(5) >= windowSize*0.5
                    tempScoreIndex = 2;
                    %Test for REM = Low Delta and Theta Power (10%) and previous score (how many) was not wake
                elseif (EpochScore(4) <= 1 & EpochScore(5) <= 1) &&  (ScoreIndex(end) < 5 & ScoreIndex(end) ~= 0)
                    if length(find(ScoreIndex(end-1:end) <= 3)) == 2
                        tempScoreIndex = 1;
                    else
                        tempScoreIndex = 4;
                    end
                    %Test for SWS1 = High Delta OR Theta Power >= 50% of the time
                elseif EpochScore(4) >= windowSize*0.5 | EpochScore(5) >= windowSize*0.5
                    tempScoreIndex = 3;
                    %Test for
                elseif ((EpochScore(4) + EpochScore(5)) > 1) && (EpochScore(3) >= 2*EpochScore(4)) %
                    if ScoreIndex(end) == 5                                                %push up to QW if previous was AW
                        tempScoreIndex = 4;
                    else
                        tempScoreIndex = 3;
                    end
                    %Test for QW = High Theta/Delta Ratio >= 50% of the time
                elseif EpochScore(3) > windowSize*0.5
                    tempScoreIndex = 4;
                elseif ((EpochScore(4) + EpochScore(5)) <= 1) && (EpochScore(3) >= 1)   %QW (< to <=)
                    tempScoreIndex = 4;
                else
                    tempScoreIndex = 0;                                                    %Unknown
                end
            end
            ScoreIndex = [ScoreIndex tempScoreIndex];                                  %Concatinate Latest score
        end
        
       
    case 'ICA'
    %% Ratio/ICA Scoring of EEG Data (Requires EEG and can use EMG)
    % Orginally this was based on acombination of EEG and EMG which works
    % well using Ratio1 (2.5 : 20.5 /2.5 : 55.5 Hz),  Ratio3 (1.5 : 10 / 
    % 1.5 : 20), and an EEG overall power ratio. Since then the ratios were
    % played with to get the best scoring for EEG alone. 
    % DeltaPower = sum(P(2:9,:)); %Delta Power 0.5 - 4
    % ThetaPower = sum(P(10:27,:)); %Theta Power 4.5-13
    
    %Normalize and Transpose P
if params.Scoring.useNormByEpoch 
% P = bsxfun(@ldivide, P, nansum(P,2)); %functionally the NOT the same this is matrix divide NOT Array right division 
P = (P ./ repmat(nansum(P,2),1,size(P,2)))'; %DMD Moment by Moment Normalization using L1
else
P = (P/norm(P))';  %to retun in a similar manner to spectrogram;
end
    
        %[S,F,T,P] = spectrogram(EEG,params.Scoring.FFTEpoch*params.File.SampleHz,0,2*params.File.SampleHz,params.File.SampleHz); 
        %5 sec win/0 sec overlap/0.5 Hz increments/500Hz SampleRate can send NaN
        %Ratio's are based on FFT power spectrum 0.4883 Hz divisions
        Ratio1 = sum(P(5:42,:),1)./sum(P(5:114,:),1); %2.5 : 20.5 /2.5 : 55.5 Hz
        Ratio2 = sum(P(5:10,:),1)./sum(P(5:20,:),1);  %2.5:4.8 / 2.5 : 10
        %Ratio2 = sum(P(10:20,:),1)./sum(P(5:20,:),1); %  2.5 : 10 / 2.5:4.8 Theta/Delta+Theta
        Ratio3 = sum(P(3:20,:),1)./sum(P(3:40,:),1);  %1.5 : 10 / 1.5 : 20 Hz
        
        % you will get Div0's == NaN here and woll cause problms later !!!
        
        if ~isempty(EMG)
            [S,F,T,P] = spectrogram(EMG,params.Scoring.FFTEpoch*params.File.SampleHz,0,2*params.File.SampleHz,params.File.SampleHz);
            EMGPower = sum(P(21:91,:));%EMG Range 10-45
            
            %Ratio's are based on FFT power spectrum 0.4883 Hz divisions
            RatioEMG = sum(P(1:21))./sum(P(1:205));
            
            %now run ICA (rows are independent signals)
            [icasig, A, icaW] = fastica([Ratio1(validBins); Ratio2(validBins); RatioEMG(validBins)],'verbose', 'on', 'displayMode', 'off'); %rows = var's
            %map back into normal space
            try
                IC1 = [Ratio1; Ratio2; RatioEMG] .* repmat(DATAHistory.icaW(:,1),length(Ratio1),1);
            catch
                icaW = ones(3);
                IC1 = [Ratio1; Ratio2; RatioEMG] .* repmat(DATAHistory.icaW(:,1),length(Ratio1),1);
            end
            
        else
            %now run ICA only on EEG ratios
            [icasig, A, icaW] = fastica([Ratio1(validBins); Ratio2(validBins); Ratio3(validBins)],'verbose', 'on', 'displayMode', 'off'); %rows = var's
            %map back into normal space
            try
                IC1 = [Ratio1; Ratio2; Ratio3] .* repmat(icaW(:,1),1,length(Ratio1));
            catch
                icaW = ones(3); %icaW = ones(2); %with Ratio1 & 2
                IC1 = [Ratio1; Ratio2; Ratio3] .* repmat(icaW(:,1),1,length(Ratio1));
            end
            
        end
        
        % Now Cluster Data
        % Create data structs for clustering
        if ~any(isnan(IC1))
            param.c=3; %3 clusters delta, Aawake, Qawake, other
        else
            param.c=4; %Add one because one cluster will be {0,0,0}
            IC1(isnan(IC1)) = 0;
        end
        param.m=2;
        param.e=1e-6;
        param.ro=ones(1,param.c);
        param.val=3;
        
        %do clustering
        disp('... Running Fuzzy K-Means Clustering')
        data.X = IC1'; %transpose ICA row data
        data = clust_normalize(data,'range');  %Normalize data
        ClusterResult = GKclust(data, param);
        ClusterMax = max(ClusterResult.data.f');
        [r,c] = size(ClusterResult.data.f);
        mytile = repmat(ClusterMax', 1 , c);
        ClusterAssignment = (mytile == ClusterResult.data.f);
        
        %plot clustering
        % plot if requested
        if params.Scoring.plot
        figure;
        subplot(3,1,1); hold on; plot(Ratio1,'b'); plot(Ratio2,'g'); plot(Ratio3, 'y');
        subplot(3,1,2); hold on; plot(IC1(1,:),'m'); plot(IC1(2,:),'c'); plot(Ratio3,'b')
        subplot(3,1,3); hold on; plot(data.X(:,1),data.X(:,2),'b.',ClusterResult.cluster.v(:,1),ClusterResult.cluster.v(:,2),'ro');
        evalClust = clusteval(data,ClusterResult,param);
        end
        
        % The next section is a rule based algorithm to find the clusters
        % since in the cluster assignments will be different each time it
        % is run. 
        if ~isempty(EMG)
            %for files w/ EMG
            %find Delta cluster
            if mean(Ratio1(ClusterAssignment(:,1))) > mean(Ratio2(ClusterAssignment(:,1))) && ...
                    mean(Ratio1(ClusterAssignment(:,1))) > mean(RatioEMG(ClusterAssignment(:,1)))
                DeltaCluster = 1;
            elseif mean(Ratio1(ClusterAssignment(:,2))) > mean(Ratio2(ClusterAssignment(:,2))) && ...
                    mean(Ratio1(ClusterAssignment(:,2))) > mean(RatioEMG(ClusterAssignment(:,2)))
                DeltaCluster = 2;
            elseif mean(Ratio1(ClusterAssignment(:,3))) > mean(Ratio2(ClusterAssignment(:,3))) && ...
                    mean(Ratio1(ClusterAssignment(:,3))) > mean(RatioEMG(ClusterAssignment(:,3)))
                DeltaCluster = 3;
            else
                disp('No DELTA Cluster Found !');
                DeltaCluster = 0;
            end
            
            %find REM cluster also < 0.5 ratio
            if mean(Ratio1(ClusterAssignment(:,1))) > mean(RatioEMG(ClusterAssignment(:,1))) && ...
                    mean(RatioEMG(ClusterAssignment(:,1))) > mean(Ratio2(ClusterAssignment(:,1))) && ...
                    DeltaCluster ~= 1
                REMCluster = 1;
            elseif mean(Ratio1(ClusterAssignment(:,2))) > mean(RatioEMG(ClusterAssignment(:,2))) && ...
                    mean(RatioEMG(ClusterAssignment(:,2))) > mean(Ratio2(ClusterAssignment(:,2))) && ...
                    DeltaCluster ~= 2
                REMCluster = 2;
            elseif mean(Ratio1(ClusterAssignment(:,3))) > mean(RatioEMG(ClusterAssignment(:,3))) && ...
                    mean(RatioEMG(ClusterAssignment(:,3))) > mean(Ratio2(ClusterAssignment(:,3)))&& ...
                    DeltaCluster ~= 3
                REMCluster = 3;
            else
                disp('No REM Cluster Found !');
                REMCluster = 0;
            end
            
        else % files without EMG 
            %find Delta cluster
            if mean(Ratio1(ClusterAssignment(:,1) & validBins)) > mean(Ratio2(ClusterAssignment(:,1) & validBins)) && ...
                    mean(Ratio1(ClusterAssignment(:,1) & validBins)) > mean(Ratio1(ClusterAssignment(:,2) & validBins)) && ...
                    mean(Ratio1(ClusterAssignment(:,1) & validBins)) > mean(Ratio1(ClusterAssignment(:,3) & validBins));
                DeltaCluster = 1;
                
            elseif mean(Ratio1(ClusterAssignment(:,2) & validBins)) > mean(Ratio2(ClusterAssignment(:,2) & validBins)) && ...
                    mean(Ratio1(ClusterAssignment(:,2) & validBins)) > mean(Ratio1(ClusterAssignment(:,1) & validBins)) && ...
                    mean(Ratio1(ClusterAssignment(:,2) & validBins)) > mean(Ratio1(ClusterAssignment(:,3) & validBins));
                DeltaCluster = 2;
                
            elseif mean(Ratio1(ClusterAssignment(:,3) & validBins)) > mean(Ratio2(ClusterAssignment(:,3) & validBins)) && ...
                    mean(Ratio1(ClusterAssignment(:,3) & validBins)) > mean(Ratio1(ClusterAssignment(:,1) & validBins)) && ...
                    mean(Ratio1(ClusterAssignment(:,3) & validBins)) > mean(Ratio1(ClusterAssignment(:,2) & validBins));
                DeltaCluster = 3;
            else
                disp('No DELTA Cluster Found !');
                DeltaCluster = 0;
            end
            
            %find QW cluster
            if mean(Ratio1(ClusterAssignment(:,1) & validBins)) < mean(Ratio1(ClusterAssignment(:,2) & validBins)) && ...
                    mean(Ratio1(ClusterAssignment(:,1) & validBins)) < mean(Ratio1(ClusterAssignment(:,3) & validBins)) && ...
                    DeltaCluster ~= 1
                QWCluster = 1;
                
            elseif mean(Ratio1(ClusterAssignment(:,2) & validBins)) < mean(Ratio1(ClusterAssignment(:,1) & validBins)) && ...
                    mean(Ratio1(ClusterAssignment(:,2) & validBins)) < mean(Ratio1(ClusterAssignment(:,3) & validBins)) && ...
                    DeltaCluster ~= 2
                QWCluster = 2;
                
            elseif mean(Ratio1(ClusterAssignment(:,3) & validBins)) < mean(Ratio1(ClusterAssignment(:,1) & validBins)) && ...
                    mean(Ratio1(ClusterAssignment(:,3) & validBins)) < mean(Ratio1(ClusterAssignment(:,2) & validBins)) && ...
                    DeltaCluster ~= 3
                QWCluster = 3;
            else
                disp('No QW Cluster Found !');
                QWCluster = 0;
            end
            
            %find AW cluster
            if mean(Ratio1(ClusterAssignment(:,2))) > mean(Ratio2(ClusterAssignment(:,2) & validBins)) && ...
                    mean(Ratio1(ClusterAssignment(:,3))) > mean(Ratio2(ClusterAssignment(:,3) & validBins)) && ...
                    DeltaCluster ~= 1
                AWCluster = 1;
                
            elseif mean(Ratio1(ClusterAssignment(:,1) & validBins)) > mean(Ratio2(ClusterAssignment(:,1) & validBins)) && ...
                    mean(Ratio1(ClusterAssignment(:,3) & validBins)) > mean(Ratio2(ClusterAssignment(:,3) & validBins)) && ...
                    DeltaCluster ~= 2
                AWCluster = 2;
                
            elseif mean(Ratio1(ClusterAssignment(:,1) & validBins)) > mean(Ratio2(ClusterAssignment(:,1) & validBins)) && ...
                    mean(Ratio1(ClusterAssignment(:,2) & validBins)) > mean(Ratio2(ClusterAssignment(:,2) & validBins)) && ...
                    DeltaCluster ~= 3
                AWCluster = 3;
                
            else
                disp('No AW Cluster Found !');
                AWCluster = 0;
            end
        end
        
        % Determine states
        [rows,cols] = find(ClusterResult.data.f == repmat(max(ClusterResult.data.f,[],2),1,size(ClusterResult.data.f,2)));
        for clustcols = 1:param.c
            tempScoreIndex(rows(cols == clustcols)) = clustcols;
        end
        
        otherIDX = (tempScoreIndex ~= DeltaCluster) & (tempScoreIndex ~= AWCluster) & (tempScoreIndex ~= QWCluster);
        ScoreIndex(tempScoreIndex == DeltaCluster) = 2;
        ScoreIndex(tempScoreIndex == QWCluster) = 4;
        ScoreIndex(tempScoreIndex == AWCluster) = 5;
        ScoreIndex(otherIDX) = 0;
        
        
        %Combine FFTEpochs into StageEpochs
        ScoreIndex = combineFFTEpoch(ScoreIndex,params);
        
case 'GMMLOGSPECTRUM'
disp('Running GMM log Spectrum');
%% logarithmically bin spectrum and use as input for GMM clustering

%This is still broken. Clustering is not like visual (i.e. big theta/delta
%not detected

    
%clean up PSD
P = P';
P(1,:) = []; %Remove DC component
F(1) = [];


%Do some temporal smoothing 
% Method 1 (3x faster unvalidated)
%     b = ones(1,numSamplesInFilterWin)./numSamplesInFilterWin;
%     a = 1;
% for curHz = 1:size(P,1);
%     smP(curHz,:) = filtfilt(b,a,P(curHz,:));
% end
%Method 2
disp('     ... temporal smoothing of spectrum.');
pause(0.1);
if params.Scoring.useTemporalMedianFilter
    if rem(numSamplesInFilterWin,2)==0
        numSamplesInFilterWin=numSamplesInFilterWin-1;
    end
    Startbin = ceil(numSamplesInFilterWin/2);
    for curHz=1:size(P,1)
        smP(curHz,:) = nanmedfilt1(P(curHz,:),numSamplesInFilterWin);
    end
else
    numSamplesInFilterWin = ceil(numSamplesInFilterWin/2);
    if rem(numSamplesInFilterWin,2)==0
        numSamplesInFilterWin=numSamplesInFilterWin-1;
    end
    Startbin = ceil(numSamplesInFilterWin/2);
    for curHz=1:size(P,1)
        ConvMat = convmtx(P(curHz,:),numSamplesInFilterWin);
        smP(curHz,:) = nanmean(ConvMat(:, Startbin:end-Startbin+1));
    end
end

%Normalize and Transpose P
disp('     ... normalizing spectral power.'); 
pause(0.1);
if params.Scoring.useNormByEpoch 
    P=P';
% P = bsxfun(@ldivide, P, nansum(P,2)); %functionally the NOT the same this is matrix divide NOT Array right division 
P = (P ./ repmat(nansum(P,2),1,size(P,2)))'; %DMD Moment by Moment Normalization using L1
else
    P=P';
P = (P/norm(P))';  %to retun in a similar manner to spectrogram;
end

%truncate to 50 Hz
P = P(1:find(F <= 50,1, 'last'),:);
F = F(1:find(F <= 50,1, 'last'));

% generate logarithmic binning
X = floor(logspace(0,log10(50),10)) +1;
X(1) = F(1);
counter = 1;
for n = 1:length(X)-1
    fStart = find(F == X(n),1);
    fEnd = find(F == X(n+1),1);
    rebinPSD(counter,:) = mean(smP(fStart:fEnd,:),1);
    rebinFreq(counter) = F(fStart);
    counter = counter +1;
end

%Transpose PSD so time is in rows
rebinPSD = rebinPSD';

%do GMM clustering
disp('... Running GMM Clustering');
options = statset('Display','final');

% get optimal number of clusters with all the data ???
%sequentially fit data with increasing numbers of clusters.
% stop if second cluster is not sig diferent
% ToDo add breakpoint analysis from previous code 

warning off;
TotalNumClusters = 5;
ChiCDF = [];
BIC=ones(1,TotalNumClusters) * NaN;
if params.Scoring.useGMMinit
    minnumComponents = length(params.Scoring.GMMinit.PComponents);
    obj = gmdistribution.fit(rebinPSD(validBins,:), minnumComponents, 'Start', params.Scoring.GMMinit);
    warning on;
    disp(['Final Number of Clusters = ',num2str(minnumComponents)]);
    [idx,nlogl,P] = cluster(obj,rebinPSD);
    %this would be more stable as a try catch then if fail do full
    %estimation
else
    for n=1:TotalNumClusters
        disp(['... Running GMM Cluster Size: ',num2str(n)]);
        try
            obj{n} = gmdistribution.fit(rebinPSD(validBins,:), n, 'Start', 'randSample', 'Replicates', 5);
            BIC(n) = obj{n}.BIC;
            if n == 2
                %do deviance test to see if truely diferent
                difdev = abs(obj{n}.NlogL - obj{n-1}.NlogL);
                df = n - (n-1);
                ChiCDF = 1 - chi2cdf(difdev, df);
                if ChiCDF >= 0.01 | max(rebinPSD(validBins,3)) <= 2* mean(rebinPSD(validBins,3)) % << soft code this !!
                    % no Wake and Sleep
                    break;
                end
            end
        catch ME
            disp(ME);
            BIC(n)=NaN;
        end
    end
    if ~isempty(ChiCDF)
        [minBIC,minnumComponents] = min(BIC);
        if minnumComponents > 5
            for j=2:TotalNumClusters
                ypredict=detrend(BIC(2:10),'linear',[j-1]);
                SumSquare(j-1)=sum(ypredict.^2);
            end
            [MinSS,breakPt]=min(SumSquare);
            minBIC = BIC(breakPt +1);
            minnumComponents = breakPt +1;
        end
    else
        minBIC = NaN;
        minnumComponents = 1;
    end
    warning on;
    disp(['Final Number of Clusters = ',num2str(minnumComponents)]);
    [idx,nlogl,P] = cluster(obj{minnumComponents},rebinPSD);
end

%Now identify clusters
% 1st Gather spectra means
for n = 1:minnumComponents %was 5
    meanSpectra(n,:) = mean(rebinPSD(idx == n,:));
    DeltaTheta(n,:) = mean(mean(rebinPSD(idx == n,2:3))) / mean(rebinPSD(idx == n,6)) ;
end
%2nd apply simple classification scheme related to scoring order
%sort SWS1 and SWS2
%OR sort by Delta/theta ratio
[SWSMeanSpectra, SWSrowIdx] = sortrows(meanSpectra,[-2 -3]); %sort in decending order by low Delta power
[WAKEMeanSpectra, WAKErowIdx] = sortrows(meanSpectra,[-3 -6]); %sort in decending order by high Delta power
if minnumComponents == 1
         %only Waking
         rowIdx = 1;
         scoringSet = 0; %unk (nothing to compare it to)
         disp('EEG State(s) are Singular and will be marked as Unknown (UNK)');
elseif minnumComponents == 2
        rowIdx = SWSrowIdx;
        scoringSet = [2,5];
elseif minnumComponents > 2
    rowIdx = [SWSrowIdx(1:2); WAKErowIdx(3:end)];
    scoringSet = [2,3,4,5,1]; %scoring order
end
    
[~,DTrowIdx] = sort(DeltaTheta,'descend');

PlotSpectraMeans = meanSpectra(rowIdx,:);
%[trash, rowIdx] = sortrows(meanSpectra,[-2 -3]); %sort in decending order by delta power

%assign scoring
ScoreIndex = zeros(1,size(rebinPSD,1)); %pallette is the length/binned the same as FFT (i.e. 5sec)
for n = 1:minnumComponents %was 5
    if ~isempty(intersect(rowIdx,n))
        ScoreIndex(idx == rowIdx(n)) = scoringSet(n);
    end
end

%Combine FFTEpochs into StageEpochs
%Valid Score IDX is scoring that met defined state rules
[ScoreIndex, ValidScoreIndex] = combineFFTEpoch(ScoreIndex,params);

        % plot if requested
        if params.Scoring.plot
            figure;
            subplot(4,3,1:3:10); imagesc(rebinPSD);
            title('LogBinSpectra');colorbar;
            subplot(4,3,[2,3,5,6]);
            plot(PlotSpectraMeans');
            if minnumComponents == 1
                legend('UNK');
            elseif minnumComponents == 2
                legend('SWS2','AW');
            else
                legend('SWS2','SWS1','QW','AW','PS');
            end
            title('GMM Spectral Profile');
            subplot(4,3,8:9); plot(EEG);
            title('EEG');
            NanValidScoreIndex = single(ValidScoreIndex);
            NanValidScoreIndex(NanValidScoreIndex == 0) = NaN;
            subplot(4,3,11:12); plot(ScoreIndex); hold on;plot(NanValidScoreIndex /2,'k');
            legend('Hypnogram postCombineFFT','GMM Known States');
            title('Hypnogram');
        end
        
end

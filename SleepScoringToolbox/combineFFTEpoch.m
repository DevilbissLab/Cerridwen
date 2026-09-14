function [ScoreIndex,ts] = combineFFTEpoch(ScoreIndex,validBins,params)
%
%   combineFFTEpoch - helper function to combine FFTEpochs into
%                       ScoringEpochs
% Usage:
%  >> ScoreIndex = combineFFTEpoch(ScoreIndex,params)
%
% Inputs:
%   ScoreIndex      - vector of scoring stages;
%                         ScoreBuffer Values
%                             value 5 = 'WAKE-ACTIVE';
%                             value 4 = 'WAKE';
%                             value 3 = 'SWS1';
%                             value 2 = 'SWS2';
%                             value 1 = 'PS';
%                             value 0 = 'UNSPECIFIED';
%   validBins       - vector of FFT valid bins (artifacts);
%   params          - struct of parameters from ParamaterFile;
%
% Outputs:
%   ScoreIndex      - vector of Sleep Stages of size params.Scoring.StageEpoch
%
% See also:
%   ParameterFile for framework settings.
%   SleepScoreModule (caller)
%
% Copyright (C) 2010 by David Devilbiss <ddevilbiss@wisc.edu>
% Version 2.0 (2026)
% ToTry: Also may want to chunk as words. then fill in tween's with guesses

ts = [];

numSamplesInFilterWin = ceil(params.Scoring.StageEpoch / params.Scoring.FFTEpoch);

ScoreBuffer = buffer(ScoreIndex,numSamplesInFilterWin);
ScoreIndex = zeros(1,length(1:size(ScoreBuffer,2))); % Set all to unknown
ArtifactBuffer = buffer(~validBins,numSamplesInFilterWin);

if isfield(params,'Scoreindex')
    if ~isempty(params.Scoreindex.ts)
        ts = params.Scoreindex.ts(1:numSamplesInFilterWin:end);
        %check Length
        if length(ts) ~= size(ScoreBuffer,2)
            ts = NaN;
        end
    end
end
% 
% for curState = 5:-1:1 %counting up gives sws2 precidence
%    switch curState
%        case 5   %aw
%            IDX = (sum(ScoreBuffer == 5)./sum(ScoreBuffer ~= 0)*100) >= params.rules.AW.PercentOfStageEpoch;
%            ScoreIndex(IDX) = 5;
%        case 4   %QW
%            IDX = (sum(ScoreBuffer == 4)./sum(ScoreBuffer ~= 0)*100) >= params.rules.QW.PercentOfStageEpoch;
%            ScoreIndex(IDX) = 4;
%        case 3   %SWS1
%            IDX = (sum(ScoreBuffer == 3)./sum(ScoreBuffer ~= 0)*100) >= params.rules.SWS1.PercentOfStageEpoch;
%            ScoreIndex(IDX) = 3;
%        case 2   %SWS2
%            IDX = (sum(ScoreBuffer == 2)./sum(ScoreBuffer ~= 0)*100) >= params.rules.SWS2.PercentOfStageEpoch;
%            ScoreIndex(IDX) = 2;
%            if strcmpi(params.Scoring.ScoringType,'delta') %Special case for delta scoring only
%                ScoreIndex(~IDX) = 5;
%            end
%        case 1   %PS
%            IDX = (sum(ScoreBuffer == 1)./sum(ScoreBuffer ~= 0)*100) >= params.rules.PS.PercentOfStageEpoch;
%            ScoreIndex(IDX) = 1;
%    end
% end
% ScoreBuffer(ScoreBuffer == 0) = NaN;
% ScoreBuffer(ScoreBuffer == 1) = 6; % want an average between AW and PS (5 & 6)  = 5.5 not 3 
% %MeanIndex = round(nanmean(ScoreBuffer,1)); %may be better to floor/ceil
% MeanIndex = mode(ScoreBuffer,1);
% MeanIndex(MeanIndex == 6) = 1; %Put back to REM
% ScoreIndex(ScoreIndex == 0) = MeanIndex(ScoreIndex == 0);
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %2026 update - Winner take all (N3 > 20% is queen)
% ScoreBuffer(ScoreBuffer == 0) = NaN;
% %Swap PS/R for value 6 since want an average between AW and PS (5 & 6)  = 5.5 not 3
% ScoreBuffer(ScoreBuffer == 1) = 6;
% ScoreIndex = mode(ScoreBuffer,1); %Winner take all
% ScoreIndex(ScoreIndex == 6) = 1; %Put state 6 back to PS/R
% ScoreIndex(ScoreIndex == 0) = MeanIndex(ScoreIndex == 0);
%
% %Override with N3 rules:
% IDX = (sum(ScoreBuffer == 2)./sum(ScoreBuffer ~= 0)*100) >= params.rules.SWS2.PercentOfStageEpoch;
% ScoreIndex(IDX) = 2;
% if strcmpi(params.Scoring.ScoringType,'delta') %Special case for delta scoring only
%     ScoreIndex(~IDX) = 5;
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%2026 update - Winner take all (N3 > 20% is king)

%Winner take all
ScoreIndex = mode(ScoreBuffer,1);

%Override with N3 rules:
if params.rules.SWS2.PercentOfStageEpoch > 0
    IDX = (sum(ScoreBuffer == 2)./sum(ScoreBuffer ~= 0)*100) >= params.rules.SWS2.PercentOfStageEpoch;
    ScoreIndex(IDX) = 2;
end
if strcmpi(params.Scoring.ScoringType,'delta') %Special case for delta scoring only
    ScoreIndex(~IDX) = 5;
end

%Override AASM v3 with all other rules:
rules = [params.rules.PS.PercentOfStageEpoch, params.rules.AW.PercentOfStageEpoch, params.rules.QW.PercentOfStageEpoch, params.rules.SWS1.PercentOfStageEpoch];
if sum(rules) ~= 0 || all(isnan(rules))

    for curCol = 1:size(ScoreBuffer,2)
        [C,~,ic] = unique(ScoreBuffer(:,curCol));
        ScoreCounts = [C, accumarray(ic,1)];
        ScoreCounts = [ScoreCounts, ScoreCounts(:,2)./size(ScoreBuffer,1)*100]; %add percentages to end
        
        StateCntr = 0;
        for curRow = 1:size(ScoreCounts,1)
            switch ScoreCounts(curRow,1)
                case 1
                    if ScoreCounts(curRow,3) >= params.rules.PS.PercentOfStageEpoch
                        ScoreIndex(curCol) = 1; StateCntr = StateCntr +1;
                    end
                case 2
                    if ScoreCounts(curRow,3) >= params.rules.SWS2.PercentOfStageEpoch
                        ScoreIndex(curCol) = 2; StateCntr = StateCntr +1;
                    end
                case 3
                    if ScoreCounts(curRow,3) >= params.rules.SWS1.PercentOfStageEpoch
                        ScoreIndex(curCol) = 3; StateCntr = StateCntr +1;
                    end
                case 4
                    if ScoreCounts(curRow,3) >= params.rules.QW.PercentOfStageEpoch
                        ScoreIndex(curCol) = 4; StateCntr = StateCntr +1;
                    end
                case 5
                    if ScoreCounts(curRow,3) >= params.rules.AW.PercentOfStageEpoch
                        ScoreIndex(curCol) = 5; StateCntr = StateCntr +1;
                    end
            end
        end
        if StateCntr ~= 1
            %If no conditions are met or more than 1 met = Winner take all
            % ScoreIndex(curCol) = mode(ScoreBuffer(:,curCol));
            %If no conditions are met or more than 1 met = Winner take all of specified states
            ScoreIndex(curCol) = mode(ScoreBuffer(ScoreBuffer(:,curCol) ~= 0,curCol));
            %If no conditions are met or more than 1 met = leave unspecified
            %ScoreIndex(curCol)  = NaN;
        end
    end
end

%Override with Artifact rule:
if params.rules.ForceArtifactsAsWaking
IDX = max(ArtifactBuffer,[],1);
%This could be a percentage as well
%IDX = (sum(ArtifactBuffer == 2)./sum(ArtifactBuffer ~= 0)*100) >= params.rules.Artifact.PercentOfStageEpoch;
ScoreIndex(IDX) = 5;
end


%Set unspecified to NaN
%ScoreIndex(ScoreIndex == 0) = NaN;
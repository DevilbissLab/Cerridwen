function [ScoreIndex,ts] = combineFFTEpoch(ScoreIndex,params)
%
%   combineFFTEpoch - helper function to combine FFTEpochs into
%                       ScoringEpochs
% Usage:
%  >> ScoreIndex = combineFFTEpoch(ScoreIndex,params)
%
% Inputs:
%   ScoreIndex      - vector of scoreing stages;
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
%
% ToTry: Also may want to chunk as words. then fill in tween's with guesses
ts = [];

numSamplesInFilterWin = ceil(params.Scoring.StageEpoch / params.Scoring.FFTEpoch);

ScoreBuffer = buffer(ScoreIndex,numSamplesInFilterWin);
ScoreIndex = zeros(1,length(1:size(ScoreBuffer,2))); % Set all to unknown

if isfield(params,'Scoreindex')
    if ~isempty(params.Scoreindex.ts)
        ts = params.Scoreindex.ts(1:numSamplesInFilterWin:end);
        %check Length
        if length(ts) ~= size(ScoreBuffer,2)
            ts = NaN;
        end
    end
end
for curState = 5:-1:1 %counting up gives sws2 precidence
   switch curState
       case 5   %aw
           IDX = (sum(ScoreBuffer == 5)./sum(ScoreBuffer ~= 0)*100) >= params.rules.AW.PercentOfStageEpoch;
           ScoreIndex(IDX) = 5;
       case 4   %QW
           IDX = (sum(ScoreBuffer == 4)./sum(ScoreBuffer ~= 0)*100) >= params.rules.QW.PercentOfStageEpoch;
           ScoreIndex(IDX) = 4;
       case 3   %SWS1
           IDX = (sum(ScoreBuffer == 3)./sum(ScoreBuffer ~= 0)*100) >= params.rules.SWS1.PercentOfStageEpoch;
           ScoreIndex(IDX) = 3;
       case 2   %SWS2
           IDX = (sum(ScoreBuffer == 2)./sum(ScoreBuffer ~= 0)*100) >= params.rules.SWS2.PercentOfStageEpoch;
           ScoreIndex(IDX) = 2;
           if strcmpi(params.Scoring.ScoringType,'delta'); %Special case for delta scoring only
               ScoreIndex(~IDX) = 5;
           end
       case 1   %PS
           IDX = (sum(ScoreBuffer == 1)./sum(ScoreBuffer ~= 0)*100) >= params.rules.PS.PercentOfStageEpoch;
           ScoreIndex(IDX) = 1;
   end
end

ScoreBuffer(ScoreBuffer == 0) = NaN;
ScoreBuffer(ScoreBuffer == 1) = 6; % mean want average between 5 & 6  = 5.5 not 3 
%MeanIndex = round(nanmean(ScoreBuffer,1)); %may be better to floor/ceil
MeanIndex = mode(ScoreBuffer,1);
MeanIndex(MeanIndex == 6) = 1; %Put back to REM
ScoreIndex(ScoreIndex == 0) = MeanIndex(ScoreIndex == 0);


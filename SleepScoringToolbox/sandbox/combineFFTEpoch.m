function [ScoreIndex, ValidScoreIndex] = combineFFTEpoch(ScoreIndex,params)
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

disp('Aggrigating FFT Epochs into Sleep Scoring binning');
numSamplesInFilterWin = ceil(params.Scoring.StageEpoch / params.Scoring.FFTEpoch);

ScoreBuffer = buffer(ScoreIndex,numSamplesInFilterWin);
ScoreIndex = zeros(1,length(1:size(ScoreBuffer,2))); % Set all to unknown

%CreateScore Buffer adn only assign known states
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
%create a vllid score IDX so we can use/view it later
ValidScoreIndex = ScoreIndex ~= 0;

if ~all(ScoreIndex == 0)
    %handle unscored  epochs
    ScoreBuffer(ScoreBuffer == 0) = NaN;
    %MODE and MEDIAN are quie similar, MEAN is different and may really
    %represent what is going on.
    if ~isfield(params.rules,'handleUNK')
        params.rules.handleUNK = 'takemean';
    end
    
    switch lower(params.rules.handleUNK)
        case 'takemode'
            %now what to do with zeros... use a winner take all stragity (mode)
            
            MeanIndex = mode(ScoreBuffer,1); %mode ignores NaN
            ScoreIndex(ScoreIndex == 0) = MeanIndex(ScoreIndex == 0);
        case 'takemedian'
            MeanIndex = nanmedian(ScoreBuffer,1); %mode ignores NaN
            ScoreIndex(ScoreIndex == 0) = MeanIndex(ScoreIndex == 0);
        case 'takemean'
            ScoreBuffer(ScoreBuffer == 1) = 6; % mean want average between 5 & 6  = 5.5 not 3
            MeanIndex = round(nanmean(ScoreBuffer,1)); %may be better to floor/ceil
            MeanIndex(MeanIndex == 6) = 1; %Put back to REM
            ScoreIndex(ScoreIndex == 0) = MeanIndex(ScoreIndex == 0);
        otherwise
            disp('     ... UNK epochs left UNK');
    end
end




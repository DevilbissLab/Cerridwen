function ScoreIndex = ArchitectureRules(ScoreIndex, params)
% ArchetectureRules is a utility function to repair mis-scored states.
% In general this applies to inappropiate state jumps and short,mis-classified states.
%
% Usage:
%  >> ScoreIndex = ArchetectureRules(ScoreIndex)
%
% Inputs:
%   ScoreIndex   - vector of Identified states
%
% Outputs:
%   ScoreIndex   - vector of repaired states.
%
% See also: 
%   ParameterFile for framework settings.
%
% Called by: RodentSleepScoring 
%
% Copyright (C) 2010 by David Devilbiss <ddevilbiss@wisc.edu>
%
% TODO: 
%       Vectorize if possible

ScoreIndex = ScoreIndex(:); % force to row vector
StageList = unique(ScoreIndex);
StageList(StageList == 0) = []; %ignore unscored states
minSegments = ceil(params.rules.minStateLength / params.Scoring.StageEpoch);
StableStateLength = 2;  %length of a state before check for transitions out of that state

%Find Short intervals witihin a stage and replace with that stage
for curStage = 1:length(StageList)
    stageIDX = ScoreIndex == StageList(curStage);

    for curMinSegment = minSegments:-1:1
        %look for transitions out and back into current state
        shorSegIDX = strfind(char(double(stageIDX)'), char([ones(1,StableStateLength) zeros(1,curMinSegment) ones(1,StableStateLength)])); % IDX of starts
        if ~isempty(shorSegIDX)
            shorSegIDX(:) = shorSegIDX + StableStateLength; %Fix Offset
            %Create index matrix
            shorSegIDX = repmat(shorSegIDX',1,curMinSegment);
            incrementor = repmat([0:curMinSegment-1],size(shorSegIDX,1),1);
            shorSegIDX = shorSegIDX + incrementor;
            
            ScoreIndex(shorSegIDX) = StageList(curStage);
        end
    end
end

%Stages can only oscilate within DS1/2 OR AW/QW
SWSstageIDX = ScoreIndex == 2 | ScoreIndex == 3;
AWstageIDX = ScoreIndex == 4 | ScoreIndex == 5;

for curMinSegment = minSegments:-1:1
shorSegIDX = strfind(char(double(SWSstageIDX)'), char([ones(1,StableStateLength) zeros(1,curMinSegment) ones(1,StableStateLength)])); % IDX of starts
if ~isempty(shorSegIDX)
    shorSegIDX(:) = shorSegIDX + StableStateLength; %Fix Offset and set as col vec.
    shorSegIDX = repmat(shorSegIDX',1,curMinSegment);
    incrementor = repmat([0:curMinSegment-1],size(shorSegIDX,1),1);
    shorSegIDX = shorSegIDX + incrementor;
    for curIDX = 1:size(shorSegIDX,1)*size(shorSegIDX,2)
        ScoreIndex(shorSegIDX(curIDX)) = ScoreIndex(shorSegIDX(curIDX)-1); %propagate last state across pieces
    end
end

shorSegIDX = strfind(char(double(AWstageIDX)'), char([ones(1,StableStateLength) zeros(1,curMinSegment) ones(1,StableStateLength)])); % IDX of starts
if ~isempty(shorSegIDX)
    shorSegIDX(:) = shorSegIDX + StableStateLength;
    shorSegIDX = repmat(shorSegIDX',1,curMinSegment);
    incrementor = repmat([0:curMinSegment-1],size(shorSegIDX,1),1);
    shorSegIDX = shorSegIDX + incrementor;
    for curIDX = 1:size(shorSegIDX,1)*size(shorSegIDX,2)
        ScoreIndex(shorSegIDX(curIDX)) = ScoreIndex(shorSegIDX(curIDX)-1);
    end
end
end

%Stages can only transititon from DS1/2 to REM & REM to DS1/2
REMStarts = find(diff(ScoreIndex == 1) == 1);
REMEnds = find(diff(ScoreIndex == 1) == -1);
for curREM = 1: length(REMStarts)
    switch ScoreIndex(REMStarts(curREM))
        case {4,5} %Transition from QW/AW
            REMendIDX = find(REMEnds > REMStarts(curREM),1,'first');
            ScoreIndex(REMStarts(curREM)+1: REMEnds(REMendIDX)) = ScoreIndex(REMStarts(curREM));
        case [0] %unknown score
            newREMstart = find(ScoreIndex(1:REMStarts(curREM) ~= 0),1,'last');
            if ScoreIndex(newREMstart) == 4 | ScoreIndex(newREMstart) == 5
                REMendIDX = find(REMEnds > REMStarts(curREM),1,'first');
                ScoreIndex(newREMstart+1: REMEnds(REMendIDX)) = ScoreIndex(newREMstart);
            end
        otherwise %Transition from DS1/2
            REMendIDX = find(REMEnds > REMStarts(curREM),1,'first');
            if isempty(intersect(ScoreIndex(REMEnds(REMendIDX)+1), [2,3]))  %returns to a state OTHER THAN DS1/2
                try
                ScoreIndex(REMStarts(curREM)+1: REMEnds(REMendIDX)) = ScoreIndex(REMEnds(curREM)+1); %Set as state entering
                catch
                ScoreIndex(REMStarts(curREM)+1: REMEnds(REMendIDX)) = 0; %setto UNK if last bin (dubious...)
                end
            end
    end
end

%look for specific illegal transitions
%Bad trans into QW >> set SWS1 to QW
shorSegIDX = strfind(char(double(ScoreIndex)'), char([5 3 4]));
ScoreIndex(shorSegIDX +1) = 4;

% Lastly...
%Stages cannot transititon from AW/QW to DS2 (set to prior stage)
DS2Starts = find(diff(ScoreIndex == 2) == 1);
DS2Ends = find(diff(ScoreIndex == 2) == -1);
for curDS2 = 1: length(DS2Starts)
    switch ScoreIndex(DS2Starts(curDS2)) 
        case {4,5} %Transition from QW/AW to DS2
            DS2endIDX = find(DS2Ends > DS2Starts(curDS2),1,'first');
            ScoreIndex(DS2Starts(curDS2)+1: DS2Ends(DS2endIDX)) = ScoreIndex(DS2Starts(curDS2));
        case [0] %unknown score
            newDS2start = find(ScoreIndex(1:DS2Starts(curDS2) ~= 0),1,'last');
            if ScoreIndex(newDS2start) == 4 | ScoreIndex(newDS2start) == 5
                DS2endIDX = find(DS2Ends > DS2Starts(curDS2),1,'first');
                ScoreIndex(newDS2start+1: DS2Ends(DS2endIDX)) = ScoreIndex(newDS2start);
            end
    end
end

%SET UNK TO KNOWN IF N = 2 SEMENTS ON EITHER SIDE ARE THE SAME STATE
% QW-DS2, first chunk of DS2 to DS1%%AW/AW-Move-DS2
% AW/AW-Move-DS1, first chunk of DS1 to QW
% short AWMovement->AW


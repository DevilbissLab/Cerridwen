function [ScoreIndex, ScoreIndex_medFilt] = StateTransitionRules(ScoreIndex, ValidScoreIndex, params)
% StateTransitionRules is a utility function to repair mis-scored Sleep-Wake states.
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
%       make narg in more robust and error check
%       use Valid Score Index
lkAround = floor(25 / params.Scoring.StageEpoch); %25 seconds

ScoreIndex = ScoreIndex(:); % force to row vector

%Apply REM/AW rules
%You can only transition in and out of rem through SWS1 and SWS2
%Stages can only transititon from DS1/2 to REM & REM to DS1/2
REMStarts = find(diff(ScoreIndex == 1) == 1); %<< find logic shift from 0 to 1
REMEnds = find(diff(ScoreIndex == 1) == -1);
for curREM = 1: length(REMStarts)
    switch ScoreIndex(REMStarts(curREM))
        case {4,5} %Transition from QW/AW << Mark REM as state entering REM
            REMendIDX = find(REMEnds > REMStarts(curREM),1,'first');
            ScoreIndex(REMStarts(curREM)+1: REMEnds(REMendIDX)) = ScoreIndex(REMStarts(curREM));
        case [0] %unknown score << Mark REM as state prior to UNK
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
                %else do nothing leave REM as it is
            end
            
    end
end

%Score index can contain zeros - UNK states
%The next addresses what to do with them.
ScoreIndex(ScoreIndex == 0) = NaN;
ScoreIndex_medFilt = nanmedfilt1(ScoreIndex,lkAround);

nBadShifts = nnz(abs(diff(ScoreIndex)) > 1);
PassCntr = 1;
while nBadShifts ~= 0
    disp(['     ... Fixing Skip States. Pass #',num2str(PassCntr),' Total Invalid Skips = ',num2str(nBadShifts)]);
        ScoreIndex = fixSkipStates(ScoreIndex, lkAround);
        PassCntr = PassCntr +1;
    if nBadShifts == nnz(abs(diff(ScoreIndex)) > 1);
        %we reached asymptope
        disp(['     ... Reached Asymptote. Total Invalid Skips = ',num2str(nnz(abs(diff(ScoreIndex)) > 1))]);
        break;
    else  
        nBadShifts = nnz(abs(diff(ScoreIndex)) > 1);
    end
end
ScoreIndex(isnan(ScoreIndex)) = 0;



function ScoreIndex = fixSkipStates(ScoreIndex, lkAround, StageShifts)
%apply no Skipping States
StageShifts = diff(ScoreIndex);
StageShiftsIDX = find(abs(StageShifts) >= 2);
for curScore = 1:length(StageShiftsIDX)
    if StageShiftsIDX(curScore) == 1
        if strfind(char(double(ScoreIndex(1:2))'), char([1 5])); %REM to AW
            ScoreIndex(1) = 5; %Set to AW
        elseif strfind(char(double(ScoreIndex(1:2))'), char([1 4])); %REM to AW
            ScoreIndex(1) = 5; %Set to AW
        elseif strfind(char(double(ScoreIndex(1:2))'), char([5 1]));
            ScoreIndex(1) = 1; %Set to REM
        elseif strfind(char(double(ScoreIndex(1:2))'), char([4 1]));
            ScoreIndex(1) = 1; %Set to REM
        end
        continue;
    end
    
    %    if StageShiftsIDX(curScore-1) == StageShiftsIDX(curScore)-1
    %        continue; %Ignore this jump because you fixed it last iteration
    %    end
    
    %have a look around
    
    curStageShift = StageShifts(StageShiftsIDX(curScore)); %for readability
    curStageShiftIDX = StageShiftsIDX(curScore); %for readability
    if curStageShiftIDX-lkAround <= 0
        MedStage = median(ScoreIndex(1:curStageShiftIDX+lkAround)); %note median does not have to mbe  an interger 
    elseif curStageShiftIDX+lkAround <= length(ScoreIndex)
        MedStage = median(ScoreIndex(curStageShiftIDX-lkAround:curStageShiftIDX+lkAround));
    else
        MedStage = median(ScoreIndex(curStageShiftIDX-lkAround:end));
    end
    if curStageShiftIDX-1 < 0
        MeanStage = (mean(ScoreIndex(1:curStageShiftIDX+1)));
    elseif curStageShiftIDX+1 <= length(ScoreIndex)
        MeanStage = (mean(ScoreIndex(curStageShiftIDX-1:curStageShiftIDX+1)));
    else
        MeanStage = (mean(ScoreIndex(curStageShiftIDX-1:end)));
    end
    
    % so we could build an extensive list of explicit rules or build
    % generalized rules.
    
   switch MedStage
        case {4,5} %IF you are generally in a waking state
            switch curStageShift
                case {2,3} %AND you have a waking shift of 2 to 3 states
                    % this is caused by some temporary dip in states and
                    % you are coming out of it
                                        
                    %check that it was not fixed previously;
                    if abs(diff([ScoreIndex(StageShiftsIDX(curScore)), ScoreIndex(StageShiftsIDX(curScore)+1)] )) >= 2 %not fixed
                        %Because you are indexing on the low state raise
                        %that one
                        ScoreIndex(curStageShiftIDX) = ceil(MeanStage); %set current state to local mean ceil
                    end
                 case {-2,-3} %AND you have a sleep shift of 2 to 3 states
                      % this is caused by some temporary dip in states and
                    % you are going into it
                    %check that it was not fixed previously;
                    if abs(diff([ScoreIndex(StageShiftsIDX(curScore)), ScoreIndex(StageShiftsIDX(curScore)+1)] )) >= 2 %not fixed
                        ScoreIndex(curStageShiftIDX+1) = ceil(MeanStage); %set future state to local mean ceil
                    end
                 end
        case {1,2,3} %IF you are generally in a sleeping state
            switch curStageShift
                case {2,3} %AND you have a waking shift of 2 to 3 states
                    % this is caused by some spike in states and
                    % you are going into the arousal
                    
                    %Allow this
                    
                case {-2,-3} %AND you have a sleeping shift of 2 to 3 states
                    % this is caused by some spike in states and
                    % you are coming out of an arousal
                    
                    %check that it was not fixed previously;
                    if abs(diff([ScoreIndex(StageShiftsIDX(curScore)), ScoreIndex(StageShiftsIDX(curScore)+1)] )) >= 2 %not fixed
                    ScoreIndex(curStageShiftIDX) = floor(MeanStage); %set current state to local mean floor
                    end
                    
            end
            %       otherwise
    end
end

% %orig approach..
% StageShifts = diff(ScoreIndex);
% StageShiftsIDX = find(abs(StageShifts) >= 2);
% for curScore = 1:length(StageShiftsIDX)
%    if StageShiftsIDX(curScore) == 1
%       if strfind(char(double(ScoreIndex(1:2))'), char([1 5])); %REM to AW
%           ScoreIndex(1) = 5; %Set to AW
%       elseif strfind(char(double(ScoreIndex(1:2))'), char([1 4])); %REM to AW
%           ScoreIndex(1) = 5; %Set to AW
%       elseif strfind(char(double(ScoreIndex(1:2))'), char([5 1]));
%           ScoreIndex(1) = 1; %Set to REM
%       elseif strfind(char(double(ScoreIndex(1:2))'), char([4 1]));
%           ScoreIndex(1) = 1; %Set to REM
%       end
%       continue;
%    end
%    curStage = StageShifts(StageShiftsIDX(curScore)); %for readability
%    curStageIDX = StageShiftsIDX(curScore); %for readability
%    if sign(curStage) == 1 %positive (more waking)
%        if strfind(char(double(ScoreIndex(curStageIDX-1:curStageIDX+1))'), char([4 3 5])); %QW->SWS1->AW %if last IDX - will fail
%         %SWS1 is likely stimulus artifact contamination
%         ScoreIndex(curStageIDX) = ScoreIndex(curStageIDX -1); %set as Prior State
%        elseif strfind(char(double(ScoreIndex(curStageIDX-1:curStageIDX+1))'), char([3 2 4])); %SWS1->SWS2->QW
%            ScoreIndex(curStageIDX) = ScoreIndex(curStageIDX -1); %set as Prior State
%            %disp(['info: StateTransitionRules >> no [3 2 4] transition defined at IDX: ',num2str(curStageIDX)]);
%        elseif strfind(char(double(ScoreIndex(curStageIDX-1:curStageIDX+1))'), char([3 2 5])); %SWS1->SWS2->AW
%            disp(['info: StateTransitionRules >> no [3 2 5] transition defined at IDX: ',num2str(curStageIDX)]);
%        end
%    end
% end
%
% % Do it again for negative shifts in a seperate loop because we may have
% % fixed them above
% StageShifts = diff(ScoreIndex);
% StageShiftsIDX = find(abs(StageShifts) >= 2);
% for curScore = 1:length(StageShiftsIDX)
%    if StageShiftsIDX(curScore) == 1
%         disp('WARNING: StateTransitionRules >> undefined transition at first epoch');
%       continue;
%    end
%    curStage = StageShifts(StageShiftsIDX(curScore)); %for readability
%    curStageIDX = StageShiftsIDX(curScore)+1; %for readability
%    if sign(curStage) == -1 %positive (more waking)
%        if strfind(char(double(ScoreIndex(curStageIDX-1:curStageIDX))'), char([5 2])); %QW->SWS1->AW %if last IDX - will fail
%         %SWS1 is likely stimulus artifact contamination
%         disp(['info: StateTransitionRules >> no [5 2] transition defined at IDX: ',num2str(curStageIDX)]);
%        elseif strfind(char(double(ScoreIndex(curStageIDX-1:curStageIDX+1))'), char([5 3 2])); %AW->SWS1->QW
%          ScoreIndex(curStageIDX) = ScoreIndex(curStageIDX +1); %set as posterior State
%        elseif strfind(char(double(ScoreIndex(curStageIDX-1:curStageIDX))'), char([5 3]));
%            disp(['info: StateTransitionRules >> no [5 3] transition defined at IDX: ',num2str(curStageIDX)]);
%        elseif strfind(char(double(ScoreIndex(curStageIDX-1:curStageIDX+1))'), char([4 2 4])); %QW->SWS2->QW
%             ScoreIndex(curStageIDX) = ScoreIndex(curStageIDX +1); %set as posterior State
%        elseif strfind(char(double(ScoreIndex(curStageIDX-1:curStageIDX+1))'), char([4 2 5])); %QW->SWS2->QW
%             ScoreIndex(curStageIDX) = ScoreIndex(curStageIDX +1); %set as posterior State
%        elseif strfind(char(double(ScoreIndex(curStageIDX-1:curStageIDX))'), char([4 2]));
%          disp(['info: StateTransitionRules >> no [4 2] transition defined at IDX: ',num2str(curStageIDX)]);
%        end
%    end
% end
% %sign can also return zero, but who cares. Right?
%

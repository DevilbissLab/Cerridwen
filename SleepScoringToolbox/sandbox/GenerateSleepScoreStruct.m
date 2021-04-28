function ScoreStruct = GenerateSleepScoreStruct(ScoreIndex,params,StartOffset)
%
% GenerateSleepScoreStruct - Generate Neuroexplorer compatible Struct from
%                           Sleep Scoring Index
%
% Usage:
%  >> ScoreStruct = GenerateSleepScoreStruct(ScoreIndex,params)
%
% Inputs:
%   ScoreIndex      - row vector of Sleep Stages of size params.Scoring.StageEpoch
%   params          - struct of parameters from ParamaterFile;
%
% Outputs:
%   ScoreStruct     - Neuroexplorer compatible struct
%
% See also:
%   ParameterFile for framework settings.
%   SleepScoreModule (caller)
%
% Copyright (C) 2010 by David Devilbiss <ddevilbiss@wisc.edu>
%
% ToDo: This needs to trim unused structs

ScoreIndex = ScoreIndex(:);
%there are 6 possible states [0:5] each representing a sleepstage
for n = 1:6
    switch n
        case 1 %unspecified State
            ScoreStruct(n,1).name = 'Unknown';
            ScoreStruct(n,1).intStarts = find(ScoreIndex == 0);
            ScoreStruct(n,1).intEnds = ScoreStruct(n,1).intStarts +1;

        case 2 %paradoxical sleep
            ScoreStruct(n,1).name = 'REM';
            ScoreStruct(n,1).intStarts = find(ScoreIndex == 1);
            ScoreStruct(n,1).intEnds = ScoreStruct(n,1).intStarts +1;

        case 3 %SW sleep (2)
            ScoreStruct(n,1).name = 'DS2';
            ScoreStruct(n,1).intStarts = find(ScoreIndex == 2);
            ScoreStruct(n,1).intEnds = ScoreStruct(n,1).intStarts +1;

        case 4 %SW sleep (1)
            ScoreStruct(n,1).name = 'DS1';
            ScoreStruct(n,1).intStarts = find(ScoreIndex == 3);
            ScoreStruct(n,1).intEnds = ScoreStruct(n,1).intStarts +1;
            
        case 5 %waking
            ScoreStruct(n,1).name = 'QuietWaking';
            ScoreStruct(n,1).intStarts = find(ScoreIndex == 4);
            ScoreStruct(n,1).intEnds = ScoreStruct(n,1).intStarts +1;
            
        case 6 %active wake
            ScoreStruct(n,1).name = 'ActiveWaking';
            ScoreStruct(n,1).intStarts = find(ScoreIndex == 5);
            ScoreStruct(n,1).intEnds = ScoreStruct(n,1).intStarts +1;
            
        otherwise %unspecified State
            ScoreStruct(n,1).name = 'Unknown';
            ScoreStruct(n,1).intStarts = find(ScoreIndex > 5);
            ScoreStruct(n,1).intEnds = ScoreStruct(n,1).intStarts +1;
    end

    if ~isempty(ScoreStruct(n).intStarts)
    %convert to seconds 
    ScoreStruct(n,1).intStarts = ((ScoreStruct(n).intStarts -1) * params.Scoring.StageEpoch + StartOffset)';
    ScoreStruct(n,1).intEnds = ((ScoreStruct(n).intEnds -1) * params.Scoring.StageEpoch + StartOffset)';
    
    %combine adjacent scorings
    endsIDX = [ScoreStruct(n).intStarts(2:end) == ScoreStruct(n).intEnds(1:end-1), false]; 
    while any(endsIDX == 1)    
        ScoreStruct(n,1).intEnds(endsIDX) = [];
        startsIDX = [false, endsIDX(1:end-1)];
        ScoreStruct(n,1).intStarts(startsIDX) = [];
        endsIDX = ScoreStruct(n).intStarts(2:end,1) == ScoreStruct(n).intEnds(1:end-1,1);
    end
    else
        ScoreStruct(n) = [];
    end
end
%% run again as 3 states
ScoreStructLength = length(ScoreStruct);
for n = 1:6
    switch n
        case 1 %unspecified State
            ScoreStruct(ScoreStructLength+2,1).name = 'Intermed';
            if isempty(ScoreStruct(ScoreStructLength+2,1).intStarts)
                ScoreStruct(ScoreStructLength+2,1).intStarts = find(ScoreIndex == 0);            
            else
                ScoreStruct(ScoreStructLength+2,1).intStarts = sort([ScoreStruct(ScoreStructLength+2,1).intStarts; find(ScoreIndex == 0)]);
            end
            ScoreStruct(ScoreStructLength+2,1).intEnds = ScoreStruct(ScoreStructLength+2,1).intStarts +1;

        case 2 %paradoxical sleep
            ScoreStruct(ScoreStructLength+1,1).name = 'Desynch';
            if isempty(ScoreStruct(ScoreStructLength+1,1).intStarts)
                ScoreStruct(ScoreStructLength+1,1).intStarts = find(ScoreIndex == 1);
            else
                ScoreStruct(ScoreStructLength+1,1).intStarts = sort([ScoreStruct(ScoreStructLength+1,1).intStarts; find(ScoreIndex == 1)]);
            end
            ScoreStruct(ScoreStructLength+1,1).intEnds = ScoreStruct(ScoreStructLength+1,1).intStarts +1;

        case 3 %SW sleep (2)
            ScoreStruct(ScoreStructLength+3,1).name = 'Synch';
            if isempty(ScoreStruct(ScoreStructLength+3,1).intStarts)
                ScoreStruct(ScoreStructLength+3,1).intStarts = find(ScoreIndex == 2);
            else
                ScoreStruct(ScoreStructLength+3,1).intStarts = sort([ScoreStruct(ScoreStructLength+3,1).intStarts; find(ScoreIndex == 2)]);
            end
            ScoreStruct(ScoreStructLength+3,1).intEnds = ScoreStruct(ScoreStructLength+3,1).intStarts +1;

        case 4 %SW sleep (1)
            ScoreStruct(ScoreStructLength+3,1).name = 'Synch';
            if isempty(ScoreStruct(ScoreStructLength+3,1).intStarts)
                ScoreStruct(ScoreStructLength+3,1).intStarts = find(ScoreIndex == 3);
            else
                ScoreStruct(ScoreStructLength+3,1).intStarts = sort([ScoreStruct(ScoreStructLength+3,1).intStarts; find(ScoreIndex == 3)]);
            end
            ScoreStruct(ScoreStructLength+3,1).intEnds = ScoreStruct(ScoreStructLength+3,1).intStarts +1;
            
        case 5 %waking
            ScoreStruct(ScoreStructLength+2,1).name = 'Intermed';
            if isempty(ScoreStruct(ScoreStructLength+2,1).intStarts)
                ScoreStruct(ScoreStructLength+2,1).intStarts = find(ScoreIndex == 4);
            else
                ScoreStruct(ScoreStructLength+2,1).intStarts = sort([ScoreStruct(ScoreStructLength+2,1).intStarts; find(ScoreIndex == 4)]);
            end
            ScoreStruct(ScoreStructLength+2,1).intEnds = ScoreStruct(ScoreStructLength+2,1).intStarts +1;
            
        case 6 %active wake
            ScoreStruct(ScoreStructLength+1,1).name = 'Desynch';
            if isempty(ScoreStruct(ScoreStructLength+1,1).intStarts)
                ScoreStruct(ScoreStructLength+1,1).intStarts = find(ScoreIndex == 5);
            else
                ScoreStruct(ScoreStructLength+1,1).intStarts = sort([ScoreStruct(ScoreStructLength+1,1).intStarts; find(ScoreIndex == 5)]);
            end
            ScoreStruct(ScoreStructLength+1,1).intEnds = ScoreStruct(ScoreStructLength+1,1).intStarts +1;
            
        otherwise %unspecified State
            ScoreStruct(ScoreStructLength+2,1).name = 'Intermed';
            if isempty(ScoreStruct(ScoreStructLength+2,1).intStarts)
                ScoreStruct(ScoreStructLength+2,1).intStarts = find(ScoreIndex > 5);
            else
                ScoreStruct(ScoreStructLength+2,1).intStarts = sort([ScoreStruct(ScoreStructLength+2,1).intStarts; find(ScoreIndex > 5)]);
            end
            ScoreStruct(ScoreStructLength+2,1).intEnds = ScoreStruct(ScoreStructLength+2,1).intStarts +1;
    end
end
for n = 3:-1:1
    try
    if ~isempty(ScoreStruct(ScoreStructLength+n).intStarts)
    %convert to seconds 
    ScoreStruct(ScoreStructLength+n,1).intStarts = ((ScoreStruct(ScoreStructLength+n).intStarts -1) * params.Scoring.StageEpoch + StartOffset)';
    ScoreStruct(ScoreStructLength+n,1).intEnds = ((ScoreStruct(ScoreStructLength+n).intEnds -1) * params.Scoring.StageEpoch + StartOffset)';
    
    %combine adjacent scorings
    endsIDX = [ScoreStruct(ScoreStructLength+n).intStarts(2:end) == ScoreStruct(ScoreStructLength+n).intEnds(1:end-1), false]; 
    while any(endsIDX == 1)    
        ScoreStruct(ScoreStructLength+n,1).intEnds(endsIDX) = [];
        startsIDX = [false, endsIDX(1:end-1)];
        ScoreStruct(ScoreStructLength+n,1).intStarts(startsIDX) = [];
        endsIDX = ScoreStruct(ScoreStructLength+n).intStarts(2:end,1) == ScoreStruct(ScoreStructLength+n).intEnds(1:end-1,1);
    end
    else
        ScoreStruct(ScoreStructLength+n) = [];
    end
    catch ME
        disp(['   ... Skipping nonexistant ScoreStruct #',num2str(ScoreStructLength+n)]);
    end
end

%% now add extra Information needed by I/O functions
for n = length(ScoreStruct):-1:1
    if isempty(ScoreStruct(n).name)
        ScoreStruct(n) = [];
    else
        %pad Struct for NexFile of Type 2 (interval)
        ScoreStruct = addAncInfo(ScoreStruct,n,length(ScoreStruct(n).intStarts),2);
    end
end
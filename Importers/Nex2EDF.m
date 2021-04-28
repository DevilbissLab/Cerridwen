function [] = Nex2EDF(filename)
% Nex2EDF is a helper function to import Neuroexplorer Files
% and .Dat Files (UW Psych EEG recording format) and write them in EDF
% format (European Data Format).
%
% Usage:
%  >> [] = Nex2EDF(filename)
%
% Inputs:
%   filename   - Filename of file;
%
% Outputs:
%   <none>
%
% See also:
%   Requires: Biosig Toolbox http://biosig.sf.net/
%
% Copyright (C) 2010 by David Devilbiss <ddevilbiss@wisc.edu>
%  v. 1.0 DMD 10Oct2010
%
% NOTE: This is only a Skeleton of a function and should be used as a guide
% only.


%% No Inputs (Open Dialog and import data):
if nargin < 1
    [FileName,PathName,FilterIndex] = uigetfile({'*.nex','Neuroexploder File (*.nex)';'*.dat','Rat Physio File (*.dat)'},'Select Neuroexplorer File To Be Scored');
else
    [FileName,PathName,FilterIndex] = fileparts(filename);
    if strcmpi(FilterIndex,nex)
        FilterIndex = 1;
    else
        FilterIndex = 2;
    end
end

if FilterIndex == 1;
    NexStruct = fullreadNexFile(fullfile(PathName,FileName));
elseif FilterIndex == 2;
    [EEGData,PHYSIO_HEADER] = ReadBerridgeDATFile(fullfile(PathName,FileName));
    PHYSIO_HEADER.filename = fullfile(PathName,FileName);
    NexStruct = Dat2Nex(PHYSIO_HEADER,EEGData);
    clear EEGData PHYSIO_HEADER;
else
    return;
end

if isfield(NexStruct,'contvars')
%select Channel to EEG score
    contVarStruct = [NexStruct.contvars{:}];
    ADnames = {contVarStruct.name};
    [EEGchan,OK] = listdlg('PromptString','Choose EEG Channel to Analyze','SelectionMode','Single','ListString',ADnames);
    if ~OK
        disp('No EEG channel selected: Terminating Function');
        return;
    else
        %extract EEG/EMG data into common var's (EEG,EMG)
        chanNum = find(strcmp({contVarStruct.name},ADnames{EEGchan}));
        DATA = contVarStruct(chanNum).data;
    end

    
%% Detect Artifact for file segment using EEG
%THIS SECTION WAS COMMENTED OUT FOR GENERAL FUNCTION USAGE.  
% %This will return a struct of intervals relating to artifacts
% 
% %load Sleep Scoring parameters
% params = ParameterFile();
% 
% disp('detecting Artifacts... ');
%     ArtifactStruct = ArtifactDetection(params,DATA);
%     ArtifactStruct.name = 'Artifacts';
% 
% % Artifact function here
% disp('Cleaning EEG Trace...');
% DATA = ClearArtifacts(DATA, ArtifactStruct, params, []);


%% Write data to EDF
    % build header
    HDR.FileName = fullfile(PathName,[FileName(1:end-4),datestr(now,'HHMMSS'),'.edf']);
    HDR.SampleRate = contVarStruct(chanNum).ADFrequency;
    gdftyp = 16;
    HDR.TYPE = 'EDF';
    [HDR.SPR, HDR.NS] = size(DATA);
    HDR.NRec = 1;
    HDR.PhysMax = max(DATA,[],1);
    HDR.PhysMin = min(DATA,[],1);
    ix = find(HDR.PhysMax == HDR.PhysMin);
    HDR.PhysMin(ix) = HDR.PhysMin(ix) - 1;
    HDR.DigMin = double(int16(HDR.PhysMin / contVarStruct(chanNum).ADtoMV + contVarStruct(chanNum).MVOfffset));
    HDR.DigMax = double(int16(HDR.PhysMax / contVarStruct(chanNum).ADtoMV + contVarStruct(chanNum).MVOfffset));
    HDR.T0 = datevec(now);
    HDR.PhysDimCode = 4256; %mV
    
    %convert to int16
%DATA = DATA / contVarStruct(chanNum).ADtoMV + contVarStruct(chanNum).MVOfffset;
    
    edfHDR = sopen(HDR,'w');
        %edfHDR.FLAG.UCAL = true;
        %edfHDR.RID = ['Startdate ',datestr(edfHDR.T0,'dd-mmm-yyyy')];
        warning off;
    edfHDR = swrite(edfHDR,DATA);
        warning on;
    edfHDR = sclose(edfHDR);
else
    disp('File does not contain continous variables. EDF NOT written.')
end
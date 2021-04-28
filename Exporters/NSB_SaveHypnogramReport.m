function [status, filenames] = NSB_SaveHypnogramReport(DataStruct, options)
%[status, filenames] = NSB_SaveHypnogramReport(DataStruct, options)
% Function used to Generate a MSword document and .csv containing Sleep
% Report Values
%
% Inputs:
%   DataStruct                   - (struct) NSB DataStruct
%   options                      - (struct)
%       .handles                    (struct) NSB Handles Structure
%       .EEGChannel                 (double) Channel Number of EEG used to SleepScore
%       .EMGChannel                 (double) Channel Number of EMG used to SleepScore
%       .ActivityChannel            (double) Channel Number of Activity Channel used to SleepScore 
%       .HypnogramChannel           (double) Channel Number of generated Hypnogram Channel
%       .curFile                    (double) current file/line of StudyDesign
%       .logfile                    (string) path and name of log file
%
% Outputs:
%   status                      - (logical) return value
%   filenames                   - (struct) status message if error
%       .type
%       .metadata
%       .filename
%
%Dependencies: 
% Word Toolbox
% Copyright (c) 2010, Ivar Eskerud Smith
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without 
% modification, are permitted provided that the following conditions are 
% met:
% 
%     * Redistributions of source code must retain the above copyright 
%       notice, this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright 
%       notice, this list of conditions and the following disclaimer in 
%       the documentation and/or other materials provided with the distribution
%       
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
% POSSIBILITY OF SUCH DAMAGE.
%
% Notes: Requires MSword to be installed on Windows machine
%        If recordings are > 24 hours this function only quantifies the 1st
%        24 hours
%
%
% Written By David M. Devilbiss
% NexStep Biomarkers, LLC. (info@nexstepbiomarkers.com)
% August 7 2013, Version 1.0
%
%ToDo:
% Add activity (if available) to Hypnogram
% Add Licensing
% better logging

%http://www.docstoc.com/docs/13081442/Example-Diagnostic-Sleep-Study-Report

status = false;
[OutputDir,trash1,trash2] = fileparts(DataStruct.Filename);
OutputDir = fullfile(OutputDir,'NSB_Output');
CSVOutputFile = ['NSB_SleepScoringAnalysis_',datestr(DataStruct.StartDate,29),'_',DataStruct.SubjectID,'_',DataStruct.Channel(options.HypnogramChannel).Name,'_',num2str(options.EEGChannel)];
SleepReportFile = ['NSB_SleepReport_',datestr(DataStruct.StartDate,29),'_',DataStruct.SubjectID,'_',DataStruct.Channel(options.HypnogramChannel).Name,'_',num2str(options.EEGChannel)];
%make sure output file has no special characters.
CSVOutputFile = regexprep(CSVOutputFile, '[<>:"?*\s]', '-', 'preservecase');
SleepReportFile = regexprep(SleepReportFile, '[<>:"?*\s]', '-', 'preservecase');

if ~isfield(options, 'MatlabPost2014')
    if isfield(options.handles.parameters.PreClinicalFramework,'MatlabPost2014')
        options.MatlabPost2014 = options.handles.parameters.PreClinicalFramework.MatlabPost2014;
    else
        options.MatlabPost2014 = false;
    end
end

existXLSax = true;
if exist(OutputDir,'dir') == 0
    mkdir(OutputDir)
end
filenames.type = 'Hypnogram';

%% Calculate Metrics
StartDateVec = datevec(DataStruct.StartDate);
if ~isfield(DataStruct.Channel(options.HypnogramChannel), 'ts') %<< this may always be filled
    if isfield(DataStruct.Channel(options.HypnogramChannel), 'timestamps')
        DataStruct.Channel(options.HypnogramChannel).ts = DataStruct.Channel(options.HypnogramChannel).timestamps; %<<< this may fail is NEX timestamps are relative
    else
        BinTime = (0:length(DataStruct.Channel(options.HypnogramChannel).Data)-1) / DataStruct.Channel(options.HypnogramChannel).Hz;
        BinTime = BinTime(:);
%         if strcmpi(DataStruct.FileFormat,'.dsi')
%             StartDateVec(:,4) = StartDateVec(:,4) + options.handles.parameters.PreClinicalFramework.File.DSIoffset;
%         end
        DataStruct.Channel(options.HypnogramChannel).ts = datenum([repmat(StartDateVec(1:5),length(BinTime),1), BinTime+StartDateVec(6)]);
        clear BinTime;
    end
else
    %check for relative time or datestr
    if length(DataStruct.Channel(options.HypnogramChannel).ts) > 5
    if ~any(mod(DataStruct.Channel(options.HypnogramChannel).ts(1:5),1)) %are these integers?
            %~isa datenum
            %increment from startdate
            ts = repmat(datevec(DataStruct.StartDate),length( DataStruct.Channel(options.HypnogramChannel).ts),1);
             DataStruct.Channel(options.HypnogramChannel).ts = datenum([ts(:,1:5),ts(:,6) + DataStruct.Channel(options.HypnogramChannel).ts(:)]);
             clear ts;
    end
    end       
end

%% Open Word Document
try
    WordDocOpen = true;
doc_obj = Word(options.TemplateFile, true, true);
goTo( doc_obj, 'wdGoToLine','wdGoToLast' ); %Go to the end.
catch ME
    WordDocOpen = false;
    errorstr = ['ERROR: NSB_SaveHypnogramReport >> Failed to open Word ActiveX object. ',ME.message];
    NSBlog(options.logfile,errorstr);
    disp(errorstr);
end

try
if WordDocOpen
% Analysis Parameters
txtstr = 'Analysis Parameters';
addText( doc_obj,txtstr, 'Normal', 1 );
insertLine( doc_obj, 0);

txtstr = [char(9),'Cerridwen: ', options.handles.parameters.PreClinicalFramework.Name,' Ver. ',options.handles.parameters.PreClinicalFramework.Version];
addText( doc_obj,txtstr, 'Normal', 1 );

txtstr = [char(9),'Analysis Date: ', datestr(now, 'mmmm dd, yyyy')];
addText( doc_obj,txtstr, 'Normal', 1 );

txtstr = [char(9),'Analysis Parameter File: ', get(options.handles.AnalysisParameters_txt,'String')];
addText( doc_obj,txtstr, 'Normal', 1 );

txtstr = [char(9),'Sleep Scoring Type: ', options.handles.parameters.PreClinicalFramework.Scoring.ScoringType];
addText( doc_obj,txtstr, 'Normal', 1 );

if options.handles.parameters.PreClinicalFramework.rules.ApplyArchitectureRules
    txtstr = [char(9),'Applied Architecture Rules: True'];
else
    txtstr = [char(9),'Applied Architecture Rules: False'];
end
addText( doc_obj,txtstr, 'Normal', 1 );

% FYI: options.handles.StudyDesign{options.curFile}.SleepCycleStart is a
% date vec so generate these as datevecs
%SleepCycleStart_datenum = datevec(DataStruct.Channel(options.EEGChannel).ts(1));
if isfield(options.handles.StudyDesign{options.curFile},'SleepCycleStart')
    SleepCycleStart_datenum = datenum([StartDateVec(1:3), options.handles.StudyDesign{options.curFile}.SleepCycleStart(4:6)]); %Use start date and replace time with SleepCycleStart
    SleepCycleEnd_datenum = StartDateVec;
    if datenum(options.handles.StudyDesign{options.curFile}.SleepCycleStart) < datenum(options.handles.StudyDesign{options.curFile}.SleepCycleEnd) %Sleep cycle ends same day (rats)
        SleepCycleEnd_datenum = datenum([SleepCycleEnd_datenum(1:3), options.handles.StudyDesign{options.curFile}.SleepCycleEnd(4:6)]); %Use start date and replace time with SleepCycleStart
    else
        SleepCycleEnd_datenum(3) = SleepCycleEnd_datenum(3)+1; %add a day
        SleepCycleEnd_datenum = datenum([SleepCycleEnd_datenum(1:3), options.handles.StudyDesign{options.curFile}.SleepCycleEnd(4:6)]); %Use start date and replace time with SleepCycleEnd
    end
else
    SleepCycleStart_datenum = StartDateVec;
    SleepCycleEnd_datenum = StartDateVec;
    SleepCycleEnd_datenum(3) = SleepCycleEnd_datenum(3)+1; %add a day
end

if isfield(options.handles.StudyDesign{options.curFile},'SleepCycleStart')
    if all(isnan(options.handles.StudyDesign{options.curFile}.SleepCycleStart))
        %err
        SleepCycleStart_IDX = 1;
        txtstr = [char(9),'Sleep Cycle Start Time: Not Specified. Using the begining of the File.'];
    else
        SleepCycleStart_IDX = find(DataStruct.Channel(options.HypnogramChannel).ts >= SleepCycleStart_datenum,1,'first'); %% Hypnogram does not return TimeStamps .ts
        txtstr = [char(9),'Sleep Cycle Start Time: ', datestr(datenum(options.handles.StudyDesign{options.curFile}.SleepCycleStart))];
    end
else
    %err
    SleepCycleStart_IDX = 1;
    txtstr = [char(9),'Sleep Cycle Start Time: Not Specified. Using the begining of the File'];
end
addText( doc_obj,txtstr, 'Normal', 1 );

if isfield(options.handles.StudyDesign{options.curFile},'SleepCycleEnd')
    if all(isnan(options.handles.StudyDesign{options.curFile}.SleepCycleEnd))
        %Not an error, just not specified
        SleepCycleEnd_IDX = length(DataStruct.Channel(options.HypnogramChannel).Data);
        txtstr = [char(9),'Sleep Cycle End Time: Not Specified. Using the end of the File'];
    else
        SleepCycleEnd_IDX = find(DataStruct.Channel(options.HypnogramChannel).ts >= SleepCycleEnd_datenum,1,'first');
        txtstr = [char(9),'Sleep Cycle End Time: ', datestr(datenum(options.handles.StudyDesign{options.curFile}.SleepCycleEnd))];
    end
else
    %Not an error, just not specified
    SleepCycleEnd_IDX = length(DataStruct.Channel(options.HypnogramChannel).Data);
    txtstr = [char(9),'Sleep Cycle End Time: Not Specified. Using the end of the File'];
end
addText( doc_obj,txtstr, 'Normal', 2 );

% Subject Information
txtstr = 'Subject Information';
addText( doc_obj,txtstr, 'Normal', 1 );
insertLine( doc_obj, 0);

txtstr = [char(9),'Subject ID: ',DataStruct.SubjectID];
addText( doc_obj,txtstr, 'Normal', 1 );

txtstr = [char(9),'Study Date: ',datestr(DataStruct.StartDate,1),' starting at ',datestr(DataStruct.StartDate,14)];
addText( doc_obj,txtstr, 'Normal', 1 );

if ~iscell(options.handles.StudyDesign{options.curFile,2})
    txtstr = [char(9),'Group: ',options.handles.StudyDesign{options.curFile,2}.group];
    addText( doc_obj,txtstr, 'Normal', 1 );
    txtstr = [char(9),'Project: ',options.handles.StudyDesign{options.curFile,2}.project];
    addText( doc_obj,txtstr, 'Normal', 1 );
    txtstr = [char(9),'Study ID: ',options.handles.StudyDesign{options.curFile,2}.studyID];
    addText( doc_obj,txtstr, 'Normal', 1 );
    txtstr = [char(9),'Dose: ',options.handles.StudyDesign{options.curFile,2}.dose];
    addText( doc_obj,txtstr, 'Normal', 1 );
else
    txtstr = [char(9),'Group: Not Available'];
    addText( doc_obj,txtstr, 'Normal', 1 );
    txtstr = [char(9),'Project: Not Available'];
    addText( doc_obj,txtstr, 'Normal', 1 );
    txtstr = [char(9),'Study ID: Not Available'];
    addText( doc_obj,txtstr, 'Normal', 1 );
    txtstr = [char(9),'Dose: Not Available'];
    addText( doc_obj,txtstr, 'Normal', 1 );
end

% Sleep Statistics
addText( doc_obj,'', 'Normal', 1 );
txtstr = 'Sleep Statistics';
addText( doc_obj,txtstr, 'Normal', 1 );
insertLine( doc_obj, 0);
end

%Calculate Statisitcs
SleepPeriodDuration  = datestr(datenum([0 0 0 0 0  etime(options.handles.StudyDesign{options.curFile}.SleepCycleEnd,options.handles.StudyDesign{options.curFile}.SleepCycleStart)]),13); %(hours:Minutes:sec)

Sleep_Latency_IDX = find(DataStruct.Channel(options.HypnogramChannel).Data(SleepCycleStart_IDX:SleepCycleEnd_IDX) > 1, 1, 'first');
if ~isempty(Sleep_Latency_IDX)
Sleep_Latency = datestr(datenum([0 0 0 0 0 (Sleep_Latency_IDX/DataStruct.Channel(options.HypnogramChannel).Hz)]),13); %(hours:Minutes:sec)
else
    Sleep_Latency = 'NA';
end

PS_Latency_IDX = find(DataStruct.Channel(options.HypnogramChannel).Data(SleepCycleStart_IDX:SleepCycleEnd_IDX) == 5, 1, 'first');
if ~isempty(PS_Latency_IDX)
PS_Latency = datestr(datenum([0 0 0 0 0 (PS_Latency_IDX/DataStruct.Channel(options.HypnogramChannel).Hz)]),13); %(hours:Minutes:sec)
else
    PS_Latency = 'NA';
end
       
FirstWake_Latency_IDX = find(DataStruct.Channel(options.HypnogramChannel).Data(Sleep_Latency_IDX:SleepCycleEnd_IDX) < 2, 1, 'first');
if ~isempty(FirstWake_Latency_IDX)
FirstWake_Latency = datestr(datenum([0 0 0 0 0 (FirstWake_Latency_IDX/DataStruct.Channel(options.HypnogramChannel).Hz)]),13); %(hours:Minutes:sec)
else
    FirstWake_Latency = 'NA';
end

%not implemented (yet)
SleepEfficiency = []; %(hours:Minutes:sec)

PS_SleepTime_IDX = DataStruct.Channel(options.HypnogramChannel).Data(SleepCycleStart_IDX:SleepCycleEnd_IDX) == 5;
SWS2_SleepTime_IDX = DataStruct.Channel(options.HypnogramChannel).Data(SleepCycleStart_IDX:SleepCycleEnd_IDX) == 4;
SWS1_SleepTime_IDX = DataStruct.Channel(options.HypnogramChannel).Data(SleepCycleStart_IDX:SleepCycleEnd_IDX) == 2;
QW_SleepTime_IDX = DataStruct.Channel(options.HypnogramChannel).Data(SleepCycleStart_IDX:SleepCycleEnd_IDX) == 1;
AW_SleepTime_IDX = DataStruct.Channel(options.HypnogramChannel).Data(SleepCycleStart_IDX:SleepCycleEnd_IDX) == 0;
nPS_SleepTime_IDX = SWS1_SleepTime_IDX | SWS2_SleepTime_IDX;
TotalSleepTime_IDX = SWS1_SleepTime_IDX | SWS2_SleepTime_IDX | PS_SleepTime_IDX;
TotalWake_IDX = QW_SleepTime_IDX | AW_SleepTime_IDX;

TotalSleepTime = datestr(datenum([0 0 0 0 0 (sum(TotalSleepTime_IDX)/DataStruct.Channel(options.HypnogramChannel).Hz)]),13); %(hours:Minutes:sec)
PS_SleepTime = datestr(datenum([0 0 0 0 0 (sum(PS_SleepTime_IDX)/DataStruct.Channel(options.HypnogramChannel).Hz)]),13); %(hours:Minutes:sec)
nPS_SleepTime = datestr(datenum([0 0 0 0 0 (sum(nPS_SleepTime_IDX)/DataStruct.Channel(options.HypnogramChannel).Hz)]),13); %(hours:Minutes:sec)
SWS2_SleepTime = datestr(datenum([0 0 0 0 0 (sum(SWS2_SleepTime_IDX)/DataStruct.Channel(options.HypnogramChannel).Hz)]),13); %(hours:Minutes:sec)
SWS1_SleepTime = datestr(datenum([0 0 0 0 0 (sum(SWS1_SleepTime_IDX)/DataStruct.Channel(options.HypnogramChannel).Hz)]),13); %(hours:Minutes:sec)
QW_SleepTime = datestr(datenum([0 0 0 0 0 (sum(QW_SleepTime_IDX)/DataStruct.Channel(options.HypnogramChannel).Hz)]),13); %(hours:Minutes:sec)
AW_SleepTime = datestr(datenum([0 0 0 0 0 (sum(AW_SleepTime_IDX)/DataStruct.Channel(options.HypnogramChannel).Hz)]),13); %(hours:Minutes:sec)
TotalWake = datestr(datenum([0 0 0 0 0 (sum(TotalWake_IDX)/DataStruct.Channel(options.HypnogramChannel).Hz)]),13); %(hours:Minutes:sec)

if WordDocOpen
txtstr = [char(9),char(9),char(9),char(9),char(9),char(9),char(9),'(HH:MM:SS)'];
addText( doc_obj,txtstr, 'Normal', 1 );
txtstr = [char(9),'Total time in sleep cycle period:',char(9),char(9),SleepPeriodDuration];
addText( doc_obj,txtstr, 'Normal', 1 );
txtstr = [char(9),'Sleep Latency:',char(9),char(9),char(9),char(9),char(9),Sleep_Latency]; %error << can be multirow ?!?
addText( doc_obj,txtstr, 'Normal', 1 );
txtstr = [char(9),'REM/PS Latency:',char(9),char(9),char(9),char(9),PS_Latency];
addText( doc_obj,txtstr, 'Normal', 1 );
txtstr = [char(9),'Latency to Wake after Sleep onset:',char(9),char(9),FirstWake_Latency];
addText( doc_obj,txtstr, 'Normal', 2 );
txtstr = [char(9),'Total Sleep Time:',char(9),char(9),char(9),char(9),TotalSleepTime];
addText( doc_obj,txtstr, 'Normal', 1 );
txtstr = [char(9),'REM/PS Sleep Time:',char(9),char(9),char(9),char(9),PS_SleepTime];
addText( doc_obj,txtstr, 'Normal', 1 );
txtstr = [char(9),'non-REM Sleep Time:',char(9),char(9),char(9),nPS_SleepTime];
addText( doc_obj,txtstr, 'Normal', 1 );
txtstr = [char(9),'SWS1 Seep Time:',char(9),char(9),char(9),char(9),SWS1_SleepTime];
addText( doc_obj,txtstr, 'Normal', 1 );
txtstr = [char(9),'SWS2 Sleep Time:',char(9),char(9),char(9),char(9),SWS2_SleepTime];
addText( doc_obj,txtstr, 'Normal', 1 );

% Sleep Statistics
addText( doc_obj,'', 'Normal', 1 );
txtstr = 'Arousal Statistics';
addText( doc_obj,txtstr, 'Normal', 1 );
insertLine( doc_obj, 0);

txtstr = [char(9),char(9),char(9),char(9),char(9),char(9),char(9),'(HH:MM:SS)'];
addText( doc_obj,txtstr, 'Normal', 1 );
txtstr = [char(9),'Total Waking Time in sleep cycle period:',char(9),TotalWake];
addText( doc_obj,txtstr, 'Normal', 1 );
txtstr = [char(9),'Quiet Waking Time:',char(9),char(9),char(9),char(9),QW_SleepTime];
addText( doc_obj,txtstr, 'Normal', 1 );
txtstr = [char(9),'Active Waking Time:',char(9),char(9),char(9),char(9),AW_SleepTime];
addText( doc_obj,txtstr, 'Normal', 1 );

pageBreak( doc_obj );

% Hypnogram
txtstr = ['Page 2: Subject ID: ',DataStruct.SubjectID];
addText( doc_obj,txtstr, 'Normal', 1 );
addText( doc_obj,'', 'Normal', 1 );
txtstr = 'Sleep Hypnogram';
addText( doc_obj,txtstr, 'Normal', 1 );
insertLine( doc_obj, 0);

%Build Hypnogram
nPlots = 2;
if ~isempty(options.EMGChannel), nPlots = nPlots +1; end
if ~isempty(options.ActivityChannel), nPlots = nPlots +1; end

h_fig = figure;
%Hypnogram
ax(1) = subplot(nPlots,1,1);
hold on;
ph1 = plot(ax(1),DataStruct.Channel(options.HypnogramChannel).Data,'k');
psIDX = NaN(length(DataStruct.Channel(options.HypnogramChannel).Data),1);
psIDX(DataStruct.Channel(options.HypnogramChannel).Data == 5) = 5;
ph2 = plot(ax(1),psIDX,'r','LineWidth',5);
%could add other colors
set(ax(1),'YTick',0:5);
set(ax(1),'YTickLabel',{'WAKE-ACTIVE','WAKE','SWS1','','SWS2','PS'});
set(ax(1),'YLim',[-1 6]);
StageEpoch = options.handles.parameters.PreClinicalFramework.Scoring.StageEpoch;
ts =  (0:StageEpoch:(length(DataStruct.Channel(options.HypnogramChannel).Data)*StageEpoch)) /60; %in minutes
set(ax(1),'XLim',[0 length(ts)]);
if ts(end) <= 60
    if options.MatlabPost2014
        xlabel(ax(1),'Time (mins)');
    else
        xlabel(ph1,'String','Time (mins)');
    end
    set(ax(1),'XTick',ts(1:find(ts==60)-1:end)+1);
    set(ax(1),'XTickLabel',ts(1:find(ts==60*60)-1:end)/(60*60));
else
    ts = ts/60;
    if options.MatlabPost2014
        xlabel(ax(1),'Time (hours)');
    else
        xlabel(ph1,'String','Time (hours)');
    end
    set(ax(1),'XTick',1:find(ts==1)-1:length(ts));
    set(ax(1),'XTickLabel',ts(1:find(ts==1)-1:end));
end
box(ax(1),'off');

% EEG
ax(2) = subplot(nPlots,1,2);
ph3 = plot(ax(2),DataStruct.Channel(options.EEGChannel).Data);
ts = 0:DataStruct.Channel(options.EEGChannel).Hz:length(DataStruct.Channel(options.EEGChannel).Data) / DataStruct.Channel(options.EEGChannel).Hz / 60;
set(ax(2),'XLim',[0 length(DataStruct.Channel(options.EEGChannel).Data)]);
if ts(end) <= 60
    if options.MatlabPost2014
        xlabel(ax(2),'Time (mins)');
    else
         xlabel(ph3,'String','Time (mins)');
    end
    set(ax(2),'XTick',ts*60*DataStruct.Channel(options.EEGChannel).Hz)
    set(ax(2),'XTickLabel',ts);
else
    ts = ts/60;
    if options.MatlabPost2014
        xlabel(ax(2),'Time (hours)');
    else
        xlabel(ph3,'String','Time (hours)');
    end
    set(ax(2),'XTick',ts*60*60*DataStruct.Channel(options.EEGChannel).Hz)
    set(ax(2),'XTickLabel',ts);
end
if options.MatlabPost2014
    ylabel(ax(2),['EEG (',DataStruct.Channel(options.EEGChannel).Units,')']);
else
     ylabel(ph3,'String',['EEG (',DataStruct.Channel(options.EEGChannel).Units,')']);
end
box(ax(2),'off');

%EMG
if ~isempty(options.EMGChannel)
ax(3) = subplot(nPlots,1,3);
ph4 = plot(ax(3),DataStruct.Channel(options.EMGChannel).Data);
ts = 0:DataStruct.Channel(options.EMGChannel).Hz:length(DataStruct.Channel(options.EMGChannel).Data) / DataStruct.Channel(options.EMGChannel).Hz / 60;
set(ax(3),'XLim',[0 length(DataStruct.Channel(options.EMGChannel).Data)]);
if ts(end) <= 60
    if options.MatlabPost2014
        xlabel(ax(3),'Time (mins)');
    else
        xlabel(ph4,'String','Time (mins)');
    end
    set(ax(3),'XTick',ts*60*DataStruct.Channel(options.EMGChannel).Hz)
    set(ax(3),'XTickLabel',ts);
else
    ts = ts/60;
    if options.MatlabPost2014
        xlabel(ax(3),'Time (hours)');
    else
        xlabel(ph4,'String','Time (hours)');
    end
    set(ax(3),'XTick',ts*60*60*DataStruct.Channel(options.EMGChannel).Hz)
    set(ax(3),'XTickLabel',ts);
end
if options.MatlabPost2014
    ylabel(ax(3),['EMG (',DataStruct.Channel(options.EMGChannel).Units,')']);
else
     ylabel(ph4,'String',['EMG (',DataStruct.Channel(options.EMGChannel).Units,')']);
end
box(ax(3),'off');
end


%Activity
if ~isempty(options.ActivityChannel)
ax(4) = subplot(nPlots,1,nPlots);
ph5 = plot(ax(4),DataStruct.Channel(options.EMGChannel).Data);
ts = 0:DataStruct.Channel(options.EMGChannel).Hz:length(DataStruct.Channel(options.EMGChannel).Data) / DataStruct.Channel(options.EMGChannel).Hz / 60;
set(ax(4),'XLim',[0 length(DataStruct.Channel(options.EMGChannel).Data)]); %DMD was ax(3)
if ts(end) <= 60
    if options.MatlabPost2014
        xlabel(ax(4),'Time (mins)');
    else
        xlabel(ph5,'String','Time (mins)');
    end
    set(ax(4),'XTick',ts*60*DataStruct.Channel(options.EMGChannel).Hz)
    set(ax(4),'XTickLabel',ts);
else
    ts = ts/60;
    if options.MatlabPost2014
        xlabel(ax(4),'Time (hours)');
    else
        xlabel(ph5,'String','Time (hours)');
    end
    set(ax(4),'XTick',ts*60*60*DataStruct.Channel(options.EMGChannel).Hz)
    set(ax(4),'XTickLabel',ts);
end
if options.MatlabPost2014
    ylabel(ax(4),['Activity (',DataStruct.Channel(options.EMGChannel).Units,')']);
else
     ylabel(ph5,'String',['Activity (',DataStruct.Channel(options.EMGChannel).Units,')']);
end
box(ax(4),'off');
end

if ~isempty(options.logfile)
    HypnoSaveFile = fullfile(fileparts(options.logfile),'Hypnogram-Fig.png');
    % print(h_fig,'-dpng', fullfile(fileparts(options.logfile),['Hypnogram-Fig_',num2str(now),'.png']) );
else
    HypnoSaveFile = fullfile(cd,'Hypnogram-Fig.png');
    %print(h_fig,'-dpng', fullfile(cd,['Hypnogram-Fig_',num2str(now),'.png']) );
end
print(h_fig,'-dpng', HypnoSaveFile );
close(h_fig);

%Now add the figure in to the doc
hypnogram_h = insertPicture( doc_obj, HypnoSaveFile );



doc_obj = save(doc_obj,true,fullfile(OutputDir,[SleepReportFile,'_Report.doc']));
doc_obj = close(doc_obj);
WordDocOpen = false;
end

%% Write values to Spreadsheet
% NOTES: Writes standardized filename with a total of 6 fields seperated by
% underscore '_'.
% "NSB_{Filetype}_{SubjectID}_{ChannelName}_{ChannelNumber}_{format}.{ext}"

%generate headers
SheetHeader = ['Total time in sleep cycle period (sec),Sleep Latency (sec),PS Latency (sec),Latency to Wake after Sleep onset (sec),',...
    'Total Sleep Time (sec),PS Sleep Time (sec),nREM Sleep Time (sec),SWS1 Seep Time (sec),SWS2 Sleep Time (sec),',...
    'Total Waking Time in sleep cycle period (sec),Quiet Waking Time (sec),Active Waking Time (sec)'];
SheetHeader =regexp(SheetHeader,',','split');
%SheetHeader = regexp(SheetHeader,'[\w\s\.]*','match');

%in seconds
CellTable = [etime(options.handles.StudyDesign{options.curFile}.SleepCycleEnd,options.handles.StudyDesign{options.curFile}.SleepCycleStart),...
    Sleep_Latency_IDX/DataStruct.Channel(options.HypnogramChannel).Hz,...
    PS_Latency_IDX/DataStruct.Channel(options.HypnogramChannel).Hz,...
    FirstWake_Latency_IDX/DataStruct.Channel(options.HypnogramChannel).Hz,...
    sum(TotalSleepTime_IDX)/DataStruct.Channel(options.HypnogramChannel).Hz,...
    sum(PS_SleepTime_IDX)/DataStruct.Channel(options.HypnogramChannel).Hz,...
    sum(nPS_SleepTime_IDX)/DataStruct.Channel(options.HypnogramChannel).Hz,...
    sum(SWS1_SleepTime_IDX)/DataStruct.Channel(options.HypnogramChannel).Hz,...
    sum(SWS2_SleepTime_IDX)/DataStruct.Channel(options.HypnogramChannel).Hz,...
    sum(TotalWake_IDX)/DataStruct.Channel(options.HypnogramChannel).Hz,...
    sum(QW_SleepTime_IDX)/DataStruct.Channel(options.HypnogramChannel).Hz,...
    sum(AW_SleepTime_IDX)/DataStruct.Channel(options.HypnogramChannel).Hz];

[status,msg] = NSB_WriteGenericCSV(SheetHeader, fullfile(OutputDir,[CSVOutputFile,'_SleepStatistics.csv']),false);
[status,msg] = NSB_WriteGenericCSV(CellTable, fullfile(OutputDir,[CSVOutputFile,'_SleepStatistics.csv']),true);
if status
    filenames.filename = fullfile(OutputDir,[CSVOutputFile,'_SleepStatistics.csv']);
end


catch ME
    %save a partial report
    if WordDocOpen
    doc_obj = save(doc_obj,true,fullfile(OutputDir,[SleepReportFile,'_Report.doc']));
    doc_obj = close(doc_obj);
    end
    
end



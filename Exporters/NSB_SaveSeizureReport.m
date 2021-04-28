function [status, filenames] = NSB_SaveSeizureReport(DataStruct, options)
%[status, filenames] = NSB_SaveSeizureReport(DataStruct, options)
% Function used to Generate a MSword document and .csv containing Seizure
% Report Values
%
% Inputs:
%   DataStruct                   - (struct) NSB DataStruct
%   options                      - (struct)
%       .handles                    (struct) NSB Handles Structure
%       .EEGChannel                 (double) Channel Number of EEG used to SleepScore
%       .EMGChannel                 (double) Channel Number of EMG used to SleepScore
%       .ActivityChannel            (double) Channel Number of Activity Channel used to SleepScore 
%       .EEGChannel             (double) Channel Number of generated Hypnogram Channel
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


status = false;
[OutputDir,trash1,trash2] = fileparts(DataStruct.Filename);
OutputDir = fullfile(OutputDir,'NSB_Output');
CSVOutputFile = ['NSB_SeizureAnalysis_',datestr(DataStruct.StartDate,29),'_',DataStruct.SubjectID,'_',DataStruct.Channel(options.EEGChannel).Name,'_',num2str(options.EEGChannel)];
ReportFile = ['NSB_SeizureReport_',datestr(DataStruct.StartDate,29),'_',DataStruct.SubjectID,'_',DataStruct.Channel(options.EEGChannel).Name,'_',num2str(options.EEGChannel)];
%make sure output file has no special characters.
CSVOutputFile = regexprep(CSVOutputFile, '[<>:"?*\s]', '-', 'preservecase');
ReportFile = regexprep(ReportFile, '[<>:"?*\s]', '-', 'preservecase');

existXLSax = true;
if exist(OutputDir,'dir') == 0
    mkdir(OutputDir)
end
filenames.type = 'Seizure';
disp(['NSB_SaveSeizureReport - Saving Seizure Report...']);

%% Calculate Metrics






%% Open Word Document
infostr = ['Information: NSB_SaveSeizureReport >> Trying to connect to MSWord ...'];
if ~isempty(options.logfile)
    NSBlog(options.logfile,infostr);
else
    errordlg(infostr,'NSB_SaveSeizureReport');
end
disp(infostr);

try
    WordDocOpen = true;
    doc_obj = Word(options.TemplateFile,true,true);
    goTo( doc_obj, 'wdGoToLine','wdGoToLast' ); %Go to the end.
catch ME
    WordDocOpen = false;
    errorstr = ['ERROR: NSB_SaveSeizureReport >> Failed to open Word ActiveX object. ',ME.message];
    NSBlog(options.logfile,errorstr);
    disp(errorstr);
end

try
    if WordDocOpen
        infostr = ['Information: NSB_SaveSeizureReport >> Successfully opened ',options.TemplateFile];
        if ~isempty(options.logfile)
            NSBlog(options.logfile,infostr);
        else
            errordlg(infostr,'NSB_SaveSeizureReport');
        end
        % Subject Information
        txtstr = 'Subject Information';
        addText( doc_obj,txtstr, 'Normal', 1 );
        insertLine( doc_obj, 0);
        
        txtstr = [char(9),'Subject ID: ',DataStruct.SubjectID];
        addText( doc_obj,txtstr, 'Normal', 1 );
        
        txtstr = [char(9),'Study Date: ',datestr(DataStruct.StartDate,1),' starting at ',datestr(DataStruct.StartDate,14)];
        addText( doc_obj,txtstr, 'Normal', 1 );
        
        %if ~iscell(options.handles.StudyDesign{options.curFile,2})
        if iscell(options.handles.StudyDesign{options.curFile,2})
            if ~ischar(options.handles.StudyDesign{options.curFile,2})
                txtstr = [char(9),'Group: ',options.handles.StudyDesign{options.curFile,2}.group];
                addText( doc_obj,txtstr, 'Normal', 1 );
                txtstr = [char(9),'Project: ',options.handles.StudyDesign{options.curFile,2}.project];
                addText( doc_obj,txtstr, 'Normal', 1 );

                StudyID = options.handles.StudyDesign{options.curFile,2}.studyID;
                txtstr = [char(9),'Study ID: ',StudyID];
                addText( doc_obj,txtstr, 'Normal', 1 );
                txtstr = [char(9),'Dose: ',options.handles.StudyDesign{options.curFile,2}.dose];
                addText( doc_obj,txtstr, 'Normal', 1 );
            else
                txtstr = [char(9),'Group: Not Available'];
                addText( doc_obj,txtstr, 'Normal', 1 );
                txtstr = [char(9),'Project: Not Available'];
                addText( doc_obj,txtstr, 'Normal', 1 );

                StudyID = 'Not Available';
                txtstr = [char(9),'Study ID: ',StudyID];
                addText( doc_obj,txtstr, 'Normal', 1 );
                txtstr = [char(9),'Dose: Not Available'];
                addText( doc_obj,txtstr, 'Normal', 1 );    
            end
        else
            txtstr = [char(9),'Group: Not Available'];
            addText( doc_obj,txtstr, 'Normal', 1 );
            txtstr = [char(9),'Project: Not Available'];
            addText( doc_obj,txtstr, 'Normal', 1 );
            
            StudyID = 'Not Available';
            txtstr = [char(9),'Study ID: ',StudyID];
            addText( doc_obj,txtstr, 'Normal', 1 );
            txtstr = [char(9),'Dose: Not Available'];
            addText( doc_obj,txtstr, 'Normal', 1 );
        end
        
        % Seizure Statistics
        addText( doc_obj,'', 'Normal', 1 );
        txtstr = 'Seizure Statistics (for the entire file)';
        addText( doc_obj,txtstr, 'Normal', 1 );
        insertLine( doc_obj, 0);
        
        txtstr = [char(9),'Total Number of Spike Trains:',char(9),char(9),num2str(length(DataStruct.Channel(options.EEGChannel).SeizureStruct.Spikes))];
        addText( doc_obj,txtstr, 'Normal', 1 );
        
        txtstr = [char(9),'Total Spike Train Duration (min):',char(9),char(9),num2str(sum( DataStruct.Channel(options.EEGChannel).SeizureStruct.intEnds - DataStruct.Channel(options.EEGChannel).SeizureStruct.intStarts) /60)];
        addText( doc_obj,txtstr, 'Normal', 1 );
        
        txtstr = [char(9),'Percent of Recording:',char(9),char(9),char(9),char(9),'N/A'];
        addText( doc_obj,txtstr, 'Normal', 1 );
        
        txtstr = [char(9),'Mean Spike Train Duration (sec):',char(9),char(9),num2str(mean( DataStruct.Channel(options.EEGChannel).SeizureStruct.intEnds - DataStruct.Channel(options.EEGChannel).SeizureStruct.intStarts))];
        addText( doc_obj,txtstr, 'Normal', 1 );
        
        txtstr = [char(9),'Longest Spike Train Duration (sec):',char(9),char(9),num2str(max( DataStruct.Channel(options.EEGChannel).SeizureStruct.intEnds - DataStruct.Channel(options.EEGChannel).SeizureStruct.intStarts))];
        addText( doc_obj,txtstr, 'Normal', 1 );
        
        txtstr = [char(9),'Shortest Spike Train Duration (sec):',char(9),char(9),num2str(min( DataStruct.Channel(options.EEGChannel).SeizureStruct.intEnds - DataStruct.Channel(options.EEGChannel).SeizureStruct.intStarts))];
        addText( doc_obj,txtstr, 'Normal', 1 );
        
        txtstr = [char(9),'Mean Number of Spikes/Train:',char(9),char(9),num2str(mean(DataStruct.Channel(options.EEGChannel).SeizureStruct.Spikes))];
        addText( doc_obj,txtstr, 'Normal', 1 ); 
        
        %Page Break
        pageBreak(doc_obj);
        
        %Header
        txtstr = ['Subject ID: ',DataStruct.SubjectID,char(9),'Study ID: ',StudyID,char(9),char(9),'Study Date: ',datestr(DataStruct.StartDate,1),' starting at ',datestr(DataStruct.StartDate,14)];
        addText( doc_obj,txtstr, 'Normal', 1 );
        insertLine( doc_obj, 0);
        
        % Analysis Parameters
        addText( doc_obj,'', 'Normal', 1 );
        txtstr = 'Analysis Parameters';
        addText( doc_obj,txtstr, 'Normal', 1 );
        insertLine( doc_obj, 0);
        
        txtstr = [char(9),'Cerridwen: ', options.handles.parameters.PreClinicalFramework.Name,' Ver. ',options.handles.parameters.PreClinicalFramework.Version];
        addText( doc_obj,txtstr, 'Normal', 1 );
        
        txtstr = [char(9),'Analysis Date: ', datestr(now, 'mmmm dd, yyyy')];
        addText( doc_obj,txtstr, 'Normal', 1 );
        
        txtstr = [char(9),'Analysis Parameter File: ', get(options.handles.AnalysisParameters_txt,'String')];
        addText( doc_obj,txtstr, 'Normal', 1 );
        
        txtstr = [char(9),'Seizure Scoring Type: NeuroScore',char(174),' Emulation'];
        addText( doc_obj,txtstr, 'Normal', 1 );
        
        %Seizure Analysis Parameters
        addText( doc_obj,'', 'Normal', 1 );
        txtstr = ['Signal Filtering'];
        addText( doc_obj,txtstr, 'Normal', 1 );
        insertLine( doc_obj, 0);
        
        txtstr = [char(9),'Filter Type: ',char(9),char(9),char(9),char(9),char(9),'FIR'];
        addText( doc_obj,txtstr, 'Normal', 1 );
        txtstr = [char(9),'Stop Band 1 (Hz): ',char(9),char(9),char(9),char(9),num2str(options.handles.parameters.PreClinicalFramework.SeizureAnalysis.filter.Fstop1)];
        addText( doc_obj,txtstr, 'Normal', 1 );
        txtstr = [char(9),'Pass Band 1 (Hz): ',char(9),char(9),char(9),char(9),num2str(options.handles.parameters.PreClinicalFramework.SeizureAnalysis.filter.Fpass1)];
        addText( doc_obj,txtstr, 'Normal', 1 );
        txtstr = [char(9),'Pass Band 2 (Hz): ',char(9),char(9),char(9),char(9),num2str(options.handles.parameters.PreClinicalFramework.SeizureAnalysis.filter.Fpass2)];
        addText( doc_obj,txtstr, 'Normal', 1 );
        txtstr = [char(9),'Stop Band 2 (Hz): ',char(9),char(9),char(9),char(9),num2str(options.handles.parameters.PreClinicalFramework.SeizureAnalysis.filter.Fstop2)];
        addText( doc_obj,txtstr, 'Normal', 1 );
        txtstr = [char(9),'Stop Band Attenuation: ',char(9),char(9),char(9),num2str(options.handles.parameters.PreClinicalFramework.SeizureAnalysis.filter.Astop1)];
        addText( doc_obj,txtstr, 'Normal', 1 );
        
        %Seizure Detector Settings Parameters
        addText( doc_obj,'', 'Normal', 1 );
        txtstr = ['Detector Settings'];
        addText( doc_obj,txtstr, 'Normal', 1 );
        insertLine( doc_obj, 0);
        
        txtstr = [char(9),'RMS Multiplier: ',char(9),char(9),char(9),char(9),num2str(options.handles.parameters.PreClinicalFramework.SeizureAnalysis.RMSMultiplier)];
        addText( doc_obj,txtstr, 'Normal', 1 );
        txtstr = [char(9),'Min. Spike Frequency (Hz): ',char(9),char(9),char(9),num2str(options.handles.parameters.PreClinicalFramework.SeizureAnalysis.detector.Hzlow)];
        addText( doc_obj,txtstr, 'Normal', 1 );
        txtstr = [char(9),'Max. Spike Frequency (Hz): ',char(9),char(9),char(9),num2str(options.handles.parameters.PreClinicalFramework.SeizureAnalysis.detector.Hzhigh)];
        addText( doc_obj,txtstr, 'Normal', 1 );
        txtstr = [char(9),'Spike Train Min. Frequency (Hz): ',char(9),char(9),num2str(1/ options.handles.parameters.PreClinicalFramework.SeizureAnalysis.detector.maxSpikeInt)];
        addText( doc_obj,txtstr, 'Normal', 1 );
        txtstr = [char(9),'Spike Train Max. Frequency (Hz): ',char(9),char(9),num2str(1/ options.handles.parameters.PreClinicalFramework.SeizureAnalysis.detector.minSpikeInt)];
        addText( doc_obj,txtstr, 'Normal', 1 );
        txtstr = [char(9),'Spike Train Min. Duration (sec): ',char(9),char(9),num2str(options.handles.parameters.PreClinicalFramework.SeizureAnalysis.detector.minTrainDur)];
        addText( doc_obj,txtstr, 'Normal', 1 );
        txtstr = [char(9),'Min. Spikes in a Train ( n= ): ',char(9),char(9),char(9),num2str(options.handles.parameters.PreClinicalFramework.SeizureAnalysis.detector.minSpikes)];
        addText( doc_obj,txtstr, 'Normal', 1 );
        txtstr = [char(9),'Combine Trains with Min. Interval (sec): ',char(9),num2str(options.handles.parameters.PreClinicalFramework.SeizureAnalysis.detector.minTrainGap)];
        addText( doc_obj,txtstr, 'Normal', 1 );
        
        %Page Break
        pageBreak(doc_obj);
        
        %Header
        txtstr = ['Subject ID: ',DataStruct.SubjectID,char(9),'Study ID: ',StudyID,char(9),char(9),'Study Date: ',datestr(DataStruct.StartDate,1),' starting at ',datestr(DataStruct.StartDate,14)];
        addText( doc_obj,txtstr, 'Normal', 1 );
        insertLine( doc_obj, 0);
        insertPicture( doc_obj, DataStruct.Channel(options.EEGChannel).SeizureStruct.plot, false );
        addText( doc_obj,'', 'Normal', 1 );
        txtstr = ['Seizure activity plot.'];
        addText( doc_obj,txtstr, 'Normal', 1 );
        
        
        
        
%         
%         % FYI: options.handles.StudyDesign{options.curFile}.SleepCycleStart is a
%         % date vec so generate these as datevecs
%         %SleepCycleStart_datenum = datevec(DataStruct.Channel(options.EEGChannel).ts(1));
%         if isfield(options.handles.StudyDesign{options.curFile},SleepCycleStart)
%             SleepCycleStart_datenum = datenum([StartDateVec(1:3), options.handles.StudyDesign{options.curFile}.SleepCycleStart(4:6)]); %Use start date and replace time with SleepCycleStart
%             SleepCycleEnd_datenum = StartDateVec;
%             if datenum(options.handles.StudyDesign{options.curFile}.SleepCycleStart) < datenum(options.handles.StudyDesign{options.curFile}.SleepCycleEnd) %Sleep cycle ends same day (rats)
%                 SleepCycleEnd_datenum = datenum([SleepCycleEnd_datenum(1:3), options.handles.StudyDesign{options.curFile}.SleepCycleEnd(4:6)]); %Use start date and replace time with SleepCycleStart
%             else
%                 SleepCycleEnd_datenum(3) = SleepCycleEnd_datenum(3)+1; %add a day
%                 SleepCycleEnd_datenum = datenum([SleepCycleEnd_datenum(1:3), options.handles.StudyDesign{options.curFile}.SleepCycleEnd(4:6)]); %Use start date and replace time with SleepCycleEnd
%             end
%         else
%             SleepCycleStart_datenum = StartDateVec;
%             SleepCycleEnd_datenum = StartDateVec;
%             SleepCycleEnd_datenum(3) = SleepCycleEnd_datenum(3)+1; %add a day
%         end
%         
%         if isfield(options.handles.StudyDesign{options.curFile},'SleepCycleStart')
%             if all(isnan(options.handles.StudyDesign{options.curFile}.SleepCycleStart))
%                 %err
%                 SleepCycleStart_IDX = 1;
%                 txtstr = [char(9),'Sleep Cycle Start Time: Not Specified. Using the begining of the File.'];
%             else
%                 SleepCycleStart_IDX = find(DataStruct.Channel(options.EEGChannel).ts >= SleepCycleStart_datenum,1,'first');
%                 txtstr = [char(9),'Sleep Cycle Start Time: ', datestr(datenum(options.handles.StudyDesign{options.curFile}.SleepCycleStart))];
%             end
%         else
%             %err
%             SleepCycleStart_IDX = 1;
%             txtstr = [char(9),'Sleep Cycle Start Time: Not Specified. Using the begining of the File'];
%         end
%         addText( doc_obj,txtstr, 'Normal', 1 );
%         
%         if isfield(options.handles.StudyDesign{options.curFile},'SleepCycleEnd')
%             if all(isnan(options.handles.StudyDesign{options.curFile}.SleepCycleEnd))
%                 %Not an error, just not specified
%                 SleepCycleEnd_IDX = length(DataStruct.Channel(options.EEGChannel).Data);
%                 txtstr = [char(9),'Sleep Cycle End Time: Not Specified. Using the end of the File'];
%             else
%                 SleepCycleEnd_IDX = find(DataStruct.Channel(options.EEGChannel).ts >= SleepCycleEnd_datenum,1,'first');
%                 txtstr = [char(9),'Sleep Cycle End Time: ', datestr(datenum(options.handles.StudyDesign{options.curFile}.SleepCycleEnd))];
%             end
%         else
%             %Not an error, just not specified
%             SleepCycleEnd_IDX = length(DataStruct.Channel(options.EEGChannel).Data);
%             txtstr = [char(9),'Sleep Cycle End Time: Not Specified. Using the end of the File'];
%         end
%         addText( doc_obj,txtstr, 'Normal', 2 );
        

        
doc_obj = save(doc_obj,true,fullfile(OutputDir,[ReportFile,'_Report.doc']));
doc_obj = close(doc_obj);
WordDocOpen = false;
    end

    catch ME
    %save a partial report
    if WordDocOpen
    doc_obj = save(doc_obj,true,fullfile(OutputDir,[ReportFile,'_Report.doc']));
    doc_obj = close(doc_obj);
    end
    
end
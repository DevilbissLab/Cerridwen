function status = NSB_GenerateStatTable(StudyDesignPath,BaselineMeanTimeStart,BaselineMeanTimeEnd, options)
%status = NSB_GenerateStatTable() - Combine NSB output into a stats table for groupwise analysis
%
% Inputs:
%   StudyDesignPath         - (string) Path+FileName of StudyDesign file
%   BaselineMeanTimeStart   - (double or empty (default - [] use all data)) Seconds: Time before Dosing to start baseline average
%   BaselineMeanTimeEnd     - (double or empty (default - [] use all data)) Seconds: Time before Dosing to end baseline average
%                               Example - BaselineMeanTimeStart = -20 * 60; BaselineMeanTimeEnd = -120 * 60;
%   options           - (struct) of options
%                           options.logfile
%                           options.progress
%                           options.doMeanBaseline (Logical Default:true) special option
%                           to do/not do baseline averageing.
%                           options.doRMtable (Logical Default:false) special option
%                           options.MovAve.do (Logical Default:false) note: endpoints are handled as a smooth of the next lowest avalable odd integer) 
%                           options.MovAve.window
%
%
% Outputs:
%   status              - (logical) return value
%       File saved in StudyDesignPath.
%
%
% Dependencies:
% NSBlog, xlsread
%
% Important Notes: %This function assumes binning is the same between data types
%
% Written By David M. Devilbiss
% NexStep Biomarkers, LLC. (info@nexstepbiomarkers.com)
% March 01 2013, Version 1.0
% June 11, 2013, v. 1.1 Added ability to not do baseline averaging
% July 23, 2013  v. 2.0 General reWrite. Handles new naming convention with dates to 
%   allow all files in one folder (i.e. edf pile). Now handles multiple
%   channels gracefully and even multiple files with same channle (i.e.
%   multiple recordings in a day)
% August 8 2013, v2.1 rewrite to write csv on th efly insted of trying to hold all of it in memory
% August 16 2013
% Jan 6 2017 Changed subject strfind to strcmp (to handle subject > 10)
% Mar 2 2017 Added respect for channel designaltions in Study design
%
%To Do deal with multiple channels!
%       handle putative .xml format of design
%       Extract Channel name
%   check to see if you can enter empty values for tiem start and time end
%   also add use z-scores instead of simple ratio
% - >> does not work if selected from menu
% - >> should understand Licences as well.
% - >> three point average - done Apr1 2014


status = false;
warning('off', 'MATLAB:datevec:Inputs');
switch nargin
    case 1
        BaselineMeanTimeStart = [];
        BaselineMeanTimeEnd = [];
        options.progress = false;
        options.logfile = '';
        options.doMeanBaseline = true;
        options.doRMtable = false;
        options.MovAve.do = false; options.MovAve.window = [];
        options.fnHasDateID = true;
        if exist(StudyDesignPath,'file') ~= 2
            errorstr = ['ERROR: NSB_GenerateStatTable >> Study Design file does not exist: ',StudyDesignPath];
            if ~isempty(options.logfile)
                status = NSBlog(options.logfile,errorstr);
            else
                errordlg(errorstr,'NSB_GenerateStatTable','replace');
            end
            return;
        end
    case 2
        BaselineMeanTimeEnd = [];
        options.progress = false;
        options.logfile = '';
        options.doMeanBaseline = true;
        options.doRMtable = false;
        options.MovAve.do = false; options.MovAve.window = [];
        options.fnHasDateID = true;
        if exist(StudyDesignPath,'file') ~= 2
            errorstr = ['ERROR: NSB_GenerateStatTable >> Study Design file does not exist: ',StudyDesignPath];
            if ~isempty(options.logfile)
                status = NSBlog(options.logfile,errorstr);
            else
                errordlg(errorstr,'NSB_GenerateStatTable','replace');
            end
            return;
        end
        
        if ~isnumeric(BaselineMeanTimeStart) && ischar(BaselineMeanTimeStart)
            BaselineMeanTimeStart = str2double(BaselineMeanTimeStart);
            errorstr = ['Warning: NSB_GenerateStatTable >> BaselineMeanTimeStart ischar and will be converted to numeric.'];
            if ~isempty(options.logfile)
                status = NSBlog(options.logfile,errorstr);
            else
                errordlg(errorstr,'NSB_GenerateStatTable','replace');
            end
        elseif ~isnumeric(BaselineMeanTimeStart)
            errorstr = ['ERROR: NSB_GenerateStatTable >> BaselineMeanTimeStart is not a string or numeric'];
            if ~isempty(options.logfile)
                status = NSBlog(options.logfile,errorstr);
            else
                errordlg(errorstr,'NSB_GenerateStatTable','replace');
            end
            return;
        end
        
    case 3
        options.progress = false;
        options.logfile = '';
        options.doMeanBaseline = true;
        options.doRMtable = false;
        options.MovAve.do = false; options.MovAve.window = [];
        options.fnHasDateID = true;
        if exist(StudyDesignPath,'file') ~= 2
            errorstr = ['ERROR: NSB_GenerateStatTable >> Study Design file does not exist: ',StudyDesignPath];
            if ~isempty(options.logfile)
                status = NSBlog(options.logfile,errorstr);
            else
                errordlg(errorstr,'NSB_GenerateStatTable','replace');
            end
            return;
        end
        
        if ~isnumeric(BaselineMeanTimeStart) && ischar(BaselineMeanTimeStart)
            BaselineMeanTimeStart = str2double(BaselineMeanTimeStart);
            errorstr = ['Warning: NSB_GenerateStatTable >> BaselineMeanTimeStart ischar and will be converted to numeric.'];
            if ~isempty(options.logfile)
                status = NSBlog(options.logfile,errorstr);
            else
                errordlg(errorstr,'NSB_GenerateStatTable','replace');
            end
        elseif ~isnumeric(BaselineMeanTimeStart)
            errorstr = ['ERROR: NSB_GenerateStatTable >> BaselineMeanTimeStart is not a string or numeric'];
            if ~isempty(options.logfile)
                status = NSBlog(options.logfile,errorstr);
            else
                errordlg(errorstr,'NSB_GenerateStatTable','replace');
            end
            return;
        end
        
        if ~isnumeric(BaselineMeanTimeEnd) && ischar(BaselineMeanTimeEnd)
            BaselineMeanTimeEnd = str2double(BaselineMeanTimeEnd);
            errorstr = ['Warning: NSB_GenerateStatTable >> BaselineMeanTimeEnd ischar and will be converted to numeric.'];
            if ~isempty(options.logfile)
                status = NSBlog(options.logfile,errorstr);
            else
                errordlg(errorstr,'NSB_GenerateStatTable','replace');
            end
        elseif ~isnumeric(BaselineMeanTimeEnd)
            errorstr = ['ERROR: NSB_GenerateStatTable >> BaselineMeanTimeEnd is not a string or numeric'];
            if ~isempty(options.logfile)
                status = NSBlog(options.logfile,errorstr);
            else
                errordlg(errorstr,'NSB_GenerateStatTable','replace');
            end
            return;
        end
    case 4
        if exist(StudyDesignPath,'file') ~= 2
            errorstr = ['ERROR: NSB_GenerateStatTable >> Study Design file does not exist: ',StudyDesignPath];
            if ~isempty(options.logfile)
                status = NSBlog(options.logfile,errorstr);
            else
                errordlg(errorstr,'NSB_GenerateStatTable','replace');
            end
            return;
        end
        
        if ~isnumeric(BaselineMeanTimeStart) && ischar(BaselineMeanTimeStart)
            BaselineMeanTimeStart = str2double(BaselineMeanTimeStart);
            errorstr = ['Warning: NSB_GenerateStatTable >> BaselineMeanTimeStart ischar and will be converted to numeric.'];
            if ~isempty(options.logfile)
                status = NSBlog(options.logfile,errorstr);
            else
                errordlg(errorstr,'NSB_GenerateStatTable','replace');
            end
        elseif ~isnumeric(BaselineMeanTimeStart)
            errorstr = ['ERROR: NSB_GenerateStatTable >> BaselineMeanTimeStart is not a string or numeric'];
            if ~isempty(options.logfile)
                status = NSBlog(options.logfile,errorstr);
            else
                errordlg(errorstr,'NSB_GenerateStatTable','replace');
            end
            return;
        end
        
        if ~isnumeric(BaselineMeanTimeEnd) && ischar(BaselineMeanTimeEnd)
            BaselineMeanTimeEnd = str2double(BaselineMeanTimeEnd);
            errorstr = ['Warning: NSB_GenerateStatTable >> BaselineMeanTimeEnd ischar and will be converted to numeric.'];
            if ~isempty(options.logfile)
                status = NSBlog(options.logfile,errorstr);
            else
                errordlg(errorstr,'NSB_GenerateStatTable','replace');
            end
        elseif ~isnumeric(BaselineMeanTimeEnd)
            errorstr = ['ERROR: NSB_GenerateStatTable >> BaselineMeanTimeEnd is not a string or numeric'];
            if ~isempty(options.logfile)
                status = NSBlog(options.logfile,errorstr);
            else
                errordlg(errorstr,'NSB_GenerateStatTable','replace');
            end
            return;
        end
        
        if ~isfield(options,'progress')
            options.progress = false;
        end
        if ~isfield(options,'logfile')
            options.logfile = '';
        end
        if ~isfield(options,'doMeanBaseline')
            options.doMeanBaseline = true;
        end
        if ~isfield(options,'doRMtable')
            options.doRMtable = false;
        end
        if ~isfield(options,'MovAve')
            options.MovAve.do = false; options.MovAve.window = [];
        else
            if ~isfield(options.MovAve,'do')
            options.MovAve.do = false; options.MovAve.window = [];
            end
        end
        if ~isfield(options,'fnHasDateID')
            options.fnHasDateID = true;
        end
        
    otherwise
        [fn, path] = uigetfile({'*.xls','Microsoft Excel (*.xls)';'*.*',  'All Files (*.*)'},'Choose a NSB Specified Study file');
        StudyDesignPath = fullfile(path,fn);
        BaselineMeanTimeStart = [];
        BaselineMeanTimeEnd = [];
        options.progress = true;
        options.logfile = '';
        options.doMeanBaseline = true;
        options.doRMtable = false;
        options.MovAve.do = false; options.MovAve.window = [];
        
end

% Generate output path for saving file
outputPath = fileparts(StudyDesignPath);

%
        errorstr = ['Information: NSB_GenerateStatTable >> Processing study design file: ',StudyDesignPath];
        if ~isempty(options.logfile)
            status = NSBlog(options.logfile,errorstr);
            disp(errorstr);
        else
            disp(errorstr);
        end
        if options.doMeanBaseline
        errorstr = ['Information: NSB_GenerateStatTable >> BaselineMeanTimeStart= ',num2str(BaselineMeanTimeStart),' BaselineMeanTimeEnd= ',num2str(BaselineMeanTimeEnd)];
        else
        errorstr = ['Information: NSB_GenerateStatTable >> No Baseline Normalization Requested.'];
        end
        if ~isempty(options.logfile)
            status = NSBlog(options.logfile,errorstr);
            disp(errorstr);
        else
            disp(errorstr);
        end
        errorstr = ['Information: NSB_GenerateStatTable >> Output written to : ',outputPath];
        if ~isempty(options.logfile)
            status = NSBlog(options.logfile,errorstr);
            disp(errorstr);
        else
            disp(errorstr);
        end
        
        %Write CSV Header(s)
SheetHeader = ['Date,Subject,Channel Name,Channel Num,Manipulation,Epoch Num,Valid Epoch,Sleep Scoring,Band 1,Band 2,Band 3,Band 4,Band 5,Ratio 1,Ratio 2,Ratio 3,Ratio 4,Ratio 5'];
SheetHeader = regexp(SheetHeader,'[\w\s\.()]*','match');
try
[status,msg] = NSB_WriteGenericCSV(SheetHeader, fullfile(outputPath, 'NSB_Cerridwen-StatisticalAnalysisTable.csv'),false);
catch
    infostr = {'Warning: NSB_GenerateStatTable >> Cannot write NSB_Cerridwen-StatisticalAnalysisTable.';'Check that the file is not currently open and then press OK'}; 
    uiwait(msgbox(infostr,'NSB_GenerateStatTable','warn','modal'));
    [status,msg] = NSB_WriteGenericCSV(SheetHeader, fullfile(outputPath, 'NSB_Cerridwen-StatisticalAnalysisTable.csv'),false);
end

SleepStatsHeader = ['Date,Subject,Channel Name,Channel Num,Manipulation,Total time in sleep cycle period (sec),Sleep Latency (sec),PS Latency (sec),Latency to Wake after Sleep onset (sec),Total Sleep Time (sec),PS Sleep Time (sec),nREM Sleep Time (sec),SWS1 Seep Time (sec),SWS2 Sleep Time (sec),Total Waking Time in sleep cycle period (sec),Quiet Waking Time (sec),Active Waking Time (sec)'];
SleepStatsHeader = regexp(SleepStatsHeader,'[\w\s\.]*','match');
try
[status,msg] = NSB_WriteGenericCSV(SleepStatsHeader, fullfile(outputPath, 'NSB_Cerridwen-SleepStatisticalAnalysisTable.csv'),false);
catch
    infostr = {'Warning: NSB_GenerateStatTable >> Cannot write NSB_Cerridwen-SleepStatisticalAnalysisTable.';'Check that the file is not currently open and then press OK'}; 
    uiwait(msgbox(infostr,'NSB_GenerateStatTable','warn','modal'));
    [status,msg] = NSB_WriteGenericCSV(SheetHeader, fullfile(outputPath, 'NSB_Cerridwen-SleepStatisticalAnalysisTable.csv'),false);
end

SeizureStatsHeader = ['Date,Subject,Channel Name,Channel Num,Manipulation,Total Number of Spike Trains,Total Spike Train Duration (min),Percent of Recording,Mean Spike Train Duration (sec),Longest Spike Train Duration (sec),Shortest Spike Train Duration (sec),Mean Number of Spikes/Train'];
SeizureStatsHeader = regexp(SeizureStatsHeader,'[/()\w\s\.]*','match');
try
[status,msg] = NSB_WriteGenericCSV(SeizureStatsHeader, fullfile(outputPath, 'NSB_Cerridwen-SeizureStatisticalAnalysisTable.csv'),false);
catch
    infostr = {'Warning: NSB_GenerateStatTable >> Cannot write NSB_Cerridwen-SeizureStatisticalAnalysisTable.';'Check that the file is not currently open and then press OK'}; 
    uiwait(msgbox(infostr,'NSB_GenerateStatTable','warn','modal'));
    [status,msg] = NSB_WriteGenericCSV(SheetHeader, fullfile(outputPath, 'NSB_Cerridwen-SeizureStatisticalAnalysisTable.csv'),false);
end

if options.progress, h = waitbar(0,'Loading Study Design .xls'); RowWaitPos = get(h,'Position'); end

%build a stats table
[~,~,StudyDesign] = xlsread(StudyDesignPath); %'~' does not work in earlier matlab versions (2010 ?)
StatsSheet = cell(0);
oldStatsSheetSize = [NaN, NaN];
RMtableCNTR = 1;
RMtable = [];
DesignLength = size(StudyDesign,1);
for curRow = 2:DesignLength
    try
        if options.progress, waitbar((curRow-1)/(DesignLength-1),h,['Processing Entry ',num2str(curRow-1),' ...']); end
    catch
        %progress bar deleted
        errorstr = ['ERROR: NSB_GenerateStatTable >> Progress Terminated. Abort writing Statistical Table.'];
        if ~isempty(options.logfile)
            status = NSBlog(options.logfile,errorstr);
        else
            errordlg(errorstr,'NSB_GenerateStatTable','replace');
        end
        return;
    end   
    
    eegProcessed = false;
    ssProcessed = false;
    %read data
    disp(['Processing Row #', num2str(curRow),' ...']);
    PivotRow = []; eegProcessed = false;
    ssPivotRow = []; ssProcessed = false;
    
    %Get Column Indexes
    PathCol = find(strcmpi(StudyDesign(1,:),'File Path'));
    AnimalCol = find(strcmpi(StudyDesign(1,:),'Animal'));
    if isempty(AnimalCol)
        AnimalCol = find(strcmpi(StudyDesign(1,:),'Subject'));
    end
    if isempty(AnimalCol)
        AnimalCol = find(strcmpi(StudyDesign(1,:),'SubjectID'));
    end
    DateCol = find(strcmpi(StudyDesign(1,:),'Date'));
    DoseCol = find(strcmpi(StudyDesign(1,:),'Manipulation/Dose'));
    DoseTimeCol = find(strcmpi(StudyDesign(1,:),'Dose Time'));
    DataChannelCol = find(strcmpi(StudyDesign(1,:),'Analysis Channel'));

    if ~isnan(StudyDesign{curRow,PathCol})
        %deal with the fact that "File Path can be a file or path and data dir is in path"
        FilePath = StudyDesign{curRow,PathCol};
        FilePathType = exist(FilePath);
        if FilePathType == 2
            [DataFolderPath,fn,ext] = fileparts(StudyDesign{curRow,PathCol});
        elseif FilePathType == 7
            %this is overkill...
            if ispc
                IDX = find(FilePath == '/' | FilePath == '\', 1, 'last');
            else
                IDX = find(FilePath == '/', 1, 'last');
            end
            if IDX ~= length(FilePath) %missing terminus filesep
                DataFolderPath = [FilePath,filesep];
            else
                DataFolderPath = FilePath;
            end
        end
        %test for output Dir...
        if exist(fullfile(DataFolderPath,'NSB_Output')) == 0
            errorstr = ['Warning: NSB_GenerateStatTable >> NSB_Output folder not found in ',DataFolderPath];
            if ~isempty(options.logfile)
                status = NSBlog(options.logfile,errorstr);
            else
                errordlg(errorstr,'NSB_GenerateStatTable','replace');
            end
            continue;
        end
        
        errorstr = ['Information: NSB_GenerateStatTable >> Processing row entry # ',num2str(curRow),' Data file: ',StudyDesign{curRow,PathCol}];
        if ~isempty(options.logfile)
            status = NSBlog(options.logfile,errorstr);
        else
            disp(errorstr);
        end
       
        FileList = fuf(fullfile(DataFolderPath,'NSB_Output'),0); %<< only filenames
        SpectralData_IDX = ~cellfun(@isempty, strfind(FileList, 'SpectralData.csv'));
        SomnoData_IDX = ~cellfun(@isempty, strfind(FileList, 'SomnogramData.csv'));
        SleepStats_IDX = ~cellfun(@isempty, strfind(FileList, 'SleepStatistics.csv'));
        SeizureStats_IDX = ~cellfun(@isempty, strfind(FileList, 'SeizureDataSummary.csv'));
        
        %find data type files
        SpectralFileList = FileList(SpectralData_IDX); % <File List
        SomnoFileList = FileList(SomnoData_IDX);
        SleepStatsList = FileList(SleepStats_IDX);
        SeizureStatsList = FileList(SeizureStats_IDX);
        
        %find files of date
        curSplitField = 3;
        if options.fnHasDateID
        DateID = StudyDesign{curRow,DateCol}; %Can be number or string
        if ischar(DateID)
            try
            DateID = datestr(datenum(DateID),29); %force into this format
            catch
            errorstr = ['Warning: NSB_GenerateStatTable >> Study Design has a badly formatted recording date. Skipping Row: ',num2str(curRow-1)];
            if ~isempty(options.logfile)
                status = NSBlog(options.logfile,errorstr);
            else
                errordlg(errorstr,'NSB_GenerateStatTable','replace');
            end
            continue;
            end
        elseif isnumeric(DateID) && ~isnan(DateID)
            DateID = datestr(DateID,29);
        else
            errorstr = ['Warning: NSB_GenerateStatTable >> Study Design has none or a badly formatted recording date. Skipping Row: ',num2str(curRow-1)];
            if ~isempty(options.logfile)
                status = NSBlog(options.logfile,errorstr);
            else
                errordlg(errorstr,'NSB_GenerateStatTable','replace');
            end
            continue;
        end
        SpectralFileList_split = regexp(SpectralFileList,'_','split');
        SpectralData_IDX = false(length(SpectralFileList),1);
        for curfile = 1:length(SpectralFileList)
            if ~isempty(strfind(SpectralFileList_split{curfile}{curSplitField}, DateID))  %<<<<<<<<<  Hardcoded to new Specifications
                SpectralData_IDX(curfile) = true;
            end
        end
        SomnoFileList_split = regexp(SomnoFileList,'_','split');
        SomnoData_IDX = false(length(SomnoFileList),1);
        for curfile = 1:length(SomnoFileList)
            if ~isempty(strfind(SomnoFileList_split{curfile}{curSplitField}, DateID))
                SomnoData_IDX(curfile) = true;
            end
        end
        SleepStatsList_split = regexp(SleepStatsList,'_','split');
        SleepStatsList_IDX = false(length(SleepStatsList),1);
        for curfile = 1:length(SleepStatsList)
            if ~isempty(strfind(SleepStatsList_split{curfile}{curSplitField}, DateID))
                SleepStatsList_IDX(curfile) = true;
            end
        end        
        SeizureStatsList_split = regexp(SeizureStatsList,'_','split');
        SeizureStatsList_IDX = false(length(SeizureStatsList),1);
        for curfile = 1:length(SeizureStatsList)
            if ~isempty(strfind(SeizureStatsList_split{curfile}{curSplitField}, DateID))
                SeizureStatsList_IDX(curfile) = true;
            end
        end
        
        SpectralFileList = SpectralFileList(SpectralData_IDX); % <File List conditions on DateID
        SomnoFileList = SomnoFileList(SomnoData_IDX);
        SleepStatsList = SleepStatsList(SleepStatsList_IDX);
        SeizureStatsList = SeizureStatsList(SeizureStatsList_IDX);
        curSplitField = curSplitField +1;
        
        end
        
        %Find files of SubjectID
        SubjectID = StudyDesign{curRow,AnimalCol}; %Can be number or string
        if ~ischar(SubjectID)
            SubjectID = num2str(SubjectID);
        end
        %because there could be multiple issue if some one call it subject
        %"1" explicitly do regexp lookup
        SpectralFileList_split = regexp(SpectralFileList,'_','split');
        SubjectSpectralData_IDX = false(length(SpectralFileList),1);
        for curfile = 1:length(SpectralFileList)
            if strcmp(SpectralFileList_split{curfile}{curSplitField}, SubjectID)  %<<<<<<<<<  Hardcoded to new Specifications <<<STRFIND may not be the best if you are finding a "1" in "1" and "18"
                SubjectSpectralData_IDX(curfile) = true;
            end
        end
        SomnoFileList_split = regexp(SomnoFileList,'_','split');
        SubjectSomnoData_IDX = false(length(SomnoFileList),1);
        for curfile = 1:length(SomnoFileList)
            if strcmp(SomnoFileList_split{curfile}{curSplitField}, SubjectID)  %<<<<<<<<<  Hardcoded to new Specifications
                SubjectSomnoData_IDX(curfile) = true;
            end
        end
        SleepStatsList_split = regexp(SleepStatsList,'_','split');
        SubjectSleepStatsList_IDX = false(length(SleepStatsList),1);
        for curfile = 1:length(SleepStatsList)
            if strcmp(SleepStatsList_split{curfile}{curSplitField}, SubjectID)  %<<<<<<<<<  Hardcoded to new Specifications
                SubjectSleepStatsList_IDX(curfile) = true;
            end
        end
        SeizureStatsList_split = regexp(SeizureStatsList,'_','split');
        SubjectSeizureStatsList_IDX = false(length(SeizureStatsList),1);
        for curfile = 1:length(SeizureStatsList)
            if strcmp(SeizureStatsList_split{curfile}{curSplitField}, SubjectID)  %<<<<<<<<<  Hardcoded to new Specifications
                SubjectSeizureStatsList_IDX(curfile) = true;
            end
        end
        
        SubjectSpectralFileList = SpectralFileList(SubjectSpectralData_IDX); % <File List conditions on SubjectID
        SubjectSomnoFileList = SomnoFileList(SubjectSomnoData_IDX);
        SubjectSleepStatsList = SleepStatsList(SubjectSleepStatsList_IDX);
        SubjectSeizureStatsList = SeizureStatsList(SubjectSeizureStatsList_IDX);
        
        %check for multiple channels << Spectral only
        SubjectSpectralFileChannelList = [];
        SubjectSpectralFileChannelName = cell(0);
        SpectralFileList_split = regexp(SubjectSpectralFileList,'_','split');
        for curfile = 1:length(SubjectSpectralFileList)
            SubjectSpectralFileChannelList = [SubjectSpectralFileChannelList; str2double(SpectralFileList_split{curfile}{end-1})];
            SubjectSpectralFileChannelName{curfile} = SpectralFileList_split{curfile}{end-2};
        end
        [SubjectSpectralFileChannelList_sort, SubjectSpectralFileChannelList_IDX] = sort(SubjectSpectralFileChannelList);
        
        %check for multiple channels << Seizure only
        SubjectSeizureStatsChannelList = [];
        SubjectSeizureStatsChannelName = cell(0);
        SeizureFileList_split = regexp(SubjectSeizureStatsList,'_','split');
        for curfile = 1:length(SubjectSeizureStatsList)
            SubjectSeizureStatsChannelList = [SubjectSeizureStatsChannelList; str2double(SeizureFileList_split{curfile}{end-1})];
            SubjectSeizureStatsChannelName{curfile} = SeizureFileList_split{curfile}{end-2};
        end
        [SubjectSeizureFileChannelList_sort, SubjectSeizureFileChannelList_IDX] = sort(SubjectSeizureStatsChannelList);
        
        if options.progress, h_chan = waitbar(0,'Processing Channel ...','Position',[RowWaitPos(1) RowWaitPos(2)-RowWaitPos(4) RowWaitPos(3:4)]); end
        totalChans = max(max(length(SubjectSpectralFileChannelList), length(SubjectSeizureStatsChannelList)), length(SubjectSomnoFileList));
        %original -> totalChans = max(length(SubjectSpectralFileChannelList), length(SubjectSeizureStatsChannelList));
        
        for curChan = 1:totalChans %<<<<< if missing channel this will fail poorly
            disp(['     Processing Channel #',num2str(curChan)]);
            
            %test for channel in Study design <<<<<<<<<<<<<<<This assumes
            %that there is always a spectral channel!!!!
            if ~isempty(DataChannelCol)
                try
                    %this is wrong but working. to fix make sure channel
                    %number matches recorded channel
                    if ~all(isnan([StudyDesign{curRow,DataChannelCol}])) %make sure user did not leave all empty columns << process all 
                    if ~ismember(SubjectSpectralFileChannelList_sort(SubjectSpectralFileChannelList_IDX(curChan)), [StudyDesign{curRow,DataChannelCol}]) && ...
                       ~any(strcmp(SubjectSpectralFileChannelName(SubjectSpectralFileChannelList_IDX(curChan)), {StudyDesign{curRow,DataChannelCol}}))
                        infostr = ['Information: NSB_GenerateStatTable >> Channel #',num2str(SubjectSpectralFileChannelList_IDX(curChan)),' not present in Study Design. Skipping Channel.'];
                        if ~isempty(options.logfile)
                            NSBlog(options.logfile,infostr);
                        else
                            errordlg(infostr,'NSB_GenerateStatTable','replace');
                        end
                        continue;
                    end
                    end
                catch
                    infostr = ['Information: NSB_GenerateStatTable >> Channel #',num2str(curChan),' not present in file list. Skipping Channel.'];
                        if ~isempty(options.logfile)
                            NSBlog(options.logfile,infostr);
                        else
                            errordlg(infostr,'NSB_GenerateStatTable','replace');
                        end
                end
            end
            
            %test for multiple spectral  files recorded for same subject on same day.
            try
                if sum( SubjectSpectralFileChannelList == str2double(SpectralFileList_split{SubjectSpectralFileChannelList_IDX(curChan)}{end-1}) ) > 1
                    %Id Current file of multiple Files
                    curChannelName = SpectralFileList_split{SubjectSpectralFileChannelList_IDX(curChan)}{4}; %<<<<<<<<<<<  HardCoded Current File name Spec.
                end
            end
            
            %disp Info
            if options.progress, waitbar((curChan)/totalChans,h_chan,['Processing Channel ',num2str(curChan),' ...']); end
            %             infostr = ['Information: NSB_GenerateStatTable >> Loading ... ',fullfile(DataFolderPath,'NSB_Output',SubjectSpectralFileList{SubjectSpectralFileChannelList_IDX(curChan)})];
            %             disp(infostr);
            %             if ~isempty(options.logfile)
            %                 NSBlog(options.logfile,infostr);
            %             else
            %                 errordlg(infostr,'NSB_GenerateStatTable','replace');
            %             end
            
            try
                eegProcessed = false;
                %Read/Process EEG Data File sorted by channel Number !
                [~,~,eegdata] = xlsread(fullfile(DataFolderPath,'NSB_Output',SubjectSpectralFileList{SubjectSpectralFileChannelList_IDX(curChan)}));
                
                if isempty(eegdata)
                    infostr = ['ERROR: NSB_GenerateStatTable >> No Data in File: ', fullfile(DataFolderPath,'NSB_Output',SubjectSpectralFileList{SubjectSpectralFileChannelList_IDX(curChan)}), 'Skipping Channel.'];
                    if ~isempty(options.logfile)
                        NSBlog(options.logfile,infostr);
                    else
                        errordlg(infostr,'NSB_GenerateStatTable','replace');
                    end
                    continue;
                end
                
                IDX = cellfun(@(x) ischar(x) && strcmp(strtrim(x),'NaN') ,eegdata); % Find non-numeric cells
                eegdata(IDX) = {NaN}; % Replace non-numeric cells
                eegdata= cell2mat(eegdata(2:end,:));
                
                %generate pivot for EEG
                %determine whether Dose time is a date + time or just time and handle it
                if ~isempty(DoseTimeCol)
                    if ischar(StudyDesign{curRow,DoseTimeCol}) %most likely full date -or- badly formed time
                        if any(strfind(StudyDesign{curRow,DoseTimeCol},'/')) %has date
                            StudyDesign{curRow,DoseTimeCol} = datenum(StudyDesign{curRow,DoseTimeCol});
                        else
                            StudyDesign{curRow,DoseTimeCol} = datevec(datenum(StudyDesign{curRow,DoseTimeCol}));
                            StudyDesign{curRow,DoseTimeCol}(1:3) = [0,0,0];
                            StudyDesign{curRow,DoseTimeCol} = datenum(StudyDesign{curRow,DoseTimeCol});
                        end
                    end
                    if StudyDesign{curRow,DoseTimeCol} < 1 %just time
                        DoseTime = datenum(StudyDesign{curRow,DateCol}) + StudyDesign{curRow,DoseTimeCol};
                    else %date and time
                        DoseTime = StudyDesign{curRow,DoseTimeCol};
                    end
                    if ~isnan(DoseTime) && ~isempty(DoseTime)
                        infostr = ['Information: NSB_GenerateStatTable >> Data Start Time: ',datestr(eegdata(1,3)),' Dosing Time: ',datestr(DoseTime)];
                    else
                        infostr = ['Information: NSB_GenerateStatTable >> Data Start Time: ',datestr(eegdata(1,3)),' Dosing Time: Not Found'];
                    end
                    disp(infostr);
                    if ~isempty(options.logfile)
                        NSBlog(options.logfile,infostr);
                    else
                        errordlg(infostr,'NSB_GenerateStatTable','replace');
                    end
                else
                    DoseTime = NaN;
                    infostr = ['Warning: NSB_GenerateStatTable >> Data Start Time: ',datestr(eegdata(1,3)),' No "Dosing Time" column found in Study Design Spreadsheet. '];
                    disp(infostr);
                    if ~isempty(options.logfile)
                        NSBlog(options.logfile,infostr);
                    else
                        errordlg(infostr,'NSB_GenerateStatTable','replace');
                    end
                end
                %DoseTime = datenum(StudyDesign{curRow,DateCol}) + StudyDesign{curRow,8}; %<<<<<<<<<<<<<<<<<< hard coded !!!
                if ~isnan(DoseTime)
                    PivotRow = find(eegdata(:,3) >= DoseTime, 1 ,'first'); %EEG Spread sheet, date num is col 3
                    PivotEpoch = eegdata(PivotRow,4); % %EEG Spread sheet, seconds is col 4
                    if PivotRow > 1
                        eegdata(:,4) = eegdata(:,4) - PivotEpoch;
                    else
                        DoseTime = NaN; %There is no baseline data
                    end
                else
                    infostr = ['Warning: NSB_GenerateStatTable >> No "Dosing Time" found for Spectral Spreadsheet. '];
                    disp(infostr);
                    if ~isempty(options.logfile)
                        NSBlog(options.logfile,infostr);
                    else
                        errordlg(infostr,'NSB_GenerateStatTable','replace');
                    end
                end
                
                if options.doMeanBaseline
                    if ~isempty(BaselineMeanTimeStart) && ~isempty(BaselineMeanTimeEnd)
                        BaselineMeanTimeStartRow = find(eegdata(:,4) <= BaselineMeanTimeStart, 1 ,'last');
                        BaselineMeanTimeEndRow = find(eegdata(:,4) >= BaselineMeanTimeEnd, 1 ,'first');
                        BaselineMean = nanmean(eegdata(BaselineMeanTimeEndRow:BaselineMeanTimeStartRow,5:end),1);
                    elseif ~isempty(BaselineMeanTimeStart) && isempty(BaselineMeanTimeEnd)
                        BaselineMeanTimeStartRow = find(eegdata(:,4) <= BaselineMeanTimeStart, 1 ,'last');
                        BaselineMean = nanmean(eegdata(1:BaselineMeanTimeStartRow,5:end),1);
                    else
                        BaselineMean = nanmean(eegdata(1:PivotRow,5:end),1);
                    end
                    if ~isnan(DoseTime)
                        eegdata(:,5:end) =  eegdata(:,5:end)./repmat(BaselineMean,size(eegdata,1),1);
                    else
                        infostr = ['Warning: NSB_GenerateStatTable >> Cannot calculate baseline mean.'];
                        disp(infostr);
                        if ~isempty(options.logfile)
                            NSBlog(options.logfile,infostr);
                        else
                            errordlg(infostr,'NSB_GenerateStatTable','replace');
                        end
                    end
                end
                
                if options.MovAve.do
                    eegdata(:,5:end) = NSB_boxcarSmooth(eegdata(:,5:end),options.MovAve.window);
                end
                
                disp('... Spectral Spreadsheet Processed.');
                if exist('eegdata','var')
                    eegProcessed = true;
                end
            catch ME
                %disp('>> ERROR - Data Not Loaded.');
                if ~isempty(SubjectSpectralFileChannelList_IDX)
                    if curChan <= length(SubjectSpectralFileChannelList_IDX)
                    infostr = ['ERROR: NSB_GenerateStatTable >> Data Not Loaded: ',fullfile(DataFolderPath,'NSB_Output',SubjectSpectralFileList{SubjectSpectralFileChannelList_IDX(curChan)})];
                    else
                    infostr = ['ERROR: NSB_GenerateStatTable >> Data Not Loaded - Next Data File Does Not Exist: ',fullfile(DataFolderPath,'NSB_Output',SubjectSpectralFileList{SubjectSpectralFileChannelList_IDX(end)})];    
                    end
                    disp(infostr);
                    errorstr = [ME.identifier, 'Function: ', ME.stack(1).name,' Line: ',num2str(ME.stack(1).line)];
                    disp(errorstr);
                    disp(ME.message);
                    infostr = ['ERROR: NSB_GenerateStatTable >> Data Not Loaded ',  errorstr,  ME.message];
                    if ~isempty(options.logfile)
                        NSBlog(options.logfile,infostr);
                    else
                        errordlg(infostr,'NSB_GenerateStatTable','replace');
                    end
                    continue;
                end
            end
            
            
            %Processess Sleep Scoring If Avalable
            try
                ssProcessed = false;
                SubjectSomnoFileChannelList = [];
                SomnoFileList_split = regexp(SubjectSomnoFileList,'_','split');
                for curfile = 1:length(SubjectSomnoFileList)
                    SubjectSomnoFileChannelList = [SubjectSomnoFileChannelList; str2double(SomnoFileList_split{curfile}{end-1})];
                end
                if ~isempty(SubjectSomnoFileChannelList)
                    SubjectSomnoFileChannelList_IDX = [];
                    try
                        %get channel of Spectral data loaded
                        SubjectSpectralChannel = str2double(SpectralFileList_split{SubjectSpectralFileChannelList_IDX(curChan)}{end-1});
                        SubjectSomnoFileChannelList_IDX = find(SubjectSomnoFileChannelList == SubjectSpectralChannel);
                        if length(SubjectSomnoFileChannelList_IDX) > 1
                            SomnoCurChannelNamesCntr = 1;
                            for curIDX = SubjectSomnoFileChannelList_IDX' %<< new - only iterates across columns
                                if options.fnHasDateID
                                    SomnoCurChannelNames{SomnoCurChannelNamesCntr} = SomnoFileList_split{curIDX}{1,4};
                                else
                                    SomnoCurChannelNames{SomnoCurChannelNamesCntr} = SomnoFileList_split{curIDX}{1,3};
                                end
                                SomnoCurChannelNamesCntr = SomnoCurChannelNamesCntr +1;
                            end
                            SubjectSomnoFileChannelList_IDX = SubjectSomnoFileChannelList_IDX(strcmpi(curChannelName, SomnoCurChannelNames) );
                        end
                    end
                    
                    if isempty(SubjectSomnoFileChannelList_IDX)
                        infostr = ['Warning: NSB_GenerateStatTable >> Could not find correct spectral channel for Somnogram Spreadsheet. '];
                        if ~isempty(options.logfile)
                            NSBlog(options.logfile,infostr);
                        else
                            errordlg(infostr,'NSB_GenerateStatTable','replace');
                        end
                        disp(infostr);
                        %New Try to use the current channel
                        SubjectSomnoFileChannelList_IDX = curChan;
                    end
                    
                    %>>>  This is how I fixed it:   SubjectSomnoFileChannelList_IDX = find(SubjectSomnoFileChannelList == SubjectSpectralFileChannelList_sort(SubjectSpectralFileChannelList_IDX(curChan)));
                    %                     infostr = ['Information: NSB_GenerateStatTable >> Loading ... ',fullfile(DataFolderPath,'NSB_Output',SubjectSomnoFileList{SubjectSomnoFileChannelList_IDX})];
                    %                     disp(infostr);
                    %                     if ~isempty(options.logfile)
                    %                         NSBlog(options.logfile,infostr);
                    %                     else
                    %                         errordlg(infostr,'NSB_GenerateStatTable','replace');
                    %                     end
                    
                    %Read/Process SleepScoring Data File
                    [~,~,ssdata] = xlsread(fullfile(DataFolderPath,'NSB_Output',SubjectSomnoFileList{SubjectSomnoFileChannelList_IDX}));
                    ssdataLables = ssdata(2:end,5);
                    ssdata = cell2mat(ssdata(2:end,1:4));% << HardCoded
                    %generate pivot for ssData
                    if exist('DoseTime','var') == 0
                        DoseTime = NaN;
                    end
                    
                    if ~isnan(DoseTime)
                        ssPivotRow = find(ssdata(:,2) > DoseTime, 1 ,'first'); %Hypnogram Spread sheet, date num is col 3 (no Valid Marker)
                        ssPivotEpoch = ssdata(ssPivotRow,3);
                        ssdata(:,3) = ssdata(:,3) - ssPivotEpoch;
                    else
                        infostr = ['Warning: NSB_GenerateStatTable >> No "Dosing Time" found for Somnogram Spreadsheet. '];
                        if ~isempty(options.logfile)
                            NSBlog(options.logfile,infostr);
                        else
                            errordlg(infostr,'NSB_GenerateStatTable','replace');
                        end
                    end
                    disp('... Somnogram Spreadsheet Processed.');
                    if exist('ssdata','var') == 1
                        ssProcessed = true;
                    end
                else
                    ssProcessed = false;
                    ssPivotRow = [];
                end
            catch ME
                ssProcessed = false;
                ssPivotRow = [];
                %disp('>> Warning - Data Not Found.');
                if SubjectSomnoFileChannelList_IDX <= numel(SubjectSomnoFileList)
                infostr = ['ERROR: NSB_GenerateStatTable >> Data Not Loaded: ',fullfile(DataFolderPath,'NSB_Output',SubjectSomnoFileList{SubjectSomnoFileChannelList_IDX})];
                else
                infostr = ['ERROR: NSB_GenerateStatTable >> Data Not Loaded: '];    
                end
                disp(infostr);
                disp(ME.identifier);
                disp(ME.message);
                infostr = ['Warning: NSB_GenerateStatTable >> Sleep Scoring Data Not Found ',  ME.identifier,  ME.message];
                if ~isempty(options.logfile)
                    NSBlog(options.logfile,infostr);
                else
                    errordlg(infostr,'NSB_GenerateStatTable','replace');
                end
            end
            
            %Process SleepStatistics
            try
                SleepStatProcessed = false;
                SubjectSleepStatsFileChannelList = [];
                SubjectSleepStatsFileList_split = regexp(SubjectSleepStatsList,'_','split');
                for curfile = 1:length(SubjectSleepStatsList)
                    SubjectSleepStatsFileChannelList = [SubjectSleepStatsFileChannelList; str2double(SubjectSleepStatsFileList_split{curfile}{end-1})];
                end
                if ~isempty(SubjectSleepStatsFileChannelList)
                    SubjectSleepStatsFileChannelList_IDX = [];
                    try
                        %get channel of Spectral data loaded
                        SubjectSleepStatsChannel = str2double(SpectralFileList_split{SubjectSpectralFileChannelList_IDX(curChan)}{end-1});
                        SubjectSleepStatsFileChannelList_IDX = find(SubjectSleepStatsFileChannelList == SubjectSleepStatsChannel);
                        if length(SubjectSleepStatsFileChannelList_IDX) > 1
                            SleepStatsCurChannelNamesCntr = 1;
                            for curIDX = SubjectSleepStatsFileChannelList_IDX' %<< new - only iterates across columns
                                if options.fnHasDateID
                                    SleepStatsCurChannelNames{SleepStatsCurChannelNamesCntr} = SomnoFileList_split{curIDX}{1,4};
                                else
                                    SleepStatsCurChannelNames{SleepStatsCurChannelNamesCntr} = SomnoFileList_split{curIDX}{1,3};
                                end
                                SleepStatsCurChannelNamesCntr = SleepStatsCurChannelNamesCntr +1;
                            end
                            SubjectSleepStatsFileChannelList_IDX = SubjectSleepStatsFileChannelList_IDX(strcmpi(curChannelName, SleepStatsCurChannelNames) );
                        end
                    end
                    if isempty(SubjectSleepStatsFileChannelList_IDX)
                        SubjectSleepStatsFileChannelList_IDX = curChan;
                    end
                    %                     infostr = ['Information: NSB_GenerateStatTable >> Loading ... ',fullfile(DataFolderPath,'NSB_Output',SubjectSleepStatsList{SubjectSleepStatsFileChannelList_IDX})];
                    %                     disp(infostr);
                    %                     if ~isempty(options.logfile)
                    %                         NSBlog(options.logfile,infostr);
                    %                     else
                    %                         errordlg(infostr,'NSB_GenerateStatTable','replace');
                    %                     end
                    
                    %Read/Process SleepScoring Data File
                    [~,~,SleepStatsData] = xlsread(fullfile(DataFolderPath,'NSB_Output',SubjectSleepStatsList{SubjectSleepStatsFileChannelList_IDX}));
                    IDX = cellfun(@(x) ischar(x) && strcmp(strtrim(x),'NaN') ,SleepStatsData); % Find non-numeric cells
                    SleepStatsData(IDX) = {NaN}; % Replace non-numeric cells
                    SleepStatsData = cell2mat(SleepStatsData(2:end,:));
                    
                    disp('... SleepStatistics Spreadsheet Processed.');
                    if exist('SleepStatsData','var')
                        SleepStatProcessed = true;
                    end
                else
                    SleepStatProcessed = false;
                end
            catch ME
                SleepStatProcessed = false;
                ssPivotRow = [];
                try
                infostr = ['ERROR: NSB_GenerateStatTable >> Data Not Loaded: ',fullfile(DataFolderPath,'NSB_Output',SubjectSleepStatsList{SubjectSleepStatsFileChannelList_IDX})];
                catch
                infostr = ['ERROR: NSB_GenerateStatTable >> Data Not Loaded: ',fullfile(DataFolderPath,'NSB_Output',SubjectSleepStatsList{end}),' Channel# ',num2str(SubjectSleepStatsFileChannelList_IDX)];    
                end
                disp(infostr);
                disp(ME.identifier);
                disp(ME.message);
                %disp('>> Warning - Data Not Found.');
                infostr = ['Warning: NSB_GenerateStatTable >> SleepStatistics Data Not Found ',  ME.identifier,  ME.message];
                if ~isempty(options.logfile)
                    NSBlog(options.logfile,infostr);
                else
                    errordlg(infostr,'NSB_GenerateStatTable','replace');
                end
            end
            
            %Process SeizureStatistics
            try
                SeizureStatProcessed = false;
                SubjectSeizureStatsFileChannelList = [];
                SubjectSeizureStatsFileList_split = regexp(SubjectSeizureStatsList,'_','split');
                for curfile = 1:length(SubjectSeizureStatsList)
                    SubjectSeizureStatsFileChannelList = [SubjectSeizureStatsFileChannelList; str2double(SubjectSeizureStatsFileList_split{curfile}{end-1})];
                end
                if ~isempty(SubjectSeizureStatsFileChannelList)
                    %get channel of Spectral data loaded
                    SubjectSeizureStatsChannel = str2double(SeizureFileList_split{SubjectSeizureFileChannelList_IDX(curChan)}{end-1});
                    SubjectSeizureStatsFileChannelList_IDX = find(SubjectSeizureStatsFileChannelList == SubjectSeizureStatsChannel);
                    if length(SubjectSeizureStatsFileChannelList_IDX) > 1
                        SeizureStatsCurChannelNamesCntr = 1;
                        for curIDX = SubjectSeizureStatsFileChannelList_IDX' %<< new - only iterates across columns
                            if options.fnHasDateID
                                SeizureStatsCurChannelNames{SeizureStatsCurChannelNamesCntr} = SomnoFileList_split{curIDX}{1,4};
                            else
                                SeizureStatsCurChannelNames{SeizureStatsCurChannelNamesCntr} = SomnoFileList_split{curIDX}{1,3};
                            end
                            SeizureStatsCurChannelNamesCntr = SeizureStatsCurChannelNamesCntr +1;
                        end
                        SubjectSeizureStatsFileChannelList_IDX = SubjectSeizureStatsFileChannelList_IDX(strcmpi(curChannelName, SeizureStatsCurChannelNames) );
                    end
                    %                     infostr = ['Information: NSB_GenerateStatTable >> Loading ... ',fullfile(DataFolderPath,'NSB_Output',SubjectSeizureStatsList{SubjectSeizureStatsFileChannelList_IDX})];
                    %                     disp(infostr);
                    %                     if ~isempty(options.logfile)
                    %                         NSBlog(options.logfile,infostr);
                    %                     else
                    %                         errordlg(infostr,'NSB_GenerateStatTable','replace');
                    %                     end
                    
                    %Read/Process SeizureScoring Data File
                    [~,~,SeizureStatsData] = xlsread(fullfile(DataFolderPath,'NSB_Output',SubjectSeizureStatsList{SubjectSeizureStatsFileChannelList_IDX}));
                    IDX = cellfun(@(x) ischar(x) && (strcmp(strtrim(x),'NaN') || strcmpi(strtrim(x),'N/A')) ,SeizureStatsData); % Find non-numeric cells
                    SeizureStatsData(IDX) = {NaN}; % Replace non-numeric cells
                    SeizureStatsData = cell2mat(SeizureStatsData(2:end,:)); %<< File Contains Header
                    
                    disp('... SeizureStatistics Spreadsheet Processed.');
                    if exist('SeizureStatsData','var')
                        SeizureStatProcessed = true;
                    end
                else
                    SeizureStatProcessed = false;
                end
            catch ME
                SeizureStatProcessed = false;
                ssPivotRow = [];
                infostr = ['ERROR: NSB_GenerateStatTable >> Data Not Loaded: ',fullfile(DataFolderPath,'NSB_Output',SubjectSeizureStatsList{SubjectSeizureStatsFileChannelList_IDX})];
                disp(infostr);
                disp(ME.identifier);
                disp(ME.message);
                %disp('>> Warning - Data Not Found.');
                infostr = ['Warning: NSB_GenerateStatTable >> SeizureStatistics Data Not Found ',  ME.identifier,  ME.message];
                if ~isempty(options.logfile)
                    NSBlog(options.logfile,infostr);
                else
                    errordlg(infostr,'NSB_GenerateStatTable','replace');
                end
            end
            
            if eegProcessed && ssProcessed
                %Error check for differences in size and pivot row
                %check for Pivot row (Predose length)
                if ~isempty(ssPivotRow) && ~isempty(PivotRow)
                    if ssPivotRow > PivotRow
                        ssdataLables(1:ssPivotRow-PivotRow) = [];
                        ssdata(1:ssPivotRow-PivotRow,:) = [];
                        disp('>> Repairing difference in Dose Pivot Rows (SleepScore > EEG)');
                    elseif PivotRow > ssPivotRow
                        eegdata(1:PivotRow-ssPivotRow,:) = [];
                        disp('>> Repairing difference in Dose Pivot Rows (EEG > SleepScore)');
                    end
                end
                %check for size (Postdose length)
                if size(ssdata,1) > size(eegdata,1)
                    ssdataLables = ssdataLables(1:size(eegdata,1),:);
                    ssdata = ssdata(1:size(eegdata,1),:);
                    disp('>> Repairing difference in Table Size (SleepScore > EEG)');
                elseif size(ssdata,1) < size(eegdata,1)
                    eegdata = eegdata(1:size(ssdata,1),:);
                    disp('>> Repairing difference in Table Size (EEG > SleepScore)');
                end
            end
            
            %Now Generate/Add Stats Sheets
            if SeizureStatProcessed
                %SeizureStatsHeader = ['Date,Subject,Channel Name,Channel Num,Manipulation,Total Number of Spike Trains,Total Spike Train Duration (min),Percent of Recording,Mean Spike Train Duration (sec),Longest Spike Train Duration (sec),Shortest Spike Train Duration (sec),Mean Number of Spikes/Train'];
                curChanVec = SubjectSeizureStatsChannelList(SubjectSeizureFileChannelList_IDX(curChan));
                curChanVec = num2cell(curChanVec);
                %New Format
                StatsSheet = [ {datestr(datenum(StudyDesign{curRow,DateCol}))} , StudyDesign(curRow,AnimalCol),...
                    SubjectSeizureStatsChannelName(SubjectSeizureFileChannelList_IDX(curChan)),curChanVec,StudyDesign(curRow,DoseCol),num2cell(SeizureStatsData)];
                %StatsSheet = [ num2cell(datenum(StudyDesign{curRow,DateCol})),StudyDesign(curRow,AnimalCol),...
                %    SubjectSeizureStatsChannelName(SubjectSeizureFileChannelList_IDX(curChan)),curChanVec,StudyDesign(curRow,DoseCol),num2cell(SeizureStatsData)];
                
                %Write File
                if options.progress, waitbar(1,h_chan,'Writing Seizure Stats .CSV ... Please Wait.'); end
                try
                    [status,msg] = NSB_WriteGenericCSV(StatsSheet, fullfile(outputPath, 'NSB_Cerridwen-SeizureStatisticalAnalysisTable.csv'),true);
                catch
                    infostr = {'Warning: NSB_GenerateStatTable >> Cannot write NSB_Cerridwen-SeizureStatisticalAnalysisTable.';'Check that the file is not currently open and then press OK'};
                    uiwait(msgbox(infostr,'NSB_GenerateStatTable','warn','modal'));
                    [status,msg] = NSB_WriteGenericCSV(StatsSheet, fullfile(outputPath, 'NSB_Cerridwen-SeizureStatisticalAnalysisTable.csv'),true);
                end
                clearvars StatsSheet curChanVec SeizureStatsData;
            end
            
            if SleepStatProcessed
                %SleepStatsHeader = ['Date,Subject,Channel Name,Channel Num,Manipulation,Total time in sleep cycle period (sec),Sleep Latency (sec),PS Latency (sec),Latency to Wake after Sleep onset (sec),Total Sleep Time (sec),PS Sleep Time (sec),nREM Sleep Time (sec),SWS1 Seep Time (sec),SWS2 Sleep Time (sec),Total Waking Time in sleep cycle period (sec),Quiet Waking Time (sec),Active Waking Time (sec)'];
                if ~isempty(SubjectSpectralFileChannelList)
                    curChanVec = SubjectSpectralFileChannelList(SubjectSpectralFileChannelList_IDX(curChan));
                    curChanVec = num2cell(curChanVec);
                    %New Format
                    StatsSheet = [ {datestr(datenum(StudyDesign{curRow,DateCol}))} ,StudyDesign(curRow,AnimalCol),...
                        SubjectSpectralFileChannelName(SubjectSpectralFileChannelList_IDX(curChan)),curChanVec,StudyDesign(curRow,DoseCol),num2cell(SleepStatsData)];
                else
                    curChanVec = curChan;
                    curChanVec = num2cell(curChanVec);
                    StatsSheet = [ {datestr(datenum(StudyDesign{curRow,DateCol}))} ,StudyDesign(curRow,AnimalCol),...
                        curChanVec,curChanVec,StudyDesign(curRow,DoseCol),num2cell(SleepStatsData)];
                end
                
                %New Format
                %StatsSheet = [ {datestr(datenum(StudyDesign{curRow,DateCol}))} ,StudyDesign(curRow,AnimalCol),...
                %    SubjectSpectralFileChannelName(SubjectSpectralFileChannelList_IDX(curChan)),curChanVec,StudyDesign(curRow,DoseCol),num2cell(SleepStatsData)];
                
                %StatsSheet = [ num2cell(datenum(StudyDesign{curRow,DateCol})),StudyDesign(curRow,AnimalCol),...
                %    SubjectSpectralFileChannelName(SubjectSpectralFileChannelList_IDX(curChan)),curChanVec,StudyDesign(curRow,DoseCol),num2cell(SleepStatsData)];
                %Write File
                if options.progress, waitbar(1,h_chan,'Writing Hypnogram Stats .CSV ... Please Wait.'); end
                try
                    [status,msg] = NSB_WriteGenericCSV(StatsSheet, fullfile(outputPath, 'NSB_Cerridwen-SleepStatisticalAnalysisTable.csv'),true);
                catch
                    infostr = {'Warning: NSB_GenerateStatTable >> Cannot write NSB_Cerridwen-SleepStatisticalAnalysisTable.';'Check that the file is not currently open and then press OK'};
                    uiwait(msgbox(infostr,'NSB_GenerateStatTable','warn','modal'));
                    [status,msg] = NSB_WriteGenericCSV(StatsSheet, fullfile(outputPath, 'NSB_Cerridwen-SleepStatisticalAnalysisTable.csv'),true);
                end
                clearvars StatsSheet curChanVec SleepStatsData;
            end
            
            if eegProcessed || ssProcessed
                %issue is that some channels could have different sampling rates
                if exist('eegdata','var') == 1
                    dataLength = size(eegdata,1);
                else
                    dataLength = size(ssdata,1);
                end
                if ~isnan(StudyDesign{curRow,DateCol})
                    curDateVec = num2cell( bsxfun(@times,ones(dataLength,1),datenum(StudyDesign{curRow,DateCol})) );
                else
                    if exist('eegdata','var') == 1
                        RecordingDate = datevec(eegdata(1,3));
                        curDateVec = num2cell( bsxfun(@times,ones(dataLength,1), datenum(RecordingDate(1:3))) );
                    else
                        RecordingDate = datevec(ssdata(1,2));
                        curDateVec = num2cell( bsxfun(@times,ones(dataLength,1), datenum(RecordingDate(1:3))) );
                    end
                end
                curDateVec = cellfun(@datestr,curDateVec,'UniformOutput', false); %<<< newformat to output as string not datenum
                curAnimalVec(1:dataLength,1) = StudyDesign(curRow,AnimalCol);
                curDoseVec(1:dataLength,1) = StudyDesign(curRow,DoseCol);
                if exist('eegdata','var') == 1
                    curChanVec(1:dataLength,1) = SubjectSpectralFileChannelList(SubjectSpectralFileChannelList_IDX(curChan));
                    curChanVec = num2cell(curChanVec);
                    curChanLabel(1:dataLength,1) = SubjectSpectralFileChannelName(SubjectSpectralFileChannelList_IDX(curChan));
                    curEpochVec = num2cell( eegdata(:,4) );
                    curValidVec = num2cell( eegdata(:,2) );
                    curDataMat = num2cell( eegdata(:,5:end) );
                else
                    curChanVec(1:dataLength,1) = curChan;
                    curChanVec = num2cell(curChanVec);
                    curChanLabel(1:dataLength,1) = {curChan};
                    curEpochVec = num2cell( ssdata(:,3) );
                    curValidVec = num2cell( ones(dataLength,1) );
                    curDataMat = num2cell( [] );
                end
            end
            
            if options.doRMtable
                if isnumeric(StudyDesign{curRow,AnimalCol})
                    curSubject = num2str(StudyDesign{curRow,AnimalCol});
                else
                    curSubject = StudyDesign{curRow,AnimalCol};
                end
                if isempty(RMtable)
                    %RMtable(RMtableCNTR).date(1) = StudyDesign{curRow,DateCol};
                    RMtable(RMtableCNTR).date = StudyDesign{curRow,DateCol};
                    RMtable(RMtableCNTR).subject = curSubject;
                    RMtable(RMtableCNTR).dose = StudyDesign{curRow,DoseCol};
                    RMtable(RMtableCNTR).Channel = SubjectSpectralFileChannelList(SubjectSpectralFileChannelList_IDX(curChan));
                    RMtable(RMtableCNTR).ts = eegdata(:,4);
                    RMtable(RMtableCNTR).tsMin = min(RMtable(RMtableCNTR).ts);
                    RMtable(RMtableCNTR).tsMax = max(RMtable(RMtableCNTR).ts);
                    RMtable(RMtableCNTR).valid = eegdata(:,2);
                    for curBand = 1:5
                        dynBandName = ['Band',num2str(curBand)];
                        RMtable(RMtableCNTR).(dynBandName).data = eegdata(:,4+curBand);
                        dynBandName = ['Ratio',num2str(curBand)];
                        RMtable(RMtableCNTR).(dynBandName).data = eegdata(:,9+curBand);
                    end
                    RMtableCNTR = RMtableCNTR +1;
                else
                    %If different add if not average into table.
                    SubjectIDX = strcmpi({RMtable(:).subject},curSubject);
                    DoseIDX = strcmpi({RMtable(:).dose},StudyDesign{curRow,DoseCol});
                    ChannelIDX = ismember([RMtable(:).Channel],SubjectSpectralFileChannelList(SubjectSpectralFileChannelList_IDX(curChan)));
                    DuplicateIDX = SubjectIDX & DoseIDX & ChannelIDX;
                    if ~any(DuplicateIDX) && ~isempty(DuplicateIDX)
                        %RMtable(RMtableCNTR).date(1) = StudyDesign{curRow,DateCol};
                        RMtable(RMtableCNTR).date = StudyDesign{curRow,DateCol};
                        RMtable(RMtableCNTR).subject = curSubject;
                        RMtable(RMtableCNTR).dose = StudyDesign{curRow,DoseCol};
                        RMtable(RMtableCNTR).Channel = SubjectSpectralFileChannelList(SubjectSpectralFileChannelList_IDX(curChan));
                        RMtable(RMtableCNTR).ts = eegdata(:,4);
                        RMtable(RMtableCNTR).tsMin = min(RMtable(RMtableCNTR).ts);
                        RMtable(RMtableCNTR).tsMax = max(RMtable(RMtableCNTR).ts);
                        RMtable(RMtableCNTR).valid = eegdata(:,2);
                        for curBand = 1:5
                            dynBandName = ['Band',num2str(curBand)];
                            RMtable(RMtableCNTR).(dynBandName).data = eegdata(:,4+curBand);
                            dynBandName = ['Ratio',num2str(curBand)];
                            RMtable(RMtableCNTR).(dynBandName).data = eegdata(:,9+curBand);
                        end
                        RMtableCNTR = RMtableCNTR +1;
                    else
                        RMtable(DuplicateIDX).date(end+1) = StudyDesign{curRow,DateCol};
                        RMtable(DuplicateIDX).tsMin = min(intersect(RMtable(DuplicateIDX).ts, eegdata(:,4)));
                        RMtable(DuplicateIDX).tsMax = max(intersect(RMtable(DuplicateIDX).ts, eegdata(:,4)));
                        tsMinIDX = [find(RMtable(DuplicateIDX).ts == RMtable(DuplicateIDX).tsMin,1,'first'), find(eegdata(:,4) == RMtable(DuplicateIDX).tsMin,1,'first')];
                        tsMaxIDX = [find(RMtable(DuplicateIDX).ts == RMtable(DuplicateIDX).tsMax,1,'first'), find(eegdata(:,4) == RMtable(DuplicateIDX).tsMax,1,'first')];
                        %trim
                        RMtable(DuplicateIDX).ts = RMtable(DuplicateIDX).ts( tsMinIDX(1) : tsMaxIDX(1) );
                        RMtable(DuplicateIDX).valid = RMtable(DuplicateIDX).valid( tsMinIDX(1) : tsMaxIDX(1) );
                        RMtable(DuplicateIDX).valid = RMtable(DuplicateIDX).valid && eegdata(tsMinIDX(2):tsMaxIDX(2),2); %are both valid
                        
                        for curBand = 1:5
                            dynBandName = ['Band',num2str(curBand)];
                            RMtable(DuplicateIDX).(dynBandName).data = nanmean([RMtable(DuplicateIDX).(dynBandName).data(tsMinIDX(1) : tsMaxIDX(1)) , eegdata(tsMinIDX(2):tsMaxIDX(2),4+curBand)],2);
                            dynBandName = ['Ratio',num2str(curBand)];
                            RMtable(DuplicateIDX).(dynBandName).data = nanmean([RMtable(DuplicateIDX).(dynBandName).data(tsMinIDX(1) : tsMaxIDX(1)) , eegdata(tsMinIDX(2):tsMaxIDX(2),9+curBand)],2);
                        end
                    end
                end
                
            end
            if eegProcessed && ssProcessed
                curSSVec = ssdataLables;
                %Added DMD July 10 2013
                StatsSheet = [curDateVec,curAnimalVec,curChanLabel,curChanVec,curDoseVec,curEpochVec,curValidVec, curSSVec, curDataMat];
                if size(StatsSheet,2) ~= oldStatsSheetSize(:,2) && ~any(isnan(oldStatsSheetSize)) %if stats sheet is not empty (first pass) and they are NOT the same size
                    infostr = ['ERROR: NSB_GenerateStatTable >> Data Table Not Same Size (Skipping): ', fullfile(DataFolderPath,'NSB_Output',SubjectSpectralFileList{SubjectSpectralFileChannelList_IDX(curChan)})];
                    if ~isempty(options.logfile)
                        NSBlog(options.logfile,infostr);
                    else
                        errordlg(infostr,'NSB_GenerateStatTable','replace');
                    end
                else
                    %Write File
                    if options.progress, waitbar(1,h_chan,'Writing Spectral Data .CSV ... Please Wait.'); end
                    try
                        [status,msg] = NSB_WriteGenericCSV(StatsSheet, fullfile(outputPath, 'NSB_Cerridwen-StatisticalAnalysisTable.csv'),true);
                    catch
                        infostr = {'Warning: NSB_GenerateStatTable >> Cannot write NSB_Cerridwen-StatisticalAnalysisTable.';'Check that the file is not currently open and then press OK'};
                        uiwait(msgbox(infostr,'NSB_GenerateStatTable','warn','modal'));
                        [status,msg] = NSB_WriteGenericCSV(StatsSheet, fullfile(outputPath, 'NSB_Cerridwen-StatisticalAnalysisTable.csv'),true);
                    end
                end
                if size(StatsSheet,2) > oldStatsSheetSize(2) || isnan(oldStatsSheetSize(2))
                    oldStatsSheetSize = size(StatsSheet);  %<< only if bigger?
                end
                %end add
                %StatsSheet = [StatsSheet; [curDateVec,curAnimalVec,curChanLabel,curChanVec,curDoseVec,curEpochVec,curValidVec, curSSVec, curDataMat]];
            elseif eegProcessed && ~ssProcessed

                %could be just EEG is being processed or failed to find
                %Sleep Scoring
                for n = 1:length(curValidVec)
                    curSSVec{n,1} = '';
                end
                %build table
                StatsSheet = [curDateVec,curAnimalVec,curChanLabel,curChanVec,curDoseVec,curEpochVec,curValidVec, curSSVec, curDataMat];
                if size(StatsSheet,2) ~= oldStatsSheetSize(2) && ~any(isnan(oldStatsSheetSize))
                    infostr = ['ERROR: NSB_GenerateStatTable >> Data Table Not Same Size (Skipping): ', fullfile(DataFolderPath,'NSB_Output',SubjectSpectralFileList{SubjectSpectralFileChannelList_IDX(curChan)})];
                    if ~isempty(options.logfile)
                        NSBlog(options.logfile,infostr);
                    else
                        errordlg(infostr,'NSB_GenerateStatTable','replace');
                    end
                    clearvars StatsSheet curDateVec curAnimalVec curChanLabel curChanVec curDoseVec curEpochVec curValidVec curDataMat curSSVec eegdata ssdata BaselineMean;
                    continue;
                    %>>>>>>>>>>>>
                else
                    %Write File
                    if options.progress, waitbar(1,h_chan,'Writing Spectral Data .CSV ... Please Wait.'); end
                    try
                        [status,msg] = NSB_WriteGenericCSV(StatsSheet, fullfile(outputPath, 'NSB_Cerridwen-StatisticalAnalysisTable.csv'),true);
                    catch
                        infostr = {'Warning: NSB_GenerateStatTable >> Cannot write NSB_Cerridwen-StatisticalAnalysisTable.';'Check that the file is not currently open and then press OK'};
                        uiwait(msgbox(infostr,'NSB_GenerateStatTable','warn','modal'));
                        [status,msg] = NSB_WriteGenericCSV(StatsSheet, fullfile(outputPath, 'NSB_Cerridwen-StatisticalAnalysisTable.csv'),true);
                    end
                end
                if size(StatsSheet,2) > oldStatsSheetSize(2) || isnan(oldStatsSheetSize(2))
                    oldStatsSheetSize = size(StatsSheet);  %<< only if bigger?
                end
            elseif ~eegProcessed && ssProcessed
                curSSVec = ssdataLables;
                StatsSheet = [curDateVec,curAnimalVec,curChanLabel,curChanVec,curDoseVec,curEpochVec,curValidVec, curSSVec];
                if size(StatsSheet,2) ~= oldStatsSheetSize(2) && ~any(isnan(oldStatsSheetSize))
                    infostr = ['ERROR: NSB_GenerateStatTable >> Data Table Not Same Size (Skipping): ', fullfile(DataFolderPath,'NSB_Output',SubjectSpectralFileList{SubjectSpectralFileChannelList_IDX(curChan)})];
                    if ~isempty(options.logfile)
                        NSBlog(options.logfile,infostr);
                    else
                        errordlg(infostr,'NSB_GenerateStatTable','replace');
                    end
                    clearvars StatsSheet curDateVec curAnimalVec curChanLabel curChanVec curDoseVec curEpochVec curValidVec curDataMat curSSVec eegdata ssdata BaselineMean;
                    continue;
                    %>>>>>>>>>>>>
                else
                    %Write File
                    if options.progress, waitbar(1,h_chan,'Writing Sleep Scoring  Data .CSV ... Please Wait.'); end
                    try
                        [status,msg] = NSB_WriteGenericCSV(StatsSheet, fullfile(outputPath, 'NSB_Cerridwen-StatisticalAnalysisTable.csv'),true);
                    catch
                        infostr = {'Warning: NSB_GenerateStatTable >> Cannot write NSB_Cerridwen-StatisticalAnalysisTable.';'Check that the file is not currently open and then press OK'};
                        uiwait(msgbox(infostr,'NSB_GenerateStatTable','warn','modal'));
                        [status,msg] = NSB_WriteGenericCSV(StatsSheet, fullfile(outputPath, 'NSB_Cerridwen-StatisticalAnalysisTable.csv'),true);
                    end
                end
                if size(StatsSheet,2) > oldStatsSheetSize(2) || isnan(oldStatsSheetSize(2))
                    oldStatsSheetSize = size(StatsSheet);  %<< only if bigger?
                end
                
            end
            clearvars StatsSheet curDateVec curAnimalVec curChanLabel curChanVec curDoseVec curEpochVec curValidVec curDataMat curSSVec eegdata ssdata BaselineMean;
            
        end %for Channel

    else
        infostr = ['Warning: NSB_GenerateStatTable >> Missing Path: Row #', num2str(curRow),' ...'];
        disp(infostr);
        if ~isempty(options.logfile)
            NSBlog(options.logfile,infostr);
        else
            errordlg(infostr,'NSB_GenerateStatTable','replace');
        end
        
    end
    try, close(h_chan); end
end %for cur Row

%Write RMfile
if options.doRMtable
    Subjects = {RMtable(:).subject}; %could be char or double
    %because this could be either double or char
    for curSubject = 1:length(Subjects)
        if isnumeric(Subjects{curSubject})
            Subjects{curSubject} = num2str(Subjects{curSubject});
        elseif ischar(Subjects{curSubject})
        else
            %error
        end
    end
    uSubjects = unique(Subjects);
    Manip = {RMtable(:).dose};
    uManip = unique(Manip);
    uChannels = unique([RMtable(:).Channel]);
    BlockStart = max([RMtable(:).tsMin]);
    BlockEnd = min([RMtable(:).tsMax]);
    for curChan = 1:length(uChannels)
        Chan_IDX = [RMtable(:).Channel] == uChannels(curChan);
        for curSubject = 1:length(uSubjects)
            Subject_IDX = strcmp(Subjects,uSubjects{curSubject});
            for curManip = 1:length(uManip)
                Manip_IDX = strcmp(Manip,uManip{curManip});
                
                Struct_IDX = find(Chan_IDX & Subject_IDX & Manip_IDX);
                %if Struct_IDX > l << deal with this
                
                %Each Row block is an animal
                
                % Write CSV
                
            end
        end
    end
end

try, close(h); end
%[status,msg] = NSB_WriteGenericCSV(StatsSheet, 'C:\Users\NexStepBiomarkers\Accounts\Maccine\Maccine - Ketamine\MAC001-01_ NSB EEGEngineOutput AnalysisTable For StatisticalPackageImport_temp.csv');
status = true;
warning('on', 'MATLAB:datevec:Inputs');



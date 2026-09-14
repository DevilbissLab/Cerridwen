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
%                           options.fnHasDateID (Logical Default:true) Filename has DateID in field 4 instead of 3(for backwards compatability
%
% Outputs:
%   status              - (logical) return value
%       File saved in StudyDesignPath.
%
%
% Dependencies:
% NSBlog, xlsread/readcell
%
% Important Notes: %This function assumes binning is the same between data types
% "{NSB}_{Filetype}_{RecordingDate(ISO 8601)}_{SubjectID}_{ChannelName}_{ChannelNumber}_{format}.{ext}"
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
% June 19 2025 rewrite to include other analysis types and annotate for readability
%
%To Do deal with multiple channels!
%       handle putative .xml format of design
%       Extract Channel name
%   check to see if you can enter empty values for tiem start and time end
%   also add use z-scores instead of simple ratio
% - >> does not work if selected from menu
% - >> should understand Licences as well.
% - >> three point average - done Apr1 2014
%
% Functional but dependent on spectral analysis for other analyses

%% Parse Inputs and set defaults
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

%% Generate output path for saving file
% Log processing stragety
outputPath = fileparts(StudyDesignPath);

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

%% Write CSV File Header(s)
% Spectral + SleepScoring
SheetHeader = ['Date,Subject,Channel Name,Channel Num,Manipulation,Epoch Num,Valid Epoch,Sleep Scoring,Band 1,Band 2,Band 3,Band 4,Band 5,Ratio 1,Ratio 2,Ratio 3,Ratio 4,Ratio 5'];
SheetHeader = regexp(SheetHeader,'[\w\s\.()]*','match');
try
    [status,msg] = NSB_WriteGenericCSV(SheetHeader, fullfile(outputPath, 'NSB_Cerridwen-StatisticalAnalysisTable.csv'),false);
catch
    infostr = {'Warning: NSB_GenerateStatTable >> Cannot write NSB_Cerridwen-StatisticalAnalysisTable.';'Check that the file is not currently open and then press OK'};
    uiwait(msgbox(infostr,'NSB_GenerateStatTable','warn','modal'));
    [status,msg] = NSB_WriteGenericCSV(SheetHeader, fullfile(outputPath, 'NSB_Cerridwen-StatisticalAnalysisTable.csv'),false);
end
% Sleep/wake calculated summaries
SleepStatsHeader = ['Date,Subject,Channel Name,Channel Num,Manipulation,Total time in sleep cycle period (sec),Sleep Latency (sec),PS Latency (sec),Latency to Wake after Sleep onset (sec),Total Sleep Time (sec),PS Sleep Time (sec),nREM Sleep Time (sec),SWS1 Seep Time (sec),SWS2 Sleep Time (sec),Total Waking Time in sleep cycle period (sec),Quiet Waking Time (sec),Active Waking Time (sec)'];
SleepStatsHeader = regexp(SleepStatsHeader,'[\w\s\.]*','match');
try
    [status,msg] = NSB_WriteGenericCSV(SleepStatsHeader, fullfile(outputPath, 'NSB_Cerridwen-SleepStatisticalAnalysisTable.csv'),false);
catch
    infostr = {'Warning: NSB_GenerateStatTable >> Cannot write NSB_Cerridwen-SleepStatisticalAnalysisTable.';'Check that the file is not currently open and then press OK'};
    uiwait(msgbox(infostr,'NSB_GenerateStatTable','warn','modal'));
    [status,msg] = NSB_WriteGenericCSV(SleepStatsHeader, fullfile(outputPath, 'NSB_Cerridwen-SleepStatisticalAnalysisTable.csv'),false);
end
% Seizure calculated summaries
SeizureStatsHeader = ['Date,Subject,Channel Name,Channel Num,Manipulation,Total Number of Spike Trains,Total Spike Train Duration (min),Percent of Recording,Mean Spike Train Duration (sec),Longest Spike Train Duration (sec),Shortest Spike Train Duration (sec),Mean Number of Spikes/Train'];
SeizureStatsHeader = regexp(SeizureStatsHeader,'[/()\w\s\.]*','match');
try
    [status,msg] = NSB_WriteGenericCSV(SeizureStatsHeader, fullfile(outputPath, 'NSB_Cerridwen-SeizureStatisticalAnalysisTable.csv'),false);
catch
    infostr = {'Warning: NSB_GenerateStatTable >> Cannot write NSB_Cerridwen-SeizureStatisticalAnalysisTable.';'Check that the file is not currently open and then press OK'};
    uiwait(msgbox(infostr,'NSB_GenerateStatTable','warn','modal'));
    [status,msg] = NSB_WriteGenericCSV(SeizureStatsHeader, fullfile(outputPath, 'NSB_Cerridwen-SeizureStatisticalAnalysisTable.csv'),false);
end
% Active Info Storage (AIS) data tables
AISFileHeader = ['Date,Subject,Channel Name,Channel Num,Manipulation,Epoch Num,Valid Epoch,Sleep Scoring,MeanAIS,optimal_k_history,NullMean,NullStd,Nullp'];
AISFileHeader = regexp(AISFileHeader,'[/()\w\s\.]*','match');
try
    [status,msg] = NSB_WriteGenericCSV(AISFileHeader, fullfile(outputPath, 'NSB_Cerridwen-AISStatisticalAnalysisTable.csv'),false);
catch
    infostr = {'Warning: NSB_GenerateStatTable >> Cannot write NSB_Cerridwen-AISStatisticalAnalysisTable.';'Check that the file is not currently open and then press OK'};
    uiwait(msgbox(infostr,'NSB_GenerateStatTable','warn','modal'));
    [status,msg] = NSB_WriteGenericCSV(AISFileHeader, fullfile(outputPath, 'NSB_Cerridwen-AISStatisticalAnalysisTable.csv'),false);
end
% Transfer Entropy (TE) data tables
TEFileHeader = ['Date,Subject,Channel Name,Channel Num,Manipulation,Epoch Num,Valid Epoch,Sleep Scoring,MeanTE,optimal_k_history,NullMean,NullStd,Nullp'];
TEFileHeader = regexp(TEFileHeader,'[/()\w\s\.]*','match');
try
    [status,msg] = NSB_WriteGenericCSV(TEFileHeader, fullfile(outputPath, 'NSB_Cerridwen-TEStatisticalAnalysisTable.csv'),false);
catch
    infostr = {'Warning: NSB_GenerateStatTable >> Cannot write NSB_Cerridwen-TEStatisticalAnalysisTable.';'Check that the file is not currently open and then press OK'};
    uiwait(msgbox(infostr,'NSB_GenerateStatTable','warn','modal'));
    [status,msg] = NSB_WriteGenericCSV(TEFileHeader, fullfile(outputPath, 'NSB_Cerridwen-TEStatisticalAnalysisTable.csv'),false);
end


%% Load Study Design and process row by row
if options.progress, h = waitbar(0,'Loading Study Design .xls'); RowWaitPos = get(h,'Position'); end

try
    [~,~,StudyDesign] = xlsread(StudyDesignPath); %'~' does not work in earlier matlab versions (2010 ?)
    infostr = ['Info: NSB_GenerateStatTable >> Using "xlsread" to load StudyDesignPath'];
catch
    %Introduced in MATLAB in R2019a
    %generates correct dates from excel, but uses <missing> instead of NaN
    StudyDesign = readcell(StudyDesignPath); %used for Matlab 2025+ with newer excel versions.
    infostr = ['Warning: NSB_GenerateStatTable >> Using "readcell" to load StudyDesignPath'];
end
disp(infostr);
if ~isempty(options.logfile)
    NSBlog(options.logfile,infostr);
end

% Setup Variables
StatsSheet = cell(0);
oldStatsSheetSize.Spectral = [NaN, NaN];
oldStatsSheetSize.AIS = [NaN, NaN];
oldStatsSheetSize.TE = [NaN, NaN];
oldStatsSheetSize.Sleep = [NaN, NaN];
RMtableCNTR = 1;
RMtable = [];
DesignLength = size(StudyDesign,1);

% Get Study Design Column Indexes
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

% Loop through each row of Study Design
for curRow = 2:DesignLength
    disp(['Processing Row #', num2str(curRow),' ...']);

    % Reset each Study Row. This may need to be cleared for each channel.
    DataStatus = resetDataStatus();

    try
        if options.progress, waitbar((curRow-1)/(DesignLength-1),h,['Processing Entry ',num2str(curRow-1),' ...']); end
    catch
        % if progress bar deleted
        errorstr = ['ERROR: NSB_GenerateStatTable >> Progress Terminated. Abort writing Statistical Table.'];
        if ~isempty(options.logfile)
            status = NSBlog(options.logfile,errorstr);
        else
            errordlg(errorstr,'NSB_GenerateStatTable','replace');
        end
        return;
    end

    if isnan(StudyDesign{curRow,PathCol})
        infostr = ['Warning: NSB_GenerateStatTable >> Missing Path: Row #', num2str(curRow),' ...'];
        disp(infostr);
        if ~isempty(options.logfile)
            NSBlog(options.logfile,infostr);
        else
            errordlg(infostr,'NSB_GenerateStatTable','replace');
        end
        continue; % skip to next row of StudyDesign
    else
        % Process StudyDesign row
        % Address the fact that "File Path can be a file or path and data dir is in path"
        FilePath = StudyDesign{curRow,PathCol};
        errorstr = ['Information: NSB_GenerateStatTable >> Processing row entry #',num2str(curRow),' Data file: ',FilePath];
        if ~isempty(options.logfile)
            status = NSBlog(options.logfile,errorstr);
        else
            disp(errorstr);
        end

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

        % Test for output Dir from analyses (containing processed data)
        % If not continue/skip to next StudyDesign row.
        if exist(fullfile(DataFolderPath,'NSB_Output')) == 0
            errorstr = ['Warning: NSB_GenerateStatTable >> NSB_Output folder not found in ',DataFolderPath];
            disp(errorstr);
            if ~isempty(options.logfile)
                status = NSBlog(options.logfile,errorstr);
            else
                errordlg(errorstr,'NSB_GenerateStatTable','replace');
            end
            continue; % skip to next row of StudyDesign
        end

        % %%%%%%%%%%%%%%%%%%%%
        % Get index for each file type in NSB_Output Direcrtory
        % %%%%%%%%%%%%%%%%%%%%
        FileList = fuf(fullfile(DataFolderPath,'NSB_Output'),0); %<< only filenames
        SpectralData_IDX = ~cellfun(@isempty, strfind(FileList, 'SpectralData.csv'));
        SomnoData_IDX = ~cellfun(@isempty, strfind(FileList, 'SomnogramData.csv'));
        SleepStats_IDX = ~cellfun(@isempty, strfind(FileList, 'SleepStatistics.csv'));
        SeizureStats_IDX = ~cellfun(@isempty, strfind(FileList, 'SeizureDataSummary.csv'));
        AISFile_IDX = ~cellfun(@isempty, strfind(FileList, 'AISData.csv'));
        TEFile_IDX = ~cellfun(@isempty, strfind(FileList, 'TEData.csv'));

        % %%%%%%%%%%%%%%%%%%%%
        % Get File names for each file type in NSB_Output Direcrtory
        % %%%%%%%%%%%%%%%%%%%%
        SpectralFileList = FileList(SpectralData_IDX); % <File List
        SomnoFileList = FileList(SomnoData_IDX);
        SleepStatsList = FileList(SleepStats_IDX);
        SeizureStatsList = FileList(SeizureStats_IDX);
        AISFileList = FileList(AISFile_IDX);
        TEFileList = FileList(TEFile_IDX);

        % %%%%%%%%%%%%%%%%%%%%
        % Get subsets of each file type in NSB_Output Direcrtory that was
        % recorded on the specified DATE in Study Design
        % %%%%%%%%%%%%%%%%%%%%
        curSplitField = 3;
        if options.fnHasDateID
            DateID = StudyDesign{curRow,DateCol}; %Can be number or string
            if ischar(DateID)
                try
                    DateID = datestr(datenum(DateID),29); %force into this format
                    StudyDesign{curRow,DateCol} = datestr(DateID,29);
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
                if 1 < year(DateID) && year(DateID) < 1900
                    %badly formed excel date
                    DateID = datetime(DateID,'ConvertFrom','excel');
                    StudyDesign{curRow,DateCol} = datestr(DateID,29);
                end
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
            AISFileList_split = regexp(AISFileList,'_','split');
            AISFileList_IDX = false(length(AISFileList),1);
            for curfile = 1:length(AISFileList)
                if ~isempty(strfind(AISFileList_split{curfile}{curSplitField}, DateID))
                    AISFileList_IDX(curfile) = true;
                end
            end
            TEFileList_split = regexp(TEFileList,'_','split');
            TEFileList_IDX = false(length(TEFileList),1);
            for curfile = 1:length(TEFileList)
                if ~isempty(strfind(TEFileList_split{curfile}{curSplitField}, DateID))
                    TEFileList_IDX(curfile) = true;
                end
            end

            SpectralFileList = SpectralFileList(SpectralData_IDX); % <File List conditions on DateID
            SomnoFileList = SomnoFileList(SomnoData_IDX);
            SleepStatsList = SleepStatsList(SleepStatsList_IDX);
            SeizureStatsList = SeizureStatsList(SeizureStatsList_IDX);
            AISFileList = AISFileList(AISFileList_IDX);
            TEFileList = TEFileList(TEFileList_IDX);
            curSplitField = curSplitField +1;
        end

        % %%%%%%%%%%%%%%%%%%%%
        % Get a further subset of each file type in NSB_Output Direcrtory
        % that matches the SubjectID in Study Design
        % %%%%%%%%%%%%%%%%%%%%
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
        AISFileList_split = regexp(AISFileList,'_','split');
        SubjectAISFileList_IDX = false(length(AISFileList),1);
        for curfile = 1:length(AISFileList)
            if strcmp(AISFileList_split{curfile}{curSplitField}, SubjectID)  %<<<<<<<<<  Hardcoded to new Specifications
                SubjectAISFileList_IDX(curfile) = true;
            end
        end
        TEFileList_split = regexp(TEFileList,'_','split');
        SubjectTEFileList_IDX = false(length(TEFileList),1);
        for curfile = 1:length(TEFileList)
            if strcmp(TEFileList_split{curfile}{curSplitField}, SubjectID)  %<<<<<<<<<  Hardcoded to new Specifications
                SubjectTEFileList_IDX(curfile) = true;
            end
        end
        SubjectSpectralFileList = SpectralFileList(SubjectSpectralData_IDX); % <File List conditions on SubjectID
        SubjectSomnoFileList = SomnoFileList(SubjectSomnoData_IDX);
        SubjectSleepStatsList = SleepStatsList(SubjectSleepStatsList_IDX);
        SubjectSeizureStatsList = SeizureStatsList(SubjectSeizureStatsList_IDX);
        SubjectAISFileList = AISFileList(SubjectAISFileList_IDX);
        SubjectTEFileList = TEFileList(SubjectTEFileList_IDX);

        % %%%%%%%%%%%%%%%%%%%%
        % There can be more that 1 channel in a recording
        % Get channel lists of each file type in NSB_Output Direcrtory
        % %%%%%%%%%%%%%%%%%%%%
        %
        % check for multiple channels << Spectral only
        SubjectSpectralFileChannelList = [];
        SubjectSpectralFileChannelName = cell(0);
        SpectralFileList_split = regexp(SubjectSpectralFileList,'_','split');
        for curfile = 1:length(SubjectSpectralFileList)
            SubjectSpectralFileChannelList = [SubjectSpectralFileChannelList; str2double(SpectralFileList_split{curfile}{end-1})];
            SubjectSpectralFileChannelName{curfile} = SpectralFileList_split{curfile}{end-2};
        end
        [SubjectSpectralFileChannelList_sort, SubjectSpectralFileChannelList_IDX] = sort(SubjectSpectralFileChannelList);

        % check for multiple channels << Seizure only
        SubjectSeizureStatsChannelList = [];
        SubjectSeizureStatsChannelName = cell(0);
        SeizureFileList_split = regexp(SubjectSeizureStatsList,'_','split');
        for curfile = 1:length(SubjectSeizureStatsList)
            SubjectSeizureStatsChannelList = [SubjectSeizureStatsChannelList; str2double(SeizureFileList_split{curfile}{end-1})];
            SubjectSeizureStatsChannelName{curfile} = SeizureFileList_split{curfile}{end-2};
        end
        [SubjectSeizureFileChannelList_sort, SubjectSeizureFileChannelList_IDX] = sort(SubjectSeizureStatsChannelList);

        % check for multiple channels << AIS only
        SubjectAISFileChannelList = [];
        SubjectAISFileChannelName = cell(0);
        AISFileList_split = regexp(SubjectAISFileList,'_','split');
        for curfile = 1:length(SubjectAISFileList)
            SubjectAISFileChannelList = [SubjectAISFileChannelList; str2double(AISFileList_split{curfile}{end-1})];
            SubjectAISFileChannelName{curfile} = AISFileList_split{curfile}{end-2};
        end
        [SubjectAISFileChannelList_sort, SubjectAISFileChannelList_IDX] = sort(SubjectAISFileChannelList);

        % check for multiple channels << TE only
        SubjectTEFileChannelList = [];
        SubjectTEFileChannelName = cell(0);
        TEFileList_split = regexp(SubjectTEFileList,'_','split');
        for curfile = 1:length(SubjectTEFileList)
            SubjectTEFileChannelList = [SubjectTEFileChannelList; str2double(TEFileList_split{curfile}{end-1})];
            SubjectTEFileChannelName{curfile} = TEFileList_split{curfile}{end-2};
        end
        [SubjectTEFileChannelList_sort, SubjectTEFileChannelList_IDX] = sort(SubjectTEFileChannelList);

        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % %%%%%%%%%%%%%%%%%%%%%%%%
        % For each row of the Study Design process each channel
        % %%%%%%%%%%%%%%%%%%%%%%%%
        if options.progress, h_chan = waitbar(0,'Processing Channel ...','Position',[RowWaitPos(1) RowWaitPos(2)-RowWaitPos(4) RowWaitPos(3:4)]); end
        totalChans = max( [length(SubjectSpectralFileChannelList), length(SubjectSeizureStatsChannelList), ...
            length(SubjectAISFileChannelList), length(SubjectTEFileChannelList), ...
            length(SubjectSomnoFileList) ]);
        %original -> totalChans = max(length(SubjectSpectralFileChannelList), length(SubjectSeizureStatsChannelList));
        %then ->     totalChans = max(max(length(SubjectSpectralFileChannelList), length(SubjectSeizureStatsChannelList)), length(SubjectSomnoFileList));

        for curChan = 1:totalChans
            disp(['     Processing Channel #',num2str(curChan)]);

            % Reset Status of all loaded data
            DataStatus = resetDataStatus();
            % NOTE if missing a channel this loop will fail poorly.
            %test for channel in Study design <<<<<<<<<<<<<<<This assumes that there is always a spectral channel!!!!

            % %%%%%%%%%%%%%%%%%%%%%%%%
            % DataChannelCol are the IDX of the specified Channels to
            % analyze in Study Design. If you are identifying channels to
            % analyze, make sure they exist.
            % %%%%%%%%%%%%%%%%%%%%%%%%
            if ~isempty(DataChannelCol) %<< columns exist in the DataSheet
                try
                    % Determine whether StudyDesign has indicated to analyze specific channels
                    % Build a logical vec of whether cells are NaN or not
                    for n = 1:length(DataChannelCol), IDX(n)=any(isnan(StudyDesign{curRow,DataChannelCol(n)})); end

                    %this is wrong but working.
                    % To fix -  make sure channel number matches recorded channel
                    % Make sure user did not leave all empty columns << process all

                    if ~all(IDX)
                        % If there is at least (1) channel name/number identified to be analyzed ...
                        if ~ismember(SubjectSpectralFileChannelList_sort(SubjectSpectralFileChannelList_IDX(curChan)), [StudyDesign{curRow,DataChannelCol}]) && ...
                                ~any(strcmp(SubjectSpectralFileChannelName(SubjectSpectralFileChannelList_IDX(curChan)), {StudyDesign{curRow,DataChannelCol}}))
                            % If the current channel number is NOT in the DataSheet AND the channel name is NOT indicated in StudyDesign.
                            % continue/skip to next channel.
                            infostr = ['Information: NSB_GenerateStatTable >> Channel #',num2str(SubjectSpectralFileChannelList_IDX(curChan)),' not present in Study Design. Skipping Channel.'];
                            if ~isempty(options.logfile)
                                NSBlog(options.logfile,infostr);
                            else
                                errordlg(infostr,'NSB_GenerateStatTable','replace');
                            end
                            continue;
                        end
                    end
                    clearvars IDX n
                catch
                    infostr = ['Information: NSB_GenerateStatTable >> Channel #',num2str(curChan),' not present in file list. Skipping Channel.'];
                    if ~isempty(options.logfile)
                        NSBlog(options.logfile,infostr);
                    else
                        errordlg(infostr,'NSB_GenerateStatTable','replace');
                    end
                end
            end

            %test for multiple spectral files recorded for same subject on same day.
            try
                if sum( SubjectSpectralFileChannelList == str2double(SpectralFileList_split{SubjectSpectralFileChannelList_IDX(curChan)}{end-1}) ) > 1
                    %Id Current file of multiple Files
                    curChannelName = SpectralFileList_split{SubjectSpectralFileChannelList_IDX(curChan)}{4}; %<<<<<<<<<<<  HardCoded Current File name Spec.
                end
            end

            % ^^^^^^^ The above is really unclear why we are doing this ^^^^
            %% Process each Output file from Cerridwen
            if options.progress, waitbar((curChan)/totalChans,h_chan,['Processing Channel ',num2str(curChan),' ...']); end

            % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Determine whether Dosing time is specified and whether it is a date + time or just time
            % Format Dosing time as datenumber
            % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
                else %date and time or NaN (no dosing)
                    DoseTime = StudyDesign{curRow,DoseTimeCol};
                end
            else
                DoseTime = NaN;
                infostr = ['Warning: NSB_GenerateStatTable >> No "Dosing Time" column found in Study Design Spreadsheet. '];
                disp(infostr);
                if ~isempty(options.logfile)
                    NSBlog(options.logfile,infostr);
                else
                    errordlg(infostr,'NSB_GenerateStatTable','replace');
                end
            end
            if exist('DoseTime','var') == 0
                DoseTime = NaN;
            end

            % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Load Spectral Power Data
            % Create - DataStatus.Spectral.Data
            % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %Read/Process EEG Data File sorted by channel Number !
            if ~isempty(SubjectSpectralFileChannelList_IDX)
                try
                    [~,~,DataStatus.Spectral.Data] = xlsread(fullfile(DataFolderPath,'NSB_Output',SubjectSpectralFileList{SubjectSpectralFileChannelList_IDX(curChan)}));
                    infostr = ['Info: NSB_GenerateStatTable >> Using "xlsread" to load Spectral.Data'];
                catch
                    DataStatus.Spectral.Data = readcell(fullfile(DataFolderPath,'NSB_Output',SubjectSpectralFileList{SubjectSpectralFileChannelList_IDX(curChan)}));
                    infostr = ['Warning: NSB_GenerateStatTable >> Using "readcell" to load Spectral.Data'];
                end
                disp(infostr);
                if ~isempty(options.logfile)
                    NSBlog(options.logfile,infostr);
                end
                if isempty(DataStatus.Spectral.Data)
                    infostr = ['ERROR: NSB_GenerateStatTable >> No Data in File: ', fullfile(DataFolderPath,'NSB_Output',SubjectSpectralFileList{SubjectSpectralFileChannelList_IDX(curChan)}), 'Skipping Channel.'];
                    if ~isempty(options.logfile)
                        NSBlog(options.logfile,infostr);
                    else
                        errordlg(infostr,'NSB_GenerateStatTable','replace');
                    end
                else
                    % cleanup data matrix
                    IDX = cellfun(@(x) ischar(x) && strcmp(strtrim(x),'NaN') ,DataStatus.Spectral.Data); % Find non-numeric cells
                    DataStatus.Spectral.Data(IDX) = {NaN}; % Replace non-numeric cells
                    DataStatus.Spectral.Data = cell2mat(DataStatus.Spectral.Data(2:end,:));
                    DataStatus.Spectral.Loaded = true;
                end
            else
                infostr = ['ERROR: NSB_GenerateStatTable >> Spectral Data Not Loaded '];
                if ~isempty(options.logfile)
                    NSBlog(options.logfile,infostr);
                else
                    errordlg(infostr,'NSB_GenerateStatTable','replace');
                end
            end

            % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Load Active Information Storage Data
            % Create - DataStatus.AIS.Data
            % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %Read/Process AIS Data File
            if ~isempty(SubjectAISFileChannelList_IDX)
                if length(SubjectAISFileChannelList_IDX) >= curChan
                    try
                        [~,~,DataStatus.AIS.Data] = xlsread(fullfile(DataFolderPath,'NSB_Output',SubjectAISFileList{SubjectAISFileChannelList_IDX(curChan)}));
                        infostr = ['Info: NSB_GenerateStatTable >> Using "xlsread" to load AIS.Data'];
                    catch
                        DataStatus.AIS.Data = readcell(fullfile(DataFolderPath,'NSB_Output',SubjectAISFileList{SubjectAISFileChannelList_IDX(curChan)}));
                        infostr = ['Warning: NSB_GenerateStatTable >> Using "readcell" to load AIS.Data'];
                    end
                    disp(infostr);
                    if ~isempty(options.logfile)
                        NSBlog(options.logfile,infostr);
                    end
                    if isempty(DataStatus.AIS.Data)
                        infostr = ['ERROR: NSB_GenerateStatTable >> No Data in File: ', fullfile(DataFolderPath,'NSB_Output',SubjectAISFileList{SubjectAISFileChannelList_IDX(curChan)}), 'Skipping Channel.'];
                        if ~isempty(options.logfile)
                            NSBlog(options.logfile,infostr);
                        else
                            errordlg(infostr,'NSB_GenerateStatTable','replace');
                        end
                    else
                        % cleanup data matrix
                        IDX = cellfun(@(x) ischar(x) && strcmp(strtrim(x),'NaN') ,DataStatus.AIS.Data); % Find non-numeric cells
                        DataStatus.AIS.Data(IDX) = {NaN}; % Replace non-numeric cells
                        DataStatus.AIS.Data = cell2mat(DataStatus.AIS.Data(2:end,:));
                        DataStatus.AIS.Loaded = true;
                    end
                else
                    infostr = ['Warning: NSB_GenerateStatTable >> AIS Data Not Loaded '];
                    if ~isempty(options.logfile)
                        NSBlog(options.logfile,infostr);
                    else
                        errordlg(infostr,'NSB_GenerateStatTable','replace');
                    end
                end
            else
                infostr = ['Warning: NSB_GenerateStatTable >> AIS Data Not Loaded '];
                if ~isempty(options.logfile)
                    NSBlog(options.logfile,infostr);
                else
                    errordlg(infostr,'NSB_GenerateStatTable','replace');
                end
            end

            % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Load Transfer Entropy Data
            % Create - DataStatus.TE.Data
            % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %Read/Process TE Data File
            %TE will not have the same number of channels Therefore, make
            %  the index empty to ignore processing
            if curChan > length(SubjectTEFileChannelList_IDX)
                SubjectTEFileChannelList_IDX = [];
            end
            if ~isempty(SubjectTEFileChannelList_IDX)
                try
                    [~,~,DataStatus.TE.Data] = xlsread(fullfile(DataFolderPath,'NSB_Output',SubjectTEFileList{SubjectTEFileChannelList_IDX(curChan)}));
                    infostr = ['Info: NSB_GenerateStatTable >> Using "xlsread" to load StudyDesignPath'];
                catch
                    DataStatus.TE.Data = readcell(fullfile(DataFolderPath,'NSB_Output',SubjectTEFileList{SubjectTEFileChannelList_IDX(curChan)}));
                    infostr = ['Warning: NSB_GenerateStatTable >> Using "readcell" to load StudyDesignPath'];
                end
                disp(infostr);
                if ~isempty(options.logfile)
                    NSBlog(options.logfile,infostr);
                end
                if isempty(DataStatus.TE.Data)
                    infostr = ['Warning: NSB_GenerateStatTable >> No Data in File: ', fullfile(DataFolderPath,'NSB_Output',SubjectAISFileList{SubjectAISFileChannelList_IDX(curChan)}), 'Skipping Channel.'];
                    if ~isempty(options.logfile)
                        NSBlog(options.logfile,infostr);
                    else
                        errordlg(infostr,'NSB_GenerateStatTable','replace');
                    end
                else
                    % cleanup data matrix
                    IDX = cellfun(@(x) ischar(x) && strcmp(strtrim(x),'NaN') ,DataStatus.TE.Data); % Find non-numeric cells
                    DataStatus.TE.Data(IDX) = {NaN}; % Replace non-numeric cells
                    DataStatus.TE.Data = cell2mat(DataStatus.TE.Data(2:end,:));
                    DataStatus.TE.Loaded = true;
                end
            else
                infostr = ['Warning: NSB_GenerateStatTable >> TE Data Not Loaded '];
                if ~isempty(options.logfile)
                    NSBlog(options.logfile,infostr);
                else
                    errordlg(infostr,'NSB_GenerateStatTable','replace');
                end
            end

            % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Load Sleep Scoring Data
            % Create - DataStatus.Sleep.Data
            % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
                    %Try to use the current channel
                    SubjectSomnoFileChannelList_IDX = curChan;
                end

                %Read/Process SleepScoring Data File
                %SleepScoring may/will not have the same number of channels Therefore, make
                %  the index empty to ignore processing << is this always 1 value??
                % if curChan > SubjectSomnoFileChannelList_IDX
                %     SubjectSomnoFileChannelList_IDX = [];
                % end

                if length(SubjectSomnoFileList) >= SubjectSomnoFileChannelList_IDX

                    try
                        [~,~,DataStatus.Sleep.Data] = xlsread(fullfile(DataFolderPath,'NSB_Output',SubjectSomnoFileList{SubjectSomnoFileChannelList_IDX}));
                        infostr = ['Info: NSB_GenerateStatTable >> Using "xlsread" to load Sleep.Data'];
                    catch
                        DataStatus.Sleep.Data = readcell(fullfile(DataFolderPath,'NSB_Output',SubjectSomnoFileList{SubjectSomnoFileChannelList_IDX}));
                        infostr = ['Warning: NSB_GenerateStatTable >> Using "readcell" to load Sleep.Data'];
                    end
                    disp(infostr);
                    if ~isempty(options.logfile)
                        NSBlog(options.logfile,infostr);
                    end
                    DataStatus.Sleep.DataLabels = DataStatus.Sleep.Data(2:end,5);
                    DataStatus.Sleep.Data = cell2mat(DataStatus.Sleep.Data(2:end,1:4));% << HardCoded
                    DataStatus.Sleep.Loaded = true;
                else
                    if curChan <= length(SubjectSomnoFileChannelList)
                        infostr = ['ERROR: NSB_GenerateStatTable >> Data Not Loaded: ',fullfile(DataFolderPath,'NSB_Output',SubjectSomnoFileList{SubjectSomnoFileChannelList_IDX})];
                    else
                        infostr = ['ERROR: NSB_GenerateStatTable >> Data Not Loaded - Nex Data File Does Not Exist'];
                    end
                    disp(infostr);
                    if ~isempty(options.logfile)
                        NSBlog(options.logfile,infostr);
                    else
                        errordlg(infostr,'NSB_GenerateStatTable','replace');
                    end
                end
            else
                if curChan <= length(SubjectSomnoFileChannelList)
                    infostr = ['ERROR: NSB_GenerateStatTable >> Data Not Loaded: ',fullfile(DataFolderPath,'NSB_Output',SubjectSomnoFileList{SubjectSomnoFileChannelList_IDX})];
                else
                    infostr = ['ERROR: NSB_GenerateStatTable >> Data Not Loaded - Nex Data File Does Not Exist'];
                end
                disp(infostr);
                if ~isempty(options.logfile)
                    NSBlog(options.logfile,infostr);
                else
                    errordlg(infostr,'NSB_GenerateStatTable','replace');
                end
            end

            if all([isempty(DataStatus.Spectral.Data), isempty(DataStatus.AIS.Data), isempty(DataStatus.TE.Data), isempty(DataStatus.Sleep.Data)])
                infostr = ['ERROR: NSB_GenerateStatTable >> No Data Loaded. Skipping channel: ',num2str(curChan)];
                if ~isempty(options.logfile)
                    disp(errorstr);
                    NSBlog(options.logfile,infostr);
                else
                    errordlg(infostr,'NSB_GenerateStatTable','replace');
                end
                continue;
            end

            % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % If there is a Dosing time Specified - Find the Pivot/Anchor row
            % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Find Pivot Row << the Row that is the new Relative time zero (i.e. dosing time)
            % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if ~isnan(DoseTime)
                % if ~isempty(DataStatus.Spectral.Data)
                if DataStatus.Spectral.Loaded
                    DataStatus.Spectral.PivotRow = find(DataStatus.Spectral.Data(:,3) >= DoseTime, 1 ,'first'); %EEG Spreadsheet, date num is col 3
                    DataStatus.Spectral.PivotEpoch = DataStatus.Spectral.Data(DataStatus.Spectral.PivotRow,4); % EEG Spreadsheet, seconds is col 4
                    
                    if DataStatus.Spectral.PivotRow > 1
                        % Recalculate Timebase
                        DataStatus.Spectral.Data(:,4) = DataStatus.Spectral.Data(:,4) - DataStatus.Spectral.PivotEpoch;
                        infostr = ['Info: NSB_GenerateStatTable >> "Dosing Time" found for Spectral Spreadsheet. '];
                        disp(infostr);
                        if ~isempty(options.logfile)
                            NSBlog(options.logfile,infostr);
                        end
                    else
                        % There is no baseline data
                        DoseTime = NaN; % Reset DoseTime since there is no baseline data.
                        infostr = ['Info: NSB_GenerateStatTable >> No Baseline data found for Spectral Spreadsheet. '];
                        disp(infostr);
                        if ~isempty(options.logfile)
                            NSBlog(options.logfile,infostr);
                        else
                            errordlg(infostr,'NSB_GenerateStatTable','replace');
                        end
                    end
                    disp('... EEG Spreadsheet Processed.');
                    % Processed = PivotEpoch not empty
                else
                    % No Spectral data loaded
                    infostr = ['Warning: NSB_GenerateStatTable >> No "Dosing Time" found for EEG Spreadsheet. '];
                    if ~isempty(options.logfile)
                        NSBlog(options.logfile,infostr);
                    else
                        errordlg(infostr,'NSB_GenerateStatTable','replace');
                    end
                end

                %if ~isempty(DataStatus.AIS.Data)
                if DataStatus.AIS.Loaded
                    DataStatus.AIS.PivotRow = find(DataStatus.AIS.Data(:,3) >= DoseTime, 1 ,'first'); %AIS Spreadsheet, date num is col 3
                    DataStatus.AIS.PivotEpoch = DataStatus.AIS.Data(DataStatus.AIS.PivotRow,4); % AIS Spreadsheet, seconds is col 4
                    
                    if DataStatus.AIS.PivotRow > 1
                        % Recalculate Timebase
                        DataStatus.AIS.Data(:,4) = DataStatus.AIS.Data(:,4) - DataStatus.AIS.PivotEpoch;
                        infostr = ['Info: NSB_GenerateStatTable >> "Dosing Time" found for AIS Spreadsheet. '];
                        disp(infostr);
                        if ~isempty(options.logfile)
                            NSBlog(options.logfile,infostr);
                        end
                    else
                        % There is no baseline data
                        DoseTime = NaN; % Reset DoseTime since there is no baseline data.
                        infostr = ['Info: NSB_GenerateStatTable >> No Baseline data found for AIS Spreadsheet. '];
                        disp(infostr);
                        if ~isempty(options.logfile)
                            NSBlog(options.logfile,infostr);
                        else
                            errordlg(infostr,'NSB_GenerateStatTable','replace');
                        end
                    end
                    disp('... AIS Spreadsheet Processed.');
                    % Processed = PivotEpoch not empty
                else
                    % No AIS data loaded
                    infostr = ['Warning: NSB_GenerateStatTable >> No "Dosing Time" found for AIS Spreadsheet. '];
                    if ~isempty(options.logfile)
                        NSBlog(options.logfile,infostr);
                    else
                        errordlg(infostr,'NSB_GenerateStatTable','replace');
                    end
                end

                %if ~isempty(DataStatus.TE.Data)
                if DataStatus.TE.Loaded
                    DataStatus.TE.PivotRow = find(DataStatus.TE.Data(:,3) >= DoseTime, 1 ,'first'); %AIS Spread sheet, date num is col 3
                    DataStatus.TE.PivotEpoch = DataStatus.TE.Data(DataStatus.TE.PivotRow,4); % %AIS Spread sheet, seconds is col 4
                    
                    if DataStatus.TE.PivotRow > 1
                        % Recalculate Timebase
                        DataStatus.TE.Data(:,4) = DataStatus.TE.Data(:,4) - DataStatus.TE.PivotEpoch;
                        infostr = ['Info: NSB_GenerateStatTable >> "Dosing Time" found for TE Spreadsheet. '];
                        disp(infostr);
                        if ~isempty(options.logfile)
                            NSBlog(options.logfile,infostr);
                        end
                    else
                        % There is no baseline data
                        DoseTime = NaN; % Reset DoseTime since there is no baseline data.
                        infostr = ['Info: NSB_GenerateStatTable >> No Baseline data found for TE Spreadsheet. '];
                        disp(infostr);
                        if ~isempty(options.logfile)
                            NSBlog(options.logfile,infostr);
                        else
                            errordlg(infostr,'NSB_GenerateStatTable','replace');
                        end
                    end
                    disp('... TE Spreadsheet Processed.');
                    % Processed = PivotEpoch not empty
                else
                    % No TE data loaded
                    infostr = ['Warning: NSB_GenerateStatTable >> No "Dosing Time" found for TE Spreadsheet. '];
                    if ~isempty(options.logfile)
                        NSBlog(options.logfile,infostr);
                    else
                        errordlg(infostr,'NSB_GenerateStatTable','replace');
                    end
                end

                %if ~isempty(DataStatus.Sleep.Data)
                if DataStatus.Sleep.Loaded
                    DataStatus.Sleep.PivotRow = find(DataStatus.Sleep.Data(:,2) >= DoseTime, 1 ,'first'); %Hypnogram Spread sheet, date num is col 3 (no Valid Marker)
                    DataStatus.Sleep.PivotEpoch = DataStatus.Sleep.Data(DataStatus.Sleep.PivotRow,3);                    
                    
                    if DataStatus.Sleep.PivotRow > 1
                        % Recalculate Timebase
                        DataStatus.Sleep.Data(:,3) = DataStatus.Sleep.Data(:,3) - DataStatus.Sleep.PivotEpoch;
                        infostr = ['Info: NSB_GenerateStatTable >> "Dosing Time" found for Sleep Scoring Spreadsheet. '];
                        disp(infostr);
                        if ~isempty(options.logfile)
                            NSBlog(options.logfile,infostr);
                        end
                    else
                        % There is no baseline data
                        DoseTime = NaN; % Reset DoseTime since there is no baseline data.
                        infostr = ['Info: NSB_GenerateStatTable >> No Baseline data found for Sleep Scoring Spreadsheet. '];
                        disp(infostr);
                        if ~isempty(options.logfile)
                            NSBlog(options.logfile,infostr);
                        else
                            errordlg(infostr,'NSB_GenerateStatTable','replace');
                        end
                    end
                    disp('... Somnogram Spreadsheet Processed.');
                    % Processed = PivotEpoch not empty
                else
                    % No Sleep data loaded
                    infostr = ['Warning: NSB_GenerateStatTable >> No "Dosing Time" found for Somnogram Spreadsheet. '];
                    if ~isempty(options.logfile)
                        NSBlog(options.logfile,infostr);
                    else
                        errordlg(infostr,'NSB_GenerateStatTable','replace');
                    end
                end
            else
                infostr = ['Warning: NSB_GenerateStatTable >> No "Dosing Time" found for Spectral/AIS/TE Spreadsheet. '];
                disp(infostr);
                if ~isempty(options.logfile)
                    NSBlog(options.logfile,infostr);
                else
                    errordlg(infostr,'NSB_GenerateStatTable','replace');
                end
            end % ~isnan(DoseTime)

            % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Process Spectral Power Data
            % DataStatus.Spectral.Data
            % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % If requested, Calculate NaNmean spectral power during Baseline
            % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if options.doMeanBaseline
                if ~isempty(BaselineMeanTimeStart) && ~isempty(BaselineMeanTimeEnd)
                    BaselineMeanTimeStartRow = find(DataStatus.Spectral.Data(:,4) <= BaselineMeanTimeStart, 1 ,'last');
                    BaselineMeanTimeEndRow = find(DataStatus.Spectral.Data(:,4) >= BaselineMeanTimeEnd, 1 ,'first');
                    BaselineMean = nanmean(DataStatus.Spectral.Data(BaselineMeanTimeEndRow:BaselineMeanTimeStartRow,5:end),1);
                elseif ~isempty(BaselineMeanTimeStart) && isempty(BaselineMeanTimeEnd)
                    BaselineMeanTimeStartRow = find(DataStatus.Spectral.Data(:,4) <= BaselineMeanTimeStart, 1 ,'last');
                    BaselineMean = nanmean(DataStatus.Spectral.Data(1:BaselineMeanTimeStartRow,5:end),1);
                else
                    BaselineMean = nanmean(DataStatus.Spectral.Data(1:DataStatus.Spectral.PivotRow,5:end),1);
                end
                if ~isnan(DoseTime)
                    DataStatus.Spectral.Data(:,5:end) =  DataStatus.Spectral.Data(:,5:end)./repmat(BaselineMean,size(DataStatus.Spectral.Data,1),1);
                    disp('... Spectral Spreadsheet Processed: doMeanBaseline.');
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

            % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % If requested, Smooth spectral power with a Boxcar sliding window
            % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if options.MovAve.do
                DataStatus.Spectral.Data(:,5:end) = NSB_boxcarSmooth(DataStatus.Spectral.Data(:,5:end),options.MovAve.window);
                disp('... Spectral Spreadsheet Processed: MovAve.do.');
            end

            % %%%%%%%%%%%%%%%%%%%%
            % Make sure the length of Sleep Scoring and Spectral Data are
            % the same size and aligned at the Pivot Row
            % %%%%%%%%%%%%%%%%%%%%
            % One Issue found is when the sleep and spectral are processed at different
            % binnings

            if DataStatus.Sleep.Loaded && DataStatus.Spectral.Loaded
                %Error check for differences in size and pivot row
                %check for Pivot row (Predose length)
                if ~isempty(DataStatus.Sleep.PivotRow) && ~isempty(DataStatus.Spectral.PivotRow)
                    if DataStatus.Sleep.PivotRow > DataStatus.Spectral.PivotRow
                        DataStatus.Sleep.DataLabels(1:DataStatus.Sleep.PivotRow-DataStatus.Spectral.PivotRow) = [];
                        DataStatus.Sleep.Data(1:DataStatus.Sleep.PivotRow-DataStatus.Spectral.PivotRow,:) = [];
                        DataStatus.Sleep.PivotRow = DataStatus.Sleep.PivotRow-(DataStatus.Sleep.PivotRow-DataStatus.Spectral.PivotRow);
                        disp('Sleep >> Repairing difference in Dose Pivot Rows (SleepScore > EEG)');
                    elseif DataStatus.Spectral.PivotRow > DataStatus.Sleep.PivotRow
                        DataStatus.Spectral.Data(1:DataStatus.Spectral.PivotRow-DataStatus.Sleep.PivotRow,:) = [];
                        DataStatus.Spectral.PivotRow = DataStatus.Spectral.PivotRow-(DataStatus.Spectral.PivotRow-DataStatus.Sleep.PivotRow);
                        disp('Spectral >> Repairing difference in Dose Pivot Rows (EEG > SleepScore)');
                    end
                end
                %check for size (Postdose length)
                if size(DataStatus.Sleep.Data,1) > size(DataStatus.Spectral.Data,1)
                    DataStatus.Sleep.DataLabels = DataStatus.Sleep.DataLabels(1:size(DataStatus.Spectral.Data,1),:);
                    DataStatus.Sleep.Data = DataStatus.Sleep.Data(1:size(DataStatus.Spectral.Data,1),:);
                    disp('Sleep >> Repairing difference in Table Size (SleepScore > EEG)');
                elseif size(DataStatus.Sleep.Data,1) < size(DataStatus.Spectral.Data,1)
                    DataStatus.Spectral.Data = DataStatus.Spectral.Data(1:size(DataStatus.Sleep.Data,1),:);
                    disp('Spectral >> Repairing difference in Table Size (EEG > SleepScore)');
                end
            end
            if DataStatus.Sleep.Loaded && DataStatus.AIS.Loaded
                %Error check for differences in size and pivot row
                %check for Pivot row (Predose length)
                if ~isempty(DataStatus.Sleep.PivotRow) && ~isempty(DataStatus.AIS.PivotRow)
                    if DataStatus.Sleep.PivotRow > DataStatus.AIS.PivotRow
                        DataStatus.Sleep.DataLabels(1:DataStatus.Sleep.PivotRow-DataStatus.AIS.PivotRow) = [];
                        DataStatus.Sleep.Data(1:DataStatus.Sleep.PivotRow-DataStatus.AIS.PivotRow,:) = [];
                        DataStatus.Sleep.PivotRow = DataStatus.Sleep.PivotRow-(DataStatus.Sleep.PivotRow-DataStatus.AIS.PivotRow);
                        disp('Sleep >> Repairing difference in Dose Pivot Rows (SleepScore > EEG)');
                    elseif DataStatus.AIS.PivotRow > DataStatus.Sleep.PivotRow
                        DataStatus.AIS.Data(1:DataStatus.AIS.PivotRow-DataStatus.Sleep.PivotRow,:) = [];
                        DataStatus.AIS.PivotRow = DataStatus.AIS.PivotRow-(DataStatus.AIS.PivotRow-DataStatus.Sleep.PivotRow);
                        disp('AIS >> Repairing difference in Dose Pivot Rows (EEG > SleepScore)');
                    end
                end
                %check for size (Postdose length)
                if size(DataStatus.Sleep.Data,1) > size(DataStatus.AIS.Data,1)
                    DataStatus.Sleep.DataLabels = DataStatus.Sleep.DataLabels(1:size(DataStatus.AIS.Data,1),:);
                    DataStatus.Sleep.Data = DataStatus.Sleep.Data(1:size(DataStatus.AIS.Data,1),:);
                    disp('Sleep >> Repairing difference in Table Size (SleepScore > EEG)');
                elseif size(DataStatus.Sleep.Data,1) < size(DataStatus.AIS.Data,1)
                    DataStatus.AIS.Data = DataStatus.AIS.Data(1:size(DataStatus.Sleep.Data,1),:);
                    disp('AIS >> Repairing difference in Table Size (EEG > SleepScore)');
                end
            end
            if DataStatus.Sleep.Loaded && DataStatus.TE.Loaded
                %Error check for differences in size and pivot row
                %check for Pivot row (Predose length)
                if ~isempty(DataStatus.Sleep.PivotRow) && ~isempty(DataStatus.TE.PivotRow)
                    if DataStatus.Sleep.PivotRow > DataStatus.TE.PivotRow
                        DataStatus.Sleep.DataLabels(1:DataStatus.Sleep.PivotRow-DataStatus.TE.PivotRow) = [];
                        DataStatus.Sleep.Data(1:DataStatus.Sleep.PivotRow-DataStatus.TE.PivotRow,:) = [];
                        DataStatus.Sleep.PivotRow = DataStatus.Sleep.PivotRow-(DataStatus.Sleep.PivotRow-DataStatus.TE.PivotRow);
                        disp('Sleep >> Repairing difference in Dose Pivot Rows (SleepScore > EEG)');
                    elseif DataStatus.TE.PivotRow > DataStatus.Sleep.PivotRow
                        DataStatus.TE.Data(1:DataStatus.TE.PivotRow-DataStatus.Sleep.PivotRow,:) = [];
                        DataStatus.TE.PivotRow = DataStatus.TE.PivotRow-(DataStatus.TE.PivotRow-DataStatus.Sleep.PivotRow);
                        disp('TE  >> Repairing difference in Dose Pivot Rows (EEG > SleepScore)');
                    end
                end
                %check for size (Postdose length)
                if size(DataStatus.Sleep.Data,1) > size(DataStatus.TE.Data,1)
                    DataStatus.Sleep.DataLabels = DataStatus.Sleep.DataLabels(1:size(DataStatus.TE.Data,1),:);
                    DataStatus.Sleep.Data = DataStatus.Sleep.Data(1:size(DataStatus.TE.Data,1),:);
                    disp('Sleep >> Repairing difference in Table Size (SleepScore > EEG)');
                elseif size(DataStatus.Sleep.Data,1) < size(DataStatus.TE.Data,1)
                    DataStatus.TE.Data = DataStatus.TE.Data(1:size(DataStatus.Sleep.Data,1),:);
                    disp('TE >> Repairing difference in Table Size (EEG > SleepScore)');
                end
            end

            % ALL data should have the same length here.
            % On the rare occasion, a files w/o a PivotEpoch may have different lengths.
            dataLength.Vec = [size(DataStatus.Spectral.Data,1), size(DataStatus.AIS.Data,1), ...
                size(DataStatus.TE.Data,1), size(DataStatus.Sleep.Data,1)];
            dataLength.Max = max(dataLength.Vec);
            dataLength.Min = min(dataLength.Vec(dataLength.Vec >= 1));
            dataLength.Diff = dataLength.Max - dataLength.Vec(dataLength.Vec >= 1);
            if ~all(dataLength.Diff == 0) %if at least one data length (> 0 data samples) is different than the max
                infostr = ['Warning: NSB_GenerateStatTable >> Processed data tables are not the same length, trimming end epochs.'];
                disp(infostr);
                if ~isempty(options.logfile)
                    NSBlog(options.logfile,infostr);
                else
                    errordlg(infostr,'NSB_GenerateStatTable','replace');
                end

                try
                    DataStatus.Spectral.Data = DataStatus.Spectral.Data(1:dataLength.Min,:);
                    infostr = ['Warning: NSB_GenerateStatTable >> Spectral data table trimmed to epoch: ', num2str(DataStatus.Spectral.Data(end,4))];
                    disp(infostr);
                    if ~isempty(options.logfile)
                        NSBlog(options.logfile,infostr);
                    else
                        errordlg(infostr,'NSB_GenerateStatTable','replace');
                    end
                end
                try
                    DataStatus.AIS.Data = DataStatus.AIS.Data(1:dataLength.Min,:);
                    infostr = ['Warning: NSB_GenerateStatTable >> AIS data table trimmed to epoch: ', num2str(DataStatus.AIS.Data(end,4))];
                    disp(infostr);
                    if ~isempty(options.logfile)
                        NSBlog(options.logfile,infostr);
                    else
                        errordlg(infostr,'NSB_GenerateStatTable','replace');
                    end
                end
                try
                    DataStatus.TE.Data = DataStatus.TE.Data(1:dataLength.Min,:);
                    infostr = ['Warning: NSB_GenerateStatTable >> TE data table trimmed to epoch: ', num2str(DataStatus.TE.Data(end,4))];
                    disp(infostr);
                    if ~isempty(options.logfile)
                        NSBlog(options.logfile,infostr);
                    else
                        errordlg(infostr,'NSB_GenerateStatTable','replace');
                    end
                end
                try
                    DataStatus.Sleep.Data = DataStatus.Sleep.Data(1:dataLength.Min,:);
                    infostr = ['Warning: NSB_GenerateStatTable >> Sleep data table trimmed to epoch: ', num2str(DataStatus.Sleep.Data(end,4))];
                    disp(infostr);
                    if ~isempty(options.logfile)
                        NSBlog(options.logfile,infostr);
                    else
                        errordlg(infostr,'NSB_GenerateStatTable','replace');
                    end
                end
            end
            clear dataLength;

            %Process SleepStatistics
            % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Process Sleep Scoring Data
            % Generate SleepStatsData
            % Write StatsSummary
            % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Self Contained - not included in DataStatus Struct
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

                    %Read/Process SleepScoring Summarized Data File
                    try
                        [~,~,SleepStatsData] = xlsread(fullfile(DataFolderPath,'NSB_Output',SubjectSleepStatsList{SubjectSleepStatsFileChannelList_IDX}));
                    catch
                        SleepStatsData = readcell(fullfile(DataFolderPath,'NSB_Output',SubjectSleepStatsList{SubjectSleepStatsFileChannelList_IDX}));
                    end
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
                DataStatus.Sleep.PivotRow = [];
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

            %Process SeizureStatistics
            % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Process Sleep Scoring Data
            % Generate SeizureStatsData
            % Write StatsSummary
            % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Self Contained - not included in DataStatus Struct
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

                    %Read/Process SeizureScoring Summary Data File
                    try
                        [~,~,SeizureStatsData] = xlsread(fullfile(DataFolderPath,'NSB_Output',SubjectSeizureStatsList{SubjectSeizureStatsFileChannelList_IDX}));
                    catch
                        SeizureStatsData = readcell(fullfile(DataFolderPath,'NSB_Output',SubjectSeizureStatsList{SubjectSeizureStatsFileChannelList_IDX}));
                    end
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
                DataStatus.Sleep.PivotRow = [];
                try
                    infostr = ['ERROR: NSB_GenerateStatTable >> Data Not Loaded: ',fullfile(DataFolderPath,'NSB_Output',SubjectSeizureStatsList{SubjectSeizureStatsFileChannelList_IDX})];
                catch
                    infostr = ['ERROR: NSB_GenerateStatTable >> Data Not Loaded: ',fullfile(DataFolderPath,'NSB_Output',SubjectSeizureStatsList{1})];
                end
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

            if SeizureStatProcessed
                % From Above: SeizureStatsHeader = ['Date,Subject,Channel Name,Channel Num,Manipulation,Total Number of Spike Trains,Total Spike Train Duration (min),Percent of Recording,Mean Spike Train Duration (sec),Longest Spike Train Duration (sec),Shortest Spike Train Duration (sec),Mean Number of Spikes/Train'];
                curChanVec = SubjectSeizureStatsChannelList(SubjectSeizureFileChannelList_IDX(curChan));
                curChanVec = num2cell(curChanVec);
                %New Format
                StatsSheet = [ {datestr(datenum(StudyDesign{curRow,DateCol}))} , StudyDesign(curRow,AnimalCol),...
                    SubjectSeizureStatsChannelName(SubjectSeizureFileChannelList_IDX(curChan)),curChanVec,StudyDesign(curRow,DoseCol),num2cell(SeizureStatsData)];

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

            % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Build variable vectors
            % Generate StatsSheet
            % Write StatsSheet
            % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % ToDo: Address issue  that some channels could have different sampling rates
            % ALL data should have the same length here.
            dataLength = max([size(DataStatus.Spectral.Data,1), size(DataStatus.AIS.Data,1), ...
                size(DataStatus.TE.Data,1), size(DataStatus.Sleep.Data,1)]);

            if ~isnan(StudyDesign{curRow,DateCol})
                % If there is a recording date/time in the StudyDesign, use it
                curDateVec = num2cell( bsxfun(@times,ones(dataLength,1),datenum(StudyDesign{curRow,DateCol})) );
            else
                if DataStatus.Spectral.Loaded
                    RecordingDate = datevec(DataStatus.Spectral.Data(1,3));
                elseif DataStatus.AIS.Loaded
                    RecordingDate = datevec(DataStatus.AIS.Data(1,3));
                elseif DataStatus.TE.Loaded
                    RecordingDate = datevec(DataStatus.TE.Data(1,3));
                else
                    RecordingDate = datevec(DataStatus.Sleep.Data(1,2));
                end
                curDateVec = num2cell( bsxfun(@times,ones(dataLength,1), datenum(RecordingDate(1:3))) );
            end
            curDateVec = cellfun(@datestr,curDateVec,'UniformOutput', false); %<<< newformat to output as string not datenum
            curAnimalVec(1:dataLength,1) = StudyDesign(curRow,AnimalCol);
            curDoseVec(1:dataLength,1) = StudyDesign(curRow,DoseCol);


            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %Go back to original - how handle no pivot -- NaN dosing
            %Decision:  does one keep 3 seperate sheets or try to combine them??

            if DataStatus.Sleep.Loaded
                curSSVec = DataStatus.Sleep.DataLabels;

                if DataStatus.Spectral.Loaded
                    clear curChanVec
                    curChanVec(1:dataLength,1) = SubjectSpectralFileChannelList(SubjectSpectralFileChannelList_IDX(curChan));
                    curChanVec = num2cell(curChanVec);
                    curChanLabel(1:dataLength,1) = SubjectSpectralFileChannelName(SubjectSpectralFileChannelList_IDX(curChan));
                    %StatsSheet = [curDateVec,curAnimalVec,curChanLabel,curChanVec,curDoseVec,curEpochVec,curValidVec, curSSVec, curDataMat];
                    StatsSheet = [curDateVec,curAnimalVec,curChanLabel,curChanVec,curDoseVec,...
                        num2cell( DataStatus.Spectral.Data(:,4) ),...
                        num2cell( DataStatus.Spectral.Data(:,2) ),...
                        curSSVec, ...
                        num2cell( DataStatus.Spectral.Data(:,5:end) )];
                    if size(StatsSheet,2) ~= oldStatsSheetSize.Spectral(:,2) && ~any(isnan(oldStatsSheetSize.Spectral))
                        %if stats sheet is not empty (first pass) and they are NOT the same size
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
                    if size(StatsSheet,2) > oldStatsSheetSize.Spectral(2) || isnan(oldStatsSheetSize.Spectral(2))
                        oldStatsSheetSize.Spectral = size(StatsSheet);  %<< only if bigger?
                    end
                end
                if DataStatus.AIS.Loaded
                    clear curChanVec
                    curChanVec(1:dataLength,1) = SubjectAISFileChannelList(SubjectAISFileChannelList_IDX(curChan));
                    curChanVec = num2cell(curChanVec);
                    curChanLabel(1:dataLength,1) = SubjectAISFileChannelName(SubjectAISFileChannelList_IDX(curChan));
                    %StatsSheet = [curDateVec,curAnimalVec,curChanLabel,curChanVec,curDoseVec,curEpochVec,curValidVec, curSSVec, curDataMat];
                    StatsSheet = [curDateVec,curAnimalVec,curChanLabel,curChanVec,curDoseVec,...
                        num2cell( DataStatus.AIS.Data(:,4) ),...
                        num2cell( DataStatus.AIS.Data(:,2) ),...
                        curSSVec,...
                        num2cell( DataStatus.AIS.Data(:,5:end) )];
                    if size(StatsSheet,2) ~= oldStatsSheetSize.AIS(:,2) && ~any(isnan(oldStatsSheetSize.AIS))
                        %if stats sheet is not empty (first pass) and they are NOT the same size
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
                            [status,msg] = NSB_WriteGenericCSV(StatsSheet, fullfile(outputPath, 'NSB_Cerridwen-AISStatisticalAnalysisTable.csv'),true);
                        catch
                            infostr = {'Warning: NSB_GenerateStatTable >> Cannot write NSB_Cerridwen-AISStatisticalAnalysisTable.';'Check that the file is not currently open and then press OK'};
                            uiwait(msgbox(infostr,'NSB_GenerateStatTable','warn','modal'));
                            [status,msg] = NSB_WriteGenericCSV(StatsSheet, fullfile(outputPath, 'NSB_Cerridwen-AISStatisticalAnalysisTable.csv'),true);
                        end
                    end
                    if size(StatsSheet,2) > oldStatsSheetSize.AIS(2) || isnan(oldStatsSheetSize.AIS(2))
                        oldStatsSheetSize.AIS = size(StatsSheet);  %<< only if bigger?
                    end

                end
                if DataStatus.TE.Loaded
                    clear curChanVec
                    curChanVec(1:dataLength,1) = SubjectTEFileChannelList(SubjectTEFileChannelList_IDX(curChan));
                    curChanVec = num2cell(curChanVec);
                    curChanLabel(1:dataLength,1) = SubjectTEFileChannelName(SubjectTEFileChannelList_IDX(curChan));
                    %StatsSheet = [curDateVec,curAnimalVec,curChanLabel,curChanVec,curDoseVec,curEpochVec,curValidVec, curSSVec, curDataMat];
                    StatsSheet = [curDateVec,curAnimalVec,curChanLabel,curChanVec,curDoseVec,...
                        num2cell( DataStatus.TE.Data(:,4) ),...
                        num2cell( DataStatus.TE.Data(:,2) ),...
                        curSSVec,...
                        num2cell( DataStatus.TE.Data(:,5:end) )];
                    if size(StatsSheet,2) ~= oldStatsSheetSize.TE(:,2) && ~any(isnan(oldStatsSheetSize.TE))
                        %if stats sheet is not empty (first pass) and they are NOT the same size
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
                            [status,msg] = NSB_WriteGenericCSV(StatsSheet, fullfile(outputPath, 'NSB_Cerridwen-TEStatisticalAnalysisTable.csv'),true);
                        catch
                            infostr = {'Warning: NSB_GenerateStatTable >> Cannot write NSB_Cerridwen-TEStatisticalAnalysisTable.';'Check that the file is not currently open and then press OK'};
                            uiwait(msgbox(infostr,'NSB_GenerateStatTable','warn','modal'));
                            [status,msg] = NSB_WriteGenericCSV(StatsSheet, fullfile(outputPath, 'NSB_Cerridwen-TEStatisticalAnalysisTable.csv'),true);
                        end
                    end
                    if size(StatsSheet,2) > oldStatsSheetSize.TE(2) || isnan(oldStatsSheetSize.TE(2))
                        oldStatsSheetSize.TE = size(StatsSheet);  %<< only if bigger?
                    end
                end
                if all([~DataStatus.Spectral.Loaded, ~DataStatus.AIS.Loaded, ~DataStatus.TE.Loaded])
                    %Only Sleep Scoring loaded
                    clear curChanVec
                    curChanVec(1:dataLength,1) = SubjectSomnoFileChannelList(SubjectSomnoFileChannelList_IDX(curChan));
                    curChanVec = num2cell(curChanVec);
                    %StatsSheet = [curDateVec,curAnimalVec,curChanLabel,curChanVec,curDoseVec,curEpochVec,curValidVec, curSSVec];
                    StatsSheet = [curDateVec,curAnimalVec,curChanLabel,curChanVec,curDoseVec,...
                        num2cell( DataStatus.Spectral.Data(:,4) ),... % <<<<<<<<<<<< CHeck
                        num2cell( DataStatus.Spectral.Data(:,2) ),... % <<<<<<<<<<<< CHeck
                        curSSVec];
                    if size(StatsSheet,2) ~= oldStatsSheetSize.Sleep(2) && ~any(isnan(oldStatsSheetSize.Sleep))
                        %if stats sheet is not empty (first pass) and they are NOT the same size
                        infostr = ['ERROR: NSB_GenerateStatTable >> Data Table Not Same Size (Skipping): ', fullfile(DataFolderPath,'NSB_Output',SubjectSpectralFileList{SubjectSpectralFileChannelList_IDX(curChan)})];
                        if ~isempty(options.logfile)
                            NSBlog(options.logfile,infostr);
                        else
                            errordlg(infostr,'NSB_GenerateStatTable','replace');
                        end
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
                    if size(StatsSheet,2) > oldStatsSheetSize.Sleep(2) || isnan(oldStatsSheetSize.Sleep(2))
                        oldStatsSheetSize.Sleep = size(StatsSheet);  %<< only if bigger?
                    end
                end
            else % ~DataStatus.Sleep.Loaded
                if DataStatus.Spectral.Loaded
                    %could be just EEG is being processed or failed to find
                    % Build a blank Sleep Scoring vector
                    for n = 1:length(curDateVec)
                        curSSVec{n,1} = '';
                    end
                    clear curChanVec
                    curChanVec(1:dataLength,1) = SubjectSpectralFileChannelList(SubjectSpectralFileChannelList_IDX(curChan));
                    curChanVec = num2cell(curChanVec);
                    curChanLabel(1:dataLength,1) = SubjectSpectralFileChannelName(SubjectSpectralFileChannelList_IDX(curChan));
                    %StatsSheet = [curDateVec,curAnimalVec,curChanLabel,curChanVec,curDoseVec,curEpochVec,curValidVec, curSSVec, curDataMat];
                    StatsSheet = [curDateVec,curAnimalVec,curChanLabel,curChanVec,curDoseVec,...
                        num2cell( DataStatus.Spectral.Data(:,4) ),...
                        num2cell( DataStatus.Spectral.Data(:,2) ),...
                        curSSVec, ...
                        num2cell( DataStatus.Spectral.Data(:,5:end) )];
                    if size(StatsSheet,2) ~= oldStatsSheetSize.Spectral(2) && ~any(isnan(oldStatsSheetSize.Spectral))
                        %if stats sheet is not empty (first pass) and they are NOT the same size
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
                    if size(StatsSheet,2) > oldStatsSheetSize.Spectral(2) || isnan(oldStatsSheetSize.Spectral(2))
                        oldStatsSheetSize.Spectral = size(StatsSheet);  %<< only if bigger?
                    end
                end
                if DataStatus.AIS.Loaded
                    % Build a blank Sleep Scoring vector
                    for n = 1:length(curDateVec)
                        curSSVec{n,1} = '';
                    end
                    clear curChanVec
                    curChanVec(1:dataLength,1) = SubjectAISFileChannelList(SubjectAISFileChannelList_IDX(curChan));
                    curChanVec = num2cell(curChanVec);
                    curChanLabel(1:dataLength,1) = SubjectAISFileChannelName(SubjectAISFileChannelList_IDX(curChan));
                    %StatsSheet = [curDateVec,curAnimalVec,curChanLabel,curChanVec,curDoseVec,curEpochVec,curValidVec, curSSVec, curDataMat];
                    StatsSheet = [curDateVec,curAnimalVec,curChanLabel,curChanVec,curDoseVec,...
                        num2cell( DataStatus.AIS.Data(:,4) ),...
                        num2cell( DataStatus.AIS.Data(:,2) ),...
                        curSSVec, ...
                        num2cell( DataStatus.AIS.Data(:,5:end) )];
                    if size(StatsSheet,2) ~= oldStatsSheetSize.AIS(2) && ~any(isnan(oldStatsSheetSize.AIS))
                        %if stats sheet is not empty (first pass) and they are NOT the same size
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
                            [status,msg] = NSB_WriteGenericCSV(StatsSheet, fullfile(outputPath, 'NSB_Cerridwen-AISStatisticalAnalysisTable.csv'),true);
                        catch
                            infostr = {'Warning: NSB_GenerateStatTable >> Cannot write NSB_Cerridwen-AISStatisticalAnalysisTable.';'Check that the file is not currently open and then press OK'};
                            uiwait(msgbox(infostr,'NSB_GenerateStatTable','warn','modal'));
                            [status,msg] = NSB_WriteGenericCSV(StatsSheet, fullfile(outputPath, 'NSB_Cerridwen-AISStatisticalAnalysisTable.csv'),true);
                        end
                    end
                    if size(StatsSheet,2) > oldStatsSheetSize.AIS(2) || isnan(oldStatsSheetSize.AIS(2))
                        oldStatsSheetSize.AIS = size(StatsSheet);  %<< only if bigger?
                    end
                end
                if DataStatus.TE.Loaded
                    % Build a blank Sleep Scoring vector
                    for n = 1:length(curDateVec)
                        curSSVec{n,1} = '';
                    end
                    clear curChanVec
                    curChanVec(1:dataLength,1) = SubjectTEFileChannelList(SubjectTEFileChannelList_IDX(curChan));
                    curChanVec = num2cell(curChanVec);
                    curChanLabel(1:dataLength,1) = SubjectTEFileChannelName(SubjectTEFileChannelList_IDX(curChan));
                    %StatsSheet = [curDateVec,curAnimalVec,curChanLabel,curChanVec,curDoseVec,curEpochVec,curValidVec, curSSVec, curDataMat];
                    StatsSheet = [curDateVec,curAnimalVec,curChanLabel,curChanVec,curDoseVec,...
                        num2cell( DataStatus.TE.Data(:,4) ),...
                        num2cell( DataStatus.TE.Data(:,2) ),...
                        curSSVec, ...
                        num2cell( DataStatus.TE.Data(:,5:end) )];
                    if size(StatsSheet,2) ~= oldStatsSheetSize.TE(2) && ~any(isnan(oldStatsSheetSize.TE))
                        %if stats sheet is not empty (first pass) and they are NOT the same size
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
                            [status,msg] = NSB_WriteGenericCSV(StatsSheet, fullfile(outputPath, 'NSB_Cerridwen-TEStatisticalAnalysisTable.csv'),true);
                        catch
                            infostr = {'Warning: NSB_GenerateStatTable >> Cannot write NSB_Cerridwen-TEStatisticalAnalysisTable.';'Check that the file is not currently open and then press OK'};
                            uiwait(msgbox(infostr,'NSB_GenerateStatTable','warn','modal'));
                            [status,msg] = NSB_WriteGenericCSV(StatsSheet, fullfile(outputPath, 'NSB_Cerridwen-TEStatisticalAnalysisTable.csv'),true);
                        end
                    end
                    if size(StatsSheet,2) > oldStatsSheetSize.TE(2) || isnan(oldStatsSheetSize.TE(2))
                        oldStatsSheetSize.TE = size(StatsSheet);  %<< only if bigger?
                    end
                end
            end
            %Cleanup memory for next iteration
            clearvars curDateVec curAnimalVec curDoseVec curChanVec curChanLabel curSSVec StatsSheet
            clearvars dataLength BaselineMean;

            % %% Generate and write RM Table
            % % generate RM Table Header
            % % options.doRMtable is not set when using Menu dropdown
            % if options.doRMtable
            %     if isnumeric(StudyDesign{curRow,AnimalCol})
            %         curSubject = num2str(StudyDesign{curRow,AnimalCol});
            %     else
            %         curSubject = StudyDesign{curRow,AnimalCol};
            %     end
            %     if isempty(RMtable)
            %         %RMtable(RMtableCNTR).date(1) = StudyDesign{curRow,DateCol};
            %         RMtable(RMtableCNTR).date = StudyDesign{curRow,DateCol};
            %         RMtable(RMtableCNTR).subject = curSubject;
            %         RMtable(RMtableCNTR).dose = StudyDesign{curRow,DoseCol};
            %         RMtable(RMtableCNTR).Channel = SubjectSpectralFileChannelList(SubjectSpectralFileChannelList_IDX(curChan));
            %         RMtable(RMtableCNTR).ts = DataStatus.Spectral.Data(:,4);
            %         RMtable(RMtableCNTR).tsMin = min(RMtable(RMtableCNTR).ts);
            %         RMtable(RMtableCNTR).tsMax = max(RMtable(RMtableCNTR).ts);
            %         RMtable(RMtableCNTR).valid = DataStatus.Spectral.Data(:,2);
            %         for curBand = 1:5
            %             dynBandName = ['Band',num2str(curBand)];
            %             RMtable(RMtableCNTR).(dynBandName).data = DataStatus.Spectral.Data(:,4+curBand);
            %             dynBandName = ['Ratio',num2str(curBand)];
            %             RMtable(RMtableCNTR).(dynBandName).data = DataStatus.Spectral.Data(:,9+curBand);
            %         end
            %         RMtableCNTR = RMtableCNTR +1;
            %     else
            %         %If different add if not average into table.
            %         SubjectIDX = strcmpi({RMtable(:).subject},curSubject);
            %         DoseIDX = strcmpi({RMtable(:).dose},StudyDesign{curRow,DoseCol});
            %         ChannelIDX = ismember([RMtable(:).Channel],SubjectSpectralFileChannelList(SubjectSpectralFileChannelList_IDX(curChan)));
            %         DuplicateIDX = SubjectIDX & DoseIDX & ChannelIDX;
            %         if ~any(DuplicateIDX) && ~isempty(DuplicateIDX)
            %             %RMtable(RMtableCNTR).date(1) = StudyDesign{curRow,DateCol};
            %             RMtable(RMtableCNTR).date = StudyDesign{curRow,DateCol};
            %             RMtable(RMtableCNTR).subject = curSubject;
            %             RMtable(RMtableCNTR).dose = StudyDesign{curRow,DoseCol};
            %             RMtable(RMtableCNTR).Channel = SubjectSpectralFileChannelList(SubjectSpectralFileChannelList_IDX(curChan));
            %             RMtable(RMtableCNTR).ts = DataStatus.Spectral.Data(:,4);
            %             RMtable(RMtableCNTR).tsMin = min(RMtable(RMtableCNTR).ts);
            %             RMtable(RMtableCNTR).tsMax = max(RMtable(RMtableCNTR).ts);
            %             RMtable(RMtableCNTR).valid = DataStatus.Spectral.Data(:,2);
            %             for curBand = 1:5
            %                 dynBandName = ['Band',num2str(curBand)];
            %                 RMtable(RMtableCNTR).(dynBandName).data = DataStatus.Spectral.Data(:,4+curBand);
            %                 dynBandName = ['Ratio',num2str(curBand)];
            %                 RMtable(RMtableCNTR).(dynBandName).data = DataStatus.Spectral.Data(:,9+curBand);
            %             end
            %             RMtableCNTR = RMtableCNTR +1;
            %         else
            %             RMtable(DuplicateIDX).date(end+1) = StudyDesign{curRow,DateCol};
            %             RMtable(DuplicateIDX).tsMin = min(intersect(RMtable(DuplicateIDX).ts, DataStatus.Spectral.Data(:,4)));
            %             RMtable(DuplicateIDX).tsMax = max(intersect(RMtable(DuplicateIDX).ts, DataStatus.Spectral.Data(:,4)));
            %             tsMinIDX = [find(RMtable(DuplicateIDX).ts == RMtable(DuplicateIDX).tsMin,1,'first'), find(DataStatus.Spectral.Data(:,4) == RMtable(DuplicateIDX).tsMin,1,'first')];
            %             tsMaxIDX = [find(RMtable(DuplicateIDX).ts == RMtable(DuplicateIDX).tsMax,1,'first'), find(DataStatus.Spectral.Data(:,4) == RMtable(DuplicateIDX).tsMax,1,'first')];
            %             %trim
            %             RMtable(DuplicateIDX).ts = RMtable(DuplicateIDX).ts( tsMinIDX(1) : tsMaxIDX(1) );
            %             RMtable(DuplicateIDX).valid = RMtable(DuplicateIDX).valid( tsMinIDX(1) : tsMaxIDX(1) );
            %             RMtable(DuplicateIDX).valid = RMtable(DuplicateIDX).valid && DataStatus.Spectral.Data(tsMinIDX(2):tsMaxIDX(2),2); %are both valid
            %
            %             for curBand = 1:5
            %                 dynBandName = ['Band',num2str(curBand)];
            %                 RMtable(DuplicateIDX).(dynBandName).data = nanmean([RMtable(DuplicateIDX).(dynBandName).data(tsMinIDX(1) : tsMaxIDX(1)) , DataStatus.Spectral.Data(tsMinIDX(2):tsMaxIDX(2),4+curBand)],2);
            %                 dynBandName = ['Ratio',num2str(curBand)];
            %                 RMtable(DuplicateIDX).(dynBandName).data = nanmean([RMtable(DuplicateIDX).(dynBandName).data(tsMinIDX(1) : tsMaxIDX(1)) , DataStatus.Spectral.Data(tsMinIDX(2):tsMaxIDX(2),9+curBand)],2);
            %             end
            %         end
            %     end
            % end  %if doRMtable
        end %for Channel
    end
    try, close(h_chan); end
end %for cur Row

% %Write RMfile
% if options.doRMtable
%     Subjects = {RMtable(:).subject}; %could be char or double
%     %because this could be either double or char
%     for curSubject = 1:length(Subjects)
%         if isnumeric(Subjects{curSubject})
%             Subjects{curSubject} = num2str(Subjects{curSubject});
%         elseif ischar(Subjects{curSubject})
%         else
%             %error
%         end
%     end
%     uSubjects = unique(Subjects);
%     Manip = {RMtable(:).dose};
%     uManip = unique(Manip);
%     uChannels = unique([RMtable(:).Channel]);
%     BlockStart = max([RMtable(:).tsMin]);
%     BlockEnd = min([RMtable(:).tsMax]);
%     for curChan = 1:length(uChannels)
%         Chan_IDX = [RMtable(:).Channel] == uChannels(curChan);
%         for curSubject = 1:length(uSubjects)
%             Subject_IDX = strcmp(Subjects,uSubjects{curSubject});
%             for curManip = 1:length(uManip)
%                 Manip_IDX = strcmp(Manip,uManip{curManip});
%
%                 Struct_IDX = find(Chan_IDX & Subject_IDX & Manip_IDX);
%                 %if Struct_IDX > l << deal with this
%
%                 %Each Row block is an animal
%
%                 % Write CSV
%
%             end
%         end
%     end
% end

try, close(h); end
%[status,msg] = NSB_WriteGenericCSV(StatsSheet, 'C:\Users\NexStepBiomarkers\Accounts\Maccine\Maccine - Ketamine\MAC001-01_ NSB EEGEngineOutput AnalysisTable For StatisticalPackageImport_temp.csv');
status = true;
warning('on', 'MATLAB:datevec:Inputs');
end

function DataStatus = resetDataStatus()
DataStatus.Spectral.Loaded = false;
DataStatus.Sleep.Loaded = false;
DataStatus.AIS.Loaded = false;
DataStatus.TE.Loaded = false;
DataStatus.Spectral.Data = [];
DataStatus.Sleep.Data = [];
%DataStatus.Sleep.DataLabels added on the fly.
DataStatus.AIS.Data = [];
DataStatus.TE.Data = [];
DataStatus.Spectral.PivotRow = [];
DataStatus.Sleep.PivotRow = [];
DataStatus.AIS.PivotRow = [];
DataStatus.TE.PivotRow = [];
DataStatus.Spectral.PivotEpoch = [];
DataStatus.Sleep.PivotEpoch = [];
DataStatus.AIS.PivotEpoch = [];
DataStatus.TE.PivotEpoch = [];
end
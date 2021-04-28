function status = NSB_GenerateRMStatTable(StudyDesignPath,BaselineRange,ReportRange, options)
%
%
% Inputs:
%   StudyDesignPath         - (string) Path+FileName of StudyDesign file
%   BaselineRange           - (double or empty (default - [] use all data)) Seconds: Time range before Dosing to calculate baseline average (2 values, if one value baseline will be calculated as -seconds:0
%   ReportRange             - (double or empty (default - [] use all data)) Seconds: range of analyzed data to write to spreadsheet
%                               Example - BaselineRange = [ (-20 * 60) , (-120 * 60) ];
%   options           - (struct) of options
%                           options.logfile
%                           options.progress
%                           options.doMeanBaseline (Logical Default:true) special option
%                           to do/not do baseline averageing.
%
% Outputs:
%   status              - (logical) return value
%       File saved in StudyDesignPath.
%
% todo... validate inputs and sort range(s)

status = false;
warning('off', 'MATLAB:datevec:Inputs');
switch nargin
    case 1
        BaselineRange = [];
        ReportRange = [];
        options.progress = false;
        options.logfile = '';
        options.doMeanBaseline = true;
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
        ReportRange = [];
        options.progress = false;
        options.logfile = '';
        options.doMeanBaseline = true;
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
        
        if ~isnumeric(BaselineRange) && ischar(BaselineRange)
            BaselineRange = str2double(BaselineRange);
            errorstr = ['Warning: NSB_GenerateStatTable >> BaselineMeanTimeStart ischar and will be converted to numeric.'];
            if ~isempty(options.logfile)
                status = NSBlog(options.logfile,errorstr);
            else
                errordlg(errorstr,'NSB_GenerateStatTable','replace');
            end
        elseif ~isnumeric(BaselineRange)
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
        
        if ~isnumeric(BaselineRange) && ischar(BaselineRange)
            BaselineRange = str2double(BaselineRange);
            errorstr = ['Warning: NSB_GenerateStatTable >> BaselineMeanTimeStart ischar and will be converted to numeric.'];
            if ~isempty(options.logfile)
                status = NSBlog(options.logfile,errorstr);
            else
                errordlg(errorstr,'NSB_GenerateStatTable','replace');
            end
        elseif ~isnumeric(BaselineRange)
            errorstr = ['ERROR: NSB_GenerateStatTable >> BaselineMeanTimeStart is not a string or numeric'];
            if ~isempty(options.logfile)
                status = NSBlog(options.logfile,errorstr);
            else
                errordlg(errorstr,'NSB_GenerateStatTable','replace');
            end
            return;
        end
        
        if ~isnumeric(ReportRange) && ischar(ReportRange)
            ReportRange = str2double(ReportRange);
            errorstr = ['Warning: NSB_GenerateStatTable >> BaselineMeanTimeEnd ischar and will be converted to numeric.'];
            if ~isempty(options.logfile)
                status = NSBlog(options.logfile,errorstr);
            else
                errordlg(errorstr,'NSB_GenerateStatTable','replace');
            end
        elseif ~isnumeric(ReportRange)
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
        
        if ~isnumeric(BaselineRange) && ischar(BaselineRange)
            BaselineRange = str2double(BaselineRange);
            errorstr = ['Warning: NSB_GenerateStatTable >> BaselineMeanTimeStart ischar and will be converted to numeric.'];
            if ~isempty(options.logfile)
                status = NSBlog(options.logfile,errorstr);
            else
                errordlg(errorstr,'NSB_GenerateStatTable','replace');
            end
        elseif ~isnumeric(BaselineRange)
            errorstr = ['ERROR: NSB_GenerateStatTable >> BaselineMeanTimeStart is not a string or numeric'];
            if ~isempty(options.logfile)
                status = NSBlog(options.logfile,errorstr);
            else
                errordlg(errorstr,'NSB_GenerateStatTable','replace');
            end
            return;
        end
        
        if ~isnumeric(ReportRange) && ischar(ReportRange)
            ReportRange = str2double(ReportRange);
            errorstr = ['Warning: NSB_GenerateStatTable >> BaselineMeanTimeEnd ischar and will be converted to numeric.'];
            if ~isempty(options.logfile)
                status = NSBlog(options.logfile,errorstr);
            else
                errordlg(errorstr,'NSB_GenerateStatTable','replace');
            end
        elseif ~isnumeric(ReportRange)
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
        if ~isfield(options,'fnHasDateID')
            options.fnHasDateID = true;
        end
        
    otherwise
        [fn, path] = uigetfile({'*.xls','Microsoft Excel (*.xls)';'*.*',  'All Files (*.*)'},'Choose a NSB Specified Study file');
        StudyDesignPath = fullfile(path,fn);
        BaselineRange = [];
        ReportRange = [];
        options.progress = true;
        options.logfile = '';
        options.doMeanBaseline = true;
end

% Generate output path for saving file
outputPath = fileparts(StudyDesignPath);

if options.progress, h = waitbar(0,'Loading Study Design .xls'); RowWaitPos = get(h,'Position'); end

%build a RM stats table
[~,~,StudyDesign] = xlsread(StudyDesignPath); %'~' does not work in earlier matlab versions (2010 ?)
StatsSheet = cell(0);
oldStatsSheetSize = [NaN, NaN];

%Get Column Indexes and unique data
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
    %ToDo Add Study ID and Functional Group
    for curRow = 2:size(StudyDesign,1)
        if ischar(StudyDesign{curRow,AnimalCol})
            SubjectID(curRow-1) = StudyDesign(curRow,AnimalCol);
        elseif isnumeric(StudyDesign{curRow,AnimalCol}) || islogical(StudyDesign{curRow,AnimalCol})
            SubjectID{curRow-1} = num2str(StudyDesign{curRow,AnimalCol});
        end;
         if ischar(StudyDesign{curRow,DoseCol})
            DoseID(curRow-1) = StudyDesign(curRow,DoseCol);
        elseif isnumeric(StudyDesign{curRow,DoseCol}) || islogical(StudyDesign{curRow,DoseCol})
            DoseID{curRow-1} = num2str(StudyDesign{curRow,DoseCol});
        end;  
    end
    uniqSubjectID = unique(SubjectID); %block columns
    uniqDoseID = unique(DoseID); %Block rows

    



%get unique animal ID's
%ger unique doses
% ... etc
%build position table (to use as reference later)

%write Spreadsheet for each band and ratio (ugh)

DesignLength = size(StudyDesign,1);
for curRow = 2:DesignLength
    
end


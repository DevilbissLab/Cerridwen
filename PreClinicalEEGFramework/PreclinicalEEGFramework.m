function varargout = PreclinicalEEGFramework(varargin)
%DMD to edit this..
%add reporting to tAnalysis Status


% PRECLINICALEEGFRAMEWORK MATLAB code for PreclinicalEEGFramework.fig
%      PRECLINICALEEGFRAMEWORK, by itself, creates a new PRECLINICALEEGFRAMEWORK or raises the existing
%      singleton*.
%
%      H = PRECLINICALEEGFRAMEWORK returns the handle to a new PRECLINICALEEGFRAMEWORK or the handle to
%      the existing singleton*.
%
%      PRECLINICALEEGFRAMEWORK('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PRECLINICALEEGFRAMEWORK.M with the given input arguments.
%
%      PRECLINICALEEGFRAMEWORK('Property','Value',...) creates a new PRECLINICALEEGFRAMEWORK or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before PreclinicalEEGFramework_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to PreclinicalEEGFramework_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help PreclinicalEEGFramework

% Last Modified by GUIDE v2.5 26-Jul-2017 08:59:03

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @PreclinicalEEGFramework_OpeningFcn, ...
                   'gui_OutputFcn',  @PreclinicalEEGFramework_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before PreclinicalEEGFramework is made visible.
function PreclinicalEEGFramework_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to PreclinicalEEGFramework (see VARARGIN)

% Choose default command line output for PreclinicalEEGFramework
handles.output = hObject;

%Load the ParamatersFile
handles.parameters = NSB_ParameterFile();
handles.licensing = NSB_LoadLicensing(handles.parameters.PreClinicalFramework.LogFile);

%Set default fields
set(handles.SoftName_stxt,'String',handles.parameters.PreClinicalFramework.Name);
set(handles.ver_stxt,'String',handles.parameters.PreClinicalFramework.Version);
set(handles.date_stxt,'String',datestr(now,'ddd mmmm dd, yyyy HH:MM:SS PM'));
set(handles.AnalysisParm_grp,'SelectionChangeFcn',@(hObject,eventdata)PreclinicalEEGFramework('AnalysisParm_grp_Callback',hObject,eventdata,guidata(hObject)));
%set(handles.genXLSoutput_chk,'Value',handles.parameters.PreClinicalFramework.XLSoutput); %moved to AnalysisParameterEditor
set(handles.doSpectral_chk,'Value',true);

%set image to open browser
ImageHandle = get(handles.NexStepImage);
set(ImageHandle.Children,'ButtonDownFcn','web http://www.nexstepbiomarkers.com -browser');
%set(ImageHandle.Children,'ButtonDownFcn','winopen http://www.nexstepbiomarkers.com');

%Set initial AnalysisStruct state
handles.StudyDesign = cell(0);

handles.AnalysisStruct.isloadedGlobalParameterFile = false;
handles.AnalysisStruct.StudyDesignFilePath = '';
%handles.AnalysisStruct.doArtifactPlot = handles.parameters.PreClinicalFramework.ArtifactDetection.plot;
%handles.AnalysisStruct.doArtifactPlot = get(handles.genArtifactPlot_chk,'Value'); %moved to AnalysisParameterEditor
%
%handles.AnalysisStruct.doSomnogramReport = true;
%these Next three are handled in main GUI
handles.AnalysisStruct.doSpectralAnalysis = get(handles.doSpectral_chk,'Value');
handles.AnalysisStruct.doSomnogram = get(handles.doSomnogram_chk,'Value');
handles.AnalysisStruct.doWriteEDF = get(handles.genEDF_chk,'Value');
handles.AnalysisStruct.doStatsTable = get(handles.genStatsTable_chk,'Value');
handles.AnalysisStruct.doSeizureAnalysis = get(handles.doSeizure_chk,'Value');

handles.AnalysisStruct.useDefaultAnalysisParameters = true;
set(handles.default_rad,'Value',true)
handles.AnalysisStruct.useExternalAnalysisParameters = false;
handles.AnalysisStruct.useNewAnalysisParameters = false;
set(handles.AnalysisParameters_txt,'Enable','off');
set(handles.LoadParm_but,'Enable','off');

txtcounter = 0;
set(handles.RunAnalysis_but, 'Enable', 'off');
%Framework Lic
if isfield(handles.licensing,'Framework')
    txtcounter = txtcounter +1;
    if handles.licensing.Framework
        txt{txtcounter} = 'Found Framework License';
        set(handles.RunAnalysis_but, 'Enable', 'on');
    elseif ~isempty(handles.licensing.Expiration)
        if now <= handles.licensing.Expiration
            txt{txtcounter} = 'Found Framework License';
            set(handles.RunAnalysis_but, 'Enable', 'on');
        else
            txt{txtcounter} = ['ERROR: Framework License Expired on ',datestr(handles.licensing.Expiration)];
        end
    else
        txt{txtcounter} = 'ERROR: No Framework License';
    end
else
    txtcounter = txtcounter +1;
    txt{txtcounter} = 'ERROR: No Framework License';
end
%DSI Lic
if isfield(handles.licensing,'DSIImporter')
    txtcounter = txtcounter +1;
    if handles.licensing.DSIImporter
        txt{txtcounter} = 'Found DSI Import License';
    else
        txt{txtcounter} = 'No DSI Import License';
    end
end
%FIFF Lic
if isfield(handles.licensing,'FIFFImporter')
    txtcounter = txtcounter +1;
    if handles.licensing.FIFFImporter
        txt{txtcounter} = 'Found FIFF Import License';
    else
        txt{txtcounter} = 'No FIFF Import License';
    end
end
%EDF Writer Lic
if isfield(handles.licensing,'EDFWriter')
    txtcounter = txtcounter +1;
    if handles.licensing.EDFWriter
        txt{txtcounter} = 'Found EDFWriter License';
        set(handles.genEDF_chk, 'Enable', 'on');
    else
        txt{txtcounter} = 'No EDFWriter License';
        set(handles.genEDF_chk, 'Value', false, 'Enable', 'off');
    end
end
%SleepScore Lic (Contains reporting for free)
if isfield(handles.licensing,'ssModule')
    txtcounter = txtcounter +1;
    if handles.licensing.ssModule
        txt{txtcounter} = 'Found Sleep Scoring License';
        set(handles.doSomnogram_chk, 'Enable', 'on');
    else
        txt{txtcounter} = 'No Sleep Scoring License';
        set(handles.doSomnogram_chk, 'Value', false, 'Enable', 'off');
    end
end
% %Seizure Analysis Lic (Contains reporting for free)
% if isfield(handles.licensing,'SeizureModule')
%     txtcounter = txtcounter +1;
%     if handles.licensing.SeizureModule
%         txt{txtcounter} = 'Found Seizure Scoring License';
%         set(handles.doSeizure_chk, 'Enable', 'on');
%     else
%         txt{txtcounter} = 'No Seizure Scoring License';
%         set(handles.doSeizure_chk, 'Value', false, 'Enable', 'off');
%     end
% end

%Stats Table Lic
%  special because we are handling the chk and menu differently
%  always start with it off until study design is loaded
set(handles.genStatsTable_chk, 'Enable', 'off');
if isfield(handles.licensing,'StatTableOutput')
    txtcounter = txtcounter +1;
    if handles.licensing.StatTableOutput
        txt{txtcounter} = 'Found Groupwise Table Output License';
        txtcounter = txtcounter +1;
        txt{txtcounter} = '  Select Study Design to Activate';
        set(handles.genStatTable_menu, 'Enable', 'on');
    else
        txt{txtcounter} = 'No Groupwise Table Output License';
        set(handles.genStatsTable_chk, 'Value', false, 'Enable', 'off');
        set(handles.genStatTable_menu, 'Enable', 'off');
    end
end

txtcounter = txtcounter +1;
txt{txtcounter} = 'Initalization...Complete';
set(handles.status_stxt,'String',txt);
clear txtcounter;

NSBlog(handles.parameters.PreClinicalFramework.LogFile,'NexStep Biomarkers Preclinical EEG Framework log file');
if isdeployed
    [MCCver.major, MCCver.minor, MCCver.update, MCCver.point] = mcrversion;
    NSBlog(handles.parameters.PreClinicalFramework.LogFile,['Running MCR version: ',num2str(MCCver.major),'.',num2str(MCCver.minor),'.',num2str(MCCver.update),'.',num2str(MCCver.point)]);
end

%Temp inactivation during development <<<<<<<<<<<<<<<<
%set(handles.genEDF_chk, 'Enable', 'off');

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes PreclinicalEEGFramework wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = PreclinicalEEGFramework_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

function dir_txt_Callback(hObject, eventdata, handles)
% hObject    handle to dir_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
txt = get(handles.status_stxt,'String');
if iscell(txt)
    StatusLines = handles.parameters.PreClinicalFramework.StatusLines -3;
    if length(txt) > StatusLines
        txt = txt(end-(StatusLines-1):end);
    end
    rows = length(txt);
else
    txt = {txt}; %create cell array
    rows = 1;
end
if exist(get(hObject,'String'),'dir') == 7
    DIRECTORYNAME = get(hObject,'String');
    [status, handles.StudyDesign] = NSB_BuildAnalysisStruct(DIRECTORYNAME,'dir');
    if status
        set(handles.dir_txt, 'String', DIRECTORYNAME);
        rows = rows+1;
        txt{rows,1} = 'Analysis Directory...';
        rows = rows+1;
        txt{rows,1} = DIRECTORYNAME;
        rows = rows+1;
        txt{rows,1} = ['Processed ',num2str(size(handles.StudyDesign,1)),' files'];
        set(handles.status_stxt,'String',txt);
    else
        rows = rows+1;
        txt{rows,1} = 'Error in Dir Structure...Failed';
        set(handles.status_stxt,'String',txt);
    end
else
    DIRECTORYNAME = uigetdir('', 'Not a Valid Directory: Please Select Experiment Directory to Analyze');
    if ischar(DIRECTORYNAME)
        [status, handles.StudyDesign] = NSB_BuildAnalysisStruct(DIRECTORYNAME,'dir');
        if status
            set(handles.dir_txt, 'String', DIRECTORYNAME);
            rows = rows+1;
            txt{rows,1} = 'Analysis Directory...';
            rows = rows+1;
            txt{rows,1} = DIRECTORYNAME;
            rows = rows+1;
            txt{rows,1} = ['Processed ',num2str(size(handles.StudyDesign,1)),' files'];
            set(handles.status_stxt,'String',txt);
%             for curFile = 1:length(handles.status_stxt)
%                 NSBlog(handles.parameters.PreClinicalFramework.LogFile,['Adding File to StudyDesign: ',fullfile(handles.StudyDesign{curFile,1}.path,handles.StudyDesign{curFile,1}.name),' TYPE: ',handles.StudyDesign{curFile,1}.type,' ',handles.StudyDesign{curFile,2}]);
%             end
        else
            rows = rows+1;
            txt{rows,1} = 'Error in Dir Structure...Failed';
            set(handles.status_stxt,'String',txt);
        end
    else
        handles.StudyDesign = cell(0);
        set(handles.dir_txt, 'String', 'C:\      [Select Directory]');
        rows = rows+1;
        txt{rows,1} = 'Set Analysis Directory...Canceled';
        set(handles.status_stxt,'String',txt);
    end
end
NSBlog(handles.parameters.PreClinicalFramework.LogFile,['Data Input Selected: ',DIRECTORYNAME]);
guidata(hObject, handles);

% --- Executes on button press in getDir_but.
function getDir_but_Callback(hObject, eventdata, handles)
% hObject    handle to getDir_but (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
txt = get(handles.status_stxt,'String');
if iscell(txt)
    StatusLines = handles.parameters.PreClinicalFramework.StatusLines -3;
    if length(txt) > StatusLines
        txt = txt(end-(StatusLines-1):end);
    end
    rows = length(txt);
else
    txt = {txt}; %create cell array
    rows = 1;
end
DIRECTORYNAME = uigetdir('', 'Analyze Experiment Directory');
if ischar(DIRECTORYNAME)
    [status, handles.StudyDesign] = NSB_BuildAnalysisStruct(DIRECTORYNAME,'dir');
    if status
        set(handles.dir_txt, 'String', DIRECTORYNAME);
        rows = rows+1;
        txt{rows,1} = 'Analysis Directory...';
        rows = rows+1;
        txt{rows,1} = DIRECTORYNAME;
        rows = rows+1;
        txt{rows,1} = ['Processed ',num2str(size(handles.StudyDesign,1)),' files'];
        set(handles.status_stxt,'String',txt);
%         for curFile = 1:length(handles.StudyDesign)
%             NSBlog(handles.parameters.PreClinicalFramework.LogFile,['Adding File to StudyDesign: ',fullfile(handles.StudyDesign{curFile,1}.path,handles.StudyDesign{curFile,1}.name),' TYPE: ',handles.StudyDesign{curFile,1}.type,' ',handles.StudyDesign{curFile,2}]);
%         end
    else
        rows = rows+1;
        txt{rows,1} = 'Error in Dir Structure...Failed';
        set(handles.status_stxt,'String',txt);
    end
else
    handles.StudyDesign = cell(0);
    set(handles.dir_txt, 'String', 'C:\      [Select Directory]');
    rows = rows+1;
    txt{rows,1} = 'Set Analysis Directory...Canceled';
    set(handles.status_stxt,'String',txt);
end
NSBlog(handles.parameters.PreClinicalFramework.LogFile,['Data Input Selected: ',DIRECTORYNAME]);
guidata(hObject, handles);

% --- Executes on button press in xlsImport_but.
function xlsImport_but_Callback(hObject, eventdata, handles)
% hObject    handle to xlsImport_but (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
txt = get(handles.status_stxt,'String');
if iscell(txt)
    StatusLines = handles.parameters.PreClinicalFramework.StatusLines -3;
    if length(txt) > StatusLines
        txt = txt(end-(StatusLines-1):end);
    end
    rows = length(txt);
else
    txt = {txt}; %create cell array
    rows = 1;
end
[fn, path] = uigetfile({'*.xls;*.xlsx','Microsoft Excel (*.xls,*xlsx)';'*.*',  'All Files (*.*)'},'Choose a NSB Specified Study file');
if ischar(fn)
    rows = rows+1;
    txt{rows,1} = 'Processing Analysis Spreadsheet File...';
    set(handles.status_stxt,'String',txt);
    drawnow();
    [status, handles.StudyDesign] = NSB_BuildAnalysisStruct(fullfile(path,fn),'xls');
    if status
        set(handles.genStatsTable_chk, 'Enable', 'on'); %<< allow Stats table
        handles.AnalysisStruct.StudyDesignFilePath = fullfile(path,fn); %<< Set StudyDesign Path
        set(handles.dir_txt, 'String', '<< Using Study Design Spreadsheet>>');
        rows = rows+1;
        txt{rows,1} = 'Analysis Speradsheet File...';
        rows = rows+1;
        txt{rows,1} = fn;
        rows = rows+1;
        txt{rows,1} = ['Processed ',num2str(size(handles.StudyDesign,1)),' files'];
        set(handles.status_stxt,'String',txt);
    else
        rows = rows+1;
        txt{rows,1} = 'Error in Dir Structure...Failed';
        set(handles.status_stxt,'String',txt);
    end
else
    handles.StudyDesign = cell(0);
    set(handles.dir_txt, 'String', 'C:\      [Select Directory]');
    rows = rows+1;
    txt{rows,1} = 'Set Analysis Directory...Canceled';
    set(handles.status_stxt,'String',txt);
end
NSBlog(handles.parameters.PreClinicalFramework.LogFile,['Analysis Study Design Selected: ',fn]);
guidata(hObject, handles);


% --- Executes on button press in useSavedAnalysis_chk.
function useSavedAnalysis_chk_Callback(hObject, eventdata, handles)
% hObject    handle to useSavedAnalysis_chk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of useSavedAnalysis_chk

function AnalysisParm_grp_Callback(hObject, eventdata, handles)
% here we need to detect button, set state of parameter buttons and set
% appropiate handles
if strcmpi(get(get(hObject,'SelectedObject'),'String'), 'User Defined Analyses Parameters')
    handles.AnalysisStruct.useDefaultAnalysisParameters = false;
    handles.AnalysisStruct.useExternalAnalysisParameters = true;
    handles.AnalysisStruct.useNewAnalysisParameters = false;
    set(handles.AnalysisParameters_txt,'Enable','on');
    set(handles.LoadParm_but,'Enable','on');
elseif strcmpi(get(get(hObject,'SelectedObject'),'String'), 'Generate New Analyses Parameters')
    handles.AnalysisStruct.useDefaultAnalysisParameters = false;
    handles.AnalysisStruct.useExternalAnalysisParameters = false;
    handles.AnalysisStruct.useNewAnalysisParameters = true;
    set(handles.AnalysisParameters_txt,'Enable','off');
    set(handles.LoadParm_but,'Enable','off');
else %default
    handles.AnalysisStruct.useDefaultAnalysisParameters = true;
    handles.AnalysisStruct.useExternalAnalysisParameters = false;
    handles.AnalysisStruct.useNewAnalysisParameters = false;
    set(handles.AnalysisParameters_txt,'Enable','off');
    set(handles.LoadParm_but,'Enable','off');
end
guidata(hObject, handles);   

function AnalysisParameters_txt_Callback(hObject, eventdata, handles)
% hObject    handle to AnalysisParameters_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
txt = get(handles.status_stxt,'String');
if iscell(txt)
    StatusLines = handles.parameters.PreClinicalFramework.StatusLines -3;
    if length(txt) > StatusLines
        txt = txt(end-(StatusLines-1):end);
    end
    rows = length(txt);     
else
    txt = {txt}; %create cell array
    rows = 1;
end
if iscell(get(hObject,'String')) NewFile = get(hObject,'String');NewFile = NewFile{1}; else NewFile = get(hObject,'String'); end
NSBlog(handles.parameters.PreClinicalFramework.LogFile,['Loading: ',NewFile]);
if exist(NewFile,'file') == 2
    DynParamGUIStruct = [];
    if handles.parameters.PreClinicalFramework.MatlabPost2014
        DynParamGUIStruct = tinyxml2_wrap('load', NewFile);
    else
        DynParamGUIStruct = xml_load(NewFile);
    end
    if ~isempty(DynParamGUIStruct)
            NSBlog(handles.parameters.PreClinicalFramework.LogFile,['Sucessfully Loaded: ',NewFile]);
    end
    handles.parameters.PreClinicalFramework.ArtifactDetection = DynParamGUIStruct.ArtifactDetection;
    handles.parameters.PreClinicalFramework.SpectralAnalysis = DynParamGUIStruct.SpectralAnalysis;
    %if exists
    if isfield(DynParamGUIStruct, 'Scoring')
        if ~isfield(DynParamGUIStruct.Scoring,'StageEpoch')
            DynParamGUIStruct.Scoring.StageEpoch = handles.parameters.PreClinicalFramework.Scoring.StageEpoch;
        end
        if ~isfield(DynParamGUIStruct.Scoring,'GMMinit')
            DynParamGUIStruct.Scoring.GMMinit = handles.parameters.PreClinicalFramework.Scoring.GMMinit;
        end
        if ~isfield(DynParamGUIStruct.Scoring,'doSomnogramReport')
            DynParamGUIStruct.Scoring.doSomnogramReport = false;
        end
        handles.parameters.PreClinicalFramework.Scoring = DynParamGUIStruct.Scoring;
    end
    if isfield(DynParamGUIStruct, 'StatsTable'), handles.parameters.PreClinicalFramework.StatsTable = DynParamGUIStruct.StatsTable; end
    if isfield(DynParamGUIStruct, 'rules'), handles.parameters.PreClinicalFramework.rules = DynParamGUIStruct.rules; end
    if isfield(DynParamGUIStruct, 'File')
        handles.parameters.PreClinicalFramework.XLSoutput = DynParamGUIStruct.File.XLSoutput;
        handles.parameters.PreClinicalFramework.useWaitBar = DynParamGUIStruct.File.useWaitBar;
        handles.parameters.PreClinicalFramework.File.DSIoffset = DynParamGUIStruct.File.DSIoffset;
        if isfield(DynParamGUIStruct.File,'BioBookoutput')
            handles.parameters.PreClinicalFramework.BioBookoutput = DynParamGUIStruct.File.BioBookoutput;
        else
            handles.parameters.PreClinicalFramework.BioBookoutput = true;
        end
        if isfield(DynParamGUIStruct.File,'FIFtype')
            handles.parameters.PreClinicalFramework.File.FIFtype = DynParamGUIStruct.File.FIFtype;
        else
            handles.parameters.PreClinicalFramework.File.FIFtype = 'EEG';
        end
    end
    %version 2.xx
    if isfield(DynParamGUIStruct, 'OutputDir')
        handles.parameters.PreClinicalFramework.OutputDir = DynParamGUIStruct.OutputDir;
        %find log file and move it
        %also update handles.parameters.PreClinicalFramework.LogFile
        if exist(handles.parameters.PreClinicalFramework.OutputDir,'dir') ~=7
            mkdir(handles.parameters.PreClinicalFramework.OutputDir);
        end
        if exist(handles.parameters.PreClinicalFramework.LogFile,'file') == 2
            
            [LogPath,logName,LogExt] = fileparts(handles.parameters.PreClinicalFramework.LogFile);
            if ~strcmpi(LogPath,handles.parameters.PreClinicalFramework.OutputDir)
            NewLogPath = fullfile(handles.parameters.PreClinicalFramework.OutputDir,[logName,LogExt]);
            movefile(handles.parameters.PreClinicalFramework.LogFile, NewLogPath);
            end
        end
    end
    if isfield(DynParamGUIStruct, 'SeizureAnalysis')
        handles.parameters.PreClinicalFramework.SeizureAnalysis = DynParamGUIStruct.SeizureAnalysis;
    end
    if isfield(DynParamGUIStruct, 'Resample')
        handles.parameters.PreClinicalFramework.Resample = DynParamGUIStruct.Resample;
    end
    handles.AnalysisStruct.isloadedGlobalParameterFile = true;
    
    rows = rows+1;
    txt{rows,1} = 'User Parameter File...';
    rows = rows+1;
    txt{rows,1} = NewFile;
    set(handles.status_stxt,'String',txt);
else
    oldFilename = NewFile;
    [fn, xmlpath] = uigetfile({'*.xml','NexStep Biomarkers Parameter Files (*.xml)';'*.*',  'All Files (*.*)'},'Choose a parameter file');
    if ischar(xmlpath)
        NewFile = fullfile(xmlpath,fn);
        if exist(NewFile,'file') == 2
            if handles.parameters.PreClinicalFramework.MatlabPost2014
                DynParamGUIStruct = tinyxml2_wrap('load', NewFile);
            else
                DynParamGUIStruct = xml_load(NewFile);
            end
            handles.parameters.PreClinicalFramework.ArtifactDetection = DynParamGUIStruct.ArtifactDetection;
            handles.parameters.PreClinicalFramework.SpectralAnalysis = DynParamGUIStruct.SpectralAnalysis;
            %if exists
            if isfield(DynParamGUIStruct, 'Scoring')
                if ~isfield(DynParamGUIStruct.Scoring,'StageEpoch')
                    DynParamGUIStruct.Scoring.StageEpoch = handles.parameters.PreClinicalFramework.Scoring.StageEpoch;
                end
                if ~isfield(DynParamGUIStruct.Scoring,'GMMinit')
                    DynParamGUIStruct.Scoring.GMMinit = handles.parameters.PreClinicalFramework.Scoring.GMMinit;
                end
                if ~isfield(DynParamGUIStruct.Scoring,'doSomnogramReport')
                    DynParamGUIStruct.Scoring.doSomnogramReport = false;
                end
                if ~isfield(DynParamGUIStruct.Scoring,'SomnogramReport_Template')
                    DynParamGUIStruct.Scoring.SomnogramReport_Template = handles.parameters.PreClinicalFramework.Scoring.SomnogramReport_Template;
                end
                handles.parameters.PreClinicalFramework.Scoring = DynParamGUIStruct.Scoring;
            end
            if isfield(DynParamGUIStruct, 'StatsTable'), handles.parameters.PreClinicalFramework.StatsTable = DynParamGUIStruct.StatsTable; end
            if isfield(DynParamGUIStruct, 'rules'), handles.parameters.PreClinicalFramework.rules = DynParamGUIStruct.rules; end
            if isfield(DynParamGUIStruct, 'File')
                handles.parameters.PreClinicalFramework.XLSoutput = DynParamGUIStruct.File.XLSoutput;
                handles.parameters.PreClinicalFramework.useWaitBar = DynParamGUIStruct.File.useWaitBar;
                handles.parameters.PreClinicalFramework.File.DSIoffset = DynParamGUIStruct.File.DSIoffset;
                if isfield(DynParamGUIStruct.File,'BioBookoutput')
                    handles.parameters.PreClinicalFramework.BioBookoutput = DynParamGUIStruct.File.BioBookoutput;
                else
                    handles.parameters.PreClinicalFramework.BioBookoutput = true;
                end
                if isfield(DynParamGUIStruct.File,'FIFtype')
                    handles.parameters.PreClinicalFramework.File.FIFtype = DynParamGUIStruct.File.FIFtype;
                else
                    handles.parameters.PreClinicalFramework.File.FIFtype = 'EEG';
                end
            end
            %version 2.xx
            if isfield(DynParamGUIStruct, 'OutputDir')
                handles.parameters.PreClinicalFramework.OutputDir = DynParamGUIStruct.OutputDir;
                %find log file and move it
                %also update handles.parameters.PreClinicalFramework.LogFile
                if exist(handles.parameters.PreClinicalFramework.OutputDir,'dir') ~=7
                    mkdir(handles.parameters.PreClinicalFramework.OutputDir);
                end
                if exist(handles.parameters.PreClinicalFramework.LogFile,'file') == 2
                    
            [LogPath,logName,LogExt] = fileparts(handles.parameters.PreClinicalFramework.LogFile);
            if ~strcmpi(LogPath,handles.parameters.PreClinicalFramework.OutputDir)
            NewLogPath = fullfile(handles.parameters.PreClinicalFramework.OutputDir,[logName,LogExt]);
            movefile(handles.parameters.PreClinicalFramework.LogFile, NewLogPath);
            end
                end
            end
            if isfield(DynParamGUIStruct, 'SeizureAnalysis')
                handles.parameters.PreClinicalFramework.SeizureAnalysis = DynParamGUIStruct.SeizureAnalysis;
            end
            if isfield(DynParamGUIStruct, 'Resample')
                handles.parameters.PreClinicalFramework.Resample = DynParamGUIStruct.Resample;
            end
            handles.AnalysisStruct.isloadedGlobalParameterFile = true;
            
            set(handles.AnalysisParameters_txt, 'String', NewFile);
            rows = rows+1;
            txt{rows,1} = 'User Parameter File...';
            rows = rows+1;
            txt{rows,1} = NewFile;
            set(handles.status_stxt,'String',txt);
        else
            handles.AnalysisStruct.isloadedGlobalParameterFile = false;
            set(handles.AnalysisParameters_txt, 'String', oldFilename);
            rows = rows+1;
            txt{rows,1} = 'Set Parameter File: Does not exist';
            set(handles.status_stxt,'String',txt);
        end
    else
        handles.AnalysisStruct.isloadedGlobalParameterFile = false;
        set(handles.AnalysisParameters_txt, 'String', oldFilename);
        rows = rows+1;
        txt{rows,1} = 'Set Parameter File...Canceled';
        set(handles.status_stxt,'String',txt);
    end
end
NSBlog(handles.parameters.PreClinicalFramework.LogFile,['User Parameters File Selected: ',NewFile]);
guidata(hObject, handles);

% --- Executes on button press in LoadParm_but.
function LoadParm_but_Callback(hObject, eventdata, handles)
% hObject    handle to LoadParm_but (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
txt = get(handles.status_stxt,'String');
if iscell(txt)
    StatusLines = handles.parameters.PreClinicalFramework.StatusLines -3;
    if length(txt) > StatusLines
        txt = txt(end-(StatusLines-1):end);
    end
    rows = length(txt);     
else
    txt = {txt}; %create cell array
    rows = 1;
end
oldFilename = set(hObject, 'String');
newFilename = [];
[fn, xmlpath] = uigetfile({'*.xml','NexStep Biomarkers Parameter Files (*.xml)';'*.*',  'All Files (*.*)'},'Choose a parameter file');
if ischar(xmlpath)
    newFilename = fullfile(xmlpath,fn);
    %update handles with info...
    NSBlog(handles.parameters.PreClinicalFramework.LogFile,['Loading: ',newFilename]);
    if exist(newFilename,'file') == 2
        DynParamGUIStruct = [];
        if handles.parameters.PreClinicalFramework.MatlabPost2014
            DynParamGUIStruct = tinyxml2_wrap('load', newFilename);
        else
            DynParamGUIStruct = xml_load(newFilename);
        end
        if ~isempty(DynParamGUIStruct)
            NSBlog(handles.parameters.PreClinicalFramework.LogFile,['Sucessfully Loaded: ',newFilename]);
        end
            
        handles.parameters.PreClinicalFramework.ArtifactDetection = DynParamGUIStruct.ArtifactDetection;%check to see how handle logfiles...
        handles.parameters.PreClinicalFramework.SpectralAnalysis = DynParamGUIStruct.SpectralAnalysis;
        %if exists
        if isfield(DynParamGUIStruct, 'Scoring')
            if ~isfield(DynParamGUIStruct.Scoring,'StageEpoch')
                DynParamGUIStruct.Scoring.StageEpoch = handles.parameters.PreClinicalFramework.Scoring.StageEpoch;
            end
            if ~isfield(DynParamGUIStruct.Scoring,'GMMinit')
                DynParamGUIStruct.Scoring.GMMinit = handles.parameters.PreClinicalFramework.Scoring.GMMinit;
            end
            if ~isfield(DynParamGUIStruct.Scoring,'doSomnogramReport')
                DynParamGUIStruct.Scoring.doSomnogramReport = false;
            end
            if ~isfield(DynParamGUIStruct.Scoring,'SomnogramReport_Template')
                DynParamGUIStruct.Scoring.SomnogramReport_Template = handles.parameters.PreClinicalFramework.Scoring.SomnogramReport_Template;
            end
            handles.parameters.PreClinicalFramework.Scoring = DynParamGUIStruct.Scoring;
        end
         if isfield(DynParamGUIStruct, 'StatsTable'), handles.parameters.PreClinicalFramework.StatsTable = DynParamGUIStruct.StatsTable; end
        if isfield(DynParamGUIStruct, 'rules'), handles.parameters.PreClinicalFramework.rules = DynParamGUIStruct.rules; end
        if isfield(DynParamGUIStruct, 'File')
            handles.parameters.PreClinicalFramework.XLSoutput = DynParamGUIStruct.File.XLSoutput;
            handles.parameters.PreClinicalFramework.useWaitBar = DynParamGUIStruct.File.useWaitBar;
            handles.parameters.PreClinicalFramework.File.DSIoffset = DynParamGUIStruct.File.DSIoffset;
            if isfield(DynParamGUIStruct.File,'BioBookoutput')
                handles.parameters.PreClinicalFramework.BioBookoutput = DynParamGUIStruct.File.BioBookoutput;
            else
                handles.parameters.PreClinicalFramework.BioBookoutput = true;
            end
            if isfield(DynParamGUIStruct.File,'FIFtype')
                handles.parameters.PreClinicalFramework.File.FIFtype = DynParamGUIStruct.File.FIFtype;
            else
                handles.parameters.PreClinicalFramework.File.FIFtype = 'EEG';
            end
            if isfield(DynParamGUIStruct.File,'FIF')
                handles.parameters.PreClinicalFramework.File.FIF.assumeTemplateChOrderCorrect = DynParamGUIStruct.File.FIF.assumeTemplateChOrderCorrect;
                handles.parameters.PreClinicalFramework.File.FIF.showHeadPlot = DynParamGUIStruct.File.FIF.showHeadPlot;
            else
                handles.parameters.PreClinicalFramework.File.FIF.assumeTemplateChOrderCorrect = false;
                handles.parameters.PreClinicalFramework.File.FIF.showHeadPlot = false;
            end
            
        end
        %version 2.xx
        if isfield(DynParamGUIStruct, 'OutputDir')
            handles.parameters.PreClinicalFramework.OutputDir = DynParamGUIStruct.OutputDir;
            %find log file and move it
            %also update handles.parameters.PreClinicalFramework.LogFile
            if exist(handles.parameters.PreClinicalFramework.OutputDir,'dir') ~=7
                %if the drive doesn't exist than this will fail
                try
                    mkdir(handles.parameters.PreClinicalFramework.OutputDir);
                catch
                    warning('PreclinicalEEGFramework:LoadParm - Cannot create output dir stored in analysis parameters file: ',handles.parameters.PreClinicalFramework.OutputDir);
                    handles.parameters.PreClinicalFramework.OutputDir = uigetdir('.', 'Choose an Analysis Output Directory');
                end
            end
            if exist(handles.parameters.PreClinicalFramework.LogFile,'file') == 2
                
            [LogPath,logName,LogExt] = fileparts(handles.parameters.PreClinicalFramework.LogFile);
            if ~strcmpi(LogPath,handles.parameters.PreClinicalFramework.OutputDir)
            NewLogPath = fullfile(handles.parameters.PreClinicalFramework.OutputDir,[logName,LogExt]);
            movefile(handles.parameters.PreClinicalFramework.LogFile, NewLogPath);
            end
            end
        end
        if isfield(DynParamGUIStruct, 'SeizureAnalysis')
            handles.parameters.PreClinicalFramework.SeizureAnalysis = DynParamGUIStruct.SeizureAnalysis;
        end
        if isfield(DynParamGUIStruct, 'Resample')
            handles.parameters.PreClinicalFramework.Resample = DynParamGUIStruct.Resample;
        end
        
        %handles.AnalysisStruct.ParameterFilePath = fullfile(path,fn);
        handles.AnalysisStruct.isloadedGlobalParameterFile = true;
        set(handles.AnalysisParameters_txt, 'String', newFilename);
        
        rows = rows+1;
        txt{rows,1} = 'User Parameter File...';
        rows = rows+1;
        txt{rows,1} = newFilename;
        set(handles.status_stxt,'String',txt);
    else
        handles.AnalysisStruct.isloadedGlobalParameterFile = false;
        set(handles.AnalysisParameters_txt, 'String', oldFilename);
        rows = rows+1;
        txt{rows,1} = 'Set Parameter File: Does not exist';
        set(handles.status_stxt,'String',txt);
    end
else
    newFilename = oldFilename;
    handles.AnalysisStruct.isloadedGlobalParameterFile = false;
    %handles.AnalysisStruct.ParameterFilePath = [];
    set(handles.AnalysisParameters_txt, 'String', oldFilename);
    rows = rows+1;
    txt{rows,1} = 'Set Parameter File...Canceled';
    set(handles.status_stxt,'String',txt);
end
NSBlog(handles.parameters.PreClinicalFramework.LogFile,['User Parameters File Selected: ',newFilename]);
guidata(hObject, handles);

% --- Executes on button press in EditAnalysisParms_but.
function EditAnalysisParms_but_Callback(hObject, eventdata, handles)
% hObject    handle to EditAnalysisParms_but (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
txt = get(handles.status_stxt,'String');
if iscell(txt)
    StatusLines = handles.parameters.PreClinicalFramework.StatusLines -3;
    if length(txt) > StatusLines
        txt = txt(end-(StatusLines-1):end);
    end
    rows = length(txt);
else
    txt = {txt}; %create cell array %Cellify
    rows = 1;
end
    rows = rows+1;
    txt{rows,1} = 'Generating Analyses Parameters GUI...';
    set(handles.status_stxt,'String',txt);
NSBlog(handles.parameters.PreClinicalFramework.LogFile,['Generating Analyses Parameters GUI']);
drawnow;
[EditorOutput, status] = AnalysisParameterEditor(handles.parameters.PreClinicalFramework);
if status
    handles.parameters.PreClinicalFramework = EditorOutput;
    %You have moved the output folder so update log location.
    if isfield(handles.parameters.PreClinicalFramework, 'OutputDir')
        %find log file and move it
        %also update handles.parameters.PreClinicalFramework.LogFile
        if exist(handles.parameters.PreClinicalFramework.OutputDir,'dir') ~=7
            mkdir(handles.parameters.PreClinicalFramework.OutputDir);
        end
        if exist(handles.parameters.PreClinicalFramework.LogFile,'file') == 2
            
            [LogPath,logName,LogExt] = fileparts(handles.parameters.PreClinicalFramework.LogFile);
            if ~strcmpi(LogPath,handles.parameters.PreClinicalFramework.OutputDir)
            NewLogPath = fullfile(handles.parameters.PreClinicalFramework.OutputDir,[logName,LogExt]);
            movefile(handles.parameters.PreClinicalFramework.LogFile, NewLogPath);
            end
        end
    end
end

guidata(hObject, handles);

% --- Executes on button press in RunAnalysis_but.
function RunAnalysis_but_Callback(hObject, eventdata, handles)
% hObject    handle to RunAnalysis_but (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
txt = get(handles.status_stxt,'String');
if iscell(txt)
    %truncate Long lines
    StatusLineLength = cellfun(@length,txt);
    for curLine = 1:length(txt)
        if StatusLineLength(curLine) >= 33
        txt{curLine} = txt{curLine}(1:33);
        end
    end
      
    StatusLines = handles.parameters.PreClinicalFramework.StatusLines -1;
    if length(txt) > StatusLines
        txt = txt(end-(StatusLines-1):end);
    end
    rows = length(txt);
else
    txt = {txt}; %create cell array %Cellify
    rows = 1;
end
NSBlog(handles.parameters.PreClinicalFramework.LogFile,['>> Begin Analyses: ',get(handles.date_stxt,'String')]);
try
    rows = rows+1;
    txt{rows,1} = 'Running Analyses...';
    set(handles.status_stxt,'String',txt);
    [status, msg] = NSB_Workflow_LIMS(handles);
    
    if status
        txt = get(handles.status_stxt,'String');
        if length(txt) > StatusLines
            txt = txt(end-(StatusLines-1):end);
        end
        rows = length(txt);
        rows = rows+1;
        txt{rows,1} = '... Finished Analyses';
        set(handles.status_stxt,'String',txt);
    else
        txt = get(handles.status_stxt,'String');
        if length(txt) > StatusLines
            txt = txt(end-(StatusLines-1):end);
        end
        rows = length(txt);
        rows = rows+1;
        txt{rows,1} = '... Analyses Failed';
        rows = rows+1;
        txt{rows,1} = msg;
        set(handles.status_stxt,'String',txt);
        NSBlog(handles.parameters.PreClinicalFramework.LogFile,['>> Analyses FAILED: ',msg]);
    end
catch ME
    txt = get(handles.status_stxt,'String');
    if length(txt) > StatusLines
        txt = txt(end-(StatusLines-1):end);
    end
    rows = length(txt);
    rows = rows+1;
    txt{rows,1} = '... Analyses FAILED';
    set(handles.status_stxt,'String',txt);
    NSBlog(handles.parameters.PreClinicalFramework.LogFile,['>> Analyses FAILED: ']);
    NSBlog(handles.parameters.PreClinicalFramework.LogFile,['>> Analyses FAILED: ',ME.identifier,ME.message]);
end
% guidata(hObject, handles);

% --- Executes on button press in quit_but.
function quit_but_Callback(hObject, eventdata, handles)
% hObject    handle to quit_but (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
 delete(handles.figure1)
 close all force;
 NSBlog(handles.parameters.PreClinicalFramework.LogFile,['>> Quitting Analyses: ',datestr(now,'ddd mmmm dd, yyyy HH:MM:SS PM')]);

% --- Executes on button press in doSpectral_chk.
function doSpectral_chk_Callback(hObject, eventdata, handles)
% hObject    handle to doSpectral_chk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.AnalysisStruct.doSpectralAnalysis = get(hObject,'Value');
guidata(hObject, handles);

% --- Executes on button press in doSomnogram_chk.
function doSomnogram_chk_Callback(hObject, eventdata, handles)
% hObject    handle to doSomnogram_chk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.AnalysisStruct.doSomnogram = get(hObject,'Value');
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function AnalysisParameters_txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AnalysisParameters_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function dir_txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dir_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --------------------------------------------------------------------
function file_menu_Callback(hObject, eventdata, handles)
% hObject    handle to file_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function help_menu_Callback(hObject, eventdata, handles)
% hObject    handle to help_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function manual_menu_Callback(hObject, eventdata, handles)
% hObject    handle to manual_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
     winopen('NexStep Biomarkers PreclinicalEEGFramework Software Manual.pdf');
catch
    h = errordlg({'Cannot open Preclinical EEG Framework Manual as a pdf.','Please install a PDF reader.','http://get.adobe.com/reader/otherversions/','http://www.foxitsoftware.com/Secure_PDF_Reader/'},'Help');
end

% --------------------------------------------------------------------
function about_menu_Callback(hObject, eventdata, handles)
% hObject    handle to about_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
     winopen('NexStep Biomarkers EULA.pdf');
catch
    h = errordlg({'Cannot open Preclinical EEG Framework EULAas a pdf.','Please install a PDF reader.','http://get.adobe.com/reader/otherversions/','http://www.foxitsoftware.com/Secure_PDF_Reader/'},'Help');
end

% --------------------------------------------------------------------
function load_menu_Callback(hObject, eventdata, handles)
% hObject    handle to load_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
txt = get(handles.status_stxt,'String');
if iscell(txt)
    StatusLines = handles.parameters.PreClinicalFramework.StatusLines -2;
    if length(txt) > StatusLines
        txt = txt(end-(StatusLines-1):end);
    end
    rows = length(txt);
else
    txt = {txt}; %create cell array
    rows = 1;
end
[fn, path] = uigetfile({'*.xls','Microsoft Excel (*.xls)';'*.*',  'All Files (*.*)'},'Choose a NSB Specified Study file');
if ischar(fn)
    [status, handles.StudyDesign] = NSB_BuildAnalysisStruct(fn,'xls');
    if status
        set(handles.dir_txt, 'String', '<< Using Study Design Spreadsheet>>');
        rows = rows+1;
        txt{rows,1} = 'Analysis Spreadsheet File...';
        rows = rows+1;
        txt{rows,1} = fn;
        rows = rows+1;
        txt{rows,1} = ['Processed ',num2str(size(handles.StudyDesign,1)),' files'];
        set(handles.status_stxt,'String',txt);
    else
        rows = rows+1;
        txt{rows,1} = 'Error in Dir Structure...Failed';
        set(handles.status_stxt,'String',txt);
    end
else
    handles.StudyDesign = cell(0);
    set(handles.dir_txt, 'String', 'C:\      [Select Directory]');
    rows = rows+1;
    txt{rows,1} = 'Set Analysis Directory...Canceled';
    set(handles.status_stxt,'String',txt);
end
NSBlog(handles.parameters.PreClinicalFramework.LogFile,['Analysis Study Design Selected: ',fn]);
guidata(hObject, handles);

% --------------------------------------------------------------------
function quit_menu_Callback(hObject, eventdata, handles)
% hObject    handle to quit_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
 delete(handles.figure1)
 NSBlog(handles.parameters.PreClinicalFramework.LogFile,['>> Quitting Analyses: ',datestr(now,'ddd mmmm dd, yyyy HH:MM:SS PM')]);


% --- Executes on button press in genEDF_chk.
function genEDF_chk_Callback(hObject, eventdata, handles)
% hObject    handle to genEDF_chk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.AnalysisStruct.doWriteEDF = get(hObject,'Value');
guidata(hObject, handles);

% Hint: get(hObject,'Value') returns toggle state of genEDF_chk


% --- Executes on button press in genStatsTable_chk.
function genStatsTable_chk_Callback(hObject, eventdata, handles)
% hObject    handle to genStatsTable_chk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of genStatsTable_chk
handles.AnalysisStruct.doStatsTable = get(hObject,'Value');
guidata(hObject, handles);

% --- Executes on button press in doSeizure_chk.
function doSeizure_chk_Callback(hObject, eventdata, handles)
% hObject    handle to doSeizure_chk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.AnalysisStruct.doSeizureAnalysis = get(hObject,'Value');
guidata(hObject, handles);


% --------------------------------------------------------------------
function genStatTable_menu_Callback(hObject, eventdata, handles)
% hObject    handle to genStatTable_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
txt = get(handles.status_stxt,'String');
if iscell(txt)
    StatusLines = handles.parameters.PreClinicalFramework.StatusLines -2;
    if length(txt) > StatusLines
        txt = txt(end-(StatusLines-1):end);
    end
    rows = length(txt);
else
    txt = {txt}; %create cell array
    rows = 1;
end

rows = rows+1;
txt{rows,1} = 'Generating Statistical Table...';
set(handles.status_stxt,'String',txt);
NSBlog(handles.parameters.PreClinicalFramework.LogFile,['NSB_Workflow_LIMS: ...Generating Statistical Table: ',datestr(now)]);
drawnow();
    
if isempty(handles.AnalysisStruct.StudyDesignFilePath)
    status = NSB_GenerateStatTable();
else
    if handles.AnalysisStruct.isloadedGlobalParameterFile
        inputParms.logfile = handles.parameters.PreClinicalFramework.LogFile;
        inputParms.progress = handles.parameters.PreClinicalFramework.useWaitBar;
        inputParms.doMeanBaseline = handles.parameters.PreClinicalFramework.StatsTable.doMeanBaseline;

        status = NSB_GenerateStatTable(handles.AnalysisStruct.StudyDesignFilePath,...
            handles.parameters.PreClinicalFramework.StatsTable.BaselineMeanTimeStart,...
            handles.parameters.PreClinicalFramework.StatsTable.BaselineMeanTimeEnd,inputParms);
    else
        status = NSB_GenerateStatTable(handles.AnalysisStruct.StudyDesignFilePath);
    end
end
        if status
            rows = rows+1;
            txt{rows,1} = '...Statistical Table Generation Sucessful';
            set(handles.status_stxt,'String',txt);
            NSBlog(handles.parameters.PreClinicalFramework.LogFile,['NSB_GUI: ...Write Statistical Table Sucessful: ',datestr(now)]);
            drawnow();
        else
            rows = rows+1;
            txt{rows,1} = '...Statistical Table Generation Failed';
            set(handles.status_stxt,'String',txt);
            NSBlog(handles.parameters.PreClinicalFramework.LogFile,['NSB_GUI: ...Write Statistical Table Failed: ',datestr(now)]);
            drawnow();
        end
guidata(hObject, handles);


% --------------------------------------------------------------------
function support_menu_Callback(hObject, eventdata, handles)
% hObject    handle to support_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
web http://support.nexstepbiomarkers.com -browser


% --------------------------------------------------------------------
function log_menu_Callback(hObject, eventdata, handles)
% hObject    handle to log_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function DetailedLog_menu_Callback(hObject, eventdata, handles)
% hObject    handle to DetailedLog_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

web(handles.parameters.PreClinicalFramework.LogFile,'-browser');
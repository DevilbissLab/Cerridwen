function varargout = AnalysisParameterEditor_new(varargin)
% ANALYSISPARAMETEREDITOR_NEW MATLAB code for AnalysisParameterEditor_new.fig
%      ANALYSISPARAMETEREDITOR_NEW, by itself, creates a new ANALYSISPARAMETEREDITOR_NEW or raises the existing
%      singleton*.
%
%      H = ANALYSISPARAMETEREDITOR_NEW returns the handle to a new ANALYSISPARAMETEREDITOR_NEW or the handle to
%      the existing singleton*.
%
%      ANALYSISPARAMETEREDITOR_NEW('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ANALYSISPARAMETEREDITOR_NEW.M with the given input arguments.
%
%      ANALYSISPARAMETEREDITOR_NEW('Property','Value',...) creates a new ANALYSISPARAMETEREDITOR_NEW or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before AnalysisParameterEditor_new_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to AnalysisParameterEditor_new_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help AnalysisParameterEditor_new

% Last Modified by GUIDE v2.5 15-May-2017 15:17:09

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @AnalysisParameterEditor_new_OpeningFcn, ...
                   'gui_OutputFcn',  @AnalysisParameterEditor_new_OutputFcn, ...
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


% --- Executes just before AnalysisParameterEditor_new is made visible.
function AnalysisParameterEditor_new_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to AnalysisParameterEditor_new (see VARARGIN)

% Choose default command line output for AnalysisParameterEditor_new
handles.output = hObject;
if isfield(varargin{1,1},'Name')
    handles.input = varargin{1,1};
%Set parameters into GUI
set(handles.StatusBar_chk,'Value',varargin{1,1}.useWaitBar);
set(handles.DSIGMT_txt,'String',num2str(varargin{1,1}.File.DSIoffset));
IDX = find(strcmpi(get(handles.Algorithm_pull,'String'),varargin{1,1}.ArtifactDetection.algorithm));
set(handles.Algorithm_pull,'Value',IDX);
set(handles.zero_chk,'Value',varargin{1,1}.ArtifactDetection.rm2Zero);
set(handles.normPower_chk,'Value',varargin{1,1}.SpectralAnalysis.normSpectaTotalPower);
set(handles.MinArtLen_txt,'String',num2str(varargin{1,1}.ArtifactDetection.full.MinArtifactDuration));
set(handles.MinArtGap_txt,'String',num2str(varargin{1,1}.ArtifactDetection.full.CombineArtifactTimeThreshold));
set(handles.SimpDCThresh_txt ,'String',num2str(varargin{1,1}.ArtifactDetection.DCvalue ));
set(handles.SimpRMS_txt ,'String',num2str(varargin{1,1}.ArtifactDetection.RMSMultiplier ));
set(handles.FullDCThresh_txt ,'String',num2str(varargin{1,1}.ArtifactDetection.full.DCvalue ));
IDX = find(strcmpi(get(handles.FullDCCalc_pull,'String'),varargin{1,1}.ArtifactDetection.full.DCcalculation));
set(handles.FullDCCalc_pull,'Value',IDX);
set(handles.FullScaleMult_txt ,'String',num2str(varargin{1,1}.ArtifactDetection.full.STDMultiplier ));
set(handles.FullFlatLen_txt ,'String',num2str(varargin{1,1}.ArtifactDetection.full.minFlatSigLength ));
set(handles.FullSpikeMult_txt ,'String',num2str(varargin{1,1}.ArtifactDetection.full.dvValMultiplier ));
set(handles.FullSpikeSlope_txt ,'String',num2str(varargin{1,1}.ArtifactDetection.full.MaxDT ));
try set(handles.FullMuscMult_txt ,'String',num2str(varargin{1,1}.ArtifactDetection.full.MuscleArtifactMultiplier ));
catch, set(handles.FullMuscMult_txt,'String','3'); end

%new GUI version additional parameters
% Fill Default bands
for curBand = 1:length(varargin{1,1}.SpectralAnalysis.SpectralBands)
    BandData{curBand,1} = num2str(varargin{1,1}.SpectralAnalysis.SpectralBands(curBand).Start);
    BandData{curBand,2} = num2str(varargin{1,1}.SpectralAnalysis.SpectralBands(curBand).Stop);
end
for curRatio = 1:length(varargin{1,1}.SpectralAnalysis.SpectralRatio)
    BandRatio{curRatio,1} = num2str(varargin{1,1}.SpectralAnalysis.SpectralRatio(curRatio).num);
    BandRatio{curRatio,2} = num2str(varargin{1,1}.SpectralAnalysis.SpectralRatio(curRatio).den);
end
set(handles.BandCalc_tab ,'Data', BandData );
set(handles.RatioCalc_tab ,'Data', BandRatio );

%%%%%%%%%%%%%%%%%%%%%%
IDX = find(strcmpi(get(handles.SpectMeth_pull,'String'),varargin{1,1}.SpectralAnalysis.SPTmethod));
set(handles.SpectMeth_pull,'Value',IDX);
IDX = find(strcmpi(get(handles.SpectWindow_pull,'String'),varargin{1,1}.SpectralAnalysis.WindowType));
set(handles.SpectWindow_pull,'Value',IDX);
set(handles.SpectFinalFreq_txt ,'String',num2str(varargin{1,1}.SpectralAnalysis.FinalFreqResolution ));
set(handles.SpectFinalTime_txt ,'String',num2str(varargin{1,1}.SpectralAnalysis.FinalTimeResolution ));


List = get(handles.Algorithm_pull,'String');
if strcmpi(List(get(handles.Algorithm_pull,'Value')),'full') || strcmpi(List(get(handles.Algorithm_pull,'Value')),'full -emg')
    %Turn All children inactive
    Child = get(handles.ArtDetSimp_pan,'Children');
    for n = 1:length(Child)
        set(Child(n),'Enable','off');
    end
    Child = get(handles.ArtDetFull_pan,'Children');
        for n = 1:length(Child)
        set(Child(n),'Enable','on');
        end
else
    Child = get(handles.ArtDetFull_pan,'Children');
    for n = 1:length(Child)
        set(Child(n),'Enable','off');
    end
    Child = get(handles.ArtDetSimp_pan,'Children');
        for n = 1:length(Child)
        set(Child(n),'Enable','on');
        end
end

List = get(handles.SpectMeth_pull,'String');
if ~strcmpi(List(get(handles.SpectMeth_pull,'Value')),'welch')
    %Turn All children inactive
    set(handles.SpectWindow_stxt,'Enable','off');
    set(handles.SpectWindow_pull,'Enable','off');
else
    set(handles.SpectWindow_stxt,'Enable','on');
    set(handles.SpectWindow_pull,'Enable','on');
end
guidata(hObject, handles);

set(handles.SomnoStageSize_txt ,'String',num2str(varargin{1,1}.rules.minStateLength ));
IDX = find(strcmpi(get(handles.SomnoMeth_pul,'String'),varargin{1,1}.Scoring.ScoringType));
set(handles.SomnoMeth_pul,'Value',IDX);
set(handles.zDelta_txt ,'String',num2str(varargin{1,1}.Scoring.zDeltaThreshold ));
set(handles.SomnoArchRules_chk ,'Value',varargin{1,1}.rules.ApplyArchitectureRules );
set(handles.SWS2thresh_txt ,'String',num2str(varargin{1,1}.rules.SWS2.PercentOfStageEpoch ));
set(handles.SWS1thresh_txt ,'String',num2str(varargin{1,1}.rules.SWS1.PercentOfStageEpoch ));
set(handles.QWthresh_txt ,'String',num2str(varargin{1,1}.rules.QW.PercentOfStageEpoch ));
set(handles.AWthresh_txt ,'String',num2str(varargin{1,1}.rules.AW.PercentOfStageEpoch ));
set(handles.PSthresh_txt ,'String',num2str(varargin{1,1}.rules.PS.PercentOfStageEpoch ));
set(handles.SomnoPlot_chk ,'Value',varargin{1,1}.Scoring.plot );

List = get(handles.SomnoMeth_pul,'String');
if ~strcmpi(List(get(handles.SomnoMeth_pul,'Value')),'delta')
    %Turn All children inactive
    Child = get(handles.zDelta_pan,'Children');
    for n = 1:length(Child)
        set(Child(n),'Enable','off');
    end
else
        Child = get(handles.zDelta_pan,'Children');
        for n = 1:length(Child)
        set(Child(n),'Enable','on');
        end
end
if ~get(handles.SomnoArchRules_chk,'Value')
    %Turn All children inactive
    Child = get(handles.Arch_pan,'Children');
    for n = 1:length(Child)
        set(Child(n),'Enable','off');
    end
else
        Child = get(handles.Arch_pan,'Children');
        for n = 1:length(Child)
        set(Child(n),'Enable','on');
        end
end

%New parameters as of 1.17
try
IDX = find(strcmpi(get(handles.FIFdata_pul,'String'),varargin{1,1}.File.FIFtype));
set(handles.FIFdata_pul,'Value',IDX);
catch, set(handles.FIFdata_pul,'Value',1); end

try set(handles.genArtifactPlot_chk ,'Value',varargin{1,1}.ArtifactDetection.plot);
catch, set(handles.genArtifactPlot_chk ,'Value',false); end

try set(handles.genXLSoutput_chk ,'Value',varargin{1,1}.XLSoutput);
catch, set(handles.genXLSoutput_chk ,'Value',false); end

try set(handles.genBioBook_chk ,'Value',varargin{1,1}.BioBookoutput);
catch, set(handles.genBioBook_chk ,'Value',false); end

try
IDX = find(strcmpi(get(handles.FFTwinSize_pul,'String'),varargin{1,1}.SpectralAnalysis.FFTWindowSizeMethod));
set(handles.FFTwinSize_pul,'Value',IDX);
catch, set(handles.FFTwinSize_pul,'Value',1); end

try
List = get(handles.FFTwinSize_pul,'String');
if ~strcmpi(List(get(handles.FFTwinSize_pul,'Value')),'manual')
    set(handles.ManualFFTwinSize_txt,'Enable','off');
    set(handles.ManualFFTwinSize_stxt,'Enable','off');
    set(handles.ManualFFTwinSize_txt ,'String','');
else
    set(handles.ManualFFTwinSize_txt,'Enable','on');
    set(handles.ManualFFTwinSize_stxt,'Enable','on');
    set(handles.ManualFFTwinSize_txt ,'String',num2str(varargin{1,1}.SpectralAnalysis.FFTWindowSize));
end
catch, set(handles.ManualFFTwinSize_txt ,'String',''); end

try
    if varargin{1,1}.SpectralAnalysis.nanMean
        IDX = find(strcmpi(get(handles.FFTMeanWin_pul,'String'),'mean'));
        set(handles.FFTMeanWin_pul,'Value',IDX);
    else
        IDX = find(strcmpi(get(handles.FFTMeanWin_pul,'String'),'sum'));
        set(handles.FFTMeanWin_pul,'Value',IDX);
    end
catch, set(handles.FFTMeanWin_pul,'Value',1); end

% SomnoStageSize_chk
try set(handles.SomnoStageSize_chk ,'Value',varargin{1,1}.Scoring.useGlobalEpoch);
catch, set(handles.SomnoStageSize_chk ,'Value',false); end

if get(handles.SomnoStageSize_chk ,'Value')
    set(handles.SomnoStageSize_txt ,'String',num2str(varargin{1,1}.SpectralAnalysis.FinalTimeResolution));
    set(handles.SomnoStageSize_txt,'Enable','off');
    set(handles.SomnoStageSize_stxt,'Enable','off');
else
    set(handles.SomnoStageSize_txt,'Enable','on');
    set(handles.SomnoStageSize_stxt,'Enable','on');
end
%new 1.42 settings
try set(handles.PosTempOrder_chk ,'Value',varargin{1,1}.File.FIF.assumeTemplateChOrderCorrect);
catch, set(handles.PosTempOrder_chk ,'Value',false); end
try set(handles.HeadPlot_chk ,'Value',varargin{1,1}.File.FIF.showHeadPlot);
catch, set(handles.HeadPlot_chk ,'Value',false); end

%new 1.5x settings
try set(handles.doSomnoReport_chk,'Value',varargin{1,1}.Scoring.doSomnogramReport);
catch, set(handles.doSomnoReport_chk,'Value',false); end
try set(handles.doMeanBaseline_chk,'Value',varargin{1,1}.StatsTable.doMeanBaseline);
catch, set(handles.doMeanBaseline_chk,'Value',false); end
try set(handles.BaselineMeanTimeStart_txt,'String',num2str(varargin{1,1}.StatsTable.BaselineMeanTimeStart));
catch, set(handles.BaselineMeanTimeStart_txt,'String',''); end
try set(handles.BaselineMeanTimeEnd_txt,'String',num2str(varargin{1,1}.StatsTable.BaselineMeanTimeEnd));
catch, set(handles.BaselineMeanTimeEnd_txt,'String',''); end
if get(handles.doMeanBaseline_chk,'Value')
    set(handles.BaselineMeanTimeStart_stxt,'Enable','on'); 
    set(handles.BaselineMeanTimeStart_txt,'Enable','on');
    set(handles.BaselineMeanTimeEnd_stxt,'Enable','on'); 
    set(handles.BaselineMeanTimeEnd_txt,'Enable','on');
else
    set(handles.BaselineMeanTimeStart_stxt,'Enable','off'); 
    set(handles.BaselineMeanTimeStart_txt,'Enable','off');
    set(handles.BaselineMeanTimeEnd_stxt,'Enable','off'); 
    set(handles.BaselineMeanTimeEnd_txt,'Enable','off');
end

end %end of determining whether valid input struct
handles.OK = false;
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes AnalysisParameterEditor_new wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = AnalysisParameterEditor_new_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Process
if ~isempty(handles)
if handles.OK
    
FinalBands = get(handles.BandCalc_tab ,'Data');
FinalRatios = get(handles.RatioCalc_tab ,'Data');
%error check
if any(any(cellfun(@str2num,FinalRatios)>5) | any(cellfun(@str2num,FinalRatios)<1))
    errorstr = ['Warning: Analysis Parameter Editor >> At least one BandRatio index is <> the number of Bands.  Please Fix before continuing'];
    errordlg(errorstr,'Analysis Parameter Editor');
    return;
end
        
    handles.input.useWaitBar = get(handles.StatusBar_chk,'Value');
    handles.input.File.DSIoffset = str2double(get(handles.DSIGMT_txt ,'String'));
     List = get(handles.FIFdata_pul,'String');
    handles.input.File.FIFtype = List{get(handles.FIFdata_pul,'Value')};
    handles.input.File.FIF.assumeTemplateChOrderCorrect = get(handles.PosTempOrder_chk,'Value');
    handles.input.File.FIF.showHeadPlot = get(handles.HeadPlot_chk,'Value');
    
    handles.input.ArtifactDetection.plot = get(handles.genArtifactPlot_chk,'Value');
    handles.input.XLSoutput = get(handles.genXLSoutput_chk,'Value');%This was originally in the main gui but now need to be remaped to AnalysisStruct 
    handles.input.BioBookoutput = get(handles.genBioBook_chk,'Value');%This was originally in the main gui but now need to be remaped to AnalysisStruct 
    
     List = get(handles.Algorithm_pull,'String');
    handles.input.ArtifactDetection.algorithm = List{get(handles.Algorithm_pull,'Value')};
    handles.input.ArtifactDetection.rm2Zero = get(handles.zero_chk,'Value');
    handles.input.ArtifactDetection.DCvalue = str2double(get(handles.SimpDCThresh_txt ,'String'));
    handles.input.ArtifactDetection.RMSMultiplier = str2double(get(handles.SimpRMS_txt ,'String'));
    
     List = get(handles.FullDCCalc_pull,'String');
    handles.input.ArtifactDetection.full.DCcalculation = List{get(handles.FullDCCalc_pull,'Value')};
    handles.input.ArtifactDetection.full.DCvalue = str2double(get(handles.FullDCThresh_txt ,'String'));
    handles.input.ArtifactDetection.full.STDMultiplier = str2double(get(handles.FullScaleMult_txt ,'String'));
    handles.input.ArtifactDetection.full.minFlatSigLength = str2double(get(handles.FullFlatLen_txt ,'String'));
    handles.input.ArtifactDetection.full.dvValMultiplier = str2double(get(handles.FullSpikeMult_txt ,'String'));
    handles.input.ArtifactDetection.full.MaxDT = str2double(get(handles.FullSpikeSlope_txt ,'String'));
    handles.input.ArtifactDetection.full.MinArtifactDuration = str2double(get(handles.MinArtLen_txt ,'String'));
    handles.input.ArtifactDetection.full.CombineArtifactTimeThreshold = str2double(get(handles.MinArtGap_txt ,'String'));
    handles.input.ArtifactDetection.full.MuscleArtifactMultiplier = str2double(get(handles.FullMuscMult_txt ,'String'));
    
     List = get(handles.SpectMeth_pull,'String');
    handles.input.SpectralAnalysis.SPTmethod = List{get(handles.SpectMeth_pull,'Value')};
     List = get(handles.SpectWindow_pull,'String');
    handles.input.SpectralAnalysis.WindowType = List{get(handles.SpectWindow_pull,'Value')};
    handles.input.SpectralAnalysis.FinalFreqResolution = str2double(get(handles.SpectFinalFreq_txt ,'String'));
    handles.input.SpectralAnalysis.FinalTimeResolution = str2double(get(handles.SpectFinalTime_txt ,'String'));

     List = get(handles.FFTwinSize_pul,'String');
    handles.input.SpectralAnalysis.FFTWindowSizeMethod = List{get(handles.FFTwinSize_pul,'Value')};
    if strcmpi(handles.input.SpectralAnalysis.FFTWindowSizeMethod,'manual');
        handles.input.SpectralAnalysis.FFTWindowSize = str2double(get(handles.ManualFFTwinSize_txt ,'String'));
    else
        handles.input.SpectralAnalysis.FFTWindowSize = [];    
    end
     List = get(handles.FFTMeanWin_pul,'String');
    if strcmpi(List{get(handles.FFTMeanWin_pul,'Value')},'mean')
        handles.input.SpectralAnalysis.nanMean = true;
    else
        handles.input.SpectralAnalysis.nanMean = false;
    end
    handles.input.SpectralAnalysis.normSpectaTotalPower = get(handles.normPower_chk ,'Value');
    
    %%%%%%%NEW with new GUI%%%%%%%%%%%%
    for curBand = 1:length(handles.input.SpectralAnalysis.SpectralBands)
        handles.input.SpectralAnalysis.SpectralBands(curBand).Start = str2num(FinalBands{curBand,1});
        handles.input.SpectralAnalysis.SpectralBands(curBand).Stop = str2num(FinalBands{curBand,2});
    end
    for curRatio = 1:length(handles.input.SpectralAnalysis.SpectralRatio)
        handles.input.SpectralAnalysis.SpectralRatio(curRatio).num = str2num(FinalRatios{curRatio,1});
        handles.input.SpectralAnalysis.SpectralRatio(curRatio).den = str2num(FinalRatios{curRatio,2});
    end
    
    handles.input.Scoring.doSomnogramReport = get(handles.doSomnoReport_chk,'Value');
    handles.input.StatsTable.doMeanBaseline = get(handles.doMeanBaseline_chk,'Value');
    handles.input.StatsTable.BaselineMeanTimeStart = str2double(get(handles.BaselineMeanTimeStart_txt ,'String'));
    handles.input.StatsTable.BaselineMeanTimeEnd = str2double(get(handles.BaselineMeanTimeEnd_txt ,'String'));
    %%%%%%%%%%%%%%%%%%%%
    
    handles.input.Scoring.useGlobalEpoch = get(handles.SomnoStageSize_chk,'Value');
    if handles.input.Scoring.useGlobalEpoch
       handles.input.rules.minStateLength = handles.input.SpectralAnalysis.FinalTimeResolution; 
    else
       handles.input.rules.minStateLength = str2double(get(handles.SomnoStageSize_txt ,'String')); %<< check this << Scoring.StageEpoch
    end
    handles.input.rules.minStateLength = str2double(get(handles.SomnoStageSize_txt ,'String')); %<< check this << Scoring.StageEpoch
     List = get(handles.SomnoMeth_pul,'String');
    handles.input.Scoring.ScoringType = List{get(handles.SomnoMeth_pul,'Value')};
    handles.input.Scoring.zDeltaThreshold = str2double(get(handles.zDelta_txt ,'String'));
    handles.input.rules.ApplyArchitectureRules = get(handles.SomnoArchRules_chk,'Value');
    handles.input.rules.SWS2.PercentOfStageEpoch = str2double(get(handles.SWS2thresh_txt ,'String'));
    handles.input.rules.SWS1.PercentOfStageEpoch = str2double(get(handles.SWS1thresh_txt ,'String'));
    handles.input.rules.QW.PercentOfStageEpoch = str2double(get(handles.QWthresh_txt ,'String'));
    handles.input.rules.AW.PercentOfStageEpoch = str2double(get(handles.AWthresh_txt ,'String'));
    handles.input.rules.PS.PercentOfStageEpoch = str2double(get(handles.PSthresh_txt ,'String'));
    handles.input.Scoring.plot = get(handles.SomnoPlot_chk,'Value');
    
    %If rules are not applied, assign scoring interval to Stage epoch 
if ~handles.input.rules.ApplyArchitectureRules
    handles.input.Scoring.StageEpoch = handles.input.rules.minStateLength;
end 
end
% Get default command line output from handles structure
varargout{1} = handles.input;
varargout{2} = handles.OK; %status of button click
delete(handles.figure1);
else
    %figure was deleted (x'd out)
    varargout{1} = handles;
    varargout{2} = false;
end


% --- Executes on button press in OK_but.
function OK_but_Callback(hObject, eventdata, handles)
% hObject    handle to OK_but (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
status = guiErrorCheck(handles);
if ~status
    return;
end
handles.OK = true;
guidata(hObject, handles);
uiresume(handles.figure1);

% --- Executes on button press in Cancel_but.
function Cancel_but_Callback(hObject, eventdata, handles)
% hObject    handle to Cancel_but (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
guidata(hObject, handles);
uiresume(handles.figure1);

% --- Executes on selection change in SpectMeth_pull.
function SpectMeth_pull_Callback(hObject, eventdata, handles)
% hObject    handle to SpectMeth_pull (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns SpectMeth_pull contents as cell array
%        contents{get(hObject,'Value')} returns selected item from SpectMeth_pull
List = get(handles.SpectMeth_pull,'String');
if ~strcmpi(List(get(handles.SpectMeth_pull,'Value')),'welch')
    %Turn All children inactive
    set(handles.SpectWindow_stxt,'Enable','off');
    set(handles.SpectWindow_pull,'Enable','off');
else
    set(handles.SpectWindow_stxt,'Enable','on');
    set(handles.SpectWindow_pull,'Enable','on');
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function SpectMeth_pull_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SpectMeth_pull (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in SpectWindow_pull.
function SpectWindow_pull_Callback(hObject, eventdata, handles)
% hObject    handle to SpectWindow_pull (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns SpectWindow_pull contents as cell array
%        contents{get(hObject,'Value')} returns selected item from SpectWindow_pull


% --- Executes during object creation, after setting all properties.
function SpectWindow_pull_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SpectWindow_pull (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function SpectFinalFreq_txt_Callback(hObject, eventdata, handles)
% hObject    handle to SpectFinalFreq_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SpectFinalFreq_txt as text
%        str2double(get(hObject,'String')) returns contents of SpectFinalFreq_txt as a double


% --- Executes during object creation, after setting all properties.
function SpectFinalFreq_txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SpectFinalFreq_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function SpectFinalTime_txt_Callback(hObject, eventdata, handles)
% hObject    handle to SpectFinalTime_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SpectFinalTime_txt as text
%        str2double(get(hObject,'String')) returns contents of SpectFinalTime_txt as a double

%check if Sleep scoring is dependent on this value
if get(handles.SomnoStageSize_chk,'value')
    set(handles.SomnoStageSize_txt,'string',get(hObject,'String'));
end
if str2double(get(hObject,'String')) < str2double(get(handles.ManualFFTwinSize_txt,'string'))
    set(handles.ManualFFTwinSize_txt,'BackgroundColor','red');
else
    set(handles.ManualFFTwinSize_txt,'BackgroundColor','white');
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function SpectFinalTime_txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SpectFinalTime_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in Algorithm_pull.
function Algorithm_pull_Callback(hObject, eventdata, handles)
% hObject    handle to Algorithm_pull (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns Algorithm_pull contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Algorithm_pull

List = get(handles.Algorithm_pull,'String');
if strcmpi(List(get(handles.Algorithm_pull,'Value')),'full')
    %Turn All children inactive
    Child = get(handles.ArtDetSimp_pan,'Children');
    for n = 1:length(Child)
        set(Child(n),'Enable','off');
    end
    Child = get(handles.ArtDetFull_pan,'Children');
        for n = 1:length(Child)
        set(Child(n),'Enable','on');
        end
elseif strcmpi(List(get(handles.Algorithm_pull,'Value')),'Full -EMG')
    %Turn All children inactive
    Child = get(handles.ArtDetSimp_pan,'Children');
    for n = 1:length(Child)
        set(Child(n),'Enable','off');
    end
    Child = get(handles.ArtDetFull_pan,'Children');
        for n = 1:length(Child)
            if isempty(strfind(get(Child(n),'Tag'),'FullMuscMult'))
                set(Child(n),'Enable','on');
            else
                set(Child(n),'Enable','off');
            end
        end
else
    Child = get(handles.ArtDetFull_pan,'Children');
    for n = 1:length(Child)
        set(Child(n),'Enable','off');
    end
    Child = get(handles.ArtDetSimp_pan,'Children');
        for n = 1:length(Child)
        set(Child(n),'Enable','on');
        end
end
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function Algorithm_pull_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Algorithm_pull (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in zero_chk.
function zero_chk_Callback(hObject, eventdata, handles)
% hObject    handle to zero_chk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of zero_chk


% --- Executes on button press in plot_chk.
function plot_chk_Callback(hObject, eventdata, handles)
% hObject    handle to plot_chk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of plot_chk



function MinArtLen_txt_Callback(hObject, eventdata, handles)
% hObject    handle to MinArtLen_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MinArtLen_txt as text
%        str2double(get(hObject,'String')) returns contents of MinArtLen_txt as a double
if str2double(get(hObject,'String')) <= 0.01
    set(handles.MinArtLen_txt,'String','0.01');
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function MinArtLen_txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MinArtLen_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function MinArtGap_txt_Callback(hObject, eventdata, handles)
% hObject    handle to MinArtGap_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MinArtGap_txt as text
%        str2double(get(hObject,'String')) returns contents of MinArtGap_txt as a double
if str2double(get(hObject,'String')) <= 0.01
    set(handles.MinArtGap_txt,'String','0.01');
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function MinArtGap_txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MinArtGap_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in StatusBar_chk.
function StatusBar_chk_Callback(hObject, eventdata, handles)
% hObject    handle to StatusBar_chk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of StatusBar_chk



function SimpDCThresh_txt_Callback(hObject, eventdata, handles)
% hObject    handle to SimpDCThresh_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SimpDCThresh_txt as text
%        str2double(get(hObject,'String')) returns contents of SimpDCThresh_txt as a double
if str2double(get(hObject,'String')) <= 1
    set(handles.SimpDCThresh_txt,'String','1');
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function SimpDCThresh_txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SimpDCThresh_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function SimpRMS_txt_Callback(hObject, eventdata, handles)
% hObject    handle to SimpRMS_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SimpRMS_txt as text
%        str2double(get(hObject,'String')) returns contents of SimpRMS_txt as a double
if str2double(get(hObject,'String')) <= 0.001
    set(handles.SimpRMS_txt,'String','0.001');
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function SimpRMS_txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SimpRMS_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function FullDCThresh_txt_Callback(hObject, eventdata, handles)
% hObject    handle to FullDCThresh_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of FullDCThresh_txt as text
%        str2double(get(hObject,'String')) returns contents of FullDCThresh_txt as a double
if str2double(get(hObject,'String')) <= 0.001
    set(handles.FullDCThresh_txt,'String','0.001');
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function FullDCThresh_txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FullDCThresh_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in FullDCCalc_pull.
function FullDCCalc_pull_Callback(hObject, eventdata, handles)
% hObject    handle to FullDCCalc_pull (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns FullDCCalc_pull contents as cell array
%        contents{get(hObject,'Value')} returns selected item from FullDCCalc_pull


% --- Executes during object creation, after setting all properties.
function FullDCCalc_pull_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FullDCCalc_pull (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function FullScaleMult_txt_Callback(hObject, eventdata, handles)
% hObject    handle to FullScaleMult_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of FullScaleMult_txt as text
%        str2double(get(hObject,'String')) returns contents of FullScaleMult_txt as a double
if str2double(get(hObject,'String')) <= 0.001
    set(handles.FullScaleMult_txt,'String','0.001');
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function FullScaleMult_txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FullScaleMult_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function FullFlatLen_txt_Callback(hObject, eventdata, handles)
% hObject    handle to FullFlatLen_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of FullFlatLen_txt as text
%        str2double(get(hObject,'String')) returns contents of FullFlatLen_txt as a double
if str2double(get(hObject,'String')) <= 0.01
    set(handles.FullFlatLen_txt,'String','0.01');
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function FullFlatLen_txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FullFlatLen_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function FullSpikeMult_txt_Callback(hObject, eventdata, handles)
% hObject    handle to FullSpikeMult_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of FullSpikeMult_txt as text
%        str2double(get(hObject,'String')) returns contents of FullSpikeMult_txt as a double
if str2double(get(hObject,'String')) <= 0.001
    set(handles.FullSpikeSlope_txt,'String','0.001');
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function FullSpikeMult_txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FullSpikeMult_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function FullSpikeSlope_txt_Callback(hObject, eventdata, handles)
% hObject    handle to FullSpikeSlope_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of FullSpikeSlope_txt as text
%        str2double(get(hObject,'String')) returns contents of FullSpikeSlope_txt as a double
if str2double(get(hObject,'String')) <= 2
    set(handles.FullSpikeSlope_txt,'String','2');
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function FullSpikeSlope_txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FullSpikeSlope_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in normPower_chk.
function normPower_chk_Callback(hObject, eventdata, handles)
% hObject    handle to normPower_chk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of normPower_chk


% --- Executes on selection change in SomnoMeth_pul.
function SomnoMeth_pul_Callback(hObject, eventdata, handles)
% hObject    handle to SomnoMeth_pul (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns SomnoMeth_pul contents as cell array
%        contents{get(hObject,'Value')} returns selected item from SomnoMeth_pul

List = get(handles.SomnoMeth_pul,'String');
if ~strcmpi(List(get(handles.SomnoMeth_pul,'Value')),'delta')
    %Turn All children inactive
    Child = get(handles.zDelta_pan,'Children');
    for n = 1:length(Child)
        set(Child(n),'Enable','off');
    end
else
    Child = get(handles.zDelta_pan,'Children');
    for n = 1:length(Child)
        set(Child(n),'Enable','on');
    end
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function SomnoMeth_pul_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SomnoMeth_pul (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function SomnoStageSize_txt_Callback(hObject, eventdata, handles)
% hObject    handle to SomnoStageSize_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SomnoStageSize_txt as text
%        str2double(get(hObject,'String')) returns contents of SomnoStageSize_txt as a double
if str2double(get(hObject,'String')) <= 0
    set(handles.SomnoStageSize_txt,'String','10');
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function SomnoStageSize_txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SomnoStageSize_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in SomnoPlot_chk.
function SomnoPlot_chk_Callback(hObject, eventdata, handles)
% hObject    handle to SomnoPlot_chk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of SomnoPlot_chk


% --- Executes on button press in SomnoArchRules_chk.
function SomnoArchRules_chk_Callback(hObject, eventdata, handles)
% hObject    handle to SomnoArchRules_chk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of SomnoArchRules_chk
if ~get(hObject,'Value')
    %Turn All children inactive
    Child = get(handles.Arch_pan,'Children');
    for n = 1:length(Child)
        set(Child(n),'Enable','off');
    end
else
        Child = get(handles.Arch_pan,'Children');
        for n = 1:length(Child)
        set(Child(n),'Enable','on');
        end
end
guidata(hObject, handles);

function zDelta_txt_Callback(hObject, eventdata, handles)
% hObject    handle to zDelta_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of zDelta_txt as text
%        str2double(get(hObject,'String')) returns contents of zDelta_txt as a double
if str2double(get(hObject,'String')) <= 0
    set(handles.zDelta_txt,'String','0.1');
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function zDelta_txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to zDelta_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function DSIGMT_txt_Callback(hObject, eventdata, handles)
% hObject    handle to DSIGMT_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of DSIGMT_txt as text
%        str2double(get(hObject,'String')) returns contents of DSIGMT_txt as a double
if str2double(get(hObject,'String'))  < -12
    set(handles.DSIGMT_txt,'String','0');
elseif str2double(get(hObject,'String')) > 12
    set(handles.DSIGMT_txt,'String','0');
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function DSIGMT_txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DSIGMT_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function PSthresh_txt_Callback(hObject, eventdata, handles)
% hObject    handle to PSthresh_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of PSthresh_txt as text
%        str2double(get(hObject,'String')) returns contents of PSthresh_txt as a double
if str2double(get(hObject,'String')) < 0
    set(handles.PSthresh_txt,'String','0');
elseif str2double(get(hObject,'String')) > 100
    set(handles.PSthresh_txt,'String','100');
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function PSthresh_txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PSthresh_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function AWthresh_txt_Callback(hObject, eventdata, handles)
% hObject    handle to AWthresh_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AWthresh_txt as text
%        str2double(get(hObject,'String')) returns contents of AWthresh_txt as a double
if str2double(get(hObject,'String')) < 0
    set(handles.AWthresh_txt,'String','0');
elseif str2double(get(hObject,'String')) > 100
    set(handles.AWthresh_txt,'String','100');
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function AWthresh_txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AWthresh_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function QWthresh_txt_Callback(hObject, eventdata, handles)
% hObject    handle to QWthresh_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of QWthresh_txt as text
%        str2double(get(hObject,'String')) returns contents of QWthresh_txt as a double
if str2double(get(hObject,'String')) < 0
    set(handles.QWthresh_txt,'String','0');
elseif str2double(get(hObject,'String')) > 100
    set(handles.QWthresh_txt,'String','100');
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function QWthresh_txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to QWthresh_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function SWS1thresh_txt_Callback(hObject, eventdata, handles)
% hObject    handle to SWS1thresh_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SWS1thresh_txt as text
%        str2double(get(hObject,'String')) returns contents of SWS1thresh_txt as a double
if str2double(get(hObject,'String')) < 0
    set(handles.SWS1thresh_txt,'String','0');
elseif str2double(get(hObject,'String')) > 100
    set(handles.SWS1thresh_txt,'String','100');
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function SWS1thresh_txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SWS1thresh_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function SWS2thresh_txt_Callback(hObject, eventdata, handles)
% hObject    handle to SWS2thresh_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SWS2thresh_txt as text
%        str2double(get(hObject,'String')) returns contents of SWS2thresh_txt as a double
if str2double(get(hObject,'String')) < 0
    set(handles.SWS2thresh_txt,'String','0');
elseif str2double(get(hObject,'String')) > 100
    set(handles.SWS2thresh_txt,'String','100');
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function SWS2thresh_txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SWS2thresh_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function FullMuscMult_txt_Callback(hObject, eventdata, handles)
% hObject    handle to FullMuscMult_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of FullMuscMult_txt as text
%        str2double(get(hObject,'String')) returns contents of FullMuscMult_txt as a double


% --- Executes during object creation, after setting all properties.
function FullMuscMult_txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FullMuscMult_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Save_but.
function Save_but_Callback(hObject, eventdata, handles)
% hObject    handle to Save_but (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
status = guiErrorCheck(handles);
if ~status
    return;
end

FinalBands = get(handles.BandCalc_tab ,'Data');
FinalRatios = get(handles.RatioCalc_tab ,'Data');
%error check
if any(any(cellfun(@str2num,FinalRatios)>5) | any(cellfun(@str2num,FinalRatios)<1))
    errorstr = ['Warning: Analysis Parameter Editor >> At least one BandRatio index is <> the number of Bands.  Please Fix before continuing'];   errordlg(errorstr,'Analysis Parameter Editor');
    return;
end

%Build Struct to save
SaveXMLStruct.Version = handles.input.Version;
SaveXMLStruct.File.DSIoffset = str2double(get(handles.DSIGMT_txt ,'String'));
List = get(handles.FIFdata_pul,'String');
SaveXMLStruct.File.FIFtype = List{get(handles.FIFdata_pul,'Value')};
SaveXMLStruct.File.FIF.assumeTemplateChOrderCorrect = get(handles.PosTempOrder_chk,'Value');
SaveXMLStruct.File.FIF.showHeadPlot = get(handles.HeadPlot_chk,'Value');
SaveXMLStruct.File.useWaitBar = get(handles.StatusBar_chk,'Value');
SaveXMLStruct.File.XLSoutput = get(handles.genXLSoutput_chk,'Value');
SaveXMLStruct.File.BioBookoutput = get(handles.genBioBook_chk,'Value');

SaveXMLStruct.StatsTable.doMeanBaseline = get(handles.doMeanBaseline_chk,'Value');
SaveXMLStruct.StatsTable.BaselineMeanTimeStart = str2double(get(handles.BaselineMeanTimeStart_txt ,'String'));
SaveXMLStruct.StatsTable.BaselineMeanTimeEnd = str2double(get(handles.BaselineMeanTimeEnd_txt ,'String'));

List = get(handles.Algorithm_pull,'String');
SaveXMLStruct.ArtifactDetection.algorithm = List{get(handles.Algorithm_pull,'Value')};
SaveXMLStruct.ArtifactDetection.rm2Zero = get(handles.zero_chk,'Value');
SaveXMLStruct.ArtifactDetection.DCvalue = str2double(get(handles.SimpDCThresh_txt ,'String'));
SaveXMLStruct.ArtifactDetection.RMSMultiplier = str2double(get(handles.SimpRMS_txt ,'String'));
%Values not in GUI but maintained in Parameters file
SaveXMLStruct.ArtifactDetection.SampleRate = handles.input.ArtifactDetection.SampleRate;
SaveXMLStruct.ArtifactDetection.IndexedOutput = handles.input.ArtifactDetection.IndexedOutput;
SaveXMLStruct.ArtifactDetection.logfile = handles.input.ArtifactDetection.logfile;
SaveXMLStruct.ArtifactDetection.plot = get(handles.genArtifactPlot_chk,'Value');
%
List = get(handles.FullDCCalc_pull,'String');
SaveXMLStruct.ArtifactDetection.full.DCcalculation = List{get(handles.FullDCCalc_pull,'Value')};
SaveXMLStruct.ArtifactDetection.full.DCvalue = str2double(get(handles.FullDCThresh_txt ,'String'));
SaveXMLStruct.ArtifactDetection.full.STDMultiplier = str2double(get(handles.FullScaleMult_txt ,'String'));
SaveXMLStruct.ArtifactDetection.full.minFlatSigLength = str2double(get(handles.FullFlatLen_txt ,'String'));
SaveXMLStruct.ArtifactDetection.full.dvValMultiplier = str2double(get(handles.FullSpikeMult_txt ,'String'));
SaveXMLStruct.ArtifactDetection.full.MaxDT = str2double(get(handles.FullSpikeSlope_txt ,'String'));
SaveXMLStruct.ArtifactDetection.full.MinArtifactDuration = str2double(get(handles.MinArtLen_txt ,'String'));
SaveXMLStruct.ArtifactDetection.full.CombineArtifactTimeThreshold = str2double(get(handles.MinArtGap_txt ,'String'));
SaveXMLStruct.ArtifactDetection.full.MuscleArtifactMultiplier = str2double(get(handles.FullMuscMult_txt ,'String'));

List = get(handles.SpectMeth_pull,'String');
SaveXMLStruct.SpectralAnalysis.SPTmethod = List{get(handles.SpectMeth_pull,'Value')};
List = get(handles.SpectWindow_pull,'String');
SaveXMLStruct.SpectralAnalysis.WindowType = List{get(handles.SpectWindow_pull,'Value')};
SaveXMLStruct.SpectralAnalysis.FinalFreqResolution = str2double(get(handles.SpectFinalFreq_txt ,'String'));
SaveXMLStruct.SpectralAnalysis.FinalTimeResolution = str2double(get(handles.SpectFinalTime_txt ,'String'));

List = get(handles.FFTwinSize_pul,'String');
SaveXMLStruct.SpectralAnalysis.FFTWindowSizeMethod = List{get(handles.FFTwinSize_pul,'Value')};
if strcmpi(SaveXMLStruct.SpectralAnalysis.FFTWindowSizeMethod,'manual');
    SaveXMLStruct.SpectralAnalysis.FFTWindowSize = str2double(get(handles.ManualFFTwinSize_txt ,'String'));
else
    SaveXMLStruct.SpectralAnalysis.FFTWindowSize = [];
end
List = get(handles.FFTMeanWin_pul,'String');
if strcmpi(List{get(handles.FFTMeanWin_pul,'Value')},'mean')
    SaveXMLStruct.SpectralAnalysis.nanMean = true;
else
    SaveXMLStruct.SpectralAnalysis.nanMean = false;
end

SaveXMLStruct.SpectralAnalysis.FFTWindowOverlap = handles.input.SpectralAnalysis.FFTWindowOverlap; %Values not in GUI but maintained in Parameters file
SaveXMLStruct.SpectralAnalysis.TimeBW = handles.input.SpectralAnalysis.TimeBW; %Values not in GUI but maintained in Parameters file
%Values not in GUI but maintained in Parameters file
for curBand = 1:length(handles.input.SpectralAnalysis.SpectralBands)
    SaveXMLStruct.SpectralAnalysis.SpectralBands(curBand).Start = str2num(FinalBands{curBand,1});
    SaveXMLStruct.SpectralAnalysis.SpectralBands(curBand).Stop = str2num(FinalBands{curBand,2});
end
for curRatio = 1:length(handles.input.SpectralAnalysis.SpectralRatio)
    SaveXMLStruct.SpectralAnalysis.SpectralRatio(curRatio).num = str2num(FinalRatios{curRatio,1});
    SaveXMLStruct.SpectralAnalysis.SpectralRatio(curRatio).den = str2num(FinalRatios{curRatio,2});
end

%
SaveXMLStruct.SpectralAnalysis.normSpectaTotalPower = get(handles.normPower_chk ,'Value');
%handles.input.SpectralAnalysis.logfile %not saved and likely not necessarry
%handles.input.SpectralAnalysis.Freqs
SaveXMLStruct.SpectralAnalysis.nanDC = handles.input.SpectralAnalysis.nanDC;

%Scoring
List = get(handles.SomnoMeth_pul,'String');
SaveXMLStruct.Scoring.ScoringType = List{get(handles.SomnoMeth_pul,'Value')};
SaveXMLStruct.Scoring.FFTEpoch = handles.input.Scoring.FFTEpoch;
SaveXMLStruct.Scoring.WinOffset = handles.input.Scoring.WinOffset;
SaveXMLStruct.Scoring.HzDiv = handles.input.Scoring.HzDiv;
SaveXMLStruct.Scoring.useGlobalEpoch = get(handles.SomnoStageSize_chk ,'Value');
%If rules are not applied, assign scoring interval to Stage epoch
if ~handles.input.rules.ApplyArchitectureRules
    SaveXMLStruct.Scoring.StageEpoch = handles.input.rules.minStateLength;
end
SaveXMLStruct.Scoring.zDeltaThreshold = str2double(get(handles.zDelta_txt ,'String'));
SaveXMLStruct.Scoring.FFTvalidData = handles.input.Scoring.FFTvalidData;
SaveXMLStruct.Scoring.plot = get(handles.SomnoPlot_chk,'Value');
SaveXMLStruct.Scoring.doSomnogramReport = get(handles.doSomnoReport_chk ,'Value');
SaveXMLStruct.Scoring.useGMMinit = handles.input.Scoring.useGMMinit;
SaveXMLStruct.Scoring.GMMclust = handles.input.Scoring.GMMclust;

SaveXMLStruct.rules.ApplyArchitectureRules = get(handles.SomnoArchRules_chk,'Value');
SaveXMLStruct.rules.SWS2.PercentOfStageEpoch = str2double(get(handles.SWS2thresh_txt ,'String'));
SaveXMLStruct.rules.SWS1.PercentOfStageEpoch = str2double(get(handles.SWS1thresh_txt ,'String'));
SaveXMLStruct.rules.QW.PercentOfStageEpoch = str2double(get(handles.QWthresh_txt ,'String'));
SaveXMLStruct.rules.AW.PercentOfStageEpoch = str2double(get(handles.AWthresh_txt ,'String'));
SaveXMLStruct.rules.PS.PercentOfStageEpoch = str2double(get(handles.PSthresh_txt ,'String'));
SaveXMLStruct.rules.UNK = handles.input.rules.UNK;
SaveXMLStruct.rules.minStateLength = str2double(get(handles.SomnoStageSize_txt ,'String')); %<< check this << Scoring.StageEpoch

[fn, path] = uiputfile({'*.xml','NexStep Biomarkers Parameter Files (*.xml)';'*.*',  'All Files (*.*)'},'Save the parameter file');
if ischar(path)
    warning('off', 'MATLAB:pfileOlderThanMfile')
    try
        if handles.input.MatlabPost2014
            errorstr = ['info:Analysis Parameter Editor >> Using tinyxml2_wrap'];
            if ~isempty(handles.input.LogFile)
                NSBlog(handles.input.LogFile,errorstr);
            end
            tinyxml2_wrap('save', fullfile(path,fn), SaveXMLStruct);
        else
            xml_save( fullfile(path,fn), SaveXMLStruct );
        end
        helpdlg({'Successfully Saved:',fullfile(path,fn)},'Save Parameter File');
    catch me
        errordlg({'Unknown Error During Save:',fullfile(path,fn)},'Save Parameter File');
        errorstr = ['ERROR:Analysis Parameter Editor >> ',me.message];
        if ~isempty(handles.input.LogFile)
             NSBlog(handles.input.LogFile,errorstr);
        end
    end
else
    errorstr = ['Warning: Analysis Parameter Editor >> Parameters were not saved'];
    if ~isempty(handles.input.LogFile)
        NSBlog(handles.input.LogFile,errorstr);
    else
        errordlg(errorstr,'Analysis Parameter Editor');
    end
end


% --- Executes on selection change in SpectBin_pull.
function SpectBin_pull_Callback(hObject, eventdata, handles)
% hObject    handle to SpectBin_pull (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns SpectBin_pull contents as cell array
%        contents{get(hObject,'Value')} returns selected item from SpectBin_pull


% --- Executes during object creation, after setting all properties.
function SpectBin_pull_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SpectBin_pull (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function SpectBinSize_txt_Callback(hObject, eventdata, handles)
% hObject    handle to SpectBinSize_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SpectBinSize_txt as text
%        str2double(get(hObject,'String')) returns contents of SpectBinSize_txt as a double


% --- Executes during object creation, after setting all properties.
function SpectBinSize_txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SpectBinSize_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in SpectBinCombine_pull.
function SpectBinCombine_pull_Callback(hObject, eventdata, handles)
% hObject    handle to SpectBinCombine_pull (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns SpectBinCombine_pull contents as cell array
%        contents{get(hObject,'Value')} returns selected item from SpectBinCombine_pull


% --- Executes during object creation, after setting all properties.
function SpectBinCombine_pull_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SpectBinCombine_pull (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in genXLSoutput_chk.
function genXLSoutput_chk_Callback(hObject, eventdata, handles)
% hObject    handle to genXLSoutput_chk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of genXLSoutput_chk


% --- Executes on button press in genBioBookoutput_chk.
function genBioBookoutput_chk_Callback(hObject, eventdata, handles)
% hObject    handle to genBioBookoutput_chk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of genBioBookoutput_chk


% --- Executes on selection change in FFTwinSize_pul.
function FFTwinSize_pul_Callback(hObject, eventdata, handles)
% hObject    handle to FFTwinSize_pul (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns FFTwinSize_pul contents as cell array
%        contents{get(hObject,'Value')} returns selected item from FFTwinSize_pul

List = get(handles.FFTwinSize_pul,'String');
if strcmpi(List(get(handles.FFTwinSize_pul,'Value')),'Auto')
    set(handles.ManualFFTwinSize_stxt,'Enable','off');
    set(handles.ManualFFTwinSize_txt,'Enable','off');      
elseif strcmpi(List(get(handles.FFTwinSize_pul,'Value')),'Manual')
    set(handles.ManualFFTwinSize_stxt,'Enable','on');
    set(handles.ManualFFTwinSize_txt,'Enable','on'); 
else
    set(handles.ManualFFTwinSize_stxt,'Enable','on');
    set(handles.ManualFFTwinSize_txt,'Enable','on'); 
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function FFTwinSize_pul_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FFTwinSize_pul (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ManualFFTwinSize_txt_Callback(hObject, eventdata, handles)
% hObject    handle to ManualFFTwinSize_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ManualFFTwinSize_txt as text
%        str2double(get(hObject,'String')) returns contents of ManualFFTwinSize_txt as a double
if str2double(get(hObject,'String')) > str2double(get(handles.SpectFinalTime_txt,'string'))
    set(handles.ManualFFTwinSize_txt,'BackgroundColor','red');
else
    set(handles.ManualFFTwinSize_txt,'BackgroundColor','white');
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function ManualFFTwinSize_txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ManualFFTwinSize_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in FFTMeanWin_pul.
function FFTMeanWin_pul_Callback(hObject, eventdata, handles)
% hObject    handle to FFTMeanWin_pul (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns FFTMeanWin_pul contents as cell array
%        contents{get(hObject,'Value')} returns selected item from FFTMeanWin_pul


% --- Executes during object creation, after setting all properties.
function FFTMeanWin_pul_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FFTMeanWin_pul (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in FIFdata_pul.
function FIFdata_pul_Callback(hObject, eventdata, handles)
% hObject    handle to FIFdata_pul (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns FIFdata_pul contents as cell array
%        contents{get(hObject,'Value')} returns selected item from FIFdata_pul


% --- Executes during object creation, after setting all properties.
function FIFdata_pul_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FIFdata_pul (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in genBioBook_chk.
function genBioBook_chk_Callback(hObject, eventdata, handles)
% hObject    handle to genBioBook_chk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of genBioBook_chk


% --- Executes on button press in SomnoStageSize_chk.
function SomnoStageSize_chk_Callback(hObject, eventdata, handles)
% hObject    handle to SomnoStageSize_chk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of SomnoStageSize_chk
if get(hObject,'Value')
    %copy final time resolution and dim
    set(handles.SomnoStageSize_txt,'String', get(handles.SpectFinalTime_txt,'String') );
    set(handles.SomnoStageSize_stxt,'Enable','off'); 
    set(handles.SomnoStageSize_txt,'Enable','off');
else
    set(handles.SomnoStageSize_txt,'String', num2str(handles.input.rules.minStateLength));
    set(handles.SomnoStageSize_stxt,'Enable','on'); 
    set(handles.SomnoStageSize_txt,'Enable','on');
end
guidata(hObject, handles);

% --- Executes on button press in genArtifactPlot_chk.
function genArtifactPlot_chk_Callback(hObject, eventdata, handles)
% hObject    handle to genArtifactPlot_chk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of genArtifactPlot_chk

function status = guiErrorCheck(handles)
status = true;
%Beyond this accumulate errors in cell array and display
if str2double(get(handles.ManualFFTwinSize_txt,'String')) > str2double(get(handles.SpectFinalTime_txt,'string'))
    errordlg('Spectral manual window size must be less than final time resolution','Analysis Parameter Editor','modal');
    status = false;
end


% --- Executes on button press in HeadPlot_chk.
function HeadPlot_chk_Callback(hObject, eventdata, handles)
% hObject    handle to HeadPlot_chk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of HeadPlot_chk


% --- Executes on button press in PosTempOrder_chk.
function PosTempOrder_chk_Callback(hObject, eventdata, handles)
% hObject    handle to PosTempOrder_chk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of PosTempOrder_chk


% --- Executes on button press in doSomnoReport_chk.
function doSomnoReport_chk_Callback(hObject, eventdata, handles)
% hObject    handle to doSomnoReport_chk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of doSomnoReport_chk



function BaselineMeanTimeEnd_txt_Callback(hObject, eventdata, handles)
% hObject    handle to BaselineMeanTimeEnd_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of BaselineMeanTimeEnd_txt as text
%        str2double(get(hObject,'String')) returns contents of BaselineMeanTimeEnd_txt as a double


% --- Executes during object creation, after setting all properties.
function BaselineMeanTimeEnd_txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BaselineMeanTimeEnd_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function BaselineMeanTimeStart_txt_Callback(hObject, eventdata, handles)
% hObject    handle to BaselineMeanTimeStart_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of BaselineMeanTimeStart_txt as text
%        str2double(get(hObject,'String')) returns contents of BaselineMeanTimeStart_txt as a double

% --- Executes during object creation, after setting all properties.
function BaselineMeanTimeStart_txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BaselineMeanTimeStart_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in doMeanBaseline_chk.
function doMeanBaseline_chk_Callback(hObject, eventdata, handles)
% hObject    handle to doMeanBaseline_chk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of doMeanBaseline_chk
if get(hObject,'Value')
    set(handles.BaselineMeanTimeStart_stxt,'Enable','on'); 
    set(handles.BaselineMeanTimeStart_txt,'Enable','on');
    set(handles.BaselineMeanTimeEnd_stxt,'Enable','on'); 
    set(handles.BaselineMeanTimeEnd_txt,'Enable','on');
else
    set(handles.BaselineMeanTimeStart_stxt,'Enable','off'); 
    set(handles.BaselineMeanTimeStart_txt,'Enable','off');
    set(handles.BaselineMeanTimeEnd_stxt,'Enable','off'); 
    set(handles.BaselineMeanTimeEnd_txt,'Enable','off');
end
guidata(hObject, handles);


% --- Executes on button press in GenParm_but.
function GenParm_but_Callback(hObject, eventdata, handles)
% hObject    handle to GenParm_but (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.GenParm_pan,'Visible','on');
set(handles.ArtDet_pan,'Visible','off');
set(handles.SpectDet_pan,'Visible','off');
set(handles.Somnogram_pan,'Visible','off');
guidata(hObject, handles);
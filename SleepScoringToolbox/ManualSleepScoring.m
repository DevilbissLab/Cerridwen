function varargout = ManualSleepScoring(varargin)
% MANUALSLEEPSCORING MATLAB code for ManualSleepScoring.fig
%      MANUALSLEEPSCORING, by itself, creates a new MANUALSLEEPSCORING or raises the existing
%      singleton*.
%
%      H = MANUALSLEEPSCORING returns the handle to a new MANUALSLEEPSCORING or the handle to
%      the existing singleton*.
%
%      MANUALSLEEPSCORING('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MANUALSLEEPSCORING.M with the given input arguments.
%
%      MANUALSLEEPSCORING('Property','Value',...) creates a new MANUALSLEEPSCORING or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ManualSleepScoring_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ManualSleepScoring_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ManualSleepScoring

% Last Modified by GUIDE v2.5 20-Nov-2013 15:53:21

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ManualSleepScoring_OpeningFcn, ...
                   'gui_OutputFcn',  @ManualSleepScoring_OutputFcn, ...
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


% --- Executes just before ManualSleepScoring is made visible.
function ManualSleepScoring_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ManualSleepScoring (see VARARGIN)

%ManualSleepScoring
%Expected I/O is: 
%status = ManualSleepScoring(EEG, EMG, Activity, options)
% Each Variable is normally a vector but can contain a column matrix with
% each channel as a column
% options
%   options.ChNames.EEG (cell
%   options.ChNames.EMG (cell
%   options.ChNames.Activity (cell
%   options.Hypnogram

switch length(varargin)
    case 0
        
    case 1
        
    case 2
        
    case 3
        if isnumeric(varargin{1})
            handles.data.EEG = varargin{1};
        end
        if isnumeric(varargin{2})
            handles.data.EMG = varargin{2};
        end
        if isnumeric(varargin{3})
            handles.data.Activity = varargin{3};
        end
        if isstruct(varargin{4})
            handles.options = varargin{4};
        end
        if isempty(handles.options.ChNames)
            handles.options.ChNames = {'Channel 1','Channel 2','Channel 3','Hypnogram'};
        else
        if iscell(handles.options.ChNames)
                handles.options.ChNames = handles.options.ChNames(:);
                handles.options.ChNames = [handles.options.ChNames; {'Hypnogram'}];
        end
        end
    case 4
        
        
    otherwise
        
end
    set(handles.axes1_pull,'String',handles.options.ChNames);
    set(handles.axes2_pull,'String',handles.options.ChNames);
    set(handles.axes3_pull,'String',handles.options.ChNames);
    set(handles.axes4_pull,'String',handles.options.ChNames);

    h(1) = plot(handles.axes1, handles.data.EEG);
    h(2) = plot(handles.axes2, handles.data.EMG);
    h(3) = plot(handles.axes3, handles.data.Activity);
    h(4) = plot(handles.axes4, handles.data.Hypnogram);
    linkaxes(h,'x');
    
    
% Choose default command line output for ManualSleepScoring
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ManualSleepScoring wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = ManualSleepScoring_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on slider movement.
function time_sli_Callback(hObject, eventdata, handles)
% hObject    handle to time_sli (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
disp('')

% --- Executes during object creation, after setting all properties.
function time_sli_CreateFcn(hObject, eventdata, handles)
% hObject    handle to time_sli (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function Gain_sli_Callback(hObject, eventdata, handles)
% hObject    handle to Gain_sli (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function Gain_sli_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Gain_sli (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on selection change in axes1_pull.
function axes1_pull_Callback(hObject, eventdata, handles)
% hObject    handle to axes1_pull (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns axes1_pull contents as cell array
%        contents{get(hObject,'Value')} returns selected item from axes1_pull


% --- Executes during object creation, after setting all properties.
function axes1_pull_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes1_pull (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in axes2_pull.
function axes2_pull_Callback(hObject, eventdata, handles)
% hObject    handle to axes2_pull (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns axes2_pull contents as cell array
%        contents{get(hObject,'Value')} returns selected item from axes2_pull


% --- Executes during object creation, after setting all properties.
function axes2_pull_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes2_pull (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in axes3_pull.
function axes3_pull_Callback(hObject, eventdata, handles)
% hObject    handle to axes3_pull (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns axes3_pull contents as cell array
%        contents{get(hObject,'Value')} returns selected item from axes3_pull


% --- Executes during object creation, after setting all properties.
function axes3_pull_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes3_pull (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in axes4_pull.
function axes4_pull_Callback(hObject, eventdata, handles)
% hObject    handle to axes4_pull (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns axes4_pull contents as cell array
%        contents{get(hObject,'Value')} returns selected item from axes4_pull


% --- Executes during object creation, after setting all properties.
function axes4_pull_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes4_pull (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

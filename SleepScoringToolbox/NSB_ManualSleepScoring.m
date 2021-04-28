function varargout = NSB_ManualSleepScoring(varargin)
% NSB_ManualSleepScoring
% Visual editor of sleep scoring. This function reads a Neuroexplorer file
% and plots intervals with names matching : 'desynch' 'intermed' 'synch'.
%
% To edit scoring, click and drag the scored state to a new state. You can 
% also click and drag the start or end time of an interval. 
%
% Usage:
%  >> NSB_ManualSleepScoring(filename)
%
% Inputs:
%   filename    - Filename of path+name to be opened (optional);
%
% Outputs:
%   none.
%
% Requires the accompaning NSB_ManualSleepScoring.fig
%
% version. 1.0 DMD 1Aug2014
%
% Copyright (c) 2014 by David Devilbiss <david.devilbiss@NexStepBiomarkers.com>
% 
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
% 
% The above copyright notice and this permission notice shall be included in
% all copies or substantial portions of the Software.
% 
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
% THE SOFTWARE.


% Last Modified by GUIDE v2.5 10-Aug-2014 14:16:01

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @NSB_ManualSleepScoring_OpeningFcn, ...
    'gui_OutputFcn',  @NSB_ManualSleepScoring_OutputFcn, ...
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


% --- Executes just before NSB_ManualSleepScoring is made visible.
function NSB_ManualSleepScoring_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to NSB_ManualSleepScoring (see VARARGIN)
switch length(varargin)
    case 0
        [FileName,PathName,FilterIndex] = uigetfile({'*.nex','Neuroexplorer File (*.nex)';'*.dat','Rat Physio File (*.dat)'},'Select Neuroexplorer File To Be Scored');
        if FileName == 0
            errordlg('NSB_ManualSleepScoring function terminating. No file selected','NSB_ManualSleepScoring');
            close(handles.figure1);
            return;
        end
        handles.NexStruct = fullreadNexFile(fullfile(PathName,FileName));
        handles.NexStruct.filename = fullfile(PathName,FileName);
    case 1
        if ischar(varargin{1})
            [PathName, FileName,FileExt] = fileparts(varargin{1});
            FileName = [FileName,'.nex'];
            handles.NexStruct = fullreadNexFile(fullfile(varargin{1}));
            handles.NexStruct.filename = fullfile(varargin{1});
        end
    case 2
        FileName = '';
    case 3
        if ischar(varargin{1})
            [PathName, FileName,FileExt] = fileparts(varargin{1});
            FileName = [FileName,'.nex'];
            handles.NexStruct = fullreadNexFile(fullfile(varargin{1}));
            handles.NexStruct.filename = fullfile(varargin{1});
        end
end

handles.isTracking_L = false;
handles.isTracking_R = false;

%select Channel to EEG score
contVarStruct = [handles.NexStruct.contvars{:}];
ADnames = {contVarStruct.name};


%loop Through and pick one with the greatest
rms = [];
for curChan = 1:length(ADnames)
    chanNum = find(strcmp({contVarStruct.name},ADnames{curChan}));
    rms(curChan) = sqrt(mean(handles.NexStruct.contvars{chanNum}.data.^2));
end
rmsIDX = find(rms == max(rms),1,'first');
set(handles.chan_pul,'String',ADnames, 'Value', rmsIDX);


ts = 0:(1/handles.NexStruct.contvars{rmsIDX}.ADFrequency): (length(handles.NexStruct.contvars{rmsIDX}.data)/handles.NexStruct.contvars{rmsIDX}.ADFrequency);
for curFrag = 1:length(handles.NexStruct.contvars{rmsIDX}.fragmentStarts)
    if curFrag < length(handles.NexStruct.contvars{rmsIDX}.fragmentStarts)
        ts(handles.NexStruct.contvars{rmsIDX}.fragmentStarts(curFrag):handles.NexStruct.contvars{rmsIDX}.fragmentStarts(curFrag+1)-1) = ...
            handles.NexStruct.contvars{rmsIDX}.timestamps(curFrag) + ts(handles.NexStruct.contvars{rmsIDX}.fragmentStarts(curFrag):handles.NexStruct.contvars{rmsIDX}.fragmentStarts(curFrag+1)-1);
    else
        ts(handles.NexStruct.contvars{rmsIDX}.fragmentStarts(curFrag):end) = ...
            handles.NexStruct.contvars{rmsIDX}.timestamps(curFrag) + ts(handles.NexStruct.contvars{rmsIDX}.fragmentStarts(curFrag):end);
    end
end
ts(end) = [];

handles.PlotWin.Start = 0; %sec
handles.PlotWin.StartIDX = 1;
handles.PlotWin.Stop = 60;
handles.PlotWin.StopIDX = 60 * handles.NexStruct.contvars{rmsIDX}.ADFrequency;
handles.PlotWin.Max = ts(end);
handles.PlotWin.Length = 60;

plot(handles.trace_axes, ts, handles.NexStruct.contvars{rmsIDX}.data);
ylabel(handles.trace_axes, ADnames{rmsIDX});
grid(handles.trace_axes);
set(handles.trace_axes, 'Xlim', [handles.PlotWin.Start, handles.PlotWin.Stop]);
set(handles.trace_axes,'XTick',[])

intVarStruct = [handles.NexStruct.intervals{:}];
INTnames = {intVarStruct.name};
desynchIDX = find( strcmpi(INTnames,'desynch'));
intermedIDX = find(  strcmpi(INTnames,'intermed') );
syncIDX = find( strcmpi(INTnames,'synch'));
scoreIDX = [syncIDX intermedIDX desynchIDX]; %sleep to waking (this could be expanded to total staes)

set(handles.figure1,'WindowButtonUpFcn',@StopDragFcn);
colors = get(gca,'ColorOrder');

INTIDX = 0;
for curINTvar = 1:length(scoreIDX)
    handles.Archetecture(curINTvar).name = INTnames(scoreIDX(curINTvar)); %labels in order
    handles.Archetecture(curINTvar).NexStructIDX = scoreIDX(curINTvar);
    
    for curINT = 1:length(handles.NexStruct.intervals{scoreIDX(curINTvar)}.intStarts)
        INTIDX = INTIDX +1;
        %draw and assign line handle to interval
        handles.Scoring(INTIDX) = line( [handles.NexStruct.intervals{scoreIDX(curINTvar)}.intStarts(curINT), handles.NexStruct.intervals{scoreIDX(curINTvar)}.intEnds(curINT)],...
            [curINTvar,curINTvar],'Parent',handles.score_axes, 'Marker','v','MarkerSize',3,'MarkerEdgeColor','k','Color',colors(curINTvar,:),'linewidth',2,'ButtonDownFcn',@StartDragFcn);
    end
end

if ~isempty(curINTvar)
    set(handles.score_axes, 'YLim', [0 curINTvar+1], 'YTick', [1:curINTvar], 'YTickLabel', INTnames(scoreIDX));
else
    disp('Warning >> No current Scoring avalable in File');
end

linkaxes([handles.trace_axes handles.score_axes], 'x');


%set View of time plot
WinViewPct = (handles.PlotWin.Length * handles.NexStruct.contvars{rmsIDX}.ADFrequency) / length(handles.NexStruct.contvars{rmsIDX}.data);
bigTimeStep = WinViewPct*10;
if bigTimeStep > 1
    bigTimeStep = 1;
end
set(handles.timeWinSet_slide,'Min',0,'Max',ceil(length(handles.NexStruct.contvars{rmsIDX}.data)),'Value',0,...
    'SliderStep',[WinViewPct bigTimeStep]); %dynamic steps

uicontrol(handles.timeWinSet_slide);


% Choose default command line output for NSB_ManualSleepScoring
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes NSB_ManualSleepScoring wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = NSB_ManualSleepScoring_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
try,
varargout{1} = handles.output;
end

% --- Executes on button press in cancel_but.
function cancel_but_Callback(hObject, eventdata, handles)
% hObject    handle to cancel_but (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(handles.figure1);

% --- Executes on button press in Save_but.
function Save_but_Callback(hObject, eventdata, handles)
% hObject    handle to Save_but (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[FileName,PathName,FilterIndex] = uiputfile( {'*.nex','Neuroexplorer Files';...
    '*.*','All Files' },'Save Scored File',handles.NexStruct.filename);
if ~isnumeric(FileName)
    handles.SaveFilename = fullfile(PathName,FileName);
    %update NexStruct with Currnet states
    handles = updateNexStruct(handles);
    [status] = NSB_NEXwriter(handles.NexStruct, handles.SaveFilename);
    if status
        msgbox({handles.SaveFilename,' Successfully written'}, 'File Writer Information','help');
    else
        disp('ERROR >> Nex File not written properly!');
    end
else
    disp('Warning >> File not saved (user canceled operation)');
end

% --- Executes on selection change in chan_pul.
function chan_pul_Callback(hObject, eventdata, handles)
% hObject    handle to chan_pul (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

curChan = get(hObject,'Value');
set(get(handles.trace_axes,'Children'), 'YData', handles.NexStruct.contvars{curChan}.data );

% Hints: contents = cellstr(get(hObject,'String')) returns chan_pul contents as cell array
%        contents{get(hObject,'Value')} returns selected item from chan_pul


% --- Executes during object creation, after setting all properties.
function chan_pul_CreateFcn(hObject, eventdata, handles)
% hObject    handle to chan_pul (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function timeWinSet_slide_Callback(hObject, eventdata, handles)
% hObject    handle to timeWinSet_slide (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
chanIDX = get(handles.chan_pul,'Value');
%updateplots
handles.PlotWin.StartIDX = floor(get(handles.timeWinSet_slide,'Value'));
handles.PlotWin.Start = handles.PlotWin.StartIDX/handles.NexStruct.contvars{chanIDX}.ADFrequency;
handles.PlotWin.StopIDX = handles.PlotWin.StartIDX + str2double(get(handles.view_txt,'String'))*handles.NexStruct.contvars{chanIDX}.ADFrequency;
handles.PlotWin.Stop = handles.PlotWin.StopIDX/handles.NexStruct.contvars{chanIDX}.ADFrequency;

if handles.PlotWin.Start >=  handles.PlotWin.Max || handles.PlotWin.Stop >=  handles.PlotWin.Max
    handles.PlotWin.Stop = handles.PlotWin.Max;
    handles.PlotWin.StopIDX = length(handles.NexStruct.contvars{chanIDX}.data);
    handles.PlotWin.StartIDX = handles.PlotWin.StopIDX - handles.PlotWin.Length * handles.NexStruct.contvars{chanIDX}.ADFrequency;
    handles.PlotWin.Start = handles.PlotWin.Stop - handles.PlotWin.Length;
end
%set Time Plot
set(handles.trace_axes,'XLim',[handles.PlotWin.Start handles.PlotWin.Stop]);


% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function timeWinSet_slide_CreateFcn(hObject, eventdata, handles)
% hObject    handle to timeWinSet_slide (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function view_txt_Callback(hObject, eventdata, handles)
% hObject    handle to view_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.PlotWin.Length = str2double(get(hObject,'String'));
chanIDX = get(handles.chan_pul,'Value');

curView = get(handles.trace_axes,'XLim');
set(handles.trace_axes,'XLim', [curView(1), curView(1)+handles.PlotWin.Length ]);

%set View of time slider
WinViewPct = (handles.PlotWin.Length * handles.NexStruct.contvars{chanIDX}.ADFrequency) / length(handles.NexStruct.contvars{chanIDX}.data);
bigTimeStep = WinViewPct*10;
if bigTimeStep > 1
    bigTimeStep = 1;
end
set(handles.timeWinSet_slide,'SliderStep',[WinViewPct bigTimeStep]); %dynamic steps

% --- Executes during object creation, after setting all properties.
function view_txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to view_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in up_but.
function up_but_Callback(hObject, eventdata, handles)
% hObject    handle to up_but (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
yRange = get(handles.trace_axes,'YLim');
inc = diff(yRange)/10;
yRange = [yRange(1)+inc, yRange(2)-inc];
set(handles.trace_axes,'YLim', yRange);


% --- Executes on button press in down_but.
function down_but_Callback(hObject, eventdata, handles)
% hObject    handle to down_but (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
yRange = get(handles.trace_axes,'YLim');
inc = diff(yRange)/10;
yRange = [yRange(1)-inc, yRange(2)+inc];
set(handles.trace_axes,'YLim', yRange);

% --------------------------------------------------------------------
function open_ui_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to open_ui (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%[FileName,PathName,FilterIndex] = uigetfile({'*.nex','Neuroexplorer File (*.nex)';'*.dat','Rat Physio File (*.dat)'},'Select Neuroexplorer File To Be Scored');
%handles.NexStruct = fullreadNexFile(fullfile(PathName,FileName));

% --------------------------------------------------------------------
function save_ui_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to save_ui (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[FileName,PathName,FilterIndex] = uiputfile( {'*.nex','Neuroexplorer Files';...
    '*.*','All Files' },'Save Scored File',handles.NexStruct.filename);
if ~isnumeric(FileName)
    handles.SaveFilename = fullfile(PathName,FileName);
    %update NexStruct with Currnet states
    handles = updateNexStruct(handles);
    [status] = NSB_NEXwriter(handles.NexStruct, handles.SaveFilename);
    if status
        msgbox({handles.SaveFilename,' Successfully written'}, 'File Writer Information','help');
    else
        disp('ERROR >> Nex File not written properly!');
    end
else
    disp('ERROR >> Nex File not written properly!');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Drag Functions
function StartDragFcn(hObject, eventdata, handles)
%gets passed h_ArtifactThreshLine
handles = guidata(gcbo);
handles.isTracking_L = false;
handles.isTracking_R = false;
set(handles.figure1, 'WindowButtonMotionFcn', {@draggingFcn,hObject}, 'UserData', hObject)

function StopDragFcn(hObject, eventdata, handles)
%gets passed handles.MainFigure
handles = guidata(gcbo);
%Snap to position
objLoc = get(get(handles.figure1,'UserData'),'YData');
if objLoc > length(handles.Archetecture)
    objLoc = length(handles.Archetecture)*[1,1];
elseif objLoc < 1
    objLoc = [1,1];
end
set(get(handles.figure1,'UserData'),'YData', round(objLoc) );
set(handles.figure1, 'WindowButtonMotionFcn', '');
%Cleanup
if isfield(handles,'horzMarks')
    try, delete(handles.horzMarks); end;
    handles = rmfield(handles,'horzMarks');
end
handles.isTracking_L = false;
handles.isTracking_R = false;
guidata(hObject,handles);

function draggingFcn(hFigure, eventdata, hObject)
%%gets passed handles.MainFigure
handles = guidata(gcbo);
curPoint = get(get(hObject,'Parent'),'CurrentPoint');
edges = get(hObject,'XData');
set(hObject,'YData', curPoint(1,2)*[1,1]);

if (edges(1)-1 < curPoint(1,1) &&  curPoint(1,1) < edges(1)+1) || handles.isTracking_L
    handles.isTracking_L = true;
    edges(1) = curPoint(1,1);
    ylimits = get(handles.trace_axes,'YLim');
    if isfield(handles,'horzMarks')
        try
        set(handles.horzMarks,'XData', [edges(1),edges(1)]);
        catch
            disp('horz line not set');
        end
    else
        axes(handles.trace_axes);
        handles.horzMarks = line([edges(1),edges(1)],ylimits,'Color','red','LineWidth',2);
        axes(handles.score_axes);
    end
    set(hObject,'XData', edges);
elseif (edges(2)-1 < curPoint(1,1) &&  curPoint(1,1) < edges(2)+1) || handles.isTracking_R
    handles.isTracking_R = true;
    edges(2) = curPoint(1,1);
    ylimits = get(handles.trace_axes,'YLim');
    if isfield(handles,'horzMarks')
        try
        set(handles.horzMarks,'XData', [edges(2),edges(2)]);
        catch
            disp('horz line not set');
        end
    else
        axes(handles.trace_axes);
        handles.horzMarks = line([edges(2),edges(2)],ylimits,'Color','red','LineWidth',2);
        axes(handles.score_axes);
    end
    set(hObject,'XData', edges);
end
guidata(hObject,handles);


function StartHorzDragFcn(hObject, eventdata, handles)
%gets passed h_ArtifactThreshLine
handles = guidata(gcbo);
set(handles.figure1, 'WindowButtonMotionFcn', {@HorzDraggingFcn,hObject})

function HorzDraggingFcn(hObject, eventdata, h_line)
%%gets passed handles.MainFigure
handles = guidata(gcbo);
curPoint = get(handles.SpectralPlot, 'CurrentPoint');
set(h_line,'XData',curPoint(1,1)*[1 1]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Utility Functions
function handles = updateNexStruct(handles)
%get info about current scoring
%can handle add / remove ints
ScoreInfo = zeros(length(handles.Scoring),3);
for curINT = 1:length(handles.Scoring)
    GetVal = get(handles.Scoring(curINT),'YData');
    ScoreInfo(curINT,1) = GetVal(1);
    ScoreInfo(curINT,2:3) = get(handles.Scoring(curINT),'XData');
end

intVarStruct = [handles.NexStruct.intervals{:}];
INTnames = {intVarStruct.name};
syncIDX = find( strcmpi(INTnames,'synch'));
desynchIDX = find( strcmpi(INTnames,'desynch'));
intermedIDX = find(  strcmpi(INTnames,'intermed') );
%we nkow where far are

for curINT = 1:length(handles.Archetecture)
    if ~isempty(handles.Archetecture(curINT).NexStructIDX)
        try
        if strcmp(handles.Archetecture(curINT).name, handles.NexStruct.intervals{syncIDX}.name)
            INTIDX = ScoreInfo(:,1) == 1;
        elseif strcmp(handles.Archetecture(curINT).name, handles.NexStruct.intervals{intermedIDX}.name)
            INTIDX = ScoreInfo(:,1) == 2;
        elseif strcmp(handles.Archetecture(curINT).name, handles.NexStruct.intervals{desynchIDX}.name)
            INTIDX = ScoreInfo(:,1) == 3;
        end
        catch
            errordlg('Error extracting Sleep Scoring from plot');
            INTIDX = [];
        end
    
    INTIDX = ScoreInfo(:,1) == 1;
    StateInfo = sortrows(ScoreInfo(INTIDX,:),2);

    handles.NexStruct.intervals{handles.Archetecture(curINT).NexStructIDX}.intStarts = StateInfo(:,2);
    handles.NexStruct.intervals{handles.Archetecture(curINT).NexStructIDX}.intEnds = StateInfo(:,3);
    handles.NexStruct.intervals{handles.Archetecture(curINT).NexStructIDX}.nEvents = size(StateInfo,1);
    handles.NexStruct.intervals{handles.Archetecture(curINT).NexStructIDX}.FilePosDataOffset = -1;
    end
end
 



function [nexFile] = fullreadNexFile(fileName,readType)
% [nexfile] = fullreadNexFile(fileName) -- read .nex file and return file data
% in nexfile structure
%
% INPUT:
%   fileName - if empty string, will use File Open dialog
%   readType     - vector of data filetypes, if empty will read all types
%
% OUTPUT:
%   nexFile - a structure containing .nex file data
%   nexFile.version - file version
%   nexFile.comment - file comment
%   nexFile.tbeg - beginning of recording session (in seconds)
%   nexFile.teng - end of resording session (in seconds)
%
%   nexFile.neurons - array of neuron structures
%           neuron.name - name of a neuron variable
%           neuron.timestamps - array of neuron timestamps (in seconds)
%               to access timestamps for neuron 2 use {n} notation:
%               nexFile.neurons{2}.timestamps
%
%   nexFile.events - array of event structures
%           event.name - name of neuron variable
%           event.timestamps - array of event timestamps (in seconds)
%               to access timestamps for event 3 use {n} notation:
%               nexFile.events{3}.timestamps
%
%   nexFile.intervals - array of interval structures
%           interval.name - name of neuron variable
%           interval.intStarts - array of interval starts (in seconds)
%           interval.intEnds - array of interval ends (in seconds)
%
%   nexFile.waves - array of wave structures
%           wave.name - name of neuron variable
%           wave.NPointsWave - number of data points in each wave
%           wave.WFrequency - A/D frequency for wave data points
%           wave.timestamps - array of wave timestamps (in seconds)
%           wave.waveforms - matrix of waveforms (in milliVolts), each
%                             waveform is a vector
%
%   nexFile.contvars - array of contvar structures
%           contvar.name - name of neuron variable
%           contvar.ADFrequency - A/D frequency for data points
%
%           continuous (a/d) data come in fragments. Each fragment has a timestamp
%           and an index of the a/d data points in data array. The timestamp corresponds to
%           the time of recording of the first a/d value in this fragment.
%
%           contvar.timestamps - array of timestamps (fragments start times in seconds)
%           contvar.fragmentStarts - array of start indexes for fragments in contvar.data array
%           contvar.data - array of data points (in milliVolts)
%
%   nexFile.popvectors - array of popvector (population vector) structures
%           popvector.name - name of popvector variable
%           popvector.weights - array of population vector weights
%
%   nexFile.markers - array of marker structures
%           marker.name - name of marker variable
%           marker.timestamps - array of marker timestamps (in seconds)
%           marker.values - array of marker value structures
%           	marker.value.name - name of marker value
%           	marker.value.strings - array of marker value strings
%
% This file was originally written by Nex Technologies and likely copyrighted.
% See http://www.neuroexplorer.com/code.html but no licence was Identified
% Modified by David M. Devilbiss (26Jan2009) for Full Read of Data
% release version 1.0 10Oct2010
% added ability to import data type subset

nexFile = [];

if (nargin < 1 | length(fileName) == 0)
    [fname, pathname] = uigetfile('*.nex', 'Select a NeuroExplorer file');
    fileName = strcat(pathname, fname);
    readType = 0:6;
elseif nargin == 1
    [pathname, fname, fext] = fileparts(fileName);
    fname = [fname,fext];
    readType = 0:6;
else
    [pathname, fname, fext] = fileparts(fileName);
    fname = [fname,fext];
end

fid = fopen(fileName, 'r');
if(fid == -1)
    error 'Unable to open file'
    return
end

warning off; %may be tex issues with underscores
hWaitBar = waitbar(0, ['Please Wait, Opening: ',fname]);
%hWaitBar = waitbar(0, ['Please Wait, Opening: ',regexprep(fname,'[_^]',' ')]);
try, set(get(get(hWaitBar,'Children'),'Title'),'Interpreter','none'); end;
warning on;

magic = fread(fid, 1, 'int32');
if magic ~= 827868494
    error 'The file is not a valid .nex file'
end
nexFile.version = fread(fid, 1, 'int32');
nexFile.comment = deblank(char(fread(fid, 256, 'char')'));
nexFile.freq = fread(fid, 1, 'double');
nexFile.tbeg = fread(fid, 1, 'int32')./nexFile.freq;
nexFile.tend = fread(fid, 1, 'int32')./nexFile.freq;
nexFile.nvar = fread(fid, 1, 'int32');

% skip location of next header and padding
fseek(fid, 260, 'cof');

neuronCount = 0;
eventCount = 0;
intervalCount = 0;
waveCount = 0;
popCount = 0;
contCount = 0;
markerCount = 0;

% read all variables
for i=1:nexFile.nvar
    type = fread(fid, 1, 'int32');
    varVersion = fread(fid, 1, 'int32');
    name = deblank(char(fread(fid, 64, 'char')'));
    offset = fread(fid, 1, 'int32');
    n = fread(fid, 1, 'int32');
    WireNumber = fread(fid, 1, 'int32');
    UnitNumber = fread(fid, 1, 'int32');
    Gain = fread(fid, 1, 'int32');
    Filter = fread(fid, 1, 'int32');
    XPos = fread(fid, 1, 'double');
    YPos = fread(fid, 1, 'double');
    WFrequency = fread(fid, 1, 'double'); % wf sampling fr.
    ADtoMV  = fread(fid, 1, 'double'); % coeff to convert from AD values to Millivolts.
    NPointsWave = fread(fid, 1, 'int32'); % number of points in each wave
    NMarkers = fread(fid, 1, 'int32'); % how many values are associated with each marker
    MarkerLength = fread(fid, 1, 'int32'); % how many characters are in each marker value
    MVOfffset = fread(fid, 1, 'double'); % coeff to shift AD values in Millivolts: mv = raw*ADtoMV+MVOfffset
    %60 char pad delt with below
    filePosition = ftell(fid);
    if ismember(type, readType)
        switch type
            case 0 % neuron
                neuronCount = neuronCount+1;
                nexFile.neurons{neuronCount,1}.name = name;
                fseek(fid, offset, 'bof');
                nexFile.neurons{neuronCount,1}.timestamps = fread(fid, [n 1], 'int32')./nexFile.freq;
                fseek(fid, filePosition, 'bof');
                
                %added bonus data for ease of re-writing
                nexFile.neurons{neuronCount,1}.type = type;
                nexFile.neurons{neuronCount,1}.varVersion = varVersion;
                nexFile.neurons{neuronCount,1}.FilePosDataOffset = offset;
                nexFile.neurons{neuronCount,1}.nEvents = n;
                nexFile.neurons{neuronCount,1}.WireNumber = WireNumber;
                nexFile.neurons{neuronCount,1}.UnitNumber = UnitNumber;
                nexFile.neurons{neuronCount,1}.Gain = Gain;
                nexFile.neurons{neuronCount,1}.Filter = Filter;
                nexFile.neurons{neuronCount,1}.XPos = XPos;
                nexFile.neurons{neuronCount,1}.YPos = YPos;
                nexFile.neurons{neuronCount,1}.WFrequency = WFrequency;
                nexFile.neurons{neuronCount,1}.ADtoMV = ADtoMV;
                nexFile.neurons{neuronCount,1}.NPointsWave = NPointsWave;
                nexFile.neurons{neuronCount,1}.NMarkers = NMarkers;
                nexFile.neurons{neuronCount,1}.MarkerLength = MarkerLength;
                nexFile.neurons{neuronCount,1}.MVOfffset = MVOfffset;
                
            case 1 % event
                eventCount = eventCount+1;
                nexFile.events{eventCount,1}.name = name;
                fseek(fid, offset, 'bof');
                nexFile.events{eventCount,1}.timestamps = fread(fid, [n 1], 'int32')./nexFile.freq;
                fseek(fid, filePosition, 'bof');
                
                %added bonus data for ease of re-writing
                nexFile.events{eventCount,1}.type = type;
                nexFile.events{eventCount,1}.varVersion = varVersion;
                nexFile.events{eventCount,1}.FilePosDataOffset = offset;
                nexFile.events{eventCount,1}.nEvents = n;
                nexFile.events{eventCount,1}.WireNumber = WireNumber;
                nexFile.events{eventCount,1}.UnitNumber = UnitNumber;
                nexFile.events{eventCount,1}.Gain = Gain;
                nexFile.events{eventCount,1}.Filter = Filter;
                nexFile.events{eventCount,1}.XPos = XPos;
                nexFile.events{eventCount,1}.YPos = YPos;
                nexFile.events{eventCount,1}.WFrequency = WFrequency;
                nexFile.events{eventCount,1}.ADtoMV = ADtoMV;
                nexFile.events{eventCount,1}.NPointsWave = NPointsWave;
                nexFile.events{eventCount,1}.NMarkers = NMarkers;
                nexFile.events{eventCount,1}.MarkerLength = MarkerLength;
                nexFile.events{eventCount,1}.MVOfffset = MVOfffset;
                
            case 2 % interval
                intervalCount = intervalCount+1;
                nexFile.intervals{intervalCount,1}.name = name;
                fseek(fid, offset, 'bof');
                nexFile.intervals{intervalCount,1}.intStarts = fread(fid, [n 1], 'int32')./nexFile.freq;
                nexFile.intervals{intervalCount,1}.intEnds = fread(fid, [n 1], 'int32')./nexFile.freq;
                fseek(fid, filePosition, 'bof');
                
                %added bonus data for ease of re-writing
                nexFile.intervals{intervalCount,1}.type = type;
                nexFile.intervals{intervalCount,1}.varVersion = varVersion;
                nexFile.intervals{intervalCount,1}.FilePosDataOffset = offset;
                nexFile.intervals{intervalCount,1}.nEvents = n;
                nexFile.intervals{intervalCount,1}.WireNumber = WireNumber;
                nexFile.intervals{intervalCount,1}.UnitNumber = UnitNumber;
                nexFile.intervals{intervalCount,1}.Gain = Gain;
                nexFile.intervals{intervalCount,1}.Filter = Filter;
                nexFile.intervals{intervalCount,1}.XPos = XPos;
                nexFile.intervals{intervalCount,1}.YPos = YPos;
                nexFile.intervals{intervalCount,1}.WFrequency = WFrequency;
                nexFile.intervals{intervalCount,1}.ADtoMV = ADtoMV;
                nexFile.intervals{intervalCount,1}.NPointsWave = NPointsWave;
                nexFile.intervals{intervalCount,1}.NMarkers = NMarkers;
                nexFile.intervals{intervalCount,1}.MarkerLength = MarkerLength;
                nexFile.intervals{intervalCount,1}.MVOfffset = MVOfffset;
                
            case 3 % waveform
                waveCount = waveCount+1;
                nexFile.waves{waveCount,1}.name = name;
                nexFile.waves{waveCount,1}.NPointsWave = NPointsWave;
                nexFile.waves{waveCount,1}.WFrequency = WFrequency;
                
                fseek(fid, offset, 'bof');
                nexFile.waves{waveCount,1}.timestamps = fread(fid, [n 1], 'int32')./nexFile.freq;
                nexFile.waves{waveCount,1}.waveforms = fread(fid, [NPointsWave n], 'int16').*ADtoMV + MVOfffset;
                fseek(fid, filePosition, 'bof');
                
                %added bonus data for ease of re-writing
                nexFile.waves{waveCount,1}.type = type;
                nexFile.waves{waveCount,1}.varVersion = varVersion;
                nexFile.waves{waveCount,1}.FilePosDataOffset = offset;
                nexFile.waves{waveCount,1}.nEvents = n;
                nexFile.waves{waveCount,1}.WireNumber = WireNumber;
                nexFile.waves{waveCount,1}.UnitNumber = UnitNumber;
                nexFile.waves{waveCount,1}.Gain = Gain;
                nexFile.waves{waveCount,1}.Filter = Filter;
                nexFile.waves{waveCount,1}.XPos = XPos;
                nexFile.waves{waveCount,1}.YPos = YPos;
                nexFile.waves{waveCount,1}.WFrequency = WFrequency;
                nexFile.waves{waveCount,1}.ADtoMV = ADtoMV;
                nexFile.waves{waveCount,1}.NPointsWave = NPointsWave;
                nexFile.waves{waveCount,1}.NMarkers = NMarkers;
                nexFile.waves{waveCount,1}.MarkerLength = MarkerLength;
                nexFile.waves{waveCount,1}.MVOfffset = MVOfffset;
                
            case 4 % population vector
                popCount = popCount+1;
                nexFile.popvectors{popCount,1}.name = name;
                fseek(fid, offset, 'bof');
                nexFile.popvectors{popCount,1}.weights = fread(fid, [n 1], 'double');
                fseek(fid, filePosition, 'bof');
                
                %added bonus data for ease of re-writing
                nexFile.popvectors{popCount,1}.type = type;
                nexFile.popvectors{popCount,1}.varVersion = varVersion;
                nexFile.popvectors{popCount,1}.FilePosDataOffset = offset;
                nexFile.popvectors{popCount,1}.nEvents = n;
                nexFile.popvectors{popCount,1}.WireNumber = WireNumber;
                nexFile.popvectors{popCount,1}.UnitNumber = UnitNumber;
                nexFile.popvectors{popCount,1}.Gain = Gain;
                nexFile.popvectors{popCount,1}.Filter = Filter;
                nexFile.popvectors{popCount,1}.XPos = XPos;
                nexFile.popvectors{popCount,1}.YPos = YPos;
                nexFile.popvectors{popCount,1}.WFrequency = WFrequency;
                nexFile.popvectors{popCount,1}.ADtoMV = ADtoMV;
                nexFile.popvectors{popCount,1}.NPointsWave = NPointsWave;
                nexFile.popvectors{popCount,1}.NMarkers = NMarkers;
                nexFile.popvectors{popCount,1}.MarkerLength = MarkerLength;
                nexFile.popvectors{popCount,1}.MVOfffset = MVOfffset;
                
            case 5 % continuous variable
                contCount = contCount+1;
                nexFile.contvars{contCount,1}.name = name;
                nexFile.contvars{contCount,1}.ADFrequency = WFrequency;
                fseek(fid, offset, 'bof');
                nexFile.contvars{contCount,1}.timestamps = fread(fid, [n 1], 'int32')./nexFile.freq;
                nexFile.contvars{contCount,1}.fragmentStarts = fread(fid, [n 1], 'int32') + 1;
                nexFile.contvars{contCount,1}.data = fread(fid, [NPointsWave 1], 'int16').*ADtoMV + MVOfffset;
                fseek(fid, filePosition, 'bof');
                
                %added bonus data for ease of re-writing
                nexFile.contvars{contCount,1}.type = type;
                nexFile.contvars{contCount,1}.varVersion = varVersion;
                nexFile.contvars{contCount,1}.FilePosDataOffset = offset;
                nexFile.contvars{contCount,1}.nEvents = n;
                nexFile.contvars{contCount,1}.WireNumber = WireNumber;
                nexFile.contvars{contCount,1}.UnitNumber = UnitNumber;
                nexFile.contvars{contCount,1}.Gain = Gain;
                nexFile.contvars{contCount,1}.Filter = Filter;
                nexFile.contvars{contCount,1}.XPos = XPos;
                nexFile.contvars{contCount,1}.YPos = YPos;
                nexFile.contvars{contCount,1}.WFrequency = WFrequency;
                nexFile.contvars{contCount,1}.ADtoMV = ADtoMV;
                nexFile.contvars{contCount,1}.NPointsWave = NPointsWave;
                nexFile.contvars{contCount,1}.NMarkers = NMarkers;
                nexFile.contvars{contCount,1}.MarkerLength = MarkerLength;
                nexFile.contvars{contCount,1}.MVOfffset = MVOfffset;
                
            case 6 % marker
                markerCount = markerCount+1;
                nexFile.markers{markerCount,1}.name = name;
                fseek(fid, offset, 'bof');
                nexFile.markers{markerCount,1}.timestamps = fread(fid, [n 1], 'int32')./nexFile.freq;
                for i=1:NMarkers
                    nexFile.markers{markerCount,1}.values{i,1}.name = deblank(char(fread(fid, 64, 'char')'));
                    for p = 1:n
                        nexFile.markers{markerCount,1}.values{i,1}.strings{p, 1} = deblank(char(fread(fid, MarkerLength, 'char')'));
                    end
                end
                fseek(fid, filePosition, 'bof');
                
                %added bonus data for ease of re-writing
                nexFile.markers{markerCount,1}.type = type;
                nexFile.markers{markerCount,1}.varVersion = varVersion;
                nexFile.markers{markerCount,1}.FilePosDataOffset = offset;
                nexFile.markers{markerCount,1}.nEvents = n;
                nexFile.markers{markerCount,1}.WireNumber = WireNumber;
                nexFile.markers{markerCount,1}.UnitNumber = UnitNumber;
                nexFile.markers{markerCount,1}.Gain = Gain;
                nexFile.markers{markerCount,1}.Filter = Filter;
                nexFile.markers{markerCount,1}.XPos = XPos;
                nexFile.markers{markerCount,1}.YPos = YPos;
                nexFile.markers{markerCount,1}.WFrequency = WFrequency;
                nexFile.markers{markerCount,1}.ADtoMV = ADtoMV;
                nexFile.markers{markerCount,1}.NPointsWave = NPointsWave;
                nexFile.markers{markerCount,1}.NMarkers = NMarkers;
                nexFile.markers{markerCount,1}.MarkerLength = MarkerLength;
                nexFile.markers{markerCount,1}.MVOfffset = MVOfffset;
                
            otherwise
                disp (['unknown variable type ' num2str(type)]);
        end
    end
    dummy = fread(fid, 60, 'char');
    waitbar(i/100);
end
waitbar(100);
fclose(fid);
close(hWaitBar)


function [status, nexStruct] = NSB_NEXwriter(nexStruct, fileName)
% write2NexFile is a replacment for writeNexFile
% Written de novo with inspiration from C++ code on Neuroexplorer site.
% Additionally contains abilty to write poulation vectors
%
% Usage:
%  >> [nexStruct] = write2NexFile(nexStruct, fileName)
%
% Inputs:
%   nexStruct   - STRUCT of Nex Data;
%   fileName    - FileName of path+name to be written (optional);
%
% Outputs:
%   nexStruct   - returned nexStruct with updated data fields.
%
% See also: readNexFile for nexStruct structure
%
% Copyright (C) 2010 by David Devilbiss <david.devilbiss@NexStepBiomarkers.com>
%  v. 1.0 DMD 10Oct2010
%
% NOTE: make sure to increment nVar when adding variables to an existing
% structure
status = false;
warning off; %there are conversion rounding warnings

%%
% Initialize variables and collect some information
magicNumber = 827868494; %i.e. 'NEX1'
NexFileHeaderSize = 544;
NexVarHeaderSize = 208;
offsetArray = [];

if (nargin < 2 | length(fileName) == 0)
    [fname, pathname] = uiputfile('*.nex', 'Select a NeuroExplorer file');
    fileName = strcat(pathname, fname);
else
    [pathname, fname, fext] = fileparts(fileName);
    fname = [fname,fext];
end

%make sure num of items = nexStruct.nvar
nNeurons = 0;
nEvents = 0;
nIntervals = 0;
nWaveforms = 0;
nPopvectors = 0;
nCont = 0;
nMarker = 0;
if isfield(nexStruct, 'neurons'), nNeurons = length(nexStruct.neurons); end;
if isfield(nexStruct, 'events'), nEvents = length(nexStruct.events); end;
if isfield(nexStruct, 'intervals'), nIntervals = length(nexStruct.intervals); end;
if isfield(nexStruct, 'waves'), nWaveforms = length(nexStruct.waves); end;
if isfield(nexStruct, 'popvectors'), nPopvectors = length(nexStruct.popvectors); end;
if isfield(nexStruct, 'contvars'), nCont = length(nexStruct.contvars); end;
if isfield(nexStruct, 'markers'), nMarker = length(nexStruct.markers); end;
totalNexDataTypes = nnz([nNeurons,nEvents,nIntervals,nWaveforms,nPopvectors,nCont,nMarker]);
if nNeurons + nEvents + nIntervals + nWaveforms + nPopvectors + nCont + nMarker ~= nexStruct.nvar
    error('Events in structure do not match nVar');
    return;
end

%%
%hWaitBar = waitbar(0, ['Please Wait, Saving: ', regexprep(fname, '_', '\\\_')]);
hWaitBar = waitbar(0, ['Please Wait, Saving: ', fname]);
try, set(get(get(hWaitBar,'Children'),'Title'),'Interpreter','none'); end;
waitbarjump = 0.0666; %total 13 intervals 
% open file
fid = fopen(fileName, 'w+'); %this may need to be just 'W'
if(fid == -1)
    error('Unable to open file');
    return
end

%% write .nex file header
try
waitbar(waitbarjump,hWaitBar);
% write .nex file header
elementCnt = fwrite(fid, magicNumber, 'int32');
elementCnt = fwrite(fid, nexStruct.version, 'int32');

%comment section is 256 elements, buffer with white space.
nexStruct.comment = char(nexStruct.comment, sprintf('%256s',' '));
nexStruct.comment = nexStruct.comment(1,:);

elementCnt = fwrite(fid, nexStruct.comment, 'char');
elementCnt = fwrite(fid, nexStruct.freq, 'double');
elementCnt = fwrite(fid, nexStruct.tbeg.*nexStruct.freq, 'int32');
elementCnt = fwrite(fid, nexStruct.tend.*nexStruct.freq, 'int32');
elementCnt = fwrite(fid, nexStruct.nvar, 'int32');%nvar is number of variables
elementCnt = fwrite(fid, 0, 'int32'); %// position of the next file header in the file not implemented yet
elementCnt = fwrite(fid, sprintf('%256s',' '), 'char'); %padding for future expansion
% end of file header

% sizeof(NexFileHeader) = 544
if ftell(fid) ~= NexFileHeaderSize
    error 'Badly Written Nex File header';
    fclose(fid);
    return;
end

%% Write each Variable Header
%go through each data type and write header
varCounter = 0;
varOffset = NexFileHeaderSize + nexStruct.nvar*NexVarHeaderSize;

for curDataType = 0:6 %7 total data types
    waitbar(waitbarjump + waitbarjump*(curDataType+1),hWaitBar);
    switch curDataType
        case 0
            dynFieldname = 'neurons';
        case 1
            dynFieldname = 'events';
        case 2
            dynFieldname = 'intervals';
        case 3
            dynFieldname = 'waves';
        case 4
            dynFieldname = 'popvectors';
        case 5
            dynFieldname = 'contvars';
        case 6
            dynFieldname = 'markers';
    end

    if isfield(nexStruct, dynFieldname)
        for nItems = 1:length(nexStruct.(dynFieldname));
            varCounter = varCounter +1;
            tempName = [];

            elementCnt = fwrite(fid, nexStruct.(dynFieldname){nItems}.type, 'int32');
            elementCnt = fwrite(fid, nexStruct.(dynFieldname){nItems}.varVersion, 'int32');

            %name section is 64 elements, buffer with white space.
            tempName = char(nexStruct.(dynFieldname){nItems}.name, sprintf('%64s',' '));
            elementCnt = fwrite(fid, tempName(1,:), 'char');

            %test for difference in old/new file offset
            if varOffset ~= nexStruct.(dynFieldname){nItems}.FilePosDataOffset
                nexStruct.(dynFieldname){nItems}.FilePosDataOffset = varOffset;
            end
            elementCnt = fwrite(fid, nexStruct.(dynFieldname){nItems}.FilePosDataOffset, 'int32');

            elementCnt = fwrite(fid, nexStruct.(dynFieldname){nItems}.nEvents, 'int32');
            elementCnt = fwrite(fid, nexStruct.(dynFieldname){nItems}.WireNumber, 'int32');
            elementCnt = fwrite(fid, nexStruct.(dynFieldname){nItems}.UnitNumber, 'int32');
            elementCnt = fwrite(fid, nexStruct.(dynFieldname){nItems}.Gain, 'int32');
            elementCnt = fwrite(fid, nexStruct.(dynFieldname){nItems}.Filter, 'int32');
            elementCnt = fwrite(fid, nexStruct.(dynFieldname){nItems}.XPos, 'double');
            elementCnt = fwrite(fid, nexStruct.(dynFieldname){nItems}.YPos, 'double');
            elementCnt = fwrite(fid, nexStruct.(dynFieldname){nItems}.WFrequency, 'double');
            elementCnt = fwrite(fid, nexStruct.(dynFieldname){nItems}.ADtoMV, 'double');
            elementCnt = fwrite(fid, nexStruct.(dynFieldname){nItems}.NPointsWave, 'int32');
            elementCnt = fwrite(fid, nexStruct.(dynFieldname){nItems}.NMarkers, 'int32');
            elementCnt = fwrite(fid, nexStruct.(dynFieldname){nItems}.MarkerLength, 'int32');
            elementCnt = fwrite(fid, nexStruct.(dynFieldname){nItems}.MVOfffset, 'double');

            elementCnt = fwrite(fid, sprintf('%60s',' '), 'char'); %padding for future expansion

            %populate offset table
            offsetArray(varCounter,:) = [varCounter, curDataType, nItems, nexStruct.(dynFieldname){nItems}.FilePosDataOffset];

            %Update offset dependent on data type
            % maybe faster/smaller if used sizeof(1,'int32')*nEvents
            switch curDataType
                case {0,1}
                    varOffset = varOffset + sizeof(nexStruct.(dynFieldname){nItems}.timestamps,'int32');
                case 2
                    varOffset = varOffset + 2 * sizeof(nexStruct.(dynFieldname){nItems}.intStarts,'int32');
                case 3
                    varOffset = varOffset + sizeof(nexStruct.(dynFieldname){nItems}.timestamps,'int32');
                    varOffset = varOffset + sizeof(nexStruct.(dynFieldname){nItems}.waveforms,'int16');
                case 4
                    varOffset = varOffset + sizeof(nexStruct.(dynFieldname){nItems}.weights,'double');
                case 5
                    varOffset = varOffset + sizeof(nexStruct.(dynFieldname){nItems}.timestamps,'int32');
                    varOffset = varOffset + sizeof(nexStruct.(dynFieldname){nItems}.fragmentStarts,'int32');
                    varOffset = varOffset + sizeof(nexStruct.(dynFieldname){nItems}.data,'int16');
                case 6
                    varOffset = varOffset + sizeof(nexStruct.(dynFieldname){nItems}.timestamps,'int32');
                    varOffset = varOffset + nexStruct.(dynFieldname){nItems}.NMarkers * ...
                        (sizeof(64,'char') * nexStruct.(dynFieldname){nItems}.MarkerLength);
            end
        end
    end
end

if varCounter == nexStruct.nvar
    disp('Correct Number of Var Headers Written');
else
    error('Incorrect Number of Var Headers Written')
end

%% Write each Variable Data
%go through each data type and write header
varCounter = 0;
for curDataType = 0:6 %7 total data types
     waitbar(8*waitbarjump + waitbarjump*(curDataType+1), hWaitBar);
    switch curDataType
        case 0
            dynFieldname = 'neurons';
            if isfield(nexStruct, dynFieldname)
            for nItems = 1:length(nexStruct.(dynFieldname));
                varCounter = varCounter +1;
                if ftell(fid) ~= offsetArray(varCounter,4)
                    error(['Calculated offset: ',offsetArray(varCounter,4),' ~= current file position: ', ftell(fid)]);
                    %return;
                end
                elementCnt = fwrite(fid, nexStruct.(dynFieldname){nItems}.timestamps .* nexStruct.freq, 'int32');
            end
            end
        case 1
            dynFieldname = 'events';
            if isfield(nexStruct, dynFieldname)
            for nItems = 1:length(nexStruct.(dynFieldname));
                varCounter = varCounter +1;
                if ftell(fid) ~= offsetArray(varCounter,4)
                    error(['Calculated offset: ',offsetArray(varCounter,4),' ~= current file position: ', ftell(fid)]);
                    %return;
                end
                elementCnt = fwrite(fid, nexStruct.(dynFieldname){nItems}.timestamps .* nexStruct.freq, 'int32');
            end
            end
        case 2
            dynFieldname = 'intervals';
            if isfield(nexStruct, dynFieldname)
            for nItems = 1:length(nexStruct.(dynFieldname));
                varCounter = varCounter +1;
                if ftell(fid) ~= offsetArray(varCounter,4)
                    error(['Calculated offset: ',offsetArray(varCounter,4),' ~= current file position: ', ftell(fid)]);
                    %return;
                end
                elementCnt = fwrite(fid, nexStruct.(dynFieldname){nItems}.intStarts .* nexStruct.freq, 'int32');
                elementCnt = fwrite(fid, nexStruct.(dynFieldname){nItems}.intEnds .* nexStruct.freq, 'int32');
            end
            end
        case 3
            dynFieldname = 'waves';
            if isfield(nexStruct, dynFieldname)
                for nItems = 1:length(nexStruct.(dynFieldname));
                    varCounter = varCounter +1;
                    if ftell(fid) ~= offsetArray(varCounter,4)
                        error(['Calculated offset: ',offsetArray(varCounter,4),' ~= current file position: ', ftell(fid)]);
                        %return;
                    end
                    elementCnt = fwrite(fid, nexStruct.(dynFieldname){nItems}.timestamps .* nexStruct.freq, 'int32');
                    elementCnt = fwrite(fid, nexStruct.(dynFieldname){nItems}.waveforms ./ nexStruct.(dynFieldname){nItems}.ADtoMV, 'int16');

                    %Original way of doing it reshape was not working properly
                    %in this instance

                    % .wave forms is a matrix, 1st linearize it.
                    % the transpose allows reshape to use columns like fread
                    %      wavearray = reshape(nexStruct.(dynFieldname){nItems}.waveforms', 1, nexStruct.(dynFieldname){nItems}.NPointsWave * nexStruct.(dynFieldname){nItems}.nEvents);
                    %      elementCnt = fwrite(fid, wavearray ./ nexStruct.(dynFieldname){nItems}.ADtoMV - ...
                    %       nexStruct.(dynFieldname){nItems}.MVOfffset, 'int16');
                end
            end
        case 4
            dynFieldname = 'popvectors';
            if isfield(nexStruct, dynFieldname)
            for nItems = 1:length(nexStruct.(dynFieldname));
                varCounter = varCounter +1;
                if ftell(fid) ~= offsetArray(varCounter,4)
                    error(['Calculated offset: ',offsetArray(varCounter,4),' ~= current file position: ', ftell(fid)]);
                    %return;
                end
                %elementCnt = fwrite(fid, nexStruct.(dynFieldname){nItems}.weights .* nexStruct.freq, 'float64');
                elementCnt = fwrite(fid, nexStruct.(dynFieldname){nItems}.weights, 'float64');
            end
            end
        case 5
            dynFieldname = 'contvars';
            if isfield(nexStruct, dynFieldname)
            for nItems = 1:length(nexStruct.(dynFieldname));
                varCounter = varCounter +1;
                if ftell(fid) ~= offsetArray(varCounter,4)
                    error(['Calculated offset: ',offsetArray(varCounter,4),' ~= current file position: ', ftell(fid)]);
                    %return;
                end
                elementCnt = fwrite(fid, nexStruct.(dynFieldname){nItems}.timestamps .* nexStruct.freq, 'int32');
                elementCnt = fwrite(fid, nexStruct.(dynFieldname){nItems}.fragmentStarts -1, 'int32');
                elementCnt = fwrite(fid, nexStruct.(dynFieldname){nItems}.data ./ ...
                    nexStruct.(dynFieldname){nItems}.ADtoMV - nexStruct.(dynFieldname){nItems}.MVOfffset, 'int16');
            end
            end
        case 6
            % this section is broken. possibly deeper data structs ??
            dynFieldname = 'markers';
            if isfield(nexStruct, dynFieldname)
            for nItems = 1:length(nexStruct.(dynFieldname));
                tempName = [];
                varCounter = varCounter +1;
                if ftell(fid) ~= offsetArray(varCounter,4)
                    error(['Calculated offset: ',offsetArray(varCounter,4),' ~= current file position: ', ftell(fid)]);
                    %return;
                end
                elementCnt = fwrite(fid, nexStruct.(dynFieldname){nItems}.timestamps .* nexStruct.freq, 'int32');
                for i=1:nexStruct.(dynFieldname){nItems}.NMarkers
                    % element name is 64 elements, buffer with white space.
                    tempName = char(nexStruct.(dynFieldname){nItems}.name, sprintf('%64s',' '));
                    elementCnt = fwrite(fid, tempName(1,:), 'char');
                    for p = 1:length(nexStruct.(dynFieldname){nItems}.values{i}.strings)
                        elementCnt = fwrite(fid, nexStruct.(dynFieldname){nItems}.values{p}.strings{:}, 'char');
                    end
                end
                
            end
            end
    end
end
    

%% clean up
waitbar(100,hWaitBar);
fclose(fid);
close(hWaitBar)
disp('File written properly !');
status = true;
catch
waitbar(100,hWaitBar);
fclose(fid);
close(hWaitBar)
disp('File not written properly !');
end

function nBytes = sizeof(Data,precision)
error(nargchk(1,2,nargin,'struct'));
if nargin == 1
    precision = 'int8';
elseif ~isempty(strfind(precision,'char'))
    precision = 'int8';
elseif isstr(Data)
    error('First argument may not be of type string');
end

[r,c] = size(Data);
NewData = zeros(r,c,precision);
info = whos('NewData');
nBytes = info.bytes;

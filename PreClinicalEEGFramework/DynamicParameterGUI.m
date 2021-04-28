function [ArtifactDetectionParms, SpectralAnalysisParms, status] = DynamicParameterGUI(ChannelStruct, inputParms)
% DynamicParameterGUI() - User Guided selection of Spectral Ananlysis Parameters
% [ArtifactDetectionParms, SpectralAnalysisParms, status] = DynamicParameterGUI(data,inputParms)
%
% Functions very Similar to Spectrogram()
%
% Inputs:
%   data                - (struct) Structure of data channel (see LIMS)
%   inputParms          - (struct) Structure of analysis parameters
%   	.PreClinicalFramework   (struct) Structure of PreClinicalFramework parameters (see parameters file)
%   	.Filename               (string) FileName
%
% Outputs: Pyy,CI,T,F,validBins,status
%   ArtifactDetectionParms      - (struct) Structure of artifact detection parameters
%   SpectralAnalysisParms       - (struct) Structure of spectral analysis parameters
%   status                      - (logical) return value
%
%
% Dependencies: 
% NSBlog, NSB_SpectralAnalysis
% 
%ToDo: BinSize and options.FinalTimeResolution seem to be mishandled? 
%
% Written By David M. Devilbiss
% NexStep Biomarkers, LLC. (info@nexstepbiomarkers.com)
% Febuary 27 2012, Version 1.0
% Sept 29 2015, Version 2.0 - Many of the changes applied to this function were lost on another branch. Altering input structure and fixing XML output.

global Heatmapdeleted;
Heatmapdeleted = false;

status = false;
if nargin > 1
    ArtifactDetectionParms = inputParms.PreClinicalFramework.ArtifactDetection;
    SpectralAnalysisParms = inputParms.PreClinicalFramework.SpectralAnalysis;
    SystemParms.Version = inputParms.PreClinicalFramework.Version;
    SystemParms.OutputDir = inputParms.PreClinicalFramework.OutputDir;
    SystemParms.MatlabPost2014 = inputParms.PreClinicalFramework.MatlabPost2014;
    SystemParms.File = inputParms.PreClinicalFramework.File;
    SystemParms.File.useWaitBar = inputParms.PreClinicalFramework.useWaitBar;
    SystemParms.File.XLSoutput = inputParms.PreClinicalFramework.XLSoutput;
    SystemParms.File.BioBookoutput = inputParms.PreClinicalFramework.BioBookoutput;
    SystemParms.Resample = inputParms.PreClinicalFramework.Resample;
    SystemParms.StatsTable = inputParms.PreClinicalFramework.StatsTable;
    SystemParms.Scoring = inputParms.PreClinicalFramework.Scoring;
    SystemParms.rules = inputParms.PreClinicalFramework.rules;
    SystemParms.Seizure = inputParms.PreClinicalFramework.SeizureAnalysis;
    SystemParms.status = false;
    
    
    if isfield(inputParms,'Filename')
        Filename = inputParms.Filename;
    else
        Filename = '';
    end
    if isfield(inputParms.PreClinicalFramework,'LogFile')
        SpectralAnalysisParms.logfile = inputParms.PreClinicalFramework.LogFile;
    else
        SpectralAnalysisParms.logfile = '';
    end
end
clear inputParms;

%% Setup GUI
FileLength = length(ChannelStruct.Data)/ChannelStruct.Hz;
[DataPath,DataFilename,DataFileext] = fileparts(Filename);
DataNameStr = ['Channel: ',ChannelStruct.Name, ' File: ',DataFilename,DataFileext,' File Length: ',num2str(FileLength),' (sec)'];
[DynParamGUIFig, handles] = GenerateGUI(DataNameStr);
movegui(DynParamGUIFig,'center'); 

%% Now that GUI is setup
% Set relevant fields
%set(handles.MainFigure,'UserData',false); %this used to be >> handles.status = status; but wasnt being maintained??
set(handles.MainFigure,'UserData',SystemParms);

handles.PlotWin.Start = 0;
if SpectralAnalysisParms.FinalTimeResolution > 60
    handles.PlotWin.Stop = SpectralAnalysisParms.FinalTimeResolution;
else
    handles.PlotWin.Stop = 60;
end
handles.PlotWin.Max = FileLength;

% Fill Default bands
for curBand = 1:length(SpectralAnalysisParms.SpectralBands)
    BandData{curBand,1} = num2str(SpectralAnalysisParms.SpectralBands(curBand).Start);
    BandData{curBand,2} = num2str(SpectralAnalysisParms.SpectralBands(curBand).Stop);
end
set(handles.BandCalc_tab,'Data',BandData);
set(handles.normSpecta_chk,'Value',SpectralAnalysisParms.normSpectaTotalPower);
% Fill Default Ratios
RatioDefaultValues = [SpectralAnalysisParms.SpectralRatio(:).num, SpectralAnalysisParms.SpectralRatio(:).den];
RatioDefaultValues(isnan(RatioDefaultValues)) = 1;
set(handles.Ratio1Num_pul,'Value',RatioDefaultValues(1));
set(handles.Ratio2Num_pul,'Value',RatioDefaultValues(2));
set(handles.Ratio3Num_pul,'Value',RatioDefaultValues(3));
set(handles.Ratio4Num_pul,'Value',RatioDefaultValues(4));
set(handles.Ratio5Num_pul,'Value',RatioDefaultValues(5));
set(handles.Ratio1Den_pul,'Value',RatioDefaultValues(6));
set(handles.Ratio2Den_pul,'Value',RatioDefaultValues(7));
set(handles.Ratio3Den_pul,'Value',RatioDefaultValues(8));
set(handles.Ratio4Den_pul,'Value',RatioDefaultValues(9));
set(handles.Ratio5Den_pul,'Value',RatioDefaultValues(10));

%plot EEG and generate user selectable threshold   
t = 0: (1/ChannelStruct.Hz): (length(ChannelStruct.Data)/ChannelStruct.Hz); %<<
set(handles.TimePlot,'NextPlot','add');
plot(handles.TimePlot,t(1:length(ChannelStruct.Data)),ChannelStruct.Data);
DCThreshold = getArtifactThresh(ArtifactDetectionParms,ChannelStruct.Data,ChannelStruct.Units); 
set(handles.MainFigure,'WindowButtonUpFcn',@StopDragFcn);

%draw a user grabbale line
handles.ArtifactThreshLine = line(get(handles.TimePlot,'XLim'), [DCThreshold DCThreshold],...
    'Parent',handles.TimePlot,'color','red','linewidth',2,'ButtonDownFcn',@StartDragFcn);
%pass artifact struct with Timeplot
set(handles.TimePlot,'UserData',ArtifactDetectionParms);

%set View of time plot
set(handles.TimePlot,'XLim',[handles.PlotWin.Start handles.PlotWin.Stop]); %Default View of 60 Seconds
set(handles.PlotTimeSlice_txt,'String',num2str(handles.PlotWin.Stop));
ltlTimeStep = handles.PlotWin.Stop/handles.PlotWin.Max;
bigTimeStep = handles.PlotWin.Stop/handles.PlotWin.Max*10;
if bigTimeStep > 1
    bigTimeStep = 1;
end
set(handles.timeWinSet_slide,'Min',0,'Max',ceil(FileLength),'Value',0,...
'SliderStep',[ltlTimeStep bigTimeStep]); %dynamic steps

%convert Units to mV -or uV-
set(handles.TimePlotYLabel,'String', ['Signal (',ChannelStruct.Units,')']);
set(handles.SpectralPlotYLabel,'String', ['Signal Power (',ChannelStruct.Units,')']);
% if isfield(ChannelStruct,'Units');
%     [OutStr,OutVal,retVal] = NSB_ConvertVunits('get',ChannelStruct.Units);
%     YlimitVals = get(handles.TimePlot,'YLim');
%     if max(YlimitVals) > 1e4
%         %rescale and center
%         YlimitVals = [-max(abs(YlimitVals)), max(abs(YlimitVals))];
%         set(handles.TimePlot,'YLim',YlimitVals);
%         [OutStr,OutVal,retVal] = NSB_ConvertVunits('get',OutVal / 1e3);
%         set(handles.TimePlot,'YTickLabel',get(handles.TimePlot,'YTick')/1e3);
%     elseif max(YlimitVals) < 1
%         YlimitVals = [-max(abs(YlimitVals)), max(abs(YlimitVals))];
%         set(handles.TimePlot,'YLim',YlimitVals);
%         [OutStr,OutVal,retVal] = NSB_ConvertVunits('get',OutVal * -1e3);
%         set(handles.TimePlot,'YTickLabel',get(handles.TimePlot,'YTick')*1e3);
%     end
%     set(handles.TimePlotYLabel,'UserData',OutVal);
%     set(handles.TimePlotYLabel,'String', ['Signal (',OutStr,')']);
%     set(handles.SpectralPlotYLabel,'String', ['Signal Power (',OutStr,')']);
% end

%plot FFT for 1st PlotWin.Stop seconds
SpectralAnalysisParms.SPTmethod = 'FFT';
SpectralAnalysisParms.nanDC = true;
set(handles.SpectralPlot,'NextPlot','add');
if FileLength > handles.PlotWin.Stop %seconds
[Pyy,CI,T,F,validBins,status] = NSB_SpectralAnalysis(ChannelStruct.Data(1:handles.PlotWin.Stop*ChannelStruct.Hz), SpectralAnalysisParms.FinalTimeResolution, SpectralAnalysisParms.FinalFreqResolution, ChannelStruct.Hz, SpectralAnalysisParms);
else
[Pyy,CI,T,F,validBins,status] = NSB_SpectralAnalysis(ChannelStruct.Data, SpectralAnalysisParms.FinalTimeResolution, SpectralAnalysisParms.FinalFreqResolution, ChannelStruct.Hz, SpectralAnalysisParms);   
end
plot(handles.SpectralPlot,F,Pyy);
%set max displayed Freq
set(handles.maxSpectFreq_txt,'String',num2str(F(end)));

%Setup FFT Frequencu Bins
SpectralAnalysisParms.Freqs = 0:SpectralAnalysisParms.FinalFreqResolution:ChannelStruct.Hz/2;

%setup Sliders
%setup a struct to pass along with the spectral plot.
SpectralFigStruct.Data = ChannelStruct.Data;
SpectralFigStruct.FinalTimeResolution = SpectralAnalysisParms.FinalTimeResolution;
SpectralFigStruct.FinalFreqResolution = SpectralAnalysisParms.FinalFreqResolution;
SpectralFigStruct.Hz = ChannelStruct.Hz;
SpectralFigStruct.SpectralAnalysisParms = SpectralAnalysisParms;
SpectralFigStruct.nanDC = SpectralAnalysisParms.nanDC;

set(handles.SpectralPlot,'UserData',SpectralFigStruct);
%sliders
set(handles.HzSet_txt,'String',num2str(SpectralAnalysisParms.FinalFreqResolution));
set(handles.timebinSet_txt,'String',num2str(SpectralAnalysisParms.FinalTimeResolution));
%set(handles.HzSet_slide,'Min',0.5,'Max',10,'Value',SpectralAnalysisParms.FinalFreqResolution,...
%'SliderStep',[0.0263 0.1053]); %1 and 0.25 steps
set(handles.HzSet_slide,'Min',0.1,'Max',10,'Value',SpectralAnalysisParms.FinalFreqResolution,...
'SliderStep',[0.0101 0.1010]); %1 and 0.25 steps
set(handles.timebinSet_slide,'Min',10,'Max',3600,'Value',SpectralAnalysisParms.FinalTimeResolution,...
'SliderStep',[0.0028 0.0167]);

%setup Spectral line Plots
defColors = get(0,'DefaultAxesColorOrder'); %7 colors << will barf if more
for curBand = 1:length(SpectralAnalysisParms.SpectralBands)
    curColor = defColors(curBand,:);
    BandHandle(curBand,1) = line([SpectralAnalysisParms.SpectralBands(curBand).Start SpectralAnalysisParms.SpectralBands(curBand).Start],...
        get(handles.SpectralPlot,'YLim'), 'Parent',handles.SpectralPlot,'color',curColor,'linewidth',2,'ButtonDownFcn',@StartHorzDragFcn,...
        'UserData','marker');
    BandHandle(curBand,2) = line([SpectralAnalysisParms.SpectralBands(curBand).Stop SpectralAnalysisParms.SpectralBands(curBand).Stop],...
        get(handles.SpectralPlot,'YLim'), 'Parent',handles.SpectralPlot,'color',curColor,'linewidth',2,'ButtonDownFcn',@StartHorzDragFcn,...
        'UserData','marker');
end
handles.BandHandle = BandHandle;

%Setup Heat Map (not Visble)
[handles.Heatmap] = GenerateHEATMAP(Pyy);
ImageAxesHandle = get(handles.Heatmap.HeatMapPlot,'Parent');
for curBand = 1:length(SpectralAnalysisParms.SpectralBands)
    curColor = defColors(curBand,:);
    HeatBandHandle(curBand,1) = line(get(ImageAxesHandle,'XLim'),...
        [SpectralAnalysisParms.SpectralBands(curBand).Start SpectralAnalysisParms.SpectralBands(curBand).Start],...
        'Parent',ImageAxesHandle,'color',curColor,'linewidth',2,'UserData','marker');
    HeatBandHandle(curBand,2) = line(get(ImageAxesHandle,'XLim'),...
        [SpectralAnalysisParms.SpectralBands(curBand).Stop SpectralAnalysisParms.SpectralBands(curBand).Stop],...
        'Parent',ImageAxesHandle,'color',curColor,'linewidth',2,'UserData','marker');
end
handles.HeatBandHandle = HeatBandHandle;

% Update handles structure
guidata(DynParamGUIFig, handles);

% UIWAIT makes figure wait for user response (see UIRESUME)
uiwait(DynParamGUIFig);

%when done collect all parms
SysStatus = get(handles.MainFigure,'UserData');
if SysStatus.status
    status = true;
    ArtifactDetectionParms = get(handles.TimePlot,'UserData');
    SpectralAnalysisParms = get(handles.SpectralPlot,'UserData');
else
    status = false;
    %Return same as input params
end
%Close Figures HeatMap
try, delete(handles.Heatmap.HeatMapFigure); end
delete(handles.MainFigure);
drawnow();

function HzSlider_callback(hObject,eventdata)
handles = guidata(gcbo);
NumAsStr = num2str(get(hObject,'Value'),'%4.1f');
set(handles.HzSet_txt,'String', NumAsStr);
SpectralFigStruct = get(handles.SpectralPlot,'UserData');
SpectralFigStruct.FinalFreqResolution = str2double(NumAsStr);
SpectralFigStruct.SpectralAnalysisParms.Freqs = str2double(NumAsStr);

%The above lines should always work now.
% %This next line rounds to the nearest 0.25 Hz << hard coded
% SpectralFigStruct.SpectralAnalysisParms.Freqs = floor(get(hObject,'Value')) + floor(rem(get(hObject,'Value'),floor(get(hObject,'Value'))) /0.25) *0.25;
% if isnan(SpectralFigStruct.SpectralAnalysisParms.Freqs) %less than 1 Hz
%     SpectralFigStruct.SpectralAnalysisParms.Freqs = floor((1-get(hObject,'Value'))/0.25) *0.25;
% end
SpectralFigStruct.SpectralAnalysisParms.Freqs = 0:SpectralFigStruct.SpectralAnalysisParms.Freqs:SpectralFigStruct.Hz/2;
[Pyy,CI,T,F,validBins,status] = NSB_SpectralAnalysis(SpectralFigStruct.Data(handles.PlotWin.Start*SpectralFigStruct.Hz+1 : handles.PlotWin.Stop*SpectralFigStruct.Hz),...
    SpectralFigStruct.FinalTimeResolution, SpectralFigStruct.FinalFreqResolution, SpectralFigStruct.Hz, SpectralFigStruct.SpectralAnalysisParms);
PlotChildren = get(handles.SpectralPlot,'Children');
PlotCounter = 1;
for curChild = 1:length(PlotChildren)
    if ~strcmpi(get(PlotChildren(curChild),'UserData'),'marker')
    %set(PlotChildren(curChild),'XData',F);
    %set(PlotChildren(curChild),'YData',Pyy(PlotCounter,:));
    set(PlotChildren(curChild),'XData',F,'YData',Pyy(PlotCounter,:)); %This may be safer
    PlotCounter = PlotCounter +1;
    else
         %temp make lines small
        set(PlotChildren(curChild),'YData',[0,0]);
    end
end
%now update band lines
for curChild = 1:length(PlotChildren)
    if strcmpi(get(PlotChildren(curChild),'UserData'),'marker')
    set(PlotChildren(curChild),'YData',get(handles.SpectralPlot,'YLim'));
    end
end
set(handles.SpectralPlot,'UserData',SpectralFigStruct);

%update Heatmap
set(handles.Heatmap.HeatMapPlot,'CData',Pyy');

HeatMapAxis = get(handles.Heatmap.HeatMapPlot,'Parent');
yHzDiv = ceil(str2double(get(handles.maxSpectFreq_txt,'String'))/10);
yAxisIntervals = ceil(yHzDiv/str2double(NumAsStr));
%yAxisIntervals = min(diff(get(HeatMapAxis,'YTick')));
dispHzBins = str2double(get(handles.maxSpectFreq_txt,'String'))./str2double(NumAsStr);
set(HeatMapAxis,'YLim', [0.5 dispHzBins+0.5]);
set(HeatMapAxis,'YTick',0:yAxisIntervals:dispHzBins);
set(HeatMapAxis,'YTickLabel',0:yHzDiv:str2double(get(handles.maxSpectFreq_txt,'String')));
%set(HeatMapAxis,'YTickLabel',0:yAxisIntervals*str2double(NumAsStr):str2double(get(handles.maxSpectFreq_txt,'String')));

%update Bands
bandValues = str2double(get(handles.BandCalc_tab,'Data'));
for curBand = 1:size(handles.HeatBandHandle,1)
        set(handles.HeatBandHandle(curBand,1),'YData', bandValues(curBand,1)./[str2double(NumAsStr) str2double(NumAsStr)] );
        set(handles.HeatBandHandle(curBand,2),'YData', bandValues(curBand,2)./[str2double(NumAsStr) str2double(NumAsStr)] );
end

guidata(gcbo, handles);

function TimeSlider_callback(hObject,eventdata)
handles = guidata(gcbo);
NumAsStr = num2str(get(hObject,'Value'),'%2.0f');
set(handles.timebinSet_txt,'String', NumAsStr);
SpectralFigStruct = get(handles.SpectralPlot,'UserData');
SpectralFigStruct.FinalTimeResolution = str2double(NumAsStr);

[Pyy,CI,T,F,validBins,status] = NSB_SpectralAnalysis(SpectralFigStruct.Data(handles.PlotWin.Start*SpectralFigStruct.Hz+1 : handles.PlotWin.Stop*SpectralFigStruct.Hz),...
    SpectralFigStruct.FinalTimeResolution, SpectralFigStruct.FinalFreqResolution, SpectralFigStruct.Hz, SpectralFigStruct.SpectralAnalysisParms);
%now more Children/less Children
PlotChildren = get(handles.SpectralPlot,'Children');
PlotCounter = 1;
for curChild = 1:length(PlotChildren)
    if ~strcmpi(get(PlotChildren(curChild),'UserData'),'marker')
        delete(PlotChildren(curChild));
    else
        %temp make lines small
        set(PlotChildren(curChild),'YData',[0,0]);
    end
end
plot(handles.SpectralPlot,F,Pyy);
%now update band lines
PlotChildren = get(handles.SpectralPlot,'Children');
for curChild = 1:length(PlotChildren)
    if strcmpi(get(PlotChildren(curChild),'UserData'),'marker')
    set(PlotChildren(curChild),'YData',get(handles.SpectralPlot,'YLim'));
    end
end
% PlotChildren = get(handles.SpectralPlot,'Children');
% PlotCounter = 1;
% for curChild = 1:length(PlotChildren)
%     if ~strcmpi(get(PlotChildren(curChild),'UserData'),'marker')
%     set(PlotChildren(curChild),'XData',F);
%     set(PlotChildren(curChild),'YData',Pyy(PlotCounter,:));
%     PlotCounter = PlotCounter +1;
%     end
% end
set(handles.SpectralPlot,'UserData',SpectralFigStruct);

%update Heatmap
set(handles.Heatmap.HeatMapPlot,'CData',Pyy');
HeatMapAxis = get(handles.Heatmap.HeatMapPlot,'Parent');
set(HeatMapAxis,'XLim', [0.5 size(Pyy,1)+0.5]);
set(HeatMapAxis,'XTick',0:size(Pyy,1)/6:size(Pyy,1));
set(HeatMapAxis,'XTickLabel',handles.PlotWin.Start:(handles.PlotWin.Stop-handles.PlotWin.Start)/6:handles.PlotWin.Stop);

guidata(gcbo, handles);

function HzSet_txt_callback(hObject,eventdata)
handles = guidata(gcbo);
HzValue = str2double(get(hObject,'String'));
if HzValue < 0.1
    HzValue = 0.1;
    set(handles.HzSet_txt,'String', num2str(HzValue,'%4.1f'));
elseif HzValue > 10
    HzValue = 10;
    set(handles.HzSet_txt,'String', num2str(HzValue,'%4.1f'));
end
set(handles.HzSet_slide,'Value', HzValue);

SpectralFigStruct = get(handles.SpectralPlot,'UserData');
SpectralFigStruct.FinalFreqResolution = HzValue;
SpectralFigStruct.SpectralAnalysisParms.Freqs = HzValue;

%Again, the above lines should fix this
% %This next line rounds to the nearest 0.25 Hz << hard coded
% SpectralFigStruct.SpectralAnalysisParms.Freqs = floor(HzValue) + floor(rem(HzValue,floor(HzValue)) /0.25) *0.25;
% if isnan(SpectralFigStruct.SpectralAnalysisParms.Freqs) %less than 1 Hz
%     SpectralFigStruct.SpectralAnalysisParms.Freqs = floor((1-HzValue)/0.25) *0.25;
% end
SpectralFigStruct.SpectralAnalysisParms.Freqs = 0:SpectralFigStruct.SpectralAnalysisParms.Freqs:SpectralFigStruct.Hz/2;
[Pyy,CI,T,F,validBins,status] = NSB_SpectralAnalysis(SpectralFigStruct.Data(handles.PlotWin.Start*SpectralFigStruct.Hz+1 : handles.PlotWin.Stop*SpectralFigStruct.Hz),...
    SpectralFigStruct.FinalTimeResolution, SpectralFigStruct.FinalFreqResolution, SpectralFigStruct.Hz, SpectralFigStruct.SpectralAnalysisParms);
PlotChildren = get(handles.SpectralPlot,'Children');
PlotCounter = 1;
for curChild = 1:length(PlotChildren)
    if ~strcmpi(get(PlotChildren(curChild),'UserData'),'marker')
    set(PlotChildren(curChild),'XData',F);
    set(PlotChildren(curChild),'YData',Pyy(PlotCounter,:));
    PlotCounter = PlotCounter +1;
        else
         %temp make lines small
        set(PlotChildren(curChild),'YData',[0,0]);
    end
end
%now update band lines
for curChild = 1:length(PlotChildren)
    if strcmpi(get(PlotChildren(curChild),'UserData'),'marker')
    set(PlotChildren(curChild),'YData',get(handles.SpectralPlot,'YLim'));
    end
end
set(handles.SpectralPlot,'UserData',SpectralFigStruct);

%update Heatmap
set(handles.Heatmap.HeatMapPlot,'CData',Pyy');

HeatMapAxis = get(handles.Heatmap.HeatMapPlot,'Parent');
yHzDiv = str2double(get(handles.maxSpectFreq_txt,'String'))/10;
yAxisIntervals = yHzDiv/HzValue;
%yAxisIntervals = min(diff(get(HeatMapAxis,'YTick')));
dispHzBins = str2double(get(handles.maxSpectFreq_txt,'String'))./HzValue;
set(HeatMapAxis,'YLim', [0.5 dispHzBins+0.5]);
set(HeatMapAxis,'YTick',0:yAxisIntervals:dispHzBins);
set(HeatMapAxis,'YTickLabel',0:yHzDiv:str2double(get(handles.maxSpectFreq_txt,'String')));
%set(HeatMapAxis,'YTickLabel',0:yAxisIntervals*str2double(NumAsStr):str2double(get(handles.maxSpectFreq_txt,'String')));

%update Bands
bandValues = str2double(get(handles.BandCalc_tab,'Data'));
for curBand = 1:size(handles.HeatBandHandle,1)
        set(handles.HeatBandHandle(curBand,1),'YData', bandValues(curBand,1)./[HzValue HzValue] );
        set(handles.HeatBandHandle(curBand,2),'YData', bandValues(curBand,2)./[HzValue HzValue] );
end

guidata(gcbo, handles);

function timebinSet_txt_callback(hObject,eventdata)
handles = guidata(gcbo);
TimeValue = str2double(get(hObject,'String'));
if TimeValue < 10
    TimeValue = 10;
    set(handles.HzSet_txt,'String', num2str(TimeValue,'%4.0f'));
elseif TimeValue > 3600
    TimeValue = 3600;
    set(handles.HzSet_txt,'String', num2str(TimeValue,'%4.0f'));
end
set(handles.timebinSet_slide,'Value', TimeValue);

SpectralFigStruct = get(handles.SpectralPlot,'UserData');
SpectralFigStruct.FinalTimeResolution = TimeValue;
[Pyy,CI,T,F,validBins,status] = NSB_SpectralAnalysis(SpectralFigStruct.Data(handles.PlotWin.Start*SpectralFigStruct.Hz+1 : handles.PlotWin.Stop*SpectralFigStruct.Hz),...
    SpectralFigStruct.FinalTimeResolution, SpectralFigStruct.FinalFreqResolution, SpectralFigStruct.Hz, SpectralFigStruct.SpectralAnalysisParms);
%now more Children/less Children
PlotChildren = get(handles.SpectralPlot,'Children');
PlotCounter = 1;
for curChild = 1:length(PlotChildren)
    if ~strcmpi(get(PlotChildren(curChild),'UserData'),'marker')
        delete(PlotChildren(curChild));
    else
        %temp make lines small
        set(PlotChildren(curChild),'YData',[0,0]);
    end
end
plot(handles.SpectralPlot,F,Pyy);
%now update band lines
PlotChildren = get(handles.SpectralPlot,'Children');
for curChild = 1:length(PlotChildren)
    if strcmpi(get(PlotChildren(curChild),'UserData'),'marker')
    set(PlotChildren(curChild),'YData',get(handles.SpectralPlot,'YLim'));
    end
end

% PlotChildren = get(handles.SpectralPlot,'Children');
% PlotCounter = 1;
% for curChild = 1:length(PlotChildren)
%     if ~strcmpi(get(PlotChildren(curChild),'UserData'),'marker')
%     set(PlotChildren(curChild),'XData',F);
%     set(PlotChildren(curChild),'YData',Pyy(PlotCounter,:));
%     PlotCounter = PlotCounter +1;
%     end
% end
set(handles.SpectralPlot,'UserData',SpectralFigStruct);

%update Heatmap
set(handles.Heatmap.HeatMapPlot,'CData',Pyy');
HeatMapAxis = get(handles.Heatmap.HeatMapPlot,'Parent');
set(HeatMapAxis,'XLim', [0.5 size(Pyy,1)+0.5]);
set(HeatMapAxis,'XTick',0:size(Pyy,1)/6:size(Pyy,1));
set(HeatMapAxis,'XTickLabel',handles.PlotWin.Start:(handles.PlotWin.Stop-handles.PlotWin.Start)/6:handles.PlotWin.Stop);

guidata(gcbo, handles);

function setTimeSlice_callback(hObject,eventdata)
handles = guidata(gcbo);
handles.PlotWin.Start = floor(get(handles.timeWinSet_slide,'Value'));
handles.PlotWin.Stop = handles.PlotWin.Start + str2double(get(handles.PlotTimeSlice_txt,'String'));
if handles.PlotWin.Start >=  handles.PlotWin.Max || handles.PlotWin.Stop >=  handles.PlotWin.Max
    handles.PlotWin.Stop = handles.PlotWin.Max;
    handles.PlotWin.Start = handles.PlotWin.Max - str2double(get(handles.PlotTimeSlice_txt,'String'));
end

%set Time Plot
set(handles.TimePlot,'XLim',[handles.PlotWin.Start handles.PlotWin.Stop]);
if handles.PlotWin.Stop <= 120
    %set to sec
    set(handles.TimePlot,'XTickLabel',get(handles.TimePlot,'XTick'));
    set(handles.TimePlotXLabel,'String','Time (Seconds)') ;
elseif handles.PlotWin.Stop > 120 && handles.PlotWin.Stop <= 3600
    %set to min
    set(handles.TimePlot,'XTickLabel',get(handles.TimePlot,'XTick')/60);
    set(handles.TimePlotXLabel,'String','Time (Minutes)');
elseif handles.PlotWin.Stop > 3600
    %set to hours
    set(handles.TimePlot,'XTickLabel',get(handles.TimePlot,'XTick')/60/60);
    set(handles.TimePlotXLabel,'String','Time (Hours)');
end

%set Hz Plot
SpectralFigStruct = get(handles.SpectralPlot,'UserData');
[Pyy,CI,T,F,validBins,status] = NSB_SpectralAnalysis(SpectralFigStruct.Data(handles.PlotWin.Start*SpectralFigStruct.Hz+1 : handles.PlotWin.Stop*SpectralFigStruct.Hz), SpectralFigStruct.FinalTimeResolution, SpectralFigStruct.FinalFreqResolution, SpectralFigStruct.Hz, SpectralFigStruct.SpectralAnalysisParms);
PlotChildren = get(handles.SpectralPlot,'Children');
PlotCounter = 1;
for curChild = 1:length(PlotChildren)
    if ~strcmpi(get(PlotChildren(curChild),'UserData'),'marker')
    set(PlotChildren(curChild),'XData',F);
    set(PlotChildren(curChild),'YData',Pyy(PlotCounter,:));
    PlotCounter = PlotCounter +1;
    end
end
%now update band lines
for curChild = 1:length(PlotChildren)
    if strcmpi(get(PlotChildren(curChild),'UserData'),'marker')
    set(PlotChildren(curChild),'YData',get(handles.SpectralPlot,'YLim'));
    end
end
set(handles.SpectralPlot,'UserData',SpectralFigStruct);

%update Heatmap
set(handles.Heatmap.HeatMapPlot,'CData',Pyy');
HeatMapAxis = get(handles.Heatmap.HeatMapPlot,'Parent');

set(HeatMapAxis,'XTickLabel',handles.PlotWin.Start:(handles.PlotWin.Stop-handles.PlotWin.Start)/6:handles.PlotWin.Stop);
% if handles.PlotWin.Stop < 120
%    %set to sec
%     set(HeatMapAxis,'XTickLabel',get(handles.TimePlot,'XTick'));
%     set(handles.Heatmap.HeatMapPlotXLabel,'String','Time (Seconds)');
% elseif handles.PlotWin.Stop > 120
%     %set to min
%     set(HeatMapAxis,'XTickLabel',get(handles.TimePlot,'XTick')/60);
%     set(handles.Heatmap.HeatMapPlotXLabel,'String','Time (Minutes)');
% elseif handles.PlotWin.Stop > 3600
%     %set to hours
%     set(HeatMapAxis,'XTickLabel',get(handles.TimePlot,'XTick')/60/60);
%     set(handles.Heatmap.HeatMapPlotXLabel,'String','Time (Hours)');
% end

guidata(gcbo, handles);

function PlotTimeSlice_txt_callback(hObject,eventdata)
handles = guidata(gcbo);
WinValue = str2double(get(handles.PlotTimeSlice_txt,'String'));
if WinValue > handles.PlotWin.Max
    WinValue = floor(handles.PlotWin.Max);
    handles.PlotWin.Start = 0;
    handles.PlotWin.Stop = WinValue;
elseif handles.PlotWin.Stop+WinValue > handles.PlotWin.Max
    handles.PlotWin.Stop = handles.PlotWin.Max;
else
     handles.PlotWin.Stop = handles.PlotWin.Start + WinValue;
end
%set Slider
stepMin = handles.PlotWin.Stop/handles.PlotWin.Max; if stepMin > 1, stepMin = 1; end; 
stepMax = handles.PlotWin.Stop/handles.PlotWin.Max*10; if stepMax > 1, stepMax = stepMin; end; 
set(handles.timeWinSet_slide,'SliderStep',[stepMin stepMax]); %dynamic steps

%set Time Plot
set(handles.TimePlot,'XLim',[handles.PlotWin.Start handles.PlotWin.Stop]);
if handles.PlotWin.Stop <= 120
    %set to sec
    set(handles.TimePlot,'XTickLabel',get(handles.TimePlot,'XTick'));
    set(handles.TimePlotXLabel,'String','Time (Seconds)') ;
elseif handles.PlotWin.Stop > 120 && handles.PlotWin.Stop <= 3600
    %set to min
    set(handles.TimePlot,'XTickLabel',get(handles.TimePlot,'XTick')/60);
    set(handles.TimePlotXLabel,'String','Time (Minutes)');
elseif handles.PlotWin.Stop > 3600
    %set to hours
    set(handles.TimePlot,'XTickLabel',get(handles.TimePlot,'XTick')/60/60);
    set(handles.TimePlotXLabel,'String','Time (Hours)');
end

%set Hz Plot
SpectralFigStruct = get(handles.SpectralPlot,'UserData');
[Pyy,CI,T,F,validBins,status] = NSB_SpectralAnalysis(SpectralFigStruct.Data(handles.PlotWin.Start*SpectralFigStruct.Hz+1 : handles.PlotWin.Stop*SpectralFigStruct.Hz), SpectralFigStruct.FinalTimeResolution, SpectralFigStruct.FinalFreqResolution, SpectralFigStruct.Hz, SpectralFigStruct.SpectralAnalysisParms);
%now more Children/less Children
PlotChildren = get(handles.SpectralPlot,'Children');
PlotCounter = 1;
for curChild = 1:length(PlotChildren)
    if ~strcmpi(get(PlotChildren(curChild),'UserData'),'marker')
        delete(PlotChildren(curChild));
    else
        %temp make lines small
        set(PlotChildren(curChild),'YData',[0,0]);
    end
end
plot(handles.SpectralPlot,F,Pyy);
%now update band lines
PlotChildren = get(handles.SpectralPlot,'Children');
for curChild = 1:length(PlotChildren)
    if strcmpi(get(PlotChildren(curChild),'UserData'),'marker')
    set(PlotChildren(curChild),'YData',get(handles.SpectralPlot,'YLim'));
    end
end
set(handles.SpectralPlot,'UserData',SpectralFigStruct);

%update Heatmap
set(handles.Heatmap.HeatMapPlot,'CData',Pyy');
HeatMapAxis = get(handles.Heatmap.HeatMapPlot,'Parent');

set(HeatMapAxis,'XLim', [0.5 size(Pyy,1)+0.5]);
set(HeatMapAxis,'XTick',0:size(Pyy,1)/6:size(Pyy,1));
set(HeatMapAxis,'XTickLabel',handles.PlotWin.Start:(handles.PlotWin.Stop-handles.PlotWin.Start)/6:handles.PlotWin.Stop);

%update bands handles.HeatBandHandle
xValues = get(handles.Heatmap.HeatMapPlot,'XData');
for curBand = 1:length(handles.HeatBandHandle)
        set(handles.HeatBandHandle(curBand,1),'XData', xValues);
        set(handles.HeatBandHandle(curBand,2),'XData', xValues);
end

guidata(gcbo, handles);

function TimePlotIncY_but_callback(hObject,eventdata)
handles = guidata(gcbo);
YlimitVals = get(handles.TimePlot,'YLim');
YlimitVals = [-max(abs(YlimitVals)), max(abs(YlimitVals))];
set(handles.TimePlot,'YLim',YlimitVals/2);
%Scale if necessary
% if max(YlimitVals/2) < 1e3
%     [OutStr,OutVal,retVal] = NSB_ConvertVunits('get',get(handles.TimePlotYLabel,'UserData') * 1e3);
%     set(handles.TimePlot,'YTickLabel',get(handles.TimePlot,'YTick'));
%     set(handles.TimePlotYLabel,'UserData',OutVal);
%     set(handles.TimePlotYLabel,'String', ['Signal (',OutStr,')']);
%     set(handles.SpectralPlotYLabel,'String', ['Signal Power (',OutStr,')']);
% end

function TimePlotDecY_but_callback(hObject,eventdata)
handles = guidata(gcbo);
YlimitVals = get(handles.TimePlot,'YLim');
YlimitVals = [-max(abs(YlimitVals)), max(abs(YlimitVals))];
set(handles.TimePlot,'YLim',YlimitVals*2);
%Scale if necessary
% if max(YlimitVals*2) > 1e3
%     [OutStr,OutVal,retVal] = NSB_ConvertVunits('get',get(handles.TimePlotYLabel,'UserData') / 1e3);
%     set(handles.TimePlot,'YTickLabel',get(handles.TimePlot,'YTick')/1e3);
%     set(handles.TimePlotYLabel,'UserData',OutVal);
%     set(handles.TimePlotYLabel,'String', ['Signal (',OutStr,')']);
%     set(handles.SpectralPlotYLabel,'String', ['Signal Power (',OutStr,')']);
% end

function TimePlotResetY_but_callback(hObject,eventdata)
handles = guidata(gcbo);
set(handles.TimePlot,'YLimMode','auto');

function maxHzSet_txt_callback(hObject,eventdata)
handles = guidata(gcbo);
newval = str2double(get(handles.maxSpectFreq_txt,'String'));
set(handles.SpectralPlot,'XLim',[0 newval]);
%update Heatmap
HeatMapAxis = get(handles.Heatmap.HeatMapPlot,'Parent');
yAxisIntervals = min(diff(get(HeatMapAxis,'YTick')));
dispHzBins = newval./str2double(get(handles.HzSet_txt,'String'));
set(HeatMapAxis,'YLim',[0.5 dispHzBins+0.5]);
set(HeatMapAxis,'YTick',0:yAxisIntervals:dispHzBins);
set(HeatMapAxis,'YTickLabel',0:yAxisIntervals*str2double(get(handles.HzSet_txt,'String')):str2double(get(handles.maxSpectFreq_txt,'String')));


function setY2log_callback(hObject,eventdata)
handles = guidata(gcbo);
if get(hObject,'Value')
    set(handles.SpectralPlot,'YScale','log')
    for curBand = 1:length(handles.BandHandle)
        yValues = get(handles.BandHandle(curBand,1),'YData');
        set(handles.BandHandle(curBand,1),'YData', [0.1 yValues(2)]);
        yValues = get(handles.BandHandle(curBand,2),'YData');
        set(handles.BandHandle(curBand,2),'YData', [0.1 yValues(2)]);
    end
else
    set(handles.SpectralPlot,'YScale','linear')
    for curBand = 1:length(handles.BandHandle)
        yValues = get(handles.BandHandle(curBand,1),'YData');
        set(handles.BandHandle(curBand,1),'YData', [0 yValues(2)]);
        yValues = get(handles.BandHandle(curBand,2),'YData');
        set(handles.BandHandle(curBand,2),'YData', [0 yValues(2)]);
    end
end

function createHeatMap_callback(hObject,eventdata)
global Heatmapdeleted;
handles = guidata(gcbo);
if ~Heatmapdeleted
    set(handles.Heatmap.HeatMapFigure,'Visible','on');
else
    SpectralFigStruct = get(handles.SpectralPlot,'UserData');
    [Pyy,CI,T,F,validBins,status] = NSB_SpectralAnalysis(SpectralFigStruct.Data(handles.PlotWin.Start*SpectralFigStruct.Hz+1 : handles.PlotWin.Stop*SpectralFigStruct.Hz), SpectralFigStruct.FinalTimeResolution, SpectralFigStruct.FinalFreqResolution, SpectralFigStruct.Hz, SpectralFigStruct.SpectralAnalysisParms);
    [handles.Heatmap] = GenerateHEATMAP(Pyy);
    ImageAxesHandle = get(handles.Heatmap.HeatMapPlot,'Parent');
    defColors = get(0,'DefaultAxesColorOrder'); %7 colors << will barf if more
    for curBand = 1:length(SpectralFigStruct.SpectralAnalysisParms.SpectralBands)
        curColor = defColors(curBand,:);
        HeatBandHandle(curBand,1) = line(get(ImageAxesHandle,'XLim'),...
            [SpectralFigStruct.SpectralAnalysisParms.SpectralBands(curBand).Start SpectralFigStruct.SpectralAnalysisParms.SpectralBands(curBand).Start],...
            'Parent',ImageAxesHandle,'color',curColor,'linewidth',2,'UserData','marker');
        HeatBandHandle(curBand,2) = line(get(ImageAxesHandle,'XLim'),...
            [SpectralFigStruct.SpectralAnalysisParms.SpectralBands(curBand).Stop SpectralFigStruct.SpectralAnalysisParms.SpectralBands(curBand).Stop],...
            'Parent',ImageAxesHandle,'color',curColor,'linewidth',2,'UserData','marker');
    end
    handles.HeatBandHandle = HeatBandHandle;
    set(handles.Heatmap.HeatMapFigure,'Visible','on');
    guidata(gcbo, handles);
end

function deleteHeatMap_callback(hObject,eventdata)
global Heatmapdeleted;
Heatmapdeleted = true;

function EditColorMapping_but_callback(hObject,eventdata)
colormapeditor(get(hObject,'Parent'));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Drag Functions
function StartDragFcn(hObject, eventdata, handles)
%gets passed h_ArtifactThreshLine
handles = guidata(gcbo);
set(handles.MainFigure, 'WindowButtonMotionFcn', @draggingFcn)

function StopDragFcn(hObject, eventdata, handles)
%gets passed handles.MainFigure
handles = guidata(gcbo);
set(handles.MainFigure, 'WindowButtonMotionFcn', '');

function draggingFcn(varargin)
%%gets passed handles.MainFigure
handles = guidata(gcbo);
curPoint = get(handles.TimePlot, 'CurrentPoint');
set(handles.ArtifactThreshLine,'YData',curPoint(1,2)*[1 1]);

function StartHorzDragFcn(hObject, eventdata, handles)
%gets passed h_ArtifactThreshLine
handles = guidata(gcbo);
set(handles.MainFigure, 'WindowButtonMotionFcn', {@HorzDraggingFcn,hObject})

function HorzDraggingFcn(hObject, eventdata, h_line)
%%gets passed handles.MainFigure
handles = guidata(gcbo);
curPoint = get(handles.SpectralPlot, 'CurrentPoint');
set(h_line,'XData',curPoint(1,1)*[1 1]);

%and update table
Table = get(handles.BandCalc_tab,'Data');
Table{handles.BandHandle == h_line} = num2str(curPoint(1,1));
set(handles.BandCalc_tab,'Data',Table);

%and update Heat Map
HzRes = str2double(get(handles.HzSet_txt,'String'));
set(handles.HeatBandHandle(handles.BandHandle == h_line),'YData',curPoint(1,1)./[HzRes HzRes]);
guidata(gcbo, handles);

function BandCalc_tab_callback(hObject, eventdata, handles)
%gets handle to table, event data old/new values/ handles
handles = guidata(gcbo);
set(handles.BandHandle(eventdata.Indices(1),eventdata.Indices(2)),'XData',str2double(eventdata.NewData)*[1,1]);
HzRes = str2double(get(handles.HzSet_txt,'String'));
set(handles.HeatBandHandle(eventdata.Indices(1),eventdata.Indices(2)),'YData',str2double(eventdata.NewData)./[HzRes HzRes]);
guidata(gcbo, handles);

function print_but_callback(hObject,eventdata)
handles = guidata(gcbo);
printpreview(handles.MainFigure);

function cancel_but_callback(hObject, eventdata, handles)
handles = guidata(gcbo);
SysStatus = get(handles.MainFigure,'UserData');
SysStatus.status = false;
set(handles.MainFigure,'UserData',SysStatus); %handles.status = false;
guidata(gcbo, handles);
uiresume(handles.MainFigure);
%delete(handles.MainFigure);

%%%%%%%%%%%%%%%%%%%
function save_but_callback(hObject, eventdata, handles)
handles = guidata(gcbo);
%build struct
%Get original structs.
ArtDetStruct = get(handles.TimePlot,'UserData');
SpectPlotStruct = get(handles.SpectralPlot,'UserData');
SpectAnalStruct = SpectPlotStruct.SpectralAnalysisParms;
SysStatus = get(handles.MainFigure,'UserData');

%Update with GUI params (Artifact Struct)
%Get plot data
plotChildren = get(handles.TimePlot,'Children');
Signal = get(plotChildren(~(plotChildren == handles.ArtifactThreshLine)),'YData');
switch upper(ArtDetStruct.algorithm)
    case 'RMS'
        rms = sqrt(mean(Signal.^2));
        curThresh =get(handles.ArtifactThreshLine,'YData');
        ArtDetStruct.RMSMultiplier = curThresh(1)/rms;
    case 'DC'
        curThresh =get(handles.ArtifactThreshLine,'YData');
        ArtDetStruct.DCvalue = curThresh(1);
    case {'FULL','FULL -EMG'}
        switch lower(ArtDetStruct.full.DCcalculation)
            case 'scaled'
                curThresh =get(handles.ArtifactThreshLine,'YData');
                rms = sqrt(mean(Signal.^2));
                IDX = (Signal > rms*ArtDetStruct.RMSMultiplier) | ...
                        (Signal < -rms*ArtDetStruct.RMSMultiplier);
                nanSignal = Signal;
                nanSignal(IDX) = NaN;    
                SigBuff = buffer(abs(nanSignal),double(round(ArtDetStruct.SampleRate/2)));% buffer will fail if data is empty
                clear nanSignal;
                BuffMax = max(SigBuff);
                clear SigBuff;
                ArtDetStruct.full.STDMultiplier = curThresh(1)/(max(BuffMax)-min(BuffMax));
                
%                 if Threshold < min(BuffMax)*2  %deal with sig's with no artifact
%                     ArtDetStruct.full.STDMultiplier = get(handles.ArtifactThreshLine,'YData');
%                 else
%                     ArtDetStruct.full.STDMultiplier = curThresh(1)/(max(BuffMax)-min(BuffMax));
%                 end
            otherwise %use DC thresh
                curThresh = get(handles.ArtifactThreshLine,'YData');
                ArtDetStruct.full.DCvalue = curThresh(1);
        end
    otherwise
        curThresh =get(handles.ArtifactThreshLine,'YData');
        ArtDetStruct.DCvalue = curThresh(1);
end
% %Update with GUI params (Spectral Struct)
SpectAnalStruct.FinalFreqResolution = str2double(get(handles.HzSet_txt,'String'));
SpectAnalStruct.FinalTimeResolution = str2double(get(handles.timebinSet_txt,'String'));
tableData = get(handles.BandCalc_tab,'Data');
for curBand = 1:length(SpectAnalStruct.SpectralBands)
    SpectAnalStruct.SpectralBands(curBand).Start = str2double(tableData{curBand,1});
    SpectAnalStruct.SpectralBands(curBand).Stop = str2double(tableData{curBand,2});
end
SpectAnalStruct.normSpectaTotalPower  = logical(get(handles.normSpecta_chk,'Value'));

%UGH Hard Coded !!
SpectAnalStruct.SpectralRatio(1).num = get(handles.Ratio1Num_pul,'Value');
SpectAnalStruct.SpectralRatio(1).den = get(handles.Ratio1Den_pul,'Value');
SpectAnalStruct.SpectralRatio(2).num = get(handles.Ratio2Num_pul,'Value');
SpectAnalStruct.SpectralRatio(2).den = get(handles.Ratio2Den_pul,'Value');
SpectAnalStruct.SpectralRatio(3).num = get(handles.Ratio3Num_pul,'Value');
SpectAnalStruct.SpectralRatio(3).den = get(handles.Ratio3Den_pul,'Value');
SpectAnalStruct.SpectralRatio(4).num = get(handles.Ratio4Num_pul,'Value');
SpectAnalStruct.SpectralRatio(4).den = get(handles.Ratio4Den_pul,'Value');
SpectAnalStruct.SpectralRatio(5).num = get(handles.Ratio5Num_pul,'Value');
SpectAnalStruct.SpectralRatio(5).den = get(handles.Ratio5Den_pul,'Value');

%build struct and save as XML
DynParamGUIStruct.Version = SysStatus.Version;
DynParamGUIStruct.OutputDir = SysStatus.OutputDir;
DynParamGUIStruct.File = SysStatus.File;
DynParamGUIStruct.StatsTable = SysStatus.StatsTable;
DynParamGUIStruct.Resample = SysStatus.Resample;
DynParamGUIStruct.ArtifactDetection = ArtDetStruct;
DynParamGUIStruct.SpectralAnalysis = SpectAnalStruct;
DynParamGUIStruct.Scoring = SysStatus.Scoring;
DynParamGUIStruct.rules = SysStatus.rules;
DynParamGUIStruct.SeizureAnalysis = SysStatus.Seizure;

[fn, path] = uiputfile({'*.xml','NexStep Biomarkers Parameter Files (*.xml)';'*.*',  'All Files (*.*)'},'Save the parameter file');
if ischar(path)
    warning('off', 'MATLAB:pfileOlderThanMfile')
    try
        if SysStatus.MatlabPost2014
            tinyxml2_wrap('save', fullfile(path,fn), DynParamGUIStruct);
        else
            xml_save( fullfile(path,fn), DynParamGUIStruct );
        end
        helpdlg({'Successfully Saved:',fullfile(path,fn)},'Save Parameter File');
    catch
      errordlg({'Unknown Error During Save:',fullfile(path,fn)},'Save Parameter File');  
    end
else
    errorstr = ['Warning: DynamicParameterGUI >> Parameters were not saved'];
        if ~isempty(SpectAnalStruct.logfile)
            NSBlog(SpectAnalStruct.logfile,errorstr);
        else
            errordlg(errorstr,'DynamicParameterGUI');
        end
end
guidata(gcbo, handles);


function ok_but_callback(hObject, eventdata, handles)
handles = guidata(gcbo);
%clean this up with fcn above...
ArtDetStruct = get(handles.TimePlot,'UserData');
SpectPlotStruct = get(handles.SpectralPlot,'UserData');
SpectAnalStruct = SpectPlotStruct.SpectralAnalysisParms;

%Update with GUI params (Artifact Struct)
%Get plot data
plotChildren = get(handles.TimePlot,'Children');
Signal = get(plotChildren(~(plotChildren == handles.ArtifactThreshLine)),'YData');
switch upper(ArtDetStruct.algorithm)
    case 'RMS'
        rms = sqrt(mean(Signal.^2));
        curThresh =get(handles.ArtifactThreshLine,'YData');
        ArtDetStruct.RMSMultiplier = curThresh(1)/rms;
    case 'DC'
        curThresh =get(handles.ArtifactThreshLine,'YData');
        ArtDetStruct.DCvalue = curThresh(1);
    case 'FULL'
        switch lower(ArtDetStruct.full.DCcalculation)
             case 'scaled'
%                 curThresh =get(handles.ArtifactThreshLine,'YData');
%                 SigBuff = buffer(abs(Signal),double(round(ArtDetStruct.SampleRate/2)));% buffer will fail if data is empty
%                 BuffMax = max(SigBuff);
%                 ArtDetStruct.full.STDMultiplier = curThresh(1)/(max(BuffMax)-min(BuffMax));

                curThresh =get(handles.ArtifactThreshLine,'YData');
                rms = sqrt(mean(Signal.^2));
                IDX = (Signal > rms*ArtDetStruct.RMSMultiplier) | ...
                        (Signal < -rms*ArtDetStruct.RMSMultiplier);
                nanSignal = Signal;
                nanSignal(IDX) = NaN;    
                SigBuff = buffer(abs(nanSignal),double(round(ArtDetStruct.SampleRate/2)));% buffer will fail if data is empty
                clear nanSignal;
                BuffMax = max(SigBuff);
                clear SigBuff;
                ArtDetStruct.full.STDMultiplier = curThresh(1)/(max(BuffMax)-min(BuffMax));

            otherwise %use DC thresh
                curThresh = get(handles.ArtifactThreshLine,'YData');
                ArtDetStruct.full.DCvalue = curThresh(1);
        end
    otherwise
        curThresh =get(handles.ArtifactThreshLine,'YData');
        ArtDetStruct.DCvalue = curThresh(1);
end
% %Update with GUI params (Spectral Struct)
SpectAnalStruct.FinalFreqResolution = str2double(get(handles.HzSet_txt,'String'));
SpectAnalStruct.FinalTimeResolution = str2double(get(handles.timebinSet_txt,'String'));
tableData = get(handles.BandCalc_tab,'Data');
for curBand = 1:length(SpectAnalStruct.SpectralBands)
    SpectAnalStruct.SpectralBands(curBand).Start = str2double(tableData{curBand,1});
    SpectAnalStruct.SpectralBands(curBand).Stop = str2double(tableData{curBand,2});
end
SpectAnalStruct.normSpectaTotalPower  = logical(get(handles.normSpecta_chk,'Value'));

%UGH Hard Coded !!
SpectAnalStruct.SpectralRatio(1).num = get(handles.Ratio1Num_pul,'Value');
SpectAnalStruct.SpectralRatio(1).den = get(handles.Ratio1Den_pul,'Value');
SpectAnalStruct.SpectralRatio(2).num = get(handles.Ratio2Num_pul,'Value');
SpectAnalStruct.SpectralRatio(2).den = get(handles.Ratio2Den_pul,'Value');
SpectAnalStruct.SpectralRatio(3).num = get(handles.Ratio3Num_pul,'Value');
SpectAnalStruct.SpectralRatio(3).den = get(handles.Ratio3Den_pul,'Value');
SpectAnalStruct.SpectralRatio(4).num = get(handles.Ratio4Num_pul,'Value');
SpectAnalStruct.SpectralRatio(4).den = get(handles.Ratio4Den_pul,'Value');
SpectAnalStruct.SpectralRatio(5).num = get(handles.Ratio5Num_pul,'Value');
SpectAnalStruct.SpectralRatio(5).den = get(handles.Ratio5Den_pul,'Value');

%This time save in fig data
set(handles.TimePlot,'UserData',ArtDetStruct);
set(handles.SpectralPlot,'UserData',SpectAnalStruct);
SysStatus = get(handles.MainFigure,'UserData');
SysStatus.status = true;
set(handles.MainFigure,'UserData',SysStatus); %handles.status = true;
guidata(gcbo, handles);
uiresume(handles.MainFigure);
%delete(handles.MainFigure);

function Threshold = getArtifactThresh(ArtifactDetectionParms,Signal,units)
switch upper(ArtifactDetectionParms.algorithm)
    case 'RMS'
        rms = sqrt(mean(Signal.^2));
        Threshold = rms*ArtifactDetectionParms.RMSMultiplier;
    case 'DC'
        Threshold = ArtifactDetectionParms.DCvalue;
        %(this is in mV) so...
        if ~strcmpi(units,'mv')
            [dataOutStr,dataOutVal,retVal] = NSB_ConvertVunits('get',units);
            [parmOutStr,parmOutVal,retVal] = NSB_ConvertVunits('get','mv');
            Threshold = Threshold/abs(parmOutVal/dataOutVal);
        end
    case {'FULL','FULL -EMG'}
        switch lower(ArtifactDetectionParms.full.DCcalculation)
            case 'scaled'
                rms = sqrt(mean(Signal.^2));
                IDX = (Signal > rms*ArtifactDetectionParms.RMSMultiplier) | ...
                        (Signal < -rms*ArtifactDetectionParms.RMSMultiplier);
                nanSignal = Signal;
                nanSignal(IDX) = NaN;    
                SigBuff = buffer(abs(nanSignal),double(round(ArtifactDetectionParms.SampleRate/2)));% buffer will fail if data is empty
                clear nanSignal;
                BuffMax = max(SigBuff);
                clear SigBuff;
                Threshold = (max(BuffMax)-min(BuffMax)) * ArtifactDetectionParms.full.STDMultiplier;
                if Threshold < min(BuffMax)*2  %deal with sig's with no artifact
                    Threshold = min(BuffMax)*2;
                end
            otherwise %use DC thresh
                Threshold = ArtifactDetectionParms.full.DCvalue;
        end
    otherwise
             Threshold = ArtifactDetectionParms.DCvalue;
end


function [h1, handles] = GenerateGUI(DataStr)
%
BandRatioCell = {  'Band 1'; 'Band 2'; 'Band 3'; 'Band 4'; 'Band 5' };

h1 = figure(...
'Color',[0.941176470588235 0.941176470588235 0.941176470588235],...
'Position',[0 0 1 1],...
'MenuBar','none',...
'Name','Parameter Interface GUI',...
'PaperPosition',get(0,'defaultfigurePaperPosition'),...
'Position',[727 154 807 820],...
'Resize','off',...
'Tag','MainFigure',...
'Visible','on');

h1a = uicontrol(...
'Parent',h1,...
'Units','characters',...
'FontSize',10,...
'HorizontalAlignment','right',...
'Position',[2 61 157 1.8],...
'String',DataStr,...
'Style','text',...
'Tag','Filedata_stxt');

% Artifact detection
h2 = uipanel(...
'Parent',h1,...
'Units','characters',...
'Title','Artifact Detection Parameters',...
'Tag','Artifact_pan',...
'Clipping','on',...
'Position',[2 40 158.2 21.5]);

h3 = axes(...
'Parent',h2,...
'Units','pixels',...
'Position',[55 80 700 160],...%[55 40 715 160] then [55 90 700 160]
'Tag','TimePlot');

h4 = get(h3,'xlabel');
set(h4, 'Parent',h3,...
    'FontName','Helvetica',...
    'FontSize',10,...
    'String','Time (Seconds)',...
    'Tag','TimePlotXLabel');

h5 = get(h3,'ylabel');
set(h5, 'Parent',h3,...
    'FontName','Helvetica',...
    'FontSize',10,...
    'String','Signal (V)',...
    'UserData',1,...
    'Tag','TimePlotYLabel');

h3a = uicontrol(...
'Parent',h2,...
'Units','characters',...
'FontSize',10,...
'HorizontalAlignment','left',...
'Position',[2.6 1.38461538461538 15 1.53846153846154],...
'String','File Position',...
'Style','text',...
'Tag','timeWinSet_stxt');

h3b = uicontrol(...
'Parent',h2,...
'Units','characters',...
'BackgroundColor',[0.9 0.9 0.9],...
'Position',[20 1.38461538461538 80 1.53846153846154],...
'String',{  'Slider' },...
'Style','slider',...
'Callback',@setTimeSlice_callback,...
'Tag','timeWinSet_slide');

h3c = uicontrol(...
'Parent',h2,...
'Units','characters',...
'FontSize',10,...
'HorizontalAlignment','left',...
'Position',[107 1.30769230769231 32.8 1.61538461538462],...
'String','Global Time View (sec)',... %Plotted Time Window (sec)
'Style','text',...
'Tag','PlotTimeSlice_stxt');

h3d = uicontrol(...
'Parent',h2,...
'Units','characters',...
'BackgroundColor',[1 1 1],...
'FontSize',10,...
'Position',[140 1.38461538461538 14 1.69230769230769],...
'String','0',...
'Style','edit',...
'Callback',@PlotTimeSlice_txt_callback,...
'Tag','PlotTimeSlice_txt');

h3e = uicontrol(...
'Parent',h2,...
'Units','characters',...
'Position',[151.5 16.2 4 2.30769230769231],... %[151.5 17 4 2.30769230769231]
'String','/\',...
'Callback',@TimePlotIncY_but_callback,...
'Tag','TimePlotY_but');

h3f = uicontrol(...
'Parent',h2,...
'Units','characters',...
'Position',[151.5 6 4 2.30769230769231],...%[151.5 6.8 4 2.30769230769231]
'String','\/',...
'Callback',@TimePlotDecY_but_callback,...
'Tag','TimePlotDecY_but');

h3g = uicontrol(...
'Parent',h2,...
'Units','characters',...
'Position',[151.5 10.2 4 4.30769],...  %[151.5 11 4 4.30769]
'String','A',...
'TooltipString','Auto Adjust',...
'Callback',@TimePlotResetY_but_callback,...
'Tag','TimePlotResetY_but');

%Spectral Analysis panel
h6 = uipanel(...
'Parent',h1,...
'Units','characters',...
'Title','Spectral Parameters',...
'Tag','Spectral_pan',...
'Clipping','on',...
'Position',[2 3 158.2 36]);

h7 = axes(...
'Parent',h6,...
'Units','pixels',...
'Position',[60 220 400 210],...%[50 220 400 220]
'Tag','SpectralPlot');

h8 = get(h7,'xlabel');
set(h8, 'Parent',h7,...
    'FontName','Helvetica',...
    'FontSize',10,...
    'String','Frequency (Hz)',...
    'Tag','SpectralPlotXLabel');

h9 = get(h7,'ylabel');
set(h9, 'Parent',h7,...
    'FontName','Helvetica',...
    'FontSize',10,...
    'String','Signal Power',...
    'Tag','SpectralPlotYLabel');

h6a = uipanel(...
'Parent',h6,...
'Units','characters',...
'Title','Spectral View Controls',...
'Tag','SpectControl_pan',...
'Clipping','on',...
'Position',[3.8 1.2 89 13]);

h10 = uicontrol(...
'Parent',h6a,...
'Units','characters',...
'FontSize',10,...
'HorizontalAlignment','left',...
'Position',[2 9.5 48.8 1.53846153846154],...
'String','Final Frequency Resolution (Hz)',...
'Style','text',...
'Tag','HzSet_stxt');

h11 = uicontrol(...
'Parent',h6a,...
'Units','characters',...
'BackgroundColor',[1 1 1],...
'FontSize',10,...
'Position',[79 9.5 7.2 1.53846153846154],...
'String','10',...
'Style','edit',...
'Callback',@HzSet_txt_callback,...
'Tag','HzSet_txt');

h12 = uicontrol(...
'Parent',h6a,...
'Units','characters',...
'BackgroundColor',[0.9 0.9 0.9],...
'Position',[2 7.3 84 1.53846153846154],...
'String',{  'Slider' },...
'Style','slider',...
'Callback',@HzSlider_callback,...
'Tag','HzSet_slide');

h13 = uicontrol(...
'Parent',h6a,...
'Units','characters',...
'FontSize',10,...
'HorizontalAlignment','left',...
'Position',[2 5.38 48.8 1.38461538461538],...
'String','Final Time Bin Size (sec)',...
'Style','text',...
'Tag','timebinSet_stxt');

h14 = uicontrol(...
'Parent',h6a,...
'Units','characters',...
'BackgroundColor',[1 1 1],...
'FontSize',10,...
'Position',[79 5.38 7.2 1.53846153846154],...
'String','3600',...
'Style','edit',...
'Callback',@timebinSet_txt_callback,...
'Tag','timebinSet_txt');

h15 = uicontrol(...
'Parent',h6a,...
'Units','characters',...
'BackgroundColor',[0.9 0.9 0.9],...
'Position',[2 3.2 84 1.53846153846154],...
'String',{  'Slider' },...
'Style','slider',...
'Callback',@TimeSlider_callback,...
'Tag','timebinSet_slide');

h15a = uicontrol(...
'Parent',h6a,...
'Units','characters',...
'FontSize',10,...
'Position',[2.2 0.615384615384615 28.6 1.76923076923077],...
'String','log Scale Ordinate ',...
'Style','checkbox',...
'Callback',@setY2log_callback,...
'Tag','SemiLog_chk');

h15b = uicontrol(...
'Parent',h6a,...
'Units','characters',...
'FontSize',10,...
'HorizontalAlignment','left',...
'Position',[41 0.692307692307692 45 1.53846153846154],...
'String','Max Displayed Frequency (Hz)',...
'Style','text',...
'Tag','maxSpectFreq_stxt');

h15c = uicontrol(...
'Parent',h6a,...
'Units','characters',...
'BackgroundColor',[1 1 1],...
'FontSize',10,...
'Position',[79 0.692307692307692 7.2 1.53846153846154],...
'String','128',...
'Style','edit',...
'Callback',@maxHzSet_txt_callback,...
'Tag','maxSpectFreq_txt');

h6b = uicontrol(...
'Parent',h6,...
'Units','characters',...
'Position',[95 1.2 50 1.84615384615385],...
'String','Heat Map',...
'Callback',@createHeatMap_callback,...
'Tag','CreateHeatMap_but');

%Spectral Bands Pan
h16 = uipanel(...
'Parent',h6,...
'Units','pixels',...
'Title','Spectral Bands',...
'Tag','sBands_pan',...
'Clipping','on',...
'Position',[472 50 305 400]);

h17 = uipanel(...
'Parent',h16,...
'Units','pixels',...
'Title','Band Calculations',...
'Tag','BandCalc_pan',...
'Clipping','on',...
'Position',[10 190 280 190]);

h18 = uitable(...
'Parent',h17,...
'Units','characters',...
'BackgroundColor',[0.870588235294118 0.92156862745098 0.980392156862745;0.96078431372549 0.96078431372549 0.96078431372549],...
'ColumnFormat',{  [] [] },...
'ColumnEditable', [true, true],...
'ColumnName',{  'Start (Hz)'; 'Stop (Hz)' },...
'ColumnWidth',{  'auto' 'auto' },...
'Data',{  blanks(0) blanks(0); blanks(0) blanks(0); blanks(0) blanks(0); blanks(0) blanks(0); blanks(0) blanks(0) },...
'FontSize',10,...
'Position',[4.8 3 46.2 9.69230769230769],...
'RowName',{  'Band 1'; 'Band 2'; 'Band 3'; 'Band 4'; 'Band 5' },...
'UserData',[],...
'CellEditCallback',@BandCalc_tab_callback,...
'Tag','BandCalc_tab' );

h19 = uicontrol(...
'Parent',h17,...
'Units','characters',...
'FontSize',10,...
'Position',[4.8 0.615384615384615 48.2 1.61538461538462],...
'String','Normalize to total spectral power',...
'Style','checkbox',...
'Tag','normSpecta_chk');


h20 = uipanel(...
'Parent',h16,...
'Units','pixels',...
'Title','Band Ratio''s',...
'Tag','BandRatios_pan',...
'Clipping','on',...
'Position',[10 10 282 178]);

%
h21 = uicontrol(...
'Parent',h20,...
'Units','characters',...
'FontSize',10,...
'HorizontalAlignment','left',...
'Position',[3.4 9.92307692307693 8.6 1.15384615384615],...
'String','Ratio 1',...
'Style','text',...
'Tag','ratio1_stxt' );

h22 = uicontrol(...
'Parent',h20,...
'Units','characters',...
'FontSize',10,...
'HorizontalAlignment','left',...
'Position',[3.4 7.92307692307693 8.6 1.15384615384615],...
'String','Ratio 2',...
'Style','text',...
'Tag','ratio2_stxt');

h23 = uicontrol(...
'Parent',h20,...
'Units','characters',...
'FontSize',10,...
'HorizontalAlignment','left',...
'Position',[3.4 5.84615384615385 8.6 1.15384615384615],...
'String','Ratio 3',...
'Style','text',...
'Tag','ratio3_stxt' );

h24 = uicontrol(...
'Parent',h20,...
'Units','characters',...
'FontSize',10,...
'HorizontalAlignment','left',...
'Position',[3.4 3.76923076923077 9 1.15384615384615],...
'String','Ratio 4',...
'Style','text',...
'Tag','ratio4_stxt');

h25 = uicontrol(...
'Parent',h20,...
'Units','characters',...
'FontSize',10,...
'HorizontalAlignment','left',...
'Position',[3.4 1.69230769230769 9 1.15384615384615],...
'String','Ratio 5',...
'Style','text',...
'Tag','ratio5_stxt' );

%
h26 = uicontrol(...
'Parent',h20,...
'Units','characters',...
'FontSize',10,...
'Position',[31.8 10.1538461538462 2.4 0.923076923076923],...
'String','/',...
'Style','text',...
'Tag','div1_stxt');

h27 = uicontrol(...
'Parent',h20,...
'Units','characters',...
'FontSize',10,...
'Position',[31.8 8.07692307692308 2.4 0.923076923076923],...
'String','/',...
'Style','text',...
'Tag','div2_stxt' );

h28 = uicontrol(...
'Parent',h20,...
'Units','characters',...
'FontSize',10,...
'Position',[31.8 6 2.4 0.923076923076923],...
'String','/',...
'Style','text',...
'Tag','div3_stxt' );

h29 = uicontrol(...
'Parent',h20,...
'Units','characters',...
'FontSize',10,...
'Position',[31.8 3.92307692307693 2.4 0.923076923076923],...
'String','/',...
'Style','text',...
'Tag','div4_stxt');

h30 = uicontrol(...
'Parent',h20,...
'Units','characters',...
'FontSize',10,...
'Position',[31.8 1.92307692307692 2.4 0.923076923076923],...
'String','/',...
'Style','text',...
'Tag','div5_stxt');

%
h31 = uicontrol(...
'Parent',h20,...
'Units','characters',...
'BackgroundColor',[1 1 1],...
'FontSize',10,...
'Position',[15.8 9.53846153846154 15 1.92307692307692],...
'String',BandRatioCell,...
'Style','popupmenu',...
'Value',1,...
'Tag','Ratio1Num_pul');

h32 = uicontrol(...
'Parent',h20,...
'Units','characters',...
'BackgroundColor',[1 1 1],...
'FontSize',10,...
'Position',[15.8 7.46153846153846 15 1.92307692307692],...
'String',BandRatioCell,...
'Style','popupmenu',...
'Value',1,...
'Tag','Ratio2Num_pul');

h33 = uicontrol(...
'Parent',h20,...
'Units','characters',...
'BackgroundColor',[1 1 1],...
'FontSize',10,...
'Position',[15.8 5.38461538461539 15 1.92307692307692],...
'String',BandRatioCell,...
'Style','popupmenu',...
'Value',1,...
'Tag','Ratio3Num_pul');

h34 = uicontrol(...
'Parent',h20,...
'Units','characters',...
'BackgroundColor',[1 1 1],...
'FontSize',10,...
'Position',[15.8 3.30769230769231 15 1.92307692307692],...
'String',BandRatioCell,...
'Style','popupmenu',...
'Value',1,...
'Tag','Ratio4Num_pul');

h35 = uicontrol(...
'Parent',h20,...
'Units','characters',...
'BackgroundColor',[1 1 1],...
'FontSize',10,...
'Position',[15.8 1.30769230769231 15 1.92307692307692],...
'String',BandRatioCell,...
'Style','popupmenu',...
'Value',1,...
'Tag','Ratio5Num_pul');

%
h36 = uicontrol(...
'Parent',h20,...
'Units','characters',...
'BackgroundColor',[1 1 1],...
'FontSize',10,...
'Position',[35.6 9.53846153846154 15 1.92307692307692],...
'String',BandRatioCell,...
'Style','popupmenu',...
'Value',1,...
'Tag','Ratio1Den_pul');

h37 = uicontrol(...
'Parent',h20,...
'Units','characters',...
'BackgroundColor',[1 1 1],...
'FontSize',10,...
'Position',[35.6 7.46153846153846 15 1.92307692307692],...
'String',BandRatioCell,...
'Style','popupmenu',...
'Value',1,...
'Tag','Ratio2Den_pul');

h38 = uicontrol(...
'Parent',h20,...
'Units','characters',...
'BackgroundColor',[1 1 1],...
'FontSize',10,...
'Position',[35.6 5.38461538461539 15 1.92307692307692],...
'String',BandRatioCell,...
'Style','popupmenu',...
'Value',1,...
'Tag','Ratio3Den_pul');

h39 = uicontrol(...
'Parent',h20,...
'Units','characters',...
'BackgroundColor',[1 1 1],...
'FontSize',10,...
'Position',[35.6 3.30769230769231 15 1.92307692307692],...
'String',BandRatioCell,...
'Style','popupmenu',...
'Value',1,...
'Tag','Ratio4Den_pul');

h40 = uicontrol(...
'Parent',h20,...
'Units','characters',...
'BackgroundColor',[1 1 1],...
'FontSize',10,...
'Position',[35.6 1.30769230769231 15 1.92307692307692],...
'String',BandRatioCell,...
'Style','popupmenu',...
'Value',1,...
'Tag','Ratio5Den_pul');

% Buttons
h41 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'Position',[123.4 0.692307692307695 11.8 2.30769230769231],...
'String','Cancel',...
'Callback',@cancel_but_callback,...
'Tag','cancel_but');

h42 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'Position',[135.4 0.692307692307695 11.8 2.30769230769231],...
'String','Save',...
'Callback',@save_but_callback,...
'Tag','save_but' );

h43 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'Position',[147.4 0.692307692307695 11.8 2.30769230769231],...
'String','OK',...
'Callback',@ok_but_callback,...
'Tag','ok_but');

h44 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'Position',[1.8 0.692307692307695 25 2.30769230769231],...
'String','Print Figure',...
'Callback',@print_but_callback,...
'Tag','print_but');

% create structure of handles
handles = guihandles(h1);

function [handles] = GenerateHEATMAP(Pyy)
%%%%%%%%%%%%%%%%%%%
h100 = figure(...
'Color',[0.941176470588235 0.941176470588235 0.941176470588235],...
'Position',[0 0 1 1],...
'Name','Heat Map',...
'PaperPosition',get(0,'defaultfigurePaperPosition'),...
'Position',[827 154 800 600],...
'Resize','off',...
'Toolbar','figure',...
'Tag','HeatMapFigure',...
'DeleteFcn',@deleteHeatMap_callback,...
'Visible','off');
%'MenuBar','none',...

h101 = axes(...
'Parent',h100,...
'Units','pixels',...
'Position',[60 60 720 520],...%[50 220 400 220]
'Tag','HeatMapAxes');

h102 = image(Pyy',...
'Parent',h101,...
'CDataMapping','scaled',...
'Tag','HeatMapPlot');
set(h101,'YDir','normal');
colormap(h101,'hot');

h103 = get(h101,'xlabel');
set(h103, 'Parent',h101,...
    'FontName','Helvetica',...
    'FontSize',10,...
    'String','Time (Sec)',...
    'Tag','HeatMapPlotXLabel');

h104 = get(h101,'ylabel');
set(h104, 'Parent',h101,...
    'FontName','Helvetica',...
    'FontSize',10,...
    'String','Frequency (Hz)',...
    'Tag','HeatMapPlotYLabel');

h105 = uicontrol(...
'Parent',h100,...
'Units','characters',...
'Position',[125 0.1 35 1.7],...
'String','Edit Color Map Sensitivity',...
'BackgroundColor',[0.871 0.922 0.98],...
'TooltipString','Edit -> Colormap',...
'Callback',@EditColorMapping_but_callback,...
'Tag','EditColorMapping_but');

% create structure of handles
handles = guihandles(h100);

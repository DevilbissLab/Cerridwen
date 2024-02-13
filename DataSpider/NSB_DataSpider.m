function [] = NSB_DataSpider(path)
%
%Do we want to add licencing to this???
%

%%Setup GUI
[GUIFig, handles] = GenerateGUI();

%% Now that GUI is setup
% load the parameter file
[~,handles.parameters] = NSB_ParameterHandler('new');

if nargin > 0
    handles.paramaters.DataSpider.StartDirs = path;
end

% Set relevant fields
global goQuit
goQuit = false;
set(handles.Title_stxt,'String',handles.paramaters.DataSpider.GUI.Title);

%set image to open browser
ImageHandle = get(handles.NexStepImage);
set(ImageHandle.Children,'ButtonDownFcn','web http://www.nexstepbiomarkers.com -browser');

% Update handles structure
guidata(GUIFig, handles);

%% Begin Processing
%pause(handles.paramaters.DataSpider.PollPeriod);
StartTic = tic;
while ~goQuit
    %collect full list of files
    %this includes decrypt, DataTank, and Archive << and must be fixed
    SpiderFileList = fuf(handles.paramaters.DataSpider.StartDirs,0,'detail');
    %parse New files one by one
    for curFile = 1:length(SpiderFileList)
        set(handles.Folder_stxt,'String',['Parsing ... ',SpiderFileList{curFile}]);
        [pathstr, name, ext] = fileparts(SpiderFileList{curFile});
        switch ext
            case '.sk'
                %the issues is tha all conduit files are .sk files
                
                %dirty code but will work for now
                if strcmpi(handles.paramaters.DataSpider.GUI.Licence,'NSB')
                    %silverkey file
                    if exist(fullfile(pathstr,'decrypt')) == 0
                        try
                        mkdir(fullfile(pathstr,'decrypt'));
                        catch ME
                            disp(ME);
                        end  
                    end
                    
                    %generate folder outside of search path
                    seps = strfind(pathstr,filesep);
                    uppathstr = pathstr(1:seps(end));
                    
                    if exist(fullfile(uppathstr,'DataTank')) == 0
                        mkdir(fullfile(uppathstr,'DataTank'));
                    end
                    if exist(fullfile(uppathstr,'Archive')) == 0
                        mkdir(fullfile(uppathstr,'Archive'));
                    end
                    %decrypt files and put into temp storage (unknown number of files)
                    retVal = BCiLab_Decrypt(SpiderFileList{curFile}, fullfile(pathstr,'decrypt'),...
                        handles.paramaters.DataSpider.HIPAA.ScrubIDinfo, handles.paramaters.DataSpider.HIPAA.ShredPartial);
                    %Add files to database
                    %ISSUE (What happends if files already exist in dir)
                    DatafileNames = fuf(fullfile(pathstr,'decrypt'),0); %find all newly decrypted files
                    for curDecryptFile = 1:length(DatafileNames)
                        % 1) Add to DataBase
                        status = NSB_dbHandler(handles.paramaters.DataSpider.XMLdbFile, 'ADD',...
                            fullfile(pathstr,'decrypt',DatafileNames{curDecryptFile}), fullfile(uppathstr,'DataTank'));
                        % 2) Move file to Holding Dir
                        [status,message,messageid]=movefile(fullfile(pathstr,'decrypt',DatafileNames{curDecryptFile}),...
                            fullfile(uppathstr,'DataTank',DatafileNames{curDecryptFile}));  
                    end 
                end
                %3) move .sk file into Archive
                [status,message,messageid]=movefile(SpiderFileList{curFile},...
                    fullfile(uppathstr,'Archive',[name,ext]));
                set(handles.Folder_stxt,'String',['Archiving ... ',SpiderFileList{curFile}]);
                try rmdir(fullfile(pathstr,'decrypt')); pause(1); end

            case '.csv'

        end
    end
    
    if ~isempty(SpiderFileList)
    set(handles.Folder_stxt,'String','Cleaning and Saving Database ...');
    %Clean XML
    
    %save XML
    status = NSB_dbHandler(handles.paramaters.DataSpider.XMLdbFile, 'SAVE');
    
    %Post to Oracle
    end
    
    if ~goQuit
    pausetime = handles.paramaters.DataSpider.PollPeriod-ceil(toc(StartTic));
    if pausetime < 0, pausetime = 0; end
    set(handles.Folder_stxt,'String','Waiting for next run ...');
    pause(pausetime);
    StartTic = tic;
    end
end

close(GUIFig);

%% Callbacks
function BrandingImg_CreateFcn(hObject, eventdata, handles)
try
axes(hObject);
logo = imread('NexStepHeader.png');
image(logo);
axis('off');
axis('image');
catch
    disp('No Image: NexStepHeader.png');
end

function Quit_but_Callback(hObject, eventdata, handles)
global goQuit
goQuit = true;
handles = guidata(gcbo);
set(handles.Folder_stxt,'String','Quitting (may take several seconds) ...');


%% Generate GUI
function [GUIFig, handles] = GenerateGUI()

GUIFig = figure(...
'Units','characters',...
'MenuBar','none',...
'Name','NSB_DataSpider',...
'NumberTitle','off',...
'Color',[0.941176470588235 0.941176470588235 0.941176470588235],...
'Position',[103.8 45.1538461538462 112.2 16.3076923076923],...
'Resize','off',...
'HandleVisibility','callback',...
'Tag','DataSpider_GUI',...
'Visible','on');

h2 = axes(...
'Parent',GUIFig,...
'Units','characters',...
'Position',[-0.2 8.46153846153846 40.2 7.76923076923077],...
'CreateFcn', {@BrandingImg_CreateFcn});
set(h2,'Tag','NexStepImage');

h3 = uicontrol(...
'Parent',GUIFig,...
'Units','characters',...
'FontSize',12,...
'Position',[49.8 13.1538461538462 56 2],...
'String','NexStepBiomarkers Data Spider v.0.1',...
'Style','text',...
'Tag','Title_stxt' );

h4 = uicontrol(...
'Parent',GUIFig,...
'Units','characters',...
'FontSize',12,...
'HorizontalAlignment','left',...
'Position',[2.2 4.69230769230769 21.2 1.92307692307692],...
'String','Spider Status',...
'Style','text',...
'Tag','Status_stxt' );

h5 = uicontrol(...
'Parent',GUIFig,...
'Units','characters',...
'FontSize',10,...
'HorizontalAlignment','left',...
'Position',[25 2.69230769230769 85 3.76923076923077],...
'String','Waiting for Next Crawl ...',...
'Style','text',...
'Tag','Folder_stxt');

h6 = uicontrol(...
'Parent',GUIFig,...
'Units','characters',...
'Callback',{@Quit_but_Callback},...
'Position',[89.8 0.846153846153846 20 2.46153846153846],...
'String','Quit',...
'Tag','Quit_but' );

% create structure of handles
handles = guihandles(GUIFig);
function varargout = NSB_DataConduit(varargin)
% NSB_DATACONDUIT MATLAB code for NSB_DataConduit.fig
%      NSB_DATACONDUIT, by itself, creates a new NSB_DATACONDUIT or raises the existing
%      singleton*.
%
%      H = NSB_DATACONDUIT returns the handle to a new NSB_DATACONDUIT or the handle to
%      the existing singleton*.
%
%      NSB_DATACONDUIT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in NSB_DATACONDUIT.M with the given input arguments.
%
%      NSB_DATACONDUIT('Property','Value',...) creates a new NSB_DATACONDUIT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before NSB_DataConduit_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to NSB_DataConduit_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help NSB_DataConduit

% Last Modified by GUIDE v2.5 06-Jun-2013 21:53:37

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @NSB_DataConduit_OpeningFcn, ...
                   'gui_OutputFcn',  @NSB_DataConduit_OutputFcn, ...
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


% --- Executes just before NSB_DataConduit is made visible.
function NSB_DataConduit_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to NSB_DataConduit (see VARARGIN)

% Choose default command line output for NSB_DataConduit
handles.output = hObject;

%Load the ParamatersFile
handles.params = NSB_DataConduitParameters();

%Set fields
set(handles.version_txt,'String',handles.params.DataConduit.version);
set(handles.date_txt,'String',datestr(now,'mmmm dd, yyyyHH:MM:SS PM'));
set(handles.source_input,'String',handles.params.DataConduit.sourcePath);
set(handles.sourceDir_lst,'Max',2); %Allow multiple selection items

[dirList,handles.params.DataConduit.sourceStruct] = getSourceList(handles.params.DataConduit.sourcePath, handles);
set(handles.sourceDir_lst,'String',dirList);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes NSB_DataConduit wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = NSB_DataConduit_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function source_input_Callback(hObject, eventdata, handles)
% hObject    handle to source_input (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of source_input as text
%        str2double(get(hObject,'String')) returns contents of source_input as a double

newPath = get(hObject,'String');
if ~isempty(newPath)
    %loadup list box
    try
    [dirList,handles.params.DataConduit.sourceStruct] = getSourceList(handles.params.DataConduit.sourcePath, handles);
    set(handles.sourceDir_lst,'String',dirList);
    catch
        errordlg('Not a Valid Directory','NSB Data Conduit');
        set(hObject,'String',handles.params.DataConduit.sourcePath);
        return;
    end
        handles.params.DataConduit.sourcePath = newPath;
else
    set(hObject,'String',handles.params.DataConduit.sourcePath);
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function source_input_CreateFcn(hObject, eventdata, handles)
% hObject    handle to source_input (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in sourceBrowse_but.
function sourceBrowse_but_Callback(hObject, eventdata, handles)
% hObject    handle to sourceBrowse_but (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

oldpath = handles.params.DataConduit.sourcePath;
handles.params.DataConduit.sourcePath = uigetdir(handles.params.DataConduit.sourcePath);
if ~ischar(handles.params.DataConduit.sourcePath)
    handles.params.DataConduit.sourcePath = oldpath;
end

set(handles.source_input, 'String', handles.params.DataConduit.sourcePath);
%loadup list box
[dirList,handles.params.DataConduit.sourceStruct] = getSourceList(handles.params.DataConduit.sourcePath, handles);
set(handles.sourceDir_lst,'Value',1);
set(handles.sourceDir_lst,'String',dirList);
guidata(hObject, handles);


% --- Executes on selection change in sourceDir_lst.
function sourceDir_lst_Callback(hObject, eventdata, handles)
% hObject    handle to sourceDir_lst (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns sourceDir_lst contents as cell array
%        contents{get(hObject,'Value')} returns selected item from sourceDir_lst

% val = get(hObject,'Value');
% %behavior: 
% %loadup list box
% if ~strcmpi(handles.params.DataConduit.sourceStruct(val).name,'.') && ~strcmpi(handles.params.DataConduit.sourceStruct(val).name,'..')
%     try
%         newPath = fullfile(handles.params.DataConduit.sourcePath, handles.params.DataConduit.sourceStruct(val).name);
%         [dirList,handles.params.DataConduit.sourceStruct] = getSourceList(newPath, handles);
%         set(handles.sourceDir_lst,'String',dirList);
%         catch
%             errordlg('Not a Valid Directory','NSB Data Conduit');
%             set(hObject,'String',handles.params.DataConduit.sourcePath);
%             return;
%     end
%     handles.params.DataConduit.sourcePath = newPath;
%     set(handles.source_input,'String',newPath)
% elseif strcmpi(handles.params.DataConduit.sourceStruct(val).name,'..')
%     
% end
% guidata(hObject, handles);




% --- Executes during object creation, after setting all properties.
function sourceDir_lst_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sourceDir_lst (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function Branding_IMG_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Branding_IMG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

try
axes(hObject);
[imageData,map] = imread('NexStepHeader.png');
h = image(imageData);colormap(map);
axis off;axis image;
%set image to open browser
ImageHandle = get(hObject,'Children');
set(ImageHandle,'ButtonDownFcn','web http://www.nexstepbiomarkers.com -browser');
catch
    disp('No Image: NexStepHeader.png');
end


function [dirList,dirStruct] = getSourceList(myDir, handles)
%dirList = is a cell array
%myDir = is a string
dirStruct = dir(myDir); 
dirList = {dirStruct(:).name};
for n = 1:length(dirStruct)
    if dirStruct(n).isdir == true
        dirList{n} = ['<dir> ', dirList{n}];
    end
end


% --- Executes on button press in send_but.
function send_but_Callback(hObject, eventdata, handles)
% hObject    handle to send_but (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

try
    %FTPdata = NSBConduitData();
    load('C:\NexStepBiomarkers\NSB_LicenseFile.lic', '-mat');%load new licnece file
catch
    errordlg('A license is necessary for this software. Please contact: sales@NexstepBiomarkers.com','NexStep Biomarkers: Data Conduit');
    return;
end

%Setup for status window
txt = get(handles.status_txt,'String');
if iscell(txt)
    rows = length(txt);
else
    txt = cell(0);
    txt{1} = get(handles.status_txt,'String');
    rows = 1;
end
%new way of handling overrun
%Scroll Status pannel
rowchars =  ceil(cellfun(@length,txt)/24); %25-1 characters in window
if sum(rowchars) >= handles.params.DataConduit.GUIStatusLines
    rows = find(cumsum(flipud(rowchars)) >= handles.params.DataConduit.GUIStatusLines,1,'first');
    txt = txt(length(txt)-rows+1:end);
    set(handles.status_txt,'String',txt);
end


%Determine if SilverKey Exists
SkExists = false;
if exist('C:\Program Files (x86)\Kryptel','dir') == 7
    SkCmd = 'C:\Program Files (x86)\Kryptel\SkCmd.exe';
    SkExists = true;
elseif exist('C:\Program Files\Kryptel','dir') == 7
    SkCmd = 'C:\Program Files\Kryptel\SkCmd.exe';
    SkExists = true;
end

try
    if SkExists
        tech = inputdlg('Enter Data Upload ID','NSB DataConduit');
        if isempty(tech)
            msgbox('No Data Upload ID: Encryption Aborted','NSB DataConduit','warn');
            return;
        end
        tech = tech{:};
        rows = rows+1; txt{rows,1} = ['Data Upload ID = ', tech];
        set(handles.status_txt,'String',txt);
        rowchars =  ceil(cellfun(@length,txt)/24); %25-1 characters in window
        if sum(rowchars) >= handles.params.DataConduit.GUIStatusLines
            rows = find(cumsum(flipud(rowchars)) >= handles.params.DataConduit.GUIStatusLines,1,'first');
            txt = txt(length(txt)-rows+1:end);
            set(handles.status_txt,'String',txt);
        end
        
        %by using fuf it must include BSD cright notice
        %Create a file list
        EncryptList = cell(0);
        SelectedFiles = get(handles.sourceDir_lst,'Value');
        for curCell = 1:length(SelectedFiles)
            CurFile = handles.params.DataConduit.sourceStruct(SelectedFiles(curCell)).name;
            EncryptList = [EncryptList; fuf(fullfile(handles.params.DataConduit.sourcePath, CurFile),'detail')];
        end
        %generate file list
        fid = fopen(fullfile(handles.params.DataConduit.dataDir, 'EncryptFileList.txt'), 'w');
        for curCell = 1:length(EncryptList)
            fprintf(fid, '%s\n', EncryptList{curCell});
        end
        fclose(fid);
        
        %Invoke Silverkey
        filename = strcat(tech, '_', num2str(now), '.sk');
        cmdStr = ['"',SkCmd,'" /E "',fullfile(handles.params.DataConduit.dataDir, filename),...
            '" /P ',FTPdata.Silverkey, ...
            ' /L ' fullfile(handles.params.DataConduit.dataDir, 'EncryptFileList.txt')];
        rows = rows+1;txt{rows,1} = 'Data Encryping ... ';
        set(handles.status_txt,'String',txt);
        rowchars =  ceil(cellfun(@length,txt)/24); %25-1 characters in window
        if sum(rowchars) >= handles.params.DataConduit.GUIStatusLines
            rows = find(cumsum(flipud(rowchars)) >= handles.params.DataConduit.GUIStatusLines,1,'first');
            txt = txt(length(txt)-rows+1:end);
            set(handles.status_txt,'String',txt);
        end
        [out, outStr] = system(cmdStr);
        
        if out == 0
            rows = rows+1;txt{rows,1} = 'Data Encryption ... OK';
            set(handles.status_txt,'String',txt);
        else
            srtIDX = strfind(outStr,'>>');  % deal with a security issue regarding possible printing of passcode
            msgbox({'ERROR: Data NOT Encrypted !','Check SilverKey installation and manually encrypt C:\NexStepBiomarkers\Data',['Error: ',outStr(srtIDX(end):end)]},'NSB DataConduit','error');
            rows = rows+1;txt{rows,1} = 'Data Encryption ... FAILED';
            set(handles.status_txt,'String',txt);
        end
        handles.BCILabData.FileName = filename;
    else
        errordlg('Silver Key does not seem to exist. Check SilverKey installation and manually install.', 'NSB DataConduit')
        rows = rows+1;txt{rows,1} = 'Data Encryption ... Failed';
        set(handles.status_txt,'String',txt);
    end
catch me
    errordlg({me.identifier, me.message});
    disp([handles.paramaters.LogFile,': Encrypt_item_Callback: Returned ', me.message]);
    rows = rows+1;txt{rows,1} = 'Data Encryption ... FAILED';
    set(handles.status_txt,'String',txt);
end
%Scroll Status pannel
rowchars =  ceil(cellfun(@length,txt)/24); %25-1 characters in window
if sum(rowchars) >= handles.params.DataConduit.GUIStatusLines
    rows = find(cumsum(flipud(rowchars)) >= handles.params.DataConduit.GUIStatusLines,1,'first');
    txt = txt(length(txt)-rows+1:end);
    set(handles.status_txt,'String',txt);
end


% sFtp Segment
% FTP server can only handle 10 concurent connections. limit to 5.
%ftpsLocation = 'C:\NexStepBiomarkers\ftps.exe';
ftpsLocation = 'C:\NexStepBiomarkers\WinSCP.com';

if exist(ftpsLocation,'file') == 2
    sftp = true;
else
    sftp = false;
end
if ~sftp
    answer = questdlg('sFTP not avalable! Do you want to continue this non-HIPAA process?', ...
        'NSB DataConduit', 'Yes', 'Abort', 'Abort');
    switch answer
        case 'Yes'
            sftp = false;
        case 'Abort'
            rows = rows+1;txt{rows,1} = 'Data Uploading ... FAILED';
            set(handles.status_txt,'String',txt);
            %Scroll Status pannel
            rowchars =  ceil(cellfun(@length,txt)/24); %25-1 characters in window
            if sum(rowchars) >= handles.params.DataConduit.GUIStatusLines
                rows = find(cumsum(flipud(rowchars)) >= handles.params.DataConduit.GUIStatusLines,1,'first');
                txt = txt(length(txt)-rows+1:end);
                set(handles.status_txt,'String',txt);
            end
            return;
    end
end

if sftp
    files = dir(fullfile(handles.params.DataConduit.dataDir,'*.sk'));
    if isempty(files)
        errordlg('NO Encrypted files to upload','NSB DataConduit');
        retVal = false;
        return;
    end
    try
        outStr = [];
        %do this serially ...
        UploadWait_h = waitbar(0,'Block ','Name','Uploading ...');
        for curfile = 1:length(files)
            %generate SCP script command file for each file
            fid = fopen(fullfile(handles.params.DataConduit.dataDir, 'ftpcmds.txt'), 'w');
            fprintf(fid, '%s\n', 'option batch abort');
            fprintf(fid, '%s\n', 'option confirm off');
            fprintf(fid, '%s\n', 'option reconnecttime 300');
            %New 2013 Certificate
            fprintf(fid, '%s\n', ['open ftps://',FTPdata.username,':',FTPdata.pwd,'@ftp.NexStepBiomarkers.com -explicittls -certificate="66:58:9f:39:f9:a2:ea:9b:c4:cd:2a:6a:8d:2d:f6:70:7b:2c:17:8d" -rawsettings PingType=2 PingIntervalSecs=10']);
%            fprintf(fid, '%s\n', ['open ftps://',FTPdata.username,':',FTPdata.pwd,'@ftp.NexStepBiomarkers.com -explicittls -certificate="ad:0e:0c:8a:09:5f:53:cc:cb:c4:e7:90:5d:0d:36:93:07:7a:b8:b1" -rawsettings PingType=2 PingIntervalSecs=10']);
            fprintf(fid, '%s\n', 'cd /Uploads');
            fprintf(fid, '%s\n', 'option transfer binary');
            fprintf(fid, '%s\n', ['put "', fullfile(handles.params.DataConduit.dataDir, files(curfile).name),'" -resume']);
            fprintf(fid, '%s\n', 'exit');
            fclose(fid);
            % run winSCP
            cmdstr = [ftpsLocation ' /script=', fullfile(handles.params.DataConduit.dataDir), filesep, 'ftpcmds.txt /log="winscp.log"'];
            rows = rows+1;txt{rows,1} = 'Data Uploading ... ';
            set(handles.status_txt,'String',txt);
            
            if rows >= handles.params.DataConduit.GUIStatusLines
                txt = txt{end-handles.params.DataConduit.GUIStatusLines:end};
                set(handles.status_txt,'String',txt);
                rows = handles.params.DataConduit.GUIStatusLines;
            end
            waitbar(curfile/length(files),UploadWait_h,['Transfering File = ',num2str(curfile),' of ',num2str(length(files))]);
            %this will wait until command is done.
            [out(curfile), outStr{curfile}] = system(cmdstr); % out should return 0 if OK
            
            if out(end) == 0
                retVal = true;
                %Clean up Files
                system(['del "',fullfile(handles.params.DataConduit.dataDir, 'ftpcmds.txt"')]);
                system(['del "',fullfile(handles.params.DataConduit.dataDir, files(curfile).name),'"']);
                rows = rows+1;txt{rows,1} = [files(curfile).name, ' Upload ... OK'];
                set(handles.status_txt,'String',txt);
            else
                retVal = false;
                system(['del ',fullfile(handles.params.DataConduit.dataDir, 'ftpcmds.txt')]);
                msgbox({'ERROR: Data NOT Uploaded !', 'Check with NexStepBiomarkers to manually Upload Data',['Error: ',outStr{end}]},'NSB DataConduit','error');
                rows = rows+1;txt{rows,1} = [files(curfile).name, ' Upload ... FAILED'];
                set(handles.status_txt,'String',txt);
            end
            %Scroll Status pannel
            rowchars =  ceil(cellfun(@length,txt)/24); %25-1 characters in window
            if sum(rowchars) >= handles.params.DataConduit.GUIStatusLines
                rows = find(cumsum(flipud(rowchars)) >= handles.params.DataConduit.GUIStatusLines,1,'first');
                txt = txt(length(txt)-rows+1:end);
                set(handles.status_txt,'String',txt);
            end
            
        end
        delete(UploadWait_h);
        uploadedFileName = [files(~out).name];
        
    catch me
        errordlg({me.identifier, me.message, ['Line = ', num2str(me.stack(1).line)]});
        disp('Could not Open FTPs connection for upload ...');
        disp(['Reason: ',me.message]);
        retVal = false;
        rows = rows+1;txt{rows,1} = 'Data Uploading ... FAILED';
        set(handles.status_txt,'String',txt);
        %Scroll Status pannel
        rowchars =  ceil(cellfun(@length,txt)/24); %25-1 characters in window
        if sum(rowchars) >= handles.params.DataConduit.GUIStatusLines
            rows = find(cumsum(flipud(rowchars)) >= handles.params.DataConduit.GUIStatusLines,1,'first');
            txt = txt(length(txt)-rows+1:end);
            set(handles.status_txt,'String',txt);
        end
        try
            delete(UploadWait_h);
        end
        return;
    end
%         
%         
%         
%         if length(files) <= 5
%             %generate SCP script command file
%             fid = fopen(fullfile(handles.params.DataConduit.dataDir, 'ftpcmds.txt'), 'w');
%             fprintf(fid, '%s\n', 'option batch abort');
%             fprintf(fid, '%s\n', 'option confirm off');
%             fprintf(fid, '%s\n', 'option reconnecttime 300');
%             %fprintf(fid, '%s\n', 'option log "winscp.log"');
%             for curfile = 1:length(files)
%                 %fprintf(fid, '%s\n', ['open ftps://',FTPdata.username,':',FTPdata.pwd,'@ftp.NexStepBiomarkers.com -explicittls -certificate="36:2c:61:2c:82:3f:9e:80:0e:f4:15:ed:0e:f7:d7:16:03:d0:70:c4"']);
%                 %fprintf(fid, '%s\n', ['open ftps://',FTPdata.username,':',FTPdata.pwd,'@ftp.NexStepBiomarkers.com -explicittls -certificate="ad:0e:0c:8a:09:5f:53:cc:cb:c4:e7:90:5d:0d:36:93:07:7a:b8:b1"']);
%                 fprintf(fid, '%s\n', ['open ftps://',FTPdata.username,':',FTPdata.pwd,'@ftp.NexStepBiomarkers.com -explicittls -certificate="ad:0e:0c:8a:09:5f:53:cc:cb:c4:e7:90:5d:0d:36:93:07:7a:b8:b1" -rawsettings PingType=2 PingIntervalSecs=10']);
%                 fprintf(fid, '%s\n', 'cd /Uploads');
%                 fprintf(fid, '%s\n', 'option transfer binary');
%                 fprintf(fid, '%s\n', ['put "', fullfile(handles.params.DataConduit.dataDir, files(curfile).name),'" -resume']);
%             end
%             uploadedFileName = [files(:).name];
%             fprintf(fid, '%s\n', 'exit');
%             fclose(fid);
%             % run winSCP
%             cmdstr = [ftpsLocation ' /script=', fullfile(handles.params.DataConduit.dataDir), filesep, 'ftpcmds.txt /log="winscp.log"'];
%             %cmdstr = [ftpsLocation ' /console /script=', fullfile(handles.params.DataConduit.dataDir), filesep, 'ftpcmds.txt'];
%             rows = rows+1;txt{rows,1} = 'Data Uploading ... ';
%             set(handles.status_txt,'String',txt);
%             [out, outStr] = system(cmdstr);% outshould return 0
%             
%             %%%%%%%%%%%%%%%%
%             if ~out
%                 retVal = true;
%                 %Clean up Files
%                 system(['del ',fullfile(handles.params.DataConduit.dataDir, 'ftpcmds.txt')]);
%                 for curfile = 1:length(files)
%                     system(['del ',fullfile(handles.params.DataConduit.dataDir, files(curfile).name)]);
%                 end
%                 rows = rows+1;txt{rows,1} = 'Data Uploading ... OK';
%                 set(handles.status_txt,'String',txt);
%             else
%                 retVal = false;
%                 msgbox({'ERROR: Data NOT Uploaded !', 'Check with NexStepBiomarkers to manually Upload Data',['Error: ',outStr]},'NSB DataConduit','error');
%                 rows = rows+1;txt{rows,1} = 'Data Uploading ... FAILED';
%                 set(handles.status_txt,'String',txt);
%             end
%             %%%%%%%%%%%%%%%%%
%         else
%             blocks = ceil(length(files)/5);
%             uploadedFileName = '';
%             UploadWait_h = waitbar(0,'Block ','Name','Uploading ...');
%             
%             for curblock = 0:blocks-1
%                 %generate SCP script command file
%                 fid = fopen(fullfile(handles.params.DataConduit.dataDir, 'ftpcmds.txt'), 'w');
%                 fprintf(fid, '%s\n', 'option batch abort');
%                 fprintf(fid, '%s\n', 'option confirm off');
%                 fprintf(fid, '%s\n', 'option reconnecttime 300');
%                 
%                blockfiles = 0;
%                 for curfile = 1:5
%                     if length(files) >= 5*curblock + curfile
%                         blockfiles = blockfiles +1;
%                         fprintf(fid, '%s\n', ['open ftps://',FTPdata.username,':',FTPdata.pwd,'@ftp.NexStepBiomarkers.com -explicittls -certificate="ad:0e:0c:8a:09:5f:53:cc:cb:c4:e7:90:5d:0d:36:93:07:7a:b8:b1" -rawsettings PingType=2 PingIntervalSecs=10']);
%                         fprintf(fid, '%s\n', 'cd /Uploads');
%                         fprintf(fid, '%s\n', 'option transfer binary');
%                         fprintf(fid, '%s\n', ['put "', fullfile(handles.params.DataConduit.dataDir, files( 5*curblock + curfile).name),'" -resume']);
%                     end
%                 end
%                 
%                 uploadedFileName = [uploadedFileName, files(1:blockfiles*curblock + curfile).name];
%                 
%                 fprintf(fid, '%s\n', 'exit');
%                 fclose(fid);
%                 % run winSCP
%                 cmdstr = [ftpsLocation ' /script=', fullfile(handles.params.DataConduit.dataDir), filesep, 'ftpcmds.txt /log="winscp.log"'];
%                 %cmdstr = [ftpsLocation ' /console /script=', fullfile(handles.params.DataConduit.dataDir), filesep, 'ftpcmds.txt'];
%                 rows = rows+1;txt{rows,1} = ['Data Uploading ... Block ',num2str(curblock+1)];
%                 set(handles.status_txt,'String',txt);
%                 
%                 %waitbar(curblock+1/blocks,UploadWait_h,sprintf('%0.1f',curblock+1))
%                 waitbar(curblock+1/blocks,UploadWait_h,['Transfering Block = ',num2str(curblock+1),' of ',num2str(blocks)]);
%                 [out, outStr] = system(cmdstr);% outshould return 0
%                 
%                 %%%%%%%%%%%%%%%%
%                 if ~out
%                     retVal = true;
%                     %Clean up Files
%                     system(['del ',fullfile(handles.params.DataConduit.dataDir, 'ftpcmds.txt')]);
%                     for curfile = 1:length(files)
%                         if length(files) <= 5*curblock + curfile
%                             system(['del ',fullfile(handles.params.DataConduit.dataDir, files(5*curblock + curfile).name)]);
%                         end
%                     end
%                     rows = rows+1;txt{rows,1} = 'Data Uploading ... OK';
%                     set(handles.status_txt,'String',txt);
%                 else
%                     retVal = false;
%                     msgbox({'ERROR: Data NOT Uploaded !', 'Check with NexStepBiomarkers to manually Upload Data',['Error: ',outStr]},'NSB DataConduit','error');
%                     rows = rows+1;txt{rows,1} = 'Data Uploading ... FAILED';
%                     set(handles.status_txt,'String',txt);
%                 end
%                 %%%%%%%%%%%%%%%%%
%                 
%             end
%             delete(UploadWait_h);
%         end





%For sftp.exe        
%         %generate command file
%         fid = fopen(fullfile(handles.params.DataConduit.dataDir, 'ftpcmds.txt'), 'w');
%         fprintf(fid, '%s\n', 'binary');
%         fprintf(fid, '%s\n', 'passive');
%         fprintf(fid, '%s\n', 'cd /Uploads/');
%         for curfile = 1:length(files)
%             fprintf(fid, '%s\n', ['put ', fullfile(handles.params.DataConduit.dataDir, files(curfile).name)]);
%         end
%         uploadedFileName = [files(:).name];
%         fprintf(fid, '%s\n', 'quit');
%         fclose(fid);
%         % run ftps
%         cmdstr = [ftpsLocation ' -e:tls-c -z -user:',FTPdata.username,' -password:',FTPdata.pwd,' -s:',fullfile(handles.params.DataConduit.dataDir, 'ftpcmds.txt'), ' ' ,FTPdata.site];
%     rows = rows+1;txt{rows,1} = 'Data Uploading ... ';
%     set(handles.status_txt,'String',txt);
%         [out, outStr] = system(cmdstr);
%%%%%%%%%%%%%%%%%%

    
%     catch me
%         errordlg({me.identifier, me.message, ['Line = ', num2str(me.stack(1).line)]});
%         disp('Could not Open FTPs connection for upload ...');
%         disp(['Reason: ',me.message]);
%         retVal = false;
%         rows = rows+1;txt{rows,1} = 'Data Uploading ... FAILED';
%         set(handles.status_txt,'String',txt);
%         try
%             delete(UploadWait_h);
%         end
%         return;
%     end
    
    
else %Straight FTP no encryption
    try
        rows = rows+1;txt{rows,1} = 'Secure Data Uploading ... FAILED';
        set(handles.status_txt,'String',txt);
        FtpOBJ = ftp(FTPdata.site,FTPdata.username,FTPdata.pwd);
        binary(FtpOBJ);
        cd(FtpOBJ,'/Uploads');
        dirFiles = dir(fullfile(handles.params.DataConduit.dataDir,'*.sk'));
        files = mput(FtpOBJ,fullfile(handles.params.DataConduit.dataDir,'*.sk'));
        close(FtpOBJ);
        uploadedFileName = [dirFiles(:).name];
        if ~isempty(files)
            retVal = true;
        end
        rows = rows+1;txt{rows,1} = 'Only .sk Data Uploaded ... OK';
        set(handles.status_txt,'String',txt);
        %Scroll Status pannel
        rowchars =  ceil(cellfun(@length,txt)/24); %25-1 characters in window
        if sum(rowchars) >= handles.params.DataConduit.GUIStatusLines
            rows = find(cumsum(flipud(rowchars)) >= handles.params.DataConduit.GUIStatusLines,1,'first');
            txt = txt(length(txt)-rows+1:end);
            set(handles.status_txt,'String',txt);
        end
    catch me
        try
            close(FtpOBJ);
        end
        errordlg({me.identifier, me.message});
        disp('Could not Open FTP connection for download ...');
        disp(['Reason: ',me.message]);
        retVal = false;
        rows = rows+1;txt{rows,1} = 'Data Uploading ... FAILED';
        set(handles.status_txt,'String',txt);
        %Scroll Status pannel
        rowchars =  ceil(cellfun(@length,txt)/24); %25-1 characters in window
        if sum(rowchars) >= handles.params.DataConduit.GUIStatusLines
            rows = find(cumsum(flipud(rowchars)) >= handles.params.DataConduit.GUIStatusLines,1,'first');
            txt = txt(length(txt)-rows+1:end);
            set(handles.status_txt,'String',txt);
        end
        return;
    end
end

%generate mail message
try
    if ~verLessThan('matlab','7.5.0')
        msg{1} = ['Upload Date:', datestr(now)];
        msg{2} = uploadedFileName;
        msg{3} = ['NSB DataConduit: ver. ',handles.params.DataConduit.version];
        msg{4} = ['______________________________________________________'];
        if ispc
            msg{5} = [system_dependent('getos'),' ',system_dependent('getwinsys')];
            disp('User Identification:');
            [trash,myName] = dos('echo %username%');
            [trash,myVol] = dos('vol');
        elseif ismac
            [fail, input] = unix('sw_vers');
            if ~fail
                msg{5} = strrep(input, 'ProductName:', '');
                msg{5} = strrep(msg{4}, sprintf('\t'), '');
                msg{5} = strrep(msg{4}, sprintf('\n'), ' ');
                msg{5} = strrep(msg{4}, 'ProductVersion:', ' Version: ');
                msg{5} = strrep(msg{4}, 'BuildVersion:', 'Build: ');
            else
                msg{5} = system_dependent('getos');
            end
        else
            msg{5} = system_dependent('getos');
        end
        msg{6} = [char(10),'MATLAB Version ',version];
        msg{7} = [char(10),'MATLAB License Number: ',license, char(10)];
        msg{8} = [char(10),'Java VM Version: ',char(strread(version('-java'),'%s',1,'delimiter','\n'))];
        msg{9} = [char(10),'______________________________________________________'];
        if ispc
            msg{10} = [char(10),'Transmitted by:'];
            msg{11} = myName;
        end
        mail = 'NSBMailBouncer@gmail.com';
        password = 'NSBSoftware';
        setpref('Internet','E_mail',mail);
        setpref('Internet','SMTP_Server','smtp.gmail.com');
        setpref('Internet','SMTP_Username',mail);
        setpref('Internet','SMTP_Password',password);
        props = java.lang.System.getProperties;
        props.setProperty('mail.smtp.auth','true');
        props.setProperty('mail.smtp.socketFactory.class', 'javax.net.ssl.SSLSocketFactory');
        props.setProperty('mail.smtp.socketFactory.port','465');
        
        sendmail('david.devilbiss@NexStepBiomarkers.com','NSB DataConduit: New Data',msg);
    end
end
rows = rows+1;txt{rows,1} = 'Emailing Report';
rows = rows+1;txt{rows,1} = '... Finished';
set(handles.status_txt,'String',txt);
%Scroll Status pannel
rowchars =  ceil(cellfun(@length,txt)/24); %25-1 characters in window
if sum(rowchars) >= handles.params.DataConduit.GUIStatusLines
    rows = find(cumsum(flipud(rowchars)) >= handles.params.DataConduit.GUIStatusLines,1,'first');
    txt = txt(length(txt)-rows+1:end);
    set(handles.status_txt,'String',txt);
end

% --------------------------------------------------------------------
function Help_pull_Callback(hObject, eventdata, handles)
% hObject    handle to Help_pull (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
     winopen('C:\NexStepBiomarkers\NexStep Biomarkers DataConduit Software Manual.pdf');
catch
    h = errordlg({'Cannot open DataConduit Software Manual as a pdf.','Please install a PDF reader.','http://get.adobe.com/reader/otherversions/','http://www.foxitsoftware.com/Secure_PDF_Reader/'},'Help');
end

% --------------------------------------------------------------------
function Legal_item_Callback(hObject, eventdata, handles)
% hObject    handle to Legal_item (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

 out = msgbox({'Copyright (c) 2011, David M. Devilbiss, NexStep Biomarkers, LLC.';'All rights reserved.';' ';...
     'This software is provided by the copyright holder (NexStep Biomarkers, LLC.) under a Licence Agreement and provided "AS IS" and any express or implied warranties, including, but not limited to, the implied warranties of merchantability and fitness for a particular purpose are disclaimed.';...
     'In no event shall the copyright owner or contributors be liable for any direct, indirect, incidental, special, exemplary, or consequential damages (including, but not limited to, procurement of substitute goods or services; loss of use, data, or profits; or business interruption) however caused and on any theory of liability, whether in contract, strict liability, or tort (including negligence or otherwise) arising in any way out of the use of this software, even if advised of the possibility of such damage.';...
     ' ';... 
     'fuf code is provided under the folowing license';'Copyright (c) 2002, Francesco di Pierro';'All rights reserved.';...
     'Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:';...
     '* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.';...
     '* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution';...
     'THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.';...
     'IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS';...
     'INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)';...
     'ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.'},'NSB DataConduit');

% --------------------------------------------------------------------
function Help_item_Callback(hObject, eventdata, handles)
% hObject    handle to Help_item (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

 out = msgbox('Cannot find help file','NSB DataConduit');

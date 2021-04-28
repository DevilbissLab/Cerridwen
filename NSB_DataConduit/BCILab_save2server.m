function retVal = BCILab_save2server(handles)
%
%There are generally three types of FTP; 1) ftp (native to win and matlab)
%2) sFTP (tunneling through a SSH) and 3) FTPs (using SSL or TLS)

retVal = false;
FTPdata = BCILab_FTPdata();
if isdeployed
    ftpsLocation = 'C:\BCILab\Program\BCILab_Daq\SSH\ftps.exe';
else
    ftpsLocation = which('ftps.exe');
end

%determine if secure FTP type is avalable
if strcmpi(handles.paramaters.BCILabFTPServerType,'sftp')
    try
        javaaddpath('C:\BCILab\Program\BCILab_Daq\SSH\ganymed-ssh2-build250.jar');
        sftp = true;
    catch
        sftp = false;
    end
elseif strcmpi(handles.paramaters.BCILabFTPServerType,'ftps')
    if exist(ftpsLocation,'file')
        sftp = true;
    else
        sftp = false;
    end
end
if ~sftp
    answer = questdlg('sFTP not avalable! Do you want to continue this non-HIPAA process?', ...
        'sFTP Post Data', 'Yes', 'Abort', 'Abort');
    switch answer
        case 'Yes'
            sftp = false;
        case 'Abort'
            return;
    end
end

%this may be run offline or at some other time
if sftp
    %there should be only one encrypted file but check anyway
    files = dir(fullfile(handles.paramaters.DataDir,'*.sk'));
     if isempty(files)
            errordlg('NO Encrypted files to upload','BCILab_save2server');
            BCI_Log(handles.paramaters.LogFile,'BCiLab_save2server: NO Encrypted files to upload');
            disp('NO Encrypted files to upload ...');
            retVal = false;
            return;
     end
    if strcmpi(handles.paramaters.BCILabFTPServerType,'sftp')
        try
            if isfield(handles,'BCILabData') %just finished collecting data
                sftpfrommatlab(FTPdata.username,FTPdata.site,FTPdata.pwd,...
                    handles.BCILabData.FileName,['/Data/Uploads/',files(curFile).name]);
                uploadedFileName = handles.BCILabData.FileName;
            else %offline mode
                for curFile = 1:length(files)
                    sftpfrommatlab(FTPdata.username,FTPdata.site,FTPdata.pwd,...
                        fullfile(handles.paramaters.DataDir,files(curFile).name),...
                        ['/Data/Uploads/',files(curFile).name]);
                end
                uploadedFileName = [files(:).name];
            end
            retVal = true;
        catch me
            errordlg({me.identifier, me.message});
            BCI_Log(handles.paramaters.LogFile,['BCiLab_save2server: Returned ', me.message]);
            disp('Could not Open sFTP connection for upload ...');
            disp(['Reason: ',me.message]);
            retVal = false;
            return;
        end
    elseif strcmpi(handles.paramaters.BCILabFTPServerType, 'ftps')
        try
            %generate command file
            fid = fopen(fullfile(handles.paramaters.DataDir, 'ftpcmds.txt'), 'w');
            fprintf(fid, '%s\n', 'binary');
            fprintf(fid, '%s\n', 'passive');
            fprintf(fid, '%s\n', 'cd /Data/Uploads/');
            if isfield(handles,'BCILabData') %just finished collecting data
                %fprintf(fid, '%s\n', ['put ',
                %fullfile(handles.paramaters.DataDir,handles.BCILabData.FileName)]);
                %  getting C:\BCILab\Data\C:\BCILab\Data\jh734675.9971cmp.mat
                fprintf(fid, '%s\n', ['put ', fullfile(handles.paramaters.DataDir,handles.BCILabData.FileName)]);
                uploadedFileName = handles.BCILabData.FileName;
            else %offline mode
                for curfile = 1:length(files)
                    fprintf(fid, '%s\n', ['put ', fullfile(handles.paramaters.DataDir, files(curfile).name)]);
                end
                uploadedFileName = [files(:).name];
            end
            fprintf(fid, '%s\n', 'quit');
            fclose(fid);
            % run ftps
            cmdstr = [ftpsLocation ' -e:tls-c -z -user:',FTPdata.username,' -password:',FTPdata.pwd,' -s:',fullfile(handles.paramaters.DataDir, 'ftpcmds.txt'), ' ' ,FTPdata.site];
            [out, outStr] = system(cmdstr);
            BCI_Log(handles.paramaters.LogFile,['BCiLab_save2server sFTP Input: ', cmdstr]);
            BCI_Log(handles.paramaters.LogFile,['BCiLab_save2server sFTP Returned: ', out]);
            BCI_Log(handles.paramaters.LogFile,['BCiLab_save2server sFTP Returned: ', outStr]);
            if ~out
                retVal = true;
                system(['del ',fullfile(handles.paramaters.DataDir, 'ftpcmds.txt')]);
                %Archive current data
                if  exist(fullfile(handles.paramaters.DataDir,'Archive')) ~= 7
                    stat = mkdir(fullfile(handles.paramaters.DataDir,'Archive')); 
                end
                %this is a cheap way to do this but... i am tired
                try
                movefile(fullfile(handles.paramaters.DataDir,'*.sk'),fullfile(handles.paramaters.DataDir,'Archive'));
                end
                try 
                movefile(fullfile(handles.paramaters.DataDir,'*.mat'),fullfile(handles.paramaters.DataDir,'Archive'));
                end
                try
                movefile(fullfile(handles.paramaters.DataDir,'*.txt'),fullfile(handles.paramaters.DataDir,'Archive'));
                end
            else
                retVal = false;
                msgbox({'ERROR: Data NOT Uploaded !', 'Check with BCI to manually Upload Data',['Error: ',outStr]},'BCILab_save2server','error');
            end
        catch me
            errordlg({me.identifier, me.message});
            BCI_Log(handles.paramaters.LogFile,['BCiLab_save2server: Returned ', me.message]);
            disp('Could not Open FTPs connection for upload ...');
            disp(['Reason: ',me.message]);
            retVal = false;
            return;
        end
    end
else %Straight FTP no encryption
    try
        FtpOBJ = ftp(FTPdata.site,FTPdata.username,FTPdata.pwd);
        binary(FtpOBJ);
        cd(FtpOBJ,'/Data/Uploads');
        if isfield(handles,'BCILabData') %just finished collecting data
            files = mput(FtpOBJ,handles.BCILabData.FileName);
            uploadedFileName = handles.BCILabData.FileName;
        else
            dirFiles = dir(fullfile(handles.paramaters.DataDir,'*.sk'));
            files = mput(FtpOBJ,fullfile(handles.paramaters.DataDir,'*.sk'));
            uploadedFileName = [dirFiles(:).name];
        end
        if ~isempty(files)
            retVal = true;
        end
        
    catch me
        errordlg({me.identifier, me.message});
        BCI_Log(handles.paramaters.LogFile,['BCiLab_save2server FTP: Returned ', me.message]);
        disp('Could not Open FTP connection for download ...');
        disp(['Reason: ',me.message]);
        retVal = false;
        return;
    end
    close(FtpOBJ);
end



% >> uploadedFileName
%generate mail message
if ~verLessThan('matlab','7.5.0')
    msg{1} = ['Upload Date:', datestr(now)];
    msg{2} = uploadedFileName;
    msg{3} = ['BCILab_Daq_Version: ',handles.paramaters.BCILab_Daq_Name,' ver. ',handles.paramaters.BCILab_Daq_Version];
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
        msg{10} = [char(10),'Recorded by:'];
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
    
    sendmail('david.devilbiss@NexStepBiomarkers.com','BCILab_Uploader: New Data',msg);
end

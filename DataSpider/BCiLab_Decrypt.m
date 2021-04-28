function retVal = BCiLab_Decrypt(in_FileName, out_Path, ScrubFlag, ShredFlag)
%BCiLab_Decrypt(in_FileName, out_Path, ScrubFlag, ShredFlag)

retVal = false;
FTPdata = BCILab_FTPdata();

if nargin == 0
    [in_FileName,pathname] = uigetfile('*.sk','Select the silverkey code file');
    in_FileName = fullfile(pathname,in_FileName);
    if isnumeric(pathname)
        return;
    end
end
if nargin < 2
    out_Path = uigetdir('','Select path to save decrypted files');
    if isnumeric(out_Path)
        return;
    end
end
if nargin < 3
    ScrubFlag = true;
end
if nargin < 4
    ShredFlag = true;
end
%Get cur file list. We'll be diff it later
oldDIRStruct = dir(out_Path);

try
    SkExists = false;
    if exist('C:\Program Files (x86)\Kryptel','dir') == 7
        SkCmd = 'C:\Program Files (x86)\Kryptel\SkCmd.exe';
        ShredCmd = 'C:\Program Files (x86)\Kryptel\shred.exe';
        SkExists = true;
    elseif exist('C:\Program Files\Kryptel','dir') == 7
        SkCmd = 'C:\Program Files\Kryptel\SkCmd.exe';
        ShredCmd = 'C:\Program Files\Kryptel\shred.exe';
        SkExists = true;
    end
    if SkExists
        cmdStr = ['"',SkCmd,'" /D "',in_FileName,...
            '" /P ',FTPdata.Silverkey, ' /T "' out_Path '"'];
        [out, outStr] = system(cmdStr); %system always reports something !
        if out ~= 0
            srtIDX = strfind(outStr,'>>');  % deal with a security issue regarding possible printing of passcode
            if ~isempty(srtIDX)
                msgbox({'ERROR: Data NOT Decrypted !','Check SilverKey installation and manually decrypt',['Error: ',outStr(srtIDX(end):end)]},'BCiLab_Decrypt','error');
            else
                 msgbox({'ERROR: Data NOT Decrypted !','Check SilverKey installation and manually decrypt',['Error: ',outStr]},'BCiLab_Decrypt','error');   
            end
            end
        
        newDIRStruct = dir(out_Path);
        %loop through files and Delete or Scrub
        oldFileList = {oldDIRStruct(:).name};
        newFileList = {newDIRStruct(:).name};
        diffFileList = setxor(oldFileList,newFileList);
        
        for curfile = 1:length(diffFileList)
            if strcmpi(diffFileList{curfile},'.') || strcmpi(diffFileList{curfile},'..') || isdir(fullfile(out_Path,diffFileList{curfile}))
                continue;
            elseif strfind(diffFileList{curfile},'cmp.mat')
                load(fullfile(out_Path,diffFileList{curfile}));
                if ScrubFlag
                    %Only keep needed non-id data
                    cleanBCILabData.Epoch = BCILabData.Epoch;
                    cleanBCILabData.BCILabDaqVersion = BCILabData.BCILabDaqVersion;
                    cleanBCILabData.sernum = BCILabData.sernum;
                    cleanBCILabData.subject = BCILabData.subject;
                    cleanBCILabData.sRate = BCILabData.sRate;
                    cleanBCILabData.FileName = BCILabData.FileName;
                    cleanBCILabData.tech = BCILabData.tech;
                    %Cerora HIPPA Specs
                    cleanBCILabData.subjectInitials = BCILabData.subjectInitials;
                    cleanBCILabData.birthdate = BCILabData.birthdate;
                    cleanBCILabData.address = BCILabData.address;
                    cleanBCILabData.handedness = BCILabData.handedness;
                    cleanBCILabData.gender = BCILabData.gender;
                    BCILabData = cleanBCILabData;
                end
                save(fullfile(out_Path,diffFileList{curfile}),'BCILabData');
                retVal = true;
            elseif ShredFlag
                %shred partial files
                cmdStr = ['"',ShredCmd,'" /S 3 /I "',fullfile(out_Path,diffFileList{curfile}),'"'];
                [out, outStr] = system(cmdStr); %system always reports something !
                if out ~= 0
                    srtIDX = strfind(outStr,'>>');  % deal with a security issue regarding possible printing of passcode
                    if ~isempty(srtIDX)
                    msgbox({'ERROR: Data NOT Shredded !','Inform BCI Immediately',['Error: ',outStr(srtIDX(end):end)]},'BCiLab_Decrypt','error');
                    else
                    msgbox({'ERROR: Data NOT Shredded !','Inform BCI Immediately',['Error: ',outStr]},'BCiLab_Decrypt','error');    
                    end
                end
            else
                %Special case, deal with damaged files....
                [fnPath,fn,fnExt] = fileparts(fullfile(out_Path,diffFileList{curfile}));
                if strcmpi(fnExt,'.mat')
                load(fullfile(out_Path,diffFileList{curfile}));
                if ~isfield(BCILabData,'Epoch');
                    BCILabData.Epoch = [];
                end
                if ~isfield(BCILabData,'BCILabDaqVersion');
                    BCILabData.BCILabDaqVersion = NaN;
                end
                if ~isfield(BCILabData,'sernum');
                    BCILabData.sernum = NaN;
                end
                if ~isfield(BCILabData,'subject');
                    BCILabData.subject = datestr(str2double(regexp(fn, '[\d\.]+', 'match')));
                end
                if ~isfield(BCILabData,'sRate');
                    BCILabData.sRate = 128;
                end
                if ~isfield(BCILabData,'FileName');
                    BCILabData.FileName = fullfile(out_Path,diffFileList{curfile});
                end
                if ~isfield(BCILabData,'tech');
                    BCILabData.tech = regexp(fn, '[a-zA-Z]+', 'match');
                    BCILabData.tech = BCILabData.tech{1};
                end
                if ~isfield(BCILabData,'subjectInitials');
                    BCILabData.subjectInitials = '';
                end
                if ~isfield(BCILabData,'birthdate');
                    BCILabData.birthdate = [];
                end
                if ~isfield(BCILabData,'address');
                    BCILabData.address = '';
                end
                if ~isfield(BCILabData,'handedness');
                    BCILabData.handedness = '';
                end
                if ~isfield(BCILabData,'gender');
                    BCILabData.gender = '';
                end
                save(fullfile(out_Path,diffFileList{curfile}),'BCILabData');
                retVal = true;
                end
                
            end
        end
    else
        msgbox({'ERROR: No Valid Decrypter !','Check SilverKey installation and manually decrypt'},'BCiLab_Decrypt','error');
    end
catch me
    errordlg({me.identifier, me.message});
end
if retVal
    disp('Finished Decryption Successfully');
else
    disp(['Decryption Failed for: ',in_FileName]);
end
function status = NSB_SoftwareUpdate()
% NSB_SoftwareUpdate() - Software Updater all NSB software
%
% Inputs: none
%
% Outputs:
%   status               - (Logic) return status
%
%
% Written By David M. Devilbiss
% NexStep Biomarkers, LLC. (info@nexstepbiomarkers.com)
% December 1 2011, Version 1.0
% May 10 2017, Version 1.1 - Updated URls and added compatavility with
% figure conventions post v2014

%update packages are ZIP files
% Base system should be in C:\NexStepBiomarkers\EEGFramework\ but may be
% moved All files in one Dir

status = false;
% Get current version of matlab
curMatVersion = regexp(version,'\s','split'); curMatVersion = cellfun(@str2num,regexp(curMatVersion{1},'\.','split') );
if any(curMatVersion >= [8,4,0,150421])
    MatlabPost2014 = true;
else
    MatlabPost2014 = false;
end
LogFile = fullfile(cd,['NSB_SoftwareUpdate_log',num2str(now),'.log']);

infostr = ['NexStep Biomarkers Software Update in progress ...', datestr(now)];
NSBlog(LogFile,infostr);

h1 = msgbox('NexStep Biomarkers Software Update in progress ...','NSB_SoftwareUpdate','help');
try
    childs = get(h1,'Children');
    if MatlabPost2014
        h1_text =  get(childs(3),'Children');
    else
        h1_text = get(childs(2),'Children');
    end
catch ME
    infostr = ['ERROR:NSB_SoftwareUpdate >> ',ME.message, ' in ',ME.stack(1).name,' line: ',num2str(ME.stack(1).line)];
    NSBlog(LogFile,infostr);
end

%Get Deploymenmt status
if (ismcc || isdeployed)
    if exist([matlabroot, '\runtime\win64'])
        is64 = true;
        %params.SoftwareUpdateSite = 'http://dl.dropbox.com/u/20155832/NSB_PreclinicalEEGFramework_64bit.zip';
        params.SoftwareUpdateSite = 'http://nexstepbiomarkers.com/FTP/Software/NSB_PreclinicalEEGFramework_64bit.zip';
    else
        is64 = false;
        params.SoftwareUpdateSite = 'http://nexstepbiomarkers.com/FTP/Software/NSB_PreclinicalEEGFramework_32bit.zip';
        %params.SoftwareUpdateSite = 'http://dl.dropbox.com/u/20155832/NSB_PreclinicalEEGFramework_32bit.zip';
    end
else
    try, close(h1); end
    msgbox({'ERROR: NexStep Biomarkers Software Update cannot be run as an ".m" file.','Use FTP site to update'},'NSB_SoftwareUpdate','error');
    infostr = ['Error:NSB_SoftwareUpdate >> NexStep Biomarkers Software Update cannot be run as an ".m" file.'];
    NSBlog(LogFile,infostr);
    return;
end

%DownLoad and write to local location
currentLocation = cd; %where the updater .exe resides
%pull down a zip package and unzip
try
    set(h1_text,'String',{'NexStep Biomarkers Software Update in progress ...','Downloading Update ...'});
    try
        infostr = ['Information:NSB_SoftwareUpdate >> unzipping update from: ', params.SoftwareUpdateSite];
        NSBlog(LogFile,infostr);
        uFiles = unzip(params.SoftwareUpdateSite, currentLocation);
        
        for curFile = 1:length(uFiles)
        infostr = ['Information:NSB_SoftwareUpdate >> Downloaded: ', uFiles{curFile}];
        NSBlog(LogFile,infostr);
        end
        
        set(h1_text,'String',{'Downloading Update ...','NexStep Biomarkers Software Updated Succesfully'});
        infostr = ['Information:NSB_SoftwareUpdate >> Software Updated Succesfully to: ', currentLocation];
        NSBlog(LogFile,infostr);
        status = true;
        infostr = ['NexStep Biomarkers Software Sucessfully Updated.'];
        NSBlog(LogFile,infostr);
    catch ME
        errorstr = ['ERROR:NSB_SoftwareUpdate >> >> ',ME.message];
        if ~isempty(ME.stack)
            errorstr = [errorstr,' Function: ',ME.stack(1).name,' Line # ',num2str(ME.stack(1).line)];
        end
        if ~isempty(options.logfile)
            NSBlog(options.logfile,errorstr);
        else
            disp(errorstr);
        end
        Cntdwn = 5;
        h = waitbar(0,{'Could not get exclusive access to Cerridwen.exe',['Trying again in ',num2str(Cntdwn),' Seconds']});
        for cnt = 1:Cntdwn
            pause(1);
            waitbar(cnt/Cntdwn,h,{'Could not get exclusive access to Cerridwen.exe',['Trying again in ',num2str(Cntdwn-cnt),' Seconds']})
        end
        close(h);
        try
            uFiles = unzip(params.SoftwareUpdateSite, currentLocation);
            
            for curFile = 1:length(uFiles)
                infostr = ['Information:NSB_SoftwareUpdate >> Downloaded: ', uFiles{curFile}];
                NSBlog(LogFile,infostr);
            end
            
            set(h1_text,'String',{'Downloading Update ...','NexStep Biomarkers Software Updated Succesfully'});
            status = true;
            infostr = ['NexStep Biomarkers Software Sucessfully Updated.'];
            NSBlog(LogFile,infostr);
        catch
            msgbox({'ERROR: NexStep Biomarkers Software NOT Updated: Could not get exclusive access to Cerridwen.exe'},'NSB_SoftwareUpdate','error');
            infostr = ['Error:NSB_SoftwareUpdate >> NexStep Biomarkers Software NOT Updated: Could not get exclusive access to Cerridwen.exe'];
            NSBlog(LogFile,infostr);
        end
    end
catch ME
    msgbox({'ERROR: NexStep Biomarkers Software NOT Updated:',ME.identifier, ME.message},'NSB_SoftwareUpdate','error');
    infostr = ['Error:NSB_SoftwareUpdate >> ',ME.message, ' in ',ME.stack(1).name,' line: ',num2str(ME.stack(1).line)];
    NSBlog(LogFile,infostr);
    status = false;
end

figDim = get(h1,'Position');
figDim(3) = 300;
set(h1,'Position',figDim);
set(h1_text,'String',{'Check C:\NexStepBiomarkers\EEGFramework for updated software.','NSB_SoftwareUpdate may need to be "Run As Administrator".'});
try
    figDim = get(childs(1),'Position');
    figDim(1) = 125;
    set(childs(1),'Position',figDim);
end

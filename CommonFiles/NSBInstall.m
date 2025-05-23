function status = NSBInstall(fcn)
%Set path to use NSB_AnalyticFramework
%
%Use status = NSBInstall(fcn);
%Input:     fcn - (string) 'add' or 'remove'
%Output:    status - logical
%
% updated to correctly select XML_toolbox
%

status = false;
curMatVersion = regexp(version,'\s','split'); curMatVersion = cellfun(@str2num,regexp(curMatVersion{1},'\.','split') );
if any(curMatVersion >= [8,4,0,150421])
    MatlabPost2014 = true;
else
    MatlabPost2014 = false;
end
if nargin == 0
    fcn = 'add';
end

disp(['The current version of Matlab is: ',version]);
disp(['MatlabPost2014 flag = ',num2str(MatlabPost2014)]);

if strcmpi(fcn,'add')
    if ~exist('./Cerridwen.m') == 2
        %this file is NOT in the Cerridwen\PreClinicalEEGFramework folder
        error('NSBInstall: NSBInstall is NOT in the Cerridwen\PreClinicalEEGFramework folder. Terminating install');
        return;
    end

    if ispc
        %I want to use GenPath, but there are a lot of .git and .svn
        %folders that need to be ignored.

        addpath '..\PreClinicalEEGFramework';
        addpath '..\CommonFiles';
        if MatlabPost2014
            addpath '..\ExternalToolBoxes\tinyXML2';
        else
            addpath '..\ExternalToolBoxes\xml_toolbox';
        end
        addpath '..\ExternalToolBoxes\son';
        addpath '..\ExternalToolBoxes\son\SON32';
        addpath '..\ExternalToolBoxes\fuf';
        addpath '..\ExternalToolBoxes\struct2xml';
        addpath '..\ExternalToolBoxes\Word';
        addpath '..\ExternalToolBoxes\ACQreader';
        addpath '..\ExternalToolBoxes\NPMK';
        addpath '..\ExternalToolBoxes\infodynamics\';
        addpath '..\ExternalToolBoxes\infodynamics\utils';
        javaaddpath('../ExternalToolBoxes/infodynamics/infodynamics.jar');
        addpath '..\Importers';
        addpath '..\Exporters';
        addpath '..\SleepScoringToolbox';
        addpath '..\DataSpider';
        

    elseif ismac
        addpath '/Volumes/homes/DevilbissLab/SourceCode/Cerridwen/PreClinicalEEGFramework';
        addpath '/Volumes/homes/DevilbissLab/SourceCode/Cerridwen/CommonFiles';
        if MatlabPost2014
            addpath '/Volumes/homes/DevilbissLab/SourceCode/Cerridwen/ExternalToolBoxes/tinyXML2';
        else
            addpath '/Volumes/homes/DevilbissLab/SourceCode/Cerridwen/ExternalToolBoxes/xml_toolbox';
        end
        addpath '/Volumes/homes/DevilbissLab/SourceCode/Cerridwen/ExternalToolBoxes/son';
        addpath '/Volumes/homes/DevilbissLab/SourceCode/Cerridwen/ExternalToolBoxes/son/SON32';
        addpath '/Volumes/homes/DevilbissLab/SourceCode/Cerridwen/ExternalToolBoxes/fuf';
        addpath '/Volumes/homes/DevilbissLab/SourceCode/Cerridwen/ExternalToolBoxes/struct2xml';
        addpath '/Volumes/homes/DevilbissLab/SourceCode/Cerridwen/ExternalToolBoxes/Word';
        addpath '/Volumes/homes/DevilbissLab/SourceCode/Cerridwen/ExternalToolBoxes/ACQreader';
        addpath '/Volumes/homes/DevilbissLab/SourceCode/Cerridwen/ExternalToolBoxes/NPMK';
        addpath '/Volumes/homes/DevilbissLab/SourceCode/Cerridwen/ExternalToolBoxes/infodynamics';
        addpath '/Volumes/homes/DevilbissLab/SourceCode/Cerridwen/ExternalToolBoxes/infodynamics/utils';
        javaaddpath('/Volumes/homes/DevilbissLab/SourceCode/Cerridwen/ExternalToolBoxes/infodynamics/infodynamics.jar');
        addpath '/Volumes/homes/DevilbissLab/SourceCode/Cerridwen/Importers';
        addpath '/Volumes/homes/DevilbissLab/SourceCode/Cerridwen/Exporters';
        addpath '/Volumes/homes/DevilbissLab/SourceCode/Cerridwen/SleepScoringToolbox';
        addpath '/Volumes/Volume_1/UserData/NexStepBiomarkers/DataSpider';
    elseif isunix
        addpath '/home/ddevilbiss/Diskstation/NSB_AnalyticFramework/PreClinicalEEGFramework';
        addpath '/home/ddevilbiss/Diskstation/NSB_AnalyticFramework/CommonFiles';
        if MatlabPost2014
            addpath '/home/ddevilbiss/Diskstation/NSB_AnalyticFramework/ExternalToolBoxes/tinyXML2';
        else
            addpath '/home/ddevilbiss/Diskstation/NSB_AnalyticFramework/ExternalToolBoxes/xml_toolbox';
        end
        addpath '/home/ddevilbiss/Diskstation/NSB_AnalyticFramework/ExternalToolBoxes/son';
        addpath '/home/ddevilbiss/Diskstation/NSB_AnalyticFramework/ExternalToolBoxes/son/SON32';
        addpath '/home/ddevilbiss/Diskstation/NSB_AnalyticFramework/ExternalToolBoxes/fuf';
        addpath '/home/ddevilbiss/Diskstation/NSB_AnalyticFramework/ExternalToolBoxes/struct2xml';
        addpath '/home/ddevilbiss/Diskstation/NSB_AnalyticFramework/ExternalToolBoxes/Word';
        addpath '/home/ddevilbiss/Diskstation/NSB_AnalyticFramework/ExternalToolBoxes/ACQreader';
        addpath '/home/ddevilbiss/Diskstation/NSB_AnalyticFramework/ExternalToolBoxes/NPMK';
        addpath '/home/ddevilbiss/Diskstation/NSB_AnalyticFramework/ExternalToolBoxes/infodynamics';
        addpath '/home/ddevilbiss/Diskstation/NSB_AnalyticFramework/ExternalToolBoxes/infodynamics/utils';
        javaaddpath('/home/ddevilbiss/Diskstation/NSB_AnalyticFramework/ExternalToolBoxes/infodynamics/infodynamics.jar');
        addpath '/home/ddevilbiss/Diskstation/NSB_AnalyticFramework/Importers';
        addpath '/home/ddevilbiss/Diskstation/NSB_AnalyticFramework/Exporters';
        addpath '/home/ddevilbiss/Diskstation/NSB_AnalyticFramework/SleepScoringToolbox';
        addpath '/home/ddevilbiss/Diskstation/DataSpider';
    end
    status = true;

    message = sprintf('Next Steps. \n Please change your working directory outside of Cerridwen codebase. \n i.e. CD D:\\temp');
    warndlg(message,'Directory warning');

elseif strcmpi(fcn,'remove')
    fPath = fileparts(which('Cerridwen.m'));
    fPath_idx = strfind(fPath,filesep);
    fPath = fPath(1:fPath_idx(end));
    rmpath(genpath(fPath));
    status = true;
else
    disp('unknown command');
end
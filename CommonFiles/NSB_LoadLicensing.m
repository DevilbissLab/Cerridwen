function LicenseStruct = NSB_LoadLicensing(LogFile)
%NSB_LoadLicensing() - Load Licensing file and decrypt options
%Licence File must be in the same directory as the PreclinicalEEGFramework

if nargin < 1
    LogFile = '';
end

LicenseStruct = struct();
try
LicKey = load('NSB_LicenseFile.lic', '-mat');%load new licnece file;
catch
    [fn, path] = uigetfile({'*.lic','NSB License (*.lic)';'*.*',  'All Files (*.*)'},'Manually find the NSB license file');
    if ischar(fn)
        LicKey = load(fullfile(path,fn), '-mat');%load new licnece file;
    else
        return;
    end
end

LicenseStruct.Info.Company = LicKey.Company;
LicenseStruct.Info.Group = LicKey.Group;
LicenseStruct.Info.User = LicKey.FTPdata.username;
%LicenseStruct.FTPdata = LicKey.FTPdata; This is a valid file but do not include for now (DMD).

NSBlog(LogFile,['Info:NSB_LoadLicensing >> License Found for ',LicenseStruct.Info.Company,...
     ' Group=',LicenseStruct.Info.Group,' User=',LicenseStruct.Info.User]);

 %Get Curent NIC
if ispc
    [retVal, text] = system('ipconfig /all'); %<< licenceing
    PA_lines = strfind(text,'Physical Address');
    for curNIC = 1:length(PA_lines)
        NIC_Tokens(curNIC) = regexp(text(PA_lines(curNIC):PA_lines(curNIC)+128),'[0-9A-F]{2}+-[0-9A-F]{2}+-[0-9A-F]{2}+-[0-9A-F]{2}+-[0-9A-F]{2}+-[0-9A-F]{2}', 'match');
    end
    
elseif ismac
    [retVal, text] = system('netstat -I en0');
    PA_lines = strfind(text,'>');
    for curNIC = 1:length(PA_lines)
        NIC_Tokens(curNIC) = regexp(text(PA_lines(curNIC):PA_lines(curNIC)+128),'[0-9A-Fa-f]{2}+:[0-9A-Fa-f]{2}+:[0-9A-Fa-f]{2}+:[0-9A-Fa-f]{2}+:[0-9A-Fa-f]{2}+:[0-9A-Fa-f]{2}', 'match');
    end
end

% %Check for NIC and generate Primary Key
% if isempty(NIC_Tokens)
%     if ~isempty(LogFile)
%         NSBlog(LogFile,'Warning : NSB_LoadLicensing >> No Valid NIC Found');
%     end
%     return;
% end
% FirstNIC = NIC_Tokens{1};
% PrimeKey = regexprep(num2str(uint8(FirstNIC)),'\s','');
% 
% %Generate PassCode for Framework
% pwd = [];
% pwdNums = [];
% for n = 1:2:length(PrimeKey)-1
%     pwdNums = [pwdNums, (str2double(PrimeKey(n:n+1))) + str2double(PrimeKey(n+1))];
%     pwd = [pwd char((str2double(PrimeKey(n:n+1))) + str2double(PrimeKey(n+1)))];
% end

%Overall Framework license
%Huristicly find licences NIC
LicenseStruct.Framework = false;
for nNIC = 1:length(NIC_Tokens)
try
    [ValidNIC, PrimeKey, pwdNums] = getKeys(nNIC,NIC_Tokens);
    NSBlog(LogFile, ['Info:NSB_LoadLicensing >> Trying NIC# ',num2str(nNIC),' = ',ValidNIC]);
    if isempty(ValidNIC)
        if ~isempty(LogFile)
            NSBlog(LogFile,'Warning : NSB_LoadLicensing >> No Valid NIC Found');
        end
    end
    
    if all(bitxor(pwdNums,double(ValidNIC)) == LicKey.Framework)
        LicenseStruct.Framework = true;
        NSBlog(LogFile,'Info:NSB_LoadLicensing >> Framework License Valid.');
        break;
    else
        NSBlog(LogFile,'ERROR:NSB_LoadLicensing >> Software is not licensed for this NIC');
        LicenseStruct.Framework = false;
    end
catch
    LicenseStruct.Framework = false;
end
end

% try
% if all(bitxor(pwdNums,double(ValidNIC)) == LicKey.Framework)
%     LicenseStruct.Framework = true;
%     NSBlog(LogFile,'Info:NSB_LoadLicensing >> Framework License Valid.');
% else
%     NSBlog(LogFile,'ERROR:NSB_LoadLicensing >> Software is not licensed for this NIC');
%     NSBlog(LogFile, ['First Machine NIC = ',ValidNIC]);
%     for curNIC = 1:length(PA_lines)
%         curNIC_Token = regexp(text(PA_lines(curNIC):PA_lines(curNIC)+128),'[0-9A-F]{2}+-[0-9A-F]{2}+-[0-9A-F]{2}+-[0-9A-F]{2}+-[0-9A-F]{2}+-[0-9A-F]{2}', 'match');
%         NSBlog(LogFile, ['NIC ',num2str(curNIC),' = ',curNIC_Token{:}]);
%     end
%     LicenseStruct.Framework = false;
% end
% catch
%     LicenseStruct.Framework = false;
% end

if isfield(LicKey,'Expiration')
    if isempty(LicKey.Expiration)
        LicenseStruct.Expiration = [];
        NSBlog(LogFile,'Info:NSB_LoadLicensing >> Eternal Framework License Valid.');
    elseif now <= LicKey.Expiration
        LicenseStruct.Expiration = LicKey.Expiration;
        NSBlog(LogFile,'Info:NSB_LoadLicensing >> Trial Framework License Valid.');
    else
        LicenseStruct.Expiration = LicKey.Expiration;
        NSBlog(LogFile,'ERROR:NSB_LoadLicensing >> Trial Framework License EXPIRED.');
        LicenseStruct.Framework = false;
%         LicenseStruct.DSIImporter = false; 
%         LicenseStruct.EDFWriter = false;
%         LicenseStruct.ssModule = false;
%         LicenseStruct.FIFFImporter = false;
%         LicenseStruct.StatTableOutput = false;
        return;
    end
else
    LicenseStruct.Expiration = [];
end
    

%DSI file import licence
try
if PrimeKey == LicKey.DSIImporter
    LicenseStruct.DSIImporter = true;
    NSBlog(LogFile,'Info:NSB_LoadLicensing >> DSI Import Module License Valid.');
else
    LicenseStruct.DSIImporter = false;
end
catch
    LicenseStruct.DSIImporter = false;    
end
    
%EDF Writer
try
if bitxor(pwdNums,double(ValidNIC)*2) == LicKey.EDFWriter
    LicenseStruct.EDFWriter = true;
    NSBlog(LogFile,'Info:NSB_LoadLicensing >> EDF Writer Module License Valid.');
else
    LicenseStruct.EDFWriter = false;
end
catch
    LicenseStruct.EDFWriter = false;
end
    
%SleepScoring Module
try
if bitxor(pwdNums,double(ValidNIC)*3) == LicKey.SleepScore
    LicenseStruct.ssModule = true;
    NSBlog(LogFile,'Info:NSB_LoadLicensing >> Sleep Scoring Module License Valid.');
else
    LicenseStruct.ssModule = false;
end
catch
    LicenseStruct.ssModule = false;
end

%FIF File import licence
try
if bitxor(pwdNums,double(ValidNIC)*4) == LicKey.FIFFImporter
    LicenseStruct.FIFFImporter = true;
    NSBlog(LogFile,'Info:NSB_LoadLicensing >> FIFF Import Module License Valid.');
else
    LicenseStruct.FIFFImporter = false;
end
catch
   LicenseStruct.FIFFImporter = false; 
end

%Statistical Table File Output licence
try
if bitxor(pwdNums,double(ValidNIC)*5) == LicKey.StatTableOutput
    LicenseStruct.StatTableOutput = true;
    NSBlog(LogFile,'Info:NSB_LoadLicensing >> Groupwise Table Output Module License Valid.');
else
    LicenseStruct.StatTableOutput = false;
end
catch
    LicenseStruct.StatTableOutput = false;
end


function [ValidNIC, PrimeKey, pwdNums] = getKeys(nNIC,NIC_Tokens)
ValidNIC = []; PrimeKey = []; pwdNums = [];

%Check for NIC and generate Primary Key
if isempty(NIC_Tokens)
    return;
end
ValidNIC = upper(NIC_Tokens{nNIC});
PrimeKey = regexprep(num2str(uint8(ValidNIC)),'\s','');

%Generate PassCode for Framework
pwd = [];
pwdNums = [];
for n = 1:2:length(PrimeKey)-1
    pwdNums = [pwdNums, (str2double(PrimeKey(n:n+1))) + str2double(PrimeKey(n+1))];
    pwd = [pwd char((str2double(PrimeKey(n:n+1))) + str2double(PrimeKey(n+1)))];
end

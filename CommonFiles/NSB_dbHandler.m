function [status, NSB_AnalysisDBout] = NSB_dbHandler(dbFileName, Action, dbEntryFileName, DataTankPath)
%
% NSB_dbHandler() - Manage .XML database files. 
%
% Inputs:
%   dbFileName          - (string) FileName of Existing XML Database
%   Action              - (string) LOAD, SAVE, CREATE, ADD
%   dbEntryFileName     - (string) FileName of new entry to be parsed and added
%
% Outputs:
%   status          - (logical) Returned status of function
%   NSB_AnalysisDB  - (struct) Database (opt)
%	
% Called by: 
%
% See also:
%
% Requires: XML Toolbox
%           by Marc Molinari
%           17 Dec 2003 (Updated 20 Apr 2005) 
% Located at: 
% http://www.mathworks.com/matlabcentral/fileexchange/4278-xml-toolbox?controller=file_infos&download=true
%
% Written By David M. Devilbiss
% NexStep Biomarkers, LLC. (info@nexstepbiomarkers.com)
% November 16 2011, Version 1.0

%db Contents
% Data.Owner.Company = 'BCi'
% Data.Owner.Program = 'Tahoe'
% Data.Path = ''
% Data.Filename = ''
% Data.Species = ''
% Data.Group = ''
% Data.Date = ''
% Data.Manipulation = ''
% Data.Dose = ''
% Data.UID = ''
%
%NSB_AnalysisDB always is resident and may become a memory hog!

status = false;
persistent NSB_AnalysisDB; %initializes as [];
if isempty(NSB_AnalysisDB) && exist(dbFileName,'file') == 2
    %autoload 
    NSB_AnalysisDB = xml_load(dbFileName);
end

if strcmp(upper(Action),'CREATE') && nargin < 4
    error 'NSB_dbHandler requires 4 inputs to CREATE'
    return;
elseif strcmp(upper(Action),'ADD') && nargin < 4
    error 'NSB_dbHandler requires 4 inputs to add'
    return;
end

try
switch upper(Action)
    case 'LOAD'
        NSB_AnalysisDB = xml_load(dbFileName);
        NSB_AnalysisDBout = NSB_AnalysisDB;
    case 'SAVE'
        xml_save(dbFileName, NSB_AnalysisDB);
    case 'CREATE'
        %build a new struct off selected data dir
        if isempty(NSB_AnalysisDB)
            NSB_AnalysisDB = cell(0);
            NSB_AnalysisDB{1} = dbInfoParse(dbEntryFileName,DataTankPath);
        else
            disp(['WARNING: NSB_dbHandler.dbInfoParse - Cannot parse db data for ',dbEntryFileName]);
        end
        NSB_AnalysisDBout = NSB_AnalysisDB;
    case 'ADD'
        if ~isempty(NSB_AnalysisDB)
            dbEntry = dbInfoParse(dbEntryFileName,DataTankPath);
            NSB_AnalysisDB{length(NSB_AnalysisDB)+1} = dbEntry;
        else
            %this then will just create an entry
            NSB_AnalysisDB = cell(0);
            NSB_AnalysisDB{1} = dbInfoParse(dbEntryFileName,DataTankPath);
        end
        NSB_AnalysisDBout = NSB_AnalysisDB;
    case 'GET'
        NSB_AnalysisDBout = NSB_AnalysisDB;
end
status = true;
catch ME
    disp('>>ERROR: NSB_dbHandler - ');
    disp(ME.identifier);
    disp(ME.message);
end

function dbEntry = dbInfoParse(dbEntryFileName,DataTankPath)
dbEntry = [];
[Path, Name, Ext] = fileparts(dbEntryFileName);
switch Ext
       case '.mat'
           matVarNames = whos('-file',dbEntryFileName);
           if ~isempty(strfind(matVarNames.name,'BCILabData'))
                %BCiLabData FileType
                dbEntry = parseBCiLabData(dbEntryFileName,DataTankPath);
           end
        case '.csv'
        case '.edf'
            
            
    otherwise
        disp(['WARNING: NSB_dbHandler.dbInfoParse - Cannot parse db data for ',dbEntryFileName]);
end

function dbEntry = parseBCiLabData(FileName,DataTankPath)
dbEntry = [];
[Path, Filename, Ext] = fileparts(FileName); %<< path is wrong since it is moved to ../DataTank
dbEntry.Path = DataTankPath;
dbEntry.Filename = [Filename,Ext];
load(FileName); %%<<<
dbEntry.Company = 'Cerora';
dbEntry.Program = BCILabData.tech;
dbEntry.Species = 'Human';
dbEntry.Group = BCILabData.address;
try
dbEntry.Date = BCILabData.Epoch{1}.date;
catch
dbEntry.Date = '';   
end
dbEntry.Dose = '';
dbEntry.UID = BCILabData.subject;
dbEntry.ChannelNames = 'FP1';
dbEntry.ValidChannel = true;
dbEntry.InvertChannel = false;
dbEntry.Analyzed = false;

dbEntry = orderfields(dbEntry);

function dbEntry = parseMerckCSVData(FileName)
dbEntry = [];
[dbEntry.Path, Filename, Ext] = fileparts(FileName);
dbEntry.Filename = [Filename,Ext];
load(FileName);
dbEntry.Company = 'Merck';
dbEntry.Program = BCILabData.tech;
dbEntry.Species = 'Human';
dbEntry.Group = '';
dbEntry.Date = '';
dbEntry.Dose = '';
dbEntry.UID = '';
dbEntry.ChannelNames = 'FP1';
dbEntry.ValidChannel = true;
dbEntry.InvertChannel = false;

dbEntry = orderfields(dbEntry);
                
                
                
                
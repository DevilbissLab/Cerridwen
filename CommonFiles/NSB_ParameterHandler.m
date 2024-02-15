function [status, outputParms, msg] = NSB_ParameterHandler(action, oemStruct, mutableVar)
% [status, outputParms, msg] = NSB_ParameterHandler(action, oemStruct, mutableVar)
%
% Inputs:
%   action                  - (string) 'New', 'Merge', 'Save' 
%   oemStruct               - (struct) from NSB_ParameterFile() or fully constituted reference structure
%   mutableVar              - (string, struct) Filepath+name to .xml or structure to merge into oemStruct
%
% Outputs:
%   status               - (logical) return value
%   outputParms          - (struct) updated Parameter structure
%   msg                  - (string) status message if error
%
%
% Written By David M. Devilbiss
% Rowan Universitiy (devilbiss [at] rowan.edu)
% Febuary 8 2024, Version 1.0

% Notes:
%<< ugh bad handling of output vars
% PreclinicalEEGFramework preloads
%   NSB_ParameterFile();
% Then can load
%   AnalysisParameters_txt_Callback; LoadParm_but_Callback
%
% AnalysisParameterEditor - save
%   Save_but_Callback
% DynamicParameterGUI - save
%   save_but_Callback
%
% NSB_Workflow_LIMS
%   BAked in -- Parse file specific data from Study design
%
% Todo : if one field is missing in one struct  - handle exception

status = false;
msg = '';
if nargin == 0
    action = cell(0);
    oemStruct = [];
elseif nargin == 1
    oemStruct = [];
    mergeStruct = [];
elseif nargin == 2
    mergeStruct = [];
end
if ~ischar(action)
    errorstr = ['ERROR: ParameterHandler >> 1st argument must be a character array'];
                errordlg(errorstr,'ParameterHandler');
                return;
end

switch (lower(action))
    case 'new'
        outputParms = NSB_ParameterFile();
        status = true;
    case {'merge','mergeextanalysisparms'}
        %load new struct (may be filename or struct)
        mutableVar = loadStruct(oemStruct, mutableVar);
        % One issue is that the incoming structure may be a substructure of
        % oemStruct and mostlikely the PreClinicalFramework structure
        if numel(fieldnames(oemStruct)) >= numel(fieldnames(mutableVar))
            %if oemStruct has mor fields then merge into
            [outputParms, status, msg] = doMerge(action, oemStruct, mutableVar);
        elseif isfield(oemStruct,'PreClinicalFramework') && isfield(mutableVar,'ArtifactDetection')
                %merge PreClinicalFramework
                outputParms = oemStruct;
                [outputParms.PreClinicalFramework, status, msg] = doMerge(action, oemStruct.PreClinicalFramework, mutableVar);

        elseif isfield(oemStruct,'DataSpider') && isfield(mutableVar,'dbFN')
                %merge PreClinicalFramework
                outputParms = oemStruct;
                [outputParms.DataSpider, status, msg] = doMerge(action, oemStruct.DataSpider, mutableVar);     
        else
            msg = ['ERROR: ParameterHandler >> Incompatable Parameter structures for merging.'];
        end
        if ~status
                try, NSBlog(oemStruct.PreClinicalFramework.LogFile, msg); end
                errordlg(msg,'ParameterHandler');
        end
    case 'save'




    otherwise
        errorstr = ['ERROR: ParameterHandler >> Invalid parameter manipulation command.'];
        try, NSBlog(oemStruct.PreClinicalFramework.LogFile,errorstr); end
        errordlg(errorstr,'ParameterHandler');
end


function [outStruct] = loadStruct(oemStruct, newStruct)
switch class(newStruct)
    case 'char'
        % sent a file name
        NSBlog(oemStruct.PreClinicalFramework.LogFile,['Loading: ',newStruct]);
        if exist(newStruct,'file') == 2
            outStruct = [];
            if oemStruct.PreClinicalFramework.MatlabPost2014
                outStruct = tinyxml2_wrap('load', newStruct);
            else
                outStruct = xml_load(newStruct);
            end
            if ~isempty(outStruct)
                NSBlog(oemStruct.PreClinicalFramework.LogFile,['Sucessfully Loaded: ', newStruct]);
            end
        else
            errorstr = ['ERROR: ParameterHandler:loadStruct >> Cannot load parameter file', newStruct];
            NSBlog(oemStruct.PreClinicalFramework.LogFile,errorstr);
            errordlg(errorstr,'ParameterHandler:loadStruct');
        end

    case 'struct'
        % sent a structure
        outStruct = newStruct;
    otherwise
        errorstr = ['ERROR: ParameterHandler:loadStruct >> Invalid mutableVar type'];
        NSBlog(oemStruct.PreClinicalFramework.LogFile,errorstr);
        errordlg(errorstr,'ParameterHandler:loadStruct');

end

function [oemStruct, status, msg] = doMerge(action, oemStruct, mergeStruct)
status = false; msg = [];
thisFields = fieldnames(oemStruct);

for nFields = 1:length(thisFields)
    try
        if ~isProtectedField(action, thisFields{nFields} )
            if isfield(oemStruct,thisFields{nFields}) && isfield(mergeStruct,thisFields{nFields})
                if isstruct( oemStruct.(thisFields{nFields}) )
                    [oemStruct.(thisFields{nFields}), status, msg2] = doMerge(action, oemStruct.(thisFields{nFields}), mergeStruct.(thisFields{nFields}));
                    if ~status
                        %Use deal to overwrite each element in the list
                        [oemStruct.(thisFields{nFields})] = deal(mergeStruct.(thisFields{nFields}));
                        msg = [msg, msg2];
                    end
                else
                    oemStruct.(thisFields{nFields}) = mergeStruct.(thisFields{nFields});
                end
            else
                % isfield(oemStruct,thisFields{nFields}) only
                msg = [msg, ' Warning: NSB_ParameterHandler:doMerge >> Parameter: ',thisFields{nFields},', cannot be updated'];
            end
        end

        status = true;
    catch ME
        msg = ['ERROR: NSB_ParameterHandler:doMerge >> ',ME.message];
        if ~isempty(ME.stack)
            msg = [msg,' Function: ',ME.stack(1).name,' Line # ',num2str(ME.stack(1).line)];
        end
    end
end

function status = isProtectedField(action, fieldName)
switch (lower(action))
    case 'merge'
        ProtectedFields = {'Name','Version','MatlabPost2014','LogFile'};

    case 'mergeextanalysisparms'
        ProtectedFields = {'Name','Version','MatlabPost2014','LogFile',...
        'plot', 'SampleRate', 'IndexedOutput', 'algorithm', 'logfile', 'rm2Zero', ...
        'minFlatSigLength','dvValMultiplier', 'MaxDT', 'MinArtifactDuration', 'CombineArtifactTimeThreshold', 'MuscleArtifactMultiplier',...
        };
end
    status = ismember(fieldName,ProtectedFields);


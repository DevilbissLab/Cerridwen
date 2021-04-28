function [DataStruct, status] = NSB_reReference(DataStruct,Reference,options)
% [DataStruct, status] = NSB_reReference(DataStruct,Reference,options)
%
% Inputs:
%   DataStruct         - (struct) NSB Data Structure
%   Reference          - (string/numeric) of reference channel
%   options            - (struct) of options
%                           options.logfile
% Outputs:
%   DataStruct          - (struct) NSB Data Structure
%   status              - (logical) return value
%
%
% Written By David M. Devilbiss
% NexStep Biomarkers, LLC. (info@nexstepbiomarkers.com)
% December 8 2011, Version 1.0
% April 13 2014, Version 1.1 - better handling of other data types from .fiff

status = false;
if nargin > 0
    try
        ChanNames = {DataStruct.Channel(:).Name};
    catch
        error('NSB_reReference:input','Input must have at least a NSB Data Structure as input.');
    end
else
    error('NSB_reReference:input','Input must have at least a NSB Data Structure as input.');
end

switch nargin
    case 3
        if ~isfield(options,'logfile'), options.logfile = ''; end
        %         if isnumeric(Reference)
        %             Reference = ChanNames{Reference};
        %         end
        if ischar(Reference)
            RefIDX = ~cellfun(@isempty,strfind(ChanNames,Reference)); %Index reference by name (gen logical)
            if nnz(RefIDX) < 1
                errorstr = ['ERROR: NSB_reReference >> Reference does not exist in file'];
                if ~isempty(options.logfile)
                    status = NSBlog(options.logfile,errorstr);
                else
                    errordlg(errorstr,'NSB_reReference');
                end
                return;
            elseif nnz(RefIDX) > 1
                errorstr = ['ERROR: NSB_reReference >> Multiple references With that name exist in file'];
                if ~isempty(options.logfile)
                    status = NSBlog(options.logfile,errorstr);
                else
                    errordlg(errorstr,'NSB_reReference');
                end
                return;
            else
                %ok
            end
        elseif isnumeric(Reference)
            RefIDX = false(1,length(ChanNames));
            RefIDX(Reference) = true;
        end
    case 2
        %fix as above
        options.logfile = '';
%         if isnumeric(Reference)
%             Reference = ChanNames{Reference};
%         end
        if ischar(Reference)
        RefIDX = ~cellfun(@isempty,strfind(ChanNames,Reference));
        if nnz(RefIDX) < 1
            errorstr = ['ERROR: NSB_reReference >> Reference does not exist in file'];
            if ~isempty(options.logfile)
                status = NSBlog(options.logfile,errorstr);
            else
                errordlg(errorstr,'NSB_reReference');
            end
            return;
        elseif nnz(RefIDX) > 1
            errorstr = ['ERROR: NSB_reReference >> Multiple references With that name exist in file'];
            if ~isempty(options.logfile)
                status = NSBlog(options.logfile,errorstr);
            else
                errordlg(errorstr,'NSB_reReference');
            end
            return;
        else
             %ok
        end
        elseif isnumeric(Reference)
            RefIDX = false(1,length(ChanNames));
            RefIDX(Reference) = true;
        end
    case 1
        options.logfile = '';
        [Sel,ok] = listdlg('ListString',ChanNames,'SelectionMode','single','Name','NSB: Re-Referencing Module',...
            'ListSize',[250 300],'PromptString','Select a New Reference.');
        if ok
            Reference = ChanNames{Sel};
            RefIDX = ~cellfun(@isempty,strfind(ChanNames,Reference));
            errorstr = ['Information: NSB_reReference >> ReReferencing using: ',Reference];
            if ~isempty(options.logfile)
                status = NSBlog(options.logfile,errorstr);
            else
                disp(errorstr);
            end
        else
            errorstr = ['ERROR: NSB_reReference >> No Reference selected. Aborting function.'];
            if ~isempty(options.logfile)
                status = NSBlog(options.logfile,errorstr);
            else
                disp(errorstr);
            end
            return;
        end
end

%re referencing of only same type
RefChan_Type = '';
try %this is a try because .Type may not be present
    RefChan_IDX = find(RefIDX);
    if isfield(DataStruct.Channel(RefChan_IDX),'Type')
        RefChan_Type = DataStruct.Channel(RefChan_IDX).Type;
    end
    RefChan_Data = DataStruct.Channel(RefChan_IDX).Data;
    for curChan = 1:length(DataStruct.Channel)
        if ~isempty(RefChan_Type)
            if strcmp(DataStruct.Channel(curChan).Type,RefChan_Type)
                if curChan ~= RefChan_IDX
                    if DataStruct.Channel(curChan).nSamples == DataStruct.Channel(RefChan_IDX).nSamples %Check for same length.
                        %Check for same gain. << not implemented
                        %Check for same ts << not implemented
                        DataStruct.Channel(curChan).Data = DataStruct.Channel(curChan).Data - RefChan_Data;
                        DataStruct.Channel(curChan).Name = strcat(DataStruct.Channel(curChan).Name, '-',DataStruct.Channel(RefChan_IDX).Name);
                    else
                        errorstr = ['ERROR: NSB_reReference >> Channel ',num2str(curChan),' and Reference data not the same length.'];
                        if ~isempty(options.logfile)
                            status = NSBlog(options.logfile,errorstr);
                        else
                            disp(errorstr);
                        end
                    end
                end
            else
                errorstr = ['Info: NSB_reReference >> Skipping Channel ',num2str(curChan),' because not of type ',RefChan_Type,'.'];
                if ~isempty(options.logfile)
                    status = NSBlog(options.logfile,errorstr);
                else
                    disp(errorstr);
                end
            end
        else
            if curChan ~= RefChan_IDX
                if DataStruct.Channel(curChan).nSamples == DataStruct.Channel(RefChan_IDX).nSamples %Check for same length.
                    %Check for same gain. << not implemented
                    %CHeck for same ts << not implemented
                    DataStruct.Channel(curChan).Data = DataStruct.Channel(curChan).Data - RefChan_Data;
                    DataStruct.Channel(curChan).Name = strcat(DataStruct.Channel(curChan).Name, '-',DataStruct.Channel(RefChan_IDX).Name);
                else
                    errorstr = ['ERROR: NSB_reReference >> Channel ',num2str(curChan),' and Reference data not the same length.'];
                    if ~isempty(options.logfile)
                        status = NSBlog(options.logfile,errorstr);
                    else
                        disp(errorstr);
                    end
                end
            end
        end
    end
catch ME
    errorstr = ['ERROR: NSB_reReference >> re-Reference failed. ',ME.message];
    if ~isempty(options.logfile)
        disp(errorstr);
        status = NSBlog(options.logfile,errorstr);
    else
        disp(errorstr);
    end
    return;
end
status = true;


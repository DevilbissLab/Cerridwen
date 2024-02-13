function status = NSB_UpdateStatusWindow(handles, STR, FCN)
% [status] = NSB_UpdateStatusWindow(handles, STR, FCN)
%
% Inputs:
%   handles          - (struct) main GUI handles structure
%   STR              - (string) String to add to status window
%   FCN              - (string) String of function for log file
%
% Outputs:
%   status               - (logical) return value
%
%
% Written By David M. Devilbiss
% Rowan Universitiy (devilbiss [at] rowan.edu)
% Febuary 8 2024, Version 1.0
status = false;
MaxCharInWindowRow = 36;
MaxRowsInWindow = handles.parameters.PreClinicalFramework.StatusLines;

txt = get(handles.status_stxt,'String');
if iscell(txt)
    rows = length(txt);
else
    txt = {txt}; %create cell array
    rows = 1;
end

rows = rows+1;
txt{rows,1} = STR;

% calculate the number of rows and trim if needed
rows = length(txt);
rows = rows + sum(cellfun(@length,txt) > MaxCharInWindowRow); %check for overflow rows

if rows > MaxRowsInWindow
    %txt = txt(end-(MaxRowsInWindow-1):end);
    txt = txt(rows-MaxRowsInWindow:end);
end

set(handles.status_stxt,'String',txt);
NSBlog(handles.parameters.PreClinicalFramework.LogFile, [FCN, ' ', STR, ' ',datestr(now)]);
drawnow();
status = true;
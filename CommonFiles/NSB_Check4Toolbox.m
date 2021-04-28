function ToolBoxExists = NSB_Check4Toolbox(name)
% NSB_Check4Toolbox() - Check to see if you have a licnese installed
%
% Inputs:
%   name               - (string) Name of the toolbox
% Outputs:
%   ToolBoxExists       - (logical) whether it exists or not 
%
% Written By David M. Devilbiss
% NexStep Biomarkers, LLC. (info@nexstepbiomarkers.com)
% December 8 2011, Version 1.0

ToolBoxes = ver;
BoxCell = {ToolBoxes(:).Name};
if any(strcmpi(name,BoxCell))
    ToolBoxExists = true;
else
    ToolBoxExists = false;
end
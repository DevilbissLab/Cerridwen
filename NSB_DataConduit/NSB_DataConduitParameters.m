function params = NSB_DataConduitParameters()
%NSB_DataConduitParameters - Parameters file that provides setup data for
%                           NSB_DataConduit
%
% Usage:
% >> params = NSB_DataConduitParameters()
%
% Inputs:
%   <none>
%
% Outputs:
%   params - Struct
%
% Called by: NSB_DataConduitParameters
%
% See:
%
% Author: David M Devilbiss NexStepBiomarkers, LLC.
% Rev. 0.1 30Jul2011
%
%
% NSB_DataConduitParameters History
% v.0.1 DMD first iteration
% v1.1 DMD 1st Release with WINSCP
% v1.2 DMD fixed issue with SHA1 Fingerprint
% v1.21 & 1.22 DMD fixed issue with spaces in filenames
% v1.23 - 1.24 DMD fixed issue with timeouts
% v1.25 include WinSCP 5.1.0.2625
% v1.30 rewrite of sftp segment with GUI fixes
% v1.31 Cleaned up ftp segment and mailer
% v1.32 Updated WinSCP

params.DataConduit.version = 'v.1.32';
params.DataConduit.sourcePath = 'C:\';

%File Locations
params.DataConduit.dataDir = 'C:\NexStepBiomarkers\Data';

params.DataConduit.GUIStatusLines = 15;

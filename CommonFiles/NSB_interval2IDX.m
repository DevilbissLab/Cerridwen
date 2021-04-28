function logicalIDX = NSB_interval2IDX(IntStruct,Samples,SampleRate)
% NSB_interval2IDX() - Convert intervals int the form of a struct to a logical index
%
% Inputs:
%   IntStruct           - (struct) containg
%                           IntStruct.intStarts
%                           IntStruct.intEnds
%                       - (double) total samples representing final vector
%                       - (double) SampleRate
% Outputs:
%   logicalIDX          - (logical) vector that is true corresponding to
%                            interval
%
% ToDo: check if vectors are of equal length
%          check if positively incrementing
%
% Written By David M. Devilbiss
% NexStep Biomarkers, LLC. (info@nexstepbiomarkers.com)
% December 17 2011, Version 1.0

logicalIDX = false(Samples,1);

%convert Ints to samples
IntStruct.intStarts = floor(IntStruct.intStarts * SampleRate);
IntStruct.intEnds = floor(IntStruct.intEnds * SampleRate);

%error check for index into sample zero (0 sec)
IntStruct.intStarts(IntStruct.intStarts == 0) = 1;
IntStruct.intEnds(IntStruct.intEnds == 0) = 1;

for j = 1:length(IntStruct.intStarts)
    IDX = IntStruct.intStarts(j):(IntStruct.intEnds(j)+1);
    logicalIDX(IDX) = true;
end
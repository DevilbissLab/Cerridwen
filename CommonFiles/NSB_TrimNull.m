function [output] = NSB_TrimNull(in_str)
%NSB_TrimNull Remove leading and trailing null characters
%   S = NSB_TrimNull(M) removes NULL characters from
%   M and returns the result as S. The input argument M can be a string
%   or a cell array of character vectors. When M is a
%   string or cell array of character vectors, STRTRIM removes NULL
%   characters from each element of M. S is the same type as M.
%
% Written By David M. Devilbiss
% NexStep Biomarkers, LLC. (info@nexstepbiomarkers.com)
% July 17 2017, Version 1.0

if nargin ~= 1
    error('NSB_TrimNull:minrhs', 'Not enough input arguments.');
    output = [];
    return;
end

if ischar(in_str)
    output = TrimNull(in_str);
elseif iscell(in_str)
    output = cellfun(@TrimNull, in_str, 'UniformOutput', false);
else
    error('NSB_TrimNull:UndefinedFunction','Undefined function ''NSB_TrimNull'' for input arguments of type ''',class(in_str),'''.')
end

function output = TrimNull(in_str)
    IDX = single(in_str) == 0;
    output = in_str(~IDX); 

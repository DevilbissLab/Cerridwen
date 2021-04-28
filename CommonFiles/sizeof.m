function nBytes = sizeof(Data,precision)
% sizeof functions like C++ sizeof
% Calculates the sizeof a variable if cast with a given precision such as
% int32.
%
% Usage:
%  >> nBytes = sizeof(Data,precision)
%
% Inputs:
%   Data        - Vector / Matrix of data;
%   precision   - Cast precision see fread for a list of precisions;
%
% Outputs:
%   nBytes   - size of variable in number of bytes
%
% See also: 
%
% Copyright (C) 2010 by David Devilbiss <ddevilbiss@wisc.edu>
%  v. 1.0 DMD 10Oct2010
%
% ToDo: Streamline a bit

error(nargchk(1,2,nargin,'struct'));
if nargin == 1
    precision = 'int8';
elseif ~isempty(strfind(precision,'char'))
    precision = 'int8';
elseif isstr(Data)
    error('First argument may not be of type string');
end

[r,c] = size(Data);
NewData = zeros(r,c,precision);
info = whos('NewData');
nBytes = info.bytes;

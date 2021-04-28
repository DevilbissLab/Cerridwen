function [output, status] = NSB_Buffer(data,rows)
%
% Y = NSB_Buffer(X,N) partitions signal vector X into nonoverlapping data
%    segments (frames) of length N.  Each data frame occupies one
%    column in the output matrix, resulting in a matrix with N rows.
%
%
output = []; status = false;
if nargin ~= 2
    error('NSB_Buffer:incorrectNumberOfInputs',...
       'NSB_Buffer: Input must contain 2 inputs.');
   return;
elseif ~isvector(data)
        error('NSB_Buffer:incorrectType',...
       'NSB_Buffer: Input data must be a vector.');
      return;
end

cols = (length(data) / rows);
frames = ceil(length(data) / rows);

if rem(length(data), rows) == 0
    output = reshape(data,[rows,frames]);
else
    trimDataLen = rows*(frames-1);
    trimData = data(1:trimDataLen);
    output = reshape(trimData,[rows,frames-1]);
    clear trimData;
    %add final column
    zeroVec = zeros(rows,1);
    remData = data(trimDataLen+1:end);
    zeroVec(1:length(remData)) = remData;
    output = [output,zeroVec];
end

status = true;
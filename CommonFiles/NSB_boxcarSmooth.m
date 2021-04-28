function [smooth,status,err] = NSB_boxcarSmooth(Y,span)
%
% Y can be matrix smooths column wise
%
smooth = [];status = false; err = '';
if nargin == 1
    span = 5;
elseif nargin == 0
    err = 'NSB_boxcarSmooth:Cannot Have Zero Args';
    return;
end

[yRow,Ycol] = size(Y);
x = (1:yRow)'; %rowwise

% realize span
if span <= 0
    err = 'NSB_boxcarSmooth: span Must Be Positive';
    return;
end
if span < 1, span = ceil(length(Y)*t); end % percent convention

smooth = NaN(size(Y));
smooth = boxcarSmooth(Y,span);
status = true;

function smooth = boxcarSmooth(y, span)
Ylen = size(y,1);
span = floor(span); %make int
span = min(span,Ylen); %
boxwidth = span-1 + mod(span,2); %make odd

ynanIDX = isnan(y);

if boxwidth == 1 && ~any(isnan(y))
    smooth = y;
    return;
end

if ~any(ynanIDX)
    % simplest method for most common case
    smooth = filter(ones(boxwidth,1)/boxwidth,1,y);
    startpts= cumsum(y(1:boxwidth-2,:),1);
    startpts = startpts(1:2:end,:)./ repmat( (1:2:(boxwidth-2))',1,length(startpts));
    endpts = cumsum(y(Ylen:-1:Ylen-boxwidth+3,:),1);
    endpts = endpts(end:-2:1,:)./ repmat( (boxwidth-2:-2:1)',1,length(endpts));
    smooth = [startpts;smooth(boxwidth:end,:);endpts];
else
    % if NANs can take ratio of two smoothed sequences
    yy = y;
    yy(ynanIDX) = 0;
    nn = double(~ynanIDX);
    ynum = boxcarSmooth(yy,span);
    yden = boxcarSmooth(nn,span);
    smooth = ynum ./ yden;
end

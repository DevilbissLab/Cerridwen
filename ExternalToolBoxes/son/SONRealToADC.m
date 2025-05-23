function[out,hout]=SONRealToADC(in,header)
% SONREALTOADC Converts floating point array to int16
% and returns a header with uodated scale and offset
%
% Example:
% [OUT,HOUT]=SONREALTOADC(IN, HIN)
% The input data are scaled to fill the maximum range of the int16
% output array. Scale and offset in HOUT are updated in SON format.
%
% Malcolm Lidierth Updated 10/06
% Copyright � The Author & King's College London 2002-2006


% Scale+offset to give -32768 to 32768 range
% Leave the int16 cast to limit the maximum to 32767
scale=(max(in(:))-min(in(:)))/65536;
offset=(min(in(:))+max(in(:)))/2;
out=int16((in-offset))/scale;  % convert to int16
hout=header;                    % copy header info
hout.scale=scale(1)*6553.6;     % adjust scale to conform to SON scale format...
hout.offset=offset;               % ... and set offset
hout.kind=1;                      % set kind to ADC channel

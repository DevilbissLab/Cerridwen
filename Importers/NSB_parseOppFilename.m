function [FileStartDate, ID, Ch] = NSB_parseOppFilename(filename)
%input (string)
%this is hardcoded in File name
MM = str2num(filename(1:2));
DD = str2num(filename(3:4));
HH = str2num(filename(5:6));
ID = filename(7:8);
Ch = filename(9:10);

FileStartDate = datenum([00 MM DD HH 00 00]);
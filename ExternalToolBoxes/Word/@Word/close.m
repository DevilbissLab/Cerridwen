function this = close(this)

% Close the word window:
invoke(this.wordHandle,'Close');
% Quit MS Word
invoke(this.actxWord,'Quit');
% Close Word and terminate ActiveX:
delete(this.actxWord);

% After 2003 Office changed the way they handle COM servers and there is an
% incompatability with matlab. As such word/excel processes are left over.
%This is a global way to kill all but is very crude. https://www.mathworks.com/matlabcentral/newsreader/view_thread/247511
% Quit Excel and delete the server.
%e.Quit;
%e.delete;
%system('taskkill /F /IM EXCEL.EXE');
% %
% You could also handle this by...
%         ver = this.actxWord.Version;
%     if ischar(ver)
%         ver = str2double(ver);
%     end
%     if ver < 14
%       ...



end
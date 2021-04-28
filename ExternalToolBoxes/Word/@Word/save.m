function this = save(this,saveAs,FileName)

%
%NSBEdited 04Aug2013
%NSBEdited 25Aug2016

if nargin == 1
    saveAs = false;
end
% Save existing file:
if saveAs
    ver = this.actxWord.Version;
    if ischar(ver)
        ver = str2double(ver);
    end
    if ver < 14
        this.wordHandle.SaveAs(FileName);
    else
        this.wordHandle.SaveAs2(FileName);
    end
else
    this.wordHandle.Save;
    %invoke(this.wordHandle,'Save');
end
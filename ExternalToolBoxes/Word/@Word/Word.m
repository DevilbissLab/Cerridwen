function this = Word( file, visible, readOnly )
% this = Word( file, visible, readOnly )
%
%NSBEdited 04Aug2013 to include empty inputs
%NSBEdited 29Nov2016 to allow readonly
%

switch nargin
    case 0
      visible=false; 
      this.file = '';
      readOnly = false;
    case 1
      visible=false; 
      this.file = file;
      readOnly = false;
    case 2
        readOnly = false;
        if ~islogical(visible)
            this = '';
            return;
        end
        if ~ischar(file)
            this = [];
            return;
        else
            this.file = file;
        end
    case 3
        if ~islogical(visible)
            this = '';
            return;
        end
        if ~islogical(readOnly)
            this = '';
            return;
        end
        if ~ischar(file)
            this = [];
            return;
        else
            this.file = file;
        end
            
    otherwise
        this = []; 
        return; 
end
        
% NSB        
% if nargin<2
%     visible=false;
% end
% this.file = file;

try
    % Start an ActiveX session with Word:
    actxWord = actxserver('Word.Application');
    if ~exist(this.file,'file');
        % Create new document:
        wordHandle = invoke(actxWord.Documents,'Add');
    else
        % Open existing document:
        wordHandle = invoke(actxWord.Documents,'Open',file, false, readOnly);
    end
catch me
    delete(actxWord);
    %s=lasterror;
    error(me.message);
end

this.wordHandle = wordHandle;
this.actxWord = actxWord;
this.defaultFont = this.actxWord.Selection.Style.Font;

this = class( this, 'Word' );

setVisible(this,visible);

end
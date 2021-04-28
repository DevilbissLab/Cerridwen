function addText( this, text, style, n )

if nargin==2
    style='Normal';
    n=1;
elseif nargin==3
    n=1;
elseif nargin<2 || nargin>4
    error('4 inputs required');
end

setStyle(this,style);
this.actxWord.Selection.TypeText(text);
newline(this,n);

end

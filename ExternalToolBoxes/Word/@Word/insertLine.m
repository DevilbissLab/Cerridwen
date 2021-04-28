function h = insertLine( this ,n)
%NSB original.
h = this.actxWord.Application.Selection.InlineShapes.AddHorizontalLineStandard;
newline(this,n);
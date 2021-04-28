function setStyle( this, style )

for i=1:this.actxWord.ActiveDocument.Styles.Count
    if strcmpi( style, get(this.actxWord.ActiveDocument.Styles.Item(i),'NameLocal') )
        this.actxWord.Selection.Range.Style = this.actxWord.ActiveDocument.Styles.Item(i);
        return;
    end
end

error('Could not find style %s.\nType "Styles( wordObject )" to show the availabe styles',style);
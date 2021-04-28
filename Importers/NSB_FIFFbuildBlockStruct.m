function BlockStruct = NSB_FIFFbuildBlockStruct(TagDir, fid)
%
%
%
BLOCK_START = 104;
BLOCK_END = 105;
tagIDs = cell2mat({TagDir(:).kind});

IDX = find(tagIDs == BLOCK_START);
nStruct = 1;
mask = true(1,length(tagIDs));
for curIDX = fliplr(IDX)
    tag = NSB_FIFFgetTagData(fid,TagDir(curIDX));
    BlockStruct(nStruct).BlockID = tag.data;
    BlockStruct(nStruct).Name = NSB_FIFFtagLookup(tag.data,'block');
    
    maskTagIds = tagIDs .* mask;
    endblock = find(maskTagIds(curIDX:end) == BLOCK_END,1,'first') + curIDX-1;
    TagIDXs = curIDX : endblock;
    TagIDXs = TagIDXs(mask(curIDX:endblock));
    %TagIDXs = curIDX : (find(tagIDs(curIDX:end) == BLOCK_END,1,'first')+curIDX-1);
    mask(TagIDXs) = false;
    BlockStruct(nStruct).TagIDXs = TagIDXs;
    nStruct = nStruct +1;
end
   
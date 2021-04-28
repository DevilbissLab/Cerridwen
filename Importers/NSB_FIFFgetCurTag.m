function tag = NSB_FIFFgetCurTag(fid)
tag.kind = fread(fid,1,'int32');
tag.type = fread(fid,1,'int32');
tag.size = fread(fid,1,'int32');
tag.next = fread(fid,1,'int32');
function [TagDir,FIFF_HDR] = NSB_FIFreadTagDir(fid,options)
%
%
% The file has to start always with the same sequence of tags:
% FILE_START =
%     file_id
%     dir_pointer
%     free_list (optional)
%     parent_file_id (optional)
%
Tag_ID = 1;
FIFFdef = NSB_FIFFdataTypeDefinitions();

if ischar(fid)
    %open file (get fid)
end
if ftell(fid) > 0 fseek(fid,0,'bof');end

%Process 1st tag making sure it is a FIF format file
tag = NSB_FIFFgetCurTag(fid);
if any([tag.kind ~= FIFFdef.tag.file_id, tag.type ~= 31, tag.size ~= 20])
            errorstr = ['ERROR: NSB_FIFreadTagDir >> Malformed .fiff header in 1st tag: ',filename];
        if ~isempty(options.logfile)
            status = NSBlog(options.logfile,errorstr);
        else
            errordlg(errorstr,'NSB_FIFreadTagDir');
        end
        fclose(fid);
        return;
else
    %read data in tag block
    [tag,fpos,status] = NSB_FIFFgetTagData(fid,tag);
    FIFF_HDR = tag.data;
end

%Process 2nd tag making sure a tag directory exists
if tag.next == 0
    tag = NSB_FIFFgetCurTag(fid);
else
    fpos = ftell(fid);
	fseek(fid,tag.next,'bof'); %this may not work
    tag = NSB_FIFFgetCurTag(fid);
end
if tag.kind ~= FIFFdef.tag.dir_pointer
        errorstr = ['ERROR: NSB_FIFreadTagDir >> Malformed .fiff, Missing Tag_Directory tag: ',filename];
        if ~isempty(options.logfile)
            status = NSBlog(options.logfile,errorstr);
        else
            errordlg(errorstr,'NSB_FIFreadTagDir');
        end
        fclose(fid);
        return;
else
   [tag,fpos,status] = NSB_FIFFgetTagData(fid,tag);
   if tag.data > 0
       fseek(fid,tag.data,'bof');
       tag = NSB_FIFFgetCurTag(fid); %get tag for dir lilsting
       %can check to see if type 102 - dir
       tag = NSB_FIFFgetTagData(fid,tag);
       TagDir = tag.data;
   else
       %build it from Scratch
       TagDir = struct('kind',[],'type',[],'size',[],'pos',[]);
       curTag = 1;
       fseek(fid,0,'bof');
    while tag.next ~= -1
        fpos = ftell(fid);
        tag = NSB_FIFFgetCurTag(fid);
        dir(k).kind = tag.kind;
        dir(k).type = tag.type;
        dir(k).size = tag.size;
        dir(k).pos  = fpos;
    end
   end 
end






function status = NSBlog(LogFileName,LogStr)
%
% LogFileName is path\filename
% Fast attemt at this 

try
fid = fopen(LogFileName,'at');
if iscellstr(LogStr)
    for i=1:length(LogStr)
        fprintf(fid, '%s\n',LogStr{i});
    end
else
    fprintf(fid, '%s\n',LogStr);
end
fclose(fid);
status = true;
catch
    status = false;
end
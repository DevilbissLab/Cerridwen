function status = NSB_MergeParameterFiles()
% function status = mergeNSBParameterFiles()
% 
% The purpose of this funcion is to batch process multiple NexStep Biomarkers 
% Parameter Files .xml files with a Master template to make sure ALL of the
% parameters are identical (to the Master) with the sole exception of the
% artifact detection.
% 
status = false;
[MasterXML, MasterXMLpath] = uigetfile({'*.xml','NexStep Biomarkers Parameter Files (*.xml)';'*.*',  'All Files (*.*)'},'Choose a parameter file');
MasterXMLStruct = tinyxml2_wrap('load', [MasterXMLpath, MasterXML]);
disp(['Loaded ', [MasterXMLpath, MasterXML]]);

MergeXMLDir = uigetdir('', 'Please Select NexStep Biomarkers Parameter Files Directory to Merge');
MergeXMLFileList = fuf(MergeXMLDir, 0, 'detail'); % do not do recursion
disp(['Found ', num2str(length(MergeXMLFileList)), ' Parameter Files']); disp('...');

SaveXMLDir = uigetdir('', 'Please Select Directory to Save New/Merged NexStep Biomarkers Parameter Files');

f = waitbar(0,'1','Name','Merging Parameter Files...', 'CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
f.Children(2).Title.Interpreter = 'none';
setappdata(f,'canceling',0);
FileList_len = length(MergeXMLFileList);
for curFile = 1:FileList_len
    if getappdata(f,'canceling')
        break
    end
    disp(['Processing...',MergeXMLFileList{curFile}]);
    [~,fn,ext] = fileparts(MergeXMLFileList{curFile});
    waitbar(curFile/FileList_len,f,sprintf('%s',[fn,ext]));
    MergeXMLStruct = tinyxml2_wrap('load', MergeXMLFileList{curFile});
    SaveXMLStruct = MasterXMLStruct; %refresh Save Struct
    SaveXMLStruct.ArtifactDetection = MergeXMLStruct.ArtifactDetection;
    tinyxml2_wrap('save', fullfile(SaveXMLDir, [fn, ext]), SaveXMLStruct);
    disp(['Successfully Saved: ',fullfile(SaveXMLDir,[fn, ext])]);
end
try, delete(f); end
status = true;
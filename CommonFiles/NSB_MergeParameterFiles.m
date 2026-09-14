function status = NSB_MergeParameterFiles(IgnoreField,bias)
% function status = mergeNSBParameterFiles(DConlyFlag)
% 
% IgnoreField        - (cell) {"algorithm","full.DCcalculation","full.MinArtifactDuration","full.CombineArtifactTimeThreshold","all"}
%                       These are the fields that are ignored during the merge - i.e. dictated by the MasterXML
% bias               -  (double) adds a bias value to ArtifactDetection.full.DCcalculation
% The purpose of this funcion is to batch process multiple NexStep Biomarkers 
% Parameter Files .xml files with a Master template to make sure ALL of the
% parameters are identical (to the Master) with the sole exception of the
% artifact detection.
% 
status = false;

if nargin < 1
    IgnoreField = false;
    bias = 0;
elseif nargin < 2 || isempty(bias)
     bias = 0;
end

[MasterXML, MasterXMLpath] = uigetfile({'*.xml','NexStep Biomarkers Parameter Files (*.xml)';'*.*',  'All Files (*.*)'},'Choose a parameter file');
if MasterXML == 0, return; end
MasterXMLStruct = tinyxml2_wrap('load', [MasterXMLpath, MasterXML]);
disp(['Loaded ', [MasterXMLpath, MasterXML]]);

MergeXMLDir = uigetdir('', 'Please Select NexStep Biomarkers Parameter Files Directory to Merge');
if MergeXMLDir == 0, return; end
MergeXMLFileList = fuf(MergeXMLDir, 0, 'detail'); % do not do recursion
disp(['Found ', num2str(length(MergeXMLFileList)), ' Parameter Files']); disp('...');

SaveXMLDir = uigetdir('', 'Please Select Directory to Save New/Merged NexStep Biomarkers Parameter Files');
if SaveXMLDir == 0, return; end

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
    if strcmpi(ext,'.xml')
    MergeXMLStruct = tinyxml2_wrap('load', MergeXMLFileList{curFile});
    SaveXMLStruct = MasterXMLStruct; %refresh Save Struct
    SaveXMLStruct.ArtifactDetection = MergeXMLStruct.ArtifactDetection;
    
    for CurField = 1:length(IgnoreField) %iterate
    switch lower(IgnoreField{CurField})
        case "algorithm"
            % Force Master ArtifactDetection.algorithm
            SaveXMLStruct.ArtifactDetection.algorithm = MasterXMLStruct.ArtifactDetection.algorithm;
        case "full.dccalculation"
            SaveXMLStruct.ArtifactDetection.full.DCcalculation = MasterXMLStruct.ArtifactDetection.full.DCcalculation;
        case "full.minartifactduration"
            SaveXMLStruct.ArtifactDetection.full.MinArtifactDuration = MasterXMLStruct.ArtifactDetection.full.MinArtifactDuration;
        case "full.combineartifacttimethreshold"
            SaveXMLStruct.ArtifactDetection.full.CombineArtifactTimeThreshold = MasterXMLStruct.ArtifactDetection.full.CombineArtifactTimeThreshold;
        case "all"
            SaveXMLStruct.ArtifactDetection.algorithm = MasterXMLStruct.ArtifactDetection.algorithm;
            SaveXMLStruct.ArtifactDetection.full.DCcalculation = MasterXMLStruct.ArtifactDetection.full.DCcalculation;
            
            %temp fix - one could recursively check through all to make sure structure is updated.
            SaveXMLStruct.ArtifactDetection.full.SpectralNormCutoff = MasterXMLStruct.ArtifactDetection.full.SpectralNormCutoff;
            SaveXMLStruct.ArtifactDetection.full.MinSignal = MasterXMLStruct.ArtifactDetection.full.MinSignal;


        otherwise
            disp(['IgnoreField is not changed']);
    end
    end
    if bias ~= 0
        SaveXMLStruct.ArtifactDetection.full.DCcalculation = SaveXMLStruct.ArtifactDetection.full.DCcalculation + bias;
    end

    tinyxml2_wrap('save', fullfile(SaveXMLDir, [fn, ext]), SaveXMLStruct);
    disp(['Successfully Saved: ',fullfile(SaveXMLDir,[fn, ext])]);
    else
    disp(['Skipping: ',fullfile(SaveXMLDir,[fn, ext])]);
    end
end
try, delete(f); end
status = true;
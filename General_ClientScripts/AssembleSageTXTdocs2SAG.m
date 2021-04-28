%Sage file assembley
%
%


Path = uigetdir('', 'Select Sage data directory.');
FileList = fuf (Path,0);

[~,FileNames,FileExts] = cellfun(@fileparts,FileList,'UniformOutput',false);
FileNames = cellfun(@strtrim,FileNames,'UniformOutput',false);
for curfile = 1:length(FileNames)
Subjects{curfile,1} = FileNames{curfile}(1:end-1);
end
uFileList = unique(Subjects);

for curfile = 1:length(uFileList)
    disp(['Assembling: ',uFileList{curfile}]);
    IDX = strcmp(Subjects,uFileList(curfile));
    ImportList = FileNames(IDX);
    [~,sIDX] = sort(ImportList);
    
    FragFiles = [ImportList(sIDX),FileExts(sIDX)];
    %load files
    data = []; 
    FirstTS = 0;
    for curFrag = 1:size(FragFiles,1)
         %read data
         disp(['Loading: ',[FragFiles{curFrag,1}, FragFiles{curFrag,2}] ]);
        data = dlmread(fullfile(Path, [FragFiles{curFrag,1}, FragFiles{curFrag,2}]) ,'\t');
        if curFrag == 1
            FirstTS = data(1,1);
        end
        data(:,1) = data(:,1) - FirstTS;
        
         %write data
         disp(['Saving to: ',[uFileList{curfile}, '.sag'] ]);
        dlmwrite(fullfile(Path, [uFileList{curfile}, '.sag']),data,'delimiter','\t','precision','%.8f','-append')
            data = [];
    end
end
    
        
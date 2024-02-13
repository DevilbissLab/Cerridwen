function status = NSB_DataScraper(LookinDirs,ShredFlag)
%David Devilbiss
%NexStepBiomarkers
%Nov 16 2011
%Copywrite 2011
%todo:
% num runs; 

%Requires: 'XML Toolbox'
[~,parms] = NSB_ParameterHandler('new');
RunForeverLoop = true;

if nargin < 1
    %use parameter file
    LookinDirs = parms.DataSpider.StartDirs;
end
if nargin < 2
    ShredFlag = true;
end
pause(parms.DataSpider.PollPeriod);
StartTic = tic;

while RunForeverLoop
ScrapeFileList = fuf(LookinDirs,0,'detail'); %only look in that folder since processed data is below that
%parse New files
for curFile = 1:length(ScrapeFileList)
    
    [pathstr, name, ext] = fileparts(ScrapeFileList{curFile});
    switch ext
        case '.sk'
            %silverkey file
            if exist(fullfile(pathstr,'decrypt')) == 0
                mkdir(fullfile(pathstr,'decrypt'));
            end
            if exist(fullfile(pathstr,'dataTank')) == 0
                mkdir(fullfile(pathstr,'dataTank'));
            end
            if exist(fullfile(pathstr,'processedData')) == 0
                mkdir(fullfile(pathstr,'processedData'));
            end
            %decrypt files
            if ShredFlag
                 retVal = BCiLab_Decrypt(ScrapeFileList{curFile}, fullfile(pathstr,'decrypt'),true);
            else
                 retVal = BCiLab_Decrypt(ScrapeFileList{curFile}, fullfile(pathstr,'decrypt'),true,ShredFlag);   
            end
            %Add files to database
            %ISSUE (What happends if files already exist in dir)
            
            DatafileNames = fuf(fullfile(pathstr,'decrypt'),0);
            for curDecryptFile = 1:length(DatafileNames)
                % 1) Move file to Holding Dir
                [status,message,messageid]=movefile(fullfile(pathstr,'decrypt',DatafileNames{curDecryptFile}),...
                    fullfile(pathstr,'dataTank',DatafileNames{curDecryptFile}));
                % 2) Add to DataBase
                status = NSB_dbHandler(parms.DataSpider.XMLdbFile, 'ADD', fullfile(pathstr,'dataTank',DatafileNames{curDecryptFile}),fullfile(pathstr,'dataTank'));
            end
            %Move processed file out of que
            [status,message,messageid]=movefile(ScrapeFileList{curFile}, fullfile(pathstr,'processedData'));
            
        case '.csv'
            %do something similar
    end
end
disp(['Finished Scrape : ',datestr(now)]);
%save dbase
status = NSB_dbHandler(parms.DataSpider.XMLdbFile, 'SAVE');

pausetime = parms.DataSpider.PollPeriod-ceil(toc(StartTic));
if pausetime < 0, pausetime = 0; end
pause(pausetime);
StartTic = tic;
end

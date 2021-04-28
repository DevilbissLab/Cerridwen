function [DataStruct,status] = NSB_mapElectrodePosition(DataStruct,options)
%[DataStruct,status] = NSB_mapElectrodePosition(DataStruct,options)
%
% Inputs:
%   DataStruct              - (Struct) NSB DataStruct Format
%   options               - (Struct - optional)
%                               .progress - (logical) show progress bar
%                               .logfile - logfile path+name
%                               .showHeadPlot - (logical) show plot of electrode orientation and save as .pdf
%                               .assumeTemplateChOrderCorrect - (logical) when true, do not do
%                                   normalization of electrode positions and assume the serial order of
%                                   electrodes is the same as the template
%                               .ChanLocFiles_Dir - (string) path location of the .mat files containing
%                                   electrode positions. default location =
%                                   'C:\NexStepBiomarkers\EEGFramework\ChanLocFiles';
%
% Outputs:
%   DataStruct           - (struct) NSB File DataStructure
%                       returns a single struct representing the file for that Subject (ID)
%   status               - (logical) return value
%
%
% Written By David M. Devilbiss
% NexStep Biomarkers, LLC. (info@nexstepbiomarkers.com)
% December 8 2011, Version 1.0

%
%
% addds valid tag to chan << this should be implemented across the board.
% Channel localizations files are now stored in .\ChanLocFiles of the
% program root dir

status = false;
switch nargin
    case 1
        if ~isstruct(DataStruct)
            errordlg('ERROR: NSB_mapElectrodePosition >> Input Must be NSB DataStruct','NSB_mapElectrodePosition');
            return;
        end
        options.logfile = '';
        options.progress = true;
        options.showHeadPlot = true;
        options.assumeTemplateChOrderCorrect = false;
        options.ChanLocFiles_Dir = 'C:\NexStepBiomarkers\EEGFramework\ChanLocFiles';
        options.PositionTemplate = '';
        %set default options
        %log file
        %chan read vector
        %progress Bar
    case 2
        if ~isstruct(DataStruct)
            errordlg('ERROR: NSB_mapElectrodePosition >> Input Must be NSB DataStruct','NSB_mapElectrodePosition');
            return;
        end
        inputError = false;
        if ~isfield(options,'logfile'), options.logfile = '';inputError = true; end
        if ~isfield(options,'progress'), options.progress = true;inputError = true; end
        if ~isfield(options,'showHeadPlot'), options.showHeadPlot = true;inputError = true; end
        if ~isfield(options,'assumeTemplateChOrderCorrect'), options.assumeTemplateChOrderCorrect = false;inputError = true; end
        if ~isfield(options,'ChanLocFiles_Dir'), options.ChanLocFiles_Dir = 'C:\NexStepBiomarkers\EEGFramework\ChanLocFiles';inputError = true; end
        if ~isfield(options,'PositionTemplate'), options.PositionTemplate = '';inputError = true; end
        if inputError
            errorstr = ['Warning: NSB_mapElectrodePosition >> Missing at least 1 options: Missing were set to default(s)'];
            if ~isempty(options.logfile)
                NSBlog(options.logfile,errorstr);
            else
                errordlg(errorstr,'NSB_mapElectrodePosition');
            end
        end
    otherwise
        error('ERROR: NSB_mapElectrodePosition >> incurrect nubmer of parameters');
        return;
end

ChanTypes = {DataStruct.Channel(:).Type};
switch DataStruct.FileFormat
    case '.fif'
        %find Channels of type
        DataStruct.EEGchansIDX = find(strcmpi(ChanTypes, 'eeg'));
        DataStruct.MEGchansIDX = find(strcmpi(ChanTypes, 'meg'));
        DataStruct.STIMchansIDX = find(strcmpi(ChanTypes, 'stim'));
        DataStruct.MISCchansIDX = find(strcmpi(ChanTypes, 'misc'));
        
        %build location matrix
        EEG_XYZ = []; EEG_REF = [];EEG_IDX = 1;
        MEG_XYZ = [];MEG_CNTR = 1;
        ValidChan_IDX = [];
        for curloc = 1:length(DataStruct.Channel)
            %test for EEG
            switch lower(DataStruct.Channel(curloc).Type)
                case 'eeg'
                    if DataStruct.Channel(curloc).Tag.coord_frame == 4 %head frame
                        if DataStruct.Channel(curloc).Tag.loc(1:3) ~= [0;0;0]
                            %good channel and used
                            DataStruct.Channel(curloc).Valid = true;
                            ValidChan_IDX = [ValidChan_IDX, curloc];
                            EEG_XYZ(:,EEG_IDX) = DataStruct.Channel(curloc).Tag.eeg_loc(1:3,1);
                            EEG_REF(:,EEG_IDX) = DataStruct.Channel(curloc).Tag.eeg_loc(1:3,2);
                            EEG_IDX = EEG_IDX +1;
                        else
                            % Just tag bad channels without location info
                            DataStruct.Channel(curloc).Valid = false;
                            % note unclear whether bad chans removed !!!  <<<<<<<<<<<<<<<<<<
                        end
                    else
                        DataStruct.Channel(curloc).Valid = false;
                        errorstr = ['Warning: NSB_mapElectrodePosition >> EEG Chan ',num2str(EEG_IDX), 'is not in "head" coordinate Frame. Ignoring coordinate and marking channel as invalid'];
                        if ~isempty(options.logfile)
                            NSBlog(options.logfile,errorstr);
                        else
                            errordlg(errorstr,'NSB_mapElectrodePosition');
                        end
                    end
                case 'meg'
                    %Still to do....
                otherwise
                    DataStruct.Channel(curloc).Valid = false;
            end
        end
        
        nEEGchans = size(EEG_XYZ,2);
        nMEGchans = size(MEG_XYZ,2);
        
        %Locate Reference if there is one
        ref_locations = {unique(EEG_REF(1,:)); unique(EEG_REF(2,:)); unique(EEG_REF(3,:))};
        if length(ref_locations{1}) + length(ref_locations{2}) + length(ref_locations{3}) == 3
            %only 1 reference
            %            [trash,c] = ind2sub(size(EEG_XYZ),find(EEG_XYZ ==  repmat(ref_locations,1,size(EEG_XYZ,2))));
            [trash,c] = ind2sub(size(EEG_XYZ),find(EEG_XYZ ==  EEG_REF));
            if ~isempty(c)
                REF_IDX = c(1);
            else
                REF_IDX = []; %i.e. ear Reference
            end
        else
            %  more than 1 reference used.
        end
        
        % It turn out that there are some files with 2 overlapping or very
        % close channels and you end up with 61 channels not 60. so the
        % template cannot.Be loaded yet..
        %also....
        %So to date the limited template files seem to be the same channel order as fif... but I do not trust this.
        %here is a dynamic way to align and warp fif device coordinates to
        %standardized mappings.
        
        %calculate center offset and sphere size
        Diams = abs( min(EEG_XYZ,[],2)) +  abs( max(EEG_XYZ,[],2));
        Centers = Diams/2 + min(EEG_XYZ,[],2);
        
        %center the dome (not necessarilly Cz)
        EEG_XYZ = bsxfun(@minus, EEG_XYZ, Centers);
        %Scale to Unit Circle
        EEG_XYZ = bsxfun(@rdivide, EEG_XYZ, Diams) *2;
        %find putatice Fpz
        Fpz_IDX = find(EEG_XYZ(2,:) == max(EEG_XYZ(2,:)));
        %find putatice Cz Cannot use max(z) because may be rotated
        [trash, rho] = cart2pol(EEG_XYZ(1,:),EEG_XYZ(2,:));
        Cz_IDX = find(rho == min(rho));
        
        %Pick sides
        side1 = find(EEG_XYZ(1,:) == max(EEG_XYZ(1,:)));
        side2 = find(EEG_XYZ(1,:) == min(EEG_XYZ(1,:)));
        %generate point between Cz and Fpz
        temp_pt = EEG_XYZ(:,Fpz_IDX) + EEG_XYZ(:,Cz_IDX);
        %find Smallest Distance
        D = pdist2(repmat(temp_pt',2,1), [EEG_XYZ(:,side1), EEG_XYZ(:,side2)]');
        [trash, side] = min(D(1,:));
        if side == 1
            Side_IDX = side1;
        else
            Side_IDX = side2;
        end
        
        %zero Z-Axis Translate only
        if sign(EEG_XYZ(3,Side_IDX)) == -1
            EEG_XYZ(3,:) = bsxfun(@minus, EEG_XYZ(3,:), EEG_XYZ(3,Side_IDX));
        elseif sign(EEG_XYZ(3,Side_IDX)) == 1
            EEG_XYZ(3,:) = bsxfun(@plus, EEG_XYZ(3,:), EEG_XYZ(3,Side_IDX));
        end
        
        %Now deal with rotation as best as you can...
        %Requires a figure but you dont have to display it
        if options.showHeadPlot
            h_fig = figure;
            h1 = plot3(EEG_XYZ(1,:),EEG_XYZ(2,:),EEG_XYZ(3,:),'.k','MarkerSize',30,'Visible','on');
            hold on;
            plot3(EEG_XYZ(1,Side_IDX),EEG_XYZ(2,Side_IDX),EEG_XYZ(3,Side_IDX),'.c','MarkerSize',40);
            plot3(EEG_XYZ(1,Fpz_IDX),EEG_XYZ(2,Fpz_IDX),EEG_XYZ(3,Fpz_IDX),'.G','MarkerSize',40);
            plot3(EEG_XYZ(1,Cz_IDX),EEG_XYZ(2,Cz_IDX),EEG_XYZ(3,Cz_IDX),'.r','MarkerSize',40);
            xlabel('X-Axis');
            ylabel('Y-Axis');
            zlabel('Z-Axis');
        else
            h_fig = figure('Visible','off');
            h1 = plot3(EEG_XYZ(1,:),EEG_XYZ(2,:),EEG_XYZ(3,:),'Visible','off'); %his needs to be plotted not shown
        end
        
        
        %rotate around the Y-Axis (through Nasion)
        [az,el,rho] = cart2sph(EEG_XYZ(1,Fpz_IDX), EEG_XYZ(2,Fpz_IDX), EEG_XYZ(3,Fpz_IDX));
        deg_el = (180/pi) * el;
        pt_sign = sign(EEG_XYZ(3,Fpz_IDX));
        rotate(h1,[0 1 0], pt_sign*deg_el,EEG_XYZ(:,Side_IDX));
        
        %rotate around the X-Axis (through Ear)
        [az,el,rho] = cart2sph(EEG_XYZ(1,Cz_IDX), EEG_XYZ(2,Cz_IDX), EEG_XYZ(3,Cz_IDX));
        deg_el = (180/pi) * el -90;
        rotate(h1,[1 0 0],-deg_el,EEG_XYZ(:,Side_IDX));
        
        % %rotate X-Axis
        % %ok because head is normally down
        % [az,el,rho] = cart2sph(EEG_XYZ(1,Fpz_IDX), EEG_XYZ(2,Fpz_IDX), EEG_XYZ(3,Fpz_IDX));
        % deg_el = (180/pi) * el;
        % rotate(h1,[1 0 0],-deg_el/2,EEG_XYZ(:,Cz_IDX)); %crap this should be using fiduciaries???
        %
        % %rotate Y-Axis
        % [az,el,rho] = cart2sph(EEG_XYZ(1,Side_IDX), EEG_XYZ(2,Side_IDX), EEG_XYZ(3,Side_IDX));
        % deg_el = (180/pi) * el;
        % rotate(h1,[0 1 0],-deg_el/2,EEG_XYZ(:,Cz_IDX));
        
        %Recenter on Cz
        EEG_XYZ = [get(h1,'XData'); get(h1,'YData'); get(h1,'ZData')];
        EEG_XYZ(1:2,:) = bsxfun(@minus, EEG_XYZ(1:2,:), EEG_XYZ(1:2,Cz_IDX));
        
        %rotate Z-Axis
        [az,el,rho] = cart2sph(EEG_XYZ(1,Fpz_IDX), EEG_XYZ(2,Fpz_IDX), EEG_XYZ(3,Fpz_IDX));
        deg_az = (180/pi) * az;
        rotate(h1,[0 0 1],-deg_az,EEG_XYZ(:,Cz_IDX));
        
        %Now you are in normalized space !
        EEG_XYZ = [get(h1,'XData'); get(h1,'YData'); get(h1,'ZData')];
        %zero Z-Axis Translate only (Again)
        if sign(EEG_XYZ(3,Fpz_IDX)) == 1
            EEG_XYZ(3,:) = bsxfun(@minus, EEG_XYZ(3,:), EEG_XYZ(3,Fpz_IDX));
        elseif sign(EEG_XYZ(3,Fpz_IDX)) == -1
            EEG_XYZ(3,:) = bsxfun(@plus, EEG_XYZ(3,:), EEG_XYZ(3,Fpz_IDX));
        end
        close(h_fig);
        
        %             %Replot
        %             if options.showHeadPlot
        %                 f1 = figure;
        %                 h1 = plot3(EEG_XYZ(1,:),EEG_XYZ(2,:),EEG_XYZ(3,:),'.b','MarkerSize',20);
        %                 hold on;
        %                 h2 = plot3(template_XYZ(1,:),template_XYZ(2,:),template_XYZ(3,:),'.k','MarkerSize',25);
        %                 plot3(EEG_XYZ(1,Side_IDX),EEG_XYZ(2,Side_IDX),EEG_XYZ(3,Side_IDX),'+c','MarkerSize',20);
        %                 plot3(EEG_XYZ(1,Fpz_IDX),EEG_XYZ(2,Fpz_IDX),EEG_XYZ(3,Fpz_IDX),'+g','MarkerSize',20);
        %                 plot3(EEG_XYZ(1,Cz_IDX),EEG_XYZ(2,Cz_IDX),EEG_XYZ(3,Cz_IDX),'+r','MarkerSize',20);
        %                 xlabel('X-Axis');
        %                 ylabel('Y-Axis');
        %                 zlabel('Z-Axis');
        %             end
        
        %% Determine the 3D closeness of points and whether the channel order is the same
        %search for smallest distance
        D = pdist(EEG_XYZ');
        D = squareform(D);
        D(D == 0) = NaN;
        if min(min(D)) <= 0.01                                              %<<<<<<<<<<<<<<<<<<Hardcoded
            [r,c] = find(D <= 0.01);                                            %<<<<<<<<<<<<<<<<<<Hardcoded
            errorstr = ['Warning: NSB_mapElectrodePosition >> Channels : ',num2str(c'),' are extremely close (Euclidean distance < 0.01).' ];
            if ~isempty(options.logfile)
                NSBlog(options.logfile,errorstr);
            else
                errordlg(errorstr,'NSB_mapElectrodePosition');
            end
        end
        
        % Now that we are in normal space load template.
        if ~isempty(options.PositionTemplate)
            [path,fn,ext] = fileparts(options.PositionTemplate);
            if isempty(path)
                chan_loc_file = fullfile(options.ChanLocFiles_Dir,[fn,ext]);
            else
                chan_loc_file = options.PositionTemplate;
            end
        else
            % if template not specified try to find it
        % First try with current chan number...
        % note unclear whether bad chans removed !!!  <<<<<<<<<<<<<<<<<<
        %now load template if exists
        chan_loc_file = fullfile(options.ChanLocFiles_Dir,['Elekta_',num2str(nEEGchans),'.mat']);
        if exist(chan_loc_file,'file') ~= 2
            % Matched file does not exist...
            errorstr = ['Warning: NSB_mapElectrodePosition >> No Channel Localization file: ',chan_loc_file,'. Trying to remove overlapping channels.' ];
            %   errorstr = ['Warning: NSB_mapElectrodePosition >> No Channel Localization file: ',chan_loc_file,'. Mapping function terminated and using device generated names.' ];
            if ~isempty(options.logfile)
                NSBlog(options.logfile,errorstr);
            else
                errordlg(errorstr,'NSB_mapElectrodePosition');
            end
            
            % remove overlapping chanels..
            overlapChanPairs = length(c)/2;
            chan_loc_file = fullfile(options.ChanLocFiles_Dir,['Elekta_',num2str(nEEGchans - overlapChanPairs),'.mat']);
            if exist(chan_loc_file,'file') ~= 2
                errorstr = ['Warning: NSB_mapElectrodePosition >> No Channel Localization file: ',chan_loc_file,'. Mapping function terminated and using device generated names.' ];
                if ~isempty(options.logfile)
                    NSBlog(options.logfile,errorstr);
                else
                    errordlg(errorstr,'NSB_mapElectrodePosition');
                end
                return;
            else
                errorstr = ['Infomation: NSB_mapElectrodePosition >> Found and Using Localization file: ',chan_loc_file,'.' ];
                if ~isempty(options.logfile)
                    NSBlog(options.logfile,errorstr);
                else
                    errordlg(errorstr,'NSB_mapElectrodePosition');
                end
            end
        else
            errorstr = ['Infomation: NSB_mapElectrodePosition >> Found and Using Localization file: ',chan_loc_file,'.' ];
            if ~isempty(options.logfile)
                NSBlog(options.logfile,errorstr);
            else
                errordlg(errorstr,'NSB_mapElectrodePosition');
            end
        end
        end
        
        %So by now we should have found the chan_loc_file
        try
            chan_loc_template = load(chan_loc_file);
        catch ME
            errorstr = ['Warning: NSB_mapElectrodePosition >> No Channel Localization file: ',chan_loc_file,'. Mapping function terminated and using device generated names.' ];
            if ~isempty(options.logfile)
                NSBlog(options.logfile,errorstr);
            else
                errordlg(errorstr,'NSB_mapElectrodePosition');
            end
        end
        chan_loc_template = chan_loc_template.chanloc;
        template_XYZ = [chan_loc_template(:).X;chan_loc_template(:).Y;chan_loc_template(:).Z];
        
        %for Mapping purposes remove one only if EEG_XYZ is bigger
        SkippedEEGchans = [];
        if size(EEG_XYZ,2) > size(template_XYZ,2)
            for curloc = 1:2:length(c)
                EEG_XYZ(:,c(curloc)) = [];
                SkippedEEGchans = [SkippedEEGchans c(curloc)];
            end
        else
            %through warning
        end
        for curloc = 1:size(EEG_XYZ,2)
            D = pdist2(EEG_XYZ(:,curloc)', template_XYZ'); %rows = observations
            [trash, IDX] = min(D);
            locationLookup(curloc,:) = [curloc IDX];
        end
        %locationLookup is the concordane between template file and device channels
        if nnz(locationLookup(:,1) == locationLookup(:,2)) / size(EEG_XYZ,2) > 0.8 %<<<<<<<<<<<<<<<<<<Hardcoded
            options.assumeTemplateChOrderCorrect = true;
        else
            options.assumeTemplateChOrderCorrect = false;
        end
        
        %% Plot mappings if requested
        if options.showHeadPlot
            h_fig = figure;
            h1 = plot3(EEG_XYZ(1,:),EEG_XYZ(2,:),EEG_XYZ(3,:),'.b','MarkerSize',20);
            hold on;
            h2 = plot3(template_XYZ(1,:),template_XYZ(2,:),template_XYZ(3,:),'.k','MarkerSize',25);
            plot3(EEG_XYZ(1,Side_IDX),EEG_XYZ(2,Side_IDX),EEG_XYZ(3,Side_IDX),'+c','MarkerSize',20);
            plot3(EEG_XYZ(1,Fpz_IDX),EEG_XYZ(2,Fpz_IDX),EEG_XYZ(3,Fpz_IDX),'+g','MarkerSize',20);
            plot3(EEG_XYZ(1,Cz_IDX),EEG_XYZ(2,Cz_IDX),EEG_XYZ(3,Cz_IDX),'+r','MarkerSize',20);
            xlabel('X-Axis');
            ylabel('Y-Axis');
            zlabel('Z-Axis');
            legend('Scanner 3D Localizations','Template');
            %Save to file
            if ~isempty(options.logfile)
                [logpath, trash1, trash2] = fileparts(options.logfile);
            else
                logpath = cd;
            end
            disp(['NSB_mapElectrodePosition - Saving 3D Localization Plot...']);
            %hgsave(h_fig, fullfile(logpath,['ArtifactFig_',num2str(now),'.fig']), '-v7.3');
            print(h_fig,'-dpdf', fullfile(logpath,['ElectrodePosition_',DataStruct.SubjectID,'.pdf']) );
            close(h_fig);
        end
        
        %% Make Lables
        IDX = 1;
        for curloc = ValidChan_IDX
            if ~isempty(SkippedEEGchans)
                if ismember(DataStruct.Channel(curloc).Number, SkippedEEGchans)
                    DataStruct.Channel(curloc).Valid = false;
                    errorstr = ['Warning: NSB_mapElectrodePosition >> EEG Channel : ',num2str(IDX),' shares a position with another electrode and will be flagged invalid.' ];
                    if ~isempty(options.logfile)
                        NSBlog(options.logfile,errorstr);
                    else
                        errordlg(errorstr,'NSB_mapElectrodePosition');
                    end
                    continue;                                                   %<<<<<<<<THis may not be the best logic
                end
            end
            if options.assumeTemplateChOrderCorrect
                if isempty(REF_IDX)
                    DataStruct.Channel(curloc).Name = chan_loc_template(IDX).labels;
                    DataStruct.Channel(curloc).Ref = [];
                    IDX = IDX +1;
                else
                    Label = [chan_loc_template(IDX).labels, '-', chan_loc_template(REF_IDX).labels];
                    DataStruct.Channel(curloc).Name = Label;
                    DataStruct.Channel(curloc).Ref = REF_IDX;
                    IDX = IDX +1;
                end
            else %use look up table
                if isempty(REF_IDX)
                    DataStruct.Channel(curloc).Name = chan_loc_template(locationLookup(IDX,2)).labels;
                    DataStruct.Channel(curloc).Ref = [];
                    IDX = IDX +1;
                else
                    Label = [chan_loc_template(locationLookup(IDX,2)).labels, '-', chan_loc_template(locationLookup(REF_IDX,2)).labels];
                    DataStruct.Channel(curloc).Name = Label;
                    DataStruct.Channel(curloc).Ref = REF_IDX;
                    IDX = IDX +1;
                end
            end
        end
otherwise
    errorstr = ['ERROR: NSB_mapElectrodePosition >> Filetype not defined'];
    if ~isempty(options.logfile)
        NSBlog(options.logfile,errorstr);
    else
        errordlg(errorstr,'NSB_mapElectrodePosition');
    end
end
%%%



%
%
% %
% switch FileFormat
%     case 'FIFF'
%         EEG_XYZ = []; EEG_REF = [];EEG_IDX = 1;
%         EMG_XYZ = [];EMG_CNTR = 1;
%         for curloc = 1:length(DataStruct.Channel)
%             %test for EEG
%             switch lower(DataStruct.Channel(curloc).Type)
%                 case 'eeg'
%             EEG_XYZ(:,EEG_IDX) = DataStruct.Channel(curloc).Tag.eeg_loc(1:3,1);
%             EEG_REF(:,EEG_IDX) = DataStruct.Channel(curloc).Tag.eeg_loc(1:3,2);
%             EEG_IDX = EEG_IDX +1;
%                 case 'meg'
%                 otherwise
%             end
%             %test for EMG
%         end
%         %calculate center offset and sphere size
%         Diams = abs( min(EEG_XYZ,[],2)) +  abs( max(EEG_XYZ,[],2));
%         Centers = Diams/2 + min(EEG_XYZ,[],2);
%
%
%
%         EEG_XYZ = bsxfun(@minus, EEG_XYZ, Centers); %<< this is still wonkey...
%
%         %Scale to Unit Circle
%         pos3 = bsxfun(@rdivide, pos2, Diams) *2;
%
%                 %Scale to Unit Circle
%         EEG_XYZ = bsxfun(@rdivide, EEG_XYZ, Diams) *2;
% end
%
%
% Coor3d_XYZ = []; EEG_IDX = 1;
% for curloc = 1:length(DataStruct.Coord3D)
%  switch lower(DataStruct.Coord3D(curloc).type)
%   case 'eeg-ecg'
%     Coor3d_XYZ(:,EEG_IDX) = DataStruct.Coord3D(curloc).location(:);
%     EEG_IDX = EEG_IDX +1;
%  end
% end
%
%
%
% %Brute force method
% EEG_XYZ(:,62:end) = [];
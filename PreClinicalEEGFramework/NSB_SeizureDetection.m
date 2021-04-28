function [TrainStruct, status, msg] = NSB_SeizureDetection(Signal, options)
%Seizure Detection module single channel
%extension of multiple channels include coherence
% Detect and remove artifact 1st??
% implement FIR instead of IIR


status = false; msg = [];
MakeFilter = false;
TrainStruct = [];
switch nargin
    case 1
        options.plot = false;
        options.logfile = '';
        options.SampleRate    = 100;  % Sampling Frequency
        options.RMSMultiplier = 2;    % Multiplier for RMS
        options.plotTitle = '';
        
        options.filter.persist = false;  % Make filter persistent
        options.filter.Fstop1 = 4;    % First Stopband Frequency
        options.filter.Fpass1 = 5;    % First Passband Frequency
        options.filter.Fpass2 = 40;   % Second Passband Frequency
        options.filter.Fstop2 = 50;   % Second Stopband Frequency
        options.filter.Astop1 = 50;  % First Stopband Attenuation (dB)
        options.filter.Apass  = 1;    % Passband Ripple (dB)
        options.filter.Astop2 = 50;  % Second Stopband Attenuation (dB)
        
        options.detector.Hzlow = 2;    % in Hz
        options.detector.Hzhigh = 12;   % in Hz
        options.detector.minSpikeInt = 0.05; %in sec
        options.detector.maxSpikeInt = 0.30; %in sec
        options.detector.minTrainDur = 0.5; %in sec
        options.detector.minTrainGap = 1; %in sec
        options.detector.minSpikes = 3; %in sec
        % ?units?
        
    case 2
        %Check relevant options exist
        inputError = false;
        if ~isfield(options,'SampleRate'), options.SampleRate = 100; inputError = true; end
        if ~isfield(options,'RMSMultiplier'), options.RMSMultiplier = 2; inputError = true; end
        if ~isfield(options,'plot'), options.plot = true; inputError = true; end
        if ~isfield(options,'logfile'), options.logfile = ''; inputError = true; end
        if ~isfield(options,'plotTitle'), options.plotTitle = ''; inputError = true; end
        
        if isfield(options,'filter')
            if ~isfield(options.filter,'persist'), options.filter.persist = false; inputError = true; end
            if ~isfield(options.filter,'Fstop1'), options.filter.Fstop1 = 4; inputError = true; end
            if ~isfield(options.filter,'Fpass1'), options.filter.Fpass1 = 5; inputError = true; end
            if ~isfield(options.filter,'Fpass2'), options.filter.Fpass2 = 40; inputError = true; end
            if ~isfield(options.filter,'Fstop2'), options.filter.Fstop2 = 50; inputError = true; end
            if ~isfield(options.filter,'Astop1'), options.filter.Astop1 = 50; inputError = true; end
            if ~isfield(options.filter,'Apass'), options.filter.Apass = 1; inputError = true; end
            if ~isfield(options.filter,'Astop2'), options.filter.Astop2 = 50; inputError = true; end
            if ~isfield(options,'SampleRate'), options.SampleRate = 5; inputError = true; end
        else
            inputError = true;
            options.filter.persist = false;  % Make filter persistent
            options.filter.Fstop1 = 4;    % First Stopband Frequency
            options.filter.Fpass1 = 5;    % First Passband Frequency
            options.filter.Fpass2 = 40;   % Second Passband Frequency
            options.filter.Fstop2 = 50;   % Second Stopband Frequency
            options.filter.Astop1 = 50;  % First Stopband Attenuation (dB)
            options.filter.Apass  = 1;    % Passband Ripple (dB)
            options.filter.Astop2 = 50;  % Second Stopband Attenuation (dB)
        end
        
        if isfield(options,'detector'),
            if ~isfield(options.detector,'Hzlow'), options.detector.Hzlow = 4; inputError = true; end
            if ~isfield(options.detector,'Hzhigh'), options.detector.Hzhigh = 8; inputError = true; end
            if ~isfield(options.detector,'minSpikeInt'), options.detector.minSpikeInt = 0.05; inputError = true; end
            if ~isfield(options.detector,'maxSpikeInt'), options.detector.maxSpikeInt = 0.30; inputError = true; end
            if ~isfield(options.detector,'minTrainDur'), options.detector.minTrainDur = 0.5; inputError = true; end
            if ~isfield(options.detector,'minTrainGap'), options.detector.minTrainGap = 1; inputError = true; end
            if ~isfield(options.detector,'minSpikes'), options.detector.minSpikes = 3; inputError = true; end
        else
            options.detector.Hzlow = 4;
            options.detector.Hzhigh = 8;
            options.detector.minSpikeInt = 0.05; %in sec
            options.detector.maxSpikeInt = 0.30; %in sec
            options.detector.minTrainDur = 0.5; %in sec
            options.detector.minTrainGap = 1; %in sec
            options.detector.minSpikes = 3; %in sec
        end
        
        if inputError
            errorstr = ['Warning: NSB_SeizureDetection >> Missing Options were set to default'];
            if ~isempty(options.logfile)
                NSBlog(options.logfile,errorstr);
            else
                errordlg(errorstr,'NSB_SeizureDetection');
            end
        end
    otherwise
        errorstr = 'ERROR: NSB_SeizureDetection >> Incorrect number of input parameters';
        errordlg(errorstr,'NSB_SeizureDetection');
        return;
end

SampleInt = 1/options.SampleRate;
lowSpikeInt = 1/options.detector.Hzlow/2; %this is 1/2 wave
highSpikeInt = 1/options.detector.Hzhigh/2;%this is 1/2 wave

try

%% HIGH pass filter the data 0.5Hz and up
disp(['NSB_SeizureDetection - Highpass Filtering data ...']);
hpftime = tic;
hp_filter = designfilt('highpassfir',...
    'StopbandFrequency',0.5, ...
    'PassbandFrequency',1.5,'PassbandRipple',0.1, ...
    'StopbandAttenuation',45,'SampleRate', options.SampleRate,...
    'DesignMethod','kaiserwin');
disp(['NSB_SeizureDetection - Designing Highpass Filter ... Finished. ', num2str(toc(hpftime)), ' seconds']);
Signal = filtfilt(hp_filter,Signal);
disp(['NSB_SeizureDetection - Highpass Filtering data ... Finished. ', num2str(toc(hpftime)), ' seconds']);

%% Determine Dynamic threshold for Spike detection
% The issues are that 1)  is that the spikes are in the delta range as well as the theta range and individual spikes can go as high as 10Hz internally
% Therefore there is a difficulty differnetiating SWS from seizure IF the spikes are bipolar
%this has to handle both cases that there is and is not seizure - and be
%robust against differences in the abmount of spike activity.
% and handle sleep and spindles.

%Future iterations should and will need to examine all the channesl at once.

%Detect only max and dropout artifacts
options.Artifacts.algorithm = 'Full -EMG';
options.Artifacts.full.DCcalculation = 'DC';
options.Artifacts.full.DCvalue = 10*rms(Signal);
options.Artifacts.plot = false;
options.Artifacts.IndexedOutput = false;
options.Artifacts.logfile = options.logfile;
[Artifacts, status] = NSB_ArtifactDetection(Signal, options.Artifacts);

%10/13/2016
% remove Artifact (flat and anything over some LARGE Threshold)
FilteredSignal = Signal;
if islogical(Artifacts)
    FilteredSignal(Artifacts) = 0;
elseif isfield(Artifacts,'intStarts')
    %Convert Intervals 2 Logical
    Artifact_IDX = NSB_interval2IDX(Artifacts,length(FilteredSignal),options.SampleRate);
    FilteredSignal(Artifact_IDX) = 0;
    clear Artifact_IDX;
end

hp_filter2 = designfilt('highpassfir',...
    'StopbandFrequency',30, ...
    'PassbandFrequency',35,'PassbandRipple',0.1, ...
    'StopbandAttenuation',80,'SampleRate', options.SampleRate,...
    'DesignMethod','kaiserwin');
gamma = filter(hp_filter2,FilteredSignal); %here we do not care about the filter delay
rms_thresh = rms(gamma);


% Find Positive only Spikes (also could be artifact)
posSpikes = (Signal > rms_thresh*options.RMSMultiplier);
negSpikes = (-Signal > rms_thresh*options.RMSMultiplier);
if nnz(posSpikes) >= nnz(negSpikes)
    Spikes = posSpikes;
    posSpikes = true;       % we will use this for plotting later
    negSpikes = false;
else
    Spikes = negSpikes;
    posSpikes = false;
    negSpikes = true;
end

%get ends of spike and extend to nearest Zero Crossing
SpikeStarts = strfind(char(double(Spikes)'), char([0 1])) +1;
SpikeEnds = strfind(char(double(Spikes)'), char([1 0])) +1;%want to capture data on decending limb

disp(['NSB_SeizureDetection - Extending Spikes to Zero Crossings. ', num2str(length(SpikeEnds)),' events']);
Signal = Signal - mean(Signal(~Spikes));
IDX0 = Signal == 0;
IDXcross = ([Signal(1:end-1) .* Signal(2:end); 0]) < 0;
crossIDX = IDX0 | IDXcross;
%new code rockety fast
counter = 0;
while ~isempty(SpikeStarts)
    counter = counter +1;
    if SpikeStarts(end) + counter > length(SpikeStarts) %test for EOF
        SpikeStarts(end) = [];
    end
    SignDiff = sign(Signal(SpikeStarts + counter)) ~= sign(Signal(SpikeStarts));
    SpikeStarts(SignDiff) = []; %remove crossed IDX's
    Spikes(SpikeStarts + counter) = true;
end
counter = 0;
while ~isempty(SpikeEnds)
    counter = counter +1;
    if SpikeEnds(1) - counter <= 0 %test for BOF
        SpikeEnds(1) = [];
    end
    SignDiff = sign(Signal(SpikeEnds - counter)) ~= sign(Signal(SpikeEnds));
    SpikeEnds(SignDiff) = []; %remove crossed IDX's
    Spikes(SpikeEnds - counter) = true;
end

SpikeStarts = strfind(char(double(Spikes)'), char([0 1])) +1;
SpikeEnds = strfind(char(double(Spikes)'), char([1 0])) +1;%want to capture data on decending limb

if ~isempty(SpikeStarts) && ~isempty(SpikeEnds)
    if SpikeEnds(1) < SpikeStarts(1) && length(SpikeEnds) > length(SpikeStarts) %Check for sstarting trace in Spike train
        SpikeStarts = [1,SpikeStarts];
    elseif SpikeStarts(1) < SpikeEnds(1) && length(SpikeStarts) > length(SpikeEnds)
        SpikeStarts = SpikeStarts(1:length(SpikeEnds));
    end
    
    %dumb code
    SpikeInfo = [];
    for curSpike = 1:length(SpikeStarts)
        %definition of SpikeInfo = peakIDX(:,1) and duration(:,2) << this could be 2 IDX's
        peaks = find( Signal(SpikeStarts(curSpike):SpikeEnds(curSpike)) == max(Signal(SpikeStarts(curSpike):SpikeEnds(curSpike))));
        if ~isempty(peaks)
            SpikeInfo(curSpike,1) = SpikeStarts(curSpike) + peaks(1) -1;
            SpikeInfo(curSpike,2) = (SpikeEnds(curSpike)-SpikeStarts(curSpike)) * SampleInt;
        end
    end
    
    % Find Valid Spikes of correct width (this has to be @ zero Crossing) <<<
    ValidSpikes = (highSpikeInt < SpikeInfo(:,2)) &  (SpikeInfo(:,2) < lowSpikeInt);
    
    ValidSpikeInfo = SpikeInfo(ValidSpikes,:);
    %for those valid spikes get inter-spike interval and whether it is a valid interval
    ValidSpikeInts(:,1) = find(ValidSpikes);
    ValidSpikeInts(:,2) = [diff(ValidSpikeInfo(:,1)) * SampleInt; NaN]; %Get inter spike intervals
    ValidSpikeInts(:,3) = [(diff(ValidSpikeInfo(:,1)) * SampleInt) > options.detector.minSpikeInt &...
        (diff(ValidSpikeInfo(:,1)) * SampleInt) < options.detector.maxSpikeInt; NaN]; %get logical whether this is a valid interval
    
    TrainStarts = (strfind(char(double(ValidSpikeInts(1:end-1,3))'), char([0 1])) +1)';
    TrainEnds = (strfind(char(double(ValidSpikeInts(1:end-1,3))'), char([1 0])) +1)'; %want to capture data on decending limb
    
    if ~isempty(TrainStarts)
        %handle edges
        if ValidSpikeInts(1,3) == 1
            TrainStarts = [1; TrainStarts];
        end
        if ValidSpikeInts(end-1,3) == 1 && TrainStarts(end) > TrainEnds(end)
            TrainEnds = [TrainEnds; size(ValidSpikeInts,1)-1];
        end
        if length(TrainStarts) > length(TrainEnds) && TrainStarts(1) < TrainEnds(1)
            TrainStarts(end) = [];
        elseif length(TrainStarts) < length(TrainEnds) && TrainStarts(1) > TrainEnds(1)
            TrainEnds(1) = [];
        elseif length(TrainStarts) == length(TrainEnds) && TrainStarts(1) > TrainEnds(1)
        end
        TrainStruct.intStarts = SpikeInfo(ValidSpikeInts(TrainStarts,1),1);
        TrainStruct.intEnds = SpikeInfo(ValidSpikeInts(TrainEnds-1,1),1);
        TrainStruct.Spikes = [];
        
        %TrainStarts
        for curSpike = 1:length(TrainStarts)
            %calculate run length (number of spikes)
            if curSpike <= length(SpikeEnds)
                TrainStarts(curSpike,2) = TrainEnds(curSpike) - TrainStarts(curSpike,1);
                TrainStruct.Spikes(curSpike,1) = TrainEnds(curSpike) - TrainStarts(curSpike,1);
            else
                TrainStarts(curSpike,2) = length(ValidSpikeInts(:,2)) - TrainStarts(curSpike,1) +1;
                TrainStruct.Spikes(curSpike,1) = length(ValidSpikeInts(:,2)) - TrainStarts(curSpike,1) +1;
            end
        end
        
        %Try to join trains
        SpikeDistance = TrainStruct.intStarts(2:end) - TrainStruct.intEnds(1:end-1);
        CloseTrainIDX = SpikeDistance <= (options.detector.minTrainGap*options.SampleRate);
        TrainStruct.intEnds([CloseTrainIDX; false]) = [];
        TrainStruct.intStarts([false; CloseTrainIDX]) = [];
        % can break if empty
        for curSpike = length(CloseTrainIDX):-1:1
            if CloseTrainIDX(curSpike)
                TrainStruct.Spikes(curSpike) = TrainStruct.Spikes(curSpike) + TrainStruct.Spikes(curSpike+1);
                TrainStruct.Spikes(curSpike +1) = [];
            end
        end
        
        %Remove too short trains
        BadTrains = TrainStruct.Spikes < options.detector.minSpikes | (TrainStruct.intEnds-TrainStruct.intStarts)*SampleInt < options.detector.minTrainDur;
        TrainStruct.intEnds(BadTrains) = [];
        TrainStruct.intStarts(BadTrains) = [];
        TrainStruct.Spikes(BadTrains) = [];
        
        %convert to seconds (there may be an error and not converting to intergers
        TrainStruct.intStarts = ((TrainStruct.intStarts -1) / options.SampleRate);
        TrainStruct.intEnds = ((TrainStruct.intEnds -1) / options.SampleRate);
        
        TrainStruct.SingleSpikes = ValidSpikeInfo(:,1) / options.SampleRate;
        TrainStruct.SingleSpikeDuration = ValidSpikeInfo(:,2) / options.SampleRate;
    else
        TrainStruct.intStarts = [];
        TrainStruct.intEnds = [];
        TrainStruct.SingleSpikes = [];
        TrainStruct.SingleSpikeDuration = [];
    end
else
    TrainStruct.intStarts = [];
    TrainStruct.intEnds = [];
    TrainStruct.SingleSpikes = [];
    TrainStruct.SingleSpikeDuration = [];
end

if ~isfield(TrainStruct,'Spikes')
    TrainStruct.Spikes = 0;
end


TrainStruct.plot = '';
if options.plot
    disp(['NSB_SeizureDetection - Generating Seizure Detection Plot...']);
    h_spike = []; h_train = [];  
    ds_ValidSpikeInfo(:,1) = ValidSpikeInfo(:,1)/options.SampleRate;
    ds_ValidSpikeInfo(:,2) = ValidSpikeInfo(:,2);

    if length(Signal) > 10000
        reduceSample = true;
        %downsample to 50 Hz
        SR_ratio = floor(options.SampleRate/50);
        Signal = downsample(Signal,SR_ratio); %NOTE << this aliases the data. for antialias downsample the filtered (50Hz) data
        gamma = downsample(gamma,SR_ratio);
        options.SampleRate = 50;
    else
        reduceSample = false;
    end
    ts = (1:length(Signal))/options.SampleRate; %seconds

    h_fig = figure; hold on;
    h_plot = plot(ts, Signal,'color',[0.5,0.5,0.9]); %scales between [0:1]
    plot(ts, gamma,'color',[0.7,0.7,0.9]);
    %plot(ts,abs(HilbertSig),'r');
    if posSpikes
        h_rms = line([0,ts(end)],[rms_thresh,rms_thresh],'Color','c');
        h_rmsMult = line([0,ts(end)],[rms_thresh*options.RMSMultiplier,rms_thresh*options.RMSMultiplier],'Color','m');
        try
            y = ones(size(ds_ValidSpikeInfo,1),1)* rms_thresh*options.RMSMultiplier+options.RMSMultiplier;
            h_spike = scatter(ds_ValidSpikeInfo(:,1),y,10,'r','v','filled');
            h_train = line([TrainStruct.intStarts, TrainStruct.intEnds],[rms_thresh*options.RMSMultiplier,rms_thresh*options.RMSMultiplier],'Color','k','LineWidth',8);
            % Scattergram for smaller data size
            % h_spike = line([ds_ValidSpikeInfo(:,1)-ds_ValidSpikeInfo(:,2),ds_ValidSpikeInfo(:,1)+ds_ValidSpikeInfo(:,2)],[rms*options.RMSMultiplier+options.RMSMultiplier,rms*options.RMSMultiplier+options.RMSMultiplier],'Color','r','LineWidth',2);
            

        end
    elseif negSpikes
        h_rms = line([0,ts(end)],[-rms_thresh,-rms_thresh],'Color','c');
        h_rmsMult = line([0,ts(end)],[-rms_thresh*options.RMSMultiplier,-rms_thresh*options.RMSMultiplier],'Color','m');
        try
            y = ones(size(ds_ValidSpikeInfo,1),1)* -rms_thresh*options.RMSMultiplier-options.RMSMultiplier;
            h_spike = scatter(ds_ValidSpikeInfo(:,1),y,10,'r','^','filled');
            h_train = line([TrainStruct.intStarts, TrainStruct.intEnds],[-rms_thresh*options.RMSMultiplier,-rms_thresh*options.RMSMultiplier],'Color','k','LineWidth',8);
            % Scattergram for smaller data size
            % h_spike = line([ds_ValidSpikeInfo(:,1)-ds_ValidSpikeInfo(:,2),ds_ValidSpikeInfo(:,1)+ds_ValidSpikeInfo(:,2)],[rms*options.RMSMultiplier+options.RMSMultiplier,rms*options.RMSMultiplier+options.RMSMultiplier],'Color','r','LineWidth',2);
        end 
    else
        h_rms = line([0,ts(end)],[rms_thresh,rms_thresh],'Color','c');
        h_rmsMult = line([0,ts(end)],[rms_thresh*options.RMSMultiplier,rms_thresh*options.RMSMultiplier],'Color','m');
        try
            y = ones(size(ds_ValidSpikeInfo,1),1)* rms_thresh*options.RMSMultiplier+options.RMSMultiplier;
            h_spike = scatter(ds_ValidSpikeInfo(:,1),y,10,'r','v','filled');
            h_train = line([TrainStruct.intStarts, TrainStruct.intEnds],[rms_thresh*options.RMSMultiplier,rms_thresh*options.RMSMultiplier],'Color','k','LineWidth',8);
            % Scattergram for smaller data size
            % h_spike = line([ds_ValidSpikeInfo(:,1)-ds_ValidSpikeInfo(:,2),ds_ValidSpikeInfo(:,1)+ds_ValidSpikeInfo(:,2)],[rms*options.RMSMultiplier+options.RMSMultiplier,rms*options.RMSMultiplier+options.RMSMultiplier],'Color','r','LineWidth',2);
        end
    end
        
    %here scale this
    set(get(h_fig,'CurrentAxes'),'YLim',[-rms_thresh*options.RMSMultiplier*4 rms_thresh*options.RMSMultiplier*4])
    
    title(options.plotTitle,'FontWeight','bold','Interpreter', 'none');
    ylabel('Signal');
    xlabel('Seconds');
    if ~isempty(h_train)
        legend([h_plot,h_rms,h_rmsMult,h_spike(1),h_train(1)],'Signal','RMS','RMS*multiplier','Spikes','Spike Train');
    elseif ~isempty(h_spike)
        legend([h_plot,h_rms,h_rmsMult,h_spike(1)],'Signal','RMS','RMS*multiplier','Spikes');
    else
       legend('Signal','RMS','RMS*multiplier'); 
    end
    %legend('Signal','Sig. Envelope','RMS','RMS*multiplier','Spikes');
    set(get(h_fig,'CurrentAxes'),'XMinorTick','on')
    if ~isempty(options.logfile)
        [logpath, trash1, trash2] = fileparts(options.logfile);
    else
        logpath = cd;
    end
    
    if exist(logpath, 'dir') ~= 7
        mkdir(logpath);
    end
    disp(['NSB_SeizureDetection - Saving Seizure Detection PDF...']);
    filename = fullfile(logpath,['SeizureDetectionFig_',num2str(now),'.pdf']);
    print(h_fig,'-dpdf', filename );
    %Generating figures is only important for QAQC
%     disp(['NSB_SeizureDetection - Saving Seizure Detection FIG...']);
%     try 
%         savefig(h_fig, fullfile(logpath,['SeizureDetectionFig_',num2str(now),'.fig']),'compact');
%     catch
%         hgsave(h_fig, fullfile(logpath,['SeizureDetectionFig_',num2str(now),'.fig']), '-v7.3');
%     end
%     disp(['NSB_SeizureDetection - Saving Seizure Detection PNG...']);
%     filename = fullfile(logpath,['SeizureDetectionFig_',num2str(now),'.png']);
%     print(h_fig,'-dpng',filename );
    close(h_fig);
    TrainStruct.plot = filename;
end

catch msg
    errorstr = ['ERROR: NSB_SeizureDetection >> ', msg.message,' on line: ',num2str(msg.stack(1).line)];
    if ~isempty(options.logfile)
        NSBlog(options.logfile,errorstr);
    end
    disp(errorstr);
    msg = errorstr;
end
status = true;


%% other things to ehink about
%absolute/dynamic threshold of data (1  min prior)
%min/max spike duration (but define in Hz)

%Spike train
%min/max interval between spikes (define in Hz



%train Join

%min spikes in train



%As differnt possibilities
%timeseries detection



%Frequency domain analysis

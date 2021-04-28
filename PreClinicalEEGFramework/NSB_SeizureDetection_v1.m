function [TrainStruct, status] = NSB_SeizureDetection(Signal, options)
%Seizure Detection module single channel
%extension of multiple channels include coherence
% Detect and remove artifact 1st??
% implement FIR instead of IIR


status = false;
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
        
        if isfield(options,'filter'),
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

%% 1st remove artifact
if islogical(options.Artifacts)
    Signal(options.Artifacts) = 0;
elseif isfield(options.Artifacts,'intStarts')
    %Convert Intervals 2 Logical
    Artifact_IDX = NSB_interval2IDX(options.Artifacts,length(Signal),options.SampleRate);
    Signal(Artifact_IDX) = 0;
    clear Artifact_IDX;
end

%band pass data 5-50 Hz
%IIR Method
% if options.filter.persist
%     persistent BandPassOBJ;
% end
% if ~exist('BandPass','var')
%     MakeFilter = true;
% elseif isempty(BandPassOBJ)
%     MakeFilter = true;
% end
% if MakeFilter
%     %design bandpass filter for sample rate
%     filterOBJ = fdesign.bandpass('fst1,fp1,fp2,fst2,ast1,ap,ast2', options.filter.Fstop1, options.filter.Fpass1, ...
%         options.filter.Fpass2, options.filter.Fstop2, options.filter.Astop1, options.filter.Apass,...
%         options.filter.Astop2, options.SampleRate);
%
%     if NSB_Check4Toolbox('DSP System Toolbox')
%     BandPassOBJ = design(filterOBJ, 'butter', ...
%         'FilterStructure', 'df2tsos', ...
%         'MatchExactly', 'stopband', ...
%         'SOSScaleNorm', 'Linf');
%     else
%         BandPassOBJ = design(filterOBJ, 'butter', ...
%          'FilterStructure', 'df2tsos', ...
%          'MatchExactly', 'stopband');
%     end
%
%     if options.filter.persist
%     set(BandPassOBJ,'PersistentMemory',true);
%     end
% end
% Signal = filtfilt(BandPassOBJ.sosMatrix,BandPassOBJ.ScaleValues,Signal); %zero Phase filter

% %Do initial artifact detection
% %make this an option
% %version 1
% pDensity = hist(abs(Signal),max(abs(Signal)));
% warning off;
% hGap = strfind(char(pDensity),[char(0),char(0),char(0)]);
% warning on;
% if ~isempty(hGap)
%     rms = hGap(1);
% else
%     zeroIDX = Signal == 0;
%     tempSig = Signal.^2;
%     rms = sqrt( mean(tempSig(~zeroIDX))) *options.RMSMultiplier;
%     clear tempSig;
% end
% Spikes = (Signal > rms) | (Signal < -rms);
% Signal(Spikes) = 0;
%
% %FIR method
% flag = 'scale';  % Sampling Flag
% % Create the window vector for the design algorithm.
% win = barthannwin(options.SampleRate+1);
% % Calculate the coefficients using the FIR1 function.
% disp(['NSB_SeizureDetection - Filtering data.']);
% b  = fir1(options.SampleRate, [options.filter.Fpass1 options.filter.Fpass2]/(options.SampleRate/2), 'bandpass', win, flag);
% Signal = filtfilt(b,1,Signal);
%
% % %Generate Envelope and Envelope RMS twice as double thresholding
% % HilbertSig = hilbert(Signal);
% % rms = sqrt( mean( abs(HilbertSig).*abs(HilbertSig)));
% % Spikes = (Signal > rms*options.RMSMultiplier) | ...
% %             (Signal < -rms*options.RMSMultiplier);
% % rms = sqrt(mean(Signal(~Spikes).*Signal(~Spikes)));
%
% zeroIDX = Signal == 0;
% tempSig = Signal.^2;
% rms = sqrt(mean(tempSig(~zeroIDX)));
% clear tempSig;



%version 2
flag = 'scale';  % Sampling Flag
% Create the window vector for the design algorithm.
win = barthannwin(options.SampleRate+1);
% Calculate the coefficients using the FIR1 function.
disp(['NSB_SeizureDetection - Filtering data.']);
b  = fir1(options.SampleRate, [0.5 4]/(options.SampleRate/2), 'bandpass', win, flag);
delta = filter(b,1,Signal); %here we do not care about the filter delay
maxDelta = max(abs(delta));
rmsScale = 1;

if maxDelta < 1e5 %This is to prevent overflow
    if maxDelta < 1
        delta = delta *100;
        rmsScale = 100;
    elseif maxDelta < 10
        delta = delta *10;
        rmsScale = 10;
    end
    pDensity = hist(abs(delta),ceil(max(abs(delta))));
else
    pDensity = hist(abs(delta (delta > -1e5 & delta < 1e5) ),1e5);
end

pDensity(pDensity < 2) = 0;
warning off;
hGap = strfind(char(pDensity),[char(0),char(0),char(0)]);
warning on;
if ~isempty(hGap)
    rms = hGap(1); %not really RMS jus a threshold here
    delta((delta > rms) | (delta < -rms)) = 0;
end
rms = sqrt(mean(delta(delta ~= 0).^2)) / rmsScale;
clear delta;

% Find Positive only Spikes (also could be artifact)
posSpikes = (Signal > rms*options.RMSMultiplier);
negSpikes = (-Signal > rms*options.RMSMultiplier);
if nnz(posSpikes) >= nnz(negSpikes)
    Spikes = posSpikes;
    posSpikes = true;       % we will use this for plotting later
    negSpikes = false;
else
    Spikes = negSpikes;
    posSpikes = false;
    negSpikes = true;
end

%get ends of artifact and extend to nearest Zero Crossing
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
    %for those valid spikes get inter-spike interval and whether it is a avlid interval
    ValidSpikeInts(:,1) = find(ValidSpikes);
    ValidSpikeInts(:,2) = [diff(ValidSpikeInfo(:,1)) * SampleInt; NaN]; %Get inter spike intervals
    ValidSpikeInts(:,3) = [(diff(ValidSpikeInfo(:,1)) * SampleInt) > options.detector.minSpikeInt &...
        (diff(ValidSpikeInfo(:,1)) * SampleInt) < options.detector.maxSpikeInt; NaN]; %get logical whether this is a valid interval
    
    TrainStarts = (strfind(char(double(ValidSpikeInts(1:end-1,3))'), char([0 1])) +1)';
    TrainEnds = (strfind(char(double(ValidSpikeInts(1:end-1,3))'), char([1 0])) +1)'; %want to capture data on decending limb
    
    if ~isempty(TrainStarts)
        if length(TrainStarts) > length(TrainEnds) && TrainStarts(1) < TrainEnds(1)
            TrainStarts(end) = [];
        elseif length(TrainStarts) < length(TrainEnds) && TrainStarts(1) > TrainEnds(1)
            TrainEnds(1) = [];
        end
        TrainStruct.intStarts = SpikeInfo(ValidSpikeInts(TrainStarts,1),1);
        TrainStruct.intEnds = SpikeInfo(ValidSpikeInts(TrainEnds-1,1),1);
        TrainStruct.Spikes = [];
        
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
    else
        TrainStruct.intStarts = [];
        TrainStruct.intEnds = [];
    end
else
    TrainStruct.intStarts = [];
    TrainStruct.intEnds = [];
end

if ~isfield(TrainStruct,'Spikes')
    TrainStruct.Spikes = 0;
end


TrainStruct.plot = '';
if options.plot
    ts = (1:length(Signal))/options.SampleRate; %seconds
    disp(['NSB_SeizureDetection - Generating Seizure Detection Plot...']);
    if length(Signal) > 10000
        reduceSample = true;
    else
        reduceSample = false;
    end
    h_fig = figure; hold on;
    h_plot = plot(ts, Signal,'m'); %scales between [0:1]
    %plot(ts,abs(HilbertSig),'r');
    if posSpikes
        line([0,ts(end)],[rms,rms],'Color','c');
        line([0,ts(end)],[rms*options.RMSMultiplier,rms*options.RMSMultiplier],'Color','b');
        try
            line([TrainStruct.intStarts, TrainStruct.intEnds],[rms*options.RMSMultiplier,rms*options.RMSMultiplier],'Color','k','LineWidth',8);
        end
    elseif negSpikes
        line([0,ts(end)],[-rms,-rms],'Color','c');
        line([0,ts(end)],[-rms*options.RMSMultiplier,-rms*options.RMSMultiplier],'Color','b');
        try
            line([TrainStruct.intStarts, TrainStruct.intEnds],[-rms*options.RMSMultiplier,-rms*options.RMSMultiplier],'Color','k','LineWidth',8);
        end
        
        
    else
        line([0,ts(end)],[rms,rms],'Color','c');
        line([0,ts(end)],[rms*options.RMSMultiplier,rms*options.RMSMultiplier],'Color','b');
        try
            line([TrainStruct.intStarts, TrainStruct.intEnds],[rms*options.RMSMultiplier,rms*options.RMSMultiplier],'Color','k','LineWidth',8);
        end
    end
        
    %here scale this
    set(get(h_fig,'CurrentAxes'),'YLim',[-rms*options.RMSMultiplier*4 rms*options.RMSMultiplier*4])
    
    title(options.plotTitle,'FontWeight','bold','Interpreter', 'none');
    ylabel('Signal');
    xlabel('Seconds');
    legend('Signal','RMS','RMS*multiplier','Spike Train');
    %legend('Signal','Sig. Envelope','RMS','RMS*multiplier','Spikes');
    set(get(h_fig,'CurrentAxes'),'XMinorTick','on')
    if ~isempty(options.logfile)
        [logpath, trash1, trash2] = fileparts(options.logfile);
    else
        logpath = cd;
    end
    disp(['NSB_SeizureDetection - Saving Seizure Detection Plot...']);
    %hgsave(h_fig, fullfile(logpath,['SeizureDetectionFig_',num2str(now),'.fig']), '-v7.3');
    print(h_fig,'-dpdf', fullfile(logpath,['SeizureDetectionFig_',num2str(now),'.pdf']) );
    
    filename = fullfile(logpath,['SeizureDetectionFig_',num2str(now),'.png']);
    print(h_fig,'-dpng',filename );
    close(h_fig);
    TrainStruct.plot = filename;
end


%absolute/dynamic threshold of data (1  min prior)
%min/max spike duration (but define in Hz)

%Spike train
%min/max interval between spikes (define in Hz



%train Join

%min spikes in train



%As differnt possibilities
%timeseries detection



%Frequency domain analysis
status = true;
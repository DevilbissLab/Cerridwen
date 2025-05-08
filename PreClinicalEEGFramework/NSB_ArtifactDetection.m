function [Artifacts, status] = NSB_ArtifactDetection(Signal, options)
% NSB_ArtifactDetection() - Detect artifacts in Single EEG channel
%
% Inputs:
%   Signal            - (double) continuous time signal
%   options           - (struct) of options
%                           (double)    options.SampleRate
%                           (logical)   options.IndexedOutput (assign logical or index output)
%                           (string)    options.algorithm (specify which processing algorithm
%                                       'DC' - use a simple DC threshold
%                                       'RMS' - use the rms of the signal as the simple DC threshold
%                                       'FULL' - fully process signal using several simultaneous approaches
%                           (string)    options.logfile (file path and name)
%                           (double)    options.DCvalue (simple DC threshold value - mV)
%                           (double)    options.RMSMultiplier (multiply RMS value by this number for simple DC threshold)
%                           (logical)   options.rm2Zero (expand artifacts to zero crossings)
%                           (logical)   options.plot (turn on plotting)
%                           (logical)   options.plotTitle (plot title)
%                           (string)    options.full.DCcalculation (when using 'FULL' type processing, use a 'DC' or 'scaled' simple DC threshold)            
%                           (double)    options.full.DCvalue (simple DC threshold value - mV)
%                           (double)    options.full.STDMultiplier (multiply 'scaled' detection by this number for simple DC threshold)
%                           (double)    options.full.minFlatSigLength (Min time in Seconds permitted for signal to be flat)
%                           (double)    options.full.dvValMultiplier (scaline for change in time (samples)) that it takes signal to artifact)
%                           (double)    options.full.MaxDT (Maximum duration (change in time (samples)) that it takes signal to artifact)
%                           (double)    options.full.MinArtifactDuration (In Seconds. All artifacts must have at least this length)
%                           (double)    options.full.CombineArtifactTimeThreshold (in Seconds. Combine artifacts that occur less than this time window)
%
% Outputs:
%   Artifacts           - (Context Dependent !!) Logical vector of Artifacts if
%                                                   options.IndexedOutput = false, Struct of Start time/ End Time values
%                                                   (in seconds) if options.IndexedOutput = true
%   status              - (logical) return value
%
% See also:
%   "Muscle Artifacts in the sleep EEG: Automated detection and effect on
%            all-night EEG power spectra." J. Sleep Res. (1996) 5. 155-164
%
% Dependencies: 
% NSBlog
%
% ToDo: add as option, EMG channel
% ToDo: add on the fly DC limit changes
% ToDo: Send to powerpoint.
% 
%
% Written By David M. Devilbiss
% NexStep Biomarkers, LLC. (info@nexstepbiomarkers.com)
% December 8 2011, Version 1.0

status = false;
Signal = Signal(:);
Artifacts = [];
switch nargin
    case 1
        %use default parameters
        options.SampleRate = 100;
        options.IndexedOutput = true;
        options.algorithm = 'FULL';
        options.logfile = '';
        options.DCvalue = 100; %mV DC hard limit
        options.RMSMultiplier = 3; %Detect > X times RMS;(Default 5)
        options.rm2Zero = true;
        options.plot = true;
        options.plotTitle = '';
        options.full.DCcalculation = 'scaled'; %mv (DC hard limit) or std calculation
        options.full.DCvalue = 100; %mV DC hard limit
        options.full.STDMultiplier = 3; %Detect > X times Standard deviations.
        options.full.minFlatSigLength = 0.1; %Seconds.
        options.full.dvValMultiplier = .8; %Original 0.45%Jump DC limit as a function of: dvValMultiplier*DClimitValue or std(signal) << this wants to be a fraction of DC Threshold
        options.full.MaxDT = 4; %Maximum duration (change in time (samples)) that it takes signal to artifact
        options.full.MinArtifactDuration = 0.25; % in seconds >>>  code will expand all artifacts to have at least this length
        options.full.CombineArtifactTimeThreshold = 0.2; %in Seconds. Combine artifacts that occur less than this time window
        options.full.MuscleArtifactMultiplier = 3; %gain for EMGThreshold as a function of options.full.STDMultiplier * options.full.dvValMultiplier + medFiltData *3;
    case 2
        %Check relevant options exist
        inputError = false;
        if ~isfield(options,'SampleRate'), options.SampleRate = 100;inputError = true; end
        if ~isfield(options,'IndexedOutput'), options.IndexedOutput = true;inputError = true; end
        if ~isfield(options,'algorithm'), options.algorithm = 'FULL';inputError = true; end
        if ~isfield(options,'logfile'), options.logfile = '';inputError = true; end
        if ~isfield(options,'DCvalue'), options.DCvalue = 100;inputError = true; end
        if ~isfield(options,'RMSMultiplier'), options.RMSMultiplier = 3;inputError = true; 
            else, if sign(options.RMSMultiplier) == -1, options.RMSMultiplier = abs(options.RMSMultiplier); end;
            end
        if ~isfield(options,'rm2Zero'), options.rm2Zero = true;inputError = true; end
        if ~isfield(options,'plot'), options.plot = true;inputError = true; end
        if ~isfield(options,'plotTitle'), options.plotTitle = '';inputError = true; end
        if ~isfield(options,'full'),options.full.DCvalue = 100;inputError = true; end %Create .full structure and fill with default.
        if ~isfield(options.full,'DCcalculation'), options.full.DCcalculation = 'scaled';inputError = true; end
        if ~isfield(options.full,'DCvalue'), options.full.DCvalue = 100;inputError = true;
            else, if sign(options.DCvalue) == -1, options.DCvalue = abs(options.DCvalue); end;
            end
        if ~isfield(options.full,'STDMultiplier'), options.full.STDMultiplier = 3;inputError = true;
            else, if sign(options.full.STDMultiplier) == -1, options.full.STDMultiplier = abs(options.full.STDMultiplier); end;
            end
        if ~isfield(options.full,'minFlatSigLength'), options.full.minFlatSigLength = 0.1;inputError = true; end
        if ~isfield(options.full,'dvValMultiplier'), options.full.dvValMultiplier = .8;inputError = true; end
        if ~isfield(options.full,'MaxDT'), options.full.MaxDT = 4;inputError = true; end
        if ~isfield(options.full,'MinArtifactDuration'), options.full.MinArtifactDuration = 0.25;inputError = true; end
        if ~isfield(options.full,'CombineArtifactTimeThreshold'), options.full.CombineArtifactTimeThreshold = 0.2;inputError = true; end
        if ~isfield(options.full,'MuscleArtifactMultiplier'), options.full.MuscleArtifactMultiplier = 3;inputError = true; end
        if inputError
        errorstr = ['Warning: NSB_ArtifactDetection >> Missing Options were set to default'];
        if ~isempty(options.logfile)
            NSBlog(options.logfile,errorstr);
        else
            errordlg(errorstr,'NSB_ArtifactDetection');
        end
        end
    otherwise
        errorstr = 'ERROR: NSB_ArtifactDetection >> Incorrect number of input parameters';
        errordlg(errorstr,'NSB_EDFreader');
        return;
end

SignalLength = length(Signal);
disp('NSB_ArtifactDetection - Running...');
% run artifact detection
switch upper(options.algorithm)
    case 'RMS'
        %find RMS of data
        NaNIDX = find(~isnan(Signal));
        rms = sqrt(mean(Signal(NaNIDX).*Signal(NaNIDX)));
        Artifacts = (Signal > rms*options.RMSMultiplier) | ...
            (Signal < -rms*options.RMSMultiplier);

        errorstr = ['Info: NSB_ArtifactDetection:RMS Detection - RMSMultiplier = ',options.RMSMultiplier, '(',rms*options.RMSMultiplier,' mV)'];
        if ~isempty(options.logfile)
           NSBlog(options.logfile,errorstr);
        end

    case 'DC'
        %% determine the positions where signal is above DC Threshold
        Artifacts = (Signal > options.DCvalue) | ...
            (Signal < -options.DCvalue);

        errorstr = ['Info: NSB_ArtifactDetection:DC Detection - DCvalue = ',options.DCvalue, '(mV)'];
        if ~isempty(options.logfile)
           NSBlog(options.logfile,errorstr);
        end

    case {'FULL','FULL -EMG'}
        %% determine the positions where signal is above DC Threshold
        %get indicies of extreme values
        try
            switch lower(options.full.DCcalculation)
                case 'scaled'
                    %find RMS of valid data (isNAN)
                    NaNIDX = find(~isnan(Signal));
                    rms = sqrt(mean(Signal(NaNIDX).*Signal(NaNIDX)));
                    %step 1 - remove 'bad' data <> of RMS * multiplier
                    IDX = (Signal > rms*options.RMSMultiplier) | ...
                        (Signal < -rms*options.RMSMultiplier);
                    nanSignal = Signal;
                    nanSignal(IDX) = NaN;
                    %step 2 - 
                    SigBuff = buffer(abs(nanSignal),double(round(options.SampleRate/2)));% buffer will fail if data is empty
                    clear nanSignal;
                    BuffMax = max(SigBuff);
                    clear SigBuff;
                    %step 3 -
                    DCThresh = (max(BuffMax)-min(BuffMax)) * options.full.STDMultiplier;
                    %step 4 - 
                    if DCThresh < min(BuffMax)*2  %deal with sig's with no artifact
                        DCThresh = min(BuffMax)*2;
                        errorstr = ['Warning: NSB_ArtifactDetection >> DCThresh < min(BuffMax)*2. Using ',num2str(DCThresh),' as threshold calculated as min(BuffMax)*2.'];
                        if ~isempty(options.logfile)
                            NSBlog(options.logfile,errorstr);
                        else
                            errordlg(errorstr,'NSB_ArtifactDetection');
                        end
                    end
                    ExtremeSignalIDX = abs(Signal) >=  DCThresh;

                    errorstr = ['Info: NSB_ArtifactDetection:Full(Scaled) - STDMultiplier = ',options.full.STDMultiplier, '(',DCThresh,' mV)'];
                    if ~isempty(options.logfile)
                        NSBlog(options.logfile,errorstr);
                    end
                    
                otherwise %use DC thresh
                    DCThresh = options.full.DCvalue;
                    ExtremeSignalIDX = abs(Signal) >=  DCThresh;

                    errorstr = ['Info: NSB_ArtifactDetection:Full(DCvalue) - DCvalue = ',options.full.DCvalue, '(mV)'];
                    if ~isempty(options.logfile)
                        NSBlog(options.logfile,errorstr);
                    end
            end
            
            
            
            %% drop out detection
            % find segments of dropout or "railed" saturated
            
            minFlatSigLength = ceil(options.full.minFlatSigLength * options.SampleRate);
            FlatSignalIDX = diff(Signal) == 0;
            FlatSignalIDX = [FlatSignalIDX; 1] | [1; FlatSignalIDX];
            %check for min length of flat segment
            %Determine segment length using  DMD's ubiquitous char trick
            FlatIDX = strfind(char(double(FlatSignalIDX')),char(ones(1,minFlatSigLength))); %IDX of > DropoutDT
            
            if ~isempty(FlatIDX)
                dropoutIndex = false(size(Signal));
                dropoutIndex(FlatIDX) = true;
                dropoutIndex = conv(single(dropoutIndex),ones(1,minFlatSigLength-1)) > 0; %<< check math single could be used here to cheat rounding errors see 'eps'
                FlatSignalIDX = dropoutIndex(1:end-(minFlatSigLength-2));
            else
                FlatSignalIDX = false(size(FlatSignalIDX,1),1);
            end
            
            %% find artifacts that excede dv/dt limit
            % generate devalued DCthreshold used for electrical noise detection (crunchies)
            %  this may want to be more dynamic
            dvValue = options.full.dvValMultiplier * DCThresh;
            
            % get a logical IDX for dv/dt > threshold
            dvArtifactIndex = false(size(Signal));
            
            %An attempt at the filter. Much more sensitive approach
            %incorporated a discounting function for higher dt's
            for dt = 2:options.full.MaxDT
                dvDeValued = dvValue + (dt/options.full.MaxDT * dvValue);
                dvArtifactIndex = dvArtifactIndex | abs(Signal - [Signal(dt:1:end);zeros(dt-1,1)]) >= dvDeValued;
            end
            
            if strcmpi(options.algorithm,'FULL')
            %% Muscle artifacts detection
            %note: this is only calculated for EEG, but could additionally use EMG and
            %corelation between the two signals.
            %
            % see: "Muscle Artifacts in the sleep EEG: Automated detection and effect on
            % all-night EEG power spectra." J. Sleep Res. (1996) 5. 155-164
            %
            %First Clean Large artifacts because you are going to use a median
            FiltData = Signal;
            FiltData(ExtremeSignalIDX) = 0;
            %First High Pass data
            %get optimal filter order
            [N, Fo, Ao, W] = firpmord([32, 40]/(options.SampleRate/2),[1 0],[0.01 0.001]);
            %design filter
            b  = firpm(N, Fo, Ao, W, {20}); %could increase lgrid to 32
            FiltData = abs(filtfilt(b,1,FiltData)); %<< biggest time sinc of the function
            
            %low pass this poisson signal (i.e. smoothing < 4Hz)
            [N, Fo, Ao, W] = firpmord([4, 8]/(options.SampleRate/2),[1 0],[0.01 0.001]);
            b  = firpm(N, Fo, Ao, W, {20}); %could increase lgrid to 32
            FiltData = abs(filtfilt(b,1,FiltData)); %<< biggest time sinc of the function
            medFiltData = median(FiltData); %for a more acrate baseline try buffering as above or just eliminating found artifacts so far
            FiltData = abs(abs(Signal) - FiltData);
            
            EMGThreshold = (1/options.full.STDMultiplier) * options.full.dvValMultiplier + medFiltData *options.full.MuscleArtifactMultiplier;
            %EMGThreshold = options.full.dvValMultiplier * medFiltData *3; %<< DMD added x3
            EMGArtifactIndex = FiltData > EMGThreshold;
            else
                EMGArtifactIndex = false(size(Signal));
            end
            
            %% Join Artifact indicies and create Struct
            Artifacts = ExtremeSignalIDX | FlatSignalIDX | dvArtifactIndex | EMGArtifactIndex;
            
        catch ME
            Artifacts = false(size(Signal));
            errorstr = ['Warning: NSB_ArtifactDetection >> Error in "Full" Threshold Detection. ' ME.message];
            if ~isempty(options.logfile)
                NSBlog(options.logfile,errorstr);
            else
                errordlg(errorstr,'NSB_ArtifactDetection');
            end
        end
        
    otherwise
        Artifacts = false(length(Signal),1);
        errorstr = ['Warning: NSB_ArtifactDetection >> No Artifact Detection Performed'];
        if ~isempty(options.logfile)
            NSBlog(options.logfile,errorstr);
        else
            errordlg(errorstr,'NSB_ArtifactDetection');
        end
end


%% Remove extend artifact it to EEG zero crossings
if options.rm2Zero
    %check to see if mean needs to be removed
    if mean(Signal) ~= 0
        rm2ZeroData = Signal .* ~Artifacts;
        rm2ZeroData = detrend(rm2ZeroData,'constant');
    else
        rm2ZeroData = Signal;
    end
    IDX0 = rm2ZeroData == 0;
    IDXcross = ([rm2ZeroData(1:end-1) .* rm2ZeroData(2:end); 0]) < 0;
    
    crossIDX = IDX0 | IDXcross;
    
    %get ends of artifact and extend to nearest Zero Crossing
    ArtifactStarts = strfind(char(double(Artifacts)'), char([0 1])) +1;
    ArtifactEnds = strfind(char(double(Artifacts)'), char([1 0]));
    disp(['Info: NSB_ArtifactDetection - Extending Artifacts to Zero Crossings. ', num2str(length(ArtifactEnds)),' events']);
    %new code rockety fast
    counter = 0;
    while ~isempty(ArtifactStarts)
        counter = counter +1;
        if ArtifactStarts(end) + counter > length(ArtifactStarts) %test for EOF
            ArtifactStarts(end) = [];
        end
        SignDiff = sign(rm2ZeroData(ArtifactStarts + counter)) ~= sign(rm2ZeroData(ArtifactStarts));
        ArtifactStarts(SignDiff) = []; %remove crossed IDX's
        Artifacts(ArtifactStarts + counter) = true;
    end
    counter = 0;
    while ~isempty(ArtifactEnds)
        counter = counter +1;
        if ArtifactEnds(1) - counter <= 0 %test for BOF
            ArtifactEnds(1) = [];
        end
        SignDiff = sign(rm2ZeroData(ArtifactEnds - counter)) ~= sign(rm2ZeroData(ArtifactEnds));
        ArtifactEnds(SignDiff) = []; %remove crossed IDX's
        Artifacts(ArtifactEnds - counter) = true;
    end
    
%     for curArtifact = 1:length(ArtifactEnds)
%         Next0Cross = find(crossIDX(ArtifactEnds(curArtifact):end),1,'first') + ArtifactEnds(curArtifact) -1;
%         Artifacts(ArtifactEnds(curArtifact):Next0Cross) = true; %extend the artifact forward time
%     end
%     for curArtifact = 1:length(ArtifactStarts)
%         Next0Cross = ArtifactStarts(curArtifact) - find(crossIDX(ArtifactStarts(curArtifact):-1:1),1,'first') +1;
%         Artifacts(Next0Cross:ArtifactStarts(curArtifact)) = true; %extend the artifact
%     end
end

%report on artifact detection
percentArtifact = nnz(Artifacts)/length(Artifacts)*100;
errorstr = ['Information: NSB_ArtifactDetection >> ',num2str(percentArtifact), '% of file marked as artifact'];
if ~isempty(options.logfile)
    NSBlog(options.logfile,errorstr);
else
    errordlg(errorstr,'NSB_ArtifactDetection');
end

%% Plot Artifacts

if options.plot
    disp(['Info: NSB_ArtifactDetection - Generating Artifact Plot...']);
    ArtHeight = -DCThresh/2;
    ts = (1:length(Signal))/options.SampleRate; %seconds  

% new plot version
if length(Signal) > 10000
        reduceSample = true;
    else
        reduceSample = false;
    end
    h_fig = figure;hold on;
    if reduceSample
        ts = ts(1:10:end);
        Signal = Signal(1:10:end);
        h_plot = plot(ts, Signal);
        if ts(end) < 60*60  %1 hour
            set(get(h_fig,'CurrentAxes'),'XTick',1:60:ts(end));
            set(get(h_fig,'CurrentAxes'),'XTickLabel',0:1:(length(Signal)/(60*options.SampleRate/10)));
            xlabel('Minutes');
        else
            set(get(h_fig,'CurrentAxes'),'XTick',1:60*60:ts(end));
            set(get(h_fig,'CurrentAxes'),'XTickLabel',0:1:(length(Signal)/(60*60*options.SampleRate/10)));
            xlabel('Hours');
        end
    else
        h_plot = plot(ts, Signal); 
        if ts(end) < 60*60  %1 hour
            set(get(h_fig,'CurrentAxes'),'XTick',1:60:ts(end));
            set(get(h_fig,'CurrentAxes'),'XTickLabel',0:1:(length(Signal)/(60*options.SampleRate)));
            xlabel('Minutes');
        else
            set(get(h_fig,'CurrentAxes'),'XTick',1:60*60:ts(end));
            set(get(h_fig,'CurrentAxes'),'XTickLabel',0:1:(length(Signal)/(60*60*options.SampleRate)));
            xlabel('Hours');
        end
    end
    title(options.plotTitle,'FontWeight','bold','Interpreter', 'none');
    ylabel('Signal');
    set(get(h_fig,'CurrentAxes'),'XMinorTick','on')
    set(get(h_fig,'CurrentAxes'),'YLim',[-DCThresh*1.5,DCThresh*1.5]);
    
    %plot(Artifacts,':r');
    if strcmpi(options.algorithm,'full')
        if reduceSample
        plot(ts, ExtremeSignalIDX(1:10:end)*ArtHeight,':c');
        plot(ts, dvArtifactIndex(1:10:end)*ArtHeight,':g');
        plot(ts, FlatSignalIDX(1:10:end)*ArtHeight,':m');
        plot(ts, EMGArtifactIndex(1:10:end)*ArtHeight,':r');
        plot(ts, Artifacts(1:10:end)*DCThresh/2,'y');
        line([1,ts(end)],DCThresh * ones(2,1),'Color','k');
        line([1,ts(end)],-DCThresh * ones(2,1),'Color','k');
        
        else
        plot(ts, ExtremeSignalIDX*ArtHeight,':c');
        plot(ts, dvArtifactIndex*ArtHeight,':g');
        plot(ts, FlatSignalIDX*ArtHeight,':m');
        plot(ts, EMGArtifactIndex*ArtHeight,':r');
        plot(ts, Artifacts*DCThresh/2,'y');
        line([1,ts(end)],DCThresh * ones(2,1),'Color','k');
        line([1,ts(end)],-DCThresh * ones(2,1),'Color','k');
        end
        legend('Signal','ExtremeArtifact','dvArifact','dropoutArtifact','EMGartifact','Artifacts');
    elseif strcmpi(options.algorithm,'full -EMG')
        if reduceSample
        plot(ts,ExtremeSignalIDX(1:10:end)*ArtHeight,':c');
        plot(ts,dvArtifactIndex(1:10:end)*ArtHeight,':g');
        plot(ts,FlatSignalIDX(1:10:end)*ArtHeight,':m');
        plot(ts, Artifacts(1:10:end)*DCThresh/2,'y');
        line([1,ts(end)],DCThresh * ones(2,1),'Color','k');
        line([1,ts(end)],-DCThresh * ones(2,1),'Color','k');
        else
        plot(ExtremeSignalIDX*ArtHeight,':c');
        plot(dvArtifactIndex*ArtHeight,':g');
        plot(FlatSignalIDX*ArtHeight,':m');
        plot(ts, Artifacts*DCThresh/2,'y');
        line([1,ts(end)],DCThresh * ones(2,1),'Color','k');
        line([1,ts(end)],-DCThresh * ones(2,1),'Color','k');
        
        end
        legend('Signal','ExtremeArtifact','dvArifact','dropoutArtifact','EMGartifact','Artifacts');
        
    elseif strcmpi(options.algorithm,'rms')
        if reduceSample  
            plot(ts, Artifacts(1:10:end)*DCThresh/2,'y');
            line([1,ts(end)],rms*options.RMSMultiplier * ones(2,1),'Color','k');
            line([1,ts(end)],-rms*options.RMSMultiplier * ones(2,1),'Color','k');      
        else
        plot(ts, Artifacts*DCThresh/2,'y');
        line([1,ts(end)],rms*options.RMSMultiplier * ones(2,1),'Color','k');
        line([1,ts(end)],-rms*options.RMSMultiplier * ones(2,1),'Color','k');
        
        end
        legend('Signal','Artifacts','RMSthreshold');
    else
        if reduceSample
        plot(ts, Artifacts(1:10:end)*DCThresh/2,'y');
        line([1,ts(end)],options.DCvalue * ones(2,1),'Color','k');
        line([1,ts(end)],-options.DCvalue * ones(2,1),'Color','k');
        else
        plot(ts, Artifacts*DCThresh/2,'y');
        line([1,ts(end)],options.DCvalue * ones(2,1),'Color','k');
        line([1,ts(end)],-options.DCvalue * ones(2,1),'Color','k');
        end
        legend('Signal','DC value','Artifacts');
    end
%%
%     if length(Signal) > 10000
%         reduceSample = true;
%     else
%         reduceSample = false;
%     end
%     h_fig = figure;hold on;
%     if reduceSample
%         ts = ts(1:10:end);
%         Signal = Signal(1:10:end);
%         h_plot = plot(ts, (Signal/(max(Signal)*2))+1/2); %scales between [0:1]
%         if ts(end) < 60*60  %1 hour
%             set(get(h_fig,'CurrentAxes'),'XTick',1:60:ts(end));
%             set(get(h_fig,'CurrentAxes'),'XTickLabel',0:1:(length(Signal)/(60*options.SampleRate/10)));
%             xlabel('Minutes');
%         else
%             set(get(h_fig,'CurrentAxes'),'XTick',1:60*60:ts(end));
%             set(get(h_fig,'CurrentAxes'),'XTickLabel',0:1:(length(Signal)/(60*60*options.SampleRate/10)));
%             xlabel('Hours');
%         end
%     else
%         h_plot = plot(ts, (Signal/(max(Signal)*2))+1/2); %scales between [0:1]
%         if ts(end) < 60*60  %1 hour
%             set(get(h_fig,'CurrentAxes'),'XTick',1:60:ts(end));
%             set(get(h_fig,'CurrentAxes'),'XTickLabel',0:1:(length(Signal)/(60*options.SampleRate)));
%             xlabel('Minutes');
%         else
%             set(get(h_fig,'CurrentAxes'),'XTick',1:60*60:ts(end));
%             set(get(h_fig,'CurrentAxes'),'XTickLabel',0:1:(length(Signal)/(60*60*options.SampleRate)));
%             xlabel('Hours');
%         end
%     end
%     title(options.plotTitle,'FontWeight','bold','Interpreter', 'none');
%     ylabel('Normalized Signal');
%     set(get(h_fig,'CurrentAxes'),'XMinorTick','on')
%     
%     %plot(Artifacts,':r');
%     if strcmpi(options.algorithm,'full')
%         if reduceSample
%         plot(ts, ExtremeSignalIDX(1:10:end)*ArtHeight,':c');
%         plot(ts, dvArtifactIndex(1:10:end)*ArtHeight,':g');
%         plot(ts, FlatSignalIDX(1:10:end)*ArtHeight,':m');
%         plot(ts, EMGArtifactIndex(1:10:end)*ArtHeight,':r');
%         line([1,ts(end)],(DCThresh/(max(Signal)*2)+1/2) * ones(2,1),'Color','k');
%         line([1,ts(end)],(-DCThresh/(max(Signal)*2)+1/2) * ones(2,1),'Color','k');
%         %plot((DCThresh/(max(Signal)*2)+1/2) * ones(length(Signal),1),'k');
%         %plot((-DCThresh/(max(Signal)*2)+1/2)* ones(length(Signal),1),'k');
%         else
%         plot(ts, ExtremeSignalIDX*ArtHeight,':c');
%         plot(ts, dvArtifactIndex*ArtHeight,':g');
%         plot(ts, FlatSignalIDX*ArtHeight,':m');
%         plot(ts, EMGArtifactIndex*ArtHeight,':r');
%         line([1,ts(end)],(DCThresh/(max(Signal)*2)+1/2) * ones(2,1),'Color','k');
%         line([1,ts(end)],(-DCThresh/(max(Signal)*2)+1/2) * ones(2,1),'Color','k');
%         end
%         legend('Signal','ExtremeArtifact','dvArifact','dropoutArtifact','EMGartifact');
%     elseif strcmpi(options.algorithm,'full -EMG')
%         if reduceSample
%         plot(ts,ExtremeSignalIDX(1:10:end)*ArtHeight,':c');
%         plot(ts,dvArtifactIndex(1:10:end)*ArtHeight,':g');
%         plot(ts,FlatSignalIDX(1:10:end)*ArtHeight,':m');
%         %plot(EMGArtifactIndex(1:10:end),':r');
%         line([1,ts(end)],(DCThresh/(max(Signal)*2)+1/2) * ones(2,1),'Color','k');
%         line([1,ts(end)],(-DCThresh/(max(Signal)*2)+1/2) * ones(2,1),'Color','k');
%         %plot((DCThresh/(max(Signal)*2)+1/2) * ones(length(Signal),1),'k');
%         %plot((-DCThresh/(max(Signal)*2)+1/2)* ones(length(Signal),1),'k');
%         else
%         plot(ExtremeSignalIDX*ArtHeight,':c');
%         plot(dvArtifactIndex*ArtHeight,':g');
%         plot(FlatSignalIDX*ArtHeight,':m');
%         %plot(EMGArtifactIndex,':r');
%         plot((DCThresh/(max(Signal)*2)+1/2) * ones(length(Signal),1),'k');
%         plot((-DCThresh/(max(Signal)*2)+1/2)* ones(length(Signal),1),'k');
%         end
%         legend('Signal','ExtremeArtifact','dvArifact','dropoutArtifact','EMGartifact');
%         
%     elseif strcmpi(options.algorithm,'rms')
%         if reduceSample
%         plot(ts,Artifacts(1:10:end)*ArtHeight,':r');  
%         plot(ts,repmat((rms*options.RMSMultiplier)/(max(Signal)*2)+1/2,1,length(Signal)),':g');
%         plot(ts,repmat((-rms*options.RMSMultiplier)/(max(Signal)*2)+1/2,1,length(Signal)),':g');
%         else
%         plot(Artifacts*ArtHeight,':r');
%         plot(repmat((rms*options.RMSMultiplier)/(max(Signal)*2)+1/2,1,length(Signal)),':g');
%         plot(repmat((-rms*options.RMSMultiplier)/(max(Signal)*2)+1/2,1,length(Signal)),':g');
%         end
%         legend('Signal','RMSthreshold','Artifacts');
%     else
%         if reduceSample
%         plot(ts,Artifacts(1:10:end)*ArtHeight,':r'); 
%         plot(ts,repmat(options.DCvalue/(max(Signal)*2)+1/2,1,length(Signal)),':g');
%         plot(ts,repmat(-options.DCvalue/(max(Signal)*2)+1/2,1,length(Signal)),':g');  
%         else
%         plot(Artifacts*ArtHeight,':r');
%         plot(repmat(options.DCvalue/(max(Signal)*2)+1/2,1,length(Signal)),':g');
%         plot(repmat(-options.DCvalue/(max(Signal)*2)+1/2,1,length(Signal)),':g');
%         end
%         legend('Signal','Artifacts', 'DC value');
%     end
    if ~isempty(options.logfile)
        [logpath, trash1, trash2] = fileparts(options.logfile);
    else
        logpath = cd;
    end    
    disp(['Info: NSB_ArtifactDetection - Saving Artifact Plot...']);

% Better naming
[~,filename,~] = fileparts(options.plotTitle{1});
filename = ['ArtifactFig_',filename,'_',options.plotTitle{2},'_',num2str(now)];

%Debugging    
%hgsave(h_fig, fullfile(logpath,[filename,'.fig']), '-v7.3');

print(h_fig,'-dpdf', fullfile(logpath,[filename,'.pdf']) );
close(h_fig);
end

% Artifacts is a logical array.  Now we have to have it become a Start-Stop array.
%create segments
%find begining and end of truths
if options.IndexedOutput
    ArtifactStruct.intStarts = strfind(char(double(Artifacts)'), char([0 1])) +1;
    ArtifactStruct.intEnds = strfind(char(double(Artifacts)'), char([1 0]));
    if Artifacts(1) == true
        ArtifactStruct.intStarts = [1; ArtifactStruct.intStarts'];
    else
        ArtifactStruct.intStarts = ArtifactStruct.intStarts';
    end
    if Artifacts(end) == true
        ArtifactStruct.intEnds = [ArtifactStruct.intEnds'; length(Artifacts)];
    else
        ArtifactStruct.intEnds = ArtifactStruct.intEnds';
    end
    
    % join artifacts that are close together ...
    % and ignore ultra small artifacts ..
    % then do some error checking
    if ~isempty(ArtifactStruct.intStarts) && ~isempty(ArtifactStruct.intEnds)
        % Generate a list of artifact lengths and determine which are
        %shorter than MinArtifactDuration
        ArtifactLength = ArtifactStruct.intEnds - ArtifactStruct.intStarts +1;
        ShortArtifacts = find(ArtifactLength < ceil(options.SampleRate*options.full.MinArtifactDuration));
        
        % force short artifacts to be at least the length of Artifact.MinArtifactDuration
        for curArtifact = 1:length(ShortArtifacts)
            ArtifactCenter = ArtifactStruct.intStarts(ShortArtifacts(curArtifact)) + ArtifactLength(ShortArtifacts(curArtifact)) /2;
            ArtifactStruct.intStarts(ShortArtifacts(curArtifact)) = ceil(ArtifactCenter - options.SampleRate*options.full.MinArtifactDuration /2);
            ArtifactStruct.intEnds(ShortArtifacts(curArtifact)) = ceil(ArtifactCenter + options.SampleRate*options.full.MinArtifactDuration /2);
        end
        
        %since artifacts were lengthened ...
        %Check for < zero's indicies (there could be more than 1)
        ArtifactStruct.intStarts(ArtifactStruct.intStarts < 0) = 0;
        ArtifactStruct.intEnds(ArtifactStruct.intEnds < 0) = 0;
        if ArtifactStruct.intStarts(1) == 0
            ArtifactStruct.intStarts(1) = 1; %Although zero is zero seconds, the 1st data point is IDX 1 == 0 sec
        end
        
        % Additionaly check for > sig length indicies
        ArtifactStruct.intStarts(ArtifactStruct.intStarts > SignalLength) = SignalLength;
        ArtifactStruct.intEnds(ArtifactStruct.intEnds > SignalLength) = SignalLength;
        
        if length(ArtifactStruct.intStarts) > 1
            % ... check for overlap of artifact segments
            totalArtifacts = length(ArtifactStruct.intStarts);
            ArtifactOverlapIDX = ArtifactStruct.intEnds(1:end-1) >= ArtifactStruct.intStarts(2:end);
            ArtifactStruct.intStarts([false; ArtifactOverlapIDX(1:end)]) = [];
            ArtifactStruct.intEnds(ArtifactOverlapIDX) = [];
            
            % NOW, Join Artifacts that are closer than CombineArtifactTimeThreshold
            ArtifactDistance = ArtifactStruct.intStarts(2:end) - ArtifactStruct.intEnds(1:end-1);
            CloseArtifactIDX = ArtifactDistance <= options.full.CombineArtifactTimeThreshold*options.SampleRate;
            ArtifactStruct.intEnds(CloseArtifactIDX) = [];
            ArtifactStruct.intStarts([false; CloseArtifactIDX(1:end-1)]) = [];
        end
        
        % error Checking:
        %Check for uneven columns
        lengthDiff = length(ArtifactStruct.intStarts) - length(ArtifactStruct.intEnds);
        if lengthDiff > 0
            for offset = 1:lengthDiff
                if ArtifactStruct.intStarts(end) > ArtifactStruct.intStarts(end-1) && ...
                        ArtifactStruct.intEnds(end) > ArtifactStruct.intStarts(end)
                    ArtifactStruct.intStarts(end) = [];
                else
                    %artifact is contained in the last sample
                    ArtifactStruct.intEnds(end+1) = SignalLength;
                end
            end
        elseif lengthDiff < 0
            disp('Artifact End count > Start count')
        end
        %Check for unacending columns
        if any(ArtifactStruct.intStarts > ArtifactStruct.intEnds)
            disp('Individual Artifact Ends > Starts')
        end
        
        %convert to seconds (there may be an error and not converting to intergers
        ArtifactStruct.intStarts = ((ArtifactStruct.intStarts -1) / options.SampleRate);
        ArtifactStruct.intEnds = ((ArtifactStruct.intEnds -1) / options.SampleRate);
        
        Artifacts = ArtifactStruct;
       
        
    else
        disp('Information: No Artifacts Detected')
        errorstr = ['Information: NSB_ArtifactDetection >> No Artifacts Detected'];
        if ~isempty(options.logfile)
            NSBlog(options.logfile,errorstr);
        else
            errordlg(errorstr,'NSB_ArtifactDetection');
        end
    end
end
status = true;
function [Pyy,CI,T,F,validBins,status] = NSB_SpectralAnalysis(Signal, FinalTimeBinSize, FinalFreqRes, fs, options)
% NSB_SpectralAnalysis() - Perform Spectral Ananlysis on Single EEG channel
% [Pyy,CI,T,F,validBins,status] = NSB_SpectralAnalysis(Signal, FinalTimeBinSize, FinalFreqResolution, fs, options)
%
% Functions very Similar to Spectrogram()
%
% Inputs:
%   Signal            - (double) continuous time signal
%   FinalTimeBinSize  - (double) Final Window Size (seconds)
%   FinalFreqRes      - (double) Final Frequency Resolution (Hz) -or- vector of frequencies to return
%   fs                - (double)  sampling frequency (Hz)
%   options           - (struct) of options
%                           (string)    options.SPTmethod Can be {'mtm','welch','FFT'} for Thompson MultiTaper
%                                        Method, Welch Method, Default FFT (no sig processing toolbox).
%                           (string)   options.WindowType can be {'none',Hamming, Hann, Blackman} Default =Hamming
%                           (double)    options.FFTWindowSize size of FFT  window (seconds). The behavior is that a number
%                                       of FFTWindows make up a BinSize window default is to divide 'BinSize' into 2 segments.
%                           (double)    options.FFTWindowOverlap percent of FFT window overlap (0-100). Default (50%)
%                           (double)    options.TimeBW time-bandwidth product for MTM Default = 4 see: help spectrum.mtm
%                           (logical)   options.Artifacts T/F index of artifacts
%                           (string)   options.logfile Path+FileName of LogFile
%  undocumented options
%                           (logical)   options.nanDC fill DC with NaN (useful for plotting)
%                           (logical)   options.nanMean Use nanMean instead
%                           of nanSum when re time bin spectrum
%
% Outputs: Pyy,CI,T,F,validBins,status
%   Pyy                 - (double) Spectrogram (power units) Rows = time, cols = Hz
%   CI                  - (double) Spectrogram confidence intervals 
%   T                   - (double) Time Values of Pyy
%   F                   - (double) Frequency values of Pyy
%   validBins           - (logical) Logical vector of Valid Binds (spectral estimation without artifacts)
%   status              - (logical) return value
%
%
% Dependencies: 
% NSBlog
% 
%   F = fs/nFFT;
% But you want to set... T, F, and nFFT
% There are a couple of ways to do this... every T, take nFFT points such
% that fs = 100
% |-------|      t = 0.5 F = 0.5 and nFFT is 200
%      |-------| t = 1.0
% or
%  |---|          t = 0.5 F = 0.5 and nFFT is 200
%      |---|      t = 1.0
% <the difference is the normalization>
%
%
% Written By David M. Devilbiss
% NexStep Biomarkers, LLC. (info@nexstepbiomarkers.com)
% December 8 2011, Version 1.0
% March 1 2013, Version 1.1 - added nanMean as an option and fixed a bug in
% handling valid time bins as a function of all([])
% July 29 2013, Version 2.1 (bug fix - handle exception when FinalTimeBinSize/FFTepoch is not an interger)

%the main issue of this is that we still have not defined how it is
%functioning !
%ToDo: BinSize and options.FinalTimeResolution seem to be mishandled?

status = false;
F = []; T = []; Pyy = []; CI = []; validBins = [];
FFTuseWindowing = false;

%% Check for inputs options
if nargin == 4 % no options
    options.SPTmethod = 'welch'; %{mtm,welch,FFT}
    options.WindowType = 'Hamming'; % can be {'none',Hamming, Hann, Blackman}
    options.FFTWindowSize = []; %in seconds divide into 8 segments
    options.FFTWindowOverlap = []; %percent (default (50%))
    options.Artifacts = false(length(Signal),1); 
    if strcmpi(options.SPTmethod,'mtm')
        options.TimeBW = 4;
    end
    options.nanMean = false;
    options.logfile = '';
elseif nargin == 5 %options and Check
    inputError = false;
    if ~isfield(options,'SPTmethod'), options.SPTmethod = 'FFT';inputError = true; end
    if ~isfield(options,'WindowType'), options.WindowType = 'Hamming';inputError = true; end
    if ~isfield(options,'FFTWindowSize'), options.FFTWindowSize = [];inputError = true; end
    if ~isfield(options,'FFTWindowOverlap'), options.FFTWindowOverlap = [];inputError = true; end
    if ~isfield(options,'TimeBW'), options.TimeBW = 4;inputError = true; end
    if ~isfield(options,'Artifacts'), options.Artifacts = false(length(Signal),1);inputError = true; end
    if ~isfield(options,'logfile'), options.logfile = '';inputError = true; end
    if ~isfield(options,'nanMean'), options.nanMean = false; end %hidden option
    if inputError
        errorstr = ['Warning: NSB_SpectralAnalysis >> Missing at least 1 options: Missing were set to default(s)'];
        if ~isempty(options.logfile)
            NSBlog(options.logfile,errorstr);
        else
            errordlg(errorstr,'NSB_SpectralAnalysis');
        end
    end
else
    errorstr = 'ERROR: NSB_SpectralAnalysis >> Incorrect number of input parameters';
    errordlg(errorstr,'NSB_SpectralAnalysis');
    return;
end

if length(FinalFreqRes) == 1
    FinalFreqs = 0:FinalFreqRes:(fs/2);
else
    FinalFreqs = FinalFreqRes;
end

%% Check For toolboxes
if NSB_Check4Toolbox('Signal Processing Toolbox')
    options.SPToolbox = true;
else
    options.SPToolbox = false;
end

%Begin Processing
%% 1st remove artifact
Signal = Signal(:); %force to column vector (but dosn't really matter)
if islogical(options.Artifacts)
    Signal(options.Artifacts) = NaN;
elseif isfield(options.Artifacts,'intStarts')
    %Convert Intervals 2 Logical
    Artifact_IDX = NSB_interval2IDX(options.Artifacts,length(Signal),fs);
    Signal(Artifact_IDX) = NaN;
    clear Artifact_IDX;
end

%% 2nd Generate Power Spectrum
% If sig Processing took kit exists and MTM or Welch
if options.SPToolbox && ~strcmpi(options.SPTmethod,'FFT')
    %Bin Data into time epochs
    BinnedData = buffer(Signal,round(FinalTimeBinSize*fs),0,'nodelay'); %BinSize = round(BinSize*fs);
    validBins = ~any(isnan(BinnedData));
    
    %One could also identify NaNs, replace with zeros, PSD(matrix), replace
    %with nans,
    
    %also inject mscohere in here as well
    
    %i fyou are fixing this also fix mtm and welch
    
    %malloc
    T = [0:FinalTimeBinSize:length(validBins)*FinalTimeBinSize]; %returns in seconds
    T = T(1:length(validBins));   
    Pyy = NaN(length(validBins),length(FinalFreqs));
    CILo = NaN(length(validBins),length(FinalFreqs));
    CIHi = NaN(length(validBins),length(FinalFreqs));

    switch lower(options.SPTmethod)
        case {'mtm','thompson'}
            obj = spectrum.mtm(options.TimeBW);
        case 'welch'
            %setup within bin windowing   
            if isempty(options.FFTWindowSize)
                options.FFTWindowSize = floor(size(BinnedData,1)/3); %use 3 segments, dspdata.psd sets nextpow2
            elseif options.FFTWindowSize <= FinalTimeBinSize
                options.FFTWindowSize = floor(size(BinnedData,1)/3); %use 3 segments, dspdata.psd sets nextpow2
            else
                options.FFTWindowSize = options.FFTWindowSize*fs;
            end            
            if isempty(options.FFTWindowOverlap)
                options.FFTWindowOverlap = 50; %use a 50% overlap
            end
            %spectrum.welch(WindowName,SegmentLength,OverlapPercent)
            obj = spectrum.welch({options.WindowType,'periodic'},options.FFTWindowSize,options.FFTWindowOverlap);
            %by specifing a freq vector NFFT is lost in that object so workaround
            %set(obj,'SegmentLength', 2.^nextpow2(FinalFreqRes/fs)); %at least that Fs/N samples
        otherwise
            %setup within bin windowing   
            if isempty(options.FFTWindowSize)
                options.FFTWindowSize = floor(size(BinnedData,1)/3); %use 3 segments, dspdata.psd sets nextpow2
            else
                options.FFTWindowSize = options.FFTWindowSize*fs;
            end            
            if isempty(options.FFTWindowOverlap)
                options.FFTWindowOverlap = 50; %use a 50% overlap
            end
            obj = spectrum.welch({options.WindowType,'periodic'},options.FFTWindowSize,options.FFTWindowOverlap);
            %by specifing a freq vector NFFT is lost in that object so workaround
            %set(obj,'SegmentLength', 2.^nextpow2(FinalFreqRes/fs)); %at least that Fs/N samples
    end
    %set options
    objOPTS = psdopts(obj);
    set(objOPTS,'Fs',fs); %use this sample rate and use a default set of linear frequencies
    set(objOPTS,'FreqPoints','User Defined','FrequencyVector',FinalFreqs); % returns a PSD object where the spectrum is calculated only on the frequency points defined in the frequency vector
    set(objOPTS,'ConfLevel',0.95); %return confidence intervals

    warning('off','signal:welch:InconsistentRangeOption');
    warning('off','signal:pmtm:InconsistentRangeOption');
    for curbuffer = 1:length(validBins) %could run in a ParFor but obj is an issue!
        if validBins(curbuffer)
            hpsd = psd(obj,BinnedData(:,curbuffer),objOPTS);
            Pyy(curbuffer,:) = hpsd.Data;
            CILo(curbuffer,:) = hpsd.ConfInterval(:,1);
            CIHi(curbuffer,:) = hpsd.ConfInterval(:,2);
        end
    end
    CI.Lo = CILo;
    CI.Hi = CIHi;
    warning('on','signal:welch:InconsistentRangeOption');
    warning('on','signal:pmtm:InconsistentRangeOption');
    F = FinalFreqs;

else
    %Do manual FFT
    %this is a total redo based on SSM_Spectrogram and should deal with Hz
    %differences better.
    
%     %if options.FFTWindowSize (Window) is missing use default which gives you
%     %that exact decomposition
%     if isempty(options.FFTWindowSize)
%         options.FFTWindowSize = floor(fs/FinalFreqRes); %Do no subsampling
%     else
%         options.FFTWindowSize = floor(FinalTimeBinSize*fs); %Seconds to samples
%     end
%     %if options.FFTWindowOverlap (overlap) is missing use default of 0% overlap
%     if isempty(options.FFTWindowOverlap)
%         options.FFTWindowOverlap = 0; %zero percent
%     else %there is overlap set flag for later windowing...
%         FFTuseWindowing = true;
%         options.FFTWindowOverlap = floor(options.FFTWindowSize*options.FFTWindowOverlap/100); %percent to Samples
%     end

    
    %set Window and nFFT
    %if options.FFTWindowOverlap (overlap) is missing use default of 0% overlap
    if isempty(options.FFTWindowOverlap)
        options.FFTWindowOverlap = 0; %zero percent
        if isempty(options.FFTWindowSize)
            options.FFTWindowSize = floor(fs/FinalFreqRes) * 10; %do FFT with 10x higher resolution
            if options.FFTWindowSize > FinalTimeBinSize*fs % but do not let it go over window length
                options.FFTWindowSize = floor(FinalTimeBinSize*fs);
            end
        else
            %options.FFTWindowSize = floor(FinalTimeBinSize*fs); %Seconds to samples
            options.FFTWindowSize = floor(options.FFTWindowSize*fs); %Seconds to samples
            %check that it i <= to Hzdiv F = fs/nFFT;
            if fs/options.FFTWindowSize > FinalFreqRes
                %default to 10 higher resolution
                options.FFTWindowSize = floor(fs/FinalFreqRes) * 10; %do FFT with 10x higher resolution
                if options.FFTWindowSize > FinalTimeBinSize*fs % but do not let it go over window length
                    options.FFTWindowSize = floor(FinalTimeBinSize*fs);
                end
            end
        end
    else %there is overlap set flag for later windowing...
        FFTuseWindowing = true;
        if isempty(options.FFTWindowSize)
            options.FFTWindowSize = floor(fs/FinalFreqRes); %optimize for time resolution
        else
            options.FFTWindowSize = floor(FinalTimeBinSize*fs); %Seconds to samples
        end
        options.FFTWindowOverlap = floor(options.FFTWindowSize*options.FFTWindowOverlap/100); %percent to Samples
    end
    
    %Throw Warning if necessary
    if options.FFTWindowSize > FinalTimeBinSize*fs
       errorstr = ['ERROR: NSB_SpectralAnalysis >> nFFT size is greater than TimeBin Size. Overlapping data will be used to fill nFFT window.'];
        if ~isempty(options.logfile)
            NSBlog(options.logfile,errorstr);
        else
            errordlg(errorstr,'NSB_SpectralAnalysis');
        end
    end
    
    % Bin Data into FFTWindowSize Segments (with overlap)
    WindowOffset = (options.FFTWindowSize-options.FFTWindowOverlap); %samples of offset
    nSegments = ceil(length(Signal) / WindowOffset); %num of windows
    %malloc
    BinnedData = NaN(options.FFTWindowSize,nSegments);
    for curSeg = 0:nSegments-1
        if curSeg*WindowOffset+options.FFTWindowSize <= length(Signal)
            SigFrag = Signal(curSeg*WindowOffset+1 : curSeg*WindowOffset+options.FFTWindowSize);
        elseif curSeg == 0 %special case FFTWindowSize > sig length
             SigFrag = Signal;     
        else
            SigFrag = Signal(curSeg*WindowOffset : end);
            SigFrag = [SigFrag; zeros(options.FFTWindowSize-length(SigFrag),1)];
        end
        %BinnedData(:,curSeg+1) = SigFrag;
        BinnedData(1:length(SigFrag),curSeg+1) = SigFrag;
    end
    clear Signal;
    validBins = ~any(isnan(BinnedData));
    
    %Apply Windowing if requested 
    if FFTuseWindowing
        if strcmp(options.WindowType,'Blackman')
            errorstr = ['Info: NSB_SpectralAnalysis >> FFT using Blackman Window'];
            winfun = .42 - .5*cos(2*pi*(1:options.FFTWindowSize)/options.FFTWindowSize) + .08*cos(4*pi*(1:options.FFTWindowSize)/options.FFTWindowSize);
        elseif strcmp(options.WindowType,'Hamming')
            errorstr = ['Info: NSB_SpectralAnalysis >> FFT using Hamming Window'];
            winfun = .54 - .46*cos(2*pi*(1:options.FFTWindowSize)/options.FFTWindowSize);
        elseif strcmp(options.WindowType,'None')
            errorstr = ['Info: NSB_SpectralAnalysis >> FFT using no (None) Window'];
        else
            errorstr = ['Info: NSB_SpectralAnalysis >> FFT using Default Hamming Window'];
            %use hamming window
            winfun = .54 - .46*cos(2*pi*(1:options.FFTWindowSize)/options.FFTWindowSize);
        end
        %BinnedData = BinnedData .* repmat(winfun(:),1,size(BinnedData,2));
        BinnedData = bsxfun(@times,BinnedData,winfun(:));
    
        if ~isempty(options.logfile)
            NSBlog(options.logfile,errorstr);
        else
            errordlg(errorstr,'NSB_SpectralAnalysis');
        end
    end
    
    %NeuroScore Version
    DFT = abs(fft(BinnedData,options.FFTWindowSize))/(options.FFTWindowSize/2); %Get Magnitude of FFT %ok work on each time slice
    if (mod(options.FFTWindowSize,2)==0) %could use rem here as well since mod 2 always determines odd vs even
            NumUniquePts = options.FFTWindowSize/2+1;
    else
            NumUniquePts = (options.FFTWindowSize+1)/2;
    end
    DFT(NumUniquePts+1:end,:) = []; %take only the positve frequency half
    Pyy = DFT.^2; 
    Pyy(1,:) = DFT(1,:); %Report Power, but dont square the 0Hz bin
    if isfield(options,'nanDC')
        if options.nanDC
            Pyy(1,:) = NaN(size(Pyy,2),1);
        end
    end
    
%Pre version 0.96
%     %do manual FFT
%     %default behavior is to do an FFT on the entire FinalTimeBinSize (options.FFTWindowSize = [];)
%     
%     %Error Check for FFTWinSize and Overlap
%     if isempty(options.FFTWindowSize)
%         options.FFTWindowSize = FinalTimeBinSize*fs;
%         options.FFTWindowOverlap = 0; %zero percent
%     elseif options.FFTWindowSize > FinalTimeBinSize
%         options.FFTWindowSize = FinalTimeBinSize*fs;
%         errorstr = ['Warning: NSB_SpectralAnalysis >> nFFT size is greater than TimeBin Size. nFFT/Spectral Bin Size takes precidence.'];
%         if ~isempty(options.logfile)
%             NSBlog(options.logfile,errorstr);
%         else
%             errordlg(errorstr,'NSB_SpectralAnalysis');
%         end
%     else
%         options.FFTWindowSize = options.FFTWindowSize*fs;
%     end
%     
%     % Generate FFTWindowOverlap window size
%     if ~isempty(options.FFTWindowOverlap)
%         options.FFTWindowOverlap = floor(options.FFTWindowSize*options.FFTWindowOverlap/100);
%     else
%         options.FFTWindowOverlap = floor(options.FFTWindowSize*50/100); %50%
%     end
%     
%     % Bin Data into FFTWindowSize Segments (with overlap)
%     WindowOffset = (options.FFTWindowSize-options.FFTWindowOverlap); %samples of offset
%     nSegments = ceil(length(Signal) / WindowOffset); %num of windows
%     
%     %malloc
%     BinnedData = NaN(options.FFTWindowSize,nSegments);
%     for curSeg = 0:nSegments-1
%         if curSeg*WindowOffset+options.FFTWindowSize <= length(Signal)
%             SigFrag = Signal(curSeg*WindowOffset+1 : curSeg*WindowOffset+options.FFTWindowSize);
%         elseif curSeg == 0 %special case FFTWindowSize > sig length
%              SigFrag = Signal;     
%         else
%             SigFrag = Signal(curSeg*WindowOffset : end);
%             SigFrag = [SigFrag; zeros(options.FFTWindowSize-length(SigFrag),1)];
%         end
%         %BinnedData(:,curSeg+1) = SigFrag;
%         BinnedData(1:length(SigFrag),curSeg+1) = SigFrag;
%     end
%     clear Signal;
%     validBins = ~any(isnan(BinnedData));
%     
%     %NeuroScore Version
%     DFT = abs(fft(BinnedData,options.FFTWindowSize))/(options.FFTWindowSize/2); %Get Magnitude of FFT %ok work on each time slice
%     if (mod(options.FFTWindowSize,2)==0) %could use rem here as well since mod 2 always determines odd vs even
%             NumUniquePts = options.FFTWindowSize/2+1;
%              DFT = DFT(1:NumUniquePts,:); %take only the positve frequency half
%      else
%             NumUniquePts = (options.FFTWindowSize+1)/2;
%              DFT = DFT(1:NumUniquePts,:);
%      end
%     Pyy = DFT.^2; 
%     Pyy(1,:) = DFT(1,:); %Report Power, but dont square the 0Hz bin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
%     %Initial Version: Do FFT (Super transparent version: See http://www.mathworks.com/support/tech-notes/1700/1702.html). 
%     DFT = abs(fft(BinnedData,options.FFTWindowSize)); %Get Magnitude of FFT %ok work on each time slice
%     clear BinnedData;
%     NumUniquePts = ceil((options.FFTWindowSize+1)/2);
%     DFT = DFT(1:NumUniquePts,:); %Truncate to one sided spectrum  
%     DFT = DFT/options.FFTWindowSize; %Scale/normalize the fft so that it is not a function of the length of x
%     Pyy = DFT.^2; %Report Power
%     clear DFT;
%
    % Since we dropped half the FFT, we multiply mx by 2 to keep the same energy.
    % The DC component and Nyquist component, if it exists, are unique and should not be multiplied by 2.
    % True but is is not scaled the same way as MTM or Welch
%     if rem(options.FFTWindowSize, 2) % odd nfft excludes Nyquist point
%         Pyy(2:size(Pyy,1),:) = Pyy(2:size(Pyy,1),:)*2;
%     else
%         Pyy(2:size(Pyy,1)-1,:) = Pyy(2:size(Pyy,1)-1,:)*2;
%     end
    
    %Pyy = pow2db(Pyy); if you want in db but plot on a semilog scale
    
%     %This is in esscence the same as... but numbers do not match
%     %DFT = abs(fft(BinnedData,options.FFTWindowSize)); %Get Magnitude of FFT
%     %Pyy = Y.*conj(DFT)/options.FFTWindowSize;
%     %http://www.mathworks.com/products/matlab/demos.html?file=/products/demos/shipping/matlab/fftdemo.html
%         
%     %version JS
%     DFT = abs(fft(BinnedData,nfft));
%     if (mod(nfft,2)==0) %could use rem here as well since mod 2 always determines odd vs even  
%             DFT = DFT(1:(nfft/2+1)); %take only the positve frequency half
%     else
%             DFT = DFT(1:(nfft+1)/2);
%     end
%     Pyy = DFT.*DFT/nfft;
%
%     %Version http://faculty.olin.edu/bstorey/Notes/Fourier.pdf
%     DFT = abs(fft(BinnedData,nfft))/(nfft/2); %Generate the absolute value of the FFT upto 1/2 Nyquist
%     if (mod(nfft,2)==0) %could use rem here as well since mod 2 always determines odd vs even  
%             DFT = DFT(1:(nfft/2+1)); %take only the positve frequency half
%     else
%             DFT = DFT(1:(nfft+1)/2);
%     end
%     Pyy = DFT.^2;

% Code that gets close to NeuroView...
% Version http://faculty.olin.edu/bstorey/Notes/Fourier.pdf
   
%% 3nd Generate re time bin spectrum
Pyy = Pyy'; %transpse so we can operate on time as rows
if options.FFTWindowSize ~= FinalTimeBinSize*fs
    % Combine time segments
    if  mod(FinalTimeBinSize*fs / options.FFTWindowSize * (options.FFTWindowSize/WindowOffset) ,1) == 0
        NonIntNSeg = false;
    else
        NonIntNSeg = true;
        errorstr = ['Warning: NSB_SpectralAnalysis >> The number of FFT Windows (',num2str(options.FFTWindowSize/fs),...
            ' sec.) does not evenly aggrigate into the final time bin size (',num2str(FinalTimeBinSize),...
            ' sec.). Truncation of the remaining FFT Window will underestimate sprctral power.'];
        disp(errorstr);
        if ~isempty(options.logfile)
            NSBlog(options.logfile,errorstr);
        else
            errordlg(errorstr,'NSB_SpectralAnalysis');
        end
    end
    
    combineNsegments = floor(FinalTimeBinSize*fs / options.FFTWindowSize * (options.FFTWindowSize/WindowOffset)); %how many FFTsegments to aggrigate check this.if 1000/2 is 500 with an over lap of 50% thn this should be 3 not 2
    TotalnSegments = floor(nSegments/combineNsegments)*combineNsegments;
    if TotalnSegments ~= 0
    counter = 1;
%     rebinPyy = NaN(TotalnSegments/combineNsegments,size(Pyy,2));%preallocate
%     rebinValidBins = false(TotalnSegments/combineNsegments,1);%preallocate
    rebinPyy = NaN( ceil(TotalnSegments/(FinalTimeBinSize*fs / options.FFTWindowSize * (options.FFTWindowSize/WindowOffset)) ) ,size(Pyy,2));%preallocate
    rebinValidBins = false( ceil(TotalnSegments/(FinalTimeBinSize*fs / options.FFTWindowSize * (options.FFTWindowSize/WindowOffset)) ),1);%preallocate
    for curBIN = 1:combineNsegments+NonIntNSeg:TotalnSegments %This now skips the partial FFTWindosSize if it is a fragment
        selectedBins = false(length(validBins),1); 
        selectedBins(curBIN:curBIN+combineNsegments-1) = validBins(curBIN:curBIN+combineNsegments-1);
        if options.nanMean
            rebinPyy(counter,:) = nanmean(Pyy(selectedBins,:),1); %nanmean/nansum
            if any(validBins(curBIN:curBIN+combineNsegments-1)) %if all bins contain data
                rebinValidBins(counter) = true; %valid is true
            else
                rebinValidBins(counter) = false; %FALSE can indicate incomplete filled bins of bins with no data
            end
        else
            rebinPyy(counter,:) = nansum(Pyy(selectedBins,:),1); %nanmean/nansum
            if all(validBins(curBIN:curBIN+combineNsegments-1)) %if all bins contain data
                rebinValidBins(counter) = true; %valid is true
            else
                rebinValidBins(counter) = false; %FALSE can indicate incomplete filled bins of bins with no data
            end
        end
%         if ~isempty(validBins(selectedBins)) %if there are valid bins... %if all(validBins(curBIN:curBIN+combineNsegments-1))
%             rebinValidBins(counter) = all(validBins(selectedBins));
%         else
%             rebinValidBins(counter) = false;
%         end
        counter = counter +1;
    end
    else
        rebinPyy = nansum(Pyy); %nanmean/nansum
        rebinValidBins = 1;
    end
    if isfield(options,'nanDC')
        if options.nanDC
            rebinPyy(:,1) = NaN(size(rebinPyy,1),1);
        end
    end
    Pyy = rebinPyy;
    validBins = rebinValidBins;
end
T = [0:FinalTimeBinSize:FinalTimeBinSize*size(Pyy,1)-1]; %returns Time Vector in seconds
%generate Frequency Vector

F = (0:NumUniquePts-1)*fs/options.FFTWindowSize; %<<< check this !
end

%% 3nd Generate de-resolve spectrum if necessarry
LengthsEqual = false;
ExactMatch = false;
if length(FinalFreqs) == length(F)
    LengthsEqual = true;
    if FinalFreqs == F
        ExactMatch = true;
    end
end

if ~LengthsEqual || ~ExactMatch
%check if the freqresolutions are different if so fix
FsRes = single(min(diff(F))); %single is to get around EPS errors
if length(FinalFreqRes) == 1
    FinalRes = FinalFreqRes;
else
    FinalRes = single(min(diff(FinalFreqs)));
end
if FsRes < FinalRes
    startF = find(F >= FinalRes,1,'first');
    combineNfreqs = ceil(FinalRes/FsRes);
    Totalnfreqs = floor((size(Pyy,2)-1)/combineNfreqs)*combineNfreqs; %dmd added -1 since dont count oHz
    counter = 1;
    rebinPyy = NaN(size(Pyy,1),(Totalnfreqs/combineNfreqs));%preallocate
    rebinPyy(:,1) = Pyy(:,1); %Retain DC component
    Fyy = 0;
    for curBIN = startF:combineNfreqs:Totalnfreqs %was 1:...:..
        selectedBins = false(size(Pyy,2),1);
        selectedBins((curBIN):curBIN+combineNfreqs-1) = true;    
        rebinPyy(:,counter+1) = nansum(Pyy(:,selectedBins),2); %nanmean/nansum
        Fyy(counter+1) = F(curBIN);
        counter = counter +1;
    end
%     for curBIN = 1:combineNfreqs:Totalnfreqs %was 1:...:..
%         selectedBins = false(size(Pyy,2),1);
%         selectedBins((curBIN+1):curBIN+combineNfreqs) = true;    
%         rebinPyy(:,counter+1) = nansum(Pyy(:,selectedBins),2); %nanmean/nansum
%         counter = counter +1;
%     end 
    Pyy = rebinPyy;
    F = Fyy;
else %ignore and warn
        errorstr = ['Warning: NSB_SpectralAnalysis >> Final Spectral Resolution is less than FinalTimeBinSize Size.'];
        if ~isempty(options.logfile)
            NSBlog(options.logfile,errorstr);
        else
            errordlg(errorstr,'NSB_SpectralAnalysis');
        end
        F = 0:FinalRes:(fs/2);
end
%F = 0:FinalRes:(fs/2);
%
%F = 0:FinalRes:(size(rebinPyy,2)-1);
%F = 0:FinalRes:Totalnfreqs/combineNfreqs;%<<< check this !
end

%4 finish up
status = true;
    
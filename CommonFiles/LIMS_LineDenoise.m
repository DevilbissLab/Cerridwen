function [DataStruct,status] = LIMS_LineDenoise(LIMS, DataStruct)
%helper function to remove 50/60Hz on a channel by channel bases

status = false;
try
    for curChan = 1:DataStruct.nChannels
        Fs = DataStruct.Channel(curChan).Hz;   % Sampling frequency

        %Design the filter object - yes for each channel since channels may have different sampling frequencies
        %requires DSP System Toolbox.
        % Fnyq = Fs/2; % Nyquist frequency
        % filtobj = designNotchPeakIIR(Response="notch",...
        %                     CenterFrequency=LIMS.PreClinicalFramework.LineNoiseDetection.Freq/Fnyq,...
        %                     Bandwidth=LIMS.PreClinicalFramework.LineNoiseDetection.Bandwidth/Fnyq,...
        %                     FilterOrder=2,SystemObject=true);

        %requires Signal processing System Toolbox.
        % Butterworth Bandstop filter
        % All frequency values are in Hz.
        CenterFrequency=LIMS.PreClinicalFramework.LineNoiseDetection.Freq;
        Bandwidth=LIMS.PreClinicalFramework.LineNoiseDetection.Bandwidth;
        
        %For filtfilt use designfilt
        filtobj = designfilt('bandstopiir', ...       % Response type
       'PassbandFrequency1',CenterFrequency-Bandwidth/2, ...    % Frequency constraints
       'StopbandFrequency1',CenterFrequency-Bandwidth/2/2, ...
       'StopbandFrequency2',CenterFrequency+Bandwidth/2/2, ...
       'PassbandFrequency2',CenterFrequency+Bandwidth/2, ...
       'PassbandRipple1',0.5, ...         % Magnitude constraints
       'StopbandAttenuation',60, ...
       'PassbandRipple2',1, ...
       'DesignMethod','butter', ...      % Design method
       'MatchExactly','stopband', ...       % Design method options
       'SampleRate',Fs);               % Sample rate

        DataStruct.Channel(curChan).Data = filtfilt(filtobj, DataStruct.Channel(curChan).Data);
    end
    status = true;
catch ME
    errorstr = ['ERROR: NSB_Workflow_LIMS.Rereference >> ',ME.message];
    if ~isempty(ME.stack)
        errorstr = [errorstr,' Function: ',ME.stack(1).name,' Line # ',num2str(ME.stack(1).line)];
    end
    if ~isempty(LIMS.logfile)
        NSBlog(LIMS.logfile,errorstr);
        disp(errorstr);
    else
        disp(errorstr);
    end
    status = false;
end

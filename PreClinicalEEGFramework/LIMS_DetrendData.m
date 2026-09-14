function [DataStruct,status] = LIMS_DetrendData(LIMS, DataStruct)
%helper function to detrend on a channel by channel bases

status = false;
try
    for curChan = 1:DataStruct.nChannels
        DataStruct.Channel(curChan).Data = detrend(DataStruct.Channel(curChan).Data, LIMS.PreClinicalFramework.Resample.DetrendType);
    end
    status = true;
catch ME
    errorstr = ['ERROR: NSB_Workflow_LIMS.Rereference >> ',ME.message];
    if ~isempty(ME.stack)
        errorstr = [errorstr,' Function: ',ME.stack(1).name,' Line # ',num2str(ME.stack(1).line)];
    end
    if ~isempty(LIMS.logfile)
        NSBlog(LIMS.logfile,errorstr);
    else
        disp(errorstr);
    end
    status = false;
end

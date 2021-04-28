function NSB_ProgressCloseReq(src,callbackdata)
    setappdata(gcbf,'Canceling',1);
    figAppData = getappdata(gcbf,'TMWWaitbar_handles');
    figAppData.axesTitle.String = 'Canceling Analyses. Please Wait...';
    
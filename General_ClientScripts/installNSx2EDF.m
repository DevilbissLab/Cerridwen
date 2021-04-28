function installNSx2EDF()
    %navigate to this folder and run installNSx2EDF() to install to
    %Matlab's path
    
    currentPath = what;
    
    addpath(currentPath.path);
    addpath(fullfile(currentPath.path,'lab_write_EDF'));
    cd(fullfile(currentPath.path,'NPMK'));
    installNPMK();
    cd(currentPath.path);
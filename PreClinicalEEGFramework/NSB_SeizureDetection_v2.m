intervals = [3,5,10,15,30];
figure;
for rep = 1:numel(intervals)

%tic;
[p10YUPPER,p10YLOWER] = envelope(FilteredSignal,options.SampleRate*intervals(rep),'peak');
[r10YUPPER,r10YLOWER] = envelope(FilteredSignal,options.SampleRate*intervals(rep),'rms');
yUPPER = r10YUPPER + (p10YUPPER - r10YUPPER)/2;
yLOWER = r10YLOWER + (p10YLOWER + r10YLOWER)/2;
envDist = yUPPER - yLOWER;
%toc;

subplot(5,1,rep);
plot(FilteredSignal);hold on;
plot(yUPPER,'g'); plot(yLOWER,'r'); plot(envDist,'c');
title(['integrated interval = ',num2str(intervals(rep))]);
end

%remove artifacts

%Rules
%Find Spikes 
    %single waves
        %can be monopolar, or bipolar
        %envlope is highly skewed << key
        %spike can have a instantaneous/internal frequency
        %has to be bigger than some threshold << ill defined !!!!!!
        
    %spike train
        %train must be a certain length << 10 Sec
        %train can have a spike frequency
        %   or certain number of spikes
        
    %Seizure
        %train must be a certain length << 10 Sec
        %1st in train must have post baseline smaller than prebaseline << ill defined !!!!!!
        %other trains must be seperated by some time < 60 seconds
        %other trains may not have difference in pre-post baselines
        %there is a refractory period where baseline resets
        


% create envelope
[p10YUPPER,p10YLOWER] = envelope(FilteredSignal,options.SampleRate*10,'peak');
[r10YUPPER,r10YLOWER] = envelope(FilteredSignal,options.SampleRate*10,'rms');
yUPPER = r10YUPPER + (p10YUPPER - r10YUPPER)/2;
yLOWER = r10YLOWER + (p10YLOWER + r10YLOWER)/2;
envDist = yUPPER - yLOWER;

%plot
figure;
plot(FilteredSignal);hold on;
plot(yUPPER,'g'); plot(yLOWER,'r'); plot(envDist,'c');
title(['integrated interval = ',num2str(10)]);

% do clustering
rng('default');
opts = statset('Display','iter');
[idx,C,sumd,d,midx,info] = kmedoids(envDist,3,'Algorithm','Clara','Options',opts);

% are means signifigantly different?
[~,~,stats] = anova1(envDist,idx,'off');
c = multcompare(stats);
c(:,6) < 0.05


function [StateLookup,status] = NSB_GMMclusterClassification(meanSpectra,options)
% [StateLookup,status] = NSB_GMMclusterClassification(rebinPSD,idx)
%
% Inputs:
%   meanSpectra      - (matrix) spectra for each cluster
%%   idx              - (double) index output from GMM.cluster
%   clusters            - number of GMM clusters
%   options            - (struct) of options
%                           options.logfile
%
% Outputs:
%   StateLookup        - (cell) cluster asignments
%   status             - (logical) return value
%
%
% Written By David M. Devilbiss
% (devilbiss@rowan.edu)
% August 26, 2026 - Version 1.0

status = false;
NSB_GMMclusterClassificationVersion = 'AASM 2026 v3 - 8-26-2026';
StateLookup = cell(6,3); % State name; scoringSet; cluster number
StateLookup(:,1) = {'SWS2'; 'SWS1'; 'QW'; 'AW'; 'PS'; 'UNK'};
StateLookup(:,2) = {2;3;4;5;1;0};
StateLookup(:,3) = num2cell(ones(1,6)*NaN);


if nargin > 0
    try
        if ~isempty(options.LogFile)
            errorstr = ['NSB_GMMclusterClassification using : ',NSB_GMMclusterClassificationVersion];
            NSBlog(options.LogFile,errorstr);
        else
            error('NSB_GMMclusterClassification:input','Input must include meanSpectra and options valid inputs.');
            return;
        end
    catch
        error('NSB_GMMclusterClassification:input','Input must include meanSpectra and options valid inputs.');
        return;
    end
else
    error('NSB_GMMclusterClassification:input','Input must include meanSpectra and options as input.');
    return;
end

% AASM 2026 v3
try
    [~, DeltaIdx] = sortrows(meanSpectra,[-2 -3],'MissingPlacement','last'); %sort in decending order by delta power
    [~, ThetaIdx] = sortrows(meanSpectra,[-4 -5],'MissingPlacement','last'); %sort in decending order by theta power
    %[~, BetaIdx] = sortrows(meanSpectra,[-6 -7],'MissingPlacement','last'); %sort in decending order by beta power
    [~, BetaIdx] = sortrows(sum(meanSpectra(:,6:7),2) ./ sum(meanSpectra(:,4:5),2) ./ sum(meanSpectra(:,2:3),2),[-1],'MissingPlacement','last'); %sort in decending order by beta power
    [~,LowPwrIdx] = sortrows(sum(meanSpectra(:,2:end),2),[1],'MissingPlacement','last'); %sort in decending order by total power (1+ Hz)

    %% Try the 1st two easiest states to identify.
    %N3 0.5-2Hz that are > 20% of the 30 sec epoch
    if sum(meanSpectra(DeltaIdx(1),2:3),2) > sum(meanSpectra(DeltaIdx(1),5:6),2) && all(meanSpectra(DeltaIdx(1),2) > meanSpectra(DeltaIdx(1),3:end))
        %if Delta power > Beta power AND 1-3 Hz has the most power
        StateLookup{1,3} = DeltaIdx(1);
    else
        LogStr = ['Warning: NSB_GMMclusterClassification >> GMM Cannot find N3/SWS2'];
        disp(LogStr);
        NSBlog(options.LogFile,LogStr);
    end

    % Rem Sawtooth waves 2-6 Hz,LAMF w/o spindles or K-complexes
    if all(meanSpectra(ThetaIdx(1),4) > meanSpectra(ThetaIdx(1),[1:3,5:end]))
        % if the spectral peak is truely theta - Highest theta 4.5-6.5 AND higher than all other points.
        StateLookup{5,3} = ThetaIdx(1);
        LogStr = ['Info: NSB_GMMclusterClassification >> GMM found PS/R using rule 1a'];
    elseif all(meanSpectra(ThetaIdx(1),5) > meanSpectra(ThetaIdx(1),[1:3,5:end]))
        % if the spectral peak is truely theta - Highest theta 4.5-6.5 AND higher than all other points.
        StateLookup{5,3} = ThetaIdx(1);
        LogStr = ['Warning: NSB_GMMclusterClassification >> GMM found PS/R using rule 1b'];
    else
        LogStr = ['Warning: NSB_GMMclusterClassification >> GMM Cannot find PS/R'];
    end
    disp(LogStr);
    NSBlog(options.LogFile,LogStr);

    %N1 LAMF 4-7 Hz > 50% of the epoch + more power in slow Hz
    %     Delta 2+3 / Beta 6+7 (Ratio)
    if sum(meanSpectra(DeltaIdx(1),2:3),2) > sum(meanSpectra(DeltaIdx(1),5:6),2)
        %if Delta power > Beta power
        if ~ismember(DeltaIdx(1),[StateLookup{:,3}])
            %if cluster has not been identified than label it with N1
            StateLookup{2,3} = DeltaIdx(1);
            LogStr = ['Info: NSB_GMMclusterClassification >> GMM found N1/SWS1 using rule 1a'];
        elseif sum(meanSpectra(DeltaIdx(2),2:3),2) > sum(meanSpectra(DeltaIdx(2),5:6),2)
            if ~ismember(DeltaIdx(2),[StateLookup{:,3}])
                StateLookup{2,3} = DeltaIdx(2);
                LogStr = ['Info: NSB_GMMclusterClassification >> GMM found N1/SWS1 using rule 1b'];
            end
        else
            LogStr = ['Warning: NSB_GMMclusterClassification >> GMM Cannot find N1/SWS1'];
        end
    else
        LogStr = ['Warning: NSB_GMMclusterClassification >> GMM Cannot find N1/SWS1'];
    end
    disp(LogStr);
    NSBlog(options.LogFile,LogStr);

    % Waking alpha activity 8-13 Hz (with Theta)
    if isnan(StateLookup{4,3})
        if BetaIdx(1) == LowPwrIdx(1)
            %If Beta/Theta/Delta ratio is the lowest total spectral power
            if ~ismember(BetaIdx(1),[StateLookup{:,3}])
                StateLookup{4,3} = BetaIdx(1);
            else
                LogStr = ['Warning: NSB_GMMclusterClassification >> GMM Cannot find AW/W'];
                disp(LogStr);
                NSBlog(options.LogFile,LogStr);
            end
        else
            LogStr = ['Warning: NSB_GMMclusterClassification >> GMM Cannot find AW/W'];
            disp(LogStr);
            NSBlog(options.LogFile,LogStr);
        end
    end


    % Quiet Waking
    if isnan(StateLookup{3,3})
        if DeltaIdx(end-1) == LowPwrIdx(2)
            if ~ismember(LowPwrIdx(1),[StateLookup{:,3}])
                StateLookup{3,3} = LowPwrIdx(2);
            else
                LogStr = ['Warning: NSB_GMMclusterClassification >> GMM Cannot find QW/N1'];
                disp(LogStr);
                NSBlog(options.LogFile,LogStr);
            end
        else
            LogStr = ['Warning: NSB_GMMclusterClassification >> GMM Cannot find QW/N1'];
            disp(LogStr);
            NSBlog(options.LogFile,LogStr);
        end
    end

    % now try 2ndary identifications
    [~, DeltaIdx] = sortrows(meanSpectra,[-3 -2],'MissingPlacement','last'); %sort in decending order by delta power
    [~, ThetaIdx] = sortrows(meanSpectra,[-5 -4],'MissingPlacement','last'); %sort in decending order by theta power
    %[~, BetaIdx] = sortrows(meanSpectra,[-6 -7],'MissingPlacement','last'); %sort in decending order by beta power
    [~, BetaIdx] = sortrows(sum(meanSpectra(:,7:8),2) ./ sum(meanSpectra(:,4:5),2) ./ sum(meanSpectra(:,2:3),2),[-1],'MissingPlacement','last'); %sort in decending order by beta power
    [~,LowPwrIdx] = sortrows(sum(meanSpectra(:,2:end),2),[1],'MissingPlacement','last'); %sort in decending order by total power (1+ Hz)

    % Rem - Sawtooth waves 2-6 Hz,LAMF w/o spindles or K-complexes
    if all(meanSpectra(ThetaIdx(1),4) > meanSpectra(ThetaIdx(1),[2:3,5:end]))
        %  Highest theta 4.5-6.5 AND higher than other points >1Hz.
        if isnan(StateLookup{5,3}) && ~ismember(ThetaIdx(1),[StateLookup{:,3}])
            StateLookup{5,3} = ThetaIdx(1);
        end
        LogStr = ['Warning: NSB_GMMclusterClassification >> GMM found PS/R using rule 1c'];
        disp(LogStr);
        NSBlog(options.LogFile,LogStr);
    elseif all(meanSpectra(ThetaIdx(1),5) > meanSpectra(ThetaIdx(1),[2:4,6:end]))
        % Highest theta 6.5-8.5 AND higher than other points >1Hz.
        if isnan(StateLookup{5,3}) && ~ismember(ThetaIdx(1),[StateLookup{:,3}])
            StateLookup{5,3} = ThetaIdx(1);
        end
        LogStr = ['Warning: NSB_GMMclusterClassification >> GMM found PS/R using 2ndary rule'];
        disp(LogStr);
        NSBlog(options.LogFile,LogStr);
    elseif all(meanSpectra(ThetaIdx(1),4) > meanSpectra(ThetaIdx(1),[3,6:end])) || ...
            all(meanSpectra(ThetaIdx(1),5) > meanSpectra(ThetaIdx(1),[3,6:end]))
        if isnan(StateLookup{5,3}) && ~ismember(ThetaIdx(1),[StateLookup{:,3}])
            StateLookup{5,3} = ThetaIdx(1);
        end
        LogStr = ['Warning: NSB_GMMclusterClassification >> GMM found PS/R using 3rd rule'];
        disp(LogStr);
        NSBlog(options.LogFile,LogStr);
    end

    % Waking alpha activity 8-13 Hz (with Theta)
    if isnan(StateLookup{4,3})
        %If Beta/Theta/Delta ratio is the lowest total spectral power
        if ~ismember(LowPwrIdx(1),[StateLookup{:,3}])
            StateLookup{4,3} = LowPwrIdx(1);
            LogStr = ['Warning: NSB_GMMclusterClassification >> GMM found PS/R using min power rule'];
            disp(LogStr);
            NSBlog(options.LogFile,LogStr);
        end
    end
    status = true;

catch ME
    errorstr = ['ERROR: NSB_GMMclusterClassification >> ',ME.message];
    if ~isempty(ME.stack)
        errorstr = [errorstr,' Function: ',ME.stack(1).name,' Line # ',num2str(ME.stack(1).line)];
    end
    NSBlog(options.LogFile,errorstr);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Version 0.9
% % AASM 2026 v3
% if ~isempty(meanSpectra)
% %[N3idx,N1idx,QWidx,Widx,Ridx] = deal(NaN);
% %N3 0.5-2Hz that are > 20% of the 30 sec epoch
% [~, N3idx] = sortrows(meanSpectra,[-2 -3],'MissingPlacement','last'); %N3 sort in decending order by delta power
% if sum(meanSpectra(N3idx(1),2:3),2) > sum(meanSpectra(N3idx(1),5:6),2) && all(meanSpectra(N3idx(1),2) > meanSpectra(N3idx(1),3:end))
%     %Then it really is SWS2/N3
%     %N3idx = N3idx(1);
%     StateLookup{1,3} = N3idx(1);
% else
%     LogStr = ['Warning: NSB_SleepScoring >> GMM Cannot find N3/SWS'];
%     disp(LogStr);
%     NSBlog(options.LogFile,LogStr);
% end
%
% % Rem Sawtooth waves 2-6 Hz,LAMF w/o spindles or K-complexes
% % [~, Ridx] = sortrows(sum(meanSpectra(:,4:5),2),[-1],'MissingPlacement','last'); %R sort in decending order by Theta power (4.5-8.5Hz)
% [~, Ridx] = sortrows(meanSpectra,[-4 -5],'MissingPlacement','last'); %N3 sort in decending order by delta power
% %Ridx = Ridx(1);
% %StateLookup{5,3} = Ridx(1);
% if all(meanSpectra(Ridx(1),4) > meanSpectra(Ridx(1),1:3,5:end))
%     %Then it really is SWS2/N3
%     %N3idx = N3idx(1);
%     StateLookup{5,3} = Ridx(1);
% else
%     LogStr = ['Warning: NSB_SleepScoring >> GMM Cannot find PS/R'];
%     disp(LogStr);
%     NSBlog(options.LogFile,LogStr);
% end
%
% %N1 LAMF 4-7 Hz > 50% of the epoch + more power in slow Hz
% %N2 K-complex, Sleep Spindle 11-16 Hz > 50% of the epoch
% % Waking alpha activity 8-13 Hz
% [~, rowIdx] = sortrows(meanSpectra,[-4],'MissingPlacement','last'); %decending order by low Theta power (4.5-6.5Hz)
% rowIdx(find(rowIdx==StateLookup{1,3} | rowIdx==StateLookup{5,3})) = [];
%
% % if sum(~isNaN_idx) == 5 %All 5 states exist
%
%     %N1 LAMF 4-7 Hz > 50% of the epoch + more power in slow Hz
%     %Delta 2+3 / Beta 6+7 (Ratio)
%     [~, N12idx] =sortrows(sum(meanSpectra(rowIdx,2:3),2)./sum(meanSpectra(rowIdx,6:7),2),[-1],'MissingPlacement','last'); %N1 sort in decending order by delta/beta power
%     %N1idx = rowIdx(N12idx(1));
%     StateLookup{2,3} = rowIdx(N12idx(1));
%
%     % Waking alpha activity 8-13 Hz (with Theta)
%     %Widx = rowIdx(N12idx(end));
%     StateLookup{4,3} = rowIdx(N12idx(end));
%
%     %Quiet waking
%     QWidx = 1:n;
%     %QWidx([Widx,N1idx,N3idx,Ridx]) = [];
%     temp = cell2mat(StateLookup(:,3));  temp(isnan(temp))=[];
%     QWidx(temp) = [];
%     StateLookup{3,3} = QWidx;
%     if length(QWidx) > 1
%         StateLookup{3,3} = QWidx(1); %Use only the first cluster and set the second to unknown
%         LogStr = ['Warning: NSB_SleepScoring >> GMM Cannot find a single QW state'];
%         disp(LogStr);
%         NSBlog(options.LogFile,LogStr);
%     end
%
%
% % elseif sum(~isNaN_idx) == 4 % Only 4 states exist
% %     %N1 LAMF 4-7 Hz > 50% of the epoch + more power in slow Hz
% %     %Delta 2+3 / Beta 6+7 (Ratio)
% %     [~, N12idx] =sortrows(sum(meanSpectra(rowIdx,2:3),2)./sum(meanSpectra(rowIdx,6:7),2),[-1],'MissingPlacement','last'); %N1 sort in decending order by delta/beta power
% %     %N1idx = rowIdx(N12idx(1));
% %     StateLookup{2,3} = rowIdx(N12idx(1));
% %
% %     % Waking alpha activity 8-13 Hz (with Theta)
% %     %Widx = rowIdx(N12idx(end));
% %     StateLookup{4,3} = rowIdx(N12idx(end));
% %
% %     LogStr = ['Warning: NSB_SleepScoring >> GMM only found 4 states'];
% %     disp(LogStr);
% %     NSBlog(options.LogFile,LogStr);
% %
% % elseif sum(~isNaN_idx) == 3 % Only 3 states exist
% %     %Final states are SWS2, AW/PS, QW/N1
% %     %QWidx = rowIdx;
% %     StateLookup{3,3} = rowIdx;
% %
% %     LogStr = ['Warning: NSB_SleepScoring >> GMM only found 3 states'];
% %     disp(LogStr);
% %     NSBlog(options.LogFile,LogStr);
% % else
% %     LogStr = ['Warning: NSB_SleepScoring >> GMM only found 2 states'];
% %     disp(LogStr);
% %     NSBlog(options.LogFile,LogStr);
% % end
%
% % rowIdx = [N3idx,N1idx,QWidx,Widx,Ridx]; %orders the clusters by state
% % scoringSet = [2,3,4,5,1]; %scoring order sws2, sws1, wake, aw, ps
% %
% % %old
% % %[DeltaSort, rowIdx] = sortrows(meanSpectra,[-2 -3]); %sort in decending order by delta power
% % %isNaN_idx = isnan(DeltaSort(:,1));
% %
% % switch minnumComponents
% %     case 1
% %         if ~isnan(N3idx)
% %             scoringSet = [2];
% %         elseif ~isnan(Ridx)
% %             scoringSet = [4];
% %         else
% %             scoringSet = [0];
% %         end
% %     case 2
% %         scoringSet = [2,4];
% %     case 3
% %         scoringSet = [2,3,5];
% %     case 4
% %         scoringSet = [2,3,4,5];
% %     case 5
% %         scoringSet = [2,3,4,5,1]; %scoring order sws2, sws1, wake, aw, ps
% %     otherwise
% %         scoringSet = [2,3,4,5,1]; %scoring order sws2, sws1, wake, aw, ps
% % end
% %
% % %rowIdx(isNaN_idx,:) = [];
% % %DeltaSort(isNaN_idx,:) = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Version < 2026
% identify empty clusters and remove
%isNaN_idx = isnan(meanSpectra(:,1));
%meanSpectra = meanSpectra(~isNaN_idx,:);

% 2nd apply simple classification (labeling) scheme
% assign each cluster an internal state value to be used by archetecture rules and to combine epochs
% rowIdx = [N3idx,N1idx,QWidx,Widx,Ridx]; %orders the clusters by state
% scoringSet = [2,3,4,5,1]; %scoring order sws2, sws1, wake, aw, ps

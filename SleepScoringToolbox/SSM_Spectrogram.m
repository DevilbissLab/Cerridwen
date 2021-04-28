function [F,T,Pyy,validBins] = SSM_Spectrogram(Signal,window,overlap,fs,HzDiv)

Signal = Signal(:); %force to row vector
offset = (window-overlap);
nSegments = ceil(length(Signal) / offset);
winfun = hamming(window);
nFFT = fs/1/HzDiv;
validBins = false(nSegments,1);

T = [0:offset:nSegments*offset]/fs;
F = single(fs/2*linspace(0,1,nFFT/2+1)); %this is a single since there seems to be float issues (small residuals)

SigMat = zeros(nFFT,nSegments);

% Setup matrix for fft
% in Nan;s are in vector ignore
%this can be vectorized...
for curSeg = 0:nSegments-1
    if curSeg*offset+window <= length(Signal)
        SigFrag = Signal(curSeg*offset+1 : curSeg*offset+window);
    else
        SigFrag = Signal(curSeg*offset : end);
        SigFrag = [SigFrag; zeros(window-length(SigFrag),1)];
    end
    if ~any(isnan(SigFrag))
        validBins(curSeg+1) = true;
        SigFrag = SigFrag .* winfun;
        if length(SigFrag) ~= nFFT
            SigMat(:,curSeg+1) = sum(buffer(SigFrag,nFFT),2); %buffer can only take a vector
        else
            SigMat(:,curSeg+1) = SigFrag;
        end  
    else
        continue;
    end
end

yy = fft(SigMat,nFFT);
try
disp('     ... calculating power w/ conj')
clear signal SigMat;
Pyy = yy.*conj(yy) / nFFT;  % PSD = |Y|^2 same as abs(Y).^2 / n; but data is wrapped ?!?
clear yy;
Pyy = Pyy';
Pyy(:,nFFT/2+2:end) = [];
Pyy(:,2:nFFT/2+1) = 2*Pyy(:,2:nFFT/2+1);  % compensate for missing negative frequencies
catch
%Alternative Approach
try
disp('     ... calculating power w/ pow2')
clear signal SigMat;
Pyy = abs(yy)/(nFFT/2);
clear yy;
Pyy = Pyy';
Pyy(:,nFFT/2+2:end) = [];
Pyy = Pyy.^2;
catch
   disp('Can not calculate power on this matrix'); 
end
end

Tlength = length(T);
Plength = size(Pyy,1);
if Tlength > Plength
    T(Plength+1:end) = [];
else Tlength < Plength
    Pyy(Tlength+1:end,:) = []; %<< not the best solution
end



% semilogy(f,Pyy); to plot

%  %heres another way to do binning (swiped for signal proc toolbox)
%  % Make x and win into columns
% x = x(:); 
% win = win(:); 
% 
% % Determine the number of columns of the STFT output (i.e., the S output)
% ncol = fix((nx-noverlap)/(nwind-noverlap));
% 
% %
% % Pre-process X
% %
% colindex = 1 + (0:(ncol-1))*(nwind-noverlap);
% rowindex = (1:nwind)';
% xin = zeros(nwind,ncol);
% 
% % Put x into columns of xin with the proper offset
% xin(:) = x(rowindex(:,ones(1,ncol))+colindex(ones(nwind,1),:)-1);
% 
% % Apply the window to the array of offset signal segments.
% xin = win(:,ones(1,ncol)).*xin;





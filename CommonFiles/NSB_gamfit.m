function stats = NSB_gamfit(x, alpha)
% stats = NSB_gamfit(x, alpha) - fit and calaculate  statistics for an unknown gamma distribution.
%  Uses the method of moments estimators of ? and ? (a and b). Does not
%  conform to Matlab standard as a dropin replacement.
%
%
% Inputs:
%   x               - (double) vector of the raw data to be fitted.
%   alpha           - (singlton) p-values for confidence interval (e.g. 0.05, 0.01)
%
% Outputs:
%   stats         - (struct) gamma dist outputs
%       .parmhat        - (double) PARMHAT(1) and PARMHAT(2) are estimates of the 
%                           shape and scale parameters A and B, respectively as reported in matlab gamfit().
%       .mode           - (double) statistical mode of Gamma dist
%       .mean           - (double) first momment (mean) of gamma dist
%       .varience       - (double) second momment (varience) of gamma dist
%       .parmci         - (double) Vector of confidence intervals of the fitted 
%                           Gamma distrobution (returns 100(1-ALPHA) percent confidence
%                           intervals for the distribution NOT the parameter estimates.
%
% Dependencies: none.
%
% Written By David M. Devilbiss
% NexStep Biomarkers, LLC. (info@nexstepbiomarkers.com)
% June 23 2017, Version 1.0 First Release
%

%
% shape parameter k and a scale parameter ? and returns 100(1-ALPHA) percent
%   confidence intervals for the parameter estimates.

%Use Method of Moments estimates
n = numel(x);
mu=mean(x);
m2=(1/n)*sum(x.^2); % or xScale = sum(x) / n; 
kappa=mu^2/(m2-mu^2);
theta = mu/(m2-mu^2);
stats.parmhat = [kappa, theta];

stats.mode = (kappa-1)/theta;
stats.mean = kappa/theta;
stats.variance = kappa/theta^2;

%Determine Confidence intervals of the distribution.
%
CIs = [1-alpha, alpha];
q = gammaincinv(CIs,kappa);
stats.parmci = q .* theta;


% Alternatively.
% see - https://stats.stackexchange.com/questions/89230/confidence-interval-for-a-random-sample-selected-from-gamma-distribution 
% 
% %Determine new Gamma distro A
% T = n*kappa;
% Q = T/theta;
% CIs = [alpha, 1-alpha]/2;
% y = theta*exp(-theta*CIs).*(theta*CIs).^(T-1);
% cons = 1/gamma(T);
% y = cons*y;
% 
% parmci = theta*exp(-theta*alpha).*(theta*alpha).^(kappa-1);
% cons = 1/gamma(kappa);
% parmci = cons*parmci;
%this approach does not mimic Matlab 

% %unit test
%Gamma distribution with a mode = 5;
% A = 6;
% B = 1;
% data = gamrnd(A,B,100,1);
% figure
% subplot(1,1,1);plot(data);
% subplot(2,1,2);hist(data,100);
% %now estimate it matlab way:
% [parmhat, parmci] = gamfit(data, 0.01);
% A1 = parmhat(1);
% B1 = parmhat(2);
% disp(['Matlab Stats ToolBox Mode = ',num2str( (A1-1)/B1 )]);
% disp(['Matlab Gamma 99% Dist CI = ', num2str(gaminv(0.99,A1,B1)) ]);
% 
% stats = NSB_gamfit(data, 0.01);
% disp('NSB_gamfit Stats:');
% disp(stats);
% disp(['NSB_gamfit Mode = ',num2str(stats.mode )]);
% disp(['NSB_gamfit Gamma 99% Dist CI = ', num2str( stats.parmci(1) )]);



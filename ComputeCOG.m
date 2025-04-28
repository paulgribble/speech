function [COG,skew,kurt,z,f] = ComputeCOG(s,sRate,t,varargin)
%COMPUTECOG  - compute fricative spectral Center-Of-Gravity measures
%
%	usage:  [COG,skew,kurt,z,f] = ComputeCOG(s, sRate, t, ...)
%
% given signal vector S sampled at SRATE Hz computes spectral center of gravity 
% measures at offset time T (secs) using the methods of Forrest et al. (1988) 
% applied to a multitapered power spectral density estimate centered on T
%
% returns spectral moments M1 (COG), M3 (SKEWness), and M4 (KURTosis)
% optionall returns power spectrum Z sampled at frequencies F
% plots spectrum if no return arguments requested
%
% Moments describe how a function differs from a normal Gaussian distribution.  To use 
% moments to describe a fricative, its spectrum is first converted to a probability 
% distribution by dividing the power at each frequency component P(k) by the summed
% power of all components; NP = sum(P(1:N)).  The first 4 moments are then computed as: 
%  M1 = f(1)*NP(1) + ... + f(N)*NP(N)  => weighted spectral mean (COG)
%  M2 = (f(1)-M1)^2*NP(1) + ... + (f(N)-M1)^2*NP(N)  => variance around M1
%  M3 = (f(1)-M1)^3*NP(1) + ... + (f(N)-M1)^3*NP(N)  => spectrum skewness
%  M4 = (f(1)-M1)^4*NP(1) + ... + (f(N)-M1)^4*NP(N)  => spectrum kurtosis
% SKEWness and KURTosis are normalized to provide dimensionless parameters consistent
% across individual speaker differences:
%  SKEW = M3 / M2^1.5
%  KURT = M4 / M2^2 - 3
% for more details see Forrest et al. (1988) and Shadle (2023)
%
% optional 'NAME',VALUE input arguments (defaults in {}):
%  NTAPER - number of Slepian tapers averaged for the PSD estimate: {7}
%  PREEMP - audio pre-emphasis (0-1): {1}
%  WSIZE  - analysis window around T (ms): {50}
%
% Refs
% Forrest K, Weismer G, Milenkovic P, & Dougall R. (1988) "Statistical analysis of 
%   word-initial voiceless obstruents:  preliminary data." JASA, 84, 115-123.
% Shadle C. (2023). “Alternatives to moments for characterizing fricatives: Reconsidering 
%   Forrest et al. (1988),” JASA, 153(2), 1412–26.

% mkt 01/09
% mkt 06/16 use pmtm (multitaper spectrum)
% mkt 03/25 facelift
% mkt 04/25 fix z < 0 inversion bug (thanks to P. Gribble)

% defaults
nTaper = 7;		% number of tapers averaged for the PSD estimate
preEmp = 1;		% pre-emphasis
wSize = 50;		% analysis window length (ms)

% parse parameters
if nargin < 3, help ComputeCOG; return; end
p = inputParser;
addParameter(p,'nTaper',nTaper);
addParameter(p,'preEmp',preEmp);
addParameter(p,'wSize',wSize);
parse(p,varargin{:});
cellfun(@(x) assignin('caller', x, p.Results.(x)), fieldnames(p.Results));

% ensure vector of monodimensional samples
if min(size(s)) > 1, error('expecting vector of monodimensional samples'); end
s = s(:);
nSamps = length(s);

% pre-emphasize
if preEmp > 0, s = filter([1 -preEmp], 1, s); end

% extract analysis window
ts = floor(t*sRate)+1;				% sample offset
wSize = round(wSize/1000*sRate);	% -> samps
head = ts - round(wSize/2);
if head < 1, head = 1; end
tail = head + wSize - 1;
if tail > nSamps
	tail = nSamps;
	head = tail - wSize + 1;
end
s = s(head:tail);

% compute tapered power spectrum
nw = (nTaper + 1) / 2;
[z,f] = pmtm(s,nw,[],sRate);
z = 10 * log10(z);

% compute spectral moments
z = z - min(z);	% P. Gribble: ensure spectral orientation retained for z < 0
p = z ./ sum(z);		% normalized power
COG = sum(f .* p);		% weighted spectral mean (COG)
CF = f - COG;			% centered frequencies
M2 = sum(CF.^2 .* p);	% variance around M1
M3 = sum(CF.^3 .* p);	% skewness
M4 = sum(CF.^4 .* p);	% kurtosis

% adjust skewness and kurtosis for generalization across shifts in center frequency 
% and frequency scale that can occur between speakers producing the same sound
skew = M3/M2^1.5;
kurt = M4/M2^2 - 3;

if nargout > 0, return; end

% plot
figure
title(tiledlayout('vertical'),inputname(1),'interpreter','none','fontsize',20)
ah = nexttile;
ht = ([head tail]-1)/sRate;
x = linspace(ht(1),ht(2),wSize)';
plot(x,s)
y = max(abs(s));
line([t t],[-y y],'color','r','linewidth',1.5)
set(ah,'xlim',ht,'xgrid','on','ygrid','on')
xlabel('secs')
title(sprintf('t = %.3f',t),'fontweight','normal','fontsize',14)

ah = nexttile([2 1]);
plot(f/1000,z,'color',[0 .6 0])
y = [min(z)-range(z)/5 max(z)+range(z)/5];
line([COG COG]/1000,y,'color','r','linewidth',1.5)
set(ah,'xlim',f([1 end])/1000,'xgrid','on','ygrid','on')
xlabel('kHz') ; ylabel('dB')
title(sprintf('COG: %.0f Hz  SKEW: %.2f  KURT: %.2f',COG,skew,kurt),'fontweight','normal','fontsize',14)

clear COG skew kurt

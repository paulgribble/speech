%% MUNGEDATA  - find COG measures

clear ; close all

% loop over list of audio files
fl = dir('*.wav');
fl(cell2mat({fl.isdir})) = [];
fl = {fl.name}';
nFiles = length(fl);
wSize = 30;					% RMS and ZC window size (ms)
RMSthr = .05;				% low energy detection threshold

cog = zeros(nFiles,2);		% sibilant measures (source, shifted)
skew = cog; kurt = cog;
lat = zeros(nFiles,1);		% shifter latency (ms)
TARGET = {};				% stimulus target
SHIFT = zeros(nFiles,2);	% shifted or not

for fi = 1 : nFiles

% load the data
	fn = fl{fi};
	t = split(fn,'_');
	TARGET{end+1,1} = t{2};
	if isequal(t{3},'E'), SHIFT(fi,:) = [1 1]; end	% "E" is shifted (=1)
	[s,sr] = audioread(fl{fi});
	source = s(:,1);			% what they said
	shifted = s(:,2);			% what they heard
	nSamps = length(source);

% align the data
	[xc,lags] = xcorr(shifted, source);
	[~,k] = max(xc);
	offs = lags(k);				% delay of shifted audio w.r.t. source (samps)
	lat(fi) = 1000*(offs-1)/sr;	% latency in ms
	shifted = [shifted(offs+1:end) ; zeros(offs,1)];
	
% compute RMS and zero crossing rate
	ws = round(wSize*sr/1000);
	rms = smooth(envelope(source,ws,'rms'),ws);
	rms = rms ./ max(rms);
	ws2 = ceil(ws/2);
	s = [zeros(ws2,1) ; source ; zeros(ws2,1)];
	zc = filter(rectwin(ws),1,[0;abs(diff(s>=0))]);
	zc = smooth(zc(ws2*2+1:end),ws);
	zc = zc ./ max(abs(zc));
	zc(rms < RMSthr) = 0;		% drop low energy regions
	idx = find(zc > .5);
	hts = idx([1 end]);			% sibilant region (samps)
	ht = (hts-1)/sr;			%                 (ms)

% average 5 values around center of sibilant region
	t = [-100 -50 0 50 100] + mean(ht);		% ms
	[c,s,k] = ComputeCOG(source,sr,t);
	cog(fi,1) = mean(c);		% source
	skew(fi,1) = mean(s);
	kurt(fi,1) = mean(k);
	[c,s,k] = ComputeCOG(shifted,sr,t);
	cog(fi,2) = mean(c);		% shifted
	skew(fi,2) = mean(s);
	kurt(fi,2) = mean(k);

% progress
	fprintf('.')
end
fprintf('\n')

% make table
FNAME = cellfun(@(s)s(1:end-4),fl,'UniformOutput',false);
FNAME = reshape([FNAME,FNAME]',nFiles*2,1);
TARGET = reshape([TARGET,TARGET]',nFiles*2,1);
TARGET = categorical(TARGET);
SHIFT = categorical(reshape(SHIFT',nFiles*2,1));
SRC = reshape(repmat({'SOURCE','SHIFTED'},nFiles,1)',nFiles*2,1);
SRC = categorical(SRC(:)); 
SRC = reordercats(SRC,{'SOURCE','SHIFTED'});
COG = reshape(cog',nFiles*2,1);
SKEW = reshape(skew',nFiles*2,1);
KURT = reshape(kurt',nFiles*2,1);

T = table(FNAME,TARGET,SHIFT,SRC,COG,SKEW,KURT);

%% plot COG

targs = categorical({'she','shoe'});
vars = {'COG','SKEW','KURT'};

figure('color','w')
title(tiledlayout('horizontal'),'Spectral measures','fontsize',20)

for vi = 1 : length(vars)

	t = T(T.TARGET=='she' | T.TARGET=='shoe',:);
	vv = t.(vars{vi});
	if vi==1, vv = vv/1000; end		% -> kHz
	v = vv(t.SHIFT=='0' & t.SRC=='SOURCE');
	tt = t.TARGET(t.SHIFT=='0' & t.SRC=='SOURCE');
	s = repmat({'BASELINE'},length(v),1);
	v = [v ; vv(t.SHIFT=='1')];
	tt = [tt ; t.TARGET(t.SHIFT=='1')];
	s = [s ; t.SRC(t.SHIFT=='1')];
	s = categorical(s);
	s = reordercats(s,{'BASELINE','SOURCE','SHIFTED'});

	nexttile
	boxchart(s,v,'GroupByColor',tt,'notch',false)
	if vi==1, legend(unique(tt),'fontsize',14,'location','northwest'); end
	box on ; grid on
	set(gca,'fontsize',14)
	if vi==1, ylabel('kHz'); end
	title(vars(vi),'fontweight','normal','fontsize',16)

end

%% stats

% comparison of baseline vs. shifted source
%   shift significantly lowers COG (t = -2.4 *)
%   no effect of target or interaction with shift

t = T(T.SRC=="SOURCE" & (T.TARGET=='she' | T.TARGET=='shoe'),:);
t.TARGET = removecats(t.TARGET);	% drop unused targets
for vi = 1 : length(vars)
	m = fitlm(t,sprintf('%s ~ SHIFT * TARGET', vars{vi}))
end

% Linear regression model (N=40, DOF=36):
%   DV ~ 1 + TARGET*SHIFT
% main effect of SHIFT:
%   DV     t     p
%  COG  -2.37  0.023
%  SKEW  2.09  0.044
%  KURT -2.15  0.038

% git clone --recurse-submodules https://github.com/sccn/eeglab.git
% then also install biosig extension via eeglab menus

%% fresh start
clear all

%% load eeglab
addpath('eeglab')

% Launch EEGLAB
[ALLEEG,EEG,CURRENTSET,ALLCOM] = eeglab;

%% load a datafile
fname = 'TESTSM1P05.bdf';
EEG = pop_biosig(fname);
EEG_raw = EEG.data;

%%  filter the data
EEG = pop_eegfiltnew(EEG, 'locutoff',0.1); % high-pass filter 0.1 Hz
EEG = pop_eegfiltnew(EEG, 'hicutoff',30);  % low-pass filter   30 Hz

chan_names = string({EEG.chanlocs.labels});

% re-reference to the average of T7 & T8 (channels 7 & 24)
%EEG.data = EEG.data - repmat(mean(EEG.data([7,24],:),1),32,1);

% re-reference to the average of P7 & P8 (channels 11 & 20)
EEG.data = EEG.data - repmat(mean(EEG.data([11,20],:),1),32,1);

% re-reference to whole head
% note we excluded channel 28 here
%EEG.data = EEG.data - repmat(mean(EEG.data([1:27,29:32],:),1),32,1);


% bad channel rejection
% noise rejection
% ICA







%% CUSTOM CODE TO DO THE WINDOWING/AVERAGING BY EPOCH

% identify events
e = [EEG.event.type];
e_latency = [EEG.event.latency];
e96_i = find(e==96);
e96_latency = e_latency(e96_i);
n_96 = length(e96_i);

if exist("i_boundaries.txt", "file")
    load i_boundaries.txt
else
    % interactively click on boundaries
    n_epochs = 7;
    n_boundaries = n_epochs - 1;
    figure
    plot(EEG_raw');
    hold on
    xline(e_latency, '-k')
    title(sprintf("click on %d boundaries from L to R", n_boundaries))
    drawnow
    pause(0.2)
    i_boundaries = ginput(n_boundaries);
    i_boundaries = [1, round(i_boundaries(:,1))', size(EEG_raw,2)];
end
disp(i_boundaries)
disp(diff(i_boundaries)/EEG.srate)

% save boundaries to a file boundaries.txt
save i_boundaries.txt i_boundaries -ascii

%%
% chop up into windows
t_before = 0.200; % seconds
t_after  = 0.800; % seconds
i_before = round(t_before * EEG.srate);
i_after  = round(t_after  * EEG.srate);
i_win    = i_before + i_after;
WIN = zeros(EEG.nbchan, i_win, n_96);
for i=1:n_96
    i1 = e96_latency(i)-i_before;
    i2 = e96_latency(i)+i_after-1;
    window = EEG.data(:,i1:i2);
    baseline = repmat(mean(window(:,1:i_before),2),1,i_win);
    WIN(:,:,i) = window - baseline; % baseline correct
end
t_win = (1:i_win)/EEG.srate - t_before;

% average window within epochs 1-7
WINm = zeros(EEG.nbchan, i_win, 7); % channel x ERP x epoch
EPOCH_INDICES = {}; % to store sample times of each stimulus in each epoch
for i_epoch = 1:7
    ii = find((e96_latency>i_boundaries(i_epoch)) & (e96_latency<i_boundaries(i_epoch+1)));
    WINm(:,:,i_epoch) = mean(WIN(:,:,ii),3);
    EPOCH_INDICES{i_epoch} = e96_latency(ii);
end

% plot all channels all epoch means
my_fig = tiledlayout(8, 4, 'TileSpacing', 'compact', 'Padding', 'compact');
for i=1:EEG.nbchan
    nexttile;
    plot(t_win*1000, squeeze(WINm(i,:,:)))
    hold on
    plot([0,0],get(gca,'ylim'),'r-','linewidth',0.5)
    plot(get(gca,'xlim'),[0,0],'r--','linewidth',0.5)
    xlim([-t_before,t_after]*1000)
    grid on
    box off
    title(chan_names(i))
    if (i>=29)
        xlabel('TIME (MS)')
    end
    if (mod(i,4)==1)
        ylabel('ERP (uV)')
    end
end
title(my_fig, fname, 'FontSize', 16, 'FontWeight', 'bold', 'Interpreter', 'None');
figname = replace(fname,'.bdf','_epochs.png');
exportgraphics(gcf, figname, 'Resolution', 300);  % 300 DPI

% store the epoch sample indices in a .csv file
epoch_table = [];
for i=1:7
    epoch_table = [epoch_table ; [EPOCH_INDICES{i}', repmat(i,length(EPOCH_INDICES{i}),1)]];
end
T = array2table(epoch_table, 'VariableNames', {'sample', 'epoch'});
csv_fname = replace(fname,'.bdf','_epochs.csv');
writetable(T, csv_fname);

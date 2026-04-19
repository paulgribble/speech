%% load an audio file
fdir = "/Users/plg/Library/CloudStorage/Dropbox/data/julia_speech/speech/Exp_behav/e/TEST1S14/";
fname = 'TEST1SM14_she_E_B01_R11_0099_01.wav';
[y,Fs] = audioread(fullfile(fdir, fname));

%% compute spectralCentroid using MATLAB's function
my_output = spectralCentroid(y,Fs);

%% generate a time vector given the window size and overlap defaults of spectralCentroid
win_size = round(Fs * 0.03);
overlap  = round(Fs * 0.02);
hop_size = win_size - overlap;  % = round(Fs * 0.01)
t_win = ((0:size(my_output,1)-1) * hop_size + win_size/2) / Fs;

%% plot the spectral centroid over time
plot(t_win,my_output)
grid on
xlabel('TIME (s)')
ylabel('SPECTRAL CENTROID FREQUENCY (Hz)')

%% load the sibilant scored file and identify the row for the above .wav file
fname_scored = '/Users/plg/Library/CloudStorage/Dropbox/data/julia_speech/speech/Exp_behav/e/TEST1S14_scored.csv';
trials_scored = readtable(fname_scored, "Delimiter",',');
myrow = trials_scored(strcmp(trials_scored.filename, 'TEST1SM14_she_E_B01_R11_0099_01.wav'), :);

%% compute sib_start and sib_end in units of time windows as from spectralCentroid
sib_start_t = myrow.sib_start / Fs;
sib_end_t = myrow.sib_end / Fs;
sib_start_win = max(find(t_win<=sib_start_t)) + 2;
sib_end_win = max(find(t_win<=sib_end_t)) - 2;

%% compute mean centroid over sib_start to sib_end
centroid_means = mean(my_output(sib_start_win:sib_end_win,:));

%% plot the sib_start and sib_end and overlay centroid means
hold on
plot(t_win([sib_start_win,sib_start_win]),get(gca,'ylim'),'m--')
plot(t_win([sib_end_win,sib_end_win]),get(gca,'ylim'),'m--')
text(sib_start_t+0.35, centroid_means(1), sprintf("mean = %.0f Hz", centroid_means(1)), 'color','b')
text(sib_start_t+0.35, centroid_means(2), sprintf("mean = %.0f Hz", centroid_means(2)), 'color','r')

function out = go_extract(fname_scored_pts)

% go_extract : Given a filename of a .csv file produced by go_score.m,
% go_extract will load each .wav file listed in the .csv file, and use the
% value of the scoredpoints column to compute COG measures for the
% microphone and headphone audio signals, and store all data in a new .csv
% file called <fname>_extracted.csv

if nargin==1
    noPathGiven = true;
else
    noPathGiven = false;
end

% read in .csv file
T = readtable(fname_scored_pts, 'Delimiter', ',', 'ReadVariableNames', true, 'TextType', 'string');

% determine number of files
n_wav = size(T,1);

% set up arrays to store variables
filedir = string.empty;
filename = string.empty;
participant = string.empty;
trial_num = zeros(1,n_wav);
token = string.empty;
token_start = zeros(1,n_wav);
token_end = zeros(1,n_wav);
sib_centre = zeros(1,n_wav);
sib_cog = zeros(1,n_wav);
sib_cog_fb = zeros(1,n_wav);
sib_skew = zeros(1,n_wav);
sib_kurt = zeros(1,n_wav);
sib_skew_fb = zeros(1,n_wav);
sib_kurt_fb = zeros(1,n_wav);
fb_delay = zeros(1,n_wav);


parfor i=1:n_wav
    fname = T.filedir(i) + "/" + T.filename(i);
    filedir(i) = T.filedir(i);
    filename(i) = T.filename(i);
    % load in the .wav file
    fprintf("file %3d/%3d : %s ... \n", i, n_wav, fname);
    [y,Fs] = audioread(fname);
    y_mic = y(:,1); % from microphone
    y_ear = y(:,2); % played over headphones
    % extract scored point from .csv file
    i_scored = T.scoredpoints(i);

    if (i_scored>0)

        % compute COG measures for microphone signal
        % averaging over several windows around the scored point
        windowOffsets = [-10, -8, -6, -4, -2, 0, 2, 4, 6, 8, 10] / 1000; % ms to seconds
        t = i_scored/Fs + windowOffsets;
        windowSize = 50; % ms
        [c1,skew1,kurt1,z1,f1] = ComputeCOG(y_mic, Fs, t, "WSIZE", windowSize);
        
        % estimate time lag from microphone to headphones
        [r,lags] = xcorr(y_mic,y_ear);
        [yy,ii] = max(r);
        fb_delay_t = -lags(ii)/Fs;
        fb_delay_s = -lags(ii);
        fb_delay(i) = fb_delay_t;
        
        % compute COG measures for headphone signal
        [c2,skew2,kurt2,z2,f2] = ComputeCOG(y_ear, Fs, t+fb_delay_t, "WSIZE", windowSize);
        
        sib_centre(i) = i_scored/Fs;
        sib_cog(i) = mean(c1);
        sib_cog_fb(i) = mean(c2);
        sib_skew(i) = mean(skew1);
        sib_skew_fb(i) = mean(skew2);
        sib_kurt(i) = mean(kurt1);
        sib_kurt_fb(i) = mean(kurt2);

    else
        sib_centre(i) = NaN;
        fb_delay(i) = NaN;
        sib_cog(i) = NaN;
        sib_cog_fb(i) = NaN;
        sib_skew(i) = NaN;
        sib_skew_fb(i) = NaN;
        sib_kurt(i) = NaN;
        sib_kurt_fb(i) = NaN;
    end

    f = T.filename(i);
    f_parts = strsplit(f,'_');
    trial_num(i) = str2num(f_parts{6});
    participant(i) = f_parts{1};
    token(i) = f_parts{2};

end

filedir = filedir';
filename = filename';
participant = participant';
trial_num = trial_num';
token = token';
sib_centre = sib_centre';
sib_cog = sib_cog';
sib_cog_fb = sib_cog_fb';
fb_delay = fb_delay';
sib_skew = sib_skew';
sib_skew_fb = sib_skew_fb';
sib_kurt = sib_kurt';
sib_kurt_fb = sib_kurt_fb';

out_table = table(filedir, filename, participant, trial_num, token, sib_centre, sib_cog, sib_cog_fb, sib_skew, sib_skew_fb, sib_kurt, sib_kurt_fb, fb_delay);

[~, name, ext] = fileparts(fname_scored_pts);
name = replace(name, '_scored', '');
csv_filename = name + "_extracted" + ext;

writetable(out_table, csv_filename, "WriteVariableNames",true);

fprintf("wrote to %s\n", csv_filename);

if nargout>0
    out = out_table;
end

end
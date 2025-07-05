function out = go_score1new(clicks)

selpath = uigetdir;
if isfolder(selpath)
    file_list = dir(selpath + "/" + "*.wav");
end
n_wav = length(file_list);
fprintf("found %d .wav files in %s\n", n_wav, selpath)

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

for i=1:n_wav
    fprintf("file %3d/%3d : %s ... \n", i, n_wav, file_list(i).name);
    f = file_list(i).name;
    f_parts = strsplit(f,'_');
    trial_num(i) = str2num(f_parts{6});
    participant(i) = f_parts{1};
    token(i) = f_parts{2};
    fname = file_list(i).folder + "/" + f;
    filedir(i) = file_list(i).folder;
    filename(i) = f;
    [y,Fs] = audioread(fname);
    y1 = y(:,1); % from microphone
    y2 = y(:,2); % played over headphones
    t = 0:(1/Fs):(size(y,1)/Fs); t = t(1:end-1)';
    sound(y1, Fs);
    g1 = plotWithSkipButton(y1,t,Fs,file_list(i).name);
    sib_centre(i) = g1;
    if ~isnan(g1)
        [c1,skew1,kurt1,z1,f1] = ComputeCOG(y(:,1),Fs,g1);
        [r,lags] = xcorr(y(:,1),y(:,2));
        [yy,ii] = max(r);
        fb_delay_i = -lags(ii)/Fs;
        fb_delay(i) = fb_delay_i;
        g2 = g1 + fb_delay_i;
        [c2,skew2,kurt2,z2,f2] = ComputeCOG(y(:,2),Fs,g2);
        c1_msg = sprintf('the spectral centroid at the mic is        %.0f Hz', round(c1));
        c2_msg = sprintf('the spectral centroid at the headphones is %.0f Hz', round(c2));
        fb_delay_msg = sprintf('the feedback delay is %.3f ms', fb_delay_i*1000);
        disp(c1_msg)
        disp(c2_msg)
        disp(fb_delay_msg)
        sib_cog(i) = c1;
        sib_cog_fb(i) = c2;
        sib_skew(i) = skew1;
        sib_skew_fb(i) = skew2;
        sib_kurt(i) = kurt1;
        sib_kurt_fb(i) = kurt2;
    else
        sib_cog(i) = NaN;
        sib_cog_fb(i) = NaN;
        sib_skew(i) = NaN;
        sib_skew_fb(i) = NaN;
        sib_kurt(i) = NaN;
        sib_kurt_fb(i) = NaN;
        fb_delay(i) = NaN;
    end
    drawnow
    pause(0.350)
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

csv_filename = input('ENTER FILENAME FOR .csv FILE: ',"s");
writetable(out_table, csv_filename);

i_she  = find(out_table.token=='she');
i_shoe = find(out_table.token=='shoe');
i_see  = find(out_table.token=='see');
i_sue  = find(out_table.token=='sue');

f1 = figure;
hold on
plot(out_table.trial_num(i_she), out_table.sib_cog(i_she),'bs')
plot(out_table.trial_num(i_shoe), out_table.sib_cog(i_shoe),'bo')
plot(out_table.trial_num(i_see), out_table.sib_cog(i_see),'rs')
plot(out_table.trial_num(i_sue), out_table.sib_cog(i_sue),'ro')
plot(out_table.trial_num(i_she), out_table.sib_cog_fb(i_she),'b.')
plot(out_table.trial_num(i_shoe), out_table.sib_cog_fb(i_shoe),'b.')
plot(out_table.trial_num(i_see), out_table.sib_cog_fb(i_see),'r.')
plot(out_table.trial_num(i_sue), out_table.sib_cog_fb(i_sue),'r.')
legend({'/she/','/shoe/','/see/','/sue/','/she/ fb','/shoe/ fb','/see/ fb','/sue/ fb'}, 'location','southeast')
grid on
xlabel('TRIAL NUMBER')
ylabel('SIBILANT COG (Hz)')
title(out_table.filedir(1), 'interpreter','none')
fig_fname = strsplit(csv_filename,'.');
fig_fname = fig_fname(1) + ".png";
saveas(f1, fig_fname)


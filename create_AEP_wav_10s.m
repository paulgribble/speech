
noise_burst_rise    =     0.015 ;      % rise time (sec)
noise_burst_hold    =    10.050 ;      % plateau time (sec)
sample_rate         = 44100.000 ;      % sample rate (Hz)
file_name           = "test_sound_10s.wav";

rise_samples = round(noise_burst_rise * sample_rate);
hold_samples = round(noise_burst_hold * sample_rate);
noise_burst_samples = rise_samples + hold_samples + rise_samples;
noise_burst_dur = noise_burst_samples / sample_rate;

mask = zeros(noise_burst_samples,1);
mask_hanning = hanning(rise_samples * 2);
mask(1:rise_samples) = mask_hanning(1:rise_samples);
mask(rise_samples:rise_samples+hold_samples) = 1;
mask(rise_samples+hold_samples+1:end) = mask_hanning(rise_samples+1:end);

fprintf("creating %.3f sec of audio ...\n", noise_burst_dur)

% repeat noise bursts at noise_burst_freq
sound_array = zeros(noise_burst_dur * sample_rate,1);
sound_array_samples = length(sound_array);
hnoise = pinknoise(noise_burst_samples); % pink noise (1/f power)
hnoise = hnoise./max(abs(hnoise));       % normalize to [-1,1]
sound_array = hnoise .* mask;            % apply hanning window mask

% Create stereo array: duplicate sound_array into two channels
stereo_array = [sound_array, sound_array];

fprintf("saving %s (stereo) ...\n", file_name)
audiowrite(file_name, stereo_array, sample_rate, 'BitsPerSample', 16);



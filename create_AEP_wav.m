
noise_burst_rise    =     0.015 ;      % rise / fall time (sec)
noise_burst_hold    =     0.050 ;      % plateau time (sec)
noise_burst_freq    =     1.000 ;      % noise burst repeat frequency (Hz)
file_duration       =   101.000 ;      % total duration of audio file (sec)
sample_rate         = 44100.000 ;      % sample rate (Hz)
file_name           = "test_sound.wav";

rise_samples = round(noise_burst_rise * sample_rate);
hold_samples = round(noise_burst_hold * sample_rate);
noise_burst_samples = rise_samples + hold_samples + rise_samples;
noise_burst_dur = noise_burst_samples / sample_rate;
noise_burst_episode_samples = round(noise_burst_freq * sample_rate);

mask = zeros(noise_burst_samples,1);
mask_hanning = hanning(rise_samples * 2);
mask(1:rise_samples) = mask_hanning(1:rise_samples);
mask(rise_samples:rise_samples+hold_samples) = 1;
mask(rise_samples+hold_samples+1:end) = mask_hanning(rise_samples+1:end);

% create pink noise (1/f noise)
noise_array = pinknoise(file_duration * sample_rate);

fprintf("creating %.3f sec of audio ...\n", file_duration)
fprintf("%.0f ms noise bursts repeating at %.1f Hz ...\n", noise_burst_dur*1000,noise_burst_freq)

% create hanning window repeating mask
mask_array = zeros(size(noise_array));
sound_array_samples = length(noise_array);
i = noise_burst_episode_samples;
while ((i + noise_burst_episode_samples - 1) < sound_array_samples)
	mask_array(i:i+noise_burst_samples-1) = mask;
	i = i + noise_burst_episode_samples;
end

% apply hanning mask
sound_array = noise_array .* mask_array;

% normalize to [-1,1]
sound_array = sound_array ./ max(abs(sound_array));


fprintf("saving %s ...\n", file_name)
audiowrite(file_name,sound_array,sample_rate,'BitsPerSample',16);



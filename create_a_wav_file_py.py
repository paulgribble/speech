# python3.13 -m venv .venv
# source .venv/bin/activate
# python3.13 -m pip install -U pip
# pip install numpy scipy matplotlib

import numpy as np
import scipy as sp
import matplotlib.pyplot as plt

noise_burst_rise    = 0.010     # rise / fall time (sec)
noise_burst_hold    = 0.030     # plateau time (sec)
noise_burst_freq    = 1.0       # noise burst repeat frequency (Hz)
file_duration       = 90.0      # total duration of audio file (sec)
sample_rate         = 44100     # sample rate (Hz)
file_name           = "test_sound.wav"

rise_samples = int(noise_burst_rise * sample_rate)
hold_samples = int(noise_burst_hold * sample_rate)
noise_burst_samples = rise_samples + hold_samples + rise_samples
noise_burst_dur = noise_burst_samples / sample_rate
noise_burst = np.random.uniform(-1,1,noise_burst_samples) # random samples over full range
noise_hanning = np.hanning(rise_samples * 2)
noise_burst[0:rise_samples] = noise_burst[0:rise_samples] * noise_hanning[0:rise_samples]
noise_burst[rise_samples+hold_samples:] = noise_burst[rise_samples+hold_samples:] * noise_hanning[rise_samples:]
noise_burst_episode_samples = int(noise_burst_freq * sample_rate)

print(f"creating {file_duration:.3f} sec of audio ...")
print(f"{noise_burst_dur*1000:.0f} ms noise bursts repeating at {noise_burst_freq:.1f} Hz")
sound_array_samples = int(file_duration * sample_rate)
sound_array = np.zeros(sound_array_samples)
i = noise_burst_episode_samples
while ((i + noise_burst_episode_samples - 1) < sound_array_samples):
	sound_array[i:i+noise_burst_samples] = noise_burst
	i += noise_burst_episode_samples

# convert to 16 bit int format
sound_array = np.int16(sound_array * 32767)

# create stereo signal: same in both L and R channels
stereo_array = np.column_stack((sound_array, sound_array))

print(f"saving {file_name} (stereo)")
sp.io.wavfile.write(file_name, sample_rate, stereo_array)


# Read the WAV file (stereo: shape = [samples, 2])
sample_rate, y = sp.io.wavfile.read(file_name)

# Check shape
if y.ndim != 2 or y.shape[1] != 2:
    raise ValueError("Expected a stereo WAV file with 2 channels")

# Split channels
left_channel = y[:, 0]
right_channel = y[:, 1]

# Compute spectrograms
f_L, t_L, Sxx_L = sp.signal.spectrogram(left_channel, fs=sample_rate, nfft=1024)
f_R, t_R, Sxx_R = sp.signal.spectrogram(right_channel, fs=sample_rate, nfft=1024)

# Plot both
spectrogram_filename = "spectrogram_stereo.png"
fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(8, 6), sharex=True)

pcm1 = ax1.pcolormesh(t_L, f_L, Sxx_L, shading='gouraud')
ax1.set_title('Left Channel')
ax1.set_ylabel('Frequency (Hz)')

pcm2 = ax2.pcolormesh(t_R, f_R, Sxx_R, shading='gouraud')
ax2.set_title('Right Channel')
ax2.set_xlabel('Time (s)')
ax2.set_ylabel('Frequency (Hz)')

fig.suptitle(file_name)
plt.tight_layout()
plt.subplots_adjust(top=0.9)  # make room for title

# Save figure
print(f"saving spectrogram {spectrogram_filename}")
fig.savefig(spectrogram_filename, dpi=300)



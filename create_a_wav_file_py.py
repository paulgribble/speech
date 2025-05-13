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
file_duration       = 5.0       # total duration of audio file (sec)
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

print(f"saving {file_name}")
sp.io.wavfile.write(file_name, sample_rate, sound_array)


# read a .wav file and play it over the sound device

sample_rate, y = sp.io.wavfile.read(file_name)

# plot a spectrogram

spectrogram_filename = "spectrogram.png"
t = np.arange(len(y)) / sample_rate
f,t,Sxx = sp.signal.spectrogram(y, fs=sample_rate, nfft=1024)
fig = plt.figure(figsize=(6,4))
plt.pcolormesh(t,f,Sxx)
plt.xlabel('TIME (s)')
plt.ylabel('FREQUENCY (Hz)')
plt.title(file_name)
plt.tight_layout()
print(f"saving spectrogram {spectrogram_filename}")
fig.savefig(spectrogram_filename, dpi=300)


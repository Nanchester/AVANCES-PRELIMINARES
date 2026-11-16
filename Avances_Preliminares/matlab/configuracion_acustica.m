function cfg = configuracion_acustica()
% Parametros comunes. No modifica datos de entrada ni la instalacion MATLAB.
cfg.schema_version = 1;
cfg.root = fileparts(fileparts(mfilename('fullpath')));
cfg.output = fullfile(cfg.root,'resultados_matlab');
cfg.seed = 42;
cfg.fs_expected = 16000;
cfg.samples_expected = 64000;
cfg.bits_expected = 16;
cfg.window = 'Hann periodica: 0.5-0.5*cos(2*pi*n/L)';
cfg.remove_global_dc_spectral = true;
cfg.spectral_min_hz = 20;
cfg.stft_window_seconds = 0.025;
cfg.stft_hop_seconds = 0.010;
cfg.stft_fft_length = 1024;
cfg.mel_bands = 40;
cfg.mfcc_coefficients = 13;
cfg.power_floor = 1e-12;
cfg.mel_formula = 'HTK: 2595*log10(1+f/700); 40 triangulos sin normalizacion de area';
cfg.mel_power = 'Integral discreta PSD unilateral por filtro: H*PSD*df, unidades FS^2';
cfg.fft_amplitude = 'abs(FFT(x_dc.*w))/sum(w); duplicar bins interiores unilaterales';
cfg.psd = 'abs(FFT(x_dc.*w))^2/(fs*sum(w.^2)); duplicar bins interiores, FS^2/Hz';
cfg.spectral_moments = 'Media y desviacion frecuencial ponderadas por PSD, 20 Hz hasta Nyquist';
cfg.flatness = 'Media geometrica/media aritmetica PSD en banda; piso relativo max(PSD)*1e-12';
cfg.zcr = 'Cruces de signo de x original (cero asignado no negativo)/(N-1), cruces/muestra';
cfg.dbfs = 'RMS dBFS=20*log10(RMS/1); potencia dB=10*log10(P/1); no calibrado en dB SPL';
cfg.mfcc_fallback = 'DCT-II ortonormal de ln(potencia Mel), coeficientes c0..c12';
cfg.png_dpi = 300;
cfg.figure_inches = [12 7.5];
cfg.font = 'Arial';
cfg.font_size = 10;
cfg.stft_color_db = [-110 -20];
cfg.mel_color_db = [-100 0];
cfg.histogram_rms_edges = -80:5:5;
cfg.save_mfcc_frames = true;
cfg.pdf_note = 'Texto y curvas vectoriales; espectrogramas son imagenes raster incrustadas en PDF';
end

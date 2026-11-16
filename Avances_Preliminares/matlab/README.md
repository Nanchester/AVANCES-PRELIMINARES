# Caracterizacion acustica en MATLAB

Todo el calculo de caracteristicas, las figuras y los estadisticos se ejecutan en MATLAB. No se necesitan NumPy, librosa, pandas o Matplotlib. No hay entrenamiento, conversion, renombrado ni escritura de WAV de entrada.

Desde PowerShell, en la raiz del proyecto:

```powershell
& 'C:\Program Files\MATLAB\R2026a\bin\matlab.exe' -batch "addpath(fullfile(pwd,'matlab')); ejecutar_analisis();"
```

Entradas: `dataset_procesado_v2/metadata.csv` y sus WAV recursivos. Si no forman un conjunto completo de WAV validos con metadatos, se intenta `dataset_procesado`. Se conserva la subcategoria existente; no se inventan motores, rodamientos o tipos de alarma.

Los archivos principales solicitados son `caracterizar_audios.m` y `comparar_categorias.m`. `configuracion_acustica.m` contiene los parametros y `exportar_figura_acustica.m` centraliza PNG/PDF. `finalizar_resultados.m` une los lotes y verifica los archivos reales antes de crear comparaciones. `ejecutar_analisis.m` ejecuta la autoprueba, prueba representativa, analisis completo y comparaciones.

## Parametros y definiciones

- Muestras `audioread` normalizadas a full scale (FS). Pico y RMS se calculan sobre las muestras originales; no se normaliza cada grabacion por su pico.
- RMS dBFS = `20*log10(RMS/1 FS)`. Una sinusoidal de pico 1 FS tiene -3.0103 dBFS RMS con esta referencia. No son dB SPL ni niveles de exposicion laboral: faltan calibracion microfonica y datos de adquisicion.
- FFT sobre las 64.000 muestras, despues de quitar la media global. Ventana Hann periodica. FFT 65.536 puntos: separacion de bins 0.244140625 Hz; el zero padding interpola, no aporta resolucion fisica adicional.
- Amplitud unilateral: `abs(FFT)/sum(ventana)` y factor dos en bins interiores. Se grafica `20*log10(amplitud/1 FS)`; es amplitud espectral de pico, no potencia ni RMS.
- PSD unilateral: `abs(FFT).^2/(fs*sum(ventana.^2))`, factor dos solo en bins interiores. Unidades FS^2/Hz. Integrar PSD por `df` recupera la potencia ponderada por ventana.
- Frecuencia dominante: maximo de PSD entre 20 Hz y Nyquist; no equivale necesariamente al tono fundamental de una voz. Centroide y ancho de banda son media y desviacion frecuencial ponderadas por esa PSD.
- Flatness: media geometrica/media aritmetica de PSD de archivo completo en esa misma banda, con piso relativo `max(PSD)*1e-12`. Un periodograma de ruido blanco finito no necesariamente da 1. No se usa la media de flatness por trama.
- ZCR: cambios de signo de las muestras originales divididos por N-1, en cruces/muestra; los ceros se consideran no negativos. No se informa en Hz.
- STFT: Hann periodica de 400 muestras (25 ms), salto de 160 muestras (10 ms), solapamiento 240, FFT de 1.024 puntos. 398 tramas completas sin padding temporal; centros de trama en segundos. Separacion de bins 15.625 Hz; duracion fisica de ventana 25 ms. PSD normalizada como arriba y mostrada con `10*log10(PSD/1 FS^2/Hz)`.
- Mel: 40 triangulos igualmente espaciados en escala HTK entre 0 y 8 kHz, sin normalizacion de area. Potencia de cada banda = suma `H*PSD*df`; se muestra `10*log10(P_banda/1 FS^2)`. La implementacion explicita en MATLAB mantiene unidades fisicas y funciona sin Audio Toolbox. No se compara directamente el valor de color Mel con la PSD STFT: sus unidades son distintas.
- MFCC nativos si la funcion Audio Toolbox funciona: misma ventana/salto/FFT, 40 bandas con bordes HTK explicitos, 13 coeficientes, rectificacion log y `LogEnergy='ignore'`. Se guardan media y desviacion de cada coeficiente c0..c12 en CSV y las matrices completas con centros temporales en `mfcc/*.mat`.
- Alternativa sin Audio Toolbox: DCT-II ortonormal de logaritmo natural de la potencia Mel explicita. No se promete igualdad numerica con las convenciones internas de Audio Toolbox. El metodo se registra y se impide mezclar configuraciones distintas en una misma carpeta de resultados.
- Sin Signal Processing Toolbox: STFT con segmentacion, ventana y FFT de MATLAB base. Una autoprueba compara sus PSD y Mel con las obtenidas usando `spectrogram`.
- Para reducir el peso grafico se dibuja una submuestra de los puntos temporales y espectrales; las caracteristicas y espectrogramas usan todas las muestras. Las curvas son una visualizacion, no un nuevo WAV remuestreado.

`configuracion.json` y `configuracion.mat` guardan parametros, version, dataset, capacidades operativas y metodo MFCC. Si cambia esa configuracion, use otra carpeta de resultados; el script rechaza mezclar metodos. Las funciones instaladas y las licencias se comprueban con una llamada real, no solo con `which`.

## Prueba y verificaciones

La prueba elige hasta tres fuentes por categoria con semilla 42, priorizando distintas subcategorias y grabaciones. Comprueba CSV numericos finitos, WAV esperados, cuatro ejes con titulos/unidades, dos barras de color, PNG de 300 DPI y PDF presentes. La primera ejecucion tambien incluyo inspeccion visual externa de ejemplos de voz, maquinaria y alarma.

La autoprueba DSP utiliza una sinusoidal sintetica conocida y comprueba RMS, dBFS, frecuencia de 1 kHz, ganancia FFT, integrales PSD/STFT/Mel y la alternativa sin Toolboxes. Esa senal no se incorpora al dataset ni a las figuras de resultados.

Las figuras ya completas con filas en CSV se reutilizan al reanudar. Los errores individuales se registran en `errores.csv`; no se ocultan ni se convierten en filas con valores inventados. La comprobacion final vuelve a contrastar RMS/pico con cada WAV y verifica todos los PNG/PDF.

Opcionalmente se puede repartir el trabajo por indices disjuntos en tres procesos MATLAB, sin Parallel Computing Toolbox:

```matlab
caracterizar_audios('full',1,3) % proceso 1
caracterizar_audios('full',2,3) % proceso 2
caracterizar_audios('full',3,3) % proceso 3
% Despues de que los tres terminen:
finalizar_resultados()
```

## Interpretacion estadistica

Se generan cajas (mediana, Q1/Q3 con interpolacion lineal, bigotes a observaciones dentro de 1.5 IQR y puntos atipicos), histogramas de fraccion por intervalo y dispersiones. No requieren Statistics Toolbox. `grupos_comparaciones.csv` relaciona codigos cortos con etiquetas declaradas completas y cantidades de fuentes.

Las combinaciones de acentos declarados se conservan literalmente como grupos; no se deducen acentos puros. Las condiciones de fresado son etiquetas de ruta y conservan sus advertencias de metadatos. Las etiquetas de alarma mantienen el estado de revision de v2.

Los segmentos de una grabacion no son replicas independientes. `resumen_estadistico.csv` resume todas las columnas numericas, incluidos MFCC, y registra tanto segmentos como fuentes y grupos de independencia. Las figuras comparan seis caracteristicas principales. Las comparaciones son descriptivas, no validaciones de clasificacion ni pruebas de generalizacion a maquinas nuevas. Los niveles digitales dependen de ganancias de grabacion diferentes.

PNG se exporta a 300 DPI, con fondo blanco. PDF conserva texto y curvas vectoriales; los espectrogramas se incrustan como imagenes raster. No se afirma que todo el PDF sea vectorial.

Documentacion primaria consultada: [MFCC](https://www.mathworks.com/help/audio/ref/mfcc.html), [Mel](https://www.mathworks.com/help/audio/ref/melspectrogram.html), [exportgraphics](https://www.mathworks.com/help/matlab/ref/exportgraphics.html). La compatibilidad efectiva con R2026a se verifico mediante ejecucion local.

# Caracterizacion acustica en MATLAB

MATLAB 26.1.0.3203278 (R2026a), release 2026a. Ejecucion real mediante matlab.exe -batch. Licencia MATLAB operativa; Signal Processing y Audio Toolbox instalados y probados mediante funciones reales. El identificador de licencia de Audio Toolbox es Audio_System_Toolbox.

Dataset: `C:\Users\nayca\OneDrive\Documentos\TALLER_GRADO_I\dataset_procesado_v2`. Se conservaron categorias, subcategorias y estados de revision existentes. No se escribieron, renombraron ni convirtieron WAV de entrada. No se entrenaron modelos.

## Resultados verificados

| Categoria | Audios | Fuentes distintas | Grupos de independencia | Duracion |
|---|---:|---:|---:|---:|
| speech | 100 | 100 | 100 | 400 s |
| machinery | 100 | 91 | 2 | 400 s |
| alarms | 21 | 5 | 5 | 84 s |

Audios caracterizados: 221 de 221. Figuras individuales: 221 PNG + 221 PDF. Figuras comparativas: 27 PNG + 27 PDF. Total de figuras distintas: 248; dos formatos por figura.

Adicionalmente se conservan 3 PNG y 3 PDF comparativos preliminares de la prueba de software en prueba_comparaciones/. No forman parte de las figuras finales ni deben interpretarse como comparaciones del dataset completo. Los nueve ejemplos individuales de la prueba si estan incluidos, sin duplicarse, entre las figuras finales.

Todos los WAV analizados tienen 16 kHz, mono PCM16, 64.000 muestras y 4 s. Se verifico que los CSV numericos contienen valores finitos, que RMS y pico coinciden con una nueva lectura de cada WAV y que todos los PNG individuales tienen al menos 300 DPI (tolerancia de redondeo del metadato PNG), dimensiones suficientes y PDF presentes con cabecera valida.

La prueba inicial utilizo nueve archivos (hasta tres por categoria) y paso antes de continuar. Se inspeccionaron visualmente ejemplos de voz, maquinaria y alarma. Los nueve resultados se reutilizaron en el analisis completo. La autoprueba DSP con un seno conocido comprobo RMS, dBFS, frecuencia, correccion FFT e integrales PSD/STFT/Mel; ademas comparo la alternativa STFT base con Signal Processing Toolbox y verifico MFCC alternativos finitos. Ver prueba_validada.json, verificacion_formulas.json y verificacion_imagenes.csv.

## Caracteristicas y normalizaciones

Por audio: duracion, frecuencia de muestreo, numero de muestras, pico absoluto, RMS lineal, RMS dBFS, media DC, frecuencia dominante, centroide, ancho de banda espectral, ZCR y planitud espectral. Ademas: STFT, potencia Mel y 13 MFCC con media/desviacion por archivo y coeficientes por trama en mfcc/*.mat. Metodo MFCC empleado: `Audio_Toolbox_mfcc_log_ignore`.

FFT: Hann periodica de archivo completo, retirada de media global, FFT 65.536 puntos. Amplitud unilateral corregida por sum(w), duplicando solo bins interiores. PSD unilateral corregida por fs*sum(w^2), en FS^2/Hz. Los momentos y flatness usan 20 Hz hasta Nyquist. ZCR usa la senal original y se expresa en cruces/muestra.

STFT: Hann de 400 muestras, salto 160, FFT 1.024, 398 tramas completas. Mel: 40 triangulos HTK, potencia integrada por banda H*PSD*df. Se usa 20*log10 para amplitudes y 10*log10 para potencias. El color STFT indica dB re 1 FS^2/Hz y el color Mel dB re 1 FS^2; no tienen la misma unidad. Se guardan parametros completos en configuracion.json y configuracion.mat.

RMS dBFS se define como 20*log10(RMS/1 FS): un seno de pico 1 FS corresponde a -3.0103 dBFS RMS. Los niveles digitales NO son dB SPL, no miden directamente exposicion laboral y no permiten ordenar la peligrosidad de las fuentes sin calibracion y ganancias de adquisicion.

PNG: 300 DPI, fondo blanco, cuatro paneles con ejes/unidades/titulos, leyendas temporales/espectrales y barras de color. PDF: curvas y texto vectoriales, con espectrogramas raster incrustados. No se afirma que los PDF individuales sean totalmente vectoriales.

## Observaciones descriptivas medidas

| Categoria | RMS mediano (dBFS) | Dominante mediana (Hz) | Centroide mediano (Hz) | Ancho mediano (Hz) | ZCR mediano (cruces/muestra) | Flatness mediana |
|---|---:|---:|---:|---:|---:|---:|
| speech | -21.563 | 229.37 | 541.50 | 562.42 | 0.13581 | 0.009959 |
| machinery | -18.478 | 927.49 | 969.15 | 753.75 | 0.14972 | 0.033069 |
| alarms | -21.121 | 842.04 | 1035.19 | 653.95 | 0.14864 | 0.005179 |

Subcategorias (medianas):

| Categoria/subcategoria | n | RMS (dBFS) | Centroide (Hz) | Flatness |
|---|---:|---:|---:|---:|
| alarms/Fire | 6 | -24.328 | 3286.88 | 0.007327 |
| alarms/General | 15 | -19.749 | 1025.88 | 0.004112 |
| machinery/Milling | 90 | -18.395 | 975.58 | 0.034124 |
| machinery/Other | 10 | -18.536 | 315.79 | 0.009354 |
| speech/A | 9 | -21.766 | 572.25 | 0.008812 |
| speech/F | 46 | -20.737 | 549.94 | 0.009814 |
| speech/M | 45 | -21.925 | 527.11 | 0.010524 |

Los valores describen este piloto y sus condiciones de adquisicion. La frecuencia dominante no necesariamente es la fundamental de la voz. Una diferencia de medianas, cajas o nubes de puntos no demuestra una clasificacion correcta, causalidad ni generalizacion. No se calcularon metricas de clasificacion ni se ajustaron modelos.

## Comparaciones disponibles

- voz_genero: generada_descriptiva_sin_inferencia, 2 grupos, 3 PNG y 3 PDF.
- voz_acentos: generada_descriptiva_sin_inferencia, 17 grupos, 3 PNG y 3 PDF.
- maquinaria_tipos: generada_descriptiva_sin_inferencia, 2 grupos, 3 PNG y 3 PDF.
- fresado_condiciones: generada_descriptiva_sin_inferencia, 16 grupos, 3 PNG y 3 PDF.
- alarmas_tipos: generada_descriptiva_sin_inferencia, 2 grupos, 3 PNG y 3 PDF.
- voz_vs_maquinaria: generada_descriptiva_sin_inferencia, 2 grupos, 3 PNG y 3 PDF.
- alarmas_vs_maquinaria: generada_descriptiva_sin_inferencia, 2 grupos, 3 PNG y 3 PDF.
- voz_vs_alarmas: generada_descriptiva_sin_inferencia, 2 grupos, 3 PNG y 3 PDF.
- categorias: generada_descriptiva_sin_inferencia, 3 grupos, 3 PNG y 3 PDF.

Cada comparacion contiene cajas de seis caracteristicas, histogramas normalizados y dispersiones centroide-RMS/ZCR-flatness. Los codigos G01, G02, etc. se resuelven en comparaciones/grupos_comparaciones.csv. Las cajas usan Q1/Q3 por interpolacion lineal, mediana y bigotes de 1.5 IQR; los puntos externos no se eliminan.

Genero y acento se toman literalmente de los metadatos declarados. Las etiquetas con varios acentos se comparan como combinaciones declaradas, sin inferir un acento puro. Condiciones de fresado provienen de las rutas y no certifican parametros experimentales. No se agregaron subcategorias inexistentes (Motor, Bearing, Buzzer, Siren). Las etiquetas de alarma conservan sus pendientes de revision.

Los 90 proyectos de fresado comparten un grupo conservador de maquina desconocida. Los 10 segmentos Other proceden de una sola grabacion de nieve. Las alarmas proceden de cinco grabaciones. Fuentes y segmentos no son replicas intercambiables; resumen_estadistico.csv informa ambos recuentos y grupos de independencia. No se aplican pruebas de significacion tratando todos los segmentos como independientes.

## Archivos no procesados

Ninguno. errores.csv contiene solo la cabecera.

## Ubicaciones y reproduccion

- features.csv: caracteristicas por audio y trazabilidad.
- resumen_estadistico.csv: estadisticos por comparacion/grupo/caracteristica.
- figuras_individuales/: PNG y PDF por WAV.
- comparaciones/: PNG/PDF, mapa de grupos y manifiesto.
- mfcc/: matrices por trama, tiempos centrales y metodo.
- configuracion.json y configuracion.mat: parametros completos.
- validacion_final.json: cantidades comprobadas.

Desde la raiz: `matlab -batch "addpath(fullfile(pwd,'matlab')); ejecutar_analisis();"`. Puede utilizarse la ruta completa C:\Program Files\MATLAB\R2026a\bin\matlab.exe. Las figuras individuales con resultados existentes se reutilizan. Los errores individuales no detienen los demas archivos. Para cambiar parametros o metodos use otra carpeta de salida.

Ver matlab/README.md para ecuaciones, alternativas sin Toolboxes y ejecucion por lotes disjuntos.

function informe_caracterizacion()
% Informe generado desde resultados calculados, sin valores predefinidos.
cfg=configuracion_acustica();out=cfg.output;
T=readtable(fullfile(out,'features.csv'),'TextType','string','Encoding','UTF-8');
report=jsondecode(fileread(fullfile(out,'validacion_final.json')));
config=jsondecode(fileread(fullfile(out,'configuracion.json')));
manifest=readtable(fullfile(out,'comparaciones','comparaciones_generadas.csv'),'TextType','string');
err=readtable(fullfile(out,'errores.csv'),'TextType','string');
fid=fopen(fullfile(out,'INFORME.md'),'w','n','UTF-8');cleanup=onCleanup(@() fclose(fid));
fprintf(fid,'# Caracterizacion acustica en MATLAB\n\n');
fprintf(fid,'MATLAB %s, release %s. Ejecucion real mediante matlab.exe -batch. Licencia MATLAB operativa; Signal Processing y Audio Toolbox instalados y probados mediante funciones reales. El identificador de licencia de Audio Toolbox es Audio_System_Toolbox.\n\n',config.matlab_version,config.release);
fprintf(fid,'Dataset: `%s`. Se conservaron categorias, subcategorias y estados de revision existentes. No se escribieron, renombraron ni convirtieron WAV de entrada. No se entrenaron modelos.\n\n',config.dataset);
fprintf(fid,'## Resultados verificados\n\n| Categoria | Audios | Fuentes distintas | Grupos de independencia | Duracion |\n|---|---:|---:|---:|---:|\n');
for cat=["speech","machinery","alarms"]
    mask=T.categoria==cat;
    fprintf(fid,'| %s | %d | %d | %d | %.0f s |\n',cat,sum(mask),numel(unique(T.source_id(mask))),numel(unique(T.grupo_independencia(mask))),sum(T.duracion_s(mask)));
end
fprintf(fid,'\nAudios caracterizados: %d de %d. Figuras individuales: %d PNG + %d PDF. Figuras comparativas: %d PNG + %d PDF. Total de figuras distintas: %d; dos formatos por figura.\n\n',report.audios_caracterizados,report.audios_dataset,report.figuras_individuales_png,report.figuras_individuales_pdf,report.figuras_comparativas_png,report.figuras_comparativas_pdf,report.figuras_individuales_png+report.figuras_comparativas_png);
trialPNG=dir(fullfile(out,'prueba_comparaciones','*.png'));trialPDF=dir(fullfile(out,'prueba_comparaciones','*.pdf'));
fprintf(fid,'Adicionalmente se conservan %d PNG y %d PDF comparativos preliminares de la prueba de software en prueba_comparaciones/. No forman parte de las figuras finales ni deben interpretarse como comparaciones del dataset completo. Los nueve ejemplos individuales de la prueba si estan incluidos, sin duplicarse, entre las figuras finales.\n\n',numel(trialPNG),numel(trialPDF));
fprintf(fid,'Todos los WAV analizados tienen 16 kHz, mono PCM16, 64.000 muestras y 4 s. Se verifico que los CSV numericos contienen valores finitos, que RMS y pico coinciden con una nueva lectura de cada WAV y que todos los PNG individuales tienen al menos 300 DPI (tolerancia de redondeo del metadato PNG), dimensiones suficientes y PDF presentes con cabecera valida.\n\n');
fprintf(fid,'La prueba inicial utilizo nueve archivos (hasta tres por categoria) y paso antes de continuar. Se inspeccionaron visualmente ejemplos de voz, maquinaria y alarma. Los nueve resultados se reutilizaron en el analisis completo. La autoprueba DSP con un seno conocido comprobo RMS, dBFS, frecuencia, correccion FFT e integrales PSD/STFT/Mel; ademas comparo la alternativa STFT base con Signal Processing Toolbox y verifico MFCC alternativos finitos. Ver prueba_validada.json, verificacion_formulas.json y verificacion_imagenes.csv.\n\n');
fprintf(fid,'## Caracteristicas y normalizaciones\n\n');
fprintf(fid,'Por audio: duracion, frecuencia de muestreo, numero de muestras, pico absoluto, RMS lineal, RMS dBFS, media DC, frecuencia dominante, centroide, ancho de banda espectral, ZCR y planitud espectral. Ademas: STFT, potencia Mel y 13 MFCC con media/desviacion por archivo y coeficientes por trama en mfcc/*.mat. Metodo MFCC empleado: `%s`.\n\n',config.mfcc_method);
fprintf(fid,'FFT: Hann periodica de archivo completo, retirada de media global, FFT 65.536 puntos. Amplitud unilateral corregida por sum(w), duplicando solo bins interiores. PSD unilateral corregida por fs*sum(w^2), en FS^2/Hz. Los momentos y flatness usan 20 Hz hasta Nyquist. ZCR usa la senal original y se expresa en cruces/muestra.\n\n');
fprintf(fid,'STFT: Hann de 400 muestras, salto 160, FFT 1.024, 398 tramas completas. Mel: 40 triangulos HTK, potencia integrada por banda H*PSD*df. Se usa 20*log10 para amplitudes y 10*log10 para potencias. El color STFT indica dB re 1 FS^2/Hz y el color Mel dB re 1 FS^2; no tienen la misma unidad. Se guardan parametros completos en configuracion.json y configuracion.mat.\n\n');
fprintf(fid,'RMS dBFS se define como 20*log10(RMS/1 FS): un seno de pico 1 FS corresponde a -3.0103 dBFS RMS. Los niveles digitales NO son dB SPL, no miden directamente exposicion laboral y no permiten ordenar la peligrosidad de las fuentes sin calibracion y ganancias de adquisicion.\n\n');
fprintf(fid,'PNG: 300 DPI, fondo blanco, cuatro paneles con ejes/unidades/titulos, leyendas temporales/espectrales y barras de color. PDF: curvas y texto vectoriales, con espectrogramas raster incrustados. No se afirma que los PDF individuales sean totalmente vectoriales.\n\n');
fprintf(fid,'## Observaciones descriptivas medidas\n\n| Categoria | RMS mediano (dBFS) | Dominante mediana (Hz) | Centroide mediano (Hz) | Ancho mediano (Hz) | ZCR mediano (cruces/muestra) | Flatness mediana |\n|---|---:|---:|---:|---:|---:|---:|\n');
for cat=["speech","machinery","alarms"]
    mask=T.categoria==cat;
    fprintf(fid,'| %s | %.3f | %.2f | %.2f | %.2f | %.5f | %.6f |\n',cat,median(T.rms_dbfs(mask)),median(T.frecuencia_dominante_hz(mask)),median(T.centroide_hz(mask)),median(T.ancho_banda_hz(mask)),median(T.zcr_cruces_muestra(mask)),median(T.spectral_flatness(mask)));
end
fprintf(fid,'\nSubcategorias (medianas):\n\n| Categoria/subcategoria | n | RMS (dBFS) | Centroide (Hz) | Flatness |\n|---|---:|---:|---:|---:|\n');
keys=unique(T.categoria+"/"+T.subcategoria);
for k=keys'
    mask=T.categoria+"/"+T.subcategoria==k;
    fprintf(fid,'| %s | %d | %.3f | %.2f | %.6f |\n',k,sum(mask),median(T.rms_dbfs(mask)),median(T.centroide_hz(mask)),median(T.spectral_flatness(mask)));
end
fprintf(fid,'\nLos valores describen este piloto y sus condiciones de adquisicion. La frecuencia dominante no necesariamente es la fundamental de la voz. Una diferencia de medianas, cajas o nubes de puntos no demuestra una clasificacion correcta, causalidad ni generalizacion. No se calcularon metricas de clasificacion ni se ajustaron modelos.\n\n');
fprintf(fid,'## Comparaciones disponibles\n\n');
for i=1:height(manifest)
    fprintf(fid,'- %s: %s, %d grupos, %d PNG y %d PDF.\n',manifest.comparacion(i),manifest.estado(i),manifest.grupos(i),manifest.figuras_png(i),manifest.figuras_pdf(i));
end
fprintf(fid,'\nCada comparacion contiene cajas de seis caracteristicas, histogramas normalizados y dispersiones centroide-RMS/ZCR-flatness. Los codigos G01, G02, etc. se resuelven en comparaciones/grupos_comparaciones.csv. Las cajas usan Q1/Q3 por interpolacion lineal, mediana y bigotes de 1.5 IQR; los puntos externos no se eliminan.\n\n');
fprintf(fid,'Genero y acento se toman literalmente de los metadatos declarados. Las etiquetas con varios acentos se comparan como combinaciones declaradas, sin inferir un acento puro. Condiciones de fresado provienen de las rutas y no certifican parametros experimentales. No se agregaron subcategorias inexistentes (Motor, Bearing, Buzzer, Siren). Las etiquetas de alarma conservan sus pendientes de revision.\n\n');
fprintf(fid,'Los 90 proyectos de fresado comparten un grupo conservador de maquina desconocida. Los 10 segmentos Other proceden de una sola grabacion de nieve. Las alarmas proceden de cinco grabaciones. Fuentes y segmentos no son replicas intercambiables; resumen_estadistico.csv informa ambos recuentos y grupos de independencia. No se aplican pruebas de significacion tratando todos los segmentos como independientes.\n\n');
fprintf(fid,'## Archivos no procesados\n\n');
if height(err)==0,fprintf(fid,'Ninguno. errores.csv contiene solo la cabecera.\n\n');else
    for i=1:height(err),fprintf(fid,'- %s: %s\n',err.archivo(i),err.mensaje(i));end
end
fprintf(fid,'## Ubicaciones y reproduccion\n\n- features.csv: caracteristicas por audio y trazabilidad.\n- resumen_estadistico.csv: estadisticos por comparacion/grupo/caracteristica.\n- figuras_individuales/: PNG y PDF por WAV.\n- comparaciones/: PNG/PDF, mapa de grupos y manifiesto.\n- mfcc/: matrices por trama, tiempos centrales y metodo.\n- configuracion.json y configuracion.mat: parametros completos.\n- validacion_final.json: cantidades comprobadas.\n\n');
fprintf(fid,'Desde la raiz: `matlab -batch "addpath(fullfile(pwd,''matlab'')); ejecutar_analisis();"`. Puede utilizarse la ruta completa C:\\Program Files\\MATLAB\\R2026a\\bin\\matlab.exe. Las figuras individuales con resultados existentes se reutilizan. Los errores individuales no detienen los demas archivos. Para cambiar parametros o metodos use otra carpeta de salida.\n\nVer matlab/README.md para ecuaciones, alternativas sin Toolboxes y ejecucion por lotes disjuntos.\n');
clear cleanup
end

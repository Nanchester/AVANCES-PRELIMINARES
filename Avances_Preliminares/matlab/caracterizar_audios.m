function T = caracterizar_audios(mode,shard,shards)
% CARACTERIZAR_AUDIOS('test'|'full'): analisis MATLAB reproducible, sin Python.
% RMS y pico se calculan sobre muestras originales audioread en [-1,1].
% FFT/STFT eliminan solamente la media global. No hay normalizacion por pico.
% FFT de archivo completo: Hann periodica; NFFT=2^nextpow2(N). El zero padding
% interpola bins; no mejora la resolucion fisica de la ventana de 4 segundos.
% Centroide/ancho/flatness: PSD de archivo completo entre 20 Hz y Nyquist.
% STFT: Hann 25 ms, salto 10 ms, FFT 1024, sin padding temporal ni trama parcial.
% Las filas CSV son estadisticas por archivo, no observaciones independientes.
if nargin==0,mode='full';end
if nargin<2,shard=1;end
if nargin<3,shards=1;end
assert(shard>=1 && shard<=shards && floor(shard)==shard && floor(shards)==shards);
assert(ismember(string(mode),["test","full","selftest"]),'Modo invalido');
cfg=configuracion_acustica();rng(cfg.seed,'twister');
if ~exist(cfg.output,'dir'),mkdir(cfg.output);end
for d={'figuras_individuales','comparaciones','mfcc'}
    if ~exist(fullfile(cfg.output,d{1}),'dir'),mkdir(fullfile(cfg.output,d{1}));end
end
[meta,dataset]=choose_dataset(cfg);
caps=capabilities(cfg);
cfg.dataset=dataset;cfg.matlab_version=version;cfg.release=version('-release');cfg.capabilities=caps;
cfg.mfcc_method=ternary(caps.mfcc_operational,'Audio_Toolbox_mfcc_log_ignore','manual_HTK_DCTII_orthonormal');
if strcmp(mode,'selftest'),formula_selftest(meta(1,:),cfg,caps);T=table();return;end
configFile=fullfile(cfg.output,'configuracion.json');
encoded=jsonencode(cfg,'PrettyPrint',true);
if isfile(configFile)
    assert(strcmp(strtrim(fileread(configFile)),strtrim(encoded)),...
        'La configuracion cambio. Use otra carpeta de salida para no mezclar metodos.');
else
    fid=fopen(configFile,'w','n','UTF-8');fprintf(fid,'%s',encoded);fclose(fid);
end
if ~isfile(fullfile(cfg.output,'configuracion.mat')),save(fullfile(cfg.output,'configuracion.mat'),'cfg');end
if strcmp(mode,'test')
    selected=representatives(meta);
else
    assert(isfile(fullfile(cfg.output,'prueba_validada.json')),...
        'Primero ejecutar y verificar caracterizar_audios(''test'').');
    selected=(1:height(meta))';
    selected=selected(mod(selected-1,shards)==shard-1);
end
featureFile=fullfile(cfg.output,'features.csv');
seedFile=featureFile;
if shards>1
    featureFile=fullfile(cfg.output,sprintf('features_parte_%02d.csv',shard));
    if isfile(featureFile),seedFile=featureFile;end
end
if isfile(seedFile),T=readtable(seedFile,'TextType','string','Encoding','UTF-8');else,T=table();end
errorFile=fullfile(cfg.output,'errores.csv');
if shards>1,errorFile=fullfile(cfg.output,sprintf('errores_parte_%02d.csv',shard));end
errors=struct('archivo',{},'identificador',{},'mensaje',{});
if isfile(errorFile)
    prior=readtable(errorFile,'TextType','string');
    if height(prior)>0,errors=table2struct(prior);end
end
for ii=1:numel(selected)
    idx=selected(ii);r=meta(idx,:);name=char(r.nombre_archivo);base=fullfile(cfg.output,'figuras_individuales',erase(name,'.wav'));
    if ~isempty(T) && any(T.nombre_archivo==r.nombre_archivo) && isfile([base '.png']) && isfile([base '.pdf'])
        continue
    end
    try
        p=fullfile(dataset,char(r.categoria),name);info=audioinfo(p);[x,fs]=audioread(p);
        assert(fs==cfg.fs_expected && size(x,1)==cfg.samples_expected && size(x,2)==1 && info.BitsPerSample==16,...
            'El WAV no cumple PCM16 mono, 16kHz y 64000 muestras');
        assert(all(isfinite(x)),'Muestras no finitas');
        [frow,z]=extract_features(x,fs,r,cfg,caps);
        fig=individual_figure(x,fs,r,z,cfg);
        cleanup=onCleanup(@() close_if_valid(fig));
        exportar_figura_acustica(fig,base,cfg);clear cleanup
        if cfg.save_mfcc_frames
            coefficients=z.mfcc;time_seconds=z.t;method=cfg.mfcc_method; %#ok<NASGU>
            save(fullfile(cfg.output,'mfcc',[erase(name,'.wav') '.mat']),'coefficients','time_seconds','method');
        end
        new=struct2table(frow);
        if isempty(T),T=new;else
            T(T.nombre_archivo==r.nombre_archivo,:)=[];T=[T;new]; %#ok<AGROW>
        end
        writetable(T,featureFile,'Encoding','UTF-8');
        fprintf('[%s %d/%d] %s | RMS %.2f dBFS | centroide %.1f Hz\n',mode,ii,numel(selected),name,frow.rms_dbfs,frow.centroide_hz);
    catch err
        errors(end+1)=struct('archivo',name,'identificador',err.identifier,'mensaje',err.message); %#ok<AGROW>
        warning('Caracterizacion:Archivo','%s: %s',name,err.message);
    end
end
if isempty(errors)
    writetable(table(strings(0,1),strings(0,1),strings(0,1),'VariableNames',{'archivo','identificador','mensaje'}),errorFile);
else,writetable(struct2table(errors),errorFile,'Encoding','UTF-8');end
if strcmp(mode,'test')
    trial=T(ismember(T.nombre_archivo,meta.nombre_archivo(selected)),:);
    assert(height(trial)==numel(selected),'La prueba no proceso todos los representantes');
    writetable(trial,fullfile(cfg.output,'features_prueba.csv'),'Encoding','UTF-8');
    validate_numeric(trial);
    report=struct('estado','CSV e imagenes comprobados; pendiente inspeccion visual externa',...
        'audios',height(trial),'archivos',trial.nombre_archivo,'categorias',unique(trial.categoria),...
        'paneles_por_figura',4,'png_dpi',cfg.png_dpi,'mfcc_method',cfg.mfcc_method);
    fid=fopen(fullfile(cfg.output,'prueba_ejecutada.json'),'w','n','UTF-8');fprintf(fid,'%s',jsonencode(report,'PrettyPrint',true));fclose(fid);
else
    validate_numeric(T);assert(all(ismember(meta.nombre_archivo(selected),T.nombre_archivo) | ismember(meta.nombre_archivo(selected),string({errors.archivo}))), 'Audios sin resultado ni error');
end
end

function [meta,dataset]=choose_dataset(cfg)
for folder={'dataset_procesado_v2','dataset_procesado'}
    dataset=fullfile(cfg.root,folder{1});file=fullfile(dataset,'metadata.csv');
    if ~isfile(file),continue;end
    m=readtable(file,'TextType','string','VariableNamingRule','preserve','Encoding','UTF-8');
    if ismember('nombre_segmento',m.Properties.VariableNames),m=renamevars(m,'nombre_segmento','nombre_archivo');end
    pairs={'carpeta_original','carpeta_origen';'gender','genero_declarado';'accents','acento_declarado';'locale','idioma';'estrato','condicion_declarada';'estado_validacion','validacion'};
    for j=1:size(pairs,1)
        if ismember(pairs{j,1},m.Properties.VariableNames) && ~ismember(pairs{j,2},m.Properties.VariableNames)
            m=renamevars(m,pairs{j,1},pairs{j,2});
        end
    end
    needed={'source_id','grupo_independencia','speaker_id','genero_declarado','acento_declarado','idioma','condicion_declarada','estado_revision_etiqueta','carpeta_origen'};
    for j=1:numel(needed)
        if ~ismember(needed{j},m.Properties.VariableNames),m.(needed{j})=strings(height(m),1);end
    end
    for j=1:width(m)
        if isstring(m.(j)),a=m.(j);a(ismissing(a))="";m.(j)=a;end
    end
    files=dir(fullfile(dataset,'**','*.wav'));ok=height(m)>0 && numel(files)==height(m) && numel(unique(m.nombre_archivo))==height(m);
    for j=1:height(m)
        try
            a=audioinfo(fullfile(dataset,char(m.categoria(j)),char(m.nombre_archivo(j))));
            ok=ok && a.SampleRate==16000 && a.TotalSamples==64000 && a.NumChannels==1 && a.BitsPerSample==16;
        catch,ok=false;end
        if ~ok,break;end
    end
    if ok,meta=sortrows(m,{'categoria','subcategoria','nombre_archivo'});return;end
    warning('Caracterizacion:Dataset','%s incompleto/invalido; intentando alternativa.',folder{1});
end
error('No existe dataset completo y valido con metadatos.');
end

function caps=capabilities(cfg)
caps=struct('matlab_version',version,'matlab_license',license('test','MATLAB'),...
    'signal_installed',~isempty(ver('signal')),'signal_license',license('test','Signal_Toolbox'),...
    'audio_installed',~isempty(ver('audio')),'audio_license_Audio_System_Toolbox',license('test','Audio_System_Toolbox'),...
    'spectrogram_operational',false,'mfcc_operational',false,'melSpectrogram_operational',false);
v=sin(2*pi*1000*(0:1599)'/16000);w=.5-.5*cos(2*pi*(0:399)'/400);
try,tmp=spectrogram(v,w,240,1024,16000);caps.spectrogram_operational=all(isfinite(tmp),'all');catch e,caps.spectrogram_error=e.message;end
try,tmp=mfcc(v,16000,'Window',w,'OverlapLength',240,'FFTLength',1024,'NumCoeffs',13,'LogEnergy','ignore','BandEdges',mel_edges(16000,cfg.mel_bands));caps.mfcc_operational=all(isfinite(tmp),'all');catch e,caps.mfcc_error=e.message;end
try,tmp=melSpectrogram(v,16000,'Window',w,'OverlapLength',240,'FFTLength',1024,'NumBands',40);caps.melSpectrogram_operational=all(isfinite(tmp),'all');catch e,caps.melSpectrogram_error=e.message;end
end

function idx=representatives(m)
idx=[];rng(42);
for cat=["speech","machinery","alarms"]
    ids=find(m.categoria==cat);ids=ids(randperm(numel(ids)));chosen=[];keys=strings(0,1);
    for i=ids(:)'
        key=m.subcategoria(i);
        if ~ismember(key,keys),chosen(end+1)=i;keys(end+1)=key;end %#ok<AGROW>
        if numel(chosen)==3,break;end
    end
    for i=ids(:)'
        if numel(chosen)>=3,break;end
        if ~ismember(i,chosen) && ~ismember(m.source_id(i),m.source_id(chosen)),chosen(end+1)=i;end %#ok<AGROW>
    end
    idx=[idx chosen]; %#ok<AGROW>
end
idx=idx(:);
end

function [row,z]=extract_features(x,fs,r,cfg,caps)
N=numel(x);y=x;if cfg.remove_global_dc_spectral,y=x-mean(x);end
w=.5-.5*cos(2*pi*(0:N-1)'/N);nfft=2^nextpow2(N);
F=fft(y.*w,nfft);f=(0:nfft/2)'*fs/nfft;
amp=abs(F(1:nfft/2+1))/sum(w);amp(2:end-1)=2*amp(2:end-1);
psd=abs(F(1:nfft/2+1)).^2/(fs*sum(w.^2));psd(2:end-1)=2*psd(2:end-1);
mask=f>=cfg.spectral_min_hz;pb=psd(mask);fb=f(mask);total=sum(pb);
assert(total>0,'Espectro sin energia');[~,i]=max(pb);dom=fb(i);
centroid=sum(fb.*pb)/total;band=sqrt(sum((fb-centroid).^2.*pb)/total);
floorP=max(max(pb)*1e-12,realmin);flat=exp(mean(log(max(pb,floorP))))/mean(max(pb,floorP));
L=round(cfg.stft_window_seconds*fs);hop=round(cfg.stft_hop_seconds*fs);win=.5-.5*cos(2*pi*(0:L-1)'/L);
if caps.spectrogram_operational
    [S,fst,t]=spectrogram(y,win,L-hop,cfg.stft_fft_length,fs);
else
    starts=0:hop:N-L;frames=y((1:L)'+starts);S=fft(frames.*win,cfg.stft_fft_length,1);S=S(1:cfg.stft_fft_length/2+1,:);
    fst=(0:cfg.stft_fft_length/2)'*fs/cfg.stft_fft_length;t=(starts+L/2)/fs;
end
P=abs(S).^2/(fs*sum(win.^2));P(2:end-1,:)=2*P(2:end-1,:);
edges=mel_edges(fs,cfg.mel_bands);H=zeros(cfg.mel_bands,numel(fst));
for b=1:cfg.mel_bands,H(b,:)=max(0,min((fst-edges(b))/(edges(b+1)-edges(b)),(edges(b+2)-fst)/(edges(b+2)-edges(b+1))));end
melPower=H*P*(fs/cfg.stft_fft_length);
if caps.mfcc_operational
    C=mfcc(y,fs,'Window',win,'OverlapLength',L-hop,'FFTLength',cfg.stft_fft_length,...
        'NumCoeffs',cfg.mfcc_coefficients,'LogEnergy','ignore','BandEdges',edges,'Rectification','log');
else
    b=cfg.mel_bands;k=(0:cfg.mfcc_coefficients-1)';Q=sqrt(2/b)*cos(pi/b*k*((0:b-1)+.5));Q(1,:)=Q(1,:)/sqrt(2);
    C=(Q*log(max(melPower,cfg.power_floor)))';
end
assert(size(C,1)==numel(t) && size(C,2)==cfg.mfcc_coefficients && all(isfinite(C),'all'),'MFCC invalidos');
rmsValue=sqrt(mean(x.^2));
row=struct('nombre_archivo',r.nombre_archivo,'categoria',r.categoria,'subcategoria',r.subcategoria,...
    'carpeta_origen',r.carpeta_origen,'fuente_original',r.archivo_original,'source_id',r.source_id,...
    'grupo_independencia',r.grupo_independencia,'speaker_id',r.speaker_id,...
    'genero_declarado',r.genero_declarado,'acento_declarado',r.acento_declarado,'idioma',r.idioma,...
    'condicion_declarada',r.condicion_declarada,'estado_revision_etiqueta',r.estado_revision_etiqueta,...
    'duracion_s',N/fs,'frecuencia_muestreo_hz',fs,'muestras',N,'amplitud_maxima_fs',max(abs(x)),...
    'rms_fs',rmsValue,'rms_dbfs',20*log10(max(rmsValue,sqrt(cfg.power_floor))),...
    'frecuencia_dominante_hz',dom,'centroide_hz',centroid,'ancho_banda_hz',band,...
    'zcr_cruces_muestra',sum(diff(x>=0)~=0)/(N-1),'spectral_flatness',flat,...
    'dc_media_fs',mean(x),'mfcc_metodo',string(cfg.mfcc_method),'validacion',"audioinfo_audioread_ok");
for k=1:cfg.mfcc_coefficients
    row.(sprintf('mfcc_%02d_media',k-1))=mean(C(:,k));row.(sprintf('mfcc_%02d_std',k-1))=std(C(:,k));
end
z=struct('f',f,'amplitude',amp,'psd',psd,'fst',fst,'t',t,'P',P,'melPower',melPower,...
    'melCenters',2595*log10(1+edges(2:end-1)/700),'mfcc',C);
end

function fig=individual_figure(x,fs,r,z,cfg)
fig=figure('Visible','off','Color','white');
layout=tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
title(layout,sprintf('%s | %s/%s',r.nombre_archivo,r.categoria,r.subcategoria),'Interpreter','none','FontWeight','bold');
ax=nexttile(layout);n=numel(x);step=max(1,floor(n/12000));plot(ax,(0:step:n-1)/fs,x(1:step:end),'Color',[.05 .35 .65]);grid(ax,'on');
title(ax,'Senal temporal');xlabel(ax,'Tiempo (s)');ylabel(ax,'Amplitud (FS)');xlim(ax,[0 n/fs]);legend(ax,'Muestras originales','Location','northeast');
ax=nexttile(layout);step=max(1,floor(numel(z.f)/8000));plot(ax,z.f(1:step:end)/1000,20*log10(max(z.amplitude(1:step:end),1e-8)),'Color',[.65 .2 .1]);grid(ax,'on');
title(ax,'FFT unilateral - Hann, ganancia coherente corregida');xlabel(ax,'Frecuencia (kHz)');ylabel(ax,'20 log_{10}(amplitud / 1 FS) (dB)');xlim(ax,[0 fs/2000]);ylim(ax,[-120 0]);legend(ax,'Amplitud de pico espectral','Location','northeast');
ax=nexttile(layout);imagesc(ax,z.t,z.fst/1000,10*log10(max(z.P,cfg.power_floor)));axis(ax,'xy');
title(ax,'STFT - densidad espectral de potencia');xlabel(ax,'Tiempo (s)');ylabel(ax,'Frecuencia (kHz)');clim(ax,cfg.stft_color_db);c=colorbar(ax);c.Label.String='PSD (dB re 1 FS^2/Hz)';
ax=nexttile(layout);imagesc(ax,z.t,z.melCenters,10*log10(max(z.melPower,cfg.power_floor)));axis(ax,'xy');
title(ax,'Mel - potencia integrada por banda');xlabel(ax,'Tiempo (s)');ylabel(ax,'Frecuencia perceptual (mel HTK)');clim(ax,cfg.mel_color_db);c=colorbar(ax);c.Label.String='Potencia por banda (dB re 1 FS^2)';
colormap(fig,parula(256));
axesFound=findall(fig,'Type','axes');assert(numel(axesFound)==4,'Faltan paneles');
for a=axesFound'
    assert(~isempty(a.Title.String) && ~isempty(a.XLabel.String) && ~isempty(a.YLabel.String),'Faltan titulos o unidades');
end
assert(numel(findall(fig,'Type','colorbar'))==2,'Faltan barras de color');
end
function edges=mel_edges(fs,bands)
edges=700*(10.^(linspace(0,2595*log10(1+fs/1400),bands+2)/2595)-1);edges(end)=fs/2;
end
function validate_numeric(T)
for j=1:width(T)
    if isnumeric(T.(j)),assert(all(isfinite(T.(j)),'all'),'CSV contiene valores no finitos en %s',T.Properties.VariableNames{j});end
end
assert(all(T.duracion_s==4) && all(T.muestras==64000) && all(T.frecuencia_muestreo_hz==16000));
assert(all(T.spectral_flatness>=0 & T.spectral_flatness<=1+1e-10));
end
function val=ternary(cond,a,b)
if cond,val=a;else,val=b;end
end
function close_if_valid(f)
if isgraphics(f),close(f);end
end
function formula_selftest(r,cfg,caps)
fs=16000;t=(0:63999)'/fs;x=.5*sin(2*pi*1000*t);
[row,z]=extract_features(x,fs,r,cfg,caps);
assert(abs(row.rms_fs-.5/sqrt(2))<1e-12);
assert(abs(row.rms_dbfs-20*log10(.5/sqrt(2)))<1e-10);
assert(abs(row.frecuencia_dominante_hz-1000)<fs/65536);
assert(abs(max(z.amplitude)-.5)<1e-10);
assert(abs(sum(z.psd)*(fs/65536)-.125)<1e-10);
assert(max(abs(sum(z.P,1)*(fs/1024)-.125))<1e-10);
assert(max(abs(sum(z.melPower,1)-.125))<1e-5);
assert(row.spectral_flatness<.01);
fallback=caps;fallback.spectrogram_operational=false;fallback.mfcc_operational=false;
[rowFallback,zFallback]=extract_features(x,fs,r,cfg,fallback);
assert(max(abs(z.P-zFallback.P),[],'all')<1e-12);
assert(max(abs(z.melPower-zFallback.melPower),[],'all')<1e-12);
assert(all(isfinite(zFallback.mfcc),'all'));
assert(abs(rowFallback.rms_fs-row.rms_fs)<1e-12);
report=struct('estado','aprobada','pruebas',{{'RMS seno 0.5 pico','RMS dBFS seno','FFT 1000Hz y ganancia coherente','Parseval PSD archivo','Integral PSD STFT','Potencia Mel seno','Planitud seno','STFT base igual a Signal Toolbox','MFCC alternativo finito'}});
fid=fopen(fullfile(cfg.output,'verificacion_formulas.json'),'w');fprintf(fid,'%s',jsonencode(report,'PrettyPrint',true));fclose(fid);
fprintf('AUTOPRUEBA DSP: normalizaciones FFT/PSD/STFT/Mel y alternativa sin Toolbox correctas.\n');
end

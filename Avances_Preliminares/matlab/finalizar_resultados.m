function finalizar_resultados()
% Une lotes disjuntos, comprueba numeros/imagenes y genera comparaciones.
cfg=configuracion_acustica();files=dir(fullfile(cfg.output,'features_parte_*.csv'));
T=readtable(fullfile(cfg.output,'features.csv'),'TextType','string','Encoding','UTF-8');
for i=1:numel(files)
    p=readtable(fullfile(files(i).folder,files(i).name),'TextType','string','Encoding','UTF-8');T=[T;p]; %#ok<AGROW>
end
names=unique(T.nombre_archivo,'stable');
for i=1:numel(names)
    rows=find(T.nombre_archivo==names(i));
    for j=1:width(T)
        v=T.(j)(rows,:);
        if isnumeric(v),assert(all(abs(v-v(1,:))<=1e-10*max(1,abs(v(1,:))),'all'),'Lotes con valores incompatibles');
        else
            v=string(v);v(ismissing(v))="";assert(all(v==v(1,:),'all'),'Metadatos incompatibles entre lotes');
        end
    end
end
[~,idx]=unique(T.nombre_archivo,'stable');T=sortrows(T(idx,:),{'categoria','subcategoria','nombre_archivo'});
for j=1:width(T)
    if isnumeric(T.(j)),assert(all(isfinite(T.(j)),'all'),'Valores no finitos en CSV');end
end
assert(all(T.duracion_s==4 & T.muestras==64000 & T.frecuencia_muestreo_hz==16000));
pngInfo=struct('archivo',{},'ancho_px',{},'alto_px',{},'dpi',{},'pdf_valido',{});
for i=1:height(T)
    name=char(T.nombre_archivo(i));base=fullfile(cfg.output,'figuras_individuales',erase(name,'.wav'));
    im=imfinfo([base '.png']);dpi=double(im.XResolution);
    if strcmpi(im.ResolutionUnit,'meter'),dpi=dpi*.0254;end
    assert(dpi>=299.8 && im.Width>=2000 && im.Height>=1200);
    fid=fopen([base '.pdf'],'r');head=char(fread(fid,5,'*char')');fclose(fid);assert(strcmp(head,'%PDF-'));
    pngInfo(end+1)=struct('archivo',string(name),'ancho_px',im.Width,'alto_px',im.Height,'dpi',dpi,'pdf_valido',true); %#ok<AGROW>
    raw=jsondecode(fileread(fullfile(cfg.output,'configuracion.json')));
    [x,fs]=audioread(fullfile(raw.dataset,char(T.categoria(i)),name));
    assert(abs(sqrt(mean(x.^2))-T.rms_fs(i))<1e-10 && abs(max(abs(x))-T.amplitud_maxima_fs(i))<1e-10,'RMS/pico no coincide con WAV');
    assert(fs==16000 && numel(x)==64000);
end
writetable(T,fullfile(cfg.output,'features.csv'),'Encoding','UTF-8');
writetable(struct2table(pngInfo),fullfile(cfg.output,'verificacion_imagenes.csv'));
raw=jsondecode(fileread(fullfile(cfg.output,'configuracion.json')));meta=readtable(fullfile(raw.dataset,'metadata.csv'),'TextType','string','Encoding','UTF-8');
namecol='nombre_archivo';if ~ismember(namecol,meta.Properties.VariableNames),namecol='nombre_segmento';end
errFiles=dir(fullfile(cfg.output,'errores*.csv'));allErrors=table();
for i=1:numel(errFiles)
    e=readtable(fullfile(errFiles(i).folder,errFiles(i).name),'TextType','string');
    if height(e)>0,allErrors=[allErrors;e];end %#ok<AGROW>
end
if isempty(allErrors),allErrors=table(strings(0,1),strings(0,1),strings(0,1),'VariableNames',{'archivo','identificador','mensaje'});else,allErrors=unique(allErrors,'rows');end
writetable(allErrors,fullfile(cfg.output,'errores.csv'),'Encoding','UTF-8');
missing=setdiff(meta.(namecol),T.nombre_archivo);assert(all(ismember(missing,allErrors.archivo)),'WAV sin resultado ni error');
png=dir(fullfile(cfg.output,'figuras_individuales','*.png'));assert(numel(png)==height(T),'Imagenes sin features');
comparar_categorias();
manifest=readtable(fullfile(cfg.output,'comparaciones','comparaciones_generadas.csv'),'TextType','string');
report=struct('audios_caracterizados',height(T),'audios_dataset',height(meta),'sin_procesar',missing,...
    'figuras_individuales_png',height(T),'figuras_individuales_pdf',height(T),...
    'figuras_comparativas_png',sum(manifest.figuras_png),'figuras_comparativas_pdf',sum(manifest.figuras_pdf),...
    'csv_numerico_finito',true,'rms_y_pico_verificados_con_original',true,'png_300_dpi',true,...
    'metodo_mfcc',raw.mfcc_method,'comparaciones',manifest.comparacion,'training',false);
fid=fopen(fullfile(cfg.output,'validacion_final.json'),'w','n','UTF-8');fprintf(fid,'%s',jsonencode(report,'PrettyPrint',true));fclose(fid);
disp(report);
informe_caracterizacion();
end

function comparar_categorias(featureFile,testOnly)
% Comparaciones descriptivas. No pruebas de hipotesis ni clasificacion.
cfg=configuracion_acustica();out=fullfile(cfg.output,'comparaciones');
if nargin<1,featureFile=fullfile(cfg.output,'features.csv');end
if nargin<2,testOnly=false;end
if testOnly,out=fullfile(cfg.output,'prueba_comparaciones');end
if ~exist(out,'dir'),mkdir(out);end
T=readtable(featureFile,'TextType','string','Encoding','UTF-8');
fields={'rms_dbfs','frecuencia_dominante_hz','centroide_hz','ancho_banda_hz','zcr_cruces_muestra','spectral_flatness'};
statsFields=T.Properties.VariableNames(varfun(@isnumeric,T,'OutputFormat','uniform'));
labels={'RMS (dBFS)','Frecuencia dominante (Hz)','Centroide (Hz)','Ancho de banda (Hz)','ZCR (cruces/muestra)','Planitud espectral (0-1)'};
jobs=cell(0,4);
isSpeech=T.categoria=="speech";isMachine=T.categoria=="machinery";isAlarm=T.categoria=="alarms";
jobs(end+1,:)={'voz_genero','Voz: genero declarado',isSpeech & ismember(T.genero_declarado,["female_feminine","male_masculine","female","male"]),T.genero_declarado};
acc=T.acento_declarado;acc(ismissing(acc))="";
jobs(end+1,:)={'voz_acentos','Voz: acento declarado (etiquetas completas en CSV)',isSpeech & strlength(acc)>0,acc};
jobs(end+1,:)={'maquinaria_tipos','Maquinaria: tipos respaldados por metadatos',isMachine,T.subcategoria};
condition=T.condicion_declarada;condition(ismissing(condition))="";
jobs(end+1,:)={'fresado_condiciones','Fresado: condiciones declaradas en rutas',isMachine & strlength(condition)>0,condition};
jobs(end+1,:)={'alarmas_tipos','Alarmas: General y Fire (revision documentada)',isAlarm,T.subcategoria};
jobs(end+1,:)={'voz_vs_maquinaria','Voz frente a maquinaria',isSpeech | isMachine,T.categoria};
jobs(end+1,:)={'alarmas_vs_maquinaria','Alarmas frente a maquinaria',isAlarm | isMachine,T.categoria};
jobs(end+1,:)={'voz_vs_alarmas','Voz frente a alarmas',isSpeech | isAlarm,T.categoria};
jobs(end+1,:)={'categorias','Comparacion de las tres categorias',true(height(T),1),T.categoria};
if testOnly,jobs=jobs(1,:);end
summary=struct('comparacion',{},'codigo_grupo',{},'grupo',{},'categoria',{},'subcategoria',{},'caracteristica',{},'segmentos',{},'fuentes',{},'grupos_independencia',{},'media',{},'desviacion_std',{},'mediana',{},'q25',{},'q75',{},'minimo',{},'maximo',{});
groupmap=struct('comparacion',{},'codigo',{},'etiqueta',{},'segmentos',{},'fuentes',{});
manifest=struct('comparacion',{},'estado',{},'grupos',{},'figuras_png',{},'figuras_pdf',{});
for job=1:size(jobs,1)
    key=jobs{job,1};heading=jobs{job,2};mask=jobs{job,3};G=string(jobs{job,4});G(ismissing(G))="";
    groups=unique(G(mask));groups=groups(strlength(groups)>0);
    if numel(groups)<2
        manifest(end+1)=struct('comparacion',key,'estado','omitida_menos_de_dos_grupos','grupos',numel(groups),'figuras_png',0,'figuras_pdf',0);continue %#ok<AGROW>
    end
    codes=compose("G%02d",(1:numel(groups))');colors=lines(numel(groups));plotLabels=strings(numel(groups),1);legendLabels=codes;
    if numel(groups)>7,colors=.82*turbo(numel(groups));end
    for g=1:numel(groups)
        sel=mask & G==groups(g);n=sum(sel);sources=numel(unique(T.source_id(sel)));indep=numel(unique(T.grupo_independencia(sel)));
        if strcmp(key,'voz_genero')
            if startsWith(groups(g),"female"),short="F";else,short="M";end
            plotLabels(g)=short+" (n="+n+")";legendLabels(g)=plotLabels(g);
        elseif numel(groups)<=3 && strlength(groups(g))<24
            plotLabels(g)=groups(g)+" (n="+n+")";legendLabels(g)=plotLabels(g);
        else,plotLabels(g)=codes(g)+" (n="+n+")";end
        groupmap(end+1)=struct('comparacion',key,'codigo',codes(g),'etiqueta',groups(g),'segmentos',n,'fuentes',sources); %#ok<AGROW>
        for f=1:numel(statsFields)
            v=T.(statsFields{f})(sel);q=percentiles(v,[.25 .5 .75]);
            cats=unique(T.categoria(sel));subs=unique(T.subcategoria(sel));
            summary(end+1)=struct('comparacion',string(key),'codigo_grupo',codes(g),'grupo',groups(g),...
                'categoria',join(cats,'|'),'subcategoria',join(subs,'|'),'caracteristica',string(statsFields{f}),...
                'segmentos',n,'fuentes',sources,'grupos_independencia',indep,'media',mean(v),'desviacion_std',std(v),...
                'mediana',q(2),'q25',q(1),'q75',q(3),'minimo',min(v),'maximo',max(v)); %#ok<AGROW>
        end
    end
    fig=figure('Visible','off','Color','white');tl=tiledlayout(fig,2,3,'Padding','compact','TileSpacing','compact');
    title(tl,[heading ' | cajas descriptivas'],'Interpreter','none');
    for f=1:numel(fields)
        ax=nexttile(tl);hold(ax,'on');
        for g=1:numel(groups),draw_box(ax,T.(fields{f})(mask & G==groups(g)),g,colors(g,:));end
        xlim(ax,[.5 numel(groups)+.5]);xticks(ax,1:numel(groups));xticklabels(ax,plotLabels);
        if numel(groups)<=3,xtickangle(ax,0);elseif numel(groups)>8,xtickangle(ax,75);else,xtickangle(ax,55);end
        grid(ax,'on');title(ax,labels{f});xlabel(ax,'Grupo (n: segmentos)');ylabel(ax,labels{f});
    end
    exportar_figura_acustica(fig,fullfile(out,[key '_cajas']),cfg);close(fig);
    fig=figure('Visible','off','Color','white');tl=tiledlayout(fig,2,3,'Padding','compact','TileSpacing','compact');title(tl,[heading ' | histogramas normalizados'],'Interpreter','none');
    for f=1:numel(fields)
        ax=nexttile(tl);hold(ax,'on');data=T.(fields{f})(mask);
        if f==1,edges=cfg.histogram_rms_edges;else
            a=min(data);b=max(data);if a==b,b=a+max(1,abs(a)*.1);end;edges=linspace(a,b,21);
        end
        for g=1:numel(groups)
            v=T.(fields{f})(mask & G==groups(g));counts=histcounts(v,edges,'Normalization','probability');
            stairs(ax,edges,[counts counts(end)],'LineWidth',1.3,'Color',colors(g,:),'DisplayName',char(legendLabels(g)));
        end
        grid(ax,'on');title(ax,labels{f});xlabel(ax,labels{f});ylabel(ax,'Fraccion de segmentos por intervalo');
        if f==1,legend(ax,'Location','best','FontSize',8,'Interpreter','none','NumColumns',1+(numel(groups)>6));end
    end
    exportar_figura_acustica(fig,fullfile(out,[key '_histogramas']),cfg);close(fig);
    fig=figure('Visible','off','Color','white');tl=tiledlayout(fig,1,2,'Padding','compact','TileSpacing','compact');title(tl,[heading ' | dispersion'],'Interpreter','none');
    for k=1:2
        ax=nexttile(tl);hold(ax,'on');
        for g=1:numel(groups)
            sel=mask & G==groups(g);
            if k==1,a=T.centroide_hz(sel);b=T.rms_dbfs(sel);else,a=T.zcr_cruces_muestra(sel);b=T.spectral_flatness(sel);end
            scatter(ax,a,b,25,colors(g,:),'filled','DisplayName',char(legendLabels(g)));
        end
        grid(ax,'on');
        if k==1,xlabel(ax,'Centroide (Hz)');ylabel(ax,'RMS (dBFS)');title(ax,'Distribucion espectral y nivel digital');else,xlabel(ax,'ZCR (cruces/muestra)');ylabel(ax,'Planitud espectral (0-1)');title(ax,'Cruces por cero y forma espectral');end
        legend(ax,'Location','best','FontSize',8,'Interpreter','none','NumColumns',1+(numel(groups)>6));
    end
    exportar_figura_acustica(fig,fullfile(out,[key '_dispersion']),cfg);close(fig);
    manifest(end+1)=struct('comparacion',key,'estado','generada_descriptiva_sin_inferencia','grupos',numel(groups),'figuras_png',3,'figuras_pdf',3); %#ok<AGROW>
    fprintf('COMPARACION %s: %d grupos\n',key,numel(groups));
end
summaryPath=fullfile(cfg.output,'resumen_estadistico.csv');
if testOnly,summaryPath=fullfile(out,'resumen_estadistico_prueba.csv');end
writetable(struct2table(summary),summaryPath,'Encoding','UTF-8');
writetable(struct2table(groupmap),fullfile(out,'grupos_comparaciones.csv'),'Encoding','UTF-8');
writetable(struct2table(manifest),fullfile(out,'comparaciones_generadas.csv'),'Encoding','UTF-8');
end
function q=percentiles(v,p)
v=sort(v(:));if numel(v)==1,q=repmat(v,size(p));else,q=interp1(1:numel(v),v,1+(numel(v)-1)*p,'linear');end
end
function draw_box(ax,v,x,color)
q=percentiles(v,[.25 .5 .75]);iqr=q(3)-q(1);low=min(v(v>=q(1)-1.5*iqr));high=max(v(v<=q(3)+1.5*iqr));
patch(ax,x+[-.27 .27 .27 -.27],[q(1) q(1) q(3) q(3)],color,'FaceAlpha',.22,'EdgeColor',color,'LineWidth',1.1);
plot(ax,x+[-.27 .27],[q(2) q(2)],'Color',color,'LineWidth',1.7);
plot(ax,[x x],[low q(1)],'Color',color);plot(ax,[x x],[q(3) high],'Color',color);
plot(ax,x+[-.15 .15],[low low],'Color',color);plot(ax,x+[-.15 .15],[high high],'Color',color);
out=v(v<low | v>high);plot(ax,repmat(x,size(out)),out,'.','Color',color);
end

function ejecutar_analisis()
% Punto de entrada secuencial para reproducir toda la caracterizacion.
% La ejecucion por lotes disjuntos es opcional y no requiere Parallel Toolbox.
cfg=configuracion_acustica();
caracterizar_audios('selftest');
caracterizar_audios('test');
if ~isfile(fullfile(cfg.output,'prueba_validada.json'))
    a=jsondecode(fileread(fullfile(cfg.output,'prueba_ejecutada.json')));
    a.estado='aprobada_por_verificacion_automatica_CSV_PNG_PDF_ejes';
    fid=fopen(fullfile(cfg.output,'prueba_validada.json'),'w','n','UTF-8');fprintf(fid,'%s',jsonencode(a,'PrettyPrint',true));fclose(fid);
end
caracterizar_audios('full');
finalizar_resultados();
end

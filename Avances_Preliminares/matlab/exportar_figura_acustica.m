function info = exportar_figura_acustica(fig,base,cfg)
% Exporta PNG 300 DPI y PDF con ejes/texto vectoriales e imagenes incrustadas.
set(fig,'Color','white','InvertHardcopy','off','Units','inches',...
    'Position',[0.5 0.5 cfg.figure_inches]);
ax=findall(fig,'Type','axes');
set(ax,'FontName',cfg.font,'FontSize',cfg.font_size,'Color','white',...
    'XColor',[0.1 0.1 0.1],'YColor',[0.1 0.1 0.1],'Box','on');
drawnow;
exportgraphics(fig,[base '.png'],'Resolution',cfg.png_dpi,'BackgroundColor','white');
exportgraphics(fig,[base '.pdf'],'ContentType','vector','BackgroundColor','white');
im=imfinfo([base '.png']);
info=struct('png',[base '.png'],'pdf',[base '.pdf'],'width',im.Width,'height',im.Height,'dpi_requested',cfg.png_dpi);
assert(im.Width>=2000 && im.Height>=1200,'Imagen demasiado pequena');
if isfield(im,'XResolution') && isfield(im,'ResolutionUnit')
    dpi=double(im.XResolution);
    if strcmpi(im.ResolutionUnit,'meter'),dpi=dpi*.0254;end
    info.dpi_recorded=dpi;
    assert(dpi>=299.8,'Resolucion PNG inferior a 300 DPI');
end
end

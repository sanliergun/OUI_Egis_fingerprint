function[] = fp_plot(fpscan_focused, fpscan_focused_filtered, BF, output_folder)

histogram_zero_reference = BF.histogram_zero_reference;
histogram_one_reference = BF.histogram_one_reference;

plotVar2a = real(fpscan_focused); % /max(max(real(fpscan_focused))); % Normalized beamformed image based on the compensated raw image.
plotVar2b = real(fpscan_focused_filtered);

plotVar2a_filtered_equalized = shift_image_hist(plotVar2a, histogram_zero_reference, histogram_one_reference);
plotVar2b_filtered_equalized = shift_image_hist(plotVar2b, histogram_zero_reference, histogram_one_reference);

plotX1 = (-BF.MRX/2+1/2:BF.MRX/2-1/2)*BF.dxy*1e3;
plotY1 = (-BF.MTX/2+1/2:BF.MTX/2-1/2)*BF.dxy*1e3;

%% image plot
plotin.datestr = datestr(now);
plotin.datestr(strfind(plotin.datestr, ' ')) = '_';
plotin.datestr(strfind(plotin.datestr, ':')) = '_';
plotin.datestr(strfind(plotin.datestr, '-')) = '_';
plotin.figpos = [1 229 680 628];
plotin.x1 = plotX1;
plotin.y1 = plotY1;
plotin.z1 = plotVar2b_filtered_equalized;
plotin.xlabel1 = 'X (mm)';
plotin.ylabel1 = 'Y (mm)';
plotin.title1 = ['Focused Image'];
plotin.fontsize1 = 20;
plotin.axis1 = [-5 5 -5 5];
plotin.clim1 = [0 1];
plotin.autocolor1 = 1;
plotin.filename = [output_folder '/fp_focused_' plotin.datestr];

    N_bins = 1000;
    N_exc = 0.05;
    if plotin.autocolor1
            [N_bins, Z_edges] = histcounts(plotin.z1);
            Z_bins = (Z_edges(1:end-1) + Z_edges(2:end))/2;
            Z_tmp = Z_bins(find(cumsum(N_bins)/numel(plotin.z1) < N_exc));
            Z_lo = Z_tmp(end);
            Z_tmp = Z_bins(find(cumsum(N_bins)/numel(plotin.z1) > 1-N_exc));
            Z_hi = Z_tmp(1);
            clim_W = std(plotin.z1(:));
            clim_0 = mean(plotin.z1(:));
            plotin.clim1 = clim_0 + [-clim_W clim_W]*3;
            plotin.clim1 = [Z_lo Z_hi];
    end

    figure;
    set(gcf,'ToolBar','none')
    set(gcf,'MenuBar','none')
    set(gcf,'DockControls','off')
    
    set(gcf,'Position', plotin.figpos);
    imagesc(plotin.x1, plotin.y1, plotin.z1);
    set(gca,'DataAspectRatio',[1 1 1]);
    set(gca,'Position',[0.1 0.1 0.82 0.82])
    axis('xy')
%     colorbar;
    grid off;
    xlabel(plotin.xlabel1);
    ylabel(plotin.ylabel1);
%     title(plotin.title1, 'Interpreter', 'none', 'Fontweight', 'normal');
    set(gca,'Fontsize', plotin.fontsize1);
    axis(plotin.axis1);
    set(gca, 'Clim', plotin.clim1)
    axis off;

    drawnow;
    if ~exist(output_folder)
        mkdir(output_folder)
    end
    print('-djpeg', plotin.filename);
    exportgraphics(gca, [plotin.filename '.png']),
%     print('-dpng', plotin.filename);
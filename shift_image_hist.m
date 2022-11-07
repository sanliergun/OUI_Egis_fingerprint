function[plotZ] = shift_image_hist(plotZ, histogram_zero_reference, histogram_one_reference)

% [plotZ_filtered] = fix_beamformed_image(plotZ, histogram_zero_reference)
% It also equalizes the histogram to provide a better contrast.

% % get the plotZ image filtered with a circular filter
% plotZ_filtered = real(get_2D_circular_filter(plotZ, dxy, k_lo, k_hi, dk_edge));

% get the histogram of the filtered image 
[N_bins, Z_edges] = histcounts(plotZ);
% find the centers of the bins
Z_bins = (Z_edges(1:end-1) + Z_edges(2:end))/2;
% find the bin below which there is only x% of the data
Z_tmp = Z_bins(find(cumsum(N_bins)/numel(plotZ) > (1-histogram_zero_reference)));
Z0 = Z_tmp(1);
Z_shift = 1 - Z0;
% 
% plotZ = plotZ + Z_shift;

Z_tmp = Z_bins(find(cumsum(N_bins)/numel(plotZ) > (histogram_zero_reference)));
Z0 = Z_tmp(1);
Z_tmp = Z_bins(find(cumsum(N_bins)/numel(plotZ) > (1-histogram_one_reference)));
Z1 = Z_tmp(1);
% 
plotZ = (plotZ - Z0)/(Z1-Z0);
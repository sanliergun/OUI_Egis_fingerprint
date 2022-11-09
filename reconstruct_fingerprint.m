function[] = reconstruct_fingerprint()

% load reference and fingerprint scans.
[rf_data_bl, rf_data_fp, fp_indices, error_flag] = load_HDF5_file();

% stop if there is an error.
if error_flag
    disp('Reference and Fingerprint scan size do not match or the files are not laoded.')
    return;
end

% processing parameters
BF.fs                       = 1.25e9;
BF.f                        = BF.fs/8;
BF.M                        = 250; % Sensor size BF.M by BF.M - this is fixed by the sensor
BF.P                        = 40e-6; % pitch - this is fixed by the sensor
BF.dz                       = 500e-6; % nominal focal depth/glass thickness - fixed by sensor
BF.medium.velocity          = 6000; % speed of sound - will be set in batch_beamform if a different value is provided in batch scan parameters list
BF.nup                      = 4; % number of beamforming points per pitch. The resulting pixel size is BF.P/BF.nup YOU MAY CHANGE THIS 
BF.TXfocus                  = 0.86 * BF.dz; % TX focus depth - will be set in batch_beamform if a different value is provided in batch scan parameters list
BF.RXfocus                  = 0.86 * BF.dz; % RX focus depth - will be set in batch_beamform if a different value is provided in batch scan parameters list
BF.TXaperture               = 12; % TX focus aperture - will be set in batch_beamform if a different value is provided in batch scan parameters list
BF.RXaperture               = 12; % RX focus aperture - will be set in batch_beamform if a different value is provided in batch scan parameters list
BF.windowtype               = 'tukey0.25';
BF.histogram_zero_reference = 0.025;
BF.histogram_one_reference  = 0.025;
BF.k_lo                     = 500;
BF.k_hi                     = 10500;

% get IQ data
BF.sample_length            = 60; % use only this many samples from the original sample size
BF.sample_start             = 21; % the time sample starts with sample_start and goes up to sample_start+sample_length-1
BF.sample                   = 24; % which sample(s) to use while doing batch_beamforming. Chose this appropriately depending on which data files you are loading.

prompt = {'Sample', 'Depth', 'Elements', 'Filter_lo', 'Filter_hi', 'Crop %'};
figname = 'Inputs to processing.';
numlines = 1;
defaults{1} = num2str(BF.sample);
defaults{2} = num2str(round(100*BF.TXfocus/BF.dz)/100);
defaults{3} = num2str(BF.TXaperture);
defaults{4} = num2str(BF.k_lo/1000);
defaults{5} = num2str(BF.k_hi/1000);
defaults{6} = num2str(BF.histogram_zero_reference*100);
answers = [];
answers = inputdlg(prompt, figname, numlines, defaults);
if ~isempty(answers)
    BF.sample = str2double(answers{1});
end

[blscan_amp, blscan_rad, bl_dead_elements] = get_IQ_sample(rf_data_bl, BF);
[fpscan_amp, fpscan_rad, fp_dead_elements] = get_IQ_sample(rf_data_fp, BF);
dead_RX_elements = sort( unique([bl_dead_elements fp_dead_elements]));
i1 = fp_indices(1);
i2 = fp_indices(2);
j1 = fp_indices(1);
j2 = fp_indices(2);

% Generate complex raw image
blscan = zeros(BF.M);
fpscan = zeros(BF.M);
blscan(i1:i2, j1:j2) = blscan_amp.*exp(1i*blscan_rad);
fpscan(i1:i2, j1:j2) = fpscan_amp.*exp(1i*fpscan_rad);
dead_RX_elements = dead_RX_elements + j1 - 1;

% Interpolate dead elements
for iy = 1:length(dead_RX_elements)
    ix = dead_RX_elements(iy);
    blscan(:, ix) = (blscan(:, ix-1) + blscan(:, ix+1))/2;
    fpscan(:, ix) = (fpscan(:, ix-1) + fpscan(:, ix+1))/2;
end

% filter and normalize raw image
BF.k_lo                     = 0;
if ~isempty(answers)
    BF.k_hi                     = str2double(answers{5}) * 1000;
end
BF.dk_lo                    = 1000;
BF.dk_hi                    = 1000;
[blscan_filtered, ~] = get_2D_circular_filter(blscan, BF.P, BF);
[fpscan_filtered, ~] = get_2D_circular_filter(fpscan, BF.P, BF);
fpscan_normalized = fpscan_filtered./blscan_filtered;

if ~isempty(answers)
    BF.TXfocus = str2double(answers{2})*BF.dz;
    BF.TXaperture = str2double(answers{3});
end
BF.RXfocus = BF.TXfocus; 
BF.RXaperture = BF.TXaperture;
% process and focus the raw image
[fpscan_focused, BF] = fp_focus(fpscan_normalized, BF);

% filter the focused image
if ~isempty(answers)
    BF.k_hi                     = str2double(answers{5}) * 1000;
    BF.k_lo                     = str2double(answers{4}) * 1000;
end
BF.dk_lo                    = 1000;
BF.dk_hi                    = 1000;
fpscan_focused_filtered = real(get_2D_circular_filter(fpscan_focused, BF.dxy, BF));

% Spread out the histogram, plot and save the image.
if ~isempty(answers)
    BF.histogram_zero_reference    = str2double(answers{6})/100; % shift the histogram so that the lower 2.5% in value is below 0
end
BF.histogram_one_reference     = BF.histogram_zero_reference; % shift the histogram so that the higher 2.5% in value is above 1
output_folder               = 'output_images/';
if ~exist(output_folder)
    mkdir(output_folder);
end

fp_plot(fpscan_focused, fpscan_focused_filtered, BF, output_folder);

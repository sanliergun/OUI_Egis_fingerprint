function[Jout_amp, Jout_rad, dead_rx_elements] = get_IQ_sample(rf_data, BF)
    
% tic;
sample_start = BF.sample_start;
sample_length = BF.sample_length;
fs = BF.fs;

N1 = size(rf_data, 1); % Y sample size
N2 = size(rf_data, 2); % X sample size
N3 = size(rf_data, 3); % time sample size
sample_length = min(sample_length, N3-sample_start+1);

dt = 1/fs;          % sampling time
t = (1:sample_length)*dt; % time vector
df = 1/(sample_length*dt); % frequency sample size (of the fft) after upsampling
f = (0:sample_length-1)*df; % frequency vector
tm = (t(1) + t(end))/2; % midpoint of the time vector 
f0 = fs/8; % TX signal frequency
w0 = 2*pi*f0; % TX signal frequency (radial)
BW_bpf = w0/2.4; % BPF bandwidth
BW_lpf = w0/2; % LPW bandwidth

II = cos(w0*t); % In-Phase Local Oscillaltor
QQ = sin(w0*t); % Quadrature Local Oscillator
bpf = BW_bpf*sinc(BW_bpf*(t-tm)/2/pi).*cos(w0*(t-tm)).*tukeywin(sample_length).'; % BPF in time domain
lpf = 2*BW_lpf*sinc(BW_lpf*(t-tm)/pi).*(hanning(sample_length).'); % LPF in time domain

% V1 and V1_bl are the target and baseline RF data converted from 3D to a 2D data set.
V1 = double(reshape(rf_data(:,:,sample_start:sample_start+sample_length-1), N1*N2, sample_length));

% V2 and V4_bl are band pass filtered versions of V1 and V3_bl
V2 = zeros(N1*N2, sample_length);
% V2_I and V2_Q are in-phase and quadrature components of V2
% V4_bl_I and V4_bl_Q are in-phase and quadrature components of V4_bl
V2_I = zeros(N1*N2, sample_length);
V2_Q = zeros(N1*N2, sample_length);
% Iout_amp and Iout_rad are the peak to peak amplitude (of the envelope) and phase of the target RF signal.
Iout_amp = zeros(N1*N2, sample_length);
Iout_rad = zeros(N1*N2, sample_length);

for i1 = 1:N1*N2
    V2(i1, :) = conv(V1(i1,:) - mean(V1(i1,:)), bpf, 'same')*dt/pi;
    V2_I(i1, :) = conv(V2(i1, :) .* II, lpf, 'same')*dt/pi;
    V2_Q(i1, :) = conv(V2(i1, :) .* QQ, lpf, 'same')*dt/pi;
    Iout_amp(i1, :) = sqrt(V2_I(i1, :).^2 + V2_Q(i1, :).^2);
    Iout_rad(i1, :) = atan2(-V2_Q(i1, :), V2_I(i1, :));
end

Iout_amp = reshape(Iout_amp, N1, N2, sample_length);
Iout_rad = reshape(Iout_rad, N1, N2, sample_length);

% energy in each element
Eout = squeeze(sum(Iout_amp.^2, 3));
% energy in RX elements
Wout = sum(Eout,1);
nn = (1:length(Wout));
p2 = polyfit(nn, Wout, 2);
p_threshold = 3;
% find the elements with low energy and label them as dead elements.
dead_rx_elements = find(Wout < polyval(p2, nn)/p_threshold);

Jout_amp = squeeze(Iout_amp(:,:,BF.sample));
Jout_rad = squeeze(Iout_rad(:,:,BF.sample));

deadelements = [11 23 25 33 35 37 58 71 80 122 139 146 158 162 200];
% toc;
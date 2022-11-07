function[Vout, kfilter] = get_2D_circular_filter(Vin, dxy, BF)

% [Vout] = get_2D_circular_filter(Vin, dx, k1, k2, dk)

% N = max(size(Vin,1), size(Vin,2));
% tic;
k_lo = BF.k_lo;
k_hi = BF.k_hi;
dk_lo = BF.dk_lo;
dk_hi = BF.dk_hi;

N = max(size(Vin,1), size(Vin,2));

Vtmp = ones(N) * median(Vin(:));
k1 = round((N-size(Vin,1))/2) + 1;
k2 = round((N-size(Vin,1))/2) + size(Vin,1);
j1 = round((N-size(Vin,2))/2) + 1;
j2 = round((N-size(Vin,2))/2) + size(Vin,2);
Vtmp(k1:k2, j1:j2) = Vin;
Vin = Vtmp;

Vin_fft = fftshift(fft2(Vin, N, N));

kr = (0:N-1)/(dxy*N);
kr = kr - kr(floor(N/2)+1);

ky1 = kr' * ones(1, N);
kx1 = ones(N, 1) * kr;
kr2 = sqrt(kx1.^2 + ky1.^2);

if k_lo <= 0
    kfilter = 1./(1+exp((kr2-k_hi)/(dk_hi/10)));
else
    kfilter = (1-1./(1+exp((kr2-k_lo)/(dk_lo/10)))) .* 1./(1+exp((kr2-k_hi)/(dk_hi/10)));
end

% figure;
% plot(kr*1e-3, kfilter(round(N/2), :))
% xlim([0 12.5])

Vout_fft = abs(Vin_fft) .* kfilter .* exp(1i*angle(Vin_fft));

Vout = ifft2(ifftshift(Vout_fft));

Vout = Vout(k1:k2, j1:j2);
% toc;
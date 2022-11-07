function[fpscan_out, BF] = fp_focus(fpscan_in, BF)
%%

    % aperture used for beamforming 2*n+1
    % tic;
    BF.k = 2*pi*BF.f/BF.medium.velocity;
    BF.NTX = BF.M - BF.TXaperture + 1;
    BF.NRX = BF.M - BF.RXaperture + 1;
    BF.dxy = BF.P/BF.nup;
    BF.MTX = BF.NTX * BF.nup;
    BF.MRX = BF.NRX * BF.nup;

    % beamforming phases
    dist_TX = zeros(BF.nup, BF.TXaperture);
    phi_TX = zeros(BF.nup, BF.TXaperture);
    dist_RX = zeros(BF.nup, BF.RXaperture);
    phi_RX = zeros(BF.nup, BF.RXaperture);
    beamform_TX = zeros(BF.nup, BF.TXaperture);
    beamform_RX = zeros(BF.nup, BF.RXaperture);
    
    if or(strcmp(BF.windowtype, 'tukey0.0'), strcmp(BF.windowtype, 'rect'))
        apod_TX = ones(1, BF.TXaperture);
        apod_RX = ones(1, BF.RXaperture);
    elseif strcmp(BF.windowtype, 'tukey0.25')
        apod_TX = tukeywin(BF.TXaperture, 0.25)';
        apod_RX = tukeywin(BF.RXaperture, 0.25)';
    elseif strcmp(BF.windowtype, 'tukey0.5')
        apod_TX = tukeywin(BF.TXaperture, 0.5)';
        apod_RX = tukeywin(BF.RXaperture, 0.5)';
    elseif strcmp(BF.windowtype, 'tukey0.75')
        apod_TX = tukeywin(BF.TXaperture, 0.75)';
        apod_RX = tukeywin(BF.RXaperture, 0.75)';
    elseif or(strcmp(BF.windowtype, 'tukey1.0'), strcmp(BF.windowtype, 'hanning'))
        apod_TX = hanning(BF.TXaperture)'; %.*(1*iseven((1:BF.TXaperture))+exp(-1i*pi/3)*isodd((1:BF.TXaperture)));
        apod_RX = hanning(BF.RXaperture)'; %.*(1*iseven((1:BF.RXaperture))+exp(-1i*pi/3)*isodd((1:BF.RXaperture)));
    elseif strcmp(BF.windowtype, 'hamming')
        apod_TX = hamming(BF.TXaperture)'; % .*isodd((1:2*BF.TXaperture+1)');
        apod_RX = hamming(BF.RXaperture)';
    else
        apod_TX = ones(1, BF.TXaperture); % .*isodd((1:2*BF.TXaperture+1)');
        apod_RX = ones(1, BF.RXaperture);
    end

    sources_TX = (-(BF.TXaperture-1)/2:(BF.TXaperture-1)/2)*BF.P;
    sources_RX = (-(BF.RXaperture-1)/2:(BF.RXaperture-1)/2)*BF.P;
    targets = (-(BF.nup-1)/2:(BF.nup-1)/2)*BF.dxy;
    for ix = 1:BF.nup
        dist_TX(ix, :) = sqrt((sources_TX-targets(ix)).^2 + BF.TXfocus(1)^2);
        phi_TX(ix, :) = BF.k * (dist_TX(ix, :) - BF.TXfocus(1));
        beamform_TX(ix, :) = exp(1i*phi_TX(ix, :)) .* apod_TX;
        dist_RX(ix, :) = sqrt((sources_RX-targets(ix)).^2 + BF.RXfocus(1)^2);
        phi_RX(ix, :) = BF.k * (dist_RX(ix,:) - BF.RXfocus(1));
        beamform_RX(ix, :) = exp(1i*phi_RX(ix, :)) .* apod_RX;
    end

    BF.sources_TX = sources_TX;
    BF.sources_RX = sources_RX;
    BF.targets = targets;
    BF.dist_TX = dist_TX;
    BF.dist_RX = dist_RX;
    BF.phi_TX = phi_TX;
    BF.phi_RX = phi_RX;
    BF.apod_TX = apod_TX;
    BF.apod_RX = apod_RX;
    BF.beamform_TX = beamform_TX;
    BF.beamform_RX = beamform_RX; 

    %% initialize matrices.
    fpscan_out = zeros(BF.MTX, BF.MRX);

    for i2 = 1:BF.nup
        for i1 = 1:BF.nup
            BFmatrix = flipud(fliplr(beamform_TX(i1, :).' * beamform_RX(i2,:)));
            fpscan_out(i1:BF.nup:end, i2:BF.nup:end) = conv2(fpscan_in, BFmatrix, 'valid')/sum(abs(BFmatrix(:)));
        end
    end
    % toc;



    
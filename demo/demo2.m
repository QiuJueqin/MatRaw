%% Demo 2
% Calibrate darkness and saturation levels for Nikon D3x DSLR

clc;

bit = 14; % valid bit depth for D3x

% read black image to calibrate darkness level
I_darkness = matrawread('.\MatRaw\sample_raw_files\Nikon_D3x\darkness.NEF',...
                        'bit', bit);
darkness = double( min(I_darkness(:)) );

% read completely overexposing image to calibrate saturation level
I_saturation = matrawread('.\MatRaw\sample_raw_files\Nikon_D3x\saturation.NEF',...
                          'bit', bit);
saturation = double( max(I_saturation(:)) ) - darkness;

% MATRAWREAD produces 16-bit output, so normalized the saturation level
% back to the original bit depth
saturation = saturation / (2^16 - 1) * (2^bit - 1);

% read color checker image with calibrated parameters
I_colorchecker = matrawread('.\MatRaw\sample_raw_files\Nikon_D3x\colorchecker.NEF',...
                            'bit', bit,...
                            'darkness', darkness,...
                            'saturation', saturation,...
                            'interpolation', true);

% scale brightness by 2 for better visualization
figure; imshow(2 * I_colorchecker);

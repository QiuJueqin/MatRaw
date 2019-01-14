%% Demo 2
% Calibrate darkness and saturation levels for Nikon D3x DSLR.
%
% These two parameters can be obtained via dcraw with '-d -v' option too,
% but performing a calibration experiment for your own camera model is a
% more secure way.
%
% % Sample raw files in this demo can be downloaded from
% https://1drv.ms/u/s!AniPeh_FlASDhVwZp5Bgujheu0N4
%
% See README.md for more info.

clc;

input_bit = 14; % valid bit depth for D3x

% read black image to calibrate darkness level.
% black image is an intermediate frame for calculating darkness level,
% which will be subtracted from the target image (ColorChecker image in
% this demo), so set the output bit depth to be equal to the input bit
% depth.
I_darkness = matrawread('.\MatRaw\sample_raw_files\Nikon_D3x\darkness.NEF',...
                        'inbit', input_bit,...
                        'outbit', 'same');
darkness = double( min(I_darkness(:)) );

% read completely overexposing image to calibrate saturation level.
% overexposing image is an intermediate frame for calculating saturation
% level, which will be used to clip and normalize the target image.
I_saturation = matrawread('.\MatRaw\sample_raw_files\Nikon_D3x\saturation.NEF',...
                          'inbit', input_bit,...
                          'outbit', 'same');
saturation = double( max(I_saturation(:)) ) - darkness;

% read color checker image with calibrated parameters
I_colorchecker = matrawread('.\MatRaw\sample_raw_files\Nikon_D3x\colorchecker.NEF',...
                            'inbit', input_bit,...
                            'darkness', darkness,...
                            'saturation', saturation,...
                            'interpolation', true);

% scale brightness by 2 for better visualization (not necessary)
figure; imshow(2 * I_colorchecker);

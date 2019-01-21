%% Demo 3
% Read .raf files from Fujifilm XT2 DSLM and perform basic processing to
% produce displayable linear sRGB image.
%
% % Sample raw files in this demo can be downloaded from
% https://1drv.ms/u/s!AniPeh_FlASDhVwZp5Bgujheu0N4
%
% See README.md for more info.

clc;

raw_dir = '.\MatRaw\sample_raw_files\Fujifilm_XT2\DSCF4886.RAF';

% automatically identify camera model and the darkness & saturation levels
% via dcraw
% NOTE: darkness and saturation levels reported by dcraw may be wrong for
% some camera models (e.g., Canon EOS 5D Mark IV)!!! Run your own
% calibration if the output image had a weird appearance, as done in
% demo2.m.
raw_params = getrawparams(raw_dir);
disp(raw_params);

read_attr = {'cfa', 'xtrans',...
             'darkness', raw_params.darkness,...
             'saturation', raw_params.saturation,...
             'interpolation', false,... % interpolation for X-Trans CFA will be extremely slow!
             'print', true};
         
converted = matrawread(raw_dir, read_attr{:});

% perform white-balancing and color space transformation for the converted
% raw image
proc_attr = {'cam2xyz', getcam2xyz(raw_params.camera_model),... % use 'getcam2xyz(camera_model)' to specify device-dependent color matrix
             'wb', 'manual',... % manual white balancing
             'scale', 2,... % scale by 200% for brighter output
             'print', true};

% only minimum processing (white balancing and color space transformation)
% will be performed
output = matrawproc(converted, proc_attr{:});

% use lin2rgb() to display sRGB image after gamma correction
figure; imshow(lin2rgb(output));

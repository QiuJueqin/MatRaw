%% Demo 3
% Read .raf files from Fujifilm XT2 DSLM and perform minimum processing to
% produce displayable linear sRGB image

clc;

raw_dir = '.\MatRaw\sample_raw_files\Fujifilm_XT2\DSCF4886.RAF';

% automatically identify camera model and the darkness & saturation levels
raw_params = getrawparams(raw_dir);
disp(raw_params);

read_attr = {'cfa', 'xtrans',...
             'darkness', raw_params.darkness,...
             'saturation', raw_params.saturation,...
             'interpolation', false,... % interpolation for X-Trans CFA will be extremely slow!
             'print', true};
         
raw = matrawread(raw_dir, read_attr{:});

% use 'getcam2xyz(camera_model)' to specify device-dependent color matrix
proc_attr = {'cam2xyz', getcam2xyz(raw_params.camera_model),...
             'wb', 'manual',... % manual white balancing
             'scale', 2,... % scale by 200% for brighter output
             'print', true};

% only minimum processing (white balancing and color space transformation)
% will be performed
output = matrawproc(raw, proc_attr{:});

% use lin2rgb() to display sRGB image after gamma correction
figure; imshow(lin2rgb(output));

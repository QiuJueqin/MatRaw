%% Demo 3
% Read .raf files from Fujifilm XT2 DSLM and perform minimum processing to
% produce displayable linear sRGB image

clc;

camera_model = 'Fujifilm XT2';

raw_dir = '.\MatRaw\sample_raw_files\Fujifilm_XT2\DSCF4886.RAF';
read_attr = {'cfa', 'xtrans',...
             'darkness', 1022,...
             'saturation', 15872,...
             'interpolation', false,... % interpolation for X-Trans CFA will be extremely slow!
             'print', true};
         
raw = matrawread(raw_dir, read_attr{:});

% use 'getcam2xyz(camera_model)' to specify device-dependent color matrix
proc_attr = {'cam2xyz', getcam2xyz(camera_model),...
             'wb', 'manual',... % manual white balancing
             'scale', 2,... % scale by 200% for brighter output
             'print', true};

% only minimum processing (white balancing and color space transformation)
% will be performed
output = matrawproc(raw, proc_attr{:});

% use lin2rgb() to display sRGB image after gamma correction
figure; imshow(lin2rgb(output));

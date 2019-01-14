%% demo 4
% calibrate fixed pattern noise (FPN) and pixel response non-uniformity
% (PRNU) for Nikon D3x DSLR (only for professional users who have demands
% for very high color accuracy).
%
% Sample raw files in this demo can be downloaded from
% https://1drv.ms/u/s!AniPeh_FlASDhV8LayVbCIreBU65
%
% See README.md and
% http://theory.uchicago.edu/~ejm/pix/20d/tests/noise/noise-p4.html for
% more info.


%% fixed pattern noise calibration
% Note: generating fpn template for some Nikon models is problematic,
%       because darkness levels for these models are zero and averaging
%       multiple frames can not produce actural fpn template (fpn +
%       gaussian read noise could be negative, but it will be clamped at
%       zero). So this calibration is only for demo purpose.

% to produce intermediate image (fpn and prnu templates, etc), set the
% output bit depth to 'same', and leave the 'darkness' and 'saturation' as
% default!
fpn_read_attr = {'demosaic', false,...
                 'inbit', 14,...
                 'outbit', 'same'};
             
% read 16 darkness frames in sequence
fpn_contents = dir('.\FPN\*.NEF');
for i = 1:numel(fpn_contents)
    raw_dir = fullfile(fpn_contents(i).folder, fpn_contents(i).name);
    stack(:, :, i) = matrawread(raw_dir, fpn_read_attr{:});
end

% average over 16 images
fpn_template = uint16(mean(double(stack), 3));

% show the fpn template (scaled for better visualization)
% you can notice some vertical banding noise
figure; imshow(fpn_template * 2^14); title('Fixed pattern noise template (x4096)');

clear stack


%% pixel response non-uniformity calibration
% subtract the fixed pattern noise template
prnu_read_attr = {'demosaic', true,...
                  'cfa', 'RGGB',...
                  'inbit', 14,...
                  'outbit', 'same',...
                  'fpntemplate', fpn_template};
              
% read 16 prnu frames in sequence
prnu_contents = dir('.\PRNU\*.NEF');
for i = 1:numel(fpn_contents)
    raw_dir = fullfile(prnu_contents(i).folder, prnu_contents(i).name);
    stack(:, :, :, i) = matrawread(raw_dir, prnu_read_attr{:});
end

% average over 16 images
prun_template = uint16(mean(double(stack), 4));

% show the prnu template
figure; imshow(prun_template * 4); title('Pixel response non-uniformity template');

clear stack


%% compare converted images with and without FPN and PRNU calibration
% read a colorchecker raw file
colorchecker_raw_dir = '.\ColorChecker\DSC_7058.NEF';

% image with FPN and PRNU calibration
I1 = matrawread(colorchecker_raw_dir,...
                'inbit', 14,...
                'saturation', 16383,...
                'fpntemplate', fpn_template,...
                'prnutemplate', prun_template,...
                'format', 'tiff',...
                'suffix', 'fpn+prun',...
                'print', true);

% image without FPN and PRNU calibration
I2 = matrawread(colorchecker_raw_dir,...
                'inbit', 14,...
                'saturation', 16383,...
                'darkness', 0,...
                'format', 'tiff',...
                'suffix', 'darkness_subtracted',...
                'print', true);

% calculate the diff image
diff = double(I1) - double(I2);
diff = (diff - min(diff(:))) / (max(diff(:)) - min(diff(:)));

figure; imshow(I1); title('With FPN reduction and PRNU compensation');
figure; imshow(I2); title('With normal darkness level subtration');
figure; imshow(diff); title('Difference');

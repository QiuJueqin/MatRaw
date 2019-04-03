%% demo 4
% calibrate fixed pattern noise (FPN) and pixel response non-uniformity
% (PRNU) for Nikon D3x DSLR (only for professional users who have demands
% for very high color accuracy).
%
% Sample raw files in this demo can be downloaded from
% https://1drv.ms/u/s!AniPeh_FlASDhX14vgSPzyeA3Ekf
% Please unzip the downloaded file to the root directory (.\MatRaw\)
%
% See README.md and
% http://theory.uchicago.edu/~ejm/pix/20d/tests/noise/noise-p4.html for
% more info.

clear; close all; clc;

%% load fixed pattern noise profile for Nikon D3x
fpn_profile = load('.\MatRaw\sample_raw_files\Nikon_D3x\fpn_Nikon_D3x.mat');


%% load pixel response non-uniformity profile for Nikon D3x
prnu_profile = load('.\MatRaw\sample_raw_files\Nikon_D3x\prnu_Nikon_D3x.mat');


%% compare converted images with and without FPN and PRNU calibration
% read a colorchecker raw file
dsg_raw_dir = '.\MatRaw\sample_raw_files\Nikon_D3x\DSC_7058.NEF';

% image with FPN and PRNU calibration
I1 = matrawread(dsg_raw_dir,...
                'inbit', 14,...
                'fpntemplate', fpn_profile.fpn_template,...
                'prnutemplate', prnu_profile.prnu_template,...
                'format', 'tiff',...
                'suffix', 'fpn+prun',...
                'print', true);

% image without FPN and PRNU calibration
I2 = matrawread(dsg_raw_dir,...
                'inbit', 14,...
                'format', 'tiff',...
                'suffix', 'darkness_subtracted',...
                'print', true);

% calculate the diff image
diff = abs(double(I1) - double(I2)) ./ double(I1);

figure; imshow(I1); title('With FPN reduction and PRNU compensation');
figure; imshow(I2); title('With normal darkness level subtration');
figure; imshow(128 * diff); title('Difference (\times{}128)');

function matrices = readmatrices()
% READMATRICES extracts color matrices from dcraw.c that convert XYZ
% triplets into camera RGB values, and calculates their inversions to get
% color matrices that converts camera RGB values into XYZ values, i.e.,
% matrices in dcraw.c:                                   XYZ -> camera RGB
% matrices returned by this script:                      camera RGB -> XYZ
%
% NOTE:
% 1. The extracted matrices have been saved in the current directory.
% Download the latest version of dcraw.c, replace the existing one, and run
% ========================================================
% matrices_cam2xyz = readmatrices();
% save .\MatRaw\matrices_cam2xyz.mat matrices_cam2xyz
% ========================================================
% only if your camera model is not included in the existing file.
%
% 2. This script has only been tested for dcraw.c versions 8.77 and 9.28.
% For other versions, modify the regular expressions in lines 31, 36, and
% 38, if encounters errors.
%
% Copyright
% Qiu Jueqin - Jan, 2019

[current_folder, ~, ~] = fileparts(mfilename('fullpath'));
dcraw_dir = fullfile(current_folder, 'dcraw.c');
assert(exist(dcraw_dir, 'file') == 2, 'dcraw.c is not found in ./MatRaw/ folder.');
fileID = fopen(dcraw_dir);
matrices = struct;
while ~feof(fileID)
    tline = fgetl(fileID);
    camera_model = regexpi(tline, '{ "(.+)", \d{1,3},', 'tokens');
    if ~isempty(camera_model)
        tline_ccm = fgetl(fileID);
        camera_model = camera_model{1}{1};
        % remove the special characters, and replace the whitespaces with '_'
        camera_model = regexprep(camera_model, '-|\*|\(|\)', '');
        camera_model = strrep(camera_model, ' ', '_');
        xyz2cam = regexpi(tline_ccm, '(-?\d{1,6},?){9}', 'tokens');
        if ~isempty(xyz2cam)
            % reshape and calculate the inverse matrix
            xyz2cam = reshape(str2num(xyz2cam{1}{1}), 3, 3)'/10000;
            cam2xyz = xyz2cam ^ (-1);
            % save to a struct
            matrices.(camera_model) = cam2xyz;
        else
            matrices.(camera_model) = diag([1, 1, 1]);
        end
    end
end
fclose(fileID);

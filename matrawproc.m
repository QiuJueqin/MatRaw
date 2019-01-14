function output = matrawproc(raw, varargin)
% MATRAWPROC (MATlab RAW data PROCess) performs very basic processing
% (scaling, white balancing, and color space transformation) to the raw
% image data from DSLR/DSLM.
%
% USAGE:
% output = matrawproc(raw, 'param', value, ...)
%        : process the raw data and return the output image
%
% INPUTS:
% raw: raw image in uint16 data type (after demosaicking, with darkness
%      level subtracted)
%
% OPTIONAL PARAMETERS:
% wb: white balancing option, can be a 3x1 vector, or 'manual', or
%     'grayworld'. If 'wb' is a numeric vector (in [R, G, B] format), the
%     script will use it as the gain coefficients to correct raw image's
%     white balance; if 'wb'='manual', the script will allow user to
%     manually select a reference nuetral region in the raw image, which 
%     will be used to calculate wb coefficients; if 'wb'='grayworld', gray
%     world algorithm will be employed to estimate wb coefficients.
%     (default = 'manual')
% cam2xyz: specify the device-dependent color matrix for the DSLR/DSLM,
%          which transforms the pixels' values from camera RGB color space
%          into CIE1931 XYZ color space. Dcraw provides such matrices, run 
%          =====================================
%          matrix = getcam2xyz(camera_model);
%          =====================================
%          to get the matrix for the target camera model. (default = 3x3
%          identity matrix)
% colorspace: specify the target color space for the output image.
%             Currently only sRGB and Adobe RGB are supported. Note that
%             this script only converts the XYZ values to the LINEAR RGB
%             values in the target color space, WITHOUT applying any
%             non-linear functions (e.g., gamma correction). (default =
%             'sRGB')
% scale: adjust image's brightness by (100*SCALE)%. This scaling will be
%        applied to the raw image in the very early stage, so it can be
%        analogously interpreted as digital amplification (of course noise
%        will be amplified too). (default = 1)
% print: print parameters. (default = false)
%
% NOTE:
% the function has only been tested on Windows with MATLAB version higher
% than R2016b and Dcraw version v9.27
%
% Copyright
% Qiu Jueqin - Jan, 2019

% parse input parameters
param = parseInput(varargin{:});

% only accept uint16 data
assert(isa(raw, 'uint16'), 'Only uint16 data type is supported. Run matrawread.m to get the readable image data.');
assert(ndims(raw) == 3 && size(raw, 3) == 3, 'The size of input array must be HxWx3.');
% convert to double data type for floating-point calculation
raw = double(raw) / 65535;

% scale image brightness and check if overexposure rises
nb_saturation_pixel = nnz(any(raw >= 1, 3));
raw = max(min(param.scale * raw, 1), 0);
if nnz(any(raw >= 1, 3)) > nb_saturation_pixel
    warning('Scaling the image intensities by %d%% causes overexposure for %d pixels (%.1f%%).',...
            100*param.scale,...
            nnz(any(raw >= 1, 3)) - nb_saturation_pixel,...
            300*(nnz(any(raw >= 1, 3)) - nb_saturation_pixel)/numel(raw));
end

% white balance coefficients can be explicitly given by passing a 3x1
% vector, or estimated by manually selecting a reference nuetral region, or
% estimated using gray world algorithm
if ischar(param.wb)
    if strcmpi(param.wb, 'manual')
        wb_gain = manualwb(raw); % manual selection
    elseif strcmpi(param.wb, 'grayworld')
        wb_gain = 1./mean(reshape(raw, [], 3), 1); % gray world algorithm
    else
        error('The value of ''wb'' is invalid. Expected input to be either ''manual'' or ''grayworld'' or a 1x3 vector.');
    end
elseif isnumeric(param.wb)
    assert(all(size(param.wb) == [1,3]), 'Expected the value of ''wb'' to be a 1x3 vector.');
    wb_gain = param.wb;
else
	error('The value of ''wb'' is invalid. Expected input to be either ''manual'' or ''grayworld'' or a 1x3 vector.');
end

% normalize the white balance coefficients
wb_gain = wb_gain / min(wb_gain);

% store in 'param'
param.wb_gain = wb_gain;

% white balancing
wb_img = raw .* reshape(wb_gain, 1, 1, 3);
wb_img = max(min(wb_img, 1), 0);

% transform image from camera color space into target color space
if ~isempty(param.cam2xyz)
    switch lower(param.colorspace)
        case 'srgb'
            xyz2rgb = [3.2404542, -1.5371385, -0.4985314;...
                      -0.9692660,  1.8760108,  0.0415560;...
                       0.0556434, -0.2040259,  1.0572252]; % from wiki
        case 'adobe-rgb'
            xyz2rgb = [2.0413690, -0.5649464, -0.3446944;...
                      -0.9692660,  1.8760108,  0.0415560;...
                       0.0134474, -0.1183897,  1.0154096];  % from wiki
    end
    
    % color matrix chain rule
    cam2rgb = xyz2rgb * param.cam2xyz;
    
    % matrix inverse
    rgb2cam = cam2rgb ^ (-1);
    
    % normalized each row in the 'rgb2cam' such that neutral points are
    % remained unchanged in both color spaces (assuming white point is
    % D65), otherwise white balancing will be meaningless
    rgb2cam = rgb2cam ./ sum(rgb2cam, 2);
    
    % matrix inverse again
    cam2rgb = rgb2cam ^ (-1);
    
    % store in 'param'
    param.cam2rgb = cam2rgb;
    
    % color correction
    cc_img = camera2rgb(wb_img, cam2rgb);
else
    warning('Color correction will not be performed because no cam2xyz matrix is given.');
    cc_img = wb_img;
    param.cam2xyz = diag([1, 1, 1]);
    param.cam2rgb = diag([1, 1, 1]);
end

output = max(min(cc_img, 1), 0);

if param.print == true
    printParams(param);
end

end


function wb_gain = manualwb(img)
% MANUALWB allows user to manually select a reference neutral region in the
% input image IMG and accordingly calculates white balance coefficients 
fig = figure('name', 'Drag a rectangle to select the reference neutral region.');
fig.IntegerHandle = 'off';
imshow(img);
rect = round(getrect(fig));
roi = img(rect(2)+(0:rect(4)), rect(1)+(0:rect(3)), :);
wb_gain = 1./mean(reshape(roi, [], 3), 1); % local gray world algorithm
close(fig);
end


function Irgb = camera2rgb(Icam, cam2rgb)
% CAMERA2RGB transforms input image ICAM from camera color space into the
% target color space, using transformation matrix CAM2RGB
[h, w, ~] = size(Icam);
Irgb = reshape((cam2rgb * reshape(Icam, h*w, 3)')', h, w, 3);
end


function param = parseInput(varargin)
% Parse inputs & return structure of parameters

parser = inputParser;
parser.addParameter('cam2xyz', [], @(x)validateattributes(x, {'numeric'}, {'size',[3,3]}));
parser.addParameter('colorspace', 'sRGB', @(x)any(strcmpi(x, {'sRGB', 'Adobe-RGB'})));
parser.addParameter('print', false, @(x)islogical(x));
parser.addParameter('scale', 1, @(x)validateattributes(x, {'numeric'}, {'nonnegative'}));
parser.addParameter('wb', 'manual', @(x)validateattributes(x, {'numeric', 'char'}, {}));
parser.parse(varargin{:});
param = parser.Results;
end


function printParams(param)
% make format pretty
if strcmpi(param.colorspace, 'sRGB')
    param.colorspace = 'sRGB';
elseif strcmpi(param.colorspace, 'Adobe-RGB')    
    param.colorspace = 'Adobe-RGB';
end
width = 42;
disp('Processing parameters:')
disp('================================================================================');
len = fprintf('White balance coefficients vector:');
fprintf([repmat(' ', 1, width-len), '%.2f(R), %.2f(G), %.2f(B)'], param.wb_gain);
if strcmpi(param.wb, 'manual')
    fprintf(' (manual)\n');
elseif strcmpi(param.wb, 'grayworld')
    fprintf(' (gray world)\n');
else
    fprintf('\n');
end
len = fprintf('Brightness scale:');
fprintf([repmat(' ', 1, width-len), '%.1f\n'], param.scale);
len = fprintf('Camera RGB => XYZ matrix:');
fprintf([repmat(' ', 1, width-len), '[%5.2f, %5.2f, %5.2f ]\n'], param.cam2xyz(1,:));
fprintf([repmat(' ', 1, width), '[%5.2f, %5.2f, %5.2f ]\n'], param.cam2xyz(2,:));
fprintf([repmat(' ', 1, width), '[%5.2f, %5.2f, %5.2f ]\n'], param.cam2xyz(3,:));
len = fprintf('Target color space:');
fprintf([repmat(' ', 1, width-len), '%s (linear)\n'], param.colorspace);
len = fprintf('Camera RGB => %s (linear) matrix:', param.colorspace);
fprintf([repmat(' ', 1, width-len), '[%5.2f, %5.2f, %5.2f ]\n'], param.cam2rgb(1,:));
fprintf([repmat(' ', 1, width), '[%5.2f, %5.2f, %5.2f ]\n'], param.cam2rgb(2,:));
fprintf([repmat(' ', 1, width), '[%5.2f, %5.2f, %5.2f ]\n'], param.cam2rgb(3,:));
disp('================================================================================');
end
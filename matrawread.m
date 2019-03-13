function varargout = matrawread(raw_dir, varargin)
% MATRAWREAD (MATlab RAW data READ) converts raw data from DSLR/DSLM to 
% MATLAB-readable file(s) and, optionally, applies some noise reduction in
% raw data (before demosaicking).
% Make sure dcraw.exe is accessible before running. If not, place it in
% c:\windows\ or add its path to the value of the PATH environment 
% variable. If multiple versions of dcraw.exe are accessible, modify line
% 178 to specify the version you wish to call.
%
% USAGE:
% matrawread(raw_dir, 'param', value, ...)
%   : save the converted file(s) to the disk
%
% I = matrawread(raw_dir, 'param', value, ...)
%   : load the converted image into MATLAB workspace
%
% [I, image_info] = matrawread(raw_dir, 'param', value, ...)
%   : load the converted image and raw data info into MATLAB workspace
%
% INPUTS:
% raw_dir:       path of the raw data file(s). Use wildcard '*' to select
%                all files in the directory, e.g., 'c:\foo\*.NEF'
%
% OPTIONAL PARAMETERS:
% demosica:      determine whether to apply demosaicking. It can be either
%                true or false. If set to false, 'cfa' and 'interpolation'
%                parameter will be ignored. For most cases 'demosaic' will
%                be true, except for those where intermediate undemosaicked
%                images are required to output to serve as templates, for
%                example, fixed pattern noise subtraction, pixel response
%                non-uniformity compensation, and other raw image noise
%                reduction applications. (default = true)
% cfa:           specify the color filter array for the DSLR/DSLM. Its
%                value can only be one of 'RGGB', 'BGGR', 'GRBG', 'GBRG',
%                and 'XTrans'. (default = 'RGGB')
% inbit:         specify the valid bit depth for the input raw data.
%                (default = 14) 
% outbit:        specify the valid bit depth for the input raw data. Use
%                'same' to set it to be equal to the input bit depth for
%                those cases where intermediate images are required to
%                output. (default = 16)
% darkness:      specify the darkness level for the DSLR/DSLM. If unknown,
%                capture one frame with lens cap on and then evaluate it.
%                (default = 0)
% saturation:    specify the saturation level for the DSLR/DSLM. If
%                unknown, overexpose a scene by 5 or 6 stops and then
%                evaluate it. (default = 2^inbit-1)
% format:        select in which data format to store the converted
%                file(s). Only 'mat', 'ppm', 'png', and 'tiff' are
%                supported. If an image format is required, 'ppm' is highly
%                recommended. (default = 'mat')
% interpolation: can be either true or false. If true, MATLAB built-in
%                function demosaic() will be used to generate a H*W*3 color
%                image from the H*W*1 (grayscale) cfa image. Otherwise, no
%                interpolation will be performed, thus generating a 
%                (H/2)*(W/2)*3 color image (or (H/3)*(W/3)*3 for Fujifilm's
%                X-Trans CFA). Note: interpolation for X-Trans CFA will be
%                extremely slow. (default = false)
% fpntemplate:   specify the fixed pattern noise template, which will be
%                subtracted from the converted raw image, thus the fixed
%                pattern noise can be removed. The template should be a H*W
%                undemosaicked image in uint16 data type, where H and W is
%                equal to the height and width of the target image. If
%                'fpntemplate' is given, 'darkness' will be ignored. This
%                parameter is only for professional users who have demands
%                for very high accuracy. See ./demo/demo4.m for more
%                details about how to produce a template image. (default =
%                [])
% prnutemplate:  specify the pixel response non-uniformity template. Pixel
%                values in the converted raw image will be divided
%                pixelwise by the values in this template, so the pixel
%                response non-uniformity can be compensated (sometimes also
%                known as flat field correction). The template should be a
%                H*W*3 DEMOSAICKED image in uint16 data type, where H and W
%                is equal to the height and width of the target image. The
%                PRNU compensation will be applied to the target image
%                after the darkness level subtraction (or fpn reduction)
%                and demosaicking, so the template image should be darkness
%                level subtracted (or fpn removed) as well. This parameter
%                is only for professional users (even more unusual than fpn
%                reduction). See ./demo/demo4.m for more details about how
%                to produce a template image. (default = [])
% save:          specify whether to save the converted file to the disk.
%                Only alternative when an output argument is given and no
%                wildcard (*) is used in raw_dir. Otherwise, it will be
%                forced to be true. Set this to false to save time if you
%                only wish to access the converted data in MATLAB
%                workspace. (default = false)
% rename:        can be either true or false. If true, output file(s) will
%                be renamed with capturing parameters (exposure time, F
%                number, ISO, time stamp). (default = false)
% keeppgm:       can be either true or false. If true, the temporary .pgm
%                file generated by dcraw.exe will be kept. (default =
%                false)
% suffix:        add a suffix to the output file name(s). This will be
%                useful if you want to convert the same raw data with
%                different settings. (default = '')
% print:         whether to print parameters. (default = false)
%
% See demo folder for more details.
%
% NOTE:
% the function has only been tested on Windows with MATLAB version higher
% than R2016b and Dcraw version v9.27
%
% Copyright
% Qiu Jueqin - Jan, 2019

% parse input parameters
param = parseInput(varargin{:});

% if no output argument is specified, or a output fotmat is given, force to
% save the converted file(s) to the disk
if nargout == 0 || ~strcmpi(param.format, 'N/A')
    param.save = true;
end

% if the converted file(s) is to be saved to the disk but no output format
% is given, use .mat as default format
if param.save == true && strcmpi(param.format, 'N/A')
    param.format = 'mat';
end

if param.demosaic == false && param.interpolation == true
    warning('Color interpolation will be invalid because demosaic is truned off.');
    param.interpolation = false;
end
% check param.outbit
% 16-bit is the recommended option for most cases
% use 'same' only for those intermediate cases, e.g., pattern read noise
% subtraction, pixel response non-uniformity compensation (a.k.a flat field
% correction), etc.
if ischar(param.outbit)
    if strcmpi(param.outbit, 'same')
        param.outbit = param.inbit;
    else
        error('Output bit depth can only be either an integer or ''same''.');
    end
else
    assert(floor(param.outbit) == param.outbit, 'Output bit depth must be an integer.');
end

% set the darkness level to 0 if fixed pattern noise template is given
if ~isempty(param.fpntemplate) && param.darkness ~= 0
    warning('Fixed pattern noise template is given. Darkness level will be forced to be 0.');
    param.darkness = 0;
end

% if no saturation level is specified, use (2^bit - 1) as default
if isempty(param.saturation)
    param.saturation = 2^param.inbit - 1;
else
    assert(param.saturation <= 2^param.inbit - 1, 'Saturation level %0.f is greater than the valid maximum value %d (2^%d-1).',...
                                                param.saturation, 2^param.inbit-1, param.inbit);
end

% list all raw data files
folder_contents = dir(raw_dir);

if numel(folder_contents) > 1
    param.save = true;
    param.print = true;
    disp('Processes started. Do not modify the temporary .pgm files before the processes completed.');
    if nargout > 0
        warning('To load image into workspace, use a specified file name instead of a wildcard (*).');
    end
elseif numel(folder_contents) == 0
    error('File %s is not found. Make sure the path is accessible by MATLAB, or consider to use absolute path.', raw_dir);
end

if param.print == true
    printParams(param);
end

for i = 1:numel(folder_contents)
    if numel(folder_contents) > 1
        fprintf('Processing %s... (%d/%d)\n', folder_contents(i).name, i, numel(folder_contents));
    end
    raw_file = fullfile(folder_contents(i).folder, folder_contents(i).name);
    [folder, name, extension] = fileparts(raw_file);
    
    % call dcraw.exe in cmd and convert raw data to a .pgm file, without
    % any further processing
    [status, cmdout] = system(['dcraw -4 -D ', raw_file]); % save to .pgm file(s)
    if status
        error(cmdout);
    end
    
    pgm_file = strrep(raw_file, extension, '.pgm');
    % read image from the .pgm file
    raw = imread(pgm_file);

    % delete the .pgm file
    if param.keeppgm == false
        delete(pgm_file);
    end
    
    % subtract the fixed pattern noise template OR darkness level
    if isempty(param.fpntemplate)
        if min(raw(:)) < param.darkness
            warning('The minimum ADU (%d) is smaller than the specified darkness level (%d). Please check if there exist dead pixels. (%d pixels detected.)',...
                    min(raw(:)), param.darkness, nnz(raw < param.darkness));
        end
        % subtract the darkness level
        raw = raw - param.darkness;
    else
        assert(isequal(size(raw), size(param.fpntemplate)), 'Fixed pattern noise template must be of the same size as the target image.');
        assert(isa(param.fpntemplate, 'uint16'), 'Only uint16 data type is supported for the fixed pattern noise template, in case of scale mismatching between two images.');
        raw = raw - param.fpntemplate;
    end

    % demosaicking
    if param.demosaic == true
        if param.interpolation == true
            raw = demosaic_(raw, param.cfa);
        else
            raw = demosaic_nointerp(raw, param.cfa);
        end
    end
    
    % pixel response non-uniformity compensation
    if ~isempty(param.prnutemplate)
        assert(isequal(size(raw), size(param.prnutemplate)), 'Pixel response non-uniformity template must be of the same size as the target image.');
        assert(isa(param.prnutemplate, 'uint16'), 'Only uint16 data type is supported for the pixel response non-uniformity template, in case of scale mismatching between two images.');
        % calculate maxima for 3 channels individually
        ch_max = squeeze(max(max(param.prnutemplate, [], 1), [], 2)); 
        % normalize it such that the minimum in the compensation image is
        % equal to 1
        compensation = double(reshape(ch_max, 1, 1, 3)) ./ double(param.prnutemplate);
        raw = uint16( double(raw) .* compensation );
    end
    
    % normalize the image and convert it to (param.outbit)-bit data type
    if param.outbit == param.inbit &&...
            param.saturation == (2^param.outbit - 1) &&...
            param.darkness == 0
        % do nothing, only for acceleration (no data type conversion)
    else
        if param.outbit <= 8
            raw = uint8( double(raw) / (param.saturation - param.darkness) * (2^param.outbit - 1) );
        elseif param.outbit <= 16
            raw = uint16( double(raw) / (param.saturation - param.darkness) * (2^param.outbit - 1) );
        elseif param.outbit <= 32
            raw = uint32( double(raw) / (param.saturation - param.darkness) * (2^param.outbit - 1) );
        else
            error('Unsigned 32-bit is the maximum supported bit depth.');
        end
    end
    
    if param.save == true
        % extract capturing parameters and rename the file
        if param.rename == true
            try
                info = imfinfo(raw_file);
                if numel(info) > 1
                    info = info(1);
                end
                exposure = info.DigitalCamera.ExposureTime;
                f_number = info.DigitalCamera.FNumber;
                iso = info.DigitalCamera.ISOSpeedRatings;
                datatime = info.DigitalCamera.DateTimeDigitized;
                datatime = strrep(datatime,':','');
                datatime = strrep(datatime,' ','_');
                name = strjoin({name,...
                                sprintf('EXP%.0f', 1000*exposure),... % shutter speed in millisecond
                                sprintf('F%.1f', f_number),...
                                sprintf('ISO%d', iso),...
                                datatime}, '_');
            catch
                warning('Can not extract capturing info.');
            end
        end

        % add suffix
        if ~isempty(param.suffix)
            name = strjoin({name, param.suffix}, '_');
        end

        % save the image in user-specified format
        name = strjoin({name, param.format}, '.');
        save_dir = fullfile(folder, name);
        if strcmpi(param.format, 'mat')
            save(save_dir, 'raw', '-v7.3');
        elseif strcmpi(param.format, 'ppm')
            imwrite(raw, save_dir);
        elseif strcmpi(param.format, 'tiff')
            imwrite(raw, save_dir, 'compression', 'none');
        elseif strcmpi(param.format, 'png')
            imwrite(raw, save_dir, 'bitdepth', 16);
        end
    end
    
end

if nargout > 0
    varargout{1} = raw;
end
if nargout > 1
    info = imfinfo(raw_file);
    if numel(info) > 1
        info = info(1);
    end
    varargout{2} = info;
end

if numel(folder_contents) > 1
    disp('Done.');
end

end


function RGB = demosaic_(raw, sensorAlignment)
% a wrapper for built-in demosaic funtion    
assert(isa(raw, 'uint16'));
if strcmpi(sensorAlignment, 'XTrans')
    disp('Interpolation for X-Trans CFA will be slow. Keep your patience...');
    RGB = uint16(demosaic_xtrans(double(raw)));
else
    RGB = demosaic(raw, sensorAlignment);
end
end

        
function RGB = demosaic_nointerp(raw, sensorAlignment)
% DEMOSAIC_NOINTERP performs demosaicking without interpolation
% 
% MATLAB built-in demosaic function generates a H*W*3 color image from a
% H*W*1 grayscale cfa image by 'guessing' the pixel's RGB values from its
% neighbors, which might introduces some color biases (althout negligible
% for most of applications).
%
% DEMOSAIC_NOINTERP generates a (H/2)*(W/2)*3 color image from the original
% cfa image without interpolation. The G value of each pixel in the output
% color image is produced by averaging two green sensor elements in the
% quadruplet.

if strcmpi(sensorAlignment, 'XTrans')
    RGB = demosaic_xtrans_nointerp(raw);
else
    [height, width] = size(raw);
    if mod(height, 2) ~= 0
        raw = raw(1:end-1, :);
    end
    if mod(width, 2) ~= 0
        raw = raw(:, 1:end-1);
    end

    switch upper(sensorAlignment)
        case 'RGGB'
            [r_begin, g1_begin, g2_begin, b_begin] = deal([1, 1], [1, 2], [2, 1], [2, 2]);
        case 'BGGR'
            [r_begin, g1_begin, g2_begin, b_begin] = deal([2, 2], [1, 2], [2, 1], [1, 1]);
        case 'GBRG'
            [r_begin, g1_begin, g2_begin, b_begin] = deal([2, 1], [1, 1], [2, 2], [1, 2]);
        case 'GRBG'
            [r_begin, g1_begin, g2_begin, b_begin] = deal([1, 2], [1, 1], [2, 2], [2, 1]);
    end
    R = raw(r_begin(1):2:end, r_begin(2):2:end);
    G1 = raw(g1_begin(1):2:end, g1_begin(2):2:end);
    G2 = raw(g2_begin(1):2:end, g2_begin(2):2:end);
    B = raw(b_begin(1):2:end, b_begin(2):2:end);
    RGB  = cat(3, R, (G1 + G2)/2, B);
end
end


function param = parseInput(varargin)
% Parse inputs & return structure of parameters

parser = inputParser;
parser.PartialMatching = false;
parser.addParameter('cfa', 'RGGB', @(x)any(strcmpi(x, {'RGGB', 'BGGR', 'GBRG', 'GRBG', 'XTrans'}))); % color filter array
parser.addParameter('darkness', 0, @(x)validateattributes(x, {'numeric'}, {'nonnegative'}));
parser.addParameter('demosaic', true, @(x)islogical(x));
parser.addParameter('format', 'N/A', @(x)any(strcmpi(x, {'N/A', 'mat', 'ppm', 'png', 'tiff'})));
parser.addParameter('fpntemplate', [], @(x)isnumeric(x)); % fixed pattern noise template
parser.addParameter('inbit', 14, @(x)validateattributes(x, {'numeric'}, {'integer', 'nonnegative'}));
parser.addParameter('rename', false, @(x)islogical(x));
parser.addParameter('interpolation', false, @(x)islogical(x));
parser.addParameter('keeppgm', false, @(x)islogical(x));
parser.addParameter('outbit', 16, @(x)validateattributes(x, {'numeric', 'char'}, {}));
parser.addParameter('print', false, @(x)islogical(x));
parser.addParameter('prnutemplate', [], @(x)isnumeric(x)); % pixel response non-uniformity template (flat field template)
parser.addParameter('saturation', [], @(x)validateattributes(x, {'numeric'}, {'nonnegative'}));
parser.addParameter('save', false, @(x)islogical(x));
parser.addParameter('suffix', '', @(x)ischar(x));
parser.parse(varargin{:});
param = parser.Results;
end


function printParams(param)
% make format pretty
if param.save == true
    attr_idx = [3, 6, 10, 2, 13, 1, 8, 5, 12, 14, 4, 7, 15, 9];
else
    attr_idx = [3, 6, 10, 2, 13, 1, 8, 5, 12, 14, 9];
end
if strcmpi(param.cfa, 'XTrans')
    param.cfa = 'X-Trans';
else
    param.cfa = upper(param.cfa);
end
if isempty(param.fpntemplate)
    param.fpntemplate = 'None';
else
    [h, w] = size(param.fpntemplate);
    param.fpntemplate = sprintf('%d*%d %s matrix', h, w, class(param.fpntemplate));
end
if isempty(param.prnutemplate)
    param.prnutemplate = 'None';
else
    [h, w, ch] = size(param.prnutemplate);
    param.prnutemplate = sprintf('%d*%d*%d %s matrix', h, w, ch, class(param.prnutemplate));
end
if isempty(param.suffix)
    param.suffix = 'None';
end
disp('Conversion parameters:')
disp('================================================================================');
field_names = fieldnames(param);
field_name_dict.cfa = 'Color filter array';
field_name_dict.darkness = 'Darkness level';
field_name_dict.demosaic = 'Demosaic';
field_name_dict.format = 'Output format';
field_name_dict.fpntemplate = 'Fixed pattern noise template';
field_name_dict.inbit = 'Input bit depth';
field_name_dict.rename = 'Rename with capturing info';
field_name_dict.interpolation = 'Color interpolation';
field_name_dict.keeppgm = 'Keep the temporary .pgm files';
field_name_dict.outbit = 'Output bit depth';
field_name_dict.prnutemplate = 'Pixel response nonuniformity template';
field_name_dict.saturation = 'Saturation level';
field_name_dict.save = 'Save outputs to the disk';
field_name_dict.suffix = 'Filename suffix';
for i = attr_idx
    if ~strcmpi(field_names{i}, 'print')
        len = fprintf('%s:',field_name_dict.(field_names{i}));
        fprintf(repmat(' ', 1, 42-len));
        fprintf('%s\n', string(param.(field_names{i})));
    end
end
disp('================================================================================');
end

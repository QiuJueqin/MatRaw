function params = getrawparams(raw_dir)
% GETRAWPARAMS identifies darkness level, saturation level, and default
% white balance multipliers for the target raw file via dcraw.

assert(exist(raw_dir, 'file') == 2, 'File %s is not found.', raw_dir);
[~, ~, extension] = fileparts(raw_dir);

% dcraw with option -v will print raw parameters
[status, cmdout] = system(['dcraw -v -d ', raw_dir]); % save to .pgm file(s)
if status
    error(cmdout);
end

% delete the .pgm file
pgm_file = strrep(raw_dir, extension, '.pgm');
delete(pgm_file);

% get parameters
camera_model = regexp(cmdout, 'Loading (.*) image', 'tokens', 'ignorecase');
params.camera_model = camera_model{1}{1};
darkness = regexp(cmdout, 'darkness (\d+),', 'tokens', 'ignorecase');
params.darkness = str2double(darkness{1}{1});
saturation = regexp(cmdout, 'saturation (\d+),', 'tokens', 'ignorecase');
params.saturation = str2double(saturation{1}{1});
multipliers = regexp(cmdout, 'multipliers (\d+\.\d+) (\d+\.\d+) (\d+\.\d+) (\d+\.\d+)', 'tokens', 'ignorecase');
params.multipliers = str2double(multipliers{1});

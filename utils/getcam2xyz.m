function cam2xyz = getcam2xyz(camera_model)
% GETCAM2XYZ returns the color mactrix (camera RGB -> XYZ) of the given
% camera model
% 
% Input CAMERA_MODEL can be completely or partly matched to the models in
% the stored database. The script will search for its closest match(es).
% Run 
% ========================================================
% load('matrices.mat')
% disp(fieldnames(matrices_cam2xyz));
% ========================================================
% to view all supported camera models.
%
% If your camera model is not found in matrices.mat, download the latest 
% dcraw.c and run
% ========================================================
% matrices_cam2xyz = readmatrices();
% save .\matrawread\matrices.mat matrices_cam2xyz
% ========================================================
% to update the database.
%
% Copyright
% Qiu Jueqin - Jan, 2019

% remove the special characters, and replace the whitespaces with '_'
camera_model = regexprep(camera_model, '-|\*|\(|\)', '');
camera_model = strrep(camera_model, ' ', '_');

% load color matrices database
matrices = load('matrices_cam2xyz.mat');

% extract all camera model names
all_camera_models = fieldnames(matrices.matrices_cam2xyz);

% find if the perfect matching exists
camera_model_index = find(strcmpi(all_camera_models, camera_model));

if ~isempty(camera_model_index)
    % if the perfect matching exists, load the color matrix
    cam2xyz = matrices.matrices_cam2xyz.(all_camera_models{camera_model_index});
else
    % if no perfect matching exists, find if any camera model name
    % contains the input name
    match_indices = find(contains(all_camera_models, camera_model, 'IgnoreCase', true));
    if isempty(match_indices)
        % if no containing exists, find index using Levenshtein and editor distance 
        match_indices = strnearest(lower(camera_model), lower(all_camera_models));
    end
    if length(match_indices) >= 1
        % list all matched camera model(s)
        matched_camera_models = all_camera_models(match_indices);
        % load the first camera model in the matched list
        cam2xyz = matrices.matrices_cam2xyz.(matched_camera_models{1});
        fprintf('Camera model ''%s'' is not found. The closest matched model ''%s'' is selected.\n',...
                camera_model, matched_camera_models{1});
    end
    if length(match_indices) >= 2
        % print other possibly matched camera model(s)
        disp('Or maybe you would like to select following model(s)?\n');
        disp(repmat('=', 1, 25));
        fprintf([repmat('%s\n',1, length(all_camera_models(match_indices))-1), '\n'], matched_camera_models{2:end});
        disp(repmat('=', 1, 25));
    end
end
end

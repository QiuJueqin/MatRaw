function info = getrawinfo(raw_dir)
% GETRAWINFO extracts image information such as exposure time, ISO speed,
% F-number and so on via MATLAB built-in imfinfo function.

info = imfinfo(raw_dir);
if numel(info) > 1
    info = info(1);
end
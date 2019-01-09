%% Demo 1
% Batch convert .arw files from Sony ILCE7 DSLM to .tiff files and save to
% the same directory
%
% DARKNESS and SATURATION can be calculated by calibrating the camera, or
% by running 'dcraw -v [raw_dir]' to view.
%
% CFA (color filter array) can be guessed by several trial-and-errors, if
% you are not sure.
%
% See README.md for more info.

clc;

raw_dir = '.\MatRaw\sample_raw_files\Sony_ILCE7\*.ARW';
read_attr = {'cfa', 'RGGB',...
             'darkness', 128,...
             'saturation', 4095,...
             'format', 'tiff',...
             'info', true}; % rename the converted files with capturing info
         
matrawread(raw_dir, read_attr{:});

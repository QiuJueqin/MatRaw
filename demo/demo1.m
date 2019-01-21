%% Demo 1
% Batch convert .arw files from Sony ILCE7 DSLM to .ppm files and save to
% the same directory.
%
% DARKNESS and SATURATION can be calculated by calibrating the camera, or
% by running 'dcraw -v [raw_dir]' to view. 
%
% NOTE: darkness and saturation levels reported by dcraw may be wrong for
% some camera models (e.g., Canon EOS 5D Mark IV)!!! Run your own
% calibration if the output image had a weird appearance, as done in
% demo2.m.
%
% CFA (color filter array) can be guessed by several trial-and-errors, if
% you are not sure.
%
% % Sample raw files in this demo can be downloaded from
% https://1drv.ms/u/s!AniPeh_FlASDhVwZp5Bgujheu0N4
%
% See README.md for more info.

clc;

raw_dir = '.\MatRaw\sample_raw_files\Sony_ILCE7\*.ARW';
read_attr = {'cfa', 'RGGB',...
             'darkness', 128,...
             'saturation', 4095,...
             'format', 'ppm',...
             'info', true}; % rename the converted files with capturing info
         
matrawread(raw_dir, read_attr{:});

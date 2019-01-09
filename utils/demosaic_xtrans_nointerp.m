function RGB = demosaic_xtrans_nointerp(raw)
% DEMOSAIC_XTRANS_NOINTERP converts X-Trans CFA images into full color RGB
% images without color interpolation 
%
% This script 'combines' 9 pixels from a unit cell in the CFA into one
% single 'large' pixel in the color image, thus the spatial resolution will
% be reduced to (H/3)*(W/3) after demosaicking.
%
% Copyright
% Qiu Jueqin - Jan, 2019

raw = double(raw);
[height, width] = size(raw);
variance = zeros(3,3);

% clip off first 2 rows in the CFA image, otherwise the red and blue
% channels may be confounded
nb_skip_pixel_x = 0;
nb_skip_pixel_y = 2; 
for h = 1:3
    for v = 1:3
        variance(v,h) = std2(raw([nb_skip_pixel_y + v+1, nb_skip_pixel_y + v+2],...
                                 [nb_skip_pixel_x + h, nb_skip_pixel_x + h + 2]));
    end
end
[r, c] = find(variance == min(variance(:)));

% ensure the fisrt 3x3 cell in the top-left corner is equal to (indices in
% parentheses)
% [R(1) G(2) R(3)]
% [G(4) B(5) G(6)]
% [G(7) R(8) G(9)]
% otherwise you can never distinguish red and blue filters from a X-Trans
% CFA
begin_x = c + nb_skip_pixel_x;
begin_y = r + nb_skip_pixel_y;

% ensure the last 3x3 cell in the bottom-right corner is equal to
% [R G R]
% [G B G]
% [G R G]
% (actually 6x6 cell is the minimum regular unit in the X-Trans CFA)
end_x = floor((width - nb_skip_pixel_x - begin_x + 1)/6)*6 + begin_x - 1;
end_y = floor((height - nb_skip_pixel_y - begin_y + 1)/6)*6 + begin_y - 1;
raw = raw(begin_y : end_y, begin_x : end_x);

G2 = raw(1:3:end, 2:3:end);
G4 = raw(2:3:end, 1:3:end);
G6 = raw(2:3:end, 3:3:end);
G7 = raw(3:3:end, 1:3:end);
G9 = raw(3:3:end, 3:3:end);
Green = (G2 + G6 + G4 + G7 + G9)/5;

RB1 = raw(1:3:end, 1:3:end);
RB3 = raw(1:3:end, 3:3:end);
RB8 = raw(3:3:end, 2:3:end);
RB138 = (RB1 + RB3 + RB8)/3;

RB5 = raw(2:3:end, 2:3:end);

Red = zeros(size(Green));
Red(1:2:end, 1:2:end) = RB138(1:2:end, 1:2:end);
Red(2:2:end, 2:2:end) = RB138(2:2:end, 2:2:end);
Red(1:2:end, 2:2:end) = RB5(1:2:end, 2:2:end);
Red(2:2:end, 1:2:end) = RB5(2:2:end, 1:2:end);

Blue = zeros(size(Green));
Blue(1:2:end, 1:2:end) = RB5(1:2:end, 1:2:end);
Blue(2:2:end, 2:2:end) = RB5(2:2:end, 2:2:end);
Blue(1:2:end, 2:2:end) = RB138(1:2:end, 2:2:end);
Blue(2:2:end, 1:2:end) = RB138(2:2:end, 1:2:end);

RGB = cat(3, Red, Green, Blue);

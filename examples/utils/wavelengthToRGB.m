function RGB = wavelengthToRGB(wavelength)
% WAVELENGTHTORGB  Approximate visible-wavelength to display RGB.
%
%   RGB = wavelengthToRGB(wavelength) returns an approximate sRGB-like
%   triple in [0, 1] for a single scalar wavelength in nm. The mapping
%   is piecewise-linear over the visible band (380-780 nm) and fades
%   to dark at the band edges. Intended only for *illustration* of
%   chromaticity plots and the like; it is not colorimetrically
%   accurate and should not be used for color reproduction.
%
%   INPUTS:
%       wavelength - Scalar wavelength in nanometers
%
%   OUTPUTS:
%       RGB - 1x3 row vector of sRGB-like values in [0, 1]
%
%   EXAMPLE:
%       c = wavelengthToRGB(550);   % yellowish-green
%
%   Copyright 2025-2026 Alexander Forsythe and Brian Funt. Simon Fraser University.

arguments
    wavelength (1,1) double
end

if wavelength < 440
    r = (440 - wavelength) / (440 - 380); g = 0; b = 1;
elseif wavelength < 490
    r = 0; g = (wavelength - 440) / (490 - 440); b = 1;
elseif wavelength < 510
    r = 0; g = 1; b = (510 - wavelength) / (510 - 490);
elseif wavelength < 580
    r = (wavelength - 510) / (580 - 510); g = 1; b = 0;
elseif wavelength < 645
    r = 1; g = (645 - wavelength) / (645 - 580); b = 0;
else
    r = 1; g = 0; b = 0;
end

if wavelength < 420
    factor = 0.3 + 0.7 * (wavelength - 380) / (420 - 380);
elseif wavelength > 700
    factor = 0.3 + 0.7 * (780 - wavelength) / (780 - 700);
else
    factor = 1;
end

RGB = max(0, min(1, [r, g, b] * factor));
end

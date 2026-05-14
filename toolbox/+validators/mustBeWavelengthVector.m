function mustBeWavelengthVector(wl)
% MUSTBEWAVELENGTHVECTOR  Validate that wl is a sensible wavelength vector.
%
%   Throws an error if any element is non-positive, non-finite, complex,
%   or NaN. Wavelengths are not required to be sorted - the toolbox
%   handles unsorted input - but every value must be a real, finite,
%   strictly-positive number.
%
%   INPUTS:
%       wl - Wavelength vector to validate (vector)
%
%   Use as a validator inside an arguments block:
%       arguments
%           wl (:,1) double {validators.mustBeWavelengthVector}
%       end
%
%   Centralizes the {mustBeReal, mustBeFinite, mustBePositive} chain
%   used at every wavelength input. A future tightening (e.g.,
%   requiring sorted input or imposing a minimum bound) needs to be
%   made in only one place.
%
%   See also: mustBeReal, mustBeFinite, mustBePositive
%
%   SPDX-License-Identifier: AGPL-3.0-or-later
%
%   Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
%   Simon Fraser University, Burnaby, British Columbia, Canada

mustBeReal(wl);
mustBeFinite(wl);
mustBePositive(wl);
end

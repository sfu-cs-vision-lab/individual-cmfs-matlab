function mustBeNonnegativeFiniteOrNaN(x)
% MUSTBENONNEGATIVEFINITEORNAN  Validate that x is non-negative finite or NaN.
%
%   Throws an error if any element is non-NaN and either negative or
%   non-finite. NaN is used elsewhere in the toolbox as a sentinel for
%   "value not provided" in constructor options for optical densities
%   (Lod, Mod, Sod, MacularDensity, LensDensity), where zero is a valid
%   value (gene-deletion dichromacy or aphakic lens) but Inf and
%   negative are non-physical.
%
%   Use as a validator inside an arguments block:
%       arguments
%           options.Lod (1,1) double {validators.mustBeNonnegativeFiniteOrNaN} = NaN
%       end
%
%   See also: mustBeNonnegative, validators.mustBePositiveOrNaN

%   SPDX-License-Identifier: AGPL-3.0-or-later
%
%   Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
%   Simon Fraser University, Burnaby, British Columbia, Canada

nonNaN = ~isnan(x);
if any(nonNaN & (x < 0))
    error("IndividualCMF:NotNonnegativeFiniteOrNan", ...
        "Value must be non-negative or NaN.");
end
if any(nonNaN & ~isfinite(x))
    error("IndividualCMF:NotNonnegativeFiniteOrNan", ...
        "Value must be finite (or NaN).");
end
end

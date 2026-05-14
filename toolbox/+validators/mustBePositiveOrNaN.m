function mustBePositiveOrNaN(x)
% MUSTBEPOSITIVEORNAN  Validate that x is positive finite or NaN.
%
%   Throws an error if any element is non-NaN and either non-positive or
%   non-finite. NaN is used elsewhere in the toolbox as a sentinel for
%   "value not provided" in constructor options (Age, FieldSize), so
%   this validator is more permissive than mustBePositive at the API
%   boundary, but still rejects Inf to keep the constructor's contract
%   matching the now-stricter property setters.
%
%   Use as a validator inside an arguments block:
%       arguments
%           options.Age (1,1) double {validators.mustBePositiveOrNaN} = NaN
%       end
%
%   See also: mustBePositive, validators.mustBeWavelengthVector

%   SPDX-License-Identifier: AGPL-3.0-or-later
%
%   Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
%   Simon Fraser University, Burnaby, British Columbia, Canada

nonNaN = ~isnan(x);
if any(nonNaN & (x <= 0))
    error("IndividualCMF:NotPositiveOrNan", "Value must be positive or NaN.");
end
if any(nonNaN & ~isfinite(x))
    error("IndividualCMF:NotPositiveOrNan", "Value must be finite (or NaN).");
end
end

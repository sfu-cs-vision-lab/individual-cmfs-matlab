function mustBeValidPrimaries(p)
% MUSTBEVALIDPRIMARIES  Validate RGB primary wavelengths.
%
%   Throws an error if the primaries are not three distinct, positive,
%   finite wavelengths. Distinctness is required because the RGB CMF
%   computation inverts a 3x3 LMS-at-primaries matrix; two identical
%   primary wavelengths make that matrix singular and produce NaN
%   output with only a MATLAB warning. Catching the bad input here
%   gives the user a clear domain error instead.
%
%   Use as a validator inside an arguments block:
%       arguments
%           options.Primaries (1,3) double {validators.mustBeValidPrimaries} = ...
%       end
%
%   See also: IndividualCMF.RGB

%   SPDX-License-Identifier: AGPL-3.0-or-later
%
%   Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
%   Simon Fraser University, Burnaby, British Columbia, Canada

if any(~isfinite(p))
    error("IndividualCMF:InvalidPrimaries", ...
        "Primaries must be finite wavelengths in nm.");
end
if any(p <= 0)
    error("IndividualCMF:InvalidPrimaries", ...
        "Primaries must be positive wavelengths in nm.");
end
if numel(unique(p)) < numel(p)
    error("IndividualCMF:InvalidPrimaries", ...
        "Primaries must be three distinct wavelengths; the RGB " + ...
        "transform is singular otherwise.");
end
end

function mustBe3x3OrEmpty(v)
% MUSTBE3X3OREMPTY  Validate that v is a 3x3 matrix or empty.
%
%   Throws an error if v is non-empty and is not exactly 3x3. Empty input
%   is accepted as a sentinel for "no transformation matrix supplied" at
%   the API boundary (e.g. Primaries-driven RGB derivation).
%
%   Use as a validator inside an arguments block:
%       arguments
%           options.TransformationMatrix double {validators.mustBe3x3OrEmpty} = []
%       end
%
%   See also: validators.mustBeWavelengthVector

%   SPDX-License-Identifier: AGPL-3.0-or-later
%
%   Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
%   Simon Fraser University, Burnaby, British Columbia, Canada

if isempty(v)
    return
end
if ~isequal(size(v), [3 3])
    error("IndividualCMF:InvalidMatrix", "Value must be a 3x3 matrix.");
end
end

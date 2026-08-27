classdef NormalizationMethod
% NORMALIZATIONMETHOD  How the peak used for output normalization is found.
%
%   Continuous - Locate the peak of the continuous spectral model, using a
%                closed form where the template provides one and fminbnd
%                otherwise. The normalized peak is 1 regardless of which
%                wavelengths the caller evaluates at. Default.
%   Sampled    - Take the maximum over the discrete grid in
%                IndividualCMF.NormalizationGrid. Matches the pycone
%                reference implementation, which normalizes to the maximum
%                of a sampled spectrum, so the parity harness uses it.
%
%   Members are valid MATLAB identifiers, so a string assignment such as
%   `obs.NormalizationMethod = "Sampled"` is auto-converted.
%
%   See also: IndividualCMF, NormalizationCache.

%   SPDX-License-Identifier: AGPL-3.0-or-later
%
%   Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
%   Simon Fraser University, Burnaby, British Columbia, Canada

    enumeration
        Continuous
        Sampled
    end
end

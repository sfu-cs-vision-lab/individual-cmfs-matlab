classdef LensDensityAlgorithm
% LENSDENSITYALGORITHM  Lens density derivation strategy.
%
%   Auto   - LensDensity is recomputed from the active LensModel and Age
%            whenever those change. Default.
%   Custom - LensDensity is held fixed at the most recently assigned
%            value. Auto-engaged when the user assigns LensDensity
%            directly.
%
%   Members are valid MATLAB identifiers, so a string assignment such as
%   `obs.LensDensityAlgorithm = "Custom"` is auto-converted.
%
%   Note on dispatch style: this enum is dispatched via switch in
%   IndividualCMF (set.LensDensityAlgorithm and recalcLensFromAge),
%   not via a strategy-class hierarchy like LensTemplate. Each branch is
%   small and stateless -- "Auto" delegates to LensTemplate.computeDensityAt400(age)
%   and "Custom" is a no-op preserving user values -- so strategy classes
%   would add ceremony without unlocking polymorphism. Templates carry
%   per-instance parameter state and multiple methods, which is why they
%   earn the heavier pattern. If a future algorithm needs configuration,
%   or if user-defined algorithms become a requirement, revisit this.
%
%   See also: IndividualCMF, LensTemplate.

%   SPDX-License-Identifier: AGPL-3.0-or-later
%
%   Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
%   Simon Fraser University, Burnaby, British Columbia, Canada

    enumeration
        Auto
        Custom
    end
end

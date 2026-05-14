classdef PhotopigmentDensityAlgorithm
% PHOTOPIGMENTDENSITYALGORITHM  Photopigment density derivation strategy.
%
%   CIE170       - Use the CIE 170-1:2006 tabulated values at the
%                  standard 2 deg and 10 deg field sizes; fall back to
%                  the Pokorny-Smith formula for any other field size.
%                  Default at standard field sizes.
%   PokornySmith - Continuous formula valid for any field size (Pokorny
%                  & Smith 1976).
%   Custom       - Hold Lod / Mod / Sod fixed; auto-engaged when any of
%                  Lod, Mod, or Sod is assigned directly.
%
%   Members are valid MATLAB identifiers, so a string assignment such as
%   `obs.PhotopigmentDensityAlgorithm = "PokornySmith"` is auto-converted.
%
%   Note on dispatch style: this enum is dispatched via switch in
%   IndividualCMF.updatePhotopigmentDensities (and in
%   updatePhotopigmentAlgorithmFromValues), not via a strategy-class
%   hierarchy like PhotopigmentTemplate. Each branch is small and
%   stateless -- the actual math lives in
%   PhotopigmentParameters.densitiesCIEStandard and
%   PhotopigmentParameters.densitiesAtFieldSize as named static methods.
%   Strategy classes would add ceremony without unlocking polymorphism
%   we cannot already get from those named primitives. Templates carry
%   per-instance parameter state and multiple methods, which is why
%   they earn the heavier pattern. If a future algorithm needs
%   configuration, or if user-defined algorithms become a requirement,
%   revisit this.
%
%   See also: IndividualCMF, PhotopigmentParameters.densitiesCIEStandard.

%   SPDX-License-Identifier: AGPL-3.0-or-later
%
%   Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
%   Simon Fraser University, Burnaby, British Columbia, Canada

    enumeration
        CIE170
        PokornySmith
        Custom
    end
end

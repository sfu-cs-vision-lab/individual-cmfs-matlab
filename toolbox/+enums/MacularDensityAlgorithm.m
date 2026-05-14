classdef MacularDensityAlgorithm
% MACULARDENSITYALGORITHM  Macular density derivation strategy.
%
%   CIE170            - Use the CIE 170-1:2006 tabulated values at the
%                       standard 2 deg and 10 deg field sizes; fall back
%                       to the Moreland-Alexander formula for any other
%                       field size. Default at standard field sizes.
%   MorelandAlexander - Continuous formula valid for any field size:
%                       D_mac = 0.485 * exp(-fieldSize/6.132)
%                       (Moreland & Alexander 1997; CIEPO06).
%   Custom            - Hold MacularDensity fixed; auto-engaged when
%                       MacularDensity is assigned directly.
%
%   Members are valid MATLAB identifiers, so a string assignment such as
%   `obs.MacularDensityAlgorithm = "MorelandAlexander"` is auto-converted.
%
%   Note on dispatch style: this enum is dispatched via switch in
%   IndividualCMF.updateMacularDensity (and in the standard-detection
%   logic of set.MacularDensity), not via a strategy-class hierarchy
%   like MacularTemplate. Each branch is small and stateless -- the
%   actual math lives in PreReceptoralFilter.macularDensityCIEStandard
%   and PreReceptoralFilter.macularDensityAtFieldSize as named static
%   methods. Strategy classes would add ceremony without unlocking
%   polymorphism we cannot already get from those named primitives.
%   Templates carry per-instance parameter state and multiple methods,
%   which is why they earn the heavier pattern. If a future algorithm
%   needs configuration, or if user-defined algorithms become a
%   requirement, revisit this.
%
%   See also: IndividualCMF, PreReceptoralFilter.macularDensityCIEStandard.

%   SPDX-License-Identifier: AGPL-3.0-or-later
%
%   Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
%   Simon Fraser University, Burnaby, British Columbia, Canada

    enumeration
        CIE170
        MorelandAlexander
        Custom
    end
end

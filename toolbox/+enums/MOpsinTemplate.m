classdef MOpsinTemplate
% MOPSINTEMPLATE  M-cone opsin template / polymorphism selector.
%
%   Mean     - Same as Standard; preserved for symmetry with
%              L_OpsinTemplate. Default.
%   Standard - The single canonical M-cone curve (no Serine/Alanine
%              dimorphism for M-cones).
%   LinM     - "L-in-M" hybrid opsin (uses L-cone shape for M-cone
%              position). Used to model M-cone variants in
%              dichromat / anomalous-trichromat genotypes.
%
%   Members are valid MATLAB identifiers, so a string assignment such as
%   `obs.M_OpsinTemplate = "Standard"` is auto-converted.
%
%   NOTE: This was previously the string "L-in-M" (with hyphens); it is
%   now the identifier LinM. Update assignments and comparisons
%   accordingly.
%
%   See also: IndividualCMF, Genotype.

%   SPDX-License-Identifier: AGPL-3.0-or-later
%
%   Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
%   Simon Fraser University, Burnaby, British Columbia, Canada

    enumeration
        Mean
        Standard
        LinM
    end
end

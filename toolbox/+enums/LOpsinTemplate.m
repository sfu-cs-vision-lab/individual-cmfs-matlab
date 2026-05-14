classdef LOpsinTemplate
% LOPSINTEMPLATE  L-cone opsin template / polymorphism selector.
%
%   Mean    - Population-weighted average of Serine (56%) and Alanine
%             (44%) variants at codon 180. Default.
%   Serine  - Pure Ser-180 variant (long-shifted L-cone polymorphism).
%   Alanine - Pure Ala-180 variant (Serine - 2.7 nm).
%   MinL    - "M-in-L" hybrid opsin (uses M-cone shape for L-cone
%             position). Used to model L-cone variants in
%             dichromat / anomalous-trichromat genotypes.
%
%   Members are valid MATLAB identifiers, so a string assignment such as
%   `obs.L_OpsinTemplate = "Serine"` is auto-converted.
%
%   NOTE: This was previously the string "M-in-L" (with hyphens); it is
%   now the identifier MinL. Update assignments and comparisons
%   accordingly.
%
%   See also: IndividualCMF, Genotype.

%   SPDX-License-Identifier: AGPL-3.0-or-later
%
%   Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
%   Simon Fraser University, Burnaby, British Columbia, Canada

    enumeration
        Mean
        Serine
        Alanine
        MinL
    end
end

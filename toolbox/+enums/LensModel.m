classdef LensModel
% LENSMODEL  Lens absorption template model selector.
%
%   StockmanRider2023 - Age-invariant 9-term Fourier polynomial template
%                       (Stockman & Rider 2023, Table 2). Density at
%                       400 nm is fixed at 1.7649 unless set externally.
%                       Default.
%   Pokorny1987       - Age-dependent two-component template (Pokorny,
%                       Smith & Lutze 1987, Table I) with bilinear density
%                       growth above age 60.
%   VanDeKraats2007   - Age-dependent five-component total-ocular-media
%                       template (van de Kraats & van Norren 2007, Eq. 8)
%                       with quadratic-in-age density coefficients. Uses
%                       the small-field (<=3 deg) Rayleigh coefficient.
%
%   Members are valid MATLAB identifiers, so a string assignment such as
%   `obs.LensModel = "Pokorny1987"` is auto-converted.
%
%   See also: IndividualCMF, StockmanRiderLensTemplate, Pokorny1987LensTemplate,
%             VanDeKraatsVanNorren2007LensTemplate.

%   SPDX-License-Identifier: AGPL-3.0-or-later
%
%   Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
%   Simon Fraser University, Burnaby, British Columbia, Canada

    enumeration
        StockmanRider2023
        Pokorny1987
        VanDeKraats2007
    end
end

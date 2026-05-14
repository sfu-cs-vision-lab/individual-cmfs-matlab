classdef MacularModel
% MACULARMODEL  Macular pigment template model selector.
%
%   StockmanRider2023 - 11-term Fourier polynomial template (Stockman &
%                       Rider 2023, Table 2; CIE 170-1:2006 macular
%                       shape). Default. Currently the only published
%                       option; the enum exists so the macular template
%                       hierarchy mirrors LensTemplate / PhotopigmentModel
%                       and additional shapes can be plugged in without
%                       changing the IndividualCMF surface.
%
%   Members are valid MATLAB identifiers, so a string assignment such as
%   `obs.MacularModel = "StockmanRider2023"` is auto-converted.
%
%   See also: IndividualCMF, MacularTemplate, StockmanRider2023MacularTemplate.

%   SPDX-License-Identifier: AGPL-3.0-or-later
%
%   Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
%   Simon Fraser University, Burnaby, British Columbia, Canada

    enumeration
        StockmanRider2023
    end
end

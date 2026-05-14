classdef PhotopigmentModel
% PHOTOPIGMENTMODEL  Photopigment template model selector.
%
%   StockmanRider2023  - 8th-order Fourier polynomial templates from
%                        Stockman & Rider (2023), Table 1. Default; basis
%                        of CIE 170-1:2006 standard observers.
%   Govardovskii2000   - Continuous A1 visual pigment nomogram from
%                        Govardovskii et al. (2000). The standard human
%                        chromophore (11-cis retinal).
%   Govardovskii2000A2 - Continuous A2 (3,4-dehydroretinal) nomogram from
%                        Govardovskii et al. (2000), Eqs. 6 and 8. The
%                        A2 chromophore is found in freshwater fish,
%                        larval amphibians, and some reptiles; with the
%                        same opsin it produces a red-shifted lambda-max
%                        relative to A1. Intended for comparative-vision
%                        research.
%
%   Members are valid MATLAB identifiers, so a string assignment such as
%   `obs.PhotopigmentModel = "StockmanRider2023"` is auto-converted.
%
%   See also: IndividualCMF, StockmanRiderPhotopigmentTemplate, GovardovskiiPhotopigmentTemplate.

%   SPDX-License-Identifier: AGPL-3.0-or-later
%
%   Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
%   Simon Fraser University, Burnaby, British Columbia, Canada

    enumeration
        StockmanRider2023
        Govardovskii2000
        Govardovskii2000A2
    end
end

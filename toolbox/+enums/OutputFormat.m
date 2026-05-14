classdef OutputFormat
% OUTPUTFORMAT  Pipeline stage at which cone sensitivities are reported.
%
%   energy      - Corneal energy spectral sensitivity (the standard
%                 cone fundamental output; default).
%   quantal     - Corneal quantal spectral sensitivity.
%   absorptance - Relative retinal absorptance after self-screening:
%                 (1 - 10^(-OD*A)) / (1 - 10^(-OD)). Peaks near 1 by
%                 construction for both Stockman-Rider and Govardovskii
%                 templates. The raw Beer-Lambert fraction
%                 1 - 10^(-OD*A) is available via
%                 pipeline.PhotopigmentStage.absorptanceFromAbsorbance
%                 with Normalize=false.
%   absorbance  - Linear photopigment absorbance from the template
%                 model (output of stage 1 of the pipeline). Set
%                 LogOutput=true for log10 values.
%
%   Members are valid MATLAB identifiers, so a string assignment such as
%   `obs.OutputFormat = "energy"` is auto-converted by MATLAB.
%
%   See also: IndividualCMF.

%   SPDX-License-Identifier: AGPL-3.0-or-later
%
%   Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
%   Simon Fraser University, Burnaby, British Columbia, Canada

    enumeration
        energy
        quantal
        absorptance
        absorbance
    end
end

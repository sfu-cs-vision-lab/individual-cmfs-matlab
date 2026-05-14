classdef PhotopigmentStage
    % PHOTOPIGMENTSTAGE  Pure-function pipeline stage for photopigment computation.
    %
    %   Stage 1 of the LMS compute pipeline. Computes log10 absorbance
    %   from a PhotopigmentTemplate, then converts to retinal absorptance
    %   via optical-density self-screening.
    %
    %   This class has no state -- all methods are static. Inputs flow in,
    %   spectra flow out. The class exists for organization and testing
    %   so the photopigment math can be verified independently of any
    %   IndividualCMF instance.
    %
    %   PhotopigmentStage Methods (Static):
    %       logAbsorbance              - Stage 1a: template + lambda-max shift -> log10 absorbance.
    %       retinalAbsorptance         - Stage 1b: log absorbance + OD -> absorptance.
    %       absorptanceFromAbsorbance  - Bare math primitive: linear absorbance + OD -> absorptance.
    %
    %   See also: pipeline.PreReceptoralStage, pipeline.OutputStage,
    %             PhotopigmentTemplate, IndividualCMF.

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada
    %
    % This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    % Licensed under AGPL-3.0-or-later. See LICENSE file for details.
    % Repository: https://github.com/sfu-cs-vision-lab/Individual-CMFs

    methods (Static)
        function logAbs = logAbsorbance(template, wavelengths, coneType, lambdaMaxShift, templateOptions)
            % LOGABSORBANCE  Compute log10 photopigment absorbance.
            %
            %   logAbs = pipeline.PhotopigmentStage.logAbsorbance(template,
            %       wavelengths, coneType, lambdaMaxShift, templateOptions)
            %   delegates to the template strategy. The template owns the
            %   actual computation; this stage exists to make the pipeline
            %   structure explicit and testable.
            %
            %   INPUTS:
            %       template - PhotopigmentTemplate strategy instance
            %       wavelengths - Wavelengths in nm (column vector)
            %       coneType - 'L', 'M', or 'S' (char)
            %       lambdaMaxShift - lambda-max shift in nm (scalar)
            %       templateOptions - Template-specific options (struct)
            %
            %   OUTPUTS:
            %       logAbs - Log10 absorbance spectrum (column vector)
            arguments
                template (1,1) PhotopigmentTemplate
                wavelengths (:,1) double
                coneType (1,1) char {mustBeMember(coneType, {'L', 'M', 'S'})}
                lambdaMaxShift (1,1) double
                templateOptions (1,1) struct
            end

            logAbs = template.computeAbsorbance(wavelengths, coneType, lambdaMaxShift, templateOptions);
        end

        function absorptance = retinalAbsorptance(logAbs, opticalDensity, doHelperNorm)
            % RETINALABSORPTANCE  Convert log absorbance to retinal absorptance.
            %
            %   absorptance = pipeline.PhotopigmentStage.retinalAbsorptance(
            %       logAbs, opticalDensity, doHelperNorm) applies the
            %   optical-density self-screening transformation.
            %
            %   INPUTS:
            %       logAbs - Log10 absorbance from logAbsorbance() (column vector)
            %       opticalDensity - Cone optical density (scalar)
            %       doHelperNorm - Selects the output convention:
            %                      true: relative retinal absorptance
            %                            (1-10^(-OD*A)) / (1-10^(-OD)), used
            %                            by the high-level OutputFormat path.
            %                      false: raw Beer-Lambert fraction
            %                            1 - 10^(-OD*A).
            %
            %   OUTPUTS:
            %       absorptance - Retinal absorptance (column vector)
            arguments
                logAbs (:,1) double
                opticalDensity (1,1) double
                doHelperNorm (1,1) logical
            end

            linAbs = 10.^(logAbs);
            absorptance = pipeline.PhotopigmentStage.absorptanceFromAbsorbance(linAbs, opticalDensity, ...
                Normalize=doHelperNorm);
        end

        function out = absorptanceFromAbsorbance(linAbs, od, options)
            % ABSORPTANCEFROMABSORBANCE  Convert linear absorbance to absorptance.
            %
            %   out = pipeline.PhotopigmentStage.absorptanceFromAbsorbance(
            %       linAbs, od) applies the Beer-Lambert absorbance-to-
            %   absorptance conversion:
            %
            %       absorptance = (1 - 10^(-od * linAbs)) / (1 - 10^(-od))
            %                     [Normalize=true, default]
            %       absorptance =  1 - 10^(-od * linAbs)
            %                     [Normalize=false]
            %
            %   This is a bare math primitive exposed for callers that
            %   already have the linear absorbance values in hand. The
            %   higher-level retinalAbsorptance() takes log absorbance
            %   and exponentiates internally; prefer that for the normal
            %   pipeline path.
            %
            %   Absorbance and absorptance are different physical
            %   quantities: absorbance is log10(I_in/I_out) and can
            %   exceed 1; absorptance is the fraction of light absorbed,
            %   bounded 0..1. The function name describes the conversion
            %   direction (absorbance in, absorptance out).
            %
            %   INPUTS:
            %       linAbs - Linear absorbance (column vector)
            %       od - Optical density (scalar)
            %
            %   OPTIONAL INPUTS (Name-Value arguments):
            %       Normalize - true (default): relative retinal absorptance
            %                   (1 - 10^(-od*linAbs)) / (1 - 10^(-od)). This
            %                   is the convention IndividualCMF's high-level
            %                   OutputFormat="absorptance" returns for both
            %                   Stockman-Rider and Govardovskii templates.
            %                   false: raw Beer-Lambert fraction
            %                   1 - 10^(-od*linAbs). Use when you want the
            %                   physical absorptance (fraction of photons
            %                   absorbed at a given wavelength), independent
            %                   of any normalisation convention.
            %
            %   OUTPUTS:
            %       out - Absorptance (column vector)
            arguments
                linAbs (:,1) double
                od (1,1) double
                options.Normalize (1,1) logical = true
            end

            % An optical density of zero represents an absent cone (gene
            % deletion dichromacy). Physical absorptance is identically
            % zero, but the Normalize branch's denominator (1 - 10^-od)
            % also collapses to zero, producing NaN. Short-circuit to
            % honour the convention that an absent cone yields a zero column.
            if od == 0
                out = zeros(size(linAbs));
                return;
            end

            num = 1 - 10.^(-od .* linAbs);

            if options.Normalize
                den = 1 - 10^(-od);
                out = num ./ den;
            else
                out = num;
            end
        end
    end
end

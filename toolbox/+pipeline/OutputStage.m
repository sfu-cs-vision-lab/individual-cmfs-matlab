classdef OutputStage
    % OUTPUTSTAGE  Pure-function pipeline stage for output formatting.
    %
    %   Stage 3 of the LMS compute pipeline. Converts quantal sensitivity
    %   to the requested output format (energy, quantal, absorptance, or
    %   raw absorbance), applies normalization, and applies log10 transform.
    %
    %   This stage handles only the pure transformations. The peak-finding
    %   for normalization is done by NormalizationCache, which lives on
    %   IndividualCMF; this stage just divides by the precomputed peak.
    %
    %   OutputStage Methods (Static):
    %       quantalToEnergy - Multiply by wavelength to convert units.
    %       normalize       - Divide by peak.
    %       applyLog        - log10 with NaN/Inf -> -10.
    %       cleanNaN        - Replace NaN (and optionally clamp < 0) for
    %                         already-formatted output.
    %
    %   See also: pipeline.PhotopigmentStage, pipeline.PreReceptoralStage,
    %             NormalizationCache, IndividualCMF.

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada
    %
    % This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    % Licensed under AGPL-3.0-or-later. See LICENSE file for details.
    % Repository: https://github.com/sfu-cs-vision-lab/Individual-CMFs

    methods (Static)
        function energy = quantalToEnergy(quantal, wavelengths)
            % QUANTALTOENERGY  Convert quantal to energy-based sensitivity.
            %
            %   energy = pipeline.OutputStage.quantalToEnergy(quantal,
            %       wavelengths) multiplies quantal sensitivity by
            %       wavelength to convert from photon-count to energy
            %       units (Watts).
            arguments
                quantal (:,1) double
                wavelengths (:,1) double
            end
            energy = quantal .* wavelengths;
        end

        function out = normalize(sensitivity, peak)
            % NORMALIZE  Divide sensitivity by a precomputed peak.
            %
            %   out = pipeline.OutputStage.normalize(sensitivity, peak)
            %       returns sensitivity ./ peak. Trivial wrapper that
            %       exists for pipeline-shape symmetry and so callers
            %       can be read top-to-bottom as a sequence of stage
            %       operations rather than a mix of stage calls and
            %       inline math.
            arguments
                sensitivity (:,1) double
                peak (1,1) double
            end
            out = sensitivity ./ peak;
        end

        function out = applyLog(sensitivity)
            % APPLYLOG  log10 with NaN/Inf replaced by -10.
            %
            %   out = pipeline.OutputStage.applyLog(sensitivity) returns
            %       log10(sensitivity) with any NaN or +/-Inf replaced
            %       by -10. The -10 floor is the toolbox-wide convention
            %       for "below dynamic range" in log output.
            arguments
                sensitivity (:,1) double
            end
            out = log10(sensitivity);
            out(isnan(out) | isinf(out)) = -10;
        end

        function out = cleanNaN(sensitivity, isLog)
            % CLEANNAN  Replace NaN in already-formatted sensitivity output.
            %
            %   out = pipeline.OutputStage.cleanNaN(sensitivity, isLog)
            %       replaces NaN values with the appropriate floor and,
            %       in linear mode, also clamps negative values to zero.
            %
            %   isLog == true  : NaN -> -10 (log floor). Inf is left alone
            %                    -- callers in this mode pass log-domain
            %                    inputs that have not been re-logged
            %                    (e.g. raw absorbance log values from a
            %                    template), so Inf is not synthesized
            %                    inside this function.
            %   isLog == false : NaN -> 0, and any negative value -> 0.
            %                    The negative clamp is a no-op for
            %                    physically meaningful linear sensitivity
            %                    (always >= 0) but is applied
            %                    defensively.
            arguments
                sensitivity (:,1) double
                isLog (1,1) logical
            end
            if isLog
                sensitivity(isnan(sensitivity)) = -10;
            else
                sensitivity(isnan(sensitivity)) = 0;
                sensitivity(sensitivity < 0) = 0;
            end
            out = sensitivity;
        end
    end
end

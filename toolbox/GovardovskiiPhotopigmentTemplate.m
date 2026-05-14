classdef GovardovskiiPhotopigmentTemplate < PhotopigmentTemplate
    % GOVARDOVSKIITEMPLATE  Govardovskii et al. (2000) visual pigment template.
    %
    %   This class implements the continuous visual pigment template from
    %   Govardovskii et al. (2000), which provides a parametric formula for
    %   generating absorbance spectra based on lambda-max. The template
    %   supports both chromophores defined in the paper:
    %     - A1 (11-cis retinal): the standard human/mammalian chromophore.
    %     - A2 (11-cis 3,4-dehydroretinal): found in freshwater fish, larval
    %       amphibians, and some reptiles. With the same opsin it produces
    %       a systematic red-shift in lambda-max relative to A1.
    %
    %   Select the chromophore at construction with the Pigment Name-Value
    %   argument; the default is "A1" so existing code is unchanged.
    %
    %   The template returns LINEAR absorbance (normalized to 1.0 at peak).
    %
    %   Reference:
    %       Govardovskii, V. I., et al. (2000). In search of the visual pigment
    %       template. Visual Neuroscience, 17(4), 509-528.

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada
    %
    % This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    % Licensed under AGPL-3.0-or-later. See LICENSE file for details.
    % Repository: https://github.com/sfu-cs-vision-lab/Individual-CMFs
    %
    % To cite this toolbox and its underlying scientific basis, see CITATION.cff
    % in the repository root.

    properties (SetAccess = protected)
        Name = "Govardovskii et al. (2000) A1 Visual Pigment Template"
        ShortName = "Govardovskii2000"
        % Pigment  Chromophore type: "A1" (default) or "A2".
        Pigment (1,1) string = "A1"
    end

    properties (Constant)
        % Base lambda-max values for human L, M, S cones used with the
        % Govardovskii et al. (2000) A1 visual pigment template. These
        % are the Stockman & Sharpe (2000) physiological lambda-max
        % values (the toolbox's default cross-species-template anchor
        % for human cones); they are not published in Govardovskii 2000.
        % Stockman & Sharpe (2000), JOSA A 17(9), 2722-2750, Table 1.
        BASE_LAMBDA_MAX_L = 558.9
        BASE_LAMBDA_MAX_M = 530.3
        BASE_LAMBDA_MAX_S = 420.7

        % SupportsShift  True; the Govardovskii template is parametric on
        % lambda-max, so shifting the curve is intrinsic.
        SupportsShift = true

        % SupportsAnalyticalPeak  True; the Govardovskii alpha-band template
        % places its peak at lambda-max by construction, and the peak value
        % is given directly by evaluating the parametric formula at
        % lambda-max -- no numerical search needed.
        SupportsAnalyticalPeak = true

        % ValidRange  Govardovskii A1 was fitted on the 380-780 nm visible
        % range. The parametric formula extends outside this range but
        % accuracy degrades for extreme wavelengths.
        ValidRange = [380, 780]
    end

    methods
        function obj = GovardovskiiPhotopigmentTemplate(options)
            % GOVARDOVSKIIPHOTOPIGMENTTEMPLATE  Construct a new Govardovskii template.
            %
            %   t = GovardovskiiPhotopigmentTemplate() builds the default
            %   A1 template, suitable for human and mammalian cone vision.
            %
            %   t = GovardovskiiPhotopigmentTemplate(Pigment="A2") builds
            %   the A2 (3,4-dehydroretinal) template for comparative
            %   vision research (fish, larval amphibians, reptiles).
            %
            %   OPTIONAL INPUTS (Name-Value arguments):
            %       Pigment - "A1" or "A2" (string) Default: "A1"
            %
            %   EXAMPLE:
            %       t = GovardovskiiPhotopigmentTemplate(Pigment="A2");
            arguments
                options.Pigment (1,1) string ...
                    {mustBeMember(options.Pigment, ["A1", "A2"])} = "A1"
            end
            obj.Pigment = options.Pigment;
            if obj.Pigment == "A2"
                obj.Name = "Govardovskii et al. (2000) A2 Visual Pigment Template";
                obj.ShortName = "Govardovskii2000A2";
            end
        end

        function logAbs = computeAbsorbance(obj, wl, coneType, shift, options)
            % COMPUTEABSORBANCE  Compute log10 absorbance using Govardovskii formula.
            %
            %   The Govardovskii model computes linear absorbance directly from
            %   the lambda-max parameter, then converts to log10. The active
            %   chromophore (A1 or A2) is selected at construction.
            %
            %   INPUTS:
            %       wl - Wavelengths in nm (vector)
            %       coneType - Cone type: 'L', 'M', or 'S' (char)
            %       shift - Wavelength shift in nm (double)
            %       options - Unused for Govardovskii model (struct)
            %
            %   OUTPUTS:
            %       logAbs - Log10 absorbance spectrum (vector)
            arguments
                obj
                wl (:,1) double {validators.mustBeWavelengthVector}
                coneType (1,1) char {mustBeMember(coneType, {'L', 'M', 'S'})}
                shift (1,1) double
                options (1,1) struct = struct() %#ok<INUSA>
            end

            lmax = obj.getLambdaMax(coneType, shift);
            if obj.Pigment == "A2"
                linAbs = Nomograms.govardovskii2000A2(wl, lmax);
            else
                linAbs = Nomograms.govardovskii2000(wl, lmax);
            end
            logAbs = log10(linAbs);
        end

        function peakAbs = computePeakAbsorbance(obj, coneType, shift, options)
            % COMPUTEPEAKABSORBANCE  Compute analytical peak absorbance.
            %
            %   For Govardovskii, the peak absorbance is calculated at lambda-max
            %   using the analytical formula. This allows precise normalization
            %   without sampling errors.
            %
            %   INPUTS:
            %       coneType - Cone type: 'L', 'M', or 'S' (char)
            %       shift - Wavelength shift in nm (double)
            %       options - Unused for Govardovskii model (struct)
            %
            %   OUTPUTS:
            %       peakAbs - Peak absorbance value (linear scale) (double)
            arguments
                obj
                coneType (1,1) char {mustBeMember(coneType, {'L', 'M', 'S'})}
                shift (1,1) double
                options (1,1) struct = struct() %#ok<INUSA>
            end

            lmax = obj.getLambdaMax(coneType, shift);
            if obj.Pigment == "A2"
                peakAbs = Nomograms.govardovskii2000A2(lmax, lmax);
            else
                peakAbs = Nomograms.govardovskii2000(lmax, lmax);
            end
        end

    end
end

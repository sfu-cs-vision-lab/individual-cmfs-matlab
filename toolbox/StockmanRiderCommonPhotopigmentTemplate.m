classdef StockmanRiderCommonPhotopigmentTemplate < PhotopigmentTemplate
    % STOCKMANRIDERCOMMONTEMPLATE  Stockman & Rider (2023) common pigment template.
    %
    %   This class implements the shape-invariant (common) photopigment
    %   template from Stockman & Rider (2023), Table 4 column 3. A single
    %   8th-order Fourier shape is translated along the log-wavelength axis
    %   to fit all three CIE cone absorbances. Each cone is positioned by a
    %   fixed per-cone offset plus a shift term derived from its common
    %   lambda-max.
    %
    %   Unlike the per-cone Stockman & Rider (2023) templates (which use a
    %   distinct Fourier polynomial for each cone and underpin the CIE 2006
    %   standard observer), the common template is a pure cross-species
    %   lambda-max model. It is NOT on the CIE parity path and should be used
    %   for comparative-vision work or arbitrary lambda-max generation, much
    %   like the Govardovskii et al. (2000) template.
    %
    %   The template returns LOG10 absorbance, normalized so the linear
    %   absorbance peaks at approximately 1.0 at lambda-max.
    %
    %   Reference:
    %       Stockman, A., & Rider, A. T. (2023). Formulae for generating
    %       standard and individual human cone spectral sensitivities. Color
    %       Research and Application, 48(6), 818-840.

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
        Name = "Stockman & Rider (2023) Common Photopigment Template"
        ShortName = "StockmanRider2023Common"
    end

    properties (Constant)
        % Base lambda-max values for the common (shape-invariant) template.
        % These are the per-cone common lambda-max values from Stockman &
        % Rider (2023) Table 4 col 3 (L = L(ser) anchor). A zero shift
        % places each cone's peak at these wavelengths.
        % Source: Stockman & Rider (2023), Table 4 col 3; pycone
        % CMFtemplates.py (Lsercommonlmax / Mcommonlmax / Scommonlmax).
        BASE_LAMBDA_MAX_L = 557.5
        BASE_LAMBDA_MAX_M = 527.3
        BASE_LAMBDA_MAX_S = 418.5

        % SupportsShift  True; the common template is defined in
        % log-wavelength space and accepts lambda-max shifts.
        SupportsShift = true

        % SupportsAnalyticalPeak  False; the common template is an 8th-order
        % Fourier polynomial pre-normalized so the peak is approximately 1.0
        % in linear units. The exact peak location has no closed form --
        % consumers must locate it numerically (e.g. fminbnd over the active
        % wavelength grid).
        SupportsAnalyticalPeak = false

        % ValidRange  Matches the Stockman & Rider valid range (360-830 nm),
        % the same SR_VALID_RANGE used by the per-cone templates.
        ValidRange = [360, 830]
    end

    methods
        function obj = StockmanRiderCommonPhotopigmentTemplate()
            % STOCKMANRIDERCOMMONPHOTOPIGMENTTEMPLATE  Construct a new common template.
        end

        function logAbs = computeAbsorbance(obj, wl, coneType, shift, options)
            % COMPUTEABSORBANCE  Compute log10 absorbance using the common template.
            %
            %   The common template positions a single shared Fourier shape
            %   per cone via Nomograms.stockmanRiderCommon. Opsin-template
            %   options (L_Template / M_Template) do not apply to the common
            %   template and are ignored with a warning, mirroring the
            %   Govardovskii model.
            %
            %   INPUTS:
            %       wl - Wavelengths in nm (vector)
            %       coneType - Cone type: 'L', 'M', or 'S' (char)
            %       shift - Wavelength shift in nm (double)
            %       options - Unused for the common template (struct)
            %
            %   OUTPUTS:
            %       logAbs - Log10 absorbance spectrum (vector)
            arguments
                obj %#ok<INUSA>
                wl (:,1) double {validators.mustBeWavelengthVector}
                coneType (1,1) char {mustBeMember(coneType, {'L', 'M', 'S'})}
                shift (1,1) double
                options (1,1) struct = struct()
            end

            % The common template ignores per-cone opsin templates. Warn if
            % such options are supplied, like the Govardovskii model.
            if isfield(options, 'L_Template') || isfield(options, 'M_Template')
                warning('StockmanRiderCommonPhotopigmentTemplate:IgnoredOption', ...
                    ['Opsin-template options are ignored by the common ' ...
                    '(shape-invariant) Stockman-Rider template.']);
            end

            logAbs = Nomograms.stockmanRiderCommon(wl, coneType, shift);
        end

        function peakAbs = computePeakAbsorbance(obj, coneType, shift, options)
            % COMPUTEPEAKABSORBANCE  Return peak absorbance value.
            %
            %   The common template's trailing 's' coefficient normalizes the
            %   linear absorbance so it peaks at approximately 1.0 at
            %   lambda-max, as with the per-cone Stockman-Rider templates.
            %
            %   INPUTS:
            %       coneType - Cone type: 'L', 'M', or 'S' (unused) (char)
            %       shift - Wavelength shift in nm (unused) (double)
            %       options - Unused for the common template (struct)
            %
            %   OUTPUTS:
            %       peakAbs - Peak absorbance value (always 1.0) (double)
            arguments
                obj %#ok<INUSA>
                coneType (1,1) char {mustBeMember(coneType, {'L', 'M', 'S'})} %#ok<INUSA>
                shift (1,1) double %#ok<INUSA>
                options (1,1) struct = struct() %#ok<INUSA>
            end

            peakAbs = 1.0;
        end

    end
end

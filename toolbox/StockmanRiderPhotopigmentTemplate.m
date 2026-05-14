classdef StockmanRiderPhotopigmentTemplate < PhotopigmentTemplate
    % STOCKMANRIDERTEMPLATE  Stockman & Rider (2023) cone fundamental templates.
    %
    %   This class implements the shifted Fourier series templates from
    %   Stockman & Rider (2023), which provide spectral absorbance curves
    %   for L, M, and S cones with support for wavelength shifts.
    %
    %   The template returns LOG10 absorbance.
    %
    %   L-cone variants (options.L_Template):
    %       "Mean"    - Weighted mean of Serine (56%) and Alanine (44%) variants.
    %                   Represents the population average. Shifts are NOT supported;
    %                   if a non-zero shift is applied, automatically switches to
    %                   Serine template with a warning.
    %       "Serine"  - Serine variant at position 180. Supports wavelength shifts.
    %       "Alanine" - Alanine variant at position 180 (Serine - 2.7nm).
    %                   If a non-zero shift is applied, the shift is combined with
    %                   the -2.7nm Alanine offset and applied to Serine template.
    %       "MinL"  - Hybrid: M-cone template shifted to L-cone peak position.
    %                   Supports wavelength shifts.
    %
    %   M-cone variants (options.M_Template):
    %       "Standard" - Standard M-cone template. Supports wavelength shifts.
    %       "LinM"   - Hybrid: L-cone (Serine) template shifted to M-cone position.
    %                    Supports wavelength shifts.
    %
    %   Note on shifts:
    %       The Stockman & Rider templates are defined in log-wavelength space.
    %       Only the Serine L-cone template and the M-cone template have explicit
    %       shift parameters. The Mean template is a fixed weighted average, and
    %       the Alanine template is defined as Serine shifted by -2.7nm.
    %
    %   Reference:
    %       Stockman, A., & Rider, A. T. (2023). Formulae for generating standard
    %       and individual human cone spectral sensitivities. Color Res Appl.

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
        Name = "Stockman & Rider (2023) Cone Fundamental Templates"
        ShortName = "StockmanRider2023"
    end

    properties (Constant)
        % Base lambda-max values used for the log-wavelength shift
        % normalization in Stockman & Rider (2023) Eq. (1):
        %   xshift = log10(lambdaMax / (lambdaMax + shift)) / SR_LOG_WL_SCALE
        % These are the lambda-max values of the underlying Fourier
        % polynomials, not the lambda-max of every selectable variant.
        % Specifically:
        %   L = 553.1 nm is the L(Ser180) Fourier polynomial peak. The
        %       L(Ala180) variant is implemented as L(Ser180) shifted by
        %       -2.7 nm (peak ~ 550.4 nm). The Mean L variant is a
        %       linear-space weighted average of L(Ser180) and L(Ala180)
        %       computed at evaluation time, whose composite peak lies
        %       at ~ 551.9 nm.
        %   M = 529.9 nm is the value pycone uses for the M-cone shift
        %       normalization. The Fourier polynomial's actual numerical
        %       peak is at 529.80 nm and S&R 2023 Section 2.1 reports
        %       529.8 nm. The 0.1 nm constant is preserved verbatim for
        %       pycone parity; see Nomograms.SR_M_LMAX for details.
        %   S = 416.9 nm matches S&R 2023 to printed precision.
        % References: Stockman & Rider (2023), Table 1; pycone
        % CMFtemplates.py (Lserlmax_template, Mlmax_template, Slmax_template).
        BASE_LAMBDA_MAX_L = 553.1
        BASE_LAMBDA_MAX_M = 529.9
        BASE_LAMBDA_MAX_S = 416.9

        % SupportsShift  True; Stockman-Rider templates are defined in
        % log-wavelength space and accept lambda-max shifts.
        SupportsShift = true

        % SupportsAnalyticalPeak  False; Stockman-Rider is an 8th-order
        % Fourier polynomial fit pre-normalized so the peak is approximately
        % 1.0 in linear units. The exact peak location and value have no
        % closed form -- consumers must locate the peak numerically (e.g.
        % fminbnd over the active wavelength grid).
        SupportsAnalyticalPeak = false

        % ValidRange  The Stockman-Rider Fourier templates are designed
        % to produce accurate absorbance over 360-830 nm, covering the
        % full visible spectrum plus near-UV and near-IR extension.
        ValidRange = [360, 830]
    end

    methods
        function obj = StockmanRiderPhotopigmentTemplate()
            % STOCKMANRIDERPHOTOPIGMENTTEMPLATE  Construct a new Stockman-Rider template.
        end

        function logAbs = computeAbsorbance(obj, wl, coneType, shift, options)
            % COMPUTEABSORBANCE  Compute log10 absorbance using Stockman-Rider templates.
            %
            %   INPUTS:
            %       wl - Wavelengths in nm (vector)
            %       coneType - Cone type: 'L', 'M', or 'S' (char)
            %       shift - Wavelength shift in nm (double)
            %       options - Template-specific options: (struct)
            %           L_Template - L-cone variant: "Mean", "Serine", "Alanine", "MinL" (string)
            %           M_Template - M-cone variant: "Standard", "LinM" (string)
            %
            %   OUTPUTS:
            %       logAbs - Log10 absorbance spectrum (vector)
            arguments
                obj
                wl (:,1) double {validators.mustBeWavelengthVector}
                coneType (1,1) char {mustBeMember(coneType, {'L', 'M', 'S'})}
                shift (1,1) double
                options (1,1) struct = struct()
            end

            % Apply defaults
            if ~isfield(options, 'L_Template')
                options.L_Template = "Mean";
            end
            if ~isfield(options, 'M_Template')
                options.M_Template = "Standard";
            end

            switch coneType
                case 'L'
                    logAbs = obj.computeLconeLogAbsorbance(wl, shift, options.L_Template);
                case 'M'
                    logAbs = obj.computeMconeLogAbsorbance(wl, shift, options.M_Template);
                case 'S'
                    logAbs = Nomograms.stockmanRider(wl, 'S', Shift=shift);
            end
        end

        function peakAbs = computePeakAbsorbance(obj, coneType, shift, options)
            % COMPUTEPEAKABSORBANCE  Return peak absorbance value.
            %
            %   For Stockman-Rider templates, the Fourier coefficients include a
            %   normalization factor 's' that ensures absorbance peaks at exactly 1.0
            %   at lambda-max. This is by construction of the template.
            %
            %   Source: Stockman & Rider (2023), Table 1 - the 's' coefficient is
            %   "a renormalisation factor added after the polynomial fit so that the
            %   linear absorbance spectra peak exactly at 1 at lambda-max"
            %
            %   INPUTS:
            %       coneType - Cone type: 'L', 'M', or 'S' (char)
            %       shift - Wavelength shift in nm (unused) (double)
            %       options - Template-specific options (unused) (struct)
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

    methods (Access = private)
        function logAbs = computeLconeLogAbsorbance(~, wl, shift, templateType)
            % COMPUTELCONELOGABSORBANCE  Compute L-cone log absorbance.
            %
            %   Delegates to Nomograms.stockmanRider with the appropriate L_Template
            %   option. Wavelength shifts are only directly supported for the Serine
            %   template. If a non-zero shift is applied with Mean or Alanine templates,
            %   the method automatically switches to Serine and issues a warning.
            %   This matches the behavior of the Python reference implementation.
            arguments
                ~
                wl (:,1) double {validators.mustBeWavelengthVector}
                shift (1,1) double
                templateType (1,1) string
            end

            switch templateType
                case "Mean"
                    if shift ~= 0
                        warning('StockmanRiderPhotopigmentTemplate:ShiftOverride', ...
                            ['L-cone shift is non-zero (%.2f nm) but Mean template selected. ' ...
                            'Shifts only apply to Serine template. Switching to Serine.'], shift);
                        logAbs = Nomograms.stockmanRider(wl, 'L', Shift=shift, L_Template="Serine");
                    else
                        logAbs = Nomograms.stockmanRider(wl, 'L', L_Template="Mean");
                    end
                case "Serine"
                    logAbs = Nomograms.stockmanRider(wl, 'L', Shift=shift, L_Template="Serine");
                case "Alanine"
                    if shift ~= 0
                        % Alanine is defined as Serine shifted by -2.7nm. When a non-zero
                        % shift is requested, the user's shift is combined with the -2.7nm
                        % offset and applied to the Serine template directly.
                        warning('StockmanRiderPhotopigmentTemplate:ShiftOverride', ...
                            ['L-cone shift is non-zero (%.2f nm) but Alanine template selected. ' ...
                            'Alanine is Serine-2.7nm. Applying combined shift of %.2f nm to Serine template.'], ...
                            shift, shift - 2.7);
                        logAbs = Nomograms.stockmanRider(wl, 'L', Shift=shift-2.7, L_Template="Serine");
                    else
                        logAbs = Nomograms.stockmanRider(wl, 'L', L_Template="Alanine");
                    end
                case "MinL"
                    % Hybrid: M-cone template shifted to L-cone peak position.
                    % Nomograms.stockmanRider handles the L-M lambda-max difference internally.
                    logAbs = Nomograms.stockmanRider(wl, 'L', Shift=shift, L_Template="MinL");
                otherwise
                    logAbs = Nomograms.stockmanRider(wl, 'L', L_Template="Mean");
            end
        end

        function logAbs = computeMconeLogAbsorbance(~, wl, shift, templateType)
            % COMPUTEMCONELOGABSORBANCE  Compute M-cone log absorbance.
            %
            %   Delegates to Nomograms.stockmanRider with the appropriate M_Template
            %   option. Supports "Standard" (default) and "LinM" (hybrid) variants.
            arguments
                ~
                wl (:,1) double {validators.mustBeWavelengthVector}
                shift (1,1) double
                templateType (1,1) string
            end

            switch templateType
                case "LinM"
                    % Hybrid: L-cone (Serine) template shifted to M-cone position.
                    % Nomograms.stockmanRider handles the L-M lambda-max difference internally.
                    logAbs = Nomograms.stockmanRider(wl, 'M', Shift=shift, M_Template="LinM");
                otherwise
                    % Standard M-cone template
                    logAbs = Nomograms.stockmanRider(wl, 'M', Shift=shift, M_Template="Standard");
            end
        end
    end
end

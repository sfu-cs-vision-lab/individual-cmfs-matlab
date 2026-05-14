classdef Nomograms
    % NOMOGRAMS  Static utility class for photopigment absorbance computations.
    %
    %   This class contains the core mathematical functions for computing visual
    %   pigment absorbance spectra. It provides two main nomogram formulations:
    %
    %   1. Govardovskii et al. (2000): A parametric formula for vertebrate visual
    %      pigments that generates absorbance spectra based on lambda-max. The
    %      template consists of an alpha-band (main peak) modeled by a modified
    %      Lamb (1995) function, and a beta-band (UV secondary peak) modeled by
    %      a Gaussian. This template is universal across species and can generate
    %      spectra for any lambda-max in the visible range.
    %
    %   2. Stockman & Rider (2023): Fourier polynomial templates fitted directly
    %      to CIE cone fundamental data. These templates operate in log-wavelength
    %      space and provide high-precision representations of human L, M, and S
    %      cone absorbance spectra. Wavelength shifts are applied by translating
    %      along the log-wavelength axis.
    %
    %   The Govardovskii template returns linear absorbance (normalized to 1.0 at
    %   peak), while the Stockman-Rider templates return log10 absorbance.
    %
    %   References:
    %       Govardovskii, V. I., Fyhrquist, N., Reuter, T., Kuzmin, D. G., &
    %           Donner, K. (2000). In search of the visual pigment template.
    %           Visual Neuroscience, 17(4), 509-528.
    %
    %       Stockman, A., & Rider, A. T. (2023). Formulae for generating standard
    %           and individual human cone spectral sensitivities. Color Research
    %           and Application, 48(6), 818-840. doi:10.1002/col.22879

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

    properties (Constant)
        % Govardovskii et al. (2000) alpha-band coefficients from Eq. (1).
        % The alpha-band uses the modified Lamb (1995) formula:
        %   S(x) = 1 / {exp[A(a-x)] + exp[B(b-x)] + exp[C(c-x)] + D}
        % where x = lambda_max/lambda
        % Source: Govardovskii et al. (2000), Vis. Neurosci. 17(4), 509-528, Eq. 1.
        GOV_A = 69.7
        GOV_B = 28.0
        GOV_C = -14.9
        GOV_D = 0.674
        GOV_B_OFFSET = 0.922
        GOV_C_OFFSET = 1.104

        % Govardovskii parameter 'a' is lambda-max dependent, expressed as p/A
        % where p = 61.3 + 3.2*exp(-((lambda_max-300)^2)/11940).
        % These constants define the p calculation.
        % Source: Govardovskii et al. (2000), Eq. 2.
        GOV_P_BASE = 61.3
        GOV_P_AMPLITUDE = 3.2
        GOV_P_CENTER = 300
        GOV_P_WIDTH = 11940

        % Beta-band coefficients. Modeled as a Gaussian in wavelength space:
        %   S_beta = A_beta * exp(-((lambda - lambda_m_beta)/d)^2)
        % where lambda_m_beta = 189 + 0.315*lambda_max (Eq. 5a)
        % and d = -40.5 + 0.195*lambda_max (Eq. 5b).
        % Source: Govardovskii et al. (2000), Eqs. 4, 5a, 5b.
        GOV_ABETA = 0.26
        GOV_BETA_PEAK_INTERCEPT = 189.0
        GOV_BETA_PEAK_SLOPE = 0.315
        GOV_BETA_WIDTH_INTERCEPT = -40.5
        GOV_BETA_WIDTH_SLOPE = 0.195

        % Govardovskii et al. (2000) A2 (3,4-dehydroretinal) alpha-band
        % coefficients. Same functional form as the A1 template (Eq. 1),
        % but with different fixed constants and a different lambda-max
        % dependence: in A2 both 'A' and 'a' are lambda-max dependent
        % (Eqs. 6a, 6b), whereas A1 has fixed A and lambda-max-dependent
        % 'a' only.
        % Source: Govardovskii et al. (2000), Vis. Neurosci. 17(4),
        % 509-528, paragraph after Eq. (5) (page 517).
        GOV_A2_B = 20.85
        GOV_A2_C = -10.37
        GOV_A2_D = 0.5343
        GOV_A2_B_OFFSET = 0.9101
        GOV_A2_C_OFFSET = 1.1123

        % Lambda-max-dependent A2 parameters (Eqs. 6a, 6b):
        %   A(lmax) = 62.7 + 1.834 * exp[(lmax - 625) / 54.2]
        %   a(lmax) = 0.875 + 0.0268 * exp[(lmax - 665) / 40.7]
        GOV_A2_A_BASE = 62.7
        GOV_A2_A_AMPLITUDE = 1.834
        GOV_A2_A_CENTER = 625
        GOV_A2_A_WIDTH = 54.2
        GOV_A2_a_BASE = 0.875
        GOV_A2_a_AMPLITUDE = 0.0268
        GOV_A2_a_CENTER = 665
        GOV_A2_a_WIDTH = 40.7

        % A2 beta-band coefficients. Gaussian form (Eq. 4) with:
        %   lambda_m_beta = 216.7 + 0.287*lmax (Eq. 8a)
        %   d = 317 - 1.149*lmax + 0.00124*lmax^2 (Eq. 8b, quadratic)
        % Amplitude A_beta = 0.37 (fixed; A1 uses 0.26).
        % Source: Govardovskii et al. (2000), Eqs. 4, 8a, 8b.
        GOV_A2_ABETA = 0.37
        GOV_A2_BETA_PEAK_INTERCEPT = 216.7
        GOV_A2_BETA_PEAK_SLOPE = 0.287
        GOV_A2_BETA_WIDTH_INTERCEPT = 317.0
        GOV_A2_BETA_WIDTH_LINEAR = -1.149
        GOV_A2_BETA_WIDTH_QUADRATIC = 0.00124

        % Stockman-Rider Fourier series parameters.
        % The templates use 8th-order Fourier polynomials in log-wavelength space:
        %   f(x) = a0 + sum_{k=1}^{8} [a_k*cos(kx) + b_k*sin(kx)]
        % Coefficients are stored as column vectors [a0; a1; b1; a2; b2; ... a8; b8; s]
        % where s is a renormalization constant.
        % Source: Stockman & Rider (2023), Eq. 1.
        SR_LOG_WL_CENTER = 2.556302500767287267
        SR_LOG_WL_SCALE = 0.1187666467581842301

        % L-cone (Serine variant) Fourier coefficients.
        % SR_L_LMAX = 553.1 nm is the value pycone uses for the
        % log-wavelength shift normalization; it equals the L(Ser180)
        % Fourier polynomial's actual numerical peak to printed precision.
        % The L(Ala180) variant is derived as L(Ser180) shifted by
        % SR_ALANINE_SHIFT = -2.7 nm. The Mean L variant is composed at
        % evaluation time and peaks at ~ 551.9 nm.
        % Source: Stockman & Rider (2023), Table 1; pycone CMFtemplates.py
        % (Lserlmax_template = 553.1).
        SR_L_LMAX = 553.1
        SR_L_COEFFS = [-42.417608560; -2.656791612; 75.011093607; 56.477062776; ...
                        7.509397607;  9.061442173; -38.068488495; -20.974610259; ...
                       -6.642746250; -3.785039126;   9.322071459;   3.134494745; ...
                        1.603799055;  0.439302358;  -0.676958684;  -0.072988371; ...
                       -0.078857510; -0.004264105]

        % M-cone Fourier coefficients.
        % SR_M_LMAX = 529.9 nm is the value pycone uses for the
        % log-wavelength shift normalization (pycone CMFtemplates.py,
        % Mlmax_template = 529.9). The Fourier polynomial's actual
        % numerical peak is at 529.80 nm, and S&R 2023 Section 2.1
        % reports 529.8 nm. The 0.1 nm constant is preserved verbatim
        % for parity with pycone; output differs by ~ 6e-6 from the
        % "true" 529.8 only when a non-zero M_LambdaMaxShift is applied.
        % Source: Stockman & Rider (2023), Table 1; pycone parity.
        SR_M_LMAX = 529.9
        SR_M_COEFFS = [-210.6568853069; -0.1458073553; 386.7319763250; 305.4710584670; ...
                          5.0218382813;  6.8386224350; -208.2062335724; -118.4890200521; ...
                         -5.7625866330; -3.7973553168;   55.1803460639;   19.9728512548; ...
                          1.8990456325;  0.6913410864;   -5.0891806213;   -0.7070689492; ...
                         -0.1419926703;  0.0005894876]

        % S-cone Fourier coefficients.
        % Template lambda_max = 416.9 nm
        % Source: Stockman & Rider (2023), Table 1.
        SR_S_LMAX = 416.9
        SR_S_COEFFS = [207.3880950935; -6.3065623516; -393.7100478026; -315.6650602846; ...
                        19.2917535553; 19.6414743488;  214.2211570447;  121.8584683485; ...
                       -15.1820737886; -8.6774057156;  -56.7596380441;  -20.6318720369; ...
                         3.6934875040;  1.0483022480;    5.3656615075;    0.7898783086; ...
                        -0.1480357836;  0.0002358232]

        % Mean L-cone renormalization factor.
        % The mean template is computed as:
        %   log10(RENORM * (0.56*10^Serine + 0.44*10^Alanine))
        % The exact literal value is copied verbatim from pycone
        % (CMFtemplates.py, Lmeanconelog: literal 1.0009350552348480).
        % It is an empirically derived correction so the composite Mean
        % L absorbance peaks at the canonical level for the toolbox.
        % Not derivable in closed form from S&R 2023 Eq. 2 alone.
        SR_LMEAN_RENORM = 1.0009350552348480
        SR_LMEAN_SERINE_WEIGHT = 0.56
        SR_LMEAN_ALANINE_WEIGHT = 0.44
        SR_ALANINE_SHIFT = -2.70

        % L-serine to M-cone lambda_max difference in nm.
        % Used for computing hybrid templates (M-in-L, L-in-M) and as
        % the numerator of the Genotype Table-3 scaling factor.
        % NOTE: 23.67 is a pycone parity convention, not a value
        % prescribed by S&R 2023. Pycone defines it as the difference
        % between its class-level Lserlmax_template = 554.86 nm and
        % Mlmax_template = 531.19 nm (LMStemplateCMFs.py: Lser_Mlmax_diff).
        % The toolbox's actual numerical L(Ser)-M gap is 23.31 nm
        % (553.11 - 529.80), so a MinL hybrid lands at 553.47 instead of
        % 553.11 (a 0.36 nm offset). The 23.67 value is preserved so
        % the toolbox matches pycone bit-for-bit; the SR 2023 paper
        % itself does not publish 23.67 as the L-M gap.
        SR_LSER_M_LMAX_DIFF = 23.67

        % Valid wavelength ranges for each template type
        GOV_VALID_RANGE = [380, 780]
        SR_VALID_RANGE = [360, 830]
    end

    methods (Static)
        function absorbance = govardovskii2000(wavelengths, lambdaMax)
            % GOVARDOVSKII2000  Compute absorbance using Govardovskii A1 template.
            %
            %   absorbance = Nomograms.govardovskii2000(wavelengths, lambdaMax)
            %
            %   The Govardovskii template is a parametric formula for vertebrate
            %   A1-type visual pigments. It combines an alpha-band (main absorption
            %   peak) with a beta-band (secondary UV peak) to produce a complete
            %   absorbance spectrum.
            %
            %   The alpha-band uses the modified Lamb formula with a lambda-max
            %   dependent 'a' parameter that improves fits for short-wavelength
            %   pigments. For lambda_max > 500nm, the 'a' parameter is nearly
            %   constant (~0.88), but decreases for smaller lambda_max.
            %
            %   INPUTS:
            %       wavelengths - Wavelengths in nm (column vector) (vector)
            %       lambdaMax - Peak wavelength of the pigment in nm (scalar)
            %
            %   OUTPUTS:
            %       absorbance - Linear absorbance (0 to ~1) (vector)
            %
            %   EXAMPLE:
            %       wl = (380:1:780)';
            %       abs = Nomograms.govardovskii2000(wl, 559);  % L-cone
            %
            %   Source: Govardovskii, V.I., Fyhrquist, N., Reuter, T., Kuzmin, D.G.
            %   & Donner, K. (2000). In search of the visual pigment template.
            %   Visual Neuroscience, 17(4), 509-528. doi:10.1017/S0952523800174036
            arguments
                wavelengths (:,1) double {validators.mustBeWavelengthVector}
                lambdaMax (1,1) double
            end

            Nomograms.validateWavelengths(wavelengths, Nomograms.GOV_VALID_RANGE);

            % Alpha-band: S(x) = 1 / {exp[A(a-x)] + exp[B(b-x)] + exp[C(c-x)] + D}
            % The variable x represents the wavenumber ratio lambda_max/lambda
            x = lambdaMax ./ wavelengths;

            % Parameter 'a' is lambda-max dependent (Eq. 2).
            % This modification from Lamb's original constant a=0.88 improves
            % fits for short-wavelength pigments by steepening the long-wave slope.
            p = Nomograms.GOV_P_BASE + Nomograms.GOV_P_AMPLITUDE * ...
                exp(-((lambdaMax - Nomograms.GOV_P_CENTER)^2) / Nomograms.GOV_P_WIDTH);
            a = p / Nomograms.GOV_A;

            term1 = exp(Nomograms.GOV_A * (a - x));
            term2 = exp(Nomograms.GOV_B * (Nomograms.GOV_B_OFFSET - x));
            term3 = exp(Nomograms.GOV_C * (Nomograms.GOV_C_OFFSET - x));

            S_alpha = 1 ./ (term1 + term2 + term3 + Nomograms.GOV_D);

            % Beta-band: Gaussian in wavelength space (Eq. 4)
            lambda_m_beta = Nomograms.GOV_BETA_PEAK_INTERCEPT + ...
                            Nomograms.GOV_BETA_PEAK_SLOPE * lambdaMax;
            d = Nomograms.GOV_BETA_WIDTH_INTERCEPT + ...
                Nomograms.GOV_BETA_WIDTH_SLOPE * lambdaMax;

            S_beta = Nomograms.GOV_ABETA * exp(-((wavelengths - lambda_m_beta) / d).^2);

            % Combined absorbance
            absorbance = S_alpha + S_beta;

            % Clamp negative values (can occur at wavelength extremes)
            absorbance(absorbance < 0) = 0;
        end

        function absorbance = govardovskii2000A2(wavelengths, lambdaMax)
            % GOVARDOVSKII2000A2  Compute absorbance using Govardovskii A2 template.
            %
            %   absorbance = Nomograms.govardovskii2000A2(wavelengths, lambdaMax)
            %
            %   The A2 template is the 3,4-dehydroretinal-based companion
            %   to the A1 template defined in govardovskii2000(). A2 is
            %   the chromophore found in freshwater fish, larval
            %   amphibians, and some reptiles; the same opsin protein
            %   combined with A2 produces a systematic red-shift in
            %   lambda-max relative to A1.
            %
            %   The functional form is identical to A1 (Eq. 1), but with
            %   different fixed constants and a lambda-max-dependent A:
            %     A(lmax) = 62.7 + 1.834 * exp[(lmax - 625) / 54.2]   (Eq. 6a)
            %     a(lmax) = 0.875 + 0.0268 * exp[(lmax - 665) / 40.7] (Eq. 6b)
            %     B = 20.85, b = 0.9101, C = -10.37, c = 1.1123, D = 0.5343
            %
            %   The beta-band amplitude is 0.37 (vs 0.26 for A1) and the
            %   beta-band width regression on lambda-max is quadratic in
            %   A2 (Eq. 8b) rather than linear.
            %
            %   INPUTS:
            %       wavelengths - Wavelengths in nm (column vector) (vector)
            %       lambdaMax - Peak wavelength of the pigment in nm (scalar)
            %
            %   OUTPUTS:
            %       absorbance - Linear absorbance (0 to ~1) (vector)
            %
            %   EXAMPLE:
            %       wl = (380:1:780)';
            %       % Carp red cone, lambda_max = 619.4 nm (Govardovskii Fig. 9A)
            %       abs = Nomograms.govardovskii2000A2(wl, 619.4);
            %
            %   Source: Govardovskii, V.I., Fyhrquist, N., Reuter, T., Kuzmin, D.G.
            %   & Donner, K. (2000). In search of the visual pigment template.
            %   Visual Neuroscience, 17(4), 509-528. doi:10.1017/S0952523800174036
            arguments
                wavelengths (:,1) double {validators.mustBeWavelengthVector}
                lambdaMax (1,1) double
            end

            Nomograms.validateWavelengths(wavelengths, Nomograms.GOV_VALID_RANGE);

            % Alpha-band: same form as A1 (Eq. 1) with x = lambda_max / lambda.
            x = lambdaMax ./ wavelengths;

            % Both A and a are lambda-max dependent in A2 (Eqs. 6a, 6b).
            A = Nomograms.GOV_A2_A_BASE + Nomograms.GOV_A2_A_AMPLITUDE * ...
                exp((lambdaMax - Nomograms.GOV_A2_A_CENTER) / Nomograms.GOV_A2_A_WIDTH);
            a = Nomograms.GOV_A2_a_BASE + Nomograms.GOV_A2_a_AMPLITUDE * ...
                exp((lambdaMax - Nomograms.GOV_A2_a_CENTER) / Nomograms.GOV_A2_a_WIDTH);

            term1 = exp(A * (a - x));
            term2 = exp(Nomograms.GOV_A2_B * (Nomograms.GOV_A2_B_OFFSET - x));
            term3 = exp(Nomograms.GOV_A2_C * (Nomograms.GOV_A2_C_OFFSET - x));

            S_alpha = 1 ./ (term1 + term2 + term3 + Nomograms.GOV_A2_D);

            % Beta-band: Gaussian (Eq. 4) with quadratic-in-lmax width (Eq. 8b).
            lambda_m_beta = Nomograms.GOV_A2_BETA_PEAK_INTERCEPT + ...
                            Nomograms.GOV_A2_BETA_PEAK_SLOPE * lambdaMax;
            d = Nomograms.GOV_A2_BETA_WIDTH_INTERCEPT + ...
                Nomograms.GOV_A2_BETA_WIDTH_LINEAR * lambdaMax + ...
                Nomograms.GOV_A2_BETA_WIDTH_QUADRATIC * lambdaMax^2;

            S_beta = Nomograms.GOV_A2_ABETA * exp(-((wavelengths - lambda_m_beta) / d).^2);

            absorbance = S_alpha + S_beta;
            absorbance(absorbance < 0) = 0;
        end

        function logAbsorbance = stockmanRider(wavelengths, coneType, options)
            % STOCKMANRIDER  Compute log absorbance using Stockman-Rider templates.
            %
            %   logAbsorbance = Nomograms.stockmanRider(wavelengths, coneType)
            %   logAbsorbance = Nomograms.stockmanRider(wavelengths, coneType, options)
            %
            %   The Stockman-Rider templates are 8th-order Fourier polynomials
            %   fitted to CIE cone fundamental data. They operate in log-wavelength
            %   space, which means wavelength shifts translate to horizontal
            %   translations along the log-wavelength axis.
            %
            %   INPUTS:
            %       wavelengths - Wavelengths in nm (column vector) (vector)
            %       coneType - Cone type: 'L', 'M', or 'S' (char)
            %       options - Optional parameters: (struct)
            %           Shift - Wavelength shift in nm. Default: 0 (double)
            %           L_Template - L-cone variant: "Mean", "Serine", (string)
            %                                 "Alanine", "MinL". Default: "Serine".
            %           M_Template - M-cone variant: "Standard", "LinM" (string) Default: "Standard"
            %
            %   OUTPUTS:
            %       logAbsorbance - Log10 absorbance spectrum (vector)
            %
            %   EXAMPLE:
            %       wl = (360:1:830)';
            %       logAbs = Nomograms.stockmanRider(wl, 'L', Shift=2.5);
            %
            %   Note:
            %       The Mean L-cone template is a weighted average of Serine (56%)
            %       and Alanine (44%) variants. The Alanine template is equivalent
            %       to Serine shifted by -2.7nm.
            %
            %   Source: Stockman, A. & Rider, A.T. (2023). Formulae for generating
            %   standard and individual human cone spectral sensitivities. Color
            %   Research and Application, 48(6), 818-840. doi:10.1002/col.22879
            arguments
                wavelengths (:,1) double {validators.mustBeWavelengthVector}
                coneType (1,1) char {mustBeMember(coneType, {'L', 'M', 'S'})}
                options.Shift (1,1) double = 0
                options.L_Template (1,1) string = "Serine"
                options.M_Template (1,1) string = "Standard"
            end

            Nomograms.validateWavelengths(wavelengths, Nomograms.SR_VALID_RANGE);

            switch coneType
                case 'L'
                    logAbsorbance = Nomograms.computeLcone(wavelengths, options.Shift, options.L_Template);
                case 'M'
                    logAbsorbance = Nomograms.computeMcone(wavelengths, options.Shift, options.M_Template);
                case 'S'
                    logAbsorbance = Nomograms.computeScone(wavelengths, options.Shift);
            end
        end

        function validateWavelengths(wavelengths, validRange, options)
            % VALIDATEWAVELENGTHS  Check wavelengths are within valid range.
            %
            %   Nomograms.validateWavelengths(wavelengths, validRange)
            %
            %   Issues a warning if any wavelengths fall outside the specified
            %   valid range. The warning is issued only once per session to avoid
            %   excessive console output during iterative computations.
            %
            %   Nomograms.validateWavelengths([], [], Reset=true) resets the
            %   warning state so warnings can be issued again.
            %
            %   INPUTS:
            %       wavelengths - Wavelengths to validate in nm (vector)
            %       validRange - Valid range [min_nm, max_nm] (1x2)
            %
            %   OPTIONAL INPUTS (Name-Value arguments):
            %       Reset - If true, resets the warning state (logical)
            %
            %   The warning has ID 'Nomograms:WavelengthOutOfRange'.
            arguments
                wavelengths (:,1) double {validators.mustBeWavelengthVector} = []
                validRange (:,2) double = []
                options.Reset (1,1) logical = false
            end

            persistent hasWarned
            if isempty(hasWarned)
                hasWarned = false;
            end

            % Handle reset request
            if options.Reset
                hasWarned = false;
                return
            end

            if hasWarned
                return
            end

            % Skip validation if no wavelengths provided
            if isempty(wavelengths)
                return
            end

            minWl = min(wavelengths);
            maxWl = max(wavelengths);

            if minWl < validRange(1) || maxWl > validRange(2)
                % Only flip the once-per-session latch when the warning
                % is actually emitted. If the caller (typically
                % IndividualCMF when WavelengthWarning=false) has
                % suppressed Nomograms:WavelengthOutOfRange, leave
                % hasWarned alone so the warning will fire next time the
                % suppression is lifted.
                s = warning('query', 'Nomograms:WavelengthOutOfRange');
                if strcmp(s.state, 'on')
                    hasWarned = true;
                    warning('Nomograms:WavelengthOutOfRange', ...
                        'Wavelengths [%.1f, %.1f] nm extend beyond valid range [%.0f, %.0f] nm. Results may be unreliable.', ...
                        minWl, maxWl, validRange(1), validRange(2));
                end
            end
        end

        function resetWarnings()
            % RESETWARNINGS  Reset the wavelength warning state.
            %
            %   Nomograms.resetWarnings()
            %
            %   Clears the persistent warning state so that wavelength validation
            %   warnings will be issued again. Useful for testing.
            Nomograms.validateWavelengths([], [], Reset=true);
        end
    end

    methods (Static, Access = private)
        function logAbs = computeLcone(wavelengths, shift, templateType)
            % COMPUTELCONE  Compute L-cone log absorbance for various templates.
            arguments
                wavelengths (:,1) double {validators.mustBeWavelengthVector}
                shift (1,1) double
                templateType (1,1) string
            end

            switch templateType
                case "Serine"
                    logAbs = Nomograms.fourierTemplate(wavelengths, shift, ...
                        Nomograms.SR_L_COEFFS, Nomograms.SR_L_LMAX);
                case "Alanine"
                    % Alanine is Serine shifted by -2.7nm
                    combinedShift = shift + Nomograms.SR_ALANINE_SHIFT;
                    logAbs = Nomograms.fourierTemplate(wavelengths, combinedShift, ...
                        Nomograms.SR_L_COEFFS, Nomograms.SR_L_LMAX);
                case "Mean"
                    % Weighted average of Serine and Alanine in linear space
                    serineLog = Nomograms.fourierTemplate(wavelengths, shift, ...
                        Nomograms.SR_L_COEFFS, Nomograms.SR_L_LMAX);
                    alanineLog = Nomograms.fourierTemplate(wavelengths, ...
                        shift + Nomograms.SR_ALANINE_SHIFT, ...
                        Nomograms.SR_L_COEFFS, Nomograms.SR_L_LMAX);
                    serineLin = 10.^serineLog;
                    alanineLin = 10.^alanineLog;
                    meanLin = Nomograms.SR_LMEAN_RENORM * ...
                        (Nomograms.SR_LMEAN_SERINE_WEIGHT * serineLin + ...
                         Nomograms.SR_LMEAN_ALANINE_WEIGHT * alanineLin);
                    logAbs = log10(meanLin);
                case "MinL"
                    % Hybrid: M-cone template shifted to L-cone position
                    hybridShift = shift + Nomograms.SR_LSER_M_LMAX_DIFF;
                    logAbs = Nomograms.fourierTemplate(wavelengths, hybridShift, ...
                        Nomograms.SR_M_COEFFS, Nomograms.SR_M_LMAX);
                otherwise
                    error('Nomograms:InvalidTemplate', ...
                        'Unknown L-cone template: %s. Valid options: "Serine", "Alanine", "Mean", "MinL".', ...
                        templateType);
            end
        end

        function logAbs = computeMcone(wavelengths, shift, templateType)
            % COMPUTEMCONE  Compute M-cone log absorbance for various templates.
            arguments
                wavelengths (:,1) double {validators.mustBeWavelengthVector}
                shift (1,1) double
                templateType (1,1) string
            end

            switch templateType
                case "Standard"
                    logAbs = Nomograms.fourierTemplate(wavelengths, shift, ...
                        Nomograms.SR_M_COEFFS, Nomograms.SR_M_LMAX);
                case "LinM"
                    % Hybrid: L-cone (Serine) template shifted to M-cone position
                    hybridShift = shift - Nomograms.SR_LSER_M_LMAX_DIFF;
                    logAbs = Nomograms.fourierTemplate(wavelengths, hybridShift, ...
                        Nomograms.SR_L_COEFFS, Nomograms.SR_L_LMAX);
                otherwise
                    error('Nomograms:InvalidTemplate', ...
                        'Unknown M-cone template: %s. Valid options: "Standard", "LinM".', ...
                        templateType);
            end
        end

        function logAbs = computeScone(wavelengths, shift)
            % COMPUTESCONE  Compute S-cone log absorbance.
            arguments
                wavelengths (:,1) double {validators.mustBeWavelengthVector}
                shift (1,1) double
            end

            logAbs = Nomograms.fourierTemplate(wavelengths, shift, ...
                Nomograms.SR_S_COEFFS, Nomograms.SR_S_LMAX);
        end

        function logAbs = fourierTemplate(wavelengths, shift, coeffs, templateLmax)
            % FOURIERTEMPLATE  Evaluate 8th-order Fourier polynomial template.
            %
            %   The Stockman-Rider templates use the following parameterization:
            %     x = (log10(wl) - center) / scale + x_shift
            %   where x_shift = log10(lmax / (lmax + shift)) / scale
            %
            %   The Fourier sum is:
            %     f(x) = a0 + sum_{k=1}^{8} [a_k*cos(kx) + b_k*sin(kx)] + s
            %   where s is the trailing coefficient (additive in
            %   log-absorbance space; S&R 2023 Eq. 1). NOTE the convention
            %   split with the lens and macular Fourier templates, which
            %   use the same Fourier sum but multiply the trailing
            %   coefficient d in linear-density space (Eq. 3):
            %   StockmanRiderLensTemplate.fourierLensTemplate and
            %   StockmanRider2023MacularTemplate.fourierMacularTemplate
            %   implement the multiplicative form. Photopigments are
            %   additive because the templates are fit in log-absorbance;
            %   lens / macular are multiplicative because they are fit
            %   directly in linear density.
            arguments
                wavelengths (:,1) double {validators.mustBeWavelengthVector}
                shift (1,1) double
                coeffs (:,1) double
                templateLmax (1,1) double
            end

            % Transform wavelengths to normalized log-wavelength space
            x = (log10(wavelengths) - Nomograms.SR_LOG_WL_CENTER) / Nomograms.SR_LOG_WL_SCALE;

            % Apply wavelength shift in log-wavelength space
            xshift = log10(templateLmax / (templateLmax + shift)) / Nomograms.SR_LOG_WL_SCALE;
            x = x + xshift;

            % Evaluate 8th-order Fourier polynomial
            order = 8;
            % a0 term
            val = coeffs(1);
            k = 1:order;

            % Coefficient indices: [a0, a1, b1, a2, b2, ..., a8, b8, s]
            % a1, a2, ..., a8
            idx_cos = 2 + (k-1)*2;
            % b1, b2, ..., b8
            idx_sin = 3 + (k-1)*2;

            c_cos = coeffs(idx_cos);
            c_sin = coeffs(idx_sin);

            % Vectorized computation
            terms = cos(x * k) .* c_cos' + sin(x * k) .* c_sin';
            val = val + sum(terms, 2);

            % Add renormalization constant (last coefficient)
            logAbs = val + coeffs(end);
        end
    end
end

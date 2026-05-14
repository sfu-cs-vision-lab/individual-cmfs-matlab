classdef VanDeKraatsVanNorren2007LensTemplate < LensTemplate
    % VANDEKRAATSVANNORREN2007LENSTEMPLATE  Five-component aging-media template (van de Kraats & van Norren 2007).
    %
    %   This lens model implements the total-ocular-media density model of
    %   van de Kraats & van Norren (2007), Eq. 8. The model is a sum of
    %   five Gaussian-or-power-law spectral templates:
    %
    %     M_RL    Rayleigh loss              (400/lambda)^4
    %     M_TP    Tryptophan                 narrow Gaussian, peak 273 nm
    %     M_LY    Lens Young chromophore     Gaussian, peak 370 nm
    %     M_LOUV  Lens Old UV chromophore    Gaussian, peak 325 nm
    %     M_LO    Lens Old chromophore       broad Gaussian, peak 325 nm
    %
    %   Each component has a quadratic-in-age density coefficient
    %       d_i(age) = d_{i,0} + alpha_i * age^2
    %   (Eq. 7) plus a wavelength-flat offset d_neutral = 0.111 representing
    %   spectrally-neutral light losses in the non-lens media.
    %
    %   Total-media interpretation. The coefficients in Eq. 8 (and used here)
    %   describe the entire ocular media absorption -- cornea, aqueous,
    %   vitreous, AND lens. This matches what the toolbox's existing
    %   StockmanRider2023 and Pokorny1987 lens templates also represent in
    %   practice (both are fitted to whole-eye psychophysical data, not
    %   pure isolated-lens measurements).
    %
    %   Note on macular pigment. Despite the model's breadth, vdK&vN 2007
    %   explicitly excludes macular pigment. From Section 2:
    %     "Chromophores in the retina, like macular pigment, were not
    %      supposed to be a part of the ocular media."
    %   Macular filtering remains the responsibility of the active
    %   MacularTemplate; this class models only the lens-stage filtering.
    %
    %   Field-size dependence of Rayleigh loss. The d_RL coefficient
    %   reported in Table 6 has two values:
    %     0.446  for fields <= 3 deg
    %     0.225  for fields >  3 deg
    %   The reduction at large fields reflects forward-scattered light that
    %   re-enters the wider detector aperture. This class selects between
    %   the two values based on the fieldSize argument threaded through
    %   computeTemplate / computeDensityAt400; the IndividualCMF orchestrator
    %   passes the observer's FieldSize automatically. For 10-deg observers
    %   the large-field coefficient lowers the absolute density at 400 nm
    %   by ~ 0.2 OD relative to the small-field value.
    %
    %   Wavelength validity. The templates are fitted on data from 300-700 nm.
    %   This class extrapolates the analytical forms outside that range
    %   (the Gaussians decay smoothly, M_RL increases as lambda^-4); use
    %   below 300 nm or above 700 nm with awareness that the model was not
    %   fitted there. StockmanRider2023 covers 360-830 nm by design;
    %   switch lens models if extreme-wavelength precision matters.
    %
    %   Reference:
    %       van de Kraats, J. & van Norren, D. (2007). Optical density of
    %       the aging human ocular media in the visible and the UV.
    %       Journal of the Optical Society of America A, 24(7), 1842-1857.
    %       doi:10.1364/JOSAA.24.001842
    %
    %       Templates: Eqs. 2-6, Table 1.
    %       Density coefficients and aging: Eq. 8, Table 6.
    %
    %   See also: LensTemplate, StockmanRiderLensTemplate, Pokorny1987LensTemplate, IndividualCMF

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada
    %
    % This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    % Licensed under AGPL-3.0-or-later. See LICENSE file for details.
    % Repository: https://github.com/sfu-cs-vision-lab/Individual-CMFs

    properties (SetAccess = protected)
        Name = "van de Kraats & van Norren (2007)"
        ShortName = "VanDeKraats2007"
    end

    properties (Constant)
        % SupportsAging  True; vdK&vN's component density coefficients
        % depend on age via the quadratic d_i = d_{i,0} + alpha_i * age^2
        % relationship (Eq. 7), so the spectral SHAPE shifts with age as
        % the relative contributions of the five components evolve.
        SupportsAging = true
    end

    properties (Constant, Access = private)
        % All constants in this block derive from:
        %   van de Kraats & van Norren (2007). Optical density of the aging
        %   human ocular media in the visible and the UV. JOSA A, 24(7),
        %   1842-1857.
        %
        % Template parameters from Table 1 / Eqs. 2-6.
        % Per-component aging coefficients from Table 6 (donor lens fit).
        %
        % Each component is described by
        %   M_i(lambda) = NORM_i * exp(-{[WIDTH_i * (lambda - PEAK_i)]^2})
        % (Gaussians: TP, LY, LOUV, LO) or
        %   M_RL(lambda) = (400 / lambda)^4
        % (power law: Rayleigh loss).

        % Rayleigh loss (M_RL).
        % Power-law scattering, normalized to 1.0 at 400 nm.
        % d_RL,0 is field-size dependent (Table 6):
        %   0.446 for fields <= 3 deg (small-field, e.g. 2-deg observer)
        %   0.225 for fields >  3 deg (large-field, e.g. 10-deg observer)
        % alpha_RL = 0.000031 is shared by both regimes.
        RL_D0_SMALL_FIELD = 0.446
        RL_D0_LARGE_FIELD = 0.225
        RL_FIELD_SIZE_THRESHOLD = 3
        RL_ALPHA = 0.000031

        % Tryptophan (M_TP).
        % Gaussian peak 273 nm, width 0.057 nm^-1, normalized to 1.0 at 300 nm.
        % This component is age-invariant (alpha_TP = 0). The coefficient
        % d_TP = 14.19 is the TOTAL ocular-media value used in Eq. 8 (p.
        % 1851, Table 6 row "Sum total media lens"), not a partial. It
        % decomposes as 12.36 (lens, Subsection 3.H) + 1.83 (cornea +
        % aqueous + vitreous, Section 4.C / Table 4) = 14.19. The
        % age-invariance reflects the fact that lens TP is masked above
        % 320 nm by other lens components, so vdK&vN could not fit alpha
        % from the donor-lens data and held it at zero.
        TP_PEAK = 273
        TP_WIDTH = 0.057
        TP_NORM = 10.68
        TP_D0 = 14.19
        TP_ALPHA = 0

        % Lens Young (M_LY).
        % Gaussian peak 370 nm, width 0.029 nm^-1, normalized to 2.13 at 400 nm.
        % d_LY,0 = 0.998; alpha_LY = -0.000063 (slight DECREASE with age,
        % reflecting kynurenine derivative consumption as the lens ages).
        LY_PEAK = 370
        LY_WIDTH = 0.029
        LY_NORM = 2.13
        LY_D0 = 0.998
        LY_ALPHA = -0.000063

        % Lens Old UV (M_LOUV).
        % Gaussian peak 325 nm, width 0.021 nm^-1, normalized to 11.95 at 400 nm.
        % d_LOUV,0 = 0.059; alpha_LOUV = 0.000186.
        LOUV_PEAK = 325
        LOUV_WIDTH = 0.021
        LOUV_NORM = 11.95
        LOUV_D0 = 0.059
        LOUV_ALPHA = 0.000186

        % Lens Old (M_LO).
        % Broader Gaussian: peak 325 nm, width 0.008 nm^-1, normalized to
        % 1.43 at 400 nm. The shallow shape extends well into the visible.
        % d_LO,0 = 0.016; alpha_LO = 0.000132.
        LO_PEAK = 325
        LO_WIDTH = 0.008
        LO_NORM = 1.43
        LO_D0 = 0.016
        LO_ALPHA = 0.000132

        % Spectrally-neutral offset (d_neutral).
        % Wavelength-independent baseline OD in the non-lens media (Eq. 8).
        % Roughly the small-particle scatter losses not absorbed into RL.
        D_NEUTRAL = 0.111
    end

    methods
        function obj = VanDeKraatsVanNorren2007LensTemplate()
            % VANDEKRAATSVANNORREN2007LENSTEMPLATE  Construct the template.
        end

        function template = computeTemplate(obj, wavelengths, age, options)
            % COMPUTETEMPLATE  Lens density spectrum normalized to 1.0 at 400 nm.
            %
            %   template = obj.computeTemplate(wavelengths, age) returns
            %   the total-media optical density (Eq. 8) at each wavelength
            %   for an observer of the specified age, divided by the value
            %   at 400 nm so that the returned spectrum equals 1.0 there.
            %   The Rayleigh-loss coefficient d_RL is selected by field size
            %   (Table 6): 0.446 for fields <= 3 deg, 0.225 for > 3 deg.
            %   template = obj.computeTemplate(wavelengths, age, FieldSize=fs)
            %   passes the observer field size in degrees. When omitted, the
            %   small-field value is used (backward compatible default).
            %
            %   The shape shifts subtly with age because the five component
            %   coefficients each scale differently with age^2 (Eq. 7);
            %   the standard 32-year-old shape and an 80-year-old shape
            %   differ most strongly near the LOUV (325 nm) and LO peaks
            %   relative to the longer-wavelength Rayleigh tail.
            %
            %   INPUTS:
            %       wavelengths - Wavelengths in nanometers (column vector)
            %       age         - Observer age in years (scalar)
            %
            %   OPTIONAL INPUTS (Name-Value arguments):
            %       FieldSize - Observer field size in degrees (scalar).
            %                   Selects small-field (<=3) vs large-field (>3)
            %                   Rayleigh-loss coefficient per Table 6.
            %
            %   OUTPUTS:
            %       template - Optical density normalized to 1.0 at 400 nm (column vector)
            arguments
                obj
                wavelengths (:,1) double {validators.mustBeWavelengthVector}
                age (1,1) double {mustBePositive}
                options.FieldSize (1,1) double = NaN
            end

            rawDensity = obj.computeRawDensity(wavelengths, age, options.FieldSize);
            densityAt400 = obj.computeRawDensity(400, age, options.FieldSize);
            template = rawDensity / densityAt400;
        end

        function density = computeDensityAt400(obj, age, options)
            % COMPUTEDENSITYAT400  Total-media optical density at 400 nm.
            %
            %   density = obj.computeDensityAt400(age) evaluates Eq. 8 at
            %   400 nm for the specified age using the small-field d_RL.
            %   density = obj.computeDensityAt400(age, FieldSize=fs) uses
            %   the large-field d_RL when fs > 3 (Table 6); small-field
            %   otherwise. At age 32 the small-field value is ~1.92 OD and
            %   the large-field value is ~1.70 OD.
            %
            %   INPUTS:
            %       age       - Observer age in years (scalar)
            %
            %   OPTIONAL INPUTS (Name-Value arguments):
            %       FieldSize - Observer field size in degrees (scalar)
            %
            %   OUTPUTS:
            %       density - Total-media optical density at 400 nm (scalar)
            arguments
                obj
                age (1,1) double {mustBePositive}
                options.FieldSize (1,1) double = NaN
            end

            density = obj.computeRawDensity(400, age, options.FieldSize);
        end
    end

    methods (Access = private)
        function density = computeRawDensity(obj, wavelengths, age, fieldSize)
            % COMPUTERAWDENSITY  Evaluate Eq. 8 at the given wavelengths and age.
            %
            %   D_media(lambda, age, fieldSize) = sum_i d_i(age) * M_i(lambda) + d_neutral
            %   where d_i(age) = d_{i,0} + alpha_i * age^2 and d_RL,0
            %   depends on fieldSize per Table 6. This private helper
            %   takes fieldSize positionally because it is called by both
            %   computeTemplate and computeDensityAt400 with the already-
            %   resolved value from each method's options struct.
            %
            %   INPUTS:
            %       wavelengths - Wavelengths in nanometers (column vector)
            %       age         - Observer age in years (scalar)
            %       fieldSize   - Observer field size in degrees (scalar).
            %                     NaN selects the small-field default.
            %
            %   OUTPUTS:
            %       density - Total-media optical density (column vector)
            arguments
                obj
                wavelengths (:,1) double
                age (1,1) double
                fieldSize (1,1) double
            end

            ageSq = age^2;

            % Rayleigh loss: power-law in lambda. d_RL_0 selected by field size.
            if isnan(fieldSize) || fieldSize <= obj.RL_FIELD_SIZE_THRESHOLD
                d_RL_0 = obj.RL_D0_SMALL_FIELD;
            else
                d_RL_0 = obj.RL_D0_LARGE_FIELD;
            end
            d_RL = d_RL_0 + obj.RL_ALPHA * ageSq;
            M_RL = (400 ./ wavelengths).^4;

            % Tryptophan (age-invariant)
            M_TP = obj.TP_NORM * exp(-(obj.TP_WIDTH * (wavelengths - obj.TP_PEAK)).^2);

            % Lens Young
            d_LY = obj.LY_D0 + obj.LY_ALPHA * ageSq;
            M_LY = obj.LY_NORM * exp(-(obj.LY_WIDTH * (wavelengths - obj.LY_PEAK)).^2);

            % Lens Old UV
            d_LOUV = obj.LOUV_D0 + obj.LOUV_ALPHA * ageSq;
            M_LOUV = obj.LOUV_NORM * exp(-(obj.LOUV_WIDTH * (wavelengths - obj.LOUV_PEAK)).^2);

            % Lens Old
            d_LO = obj.LO_D0 + obj.LO_ALPHA * ageSq;
            M_LO = obj.LO_NORM * exp(-(obj.LO_WIDTH * (wavelengths - obj.LO_PEAK)).^2);

            density = d_RL .* M_RL ...
                    + obj.TP_D0 .* M_TP ...
                    + d_LY .* M_LY ...
                    + d_LOUV .* M_LOUV ...
                    + d_LO .* M_LO ...
                    + obj.D_NEUTRAL;
        end
    end
end

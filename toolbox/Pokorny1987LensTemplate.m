classdef Pokorny1987LensTemplate < LensTemplate
    % POKORNY1987LENSTEMPLATE  Age-dependent lens template from Pokorny et al. (1987).
    %
    %   This lens model partitions optical density into two components:
    %     TL1 - The portion affected by aging (scales with age factor)
    %     TL2 - The portion stable after age 20 (constant, only non-zero 400-450nm)
    %
    %   Total lens OD = TL1 * ageFactor + TL2
    %
    %   For ages 20-60: ageFactor = 1 + 0.02 * (age - 32)
    %   For ages > 60:  ageFactor = 1.56 + 0.0667 * (age - 60)
    %
    %   The template shape changes with age because TL2 contributes differently
    %   at short wavelengths (400-450nm) than at longer wavelengths where TL2=0.
    %
    %   Wavelength validity. The Pokorny tabulated values start at 400 nm.
    %   For shorter wavelengths the template flat-extrapolates the 400-nm
    %   value (TL1) and zero (TL2) -- a defensible boundary choice but
    %   not a measured spectrum. Users modeling 360-399 nm with this lens
    %   model should treat the result as constant-OD extrapolation, not
    %   a paper-validated curve. (StockmanRider2023 covers the full
    %   360-830 nm range; switch lens models if sub-400-nm precision
    %   matters.)
    %
    %   Reference:
    %       Pokorny, J., Smith, V. C., & Lutze, M. (1987). Aging of the human lens.
    %       Applied Optics, 26(8), 1437-1440.
    %
    %   See also: LensTemplate, StockmanRiderLensTemplate, IndividualCMF

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada
    %
    % This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    % Licensed under AGPL-3.0-or-later. See LICENSE file for details.
    % Repository: https://github.com/sfu-cs-vision-lab/Individual-CMFs

    properties (SetAccess = protected)
        Name = "Pokorny, Smith & Lutze (1987)"
        ShortName = "Pokorny1987"
    end

    properties (Constant)
        % SupportsAging  True; the Pokorny 1987 lens template's spectral
        % shape changes with age via the two-component (TL1 age-scaled,
        % TL2 age-stable) decomposition.
        SupportsAging = true
    end

    properties (Constant, Access = private)
        % All constants in this block derive from:
        %   Source: Pokorny, J., Smith, V.C. & Lutze, M. (1987). Aging of the
        %   human lens. Applied Optics, 26(8), 1437-1440.

        % Reference age for the standard observer (Stiles and Burch average).
        % At this age, the age factor for TL1 equals 1.0.
        REF_AGE = 32

        % Age threshold where aging rate accelerates. After age 60, the rate
        % of lens yellowing increases from 0.02/year to 0.0667/year.
        ACCELERATED_AGE = 60

        % Age coefficient for TL1 scaling (ages 20-60): 0.02 per year.
        % This corresponds to approximately 0.12 density units per decade at 400nm.
        AGE_COEFF_NORMAL = 0.02

        % Age coefficient for TL1 scaling (ages > 60): 0.0667 per year.
        % This corresponds to approximately 0.4 density units per decade at 400nm,
        % reflecting the accelerated lens yellowing observed in older observers.
        AGE_COEFF_ACCELERATED = 0.0667

        % Baseline factor at age 60 for the accelerated equation.
        % This equals 1 + 0.02 * (60 - 32) = 1.56, ensuring continuity at age 60.
        BASELINE_FACTOR_60 = 1.56

        % Tabulated wavelengths from Table I (nm). These span the visible range
        % where lens absorption is significant, from 400nm to 650nm.
        WAVELENGTHS = [400; 410; 420; 430; 440; 450; 460; 470; 480; 490; ...
                       500; 510; 520; 530; 540; 550; 560; 570; 580; 590; ...
                       600; 610; 620; 630; 640; 650]

        % TL1 values from Table I: the portion of lens optical density affected
        % by aging. These values are for a 32-year-old observer with small pupil.
        % TL1 decreases monotonically from 0.600 at 400nm to 0.000 at 650nm.
        TL1_VALUES = [0.600; 0.510; 0.433; 0.377; 0.327; 0.295; 0.267; 0.233; 0.207; 0.187; ...
                      0.167; 0.147; 0.133; 0.120; 0.107; 0.093; 0.080; 0.067; 0.053; 0.040; ...
                      0.033; 0.027; 0.020; 0.013; 0.007; 0.000]

        % TL2 values from Table I: the portion of lens optical density that is
        % stable after age 20. This component is non-zero only from 400-450nm
        % and represents the age-invariant chromophore absorption. The dashes
        % in Table I (indicating zero values) are represented as 0.000 here.
        TL2_VALUES = [1.000; 0.583; 0.300; 0.116; 0.033; 0.005; 0.000; 0.000; 0.000; 0.000; ...
                      0.000; 0.000; 0.000; 0.000; 0.000; 0.000; 0.000; 0.000; 0.000; 0.000; ...
                      0.000; 0.000; 0.000; 0.000; 0.000; 0.000]
    end

    methods
        function obj = Pokorny1987LensTemplate()
            % POKORNY1987LENSTEMPLATE  Construct a new Pokorny 1987 lens template.
        end

        function template = computeTemplate(obj, wavelengths, age, options)
            % COMPUTETEMPLATE  Returns optical density spectrum normalized to 1.0 at 400nm.
            %
            %   template = obj.computeTemplate(wavelengths, age) returns the lens
            %   optical density spectrum normalized such that the value at 400nm
            %   equals 1.0.
            %   template = obj.computeTemplate(wavelengths, age, FieldSize=fs)
            %   silently accepts field size for interface compatibility; Pokorny
            %   1987 does not model field-size dependence.
            %
            %   The template SHAPE changes with age because TL1 scales with age while
            %   TL2 remains constant. At short wavelengths where TL2 is significant,
            %   the relative contribution of the age-invariant component decreases
            %   as the observer ages.
            %
            %   INPUTS:
            %       wavelengths - Wavelengths in nanometers (column vector)
            %       age - Observer age in years (valid range: 20-80) (scalar)
            %
            %   OPTIONAL INPUTS (Name-Value arguments):
            %       FieldSize - Observer field size (ignored) (scalar)
            %
            %   OUTPUTS:
            %       template - Optical density normalized to 1.0 at 400nm (column vector)
            arguments
                obj
                wavelengths (:,1) double {validators.mustBeWavelengthVector}
                age (1,1) double {mustBePositive}
                % options.FieldSize is declared to satisfy the LensTemplate
                % abstract interface; Pokorny 1987 does not model
                % field-size dependence.
                options.FieldSize (1,1) double = NaN %#ok<INUSA>
            end

            rawDensity = obj.computeRawDensity(wavelengths, age);
            densityAt400 = obj.computeRawDensity(400, age);
            template = rawDensity / densityAt400;
        end

        function density = computeDensityAt400(obj, age, options)
            % COMPUTEDENSITYAT400  Returns the lens density at 400nm for given age.
            %
            %   density = obj.computeDensityAt400(age) returns the lens optical
            %   density at 400nm for an observer of the specified age.
            %   density = obj.computeDensityAt400(age, FieldSize=fs) silently
            %   accepts field size for interface compatibility; Pokorny 1987
            %   does not model field-size dependence.
            %
            %   For Pokorny1987, this value increases with age due to TL1 scaling.
            %   At age 32: density = TL1(0.600) * 1.0 + TL2(1.000) = 1.600
            %   At age 60: density = TL1(0.600) * 1.56 + TL2(1.000) = 1.936
            %
            %   INPUTS:
            %       age - Observer age in years (scalar)
            %
            %   OPTIONAL INPUTS (Name-Value arguments):
            %       FieldSize - Observer field size (ignored) (scalar)
            %
            %   OUTPUTS:
            %       density - Lens optical density at 400nm (scalar)
            arguments
                obj
                age (1,1) double {mustBePositive}
                % options.FieldSize is declared to satisfy the LensTemplate
                % abstract interface; Pokorny 1987 does not model
                % field-size dependence.
                options.FieldSize (1,1) double = NaN %#ok<INUSA>
            end

            density = obj.computeRawDensity(400, age);
        end
    end

    methods (Access = private)
        function density = computeRawDensity(obj, wavelengths, age)
            % COMPUTERAWDENSITY  Computes raw optical density before normalization.
            %
            %   density = obj.computeRawDensity(wavelengths, age) implements the
            %   equations from Table I of Pokorny et al. (1987):
            %
            %   For ages 20-60: TL = TL1 * [1 + 0.02 * (age - 32)] + TL2
            %   For ages > 60:  TL = TL1 * [1.56 + 0.0667 * (age - 60)] + TL2
            %
            %   INPUTS:
            %       wavelengths - Wavelengths in nanometers (column vector)
            %       age - Observer age in years (scalar)
            %
            %   OUTPUTS:
            %       density - Raw optical density values (column vector)
            arguments
                obj
                wavelengths (:,1) double {validators.mustBeWavelengthVector}
                age (1,1) double
            end

            tl1 = obj.interpolateTL1(wavelengths);
            tl2 = obj.interpolateTL2(wavelengths);
            ageFactor = obj.computeAgeFactor(age);

            density = tl1 * ageFactor + tl2;
        end

        function factor = computeAgeFactor(obj, age)
            % COMPUTEAGEFACTOR  Computes the age-dependent scaling factor for TL1.
            %
            %   factor = obj.computeAgeFactor(age) returns the multiplicative
            %   factor applied to TL1 values based on observer age.
            %
            %   The aging rate is approximately linear at 0.12 density units per decade
            %   at 400nm between ages 20-60, then accelerates to about 0.4 per decade
            %   after age 60. The equation ensures continuity at age 60.
            %
            %   INPUTS:
            %       age - Observer age in years (scalar)
            %
            %   OUTPUTS:
            %       factor - Age-dependent scaling factor for TL1 (scalar)
            %
            %   Source: Pokorny, Smith & Lutze (1987), Eqs. 3 and 4.
            arguments
                obj
                age (1,1) double
            end

            if age <= obj.ACCELERATED_AGE
                factor = 1 + obj.AGE_COEFF_NORMAL * (age - obj.REF_AGE);
            else
                factor = obj.BASELINE_FACTOR_60 + obj.AGE_COEFF_ACCELERATED * (age - obj.ACCELERATED_AGE);
            end
        end

        function tl1 = interpolateTL1(obj, wavelengths)
            % INTERPOLATETL1  Interpolates TL1 values for arbitrary wavelengths.
            %
            %   tl1 = obj.interpolateTL1(wavelengths) uses linear interpolation
            %   between the tabulated values from Table I. Returns 0 for wavelengths
            %   beyond 650nm where lens absorption is negligible. Extrapolates for
            %   wavelengths below 400nm using the 400nm value.
            %
            %   INPUTS:
            %       wavelengths - Wavelengths in nanometers (column vector)
            %
            %   OUTPUTS:
            %       tl1 - Interpolated TL1 values (column vector)
            arguments
                obj
                wavelengths (:,1) double {validators.mustBeWavelengthVector}
            end

            tl1 = interp1(obj.WAVELENGTHS, obj.TL1_VALUES, wavelengths, 'linear', 0);
            tl1(wavelengths < obj.WAVELENGTHS(1)) = obj.TL1_VALUES(1);
        end

        function tl2 = interpolateTL2(obj, wavelengths)
            % INTERPOLATETL2  Interpolates TL2 values for arbitrary wavelengths.
            %
            %   tl2 = obj.interpolateTL2(wavelengths) uses linear interpolation
            %   between the tabulated values from Table I. TL2 is only non-zero
            %   from 400-450nm; returns 0 elsewhere. Extrapolates for wavelengths
            %   below 400nm using the 400nm value (TL2 = 1.000), a flat
            %   plateau that overestimates lens density in the near-UV.
            %
            %   WARNING: Pokorny et al. (1987) only tabulate TL1 and TL2 from
            %   400 nm upward. Below 400 nm the model has no published basis;
            %   the flat-plateau extrapolation here is a sentinel only, not
            %   a fitted curve. Users needing accurate UV behaviour should
            %   select LensModel = "VanDeKraats2007" (modelled to ~ 300 nm)
            %   instead.
            %
            %   INPUTS:
            %       wavelengths - Wavelengths in nanometers (column vector)
            %
            %   OUTPUTS:
            %       tl2 - Interpolated TL2 values (column vector)
            arguments
                obj
                wavelengths (:,1) double {validators.mustBeWavelengthVector}
            end

            tl2 = interp1(obj.WAVELENGTHS, obj.TL2_VALUES, wavelengths, 'linear', 0);
            tl2(wavelengths < obj.WAVELENGTHS(1)) = obj.TL2_VALUES(1);
        end
    end
end

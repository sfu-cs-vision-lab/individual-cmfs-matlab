classdef StockmanRiderLensTemplate < LensTemplate
    % STOCKMANRIDERLENSTEMPLATE  Stockman & Rider (2023) lens optical density template.
    %
    %   This class implements the 9-term Fourier polynomial lens template from
    %   Stockman & Rider (2023). The template describes the spectral shape of
    %   lens optical density for a standard 32-year-old observer.
    %
    %   The template shape is AGE-INVARIANT. The Stockman & Rider model assumes
    %   that the spectral shape of lens absorption does not change with age;
    %   only the magnitude (density at 400nm) increases with lens yellowing.
    %   Age-dependent scaling is handled externally through the observer's
    %   LensDensity property.
    %
    %   The template is normalized such that the value at 400nm equals 1.0.
    %   To obtain absolute optical density, multiply by the observer's lens
    %   density at 400nm.
    %
    %   Reference:
    %       Stockman, A. & Rider, A.T. (2023). Formulae for generating standard
    %       and individual human cone spectral sensitivities. Color Research
    %       and Application, 48(6), 818-840. https://doi.org/10.1002/col.22879

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada
    %
    % This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    % Licensed under AGPL-3.0-or-later. See LICENSE file for details.
    % Repository: https://github.com/sfu-cs-vision-lab/Individual-CMFs

    properties (SetAccess = protected)
        Name = "Stockman & Rider (2023) Lens Template"
        ShortName = "StockmanRider2023"
    end

    properties (Constant)
        % SupportsAging  False; the Stockman & Rider lens template is an
        % age-invariant Fourier polynomial. Aging is handled externally by
        % scaling the template via the observer's LensDensity rather than
        % by changing the template SHAPE.
        SupportsAging = false
    end

    properties (Constant, Access = private)
        % Lens pigment Fourier coefficients. These coefficients define a
        % 9-term (8th-order) Fourier polynomial that describes the spectral
        % shape of lens absorption.
        % Coefficients are ordered as: [a0, a1, b1, a2, b2, ..., a8, b8, scale]
        % Source: Stockman & Rider (2023), Table 2.
        LENS_COEFFICIENTS = [ ...
            -313.9508632762; -70.3216819666; 585.4719725809; 471.5395862431; ...
             117.3539102044; 127.0168222865; -324.4700544731; -188.1638078982; ...
            -104.5512488013; -68.3078486904;  89.7815373733;  33.4498264952; ...
              35.2723638870;  13.6524086627;  -8.7568168893;  -1.2825766708; ...
              -3.5126531075;  -0.4477840959;   0.0428291365;   1.0091871745]

        % Normalization wavelength for lens template wavelength transformation.
        LENS_NORM_WL = 360.0

        % Normalization factor for lens template wavelength transformation.
        LENS_NORM_SCALE = 95.49296586

        % Upper wavelength limit for lens template validity.
        LENS_UPPER_LIMIT = 660

        % Pre-computed normalization factor: raw Fourier value at 400nm.
        % This is computed once and used to normalize all outputs to 1.0 at 400nm.
        % STD_LENS_DENSITY_400
        NORM_FACTOR_400 = 1.7649
    end

    methods
        function obj = StockmanRiderLensTemplate()
            % STOCKMANRIDERLENSTEMPLATE  Construct a new Stockman-Rider lens template.
        end

        function template = computeTemplate(obj, wavelengths, age, options)
            % COMPUTETEMPLATE  Compute lens optical density template normalized to 1.0 at 400nm.
            %
            %   template = obj.computeTemplate(wavelengths, age) returns the lens
            %   optical density spectrum with the value at 400nm normalized to 1.0.
            %   template = obj.computeTemplate(wavelengths, age, FieldSize=fs)
            %   silently accepts field size for interface compatibility; this
            %   template is field-size-invariant.
            %
            %   This template does NOT support aging (SupportsAging == false).
            %   The age parameter is accepted for interface compatibility but is
            %   ignored. The returned shape is always that of the standard 32yo.
            %
            %   INPUTS:
            %       wavelengths - Wavelengths in nanometers (column vector)
            %       age - Observer age (ignored) (scalar)
            %
            %   OPTIONAL INPUTS (Name-Value arguments):
            %       FieldSize - Observer field size (ignored) (scalar)
            %
            %   OUTPUTS:
            %       template - Optical density normalized to 1.0 at 400nm (column vector)
            arguments
                obj
                wavelengths (:,1) double {validators.mustBeWavelengthVector}
                % age and options.FieldSize are declared to satisfy the
                % LensTemplate abstract interface; SR23 is age- and
                % field-size-invariant, so neither is consumed below.
                age (1,1) double = 32 %#ok<INUSA>
                options.FieldSize (1,1) double = NaN %#ok<INUSA>
            end

            % Compute raw Fourier template (unnormalized)
            rawTemplate = obj.fourierLensTemplate(wavelengths);

            % Compute normalization factor: raw value at 400nm
            raw400 = obj.fourierLensTemplate(400);

            % Normalize so that value at 400nm = 1.0
            template = rawTemplate / raw400;
        end

        function density = computeDensityAt400(obj, age, options)
            % COMPUTEDENSITYAT400  Returns standard lens density at 400nm.
            %
            %   density = obj.computeDensityAt400(age) returns the standard lens
            %   optical density at 400nm for a 32-year-old observer.
            %   density = obj.computeDensityAt400(age, FieldSize=fs) silently
            %   accepts field size for interface compatibility; this template
            %   is field-size-invariant.
            %
            %   Since this template does not support aging, this method always
            %   returns STD_LENS_DENSITY_400 regardless of the age parameter.
            %   Age-dependent density scaling is handled externally via the
            %   IndividualCMF.recalcLensFromAge() method and the LensDensity property.
            %
            %   INPUTS:
            %       age - Observer age (ignored) (scalar)
            %
            %   OPTIONAL INPUTS (Name-Value arguments):
            %       FieldSize - Observer field size (ignored) (scalar)
            %
            %   OUTPUTS:
            %       density - Standard lens density at 400nm (1.7649) (scalar)
            arguments
                obj %#ok<INUSA>
                % age and options.FieldSize are declared to satisfy the
                % LensTemplate abstract interface; SR23 is age- and
                % field-size-invariant.
                age (1,1) double = 32 %#ok<INUSA>
                options.FieldSize (1,1) double = NaN %#ok<INUSA>
            end

            density = CIE170.STD_LENS_DENSITY_400;
        end
    end

    methods (Access = private)
        function template = fourierLensTemplate(obj, wavelengths)
            % FOURIERLENSTEMPLATE  Compute raw Fourier lens template (not normalized).
            %
            %   template = obj.fourierLensTemplate(wavelengths) evaluates the
            %   9-term Fourier polynomial from Stockman & Rider (2023) Table 2.
            %
            %   The template is valid for wavelengths up to 660nm. Values at
            %   longer wavelengths are zero.
            %
            %   INPUTS:
            %       wavelengths - Wavelengths in nanometers (column vector)
            %
            %   OUTPUTS:
            %       template - Raw optical density values (column vector)
            arguments
                obj
                wavelengths (:,1) double {validators.mustBeWavelengthVector}
            end

            x = (wavelengths - obj.LENS_NORM_WL) / obj.LENS_NORM_SCALE;
            template = zeros(size(wavelengths));

            limit = (obj.LENS_UPPER_LIMIT - obj.LENS_NORM_WL) / obj.LENS_NORM_SCALE;
            mask = (x <= limit);

            if ~any(mask)
                return
            end

            c = obj.LENS_COEFFICIENTS;
            val = obj.fourierSum(x(mask), c(1:19), 9);
            template(mask) = val * c(20);
        end

        function val = fourierSum(~, x, c, order)
            % FOURIERSUM  Evaluate 8th-order Fourier polynomial.
            %
            %   This implements Equation (1) from Stockman & Rider (2023):
            %     f(x) = a0 + sum_{k=1}^{n} [a_k*cos(kx) + b_k*sin(kx)]
            %
            %   Coefficients are ordered as [a0, a1, b1, a2, b2, ...].
            arguments
                ~
                x (:,1) double
                c (:,1) double
                order (1,1) double
            end

            val = c(1);
            k = 1:order;

            idxCos = 2 + (k - 1) * 2;
            idxSin = 3 + (k - 1) * 2;

            cCos = c(idxCos);
            cSin = c(idxSin);

            terms = cos(x * k) .* cCos' + sin(x * k) .* cSin';
            val = val + sum(terms, 2);
        end
    end
end

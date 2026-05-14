classdef StockmanRider2023MacularTemplate < MacularTemplate
    % STOCKMANRIDER2023MACULARTEMPLATE  Stockman & Rider (2023) macular template.
    %
    %   This class implements the 11-term (8th-order) Fourier polynomial
    %   macular pigment template from Stockman & Rider (2023), Table 2.
    %   The template describes the spectral shape of macular pigment
    %   optical density and was adopted by CIE 170-1:2006.
    %
    %   The template is normalized so that the value at 460 nm equals 1.0;
    %   the absolute density spectrum is obtained by multiplying by the
    %   observer's MacularDensity (peak OD at 460 nm). The template is
    %   defined over 375-550 nm and returns zero outside that range.
    %
    %   Reference:
    %       Stockman, A. & Rider, A.T. (2023). Formulae for generating standard
    %       and individual human cone spectral sensitivities. Color Research
    %       and Application, 48(6), 818-840. https://doi.org/10.1002/col.22879
    %       (Table 2.)
    %
    %       CIE 170-1:2006. Fundamental chromaticity diagram with
    %       physiological axes - Part 1. Vienna: CIE.

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada
    %
    % This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    % Licensed under AGPL-3.0-or-later. See LICENSE file for details.
    % Repository: https://github.com/sfu-cs-vision-lab/Individual-CMFs

    properties (SetAccess = protected)
        Name = "Stockman & Rider (2023) Macular Template"
        ShortName = "StockmanRider2023"
    end

    properties (Constant)
        % Macular pigment Fourier coefficients (Stockman & Rider 2023, Table 2).
        % 11-term (8th-order) Fourier polynomial in normalized wavelength
        %     x = (lambda - 375) / 55.70423008
        % Coefficients ordered as [a0, a1, b1, ..., a11, b11, scale].
        % The raw polynomial output peaks at CIE170.STD_2DEG_MACULAR_DENSITY
        % (0.350 OD) near 460 nm; computeTemplate divides through that peak
        % to return a unit-peak spectrum.
        MACULAR_COEFFICIENTS = [ ...
            3712.2037792986;  374.1811575175; -7007.6989637831; -5887.2857515364; ...
            -633.0475233043; -716.0429039473;  4386.8811254914;  2882.1092658881; ...
             638.1347550701;  468.4980700497; -1653.7567388120;  -817.1240899995; ...
            -286.4038978705; -144.7996457395;   340.3364828167;   115.5652804221; ...
              59.1650826447;   18.6678197694;   -30.2344535413;    -5.4683753172; ...
              -4.1335064207;   -0.5043959566;     0.5094171266;     1.0050048550]

        % Lower wavelength anchor for the polynomial change-of-variable.
        MACULAR_NORM_WL = 375.0

        % Wavelength scaling for the polynomial change-of-variable.
        MACULAR_NORM_SCALE = 55.70423008

        % Upper wavelength limit; macular OD is taken as zero above this.
        MACULAR_UPPER_LIMIT = 550

        % Pre-computed normalization factor: the CIE 170-1:2006 nominal peak
        % macular OD at 460 nm. Dividing by 0.35 produces a unit-peak
        % template. Note: the raw Fourier polynomial actually evaluates to
        % 0.34999999993832 at 460 nm (~1.8e-10 below 0.35) due to rounding
        % in the coefficient table, so computeTemplate(460) returns
        % 0.9999999998 rather than exactly 1.0. This is a property of the
        % paper's rounded coefficients; tests should use a relaxed
        % tolerance for the unit-peak property.
        NORM_FACTOR_460 = 0.35
    end

    methods
        function obj = StockmanRider2023MacularTemplate()
            % STOCKMANRIDER2023MACULARTEMPLATE  Construct the template.
        end

        function template = computeTemplate(obj, wavelengths)
            % COMPUTETEMPLATE  Macular OD spectrum normalized to 1.0 at 460 nm.
            %
            %   template = obj.computeTemplate(wavelengths) returns the
            %   Stockman & Rider (2023) macular pigment optical density
            %   spectrum, divided by its peak so the value at 460 nm
            %   equals 1.0. Wavelengths outside 375-550 nm return zero.
            %
            %   INPUTS:
            %       wavelengths - Wavelengths in nanometers (column vector)
            %
            %   OUTPUTS:
            %       template - OD normalized to 1.0 at 460 nm (column vector)
            arguments
                obj
                wavelengths (:,1) double {validators.mustBeWavelengthVector}
            end

            absSpectrum = obj.fourierMacularTemplate(wavelengths);
            template = absSpectrum / obj.NORM_FACTOR_460;
        end
    end

    methods (Access = private)
        function template = fourierMacularTemplate(obj, wavelengths)
            % FOURIERMACULARTEMPLATE  Raw absolute Fourier macular template.
            %
            %   Evaluates the Stockman & Rider (2023) Table 2 Fourier
            %   polynomial. Output is the absolute CIE 2-deg standard
            %   density curve peaking at 0.35 near 460 nm.
            arguments
                obj
                wavelengths (:,1) double
            end

            x = (wavelengths - obj.MACULAR_NORM_WL) / obj.MACULAR_NORM_SCALE;
            template = zeros(size(wavelengths));

            limit = (obj.MACULAR_UPPER_LIMIT - obj.MACULAR_NORM_WL) / ...
                     obj.MACULAR_NORM_SCALE;
            mask = (x >= 0) & (x <= limit);

            if ~any(mask)
                return
            end

            c = obj.MACULAR_COEFFICIENTS;
            val = obj.fourierSum(x(mask), c(1:23), 11);
            template(mask) = val * c(24);
        end

        function val = fourierSum(~, x, c, order)
            % FOURIERSUM  Evaluate Fourier polynomial.
            %
            %   Implements Eq. 1 from Stockman & Rider (2023):
            %     f(x) = a0 + sum_{k=1}^{n} [a_k*cos(kx) + b_k*sin(kx)]
            %
            %   Coefficients ordered as [a0, a1, b1, a2, b2, ...].
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

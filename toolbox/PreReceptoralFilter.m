classdef PreReceptoralFilter
    % PRERECEPTORALFILTER  Optical filtering before light reaches photoreceptors.
    %
    %   This value class models the pre-receptoral filtering that occurs in
    %   the human eye before light reaches the cone photoreceptors.
    %
    %   Macular pigment: Lutein and zeaxanthin concentrated in the fovea
    %   absorb blue light (peak around 460nm). This pigment protects the
    %   foveal photoreceptors from photo-oxidative damage. Macular pigment
    %   density varies substantially between individuals and decreases with
    %   eccentricity from the fovea.
    %
    %   NOTE: Lens pigment spectral computation has been moved to the LensTemplate
    %   class hierarchy. The Type="lens" option is retained for backward compatibility
    %   with ObserverParameters, but getDensitySpectrum will error if called on
    %   a lens filter. Use IndividualCMF.getLensDensitySpectrum() for lens spectra.
    %
    %   PreReceptoralFilter Properties:
    %       Type    - Filter type ("lens" or "macular").
    %       Density - Scaling factor for the optical density spectrum.
    %       Age     - Observer age in years (for backward compatibility).
    %
    %   PreReceptoralFilter Methods:
    %       getDensitySpectrum - Compute optical density spectrum (macular only).
    %       getTransmission    - Compute transmission spectrum (10^-density).
    %
    %   PreReceptoralFilter Static Methods:
    %       macularTemplate            - Normalized macular pigment density template.
    %       macularDensityAtFieldSize  - Peak macular OD via Moreland-Alexander formula.
    %       macularDensityCIEStandard  - Peak macular OD using CIE standard tables
    %                                    (with Moreland-Alexander fallback).
    %
    %   Syntax:
    %       filter = PreReceptoralFilter()
    %       filter = PreReceptoralFilter(Type="macular")
    %       filter = PreReceptoralFilter(Type="macular", Density=0.35)
    %
    %   EXAMPLE:
    %       wl = (390:550)';
    %       macFilter = PreReceptoralFilter(Type="macular", Density=0.35);
    %       transmission = macFilter.getTransmission(wl);
    %       plot(wl, transmission);
    %
    %   References:
    %       CIE 170-1:2006. Fundamental chromaticity diagram with physiological
    %       axes - Part 1. Vienna: CIE.
    %
    %       Stockman, A. & Rider, A.T. (2023). Formulae for generating standard
    %       and individual human cone spectral sensitivity functions. Color
    %       Research and Application, 48(6), 818-840.

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada
    %
    % This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    % Licensed under AGPL-3.0-or-later. See LICENSE file for details.
    % Repository: https://github.com/sfu-cs-vision-lab/Individual-CMFs

    properties
        % Filter type specifying which pre-receptoral filter to model.
        % "macular" models the macular pigment absorption concentrated
        % in the blue region of the spectrum.
        % "lens" is retained for backward compatibility in ObserverParameters
        % but getDensitySpectrum will error if called with Type="lens".
        % For lens spectra, use IndividualCMF.getLensDensitySpectrum().
        Type (1,1) string {mustBeMember(Type, ["lens", "macular"])} = "macular"

        % Scaling factor for the optical density spectrum. For macular filters,
        % this represents the peak density at 460nm. For lens filters,
        % this represents a relative density scaling factor.
        Density (1,1) double {mustBeNonnegative, mustBeFinite} = 1.0

        % Observer age in years. Retained for backward compatibility with
        % ObserverParameters. This property is only used for lens filter
        % storage and has no effect on macular filters.
        Age (1,1) double {mustBePositive} = 32
    end

    % Macular Fourier coefficients now live on StockmanRider2023MacularTemplate
    % (the strategy class is the single source of truth). PreReceptoralFilter's
    % static macularTemplate method delegates there.

    properties (Constant, Access = private)
        % Moreland & Alexander (1997) field-size formula for peak macular
        % optical density (at 460 nm):
        %   D_mac(fieldSize) = MORELAND_ALEX_PEAK_OD
        %                      * exp(-fieldSize / MORELAND_ALEX_DECAY_DEG)
        %
        % Moreland, J. D. & Alexander, E. C. (1997). Effect of macular
        % pigment on colour matching with field sizes in the 1 to 10 deg
        % range. Documenta Ophthalmologica Proceedings Series, 59, 363-368.
        % doi:10.1007/978-94-011-5408-6_39
        MORELAND_ALEX_PEAK_OD   = 0.485
        MORELAND_ALEX_DECAY_DEG = 6.132
    end

    methods
        function obj = PreReceptoralFilter(options)
            % PRERECEPTORALFILTER  Construct a pre-receptoral filter.
            %
            %   filter = PreReceptoralFilter() creates a macular filter with
            %   default density (1.0).
            %
            %   filter = PreReceptoralFilter(Name, Value) creates a filter
            %   with specified properties.
            %
            %   NOTE: For lens spectra computation, use IndividualCMF.getLensDensitySpectrum()
            %   or LensTemplate classes. Type="lens" is retained for backward
            %   compatibility with ObserverParameters but getDensitySpectrum will error
            %   if called on a lens filter.
            %
            %   OPTIONAL INPUTS (Name-Value arguments):
            %       Type    - "lens" or "macular" (string) Default: "macular"
            %       Density - Density scaling factor (double) Default: 1.0
            %       Age     - Observer age in years (double) Default: 32
            %
            %   OUTPUTS:
            %       filter - New filter object (PreReceptoralFilter)
            arguments
                options.Type (1,1) string {mustBeMember(options.Type, ["lens", "macular"])} = "macular"
                options.Density (1,1) double {mustBeNonnegative, mustBeFinite} = 1.0
                options.Age (1,1) double {mustBePositive} = 32
            end

            obj.Type = options.Type;
            obj.Density = options.Density;
            obj.Age = options.Age;
        end

        function spectrum = getDensitySpectrum(obj, wavelengths)
            % GETDENSITYSPECTRUM  Compute optical density spectrum.
            %
            %   spectrum = filter.getDensitySpectrum(wavelengths) returns the
            %   optical density at each wavelength, scaled by the filter's
            %   Density property.
            %
            %   The optical density spectrum represents the log10 ratio of
            %   incident to transmitted light intensity. Higher values indicate
            %   greater absorption at that wavelength.
            %
            %   NOTE: For lens filters, this method will error. Use
            %   IndividualCMF.getLensDensitySpectrum() for lens spectra.
            %
            %   INPUTS:
            %       wavelengths - Wavelengths in nanometers (vector)
            %
            %   OUTPUTS:
            %       spectrum - Optical density at each wavelength (vector)
            arguments
                obj
                wavelengths (:,1) double {validators.mustBeWavelengthVector}
            end

            if obj.Type == "lens"
                error('PreReceptoralFilter:UseLensTemplate', ...
                    'Lens density spectrum should be computed via LensTemplate classes. See IndividualCMF.getLensDensitySpectrum().');
            end

            template = PreReceptoralFilter.macularTemplate(wavelengths);
            % macularTemplate is an absolute Stockman-Rider density curve
            % whose peak is CIE170.STD_2DEG_MACULAR_DENSITY (0.350 OD at 460
            % nm, the CIE 2-deg standard). Scale so the user's Density (also
            % expressed as a peak OD at 460 nm) becomes the actual peak of
            % the returned spectrum.
            spectrum = (obj.Density / CIE170.STD_2DEG_MACULAR_DENSITY) * template;
        end

        function transmission = getTransmission(obj, wavelengths)
            % GETTRANSMISSION  Compute transmission spectrum.
            %
            %   transmission = filter.getTransmission(wavelengths) returns the
            %   fractional transmission at each wavelength. Transmission is
            %   calculated as 10^(-density) following the Beer-Lambert law.
            %
            %   Transmission values range from 0 (complete absorption) to 1
            %   (complete transmission). Values near 1 indicate wavelengths
            %   where the filter has minimal effect.
            %
            %   INPUTS:
            %       wavelengths - Wavelengths in nanometers (vector)
            %
            %   OUTPUTS:
            %       transmission - Transmission fraction (0 to 1) (vector)
            arguments
                obj
                wavelengths (:,1) double {validators.mustBeWavelengthVector}
            end

            density = obj.getDensitySpectrum(wavelengths);
            transmission = 10.^(-density);
        end
    end

    methods (Static)
        function template = macularTemplate(wavelengths)
            % MACULARTEMPLATE  Absolute Stockman & Rider (2023) macular template.
            %
            %   template = PreReceptoralFilter.macularTemplate(wavelengths)
            %   returns the macular pigment optical density spectrum from
            %   Stockman & Rider (2023), Table 2. The output is the
            %   absolute CIE 2-deg standard density: it peaks at
            %   CIE170.STD_2DEG_MACULAR_DENSITY (0.350 OD) near 460 nm and
            %   is valid for 375-550 nm; outside that range it returns zero.
            %
            %   This static method now delegates to the
            %   StockmanRider2023MacularTemplate strategy class to share
            %   the polynomial implementation with the MacularTemplate
            %   hierarchy. Callers that want the unit-peak (normalized to
            %   1.0 at 460 nm) template should construct a
            %   StockmanRider2023MacularTemplate directly. The absolute-
            %   peak convention is preserved here because existing callers
            %   (CMFPlotter, tests, getDensitySpectrum) depend on it.
            %
            %   To rescale for a different field size or for an individual
            %   observer with a different peak macular density D, use
            %       D / CIE170.STD_2DEG_MACULAR_DENSITY * macularTemplate(wl)
            %   (or call PreReceptoralFilter(Density=D).getDensitySpectrum,
            %   which performs that rescaling for you).
            %
            %   INPUTS:
            %       wavelengths - Wavelengths in nanometers (vector)
            %
            %   OUTPUTS:
            %       template - Absolute macular density spectrum (vector)
            arguments
                wavelengths (:,1) double {validators.mustBeWavelengthVector}
            end

            mt = StockmanRider2023MacularTemplate();
            template = mt.computeTemplate(wavelengths) * CIE170.STD_2DEG_MACULAR_DENSITY;
        end

        function D_mac = macularDensityAtFieldSize(fieldSize)
            % MACULARDENSITYATFIELDSIZE  Peak macular OD as a function of field size.
            %
            %   D_mac = PreReceptoralFilter.macularDensityAtFieldSize(fieldSize)
            %   returns the peak macular pigment optical density (at 460 nm) for
            %   an observer with the specified field-of-view diameter, using the
            %   continuous formula
            %
            %       D_mac = 0.485 * exp(-fieldSize / 6.132)
            %
            %   This is the formula used by the IndividualCMF
            %   MacularDensityAlgorithm="MorelandAlexander" mode and was
            %   adopted by CIE 170-1:2006 (CIEPO06) for non-standard field
            %   sizes. Reference values: 2-deg ~ 0.350, 10-deg ~ 0.095.
            %
            %   INPUTS:
            %       fieldSize - Visual field diameter in degrees (scalar)
            %
            %   OUTPUTS:
            %       D_mac - Peak macular optical density at 460 nm (scalar)
            %
            %   Reference:
            %       Moreland, J. D. & Alexander, E. C. (1997). Effect of macular
            %       pigment on colour matching with field sizes in the 1 to 10
            %       deg range. In C.R. Cavonius (Ed.), Colour Vision Deficiencies
            %       XIII, Documenta Ophthalmologica Proceedings Series, Vol. 59,
            %       pp. 363-368. Springer, Dordrecht.
            %       doi:10.1007/978-94-011-5408-6_39
            arguments
                fieldSize (1,1) double {mustBePositive}
            end
            D_mac = PreReceptoralFilter.MORELAND_ALEX_PEAK_OD * ...
                exp(-fieldSize / PreReceptoralFilter.MORELAND_ALEX_DECAY_DEG);
        end

        function D_mac = macularDensityCIEStandard(fieldSize)
            % MACULARDENSITYCIESTANDARD  Peak macular OD using CIE standard tables.
            %
            %   D_mac = PreReceptoralFilter.macularDensityCIEStandard(fieldSize)
            %   returns the peak macular pigment optical density (at 460 nm)
            %   using the CIE 170-1:2006 tabulated values for the standard
            %   2-deg and 10-deg observers, falling back to the Moreland-
            %   Alexander formula (via macularDensityAtFieldSize) for any
            %   other field size.
            %
            %   This implements the IndividualCMF
            %   MacularDensityAlgorithm="CIE170" mode: prefer the
            %   published standard table where it applies, otherwise the
            %   continuous formula. Use macularDensityAtFieldSize directly
            %   if you want the formula at all field sizes.
            %
            %   INPUTS:
            %       fieldSize - Visual field diameter in degrees (scalar)
            %
            %   OUTPUTS:
            %       D_mac - Peak macular optical density at 460 nm (scalar)
            %
            %   See also: macularDensityAtFieldSize
            arguments
                fieldSize (1,1) double {mustBePositive}
            end
            switch fieldSize
                case 2
                    D_mac = CIE170.STD_2DEG_MACULAR_DENSITY;
                case 10
                    D_mac = CIE170.STD_10DEG_MACULAR_DENSITY;
                otherwise
                    D_mac = PreReceptoralFilter.macularDensityAtFieldSize(fieldSize);
            end
        end
    end
end

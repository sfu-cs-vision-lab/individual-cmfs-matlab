classdef PhotopigmentParameters
    % PHOTOPIGMENTPARAMETERS  Parameters describing cone photopigment properties.
    %
    %   This value class holds the optical properties of a cone photopigment,
    %   including the peak axial optical density and any shift in peak
    %   wavelength from the standard template.
    %
    %   Photopigment optical density determines the self-screening effect,
    %   which affects how light is absorbed as it passes through the outer
    %   segment. Higher densities result in broader, flatter absorption spectra.
    %   Standard values come from CIE 170-1:2006 and Stockman & Sharpe (2000).
    %
    %   The lambda-max shift parameter allows modeling of polymorphisms in
    %   opsin genes that alter the peak wavelength of the photopigment
    %   absorption spectrum.
    %
    %   PhotopigmentParameters Properties:
    %       OpticalDensity - Peak axial optical density (dimensionless, 0.3-0.5 typical).
    %       LambdaMaxShift - Shift in peak wavelength from standard template (nm).
    %
    %   PhotopigmentParameters Constant Properties:
    %       STD_L_OPTICAL_DENSITY - Standard L-cone optical density (0.38).
    %       STD_M_OPTICAL_DENSITY - Standard M-cone optical density (0.38).
    %       STD_S_OPTICAL_DENSITY - Standard S-cone optical density (0.30).
    %
    %   PhotopigmentParameters Methods:
    %       PhotopigmentParameters - Constructor with optional Name=Value arguments.
    %
    %   PhotopigmentParameters Static Methods:
    %       standardL              - Create parameters for standard L-cone.
    %       standardM              - Create parameters for standard M-cone.
    %       standardS              - Create parameters for standard S-cone.
    %       densitiesAtFieldSize   - L/M/S cone ODs via Pokorny-Smith formula.
    %       densitiesCIEStandard   - L/M/S cone ODs using CIE standard tables
    %                                (with Pokorny-Smith fallback).
    %
    %   Syntax:
    %       params = PhotopigmentParameters()
    %       params = PhotopigmentParameters(OpticalDensity=0.45)
    %       params = PhotopigmentParameters(OpticalDensity=0.38, LambdaMaxShift=-2)
    %       params = PhotopigmentParameters.standardL()
    %       params = PhotopigmentParameters.standardS()
    %
    %   EXAMPLE:
    %       lParams = PhotopigmentParameters.standardL();
    %       customParams = PhotopigmentParameters(OpticalDensity=0.45, LambdaMaxShift=-3);
    %
    %   References:
    %       CIE 170-1:2006. Fundamental chromaticity diagram with physiological
    %       axes - Part 1. Vienna: CIE.
    %
    %       Stockman, A. & Sharpe, L.T. (2000). The spectral sensitivities of
    %       the middle- and long-wavelength-sensitive cones derived from
    %       measurements in observers of known genotype. Vision Research,
    %       40(13), 1711-1737.

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada
    %
    % This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    % Licensed under AGPL-3.0-or-later. See LICENSE file for details.
    % Repository: https://github.com/sfu-cs-vision-lab/Individual-CMFs

    properties
        % Peak axial optical density of the photopigment in the outer segment.
        % This dimensionless quantity determines the degree of self-screening:
        % higher values produce broader, flatter absorption spectra. Typical
        % values range from 0.3 to 0.5 depending on cone type and field size.
        OpticalDensity (1,1) double {mustBeNonnegative, mustBeFinite} = 0.38

        % Shift in peak wavelength (lambda-max) from the standard template in
        % nanometers. Positive values shift the spectrum toward longer wavelengths
        % (red shift), negative values shift toward shorter wavelengths (blue shift).
        % Used to model opsin gene polymorphisms that alter spectral tuning.
        LambdaMaxShift (1,1) double {mustBeFinite} = 0
    end

    properties (Constant)
        % Standard 10-degree cone optical densities. Aliases that route
        % through CIE170, the canonical leaf for CIE 170-1:2006 Table 6.5.1
        % values, so a future revision of the standard is a one-place edit.
        STD_L_OPTICAL_DENSITY = CIE170.STD_10DEG_L_OPTICAL_DENSITY
        STD_M_OPTICAL_DENSITY = CIE170.STD_10DEG_M_OPTICAL_DENSITY
        STD_S_OPTICAL_DENSITY = CIE170.STD_10DEG_S_OPTICAL_DENSITY
    end

    properties (Constant, Access = private)
        % Pokorny & Smith (1976) field-size formulae for cone photopigment
        % optical density. Each formula is a 10-deg baseline plus an
        % exponential decay with field size:
        %   D_LM(fs) = STD_L_OPTICAL_DENSITY + POKORNY_LM_AMPLITUDE
        %                                   * exp(-fs / POKORNY_DECAY_DEG)
        %   D_S (fs) = STD_S_OPTICAL_DENSITY + POKORNY_S_AMPLITUDE
        %                                   * exp(-fs / POKORNY_DECAY_DEG)
        %
        % Pokorny, J. & Smith, V. C. (1976). Effect of field size on
        % red-green color mixture equations. Journal of the Optical
        % Society of America, 66(7), 705-708.
        POKORNY_LM_AMPLITUDE = 0.54
        POKORNY_S_AMPLITUDE  = 0.45
        POKORNY_DECAY_DEG    = 1.333
    end

    methods
        function obj = PhotopigmentParameters(options)
            % PHOTOPIGMENTPARAMETERS  Construct photopigment parameters.
            %
            %   params = PhotopigmentParameters() creates parameters with default
            %   values (OpticalDensity=0.38, LambdaMaxShift=0).
            %
            %   params = PhotopigmentParameters(Name, Value) creates parameters
            %   with specified values.
            %
            %   OPTIONAL INPUTS (Name-Value arguments):
            %       OpticalDensity - Peak axial optical density (double) Default: 0.38
            %       LambdaMaxShift - Wavelength shift in nm (double) Default: 0
            %
            %   OUTPUTS:
            %       params - New parameter object (PhotopigmentParameters)
            arguments
                options.OpticalDensity (1,1) double {mustBeNonnegative, mustBeFinite} = 0.38
                options.LambdaMaxShift (1,1) double {mustBeFinite} = 0
            end

            obj.OpticalDensity = options.OpticalDensity;
            obj.LambdaMaxShift = options.LambdaMaxShift;
        end
    end

    methods (Static)
        function params = standardL()
            % STANDARDL  Create parameters for the standard L-cone.
            %
            %   params = PhotopigmentParameters.standardL() returns a
            %   PhotopigmentParameters object configured with the CIE 170-1:2006
            %   standard values for L-cones (10-degree observer): optical density
            %   of 0.38 and zero wavelength shift.
            %
            %   OUTPUTS:
            %       params - Standard L-cone parameters (PhotopigmentParameters)
            params = PhotopigmentParameters( ...
                OpticalDensity=PhotopigmentParameters.STD_L_OPTICAL_DENSITY, ...
                LambdaMaxShift=0);
        end

        function params = standardM()
            % STANDARDM  Create parameters for the standard M-cone.
            %
            %   params = PhotopigmentParameters.standardM() returns a
            %   PhotopigmentParameters object configured with the CIE 170-1:2006
            %   standard values for M-cones (10-degree observer): optical density
            %   of 0.38 and zero wavelength shift.
            %
            %   OUTPUTS:
            %       params - Standard M-cone parameters (PhotopigmentParameters)
            params = PhotopigmentParameters( ...
                OpticalDensity=PhotopigmentParameters.STD_M_OPTICAL_DENSITY, ...
                LambdaMaxShift=0);
        end

        function params = standardS()
            % STANDARDS  Create parameters for the standard S-cone.
            %
            %   params = PhotopigmentParameters.standardS() returns a
            %   PhotopigmentParameters object configured with the CIE 170-1:2006
            %   standard values for S-cones (10-degree observer): optical density
            %   of 0.30 and zero wavelength shift. S-cones have lower optical
            %   density than L and M cones due to their shorter outer segments.
            %
            %   OUTPUTS:
            %       params - Standard S-cone parameters (PhotopigmentParameters)
            params = PhotopigmentParameters( ...
                OpticalDensity=PhotopigmentParameters.STD_S_OPTICAL_DENSITY, ...
                LambdaMaxShift=0);
        end

        function [Lod, Mod, Sod] = densitiesAtFieldSize(fieldSize)
            % DENSITIESATFIELDSIZE  Cone optical densities as a function of field size.
            %
            %   [Lod, Mod, Sod] = PhotopigmentParameters.densitiesAtFieldSize(fieldSize)
            %   returns the L, M, and S cone peak photopigment optical densities
            %   for an observer with the specified field-of-view diameter, using
            %   the continuous formulas
            %
            %       D_LM = 0.38 + 0.54 * exp(-fieldSize / 1.333)
            %       D_S  = 0.30 + 0.45 * exp(-fieldSize / 1.333)
            %
            %   This is the formula used by the IndividualCMF
            %   PhotopigmentDensityAlgorithm="PokornySmith" mode. Reference
            %   values: 2-deg -> L/M ~ 0.50, S ~ 0.40; 10-deg -> L/M ~ 0.38,
            %   S ~ 0.30.
            %
            %   INPUTS:
            %       fieldSize - Visual field diameter in degrees (scalar)
            %
            %   OUTPUTS:
            %       Lod - L-cone peak optical density (scalar)
            %       Mod - M-cone peak optical density (scalar; equal to Lod)
            %       Sod - S-cone peak optical density (scalar)
            %
            %   Reference:
            %       Pokorny, J. & Smith, V. C. (1976). Effect of field size on
            %       red-green color mixture equations. Journal of the Optical
            %       Society of America, 66(7), 705-708.
            arguments
                fieldSize (1,1) double {mustBePositive}
            end
            Lod = PhotopigmentParameters.STD_L_OPTICAL_DENSITY + ...
                PhotopigmentParameters.POKORNY_LM_AMPLITUDE * ...
                exp(-fieldSize / PhotopigmentParameters.POKORNY_DECAY_DEG);
            Mod = Lod;
            Sod = PhotopigmentParameters.STD_S_OPTICAL_DENSITY + ...
                PhotopigmentParameters.POKORNY_S_AMPLITUDE * ...
                exp(-fieldSize / PhotopigmentParameters.POKORNY_DECAY_DEG);
        end

        function [Lod, Mod, Sod] = densitiesCIEStandard(fieldSize)
            % DENSITIESCIESTANDARD  Cone optical densities using CIE standard tables.
            %
            %   [Lod, Mod, Sod] = PhotopigmentParameters.densitiesCIEStandard(fieldSize)
            %   returns the L/M/S cone peak photopigment optical densities
            %   using the CIE 170-1:2006 tabulated values for the standard
            %   2-deg and 10-deg observers, falling back to the Pokorny-
            %   Smith formula (via densitiesAtFieldSize) for any other
            %   field size.
            %
            %   This implements the IndividualCMF
            %   PhotopigmentDensityAlgorithm="CIE170" mode: prefer
            %   the published standard table where it applies, otherwise
            %   the continuous formula. Use densitiesAtFieldSize directly
            %   if you want the formula at all field sizes.
            %
            %   INPUTS:
            %       fieldSize - Visual field diameter in degrees (scalar)
            %
            %   OUTPUTS:
            %       Lod - L-cone peak optical density (scalar)
            %       Mod - M-cone peak optical density (scalar)
            %       Sod - S-cone peak optical density (scalar)
            %
            %   See also: densitiesAtFieldSize
            arguments
                fieldSize (1,1) double {mustBePositive}
            end
            switch fieldSize
                case 2
                    Lod = CIE170.STD_2DEG_L_OPTICAL_DENSITY;
                    Mod = CIE170.STD_2DEG_M_OPTICAL_DENSITY;
                    Sod = CIE170.STD_2DEG_S_OPTICAL_DENSITY;
                case 10
                    Lod = CIE170.STD_10DEG_L_OPTICAL_DENSITY;
                    Mod = CIE170.STD_10DEG_M_OPTICAL_DENSITY;
                    Sod = CIE170.STD_10DEG_S_OPTICAL_DENSITY;
                otherwise
                    [Lod, Mod, Sod] = PhotopigmentParameters.densitiesAtFieldSize(fieldSize);
            end
        end
    end
end

classdef (Abstract) LensTemplate < handle
    % LENSTEMPLATE  Abstract base class for lens optical density templates.
    %
    %   This class defines the interface for lens template strategies used
    %   in the IndividualCMF model. Subclasses implement specific template
    %   models such as the Stockman & Rider (2023) Fourier template.
    %
    %   The lens optical density template describes the spectral shape of
    %   lens absorption. The template is normalized such that the value at
    %   400nm equals 1.0. To obtain absolute optical density, multiply by
    %   the observer's lens density at 400nm.
    %
    %   LensTemplate Abstract Properties:
    %       Name      - Full descriptive name of the template model.
    %       ShortName - Short identifier for the template model.
    %
    %   LensTemplate Abstract Constant Properties:
    %       SupportsAging - True if the template SHAPE changes with age.
    %
    %   LensTemplate Abstract Methods:
    %       computeTemplate      - Returns optical density spectrum normalized to 1.0 at 400nm.
    %       computeDensityAt400  - Returns the lens density at 400nm for given age.
    %
    %   References:
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

    properties (Abstract, SetAccess = protected)
        % Name  Full descriptive name of the template model.
        Name

        % ShortName  Short identifier (e.g., "StockmanRider2023").
        ShortName
    end

    properties (Abstract, Constant)
        % SupportsAging  True if the template SHAPE changes with age.
        %
        %   For age-invariant templates the absorbance shape is fixed and only
        %   the magnitude (density at 400nm) varies with age, handled
        %   externally via the observer's LensDensity. For age-dependent
        %   templates the shape itself depends on age. Concrete subclasses
        %   declare this constant so callers don't dispatch on type.
        SupportsAging (1,1) logical
    end

    methods (Abstract)
        % computeTemplate  Returns optical density spectrum normalized to 1.0 at 400nm.
        %
        %   template = obj.computeTemplate(wavelengths, age) returns the lens
        %   optical density spectrum normalized such that the value at 400nm
        %   equals 1.0. This represents the spectral SHAPE of lens absorption.
        %   template = obj.computeTemplate(wavelengths, age, FieldSize=fs)
        %   passes the observer's field size in degrees to templates that
        %   depend on it (van de Kraats & van Norren 2007 has separate
        %   Rayleigh-loss coefficients for <=3 deg vs >3 deg fields).
        %   Templates that do not use field size silently accept the option.
        %
        %   For age-invariant templates (SupportsAging == false), the age
        %   parameter is ignored and the shape is always that of the standard
        %   32-year-old observer.
        %
        %   For age-dependent templates (SupportsAging == true), the shape
        %   may change with age to model changes in lens chromophore composition.
        %
        %   INPUTS:
        %       wavelengths - Wavelengths in nanometers (column vector)
        %       age - Observer age in years (scalar)
        %
        %   OPTIONAL INPUTS (Name-Value arguments):
        %       FieldSize - Observer field size in degrees (scalar). Only
        %                   consumed by lens templates that model field-size-
        %                   dependent scattering.
        %
        %   OUTPUTS:
        %       template - Optical density normalized to 1.0 at 400nm (column vector)
        template = computeTemplate(obj, wavelengths, age, options)

        % computeDensityAt400  Returns the lens density at 400nm for given age.
        %
        %   density = obj.computeDensityAt400(age) returns the lens optical
        %   density at 400nm for an observer of the specified age.
        %   density = obj.computeDensityAt400(age, FieldSize=fs) passes the
        %   observer's field size in degrees for templates that depend on
        %   it (van de Kraats & van Norren 2007); other templates ignore it.
        %
        %   For age-invariant templates, this returns CIE170.STD_LENS_DENSITY_400
        %   regardless of the age parameter. Aging is then handled externally
        %   by scaling the template with the observer's LensDensity property.
        %
        %   For age-dependent templates, this returns the model-specific
        %   density value for the given age.
        %
        %   INPUTS:
        %       age - Observer age in years (scalar)
        %
        %   OPTIONAL INPUTS (Name-Value arguments):
        %       FieldSize - Observer field size in degrees (scalar). Only
        %                   consumed by lens templates that model field-size-
        %                   dependent properties.
        %
        %   OUTPUTS:
        %       density - Lens optical density at 400nm (scalar)
        density = computeDensityAt400(obj, age, options)

    end
end

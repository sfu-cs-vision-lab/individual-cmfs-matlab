classdef (Abstract) MacularTemplate < handle
    % MACULARTEMPLATE  Abstract base class for macular pigment OD templates.
    %
    %   This class defines the interface for macular-pigment template
    %   strategies used in the IndividualCMF model, mirroring LensTemplate.
    %   Subclasses implement specific spectral shapes such as the Stockman
    %   & Rider (2023) Fourier polynomial.
    %
    %   The macular optical density template describes the spectral SHAPE
    %   of macular pigment absorption. The template is normalized so that
    %   the value at 460 nm equals 1.0; absolute density is obtained by
    %   multiplying by the observer's MacularDensity (the peak OD at 460
    %   nm). This unit-peak convention parallels LensTemplate's unit-peak-
    %   at-400-nm convention.
    %
    %   MacularTemplate Abstract Properties:
    %       Name      - Full descriptive name of the template model.
    %       ShortName - Short identifier for the template model.
    %
    %   MacularTemplate Abstract Methods:
    %       computeTemplate - Returns OD spectrum normalized to 1.0 at 460 nm.
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

        % ShortName  Short identifier matching enums.MacularModel members
        % (e.g., "StockmanRider2023").
        ShortName
    end

    methods (Abstract)
        % computeTemplate  Returns OD spectrum normalized to 1.0 at 460 nm.
        %
        %   template = obj.computeTemplate(wavelengths) returns the macular
        %   optical density spectrum normalized such that the value at
        %   460 nm equals 1.0. Multiply by the observer's MacularDensity
        %   (peak OD at 460 nm) to obtain the absolute density spectrum.
        %
        %   Wavelengths outside the template's defined range should return
        %   zero (macular pigment absorption is negligible above ~550 nm
        %   and not measured below ~375 nm in standard templates).
        %
        %   INPUTS:
        %       wavelengths - Wavelengths in nanometers (column vector)
        %
        %   OUTPUTS:
        %       template - OD normalized to 1.0 at 460 nm (column vector)
        template = computeTemplate(obj, wavelengths)
    end
end

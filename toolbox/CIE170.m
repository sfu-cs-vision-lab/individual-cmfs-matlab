classdef CIE170
% CIE170  Canonical constants from CIE 170-1:2006 and CIE 170-2:2015.
%
%   This class is a leaf-level constants module. It holds the numerical
%   values published by the CIE 170 series (cone fundamentals and the
%   chromaticity diagram with physiological axes). Domain classes
%   reference these constants instead of redeclaring them, so the
%   single source of truth lives here.
%
%   CIE170 has no methods, no dependencies, and no behavior. Adding a
%   reference to CIE170 from any class never introduces a dependency
%   cycle.
%
%   CIE170 Properties:
%       Standard observer:
%           STD_AGE                       - 32 years
%           STD_FIELD_SIZE_2DEG           - 2 degrees
%           STD_FIELD_SIZE_10DEG          - 10 degrees
%
%       Standard photopigment optical densities (CIE 170-1:2006 Table 6.5):
%           STD_2DEG_L_OPTICAL_DENSITY    - 0.50
%           STD_2DEG_M_OPTICAL_DENSITY    - 0.50
%           STD_2DEG_S_OPTICAL_DENSITY    - 0.40
%           STD_10DEG_L_OPTICAL_DENSITY   - 0.38
%           STD_10DEG_M_OPTICAL_DENSITY   - 0.38
%           STD_10DEG_S_OPTICAL_DENSITY   - 0.30
%
%       Standard macular pigment density at 460 nm (CIE 170-1:2006):
%           STD_2DEG_MACULAR_DENSITY      - 0.350
%           STD_10DEG_MACULAR_DENSITY     - 0.095
%
%       Standard crystalline lens density at 400 nm:
%           STD_LENS_DENSITY_400          - 1.7649 (Stockman & Rider 2023,
%                                           adopted by CIE 170-1:2006)
%
%       LMS->XYZ transformation matrices (CIE 170-2:2015):
%           M_2DEG                        - 3x3 matrix (transposed for
%                                           [N x 3] * [3 x 3] convention)
%           M_10DEG                       - 3x3 matrix (transposed)
%
%   References:
%       CIE 170-1:2006. Fundamental chromaticity diagram with physiological
%       axes - Part 1. Vienna: CIE.
%
%       CIE 170-2:2015. Fundamental chromaticity diagram with physiological
%       axes - Part 2. Vienna: CIE.
%
%       Stockman, A. & Rider, A.T. (2023). Formulae for generating standard
%       and individual human cone spectral sensitivity functions. Color
%       Research and Application, 48(6), 818-840.
%
%   See also: ObserverParameters, LensTemplate, PreReceptoralFilter,
%             IndividualCMF.

% SPDX-License-Identifier: AGPL-3.0-or-later
%
% Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
% Simon Fraser University, Burnaby, British Columbia, Canada
%
% This file is part of the Matlab Individual Cone Fundamentals Toolbox.
% Licensed under AGPL-3.0-or-later. See LICENSE file for details.
% Repository: https://github.com/sfu-cs-vision-lab/Individual-CMFs

    properties (Constant)
        % Standard observer age. CIE 170-1:2006 uses 32 years as the
        % reference age at which the lens aging factor equals 1.0.
        STD_AGE = 32

        % Standard 2-degree field size for foveal viewing.
        STD_FIELD_SIZE_2DEG = 2

        % Standard 10-degree field size for extrafoveal viewing.
        STD_FIELD_SIZE_10DEG = 10

        % CIE 170-1:2006 standard L-cone optical density (2-degree observer).
        STD_2DEG_L_OPTICAL_DENSITY = 0.50

        % CIE 170-1:2006 standard M-cone optical density (2-degree observer).
        STD_2DEG_M_OPTICAL_DENSITY = 0.50

        % CIE 170-1:2006 standard S-cone optical density (2-degree observer).
        STD_2DEG_S_OPTICAL_DENSITY = 0.40

        % CIE 170-1:2006 standard L-cone optical density (10-degree observer).
        STD_10DEG_L_OPTICAL_DENSITY = 0.38

        % CIE 170-1:2006 standard M-cone optical density (10-degree observer).
        STD_10DEG_M_OPTICAL_DENSITY = 0.38

        % CIE 170-1:2006 standard S-cone optical density (10-degree observer).
        STD_10DEG_S_OPTICAL_DENSITY = 0.30

        % CIE 170-1:2006 standard macular pigment density at 460 nm
        % (2-degree observer).
        STD_2DEG_MACULAR_DENSITY = 0.350

        % CIE 170-1:2006 standard macular pigment density at 460 nm
        % (10-degree observer).
        STD_10DEG_MACULAR_DENSITY = 0.095

        % Standard crystalline lens density at 400 nm. From the Stockman &
        % Rider (2023) lens template, which CIE 170-1:2006 adopts.
        STD_LENS_DENSITY_400 = 1.7649

        % Stiles & Burch (1959) 10-degree RGB color matching primaries,
        % in nanometres [R, G, B]. Adopted by CIE 170-2:2015 (Section 4.3)
        % as the canonical primaries for deriving RGB from LMS.
        %
        %   Stiles, W. S. & Burch, J. M. (1959). N.P.L. colour-matching
        %   investigation: Final report. Optica Acta, 6(1), 1-26.
        STILES_BURCH_10DEG_PRIMARIES_NM = [645.15, 526.32, 444.44]

        % CIE 170-2:2015 LMS->XYZ transformation matrix for the 2-degree
        % standard observer (Stockman 2019, Eq. 4), stored in standard
        % color-science form: row i gives the linear-combination
        % coefficients that produce output channel i (X, Y, Z) from the
        % input (L, M, S):
        %   M_2DEG(1, :) = x_bar coefficients (across L, M, S)
        %   M_2DEG(2, :) = y_bar coefficients (V*(lambda))
        %   M_2DEG(3, :) = z_bar coefficients
        %
        % For a column-vector LMS:
        %   [X; Y; Z] = M_2DEG * [L; M; S]
        % The toolbox stores spectral data in [N x 3] row-major form, so
        % batched application requires transposing the matrix at the
        % multiplication site:
        %   XYZ = LMS * M_2DEG.'
        M_2DEG = [ ...
             1.94735469, -1.41445123,  0.36476327; ...
             0.68990272,  0.34832189,  0.00000000; ...
             0.00000000,  0.00000000,  1.93485343 ]

        % CIE 170-2:2015 LMS->XYZ transformation matrix for the 10-degree
        % standard observer (Stockman 2019, Eq. 5). Same convention as
        % M_2DEG: rows are [x_bar; y_bar; z_bar] coefficients across LMS.
        % Apply to [N x 3] LMS data via XYZ = LMS * M_10DEG.'.
        M_10DEG = [ ...
             1.93986443, -1.34664359,  0.43044935; ...
             0.69283932,  0.34967567,  0.00000000; ...
             0.00000000,  0.00000000,  2.14687945 ]
    end
end

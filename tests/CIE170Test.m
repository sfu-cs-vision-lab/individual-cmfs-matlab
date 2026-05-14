classdef CIE170Test < matlab.unittest.TestCase
    % CIE170TEST  Verifies the canonical CIE-published constant values.
    %
    %   These tests pin the numerical values held in CIE170 against the
    %   numbers published in CIE 170-1:2006 and CIE 170-2:2015. If a
    %   typo or accidental edit changes a constant, the corresponding
    %   test fails immediately.

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada
    %
    % This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    % Licensed under AGPL-3.0-or-later. See LICENSE file for details.

    methods (Test)

        function testStandardObserverScalars(testCase)
            testCase.verifyEqual(CIE170.STD_AGE, 32);
            testCase.verifyEqual(CIE170.STD_FIELD_SIZE_2DEG, 2);
            testCase.verifyEqual(CIE170.STD_FIELD_SIZE_10DEG, 10);
        end

        function test2DegOpticalDensities(testCase)
            testCase.verifyEqual(CIE170.STD_2DEG_L_OPTICAL_DENSITY, 0.50);
            testCase.verifyEqual(CIE170.STD_2DEG_M_OPTICAL_DENSITY, 0.50);
            testCase.verifyEqual(CIE170.STD_2DEG_S_OPTICAL_DENSITY, 0.40);
        end

        function test10DegOpticalDensities(testCase)
            testCase.verifyEqual(CIE170.STD_10DEG_L_OPTICAL_DENSITY, 0.38);
            testCase.verifyEqual(CIE170.STD_10DEG_M_OPTICAL_DENSITY, 0.38);
            testCase.verifyEqual(CIE170.STD_10DEG_S_OPTICAL_DENSITY, 0.30);
        end

        function testMacularDensities(testCase)
            testCase.verifyEqual(CIE170.STD_2DEG_MACULAR_DENSITY, 0.350);
            testCase.verifyEqual(CIE170.STD_10DEG_MACULAR_DENSITY, 0.095);
        end

        function testLensDensityAt400(testCase)
            testCase.verifyEqual(CIE170.STD_LENS_DENSITY_400, 1.7649);
        end

        function testXYZTransformShape(testCase)
            testCase.verifySize(CIE170.M_2DEG, [3, 3]);
            testCase.verifySize(CIE170.M_10DEG, [3, 3]);
        end

        function testXYZTransform2DegRow1(testCase)
            % x_bar coefficients (row 1) from CIE 170-2:2015 (Stockman 2019 Eq. 4),
            % stored in standard color-science form (rows are output channels).
            testCase.verifyEqual(CIE170.M_2DEG(1, :), ...
                [1.94735469, -1.41445123, 0.36476327], 'AbsTol', 1e-12);
        end

        function testXYZTransform10DegRow1(testCase)
            testCase.verifyEqual(CIE170.M_10DEG(1, :), ...
                [1.93986443, -1.34664359, 0.43044935], 'AbsTol', 1e-12);
        end

    end
end

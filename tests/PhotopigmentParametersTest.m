classdef PhotopigmentParametersTest < matlab.unittest.TestCase
    % PHOTOPIGMENTPARAMETERSTEST  Unit tests for PhotopigmentParameters class.
    %
    %   Tests cover:
    %   - Default construction
    %   - Construction with custom Name=Value arguments
    %   - Static factory methods (standardL, standardM, standardS)
    %   - Validation that OpticalDensity must be non-negative
    %   - Constant values match CIE 170-1:2006 standards

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada
    %
    % This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    % Licensed under AGPL-3.0-or-later. See LICENSE file for details.
    % Repository: https://github.com/sfu-cs-vision-lab/Individual-CMFs

    methods(Test)

        function testDefaultConstruction(testCase)
            params = PhotopigmentParameters();

            testCase.verifyEqual(params.OpticalDensity, 0.38, ...
                'Default OpticalDensity should be 0.38');
            testCase.verifyEqual(params.LambdaMaxShift, 0, ...
                'Default LambdaMaxShift should be 0');
        end

        function testConstructionWithOpticalDensity(testCase)
            % Test construction with custom OpticalDensity
            params = PhotopigmentParameters(OpticalDensity=0.45);

            testCase.verifyEqual(params.OpticalDensity, 0.45, ...
                'OpticalDensity should be set to custom value');
            testCase.verifyEqual(params.LambdaMaxShift, 0, ...
                'LambdaMaxShift should remain at default');
        end

        function testConstructionWithLambdaMaxShift(testCase)
            % Test construction with custom LambdaMaxShift
            params = PhotopigmentParameters(LambdaMaxShift=-3.5);

            testCase.verifyEqual(params.OpticalDensity, 0.38, ...
                'OpticalDensity should remain at default');
            testCase.verifyEqual(params.LambdaMaxShift, -3.5, ...
                'LambdaMaxShift should be set to custom value');
        end

        function testConstructionWithBothParameters(testCase)
            % Test construction with both custom parameters
            params = PhotopigmentParameters(OpticalDensity=0.50, LambdaMaxShift=2.0);

            testCase.verifyEqual(params.OpticalDensity, 0.50, ...
                'OpticalDensity should be set to custom value');
            testCase.verifyEqual(params.LambdaMaxShift, 2.0, ...
                'LambdaMaxShift should be set to custom value');
        end

        function testStandardLFactoryMethod(testCase)
            % Test standardL() factory method returns correct L-cone parameters
            params = PhotopigmentParameters.standardL();

            testCase.verifyEqual(params.OpticalDensity, 0.38, ...
                'Standard L-cone OpticalDensity should be 0.38');
            testCase.verifyEqual(params.LambdaMaxShift, 0, ...
                'Standard L-cone LambdaMaxShift should be 0');
        end

        function testStandardMFactoryMethod(testCase)
            % Test standardM() factory method returns correct M-cone parameters
            params = PhotopigmentParameters.standardM();

            testCase.verifyEqual(params.OpticalDensity, 0.38, ...
                'Standard M-cone OpticalDensity should be 0.38');
            testCase.verifyEqual(params.LambdaMaxShift, 0, ...
                'Standard M-cone LambdaMaxShift should be 0');
        end

        function testStandardSFactoryMethod(testCase)
            % Test standardS() factory method returns correct S-cone parameters
            params = PhotopigmentParameters.standardS();

            testCase.verifyEqual(params.OpticalDensity, 0.30, ...
                'Standard S-cone OpticalDensity should be 0.30');
            testCase.verifyEqual(params.LambdaMaxShift, 0, ...
                'Standard S-cone LambdaMaxShift should be 0');
        end

        function testOpticalDensityMustBeNonnegative(testCase)
            testCase.verifyError(@() PhotopigmentParameters(OpticalDensity=-0.1), ...
                'MATLAB:validators:mustBeNonnegative');
        end

        function testZeroOpticalDensityIsValid(testCase)
            params = PhotopigmentParameters(OpticalDensity=0);

            testCase.verifyEqual(params.OpticalDensity, 0, ...
                'Zero OpticalDensity should be valid');
        end

        function testConstantLOpticalDensity(testCase)
            % Test STD_L_OPTICAL_DENSITY constant value
            testCase.verifyEqual(PhotopigmentParameters.STD_L_OPTICAL_DENSITY, 0.38, ...
                'STD_L_OPTICAL_DENSITY should match CIE 170-1:2006 value');
        end

        function testConstantMOpticalDensity(testCase)
            % Test STD_M_OPTICAL_DENSITY constant value
            testCase.verifyEqual(PhotopigmentParameters.STD_M_OPTICAL_DENSITY, 0.38, ...
                'STD_M_OPTICAL_DENSITY should match CIE 170-1:2006 value');
        end

        function testConstantSOpticalDensity(testCase)
            % Test STD_S_OPTICAL_DENSITY constant value
            testCase.verifyEqual(PhotopigmentParameters.STD_S_OPTICAL_DENSITY, 0.30, ...
                'STD_S_OPTICAL_DENSITY should match CIE 170-1:2006 value');
        end

        function testStandardLUsesConstant(testCase)
            params = PhotopigmentParameters.standardL();

            testCase.verifyEqual(params.OpticalDensity, ...
                PhotopigmentParameters.STD_L_OPTICAL_DENSITY, ...
                'standardL() should use STD_L_OPTICAL_DENSITY constant');
        end

        function testStandardMUsesConstant(testCase)
            params = PhotopigmentParameters.standardM();

            testCase.verifyEqual(params.OpticalDensity, ...
                PhotopigmentParameters.STD_M_OPTICAL_DENSITY, ...
                'standardM() should use STD_M_OPTICAL_DENSITY constant');
        end

        function testStandardSUsesConstant(testCase)
            params = PhotopigmentParameters.standardS();

            testCase.verifyEqual(params.OpticalDensity, ...
                PhotopigmentParameters.STD_S_OPTICAL_DENSITY, ...
                'standardS() should use STD_S_OPTICAL_DENSITY constant');
        end

        function testIsValueClass(testCase)
            params1 = PhotopigmentParameters(OpticalDensity=0.40);
            params2 = params1;
            params2.OpticalDensity = 0.50;

            testCase.verifyEqual(params1.OpticalDensity, 0.40, ...
                'Value class: modifying copy should not affect original');
            testCase.verifyEqual(params2.OpticalDensity, 0.50, ...
                'Value class: copy should have modified value');
        end

        function testNegativeLambdaMaxShiftIsValid(testCase)
            params = PhotopigmentParameters(LambdaMaxShift=-10);

            testCase.verifyEqual(params.LambdaMaxShift, -10, ...
                'Negative LambdaMaxShift should be valid for blue shifts');
        end

        function testPositiveLambdaMaxShiftIsValid(testCase)
            params = PhotopigmentParameters(LambdaMaxShift=5);

            testCase.verifyEqual(params.LambdaMaxShift, 5, ...
                'Positive LambdaMaxShift should be valid for red shifts');
        end

    end
end

classdef DensityAlgorithmTest < matlab.unittest.TestCase
    % DENSITYALGORITHMTEST  Tests for independent density algorithm properties.
    %   These tests cover:
    %   - Reference parity at 2deg and 10deg
    %   - Independent customization of macular vs photopigment densities
    %   - Restoration of standard values when switching from Custom

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada
    %
    % This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    % Licensed under AGPL-3.0-or-later. See LICENSE file for details.
    % Repository: https://github.com/sfu-cs-vision-lab/Individual-CMFs

    properties
        Tolerance = 1e-3  % Tolerance for reference value checks
    end

    methods(Test)

        %% Reference Parity Tests

        function testMacularDensityAt2Degrees(testCase)
            % Verify macular density at 2deg matches standard value (~0.35)
            obs = IndividualCMF(FieldSize=2);
            testCase.verifyEqual(obs.MacularDensity, 0.35, 'RelTol', testCase.Tolerance, ...
                'MacularDensity at 2deg should be approximately 0.35');
        end

        function testMacularDensityAt10Degrees(testCase)
            % Verify macular density at 10deg matches standard value (~0.095)
            obs = IndividualCMF(FieldSize=10);
            testCase.verifyEqual(obs.MacularDensity, 0.095, 'RelTol', testCase.Tolerance, ...
                'MacularDensity at 10deg should be approximately 0.095');
        end

        function testPhotopigmentDensitiesAt2Degrees(testCase)
            % Verify photopigment densities at 2deg match standard values
            obs = IndividualCMF(FieldSize=2);
            testCase.verifyEqual(obs.Lod, 0.50, 'RelTol', testCase.Tolerance, ...
                'Lod at 2deg should be approximately 0.50');
            testCase.verifyEqual(obs.Mod, 0.50, 'RelTol', testCase.Tolerance, ...
                'Mod at 2deg should be approximately 0.50');
            testCase.verifyEqual(obs.Sod, 0.40, 'RelTol', testCase.Tolerance, ...
                'Sod at 2deg should be approximately 0.40');
        end

        function testPhotopigmentDensitiesAt10Degrees(testCase)
            % Verify photopigment densities at 10deg match standard values
            obs = IndividualCMF(FieldSize=10);
            testCase.verifyEqual(obs.Lod, 0.38, 'RelTol', testCase.Tolerance, ...
                'Lod at 10deg should be approximately 0.38');
            testCase.verifyEqual(obs.Mod, 0.38, 'RelTol', testCase.Tolerance, ...
                'Mod at 10deg should be approximately 0.38');
            testCase.verifyEqual(obs.Sod, 0.30, 'RelTol', testCase.Tolerance, ...
                'Sod at 10deg should be approximately 0.30');
        end

        %% Independent Customization Tests

        function testIndependentMacularCustomization(testCase)
            % Set MacularDensity to custom value, then change FieldSize
            % Macular should stay custom, but photopigments should update
            obs = IndividualCMF(FieldSize=10);

            % Set custom macular density
            obs.MacularDensity = 0.5;
            testCase.verifyEqual(string(obs.MacularDensityAlgorithm), "Custom", ...
                'MacularDensityAlgorithm should be Custom after manual override');
            testCase.verifyEqual(string(obs.PhotopigmentDensityAlgorithm), "CIE170", ...
                'PhotopigmentDensityAlgorithm should remain CIE Constants at 10deg');

            % Store initial photopigment values (at 10deg)
            initialLod = obs.Lod;

            % Change field size from 10deg to 2deg
            obs.FieldSize = 2;

            % Verify macular density is preserved (Custom mode)
            testCase.verifyEqual(obs.MacularDensity, 0.5, ...
                'MacularDensity should remain 0.5 (Custom) after FieldSize change');

            % Verify photopigment densities updated (CIE Constants mode)
            testCase.verifyGreaterThan(obs.Lod, initialLod, ...
                'Lod should increase from 0.38 to 0.50 when FieldSize changes from 10deg to 2deg');
            testCase.verifyEqual(obs.Lod, 0.50, ...
                'Lod at 2deg should be exactly 0.50 (CIE Constants)');
        end

        function testIndependentPhotopigmentCustomization(testCase)
            % Set photopigment densities to custom values, then change FieldSize
            % Photopigments should stay custom, but macular should update
            obs = IndividualCMF(FieldSize=10);

            % Set custom photopigment density
            obs.Lod = 0.6;
            testCase.verifyEqual(string(obs.PhotopigmentDensityAlgorithm), "Custom", ...
                'PhotopigmentDensityAlgorithm should be Custom after manual override');
            testCase.verifyEqual(string(obs.MacularDensityAlgorithm), "CIE170", ...
                'MacularDensityAlgorithm should remain CIE Constants at 10deg');

            % Store initial macular density (at 10deg)
            initialMacular = obs.MacularDensity;

            % Change field size from 10deg to 2deg
            obs.FieldSize = 2;

            % Verify photopigment density is preserved (Custom mode)
            testCase.verifyEqual(obs.Lod, 0.6, ...
                'Lod should remain 0.6 (Custom) after FieldSize change');

            % Verify macular density updated (CIE Constants mode)
            testCase.verifyGreaterThan(obs.MacularDensity, initialMacular, ...
                'MacularDensity should increase from 0.095 to 0.35 when FieldSize changes from 10deg to 2deg');
            testCase.verifyEqual(obs.MacularDensity, 0.35, ...
                'MacularDensity at 2deg should be exactly 0.35 (CIE Constants)');
        end

        %% Restoration Tests

        function testMacularRestorationToCIE170(testCase)
            % Set custom macular density, then restore to CIE Constants
            obs = IndividualCMF(FieldSize=2);

            % Set custom value
            obs.MacularDensity = 0.999;
            testCase.verifyEqual(obs.MacularDensity, 0.999);
            testCase.verifyEqual(string(obs.MacularDensityAlgorithm), "Custom");

            % Silence expected warning (fixture restores cleanly)
            testCase.applyFixture( ...
                matlab.unittest.fixtures.SuppressedWarningsFixture( ...
                    'IndividualCMF:MacularCustomOverwritten'));

            % Restore to CIE Constants
            obs.MacularDensityAlgorithm = "CIE170";

            % Verify it snaps back to exact CIE value
            testCase.verifyEqual(obs.MacularDensity, 0.35, ...
                'MacularDensity should snap back to exactly 0.35 at 2deg');
        end

        function testMacularRestorationToFormula(testCase)
            % Set custom macular density, then restore to MorelandAlexander
            obs = IndividualCMF(FieldSize=2);

            % Set custom value
            obs.MacularDensity = 0.999;
            testCase.verifyEqual(string(obs.MacularDensityAlgorithm), "Custom");

            % Silence expected warning (fixture restores cleanly)
            testCase.applyFixture( ...
                matlab.unittest.fixtures.SuppressedWarningsFixture( ...
                    'IndividualCMF:MacularCustomOverwritten'));

            % Restore to formula-based algorithm
            obs.MacularDensityAlgorithm = "MorelandAlexander";

            % Verify it uses formula value (not exact CIE constant)
            expectedMacular = 0.485 * exp(-2 / 6.132);
            testCase.verifyEqual(obs.MacularDensity, expectedMacular, 'RelTol', 1e-9, ...
                'MacularDensity should use MorelandAlexander formula value');
        end

        function testPhotopigmentRestorationToCIE170(testCase)
            % Set custom photopigment densities, then restore to CIE Constants
            obs = IndividualCMF(FieldSize=2);

            % Set custom values
            obs.Lod = 0.999;
            obs.Mod = 0.888;
            obs.Sod = 0.777;
            testCase.verifyEqual(string(obs.PhotopigmentDensityAlgorithm), "Custom");

            % Silence expected warning (fixture restores cleanly)
            testCase.applyFixture( ...
                matlab.unittest.fixtures.SuppressedWarningsFixture( ...
                    'IndividualCMF:PhotopigmentCustomOverwritten'));

            % Restore to CIE Constants
            obs.PhotopigmentDensityAlgorithm = "CIE170";

            % Verify they snap back to exact CIE values
            testCase.verifyEqual(obs.Lod, 0.50, ...
                'Lod should snap back to exactly 0.50 at 2deg');
            testCase.verifyEqual(obs.Mod, 0.50, ...
                'Mod should snap back to exactly 0.50 at 2deg');
            testCase.verifyEqual(obs.Sod, 0.40, ...
                'Sod should snap back to exactly 0.40 at 2deg');
        end

        function testPhotopigmentRestorationToFormula(testCase)
            % Set custom photopigment densities, then restore to PokornySmith
            obs = IndividualCMF(FieldSize=2);

            % Set custom values
            obs.Lod = 0.999;
            testCase.verifyEqual(string(obs.PhotopigmentDensityAlgorithm), "Custom");

            % Silence expected warning (fixture restores cleanly)
            testCase.applyFixture( ...
                matlab.unittest.fixtures.SuppressedWarningsFixture( ...
                    'IndividualCMF:PhotopigmentCustomOverwritten'));

            % Restore to formula-based algorithm
            obs.PhotopigmentDensityAlgorithm = "PokornySmith";

            % Verify it uses formula values
            expectedLod = 0.38 + 0.54 * exp(-2 / 1.333);
            testCase.verifyEqual(obs.Lod, expectedLod, 'RelTol', 1e-9, ...
                'Lod should use PokornySmith formula value');
        end

        %% Warning Tests

        function testMacularCustomOverwrittenWarning(testCase)
            % Switching from Custom should issue a warning
            obs = IndividualCMF(FieldSize=2);
            obs.MacularDensity = 0.5;  % Switch to Custom

            testCase.verifyWarning(@() setMacularAlgorithm(obs, "MorelandAlexander"), ...
                'IndividualCMF:MacularCustomOverwritten');
        end

        function testPhotopigmentCustomOverwrittenWarning(testCase)
            % Switching from Custom should issue a warning
            obs = IndividualCMF(FieldSize=2);
            obs.Lod = 0.6;  % Switch to Custom

            testCase.verifyWarning(@() setPhotopigmentAlgorithm(obs, "PokornySmith"), ...
                'IndividualCMF:PhotopigmentCustomOverwritten');
        end

        %% Constructor Override Tests

        function testConstructorMacularOverride(testCase)
            % Constructor with MacularDensity should set Custom mode for macular only
            obs = IndividualCMF(MacularDensity=0.5, FieldSize=2);
            testCase.verifyEqual(string(obs.MacularDensityAlgorithm), "Custom");
            testCase.verifyEqual(string(obs.PhotopigmentDensityAlgorithm), "CIE170", ...
                'Photopigment should use CIE Constants at 2deg');
            testCase.verifyEqual(obs.MacularDensity, 0.5);
            testCase.verifyEqual(obs.Lod, 0.50, ...
                'Lod at 2deg should be exactly 0.50 (CIE Constants)');
        end

        function testConstructorPhotopigmentOverride(testCase)
            % Constructor with Lod should set Custom mode for photopigments only
            obs = IndividualCMF(Lod=0.6, FieldSize=2);
            testCase.verifyEqual(string(obs.MacularDensityAlgorithm), "CIE170", ...
                'Macular should use CIE Constants at 2deg');
            testCase.verifyEqual(string(obs.PhotopigmentDensityAlgorithm), "Custom");
            testCase.verifyEqual(obs.Lod, 0.6);
            testCase.verifyEqual(obs.MacularDensity, 0.35, ...
                'MacularDensity at 2deg should be exactly 0.35 (CIE Constants)');
        end

        function testConstructorBothOverrides(testCase)
            % Constructor with both macular and photopigment overrides
            obs = IndividualCMF(MacularDensity=0.5, Lod=0.6, FieldSize=2);
            testCase.verifyEqual(string(obs.MacularDensityAlgorithm), "Custom");
            testCase.verifyEqual(string(obs.PhotopigmentDensityAlgorithm), "Custom");
            testCase.verifyEqual(obs.MacularDensity, 0.5);
            testCase.verifyEqual(obs.Lod, 0.6);
        end

        function testConstructorAtNonStandardFieldSize(testCase)
            % Constructor at non-standard field size uses formula-based algorithms
            obs = IndividualCMF(FieldSize=5);
            testCase.verifyEqual(string(obs.MacularDensityAlgorithm), "MorelandAlexander");
            testCase.verifyEqual(string(obs.PhotopigmentDensityAlgorithm), "PokornySmith");
            testCase.verifyEqual(obs.Type, "Individualized");
        end

        %% Default Algorithm Tests

        function testDefaultAlgorithmsAtStandardFieldSize(testCase)
            % At standard field sizes (2deg and 10deg), default to CIE Constants
            obs10 = IndividualCMF(FieldSize=10);
            testCase.verifyEqual(string(obs10.MacularDensityAlgorithm), "CIE170", ...
                'Default MacularDensityAlgorithm at 10deg should be CIE Constants');
            testCase.verifyEqual(string(obs10.PhotopigmentDensityAlgorithm), "CIE170", ...
                'Default PhotopigmentDensityAlgorithm at 10deg should be CIE Constants');

            obs2 = IndividualCMF(FieldSize=2);
            testCase.verifyEqual(string(obs2.MacularDensityAlgorithm), "CIE170", ...
                'Default MacularDensityAlgorithm at 2deg should be CIE Constants');
            testCase.verifyEqual(string(obs2.PhotopigmentDensityAlgorithm), "CIE170", ...
                'Default PhotopigmentDensityAlgorithm at 2deg should be CIE Constants');
        end

        function testDefaultAlgorithmsAtNonStandardFieldSize(testCase)
            % At non-standard field sizes, default to formula-based algorithms
            obs = IndividualCMF(FieldSize=5);
            testCase.verifyEqual(string(obs.MacularDensityAlgorithm), "MorelandAlexander", ...
                'Default MacularDensityAlgorithm at 5deg should be MorelandAlexander');
            testCase.verifyEqual(string(obs.PhotopigmentDensityAlgorithm), "PokornySmith", ...
                'Default PhotopigmentDensityAlgorithm at 5deg should be PokornySmith');
        end

        %% Type Property Tests

        function testTypeIsCIEAtStandardFieldSize(testCase)
            % Type should be "CIE 170-1:2006" at standard field sizes with default settings
            obs10 = IndividualCMF(FieldSize=10);
            testCase.verifyEqual(obs10.Type, "CIE 170-1:2006", ...
                'Type at 10deg should be CIE 170-1:2006');

            obs2 = IndividualCMF(FieldSize=2);
            testCase.verifyEqual(obs2.Type, "CIE 170-1:2006", ...
                'Type at 2deg should be CIE 170-1:2006');
        end

        function testTypeIsIndividualizedAtNonStandardFieldSize(testCase)
            % Type should be "Individualized" at non-standard field sizes
            obs = IndividualCMF(FieldSize=5);
            testCase.verifyEqual(obs.Type, "Individualized", ...
                'Type at 5deg should be Individualized');
        end

        function testTypeWithMorelandAlexanderAt10Degrees(testCase)
            % Using MorelandAlexander at 10deg produces Individualized Type and precise formula values
            obs = IndividualCMF(FieldSize=10, MacularDensityAlgorithm="MorelandAlexander");
            testCase.verifyEqual(obs.Type, "Individualized", ...
                'MorelandAlexander at 10deg should result in Individualized Type');

            % Formula: 0.485 * exp(-10 / 6.132) ~ 0.09495
            expectedMacular = 0.485 * exp(-10 / 6.132);
            testCase.verifyEqual(obs.MacularDensity, expectedMacular, 'RelTol', 1e-9, ...
                'MorelandAlexander should produce precise formula value');
        end

        function testCIE170VsFormulaDifference(testCase)
            % Verify that CIE Constants and formula produce different values
            obsCIE = IndividualCMF(FieldSize=10);  % CIE Constants
            obsFormula = IndividualCMF(FieldSize=10, MacularDensityAlgorithm="MorelandAlexander");

            testCase.verifyEqual(obsCIE.MacularDensity, 0.095, ...
                'CIE Constants should produce exact value 0.095');
            testCase.verifyNotEqual(obsFormula.MacularDensity, 0.095, ...
                'MorelandAlexander should produce different value from 0.095');
        end

        %% Continuous Behavior Tests

        function testMacularDensityDecreasingWithFieldSize(testCase)
            % Macular density should decrease monotonically with field size
            fieldSizes = [1, 2, 4, 6, 8, 10, 15];
            macularDensities = zeros(size(fieldSizes));

            for i = 1:length(fieldSizes)
                obs = IndividualCMF(FieldSize=fieldSizes(i));
                macularDensities(i) = obs.MacularDensity;
            end

            % Check monotonically decreasing
            for i = 2:length(fieldSizes)
                testCase.verifyLessThan(macularDensities(i), macularDensities(i-1), ...
                    sprintf('MacularDensity should decrease: %.4f at %ddeg vs %.4f at %ddeg', ...
                    macularDensities(i), fieldSizes(i), macularDensities(i-1), fieldSizes(i-1)));
            end
        end

        function testPhotopigmentDensitiesDecreasingWithFieldSize(testCase)
            % Initialize observer
            obs = IndividualCMF();

            % FIX: Force explicit algorithms to avoid "Hybrid" artifacts
            % We want to test the monotonicity of the PHYSICS, not the table lookups.
            obs.MacularDensityAlgorithm = "MorelandAlexander";
            obs.PhotopigmentDensityAlgorithm = "PokornySmith";

            % Define field sizes to test (e.g., 2, 5, 10, 15)
            sizes = [2, 5, 10, 15, 20];

            for i = 1:length(sizes)-1
                sizeA = sizes(i);
                sizeB = sizes(i+1);

                obs.FieldSize = sizeA;
                valA = obs.Lod;

                obs.FieldSize = sizeB;
                valB = obs.Lod;

                % Check that density decreases as field size increases
                testCase.verifyLessThanOrEqual(valB, valA, ...
                    sprintf('Lod should decrease: %.4f at %ddeg vs %.4f at %ddeg', ...
                    valB, sizeB, valA, sizeA));
            end
        end

        %% State Persistence Tests

        function testDirtyFlagInvalidation(testCase)
            % LMS values should change when field size changes
            obs = IndividualCMF(FieldSize=2);
            LMS2 = obs.LMS();

            obs.FieldSize = 10;
            LMS10 = obs.LMS();

            testCase.verifyFalse(isequal(LMS2, LMS10), ...
                'LMS values should differ between 2deg and 10deg field sizes');
        end

    end
end

%% Helper functions for verifyWarning with property assignment

function setMacularAlgorithm(obj, value)
obj.MacularDensityAlgorithm = value;
end

function setPhotopigmentAlgorithm(obj, value)
obj.PhotopigmentDensityAlgorithm = value;
end

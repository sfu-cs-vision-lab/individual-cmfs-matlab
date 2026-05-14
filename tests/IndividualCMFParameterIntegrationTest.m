classdef IndividualCMFParameterIntegrationTest < matlab.unittest.TestCase
    % INDIVIDUALCMFPARAMETERINTEGRATIONTEST  Tests for IndividualCMF parameter integration.
    %
    %   Tests cover the new convenience methods that integrate with
    %   ObserverParameters and Genotype classes:
    %   - applyGenotype: Configure observer from genotype string
    %   - getParameters: Get ObserverParameters snapshot
    %   - setParameters: Apply ObserverParameters to observer
    %   - Copy functionality with new properties

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada
    %
    % This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    % Licensed under AGPL-3.0-or-later. See LICENSE file for details.
    % Repository: https://github.com/sfu-cs-vision-lab/Individual-CMFs

    properties (Constant)
        RelTol = 1e-6
        AbsTol = 1e-10
    end

    methods (TestMethodSetup)
        function suppressExpectedWarnings(testCase)
            % Suppress ShiftOverride warning (expected when using Mean template
            % with non-zero shift). The fixture restores state cleanly.
            testCase.applyFixture( ...
                matlab.unittest.fixtures.SuppressedWarningsFixture( ...
                    'StockmanRiderPhotopigmentTemplate:ShiftOverride'));
        end
    end

    methods (Test)

        function testGetParametersReturnsObserverParameters(testCase)
            obs = IndividualCMF();
            params = obs.getParameters();

            testCase.verifyClass(params, ?ObserverParameters, ...
                'getParameters() should return ObserverParameters');
        end

        function testGetParametersReflectsAge(testCase)
            obs = IndividualCMF();
            obs.Age = 45;
            params = obs.getParameters();

            testCase.verifyEqual(params.Age, 45, ...
                'getParameters() should reflect observer Age');
        end

        function testGetParametersReflectsFieldSize(testCase)
            obs = IndividualCMF(StandardObserver=2);
            params = obs.getParameters();

            testCase.verifyEqual(params.FieldSize, 2, ...
                'getParameters() should reflect observer FieldSize');
        end

        function testGetParametersReflectsConeOpticalDensities(testCase)
            obs = IndividualCMF(StandardObserver=10);
            params = obs.getParameters();

            testCase.verifyEqual(params.LCone.OpticalDensity, 0.38, ...
                'RelTol', testCase.RelTol);
            testCase.verifyEqual(params.MCone.OpticalDensity, 0.38, ...
                'RelTol', testCase.RelTol);
            testCase.verifyEqual(params.SCone.OpticalDensity, 0.30, ...
                'RelTol', testCase.RelTol);
        end

        function testGetParametersReflectsLambdaMaxShifts(testCase)
            obs = IndividualCMF();
            obs.L_LambdaMaxShift = -3.5;
            obs.M_LambdaMaxShift = 2.0;
            params = obs.getParameters();

            testCase.verifyEqual(params.LCone.LambdaMaxShift, -3.5, ...
                'getParameters() should reflect L-cone shift');
            testCase.verifyEqual(params.MCone.LambdaMaxShift, 2.0, ...
                'getParameters() should reflect M-cone shift');
        end

        function testGetParametersReflectsMacularDensity(testCase)
            obs = IndividualCMF(StandardObserver=2);
            params = obs.getParameters();

            testCase.verifyEqual(params.Macular.Density, 0.350, ...
                'RelTol', testCase.RelTol, ...
                'getParameters() should reflect 2-deg macular density');
        end

        function testGetParametersIsValueClass(testCase)
            obs = IndividualCMF();
            params = obs.getParameters();
            originalAge = obs.Age;

            params.Age = 99;

            testCase.verifyEqual(obs.Age, originalAge, ...
                'Modifying params should not affect observer');
        end

        function testSetParametersAppliesAge(testCase)
            obs = IndividualCMF();
            params = ObserverParameters(Age=50, FieldSize=10);
            obs.setParameters(params);

            testCase.verifyEqual(obs.Age, 50, ...
                'setParameters should apply Age');
        end

        function testSetParametersAppliesFieldSize(testCase)
            obs = IndividualCMF();
            params = ObserverParameters(FieldSize=5);
            obs.setParameters(params);

            testCase.verifyEqual(obs.FieldSize, 5, ...
                'setParameters should apply FieldSize');
        end

        function testSetParametersAppliesConeOpticalDensities(testCase)
            obs = IndividualCMF();
            params = ObserverParameters.standard2Deg();
            obs.setParameters(params);

            testCase.verifyEqual(obs.Lod, 0.50, ...
                'RelTol', testCase.RelTol);
            testCase.verifyEqual(obs.Mod, 0.50, ...
                'RelTol', testCase.RelTol);
            testCase.verifyEqual(obs.Sod, 0.40, ...
                'RelTol', testCase.RelTol);
        end

        function testSetParametersAppliesLambdaMaxShifts(testCase)
            obs = IndividualCMF();

            lCone = PhotopigmentParameters(OpticalDensity=0.38, LambdaMaxShift=-4.0);
            mCone = PhotopigmentParameters(OpticalDensity=0.38, LambdaMaxShift=3.0);
            params = ObserverParameters(LCone=lCone, MCone=mCone);
            obs.setParameters(params);

            testCase.verifyEqual(obs.L_LambdaMaxShift, -4.0, ...
                'setParameters should apply L-cone shift');
            testCase.verifyEqual(obs.M_LambdaMaxShift, 3.0, ...
                'setParameters should apply M-cone shift');
        end

        function testSetParametersAppliesMacularDensity(testCase)
            obs = IndividualCMF();
            params = ObserverParameters.standard2Deg();
            obs.setParameters(params);

            testCase.verifyEqual(obs.MacularDensity, 0.350, ...
                'RelTol', testCase.RelTol, ...
                'setParameters should apply macular density');
        end

        function testSetParametersRoundTripsAlgorithms(testCase)
            % setParameters preserves the source's algorithm modes. When
            % source had explicit Custom mode, that is preserved; when
            % source had a formula-based mode (e.g., "CIE170"),
            % that is preserved too -- values transferred from the source
            % are already consistent with that mode.
            obs = IndividualCMF(StandardObserver=10);

            % Hand-built params with all Custom modes (typical "transfer
            % these exact values" use case).
            params = ObserverParameters( ...
                PhotopigmentDensityAlgorithm="Custom", ...
                MacularDensityAlgorithm="Custom", ...
                LensDensityAlgorithm="Custom");
            obs.setParameters(params);

            testCase.verifyEqual(string(obs.PhotopigmentDensityAlgorithm), "Custom");
            testCase.verifyEqual(string(obs.MacularDensityAlgorithm), "Custom");
            testCase.verifyEqual(string(obs.LensDensityAlgorithm), "Custom");

            % Round-trip from a "CIE170" source preserves that mode.
            std10 = ObserverParameters.standard10Deg();
            obs.setParameters(std10);
            testCase.verifyEqual(string(obs.PhotopigmentDensityAlgorithm), "CIE170");
            testCase.verifyEqual(string(obs.MacularDensityAlgorithm), "CIE170");
            testCase.verifyEqual(string(obs.LensDensityAlgorithm), "Auto");
        end

        function testSetParametersInvalidatesCache(testCase)
            obs = IndividualCMF(StandardObserver=10);
            LMS1 = obs.LMS(550);

            lCone = PhotopigmentParameters(OpticalDensity=0.45, LambdaMaxShift=-5);
            params = ObserverParameters(LCone=lCone);
            obs.setParameters(params);

            LMS2 = obs.LMS(550);

            testCase.verifyNotEqual(LMS1, LMS2, ...
                'LMS values should change after setParameters');
        end

        function testGetSetParametersRoundTrip(testCase)
            obs1 = IndividualCMF();
            obs1.Age = 45;
            obs1.L_LambdaMaxShift = -2.5;
            obs1.M_LambdaMaxShift = 1.5;

            params = obs1.getParameters();

            obs2 = IndividualCMF();
            obs2.setParameters(params);

            testCase.verifyEqual(obs2.Age, 45);
            testCase.verifyEqual(obs2.L_LambdaMaxShift, -2.5, 'RelTol', testCase.RelTol);
            testCase.verifyEqual(obs2.M_LambdaMaxShift, 1.5, 'RelTol', testCase.RelTol);
        end

        function testCopyPreservesParameters(testCase)
            obs1 = IndividualCMF();
            obs1.Age = 45;
            obs1.L_LambdaMaxShift = -3.0;
            obs1.M_LambdaMaxShift = 2.0;
            obs1.OutputFormat = "quantal";

            obs2 = copy(obs1);

            testCase.verifyEqual(obs2.Age, 45);
            testCase.verifyEqual(obs2.L_LambdaMaxShift, -3.0);
            testCase.verifyEqual(obs2.M_LambdaMaxShift, 2.0);
            testCase.verifyEqual(string(obs2.OutputFormat), "quantal");
        end

        function testCopyIsIndependent(testCase)
            obs1 = IndividualCMF();
            obs1.Age = 45;

            obs2 = copy(obs1);
            obs2.Age = 60;

            testCase.verifyEqual(obs1.Age, 45, ...
                'Modifying copy should not affect original');
            testCase.verifyEqual(obs2.Age, 60, ...
                'Copy should have modified value');
        end

        function testCopyProducesSameLMS(testCase)
            obs1 = IndividualCMF();
            obs1.Age = 45;
            obs1.L_LambdaMaxShift = -2.0;

            obs2 = copy(obs1);

            LMS1 = obs1.LMS([500, 550, 600]');
            LMS2 = obs2.LMS([500, 550, 600]');

            testCase.verifyEqual(LMS1, LMS2, 'RelTol', testCase.RelTol, ...
                'Copy should produce same LMS values');
        end

        function testDefaultObserverIs10Degree(testCase)
            obs = IndividualCMF();

            testCase.verifyEqual(obs.FieldSize, 10, ...
                'Default observer should have 10-degree field size');
            testCase.verifyEqual(obs.Age, 32, ...
                'Default observer should have age 32');
            testCase.verifyEqual(obs.Type, "CIE 170-1:2006", ...
                'Default observer should be CIE 170-1:2006 compliant');
        end

        function testStandardObserver2CreatesCorrectType(testCase)
            obs = IndividualCMF(StandardObserver=2);

            testCase.verifyEqual(obs.FieldSize, 2);
            testCase.verifyEqual(obs.Type, "CIE 170-1:2006");
        end

        function testStandardObserver10CreatesCorrectType(testCase)
            obs = IndividualCMF(StandardObserver=10);

            testCase.verifyEqual(obs.FieldSize, 10);
            testCase.verifyEqual(obs.Type, "CIE 170-1:2006");
        end

        function testSetParametersThenGetParameters(testCase)
            params1 = ObserverParameters(Age=50, FieldSize=5);
            params1.LCone = PhotopigmentParameters(OpticalDensity=0.45, LambdaMaxShift=-3);

            obs = IndividualCMF();
            obs.setParameters(params1);
            params2 = obs.getParameters();

            testCase.verifyEqual(params2.Age, params1.Age);
            testCase.verifyEqual(params2.FieldSize, params1.FieldSize);
            testCase.verifyEqual(params2.LCone.OpticalDensity, params1.LCone.OpticalDensity, ...
                'RelTol', testCase.RelTol);
            testCase.verifyEqual(params2.LCone.LambdaMaxShift, params1.LCone.LambdaMaxShift, ...
                'RelTol', testCase.RelTol);
        end

    end
end

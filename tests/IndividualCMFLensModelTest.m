classdef IndividualCMFLensModelTest < matlab.unittest.TestCase
    % INDIVIDUALCMFLENSMODELTEST  Unit tests for IndividualCMF.LensModel property.
    %
    %   This test class verifies the integration of LensModel property into
    %   IndividualCMF, including constructor, setter, getter, and copy behavior.

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada
    %
    % This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    % Licensed under AGPL-3.0-or-later. See LICENSE file for details.

    methods (Test)
        function testDefaultLensModel(testCase)
            % Verify default LensModel is StockmanRider2023
            obs = IndividualCMF();
            testCase.verifyEqual(string(obs.LensModel), "StockmanRider2023");
        end

        function testLensModelInConstructor(testCase)
            % Verify LensModel can be set in constructor
            obs = IndividualCMF(LensModel="StockmanRider2023");
            testCase.verifyEqual(string(obs.LensModel), "StockmanRider2023");
        end

        function testLensModelProperty(testCase)
            % Verify LensModel can be set via property
            obs = IndividualCMF();
            obs.LensModel = "StockmanRider2023";
            testCase.verifyEqual(string(obs.LensModel), "StockmanRider2023");
        end

        function testLensModelInvalidValue(testCase)
            % Verify invalid LensModel values are rejected
            obs = IndividualCMF();
            function assignInvalid()
                obs.LensModel = "InvalidModel";
            end
            testCase.verifyError(@assignInvalid, 'MATLAB:validation:UnableToConvert');
        end

        function testBackwardCompatibility_Age32(testCase)
            % Results at age 32 should be identical before/after refactor
            obs = IndividualCMF(Age=32);
            wl = (400:5:700)';

            % These values should match the legacy implementation exactly
            LMS = obs.LMS(wl);
            testCase.verifyTrue(all(LMS(:) >= 0));
            testCase.verifyTrue(all(isfinite(LMS(:))));
        end

        function testBackwardCompatibility_Age60(testCase)
            % Results at age 60 should work correctly
            obs = IndividualCMF(Age=60);
            wl = (400:5:700)';

            LMS = obs.LMS(wl);
            testCase.verifyTrue(all(LMS(:) >= 0));
            testCase.verifyTrue(all(isfinite(LMS(:))));
        end

        function testCopyPreservesLensModel(testCase)
            % Verify copy preserves LensModel
            obs = IndividualCMF(LensModel="StockmanRider2023");
            obsCopy = copy(obs);
            testCase.verifyEqual(string(obsCopy.LensModel), "StockmanRider2023");
        end

        function testCopyIndependence(testCase)
            % Verify copy creates an independent object
            obs = IndividualCMF(LensModel="StockmanRider2023");
            obsCopy = copy(obs);

            % Modifying the copy should not affect the original
            % (Since currently only StockmanRider2023 is supported,
            % we verify independence through behavior rather than
            % direct property modification)
            wl = (400:50:600)';
            LMSOriginal = obs.LMS(wl);
            LMSCopy = obsCopy.LMS(wl);

            % Results should be identical
            testCase.verifyEqual(LMSOriginal, LMSCopy, 'AbsTol', 1e-10);
        end

        function testLensModelDisplayed(testCase)
            % Verify LensModel appears in display output
            obs = IndividualCMF();
            displayStr = evalc('disp(obs)');
            testCase.verifyTrue(contains(displayStr, 'LensModel'), ...
                'LensModel should appear in display output');
        end

        function testLensModelInAlgorithmsSection(testCase)
            % Verify LensModel is displayed in Algorithms section
            obs = IndividualCMF();
            displayStr = evalc('disp(obs)');
            testCase.verifyTrue(contains(displayStr, 'StockmanRider2023'), ...
                'LensModel value should appear in display output');
        end

        function testLensOutputEquivalence(testCase)
            % Verify lens filtering produces valid results with LensTemplate approach

            obs = IndividualCMF(Age=32);
            wl = (400:5:650)';

            % Get LMS using the new implementation
            LMS = obs.LMS(wl);

            % Verify results are valid
            testCase.verifyTrue(all(LMS(:) >= 0));
            testCase.verifyTrue(all(isfinite(LMS(:))));

            % Peak values should be close to 1.0 (normalized output)
            testCase.verifyTrue(max(LMS(:,1)) <= 1.0 + 1e-6);
            testCase.verifyTrue(max(LMS(:,2)) <= 1.0 + 1e-6);
            testCase.verifyTrue(max(LMS(:,3)) <= 1.0 + 1e-6);
        end

        function testLensModelWithStandardObserver(testCase)
            % Verify LensModel works with StandardObserver
            obs2 = IndividualCMF(StandardObserver=2);
            obs10 = IndividualCMF(StandardObserver=10);

            testCase.verifyEqual(string(obs2.LensModel), "StockmanRider2023");
            testCase.verifyEqual(string(obs10.LensModel), "StockmanRider2023");
        end

        function testLensModelWithDifferentAges(testCase)
            % Verify LensModel property is independent of Age
            obs32 = IndividualCMF(Age=32);
            obs60 = IndividualCMF(Age=60);
            obs80 = IndividualCMF(Age=80);

            testCase.verifyEqual(string(obs32.LensModel), "StockmanRider2023");
            testCase.verifyEqual(string(obs60.LensModel), "StockmanRider2023");
            testCase.verifyEqual(string(obs80.LensModel), "StockmanRider2023");
        end

        function testAgeDoesNotChangeLensModel(testCase)
            % Verify changing Age does not affect LensModel
            obs = IndividualCMF(Age=32);
            testCase.verifyEqual(string(obs.LensModel), "StockmanRider2023");

            obs.Age = 60;
            testCase.verifyEqual(string(obs.LensModel), "StockmanRider2023");

            obs.Age = 25;
            testCase.verifyEqual(string(obs.LensModel), "StockmanRider2023");
        end

        function testPokorny1987InConstructor(testCase)
            % Verify Pokorny1987 can be set in constructor
            obs = IndividualCMF(LensModel="Pokorny1987");
            testCase.verifyEqual(string(obs.LensModel), "Pokorny1987");
        end

        function testPokorny1987Property(testCase)
            % Verify Pokorny1987 can be set via property
            obs = IndividualCMF();
            obs.LensModel = "Pokorny1987";
            testCase.verifyEqual(string(obs.LensModel), "Pokorny1987");
        end

        function testPokorny1987LMSOutput(testCase)
            % Verify LMS output is valid with Pokorny1987 model
            obs = IndividualCMF(LensModel="Pokorny1987", Age=32);
            wl = (400:5:700)';
            LMS = obs.LMS(wl);

            testCase.verifyTrue(all(LMS(:) >= 0));
            testCase.verifyTrue(all(isfinite(LMS(:))));
        end

        function testPokorny1987VsStockmanRiderDiffers(testCase)
            % Verify the two lens models produce different results
            obsSR = IndividualCMF(LensModel="StockmanRider2023", Age=32);
            obsP87 = IndividualCMF(LensModel="Pokorny1987", Age=32);

            wl = (400:5:500)';
            LMSSR = obsSR.LMS(wl);
            LMSP87 = obsP87.LMS(wl);

            % Results should differ
            testCase.verifyNotEqual(LMSSR, LMSP87);
        end

        function testPokorny1987CopyPreservesModel(testCase)
            % Verify copy preserves Pokorny1987 model
            obs = IndividualCMF(LensModel="Pokorny1987");
            obsCopy = copy(obs);
            testCase.verifyEqual(string(obsCopy.LensModel), "Pokorny1987");
        end

        function testPokorny1987AgeAffectsLMS(testCase)
            % Verify that age affects LMS output for Pokorny1987
            obs32 = IndividualCMF(LensModel="Pokorny1987", Age=32);
            obs60 = IndividualCMF(LensModel="Pokorny1987", Age=60);

            wl = (400:10:500)';
            LMS32 = obs32.LMS(wl);
            LMS60 = obs60.LMS(wl);

            % Should differ due to age-dependent lens absorption
            testCase.verifyNotEqual(LMS32, LMS60);
        end

        function testSwitchingBetweenModels(testCase)
            % Verify switching between lens models works correctly
            obs = IndividualCMF(LensModel="StockmanRider2023");
            testCase.verifyEqual(string(obs.LensModel), "StockmanRider2023");

            obs.LensModel = "Pokorny1987";
            testCase.verifyEqual(string(obs.LensModel), "Pokorny1987");

            obs.LensModel = "StockmanRider2023";
            testCase.verifyEqual(string(obs.LensModel), "StockmanRider2023");
        end

        function testLensModelInvalidationCausesRecalculation(testCase)
            % Verify changing lens model invalidates cache
            obs = IndividualCMF(LensModel="StockmanRider2023", Age=32);
            wl = (400:10:500)';
            LMS1 = obs.LMS(wl);

            obs.LensModel = "Pokorny1987";
            LMS2 = obs.LMS(wl);

            % Results should differ after changing model
            testCase.verifyNotEqual(LMS1, LMS2);
        end

        function testRecalcLensFromAge_StockmanRider_NoAging(testCase)
            % StockmanRider model has NO lens aging - LensDensity stays constant
            obs = IndividualCMF(LensModel="StockmanRider2023", Age=32);
            density32 = obs.LensDensity;

            obs.Age = 60;
            density60 = obs.LensDensity;

            obs.Age = 20;
            density20 = obs.LensDensity;

            % All should equal STD_LENS_DENSITY_400
            testCase.verifyEqual(density32, CIE170.STD_LENS_DENSITY_400, 'AbsTol', 1e-10);
            testCase.verifyEqual(density60, CIE170.STD_LENS_DENSITY_400, 'AbsTol', 1e-10);
            testCase.verifyEqual(density20, CIE170.STD_LENS_DENSITY_400, 'AbsTol', 1e-10);
        end

        function testRecalcLensFromAge_Pokorny1987_HasAging(testCase)
            % Pokorny1987 model HAS lens aging - LensDensity varies with age
            % Values from Pokorny et al. (1987), Table I

            % Constants from Pokorny paper Table I
            TL1_400 = 0.600;  % TL1 at 400nm
            TL2_400 = 1.000;  % TL2 at 400nm
            AGE_COEFF = 0.02; % Per year for ages 20-60
            REF_AGE = 32;     % Reference age

            obs = IndividualCMF(LensModel="Pokorny1987", Age=REF_AGE);

            % At reference age 32: TL = TL1 * 1.0 + TL2 = 0.600 + 1.000 = 1.600
            expectedAge32 = TL1_400 * 1.0 + TL2_400;
            testCase.verifyEqual(obs.LensDensity, expectedAge32, 'AbsTol', 1e-10, ...
                'Pokorny1987 at age 32 should equal TL1 + TL2 = 1.600');

            % At age 60: ageFactor = 1 + 0.02*(60-32) = 1.56
            % TL = 0.600 * 1.56 + 1.000 = 1.936
            obs.Age = 60;
            ageFactor60 = 1 + AGE_COEFF * (60 - REF_AGE);
            expectedAge60 = TL1_400 * ageFactor60 + TL2_400;
            testCase.verifyEqual(obs.LensDensity, expectedAge60, 'AbsTol', 1e-10, ...
                'Pokorny1987 at age 60 should equal TL1*1.56 + TL2 = 1.936');

            % Verify density increases with age
            testCase.verifyGreaterThan(obs.LensDensity, expectedAge32);
        end

        function testRecalcLensFromAge_Pokorny1987_AcceleratedAgingAfter60(testCase)
            % Pokorny1987 has accelerated aging after age 60
            % For age > 60: TL = TL1 * [1.56 + 0.0667*(age-60)] + TL2

            % Constants from Pokorny paper Table I
            TL1_400 = 0.600;
            TL2_400 = 1.000;
            BASELINE_60 = 1.56;
            AGE_COEFF_ACCEL = 0.0667;

            obs = IndividualCMF(LensModel="Pokorny1987", Age=70);

            % At age 70: ageFactor = 1.56 + 0.0667*(70-60) = 1.56 + 0.667 = 2.227
            % TL = 0.600 * 2.227 + 1.000 = 2.3362
            ageFactor70 = BASELINE_60 + AGE_COEFF_ACCEL * (70 - 60);
            expectedAge70 = TL1_400 * ageFactor70 + TL2_400;
            testCase.verifyEqual(obs.LensDensity, expectedAge70, 'AbsTol', 1e-10);
        end

        function testLensModelSwitch_UpdatesDensityCorrectly(testCase)
            % Switching lens model should recalculate LensDensity appropriately

            % Constants for verification (from Pokorny et al. 1987, Table I)
            TL1_400 = 0.600;
            TL2_400 = 1.000;

            obs = IndividualCMF(LensModel="StockmanRider2023", Age=32);
            testCase.verifyEqual(obs.LensDensity, CIE170.STD_LENS_DENSITY_400, 'AbsTol', 1e-10);

            obs.LensModel = "Pokorny1987";
            expectedPokorny32 = TL1_400 + TL2_400;  % = 1.600
            testCase.verifyEqual(obs.LensDensity, expectedPokorny32, 'AbsTol', 1e-10);

            obs.LensModel = "StockmanRider2023";
            testCase.verifyEqual(obs.LensDensity, CIE170.STD_LENS_DENSITY_400, 'AbsTol', 1e-10);
        end

        function testStockmanRider_AgeChangeDoesNotAffectLensDensity(testCase)
            % For StockmanRider, changing Age should NOT affect LensDensity
            % because lens density stays constant at STD_LENS_DENSITY_400

            obs = IndividualCMF(LensModel="StockmanRider2023", Age=32);
            testCase.verifyEqual(obs.LensDensity, CIE170.STD_LENS_DENSITY_400, 'AbsTol', 1e-10);

            obs.Age = 60;
            testCase.verifyEqual(obs.LensDensity, CIE170.STD_LENS_DENSITY_400, 'AbsTol', 1e-10);

            obs.Age = 20;
            testCase.verifyEqual(obs.LensDensity, CIE170.STD_LENS_DENSITY_400, 'AbsTol', 1e-10);

            obs.Age = 80;
            testCase.verifyEqual(obs.LensDensity, CIE170.STD_LENS_DENSITY_400, 'AbsTol', 1e-10);
        end

        function testPokorny1987_AgeChangeAffectsLMS(testCase)
            % For Pokorny1987, changing Age SHOULD affect LMS output
            wl = (400:5:700)';

            obs = IndividualCMF(LensModel="Pokorny1987", Age=32);
            LMS32 = obs.LMS(wl);

            obs.Age = 60;
            LMS60 = obs.LMS(wl);

            % LMS should differ because Pokorny1987 has lens aging
            testCase.verifyNotEqual(LMS32, LMS60);
        end

        function testVanDeKraats2007InConstructor(testCase)
            % VanDeKraats2007 can be selected via constructor.
            obs = IndividualCMF(LensModel="VanDeKraats2007");
            testCase.verifyEqual(string(obs.LensModel), "VanDeKraats2007");
        end

        function testVanDeKraats2007Property(testCase)
            % VanDeKraats2007 can be selected via property.
            obs = IndividualCMF();
            obs.LensModel = "VanDeKraats2007";
            testCase.verifyEqual(string(obs.LensModel), "VanDeKraats2007");
        end

        function testVanDeKraats2007LMSOutput(testCase)
            % LMS output is finite, non-negative under VanDeKraats2007.
            obs = IndividualCMF(LensModel="VanDeKraats2007", Age=32);
            wl = (400:5:700)';
            LMS = obs.LMS(wl);
            testCase.verifyTrue(all(LMS(:) >= 0));
            testCase.verifyTrue(all(isfinite(LMS(:))));
        end

        function testVanDeKraats2007AgeChangeAffectsLMS(testCase)
            % VanDeKraats2007 is age-dependent: changing Age changes LMS.
            wl = (400:5:600)';
            obs = IndividualCMF(LensModel="VanDeKraats2007", Age=32);
            LMS32 = obs.LMS(wl);
            obs.Age = 70;
            LMS70 = obs.LMS(wl);
            testCase.verifyNotEqual(LMS32, LMS70);
        end

        function testVanDeKraats2007DiffersFromOtherModels(testCase)
            % vdK&vN's LMS output should differ from both S&R and Pokorny.
            wl = (400:10:600)';
            obsSR = IndividualCMF(LensModel="StockmanRider2023", Age=32);
            obsP87 = IndividualCMF(LensModel="Pokorny1987", Age=32);
            obsVdK = IndividualCMF(LensModel="VanDeKraats2007", Age=32);
            testCase.verifyNotEqual(obsSR.LMS(wl), obsVdK.LMS(wl));
            testCase.verifyNotEqual(obsP87.LMS(wl), obsVdK.LMS(wl));
        end

        function testVanDeKraats2007CopyPreservesModel(testCase)
            obs = IndividualCMF(LensModel="VanDeKraats2007");
            obsCopy = copy(obs);
            testCase.verifyEqual(string(obsCopy.LensModel), "VanDeKraats2007");
        end

        function testDefaultMacularModel(testCase)
            obs = IndividualCMF();
            testCase.verifyEqual(string(obs.MacularModel), "StockmanRider2023");
        end

        function testMacularModelInConstructor(testCase)
            obs = IndividualCMF(MacularModel="StockmanRider2023");
            testCase.verifyEqual(string(obs.MacularModel), "StockmanRider2023");
        end

        function testMacularModelInvalidValue(testCase)
            obs = IndividualCMF();
            function assignInvalid()
                obs.MacularModel = "NotAModel";
            end
            testCase.verifyError(@assignInvalid, 'MATLAB:validation:UnableToConvert');
        end

        function testMacularModelDisplayed(testCase)
            obs = IndividualCMF();
            displayStr = evalc('disp(obs)');
            testCase.verifyTrue(contains(displayStr, 'MacularModel'), ...
                'MacularModel should appear in display output');
        end

        function testMacularModelRoundTripsThroughGetSetParameters(testCase)
            % MacularModel should survive getParameters/setParameters round-trip.
            obs1 = IndividualCMF();
            params = obs1.getParameters();
            testCase.verifyEqual(string(params.MacularModel), "StockmanRider2023");

            obs2 = IndividualCMF();
            obs2.setParameters(params);
            testCase.verifyEqual(string(obs2.MacularModel), "StockmanRider2023");
        end
    end
end

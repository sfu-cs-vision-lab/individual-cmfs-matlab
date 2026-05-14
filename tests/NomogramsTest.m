classdef NomogramsTest < matlab.unittest.TestCase
    % NOMOGRAMSTEST  Unit tests for the Nomograms static class.
    %
    %   Tests cover:
    %   - Govardovskii template produces correct peak location
    %   - Stockman-Rider works for each cone type
    %   - Stockman-Rider shift parameter works correctly
    %   - Wavelength validation issues warnings appropriately
    %   - Numerical accuracy against Pycone golden files

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada
    %
    % This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    % Licensed under AGPL-3.0-or-later. See LICENSE file for details.
    % Repository: https://github.com/sfu-cs-vision-lab/Individual-CMFs
    %
    % If you use this code in your research, please cite:
    %   Forsythe, A. & Funt, B. (2025). Matlab Individual Cone Fundamentals Toolbox.
    %   https://github.com/sfu-cs-vision-lab/Individual-CMFs
    %
    % This implementation is based on:
    %   Stockman, A. & Rider, A.T. (2023). Formulae for generating standard and
    %   individual human cone spectral sensitivities. Color Research and
    %   Application, 48(6), 818-840. https://doi.org/10.1002/col.22879
    %
    %   Stockman, A. & Rider, A.T. (2023). Pycone: Individual-CMFs Python software.
    %   Colour and Vision Research Laboratory, Institute of Ophthalmology, UCL.
    %   https://github.com/CVRL-IoO/Individual-CMFs
    %
    %   Govardovskii, V.I., Fyhrquist, N., Reuter, T., Kuzmin, D.G. & Donner, K.
    %   (2000). In search of the visual pigment template. Visual Neuroscience,
    %   17(4), 509-528. https://doi.org/10.1017/S0952523800174036

    properties
        TestWavelengths
        GovardovskiiReference
    end

    methods (TestMethodSetup)
        function setup(testCase)
            testCase.TestWavelengths = (380:1:780)';

            % Reset warning state before each test
            Nomograms.resetWarnings();

            % Load golden data if available
            folder = fileparts(mfilename('fullpath'));
            dataFile = fullfile(folder, 'data', 'govardovskii_reference.csv');
            if exist(dataFile, 'file')
                testCase.GovardovskiiReference = readtable(dataFile);
            else
                testCase.GovardovskiiReference = [];
            end
        end
    end

    methods (TestMethodTeardown)
        function teardown(~)
            % Reset warning state after each test
            Nomograms.resetWarnings();
        end
    end

    methods (Test)

        %% Govardovskii Template Tests

        function testGovardovskiiPeakLocation(testCase)
            % Peak absorbance should occur at lambda_max
            wl = (400:0.1:700)';

            lambdaMaxValues = [420, 500, 530, 560, 600];
            for lmax = lambdaMaxValues
                absorbance = Nomograms.govardovskii2000(wl, lmax);
                [~, idx] = max(absorbance);
                foundPeak = wl(idx);

                testCase.verifyEqual(foundPeak, lmax, 'AbsTol', 0.5, ...
                    sprintf('Peak should be at lambda_max = %.0f nm', lmax));
            end
        end

        function testGovardovskiiBetaBandPresent(testCase)
            % Absorbance in UV region should be non-zero due to beta-band
            wl = (300:1:400)';
            lmax = 558.9;

            % Test deliberately probes 300-400 nm, which is below the
            % Govardovskii valid range (380-780). Suppress the resulting
            % warning so it doesn't pollute the suite output -- this
            % test verifies absorbance shape, not the warning.
            testCase.applyFixture( ...
                matlab.unittest.fixtures.SuppressedWarningsFixture( ...
                    'Nomograms:WavelengthOutOfRange'));

            absorbance = Nomograms.govardovskii2000(wl, lmax);

            % Beta-band peak is at ~365 nm for L-cone
            expectedBetaPeak = 189 + 0.315 * lmax;
            [~, betaIdx] = max(absorbance);
            foundBetaPeak = wl(betaIdx);

            testCase.verifyEqual(foundBetaPeak, expectedBetaPeak, 'AbsTol', 2.0, ...
                'Beta-band peak should follow Govardovskii Eq. 5a');

            % Beta-band amplitude should be approximately 0.26
            testCase.verifyEqual(max(absorbance), Nomograms.GOV_ABETA, 'AbsTol', 0.05, ...
                'Beta-band amplitude should be approximately 0.26');
        end

        function testGovardovskiiNonNegative(testCase)
            % Absorbance should never be negative
            wl = (300:1:900)';
            lmax = 500;

            % Probes wavelengths outside the Govardovskii valid range
            % deliberately; suppress the resulting warning. The test
            % verifies the non-negativity invariant, not the warning.
            testCase.applyFixture( ...
                matlab.unittest.fixtures.SuppressedWarningsFixture( ...
                    'Nomograms:WavelengthOutOfRange'));

            absorbance = Nomograms.govardovskii2000(wl, lmax);

            testCase.verifyGreaterThanOrEqual(min(absorbance), 0, ...
                'Absorbance should never be negative');
        end

        function testGovardovskiiAgainstGoldenFile(testCase)
            % Verify against reference golden data generated by absorbance_fixed.m
            % and Govardovskii_fixed.m. The golden file contains peak-normalized
            % absorptance spectra where each cone type is normalized to have
            % max = 1.0 at lambda-max. The normalization is done by dividing
            % by the peak absorptance computed at lambda-max, not by the maximum
            % value in the array.
            testCase.assumeTrue(~isempty(testCase.GovardovskiiReference), ...
                'Skipping: govardovskii_reference.csv not found');

            wl = testCase.GovardovskiiReference.nm;

            % The golden file was generated with these EXACT parameters from
            % the reference implementation (Govardovskii_fixed.m):
            OD = 0.3;
            lambdaMax_L = 560;
            lambdaMax_M = 530;
            lambdaMax_S = 430;

            % L-cone: Compute absorptance from Govardovskii absorbance template.
            % The reference algorithm computes:
            %   absorptance = 1 - 10^(-OD * absorbance)
            %   peak_absorptance = 1 - 10^(-OD * absorbance_at_lambdaMax)
            %   normalized = absorptance / peak_absorptance
            L_absorbance = Nomograms.govardovskii2000(wl, lambdaMax_L);
            L_absorptance = 1 - 10.^(-OD .* L_absorbance);
            L_peak_abs = Nomograms.govardovskii2000(lambdaMax_L, lambdaMax_L);
            L_peak_absorptance = 1 - 10^(-OD * L_peak_abs);
            L_absorptance = L_absorptance / L_peak_absorptance;
            testCase.verifyEqual(L_absorptance, testCase.GovardovskiiReference.L_absorptance, ...
                'RelTol', 1e-5, 'L-cone absorptance mismatch against golden data');

            % M-cone: Same normalization procedure as L-cone
            M_absorbance = Nomograms.govardovskii2000(wl, lambdaMax_M);
            M_absorptance = 1 - 10.^(-OD .* M_absorbance);
            M_peak_abs = Nomograms.govardovskii2000(lambdaMax_M, lambdaMax_M);
            M_peak_absorptance = 1 - 10^(-OD * M_peak_abs);
            M_absorptance = M_absorptance / M_peak_absorptance;
            testCase.verifyEqual(M_absorptance, testCase.GovardovskiiReference.M_absorptance, ...
                'RelTol', 1e-5, 'M-cone absorptance mismatch against golden data');

            % S-cone: Same normalization procedure as L-cone
            S_absorbance = Nomograms.govardovskii2000(wl, lambdaMax_S);
            S_absorptance = 1 - 10.^(-OD .* S_absorbance);
            S_peak_abs = Nomograms.govardovskii2000(lambdaMax_S, lambdaMax_S);
            S_peak_absorptance = 1 - 10^(-OD * S_peak_abs);
            S_absorptance = S_absorptance / S_peak_absorptance;
            testCase.verifyEqual(S_absorptance, testCase.GovardovskiiReference.S_absorptance, ...
                'RelTol', 1e-5, 'S-cone absorptance mismatch against golden data');
        end

        %% Stockman-Rider Template Tests

        function testStockmanRiderLconePeak(testCase)
            % L-cone peak should be near 553.1 nm (Serine template)
            wl = (400:0.5:700)';
            logAbs = Nomograms.stockmanRider(wl, 'L', L_Template="Serine");
            linAbs = 10.^logAbs;

            [~, idx] = max(linAbs);
            foundPeak = wl(idx);

            testCase.verifyEqual(foundPeak, Nomograms.SR_L_LMAX, 'AbsTol', 0.5, ...
                'L-cone (Serine) peak should be at 553.1 nm');
        end

        function testStockmanRiderMconePeak(testCase)
            % M-cone peak should be near 529.9 nm
            wl = (400:0.5:650)';
            logAbs = Nomograms.stockmanRider(wl, 'M');
            linAbs = 10.^logAbs;

            [~, idx] = max(linAbs);
            foundPeak = wl(idx);

            testCase.verifyEqual(foundPeak, Nomograms.SR_M_LMAX, 'AbsTol', 0.5, ...
                'M-cone peak should be at 529.9 nm');
        end

        function testStockmanRiderSconePeak(testCase)
            % S-cone peak should be near 416.9 nm
            wl = (360:0.5:500)';
            logAbs = Nomograms.stockmanRider(wl, 'S');
            linAbs = 10.^logAbs;

            [~, idx] = max(linAbs);
            foundPeak = wl(idx);

            testCase.verifyEqual(foundPeak, Nomograms.SR_S_LMAX, 'AbsTol', 0.5, ...
                'S-cone peak should be at 416.9 nm');
        end

        function testStockmanRiderShiftMovesPeak(testCase)
            % Wavelength shift should move the peak
            wl = (400:0.5:700)';
            shift = 10;

            % L-cone
            logAbs_base = Nomograms.stockmanRider(wl, 'L', L_Template="Serine");
            logAbs_shifted = Nomograms.stockmanRider(wl, 'L', Shift=shift, L_Template="Serine");

            [~, idx_base] = max(10.^logAbs_base);
            [~, idx_shifted] = max(10.^logAbs_shifted);

            peakDiff = wl(idx_shifted) - wl(idx_base);
            testCase.verifyEqual(peakDiff, shift, 'AbsTol', 1.0, ...
                'L-cone shift should move peak by specified amount');

            % M-cone
            logAbs_base = Nomograms.stockmanRider(wl, 'M');
            logAbs_shifted = Nomograms.stockmanRider(wl, 'M', Shift=shift);

            [~, idx_base] = max(10.^logAbs_base);
            [~, idx_shifted] = max(10.^logAbs_shifted);

            peakDiff = wl(idx_shifted) - wl(idx_base);
            testCase.verifyEqual(peakDiff, shift, 'AbsTol', 1.0, ...
                'M-cone shift should move peak by specified amount');
        end

        function testStockmanRiderHybridTemplates(testCase)
            % Hybrid templates (M-in-L, L-in-M) should work
            wl = (400:1:700)';

            % M-in-L should produce different result than standard L
            logAbs_std = Nomograms.stockmanRider(wl, 'L', L_Template="Serine");
            logAbs_hybrid = Nomograms.stockmanRider(wl, 'L', L_Template="MinL");
            testCase.verifyNotEqual(logAbs_std, logAbs_hybrid, ...
                'M-in-L should differ from Serine L-cone');

            % L-in-M should produce different result than standard M
            logAbs_std = Nomograms.stockmanRider(wl, 'M', M_Template="Standard");
            logAbs_hybrid = Nomograms.stockmanRider(wl, 'M', M_Template="LinM");
            testCase.verifyNotEqual(logAbs_std, logAbs_hybrid, ...
                'L-in-M should differ from Standard M-cone');
        end

        function testStockmanRiderAlanineEquivalence(testCase)
            % Alanine should equal Serine shifted by -2.7 nm
            wl = (400:1:700)';

            alanine = Nomograms.stockmanRider(wl, 'L', L_Template="Alanine");
            serine_shifted = Nomograms.stockmanRider(wl, 'L', Shift=-2.7, L_Template="Serine");

            testCase.verifyEqual(alanine, serine_shifted, 'AbsTol', 1e-10, ...
                'Alanine should equal Serine shifted by -2.7 nm');
        end

        function testStockmanRiderMeanFormula(testCase)
            % Mean should be weighted average of Serine and Alanine
            wl = (400:1:700)';

            serine = Nomograms.stockmanRider(wl, 'L', L_Template="Serine");
            alanine = Nomograms.stockmanRider(wl, 'L', L_Template="Alanine");
            mean_template = Nomograms.stockmanRider(wl, 'L', L_Template="Mean");

            % Compute expected mean
            expected = log10(Nomograms.SR_LMEAN_RENORM * ...
                (0.56 * 10.^serine + 0.44 * 10.^alanine));

            testCase.verifyEqual(mean_template, expected, 'AbsTol', 1e-10, ...
                'Mean should equal 0.56*Serine + 0.44*Alanine (with renorm)');
        end

        %% Wavelength Validation Tests

        function testWavelengthValidationWarning(testCase)
            % Should warn when wavelengths are outside valid range
            wl = (200:1:400)';  % Extends below GOV_VALID_RANGE

            testCase.verifyWarning(...
                @() Nomograms.govardovskii2000(wl, 500), ...
                'Nomograms:WavelengthOutOfRange', ...
                'Should warn for wavelengths outside valid range');
        end

        function testWavelengthValidationWarnsOnce(testCase)
            % Warning should only be issued once per session
            wl_bad = (200:1:400)';
            wl_good = (400:1:700)';

            % First call should warn
            testCase.verifyWarning(...
                @() Nomograms.govardovskii2000(wl_bad, 500), ...
                'Nomograms:WavelengthOutOfRange');

            % Second call should NOT warn (already warned)
            testCase.verifyWarningFree(...
                @() Nomograms.govardovskii2000(wl_bad, 500), ...
                'Should not warn twice');

            % Good wavelengths should also not warn
            testCase.verifyWarningFree(...
                @() Nomograms.govardovskii2000(wl_good, 500), ...
                'Good wavelengths should not trigger warning');
        end

        function testResetWarningsEnablesWarning(testCase)
            % After reset, warning should be issued again
            wl = (200:1:400)';

            % First call fires the warning (and sets the persistent
            % once-per-session flag). The console output is expected
            % and doesn't affect test logic.
            Nomograms.govardovskii2000(wl, 500);

            % Reset and verify warning is issued again
            Nomograms.resetWarnings();

            testCase.verifyWarning(...
                @() Nomograms.govardovskii2000(wl, 500), ...
                'Nomograms:WavelengthOutOfRange', ...
                'Should warn again after reset');
        end

        function testNomogramsHonorsSuppressedWarningState(testCase)
            % If the caller has suppressed Nomograms:WavelengthOutOfRange
            % via warning('off',...), validateWavelengths must NOT fire
            % the warning AND must NOT flip the persistent hasWarned
            % latch -- otherwise a later un-suppressed call would be
            % silently skipped.
            Nomograms.resetWarnings();
            prevState = warning('off', 'Nomograms:WavelengthOutOfRange');
            cleanup = onCleanup(@() warning(prevState)); %#ok<NASGU>

            % Out-of-range call under suppression: no warning expected
            wl = (200:1:400)';
            testCase.verifyWarningFree( ...
                @() Nomograms.govardovskii2000(wl, 500), ...
                'Suppressed warning must not fire');

            % Restore warning state and verify the latch was NOT flipped
            % (i.e. the next call still fires).
            clear cleanup
            warning(prevState);
            testCase.verifyWarning( ...
                @() Nomograms.govardovskii2000(wl, 500), ...
                'Nomograms:WavelengthOutOfRange', ...
                'Latch must not flip when warning was suppressed');
        end

        function testIndividualCMFWavelengthWarningSuppressesNomograms(testCase)
            % obs.WavelengthWarning=false must silence both the
            % IndividualCMF warning AND the Nomograms warning that
            % subsequent template calls trigger -- they are independent
            % paths and the user expects the single property to govern
            % both.
            Nomograms.resetWarnings();
            obs = IndividualCMF();
            obs.WavelengthWarning = false;
            testCase.verifyWarningFree( ...
                @() obs.LMS([200; 400]), ...
                'WavelengthWarning=false must suppress Nomograms warning');
        end

        function testNoWarningForValidWavelengths(testCase)
            % No warning for wavelengths within valid range
            wl_gov = (380:1:780)';
            wl_sr = (360:1:830)';

            testCase.verifyWarningFree(...
                @() Nomograms.govardovskii2000(wl_gov, 500), ...
                'Govardovskii should not warn for valid wavelengths');

            Nomograms.resetWarnings();

            testCase.verifyWarningFree(...
                @() Nomograms.stockmanRider(wl_sr, 'L'), ...
                'Stockman-Rider should not warn for valid wavelengths');
        end

        %% Constant Property Tests

        function testGovardovskiiConstants(testCase)
            % Verify Govardovskii constants match published values
            testCase.verifyEqual(Nomograms.GOV_A, 69.7, 'GOV_A should be 69.7');
            testCase.verifyEqual(Nomograms.GOV_B, 28.0, 'GOV_B should be 28.0');
            testCase.verifyEqual(Nomograms.GOV_C, -14.9, 'GOV_C should be -14.9');
            testCase.verifyEqual(Nomograms.GOV_D, 0.674, 'GOV_D should be 0.674');
            testCase.verifyEqual(Nomograms.GOV_B_OFFSET, 0.922, 'GOV_B_OFFSET should be 0.922');
            testCase.verifyEqual(Nomograms.GOV_C_OFFSET, 1.104, 'GOV_C_OFFSET should be 1.104');
            testCase.verifyEqual(Nomograms.GOV_ABETA, 0.26, 'GOV_ABETA should be 0.26');
        end

        function testStockmanRiderConstants(testCase)
            % Verify Stockman-Rider constants match published values
            testCase.verifyEqual(Nomograms.SR_L_LMAX, 553.1, 'SR_L_LMAX should be 553.1');
            testCase.verifyEqual(Nomograms.SR_M_LMAX, 529.9, 'SR_M_LMAX should be 529.9');
            testCase.verifyEqual(Nomograms.SR_S_LMAX, 416.9, 'SR_S_LMAX should be 416.9');
            testCase.verifyEqual(Nomograms.SR_ALANINE_SHIFT, -2.70, 'SR_ALANINE_SHIFT should be -2.70');
        end

        function testValidRangeConstants(testCase)
            % Verify valid range constants
            testCase.verifyEqual(Nomograms.GOV_VALID_RANGE, [380, 780], ...
                'Govardovskii valid range should be [380, 780]');
            testCase.verifyEqual(Nomograms.SR_VALID_RANGE, [360, 830], ...
                'Stockman-Rider valid range should be [360, 830]');
        end

        %% Error Handling Tests

        function testInvalidLconeTemplate(testCase)
            % Should error for invalid L-cone template name
            wl = (400:1:700)';

            testCase.verifyError(...
                @() Nomograms.stockmanRider(wl, 'L', L_Template="Invalid"), ...
                'Nomograms:InvalidTemplate', ...
                'Should error for invalid L-cone template');
        end

        function testInvalidMconeTemplate(testCase)
            % Should error for invalid M-cone template name
            wl = (400:1:700)';

            testCase.verifyError(...
                @() Nomograms.stockmanRider(wl, 'M', M_Template="Invalid"), ...
                'Nomograms:InvalidTemplate', ...
                'Should error for invalid M-cone template');
        end

        %% Output Size and Type Tests

        function testGovardovskiiOutputSize(testCase)
            % Output should match input wavelength size
            wl = testCase.TestWavelengths;
            absorbance = Nomograms.govardovskii2000(wl, 500);

            testCase.verifySize(absorbance, size(wl), ...
                'Output should match input wavelength size');
            testCase.verifyClass(absorbance, 'double', ...
                'Output should be double');
        end

        function testStockmanRiderOutputSize(testCase)
            % Output should match input wavelength size
            wl = (360:1:830)';

            for coneType = {'L', 'M', 'S'}
                ct = coneType{1};
                logAbs = Nomograms.stockmanRider(wl, ct);

                testCase.verifySize(logAbs, size(wl), ...
                    sprintf('%s-cone output should match input size', ct));
                testCase.verifyClass(logAbs, 'double', ...
                    sprintf('%s-cone output should be double', ct));
            end
        end

    end
end

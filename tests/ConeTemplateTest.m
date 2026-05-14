classdef ConeTemplateTest < matlab.unittest.TestCase
    % CONETEMPLATENESTS  Tests for the PhotopigmentTemplate strategy pattern.
    %
    %   Tests cover:
    %   - Polymorphism (both templates implement the same interface)
    %   - GovardovskiiPhotopigmentTemplate specific behavior
    %   - StockmanRiderPhotopigmentTemplate specific behavior
    %   - Integration with IndividualCMF

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
    end

    methods(TestMethodSetup)
        function setup(testCase)
            testCase.TestWavelengths = (380:1:780)';
        end
    end

    methods(Test)

        %% Polymorphism Tests

        function testBothTemplatesImplementAbsorbance(testCase)
            % Both template types implement the same interface (computeAbsorbance method)
            gov = GovardovskiiPhotopigmentTemplate();
            sr = StockmanRiderPhotopigmentTemplate();

            wl = testCase.TestWavelengths;
            options = struct();

            % Both should be able to compute log absorbance without error
            testCase.verifyWarningFree(@() gov.computeAbsorbance(wl, 'L', 0, options));
            testCase.verifyWarningFree(@() sr.computeAbsorbance(wl, 'L', 0, options));
        end

        function testBothReturnCorrectSize(testCase)
            % Both templates return correctly sized output for given wavelength input
            gov = GovardovskiiPhotopigmentTemplate();
            sr = StockmanRiderPhotopigmentTemplate();

            wl = testCase.TestWavelengths;
            n = length(wl);
            options = struct();

            gov_result = gov.computeAbsorbance(wl, 'L', 0, options);
            sr_result = sr.computeAbsorbance(wl, 'L', 0, options);

            testCase.verifySize(gov_result, [n, 1], ...
                'Govardovskii should return Nx1 for N wavelengths');
            testCase.verifySize(sr_result, [n, 1], ...
                'StockmanRider should return Nx1 for N wavelengths');
        end

        function testBothHavePeaksNearLambdaMax(testCase)
            % Peaks occur near the specified lambda_max
            gov = GovardovskiiPhotopigmentTemplate();
            sr = StockmanRiderPhotopigmentTemplate();

            wl = (400:0.5:700)';
            options = struct();

            % Test Govardovskii L-cone
            gov_logAbs = gov.computeAbsorbance(wl, 'L', 0, options);
            gov_abs = 10.^(gov_logAbs);
            [~, gov_idx] = max(gov_abs);
            gov_peak = wl(gov_idx);

            % Govardovskii base L lambda_max is 558.9 nm
            testCase.verifyEqual(gov_peak, 558.9, 'AbsTol', 1.0, ...
                'Govardovskii L-cone peak should be near 558.9 nm');

            % Test StockmanRider L-cone with default Mean template
            sr_logAbs = sr.computeAbsorbance(wl, 'L', 0, options);
            sr_abs = 10.^(sr_logAbs);
            [~, sr_idx] = max(sr_abs);
            sr_peak = wl(sr_idx);

            % Mean template peaks at ~551.9nm (weighted blend of Serine 553.1nm and Alanine 550.4nm)
            testCase.verifyEqual(sr_peak, 551.9, 'AbsTol', 0.5, ...
                'StockmanRider Mean L-cone peak should be near 551.9 nm');
        end

        %% GovardovskiiPhotopigmentTemplate Tests

        function testGovardovskiiAlphaBandPeak(testCase)
            % Alpha band peak location matches lambda_max (within 1nm)
            gov = GovardovskiiPhotopigmentTemplate();
            wl = (400:0.5:700)';
            options = struct();

            for coneType = {'L', 'M', 'S'}
                ct = coneType{1};
                expected_lmax = gov.getLambdaMax(ct, 0);

                logAbs = gov.computeAbsorbance(wl, ct, 0, options);
                abs = 10.^(logAbs);
                [~, idx] = max(abs);
                found_peak = wl(idx);

                testCase.verifyEqual(found_peak, expected_lmax, 'AbsTol', 1.0, ...
                    sprintf('Govardovskii %s-cone peak should be at lambda_max', ct));
            end
        end

        function testGovardovskiiBetaBandPeak(testCase)
            % Beta band center follows equation: lambda_beta = 189 + 0.315 * lambda_max
            gov = GovardovskiiPhotopigmentTemplate();

            lmax = gov.getLambdaMax('L', 0);  % 558.9 nm
            expected_beta_peak = 189 + 0.315 * lmax;  % 365.05 nm

            % Scan UV range to find beta band peak
            wl = (300:0.5:400)';
            options = struct();
            logAbs = gov.computeAbsorbance(wl, 'L', 0, options);
            abs = 10.^(logAbs);

            [~, idx] = max(abs);
            found_peak = wl(idx);

            % Note: We measure combined alpha+beta spectrum maximum, not isolated beta center.
            % The alpha band tail shifts observed UV maximum ~1nm redward from predicted center.
            testCase.verifyEqual(found_peak, expected_beta_peak, 'AbsTol', 1.5, ...
                'Beta band maximum should be near location predicted by Govardovskii eq. 5a');
        end

        function testGovardovskiiBandwidthIncreasesWithLambdaMax(testCase)
            % Bandwidth increases with lambda_max (redder pigments are wider)
            gov = GovardovskiiPhotopigmentTemplate();
            wl = (300:1:800)';
            options = struct();

            % Compare blue-shifted (-30nm) vs standard L-cone
            logAbs_blue = gov.computeAbsorbance(wl, 'L', -30, options);
            logAbs_red = gov.computeAbsorbance(wl, 'L', 0, options);

            abs_blue = 10.^(logAbs_blue);
            abs_red = 10.^(logAbs_red);

            % Normalize for comparison
            abs_blue = abs_blue / max(abs_blue);
            abs_red = abs_red / max(abs_red);

            % Calculate FWHM proxy (count wavelengths > 0.5)
            width_blue = sum(abs_blue > 0.5);
            width_red = sum(abs_red > 0.5);

            testCase.verifyGreaterThan(width_red, width_blue, ...
                'Redder pigment (longer lambda_max) should have wider bandwidth');
        end

        function testGovardovskiiShiftMovesSpectrum(testCase)
            % Shift parameter moves the spectrum appropriately
            gov = GovardovskiiPhotopigmentTemplate();
            wl = (400:0.5:700)';
            shift = 10; % nm
            options = struct();

            logAbs_base = gov.computeAbsorbance(wl, 'L', 0, options);
            logAbs_shifted = gov.computeAbsorbance(wl, 'L', shift, options);

            abs_base = 10.^(logAbs_base);
            abs_shifted = 10.^(logAbs_shifted);

            [~, idx_base] = max(abs_base);
            [~, idx_shifted] = max(abs_shifted);

            peak_base = wl(idx_base);
            peak_shifted = wl(idx_shifted);

            testCase.verifyEqual(peak_shifted - peak_base, shift, 'AbsTol', 0.5, ...
                'Shift should move the peak by the specified amount');
        end

        %% StockmanRiderPhotopigmentTemplate Tests

        function testStockmanRiderDifferentLVariants(testCase)
            % Different variants (Serine, Alanine, Mean) produce different curves
            sr = StockmanRiderPhotopigmentTemplate();
            wl = testCase.TestWavelengths;

            options_mean = struct('L_Template', "Mean");
            options_ser = struct('L_Template', "Serine");
            options_ala = struct('L_Template', "Alanine");

            abs_mean = sr.computeAbsorbance(wl, 'L', 0, options_mean);
            abs_ser = sr.computeAbsorbance(wl, 'L', 0, options_ser);
            abs_ala = sr.computeAbsorbance(wl, 'L', 0, options_ala);

            testCase.verifyNotEqual(abs_mean, abs_ser, ...
                'Mean and Serine L-cone templates should differ');
            testCase.verifyNotEqual(abs_mean, abs_ala, ...
                'Mean and Alanine L-cone templates should differ');
            testCase.verifyNotEqual(abs_ser, abs_ala, ...
                'Serine and Alanine L-cone templates should differ');
        end

        function testStockmanRiderHybridVariants(testCase)
            % Hybrid variants (M-in-L, L-in-M) work correctly
            sr = StockmanRiderPhotopigmentTemplate();
            wl = testCase.TestWavelengths;

            % M-in-L: M-cone template shifted to L-cone position
            options_minl = struct('L_Template', "MinL");
            options_std = struct('L_Template', "Mean");

            abs_hybrid = sr.computeAbsorbance(wl, 'L', 0, options_minl);
            abs_std = sr.computeAbsorbance(wl, 'L', 0, options_std);

            testCase.verifyNotEqual(abs_hybrid, abs_std, ...
                'M-in-L hybrid should differ from standard L-cone');

            % L-in-M: L-cone (Serine) template shifted to M-cone position
            options_linm = struct('M_Template', "LinM");
            options_mstd = struct('M_Template', "Standard");

            abs_linm = sr.computeAbsorbance(wl, 'M', 0, options_linm);
            abs_mstd = sr.computeAbsorbance(wl, 'M', 0, options_mstd);

            testCase.verifyNotEqual(abs_linm, abs_mstd, ...
                'L-in-M hybrid should differ from standard M-cone');
        end

        function testStockmanRiderShiftMovesSpectrum(testCase)
            % Shift parameter moves the peak appropriately
            sr = StockmanRiderPhotopigmentTemplate();
            wl = (400:0.5:700)';
            shift = 10; % nm
            options = struct('L_Template', "Serine");

            logAbs_base = sr.computeAbsorbance(wl, 'L', 0, options);
            logAbs_shifted = sr.computeAbsorbance(wl, 'L', shift, options);

            abs_base = 10.^(logAbs_base);
            abs_shifted = 10.^(logAbs_shifted);

            [~, idx_base] = max(abs_base);
            [~, idx_shifted] = max(abs_shifted);

            peak_base = wl(idx_base);
            peak_shifted = wl(idx_shifted);

            testCase.verifyEqual(peak_shifted - peak_base, shift, 'AbsTol', 1.0, ...
                'Shift should move the StockmanRider peak by the specified amount');
        end

        function testStockmanRiderSCone(testCase)
            % S-cone template works correctly
            sr = StockmanRiderPhotopigmentTemplate();
            wl = (380:0.5:500)';
            options = struct();

            logAbs = sr.computeAbsorbance(wl, 'S', 0, options);
            abs = 10.^(logAbs);

            [~, idx] = max(abs);
            peak = wl(idx);

            % StockmanRider S-cone lambda_max is around 416.9 nm
            testCase.verifyEqual(peak, 416.9, 'AbsTol', 2.0, ...
                'StockmanRider S-cone peak should be near 416.9 nm');
        end

        %% Integration Tests

        function testIndividualCMFUsesGovardovskii(testCase)
            % IndividualCMF with PhotopigmentModel="Govardovskii2000" uses GovardovskiiPhotopigmentTemplate
            obs = IndividualCMF(PhotopigmentModel="Govardovskii2000", ...
                Age=32, FieldSize=2);

            testCase.verifyEqual(string(obs.PhotopigmentModel), "Govardovskii2000", ...
                'Observer should use Govardovskii2000 template model');
        end

        function testIndividualCMFUsesStockmanRider(testCase)
            % IndividualCMF with PhotopigmentModel="StockmanRider2023" uses StockmanRiderPhotopigmentTemplate
            obs = IndividualCMF(PhotopigmentModel="StockmanRider2023", ...
                Age=32, FieldSize=2);

            testCase.verifyEqual(string(obs.PhotopigmentModel), "StockmanRider2023", ...
                'Observer should use StockmanRider2023 template model');
        end

        function testDifferentTemplatesProduceDifferentOutput(testCase)
            % Different template models produce different output
            wl = (400:10:700)';

            obs_gov = IndividualCMF(PhotopigmentModel="Govardovskii2000", ...
                Age=32, FieldSize=2);
            obs_sr = IndividualCMF(PhotopigmentModel="StockmanRider2023", ...
                Age=32, FieldSize=2);

            % Use raw absorbance to compare templates directly
            obs_gov.OutputFormat = "absorbance";
            obs_sr.OutputFormat = "absorbance";
            obs_gov.NormalizeOutput = true;
            obs_sr.NormalizeOutput = true;

            LMS_gov = obs_gov.evaluate(wl);
            LMS_sr = obs_sr.evaluate(wl);

            testCase.verifyNotEqual(LMS_gov, LMS_sr, ...
                'Different template models should produce different LMS values');
        end

        function testPhotopigmentModelSwitching(testCase)
            % Switching template model changes the output
            obs = IndividualCMF(Age=32, FieldSize=2);
            wl = (400:10:700)';

            obs.OutputFormat = "absorbance";
            obs.NormalizeOutput = true;

            % Initial model
            obs.PhotopigmentModel = "StockmanRider2023";
            LMS_sr = obs.evaluate(wl);

            % Switch model
            obs.PhotopigmentModel = "Govardovskii2000";
            LMS_gov = obs.evaluate(wl);

            testCase.verifyNotEqual(LMS_sr, LMS_gov, ...
                'Switching template model should change output');
        end

        %% Base Lambda Max Tests

        function testGovardovskiiBaseLambdaMax(testCase)
            % Verify Govardovskii has correct base lambda_max values
            testCase.verifyEqual(GovardovskiiPhotopigmentTemplate.BASE_LAMBDA_MAX_L, 558.9);
            testCase.verifyEqual(GovardovskiiPhotopigmentTemplate.BASE_LAMBDA_MAX_M, 530.3);
            testCase.verifyEqual(GovardovskiiPhotopigmentTemplate.BASE_LAMBDA_MAX_S, 420.7);
        end

        function testStockmanRiderBaseLambdaMax(testCase)
            % Verify StockmanRider has correct base lambda_max values
            testCase.verifyEqual(StockmanRiderPhotopigmentTemplate.BASE_LAMBDA_MAX_L, 553.1);
            testCase.verifyEqual(StockmanRiderPhotopigmentTemplate.BASE_LAMBDA_MAX_M, 529.9);
            testCase.verifyEqual(StockmanRiderPhotopigmentTemplate.BASE_LAMBDA_MAX_S, 416.9);
        end

        %% computePeakAbsorbance Tests

        function testComputePeakAbsorbance(testCase)
            % computePeakAbsorbance should return positive value close to 1
            gov = GovardovskiiPhotopigmentTemplate();
            sr = StockmanRiderPhotopigmentTemplate();
            options = struct();

            gov_peak = gov.computePeakAbsorbance('L', 0, options);
            sr_peak = sr.computePeakAbsorbance('L', 0, options);

            testCase.verifyGreaterThan(gov_peak, 0, ...
                'Govardovskii peak absorbance should be positive');
            testCase.verifyGreaterThan(sr_peak, 0, ...
                'StockmanRider peak absorbance should be positive');

            % For normalized templates, peak should be close to 1
            testCase.verifyEqual(gov_peak, 1.0, 'AbsTol', 0.01, ...
                'Govardovskii peak absorbance should be ~1.0');
        end

        %% L-cone Template Shift Warning Tests

        function testMeanTemplateShiftWarning(testCase)
            % Mean template with non-zero shift should warn and use Serine
            sr = StockmanRiderPhotopigmentTemplate();
            wl = (500:1:600)';
            options_mean = struct('L_Template', "Mean");

            % Should produce a warning
            testCase.verifyWarning(...
                @() sr.computeAbsorbance(wl, 'L', 5.0, options_mean), ...
                'StockmanRiderPhotopigmentTemplate:ShiftOverride', ...
                'Mean template with shift should produce warning');

            % Result should match Serine with same shift. Suppress the
            % expected warning for the comparison calls; fixture is
            % scoped to the rest of this test method.
            options_ser = struct('L_Template', "Serine");
            testCase.applyFixture( ...
                matlab.unittest.fixtures.SuppressedWarningsFixture( ...
                    'StockmanRiderPhotopigmentTemplate:ShiftOverride'));
            mean_shifted = sr.computeAbsorbance(wl, 'L', 5.0, options_mean);
            serine_shifted = sr.computeAbsorbance(wl, 'L', 5.0, options_ser);

            testCase.verifyEqual(mean_shifted, serine_shifted, 'AbsTol', 1e-10, ...
                'Mean template with shift should produce same result as Serine with same shift');
        end

        function testAlanineTemplateShiftWarning(testCase)
            % Alanine template with non-zero shift should warn and use Serine with offset
            sr = StockmanRiderPhotopigmentTemplate();
            wl = (500:1:600)';
            options_ala = struct('L_Template', "Alanine");

            % Should produce a warning
            testCase.verifyWarning(...
                @() sr.computeAbsorbance(wl, 'L', 5.0, options_ala), ...
                'StockmanRiderPhotopigmentTemplate:ShiftOverride', ...
                'Alanine template with shift should produce warning');

            % Result should match Serine with combined shift (user_shift - 2.7).
            % Suppress the expected warning for the comparison calls.
            options_ser = struct('L_Template', "Serine");
            testCase.applyFixture( ...
                matlab.unittest.fixtures.SuppressedWarningsFixture( ...
                    'StockmanRiderPhotopigmentTemplate:ShiftOverride'));
            ala_shifted = sr.computeAbsorbance(wl, 'L', 5.0, options_ala);

            % Alanine is Serine - 2.7nm, so shift of 5.0 becomes 5.0 - 2.7 = 2.3
            serine_combined = sr.computeAbsorbance(wl, 'L', 5.0 - 2.7, options_ser);

            testCase.verifyEqual(ala_shifted, serine_combined, 'AbsTol', 1e-10, ...
                'Alanine template with shift should equal Serine with combined shift');
        end

        function testMeanTemplateNoShiftNoWarning(testCase)
            % Mean template with zero shift should NOT warn
            sr = StockmanRiderPhotopigmentTemplate();
            wl = (500:1:600)';
            options = struct('L_Template', "Mean");

            testCase.verifyWarningFree(...
                @() sr.computeAbsorbance(wl, 'L', 0, options), ...
                'Mean template with zero shift should not produce warning');
        end

        function testAlanineTemplateNoShiftNoWarning(testCase)
            % Alanine template with zero shift should NOT warn
            sr = StockmanRiderPhotopigmentTemplate();
            wl = (500:1:600)';
            options = struct('L_Template', "Alanine");

            testCase.verifyWarningFree(...
                @() sr.computeAbsorbance(wl, 'L', 0, options), ...
                'Alanine template with zero shift should not produce warning');
        end

        function testSerineTemplateShiftNoWarning(testCase)
            % Serine template with shift should NOT warn (this is the expected use case)
            sr = StockmanRiderPhotopigmentTemplate();
            wl = (500:1:600)';
            options = struct('L_Template', "Serine");

            testCase.verifyWarningFree(...
                @() sr.computeAbsorbance(wl, 'L', 5.0, options), ...
                'Serine template with shift should not produce warning');
        end

    end
end

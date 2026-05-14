classdef PhotopigmentTemplateTest < matlab.unittest.TestCase
    % PHOTOPIGMENTTEMPLATETESTS  Tests for PhotopigmentTemplate abstract base class methods.
    %   These tests verify the concrete and abstract methods in the PhotopigmentTemplate
    %   class hierarchy:
    %   - computeAbsorbance
    %   - computePeakAbsorbance
    %   - getLambdaMax
    %   - getValidRange
    %   - SupportsShift

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada
    %
    % This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    % Licensed under AGPL-3.0-or-later. See LICENSE file for details.
    % Repository: https://github.com/sfu-cs-vision-lab/Individual-CMFs

    properties
        GovTemplate
        SRTemplate
        TestWavelengths
    end

    methods(TestMethodSetup)
        function setupTemplates(testCase)
            testCase.GovTemplate = GovardovskiiPhotopigmentTemplate();
            testCase.SRTemplate = StockmanRiderPhotopigmentTemplate();
            testCase.TestWavelengths = (400:5:700)';
        end
    end

    methods(Test)

        %% getLambdaMax Tests

        function testGetLambdaMaxL(testCase)
            % Test getLambdaMax for L-cone
            lmax = testCase.GovTemplate.getLambdaMax('L', 0);
            testCase.verifyEqual(lmax, 558.9, 'Govardovskii L base lambda-max should be 558.9');

            lmax_sr = testCase.SRTemplate.getLambdaMax('L', 0);
            testCase.verifyEqual(lmax_sr, 553.1, 'StockmanRider L base lambda-max should be 553.1');
        end

        function testGetLambdaMaxM(testCase)
            % Test getLambdaMax for M-cone
            lmax = testCase.GovTemplate.getLambdaMax('M', 0);
            testCase.verifyEqual(lmax, 530.3, 'Govardovskii M base lambda-max should be 530.3');

            lmax_sr = testCase.SRTemplate.getLambdaMax('M', 0);
            testCase.verifyEqual(lmax_sr, 529.9, 'StockmanRider M base lambda-max should be 529.9');
        end

        function testGetLambdaMaxS(testCase)
            % Test getLambdaMax for S-cone
            lmax = testCase.GovTemplate.getLambdaMax('S', 0);
            testCase.verifyEqual(lmax, 420.7, 'Govardovskii S base lambda-max should be 420.7');

            lmax_sr = testCase.SRTemplate.getLambdaMax('S', 0);
            testCase.verifyEqual(lmax_sr, 416.9, 'StockmanRider S base lambda-max should be 416.9');
        end

        function testGetLambdaMaxWithShift(testCase)
            % Test getLambdaMax with shift
            shift = 10;
            lmax = testCase.GovTemplate.getLambdaMax('L', shift);
            testCase.verifyEqual(lmax, 558.9 + shift, 'Shift should be added to base');

            lmax_neg = testCase.GovTemplate.getLambdaMax('L', -5);
            testCase.verifyEqual(lmax_neg, 558.9 - 5, 'Negative shift should work');
        end

        function testGetLambdaMaxDefaultShift(testCase)
            % Test getLambdaMax with default shift (0)
            lmax = testCase.GovTemplate.getLambdaMax('L');
            testCase.verifyEqual(lmax, 558.9, 'Default shift should be 0');
        end

        %% computeAbsorbance Tests

        function testComputeAbsorbanceGov(testCase)
            % Test computeAbsorbance for Govardovskii
            wl = testCase.TestWavelengths;
            options = struct();

            logAbs = testCase.GovTemplate.computeAbsorbance(wl, 'L', 0, options);

            testCase.verifySize(logAbs, [numel(wl), 1]);
            testCase.verifyLessThan(max(logAbs), 0.1, 'Log absorbance should be <= 0 (or close)');
        end

        function testComputeAbsorbanceSR(testCase)
            % Test computeAbsorbance for StockmanRider
            wl = testCase.TestWavelengths;
            options = struct('L_Template', "Serine");

            logAbs = testCase.SRTemplate.computeAbsorbance(wl, 'L', 0, options);

            testCase.verifySize(logAbs, [numel(wl), 1]);
        end

        function testComputeAbsorbanceAllCones(testCase)
            % Test computeAbsorbance for all cone types
            wl = testCase.TestWavelengths;
            options = struct();

            for coneType = {'L', 'M', 'S'}
                ct = coneType{1};
                logAbs = testCase.GovTemplate.computeAbsorbance(wl, ct, 0, options);
                linAbs = 10.^(logAbs);
                testCase.verifyGreaterThan(max(linAbs), 0, ...
                    sprintf('%s-cone should have positive absorbance', ct));
            end
        end

        function testComputeAbsorbanceWithShift(testCase)
            % Test computeAbsorbance with shift
            wl = (500:1:650)';
            options = struct();

            logAbs_base = testCase.GovTemplate.computeAbsorbance(wl, 'L', 0, options);
            logAbs_shifted = testCase.GovTemplate.computeAbsorbance(wl, 'L', 10, options);

            linAbs_base = 10.^(logAbs_base);
            linAbs_shifted = 10.^(logAbs_shifted);

            % Find peaks
            [~, idx_base] = max(linAbs_base);
            [~, idx_shifted] = max(linAbs_shifted);

            % Shifted peak should be at higher wavelength
            testCase.verifyGreaterThan(idx_shifted, idx_base, ...
                'Positive shift should move peak to longer wavelength');
        end

        %% getValidRange Tests

        function testGetValidRangeGov(testCase)
            % Test getValidRange for Govardovskii
            range = testCase.GovTemplate.getValidRange();

            testCase.verifySize(range, [1, 2]);
            testCase.verifyEqual(range, [380, 780], ...
                'Govardovskii valid range should be [380, 780]');
        end

        function testGetValidRangeSR(testCase)
            % Test getValidRange for StockmanRider
            range = testCase.SRTemplate.getValidRange();

            testCase.verifySize(range, [1, 2]);
            testCase.verifyEqual(range, [360, 830], ...
                'StockmanRider valid range should be [360, 830]');
        end

        %% SupportsShift Tests

        function testSupportsShiftGov(testCase)
            % Test SupportsShift for Govardovskii
            tf = testCase.GovTemplate.SupportsShift;

            testCase.verifyTrue(tf, 'Govardovskii should support shifts');
        end

        function testSupportsShiftSR(testCase)
            % Test SupportsShift for StockmanRider
            tf = testCase.SRTemplate.SupportsShift;

            testCase.verifyTrue(tf, 'StockmanRider should support shifts');
        end

        %% GovardovskiiPhotopigmentTemplate Specific Tests

        function testGovardovskiiPeakAbsorbanceAnalytical(testCase)
            options = struct();

            for coneType = {'L', 'M', 'S'}
                ct = coneType{1};
                peakAbs = testCase.GovTemplate.computePeakAbsorbance(ct, 0, options);

                % Peak should be close to 1.0 (template is normalized)
                testCase.verifyEqual(peakAbs, 1.0, 'AbsTol', 0.02, ...
                    sprintf('%s-cone peak absorbance should be ~1.0', ct));
            end
        end

        function testGovardovskiiPeakAbsorbanceWithShift(testCase)
            % Test peak absorbance with shift
            options = struct();

            peakAbs_base = testCase.GovTemplate.computePeakAbsorbance('L', 0, options);
            peakAbs_shifted = testCase.GovTemplate.computePeakAbsorbance('L', 10, options);

            % Both should be close to 1.0
            testCase.verifyEqual(peakAbs_base, 1.0, 'AbsTol', 0.02);
            testCase.verifyEqual(peakAbs_shifted, 1.0, 'AbsTol', 0.02);
        end

        %% StockmanRiderPhotopigmentTemplate Specific Tests

        function testStockmanRiderPeakAbsorbanceNumerical(testCase)
            options = struct('L_Template', "Serine");

            peakAbs = testCase.SRTemplate.computePeakAbsorbance('L', 0, options);

            % Peak should be close to 1.0
            testCase.verifyGreaterThan(peakAbs, 0.9);
            testCase.verifyLessThan(peakAbs, 1.1);
        end

        function testStockmanRiderDefaultOptions(testCase)
            wl = testCase.TestWavelengths;

            % Call without L_Template in options
            options = struct();
            logAbs = testCase.SRTemplate.computeAbsorbance(wl, 'L', 0, options);

            testCase.verifySize(logAbs, [numel(wl), 1]);
        end

        function testStockmanRiderMTemplateDefault(testCase)
            wl = testCase.TestWavelengths;
            options = struct();  % No M_Template specified

            logAbs = testCase.SRTemplate.computeAbsorbance(wl, 'M', 0, options);
            testCase.verifySize(logAbs, [numel(wl), 1]);
        end

        %% Govardovskii template tests

        function testGovardovskiiComputeAbsorbanceAllCones(testCase)
            % Test Govardovskii for all cone types
            template = GovardovskiiPhotopigmentTemplate();
            wl = (400:10:700)';
            options = struct();

            % Test L cone
            logAbsL = template.computeAbsorbance(wl, 'L', 0, options);
            testCase.verifySize(logAbsL, [numel(wl), 1]);

            % Test M cone
            logAbsM = template.computeAbsorbance(wl, 'M', 0, options);
            testCase.verifySize(logAbsM, [numel(wl), 1]);

            % Test S cone
            logAbsS = template.computeAbsorbance(wl, 'S', 0, options);
            testCase.verifySize(logAbsS, [numel(wl), 1]);
        end

        function testGovardovskiiWithShifts(testCase)
            % Test Govardovskii with various shifts
            template = GovardovskiiPhotopigmentTemplate();
            wl = (400:10:700)';
            options = struct();

            % Positive shift
            logAbs1 = template.computeAbsorbance(wl, 'L', 10, options);
            testCase.verifySize(logAbs1, [numel(wl), 1]);

            % Negative shift
            logAbs2 = template.computeAbsorbance(wl, 'L', -10, options);
            testCase.verifySize(logAbs2, [numel(wl), 1]);

            % Verify shifts produce different results
            testCase.verifyNotEqual(logAbs1, logAbs2);
        end

        function testGovardovskiiPeakAbsorbance(testCase)
            % Test Govardovskii peak absorbance calculation
            template = GovardovskiiPhotopigmentTemplate();
            options = struct();

            peakL = template.computePeakAbsorbance('L', 0, options);
            peakM = template.computePeakAbsorbance('M', 0, options);
            peakS = template.computePeakAbsorbance('S', 0, options);

            % Peaks should be close to 1.0
            testCase.verifyEqual(peakL, 1.0, 'AbsTol', 0.01);
            testCase.verifyEqual(peakM, 1.0, 'AbsTol', 0.01);
            testCase.verifyEqual(peakS, 1.0, 'AbsTol', 0.01);
        end

        %% PhotopigmentTemplate abstract class

        function testPhotopigmentTemplateGetLambdaMaxWithShift(testCase)
            % Test getLambdaMax with shifts for all cones
            template = StockmanRiderPhotopigmentTemplate();

            % L cone with shift
            lmaxL = template.getLambdaMax('L', 5);
            testCase.verifyGreaterThan(lmaxL, 550);

            % M cone with shift
            lmaxM = template.getLambdaMax('M', -5);
            testCase.verifyGreaterThan(lmaxM, 520);
            testCase.verifyLessThan(lmaxM, 540);

            % S cone with shift
            lmaxS = template.getLambdaMax('S', 3);
            testCase.verifyGreaterThan(lmaxS, 415);
            testCase.verifyLessThan(lmaxS, 450);
        end

        function testPhotopigmentTemplateGetValidRange(testCase)
            % Test getValidRange for both template types
            sr = StockmanRiderPhotopigmentTemplate();
            gov = GovardovskiiPhotopigmentTemplate();

            srRange = sr.getValidRange();
            testCase.verifyEqual(srRange, [360, 830]);

            govRange = gov.getValidRange();
            testCase.verifyEqual(govRange, [380, 780]);
        end

        function testPhotopigmentTemplateSupportsShift(testCase)
            % Test SupportsShift for both template types
            sr = StockmanRiderPhotopigmentTemplate();
            gov = GovardovskiiPhotopigmentTemplate();

            testCase.verifyTrue(sr.SupportsShift);
            testCase.verifyTrue(gov.SupportsShift);
        end

        %% IndividualCMF template-related behavior

        function testSConeShift(testCase)
            % Verify that manually setting S_LambdaMaxShift moves the peak
            obs = IndividualCMF(Age=32, FieldSize=10);

            % 1. Baseline Peak Index
            obs.S_LambdaMaxShift = 0;
            wl = (390:1:500)';
            s_base = obs.S(wl);
            [~, idx_base] = max(s_base);

            % 2. Shifted Peak Index (-10nm is a large, obvious shift)
            obs.S_LambdaMaxShift = -10;
            s_shifted = obs.S(wl);
            [~, idx_shift] = max(s_shifted);

            % 3. Verification
            testCase.verifyNotEqual(idx_base, idx_shift, ...
                'S-cone peak index should change when S_LambdaMaxShift is set.');

            % Check direction (Negative shift = Shorter Wavelength = Lower Index)
            testCase.verifyTrue(idx_shift < idx_base, ...
                'Negative shift should move peak to shorter wavelengths (lower index).');
        end

        function testTemplateShapeDifferences(testCase)
            % Verify that the "Mean" template and "Serine" template have
            % different shapes.
            % NOTE: The "Mean" template mixes Serine (longer) and Alanine (shorter).
            % Because of the log-wavelength shape invariance, shifting to shorter
            % wavelengths (Alanine) compresses the curve slightly in linear space.
            % Therefore, the "Mean" (Mixed) template has a slightly SMALLER area
            % than the pure "Serine" template.

            wl = (400:1:700)';

            % 1. Mean Observer (Standard)
            obsMean = IndividualCMF(StandardObserver=2);
            obsMean.L_LambdaMaxShift = 0;
            L_mean = obsMean.L(wl);

            % 2. Serine Observer (Manual config)
            obsSerine = IndividualCMF(Age=32, FieldSize=2);
            obsSerine.L_OpsinTemplate = "Serine";
            obsSerine.L_LambdaMaxShift = 0;
            L_serine = obsSerine.L(wl);

            % 3. Basic Inequality Check
            testCase.verifyNotEqual(L_mean, L_serine, ...
                'Mean and Serine templates should differ in shape.');

            % 4. Bandwidth/Area Check
            L_mean_norm = L_mean ./ max(L_mean);
            L_serine_norm = L_serine ./ max(L_serine);

            area_mean = sum(L_mean_norm);
            area_serine = sum(L_serine_norm);

            % Mean < Serine
            testCase.verifyTrue(area_mean < area_serine, ...
                sprintf('Mean template area (%.4f) should be smaller than Serine area (%.4f)', area_mean, area_serine));
        end

    end
end

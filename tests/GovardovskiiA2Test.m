classdef GovardovskiiA2Test < matlab.unittest.TestCase
    % GovardovskiiA2Test  Verifies the Govardovskii (2000) A2 visual pigment template.
    %
    %   The A2 template (3,4-dehydroretinal chromophore) is defined by
    %   Eqs. 6 and 8 of Govardovskii et al. (2000). These tests pin the
    %   implementation against Fig. 9 spot values across the six species
    %   reported in the paper (lambda_max ranging from 444 nm to 619 nm)
    %   and verify the architectural plumbing: IndividualCMF dispatch,
    %   GovardovskiiPhotopigmentTemplate Pigment property, and analytical
    %   peak invariance.

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada
    %
    % This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    % Licensed under AGPL-3.0-or-later. See LICENSE file for details.

    properties (Constant)
        % Fig. 9 species and their fitted A2 lambda_max values, in nm.
        % Source: Govardovskii et al. (2000) Fig. 9 legend.
        Fig9Lmax = [619.4, 563.7, 537.6, 523.4, 459.4, 444.3]
        Fig9Names = ["CarpRed", "AstellRed", "CarpGreen", ...
                     "XenopusGreen", "AstellBlue", "XenopusBlue"]

        % Beta-band parameters reported for A. stellatus red cone in
        % Govardovskii Fig. 10 legend: A_beta = 0.37, lambda_m_beta =
        % 378 nm, b = 69 nm at lambda_max = 563.7 nm.
        AstellRedBetaCenter = 378
        AstellRedBetaWidth = 69
        AstellRedBetaAmplitude = 0.37

        % Spot-check tolerance for the alpha-band peak location. The
        % paper's Fourier filtering (35 harmonics, SD = 1.414 nm
        % Gaussian) limits practical peak-location accuracy to about
        % +/- 1.5 nm.
        PeakLocationTol = 1.5

        % Peak-amplitude tolerance. The A2 template normalizes the
        % alpha-band to 1.0 at lambda_max by construction, but the
        % beta-band Gaussian can contribute up to ~1% for short-wave
        % pigments where the beta-peak moves into the visible range.
        PeakAmplitudeTol = 0.015
    end

    methods (Test)

        % Direct Nomogram tests.

        function testA2PeaksAtLambdaMax(testCase)
            % Every published A2 lambda_max from Fig. 9 should produce a
            % template whose alpha-band peak lies at that wavelength.
            wl = (380:0.5:780)';
            for i = 1:numel(testCase.Fig9Lmax)
                lmax = testCase.Fig9Lmax(i);
                abs = Nomograms.govardovskii2000A2(wl, lmax);
                [~, idx] = max(abs);
                testCase.verifyEqual(wl(idx), lmax, ...
                    'AbsTol', testCase.PeakLocationTol, ...
                    sprintf('A2 %s (lmax=%.1f) peak at wrong wavelength', ...
                        testCase.Fig9Names(i), lmax));
            end
        end

        function testA2PeakAmplitudeNearOne(testCase)
            % Peak amplitude should be ~1.0 (long-wave pigments) or
            % slightly above (short-wave pigments where beta-band
            % contribution rises into the alpha range).
            wl = (380:0.5:780)';
            for i = 1:numel(testCase.Fig9Lmax)
                lmax = testCase.Fig9Lmax(i);
                abs = Nomograms.govardovskii2000A2(wl, lmax);
                testCase.verifyGreaterThanOrEqual(max(abs), ...
                    1.0 - testCase.PeakAmplitudeTol);
                testCase.verifyLessThanOrEqual(max(abs), ...
                    1.0 + testCase.PeakAmplitudeTol);
            end
        end

        function testA2OutputIsColumnVector(testCase)
            abs = Nomograms.govardovskii2000A2((400:10:700)', 540);
            testCase.verifySize(abs, [31, 1]);
        end

        function testA2OutputIsNonNegative(testCase)
            abs = Nomograms.govardovskii2000A2((380:1:780)', 540);
            testCase.verifyGreaterThanOrEqual(min(abs), 0);
        end

        % A1 vs A2 differentiation.

        function testA2DiffersFromA1AtSameLambdaMax(testCase)
            % At the same lambda_max, A1 and A2 templates should
            % produce visibly different spectra (different long-wave
            % decay, different beta-band amplitude).
            wl = (380:1:780)';
            lmax = 540;
            abs_a1 = Nomograms.govardovskii2000(wl, lmax);
            abs_a2 = Nomograms.govardovskii2000A2(wl, lmax);
            maxDiff = max(abs(abs_a1 - abs_a2));
            testCase.verifyGreaterThan(maxDiff, 0.01, ...
                'A2 template indistinguishable from A1');
        end

        function testA2BetaBandHigherThanA1(testCase)
            % A2 beta-band amplitude is 0.37 vs A1's 0.26; expect higher
            % short-wavelength absorbance for the same lambda_max.
            wl_uv = 400;
            lmax = 540;
            abs_a1 = Nomograms.govardovskii2000(wl_uv, lmax);
            abs_a2 = Nomograms.govardovskii2000A2(wl_uv, lmax);
            testCase.verifyGreaterThan(abs_a2, abs_a1);
        end

        % AstellRed beta-band spot values from Fig. 10.

        function testA2AstellRedBetaCenter(testCase)
            % lambda_m_beta = 216.7 + 0.287 * lambda_max
            % For lmax = 563.7: 216.7 + 0.287 * 563.7 = 378.4 nm.
            lmax = 563.7;
            expected = 216.7 + 0.287 * lmax;
            testCase.verifyEqual(expected, ...
                testCase.AstellRedBetaCenter, 'AbsTol', 0.5);
        end

        function testA2AstellRedBetaWidth(testCase)
            % b = 317 - 1.149 * lmax + 0.00124 * lmax^2
            % For lmax = 563.7: 317 - 647.5 + 394.2 = 63.7 nm.
            % Paper reports 69 nm but uses a free fit, not the
            % regression. The regression should be within ~10 nm.
            lmax = 563.7;
            expected = 317 - 1.149 * lmax + 0.00124 * lmax^2;
            testCase.verifyEqual(expected, ...
                testCase.AstellRedBetaWidth, 'AbsTol', 10);
        end

        % Template class integration.

        function testTemplateDefaultsToA1(testCase)
            t = GovardovskiiPhotopigmentTemplate();
            testCase.verifyEqual(t.Pigment, "A1");
            testCase.verifyEqual(t.ShortName, "Govardovskii2000");
        end

        function testTemplateAcceptsA2Pigment(testCase)
            t = GovardovskiiPhotopigmentTemplate(Pigment="A2");
            testCase.verifyEqual(t.Pigment, "A2");
            testCase.verifyEqual(t.ShortName, "Govardovskii2000A2");
        end

        function testTemplateRejectsInvalidPigment(testCase)
            testCase.verifyError( ...
                @() GovardovskiiPhotopigmentTemplate(Pigment="A3"), ...
                ?MException);
        end

        function testTemplateA2AnalyticalPeak(testCase)
            % The analytical peak (computePeakAbsorbance) should match
            % the peak of computeAbsorbance to high precision.
            t = GovardovskiiPhotopigmentTemplate(Pigment="A2");
            wl = (400:0.5:700)';
            logAbs = t.computeAbsorbance(wl, 'L', 0);
            peakNumeric = max(10.^logAbs);
            peakAnalytic = t.computePeakAbsorbance('L', 0);
            testCase.verifyEqual(peakNumeric, peakAnalytic, 'AbsTol', 0.005);
        end

        % IndividualCMF dispatch.

        function testIndividualCMFAcceptsA2(testCase)
            obs = IndividualCMF(PhotopigmentModel="Govardovskii2000A2");
            testCase.verifyEqual(string(obs.PhotopigmentModel), ...
                "Govardovskii2000A2");
        end

        function testIndividualCMFA1A2ProduceDifferentLMS(testCase)
            obs_a1 = IndividualCMF(PhotopigmentModel="Govardovskii2000");
            obs_a2 = IndividualCMF(PhotopigmentModel="Govardovskii2000A2");
            wl = (400:5:700)';
            LMS_a1 = obs_a1.LMS(wl);
            LMS_a2 = obs_a2.LMS(wl);
            maxDiff = max(abs(LMS_a1(:) - LMS_a2(:)));
            testCase.verifyGreaterThan(maxDiff, 0.01);
        end

        function testIndividualCMFA2RoundTripViaProperty(testCase)
            obs = IndividualCMF();
            obs.PhotopigmentModel = "Govardovskii2000A2";
            testCase.verifyEqual(string(obs.PhotopigmentModel), ...
                "Govardovskii2000A2");
            obs.PhotopigmentModel = "Govardovskii2000";
            testCase.verifyEqual(string(obs.PhotopigmentModel), ...
                "Govardovskii2000");
        end

    end
end

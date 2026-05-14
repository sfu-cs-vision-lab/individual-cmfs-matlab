classdef LuminanceTest < matlab.unittest.TestCase
    % LuminanceTest  Verifies IndividualCMF.Luminance.
    %
    %   These tests pin the photopic luminous efficiency function
    %   V*(lambda) against published values from CIE 170-2:2015 and
    %   Sharpe et al. (2005): peak value and location for both
    %   standard observers, matrix-row consistency with the CIE
    %   LMS-to-XYZ transform, independence from the observer's
    %   OutputFormat / LogOutput settings, and analytic reductions
    %   for protanope, deuteranope, and tritanope observers.

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada
    %
    % This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    % Licensed under AGPL-3.0-or-later. See LICENSE file for details.

    properties (Constant)
        % Stockman-Rider 2023 Fourier-fit residual vs the CIE tables.
        % V*(555) peaks near 1.0 with up to 1-2 percent deviation from
        % the underlying tabulated CIE 170-2:2015 values.
        SR2023Tol = 0.02
    end

    methods (Test)

        % Peak value and location.

        function testLuminance2DegPeaksNearOne(testCase)
            obs = IndividualCMF(StandardObserver=2);
            wl = (380:1:780)';
            lum = obs.Luminance(wl);
            [peak, idx] = max(lum);
            testCase.verifyEqual(peak, 1.0, 'AbsTol', testCase.SR2023Tol);
            testCase.verifyEqual(wl(idx), 555, 'AbsTol', 5);
        end

        function testLuminance10DegPeaksNearOne(testCase)
            obs = IndividualCMF(StandardObserver=10);
            wl = (380:1:780)';
            lum = obs.Luminance(wl);
            [peak, idx] = max(lum);
            testCase.verifyEqual(peak, 1.0, 'AbsTol', testCase.SR2023Tol);
            testCase.verifyEqual(wl(idx), 555, 'AbsTol', 5);
        end

        function testLuminanceOutputShape(testCase)
            obs = IndividualCMF();
            wl = (400:10:700)';
            lum = obs.Luminance(wl);
            testCase.verifySize(lum, [numel(wl), 1]);
        end

        function testLuminanceNonNegative(testCase)
            obs = IndividualCMF();
            lum = obs.Luminance((380:1:780)');
            testCase.verifyGreaterThanOrEqual(min(lum), 0);
        end

        % Matrix-row consistency with CIE 170-2:2015.

        function testLuminanceMatchesM2DegRow2(testCase)
            % V*(lambda) for the 2-deg observer is the y-bar row of
            % CIE170.M_2DEG applied to energy-normalized LMS.
            obs = IndividualCMF(StandardObserver=2);
            wl = (400:5:700)';
            LMS = obs.LMS(wl, OutputFormat="energy", ...
                NormalizeOutput=true, LogOutput=false);
            expected = LMS * CIE170.M_2DEG(2, :)';
            actual = obs.Luminance(wl);
            testCase.verifyEqual(actual, expected, 'AbsTol', 1e-10);
        end

        function testLuminanceMatchesM10DegRow2(testCase)
            obs = IndividualCMF(StandardObserver=10);
            wl = (400:5:700)';
            LMS = obs.LMS(wl, OutputFormat="energy", ...
                NormalizeOutput=true, LogOutput=false);
            expected = LMS * CIE170.M_10DEG(2, :)';
            actual = obs.Luminance(wl);
            testCase.verifyEqual(actual, expected, 'AbsTol', 1e-10);
        end

        % Dichromat reductions.

        function testProtanopeLuminanceIsBTimesM(testCase)
            % Protanope (Lod=0): V*(lambda) = b*Mbar(lambda).
            obs = IndividualCMF(Lod=0);
            wl = (450:10:650)';
            kM = CIE170.M_10DEG(2, 2);
            mbar = obs.LMS(wl, OutputFormat="energy", ...
                NormalizeOutput=true, LogOutput=false);
            expected = kM * mbar(:, 2);
            testCase.verifyEqual(obs.Luminance(wl), expected, 'AbsTol', 1e-10);
        end

        function testDeuteranopeLuminanceIsATimesL(testCase)
            obs = IndividualCMF(Mod=0);
            wl = (450:10:650)';
            kL = CIE170.M_10DEG(2, 1);
            lbar = obs.LMS(wl, OutputFormat="energy", ...
                NormalizeOutput=true, LogOutput=false);
            expected = kL * lbar(:, 1);
            testCase.verifyEqual(obs.Luminance(wl), expected, 'AbsTol', 1e-10);
        end

        function testTritanopeLuminanceMatchesStandard(testCase)
            % S not in V*(lambda), so a tritanope sees the same V* as
            % the standard observer.
            standard = IndividualCMF();
            tritanope = IndividualCMF(Sod=0);
            wl = (450:10:650)';
            testCase.verifyEqual(tritanope.Luminance(wl), ...
                standard.Luminance(wl), 'AbsTol', 1e-10);
        end

        % Independence from observer output settings.

        function testLuminanceIgnoresOutputFormat(testCase)
            obs1 = IndividualCMF();
            obs1.OutputFormat = "energy";
            obs2 = IndividualCMF();
            obs2.OutputFormat = "quantal";
            wl = (450:10:650)';
            testCase.verifyEqual(obs1.Luminance(wl), obs2.Luminance(wl), ...
                'AbsTol', 1e-10);
        end

        function testLuminanceIgnoresLogOutput(testCase)
            obs1 = IndividualCMF(LogOutput=false);
            obs2 = IndividualCMF(LogOutput=true);
            wl = (450:10:650)';
            testCase.verifyEqual(obs1.Luminance(wl), obs2.Luminance(wl), ...
                'AbsTol', 1e-10);
        end

    end
end

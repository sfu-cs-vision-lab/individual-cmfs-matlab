classdef GetMacularDensitySpectrumTest < matlab.unittest.TestCase
    % GETMACULARDENSITYSPECTRUMTEST  Unit tests for IndividualCMF.getMacularDensitySpectrum.
    %
    %   Verifies that the macular pigment optical density spectrum is
    %   returned correctly for default and custom observers, that the
    %   dichromat case does not affect MacularDensity, and that
    %   wavelengths outside the template-defined range return zero.

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada
    %
    % This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    % Licensed under AGPL-3.0-or-later. See LICENSE file for details.

    methods (Test)
        function testDefaultObserver(testCase)
            % Default 2-deg observer: value at 460 nm matches MacularDensity
            % (the template is unit-normalized at 460 nm).
            obs = IndividualCMF();
            wl = (380:1:780)';
            spectrum = obs.getMacularDensitySpectrum(wl);

            testCase.verifyEqual(size(spectrum), size(wl));
            testCase.verifyTrue(all(spectrum >= 0));
            testCase.verifyTrue(all(isfinite(spectrum)));

            value460 = spectrum(wl == 460);
            testCase.verifyEqual(value460, obs.MacularDensity, 'AbsTol', 1e-9);
        end

        function testMatchesManualComputation(testCase)
            % Output equals MacularDensity * template (the documented identity).
            obs = IndividualCMF();
            wl = (400:5:550)';
            template = StockmanRider2023MacularTemplate().computeTemplate(wl);
            expected = obs.MacularDensity * template;
            actual = obs.getMacularDensitySpectrum(wl);
            testCase.verifyEqual(actual, expected, 'AbsTol', 1e-12);
        end

        function testCustomMacularDensity(testCase)
            % Scaling MacularDensity scales the spectrum linearly.
            obs = IndividualCMF();
            wl = (400:10:550)';
            base = obs.getMacularDensitySpectrum(wl);
            obs.MacularDensity = 2 * obs.MacularDensity;
            scaled = obs.getMacularDensitySpectrum(wl);
            testCase.verifyEqual(scaled, 2 * base, 'AbsTol', 1e-12);
        end

        function testMacularDensityZero(testCase)
            % Zero macular density yields an all-zero spectrum.
            obs = IndividualCMF();
            obs.MacularDensity = 0;
            wl = (400:10:550)';
            spectrum = obs.getMacularDensitySpectrum(wl);
            testCase.verifyEqual(spectrum, zeros(size(wl)), 'AbsTol', 0);
        end

        function testDichromatPreservesMacularDensity(testCase)
            % Setting Sod=0 (S-cone dichromat) leaves MacularDensity unchanged.
            obs = IndividualCMF();
            originalDensity = obs.MacularDensity;
            obs.Sod = 0;
            testCase.verifyEqual(obs.MacularDensity, originalDensity, 'AbsTol', 1e-12);

            wl = (400:10:550)';
            template = StockmanRider2023MacularTemplate().computeTemplate(wl);
            expected = originalDensity * template;
            testCase.verifyEqual(obs.getMacularDensitySpectrum(wl), expected, ...
                'AbsTol', 1e-12);
        end

        function testZeroOutsideTemplateRange(testCase)
            % Wavelengths outside the template's defined range (375-550 nm)
            % return zero.
            obs = IndividualCMF();
            wlBelow = (300:10:370)';
            wlAbove = (560:10:780)';
            specBelow = obs.getMacularDensitySpectrum(wlBelow);
            specAbove = obs.getMacularDensitySpectrum(wlAbove);
            testCase.verifyEqual(specBelow, zeros(size(wlBelow)), 'AbsTol', 0);
            testCase.verifyEqual(specAbove, zeros(size(wlAbove)), 'AbsTol', 0);
        end

        function testFieldSizeAffectsMacularDensity(testCase)
            % A 10-deg observer has lower macular density than 2-deg.
            obs2 = IndividualCMF(FieldSize=2);
            obs10 = IndividualCMF(FieldSize=10);
            wl = 460;
            peak2 = obs2.getMacularDensitySpectrum(wl);
            peak10 = obs10.getMacularDensitySpectrum(wl);
            testCase.verifyLessThan(peak10, peak2);
        end
    end
end

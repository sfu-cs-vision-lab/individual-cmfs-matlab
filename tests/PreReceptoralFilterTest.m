classdef PreReceptoralFilterTest < matlab.unittest.TestCase
    % PRERECEPTORALFILTERTEST  Unit tests for PreReceptoralFilter class.
    %
    %   Tests cover:
    %   - Default and custom construction for macular filters
    %   - Density spectrum calculation
    %   - Transmission calculations (10^-density)
    %   - Static macular template method
    %   - Verification against CIE 170-1:2006

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada
    %
    % This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    % Licensed under AGPL-3.0-or-later. See LICENSE file for details.
    % Repository: https://github.com/sfu-cs-vision-lab/Individual-CMFs

    properties (Constant)
        % Standard test wavelengths
        TestWavelengths = (390:830)'

        % Tolerance for floating point comparisons
        RelTol = 1e-10
        AbsTol = 1e-12
    end

    methods (Test)

        function testDefaultConstruction(testCase)
            filter = PreReceptoralFilter();

            testCase.verifyEqual(filter.Type, "macular", ...
                'Default Type should be "macular"');
            testCase.verifyEqual(filter.Density, 1.0, ...
                'Default Density should be 1.0');
        end

        function testMacularConstruction(testCase)
            % Test explicit construction of macular filter
            filter = PreReceptoralFilter(Type="macular");

            testCase.verifyEqual(filter.Type, "macular", ...
                'Type should be "macular"');
            testCase.verifyEqual(filter.Density, 1.0, ...
                'Default Density should be 1.0');
        end

        function testConstructionWithCustomDensity(testCase)
            % Test construction with custom density value
            filter = PreReceptoralFilter(Type="macular", Density=0.5);

            testCase.verifyEqual(filter.Density, 0.5, ...
                'Density should be set to custom value');
        end

        function testMacularDensitySpectrumShape(testCase)
            wl = testCase.TestWavelengths;
            filter = PreReceptoralFilter(Type="macular");
            spectrum = filter.getDensitySpectrum(wl);

            testCase.verifySize(spectrum, size(wl), ...
                'Spectrum should have same size as wavelengths');

            testCase.verifyTrue(all(spectrum >= 0), ...
                'Macular density should be non-negative');

            density700 = spectrum(wl == 700);
            testCase.verifyEqual(density700, 0, 'AbsTol', testCase.AbsTol, ...
                'Macular density should be zero at 700nm');
        end

        function testTransmissionCalculation(testCase)
            wl = testCase.TestWavelengths;
            filter = PreReceptoralFilter(Type="macular");

            density = filter.getDensitySpectrum(wl);
            transmission = filter.getTransmission(wl);

            expected = 10.^(-density);
            testCase.verifyEqual(transmission, expected, ...
                'RelTol', testCase.RelTol, ...
                'Transmission should equal 10^(-density)');
        end

        function testTransmissionRange(testCase)
            wl = testCase.TestWavelengths;
            filter = PreReceptoralFilter(Type="macular");
            transmission = filter.getTransmission(wl);

            testCase.verifyGreaterThanOrEqual(transmission, 0, ...
                'Transmission should be non-negative');
            testCase.verifyLessThanOrEqual(transmission, 1, ...
                'Transmission should not exceed 1');
        end

        function testDensityScaling(testCase)
            wl = testCase.TestWavelengths;
            filter1 = PreReceptoralFilter(Type="macular", Density=1.0);
            filter2 = PreReceptoralFilter(Type="macular", Density=2.0);

            spectrum1 = filter1.getDensitySpectrum(wl);
            spectrum2 = filter2.getDensitySpectrum(wl);

            testCase.verifyEqual(spectrum2, 2 * spectrum1, ...
                'RelTol', testCase.RelTol, ...
                'Density=2 should give twice the spectrum of Density=1');
        end

        function testStaticMacularTemplate(testCase)
            % Test static macular template method
            wl = (375:550)';
            template = PreReceptoralFilter.macularTemplate(wl);

            testCase.verifySize(template, size(wl), ...
                'Template should have same size as wavelengths');

            testCase.verifyTrue(all(template >= 0), ...
                'Template values should be non-negative');
        end

        function testMacularTemplateOutOfRange(testCase)
            wlLow = (300:374)';
            wlHigh = (551:700)';

            templateLow = PreReceptoralFilter.macularTemplate(wlLow);
            templateHigh = PreReceptoralFilter.macularTemplate(wlHigh);

            testCase.verifyEqual(templateLow, zeros(size(wlLow)), ...
                'Macular template should be zero below 375nm');
            testCase.verifyEqual(templateHigh, zeros(size(wlHigh)), ...
                'Macular template should be zero above 550nm');
        end

        function testIsValueClass(testCase)
            filter1 = PreReceptoralFilter(Density=1.0);
            filter2 = filter1;
            filter2.Density = 2.0;

            testCase.verifyEqual(filter1.Density, 1.0, ...
                'Value class: modifying copy should not affect original');
            testCase.verifyEqual(filter2.Density, 2.0, ...
                'Value class: copy should have modified value');
        end

        function testNegativeDensityNotAllowed(testCase)
            testCase.verifyError(@() PreReceptoralFilter(Density=-0.5), ...
                'MATLAB:validators:mustBeNonnegative');
        end

        function testZeroDensityIsValid(testCase)
            filter = PreReceptoralFilter(Density=0);

            testCase.verifyEqual(filter.Density, 0, ...
                'Zero density should be valid');

            wl = testCase.TestWavelengths;
            spectrum = filter.getDensitySpectrum(wl);
            testCase.verifyEqual(spectrum, zeros(size(wl)), ...
                'Zero density should give zero spectrum');
        end

        function testInvalidTypeNotAllowed(testCase)
            testCase.verifyError(@() PreReceptoralFilter(Type="invalid"), ...
                'MATLAB:validators:mustBeMember');
        end

        function testLensTypeAllowedButGetDensityErrors(testCase)
            % Lens filter type is accepted for backward compatibility, but
            % getDensitySpectrum errors and directs callers to LensTemplate.
            filter = PreReceptoralFilter(Type="lens", Density=1.0, Age=32);
            testCase.verifyEqual(filter.Type, "lens");

            wl = testCase.TestWavelengths;
            testCase.verifyError(@() filter.getDensitySpectrum(wl), ...
                'PreReceptoralFilter:UseLensTemplate');
        end

        function testMacularTemplateCoefficientsLength(testCase)
            % Verify macular coefficients have correct length. Coefficients
            % migrated to the StockmanRider2023MacularTemplate strategy class.
            testCase.verifyLength(StockmanRider2023MacularTemplate.MACULAR_COEFFICIENTS, 24, ...
                'Macular coefficients should have 24 elements');
        end

        function testScalarWavelengthInput(testCase)
            filter = PreReceptoralFilter(Type="macular");
            spectrum = filter.getDensitySpectrum(460);

            testCase.verifySize(spectrum, [1 1], ...
                'Single wavelength should return scalar');
            testCase.verifyGreaterThan(spectrum, 0, ...
                'Macular density at 460nm should be positive');
        end

        function testEmptyWavelengthInput(testCase)
            % Test behavior with empty wavelength input
            filter = PreReceptoralFilter(Type="macular");
            spectrum = filter.getDensitySpectrum(zeros(0,1));

            testCase.verifyEmpty(spectrum, ...
                'Empty input should return empty output');
        end

        function testMacularPeakNear460nm(testCase)
            % Verify macular pigment absorption peaks near 460nm
            wl = (375:550)';
            template = PreReceptoralFilter.macularTemplate(wl);

            [~, peakIdx] = max(template);
            peakWl = wl(peakIdx);

            testCase.verifyLessThan(abs(peakWl - 460), 20, ...
                'Macular pigment peak should be near 460nm');
        end

        function testDensitySpectrumValueAt460nmMatchesRequestedDensity(testCase)
            % Regression: getDensitySpectrum(D) must produce a spectrum
            % whose value at 460 nm equals D. Earlier the code multiplied
            % an already-absolute Stockman-Rider template (= 0.350 OD at
            % 460 nm) by the user-supplied Density, double-scaling and
            % producing 460-nm OD = D * 0.350 instead of D.
            % (See PreReceptoralFilter macular-scaling fix.)
            for D = [0.10, 0.35, 1.0]
                filter = PreReceptoralFilter(Type="macular", Density=D);
                value460 = filter.getDensitySpectrum(460);
                testCase.verifyEqual(value460, D, 'AbsTol', 1e-8, ...
                    sprintf(['getDensitySpectrum(D=%.2f) at 460 nm ' ...
                             'should be %.3f, not %.3f * 0.350.'], ...
                             D, D, D));
            end
        end

        function testMacular(testCase)
            % Verify macular pigment template matches reference data
            folder = fileparts(mfilename('fullpath'));
            refData = readtable(fullfile(folder, 'data', 'cmf_verification_data.csv'));
            matlabRes = PreReceptoralFilter.macularTemplate(refData.nm);
            testCase.verifyEqual(matlabRes, refData.macular, ...
                'AbsTol', 1e-10, 'Macular function mismatch');
        end

        function testLens(testCase)
            % Verify lens template matches reference data.
            % The reference data is the raw Fourier template (not normalized to 1 at 400nm)
            % so we need to denormalize the StockmanRiderLensTemplate output.
            folder = fileparts(mfilename('fullpath'));
            refData = readtable(fullfile(folder, 'data', 'cmf_verification_data.csv'));
            % Suppress wavelength-out-of-range warnings that fire when the
            % reference grid extends beyond template support.
            testCase.applyFixture( ...
                matlab.unittest.fixtures.SuppressedWarningsFixture({ ...
                    'IndividualCMF:WavelengthOutOfRange', ...
                    'Nomograms:WavelengthOutOfRange'}));
            lensTemplate = StockmanRiderLensTemplate();
            normalizedTemplate = lensTemplate.computeTemplate(refData.nm, 32);
            matlabRes = normalizedTemplate * CIE170.STD_LENS_DENSITY_400;
            testCase.verifyEqual(matlabRes, refData.lens, ...
                'AbsTol', 1e-10, 'Lens function mismatch');
        end

        function testMacularTemplateIsAbsoluteAt460nm(testCase)
            % The static macularTemplate is documented as absolute, with
            % peak at STD_MACULAR_DENSITY_460 (= 0.350). Lock the contract
            % so a future "normalize the template" change must update
            % every caller (incl. IndividualCMF.computeSensitivityCore).
            template = PreReceptoralFilter.macularTemplate(460);
            testCase.verifyEqual(template, ...
                CIE170.STD_2DEG_MACULAR_DENSITY, 'AbsTol', 1e-3, ...
                'macularTemplate(460) should equal STD_MACULAR_DENSITY_460.');
        end

    end
end

classdef LensTemplateTest < matlab.unittest.TestCase
    % LENSTEMPLATETEST  Unit tests for LensTemplate and StockmanRiderLensTemplate.
    %
    %   This test class verifies the behavior of the LensTemplate abstract
    %   base class and the StockmanRiderLensTemplate concrete implementation.

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada
    %
    % This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    % Licensed under AGPL-3.0-or-later. See LICENSE file for details.

    methods (Test)
        %% StockmanRiderLensTemplate Tests

        function testSR_ImplementsInterface(testCase)
            % Verify StockmanRiderLensTemplate is a subclass of LensTemplate
            template = StockmanRiderLensTemplate();
            testCase.verifyInstanceOf(template, 'LensTemplate');
        end

        function testSR_ShortName(testCase)
            % Verify the ShortName property
            template = StockmanRiderLensTemplate();
            testCase.verifyEqual(template.ShortName, "StockmanRider2023");
        end

        function testSR_Name(testCase)
            % Verify the Name property
            template = StockmanRiderLensTemplate();
            testCase.verifyEqual(template.Name, "Stockman & Rider (2023) Lens Template");
        end

        function testSR_TemplateNormalizedAt400(testCase)
            % Verify template is normalized to 1.0 at 400nm
            template = StockmanRiderLensTemplate();
            val = template.computeTemplate(400, 32);
            testCase.verifyEqual(val, 1.0, 'AbsTol', 1e-10);
        end

        function testSR_TemplateShapeAgeInvariant(testCase)
            % Shape should NOT change with age for StockmanRider
            template = StockmanRiderLensTemplate();
            wl = (390:5:700)';
            shape32 = template.computeTemplate(wl, 32);
            shape60 = template.computeTemplate(wl, 60);
            shape80 = template.computeTemplate(wl, 80);
            testCase.verifyEqual(shape32, shape60, 'AbsTol', 1e-10);
            testCase.verifyEqual(shape32, shape80, 'AbsTol', 1e-10);
        end

        function testSR_DensityAt400AgeInvariant(testCase)
            % computeDensityAt400 should return STD_LENS_DENSITY_400 regardless of age
            template = StockmanRiderLensTemplate();
            testCase.verifyEqual(template.computeDensityAt400(32), 1.7649, 'AbsTol', 1e-4);
            testCase.verifyEqual(template.computeDensityAt400(60), 1.7649, 'AbsTol', 1e-4);
            testCase.verifyEqual(template.computeDensityAt400(80), 1.7649, 'AbsTol', 1e-4);
        end

        function testSR_DoesNotSupportAging(testCase)
            % SupportsAging should be false
            template = StockmanRiderLensTemplate();
            testCase.verifyFalse(template.SupportsAging);
        end

        function testSR_VectorWavelengths(testCase)
            % Verify template works with vector wavelengths
            template = StockmanRiderLensTemplate();
            wl = (380:10:700)';
            result = template.computeTemplate(wl, 32);
            testCase.verifySize(result, size(wl));
            testCase.verifyTrue(all(result >= 0));
        end

        function testSR_ScalarWavelength(testCase)
            % Verify template works with scalar wavelength
            template = StockmanRiderLensTemplate();
            result = template.computeTemplate(450, 32);
            testCase.verifySize(result, [1, 1]);
        end

        function testSR_ZeroAboveLensLimit(testCase)
            % Verify template returns zero above the lens upper limit (660nm)
            template = StockmanRiderLensTemplate();
            wl = (650:5:700)';
            result = template.computeTemplate(wl, 32);

            % Values at 660nm and below should be positive
            testCase.verifyTrue(result(1) > 0);
            testCase.verifyTrue(result(2) > 0);
            testCase.verifyTrue(result(3) > 0);

            % Values above 660nm should be zero
            testCase.verifyEqual(result(end-2:end), [0; 0; 0], 'AbsTol', 1e-10);
        end

        function testSR_DecreasingWithWavelength(testCase)
            % Verify template generally decreases with increasing wavelength
            template = StockmanRiderLensTemplate();
            wl = (400:20:600)';
            result = template.computeTemplate(wl, 32);

            % Template should be monotonically decreasing in this range
            diffs = diff(result);
            testCase.verifyTrue(all(diffs < 0), ...
                'Template should decrease with increasing wavelength in 400-600nm range');
        end

        function testSR_DensityAt400EqualsStandardConstant(testCase)
            % StockmanRider returns the standard lens density for all ages
            % because this model does not include age-dependent lens changes
            template = StockmanRiderLensTemplate();
            testCase.verifyEqual(template.computeDensityAt400(20), CIE170.STD_LENS_DENSITY_400, 'AbsTol', 1e-10);
            testCase.verifyEqual(template.computeDensityAt400(32), CIE170.STD_LENS_DENSITY_400, 'AbsTol', 1e-10);
            testCase.verifyEqual(template.computeDensityAt400(60), CIE170.STD_LENS_DENSITY_400, 'AbsTol', 1e-10);
            testCase.verifyEqual(template.computeDensityAt400(80), CIE170.STD_LENS_DENSITY_400, 'AbsTol', 1e-10);
        end

        function testSR_DefaultAgeParameter(testCase)
            % Verify default age parameter works
            template = StockmanRiderLensTemplate();
            wl = (400:50:600)';

            % These should produce identical results
            resultWithAge = template.computeTemplate(wl, 32);
            resultDefaultAge = template.computeTemplate(wl);

            testCase.verifyEqual(resultWithAge, resultDefaultAge, 'AbsTol', 1e-10);
        end
    end
end

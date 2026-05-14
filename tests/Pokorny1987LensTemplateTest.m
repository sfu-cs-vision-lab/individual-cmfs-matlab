classdef Pokorny1987LensTemplateTest < matlab.unittest.TestCase
    % POKORNY1987LENSTEMPLATETEST  Unit tests for Pokorny1987LensTemplate class.
    %
    %   Tests verify:
    %   - Table I values at tabulated wavelengths
    %   - Age factor computation
    %   - Template normalization
    %   - Interpolation between tabulated wavelengths
    %   - Age-dependent template shape changes

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada
    %
    % This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    % Licensed under AGPL-3.0-or-later. See LICENSE file for details.

    properties (Constant)
        RelTol = 1e-10
        AbsTol = 1e-12
    end

    methods (Test)

        function testNameProperties(testCase)
            % Verify Name and ShortName are correct
            t = Pokorny1987LensTemplate();
            testCase.verifyEqual(t.Name, "Pokorny, Smith & Lutze (1987)");
            testCase.verifyEqual(t.ShortName, "Pokorny1987");
        end

        function testSupportsAging(testCase)
            % Verify SupportsAging is true
            t = Pokorny1987LensTemplate();
            testCase.verifyTrue(t.SupportsAging);
        end

        function testTemplateNormalizedTo1At400nm(testCase)
            % Template should equal 1.0 at 400nm for any age
            t = Pokorny1987LensTemplate();
            ages = [20, 32, 45, 60, 75];
            for age = ages
                template = t.computeTemplate(400, age);
                testCase.verifyEqual(template, 1.0, 'AbsTol', testCase.AbsTol, ...
                    sprintf('Template should be 1.0 at 400nm for age %d', age));
            end
        end

        function testDensityAt400Age32(testCase)
            % At age 32, density should equal TL1 + TL2 = 0.600 + 1.000 = 1.600
            t = Pokorny1987LensTemplate();
            density = t.computeDensityAt400(32);
            testCase.verifyEqual(density, 1.600, 'AbsTol', 1e-6);
        end

        function testDensityAt400Age60(testCase)
            % At age 60, density = TL1 * 1.56 + TL2 = 0.600 * 1.56 + 1.000 = 1.936
            t = Pokorny1987LensTemplate();
            density = t.computeDensityAt400(60);
            testCase.verifyEqual(density, 1.936, 'AbsTol', 1e-6);
        end

        function testTableIValuesAge32(testCase)
            % Verify density values match Table I for age 32
            t = Pokorny1987LensTemplate();

            % Table I wavelengths and expected total density (TL1 * 1.0 + TL2)
            wl = [400; 410; 420; 430; 440; 450; 460];
            tl1 = [0.600; 0.510; 0.433; 0.377; 0.327; 0.295; 0.267];
            tl2 = [1.000; 0.583; 0.300; 0.116; 0.033; 0.005; 0.000];
            expectedDensity = tl1 + tl2;

            % Get template and scale by density at 400nm to get absolute density
            template = t.computeTemplate(wl, 32);
            densityAt400 = t.computeDensityAt400(32);
            actualDensity = template * densityAt400;

            testCase.verifyEqual(actualDensity, expectedDensity, 'AbsTol', 1e-6);
        end

        function testAgeFactor20To60(testCase)
            % Verify age factor formula for ages 20-60
            % factor = 1 + 0.02 * (age - 32)
            t = Pokorny1987LensTemplate();

            % At age 20: factor = 1 + 0.02 * (20 - 32) = 1 - 0.24 = 0.76
            density20 = t.computeDensityAt400(20);
            expected20 = 0.600 * 0.76 + 1.000;
            testCase.verifyEqual(density20, expected20, 'AbsTol', 1e-6);

            % At age 32: factor = 1.0
            density32 = t.computeDensityAt400(32);
            expected32 = 0.600 * 1.0 + 1.000;
            testCase.verifyEqual(density32, expected32, 'AbsTol', 1e-6);

            % At age 52: factor = 1 + 0.02 * (52 - 32) = 1.4
            density52 = t.computeDensityAt400(52);
            expected52 = 0.600 * 1.4 + 1.000;
            testCase.verifyEqual(density52, expected52, 'AbsTol', 1e-6);
        end

        function testAgeFactorContinuityAt60(testCase)
            % Verify continuity at age 60
            t = Pokorny1987LensTemplate();

            densityJustBefore = t.computeDensityAt400(59.999);
            densityAt60 = t.computeDensityAt400(60);
            densityJustAfter = t.computeDensityAt400(60.001);

            % Should be continuous
            testCase.verifyEqual(densityJustBefore, densityAt60, 'AbsTol', 1e-3);
            testCase.verifyEqual(densityAt60, densityJustAfter, 'AbsTol', 1e-3);
        end

        function testAgeFactorAfter60(testCase)
            % Verify age factor formula for ages > 60
            % factor = 1.56 + 0.0667 * (age - 60)
            t = Pokorny1987LensTemplate();

            % At age 75: factor = 1.56 + 0.0667 * 15 = 2.5605
            density75 = t.computeDensityAt400(75);
            expected75 = 0.600 * 2.5605 + 1.000;
            testCase.verifyEqual(density75, expected75, 'AbsTol', 1e-3);
        end

        function testTemplateShapeChangesWithAge(testCase)
            % Verify that template SHAPE changes with age
            % This is because TL2 (age-invariant) only contributes at short wavelengths
            t = Pokorny1987LensTemplate();
            wl = (400:10:500)';

            template32 = t.computeTemplate(wl, 32);
            template60 = t.computeTemplate(wl, 60);

            % Templates should NOT be identical (unlike StockmanRider which is age-invariant)
            testCase.verifyNotEqual(template32, template60, ...
                'Template shape should change with age');
        end

        function testTL2OnlyAffects400to450nm(testCase)
            % Verify TL2 contribution only affects 400-450nm range
            t = Pokorny1987LensTemplate();

            % At wavelengths > 450nm, TL2 = 0, so template shape is purely from TL1
            % and should scale linearly with age factor
            wl500 = 500;

            template32at500 = t.computeTemplate(wl500, 32);
            template60at500 = t.computeTemplate(wl500, 60);

            % Get the raw densities
            density32 = t.computeDensityAt400(32);
            density60 = t.computeDensityAt400(60);

            % At 500nm, only TL1 contributes, so absolute density scales with age factor
            % TL1 at 500nm = 0.167 (from Table I)
            % Age 32: density = 0.167 * 1.0 = 0.167
            % Age 60: density = 0.167 * 1.56 = 0.26052

            absActual32 = template32at500 * density32;
            absActual60 = template60at500 * density60;

            testCase.verifyEqual(absActual32, 0.167, 'AbsTol', 1e-6);
            testCase.verifyEqual(absActual60, 0.167 * 1.56, 'AbsTol', 1e-3);
        end

        function testInterpolationBetweenTableValues(testCase)
            % Verify linear interpolation between tabulated wavelengths
            t = Pokorny1987LensTemplate();

            % At 405nm (midpoint between 400 and 410)
            template = t.computeTemplate([400; 405; 410], 32);

            % Should interpolate linearly
            expected405 = (template(1) + template(3)) / 2;
            testCase.verifyEqual(template(2), expected405, 'AbsTol', 1e-6);
        end

        function testZeroDensityAt650nm(testCase)
            % TL1 and TL2 are both zero at 650nm
            t = Pokorny1987LensTemplate();
            template = t.computeTemplate(650, 32);
            testCase.verifyEqual(template, 0, 'AbsTol', testCase.AbsTol);
        end

        function testTemplateMonotonicallyDecreasing(testCase)
            % Template should generally decrease from 400nm to longer wavelengths
            t = Pokorny1987LensTemplate();
            wl = (400:10:650)';
            template = t.computeTemplate(wl, 32);

            % Check that each value is >= the next (allowing for small floating point differences)
            diffs = diff(template);
            testCase.verifyTrue(all(diffs <= 1e-10), ...
                'Template should be monotonically decreasing');
        end

        function testInheritsFromLensTemplate(testCase)
            % Verify inheritance from LensTemplate
            t = Pokorny1987LensTemplate();
            testCase.verifyTrue(isa(t, 'LensTemplate'));
        end

    end
end

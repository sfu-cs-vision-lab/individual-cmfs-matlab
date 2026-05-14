classdef VanDeKraatsVanNorren2007LensTemplateTest < matlab.unittest.TestCase
    % VANDEKRAATSVANNORREN2007LENSTEMPLATETEST  Unit tests for the vdK&vN 2007 lens template.
    %
    %   Tests verify:
    %   - Class metadata (Name, ShortName, SupportsAging, inheritance).
    %   - Template normalization (1.0 at 400 nm for any age).
    %   - Density at 400 nm matches Eq. 8 evaluated by hand at age 0, 32, 70.
    %   - Age scaling is quadratic (not linear).
    %   - Template shape changes with age (shape is age-dependent).
    %   - Long-wavelength tail follows the Rayleigh + neutral-offset
    %     baseline (vdK&vN does not vanish at 650 nm the way Pokorny does).

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada
    %
    % This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    % Licensed under AGPL-3.0-or-later. See LICENSE file for details.

    properties (Constant)
        AbsTol = 1e-12
    end

    methods (Test)

        function testNameProperties(testCase)
            t = VanDeKraatsVanNorren2007LensTemplate();
            testCase.verifyEqual(t.Name, "van de Kraats & van Norren (2007)");
            testCase.verifyEqual(t.ShortName, "VanDeKraats2007");
        end

        function testSupportsAging(testCase)
            t = VanDeKraatsVanNorren2007LensTemplate();
            testCase.verifyTrue(t.SupportsAging);
        end

        function testInheritsFromLensTemplate(testCase)
            t = VanDeKraatsVanNorren2007LensTemplate();
            testCase.verifyTrue(isa(t, 'LensTemplate'));
        end

        function testTemplateNormalizedTo1At400nm(testCase)
            % computeTemplate must return exactly 1.0 at 400 nm for any age.
            t = VanDeKraatsVanNorren2007LensTemplate();
            ages = [1, 20, 32, 50, 70, 80];
            for age = ages
                template = t.computeTemplate(400, age);
                testCase.verifyEqual(template, 1.0, 'AbsTol', testCase.AbsTol, ...
                    sprintf('Template should be 1.0 at 400 nm for age %d', age));
            end
        end

        function testDensityAt400Age0(testCase)
            % Hand-computed: D(400, age=0) per Eq. 8.
            % d_i = d_{i,0} (no age contribution); component values at 400
            % nm: M_RL=1, M_TP~0, M_LY~0.9992, M_LOUV~1.0001, M_LO~0.9978;
            % plus d_neutral=0.111. Sum is approximately 1.629.
            t = VanDeKraatsVanNorren2007LensTemplate();
            density = t.computeDensityAt400(0.001);  % effectively age 0
            testCase.verifyEqual(density, 1.629, 'AbsTol', 5e-3);
        end

        function testDensityAt400Age32(testCase)
            % Hand-computed: D(400, age=32) per Eq. 8 with quadratic aging.
            % Approximately 1.92 OD.
            t = VanDeKraatsVanNorren2007LensTemplate();
            density = t.computeDensityAt400(32);
            testCase.verifyEqual(density, 1.92, 'AbsTol', 0.05);
        end

        function testDensityAt400Age70(testCase)
            % Hand-computed: D(400, age=70) per Eq. 8.
            % Approximately 3.03 OD.
            t = VanDeKraatsVanNorren2007LensTemplate();
            density = t.computeDensityAt400(70);
            testCase.verifyEqual(density, 3.03, 'AbsTol', 0.05);
        end

        function testDensityIncreasesWithAge(testCase)
            % Total density at 400 nm must increase monotonically with age.
            t = VanDeKraatsVanNorren2007LensTemplate();
            ages = (1:10:81)';
            densities = arrayfun(@(a) t.computeDensityAt400(a), ages);
            testCase.verifyTrue(all(diff(densities) > 0), ...
                'Density at 400 nm should increase monotonically with age');
        end

        function testAgeScalingIsQuadratic(testCase)
            % Verify alpha_i scaling is quadratic in age, not linear.
            % Take three ages (10, 30, 60) and check that the increase from
            % 10->30 (200 yr^2 of age^2) is much smaller than the increase
            % from 30->60 (2700 yr^2). For a linear model the ratio would
            % be 20:30 = 2:3; for quadratic it is 800:2700 ~= 0.30 (Pokorny
            % bilinear lies between).
            t = VanDeKraatsVanNorren2007LensTemplate();
            d10 = t.computeDensityAt400(10);
            d30 = t.computeDensityAt400(30);
            d60 = t.computeDensityAt400(60);

            ratio = (d30 - d10) / (d60 - d30);
            testCase.verifyLessThan(ratio, 0.4, ...
                'Age scaling appears linear, not quadratic');
        end

        function testTemplateShapeChangesWithAge(testCase)
            % vdK&vN's spectral shape shifts with age because the five
            % component coefficients each scale differently. Templates at
            % 32 vs 70 should differ.
            t = VanDeKraatsVanNorren2007LensTemplate();
            wl = (400:20:600)';
            template32 = t.computeTemplate(wl, 32);
            template70 = t.computeTemplate(wl, 70);
            testCase.verifyNotEqual(template32, template70, ...
                'Template shape should change with age');
        end

        function testRayleighTailNonZeroAt650nm(testCase)
            % vdK&vN includes (400/lambda)^4 Rayleigh scatter and a flat
            % d_neutral baseline. Unlike Pokorny 1987 (zero past 650 nm),
            % vdK&vN should retain a small positive density at 650 nm.
            t = VanDeKraatsVanNorren2007LensTemplate();
            template = t.computeTemplate(650, 32);
            testCase.verifyGreaterThan(template, 0.05, ...
                'vdK&vN tail at 650 nm should be non-trivially positive');
            testCase.verifyLessThan(template, 0.20, ...
                'vdK&vN tail at 650 nm should still be small');
        end

        function testTemplateMonotonicallyDecreasingInVisible(testCase)
            % Template is monotonically decreasing from 400 nm out to 700 nm
            % (the lens-old Gaussians and Rayleigh term both decrease there).
            t = VanDeKraatsVanNorren2007LensTemplate();
            wl = (400:10:700)';
            template = t.computeTemplate(wl, 32);
            diffs = diff(template);
            testCase.verifyTrue(all(diffs <= 1e-10), ...
                'Template should be monotonically decreasing 400-700 nm');
        end

        function testColumnVectorOutputShape(testCase)
            % Output shape should match input shape (column vector).
            t = VanDeKraatsVanNorren2007LensTemplate();
            wl = (400:10:600)';
            template = t.computeTemplate(wl, 32);
            testCase.verifySize(template, size(wl));
        end

        function testTryptophanComponentBelow320nm(testCase)
            % Density at 310 nm should be substantially higher than at 400
            % nm. Tryptophan peaks at 273 nm and "heavily absorbs below 310
            % nm" (paper p. 1843); at 310 nm itself, LOUV (peak 325 nm)
            % still dominates the absorption, so the density ratio is
            % moderate rather than extreme. Hand-evaluating Eq. 8 at age
            % 32 gives D(310)/D(400) ~ 6.22/1.92 ~ 3.24.
            t = VanDeKraatsVanNorren2007LensTemplate();
            template = t.computeTemplate(310, 32);
            testCase.verifyGreaterThan(template, 3, ...
                'Density at 310 nm should be much higher than at 400 nm');
        end

    end
end

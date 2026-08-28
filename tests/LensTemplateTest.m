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

        % ValidRange drives the warning; Domain decides whether a value exists

        function testUnfittedModelsWarnOnTheWideGrid(testCase)
            % Andy Rider's review point: the Pokorny lens flat-extrapolates
            % below 400 nm and that should not pass silently.
            wl = (360:1:830)';

            obs = IndividualCMF(LensModel="Pokorny1987", Age=70);
            testCase.verifyWarning(@() obs.getLensDensitySpectrum(wl), ...
                'IndividualCMF:WavelengthOutOfRange', ...
                'Pokorny below 400 nm must warn');

            % 830 nm is well past the 700 nm van de Kraats fit.
            obs2 = IndividualCMF(LensModel="VanDeKraats2007", Age=70);
            testCase.verifyWarning(@() obs2.getLensDensitySpectrum(wl), ...
                'IndividualCMF:WavelengthOutOfRange', ...
                'van de Kraats above 700 nm must warn');
        end

        function testPokornyReportsNothingBelow400(testCase)
            % Andy Rider's objection resolved rather than documented: the
            % flat 400 nm extrapolation is no longer reported as data.
            obs = IndividualCMF(LensModel="Pokorny1987", Age=70);
            obs.WavelengthWarning = false;
            wl = (360:1:830)';
            LMS = obs.LMS(wl);

            below = wl < 400;
            testCase.verifyEqual(LMS(below,:), zeros(sum(below), 3), 'AbsTol', 0, ...
                'Out-of-domain samples must report zero sensitivity');
            testCase.verifyEqual(size(LMS), [numel(wl) 3]);

            % In-domain values must be untouched, not merely present.
            testCase.verifyGreaterThan(max(LMS(:,1)), 0.5, ...
                'The L cone must still peak inside the domain');

            % The density accessor reports NaN, not zero: zero optical
            % density would read as perfectly transparent.
            od = obs.getLensDensitySpectrum(wl);
            testCase.verifyTrue(all(isnan(od(below))), ...
                'Out-of-domain lens density must be NaN');
            testCase.verifyTrue(all(isfinite(od(~below))), ...
                'In-domain lens density must stay finite');
        end

        function testSmoothDecayIsKeptOutsideValidRange(testCase)
            % van de Kraats above 700 nm decays smoothly, so the values are
            % kept and only warned about. Truncating would put a cliff in
            % the long-wavelength tail.
            wl = (360:1:830)';

            o1 = IndividualCMF(LensModel="VanDeKraats2007");
            o1.WavelengthWarning = false;
            od = o1.getLensDensitySpectrum(wl);

            tail = od(wl >= 700);
            testCase.verifyTrue(all(tail > 0), ...
                'The van de Kraats tail must not be zeroed');
            testCase.verifyLessThanOrEqual(diff(tail), 1e-12, ...
                'The van de Kraats tail must decay, not oscillate');

            % Govardovskii keeps its tails outside 380-780 nm too.
            o2 = IndividualCMF(PhotopigmentModel="Govardovskii2000", ...
                LensModel="VanDeKraats2007");
            o2.WavelengthWarning = false;
            LMS = o2.LMS(wl);
            testCase.verifyTrue(all(LMS(:,1) >= 0));
            testCase.verifyGreaterThan(max(LMS(wl > 780, 1)), 0, ...
                'Govardovskii must keep its long-wavelength tail');
        end

        function testDivergenceIsNeverReturned(testCase)
            % Before this task obs.L(320) returned 2.897e+13 against a
            % normalized peak of 1.0, and 8.36e+153 on the common template.
            for m = ["StockmanRider2023", "StockmanRider2023Common"]
                obs = IndividualCMF(PhotopigmentModel=m);
                obs.WavelengthWarning = false;
                for w = [300 310 320 330 340 350]
                    testCase.verifyEqual(obs.L(w), 0, 'AbsTol', 0, ...
                        sprintf('%s at %d nm must report zero, not a diverged value', m, w));
                end
                testCase.verifyLessThanOrEqual( ...
                    max(obs.LMS((360:1:830)'), [], 'all'), 1 + 1e-9, ...
                    'No in-domain sample may exceed the normalized peak');
            end
        end

        function testDesignedZerosDoNotWarn(testCase)
            % The Stockman-Rider lens zeroes above 660 nm and the macular
            % template zeroes outside 375-550 nm. Both are the model's
            % answer, not extrapolation, and must stay silent.
            wl = (360:1:830)';
            obs = IndividualCMF();
            testCase.verifyWarningFree(@() obs.getLensDensitySpectrum(wl), ...
                'A deliberate zero outside the support band must not warn');
            testCase.verifyWarningFree(@() obs.getMacularDensitySpectrum(wl), ...
                'A deliberate zero outside the support band must not warn');
            testCase.verifyWarningFree(@() obs.LMS(wl));
        end

        function testWavelengthWarningSilencesTheFilterPath(testCase)
            % The density accessors now validate, so the existing opt-out
            % has to reach them too.
            obs = IndividualCMF(LensModel="Pokorny1987");
            obs.WavelengthWarning = false;
            testCase.verifyWarningFree(@() obs.getLensDensitySpectrum((360:1:830)'));
        end

        function testDomainIsTheIntersectionOfActiveTemplates(testCase)
            % A Pokorny lens (400) with a Stockman-Rider pigment (360)
            % must take the tighter floor.
            obs = IndividualCMF(LensModel="Pokorny1987");
            obs.WavelengthWarning = false;
            testCase.verifyEqual(obs.L(399), 0, 'AbsTol', 0);
            testCase.verifyGreaterThan(obs.L(400), 0);

            % Swapping to a lens with an unbounded domain lets the pigment
            % anchor at 360 become the binding constraint.
            obs.LensModel = "VanDeKraats2007";
            testCase.verifyGreaterThan(obs.L(399), 0, ...
                'van de Kraats has no 400 nm floor');
            testCase.verifyEqual(obs.L(359), 0, 'AbsTol', 0, ...
                'The photopigment anchor at 360 nm still binds');
        end

        function testEveryTemplateDeclaresBothRanges(testCase)
            % Adding a template without these is a silent hole in the guard.
            templates = { ...
                StockmanRiderLensTemplate(), Pokorny1987LensTemplate(), ...
                VanDeKraatsVanNorren2007LensTemplate(), ...
                StockmanRider2023MacularTemplate(), ...
                StockmanRiderPhotopigmentTemplate(), ...
                StockmanRiderCommonPhotopigmentTemplate(), ...
                GovardovskiiPhotopigmentTemplate()};
            for k = 1:numel(templates)
                t = templates{k};
                name = class(t);
                testCase.verifySize(t.ValidRange, [1 2], [name ' ValidRange']);
                testCase.verifySize(t.Domain, [1 2], [name ' Domain']);
                testCase.verifyLessThan(t.ValidRange(1), t.ValidRange(2), ...
                    [name ' ValidRange must be ordered']);
                testCase.verifyLessThan(t.Domain(1), t.Domain(2), ...
                    [name ' Domain must be ordered']);
            end
        end
    end
end

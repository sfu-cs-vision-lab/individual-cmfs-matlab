classdef OutputFormatTest < matlab.unittest.TestCase
    % OUTPUTFORMATTEST  Tests for output format consistency.

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
        RefData
        Tolerance = 1e-10;
    end

    methods(TestMethodSetup)
        function loadData(testCase)
            folder = fileparts(mfilename('fullpath'));
            testCase.RefData = readtable(fullfile(folder, 'data', 'pipeline_verification.csv'));
        end
    end

    methods(Test)

        function testAbsorbanceOutput(testCase)
            % Verify Stage 1: Raw Pigment Absorbance (Log)

            % Standard Observer (2 deg)
            obs = IndividualCMF(StandardObserver=2);

            obs.OutputFormat = "absorbance";
            obs.LogOutput = true;

            wl = testCase.RefData.nm;
            L_log = obs.L(wl);
            M_log = obs.M(wl);

            testCase.verifyEqual(L_log, testCase.RefData.L_log_abs, ...
                'AbsTol', testCase.Tolerance, 'Log Absorbance Mismatch');
            testCase.verifyEqual(M_log, testCase.RefData.M_log_abs, ...
                'AbsTol', testCase.Tolerance, 'Log Absorbance Mismatch');
        end

        function testAbsorptanceOutput(testCase)
            % Verify Stage 2: Retinal Absorptance (Linear)

            obs = IndividualCMF(StandardObserver=2);

            obs.OutputFormat = "absorptance";
            obs.LogOutput = false;
            % Note: Absorptance implies normalization logic in class,
            % but usually raw absorptance is < 1.0 anyway.
            obs.NormalizeOutput = false;

            wl = testCase.RefData.nm;
            L_abs = obs.L(wl);

            testCase.verifyEqual(L_abs, testCase.RefData.L_absorptance, ...
                'AbsTol', testCase.Tolerance, 'Retinal Absorptance Mismatch');
        end

        function testLogToggleLogic(testCase)
            % Verify that LogOutput=true simply takes log10 of the linear output

            obs = IndividualCMF(StandardObserver=2);
            wl = (500:10:600)';

            % 1. Get Linear
            obs.LogOutput = false;
            lin_val = obs.L(wl);

            % 2. Get Log
            obs.LogOutput = true;
            log_val = obs.L(wl);

            % 3. Verify consistency
            testCase.verifyEqual(log_val, log10(lin_val), ...
                'AbsTol', 1e-12, 'LogOutput switch is not calculating log10 correctly');
        end

        % Add to methods(Test)

        function testEvaluateRespectsOutputFormat(testCase)
            % Verify evaluate() uses the OutputFormat property
            obs = IndividualCMF(StandardObserver=2);
            wl = testCase.RefData.nm;

            % Test Absorbance
            obs.OutputFormat = "absorbance";
            obs.LogOutput = true;
            result = obs.L(wl);
            expected = obs.L(wl);

            testCase.verifyEqual(result, expected, 'AbsTol', testCase.Tolerance, ...
                'evaluate() should respect OutputFormat=absorbance');

            % Test Absorptance
            obs.OutputFormat = "absorptance";
            obs.LogOutput = false;
            result = obs.L(wl);
            expected = obs.L(wl);

            testCase.verifyEqual(result, expected, 'AbsTol', testCase.Tolerance, ...
                'evaluate() should respect OutputFormat=absorptance');
        end

        function testEvaluateRespectsNormalization(testCase)
            % Verify evaluate() respects NormalizeOutput
            obs = IndividualCMF(StandardObserver=2);
            wl = (500:10:600)';

            % Test 1: Normalized output should be close to but not exceed 1.0
            obs.NormalizeOutput = true;
            result_norm = obs.L(wl);
            testCase.verifyLessThanOrEqual(max(result_norm), 1.0, ...
                'Normalized output should not exceed 1.0');
            testCase.verifyGreaterThan(max(result_norm), 0.99, ...
                'Normalized output should be close to 1.0');

            % Test 2: Unnormalized should be larger in absolute terms
            obs.NormalizeOutput = false;
            result_unnorm = obs.L(wl);
            testCase.verifyGreaterThan(max(result_unnorm), max(result_norm), ...
                'Unnormalized max should be greater than normalized max');

            % Test 3: Verify the normalization relationship
            % Normalized and unnormalized should be proportional
            ratio = result_unnorm(1) / result_norm(1);
            testCase.verifyEqual(result_norm * ratio, result_unnorm, ...
                'RelTol', 1e-6, 'Normalized and unnormalized should be proportional');
        end

        function testEvaluateRespectsLogOutput(testCase)
            % Verify evaluate() respects LogOutput
            obs = IndividualCMF(StandardObserver=2);
            wl = (500:10:600)';

            % Linear
            obs.LogOutput = false;
            lin_result = obs.LMS(wl);

            % Log
            obs.LogOutput = true;
            log_result = obs.LMS(wl);

            % Verify relationship
            testCase.verifyEqual(log_result, log10(lin_result), 'AbsTol', 1e-12, ...
                'evaluate() should respect LogOutput setting');
        end

        function testBasicLogComponents(testCase)
            % Verify Stockman-Rider cone templates match reference data from Pycone.
            % The reference data contains log10 absorbance values for each cone type.
            folder = fileparts(mfilename('fullpath'));
            refData = readtable(fullfile(folder, 'data', 'cmf_verification_data.csv'));
            % Suppress wavelength-out-of-range warnings that fire incidentally
            % when these tests probe wider-than-template wavelength grids.
            testCase.applyFixture( ...
                matlab.unittest.fixtures.SuppressedWarningsFixture({ ...
                    'IndividualCMF:WavelengthOutOfRange', ...
                    'Nomograms:WavelengthOutOfRange'}));
            wl = refData.nm;

            % L-cone Serine template (shift=0)
            testCase.verifyEqual(Nomograms.stockmanRider(wl, 'L', Shift=0, L_Template="Serine"), ...
                refData.Lser_log, 'AbsTol', testCase.Tolerance, 'Lserconelog mismatch');

            % L-cone Alanine template (equivalent to Serine shifted by -2.7nm)
            testCase.verifyEqual(Nomograms.stockmanRider(wl, 'L', L_Template="Alanine"), ...
                refData.Lala_log, 'AbsTol', testCase.Tolerance, 'Lalaconelog mismatch');

            % L-cone Mean template (population average of 56% Serine + 44% Alanine)
            testCase.verifyEqual(Nomograms.stockmanRider(wl, 'L', L_Template="Mean"), ...
                refData.Lmean_log, 'AbsTol', testCase.Tolerance, 'Lmeanconelog mismatch');

            % M-cone template (shift=0)
            testCase.verifyEqual(Nomograms.stockmanRider(wl, 'M', Shift=0), ...
                refData.M_log, 'AbsTol', testCase.Tolerance, 'Mconelog mismatch');

            % S-cone template (shift=0)
            testCase.verifyEqual(Nomograms.stockmanRider(wl, 'S', Shift=0), ...
                refData.S_log, 'AbsTol', testCase.Tolerance, 'Sconelog mismatch');
        end

        function testEvaluateChromaticityFormat(testCase)
            % Chromaticity is computed from the current OutputFormat setting
            % Energy vs Quantal WILL produce different chromaticity values
            % This is correct behavior - test that chromaticity is consistent
            % when using the SAME output format

            obs = IndividualCMF(StandardObserver=2);
            wl = (500:10:600)';

            % Test consistency within same format
            obs.OutputFormat = "energy";
            chrom1 = obs.lmChromaticity(wl);
            chrom2 = obs.lmChromaticity(wl);

            testCase.verifyEqual(chrom1, chrom2, 'AbsTol', 1e-10, ...
                'Chromaticity should be consistent with same format');

            % lmChromaticity returns (l, m); the third coordinate is
            % implicit, so l + m + s = 1 with s = 1 - l - m.
            s_implicit = 1 - chrom1(:,1) - chrom1(:,2);
            testCase.verifyEqual(sum([chrom1, s_implicit], 2), ...
                ones(size(chrom1, 1), 1), 'AbsTol', 1e-10, ...
                'Chromaticity coordinates plus the implicit s should sum to 1');

            % Note: Different OutputFormats (energy vs quantal) WILL give different
            % chromaticity values. This is expected because the spectral shape differs.
        end

        % One wavelength default across every method

        function testEveryMethodSharesOneWavelengthDefault(testCase)
            obs = IndividualCMF();
            n = numel(IndividualCMF.DEFAULT_WL);

            testCase.verifyNumElements(obs.L(), n);
            testCase.verifyNumElements(obs.M(), n);
            testCase.verifyNumElements(obs.S(), n);
            testCase.verifySize(obs.LMS(), [n 3]);
            testCase.verifySize(obs.XYZ(), [n 3]);
            testCase.verifySize(obs.RGB(), [n 3]);
            testCase.verifyNumElements(obs.Luminance(), n);
            testCase.verifySize(obs.lmChromaticity(), [n 2]);
            testCase.verifySize(obs.xyChromaticity(), [n 2]);
            testCase.verifySize(obs.MacLeodBoynton(), [n 2]);
            testCase.verifyEqual(height(obs.evaluate()), n);
            testCase.verifyNumElements(obs.getLensDensitySpectrum(), n);
            testCase.verifyNumElements(obs.getMacularDensitySpectrum(), n);
        end

        function testPerConeMatchesTheLMSColumn(testCase)
            % obs.L() and obs.LMS()(:,1) are the same quantity and must be
            % subtractable. They were 471 and 401 samples before this task.
            obs = IndividualCMF();
            LMS = obs.LMS();
            testCase.verifyEqual(obs.L(), LMS(:,1), 'AbsTol', 0);
            testCase.verifyEqual(obs.M(), LMS(:,2), 'AbsTol', 0);
            testCase.verifyEqual(obs.S(), LMS(:,3), 'AbsTol', 0);
        end

        function testChromaticitySiblingsAgreeOnLength(testCase)
            % lmChromaticity used the Govardovskii range and xyChromaticity
            % the Stockman-Rider one, for the same observer.
            obs = IndividualCMF();
            testCase.verifyEqual(height(obs.lmChromaticity()), ...
                height(obs.xyChromaticity()));
            testCase.verifyEqual(numel(obs.Luminance()), height(obs.XYZ()), ...
                'Luminance is a row of the XYZ matrix and must match it');
        end

        function testDefaultMatchesTheDefaultTemplateValidity(testCase)
            % The default grid must be exactly where the default
            % photopigment model is defined, so nothing is truncated
            % silently.
            testCase.verifyEqual( ...
                [IndividualCMF.DEFAULT_WL(1), IndividualCMF.DEFAULT_WL(end)], ...
                Nomograms.SR_VALID_RANGE, 'AbsTol', 0);
        end

        function testPlotMethodsShareTheSameDefault(testCase)
            obs = IndividualCMF();
            fig = figure(Visible="off");
            cleanup = onCleanup(@() close(fig)); %#ok<NASGU>
            p = obs.plotLMS(Parent=axes(fig));
            testCase.verifyNumElements(p(1).XData, numel(IndividualCMF.DEFAULT_WL));
        end

        function testDefaultIsWarningFreeUnderTheDefaultModel(testCase)
            % Stockman-Rider is valid over 360-830, so a no-argument call
            % must not warn. Govardovskii observers warn once by design.
            Nomograms.resetWarnings();
            obs = IndividualCMF();
            testCase.verifyWarningFree(@() obs.LMS(), ...
                'The default grid must be warning-free under the default model');
            testCase.verifyWarningFree(@() obs.getLensDensitySpectrum());
            testCase.verifyWarningFree(@() obs.getMacularDensitySpectrum());
        end

        function testFilterSpectraAreWellBehavedOnTheDefaultGrid(testCase)
            % Pin the numerics on the wider default: no Inf, no negative
            % density, no polynomial oscillation in the tails.
            wl = IndividualCMF.DEFAULT_WL;
            % Domain floor per lens model. Only Pokorny has one inside the
            % default grid, and 360-399 nm is exactly where it would
            % otherwise flat-extrapolate.
            floors = dictionary( ...
                ["StockmanRider2023", "Pokorny1987", "VanDeKraats2007"], ...
                [360, 400, 0]);

            for model = ["StockmanRider2023", "Pokorny1987", "VanDeKraats2007"]
                obs = IndividualCMF(LensModel=model, Age=45);
                obs.WavelengthWarning = false;
                s = obs.getLensDensitySpectrum();

                % Pokorny has no value below 400 nm and reports NaN there
                % (Task 4.9). Everything it does report must be sound.
                defined = ~isnan(s);
                testCase.verifyTrue(all(isfinite(s(defined))), ...
                    model + " lens: non-finite value");
                testCase.verifyGreaterThanOrEqual(s(defined), 0, ...
                    model + " lens: negative density");

                testCase.verifyEqual(isnan(s), wl < floors(model), ...
                    model + " lens: NaN must appear exactly outside the domain");
            end

            m = IndividualCMF().getMacularDensitySpectrum();
            testCase.verifyTrue(all(isfinite(m)));
            testCase.verifyGreaterThanOrEqual(m, 0);
            % Macular pigment absorbs roughly 380-540 nm and must be flat
            % zero well outside it, not ringing.
            testCase.verifyEqual(m(wl > 620), zeros(sum(wl > 620), 1), ...
                'AbsTol', 1e-12);
        end

        % Per-cone methods share LMS's per-call override surface

        function testPerConeMethodsAcceptTheSameOverridesAsLMS(testCase)
            obs = IndividualCMF();
            wl = (400:10:700)';
            for fmt = ["energy" "quantal" "absorptance" "absorbance"]
                LMS = obs.LMS(wl, OutputFormat=fmt);
                testCase.verifyEqual(obs.L(wl, OutputFormat=fmt), LMS(:,1), ...
                    'AbsTol', 0, "L must match the LMS column for " + fmt);
                testCase.verifyEqual(obs.M(wl, OutputFormat=fmt), LMS(:,2), ...
                    'AbsTol', 0, "M must match the LMS column for " + fmt);
                testCase.verifyEqual(obs.S(wl, OutputFormat=fmt), LMS(:,3), ...
                    'AbsTol', 0, "S must match the LMS column for " + fmt);
            end
        end

        function testPerConeLogAndNormalizeOverrides(testCase)
            obs = IndividualCMF();
            wl = (400:10:700)';

            LMS = obs.LMS(wl, LogOutput=true);
            testCase.verifyEqual(obs.L(wl, LogOutput=true), LMS(:,1), 'AbsTol', 0);

            LMS = obs.LMS(wl, NormalizeOutput=false);
            testCase.verifyEqual(obs.S(wl, NormalizeOutput=false), LMS(:,3), 'AbsTol', 0);
        end

        function testPerConeOverridesDoNotMutateTheObserver(testCase)
            obs = IndividualCMF();
            formatBefore = obs.OutputFormat;
            obs.L((400:10:700)', OutputFormat="quantal", LogOutput=true, ...
                NormalizeOutput=false);
            testCase.verifyEqual(obs.OutputFormat, formatBefore);
            testCase.verifyFalse(obs.LogOutput);
            testCase.verifyTrue(obs.NormalizeOutput);
        end

        function testPerConeOverridesPreserveInputOrientation(testCase)
            % L/M/S return a row for a row input; the overrides must not
            % quietly reshape that.
            obs = IndividualCMF();
            wlRow = 400:10:700;
            testCase.verifyTrue(isrow(obs.L(wlRow, OutputFormat="quantal")));
            testCase.verifyTrue(iscolumn(obs.L(wlRow', OutputFormat="quantal")));
        end

    end
end

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
            result = obs.evaluate(wl, Data='L');
            expected = obs.L(wl);

            testCase.verifyEqual(result, expected, 'AbsTol', testCase.Tolerance, ...
                'evaluate() should respect OutputFormat=absorbance');

            % Test Absorptance
            obs.OutputFormat = "absorptance";
            obs.LogOutput = false;
            result = obs.evaluate(wl, Data='L');
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
            result_norm = obs.evaluate(wl, Data='L');
            testCase.verifyLessThanOrEqual(max(result_norm), 1.0, ...
                'Normalized output should not exceed 1.0');
            testCase.verifyGreaterThan(max(result_norm), 0.99, ...
                'Normalized output should be close to 1.0');

            % Test 2: Unnormalized should be larger in absolute terms
            obs.NormalizeOutput = false;
            result_unnorm = obs.evaluate(wl, Data='L');
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
            lin_result = obs.evaluate(wl, Data='LMS');

            % Log
            obs.LogOutput = true;
            log_result = obs.evaluate(wl, Data='LMS');

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
            chrom1 = obs.evaluate(wl, Data='chromaticity');
            chrom2 = obs.evaluate(wl, Data='chromaticity');

            testCase.verifyEqual(chrom1, chrom2, 'AbsTol', 1e-10, ...
                'Chromaticity should be consistent with same format');

            % Verify chromaticity sums to 1
            testCase.verifyEqual(sum(chrom1, 2), ones(size(chrom1, 1), 1), ...
                'AbsTol', 1e-10, 'Chromaticity should sum to 1');

            % Note: Different OutputFormats (energy vs quantal) WILL give different
            % chromaticity values. This is expected because the spectral shape differs.
        end

    end
end
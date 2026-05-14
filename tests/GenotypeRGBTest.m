classdef GenotypeRGBTest < matlab.unittest.TestCase
    % GENOTYPERGBTESTS  Tests for genotype-based RGB CMF calculations.

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
        ShiftData
        RGBData
        MatrixData
        Tolerance = 1e-6;
    end

    methods(TestMethodSetup)
        function loadData(testCase)
            folder = fileparts(mfilename('fullpath'));
            testCase.ShiftData = readtable(fullfile(folder, 'data', 'genotype_shifts.csv'));
            testCase.RGBData = readtable(fullfile(folder, 'data', 'rgb_verification.csv'));
            testCase.MatrixData = readmatrix(fullfile(folder, 'data', 'rgb_matrix.csv'));
        end
    end

    methods(Test)

        function testGenotypeShifts(testCase)
            obs = IndividualCMF(Age=32, FieldSize=2); % Manual mode to allow shifts

            % 1. M-180-Ser
            obs.setGenotype('M', 180, 'Ser');
            actual = obs.M_LambdaMaxShift;
            expected = testCase.ShiftData.shift_M_180_Ser;
            testCase.verifyEqual(actual, expected, 'AbsTol', 1e-10);

            % 2. L-116-Tyr
            obs.setGenotype('L', 116, 'Tyr');
            actual = obs.L_LambdaMaxShift;
            expected = testCase.ShiftData.shift_L_116_Tyr;
            testCase.verifyEqual(actual, expected, 'AbsTol', 1e-10);

            % 3. L-180-Ala (Additive)
            obs.setGenotype('L', 180, 'Ala');
            actual = obs.L_LambdaMaxShift;
            expected = testCase.ShiftData.shift_L_116_Tyr + testCase.ShiftData.shift_L_180_Ala;
            testCase.verifyEqual(actual, expected, 'AbsTol', 1e-10);
        end

        function testQuantalOutput(testCase)
            % Verify raw quantal sensitivity (Photons)
            obs = IndividualCMF(StandardObserver=2);
            obs.OutputFormat = "quantal";
            obs.NormalizeOutput = false;

            wl = testCase.RGBData.nm;

            testCase.verifyEqual(obs.L(wl), testCase.RGBData.L_quantal, 'AbsTol', 1e-10, 'L-Quantal Mismatch');
            testCase.verifyEqual(obs.M(wl), testCase.RGBData.M_quantal, 'AbsTol', 1e-10, 'M-Quantal Mismatch');
            testCase.verifyEqual(obs.S(wl), testCase.RGBData.S_quantal, 'AbsTol', 1e-10, 'S-Quantal Mismatch');
        end

        function testRGBMatrixOrientation(testCase)
            % Verify the 3x3 transformation matrix
            obs = IndividualCMF(StandardObserver=2);

            % FIX: Must disable normalization to match Python's raw energy calculation
            obs.NormalizeOutput = false;
            obs.OutputFormat = "energy";

            % Get Primaries
            L_prim = obs.L(obs.Primaries)';
            M_prim = obs.M(obs.Primaries)';
            S_prim = obs.S(obs.Primaries)';

            % Replicate Class Logic
            % Note: We use the transposed matrix [L;M;S] to match the class logic
            RGBLMS = [L_prim, M_prim, S_prim]';

            % CORRECTED: Do NOT transpose the result.
            % inv(RGBLMS) matches the Python matrix directly.
            actual_matrix = inv(RGBLMS);

            testCase.verifyEqual(actual_matrix, testCase.MatrixData, ...
                'RelTol', 1e-6, 'RGB Matrix Mismatch');
        end

        function testRGBConversion(testCase)
            obs = IndividualCMF(StandardObserver=2);
            wl = testCase.RGBData.nm;

            [RGB_result, wl_out] = obs.RGB(wl);

            % Verify wavelengths returned correctly
            testCase.verifyEqual(wl_out, wl, 'Wavelengths should match input');

            % Verify RGB data (now columns 1, 2, 3 instead of 2, 3, 4)
            testCase.verifyEqual(RGB_result(:,1), testCase.RGBData.R, 'RelTol', 1e-5, 'R-channel mismatch');
            testCase.verifyEqual(RGB_result(:,2), testCase.RGBData.G, 'RelTol', 1e-5, 'G-channel mismatch');
            testCase.verifyEqual(RGB_result(:,3), testCase.RGBData.B, 'RelTol', 1e-5, 'B-channel mismatch');
        end

        function testHybridConeSwapping(testCase)
            folder = fileparts(mfilename('fullpath'));
            pipeData = readtable(fullfile(folder, 'data', 'pipeline_verification.csv'));
            wl = pipeData.nm;

            obs_L = IndividualCMF(Age=32, FieldSize=2);
            obs_L.L_OpsinTemplate = "MinL";
            obs_L.NormalizeOutput = false;
            obs_L.OutputFormat = "energy";

            testCase.verifyEqual(obs_L.L(wl), pipeData.L_hybrid_energy, 'RelTol', 1e-8);

            obs_M = IndividualCMF(Age=32, FieldSize=2);
            obs_M.M_OpsinTemplate = "LinM";
            obs_M.NormalizeOutput = false;

            testCase.verifyEqual(obs_M.M(wl), pipeData.M_hybrid_energy, 'RelTol', 1e-8);
        end

        function testEvaluateWithGenotype(testCase)
            obs = IndividualCMF(Age=32, FieldSize=2);
            obs.setGenotype('M', 180, 'Ser');

            wl = (400:10:700)';  % Ensure column vector

            % Should be equivalent
            result1 = obs.evaluate(wl, Data='M');
            result2 = obs.M(wl);

            % Both should be column vectors
            testCase.verifyEqual(result1, result2, 'AbsTol', 1e-10, ...
                'evaluate() should match M() after genotype change');
        end

        function testRGBViaEvaluate(testCase)
            % Verifies that RGB data from `evaluate` matches the dedicated `RGB` method.
            obs = IndividualCMF();
            wl = (380:5:780)';
            RGB_eval = obs.evaluate(wl, Data='RGB');
            testCase.verifySize(RGB_eval, [length(wl), 3]);
            RGB_direct = obs.RGB(wl);
            testCase.verifyEqual(RGB_eval, RGB_direct, ...
                'evaluate(Data="RGB") should match RGB()');
        end
    end
end

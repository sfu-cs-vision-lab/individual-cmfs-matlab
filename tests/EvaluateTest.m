classdef EvaluateTest < matlab.unittest.TestCase
    % EVALUATETEST  Unit tests for the evaluate() method.

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
        Observer
        TestWavelengths
        Tolerance = 1e-10;
    end

    properties(TestParameter)
        ConeType = {'L', 'M', 'S'};
        DataOption = {'LMS', 'L', 'M', 'S', 'RGB', 'chromaticity'};
        FormatOption = {'array', 'table', 'struct'};
    end

    methods(TestMethodSetup)
        function setupObserver(testCase)
            testCase.Observer = IndividualCMF(StandardObserver=2);
            testCase.TestWavelengths = (400:10:700)';
        end
    end

    methods(Test)

        %% Test Data Options

        function testDefaultData(testCase)
            % Default should return LMS as array
            result = testCase.Observer.evaluate(testCase.TestWavelengths);
            expected = testCase.Observer.LMS(testCase.TestWavelengths);

            testCase.verifyEqual(result, expected, ...
                'AbsTol', testCase.Tolerance, 'Default should return LMS array');
            testCase.verifySize(result, [length(testCase.TestWavelengths), 3]);
        end

        function testDataLMS(testCase)
            result = testCase.Observer.evaluate(testCase.TestWavelengths, Data='LMS');
            expected = testCase.Observer.LMS(testCase.TestWavelengths);

            testCase.verifyEqual(result, expected, ...
                'AbsTol', testCase.Tolerance, 'Data=LMS should match LMS()');
        end

        function testDataL(testCase)
            result = testCase.Observer.evaluate(testCase.TestWavelengths, Data='L');
            expected = testCase.Observer.L(testCase.TestWavelengths);

            testCase.verifyEqual(result, expected, ...
                'AbsTol', testCase.Tolerance, 'Data=L should match L()');
            testCase.verifySize(result, [length(testCase.TestWavelengths), 1]);
        end

        function testDataM(testCase)
            result = testCase.Observer.evaluate(testCase.TestWavelengths, Data='M');
            expected = testCase.Observer.M(testCase.TestWavelengths);

            testCase.verifyEqual(result, expected, ...
                'AbsTol', testCase.Tolerance, 'Data=M should match M()');
        end

        function testDataS(testCase)
            result = testCase.Observer.evaluate(testCase.TestWavelengths, Data='S');
            expected = testCase.Observer.S(testCase.TestWavelengths);

            testCase.verifyEqual(result, expected, ...
                'AbsTol', testCase.Tolerance, 'Data=S should match S()');
        end

        function testDataRGB(testCase)
            result = testCase.Observer.evaluate(testCase.TestWavelengths, Data='RGB');
            expected = testCase.Observer.RGB(testCase.TestWavelengths);

            % Both now return Nx3 RGB data directly
            testCase.verifyEqual(result, expected, ...
                'AbsTol', testCase.Tolerance, 'Data=RGB should match RGB()');
        end

        function testDataChromaticity(testCase)
            result = testCase.Observer.evaluate(testCase.TestWavelengths, Data='chromaticity');

            % Manually calculate expected
            LMS = testCase.Observer.LMS(testCase.TestWavelengths);
            sum_LMS = sum(LMS, 2);
            sum_LMS(sum_LMS == 0) = eps;
            expected = LMS ./ sum_LMS;

            testCase.verifyEqual(result, expected, ...
                'AbsTol', testCase.Tolerance, 'Chromaticity calculation mismatch');
            testCase.verifySize(result, [length(testCase.TestWavelengths), 3]);
        end

        %% Test Format Options

        function testFormatArray(testCase)
            result = testCase.Observer.evaluate(testCase.TestWavelengths, Format='array');

            testCase.verifyClass(result, 'double', 'Array format should return double');
            testCase.verifySize(result, [length(testCase.TestWavelengths), 3]);
        end

        function testFormatTable(testCase)
            result = testCase.Observer.evaluate(testCase.TestWavelengths, Format='table');

            testCase.verifyClass(result, 'table', 'Format=table should return table');
            testCase.verifyEqual(result.Properties.VariableNames, ...
                {'Wavelength_nm', 'L', 'M', 'S'}, ...
                'Table should have correct column names');
            testCase.verifyEqual(height(result), length(testCase.TestWavelengths));
        end

        function testFormatStruct(testCase)
            result = testCase.Observer.evaluate(testCase.TestWavelengths, Format='struct');

            testCase.verifyClass(result, 'struct', 'Format=struct should return struct');
            testCase.verifyTrue(isfield(result, 'Wavelength_nm'), 'Struct missing Wavelength_nm');
            testCase.verifyTrue(isfield(result, 'L'), 'Struct missing L');
            testCase.verifyTrue(isfield(result, 'M'), 'Struct missing M');
            testCase.verifyTrue(isfield(result, 'S'), 'Struct missing S');
        end

        %% Test Combined Options

        function testLAsTable(testCase)
            result = testCase.Observer.evaluate(testCase.TestWavelengths, ...
                Data='L', Format='table');

            testCase.verifyClass(result, 'table');
            testCase.verifyEqual(result.Properties.VariableNames, ...
                {'Wavelength_nm', 'L'}, ...
                'Single cone table should have two columns');

            % Verify data matches
            expected = testCase.Observer.L(testCase.TestWavelengths);
            testCase.verifyEqual(result.L, expected, 'AbsTol', testCase.Tolerance);
        end

        function testRGBAsTable(testCase)
            result = testCase.Observer.evaluate(testCase.TestWavelengths, ...
                Data='RGB', Format='table');

            testCase.verifyClass(result, 'table');
            testCase.verifyEqual(result.Properties.VariableNames, ...
                {'Wavelength_nm', 'R', 'G', 'B'}, ...
                'RGB table should have correct column names');
        end

        function testChromaticityAsStruct(testCase)
            result = testCase.Observer.evaluate(testCase.TestWavelengths, ...
                Data='chromaticity', Format='struct');

            testCase.verifyClass(result, 'struct');
            testCase.verifyTrue(isfield(result, 'l'), 'Chromaticity struct missing l');
            testCase.verifyTrue(isfield(result, 'm'), 'Chromaticity struct missing m');
            testCase.verifyTrue(isfield(result, 's'), 'Chromaticity struct missing s');

            % Verify sum equals 1
            sum_chrom = result.l + result.m + result.s;
            testCase.verifyEqual(sum_chrom, ones(size(sum_chrom)), ...
                'AbsTol', 1e-10, 'Chromaticity coordinates should sum to 1');
        end

        function testMAsStruct(testCase)
            result = testCase.Observer.evaluate(testCase.TestWavelengths, ...
                Data='M', Format='struct');

            testCase.verifyClass(result, 'struct');
            testCase.verifyTrue(isfield(result, 'M'), 'M struct missing M field');
            testCase.verifyEqual(length(result.M), length(testCase.TestWavelengths));
        end

        %% Test IncludeWavelength Option

        function testIncludeWavelength_ArrayDefault(testCase)
            % Array format should NOT include wavelength by default
            result = testCase.Observer.evaluate(testCase.TestWavelengths);
            testCase.verifySize(result, [length(testCase.TestWavelengths), 3], ...
                'Array should have 3 columns by default (no wavelength)');
        end

        function testIncludeWavelength_ArrayTrue(testCase)
            % Verify that we can get [Data, Wavelengths] as two separate outputs
            [result, wl_out] = testCase.Observer.evaluate(testCase.TestWavelengths, ...
                Data='LMS', Format='array');
            testCase.verifySize(result, [numel(testCase.TestWavelengths), 3], ...
                'Data output should be Nx3 (L,M,S only)');
            testCase.verifyEqual(wl_out, testCase.TestWavelengths, ...
                'Second output argument should match input wavelengths');
        end

        function testIncludeWavelength_TableDefault(testCase)
            % Table format should include wavelength by default
            result = testCase.Observer.evaluate(testCase.TestWavelengths, Format='table');
            testCase.verifyTrue(ismember('Wavelength_nm', result.Properties.VariableNames), ...
                'Table should include Wavelength_nm by default');
        end

        function testIncludeWavelength_StructDefault(testCase)
            % Struct format should include wavelength by default
            result = testCase.Observer.evaluate(testCase.TestWavelengths, Format='struct');
            testCase.verifyTrue(isfield(result, 'Wavelength_nm'), ...
                'Struct should include Wavelength_nm by default');
        end

        function testIncludeWavelength_SingleConeArray(testCase)
            % Verify single-column data return behavior
            [result, wl_out] = testCase.Observer.evaluate(testCase.TestWavelengths, ...
                Data='L', Format='array');
            testCase.verifySize(result, [numel(testCase.TestWavelengths), 1], ...
                'Data output should be Nx1 for single cone');
            testCase.verifyEqual(wl_out, testCase.TestWavelengths, ...
                'Second output argument should match input wavelengths');
        end

        %% Test Edge Cases

        function testSingleWavelength(testCase)
            result = testCase.Observer.evaluate(550);
            testCase.verifySize(result, [1, 3], 'Single wavelength should return 1x3');
        end

        function testRowVectorInput(testCase)
            wl_row = testCase.TestWavelengths';
            result = testCase.Observer.evaluate(wl_row);
            expected = testCase.Observer.LMS(testCase.TestWavelengths);

            testCase.verifyEqual(result, expected, 'AbsTol', testCase.Tolerance, ...
                'Row vector input should be handled correctly');
        end

        function testDefaultWavelengths(testCase)
            % Test default wavelength range
            obs = IndividualCMF();

            % Capture both outputs
            [data, wl] = obs.evaluate();

            % Verify Wavelengths (Output 2)
            testCase.verifyEqual(wl(1), 380, 'Start wavelength should be 380');
            testCase.verifyEqual(wl(end), 780, 'End wavelength should be 780');
            testCase.verifySize(wl, [401, 1], 'Wavelength should be 401x1');

            % Verify Data (Output 1) - Pure data, no wavelength column
            testCase.verifySize(data, [401, 3], 'Data should be 401x3 (LMS only)');
        end

        function testChromaticitySumToOne(testCase)
            result = testCase.Observer.evaluate(testCase.TestWavelengths, ...
                Data='chromaticity');

            row_sums = sum(result, 2);
            testCase.verifyEqual(row_sums, ones(size(row_sums)), ...
                'AbsTol', 1e-10, 'Each row should sum to 1.0');
        end

        function testChromaticityInvariantUnderOutputFormat(testCase)
            % Chromaticity is a projective normalization; the result must
            % be identical regardless of the observer's OutputFormat /
            % LogOutput / NormalizeOutput. evaluate(Data='chromaticity')
            % previously called obj.LMS(wl) without forcing the right
            % basis, so the curve silently changed shape under
            % OutputFormat="absorbance" / LogOutput=true.
            wl = testCase.TestWavelengths;
            obs = IndividualCMF(StandardObserver=2);
            ref = obs.evaluate(wl, Data='chromaticity');

            obs.OutputFormat = "absorbance";
            testCase.verifyEqual(obs.evaluate(wl, Data='chromaticity'), ref, ...
                'AbsTol', 1e-10, 'chromaticity must not depend on OutputFormat');

            obs.OutputFormat = "energy";
            obs.LogOutput = true;
            testCase.verifyEqual(obs.evaluate(wl, Data='chromaticity'), ref, ...
                'AbsTol', 1e-10, 'chromaticity must not depend on LogOutput');

            obs.LogOutput = false;
            obs.NormalizeOutput = false;
            testCase.verifyEqual(obs.evaluate(wl, Data='chromaticity'), ref, ...
                'AbsTol', 1e-10, 'chromaticity must not depend on NormalizeOutput');
        end

        function testChromaticityEntryPointsAgree(testCase)
            % Cross-API parity for the chromaticity quantity. All four
            % paths must produce the same lm coordinates:
            %   1) obs.evaluate(wl, Data='chromaticity')[:, 1:2]
            %   2) obs.lmChromaticity(wl)
            %   3) CMFPlotter().plotChromaticity(obs).XData/YData
            %   4) MacLeodBoynton(wl) is a different convention, so it's
            %      excluded from this lm-specific parity check.
            obs = IndividualCMF(StandardObserver=2);
            wl = (400:5:700)';

            evalChrom = obs.evaluate(wl, Data='chromaticity');
            lmDirect = obs.lmChromaticity(wl);

            testCase.verifyEqual(evalChrom(:,1:2), lmDirect, 'AbsTol', 1e-12, ...
                'evaluate chromaticity columns 1:2 must match lmChromaticity');

            % Plotter delegates to lmChromaticity now; verify YData parity
            % via a hidden figure.
            fig = figure('Visible', 'off');
            cleanup = onCleanup(@() close(fig));
            plotter = CMFPlotter(Visible=false);
            cleanupP = onCleanup(@() close(plotter.Figure));
            p = plotter.plotChromaticity(obs, Wavelength=wl);
            xdata = p(1).XData(:);
            ydata = p(1).YData(:);
            testCase.verifyEqual(xdata, lmDirect(:,1), 'AbsTol', 1e-12, ...
                'plotter X must match lmChromaticity column 1');
            testCase.verifyEqual(ydata, lmDirect(:,2), 'AbsTol', 1e-12, ...
                'plotter Y must match lmChromaticity column 2');
        end

        %% Test Invalid Inputs

        function testInvalidData(testCase)
            testCase.verifyError(...
                @() testCase.Observer.evaluate(testCase.TestWavelengths, Data='invalid'), ...
                'MATLAB:validators:mustBeMember', ...
                'Invalid Data option should throw error');
        end

        function testInvalidFormat(testCase)
            testCase.verifyError(...
                @() testCase.Observer.evaluate(testCase.TestWavelengths, Format='json'), ...
                'MATLAB:validators:mustBeMember', ...
                'Invalid Format option should throw error');
        end

        %% Test Consistency Across Formats

        function testDataConsistencyAcrossFormats(testCase)
            % Verify that array, table, and struct return the same underlying data

            array_result = testCase.Observer.evaluate(testCase.TestWavelengths, ...
                Data='LMS', Format='array');

            table_result = testCase.Observer.evaluate(testCase.TestWavelengths, ...
                Data='LMS', Format='table');

            struct_result = testCase.Observer.evaluate(testCase.TestWavelengths, ...
                Data='LMS', Format='struct');

            % Extract data from table
            table_data = [table_result.L, table_result.M, table_result.S];

            % Extract data from struct
            struct_data = [struct_result.L, struct_result.M, struct_result.S];

            % Compare
            testCase.verifyEqual(table_data, array_result, ...
                'AbsTol', testCase.Tolerance, 'Table data should match array');
            testCase.verifyEqual(struct_data, array_result, ...
                'AbsTol', testCase.Tolerance, 'Struct data should match array');
        end

        function testEvaluateIntegrationWithTemplates(testCase)
            % Verify evaluate() works correctly with cone templates.
            % Use a 1 nm grid so the sampled peak lands close to the true
            % template maximum (normalization is to within ~2e-5).
            obs = IndividualCMF(StandardObserver=2);
            wl = (380:1:780)';

            % Get data via evaluate
            LMS = obs.evaluate(wl, Data='LMS', Format='array');

            % Verify it's using the templates (non-zero, reasonable range)
            testCase.verifyGreaterThan(max(LMS(:,1)), 0, 'L should have positive values');
            testCase.verifyGreaterThan(max(LMS(:,2)), 0, 'M should have positive values');
            testCase.verifyGreaterThan(max(LMS(:,3)), 0, 'S should have positive values');

            % Peak should be normalized if NormalizeOutput=true (default).
            testCase.verifyEqual(max(LMS(:,1)), 1.0, 'RelTol', 2e-5, 'L should be normalized');
            testCase.verifyEqual(max(LMS(:,2)), 1.0, 'RelTol', 2e-5, 'M should be normalized');
            testCase.verifyEqual(max(LMS(:,3)), 1.0, 'RelTol', 2e-5, 'S should be normalized');
        end

        function testWavelengthConsistency(testCase)
            % Verify wavelength values are consistent across formats

            table_result = testCase.Observer.evaluate(testCase.TestWavelengths, Format='table');
            struct_result = testCase.Observer.evaluate(testCase.TestWavelengths, Format='struct');

            testCase.verifyEqual(table_result.Wavelength_nm, testCase.TestWavelengths, ...
                'Table wavelengths should match input');
            testCase.verifyEqual(struct_result.Wavelength_nm, testCase.TestWavelengths, ...
                'Struct wavelengths should match input');
        end

    end

    methods(Test, ParameterCombination='sequential')

        function testEachConeType(testCase, ConeType)
            % Test each cone type individually
            result = testCase.Observer.evaluate(testCase.TestWavelengths, Data=ConeType);

            testCase.verifySize(result, [length(testCase.TestWavelengths), 1], ...
                sprintf('%s cone should return Nx1', ConeType));
            testCase.verifyGreaterThan(max(result), 0, ...
                sprintf('%s cone should have positive values', ConeType));
        end

        function testEachDataOption(testCase, DataOption)
            % Test each data option works without error
            testCase.verifyWarningFree(...
                @() testCase.Observer.evaluate(testCase.TestWavelengths, Data=DataOption));
        end

        function testEachFormatOption(testCase, FormatOption)
            % Test each format option returns correct type
            result = testCase.Observer.evaluate(testCase.TestWavelengths, Format=FormatOption);

            switch FormatOption
                case 'array'
                    testCase.verifyClass(result, 'double');
                case 'table'
                    testCase.verifyClass(result, 'table');
                case 'struct'
                    testCase.verifyClass(result, 'struct');
            end
        end

    end
end
classdef StockmanRiderPhotopigmentTemplateTest < matlab.unittest.TestCase
    % STOCKMANRIDERPHOTOPIGMENTTEMPLATETEST  Tests for StockmanRiderPhotopigmentTemplate.

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada
    %
    % This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    % Licensed under AGPL-3.0-or-later. See LICENSE file for details.
    % Repository: https://github.com/sfu-cs-vision-lab/Individual-CMFs

    properties
        Template
        TestWavelengths
    end

    methods(TestMethodSetup)
        function setupTemplate(testCase)
            testCase.Template = StockmanRiderPhotopigmentTemplate();
            testCase.TestWavelengths = (450:5:650)';
        end
    end

    methods(Test)

        %% L-cone Template Tests

        function testLconeDefaultTemplateType(testCase)
            % An unspecified L_Template option must fall through to "Mean".
            wl = testCase.TestWavelengths;

            % Call with empty options - should use default
            options = struct();
            logAbs = testCase.Template.computeAbsorbance(wl, 'L', 0, options);

            % Compare with explicit Mean
            options_mean = struct('L_Template', "Mean");
            logAbs_mean = testCase.Template.computeAbsorbance(wl, 'L', 0, options_mean);

            testCase.verifyEqual(logAbs, logAbs_mean, 'AbsTol', 1e-10, ...
                'Default should be Mean template');
        end

        function testLconeMeanNoShift(testCase)
            % Test Mean template with no shift
            wl = testCase.TestWavelengths;
            options = struct('L_Template', "Mean");

            testCase.verifyWarningFree(@() testCase.Template.computeAbsorbance(wl, 'L', 0, options));
        end

        function testLconeMeanWithShiftWarning(testCase)
            % Test Mean template with shift produces warning
            wl = testCase.TestWavelengths;
            options = struct('L_Template', "Mean");

            testCase.verifyWarning(@() testCase.Template.computeAbsorbance(wl, 'L', 5, options), ...
                'StockmanRiderPhotopigmentTemplate:ShiftOverride');
        end

        function testLconeSerineNoWarning(testCase)
            % Test Serine template with shift produces no warning
            wl = testCase.TestWavelengths;
            options = struct('L_Template', "Serine");

            testCase.verifyWarningFree(@() testCase.Template.computeAbsorbance(wl, 'L', 5, options));
        end

        function testLconeAlanineNoShiftNoWarning(testCase)
            % Test Alanine template without shift produces no warning
            wl = testCase.TestWavelengths;
            options = struct('L_Template', "Alanine");

            testCase.verifyWarningFree(@() testCase.Template.computeAbsorbance(wl, 'L', 0, options));
        end

        function testLconeAlanineWithShiftWarning(testCase)
            % Test Alanine template with shift produces warning
            wl = testCase.TestWavelengths;
            options = struct('L_Template', "Alanine");

            testCase.verifyWarning(@() testCase.Template.computeAbsorbance(wl, 'L', 5, options), ...
                'StockmanRiderPhotopigmentTemplate:ShiftOverride');
        end

        function testLconeMInLTemplate(testCase)
            % Test M-in-L hybrid template
            wl = testCase.TestWavelengths;
            options = struct('L_Template', "MinL");

            logAbs = testCase.Template.computeAbsorbance(wl, 'L', 0, options);
            testCase.verifySize(logAbs, [numel(wl), 1]);

            % M-in-L should have a different shape than standard L
            options_mean = struct('L_Template', "Mean");
            logAbs_mean = testCase.Template.computeAbsorbance(wl, 'L', 0, options_mean);

            testCase.verifyNotEqual(logAbs, logAbs_mean, ...
                'M-in-L should differ from Mean');
        end

        function testLconeMInLWithShift(testCase)
            % Test M-in-L hybrid template with shift
            wl = testCase.TestWavelengths;
            options = struct('L_Template', "MinL");

            logAbs_base = testCase.Template.computeAbsorbance(wl, 'L', 0, options);
            logAbs_shifted = testCase.Template.computeAbsorbance(wl, 'L', 5, options);

            testCase.verifyNotEqual(logAbs_base, logAbs_shifted, ...
                'Shift should affect M-in-L template');
        end

        %% M-cone Template Tests

        function testMconeStandardTemplate(testCase)
            % Test Standard M-cone template
            wl = testCase.TestWavelengths;
            options = struct('M_Template', "Standard");

            logAbs = testCase.Template.computeAbsorbance(wl, 'M', 0, options);
            testCase.verifySize(logAbs, [numel(wl), 1]);
        end

        function testMconeLInMTemplate(testCase)
            % Test L-in-M hybrid template
            wl = testCase.TestWavelengths;
            options = struct('M_Template', "LinM");

            logAbs = testCase.Template.computeAbsorbance(wl, 'M', 0, options);
            testCase.verifySize(logAbs, [numel(wl), 1]);

            % L-in-M should differ from Standard
            options_std = struct('M_Template', "Standard");
            logAbs_std = testCase.Template.computeAbsorbance(wl, 'M', 0, options_std);

            testCase.verifyNotEqual(logAbs, logAbs_std, ...
                'L-in-M should differ from Standard');
        end

        function testMconeLInMWithShift(testCase)
            % Test L-in-M hybrid template with shift
            wl = testCase.TestWavelengths;
            options = struct('M_Template', "LinM");

            logAbs_base = testCase.Template.computeAbsorbance(wl, 'M', 0, options);
            logAbs_shifted = testCase.Template.computeAbsorbance(wl, 'M', 10, options);

            testCase.verifyNotEqual(logAbs_base, logAbs_shifted, ...
                'Shift should affect L-in-M template');
        end

        function testMconeDefaultTemplate(testCase)
            % Test default M-cone template (should be Standard)
            wl = testCase.TestWavelengths;

            options_empty = struct();
            logAbs_default = testCase.Template.computeAbsorbance(wl, 'M', 0, options_empty);

            options_std = struct('M_Template', "Standard");
            logAbs_std = testCase.Template.computeAbsorbance(wl, 'M', 0, options_std);

            testCase.verifyEqual(logAbs_default, logAbs_std, 'AbsTol', 1e-10, ...
                'Default M template should be Standard');
        end

        %% S-cone Tests

        function testSconeWithShift(testCase)
            % Test S-cone with wavelength shift
            wl = (380:5:480)';

            logAbs_base = testCase.Template.computeAbsorbance(wl, 'S', 0, struct());
            logAbs_shifted = testCase.Template.computeAbsorbance(wl, 'S', 5, struct());

            % Find peaks
            [~, idx_base] = max(10.^logAbs_base);
            [~, idx_shifted] = max(10.^logAbs_shifted);

            testCase.verifyGreaterThan(idx_shifted, idx_base, ...
                'Positive S shift should move peak to longer wavelength');
        end

        %% computePeakAbsorbance Tests

        function testComputePeakAbsorbanceLMean(testCase)
            % Test peak absorbance for L Mean template
            options = struct('L_Template', "Mean");
            peakAbs = testCase.Template.computePeakAbsorbance('L', 0, options);

            testCase.verifyGreaterThan(peakAbs, 0.9);
            testCase.verifyLessThan(peakAbs, 1.1);
        end

        function testComputePeakAbsorbanceLSerine(testCase)
            % Test peak absorbance for L Serine template
            options = struct('L_Template', "Serine");
            peakAbs = testCase.Template.computePeakAbsorbance('L', 0, options);

            testCase.verifyGreaterThan(peakAbs, 0.9);
            testCase.verifyLessThan(peakAbs, 1.1);
        end

        function testComputePeakAbsorbanceLAlanine(testCase)
            % Test peak absorbance for L Alanine template
            options = struct('L_Template', "Alanine");
            peakAbs = testCase.Template.computePeakAbsorbance('L', 0, options);

            testCase.verifyGreaterThan(peakAbs, 0.9);
            testCase.verifyLessThan(peakAbs, 1.1);
        end

        function testComputePeakAbsorbanceM(testCase)
            % Test peak absorbance for M cone
            options = struct('M_Template', "Standard");
            peakAbs = testCase.Template.computePeakAbsorbance('M', 0, options);

            testCase.verifyGreaterThan(peakAbs, 0.9);
            testCase.verifyLessThan(peakAbs, 1.1);
        end

        function testComputePeakAbsorbanceS(testCase)
            % Test peak absorbance for S cone
            options = struct();
            peakAbs = testCase.Template.computePeakAbsorbance('S', 0, options);

            testCase.verifyGreaterThan(peakAbs, 0.9);
            testCase.verifyLessThan(peakAbs, 1.1);
        end

        function testComputePeakAbsorbanceWithShift(testCase)
            % Test peak absorbance with shift
            options = struct('L_Template', "Serine");

            peakAbs_base = testCase.Template.computePeakAbsorbance('L', 0, options);
            peakAbs_shifted = testCase.Template.computePeakAbsorbance('L', 5, options);

            % Both should be close to 1.0 (normalized templates)
            testCase.verifyEqual(peakAbs_base, 1.0, 'AbsTol', 0.1);
            testCase.verifyEqual(peakAbs_shifted, 1.0, 'AbsTol', 0.1);
        end

        %% Boundary Condition Tests

        function testLargePositiveShift(testCase)
            % Test with maximum allowed M shift
            wl = testCase.TestWavelengths;
            options = struct('M_Template', "Standard");

            % M shift range is -20 to 30
            logAbs = testCase.Template.computeAbsorbance(wl, 'M', 30, options);
            testCase.verifySize(logAbs, [numel(wl), 1]);
        end

        function testLargeNegativeShift(testCase)
            % Test with minimum allowed L shift
            wl = testCase.TestWavelengths;
            options = struct('L_Template', "Serine");

            % L shift range is -40 to 10
            logAbs = testCase.Template.computeAbsorbance(wl, 'L', -40, options);
            testCase.verifySize(logAbs, [numel(wl), 1]);
        end

        %% Integration Tests

        function testAllLTemplateTypes(testCase)
            % Test all L template types produce different results
            wl = testCase.TestWavelengths;

            templates = ["Mean", "Serine", "Alanine", "MinL"];
            results = cell(1, numel(templates));

            for i = 1:numel(templates)
                options = struct('L_Template', templates(i));
                results{i} = testCase.Template.computeAbsorbance(wl, 'L', 0, options);
            end

            % All should be different
            for i = 1:numel(templates)
                for j = i+1:numel(templates)
                    testCase.verifyNotEqual(results{i}, results{j}, ...
                        sprintf('%s and %s should be different', templates(i), templates(j)));
                end
            end
        end

        function testAllMTemplateTypes(testCase)
            % Test all M template types produce different results
            wl = testCase.TestWavelengths;

            templates = ["Standard", "LinM"];
            results = cell(1, numel(templates));

            for i = 1:numel(templates)
                options = struct('M_Template', templates(i));
                results{i} = testCase.Template.computeAbsorbance(wl, 'M', 0, options);
            end

            % All should be different
            testCase.verifyNotEqual(results{1}, results{2}, ...
                'Standard and L-in-M should be different');
        end

    end
end

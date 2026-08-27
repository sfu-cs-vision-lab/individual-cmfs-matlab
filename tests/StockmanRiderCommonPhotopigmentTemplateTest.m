classdef StockmanRiderCommonPhotopigmentTemplateTest < matlab.unittest.TestCase
    % STOCKMANRIDERCOMMONPHOTOPIGMENTTEMPLATETEST  Tests for StockmanRiderCommonPhotopigmentTemplate.

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
            testCase.Template = StockmanRiderCommonPhotopigmentTemplate();
            testCase.TestWavelengths = (360:1:830)';
        end
    end

    methods(Static)
        function nm = peakWavelength(template, coneType, shift, wl)
            % PEAKWAVELENGTH  Numerically locate the linear-absorbance peak.
            logAbs = template.computeAbsorbance(wl, coneType, shift, struct());
            [~, idx] = max(logAbs);
            nm = wl(idx);
        end
    end

    methods(Test)

        %% Peak Location Tests

        function testPeakLocationL(testCase)
            % L cone with zero shift should peak at the base lambda-max.
            wl = testCase.TestWavelengths;
            nm = StockmanRiderCommonPhotopigmentTemplateTest.peakWavelength( ...
                testCase.Template, 'L', 0, wl);
            testCase.verifyEqual(nm, testCase.Template.BASE_LAMBDA_MAX_L, ...
                'AbsTol', 1.0, 'L peak should land near 557.5 nm');
        end

        function testPeakLocationM(testCase)
            % M cone with zero shift should peak at the base lambda-max.
            wl = testCase.TestWavelengths;
            nm = StockmanRiderCommonPhotopigmentTemplateTest.peakWavelength( ...
                testCase.Template, 'M', 0, wl);
            testCase.verifyEqual(nm, testCase.Template.BASE_LAMBDA_MAX_M, ...
                'AbsTol', 1.0, 'M peak should land near 527.3 nm');
        end

        function testPeakLocationS(testCase)
            % S cone with zero shift should peak at the base lambda-max.
            wl = testCase.TestWavelengths;
            nm = StockmanRiderCommonPhotopigmentTemplateTest.peakWavelength( ...
                testCase.Template, 'S', 0, wl);
            testCase.verifyEqual(nm, testCase.Template.BASE_LAMBDA_MAX_S, ...
                'AbsTol', 1.0, 'S peak should land near 418.5 nm');
        end

        %% Peak Absorbance Tests

        function testPeakAbsorbanceNearUnity(testCase)
            % Linear absorbance at each base lambda-max should be ~1.0.
            wl = testCase.TestWavelengths;
            for coneType = {'L', 'M', 'S'}
                ct = coneType{1};
                logAbs = testCase.Template.computeAbsorbance(wl, ct, 0, struct());
                peakLin = max(10.^logAbs);
                testCase.verifyEqual(peakLin, 1.0, 'AbsTol', 0.02, ...
                    sprintf('%s peak linear absorbance should be ~1.0', ct));
            end
        end

        function testComputePeakAbsorbanceReturnsUnity(testCase)
            % computePeakAbsorbance is normalized to return exactly 1.0.
            for coneType = {'L', 'M', 'S'}
                ct = coneType{1};
                peakAbs = testCase.Template.computePeakAbsorbance(ct, 0, struct());
                testCase.verifyEqual(peakAbs, 1.0, 'AbsTol', 1e-12);
            end
        end

        %% Shift Tests

        function testPositiveShiftMovesPeakRed(testCase)
            % A positive shift should move the peak to longer wavelengths.
            wl = testCase.TestWavelengths;
            nm0 = StockmanRiderCommonPhotopigmentTemplateTest.peakWavelength( ...
                testCase.Template, 'M', 0, wl);
            nmShift = StockmanRiderCommonPhotopigmentTemplateTest.peakWavelength( ...
                testCase.Template, 'M', 10, wl);
            testCase.verifyGreaterThan(nmShift, nm0, ...
                'Positive shift should move peak to longer wavelength');
        end

        function testNegativeShiftMovesPeakBlue(testCase)
            % A negative shift should move the peak to shorter wavelengths.
            wl = testCase.TestWavelengths;
            nm0 = StockmanRiderCommonPhotopigmentTemplateTest.peakWavelength( ...
                testCase.Template, 'L', 0, wl);
            nmShift = StockmanRiderCommonPhotopigmentTemplateTest.peakWavelength( ...
                testCase.Template, 'L', -15, wl);
            testCase.verifyLessThan(nmShift, nm0, ...
                'Negative shift should move peak to shorter wavelength');
        end

        %% Opsin-Template Option Handling

        function testOpsinOptionIgnoredWithWarning(testCase)
            % Opsin-template options must be ignored with a warning.
            wl = testCase.TestWavelengths;
            options = struct('L_Template', "Serine");
            testCase.verifyWarning( ...
                @() testCase.Template.computeAbsorbance(wl, 'L', 0, options), ...
                'StockmanRiderCommonPhotopigmentTemplate:IgnoredOption');
        end

        function testOpsinOptionDoesNotChangeResult(testCase)
            % The ignored option must not alter the computed absorbance.
            wl = testCase.TestWavelengths;
            warnState = warning('off', ...
                'StockmanRiderCommonPhotopigmentTemplate:IgnoredOption');
            cleanup = onCleanup(@() warning(warnState));
            withOpt = testCase.Template.computeAbsorbance(wl, 'L', 0, ...
                struct('L_Template', "Serine"));
            withoutOpt = testCase.Template.computeAbsorbance(wl, 'L', 0, struct());
            testCase.verifyEqual(withOpt, withoutOpt, 'AbsTol', 1e-12);
        end

        function testNoWarningWithoutOpsinOption(testCase)
            % No warning should fire when no opsin-template option is given.
            wl = testCase.TestWavelengths;
            testCase.verifyWarningFree( ...
                @() testCase.Template.computeAbsorbance(wl, 'L', 0, struct()));
        end

        %% Property and Range Tests

        function testValidRange(testCase)
            % ValidRange should match the SR valid range [360, 830].
            testCase.verifyEqual(testCase.Template.ValidRange, [360, 830]);
        end

        function testSupportsAnalyticalPeakIsFalse(testCase)
            % The common template is pre-normalized to a peak of 1.0 but has
            % no closed form for the peak location, so consumers must find
            % it numerically.
            testCase.verifyFalse(testCase.Template.SupportsAnalyticalPeak);
        end

        function testShortName(testCase)
            testCase.verifyEqual(testCase.Template.ShortName, "StockmanRider2023Common");
        end

        %% Integration with IndividualCMF

        function testWiredIntoIndividualCMF(testCase)
            % The model name should construct the common template.
            obs = IndividualCMF(PhotopigmentModel="StockmanRider2023Common");
            testCase.verifyEqual(obs.PhotopigmentModel, ...
                enums.PhotopigmentModel.StockmanRider2023Common);
        end

        %% pycone Parity (guarded by python3 + vendored pycone)

        function testPyconeParity(testCase)
            % Compare against pycone LMSconelogcommon on a grid, if available.
            pyconeDir = fullfile(fileparts(mfilename('fullpath')), ...
                'parity', 'pycone');
            if ~isfile(fullfile(pyconeDir, 'CMFtemplates.py'))
                testCase.assumeFail('Vendored pycone not found');
            end
            [status, ~] = system('python3 --version');
            testCase.assumeEqual(status, 0, 'python3 not available');

            wl = (360:5:830)';
            coneMap = struct('L', 'Lser', 'M', 'M', 'S', 'S');
            for coneType = {'L', 'M', 'S'}
                ct = coneType{1};
                logAbs = testCase.Template.computeAbsorbance(wl, ct, 0, struct());
                ref = StockmanRiderCommonPhotopigmentTemplateTest.pyconeCommon( ...
                    pyconeDir, coneMap.(ct), 0, wl);
                testCase.verifyEqual(logAbs, ref, 'AbsTol', 1e-9, ...
                    sprintf('%s should match pycone LMSconelogcommon', ct));
            end
        end

    end

    methods(Static)
        function ref = pyconeCommon(pyconeDir, lms, shift, wl)
            % PYCONECOMMON  Evaluate pycone LMSconelogcommon at given wl.
            script = sprintf([ ...
                'import sys; sys.path.insert(0, r"%s")\n' ...
                'import numpy as np\n' ...
                'from CMFtemplates import LMSconelogcommon\n' ...
                'nm = np.array([%s])\n' ...
                'y = LMSconelogcommon(nm, "%s", %.10g)\n' ...
                'print("\\n".join("%%.15g" %% v for v in y))\n'], ...
                pyconeDir, strjoin(string(wl(:)'), ','), lms, shift);
            tmp = [tempname '.py'];
            fid = fopen(tmp, 'w');
            fprintf(fid, '%s', script);
            fclose(fid);
            cleanup = onCleanup(@() delete(tmp));
            [status, out] = system(['python3 ' tmp]);
            assert(status == 0, 'pycone evaluation failed: %s', out);
            ref = sscanf(out, '%g');
        end
    end
end

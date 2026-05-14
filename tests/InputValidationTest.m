classdef InputValidationTest < matlab.unittest.TestCase
    % INPUTVALIDATIONTEST  Tests for input validation and error handling.

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

    methods(Test)

        function testValidStandardObserver(testCase)
            % Test Standard 2-degree (Should pass)
            obs2 = IndividualCMF(StandardObserver=2);
            testCase.verifyEqual(obs2.Age, 32, 'Standard Observer Age must be 32');
            testCase.verifyEqual(obs2.FieldSize, 2, 'Standard Observer FieldSize must be 2');

            % Test Standard 10-degree (Should pass)
            obs10 = IndividualCMF(StandardObserver=10);
            testCase.verifyEqual(obs10.FieldSize, 10);
        end

        function testValidManualConfig(testCase)
            % Test manual configuration (Should pass)
            obs = IndividualCMF(Age=45, FieldSize=4);
            testCase.verifyEqual(obs.Age, 45);
            testCase.verifyEqual(obs.FieldSize, 4);
        end

        function testConflict_Standard_and_Age(testCase)
            testCase.verifyError(...
                @() IndividualCMF(StandardObserver=2, Age=40), ...
                'IndividualCMF:Conflict', ...
                'Should fail when Age is provided with StandardObserver');
        end

        function testConflict_Standard_and_FieldSize(testCase)
            % Updated to use verifyError directly
            testCase.verifyError(...
                @() IndividualCMF(StandardObserver=2, FieldSize=10), ...
                'IndividualCMF:Conflict', ...
                'Constructor should throw error for conflicting FieldSize');
        end

        function testConflict_Standard_and_Biophysics(testCase)
            testCase.verifyError(...
                @() IndividualCMF(StandardObserver=10, Lod=0.9), ...
                'IndividualCMF:Conflict', ...
                'Should fail when Lod override provided with StandardObserver');

            testCase.verifyError(...
                @() IndividualCMF(StandardObserver=2, MacularDensity=0.5), ...
                'IndividualCMF:Conflict', ...
                'Should fail when Macular override provided with StandardObserver');
        end

        function testShiftAndVariantValidation(testCase)
            % Standard Observer requires 0 shift and Mean template
            testCase.verifyError(...
                @() IndividualCMF(StandardObserver=2, L_LambdaMaxShift=5), ...
                'IndividualCMF:Conflict');

            testCase.verifyError(...
                @() IndividualCMF(StandardObserver=2, L_OpsinTemplate="Serine"), ...
                'IndividualCMF:Conflict');
        end

        function testConflict_Standard_and_HybridVariants(testCase)

            % L-cone Hybrid attempt
            testCase.verifyError(...
                @() IndividualCMF(StandardObserver=2, L_OpsinTemplate="MinL"), ...
                'IndividualCMF:Conflict', ...
                'Should fail when L-Cone Hybrid variant is set with Standard Observer');

            % M-cone Hybrid attempt
            testCase.verifyError(...
                @() IndividualCMF(StandardObserver=2, M_OpsinTemplate="LinM"), ...
                'IndividualCMF:Conflict', ...
                'Should fail when M-Cone Hybrid variant is set with Standard Observer');
        end

        % Add to methods(Test)

        function testEvaluateInvalidData(testCase)
            obs = IndividualCMF(StandardObserver=2);

            testCase.verifyError(...
                @() obs.evaluate(550, Data='XYZ'), ...
                'MATLAB:validators:mustBeMember', ...
                'Should reject invalid Data parameter');
        end

        function testEvaluateInvalidFormat(testCase)
            obs = IndividualCMF(StandardObserver=2);

            testCase.verifyError(...
                @() obs.evaluate(550, Format='csv'), ...
                'MATLAB:validators:mustBeMember', ...
                'Should reject invalid Format parameter');
        end

        function testEvaluateWithModifiedObserver(testCase)
            % Use Pokorny1987 lens model which has age-dependent lens density
            obs = IndividualCMF(Age=32, FieldSize=2, LensModel="Pokorny1987");
            wl = 500:10:600;  % Range around L-cone peak

            % Get baseline
            baseline = obs.evaluate(wl, Data='L');

            % Make a dramatic change - age affects lens density with Pokorny1987
            obs.Age = 70;  % Major age change
            aged = obs.evaluate(wl, Data='L');

            % Should be different (older age = more lens absorption = lower sensitivity)
            testCase.verifyNotEqual(aged, baseline, ...
                'evaluate() should reflect property changes (age affects lens density with Pokorny1987)');
        end

        function testEvaluateConsistencyAfterChanges(testCase)
            % Verify evaluate() and direct methods stay consistent
            obs = IndividualCMF(Age=32, FieldSize=10);
            wl = (400:10:700)';  % Column vector

            % Change multiple properties
            obs.Age = 45;
            obs.OutputFormat = "quantal";
            obs.NormalizeOutput = false;

            % Compare methods
            LMS_direct = obs.LMS(wl);
            LMS_eval = obs.evaluate(wl);

            % Verify sizes match
            testCase.verifySize(LMS_direct, size(LMS_eval), ...
                'Size mismatch between LMS() and evaluate');

            testCase.verifyEqual(LMS_eval, LMS_direct, 'AbsTol', 1e-10, ...
                'evaluate() should match LMS() after property changes');
        end

        function testWavelengthWarningIssuedForOutOfRange(testCase)
            obs = IndividualCMF(StandardObserver=10);
            obs.WavelengthWarning = true;

            % Stockman-Rider template has valid range [360, 830] nm
            % Request wavelengths outside this range
            wl = (340:10:850)';

            testCase.verifyWarning(@() obs.L(wl), 'IndividualCMF:WavelengthOutOfRange', ...
                'Should warn when wavelengths are outside the valid range');
        end

        function testWavelengthWarningOnlyOnce(testCase)
            obs = IndividualCMF(StandardObserver=10);
            obs.WavelengthWarning = true;

            % First call should warn
            wl_out = (340:10:380)';
            testCase.verifyWarning(@() obs.L(wl_out), 'IndividualCMF:WavelengthOutOfRange', ...
                'First call should warn');

            % Subsequent calls should NOT warn (warning already issued)
            testCase.verifyWarningFree(@() obs.L(wl_out), ...
                'Second call with same object should not warn again');

            testCase.verifyWarningFree(@() obs.M(wl_out), ...
                'Third call with same object should not warn again');
        end

        function testWavelengthWarningDisabled(testCase)
            obs = IndividualCMF(StandardObserver=10);
            obs.WavelengthWarning = false;

            wl_out = (340:10:380)';
            testCase.verifyWarningFree(@() obs.L(wl_out), ...
                'Should not warn when WavelengthWarning is disabled');
        end

        function testWavelengthWarningValidRangeNoWarning(testCase)
            obs = IndividualCMF(StandardObserver=10);
            obs.WavelengthWarning = true;

            % Request wavelengths strictly within Stockman-Rider valid range [360, 830]
            wl_valid = (400:10:700)';

            testCase.verifyWarningFree(@() obs.L(wl_valid), ...
                'Valid wavelengths should not trigger warning');
        end

        function testWavelengthWarningResetsOnTemplateChange(testCase)
            obs = IndividualCMF(StandardObserver=10);
            obs.WavelengthWarning = true;

            % Trigger the warning with Stockman-Rider template
            wl_out = (340:10:380)';
            testCase.verifyWarning(@() obs.L(wl_out), 'IndividualCMF:WavelengthOutOfRange', ...
                'First call should warn');

            % Verify warning is not issued again
            testCase.verifyWarningFree(@() obs.L(wl_out), ...
                'Second call should not warn again');

            % Change template to Govardovskii
            obs.PhotopigmentModel = "Govardovskii2000";

            % Now the warning should be issued again since template changed
            % Govardovskii has valid range [380, 780] nm, so 340-380 is still out of range
            testCase.verifyWarning(@() obs.L(wl_out), 'IndividualCMF:WavelengthOutOfRange', ...
                'Warning should reset after template change');
        end

        function testWavelengthWarningGovardovskiiRange(testCase)
            % Test Govardovskii template's different valid range [380, 780]
            obs = IndividualCMF(StandardObserver=10);
            obs.PhotopigmentModel = "Govardovskii2000";
            obs.WavelengthWarning = true;

            % Wavelengths 360-380 are valid for Stockman-Rider but invalid for Govardovskii
            wl_out = (360:5:400)';
            testCase.verifyWarning(@() obs.L(wl_out), 'IndividualCMF:WavelengthOutOfRange', ...
                'Govardovskii should warn for wavelengths below 380 nm');
        end

        function testWavelengthWarningGovardovskiiUpperBound(testCase)
            % Test Govardovskii template warns for wavelengths above 780 nm
            obs = IndividualCMF(StandardObserver=10);
            obs.PhotopigmentModel = "Govardovskii2000";
            obs.WavelengthWarning = true;

            % 800 nm is valid for Stockman-Rider but invalid for Govardovskii
            wl_out = (750:10:810)';
            testCase.verifyWarning(@() obs.L(wl_out), 'IndividualCMF:WavelengthOutOfRange', ...
                'Govardovskii should warn for wavelengths above 780 nm');
        end

    end
end

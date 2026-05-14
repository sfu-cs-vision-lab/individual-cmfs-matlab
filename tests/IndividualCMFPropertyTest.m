classdef IndividualCMFPropertyTest < matlab.unittest.TestCase
    % INDIVIDUALCMFPROPERTYTESTS  Tests for IndividualCMF property setters/getters.
    %   These tests cover:
    %   - M_LambdaMaxShift setter with bounds validation
    %   - S_LambdaMaxShift setter
    %   - M_OpsinTemplate setter/getter
    %   - L_OpsinTemplate warning with Govardovskii
    %   - PhotopigmentModel switching
    %   - Primaries property
    %   - Biophysical property changes

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada
    %
    % This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    % Licensed under AGPL-3.0-or-later. See LICENSE file for details.
    % Repository: https://github.com/sfu-cs-vision-lab/Individual-CMFs

    properties
        Observer
        TestWavelengths
    end

    methods(TestMethodSetup)
        function setupObserver(testCase)
            testCase.Observer = IndividualCMF(Age=32, FieldSize=2);
            testCase.TestWavelengths = (400:10:700)';
        end
    end

    methods(Test)

        %% M_LambdaMaxShift Tests

        function testMLambdaMaxShiftDefault(testCase)
            % Test default M_LambdaMaxShift value
            testCase.verifyEqual(testCase.Observer.M_LambdaMaxShift, 0);
        end

        function testMLambdaMaxShiftSet(testCase)
            % Test setting M_LambdaMaxShift
            testCase.Observer.M_LambdaMaxShift = 5;
            testCase.verifyEqual(testCase.Observer.M_LambdaMaxShift, 5);
        end

        function testMLambdaMaxShiftNegative(testCase)
            % Test negative M_LambdaMaxShift
            testCase.Observer.M_LambdaMaxShift = -10;
            testCase.verifyEqual(testCase.Observer.M_LambdaMaxShift, -10);
        end

        function testMLambdaMaxShiftBoundsLow(testCase)
            % Test M_LambdaMaxShift below minimum bound (-20)
            testCase.verifyError(@() setMShift(testCase.Observer, -25), ...
                'MATLAB:validators:mustBeInRange');
        end

        function testMLambdaMaxShiftBoundsHigh(testCase)
            % Test M_LambdaMaxShift above maximum bound (30)
            testCase.verifyError(@() setMShift(testCase.Observer, 35), ...
                'MATLAB:validators:mustBeInRange');
        end

        function testMLambdaMaxShiftEffectOnOutput(testCase)
            wl = testCase.TestWavelengths;
            val_base = testCase.Observer.M(wl);

            testCase.Observer.M_LambdaMaxShift = 10;
            val_shifted = testCase.Observer.M(wl);

            testCase.verifyNotEqual(val_base, val_shifted, ...
                'M shift should affect output');
        end

        function testMLambdaMaxShiftPeakMovement(testCase)
            wl = (480:2:600)';

            testCase.Observer.M_LambdaMaxShift = 0;
            m_base = testCase.Observer.M(wl);
            [~, idx_base] = max(m_base);

            testCase.Observer.M_LambdaMaxShift = 15;
            m_shifted = testCase.Observer.M(wl);
            [~, idx_shifted] = max(m_shifted);

            testCase.verifyGreaterThan(idx_shifted, idx_base, ...
                'Positive M shift should move peak to longer wavelength');
        end

        %% S_LambdaMaxShift Tests

        function testSLambdaMaxShiftDefault(testCase)
            % Test default S_LambdaMaxShift value
            testCase.verifyEqual(testCase.Observer.S_LambdaMaxShift, 0);
        end

        function testSLambdaMaxShiftSet(testCase)
            % Test setting S_LambdaMaxShift
            testCase.Observer.S_LambdaMaxShift = 3;
            testCase.verifyEqual(testCase.Observer.S_LambdaMaxShift, 3);
        end

        function testSLambdaMaxShiftEffectOnOutput(testCase)
            wl = (380:5:500)';
            val_base = testCase.Observer.S(wl);

            testCase.Observer.S_LambdaMaxShift = 8;
            val_shifted = testCase.Observer.S(wl);

            testCase.verifyNotEqual(val_base, val_shifted, ...
                'S shift should affect output');
        end

        %% M_OpsinTemplate Tests

        function testMOpsinTemplateDefault(testCase)
            % Test default M_OpsinTemplate value
            % Default depends on implementation, just verify it's the enum type
            template = testCase.Observer.M_OpsinTemplate;
            testCase.verifyClass(template, 'enums.MOpsinTemplate');
        end

        function testMOpsinTemplateSetStandard(testCase)
            % Test setting M_OpsinTemplate to Standard
            testCase.Observer.M_OpsinTemplate = "Standard";
            testCase.verifyEqual(string(testCase.Observer.M_OpsinTemplate), "Standard");
        end

        function testMOpsinTemplateSetLInM(testCase)
            % Test setting M_OpsinTemplate to L-in-M
            testCase.Observer.M_OpsinTemplate = "LinM";
            testCase.verifyEqual(string(testCase.Observer.M_OpsinTemplate), "LinM");
        end

        function testMOpsinTemplateEffectOnOutput(testCase)
            wl = testCase.TestWavelengths;

            testCase.Observer.M_OpsinTemplate = "Standard";
            val_std = testCase.Observer.M(wl);

            testCase.Observer.M_OpsinTemplate = "LinM";
            val_linm = testCase.Observer.M(wl);

            testCase.verifyNotEqual(val_std, val_linm, ...
                'Different M templates should produce different outputs');
        end

        function testMOpsinTemplateWarningWithGovardovskii(testCase)
            obs = IndividualCMF(Age=32, FieldSize=2, PhotopigmentModel="Govardovskii2000");

            testCase.verifyWarning(@() setMTemplate(obs, "Standard"), ...
                'IndividualCMF:IgnoredProperty');
        end

        function testMOpsinTemplateConstructor(testCase)
            % Test M_OpsinTemplate in constructor
            obs = IndividualCMF(Age=32, FieldSize=2, M_OpsinTemplate="Standard");
            testCase.verifyEqual(string(obs.M_OpsinTemplate), "Standard", ...
                'M template should be set via constructor');
        end

        %% L_OpsinTemplate Warning Tests

        function testLOpsinTemplateWarningWithGovardovskii(testCase)
            obs = IndividualCMF(Age=32, FieldSize=2, PhotopigmentModel="Govardovskii2000");

            testCase.verifyWarning(@() setLTemplate(obs, "Serine"), ...
                'IndividualCMF:IgnoredProperty');
        end

        %% PhotopigmentModel Tests

        function testPhotopigmentModelSwitching(testCase)
            % Test switching template models
            obs = IndividualCMF(Age=32, FieldSize=2);
            wl = (400:10:700)';

            % Start with default (StockmanRider)
            testCase.verifyEqual(string(obs.PhotopigmentModel), "StockmanRider2023");
            LMS1 = [obs.L(wl), obs.M(wl), obs.S(wl)];

            % Switch to Govardovskii
            obs.PhotopigmentModel = "Govardovskii2000";
            testCase.verifyEqual(string(obs.PhotopigmentModel), "Govardovskii2000");
            LMS2 = [obs.L(wl), obs.M(wl), obs.S(wl)];

            testCase.verifyNotEqual(LMS1, LMS2, ...
                'Different template models should produce different outputs');
        end

        function testPhotopigmentModelInvalid(testCase)
            % Test invalid template model
            testCase.verifyError(@() setPhotopigmentModel(testCase.Observer, "InvalidModel"), ...
                'MATLAB:validation:UnableToConvert');
        end

        %% Primaries Property Tests

        function testPrimariesDefault(testCase)
            % Test default primaries
            primaries = testCase.Observer.Primaries;
            testCase.verifySize(primaries, [1, 3], 'Primaries should be 1x3');
        end

        function testPrimariesSet(testCase)
            % Test setting custom primaries
            newPrimaries = [620, 540, 460];
            testCase.Observer.Primaries = newPrimaries;
            testCase.verifyEqual(testCase.Observer.Primaries, newPrimaries);
        end

        function testPrimariesEffectOnRGB(testCase)
            originalPrimaries = testCase.Observer.Primaries;
            newPrimaries = [625, 532, 470];
            testCase.Observer.Primaries = newPrimaries;
            testCase.verifyEqual(testCase.Observer.Primaries, newPrimaries);
            testCase.verifyNotEqual(originalPrimaries, newPrimaries);
        end

        %% Biophysical Property Tests

        function testLodSet(testCase)
            wl = testCase.TestWavelengths;

            % Create two observers with different Lod values
            obs1 = IndividualCMF(Age=32, FieldSize=2, Lod=0.38);
            obs2 = IndividualCMF(Age=32, FieldSize=2, Lod=0.50);

            l1 = obs1.L(wl);
            l2 = obs2.L(wl);

            testCase.verifyNotEqual(l1, l2, ...
                'Different L optical density should produce different L output');
        end

        function testModSet(testCase)
            % Test setting M optical density
            wl = testCase.TestWavelengths;
            LMS1 = [testCase.Observer.L(wl), testCase.Observer.M(wl), testCase.Observer.S(wl)];

            testCase.Observer.Mod = 0.45;
            testCase.verifyEqual(testCase.Observer.Mod, 0.45);

            LMS2 = [testCase.Observer.L(wl), testCase.Observer.M(wl), testCase.Observer.S(wl)];
            testCase.verifyNotEqual(LMS1, LMS2, ...
                'Changing M optical density should affect output');
        end

        function testSodSet(testCase)
            % Test setting S optical density
            wl = testCase.TestWavelengths;
            LMS1 = [testCase.Observer.L(wl), testCase.Observer.M(wl), testCase.Observer.S(wl)];

            testCase.Observer.Sod = 0.35;
            testCase.verifyEqual(testCase.Observer.Sod, 0.35);

            LMS2 = [testCase.Observer.L(wl), testCase.Observer.M(wl), testCase.Observer.S(wl)];
            testCase.verifyNotEqual(LMS1, LMS2, ...
                'Changing S optical density should affect output');
        end

        function testMacularDensitySet(testCase)
            % Test setting macular density
            wl = testCase.TestWavelengths;
            LMS1 = [testCase.Observer.L(wl), testCase.Observer.M(wl), testCase.Observer.S(wl)];

            testCase.Observer.MacularDensity = 0.5;
            testCase.verifyEqual(testCase.Observer.MacularDensity, 0.5);

            LMS2 = [testCase.Observer.L(wl), testCase.Observer.M(wl), testCase.Observer.S(wl)];
            testCase.verifyNotEqual(LMS1, LMS2, ...
                'Changing macular density should affect output');
        end

        function testLensDensitySet(testCase)
            % Test setting lens density
            wl = testCase.TestWavelengths;
            LMS1 = [testCase.Observer.L(wl), testCase.Observer.M(wl), testCase.Observer.S(wl)];

            testCase.Observer.LensDensity = 2.0;
            testCase.verifyEqual(testCase.Observer.LensDensity, 2.0);

            LMS2 = [testCase.Observer.L(wl), testCase.Observer.M(wl), testCase.Observer.S(wl)];
            testCase.verifyNotEqual(LMS1, LMS2, ...
                'Changing lens density should affect output');
        end

        %% Output Format Tests

        function testNormalizeOutputSet(testCase)
            % Test setting NormalizeOutput
            wl = testCase.TestWavelengths;

            testCase.Observer.NormalizeOutput = true;
            LMS_norm = [testCase.Observer.L(wl), testCase.Observer.M(wl), testCase.Observer.S(wl)];
            maxVals_norm = max(LMS_norm);

            testCase.Observer.NormalizeOutput = false;
            LMS_unnorm = [testCase.Observer.L(wl), testCase.Observer.M(wl), testCase.Observer.S(wl)];
            maxVals_unnorm = max(LMS_unnorm);

            % Normalized should have max closer to 1
            testCase.verifyLessThan(max(abs(maxVals_norm - 1)), max(abs(maxVals_unnorm - 1)), ...
                'Normalized output should have max values closer to 1');
        end

        function testLogOutputSet(testCase)
            % Test setting LogOutput
            wl = testCase.TestWavelengths;

            testCase.Observer.LogOutput = false;
            LMS_lin = [testCase.Observer.L(wl), testCase.Observer.M(wl), testCase.Observer.S(wl)];

            testCase.Observer.LogOutput = true;
            LMS_log = [testCase.Observer.L(wl), testCase.Observer.M(wl), testCase.Observer.S(wl)];

            % Log values should be negative for values < 1
            testCase.verifyTrue(all(LMS_log(:) < 0), ...
                'Log output should be negative for normalized sensitivities');
        end

        %% Multiple Property Changes

        function testPhotopigmentModelGetterGovardovskii(testCase)
            % Test PhotopigmentModel getter with Govardovskii
            obs = IndividualCMF(Age=32, FieldSize=2, PhotopigmentModel="Govardovskii2000");
            model = obs.PhotopigmentModel;
            testCase.verifyEqual(string(model), "Govardovskii2000");
        end

        function testPhotopigmentModelGetterStockmanRider(testCase)
            % Test PhotopigmentModel getter with StockmanRider
            obs = IndividualCMF(Age=32, FieldSize=2, PhotopigmentModel="StockmanRider2023");
            model = obs.PhotopigmentModel;
            testCase.verifyEqual(string(model), "StockmanRider2023");
        end

        function testMultiplePropertyChanges(testCase)
            % Use Pokorny1987 lens model since StockmanRider2023 has no lens aging
            obs = IndividualCMF(Age=32, FieldSize=2, L_OpsinTemplate="Serine", LensModel="Pokorny1987");
            wl = testCase.TestWavelengths;

            % Get baseline
            val1 = obs.L(wl);

            % Change Age - affects output because Pokorny1987 has lens aging
            obs.Age = 60;
            val2 = obs.L(wl);
            testCase.verifyNotEqual(val1, val2, 'Age change should affect output with Pokorny1987 lens model');

            % Change FieldSize
            obs.FieldSize = 10;
            val3 = obs.L(wl);
            testCase.verifyNotEqual(val2, val3, 'FieldSize change should affect output');

            % Change L shift (Serine template supports shifts)
            obs.L_LambdaMaxShift = -5;
            val4 = obs.L(wl);
            testCase.verifyNotEqual(val3, val4, 'L shift change should affect output');

            % Change optical density
            obs.Lod = 0.6;
            val5 = obs.L(wl);
            testCase.verifyNotEqual(val4, val5, 'Optical density change should affect output');
        end

    end
end

%% Helper functions for verifyWarning/verifyError with property assignment

function setMShift(obj, value)
obj.M_LambdaMaxShift = value;
end

function setMTemplate(obj, value)
obj.M_OpsinTemplate = value;
end

function setLTemplate(obj, value)
obj.L_OpsinTemplate = value;
end

function setPhotopigmentModel(obj, value)
obj.PhotopigmentModel = value;
end

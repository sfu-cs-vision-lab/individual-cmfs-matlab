classdef ReferenceParityTest < matlab.unittest.TestCase
    % REFERENCEPARITYTEST  Tests for parity with reference implementations.

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
        LegacyData
    end

    methods(TestMethodSetup)
        function loadData(testCase)
            % robust path loading
            folder = fileparts(mfilename('fullpath'));
            testCase.LegacyData = readtable(fullfile(folder, 'data', 'govardovskii_reference.csv'));
        end
    end

    methods(Test)
        function testMatchLegacyGovardovskii(testCase)
            % 1. Align Class with Legacy Integer Peaks (560, 530, 430)
            % The class defaults to CIE values (558.9, 530.3, 420.7), so we must shift them.
            shift_L = 560 - 558.9; %  1.1
            shift_M = 530 - 530.3; % -0.3
            shift_S = 430 - 420.7; %  9.3

            obs = IndividualCMF(PhotopigmentModel="Govardovskii2000", ...
                Lod=0.3, Mod=0.3, Sod=0.3, ...
                L_LambdaMaxShift=shift_L, ...
                M_LambdaMaxShift=shift_M, ...
                S_LambdaMaxShift=shift_S);

            % 2. Configure output to match golden data
            obs.OutputFormat = "absorptance";
            obs.NormalizeOutput = true;

            % 3. Evaluate and Verify
            wl = testCase.LegacyData.nm;
            new_LMS = obs.evaluate(wl);

            legacy_matrix = [testCase.LegacyData.L_absorptance, ...
                testCase.LegacyData.M_absorptance, ...
                testCase.LegacyData.S_absorptance];

            testCase.verifyEqual(new_LMS, legacy_matrix, 'AbsTol', 1e-10, ...
                'Class implementation does not match legacy Govardovskii data');
        end

        function testGovardovskiiShiftPlumbing(testCase)
            % Verify that setting a shift actually moves the peak wavelength
            shift_amount = 10; % nm
            base_L = 558.9;

            obs = IndividualCMF(PhotopigmentModel="Govardovskii2000", ...
                L_LambdaMaxShift=shift_amount, ...
                OutputFormat="absorbance"); % Use absorbance to see raw peak

            % Evaluate near the expected shifted peak
            target_peak = base_L + shift_amount;
            wl = (target_peak-5 : 0.1 : target_peak+5)';
            l_curve = obs.evaluate(wl, Data="L");

            [~, idx] = max(l_curve);
            found_peak = wl(idx);

            testCase.verifyEqual(found_peak, target_peak, 'AbsTol', 0.1, ...
                'Govardovskii L-cone peak did not shift to the expected wavelength.');
        end

        function testBetaBandCoupling(testCase)
            % Govardovskii predicts the Beta band peak is coupled to Alpha peak.
            % We use a NEGATIVE shift to stay within valid range (-40 to 10).

            % Test scans 300-400 nm to locate the beta peak; that range
            % is below the Govardovskii valid-range floor (380 nm) so a
            % wavelength warning fires incidentally. Suppress it -- this
            % test verifies beta-peak coupling, not warning behaviour.
            testCase.applyFixture( ...
                matlab.unittest.fixtures.SuppressedWarningsFixture( ...
                    'Nomograms:WavelengthOutOfRange'));

            shift = -20; % 20nm Blue Shift (Valid)
            base_L = 558.9;
            shifted_L = base_L + shift;

            obs = IndividualCMF(PhotopigmentModel="Govardovskii2000", ...
                                L_LambdaMaxShift=shift, ...
                                OutputFormat="absorbance");

            % Calculate expected Beta peak location
            % Eq 5a: Lambda_beta = 189 + 0.315 * Lambda_alpha
            expected_beta_peak = 189 + 0.315 * shifted_L;

            % Scan UV range to find actual peak
            wl = (300:0.5:400)';
            l_curve = obs.evaluate(wl, Data="L");

            [~, idx] = max(l_curve);
            found_peak = wl(idx);

            % Note: Testing combined alpha+beta spectrum maximum, not isolated beta center.
            % The alpha band tail shifts observed UV maximum ~1-1.5nm redward.
            testCase.verifyEqual(found_peak, expected_beta_peak, 'AbsTol', 1.5, ...
                'Beta band maximum should be near location predicted by Govardovskii eq. 5a');
        end

        function testTemplateGoldenData(testCase)
            % Validates MATLAB output against Python 'template_verification.csv'
            folder = fileparts(mfilename('fullpath'));
            dataFile = fullfile(folder, 'data', 'template_verification.csv');
            testCase.assumeTrue(exist(dataFile, 'file') == 2, ...
                'Skipping: template_verification.csv not found');
            templateData = readtable(dataFile);

            wl = templateData.wavelength;

            % 1. Verify Mean (Standard) L-cone
            obs = IndividualCMF(StandardObserver=2);
            obs.OutputFormat = "absorbance";
            obs.NormalizeOutput = false;

            L_matlab = obs.L(wl);
            testCase.verifyEqual(L_matlab, templateData.l_mean_absorbance, ...
                'RelTol', 1e-5, 'Mean L-cone absorbance mismatch against Python golden data');

            % 2. Verify Serine Template
            obs.L_OpsinTemplate = "Serine";
            L_ser_matlab = obs.L(wl);
            testCase.verifyEqual(L_ser_matlab, templateData.l_serine_absorbance, ...
                'RelTol', 1e-5, 'Serine L-cone absorbance mismatch against Python golden data');

            % 3. Verify Hybrid Template (M-in-L)
            if ismember('l_hybrid_absorbance', templateData.Properties.VariableNames)
                obs.L_OpsinTemplate = "MinL";
                L_hyb_matlab = obs.L(wl);
                testCase.verifyEqual(L_hyb_matlab, templateData.l_hybrid_absorbance, ...
                    'RelTol', 1e-5, 'Hybrid (M-in-L) absorbance mismatch against Python golden data');
            end
        end

        function testBandwidthDependency(testCase)
            % Govardovskii pigments should get wider as lambda_max increases (Redder).
            % We compare "Blue-shifted" (-30) vs "Standard" (0) to stay in range.
            
            % 1. Blue Shifted (-30 nm)
            obs_blue = IndividualCMF(PhotopigmentModel="Govardovskii2000", ...
                                     L_LambdaMaxShift=-30, ...
                                     OutputFormat="absorbance");
            wl = (300:1:800)';
            curve_blue = obs_blue.evaluate(wl, Data="L");
            
            % 2. Standard / Redder (0 nm)
            obs_red  = IndividualCMF(PhotopigmentModel="Govardovskii2000", ...
                                     L_LambdaMaxShift=0, ...
                                     OutputFormat="absorbance");
            curve_red = obs_red.evaluate(wl, Data="L");
            
            % 3. Calculate FWHM (Full Width Half Max)
            width_blue = sum(curve_blue > 0.5);
            width_red  = sum(curve_red  > 0.5);
            
            % The redder pigment (0nm) MUST be wider than the bluer pigment (-30nm)
            testCase.verifyGreaterThan(width_red, width_blue, ...
                'Govardovskii physics violation: Red-shifted pigment should be wider than Blue-shifted pigment.');
        end
        
    end
end
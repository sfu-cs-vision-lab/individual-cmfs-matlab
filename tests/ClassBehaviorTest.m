classdef ClassBehaviorTest < matlab.unittest.TestCase
    % CLASSBEHAVIORTEST  Tests for class behavior and property updates.

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

        function testCacheCallbackMethodsAreNotPublic(testCase)
            % Regression guard: computeRawSensitivity, computePeakForFormat,
            % and computeAnalyticalAbsorptancePeak exist solely to support
            % NormalizationCache and white-box tests in NormalizationTest.
            % They must not be callable from arbitrary external code,
            % otherwise they leak into the public API surface. This test
            % runs from ClassBehaviorTest, which is intentionally NOT in
            % the friend list, so the calls below must error.
            obs = IndividualCMF();
            testCase.verifyError(@() obs.computeRawSensitivity(550, 'L', "energy"), ...
                'MATLAB:class:MethodRestricted');
            testCase.verifyError(@() obs.computePeakForFormat('L', "energy"), ...
                'MATLAB:class:MethodRestricted');
            testCase.verifyError(@() obs.computeAnalyticalAbsorptancePeak('L'), ...
                'MATLAB:class:MethodRestricted');
        end

        function testPropertyUpdates(testCase)
            % Verify that changing properties triggers a recalculation
            % Use Pokorny1987 lens model since StockmanRider2023 has no lens aging

            % Initialize with Pokorny1987 for age-dependent behavior
            obs = IndividualCMF(Age=20, FieldSize=10, LensModel="Pokorny1987");
            wl = 500;

            % Get initial value
            val_initial = obs.L(wl);

            % Change Age - should change value with Pokorny1987 lens aging
            obs.Age = 80;
            val_age80 = obs.L(wl);

            testCase.verifyNotEqual(val_initial, val_age80, ...
                'Changing Age property should update output with Pokorny1987 lens model.');

            % Change Field Size - should change value
            obs.FieldSize = 2;
            val_field2 = obs.L(wl);

            testCase.verifyNotEqual(val_age80, val_field2, ...
                'Changing FieldSize property did not update the calculation output.');
        end
        
        function testInputShapes(testCase)
            % Verify Vectorization (Row in -> Row out, Col in -> Col out)
            obs = IndividualCMF(StandardObserver=2);
            
            % Test Row Input becomes row Output
            row_in = 400:10:700;
            row_out = obs.L(row_in);
            testCase.verifyTrue(isrow(row_out), 'Row input should yield Row output');
            testCase.verifyEqual(size(row_in), size(row_out), 'Output size mismatch');
            
            % Test Column Input becomes column output
            col_in = (400:10:700)';
            col_out = obs.L(col_in);
            testCase.verifyTrue(iscolumn(col_out), 'Column input should yield Column output');
            
            % Verify values are identical regardless of shape
            testCase.verifyEqual(row_out', col_out, ...
                'AbsTol', 1e-12, 'Values should match regardless of input vector orientation');
        end
        
        function testNormalization(testCase)
            % Verify internal peak finding logic using continuous optimization
            obs = IndividualCMF(StandardObserver=2);
            obs.NormalizeOutput = true;
            
            % Define a helper to find the true continuous peak of the output
            function p = findTruePeak(funcHandle, bounds)
                objFn = @(w) -1 * funcHandle(w);
                [~, negPeak] = fminbnd(objFn, bounds(1), bounds(2));
                p = -negPeak;
            end
            
            % Find the exact peaks of the L, M, and S outputs
            pL = findTruePeak(@obs.L, [500 650]);
            pM = findTruePeak(@obs.M, [480 600]);
            pS = findTruePeak(@obs.S, [400 480]);
            
            % Check peaks are exactly 1.0 with high precision
            testCase.verifyEqual(pL, 1.0, 'AbsTol', 1e-10, 'L-cone not normalized to 1.0');
            testCase.verifyEqual(pM, 1.0, 'AbsTol', 1e-10, 'M-cone not normalized to 1.0');
            testCase.verifyEqual(pS, 1.0, 'AbsTol', 1e-10, 'S-cone not normalized to 1.0');
            
            % Test disabling normalization (sanity check)
            obs.NormalizeOutput = false;
            % For this check, a simple point sample is sufficient to prove it changed
            l_val_at_peak = obs.L(555); 
            testCase.verifyNotEqual(l_val_at_peak, 1.0, 'Disabling normalization failed to change output');
        end
        
    end
end
classdef PerformanceTest < matlab.unittest.TestCase
    % PERFORMANCETEST  Performance regression tests.
    %   Ensures refactoring doesn't introduce performance regressions.

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

        function testEvaluationSpeed(testCase)
            % 100 full evaluations should complete in under 2 seconds
            obs = IndividualCMF(StandardObserver=2);
            wl = (380:780)';

            % Warm-up
            obs.evaluate(wl);

            % Timed run
            tic;
            for i = 1:100
                obs.evaluate(wl);
            end
            elapsed = toc;

            testCase.verifyLessThan(elapsed, 2.0, ...
                sprintf('Performance regression: 100 evaluations took %.2fs (limit: 2.0s)', elapsed));
        end

        function testConstructorSpeed(testCase)
            % 50 constructor calls should complete in under 1 second
            tic;
            for i = 1:50
                obs = IndividualCMF(Age=32, FieldSize=2); %#ok<NASGU>
            end
            elapsed = toc;

            testCase.verifyLessThan(elapsed, 1.0, ...
                sprintf('Constructor regression: 50 calls took %.2fs (limit: 1.0s)', elapsed));
        end

        function testTemplateCalculationSpeed(testCase)
            % Template calculations should be fast
            wl = (380:780)';

            % Test Govardovskii if it exists
            if exist('GovardovskiiPhotopigmentTemplate', 'class')
                t = GovardovskiiPhotopigmentTemplate();
                options = struct();
                tic;
                for i = 1:1000
                    t.computeAbsorbance(wl, 'L', 0, options);
                end
                elapsed = toc;

                testCase.verifyLessThan(elapsed, 2.0, ...
                    sprintf('GovardovskiiPhotopigmentTemplate: 1000 calls took %.2fs', elapsed));
            end

            % Test StockmanRider if it exists
            if exist('StockmanRiderPhotopigmentTemplate', 'class')
                t = StockmanRiderPhotopigmentTemplate();
                options = struct('L_Template', "Serine");
                tic;
                for i = 1:1000
                    t.computeAbsorbance(wl, 'L', 0, options);
                end
                elapsed = toc;

                testCase.verifyLessThan(elapsed, 2.0, ...
                    sprintf('StockmanRiderPhotopigmentTemplate: 1000 calls took %.2fs', elapsed));
            end
        end

    end
end

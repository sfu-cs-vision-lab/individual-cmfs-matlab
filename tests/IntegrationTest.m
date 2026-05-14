classdef IntegrationTest < matlab.unittest.TestCase
    % INTEGRATIONTEST  Integration tests for complete workflows.

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
        
        function testCompleteWorkflow(testCase)
            % Simulate a complete user workflow
            
            % 1. Create observer
            obs = IndividualCMF(Age=45, FieldSize=4);
            
            % 2. Get data in multiple formats
            wl = 400:10:700;
            
            array_LMS = obs.evaluate(wl);
            table_LMS = obs.evaluate(wl, Format='table');
            struct_LMS = obs.evaluate(wl, Format='struct');
            
            % 3. Verify consistency
            testCase.verifyEqual([table_LMS.L, table_LMS.M, table_LMS.S], ...
                array_LMS, 'AbsTol', 1e-10);
            testCase.verifyEqual([struct_LMS.L, struct_LMS.M, struct_LMS.S], ...
                array_LMS, 'AbsTol', 1e-10);
        end
        
        function testExportWorkflow(testCase)
            % Test typical export scenario
            obs = IndividualCMF(StandardObserver=2);
            wl = 400:5:700;
            
            % Export-friendly format
            data_table = obs.evaluate(wl, Format='table');
            
            % Verify it can be written to file
            temp_file = [tempname, '.csv'];
            writetable(data_table, temp_file);
            
            % Read back and verify
            read_back = readtable(temp_file);
            testCase.verifyEqual(height(read_back), height(data_table));
            testCase.verifyEqual(read_back.L, data_table.L, 'AbsTol', 1e-10);
            
            % Cleanup
            delete(temp_file);
        end
        
        function testCustomPhysiologyWorkflow(testCase)
            % Test custom physiology with multiple output formats
            obs = IndividualCMF(Age=60, FieldSize=2);
            obs.setGenotype('L', 180, 'Ala');
            obs.OutputFormat = "quantal";
            
            wl = 400:10:700;
            
            % Get various outputs
            LMS = obs.evaluate(wl);
            L_only = obs.evaluate(wl, Data='L');
            RGB = obs.evaluate(wl, Data='RGB');
            chrom = obs.evaluate(wl, Data='chromaticity');

            % Basic sanity checks
            testCase.verifySize(LMS, [length(wl), 3]);
            testCase.verifySize(L_only, [length(wl), 1]);
            testCase.verifySize(RGB, [length(wl), 3]);
            testCase.verifySize(chrom, [length(wl), 3]);
            
            % Chromaticity should sum to 1
            testCase.verifyEqual(sum(chrom, 2), ones(length(wl), 1), ...
                'AbsTol', 1e-10);
        end
        
        function testComparisonWorkflow(testCase)
            % Compare two observers with different ages
            % Use Pokorny1987 lens model since StockmanRider2023 has no lens aging
            obs_young = IndividualCMF(Age=20, FieldSize=2, LensModel="Pokorny1987");
            obs_old = IndividualCMF(Age=70, FieldSize=2, LensModel="Pokorny1987");

            wl = 400:10:700;

            LMS_young = obs_young.evaluate(wl);
            LMS_old = obs_old.evaluate(wl);

            % They should be different due to age-dependent lens density with Pokorny1987
            testCase.verifyNotEqual(LMS_young, LMS_old, ...
                'Different ages should produce different sensitivities with Pokorny1987');
        end
        
    end
end
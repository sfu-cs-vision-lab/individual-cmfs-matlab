classdef TestUtilities
    % TESTUTILITIES  Shared utilities for test classes.

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

    methods(Static)

        function data = loadTestData(filename)
            % Load test data with automatic path resolution
            %
            % Usage:
            %   data = TestUtilities.loadTestData('standard_2deg.csv');

            % Get the tests folder
            thisFile = mfilename('fullpath');
            testsFolder = fileparts(thisFile);
            filepath = fullfile(testsFolder, 'data', filename);

            if ~exist(filepath, 'file')
                data = [];
                return;
            end

            [~, ~, ext] = fileparts(filename);
            switch lower(ext)
                case '.csv'
                    data = readtable(filepath);
                case '.mat'
                    data = load(filepath);
                otherwise
                    error('TestUtilities:UnsupportedFormat', ...
                        'Unsupported file format: %s', ext);
            end
        end

        function verifyMatrixAgainstTable(testCase, matrix, refTable, prefix, tol)
            % Verify matrix columns against reference table columns
            %
            % Usage:
            %   TestUtilities.verifyMatrixAgainstTable(testCase, result, refData, 'LMS', 1e-10);

            arguments
                testCase matlab.unittest.TestCase
                matrix (:,:) double
                refTable table
                prefix string
                tol double = 1e-10
            end

            for col = 1:size(matrix, 2)
                colName = sprintf('%s_%d', prefix, col);
                if ismember(colName, refTable.Properties.VariableNames)
                    testCase.verifyEqual(matrix(:, col), refTable.(colName), ...
                        'AbsTol', tol, sprintf('%s mismatch', colName));
                end
            end
        end

        function tf = dataFileExists(filename)
            % Check if a test data file exists
            thisFile = mfilename('fullpath');
            testsFolder = fileparts(thisFile);
            filepath = fullfile(testsFolder, 'data', filename);
            tf = exist(filepath, 'file') == 2;
        end

    end
end

classdef XYZTest < matlab.unittest.TestCase
    % XYZTest  Verifies IndividualCMF.XYZ numerical output.

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada
    %
    % This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    % Licensed under AGPL-3.0-or-later. See LICENSE file for details.

    methods (Test)

        function testXYZ_YComponentEqualsLuminance_2Deg(testCase)
            % Y is V*(lambda) by definition.
            obs = IndividualCMF(StandardObserver=2);
            wl = (400:5:700)';
            XYZ = obs.XYZ(wl);
            testCase.verifyEqual(XYZ(:, 2), obs.Luminance(wl), 'AbsTol', 1e-10);
        end

        function testXYZ_YComponentEqualsLuminance_10Deg(testCase)
            obs = IndividualCMF(StandardObserver=10);
            wl = (400:5:700)';
            XYZ = obs.XYZ(wl);
            testCase.verifyEqual(XYZ(:, 2), obs.Luminance(wl), 'AbsTol', 1e-10);
        end

        function testXYZ_CustomMatrixHonorsPaperConvention(testCase)
            % A user-supplied TransformationMatrix M is in paper form
            % (row i produces output channel i). XYZ must apply it as
            % LMS * M.' so that a non-symmetric M flips axes the way a
            % colorimetrist expects when reading Stockman 2019 Eq. 4.
            obs = IndividualCMF(StandardObserver=2);
            wl = (400:10:700)';
            % Energy, peak-normalized LMS is what XYZ uses internally
            % regardless of obj.OutputFormat.
            LMS = obs.LMS(wl, OutputFormat="energy", ...
                NormalizeOutput=true, LogOutput=false);
            % Asymmetric matrix so transposing matters.
            M = [0.1, 0.2, 0.3; ...
                 0.4, 0.5, 0.6; ...
                 0.7, 0.0, 0.9];
            XYZ = obs.XYZ(wl, TransformationMatrix=M);
            testCase.verifyEqual(XYZ, LMS * M.', 'AbsTol', 1e-10);
        end

    end
end

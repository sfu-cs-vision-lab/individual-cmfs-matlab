classdef CIEReferenceTest < matlab.unittest.TestCase
    % CIEReferenceTest  Verify standard observers against CVRL CIE tables.
    %
    %   The toolbox uses the Stockman & Rider (2023) Fourier polynomial
    %   templates by default. Those templates are an approximation of
    %   the original Stockman-Sharpe / CIE 170-1:2006 tabulated cone
    %   fundamentals, with documented max fit residuals of ~1-2% in
    %   linear units (Stockman & Rider 2023, Table 4).
    %
    %   These tests download-once-vendored CVRL tables (see
    %   tests/data/cvrl/) and verify both the 2-deg and 10-deg standard
    %   observers stay within that documented fit residual. They will
    %   not catch sub-percent regressions in the polynomial coefficients
    %   - those are the job of PyconeParityTest, which compares against
    %   the polynomial fit at machine precision. CIEReferenceTest
    %   instead catches large regressions or accidental swaps of the
    %   underlying mathematical basis.
    %
    %   See also: tests/data/cvrl/NOTES.md, PyconeParityTest

    %   SPDX-License-Identifier: AGPL-3.0-or-later
    %
    %   Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    %   Simon Fraser University, Burnaby, British Columbia, Canada
    %
    %   This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    %   Licensed under AGPL-3.0-or-later. See LICENSE file for details.

    properties (Constant)
        % Documented Stockman-Rider 2023 fit residual against CIE tables.
        % Tightening this past 0.02 would require a non-parametric tabular
        % interpolation toolbox; the upside of the polynomial form is
        % parametric lambda-max shift support.
        FitResidualTol = 0.02
    end

    properties
        CIE2Deg
        CIE10Deg
    end

    methods (TestClassSetup)
        function loadCIETables(testCase)
            here = fileparts(mfilename('fullpath'));
            cvrlDir = fullfile(here, 'data', 'cvrl');
            testCase.assumeTrue(isfolder(cvrlDir), ...
                'CVRL reference tables not vendored at tests/data/cvrl');

            testCase.CIE2Deg = readmatrix(fullfile( ...
                cvrlDir, 'cie_2006_2deg_energy_1nm.csv'));
            testCase.CIE10Deg = readmatrix(fullfile( ...
                cvrlDir, 'cie_2006_10deg_energy_1nm.csv'));
        end
    end

    methods (Test)
        function test10DegStandardWithinFitResidual(testCase)
            obs = IndividualCMF(StandardObserver=10);
            obs.OutputFormat = "energy";
            obs.NormalizeOutput = true;
            obs.LogOutput = false;

            wl = testCase.CIE10Deg(:, 1);
            mat = obs.LMS(wl);
            CIE = testCase.CIE10Deg(:, 2:4);

            % CIE table has empty cells for S beyond the S-cone range.
            % Match toolbox behavior: zero-fill those positions.
            CIE(isnan(CIE)) = 0;

            tol = testCase.FitResidualTol;
            testCase.verifyLessThan(max(abs(mat(:,1) - CIE(:,1))), tol, ...
                'L cone differs from CIE 10-deg table by more than the SR2023 fit residual');
            testCase.verifyLessThan(max(abs(mat(:,2) - CIE(:,2))), tol, ...
                'M cone differs from CIE 10-deg table by more than the SR2023 fit residual');
            testCase.verifyLessThan(max(abs(mat(:,3) - CIE(:,3))), tol, ...
                'S cone differs from CIE 10-deg table by more than the SR2023 fit residual');
        end

        function test2DegStandardWithinFitResidual(testCase)
            obs = IndividualCMF(StandardObserver=2);
            obs.OutputFormat = "energy";
            obs.NormalizeOutput = true;
            obs.LogOutput = false;

            wl = testCase.CIE2Deg(:, 1);
            mat = obs.LMS(wl);
            CIE = testCase.CIE2Deg(:, 2:4);
            CIE(isnan(CIE)) = 0;

            tol = testCase.FitResidualTol;
            testCase.verifyLessThan(max(abs(mat(:,1) - CIE(:,1))), tol, ...
                'L cone differs from CIE 2-deg table by more than the SR2023 fit residual');
            testCase.verifyLessThan(max(abs(mat(:,2) - CIE(:,2))), tol, ...
                'M cone differs from CIE 2-deg table by more than the SR2023 fit residual');
            testCase.verifyLessThan(max(abs(mat(:,3) - CIE(:,3))), tol, ...
                'S cone differs from CIE 2-deg table by more than the SR2023 fit residual');
        end

        function testTypeIsCIE170(testCase)
            % If the configuration claims to be standards-compliant, the
            % Type property must say so explicitly.
            obs10 = IndividualCMF(StandardObserver=10);
            testCase.verifyEqual(obs10.Type, "CIE 170-1:2006");
            obs2 = IndividualCMF(StandardObserver=2);
            testCase.verifyEqual(obs2.Type, "CIE 170-1:2006");
        end
    end
end

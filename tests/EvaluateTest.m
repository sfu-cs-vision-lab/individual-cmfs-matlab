classdef EvaluateTest < matlab.unittest.TestCase
    % EVALUATETEST  Unit tests for the evaluate() method.
    %
    %   evaluate returns a table with a Wavelength_nm column plus one column
    %   per channel, and every Data branch delegates to the correspondingly
    %   named method. The tests here check that delegation, the table shape,
    %   and the chromaticity basis guarantee.

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
        Tolerance = 1e-10;
    end

    properties(TestParameter)
        % Every Data value, with the method it must delegate to and the
        % column names it must produce.
        DataCase = struct( ...
            LMS            = struct(Name="LMS",            Call=@(o,wl) o.LMS(wl),            Cols=["L" "M" "S"]), ...
            L              = struct(Name="L",              Call=@(o,wl) o.L(wl),              Cols="L"), ...
            M              = struct(Name="M",              Call=@(o,wl) o.M(wl),              Cols="M"), ...
            S              = struct(Name="S",              Call=@(o,wl) o.S(wl),              Cols="S"), ...
            RGB            = struct(Name="RGB",            Call=@(o,wl) o.RGB(wl),            Cols=["R" "G" "B"]), ...
            XYZ            = struct(Name="XYZ",            Call=@(o,wl) o.XYZ(wl),            Cols=["X" "Y" "Z"]), ...
            Luminance      = struct(Name="Luminance",      Call=@(o,wl) o.Luminance(wl),      Cols="V"), ...
            lmChromaticity = struct(Name="lmChromaticity", Call=@(o,wl) o.lmChromaticity(wl), Cols=["l" "m"]), ...
            xyChromaticity = struct(Name="xyChromaticity", Call=@(o,wl) o.xyChromaticity(wl), Cols=["x" "y"]), ...
            MacLeodBoynton = struct(Name="MacLeodBoynton", Call=@(o,wl) o.MacLeodBoynton(wl), Cols=["l_MB" "s_MB"]))
    end

    methods(TestMethodSetup)
        function setupObserver(testCase)
            testCase.Observer = IndividualCMF(StandardObserver=2);
            testCase.TestWavelengths = (400:10:700)';
        end
    end

    methods(Test)

        %% Delegation to the named methods

        function testEveryDataValueMatchesItsNamedMethod(testCase, DataCase)
            % The point of the rewrite: evaluate must not reimplement any
            % quantity, so each branch has to equal its named method exactly.
            wl = testCase.TestWavelengths;
            result = testCase.Observer.evaluate(wl, Data=DataCase.Name);
            expected = DataCase.Call(testCase.Observer, wl);

            testCase.verifyClass(result, 'table');
            testCase.verifyEqual(result.Wavelength_nm, wl, ...
                'Wavelength_nm column must match the input grid');
            testCase.verifyEqual(result.Properties.VariableNames, ...
                cellstr(["Wavelength_nm", DataCase.Cols]), ...
                sprintf('Column names wrong for Data=%s', DataCase.Name));

            actual = table2array(result(:, 2:end));
            testCase.verifyEqual(actual, expected, 'AbsTol', 0, ...
                sprintf('Data=%s must equal its named method exactly', DataCase.Name));
        end

        %% Table shape

        function testDefaultDataIsLMS(testCase)
            result = testCase.Observer.evaluate(testCase.TestWavelengths);
            testCase.verifyEqual(result.Properties.VariableNames, ...
                {'Wavelength_nm', 'L', 'M', 'S'});
        end

        function testSecondOutputIsTheWavelengthGrid(testCase)
            [result, wl] = testCase.Observer.evaluate(testCase.TestWavelengths);
            testCase.verifyEqual(wl, testCase.TestWavelengths);
            testCase.verifyEqual(result.Wavelength_nm, wl);
        end

        function testDefaultWavelengths(testCase)
            [result, wl] = IndividualCMF().evaluate();
            testCase.verifyEqual(wl(1), 380);
            testCase.verifyEqual(wl(end), 780);
            testCase.verifyEqual(height(result), 401);
        end

        function testSingleWavelength(testCase)
            result = testCase.Observer.evaluate(550);
            testCase.verifyEqual(height(result), 1);
            testCase.verifyEqual(width(result), 4);
        end

        function testRowVectorInputIsAccepted(testCase)
            % start:step:stop yields a row; evaluate must take it and return
            % the same table as the column form.
            wlRow = testCase.TestWavelengths';
            fromRow = testCase.Observer.evaluate(wlRow);
            fromCol = testCase.Observer.evaluate(testCase.TestWavelengths);
            testCase.verifyEqual(fromRow, fromCol);
        end

        %% Chromaticity basis

        function testChromaticityInvariantUnderOutputState(testCase)
            % Chromaticity is a projective normalization, so it must be
            % identical regardless of the observer's OutputFormat /
            % LogOutput / NormalizeOutput. Without forcing the right basis
            % the curve silently changes shape under
            % OutputFormat="absorbance" or LogOutput=true.
            wl = testCase.TestWavelengths;
            obs = IndividualCMF(StandardObserver=2);
            ref = obs.evaluate(wl, Data="lmChromaticity");

            obs.OutputFormat = "absorbance";
            testCase.verifyEqual(obs.evaluate(wl, Data="lmChromaticity"), ref, ...
                'chromaticity must not depend on OutputFormat');

            obs.OutputFormat = "energy";
            obs.LogOutput = true;
            testCase.verifyEqual(obs.evaluate(wl, Data="lmChromaticity"), ref, ...
                'chromaticity must not depend on LogOutput');

            obs.LogOutput = false;
            obs.NormalizeOutput = false;
            testCase.verifyEqual(obs.evaluate(wl, Data="lmChromaticity"), ref, ...
                'chromaticity must not depend on NormalizeOutput');
        end

        function testChromaticityCoordinatesAreBounded(testCase)
            % l and m are each a fraction of L+M+S, so both lie in [0, 1]
            % and their sum cannot exceed 1. The implicit third coordinate
            % is s = 1 - l - m, and the three must still sum to one.
            result = testCase.Observer.evaluate(testCase.TestWavelengths, ...
                Data="lmChromaticity");
            testCase.verifyGreaterThanOrEqual([result.l; result.m], 0);
            testCase.verifyLessThanOrEqual(result.l + result.m, 1 + testCase.Tolerance);

            s_implicit = 1 - result.l - result.m;
            testCase.verifyGreaterThanOrEqual(s_implicit, -testCase.Tolerance);
            testCase.verifyEqual(result.l + result.m + s_implicit, ...
                ones(height(result), 1), 'AbsTol', testCase.Tolerance);
        end

        function testChromaticityEntryPointsAgree(testCase)
            % Cross-API parity for the chromaticity quantity. All three
            % paths must produce the same lm coordinates:
            %   1) obs.evaluate(wl, Data="lmChromaticity")
            %   2) obs.lmChromaticity(wl)
            %   3) obs.plotChromaticity(wl) XData/YData
            %   MacLeodBoynton is a different convention and is excluded.
            obs = IndividualCMF(StandardObserver=2);
            wl = (400:5:700)';

            evalChrom = obs.evaluate(wl, Data="lmChromaticity");
            lmDirect = obs.lmChromaticity(wl);

            testCase.verifyEqual([evalChrom.l, evalChrom.m], lmDirect, 'AbsTol', 0, ...
                'evaluate must match lmChromaticity exactly');

            fig = figure('Visible', 'off');
            cleanup = onCleanup(@() close(fig)); %#ok<NASGU>
            p = obs.plotChromaticity(Wavelength=wl, Parent=axes(fig));
            testCase.verifyEqual(p(1).XData(:), lmDirect(:,1), 'AbsTol', 1e-12);
            testCase.verifyEqual(p(1).YData(:), lmDirect(:,2), 'AbsTol', 1e-12);
        end

        %% Output-state propagation

        function testEvaluateIntegrationWithTemplates(testCase)
            % The table carries real template output, not placeholder
            % numbers. A 1 nm grid puts the sampled peak close enough to
            % the true template maximum to pin normalization to within
            % ~2e-5.
            obs = IndividualCMF(StandardObserver=2);
            wl = (380:1:780)';
            result = obs.evaluate(wl, Data="LMS");

            for cone = ["L" "M" "S"]
                testCase.verifyGreaterThan(max(result.(cone)), 0, ...
                    sprintf('%s should have positive values', cone));
                testCase.verifyEqual(max(result.(cone)), 1.0, 'RelTol', 2e-5, ...
                    sprintf('%s should be normalized', cone));
            end
        end

        function testEvaluateRespectsOutputFormat(testCase)
            % evaluate delegates to LMS, so the observer's persistent
            % OutputFormat must reach the table.
            wl = testCase.TestWavelengths;
            obs = IndividualCMF(StandardObserver=2, OutputFormat="absorbance");
            result = obs.evaluate(wl, Data="LMS");
            testCase.verifyEqual(table2array(result(:, 2:end)), obs.LMS(wl), 'AbsTol', 0);
        end

        %% Invalid input

        function testInvalidDataErrors(testCase)
            testCase.verifyError( ...
                @() testCase.Observer.evaluate(testCase.TestWavelengths, Data='invalid'), ...
                'MATLAB:validators:mustBeMember');
        end

        function testFormatArgumentIsGone(testCase)
            % Format is removed: evaluate always returns a table. For an
            % array call the named method; for a struct use table2struct.
            testCase.verifyError( ...
                @() testCase.Observer.evaluate(testCase.TestWavelengths, Format='array'), ...
                'MATLAB:TooManyInputs');
        end

        function testChromaticityDataValueRenamed(testCase)
            % Data='chromaticity' is now Data="lmChromaticity", which also
            % makes room for xyChromaticity as a sibling.
            testCase.verifyError( ...
                @() testCase.Observer.evaluate(testCase.TestWavelengths, Data='chromaticity'), ...
                'MATLAB:validators:mustBeMember');
        end

        %% Export round trip

        function testTableIsWritetableReady(testCase)
            % The stated purpose of the table form.
            result = testCase.Observer.evaluate(testCase.TestWavelengths);
            f = fullfile(tempname + ".csv");
            cleanup = onCleanup(@() delete(f)); %#ok<NASGU>
            writetable(result, f);
            readBack = readtable(f);
            testCase.verifyEqual(readBack.Wavelength_nm, result.Wavelength_nm, 'AbsTol', 1e-9);
            testCase.verifyEqual(readBack.Properties.VariableNames, ...
                result.Properties.VariableNames);
        end

    end
end

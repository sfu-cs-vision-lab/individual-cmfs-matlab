classdef OutputStageTest < matlab.unittest.TestCase
    % OUTPUTSTAGETEST  Characterization tests for pipeline.OutputStage.
    %
    %   Pins the pure-function behavior of the four output helpers.
    %   Equivalence with the previous IndividualCMF behavior is covered
    %   by the existing public-API test suite (EvaluateTest,
    %   OutputFormatTest, NormalizationTest, PyconeParityTest, etc.)
    %   which all flow through the pipeline.

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada

    methods (Test)
        function testQuantalToEnergy(testCase)
            wl = [400; 500; 600];
            quantal = [0.5; 1.0; 0.5];
            energy = pipeline.OutputStage.quantalToEnergy(quantal, wl);
            testCase.verifyEqual(energy, [200; 500; 300]);
        end

        function testNormalizeIdentity(testCase)
            sens = [0.5; 1.0; 0.25];
            out = pipeline.OutputStage.normalize(sens, 1.0);
            testCase.verifyEqual(out, sens);
        end

        function testNormalizeDividesByPeak(testCase)
            sens = [0.5; 1.0; 0.25];
            out = pipeline.OutputStage.normalize(sens, 2.0);
            testCase.verifyEqual(out, [0.25; 0.5; 0.125]);
        end

        function testApplyLogBasic(testCase)
            sens = [1.0; 100; 0.1];
            out = pipeline.OutputStage.applyLog(sens);
            testCase.verifyEqual(out, [0; 2; -1], 'AbsTol', 1e-12);
        end

        function testApplyLogReplacesZero(testCase)
            % log10(0) = -Inf must be replaced with -10 (the toolbox
            % convention for "below dynamic range").
            sens = [1.0; 0; 100];
            out = pipeline.OutputStage.applyLog(sens);
            testCase.verifyEqual(out(1), 0);
            testCase.verifyEqual(out(2), -10);
            testCase.verifyEqual(out(3), 2);
        end

        function testApplyLogReplacesNaN(testCase)
            sens = [1.0; NaN; 100];
            out = pipeline.OutputStage.applyLog(sens);
            testCase.verifyEqual(out(2), -10);
        end

        function testCleanNaNNonLogReplacesNaNAndClampsNegatives(testCase)
            sens = [0.5; NaN; -0.1; 1.0];
            out = pipeline.OutputStage.cleanNaN(sens, false);
            testCase.verifyEqual(out, [0.5; 0; 0; 1.0]);
        end

        function testCleanNaNLogReplacesNaNOnly(testCase)
            % In log mode, only NaN is replaced. Negative log values
            % (e.g., -1.0 representing 10% sensitivity) are valid and
            % must be preserved. Inf is also not replaced -- callers
            % in this mode pass log-domain inputs that don't synthesize
            % Inf inside cleanNaN.
            sens = [0.5; NaN; -1.0; 0];
            out = pipeline.OutputStage.cleanNaN(sens, true);
            testCase.verifyEqual(out, [0.5; -10; -1.0; 0]);
        end
    end
end

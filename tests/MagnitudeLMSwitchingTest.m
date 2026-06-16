classdef MagnitudeLMSwitchingTest < matlab.unittest.TestCase
    % MAGNITUDELMSWITCHINGTEST  Direct-shift L/M template switching trip points.
    %
    %   A direct L_LambdaMaxShift / M_LambdaMaxShift large enough should swap
    %   the cone template the same way pycone does: the M cone borrows the L
    %   template (M_OpsinTemplate "LinM") once Mshift reaches the M->L exon-5
    %   shift, and the L cone borrows the M template (L_OpsinTemplate "MinL")
    %   once Lshift reaches the L->M exon-5 shift.
    %
    %   These assertions are anchored to the published Stockman & Rider /
    %   pycone trip points (18.41 nm and -16.0345 nm), not to the toolbox's
    %   own constants or to the parity port in run_pycone.py. That keeps them
    %   an independent backstop: a shared mistake that derived the threshold
    %   from 553.11 - 529.80 = 23.31 (giving 18.13 / -15.79) instead of
    %   554.86 - 531.19 = 23.67 would make both parity sides agree on the
    %   wrong value, and only a spec-anchored test like this would catch it.
    %   The 18.25 nm and -15.9 nm cases sit in exactly that gap.
    %
    %   The trip points (LMStemplateCMFs.py, useCodons == False):
    %       MisL  when  Mshift >= (M_L_277shift + M_L_285shift) = (7+14)*23.67/27 = 18.41
    %       LisM  when  Lshift <= (L_M_277shift + L_M_285shift) = (-7-14)*23.67/31 = -16.0345
    %   The asymmetry is intentional: the two directions use different scales
    %   (23.67/27 vs 23.67/31).
    %
    %   See also: IndividualCMF, GenotypeTest, tests/parity/run_pycone.py.

    %   SPDX-License-Identifier: AGPL-3.0-or-later
    %
    %   Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    %   Simon Fraser University, Burnaby, British Columbia, Canada
    %
    %   This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    %   Licensed under AGPL-3.0-or-later. See LICENSE file for details.

    properties (Constant)
        % Published pycone trip points (LMStemplateCMFs.py decision peaks
        % 554.86 / 531.19; difference 23.67). Hardcoded on purpose so this
        % test does not depend on the toolbox or the parity port.
        M_SWAP_THRESHOLD = 18.41
        L_SWAP_THRESHOLD = -16.0345
    end

    methods (Static)
        function obs = observerAtShift(lShift, mShift)
            % Direct-shift observer on the Serine L base, so the L cone shares
            % pycone's direct-shift Lser template and the swap is the only
            % variable.
            obs = IndividualCMF(Age=32, FieldSize=10, ...
                L_OpsinTemplate="Serine", ...
                L_LambdaMaxShift=lShift, M_LambdaMaxShift=mShift);
        end
    end

    methods (Test)

        function testMBelowThresholdDoesNotSwap(testCase)
            % M shifts below 18.41 leave the M cone on its own template.
            for mShift = [0, 17.0, 18.0, 18.3, 18.40]
                obs = MagnitudeLMSwitchingTest.observerAtShift(0, mShift);
                testCase.verifyNotEqual(string(obs.M_OpsinTemplate), "LinM", ...
                    sprintf('Mshift=%g (below 18.41) must not swap M to LinM', mShift));
            end
        end

        function testMAtAndAboveThresholdSwaps(testCase)
            % M shifts at or above 18.41 swap the M cone to the L template.
            for mShift = [testCase.M_SWAP_THRESHOLD, 18.42, 18.5, 22.0]
                obs = MagnitudeLMSwitchingTest.observerAtShift(0, mShift);
                testCase.verifyEqual(string(obs.M_OpsinTemplate), "LinM", ...
                    sprintf('Mshift=%g (>= 18.41) must swap M to LinM', mShift));
            end
        end

        function testLAboveThresholdDoesNotSwap(testCase)
            % L shifts above -16.0345 leave the L cone on its own template.
            for lShift = [0, -10.0, -15.0, -16.03]
                obs = MagnitudeLMSwitchingTest.observerAtShift(lShift, 0);
                testCase.verifyNotEqual(string(obs.L_OpsinTemplate), "MinL", ...
                    sprintf('Lshift=%g (above -16.0345) must not swap L to MinL', lShift));
            end
        end

        function testLAtAndBelowThresholdSwaps(testCase)
            % L shifts at or below -16.0345 swap the L cone to the M template.
            for lShift = [-16.04, -16.2, -20.0]
                obs = MagnitudeLMSwitchingTest.observerAtShift(lShift, 0);
                testCase.verifyEqual(string(obs.L_OpsinTemplate), "MinL", ...
                    sprintf('Lshift=%g (<= -16.0345) must swap L to MinL', lShift));
            end
        end

        function testGapDiscriminatorsProveTheLargerScale(testCase)
            % The 18.13-18.41 and -15.79 to -16.0345 gaps separate the 23.67
            % threshold from a 23.31 one. pycone does not swap here; a
            % 23.31-derived threshold would.
            obsM = MagnitudeLMSwitchingTest.observerAtShift(0, 18.25);
            testCase.verifyNotEqual(string(obsM.M_OpsinTemplate), "LinM", ...
                'Mshift=18.25 must not swap (would swap under a 23.31 threshold)');

            obsL = MagnitudeLMSwitchingTest.observerAtShift(-15.9, 0);
            testCase.verifyNotEqual(string(obsL.L_OpsinTemplate), "MinL", ...
                'Lshift=-15.9 must not swap (would swap under a 23.31 threshold)');
        end

        function testBothConesSwapPastBothThresholds(testCase)
            % Past both thresholds, both cones swap independently.
            obs = MagnitudeLMSwitchingTest.observerAtShift(-20.0, 22.0);
            testCase.verifyEqual(string(obs.M_OpsinTemplate), "LinM", ...
                'M must swap to LinM when Mshift=22.0');
            testCase.verifyEqual(string(obs.L_OpsinTemplate), "MinL", ...
                'L must swap to MinL when Lshift=-20.0');
        end

        function testCodonIdentityPathUnchanged(testCase)
            % The genotype-identity swap (amino acids 277/285) is independent
            % of the magnitude path and must keep resolving as before.
            obsL = IndividualCMF(Genotype="LATFA/SIAVA");
            testCase.verifyEqual(string(obsL.L_OpsinTemplate), "MinL", ...
                'Genotype Phe277+Ala285 must still resolve L to MinL');

            obsM = IndividualCMF(Genotype="LIAVA/SIAYT");
            testCase.verifyEqual(string(obsM.M_OpsinTemplate), "LinM", ...
                'Genotype Tyr277+Thr285 must still resolve M to LinM');

            obsNone = IndividualCMF(Genotype="LIAVA/SIAVA");
            testCase.verifyNotEqual(string(obsNone.L_OpsinTemplate), "MinL", ...
                'Standard genotype must not produce an L hybrid');
            testCase.verifyNotEqual(string(obsNone.M_OpsinTemplate), "LinM", ...
                'Standard genotype must not produce an M hybrid');
        end

    end
end

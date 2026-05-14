classdef DichromatBehaviorTest < matlab.unittest.TestCase
    % DICHROMATBEHAVIORTEST  Public-API contracts when a cone is absent.

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada
    %
    % This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    % Licensed under AGPL-3.0-or-later. See LICENSE file for details.
    % Repository: https://github.com/sfu-cs-vision-lab/Individual-CMFs

    properties(TestParameter)
        AbsentCone = struct( ...
            'L', struct('field', 'Lod', 'col', 1, 'label', "L"), ...
            'M', struct('field', 'Mod', 'col', 2, 'label', "M"), ...
            'S', struct('field', 'Sod', 'col', 3, 'label', "S"));
    end

    properties(Constant)
        WL = (400:10:700)';
    end

    methods(Test)

        function testRGB_ThrowsForAbsentCone(testCase, AbsentCone)
            obs = makeDichromat(AbsentCone.field);
            testCase.verifyError(@() obs.RGB(), ...
                'IndividualCMF:RGBUndefinedForDichromat');
        end

        function testRGB_ErrorListsAllAbsentCones(testCase)
            obs = IndividualCMF(Lod=0, Mod=0);
            try
                obs.RGB();
                testCase.verifyFail('Expected RGBUndefinedForDichromat');
            catch ME
                testCase.verifyEqual(ME.identifier, ...
                    'IndividualCMF:RGBUndefinedForDichromat');
                testCase.verifySubstring(ME.message, 'L, M');
            end
        end

        function testXYZ_ThrowsForAbsentCone(testCase, AbsentCone)
            obs = makeDichromat(AbsentCone.field);
            testCase.verifyError(@() obs.XYZ(), ...
                'IndividualCMF:XYZUndefinedForDichromat');
        end

        function testXYZ_CustomMatrixBypassesDichromatGuard(testCase)
            obs = makeDichromat('Lod');
            XYZ = obs.XYZ(testCase.WL, TransformationMatrix=eye(3));
            testCase.verifySize(XYZ, [numel(testCase.WL), 3]);
            testCase.verifyEqual(XYZ(:,1), zeros(numel(testCase.WL), 1));
        end

        function testXYZ_WarnsNonStandardFieldSize(testCase)
            obs = IndividualCMF(Age=32, FieldSize=5);
            restore = ensureWarningOn('IndividualCMF:NonStandardFieldSize'); %#ok<NASGU>
            testCase.verifyWarning(@() obs.XYZ(testCase.WL), ...
                'IndividualCMF:NonStandardFieldSize');
        end

        function testXYZ_WarnsNonStandardObserver(testCase)
            obs = IndividualCMF(Age=70, FieldSize=2);
            restore = ensureWarningOn('IndividualCMF:NonStandardObserver'); %#ok<NASGU>
            testCase.verifyWarning(@() obs.XYZ(testCase.WL), ...
                'IndividualCMF:NonStandardObserver');
        end

        function testXYZ_CustomMatrixSuppressesNonStandardWarnings(testCase)
            obs = IndividualCMF(Age=70, FieldSize=5);
            prevA = warning('error', 'IndividualCMF:NonStandardFieldSize');
            prevB = warning('error', 'IndividualCMF:NonStandardObserver');
            cleanup = onCleanup(@() warning([prevA prevB])); %#ok<NASGU>
            testCase.verifyWarningFree(...
                @() obs.XYZ(testCase.WL, TransformationMatrix=eye(3)));
        end

        function testLMS_ZeroColumnForAbsentCone(testCase, AbsentCone)
            obs = makeDichromat(AbsentCone.field);
            LMS = obs.LMS(testCase.WL);
            testCase.verifyEqual(LMS(:, AbsentCone.col), ...
                zeros(numel(testCase.WL), 1));
            present = setdiff(1:3, AbsentCone.col);
            testCase.verifyGreaterThan(sum(LMS(:, present(1))), 0);
            testCase.verifyGreaterThan(sum(LMS(:, present(2))), 0);
        end

        function testLMS_LogOutputFloorForAbsentCone(testCase, AbsentCone)
            % -10 (not -Inf) is the toolbox-wide "below dynamic range" floor;
            % swapping it for -Inf would silently break downstream math.
            obs = makeDichromat(AbsentCone.field);
            LMS = obs.LMS(testCase.WL, LogOutput=true);
            testCase.verifyEqual(LMS(:, AbsentCone.col), ...
                -10 * ones(numel(testCase.WL), 1));
        end

        function testPhotopigmentStage_AbsorptanceZeroForOdZero(testCase)
            % od == 0 collapses (1 - 10^-od) to zero; the short-circuit
            % prevents a 0/0 NaN result for gene-deletion dichromacy.
            linAbs = [0.1; 0.5; 0.9];
            out = pipeline.PhotopigmentStage.absorptanceFromAbsorbance(linAbs, 0);
            testCase.verifyEqual(out, zeros(size(linAbs)));
        end

    end
end

% -------------------------------------------------------------------------

function obs = makeDichromat(odField)
    obs = IndividualCMF();
    obs.(odField) = 0;
end

function cleanup = ensureWarningOn(id)
% Some test harnesses ship with custom warning IDs off by default. Force
% the ID on for the duration of the test and restore the prior state on
% exit so the warning state doesn't leak into adjacent tests.
    prev = warning('on', id);
    cleanup = onCleanup(@() warning(prev));
end

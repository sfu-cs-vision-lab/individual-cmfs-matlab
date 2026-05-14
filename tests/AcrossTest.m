classdef AcrossTest < matlab.unittest.TestCase
    % ACROSSTEST  Unit tests for IndividualCMF.across.
    %
    %   Verifies the static factory that builds an array of IndividualCMF
    %   observers across a single parameter axis with fixed name-value
    %   arguments propagated to every element.

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada
    %
    % This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    % Licensed under AGPL-3.0-or-later. See LICENSE file for details.

    methods (Test)
        function testNumericSweepAge(testCase)
            ages = [25 50 75];
            observers = IndividualCMF.across('Age', ages, ...
                LensModel="VanDeKraats2007", FieldSize=10);
            testCase.verifyEqual(size(observers), [1 3]);
            testCase.verifyEqual([observers.Age], ages);
            testCase.verifyTrue(all(arrayfun(@(o) string(o.LensModel) == "VanDeKraats2007", observers)));
            testCase.verifyTrue(all([observers.FieldSize] == 10));
        end

        function testGenotypeAsFixedArg(testCase)
            % Genotype is a constructor-only argument (not a settable
            % property); verify it still works as a fixed arg.
            observers = IndividualCMF.across('Age', [25 65], ...
                Genotype="LSAYT/SAAFA");
            testCase.verifyEqual(numel(observers), 2);
            for k = 1:numel(observers)
                testCase.verifyEqual(string(observers(k).L_OpsinTemplate), "Serine");
            end
        end

        function testStringSweepLensModel(testCase)
            models = ["StockmanRider2023", "Pokorny1987", "VanDeKraats2007"];
            observers = IndividualCMF.across('LensModel', models, Age=70);
            testCase.verifyEqual(numel(observers), 3);
            for k = 1:numel(observers)
                testCase.verifyEqual(string(observers(k).LensModel), models(k));
                testCase.verifyEqual(observers(k).Age, 70);
            end
        end

        function testScalarValuesReturns1x1(testCase)
            observers = IndividualCMF.across('Age', 40);
            testCase.verifyEqual(size(observers), [1 1]);
            testCase.verifyEqual(observers(1).Age, 40);
        end

        function testEmptyValuesReturnsEmpty(testCase)
            observers = IndividualCMF.across('Age', []);
            testCase.verifyTrue(isempty(observers));
            testCase.verifyEqual(class(observers), 'IndividualCMF');
        end

        function testNoFixedArgs(testCase)
            observers = IndividualCMF.across('FieldSize', [2 10]);
            testCase.verifyEqual(numel(observers), 2);
            testCase.verifyEqual([observers.FieldSize], [2 10]);
        end

        function testConflictRaises(testCase)
            testCase.verifyError( ...
                @() IndividualCMF.across('Age', [25 50], Age=32), ...
                'IndividualCMF:AcrossConflict');
        end

        function testUnknownParameterForwardsConstructorError(testCase)
            % An unknown parameter is rejected by the IndividualCMF constructor.
            testCase.verifyError( ...
                @() IndividualCMF.across('NotAParameter', [1 2]), ...
                'MATLAB:TooManyInputs');
        end

        function testInvalidValueForwardsConstructorError(testCase)
            % Age=-5 violates the constructor's validator.
            testCase.verifyError( ...
                @() IndividualCMF.across('Age', [-5 50]), ...
                'IndividualCMF:NotPositiveOrNan');
        end

        function testHandleIndependence(testCase)
            % Each observer must be an independent handle, not aliased
            observers = IndividualCMF.across('Age', [25 50 75], ...
                LensModel="VanDeKraats2007");
            observers(2).FieldSize = 4;
            testCase.verifyEqual(observers(1).FieldSize, 10);
            testCase.verifyEqual(observers(2).FieldSize, 4);
            testCase.verifyEqual(observers(3).FieldSize, 10);
        end

        function testPrimariesSweepViaCell(testCase)
            primSets = {[640 540 460], [620 530 470]};
            observers = IndividualCMF.across('Primaries', primSets);
            testCase.verifyEqual(observers(1).Primaries, [640 540 460]);
            testCase.verifyEqual(observers(2).Primaries, [620 530 470]);
        end

        function testPropertyVectorization(testCase)
            % Standard [observers.Prop] pattern should work on the result
            observers = IndividualCMF.across('Age', [25 50 75], ...
                LensModel="VanDeKraats2007");
            densities = [observers.LensDensity];
            testCase.verifyEqual(size(densities), [1 3]);
            testCase.verifyTrue(all(densities > 0));
            testCase.verifyTrue(densities(1) < densities(end));
        end
    end
end

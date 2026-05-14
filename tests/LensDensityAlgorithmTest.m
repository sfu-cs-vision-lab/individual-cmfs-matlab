classdef LensDensityAlgorithmTest < matlab.unittest.TestCase
    % LensDensityAlgorithmTest  Tests for the LensDensityAlgorithm property.
    %
    %   Verifies that LensDensity has parallel "Auto"/"Custom" semantics to
    %   the macular and photopigment density algorithms, so explicit
    %   LensDensity overrides survive subsequent Age, FieldSize, and
    %   LensModel changes.

    methods (Test)
        function testDefaultIsAuto(testCase)
            % Default-constructed observer starts in Auto lens-density mode.
            obs = IndividualCMF();
            testCase.verifyEqual(string(obs.LensDensityAlgorithm), "Auto");
        end

        function testStandardObserverIsAuto(testCase)
            % Standard observers don't allow LensDensity overrides, so they
            % must always be in Auto mode.
            obs = IndividualCMF(StandardObserver=10);
            testCase.verifyEqual(string(obs.LensDensityAlgorithm), "Auto");
        end

        function testExplicitLensDensityInConstructorEnablesCustom(testCase)
            % Passing LensDensity= to the constructor auto-engages Custom mode.
            obs = IndividualCMF(LensDensity=2.5);
            testCase.verifyEqual(string(obs.LensDensityAlgorithm), "Custom");
            testCase.verifyEqual(obs.LensDensity, 2.5, 'AbsTol', 1e-9);
        end

        function testExplicitAlgorithmInConstructor(testCase)
            % Passing LensDensityAlgorithm="Custom" without an explicit
            % LensDensity preserves whatever value was computed by the
            % active LensModel at construction time.
            obs = IndividualCMF(LensDensityAlgorithm="Custom");
            testCase.verifyEqual(string(obs.LensDensityAlgorithm), "Custom");
        end

        function testCustomModePreservesAcrossAgeChange(testCase)
            % In Custom mode, changing Age must not recompute LensDensity.
            obs = IndividualCMF(LensModel="Pokorny1987", Age=70, LensDensity=3.0);
            testCase.assertEqual(obs.LensDensity, 3.0, 'AbsTol', 1e-9);
            obs.Age = 30;
            testCase.verifyEqual(obs.LensDensity, 3.0, 'AbsTol', 1e-9, ...
                'Custom-mode LensDensity must survive Age changes.');
        end

        function testCustomModePreservesAcrossLensModelChange(testCase)
            % In Custom mode, switching LensModel must not recompute LensDensity.
            obs = IndividualCMF(LensModel="Pokorny1987", Age=70, LensDensity=3.0);
            testCase.assertEqual(obs.LensDensity, 3.0, 'AbsTol', 1e-9);
            obs.LensModel = "StockmanRider2023";
            testCase.verifyEqual(obs.LensDensity, 3.0, 'AbsTol', 1e-9, ...
                'Custom-mode LensDensity must survive LensModel changes.');
        end

        function testCustomModePreservesAcrossFieldSizeChange(testCase)
            % In Custom mode, changing FieldSize (which triggers
            % recalcBiophysics -> recalcLensFromAge) must not recompute LensDensity.
            obs = IndividualCMF(FieldSize=2, LensDensity=2.5);
            testCase.assertEqual(obs.LensDensity, 2.5, 'AbsTol', 1e-9);
            obs.FieldSize = 10;
            testCase.verifyEqual(obs.LensDensity, 2.5, 'AbsTol', 1e-9, ...
                'Custom-mode LensDensity must survive FieldSize changes.');
        end

        function testAutoModeRecomputesOnAgeWithPokorny(testCase)
            % In Auto mode with the age-dependent Pokorny1987 model,
            % changing Age must change LensDensity.
            obs = IndividualCMF(LensModel="Pokorny1987", Age=30);
            testCase.assertEqual(string(obs.LensDensityAlgorithm), "Auto");
            d30 = obs.LensDensity;
            obs.Age = 70;
            d70 = obs.LensDensity;
            testCase.verifyNotEqual(d30, d70, ...
                'Auto-mode LensDensity must change with Age under Pokorny1987.');
        end

        function testSwitchingToCustomViaSetterAutoEngages(testCase)
            % Direct assignment to LensDensity should auto-engage Custom mode.
            obs = IndividualCMF();
            testCase.assertEqual(string(obs.LensDensityAlgorithm), "Auto");
            obs.LensDensity = 2.7;
            testCase.verifyEqual(string(obs.LensDensityAlgorithm), "Custom");
            testCase.verifyEqual(obs.LensDensity, 2.7, 'AbsTol', 1e-9);
        end

        function testSwitchingFromCustomToAutoWarnsAndRecomputes(testCase)
            % Switching back to Auto should warn and recompute from Age.
            obs = IndividualCMF(LensModel="Pokorny1987", Age=70, LensDensity=3.0);
            testCase.assertEqual(string(obs.LensDensityAlgorithm), "Custom");
            testCase.verifyWarning(@() setLensAlgorithm(obs, "Auto"), ...
                'IndividualCMF:LensCustomOverwritten');
            testCase.verifyEqual(string(obs.LensDensityAlgorithm), "Auto");
            testCase.verifyNotEqual(obs.LensDensity, 3.0, ...
                'Auto must recompute LensDensity from Age, dropping the override.');
        end

        function testInternalRecalcDoesNotEngageCustom(testCase)
            % recalcLensFromAge writes to LensDensity internally; that write
            % must NOT auto-engage Custom (which would freeze the model).
            obs = IndividualCMF(LensModel="Pokorny1987", Age=30);
            testCase.assertEqual(string(obs.LensDensityAlgorithm), "Auto");
            obs.Age = 70;  % triggers recalcLensFromAge internally
            testCase.verifyEqual(string(obs.LensDensityAlgorithm), "Auto", ...
                'Internal recalc must not flip the algorithm to Custom.');
        end

        function testCustomModePreservedAcrossCopy(testCase)
            % Copying a Custom-mode observer must preserve the mode.
            obs = IndividualCMF(LensDensity=2.8);
            cp = copy(obs);
            testCase.verifyEqual(string(cp.LensDensityAlgorithm), "Custom");
            testCase.verifyEqual(cp.LensDensity, 2.8, 'AbsTol', 1e-9);
        end

        function testStandardObserverWithLensDensityErrors(testCase)
            % Sanity: standard observer still rejects LensDensity overrides.
            testCase.verifyError( ...
                @() IndividualCMF(StandardObserver=10, LensDensity=2.5), ...
                'IndividualCMF:Conflict');
        end

        function testNegativeLensDensityRejected(testCase)
            % Lens optical density is non-negative by physical definition.
            % The setter must refuse negative values rather than producing
            % non-physical pre-receptoral transmission > 1.
            obs = IndividualCMF();
            testCase.verifyError(@() setLensDensity(obs, -0.1), ...
                'MATLAB:validators:mustBeNonnegative');
        end

        function testNonFiniteLensDensityRejected(testCase)
            % Inf and NaN are non-physical and would propagate through the
            % normalization cache; reject at the setter. NaN trips
            % mustBeNonnegative first because NaN >= 0 is false.
            obs = IndividualCMF();
            testCase.verifyError(@() setLensDensity(obs, Inf), ...
                'MATLAB:validators:mustBeFinite');
            testCase.verifyError(@() setLensDensity(obs, NaN), ...
                'MATLAB:validators:mustBeNonnegative');
        end
    end
end

function setLensDensity(obs, v)
    obs.LensDensity = v;
end

function setLensAlgorithm(obs, alg)
    obs.LensDensityAlgorithm = alg;
end

classdef ObserverParametersRoundTripTest < matlab.unittest.TestCase
    % ObserverParametersRoundTripTest  Tests that getParameters / setParameters
    % preserve all observer state, including model selections and algorithm
    % modes that were previously lost on round-trip.

    methods (Test)
        function testGetParametersCapturesPhotopigmentModel(testCase)
            obs = IndividualCMF(PhotopigmentModel="Govardovskii2000");
            params = obs.getParameters();
            testCase.verifyEqual(string(params.PhotopigmentModel), "Govardovskii2000");
        end

        function testGetParametersCapturesLensModel(testCase)
            obs = IndividualCMF(LensModel="Pokorny1987");
            params = obs.getParameters();
            testCase.verifyEqual(string(params.LensModel), "Pokorny1987");
        end

        function testGetParametersCapturesOpsinTemplates(testCase)
            obs = IndividualCMF(L_OpsinTemplate="Serine", M_OpsinTemplate="Standard");
            params = obs.getParameters();
            testCase.verifyEqual(string(params.L_OpsinTemplate), "Serine");
            testCase.verifyEqual(string(params.M_OpsinTemplate), "Standard");
        end

        function testGetParametersCapturesAlgorithms(testCase)
            obs = IndividualCMF(StandardObserver=10);
            params = obs.getParameters();
            testCase.verifyEqual(string(params.MacularDensityAlgorithm), "CIE170");
            testCase.verifyEqual(string(params.PhotopigmentDensityAlgorithm), "CIE170");
            testCase.verifyEqual(string(params.LensDensityAlgorithm), "Auto");
        end

        function testGetParametersCapturesCustomLensMode(testCase)
            obs = IndividualCMF(LensDensity=2.5);
            params = obs.getParameters();
            testCase.verifyEqual(string(params.LensDensityAlgorithm), "Custom");
        end

        function testSetParametersAppliesPhotopigmentModel(testCase)
            obs = IndividualCMF();
            params = ObserverParameters(PhotopigmentModel="Govardovskii2000");
            obs.setParameters(params);
            testCase.verifyEqual(string(obs.PhotopigmentModel), "Govardovskii2000");
        end

        function testSetParametersAppliesLensModel(testCase)
            obs = IndividualCMF();
            params = ObserverParameters(LensModel="Pokorny1987");
            obs.setParameters(params);
            testCase.verifyEqual(string(obs.LensModel), "Pokorny1987");
        end

        function testSetParametersAppliesOpsinTemplates(testCase)
            obs = IndividualCMF();
            params = ObserverParameters(L_OpsinTemplate="Alanine", M_OpsinTemplate="LinM");
            obs.setParameters(params);
            testCase.verifyEqual(string(obs.L_OpsinTemplate), "Alanine");
            testCase.verifyEqual(string(obs.M_OpsinTemplate), "LinM");
        end

        function testFullRoundTripPreservesLMS(testCase)
            % The acid test: an observer constructed with non-default model
            % choices, then round-tripped through getParameters/setParameters,
            % must produce identical LMS output.
            obs1 = IndividualCMF( ...
                LensModel="Pokorny1987", ...
                PhotopigmentModel="Govardovskii2000", ...
                Age=70, ...
                FieldSize=4, ...
                L_OpsinTemplate="Serine");
            LMS1 = obs1.LMS(400:5:700);

            params = obs1.getParameters();
            obs2 = IndividualCMF();
            obs2.setParameters(params);
            LMS2 = obs2.LMS(400:5:700);

            testCase.verifyEqual(LMS2, LMS1, 'AbsTol', 1e-9, ...
                'Round-trip through ObserverParameters must preserve LMS exactly.');
        end

        function testRoundTripPreservesCustomLensDensity(testCase)
            % If source had Custom lens mode, round-trip must preserve both
            % the value and the mode.
            obs1 = IndividualCMF(Age=70, LensDensity=3.0);
            testCase.assertEqual(string(obs1.LensDensityAlgorithm), "Custom");

            params = obs1.getParameters();
            obs2 = IndividualCMF();
            obs2.setParameters(params);

            testCase.verifyEqual(string(obs2.LensDensityAlgorithm), "Custom");
            testCase.verifyEqual(obs2.LensDensity, 3.0, 'AbsTol', 1e-9);
        end

        function testRoundTripPreservesAutoLensMode(testCase)
            % If source had Auto lens mode, the receiver should also be in
            % Auto mode (not silently switched to Custom by the value
            % transfer, then re-derived).
            obs1 = IndividualCMF(LensModel="Pokorny1987", Age=70);
            testCase.assertEqual(string(obs1.LensDensityAlgorithm), "Auto");

            params = obs1.getParameters();
            obs2 = IndividualCMF();
            obs2.setParameters(params);

            testCase.verifyEqual(string(obs2.LensDensityAlgorithm), "Auto");
            testCase.verifyEqual(obs2.LensDensity, obs1.LensDensity, 'AbsTol', 1e-9);
        end

        function testRoundTripFromHybridGenotypeObserver(testCase)
            % Observer with a hybrid M-in-L L-cone has L_OpsinTemplate set.
            % Confirm the hybrid template round-trips.
            obs1 = IndividualCMF();
            obs1.applyGenotype("LIAFA/SIAVA");  % M-in-L hybrid
            testCase.assertEqual(string(obs1.L_OpsinTemplate), "MinL");

            params = obs1.getParameters();
            obs2 = IndividualCMF();
            obs2.setParameters(params);

            testCase.verifyEqual(string(obs2.L_OpsinTemplate), "MinL");
        end

        function testRoundTripDoesNotEmitWarnings(testCase)
            % Round-tripping a Custom-mode observer must not emit the
            % IndividualCMF:*CustomOverwritten warnings -- those are
            % intended for interactive mode changes, not parameter
            % transfers.
            obs1 = IndividualCMF(LensDensity=2.5, Lod=0.42);
            params = obs1.getParameters();

            % Suppress the *CustomOverwritten warnings (this test asserts
            % the round-trip stays warning-free; if the asserts ever fail
            % we want lastwarn() to surface it, not noisy console output).
            testCase.applyFixture( ...
                matlab.unittest.fixtures.SuppressedWarningsFixture({ ...
                    'IndividualCMF:LensCustomOverwritten', ...
                    'IndividualCMF:PhotopigmentCustomOverwritten', ...
                    'IndividualCMF:MacularCustomOverwritten'}));
            lastwarn('');

            obs2 = IndividualCMF();
            obs2.setParameters(params);

            [msg, ~] = lastwarn();
            testCase.verifyEmpty(msg, ...
                'setParameters round-trip must not emit warnings.');
        end
    end
end


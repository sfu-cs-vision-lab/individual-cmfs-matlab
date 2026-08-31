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
        % Exhaustive round-trip guard
        %
        % ARCHITECTURE.md claimed the round trip reproduces LMS
        % "bit-for-bit" while IndividualCMF's own comment warned
        % ObserverParameters was "not a live mirror". Sweeping every
        % settable public property settles it: 21 of 26 round-trip at
        % exactly 0, LensDensity is lossy at ~1e-12 by construction, and
        % five output-shape settings are deliberately not carried. These
        % three tests pin that contract so the claim is checked rather
        % than asserted.

        function testPhysiologyAndModelSelectionsRoundTripExactly(testCase)
            % Everything ObserverParameters is FOR: who the observer is.
            variants = { ...
                {'Age', 70}, {'FieldSize', 4}, ...
                {'LensModel', "Pokorny1987"}, {'LensModel', "VanDeKraats2007"}, ...
                {'PhotopigmentModel', "Govardovskii2000"}, ...
                {'PhotopigmentModel', "Govardovskii2000A2"}, ...
                {'PhotopigmentModel', "StockmanRider2023Common"}, ...
                {'L_OpsinTemplate', "Serine"}, {'L_OpsinTemplate', "Alanine"}, ...
                {'L_OpsinTemplate', "MinL"}, {'M_OpsinTemplate', "LinM"}, ...
                {'L_LambdaMaxShift', -5}, {'M_LambdaMaxShift', 7}, ...
                {'S_LambdaMaxShift', 3}, ...
                {'Lod', 0.42}, {'Mod', 0.31}, {'Sod', 0.22}, ...
                {'MacularDensity', 0.28}, ...
                {'MacularDensityAlgorithm', "MorelandAlexander"}, ...
                {'PhotopigmentDensityAlgorithm', "PokornySmith"}};

            % A non-zero shift on the default Mean L template warns on
            % every absorbance call, including inside fminbnd peak-finding.
            % The shift variants below exercise that deliberately.
            testCase.applyFixture( ...
                matlab.unittest.fixtures.SuppressedWarningsFixture( ...
                    'StockmanRiderPhotopigmentTemplate:ShiftOverride'));

            % Inside every active model's ValidRange, so this tests the
            % round trip rather than the range guards.
            wl = (400:5:700)';
            for k = 1:numel(variants)
                name = variants{k}{1};
                value = variants{k}{2};

                src = IndividualCMF();
                src.ModelRangeWarning = false;
                src.(name) = value;

                dst = IndividualCMF();
                dst.ModelRangeWarning = false;
                dst.setParameters(src.getParameters());

                testCase.verifyEqual(dst.(name), src.(name), ...
                    sprintf('%s did not survive the round trip', name));
                testCase.verifyEqual(dst.LMS(wl), src.LMS(wl), 'AbsTol', 0, ...
                    sprintf('LMS differs after round-tripping %s', name));
            end
        end

        function testLensDensityRoundTripsToScalingPrecision(testCase)
            % ObserverParameters stores lens density as a RATIO to
            % CIE170.STD_LENS_DENSITY_400, which is what lets
            % isStandardConfiguration test it against 1.0. getParameters
            % divides by that constant and setParameters multiplies back,
            % and x/c*c does not return x exactly in binary floating point.
            % The residual is ~1e-12 relative -- far below any measurement
            % precision, but it is why the round trip is not bit-for-bit.
            src = IndividualCMF();
            src.LensDensity = 1.9;

            dst = IndividualCMF();
            dst.setParameters(src.getParameters());

            testCase.verifyEqual(dst.LensDensity, src.LensDensity, 'RelTol', 1e-11, ...
                'Lens density must round-trip to scaling precision');
            testCase.verifyEqual(dst.LMS((400:5:700)'), src.LMS((400:5:700)'), ...
                'AbsTol', 1e-10, 'LMS must agree to well beyond measurement precision');

            % A standard observer's ratio is exactly 1.0, so that case is
            % lossless and isStandardConfiguration stays reliable.
            std10 = IndividualCMF(StandardObserver=10);
            round10 = IndividualCMF();
            round10.setParameters(std10.getParameters());
            testCase.verifyEqual(round10.LensDensity, std10.LensDensity, 'AbsTol', 0, ...
                'The standard observer ratio of 1.0 must round-trip exactly');
            testCase.verifyTrue(round10.getParameters().isStandardConfiguration());
        end

        function testOutputShapeSettingsAreDeliberatelyNotCarried(testCase)
            % ObserverParameters captures who the observer is, not how you
            % are currently viewing them. IndividualCMF.snapToStandardObserver
            % names the same group and preserves it across a physiology
            % reset, so the exclusion is one decision applied consistently
            % rather than an oversight. Transferring physiology from a
            % log-mode observer must not silently flip the receiver's
            % display mode.
            src = IndividualCMF();
            src.OutputFormat = "quantal";
            src.LogOutput = true;
            src.NormalizeOutput = false;
            src.Primaries = [640 530 450];
            src.NormalizationMethod = "Sampled";

            dst = IndividualCMF();
            defaults = struct( ...
                OutputFormat = dst.OutputFormat, ...
                LogOutput = dst.LogOutput, ...
                NormalizeOutput = dst.NormalizeOutput, ...
                Primaries = dst.Primaries, ...
                NormalizationMethod = dst.NormalizationMethod);

            dst.setParameters(src.getParameters());

            for name = string(fieldnames(defaults))'
                testCase.verifyEqual(dst.(name), defaults.(name), ...
                    sprintf('%s must not be carried by a parameter snapshot', name));
            end

            % The physiology did transfer, which is the point.
            testCase.verifyEqual(dst.Age, src.Age);
            testCase.verifyEqual(dst.Lod, src.Lod);
        end

        function testRoundTripPreservesTheDensityAlgorithmStates(testCase)
            % Custom is engaged by pinning a value, and a snapshot has to
            % carry that state or the restored observer silently reverts to
            % a formula on the next Age or FieldSize change.
            src = IndividualCMF();
            src.LensDensity = 1.9;
            src.MacularDensity = 0.28;
            src.Lod = 0.42;

            dst = IndividualCMF();
            dst.setParameters(src.getParameters());

            testCase.verifyEqual(string(dst.LensDensityAlgorithm), "Custom");
            testCase.verifyEqual(string(dst.MacularDensityAlgorithm), "Custom");
            testCase.verifyEqual(string(dst.PhotopigmentDensityAlgorithm), "Custom");

            % And the pin must actually hold in the restored observer.
            dst.Age = 45;
            testCase.verifyEqual(dst.LensDensity, 1.9, 'RelTol', 1e-11);
        end

        function testSnapshotAppliesRegardlessOfTheReceiverState(testCase)
            % setParameters assigned LensModel before Age, so the incoming
            % model was validated against the RECEIVER's age. A valid
            % Pokorny-at-50 snapshot failed to apply to a receiver sitting
            % at age 90, with AgeOutsideModelDomain, though both states
            % were legal on their own.
            testCase.applyFixture( ...
                matlab.unittest.fixtures.SuppressedWarningsFixture( ...
                    'IndividualCMF:AgeOutOfRange'));

            snapshot = IndividualCMF(LensModel="Pokorny1987", Age=50).getParameters();

            receiver = IndividualCMF(LensModel="VanDeKraats2007", Age=90);
            receiver.setParameters(snapshot);
            testCase.verifyEqual(receiver.Age, 50);
            testCase.verifyEqual(string(receiver.LensModel), "Pokorny1987");

            % And the reverse direction: a receiver too young for the
            % incoming model must not block a snapshot that is fine.
            receiver2 = IndividualCMF(LensModel="VanDeKraats2007", Age=5);
            receiver2.setParameters(snapshot);
            testCase.verifyEqual(receiver2.Age, 50);
            testCase.verifyEqual(receiver2.LensDensity, ...
                IndividualCMF(LensModel="Pokorny1987", Age=50).LensDensity, ...
                'RelTol', 1e-11);
        end

    end
end

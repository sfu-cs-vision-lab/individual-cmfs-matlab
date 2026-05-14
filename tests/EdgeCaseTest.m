classdef EdgeCaseTest < matlab.unittest.TestCase
    % EDGECASETEST  Unit tests for edge cases and boundary conditions.

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada
    %
    % This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    % Licensed under AGPL-3.0-or-later. See LICENSE file for details.
    % Repository: https://github.com/sfu-cs-vision-lab/Individual-CMFs
    %
    % If you use this code in your research, please cite:
    %   Forsythe, A. & Funt, B. (2025). Matlab Individual Cone Fundamentals Toolbox.
    %   https://github.com/sfu-cs-vision-lab/Individual-CMFs
    %
    % This implementation is based on:
    %   Stockman, A. & Rider, A.T. (2023). Formulae for generating standard and
    %   individual human cone spectral sensitivities. Color Research and
    %   Application, 48(6), 818-840. https://doi.org/10.1002/col.22879
    %
    %   Stockman, A. & Rider, A.T. (2023). Pycone: Individual-CMFs Python software.
    %   Colour and Vision Research Laboratory, Institute of Ophthalmology, UCL.
    %   https://github.com/CVRL-IoO/Individual-CMFs
    %
    %   Govardovskii, V.I., Fyhrquist, N., Reuter, T., Kuzmin, D.G. & Donner, K.
    %   (2000). In search of the visual pigment template. Visual Neuroscience,
    %   17(4), 509-528. https://doi.org/10.1017/S0952523800174036

    methods(Test)
        
        function testCustomPrimaries(testCase)
            % Verify that changing Primaries alters the RGB output
            wl = (400:10:700)';

            % 1. Default Primaries (Stiles & Burch)
            obs1 = IndividualCMF(StandardObserver=2);
            RGB1 = obs1.RGB(wl);

            % 2. Custom Primaries (e.g. Rec. 2020 or hypothetical)
            % Shift Red primary significantly (645 -> 600)
            customPrimaries = [600, 526.32, 444.44];
            obs2 = IndividualCMF(Age=32, FieldSize=2); % Manual config
            obs2.Primaries = customPrimaries;
            RGB2 = obs2.RGB(wl);

            % 3. Assertions
            % The CMFs should be different (now columns 1:3 since wl is separate)
            diff = max(abs(RGB1 - RGB2), [], 'all');
            testCase.verifyTrue(diff > 0.01, 'Changing primaries should alter RGB CMFs');
        end

        function testRepeatedPrimariesRejected(testCase)
            % Duplicate primary wavelengths make the LMS-at-primaries
            % matrix singular. Reject at the setter rather than letting
            % backslash silently produce NaN/Inf.
            obs = IndividualCMF();
            testCase.verifyError(@() setPrimaries(obs, [500 500 500]), ...
                'IndividualCMF:InvalidPrimaries');
            testCase.verifyError(@() setPrimaries(obs, [600 600 444]), ...
                'IndividualCMF:InvalidPrimaries');
        end

        function testNonPositivePrimariesRejected(testCase)
            % Wavelengths must be positive.
            obs = IndividualCMF();
            testCase.verifyError(@() setPrimaries(obs, [0 500 444]), ...
                'IndividualCMF:InvalidPrimaries');
            testCase.verifyError(@() setPrimaries(obs, [-1 500 444]), ...
                'IndividualCMF:InvalidPrimaries');
        end

        function testNonFinitePrimariesRejected(testCase)
            % Inf and NaN must be rejected.
            obs = IndividualCMF();
            testCase.verifyError(@() setPrimaries(obs, [Inf 500 444]), ...
                'IndividualCMF:InvalidPrimaries');
            testCase.verifyError(@() setPrimaries(obs, [NaN 500 444]), ...
                'IndividualCMF:InvalidPrimaries');
        end

        function testInfOpticalDensityRejected(testCase)
            % Inf passes mustBeNonnegative; needs mustBeFinite to be
            % rejected. Without this, Inf-OD propagates into self-screening
            % math (1 - 10^(-Inf*A)) and produces non-physical flat 1.0
            % everywhere absorbance is non-zero.
            obs = IndividualCMF();
            testCase.verifyError(@() setLod(obs, Inf), ...
                'MATLAB:validators:mustBeFinite');
            testCase.verifyError(@() setMod(obs, Inf), ...
                'MATLAB:validators:mustBeFinite');
            testCase.verifyError(@() setSod(obs, Inf), ...
                'MATLAB:validators:mustBeFinite');
            testCase.verifyError( ...
                @() PhotopigmentParameters(OpticalDensity=Inf), ...
                'MATLAB:validators:mustBeFinite');
        end

        function testNonFiniteAgeRejected(testCase)
            % Age must validate before any side effects so a bad value
            % doesn't half-mutate observer state (Age + lens filter were
            % updated separately).
            obs = IndividualCMF();
            testCase.verifyError(@() setAge(obs, NaN), ...
                'MATLAB:validators:mustBePositive');
            testCase.verifyError(@() setAge(obs, Inf), ...
                'MATLAB:validators:mustBeFinite');
            testCase.verifyError(@() setAge(obs, -5), ...
                'MATLAB:validators:mustBePositive');
        end

        function testInfMacularDensityRejected(testCase)
            % PreReceptoralFilter.Density only required mustBeNonnegative
            % previously, so Inf could be smuggled in via MacularDensity
            % setter or imported ObserverParameters.
            obs = IndividualCMF();
            testCase.verifyError(@() setMacularDensity(obs, Inf), ...
                'MATLAB:validators:mustBeFinite');
            testCase.verifyError( ...
                @() PreReceptoralFilter(Type="macular", Density=Inf), ...
                'MATLAB:validators:mustBeFinite');
        end

        function testConstructorRejectsInfAgeAndFieldSize(testCase)
            % validators.mustBePositiveOrNaN previously accepted Inf
            % (Inf > 0 is true). The constructor's NaN sentinel for
            % "value not provided" stays valid; Inf does not.
            testCase.verifyError(@() IndividualCMF(Age=Inf), ...
                'IndividualCMF:NotPositiveOrNan');
            testCase.verifyError(@() IndividualCMF(FieldSize=Inf), ...
                'IndividualCMF:NotPositiveOrNan');
        end

        function testPhotopigmentParametersRejectsNonFiniteShift(testCase)
            % Public L/M/S shift setters reject NaN/Inf, but a snapshot
            % round-trip via setParameters could previously smuggle a
            % non-finite shift through PhotopigmentParameters and into
            % computePeakForFormat's fminbnd bounds. Reject at the
            % value-object boundary too.
            testCase.verifyError( ...
                @() PhotopigmentParameters(LambdaMaxShift=Inf), ...
                'MATLAB:validators:mustBeFinite');
            testCase.verifyError( ...
                @() PhotopigmentParameters(LambdaMaxShift=NaN), ...
                'MATLAB:validators:mustBeFinite');
        end

        function testSampledConfigRejectsNonFiniteGrid(testCase)
            % validateSampledConfig used to do only relational checks,
            % which NaN and some Inf values pass. A NaN/Inf Start/Stop/
            % Step would then produce an invalid colon grid in
            % computeSampledPeak.
            obs = IndividualCMF();
            badStart = struct('Method', "Sampled", 'Start', NaN, 'Stop', 780, 'Step', 1);
            badStop  = struct('Method', "Sampled", 'Start', 380, 'Stop', Inf, 'Step', 1);
            badStep  = struct('Method', "Sampled", 'Start', 380, 'Stop', 780, 'Step', NaN);
            for cfg = {badStart, badStop, badStep}
                testCase.verifyError( ...
                    @() setNorm(obs, cfg{1}), ...
                    'IndividualCMF:InvalidNormalizationConfig');
            end
        end

        function testConstructorRejectsInfDensities(testCase)
            % Constructor options for Lod/Mod/Sod/MacularDensity/
            % LensDensity accept NaN as a sentinel ("value not provided")
            % but must reject Inf so the constructor matches the
            % now-stricter property setters and downstream value objects.
            testCase.verifyError(@() IndividualCMF(Lod=Inf), ...
                'IndividualCMF:NotNonnegativeFiniteOrNan');
            testCase.verifyError(@() IndividualCMF(Mod=Inf), ...
                'IndividualCMF:NotNonnegativeFiniteOrNan');
            testCase.verifyError(@() IndividualCMF(Sod=Inf), ...
                'IndividualCMF:NotNonnegativeFiniteOrNan');
            testCase.verifyError(@() IndividualCMF(MacularDensity=Inf), ...
                'IndividualCMF:NotNonnegativeFiniteOrNan');
            testCase.verifyError(@() IndividualCMF(LensDensity=Inf), ...
                'IndividualCMF:NotNonnegativeFiniteOrNan');
            % And negatives.
            testCase.verifyError(@() IndividualCMF(Lod=-0.1), ...
                'IndividualCMF:NotNonnegativeFiniteOrNan');
        end

        function testLargeSConeShiftFallsBackToValidRange(testCase)
            % A large but finite S shift can push the base [380, 500]
            % search window entirely off the template's valid range, so
            % naive endpoint-clamping produces lb >= ub and fminbnd
            % errors. Peak search must fall back to the full valid
            % range when the shifted window no longer overlaps it.
            obs = IndividualCMF();
            obs.S_LambdaMaxShift = 500;  % well beyond physiological
            obs.NormalizeOutput = true;
            % Should not throw, and S(wl) should be a finite Nx1 vector.
            wl = (380:1:780)';
            S = obs.S(wl);
            testCase.verifyTrue(all(isfinite(S)), ...
                'Large S shift must produce finite S(wl)');
            testCase.verifyEqual(numel(S), numel(wl));
        end

        function testObserverParametersRejectsNonFiniteAgeAndFieldSize(testCase)
            % setParameters bypasses the facade setters by writing the
            % value object's fields straight into p_Parameters. Match the
            % facade's finite validation at the value-object boundary so
            % a hand-built snapshot can't smuggle Inf in.
            testCase.verifyError(@() ObserverParameters(Age=Inf), ...
                'MATLAB:validators:mustBeFinite');
            testCase.verifyError(@() ObserverParameters(FieldSize=Inf), ...
                'MATLAB:validators:mustBeFinite');
            testCase.verifyError(@() ObserverParameters(Age=NaN), ...
                'MATLAB:validators:mustBePositive');
            testCase.verifyError(@() ObserverParameters(FieldSize=NaN), ...
                'MATLAB:validators:mustBePositive');
        end

        function testConstructorRejectsNonFiniteSConeShift(testCase)
            % Setter rejected NaN/Inf; the constructor option needed the
            % same guard for parity.
            testCase.verifyError(@() IndividualCMF(S_LambdaMaxShift=Inf), ...
                'MATLAB:validators:mustBeFinite');
            testCase.verifyError(@() IndividualCMF(S_LambdaMaxShift=NaN), ...
                'MATLAB:validators:mustBeFinite');
        end

        function testSetGenotypeRejectsInvalidPosition(testCase)
            % setGenotype previously accepted any double for position and
            % silently wrote a bogus key (e.g. "L_42") into GenotypeState
            % that no shift lookup would find. Now must reject anything
            % outside the documented set {116, 180, 230, 233, 277, 285, 309}.
            obs = IndividualCMF();
            testCase.verifyError(@() obs.setGenotype('L', 42, 'Ala'), ...
                'MATLAB:validators:mustBeMember');
            testCase.verifyError(@() obs.setGenotype('L', 180.5, 'Ala'), ...
                'MATLAB:validators:mustBeMember');
            % Valid positions still pass.
            testCase.verifyWarningFree(@() obs.setGenotype('L', 180, 'Ala'));
        end

        function testNonFiniteSConeShiftRejected(testCase)
            % S_LambdaMaxShift is otherwise unbounded (L/M are clamped to
            % a physiological window). Non-finite values still need to be
            % rejected: they would propagate into the fminbnd peak-search
            % bounds in computePeakForFormat and produce non-finite spectra.
            obs = IndividualCMF();
            testCase.verifyError(@() setSshift(obs, NaN), ...
                'MATLAB:validators:mustBeFinite');
            testCase.verifyError(@() setSshift(obs, Inf), ...
                'MATLAB:validators:mustBeFinite');
            % Sanity: large finite shifts still allowed.
            testCase.verifyWarningFree(@() setSshift(obs, 50), ...
                'Large finite S shifts must remain accepted');
        end

        function testNearSingularPrimariesRaiseClearError(testCase)
            % Three distinct but spectrally-close primaries deep in the
            % L-cone tail produce a near-singular LMS-at-primaries matrix
            % (rcond ~ 1e-8 vs ~0.1 for reasonable primaries). RGB() must
            % raise a clear domain error rather than emit a MATLAB
            % ill-conditioning warning and return junk.
            obs = IndividualCMF();
            obs.Primaries = [700 705 710];
            wl = (400:10:700)';
            testCase.verifyError(@() obs.RGB(wl), ...
                'IndividualCMF:SingularPrimaries');
        end

        function testZeroLensDensity(testCase)
            % Verify the model handles 0 Lens Density (Albino/Aphakic simulation)
            % With 0 density, sensitivity should be HIGHER (more light reaches retina)
            
            wl = 400; % Short wavelength where lens absorbs most
            
            obsStd = IndividualCMF(StandardObserver=2);
            obsClear = IndividualCMF(Age=32, FieldSize=2);
            obsClear.LensDensity = 0;
            
            % Calculate Quantal sensitivity (to ignore energy scaling)
            obsStd.OutputFormat = "quantal";
            obsClear.OutputFormat = "quantal";
            obsStd.NormalizeOutput = false;
            obsClear.NormalizeOutput = false;
            
            s_std = obsStd.S(wl);
            s_clear = obsClear.S(wl);
            
            % Sensitivity with no lens should be higher than with lens
            testCase.verifyTrue(s_clear > s_std, ...
                'Zero lens density should result in higher short-wavelength sensitivity');
        end
        
        function testInputDimensions(testCase)
            % Verify that LMS() returns correct shape regardless of input vector orientation
            obs = IndividualCMF(StandardObserver=2);

            % 1. Column Vector Input (Standard)
            wl_col = (400:10:700)';
            out_col = obs.LMS(wl_col);
            testCase.verifySize(out_col, [length(wl_col), 3], 'Column input should return Nx3 matrix');

            % 2. Row Vector Input (Robustness check)
            wl_row = (400:10:700);
            out_row = obs.LMS(wl_row);

            % It currently returns Nx3 regardless (due to internal wl(:))
            % If your code doesn't force wl(:), this test confirms current behavior
            testCase.verifySize(out_row, [length(wl_row), 3], 'Row input should return Nx3 matrix');

            % Values should be identical
            testCase.verifyEqual(out_col, out_row, 'Output values should be identical regardless of input shape');
        end

        function testWavelengthBoundaries(testCase)
            % Test standard range boundaries
            obs = IndividualCMF(StandardObserver=2);

            % Should handle boundary wavelengths without warning
            testCase.verifyWarningFree(@() obs.L(380));
            testCase.verifyWarningFree(@() obs.L(780));

            % Single wavelength should return scalar
            result = obs.L(550);
            testCase.verifySize(result, [1, 1]);
            testCase.verifyGreaterThan(result, 0);
        end

        function testExtremeAgeValues(testCase)
            % Test age boundary conditions
            % Use Pokorny1987 lens model for age-dependent comparisons

            % Young observer
            obs_young = IndividualCMF(Age=1, FieldSize=2, LensModel="Pokorny1987");
            testCase.verifyWarningFree(@() obs_young.L(550));

            % Elderly observer
            obs_old = IndividualCMF(Age=100, FieldSize=2, LensModel="Pokorny1987");
            testCase.verifyWarningFree(@() obs_old.L(550));

            % Older should have more lens absorption at short wavelengths
            % due to increased lens optical density (yellowing) with Pokorny1987 model
            testCase.verifyLessThan(obs_old.S(420), obs_young.S(420), ...
                'Older observer should have reduced short-wavelength sensitivity with Pokorny1987');
        end

        function testExtremeFieldSizes(testCase)
            % Test field size boundary conditions
            obs_small = IndividualCMF(Age=32, FieldSize=1);
            obs_large = IndividualCMF(Age=32, FieldSize=10);

            testCase.verifyWarningFree(@() obs_small.L(550));
            testCase.verifyWarningFree(@() obs_large.L(550));

            % Different field sizes should give different macular density
            testCase.verifyNotEqual(obs_small.MacularDensity, obs_large.MacularDensity, ...
                'Different field sizes should have different macular pigment density');
        end

        function testEmptyWavelengthInput(testCase)
            % Empty input should return empty output
            obs = IndividualCMF(StandardObserver=2);
            result = obs.L([]);
            testCase.verifyEmpty(result);
        end

        function testLargeWavelengthArray(testCase)
            % Test with large input array
            obs = IndividualCMF(StandardObserver=2);
            wl = linspace(380, 780, 10000)';

            testCase.verifyWarningFree(@() obs.evaluate(wl));
            result = obs.evaluate(wl);
            testCase.verifySize(result, [10000, 3]);
        end

    end
end

function setPrimaries(obs, p)
    obs.Primaries = p;
end

function setLod(obs, v)
    obs.Lod = v;
end

function setMod(obs, v)
    obs.Mod = v;
end

function setSod(obs, v)
    obs.Sod = v;
end

function setSshift(obs, v)
    obs.S_LambdaMaxShift = v;
end

function setAge(obs, v)
    obs.Age = v;
end

function setMacularDensity(obs, v)
    obs.MacularDensity = v;
end

function setNorm(obs, cfg)
    obs.NormalizationMethod = cfg;
end
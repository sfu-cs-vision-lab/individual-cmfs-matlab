classdef ApplyGenotypeTest < matlab.unittest.TestCase
    % APPLYGENOTYPETEST  Tests for IndividualCMF.applyGenotype() and the
    %   Genotype/IndividualCMF boundary (struct, dictionary, slash-form,
    %   dichromacy paths, restore-from-absent, hybrid templates).

    % SPDX-License-Identifier: AGPL-3.0-or-later
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt

    properties (Constant)
        RelTol = 1e-6
        AbsTol = 1e-10
    end

    methods (TestMethodSetup)
        function suppressExpectedWarnings(testCase)
            % Suppress ShiftOverride warning (expected when using Mean template
            % with non-zero shift). The fixture restores state cleanly.
            testCase.applyFixture( ...
                matlab.unittest.fixtures.SuppressedWarningsFixture( ...
                    'StockmanRiderPhotopigmentTemplate:ShiftOverride'));
        end
    end

    methods (Test)

        function testApplyGenotypeBasicTrichromat(testCase)
            % Test applyGenotype with a basic trichromat genotype.
            % Use genotypes that produce non-zero shifts for both cones:
            % L: LIAVA has Ala at 285 which gives -14.0 * scale shift
            % M: SSAFA has Ser at 180 which gives 3.0 * scale shift
            obs = IndividualCMF();
            obs.applyGenotype("LIAVA/SSAFA");

            testCase.verifyNotEqual(obs.L_LambdaMaxShift, 0, ...
                'L-cone shift should be computed from genotype');
            testCase.verifyNotEqual(obs.M_LambdaMaxShift, 0, ...
                'M-cone shift should be computed from genotype');
        end

        function testApplyGenotypePreservesAgeByDefault(testCase)
            obs = IndividualCMF();
            obs.Age = 55;
            obs.applyGenotype("LIAVA/SIAVA");

            testCase.verifyEqual(obs.Age, 55, ...
                'applyGenotype should preserve Age by default');
        end

        function testApplyGenotypePreservesFieldSizeByDefault(testCase)
            obs = IndividualCMF(StandardObserver=2);
            obs.applyGenotype("LIAVA/SIAVA");

            testCase.verifyEqual(obs.FieldSize, 2, ...
                'applyGenotype should preserve FieldSize by default');
        end

        function testApplyGenotypeResetsAgeWhenRequested(testCase)
            obs = IndividualCMF();
            obs.Age = 55;
            obs.applyGenotype("LIAVA/SIAVA", PreserveAge=false);

            testCase.verifyEqual(obs.Age, CIE170.STD_AGE, ...
                'applyGenotype should reset Age to STD_AGE when PreserveAge=false');
        end

        function testApplyGenotypeResetsFieldSizeWhenRequested(testCase)
            obs = IndividualCMF(StandardObserver=2);
            obs.applyGenotype("LIAVA/SIAVA", PreserveFieldSize=false);

            testCase.verifyEqual(obs.FieldSize, CIE170.STD_FIELD_SIZE_10DEG, ...
                'applyGenotype should reset FieldSize to STD_FIELD_SIZE_10DEG when PreserveFieldSize=false');
        end

        function testApplyGenotypeDeuteranope(testCase)
            % Test applyGenotype with a deuteranope genotype (L-cone only).
            % An empty M genotype must zero the M-cone optical density so
            % the observer is genuinely dichromatic, not a trichromat with
            % an unshifted M cone.
            obs = IndividualCMF();
            obs.applyGenotype("LIAVA");

            testCase.verifyNotEqual(obs.L_LambdaMaxShift, 0, ...
                'L-cone shift should be computed for deuteranope');
            testCase.verifyEqual(obs.M_LambdaMaxShift, 0, ...
                'M-cone shift should be 0 for deuteranope');
            testCase.verifyEqual(obs.Mod, 0, ...
                'M-cone optical density must be 0 for deuteranope');
            LMS = obs.LMS((400:50:700)');
            testCase.verifyEqual(LMS(:,2), zeros(size(LMS,1),1), ...
                'M column of LMS must be identically zero for deuteranope');
        end

        function testApplyGenotypeProtanope(testCase)
            % Test applyGenotype with a protanope genotype (M-cone only).
            % An empty L genotype must zero the L-cone optical density.
            % SSAFA has Ser at 180 which gives 3.0 * scale shift.
            obs = IndividualCMF();
            obs.applyGenotype("/SSAFA");

            testCase.verifyEqual(obs.L_LambdaMaxShift, 0, ...
                'L-cone shift should be 0 for protanope');
            testCase.verifyNotEqual(obs.M_LambdaMaxShift, 0, ...
                'M-cone shift should be computed for protanope');
            testCase.verifyEqual(obs.Lod, 0, ...
                'L-cone optical density must be 0 for protanope');
            LMS = obs.LMS((400:50:700)');
            testCase.verifyEqual(LMS(:,1), zeros(size(LMS,1),1), ...
                'L column of LMS must be identically zero for protanope');
        end

        function testApplyGenotypeTrichromatPreservesBothCones(testCase)
            % Regression guard: a normal "L/M" genotype must NOT zero
            % either cone's optical density. Catches over-eager dichromacy
            % logic that might trigger on a present-but-empty branch.
            obs = IndividualCMF();
            obs.applyGenotype("LIAVA/SIAVA");

            testCase.verifyGreaterThan(obs.Lod, 0, ...
                'Trichromat genotype must keep Lod > 0');
            testCase.verifyGreaterThan(obs.Mod, 0, ...
                'Trichromat genotype must keep Mod > 0');
        end

        function testApplyGenotypeProtanopeSlashOnlyForm(testCase)
            % "/SIAVA" and "" + setting Lod=0 should be equivalent for L-cone presence.
            obs = IndividualCMF();
            obs.applyGenotype("/SIAVA");
            testCase.verifyEqual(obs.Lod, 0, ...
                'Slash-prefix genotype must zero Lod');
        end

        function testGenotypeToObserverParametersZerosAbsentCone(testCase)
            % Genotype.toObserverParameters() must apply the same dichromacy
            % semantics as applyGenotype.
            obsDeut = Genotype("LIAVA").toObserverParameters();
            testCase.verifyEqual(obsDeut.Mod, 0, ...
                'toObserverParameters: deuteranope must have Mod=0');

            obsProt = Genotype("/SIAVA").toObserverParameters();
            testCase.verifyEqual(obsProt.Lod, 0, ...
                'toObserverParameters: protanope must have Lod=0');
        end

        function testStructGenotypeDoesNotZeroAbsentCone(testCase)
            % The struct/dictionary genotype path is partial-override
            % semantics, NOT dichromacy. A struct without an M_* key
            % means "M is unchanged from the default" -- not "M cone is
            % absent". Catches regressions if the consolidation
            % accidentally routes the struct path through the same
            % dichromacy logic as the 5-letter string path.
            obs = IndividualCMF(Genotype=struct('L_180','Ala'));
            testCase.verifyGreaterThan(obs.Mod, 0, ...
                'struct Genotype= must not zero Mod (partial override)');
            testCase.verifyGreaterThan(obs.Lod, 0, ...
                'struct Genotype= must not zero Lod');
            % The L cone gets a shift; M and S do not.
            testCase.verifyNotEqual(obs.L_LambdaMaxShift, 0, ...
                'struct Genotype= L_180_Ala must shift L lambda-max');
            testCase.verifyEqual(obs.M_LambdaMaxShift, 0, ...
                'struct Genotype= without M entry must leave M shift 0');
        end

        function testSetGenotypeAgreesWithFromGenotypeSinglePosition(testCase)
            % obj.setGenotype('L', 180, 'Ala') is the per-position
            % version of the partial-override API. For a single position
            % it should produce the same L shift as
            % ObserverParameters.fromGenotype("L_180_Ala"). Catches drift
            % in either path's use of the GENOTYPE_SHIFTS dictionary or
            % the L/M scaling constants.
            singlePositions = struct( ...
                'L_180_Ala', {'L', 180, 'Ala'}, ...
                'L_277_Phe', {'L', 277, 'Phe'}, ...
                'L_285_Ala', {'L', 285, 'Ala'}, ...
                'M_180_Ser', {'M', 180, 'Ser'}, ...
                'M_285_Thr', {'M', 285, 'Thr'});
            names = fieldnames(singlePositions);
            for k = 1:numel(names)
                spec = strsplit(names{k}, '_');
                cone = spec{1};
                position = str2double(spec{2});
                aminoAcid = spec{3};

                obs = IndividualCMF();
                obs.setGenotype(cone, position, aminoAcid);

                params = ObserverParameters.fromGenotype(string(names{k}));

                msg = sprintf('setGenotype(%s, %d, %s)', cone, position, aminoAcid);
                switch cone
                    case 'L'
                        testCase.verifyEqual(obs.L_LambdaMaxShift, ...
                            params.LCone.LambdaMaxShift, 'AbsTol', 1e-12, ...
                            [msg ' L shift must match fromGenotype']);
                    case 'M'
                        testCase.verifyEqual(obs.M_LambdaMaxShift, ...
                            params.MCone.LambdaMaxShift, 'AbsTol', 1e-12, ...
                            [msg ' M shift must match fromGenotype']);
                end
            end
        end

        function testGenotypeCrossAPIParity(testCase)
            % All three string-genotype entry points -- the constructor's
            % Genotype= argument, applyGenotype, and
            % Genotype.toObserverParameters -- must produce identical
            % observer state (optical densities, templates, shifts).
            % Catches the class of bugs where one path zeros an absent
            % cone but the others don't, or where applyGenotype and the
            % constructor disagree on template selection.
            cases = ["LIAVA/SIAVA";   % synthetic trichromat fixture (legacy)
                     "LSAYA/SIAVA";   % L with single Ala variant
                     "LIAFT/SIAVA";   % unusual L 277/285 pair (F+T)
                     "LSAFA/SIAVA";   % M-in-L hybrid
                     "LIAVA";         % deuteranope (M absent)
                     "/SIAVA";        % protanope (L absent)
                     "LIAVA/"];       % deuteranope, slash form
            for k = 1:numel(cases)
                gstr = cases(k);
                a = IndividualCMF();
                a.applyGenotype(gstr);
                b = IndividualCMF(Genotype=gstr);
                c = Genotype(gstr).toObserverParameters();
                msg = sprintf('Genotype "%s": ', gstr);
                testCase.verifyEqual(b.Lod, a.Lod, 'AbsTol', 1e-12, ...
                    [char(msg) 'Lod (ctor vs apply)']);
                testCase.verifyEqual(c.Lod, a.Lod, 'AbsTol', 1e-12, ...
                    [char(msg) 'Lod (toObs vs apply)']);
                testCase.verifyEqual(b.Mod, a.Mod, 'AbsTol', 1e-12, ...
                    [char(msg) 'Mod (ctor vs apply)']);
                testCase.verifyEqual(c.Mod, a.Mod, 'AbsTol', 1e-12, ...
                    [char(msg) 'Mod (toObs vs apply)']);
                testCase.verifyEqual(string(b.L_OpsinTemplate), string(a.L_OpsinTemplate), ...
                    [char(msg) 'L_OpsinTemplate (ctor vs apply)']);
                testCase.verifyEqual(string(c.L_OpsinTemplate), string(a.L_OpsinTemplate), ...
                    [char(msg) 'L_OpsinTemplate (toObs vs apply)']);
                testCase.verifyEqual(string(b.M_OpsinTemplate), string(a.M_OpsinTemplate), ...
                    [char(msg) 'M_OpsinTemplate (ctor vs apply)']);
                testCase.verifyEqual(string(c.M_OpsinTemplate), string(a.M_OpsinTemplate), ...
                    [char(msg) 'M_OpsinTemplate (toObs vs apply)']);
                testCase.verifyEqual(b.L_LambdaMaxShift, a.L_LambdaMaxShift, ...
                    'AbsTol', 1e-12, [char(msg) 'L_LambdaMaxShift (ctor vs apply)']);
                testCase.verifyEqual(c.L_LambdaMaxShift, a.L_LambdaMaxShift, ...
                    'AbsTol', 1e-12, [char(msg) 'L_LambdaMaxShift (toObs vs apply)']);
                testCase.verifyEqual(b.M_LambdaMaxShift, a.M_LambdaMaxShift, ...
                    'AbsTol', 1e-12, [char(msg) 'M_LambdaMaxShift (ctor vs apply)']);
                testCase.verifyEqual(c.M_LambdaMaxShift, a.M_LambdaMaxShift, ...
                    'AbsTol', 1e-12, [char(msg) 'M_LambdaMaxShift (toObs vs apply)']);
                % LMS output parity (the user-visible contract)
                wl = (400:50:700)';
                testCase.verifyEqual(b.LMS(wl), a.LMS(wl), 'AbsTol', 1e-10, ...
                    [char(msg) 'LMS output (ctor vs apply)']);
                testCase.verifyEqual(c.LMS(wl), a.LMS(wl), 'AbsTol', 1e-10, ...
                    [char(msg) 'LMS output (toObs vs apply)']);
            end
        end

        function testApplyGenotypeRestoresAbsentCone(testCase)
            % Applying a trichromat genotype after a dichromat one
            % must restore the previously zeroed cone, not leave the
            % observer permanently dichromatic.
            obs = IndividualCMF();
            obs.applyGenotype("LIAVA");                  % deuteranope
            testCase.assertEqual(obs.Mod, 0, ...
                'Setup: deuteranope must have Mod=0');
            obs.applyGenotype("LIAVA/SIAVA");            % trichromat
            testCase.verifyGreaterThan(obs.Mod, 0, ...
                'Applying trichromat genotype must restore Mod');
            obs.applyGenotype("/SIAVA");                 % protanope
            testCase.assertEqual(obs.Lod, 0, ...
                'Setup: protanope must have Lod=0');
            obs.applyGenotype("LIAVA/SIAVA");            % trichromat again
            testCase.verifyGreaterThan(obs.Lod, 0, ...
                'Applying trichromat genotype must restore Lod');
        end

        function testApplyGenotypeRestoreUsesFieldSizeAppropriateOD(testCase)
            % Restoring a previously zeroed cone must use the field-size-
            % appropriate optical density, not the 10-deg constant. A
            % 2-deg observer's standard Mod is 0.5, not 0.38; restoring
            % to 0.38 would silently change the user-visible LMS output
            % across a dichromat -> trichromat round trip.
            obs = IndividualCMF(StandardObserver=2);
            initialMod = obs.Mod;
            testCase.assertEqual(initialMod, 0.5, 'AbsTol', 1e-12, ...
                'Setup: 2-deg standard Mod must be 0.5');
            obs.applyGenotype("LIAVA");          % deuteranope: Mod=0
            obs.applyGenotype("LIAVA/SIAVA");    % trichromat: Mod restored
            testCase.verifyEqual(obs.Mod, initialMod, 'AbsTol', 1e-12, ...
                'Restored Mod must equal field-size-appropriate value');
        end

        function testAbsentConeClearsStaleState(testCase)
            % When a one-sided genotype zeros a cone, the cone's shift,
            % template, and GenotypeState entries must also be cleared
            % so a snapshot of the observer matches the parsed Genotype
            % (whose absent side has empty genotype and zero shift).
            obs = IndividualCMF();
            obs.applyGenotype("LSAYA/SIAVA");
            testCase.assertNotEqual(obs.L_LambdaMaxShift, 0, ...
                'Setup: L shift must be non-zero before protanope');

            obs.applyGenotype("/SIAVA");  % L absent
            testCase.verifyEqual(obs.Lod, 0, ...
                'Absent L: Lod must be 0');
            testCase.verifyEqual(obs.L_LambdaMaxShift, 0, ...
                'Absent L: shift must be cleared (not stale)');
            testCase.verifyEqual(string(obs.L_OpsinTemplate), "Mean", ...
                'Absent L: template must reset to default');

            % Same for M
            obs2 = IndividualCMF();
            obs2.applyGenotype("LSAYA/SIAVT");
            testCase.assertNotEqual(obs2.M_LambdaMaxShift, 0, ...
                'Setup: M shift must be non-zero before deuteranope');
            obs2.applyGenotype("LIAVA");  % M absent
            testCase.verifyEqual(obs2.Mod, 0, ...
                'Absent M: Mod must be 0');
            testCase.verifyEqual(obs2.M_LambdaMaxShift, 0, ...
                'Absent M: shift must be cleared (not stale)');
            testCase.verifyEqual(string(obs2.M_OpsinTemplate), "Mean", ...
                'Absent M: template must reset to default');
        end

        function testFieldSizeValidationDoesNotMutateState(testCase)
            % A bad FieldSize value must throw cleanly without first
            % mutating PhotopigmentDensityAlgorithm or
            % MacularDensityAlgorithm from CIE170 to the formula variants.
            obs = IndividualCMF(StandardObserver=10);
            testCase.assertEqual(string(obs.PhotopigmentDensityAlgorithm), "CIE170");
            testCase.assertEqual(string(obs.MacularDensityAlgorithm), "CIE170");

            testCase.verifyError(@() setFieldSize(obs, -1), ...
                'MATLAB:validators:mustBePositive');
            testCase.verifyEqual(string(obs.PhotopigmentDensityAlgorithm), "CIE170", ...
                'Bad FieldSize must not mutate PhotopigmentDensityAlgorithm');
            testCase.verifyEqual(string(obs.MacularDensityAlgorithm), "CIE170", ...
                'Bad FieldSize must not mutate MacularDensityAlgorithm');

            testCase.verifyError(@() setFieldSize(obs, NaN), ...
                'MATLAB:validators:mustBePositive');
            testCase.verifyError(@() setFieldSize(obs, Inf), ...
                'MATLAB:validators:mustBeFinite');
        end


        function testApplyGenotypeSetsMinLHybridTemplate(testCase)
            obs = IndividualCMF();
            obs.applyGenotype("LIAFA/SIAVA");

            testCase.verifyEqual(string(obs.L_OpsinTemplate), "MinL", ...
                'L template should be M-in-L for Phe at 277 and Ala at 285');
        end

        function testApplyGenotypeSetsLinMHybridTemplate(testCase)
            % L-in-M hybrid requires Tyr (Y) at position 277 and Thr (T) at position 285.
            obs = IndividualCMF();
            obs.applyGenotype("LIAVA/SIAYT");

            testCase.verifyEqual(string(obs.M_OpsinTemplate), "LinM", ...
                'M template should be L-in-M for Tyr at 277 and Thr at 285');
        end

        function testApplyGenotypeConsistentWithGenotype(testCase)
            g = Genotype("LIAVA/SIAVA");
            obs = IndividualCMF();
            obs.applyGenotype("LIAVA/SIAVA");

            testCase.verifyEqual(obs.L_LambdaMaxShift, g.LShift, ...
                'RelTol', testCase.RelTol, ...
                'L-shift should match Genotype class');
            testCase.verifyEqual(obs.M_LambdaMaxShift, g.MShift, ...
                'RelTol', testCase.RelTol, ...
                'M-shift should match Genotype class');
        end

    end
end

function setFieldSize(obs, v)
    obs.FieldSize = v;
end

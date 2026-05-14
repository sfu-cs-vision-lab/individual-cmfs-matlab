classdef GenotypeTest < matlab.unittest.TestCase
    % GENOTYPETEST  Unit tests for Genotype class.
    %
    %   Tests cover:
    %   - Parsing standard genotype strings
    %   - Computing L and M shifts correctly
    %   - Identifying trichromats
    %   - Identifying deuteranopes and protanopes
    %   - toObserverParameters conversion
    %   - Error handling for invalid genotype strings
    %   - Hybrid cone detection

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada
    %
    % This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    % Licensed under AGPL-3.0-or-later. See LICENSE file for details.
    % Repository: https://github.com/sfu-cs-vision-lab/Individual-CMFs

    properties (Constant)
        % Tolerance for floating point comparisons
        AbsTol = 1e-10

        % Scaling constants from Stockman & Rider (2023)
        LSER_MLMAX_DIFF = 23.67
        M_BASES_SUM = 27
        L_BASES_SUM = 31
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

        function testParseStandardTrichromatGenotype(testCase)
            % Test parsing a trichromat genotype string (LIAVA/SIAVA is a synthetic legacy fixture)
            g = Genotype("LIAVA/SIAVA");

            testCase.verifyEqual(g.LGenotype, 'LIAVA', ...
                'L-cone genotype should be parsed correctly');
            testCase.verifyEqual(g.MGenotype, 'SIAVA', ...
                'M-cone genotype should be parsed correctly');
        end

        function testParseGenotypeWithSpaces(testCase)
            g = Genotype(" LIAVA / SIAVA ");

            testCase.verifyEqual(g.LGenotype, 'LIAVA', ...
                'L-cone genotype should be trimmed');
            testCase.verifyEqual(g.MGenotype, 'SIAVA', ...
                'M-cone genotype should be trimmed');
        end

        function testParseDeuteranopeGenotype(testCase)
            % Test parsing deuteranope genotype (L-cone only, no slash)
            g = Genotype("LIAVA");

            testCase.verifyEqual(g.LGenotype, 'LIAVA', ...
                'L-cone genotype should be present');
            testCase.verifyEmpty(g.MGenotype, ...
                'M-cone genotype should be empty for deuteranope');
        end

        function testParseDeuteranopeGenotypeWithSlash(testCase)
            % Test parsing deuteranope genotype (L-cone only, with slash)
            g = Genotype("LIAVA/");

            testCase.verifyEqual(g.LGenotype, 'LIAVA', ...
                'L-cone genotype should be present');
            testCase.verifyEmpty(g.MGenotype, ...
                'M-cone genotype should be empty');
        end

        function testParseProtanopeGenotype(testCase)
            % Test parsing protanope genotype (M-cone only)
            g = Genotype("/SIAVA");

            testCase.verifyEmpty(g.LGenotype, ...
                'L-cone genotype should be empty for protanope');
            testCase.verifyEqual(g.MGenotype, 'SIAVA', ...
                'M-cone genotype should be present');
        end

        function testColorVisionTypeTrichromat(testCase)
            g = Genotype("LIAVA/SIAVA");

            testCase.verifyEqual(g.ColorVisionType, "trichromat", ...
                'Should be classified as trichromat');
        end

        function testColorVisionTypeDeuteranope(testCase)
            g = Genotype("LIAVA");

            testCase.verifyEqual(g.ColorVisionType, "deuteranope", ...
                'L-cone only should be classified as deuteranope');
        end

        function testColorVisionTypeProtanope(testCase)
            g = Genotype("/SIAVA");

            testCase.verifyEqual(g.ColorVisionType, "protanope", ...
                'M-cone only should be classified as protanope');
        end

        function testLShiftForSer180(testCase)
            % Test L-cone shift with Serine at position 180 (baseline).
            % We use baseline amino acids at all other positions:
            % L-baseline: LSAYT (Leu116, Ser180, Ala230, Tyr277, Thr285)
            g = Genotype("LSAYT/SAAFA");

            expectedLShift = 0;
            testCase.verifyEqual(g.LShift, expectedLShift, 'AbsTol', testCase.AbsTol, ...
                'L-cone with Ser180 should have zero shift at position 180');
        end

        function testLShiftForAla180(testCase)
            % Test L-cone shift with Alanine at position 180.
            % We use baseline amino acids at all other positions so only
            % position 180 contributes to the shift.
            g = Genotype("LAAYT/SAAFA");

            Lscale = testCase.LSER_MLMAX_DIFF / testCase.L_BASES_SUM;
            expectedLShift = -4.0 * Lscale;

            testCase.verifyEqual(g.LShift, expectedLShift, 'AbsTol', testCase.AbsTol, ...
                'L-cone with Ala180 should have correct shift');
        end

        function testMShiftForSer180(testCase)
            % Test M-cone shift with Serine at position 180.
            % We use baseline amino acids at all other positions so only
            % position 180 contributes to the shift.
            g = Genotype("LSAYT/SSAFA");

            Mscale = testCase.LSER_MLMAX_DIFF / testCase.M_BASES_SUM;
            expectedMShift = 3.0 * Mscale;

            testCase.verifyEqual(g.MShift, expectedMShift, 'AbsTol', testCase.AbsTol, ...
                'M-cone with Ser180 should have correct shift');
        end

        function testMShiftForAla180(testCase)
            % Test M-cone shift with Alanine at position 180 (baseline).
            % We use baseline amino acids at all positions.
            g = Genotype("LSAYT/SAAFA");

            testCase.verifyEqual(g.MShift, 0, 'AbsTol', testCase.AbsTol, ...
                'M-cone with Ala180 should have zero shift at position 180');
        end

        function testCumulativeShifts(testCase)
            % The genotype uses amino acids that produce known shifts from
            % the GENOTYPE_SHIFTS dictionary at each position:
            % L-cone (YSTFA): Tyr116(-3), Ser180(0), Thr230(-3), Phe277(-7), Ala285(-14)
            % M-cone (SAAYT): Ser116(0), Ala180(0), Ala230(0), Tyr277(+7), Thr285(+14)
            g = Genotype("YSTFA/SAAYT");

            Lscale = testCase.LSER_MLMAX_DIFF / testCase.L_BASES_SUM;

            expectedLShift = (-3.0 + 0.0 + (-3.0) + (-7.0) + (-14.0)) * Lscale;

            testCase.verifyEqual(g.LShift, expectedLShift, 'AbsTol', testCase.AbsTol, ...
                'L-cone shifts should accumulate across all positions');

            Mscale = testCase.LSER_MLMAX_DIFF / testCase.M_BASES_SUM;

            expectedMShift = (0.0 + 0.0 + 0.0 + 7.0 + 14.0) * Mscale;

            testCase.verifyEqual(g.MShift, expectedMShift, 'AbsTol', testCase.AbsTol, ...
                'M-cone shifts should accumulate across all positions');
        end

        function testVerifyAgainstIndividualCMF(testCase)
            % Verify shifts match IndividualCMF.setGenotype calculations.
            % Use baseline amino acids at all positions except 180 for Ser.
            obs = IndividualCMF(Age=32, FieldSize=2);
            obs.setGenotype('M', 180, 'Ser');

            g = Genotype("LSAYT/SSAFA");

            testCase.verifyEqual(g.MShift, obs.M_LambdaMaxShift, 'AbsTol', testCase.AbsTol, ...
                'M-cone shift should match IndividualCMF setGenotype');
        end

        function testVerifyLShiftAgainstIndividualCMF(testCase)
            % Verify L-cone shifts match IndividualCMF.setGenotype calculations.
            % Use baseline amino acids at all positions except 180 for Ala.
            obs = IndividualCMF(Age=32, FieldSize=2);
            obs.setGenotype('L', 180, 'Ala');

            g = Genotype("LAAYT/SAAFA");

            testCase.verifyEqual(g.LShift, obs.L_LambdaMaxShift, 'AbsTol', testCase.AbsTol, ...
                'L-cone shift should match IndividualCMF setGenotype');
        end

        function testToObserverParametersDefault(testCase)
            % Test toObserverParameters with default Age and FieldSize
            g = Genotype("LAAVA/SSAVA");
            obs = g.toObserverParameters();

            testCase.verifyEqual(obs.Age, 32, ...
                'Default Age should be 32');
            testCase.verifyEqual(obs.FieldSize, 10, ...
                'Default FieldSize should be 10');
            testCase.verifyEqual(obs.L_LambdaMaxShift, g.LShift, 'AbsTol', testCase.AbsTol, ...
                'L-cone shift should be applied');
            testCase.verifyEqual(obs.M_LambdaMaxShift, g.MShift, 'AbsTol', testCase.AbsTol, ...
                'M-cone shift should be applied');
        end

        function testToObserverParametersCustomAge(testCase)
            % Test toObserverParameters with custom Age
            g = Genotype("LAAVA/SSAVA");
            obs = g.toObserverParameters(Age=45);

            testCase.verifyEqual(obs.Age, 45, ...
                'Age should be set to custom value');
            testCase.verifyEqual(obs.FieldSize, 10, ...
                'FieldSize should remain at default');
        end

        function testToObserverParametersCustomFieldSize(testCase)
            % Test toObserverParameters with custom FieldSize
            g = Genotype("LAAVA/SSAVA");
            obs = g.toObserverParameters(FieldSize=2);

            testCase.verifyEqual(obs.Age, 32, ...
                'Age should remain at default');
            testCase.verifyEqual(obs.FieldSize, 2, ...
                'FieldSize should be set to custom value');
        end

        function testToObserverParametersBothCustom(testCase)
            % Test toObserverParameters with both custom Age and FieldSize
            g = Genotype("LAAVA/SSAVA");
            obs = g.toObserverParameters(Age=55, FieldSize=4);

            testCase.verifyEqual(obs.Age, 55, ...
                'Age should be set to custom value');
            testCase.verifyEqual(obs.FieldSize, 4, ...
                'FieldSize should be set to custom value');
        end

        function testInvalidGenotypeLength(testCase)
            testCase.verifyError(@() Genotype("LIA/SIAVA"), ...
                'Genotype:InvalidFormat');
            testCase.verifyError(@() Genotype("LIAVAA/SIAVA"), ...
                'Genotype:InvalidFormat');
        end

        function testInvalidMGenotypeLength(testCase)
            testCase.verifyError(@() Genotype("LIAVA/SIA"), ...
                'Genotype:InvalidFormat');
            testCase.verifyError(@() Genotype("LIAVA/SIAVAA"), ...
                'Genotype:InvalidFormat');
        end

        function testInvalidAminoAcidCode(testCase)
            testCase.verifyError(@() Genotype("LIXVA/SIAVA"), ...
                'Genotype:InvalidAminoAcid');
            testCase.verifyError(@() Genotype("LIAVA/SXAVA"), ...
                'Genotype:InvalidAminoAcid');
        end

        function testNumericInGenotypeThrowsError(testCase)
            testCase.verifyError(@() Genotype("L1AVA/SIAVA"), ...
                'Genotype:InvalidAminoAcid');
        end

        function testLHybridDetection(testCase)
            % Test detection of L-cone hybrid (M-in-L)
            g = Genotype("LATFA/SIAVA");
            obs = g.toObserverParameters();

            testCase.verifyEqual(string(obs.L_OpsinTemplate), "MinL", ...
                'L-cone with Phe277+Ala285 should be M-in-L hybrid');
        end

        function testMHybridDetection(testCase)
            % Test detection of M-cone hybrid (L-in-M)
            g = Genotype("LIAVA/SIAYT");
            obs = g.toObserverParameters();

            testCase.verifyEqual(string(obs.M_OpsinTemplate), "LinM", ...
                'M-cone with Tyr277+Thr285 should be L-in-M hybrid');
        end

        function testNonHybridLCone(testCase)
            g = Genotype("LIAVA/SIAVA");
            obs = g.toObserverParameters();

            testCase.verifyNotEqual(obs.L_OpsinTemplate, "MinL", ...
                'Standard L-cone should not be M-in-L hybrid');
        end

        function testNonHybridMCone(testCase)
            g = Genotype("LIAVA/SIAVA");
            obs = g.toObserverParameters();

            testCase.verifyNotEqual(obs.M_OpsinTemplate, "LinM", ...
                'Standard M-cone should not be L-in-M hybrid');
        end

        function testIsLHybridDirectPredicate(testCase)
            % Direct test of the public isLHybrid predicate. M-in-L hybrid
            % requires Phe at 277 + Ala at 285.
            testCase.verifyTrue(Genotype("LIAFA/SIAVA").isLHybrid(), ...
                'Phe277+Ala285 must report isLHybrid=true');
            testCase.verifyFalse(Genotype("LIAVA/SIAVA").isLHybrid(), ...
                'Standard L-cone (Tyr277+Thr285) must report isLHybrid=false');
            testCase.verifyFalse(Genotype("/SIAVA").isLHybrid(), ...
                'Empty L-genotype must report isLHybrid=false');
        end

        function testIsMHybridDirectPredicate(testCase)
            % Direct test of the public isMHybrid predicate. L-in-M hybrid
            % requires Tyr at 277 + Thr at 285.
            testCase.verifyTrue(Genotype("LIAVA/SIAYT").isMHybrid(), ...
                'Tyr277+Thr285 must report isMHybrid=true');
            testCase.verifyFalse(Genotype("LIAVA/SIAVA").isMHybrid(), ...
                'Standard M-cone (Phe277+Ala285) must report isMHybrid=false');
            testCase.verifyFalse(Genotype("LIAVA").isMHybrid(), ...
                'Empty M-genotype must report isMHybrid=false');
        end

        function testIsValueClass(testCase)
            g1 = Genotype("LIAVA/SIAVA");
            g2 = g1;

            testCase.verifyEqual(g1.LGenotype, g2.LGenotype, ...
                'Copied Genotype should have same LGenotype');
            testCase.verifyEqual(g1.MGenotype, g2.MGenotype, ...
                'Copied Genotype should have same MGenotype');
        end

        function testEmptyBothGenotypes(testCase)
            % Test behavior when both genotypes are empty
            g = Genotype("/");

            testCase.verifyEmpty(g.LGenotype, ...
                'L-genotype should be empty');
            testCase.verifyEmpty(g.MGenotype, ...
                'M-genotype should be empty');
            testCase.verifyEqual(g.ColorVisionType, "achromat", ...
                'No cones should classify as achromat');
        end

        function testZeroShiftForBaselineGenotype(testCase)
            % L-baseline: LSAYT (Leu116, Ser180, Ala230, Tyr277, Thr285)
            % M-baseline: SAAFA (Ser116, Ala180, Ala230, Phe277, Ala285)
            g = Genotype("LSAYT/SAAFA");

            testCase.verifyEqual(g.LShift, 0, 'AbsTol', testCase.AbsTol, ...
                'Baseline L-cone genotype should have zero shift');
            testCase.verifyEqual(g.MShift, 0, 'AbsTol', testCase.AbsTol, ...
                'Baseline M-cone genotype should have zero shift');
        end

        function testLowercaseAminoAcidRejected(testCase)
            testCase.verifyError(@() Genotype("liava/siava"), ...
                'Genotype:InvalidAminoAcid');
        end

        function testStringInputWorks(testCase)
            g = Genotype(string("LIAVA/SIAVA"));

            testCase.verifyEqual(g.LGenotype, 'LIAVA', ...
                'String input should be parsed correctly');
        end

        function testCharInputWorks(testCase)
            g = Genotype('LIAVA/SIAVA');

            testCase.verifyEqual(g.LGenotype, 'LIAVA', ...
                'Char input should be parsed correctly');
        end

        function testObserverProducesValidOutput(testCase)
            g = Genotype("LAAVA/SSAVA");
            obs = g.toObserverParameters(Age=32, FieldSize=10);

            wl = (400:10:700)';
            L = obs.L(wl);
            M = obs.M(wl);
            S = obs.S(wl);

            testCase.verifySize(L, size(wl), 'L sensitivity should match wavelength size');
            testCase.verifySize(M, size(wl), 'M sensitivity should match wavelength size');
            testCase.verifySize(S, size(wl), 'S sensitivity should match wavelength size');

            testCase.verifyTrue(all(L >= 0), 'L sensitivity should be non-negative');
            testCase.verifyTrue(all(M >= 0), 'M sensitivity should be non-negative');
            testCase.verifyTrue(all(S >= 0), 'S sensitivity should be non-negative');
        end

        function testDeuteranopeStillHasLShift(testCase)
            % LAAYT produces only a -4.0 shift from Ala180:
            % Leu116(0), Ala180(-4), Ala230(0), Tyr277(0), Thr285(0)
            g = Genotype("LAAYT");

            Lscale = testCase.LSER_MLMAX_DIFF / testCase.L_BASES_SUM;
            expectedLShift = -4.0 * Lscale;

            testCase.verifyEqual(g.LShift, expectedLShift, 'AbsTol', testCase.AbsTol, ...
                'Deuteranope L-cone shift should be computed');
            testCase.verifyEqual(g.MShift, 0, ...
                'Deuteranope M-cone shift should be zero');
        end

        function testProtanopeStillHasMShift(testCase)
            g = Genotype("/SSAVA");

            Mscale = testCase.LSER_MLMAX_DIFF / testCase.M_BASES_SUM;
            expectedMShift = 3.0 * Mscale;

            testCase.verifyEqual(g.LShift, 0, ...
                'Protanope L-cone shift should be zero');
            testCase.verifyEqual(g.MShift, expectedMShift, 'AbsTol', testCase.AbsTol, ...
                'Protanope M-cone shift should be computed');
        end

        %% IndividualCMF.setGenotype interaction tests

        function testSetGenotypeAllPositions(testCase)
            % Test setGenotype for all positions
            obs = IndividualCMF(Age=32, FieldSize=2);

            % Test L cone positions
            obs.setGenotype('L', 180, 'A');
            obs.setGenotype('L', 277, 'F');
            obs.setGenotype('L', 285, 'A');

            % Test M cone positions
            obs.setGenotype('M', 180, 'S');
            obs.setGenotype('M', 277, 'Y');
            obs.setGenotype('M', 285, 'T');

            % Verify no errors occurred
            testCase.verifyTrue(true);
        end

        function testSetGenotypeLogic(testCase)
            % Verify that setGenotype correctly toggles the Template property
            obs = IndividualCMF(Age=32, FieldSize=2);

            % Initial State
            testCase.verifyEqual(string(obs.L_OpsinTemplate), "Mean", 'Default should be Mean');

            % 1. Polymorphism (L-Ala180) -> Should switch to "Serine" base + Shift
            obs.setGenotype('L', 180, 'Ala');
            testCase.verifyEqual(string(obs.L_OpsinTemplate), "Serine", ...
                'L-Ala180 should switch template to Serine (polymorphic base)');
            testCase.verifyNotEqual(obs.L_LambdaMaxShift, 0, 'L-Ala180 should induce a shift');

            % 2. Hybrid (M-tail on L-head) -> Should switch to "MinL"
            obs.setGenotype('L', 277, 'Phe');
            obs.setGenotype('L', 285, 'Ala');

            testCase.verifyEqual(string(obs.L_OpsinTemplate), "MinL", ...
                'Hybrid genotype (exons 5) should switch template to M-in-L');
        end

    end
end

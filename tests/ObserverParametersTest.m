classdef ObserverParametersTest < matlab.unittest.TestCase
    % OBSERVERPARAMETERSTEST  Unit tests for ObserverParameters class.
    %
    %   Tests cover:
    %   - Default construction produces 10-degree standard values
    %   - Standard-observer snapshots via IndividualCMF(...).getParameters()
    %   - isStandardConfiguration returns true for standard observers
    %   - isStandardConfiguration returns false when any parameter differs
    %   - Construction with custom PhotopigmentParameters
    %   - Genotype partial overrides reaching the snapshot

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada
    %
    % This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    % Licensed under AGPL-3.0-or-later. See LICENSE file for details.
    % Repository: https://github.com/sfu-cs-vision-lab/Individual-CMFs

    properties (Constant)
        RelTol = 1e-10
        AbsTol = 1e-12
    end

    methods (Test)

        function testDefaultConstructionIs10DegStandard(testCase)
            params = ObserverParameters();

            testCase.verifyEqual(params.FieldSize, 10, ...
                'Default FieldSize should be 10 degrees');
            testCase.verifyEqual(params.Age, 32, ...
                'Default Age should be 32');
            testCase.verifyEqual(params.LCone.OpticalDensity, 0.38, ...
                'Default L-cone optical density should be 0.38');
            testCase.verifyEqual(params.MCone.OpticalDensity, 0.38, ...
                'Default M-cone optical density should be 0.38');
            testCase.verifyEqual(params.SCone.OpticalDensity, 0.30, ...
                'Default S-cone optical density should be 0.30');
            testCase.verifyEqual(params.Macular.Density, 0.095, ...
                'Default macular density should be 0.095');
        end

        function testDefaultConstructionAllShiftsZero(testCase)
            params = ObserverParameters();

            testCase.verifyEqual(params.LCone.LambdaMaxShift, 0, ...
                'Default L-cone shift should be 0');
            testCase.verifyEqual(params.MCone.LambdaMaxShift, 0, ...
                'Default M-cone shift should be 0');
            testCase.verifyEqual(params.SCone.LambdaMaxShift, 0, ...
                'Default S-cone shift should be 0');
        end

        function testDefaultConstructionLensFilter(testCase)
            % Test default lens filter configuration
            params = ObserverParameters();

            testCase.verifyEqual(params.Lens.Type, "lens", ...
                'Default lens filter should be type "lens"');
            testCase.verifyEqual(params.Lens.Density, 1.0, ...
                'Default lens density scaling should be 1.0');
            testCase.verifyEqual(params.Lens.Age, 32, ...
                'Default lens age should be 32');
        end

        function testDefaultConstructionMacularFilter(testCase)
            % Test default macular filter configuration
            params = ObserverParameters();

            testCase.verifyEqual(params.Macular.Type, "macular", ...
                'Default macular filter should be type "macular"');
            testCase.verifyEqual(params.Macular.Density, 0.095, ...
                'Default macular density should be 0.095 (10-degree standard)');
        end

        function testStandard10DegFactoryMethod(testCase)
            % Snapshot of the CIE 10-degree standard observer
            params = IndividualCMF(StandardObserver=10).getParameters();

            testCase.verifyEqual(params.FieldSize, 10, ...
                'Standard 10-degree FieldSize should be 10');
            testCase.verifyEqual(params.Age, 32, ...
                'Standard 10-degree Age should be 32');
            testCase.verifyEqual(params.LCone.OpticalDensity, 0.38, ...
                'Standard 10-degree L-cone OD should be 0.38');
            testCase.verifyEqual(params.MCone.OpticalDensity, 0.38, ...
                'Standard 10-degree M-cone OD should be 0.38');
            testCase.verifyEqual(params.SCone.OpticalDensity, 0.30, ...
                'Standard 10-degree S-cone OD should be 0.30');
            testCase.verifyEqual(params.Macular.Density, 0.095, ...
                'Standard 10-degree macular density should be 0.095');
        end

        function testStandard2DegFactoryMethod(testCase)
            % Snapshot of the CIE 2-degree standard observer
            params = IndividualCMF(StandardObserver=2).getParameters();

            testCase.verifyEqual(params.FieldSize, 2, ...
                'Standard 2-degree FieldSize should be 2');
            testCase.verifyEqual(params.Age, 32, ...
                'Standard 2-degree Age should be 32');
            testCase.verifyEqual(params.LCone.OpticalDensity, 0.50, ...
                'Standard 2-degree L-cone OD should be 0.50');
            testCase.verifyEqual(params.MCone.OpticalDensity, 0.50, ...
                'Standard 2-degree M-cone OD should be 0.50');
            testCase.verifyEqual(params.SCone.OpticalDensity, 0.40, ...
                'Standard 2-degree S-cone OD should be 0.40');
            testCase.verifyEqual(params.Macular.Density, 0.350, ...
                'Standard 2-degree macular density should be 0.350');
        end

        function testStandard2DegAllShiftsZero(testCase)
            params = IndividualCMF(StandardObserver=2).getParameters();

            testCase.verifyEqual(params.LCone.LambdaMaxShift, 0, ...
                'Standard 2-degree L-cone shift should be 0');
            testCase.verifyEqual(params.MCone.LambdaMaxShift, 0, ...
                'Standard 2-degree M-cone shift should be 0');
            testCase.verifyEqual(params.SCone.LambdaMaxShift, 0, ...
                'Standard 2-degree S-cone shift should be 0');
        end

        function testStandard10DegAllShiftsZero(testCase)
            params = IndividualCMF(StandardObserver=10).getParameters();

            testCase.verifyEqual(params.LCone.LambdaMaxShift, 0, ...
                'Standard 10-degree L-cone shift should be 0');
            testCase.verifyEqual(params.MCone.LambdaMaxShift, 0, ...
                'Standard 10-degree M-cone shift should be 0');
            testCase.verifyEqual(params.SCone.LambdaMaxShift, 0, ...
                'Standard 10-degree S-cone shift should be 0');
        end

        function testIsStandardConfigurationTrue10Deg(testCase)
            params = IndividualCMF(StandardObserver=10).getParameters();

            testCase.verifyTrue(params.isStandardConfiguration(), ...
                'Standard 10-degree should return true for isStandardConfiguration');
        end

        function testIsStandardConfigurationTrue2Deg(testCase)
            params = IndividualCMF(StandardObserver=2).getParameters();

            testCase.verifyTrue(params.isStandardConfiguration(), ...
                'Standard 2-degree should return true for isStandardConfiguration');
        end

        function testIsStandardConfigurationTrueDefault(testCase)
            params = ObserverParameters();

            testCase.verifyTrue(params.isStandardConfiguration(), ...
                'Default observer should return true for isStandardConfiguration');
        end

        function testIsStandardConfigurationFalseWhenAgeDiffers(testCase)
            params = IndividualCMF(StandardObserver=10).getParameters();
            params.Age = 45;

            testCase.verifyFalse(params.isStandardConfiguration(), ...
                'Non-standard age should return false for isStandardConfiguration');
        end

        function testIsStandardConfigurationFalseWhenFieldSizeDiffers(testCase)
            params = IndividualCMF(StandardObserver=10).getParameters();
            params.FieldSize = 5;

            testCase.verifyFalse(params.isStandardConfiguration(), ...
                'Non-standard field size should return false');
        end

        function testIsStandardConfigurationFalseWhenLConeODDiffers(testCase)
            params = IndividualCMF(StandardObserver=10).getParameters();
            params.LCone = PhotopigmentParameters(OpticalDensity=0.45);

            testCase.verifyFalse(params.isStandardConfiguration(), ...
                'Non-standard L-cone OD should return false');
        end

        function testIsStandardConfigurationFalseWhenMConeODDiffers(testCase)
            params = IndividualCMF(StandardObserver=10).getParameters();
            params.MCone = PhotopigmentParameters(OpticalDensity=0.45);

            testCase.verifyFalse(params.isStandardConfiguration(), ...
                'Non-standard M-cone OD should return false');
        end

        function testIsStandardConfigurationFalseWhenSConeODDiffers(testCase)
            params = IndividualCMF(StandardObserver=10).getParameters();
            params.SCone = PhotopigmentParameters(OpticalDensity=0.35);

            testCase.verifyFalse(params.isStandardConfiguration(), ...
                'Non-standard S-cone OD should return false');
        end

        function testIsStandardConfigurationFalseWhenLShiftNonZero(testCase)
            params = IndividualCMF(StandardObserver=10).getParameters();
            params.LCone = PhotopigmentParameters(OpticalDensity=0.38, LambdaMaxShift=2);

            testCase.verifyFalse(params.isStandardConfiguration(), ...
                'Non-zero L-cone shift should return false');
        end

        function testIsStandardConfigurationFalseWhenMShiftNonZero(testCase)
            params = IndividualCMF(StandardObserver=10).getParameters();
            params.MCone = PhotopigmentParameters(OpticalDensity=0.38, LambdaMaxShift=-1);

            testCase.verifyFalse(params.isStandardConfiguration(), ...
                'Non-zero M-cone shift should return false');
        end

        function testIsStandardConfigurationFalseWhenSShiftNonZero(testCase)
            params = IndividualCMF(StandardObserver=10).getParameters();
            params.SCone = PhotopigmentParameters(OpticalDensity=0.30, LambdaMaxShift=1);

            testCase.verifyFalse(params.isStandardConfiguration(), ...
                'Non-zero S-cone shift should return false');
        end

        function testIsStandardConfigurationFalseWhenMacularDensityDiffers(testCase)
            params = IndividualCMF(StandardObserver=10).getParameters();
            params.Macular = PreReceptoralFilter(Type="macular", Density=0.2);

            testCase.verifyFalse(params.isStandardConfiguration(), ...
                'Non-standard macular density should return false');
        end

        function testIsStandardConfigurationFalseWhenLensDensityDiffers(testCase)
            params = IndividualCMF(StandardObserver=10).getParameters();
            params.Lens = PreReceptoralFilter(Type="lens", Density=1.5, Age=32);

            testCase.verifyFalse(params.isStandardConfiguration(), ...
                'Non-standard lens density should return false');
        end

        function testIsStandardConfigurationFalseWhenLensAgeDiffers(testCase)
            params = IndividualCMF(StandardObserver=10).getParameters();
            params.Lens = PreReceptoralFilter(Type="lens", Density=1.0, Age=45);

            testCase.verifyFalse(params.isStandardConfiguration(), ...
                'Non-standard lens age should return false');
        end

        function testConstructionWithCustomLCone(testCase)
            % Test construction with custom L-cone parameters
            customL = PhotopigmentParameters(OpticalDensity=0.45, LambdaMaxShift=-3);
            params = ObserverParameters(LCone=customL);

            testCase.verifyEqual(params.LCone.OpticalDensity, 0.45, ...
                'Custom L-cone OD should be preserved');
            testCase.verifyEqual(params.LCone.LambdaMaxShift, -3, ...
                'Custom L-cone shift should be preserved');
        end

        function testConstructionWithCustomMCone(testCase)
            % Test construction with custom M-cone parameters
            customM = PhotopigmentParameters(OpticalDensity=0.42, LambdaMaxShift=2);
            params = ObserverParameters(MCone=customM);

            testCase.verifyEqual(params.MCone.OpticalDensity, 0.42, ...
                'Custom M-cone OD should be preserved');
            testCase.verifyEqual(params.MCone.LambdaMaxShift, 2, ...
                'Custom M-cone shift should be preserved');
        end

        function testConstructionWithCustomSCone(testCase)
            % Test construction with custom S-cone parameters
            customS = PhotopigmentParameters(OpticalDensity=0.35, LambdaMaxShift=-1);
            params = ObserverParameters(SCone=customS);

            testCase.verifyEqual(params.SCone.OpticalDensity, 0.35, ...
                'Custom S-cone OD should be preserved');
            testCase.verifyEqual(params.SCone.LambdaMaxShift, -1, ...
                'Custom S-cone shift should be preserved');
        end

        function testConstructionWithCustomAge(testCase)
            % Test construction with custom age
            params = ObserverParameters(Age=50);

            testCase.verifyEqual(params.Age, 50, ...
                'Custom age should be preserved');
        end

        function testConstructionWithCustomFieldSize(testCase)
            % Test construction with custom field size
            params = ObserverParameters(FieldSize=5);

            testCase.verifyEqual(params.FieldSize, 5, ...
                'Custom field size should be preserved');
        end

        function testConstructionWithCustomLensFilter(testCase)
            % Test construction with custom lens filter
            customLens = PreReceptoralFilter(Type="lens", Density=1.2, Age=45);
            params = ObserverParameters(Lens=customLens);

            testCase.verifyEqual(params.Lens.Density, 1.2, ...
                'Custom lens density should be preserved');
            testCase.verifyEqual(params.Lens.Age, 45, ...
                'Custom lens age should be preserved');
        end

        function testConstructionWithCustomMacularFilter(testCase)
            % Test construction with custom macular filter
            customMacular = PreReceptoralFilter(Type="macular", Density=0.25);
            params = ObserverParameters(Macular=customMacular);

            testCase.verifyEqual(params.Macular.Density, 0.25, ...
                'Custom macular density should be preserved');
        end

        function testConstructionWithAllCustomParameters(testCase)
            % Test construction with all custom parameters
            customL = PhotopigmentParameters(OpticalDensity=0.45, LambdaMaxShift=-2);
            customM = PhotopigmentParameters(OpticalDensity=0.42, LambdaMaxShift=1);
            customS = PhotopigmentParameters(OpticalDensity=0.35, LambdaMaxShift=0);
            customLens = PreReceptoralFilter(Type="lens", Density=1.1, Age=40);
            customMacular = PreReceptoralFilter(Type="macular", Density=0.20);

            params = ObserverParameters( ...
                LCone=customL, MCone=customM, SCone=customS, ...
                Lens=customLens, Macular=customMacular, ...
                Age=40, FieldSize=5);

            testCase.verifyEqual(params.LCone.OpticalDensity, 0.45);
            testCase.verifyEqual(params.LCone.LambdaMaxShift, -2);
            testCase.verifyEqual(params.MCone.OpticalDensity, 0.42);
            testCase.verifyEqual(params.MCone.LambdaMaxShift, 1);
            testCase.verifyEqual(params.SCone.OpticalDensity, 0.35);
            testCase.verifyEqual(params.Lens.Density, 1.1);
            testCase.verifyEqual(params.Macular.Density, 0.20);
            testCase.verifyEqual(params.Age, 40);
            testCase.verifyEqual(params.FieldSize, 5);
        end

        function testIsValueClass(testCase)
            params1 = IndividualCMF(StandardObserver=10).getParameters();
            params2 = params1;
            params2.Age = 45;

            testCase.verifyEqual(params1.Age, 32, ...
                'Value class: modifying copy should not affect original');
            testCase.verifyEqual(params2.Age, 45, ...
                'Value class: copy should have modified value');
        end

        function testGenotypeAbsentGivesStandardObserver(testCase)
            % No genotype override leaves the standard 10-degree observer.
            params = IndividualCMF().getParameters();

            testCase.verifyTrue(params.isStandardConfiguration(), ...
                'Empty genotype should return standard observer');
        end

        function testGenotypeSingleL180Ala(testCase)
            % L_180_Ala produces the Table 3 shift scaled by the L bases sum.
            params = IndividualCMF(Genotype=struct('L_180', 'Ala')).getParameters();

            LSER_MLMAX_DIFF = 23.67;
            L_BASES_SUM = 31;
            expectedShift = -4.0 * (LSER_MLMAX_DIFF / L_BASES_SUM);

            testCase.verifyEqual(params.LCone.LambdaMaxShift, expectedShift, ...
                'RelTol', testCase.RelTol, ...
                'L_180_Ala should produce expected shift');
            testCase.verifyEqual(params.MCone.LambdaMaxShift, 0, ...
                'M-cone shift should be 0 when only L genotype specified');
        end

        function testGenotypeSingleM180Ser(testCase)
            % M_180_Ser produces the Table 3 shift scaled by the M bases sum.
            params = IndividualCMF(Genotype=struct('M_180', 'Ser')).getParameters();

            LSER_MLMAX_DIFF = 23.67;
            M_BASES_SUM = 27;
            expectedShift = 3.0 * (LSER_MLMAX_DIFF / M_BASES_SUM);

            testCase.verifyEqual(params.MCone.LambdaMaxShift, expectedShift, ...
                'RelTol', testCase.RelTol, ...
                'M_180_Ser should produce expected shift');
            testCase.verifyEqual(params.LCone.LambdaMaxShift, 0, ...
                'L-cone shift should be 0 when only M genotype specified');
        end

        function testGenotypeMultipleEntries(testCase)
            % L and M overrides in one call must not interfere.
            params = IndividualCMF(Genotype=struct( ...
                'L_180', 'Ala', 'M_180', 'Ser')).getParameters();

            LSER_MLMAX_DIFF = 23.67;
            L_BASES_SUM = 31;
            M_BASES_SUM = 27;
            expectedLShift = -4.0 * (LSER_MLMAX_DIFF / L_BASES_SUM);
            expectedMShift = 3.0 * (LSER_MLMAX_DIFF / M_BASES_SUM);

            testCase.verifyEqual(params.LCone.LambdaMaxShift, expectedLShift, ...
                'RelTol', testCase.RelTol, ...
                'L-cone shift should be correct with multiple entries');
            testCase.verifyEqual(params.MCone.LambdaMaxShift, expectedMShift, ...
                'RelTol', testCase.RelTol, ...
                'M-cone shift should be correct with multiple entries');
        end

        function testGenotypePreservesOtherParameters(testCase)
            % A partial override touches lambda-max only: densities, age,
            % and field size stay at their standard 10-degree values.
            params = IndividualCMF(Genotype=struct('L_180', 'Ala')).getParameters();

            testCase.verifyEqual(params.FieldSize, 10, ...
                'Field size should remain 10');
            testCase.verifyEqual(params.Age, 32, ...
                'Age should remain 32');
            testCase.verifyEqual(params.LCone.OpticalDensity, 0.38, ...
                'L-cone OD should remain 0.38');
            testCase.verifyEqual(params.MCone.OpticalDensity, 0.38, ...
                'M-cone OD should remain 0.38');
            testCase.verifyEqual(params.SCone.OpticalDensity, 0.30, ...
                'S-cone OD should remain 0.30');
        end

        function testGenotypeL277Phe(testCase)
            % L_277_Phe, a larger shift than position 180.
            params = IndividualCMF(Genotype=struct('L_277', 'Phe')).getParameters();

            LSER_MLMAX_DIFF = 23.67;
            L_BASES_SUM = 31;
            expectedShift = -7.0 * (LSER_MLMAX_DIFF / L_BASES_SUM);

            testCase.verifyEqual(params.LCone.LambdaMaxShift, expectedShift, ...
                'RelTol', testCase.RelTol, ...
                'L_277_Phe should produce expected shift');
        end

        function testGenotypeM285Thr(testCase)
            % M_285_Thr, the largest single-position shift in Table 3.
            params = IndividualCMF(Genotype=struct('M_285', 'Thr')).getParameters();

            LSER_MLMAX_DIFF = 23.67;
            M_BASES_SUM = 27;
            expectedShift = 14.0 * (LSER_MLMAX_DIFF / M_BASES_SUM);

            testCase.verifyEqual(params.MCone.LambdaMaxShift, expectedShift, ...
                'RelTol', testCase.RelTol, ...
                'M_285_Thr should produce expected shift');
        end

        function testGenotypeUnknownPositionRejected(testCase)
            % The removed fromGenotype silently ignored an unrecognised
            % position, so a typo returned standard-observer numbers while
            % the caller believed a variant had been applied. The
            % constructor rejects it instead.
            testCase.verifyError( ...
                @() IndividualCMF(Genotype=struct('L_180', 'Ala', 'L_999', 'Unknown')), ...
                'MATLAB:validators:mustBeMember', ...
                'An unrecognised genotype position must be rejected, not ignored');
        end

        function testGenotypeUnknownAminoAcidGivesNoShift(testCase)
            % A valid position with an unrecognised amino acid is not an
            % error: the position simply contributes no shift.
            params = IndividualCMF(Genotype=struct('L_180', 'Zzz')).getParameters();

            testCase.verifyEqual(params.LCone.LambdaMaxShift, 0, ...
                'An unrecognised amino acid should contribute no shift');
        end

        function testGenotypeCumulativeShifts(testCase)
            % Two positions on the same cone add rather than replace.
            params = IndividualCMF(Genotype=struct( ...
                'L_180', 'Ala', 'L_277', 'Phe')).getParameters();

            LSER_MLMAX_DIFF = 23.67;
            L_BASES_SUM = 31;
            expectedShift = (-4.0 + -7.0) * (LSER_MLMAX_DIFF / L_BASES_SUM);

            testCase.verifyEqual(params.LCone.LambdaMaxShift, expectedShift, ...
                'RelTol', testCase.RelTol, ...
                'Multiple L genotype entries should produce cumulative shift');
        end

        function testNonPositiveAgeNotAllowed(testCase)
            testCase.verifyError(@() ObserverParameters(Age=0), ...
                'MATLAB:validators:mustBePositive');
            testCase.verifyError(@() ObserverParameters(Age=-10), ...
                'MATLAB:validators:mustBePositive');
        end

        function testNonPositiveFieldSizeNotAllowed(testCase)
            testCase.verifyError(@() ObserverParameters(FieldSize=0), ...
                'MATLAB:validators:mustBePositive');
            testCase.verifyError(@() ObserverParameters(FieldSize=-5), ...
                'MATLAB:validators:mustBePositive');
        end

        function testStandard2DegLensConfiguration(testCase)
            params = IndividualCMF(StandardObserver=2).getParameters();

            testCase.verifyEqual(params.Lens.Type, "lens", ...
                'Standard 2-degree should have lens type');
            testCase.verifyEqual(params.Lens.Density, 1.0, ...
                'Standard 2-degree lens density should be 1.0');
            testCase.verifyEqual(params.Lens.Age, 32, ...
                'Standard 2-degree lens age should be 32');
        end

        function testStandard10DegLensConfiguration(testCase)
            params = IndividualCMF(StandardObserver=10).getParameters();

            testCase.verifyEqual(params.Lens.Type, "lens", ...
                'Standard 10-degree should have lens type');
            testCase.verifyEqual(params.Lens.Density, 1.0, ...
                'Standard 10-degree lens density should be 1.0');
            testCase.verifyEqual(params.Lens.Age, 32, ...
                'Standard 10-degree lens age should be 32');
        end

        function testDefaultMatchesStandard10Deg(testCase)
            % Verify that default constructor matches the 10-degree standard
            defaultParams = ObserverParameters();
            std10Params = IndividualCMF(StandardObserver=10).getParameters();

            testCase.verifyEqual(defaultParams.FieldSize, std10Params.FieldSize);
            testCase.verifyEqual(defaultParams.Age, std10Params.Age);
            testCase.verifyEqual(defaultParams.LCone.OpticalDensity, std10Params.LCone.OpticalDensity);
            testCase.verifyEqual(defaultParams.LCone.LambdaMaxShift, std10Params.LCone.LambdaMaxShift);
            testCase.verifyEqual(defaultParams.MCone.OpticalDensity, std10Params.MCone.OpticalDensity);
            testCase.verifyEqual(defaultParams.MCone.LambdaMaxShift, std10Params.MCone.LambdaMaxShift);
            testCase.verifyEqual(defaultParams.SCone.OpticalDensity, std10Params.SCone.OpticalDensity);
            testCase.verifyEqual(defaultParams.SCone.LambdaMaxShift, std10Params.SCone.LambdaMaxShift);
            testCase.verifyEqual(defaultParams.Lens.Density, std10Params.Lens.Density);
            testCase.verifyEqual(defaultParams.Macular.Density, std10Params.Macular.Density);
        end

    end
end

classdef ConstructorGenotypeTest < matlab.unittest.TestCase
    % CONSTRUCTORGENOTYPETEST  Tests for constructor genotype handling.

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
        
        function testGenotypeAsStruct(testCase)
            % Verify passing a struct to the constructor works
            genoStruct = struct('L_180', 'Ala', 'M_180', 'Ser');
            obs = IndividualCMF(Age=32, Genotype=genoStruct);
            
            % Check L-cone (Ala180 should induce a shift)
            testCase.verifyEqual(string(obs.L_OpsinTemplate), "Serine", ...
                'Struct input L_180=Ala should set template to Serine');
            testCase.verifyNotEqual(obs.L_LambdaMaxShift, 0, ...
                'Struct input L_180=Ala should induce a shift');
                
            % Check M-cone (Ser180 should induce a shift)
            testCase.verifyNotEqual(obs.M_LambdaMaxShift, 0, ...
                'Struct input M_180=Ser should induce a shift');
        end
        
        function testGenotypeAsDictionary(testCase)
            d = dictionary(["L_277", "L_285"], ["Phe", "Ala"]);
            
            obs = IndividualCMF(Age=32, Genotype=d);
            
            % This specific combo (L_277 Phe + L_285 Ala) should trigger the Hybrid template
            testCase.verifyEqual(string(obs.L_OpsinTemplate), "MinL", ...
                'Dictionary input for Hybrid exons should set template to M-in-L');
        end
        
        function testStandardObserverConflict(testCase)
            % You cannot set a Genotype override on a Standard Observer
            geno = struct('L_180', 'Ala');
            
            testCase.verifyError(...
                @() IndividualCMF(StandardObserver=2, Genotype=geno), ...
                'IndividualCMF:Conflict', ...
                'Should fail when Genotype is provided with StandardObserver');
        end
        
        function testMixedGenotypeInputs(testCase)
            % Test a complex mix of inputs
            % Age 60 (affects lens with Pokorny1987) + L-Ala180 (affects L-cone)
            % Use Pokorny1987 lens model since StockmanRider2023 has no lens aging
            obs = IndividualCMF(Age=60, Genotype=struct('L_180', 'Ala'), LensModel="Pokorny1987");

            % Verify Lens is aged with Pokorny1987 model
            % At age 60: TL = TL1 * 1.56 + TL2 = 0.600 * 1.56 + 1.000 = 1.936
            testCase.verifyTrue(obs.LensDensity > 1.8, 'Age=60 should increase lens density with Pokorny1987');

            % Verify L-cone is shifted
            testCase.verifyEqual(string(obs.L_OpsinTemplate), "Serine", 'Genotype should still process correctly with Age');
        end

        function testGenotypeAsString(testCase)
            % Constructor with Genotype="..." string form should parse the
            % 5-letter notation and produce the same shift as applyGenotype
            % on the same string.
            obs_ctor  = IndividualCMF(Genotype="LIAVA/SIAVA");
            obs_apply = IndividualCMF();
            obs_apply.applyGenotype("LIAVA/SIAVA");

            testCase.verifyEqual(obs_ctor.L_LambdaMaxShift, obs_apply.L_LambdaMaxShift, ...
                'AbsTol', 1e-9, ...
                'String-form Genotype= should produce the same L shift as applyGenotype');
            testCase.verifyEqual(obs_ctor.M_LambdaMaxShift, obs_apply.M_LambdaMaxShift, ...
                'AbsTol', 1e-9, ...
                'String-form Genotype= should produce the same M shift as applyGenotype');
        end

        function testGenotypeStringHybridDetection(testCase)
            % String form should also trigger hybrid template detection.
            obs = IndividualCMF(Genotype="LIAFA/SIAVA");  % M-in-L: Phe at L_277, Ala at L_285
            testCase.verifyEqual(string(obs.L_OpsinTemplate), "MinL", ...
                'String form should detect M-in-L hybrid');
        end

        function testConflict_Genotype_and_LambdaMaxShift(testCase)
            % Cannot combine explicit shift with Genotype.
            testCase.verifyError( ...
                @() IndividualCMF(L_LambdaMaxShift=5, Genotype=struct('L_180','Ala')), ...
                'IndividualCMF:Conflict', ...
                'L_LambdaMaxShift + Genotype should error');
            testCase.verifyError( ...
                @() IndividualCMF(M_LambdaMaxShift=3, Genotype=struct('M_180','Ser')), ...
                'IndividualCMF:Conflict', ...
                'M_LambdaMaxShift + Genotype should error');
            testCase.verifyError( ...
                @() IndividualCMF(S_LambdaMaxShift=2, Genotype=struct('L_180','Ala')), ...
                'IndividualCMF:Conflict', ...
                'S_LambdaMaxShift + Genotype should error');
        end

        function testConflict_Genotype_and_OpsinTemplate(testCase)
            % Cannot combine explicit opsin template with Genotype.
            testCase.verifyError( ...
                @() IndividualCMF(L_OpsinTemplate="Serine", Genotype=struct('L_180','Ala')), ...
                'IndividualCMF:Conflict', ...
                'L_OpsinTemplate + Genotype should error');
            testCase.verifyError( ...
                @() IndividualCMF(M_OpsinTemplate="Standard", Genotype=struct('M_180','Ser')), ...
                'IndividualCMF:Conflict', ...
                'M_OpsinTemplate + Genotype should error');
        end

        function testNoConflict_DefaultArgsWithGenotype(testCase)
            % Default values for shift (0) and template ("Mean") should NOT
            % count as user overrides -- passing only Genotype is valid.
            obs = IndividualCMF(Genotype=struct('L_180','Ala'));
            testCase.verifyNotEqual(obs.L_LambdaMaxShift, 0, ...
                'Genotype-only construction should work without conflict');
        end

    end
end
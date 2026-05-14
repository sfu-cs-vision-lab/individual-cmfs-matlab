classdef StandardObserverTest < matlab.unittest.TestCase
    % STANDARDOBSERVERTEST  Tests for standard observer configurations.

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

    properties
        Data2Deg
        Data10Deg
    end
    
    methods(TestMethodSetup)
        function loadData(testCase)
            folder = fileparts(mfilename('fullpath'));
            testCase.Data2Deg = readtable(fullfile(folder, 'data', 'standard_2deg.csv'));
            testCase.Data10Deg = readtable(fullfile(folder, 'data', 'standard_10deg.csv'));
        end
    end
    
    methods(Test)

        function test2DegStandardEnergy(testCase)
            % Verify the CIE 2006 2-degree Standard Observer
            obs = IndividualCMF(StandardObserver=2);
            wl = testCase.Data2Deg.nm;

            % Check Energy (Raw)
            % This is the most critical test. It proves your physics engine 
            % produces the exact same raw output as the Python reference.
            obs.OutputFormat = "energy";
            obs.NormalizeOutput = false; 

            testCase.verifyEqual(obs.L(wl), testCase.Data2Deg.L_energy, 'RelTol', 1e-10, '2-deg L Energy mismatch');
            testCase.verifyEqual(obs.M(wl), testCase.Data2Deg.M_energy, 'RelTol', 1e-10, '2-deg M Energy mismatch');
            testCase.verifyEqual(obs.S(wl), testCase.Data2Deg.S_energy, 'RelTol', 1e-10, '2-deg S Energy mismatch');
        end


        function test2DegStandardQuantal(testCase)
            % Verify the CIE 2006 2-degree Standard Observer
            obs = IndividualCMF(StandardObserver=2);
            wl = testCase.Data2Deg.nm;

            % Check Quantal (Raw)
            obs.OutputFormat = "quantal";
            obs.NormalizeOutput = false;

            testCase.verifyEqual(obs.L(wl), testCase.Data2Deg.L_quantal, 'RelTol', 1e-10, '2-deg L Quantal mismatch');
            testCase.verifyEqual(obs.M(wl), testCase.Data2Deg.M_quantal, 'RelTol', 1e-10, '2-deg M Quantal mismatch');
            testCase.verifyEqual(obs.S(wl), testCase.Data2Deg.S_quantal, 'RelTol', 1e-10, '2-deg S Quantal mismatch');
        end

        function test10DegStandardEnergy(testCase)
            % Verify the CIE 2006 10-degree Standard Observer
            obs = IndividualCMF(StandardObserver=10);
            wl = testCase.Data10Deg.nm;

            % Check Energy (Raw)
            obs.OutputFormat = "energy";
            obs.NormalizeOutput = false;

            testCase.verifyEqual(obs.L(wl), testCase.Data10Deg.L_energy, 'RelTol', 1e-9, '10-deg L Energy mismatch');
            testCase.verifyEqual(obs.M(wl), testCase.Data10Deg.M_energy, 'RelTol', 1e-9, '10-deg M Energy mismatch');
            testCase.verifyEqual(obs.S(wl), testCase.Data10Deg.S_energy, 'RelTol', 1e-9, '10-deg S Energy mismatch');

        end

        function test10DegStandardQuantal(testCase)
            % Verify the CIE 2006 10-degree Standard Observer
            obs = IndividualCMF(StandardObserver=10);
            wl = testCase.Data10Deg.nm;

            % Check Quantal (Raw)
            obs.OutputFormat = "quantal";
            obs.NormalizeOutput = false;

            testCase.verifyEqual(obs.L(wl), testCase.Data10Deg.L_quantal, 'RelTol', 1e-9, '10-deg L Quantal mismatch');
            testCase.verifyEqual(obs.M(wl), testCase.Data10Deg.M_quantal, 'RelTol', 1e-9, '10-deg M Quantal mismatch');
            testCase.verifyEqual(obs.S(wl), testCase.Data10Deg.S_quantal, 'RelTol', 1e-9, '10-deg S Quantal mismatch');
        end

        %% Type Inference Tests

        function test10DegDefaultType(testCase)
            % Verify IndividualCMF(10) defaults to CIE 170-1:2006 Type
            obs = IndividualCMF(FieldSize=10);
            testCase.verifyEqual(obs.Type, "CIE 170-1:2006", ...
                'IndividualCMF(10) should default to CIE 170-1:2006 Type');
            testCase.verifyEqual(string(obs.MacularDensityAlgorithm), "CIE170", ...
                'Default MacularDensityAlgorithm at 10deg should be CIE Constants');
            testCase.verifyEqual(string(obs.PhotopigmentDensityAlgorithm), "CIE170", ...
                'Default PhotopigmentDensityAlgorithm at 10deg should be CIE Constants');
        end

        function test10DegNonStandardAge(testCase)
            % Verify that changing Age makes Type Individualized
            obs = IndividualCMF(FieldSize=10, Age=33);
            testCase.verifyEqual(obs.Type, "Individualized", ...
                'IndividualCMF(10, Age=33) should be Individualized');
        end

        function test10DegNonStandardTemplate(testCase)
            % Verify that using Govardovskii2000 makes Type Individualized
            obs = IndividualCMF(FieldSize=10, PhotopigmentModel="Govardovskii2000");
            testCase.verifyEqual(obs.Type, "Individualized", ...
                'IndividualCMF(10, PhotopigmentModel=Govardovskii2000) should be Individualized');
        end

        function testNonStandardFieldSize(testCase)
            % Verify that non-standard field sizes result in Individualized Type
            obs = IndividualCMF(FieldSize=5);
            testCase.verifyEqual(obs.Type, "Individualized", ...
                'IndividualCMF(5) should be Individualized');
            testCase.verifyEqual(string(obs.MacularDensityAlgorithm), "MorelandAlexander", ...
                'Non-standard field size should use MorelandAlexander');
            testCase.verifyEqual(string(obs.PhotopigmentDensityAlgorithm), "PokornySmith", ...
                'Non-standard field size should use PokornySmith');
        end

        function testConeShiftMakesIndividualized(testCase)
            % Verify that cone shifts make Type Individualized
            obs = IndividualCMF(FieldSize=10, L_LambdaMaxShift=1);
            testCase.verifyEqual(obs.Type, "Individualized", ...
                'Cone shift should make Type Individualized');
        end

        function testAlgorithmOverrideMakesIndividualized(testCase)
            % Verify that explicit algorithm override at 10deg can make Type Individualized
            obs = IndividualCMF(FieldSize=10, MacularDensityAlgorithm="MorelandAlexander");
            testCase.verifyEqual(obs.Type, "Individualized", ...
                'MorelandAlexander algorithm at 10deg should make Type Individualized');
            % Verify the macular density is formula-based (~0.09495) not exact CIE constant (0.095)
            testCase.verifyLessThan(abs(obs.MacularDensity - 0.09495), 1e-4, ...
                'MorelandAlexander should produce precise formula value');
        end

        % StandardObserver derived property

        function testStandardObserverDefaultIs10(testCase)
            % IndividualCMF() with no args should report StandardObserver == 10
            obs = IndividualCMF();
            testCase.verifyEqual(obs.StandardObserver, 10);
        end

        function testStandardObserverConstructorTwoDeg(testCase)
            obs = IndividualCMF(StandardObserver=2);
            testCase.verifyEqual(obs.StandardObserver, 2);
            testCase.verifyEqual(obs.FieldSize, 2);
        end

        function testStandardObserverGoesToZeroAfterEdit(testCase)
            % Any biophysical edit drops StandardObserver to 0
            obs = IndividualCMF(StandardObserver=10);
            obs.Age = 70;
            testCase.verifyEqual(obs.StandardObserver, 0);
            testCase.verifyEqual(obs.Type, "Individualized");
        end

        function testStandardObserverSetterSnapsBack(testCase)
            % Setting StandardObserver=2 on an edited observer snaps every
            % biophysical parameter to the 2-deg tabulated values
            obs = IndividualCMF(StandardObserver=10);
            obs.Age = 70;
            obs.LensDensity = 2.5;            % engages Custom mode
            testCase.verifyEqual(obs.StandardObserver, 0);
            testCase.verifyEqual(string(obs.LensDensityAlgorithm), "Custom");

            obs.StandardObserver = 2;
            testCase.verifyEqual(obs.StandardObserver, 2);
            testCase.verifyEqual(obs.Type, "CIE 170-1:2006");
            testCase.verifyEqual(obs.Age, 32);
            testCase.verifyEqual(obs.FieldSize, 2);
            testCase.verifyEqual(string(obs.LensDensityAlgorithm), "Auto");
            testCase.verifyEqual(string(obs.MacularDensityAlgorithm), "CIE170");
            testCase.verifyEqual(string(obs.PhotopigmentDensityAlgorithm), "CIE170");
        end

        function testStandardObserverSetterRejectsZero(testCase)
            obs = IndividualCMF();
            testCase.verifyError(@() setSO(obs, 0), 'MATLAB:validators:mustBeMember');
        end

        function testStandardObserverSetterRejectsArbitraryValue(testCase)
            obs = IndividualCMF();
            testCase.verifyError(@() setSO(obs, 5), 'MATLAB:validators:mustBeMember');
        end

        function testStandardObserverPreservesOutputSettings(testCase)
            % Snap should preserve OutputFormat / NormalizeOutput / LogOutput
            obs = IndividualCMF(StandardObserver=10);
            obs.OutputFormat = "quantal";
            obs.LogOutput = true;
            obs.NormalizeOutput = false;
            obs.Age = 70;                     % drift out of standard
            obs.StandardObserver = 2;         % snap back

            testCase.verifyEqual(string(obs.OutputFormat), "quantal");
            testCase.verifyEqual(obs.LogOutput, true);
            testCase.verifyEqual(obs.NormalizeOutput, false);
        end

    end
end

function setSO(obs, val)
    obs.StandardObserver = val;
end
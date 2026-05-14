classdef GenotypeIntegrationTest < matlab.unittest.TestCase
    
    properties
        Data
        Wavelengths
    end
    
    methods(TestMethodSetup)
        function loadData(testCase)
            try
                testCase.Data = readtable('tests/data/genotype_rgb_verification.csv'); 
                testCase.Wavelengths = testCase.Data.nm;
            catch
                testCase.Data = readtable('genotype_rgb_verification.csv');
                testCase.Wavelengths = testCase.Data.nm;
            end
        end
    end
    
    methods(Test)
        
        function testGenotypeShiftCalculation(testCase)
            % 1. Verify Shifts are correct.
            % The Genotype struct fully determines the L/M templates and
            % shifts -- explicit L_OpsinTemplate is no longer combined here
            % (would be a IndividualCMF:Conflict error).
            myGenotype = struct('L_180','Ala', 'M_180','Ser');
            obs = IndividualCMF('Age', 32, 'FieldSize', 2, 'Genotype', myGenotype);

            testCase.verifyEqual(obs.L_LambdaMaxShift, testCase.Data.L_shift(1), 'AbsTol', 1e-6);
            testCase.verifyEqual(obs.M_LambdaMaxShift, testCase.Data.M_shift(1), 'AbsTol', 1e-6);
            testCase.verifyEqual(string(obs.L_OpsinTemplate), "Serine", ...
                'L_180=Ala (non-hybrid) should leave L_OpsinTemplate at "Serine".');
        end
        
        function testLMSMatch(testCase)
            % 2. Verify LMS Energy curves match Python (Normalized)
            myGenotype = struct('L_180','Ala', 'M_180','Ser');

            % Explicitly configure Sampled normalization to match CSV resolution.
            % The CSV data is at 5nm resolution (380:5:780), so we must configure
            % the normalization to use the same wavelength grid for peak finding.
            obs = IndividualCMF(...
                'Age', 32, 'FieldSize', 2, ...
                'Genotype', myGenotype, ...
                'OutputFormat', 'energy', ...
                'NormalizeOutput', true, ...
                'NormalizationMethod', struct('Method', "Sampled", ...
                    'Start', 380, 'Stop', 780, 'Step', 5));  % Match CSV wavelength grid

            L = obs.L(testCase.Wavelengths);
            M = obs.M(testCase.Wavelengths);
            S = obs.S(testCase.Wavelengths);

            % Verify directly against normalized CSV data
            testCase.verifyEqual(L, testCase.Data.L_energy, 'AbsTol', 1e-4, 'L-Cone Energy Mismatch');
            testCase.verifyEqual(M, testCase.Data.M_energy, 'AbsTol', 1e-4, 'M-Cone Energy Mismatch');
            testCase.verifyEqual(S, testCase.Data.S_energy, 'AbsTol', 1e-4, 'S-Cone Energy Mismatch');
        end
        
        function testRGBMatch(testCase)
            % 3. Verify RGB Output
            % Uses explicit Sampled normalization configuration matching CSV resolution.
            myGenotype = struct('L_180','Ala', 'M_180','Ser');

            obs = IndividualCMF(...
                'Age', 32, 'FieldSize', 2, ...
                'Genotype', myGenotype, ...
                'OutputFormat', 'energy', ...
                'NormalizeOutput', true, ...
                'NormalizationMethod', struct('Method', "Sampled", ...
                    'Start', 380, 'Stop', 780, 'Step', 5));  % Match CSV wavelength grid

            % 1. Get Normalized Spectrum (Peak = 1.0)
            wls = testCase.Wavelengths;
            L_norm = obs.L(wls);
            M_norm = obs.M(wls);
            S_norm = obs.S(wls);

            % 2. Get Normalized Primaries
            % The cache uses the global peak from the configured grid,
            % so these will be correctly scaled relative to the full spectrum.
            prim_wls = [645.15; 526.32; 444.44];
            L_p = obs.L(prim_wls);
            M_p = obs.M(prim_wls);
            S_p = obs.S(prim_wls);

            % 3. Calculate Matrix & RGB
            M_mat = [L_p, M_p, S_p]';
            LMS_norm = [L_norm, M_norm, S_norm]';
            RGB_calc = (M_mat \ LMS_norm)';

            % 4. Verify
            testCase.verifyEqual(RGB_calc(:,1), testCase.Data.R_cmf, 'AbsTol', 1e-4, 'Red CMF Mismatch');
            testCase.verifyEqual(RGB_calc(:,2), testCase.Data.G_cmf, 'AbsTol', 1e-4, 'Green CMF Mismatch');
            testCase.verifyEqual(RGB_calc(:,3), testCase.Data.B_cmf, 'AbsTol', 1e-4, 'Blue CMF Mismatch');
        end
    end
end
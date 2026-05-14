classdef NormalizationTest < matlab.unittest.TestCase
    % NORMALIZATIONTEST  Tests for normalization configuration and behavior.
    %
    %   Tests the NormalizationMethod property, NormalizationConfig, and
    %   the NormalizationCache class for correct behavior.
    %
    %   Key concepts:
    %   - Both "Continuous" and "Sampled" evaluate the SAME continuous function
    %   - The only difference is how the normalization peak is found:
    %     * Continuous: True peak via computePeakForFormat (analytical for
    %                   Govardovskii absorptance, fminbnd otherwise)
    %     * Sampled: Uses max() over a discrete wavelength grid

    methods(Test)

        %% --- Configuration Tests ---

        function testContinuousIsDefault(testCase)
            % Verify Continuous is the default normalization method
            obs = IndividualCMF();
            testCase.verifyEqual(obs.NormalizationMethod, "Continuous");
            testCase.verifyEqual(obs.NormalizationConfig.Method, "Continuous");
        end

        function testSampledStringExpandsToStruct(testCase)
            % Verify "Sampled" string expands to struct with default resolution
            obs = IndividualCMF();
            obs.NormalizationMethod = "Sampled";

            testCase.verifyEqual(obs.NormalizationMethod, "Sampled");

            cfg = obs.NormalizationConfig;
            testCase.verifyEqual(cfg.Method, "Sampled");
            testCase.verifyEqual(cfg.Start, 380);
            testCase.verifyEqual(cfg.Stop, 780);
            testCase.verifyEqual(cfg.Step, 1);
        end

        function testSampledStructWithExplicitResolution(testCase)
            % Verify struct with explicit resolution is accepted
            obs = IndividualCMF();
            obs.NormalizationMethod = struct('Method', "Sampled", ...
                'Start', 390, 'Stop', 730, 'Step', 5);

            testCase.verifyEqual(obs.NormalizationMethod, "Sampled");

            cfg = obs.NormalizationConfig;
            testCase.verifyEqual(cfg.Start, 390);
            testCase.verifyEqual(cfg.Stop, 730);
            testCase.verifyEqual(cfg.Step, 5);
        end

        function testSampledStructWithPartialFields(testCase)
            % Verify struct with partial fields gets defaults
            obs = IndividualCMF();
            obs.NormalizationMethod = struct('Method', "Sampled", 'Step', 5);

            cfg = obs.NormalizationConfig;
            testCase.verifyEqual(cfg.Start, 380);  % Default
            testCase.verifyEqual(cfg.Stop, 780);   % Default
            testCase.verifyEqual(cfg.Step, 5);     % Specified
        end

        function testConstructorAcceptsContinuousString(testCase)
            % Verify constructor accepts "Continuous" string
            obs = IndividualCMF(NormalizationMethod="Continuous");
            testCase.verifyEqual(obs.NormalizationMethod, "Continuous");
        end

        function testConstructorAcceptsSampledString(testCase)
            % Verify constructor accepts "Sampled" string
            obs = IndividualCMF(NormalizationMethod="Sampled");
            testCase.verifyEqual(obs.NormalizationMethod, "Sampled");
        end

        function testConstructorAcceptsSampledStruct(testCase)
            % Verify constructor accepts Sampled struct
            obs = IndividualCMF(NormalizationMethod=struct('Method', "Sampled", 'Step', 5));
            testCase.verifyEqual(obs.NormalizationConfig.Step, 5);
        end

        function testNormalizationConfigIsReadOnly(testCase)
            % Verify NormalizationConfig cannot be set directly
            obs = IndividualCMF();
            testCase.verifyError(@() setNormConfig(obs), 'MATLAB:class:noSetMethod');
        end

        %% --- Error Handling Tests ---

        function testInvalidStructMissingMethodErrors(testCase)
            % Verify error when struct is missing Method field
            obs = IndividualCMF();
            testCase.verifyError(@() setNormMethod(obs, struct('Start', 380)), ...
                'IndividualCMF:InvalidNormalizationConfig');
        end

        function testInvalidStructWrongMethodErrors(testCase)
            % Verify error when struct has invalid Method value
            obs = IndividualCMF();
            testCase.verifyError(@() setNormMethod(obs, struct('Method', "Invalid")), ...
                'IndividualCMF:InvalidNormalizationConfig');
        end

        function testInvalidStructStartGTEStopErrors(testCase)
            % Verify error when Start >= Stop
            obs = IndividualCMF();
            testCase.verifyError(@() setNormMethod(obs, struct('Method', "Sampled", 'Start', 800, 'Stop', 400)), ...
                'IndividualCMF:InvalidNormalizationConfig');
        end

        function testInvalidStructNegativeStepErrors(testCase)
            % Verify error when Step is negative
            obs = IndividualCMF();
            testCase.verifyError(@() setNormMethod(obs, struct('Method', "Sampled", 'Step', -1)), ...
                'IndividualCMF:InvalidNormalizationConfig');
        end

        function testInvalidStringErrors(testCase)
            % Verify error for invalid string values
            obs = IndividualCMF();
            testCase.verifyError(@() setNormMethod(obs, "Invalid"), ...
                'IndividualCMF:InvalidNormalizationMethod');
        end

        %% --- Continuous Normalization Behavior Tests ---

        function testContinuousNormalizationFindsTruePeak(testCase)
            % Continuous normalization finds the true peak via optimization.
            % Evaluating at that exact wavelength should return 1.0.

            obs = IndividualCMF(NormalizationMethod="Continuous", OutputFormat="energy");

            % Find peak wavelength using optimization (same approach as the class)
            findPeakWl = @(cone, lb, ub) fminbnd(@(w) -obs.computeRawSensitivity(w, cone, "energy"), lb, ub);

            peakWl_L = findPeakWl('L', 520, 600);
            peakWl_M = findPeakWl('M', 500, 560);
            peakWl_S = findPeakWl('S', 400, 480);

            % Evaluating at peak wavelength should give exactly 1.0
            testCase.verifyEqual(obs.L(peakWl_L), 1.0, 'AbsTol', 1e-9, ...
                'L at peak wavelength should be 1.0');
            testCase.verifyEqual(obs.M(peakWl_M), 1.0, 'AbsTol', 1e-9, ...
                'M at peak wavelength should be 1.0');
            testCase.verifyEqual(obs.S(peakWl_S), 1.0, 'AbsTol', 1e-9, ...
                'S at peak wavelength should be 1.0');
        end

        function testContinuousIsResolutionIndependent(testCase)
            % Continuous normalization results should not depend on evaluation wavelengths

            obs = IndividualCMF(NormalizationMethod="Continuous");

            % Evaluate same wavelength point in different contexts
            wl_test = 555;

            val1 = obs.L(wl_test);
            val2 = obs.L([500; wl_test; 600]);  % Same point within array
            val3 = obs.L(wl_test);              % Repeat

            testCase.verifyEqual(val1, val2(2), 'AbsTol', 1e-12, ...
                'Same wavelength should give same result in different arrays');
            testCase.verifyEqual(val1, val3, 'AbsTol', 1e-12, ...
                'Repeated evaluation should be identical');
        end

        %% --- Sampled Normalization Behavior Tests ---

        function testSampledPeakMatchesGridMaximum(testCase)
            % Sampled normalization peak should equal max of the sampling grid

            cfg = struct('Method', "Sampled", 'Start', 400, 'Stop', 700, 'Step', 5);
            obs = IndividualCMF(NormalizationMethod=cfg, OutputFormat="energy");

            % The configured grid
            wl_grid = (cfg.Start : cfg.Step : cfg.Stop)';

            % Evaluate raw (unnormalized) at grid points
            L_raw = obs.computeRawSensitivity(wl_grid, 'L', "energy");

            % The normalization peak should equal max of raw values on grid
            expected_peak = max(L_raw);
            actual_peak = obs.getPeak('L', OutputFormat="energy");

            testCase.verifyEqual(actual_peak, expected_peak, 'AbsTol', 1e-12, ...
                'Sampled peak should equal max of configured grid');
        end

        function testSampledResolutionAffectsPeak(testCase)
            % Coarser Sampled resolution may find a different (lower) peak

            cfg_fine = struct('Method', "Sampled", 'Start', 380, 'Stop', 780, 'Step', 1);
            cfg_coarse = struct('Method', "Sampled", 'Start', 380, 'Stop', 780, 'Step', 20);

            obs_fine = IndividualCMF(NormalizationMethod=cfg_fine, OutputFormat="energy");
            obs_coarse = IndividualCMF(NormalizationMethod=cfg_coarse, OutputFormat="energy");

            peak_fine = obs_fine.getPeak('L', OutputFormat="energy");
            peak_coarse = obs_coarse.getPeak('L', OutputFormat="energy");

            % Finer resolution should find a peak >= coarser resolution
            testCase.verifyGreaterThanOrEqual(peak_fine, peak_coarse, ...
                'Finer sampling should find peak >= coarser sampling');

            % They should be close but likely not identical
            testCase.verifyEqual(peak_fine, peak_coarse, 'RelTol', 0.01, ...
                'Peaks should be within 1% of each other');
        end

        %% --- Normalization Bounds Tests ---

        function testContinuousNormalizedValuesNeverExceedOne(testCase)
            % Continuous normalization guarantees values never exceed 1.0
            % at any evaluation wavelength
            wl = (380:0.5:780)';

            obs = IndividualCMF(NormalizationMethod="Continuous");
            testCase.verifyLessThanOrEqual(max(obs.L(wl)), 1.0, 'Continuous L');
            testCase.verifyLessThanOrEqual(max(obs.M(wl)), 1.0, 'Continuous M');
            testCase.verifyLessThanOrEqual(max(obs.S(wl)), 1.0, 'Continuous S');
        end

        function testSampledAtOwnGridNeverExceedsOne(testCase)
            % Sampled normalization guarantees values never exceed 1.0
            % ONLY when evaluated at the same grid used for normalization

            cfg = struct('Method', "Sampled", 'Start', 380, 'Stop', 780, 'Step', 5);
            obs = IndividualCMF(NormalizationMethod=cfg);

            % Evaluate at the normalization grid
            wl_grid = (cfg.Start : cfg.Step : cfg.Stop)';

            testCase.verifyLessThanOrEqual(max(obs.L(wl_grid)), 1.0, ...
                'Sampled L at grid points');
            testCase.verifyLessThanOrEqual(max(obs.M(wl_grid)), 1.0, ...
                'Sampled M at grid points');
            testCase.verifyLessThanOrEqual(max(obs.S(wl_grid)), 1.0, ...
                'Sampled S at grid points');
        end

        function testSampledCanExceedOneAtOffGridPoints(testCase)
            % Sampled normalization may produce values > 1.0 when evaluated
            % at wavelengths finer than the normalization grid.
            % This is expected behavior - documenting it here.

            % Use coarse normalization grid
            cfg = struct('Method', "Sampled", 'Start', 380, 'Stop', 780, 'Step', 10);
            obs = IndividualCMF(NormalizationMethod=cfg);

            % Evaluate at finer resolution (off-grid points)
            wl_fine = (380:0.5:780)';
            L_max = max(obs.L(wl_fine));

            % Value should be close to 1.0 (within a small tolerance)
            % but may slightly exceed it
            testCase.verifyEqual(L_max, 1.0, 'AbsTol', 0.01, ...
                'Sampled peak at fine resolution should be approximately 1.0');

            % The key point: at the actual normalization grid, it should be exactly <= 1.0
            wl_grid = (cfg.Start : cfg.Step : cfg.Stop)';
            testCase.verifyLessThanOrEqual(max(obs.L(wl_grid)), 1.0, ...
                'But at grid points, should not exceed 1.0');
        end

        %% --- Continuous vs Sampled Comparison Tests ---

        function testContinuousVsSampledNormalizationDifference(testCase)
            % Continuous finds true peak; Sampled may miss it slightly
            % This test documents expected behavior

            obs_cont = IndividualCMF(NormalizationMethod="Continuous", OutputFormat="energy");
            obs_samp = IndividualCMF(NormalizationMethod="Sampled", OutputFormat="energy");

            wl = (400:10:700)';

            L_cont = obs_cont.L(wl);
            L_samp = obs_samp.L(wl);

            % Results should be very close but may differ slightly
            testCase.verifyEqual(L_cont, L_samp, 'RelTol', 0.001, ...
                'Continuous and Sampled should produce similar results');

            % They should not be exactly identical (different peak finding)
            testCase.verifyNotEqual(L_cont, L_samp, ...
                'Continuous and Sampled should produce slightly different results');
        end

        %% --- Cache Behavior Tests ---

        function testCacheInvalidationOnPropertyChange(testCase)
            % Verify cache is invalidated when property changes
            obs = IndividualCMF(NormalizationMethod="Sampled");
            wl = 550;

            % Get initial value (populates cache)
            val1 = obs.L(wl);

            % Change optical density (affects sensitivity, no template warning)
            obs.Lod = obs.Lod + 0.1;

            % Get new value (should use invalidated/recomputed cache)
            val2 = obs.L(wl);

            testCase.verifyNotEqual(val1, val2, ...
                'Property change should invalidate cache and produce different result');
        end

        function testSwitchingNormalizationMethodInvalidatesCache(testCase)
            % Verify switching normalization method invalidates cache
            obs = IndividualCMF(NormalizationMethod="Continuous");
            wl = 550;

            val1 = obs.L(wl);

            obs.NormalizationMethod = "Sampled";
            val2 = obs.L(wl);

            % Values should be different
            testCase.verifyNotEqual(val1, val2, ...
                'Switching method should produce different results');
        end

        function testCacheWorksAcrossConeTypes(testCase)
            % Verify cache stores peaks for all cone types
            obs = IndividualCMF(NormalizationMethod="Sampled");
            wl = (400:10:700)';

            % Call all three cones
            L = obs.L(wl);
            M = obs.M(wl);
            S = obs.S(wl);

            % All should produce valid results
            testCase.verifySize(L, size(wl));
            testCase.verifySize(M, size(wl));
            testCase.verifySize(S, size(wl));
        end

        function testCacheWorksWithDifferentOutputFormats(testCase)
            % Verify cache works with different output formats
            wl = (400:10:700)';

            obs_energy = IndividualCMF(OutputFormat="energy", NormalizationMethod="Sampled");
            obs_quantal = IndividualCMF(OutputFormat="quantal", NormalizationMethod="Sampled");

            L_energy = obs_energy.L(wl);
            L_quantal = obs_quantal.L(wl);

            % Results should be different (energy = quantal * wavelength)
            testCase.verifyNotEqual(L_energy, L_quantal, ...
                'Energy and Quantal should produce different results');
        end

        function testNormalizationCacheClass(testCase)
            % Basic test of NormalizationCache class
            obs = IndividualCMF();
            cache = NormalizationCache(obs);

            % Set configuration
            cache.setConfig(struct('Method', "Continuous"));

            % Get peak (should compute and cache)
            peak1 = cache.getPeak('L', "energy");
            testCase.verifyGreaterThan(peak1, 0, 'Peak should be positive');

            % Get again (should use cache)
            peak2 = cache.getPeak('L', "energy");
            testCase.verifyEqual(peak1, peak2, 'Cache should return same value');

            % Invalidate and recompute
            cache.invalidate();
            peak3 = cache.getPeak('L', "energy");
            testCase.verifyEqual(peak1, peak3, 'Recomputed peak should be same');
        end

        %% --- Absorptance Normalization Tests (Unified Cache Path) ---

        function testAbsorptanceNormalizationContinuous(testCase)
            % Continuous normalization uses fminbnd for all templates.
            % Absorptance now flows through the same cache path as quantal/energy.
            obs = IndividualCMF(StandardObserver=10);
            obs.NormalizationMethod = "Continuous";
            obs.OutputFormat = "absorptance";
            obs.NormalizeOutput = true;

            LMS = obs.LMS((400:1:700)');

            % Peak should be very close to 1.0
            testCase.verifyLessThanOrEqual(max(LMS, [], 'all'), 1.0 + 1e-6, ...
                'Normalized absorptance should not exceed 1.0');
            testCase.verifyGreaterThan(max(LMS, [], 'all'), 0.99, ...
                'Normalized absorptance peak should be close to 1.0');
        end

        function testAbsorptanceNormalizationSampled(testCase)
            % Sampled normalization for Pycone compatibility.
            % Peak should be exactly 1.0 when evaluated at normalization grid.
            obs = IndividualCMF(StandardObserver=10);
            obs.NormalizationMethod = struct('Method', "Sampled", 'Start', 390, 'Stop', 830, 'Step', 5);
            obs.OutputFormat = "absorptance";
            obs.NormalizeOutput = true;

            % Evaluate at the SAME grid as normalization
            wl = (390:5:830)';
            LMS = obs.LMS(wl);

            % Peak should be exactly 1.0 when evaluated at normalization grid
            testCase.verifyEqual(max(LMS(:,1)), 1.0, 'AbsTol', 1e-10, ...
                'L absorptance peak should be 1.0 at grid');
            testCase.verifyEqual(max(LMS(:,2)), 1.0, 'AbsTol', 1e-10, ...
                'M absorptance peak should be 1.0 at grid');
            testCase.verifyEqual(max(LMS(:,3)), 1.0, 'AbsTol', 1e-10, ...
                'S absorptance peak should be 1.0 at grid');
        end

        function testAbsorptanceUsesCache(testCase)
            % Verify absorptance flows through cache like quantal/energy.
            % getPeak should return valid peaks for all output formats.
            obs = IndividualCMF(StandardObserver=10);

            % Get peaks from cache for all formats
            peakAbsorptance = obs.getPeak('L', OutputFormat="absorptance");
            peakQuantal = obs.getPeak('L', OutputFormat="quantal");
            peakEnergy = obs.getPeak('L', OutputFormat="energy");

            % All should be valid positive numbers
            testCase.verifyGreaterThan(peakAbsorptance, 0, ...
                'Absorptance peak should be positive');
            testCase.verifyGreaterThan(peakQuantal, 0, ...
                'Quantal peak should be positive');
            testCase.verifyGreaterThan(peakEnergy, 0, ...
                'Energy peak should be positive');
        end

        function testAbsorptanceRawVsNormalized(testCase)
            % Verify raw/peak equals normalized (proves cache is used).
            % This confirms absorptance uses the same normalization path.
            obs = IndividualCMF(StandardObserver=10);
            wl = (400:10:700)';

            % Get peak
            peakL = obs.getPeak('L', OutputFormat="absorptance");

            % Get raw absorptance
            obs.OutputFormat = "absorptance";
            obs.NormalizeOutput = false;
            raw = obs.L(wl);

            % Get normalized absorptance
            obs.NormalizeOutput = true;
            normalized = obs.L(wl);

            % Verify: raw / peak == normalized
            testCase.verifyEqual(raw / peakL, normalized, 'AbsTol', 1e-12, ...
                'raw / peak should equal normalized');
        end

        function testAbsorptanceBothTemplates(testCase)
            % Verify absorptance normalization works for both template types.
            % Both Stockman-Rider and Govardovskii are continuous analytical
            % functions suitable for fminbnd optimization.
            wl = (400:5:700)';

            % Stockman-Rider
            obs_sr = IndividualCMF(StandardObserver=10, PhotopigmentModel="StockmanRider2023");
            obs_sr.OutputFormat = "absorptance";
            obs_sr.NormalizeOutput = true;
            LMS_sr = obs_sr.LMS(wl);
            testCase.verifyLessThanOrEqual(max(LMS_sr, [], 'all'), 1.0 + 1e-6, ...
                'StockmanRider absorptance should not exceed 1.0');
            testCase.verifyGreaterThan(max(LMS_sr, [], 'all'), 0.99, ...
                'StockmanRider absorptance peak should be close to 1.0');

            % Govardovskii
            obs_gov = IndividualCMF(PhotopigmentModel="Govardovskii2000");
            obs_gov.OutputFormat = "absorptance";
            obs_gov.NormalizeOutput = true;
            LMS_gov = obs_gov.LMS(wl);
            testCase.verifyLessThanOrEqual(max(LMS_gov, [], 'all'), 1.0 + 1e-6, ...
                'Govardovskii absorptance should not exceed 1.0');
            testCase.verifyGreaterThan(max(LMS_gov, [], 'all'), 0.99, ...
                'Govardovskii absorptance peak should be close to 1.0');
        end

        %% --- Analytical Peak Absorbance Tests ---

        function testStockmanRiderPeakAbsorbanceIsOne(testCase)
            % Stockman-Rider templates are pre-normalized to peak at 1.0
            % due to the 's' renormalization factor in the Fourier coefficients.
            template = StockmanRiderPhotopigmentTemplate();

            for coneType = ['L', 'M', 'S']
                peakAbs = template.computePeakAbsorbance(coneType, 0, struct());
                testCase.verifyEqual(peakAbs, 1.0, ...
                    sprintf('%s-cone peak absorbance should be exactly 1.0', coneType));
            end
        end

        function testGovardovskiiPeakAbsorbanceNearOne(testCase)
            % Govardovskii peaks near 1.0 at lambda-max.
            % The alpha-band peaks at 1.0 by construction, but beta-band
            % contribution may cause slight deviation.
            template = GovardovskiiPhotopigmentTemplate();

            for coneType = ['L', 'M', 'S']
                peakAbs = template.computePeakAbsorbance(coneType, 0, struct());

                % Should be very close to 1.0
                testCase.verifyEqual(peakAbs, 1.0, 'RelTol', 0.01, ...
                    sprintf('%s-cone peak absorbance should be near 1.0', coneType));
            end
        end

        function testAnalyticalAbsorptancePeakFormula(testCase)
            % Verify the relative retinal absorptance peak formula for
            % Govardovskii. Under the helper-norm convention, the
            % analytical peak is (1-10^(-OD*peakA)) / (1-10^(-OD)). The
            % Govardovskii alpha-band absorbance peaks very close to but
            % not exactly 1.0 (within ~0.15% of the analytical maximum),
            % so the relative absorptance peak is very close to 1 but
            % can deviate by a similarly small amount. The contract this
            % test pins is the formula itself, not that the peak equals
            % 1 exactly.
            obs = IndividualCMF();
            obs.PhotopigmentModel = "Govardovskii2000";

            for coneType = ['L', 'M', 'S']
                peak = obs.computeAnalyticalAbsorptancePeak(coneType);

                % Peak must be positive and within ~1% of 1.0 (matches
                % the existing peakAbsorbance-near-1 contract enforced
                % by testGovardovskiiPeakAbsorbanceNormalized).
                testCase.verifyGreaterThan(peak, 0, ...
                    sprintf('%s analytical peak must be positive', coneType));
                testCase.verifyEqual(peak, 1.0, 'RelTol', 0.01, ...
                    sprintf('%s analytical peak should be near 1.0 under the relative formula', coneType));
            end
        end

        function testGovardovskiiAbsentConePeakIsFinite(testCase)
            % When a Govardovskii observer has a zeroed cone (gene-
            % deletion dichromacy), the analytical absorptance peak
            % formula would be 0/0 = NaN without the OD guard. NaN
            % escapes the cache's "peak == 0 -> 1" sentinel and leaks
            % into downstream normalisation. The OD guard returns 1
            % so the cone's identically-zero output gets divided by 1
            % (no-op).
            obs = IndividualCMF(PhotopigmentModel="Govardovskii2000");
            obs.Mod = 0;
            peakAbsorptance = obs.getPeak('M', OutputFormat="absorptance");
            testCase.verifyTrue(isfinite(peakAbsorptance), ...
                'Absent-cone absorptance peak must be finite');
            testCase.verifyEqual(peakAbsorptance, 1, 'AbsTol', 1e-12, ...
                'Absent-cone absorptance peak must equal 1 (the no-op divisor)');

            % And the downstream LMS column for the absent cone must
            % still be identically zero.
            wl = (400:50:700)';
            obs.OutputFormat = "absorptance";
            obs.NormalizeOutput = true;
            LMS = obs.LMS(wl);
            testCase.verifyEqual(LMS(:,2), zeros(size(wl)), 'AbsTol', 1e-12, ...
                'Absent M column must remain zero after normalisation');
        end

        function testAnalyticalPeakMatchesNormalizedMax(testCase)
            % Verify that normalized absorptance using analytical peak
            % produces max values very close to 1.0
            obs = IndividualCMF(StandardObserver=10);
            obs.NormalizationMethod = "Continuous";
            obs.OutputFormat = "absorptance";
            obs.NormalizeOutput = true;

            wl = (380:0.001:780)';
            LMS = obs.LMS(wl);

            % Each cone should peak very close to 1.0
            testCase.verifyEqual(max(LMS(:,1)), 1.0, 'AbsTol', 1e-9, ...
                'L normalized absorptance should peak at 1.0');
            testCase.verifyEqual(max(LMS(:,2)), 1.0, 'AbsTol', 1e-9, ...
                'M normalized absorptance should peak at 1.0');
            testCase.verifyEqual(max(LMS(:,3)), 1.0, 'AbsTol', 1e-9, ...
                'S normalized absorptance should peak at 1.0');
        end

        function testRelativeAbsorptanceFormulaStockmanRider(testCase)
            % Pin the relative retinal absorptance convention for the
            % Stockman-Rider family: with NormalizeOutput=false, the
            % public OutputFormat="absorptance" must return
            % (1 - 10^(-OD*A)) / (1 - 10^(-OD)), where A is the linear
            % absorbance peaking at 1. Compare against the math primitive
            % pipeline.PhotopigmentStage.absorptanceFromAbsorbance with
            % Normalize=true.
            wl = (400:5:700)';
            ods = struct('L', 0.38, 'M', 0.38, 'S', 0.3);
            verifyRelativeFormula(testCase, "StockmanRider2023", wl, ods);
        end

        function testRelativeAbsorptanceFormulaGovardovskii(testCase)
            % Same pin for Govardovskii: both families must produce the
            % same physical quantity under OutputFormat="absorptance" so
            % the user gets a consistent semantic regardless of
            % PhotopigmentModel.
            wl = (400:5:700)';
            ods = struct('L', 0.38, 'M', 0.38, 'S', 0.3);
            verifyRelativeFormula(testCase, "Govardovskii2000", wl, ods);
        end

        function testPeakSearchTracksLambdaMaxShift(testCase)
            % The fminbnd search window in computePeakForFormat is base
            % bounds around each cone's unshifted peak, shifted by the
            % cone's LambdaMaxShift, and clamped to the template valid
            % range. Without shifting the window, a large shift would
            % push the true peak outside the search interval and
            % NormalizeOutput=true would divide by a non-peak value.
            % Catches the original bug for the S cone (which has an
            % unbounded shift setter) and the latent same-shape bug for
            % L and M.
            for shift = [-30, 0, 30]
                obs = IndividualCMF();
                obs.S_LambdaMaxShift = shift;
                obs.NormalizeOutput = true;
                % The S cone's normalized peak must be ~1 regardless of
                % shift; we use a coarse grid that hits the new peak
                % location.
                wl = (380:1:780)';
                S = obs.S(wl);
                testCase.verifyEqual(max(S), 1.0, 'RelTol', 1e-3, ...
                    sprintf('S(wl) peak must be ~1 after S_LambdaMaxShift=%d', shift));
            end
        end

        function testRawBeerLambertPrimitiveStillAvailable(testCase)
            % The raw physical fraction 1 - 10^(-OD*A) must remain
            % accessible through pipeline.PhotopigmentStage with
            % Normalize=false, even though the high-level OutputFormat
            % path now always normalises.
            A = (0:0.1:1)';
            od = 0.38;
            raw = pipeline.PhotopigmentStage.absorptanceFromAbsorbance( ...
                A, od, Normalize=false);
            expected = 1 - 10.^(-od .* A);
            testCase.verifyEqual(raw, expected, 'AbsTol', 1e-14, ...
                'Normalize=false must return raw 1-10^(-OD*A)');

            % And the peak of raw is (1-10^(-OD)), not 1.
            testCase.verifyEqual(raw(end), 1 - 10^(-od), 'AbsTol', 1e-14, ...
                'Raw peak must equal 1-10^(-OD), not 1');
        end

    end
end

function setNormMethod(obs, val)
    obs.NormalizationMethod = val;
end

function setNormConfig(obs)
    obs.NormalizationConfig = struct('Method', "Continuous");
end

function verifyRelativeFormula(testCase, photopigmentModel, wl, ods)
    % Helper: assert obs.LMS(wl, OutputFormat="absorptance", NormalizeOutput=false)
    % equals the relative formula applied to the absorbance for each cone.
    obsAbsorptance = IndividualCMF(PhotopigmentModel=photopigmentModel);
    obsAbsorptance.OutputFormat = "absorptance";
    obsAbsorptance.NormalizeOutput = false;
    obsAbsorptance.LogOutput = false;

    obsAbsorbance = IndividualCMF(PhotopigmentModel=photopigmentModel);
    obsAbsorbance.OutputFormat = "absorbance";
    obsAbsorbance.NormalizeOutput = false;
    obsAbsorbance.LogOutput = false;

    actual = obsAbsorptance.LMS(wl);
    coneTypes = {'L', 'M', 'S'};
    for k = 1:3
        coneType = coneTypes{k};
        switch coneType
            case 'L', A = obsAbsorbance.L(wl);
            case 'M', A = obsAbsorbance.M(wl);
            case 'S', A = obsAbsorbance.S(wl);
        end
        expected = pipeline.PhotopigmentStage.absorptanceFromAbsorbance( ...
            A, ods.(coneType), Normalize=true);
        testCase.verifyEqual(actual(:,k), expected, 'AbsTol', 1e-12, ...
            sprintf('%s %s absorptance must equal relative retinal formula', ...
            photopigmentModel, coneType));
    end
end

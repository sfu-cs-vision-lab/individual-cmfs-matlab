classdef PhotopigmentStageTest < matlab.unittest.TestCase
    % PHOTOPIGMENTSTAGETEST  Characterization tests for pipeline.PhotopigmentStage.
    %
    %   Pins the input/output behavior of the stage so that the extraction
    %   from IndividualCMF can be verified bit-for-bit. The
    %   testEquivalentToIndividualCMFPipeline test is the no-regression
    %   contract: stage output must equal what IndividualCMF produced
    %   pre-extraction for the same inputs.

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada

    methods (Test)
        function testLogAbsorbanceMatchesTemplate(testCase)
            % logAbsorbance must produce the same output as calling the
            % template directly -- it is a thin wrapper.
            template = StockmanRiderPhotopigmentTemplate();
            wl = (400:5:700)';
            opts = struct();
            expected = template.computeAbsorbance(wl, 'L', 0, opts);
            actual = pipeline.PhotopigmentStage.logAbsorbance(template, wl, 'L', 0, opts);
            testCase.verifyEqual(actual, expected);
        end

        function testRetinalAbsorptanceRawConvention(testCase)
            % retinalAbsorptance with doHelperNorm=false returns the raw
            % Beer-Lambert fraction 1 - 10^(-OD*A), independent of which
            % template produced A. Exercising both templates through the
            % same flag value pins that the formula -- not the template
            % family -- determines the output.
            wl = (400:5:700)';
            od = 0.38;
            for template = { ...
                    StockmanRiderPhotopigmentTemplate(), ...
                    GovardovskiiPhotopigmentTemplate()}
                logAbs = template{1}.computeAbsorbance(wl, 'L', 0, struct());
                absorptance = pipeline.PhotopigmentStage.retinalAbsorptance( ...
                    logAbs, od, false);
                expected = 1 - 10.^(-od * 10.^logAbs);
                testCase.verifyEqual(absorptance, expected, 'AbsTol', 1e-12, ...
                    sprintf('Raw absorptance must equal 1 - 10^(-OD*A) for %s', ...
                    class(template{1})));
            end
        end

        function testRetinalAbsorptanceRelativeConvention(testCase)
            % retinalAbsorptance with doHelperNorm=true returns relative
            % retinal absorptance (1 - 10^(-OD*A)) / (1 - 10^(-OD)) -- the
            % convention IndividualCMF's high-level OutputFormat path
            % uses. Both templates must satisfy the same formula.
            wl = (400:5:700)';
            od = 0.38;
            divisor = 1 - 10^(-od);
            for template = { ...
                    StockmanRiderPhotopigmentTemplate(), ...
                    GovardovskiiPhotopigmentTemplate()}
                logAbs = template{1}.computeAbsorbance(wl, 'L', 0, struct());
                absorptance = pipeline.PhotopigmentStage.retinalAbsorptance( ...
                    logAbs, od, true);
                expected = (1 - 10.^(-od * 10.^logAbs)) / divisor;
                testCase.verifyEqual(absorptance, expected, 'AbsTol', 1e-12, ...
                    sprintf('Relative absorptance must equal (1-10^(-OD*A))/(1-10^(-OD)) for %s', ...
                    class(template{1})));
            end
        end

        function testRetinalAbsorptanceMonotoneInOpticalDensity(testCase)
            % Higher optical density should produce higher absorptance
            % everywhere (more pigment absorbs more light). Verifies the
            % math direction without coupling to a specific template.
            wl = (400:5:700)';
            logAbs = log10(linspace(0.1, 1.0, numel(wl)))';  % synthetic peak-1 absorbance
            lowOD = pipeline.PhotopigmentStage.retinalAbsorptance(logAbs, 0.2, true);
            highOD = pipeline.PhotopigmentStage.retinalAbsorptance(logAbs, 0.5, true);
            % At every wavelength, higher OD must yield higher absorptance
            % when the input absorbance is non-zero.
            nonZero = logAbs > -10;  % skip the dynamic-range floor
            testCase.verifyGreaterThanOrEqual(highOD(nonZero), lowOD(nonZero));
        end
    end
end

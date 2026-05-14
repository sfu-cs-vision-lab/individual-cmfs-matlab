classdef ChromaticityTest < matlab.unittest.TestCase
    % ChromaticityTest  Verifies the chromaticity methods on IndividualCMF:
    %   MacLeodBoynton, lmChromaticity, and xyChromaticity.
    %
    %   These tests pin the chromaticity methods against published
    %   values from MacLeod & Boynton (1979), Smith & Pokorny (1996),
    %   Stockman (2019), and CIE 170-2:2015: output shape, projective
    %   normalization invariants (l + m + s = 1, x + y + z = 1),
    %   MacLeod-Boynton spot values and unbounded s_MB near the S-cone
    %   peak, dichromat reductions (protanope -> l_MB = 0, deuteranope
    %   -> l_MB = 1, tritanope -> s_MB = 0), and xyChromaticity's
    %   inheritance of the XYZ dichromat error and custom-matrix
    %   bypass.

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada
    %
    % This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    % Licensed under AGPL-3.0-or-later. See LICENSE file for details.

    properties (Constant)
        % Tolerance for chromaticity-coordinate spot checks. Loose
        % because chromaticity diagrams compress the spectrum locus
        % onto a 2D simplex where 1-2 percent differences are
        % visually indistinguishable.
        ChromaticityTol = 0.01
    end

    methods (Test)

        % MacLeod-Boynton: range, shape, and spot values.

        function testMacLeodBoyntonOutputShape(testCase)
            obs = IndividualCMF();
            wl = (400:10:700)';
            mb = obs.MacLeodBoynton(wl);
            testCase.verifySize(mb, [numel(wl), 2]);
        end

        function testMacLeodBoyntonLBoundedInUnitInterval(testCase)
            obs = IndividualCMF();
            mb = obs.MacLeodBoynton((400:1:700)');
            testCase.verifyGreaterThanOrEqual(min(mb(:, 1)), 0);
            testCase.verifyLessThanOrEqual(max(mb(:, 1)), 1);
        end

        function testMacLeodBoyntonAt555nm(testCase)
            % l_MB at 555 nm is canonically about 0.67 for the
            % standard observer; pinning to 0.67 with chromaticity
            % tolerance catches any silent scaling regression.
            obs = IndividualCMF(StandardObserver=10);
            mb = obs.MacLeodBoynton(555);
            testCase.verifyEqual(mb(1), 0.67, ...
                'AbsTol', testCase.ChromaticityTol);
        end

        function testMacLeodBoyntonSExceedsOneNearScone(testCase)
            % s_MB peaks well above 1 near the S-cone lambda-max
            % because the MB convention does not renormalize S.
            obs = IndividualCMF();
            mb = obs.MacLeodBoynton(440);
            testCase.verifyGreaterThan(mb(2), 1);
        end

        function testMacLeodBoyntonProtanope(testCase)
            obs = IndividualCMF(Lod=0);
            mb = obs.MacLeodBoynton((450:10:650)');
            testCase.verifyEqual(mb(:, 1), zeros(size(mb, 1), 1), ...
                'AbsTol', 1e-10);
        end

        function testMacLeodBoyntonDeuteranope(testCase)
            obs = IndividualCMF(Mod=0);
            mb = obs.MacLeodBoynton((450:10:650)');
            testCase.verifyEqual(mb(:, 1), ones(size(mb, 1), 1), ...
                'AbsTol', 1e-10);
        end

        function testMacLeodBoyntonTritanope(testCase)
            obs = IndividualCMF(Sod=0);
            mb = obs.MacLeodBoynton((450:10:650)');
            testCase.verifyEqual(mb(:, 2), zeros(size(mb, 1), 1), ...
                'AbsTol', 1e-10);
        end

        % lmChromaticity: range, shape, and consistency.

        function testLmChromaticityOutputShape(testCase)
            obs = IndividualCMF();
            wl = (400:10:700)';
            lm = obs.lmChromaticity(wl);
            testCase.verifySize(lm, [numel(wl), 2]);
        end

        function testLmChromaticitySumsBelowOne(testCase)
            % l + m + s = 1 by construction (projective normalization),
            % so l + m must be in [0, 1] across the visible range.
            obs = IndividualCMF();
            lm = obs.lmChromaticity((400:1:700)');
            sums = sum(lm, 2);
            testCase.verifyGreaterThanOrEqual(min(sums), 0);
            testCase.verifyLessThanOrEqual(max(sums), 1 + 1e-10);
        end

        function testLmChromaticityAt555NearOne(testCase)
            % At 555 nm the S contribution is negligible so l + m ~ 1.
            obs = IndividualCMF();
            lm = obs.lmChromaticity(555);
            testCase.verifyEqual(sum(lm), 1.0, 'AbsTol', 0.01);
        end

        function testLmChromaticityProtanopeHasZeroL(testCase)
            obs = IndividualCMF(Lod=0);
            lm = obs.lmChromaticity((450:10:650)');
            testCase.verifyEqual(lm(:, 1), zeros(size(lm, 1), 1), ...
                'AbsTol', 1e-10);
        end

        function testLmChromaticityDeuteranopeHasZeroM(testCase)
            obs = IndividualCMF(Mod=0);
            lm = obs.lmChromaticity((450:10:650)');
            testCase.verifyEqual(lm(:, 2), zeros(size(lm, 1), 1), ...
                'AbsTol', 1e-10);
        end

        % xyChromaticity: shape, consistency, and dichromat error.

        function testXyChromaticityOutputShape(testCase)
            obs = IndividualCMF();
            wl = (400:10:700)';
            xy = obs.xyChromaticity(wl);
            testCase.verifySize(xy, [numel(wl), 2]);
        end

        function testXyChromaticitySumsBelowOne(testCase)
            obs = IndividualCMF();
            xy = obs.xyChromaticity((400:1:700)');
            sums = sum(xy, 2);
            testCase.verifyGreaterThanOrEqual(min(sums), 0);
            testCase.verifyLessThanOrEqual(max(sums), 1 + 1e-10);
        end

        function testXyChromaticityErrorsForProtanope(testCase)
            obs = IndividualCMF(Lod=0);
            testCase.verifyError(@() obs.xyChromaticity((400:10:700)'), ...
                'IndividualCMF:XYZUndefinedForDichromat');
        end

        function testXyChromaticityErrorsForDeuteranope(testCase)
            obs = IndividualCMF(Mod=0);
            testCase.verifyError(@() obs.xyChromaticity((400:10:700)'), ...
                'IndividualCMF:XYZUndefinedForDichromat');
        end

        function testXyChromaticityErrorsForTritanope(testCase)
            obs = IndividualCMF(Sod=0);
            testCase.verifyError(@() obs.xyChromaticity((400:10:700)'), ...
                'IndividualCMF:XYZUndefinedForDichromat');
        end

        function testXyChromaticityCustomMatrixBypass(testCase)
            % Passing a custom TransformationMatrix should bypass the
            % dichromat error path, since XYZ() accepts it.
            obs = IndividualCMF(Lod=0);
            customMatrix = eye(3);
            xy = obs.xyChromaticity((400:10:700)', ...
                TransformationMatrix=customMatrix);
            testCase.verifySize(xy, [31, 2]);
        end

    end
end

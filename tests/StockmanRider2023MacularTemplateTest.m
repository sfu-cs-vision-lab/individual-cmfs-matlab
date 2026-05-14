classdef StockmanRider2023MacularTemplateTest < matlab.unittest.TestCase
    % STOCKMANRIDER2023MACULARTEMPLATETEST  Unit tests for the S&R 2023 macular template strategy class.
    %
    %   Tests verify:
    %   - Class metadata (Name, ShortName, inheritance from MacularTemplate).
    %   - Template normalized to 1.0 at 460 nm (the unit-peak convention
    %     that mirrors LensTemplate's unit-peak-at-400-nm contract).
    %   - Zero outside the valid 375-550 nm range.
    %   - Numerical equivalence with the legacy
    %     PreReceptoralFilter.macularTemplate static method (the new
    %     class is the single source of truth; the static method is now
    %     a thin delegating wrapper).

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada
    %
    % This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    % Licensed under AGPL-3.0-or-later. See LICENSE file for details.

    properties (Constant)
        AbsTol = 1e-12
    end

    methods (Test)

        function testNameProperties(testCase)
            t = StockmanRider2023MacularTemplate();
            testCase.verifyEqual(t.Name, "Stockman & Rider (2023) Macular Template");
            testCase.verifyEqual(t.ShortName, "StockmanRider2023");
        end

        function testInheritsFromMacularTemplate(testCase)
            t = StockmanRider2023MacularTemplate();
            testCase.verifyTrue(isa(t, 'MacularTemplate'));
        end

        function testTemplatePeaksAt460nm(testCase)
            % Unit-peak normalization: computeTemplate(460) == 1.0. This is
            % a normalization convention, not a claim about where the
            % curve's maximum is located -- the raw Fourier polynomial
            % actually peaks slightly shortward of 460 nm, but the contract
            % is that the value AT 460 nm equals 1.0. Tolerance is loosened
            % from strict equality because the Stockman & Rider Table 2
            % coefficients are rounded: the raw polynomial lands at
            % 0.34999999993832 (~1.8e-10 below the nominal 0.35 OD), so
            % dividing by 0.35 gives 0.9999999998 rather than exactly 1.0.
            t = StockmanRider2023MacularTemplate();
            value = t.computeTemplate(460);
            testCase.verifyEqual(value, 1.0, 'RelTol', 1e-8);
        end

        function testTemplateZeroBelowValidRange(testCase)
            t = StockmanRider2023MacularTemplate();
            wl = (300:374)';
            template = t.computeTemplate(wl);
            testCase.verifyEqual(template, zeros(size(wl)), 'AbsTol', testCase.AbsTol);
        end

        function testTemplateZeroAboveValidRange(testCase)
            t = StockmanRider2023MacularTemplate();
            wl = (551:700)';
            template = t.computeTemplate(wl);
            testCase.verifyEqual(template, zeros(size(wl)), 'AbsTol', testCase.AbsTol);
        end

        function testTemplateNonNegativeInValidRange(testCase)
            t = StockmanRider2023MacularTemplate();
            wl = (375:550)';
            template = t.computeTemplate(wl);
            testCase.verifyTrue(all(template >= 0), ...
                'Template values should be non-negative');
        end

        function testStaticDelegatorReturnsAbsoluteSpectrum(testCase)
            % PreReceptoralFilter.macularTemplate must still return the
            % absolute spectrum (peak 0.35 OD at 460 nm) for backward
            % compatibility. The new strategy class returns the unit-peak
            % version; the two should differ exactly by the 0.35 factor.
            wl = (375:5:550)';
            t = StockmanRider2023MacularTemplate();
            unitPeak = t.computeTemplate(wl);
            absolute = PreReceptoralFilter.macularTemplate(wl);
            testCase.verifyEqual(absolute, unitPeak * CIE170.STD_2DEG_MACULAR_DENSITY, ...
                'AbsTol', 1e-12);
        end

        function testCoefficientsAccessibleAsConstant(testCase)
            % The Fourier coefficient table is exposed as a public Constant
            % so callers (e.g. parity tests) can verify lengths or values.
            coefs = StockmanRider2023MacularTemplate.MACULAR_COEFFICIENTS;
            testCase.verifyLength(coefs, 24, ...
                'Macular coefficients should have 24 elements');
        end

        function testColumnVectorOutputShape(testCase)
            t = StockmanRider2023MacularTemplate();
            wl = (375:550)';
            template = t.computeTemplate(wl);
            testCase.verifySize(template, size(wl));
        end

    end
end

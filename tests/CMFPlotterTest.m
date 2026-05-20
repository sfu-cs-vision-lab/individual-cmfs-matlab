classdef CMFPlotterTest < matlab.unittest.TestCase
    % CMFPLOTTERTEST  Tests for the CMFPlotter visualization class.

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
        Plotter
        Observer1
        Observer2
    end

    properties(TestParameter)
        % First N bytes that uniquely identify each format. A driver-string
        % swap (e.g. -dpdf -> -dsvg) writes valid content under a misleading
        % extension; only a magic-byte check catches it.
        ExportFormat = struct( ...
            'pdf',  struct('fmt', "pdf",  'magic', uint8('%PDF')), ...
            'eps',  struct('fmt', "eps",  'magic', uint8('%!PS')), ...
            'svg',  struct('fmt', "svg",  'magic', uint8('<?xml')), ...
            'png',  struct('fmt', "png",  'magic', uint8([137 80 78 71])), ...
            'tiff', struct('fmt', "tiff", 'magic', uint8([73 73 42 0])))
    end

    methods(TestMethodSetup)
        function createFixtures(testCase)
            % Initialize observers
            testCase.Observer1 = IndividualCMF(StandardObserver=2);
            testCase.Observer2 = IndividualCMF(Age=70, FieldSize=10);

            % Initialize Plotter (hidden to prevent flashing windows)
            testCase.Plotter = CMFPlotter(3, 3, Visible=false);
        end
    end

    methods(TestMethodTeardown)
        function closeFigure(testCase)
            % Clean up the figure after every test to prevent memory leaks
            if isvalid(testCase.Plotter.Figure)
                close(testCase.Plotter.Figure);
            end
        end
    end

    methods(Test)

        function testPlotLMS(testCase)
            titleStr = "Test LMS Plot";

            p = testCase.Plotter.plotLMS(testCase.Observer1, Title=titleStr);
            ax = p(1).Parent;

            testCase.verifyNotEmpty(ax, 'Axes handle should not be empty.');
            testCase.verifyNotEmpty(p, 'Line handles should not be empty.');
            testCase.verifyEqual(string(ax.Title.String), titleStr, 'Title should match.');
            testCase.verifyNumElements(p, 3, 'Should return 3 line handles for LMS.');
            testCase.verifyClass(p, 'matlab.graphics.chart.primitive.Line');

            lines = findobj(ax, 'Type', 'Line');
            testCase.verifyNumElements(lines, 3, 'Should plot 3 lines for LMS.');
        end

        function testCompareLMS(testCase)
            titleStr = "Test LMS Comparison";
            p = testCase.Plotter.compareLMS(testCase.Observer1, testCase.Observer2, Title=titleStr);
            ax = p(1).Parent;

            testCase.verifyNotEmpty(ax);
            testCase.verifyNotEmpty(p);
            testCase.verifyEqual(string(ax.Title.String), titleStr);
            testCase.verifyNumElements(p, 6, 'Should return 6 line handles for Comparison.');

            lines = findobj(ax, 'Type', 'Line');
            testCase.verifyNumElements(lines, 6, 'Should plot 6 lines for Comparison.');
        end

        function testCompareRGBCMFs(testCase)
            titleStr = "Test RGB Comparison";
            p = testCase.Plotter.compareRGBCMFs(testCase.Observer1, testCase.Observer2, Title=titleStr);
            ax = p(1).Parent;

            testCase.verifyEqual(string(ax.Title.String), titleStr);
            testCase.verifyNumElements(p, 6);
            % RGB-vs-LMS labels are the only contract distinguishing this
            % method's output from compareLMS -- a routing mistake otherwise
            % passes every shape and count check.
            testCase.verifyEqual(string({p.DisplayName}), ...
                ["R", "G", "B", "R'", "G'", "B'"]);
        end

        function testPlotMacular(testCase)
            p = testCase.Plotter.plotMacular(testCase.Observer1, Title="Macular");
            ax = p(1).Parent;

            testCase.verifyNotEmpty(ax);
            testCase.verifyNotEmpty(p);
            testCase.verifyNumElements(p, 1);
            lines = findobj(ax, 'Type', 'Line');
            testCase.verifyNumElements(lines, 1);
        end

        function testCompareMacular(testCase)
            p = testCase.Plotter.compareMacular(testCase.Observer1, testCase.Observer2);
            ax = p(1).Parent;

            testCase.verifyNotEmpty(ax);
            testCase.verifyNotEmpty(p);
            testCase.verifyNumElements(p, 2, 'Should return 2 line handles.');
            lines = findobj(ax, 'Type', 'Line');
            testCase.verifyNumElements(lines, 2, 'Should plot 2 lines.');
        end

        function testPlotLens(testCase)
            p = testCase.Plotter.plotLens(testCase.Observer1);
            ax = p(1).Parent;

            testCase.verifyNotEmpty(ax);
            testCase.verifyNotEmpty(p);
            testCase.verifyNumElements(p, 1);
            lines = findobj(ax, 'Type', 'Line');
            testCase.verifyNumElements(lines, 1);
        end

        function testCompareLens(testCase)
            p = testCase.Plotter.compareLens(testCase.Observer1, testCase.Observer2);
            ax = p(1).Parent;

            testCase.verifyNotEmpty(ax);
            testCase.verifyNotEmpty(p);
            testCase.verifyNumElements(p, 2);
            lines = findobj(ax, 'Type', 'Line');
            testCase.verifyNumElements(lines, 2);
        end

        function testQuantalEnergyRobustness(testCase)
            p = testCase.Plotter.compareLMSQuantalEnergy(testCase.Observer1);
            ax = p(1).Parent;

            testCase.verifyEqual(string(testCase.Observer1.OutputFormat), "energy", ...
                "Observer state should be restored after plotting.");

            testCase.verifyNumElements(p, 6, 'Should return 6 line handles.');
            lines = findobj(ax, 'Type', 'Line');
            testCase.verifyNumElements(lines, 6, 'Should compare 3 Quantal vs 3 Energy lines.');
        end

        function testPostCreationCustomization(testCase)
            p = testCase.Plotter.plotLMS(testCase.Observer1);

            set(p, 'LineWidth', 5);

            testCase.verifyEqual(p(1).LineWidth, 5, 'Post-creation customization should work.');
            testCase.verifyEqual(p(2).LineWidth, 5, 'All lines should be customized.');
            testCase.verifyEqual(p(3).LineWidth, 5, 'All lines should be customized.');
        end

        function testNewPropertyNames(testCase)
            % Test new property names
            testCase.verifyTrue(isprop(testCase.Plotter, 'Figure'), 'Should have Figure property');
            testCase.verifyTrue(isprop(testCase.Plotter, 'Layout'), 'Should have Layout property');
            testCase.verifyTrue(isprop(testCase.Plotter, 'ConeColors'), 'Should have ConeColors property');
            testCase.verifyTrue(isprop(testCase.Plotter, 'NeutralColor'), 'Should have NeutralColor property');
            testCase.verifyTrue(isprop(testCase.Plotter, 'PrimaryLineStyle'), 'Should have PrimaryLineStyle');
            testCase.verifyTrue(isprop(testCase.Plotter, 'SecondaryLineStyle'), 'Should have SecondaryLineStyle');
            testCase.verifyTrue(isprop(testCase.Plotter, 'LineWidth'), 'Should have LineWidth property');
        end

        function testDependentColorProperties(testCase)
            % Test dependent ColorL, ColorM, ColorS properties
            testCase.verifyEqual(testCase.Plotter.ColorL, testCase.Plotter.ConeColors(1,:));
            testCase.verifyEqual(testCase.Plotter.ColorM, testCase.Plotter.ConeColors(2,:));
            testCase.verifyEqual(testCase.Plotter.ColorS, testCase.Plotter.ConeColors(3,:));

            % Modify ConeColors and verify dependent properties update
            testCase.Plotter.ConeColors = [1 0 0; 0 1 0; 0 0 1];
            testCase.verifyEqual(testCase.Plotter.ColorL, [1 0 0]);
            testCase.verifyEqual(testCase.Plotter.ColorM, [0 1 0]);
            testCase.verifyEqual(testCase.Plotter.ColorS, [0 0 1]);
        end

        function testTileCount(testCase)
            % Test TileCount dependent property
            testCase.verifyEqual(testCase.Plotter.TileCount, 9, 'TileCount should be 9 for 3x3');
        end

        function testReturnTypesConsistency(testCase)
            p1 = testCase.Plotter.plotLMS(testCase.Observer1);
            ax1 = p1(1).Parent;
            testCase.verifyClass(ax1, 'matlab.graphics.axis.Axes');
            testCase.verifyTrue(all(isgraphics(p1)));

            p2 = testCase.Plotter.plotMacular(testCase.Observer1);
            ax2 = p2(1).Parent;
            testCase.verifyClass(ax2, 'matlab.graphics.axis.Axes');
            testCase.verifyTrue(all(isgraphics(p2)));

            p3 = testCase.Plotter.plotLens(testCase.Observer1);
            ax3 = p3(1).Parent;
            testCase.verifyClass(ax3, 'matlab.graphics.axis.Axes');
            testCase.verifyTrue(all(isgraphics(p3)));

            p4 = testCase.Plotter.compareLMS(testCase.Observer1, testCase.Observer2);
            ax4 = p4(1).Parent;
            testCase.verifyClass(ax4, 'matlab.graphics.axis.Axes');
            testCase.verifyTrue(all(isgraphics(p4)));
        end


        %% plotChromaticity Tests

        function testPlotChromaticity(testCase)
            titleStr = "Test Chromaticity";
            p = testCase.Plotter.plotChromaticity(testCase.Observer1, Title=titleStr);
            ax = p(1).Parent;

            testCase.verifyNotEmpty(ax, 'Axes handle should not be empty.');
            testCase.verifyNotEmpty(p, 'Line handles should not be empty.');
            testCase.verifyEqual(string(ax.Title.String), titleStr, 'Title should match.');

            plotObjects = findall(ax, 'Type', 'Line');
            testCase.verifyGreaterThanOrEqual(numel(plotObjects), 2, ...
                'Should have locus line and markers.');
        end

        function testPlotChromaticityCustomWavelength(testCase)
            wl = (400:10:700)';
            p = testCase.Plotter.plotChromaticity(testCase.Observer1, Wavelength=wl);
            ax = p(1).Parent;

            testCase.verifyNotEmpty(ax);
            testCase.verifyNotEmpty(p);
            testCase.verifyEqual(ax.XLim, [0 1], 'X-axis should span 0-1');
        end

        function testPlotChromaticityIgnoresOutputFormat(testCase)
            % Chromaticity must be invariant under the observer's
            % OutputFormat / LogOutput / NormalizeOutput settings.
            % Without forcing energy/normalized/non-log inside the
            % plotter, an absorbance-configured observer would silently
            % produce a different (wrong) curve.
            obs = IndividualCMF(StandardObserver=2);
            wl = (400:5:700)';

            % Reference: lmChromaticity, which already forces the right
            % LMS basis.
            lmRef = obs.lmChromaticity(wl);

            % Plot under default (energy) state.
            pDefault = testCase.Plotter.plotChromaticity(obs, Wavelength=wl);
            yDefault = pDefault(1).YData(:);
            xDefault = pDefault(1).XData(:);

            % Switch observer to absorbance + log; reuse a fresh plotter
            % to avoid axis state from the previous call. Visible=false
            % keeps the figure hidden during tests.
            obs.OutputFormat = "absorbance";
            obs.LogOutput = true;
            plotter2 = CMFPlotter(Visible=false);
            cleanupPlotter2 = onCleanup(@() close(plotter2.Figure));
            pAbs = plotter2.plotChromaticity(obs, Wavelength=wl);
            yAbs = pAbs(1).YData(:);
            xAbs = pAbs(1).XData(:);

            testCase.verifyEqual(xAbs, xDefault, 'AbsTol', 1e-10, ...
                'plotChromaticity X must be invariant under OutputFormat');
            testCase.verifyEqual(yAbs, yDefault, 'AbsTol', 1e-10, ...
                'plotChromaticity Y must be invariant under OutputFormat');

            % And both must equal the lmChromaticity reference.
            testCase.verifyEqual(xDefault, lmRef(:,1), 'AbsTol', 1e-10, ...
                'plotChromaticity X must match obs.lmChromaticity column 1');
            testCase.verifyEqual(yDefault, lmRef(:,2), 'AbsTol', 1e-10, ...
                'plotChromaticity Y must match obs.lmChromaticity column 2');
        end

        %% compareLDiff Tests

        function testCompareLDiff(testCase)
            titleStr = "Test L-M Diff";
            p = testCase.Plotter.compareLDiff(testCase.Observer1, testCase.Observer2, Title=titleStr);
            ax = p(1).Parent;

            testCase.verifyNotEmpty(ax);
            testCase.verifyNotEmpty(p);
            testCase.verifyEqual(string(ax.Title.String), titleStr);

            lines = findobj(ax, 'Type', 'Line');
            testCase.verifyNumElements(lines, 2, 'Should plot 2 L-M difference lines.');
        end

        function testCompareLDiffCustomWavelength(testCase)
            wl = (450:5:650)';
            p = testCase.Plotter.compareLDiff(testCase.Observer1, testCase.Observer2, Wavelength=wl);
            ax = p(1).Parent;

            testCase.verifyNotEmpty(ax);
            testCase.verifyNotEmpty(p);
            lines = findobj(ax, 'Type', 'Line');
            testCase.verifyNumElements(lines, 2);
        end

        %% plotRGBCMFs Tests

        function testPlotRGBCMFs(testCase)
            titleStr = "Test RGB CMFs";
            p = testCase.Plotter.plotRGBCMFs(testCase.Observer1, Title=titleStr);
            ax = p(1).Parent;

            testCase.verifyNotEmpty(ax);
            testCase.verifyNotEmpty(p);
            testCase.verifyEqual(string(ax.Title.String), titleStr);

            lines = findobj(ax, 'Type', 'Line');
            testCase.verifyNumElements(lines, 3, 'Should plot 3 RGB lines.');
        end

        function testPlotRGBCMFsCustomWavelength(testCase)
            wl = (400:5:700)';
            p = testCase.Plotter.plotRGBCMFs(testCase.Observer1, Wavelength=wl, Title="Custom RGB");
            ax = p(1).Parent;

            testCase.verifyNotEmpty(ax);
            testCase.verifyNotEmpty(p);
        end

        %% plotAbsorbance Tests

        function testPlotAbsorbanceLinear(testCase)
            titleStr = "Test Absorbance Linear";
            p = testCase.Plotter.plotAbsorbance(testCase.Observer1, Title=titleStr, Log=false);
            ax = p(1).Parent;

            testCase.verifyNotEmpty(ax);
            testCase.verifyNotEmpty(p);
            testCase.verifyEqual(string(ax.Title.String), titleStr);

            lines = findobj(ax, 'Type', 'Line');
            testCase.verifyNumElements(lines, 3, 'Should plot 3 absorbance lines.');
        end

        function testPlotAbsorbanceLog(testCase)
            p = testCase.Plotter.plotAbsorbance(testCase.Observer1, Title="Log Absorbance", Log=true);
            ax = p(1).Parent;

            testCase.verifyNotEmpty(ax);
            testCase.verifyNotEmpty(p);
            lines = findobj(ax, 'Type', 'Line');
            testCase.verifyNumElements(lines, 3);
        end

        function testPlotAbsorbanceStateRestoration(testCase)
            obs = IndividualCMF(StandardObserver=2);
            originalFormat = obs.OutputFormat;
            originalLog = obs.LogOutput;
            originalNorm = obs.NormalizeOutput;

            testCase.Plotter.plotAbsorbance(obs);

            testCase.verifyEqual(string(obs.OutputFormat), originalFormat, ...
                'OutputFormat should be restored');
            testCase.verifyEqual(obs.LogOutput, originalLog, ...
                'LogOutput should be restored');
            testCase.verifyEqual(obs.NormalizeOutput, originalNorm, ...
                'NormalizeOutput should be restored');
        end

        %% plotAbsorptance Tests

        function testPlotAbsorptance(testCase)
            titleStr = "Test Absorptance";
            p = testCase.Plotter.plotAbsorptance(testCase.Observer1, Title=titleStr);
            ax = p(1).Parent;

            testCase.verifyNotEmpty(ax);
            testCase.verifyNotEmpty(p);
            testCase.verifyEqual(string(ax.Title.String), titleStr);

            lines = findobj(ax, 'Type', 'Line');
            testCase.verifyNumElements(lines, 3, 'Should plot 3 absorptance lines.');
        end

        function testPlotAbsorptanceStateRestoration(testCase)
            obs = IndividualCMF(StandardObserver=2);
            originalFormat = obs.OutputFormat;
            originalNorm = obs.NormalizeOutput;

            testCase.Plotter.plotAbsorptance(obs);

            testCase.verifyEqual(string(obs.OutputFormat), originalFormat, ...
                'OutputFormat should be restored');
            testCase.verifyEqual(obs.NormalizeOutput, originalNorm, ...
                'NormalizeOutput should be restored');
        end

        %% plotDiagnosticsPanel Tests

        function testPlotDiagnosticsPanel(testCase)
            % Test diagnostics panel (requires 3 tiles)
            plotter = CMFPlotter(1, 3, Visible=false);

            % Should not throw
            testCase.verifyWarningFree(@() plotter.plotDiagnosticsPanel(testCase.Observer1));

            % Clean up
            close(plotter.Figure);
        end

        function testPlotDiagnosticsPanelCustomWavelength(testCase)
            % Test diagnostics panel with custom wavelengths
            plotter = CMFPlotter(1, 3, Visible=false);
            wl = (400:2:700)';

            testCase.verifyWarningFree(@() plotter.plotDiagnosticsPanel(testCase.Observer1, Wavelength=wl));

            close(plotter.Figure);
        end

        function testPlotDiagnosticsPanelStateRestoration(testCase)
            plotter = CMFPlotter(1, 3, Visible=false);
            obs = IndividualCMF(StandardObserver=2);
            originalFormat = obs.OutputFormat;
            originalNorm = obs.NormalizeOutput;

            plotter.plotDiagnosticsPanel(obs);

            testCase.verifyEqual(string(obs.OutputFormat), originalFormat, ...
                'OutputFormat should be restored after diagnostics');
            testCase.verifyEqual(obs.NormalizeOutput, originalNorm, ...
                'NormalizeOutput should be restored after diagnostics');

            close(plotter.Figure);
        end

        %% Tile Position Tests

        function testSpecificTilePosition(testCase)
            p = testCase.Plotter.plotLMS(testCase.Observer1, Tile=5);
            ax = p(1).Parent;

            testCase.verifyNotEmpty(ax);
            testCase.verifyNotEmpty(p);
        end

        %% YLim Tests

        function testCustomYLim(testCase)
            ylimVal = [0 1.5];
            p = testCase.Plotter.plotLMS(testCase.Observer1, YLim=ylimVal);
            ax = p(1).Parent;

            testCase.verifyNotEmpty(p);
            testCase.verifyEqual(ax.YLim, ylimVal, 'Y-axis limits should match specified values.');
        end

        %% Color Property Tests

        function testColorProperties(testCase)
            testCase.Plotter.ConeColors = [1 0.5 0; 0 0.5 0.5; 0.5 0 0.5];

            p = testCase.Plotter.plotLMS(testCase.Observer1);
            ax = p(1).Parent;

            testCase.verifyNotEmpty(ax);
            testCase.verifyNotEmpty(p);
            lines = findobj(ax, 'Type', 'Line');
            testCase.verifyNumElements(lines, 3);
        end

        %% Line Style Tests

        function testLineStyleProperties(testCase)
            testCase.Plotter.PrimaryLineStyle = ":";
            testCase.Plotter.SecondaryLineStyle = "-.";

            p = testCase.Plotter.compareLMS(testCase.Observer1, testCase.Observer2);
            ax = p(1).Parent;

            testCase.verifyNotEmpty(ax);
            testCase.verifyNotEmpty(p);
        end

        %% LineWidth Tests

        function testLineWidthProperty(testCase)
            testCase.Plotter.LineWidth = 3;

            p = testCase.Plotter.plotLMS(testCase.Observer1);
            ax = p(1).Parent;
            lines = findobj(ax, 'Type', 'Line');

            testCase.verifyEqual(lines(1).LineWidth, 3, 'LineWidth should be applied.');
            testCase.verifyNotEmpty(p);
        end

        %% FontSize Tests

        function testFontSizeProperty(testCase)
            testCase.Plotter.FontSize = 14;

            p = testCase.Plotter.plotLMS(testCase.Observer1, Title="Font Test");
            ax = p(1).Parent;

            testCase.verifyEqual(ax.XLabel.FontSize, 14, 'FontSize should be applied to labels.');
            testCase.verifyNotEmpty(p);
        end

        %% NEW: plotDifference Tests

        function testPlotDifference(testCase)
            p = testCase.Plotter.plotDifference(testCase.Observer1, testCase.Observer2);
            ax = p(1).Parent;

            testCase.verifyNotEmpty(ax);
            testCase.verifyNotEmpty(p);
            lines = findobj(ax, 'Type', 'Line');
            testCase.verifyGreaterThanOrEqual(numel(lines), 3);
        end

        function testPlotDifferenceNormalized(testCase)
            p = testCase.Plotter.plotDifference(testCase.Observer1, testCase.Observer2, Normalize=true);
            ax = p(1).Parent;

            testCase.verifyNotEmpty(ax);
            testCase.verifyNotEmpty(p);
            testCase.verifyTrue(contains(string(ax.YLabel.String), '%'), ...
                'Y label should indicate percentage');
        end

        function testPlotDifferenceSelectCones(testCase)
            p = testCase.Plotter.plotDifference(testCase.Observer1, testCase.Observer2, Cones=["L", "S"]);
            ax = p(1).Parent;

            testCase.verifyNotEmpty(ax);
            testCase.verifyNotEmpty(p);
            lines = findobj(ax, 'Type', 'Line');
            testCase.verifyGreaterThanOrEqual(numel(lines), 2);
        end

        %% NEW: plotWithPeaks Tests

        function testPlotWithPeaks(testCase)
            p = testCase.Plotter.plotWithPeaks(testCase.Observer1);
            ax = p(1).Parent;

            testCase.verifyNotEmpty(ax);
            testCase.verifyNotEmpty(p);
            plotObjects = findobj(ax, 'Type', 'Line');
            testCase.verifyGreaterThanOrEqual(numel(plotObjects), 3);
        end

        function testPlotWithPeaksNoLabels(testCase)
            p = testCase.Plotter.plotWithPeaks(testCase.Observer1, ShowLabels=false);
            ax = p(1).Parent;

            testCase.verifyNotEmpty(ax);
            testCase.verifyNotEmpty(p);
        end

        %% NEW: plotMultiple Tests

        function testPlotMultiple(testCase)
            observers = {testCase.Observer1, testCase.Observer2};
            p = testCase.Plotter.plotMultiple(observers, Cone="L");
            ax = p(1).Parent;

            testCase.verifyNotEmpty(ax);
            testCase.verifyNotEmpty(p);
            lines = findobj(ax, 'Type', 'Line');
            testCase.verifyNumElements(lines, 2, 'Should have 2 L-cone lines');
        end

        function testPlotMultipleAllCones(testCase)
            observers = {testCase.Observer1, testCase.Observer2};
            p = testCase.Plotter.plotMultiple(observers, Cone="all");
            ax = p(1).Parent;

            testCase.verifyNotEmpty(ax);
            testCase.verifyNotEmpty(p);
            lines = findobj(ax, 'Type', 'Line');
            testCase.verifyNumElements(lines, 6, 'Should have 6 lines for 2 observers, all cones');
        end

        function testPlotMultipleWithLabels(testCase)
            observers = {testCase.Observer1, testCase.Observer2};
            p = testCase.Plotter.plotMultiple(observers, Cone="L", Labels=["Young", "Old"]);
            ax = p(1).Parent;

            testCase.verifyNotEmpty(ax);
            testCase.verifyNotEmpty(p);
        end

        %% NEW: highlightBand Tests

        function testHighlightBand(testCase)
            p = testCase.Plotter.plotLMS(testCase.Observer1);
            ax = p(1).Parent;
            testCase.Plotter.highlightBand(ax, 450, 500);

            testCase.verifyNotEmpty(p);
            patches = findall(ax, 'Type', 'Patch');
            testCase.verifyNumElements(patches, 1, 'Should have 1 highlight patch');
        end

        function testHighlightBandWithLabel(testCase)
            p = testCase.Plotter.plotLMS(testCase.Observer1);
            ax = p(1).Parent;
            testCase.Plotter.highlightBand(ax, 450, 500, Label="Blue region");

            testCase.verifyNotEmpty(p);
            patches = findall(ax, 'Type', 'Patch');
            testCase.verifyNumElements(patches, 1);
        end

        %% exportFigure Tests

        function testExportFigureWritesValidFormat(testCase, ExportFormat)
            testCase.Plotter.plotLMS(testCase.Observer1);
            tempFile = char(fullfile(tempdir, "cmfplotter_export_test." + ExportFormat.fmt));
            cleanup = onCleanup(@() safeDelete(tempFile)); %#ok<NASGU>

            % MATLAB:graphics:HardwareUnavailable fires on headless CI runners
            % (no GPU) from R2026a's print path. It is environmental, not
            % triggered by toolbox code, and absent for end users with
            % graphics acceleration. Suppress it explicitly so the assertion
            % still catches any other unexpected warning.
            warnState = warning('off', 'MATLAB:graphics:HardwareUnavailable');
            warnCleanup = onCleanup(@() warning(warnState)); %#ok<NASGU>

            testCase.verifyWarningFree( ...
                @() testCase.Plotter.exportFigure(tempFile, Format=ExportFormat.fmt));
            testCase.verifyTrue(isfile(tempFile));

            fid = fopen(tempFile, 'rb');
            hdr = fread(fid, numel(ExportFormat.magic), 'uint8=>uint8')';
            fclose(fid);
            testCase.verifyEqual(hdr, ExportFormat.magic);
        end

        %% Constructor Options Tests

        function testConstructorWithTitle(testCase)
            % Test constructor with super-title
            plotter = CMFPlotter(2, 2, Visible=false, Title="Test Figure");
            testCase.verifyNotEmpty(plotter);
            close(plotter.Figure);
        end

        function testConstructorWithCustomPosition(testCase)
            % Test constructor with custom position
            pos = [200, 200, 800, 600];
            plotter = CMFPlotter(2, 2, Visible=false, Position=pos);
            testCase.verifyEqual(plotter.Figure.Position, pos);
            close(plotter.Figure);
        end

        function testConstructorWithPadding(testCase)
            % Test constructor with padding options
            plotter = CMFPlotter(2, 2, Visible=false, Padding="tight", TileSpacing="loose");
            testCase.verifyNotEmpty(plotter);
            close(plotter.Figure);
        end
    end
end

% -------------------------------------------------------------------------

function safeDelete(f)
    if isfile(f), delete(f); end
end

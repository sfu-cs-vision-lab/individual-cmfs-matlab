classdef IndividualCMFVisualizationTest < matlab.unittest.TestCase
    % INDIVIDUALCMFVISUALIZATIONTESTS  Tests for IndividualCMF visualization methods.
    %   These tests cover the unified plot() method and its various modes.
    %   Updated for new API where all plotting methods return [p, ax].

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada
    %
    % This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    % Licensed under AGPL-3.0-or-later. See LICENSE file for details.
    % Repository: https://github.com/sfu-cs-vision-lab/Individual-CMFs

    properties
        Observer1
        Observer2
        TestWavelengths
    end

    properties(TestParameter)
        PlotDataType = {"LMS", "RGB", "chromaticity", "absorbance", "absorptance"};
    end

    methods(TestMethodSetup)
        function setupObservers(testCase)
            set(0, 'DefaultFigureVisible', 'off');
            testCase.Observer1 = IndividualCMF(Age=32, FieldSize=2);
            testCase.Observer2 = IndividualCMF(Age=55, FieldSize=10);
            testCase.TestWavelengths = (400:5:700)';
        end
    end

    methods(TestMethodTeardown)
        function closeFigures(testCase) %#ok<MANU>
            close all hidden;
        end
    end

    methods(Test)

        %% Unified plot() Method Tests

        function testPlotDispatchPerDataType(testCase, PlotDataType)
            p = testCase.Observer1.plot(Data=PlotDataType);
            ax = p(1).Parent;
            testCase.verifyNotEmpty(p);
            testCase.verifyClass(ax, 'matlab.graphics.axis.Axes');
        end

        function testPlotComparison(testCase)
            % Test plot() comparison mode
            p = testCase.Observer1.plot(Data="LMS", Compare=testCase.Observer2);
            testCase.verifyNotEmpty(p);
            % Comparison should return 6 line handles (3 Reference + 3 Comparison)
            testCase.verifyNumElements(p, 6, 'Comparison should return 6 line handles.');
        end

        function testPlotRGBComparison(testCase)
            % Test plot(Data="RGB", Compare=...) dispatches to compareRGBCMFs.
            p = testCase.Observer1.plot(Data="RGB", Compare=testCase.Observer2);
            testCase.verifyNumElements(p, 6, 'RGB comparison should return 6 line handles.');
        end

        %% plotDiagnostics Tests

        function testPlotDiagnostics(testCase)
            % Three stage panels, each with one line per cone.
            [p, ax] = testCase.Observer1.plotDiagnostics();

            testCase.verifyClass(p, 'cell');
            testCase.verifySize(p, [3 1]);
            testCase.verifySize(ax, [3 1]);
            for s = 1:3
                testCase.verifySize(p{s}, [3 1]);
                testCase.verifyTrue(all(isgraphics(p{s})), ...
                    sprintf('Stage %d should draw all three cone lines', s));
            end
        end

        function testPlotDiagnosticsWithWavelengths(testCase)
            % The supplied grid must reach the drawn data, not just be accepted.
            wl = (400:5:700)';
            [p, ax] = testCase.Observer1.plotDiagnostics(Wavelength=wl);

            testCase.verifySize(ax, [3 1]);
            for s = 1:3
                testCase.verifyEqual(p{s}(1).XData(:), wl, 'AbsTol', 0, ...
                    sprintf('Stage %d should plot against the supplied grid', s));
            end
        end

        function testPlotDiagnosticsAcceptsAnExistingLayout(testCase)
            % Parent= lets the panel compose into a layout the caller owns,
            % which is what replaced the old Plotter argument.
            fig = figure('Visible','off');
            cleanup = onCleanup(@() close(fig)); %#ok<NASGU>
            layout = tiledlayout(fig, 1, 3);

            [p, ax] = testCase.Observer1.plotDiagnostics(Parent=layout);

            testCase.verifySize(ax, [3 1]);
            testCase.verifySize(p, [3 1]);
            for s = 1:3
                testCase.verifyEqual(ancestor(ax(s), 'figure'), fig, ...
                    'Panels must be drawn into the supplied layout.');
            end
        end

        function testPlotDiagnosticsRejectsRemovedPlotterOption(testCase)
            % The Plotter argument is gone; CMFPlotter no longer participates.
            testCase.verifyError( ...
                @() testCase.Observer1.plotDiagnostics(Plotter=1), ...
                'MATLAB:TooManyInputs');
        end

        %% Shortcut Method Tests

        function testPlotLMSShortcut(testCase)
            % Test plotLMS shortcut method
            p = testCase.Observer1.plotLMS();
            testCase.verifyNotEmpty(p);
            testCase.verifyNumElements(p, 3, 'LMS plot should return 3 line handles.');
        end

        function testPlotLMSLogOption(testCase)
            % Log=true should plot log10 sensitivity values and label the y-axis accordingly.
            wl = (400:5:700)';
            [p, ax] = testCase.Observer1.plotLMS(Log=true, Wavelength=wl);
            testCase.verifyNumElements(p, 3);
            testCase.verifyEqual(string(ax.YLabel.String), "Log_{10} Sensitivity");
            % Y data should match the observer's LogOutput=true LMS values.
            expected = testCase.Observer1.LMS(wl, LogOutput=true);
            testCase.verifyEqual(p(1).YData(:), expected(:,1), 'AbsTol', 1e-12);
            testCase.verifyEqual(p(2).YData(:), expected(:,2), 'AbsTol', 1e-12);
            testCase.verifyEqual(p(3).YData(:), expected(:,3), 'AbsTol', 1e-12);
        end

        function testPlotLMSLogIndependentOfObserverState(testCase)
            % Log=true on the call should override the observer's LogOutput setting.
            obsLinear = IndividualCMF(LogOutput=false);
            obsLog    = IndividualCMF(LogOutput=true);
            wl = (400:5:700)';
            figure; pLinearOut = obsLinear.plotLMS(Log=true, Wavelength=wl);
            yLinear = pLinearOut(1).YData;
            figure; pLogOut = obsLog.plotLMS(Log=true, Wavelength=wl);
            yLog = pLogOut(1).YData;
            testCase.verifyEqual(yLinear, yLog, 'AbsTol', 1e-12);
        end

        function testPlotChromaticityShortcut(testCase)
            % The locus must be a single line whose data matches
            % lmChromaticity, not merely a non-empty handle.
            wl = (400:5:700)';
            obs = testCase.Observer1;
            p = obs.plotChromaticity(Wavelength=wl);
            ref = obs.lmChromaticity(wl);

            testCase.verifyNumElements(p, 1);
            testCase.verifyEqual(p(1).XData(:), ref(:,1), 'AbsTol', 1e-10);
            testCase.verifyEqual(p(1).YData(:), ref(:,2), 'AbsTol', 1e-10);
        end

        function testPlotChromaticityIgnoresOutputFormat(testCase)
            % Migrated from CMFPlotterTest. Chromaticity must be invariant
            % under the observer's OutputFormat / LogOutput settings:
            % without forcing the energy/normalized/non-log basis, an
            % absorbance-configured observer would silently produce a
            % different and wrong curve.
            wl = (400:5:700)';
            obs = IndividualCMF(StandardObserver=2);
            lmRef = obs.lmChromaticity(wl);

            fig = figure('Visible','off');
            cleanup = onCleanup(@() close(fig)); %#ok<NASGU>
            pDefault = obs.plotChromaticity(Wavelength=wl, Parent=axes(fig));
            xDefault = pDefault(1).XData(:);
            yDefault = pDefault(1).YData(:);

            obs.OutputFormat = "absorbance";
            obs.LogOutput = true;
            pAbs = obs.plotChromaticity(Wavelength=wl, Parent=axes(fig));

            testCase.verifyEqual(pAbs(1).XData(:), xDefault, 'AbsTol', 1e-10, ...
                'plotChromaticity X must be invariant under OutputFormat');
            testCase.verifyEqual(pAbs(1).YData(:), yDefault, 'AbsTol', 1e-10, ...
                'plotChromaticity Y must be invariant under OutputFormat');
            testCase.verifyEqual(xDefault, lmRef(:,1), 'AbsTol', 1e-10, ...
                'plotChromaticity X must match obs.lmChromaticity column 1');
            testCase.verifyEqual(yDefault, lmRef(:,2), 'AbsTol', 1e-10, ...
                'plotChromaticity Y must match obs.lmChromaticity column 2');
        end

        function testPlotMethodsDoNotMutateObserverState(testCase)
            % Migrated from CMFPlotterTest's per-method state-restoration
            % tests. The plot methods reach other output formats through
            % per-call LMS overrides, so the observer's persistent
            % OutputFormat / LogOutput / NormalizeOutput must come back
            % unchanged from every one of them.
            obs = IndividualCMF(StandardObserver=2);
            before = {obs.OutputFormat, obs.LogOutput, obs.NormalizeOutput};

            fig = figure('Visible','off');
            cleanup = onCleanup(@() close(fig)); %#ok<NASGU>
            methodsUnderTest = {@() obs.plotAbsorbance(Parent=axes(fig)), ...
                                @() obs.plotAbsorptance(Parent=axes(fig)), ...
                                @() obs.plotQuantalEnergy(Parent=axes(fig)), ...
                                @() obs.plotLMS(Parent=axes(fig)), ...
                                @() obs.plotDiagnostics(Parent=tiledlayout(fig, 1, 3))};
            names = ["plotAbsorbance", "plotAbsorptance", "plotQuantalEnergy", ...
                     "plotLMS", "plotDiagnostics"];

            for k = 1:numel(methodsUnderTest)
                methodsUnderTest{k}();
                testCase.verifyEqual(obs.OutputFormat, before{1}, ...
                    names(k) + " must restore OutputFormat");
                testCase.verifyEqual(obs.LogOutput, before{2}, ...
                    names(k) + " must restore LogOutput");
                testCase.verifyEqual(obs.NormalizeOutput, before{3}, ...
                    names(k) + " must restore NormalizeOutput");
            end
        end

        function testPlotRGBCMFsShortcut(testCase)
            % Test plotRGBCMFs shortcut method
            p = testCase.Observer1.plotRGBCMFs();
            testCase.verifyNotEmpty(p);
            testCase.verifyNumElements(p, 3, 'RGB plot should return 3 line handles.');
        end

        function testPlotXYZValuesMatchXYZ(testCase)
            % Wrapper y-data must equal obj.XYZ(wl) columns.
            wl = (400:5:700)';
            p = testCase.Observer1.plotXYZ(Wavelength=wl);
            expected = testCase.Observer1.XYZ(wl);
            for k = 1:3
                testCase.verifyEqual(p(k).YData(:), expected(:,k), 'AbsTol', 1e-12);
            end
        end

        function testPlotLMSConesSubset(testCase)
            % Cones=["L" "S"] should draw only L and S; M slot stays as gobjects placeholder.
            wl = (400:5:700)';
            p = testCase.Observer1.plotLMS(Cones=["L", "S"], Wavelength=wl);
            testCase.verifyTrue(isgraphics(p(1)));
            testCase.verifyFalse(isgraphics(p(2)));
            testCase.verifyTrue(isgraphics(p(3)));
            expected = testCase.Observer1.LMS(wl);
            testCase.verifyEqual(p(1).YData(:), expected(:,1), 'AbsTol', 1e-12);
            testCase.verifyEqual(p(3).YData(:), expected(:,3), 'AbsTol', 1e-12);
        end

        function testPlotXYZChannelsSubset(testCase)
            % Channels=["Y"] should draw only Y; X and Z stay as gobjects placeholders.
            wl = (400:5:700)';
            p = testCase.Observer1.plotXYZ(Channels="Y", Wavelength=wl);
            testCase.verifyFalse(isgraphics(p(1)));
            testCase.verifyTrue(isgraphics(p(2)));
            testCase.verifyFalse(isgraphics(p(3)));
            expected = testCase.Observer1.XYZ(wl);
            testCase.verifyEqual(p(2).YData(:), expected(:,2), 'AbsTol', 1e-12);
        end

        function testPlotXYZDichromatRequiresMatrix(testCase)
            % Bare call on a dichromat must raise; TransformationMatrix overrides.
            obs = IndividualCMF(); obs.Lod = 0;
            testCase.verifyError(@() obs.plotXYZ(), ...
                'IndividualCMF:XYZUndefinedForDichromat');
            M = [zeros(1,3); CIE170.M_10DEG(2:3,:)];
            p = obs.plotXYZ(TransformationMatrix=M);
            testCase.verifyNumElements(p, 3);
        end

        %% compareTo Method Tests

        function testCompareTo(testCase)
            % Test compareTo method 
            p = testCase.Observer1.compareTo(testCase.Observer2);
            testCase.verifyNotEmpty(p);
            testCase.verifyNumElements(p, 6, 'Comparison should return 6 line handles.');
        end

        function testCompareToWithTitle(testCase)
            % Test compareTo with custom title 
            titleStr = "Custom Comparison";
            p = testCase.Observer1.compareTo(testCase.Observer2, Title=titleStr);
            testCase.verifyNotEmpty(p);
            ax = p(1).Parent;
            testCase.verifyEqual(string(ax.Title.String), titleStr);
        end

        %% Post-Creation Customization Tests

        function testPostCreationCustomization(testCase)
            p = testCase.Observer1.plotLMS();

            % Customize via returned handles
            set(p, 'LineWidth', 4);

            % Verify the LineWidth was actually applied
            testCase.verifyEqual(p(1).LineWidth, 4, 'Post-creation customization should work.');
            testCase.verifyEqual(p(2).LineWidth, 4);
            testCase.verifyEqual(p(3).LineWidth, 4);
        end

        function testAxesCustomization(testCase)
            % plotLMS returns line handles; the axes are reachable via the
            % handles' Parent (documented in the IndividualCMF docstring).
            p = testCase.Observer1.plotLMS();
            ax = p(1).Parent;

            % Customize axes
            ax.XLim = [400 650];
            ax.Title.String = "Custom Title";

            testCase.verifyEqual(ax.XLim, [400 650]);
            testCase.verifyEqual(string(ax.Title.String), "Custom Title");
        end

        %% Return Types Consistency Tests

        function testReturnTypesConsistency(testCase)
            % Verify all shortcut methods return [p, ax] consistently

            % plotLMS
            p1 = testCase.Observer1.plotLMS();
            testCase.verifyTrue(all(isgraphics(p1)));

            % plotChromaticity
            p2 = testCase.Observer1.plotChromaticity();
            testCase.verifyTrue(all(isgraphics(p2)));

            % plotRGBCMFs
            p3 = testCase.Observer1.plotRGBCMFs();
            testCase.verifyTrue(all(isgraphics(p3)));

            % compareTo
            p4 = testCase.Observer1.compareTo(testCase.Observer2);
            testCase.verifyTrue(all(isgraphics(p4)));
        end

        %% Additional plot() Name-Value Coverage

        function testPlotWithDataParameter(testCase)
            % Test plot() with different data type strings
            testCase.verifyWarningFree(@() testCase.Observer1.plot(Data="LMS"));
            testCase.verifyWarningFree(@() testCase.Observer1.plot(Data="RGB"));
        end

        function testPlotWithLogTrue(testCase)
            % Test plot() with Log=true
            testCase.verifyWarningFree(@() testCase.Observer1.plot(Log=true));
        end

        function testPlotWithLogFalse(testCase)
            % Test plot() with Log=false
            testCase.verifyWarningFree(@() testCase.Observer1.plot(Log=false));
        end

        function testPlotWithTitle(testCase)
            % Test plot() with Title parameter
            testCase.verifyWarningFree(@() testCase.Observer1.plot(Title="Custom Title"));
        end

        %% Design-split contract tests

        function testPlotLMSPreservesHoldOn(testCase)
            % plotLMS(Parent=ax) must not change ishold(ax) when hold was on.
            fig = figure('Visible','off');
            ax = axes(fig);
            hold(ax, 'on');
            testCase.Observer1.plotLMS(Parent=ax);
            testCase.verifyTrue(ishold(ax), ...
                'plotLMS should preserve hold-on state of the supplied axes.');
            close(fig);
        end

        function testPlotLMSPreservesHoldOff(testCase)
            % plotLMS(Parent=ax) must not change ishold(ax) when hold was off.
            fig = figure('Visible','off');
            ax = axes(fig);
            testCase.assumeFalse(ishold(ax), ...
                'Setup precondition: a fresh axes should not be held.');
            testCase.Observer1.plotLMS(Parent=ax);
            testCase.verifyFalse(ishold(ax), ...
                'plotLMS should preserve hold-off state of the supplied axes.');
            close(fig);
        end

        function testPlotLMSDoesNotOpenExtraFigures(testCase)
            % From a clean state, plotLMS() should reuse the current figure
            % via gca rather than open a new one.
            close all hidden;
            preCount = numel(findall(groot, 'Type', 'figure'));
            testCase.Observer1.plotLMS();
            postCount = numel(findall(groot, 'Type', 'figure'));
            testCase.verifyEqual(postCount - preCount, 1, ...
                'plotLMS should create at most one inline figure from a clean state.');
        end

        function testPlotMethodsDoNotInstantiateCMFPlotter(testCase)
            % Static-source guarantee: no IndividualCMF plot method may
            % construct a CMFPlotter. plotDiagnostics used to be a
            % whitelisted exception; it now builds its own tiledlayout, so
            % there is no exception left and the check is unconditional.
            txt = fileread(which('IndividualCMF'));
            testCase.verifyEmpty(regexp(txt, '\<CMFPlotter\s*\(', 'start'), ...
                ['IndividualCMF.m must not construct a CMFPlotter. Plot ' ...
                 'methods are axes-native; multi-panel layouts use ' ...
                 'tiledlayout and nexttile.']);
        end

        function testDichromatHandleShape(testCase)
            % An absent cone (Lod/Mod/Sod == 0) should leave the
            % corresponding handle slot as a non-valid gobjects placeholder
            % so caller indexing stays stable at p(1)=L, p(2)=M, p(3)=S.
            obsProt = IndividualCMF(Lod=0);
            obsDeut = IndividualCMF(Mod=0);
            obsTrit = IndividualCMF(Sod=0);

            pProt = obsProt.plotLMS();
            testCase.verifyNumElements(pProt, 3);
            testCase.verifyFalse(isgraphics(pProt(1)), 'Protanope: L slot should be invalid.');
            testCase.verifyTrue(isgraphics(pProt(2)),  'Protanope: M slot should be valid.');
            testCase.verifyTrue(isgraphics(pProt(3)),  'Protanope: S slot should be valid.');

            pDeut = obsDeut.plotLMS();
            testCase.verifyNumElements(pDeut, 3);
            testCase.verifyTrue(isgraphics(pDeut(1)),  'Deuteranope: L slot should be valid.');
            testCase.verifyFalse(isgraphics(pDeut(2)), 'Deuteranope: M slot should be invalid.');
            testCase.verifyTrue(isgraphics(pDeut(3)),  'Deuteranope: S slot should be valid.');

            pTrit = obsTrit.plotLMS();
            testCase.verifyNumElements(pTrit, 3);
            testCase.verifyTrue(isgraphics(pTrit(1)),  'Tritanope: L slot should be valid.');
            testCase.verifyTrue(isgraphics(pTrit(2)),  'Tritanope: M slot should be valid.');
            testCase.verifyFalse(isgraphics(pTrit(3)), 'Tritanope: S slot should be invalid.');
        end

        function testFreshAxesEscapesPriorTiledLayout(testCase)
            % Models the Example15 pattern: after a tiledlayout/nexttile
            % section leaves gca pointing at the last tile, 'ax = axes'
            % must produce a target that is NOT one of those tiles.
            fig = figure('Visible','off');
            tl = tiledlayout(fig, 2, 3);
            tileAxes = gobjects(6, 1);
            for k = 1:6
                tileAxes(k) = nexttile(tl);
                plot(tileAxes(k), 1:10, rand(1, 10));
            end
            gcaBefore = gca;
            testCase.assertEqual(gcaBefore, tileAxes(end), ...
                'Setup precondition: gca should be the last tile.');

            ax = axes;
            testCase.verifyNotEqual(ax, tileAxes(end), ...
                'A fresh ax = axes must not point at a prior tile.');
            for k = 1:6
                testCase.verifyNotEqual(ax, tileAxes(k), ...
                    'A fresh ax = axes must not be any of the prior tiles.');
            end
            close(fig);
        end

        function testPlotMacularPeakMatchesMacularDensity(testCase)
            % The plotted curve must peak near obs.MacularDensity. Catches
            % the regression where macularTemplate (peak ~0.35) was
            % multiplied by MacularDensity directly, producing values
            % ~3.5x too small. Tolerance accounts for the ~1.5% deviation
            % between the Fourier-fit template peak and the documented
            % CIE170.STD_2DEG_MACULAR_DENSITY constant (see
            % StockmanRider2023MacularTemplate).
            obs = testCase.Observer1;
            wl = (380:1:780)';
            p = obs.plotMacular(Wavelength=wl);
            yPeak = max(p(1).YData);
            testCase.verifyEqual(yPeak, obs.MacularDensity, 'RelTol', 0.02, ...
                'plotMacular YData peak must approximate obs.MacularDensity');
            % Sharper guardrail against the buggy 0.35x scaling: peak
            % must be > 0.5 * MacularDensity (the buggy version was
            % ~0.35 * MacularDensity).
            testCase.verifyGreaterThan(yPeak, 0.5 * obs.MacularDensity, ...
                'plotMacular peak must not be silently rescaled to ~0.35x');
        end

        function testPlotQuantalEnergyHandleCount(testCase)
            p = testCase.Observer1.plotQuantalEnergy();
            testCase.verifyNumElements(p, 6);
            testCase.verifyTrue(all(isgraphics(p)));
        end

        function testPlotAbsorbanceLogLabelDiffersFromLinear(testCase)
            % A swap of the Log=true/false label branches would silently
            % mislabel every log plot without any other failure mode.
            [~, axLin] = testCase.Observer1.plotAbsorbance(Log=false);
            linLabel = axLin.YLabel.String;
            close all hidden;
            [~, axLog] = testCase.Observer1.plotAbsorbance(Log=true);
            logLabel = axLog.YLabel.String;
            testCase.verifyNotEqual(logLabel, linLabel);
            testCase.verifySubstring(lower(logLabel), 'log');
        end

        function testPlotAbsorptanceLogLabelDiffersFromLinear(testCase)
            [~, axLin] = testCase.Observer1.plotAbsorptance(Log=false);
            linLabel = axLin.YLabel.String;
            close all hidden;
            [~, axLog] = testCase.Observer1.plotAbsorptance(Log=true);
            logLabel = axLog.YLabel.String;
            testCase.verifyNotEqual(logLabel, linLabel);
            testCase.verifySubstring(lower(logLabel), 'log');
        end

        function testPlotLensDefaultReturnsSingleHandle(testCase)
            p = testCase.Observer1.plotLens();
            testCase.verifyNumElements(p, 1);
            testCase.verifyTrue(isgraphics(p(1)));
        end

        function testPlotLensCompareReturnsTwoHandles(testCase)
            % Use an age-dependent lens model on both observers (default
            % Stockman-Rider is age-independent and would give identical
            % curves, masking a copy-bug where p(2) plots the reference).
            obsRef  = IndividualCMF(Age=32, FieldSize=2, LensModel="Pokorny1987");
            obsComp = IndividualCMF(Age=70, FieldSize=2, LensModel="Pokorny1987");
            % Pokorny has no value below 400 nm, so the plotted curve
            % carries NaN there. Expected, and not what this test is about.
            obsRef.ModelRangeWarning = false;
            obsComp.ModelRangeWarning = false;

            p = obsRef.plotLens(Compare=obsComp);
            testCase.verifyNumElements(p, 2);

            % Compare where both curves have values. NaN never equals NaN,
            % so comparing the raw YData would pass even if p(2) plotted
            % the reference by mistake -- the bug this test exists to catch.
            y1 = p(1).YData(:);
            y2 = p(2).YData(:);
            defined = isfinite(y1) & isfinite(y2);
            testCase.assertTrue(any(defined), ...
                'The two curves must overlap somewhere');
            testCase.verifyNotEqual(y1(defined), y2(defined));
        end

        function testPlotLensCompareRejectsNonObserver(testCase)
            testCase.verifyError( ...
                @() testCase.Observer1.plotLens(Compare="not an observer"), ...
                'IndividualCMF:InvalidInput');
        end

        function testPlotMacularComparePeakMatchesEachObserver(testCase)
            % The Compare branch rescales BOTH curves: p(1) to the reference
            % observer's MacularDensity, p(2) to the comparison observer's.
            % Catches a regression where one of the two rescales is forgotten.
            obsRef  = IndividualCMF(Age=32, FieldSize=2);
            obsComp = IndividualCMF(Age=32, FieldSize=2, MacularDensity=0.10);
            testCase.assumeNotEqual(obsRef.MacularDensity, obsComp.MacularDensity);

            wl = (380:1:780)';
            p = obsRef.plotMacular(Compare=obsComp, Wavelength=wl);
            testCase.verifyNumElements(p, 2);
            testCase.verifyEqual(max(p(1).YData), obsRef.MacularDensity, ...
                'RelTol', 0.02);
            testCase.verifyEqual(max(p(2).YData), obsComp.MacularDensity, ...
                'RelTol', 0.02);
        end

        function testPlotMacularCompareRejectsNonObserver(testCase)
            testCase.verifyError( ...
                @() testCase.Observer1.plotMacular(Compare="not an observer"), ...
                'IndividualCMF:InvalidInput');
        end

        %% Shared palette and axes-setup helpers

        function testConeColorsConstantIsUsedByDefault(testCase)
            % The default L/M/S line colors must come from the class
            % constant, not from literals scattered through the plot code.
            obs = IndividualCMF();
            fig = figure('Visible','off');
            cleanup = onCleanup(@() close(fig)); %#ok<NASGU>
            p = obs.plotLMS(Parent=axes(fig));

            testCase.verifyEqual(p(1).Color, IndividualCMF.CONE_COLORS(1,:), ...
                'AbsTol', 1e-12);
            testCase.verifyEqual(p(2).Color, IndividualCMF.CONE_COLORS(2,:), ...
                'AbsTol', 1e-12);
            testCase.verifyEqual(p(3).Color, IndividualCMF.CONE_COLORS(3,:), ...
                'AbsTol', 1e-12);
        end

        function testConeColorsCanBeOverriddenPerCall(testCase)
            obs = IndividualCMF();
            fig = figure('Visible','off');
            cleanup = onCleanup(@() close(fig)); %#ok<NASGU>
            custom = [1 0 1; 0 1 1; 1 1 0];
            p = obs.plotLMS(Parent=axes(fig), ConeColors=custom);

            testCase.verifyEqual(p(1).Color, custom(1,:), 'AbsTol', 1e-12);
            testCase.verifyEqual(p(2).Color, custom(2,:), 'AbsTol', 1e-12);
            testCase.verifyEqual(p(3).Color, custom(3,:), 'AbsTol', 1e-12);
        end

        function testHoldStateIsRestoredByPlotMethods(testCase)
            % beginLinePlot turns hold on; finalizeLinePlot must put it back
            % so a caller's axes are left as they were found.
            obs = IndividualCMF();
            fig = figure('Visible','off');
            cleanup = onCleanup(@() close(fig)); %#ok<NASGU>
            ax = axes(fig);

            hold(ax, 'off');
            obs.plotLMS(Parent=ax);
            testCase.verifyFalse(ishold(ax), 'plotLMS must not leave hold on');

            hold(ax, 'on');
            obs.plotLMS(Parent=ax);
            testCase.verifyTrue(ishold(ax), "plotLMS must preserve a caller's hold on");
        end

    end
end

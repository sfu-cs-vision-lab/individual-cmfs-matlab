classdef CMFPlotter < handle
    % CMFPlotter  Visualization class for Color Matching Functions.
    %   The CMFPlotter class generates publication-quality plots for cone fundamentals,
    %   optical densities, and chromaticity diagrams derived from IndividualCMF objects.
    %
    %   All plotting methods return p (line handles) for customization.
    %   Exception: plotDiagnosticsPanel returns [p, ax] for multi-tile access.
    %
    %   CMFPlotter Methods:
    %       CMFPlotter              - Constructor to initialize the figure and layout.
    %       plotLMS                 - Plots L, M, and S cone fundamentals.
    %       plotRGBCMFs             - Plots RGB Color Matching Functions.
    %       plotChromaticity        - Plots the spectral locus on an rg-chromaticity diagram.
    %       plotAbsorbance          - Plots L, M, S photopigment absorbance spectra.
    %       plotAbsorptance         - Plots L, M, S retinal absorptance spectra.
    %       plotMacular             - Plots macular pigment optical density.
    %       plotLens                - Plots lens optical density.
    %       plotWithPeaks           - Plot fundamentals with lambda-max markers.
    %       compareLMS              - Compares two observers' fundamentals.
    %       compareMacular          - Compares two observers' macular density.
    %       compareLens             - Compares two observers' lens density.
    %       compareLMSQuantalEnergy - Overlays Quantal and Energy-based sensitivities.
    %       compareLDiff            - Plots the difference between L and M cones.
    %       plotDifference          - Visualize spectral differences between observers.
    %       plotMultiple            - Overlay fundamentals from multiple observers.
    %       plotDiagnosticsPanel    - Visualizes the full computational pipeline.
    %       highlightBand           - Add shaded spectral region to plot.
    %       exportFigure            - Save figure in publication-ready format.

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada
    %
    % This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    % Licensed under AGPL-3.0-or-later. See LICENSE file for details.
    % Repository: https://github.com/sfu-cs-vision-lab/Individual-CMFs

    % Figure Management Properties
    properties (SetAccess = private)
        Figure   matlab.ui.Figure
        Layout   matlab.graphics.layout.TiledChartLayout
        Rows     (1,1) double
        Cols     (1,1) double
        % True when this CMFPlotter constructed its own figure; false if
        % the caller supplied a parent container. Determines whether the
        % constructor sets figure-level properties (Visible, Position,
        % Color) -- caller-owned figures (especially Live Editor inline
        % targets) must be left alone.
        OwnsFigure (1,1) logical
    end

    % Style Configuration
    properties
        % Cone Colors - consolidated 3x3 matrix [L; M; S]
        ConeColors (3,3) double = [
            % L-cone (red)
            0.8, 0.0, 0.0
            % M-cone (green)
            0.0, 0.6, 0.0
            % S-cone (blue)
            0.0, 0.0, 0.8
        ]

        % Neutral color for single-trace plots
        NeutralColor (1,3) double = [0 0 0]

        % Line Styles with validation
        PrimaryLineStyle   (1,1) string {mustBeMember(PrimaryLineStyle, ...
            ["-", "--", ":", "-."])} = "-"
        SecondaryLineStyle (1,1) string {mustBeMember(SecondaryLineStyle, ...
            ["-", "--", ":", "-."])} = "--"

        % Default line width
        LineWidth (1,1) double {mustBePositive} = 1.5

        % Typography
        FontSize  (1,1) double {mustBePositive} = 11
        FontName  (1,1) string = "Helvetica"
    end

    % Wavelength Defaults
    properties (Constant)
        DEFAULT_WAVELENGTH = (360:1:830)'
        VISIBLE_RANGE = [380, 780]
    end

    % Derived Properties
    properties (Dependent, SetAccess = private)
        % Returns ConeColors(1,:)
        ColorL
        % Returns ConeColors(2,:)
        ColorM
        % Returns ConeColors(3,:)
        ColorS
        TileCount
    end

    methods
        % Dependent Property Getters
        function val = get.ColorL(obj)
            val = obj.ConeColors(1,:);
        end

        function val = get.ColorM(obj)
            val = obj.ConeColors(2,:);
        end

        function val = get.ColorS(obj)
            val = obj.ConeColors(3,:);
        end

        function val = get.TileCount(obj)
            val = obj.Rows * obj.Cols;
        end

        % Constructor
        function obj = CMFPlotter(rows, cols, options)
            % CMFPLOTTER  Create a tiled plotting canvas for CMF visualization.
            %
            %   plotter = CMFPlotter(rows, cols) creates a new figure with
            %       a tiled chart layout and owns figure-level properties
            %       (Visible, Position, Color). Use this form for standalone
            %       publication figures.
            %
            %   plotter = CMFPlotter(rows, cols, Parent=container) reuses an
            %       existing parent container, which may be:
            %         - a figure or uifigure handle
            %         - an existing TiledChartLayout (the plotter nests
            %           into it; rows / cols are ignored, the layout's
            %           existing geometry is used)
            %         - a uipanel or other graphics container that accepts
            %           a child tiledlayout
            %       When Parent is supplied, the constructor does NOT touch
            %       Visible, Position, or Color, so a Live Editor inline
            %       figure target is preserved.
            %
            %   OPTIONAL INPUTS (Name-Value arguments):
            %       Visible        (1,1) logical = true (only applied when this plotter owns the figure)
            %       Position       (1,4) double  = [100 100 1200 800] (only applied when this plotter owns the figure)
            %       Padding        (1,1) string  = "compact"
            %       TileSpacing    (1,1) string  = "compact"
            %       Title          (1,1) string  = "" (super-title)
            %       Parent         = [] (figure / uifigure / TiledChartLayout / uipanel)
            %       BackgroundColor (1,3) double = [1 1 1] (only applied when this plotter owns the figure)

            arguments
                rows (1,1) double {mustBeInteger, mustBePositive} = 1
                cols (1,1) double {mustBeInteger, mustBePositive} = 1
                options.Visible    (1,1) logical = true
                options.Position   (1,4) double  = [100, 100, 1200, 800]
                options.Padding    (1,1) string  {mustBeMember(options.Padding, ...
                    ["loose", "compact", "tight", "none"])} = "compact"
                options.TileSpacing (1,1) string {mustBeMember(options.TileSpacing, ...
                    ["loose", "compact", "tight", "none"])} = "compact"
                options.Title      (1,1) string  = ""
                options.Parent     = []
                options.BackgroundColor (1,3) double = [1 1 1]
            end

            obj.Rows = rows;
            obj.Cols = cols;

            if isempty(options.Parent)
                obj.Figure = figure( ...
                    Color=options.BackgroundColor, ...
                    Position=options.Position, ...
                    Visible=matlab.lang.OnOffSwitchState(options.Visible));
                obj.OwnsFigure = true;
                obj.Layout = tiledlayout(obj.Figure, rows, cols, ...
                    Padding=options.Padding, ...
                    TileSpacing=options.TileSpacing);
            elseif isa(options.Parent, 'matlab.graphics.layout.TiledChartLayout')
                obj.Layout = options.Parent;
                obj.Figure = ancestor(options.Parent, 'figure');
                obj.OwnsFigure = false;
            elseif isa(options.Parent, 'matlab.ui.Figure')
                obj.Figure = options.Parent;
                obj.OwnsFigure = false;
                obj.Layout = tiledlayout(obj.Figure, rows, cols, ...
                    Padding=options.Padding, ...
                    TileSpacing=options.TileSpacing);
            elseif isgraphics(options.Parent)
                % uipanel, uifigure, GridLayout, etc.
                obj.Figure = ancestor(options.Parent, 'figure');
                obj.OwnsFigure = false;
                obj.Layout = tiledlayout(options.Parent, rows, cols, ...
                    Padding=options.Padding, ...
                    TileSpacing=options.TileSpacing);
            else
                error('CMFPlotter:InvalidParent', ...
                    'Parent must be a figure, TiledChartLayout, uipanel, or other graphics container.');
            end

            if options.Title ~= ""
                title(obj.Layout, options.Title, FontSize=obj.FontSize + 4);
            end
        end

        % Single Observer Plots

        function [p, ax] = plotLMS(obj, observer, options)
            % PLOTLMS  Plot L, M, and S cone fundamentals.
            %
            %   p = plotter.plotLMS(observer) plots with defaults.
            %   p = plotter.plotLMS(observer, Name=Value) with customization.
            %
            %   Returns:
            %       p  - 3x1 array of line handles [L; M; S]
            %
            %   Options:
            %       Title      (1,1) string  = "Cone Fundamentals"
            %       Tile       (1,1) double  = [] (next available)
            %       Wavelength (:,1) double  = DEFAULT_WAVELENGTH
            %       YLim       (1,2) double  = [] (auto)
            %       ShowLegend (1,1) logical = true

            arguments
                obj
                observer (1,1) IndividualCMF
                options.Title      (1,1) string  = "Cone Fundamentals"
                options.Tile       double        = []
                options.Wavelength (:,1) double  = obj.DEFAULT_WAVELENGTH
                options.YLim       double        = []
                options.ShowLegend (1,1) logical = true
            end

            wl = options.Wavelength;
            LMS = observer.LMS(wl);

            ax = obj.getAxes(options.Tile);

            % An absent cone (Lod/Mod/Sod == 0; gene-deletion dichromacy)
            % is skipped: no line drawn, no legend entry. The returned
            % handle array keeps its 3x1 shape with gobjects placeholders
            % in the absent slots so downstream indexing stays stable.
            p = gobjects(3, 1);
            if observer.Lod > 0
                p(1) = plot(ax, wl, LMS(:,1), Color=obj.ColorL, DisplayName="L");
            end
            if observer.Mod > 0
                p(2) = plot(ax, wl, LMS(:,2), Color=obj.ColorM, DisplayName="M");
            end
            if observer.Sod > 0
                p(3) = plot(ax, wl, LMS(:,3), Color=obj.ColorS, DisplayName="S");
            end

            obj.applyDefaultStyle(ax, p(isgraphics(p)), options, YLabel="Sensitivity");
        end

        function [p, ax] = plotRGBCMFs(obj, observer, options)
            % PLOTRGBCMFS  Plots RGB Color Matching Functions.
            %   Note: The IndividualCMF object must have valid Primaries set.
            %
            %   Returns:
            %       p  - 3x1 array of line handles [R; G; B]

            arguments
                obj
                observer (1,1) IndividualCMF
                options.Title (1,1) string = "RGB CMFs"
                options.Tile double = []
                options.YLim double = []
                options.Wavelength (:,1) double = obj.DEFAULT_WAVELENGTH
                options.ShowLegend (1,1) logical = true
            end

            [RGB, wl] = observer.RGB(options.Wavelength);

            ax = obj.getAxes(options.Tile);

            p = gobjects(3, 1);
            p(1) = plot(ax, wl, RGB(:,1), Color=obj.ColorL, DisplayName="R");
            p(2) = plot(ax, wl, RGB(:,2), Color=obj.ColorM, DisplayName="G");
            p(3) = plot(ax, wl, RGB(:,3), Color=obj.ColorS, DisplayName="B");

            obj.applyDefaultStyle(ax, p, options, YLabel="Tristimulus Value", XLim=[375, 725]);
        end

        function [p, ax] = plotChromaticity(obj, observer, options)
            % PLOTCHROMATICITY  Plots the spectral locus on an lm-chromaticity diagram.
            %
            %   Coordinates are projective normalisations of the
            %   energy-unit, peak-normalized LMS cone fundamentals
            %   (l = L/(L+M+S), m = M/(L+M+S)), per CIE 170-2:2015. The
            %   observer's current OutputFormat / LogOutput /
            %   NormalizeOutput are ignored: chromaticity is invariant
            %   under those choices, so this method always reports the
            %   same locus regardless of how the observer is configured
            %   for direct LMS readouts. Matches IndividualCMF.lmChromaticity.
            %
            %   Returns:
            %       p  - Line handle for the locus (markers are separate)

            arguments
                obj
                observer (1,1) IndividualCMF
                options.Title (1,1) string = "Chromaticity"
                options.Tile double = []
                options.Wavelength (:,1) double = obj.DEFAULT_WAVELENGTH
                options.ShowMarkers (1,1) logical = true
                options.MarkerInterval (1,1) double = 20
                options.ShowLegend (1,1) logical = false
            end

            wl = options.Wavelength;
            % Delegate the lm-chromaticity math to the observer so the
            % plotter and the IndividualCMF method always agree, including
            % under non-default OutputFormat / LogOutput state.
            lm = observer.lmChromaticity(wl);

            ax = obj.getAxes(options.Tile);
            hold(ax, 'on');

            r = lm(:, 1);
            g = lm(:, 2);

            % Plot locus
            pLocus = plot(ax, r, g, 'k-', DisplayName="Spectrum Locus");

            % Add markers and collect all handles
            if options.ShowMarkers
                step = wl(2) - wl(1);
                stride = max(1, round(options.MarkerInterval / step));
                idx = 1:stride:length(wl);
                pMarkers = plot(ax, r(idx), g(idx), 'ro', MarkerSize=5, MarkerFaceColor="r", ...
                    HandleVisibility="off");
                p = [pLocus; pMarkers];
            else
                p = pLocus;
            end

            % Apply style but override some defaults for chromaticity
            set(pLocus, LineWidth=obj.LineWidth);
            ax.FontSize = obj.FontSize;
            ax.FontName = char(obj.FontName);
            ax.Box ="on";
            ax.XGrid ="on";
            ax.YGrid ="on";
            xlim(ax, [0 1]);
            xlabel(ax, 'l / (l+m+s)', FontSize=obj.FontSize);
            ylabel(ax, 'm / (l+m+s)', FontSize=obj.FontSize);
            if options.Title ~= ""
                title(ax, options.Title, FontSize=obj.FontSize + 2, FontWeight="bold");
            end
            if options.ShowLegend
                obj.applyDefaultLegend(ax);
            end
        end

        function [p, ax] = plotAbsorbance(obj, observer, options)
            % PLOTABSORBANCE  Plots L, M, S photopigment absorbance spectra.
            %   Shows the raw absorbance templates before self-screening or filtering.
            %
            %   Returns:
            %       p  - 3x1 array of line handles [L; M; S]

            arguments
                obj
                observer (1,1) IndividualCMF
                options.Title (1,1) string = "Photopigment Absorbance"
                options.Tile double = []
                options.YLim double = []
                options.Wavelength (:,1) double = obj.DEFAULT_WAVELENGTH
                options.Log (1,1) logical = false
                options.ShowLegend (1,1) logical = true
            end

            wl = options.Wavelength;

            LMS = observer.LMS(wl, ...
                OutputFormat="absorbance", LogOutput=options.Log, NormalizeOutput=false);

            ax = obj.getAxes(options.Tile);

            % Skip absent cones (see plotLMS for rationale).
            p = gobjects(3, 1);
            if observer.Lod > 0
                p(1) = plot(ax, wl, LMS(:,1), Color=obj.ColorL, DisplayName="L");
            end
            if observer.Mod > 0
                p(2) = plot(ax, wl, LMS(:,2), Color=obj.ColorM, DisplayName="M");
            end
            if observer.Sod > 0
                p(3) = plot(ax, wl, LMS(:,3), Color=obj.ColorS, DisplayName="S");
            end

            if options.Log
                yLabel = "Log Absorbance";
            else
                yLabel = "Absorbance";
            end

            obj.applyDefaultStyle(ax, p(isgraphics(p)), options, YLabel=yLabel);
        end

        function [p, ax] = plotAbsorptance(obj, observer, options)
            % PLOTABSORPTANCE  Plots L, M, S retinal absorptance spectra.
            %   Shows cone sensitivity after self-screening but before pre-receptoral filtering.
            %
            %   Returns:
            %       p  - 3x1 array of line handles [L; M; S]

            arguments
                obj
                observer (1,1) IndividualCMF
                options.Title (1,1) string = "Retinal Absorptance"
                options.Tile double = []
                options.YLim double = []
                options.Wavelength (:,1) double = obj.DEFAULT_WAVELENGTH
                options.Log (1,1) logical = false
                options.ShowLegend (1,1) logical = true
            end

            wl = options.Wavelength;

            LMS = observer.LMS(wl, ...
                OutputFormat="absorptance", LogOutput=options.Log, NormalizeOutput=true);

            ax = obj.getAxes(options.Tile);

            % Skip absent cones (see plotLMS for rationale).
            p = gobjects(3, 1);
            if observer.Lod > 0
                p(1) = plot(ax, wl, LMS(:,1), Color=obj.ColorL, DisplayName="L");
            end
            if observer.Mod > 0
                p(2) = plot(ax, wl, LMS(:,2), Color=obj.ColorM, DisplayName="M");
            end
            if observer.Sod > 0
                p(3) = plot(ax, wl, LMS(:,3), Color=obj.ColorS, DisplayName="S");
            end

            if options.Log
                yLabel = "Log Absorptance";
            else
                yLabel = "Absorptance";
            end

            obj.applyDefaultStyle(ax, p(isgraphics(p)), options, YLabel=yLabel);
        end

        function [p, ax] = plotMacular(obj, observer, options)
            % PLOTMACULAR  Plots the macular pigment optical density spectrum.
            %
            %   Returns:
            %       p  - Line handle

            arguments
                obj
                observer (1,1) IndividualCMF
                options.Title (1,1) string = "Macular Density"
                options.Tile double = []
                options.YLim double = []
                options.Wavelength (:,1) double = obj.DEFAULT_WAVELENGTH
                options.ShowLegend (1,1) logical = true
            end

            wl = options.Wavelength;
            mac = PreReceptoralFilter.macularTemplate(wl) * (observer.MacularDensity / 0.35);

            ax = obj.getAxes(options.Tile);

            p = plot(ax, wl, mac, Color=obj.NeutralColor, DisplayName="Macular");

            obj.applyDefaultStyle(ax, p, options, YLabel="Optical Density");
        end

        function [p, ax] = plotLens(obj, observer, options)
            % PLOTLENS  Plots the lens optical density spectrum.
            %
            %   The lens density spectrum is computed from the observer's LensModel
            %   template scaled by the observer's LensDensity property.
            %
            %   Returns:
            %       p  - Line handle

            arguments
                obj
                observer (1,1) IndividualCMF
                options.Title (1,1) string = "Lens Density"
                options.Tile double = []
                options.YLim double = []
                options.Wavelength (:,1) double = obj.DEFAULT_WAVELENGTH
                options.ShowLegend (1,1) logical = true
            end

            wl = options.Wavelength;
            lens = observer.getLensDensitySpectrum(wl);

            ax = obj.getAxes(options.Tile);

            p = plot(ax, wl, lens, Color=obj.NeutralColor, DisplayName="Lens");

            obj.applyDefaultStyle(ax, p, options, YLabel="Optical Density");
        end

        function [p, ax] = plotWithPeaks(obj, observer, options)
            % PLOTWITHPEAKS  Plot fundamentals with lambda-max markers.
            %
            %   Returns:
            %       p  - 3x1 array of line handles [L; M; S]
            %
            %   Options:
            %       ShowLabels (1,1) logical = true - Label peak wavelengths

            arguments
                obj
                observer (1,1) IndividualCMF
                options.Title (1,1) string = "Cone Fundamentals with Peaks"
                options.Tile double = []
                options.Wavelength (:,1) double = obj.DEFAULT_WAVELENGTH
                options.YLim double = []
                options.ShowLabels (1,1) logical = true
                options.ShowLegend (1,1) logical = true
            end

            wl = options.Wavelength;
            LMS = observer.LMS(wl);

            ax = obj.getAxes(options.Tile);

            p = gobjects(3, 1);
            p(1) = plot(ax, wl, LMS(:,1), Color=obj.ColorL, DisplayName="L");
            p(2) = plot(ax, wl, LMS(:,2), Color=obj.ColorM, DisplayName="M");
            p(3) = plot(ax, wl, LMS(:,3), Color=obj.ColorS, DisplayName="S");

            % Find and mark peaks - getPeak requires coneType argument
            colors = {obj.ColorL, obj.ColorM, obj.ColorS};

            for i = 1:3
                % Find peak from data directly
                [peakVal, peakIdx] = max(LMS(:, i));
                peakWl = wl(peakIdx);

                hold(ax, 'on');
                plot(ax, peakWl, peakVal, 'o', Color=colors{i}, ...
                    MarkerSize=8, MarkerFaceColor=colors{i}, ...
                    HandleVisibility="off");

                if options.ShowLabels
                    text(ax, peakWl, peakVal + 0.05, sprintf('%.0f nm', peakWl), ...
                        HorizontalAlignment="center", FontSize=obj.FontSize - 2, ...
                        Color=colors{i});
                end
            end

            obj.applyDefaultStyle(ax, p, options, YLabel="Sensitivity");
        end

        % Comparison Plots

        function [p, ax] = compareLMS(obj, ref, comp, options)
            % COMPARELMS  Compares LMS fundamentals between two observers.
            %   Solid lines = Reference, Dashed lines = Comparison.
            %
            %   Returns:
            %       p  - 6x1 array of line handles [Lref; Mref; Sref; Lcomp; Mcomp; Scomp]

            arguments
                obj
                ref (1,1) IndividualCMF
                comp (1,1) IndividualCMF
                options.Title (1,1) string = "LMS Comparison"
                options.Tile double = []
                options.YLim double = []
                options.Wavelength (:,1) double = obj.DEFAULT_WAVELENGTH
                options.ShowLegend (1,1) logical = true
            end

            wl = options.Wavelength;
            LMS1 = ref.LMS(wl);
            LMS2 = comp.LMS(wl);

            ax = obj.getAxes(options.Tile);

            p = gobjects(6, 1);
            % Reference traces (solid)
            p(1) = plot(ax, wl, LMS1(:,1), Color=obj.ColorL, ...
                LineStyle=obj.PrimaryLineStyle, DisplayName="L");
            p(2) = plot(ax, wl, LMS1(:,2), Color=obj.ColorM, ...
                LineStyle=obj.PrimaryLineStyle, DisplayName="M");
            p(3) = plot(ax, wl, LMS1(:,3), Color=obj.ColorS, ...
                LineStyle=obj.PrimaryLineStyle, DisplayName="S");

            % Comparison traces (dashed)
            p(4) = plot(ax, wl, LMS2(:,1), Color=obj.ColorL, ...
                LineStyle=obj.SecondaryLineStyle, DisplayName="L'");
            p(5) = plot(ax, wl, LMS2(:,2), Color=obj.ColorM, ...
                LineStyle=obj.SecondaryLineStyle, DisplayName="M'");
            p(6) = plot(ax, wl, LMS2(:,3), Color=obj.ColorS, ...
                LineStyle=obj.SecondaryLineStyle, DisplayName="S'");

            obj.applyDefaultStyle(ax, p, options, YLabel="Sensitivity");
        end

        function [p, ax] = compareRGBCMFs(obj, ref, comp, options)
            % COMPARERGBCMFS  Compares RGB CMFs between two observers.
            %   Solid lines = Reference, Dashed lines = Comparison.
            %   Both observers must have valid Primaries set.
            %
            %   Returns:
            %       p  - 6x1 array of line handles [Rref; Gref; Bref; Rcomp; Gcomp; Bcomp]

            arguments
                obj
                ref (1,1) IndividualCMF
                comp (1,1) IndividualCMF
                options.Title (1,1) string = "RGB CMF Comparison"
                options.Tile double = []
                options.YLim double = []
                options.Wavelength (:,1) double = obj.DEFAULT_WAVELENGTH
                options.ShowLegend (1,1) logical = true
            end

            wl = options.Wavelength;
            RGB1 = ref.RGB(wl);
            RGB2 = comp.RGB(wl);

            ax = obj.getAxes(options.Tile);

            p = gobjects(6, 1);
            % Reference traces (solid)
            p(1) = plot(ax, wl, RGB1(:,1), Color=obj.ColorL, ...
                LineStyle=obj.PrimaryLineStyle, DisplayName="R");
            p(2) = plot(ax, wl, RGB1(:,2), Color=obj.ColorM, ...
                LineStyle=obj.PrimaryLineStyle, DisplayName="G");
            p(3) = plot(ax, wl, RGB1(:,3), Color=obj.ColorS, ...
                LineStyle=obj.PrimaryLineStyle, DisplayName="B");

            % Comparison traces (dashed)
            p(4) = plot(ax, wl, RGB2(:,1), Color=obj.ColorL, ...
                LineStyle=obj.SecondaryLineStyle, DisplayName="R'");
            p(5) = plot(ax, wl, RGB2(:,2), Color=obj.ColorM, ...
                LineStyle=obj.SecondaryLineStyle, DisplayName="G'");
            p(6) = plot(ax, wl, RGB2(:,3), Color=obj.ColorS, ...
                LineStyle=obj.SecondaryLineStyle, DisplayName="B'");

            obj.applyDefaultStyle(ax, p, options, YLabel="Tristimulus Value", XLim=[375, 725]);
        end

        function [p, ax] = compareMacular(obj, ref, comp, options)
            % COMPAREMACULAR  Compares macular pigment density between two observers.
            %
            %   Returns:
            %       p  - 2x1 array of line handles [ref; comp]

            arguments
                obj
                ref (1,1) IndividualCMF
                comp (1,1) IndividualCMF
                options.Title (1,1) string = "Macular Density Comparison"
                options.Tile double = []
                options.YLim double = []
                options.Wavelength (:,1) double = obj.DEFAULT_WAVELENGTH
                options.ShowLegend (1,1) logical = true
            end

            wl = options.Wavelength;
            mac1 = PreReceptoralFilter.macularTemplate(wl) * (ref.MacularDensity / 0.35);
            mac2 = PreReceptoralFilter.macularTemplate(wl) * (comp.MacularDensity / 0.35);

            ax = obj.getAxes(options.Tile);

            p = gobjects(2, 1);
            p(1) = plot(ax, wl, mac1, Color=obj.NeutralColor, ...
                LineStyle=obj.PrimaryLineStyle, DisplayName="Macular (Ref)");
            p(2) = plot(ax, wl, mac2, Color=obj.NeutralColor, ...
                LineStyle=obj.SecondaryLineStyle, DisplayName="Macular (Comp)");

            obj.applyDefaultStyle(ax, p, options, YLabel="Optical Density");
        end

        function [p, ax] = compareLens(obj, ref, comp, options)
            % COMPARELENS  Compares lens optical density between two observers.
            %
            %   The lens density spectra are computed from each observer's LensModel
            %   template scaled by the observer's LensDensity property.
            %
            %   Returns:
            %       p  - 2x1 array of line handles [ref; comp]

            arguments
                obj
                ref (1,1) IndividualCMF
                comp (1,1) IndividualCMF
                options.Title (1,1) string = "Lens Density Comparison"
                options.Tile double = []
                options.YLim double = []
                options.Wavelength (:,1) double = obj.DEFAULT_WAVELENGTH
                options.ShowLegend (1,1) logical = true
            end

            wl = options.Wavelength;
            lens1 = ref.getLensDensitySpectrum(wl);
            lens2 = comp.getLensDensitySpectrum(wl);

            ax = obj.getAxes(options.Tile);

            p = gobjects(2, 1);
            p(1) = plot(ax, wl, lens1, Color=obj.NeutralColor, ...
                LineStyle=obj.PrimaryLineStyle, DisplayName="Lens (Ref)");
            p(2) = plot(ax, wl, lens2, Color=obj.NeutralColor, ...
                LineStyle=obj.SecondaryLineStyle, DisplayName="Lens (Comp)");

            obj.applyDefaultStyle(ax, p, options, YLabel="Optical Density");
        end

        function [p, ax] = compareLMSQuantalEnergy(obj, observer, options)
            % COMPARELMSQUANTALENERGY  Overlays Quantal and Energy-based sensitivities.
            %   This plots both Quantal (photon) and Energy-based units for a single
            %   observer to visualize the lambda-shift effect.
            %
            %   Returns:
            %       p  - 6x1 array of line handles [Lq; Mq; Sq; Le; Me; Se]

            arguments
                obj
                observer (1,1) IndividualCMF
                options.Title (1,1) string = "Quantal vs Energy"
                options.Tile double = []
                options.YLim double = []
                options.Wavelength (:,1) double = obj.DEFAULT_WAVELENGTH
                options.ShowLegend (1,1) logical = true
            end

            wl = options.Wavelength;

            % Force LogOutput=false: the axis is labeled "Sensitivity" (linear).
            LMS_Quantal = observer.LMS(wl, OutputFormat="quantal", LogOutput=false);
            LMS_Energy  = observer.LMS(wl, OutputFormat="energy",  LogOutput=false);

            ax = obj.getAxes(options.Tile);

            % Skip absent cones in both the Quantal and Energy traces
            % (see plotLMS for rationale).
            p = gobjects(6, 1);
            if observer.Lod > 0
                p(1) = plot(ax, wl, LMS_Quantal(:,1), Color=obj.ColorL, ...
                    LineStyle=obj.PrimaryLineStyle, DisplayName="Lq");
                p(4) = plot(ax, wl, LMS_Energy(:,1), Color=obj.ColorL, ...
                    LineStyle=obj.SecondaryLineStyle, DisplayName="Le");
            end
            if observer.Mod > 0
                p(2) = plot(ax, wl, LMS_Quantal(:,2), Color=obj.ColorM, ...
                    LineStyle=obj.PrimaryLineStyle, DisplayName="Mq");
                p(5) = plot(ax, wl, LMS_Energy(:,2), Color=obj.ColorM, ...
                    LineStyle=obj.SecondaryLineStyle, DisplayName="Me");
            end
            if observer.Sod > 0
                p(3) = plot(ax, wl, LMS_Quantal(:,3), Color=obj.ColorS, ...
                    LineStyle=obj.PrimaryLineStyle, DisplayName="Sq");
                p(6) = plot(ax, wl, LMS_Energy(:,3), Color=obj.ColorS, ...
                    LineStyle=obj.SecondaryLineStyle, DisplayName="Se");
            end

            obj.applyDefaultStyle(ax, p(isgraphics(p)), options, YLabel="Sensitivity");
        end

        function [p, ax] = compareLDiff(obj, ref, comp, options)
            % COMPARELDIFF  Plots the difference between L and M cone sensitivities.
            %
            %   Returns:
            %       p  - 2x1 array of line handles [ref; comp]

            arguments
                obj
                ref (1,1) IndividualCMF
                comp (1,1) IndividualCMF
                options.Title (1,1) string = "L - M Difference"
                options.Tile double = []
                options.YLim double = []
                options.Wavelength (:,1) double = obj.DEFAULT_WAVELENGTH
                options.ShowLegend (1,1) logical = true
            end

            wl = options.Wavelength;
            LMS1 = ref.LMS(wl);
            LMS2 = comp.LMS(wl);

            ax = obj.getAxes(options.Tile);

            L1 = LMS1(:,1); M1 = LMS1(:,2);
            L2 = LMS2(:,1); M2 = LMS2(:,2);

            p = gobjects(2, 1);
            p(1) = plot(ax, wl, L1-M1, Color=obj.NeutralColor, ...
                LineStyle=obj.PrimaryLineStyle, DisplayName="L-M (Ref)");
            p(2) = plot(ax, wl, L2-M2, Color=obj.NeutralColor, ...
                LineStyle=obj.SecondaryLineStyle, DisplayName="L-M (Comp)");

            obj.applyDefaultStyle(ax, p, options, YLabel="Sensitivity Difference");
        end

        function [p, ax] = plotDifference(obj, ref, comp, options)
            % PLOTDIFFERENCE  Visualize spectral differences between observers.
            %
            %   Returns:
            %       p  - Array of line handles (one per cone plotted)
            %
            %   Options:
            %       Cones     (1,:) string  = ["L", "M", "S"] - Which cones
            %       Normalize (1,1) logical = false - Plot % difference
            %       ZeroLine  (1,1) logical = true - Show y=0 line

            arguments
                obj
                ref (1,1) IndividualCMF
                comp (1,1) IndividualCMF
                options.Title (1,1) string = "Spectral Difference"
                options.Tile double = []
                options.Wavelength (:,1) double = obj.DEFAULT_WAVELENGTH
                options.YLim double = []
                options.Cones (1,:) string {mustBeMember(options.Cones, ["L", "M", "S"])} = ["L", "M", "S"]
                options.Normalize (1,1) logical = false
                options.ZeroLine (1,1) logical = true
                options.ShowLegend (1,1) logical = true
            end

            wl = options.Wavelength;
            LMS_ref = ref.LMS(wl);
            LMS_comp = comp.LMS(wl);

            ax = obj.getAxes(options.Tile);

            coneIdx = struct('L', 1, 'M', 2, 'S', 3);
            colors = {obj.ColorL, obj.ColorM, obj.ColorS};

            nCones = numel(options.Cones);
            p = gobjects(nCones, 1);

            for i = 1:nCones
                cone = options.Cones(i);
                idx = coneIdx.(cone);

                diff = LMS_ref(:, idx) - LMS_comp(:, idx);

                if options.Normalize
                    % Percentage difference relative to reference
                    refVals = LMS_ref(:, idx);
                    refVals(refVals == 0) = NaN;
                    diff = 100 * diff ./ refVals;
                end

                p(i) = plot(ax, wl, diff, Color=colors{idx}, DisplayName=char(cone));
            end

            if options.ZeroLine
                plot(ax, [wl(1), wl(end)], [0, 0], 'k--', LineWidth=0.5, ...
                    HandleVisibility="off");
            end

            if options.Normalize
                yLabel = "Difference (%)";
            else
                yLabel = "Difference (Ref - Comp)";
            end

            obj.applyDefaultStyle(ax, p, options, YLabel=yLabel);
        end

        function [p, ax] = plotMultiple(obj, observers, options)
            % PLOTMULTIPLE  Overlay fundamentals from multiple observers.
            %
            %   Returns:
            %       p  - Array of line handles
            %
            %   Options:
            %       Labels   (1,:) string = [] - Legend labels
            %       Cone     (1,1) string = "all" - "L", "M", "S", or "all"
            %       ColorMap (1,1) string = "lines" - MATLAB colormap

            arguments
                obj
                observers (1,:) cell
                options.Title (1,1) string = "Multiple Observers"
                options.Tile double = []
                options.Wavelength (:,1) double = obj.DEFAULT_WAVELENGTH
                options.YLim double = []
                options.Labels (1,:) string = string.empty
                options.Cone (1,1) string {mustBeMember(options.Cone, ["L", "M", "S", "all"])} = "all"
                options.ColorMap (1,1) string = "lines"
                options.ShowLegend (1,1) logical = true
            end

            wl = options.Wavelength;
            nObs = numel(observers);

            ax = obj.getAxes(options.Tile);

            % Get colormap
            if options.ColorMap == "lines"
                cmap = lines(nObs);
            else
                cmapFn = str2func(options.ColorMap);
                cmap = cmapFn(nObs);
            end

            % Generate labels if not provided
            if isempty(options.Labels)
                labels = "Observer " + (1:nObs);
            else
                labels = options.Labels;
            end

            coneIdx = struct('L', 1, 'M', 2, 'S', 3);

            if options.Cone == "all"
                p = gobjects(nObs * 3, 1);
                pIdx = 0;
            else
                p = gobjects(nObs, 1);
            end

            for i = 1:nObs
                obs = observers{i};
                if ~isa(obs, 'IndividualCMF')
                    error('CMFPlotter:InvalidInput', 'All elements must be IndividualCMF instances.');
                end

                LMS = obs.LMS(wl);

                if options.Cone == "all"
                    % Plot all cones with same color per observer
                    pIdx = pIdx + 1;
                    p(pIdx) = plot(ax, wl, LMS(:,1), '-', Color=cmap(i,:), ...
                        DisplayName=labels(i) + " L");
                    pIdx = pIdx + 1;
                    p(pIdx) = plot(ax, wl, LMS(:,2), '--', Color=cmap(i,:), ...
                        DisplayName=labels(i) + " M");
                    pIdx = pIdx + 1;
                    p(pIdx) = plot(ax, wl, LMS(:,3), ':', Color=cmap(i,:), ...
                        DisplayName=labels(i) + " S");
                else
                    idx = coneIdx.(options.Cone);
                    p(i) = plot(ax, wl, LMS(:,idx), '-', Color=cmap(i,:), ...
                        DisplayName=labels(i));
                end
            end

            obj.applyDefaultStyle(ax, p, options, YLabel="Sensitivity");
        end

        % Diagnostics Panel

        function [p, ax] = plotDiagnosticsPanel(obj, observer, options)
            % PLOTDIAGNOSTICSPANEL  Visualizes the full computational pipeline across 3 tiles.
            %   Plots Absorbance -> Absorptance -> Corneal Sensitivity for an observer.
            %   Requires a CMFPlotter initialized with at least 3 available tiles.
            %
            %   Returns:
            %       p  - Cell array of line handles {p1, p2, p3}
            %       ax - Array of axes handles [ax1; ax2; ax3]

            arguments
                obj
                observer (1,1) IndividualCMF
                options.Wavelength (:,1) double = obj.DEFAULT_WAVELENGTH
            end

            wl = options.Wavelength;

            % Force LogOutput=false: every panel below is labeled with linear
            % units (Absorbance / Absorptance / Sensitivity).
            ax = gobjects(3, 1);
            p = cell(3, 1);

            % 1. Absorbance
            LMS_abs = observer.LMS(wl, ...
                OutputFormat="absorbance", LogOutput=false, NormalizeOutput=false);

            ax(1) = obj.getAxes([]);
            p{1} = gobjects(3, 1);
            p{1}(1) = plot(ax(1), wl, LMS_abs(:,1), Color=obj.ColorL, DisplayName="L");
            p{1}(2) = plot(ax(1), wl, LMS_abs(:,2), Color=obj.ColorM, DisplayName="M");
            p{1}(3) = plot(ax(1), wl, LMS_abs(:,3), Color=obj.ColorS, DisplayName="S");
            obj.applyDefaultStyle(ax(1), p{1}, struct('Title', "1. Pigment Absorbance", 'ShowLegend', true), YLabel="Absorbance");

            % 2. Absorptance
            LMS_ret = observer.LMS(wl, ...
                OutputFormat="absorptance", LogOutput=false, NormalizeOutput=true);

            ax(2) = obj.getAxes([]);
            p{2} = gobjects(3, 1);
            p{2}(1) = plot(ax(2), wl, LMS_ret(:,1), Color=obj.ColorL, DisplayName="L");
            p{2}(2) = plot(ax(2), wl, LMS_ret(:,2), Color=obj.ColorM, DisplayName="M");
            p{2}(3) = plot(ax(2), wl, LMS_ret(:,3), Color=obj.ColorS, DisplayName="S");
            obj.applyDefaultStyle(ax(2), p{2}, struct('Title', "2. Retinal Absorptance", 'ShowLegend', true, YLim=[0 1.1]), YLabel="Absorptance");

            % 3. Corneal Sensitivity
            LMS_sens = observer.LMS(wl, ...
                OutputFormat="energy", LogOutput=false, NormalizeOutput=true);

            ax(3) = obj.getAxes([]);
            p{3} = gobjects(3, 1);
            p{3}(1) = plot(ax(3), wl, LMS_sens(:,1), Color=obj.ColorL, DisplayName="L");
            p{3}(2) = plot(ax(3), wl, LMS_sens(:,2), Color=obj.ColorM, DisplayName="M");
            p{3}(3) = plot(ax(3), wl, LMS_sens(:,3), Color=obj.ColorS, DisplayName="S");
            obj.applyDefaultStyle(ax(3), p{3}, struct('Title', "3. Corneal Sensitivity", 'ShowLegend', true, YLim=[0 1.1]), YLabel="Sensitivity");
        end

        % Utilities

        function p = highlightBand(obj, ax, bandStart, bandEnd, options)
            % HIGHLIGHTBAND  Add shaded spectral region to plot.
            %
            %   Returns:
            %       p  - Patch handle
            %
            %   Options:
            %       Color (1,3) double = [0.9 0.9 0.9]
            %       Alpha (1,1) double = 0.3
            %       Label (1,1) string = ""

            arguments
                obj
                ax (1,1) matlab.graphics.axis.Axes
                bandStart (1,1) double
                bandEnd (1,1) double
                options.Color (1,3) double = [0.9 0.9 0.9]
                options.Alpha (1,1) double {mustBeInRange(options.Alpha, 0, 1)} = 0.3
                options.Label (1,1) string = ""
            end

            yLimits = ylim(ax);

            % Create patch
            xPatch = [bandStart, bandEnd, bandEnd, bandStart];
            yPatch = [yLimits(1), yLimits(1), yLimits(2), yLimits(2)];

            hold(ax, 'on');
            p = patch(ax, xPatch, yPatch, options.Color, ...
                FaceAlpha=options.Alpha, ...
                EdgeColor="none", ...
                HandleVisibility="off");

            % Send to back
            uistack(p, 'bottom');

            if options.Label ~= ""
                midX = (bandStart + bandEnd) / 2;
                text(ax, midX, yLimits(2) * 0.95, options.Label, ...
                    HorizontalAlignment="center", ...
                    FontSize=obj.FontSize - 2, ...
                    FontName=obj.FontName);
            end
        end

        function exportFigure(obj, filename, options)
            % EXPORTFIGURE  Save in publication-ready format.
            %
            %   Options:
            %       Format     (1,1) string = "pdf" - pdf/eps/svg/png/tiff
            %       Resolution (1,1) double = 300 - DPI for raster
            %       Width      (1,1) double = 6 - inches
            %       Height     (1,1) double = 4 - inches

            arguments
                obj
                filename (1,1) string
                options.Format (1,1) string {mustBeMember(options.Format, ...
                    ["pdf", "eps", "svg", "png", "tiff"])} = "pdf"
                options.Resolution (1,1) double {mustBePositive} = 300
                options.Width (1,1) double {mustBePositive} = 6
                options.Height (1,1) double {mustBePositive} = 4
            end

            % Set paper size
            set(obj.Figure, PaperUnits="inches");
            set(obj.Figure, PaperSize=[options.Width, options.Height]);
            set(obj.Figure, PaperPosition=[0, 0, options.Width, options.Height]);

            % Export based on format
            switch options.Format
                case "pdf"
                    print(obj.Figure, filename, '-dpdf');
                case "eps"
                    print(obj.Figure, filename, '-depsc');
                case "svg"
                    print(obj.Figure, filename, '-dsvg');
                case "png"
                    print(obj.Figure, filename, '-dpng', sprintf('-r%d', options.Resolution));
                case "tiff"
                    print(obj.Figure, filename, '-dtiff', sprintf('-r%d', options.Resolution));
            end
        end
    end

    % Private Helper Methods
    methods (Access = private)

        function ax = getAxes(obj, tileIndex)
            % GETAXES  Get axes handle for plotting.

            arguments
                obj
                tileIndex double = []
            end

            if isempty(tileIndex)
                ax = nexttile(obj.Layout);
            else
                ax = nexttile(obj.Layout, tileIndex);
            end
            cla(ax);
            hold(ax, 'on');
        end

        function applyDefaultStyle(obj, ax, p, options, extraOptions)
            % APPLYDEFAULTSTYLE  Apply consistent default styling to plot.
            %
            %   This helper applies a uniform style to all plots:
            %   - Line properties (width)
            %   - Axes properties (font, grid, box)
            %   - Title formatting
            %   - Legend (if enabled)
            %   - Axis limits

            arguments
                obj
                ax (1,1) matlab.graphics.axis.Axes
                p
                options struct
                extraOptions.YLabel (1,1) string = ""
                extraOptions.XLabel (1,1) string = "Wavelength (nm)"
                extraOptions.XLim (1,2) double = [355, 835]
            end

            % Line defaults
            set(p, LineWidth=obj.LineWidth);

            % Axes defaults
            ax.FontSize = obj.FontSize;
            ax.FontName = char(obj.FontName);
            ax.Box ="on";
            ax.XGrid ="on";
            ax.YGrid ="on";

            % Labels
            xlabel(ax, extraOptions.XLabel, FontSize=obj.FontSize);
            if extraOptions.YLabel ~= ""
                ylabel(ax, extraOptions.YLabel, FontSize=obj.FontSize);
            end

            % X limits
            xlim(ax, extraOptions.XLim);

            % Title
            if isfield(options, 'Title') && options.Title ~= ""
                title(ax, options.Title, FontSize=obj.FontSize + 2, FontWeight="bold");
            end

            % Y limits
            if isfield(options, 'YLim') && ~isempty(options.YLim)
                ylim(ax, options.YLim);
            end

            % Legend
            showLegend = true;
            if isfield(options, 'ShowLegend')
                showLegend = options.ShowLegend;
            end
            if showLegend
                obj.applyDefaultLegend(ax);
            end

            % Restore hold-off so a follow-on caller drawing bare plot()
            % into gcf does not accumulate on top of this method's traces.
            % getAxes() turns hold on for multi-line plotting; we undo it
            % at the boundary so the axes are inert for downstream code.
            hold(ax, 'off');
        end

        function applyDefaultLegend(obj, ax)
            % APPLYDEFAULTLEGEND  Apply default legend styling.

            legend(ax, 'show');
            lgd = legend(ax);
            lgd.Location ="best";
            lgd.FontSize = obj.FontSize - 1;
            lgd.Box ="off";
        end
    end

end

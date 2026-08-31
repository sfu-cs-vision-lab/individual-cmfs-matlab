%[text] # Example 18: Publication-Quality Figures
%[text] This example covers the mechanics of building a multi-panel figure and writing it to a file. The scientific content it draws on comes from the earlier examples.
%[text] Figures are composed with MATLAB's own `tiledlayout` and `nexttile`. The plot methods that draw a single set of axes accept a `Parent` argument, so passing it `nexttile()` places that plot in the next tile. `plotDiagnostics` is the exception, since it draws three panels of its own and takes the layout rather than a tile. Figures are written to file with `exportgraphics`.
%[text] **Time:** about 8 minutes.
exampleDefaults();
%%
%[text] ## Suggested settings
%[text:table]
%[text] | Element | Recommended setting |
%[text] | --- | --- |
%[text] | Title | 12-14 pt |
%[text] | Axis labels | 10-12 pt |
%[text] | Tick labels | 9-11 pt |
%[text] | Legend | 9-10 pt |
%[text] | Data lines | 1\.5-2 pt |
%[text] | Reference lines | 0\.5-1 pt |
%[text] | Axes | 1 pt |
%[text] | Cone colours | `IndividualCMF.CONE_COLORS` rows L, M, S. Override per call with `ConeColors=` |
%[text] | Vector export | PDF, SVG or EPS, through `exportgraphics` |
%[text] | Raster export | `Resolution=300` or higher |
%[text] | Single-column width | 3\.25-3.5 in (83-89 mm) |
%[text] | Double-column width | 6\.5-7 in (165-178 mm) |
%[text:table]
%%
%[text] ## Two ways of drawing
%[text] - **Drawing inline.** For a single panel in a Live Script section, call a plot method without creating a figure. It draws into the current axes, so the Live Editor captures the result under that section.
%[text] - **Drawing a standalone figure.** For a composite that will be exported, call `figure`, then `tiledlayout` and `nexttile`, and pass each tile to a plot method through `Parent=`. These open a figure window of their own. \
%[text] The section below draws inline. Note that `exampleDefaults` sets graphics defaults on the MATLAB root. Those persist for the session and affect every figure drawn afterwards, including ones unrelated to this toolbox. Call `exampleDefaults('reset')` before producing figures in another style.
obs = IndividualCMF(StandardObserver=10);
obs.plotLMS(Title="CIE 2006 10 deg cone fundamentals");
%%
%[text] ## A four-panel composite
%[text] The figure below shows the cone fundamentals, the RGB colour matching functions, the lens density and the macular density for one observer. Each plot method receives its own tile through `Parent=`.
%[text] Size the figure to its tile grid by choosing a size per tile and multiplying by the number of rows and columns. This one uses 500 by 375 pixels per tile. Left at the default figure size, a grid of panels comes out narrow and tall.
obs4 = IndividualCMF(StandardObserver=10);
wl4 = (390:1:780)';
figure(Position=[100 100 1000 750]);
t4 = tiledlayout(2, 2, TileSpacing="loose", Padding="compact");
title(t4, "CIE 170-1:2006 10-degree observer", FontWeight="bold");
obs4.plotLMS(Parent=nexttile(t4), Wavelength=wl4, Title="Cone fundamentals");
obs4.plotRGBCMFs(Parent=nexttile(t4), Wavelength=wl4, Title="RGB CMFs");
obs4.plotLens(Parent=nexttile(t4), Wavelength=wl4, Title="Lens density");
obs4.plotMacular(Parent=nexttile(t4), Wavelength=wl4, Title="Macular density");
%%
%[text] ## Composing a figure from several observers
%[text] A figure that compares observers is built the same way. The panels below sweep age, which requires `LensModel="VanDeKraats2007"` or `"Pokorny1987"`, since the default lens model does not depend on age. [Example 08](matlab:edit('Example08_AgingEffects.m')) covers the models themselves.
%[text] Two choices matter for a figure of this kind. Use a sequential colormap such as `parula` for an ordered variable, since `lines` gives no sense of order. And pass `NormalizeOutput=false` whenever the figure is about how much sensitivity changes, since the default normalization sets every curve to 1.0 at its own peak and gives no warning that it has done so.
%[text] Note that `parula` ends in a pale yellow, so on a white background the oldest observer draws the faintest line, which is usually the one of most interest. `flipud(parula(n))` puts the strongest contrast where it is wanted.
wl = (390:1:700)';
ages = [25, 40, 55, 70];
agecol = parula(numel(ages));
age_observers = IndividualCMF.across('Age', ages, LensModel="VanDeKraats2007", FieldSize=10);
[age_observers.ModelRangeWarning] = deal(false);
figure(Position=[100 100 1000 420]);
tiledlayout(1, 2, TileSpacing="loose", Padding="compact");
nexttile
hold on
for i = 1:numel(ages)
    plot(wl, age_observers(i).S(wl, NormalizeOutput=false), 'Color', agecol(i,:), ...
        'DisplayName', sprintf('Age %d', ages(i)))
end
hold off
xlabel('Wavelength (nm)'); ylabel('S-Cone Sensitivity')
title('S cone, unnormalized'); xlim([390 520]); legend('Location', 'best')
nexttile
hold on
for i = 1:numel(ages)
    plot(wl, age_observers(i).getLensDensitySpectrum(wl), 'Color', agecol(i,:))
end
hold off
xlabel('Wavelength (nm)'); ylabel('Lens optical density')
title('Lens density'); xlim([390 550])
sgtitle('Effects of age, VanDeKraats2007 lens model', 'FontWeight', 'bold')
%%
%[text] ## Writing a figure to file
%[text] `exportgraphics` chooses the format from the file extension and produces vector output for PDF, SVG and EPS. Pass `ContentType="vector"` to require it, and `Resolution` for a raster format.
exportgraphics(gcf, fullfile(tempdir, "observer_panel.pdf"), ContentType="vector");
exportgraphics(gcf, fullfile(tempdir, "observer_panel.png"), Resolution=300);
disp(['Exported to ' tempdir])
%%
%[text] ## Key takeaways
%[text] - The single-axes plot methods accept `Parent=`, so `nexttile` places them into any layout. `plotDiagnostics` draws three panels and takes the layout rather than a tile
%[text] - Pass `NormalizeOutput=false` whenever a figure is about how much sensitivity changes. The default normalization sets every curve to 1.0 at its peak and gives no warning
%[text] - A section that draws inline never calls `figure`. Draw the first curve before `hold on`, so that re-running a section replaces the curves rather than adding a second set
%[text] - A standalone figure calls `figure` first, then `tiledlayout` and `nexttile`. Size it to its tile grid by choosing a size per tile and multiplying by the rows and columns
%[text] - A section that follows a standalone figure must call `figure` before drawing. Otherwise `gcf` is still the previous figure and a bare `plot` replaces one of its panels
%[text] - Use a sequential colormap for an ordered variable. `parula` ends pale, so consider `flipud(parula(n))`
%[text] - Age sweeps need `LensModel="VanDeKraats2007"` or `"Pokorny1987"`
%[text] - `sgtitle` adds a title above a whole `tiledlayout`
%[text] - `exportgraphics(gcf, path, ContentType="vector")` writes the figure. Prefer PDF, SVG or EPS over a raster format
%[text] - `exampleDefaults` changes root graphics defaults for the session. Call `exampleDefaults('reset')` before producing figures in another style \
%[text] **Next:** [Example 19: Working with Measured Spectra](matlab:edit('Example19_MeasuredSpectra.m')). Reading a measured spectrum from a file and integrating it against an observer.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

%[text] # Example 17: Publication-Quality Figures
%[text] Multi-panel publication figures use MATLAB's `tiledlayout` and `nexttile` directly. Every `IndividualCMF` plot method accepts `Parent=`, so passing `nexttile()` places that plot in the next tile of the layout. Export with `exportgraphics`.
%[text] This is the capstone example: combine everything from the earlier scripts into figures suitable for papers and presentations.
%[text] **Time:** about 10 minutes.
exampleDefaults();
%%
%[text] ## Style guide for publication figures
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
%[text] | Cone colors | `IndividualCMF.CONE_COLORS` rows L, M, S; override per call with `ConeColors=` |
%[text] | Vector export | PDF / SVG / EPS preferred (via `exportgraphics`) |
%[text] | Raster export | `-r300` minimum |
%[text] | Single-column width | 3\.25-3.5 in (83-89 mm) |
%[text] | Double-column width | 6\.5-7 in (165-178 mm) |
%[text:table]
%%
%[text] ## Two paths to publication figures
%[text] This example shows two complementary patterns:
%[text] - **Inline plotting** (single panels in a Live Script section): call the `IndividualCMF` shortcuts (`obs.plotLMS`, `obs.compareTo`, ...). They draw into the current axes via `gca`, so the output is captured inline by the Live Editor.
%[text] - **Standalone publication figures** (multi-panel composites, PNG/PDF export): build the figure with `figure`, `tiledlayout`, and `nexttile`, passing each tile to a plot method via `Parent=`. Those produce real figure windows. \
%[text] The sections below alternate between the two patterns.
%%
%[text] ## Single-panel LMS plot (inline)
%[text] For inline Live Script use, call the `IndividualCMF` plot shortcut: it draws into the current axes (gca) so the output is captured by the Live Editor section.
obs = IndividualCMF(StandardObserver=10);
obs.plotLMS(Title="CIE 2006 10 deg cone fundamentals");
%%
%[text] ## Two-observer comparison (inline)
%[text] `compareTo` overlays a second observer in dashed lines. Same gca pattern as `plotLMS`.
%[text] The `VanDeKraats2007` lens is fitted on 300-700 nm, so evaluating it past 700 raises `IndividualCMF:WavelengthOutOfRange` once per observer. The extrapolation there is a smooth bounded decay and the values are kept; the warning is silenced below because model range is not what this example is about. See [Example 04](matlab:edit('Example04_AgingEffects.m')) for the `ValidRange` / `Domain` contract.
obs_ref  = IndividualCMF(StandardObserver=10);
obs_comp = IndividualCMF(LensModel="VanDeKraats2007", Age=60, FieldSize=10);
obs_comp.ModelRangeWarning = false;
obs_ref.compareTo(obs_comp, ...
    Title="CIE 10 deg (solid) vs Age 60 VanDeKraats2007 (dashed)");
%%
%[text] ## A six-perspective view of aging (VanDeKraats2007 model)
%[text] The next six sections each isolate one aspect of how the visual system changes with age, using the `VanDeKraats2007` lens model. Together these are exactly the panels you'd assemble into a publication-summary aging figure (see the final "composite figure" section below). Always use `VanDeKraats2007` (or `Pokorny1987`) for age studies; the default `StockmanRider2023` lens is age-flat (see [Example 04](matlab:edit('Example04_AgingEffects.m'))).
wl = (390:1:700)';
ages = [25, 40, 55, 70];
agecol = parula(numel(ages));
age_observers = IndividualCMF.across('Age', ages, LensModel="VanDeKraats2007", FieldSize=10);
[age_observers.ModelRangeWarning] = deal(false);
%%
%[text] ### Lens density spectrum vs age
plot(wl, age_observers(1).getLensDensitySpectrum(wl), 'Color', agecol(1,:), ...
    'DisplayName', sprintf('Age %d', ages(1)))
hold on
for i = 2:numel(ages)
    plot(wl, age_observers(i).getLensDensitySpectrum(wl), 'Color', agecol(i,:), ...
        'DisplayName', sprintf('Age %d', ages(i)))
end
hold off
xlabel('Wavelength (nm)'); ylabel('Lens optical density')
title('Lens density spectrum')
legend('Location', 'bestoutside'); xlim([390 550])
%%
%[text] ### Pre-receptoral transmission vs age
transmission = @(o) 100 * 10.^(-(o.getLensDensitySpectrum(wl) + o.getMacularDensitySpectrum(wl)));
plot(wl, transmission(age_observers(1)), 'Color', agecol(1,:), ...
    'DisplayName', sprintf('Age %d', ages(1)))
hold on
for i = 2:numel(ages)
    plot(wl, transmission(age_observers(i)), 'Color', agecol(i,:), ...
        'DisplayName', sprintf('Age %d', ages(i)))
end
hold off
xlabel('Wavelength (nm)'); ylabel('Transmission (%)')
title('Pre-receptoral transmission (lens + macular)')
legend('Location', 'bestoutside'); xlim([390 700])
%%
%[text] ### S-cone amplitude vs age
plot(wl, age_observers(1).S(wl), 'Color', agecol(1,:), ...
    'DisplayName', sprintf('Age %d', ages(1)))
hold on
for i = 2:numel(ages)
    plot(wl, age_observers(i).S(wl), 'Color', agecol(i,:), ...
        'DisplayName', sprintf('Age %d', ages(i)))
end
hold off
xlabel('Wavelength (nm)'); ylabel('S-Cone Sensitivity')
title('S-cone amplitude')
legend('Location', 'bestoutside'); xlim([390 520])
%%
%[text] ### L-cone vs age (mostly unchanged)
plot(wl, age_observers(1).L(wl), 'Color', agecol(1,:), ...
    'DisplayName', sprintf('Age %d', ages(1)))
hold on
for i = 2:numel(ages)
    plot(wl, age_observers(i).L(wl), 'Color', agecol(i,:), ...
        'DisplayName', sprintf('Age %d', ages(i)))
end
hold off
xlabel('Wavelength (nm)'); ylabel('L-Cone Sensitivity')
title('L-cone amplitude')
legend('Location', 'bestoutside'); xlim([500 650])
%%
%[text] ### V*(lambda) shift across ages
plot(wl, age_observers(1).Luminance(wl), 'Color', agecol(1,:), ...
    'DisplayName', sprintf('Age %d', ages(1)))
hold on
for i = 2:numel(ages)
    plot(wl, age_observers(i).Luminance(wl), 'Color', agecol(i,:), ...
        'DisplayName', sprintf('Age %d', ages(i)))
end
hold off
xlabel('Wavelength (nm)'); ylabel('V^*(\lambda)')
title('Photopic luminance')
legend('Location', 'bestoutside'); xlim([390 700])
%%
%[text] ### Spectral locus shift across ages
chrom = age_observers(1).lmChromaticity(wl);
plot(chrom(:,1), chrom(:,2), 'Color', agecol(1,:), ...
    'DisplayName', sprintf('Age %d', ages(1)))
hold on
for i = 2:numel(ages)
    chrom = age_observers(i).lmChromaticity(wl);
    plot(chrom(:,1), chrom(:,2), 'Color', agecol(i,:), ...
        'DisplayName', sprintf('Age %d', ages(i)))
end
hold off
xlabel('l'); ylabel('m')
title('Spectral locus (lm chromaticity)')
legend('Location', 'bestoutside'); axis equal; xlim([0 0.25]); ylim([0 0.25])
%%
%[text] ### Composite figure for publication
%[text] The same six panels assembled into a single 2x3 figure. Sizing the figure to match the tile grid keeps the panels roughly square; left at the default size a 2x3 grid comes out cramped and tall. Exported via `exportgraphics` (see "Exporting for publication" below) it scales to a clean publication-quality summary.
figure(Position=[100 100 1200 640]);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile
hold on
for i = 1:numel(ages)
    plot(wl, age_observers(i).getLensDensitySpectrum(wl), 'Color', agecol(i,:), ...
        'DisplayName', sprintf('Age %d', ages(i)))
end
hold off
xlabel('Wavelength (nm)'); ylabel('Lens OD'); title('Lens density'); xlim([390 550])
legend('Location', 'best')
nexttile
hold on
for i = 1:numel(ages)
    od_total = age_observers(i).getLensDensitySpectrum(wl) + age_observers(i).getMacularDensitySpectrum(wl);
    plot(wl, 100 * 10.^(-od_total), 'Color', agecol(i,:))
end
hold off
xlabel('Wavelength (nm)'); ylabel('Transmission (%)'); title('Pre-receptoral transmission'); xlim([390 700])
nexttile
hold on
for i = 1:numel(ages)
    plot(wl, age_observers(i).S(wl), 'Color', agecol(i,:))
end
hold off
xlabel('Wavelength (nm)'); ylabel('S sensitivity'); title('S-cone'); xlim([390 520])
nexttile
hold on
for i = 1:numel(ages)
    plot(wl, age_observers(i).L(wl), 'Color', agecol(i,:))
end
hold off
xlabel('Wavelength (nm)'); ylabel('L sensitivity'); title('L-cone'); xlim([500 650])
nexttile
hold on
for i = 1:numel(ages)
    plot(wl, age_observers(i).Luminance(wl), 'Color', agecol(i,:))
end
hold off
xlabel('Wavelength (nm)'); ylabel('V^*(\lambda)'); title('Photopic luminance'); xlim([390 700])
nexttile
hold on
for i = 1:numel(ages)
    chrom = age_observers(i).lmChromaticity(wl);
    plot(chrom(:,1), chrom(:,2), 'Color', agecol(i,:))
end
hold off
xlabel('l'); ylabel('m'); title('Spectral locus'); axis equal; xlim([0 0.25]); ylim([0 0.25])
sgtitle('Aging effects (VanDeKraats2007 lens, ages 25-70)', 'FontWeight', 'bold')
%%
%[text] ## Genetic-variants figure
%[text] Two-panel figure illustrating the L-cone Ser180Ala polymorphism. Left: zoom on the L-cone peak. Right: full-spectrum LMS with Serine (solid) and Alanine (dashed L) overlaid.
obs_ser  = IndividualCMF(L_OpsinTemplate="Serine");
obs_mean = IndividualCMF(L_OpsinTemplate="Mean");
obs_ala  = IndividualCMF(L_OpsinTemplate="Alanine");
wl_zoom = (520:0.5:620)';
figure(Position=[100 100 1000 420]);
tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile
plot(wl_zoom, obs_ser.L(wl_zoom),  'r-'); hold on
plot(wl_zoom, obs_mean.L(wl_zoom), 'k-')
plot(wl_zoom, obs_ala.L(wl_zoom),  'b-'); hold off
xlabel('Wavelength (nm)'); ylabel('L-Cone Sensitivity')
title('Ser180Ala polymorphism (L-cone peak zoom)')
legend('Serine', 'Mean', 'Alanine', 'Location', 'bestoutside')
nexttile
plot(wl, obs_ser.L(wl), 'r-'); hold on
plot(wl, obs_ser.M(wl), 'g-')
plot(wl, obs_ser.S(wl), 'b-')
plot(wl, obs_ala.L(wl), 'r--'); hold off
xlabel('Wavelength (nm)'); ylabel('Sensitivity')
title('Serine (solid) vs Alanine L (dashed)')
grid on; xlim([390 700])
sgtitle('L-cone genetic variants', 'FontWeight', 'bold')
%%
%[text] ## Exporting for publication
%[text] `exportgraphics(gcf, path, 'ContentType', 'vector')` is the modern recommendation for publication figures. The toolbox doesn't manage export paths automatically: write to the path you want.
obs_pub = IndividualCMF(StandardObserver=10);
LMS_pub = obs_pub.LMS(wl);
figure;
plot(wl, LMS_pub(:,1), 'r-', 'LineWidth', 1.5); hold on
plot(wl, LMS_pub(:,2), 'Color', [0 0.6 0], 'LineWidth', 1.5)
plot(wl, LMS_pub(:,3), 'b-', 'LineWidth', 1.5); hold off
xlabel('Wavelength (nm)'); ylabel('Relative Sensitivity')
title('CIE 2006 10 deg Cone Fundamentals')
legend('L', 'M', 'S', 'Location', 'bestoutside')
grid on; xlim([380 700]); ylim([0 1.05])
pdf_path = fullfile(tempdir, 'cone_fundamentals.pdf');
exportgraphics(gcf, pdf_path, 'ContentType', 'vector');
disp(['Exported: ' pdf_path])
%%
%[text] ## Key takeaways
%[text] - **Inline** sections draw a single axes and never call `figure`, so the plot renders under its own section in the Live Editor. Build the first line before `hold on` rather than after, so re-running a section replaces the curves instead of stacking a second set on top of them.
%[text] - **Standalone publication figures** call `figure` first, then `tiledlayout(...); nexttile`, and size the figure to match the tile grid -- roughly 500 x 320 px per tile keeps the panels square. Inside a fresh `nexttile` a bare `hold on` is safe, because the tile starts empty.
%[text] - A section that follows a standalone figure must open its own `figure` before drawing. `gcf` is still the previous section's figure, so a bare `plot` lands in one of its tiles and silently replaces that panel.
%[text] - Use `parula` (or any sequential colormap) for the age axis; `lines` doesn't suggest ordering
%[text] - For age sweeps, set `LensModel="VanDeKraats2007"` -- the default `StockmanRider2023` lens is age-flat
%[text] - `sgtitle` adds a supertitle to a `tiledlayout` composite
%[text] - `exportgraphics(gcf, path, 'ContentType', 'vector')` is the modern publication-export call -- PDF / SVG / EPS preferred over raster \
%%
%[text] ## Four-panel observer figure
%[text] A 2x2 composite: cone fundamentals, RGB CMFs, lens density, and macular density for one observer. Each plot method receives its own tile through `Parent=`, so no wrapper class is involved.
obs4 = IndividualCMF(StandardObserver=10);
wl4 = (390:1:780)';
figure(Position=[100 100 1000 750]);
t4 = tiledlayout(2, 2, TileSpacing="compact", Padding="compact");
title(t4, "CIE 170-1:2006 10-degree observer", FontWeight="bold");
obs4.plotLMS(Parent=nexttile(t4), Wavelength=wl4, Title="Cone fundamentals");
obs4.plotRGBCMFs(Parent=nexttile(t4), Wavelength=wl4, Title="RGB CMFs");
obs4.plotLens(Parent=nexttile(t4), Wavelength=wl4, Title="Lens density");
obs4.plotMacular(Parent=nexttile(t4), Wavelength=wl4, Title="Macular density");
%[text] Export at publication resolution. `exportgraphics` picks the format from the file extension and produces vector output for PDF and EPS.
exportgraphics(gcf, fullfile(tempdir, "observer_panel.pdf"), ContentType="vector");
exportgraphics(gcf, fullfile(tempdir, "observer_panel.png"), Resolution=300);
%[text] **Next:** [Example 18: Observer Metamerism](matlab:edit('Example18_ObserverMetamerism.m')) -- how a metameric pair for the standard observer breaks for an individual observer.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

%[text] # Example 17: Publication-Quality Figures
%[text] The `CMFPlotter` class wraps a tiled-layout figure with consistent styling and shorthand methods for the toolbox's standard plot types: LMS fundamentals, RGB CMFs, chromaticity diagrams, comparison overlays, and pre-receptoral filtering.
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
%[text] | L-cone color | Red `[1 0 0]` or `[0.8 0 0]` |
%[text] | M-cone color | Green `[0 0.6 0]` |
%[text] | S-cone color | Blue `[0 0 1]` or `[0 0 0.8]` |
%[text] | Vector export | PDF / SVG / EPS preferred (via `exportgraphics`) |
%[text] | Raster export | `-r300` minimum |
%[text] | Single-column width | 3\.25-3.5 in (83-89 mm) |
%[text] | Double-column width | 6\.5-7 in (165-178 mm) |
%[text:table]
%%
%[text] ## Two paths to publication figures
%[text] This example shows two complementary patterns:
%[text] - **Inline plotting** (single panels in a Live Script section): call the `IndividualCMF` shortcuts (`obs.plotLMS`, `obs.compareTo`, ...). They draw into the current axes via `gca`, so the output is captured inline by the Live Editor.
%[text] - **Standalone publication figures** (multi-panel composites, PNG/PDF export): build the figure yourself with `figure`, `tiledlayout`, and `nexttile`, or use `CMFPlotter` for a styled tiled-layout wrapper. Those produce real figure windows. \
%[text] The sections below alternate between the two patterns.
%%
%[text] ## Single-panel LMS plot (inline)
%[text] For inline Live Script use, call the `IndividualCMF` plot shortcut: it draws into the current axes (gca) so the output is captured by the Live Editor section.
obs = IndividualCMF(StandardObserver=10);
obs.plotLMS(Title="CIE 2006 10 deg cone fundamentals");
%%
%[text] ## Two-observer comparison (inline)
%[text] `compareTo` overlays a second observer in dashed lines. Same gca pattern as `plotLMS`.
obs_ref  = IndividualCMF(StandardObserver=10);
obs_comp = IndividualCMF(LensModel="VanDeKraats2007", Age=60, FieldSize=10);
obs_ref.compareTo(obs_comp, ...
    Title="CIE 10 deg (solid) vs Age 60 VanDeKraats2007 (dashed)");
%%
%[text] ## A six-perspective view of aging (VanDeKraats2007 model)
%[text] The next six sections each isolate one aspect of how the visual system changes with age, using the `VanDeKraats2007` lens model. Together these are exactly the panels you'd assemble into a publication-summary aging figure (see the final "composite figure" section below). Always use `VanDeKraats2007` (or `Pokorny1987`) for age studies; the default `StockmanRider2023` lens is age-flat (see [Example 04](matlab:edit('Example04_AgingEffects.m'))).
wl = (390:1:700)';
ages = [25, 40, 55, 70];
agecol = parula(numel(ages));
age_observers = IndividualCMF.across('Age', ages, LensModel="VanDeKraats2007", FieldSize=10);
%%
%[text] ### Lens density spectrum vs age
figure;
hold on
for i = 1:numel(ages)
    plot(wl, age_observers(i).getLensDensitySpectrum(wl), 'Color', agecol(i,:), ...
        'DisplayName', sprintf('Age %d', ages(i)))
end
hold off
xlabel('Wavelength (nm)'); ylabel('Lens optical density')
title('Lens density spectrum')
legend('Location', 'bestoutside'); xlim([390 550])
%%
%[text] ### Pre-receptoral transmission vs age
figure;
hold on
for i = 1:numel(ages)
    od_total = age_observers(i).getLensDensitySpectrum(wl) + age_observers(i).getMacularDensitySpectrum(wl);
    plot(wl, 100 * 10.^(-od_total), 'Color', agecol(i,:), ...
        'DisplayName', sprintf('Age %d', ages(i)))
end
hold off
xlabel('Wavelength (nm)'); ylabel('Transmission (%)')
title('Pre-receptoral transmission (lens + macular)')
legend('Location', 'bestoutside'); xlim([390 700])
%%
%[text] ### S-cone amplitude vs age
figure;
hold on
for i = 1:numel(ages)
    plot(wl, age_observers(i).S(wl), 'Color', agecol(i,:), ...
        'DisplayName', sprintf('Age %d', ages(i)))
end
hold off
xlabel('Wavelength (nm)'); ylabel('S-Cone Sensitivity')
title('S-cone amplitude')
legend('Location', 'bestoutside'); xlim([390 520])
%%
%[text] ### L-cone vs age (mostly unchanged)
figure;
hold on
for i = 1:numel(ages)
    plot(wl, age_observers(i).L(wl), 'Color', agecol(i,:), ...
        'DisplayName', sprintf('Age %d', ages(i)))
end
hold off
xlabel('Wavelength (nm)'); ylabel('L-Cone Sensitivity')
title('L-cone amplitude')
legend('Location', 'bestoutside'); xlim([500 650])
%%
%[text] ### V*(lambda) shift across ages
figure;
hold on
for i = 1:numel(ages)
    plot(wl, age_observers(i).Luminance(wl), 'Color', agecol(i,:), ...
        'DisplayName', sprintf('Age %d', ages(i)))
end
hold off
xlabel('Wavelength (nm)'); ylabel('V^*(\lambda)')
title('Photopic luminance')
legend('Location', 'bestoutside'); xlim([390 700])
%%
%[text] ### Spectral locus shift across ages
figure;
hold on
for i = 1:numel(ages)
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
%[text] The same six panels assembled into a single 2x3 figure. Inline, this rendering is cramped, but when exported via `exportgraphics` (see "Exporting for publication" below) the figure window scales correctly and produces a clean publication-quality summary.
figure;
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
figure;
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
%[text] - **Inline** sections call `obs.plotLMS`, `obs.compareTo`, etc. directly so the wrapper draws into the Live Editor's current axes
%[text] - **Standalone publication figures** use `figure; tiledlayout(...); nexttile` to build multi-panel composites in a real figure window
%[text] - Use `parula` (or any sequential colormap) for the age axis; `lines` doesn't suggest ordering
%[text] - For age sweeps, set `LensModel="VanDeKraats2007"` -- the default `StockmanRider2023` lens is age-flat
%[text] - `sgtitle` adds a supertitle to a `tiledlayout` composite
%[text] - `exportgraphics(gcf, path, 'ContentType', 'vector')` is the modern publication-export call -- PDF / SVG / EPS preferred over raster \
%[text] **Next:** [Example 18: Observer Metamerism](matlab:edit('Example18_ObserverMetamerism.m')) -- how a metameric pair for the standard observer breaks for an individual observer.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

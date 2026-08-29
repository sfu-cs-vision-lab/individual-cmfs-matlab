%[text] # Example 18: Publication-Quality Figures
%[text] Multi-panel figures are built with MATLAB's own `tiledlayout` and `nexttile`. Every plot method in the toolbox accepts a `Parent` argument, so passing it `nexttile()` places that plot in the next tile. Figures are written to file with `exportgraphics`.
%[text] This example draws on the material of the earlier ones and assembles it into figures of the kind used in papers and presentations.
%[text] **Time:** about 10 minutes.
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
%[text] This example uses two patterns, and alternates between them.
%[text] - **Drawing inline.** For a single panel in a Live Script section, call a plot method such as `obs.plotLMS` or `obs.compareTo` without creating a figure. They draw into the current axes, so the Live Editor captures the result under that section.
%[text] - **Drawing a standalone figure.** For a composite that will be exported, call `figure`, then `tiledlayout` and `nexttile`, and pass each tile to a plot method through `Parent=`. These open a figure window of their own. \
%%
%[text] ## A single panel drawn inline
obs = IndividualCMF(StandardObserver=10);
obs.plotLMS(Title="CIE 2006 10 deg cone fundamentals");
%%
%[text] ## Two observers drawn inline
%[text] `compareTo` draws a second observer with dashed lines, into the current axes as before.
%[text] The `VanDeKraats2007` model was fitted over 300 to 700 nm, so evaluating it beyond 700 nm raises `IndividualCMF:WavelengthOutOfRange` once for each observer. The extrapolation is a smooth decay of bounded size and the values are kept. The warning is switched off below because the range of the model is not the subject here. See [Example 05](matlab:edit('Example05_AgingEffects.m')).
obs_ref  = IndividualCMF(StandardObserver=10);
obs_comp = IndividualCMF(LensModel="VanDeKraats2007", Age=60, FieldSize=10);
obs_comp.ModelRangeWarning = false;
obs_ref.compareTo(obs_comp, ...
    Title="CIE 10 deg (solid) and age 60, VanDeKraats2007 (dashed)");
%%
%[text] ## Six views of the same effect
%[text] The six sections that follow each show one consequence of the lens absorbing more light with age. The section after them assembles the same six panels into one figure.
%[text] Age work requires `VanDeKraats2007` or `Pokorny1987`, since the default lens model does not depend on age. See [Example 05](matlab:edit('Example05_AgingEffects.m')).
wl = (390:1:700)';
ages = [25, 40, 55, 70];
agecol = parula(numel(ages));
age_observers = IndividualCMF.across('Age', ages, LensModel="VanDeKraats2007", FieldSize=10);
[age_observers.ModelRangeWarning] = deal(false);
%%
%[text] ### Lens optical density
plot(wl, age_observers(1).getLensDensitySpectrum(wl), 'Color', agecol(1,:), ...
    'DisplayName', sprintf('Age %d', ages(1)))
hold on
for i = 2:numel(ages)
    plot(wl, age_observers(i).getLensDensitySpectrum(wl), 'Color', agecol(i,:), ...
        'DisplayName', sprintf('Age %d', ages(i)))
end
hold off
xlabel('Wavelength (nm)'); ylabel('Lens optical density')
title('Lens optical density')
legend('Location', 'bestoutside'); xlim([390 550])
%%
%[text] ### Light reaching the cones
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
title('Transmission through the lens and macular pigment')
legend('Location', 'bestoutside'); xlim([390 700])
%%
%[text] ### S-cone sensitivity
%[text] These curves are drawn with `NormalizeOutput=false`. Under the default normalization each age would reach 1.0 at its own peak and the loss this panel exists to show would not appear at all.
plot(wl, age_observers(1).S(wl, NormalizeOutput=false), 'Color', agecol(1,:), ...
    'DisplayName', sprintf('Age %d', ages(1)))
hold on
for i = 2:numel(ages)
    plot(wl, age_observers(i).S(wl, NormalizeOutput=false), 'Color', agecol(i,:), ...
        'DisplayName', sprintf('Age %d', ages(i)))
end
hold off
xlabel('Wavelength (nm)'); ylabel('S-Cone Sensitivity')
title('S-cone sensitivity')
legend('Location', 'bestoutside'); xlim([390 520])
%%
%[text] ### L-cone sensitivity
%[text] Also drawn without normalization. The L cone keeps most of its sensitivity but not all of it. Between ages 25 and 70 it loses about 12%, against 17% for M and 61% for S.
%[text] The M cone is left out of the six panels for space rather than because it is unaffected. Without normalization it peaks 24 nm short of L and reaches only 92% of L's height, so it would be a clearly separate curve, and its loss with age is of the same kind as L's.
plot(wl, age_observers(1).L(wl, NormalizeOutput=false), 'Color', agecol(1,:), ...
    'DisplayName', sprintf('Age %d', ages(1)))
hold on
for i = 2:numel(ages)
    plot(wl, age_observers(i).L(wl, NormalizeOutput=false), 'Color', agecol(i,:), ...
        'DisplayName', sprintf('Age %d', ages(i)))
end
hold off
xlabel('Wavelength (nm)'); ylabel('L-Cone Sensitivity')
title('L-cone sensitivity')
legend('Location', 'bestoutside'); xlim([500 650])
%%
%[text] ### Photopic luminance
%[text] The axes cover 500 to 620 nm. Over that range the peak of $V^{*}(\\lambda)$ can be seen to move about 5.7 nm towards longer wavelengths between ages 25 and 70, which is not visible across the full spectrum.
%[text] These curves keep the default normalization, since the movement of the peak is the subject here rather than the height of the curve. Note that $V^{*}$ is a weighted sum of two normalized cones, so its own maximum is slightly above 1, near 1.01.
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
legend('Location', 'bestoutside'); xlim([500 620])
%%
%[text] ### Spectrum locus
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
xlabel('l = L / (L + M + S)'); ylabel('m = M / (L + M + S)')
title('Spectrum locus, short-wavelength end')
legend('Location', 'bestoutside'); axis equal; xlim([0 0.30]); ylim([0 0.45])
%%
%[text] ### The six panels as one figure
%[text] The figure is sized to its tile grid, at 400 by 320 pixels per tile. Left at the default figure size, a 2 by 3 grid of panels comes out narrow and tall.
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
xlabel('Wavelength (nm)'); ylabel('Transmission (%)'); title('Transmission'); xlim([390 700])
nexttile
hold on
for i = 1:numel(ages)
    plot(wl, age_observers(i).S(wl, NormalizeOutput=false), 'Color', agecol(i,:))
end
hold off
xlabel('Wavelength (nm)'); ylabel('S sensitivity'); title('S cone'); xlim([390 520])
nexttile
hold on
for i = 1:numel(ages)
    plot(wl, age_observers(i).L(wl, NormalizeOutput=false), 'Color', agecol(i,:))
end
hold off
xlabel('Wavelength (nm)'); ylabel('L sensitivity'); title('L cone'); xlim([500 650])
nexttile
hold on
for i = 1:numel(ages)
    plot(wl, age_observers(i).Luminance(wl), 'Color', agecol(i,:))
end
hold off
xlabel('Wavelength (nm)'); ylabel('V^*(\lambda)'); title('Photopic luminance'); xlim([500 620])
nexttile
hold on
for i = 1:numel(ages)
    chrom = age_observers(i).lmChromaticity(wl);
    plot(chrom(:,1), chrom(:,2), 'Color', agecol(i,:))
end
hold off
xlabel('l'); ylabel('m'); title('Spectrum locus'); axis equal; xlim([0 0.30]); ylim([0 0.45])
sgtitle('Effects of age, VanDeKraats2007 lens model, ages 25 to 70', 'FontWeight', 'bold')
%%
%[text] ## A two-panel figure
%[text] The figure below shows the L-cone Ser180Ala polymorphism. The left panel covers the wavelengths around the L-cone peak. The right panel shows all three cones across the spectrum, with the serine variant drawn solid and the alanine L cone drawn dashed.
obs_ser  = IndividualCMF(L_OpsinTemplate="Serine");
obs_mean = IndividualCMF(L_OpsinTemplate="Mean");
obs_ala  = IndividualCMF(L_OpsinTemplate="Alanine");
wl_zoom = (520:0.5:620)';
figure(Position=[100 100 1000 420]);
tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile
plot(wl_zoom, obs_ser.L(wl_zoom),  'r-'); hold on
plot(wl_zoom, obs_mean.L(wl_zoom), '-', 'Color', IndividualCMF.neutralColor())
plot(wl_zoom, obs_ala.L(wl_zoom),  'b-'); hold off
xlabel('Wavelength (nm)'); ylabel('L-Cone Sensitivity')
title('Near the L-cone peak')
legend('Serine', 'Mean', 'Alanine', 'Location', 'bestoutside')
nexttile
plot(wl, obs_ser.L(wl), 'r-'); hold on
plot(wl, obs_ser.M(wl), 'g-')
plot(wl, obs_ser.S(wl), 'b-')
plot(wl, obs_ala.L(wl), 'r--'); hold off
xlabel('Wavelength (nm)'); ylabel('Sensitivity')
title('Serine (solid) and Alanine L (dashed)')
grid on; xlim([390 700])
sgtitle('L-cone genetic variants', 'FontWeight', 'bold')
%%
%[text] ## Writing a figure to file
%[text] `exportgraphics(gcf, path, 'ContentType', 'vector')` is the current recommendation for publication figures. The toolbox does not manage output paths, so give it the path you want.
obs_pub = IndividualCMF(StandardObserver=10);
LMS_pub = obs_pub.LMS(wl);
figure;
plot(wl, LMS_pub(:,1), 'r-', 'LineWidth', 1.5); hold on
plot(wl, LMS_pub(:,2), 'Color', [0 0.6 0], 'LineWidth', 1.5)
plot(wl, LMS_pub(:,3), 'b-', 'LineWidth', 1.5); hold off
xlabel('Wavelength (nm)'); ylabel('Relative Sensitivity')
title('CIE 2006 10 deg cone fundamentals')
legend('L', 'M', 'S', 'Location', 'bestoutside')
grid on; xlim([380 700]); ylim([0 1.05])
pdf_path = fullfile(tempdir, 'cone_fundamentals.pdf');
exportgraphics(gcf, pdf_path, 'ContentType', 'vector');
disp(['Exported: ' pdf_path])
%%
%[text] ## A four-panel figure
%[text] The figure below shows the cone fundamentals, the RGB colour matching functions, the lens density and the macular density for one observer. Each plot method receives its own tile through `Parent=`.
obs4 = IndividualCMF(StandardObserver=10);
wl4 = (390:1:780)';
figure(Position=[100 100 1000 750]);
t4 = tiledlayout(2, 2, TileSpacing="compact", Padding="compact");
title(t4, "CIE 170-1:2006 10-degree observer", FontWeight="bold");
obs4.plotLMS(Parent=nexttile(t4), Wavelength=wl4, Title="Cone fundamentals");
obs4.plotRGBCMFs(Parent=nexttile(t4), Wavelength=wl4, Title="RGB CMFs");
obs4.plotLens(Parent=nexttile(t4), Wavelength=wl4, Title="Lens density");
obs4.plotMacular(Parent=nexttile(t4), Wavelength=wl4, Title="Macular density");
%[text] `exportgraphics` chooses the format from the file extension, and produces vector output for PDF and EPS.
exportgraphics(gcf, fullfile(tempdir, "observer_panel.pdf"), ContentType="vector");
exportgraphics(gcf, fullfile(tempdir, "observer_panel.png"), Resolution=300);
%%
%[text] ## Key takeaways
%[text] - Pass `NormalizeOutput=false` whenever a figure is about how much sensitivity changes. The default normalization sets every curve to 1.0 at its peak, and no warning is given. Here it would have hidden the 61% S-cone loss entirely
%[text] - Every plot method accepts `Parent=`, so `nexttile` places them into any layout. That is how all three composite figures here are built
%[text] - A section that draws inline never calls `figure`, so the plot appears under that section in the Live Editor. Draw the first curve before `hold on` rather than after, so that re-running a section replaces the curves instead of adding a second set
%[text] - A standalone figure calls `figure` first, then `tiledlayout` and `nexttile`. Size the figure to its tile grid by choosing a size per tile and multiplying by the number of rows and columns. The three composites here use 400 by 320, 500 by 420 and 500 by 375 pixels per tile, which keep each panel wider than it is tall. Inside a fresh `nexttile` a bare `hold on` is safe, since the tile starts empty
%[text] - A section that follows a standalone figure must call `figure` before drawing. Otherwise `gcf` is still the previous figure, and a bare `plot` draws into one of its tiles and replaces that panel
%[text] - Use `parula` or another sequential colormap for an age axis, since `lines` gives no sense of order. Note that parula ends in a pale yellow, so on a white background the oldest observer draws the faintest line, which is usually the one of most interest. `flipud(parula(n))` or a truncated map puts the strongest contrast where it is wanted
%[text] - Age sweeps need `LensModel="VanDeKraats2007"`, since the default model does not depend on age
%[text] - `sgtitle` adds a title above a whole `tiledlayout`
%[text] - `exportgraphics(gcf, path, 'ContentType', 'vector')` writes the figure. Prefer PDF, SVG or EPS over a raster format \
%[text] **Next:** [Example 19: Observer Metamerism](matlab:edit('Example19_ObserverMetamerism.m')). How a match made for the standard observer fails for an individual observer.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

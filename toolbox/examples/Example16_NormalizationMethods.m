%[text] # Example 16: Normalization Methods
%[text] **This is a developer / reproducibility topic.** Most users will never touch `NormalizationMethod`. The default `"Continuous"` method is correct for almost all colorimetric work. This example covers when and why to override it.
%[text] When `NormalizeOutput=true` (the default), each cone fundamental is divided by its peak so the maximum equals 1.0. The question is **how** that peak is found:
%[text] - **`Continuous`** *(default)* -- uses numerical optimization (`fminbnd`) to find the exact peak. Resolution-independent. Normalized values never exceed 1.0.
%[text] - **`Sampled`** -- uses `max()` over a discrete wavelength grid. Resolution-dependent. May slightly exceed 1.0 at off-grid wavelengths but matches reference tools (e.g., Pycone) that use the same approach. \
%[text] **Time:** about 10 minutes.
exampleDefaults();
%%
%[text] ## Two normalization methods
%[text] You can request either method by name. The wavelengths `Sampled` normalizes over live in `NormalizationGrid`, which accepts any wavelength vector -- the `start:step:stop` form below is just convenient.
%[text] Three of the four output formats are normalized. `absorbance` is the exception: it is never normalized, whatever `NormalizeOutput` says, because its absolute scale carries meaning -- `A(lambda_max) = 1` is what makes `Lod`/`Mod`/`Sod` mean peak axial optical density.
obs_cont = IndividualCMF(NormalizationMethod="Continuous");
obs_samp = IndividualCMF(NormalizationMethod="Sampled");
grid_default = obs_samp.NormalizationGrid;
table(string(obs_cont.NormalizationMethod), string(obs_samp.NormalizationMethod), ...
      min(grid_default), max(grid_default), numel(grid_default), ...
      'VariableNames', {'Cont_method', 'Samp_method', 'Grid_min', 'Grid_max', 'Grid_points'})
%%
%[text] ## Comparing the two normalizations on the L-cone
%[text] Side-by-side: the two methods produce nearly identical L-cone curves over the visible range. The difference is around 1e-5 -- the fifth decimal place -- significant only when reproducibility against a reference implementation is required.
wl = (400:5:700)';
L_cont = obs_cont.L(wl);
L_samp = obs_samp.L(wl);
tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile
plot(wl, L_cont, 'b-'); hold on
plot(wl, L_samp, 'r--'); hold off
xlabel('Wavelength (nm)'); ylabel('L-Cone Sensitivity')
title('L-cone, two methods overlaid'); legend('Continuous', 'Sampled')
nexttile
plot(wl, (L_cont - L_samp) * 1e5, '-', 'Color', IndividualCMF.neutralColor())
xlabel('Wavelength (nm)'); ylabel('Difference (x10^{-5})')
title('Continuous - Sampled (scaled)')
table(max(abs(L_cont - L_samp)), mean(abs(L_cont - L_samp)), ...
      'VariableNames', {'MaxAbsDiff', 'MeanAbsDiff'})
%%
%[text] ## Inspecting the normalization peak with `getPeak`
%[text] The `getPeak` method returns the *unnormalized* peak value used as the divisor. The Continuous peak is always at least as large as the Sampled peak (because it can find the true maximum between grid points).
table(obs_cont.getPeak('L'), obs_samp.getPeak('L'), ...
      obs_cont.getPeak('L') - obs_samp.getPeak('L'), ...
      'VariableNames', {'Continuous_peak', 'Sampled_peak', 'Difference'})
%%
%[text] ## Resolution dependence of `Sampled`
%[text] Coarser grids miss the true maximum and find a smaller peak (so subsequent normalised values are *higher* -- including possibly above 1.0). Finer grids approach the Continuous result.
peaks = struct();
for step = [1, 5, 10]
    o = IndividualCMF(NormalizationMethod="Sampled", ...
        NormalizationGrid=380:step:780);
    peaks.(sprintf('step_%d', step)) = o.getPeak('L');
end
table(peaks.step_1, peaks.step_5, peaks.step_10, obs_cont.getPeak('L'), ...
      'VariableNames', {'Step_1nm', 'Step_5nm', 'Step_10nm', 'Continuous'})
%%
%[text] ## The off-grid exceedance issue
%[text] If you normalise on a coarse grid then evaluate at a finer grid, the values can exceed 1.0 -- you've found a wavelength between two grid points where the true sensitivity is higher than any sampled value.
obs_demo  = IndividualCMF(NormalizationMethod="Sampled", NormalizationGrid=380:10:780);
obs_cont2 = IndividualCMF(NormalizationMethod="Continuous");
wl_fine = (500:0.1:600)';
table(max(obs_demo.L(wl_fine)),  max(obs_demo.L(wl_fine))  > 1.0, ...
      max(obs_cont2.L(wl_fine)), max(obs_cont2.L(wl_fine)) > 1.0, ...
      'VariableNames', {'Sampled_max', 'Sampled_exceeds_1', 'Continuous_max', 'Continuous_exceeds_1'})
%%
%[text] ## Visualizing the exceedance
%[text] Zooming around the true L-cone peak (566.7 nm) with a deliberately coarse 5 nm Sampled grid. The sampled maximum is taken at 565 nm, the grid point nearest the peak, so the red curve reaches exactly 1.0 there and then climbs *above* it between the 565 and 570 nm grid points, peaking near 1.00048. Continuous (blue) stays at or below 1.0 everywhere. Note the y-axis spans only 0.004 -- the exceedance is under 5e-4 and is invisible on a normal scale.
wl_zoom = (560:0.01:576)';
obs_samp_5 = IndividualCMF(NormalizationMethod="Sampled", NormalizationGrid=380:5:780);
tiledlayout(1, 1, 'TileSpacing', 'compact', 'Padding', 'compact'); nexttile
plot(wl_zoom, obs_cont.L(wl_zoom), 'b-'); hold on
plot(wl_zoom, obs_samp_5.L(wl_zoom), 'r--')
plot(wl_zoom, ones(size(wl_zoom)), ':', 'Color', IndividualCMF.neutralColor(), 'LineWidth', 1)
plot((560:5:575)', obs_samp_5.L((560:5:575)'), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r')
hold off
xlabel('Wavelength (nm)'); ylabel('L-Cone Sensitivity')
title('Off-grid exceedance (Sampled 5 nm vs Continuous)')
legend('Continuous', 'Sampled (5 nm)', 'y = 1', 'Sampled grid points', 'Location', 'bestoutside')
grid on; ylim([0.997 1.001])
%%
%[text] ## Reproducing external reference implementations
%[text] To match an external implementation that normalizes on a discrete wavelength grid, set `NormalizationMethod="Sampled"` and give `NormalizationGrid` the same wavelengths the reference uses, then evaluate at that grid. **Pycone** (the Python reference implementation) is the canonical example: it accepts a user-configurable step size. Because the grid is a plain wavelength vector, one expression serves as both the normalization grid and the evaluation grid.
%[text] The grid below is a stand-in for some external reference's configuration, not pycone's -- pycone normalizes over 380:1:780, which is exactly why that is this toolbox's default `NormalizationGrid`.
wl_reference = (390:5:830)';
obs_reference = IndividualCMF(NormalizationMethod="Sampled", NormalizationGrid=wl_reference);
table(string(obs_reference.NormalizationMethod), ...
      min(obs_reference.NormalizationGrid), ...
      max(obs_reference.NormalizationGrid), ...
      numel(obs_reference.NormalizationGrid), ...
      'VariableNames', {'Method', 'Grid_min', 'Grid_max', 'Grid_points'})
%%
%[text] ## Recommendations
%[text] **Use Continuous when:** you need guaranteed values <= 1.0; you're evaluating at arbitrary wavelengths; this is the right default for general colorimetric work.
%[text] **Use Sampled when:** you're matching a specific reference dataset (Pycone, published tables); you need bit-exact reproducibility on a known grid. Use the matching evaluation grid to avoid off-grid exceedance.
%%
%[text] ## Key takeaways
%[text] - `Continuous` (default) finds the exact peak via optimisation; resolution-independent; never exceeds 1.0
%[text] - `Sampled` finds the max over a discrete grid; resolution-dependent; may exceed 1.0 between grid points
%[text] - Use `NormalizationGrid = a:s:b` for explicit grid control
%[text] - `obs.getPeak('L')` returns the unnormalised peak (the divisor)
%[text] - For pycone parity, keep the default `NormalizationGrid` (380:1:780, which is the grid pycone normalizes over) or set it to the grid the pycone session used, and evaluate on that same grid \
%[text] **Next:** [Example 17: Publication-Quality Figures](matlab:edit('Example17_PublicationFigures.m')) -- composing multi-panel figures with `tiledlayout` and exporting them for publication.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

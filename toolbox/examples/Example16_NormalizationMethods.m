%[text] # Example 16: Normalization Methods
%[text] **This is a developer / reproducibility topic.** Most users will never touch `NormalizationMethod`. The default `"Continuous"` method is correct for almost all colorimetric work. This example covers when and why to override it.
%[text] When `NormalizeOutput=true` (the default), each cone fundamental is divided by its peak so the maximum equals 1.0. The question is **how** that peak is found:
%[text] - **`Continuous`** *(default)* -- uses numerical optimization (`fminbnd`) to find the exact peak. Resolution-independent. Normalized values never exceed 1.0.
%[text] - **`Sampled`** -- uses `max()` over a discrete wavelength grid. Resolution-dependent. May slightly exceed 1.0 at off-grid wavelengths but matches reference tools (e.g., Pycone) that use the same approach. \
%[text] **Time:** about 10 minutes.
exampleDefaults();
%%
%[text] ## Two normalization methods
%[text] You can request either method by name. The full configuration (start/stop/step) for `Sampled` is exposed via `NormalizationConfig`.
obs_cont = IndividualCMF(NormalizationMethod="Continuous");
obs_samp = IndividualCMF(NormalizationMethod="Sampled");
cfg = obs_samp.NormalizationConfig;
table(string(obs_cont.NormalizationMethod), string(obs_samp.NormalizationMethod), ...
      cfg.Start, cfg.Stop, cfg.Step, ...
      'VariableNames', {'Cont_method', 'Samp_method', 'Start', 'Stop', 'Step'})
%%
%[text] ## Comparing the two normalizations on the L-cone
%[text] Side-by-side: the two methods produce nearly identical L-cone curves over the visible range. The difference is in the third decimal place -- significant only when reproducibility against a reference is required.
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
plot(wl, (L_cont - L_samp) * 1000, 'k-')
xlabel('Wavelength (nm)'); ylabel('Difference (x10^{-3})')
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
    o = IndividualCMF(NormalizationMethod=struct('Method', "Sampled", ...
        'Start', 380, 'Stop', 780, 'Step', step));
    peaks.(sprintf('step_%d', step)) = o.getPeak('L');
end
table(peaks.step_1, peaks.step_5, peaks.step_10, obs_cont.getPeak('L'), ...
      'VariableNames', {'Step_1nm', 'Step_5nm', 'Step_10nm', 'Continuous'})
%%
%[text] ## The off-grid exceedance issue
%[text] If you normalise on a coarse grid then evaluate at a finer grid, the values can exceed 1.0 -- you've found a wavelength between two grid points where the true sensitivity is higher than any sampled value.
obs_demo  = IndividualCMF(NormalizationMethod=struct('Method', "Sampled", 'Step', 10));
obs_cont2 = IndividualCMF(NormalizationMethod="Continuous");
wl_fine = (500:0.1:600)';
table(max(obs_demo.L(wl_fine)),  max(obs_demo.L(wl_fine))  > 1.0, ...
      max(obs_cont2.L(wl_fine)), max(obs_cont2.L(wl_fine)) > 1.0, ...
      'VariableNames', {'Sampled_max', 'Sampled_exceeds_1', 'Continuous_max', 'Continuous_exceeds_1'})
%%
%[text] ## Visualizing the exceedance
%[text] Zooming around the L-cone peak with a deliberately coarse 5 nm Sampled grid shows the curve crossing 1.0 between grid points. Continuous (blue) stays cleanly below 1.0 everywhere.
wl_zoom = (555:0.01:565)';
obs_samp_5 = IndividualCMF(NormalizationMethod=struct('Method', "Sampled", 'Step', 5));
tiledlayout(1, 1, 'TileSpacing', 'compact', 'Padding', 'compact'); nexttile
plot(wl_zoom, obs_cont.L(wl_zoom), 'b-'); hold on
plot(wl_zoom, obs_samp_5.L(wl_zoom), 'r--')
plot(wl_zoom, ones(size(wl_zoom)), 'k:', 'LineWidth', 1)
plot((555:5:565)', obs_samp_5.L((555:5:565)'), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r')
hold off
xlabel('Wavelength (nm)'); ylabel('L-Cone Sensitivity')
title('Off-grid exceedance (Sampled 5 nm vs Continuous)')
legend('Continuous', 'Sampled (5 nm)', 'y = 1', 'Sampled grid points', 'Location', 'bestoutside')
grid on; ylim([0.98 1.01])
%%
%[text] ## Reproducing external reference implementations
%[text] To match an external implementation that normalizes on a discrete wavelength grid, set `NormalizationMethod` to a `Sampled` struct with the same `Start`/`Stop`/`Step` the reference uses, and evaluate at the same grid. **Pycone** (the Python reference implementation) is the canonical example: it accepts a user-configurable step size. Match `Step` to whatever the reference session uses; the example below configures a 5 nm grid.
pycone_cfg = struct('Method', "Sampled", 'Start', 390, 'Stop', 830, 'Step', 5);
obs_pycone = IndividualCMF(NormalizationMethod=pycone_cfg);
wl_pycone = (390:5:830)';
table(string(obs_pycone.NormalizationMethod), ...
      obs_pycone.NormalizationConfig.Start, ...
      obs_pycone.NormalizationConfig.Stop, ...
      obs_pycone.NormalizationConfig.Step, ...
      'VariableNames', {'Method', 'Start', 'Stop', 'Step'})
%%
%[text] ## Recommendations
%[text] **Use Continuous when:** you need guaranteed values <= 1.0; you're evaluating at arbitrary wavelengths; this is the right default for general colorimetric work.
%[text] **Use Sampled when:** you're matching a specific reference dataset (Pycone, published tables); you need bit-exact reproducibility on a known grid. Use the matching evaluation grid to avoid off-grid exceedance.
%%
%[text] ## Key takeaways
%[text] - `Continuous` (default) finds the exact peak via optimisation; resolution-independent; never exceeds 1.0
%[text] - `Sampled` finds the max over a discrete grid; resolution-dependent; may exceed 1.0 between grid points
%[text] - Use `struct('Method', "Sampled", 'Start', a, 'Stop', b, 'Step', s)` for explicit grid control
%[text] - `obs.getPeak('L')` returns the unnormalised peak (the divisor)
%[text] - For Pycone parity, set `Step` to match the Pycone session's configuration and evaluate on the same grid \
%[text] **Next:** [Example 17: Publication-Quality Figures](matlab:edit('Example17_PublicationFigures.m')) -- using the `CMFPlotter` class for publication-quality multi-panel figures.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

%[text] # Example 17: Normalization Methods
%[text] This example concerns reproducibility. Most users never need to change `NormalizationMethod`, and the default is correct for ordinary colorimetric work. The reason to change it is to match another implementation exactly.
%[text] With `NormalizeOutput=true`, which is the default, each cone fundamental is divided by its peak so that the maximum is 1.0. `NormalizationMethod` decides how that peak is found:
%[text] - **`Continuous`**, the default. It locates the peak by numerical optimization, using `fminbnd`. The result does not depend on any wavelength grid, and the normalized values never exceed 1.0.
%[text] - **`Sampled`**. It takes the largest value on a discrete grid of wavelengths. The result depends on that grid, and the normalized values can exceed 1.0 slightly at wavelengths between grid points. This is what pycone and similar tools do. \
%[text] **Time:** about 10 minutes.
exampleDefaults();
%%
%[text] ## Selecting a method
%[text] Either method can be named. The wavelengths that `Sampled` searches are held in `NormalizationGrid`, which accepts any wavelength vector. The `start:step:stop` form used below is only a convenient way to write one.
%[text] Three of the four output formats are normalized. Absorbance is not, whatever `NormalizeOutput` is set to, because its scale carries meaning. The templates are anchored so that absorbance is 1 at lambda-max, and that is what makes `Lod`, `Mod` and `Sod` the peak axial optical density. The anchoring is a convention that the Fourier fit approximates rather than an exact equality, and it puts the L peak at 0.995.
obs_cont = IndividualCMF(NormalizationMethod="Continuous");
obs_samp = IndividualCMF(NormalizationMethod="Sampled");
grid_default = obs_samp.NormalizationGrid;
table(string(obs_cont.NormalizationMethod), string(obs_samp.NormalizationMethod), ...
      min(grid_default), max(grid_default), numel(grid_default), ...
      'VariableNames', {'Cont_method', 'Samp_method', 'Grid_min', 'Grid_max', 'Grid_points'})
%%
%[text] ## The two methods compared
%[text] Over the visible range the two methods give almost the same L-cone curve. The difference is about 1e-5, in the fifth decimal place. It matters only when the results have to match another implementation exactly.
wl = (400:5:700)';
L_cont = obs_cont.L(wl);
L_samp = obs_samp.L(wl);
tiledlayout(2, 1, 'TileSpacing', 'loose', 'Padding', 'compact');
nexttile
plot(wl, L_cont, 'b-'); hold on
plot(wl, L_samp, 'r--'); hold off
xlabel('Wavelength (nm)'); ylabel('L-Cone Sensitivity')
title('L cone under both methods'); legend('Continuous', 'Sampled')
nexttile
plot(wl, (L_cont - L_samp) * 1e5, '-', 'Color', IndividualCMF.neutralColor())
xlabel('Wavelength (nm)'); ylabel('Difference (x10^{-5})')
title('Continuous minus Sampled, scaled by 10^5')
table(max(abs(L_cont - L_samp)), mean(abs(L_cont - L_samp)), ...
      'VariableNames', {'MaxAbsDiff', 'MeanAbsDiff'})
%%
%[text] ## Reading the divisor
%[text] `getPeak` returns the unnormalized peak value that the method found, which is the number each curve is divided by. The Continuous peak is always at least as large as the Sampled peak, since it can find a maximum lying between grid points.
table(obs_cont.getPeak('L'), obs_samp.getPeak('L'), ...
      obs_cont.getPeak('L') - obs_samp.getPeak('L'), ...
      'VariableNames', {'Continuous_peak', 'Sampled_peak', 'Difference'})
%%
%[text] ## How the grid affects the result
%[text] A coarse grid is less likely to include a point close to the true peak, so it finds a smaller divisor, and dividing by a smaller number gives larger normalized values. A finer grid approaches the Continuous result.
peaks = struct();
for step = [1, 5, 10]
    o = IndividualCMF(NormalizationMethod="Sampled", ...
        NormalizationGrid=380:step:780);
    peaks.(sprintf('step_%d', step)) = o.getPeak('L');
end
table(peaks.step_1, peaks.step_5, peaks.step_10, obs_cont.getPeak('L'), ...
      'VariableNames', {'Step_1nm', 'Step_5nm', 'Step_10nm', 'Continuous'})
%%
%[text] ## Values above 1.0
%[text] Normalizing on a coarse grid and then evaluating on a finer one can give values above 1.0. The finer grid includes wavelengths at which the sensitivity is higher than at any point the coarse grid sampled.
obs_demo  = IndividualCMF(NormalizationMethod="Sampled", NormalizationGrid=380:10:780);
obs_cont2 = IndividualCMF(NormalizationMethod="Continuous");
wl_fine = (500:0.1:600)';
table(max(obs_demo.L(wl_fine)),  max(obs_demo.L(wl_fine))  > 1.0, ...
      max(obs_cont2.L(wl_fine)), max(obs_cont2.L(wl_fine)) > 1.0, ...
      'VariableNames', {'Sampled_max', 'Sampled_exceeds_1', 'Continuous_max', 'Continuous_exceeds_1'})
%%
%[text] ## The same effect drawn
%[text] The figure below covers the wavelengths around the true L-cone peak at 566.7 nm, using a deliberately coarse 5 nm grid for the Sampled method.
%[text] The nearest grid point to the peak is 565 nm, so the Sampled curve reaches exactly 1.0 there. Between 565 and 570 nm it rises above 1.0, reaching about 1.00048. The Continuous curve stays at or below 1.0 everywhere.
%[text] Note the range of the y axis, which spans only 0.004. The amount by which the Sampled curve exceeds 1.0 is less than 5e-4 and would not be visible on an ordinary axis.
wl_zoom = (560:0.01:576)';
obs_samp_5 = IndividualCMF(NormalizationMethod="Sampled", NormalizationGrid=380:5:780);
tiledlayout(1, 1); nexttile
plot(wl_zoom, obs_cont.L(wl_zoom), 'b-'); hold on
plot(wl_zoom, obs_samp_5.L(wl_zoom), 'r--')
plot(wl_zoom, ones(size(wl_zoom)), ':', 'Color', IndividualCMF.neutralColor(), 'LineWidth', 1)
plot((560:5:575)', obs_samp_5.L((560:5:575)'), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r')
hold off
xlabel('Wavelength (nm)'); ylabel('L-Cone Sensitivity')
title('Sampled on a 5 nm grid, against Continuous')
legend('Continuous', 'Sampled (5 nm)', 'y = 1', 'Sampled grid points', 'Location', 'bestoutside')
grid on; ylim([0.997 1.001])
%%
%[text] ## Matching another implementation
%[text] To match an implementation that normalizes on a discrete grid, set `NormalizationMethod="Sampled"`, give `NormalizationGrid` the wavelengths that implementation uses, and evaluate on those same wavelengths. Since the grid is an ordinary wavelength vector, one expression can serve as both.
%[text] pycone needs no work here. It normalizes over 380:1:780, which is already this toolbox's default grid. The grid used below stands in for a different tool, to show what changing it involves.
wl_reference = (390:5:830)';
obs_reference = IndividualCMF(NormalizationMethod="Sampled", NormalizationGrid=wl_reference);
table(string(obs_reference.NormalizationMethod), ...
      min(obs_reference.NormalizationGrid), ...
      max(obs_reference.NormalizationGrid), ...
      numel(obs_reference.NormalizationGrid), ...
      'VariableNames', {'Method', 'Grid_min', 'Grid_max', 'Grid_points'})
%[text] Evaluating on the same grid gives a maximum of exactly 1, because the wavelength the divisor came from is one of the wavelengths being evaluated. Values above 1.0 appear only when the evaluation grid is finer than the normalization grid.
table(max(obs_reference.L(wl_reference)), max(obs_reference.L((390:0.1:830)')), ...
      'VariableNames', {'On_its_own_grid', 'On_a_finer_grid'})
%%
%[text] ## Which method to use
%[text] Use **Continuous** when the values must not exceed 1.0, and when evaluating at arbitrary wavelengths. It is the right choice for ordinary colorimetric work.
%[text] Use **Sampled** when matching a particular reference implementation or a published table, and when the results have to agree with it exactly. Evaluate on the same grid used for normalization, so that no value exceeds 1.0.
%[text] Note that `NormalizationMethod` and `NormalizationGrid` are not carried by `getParameters` and `setParameters`, which hold the observer's biophysical state only. An observer restored from a saved parameter set comes back with `Continuous` even if it was configured as `Sampled`, and no warning is issued. Set both properties again after any such transfer. See [Example 16](matlab:edit('Example16_DataExport.m')).
%%
%[text] ## Key takeaways
%[text] - `Continuous`, the default, finds the peak by optimization. It does not depend on a grid and never returns values above 1.0
%[text] - `Sampled` takes the largest value on a grid. It depends on that grid and can return values slightly above 1.0 between grid points
%[text] - `NormalizationGrid` sets the wavelengths that `Sampled` searches
%[text] - `obs.getPeak('L')` returns the divisor
%[text] - For agreement with pycone, set `NormalizationMethod="Sampled"`, keep the default grid of 380:1:780, and evaluate on that grid. The method is the part that matters, since under `Continuous` the grid is not used at all and the result is about 1e-5 away \
%[text] **Next:** [Example 18: Publication-Quality Figures](matlab:edit('Example18_PublicationFigures.m')). Building multi-panel figures and exporting them.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

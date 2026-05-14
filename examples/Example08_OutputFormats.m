%[text] # Example 08: Output Formats and Units
%[text] Cone sensitivities can be expressed at different stages of the visual pipeline. Four output formats are available via the `OutputFormat` property:
%[text:table]
%[text] | Format | Stage | Units |
%[text] | --- | --- | --- |
%[text] | `"absorbance"` | Photopigment absorbance (intrinsic) | Linear, fraction (0-1); set `LogOutput=true` for $\\log_{10}$ |
%[text] | `"absorptance"` | After self-screening (relative retinal absorptance) | Linear, peaks near 1; raw `1 - 10^(-OD*A)` is available via `pipeline.PhotopigmentStage.absorptanceFromAbsorbance` |
%[text] | `"quantal"` | Corneal, photon-counting | Linear |
%[text] | `"energy"` *(default)* | Corneal, energy/power | Linear |
%[text:table]
%[text] **Time:** about 12 minutes.
exampleDefaults();
%%
%[text] ## Pick a format at construction or change it later
%[text] You can either pass `OutputFormat` to the constructor or assign it after the fact. Both work.
obs_dynamic = IndividualCMF();
fmt_before = string(obs_dynamic.OutputFormat);
obs_dynamic.OutputFormat = "quantal";
fmt_after = string(obs_dynamic.OutputFormat);
table(fmt_before, fmt_after, 'VariableNames', {'Default', 'AfterAssignment'})
%%
%[text] ## Or override per call without mutating the observer
%[text] Pass `OutputFormat` (or `LogOutput`, `NormalizeOutput`) as Name-Value directly to `LMS` for a one-off readout. The observer's persistent state is untouched.
obs_one_shot = IndividualCMF();   % default OutputFormat = "energy"
L_energy        = obs_one_shot.LMS(555);                              % uses observer's "energy"
L_quantal       = obs_one_shot.LMS(555, OutputFormat="quantal");
L_absorbance    = obs_one_shot.LMS(555, OutputFormat="absorbance");
fmt_after_calls = string(obs_one_shot.OutputFormat);
table(L_energy(1), L_quantal(1), L_absorbance(1), fmt_after_calls, ...
      'VariableNames', {'Energy', 'Quantal', 'Absorbance_linear', 'ObserverFormat'})
%%
%[text] ## Visual comparison of all four formats
%[text] All four formats plotted for L, M, S over the visible range using the toolbox's stage-specific plot wrappers: `plotAbsorbance`, `plotAbsorptance`, and `plotLMS` (which plots in the observer's current `OutputFormat`). The shapes are clearly different -- each represents a different physical quantity. Absorbance values are linear in \[0, 1\]; pass `LogOutput=true` (or `Log=true` to `plotAbsorbance`) if you want log10.
wl = (390:1:700)';
obs_abs  = IndividualCMF(OutputFormat="absorbance");
obs_absp = IndividualCMF(OutputFormat="absorptance");
obs_q    = IndividualCMF(OutputFormat="quantal");
obs_e    = IndividualCMF(OutputFormat="energy");
f = gcf;
f.Position(3:4) = [800 900];
tiledlayout(f, 4, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
obs_abs.plotAbsorbance(Title="Absorbance (intrinsic)", Wavelength=wl, Parent=nexttile);
xlim([390 700]); ylim([0 1.1])
obs_absp.plotAbsorptance(Title="Absorptance (after self-screening)", Wavelength=wl, Parent=nexttile);
xlim([390 700]); ylim([0 1.1])
obs_q.plotLMS(Title="Quantal (corneal, photon-based)", Wavelength=wl, Parent=nexttile);
xlim([390 700]); ylim([0 1.1])
obs_e.plotLMS(Title="Energy (corneal, default)", Wavelength=wl, Parent=nexttile);
xlim([390 700]); ylim([0 1.1])
%%
%[text] ## The `"absorptance"` convention
%[text] `OutputFormat="absorptance"` returns the **relative** absorptance, $ (1 - 10^{-\\mathrm{OD}\\cdot A}) / (1 - 10^{-\\mathrm{OD}}) $, which peaks near 1.0 by construction. This is *not* the raw Beer-Lambert fraction $ 1 - 10^{-\\mathrm{OD}\\cdot A} $. If you need the raw fraction, call `pipeline.PhotopigmentStage.absorptanceFromAbsorbance(linAbs, od, Normalize=false)`.
%%
%[text] ## Energy vs quantal -- the wavelength factor
%[text] Energy and quantal differ by an explicit wavelength factor: the *sensitivity* in energy units is `alpha*lambda*sensitivity_quantal` (S&R 2023, Eq. 8). Multiplying by lambda shifts the peak slightly toward **longer** wavelengths relative to the quantal version. The shift is small but consistent across all three cones. `compareTo` handles the two-observer overlay; the legend is relabeled after the call to distinguish quantal vs energy.
tiledlayout(1, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
obs_q.compareTo(obs_e, Title="Quantal (solid) vs Energy (dashed)", Wavelength=wl, Parent=nexttile);
xlim([390 700]); ylim([0 1.1])
legend({'L (q)', 'M (q)', 'S (q)', 'L (e)', 'M (e)', 'S (e)'}, ...
       'Location', 'bestoutside', 'NumColumns', 2);
%%
%[text] ## Trace one wavelength through the pipeline
%[text] At a fixed wavelength (here 555 nm) the four formats produce very different numeric values -- they are not normalisations of the same underlying quantity, they are different *stages* of the pipeline.
test_wl = 555;
table(obs_abs.L(test_wl), obs_absp.L(test_wl), obs_q.L(test_wl), obs_e.L(test_wl), ...
      'VariableNames', {'Absorbance_linear', 'Absorptance_relative', 'Quantal', 'Energy'})
%[text] Each number is the previous one's stage transformed: **absorbance** is the photopigment shape; **absorptance** applies self-screening; **quantal** applies pre-receptoral filtering (lens + macular); **energy** multiplies by wavelength.
%%
%[text] ## When to use each
%[text] - **`absorbance`** -- studying photopigment properties; comparing to microspectrophotometry; template model development
%[text] - **`absorptance`** -- modelling photoreceptor response at the retinal level; studying self-screening
%[text] - **`quantal`** -- photon-based calculations; quantum efficiency studies; stimuli specified in photons / area
%[text] - **`energy`** -- *(default)* standard colorimetric calculations; CIE color matching; display and lighting; stimuli in watts or joules
%%
%[text] ## Two orthogonal output controls -- `NormalizeOutput` and `LogOutput`
%[text] - `NormalizeOutput` *(default true)* -- divides each curve by its peak so the maximum is 1.0. Set to `false` to see raw pipeline values.
%[text] - `LogOutput` *(default false)* -- wraps the result in `log10` after normalisation. Useful for inspecting the tails. \
%[text] Both are independent of `OutputFormat`.
obs_unnorm = IndividualCMF(NormalizeOutput=false, OutputFormat="energy");
table(max(obs_unnorm.L(wl)), max(obs_unnorm.M(wl)), max(obs_unnorm.S(wl)), ...
      'VariableNames', {'L_peak_raw', 'M_peak_raw', 'S_peak_raw'})
%%
%[text] ## L-cone on a log scale
%[text] `plotLMS(Cones="L", Log=true)` selects the L-cone alone and plots it on a log10 axis -- the absorption tails are otherwise lost in linear-axis plots.
tiledlayout(1, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
obs_e.plotLMS(Cones="L", Log=true, Title="L-cone Energy Sensitivity (Log Scale)", Wavelength=wl, Parent=nexttile);
xlim([390 700]); ylim([-4 0.25])
%%
%[text] ## Practical example -- LMS response to display primaries
%[text] Typical RGB display primary wavelengths and the corresponding LMS sensitivities in the default energy format.
obs_display = IndividualCMF(OutputFormat="energy");
display_primaries = [615; 545; 465];
LMS_primaries = obs_display.LMS(display_primaries);
array2table([display_primaries, LMS_primaries], ...
    'VariableNames', {'Wavelength_nm', 'L', 'M', 'S'}, ...
    'RowNames', {'Red', 'Green', 'Blue'})
%%
%[text] ## Key takeaways
%[text] - Four output formats: `absorbance`, `absorptance`, `quantal`, `energy`
%[text] - `energy` is the default and the right choice for colorimetry
%[text] - `quantal` and `energy` differ by an explicit wavelength factor (E = hc/lambda)
%[text] - Set `OutputFormat` at construction, change it dynamically, or override per call via `obs.LMS(wl, OutputFormat=...)`
%[text] - `NormalizeOutput` and `LogOutput` are independent post-processing controls \
%[text] **Next:** [Example 09: RGB Color Matching Functions](matlab:edit('Example09_RGBColorMatching.m')) -- RGB color matching functions and custom primaries.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

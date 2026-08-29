%[text] # Example 15: Advanced Customization
%[text] Full control over every observer parameter for specialized applications: building hypothetical observers, exploring the parameter space, encoding individual variation, and round-tripping observer state for reproducibility.
%[text] **Time:** about 15 minutes.
exampleDefaults();
%%
%[text] ## Constructor argument reference
%[text:table]
%[text] | Group | Arguments |
%[text] | --- | --- |
%[text] | Standard configuration | `StandardObserver` (2 or 10 -- rejects any conflicting *biophysical* argument; output settings such as `OutputFormat` are still allowed) |
%[text] | Physiological | `Age`, `FieldSize`, `LensDensity`, `MacularDensity`, `Lod`, `Mod`, `Sod` |
%[text] | Template & genetics | `PhotopigmentModel`, `LensModel`, `MacularModel`, `L_OpsinTemplate`, `M_OpsinTemplate`, `L_LambdaMaxShift`, `M_LambdaMaxShift`, `S_LambdaMaxShift`, `Genotype` |
%[text] | Algorithm selection | `MacularDensityAlgorithm`, `PhotopigmentDensityAlgorithm`, `LensDensityAlgorithm` |
%[text] | Output configuration | `OutputFormat`, `NormalizeOutput`, `LogOutput`, `Primaries`, `NormalizationMethod`, `NormalizationGrid` |
%[text:table]
%%
%[text] ## Building a custom observer step-by-step
%[text] Combine arbitrary parameter selections in a single constructor call. The result reports `Type = "Individualized"` because it doesn't match the CIE 2 deg/10 deg spec.
obs_custom = IndividualCMF( ...
    Age=45, FieldSize=6, ...
    L_OpsinTemplate="Serine", ...
    L_LambdaMaxShift=2, ...
    LensModel="VanDeKraats2007", ...
    MacularDensityAlgorithm="MorelandAlexander", ...
    PhotopigmentDensityAlgorithm="PokornySmith", ...
    NormalizationMethod="Continuous", ...
    OutputFormat="energy")
%%
%[text] ## Direct density overrides -- Custom mode in action
%[text] Direct assignment to `LensDensity`, `MacularDensity`, `Lod/Mod/Sod` auto-engages the corresponding `*Algorithm` to `"Custom"`. This protects the override from being silently re-derived when its driving parameter changes -- `FieldSize` for the macular and cone densities, and `Age`, `FieldSize` or `LensModel` for lens density. One subtlety, and it differs by property. For the **cone and macular** densities the auto-engage compares against the CIE table, but only at field sizes 2 and 10 -- so `Sod = 0.30` on a 10 deg observer leaves the algorithm at `CIE170`, while the same no-op assignment at 6 deg engages `Custom`, because there is no table to compare against. **Lens** density has no comparison at all: assigning it always engages `Custom`, even at the standard 1.7649.
%[text] Precedence here is override, not composition: the assigned value replaces the age / field-size formula result rather than adding to it (contrast Asano, Fairchild & Blonde 2016, where age and a separate density deviation compose).
obs_override = IndividualCMF();
obs_override.LensDensity    = 2.5;
obs_override.MacularDensity = 0.6;
obs_override.Lod = 0.35; obs_override.Mod = 0.35; obs_override.Sod = 0.25;
table(obs_override.LensDensity,    string(obs_override.LensDensityAlgorithm), ...
      obs_override.MacularDensity, string(obs_override.MacularDensityAlgorithm), ...
      obs_override.Lod,            string(obs_override.PhotopigmentDensityAlgorithm), ...
      'VariableNames', {'LensDensity', 'LensAlg', 'MacularDensity', 'MacAlg', 'Lod', 'PhotoAlg'})
%%
%[text] ## Pinning one density pins its whole group
%[text] Custom mode is granted per *group*, not per property: the three cone densities move together, and pinning any one of them freezes the other two at whatever they held at that moment. That is the number-one surprise in this API, and it bites when a later `FieldSize` change silently fails to reach the cones you did not assign.
obs_group = IndividualCMF(FieldSize=10);
mod_before = obs_group.Mod;
obs_group.Lod = 0.35;
obs_group.FieldSize = 2;
table(mod_before, obs_group.Mod, IndividualCMF(FieldSize=2).Mod, ...
      'VariableNames', {'Mod_at_10deg', 'Mod_after_FieldSize2', 'Mod_a_normal_2deg_has'})
%[text] Only `Lod` was assigned, yet `Mod` stayed at its 10 deg value instead of recomputing to the 2 deg one. Assigning `[]` to any member reverts the whole group, for the same reason: one formula produces all three.
%%
%[text] ## Custom-mode protection across an Age change
%[text] Setting `Age=80` would normally recalculate `LensDensity` from the active lens model. Because we engaged Custom mode in the previous section, the override sticks.
obs_override.Age = 80;
table(obs_override.Age, obs_override.LensDensity, string(obs_override.LensDensityAlgorithm), ...
      'VariableNames', {'Age', 'LensDensity', 'Algorithm'})
%%
%[text] ## Returning to model-driven behaviour
%[text] Assigning `[]` is the inverse of pinning a value: it clears `Custom` and recomputes `LensDensity` from `Age` and the active lens model. Discarding the override is the whole point of the call, so it does not warn. Setting `LensDensityAlgorithm="Auto"` does the same thing and emits an `IndividualCMF:LensCustomOverwritten` warning, since there the override loss is a side effect rather than the request. **Note:** the default `LensModel="StockmanRider2023"` is age-flat, so the recompute here returns the canonical 32-year-old value (1.7649) even though `Age=80`. Switch to `LensModel="VanDeKraats2007"` for age-dependent recompute.
obs_override.LensDensity = [];
table(obs_override.Age, obs_override.LensDensity, string(obs_override.LensDensityAlgorithm), ...
      'VariableNames', {'Age', 'LensDensity_after_revert', 'Algorithm'})
%%
%[text] ## Hypothetical observers -- sensitivity analysis
%[text] Push parameters to extremes for what-if studies. The next three sections each isolate one effect: extreme lens density, an anomalous trichromat with a strongly blue-shifted L-cone, and the full LMS impact of that anomalous L-cone.
wl = (390:1:700)';
obs_low_lens  = IndividualCMF(LensModel="VanDeKraats2007", Age=20, FieldSize=10, LensDensity=1.2);
obs_high_lens = IndividualCMF(LensModel="VanDeKraats2007", Age=80, FieldSize=10, LensDensity=3.5);
obs_normal    = IndividualCMF();
obs_anomalous = IndividualCMF(L_OpsinTemplate="Serine", L_LambdaMaxShift=-15);
%%
%[text] ### Lens density extremes
%[text] Custom-mode lens density override pushed to the edges of the plausible human range. Both curves are peak-normalized, so the dense lens's real effect -- absorbing far more short-wavelength light -- appears here as a reshaping rather than a loss: the apparent S peak sits near 455 nm instead of 440, and the long flank rides higher (0.59 against 0.32 at 480 nm). The amplitude difference is divided out.
plot(wl, obs_low_lens.S(wl),  'b-'); hold on
plot(wl, obs_high_lens.S(wl), 'b--'); hold off
xlabel('Wavelength (nm)'); ylabel('S-Cone Sensitivity')
title('Lens density extremes -- S-cone'); legend('LensDensity = 1.2', 'LensDensity = 3.5', 'Location', 'bestoutside')
grid on; xlim([390 520])
%%
%[text] ### Anomalous L-cone (-15 nm shift)
%[text] An L-cone shifted 15 nm toward shorter wavelengths -- the kind of magnitude associated with strong anomalous trichromacy.
plot(wl, obs_normal.L(wl),    'r-'); hold on
plot(wl, obs_anomalous.L(wl), 'r--'); hold off
xlabel('Wavelength (nm)'); ylabel('L-Cone Sensitivity')
title('Anomalous L-cone (-15 nm)'); legend('Normal', '-15 nm shift', 'Location', 'bestoutside')
grid on; xlim([480 650])
%%
%[text] ### Full LMS -- normal vs anomalous trichromat
%[text] The same observer pair as above, plotted across the full visible range with all three cones overlaid (solid = normal, dashed = anomalous). `obs.compareTo(other)` handles the two-observer overlay -- reference solid, comparison dashed. The L shift visibly compresses the L-M separation.
obs_normal.compareTo(obs_anomalous, Title="Normal (solid) vs anomalous (dashed)", Wavelength=wl);
xlim([390 700])
%%
%[text] ## Genotype and primaries -- see earlier examples
%[text] Per-codon `Genotype=` and `setGenotype`/`applyGenotype` are covered in [Example 06: Genetic Variants](matlab:edit('Example06_GeneticVariants.m')). Custom `Primaries` is covered in [Example 10: RGB Color Matching Functions](matlab:edit('Example10_RGBColorMatching.m')).
%%
%[text] ## A fully customized observer
%[text] Combining everything in one call. The displayed property listing makes the parameter set self-documenting.
obs_full = IndividualCMF( ...
    Age=55, FieldSize=8, ...
    L_OpsinTemplate="Serine", ...
    L_LambdaMaxShift=3, M_LambdaMaxShift=-1, ...
    PhotopigmentModel="StockmanRider2023", ...
    LensModel="VanDeKraats2007", ...
    MacularDensityAlgorithm="MorelandAlexander", ...
    PhotopigmentDensityAlgorithm="PokornySmith", ...
    NormalizationMethod="Continuous", ...
    OutputFormat="energy", NormalizeOutput=true, LogOutput=false, ...
    Primaries=[620, 535, 460])
%%
%[text] ## Parameter validation
%[text] The constructor's argument validators reject out-of-range or unknown values upfront with helpful errors. Three examples (each wrapped in `try/catch` for the demo):
errors = strings(0);
try, IndividualCMF(Age=-5); catch ME, errors(end+1) = ME.message; end
try, IndividualCMF(L_LambdaMaxShift=20); catch ME, errors(end+1) = ME.message; end
try, IndividualCMF(L_OpsinTemplate="Invalid"); catch ME, errors(end+1) = ME.message; end
table(["Age=-5"; "L_LambdaMaxShift=20"; "L_OpsinTemplate=""Invalid"""], errors', ...
      'VariableNames', {'Bad_input', 'Validation_error'})
%%
%[text] ## Saving, loading, and round-trip transfer
%[text] Two ways to persist an observer:
save_path = fullfile(tempdir, 'custom_observer.mat');
save(save_path, 'obs_full');
loaded = load(save_path);
params = obs_full.getParameters();
obs_clone = IndividualCMF();
obs_clone.setParameters(params);
wl_check = (400:5:700)';
maxAbsDiff = max(abs(obs_full.LMS(wl_check) - obs_clone.LMS(wl_check)), [], 'all');
table(loaded.obs_full.Age == obs_full.Age, ...
      maxAbsDiff < 1e-12, ...
      maxAbsDiff, ...
      'VariableNames', {'DirectSave_AgeMatches', 'RoundTrip_LMS_within_tol', 'MaxAbsDiff'})
%[text] What the snapshot does *not* carry is the output-shape settings. `ObserverParameters` holds the biophysics -- who the observer is -- not how their numbers are reported. Give the source a non-default `OutputFormat` and the round trip no longer reproduces the same array:
obs_shaped = IndividualCMF(Age=55, OutputFormat="quantal", NormalizeOutput=false);
obs_reshaped = IndividualCMF();
obs_reshaped.setParameters(obs_shaped.getParameters());
table(string(obs_shaped.OutputFormat), string(obs_reshaped.OutputFormat), ...
      obs_shaped.Age == obs_reshaped.Age, ...
      isequal(obs_shaped.LMS(wl_check), obs_reshaped.LMS(wl_check)), ...
      'VariableNames', {'Source_Format', 'Restored_Format', 'Age_Matches', 'LMS_Identical'})
%[text] Age transfers; the format does not, so the arrays differ. Set the output-shape properties explicitly on the receiving observer when you need them to match.
%%
%[text] ## Key takeaways
%[text] - **Direct save** of the whole `IndividualCMF` object -- opaque, but simple
%[text] - **`getParameters`** / **`setParameters`** round-trip via the `ObserverParameters` value class -- preserves every *biophysical* field (physiological values, `LensModel`, `PhotopigmentModel`, opsin templates, all algorithm modes including `LensDensityAlgorithm`)
%[text] - Many constructor arguments allow fine-grained observer modeling
%[text] - Direct density assignments auto-engage `"Custom"` mode, protecting overrides from re-derivation
%[text] - `LensDensityAlgorithm`, `MacularDensityAlgorithm`, `PhotopigmentDensityAlgorithm` are the three density-algorithm properties
%[text] - `setGenotype`, `applyGenotype`, and the `Genotype=` constructor arg are three paths to genetic configuration, differing in granularity
%[text] - All parameters are validated with helpful error messages \
%[text] **Next:** [Example 16: Data Export Workflows](matlab:edit('Example16_DataExport.m')) -- exporting cone fundamentals as arrays, tables, structs, CSV, Excel, and MAT files via the `evaluate` method.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

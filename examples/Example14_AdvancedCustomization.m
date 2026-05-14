%[text] # Example 14: Advanced Customization
%[text] Full control over every observer parameter for specialized applications: building hypothetical observers, exploring the parameter space, encoding individual variation, and round-tripping observer state for reproducibility.
%[text] **Time:** about 15 minutes.
exampleDefaults();
%%
%[text] ## Constructor argument reference
%[text:table]
%[text] | Group | Arguments |
%[text] | --- | --- |
%[text] | Standard configuration | `StandardObserver` (2 or 10 -- locks all other params) |
%[text] | Physiological | `Age`, `FieldSize`, `LensDensity`, `MacularDensity`, `Lod`, `Mod`, `Sod` |
%[text] | Template & genetics | `PhotopigmentModel`, `LensModel`, `L_OpsinTemplate`, `M_OpsinTemplate`, `L_LambdaMaxShift`, `M_LambdaMaxShift`, `S_LambdaMaxShift`, `Genotype` |
%[text] | Algorithm selection | `MacularDensityAlgorithm`, `PhotopigmentDensityAlgorithm`, `LensDensityAlgorithm`, `NormalizationMethod` |
%[text] | Output configuration | `OutputFormat`, `NormalizeOutput`, `LogOutput`, `Primaries` |
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
%[text] Direct assignment to `LensDensity`, `MacularDensity`, `Lod/Mod/Sod` auto-engages the corresponding `*Algorithm` to `"Custom"`. This protects the override from being silently re-derived if you later change `Age`, `FieldSize`, or `LensModel`.
obs_override = IndividualCMF();
obs_override.LensDensity    = 2.5;
obs_override.MacularDensity = 0.6;
obs_override.Lod = 0.35; obs_override.Mod = 0.35; obs_override.Sod = 0.30;
table(obs_override.LensDensity,    string(obs_override.LensDensityAlgorithm), ...
      obs_override.MacularDensity, string(obs_override.MacularDensityAlgorithm), ...
      obs_override.Lod,            string(obs_override.PhotopigmentDensityAlgorithm), ...
      'VariableNames', {'LensDensity', 'LensAlg', 'MacularDensity', 'MacAlg', 'Lod', 'PhotoAlg'})
%%
%[text] ## Custom-mode protection across an Age change
%[text] Setting `Age=80` would normally recalculate `LensDensity` from the active lens model. Because we engaged Custom mode in the previous section, the override sticks.
obs_override.Age = 80;
table(obs_override.Age, obs_override.LensDensity, string(obs_override.LensDensityAlgorithm), ...
      'VariableNames', {'Age', 'LensDensity', 'Algorithm'})
%%
%[text] ## Returning to model-driven behaviour
%[text] Switching `LensDensityAlgorithm="Auto"` recomputes `LensDensity` from `Age` and the active lens model. The setter emits an `IndividualCMF:LensCustomOverwritten` warning to make the override-loss explicit (we suppress it for the demo). **Note:** the default `LensModel="StockmanRider2023"` is age-flat, so Auto recompute here returns the canonical 32-year-old value (1.7649) even though `Age=80`. Switch to `LensModel="VanDeKraats2007"` for age-dependent recompute.
warning('off', 'IndividualCMF:LensCustomOverwritten');
obs_override.LensDensityAlgorithm = "Auto";
warning('on', 'IndividualCMF:LensCustomOverwritten');
table(obs_override.Age, obs_override.LensDensity, string(obs_override.LensDensityAlgorithm), ...
      'VariableNames', {'Age', 'LensDensity_after_Auto', 'Algorithm'})
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
%[text] Custom-mode lens density override pushed to the edges of the plausible human range.
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
%[text] Per-codon `Genotype=` and `setGenotype`/`applyGenotype` are covered in [Example 05: Genetic Variants](matlab:edit('Example05_GeneticVariants.m')). Custom `Primaries` is covered in [Example 09: RGB Color Matching Functions](matlab:edit('Example09_RGBColorMatching.m')).
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
%%
%[text] ## Key takeaways
%[text] - **Direct save** of the whole `IndividualCMF` object -- opaque, but simple
%[text] - **`getParameters`** / **`setParameters`** round-trip via the `ObserverParameters` value class -- preserves *every* field that affects LMS output (physiological values, `LensModel`, `PhotopigmentModel`, opsin templates, all algorithm modes including `LensDensityAlgorithm`)
%[text] - Many constructor arguments allow fine-grained observer modeling
%[text] - Direct density assignments auto-engage `"Custom"` mode, protecting overrides from re-derivation
%[text] - `LensDensityAlgorithm`, `MacularDensityAlgorithm`, `PhotopigmentDensityAlgorithm` are the three Custom-mode toggles
%[text] - `setGenotype`, `applyGenotype`, and the `Genotype=` constructor arg are three equivalent paths to genetic configuration
%[text] - All parameters are validated with helpful error messages \
%[text] **Next:** [Example 15: Data Export Workflows](matlab:edit('Example15_DataExport.m')) -- exporting cone fundamentals as arrays, tables, structs, CSV, Excel, and MAT files via the `evaluate` method.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

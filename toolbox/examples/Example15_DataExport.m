%[text] # Example 15: Data Export Workflows
%[text] How to get cone-fundamental data out of an observer in a form usable by other tools -- CSV, MAT, or directly into a MATLAB table or struct. (`writetable` also writes `.xlsx` if you give it one; the mechanics are identical and not shown here.)
%[text] The unified entry point is `obs.evaluate(wl, Data=...)`, which always returns a table: a `Wavelength_nm` column followed by one column per channel. `Data` selects which quantity you get. For a bare numeric array, call the named method (`obs.LMS(wl)`, `obs.RGB(wl)`, ...) instead.
%[text] **Time:** about 10 minutes.
exampleDefaults();
%%
%[text] ## The `evaluate` method
%[text] **Syntax:** `[result, wl] = obs.evaluate(wl, Data=...)`
%[text] Each `Data` value delegates to the method of the same name, so the table and the direct call always agree.
%[text:table]
%[text] | `Data` | Columns | Equivalent method |
%[text] | --- | --- | --- |
%[text] | `"LMS"` *(default)* | `L`, `M`, `S` | `obs.LMS(wl)` |
%[text] | `"L"`, `"M"`, `"S"` | one cone | `obs.L(wl)` |
%[text] | `"RGB"` | `R`, `G`, `B` | `obs.RGB(wl)` |
%[text] | `"XYZ"` | `X`, `Y`, `Z` | `obs.XYZ(wl)` |
%[text] | `"Luminance"` | `V` | `obs.Luminance(wl)` |
%[text] | `"lmChromaticity"` | `l`, `m` | `obs.lmChromaticity(wl)` |
%[text] | `"xyChromaticity"` | `x`, `y` | `obs.xyChromaticity(wl)` |
%[text] | `"MacLeodBoynton"` | `l_MB`, `s_MB` | `obs.MacLeodBoynton(wl)` |
%[text:table]
obs = IndividualCMF();
wl = (380:5:780)';
%%
%[text] ## A labelled table
%[text] Each cone gets its own named column, with `Wavelength_nm` first. This is the form to hand straight to `writetable`, `stackedplot`, or `groupsummary`.
data_table = obs.evaluate(wl, Data='LMS');
head(data_table, 5)
%%
%[text] ## Getting a raw numeric matrix
%[text] For downstream computation, call the named method. It skips the table wrapper entirely, so there is nothing to unpack.
data_array = obs.LMS(wl);
size(data_array)
data_array(1:5, :)
%%
%[text] ## Getting a struct
%[text] `table2struct` with `ToScalar=true` gives one field per column, which is what you want for MAT-file storage.
data_struct = table2struct(data_table, ToScalar=true);
fieldnames(data_struct)
%%
%[text] ## Other `Data` selections
%[text] `evaluate` covers more than LMS. RGB and XYZ color matching functions, luminance, and all three chromaticity conventions are available from the same call.
L_only = obs.evaluate(wl, Data='L');
RGB    = obs.evaluate(wl, Data='RGB');
chrom  = obs.evaluate(wl, Data='lmChromaticity');
table(width(L_only) - 1, width(RGB) - 1, width(chrom) - 1, ...
      'VariableNames', {'L_cols', 'RGB_cols', 'lmChromaticity_cols'})
%%
%[text] ## Export to CSV
%[text] `writetable` takes the `evaluate` output as-is; the column names carry through to the header row.
csv_path = fullfile(tempdir, 'cone_fundamentals.csv');
writetable(data_table, csv_path);
csv_lines = readlines(csv_path);
disp(csv_lines(1:min(6, end)))
%%
%[text] ## Export to MAT -- preserve full precision and metadata
%[text] For pure-MATLAB workflows, `.mat` is the native choice. It also handles arbitrary nested structures, so you can co-locate the data with provenance metadata.
%[text] Do not hand-copy the observer's parameters into a struct. `getParameters` returns an `ObserverParameters` value object that already holds every biophysical field, survives `save`/`load`, and reconstructs the observer exactly -- a transcribed list silently drops whatever you forgot, and for a non-default observer that is usually the interesting part (lambda-max shifts, cone optical densities and opsin templates all vanish from a hand-written struct).
%[text] What `getParameters` does *not* carry is the output settings, and those decide what the numbers mean: `NormalizeOutput` and `NormalizationMethod` distinguish peak-normalized from absolute, `LogOutput` decides whether the values are log10, and `Primaries` is required to interpret the RGB columns at all, since RGB CMFs are defined relative to them. Record those alongside. Worth adding a toolbox version too, from `ver` for an installed toolbox -- normalization behaviour is still settling in this beta series, so a file without one is hard to reinterpret later.
metadata = struct( ...
    'parameters',            obs.getParameters(), ...
    'observer_type',         char(obs.Type), ...
    'output_format',         char(obs.OutputFormat), ...
    'normalize_output',      obs.NormalizeOutput, ...
    'log_output',            obs.LogOutput, ...
    'normalization_method',  char(obs.NormalizationMethod), ...
    'normalization_grid',    obs.NormalizationGrid, ...
    'primaries_nm',          obs.Primaries, ...
    'created',               char(datetime('now')));
full_export = struct( ...
    'metadata',   metadata, ...
    'wavelength', wl, ...
    'LMS',        obs.LMS(wl), ...
    'RGB',        obs.RGB(wl));
mat_path = fullfile(tempdir, 'full_export.mat');
save(mat_path, 'full_export');
whos('-file', mat_path)
%%
%[text] ## Multi-observer comparison export
%[text] A common workflow: scan over a parameter (here, age), pull the L-cone for each, and assemble a single CSV. This makes comparing observers in external tools trivial.
ages = [25, 50, 75];
%[text] The `VanDeKraats2007` lens is fitted on 300-700 nm, so evaluating it past 700 raises `IndividualCMF:WavelengthOutOfRange` once per observer. The extrapolation there is a smooth bounded decay and the values are kept; the warning is silenced below because model range is not what this example is about. See [Example 04](matlab:edit('Example04_AgingEffects.m')) for the `ValidRange` / `Domain` contract.
age_observers = IndividualCMF.across('Age', ages, ...
    LensModel="VanDeKraats2007", FieldSize=10);
[age_observers.ModelRangeWarning] = deal(false);
comparison = table(wl, 'VariableNames', {'Wavelength_nm'});
for i = 1:numel(ages)
    comparison.(sprintf('L_age%d', ages(i))) = age_observers(i).L(wl);
end
writetable(comparison, fullfile(tempdir, 'L_cone_by_age.csv'));
head(comparison, 5)
%%
%[text] ## Round-trip via `getParameters` / `setParameters`
%[text] For pure-MATLAB persistence of an observer's *configuration* (rather than its evaluated data), use `getParameters` to get an `ObserverParameters` value object and save that; `setParameters` restores. The full demonstration is in [Example 14: Advanced Customization](matlab:edit('Example14_AdvancedCustomization.m')).
%%
%[text] ## Direct array methods
%[text] `evaluate` delegates to the named methods rather than reimplementing them, so the two agree bit for bit. Use whichever fits the calling code.
LMS_direct = obs.LMS(wl);
LMS_via_evaluate = table2array(data_table(:, 2:end));
isequal(LMS_direct, LMS_via_evaluate)
%%
%[text] ## Key takeaways
%[text] - `evaluate(wl, Data=...)` always returns a labelled table, one column per channel
%[text] - For an array call the named method; for a struct use `table2struct(t, ToScalar=true)`
%[text] - `writetable` handles CSV; `save` handles MAT
%[text] - CSV carries data only. Put the observer's parameters -- including `NormalizeOutput`, `NormalizationMethod` and `Primaries` -- in the MAT metadata struct, or encode the varying parameter in the column names, as the multi-observer export does with age, so a recipient can tell what the numbers are
%[text] - For biophysical state, use the `getParameters`/`setParameters` round trip -- it carries the physiology but not the output settings, which must be recorded separately \
%[text] **Next:** [Example 16: Normalization Methods](matlab:edit('Example16_NormalizationMethods.m')) -- Continuous vs Sampled normalization and reproducibility.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

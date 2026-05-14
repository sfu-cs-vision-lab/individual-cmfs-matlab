%[text] # Example 15: Data Export Workflows
%[text] How to get cone-fundamental data out of an observer in a form usable by other tools -- CSV, Excel, MAT, or directly into a MATLAB table or struct.
%[text] The unified entry point is `obs.evaluate(wl, Data=..., Format=...)`. The `Format` argument selects how the data is packaged; `Data` selects what is returned.
%[text] **Time:** about 10 minutes.
exampleDefaults();
%%
%[text] ## The `evaluate` method
%[text] **Syntax:** `[result, wl] = obs.evaluate(wl, Data=..., Format=...)`
%[text:table]
%[text] | Argument | Options |
%[text] | --- | --- |
%[text] | `Data` | `"LMS"` *(default)*, `"L"`, `"M"`, `"S"`, `"RGB"`, `"chromaticity"` |
%[text] | `Format` | `"array"` *(default)*, `"table"`, `"struct"` |
%[text:table]
obs = IndividualCMF();
wl = (380:5:780)';
%%
%[text] ## Format = `array` -- raw numeric matrix
%[text] The fastest format for downstream computation. Returns an NxK numeric matrix.
data_array = obs.evaluate(wl, Data='LMS', Format='array');
size(data_array)
data_array(1:5, :)
%%
%[text] ## Format = `table` -- labelled columns
%[text] Best for exploratory analysis and direct CSV / Excel export. Each cone gets its own named column, with `Wavelength_nm` as the first.
data_table = obs.evaluate(wl, Data='LMS', Format='table');
head(data_table, 5)
%%
%[text] ## Format = `struct` -- named fields
%[text] Convenient for programmatic access and storage in MAT files.
data_struct = obs.evaluate(wl, Data='LMS', Format='struct');
fieldnames(data_struct)
%%
%[text] ## Other `Data` selections
%[text] `evaluate` returns more than just LMS. RGB color matching functions and chromaticity coordinates are also available.
L_only = obs.evaluate(wl, Data='L', Format='array');
RGB    = obs.evaluate(wl, Data='RGB', Format='array');
chrom  = obs.evaluate(wl, Data='chromaticity', Format='array');
table(size(L_only,2), size(RGB,2), size(chrom,2), ...
      'VariableNames', {'L_cols', 'RGB_cols', 'chromaticity_cols'})
%%
%[text] ## Export to CSV
%[text] `writetable` handles CSV output directly. Pair with `Format='table'` for clean column labels.
csv_path = fullfile(tempdir, 'cone_fundamentals.csv');
writetable(data_table, csv_path);
csv_lines = readlines(csv_path);
disp(csv_lines(1:min(6, end)))
%%
%[text] ## Export to MAT -- preserve full precision and metadata
%[text] For pure-MATLAB workflows, `.mat` is the native choice. It also handles arbitrary nested structures, so you can co-locate the data with provenance metadata.
metadata = struct( ...
    'observer_type',         char(obs.Type), ...
    'age',                   obs.Age, ...
    'field_size',            obs.FieldSize, ...
    'lens_density',          obs.LensDensity, ...
    'macular_density',       obs.MacularDensity, ...
    'template_model',        char(obs.PhotopigmentModel), ...
    'lens_model',            char(obs.LensModel), ...
    'output_format',         char(obs.OutputFormat), ...
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
age_observers = IndividualCMF.across('Age', ages, ...
    LensModel="VanDeKraats2007", FieldSize=10);
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
%[text] When you don't need the structured output, `obs.LMS(wl)` and `obs.RGB(wl)` return arrays directly without going through `evaluate`. They're a hair faster and produce identical numbers.
LMS_direct = obs.LMS(wl);
LMS_via_evaluate = obs.evaluate(wl, Data='LMS', Format='array');
isequal(LMS_direct, LMS_via_evaluate)
%%
%[text] ## Key takeaways
%[text] - `evaluate(wl, Data=..., Format=...)` is the unified structured-output interface
%[text] - Three formats: `array` (numeric), `table` (CSV/Excel-friendly), `struct` (MAT-friendly)
%[text] - `writetable` handles CSV and multi-sheet Excel; `save` handles MAT
%[text] - Include metadata (observer parameters) so exports are self-documenting
%[text] - For pure observer-state persistence, use `getParameters`/`setParameters` round-trip \
%[text] **Next:** [Example 16: Normalization Methods](matlab:edit('Example16_NormalizationMethods.m')) -- Continuous vs Sampled normalization and reproducibility.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

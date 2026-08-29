%[text] # Example 16: Data Export Workflows
%[text] This example shows how to get data out of an observer in a form other tools can read, as a MATLAB table or struct, as a CSV file, or as a MAT file. `writetable` also writes `.xlsx` files if given that extension, and works the same way.
%[text] The main method is `obs.evaluate(wl, Data=...)`, which always returns a table. The first column is `Wavelength_nm` and the rest hold one channel each. The `Data` argument chooses the quantity. For a plain numeric array, call the named method such as `obs.LMS(wl)` instead.
%[text] **Time:** about 10 minutes.
exampleDefaults();
%%
%[text] ## The evaluate method
%[text] The call takes the form `[result, wl] = obs.evaluate(wl, Data=...)`. Each value of `Data` calls the method of the same name, so the table and the direct call always give the same numbers.
%[text:table]
%[text] | `Data` | Columns | Equivalent method |
%[text] | --- | --- | --- |
%[text] | `"LMS"`, the default | `L`, `M`, `S` | `obs.LMS(wl)` |
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
%[text] ## A table with named columns
%[text] Each cone has its own column and the wavelengths come first. This is the form to pass to `writetable`, `stackedplot` or `groupsummary`.
data_table = obs.evaluate(wl, Data='LMS');
head(data_table, 5)
%%
%[text] ## A numeric array
%[text] For further computation, call the named method. It returns the array directly, with no table to unpack.
data_array = obs.LMS(wl);
size(data_array)
data_array(1:5, :)
%%
%[text] ## A struct
%[text] `table2struct` with `ToScalar=true` gives one field per column, which suits storage in a MAT file.
data_struct = table2struct(data_table, ToScalar=true);
fieldnames(data_struct)
%%
%[text] ## Other quantities
%[text] `evaluate` covers more than the cone fundamentals. The RGB and XYZ colour matching functions, luminance, and all three chromaticity conventions come from the same call.
L_only = obs.evaluate(wl, Data='L');
RGB    = obs.evaluate(wl, Data='RGB');
chrom  = obs.evaluate(wl, Data='lmChromaticity');
table(width(L_only) - 1, width(RGB) - 1, width(chrom) - 1, ...
      'VariableNames', {'L_cols', 'RGB_cols', 'lmChromaticity_cols'})
%%
%[text] ## Writing a CSV file
%[text] `writetable` accepts the output of `evaluate` unchanged, and the column names become the header row.
csv_path = fullfile(tempdir, 'cone_fundamentals.csv');
writetable(data_table, csv_path);
csv_lines = readlines(csv_path);
disp(csv_lines(1:min(6, end)))
%%
%[text] ## Writing a MAT file with its metadata
%[text] For work that stays in MATLAB, a MAT file keeps full precision and can hold nested structures, so the data and a record of how it was produced can be stored together.
%[text] Store the result of `getParameters` rather than copying the observer's properties into a struct by hand. `getParameters` returns an `ObserverParameters` object that already holds every biophysical field, survives `save` and `load`, and restores the observer exactly. A list written out by hand omits whatever was forgotten, and for a non-standard observer the omissions are usually the interesting part, since lambda-max shifts, cone optical densities and opsin templates are all easy to leave out.
%[text] What `getParameters` does not carry is the output settings, and those determine what the numbers mean. `NormalizeOutput` and `NormalizationMethod` decide whether the values are peak-normalized, `LogOutput` decides whether they are logarithms, and `Primaries` is needed to interpret the RGB columns at all, since the RGB functions are defined relative to them. Record these alongside.
%[text] Recording the toolbox version is worth doing as well, which `ver` provides for an installed toolbox. Normalization behaviour is still changing in this beta series, and a file without a version is hard to interpret later.
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
%[text] ## Exporting several observers together
%[text] The example below builds one observer per age, takes the L cone from each, and writes them to a single CSV file with the age in each column name. A recipient can then tell which column belongs to which observer without a separate metadata file.
ages = [25, 50, 75];
%[text] The `VanDeKraats2007` model was fitted over 300 to 700 nm, so evaluating it beyond 700 nm raises `IndividualCMF:WavelengthOutOfRange` once for each observer. The extrapolation is a smooth decay of bounded size and the values are kept. The warning is switched off below because the range of the model is not the subject here. See [Example 05](matlab:edit('Example05_AgingEffects.m')).
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
%[text] ## Saving the observer rather than its data
%[text] To store the configuration of an observer rather than the numbers it produces, use `getParameters` to obtain an `ObserverParameters` object, save that, and restore it later with `setParameters`. [Example 15](matlab:edit('Example15_AdvancedCustomization.m')) works through it in full.
%%
%[text] ## The two routes agree
%[text] `evaluate` calls the named methods rather than repeating their work, so the two give identical results. Use whichever suits the surrounding code.
LMS_direct = obs.LMS(wl);
LMS_via_evaluate = table2array(data_table(:, 2:end));
isequal(LMS_direct, LMS_via_evaluate)
%%
%[text] ## Key takeaways
%[text] - `evaluate(wl, Data=...)` returns a table with one column per channel
%[text] - Call the named method for an array, or `table2struct(t, ToScalar=true)` for a struct
%[text] - `writetable` writes CSV and Excel files, and `save` writes MAT files
%[text] - A CSV file carries the numbers alone. Record the observer's parameters in a MAT file alongside, including `NormalizeOutput`, `NormalizationMethod` and `Primaries`, or put the varying parameter in the column names as the multi-observer export does
%[text] - `getParameters` and `setParameters` transfer the observer itself. They do not transfer the output settings, which have to be recorded separately \
%[text] **Next:** [Example 17: Normalization Methods](matlab:edit('Example17_NormalizationMethods.m')). The two ways of locating the peak, and reproducing another implementation exactly.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

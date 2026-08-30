%[text] # Example 16: Advanced Customization
%[text] This example covers every parameter the constructor accepts, the rules that decide when an assigned value is kept, and how to save an observer and restore it later.
%[text] **Time:** about 15 minutes.
exampleDefaults();
%%
%[text] ## The constructor arguments
%[text:table]
%[text] | Group | Arguments |
%[text] | --- | --- |
%[text] | Standard configuration | `StandardObserver`, either 2 or 10. It rejects any biophysical argument given alongside it. Output settings such as `OutputFormat` are still allowed |
%[text] | Physiological | `Age`, `FieldSize`, `LensDensity`, `MacularDensity`, `Lod`, `Mod`, `Sod` |
%[text] | Templates and genetics | `PhotopigmentModel`, `LensModel`, `MacularModel`, `L_OpsinTemplate`, `M_OpsinTemplate`, `L_LambdaMaxShift`, `M_LambdaMaxShift`, `S_LambdaMaxShift`, `Genotype` |
%[text] | Density algorithms | `MacularDensityAlgorithm`, `PhotopigmentDensityAlgorithm`, `LensDensityAlgorithm` |
%[text] | Output settings | `OutputFormat`, `NormalizeOutput`, `LogOutput`, `Primaries`, `NormalizationMethod`, `NormalizationGrid` |
%[text:table]
%%
%[text] ## Building an observer
%[text] Parameters can be combined freely in one call, within the limits the table above records. `StandardObserver` cannot be combined with a biophysical argument, `Genotype` cannot be combined with an explicit template or lambda-max shift, and an algorithm cannot be set to `"Custom"` directly, since `Custom` is a state that follows from assigning a density. The observer below reports `Type = "Individualized"`, since it matches neither CIE standard observer.
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
%[text] ## Assigning a density directly
%[text] Assigning `LensDensity`, `MacularDensity`, `Lod`, `Mod` or `Sod` selects `"Custom"` for the matching algorithm property. The assigned value is then kept when the parameter that would otherwise determine it changes. That parameter is `FieldSize` for the macular and cone densities, and `Age`, `FieldSize` or `LensModel` for the lens density.
%[text] This example is the one place the rules are stated in full. Earlier examples note only the fact that an assignment is normally kept.
%[text] When Custom mode is selected differs between the components. For the cone and macular densities the toolbox compares the assigned value against the CIE table, and it has a table to compare against only at 2 and 10 deg. Assigning `Sod = 0.30` to a 10 deg observer therefore leaves the algorithm at `CIE170`, since that is the tabulated value, while the same assignment at 6 deg selects `Custom`. The lens density is compared against nothing, so assigning it always selects `Custom`, even at the standard value of 1.7649.
%[text] Three further rules complete the picture. Custom mode applies to a group rather than a single property, so assigning one cone density holds all three. Assigning `[]` returns a density to its model. And `"Custom"` cannot be requested directly, since it is a state that follows from an assignment rather than a setting.
%[text] An assigned density replaces the value the formula would have produced. It is not added to it. This differs from the model of Asano, Fairchild and Blonde (2016), in which an age term and a separate deviation term are combined.
obs_override = IndividualCMF();
obs_override.LensDensity    = 2.5;
obs_override.MacularDensity = 0.6;
obs_override.Lod = 0.35; obs_override.Mod = 0.35; obs_override.Sod = 0.25;
table(obs_override.LensDensity,    string(obs_override.LensDensityAlgorithm), ...
      obs_override.MacularDensity, string(obs_override.MacularDensityAlgorithm), ...
      obs_override.Lod,            string(obs_override.PhotopigmentDensityAlgorithm), ...
      'VariableNames', {'LensDensity', 'LensAlg', 'MacularDensity', 'MacAlg', 'Lod', 'PhotoAlg'})
%%
%[text] ## Assigning one density affects all three
%[text] Custom mode applies to a group of properties rather than to a single one. The three cone densities form such a group, because one formula produces all three. Assigning any one of them holds the other two at the values they had at that moment.
%[text] In the example below only `Lod` is assigned. `Mod` then keeps its 10 deg value through a change of field size to 2 deg, instead of taking the 2 deg value that a normal observer at that field size would have.
obs_group = IndividualCMF(FieldSize=10);
mod_before = obs_group.Mod;
obs_group.Lod = 0.35;
obs_group.FieldSize = 2;
table(mod_before, obs_group.Mod, IndividualCMF(FieldSize=2).Mod, ...
      'VariableNames', {'Mod_at_10deg', 'Mod_after_FieldSize2', 'Mod_a_normal_2deg_has'})
%[text] Assigning `[]` to any one of the three returns the whole group to the formula, for the same reason.
%%
%[text] ## An assigned value survives a change of age
%[text] Setting `Age=80` would ordinarily recompute `LensDensity` from the lens model. Custom mode was selected in the previous section, so the assigned value is kept.
obs_override.Age = 80;
table(obs_override.Age, obs_override.LensDensity, string(obs_override.LensDensityAlgorithm), ...
      'VariableNames', {'Age', 'LensDensity', 'Algorithm'})
%%
%[text] ## Returning to the model
%[text] Assigning `[]` clears Custom mode and recomputes `LensDensity` from `Age` and the lens model. Discarding the assigned value is the purpose of the call, so no warning is issued.
%[text] Setting `LensDensityAlgorithm="Auto"` has the same effect but does warn, with `IndividualCMF:LensCustomOverwritten`. There the loss of the assigned value is a consequence of the request rather than the request itself.
%[text] Note that the default `LensModel="StockmanRider2023"` does not depend on age, so the recomputed value below is the standard 1.7649 even though `Age` is 80. Use `LensModel="VanDeKraats2007"` for a value that depends on age.
obs_override.LensDensity = [];
table(obs_override.Age, obs_override.LensDensity, string(obs_override.LensDensityAlgorithm), ...
      'VariableNames', {'Age', 'LensDensity_after_revert', 'Algorithm'})
%%
%[text] ## Observers at the edge of the plausible range
%[text] The three sections that follow each vary one parameter well beyond its usual value, to show what that parameter does. The first uses an extreme lens density, the second an L cone whose peak has moved a long way towards short wavelengths, and the third shows all three cones for that second observer.
wl = (390:1:700)';
obs_low_lens  = IndividualCMF(LensModel="VanDeKraats2007", Age=20, FieldSize=10, LensDensity=1.2);
obs_high_lens = IndividualCMF(LensModel="VanDeKraats2007", Age=80, FieldSize=10, LensDensity=3.5);
obs_normal    = IndividualCMF();
obs_anomalous = IndividualCMF(L_OpsinTemplate="Serine", L_LambdaMaxShift=-15);
%%
%[text] ### Two extreme lens densities
%[text] The two lens densities below are near the limits of the plausible human range.
%[text] Both curves are peak-normalized, so the real effect of the denser lens, which is to absorb much more short-wavelength light, appears as a change of shape rather than a loss of sensitivity. The peak of the normalized S curve is near 455 nm instead of 440 nm, and at 480 nm the denser lens gives 0.59 against 0.32. The difference in overall sensitivity has been divided out.
tiledlayout(1, 1); nexttile
plot(wl, obs_low_lens.S(wl),  'b-'); hold on
plot(wl, obs_high_lens.S(wl), 'b--'); hold off
xlabel('Wavelength (nm)'); ylabel('S-Cone Sensitivity')
title('S cone at two extreme lens densities'); legend('LensDensity = 1.2', 'LensDensity = 3.5', 'Location', 'bestoutside')
grid on; xlim([390 520])
%%
%[text] ### An L cone shifted by -15 nm
%[text] A shift of this size is associated with strong anomalous trichromacy. [Example 15](matlab:edit('Example15_Dichromacy.m')) compares that condition with dichromacy.
tiledlayout(1, 1); nexttile
plot(wl, obs_normal.L(wl),    'r-'); hold on
plot(wl, obs_anomalous.L(wl), 'r--'); hold off
xlabel('Wavelength (nm)'); ylabel('L-Cone Sensitivity')
title('L cone shifted by -15 nm'); legend('Normal', '-15 nm shift', 'Location', 'bestoutside')
grid on; xlim([480 650])
%%
%[text] ### All three cones for the same pair
%[text] `compareTo` draws the reference observer with solid lines and the comparison observer with dashed lines. The shifted L cone lies closer to M than it normally would.
obs_normal.compareTo(obs_anomalous, Title="Normal (solid) and anomalous (dashed)", Wavelength=wl);
xlim([390 700])
%%
%[text] ## Genotype and primaries
%[text] The `Genotype` argument, `setGenotype` and `applyGenotype` are covered in [Example 09](matlab:edit('Example09_GeneticVariants.m')). Choosing `Primaries` is covered in [Example 11](matlab:edit('Example11_RGBColorMatching.m')).
%%
%[text] ## Many parameters in one call
%[text] The property listing that MATLAB prints for the result records the whole parameter set, including the parameters not named in the call and the values derived from those that were.
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
%[text] ## Validation
%[text] The constructor checks its arguments and reports what was wrong. The three calls below are each wrapped in `try` and `catch` so that the messages can be collected into a table.
errors = strings(0);
try, IndividualCMF(Age=-5); catch ME, errors(end+1) = ME.message; end
try, IndividualCMF(L_LambdaMaxShift=20); catch ME, errors(end+1) = ME.message; end
try, IndividualCMF(L_OpsinTemplate="Invalid"); catch ME, errors(end+1) = ME.message; end
table(["Age=-5"; "L_LambdaMaxShift=20"; "L_OpsinTemplate=""Invalid"""], errors', ...
      'VariableNames', {'Bad_input', 'Validation_error'})
%%
%[text] ## Copying an observer
%[text] `IndividualCMF` is a handle class, which means a variable holds a reference to an observer rather than the observer itself. Assigning one variable to another therefore gives a second name for one observer, not a second observer.
%[text] This is worth meeting deliberately, because nothing warns about it. Modifying what looks like a copy modifies the original as well, and the results simply come out wrong.
%[text] `copy` returns an independent duplicate. It is inherited from `matlab.mixin.Copyable`, so it carries no help text of its own, but this class overrides the copying so that the duplicate gets its own normalization cache and its own template objects.
original = IndividualCMF();
alias = original;
duplicate = copy(original);
original.Age = 70;
table([original.Age; alias.Age; duplicate.Age], ...
      ["the observer that was changed"; "a second name for it"; "an independent copy"], ...
      'VariableNames', {'Age', 'What_it_is'}, ...
      'RowNames', {'original', 'alias = original', 'duplicate = copy(original)'})
%[text] The alias followed the change and the copy did not. Use `copy` whenever an observer is about to be modified and the original is still needed, and in particular before handing an observer to a function that may change it.
%%
%[text] ## Saving an observer and restoring it
%[text] There are two ways to keep an observer. Saving the object itself with `save` preserves everything. Calling `getParameters` returns an `ObserverParameters` value that can be applied to another observer with `setParameters`.
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
%[text] What `getParameters` does not carry is the output settings. `ObserverParameters` describes the observer rather than the way that observer's numbers are reported.
%[text] The consequence is shown below. If the source observer has a non-default `OutputFormat`, the restored observer returns a different array, because it reports the same observer in different units.
obs_shaped = IndividualCMF(Age=55, OutputFormat="quantal", NormalizeOutput=false);
obs_reshaped = IndividualCMF();
obs_reshaped.setParameters(obs_shaped.getParameters());
table(string(obs_shaped.OutputFormat), string(obs_reshaped.OutputFormat), ...
      obs_shaped.Age == obs_reshaped.Age, ...
      isequal(obs_shaped.LMS(wl_check), obs_reshaped.LMS(wl_check)), ...
      'VariableNames', {'Source_Format', 'Restored_Format', 'Age_Matches', 'LMS_Identical'})
%[text] The age transfers and the format does not, so the two arrays differ. Set the output settings on the receiving observer as well when they need to match. `NormalizationMethod` and `NormalizationGrid` behave the same way. See [Example 06](matlab:edit('Example06_NormalizationMethods.m')).
%%
%[text] ## Key takeaways
%[text] - `IndividualCMF` is a handle class. Assigning one variable to another gives a second name for the same observer, so use `copy` for an independent duplicate
%[text] - Saving the object with `save` preserves everything about an observer
%[text] - `getParameters` and `setParameters` transfer the observer itself, including the physiological values, the models, the opsin templates and all three algorithm modes. They do not transfer the output settings
%[text] - Assigning a density selects `"Custom"` for its algorithm, which keeps the assigned value when the parameters behind it change. Assigning the value the CIE table already specifies is the exception and leaves the algorithm alone
%[text] - Custom mode applies to a group. Assigning one cone density holds all three
%[text] - Assigning `[]` returns a density to the model and issues no warning. For lens density only, setting `LensDensityAlgorithm="Auto"` does the same and warns. The macular and photopigment algorithms have no `"Auto"` value, so `[]` is the only route back for those
%[text] - The three density algorithm properties are `LensDensityAlgorithm`, `MacularDensityAlgorithm` and `PhotopigmentDensityAlgorithm`
%[text] - `setGenotype`, `applyGenotype` and the `Genotype` argument are three ways to set a genotype, differing in how much they set at once \
%[text] **Next:** [Example 17: Data Export](matlab:edit('Example17_DataExport.m')). Exporting cone fundamentals as tables, CSV and MAT files.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

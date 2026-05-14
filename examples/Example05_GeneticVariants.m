%[text] # Example 05: Genetic Variants and Cone Polymorphisms
%[text] L- and M-opsin polymorphisms shift cone lambda-max. The dominant axis is the **Ser180Ala** substitution at codon 180 of the L-opsin: ~56% Serine, ~44% Alanine, ~**2.7 nm** peak shift. This example covers per-codon `Genotype=` configuration, the `applyGenotype` 5-letter notation, and the named M-in-L / L-in-M hybrid templates.
%[text] **Time:** about 12 minutes.
exampleDefaults();
%%
%[text] ## L-cone template variants
%[text] The toolbox provides four L-cone template options accessed via `L_OpsinTemplate`:
%[text] - `"Mean"` *(default)* -- population-weighted average (56% Ser + 44% Ala)
%[text] - `"Serine"` -- pure Serine variant
%[text] - `"Alanine"` -- pure Alanine variant
%[text] - `"MinL"` -- hybrid (M-cone amino acids in an L-cone gene) \
%[text] M-cone analogues live under `M_OpsinTemplate`: `"Mean"` / `"Standard"` / `"LinM"`.
obs_mean = IndividualCMF(L_OpsinTemplate="Mean");
obs_ser  = IndividualCMF(L_OpsinTemplate="Serine");
obs_ala  = IndividualCMF(L_OpsinTemplate="Alanine");
table([string(obs_mean.L_OpsinTemplate); string(obs_ser.L_OpsinTemplate); string(obs_ala.L_OpsinTemplate)], ...
      'VariableNames', {'L_OpsinTemplate'}, 'RowNames', {'mean', 'serine', 'alanine'})
%%
%[text] ## Visualizing the Ser/Ala shift
%[text] The Serine and Alanine curves are nearly indistinguishable when overlaid -- the shift is real but small. The classic way to expose it is the **difference curve** $L_{\\mathrm{Ser}}(\\lambda) - L_{\\mathrm{Ala}}(\\lambda)$: a small spectral shift between two near-identical curves produces a characteristic S-shaped (zero-crossing) residual, with the zero crossing near the peak wavelength.
wl = (520:0.5:640)';
plot(wl, obs_ser.L(wl) - obs_ala.L(wl), 'r-')
yline(0, 'k--', 'HandleVisibility', 'off')
xlabel('Wavelength (nm)'); ylabel('L_{Ser} - L_{Ala}')
title('Ser180Ala shift signature (Serine minus Alanine)')
%%
%[text] ## `setGenotype` -- amino-acid-level control
%[text] `setGenotype(cone, position, amino_acid)` configures one polymorphic site at a time. The toolbox converts the genotype to the corresponding `L_LambdaMaxShift` and template choice using the Stockman & Rider (2023) coefficients.
obs_geno = IndividualCMF();
shift_before = obs_geno.L_LambdaMaxShift;
obs_geno.setGenotype('L', 180, 'Ala');
shift_after = obs_geno.L_LambdaMaxShift;
table(shift_before, shift_after, ...
      'VariableNames', {'BeforeShift_nm', 'AfterShift_nm'})
%%
%[text] ## `Genotype` in the constructor
%[text] You can pass the genotype directly to the constructor in either of two forms:
%[text] - **struct** -- one site per field, e.g. `struct('L_180', 'Ala')`. Only the listed sites change; unmentioned sites contribute zero shift.
%[text] - **string** -- Stockman & Rider 5-letter notation, `"L-genotype/M-genotype"` at codons 116/180/230/277/285 (e.g. `"LSAYT/SAAFA"`). Every codon contributes its dictionary entry, so 5-letter strings encode the genotype's full set of shifts -- they are *not* zero-shift unless every position deliberately avoids a dictionary entry. \
%[text] **There is no "standard normal trichromat genotype":** both Serine and Alanine alleles at codon 180 are common in the population (~56% / ~44%), and several other positions also segregate. The "Mean" templates are population-weighted averages, not the genotype of a typical individual. \
%[text] **Conflict handling:** combining `Genotype=` with explicit `L_/M_/S_LambdaMaxShift` or non-default `L_/M_OpsinTemplate` raises an `IndividualCMF:Conflict` error -- the genotype determines those values.
obs_struct = IndividualCMF(Genotype=struct('L_180', 'Ala'));
obs_string = IndividualCMF(Genotype="LSAYT/SAAFA");
table(obs_struct.L_LambdaMaxShift, obs_string.L_LambdaMaxShift, ...
      'VariableNames', {'StructForm_LShift_nm', 'StringForm_LShift_nm'})
%[text] The conflict error in practice:
try
    IndividualCMF(Genotype="LSAYT/SAAFA", L_LambdaMaxShift=2);
catch ME
    disp(ME.identifier)
    disp(ME.message)
end
%%
%[text] ## `applyGenotype` -- automatic template selection
%[text] `applyGenotype` parses a 5-letter genotype string and automatically picks the right opsin template (Mean / Serine / Alanine / M-in-L / L-in-M) and the right `L_LambdaMaxShift` / `M_LambdaMaxShift`. The two `Genotype.isLHybrid` / `Genotype.isMHybrid` predicates do the hybrid detection internally. The first row below uses `"LSAYT/SAAFA"` -- pycone's default "normal trichromat" baseline (Leu/Ser/Ala/Tyr/Thr for L; Ser/Ala/Ala/Phe/Ala for M), giving zero shift for both cones.
obs_nonhybrid = IndividualCMF(); obs_nonhybrid.applyGenotype("LSAYT/SAAFA");
obs_minl      = IndividualCMF(); obs_minl.applyGenotype("LIAFA/SAAFA");
obs_linm      = IndividualCMF(); obs_linm.applyGenotype("LSAYT/SIAYT");
table(string({obs_nonhybrid.L_OpsinTemplate; obs_minl.L_OpsinTemplate; obs_linm.L_OpsinTemplate}), ...
      string({obs_nonhybrid.M_OpsinTemplate; obs_minl.M_OpsinTemplate; obs_linm.M_OpsinTemplate}), ...
      [obs_nonhybrid.L_LambdaMaxShift; obs_minl.L_LambdaMaxShift; obs_linm.L_LambdaMaxShift], ...
      [obs_nonhybrid.M_LambdaMaxShift; obs_minl.M_LambdaMaxShift; obs_linm.M_LambdaMaxShift], ...
      'VariableNames', {'L_tmpl', 'M_tmpl', 'L_dnm', 'M_dnm'}, ...
      'RowNames', {'Pycone-default normal trichromat', 'M-in-L hybrid', 'L-in-M hybrid'})
%%
%[text] ## Advanced: hybrid cones
%[text] Gene recombination events can create hybrid cones. Beyond the per-codon `Genotype=` syntax and `applyGenotype` shown above, two named hybrid templates exist:
%[text] - **M-in-L** -- M-cone amino acids in the L-cone position 277/285. Use `L_OpsinTemplate="MinL"`.
%[text] - **L-in-M** -- L-cone amino acids in the M-cone position 277/285. Use `M_OpsinTemplate="LinM"`. \
%[text] These shapes are visibly different from the standard L/M templates around the peak region.
obs_hybridL = IndividualCMF(L_OpsinTemplate="MinL");
obs_hybridM = IndividualCMF(M_OpsinTemplate="LinM");
wl = (480:0.5:620)';
tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile
plot(wl, obs_ser.L(wl), 'r-'); hold on
plot(wl, obs_ser.M(wl), 'g-')
plot(wl, obs_hybridL.L(wl), 'm--', 'LineWidth', 2.5); hold off
xlabel('Wavelength (nm)'); ylabel('Sensitivity')
title('M-in-L hybrid L-cone')
legend('Normal L (Serine)', 'Normal M', 'Hybrid L (M-in-L)', 'Location', 'bestoutside')
nexttile
plot(wl, obs_ser.L(wl), 'r-'); hold on
plot(wl, obs_ser.M(wl), 'g-')
plot(wl, obs_hybridM.M(wl), 'c--', 'LineWidth', 2.5); hold off
xlabel('Wavelength (nm)'); ylabel('Sensitivity')
title('L-in-M hybrid M-cone')
legend('Normal L (Serine)', 'Normal M', 'Hybrid M (L-in-M)', 'Location', 'bestoutside')
%%
%[text] ## Key takeaways
%[text] - **Metameric matching** -- colors that match for one observer may not match for another with a different Ser180Ala genotype
%[text] - **Color discrimination** -- the ~2.7 nm Ser/Ala shift slightly changes L-vs-M wavelength separation; whether that translates to a measurable discrimination advantage depends on the task and is the subject of ongoing research
%[text] - **Personal calibration** -- knowing the observer's genotype improves precision colorimetry
%[text] - **Population studies** -- use `"Mean"` for general population averages; specific variants for individual modeling
%[text] - Ser180Ala polymorphism shifts the L-cone peak by about 2.7 nm
%[text] - L-cone templates: `"Mean"` *(default)*, `"Serine"`, `"Alanine"`, `"MinL"`
%[text] - M-cone templates: `"Mean"`/`"Standard"`, `"LinM"`
%[text] - `setGenotype(cone, pos, aa)` for amino-acid control; `Genotype=struct(...)` or `Genotype="LSAYT/SAAFA"` in the constructor
%[text] - `applyGenotype` automatically picks the right templates from a 5-letter genotype string
%[text] - `L_LambdaMaxShift` allows custom peak adjustments (range -40 to +10 nm) \
%[text] **Next:** [Example 06: Template Model Comparison](matlab:edit('Example06_PhotopigmentModels.m')) -- comparing the Stockman & Rider (2023) and Govardovskii (2000) photopigment template models.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

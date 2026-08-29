%[text] # Example 06: Genetic Variants and Cone Polymorphisms
%[text] L- and M-opsin polymorphisms shift cone lambda-max. The dominant axis is the **Ser180Ala** substitution at codon 180 of the L-opsin: ~56% Serine, ~44% Alanine, with Alanine peaking ~**2.7 nm shorter** than Serine. That figure is the photopigment lambda-max shift; the cone fundamental's peak moves slightly differently once pre-receptoral filtering is applied. This example covers per-codon `Genotype=` configuration, the `applyGenotype` 5-letter notation, and the named M-in-L / L-in-M hybrid templates.
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
%[text] The pigment templates differ by a translation along wavelength. Measuring each template's own absorbance peak shows the 2.7 nm Serine-to-Alanine step directly, with Mean sitting between them at the 56/44 population weighting.
wl_peak = (520:0.01:600)';
tpl = StockmanRiderPhotopigmentTemplate();
peakOf = @(variant) wl_peak(find(tpl.computeAbsorbance(wl_peak, 'L', 0, ...
    struct('L_Template', variant, 'M_Template', "Standard")) == ...
    max(tpl.computeAbsorbance(wl_peak, 'L', 0, ...
    struct('L_Template', variant, 'M_Template', "Standard"))), 1));
lambdaMax = [peakOf("Serine"); peakOf("Mean"); peakOf("Alanine")];
table(lambdaMax, lambdaMax - lambdaMax(1), ...
      'VariableNames', {'PigmentLambdaMax_nm', 'ShiftFromSerine_nm'}, ...
      'RowNames', {'Serine', 'Mean', 'Alanine'})
%%
%[text] ## Visualizing the Ser/Ala shift
%[text] The Serine and Alanine curves are nearly indistinguishable when overlaid -- the shift is real but small. The classic way to expose it is the **difference curve** $L_{\\mathrm{Ser}}(\\lambda) - L_{\\mathrm{Ala}}(\\lambda)$: a small spectral shift between two near-identical curves produces a characteristic S-shaped (zero-crossing) residual, with the zero crossing near the peak wavelength.
wl = (520:0.5:640)';
plot(wl, obs_ser.L(wl) - obs_ala.L(wl), 'r-')
yline(0, '--', 'Color', IndividualCMF.neutralColor(), 'HandleVisibility', 'off')
xlabel('Wavelength (nm)'); ylabel('L_{Ser} - L_{Ala}')
title('Ser180Ala shift signature (Serine minus Alanine)')
%%
%[text] ## `setGenotype` -- amino-acid-level control
%[text] `setGenotype(cone, position, amino_acid)` configures one polymorphic site at a time, converting the genotype to an `L_LambdaMaxShift` and a template choice.
%[text] The shift printed below is -3.05 nm, not the ~2.7 nm quoted at the top of this example. Both are correct and both match pycone: the genotype path scales the Stockman & Rider Table 3 coefficient for Ala at codon 180 (-4.0) by a pycone convention of 23.67/31, giving -3.05, while the **Alanine template** is defined as the Serine template offset by exactly -2.70 nm. The template route and the codon route are two different mechanisms that both model the same substitution.
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
%[text] - **string** -- Stockman & Rider 5-letter notation, `"L-genotype/M-genotype"` at codons 116/180/230/277/285 (e.g. `"LSAYT/SAAFA"`). Every codon contributes its dictionary entry, and the baseline residues carry explicit zero coefficients -- so pycone's default string `"LSAYT/SAAFA"` totals exactly zero shift, while variant residues such as Ala at L180 contribute their Table 3 values. \
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
%[text] `applyGenotype` parses a 5-letter genotype string, picks an opsin template, and sets the matching `L_LambdaMaxShift` / `M_LambdaMaxShift`. It selects the way pycone does: a normal L genotype gets **Serine** and an F+A hybrid at codons 277/285 gets **M-in-L**; a normal M gets **Standard** and a Y+T hybrid gets **L-in-M**. Mean and Alanine are never chosen this way -- a population mean is not any individual's genotype, and Alanine is reached through the codon-180 shift rather than by template swap. Note the consequence: `applyGenotype("LSAYT/SAAFA")` is not a no-op even though its shifts are zero, because it moves the L cone off the CIE-parity Mean template onto Serine. The two `Genotype.isLHybrid` / `Genotype.isMHybrid` predicates do the hybrid detection internally. The first row below uses `"LSAYT/SAAFA"` -- pycone's default "normal trichromat" baseline (Leu/Ser/Ala/Tyr/Thr for L; Ser/Ala/Ala/Phe/Ala for M), giving zero shift for both cones.
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
%[text] Unequal recombination between the adjacent L and M genes on the X chromosome can create hybrid *genes*, and so hybrid pigments. Beyond the per-codon `Genotype=` syntax and `applyGenotype` shown above, two named hybrid templates exist:
%[text] - **M-in-L** -- M-cone amino acids at L-cone positions 277 and 285. Use `L_OpsinTemplate="MinL"`.
%[text] - **L-in-M** -- L-cone amino acids at M-cone positions 277 and 285. Use `M_OpsinTemplate="LinM"`. \
%[text] Selecting a hybrid template on its own changes the *shape*, not the position: `MinL` is the M-cone shape anchored at 553.47 nm, only 0.36 nm from the Serine L pigment. The two pigments therefore sit on top of each other, but the plotted fundamentals do not -- a different shape filtered and renormalized lands its peak 4.25 nm short of L's (563.75 against 568.00), and the curves part on the long-wavelength side, reaching a gap of 0.150 near 617 nm.
%[text] A real M-in-L hybrid also carries the genotype's lambda-max shift, the -16.035 nm shown in the previous section, which is what moves it spectrally between M and L rather than merely reshaping it.
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
%[text] - Ser180Ala shifts the L photopigment lambda-max by 2.7 nm, Alanine shorter than Serine; the Mean default sits between them
%[text] - L-cone templates: `"Mean"` *(default)*, `"Serine"`, `"Alanine"`, `"MinL"`
%[text] - M-cone templates: `"Mean"`/`"Standard"`, `"LinM"`
%[text] - `setGenotype(cone, pos, aa)` for amino-acid control; `Genotype=struct(...)` or `Genotype="LSAYT/SAAFA"` in the constructor
%[text] - `applyGenotype` automatically picks the right templates from a 5-letter genotype string
%[text] - `L_LambdaMaxShift` allows custom peak adjustments (range -40 to +10 nm) \
%[text] **Next:** [Example 07: Photopigment Template Models](matlab:edit('Example07_PhotopigmentModels.m')) -- comparing the Stockman & Rider (2023) and Govardovskii (2000) photopigment template models.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

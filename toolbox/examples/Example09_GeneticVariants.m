%[text] # Example 09: Genetic Variants and Cone Polymorphisms
%[text] Differences in the L- and M-opsin genes shift the lambda-max of the photopigment they produce. The most common of these is the **Ser180Ala** substitution at codon 180 of the L-opsin gene. About 56% of the population carries serine at that position and about 44% carries alanine, and the alanine pigment peaks about 2.7 nm shorter than the serine pigment.
%[text] That 2.7 nm figure is the shift in the photopigment lambda-max. The peak of the cone fundamental moves by a different amount, because the lens and the macular pigment filter the light before it reaches the cone.
%[text] This example covers three ways of specifying a genotype, and the named hybrid templates.
%[text] **Time:** about 12 minutes.
exampleDefaults();
%%
%[text] ## L-cone template variants
%[text] The `L_OpsinTemplate` property selects one of four L-cone templates:
%[text] - `"Mean"`, the default. A population-weighted average of 56% serine and 44% alanine.
%[text] - `"Serine"`, the pure serine variant.
%[text] - `"Alanine"`, the pure alanine variant.
%[text] - `"MinL"`, a hybrid carrying M-cone amino acids in an L-cone gene. \
%[text] The M cone has the equivalent property `M_OpsinTemplate`, with the options `"Mean"`, `"Standard"` and `"LinM"`.
obs_mean = IndividualCMF(L_OpsinTemplate="Mean");
obs_ser  = IndividualCMF(L_OpsinTemplate="Serine");
obs_ala  = IndividualCMF(L_OpsinTemplate="Alanine");
%[text] The templates differ by a translation along the wavelength axis. Measuring the absorbance peak of each one shows the 2.7 nm step from serine to alanine directly, with the mean template between them at the 56 to 44 weighting.
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
%[text] ## Seeing the Ser180Ala shift
%[text] Plotted on top of one another the serine and alanine curves are almost identical, because the shift between them is small. Subtracting one from the other makes it visible.
%[text] A small shift along the wavelength axis between two otherwise identical curves produces a difference curve with one positive part, one negative part and a zero crossing near the peak wavelength. That is the shape shown below.
wl = (520:0.5:640)';
tiledlayout(1, 1); nexttile
plot(wl, obs_ser.L(wl) - obs_ala.L(wl), 'r-')
yline(0, '--', 'Color', IndividualCMF.neutralColor(), 'HandleVisibility', 'off')
xlabel('Wavelength (nm)'); ylabel('L_{Ser} - L_{Ala}')
title('Serine minus Alanine')
%%
%[text] ## Setting one amino acid at a time
%[text] `setGenotype(cone, position, amino_acid)` sets a single polymorphic site. The toolbox converts the genotype into a lambda-max shift and a template choice.
%[text] The shift printed below is -3.05 nm rather than the 2.7 nm quoted at the start of this example. Both figures are correct, and both match pycone. They come from two different routes to the same substitution. The genotype route takes the Stockman and Rider Table 3 coefficient for alanine at codon 180, which is -4.0, and scales it by the pycone convention of 23.67/31, giving -3.05. The template route defines the alanine template as the serine template moved by exactly -2.70 nm.
obs_geno = IndividualCMF();
shift_before = obs_geno.L_LambdaMaxShift;
obs_geno.setGenotype('L', 180, 'Ala');
shift_after = obs_geno.L_LambdaMaxShift;
table(shift_before, shift_after, ...
      'VariableNames', {'BeforeShift_nm', 'AfterShift_nm'})
%%
%[text] ## Passing a genotype to the constructor
%[text] The constructor accepts a genotype in either of two forms:
%[text] - A **struct**, with one field per site, such as `struct('L_180', 'Ala')`. Only the listed sites change, and any site not mentioned contributes no shift.
%[text] - A **string** in the Stockman and Rider five-letter notation, written as the L genotype and the M genotype separated by a slash, covering codons 116, 180, 230, 277 and 285. An example is `"LSAYT/SAAFA"`. Every codon contributes its tabulated coefficient, and the baseline residues carry explicit coefficients of zero, so the pycone default string `"LSAYT/SAAFA"` gives a total shift of exactly zero. \
%[text] There is no single genotype that counts as the normal trichromat. Both alleles at codon 180 are common, and several other positions vary as well. The `"Mean"` templates are population-weighted averages rather than the genotype of any individual.
%[text] Combining `Genotype` with an explicit `L_LambdaMaxShift`, `M_LambdaMaxShift`, `S_LambdaMaxShift` or a non-default opsin template raises `IndividualCMF:Conflict`, since the genotype already determines those values.
obs_struct = IndividualCMF(Genotype=struct('L_180', 'Ala'));
obs_string = IndividualCMF(Genotype="LSAYT/SAAFA");
table(obs_struct.L_LambdaMaxShift, obs_string.L_LambdaMaxShift, ...
      'VariableNames', {'StructForm_LShift_nm', 'StringForm_LShift_nm'})
%[text] The conflict error looks like this.
try
    IndividualCMF(Genotype="LSAYT/SAAFA", L_LambdaMaxShift=2);
catch ME
    disp(ME.identifier)
    disp(ME.message)
end
%%
%[text] ## Letting the genotype choose the template
%[text] `applyGenotype` reads a five-letter genotype string, chooses an opsin template, and sets the matching lambda-max shifts. It chooses as pycone does. A normal L genotype gets the serine template, and an L genotype carrying phenylalanine and alanine at codons 277 and 285 gets the M-in-L template. A normal M genotype gets the standard template, and an M genotype carrying tyrosine and threonine at those codons gets the L-in-M template.
%[text] The mean and alanine templates are never chosen this way. A population mean is not any individual's genotype, and the alanine variant is reached through the codon 180 shift rather than through a template.
%[text] One consequence is worth noting. `applyGenotype("LSAYT/SAAFA")` produces no shift for either cone, but it is not without effect, since it moves the L cone from the mean template onto the serine template and so away from the CIE standard.
%[text] The first row of the table uses `"LSAYT/SAAFA"`, which is the pycone baseline for a normal trichromat. It reads leucine, serine, alanine, tyrosine and threonine for the L cone, and serine, alanine, alanine, phenylalanine and alanine for the M cone.
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
%[text] ## Hybrid cones
%[text] The L and M genes sit next to each other on the X chromosome. Unequal recombination between them can produce a hybrid gene, and so a hybrid pigment. Two named templates cover the common cases:
%[text] - **M-in-L**, with M-cone amino acids at L-cone positions 277 and 285. Select it with `L_OpsinTemplate="MinL"`.
%[text] - **L-in-M**, with L-cone amino acids at M-cone positions 277 and 285. Select it with `M_OpsinTemplate="LinM"`. \
%[text] Selecting a hybrid template on its own changes the shape of the absorbance spectrum but barely moves it. The `MinL` pigment has the M-cone shape with a lambda-max of 553.47 nm, only 0.36 nm from the serine L pigment.
%[text] The two pigments therefore lie almost on top of each other, but the cone fundamentals computed from them do not, because a different shape filtered and renormalized gives a different result. The `MinL` fundamental peaks at 563.75 nm against 568.00 nm for the normal L cone, 4.25 nm shorter, and the two curves differ by as much as 0.150 near 617 nm.
%[text] A real M-in-L hybrid also carries the lambda-max shift from its genotype, the -16.035 nm shown in the previous section. That shift is what places the pigment between M and L rather than merely changing its shape.
obs_hybridL = IndividualCMF(L_OpsinTemplate="MinL");
obs_hybridM = IndividualCMF(M_OpsinTemplate="LinM");
wl = (480:0.5:620)';
tiledlayout(2, 1, 'TileSpacing', 'loose', 'Padding', 'compact');
nexttile
plot(wl, obs_ser.L(wl), 'r-'); hold on
plot(wl, obs_ser.M(wl), 'g-')
plot(wl, obs_hybridL.L(wl), 'm--', 'LineWidth', 2.5); hold off
xlabel('Wavelength (nm)'); ylabel('Sensitivity')
title('M-in-L hybrid L cone')
legend('Normal L (Serine)', 'Normal M', 'Hybrid L (M-in-L)', 'Location', 'bestoutside')
nexttile
plot(wl, obs_ser.L(wl), 'r-'); hold on
plot(wl, obs_ser.M(wl), 'g-')
plot(wl, obs_hybridM.M(wl), 'c--', 'LineWidth', 2.5); hold off
xlabel('Wavelength (nm)'); ylabel('Sensitivity')
title('L-in-M hybrid M cone')
legend('Normal L (Serine)', 'Normal M', 'Hybrid M (L-in-M)', 'Location', 'bestoutside')
%%
%[text] ## Why this matters
%[text] - **Metameric matching.** Two lights that match for one observer need not match for another with a different genotype at codon 180. [Example 20](matlab:edit('Example20_ObserverMetamerism.m')) works through an example.
%[text] - **Colour discrimination.** The 2.7 nm shift changes the separation between the L and M cones slightly. Whether that produces a measurable difference in discrimination depends on the task, and remains an open question.
%[text] - **Individual calibration.** Knowing an observer's genotype improves the accuracy of colorimetric predictions made for that observer.
%[text] - **Population work.** Use `"Mean"` for population averages and a specific variant when modelling an individual. \
%%
%[text] ## Key takeaways
%[text] - Ser180Ala shifts the L photopigment lambda-max by 2.7 nm, with alanine shorter than serine. The default `"Mean"` template lies between the two
%[text] - L-cone templates are `"Mean"`, `"Serine"`, `"Alanine"` and `"MinL"`. M-cone templates are `"Mean"`, `"Standard"` and `"LinM"`
%[text] - `setGenotype(cone, position, amino_acid)` sets one site. `Genotype=struct(...)` and `Genotype="LSAYT/SAAFA"` set a whole genotype in the constructor
%[text] - `applyGenotype` chooses the templates and shifts from a five-letter string. It selects serine rather than mean for a normal L genotype, so it moves the observer away from the CIE standard even when the shifts are zero
%[text] - A hybrid template changes the shape of the pigment. The lambda-max shift that comes with a real hybrid genotype is what moves it spectrally
%[text] - `L_LambdaMaxShift` sets the peak directly, over the range -40 to +10 nm \
%[text] **Next:** [Example 10: Photopigment Models](matlab:edit('Example10_PhotopigmentModels.m')). Comparing the Stockman and Rider (2023) and Govardovskii (2000) template models.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

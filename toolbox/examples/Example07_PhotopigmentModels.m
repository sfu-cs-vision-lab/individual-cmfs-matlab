%[text] # Example 07: Photopigment Template Models
%[text] The `PhotopigmentModel` property selects the formula used for the photopigment absorbance spectrum. Two families are available:
%[text] - **Stockman & Rider (2023)**, the default. An 8th-order Fourier series in log wavelength, fitted so that the resulting cone fundamentals reproduce the CIE 2006 standard. It supports the genetic variant and hybrid templates described in [Example 06](matlab:edit('Example06_GeneticVariants.m')).
%[text] - **Govardovskii et al. (2000)**. An analytical template for A1 visual pigments, derived from microspectrophotometry across many species. It depends only on lambda-max, so it applies to non-human eyes as well. \
%[text] Both act at the first stage of the calculation. Only the absorbance spectrum differs. The later stages, which apply the lens and macular pigment and convert to energy units, are the same in both cases.
%[text] This example is about photopigment templates. The choice of lens template is covered in [Example 05](matlab:edit('Example05_AgingEffects.m')).
%[text] **Time:** about 10 minutes.
exampleDefaults();
%%
%[text] ## The two models compared
%[text] The panels below show the same observer built twice, once with each photopigment model.
wl = (390:1:700)';
obs_sr  = IndividualCMF(PhotopigmentModel="StockmanRider2023");
obs_gov = IndividualCMF(PhotopigmentModel="Govardovskii2000");
LMS_sr  = obs_sr.LMS(wl);
LMS_gov = obs_gov.LMS(wl);
tiledlayout(2, 1, 'TileSpacing', 'loose', 'Padding', 'compact');
obs_sr.plotLMS(Title="Stockman & Rider (2023)", Wavelength=wl, Parent=nexttile);
xlim([390 700]); ylim([0 1.05])
obs_gov.plotLMS(Title="Govardovskii (2000)", Wavelength=wl, Parent=nexttile);
xlim([390 700]); ylim([0 1.05])
%%
%[text] ## The same curves overlaid
%[text] Drawing both models on one set of axes shows where they differ. The two agree most closely near each cone's own peak. The largest differences fall between 480 and 620 nm and reach 0.112. Towards each end of the plotted range the differences drop below 0.035.
%[text] `compareTo` draws the first observer with solid lines and the second with dashed lines. The legend is relabelled afterwards so that the two models can be told apart.
p_cmp = obs_sr.compareTo(obs_gov, Title="Stockman & Rider (solid) vs Govardovskii (dashed)", ...
    Wavelength=wl);
xlim([390 700])
legend(p_cmp, {'L (S-R)', 'M (S-R)', 'S (S-R)', 'L (Gov)', 'M (Gov)', 'S (Gov)'}, ...
       'Location', 'bestoutside', 'NumColumns', 2);
%%
%[text] ## The differences in detail
%[text] The differences are small but they are not random. Over the visible range the root mean square difference is a few percent of the peak value.
%[text] The largest single difference is on the M cone, which is -0.112 at 591 nm. A second, smaller one of -0.075 occurs at 477 nm. Each cone shows a positive difference on one side of its peak and a negative difference on the other, which is what a small difference in peak position produces. A difference in the width of the band would not look like this.
%[text] The M cone differs most because the Stockman and Rider template was fitted to human cone fundamentals, while the Govardovskii template describes a general vertebrate A1 pigment with its beta-band written as a separate Gaussian term.
residual = LMS_sr - LMS_gov;
tiledlayout(1, 1); nexttile
plot(wl, residual(:,1), 'r-'); hold on
plot(wl, residual(:,2), 'g-')
plot(wl, residual(:,3), 'b-')
plot(wl, zeros(size(wl)), '--', 'Color', IndividualCMF.neutralColor(), 'LineWidth', 1); hold off
xlabel('Wavelength (nm)'); ylabel('Sensitivity Difference (S-R - Gov)')
title('Difference between the two template models')
legend('L', 'M', 'S', 'Location', 'bestoutside')
xlim([390 700])
table(rms(residual)', max(abs(residual))', ...
      'VariableNames', {'RMS_residual', 'MaxAbs_residual'}, ...
      'RowNames', {'L', 'M', 'S'})
%%
%[text] ## The four templates side by side
%[text:table]
%[text] | Feature | Stockman-Rider 2023 | S-R 2023 Common | Govardovskii 2000 | Govardovskii 2000 A2 |
%[text] | --- | --- | --- | --- | --- |
%[text] | CIE 2006 standard compliance | Yes | No | No | No |
%[text] | Genetic variants (Ser/Ala, hybrids) | Yes | No | No | No |
%[text] | Analytical form | 8th-order Fourier series in log wavelength | Same shape, translated in log wavelength | Reciprocal of a sum of exponentials for the alpha-band, plus a Gaussian for the beta-band | As A1, with different beta-band constants |
%[text] | Species generality | Human only | Any lambda-max, one shape | Any vertebrate A1 pigment | Vertebrate A2 (3,4-dehydroretinal) |
%[text] | Beta-band | Captured by the Fourier fit | Captured by the Fourier fit | Explicit Gaussian, amplitude 0.26 | Explicit Gaussian, amplitude 0.37 |
%[text] | Valid wavelength range | 360-830 nm | 360-830 nm | 380-780 nm | 380-780 nm |
%[text:table]
%%
%[text] ## Choosing between them
%[text] Use **Stockman & Rider (2023)** for CIE 2006 compliance, for human observers, for the genetic variant and hybrid templates, and when comparing against published human cone fundamentals.
%[text] Use **Govardovskii (2000)** when an analytical form depending only on lambda-max is wanted, when the beta-band is needed as a separate term that can be inspected or varied, or when modelling a vertebrate pigment of known lambda-max. Use the **A2** variant for the pigments of freshwater fish and larval amphibians, which are built on 3,4-dehydroretinal.
%[text] Use the **Stockman and Rider common template** when an arbitrary lambda-max is wanted but the Stockman and Rider shape is preferred to the Govardovskii one. It is the same Fourier shape translated along the log wavelength axis, so it remains consistent with the default model. The last two options serve a similar purpose, and the final section of this example compares them directly at a matched lambda-max.
%%
%[text] ## Changing the model after construction
%[text] `PhotopigmentModel` can be assigned at any time. Doing so sets `Type` to `"Individualized"`, since the resulting observer no longer matches the CIE 2006 standard.
obs = IndividualCMF();
type_before = obs.Type;
template_before = obs.PhotopigmentModel;
obs.PhotopigmentModel = "Govardovskii2000";
type_after = obs.Type;
template_after = obs.PhotopigmentModel;
table(template_before, type_before, template_after, type_after, ...
      'VariableNames', {'TemplateBefore', 'TypeBefore', 'TemplateAfter', 'TypeAfter'})
%%
%[text] ## The A1 and A2 chromophores
%[text] Govardovskii et al. (2000) give templates for both photoreceptor chromophores. **A1** is 11-cis retinal, which is the chromophore in humans and other mammals. **A2** is 11-cis 3,4-dehydroretinal, found in freshwater fish, larval amphibians and some reptiles. Select them with `PhotopigmentModel="Govardovskii2000"` and `"Govardovskii2000A2"`.
%[text] This section applies only to non-human visual systems. Use A1 for human cone fundamentals.
%[text] At the same lambda-max the two templates differ in three ways:
%[text] - The A2 sensitivity decreases more slowly at long wavelengths.
%[text] - The beta-band amplitude is 0.37 for A2 against 0.26 for A1.
%[text] - The width of the beta-band is a quadratic function of lambda-max for A2 and a linear function for A1. \
%[text] The plot below shows both templates at a lambda-max of 560 nm, close to that of a human L cone. The A2 absorbance extends further into the red, and it is also higher below 450 nm.
%[text] That rise below 450 nm is the long-wavelength side of the beta-band. The A2 beta-band peaks near 377 nm, which is 216.7 plus 0.287 times lambda-max, and so lies 2.6 nm to the left of this plot. The A1 beta-band peaks further out still, at 365 nm, which is 189 plus 0.315 times lambda-max.
wl_a2 = (380:1:780)';
absA1 = Nomograms.govardovskii2000(wl_a2, 560);
absA2 = Nomograms.govardovskii2000A2(wl_a2, 560);
tiledlayout(1, 1); nexttile
plot(wl_a2, absA1, 'b-'); hold on
plot(wl_a2, absA2, 'r-'); hold off
xlabel('Wavelength (nm)'); ylabel('Absorbance')
title('Govardovskii (2000) A1 and A2 at lambda_{max} = 560 nm')
legend('A1 (11-cis retinal)', 'A2 (3,4-dehydroretinal)', 'Location', 'bestoutside')
xlim([380 780])
%%
%[text] ## The common template at an arbitrary lambda-max
%[text] Stockman and Rider (2023) also give a common template, in column 3 of their Table 4. It is a single 8th-order Fourier shape translated along the log wavelength axis to fit all three cones. Select it with `PhotopigmentModel="StockmanRider2023Common"`.
%[text] Like the Govardovskii template it does not use the genetic variant templates, and it is intended for work across species or at an arbitrary lambda-max rather than for CIE-compliant human fundamentals.
%[text] Because one shape serves every cone, a non-human lambda-max can be reached through the cone shifts alone. The figure below anchors the common template at its M lambda-max of 527.3 nm and applies a shift of +20 nm, giving a pigment near 547 nm. The Govardovskii template at the same lambda-max is drawn alongside it.
%[text] The two agree closely through the main band and at long wavelengths, where they stay within 0.017 of each other. At short wavelengths they differ by up to 0.106, about a tenth of the peak value. The disagreement is on one side only, which follows from the two templates treating the beta-band differently.
wl_common = (380:1:780)';
absCommon = 10.^Nomograms.stockmanRiderCommon(wl_common, 'M', 20);
absGovRef = Nomograms.govardovskii2000(wl_common, 547.3);
tiledlayout(1, 1); nexttile
plot(wl_common, absCommon, 'm-'); hold on
plot(wl_common, absGovRef, '--', 'Color', IndividualCMF.neutralColor()); hold off
xlabel('Wavelength (nm)'); ylabel('Absorbance')
title('S-R common template (M +20 nm) and Govardovskii at 547.3 nm')
legend('S-R common (shifted)', 'Govardovskii (2000)', 'Location', 'bestoutside')
xlim([380 780])
%%
%[text] ## Key takeaways
%[text] - Stockman & Rider (2023) is the default. It matches the CIE standard and supports the human genetic variants
%[text] - Govardovskii (2000) needs only a lambda-max. It comes in an A1 form (`Govardovskii2000`) and an A2 form (`Govardovskii2000A2`)
%[text] - A1 is the human and mammalian chromophore. A2 is found in freshwater fish and larval amphibians, and its sensitivity decreases more slowly at long wavelengths with a stronger beta-band
%[text] - The two models agree closely near each cone peak. The differences are small, systematic, and largest on the M cone at 591 nm
%[text] - Assigning `obs.PhotopigmentModel` changes the template at any time and sets `Type` to `"Individualized"` \
%[text] **Next:** [Example 08: Computational Pipeline](matlab:edit('Example08_ComputationalPipeline.m')). The four stages from photopigment absorbance to corneal sensitivity.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

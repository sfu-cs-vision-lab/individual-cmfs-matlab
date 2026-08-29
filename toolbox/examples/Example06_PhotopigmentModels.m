%[text] # Example 06: Photopigment Template Models
%[text] Two photopigment absorbance template families are available via the `PhotopigmentModel` property:
%[text] - **Stockman & Rider (2023)** *(default)* -- 8th-order shifted Fourier series refit to recover the CIE 2006 cone fundamentals; supports the genetic-variant and hybrid templates from [Example 05](matlab:edit('Example05_GeneticVariants.m')).
%[text] - **Govardovskii et al. (2000)** -- continuous analytical template based on A1 visual pigments from microspectrophotometry across many species; depends only on lambda-max, so it generalises to non-human eyes. \
%[text] **Time:** about 10 minutes. 
exampleDefaults();
%[text] **Note:** this example is about *photopigment* templates. The lens template selection (`LensModel`) is covered in [Example 04: Aging Effects on Color Vision](matlab:edit('Example04_AgingEffects.m')).
%[text] Both models occupy stage 1 of the pipeline; what differs is the absorbance shape, and downstream stages (lens, macular, energy conversion) are identical.
%%
%[text] ## Stacked comparison
%[text] Build the same observer twice -- once with each photopigment model -- and plot the resulting LMS fundamentals using `obs.plotLMS(Parent=ax)` in a tiled layout.
wl = (390:1:700)';
obs_sr  = IndividualCMF(PhotopigmentModel="StockmanRider2023");
obs_gov = IndividualCMF(PhotopigmentModel="Govardovskii2000");
LMS_sr  = obs_sr.LMS(wl);
LMS_gov = obs_gov.LMS(wl);
tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
obs_sr.plotLMS(Title="Stockman & Rider (2023)", Wavelength=wl, Parent=nexttile);
xlim([390 700]); ylim([0 1.05])
obs_gov.plotLMS(Title="Govardovskii (2000)", Wavelength=wl, Parent=nexttile);
xlim([390 700]); ylim([0 1.05])
%%
%[text] ## Overlay comparison
%[text] Plotting both models on the same axes makes the differences obvious. The two are closest near each cone's own peak and diverge on the flanks; in absolute terms the largest gaps sit between 480 and 620 nm (up to 0.112), while at the ends of the plotted range the residuals fall below 0.035. `compareTo` paints the first observer's curves solid and the second observer's dashed; the legend is relabeled afterwards to distinguish S-R from Gov.
p_cmp = obs_sr.compareTo(obs_gov, Title="Stockman & Rider (solid) vs Govardovskii (dashed)", ...
    Wavelength=wl);
xlim([390 700])
legend(p_cmp, {'L (S-R)', 'M (S-R)', 'S (S-R)', 'L (Gov)', 'M (Gov)', 'S (Gov)'}, ...
       'Location', 'bestoutside', 'NumColumns', 2);
%%
%[text] ## Residual analysis
%[text] The differences are small but systematic. RMS errors over the visible range stay around a few percent of unity, with the largest disagreement on the M cone's long-wave flank -- -0.112 near 591 nm -- and a secondary excursion of -0.075 on its short-wave flank near 477 nm. The paired positive-then-negative lobes around each peak are the classic signature of a small difference in peak position rather than in band shape. The M-cone diverges most because Stockman & Rider 2023 was tuned against human cone fundamentals, while the Govardovskii template is a species-general A1 absorbance shape with a separately parameterized beta-band Gaussian.
residual = LMS_sr - LMS_gov;
plot(wl, residual(:,1), 'r-'); hold on
plot(wl, residual(:,2), 'g-')
plot(wl, residual(:,3), 'b-')
plot(wl, zeros(size(wl)), '--', 'Color', IndividualCMF.neutralColor(), 'LineWidth', 1); hold off
xlabel('Wavelength (nm)'); ylabel('Sensitivity Difference (S-R - Gov)')
title('Residuals between template models')
legend('L', 'M', 'S', 'Location', 'bestoutside')
xlim([390 700])
table(rms(residual)', max(abs(residual))', ...
      'VariableNames', {'RMS_residual', 'MaxAbs_residual'}, ...
      'RowNames', {'L', 'M', 'S'})
%%
%[text] ## Feature comparison
%[text:table]
%[text] | Feature | Stockman-Rider 2023 | S-R 2023 Common | Govardovskii 2000 | Govardovskii 2000 A2 |
%[text] | --- | --- | --- | --- | --- |
%[text] | CIE 2006 standard compliance | Yes | No | No | No |
%[text] | Genetic variants (Ser/Ala, hybrids) | Yes | No | No | No |
%[text] | Analytical form | 8th-order shifted Fourier (in log-lambda) | Same shape, translated in log-lambda | Reciprocal of a sum of exponentials (alpha-band) + Gaussian (beta-band) | As A1, different beta constants |
%[text] | Species generality | Human only | Any lambda-max, shape-invariant | Any vertebrate A1 pigment | Vertebrate A2 (3,4-dehydroretinal) |
%[text] | Beta-band shape | Implicit (Fourier capture) | Implicit (Fourier capture) | Explicit Gaussian, amplitude 0.26 | Explicit Gaussian, amplitude 0.37 |
%[text] | Valid wavelength range | 360-830 nm | 360-830 nm | 380-780 nm | 380-780 nm |
%[text:table]
%%
%[text] ## When to use which
%[text] **Use Stockman & Rider (2023) when** you need CIE 2006 compliance, you're modeling human observers specifically, you want to use the genetic-variant or hybrid templates, or you're matching published human cone fundamental data.
%[text] **Use Govardovskii (2000) when** you want an analytical form parameterised purely by lambda-max, with the beta band as an explicit term you can inspect or vary, or you are modelling a vertebrate pigment whose lambda-max is known. Use the **A2** variant for freshwater-fish and larval-amphibian pigments built on 3,4-dehydroretinal.
%[text] **Use the S-R common template when** you want an arbitrary lambda-max but would rather keep the Stockman-Rider shape than adopt Govardovskii's -- it is the same Fourier shape translated along log-wavelength, so it stays consistent with the default model's flanks. The two species-general options overlap in purpose; the section below compares them directly at a matched lambda-max.
%%
%[text] ## Switching templates dynamically
%[text] You can change `PhotopigmentModel` after construction. Doing so flips `Type` to `"Individualized"` since the resulting observer no longer matches the CIE 2006 standard exactly.
obs = IndividualCMF();
type_before = obs.Type;
template_before = obs.PhotopigmentModel;
obs.PhotopigmentModel = "Govardovskii2000";
type_after = obs.Type;
template_after = obs.PhotopigmentModel;
table(template_before, type_before, template_after, type_after, ...
      'VariableNames', {'TemplateBefore', 'TypeBefore', 'TemplateAfter', 'TypeAfter'})
%%
%[text] ## Comparative vision research: A1 vs A2 chromophore
%[text] Govardovskii et al. (2000) defined templates for both photoreceptor chromophores: **A1** (11-cis retinal, the standard human/mammalian chromophore) and **A2** (11-cis 3,4-dehydroretinal, found in freshwater fish, larval amphibians, and some reptiles). Select via `PhotopigmentModel="Govardovskii2000"` or `"Govardovskii2000A2"`. This subsection is only relevant when modeling non-human visual systems; for human cone fundamentals stick with A1.
%[text] At the same lambda-max the two templates differ in:
%[text] - **Long-wavelength decay rate** -- A2 has a slower long-wave roll-off
%[text] - **Beta-band amplitude** -- 0.37 (A2) vs 0.26 (A1)
%[text] - **Beta-band width regression** -- quadratic in lambda-max for A2 (Eq. 8b) vs linear for A1 (Eq. 5b) \
%[text] The plot below shows both templates for an L-cone-like lambda-max (560 nm). The A2 long-wave flank reaches further into the red, and the short-wavelength shoulder below 450 nm sits higher (this is the right edge of the beta-band; the A2 beta peak lies near 377 nm (216.7 + 0.287 x lambda-max), 2.6 nm off the left edge of this plot, so only its right shoulder is visible. The A1 beta peak sits further out still, at 365 nm (189 + 0.315 x lambda-max)).
wl_a2 = (380:1:780)';
absA1 = Nomograms.govardovskii2000(wl_a2, 560);
absA2 = Nomograms.govardovskii2000A2(wl_a2, 560);
plot(wl_a2, absA1, 'b-'); hold on
plot(wl_a2, absA2, 'r-'); hold off
xlabel('Wavelength (nm)'); ylabel('Absorbance')
title('Govardovskii (2000) A1 vs A2 at lambda_{max} = 560 nm')
legend('A1 (11-cis retinal)', 'A2 (3,4-dehydroretinal)', 'Location', 'bestoutside')
xlim([380 780])
%%
%[text] ## Shape-invariant common template for arbitrary lambda-max
%[text] Stockman & Rider (2023) also published a **common** (shape-invariant) template (Table 4, column 3): a single 8th-order Fourier shape translated along log-wavelength to fit all three cones. Select it with `PhotopigmentModel="StockmanRider2023Common"`. Like Govardovskii, it ignores the genetic-variant opsin templates and is meant for cross-species or arbitrary lambda-max work rather than CIE-compliant human fundamentals.
%[text] Because one shape serves every cone, you can drive it to a non-human lambda-max purely through the cone shifts. Below we anchor the common template at its base M lambda-max (527.3 nm) and apply a +20 nm shift to model a hypothetical longer-wavelength M-like pigment near 547 nm, alongside the Govardovskii template at the matching lambda-max for reference.
%[text] - **Common template** -- absorbance comes straight from `Nomograms.stockmanRiderCommon`
%[text] - **Govardovskii** -- `Nomograms.govardovskii2000` evaluated at the same lambda-max \
%[text] The two species-general shapes agree closely through the central band and along the long-wave flank (both within 0.017) and part company on the short-wave flank, where the gap reaches 0.106 -- about a tenth of peak. The divergence is one-sided, which is what you would expect from templates whose beta-band treatments differ.
wl_common = (380:1:780)';
absCommon = 10.^Nomograms.stockmanRiderCommon(wl_common, 'M', 20);
absGovRef = Nomograms.govardovskii2000(wl_common, 547.3);
plot(wl_common, absCommon, 'm-'); hold on
plot(wl_common, absGovRef, '--', 'Color', IndividualCMF.neutralColor()); hold off
xlabel('Wavelength (nm)'); ylabel('Absorbance')
title('S-R common (M +20 nm) vs Govardovskii at 547.3 nm')
legend('S-R common (shifted)', 'Govardovskii (2000)', 'Location', 'bestoutside')
xlim([380 780])
%%
%[text] ## Key takeaways
%[text] - Stockman & Rider (2023) is the default -- CIE-compliant, supports human-specific variants
%[text] - Govardovskii (2000) is a single-parameter pigment template; available in A1 (`Govardovskii2000`) and A2 (`Govardovskii2000A2`) chromophore variants
%[text] - A1 is the standard human/mammalian chromophore; A2 is the freshwater-fish / larval-amphibian variant with a slower long-wavelength roll-off and stronger beta-band
%[text] - The Stockman-Rider and Govardovskii A1 templates agree in the visible-range center; small systematic differences appear at the band edges
%[text] - `obs.PhotopigmentModel = "..."` swaps templates dynamically; doing so flips `Type` to `"Individualized"` \
%[text] **Next:** [Example 07: Computational Pipeline](matlab:edit('Example07_ComputationalPipeline.m')) -- the four-stage visual pipeline from absorbance to corneal sensitivity.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

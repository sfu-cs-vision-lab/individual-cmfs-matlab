%[text] # Example 06: Template Model Comparison
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
%[text] Plotting both models on the same axes makes the differences obvious. The two are very close in the central visible range but diverge slightly near the band edges. `compareTo` paints the first observer's curves solid and the second observer's dashed; the legend is relabeled afterwards to distinguish S-R from Gov.
obs_sr.compareTo(obs_gov, Title="Stockman & Rider (solid) vs Govardovskii (dashed)", ...
    Wavelength=wl);
xlim([390 700])
legend({'L (S-R)', 'M (S-R)', 'S (S-R)', 'L (Gov)', 'M (Gov)', 'S (Gov)'}, ...
       'Location', 'bestoutside', 'NumColumns', 2);
%%
%[text] ## Residual analysis
%[text] The differences are small but systematic. RMS errors over the visible range stay around a few percent of unity, with the largest disagreement in the M-cone region near 480 nm (the short-wave flank of the M band) and a secondary negative excursion around 580 nm. The M-cone diverges most because Stockman & Rider 2023 was tuned against human cone fundamentals, while the Govardovskii template is a species-general A1 absorbance shape with a separately parameterized beta-band Gaussian.
residual = LMS_sr - LMS_gov;
plot(wl, residual(:,1), 'r-'); hold on
plot(wl, residual(:,2), 'g-')
plot(wl, residual(:,3), 'b-')
plot(wl, zeros(size(wl)), 'k--', 'LineWidth', 1); hold off
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
%[text] | Feature | Stockman-Rider 2023 | Govardovskii 2000 |
%[text] | --- | --- | --- |
%[text] | CIE 2006 standard compliance | Yes | No |
%[text] | Genetic variants (Ser/Ala, hybrids) | Yes | No |
%[text] | Analytical form | 8th-order shifted Fourier (in log-lambda) | Sum of exponentials (alpha-band) + Gaussian (beta-band) |
%[text] | Species generality | Human only | Any A1 pigment |
%[text] | Beta-band shape | Implicit (Fourier capture) | Explicit Gaussian term |
%[text:table]
%%
%[text] ## When to use which
%[text] **Use Stockman & Rider (2023) when** you need CIE 2006 compliance, you're modeling human observers specifically, you want to use the genetic-variant or hybrid templates, or you're matching published human cone fundamental data.
%[text] **Use Govardovskii (2000) when** you're comparing across species, you need an analytical form parameterised purely by lambda-max, you want to extrapolate lambda-max to arbitrary positions, or you prefer the simpler functional form.
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
%[text] The plot below shows both templates for an L-cone-like lambda-max (560 nm). The A2 long-wave flank reaches further into the red, and the short-wavelength shoulder below 450 nm sits higher (this is the right edge of the beta-band; the beta peak itself lies near 365 nm, off the plot to the left).
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

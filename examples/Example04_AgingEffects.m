%[text] # Example 04: Aging Effects on Color Vision
%[text] The crystalline lens grows progressively denser at short wavelengths with age. This example compares the three available `LensModel` choices and quantifies the impact on S-cone sensitivity.
%[text] **Time:** about 12 minutes.
exampleDefaults();
%%
%[text] ## The lens models
%[text] Three `LensModel` choices:
%[text] - **`StockmanRider2023`** *(default)*. Flat across age. Returns the standard density (1.7649 at 400 nm) regardless of `Age`. Useful for matching CIE 2006 cone fundamentals exactly.
%[text] - **`VanDeKraats2007`**. Five-component total-ocular-media model (van de Kraats & van Norren 2007) with quadratic-in-age density coefficients fitted across 74 donor lenses and 23 in vivo / psychophysics datasets, plus explicit Rayleigh-scatter and tryptophan components that extend the model into the near-UV.
%[text] - **`Pokorny1987`**. Bi-linear age-dependent model from Pokorny, Smith & Lutze (1987). Yellowing accelerates after age 60. \
%[text] This example focuses on `StockmanRider2023` vs `VanDeKraats2007`; `Pokorny1987` follows the same usage pattern. \\
%[text] **Important:** with the default `StockmanRider2023` model, changing `Age` does **not** change `LensDensity`. To study aging, opt into `VanDeKraats2007` or `Pokorny1987`.
ages = [20, 32, 45, 60, 75];
obs_SR = IndividualCMF.across('Age', ages, LensModel="StockmanRider2023");
observers = IndividualCMF.across('Age', ages, LensModel="VanDeKraats2007", FieldSize=10);
table(ages', [obs_SR.LensDensity]', [observers.LensDensity]', ...
      'VariableNames', {'Age', 'LensDensity_StockmanRider2023', 'LensDensity_VanDeKraats2007'})
%%
%[text] ## Lens density spectrum across ages (VanDeKraats2007)
%[text] The lens absorbs more strongly at short wavelengths. As age rises, the entire short-wavelength tail lifts.
wl = (380:1:550)';
colors = lines(numel(ages));
plot(wl, observers(1).getLensDensitySpectrum(wl), 'Color', colors(1,:), ...
    'DisplayName', sprintf('Age %d', ages(1)));
hold on
for i = 2:numel(ages)
    plot(wl, observers(i).getLensDensitySpectrum(wl), 'Color', colors(i,:), ...
        'DisplayName', sprintf('Age %d', ages(i)));
end
hold off
xlabel('Wavelength (nm)'); ylabel('Lens Optical Density')
title('Lens yellowing with age (VanDeKraats2007 model)')
legend('Location', 'bestoutside')
%%
%[text] ## Impact on S-cone sensitivity
%[text] Because S-cones are most sensitive to short wavelengths, the lens yellowing hits them hardest. Each curve is the S-cone fundamental for a VanDeKraats2007 observer at the indicated age.
wl_full = (380:1:700)';
plot(wl_full, observers(1).S(wl_full), 'Color', colors(1,:), ...
    'DisplayName', sprintf('Age %d', ages(1)));
hold on
for i = 2:numel(ages)
    plot(wl_full, observers(i).S(wl_full), 'Color', colors(i,:), ...
        'DisplayName', sprintf('Age %d', ages(i)));
end
hold off
xlabel('Wavelength (nm)'); ylabel('S-Cone Sensitivity')
title('S-cone sensitivity decreases with age')
legend('Location', 'bestoutside')
xlim([380 550])
%%
%[text] ## Young vs old: full LMS comparison
%[text] Stacked comparison of a 20-year-old and a 75-year-old observer (both VanDeKraats2007) via `obs.plotLMS(Parent=ax)`. The L and M cones change relatively little; the S-cone amplitude visibly decreases.
obs_young = observers(1);
obs_old   = observers(end);
tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
obs_young.plotLMS(Title=sprintf('Age %d', ages(1)), Wavelength=wl_full, Parent=nexttile);
xlim([380 780]); ylim([0 1.05])
obs_old.plotLMS(Title=sprintf('Age %d', ages(end)), Wavelength=wl_full, Parent=nexttile);
xlim([380 780]); ylim([0 1.05])
%%
%[text] ## Quantifying sensitivity loss
%[text] To compare aging effects across the three cone types we need **unnormalized** fundamentals; the default `NormalizeOutput=true` renormalizes each curve to peak 1.0 and hides the amplitude change. Integrating each cone's unnormalized response over the visible range gives a single "total catch" number per cone. The S-cone loss dominates because the lens-yellowing region overlaps the S-cone's response.
wl_full = (380:1:780)';
obs_y_raw = IndividualCMF(LensModel="VanDeKraats2007", Age=20, FieldSize=10, NormalizeOutput=false);
obs_o_raw = IndividualCMF(LensModel="VanDeKraats2007", Age=75, FieldSize=10, NormalizeOutput=false);
catch_young = trapz(wl_full, obs_y_raw.LMS(wl_full));
catch_old   = trapz(wl_full, obs_o_raw.LMS(wl_full));
ratio_pct = catch_old ./ catch_young * 100;
table(catch_young', catch_old', ratio_pct', ...
      'VariableNames', {'TotalCatch_Age20', 'TotalCatch_Age75', 'Age75_vs_Age20_pct'}, ...
      'RowNames', {'L', 'M', 'S'})
%%
%[text] ## Comparing all three lens models at age 70
%[text] At a fixed age the three `LensModel` choices disagree: `StockmanRider2023` is flat across age (1.7649 at all ages); `Pokorny1987` and `VanDeKraats2007` give age-dependent spectra fit from independent datasets.
wl_lens = (380:1:550)';
obs70_SR = IndividualCMF(LensModel="StockmanRider2023", Age=70, FieldSize=10);
obs70_P  = IndividualCMF(LensModel="Pokorny1987",       Age=70, FieldSize=10);
obs70_VK = IndividualCMF(LensModel="VanDeKraats2007",   Age=70, FieldSize=10);
plot(wl_lens, obs70_SR.getLensDensitySpectrum(wl_lens), 'k-', 'LineWidth', 1.5); hold on
plot(wl_lens, obs70_P.getLensDensitySpectrum(wl_lens),  'b-', 'LineWidth', 1.5)
plot(wl_lens, obs70_VK.getLensDensitySpectrum(wl_lens), 'r-', 'LineWidth', 1.5); hold off
xlabel('Wavelength (nm)'); ylabel('Lens Optical Density')
title('Three lens models at age 70')
legend('StockmanRider2023 (flat with age)', 'Pokorny1987', 'VanDeKraats2007', 'Location', 'bestoutside')
grid on
%%
%[text] ## Custom-mode override (advanced)
%[text] The `LensDensity` value computed by the lens model can be overridden directly. Doing so auto-engages `LensDensityAlgorithm="Custom"` so the override is preserved across subsequent `Age` changes. See [Example 14: Advanced Customization](matlab:edit('Example14_AdvancedCustomization.m')) for full coverage.
obs_override = IndividualCMF(LensModel="VanDeKraats2007", Age=55, LensDensity=2.0);
table(obs_override.Age, obs_override.LensDensity, string(obs_override.LensDensityAlgorithm), ...
      'VariableNames', {'Age', 'LensDensity', 'Algorithm'})
%%
%[text] ## Key takeaways
%[text] - The crystalline lens yellows progressively with age
%[text] - S-cone sensitivity is most affected; L and M are nearly age-invariant
%[text] - Pick `LensModel` deliberately: `StockmanRider2023` for CIE-spec compliance, `VanDeKraats2007` (or `Pokorny1987`) for age studies
%[text] - Setting `LensDensity` directly auto-engages Custom mode and preserves the value across Age changes \
%[text] **Next:** [Example 05: Genetic Variants and Cone Polymorphisms](matlab:edit('Example05_GeneticVariants.m')). Modeling individual genetic differences via the L-cone Ser180Ala polymorphism and hybrid cone variants.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

%[text] # Example 08: Aging Effects on Color Vision
%[text] The crystalline lens absorbs more short-wavelength light as a person ages. This example compares the three `LensModel` choices and measures the effect on the cone fundamentals.
%[text] **Time:** about 12 minutes.
exampleDefaults();
%%
%[text] ## The three lens models
%[text] - **`StockmanRider2023`**, the default. Its density does not depend on age. It returns the standard value of 1.7649 at 400 nm whatever `Age` is set to, which is the lens density the CIE 2006 standard specifies for its 32 year old observer.
%[text] - **`VanDeKraats2007`**. A five-component model of the whole ocular media, with density coefficients quadratic in age. It was fitted to 74 donor lenses from 20 sources, 17 psychophysical sensitivity curves and 23 spectral reflection measurements. Separate Rayleigh scattering and tryptophan components extend it into the near ultraviolet.
%[text] - **`Pokorny1987`**. Linear in age in two segments, with a change of slope at 60 years after which the density rises faster. Its published age range is 20 to 80 years, and the toolbox raises an error outside that range because the paper does not support extrapolation. Its Table I applies to a small pupil of less than 3 mm. For a dilated eye, multiply `LensDensity` by 0.86. Below 400 nm the toolbox reports no value rather than holding the 400 nm value flat, so `LMS` returns 0 and `getLensDensitySpectrum` returns `NaN`. Use `VanDeKraats2007` below 400 nm or outside the published age range. \
%[text] Each template declares two wavelength ranges. `ValidRange` is where the publication provides a basis, and `Domain` is where the implementation can return an answer at all. A wavelength outside `ValidRange` produces one warning per observer and the value is still returned. A wavelength outside `Domain` returns no value.
%[text] Both cases appear in this example. `VanDeKraats2007` was fitted over 300 to 700 nm, so the 380 to 780 nm grid used below reaches 80 nm past the fit and raises `IndividualCMF:WavelengthOutOfRange`. The extrapolation there is a smooth decay of bounded size and the values are kept. `Pokorny1987` has no value below 400 nm, so in the three-model figure at the end its curve simply starts 20 nm later than the others. Set `obs.ModelRangeWarning = false` once you have noted either case.
%[text] Most of this example compares `StockmanRider2023` with `VanDeKraats2007`. `Pokorny1987` is used in the same way.
%[text] Note that with the default `StockmanRider2023` model, changing `Age` does not change `LensDensity`. Studying age therefore requires `VanDeKraats2007` or `Pokorny1987`. Assigning `LensDensity` directly, for instance to a measured value, selects `Custom` mode, after which the value follows neither `Age` nor `LensModel` until it is reassigned or cleared with `obs.LensDensity = []`.
ages = [20, 32, 45, 60, 75];
obs_SR = IndividualCMF.across('Age', ages, LensModel="StockmanRider2023");
observers = IndividualCMF.across('Age', ages, LensModel="VanDeKraats2007", FieldSize=10);
table(ages', [obs_SR.LensDensity]', [observers.LensDensity]', ...
      'VariableNames', {'Age', 'LensDensity_StockmanRider2023', 'LensDensity_VanDeKraats2007'})
%%
%[text] ## Lens density across ages
%[text] The lens absorbs most strongly at short wavelengths, and the density at those wavelengths increases with age.
wl = (380:1:550)';
colors = lines(numel(ages));
tiledlayout(1, 1); nexttile
plot(wl, observers(1).getLensDensitySpectrum(wl), 'Color', colors(1,:), ...
    'DisplayName', sprintf('Age %d', ages(1)));
hold on
for i = 2:numel(ages)
    plot(wl, observers(i).getLensDensitySpectrum(wl), 'Color', colors(i,:), ...
        'DisplayName', sprintf('Age %d', ages(i)));
end
hold off
xlabel('Wavelength (nm)'); ylabel('Lens Optical Density')
title('Lens density with age (VanDeKraats2007 model)')
legend('Location', 'bestoutside')
%%
%[text] ## Effect on S-cone sensitivity
%[text] The S cone is most sensitive at short wavelengths, which is where the lens absorbs most, so the S cone is affected most.
%[text] The curves below are plotted with `NormalizeOutput=false`, so they show the actual loss of sensitivity. Under the default normalization each curve would reach 1.0 at its own peak and the loss would not be visible.
wl_full = (380:1:700)';
tiledlayout(1, 1); nexttile
plot(wl_full, observers(1).S(wl_full, NormalizeOutput=false), 'Color', colors(1,:), ...
    'DisplayName', sprintf('Age %d', ages(1)));
hold on
for i = 2:numel(ages)
    plot(wl_full, observers(i).S(wl_full, NormalizeOutput=false), 'Color', colors(i,:), ...
        'DisplayName', sprintf('Age %d', ages(i)));
end
hold off
xlabel('Wavelength (nm)'); ylabel('S-Cone Sensitivity')
title('S-cone sensitivity decreases with age')
legend('Location', 'bestoutside')
xlim([380 550])
%%
%[text] ## A 20 year old and a 75 year old compared
%[text] The two panels below show all three cones for a 20 year old and a 75 year old, both using `VanDeKraats2007`. These panels are peak-normalized, so they show only the change in shape. All three cones also lose sensitivity, which the next section measures.
%[text] The S cone changes most. Its peak lies within the range where the lens absorbs strongly, so dividing by that peak increases the normalized sensitivity at longer wavelengths. Between ages 20 and 75 the normalized S curve falls from 0.584 to 0.280 at 420 nm and rises from 0.766 to 0.956 at 460 nm.
%[text] The peak of the S curve also moves, from 442 to 452 nm. This is the lens absorbing more of the short-wavelength light the S cone depends on, which leaves the largest response at a longer wavelength than before. It is not a change in the S photopigment, and it is not an effect of normalization: dividing by a scalar cannot move the wavelength at which a curve is largest, and the peak sits at 452 nm whether the output is normalized or not.
%[text] The L and M cones change less. Their normalized curves move by at most 0.124 and 0.140 near 510 and 491 nm, against 0.312 for S. The change is not negligible. The normalized M sensitivity at 440 nm falls from 0.115 to 0.040.
obs_young = observers(1);
obs_old   = observers(end);
tiledlayout(2, 1, 'TileSpacing', 'loose', 'Padding', 'compact');
obs_young.plotLMS(Title=sprintf('Age %d', ages(1)), Wavelength=wl_full, Parent=nexttile);
xlim([wl_full(1) wl_full(end)]); ylim([0 1.05])
obs_old.plotLMS(Title=sprintf('Age %d', ages(end)), Wavelength=wl_full, Parent=nexttile);
xlim([wl_full(1) wl_full(end)]); ylim([0 1.05])
%%
%[text] ## Measuring the loss of sensitivity
%[text] Comparing the loss across the three cone types requires unnormalized fundamentals, since the default `NormalizeOutput=true` rescales each curve to a peak of 1.0 and removes the difference being measured.
%[text] Integrating each unnormalized cone sensitivity over the visible range gives one number per cone, the total amount of light that cone absorbs from an equal-energy spectrum. The table reports the age 75 value as a percentage of the age 20 value.
wl_full = (380:1:780)';
obs_y_raw = IndividualCMF(LensModel="VanDeKraats2007", Age=20, FieldSize=10, NormalizeOutput=false);
obs_o_raw = IndividualCMF(LensModel="VanDeKraats2007", Age=75, FieldSize=10, NormalizeOutput=false);
catch_young = trapz(wl_full, obs_y_raw.LMS(wl_full));
catch_old   = trapz(wl_full, obs_o_raw.LMS(wl_full));
ratio_pct = catch_old ./ catch_young * 100;
table(catch_young', catch_old', ratio_pct', ...
      'VariableNames', {'TotalCatch_Age20', 'TotalCatch_Age75', 'Age75_vs_Age20_pct'}, ...
      'RowNames', {'L', 'M', 'S'})
%[text] The S cone retains about a third of its age 20 value, because the wavelengths where the lens density rises most are the wavelengths the S cone depends on. The L and M cones retain about four fifths and three quarters.
%%
%[text] ## The three lens models at age 70
%[text] At a fixed age the three models give different densities. `StockmanRider2023` returns 1.7649 at every age. `Pokorny1987` and `VanDeKraats2007` were fitted to different datasets and depend on age in different ways.
wl_lens = (380:1:550)';
obs70_SR = IndividualCMF(LensModel="StockmanRider2023", Age=70, FieldSize=10);
obs70_P  = IndividualCMF(LensModel="Pokorny1987",       Age=70, FieldSize=10);
obs70_VK = IndividualCMF(LensModel="VanDeKraats2007",   Age=70, FieldSize=10);
tiledlayout(1, 1); nexttile
plot(wl_lens, obs70_SR.getLensDensitySpectrum(wl_lens), '-', 'Color', IndividualCMF.neutralColor(), 'LineWidth', 1.5); hold on
plot(wl_lens, obs70_P.getLensDensitySpectrum(wl_lens),  'b-', 'LineWidth', 1.5)
plot(wl_lens, obs70_VK.getLensDensitySpectrum(wl_lens), 'r-', 'LineWidth', 1.5); hold off
xlabel('Wavelength (nm)'); ylabel('Lens Optical Density')
title('Three lens models at age 70')
legend('StockmanRider2023 (no age dependence)', 'Pokorny1987', 'VanDeKraats2007', 'Location', 'bestoutside')
grid on
%%
%[text] ## Setting the lens density directly
%[text] The density computed by the lens model can be replaced with a value of your own. Doing so selects `LensDensityAlgorithm="Custom"`, so the value is kept through later changes to `Age`. Assigning `obs.LensDensity = []` returns control to the model. [Example 16](matlab:edit('Example16_AdvancedCustomization.m')) covers this in full.
obs_override = IndividualCMF(LensModel="VanDeKraats2007", Age=55, LensDensity=2.0);
table(obs_override.Age, obs_override.LensDensity, string(obs_override.LensDensityAlgorithm), ...
      'VariableNames', {'Age', 'LensDensity', 'Algorithm'})
%%
%[text] ## Key takeaways
%[text] - The lens absorbs more short-wavelength light with age
%[text] - The S cone is affected most, retaining about a third of its age 20 sensitivity by age 75. The L and M cones retain about four fifths and three quarters
%[text] - The normalized shape of the L and M curves changes little with age, which is what the peak-normalized plots show. Measuring the loss of sensitivity requires `NormalizeOutput=false`
%[text] - Choose `LensModel` deliberately. Use `StockmanRider2023` to match the CIE standard, and `VanDeKraats2007` or `Pokorny1987` to study age
%[text] - Assigning `LensDensity` directly selects Custom mode and keeps the value through later `Age` changes \
%[text] **Next:** [Example 09: Genetic Variants](matlab:edit('Example09_GeneticVariants.m')). The L-cone Ser180Ala polymorphism and the hybrid cone variants.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

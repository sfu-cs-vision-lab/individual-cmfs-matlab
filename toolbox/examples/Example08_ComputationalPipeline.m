%[text] # Example 08: Computational Pipeline
%[text] A cone fundamental is computed in four stages, which follow the light from the photopigment back out to the cornea:
%[text] 1. **Photopigment absorbance.** The absorbance of the visual pigment itself, set by the opsin protein. It is scaled so that its largest value is 1 at lambda-max. Pass `LogOutput=true` for base-10 logarithmic values.
%[text] 2. **Retinal absorptance.** The fraction of light the cone actually absorbs, which depends on the amount of pigment present.
%[text] 3. **Corneal quantal sensitivity.** Sensitivity measured at the cornea, in photon units, after the lens and macular pigment have absorbed part of the light.
%[text] 4. **Corneal energy sensitivity.** The same quantity in energy units. \
%[text] The `OutputFormat` property selects which stage the cone methods return.
%[text] **Time:** about 12 minutes.
exampleDefaults();
%%
%[text] ## Reading each stage
%[text] Setting `OutputFormat` to one of the four stage names makes `L`, `M`, `S` and `LMS` return that stage. A cone with an optical density of zero returns zero absorbance, which [Example 14](matlab:edit('Example14_Dichromacy.m')) covers.
obs = IndividualCMF();
wl = (390:1:700)';
obs_abs  = IndividualCMF(OutputFormat="absorbance");
obs_absp = IndividualCMF(OutputFormat="absorptance");
obs_q    = IndividualCMF(OutputFormat="quantal");
obs_e    = IndividualCMF(OutputFormat="energy");
absorbance  = obs_abs.L(wl);
absorptance = obs_absp.L(wl);
quantal     = obs_q.L(wl);
energy      = obs_e.L(wl);
%%
%[text] ## The four stages plotted
%[text] Each panel shows the L cone at the same wavelengths, one panel per stage.
%[text] The lower three panels are peak-normalized by the default `NormalizeOutput=true`, so each reaches 1.0 and the panels compare shape rather than scale.
%[text] The first panel is different. Absorbance ignores `NormalizeOutput` and keeps the scale of the template, which is why it peaks at 0.995 rather than at 1.0. That scale carries meaning. The templates are anchored so that absorbance is 1 at lambda-max, and it is that convention which makes `Lod`, `Mod` and `Sod` the peak axial optical density at the next stage. The 0.995 is the residual of the Fourier fit rather than a departure from the convention.
tiledlayout(4, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile
plot(wl, absorbance, 'r-')
ylabel('Absorbance')
title('Stage 1: Photopigment absorbance'); xlim([390 700])
nexttile
plot(wl, absorptance, 'r-')
ylabel('Absorptance')
title('Stage 2: Relative retinal absorptance'); xlim([390 700])
nexttile
plot(wl, quantal, 'r-')
ylabel('Sensitivity')
title('Stage 3: Corneal quantal sensitivity'); xlim([390 700])
nexttile
plot(wl, energy, 'r-')
xlabel('Wavelength (nm)'); ylabel('Sensitivity')
title('Stage 4: Corneal energy sensitivity (the default)'); xlim([390 700])
%%
%[text] ## The four stages overlaid
%[text] Dividing each curve by its own peak makes the change of shape between stages comparable. The lens and the macular pigment reduce the sensitivity at short wavelengths, and the conversion to energy units moves the peak to slightly longer wavelengths. The next two sections explain both.
tiledlayout(1, 1, 'TileSpacing', 'compact', 'Padding', 'compact'); nexttile
plot(wl, absorbance/max(absorbance),  'b-'); hold on
plot(wl, absorptance/max(absorptance), 'c-')
plot(wl, quantal/max(quantal),         'g-')
plot(wl, energy/max(energy),           'r-'); hold off
xlabel('Wavelength (nm)'); ylabel('Normalised value')
title('L cone at each pipeline stage, normalised')
legend('Absorbance', 'Absorptance', 'Quantal', 'Energy', 'Location', 'bestoutside')
grid on; xlim([390 700])
%%
%[text] ## From absorbance to absorptance
%[text] The fraction of light a cone absorbs follows the Beer-Lambert law applied to a layer of pigment of finite optical density:
%[text] $ \\text{absorptance}_{\\text{raw}} = 1 - 10^{-\\text{OD} \\cdot \\text{absorbance}} $
%[text] Setting `OutputFormat="absorptance"` returns a relative form of this, divided by $1 - 10^{-\\text{OD}}$ so that its peak is near 1. The raw fraction is available from `pipeline.PhotopigmentStage.absorptanceFromAbsorbance(..., Normalize=false)`, and the next section uses it.
%[text] The optical densities of the default observer are below.
table(obs.Lod, obs.Mod, obs.Sod, ...
      'VariableNames', {'L_OD', 'M_OD', 'S_OD'})
%%
%[text] ## The effect of optical density
%[text] The figure below evaluates the raw form at optical densities of 0.2, 0.5 and 1.0. Two things change together as the density increases. The peak rises, since more pigment absorbs more light. The curve also becomes wider, because near the peak the absorptance approaches its ceiling of $1 - 10^{-\\text{OD}}$ and cannot rise much further, while at wavelengths away from the peak it is still far from that ceiling and continues to grow. This widening is called self-screening.
%[text] The absorbance used here is the toolbox value, which is already close to a peak of 1. It is passed in as it stands rather than divided by its own peak, since that division would change what the optical density labels mean. The values are plotted as computed, without normalization, so that the change in peak height is visible.
abs_linear = absorbance;
od_values = [0.2, 0.5, 1.0];
odcol = lines(numel(od_values));
absp_first = pipeline.PhotopigmentStage.absorptanceFromAbsorbance(abs_linear, od_values(1), Normalize=false);
tiledlayout(1, 1, 'TileSpacing', 'compact', 'Padding', 'compact'); nexttile
plot(wl, absp_first, 'Color', odcol(1,:), ...
    'DisplayName', sprintf('OD = %.1f', od_values(1)))
hold on
for i = 2:numel(od_values)
    od = od_values(i);
    absp = pipeline.PhotopigmentStage.absorptanceFromAbsorbance(abs_linear, od, Normalize=false);
    plot(wl, absp, 'Color', odcol(i,:), ...
        'DisplayName', sprintf('OD = %.1f', od))
end
hold off
xlabel('Wavelength (nm)'); ylabel('Raw absorptance (fraction)')
title('Self-screening at three optical densities')
legend('Location', 'bestoutside'); xlim([450 650]); ylim([0 1])
%%
%[text] ## The lens and the macular pigment
%[text] The lens and the macular pigment absorb light before it reaches the cones. `getLensDensitySpectrum` returns the lens density directly, and `getMacularDensitySpectrum` returns the macular density. The fraction of light transmitted through both is $10^{-D}$, where $D$ is the sum of the two densities.
lens_density    = obs.getLensDensitySpectrum(wl);
macular_density = obs.getMacularDensitySpectrum(wl);
total_density   = lens_density + macular_density;
transmission     = 10 .^ (-total_density);
tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile
plot(wl, lens_density, 'b-'); hold on
plot(wl, macular_density, 'g-')
plot(wl, total_density, '-', 'Color', IndividualCMF.neutralColor()); hold off
xlabel('Wavelength (nm)'); ylabel('Optical Density')
title('Optical density of the lens and the macular pigment')
legend('Lens', 'Macular', 'Total', 'Location', 'bestoutside')
grid on; xlim([390 700])
nexttile
plot(wl, transmission * 100, '-', 'Color', IndividualCMF.neutralColor())
xlabel('Wavelength (nm)'); ylabel('Transmission (%)')
title('Fraction of light reaching the cones'); xlim([390 700])
%%
%[text] ## From quantal to energy units
%[text] The sensitivity in energy units is the sensitivity in quantal units multiplied by wavelength, as given in Equation 8 of Stockman and Rider (2023):
%[text] $ \\bar{l}_E(\\lambda) = \\alpha\\,\\lambda\\,\\bar{l}_Q(\\lambda) $
%[text] The energy of one photon is $E = hc/\\lambda$, so a photon at a long wavelength carries less energy than one at a short wavelength. A fixed amount of radiant energy therefore delivers more photons at longer wavelengths. Expressing the same photon-counting response per unit energy rather than per photon gives a larger value at longer wavelengths, which is why multiplying by wavelength moves the peak in that direction.
tiledlayout(1, 1, 'TileSpacing', 'compact', 'Padding', 'compact'); nexttile
plot(wl, quantal/max(quantal), 'b-'); hold on
plot(wl, energy/max(energy),   'r-'); hold off
xlabel('Wavelength (nm)'); ylabel('Normalised sensitivity')
title('Quantal and energy sensitivity compared')
legend('Quantal', 'Energy', 'Location', 'bestoutside')
grid on; xlim([390 700])
%%
%[text] ## The built-in diagnostic figure
%[text] `plotDiagnostics` draws the whole pipeline in a single call.
obs.plotDiagnostics(Wavelength=wl);
%%
%[text] ## Unnormalized values
%[text] `NormalizeOutput=false` returns the values as computed, without dividing by the peak. The peak of the unnormalized L cone is the number the default observer divides by.
obs_raw = IndividualCMF(NormalizeOutput=false, OutputFormat="energy");
table(max(obs.L(wl)), max(obs_raw.L(wl)), ...
      'VariableNames', {'L_normalized_peak', 'L_raw_peak'})
%%
%[text] ## Key takeaways
%[text] - The four stages are absorbance, absorptance, quantal sensitivity and energy sensitivity, in that order
%[text] - `OutputFormat` selects which stage `L`, `M`, `S` and `LMS` return. `RGB` is unaffected, since it always computes from normalized fundamentals in energy units
%[text] - A higher optical density widens the curve, by self-screening. The lens and the macular pigment reduce the sensitivity at short wavelengths. The conversion to energy units moves the peak to longer wavelengths
%[text] - Absorbance ignores `NormalizeOutput` and keeps the scale of its template, which is what gives `Lod`, `Mod` and `Sod` their meaning
%[text] - `obs.getLensDensitySpectrum(wl)` and `obs.getMacularDensitySpectrum(wl)` return the two filter spectra
%[text] - `obs.plotDiagnostics()` draws the whole pipeline in one call
%[text] - `NormalizeOutput=false` returns the values without dividing by the peak \
%[text] **Next:** [Example 09: Output Formats and Units](matlab:edit('Example09_OutputFormats.m')). Choosing between the `energy`, `quantal`, `absorptance` and `absorbance` outputs.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

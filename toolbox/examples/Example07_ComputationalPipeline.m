%[text] # Example 07: Computational Pipeline
%[text] Cone fundamentals are computed through a four-stage physiological pipeline that models light propagation through the eye:
%[text] 1. **Photopigment absorbance** (linear, 0-1) -- intrinsic absorbance of the visual pigment, determined by the opsin protein. Pass `LogOutput=true` if you want $\\log_{10}$ values.
%[text] 2. **Retinal absorptance** -- `OutputFormat="absorptance"` returns the *relative* retinal absorptance `(1 - 10^(-OD*A)) / (1 - 10^(-OD))`, which peaks near 1 by construction for both Stockman-Rider and Govardovskii templates. The raw physical fraction `1 - 10^(-OD*A)` (which peaks near `1 - 10^(-OD)` ~ 0.58 for typical OD) is available through `pipeline.PhotopigmentStage.absorptanceFromAbsorbance(..., Normalize=false)`.
%[text] 3. **Corneal quantal** (linear) -- sensitivity at the cornea, in photon units, after lens and macular filtering
%[text] 4. **Corneal energy** (linear) -- same as quantal, converted to energy units via E = hc/lambda \
%[text] Each stage is exposed via the `OutputFormat` property. 
%[text] **Time:** about 12 minutes.
exampleDefaults();
%%
%[text] ## Accessing the four stages
%[text] The cleanest way is to set `OutputFormat` to one of the four pipeline-stage names. The cone-method calls (`L`, `M`, `S`, `LMS`) then return that stage's values. Stage 1 (absorbance) collapses to zero when a cone is absent -- see [Example 13: Dichromacy](matlab:edit('Example13_Dichromacy.m')) for the dichromat case.
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
%[text] ## Visualizing the four stages
%[text] One panel per stage; each is the L-cone evaluated at the same wavelengths. Note the y-axis units differ -- only the *shape* is meaningful in this view.
tiledlayout(4, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile
plot(wl, absorbance, 'r-')
xlabel('Wavelength (nm)'); ylabel('Absorbance (linear)')
title('Stage 1: Photopigment absorbance'); xlim([390 700])
nexttile
plot(wl, absorptance, 'r-')
xlabel('Wavelength (nm)'); ylabel('Absorptance (fraction)')
title('Stage 2: Retinal absorptance'); xlim([390 700])
nexttile
plot(wl, quantal, 'r-')
xlabel('Wavelength (nm)'); ylabel('Relative Sensitivity')
title('Stage 3: Corneal quantal'); xlim([390 700])
nexttile
plot(wl, energy, 'r-')
xlabel('Wavelength (nm)'); ylabel('Relative Sensitivity')
title('Stage 4: Corneal energy (default)'); xlim([390 700])
%%
%[text] ## Overlaid normalized comparison
%[text] Normalising each curve to its own peak makes the *shape changes* between stages comparable. Pre-receptoral filtering progressively erodes short-wavelength sensitivity; energy conversion shifts the peak slightly toward **longer** wavelengths (multiplying by lambda -- see the next section).
tiledlayout(1, 1, 'TileSpacing', 'compact', 'Padding', 'compact'); nexttile
plot(wl, absorbance/max(absorbance),  'b-'); hold on
plot(wl, absorptance/max(absorptance), 'c-')
plot(wl, quantal/max(quantal),         'g-')
plot(wl, energy/max(energy),           'r-'); hold off
xlabel('Wavelength (nm)'); ylabel('Normalised value')
title('L-cone -- pipeline stages, normalised')
legend('Absorbance', 'Absorptance', 'Quantal', 'Energy', 'Location', 'bestoutside')
grid on; xlim([390 700])
%%
%[text] ## Self-screening -- absorbance -> absorptance
%[text] Self-screening follows the Beer-Lambert law applied to a finite optical density:
%[text] $ \\text{absorptance}_{\\text{raw}} = 1 - 10^{-\\text{OD} \\cdot \\text{absorbance}} $
%[text] The toolbox's high-level `OutputFormat="absorptance"` returns the *relative* form (divided by `1 - 10^(-OD)` so the peak is near 1). The block below uses the raw form to illustrate how shape varies with OD; the toolbox API returns its rescaled version.
%[text] Higher OD -> broader, more saturated curves; the L-cone's actual OD is below.
table(obs.Lod, obs.Mod, obs.Sod, ...
      'VariableNames', {'L_OD', 'M_OD', 'S_OD'})
%%
%[text] ## Self-screening at different optical densities
%[text] Sweeping OD from 0.2 to 1.0 in the raw form $1 - 10^{-\\text{OD}\\cdot A}$ shows two coupled effects: as OD increases, the peak amplitude rises (more pigment absorbs more light) and the curve broadens (the tails saturate sooner). The toolbox's `absorbance` is already linear in [0, 1], so we just normalise it to its peak before sweeping OD. Raw values plotted -- not renormalised -- so the amplitude story is visible.
abs_linear = absorbance / max(absorbance);
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
title('Self-screening -- effect of optical density')
legend('Location', 'bestoutside'); xlim([450 650]); ylim([0 1])
%%
%[text] ## Pre-receptoral filtering -- lens + macular
%[text] The lens and the macular pigment absorb light *before* it reaches the cones. The toolbox exposes the lens density spectrum directly; the macular template comes from `PreReceptoralFilter.macularTemplate`. Combined transmission = 10^(-density).
lens_density    = obs.getLensDensitySpectrum(wl);
macular_density = obs.getMacularDensitySpectrum(wl);
total_density   = lens_density + macular_density;
transmission     = 10 .^ (-total_density);
tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile
plot(wl, lens_density, 'b-'); hold on
plot(wl, macular_density, 'g-')
plot(wl, total_density, 'k-'); hold off
xlabel('Wavelength (nm)'); ylabel('Optical Density')
title('Pre-receptoral optical density')
legend('Lens', 'Macular', 'Total', 'Location', 'bestoutside')
grid on; xlim([390 700])
nexttile
plot(wl, transmission * 100, 'k-')
xlabel('Wavelength (nm)'); ylabel('Transmission (%)')
title('Pre-receptoral transmission'); xlim([390 700])
%%
%[text] ## Energy conversion -- quantal -> energy
%[text] The energy-unit sensitivity is the quantal sensitivity multiplied by lambda (S&R 2023, Eq. 8): $ \\bar{l}_E(\\lambda) = \\alpha\\,\\lambda\\,\\bar{l}_Q(\\lambda) $. Multiplying by lambda weights longer wavelengths more heavily, so the energy curve's peak sits slightly to the **right** (longer wavelengths) of the quantal curve. The reasoning is "an energy detector needs more sensitivity per photon at longer lambda to register the same energy" -- equivalently, the per-photon energy E = hc/lambda is *lower* at longer wavelengths.
tiledlayout(1, 1, 'TileSpacing', 'compact', 'Padding', 'compact'); nexttile
plot(wl, quantal/max(quantal), 'b-'); hold on
plot(wl, energy/max(energy),   'r-'); hold off
xlabel('Wavelength (nm)'); ylabel('Normalised sensitivity')
title('Quantal vs energy -- wavelength factor')
legend('Quantal', 'Energy', 'Location', 'bestoutside')
grid on; xlim([390 700])
%%
%[text] ## Built-in `plotDiagnostics`
%[text] For a turn-key pipeline visualization the observer has a `plotDiagnostics` method that produces the standard pipeline figure in one call.
obs.plotDiagnostics(Wavelength=wl);
%%
%[text] ## Unnormalized output via `NormalizeOutput=false`
%[text] To see *raw* pipeline values (the actual physical quantities, not peak-normalised), use `NormalizeOutput=false`. The peak of the raw L-cone is the divisor that the default-normalised observer is dividing by.
obs_raw = IndividualCMF(NormalizeOutput=false, OutputFormat="energy");
table(max(obs.L(wl)), max(obs_raw.L(wl)), ...
      'VariableNames', {'L_normalized_peak', 'L_raw_peak'})
%%
%[text] ## Key takeaways
%[text] - Four pipeline stages: `absorbance` -> `absorptance` -> `quantal` -> `energy`
%[text] - `OutputFormat` selects the stage returned by `L/M/S/LMS/RGB`
%[text] - Self-screening (OD) broadens the curve; pre-receptoral filtering attenuates short wavelengths; energy conversion shifts the peak slightly to the **right** (longer wavelengths) because multiplying by lambda weights longer wavelengths more
%[text] - `obs.getLensDensitySpectrum(wl)` and `obs.getMacularDensitySpectrum(wl)` expose the filter spectra
%[text] - `obs.plotDiagnostics()` gives a turn-key pipeline figure
%[text] - `NormalizeOutput=false` exposes raw pipeline values \
%[text] **Next:** [Example 08: Output Formats and Units](matlab:edit('Example08_OutputFormats.m')) -- choosing between `energy`, `quantal`, `absorptance`, and `absorbance` outputs.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

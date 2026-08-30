%[text] # Example 09: Output Formats and Units
%[text] A cone sensitivity can be reported at any of the four stages described in [Example 08](matlab:edit('Example08_ComputationalPipeline.m')). The `OutputFormat` property chooses between them.
%[text:table]
%[text] | Format | Stage | Units |
%[text] | --- | --- | --- |
%[text] | `"absorbance"` | Absorbance of the photopigment itself | Unitless. The peak is near 1 by the convention that absorbance is 1 at lambda-max. Set `LogOutput=true` for base-10 logarithmic values |
%[text] | `"absorptance"` | The fraction absorbed, after self-screening | Unitless, peak near 1. The raw fraction is available from `pipeline.PhotopigmentStage.absorptanceFromAbsorbance` |
%[text] | `"quantal"` | Sensitivity at the cornea in photon units | Unitless relative sensitivity |
%[text] | `"energy"`, the default | Sensitivity at the cornea in energy units | Unitless relative sensitivity |
%[text:table]
%[text] This example is about the property that selects between the stages. [Example 08](matlab:edit('Example08_ComputationalPipeline.m')) explains what happens at each one.
%[text] **Time:** about 12 minutes.
exampleDefaults();
%%
%[text] ## Setting the format
%[text] `OutputFormat` can be passed to the constructor or assigned afterwards.
obs_dynamic = IndividualCMF();
fmt_before = string(obs_dynamic.OutputFormat);
obs_dynamic.OutputFormat = "quantal";
fmt_after = string(obs_dynamic.OutputFormat);
table(fmt_before, fmt_after, 'VariableNames', {'Default', 'AfterAssignment'})
%%
%[text] ## Setting the format for one call only
%[text] `OutputFormat`, `LogOutput` and `NormalizeOutput` can also be passed directly to `LMS` and the single-cone methods. Used this way they apply to that call alone and the observer is left unchanged, as the last column of the table shows.
obs_one_shot = IndividualCMF();
L_energy        = obs_one_shot.LMS(555);
L_quantal       = obs_one_shot.LMS(555, OutputFormat="quantal");
L_absorbance    = obs_one_shot.LMS(555, OutputFormat="absorbance");
fmt_after_calls = string(obs_one_shot.OutputFormat);
table(L_energy(1), L_quantal(1), L_absorbance(1), fmt_after_calls, ...
      'VariableNames', {'Energy', 'Quantal', 'Absorbance_linear', 'ObserverFormat'})
%%
%[text] ## The four formats plotted
%[text] The panels below show all three cones in each format, drawn with `plotAbsorbance`, `plotAbsorptance` and `plotLMS`. The last of these plots whichever format the observer is currently set to.
%[text] The first two panels are similar. Self-screening widens the L curve from 104 to 121 nm measured at half its maximum, and moves no peak.
%[text] The change between the second and third panels is larger, because that is where the lens and the macular pigment act. The S-cone peak moves from 417 to 444 nm and the sensitivity at the shortest wavelengths is much reduced.
%[text] Absorbance is scaled so that it equals 1 at lambda-max, which puts its peak near 1 but not exactly there. It is 0.9949 for the Stockman and Rider L template, and between 1.0009 and 1.0014 for the three Govardovskii A1 cones. The A2 variant sits further out, with an S-cone peak of 1.0350. Pass `LogOutput=true`, or `Log=true` to `plotAbsorbance`, for base-10 logarithmic values.
wl = (390:1:700)';
obs_abs  = IndividualCMF(OutputFormat="absorbance");
obs_absp = IndividualCMF(OutputFormat="absorptance");
obs_q    = IndividualCMF(OutputFormat="quantal");
obs_e    = IndividualCMF(OutputFormat="energy");
f = gcf;
f.Position(3:4) = [800 900];
tiledlayout(f, 4, 1, 'TileSpacing', 'loose', 'Padding', 'compact');
obs_abs.plotAbsorbance(Title="Absorbance", Wavelength=wl, Parent=nexttile);
xlim([390 700]); ylim([0 1.1])
obs_absp.plotAbsorptance(Title="Absorptance, after self-screening", Wavelength=wl, Parent=nexttile);
xlim([390 700]); ylim([0 1.1])
obs_q.plotLMS(Title="Quantal sensitivity at the cornea", Wavelength=wl, Parent=nexttile);
xlim([390 700]); ylim([0 1.1])
obs_e.plotLMS(Title="Energy sensitivity at the cornea (the default)", Wavelength=wl, Parent=nexttile);
xlim([390 700]); ylim([0 1.1])
%%
%[text] ## What `"absorptance"` returns
%[text] `OutputFormat="absorptance"` returns the relative absorptance, $ (1 - 10^{-\\mathrm{OD}\\cdot A}) / (1 - 10^{-\\mathrm{OD}}) $, which has a peak near 1.0 by construction. This is not the raw Beer-Lambert fraction $ 1 - 10^{-\\mathrm{OD}\\cdot A} $, which for the L cone at an optical density of 0.38 peaks near 0.58 instead. The raw fraction is returned by `pipeline.PhotopigmentStage.absorptanceFromAbsorbance(linAbs, od, Normalize=false)`.
%%
%[text] ## Quantal and energy compared
%[text] The two differ by a factor of wavelength. The sensitivity in energy units is wavelength times the sensitivity in quantal units, from Equation 8 of Stockman and Rider (2023), up to a constant that normalization removes. Multiplying by wavelength moves each peak to a longer wavelength. The direction is the same for all three cones but the size is not, since it depends on how steeply each cone falls away either side of its peak. The L peak moves 5.68 nm, the M peak 3.50 nm and the S peak 1.07 nm.
%[text] `compareTo` draws both observers. The legend is relabelled after the call so that the two formats can be told apart.
tiledlayout(1, 1);
p_qe = obs_q.compareTo(obs_e, Title="Quantal (solid) vs Energy (dashed)", Wavelength=wl, Parent=nexttile);
xlim([520 620]); ylim([0.9 1.02])
legend(p_qe, {'L (q)', 'M (q)', 'S (q)', 'L (e)', 'M (e)', 'S (e)'}, ...
       'Location', 'bestoutside', 'NumColumns', 2);
%%
%[text] ## One wavelength through all four stages
%[text] At a single wavelength the four formats give very different numbers. They are not four normalizations of one quantity. They are four different stages of the calculation.
test_wl = 555;
table(obs_abs.L(test_wl), ...
      obs_absp.L(test_wl, NormalizeOutput=false), ...
      obs_q.L(test_wl, NormalizeOutput=false), ...
      obs_e.L(test_wl, NormalizeOutput=false), ...
      'VariableNames', {'Absorbance_linear', 'Absorptance_relative', 'Quantal', 'Energy'})
%[text] These values are unnormalized. `NormalizeOutput=false` is passed on each call, and absorbance is unnormalized in any case. The relation between the last two columns can therefore be checked directly. The energy value at 555 nm is the quantal value multiplied by 555, since the constant of proportionality is 1 in this implementation. Under the default normalization each column would be divided by its own peak and the relation would no longer hold.
%[text] Reading across the row, absorbance is the shape of the photopigment, absorptance adds self-screening, quantal adds the lens and the macular pigment, and energy multiplies by wavelength.
%%
%[text] ## Which format to use
%[text] - **`absorbance`** for work on photopigment properties, for comparison with microspectrophotometry, and for developing template models.
%[text] - **`absorptance`** for modelling the response of the photoreceptor at the retina, and for work on self-screening.
%[text] - **`quantal`** for calculations in photon units, for quantum efficiency, and for stimuli specified as photons per unit area.
%[text] - **`energy`**, the default, for ordinary colorimetry, for CIE colour matching, for displays and lighting, and for stimuli specified in watts or joules. \
%%
%[text] ## The two output controls
%[text] `NormalizeOutput` and `LogOutput` act after the format has been chosen, and act independently of each other.
%[text] - `NormalizeOutput`, true by default, divides each curve by its peak so that the maximum is 1.0. Set it to false for the values as computed.
%[text] - `LogOutput`, false by default, takes the base-10 logarithm after normalization. It makes the low sensitivities at the ends of the spectrum readable. \
%[text] `LogOutput` applies to every format. `NormalizeOutput` applies to three of the four. It is ignored for `absorbance`, which keeps the scale of its template so that absorbance is 1 at lambda-max. That convention is what makes `Lod`, `Mod` and `Sod` the peak axial optical density in the self-screening step. The other three formats are relative sensitivities, where dividing by a peak is meaningful. pycone behaves the same way.
obs_unnorm = IndividualCMF(NormalizeOutput=false, OutputFormat="energy");
table(max(obs_unnorm.L(wl)), max(obs_unnorm.M(wl)), max(obs_unnorm.S(wl)), ...
      'VariableNames', {'L_peak_raw', 'M_peak_raw', 'S_peak_raw'})
%%
%[text] ## One cone on a logarithmic scale
%[text] `plotLMS(Cones="L", Log=true)` plots the L cone alone on a base-10 logarithmic axis, where the low sensitivities at each end of the spectrum are visible.
tiledlayout(1, 1);
obs_e.plotLMS(Cones="L", Log=true, Title="L-cone energy sensitivity, logarithmic scale", Wavelength=wl, Parent=nexttile);
xlim([390 700]); ylim([-4 0.25])
%%
%[text] ## Key takeaways
%[text] - The four formats are `absorbance`, `absorptance`, `quantal` and `energy`
%[text] - `energy` is the default and the right choice for colorimetry
%[text] - Energy sensitivity is quantal sensitivity multiplied by wavelength, because a photon at a longer wavelength carries less energy
%[text] - Set `OutputFormat` in the constructor, assign it later, or pass it to a single call as `obs.LMS(wl, OutputFormat=...)`
%[text] - `OutputFormat` affects `L`, `M`, `S` and `LMS` only. `RGB`, `XYZ` and the chromaticity methods always compute from normalized fundamentals in energy units, so changing the format does not alter them
%[text] - `NormalizeOutput` and `LogOutput` act independently, except that `NormalizeOutput` is ignored for `absorbance` \
%[text] **Next:** [Example 10: RGB Color Matching Functions](matlab:edit('Example10_RGBColorMatching.m')). RGB colour matching functions and how to choose the primaries.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

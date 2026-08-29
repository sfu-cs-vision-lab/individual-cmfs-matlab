%[text] # Example 03: How an Observer Is Assembled
%[text] The previous two examples treated `IndividualCMF` as a black box: ask for a standard observer, get cone fundamentals. This example opens the box. It is the map you need before the individualization examples that follow, because almost every property you will set from here on is a choice about one of the three components described below.
%[text] A cone fundamental is built from three physical components stacked in front of a photoreceptor:
%[text] - the **lens**, which absorbs short-wavelength light and yellows with age
%[text] - the **macular pigment**, a yellow filter over the fovea that thins with retinal eccentricity
%[text] - the **photopigment** itself, whose absorbance spectrum sets which wavelengths the cone can catch \
%[text] Each component contributes in two separable ways, and the toolbox gives you a separate control for each. That two-controls-per-component structure is the single most useful thing to understand about the API.
%[text] **Time:** about 10 minutes.
exampleDefaults();
%%
%[text] ## The three components
%[text] Each component is a spectrum. The two pre-receptoral filters are optical densities -- light is attenuated by $10^{-D(\\lambda)}$ -- and the photopigment is an absorbance spectrum normalized to 1.0 at its own peak. The observer's cone fundamental is what survives all three.
obs = IndividualCMF();
wl = (380:1:780)';
tiledlayout(3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
obs.plotLens(Parent=nexttile, Wavelength=wl, Title="Lens density (a filter you look through)");
obs.plotMacular(Parent=nexttile, Wavelength=wl, Title="Macular pigment density (a second filter)");
obs.plotAbsorbance(Parent=nexttile, Wavelength=wl, Title="Photopigment absorbance (what the cone can catch)");
%%
%[text] ## Two controls per component: shape and magnitude
%[text] For every component the toolbox separates **what the spectrum looks like** from **how much of it there is**:
%[text] - A **model** sets the spectral *shape*: `LensModel`, `MacularModel`, `PhotopigmentModel`. Changing one swaps in a different published curve.
%[text] - A **density algorithm** sets the scalar *magnitude* that shape is scaled to: `LensDensityAlgorithm`, `MacularDensityAlgorithm`, `PhotopigmentDensityAlgorithm`. Changing one changes how the scalar is decided, not what the curve looks like. \
%[text] The two are independent, and they produce visibly different kinds of change. Below, the same photopigment optical density (0.38) under two different template models, against the same model under two different densities.
obsGov = IndividualCMF(PhotopigmentModel="Govardovskii2000");
obs2deg = IndividualCMF(FieldSize=2);
table([obs.Lod; obsGov.Lod; obs2deg.Lod], ...
      [0; max(abs(obs.L(wl) - obsGov.L(wl))); max(abs(obs.L(wl) - obs2deg.L(wl)))], ...
      'VariableNames', {'L_OD', 'MaxAbsDiff_vs_default'}, ...
      'RowNames', {'Default (10 deg)', 'Different model, same OD', 'Same model, different OD'})
%[text] Both routes move the L cone by a comparable amount, but for different reasons: the model swap changes the curve's shape at fixed density, while the field-size change rescales the density at fixed shape.
%%
%[text] ## Where the CIE 170 tables come in
%[text] CIE 170-1:2006 tabulates macular and photopigment densities at exactly two field sizes, 2 deg and 10 deg. It does not tabulate anything in between. The literature supplies continuous formulas that do -- Moreland & Alexander for macular pigment, Pokorny, Smith & Lutze for photopigment density -- and those formulas were fitted to pass through the tabulated points.
%[text] So the `CIE170` algorithm is not a different function from the formulas. It **is** the formula, with the two tabulated values substituted back in where the standard defines them. Everywhere else the two modes are bit-identical.
fieldSizes = [1 2 4 10 15]';
macCIE = zeros(size(fieldSizes)); macFormula = zeros(size(fieldSizes));
lodCIE = zeros(size(fieldSizes)); lodFormula = zeros(size(fieldSizes));
for k = 1:numel(fieldSizes)
    tabulated = IndividualCMF(FieldSize=fieldSizes(k), ...
        MacularDensityAlgorithm="CIE170", PhotopigmentDensityAlgorithm="CIE170");
    formula = IndividualCMF(FieldSize=fieldSizes(k), ...
        MacularDensityAlgorithm="MorelandAlexander", PhotopigmentDensityAlgorithm="PokornySmith");
    macCIE(k) = tabulated.MacularDensity; macFormula(k) = formula.MacularDensity;
    lodCIE(k) = tabulated.Lod; lodFormula(k) = formula.Lod;
end
table(macCIE, macFormula, macCIE - macFormula, lodCIE - lodFormula, ...
      'VariableNames', {'Macular_CIE170', 'Macular_formula', 'Macular_diff', 'Lod_diff'}, ...
      'RowNames', compose('%g deg', fieldSizes))
%[text] The difference column is exactly zero at 1, 4 and 15 deg and non-zero only at 2 and 10 deg. That is the whole distinction: the two modes disagree only where the standard has a table entry to disagree with, and the disagreement is the small residual of the published fit.
%[text] This answers the question the field-size example raises. `CIE170` is not restricted to 2 and 10 deg -- it handles any field size, by falling through to the same continuous formulas. Selecting it means "use the tabulated value wherever the standard defines one", not "only standard field sizes allowed".
%%
%[text] ## Why you would change a model
%[text] Model choice is a claim about which published curve describes your observer. Three reasons come up in practice:
%[text] - **Age work.** The default `LensModel="StockmanRider2023"` is age-flat: its density does not respond to `Age` at all. If you are studying aging you must switch to `Pokorny1987` or `VanDeKraats2007`.
%[text] - **Wavelength coverage.** Models carry validity ranges. `Pokorny1987` holds its 400 nm value flat below 400 nm; `VanDeKraats2007` is fitted from 300 nm.
%[text] - **Non-human or comparative work.** `PhotopigmentModel="Govardovskii2000"` provides the A1/A2 visual-pigment templates. \
%[text] The age-flat default is the trap worth seeing directly, because it fails silently -- you set `Age` and nothing moves.
obsOld = IndividualCMF(Age=70);
obsOldVdK = IndividualCMF(Age=70, LensModel="VanDeKraats2007");
table([obs.Age; obsOld.Age; obsOldVdK.Age], ...
      [string(obs.LensModel); string(obsOld.LensModel); string(obsOldVdK.LensModel)], ...
      [obs.LensDensity; obsOld.LensDensity; obsOldVdK.LensDensity], ...
      'VariableNames', {'Age', 'LensModel', 'LensDensity'}, ...
      'RowNames', {'Default age 32', 'Age 70, default model', 'Age 70, VanDeKraats2007'})
%[text] Age 70 under the default model returns the age-32 density unchanged. See [Example 05](matlab:edit('Example05_AgingEffects.m')) for the three lens models compared properly.
%%
%[text] ## Why you would change a density algorithm
%[text] Algorithm choice is a claim about where the scalar comes from. `Custom` is the important one: it means "I am supplying this number myself, stop deriving it". Assigning a density directly engages it automatically.
%[text] That auto-engagement is a convenience with a sharp edge. Once `Custom` is engaged, the value is pinned against every later change that would otherwise have recomputed it.
obsPinned = IndividualCMF();
algoBefore = string(obsPinned.LensDensityAlgorithm);
obsPinned.LensDensity = 1.7;
algoAfter = string(obsPinned.LensDensityAlgorithm);
obsPinned.LensModel = "VanDeKraats2007";
obsPinned.Age = 70;
table([algoBefore; algoAfter; string(obsPinned.LensDensityAlgorithm)], ...
      [obs.LensDensity; 1.7; obsPinned.LensDensity], ...
      'VariableNames', {'LensDensityAlgorithm', 'LensDensity'}, ...
      'RowNames', {'Before assignment', 'After assigning 1.7', 'After LensModel + Age=70'})
%[text] The switch to an age-dependent lens model and an age of 70 both had no effect, because the density was already pinned. This is intended -- an explicit value should outrank a derived one -- but it is worth meeting here rather than discovering it in the middle of an age sweep. [Example 15](matlab:edit('Example15_AdvancedCustomization.m')) covers the full precedence rules.
%%
%[text] ## Putting it together
%[text] The components combine in a fixed order. Light passes the lens, then the macular pigment, then meets the photopigment; what the cone absorbs is converted to a sensitivity and finally normalized. `plotDiagnostics` shows the assembled observer's parts in one view.
obs.plotDiagnostics();
%[text] Every remaining example in this series changes one of the boxes above. The physiological examples change *which* model or density applies; the pipeline and output examples change how the result is reported. [Example 08](matlab:edit('Example08_ComputationalPipeline.m')) walks the same assembly stage by stage using only public calls.
%%
%[text] ## Key takeaways
%[text] - Three components stack to make a cone fundamental: lens, macular pigment, photopigment
%[text] - Each has **two** independent controls -- a `...Model` for spectral shape, a `...DensityAlgorithm` for the scalar magnitude that shape is scaled to
%[text] - `CIE170` is not a 2-and-10-deg-only mode. It handles any field size by falling through to the same continuous formulas the standard's tables were fitted to, and differs from them *only* at exactly 2 and 10 deg
%[text] - Change a **model** when you need a different published curve: age-dependent lens work, sub-400 nm coverage, or non-human pigments
%[text] - Change a **density algorithm** when you want to supply the scalar yourself. Assigning any density engages `Custom` for that component and pins the value against later recomputation
%[text] - The default `LensModel="StockmanRider2023"` is age-flat; setting `Age` alone will not move it \
%[text] **Next:** [Example 04: Field Size Effects](matlab:edit('Example04_FieldSizeEffects.m')) -- the first component varied on its own: macular pigment and photopigment density against field size.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

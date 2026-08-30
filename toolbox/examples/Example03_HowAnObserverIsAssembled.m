%[text] # Example 03: How an Observer Is Assembled
%[text] The first two examples used `IndividualCMF` without saying much about what it does internally. This example describes the parts an observer is built from, because almost every property set in the later examples adjusts one of them.
%[text] A cone fundamental describes the sensitivity of a cone measured at the cornea, so it accounts for everything the light passes through on the way in. Three components matter:
%[text] - the **lens**, which absorbs short-wavelength light and absorbs more of it as a person ages
%[text] - the **macular pigment**, a yellow filter over the fovea that becomes thinner further from the fovea
%[text] - the **photopigment** in the cone itself, whose absorbance spectrum determines which wavelengths that cone can absorb \
%[text] Each component has two separate controls in the toolbox. Understanding that division makes the rest of the API easier to follow.
%[text] **Time:** about 10 minutes.
exampleDefaults();
%%
%[text] ## The three components
%[text] Each component is a spectrum, and the toolbox can plot each one directly.
%[text] The lens and the macular pigment are optical densities. An optical density of $D$ at some wavelength means a fraction $10^{-D}$ of the light at that wavelength gets through. A density of 0 is perfectly transparent. The macular density of 0.35 at 460 nm in the 2 deg standard observer therefore passes 44.7% of the light at that wavelength.
%[text] The photopigment is an absorbance spectrum, anchored so that its value is 1 at the wavelength of peak absorbance. That wavelength is called lambda-max. The anchoring is a convention that the fitted templates approximate rather than meet exactly, which puts the measured L peak at 0.9949.
obs = IndividualCMF();
wl = (380:1:780)';
tiledlayout(3, 1, 'TileSpacing', 'loose', 'Padding', 'compact');
obs.plotLens(Parent=nexttile, Wavelength=wl, Title="Lens optical density");
obs.plotMacular(Parent=nexttile, Wavelength=wl, Title="Macular pigment optical density");
obs.plotAbsorbance(Parent=nexttile, Wavelength=wl, Title="Photopigment absorbance");
%%
%[text] ## Two controls per component
%[text] For each component the toolbox separates the shape of the spectrum from its size:
%[text] - A **model** sets the shape. The three properties are `LensModel`, `MacularModel` and `PhotopigmentModel`. Changing one selects a different published curve.
%[text] - A **density algorithm** sets the single number that the shape is scaled to. The three properties are `LensDensityAlgorithm`, `MacularDensityAlgorithm` and `PhotopigmentDensityAlgorithm`. Changing one alters how that number is arrived at, not the shape it scales. \
%[text] The table below changes each in turn and reports how far the L cone moves. Changing the photopigment model alters the shape of the absorbance spectrum while the optical density stays at 0.38. Changing the field size from 10 deg to 2 deg raises the optical density to 0.50 while the model stays the same. Both produce a difference of similar size, for different reasons.
obsGov = IndividualCMF(PhotopigmentModel="Govardovskii2000");
obs2deg = IndividualCMF(FieldSize=2);
table([obs.Lod; obsGov.Lod; obs2deg.Lod], ...
      [0; max(abs(obs.L(wl) - obsGov.L(wl))); max(abs(obs.L(wl) - obs2deg.L(wl)))], ...
      'VariableNames', {'L_OD', 'MaxAbsDiff_vs_default'}, ...
      'RowNames', {'Default (10 deg)', 'Different model, same OD', 'Same model, different OD'})
%%
%[text] ## How the CIE 170 tables fit in
%[text] CIE 170-1:2006 tabulates macular and photopigment densities at two field sizes only, 2 deg and 10 deg. It gives no values in between. Two published formulae supply the missing values as continuous functions of field size, one from Moreland and Alexander for macular pigment and one from Pokorny, Smith and Lutze for photopigment density. Both formulae were fitted so that they pass through the tabulated points.
%[text] The `CIE170` algorithm is therefore not a different calculation from the formulae. It uses the same formulae, and substitutes the tabulated value at the two field sizes where the standard defines one.
%[text] The table below computes both densities at five field sizes under each setting and reports the difference.
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
%[text] The two settings agree exactly at 1, 4 and 15 deg. They differ only at 2 and 10 deg, and there only by the small residual left over from fitting the formulae to the tabulated values.
%[text] This answers a question the next example raises. `CIE170` is not restricted to 2 and 10 deg. It accepts any field size and uses the published formulae to do so. Selecting it means using the tabulated value wherever the standard provides one.
%%
%[text] ## When to change a model
%[text] Changing a model means choosing a different published description of that component. Three situations call for it:
%[text] - **Studying age.** The default `LensModel="StockmanRider2023"` does not depend on age at all. Age work requires `Pokorny1987` or `VanDeKraats2007`.
%[text] - **Working outside the usual range.** Each model states the wavelengths it was fitted over. `Pokorny1987` returns no value below 400 nm, so `getLensDensitySpectrum` gives `NaN` and the cone sensitivities are zero there. `VanDeKraats2007` was fitted from 300 nm and covers that range.
%[text] - **Working with non-human pigments.** `PhotopigmentModel="Govardovskii2000"` provides the A1 and A2 visual pigment templates used in comparative work. \
%[text] The first of these is easy to miss, because setting `Age` on the default observer produces no change and no warning.
obsOld = IndividualCMF(Age=70);
obsOldVdK = IndividualCMF(Age=70, LensModel="VanDeKraats2007");
table([obs.Age; obsOld.Age; obsOldVdK.Age], ...
      [string(obs.LensModel); string(obsOld.LensModel); string(obsOldVdK.LensModel)], ...
      [obs.LensDensity; obsOld.LensDensity; obsOldVdK.LensDensity], ...
      'VariableNames', {'Age', 'LensModel', 'LensDensity'}, ...
      'RowNames', {'Default age 32', 'Age 70, default model', 'Age 70, VanDeKraats2007'})
%[text] At age 70 the default model returns the same lens density as at age 32. The `VanDeKraats2007` model returns 2.8084. [Example 05](matlab:edit('Example05_AgingEffects.m')) compares the three lens models properly.
%%
%[text] ## Directly specified densities
%[text] The density algorithms determine how each density is obtained. `CIE170` and the named formulae compute it from age and field size. `Custom` takes it as given.
%[text] Assigning a value to `LensDensity`, `MacularDensity`, `Lod`, `Mod` or `Sod` normally selects `Custom` for the corresponding component. A density specified this way is then held constant, since the computation that would otherwise supply it is no longer performed. Later changes to `Age`, `FieldSize` or the associated model leave it unaltered.
%[text] Assigning a cone or macular density that equals the tabulated CIE value is the exception. `Sod = 0.30` on a 10 deg observer leaves the algorithm at `CIE170`, since the assignment asks for the value the standard already specifies. [Example 15](matlab:edit('Example15_AdvancedCustomization.m')) gives the full rule.
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
%[text] The lens density stays at 1.7 after the model is changed to `VanDeKraats2007` and the age to 70, a combination that would otherwise give 2.8084. This is intended, since a directly specified density describes a particular observer and should not be replaced by a value computed for the mean. No warning accompanies the change, so an age series built from such an observer will show no variation in lens density. [Example 15](matlab:edit('Example15_AdvancedCustomization.m')) gives the full precedence rules.
%%
%[text] ## Putting it together
%[text] The components act in a fixed order. Light passes through the lens, then through the macular pigment, and what remains is absorbed by the photopigment. The absorbed light is converted to a sensitivity and then normalized. `plotDiagnostics` shows these parts for the assembled observer.
obs.plotDiagnostics();
%[text] Each of the remaining examples changes one of these parts. The physiological examples select a different model or density. The pipeline and output examples change how the result is reported. [Example 08](matlab:edit('Example08_ComputationalPipeline.m')) works through the same assembly one stage at a time using only public methods.
%%
%[text] ## Key takeaways
%[text] - Three components combine to give a cone fundamental: the lens, the macular pigment and the photopigment
%[text] - Each has two controls. A `...Model` property sets the shape of the spectrum, and a `...DensityAlgorithm` property sets the number that shape is scaled to
%[text] - `CIE170` accepts any field size. It uses the same published formulae as the named alternatives and substitutes the tabulated value at 2 and 10 deg, which are the only field sizes where the two settings differ
%[text] - Change a model when a different published curve is needed, for age work, for wavelengths outside the fitted range, or for non-human pigments
%[text] - Assigning a density selects `Custom` for that component and holds the value constant against later changes, unless the value assigned is the one the CIE table already specifies
%[text] - The default `LensModel="StockmanRider2023"` does not depend on age, so setting `Age` alone changes nothing \
%[text] **Next:** [Example 04: Field Size Effects](matlab:edit('Example04_FieldSizeEffects.m')). Macular pigment and photopigment density as functions of field size.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

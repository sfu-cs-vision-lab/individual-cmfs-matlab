%[text] # Example 02: CIE 2006 Standard Observers
%[text] **CIE 170-1:2006** / **CIE 170-2:2015** define the physiologically-based cone fundamentals used here, a physiologically grounded alternative to the older CIE 1931 and 1964 colorimetric functions (which CIE 015 still standardizes and industrial colorimetry still runs on). This example covers the 2 deg and 10 deg standard observers, when to use each, and how `Type` / `StandardObserver` track standards compliance.
%[text] **Time:** about 10 minutes.
exampleDefaults();
%%
%[text] ## The two standard observers
%[text] CIE 2006 defines two observers reflecting different viewing conditions:
%[text] - **2 deg (foveal)** -- small stimuli, central vision, higher macular pigment, higher photopigment optical density
%[text] - **10 deg (large-field)** -- larger stimuli, still centrally fixated but extending to 5 deg eccentricity, lower macular pigment, lower photopigment optical density \
%[text] Both are defined at **age 32**, the approximate mean age of the observer population the fundamentals were derived from.
%[text] Two pigment mechanisms set these numbers. **Macular pigment** is a yellow filter over the fovea that absorbs roughly 400-530 nm light before it reaches the cones; it thins with eccentricity, so the 10 deg observer sees less of it. **Photopigment optical density** is how much pigment sits in each cone's outer segment: the segments shorten with eccentricity, and a lower density gives a narrower sensitivity curve through reduced self-screening.
obs2 = IndividualCMF(StandardObserver=2);
obs10 = IndividualCMF(StandardObserver=10);
table([obs2.MacularDensity; obs10.MacularDensity], ...
      [obs2.Lod; obs10.Lod], ...
      [obs2.Mod; obs10.Mod], ...
      [obs2.Sod; obs10.Sod], ...
      [string(obs2.Type); string(obs10.Type)], ...
      'VariableNames', {'MacularDensity_460nm', 'L_OD', 'M_OD', 'S_OD', 'Type'}, ...
      'RowNames', {'2-degree', '10-degree'})
%%
%[text] ## Visual comparison
%[text] Stacked plot of the two standard observers' cone fundamentals via `obs.plotLMS(Parent=ax)`. Both panels are peak-normalized (the default `NormalizeOutput=true`): each cone is divided by its own peak, so these figures compare spectral *shape*, not absolute sensitivity. What that does depends on where each cone's peak sits relative to the macular band. L and M peak near 570 and 545 nm, outside it, so their curves come back with a depressed flank around 498 nm. The S cone peaks at 443 nm, *inside* the band, so pinning that peak to 1.0 lifts the rest of the curve instead: its short-wavelength flank ends up slightly higher in the 2 deg observer, with a small dip just long of the peak. The difference plot in the next section shows all three.
wl = (380:1:780)';
LMS2 = obs2.LMS(wl);
LMS10 = obs10.LMS(wl);
tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
obs2.plotLMS(Title="2 deg Observer (Foveal)", Wavelength=wl, Parent=nexttile);
xlim([380 780]); ylim([0 1.05])
obs10.plotLMS(Title="10 deg Observer (Large Field)", Wavelength=wl, Parent=nexttile);
xlim([380 780]); ylim([0 1.05])
%%
%[text] ## Difference analysis
%[text] Subtracting the 10 deg observer from the 2 deg observer makes the dependency on field size visible. Both mechanisms change together between the two observers: macular density falls from 0.35 to 0.095 at its 460 nm peak, and photopigment optical density falls from 0.50 to 0.38 for L and M and from 0.40 to 0.30 for S.
%[text] Because both observers are peak-normalized, the optical-density change is largely divided out -- it mostly rescales each curve, and rescaling is what normalization removes. The macular change survives as a genuine shape difference and dominates all three residuals. It dominates so thoroughly that it *overshoots* for every cone: starting from the 10 deg observer and raising only its macular density to 0.35 produces larger residuals (L 0.1173, M 0.1774, S 0.0877) than changing both mechanisms together does (0.1042, 0.1681, 0.0788), because the two effects partly cancel.
diff_LMS = LMS2 - LMS10;
tiledlayout(1, 1, 'TileSpacing', 'compact', 'Padding', 'compact'); nexttile
plot(wl, diff_LMS(:,1), 'r-'); hold on
plot(wl, diff_LMS(:,2), 'g-')
plot(wl, diff_LMS(:,3), 'b-')
plot(wl, zeros(size(wl)), '--', 'Color', IndividualCMF.neutralColor(), 'LineWidth', 1); hold off
xlabel('Wavelength (nm)'); ylabel('Sensitivity Difference (2 deg - 10 deg)')
title('How the 2 deg and 10 deg observers differ')
legend('L', 'M', 'S', 'Location', 'bestoutside')
xlim([380 780])
%%
%[text] ## Standards compliance -- `Type` and `StandardObserver`
%[text] Two read-back properties tell you whether an observer is standards-compliant:
%[text] - `Type` -- string, `"CIE 170-1:2006"` for a tabulated standard, `"Individualized"` otherwise.
%[text] - `StandardObserver` -- numeric companion: `2` or `10` for the matching standard, `0` otherwise. \
%[text] Any **biophysical** modification -- `Age`, `FieldSize`, a density, a template, a lambda-max shift -- flips both back to the non-standard state. Output-shape settings (`OutputFormat`, `NormalizeOutput`, `LogOutput`, `NormalizationMethod`) do not: they change how the same observer's numbers are reported, not which observer it is, so compliance survives them.
obs_test = IndividualCMF(StandardObserver=10);
typeBefore = obs_test.Type;
soBefore   = obs_test.StandardObserver;
obs_test.Age = 40;
typeAfter = obs_test.Type;
soAfter   = obs_test.StandardObserver;
table([typeBefore; typeAfter], [soBefore; soAfter], ...
    'VariableNames', {'Type', 'StandardObserver'}, ...
    'RowNames', {'Before', 'After_Age=40'})
%%
%[text] ## Snapping back to a standard configuration
%[text] `StandardObserver` is also **settable**: assigning `obs.StandardObserver = 2` (or `10`) snaps every biophysical parameter -- Age, FieldSize, densities, opsin templates, lambda-max shifts, density algorithms -- back to the corresponding CIE tabulated values. Output-shape settings (OutputFormat, NormalizeOutput, etc.) are preserved.
%[text] This is the cleanest way to recover a standard configuration after experimenting on an individualized observer.
obs_test.StandardObserver = 10;   % snap back
typeRestored = obs_test.Type;
soRestored   = obs_test.StandardObserver;
ageRestored  = obs_test.Age;
table(typeRestored, soRestored, ageRestored, ...
    'VariableNames', {'Type', 'StandardObserver', 'Age'})
%%
%[text] ## CIE 2015 XYZ color matching functions
%[text] The toolbox produces CIE 2015 XYZ color matching functions as a linear transform of the LMS cone fundamentals. `obs.plotXYZ()` is the dedicated wrapper; the underlying `obs.XYZ(wl)` returns the raw Nx3 array.
%[text] The two panels do not share a transform: `XYZ()` selects the 2 deg matrix for a field size up to 4 deg and the 10 deg matrix above it, following CIE 15. So the difference between the two panels is the LMS difference *and* a different matrix applied to it.
tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
obs2.plotXYZ(Title="CIE 2015 XYZ -- 2 deg", Wavelength=wl, Parent=nexttile);
xlim([380 780]); ylim([0 2.25])
obs10.plotXYZ(Title="CIE 2015 XYZ -- 10 deg", Wavelength=wl, Parent=nexttile);
xlim([380 780]); ylim([0 2.25])
%%
%[text] ## Key takeaways
%[text] - CIE 2006 defines 2 deg and 10 deg standard observers based on physiology
%[text] - 2 deg: higher macular pigment, for stimuli up to about 4 deg; 10 deg: lower macular pigment, for larger fields. CIE 15 ties the choice to stimulus size, which is the rule `XYZ()` implements when it picks its transform matrix
%[text] - Both are defined at Age=32
%[text] - The `Type` and `StandardObserver` properties tell you whether an observer is standards-compliant; any biophysical modification flips both away from standard (output-shape settings do not), and `obs.StandardObserver = 2` (or `10`) snaps everything back
%[text] - Use `obs.XYZ(wl)` for CIE 2015 XYZ color matching functions \
%[text] **Next:** [Example 03: How an Observer Is Assembled](matlab:edit('Example03_HowAnObserverIsAssembled.m')) -- the three components behind every fundamental, and the two controls each one has.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

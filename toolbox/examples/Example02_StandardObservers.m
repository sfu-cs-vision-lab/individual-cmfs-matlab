%[text] # Example 02: CIE 2006 Standard Observers
%[text] **CIE 170-1:2006** / **CIE 170-2:2015** define the physiologically-based cone fundamentals used here, replacing the older CIE 1931 and 1964 colorimetric functions. This example covers the 2° and 10° standard observers, when to use each, and how `Type` / `StandardObserver` track standards compliance.
%[text] **Time:** about 10 minutes.
exampleDefaults();
%%
%[text] ## The two standard observers
%[text] CIE 2006 defines two observers reflecting different viewing conditions:
%[text] - **2 deg (foveal)** -- small stimuli, central vision, higher macular pigment, higher photopigment optical density
%[text] - **10 deg (peripheral)** -- larger stimuli, parafoveal vision, lower macular pigment, lower photopigment optical density \
%[text] Both are defined at **age 32** for reproducibility.
obs2 = IndividualCMF(StandardObserver=2);
obs10 = IndividualCMF(StandardObserver=10);
table([obs2.MacularDensity; obs10.MacularDensity], ...
      [obs2.Lod; obs10.Lod], ...
      [string(obs2.Type); string(obs10.Type)], ...
      'VariableNames', {'MacularDensity_460nm', 'L_OD', 'Type'}, ...
      'RowNames', {'2-degree', '10-degree'})
%%
%[text] ## Visual comparison
%[text] Stacked plot of the two standard observers' cone fundamentals via `obs.plotLMS(Parent=ax)`. The 2 deg observer (top) shows reduced S-cone sensitivity around 460 nm because of higher macular pigment absorption.
wl = (380:1:780)';
LMS2 = obs2.LMS(wl);
LMS10 = obs10.LMS(wl);
tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
obs2.plotLMS(Title="2 deg Observer (Foveal)", Wavelength=wl, Parent=nexttile);
xlim([380 780]); ylim([0 1.05])
obs10.plotLMS(Title="10 deg Observer (Peripheral)", Wavelength=wl, Parent=nexttile);
xlim([380 780]); ylim([0 1.05])
%%
%[text] ## Difference analysis
%[text] Subtracting the 10 deg observer from the 2 deg observer makes the dependency on field size visible. The 2-deg observer absorbs more of the 460 nm region in the macular pigment layer, attenuating the S-cone response there. The L and M differences come almost entirely from the optical-density change between 0.50 and 0.38.
diff_LMS = LMS2 - LMS10;
tiledlayout(1, 1, 'TileSpacing', 'compact', 'Padding', 'compact'); nexttile
plot(wl, diff_LMS(:,1), 'r-'); hold on
plot(wl, diff_LMS(:,2), 'g-')
plot(wl, diff_LMS(:,3), 'b-')
plot(wl, zeros(size(wl)), 'k--', 'LineWidth', 1); hold off
xlabel('Wavelength (nm)'); ylabel('Sensitivity Difference (2 deg - 10 deg)')
title('How the 2 deg and 10 deg observers differ')
legend('L', 'M', 'S', 'Location', 'bestoutside')
xlim([380 780])
%%
%[text] ## Standards compliance -- `Type` and `StandardObserver`
%[text] Two read-back properties tell you whether an observer is standards-compliant:
%[text] - `Type` -- string, `"CIE 170-1:2006"` for a tabulated standard, `"Individualized"` otherwise.
%[text] - `StandardObserver` -- numeric companion: `2` or `10` for the matching standard, `0` otherwise. \
%[text] **Any** modification (including a single property assignment) flips both back to the non-standard state -- your observer is no longer standards-compliant.
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
tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
obs2.plotXYZ(Title="CIE 2015 XYZ -- 2 deg", Wavelength=wl, Parent=nexttile);
xlim([380 780]); ylim([0 2.25])
obs10.plotXYZ(Title="CIE 2015 XYZ -- 10 deg", Wavelength=wl, Parent=nexttile);
xlim([380 780]); ylim([0 2.25])
%%
%[text] ## Key takeaways
%[text] - CIE 2006 defines 2 deg and 10 deg standard observers based on physiology
%[text] - 2 deg: higher macular pigment, used for small stimuli; 10 deg: lower macular pigment, preferred for most applications
%[text] - Both are defined at Age=32
%[text] - The `Type` and `StandardObserver` properties tell you whether an observer is standards-compliant; any modification flips both away from standard, and `obs.StandardObserver = 2` (or `10`) snaps everything back
%[text] - Use `obs.XYZ(wl)` for CIE 2015 XYZ color matching functions \
%[text] **Next:** [Example 03: Field Size Effects](matlab:edit('Example03_FieldSizeEffects.m')) -- how field size changes macular pigment and photopigment optical densities.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

%[text] # Example 04: Field Size Effects
%[text] Field size is the visual angle of the stimulus. It changes the cone fundamentals through two quantities:
%[text] - **Macular pigment density.** The macular pigment lies over the fovea and thins with distance from it, so a larger field includes more retina carrying less pigment.
%[text] - **Photopigment optical density.** Foveal cones have long outer segments and a high optical density. Cones further out have shorter segments and a lower density. \
%[text] CIE 170-1:2006 tabulates these values at 2 deg and 10 deg. For field sizes in between it specifies two published formulae, available here as `MacularDensityAlgorithm="MorelandAlexander"` and `PhotopigmentDensityAlgorithm="PokornySmith"`. The toolbox selects them for any non-standard field size without being asked. [Example 03](matlab:edit('Example03_HowAnObserverIsAssembled.m')) describes how the `CIE170` setting relates to these formulae.
%[text] **Time:** about 12 minutes.
exampleDefaults();
%%
%[text] ## Standard 2 deg and 10 deg parameters
%[text] CIE 170-1:2006 fixes these values exactly. The macular density falls from 0.350 to 0.095 between the two, a factor of 3.7.
obs2  = IndividualCMF(StandardObserver=2);
obs10 = IndividualCMF(StandardObserver=10);
table([obs2.MacularDensity; obs10.MacularDensity], ...
      [obs2.Lod; obs10.Lod], [obs2.Mod; obs10.Mod], [obs2.Sod; obs10.Sod], ...
      'VariableNames', {'MacularDensity_460nm', 'L_OD', 'M_OD', 'S_OD'}, ...
      'RowNames', {'2-degree', '10-degree'})
%%
%[text] ## Visual comparison
%[text] `obs2.compareTo(obs10)` draws both observers on the same axes. The lower panel shows the S cone alone, where the macular pigment has most of its effect.
wl = (380:1:700)';
tiledlayout(2, 1, 'TileSpacing', 'loose', 'Padding', 'compact');
compareAx = nexttile;
obs2.compareTo(obs10, Title="2 deg (solid) vs 10 deg (dashed)", ...
    Wavelength=wl, Parent=compareAx);
xlim([380 700])
lgd = legend(compareAx); lgd.NumColumns = 2;
nexttile
plot(wl, obs2.S(wl),  'b-'); hold on
plot(wl, obs10.S(wl), 'b--'); hold off
xlabel('Wavelength (nm)'); ylabel('S-Cone Sensitivity')
title('S cone, where the macular pigment acts')
legend('S 2 deg', 'S 10 deg', 'Location', 'bestoutside')
xlim([380 520])
%%
%[text] ## The continuous formulae
%[text] Requesting a non-standard field size is enough on its own. The toolbox switches both density algorithms to the formulae, so `IndividualCMF(FieldSize=4)` gives the same observer as the fully written form below. The algorithms are named here only so the table can report which were used.
%[text] The formulae are $D_{mac} = 0.485\\,e^{-\\phi/6.132}$ for macular pigment and $D_{L,M} = 0.38 + 0.54\\,e^{-\\phi/1.333}$ for the L and M cones, with $0.30 + 0.45\\,e^{-\\phi/1.333}$ for S. Here $\\phi$ is the field size in degrees. They were fitted over 1 to 10 deg. Values outside that range are extrapolation.
obs4 = IndividualCMF(Age=32, FieldSize=4, ...
    MacularDensityAlgorithm="MorelandAlexander", ...
    PhotopigmentDensityAlgorithm="PokornySmith");
table(obs4.FieldSize, obs4.MacularDensity, obs4.Lod, ...
      string(obs4.MacularDensityAlgorithm), string(obs4.PhotopigmentDensityAlgorithm), ...
      string(obs4.Type), ...
      'VariableNames', {'FieldSize', 'MacularDensity', 'Lod', ...
                        'MacularAlg', 'PhotopigmentAlg', 'Type'})
%%
%[text] ## Density against field size
%[text] The figure below sweeps field size from 1 to 20 deg using the formulae. Both densities fall as field size increases.
%[text] The black diamonds mark the CIE tabulated values at 2 and 10 deg. They lie on the formula curves rather than beside them, which is what the figure is meant to show. The algorithms are passed explicitly for the same reason. Without them the 2 and 10 deg observers would take their tabulated values instead, and the result would not be a single continuous curve.
%[text] The 15 and 20 deg points lie outside the range the formulae were fitted over. They are drawn on the same curve but are not supported by the fitted data.
field_sizes = [1, 2, 4, 6, 8, 10, 15, 20]';
fs_observers = IndividualCMF.across('FieldSize', field_sizes, ...
    Age=32, MacularDensityAlgorithm="MorelandAlexander", ...
    PhotopigmentDensityAlgorithm="PokornySmith");
mac = [fs_observers.MacularDensity]';
lod = [fs_observers.Lod]';
tiledlayout(2, 1, 'TileSpacing', 'loose', 'Padding', 'compact');
nexttile
plot(field_sizes, mac, 'b-o', 'MarkerSize', 6); hold on
plot([2, 10], [obs2.MacularDensity, obs10.MacularDensity], ...
    'kd', 'MarkerSize', 10, 'MarkerFaceColor', 'k'); hold off
xlabel('Field Size (deg)'); ylabel('Macular density at 460 nm')
title('Macular pigment density')
legend('Moreland-Alexander', 'CIE value (2 deg and 10 deg)', 'Location', 'bestoutside')
ylim([0 0.45])
nexttile
plot(field_sizes, lod, 'r-o', 'MarkerSize', 6); hold on
plot([2, 10], [obs2.Lod, obs10.Lod], ...
    'kd', 'MarkerSize', 10, 'MarkerFaceColor', 'k'); hold off
xlabel('Field Size (deg)'); ylabel('L-cone optical density')
title('Photopigment optical density')
legend('Pokorny-Smith', 'CIE value (2 deg and 10 deg)', 'Location', 'bestoutside')
%%
%[text] ## S-cone sensitivity across field sizes
%[text] A smaller field carries more macular pigment and a higher photopigment optical density. Every curve below is peak-normalized, so the change in overall height is removed and only the change in shape remains.
%[text] Both quantities make the S curve wider rather than narrower. At the 1 deg field the macular optical density is 0.4168 at its peak of 457 nm and 0.3537 at the S cone peak of 443 nm. Because those two values are close, dividing by the peak reduces the curve only over the narrow range from 444 to 463 nm, where the 1 deg curve is 0.055 lower than the 10 deg curve at 454.5 nm. At all other wavelengths the normalized sensitivity increases, by as much as 0.092 at 418.5 nm.
%[text] The higher photopigment optical density widens the curve as well, by self-screening. Measured at half its maximum, the 1 deg curve spans 418.5 to 477.5 nm, a width of 59 nm, against 421.5 to 474 nm and a width of 52 nm at 10 deg.
fscol = parula(numel(field_sizes));
tiledlayout(1, 1); nexttile
plot(wl, fs_observers(1).S(wl), 'Color', fscol(1,:), 'LineWidth', 1.5, ...
    'DisplayName', sprintf('%d deg', field_sizes(1)))
hold on
for i = 2:numel(field_sizes)
    plot(wl, fs_observers(i).S(wl), 'Color', fscol(i,:), 'LineWidth', 1.5, ...
        'DisplayName', sprintf('%d deg', field_sizes(i)))
end
hold off
xlabel('Wavelength (nm)'); ylabel('S-Cone Sensitivity')
title('S cone across field sizes (Moreland-Alexander and Pokorny-Smith)')
legend('Location', 'bestoutside'); xlim([380 520])
%%
%[text] ## The formulae at the standard field sizes
%[text] At 10 deg the formulae give values very close to the CIE constants but not identical to them. For `StandardObserver=10` the toolbox uses the CIE constants, so that a standard observer matches the standard exactly.
obs_CIE     = IndividualCMF(StandardObserver=10);
obs_formula = IndividualCMF(Age=32, FieldSize=10, ...
    MacularDensityAlgorithm="MorelandAlexander", ...
    PhotopigmentDensityAlgorithm="PokornySmith");
table([obs_CIE.MacularDensity; obs_formula.MacularDensity], ...
      [obs_CIE.Lod; obs_formula.Lod], ...
      [string(obs_CIE.Type); string(obs_formula.Type)], ...
      'VariableNames', {'MacularDensity', 'L_OD', 'Type'}, ...
      'RowNames', {'CIE170', 'Formula-based'})
%[text] The table below gives the size of the disagreement at 10 deg, as a percentage of the CIE value.
table(100*abs(obs_formula.MacularDensity - obs_CIE.MacularDensity)/obs_CIE.MacularDensity, ...
      100*abs(obs_formula.Lod - obs_CIE.Lod)/obs_CIE.Lod, ...
      'VariableNames', {'MacularDensity_pct_diff', 'Lod_pct_diff'})
%[text] These formulae are the field size model that CIE 170-1:2006 specifies for 1 to 10 deg, based on the Moreland and Alexander and the Pokorny, Smith and Lutze measurements. They reproduce the tabulated values to within a tenth of a percent. At 2 deg the macular formula gives 0.350020 against a tabulated 0.350, and at 10 deg the differences are those tabulated above, 0.052% for macular density and 0.078% for L-cone optical density.
%%
%[text] ## Setting a density directly
%[text] A density can also be assigned directly. Doing so selects `"Custom"` for the corresponding algorithm, so the assigned value is kept through later changes to field size or age. [Example 15](matlab:edit('Example15_AdvancedCustomization.m')) gives the full rules.
obs_manual = IndividualCMF();
obs_manual.MacularDensity = 0.5;
obs_manual.Lod = 0.6;
table(obs_manual.MacularDensity, string(obs_manual.MacularDensityAlgorithm), ...
      obs_manual.Lod, string(obs_manual.PhotopigmentDensityAlgorithm), ...
      string(obs_manual.Type), ...
      'VariableNames', {'MacularDensity', 'MacularAlg', 'Lod', 'PhotoAlg', 'Type'})
%%
%[text] ## A high-density observer against the standards
%[text] The figure below compares an observer with deliberately high densities against the two standard observers.
tiledlayout(1, 1); nexttile
plot(wl, obs2.S(wl),  'b-'); hold on
plot(wl, obs10.S(wl), 'g-')
plot(wl, obs_manual.S(wl), 'r--'); hold off
xlabel('Wavelength (nm)'); ylabel('S-Cone Sensitivity')
title('High-density observer against the standards')
legend('2 deg CIE', '10 deg CIE', 'Custom (high density)', 'Location', 'bestoutside')
grid on; xlim([380 520])
%%
%[text] ## Key takeaways
%[text] - Field size changes both the macular pigment density and the photopigment optical density
%[text] - A larger field means less macular pigment and a lower optical density
%[text] - CIE defines exact values at 2 and 10 deg only. The formula-based algorithms cover the range in between
%[text] - `MacularDensityAlgorithm="MorelandAlexander"` and `PhotopigmentDensityAlgorithm="PokornySmith"` select those formulae, and the toolbox selects them for you at any non-standard field size
%[text] - Both quantities widen the S-cone curve at small field sizes rather than narrowing it
%[text] - Assigning `MacularDensity`, `Lod` or a related property selects Custom mode for that component \
%[text] **Next:** [Example 05: Aging Effects on Color Vision](matlab:edit('Example05_AgingEffects.m')). How age and the choice of `LensModel` affect the cone fundamentals.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

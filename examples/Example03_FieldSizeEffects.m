%[text] # Example 03: Field Size Effects
%[text] Field size -- the visual angle of the stimulus -- affects cone fundamentals via two physiological mechanisms:
%[text] - **Macular pigment density**: macular pigment is concentrated in the central fovea; larger field sizes include more peripheral retina with less pigment
%[text] - **Photopigment optical density**: foveal cones have longer outer segments (higher OD); peripheral cones have shorter outer segments (lower OD) \
%[text] CIE defines exact values for 2° and 10° only. For arbitrary field sizes, two formula-based algorithms cover the continuum: `MacularDensityAlgorithm="MorelandAlexander"` and `PhotopigmentDensityAlgorithm="PokornySmith"`.
%[text] **Time:** about 12 minutes.
exampleDefaults();
%%
%[text] ## Standard 2 deg vs 10 deg parameters
%[text] CIE 170-1:2006 fixes these values exactly. Notice the macular density drops from 0.35 to 0.095 (3.7x lower) when going from 2 deg to 10 deg.
obs2  = IndividualCMF(StandardObserver=2);
obs10 = IndividualCMF(StandardObserver=10);
table([obs2.MacularDensity; obs10.MacularDensity], ...
      [obs2.Lod; obs10.Lod], [obs2.Mod; obs10.Mod], [obs2.Sod; obs10.Sod], ...
      'VariableNames', {'MacularDensity_460nm', 'L_OD', 'M_OD', 'S_OD'}, ...
      'RowNames', {'2-degree', '10-degree'})
%%
%[text] ## Visual comparison
%[text] `obs2.compareTo(obs10)` overlays both observers' LMS curves; the S-cone closeup makes the macular-pigment difference around 460 nm explicit.
wl = (380:1:700)';
tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
compareAx = nexttile;
obs2.compareTo(obs10, Title="2 deg (solid) vs 10 deg (dashed)", ...
    Wavelength=wl, Parent=compareAx);
xlim([380 700])
lgd = legend(compareAx); lgd.NumColumns = 2;
nexttile
plot(wl, obs2.S(wl),  'b-'); hold on
plot(wl, obs10.S(wl), 'b--'); hold off
xlabel('Wavelength (nm)'); ylabel('S-Cone Sensitivity')
title('S-cone close-up -- macular effect')
legend('S 2 deg', 'S 10 deg', 'Location', 'bestoutside')
xlim([380 520])
%%
%[text] ## Continuous field-size algorithms
%[text] For non-standard field sizes, set `MacularDensityAlgorithm="MorelandAlexander"` and `PhotopigmentDensityAlgorithm="PokornySmith"`. Both produce continuous values for any positive field size. Below: a 4 deg observer using these algorithms.
obs4 = IndividualCMF(Age=32, FieldSize=4, ...
    MacularDensityAlgorithm="MorelandAlexander", ...
    PhotopigmentDensityAlgorithm="PokornySmith");
table(obs4.FieldSize, obs4.MacularDensity, obs4.Lod, ...
      string(obs4.MacularDensityAlgorithm), string(obs4.PhotopigmentDensityAlgorithm), ...
      string(obs4.Type), ...
      'VariableNames', {'FieldSize', 'MacularDensity', 'Lod', ...
                        'MacularAlg', 'PhotopigmentAlg', 'Type'})
%%
%[text] ## Field size sweep -- density vs size
%[text] Sweep across field sizes from 1 deg to 20 deg using the continuous algorithms. Both densities decrease monotonically with field size; CIE 2 deg/10 deg anchor points are highlighted in red.
field_sizes = [1, 2, 4, 6, 8, 10, 15, 20]';
fs_observers = IndividualCMF.across('FieldSize', field_sizes, ...
    Age=32, MacularDensityAlgorithm="MorelandAlexander", ...
    PhotopigmentDensityAlgorithm="PokornySmith");
mac = [fs_observers.MacularDensity]';
lod = [fs_observers.Lod]';
tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile
plot(field_sizes, mac, 'b-o', 'MarkerSize', 6); hold on
plot([2, 10], [obs2.MacularDensity, obs10.MacularDensity], ...
    'kd', 'MarkerSize', 10, 'MarkerFaceColor', 'k'); hold off
xlabel('Field Size (deg)'); ylabel('Macular density at 460 nm')
title('Macular pigment density')
legend('Moreland-Alexander', 'CIE anchor (2 deg / 10 deg)', 'Location', 'bestoutside')
ylim([0 0.45])
nexttile
plot(field_sizes, lod, 'r-o', 'MarkerSize', 6); hold on
plot([2, 10], [obs2.Lod, obs10.Lod], ...
    'kd', 'MarkerSize', 10, 'MarkerFaceColor', 'k'); hold off
xlabel('Field Size (deg)'); ylabel('L-cone optical density')
title('Photopigment optical density')
legend('Pokorny-Smith', 'CIE anchor (2 deg / 10 deg)', 'Location', 'bestoutside')
%%
%[text] ## S-cone sensitivity across field sizes
%[text] Smaller (more foveal) field sizes show greater macular pigment absorption and higher optical density. The result is a more attenuated and slightly narrower S-cone response. The 1 deg-2 deg curves visibly differ from the 10 deg+ curves around the 460 nm region.
agecol = parula(numel(field_sizes));
tiledlayout(1, 1, 'TileSpacing', 'compact', 'Padding', 'compact'); nexttile
plot(wl, fs_observers(1).S(wl), 'Color', agecol(1,:), 'LineWidth', 1.5, ...
    'DisplayName', sprintf('%ddeg', field_sizes(1)))
hold on
for i = 2:numel(field_sizes)
    plot(wl, fs_observers(i).S(wl), 'Color', agecol(i,:), 'LineWidth', 1.5, ...
        'DisplayName', sprintf('%ddeg', field_sizes(i)))
end
hold off
xlabel('Wavelength (nm)'); ylabel('S-Cone Sensitivity')
title('S-cone across field sizes (Moreland-Alexander + Pokorny-Smith)')
legend('Location', 'bestoutside'); xlim([380 520])
%%
%[text] ## Algorithm comparison at standard sizes
%[text] At 10 deg the formula-based algorithms produce values very close (but not identical) to the CIE constants. The toolbox uses the CIE constants for `StandardObserver=10` to guarantee bit-exact CIE compliance.
obs_CIE     = IndividualCMF(StandardObserver=10);
obs_formula = IndividualCMF(Age=32, FieldSize=10, ...
    MacularDensityAlgorithm="MorelandAlexander", ...
    PhotopigmentDensityAlgorithm="PokornySmith");
table([obs_CIE.MacularDensity; obs_formula.MacularDensity], ...
      [obs_CIE.Lod; obs_formula.Lod], ...
      [string(obs_CIE.Type); string(obs_formula.Type)], ...
      'VariableNames', {'MacularDensity', 'L_OD', 'Type'}, ...
      'RowNames', {'CIE170', 'Formula-based'})
%[text] Quantifying the disagreement at 10 deg (percent difference from the CIE values):
table(100*abs(obs_formula.MacularDensity - obs_CIE.MacularDensity)/obs_CIE.MacularDensity, ...
      100*abs(obs_formula.Lod - obs_CIE.Lod)/obs_CIE.Lod, ...
      'VariableNames', {'MacularDensity_pct_diff', 'Lod_pct_diff'})
%[text] The Moreland-Alexander and Pokorny-Smith formulas are post-hoc fits to the CIE 2-deg and 10-deg endpoints, not independent measurements. They smooth the field-size axis but don't add information beyond the two CIE table points and a smoothness assumption.
%%
%[text] ## Manual density overrides
%[text] You can override densities directly. Doing so auto-engages the corresponding algorithm to `"Custom"` (see `ex14`), so the override is preserved across subsequent field-size or age changes.
obs_manual = IndividualCMF();
obs_manual.MacularDensity = 0.5;
obs_manual.Lod = 0.6;
table(obs_manual.MacularDensity, string(obs_manual.MacularDensityAlgorithm), ...
      obs_manual.Lod, string(obs_manual.PhotopigmentDensityAlgorithm), ...
      string(obs_manual.Type), ...
      'VariableNames', {'MacularDensity', 'MacularAlg', 'Lod', 'PhotoAlg', 'Type'})
%%
%[text] ## Comparison: high-density custom observer vs standard observers
%[text] Visualizing the impact of a deliberately atypical macular density.
plot(wl, obs2.S(wl),  'b-'); hold on
plot(wl, obs10.S(wl), 'g-')
plot(wl, obs_manual.S(wl), 'r--'); hold off
xlabel('Wavelength (nm)'); ylabel('S-Cone Sensitivity')
title('Custom (Macular=0.5, L_{OD}=0.6) vs CIE 2 deg/10 deg')
legend('2 deg CIE', '10 deg CIE', 'Custom (high density)', 'Location', 'bestoutside')
grid on; xlim([380 520])
%%
%[text] ## Key takeaways
%[text] - Field size affects both macular pigment and photopigment optical density
%[text] - Larger fields -\> less macular pigment, lower OD (peripheral)
%[text] - CIE defines exact values for 2 deg and 10 deg only; for everything else use the formula-based algorithms
%[text] - `MacularDensityAlgorithm="MorelandAlexander"` and `PhotopigmentDensityAlgorithm="PokornySmith"` give continuous formulas
%[text] - Direct assignment to `MacularDensity`, `Lod`, etc. auto-engages Custom mode (see `ex14`) \
%[text] **Next:** [Example 04: Aging Effects on Color Vision](matlab:edit('Example04_AgingEffects.m')) -- how age and the choice of `LensModel` affect color vision.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

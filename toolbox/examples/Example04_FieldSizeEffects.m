%[text] # Example 04: Field Size Effects
%[text] Field size -- the visual angle of the stimulus -- affects cone fundamentals via two physiological mechanisms:
%[text] - **Macular pigment density**: macular pigment is concentrated in the central fovea; larger field sizes include more peripheral retina with less pigment
%[text] - **Photopigment optical density**: foveal cones have longer outer segments (higher OD); peripheral cones have shorter outer segments (lower OD) \
%[text] CIE 170-1:2006 tabulates standard observers at 2 deg and 10 deg, and specifies decay formulas covering the 1-10 deg continuum. The toolbox exposes those as `MacularDensityAlgorithm="MorelandAlexander"` and `PhotopigmentDensityAlgorithm="PokornySmith"`, and selects them automatically for any non-standard field size.
%[text] Every mode handles arbitrary field sizes, so the algorithm choice is narrower than it looks: `CIE170` mode uses the published table at exactly 2 and 10 deg and falls back to these same formulas everywhere else. The two settings therefore give identical numbers at 4, 6 or 15 deg and differ only at the two standard sizes, where the table is preferred over the formula's approximation of it.
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
%[text] Asking for a non-standard field size is enough: the toolbox switches both density algorithms to the CIE formulas on its own, so `IndividualCMF(FieldSize=4)` and the fully spelled-out form below produce identical observers. The algorithms are named explicitly here only so the table can show which ones were selected.
%[text] The formulas are $D_{mac} = 0.485\\,e^{-\\phi/6.132}$ and $D_{L,M} = 0.38 + 0.54\\,e^{-\\phi/1.333}$ (with $0.30 + 0.45\\,e^{-\\phi/1.333}$ for S), where $\\phi$ is the field size in degrees. They are fitted to hold their published range of 1-10 deg; values outside it are extrapolation.
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
%[text] Sweep across field sizes from 1 deg to 20 deg using the continuous algorithms. Both densities decrease monotonically with field size, and the CIE 2 deg / 10 deg tabulated values (black diamonds) land on the formula curves rather than beside them -- that agreement is the point of the figure, and it is why the algorithms are passed explicitly here: without them the 2 and 10 deg observers would snap to the CIE table and the sweep would not be one continuous curve.
%[text] The 15 and 20 deg points are outside the formulas' published 1-10 deg range: they are extrapolation, drawn on the same curve but not backed by the fitted data.
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
%[text] Smaller (more foveal) field sizes carry more macular pigment and a higher photopigment optical density. Every curve here is peak-normalized, so the amplitude change is divided out and only a shape change remains.
%[text] Where that shape change lands follows a simple rule: after dividing by the peak, a wavelength only drops if the added absorber takes more light there than it does at the peak itself. The S cone peaks at 443 nm, which is already deep inside the macular band (macular OD 0.30 there, against a maximum of 0.354 at 457 nm), so only the narrow 445-470 nm window loses ground -- the 1 deg curve sits about 0.055 below the 10 deg one at 454 nm -- while both flanks are *lifted*, by as much as 0.09 around 420 nm. The visible effect is a pinch near 460 nm with raised shoulders, not a carved-down blue flank.
%[text] The higher photopigment optical density works on the whole band, broadening the curve through self-screening. Both effects widen rather than narrow: at half maximum the 1 deg curve spans 419-477 nm against 422-474 nm at 10 deg.
fscol = parula(numel(field_sizes));
tiledlayout(1, 1, 'TileSpacing', 'compact', 'Padding', 'compact'); nexttile
plot(wl, fs_observers(1).S(wl), 'Color', fscol(1,:), 'LineWidth', 1.5, ...
    'DisplayName', sprintf('%d deg', field_sizes(1)))
hold on
for i = 2:numel(field_sizes)
    plot(wl, fs_observers(i).S(wl), 'Color', fscol(i,:), 'LineWidth', 1.5, ...
        'DisplayName', sprintf('%d deg', field_sizes(i)))
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
%[text] These formulas are the field-size model CIE 170-1:2006 itself specifies for 1-10 deg, built on the Moreland-Alexander and Pokorny-Smith measurements, not third-party smoothing fitted to two table points. They reproduce the tabulated anchors to within a tenth of a percent -- macular 0.350020 against 0.350 at 2 deg, and at 10 deg the residuals tabulated above, 0.0052% for macular and 0.078% for L density.
%%
%[text] ## Manual density overrides
%[text] You can override densities directly. Doing so auto-engages the corresponding algorithm to `"Custom"` (see [Example 15](matlab:edit('Example15_AdvancedCustomization.m'))), so the override is preserved across subsequent field-size or age changes.
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
%[text] - Direct assignment to `MacularDensity`, `Lod`, etc. auto-engages Custom mode (see [Example 15](matlab:edit('Example15_AdvancedCustomization.m'))) \
%[text] **Next:** [Example 05: Aging Effects on Color Vision](matlab:edit('Example05_AgingEffects.m')) -- how age and the choice of `LensModel` affect color vision.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

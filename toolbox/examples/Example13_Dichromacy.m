%[text] # Example 13: Dichromacy
%[text] Gene-deletion dichromacy occurs when one of the cone opsin genes is missing or non-functional, so the corresponding photopigment is not expressed in the retina. The toolbox represents an absent cone by setting its optical density (`Lod`, `Mod`, or `Sod`) to zero. Every output format -- `energy`, `quantal`, `absorptance`, and `absorbance` -- collapses that cone's column to zero.
%[text] Real dichromats vary in whether the affected cones are missing entirely or are present but filled with one of the surviving pigments; either way only two spectrally distinct cone classes remain, and the toolbox models that as the affected pigment being absent (zero optical density). A cone class present with a *shifted* pigment is anomalous trichromacy, not dichromacy, and is modelled differently -- see the last section. Anomalous trichromacy -- where all three cones are expressed but L and M peaks are shifted closer together -- is modelled with `LambdaMaxShift` instead, contrasted at the end of this example.
%[text] **Time:** about 10 minutes.
exampleDefaults();
%%
%[text] ## Building dichromat observers
%[text] Setting any of `Lod`, `Mod`, or `Sod` to zero at construction time engages the "Custom" mode for `PhotopigmentDensityAlgorithm`, so the zero survives a later `FieldSize` change, which is the one thing that would otherwise recompute all three cone densities. (`Age` and `LensModel` changes only ever touch lens density, Custom mode or not.)
obs_proto = IndividualCMF(Lod=0);
obs_deut  = IndividualCMF(Mod=0);
obs_trit  = IndividualCMF(Sod=0);
table([obs_proto.Lod; obs_deut.Lod; obs_trit.Lod], ...
      [obs_proto.Mod; obs_deut.Mod; obs_trit.Mod], ...
      [obs_proto.Sod; obs_deut.Sod; obs_trit.Sod], ...
      'VariableNames', {'Lod', 'Mod', 'Sod'}, ...
      'RowNames', {'Protanope', 'Deuteranope', 'Tritanope'})
%%
%[text] ## What the absent cone looks like in `LMS`
%[text] The protanope's L column is identically zero; the M and S columns are the normal Stockman-Rider responses.
wl = (380:1:780)';
LMS = obs_proto.LMS(wl);
tiledlayout(1, 1, 'TileSpacing', 'compact', 'Padding', 'compact'); nexttile
plot(wl, LMS(:,1), 'r-'); hold on
plot(wl, LMS(:,2), 'g-')
plot(wl, LMS(:,3), 'b-'); hold off
xlabel('Wavelength (nm)'); ylabel('Sensitivity')
title('Protanope: L absent')
legend('L (absent)', 'M', 'S', 'Location', 'bestoutside')
%%
%[text] ## Plot methods skip absent cones
%[text] `plotLMS`, `plotAbsorbance`, `plotAbsorptance`, and `plotQuantalEnergy` all drop the absent cone from both the axes and the legend. The returned handle array keeps its shape -- `3x1`, or `6x1` for `plotQuantalEnergy`, which draws a quantal and an energy trace per cone -- with `gobjects` placeholders in the absent slots, so existing handle indexing keeps working.
p = obs_deut.plotLMS(Title="Deuteranope (Mod = 0)");
fprintf('Valid line handles: %d of 3\n', sum(isgraphics(p)))
%%
%[text] ## Log-output floor for absent cones
%[text] In `LogOutput=true` mode the absent column returns the toolbox-wide `-10` "below dynamic range" floor instead of `-Inf`. The value -10 is a toolbox convention, not a physical quantity -- it keeps log-domain plots and downstream math finite.
obs_log = IndividualCMF(Sod=0, OutputFormat="energy", LogOutput=true);
LMS_log = obs_log.LMS([400 500 600 700]');
table(LMS_log(:,1), LMS_log(:,2), LMS_log(:,3), ...
      'VariableNames', {'L_log', 'M_log', 'S_log_absent'}, ...
      'RowNames', {'400 nm', '500 nm', '600 nm', '700 nm'})
%%
%[text] ## Why `XYZ` and `RGB` refuse to compute
%[text] CIE XYZ is a 3x3 linear transform of LMS. The matrix is fixed and invertible; what is missing is a dimension of the observer. With one cone absent the LMS responses span a plane, so the transform would return finite numbers describing a 2-D gamut in 3-D coordinates, with no agreed-upon convention for what they mean. Rather than return something undefined, `XYZ` throws. `RGB` is a stronger case: solving for the primary weights genuinely is singular when a cone is absent, so there is no answer to return at all.
try
    obs_proto.XYZ(wl);
catch ME
    disp(ME.identifier)
    disp(ME.message)
end
try
    obs_proto.RGB(wl);
catch ME
    disp(ME.identifier)
    disp(ME.message)
end
%%
%[text] ## Custom `TransformationMatrix` for dichromat XYZ
%[text] If you have a published or domain-specific projection (e.g. Brettel, Vienot & Mollon 1997; a 2x3 dichromat projection padded into a 3x3 matrix), pass it as `TransformationMatrix=`. This is on the caller's authority: the toolbox validates shape, not physical meaning.
%[text] **The matrix below is a shape-validation demo only** -- it zeroes the X row of the standard 10-deg LMS->XYZ transform, producing X = 0 everywhere. For meaningful dichromat XYZ simulation, use a Brettel-Vienot-Mollon style projection.
M_custom = [zeros(1,3); CIE170.M_10DEG(2:3,:)];
XYZ_custom = obs_proto.XYZ(wl, TransformationMatrix=M_custom);
fprintf('XYZ with custom matrix: size=[%d %d], any NaN=%d\n', ...
    size(XYZ_custom,1), size(XYZ_custom,2), any(isnan(XYZ_custom(:))))
%%
%[text] ## Dichromacy vs anomalous trichromacy
%[text] In red-green anomalous trichromacy all three opsins are expressed, but the L and M peak wavelengths sit abnormally close together. (Tritanomaly is the S-cone analogue and shifts S instead.) The grey reference curve below is the unshifted L cone: the -15 nm shift closes the L-M peak separation from about 27.5 nm to about 12.5 nm, and that collapse is what makes hue discrimination in the red-green range harder. That is a shift in lambda-max, not a missing pigment, so it is modelled with `L_LambdaMaxShift` / `M_LambdaMaxShift` (or the `Genotype` argument) -- not by zeroing an optical density. Compare a protanope to a protanomalous observer with a -15 nm L-cone shift below: the protanope's L column is zero everywhere, while the protanomalous L peak is shifted toward M but otherwise intact.
%[text] A caution before changing that number: at shifts of about -16.03 nm and beyond, the L cone stops shifting the Serine template and silently borrows the M-cone template instead, matching pycone. The -15 nm used here sits just inside that boundary, so nudging it to -20 changes which pigment is being modelled rather than just how far it moved.
obs_normal      = IndividualCMF(L_OpsinTemplate="Serine");
obs_protan_anom = IndividualCMF(L_OpsinTemplate="Serine", L_LambdaMaxShift=-15);
wl_zoom = (500:0.5:680)';
tiledlayout(1, 1, 'TileSpacing', 'compact', 'Padding', 'compact'); nexttile
plot(wl_zoom, obs_normal.L(wl_zoom), '-', 'Color', [0.6 0.6 0.6], 'LineWidth', 1.5); hold on
plot(wl_zoom, obs_proto.L(wl_zoom),       'r-')
plot(wl_zoom, obs_protan_anom.L(wl_zoom), 'r--')
plot(wl_zoom, obs_protan_anom.M(wl_zoom), 'g-'); hold off
xlabel('Wavelength (nm)'); ylabel('Sensitivity')
title('Protanopia vs protanomaly')
legend('Normal L (reference)', 'Protanope L (Lod=0)', 'Protanomalous L (-15 nm)', ...
       'Protanomalous M (unchanged)', 'Location', 'bestoutside')
%[text] **Next:** [Example 14: Advanced Customization](matlab:edit('Example14_AdvancedCustomization.m')) -- full parameter-space control plus the round-trip `getParameters`/`setParameters` workflow.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

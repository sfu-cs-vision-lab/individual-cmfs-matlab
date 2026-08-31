%[text] # Example 15: Dichromacy
%[text] A dichromat has only two spectrally distinct classes of cone rather than three. This happens when one of the cone opsin genes is missing or does not function, so the pigment it codes for is not produced.
%[text] The toolbox represents an absent cone by setting its optical density, `Lod`, `Mod` or `Sod`, to zero. The corresponding column of the output is then zero at every wavelength, in all four output formats.
%[text] Real dichromats differ in whether the affected cones are absent altogether or are present but contain one of the other pigments. Either way only two spectrally distinct classes remain. Setting the optical density to zero models the absent-cone case, which is the convention this toolbox uses. It reproduces the spectral outcome of the other case but not its cone counts, so a quantity that depends on how many cones of each type are present, such as luminance, will differ.
%[text] A cone that is present but contains a pigment whose peak has moved is a different condition, called anomalous trichromacy. All three cones are expressed and the L and M peaks lie closer together than usual. It is modelled with a lambda-max shift rather than a zero density. The last section of this example compares the two.
%[text] **Time:** about 10 minutes.
exampleDefaults();
%%
%[text] ## Building the three dichromat observers
%[text] Setting `Lod`, `Mod` or `Sod` to zero, in the constructor or afterwards, selects `"Custom"` mode for `PhotopigmentDensityAlgorithm`. The zero is then kept through a later change of `FieldSize`, which is the only change that would otherwise recompute the cone densities. Changes to `Age` and `LensModel` affect only the lens density, in Custom mode or not.
%[text] Custom mode holds all three densities, not only the one set to zero, and it holds them at the values they had at that moment. `IndividualCMF(Lod=0, FieldSize=2)` therefore leaves the two surviving cones at the 10 deg values of 0.38 and 0.30 rather than the 2 deg values of 0.50 and 0.40 that a normal small-field observer would have. When building a dichromat at any field size other than the default, set the surviving densities explicitly.
obs_proto = IndividualCMF(Lod=0);
obs_deut  = IndividualCMF(Mod=0);
obs_trit  = IndividualCMF(Sod=0);
table([obs_proto.Lod; obs_deut.Lod; obs_trit.Lod], ...
      [obs_proto.Mod; obs_deut.Mod; obs_trit.Mod], ...
      [obs_proto.Sod; obs_deut.Sod; obs_trit.Sod], ...
      'VariableNames', {'Lod', 'Mod', 'Sod'}, ...
      'RowNames', {'Protanope', 'Deuteranope', 'Tritanope'})
%%
%[text] ## The absent cone in the output
%[text] For a protanope the L column is zero at every wavelength. The M and S columns are the ordinary responses.
wl = (380:1:780)';
LMS = obs_proto.LMS(wl);
tiledlayout(1, 1); nexttile
plot(wl, LMS(:,1), 'r-'); hold on
plot(wl, LMS(:,2), 'g-')
plot(wl, LMS(:,3), 'b-'); hold off
xlabel('Wavelength (nm)'); ylabel('Sensitivity')
title('Protanope, with the L cone absent')
legend('L (absent)', 'M', 'S', 'Location', 'bestoutside')
%%
%[text] ## The plot methods and the absent cone
%[text] `plotLMS`, `plotAbsorbance`, `plotAbsorptance` and `plotQuantalEnergy` leave the absent cone out of both the axes and the legend.
%[text] The array of handles they return keeps its full size, which is 3 by 1, or 6 by 1 for `plotQuantalEnergy` since that method draws a quantal and an energy curve for each cone. The entries for the absent cone hold `gobjects` placeholders, so indexing into the array continues to work as before.
p = obs_deut.plotLMS(Title="Deuteranope, with Mod = 0");
fprintf('Valid line handles: %d of 3\n', sum(isgraphics(p)))
%%
%[text] ## Logarithmic output for an absent cone
%[text] With `LogOutput=true` the absent column returns -10 rather than negative infinity. The value -10 is a convention used throughout the toolbox to mean below the range that can be represented. It keeps logarithmic plots and any later arithmetic finite.
obs_log = IndividualCMF(Sod=0, OutputFormat="energy", LogOutput=true);
LMS_log = obs_log.LMS([400 500 600 700]');
table(LMS_log(:,1), LMS_log(:,2), LMS_log(:,3), ...
      'VariableNames', {'L_log', 'M_log', 'S_log_absent'}, ...
      'RowNames', {'400 nm', '500 nm', '600 nm', '700 nm'})
%%
%[text] ## Why XYZ and RGB raise errors
%[text] CIE XYZ is a 3 by 3 linear transform of LMS. The matrix is invertible, and which of the two standard matrices applies is decided by field size as [Example 02](matlab:edit('Example02_StandardObservers.m')) describes. Neither matrix is the problem here. What is missing is a dimension of the observer.
%[text] With one cone absent the LMS responses vary in only two dimensions. The transform would return three finite numbers, but they would describe a two-dimensional set of colours in three-dimensional coordinates, and there is no agreed convention for reading them. `XYZ` therefore raises an error rather than returning them. Its message describes the projection as rank-deficient, meaning the whole mapping from observer to XYZ rather than the matrix alone.
%[text] `RGB` is a clearer case. Solving for the primary weights requires inverting the matrix of LMS values at the primaries, and that matrix really is singular when a cone is absent, so there is no result to return.
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
%[text] ## Supplying a transformation matrix
%[text] A published projection for dichromats, such as that of Brettel, Vienot and Mollon (1997), or any 2 by 3 projection padded to 3 by 3, can be passed as `TransformationMatrix`. The toolbox checks the shape of the matrix and nothing else, so the choice of matrix is the caller's responsibility.
%[text] The matrix below only demonstrates that the argument is accepted. It replaces the X row of the standard 10 deg transform with zeros, so X is zero everywhere. For a meaningful simulation, use a projection of the Brettel, Vienot and Mollon kind.
M_custom = [zeros(1,3); CIE170.M_10DEG(2:3,:)];
XYZ_custom = obs_proto.XYZ(wl, TransformationMatrix=M_custom);
fprintf('XYZ with custom matrix: size=[%d %d], any NaN=%d\n', ...
    size(XYZ_custom,1), size(XYZ_custom,2), any(isnan(XYZ_custom(:))))
%%
%[text] ## Dichromacy compared with anomalous trichromacy
%[text] In red-green anomalous trichromacy all three opsins are expressed, but the L and M peaks lie abnormally close together. Tritanomaly is the equivalent condition for the S cone.
%[text] The figure below shows a protanope and a protanomalous observer whose L cone is shifted by -15 nm, with the unshifted L cone drawn in grey for reference. The shift reduces the separation between the L and M peaks from about 27.5 nm to about 12.5 nm. Two cones whose peaks lie that close together give a smaller difference signal between them, which is why discrimination in the red to green range is harder.
%[text] The protanope has no L response at all. The protanomalous L cone is intact and has moved towards M.
%[text] One caution about changing the -15 nm used here. For shifts beyond -16.0345 nm the L cone stops shifting the serine template and uses the M-cone template instead, which is what pycone does. A shift of -20 nm therefore changes which pigment is being modelled, not only how far it has moved.
obs_normal      = IndividualCMF(L_OpsinTemplate="Serine");
obs_protan_anom = IndividualCMF(L_OpsinTemplate="Serine", L_LambdaMaxShift=-15);
wl_zoom = (500:0.5:680)';
tiledlayout(1, 1); nexttile
plot(wl_zoom, obs_normal.L(wl_zoom), '-', 'Color', [0.6 0.6 0.6], 'LineWidth', 1.5); hold on
plot(wl_zoom, obs_proto.L(wl_zoom),       'r-')
plot(wl_zoom, obs_protan_anom.L(wl_zoom), 'r--')
plot(wl_zoom, obs_protan_anom.M(wl_zoom), 'g-'); hold off
xlabel('Wavelength (nm)'); ylabel('Sensitivity')
title('Protanopia and protanomaly')
legend('Normal L (reference)', 'Protanope L (Lod=0)', 'Protanomalous L (-15 nm)', ...
       'Protanomalous M (unchanged)', 'Location', 'bestoutside')
%%
%[text] ## Key takeaways
%[text] - Set a cone's optical density to zero to model dichromacy. `Lod=0` gives a protanope, `Mod=0` a deuteranope and `Sod=0` a tritanope. That column is then zero in every output format, absorbance included
%[text] - This models a pigment that is absent. Anomalous trichromacy keeps all three cones and moves one lambda-max, so it uses `L_LambdaMaxShift` or `M_LambdaMaxShift` instead. Beyond -16.0345 nm the L cone changes to the M template rather than shifting further
%[text] - Setting a density to zero selects Custom mode, which holds all three cone densities. At any field size other than the default, set the surviving densities explicitly or they keep their 10 deg values
%[text] - `XYZ` and `RGB` raise errors for a dichromat. The observer varies in two dimensions, and for `RGB` the matrix of primaries is genuinely singular. `XYZ` accepts a `TransformationMatrix` to override this. `RGB` has no equivalent argument
%[text] - `Luminance` still works. The S cone contributes nothing to it, so a tritanope has the same luminous efficiency as the standard observer. See [Example 13](matlab:edit('Example13_Luminance.m'))
%[text] - The cone plot methods omit an absent cone but keep the returned handle array the same size, using `gobjects` placeholders \
%[text] **Next:** [Example 16: Advanced Customization](matlab:edit('Example16_AdvancedCustomization.m')). Every parameter, and the `getParameters` and `setParameters` round trip.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

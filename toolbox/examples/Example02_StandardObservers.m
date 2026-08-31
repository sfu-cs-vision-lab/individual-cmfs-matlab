%[text] # Example 02: CIE 2006 Standard Observers
%[text] CIE 170-1:2006 and CIE 170-2:2015 define the cone fundamentals used by this toolbox. They are built from measured cone spectral sensitivities, which is why they are described as physiologically based. They are an alternative to the older CIE 1931 and 1964 colour matching functions, which CIE 015 still standardizes and which most industrial colorimetry still uses.
%[text] This example covers the 2 deg and 10 deg standard observers, when to use each of them, and how the `Type` and `StandardObserver` properties record whether an observer still matches a standard.
%[text] **Time:** about 10 minutes.
exampleDefaults();
%%
%[text] ## The two standard observers
%[text] CIE 2006 defines two observers, for two viewing conditions:
%[text] - **2 deg**, for small stimuli viewed centrally. This observer has more macular pigment and a higher photopigment optical density.
%[text] - **10 deg**, for larger stimuli. These still centre on the fovea but extend to about 5 deg from it. This observer has less macular pigment and a lower photopigment optical density. \
%[text] Both are defined at age 32, which is roughly the mean age of the observers the fundamentals were derived from.
%[text] Two quantities differ between them. **Macular pigment** is a yellow filter covering the fovea. It absorbs light between roughly 400 and 530 nm before that light reaches the cones, and it becomes thinner further from the fovea, so the 10 deg observer has less of it. **Photopigment optical density** describes how much pigment lies in the outer segment of each cone. The outer segments are shorter further from the fovea, so the density is lower there. Increasing the density broadens the sensitivity curve by a process known as self-screening, so the 10 deg observer has narrower curves than the 2 deg observer.
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
%[text] The plot below shows the cone fundamentals of both standard observers. `obs.plotLMS` draws each panel, and `Parent=` puts it in its own tile.
%[text] Both panels are peak-normalized, which is the default. Each cone is divided by its own largest value, so every curve reaches 1.0 at its peak. The panels therefore compare shape rather than overall height. At this scale the two observers look much alike. The next section subtracts one from the other, which shows the differences more clearly.
wl = (380:1:780)';
LMS2 = obs2.LMS(wl);
LMS10 = obs10.LMS(wl);
tiledlayout(2, 1, 'TileSpacing', 'loose', 'Padding', 'compact');
obs2.plotLMS(Title="2 deg Observer (Foveal)", Wavelength=wl, Parent=nexttile);
xlim([380 780]); ylim([0 1.05])
obs10.plotLMS(Title="10 deg Observer (Large Field)", Wavelength=wl, Parent=nexttile);
xlim([380 780]); ylim([0 1.05])
%%
%[text] ## Difference analysis
%[text] Subtracting the 10 deg sensitivities from the 2 deg sensitivities shows how field size affects each cone. Both quantities described above change together. Macular density falls from 0.350 to 0.095 at 460 nm, and photopigment optical density falls from 0.50 to 0.38 for L and M and from 0.40 to 0.30 for S.
%[text] Almost all of the difference plotted below comes from the macular pigment. Because both observers are peak-normalized, a change that rescales a whole curve is divided out again, and the optical density change does mostly that. The macular change alters the shape of each curve instead, so it survives normalization.
%[text] Normalization also decides which way each curve moves. Dividing by the peak holds the peak at 1.0, so a cone is reduced only at wavelengths where the macular pigment absorbs more than it does at that cone's own peak. The L and M cones peak at 569 and 544 nm, where the macular optical density is 0.0000 and 0.0022, so both are reduced at shorter wavelengths. The S cone peaks at 443 nm, where the macular optical density is 0.3004. Its peak is reduced along with the rest of the curve, so the normalized sensitivity increases at most other wavelengths.
diff_LMS = LMS2 - LMS10;
tiledlayout(1, 1); nexttile
plot(wl, diff_LMS(:,1), 'r-'); hold on
plot(wl, diff_LMS(:,2), 'g-')
plot(wl, diff_LMS(:,3), 'b-')
plot(wl, zeros(size(wl)), '--', 'Color', IndividualCMF.neutralColor(), 'LineWidth', 1); hold off
xlabel('Wavelength (nm)'); ylabel('Sensitivity Difference (2 deg - 10 deg)')
title('How the 2 deg and 10 deg observers differ')
legend('L', 'M', 'S', 'Location', 'bestoutside')
xlim([380 780])
%[text] The L and M curves are reduced most near 499 and 498 nm, by 0.104 and 0.168. The S curve is higher for the 2 deg observer below 445 nm and lower between 445 and 465 nm.
%%
%[text] ## Standards compliance
%[text] Two properties record whether an observer still matches a CIE standard:
%[text] - `Type` is `"CIE 170-1:2006"` for an observer that matches a tabulated standard, and `"Individualized"` otherwise.
%[text] - `StandardObserver` is `2` or `10` for the matching standard, and `0` otherwise. \
%[text] Changing a biophysical parameter normally sets both to the non-standard values. This includes `Age`, `FieldSize`, any density, any template and any lambda-max shift. The exception is a change that lands on the other tabulated standard: setting `FieldSize` to 2 on a 10 deg observer gives the 2 deg standard observer, with a macular density of 0.350 and cone densities of 0.50, so it stays standard. A field size of 4 or 6 does not, since the standard tabulates no values there.
%[text] Changing how the result is reported never affects either property, since `OutputFormat`, `NormalizeOutput`, `LogOutput` and `NormalizationMethod` alter the presentation of the numbers rather than the observer they describe.
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
%[text] ## Returning to a standard configuration
%[text] `StandardObserver` can also be assigned. Setting `obs.StandardObserver = 2` or `10` restores every biophysical parameter to the values of that standard, including age, field size, the densities, the opsin templates, the lambda-max shifts and the density algorithms. Output settings are left as they are.
%[text] This is the simplest way to return to a standard observer after experimenting with an individual one.
obs_test.StandardObserver = 10;
typeRestored = obs_test.Type;
soRestored   = obs_test.StandardObserver;
ageRestored  = obs_test.Age;
table(typeRestored, soRestored, ageRestored, ...
    'VariableNames', {'Type', 'StandardObserver', 'Age'})
%%
%[text] ## CIE 2015 XYZ colour matching functions
%[text] The toolbox produces CIE 2015 XYZ colour matching functions by applying a linear transform to the LMS cone fundamentals. `obs.plotXYZ` plots them and `obs.XYZ(wl)` returns them as an N by 3 array.
%[text] The two panels below do not use the same transform. Following CIE 15, `XYZ` selects the 2 deg matrix for field sizes up to 4 deg and the 10 deg matrix above that. The difference between the panels is therefore the difference in the cone fundamentals together with the difference in the matrix applied to them.
tiledlayout(2, 1, 'TileSpacing', 'loose', 'Padding', 'compact');
obs2.plotXYZ(Title="CIE 2015 XYZ, 2 deg", Wavelength=wl, Parent=nexttile);
xlim([380 780]); ylim([0 2.25])
obs10.plotXYZ(Title="CIE 2015 XYZ, 10 deg", Wavelength=wl, Parent=nexttile);
xlim([380 780]); ylim([0 2.25])
%%
%[text] ## Key takeaways
%[text] - CIE 2006 defines a 2 deg and a 10 deg standard observer, both at age 32
%[text] - Use the 2 deg observer for stimuli up to about 4 deg and the 10 deg observer for larger ones. CIE 15 ties the choice to stimulus size, and `XYZ` follows the same rule when it selects a transform matrix
%[text] - Almost all of the difference between the two observers comes from the macular pigment, because peak normalization removes most of the effect of the optical density change
%[text] - `Type` and `StandardObserver` record whether an observer still matches a standard. Any biophysical change sets both to the non-standard values, and output settings do not
%[text] - Assigning `obs.StandardObserver = 2` or `10` restores the standard configuration
%[text] - Use `obs.XYZ(wl)` for CIE 2015 XYZ colour matching functions \
%[text] **Next:** [Example 03: How an Observer Is Assembled](matlab:edit('Example03_HowAnObserverIsAssembled.m')). The three components behind every cone fundamental, and the two controls each one has.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

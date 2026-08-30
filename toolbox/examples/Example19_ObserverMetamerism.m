%[text] # Example 19: Observer Metamerism
%[text] Two lights with different spectra are **metameric** for a given observer if they produce the same responses in that observer's three cones, and therefore look identical.
%[text] The CIE 2006 standard observer sees a great many such pairs. Those same pairs are not metameric for every real observer, and that is what **observer metamerism** means. A match made for one observer fails for another. If every observer saw the same matches, one standard observer would be enough, and in practice it is not.
%[text] This is a different phenomenon from illuminant metamerism, in which two surfaces match under one illuminant and not under another, for one observer. That is not covered here.
%[text] The example does four things:
%[text] - Constructs a pair of spectra that match exactly for the standard 2 deg observer.
%[text] - Changes to an observer carrying the L-cone Ser180Ala variant, for whom the match no longer holds.
%[text] - Measures how far apart the two lights then are, in CIE xy chromaticity.
%[text] - Repeats the measurement for a larger individual difference, an aged lens. \
%[text] **Time:** about 12 minutes.
exampleDefaults();
%%
%[text] ## Step 1: constructing a metameric pair
%[text] The first light is a single Gaussian centred at 555 nm. The second is a mixture of three narrower Gaussians at 460, 540 and 620 nm, with the amounts chosen so that its XYZ tristimulus values equal those of the first.
%[text] Finding those amounts means solving `M*w = t`, where `M` is a 3 by 3 matrix whose column $j$ holds the XYZ values of primary $j$, `t` holds the XYZ values of the target, and `w` is the vector of amounts. The tristimulus values come from integrating each spectrum against the observer's XYZ colour matching functions.
%[text] The three primaries are placed away from 555 nm so that the mixture is not simply a copy of the target.
obsStd = IndividualCMF(StandardObserver=2);
wl = (380:1:780)';
gauss = @(center, width) exp(-((wl - center) / width).^2);
spdTarget = gauss(555, 25);
primaries = [gauss(460, 15), gauss(540, 15), gauss(620, 15)];
XYZCmfs = obsStd.XYZ(wl);
XYZTarget = sum(spdTarget .* XYZCmfs, 1)';
XYZPrim = XYZCmfs' * primaries;
weights = XYZPrim \ XYZTarget;
spdMixture = primaries * weights;
%[text] The two spectra give the same XYZ values for the standard observer. The differences below are at the limit of double precision.
XYZMixture = sum(spdMixture .* XYZCmfs, 1)';
table(XYZTarget, XYZMixture, XYZTarget - XYZMixture, ...
      'VariableNames', {'XYZ_target', 'XYZ_mixture', 'Difference'}, ...
      'RowNames', {'X', 'Y', 'Z'})
%[text] One of the three amounts is negative, so the mixture takes negative values over a 113 nm range and is not a spectrum any real light could produce. It is an algebraic construction rather than a second light, which is enough to demonstrate observer metamerism but should not be described as a physical stimulus.
%[text] Three primaries are not inherently too few. They suffice whenever the target falls inside the range of colours their non-negative mixtures span. These three do not span this target: restricting the amounts to be non-negative leaves a residual of 5.2e-02 rather than reaching zero. Either a different set of three primaries or a fourth primary would be needed for a realizable match.
%%
%[text] ## Step 2: the two spectra
%[text] The two spectra are quite different. The target is a single broad Gaussian peaking at 555 nm. The mixture is dominated by its 540 nm primary, with a secondary contribution at 620 nm reaching about 35% of that height. The 460 nm primary is effectively absent, since its amount is small and negative.
%[text] To the CIE 2006 2 deg standard observer these two spectra are indistinguishable.
f = gcf; f.Position(3:4) = [800 500];
tiledlayout(1, 1); nexttile
plot(wl, spdTarget, '-', 'Color', IndividualCMF.neutralColor()); hold on
plot(wl, spdMixture, 'r--')
plot(wl, zeros(size(wl)), ':', 'Color', IndividualCMF.neutralColor(), 'HandleVisibility', 'off')
hold off
xlabel('Wavelength (nm)'); ylabel('Spectral power (arbitrary)')
title('A metameric pair for the CIE 2006 2 deg standard observer')
legend('Target (555 nm Gaussian)', 'Three-Gaussian mixture', ...
       'Location', 'bestoutside')
xlim([380 780])
%%
%[text] ## Step 3: an observer for whom the match fails
%[text] The observer built below carries the alanine variant of the L-opsin, which is one of the two common alleles and is present in about 44% of the population.
%[text] The alanine and serine templates lie 2.7 nm apart, but the standard observer uses neither of them. It uses the population mean, which is a weighted average of the two. Relative to that, pure alanine moves the L photopigment lambda-max by 1.5 nm and the peak of the L cone fundamental by 1.6 nm. See [Example 06](matlab:edit('Example06_GeneticVariants.m')).
%[text] Nothing else about the observer changes. The M and S cones come back identical to the standard observer's, so every difference below is due to the L-cone variant alone.
obsAla = IndividualCMF(L_OpsinTemplate="Alanine", FieldSize=2);
XYZCmfsAla = obsAla.XYZ(wl);
XYZTargetAla  = sum(spdTarget  .* XYZCmfsAla, 1)';
XYZMixtureAla = sum(spdMixture .* XYZCmfsAla, 1)';
table(XYZTargetAla, XYZMixtureAla, XYZTargetAla - XYZMixtureAla, ...
      'VariableNames', {'XYZ_target', 'XYZ_mixture', 'Difference'}, ...
      'RowNames', {'X', 'Y', 'Z'})
%[text] X and Y now differ between the two spectra. Z does not, because the Z row of the LMS to XYZ matrix depends only on the S cone, and the L-cone variant leaves the S cone unchanged.
%[text] `XYZ` issues the warning `IndividualCMF:NonStandardObserver` here, and again in Step 5. That warning states the assumption this whole example rests on. The LMS to XYZ matrix was fitted for the CIE standard observer, so applying it to an individual observer's cone fundamentals gives individual colorimetric values rather than standard CIE tristimulus values. There is no standardized matrix for an individual observer.
%[text] Holding the matrix fixed is what makes the comparison meaningful, since it leaves the observer as the only thing that changes between the two calculations. The numbers it produces should not be reported as CIE tristimulus values. The warning is left visible for that reason.
%%
%[text] ## Step 4: measuring the difference in chromaticity
%[text] Converting to CIE xy separates the colour from the intensity. The table gives the coordinates of both spectra, under both observers.
xyTargetStd  = XYZTarget(1:2)  / sum(XYZTarget);
xyMixStd     = XYZMixture(1:2) / sum(XYZMixture);
xyTargetAla  = XYZTargetAla(1:2)  / sum(XYZTargetAla);
xyMixAla     = XYZMixtureAla(1:2) / sum(XYZMixtureAla);
table([xyTargetStd(1); xyMixStd(1)], [xyTargetStd(2); xyMixStd(2)], ...
      [xyTargetAla(1); xyMixAla(1)], [xyTargetAla(2); xyMixAla(2)], ...
      'VariableNames', {'x_std', 'y_std', 'x_alanine', 'y_alanine'}, ...
      'RowNames', {'Target', 'Mixture'})
%[text] Under the standard observer the two coordinates are identical. Under the alanine observer they differ.
%%
%[text] ## Step 5: a larger individual difference
%[text] The Ser180Ala variant is the most common difference between L cones, and the separation it produces is small. The distance $\\Delta xy = \\sqrt{(\\Delta x)^2 + (\\Delta y)^2}$ between the two chromaticities from Step 4 is about 0.003, computed as `shiftAla` below.
%[text] A 70 year old with a strongly absorbing lens gives a considerably larger separation.
obsAged = IndividualCMF(LensModel="VanDeKraats2007", Age=70, FieldSize=2);
obsAged.ModelRangeWarning = false;
XYZCmfsAged = obsAged.XYZ(wl);
XYZTargetAged  = sum(spdTarget  .* XYZCmfsAged, 1)';
XYZMixtureAged = sum(spdMixture .* XYZCmfsAged, 1)';
xyTargetAged = XYZTargetAged(1:2) / sum(XYZTargetAged);
xyMixAged    = XYZMixtureAged(1:2) / sum(XYZMixtureAged);
shiftAla  = norm(xyMixAla  - xyTargetAla);
shiftAged = norm(xyMixAged - xyTargetAged);
table([0; shiftAla; shiftAged], ...
      'VariableNames', {'Euclidean_dxy'}, ...
      'RowNames', {'CIE 2-deg standard', 'Ser180Ala variant', '70 yr lens aging'})
%[text] The separation for the 70 year old is roughly three to four times that for the polymorphism. An absorbing lens is therefore a substantial source of observer metamerism among older viewers.
%[text] Note that the `VanDeKraats2007` model was fitted over 300 to 700 nm and is evaluated to 780 nm here, so its range warning is switched off above. See [Example 05](matlab:edit('Example05_AgingEffects.m')).
%%
%[text] ## Step 6: the three cases compared
%[text] Plotting the displacement $(\\Delta x, \\Delta y) = xy_\\mathrm{mixture} - xy_\\mathrm{target}$ from a common origin puts the three observers on the same axes. The length of each arrow is the separation measured in Step 5.
%[text] For the standard observer the displacement is exactly zero, which is what the pair was constructed to achieve. The arrow for the alanine variant is short and the arrow for the 70 year old is several times longer.
deltaAla  = xyMixAla  - xyTargetAla;
deltaAged = xyMixAged - xyTargetAged;
f = gcf; f.Position(3:4) = [800 600];
tiledlayout(1, 1); nexttile
plot(0, 0, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 10, ...
    'DisplayName', 'Standard 2-deg (zero displacement)');
hold on
quiver(0, 0, deltaAla(1), deltaAla(2), 0, ...
       'Color', 'r', 'LineWidth', 2, 'MaxHeadSize', 0.4, ...
       'DisplayName', sprintf('Ser180Ala variant (||\\Delta xy|| = %.4f)', shiftAla));
quiver(0, 0, deltaAged(1), deltaAged(2), 0, ...
       'Color', 'b', 'LineWidth', 2, 'MaxHeadSize', 0.4, ...
       'DisplayName', sprintf('70 yr lens aging (||\\Delta xy|| = %.4f)', shiftAged));
hold off
xlabel('\Delta x'); ylabel('\Delta y')
title('Displacement from target to mixture')
legend('Location', 'bestoutside')
axis equal; grid on
% Symmetric limits around origin with margin
lim = 1.2 * max(abs([deltaAla(:); deltaAged(:)]));
xlim([-lim lim]); ylim([-lim lim])
%%
%[text] ## Key takeaways
%[text] - A match made for one observer does not generally hold for another
%[text] - The separation is small for a common polymorphism, about 0.003 in $\\Delta xy$, and several times larger for a strong difference such as an aged lens, about 0.010 at age 70
%[text] - Build any individual observer and integrate a spectrum against `obs.XYZ(wl)` to obtain its tristimulus response
%[text] - `XYZ` applied to an individual observer uses the standard LMS to XYZ matrix and warns accordingly. That is the right choice for comparing observers, but the results are individual colorimetric values and not CIE tristimulus values
%[text] - Observer metamerism is one of the reasons individual cone fundamentals matter in applied colour science. A match verified on the standard observer is not guaranteed to hold for the person who will actually look at it \
%[text] This is the last example in the series. For related material see [Example 13: Observer Comparison](matlab:edit('Example13_ObserverComparison.m')), which compares observers at the level of the cone fundamentals, and [Example 12: Photopic Luminance](matlab:edit('Example12_Luminance.m')), which covers $V^{\\ast}(\\lambda)$ under genotype and age.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

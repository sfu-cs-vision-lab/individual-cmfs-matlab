%[text] # Example 18: Observer Metamerism
%[text] Two spectral power distributions (SPDs) are **metameric** for a given observer if they produce identical cone responses (and hence identical color appearance) despite having different spectra. The CIE 2006 2-deg standard observer sees a vast set of SPD pairs as metameric -- but those same pairs are *not* metameric for every real observer.
%[text] **Observer metamerism** is the phenomenon that a metameric match for one observer breaks for another. If every observer saw the same matches, the CIE Standard Observer would suffice; in practice they don't.
%[text] **Not the same as illuminant metamerism** (two SPDs matching under one illuminant and breaking under another, same observer); that's a separate phenomenon and is not covered here.
%[text] In this example, we:
%[text] - Construct a metameric pair (a target SPD plus a 3-Gaussian mixture) that match exactly for the standard 2-deg observer
%[text] - Switch to an observer with an L-cone polymorphism (Ser180Ala) and watch the match break
%[text] - Quantify the chromaticity shift in CIE xy space
%[text] - See how much the mismatch grows for stronger individual differences (lens aging) \
%[text] **Time:** about 12 minutes.
exampleDefaults();
%%
%[text] ## Step 1: build a metameric pair for the standard observer
%[text] We pick a single Gaussian centered at 555 nm as the target SPD, then construct a mixture of three narrower Gaussian "primaries" (at 460, 540, and 620 nm) whose XYZ tristimulus is identical to the target's. The mixture coefficients come from solving a 3x3 linear system in XYZ space. The primary wavelengths are offset from the target so the mixture isn't a trivial copy.
obsStd = IndividualCMF(StandardObserver=2);
wl = (380:1:780)';
gauss = @(center, width) exp(-((wl - center) / width).^2);
spdTarget = gauss(555, 25);
primaries = [gauss(460, 15), gauss(540, 15), gauss(620, 15)];
%[text] To match the target's XYZ exactly we solve `M*w = t`, where `M` is the 3x3 matrix of primary XYZ values (column j = XYZ of primary j), `t` is the target's XYZ vector, and `w` is the weight vector. Tristimulus values come from integrating the SPD against the observer's XYZ CMFs: `XYZ = sum(SPD .* obs.XYZ(wl), 1)'`.
XYZCmfs = obsStd.XYZ(wl);
XYZTarget = sum(spdTarget .* XYZCmfs, 1)';
XYZPrim = XYZCmfs' * primaries;
weights = XYZPrim \ XYZTarget;
spdMixture = primaries * weights;
%[text] Confirm the two SPDs produce the same XYZ for the standard observer (difference should be machine-precision zero):
XYZMixture = sum(spdMixture .* XYZCmfs, 1)';
table(XYZTarget, XYZMixture, XYZTarget - XYZMixture, ...
      'VariableNames', {'XYZ_target', 'XYZ_mixture', 'Difference'}, ...
      'RowNames', {'X', 'Y', 'Z'})
%[text] **Callout -- negative weights.** This three-Gaussian construction produces a metameric match that requires a negative weight on one primary -- not directly realizable with physical light. The toolbox supports such mathematical metamers; for physical realizability you'd need four or more primaries (or to restrict to positive weights, accepting that perfect XYZ matching is no longer guaranteed).
%%
%[text] ## Step 2: visualize the metameric pair
%[text] The two SPDs are spectrally distinct: one is a broad single Gaussian peaked at 555 nm, the other is a three-Gaussian sum with a tall middle peak and small flanking contributions. They are perceptually identical to the CIE 2006 2-deg standard observer.
f = gcf; f.Position(3:4) = [800 500];
plot(wl, spdTarget, 'k-'); hold on
plot(wl, spdMixture, 'r--')
plot(wl, zeros(size(wl)), 'k:', 'HandleVisibility', 'off')
hold off
xlabel('Wavelength (nm)'); ylabel('Spectral power (arbitrary)')
title('A metameric pair for the CIE 2006 2-deg standard observer')
legend('Target SPD (555 nm Gaussian)', 'Three-Gaussian mixture', ...
       'Location', 'bestoutside')
xlim([380 780])
%%
%[text] ## Step 3: switch to an individual observer and watch the match break
%[text] We construct an observer with the L-cone Alanine variant -- one of the two common L-opsin alleles, present in about 44% of the population. The L-cone lambda-max shifts by about 2.7 nm relative to the standard. We integrate both SPDs against this observer's XYZ CMFs and compare.
obsAla = IndividualCMF(L_OpsinTemplate="Alanine", FieldSize=2);
XYZCmfsAla = obsAla.XYZ(wl);
XYZTargetAla  = sum(spdTarget  .* XYZCmfsAla, 1)';
XYZMixtureAla = sum(spdMixture .* XYZCmfsAla, 1)';
table(XYZTargetAla, XYZMixtureAla, XYZTargetAla - XYZMixtureAla, ...
      'VariableNames', {'XYZ_target', 'XYZ_mixture', 'Difference'}, ...
      'RowNames', {'X', 'Y', 'Z'})
%[text] The X and Y components now differ. The Z component still matches because the LMS-to-XYZ Z-row is proportional to S-cone (the matrix has zero entries for L and M in the Z row), and the L-cone variant change doesn't touch the S-cone shape.
%%
%[text] ## Step 4: quantify the chromaticity shift
%[text] Converting to CIE xy chromaticity separates luminance from chromatic information. We compute xy for the target and the mixture, under both observers.
xyTargetStd  = XYZTarget(1:2)  / sum(XYZTarget);
xyMixStd     = XYZMixture(1:2) / sum(XYZMixture);
xyTargetAla  = XYZTargetAla(1:2)  / sum(XYZTargetAla);
xyMixAla     = XYZMixtureAla(1:2) / sum(XYZMixtureAla);
table([xyTargetStd(1); xyMixStd(1)], [xyTargetStd(2); xyMixStd(2)], ...
      [xyTargetAla(1); xyMixAla(1)], [xyTargetAla(2); xyMixAla(2)], ...
      'VariableNames', {'x_std', 'y_std', 'x_alanine', 'y_alanine'}, ...
      'RowNames', {'Target', 'Mixture'})
%[text] Under the standard observer the target and mixture coincide exactly. Under the Alanine observer they separate by a small but measurable amount in xy space.
%%
%[text] ## Step 5: a stronger observer difference
%[text] The Ser180Ala polymorphism is the most common L-cone variant. The Euclidean $\\Delta xy = \\sqrt{(\\Delta x)^2 + (\\Delta y)^2}$ we just measured is small -- around 0.003. A 70-year-old with strong lens yellowing produces a much larger displacement.
obsAged = IndividualCMF(LensModel="VanDeKraats2007", Age=70, FieldSize=2);
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
%[text] The 70-year-old's Euclidean $\\Delta xy$ is roughly three to four times larger than the polymorphism's. Lens yellowing is a systematic source of observer metamerism in older viewers.
%%
%[text] ## Step 6: metameric break vectors
%[text] Plotting the displacement $(\\Delta x, \\Delta y) = xy_\\mathrm{mixture} - xy_\\mathrm{target}$ from a common origin makes the three observers directly comparable. The Euclidean length of each arrow is the chromaticity break magnitude. Under the standard observer the displacement is exactly zero; the Alanine arrow is short; the 70-year-old's arrow is several times longer.
deltaAla  = xyMixAla  - xyTargetAla;
deltaAged = xyMixAged - xyTargetAged;
f = gcf; f.Position(3:4) = [800 600];
plot(0, 0, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 10, ...
    'DisplayName', 'Standard 2-deg (zero break)');
hold on
quiver(0, 0, deltaAla(1), deltaAla(2), 0, ...
       'Color', 'r', 'LineWidth', 2, 'MaxHeadSize', 0.4, ...
       'DisplayName', sprintf('Ser180Ala variant (||\\Delta xy|| = %.4f)', shiftAla));
quiver(0, 0, deltaAged(1), deltaAged(2), 0, ...
       'Color', 'b', 'LineWidth', 2, 'MaxHeadSize', 0.4, ...
       'DisplayName', sprintf('70 yr lens aging (||\\Delta xy|| = %.4f)', shiftAged));
hold off
xlabel('\Delta x'); ylabel('\Delta y')
title('Metameric break: Euclidean displacement target \rightarrow mixture')
legend('Location', 'bestoutside')
axis equal; grid on
% Symmetric limits around origin with margin
lim = 1.2 * max(abs([deltaAla(:); deltaAged(:)]));
xlim([-lim lim]); ylim([-lim lim])
%%
%[text] ## Key takeaways
%[text] - A metameric match under one observer is generally NOT metameric for another
%[text] - The Euclidean $\\Delta xy$ is small for common polymorphisms (~0.003) but grows several times larger for strong deviations like lens aging (~0.010 at age 70)
%[text] - Build any individual observer and integrate SPDs against `obs.XYZ(wl)` to compute its tristimulus response
%[text] - Individual cone fundamentals matter for applied color science precisely because of observer metamerism; without it, the CIE standard observer would suffice \
%[text] This is the last example in the series. For related material, see [Example 12: Observer Comparison](matlab:edit('Example12_ObserverComparison.m')) (quantifying observer differences at the CMF level) and [Example 11: Photopic Luminance](matlab:edit('Example11_Luminance.m')) (V*(lambda) under genotype and aging).

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

%[text] # Example 10: Chromaticity Diagrams
%[text] **Chromaticity coordinates** separate color (hue + saturation) from luminance. They are computed by normalizing the LMS tristimulus values:
%[text] $ l = L / (L + M + S) $
%[text] $ m = M / (L + M + S) $
%[text] $ s = S / (L + M + S) = 1 - l - m $
%[text] Since $ l + m + s = 1 $, only two coordinates are needed to specify chromaticity. The **spectral locus** is the curve traced by monochromatic lights through chromaticity space -- all real colors lie inside or on it. \\ 
%[text] **Time:** about 10 minutes.
exampleDefaults();
%%
%[text] ## Computing chromaticity coordinates
%[text] Three equivalent ways to get $l, m$ chromaticity: compute directly from `LMS`, call `obs.evaluate(wl, Data='chromaticity')`, or use the direct `obs.lmChromaticity(wl)` method, which returns an `Nx2` matrix of `[l, m]` (the third coordinate is implicit since $l + m + s = 1$).
obs = IndividualCMF();
wl = (390:1:700)';
lmCoords = obs.lmChromaticity(wl);
l = lmCoords(:,1); m = lmCoords(:,2); s = 1 - l - m;
%[text] At the peak luminance region (555 nm) the three coordinates sum to 1:
idx = find(wl == 555);
table(l(idx), m(idx), s(idx), l(idx)+m(idx)+s(idx), ...
      'VariableNames', {'l', 'm', 's', 'sum'})
%%
%[text] ## The spectral locus
%[text] The closed curve consisting of the monochromatic spectral locus plus the dashed "line of purples" (a non-spectral interpolation between the long-wavelength and short-wavelength endpoints) bounds all physically realisable chromaticities.
mark_wls = [400, 450, 500, 550, 600, 650, 700];
plot(l, m, 'k-'); hold on
for mwl = mark_wls
    j = find(wl == mwl);
    plot(l(j), m(j), 'ko', 'MarkerFaceColor', 'w', 'MarkerSize', 8)
    text(l(j)+0.01, m(j)+0.01, sprintf('%d nm', mwl), 'FontSize', 9)
end
plot([l(end), l(1)], [m(end), m(1)], 'k--', 'LineWidth', 1); hold off
xlabel('l = L / (L + M + S)'); ylabel('m = M / (L + M + S)')
title('lm Chromaticity Diagram'); axis equal
xlim([0 1]); ylim([0 1])
%%
%[text] ## Wavelength-coded spectral locus
%[text] Color-coding the spectral locus by approximate visible wavelength makes the curve more interpretable. The helper function `wavelengthToRGB` lives at the bottom of this script.
n = numel(wl);
colors = zeros(n, 3);
for i = 1:n, colors(i,:) = wavelengthToRGB(wl(i)); end
plot([l(1), l(2)], [m(1), m(2)], '-', 'Color', colors(1,:), 'LineWidth', 3)
hold on
for i = 2:n-1
    plot([l(i), l(i+1)], [m(i), m(i+1)], '-', 'Color', colors(i,:), 'LineWidth', 3)
end
for mwl = mark_wls
    j = find(wl == mwl);
    plot(l(j), m(j), 'ko', 'MarkerFaceColor', colors(j,:), 'MarkerSize', 10)
    text(l(j)+0.015, m(j)+0.015, sprintf('%d nm', mwl), 'FontSize', 9)
end
plot([l(end), l(1)], [m(end), m(1)], 'k--', 'LineWidth', 1); hold off
xlabel('l (L chromaticity)'); ylabel('m (M chromaticity)')
title('lm chromaticity, wavelength-coded'); axis equal
xlim([0 1]); ylim([0 1])
%%
%[text] ## Observer comparison -- 2 deg vs 10 deg
%[text] The 2 deg and 10 deg standard observers trace slightly different spectral loci, primarily because of the macular-pigment difference. The largest divergence is in the short-wavelength region.
obs2  = IndividualCMF(StandardObserver=2);
obs10 = IndividualCMF(StandardObserver=10);
chrom2  = obs2.lmChromaticity(wl);
chrom10 = obs10.lmChromaticity(wl);
plot(chrom2(:,1),  chrom2(:,2),  'b-'); hold on
plot(chrom10(:,1), chrom10(:,2), 'r-'); hold off
xlabel('l'); ylabel('m'); title('Spectral locus: 2 deg (blue) vs 10 deg (red)')
legend('2 deg', '10 deg', 'Location', 'bestoutside'); axis equal
xlim([0 1]); ylim([0 1])
locus_diff = sqrt((chrom2(:,1) - chrom10(:,1)).^2 + (chrom2(:,2) - chrom10(:,2)).^2);
table(max(locus_diff), wl(locus_diff == max(locus_diff)), mean(locus_diff), ...
      'VariableNames', {'MaxDiff', 'AtWavelength_nm', 'MeanDiff'})
%%
%[text] ## Age effects on chromaticity
%[text] Lens yellowing shifts the short-wavelength end of the spectral locus toward higher l values. Use the `VanDeKraats2007` lens model so age actually has an effect (see [Example 04: Aging Effects on Color Vision](matlab:edit('Example04_AgingEffects.m'))). The zoom in the lower-left quadrant makes the divergence clear.
ages = [25, 50, 75];
agecol = lines(numel(ages));
age_observers = IndividualCMF.across('Age', ages, ...
    LensModel="VanDeKraats2007", FieldSize=10);
c1 = age_observers(1).lmChromaticity(wl);
plot(c1(:,1), c1(:,2), 'Color', agecol(1,:), ...
    'DisplayName', sprintf('Age %d', ages(1)))
hold on
for i = 2:numel(ages)
    c = age_observers(i).lmChromaticity(wl);
    plot(c(:,1), c(:,2), 'Color', agecol(i,:), ...
        'DisplayName', sprintf('Age %d', ages(i)))
end
hold off
xlabel('l'); ylabel('m'); title('Spectral locus by age (zoomed to short-\lambda region)')
legend('Location', 'bestoutside')
xlim([0 0.25]); ylim([0 0.25])
%%
%[text] ## `plotChromaticity` wrapper
%[text] `plotChromaticity` produces a styled chromaticity diagram in a single call.
obs.plotChromaticity(Wavelength=wl);
title('Using plotChromaticity()')
%%
%[text] ## CIE xy chromaticity
%[text] The CIE 1931 xy chromaticity diagram is obtained by projective normalization of XYZ. The built-in `xyChromaticity` method delegates to `XYZ` internally (so the same non-standard-observer warnings apply) and returns an `Nx2` matrix of `[x, y]`.
xy = obs.xyChromaticity(wl);
plot(xy(:,1), xy(:,2), 'k-'); hold on
for mwl = mark_wls
    j = find(wl == mwl);
    plot(xy(j,1), xy(j,2), 'ko', 'MarkerFaceColor', wavelengthToRGB(mwl), 'MarkerSize', 10)
    text(xy(j,1)+0.01, xy(j,2)+0.01, sprintf('%d nm', mwl), 'FontSize', 9)
end
plot([xy(end,1), xy(1,1)], [xy(end,2), xy(1,2)], 'k--', 'LineWidth', 1); hold off
xlabel('x = X / (X+Y+Z)'); ylabel('y = Y / (X+Y+Z)')
title('CIE xy chromaticity'); axis equal
xlim([0 0.8]); ylim([0 0.9])
%%
%[text] ## Dichromat case -- the xy error path
%[text] CIE xy is computed from XYZ, and the LMS->XYZ transform is rank-deficient when any cone class is absent (the matrix has no inverse). Rather than silently returning an undefined projection, the toolbox raises `IndividualCMF:XYZUndefinedForDichromat`. To get xy for a dichromat you must supply a custom transformation matrix (see [Example 13: Dichromacy](matlab:edit('Example13_Dichromacy.m'))).
obs_protan = IndividualCMF(); obs_protan.Lod = 0;
try
    obs_protan.xyChromaticity(wl);
catch ME
    disp(ME.identifier)
    disp(ME.message)
end
%%
%[text] ## Key takeaways
%[text] - Chromaticity separates color from luminance via normalization
%[text] - lm coordinates: $ l = L / (L+M+S) $, $ m = M / (L+M+S) $; the third is implicit
%[text] - Direct coordinate access: `lmChromaticity` returns $(l, m)$ via $L/(L+M+S), M/(L+M+S)$; `MacLeodBoynton` returns the equiluminant $(L/(L+M), S/(L+M))$ form (different normalisation, different diagram); `xyChromaticity` returns CIE 1931 $(x, y)$. Use `evaluate(wl, Data='chromaticity')` for the table form.
%[text] - The spectral locus bounds all real colors; non-spectral colors close the diagram via the line of purples
%[text] - 2 deg/10 deg observers differ slightly; age (with `LensModel="VanDeKraats2007"`) shifts the short-$\\lambda$ region
%[text] - CIE xy chromaticity errors for dichromats (LMS->XYZ is rank-deficient); use a custom matrix to override \
%[text] **Next:** [Example 11: Photopic Luminance](matlab:edit('Example11_Luminance.m')) -- V*(lambda) for individual observers and the dichromat luminance reduction.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

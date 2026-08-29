%[text] # Example 11: Chromaticity Diagrams
%[text] Chromaticity coordinates describe a colour independently of how intense it is. They are obtained by dividing each tristimulus value by the sum of all three:
%[text] $ l = L / (L + M + S) $
%[text] $ m = M / (L + M + S) $
%[text] $ s = S / (L + M + S) = 1 - l - m $
%[text] Because the three coordinates sum to 1, only two of them are needed. Note that this removes intensity rather than luminance. Luminance is the weighted sum $aL + bM$, which is a different quantity, and [Example 12](matlab:edit('Example12_Luminance.m')) covers it.
%[text] The **spectrum locus** is the curve traced out by monochromatic lights. Colours that can be produced by real lights fill the region bounded by that curve together with the **line of purples**, which joins its two ends and represents mixtures of long and short wavelengths.
%[text] The spectrum locus is slightly concave at its short-wavelength end, so the line of purples is drawn by convention between the two endpoints rather than between the outermost points of the region. This leaves the stretch from 391 to 425 nm a little outside the drawn boundary, by at most 0.010.
%[text] **Time:** about 10 minutes.
exampleDefaults();
%%
%[text] ## Computing the coordinates
%[text] There are three ways to obtain $l$ and $m$. Compute them from `LMS` directly, call `obs.evaluate(wl, Data='lmChromaticity')` for a table, or call `obs.lmChromaticity(wl)`, which returns an N by 2 array. The third coordinate is not returned, since it follows from the other two.
obs = IndividualCMF();
wl = (390:1:700)';
lmCoords = obs.lmChromaticity(wl);
l = lmCoords(:,1); m = lmCoords(:,2); s = 1 - l - m;
%[text] The table below evaluates all three at 555 nm and confirms that they sum to 1.
idx = find(wl == 555);
table(l(idx), m(idx), s(idx), l(idx)+m(idx)+s(idx), ...
      'VariableNames', {'l', 'm', 's', 'sum'})
%%
%[text] ## The spectrum locus
%[text] The solid curve below is the spectrum locus and the dashed line is the line of purples. Together they enclose the chromaticities that a real light can produce.
mark_wls = [400, 450, 500, 550, 600, 650, 700];
tiledlayout(1, 1); nexttile
plot(l, m, '-', 'Color', IndividualCMF.neutralColor()); hold on
for mwl = mark_wls
    j = find(wl == mwl);
    plot(l(j), m(j), 'ko', 'MarkerFaceColor', 'w', 'MarkerSize', 8)
    text(l(j)+0.01, m(j)+0.01, sprintf('%d nm', mwl), 'FontSize', 9)
end
pPurple = plot([l(end), l(1)], [m(end), m(1)], '--', 'Color', IndividualCMF.neutralColor(), ...
    'LineWidth', 1, 'DisplayName', 'Line of purples'); hold off
legend(pPurple, 'Location', 'best')
xlabel('l = L / (L + M + S)'); ylabel('m = M / (L + M + S)')
title('lm chromaticity diagram'); axis equal
xlim([0 1]); ylim([0 1])
%%
%[text] ## The locus coloured by wavelength
%[text] Colouring the locus by the approximate appearance of each wavelength makes it easier to read. The helper function `wavelengthToRGB` is in `toolbox/examples/utils/`, which `exampleDefaults` adds to the path.
n = numel(wl);
colors = zeros(n, 3);
for i = 1:n, colors(i,:) = wavelengthToRGB(wl(i)); end
tiledlayout(1, 1); nexttile
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
pPurple = plot([l(end), l(1)], [m(end), m(1)], '--', 'Color', IndividualCMF.neutralColor(), ...
    'LineWidth', 1, 'DisplayName', 'Line of purples'); hold off
legend(pPurple, 'Location', 'best')
xlabel('l (L chromaticity)'); ylabel('m (M chromaticity)')
title('lm chromaticity, coloured by wavelength'); axis equal
xlim([0 1]); ylim([0 1])
%%
%[text] ## The two standard observers compared
%[text] The 2 deg and 10 deg observers trace slightly different loci. The macular pigment accounts for most of the difference at short wavelengths, and the difference in photopigment optical density contributes across the whole range. The largest difference is at short wavelengths.
obs2  = IndividualCMF(StandardObserver=2);
obs10 = IndividualCMF(StandardObserver=10);
chrom2  = obs2.lmChromaticity(wl);
chrom10 = obs10.lmChromaticity(wl);
tiledlayout(1, 1); nexttile
plot(chrom2(:,1),  chrom2(:,2),  'b-'); hold on
plot(chrom10(:,1), chrom10(:,2), 'r-'); hold off
xlabel('l'); ylabel('m'); title('Spectrum locus for the 2 deg and 10 deg observers')
legend('2 deg', '10 deg', 'Location', 'bestoutside'); axis equal
xlim([0 1]); ylim([0 1])
%[text] The table gives the distance between the two loci. These are distances in the coordinates of the diagram and not measures of how different the two colours look. A chromaticity diagram is not perceptually uniform, so equal distances in different parts of it do not correspond to equally visible differences. CIELAB and CIEDE2000 were developed to address that.
locus_diff = sqrt((chrom2(:,1) - chrom10(:,1)).^2 + (chrom2(:,2) - chrom10(:,2)).^2);
[maxDiff, iMax] = max(locus_diff);
table(maxDiff, wl(iMax), mean(locus_diff), ...
      'VariableNames', {'MaxDiff', 'AtWavelength_nm', 'MeanDiff'})
%%
%[text] ## The effect of age
%[text] With age, the short-wavelength end of the locus moves to lower values of $l$. At 400 nm, $l$ falls from about 0.065 at age 25 to 0.027 at age 75.
%[text] The reason this happens at all is worth setting out. For a light of a single wavelength, the lens and the macular pigment reduce L, M and S by the same factor, and that factor cancels exactly in a ratio such as $L/(L+M+S)$. Filtering alone therefore has no effect on chromaticity. What does have an effect is the peak normalization applied to each cone separately, which divides the three cones by three different numbers.
%[text] The `VanDeKraats2007` lens model is used here because the default model does not depend on age. See [Example 05](matlab:edit('Example05_AgingEffects.m')).
ages = [25, 50, 75];
agecol = lines(numel(ages));
age_observers = IndividualCMF.across('Age', ages, ...
    LensModel="VanDeKraats2007", FieldSize=10);
c1 = age_observers(1).lmChromaticity(wl);
tiledlayout(1, 1); nexttile
plot(c1(:,1), c1(:,2), 'Color', agecol(1,:), ...
    'DisplayName', sprintf('Age %d', ages(1)))
hold on
for i = 2:numel(ages)
    c = age_observers(i).lmChromaticity(wl);
    plot(c(:,1), c(:,2), 'Color', agecol(i,:), ...
        'DisplayName', sprintf('Age %d', ages(i)))
end
hold off
xlabel('l'); ylabel('m'); title('Spectrum locus by age, short-wavelength end')
legend('Location', 'bestoutside')
xlim([0 0.25]); ylim([0 0.25])
%%
%[text] ## The plotting wrapper
%[text] `plotChromaticity` draws a chromaticity diagram in one call.
obs.plotChromaticity(Wavelength=wl);
title('Using plotChromaticity()')
%%
%[text] ## CIE xy chromaticity
%[text] The CIE xy diagram is obtained from the XYZ tristimulus values in the same way, by dividing each by the sum of all three. `xyChromaticity` returns an N by 2 array. It calls `XYZ` internally, so the warnings described in [Example 02](matlab:edit('Example02_StandardObservers.m')) apply to it as well.
xy = obs.xyChromaticity(wl);
tiledlayout(1, 1); nexttile
plot(xy(:,1), xy(:,2), '-', 'Color', IndividualCMF.neutralColor()); hold on
for mwl = mark_wls
    j = find(wl == mwl);
    plot(xy(j,1), xy(j,2), 'ko', 'MarkerFaceColor', wavelengthToRGB(mwl), 'MarkerSize', 10)
    text(xy(j,1)+0.01, xy(j,2)+0.01, sprintf('%d nm', mwl), 'FontSize', 9)
end
pPurple = plot([xy(end,1), xy(1,1)], [xy(end,2), xy(1,2)], '--', 'Color', IndividualCMF.neutralColor(), ...
    'LineWidth', 1, 'DisplayName', 'Line of purples'); hold off
legend(pPurple, 'Location', 'best')
xlabel('x = X / (X+Y+Z)'); ylabel('y = Y / (X+Y+Z)')
title('CIE xy chromaticity'); axis equal
xlim([-0.05 0.8]); ylim([0 0.9])
%%
%[text] ## Why xy is undefined for a dichromat
%[text] CIE xy is computed from XYZ, and XYZ is computed from LMS by a fixed matrix. That matrix is perfectly invertible. The difficulty lies with the observer rather than with the matrix.
%[text] An observer missing one class of cone produces responses that vary in only two dimensions. Passing them through a transform built for three cone types returns three numbers, but those numbers describe a two-dimensional set of colours using three-dimensional coordinates, and the result cannot be interpreted as a tristimulus value.
%[text] The toolbox raises `IndividualCMF:XYZUndefinedForDichromat` rather than returning it. Supplying a transformation matrix of your own overrides this. See [Example 14](matlab:edit('Example14_Dichromacy.m')).
obs_protan = IndividualCMF(); obs_protan.Lod = 0;
try
    obs_protan.xyChromaticity(wl);
catch ME
    disp(ME.identifier)
    disp(ME.message)
end
%%
%[text] ## Key takeaways
%[text] - Chromaticity coordinates remove intensity, not luminance. Luminance is the weighted sum $aL + bM$
%[text] - The lm coordinates are $l = L/(L+M+S)$ and $m = M/(L+M+S)$. The third follows from these two
%[text] - `lmChromaticity` returns $(l, m)$, `xyChromaticity` returns the CIE $(x, y)$, and `MacLeodBoynton` returns $(aL/(aL+bM),\\ S/(aL+bM))$. The MacLeod-Boynton denominator is luminance rather than the unweighted sum $L+M$, which makes it a different diagram
%[text] - Real colours fill the region bounded by the spectrum locus and the line of purples, which is drawn between the two endpoints by convention
%[text] - The 2 deg and 10 deg observers differ slightly. Age moves the short-wavelength end of the locus, and requires `LensModel="VanDeKraats2007"` to have any effect at all
%[text] - CIE xy raises an error for a dichromat. The reason is that a dichromat's responses span two dimensions, not that the transformation matrix is singular \
%[text] **Next:** [Example 12: Photopic Luminance](matlab:edit('Example12_Luminance.m')). The luminous efficiency function for individual observers.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

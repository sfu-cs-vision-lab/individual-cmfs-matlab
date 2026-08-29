%[text] # Example 13: Observer Comparison
%[text] This example compares two or more observers and measures the differences between them.
%[text] Note that age has no effect on `LensDensity` under the default `LensModel="StockmanRider2023"`. The sections below use `LensModel="VanDeKraats2007"` wherever an age difference is needed. See [Example 05](matlab:edit('Example05_AgingEffects.m')).
%[text] **Time:** about 12 minutes.
exampleDefaults();
%%
%[text] ## Overlaying two observers
%[text] `compareTo` draws the reference observer with solid lines and the comparison observer with dashed lines, on one set of axes.
%[text] Every comparison in this example uses peak-normalized fundamentals, which is the default. The measures reported below, the maximum absolute difference, the root mean square difference and the peak wavelengths, therefore describe differences of shape and not of overall sensitivity. Two observers can differ considerably in how much light they absorb and still show almost no difference here. [Example 05](matlab:edit('Example05_AgingEffects.m')) measures that separately.
wl = (390:1:700)';
obs_ref  = IndividualCMF(StandardObserver=10);
obs_comp = IndividualCMF(LensModel="VanDeKraats2007", Age=60, FieldSize=10);
obs_ref.compareTo(obs_comp, Title="CIE 10 deg standard vs Age 60 (VanDeKraats2007)", Wavelength=wl);
%%
%[text] ## Reading a difference curve
%[text] The shape of a difference curve indicates which quantity produced it. Four cases are worth recognising:
%[text] - **A change in lens density** gives a broad difference of one sign, increasing towards short wavelengths, and present in all three cones at once.
%[text] - **A change in macular pigment** gives a difference confined to a narrow range centred near 457 nm, and none above about 530 nm.
%[text] - **A change in photopigment optical density** widens or narrows each cone about its own peak, through self-screening. The difference is close to symmetric about that peak.
%[text] - **A shift in lambda-max** gives a difference that is positive on one side of the peak and negative on the other, passing through zero near the peak itself. A difference of this shape means the curve moved along the wavelength axis rather than changing width. \
%%
%[text] ## Measuring the difference
%[text] The table reports the largest absolute difference for each cone, the wavelength at which it occurs, and the root mean square difference over the plotted range. The S cone shows the largest difference, since the lens absorbs most at the short wavelengths the S cone depends on.
LMS_ref  = obs_ref.LMS(wl);
LMS_comp = obs_comp.LMS(wl);
diffs = LMS_ref - LMS_comp;
[max_abs, idx] = max(abs(diffs));
table(max_abs', wl(idx), rms(diffs)', ...
      'VariableNames', {'MaxAbsDiff', 'AtWavelength_nm', 'RMSDiff'}, ...
      'RowNames', {'L', 'M', 'S'})
%%
%[text] ## The two observers and their difference
%[text] The upper panel draws both observers and the lower panel draws the difference between them at every wavelength.
%[text] The S cone of the 60 year old observer is not lower overall. It cannot be, since both curves are peak-normalized. What the lens does is change the shape of the normalized S curve and move it to longer wavelengths. The difference is positive below about 447 nm, reaching 0.076 at 420 nm, and negative above it. The largest difference in the whole comparison is -0.097 at 473 nm, which lies in the range where the older observer is the more sensitive of the two. The peak of the normalized S curve moves from 445 to 448 nm.
tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile
plot(wl, LMS_ref(:,1),  'r-'); hold on
plot(wl, LMS_ref(:,2),  'g-')
plot(wl, LMS_ref(:,3),  'b-')
plot(wl, LMS_comp(:,1), 'r--')
plot(wl, LMS_comp(:,2), 'g--')
plot(wl, LMS_comp(:,3), 'b--'); hold off
xlabel('Wavelength (nm)'); ylabel('Sensitivity')
title('Reference (solid) and comparison (dashed)')
grid on; xlim([390 700])
nexttile
plot(wl, diffs(:,1), 'r-'); hold on
plot(wl, diffs(:,2), 'g-')
plot(wl, diffs(:,3), 'b-')
plot(wl, zeros(size(wl)), '--', 'Color', IndividualCMF.neutralColor()); hold off
xlabel('Wavelength (nm)'); ylabel('Sensitivity Difference')
title('Reference minus comparison')
legend('L', 'M', 'S', 'Location', 'bestoutside')
xlim([390 700])
%%
%[text] ## Comparing several observers at once
%[text] The six observers below differ in age, field size and L-cone variant. The table gives the root mean square difference of each against the CIE 10 deg observer.
%[text] The serine variant is closer to the standard observer than the alanine variant is, because the default template is a weighted average of the two in which serine carries the larger weight.
observers = { ...
    IndividualCMF(StandardObserver=10),                                       'Standard 10 deg'; ...
    IndividualCMF(StandardObserver=2),                                        'Standard 2 deg'; ...
    IndividualCMF(LensModel="VanDeKraats2007", Age=25, FieldSize=10),             'Age 25'; ...
    IndividualCMF(LensModel="VanDeKraats2007", Age=70, FieldSize=10),             'Age 70'; ...
    IndividualCMF(L_OpsinTemplate="Serine"),                                  'Ser180 homozygote'; ...
    IndividualCMF(L_OpsinTemplate="Alanine"),                                 'Ala180 homozygote'};
n = size(observers, 1);
ref = observers{1, 1}.LMS(wl);
rms_diffs = zeros(n, 3);
for i = 1:n
    rms_diffs(i, :) = rms(ref - observers{i, 1}.LMS(wl));
end
table(string(observers(:,2)), rms_diffs(:,1), rms_diffs(:,2), rms_diffs(:,3), ...
      'VariableNames', {'Observer', 'RMS_L', 'RMS_M', 'RMS_S'})
%%
%[text] ## The same observers in chromaticity coordinates
%[text] Plotting all six spectrum loci together shows where on the locus the differences appear. The 2 deg observer is separated from the 10 deg observer by its macular pigment. The age and genotype variants lie closer to the standard observer than that.
obscol = lines(n);
chrom1 = observers{1, 1}.lmChromaticity(wl);
tiledlayout(1, 1, 'TileSpacing', 'compact', 'Padding', 'compact'); nexttile
plot(chrom1(:,1), chrom1(:,2), '-', 'Color', obscol(1,:), 'LineWidth', 1.5, ...
    'DisplayName', observers{1, 2})
hold on
for i = 2:n
    chrom = observers{i, 1}.lmChromaticity(wl);
    plot(chrom(:,1), chrom(:,2), '-', 'Color', obscol(i,:), 'LineWidth', 1.5, ...
        'DisplayName', observers{i, 2})
end
hold off
xlabel('l'); ylabel('m'); title('Spectrum locus for six observers')
legend('Location', 'bestoutside'); axis equal
xlim([0 1]); ylim([0 1])
%%
%[text] ## The parameters behind the differences
%[text] The table below lists the parameters that differ between the six observers.
ages = zeros(n,1); fs = zeros(n,1); ld = zeros(n,1); md = zeros(n,1); lod = zeros(n,1); types = strings(n,1);
for i = 1:n
    o = observers{i, 1};
    ages(i) = o.Age; fs(i) = o.FieldSize;
    ld(i)   = o.LensDensity; md(i) = o.MacularDensity; lod(i) = o.Lod;
    types(i) = string(o.Type);
end
table(string(observers(:,2)), ages, fs, ld, md, lod, types, ...
      'VariableNames', {'Observer', 'Age', 'FieldSize', 'LensDensity', 'MacularDensity', 'Lod', 'Type'})
%%
%[text] ## Response at three test wavelengths
%[text] Evaluating each observer at a few single wavelengths gives the differences between them directly, without integrating over a spectrum. The three wavelengths used here, 615, 545 and 465 nm, are near the primaries of a typical display.
test_wls = [615, 545, 465];
resp = zeros(n, 3 * numel(test_wls));
for i = 1:n
    LMS_test = observers{i, 1}.LMS(test_wls(:));
    % Transpose before flattening: LMS_test is wavelengths-by-cones, and
    % reshape runs down columns, so the untransposed form would group by
    % cone while the column names below group by wavelength.
    resp(i, :) = reshape(LMS_test', 1, []);
end
table(string(observers(:,2)), ...
      resp(:,1), resp(:,2), resp(:,3), ...
      resp(:,4), resp(:,5), resp(:,6), ...
      resp(:,7), resp(:,8), resp(:,9), ...
      'VariableNames', {'Observer', ...
        'L_615', 'M_615', 'S_615', ...
        'L_545', 'M_545', 'S_545', ...
        'L_465', 'M_465', 'S_465'})
%%
%[text] ## Peak wavelengths
%[text] Locating each peak on a fine wavelength grid shows the difference of about 3 nm between the serine and alanine variants.
wl_fine = (400:0.1:650)';
peaks = zeros(n, 3);
for i = 1:n
    o = observers{i, 1};
    [~, kL] = max(o.L(wl_fine));
    [~, kM] = max(o.M(wl_fine));
    [~, kS] = max(o.S(wl_fine));
    peaks(i, :) = [wl_fine(kL), wl_fine(kM), wl_fine(kS)];
end
table(string(observers(:,2)), peaks(:,1), peaks(:,2), peaks(:,3), ...
      'VariableNames', {'Observer', 'L_peak_nm', 'M_peak_nm', 'S_peak_nm'})
%%
%[text] ## Comparing the filters directly
%[text] `plotLens(Compare=...)` and `plotMacular(Compare=...)` overlay the filter spectra of two observers in one call. Use them to see the cause of a difference in the cone fundamentals rather than the difference itself.
obs_young = IndividualCMF(LensModel="VanDeKraats2007", Age=25, FieldSize=10);
obs_old   = IndividualCMF(LensModel="VanDeKraats2007", Age=70, FieldSize=10);
% plotLens takes no Wavelength argument, so it evaluates on the default
% 360-830 nm grid, past the VanDeKraats2007 model's 300-700 nm fit. The
% extrapolation is a smooth bounded decay and the warning is switched off
% because model range is not the subject here. See Example 05.
obs_young.ModelRangeWarning = false;
obs_old.ModelRangeWarning = false;
obs_young.plotLens(Compare=obs_old, Title="Lens density at age 25 and age 70");
%%
%[text] ## Macular pigment at the two standard field sizes
obs2  = IndividualCMF(StandardObserver=2);
obs10 = IndividualCMF(StandardObserver=10);
obs2.plotMacular(Compare=obs10, Title="Macular pigment at 2 deg and 10 deg");
%%
%[text] ## Key takeaways
%[text] - `obs.compareTo(other, ...)` overlays two observers in one call
%[text] - `obs.plotLens(Compare=...)` and `obs.plotMacular(Compare=...)` overlay the filter spectra
%[text] - Root mean square and maximum absolute differences measure how far apart two observers are, cone by cone
%[text] - All of these measures use peak-normalized fundamentals, so they describe differences of shape rather than of overall sensitivity
%[text] - The shape of a difference curve indicates its cause. A difference that changes sign at the peak means the curve moved along the wavelength axis
%[text] - Age comparisons need `LensModel="VanDeKraats2007"`, since the default model does not depend on age \
%[text] **Next:** [Example 14: Dichromacy](matlab:edit('Example14_Dichromacy.m')). Modelling a missing cone class with an optical density of zero.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

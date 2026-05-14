%[text] # Example 12: Observer Comparison
%[text] Compare two or more observers and quantify their differences.
%[text] **Reminder:** age has no effect on `LensDensity` under the default `LensModel="StockmanRider2023"`. The sections below use `LensModel="VanDeKraats2007"` whenever an age contrast is needed (see [Example 04](matlab:edit('Example04_AgingEffects.m'))).
%[text] **Time:** about 12 minutes.
exampleDefaults();
%%
%[text] ## `compareTo` -- quick visual comparison
%[text] The `compareTo` method overlays the reference observer (solid lines) and a comparison observer (dashed) on a single axis.
wl = (390:1:700)';
obs_ref  = IndividualCMF(StandardObserver=10);
obs_comp = IndividualCMF(LensModel="VanDeKraats2007", Age=60, FieldSize=10);
obs_ref.compareTo(obs_comp, Title="CIE 10 deg standard vs Age 60 (VanDeKraats2007)", Wavelength=wl);
%%
%[text] ## Quantifying the difference
%[text] Statistics for the reference-vs-comparison pair: maximum absolute difference, the wavelength where it occurs, and RMS difference. The S-cone change dominates because lens yellowing affects short wavelengths most.
LMS_ref  = obs_ref.LMS(wl);
LMS_comp = obs_comp.LMS(wl);
diffs = LMS_ref - LMS_comp;
[max_abs, idx] = max(abs(diffs));
table(max_abs', wl(idx), rms(diffs)', ...
      'VariableNames', {'MaxAbsDiff', 'AtWavelength_nm', 'RMSDiff'}, ...
      'RowNames', {'L', 'M', 'S'})
%%
%[text] ## Overlay and difference plots
%[text] **Top:** both observers overlaid. **Bottom:** the residual at every wavelength. The 60-year-old observer shows reduced S-cone amplitude across the short-wavelength region.
tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile
plot(wl, LMS_ref(:,1),  'r-'); hold on
plot(wl, LMS_ref(:,2),  'g-')
plot(wl, LMS_ref(:,3),  'b-')
plot(wl, LMS_comp(:,1), 'r--')
plot(wl, LMS_comp(:,2), 'g--')
plot(wl, LMS_comp(:,3), 'b--'); hold off
xlabel('Wavelength (nm)'); ylabel('Sensitivity')
title('Reference (solid) vs Comparison (dashed)')
grid on; xlim([390 700])
nexttile
plot(wl, diffs(:,1), 'r-'); hold on
plot(wl, diffs(:,2), 'g-')
plot(wl, diffs(:,3), 'b-')
plot(wl, zeros(size(wl)), 'k--'); hold off
xlabel('Wavelength (nm)'); ylabel('Sensitivity Difference')
title('Reference - Comparison')
legend('L', 'M', 'S', 'Location', 'bestoutside')
xlim([390 700])
%%
%[text] ## Multi-observer comparison
%[text] Build a small population of observers covering different ages, field sizes, and L-cone variants, then compute RMS differences against the CIE 10 deg reference. The Serine variant (Ser180Ala = Ser) is closest to the population mean; Alanine differs more.
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
%[text] ## Spectral locus comparison
%[text] Plotting all six observers in chromaticity space shows where the differences land on the locus. The 2 deg observer is offset from 10 deg because of macular pigment; the age and genotype variants pull the locus into nearby positions.
obscol = lines(n);
chrom1 = observers{1, 1}.evaluate(wl, Data='chromaticity', Format='array');
tiledlayout(1, 1, 'TileSpacing', 'compact', 'Padding', 'compact'); nexttile
plot(chrom1(:,1), chrom1(:,2), '-', 'Color', obscol(1,:), 'LineWidth', 1.5, ...
    'DisplayName', observers{1, 2})
hold on
for i = 2:n
    chrom = observers{i, 1}.evaluate(wl, Data='chromaticity', Format='array');
    plot(chrom(:,1), chrom(:,2), '-', 'Color', obscol(i,:), 'LineWidth', 1.5, ...
        'DisplayName', observers{i, 2})
end
hold off
xlabel('l'); ylabel('m'); title('Spectral loci -- multi-observer overlay')
legend('Location', 'bestoutside'); axis equal
xlim([0 1]); ylim([0 1])
%%
%[text] ## Parameter summary table
%[text] What's actually different between these observers? The summary makes the parameter axis explicit.
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
%[text] ## Response to monochromatic test wavelengths
%[text] Evaluating each observer at a small set of spectral test wavelengths -- typical display primary lines at 615 / 545 / 465 nm -- gives a direct readout of the per-observer LMS difference at points where the standard observers themselves are well-defined. No SPD integration required; the difference is just the observer pipeline.
test_wls = [615, 545, 465];
resp = zeros(n, 3 * numel(test_wls));
for i = 1:n
    LMS_test = observers{i, 1}.LMS(test_wls(:));
    resp(i, :) = reshape(LMS_test, 1, []);
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
%[text] ## Peak wavelengths across the observer population
%[text] Locating each cone's peak at fine resolution exposes the small (~3 nm) shift between Serine and Alanine variants.
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
%[text] ## Comparing pre-receptoral filtering directly
%[text] `plotLens(Compare=...)` and `plotMacular(Compare=...)` overlay two observers' filter spectra in a single call. Use them when you want to see the cause of an LMS difference rather than the LMS itself.
obs_young = IndividualCMF(LensModel="VanDeKraats2007", Age=25, FieldSize=10);
obs_old   = IndividualCMF(LensModel="VanDeKraats2007", Age=70, FieldSize=10);
obs_young.plotLens(Compare=obs_old, Title="Lens density -- Age 25 vs Age 70");
%%
%[text] ## 2 deg vs 10 deg macular pigment
obs2  = IndividualCMF(StandardObserver=2);
obs10 = IndividualCMF(StandardObserver=10);
obs2.plotMacular(Compare=obs10, Title="Macular pigment -- 2 deg vs 10 deg");
%%
%[text] ## Key takeaways
%[text] - `obs.compareTo(other, ...)` for quick visual overlay
%[text] - `obs.plotLens(Compare=...)`, `obs.plotMacular(Compare=...)` for filter-spectrum overlays
%[text] - RMS / max-abs differences quantify observer similarity per cone
%[text] - For age comparisons, use `LensModel="VanDeKraats2007"` (the default `StockmanRider2023` is age-flat) \
%[text] **Next:** [Example 13: Dichromacy](matlab:edit('Example13_Dichromacy.m')) -- gene-deletion dichromacy via `Lod`/`Mod`/`Sod` = 0.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

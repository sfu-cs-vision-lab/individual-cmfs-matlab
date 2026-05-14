%[text] # Example 11: Photopic Luminance V*(lambda)
%[text] The **photopic luminous efficiency function** $V^{*}(\\lambda)$ describes how the visual system weights different wavelengths when computing brightness. It is the y-bar row of the CIE 170-2:2015 LMS-to-XYZ transform, i.e. a linear combination of the L- and M-cone fundamentals:
%[text] $ V^*(\\lambda) = a \\bar{L}(\\lambda) + b \\bar{M}(\\lambda) $
%[text] where the coefficients $(a, b)$ are field-size dependent: $(0.6899, 0.3483)$ for the 2° observer and $(0.6928, 0.3497)$ for the 10° observer. Sharpe et al. (2005) measured these directly in 40 genotyped observers; the CIE adopted them in CIE 170-2:2015.
%[text] **Note on fit residuals:** the toolbox's $V^{*}(\\lambda)$ is constructed from the Stockman & Rider (2023) cone fundamentals; it is *not* a direct fit to the CIE tabulated $V^{*}(\\lambda)$. The two agree to better than 1% at the peak.
%[text] **Time:** about 8 minutes.
exampleDefaults();
%%
%[text] ## Standard observer V*(lambda)
%[text] For both standard observers, $V^{*}(\\lambda)$ peaks near 1.0 at 555 nm. The 2-deg and 10-deg curves are nearly identical -- the L:M weighting in luminance is almost field-size invariant.
wl = (380:1:780)';
obs2  = IndividualCMF(StandardObserver=2);
obs10 = IndividualCMF(StandardObserver=10);
plot(wl, obs2.Luminance(wl),  'b-'); hold on
plot(wl, obs10.Luminance(wl), 'r-'); hold off
xlabel('Wavelength (nm)'); ylabel('V^*(\lambda)')
title('Standard observer luminous efficiency')
legend('2 deg', '10 deg', 'Location', 'bestoutside')
xlim([380 780])
%%
%[text] ## Peak wavelength and value
%[text] The peak of $V^{*}(\\lambda)$ lies within ~1 nm of 555 nm for the standard observer. The small (<1%) deviation from exactly 1.0 reflects the Stockman-Rider 2023 Fourier polynomial fit residual vs the tabulated CIE 170-2:2015 values.
[peak2, idx2]   = max(obs2.Luminance(wl));
[peak10, idx10] = max(obs10.Luminance(wl));
table([peak2; peak10], [wl(idx2); wl(idx10)], ...
      'VariableNames', {'PeakValue', 'PeakWavelength_nm'}, ...
      'RowNames', {'2-deg', '10-deg'})
%%
%[text] ## Individual variation: L-cone genotype
%[text] Because $V^{*}(\\lambda)$ depends on the L-cone shape, observers with different L-opsin variants have shifted luminous efficiency functions. The L-Ser180 / L-Ala180 polymorphism produces a ~3 nm shift in the L-cone lambda-max, which translates into a visible shift of the long-wavelength flank of $V^{*}(\\lambda)$. Sharpe et al. (2005) measured $V^{*}$ in 40 genotyped observers and used those data to derive the CIE 170-2:2015 luminance coefficients $(a, b)$.
obs_ser = IndividualCMF(L_OpsinTemplate="Serine");
obs_ala = IndividualCMF(L_OpsinTemplate="Alanine");
plot(wl, obs_ser.Luminance(wl), 'r-'); hold on
plot(wl, obs_ala.Luminance(wl), 'r--'); hold off
xlabel('Wavelength (nm)'); ylabel('V^*(\lambda)')
title('L-cone Ser180Ala polymorphism effect on V^*')
legend('L-Serine', 'L-Alanine', 'Location', 'bestoutside')
xlim([500 700])
%%
%[text] ## Age effect via lens yellowing
%[text] As the lens yellows with age, short-wavelength light is increasingly absorbed before reaching the photoreceptors. With the `VanDeKraats2007` lens model, $V^{*}(\\lambda)$ drops on the short-wavelength flank for older observers while the long-wavelength side is essentially unchanged.
ages = [25, 50, 75];
agecol = lines(numel(ages));
age_observers = IndividualCMF.across('Age', ages, ...
    LensModel="VanDeKraats2007", FieldSize=10);
plot(wl, age_observers(1).Luminance(wl), 'Color', agecol(1,:), ...
    'DisplayName', sprintf('Age %d', ages(1)))
hold on
for i = 2:numel(ages)
    plot(wl, age_observers(i).Luminance(wl), 'Color', agecol(i,:), ...
        'DisplayName', sprintf('Age %d', ages(i)))
end
hold off
xlabel('Wavelength (nm)'); ylabel('V^*(\lambda)')
title('V^* under age-dependent lens yellowing (VanDeKraats2007)')
legend('Location', 'bestoutside')
xlim([380 700])
%%
%[text] ## Dichromat luminance reduction
%[text] For a dichromat, $V^{*}(\\lambda)$ reduces analytically to a single-cone contribution:
%[text] - **Protanope** (`Lod=0`): $V^*(\\lambda) = b \\bar{M}(\\lambda)$
%[text] - **Deuteranope** (`Mod=0`): $V^*(\\lambda) = a \\bar{L}(\\lambda)$
%[text] - **Tritanope** (`Sod=0`): $V^{*}(\\lambda)$ unchanged (S not in $V^{*}$) \
%[text] The protanope and deuteranope curves peak lower than the standard observer because only one of the two L+M contributions remains.
proto = IndividualCMF(Lod=0);
deut  = IndividualCMF(Mod=0);
trit  = IndividualCMF(Sod=0);
plot(wl, obs10.Luminance(wl), 'k-'); hold on
plot(wl, proto.Luminance(wl), 'r--')
plot(wl, deut.Luminance(wl),  'g--')
plot(wl, trit.Luminance(wl),  'b:'); hold off
xlabel('Wavelength (nm)'); ylabel('V^*(\lambda)')
title('V^* for dichromat observers')
legend('Standard 10-deg', 'Protanope (b M-bar)', 'Deuteranope (a L-bar)', ...
       'Tritanope (= standard)', 'Location', 'bestoutside')
xlim([380 780])
%%
%[text] ## MacLeod-Boynton chromaticity
%[text] MacLeod-Boynton chromaticity belongs with $V^{*}(\\lambda)$ because its denominator *is* $V^{*}(\\lambda)$: $l_{MB} = aL/(aL + bM)$ and $s_{MB} = S/(aL + bM)$ use the same $(a, b)$ luminance coefficients. The result isolates the L-vs-M opponent axis from the S-cone axis, and is widely used in color vision deficiency and post-receptoral processing research. `l_{MB}` is bounded in $[0, 1]$; `s_{MB}` is unbounded and peaks near the S-cone wavelength.
wl_mb = (390:1:700)';
mb = obs10.MacLeodBoynton(wl_mb);
l_mb = mb(:,1); s_mb = mb(:,2);
mark_wls = [400, 450, 500, 550, 600, 650, 700];
plot(l_mb, s_mb, 'k-'); hold on
for mwl = mark_wls
    j = find(wl_mb == mwl);
    plot(l_mb(j), s_mb(j), 'ko', 'MarkerFaceColor', wavelengthToRGB(mwl), 'MarkerSize', 10)
    text(l_mb(j)+0.01, s_mb(j)+0.02, sprintf('%d', mwl), 'FontSize', 9)
end
hold off
xlabel('l_{MB} = a L / (a L + b M)'); ylabel('s_{MB} = S / (a L + b M)')
title('MacLeod-Boynton diagram')
%%
%[text] ## Photometric calculations
%[text] Once you have $V^{*}(\\lambda)$ for an observer, you can compute luminance for an arbitrary spectral power distribution (SPD). For an SPD $\\Phi(\\lambda)$ in watts per nanometer, the luminance is:
%[text] $ L_v = K_m \\int \\Phi(\\lambda) V^*(\\lambda) d\\lambda $
%[text] where $K_m = 683$ lm/W is the photopic maximum luminous efficacy. As a quick example, the luminance of a 555 nm monochromatic 1 W source is exactly $K_m$ lumens for the standard observer (by definition); under our SR2023 fit residual it lands within 1% of that.
Km = 683;
wlFine = (380:0.5:780)';
Vstar = obs10.Luminance(wlFine);
% Model a 555 nm 1 W source as a unit-mass delta function at 555 nm.
spd = double(abs(wlFine - 555) < 0.5);
spd = spd / sum(spd);
Lv = Km * sum(spd .* Vstar);
table(Lv, Km, Lv / Km, ...
      'VariableNames', {'Lv_lumens', 'Km_lmPerWatt', 'EfficiencyRatio'})
%%
%[text] ## Key takeaways
%[text] - $V^{*}(\\lambda)$ is the y-bar row of the CIE 170-2:2015 LMS-to-XYZ matrix; the `Luminance` method exposes it
%[text] - It always uses energy-normalized LMS regardless of the observer's `OutputFormat`
%[text] - Genotype and lens aging produce visible individual differences in $V^{*}(\\lambda)$
%[text] - For dichromats, $V^{*}(\\lambda)$ reduces to the residual cone's contribution -- protanopes lose roughly two-thirds of standard luminance ($b \\approx 0.35$); deuteranopes lose roughly one-third ($a \\approx 0.69$) \
%[text] **Next:** [Example 12: Observer Comparison](matlab:edit('Example12_ObserverComparison.m')) -- visual and quantitative observer-vs-observer comparison.
%[text]

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

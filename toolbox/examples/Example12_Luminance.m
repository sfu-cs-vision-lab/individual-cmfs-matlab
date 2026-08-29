%[text] # Example 12: Photopic Luminance V*(lambda)
%[text] The **photopic luminous efficiency function** $V^{*}(\\lambda)$ describes how the visual system weights different wavelengths when computing luminance -- the quantity flicker photometry and additive matching measure. Luminance is not brightness: brightness carries chromatic contributions (the Helmholtz-Kohlrausch effect) that $V^{*}$ deliberately excludes. Nor is $V^{*}$ the 1924 $V(\\lambda)$, which underestimates short-wavelength sensitivity; it is the cone-fundamental-based successor. It is the y-bar row of the CIE 170-2:2015 LMS-to-XYZ transform, i.e. a linear combination of the L- and M-cone fundamentals:
%[text] $ V^*(\\lambda) = a \\bar{L}(\\lambda) + b \\bar{M}(\\lambda) $
%[text] where the coefficients $(a, b)$ are field-size dependent: $(0.6899, 0.3483)$ for the 2 deg observer and $(0.6928, 0.3497)$ for the 10 deg observer. Sharpe et al. (2005) measured these directly in 40 genotyped observers; the CIE adopted them in CIE 170-2:2015.
%[text] **Note on fit residuals:** the toolbox's $V^{*}(\\lambda)$ is constructed from the Stockman & Rider (2023) cone fundamentals; it is *not* a direct fit to the CIE tabulated $V^{*}(\\lambda)$. The two agree to better than 1% at the peak.
%[text] **Time:** about 8 minutes.
exampleDefaults();
%%
%[text] ## Standard observer V*(lambda)
%[text] For both standard observers, $V^{*}(\\lambda)$ peaks near 1.0 at 555 nm. The L:M weighting is nearly field-size invariant (0.6899/0.3483 against 0.6928/0.3497), but the curves are not: below 500 nm they diverge by up to about 66% in relative terms, where the 10 deg observer carries far less macular pigment. The gap itself is plain on the linear axis -- 0.052 at 457 nm on a curve peaking at 1.0 -- but the axis understates how large it is proportionally.
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
%[text] Because $V^{*}(\\lambda)$ depends on the L-cone shape, observers with different L-opsin variants have shifted luminous efficiency functions. The L-Ser180 / L-Ala180 polymorphism produces a 2.7 nm shift in the L-cone photopigment lambda-max, which translates into a visible shift of the long-wavelength flank of $V^{*}(\\lambda)$. Sharpe et al. (2005) measured $V^{*}$ in 40 genotyped observers and used those data to derive the CIE 170-2:2015 luminance coefficients $(a, b)$.
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
%[text] As the lens yellows with age, short-wavelength light is increasingly absorbed before reaching the photoreceptors. With the `VanDeKraats2007` lens model, $V^{*}(\\lambda)$ drops on the short-wavelength flank for older observers while the long-wavelength side moves less, though not by nothing -- it rises 7 to 11 percent between ages 25 and 75 as renormalization lifts what the lens did not attenuate, and the V* peak itself walks from 551 to 558 nm.
ages = [25, 50, 75];
agecol = lines(numel(ages));
%[text] The `VanDeKraats2007` lens is fitted on 300-700 nm, so evaluating it past 700 raises `IndividualCMF:WavelengthOutOfRange` once per observer. The extrapolation there is a smooth bounded decay and the values are kept; the warning is silenced below because model range is not what this example is about. See [Example 05](matlab:edit('Example05_AgingEffects.m')) for the `ValidRange` / `Domain` contract.
age_observers = IndividualCMF.across('Age', ages, ...
    LensModel="VanDeKraats2007", FieldSize=10);
[age_observers.ModelRangeWarning] = deal(false);
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
plot(wl, obs10.Luminance(wl), '-', 'Color', IndividualCMF.neutralColor()); hold on
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
%[text] MacLeod-Boynton chromaticity belongs with $V^{*}(\\lambda)$ because its denominator *is* $V^{*}(\\lambda)$: $l_{MB} = aL/(aL + bM)$ and $s_{MB} = S/(aL + bM)$ use the same $(a, b)$ luminance coefficients. The result isolates the L-vs-M opponent axis from the S-cone axis, and is widely used in color vision deficiency and post-receptoral processing research. `l_{MB}` is bounded in $[0, 1]$. `s_{MB}` has no upper bound -- its scale depends on an S normalization convention that this toolbox does not apply -- and it climbs toward short wavelengths, reaching its maximum near 417 nm on this grid rather than at the S-cone lambda-max, because the luminance denominator collapses faster than $\\bar{s}$ does. Most published MB diagrams rescale $s$ so its maximum is 1, and both versions are drawn below. Rescaling is a linear change, so the two panels have the same shape and differ only in what the $s$ axis reads -- the point of showing both is that this toolbox hands you the upper one. The long-wavelength arm lies flat against the axis either way: $s$ is of order $10^{-5}$ from 550 nm out, against a maximum of 18, which is a real property of the diagram rather than a scaling artefact. That arm is where the $l_{MB}$ axis does its work, spreading 550 to 700 nm across $l_{MB}$ from 0.66 to 0.97 at essentially constant $s$.
wl_mb = (390:1:700)';
mb = obs10.MacLeodBoynton(wl_mb);
l_mb = mb(:,1); s_mb = mb(:,2);
mark_wls = [400, 450, 500, 550, 600, 650, 700];
tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile
plot(l_mb, s_mb, '-', 'Color', IndividualCMF.neutralColor()); hold on
for mwl = mark_wls
    j = find(wl_mb == mwl);
    plot(l_mb(j), s_mb(j), 'ko', 'MarkerFaceColor', wavelengthToRGB(mwl), 'MarkerSize', 8)
end
hold off
xlabel('l_{MB}'); ylabel('s_{MB} (unscaled)')
title('As the toolbox returns it: s runs to 18')
nexttile
plot(l_mb, s_mb / max(s_mb), '-', 'Color', IndividualCMF.neutralColor()); hold on
for mwl = mark_wls
    j = find(wl_mb == mwl);
    plot(l_mb(j), s_mb(j)/max(s_mb), 'ko', 'MarkerFaceColor', wavelengthToRGB(mwl), 'MarkerSize', 8)
    text(l_mb(j)+0.012, s_mb(j)/max(s_mb)+0.03, sprintf('%d', mwl), 'FontSize', 9)
end
hold off
xlabel('l_{MB} = a L / (a L + b M)'); ylabel('s_{MB} / max(s_{MB})')
title('Rescaled to max(s) = 1: the published convention, same shape')
%%
%[text] ## Photometric calculations
%[text] Once you have $V^{*}(\\lambda)$ for an observer, you can compute photometric quantities for an arbitrary spectral power distribution (SPD). For a radiant flux spectrum $\\Phi_e(\\lambda)$ in watts per nanometer, the luminous **flux** is:
%[text] $ \\Phi_v = K_m \\int \\Phi_e(\\lambda) V^*(\\lambda) d\\lambda $
%[text] where $K_m = 683$ lm/W is the maximum luminous efficacy. Lumens measure luminous flux, not luminance -- luminance is cd/m$^2$ and needs a geometry this SPD does not carry. A 555 nm monochromatic 1 W source therefore gives a luminous flux of $K_m V^{*}(555)$, about 683 lm. Note "about": the SI fixes 683 lm/W at 540 THz against the 1924 $V(\\lambda)$, so pairing it with $V^{*}$ is a modelling convention rather than a definition, and the SR2023 fit residual puts the result within 1% of $K_m$.
Km = 683;
wlFine = (380:0.5:780)';
Vstar = obs10.Luminance(wlFine);
% Model a 555 nm 1 W source as a unit-mass delta function at 555 nm.
spd = double(abs(wlFine - 555) < 0.5);
spd = spd / sum(spd);
Phi_v = Km * sum(spd .* Vstar);
table(Phi_v, Km, Phi_v / Km, ...
      'VariableNames', {'LuminousFlux_lm', 'Km_lmPerWatt', 'EfficiencyRatio'})
%%
%[text] ## Key takeaways
%[text] - $V^{*}(\\lambda)$ is the y-bar row of the CIE 170-2:2015 LMS-to-XYZ matrix; the `Luminance` method exposes it
%[text] - It always uses energy-normalized LMS regardless of the observer's `OutputFormat`
%[text] - Genotype and lens aging produce visible individual differences in $V^{*}(\\lambda)$
%[text] - For dichromats, $V^{*}(\\lambda)$ reduces to the residual cone's contribution -- in this unrenormalized formulation a protanope retains only the $bM$ term (peak $\\approx 0.35$) and a deuteranope only $aL$ (peak $\\approx 0.69$). Real dichromat luminous efficiency is conventionally renormalized, which changes the picture: a renormalized protanope loses at long wavelengths (0.13 of standard at 650 nm) but a renormalized deuteranope slightly *gains* there (1.39 at 650 nm), so this is a reshaping rather than a uniform dimming \
%[text] - Dichromacy in depth -- how zero optical density models it, and what the other derived quantities do -- is [Example 14](matlab:edit('Example14_Dichromacy.m')), which carries no luminance content of its own \\
%[text] **Next:** [Example 13: Observer Comparison](matlab:edit('Example13_ObserverComparison.m')) -- visual and quantitative observer-vs-observer comparison.
%[text]

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

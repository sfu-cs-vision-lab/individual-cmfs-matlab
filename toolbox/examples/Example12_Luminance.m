%[text] # Example 12: Photopic Luminance V*(lambda)
%[text] The photopic luminous efficiency function $V^{\\ast}(\\lambda)$ gives the weight the visual system attaches to each wavelength when luminance is computed. Luminance is the quantity that flicker photometry and additive matching measure.
%[text] Luminance is not brightness. Brightness includes a contribution from the colour of the light, known as the Helmholtz-Kohlrausch effect, which $V^{\\ast}$ deliberately leaves out.
%[text] $V^{\\ast}(\\lambda)$ is also not the 1924 $V(\\lambda)$ function, which underestimates sensitivity at short wavelengths. It is the later function based on the cone fundamentals, and it is the y-bar row of the CIE 170-2:2015 transform from LMS to XYZ. That makes it a weighted sum of the L and M cone fundamentals:
%[text] $ V^{\\ast}(\\lambda) = a \\bar{L}(\\lambda) + b \\bar{M}(\\lambda) $
%[text] The coefficients depend on field size. They are $(0.6899, 0.3483)$ for the 2 deg observer and $(0.6928, 0.3497)$ for the 10 deg observer. Sharpe et al. (2005) measured them in 40 observers of known genotype, and the CIE adopted them in CIE 170-2:2015.
%[text] The toolbox computes $V^{\\ast}(\\lambda)$ from the Stockman and Rider (2023) cone fundamentals rather than fitting the tabulated CIE function directly. The two agree to better than 1% at the peak.
%[text] **Time:** about 12 minutes.
exampleDefaults();
%%
%[text] ## The two standard observers
%[text] For both standard observers $V^{\\ast}(\\lambda)$ peaks near 1.0 at 555 nm.
%[text] The relative weighting of L and M barely changes with field size, from 0.6899 and 0.3483 to 0.6928 and 0.3497. The curves themselves do change. Below 500 nm they differ by up to about 66% in relative terms, because the 10 deg observer has much less macular pigment.
%[text] On the linear axis that difference looks small, since it is 0.052 at 457 nm on a curve whose peak is 1.0. The linear axis understates it, because at that wavelength both curves are already far below their peaks.
wl = (380:1:780)';
obs2  = IndividualCMF(StandardObserver=2);
obs10 = IndividualCMF(StandardObserver=10);
tiledlayout(1, 1); nexttile
plot(wl, obs2.Luminance(wl),  'b-'); hold on
plot(wl, obs10.Luminance(wl), 'r-'); hold off
xlabel('Wavelength (nm)'); ylabel('V^*(\lambda)')
title('Luminous efficiency of the two standard observers')
legend('2 deg', '10 deg', 'Location', 'bestoutside')
xlim([380 780])
%%
%[text] ## The peak
%[text] The peak lies within about 1 nm of 555 nm for both standard observers. It is not exactly 1.0. The difference of less than 1% is the residual of the Stockman and Rider Fourier fit against the tabulated CIE 170-2:2015 values.
[peak2, idx2]   = max(obs2.Luminance(wl));
[peak10, idx10] = max(obs10.Luminance(wl));
table([peak2; peak10], [wl(idx2); wl(idx10)], ...
      'VariableNames', {'PeakValue', 'PeakWavelength_nm'}, ...
      'RowNames', {'2-deg', '10-deg'})
%%
%[text] ## The effect of L-cone genotype
%[text] $V^{\\ast}(\\lambda)$ depends on the shape of the L cone, so observers carrying different L-opsin variants have different luminous efficiency functions. The Ser180Ala polymorphism moves the L photopigment lambda-max by 2.7 nm, and that moves $V^{\\ast}(\\lambda)$ at long wavelengths.
%[text] This is the individual variation that Sharpe et al. (2005) measured in order to derive the coefficients $(a, b)$ now in CIE 170-2:2015.
obs_ser = IndividualCMF(L_OpsinTemplate="Serine");
obs_ala = IndividualCMF(L_OpsinTemplate="Alanine");
tiledlayout(1, 1); nexttile
plot(wl, obs_ser.Luminance(wl), 'r-'); hold on
plot(wl, obs_ala.Luminance(wl), 'r--'); hold off
xlabel('Wavelength (nm)'); ylabel('V^*(\lambda)')
title('Effect of the Ser180Ala polymorphism on V^*')
legend('L-Serine', 'L-Alanine', 'Location', 'bestoutside')
xlim([500 700])
%%
%[text] ## The effect of age
%[text] As the lens absorbs more short-wavelength light with age, $V^{\\ast}(\\lambda)$ decreases at short wavelengths.
%[text] At long wavelengths it increases instead, by 7 to 11 percent between ages 25 and 75. The lens absorbs almost nothing there, so normalization raises those wavelengths relative to the short ones that were reduced. The peak of $V^{\\ast}$ also moves from 551 to 558 nm.
%[text] The `VanDeKraats2007` model is used because the default lens model does not depend on age. It was fitted over 300 to 700 nm, so evaluating it beyond 700 nm raises `IndividualCMF:WavelengthOutOfRange` once for each observer. The extrapolation is a smooth decay of bounded size and the values are kept. The warning is switched off below because the range of the model is not the subject here. [Example 05](matlab:edit('Example05_AgingEffects.m')) describes the `ValidRange` and `Domain` behaviour.
ages = [25, 50, 75];
agecol = lines(numel(ages));
age_observers = IndividualCMF.across('Age', ages, ...
    LensModel="VanDeKraats2007", FieldSize=10);
[age_observers.ModelRangeWarning] = deal(false);
tiledlayout(1, 1); nexttile
plot(wl, age_observers(1).Luminance(wl), 'Color', agecol(1,:), ...
    'DisplayName', sprintf('Age %d', ages(1)))
hold on
for i = 2:numel(ages)
    plot(wl, age_observers(i).Luminance(wl), 'Color', agecol(i,:), ...
        'DisplayName', sprintf('Age %d', ages(i)))
end
hold off
xlabel('Wavelength (nm)'); ylabel('V^*(\lambda)')
title('V^* with age, using the VanDeKraats2007 lens model')
legend('Location', 'bestoutside')
xlim([380 700])
%%
%[text] ## Dichromats
%[text] For an observer missing one cone class, $V^{\\ast}(\\lambda)$ reduces to a single term:
%[text] - A **protanope**, set with `Lod=0`, has $V^{\\ast}(\\lambda) = b \\bar{M}(\\lambda)$.
%[text] - A **deuteranope**, set with `Mod=0`, has $V^{\\ast}(\\lambda) = a \\bar{L}(\\lambda)$.
%[text] - A **tritanope**, set with `Sod=0`, has $V^{\\ast}(\\lambda)$ unchanged, since the S cone does not appear in it. \
%[text] The protanope and deuteranope curves have lower peaks than the standard observer, because only one of the two terms remains and the result is not rescaled.
proto = IndividualCMF(Lod=0);
deut  = IndividualCMF(Mod=0);
trit  = IndividualCMF(Sod=0);
tiledlayout(1, 1); nexttile
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
%[text] MacLeod-Boynton chromaticity belongs in this example because its denominator is $V^{\\ast}(\\lambda)$. The two coordinates are $l_{MB} = aL/(aL + bM)$ and $s_{MB} = S/(aL + bM)$, using the same coefficients $(a, b)$.
%[text] Dividing by luminance separates the difference between L and M from the S-cone signal. The diagram is widely used in work on colour vision deficiency and on post-receptoral processing.
%[text] The two coordinates behave differently. $l_{MB}$ is bounded between 0 and 1. $s_{MB}$ has no upper bound, because its scale depends on a convention for normalizing S that this toolbox does not apply. It reaches its largest value near 417 nm on this grid rather than at the S-cone lambda-max, because the luminance in the denominator falls faster with decreasing wavelength than $\\bar{s}$ does.
%[text] Most published diagrams rescale $s_{MB}$ so that its maximum is 1. Both forms are drawn below. Rescaling is a linear operation, so the two panels have the same shape and differ only in what the vertical axis reads. They are both shown so that it is clear which one the toolbox returns.
%[text] In both panels the curve runs along the horizontal axis at long wavelengths. From 550 nm upwards $s_{MB}$ is of order $10^{-5}$, against a maximum of 18. That is a property of the diagram rather than an artefact of scaling. It is also the region where $l_{MB}$ carries the information, taking values from 0.66 to 0.97 between 550 and 700 nm while $s_{MB}$ stays effectively constant.
wl_mb = (390:1:700)';
mb = obs10.MacLeodBoynton(wl_mb);
l_mb = mb(:,1); s_mb = mb(:,2);
mark_wls = [400, 450, 500, 550, 600, 650, 700];
tiledlayout(2, 1, 'TileSpacing', 'loose', 'Padding', 'compact');
nexttile
plot(l_mb, s_mb, '-', 'Color', IndividualCMF.neutralColor()); hold on
for mwl = mark_wls
    j = find(wl_mb == mwl);
    plot(l_mb(j), s_mb(j), 'ko', 'MarkerFaceColor', wavelengthToRGB(mwl), 'MarkerSize', 8)
end
hold off
xlabel('l_{MB}'); ylabel('s_{MB} (unscaled)')
title('As the toolbox returns it, with s reaching 18')
nexttile
plot(l_mb, s_mb / max(s_mb), '-', 'Color', IndividualCMF.neutralColor()); hold on
for mwl = mark_wls
    j = find(wl_mb == mwl);
    plot(l_mb(j), s_mb(j)/max(s_mb), 'ko', 'MarkerFaceColor', wavelengthToRGB(mwl), 'MarkerSize', 8)
    text(l_mb(j)+0.012, s_mb(j)/max(s_mb)+0.03, sprintf('%d', mwl), 'FontSize', 9)
end
hold off
xlabel('l_{MB} = a L / (a L + b M)'); ylabel('s_{MB} / max(s_{MB})')
title('Rescaled so that the maximum of s is 1, as usually published')
%%
%[text] ## A photometric calculation
%[text] With $V^{\\ast}(\\lambda)$ for an observer, photometric quantities can be computed for any spectral power distribution. For a radiant flux $\\Phi_e(\\lambda)$ in watts per nanometre, the luminous flux is
%[text] $ \\Phi_v = K_m \\int \\Phi_e(\\lambda) V^{\\ast}(\\lambda) d\\lambda $
%[text] where $K_m = 683$ lm/W is the maximum luminous efficacy.
%[text] Note that lumens measure luminous flux and not luminance. Luminance is measured in cd/m$^2$ and requires a geometry that a spectral power distribution alone does not provide.
%[text] A source of 1 W at 555 nm therefore has a luminous flux of $K_m V^{\\ast}(555)$, which is about 683 lm. The result is approximate for two reasons. The SI definition fixes 683 lm/W at 540 THz against the 1924 $V(\\lambda)$, so using it with $V^{\\ast}$ is a modelling choice rather than a definition, and the residual of the Stockman and Rider fit puts the result within 1% of $K_m$.
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
%[text] - $V^{\\ast}(\\lambda)$ is the y-bar row of the CIE 170-2:2015 transform from LMS to XYZ. The `Luminance` method returns it
%[text] - It always uses normalized fundamentals in energy units, whatever the observer's `OutputFormat` is set to
%[text] - Genotype and age both produce differences in $V^{\\ast}(\\lambda)$ between individuals
%[text] - For a dichromat, $V^{\\ast}(\\lambda)$ keeps only the term for the cone that is present. Without rescaling, a protanope peaks near 0.35 and a deuteranope near 0.69
%[text] - Published dichromat luminous efficiency functions are usually rescaled to a peak of 1, which changes the comparison. A rescaled protanope is less sensitive than the standard observer at long wavelengths, at 0.13 of standard at 650 nm, while a rescaled deuteranope is more sensitive, at 1.39. The difference is a change of shape rather than an overall reduction
%[text] - Dichromacy is covered in [Example 14](matlab:edit('Example14_Dichromacy.m')) \
%[text] **Next:** [Example 13: Observer Comparison](matlab:edit('Example13_ObserverComparison.m')). Comparing two observers, visually and numerically.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

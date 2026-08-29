%[text] # Example 10: RGB Color Matching Functions
%[text] **RGB color matching functions** describe how much of three primary lights are needed to match every spectral color. They are computed from the LMS cone fundamentals via a linear transformation determined by the LMS values at the three primary wavelengths.
%[text] The toolbox uses **Stiles & Burch (1959) 10 deg primaries** by default:
%[text] - R: 645.15 nm (nominally 15 500 cm$^{-1}$, i.e. 645.16 nm; both CIE170 and pycone carry the rounded 645.15)
%[text] - G: 526.32 nm (19 000 cm$^{-1}$)
%[text] - B: 444.44 nm (22 500 cm$^{-1}$) \
%[text] You can also use any custom primary wavelengths to model specific displays. 
%[text] **Time:** about 12 minutes.
exampleDefaults();
%%
%[text] ## Default RGB CMFs
%[text] An observer in default configuration uses the Stiles & Burch 10 deg primaries. The `RGB(wl)` method returns an Nx3 matrix.
obs = IndividualCMF();
wl = (390:1:700)';
RGB = obs.RGB(wl);
table(obs.Primaries(1), obs.Primaries(2), obs.Primaries(3), ...
      'VariableNames', {'R_nm', 'G_nm', 'B_nm'})
%%
%[text] ## Visualizing RGB CMFs
%[text] A word on the experiment these functions come from, because the next paragraph depends on it. An observer views a **split (bipartite) field**: the spectral test light fills one half, an adjustable mixture of the three primaries fills the other, and the primary intensities are adjusted until the two halves look identical. When no positive mixture can match the test light, one primary is moved over to the *test* half instead, and that amount is recorded as a negative value.
%[text] `obs.plotRGBCMFs` is the dedicated wrapper for RGB CMF plots. Note the **negative values** -- particularly in the R curve around 500 nm. Negative tristimulus values mean the spectral test color cannot be matched by an additive mixture of the primaries; the only way to match it is to *add* primary light to the test side, giving a negative coefficient.
obs.plotRGBCMFs(Title="RGB Color Matching Functions (Stiles & Burch 10 deg)", Wavelength=wl);
hold on
xline(obs.Primaries(1), '--', 'Color', [0.5 0.5 0.5], 'HandleVisibility', 'off')
xline(obs.Primaries(2), '--', 'Color', [0.5 0.5 0.5], 'HandleVisibility', 'off')
xline(obs.Primaries(3), '--', 'Color', [0.5 0.5 0.5], 'HandleVisibility', 'off')
hold off
xlim([390 700])
%%
%[text] ## Reading negative values
%[text] At 500 nm the R value is clearly negative (G and B are both positive). This is the classic "you can't match a pure spectral cyan with an RGB mixture" result -- you have to add red to the test side to make the colors agree.
RGB_at_500 = RGB(wl == 500, :);
table(RGB_at_500(1), RGB_at_500(2), RGB_at_500(3), ...
      'VariableNames', {'R_500nm', 'G_500nm', 'B_500nm'})
%%
%[text] ## LMS values at the primaries determine the transform
%[text] The LMS-to-RGB transform is the inverse of the 3x3 matrix `M` whose **column** $j$ is the LMS vector at primary wavelength $\\lambda_j$ (equivalently, row $i$ contains the $i$-th cone's response at the three primaries). After applying that inverse, each primary's wavelength produces a unit vector along its RGB axis.
LMS_at_primaries = obs.LMS(obs.Primaries')
%%
%[text] ## Custom primaries
%[text] Two features of the figure above are worth naming. The dashed grey verticals mark the three primary wavelengths, where by construction one curve reaches 1 and the other two reach 0. And the R curve peaks near 599 nm rather than at its own 645 nm primary: normalization pins R to 1 at 645 nm, which sits well down the L cone's long-wave slope, so the curve rises above 1 where the cones are more sensitive.
%[text] Pass `Primaries` as a 1x3 vector to model any RGB triple. Below: comparing the toolbox default (Stiles & Burch) to a hypothetical display with monochromatic primaries near typical sRGB peak wavelengths. **Note:** sRGB and Adobe RGB are defined by *chromaticity coordinates*, not monochromatic wavelengths. Real displays have broad phosphor/LED emission spectra; the wavelengths used in this section only approximate where their primaries would sit on the spectral locus.
obs_default = IndividualCMF();
obs_sRGB    = IndividualCMF(Primaries=[615, 545, 465]);
tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
obs_default.plotRGBCMFs(Title="Stiles & Burch [645/526/444]", Wavelength=wl, Parent=nexttile);
xlim([390 700])
obs_sRGB.plotRGBCMFs(Title="Custom sRGB-like [615/545/465]", Wavelength=wl, Parent=nexttile);
xlim([390 700])
%%
%[text] ## Display-technology comparison
%[text] Different display systems use different primaries. Adobe RGB's wider gamut comes entirely from a purer **green** -- it shares sRGB's red and blue primaries exactly. The interesting part is where that shows up in the CMFs: not in the green curve, which peaks at 536 nm either way and moves by at most 0.046, but in the **red** one. Pushing the green primary to a shorter wavelength shrinks R's negative lobe from -0.396 to -0.189, a change of 0.277. A negative lobe is the gamut boundary made visible, so widening the gamut is exactly what shrinks it.
%[text] The dominant wavelengths below stand in for each system's primaries; real display primaries are broadband, so this is an approximation (see the caveat above). The Stiles & Burch row is read from the observer so it cannot drift from the toolbox default.
sb = IndividualCMF().Primaries;
disp_specs = ["sRGB";           "Adobe RGB";       "Stiles & Burch"];
disp_R = [611;                  611;               sb(1)];
disp_G = [549;                  532;               sb(2)];
disp_B = [464;                  464;               sb(3)];
tiledlayout(3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
for k = 1:numel(disp_specs)
    prim = [disp_R(k), disp_G(k), disp_B(k)];
    obs_disp = IndividualCMF(Primaries=prim);
    obs_disp.plotRGBCMFs(Title=sprintf('%s [%d/%d/%d]', disp_specs(k), round(prim)), ...
        Wavelength=wl, Parent=nexttile);
    xlim([390 700])
end
%%
%[text] ## Bad primaries: the SingularPrimaries error path
%[text] When primaries are too close together (all in one cone's response region), the LMS-at-primaries matrix becomes near-singular and the toolbox refuses to compute the inverse rather than emit nonsense. Below: three primaries within 2 nm of each other near the L-cone peak.
try
    obs_bad = IndividualCMF(Primaries=[555, 555.5, 556]);
    obs_bad.RGB(550);
catch ME
    disp(ME.identifier)
    disp(ME.message)
end
%%
%[text] ## Key takeaways
%[text] - RGB CMFs are linear transforms of LMS cone fundamentals
%[text] - Default primaries are Stiles & Burch 10 deg (645.15, 526.32, 444.44 nm)
%[text] - `RGB` ignores `OutputFormat`: it always computes from energy-format, peak-normalized fundamentals, so an observer set to quantal or absorbance returns identical RGB CMFs
%[text] - Negative tristimulus values mean the spectral color cannot be matched by an additive mixture
%[text] - Set `Primaries=[R, G, B]` in nm to model any custom display
%[text] - Primaries that don't span the L, M, S response regions distinctly raise `IndividualCMF:SingularPrimaries` \
%[text] **Next:** [Example 11: Chromaticity Diagrams](matlab:edit('Example11_ChromaticityDiagrams.m')) -- chromaticity coordinates and the spectral locus.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

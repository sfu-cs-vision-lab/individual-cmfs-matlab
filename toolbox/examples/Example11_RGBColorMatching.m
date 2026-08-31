%[text] # Example 11: RGB Color Matching Functions
%[text] RGB colour matching functions give the amounts of three primary lights needed to match each wavelength of the spectrum. The toolbox computes them from the LMS cone fundamentals by a linear transformation, which is fixed once the three primary wavelengths are chosen.
%[text] The default primaries are those of Stiles and Burch (1959) for 10 deg matching:
%[text] - R at 645.15 nm. The nominal figure is 15 500 cm$^{-1}$, which converts to 645.161 nm, so the value both CIE 170 and pycone carry is not simply that conversion rounded. This toolbox uses 645.15 to match them.
%[text] - G at 526.32 nm, which is 19 000 cm$^{-1}$.
%[text] - B at 444.44 nm, which is 22 500 cm$^{-1}$. \
%[text] Any other set of independent primary wavelengths can be supplied. The last section of this example covers what independent means here and what happens when the condition fails.
%[text] **Time:** about 12 minutes.
exampleDefaults();
%%
%[text] ## The default functions
%[text] A default observer uses the Stiles and Burch primaries. `RGB(wl)` returns an N by 3 array.
obs = IndividualCMF();
wl = (390:1:700)';
RGB = obs.RGB(wl);
table(obs.Primaries(1), obs.Primaries(2), obs.Primaries(3), ...
      'VariableNames', {'R_nm', 'G_nm', 'B_nm'})
%%
%[text] ## The colour matching experiment
%[text] These functions come from a matching experiment, and the negative values in the figure below only make sense in terms of it.
%[text] The observer views a field divided into two halves. One half is filled with a single wavelength of light, called the test light. The other half is filled with a mixture of the three primaries. The observer adjusts the amounts of the three primaries until the two halves look identical.
%[text] For some test wavelengths no mixture of the three primaries can produce a match. One primary is then moved to the test half of the field instead, where it desaturates the test light and brings it within reach of the other two. The amount moved across is recorded as a negative value.
%[text] `plotRGBCMFs` draws the three functions. The dashed vertical lines mark the primary wavelengths, where by construction one function is 1 and the other two are 0.
obs.plotRGBCMFs(Title="RGB colour matching functions (Stiles & Burch 10 deg)", Wavelength=wl);
hold on
xline(obs.Primaries(1), '--', 'Color', [0.5 0.5 0.5], 'HandleVisibility', 'off')
xline(obs.Primaries(2), '--', 'Color', [0.5 0.5 0.5], 'HandleVisibility', 'off')
xline(obs.Primaries(3), '--', 'Color', [0.5 0.5 0.5], 'HandleVisibility', 'off')
hold off
xlim([390 700])
%%
%[text] ## A negative value read from the table
%[text] At 500 nm the R value is negative while G and B are both positive. A spectral light at 500 nm cannot be matched by any mixture of the three primaries. The red primary has to be added to the test half instead.
RGB_at_500 = RGB(wl == 500, :);
table(RGB_at_500(1), RGB_at_500(2), RGB_at_500(3), ...
      'VariableNames', {'R_500nm', 'G_500nm', 'B_500nm'})
%%
%[text] ## Where the transformation comes from
%[text] Build the 3 by 3 matrix whose column $j$ is the LMS response at primary wavelength $\\lambda_j$. The LMS to RGB transformation is the inverse of that matrix. Applying it makes each primary wavelength produce a unit vector along its own RGB axis, which is why the three functions take the values 1, 0 and 0 at the primaries.
%[text] The array printed below is the transpose of that matrix, since `LMS` returns one row per wavelength. Its first row is the LMS response at the red primary.
LMS_at_primaries = obs.LMS(obs.Primaries')
%%
%[text] The R function reaches its largest value, 3.20, at 598 nm rather than at its own primary of 645 nm.
%[text] The value of 1 at 645 nm comes from the matrix inverse rather than from peak normalization, since the transformation is built to send each primary to a unit vector. Away from the primaries the functions are not bounded by 1. At 645 nm the L cone is well below its own peak, so a test light at a wavelength where the cones respond more strongly needs several units of the red primary to match.
%%
%[text] ## Supplying your own primaries
%[text] `Primaries` accepts a 1 by 3 vector of wavelengths. The panels below compare the toolbox default against a display with primaries near the peak wavelengths typical of sRGB.
%[text] Note that sRGB and Adobe RGB are defined by chromaticity coordinates rather than by single wavelengths, and that real display primaries emit over a band of wavelengths rather than at one. The wavelengths used here only indicate roughly where those primaries fall on the spectrum locus.
obs_default = IndividualCMF();
obs_sRGB    = IndividualCMF(Primaries=[615, 545, 465]);
tiledlayout(2, 1, 'TileSpacing', 'loose', 'Padding', 'compact');
obs_default.plotRGBCMFs(Title="Stiles & Burch [645/526/444]", Wavelength=wl, Parent=nexttile);
xlim([390 700])
obs_sRGB.plotRGBCMFs(Title="sRGB-like [615/545/465]", Wavelength=wl, Parent=nexttile);
xlim([390 700])
%%
%[text] ## Three sets of primaries compared
%[text] Adobe RGB covers a wider range of colours than sRGB. It does so through its green primary alone, since the two systems share the same red and blue primaries.
%[text] The effect on the colour matching functions is not where it might be expected. The green function changes little. It peaks at 536 nm under both systems and its largest change is 0.046. The red function changes far more. Moving the green primary to a shorter wavelength raises the most negative value of the R function from -0.396 to -0.189, a change of 0.207.
%[text] The negative values mark the test wavelengths that the three primaries cannot match, so a set of primaries that covers more colours produces smaller negative values.
%[text] The wavelengths below stand in for each system's primaries, with the same caveat about broadband emission. The Stiles and Burch row is read back from an observer so that it cannot disagree with the toolbox default.
sb = IndividualCMF().Primaries;
disp_specs = ["sRGB";           "Adobe RGB";       "Stiles & Burch"];
disp_R = [611;                  611;               sb(1)];
disp_G = [549;                  532;               sb(2)];
disp_B = [464;                  464;               sb(3)];
tiledlayout(3, 1, 'TileSpacing', 'loose', 'Padding', 'compact');
for k = 1:numel(disp_specs)
    prim = [disp_R(k), disp_G(k), disp_B(k)];
    obs_disp = IndividualCMF(Primaries=prim);
    obs_disp.plotRGBCMFs(Title=sprintf('%s [%d/%d/%d]', disp_specs(k), round(prim)), ...
        Wavelength=wl, Parent=nexttile);
    xlim([390 700])
end
%%
%[text] ## Primaries that cannot be used
%[text] The three primaries must be independent, in the sense that no two of them can be combined to match the third. If they are too close together in wavelength, all three fall in much the same part of the spectrum, the matrix of LMS values at the primaries is close to singular, and its inverse is meaningless.
%[text] The toolbox raises `IndividualCMF:SingularPrimaries` in that case rather than returning the result. The three primaries below lie within 2 nm of each other, near the L-cone peak.
try
    obs_bad = IndividualCMF(Primaries=[555, 555.5, 556]);
    obs_bad.RGB(550);
catch ME
    disp(ME.identifier)
    disp(ME.message)
end
%%
%[text] ## Key takeaways
%[text] - RGB colour matching functions are a linear transformation of the LMS cone fundamentals
%[text] - The default primaries are those of Stiles and Burch at 645.15, 526.32 and 444.44 nm
%[text] - `RGB` ignores `OutputFormat`. It always computes from peak-normalized fundamentals in energy units, so an observer set to quantal or absorbance returns the same functions
%[text] - A negative value means the test light cannot be matched by any mixture of the three primaries, and that the primary concerned must be added to the test light instead
%[text] - Set `Primaries=[R, G, B]` in nm to model another set of primaries
%[text] - Primaries that are not independent raise `IndividualCMF:SingularPrimaries` \
%[text] **Next:** [Example 12: Chromaticity Diagrams](matlab:edit('Example12_ChromaticityDiagrams.m')). Chromaticity coordinates and the spectrum locus.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

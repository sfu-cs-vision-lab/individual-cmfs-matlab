%[text] # Example 01: The Basics
%[text] This example creates a default observer, evaluates cone sensitivities at chosen wavelengths, and plots the three cone fundamentals. The Getting Started guide maps the whole example set.
%[text] **Time:** about 5 minutes.
exampleDefaults();
%%
%[text] ## Create an observer
%[text] `IndividualCMF` called with no arguments returns the **CIE 2006 10 deg standard observer**.
%[text] The toolbox builds that observer from the Stockman & Rider (2023) formulae rather than from the CIE tables. The two agree closely but not exactly. In units where the peak sensitivity is 1.0, the largest differences are 0.014 for the L cone near 580 nm and 0.019 for the S cone near 435 nm. If you compare the output against a table downloaded from CVRL, expect differences of about this size rather than an exact match.
obs = IndividualCMF()
%%
%[text] ## Define wavelengths
%[text] The methods accept a single wavelength or a vector of wavelengths, in either row or column form.
%[text] `LMS` returns one row per wavelength, so its result is always N by 3. The single-cone methods `L`, `M` and `S` return a result shaped like their input, so a row of wavelengths gives a row of sensitivities. These examples use column vectors throughout.
wl = (380:1:780)';
size(wl)
%%
%[text] ## Evaluate cone sensitivities
%[text] Request one cone at a time, or all three at once with `LMS`.
L = obs.L(wl);
M = obs.M(wl);
S = obs.S(wl);
LMS = obs.LMS(wl);
size(LMS)
%%
%[text] ## Visualize the cone fundamentals
%[text] `plotLMS` plots the three cone fundamentals. The toolbox provides similar wrappers for other quantities, among them `plotRGBCMFs`, `plotChromaticity`, `plotLens`, `plotMacular` and `compareTo`. Later examples use each of these.
obs.plotLMS(Title="Human Cone Fundamentals (CIE 2006 10 deg Observer)");
xlim([380 780]); ylim([0 1.05])
%%
%[text] ## Peak normalization
%[text] The output is peak-normalized by default. Each cone is divided by its own largest value, so every curve reaches 1.0 at its peak. [Example 06](matlab:edit('Example06_NormalizationMethods.m')) describes how the peak is found, and [Example 05](matlab:edit('Example05_OutputFormats.m')) shows how to turn normalization off.
%[text] The peak sensitivities in the table below are slightly less than 1.0. This is because the true peak of each cone falls between the 1 nm points sampled here rather than on one of them.
%[text] The peak wavelengths are those of the complete cone fundamental in energy units. They are not the lambda-max values of the photopigments. The lens, the macular pigment and the conversion from quantal to energy units all move the peak away from lambda-max. [Example 04](matlab:edit('Example04_ComputationalPipeline.m')) works through those stages.
[peakL, iL] = max(L);
[peakM, iM] = max(M);
[peakS, iS] = max(S);
table([peakL; peakM; peakS], wl([iL; iM; iS]), ...
    'VariableNames', {'PeakSensitivity', 'PeakWavelength_nm'}, ...
    'RowNames', {'L', 'M', 'S'})
%%
%[text] ## Log-scale view
%[text] `plotLMS(Log=true)` plots the base-10 logarithm of sensitivity. The setting applies to this call only, so the observer itself is unchanged.
%[text] The values on the y axis are negative because all the sensitivities are less than 1.0. The logarithmic scale makes the very low sensitivities at each end of the spectrum visible, which the linear plot above cannot show.
obs.plotLMS(Log=true, Title="Cone fundamentals on a log scale", Wavelength=wl);
xlim([380 780]); ylim([-5 0.2])
%%
%[text] ## Evaluate at specific wavelengths
%[text] Any wavelength or list of wavelengths can be passed.
%[text] The first example is a sodium lamp at 589 nm.
sodium_wl = 589;
LMS_sodium = obs.LMS(sodium_wl)
%[text] Wavelengths need not be whole numbers. The toolbox evaluates at the value requested rather than at the nearest 1 nm point.
LMS_555p5 = obs.LMS(555.5)
%[text] The second example is a set of typical RGB LED primaries.
RGB_peaks = [630; 530; 470];
LMS_RGB = array2table(obs.LMS(RGB_peaks), ...
    'VariableNames', {'L', 'M', 'S'}, ...
    'RowNames', {'630 nm (Red)', '530 nm (Green)', '470 nm (Blue)'})
%%
%[text] ## Key takeaways
%[text] - `IndividualCMF()` with no arguments gives the CIE 2006 10 deg standard observer
%[text] - Use `obs.L(wl)`, `obs.M(wl)` or `obs.S(wl)` for one cone, and `obs.LMS(wl)` for all three
%[text] - Wavelengths can be a single value or a vector. These examples use columns
%[text] - Output is normalized by default. It reaches 1.0 at the true peak and slightly less on a sampled grid
%[text] - Wavelengths need not be whole numbers \
%[text] **Next:** [Example 02: Standard Observers](matlab:edit('Example02_StandardObservers.m')). The 2 deg and 10 deg observers, and how the toolbox records CIE compliance.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

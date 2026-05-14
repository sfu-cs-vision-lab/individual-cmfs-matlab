%[text] # Example 01: Getting Started
%[text] Construct a default observer, evaluate cone sensitivities, and visualize the three fundamentals.
%[text] **Time:** about 5 minutes.
exampleDefaults();
%%
%[text] ## Create an observer
%[text] `IndividualCMF` with no arguments returns the **CIE 2006 10° standard observer**.
obs = IndividualCMF()
%%
%[text] ## Define wavelengths
%[text] `IndividualCMF` methods expect wavelengths as a column vector.
wl = (380:1:780)';
size(wl)
%%
%[text] ## Evaluate cone sensitivities
%[text] Fetch one cone at a time, or all three with `LMS()`.
L = obs.L(wl);
M = obs.M(wl);
S = obs.S(wl);
LMS = obs.LMS(wl);
size(LMS)
%%
%[text] ## Visualize the cone fundamentals
%[text] `plotLMS` is the plot wrapper for the three cone fundamentals; sibling wrappers (`plotRGBCMFs`, `plotChromaticity`, `plotLens`, `plotMacular`, `compareTo`, ...) appear in the later examples.
obs.plotLMS(Title="Human Cone Fundamentals (CIE 2006 10 deg Observer)");
xlim([380 780]); ylim([0 1.05])
%%
%[text] ## Peak normalization
%[text] Output is peak-normalized by default ($\\max = 1.0$). See [Example 08](matlab:edit('Example08_OutputFormats.m')) for un-normalized output and other format controls.
peakL_wl = wl(L == max(L));
peakM_wl = wl(M == max(M));
peakS_wl = wl(S == max(S));
table([max(L); max(M); max(S)], [peakL_wl; peakM_wl; peakS_wl], ...
    'VariableNames', {'PeakSensitivity', 'PeakWavelength_nm'}, ...
    'RowNames', {'L', 'M', 'S'})
%%
%[text] ## Log-scale view
%[text] `plotLMS(Log=true)` switches to a $\\log_{10}$ y-axis without mutating the observer; the tails become visible.
obs.plotLMS(Log=true, Title="Cone fundamentals on a log scale", Wavelength=wl);
xlim([380 780]); ylim([-5 0.2])
%%
%[text] ## Evaluate at specific wavelengths
%[text] Pass any wavelength or list of wavelengths.
%[text] First example: a sodium lamp at 589 nm.
sodium_wl = 589;
LMS_sodium = obs.LMS(sodium_wl)
%[text] Wavelengths can be non-integer -- the toolbox evaluates at the requested value, not the nearest 1 nm grid point.
LMS_555p5 = obs.LMS(555.5)
%[text] Second example: typical RGB LED primaries.
RGB_peaks = [630; 530; 470];
LMS_RGB = array2table(obs.LMS(RGB_peaks), ...
    'VariableNames', {'L', 'M', 'S'}, ...
    'RowNames', {'630 nm (Red)', '530 nm (Green)', '470 nm (Blue)'})
%%
%[text] ## Key takeaways
%[text] - `IndividualCMF()` with no arguments gives the CIE 2006 10 deg standard observer
%[text] - Use `obs.L(wl)`, `obs.M(wl)`, `obs.S(wl)` for one cone, or `obs.LMS(wl)` for all three
%[text] - Wavelengths should be a column vector
%[text] - Output is normalized (peak = 1.0) by default
%[text] - You can evaluate at any wavelength -- not just integer values \
%[text] **Next:** [Example 02: CIE 2006 Standard Observers](matlab:edit('Example02_StandardObservers.m')) -- the difference between 2 deg and 10 deg observers and CIE standards.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

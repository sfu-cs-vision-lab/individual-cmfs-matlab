%[text] # Example 01: The Basics
%[text] Construct a default observer, evaluate cone sensitivities, and visualize the three fundamentals. (For a map of the whole example set, see the Getting Started guide.)
%[text] **Time:** about 5 minutes.
exampleDefaults();
%%
%[text] ## Create an observer
%[text] `IndividualCMF` with no arguments returns the **CIE 2006 10 deg standard observer**.
obs = IndividualCMF()
%%
%[text] ## Define wavelengths
%[text] `IndividualCMF` methods accept a scalar or any vector, row or column; results come back with one row per wavelength. These examples use column vectors by convention.
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
%[text] Output is peak-normalized by default: each cone is divided by the peak of its *continuous* spectral model, found by search rather than read off a grid. The true peak almost never lands on an integer wavelength, so the maximum over a sampled grid comes out a hair under 1.0 -- 0.99999 for L below. See [Example 16](matlab:edit('Example16_NormalizationMethods.m')) for how the peak is located, and [Example 08](matlab:edit('Example08_OutputFormats.m')) for un-normalized output and other format controls.
%[text] The peak wavelengths below are those of the complete fundamental in energy units, not the photopigment's lambda-max: lens and macular filtering and the quantal-to-energy conversion all move the peak. [Example 07](matlab:edit('Example07_ComputationalPipeline.m')) walks that pipeline.
[peakL, iL] = max(L);
[peakM, iM] = max(M);
[peakS, iS] = max(S);
table([peakL; peakM; peakS], wl([iL; iM; iS]), ...
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
%[text] - Wavelengths can be a scalar or any vector; these examples use columns
%[text] - Output is normalized by default: 1.0 at the continuous peak, just under 1.0 on any sampled grid
%[text] - You can evaluate at any wavelength -- not just integer values \
%[text] **Next:** [Example 02: CIE 2006 Standard Observers](matlab:edit('Example02_StandardObservers.m')) -- the difference between 2 deg and 10 deg observers and CIE standards.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

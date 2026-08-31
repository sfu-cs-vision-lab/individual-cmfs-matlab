%[text] # Example 19: Working with Measured Spectra
%[text] Every earlier example evaluates an observer at wavelengths chosen for the demonstration. Real work usually starts from a spectrum measured with an instrument, on whatever grid that instrument produced, in physical units.
%[text] This example goes from a measured file to cone responses, tristimulus values and luminance. It covers the four things that go wrong in practice: the measurement grid not matching the one you would have chosen, missing samples, wavelengths outside the range a model covers, and units.
%[text] **Time:** about 12 minutes.
exampleDefaults();
%%
%[text] ## A stand-in for an instrument file
%[text] The block below writes a CSV that stands in for a spectroradiometer export, so this example needs no external data. It is a phosphor-converted white LED: a blue emission peak near 450 nm and a broad phosphor emission near 580 nm.
%[text] Three properties are deliberately awkward, and each is one a real file is likely to have. It is sampled every 5 nm rather than every 1 nm. It runs from 380 to 730 nm rather than over the toolbox default range. And two samples are missing, recorded as `NaN` by the instrument.
wl_meas = (380:5:730)';
blue    = 0.85 * exp(-((wl_meas - 452) / 11).^2);
phos    = 1.00 * exp(-((wl_meas - 580) / 55).^2);
radiance = 0.012 * (blue + phos);
radiance([12 13]) = NaN;
spectrum_path = fullfile(tempdir, 'measured_led.csv');
writetable(table(wl_meas, radiance, ...
    'VariableNames', {'wavelength_nm', 'radiance_W_per_m2_per_sr_per_nm'}), spectrum_path);
disp(['Wrote ' spectrum_path])
%%
%[text] ## Reading and inspecting it
%[text] Read the file and look at it before doing anything else. The two things to establish are the wavelength range and whether any samples are missing.
meas = readtable(spectrum_path);
wl_raw  = meas.wavelength_nm;
spd_raw = meas.radiance_W_per_m2_per_sr_per_nm;
table(min(wl_raw), max(wl_raw), mean(diff(wl_raw)), numel(wl_raw), sum(isnan(spd_raw)), ...
      'VariableNames', {'Min_nm', 'Max_nm', 'Step_nm', 'Samples', 'Missing'})
%%
%[text] ## Dealing with the missing samples
%[text] Two samples are `NaN`. Left in place they would make every integral `NaN`, since a sum containing `NaN` is `NaN`.
%[text] There are two defensible responses. Drop the affected wavelengths, which is right when the gap is at an unimportant part of the spectrum. Or interpolate across them, which is right when the spectrum is smooth and the gap is narrow. The choice belongs to whoever knows why the samples are missing, so the toolbox does not make it.
%[text] The gap here is at 435 and 440 nm, on the rising side of the blue peak, where the spectrum is neither flat nor negligible. Interpolating is the better choice, and `fillmissing` does it.
gap_nm = wl_raw(isnan(spd_raw))';
spd_filled = fillmissing(spd_raw, 'linear', 'SamplePoints', wl_raw);
table(string(mat2str(gap_nm)), sum(isnan(spd_filled)), ...
      'VariableNames', {'Missing_at_nm', 'Remaining_NaN'})
tiledlayout(1, 1); nexttile
plot(wl_raw, spd_filled, '-o', 'MarkerSize', 3, 'Color', IndividualCMF.neutralColor())
hold on
plot(gap_nm, spd_filled(ismember(wl_raw, gap_nm)), 'ro', 'MarkerSize', 9, 'LineWidth', 1.5)
hold off
xlabel('Wavelength (nm)'); ylabel('Radiance (W m^{-2} sr^{-1} nm^{-1})')
title('Measured spectrum, with the interpolated samples marked')
legend('Measured', 'Interpolated', 'Location', 'best')
xlim([380 730])
%%
%[text] ## Matching the grids
%[text] The observer and the spectrum have to be evaluated at the same wavelengths before they can be multiplied together.
%[text] Many toolboxes require the data to be resampled onto a fixed internal grid. This one does not. The cone fundamentals are continuous functions of wavelength, so the observer can be evaluated at whatever wavelengths the instrument produced. Resample the observer to the data, never the data to the observer, since interpolating a measurement adds error that was not in it.
obs = IndividualCMF(StandardObserver=2);
LMS_at_meas = obs.LMS(wl_raw);
table(size(LMS_at_meas, 1), size(LMS_at_meas, 2), numel(wl_raw), ...
      'VariableNames', {'Rows', 'Cones', 'Measured_samples'})
%%
%[text] ## Wavelengths outside the range of a model
%[text] Whether a file reaches outside a model's range depends on which model is in use, so the check has to be made against the models actually selected.
%[text] This file runs to 730 nm. The default `StockmanRider2023` lens covers 360 to 830 nm and is untroubled by it. `VanDeKraats2007` was fitted over 300 to 700 nm, so the same file reaches 30 nm past it. That is why the last section of this example switches the range warning off: it uses the aged lens model, and the file provokes it.
%[text] Two different things happen outside a range, and they are worth separating. Outside a template's `ValidRange` the toolbox warns once per observer and still returns a value, since the extrapolation is defined but not supported by the publication. Outside its `Domain` the toolbox returns no value at all. A file starting below 400 nm meets the second case with `Pokorny1987`. [Example 08](matlab:edit('Example08_AgingEffects.m')) describes both.
%[text] The practical rule is to compare the range of the file against the range of the models before integrating, rather than to discover the mismatch from a warning afterwards.
model_ranges = table( ...
    ["StockmanRider2023"; "VanDeKraats2007"; "Pokorny1987"], ...
    [360; 300; 400], [830; 700; 830], ...
    'VariableNames', {'LensModel', 'Valid_min_nm', 'Valid_max_nm'});
model_ranges.File_outside = min(wl_raw) < model_ranges.Valid_min_nm | ...
                            max(wl_raw) > model_ranges.Valid_max_nm;
model_ranges
%%
%[text] ## Integrating to cone responses
%[text] The response of a cone to a spectrum is the integral of the spectrum multiplied by that cone's sensitivity.
%[text] $ L = \\int \\Phi(\\lambda)\\, \\bar{l}(\\lambda)\\, d\\lambda $
%[text] Use `trapz` rather than `sum`. On a 5 nm grid a plain sum would understate the integral by the factor of the step size, and `trapz` handles an uneven grid correctly as well.
%[text] Note what the units of the result are. The cone fundamentals are relative sensitivities with no units, so the cone responses carry the units of the spectrum and are meaningful only when compared with other responses computed the same way.
cone_response = trapz(wl_raw, spd_filled .* LMS_at_meas);
table(cone_response(1), cone_response(2), cone_response(3), ...
      cone_response(1) / cone_response(2), ...
      'VariableNames', {'L', 'M', 'S', 'L_over_M'})
%%
%[text] ## Tristimulus values, chromaticity and luminance
%[text] The same integral against the XYZ colour matching functions gives the tristimulus values, and dividing each by their sum gives the chromaticity coordinates.
%[text] Luminance uses $V^{\\ast}(\\lambda)$ and the constant $K_m = 683$ lm/W. Because the file is a radiance in W m^-2 sr^-1 nm^-1, the result is a luminance in cd/m^2. Had the file been an irradiance the same calculation would give an illuminance in lux. The units of the answer follow from the units of the file, which is why they are worth recording alongside it.
XYZ_meas = trapz(wl_raw, spd_filled .* obs.XYZ(wl_raw));
xy = XYZ_meas(1:2) / sum(XYZ_meas);
Km = 683;
luminance = Km * trapz(wl_raw, spd_filled .* obs.Luminance(wl_raw));
table(XYZ_meas(1), XYZ_meas(2), XYZ_meas(3), xy(1), xy(2), luminance, ...
      'VariableNames', {'X', 'Y', 'Z', 'x', 'y', 'Luminance_cd_per_m2'})
%%
%[text] ## The same spectrum through two observers
%[text] This is the calculation the toolbox exists for. The same measured spectrum is integrated against two different observers, and the results differ because the observers do.
%[text] The comparison below uses the 2 deg standard observer and a 70 year old with the age-dependent lens model. Both see the same light. The chromaticity coordinates they arrive at are not the same.
obs_old = IndividualCMF(LensModel="VanDeKraats2007", Age=70, FieldSize=2);
obs_old.ModelRangeWarning = false;
xy_of = @(o) local_xy(o, wl_raw, spd_filled);
xy_std = xy_of(obs);
xy_age = xy_of(obs_old);
table([xy_std(1); xy_age(1)], [xy_std(2); xy_age(2)], ...
      [0; norm(xy_age - xy_std)], ...
      'VariableNames', {'x', 'y', 'Distance_from_standard'}, ...
      'RowNames', {'2 deg standard', 'Age 70'})
%[text] [Example 20](matlab:edit('Example20_ObserverMetamerism.m')) takes this further and shows two spectra that match for one observer and not for another.
%%
%[text] ## Key takeaways
%[text] - Evaluate the observer at the wavelengths the instrument produced. The cone fundamentals are continuous, so the measurement never has to be resampled
%[text] - Deal with missing samples before integrating. One `NaN` makes the whole integral `NaN`. `fillmissing` interpolates and `rmmissing` drops
%[text] - Check the range of the file against the range of the models before integrating. Outside a `ValidRange` the toolbox warns and returns a value. Outside a `Domain` it returns none
%[text] - Use `trapz` rather than `sum`, which handles the step size and an uneven grid correctly
%[text] - The cone fundamentals carry no units, so the cone responses carry the units of the spectrum. Record those units with the data
%[text] - Luminance is $K_m$ times the integral against $V^{\\ast}(\\lambda)$. A radiance in gives cd/m^2, an irradiance in gives lux \
%[text] **Next:** [Example 20: Observer Metamerism](matlab:edit('Example20_ObserverMetamerism.m')). How a match made for one observer fails for another.
%%
function xy = local_xy(o, wl, spd)
% LOCAL_XY  Chromaticity coordinates of a spectrum for one observer.
    XYZ = trapz(wl, spd .* o.XYZ(wl));
    xy = XYZ(1:2) / sum(XYZ);
end

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

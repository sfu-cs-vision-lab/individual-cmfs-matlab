function regen_golden()
% REGEN_GOLDEN  Regenerate golden fixtures in tests/data from pycone.
%
%   Sources every regenerated spectral value from the vendored pycone
%   reference (tests/parity/pycone) via tests/parity/regen_golden.py, so
%   the fixtures stay an independent cross-check of the toolbox rather
%   than a copy of its own output. For each fixture this driver
%   constructs the same IndividualCMF observer the consuming test uses,
%   reads the resolved biophysical values (lambda-max shifts, optical
%   densities, macular and lens densities, opsin templates), and passes
%   those exact numbers to pycone. Pure-input columns (for example the
%   genotype-driven shifts) are written from the resolved observer.
%
%   Run this whenever the vendored pycone reference moves and the stored
%   golden CSVs need to be refreshed.
%
%   SPDX-License-Identifier: AGPL-3.0-or-later
%   Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt

here = fileparts(mfilename('fullpath'));
dataDir = fullfile(here, '..', 'data');
pyScript = fullfile(here, 'regen_golden.py');

if ~isfolder(fullfile(here, 'pycone'))
    error('regen_golden:NoPycone', ...
        'pycone reference not found at %s', fullfile(here, 'pycone'));
end

addpath(fullfile(here, '..', '..', 'toolbox'));

warnIDs = { ...
    'StockmanRiderPhotopigmentTemplate:ShiftOverride', ...
    'IndividualCMF:WavelengthOutOfRange', ...
    'Nomograms:WavelengthOutOfRange'};
for k = 1:numel(warnIDs)
    warning('off', warnIDs{k});
end
cleanup = onCleanup(@() reenableWarnings(warnIDs)); %#ok<NASGU>

writeStandard(pyScript, dataDir, 2, 'standard_2deg.csv');
writeStandard(pyScript, dataDir, 10, 'standard_10deg.csv');
writeTemplate(pyScript, dataDir);
writeIndividual(pyScript, dataDir);
writePipeline(pyScript, dataDir);
writeRGB(pyScript, dataDir);
writeRGBMatrix(pyScript, dataDir);
writeCmfSColumn(pyScript, dataDir);

fprintf('Golden fixtures regenerated from pycone.\n');

end


function writeStandard(pyScript, dataDir, observer, fileName)
% nm,L_energy,M_energy,S_energy,L_quantal,M_quantal,S_quantal on 390:5:780.
obs = IndividualCMF(StandardObserver=observer);
py = runPycone(pyScript, payloadFor(obs, 390, 780, 5));

T = table();
T.nm = py.nm;
T.L_energy = py.L_energy;
T.M_energy = py.M_energy;
T.S_energy = py.S_energy;
T.L_quantal = py.L_quantal;
T.M_quantal = py.M_quantal;
T.S_quantal = py.S_quantal;
writeTableExact(T, fullfile(dataDir, fileName));
end


function writeTemplate(pyScript, dataDir)
% wavelength,l_mean_absorbance,l_serine_absorbance,l_hybrid_absorbance
% on 390:1:780. Each column is the L-cone absorbance stage for a
% different L opsin template.
obs = IndividualCMF(StandardObserver=2);

obs.L_OpsinTemplate = "Mean";
pyMean = runPycone(pyScript, payloadFor(obs, 390, 780, 1));
obs.L_OpsinTemplate = "Serine";
pySer = runPycone(pyScript, payloadFor(obs, 390, 780, 1));
obs.L_OpsinTemplate = "MinL";
pyHyb = runPycone(pyScript, payloadFor(obs, 390, 780, 1));

T = table();
T.wavelength = pyMean.nm;
T.l_mean_absorbance = pyMean.L_absorbance;
T.l_serine_absorbance = pySer.L_absorbance;
T.l_hybrid_absorbance = pyHyb.L_absorbance;
writeTableExact(T, fullfile(dataDir, 'template_verification.csv'));
end


function writeIndividual(pyScript, dataDir)
% nm,L_energy,M_energy,S_energy,L_quantal,M_quantal,S_quantal on
% 390:5:780, normalized over the 380:5:780 sampling grid used by the
% consuming test's Sampled normalization.
obs = IndividualCMF( ...
    'L_OpsinTemplate', "Serine", ...
    'L_LambdaMaxShift', 5.0, ...
    'M_LambdaMaxShift', -5.0, ...
    'Lod', 0.60, ...
    'Mod', 0.60, ...
    'Sod', 0.45, ...
    'MacularDensity', 0.50, ...
    'LensDensity', 2.00);

payload = payloadFor(obs, 390, 780, 5);
payload.norm_min = 380;
payload.norm_max = 780;
payload.norm_step = 5;
py = runPycone(pyScript, payload);

T = table();
T.nm = py.nm;
T.L_energy = py.L_energy;
T.M_energy = py.M_energy;
T.S_energy = py.S_energy;
T.L_quantal = py.L_quantal;
T.M_quantal = py.M_quantal;
T.S_quantal = py.S_quantal;
writeTableExact(T, fullfile(dataDir, 'individual_verification.csv'));
end


function writePipeline(pyScript, dataDir)
% nm,L_log_abs,M_log_abs,L_absorptance,M_absorptance,
% L_quantal,M_quantal,S_quantal,L_hybrid_energy,M_hybrid_energy
% on 390:5:780. Standard 2-deg observer for the raw stages, plus two
% hybrid observers for the swapped-template energy columns.
obs = IndividualCMF(StandardObserver=2);
py = runPycone(pyScript, payloadFor(obs, 390, 780, 5));

obsL = IndividualCMF(Age=32, FieldSize=2);
obsL.L_OpsinTemplate = "MinL";
pyL = runPycone(pyScript, payloadFor(obsL, 390, 780, 5));

obsM = IndividualCMF(Age=32, FieldSize=2);
obsM.M_OpsinTemplate = "LinM";
pyM = runPycone(pyScript, payloadFor(obsM, 390, 780, 5));

T = table();
T.nm = py.nm;
T.L_log_abs = log10(py.L_absorbance);
T.M_log_abs = log10(py.M_absorbance);
T.L_absorptance = py.L_absorptance;
T.M_absorptance = py.M_absorptance;
T.L_quantal = py.L_quantal;
T.M_quantal = py.M_quantal;
T.S_quantal = py.S_quantal;
T.L_hybrid_energy = pyL.L_energy;
T.M_hybrid_energy = pyM.M_energy;
writeTableExact(T, fullfile(dataDir, 'pipeline_verification.csv'));
end


function writeRGB(pyScript, dataDir)
% nm,R,G,B,L_quantal,M_quantal,S_quantal on 390:5:780. The RGB columns
% are the normalized-energy color matching functions; the quantal
% columns are the raw corneal quantal sensitivities.
obs = IndividualCMF(StandardObserver=2);
py = runPycone(pyScript, payloadFor(obs, 390, 780, 5));

primaries = obs.Primaries(:);
primEnergy = pointEnergy(pyScript, obs, primaries);

% Per-cone energy peaks over the spectrum grid normalize the primaries
% consistently with the normalized LMS energy used for the CMFs.
peaks = [max(py.L_energy), max(py.M_energy), max(py.S_energy)];
primNorm = primEnergy ./ peaks;
lmsNorm = [py.L_energy, py.M_energy, py.S_energy] ./ peaks;

% Rows of primNorm are primaries, columns are LMS.
rgbCmfs = (primNorm.' \ lmsNorm.').';

T = table();
T.nm = py.nm;
T.R = rgbCmfs(:, 1);
T.G = rgbCmfs(:, 2);
T.B = rgbCmfs(:, 3);
T.L_quantal = py.L_quantal;
T.M_quantal = py.M_quantal;
T.S_quantal = py.S_quantal;
writeTableExact(T, fullfile(dataDir, 'rgb_verification.csv'));
end


function writeRGBMatrix(pyScript, dataDir)
% Headerless 3x3 matrix inv([L;M;S]) built from the raw corneal energy
% at the three primary wavelengths (Standard 2-deg observer).
obs = IndividualCMF(StandardObserver=2);
primaries = obs.Primaries(:);
primEnergy = pointEnergy(pyScript, obs, primaries);

% primEnergy rows are primaries, columns are LMS. The consuming test
% forms [L_prim; M_prim; S_prim] (rows LMS, columns primaries) and
% inverts it.
RGBLMS = primEnergy.';
M = inv(RGBLMS);
writeMatrixExact(M, fullfile(dataDir, 'rgb_matrix.csv'));
end


function writeMatrixExact(M, path)
% Write a numeric matrix at full double precision, comma-separated.
fid = fopen(path, 'w');
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
for r = 1:size(M, 1)
    fprintf(fid, '%.18e', M(r, 1));
    for c = 2:size(M, 2)
        fprintf(fid, ',%.18e', M(r, c));
    end
    fprintf(fid, '\n');
end
end


function writeCmfSColumn(pyScript, dataDir)
% Refresh only the stale S_log column of cmf_verification_data.csv (the
% S photopigment template coefficients changed). Every other column is
% preserved byte-for-byte: the original lines are read as text and only
% the S_log field is replaced in place.
csvPath = fullfile(dataDir, 'cmf_verification_data.csv');
lines = readlines(csvPath);
if lines(end) == ""
    lines(end) = [];
end

header = split(lines(1), ',');
sCol = find(header == "S_log", 1);
if isempty(sCol)
    error('regen_golden:NoSLogColumn', 'S_log column not found in %s', csvPath);
end
nmCol = find(header == "nm", 1);

nRows = numel(lines) - 1;
nmValues = zeros(nRows, 1);
for r = 1:nRows
    fields = split(lines(r + 1), ',');
    nmValues(r) = str2double(fields(nmCol));
end
nmMin = min(nmValues);
nmMax = max(nmValues);
nmStep = nmValues(2) - nmValues(1);

obs = IndividualCMF(StandardObserver=2);
py = runPycone(pyScript, payloadFor(obs, nmMin, nmMax, nmStep));
sLog = log10(py.S_absorbance);

for r = 1:nRows
    fields = split(lines(r + 1), ',');
    fields(sCol) = string(sprintf('%.17g', sLog(r)));
    lines(r + 1) = strjoin(fields, ',');
end
writelines(lines, csvPath);
end


function E = pointEnergy(pyScript, obs, wavelengths)
% Raw corneal energy at arbitrary wavelengths, one pycone call per
% point so non-uniform primary grids are handled exactly. Returns an
% N-by-3 matrix with rows matching the input wavelengths and columns
% L, M, S.
E = zeros(numel(wavelengths), 3);
for i = 1:numel(wavelengths)
    payload = payloadFor(obs, wavelengths(i), wavelengths(i), 1);
    py = runPycone(pyScript, payload);
    E(i, :) = [py.L_energy(1), py.M_energy(1), py.S_energy(1)];
end
end


function payload = payloadFor(obs, wlMin, wlMax, wlStep)
payload = struct( ...
    'Lshift', obs.L_LambdaMaxShift, ...
    'Mshift', obs.M_LambdaMaxShift, ...
    'Sshift', obs.S_LambdaMaxShift, ...
    'Lod', obs.Lod, ...
    'Mod', obs.Mod, ...
    'Sod', obs.Sod, ...
    'mac_density', obs.MacularDensity, ...
    'lens_density', obs.LensDensity, ...
    'L_template', mapLTemplate(obs.L_OpsinTemplate), ...
    'M_template', mapMTemplate(obs.M_OpsinTemplate), ...
    'wl_min', wlMin, ...
    'wl_max', wlMax, ...
    'wl_step', wlStep);
end


function s = mapLTemplate(matlabName)
switch string(matlabName)
    case "Mean",    s = "Lmean";
    case "Serine",  s = "Lser";
    case "Alanine", s = "Lala";
    case "MinL",    s = "M-in-L";
    otherwise,      s = "Lmean";
end
end


function s = mapMTemplate(matlabName)
switch string(matlabName)
    case "Standard", s = "Standard";
    case "LinM",     s = "L-in-M";
    case "Mean",     s = "Standard";
    otherwise,       s = "Standard";
end
end


function tbl = runPycone(scriptPath, payload)
payloadJson = jsonencode(payload);
tmp = tempname;
writelines(payloadJson, tmp);
cleanup = onCleanup(@() delete(tmp)); %#ok<NASGU>
[status, out] = system(sprintf('python3 %s < %s', scriptPath, tmp));
if status ~= 0
    error('regen_golden:PyconeFailure', ...
        'pycone subprocess failed (status %d):\n%s', status, out);
end
csvTmp = tempname + ".csv";
fid = fopen(csvTmp, 'w');
fprintf(fid, '%s', out);
fclose(fid);
cleanupCsv = onCleanup(@() delete(csvTmp)); %#ok<NASGU>
tbl = readtable(csvTmp);
end


function writeTableExact(T, path)
% Write a table with 17 significant digits so reloaded values round-trip
% to machine precision (writetable's default 15 digits loses relative
% precision on small spectral values).
names = T.Properties.VariableNames;
nCols = numel(names);
nRows = height(T);
data = cell(nRows, nCols);
for c = 1:nCols
    col = T.(names{c});
    for r = 1:nRows
        data{r, c} = sprintf('%.17g', col(r));
    end
end
fid = fopen(path, 'w');
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', strjoin(names, ','));
fprintf(fid, '\n');
for r = 1:nRows
    fprintf(fid, '%s', strjoin(data(r, :), ','));
    fprintf(fid, '\n');
end
end


function reenableWarnings(ids)
for i = 1:numel(ids)
    warning('on', ids{i});
end
end

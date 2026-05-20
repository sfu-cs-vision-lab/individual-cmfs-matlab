function results = compare(options)
% COMPARE  Compare IndividualCMF outputs against pycone, on a per-config basis.
%
%   For each entry in tests/parity/configs.json this driver:
%     1. Constructs an IndividualCMF observer with the listed MATLAB options.
%     2. Reads the resolved values from the observer (LensDensity,
%        MacularDensity, Lod/Mod/Sod, lambda-max shifts, opsin template
%        choice).
%     3. Calls tests/parity/run_pycone.py via a Python subprocess, passing
%        those exact resolved values, so pycone evaluates the mathematical
%        pipeline with identical numerical inputs.
%     4. Compares the two resulting LMS arrays with absolute and relative
%        tolerances and prints a per-config pass/fail summary.
%
%   To make the normalization peak comparable, MATLAB is switched to
%   "Sampled" normalization on the same wavelength grid pycone uses. This
%   takes algorithmic differences (Continuous fminbnd vs sampled max) out
%   of the picture; the comparison then tests only the mathematical
%   pipeline (templates -> absorptance -> corneal -> output format).
%
%   OPTIONAL INPUTS (Name-Value arguments):
%       AbsTol  - Absolute tolerance (scalar) Default: 1e-10
%       RelTol  - Relative tolerance (scalar) Default: 1e-9
%       Verbose - Print per-config max diffs (logical) Default: true
%
%   SPDX-License-Identifier: AGPL-3.0-or-later
%   Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt

arguments
    options.AbsTol (1,1) double = 1e-10
    options.RelTol (1,1) double = 1e-9
    options.Verbose (1,1) logical = true
end

here = fileparts(mfilename('fullpath'));
raw = jsondecode(fileread(fullfile(here, 'configs.json')));
% jsondecode returns a struct array when all entries share fields, or
% a cell array of structs when they don't. Normalize to a cell array.
if iscell(raw)
    configs = raw;
else
    configs = num2cell(raw);
end
runPyconeScript = fullfile(here, 'run_pycone.py');

if ~isfolder(fullfile(here, 'pycone'))
    error('compare:NoPycone', ...
        ['pycone reference not found. Run:\n' ...
         '    cd %s && git clone --depth 1 ' ...
         'https://github.com/CVRL-IoO/Individual-CMFs.git pycone'], here);
end

addpath(fullfile(here, '..', '..', 'toolbox'));

% Default output wavelength grid common to MATLAB and pycone. Each
% config can override these via cfg.wavelength.{min, max, step}.
defaultWlMin = 390;
defaultWlMax = 780;
defaultWlStep = 1;

nConfigs = numel(configs);
formats = ["absorbance", "absorptance", "quantal", "energy"];
results = struct('name', {}, 'format', {}, 'maxAbs', {}, 'maxRel', {}, 'pass', {});

% Suppress warnings (e.g., "Alanine + non-zero shift") that are
% intentional for some test configs. Use specific IDs rather than
% 'all', and explicitly re-enable them in cleanup so the rule list
% stays clean for any caller (don't rely on warning(savedState)
% round-tripping through MATLAB's accumulating rule list).
expectedWarnings = { ...
    'StockmanRiderPhotopigmentTemplate:ShiftOverride', ...
    'IndividualCMF:WavelengthOutOfRange', ...
    'IndividualCMF:IgnoredProperty', ...
    'IndividualCMF:MacularCustomOverwritten', ...
    'IndividualCMF:PhotopigmentCustomOverwritten', ...
    'IndividualCMF:LensCustomOverwritten'};
for wi = 1:numel(expectedWarnings)
    warning('off', expectedWarnings{wi});
end
cleanupWarn = onCleanup(@() reenableWarnings(expectedWarnings)); %#ok<NASGU>

for k = 1:nConfigs
    cfg = configs{k};

    % Per-config RelTol override (log_output configs need a looser
    % RelTol to absorb cross-implementation log10 drift between
    % MATLAB's libm and numpy's, which varies by Azure CI host CPU).
    cfgRelTol = options.RelTol;
    if isfield(cfg, 'tol') && isfield(cfg.tol, 'RelTol')
        cfgRelTol = cfg.tol.RelTol;
    end

    obs = buildObserver(cfg.matlab);

    % Per-config wavelength grid (defaults to 390:1:780).
    if isfield(cfg, 'wavelength')
        wlMin = getOr(cfg.wavelength, 'min', defaultWlMin);
        wlMax = getOr(cfg.wavelength, 'max', defaultWlMax);
        wlStep = getOr(cfg.wavelength, 'step', defaultWlStep);
    else
        wlMin = defaultWlMin;
        wlMax = defaultWlMax;
        wlStep = defaultWlStep;
    end
    wl = (wlMin:wlStep:wlMax)';

    % Force Sampled normalization on the comparison grid so MATLAB and
    % pycone use the same peak-detection method.
    obs.NormalizationMethod = struct( ...
        Method="Sampled", Start=wlMin, Stop=wlMax, Step=wlStep);

    isLog = isfield(cfg.pycone, 'log_output') && cfg.pycone.log_output;
    isNormalized = ~(isfield(cfg.pycone, 'normalize') && cfg.pycone.normalize == false);
    obs.LogOutput = isLog;
    obs.NormalizeOutput = isNormalized;

    % Build pycone payload from MATLAB-resolved values.
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
        'Rnm', obs.Primaries(1), ...
        'Gnm', obs.Primaries(2), ...
        'Bnm', obs.Primaries(3), ...
        'wl_min', wlMin, ...
        'wl_max', wlMax, ...
        'wl_step', wlStep, ...
        'normalize', isNormalized, ...
        'log_output', isLog);

    pyTable = invokePycone(runPyconeScript, payload);

    cfgPass = true;
    cfgMaxAbs = struct(); cfgMaxRel = struct();
    for fi = 1:numel(formats)
        fmt = formats(fi);
        obs.OutputFormat = fmt;
        matVals = obs.LMS(wl);

        pyVals = [pyTable.("L_" + fmt), pyTable.("M_" + fmt), pyTable.("S_" + fmt)];

        [maxAbs, maxRel] = compareArrays(matVals, pyVals);
        thisPass = (maxAbs < options.AbsTol) || (maxRel < cfgRelTol);
        cfgPass = cfgPass && thisPass;
        cfgMaxAbs.(fmt) = maxAbs;
        cfgMaxRel.(fmt) = maxRel;

        results(end+1) = struct( ...
            'name', cfg.name, 'format', fmt, ...
            'maxAbs', maxAbs, 'maxRel', maxRel, ...
            'pass', thisPass); %#ok<AGROW>
    end

    % RGB CMFs (linear transform of normalized LMS energy).
    matRGB = obs.RGB(wl);
    pyRGB = [pyTable.R_cmf, pyTable.G_cmf, pyTable.B_cmf];
    [RGBAbs, RGBRel] = compareArrays(matRGB, pyRGB);
    RGBPass = (RGBAbs < options.AbsTol) || (RGBRel < cfgRelTol);
    cfgPass = cfgPass && RGBPass;
    cfgMaxAbs.RGB = RGBAbs;
    cfgMaxRel.RGB = RGBRel;
    results(end+1) = struct( ...
        'name', cfg.name, 'format', "RGB", ...
        'maxAbs', RGBAbs, 'maxRel', RGBRel, ...
        'pass', RGBPass); %#ok<AGROW>

    if options.Verbose
        fprintf('%-40s  abs:%.1e aptn:%.1e q:%.1e e:%.1e RGB:%.1e   %s\n', ...
            cfg.name, ...
            cfgMaxAbs.absorbance, cfgMaxAbs.absorptance, ...
            cfgMaxAbs.quantal, cfgMaxAbs.energy, cfgMaxAbs.RGB, ...
            ternary(cfgPass, 'PASS', 'FAIL'));
    end
end

nPass = sum([results.pass]);
nTotal = numel(results);
nFail = nTotal - nPass;

if options.Verbose
    fprintf('\n=== Parity summary (vs pycone, MATLAB-resolved inputs) ===\n');
    fprintf('  Comparisons: %d (%d configs x %d formats: 4 LMS stages + RGB)\n', ...
        nTotal, nConfigs, numel(formats) + 1);
    fprintf('  PASSED:      %d\n', nPass);
    fprintf('  FAILED:      %d\n', nFail);
    fprintf('  AbsTol:      %.0e\n', options.AbsTol);
    fprintf('  RelTol:      %.0e\n', options.RelTol);

    if nFail > 0
        fprintf('\nFailures:\n');
        for r = results(~[results.pass]) %#ok<NOSEMI>
            fprintf('  %-40s  %-12s  abs=%.2e rel=%.2e\n', ...
                r.name, r.format, r.maxAbs, r.maxRel);
        end
    end
end

end


function obs = buildObserver(matlabOpts)
nv = {};
fns = fieldnames(matlabOpts);
for i = 1:numel(fns)
    nv{end+1} = fns{i}; %#ok<AGROW>
    nv{end+1} = matlabOpts.(fns{i}); %#ok<AGROW>
end
obs = IndividualCMF(nv{:});
end


function s = mapLTemplate(matlabName)
% IndividualCMF L_OpsinTemplate -> pycone L template name
switch string(matlabName)
    case "Mean",    s = "Lmean";
    case "Serine",  s = "Lser";
    case "Alanine", s = "Lala";
    case "MinL",    s = "M-in-L";
    otherwise,      s = "Lmean";
end
end


function s = mapMTemplate(matlabName)
% IndividualCMF M_OpsinTemplate -> pycone M template name
switch string(matlabName)
    case "Standard", s = "Standard";
    case "LinM",     s = "L-in-M";
    case "Mean",     s = "Standard";   % MATLAB stores "Mean" as default for M
    otherwise,       s = "Standard";
end
end


function tbl = invokePycone(scriptPath, payload)
payloadJson = jsonencode(payload);
% Pipe payload via stdin to keep it out of the command line.
cmd = sprintf('python3 %s', scriptPath);
[status, out] = systemRun(cmd, payloadJson);
if status ~= 0
    error('compare:PyconeFailure', ...
        'pycone subprocess failed (status %d):\n%s', status, out);
end
tbl = readtableFromText(out);
end


function [status, out] = systemRun(cmd, stdinText)
% Run a shell command, feeding stdinText to stdin, capture stdout.
tmp = tempname;
writelines(stdinText, tmp);
cleanup = onCleanup(@() delete(tmp));
[status, out] = system(sprintf('%s < %s', cmd, tmp));
end


function tbl = readtableFromText(csvText)
tmp = tempname + ".csv";
fid = fopen(tmp, 'w');
fprintf(fid, '%s', csvText);
fclose(fid);
cleanup = onCleanup(@() delete(tmp));
tbl = readtable(tmp);
end


function [maxAbs, maxRel] = compareArrays(matVals, pyVals)
diff = abs(matVals - pyVals);
maxAbs = max(diff(:));
denom = max(abs(pyVals), realmin);
maxRel = max(diff(:) ./ denom(:));
end


function out = ternary(cond, a, b)
if cond
    out = a;
else
    out = b;
end
end


function val = getOr(s, fld, default)
if isfield(s, fld)
    val = s.(fld);
else
    val = default;
end
end


function reenableWarnings(ids)
% Explicitly turn each warning ID back ON. This avoids relying on
% MATLAB's warning(savedState) round-trip, which can leave 'off' rules
% in the rule list if the saved state captured 'off' (e.g. when the
% same ID was suppressed earlier in the session).
for i = 1:numel(ids)
    warning('on', ids{i});
end
end

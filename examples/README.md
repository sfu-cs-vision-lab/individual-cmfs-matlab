# Individual CMF Toolbox Examples

This folder contains 18 worked examples covering the Individual CMF Toolbox API for human cone spectral sensitivities. Each example is a **plain-text MATLAB Live Script** (`.m` file with `%[text]` rich-text annotations). Open one in the MATLAB Editor (R2025a or later) for the rich-text view, or read it directly as commented code.

## Learning Path

Roughly ordered from foundations to advanced usage:

### Foundations
| Example | Topic | Time | Description |
|---------|-------|------|-------------|
| **ex01** | Getting Started | ~5 min | Create your first observer and plot cone fundamentals |
| **ex02** | Standard Observers | ~10 min | CIE 2006 2 deg and 10 deg observers; XYZ color matching functions |

### Physiological Variations
| Example | Topic | Time | Description |
|---------|-------|------|-------------|
| **ex03** | Field Size Effects | ~12 min | Macular pigment + photopigment OD vs field size; algorithm choice |
| **ex04** | Aging Effects | ~12 min | Lens yellowing, the `LensModel` choice, and Custom-mode protection |
| **ex05** | Genetic Variants | ~12 min | Ser180Ala polymorphism, hybrid cones, `Genotype` and `applyGenotype` |
| **ex06** | Photopigment Models | ~10 min | Stockman-Rider 2023 vs Govardovskii 2000 photopigment templates |

### Pipeline & Outputs
| Example | Topic | Time | Description |
|---------|-------|------|-------------|
| **ex07** | Computational Pipeline | ~12 min | Four-stage pipeline using only the public API |
| **ex08** | Output Formats | ~12 min | `energy` / `quantal` / `absorptance` / `absorbance` and `LogOutput` |
| **ex09** | RGB Color Matching | ~12 min | RGB CMFs, negative values, custom display primaries |
| **ex10** | Chromaticity Diagrams | ~10 min | lm and CIE xy chromaticity, spectral locus |
| **ex11** | Photopic Luminance | ~8 min | `Luminance` / V*(lambda); MacLeod-Boynton; genotype, age, and dichromat reductions |

### Observer Comparisons
| Example | Topic | Time | Description |
|---------|-------|------|-------------|
| **ex12** | Observer Comparison | ~12 min | `compareTo`, RMS metrics, multi-observer comparison |
| **ex13** | Dichromacy | ~10 min | Protan/deutan/tritan via `Lod`/`Mod`/`Sod` = 0; XYZ/RGB error path |

### Reference & Reproducibility
| Example | Topic | Time | Description |
|---------|-------|------|-------------|
| **ex14** | Advanced Customization | ~15 min | Every parameter, Custom-mode behaviour, `getParameters` round-trip |
| **ex15** | Data Export | ~8 min | `evaluate`, CSV / MAT; round-trip pointer to Example 14 |
| **ex16** | Normalization Methods | ~10 min | Continuous vs Sampled; reproducing external reference implementations |
| **ex17** | Publication Figures | ~12 min | Six-panel aging composite; vector export via `exportgraphics` |
| **ex18** | Observer Metamerism | ~12 min | A metameric pair breaks for individual observers; xy chromaticity shifts from Ser180Ala and lens aging |

## Running an example

In the MATLAB Editor, open the file and click **Run**. The Editor renders `%[text]` blocks as rich text and shows results inline.

From the command line:

```matlab
addpath('toolbox')                  % once per session
run('examples/Example01_GettingStarted.m')
```

## Prerequisites

- MATLAB R2023b or later (for the modern argument-validation syntax used by the toolbox)
- The Editor recognises this `.m` Live Script format from R2025a onward; older releases will run the code but won't render the rich text
- Individual CMF Toolbox `toolbox/` folder on the MATLAB path

## Live Script format

Each example is a *plain-text* Live Script:

- Sections start with `%%` followed by a `%[text] ## Title` line.
- Narrative text uses `%[text]` prefixes; LaTeX equations are written with double-escaped backslashes.
- Tables, lists, and emphasis use Markdown after the `%[text]` prefix.
- Each file ends with the required `%[appendix]{"version":"1.0"}` block. Leave it in place.

The format is documented in MathWorks' [Plain Text Live Code Files](https://www.mathworks.com/help/matlab/matlab_prog/plain-code-files.html) reference.

## Concepts covered across the series

- CIE 2006 standard observers (2 deg, 10 deg)
- Field size effects (macular pigment, photopigment optical density; CIE 170 endpoints vs Moreland-Alexander / Pokorny-Smith continuous formulas)
- Lens aging and three-lens-model comparison at fixed age (`StockmanRider2023` age-flat vs `Pokorny1987` and `VanDeKraats2007` age-dependent)
- Genetic variants (Ser180Ala polymorphism, hybrid cones M-in-L / L-in-M; `"LSAYT/SAAFA"` is the pycone-default zero-shift baseline)
- Photopigment template choice (Stockman-Rider 2023 vs Govardovskii 2000 A1; A2 for non-human comparative work)
- Four-stage computational pipeline (absorbance -> absorptance -> quantal -> energy) and per-stage access via `OutputFormat`
- Output formats (absorbance / absorptance / quantal / energy) and the Beer-Lambert relative-vs-raw absorptance convention
- Pre-receptoral filter access via `getLensDensitySpectrum` and `getMacularDensitySpectrum`
- Normalization (Continuous vs Sampled; reproducing external reference implementations bit-exactly)
- Custom-mode protection of explicit density overrides (`LensDensityAlgorithm`, `MacularDensityAlgorithm`, `PhotopigmentDensityAlgorithm`)
- Round-trip parameter transfer via `getParameters` / `setParameters` (bit-exact LMS round-trip)
- RGB color matching with custom display primaries; `IndividualCMF:SingularPrimaries` error path for ill-conditioned sets
- Chromaticity diagrams (lm, CIE xy with dichromat error path, MacLeod-Boynton with $V^*(\lambda)$ denominator)
- Photopic luminance $V^*(\lambda)$ (CIE 170-2:2015 coefficients; genotype, age, and dichromat reductions)
- Dichromacy as the limit case (zero optical density); real phenotypes range to partial expression
- Observer metamerism (distinct from illuminant metamerism)
- Multi-observer construction via `IndividualCMF.across(parameter, values, ...)` factory
- Plotting wrappers (`plotLMS`, `plotXYZ`, `plotRGBCMFs`, `plotChromaticity`, `plotLens`, `plotMacular`, `plotAbsorbance`, `plotAbsorptance`, `plotQuantalEnergy`, `plotDiagnostics`, `compareTo`)
- Publication-quality figures and vector export via `exportgraphics(gcf, path, 'ContentType', 'vector')`

## Quick reference

```matlab
% Create a standard observer
obs = IndividualCMF();                    % Default: CIE 10 deg
obs = IndividualCMF(StandardObserver=2);  % CIE 2 deg

% Evaluate cone sensitivities
wl = (380:1:780)';
L   = obs.L(wl);     M = obs.M(wl);     S = obs.S(wl);
LMS = obs.LMS(wl);   RGB = obs.RGB(wl); XYZ = obs.XYZ(wl);

% Customize physiology
obs = IndividualCMF(LensModel="VanDeKraats2007", Age=50, FieldSize=4);
obs = IndividualCMF(L_OpsinTemplate="Serine", L_LambdaMaxShift=2);
obs = IndividualCMF(Genotype=struct('L_180', 'Ala'));
obs.applyGenotype("LSAYT/SAAFA");

% Plot wrappers
obs.plotLMS();                  % L, M, S overlay
obs.plotXYZ();                  % CIE 2015 XYZ CMFs
obs.plotChromaticity();         % lm spectral locus
obs.plotLens();                 % lens density spectrum
obs.plotLMS(Cones="S", Log=true);  % S-cone only, log10 y-axis
obs.compareTo(other);           % two-observer overlay

% Build an array of observers across one parameter axis
observers = IndividualCMF.across('Age', [25 50 75], ...
    LensModel="VanDeKraats2007", FieldSize=10);
densities = [observers.LensDensity];

% Output and normalization
obs.OutputFormat = "quantal";
obs.NormalizationMethod = "Sampled";

% Override densities (auto-engages "Custom" algorithm modes)
obs.LensDensity    = 2.5;   % engages LensDensityAlgorithm = "Custom"
obs.MacularDensity = 0.4;
obs.Lod = 0.45;

% Round-trip observer state
params = obs.getParameters();   % captures everything that affects LMS
obs2.setParameters(params);     % obs2 now matches obs exactly

% Export
data = obs.evaluate(wl, Data='LMS', Format='table');
writetable(data, 'cone_fundamentals.csv');
```

## Feedback

If you find issues or have suggestions, please open an issue on the GitHub repository.

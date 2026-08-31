# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0]

First release outside the beta line, and the first listed on MATLAB File Exchange. No code changes from 0.1.0-beta.7; the seven beta entries below record how it was built.

Under Semantic Versioning a major version of zero means the interface is still developing, and that remains true here. The one change already anticipated is the continuous L to M template morph, which is deferred until the reference implementation settles it.

What the toolbox does:

- Computes observer-specific LMS cone fundamentals from biophysical inputs: opsin genotype, age, retinal field size, and lens, macular and photopigment optical densities.
- Derives RGB colour matching functions, CIE XYZ, photopic luminance, and MacLeod-Boynton, lm and CIE xy chromaticity from those fundamentals.
- Reproduces the CIE 170-1:2006 two and ten degree standard observers with its defaults, through the Stockman and Rider (2023) formulae.
- Matches the pycone reference implementation to machine precision across 38 parity configurations.
- Offers alternative published models for research use: Govardovskii et al. (2000) A1 and A2 photopigment templates, and the Pokorny, Smith and Lutze (1987) and van de Kraats and van Norren (2007) lens models.
- Ships twenty worked examples, a Getting Started guide, and a Help Browser reference generated from the class metadata.

Requires R2023b or later. Rendering the examples as Live Scripts needs R2025a.

## [0.1.0-beta.7]

An interface-breaking release: five phases of simplification, collapsing duplicated internals and bringing the API into line with what each model supports. Fourteen changes alter existing call sites. The migrations are listed first; the reasoning is in the sections below.

Values on explicitly supplied wavelength grids are unchanged except for the two Govardovskii fixes noted under Fixed. pycone parity holds at 38/38 configurations.

### Migration

| Was | Now |
| --- | --- |
| `CMFPlotter` | Removed. Call the `plot*` methods with `Parent=<TiledChartLayout>`. |
| `plotDiagnostics(Plotter=p)` | `plotDiagnostics(Parent=t)` where `t = tiledlayout(...)` |
| `NormalizationMethod=<struct>` | `NormalizationMethod=<enum>` plus `NormalizationGrid=<vector>` |
| `NormalizationConfig` | Removed; folded into the two options above. |
| `evaluate(..., Format="array")` | `obs.LMS(wl)` or another named method |
| `evaluate(..., Format="struct")` | `table2struct(obs.evaluate(wl), ToScalar=true)` |
| `evaluate(Data="chromaticity")` | `Data="lmChromaticity"`, returning `(l, m)`; the third column is `1 - l - m` |
| `ObserverParameters.standard2Deg()` | `IndividualCMF(StandardObserver=2).getParameters()` |
| `ObserverParameters.standard10Deg()` | `IndividualCMF(StandardObserver=10).getParameters()` |
| `ObserverParameters.fromGenotype("L_180_Ala")` | `IndividualCMF(Genotype=struct('L_180','Ala')).getParameters()` |
| `obs.LensDensityAlgorithm = "Custom"` | `obs.LensDensity = obs.LensDensity` (assign the value, and `Custom` follows) |
| `obs.WavelengthWarning` | `obs.ModelRangeWarning` |
| `obs.LMS()` and friends, no argument | Still valid, but now returns 471 samples rather than 401 |
| `IndividualCMF(StandardObserver=N, LensModel=...)` | Build with `Age=` and `FieldSize=` instead |

### Added
- `IndividualCMF.neutralColor()`, a static returning black on a light figure theme and white on a dark one. Reference lines (zero lines, `y = 1` guides, difference baselines) were hardcoded black and disappeared against MATLAB's dark theme. The colour resolves at call time, so it follows a theme switch. Guarded on `isprop(fig,'Theme')`, which is R2025a and later; earlier releases get black, as before.
- Example 03, on how an observer is assembled. It covers the three stacked components and the two independent controls each carries -- a `...Model` for spectral shape, a `...DensityAlgorithm` for the scalar magnitude -- and settles what `CIE170` mode selects: any field size is supported, by falling through to the same continuous formulas the standard's tables were fitted to, with the tabulated values substituted back in at exactly 2 and 10 degrees. Examples 03 through 18 shift to 04 through 19.
- A generated Help Browser reference. `toolbox/info.xml` registers the toolbox with MATLAB, and `buildtool doc` writes 150 pages covering 30 classes: the observer and the types that configure it, the photopigment, lens and macular models, the enumerations naming their legal settings, and the pipeline stages. Every page is derived from `meta.class`, so the reference cannot disagree with the source, and the help comments in the class files remain the only place any of it is written. `buildtool package` depends on the doc task, so a packaged `.mltbx` always ships current pages. Reach it with `doc Individual CMF Toolbox`.
- An Examples section in the Help Browser. All twenty worked examples are exported with their figures and printed output, so they can be read without opening MATLAB, and the Getting Started guide sits above them. The reference landing page opens with seven common tasks, each linked to the example that answers it, and every group of classes links the examples that bear on it: the lens models point at Example 08, where the choice between the three is argued.
- Worked `EXAMPLE` blocks on twenty-four methods, covering the sensitivity accessors, the derived quantities, both density getters, `setGenotype` and all ten plotting methods on `IndividualCMF`, and four on `Genotype`. A test extracts every one of them and runs it, so an example that does not work fails the suite rather than being published as the way to call the method.

### Removed
- `CMFPlotter`. The class reimplemented subplot management, color assignment, and axis styling that MATLAB's `tiledlayout` has shipped since R2019b. Every `plot*` method now takes `Parent=<TiledChartLayout>` and composes with any layout you build yourself, including nested ones. Net 1,931 lines deleted.
- `ObserverParameters.standard2Deg`, `.standard10Deg`, and `.fromGenotype`. All three were thin wrappers over an `IndividualCMF` construction followed by `getParameters()`, and `fromGenotype` had a latent defect (see Fixed).
- `NormalizationConfig`, and the struct form of `NormalizationMethod`.
- The `SupportsShift` and `SupportsAging` template capability flags, and `getValidRange()`. Nothing read any of them.
- `evaluate`'s `Format` argument. It always returns a table.
- The analytical-peak mechanism for photopigment templates. Both Stockman-Rider templates claimed an analytical peak of exactly `1.0` against a measured `0.9944520`, so every consumer of the "exact" value was reading a worse number than the search would have found.

### Changed
- **BREAKING** `evaluate` returns a table and delegates to the named methods rather than reimplementing them, so `evaluate` and `obs.LMS` can no longer drift apart.
- **BREAKING** `NormalizationMethod` is an enum, with the wavelength grid supplied separately as `NormalizationGrid`. The four struct-shaped error paths collapse to `mustBeNonempty` and `mustBeFinite`; an invalid method name now raises `MATLAB:validation:UnableToConvert` from the enum conversion.
- **BREAKING** `<X>DensityAlgorithm = "Custom"` errors with `IndividualCMF:CustomIsNotAssignable`, from the constructor as well as the setters. `Custom` is a state you observe after assigning a density, not one you request. Assigning `[]` to a density reverts to the model-computed value.
- **BREAKING** `obs.LMS()`, `obs.RGB()`, `obs.Luminance()`, `obs.MacLeodBoynton()`, `obs.lmChromaticity()`, and `obs.evaluate()` called with no argument return 471 samples on the default grid, not 401. `L`, `M`, `S`, `XYZ`, `xyChromaticity`, and the plot methods already used the default grid and are unchanged.
- **BREAKING** `WavelengthWarning` is renamed `ModelRangeWarning`, since it now governs age-range warnings as well as wavelength ones.
- **BREAKING** `IndividualCMF(StandardObserver=N, ...)` errors if given a non-default `LensModel` or `MacularModel`, or any `*DensityAlgorithm` option. A standard observer is defined by the CIE 170-1:2006 filter models; accepting a substitute and still calling the result standard was the API promising something it did not deliver.
- **BREAKING** `IndividualCMF(LensModel="Pokorny1987", Age=)` errors outside 20-80 years with `IndividualCMF:AgeOutsideModelDomain`. That is the range Pokorny, Smith & Lutze (1987) fitted; outside it the linear aging term is extrapolation.
- **BREAKING** `S_LambdaMaxShift` is bounded to `[-40, 30]`, the range `L_LambdaMaxShift` and `M_LambdaMaxShift` already used. See Fixed for why an unbounded shift was not merely inaccurate.
- **BREAKING** The `IndividualCMF` constructor takes `[]` rather than `NaN` as its "not supplied" sentinel, and uses stdlib validators in place of two custom ones. Density arguments given `NaN` or `Inf` now raise `MATLAB:validators:mustBeNonnegative` and similar, rather than the toolbox's own identifiers.
- Templates declare `ValidRange` and `Domain` as properties, and both are enforced in `computeRawSensitivity`, which every sensitivity path routes through.
- `L`, `M`, and `S` accept the same per-call overrides `LMS` does.
- Photopigment, lens, and macular templates resolve through a `REGISTRY` on their base class, so adding a template no longer means editing a dispatch list in `IndividualCMF`.
- `plotDiagnostics` builds its own `tiledlayout` rather than requiring a plotter.
- `exampleDefaults` gained a documented `reset` action; it sets `groot` defaults that outlive the example.

### Fixed
- **BREAKING** Govardovskii absorptance normalizes to the maximum of the alpha+beta curve rather than to the value at lambda-max. The beta band displaces the true peak away from lambda-max, so the old divisor was not the maximum and normalized output exceeded 1. Output shifts by up to 0.24% (A2) and 1.3e-05 (A1) for `OutputFormat="absorptance"` with `NormalizeOutput=true`. Absorbance, quantal, energy, and `Sampled` mode are unchanged, as are all Stockman-Rider models.
- **BREAKING** The Govardovskii alpha-band `a` coefficient is stored as the three constants of the paper's Eq. 2 (`0.8795`, `0.0459`, `300`, `11940`) rather than as a pre-divided pair. A1 output shifts by up to 1.14e-03 relative on the long-wave limb; peak values move by under 5.3e-07. A2 is unaffected. `tests/data/govardovskii_reference.csv` is regenerated from `tests/parity/regen_govardovskii.m`, a transcription of the published equations that never calls `Nomograms`.
- Neither Govardovskii fix is covered by pycone parity, which has no Govardovskii configuration.
- The out-of-domain floor was applied in one of the five callers of `computeRawSensitivity`. `obs.LMS(300)` correctly returned 0 while `obs.RGB(300)` returned 4.201e+153, and a `NormalizationGrid` reaching outside the domain drove `L(550)` to 3.301e-14 instead of 0.9565. The floor now lives in the shared function.
- `setParameters` validated an incoming lens model against the *old* age, so a single call that moved both could be rejected on a combination it was not being asked to produce. Age and field size are now written first.
- `copyElement` silently substituted a default template when copying an observer that used a non-default one.
- `ObserverParameters.fromGenotype` ignored an unrecognised genotype position, so a typo returned standard-observer numbers while the caller believed a variant had been applied. The replacement path errors. An unrecognised amino acid at a valid position still contributes no shift, as before.
- The Stockman-Rider common photopigment template warned on every absorbance call.
- `plotAbsorbance` and `plotQuantalEnergy` skip cones with zero optical density instead of plotting a flat zero trace as though it were data. Dichromat observers now produce a figure showing only the cones they have, matching what the other plot wrappers already did.
- `plotDiagnostics` no longer renders as a tall narrow strip. The layout is sized for its panel count, the sensitivity panel's y-axis stops at 1.0 rather than being driven by a stray outlier, and the legend no longer overlaps the last panel.
- `LMS`/`L`/`M`/`S` return 0, and `getLensDensitySpectrum` returns NaN, below 400 nm for `Pokorny1987` observers and below 360 nm for Stockman-Rider observers. Both previously returned flat-extrapolated or divergent values; the Stockman-Rider Fourier templates diverge outside their fitted half-period rather than decaying.
- The documentation build shipped blank pages. Running one example through `export` empties `Description` and `DetailedDescription` on every enumeration class for the rest of the session, and `rehash` does not bring them back; three enumerations were measured going from 46, 33 and 36 characters to zero. `buildtool` runs the tests, several of which run examples, before the doc task, so the build read corrupted metadata and put out an enumeration page with a blank purpose and four blank value descriptions. Which enumerations were affected varied between runs.
- Documentation figures followed the desktop theme of whatever machine built them. On a dark one `neutralColor` returns white, which is white lines on a light page. The build pins the theme to light, through a temporary value that never touches the saved preference.
- `buildtool doc` left the session restyled, since every example opens with `exampleDefaults`, which sets nine `groot` defaults and never restores them.
- Every cross-reference in the Getting Started guide was dead in the Help Browser. Exporting drops the `matlab:` scheme and leaves a relative link to a source file that is not in the doc folder.
- A label nested inside a property listing became a top-level heading and took the rest of the block with it, filing every `CIE170` constant under "Standard observer".
- The `LensModel` property description listed `StockmanRider2023` and `Pokorny1987` and omitted `VanDeKraats2007`. The constructor documentation and the enumeration both had all three.

### Documentation
- All twenty examples and the Getting Started guide revised for a consistent voice, following the vocabulary of the reference papers (Stockman 2008, 2019; Stockman & Rider 2023; Stockman & Sharpe; the pycone software instructions). Sensitivity is described by what it does at particular wavelengths, numeric claims are stated plainly with the reason attached, and terms are explained where a reader first meets them.
- Explanation that had drifted into the wrong section was moved or cut. The account of how peak normalization acts on each cone had been written into the visual-comparison section of the standard-observers example, which only needs to show the two observers, and duplicated the difference section below it.
- Two numbers corrected in the field size example. The difference between the formulae and the CIE table at 10 deg is 0.052%, not the 0.0052% stated. The S-cone section quoted macular optical densities for the 2 deg observer while comparing a 1 deg observer against a 10 deg one; for the 1 deg observer those densities are 0.3537 at 443 nm and 0.4168 at 457 nm.
- Three missing section breaks restored, in the observer-comparison, dichromacy and publication-figures examples, where two headings shared one section because no `%%` separated them.
- Every worked example and the Getting Started guide were reviewed twice, with each numeric claim re-run against the toolbox rather than read. Corrections fall into four kinds: claims stated in the wrong direction (a normalized flank described as depressed where it is lifted, a long-wavelength loss that is a gain for deuteranopes, an aging effect attributed to the wrong RGB primary); figures whose axis limits excluded the effect being discussed; wrapper behaviour described as unconditional when it follows the observer's output settings; and summary lines left asserting what a corrected section body no longer said.
- Corrected a transpose in the observer-comparison example that flattened a results matrix column-major under wavelength-major column names, mislabelling six of nine printed values. One column read 0.1266 where the true value was 3.07e-06.
- `A(lambda_max) = 1` is described as the anchoring convention it is, not a measured equality, in the six places it appeared. The Fourier fit puts the L peak at 0.99494485.
- The 2.7 nm Ser180Ala figure is the separation between the Serine and Alanine templates. The standard observer uses the population-mean template, so the distance from it to Alanine is 1.51 nm at the photopigment and 1.63 nm at the fundamental peak.
- The metamerism example now explains the `IndividualCMF:NonStandardObserver` warning it raises, rather than leaving it unmentioned. There is no standardized LMS-to-XYZ matrix for an individual observer; holding the standard matrix fixed is what isolates the observer difference, at the cost of the outputs being individual colorimetric values.
- `ARCHITECTURE.md` brought back in line with the code. The class diagram documented `computePeakAbsorbance`, which went with the analytical-peak mechanism, and the instructions for adding a template still told a contributor to implement it. The layering diagram was missing `StockmanRiderCommonPhotopigmentTemplate`. The repository layout undercounted the examples, listed three build tasks where there are five, and omitted `info.xml`, without which the Help Browser cannot find the toolbox. A new section covers the generated reference.

### Notes
- `S_LambdaMaxShift` was previously unbounded on the stated grounds that S is left open for cross-species work. Outside roughly `[-50, +30]` the Stockman-Rider template stops being evaluable: it is an 8th-order Fourier series fitted over half a period (log 360 to log 850 nm mapped to 0 to pi), and past that arc it climbs again. The peak search tracks the shifted peak near 362 nm and never samples the far end, so normalization does not catch it. At a -55 nm shift the raw template returns 2.2e+03 at 830 nm and normalized "sensitivity" reached 149.8. The more dangerous case is -50, which returns 5.3e-04 where truth is ~1e-12 -- small enough to read as a genuine long-wavelength tail. pycone applies the same formula with no bound and breaks identically (`Sconelog` returns 2200.52 at -55 and `inf` at +240), so the bound is deliberate hardening beyond the reference, not a divergence from it.
- The documentation build goes from about nine seconds to roughly three minutes, because the examples now run so their figures can be captured, and the generated documentation is about 10 MB, nearly all embedded figures. `buildtool package` inherits both. Nothing in this release changes the packaged toolbox code.

## [0.1.0-beta.6]

### Added
- Direct lambda-max shifts now switch the L/M cone template on magnitude, matching pycone 1.0.3. A large positive `M_LambdaMaxShift` makes the M cone borrow the L template, and a large negative `L_LambdaMaxShift` makes the L cone borrow the M template, at the trip points pycone uses (`M_LambdaMaxShift >= 18.41` nm and `L_LambdaMaxShift <= -16.0345` nm). Previously only an opsin genotype (amino acids 277 and 285) triggered the swap, and the genotype path is unchanged. Verified against pycone by ten new parity configurations, including the gap cases that fix the trip point, and by behavioral tests that assert the thresholds directly.

## [0.1.0-beta.5]

### Added
- `PhotopigmentModel="StockmanRider2023Common"`: the Stockman & Rider (2023) common (shape-invariant) photopigment template (Table 4, column 3), a single Fourier shape translated along log-wavelength to fit any cone, for cross-species and arbitrary lambda-max use. A sibling to the existing Govardovskii option and off the CIE parity path. Includes a new Example 06 section, unit tests, and a regenerator (`tests/parity/regen_golden.m`, `regen_golden.py`) for the pycone-derived golden fixtures.
- Acknowledgments section in the README thanking Andrew Stockman and Andy Rider (UCL Institute of Ophthalmology) for reviewing the toolbox.

### Changed
- Parity reference pinned to pycone 1.0.3 (commit `344f779`), with the Stockman-Rider template anchors matched to it (`SR_M_LMAX` 529.9 to 529.8, `SR_S_LMAX` 416.9 to 417.0, and the trailing S coefficient). These anchors are inert at zero shift, so the CIE standard observers are unchanged on normalized output and parity holds at 140/140.
- README and `tests/parity/README.md` reworked to describe the relationship to pycone in terms of parity and the points where the two implementations can differ.
- Documented that a direct `LensDensity` / `MacularDensity` / `Lod` / `Mod` / `Sod` assignment engages the corresponding `Custom` density algorithm and pins the value across later `Age` / `FieldSize` / `LensModel` changes (README, `IndividualCMF` docstring, Examples 04 and 14).
- Noted in the README and Example 04 that the Pokorny, Smith & Lutze (1987) lens template holds its 400 nm value flat below 400 nm; `VanDeKraats2007` is suggested for sub-400 nm work.
- Example 08 display-primary table rows relabeled so they read as the 615/545/465 nm primaries rather than naming the L/M/S cones.

### Fixed
- Corrected two provenance comments in `toolbox/Nomograms.m`: the `SR_L_COEFFS` are the S&R 2023 Table 4 column 2 L(ser180) template (not Table 1), and the Mean L template is reconstructed at evaluation time from the 0.56/0.44 Serine/Alanine combination originating in Stockman & Sharpe (2000).

## [0.1.0-beta.4]

### Added
- The worked examples and a new **Getting Started guide** now ship inside the `.mltbx` and install on the MATLAB path (adopts the [MathWorks toolbox layout](https://github.com/mathworks/toolboxdesign)). The guide (`toolbox/doc/GettingStarted.m`) is registered with the Add-On Manager and gives a one-minute orientation plus a linked index of the examples; reach it from the command window with `open GettingStarted`.
- `LICENSING.md` documenting the AGPL-3.0 posture (academic, individual, and industry-internal research use are permitted, including corporate-authored publications; productization in closed-source products or SaaS requires a commercial license) and the contact path for commercial inquiries.

### Changed
- Repository restructured to the MathWorks toolbox layout: `examples/` moved to `toolbox/examples/` so it packages with the toolbox. `Example01_GettingStarted.m` renamed to `Example01_Basics.m`, since the getting-started role now belongs to the registered guide. Example numbering and content are otherwise unchanged.
- `buildtool check` now scopes static analysis to library source, excluding the bundled tutorial scripts.

## [0.1.0-beta.3]

### Added
- Support for MATLAB R2026a in the declared `MaximumMatlabRelease` window and the CI test matrix. Resolves the Add-On installer rejection ("not supported for this MATLAB release") that R2026a users hit on `0.1.0-beta.2`.
- Versionless `individual-cmfs-matlab.mltbx` asset attached to each release, served by the `releases/latest/download/...` redirect URL so the README install snippet stays evergreen across releases.

### Changed
- README install snippet downloads via the latest-redirect URL instead of hardcoding the versioned `.mltbx` filename.
- Hero figure caption rewritten to accurately describe what the per-cone-peak-normalized rendering actually shows (short-wavelength shoulder narrowing on L and M), with a note that in absolute units S is the most attenuated.

### Fixed
- `CMFPlotterTest/testExportFigureWritesValidFormat` now tolerates the environmental `MATLAB:graphics:HardwareUnavailable` warning that R2026a emits on headless CI runners with no GPU.

## [0.1.0-beta.2]

### Added
- Initial repository open-source governance framework (`CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`).
- Automated Contributor License Agreement (CLA) enforcement gate via CLA Assistant.

## [0.1.0-beta.1]

### Added
- Initial release of the MATLAB Individual Cone Fundamentals Toolbox framework.
- Strictly validated 4-stage biophysical computation pipeline adhering to CIE 170-1:2006 and CIE 170-2:2015 standards.
- Production-grade observer parameter state management via value-object snapshots.
- Continuous peak normalization caching utilizing continuous optimization space to prevent grid-step drift.
- Automated testing harness executing comprehensive static analysis checks and unit validation.
- Verification matrix enforcing machine-precision parity with cross-language reference implementations.

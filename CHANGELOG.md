# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

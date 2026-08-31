# Pycone parity tests

This folder verifies that `IndividualCMF` produces the same numerical
output as the reference Python implementation
[pycone (CVRL-IoO/Individual-CMFs)](https://github.com/CVRL-IoO/Individual-CMFs)
when both are fed identical inputs.

## Layout

```
tests/parity/
|-- configs.json    38-configuration list (parameters pycone supports)
|-- run_pycone.py   One-shot pycone evaluator (called per-config)
|-- compare.m       MATLAB driver: build observer, query resolved values,
|                   invoke run_pycone.py with those values, diff outputs
|-- pycone/         Cloned reference repo (gitignored)
`-- README.md       This file
```

## How to run

```bash
# 1. Clone the pycone reference, pinned to the pycone 1.0.3 commit
cd tests/parity
git clone https://github.com/CVRL-IoO/Individual-CMFs.git pycone
git -C pycone checkout 344f779   # pycone 1.0.3
```

```matlab
% 2. Run the comparison from MATLAB
cd tests/parity
compare
```

`compare.m` constructs an `IndividualCMF` for each configuration in
`configs.json`, queries its resolved biophysical parameters
(`LensDensity`, `MacularDensity`, `Lod`/`Mod`/`Sod`, lambda-max shifts,
opsin template choice), shells out to `run_pycone.py` with those exact
values, and diffs the resulting LMS arrays at every output format
(`absorbance`, `absorptance`, `quantal`, `energy`).

To enable an apples-to-apples comparison, the driver forces MATLAB to
use `NormalizationMethod = "Sampled"` on the same wavelength grid
pycone uses, so peak detection happens identically on both sides. With
that out of the picture, the comparison tests only the mathematical
pipeline (templates -> absorptance -> corneal -> output format).

### Why Sampled normalization is needed for parity

`IndividualCMF`'s default `NormalizationMethod = "Continuous"` differs
from pycone. It uses `fminbnd` to locate the peak of the continuous
spectral model, so the normalized `peak = 1` is independent of which
wavelengths the user evaluates at. pycone normalizes to the maximum of
the sampled spectrum, so its `peak = 1` depends on the sampling grid.

Both methods are mathematically valid; they answer slightly different
questions. The toolbox exposes both, via `NormalizationMethod =
"Continuous"` (default) and `"Sampled"` (matches pycone). For this
parity test we use `"Sampled"` so the two implementations agree on what
`peak = 1` means.

### Other notes

- **Absorbance is never normalized** (in either implementation). The
  template is already normalized to 1.0 at the true sub-grid
  `lambda_max`; sample-grid renormalization would distort it. See the
  "Note on absorbance normalization" section below.
- **Corneal-stage values** (quantal, energy) inherit the sampled-peak
  approximation when normalized - hence their slightly larger
  parity residual (~9e-12 vs ~2e-13 for absorbance/absorptance).
- **Output-format ordering**: when `LogOutput=true`, both
  implementations apply linear normalization first, then `log10` last.

## Coverage

The 38 configurations exercise only features pycone supports, so every
configuration is expected to match to machine precision. Configurations
that use MATLAB-only features (Pokorny lens model, Mean->Serine
auto-switch on L_LambdaMaxShift, un-normalized output convention) are
deliberately excluded.

| #  | Configuration                                              |
|----|------------------------------------------------------------|
| 01 | CIE 2006 2-deg standard observer                           |
| 02 | CIE 2006 10-deg standard observer                          |
| 03 | FieldSize=4 deg (formula-based densities)                  |
| 04 | FieldSize=6 deg                                            |
| 05 | FieldSize=8 deg                                            |
| 06 | L_OpsinTemplate=Serine                                     |
| 07 | L_OpsinTemplate=Alanine                                    |
| 08 | L_OpsinTemplate=Serine + L_LambdaMaxShift=+2 nm            |
| 09 | L_OpsinTemplate=Serine + L_LambdaMaxShift=-3 nm            |
| 10 | L_OpsinTemplate=Alanine + L_LambdaMaxShift=-1 nm           |
| 11 | M_LambdaMaxShift=-2 nm                                     |
| 12 | M_LambdaMaxShift=+3 nm                                     |
| 13 | S_LambdaMaxShift=+2 nm                                     |
| 14 | Custom LensDensity=2.0 (default StockmanRider lens, age 32)|
| 15 | Custom MacularDensity=0.6                                  |
| 16 | Custom Lod=0.5                                             |
| 17 | Custom Mod=0.45                                            |
| 18 | Custom Sod=0.35                                            |
| 19 | LogOutput=true (standard 10-deg)                           |
| 20 | Combined: Serine + L/M/S shifts + custom densities         |
| 21 | Sub-nm sampling: 390-780 at 0.5 nm steps                   |
| 22 | Sub-nm sampling: 400-700 at 0.1 nm steps                   |
| 23 | Edge wavelengths: 360-780                                  |
| 24 | Edge wavelengths: 390-830                                  |
| 25 | Full pycone range: 360-830                                 |
| 26 | Hybrid M-in-L (L cone uses M template at L position)       |
| 27 | Hybrid L-in-M (M cone uses Lser template at M position)   |
| 28 | Both hybrids combined with non-zero L/M shifts             |
| 29 | Direct M shift +18.0 nm, below the 18.41 trip point: no swap |
| 30 | Direct M shift +18.25 nm, inside the 18.13-18.41 gap: no swap |
| 31 | Direct M shift +18.3 nm, just below 18.41: no swap         |
| 32 | Direct M shift +18.5 nm, just above 18.41: M uses L template |
| 33 | Direct M shift +22.0 nm, well above 18.41: M uses L template |
| 34 | Direct L shift -15.8 nm, above the -16.0345 trip point: no swap |
| 35 | Direct L shift -15.9 nm, inside the -15.79 to -16.0345 gap: no swap |
| 36 | Direct L shift -16.2 nm, just below -16.0345: L uses M template |
| 37 | Direct L shift -20.0 nm, well below -16.0345: L uses M template |
| 38 | Past both trip points (M +22.0, L -20.0): both cones swap  |

Each configuration is compared at all four LMS pipeline stages
(`absorbance`, `absorptance`, `quantal`, `energy`) **plus** RGB
color matching functions, giving 38 x 5 = 190 total comparisons.

## Latest result

Against pycone 1.0.3 (commit `344f779`), numpy 2.0.2, scipy 1.13.1:

```
=== Parity summary (vs pycone, MATLAB-resolved inputs) ===
  Comparisons: 190 (38 configs x 5 formats: 4 LMS stages + RGB)
  PASSED:      190
  FAILED:      0
  AbsTol:      1e-10
  RelTol:      1e-09
```

Observed residuals: ~2e-13 for absorbance/absorptance and ~9e-12 for
quantal/energy/RGB, all at machine precision. The one outlier is config
19 (`LogOutput=true`), where the corneal stages reach ~5.5e-08 absolute;
it passes on relative tolerance, since `log10` magnifies small
differences where the linear value is near zero.

## Note on absorbance normalization

MATLAB's `IndividualCMF` deliberately **does not** apply
`NormalizeOutput` to the `"absorbance"` format. The photopigment
absorbance template is already normalized to 1.0 at the true (sub-grid)
`lambda_max`; sample-grid renormalization would slightly distort it.
`run_pycone.py` follows the same convention: only `absorptance`,
`quantal`, and `energy` are normalized in linear space, with `log10`
applied last when `LogOutput=true`. `absorbance` passes through raw.

## Differences not covered by the parity test

A few features and implementation details differ between the two
implementations. The harness handles them by either excluding
configurations that pycone has no equivalent for, or aligning the two
sides so the comparison is apples-to-apples. They are noted here for
transparency.

The toolbox includes models and conveniences pycone does not (alternative
photopigment and lens templates, continuous normalization, the
Mean->Serine shift guard, and custom-mode density protection). The parity
test excludes configurations that rely on these, since pycone has no
equivalent path to compare against (see also Coverage, above).

**Implementation details the harness aligns:**

- pycone applies normalization within its conversion functions, so the
  harness applies the same normalization to the MATLAB output; the
  corneal-stage outputs are then compared on equal terms.
- MATLAB's `(start:step:stop)'` and pycone's `np.arange` can produce
  wavelength samples that differ by a small floating-point amount at
  fine step sizes (visible as ~1e-5 in normalized output at 0.1 nm
  steps, through `log10(nm)` inside the templates). The harness uses a
  consistent grid so grid construction does not affect the comparison.

## Updating after pycone changes

Re-clone or `git pull` inside `tests/parity/pycone/`, then re-run
`compare`. If a previously passing configuration starts failing, the
diff is meaningful and worth investigating.

## Note on the existing tests/data/*.csv snapshots

The 11 CSV files in `tests/data/` predate this folder. They are
pycone-derived snapshots used by `tests/ReferenceParityTest.m`,
`tests/StandardObserverTest.m`, and several others. Those tests
verify that current MATLAB output still matches the pycone snapshots
captured at some earlier point in time. The harness in this folder
goes one step further by running pycone freshly on each comparison.

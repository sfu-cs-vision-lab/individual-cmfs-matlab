# Pycone parity tests

This folder verifies that `IndividualCMF` produces the same numerical
output as the reference Python implementation
[pycone (CVRL-IoO/Individual-CMFs)](https://github.com/CVRL-IoO/Individual-CMFs)
when both are fed identical inputs.

## Layout

```
tests/parity/
|-- configs.json    20-configuration list (parameters pycone supports)
|-- run_pycone.py   One-shot pycone evaluator (called per-config)
|-- compare.m       MATLAB driver: build observer, query resolved values,
|                   invoke run_pycone.py with those values, diff outputs
|-- pycone/         Cloned reference repo (gitignored)
`-- README.md       This file
```

## How to run

```bash
# 1. Clone the pycone reference
cd tests/parity
git clone --depth 1 https://github.com/CVRL-IoO/Individual-CMFs.git pycone
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

`IndividualCMF`'s default `NormalizationMethod = "Continuous"` is a
deliberate improvement over pycone. It uses `fminbnd` to locate the
true peak of the continuous spectral model, so the normalized
`peak = 1` is independent of which wavelengths the user happens to
evaluate at. Pycone, by contrast, normalizes to the maximum of the
discretely sampled spectrum, which means its `peak = 1` shifts
slightly with the sampling grid (the true peak between integer-nm
samples is never exactly captured).

Both methods are mathematically valid - they're just answering subtly
different questions. The toolbox exposes both via
`NormalizationMethod = "Continuous"` (default, more accurate) or
`"Sampled"` (matches pycone, useful for reproducing pycone results).
For this parity test we use `"Sampled"` so the two implementations
can agree on what "peak = 1" means; in normal use, `"Continuous"` is
preferable.

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

The 20 configurations exercise only features pycone supports, so every
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

Each configuration is compared at all four LMS pipeline stages
(`absorbance`, `absorptance`, `quantal`, `energy`) **plus** RGB
color matching functions, giving 28 x 5 = 140 total comparisons.

## Latest result

```
PASSED: 140/140 comparisons (28 configs x 5 formats: 4 LMS stages + RGB)
maxAbs: ~2e-13 for absorbance/absorptance,
        ~1e-11 for quantal/energy/RGB (all machine precision)
AbsTol: 1e-10
RelTol: 1e-9
```

## Note on absorbance normalization

MATLAB's `IndividualCMF` deliberately **does not** apply
`NormalizeOutput` to the `"absorbance"` format. The photopigment
absorbance template is already normalized to 1.0 at the true (sub-grid)
`lambda_max`; sample-grid renormalization would slightly distort it.
`run_pycone.py` follows the same convention: only `absorptance`,
`quantal`, and `energy` are normalized in linear space, with `log10`
applied last when `LogOutput=true`. `absorbance` passes through raw.

## Where MATLAB is more correct than pycone

The parity work surfaced several places where this MATLAB toolbox is
genuinely better than the pycone reference. None of these were
"corrected" toward pycone in the harness; the harness either follows
MATLAB's correct behavior or sidesteps the issue.

1. **`absorptancefromabsorbance` log-mode bug in pycone.** Looking at
   `pycone/CMFcalc.py`:
   ```python
   if loglin == 'log':
       for n in range(1, 4):
           LMSabtanceout[:,n] = np.log10(LMSabsf[:,n])  # log10 of INPUT
   ```
   It overwrites the just-computed absorptance with `log10(absorbance)`
   - i.e., logs the wrong stage. MATLAB's `IndividualCMF` produces the
   correct log-absorptance.

2. **Pycone normalizes inside every conversion function.**
   `corneafromlinabsorptance`, `energyfromquantalin`,
   `quantafromenergylin`, etc. all end with `LMSout /= np.max(LMSout)`.
   This conflates pipeline computation with output presentation: there
   is no way to obtain pycone's raw, un-normalized corneal output
   without running it once and then "un-normalizing" by hand. MATLAB
   keeps these separate (raw pipeline + explicit `NormalizationCache`
   layer that respects `NormalizeOutput`).

3. **Pycone's main wavelength grid uses `np.arange(360, 850+step, step)`.**
   At sub-nm step sizes (0.1 nm, 0.05 nm) `np.arange` accumulates
   floating-point drift of order `1e-11 * num_steps` because 0.1 isn't
   exact in IEEE754. After `np.log10(nm)` inside the templates this
   becomes visible (~1e-5 in normalized output at 0.1 nm step). MATLAB's
   `(start:step:stop)'` does not exhibit this drift; pycone's GUI may.

4. **No `Pokorny1987` lens template in pycone.** Pycone supports only
   the Stockman-Rider 2023 age-invariant lens model. MATLAB additionally
   provides the age-dependent two-component Pokorny et al. (1987) lens
   template, which is essential for modeling observers older than 32.

5. **No Govardovskii template in pycone.** MATLAB supports
   `PhotopigmentModel="Govardovskii2000"` for the continuous A1 visual
   pigment template; pycone's photopigment templates are
   Stockman-Rider only.

6. **No `NormalizationMethod="Continuous"` in pycone.** Pycone's
   "peak = 1" is the maximum of a discrete sample grid, which shifts
   slightly with the wavelength sampling. MATLAB's default
   `Continuous` mode uses `fminbnd` to locate the true sub-grid peak,
   giving sampling-independent normalization.

7. **No Mean->Serine auto-switch guard.** When the user assigns a
   non-zero `L_LambdaMaxShift` to a Mean L-cone template, MATLAB warns
   and switches to the Serine template (the Mean template is a fixed
   weighted average that cannot accept a shift parameter). Pycone has
   no equivalent guard - applying a shift to the Lmean is undefined
   there.

8. **No Custom-mode protection.** MATLAB tracks a `*DensityAlgorithm`
   state per density (lens, macular, photopigment) so an explicit
   override survives subsequent `Age`, `FieldSize`, or `LensModel`
   edits. Pycone has no notion of this; you must re-set densities by
   hand whenever any other parameter changes.

These are intentional MATLAB-side design improvements, not divergences
from a reference. The parity test deliberately avoids configurations
that exercise items 4-8 because pycone simply has no equivalent code
path; for items 1-3 the harness implements MATLAB's correct behavior.

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

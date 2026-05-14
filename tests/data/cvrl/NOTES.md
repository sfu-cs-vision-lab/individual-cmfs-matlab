# CVRL CIE 170-1:2006 reference tables

Tabulated cone fundamentals downloaded from the Colour & Vision
Research Laboratory (CVRL) database, used as authoritative reference
for testing IndividualCMF's standard-observer outputs.

## Files

| File | Description |
|---|---|
| `cie_2006_2deg_energy_1nm.csv` | CIE 2006 2-deg standard observer, linear energy, 1 nm steps, 390-830 nm |
| `cie_2006_10deg_energy_1nm.csv` | CIE 2006 10-deg standard observer, linear energy, 1 nm steps, 390-830 nm |
| `cie_2006_2deg_quantal_1nm.csv` | CIE 2006 2-deg standard observer, log10 quantal, 1 nm steps |
| `cie_2006_10deg_quantal_1nm.csv` | CIE 2006 10-deg standard observer, log10 quantal, 1 nm steps |

Format (no header): `nm, L, M, S` per row.

Energy-based tables are normalized so that each cone fundamental peaks
at 1.0 (within sampling resolution; the actual sample peak is
~0.99996 because the true peak falls between integer-nm samples).

## Source

Stockman, A. & Sharpe, L.T. (2000). *The spectral sensitivities of
the middle- and long-wavelength-sensitive cones derived from
measurements in observers of known genotype.* Vision Research, 40(13),
1711-1737. As tabulated and distributed by the Colour & Vision
Research Laboratory, University College London.

Direct file URLs (for refresh):

- http://cvrl.ucl.ac.uk/database/data/cones/linss2_10e_1.csv
- http://cvrl.ucl.ac.uk/database/data/cones/linss10e_1.csv
- http://cvrl.ucl.ac.uk/database/data/cones/ss2_10q_1.csv
- http://cvrl.ucl.ac.uk/database/data/cones/ss10q_1.csv

## Note on the toolbox's expected residual

`IndividualCMF` uses the Stockman & Rider (2023) 8th-order Fourier
polynomial templates as its photopigment model (the
`PhotopigmentModel="StockmanRider2023"` default). These polynomials are an
*approximation* of the original Stockman-Sharpe / CIE 170-1:2006
tabulated values, with reported max residuals of ~1-2% in linear units
(Stockman & Rider 2023, Table 4).

`tests/CIEReferenceTest.m` therefore tests the standard-observer
output against these tables at a 2% absolute tolerance - the
documented Stockman-Rider fit residual. Tighter agreement would
require a non-parametric tabular interpolation toolbox; the upside of
the polynomial form is parametric lambda-max shift support for
individual observers.

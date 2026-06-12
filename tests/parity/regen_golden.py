"""regen_golden.py - Raw and normalized pycone pipeline for golden fixtures.

Reads a JSON payload describing a resolved set of pycone inputs from
stdin and writes the four pipeline stages (absorbance, absorptance,
corneal quantal, corneal energy) as CSV to stdout. Used by
tests/parity/regen_golden.m to source the golden fixtures in
tests/data/ from the vendored pycone reference.

This script computes the stages WITHOUT pycone's internal per-stage
peak renormalization, so it can emit the raw (un-normalized) values the
toolbox produces when NormalizeOutput is false. When a normalization
grid is supplied, each stage is divided by its peak over that grid,
matching the toolbox "Sampled" normalization. All template, macular,
lens and self-screening formulas are taken from the vendored pycone
modules (CMFtemplates, CMFcalc), so the fixtures remain an independent
reference for the toolbox.

Input JSON schema (one object):
    {
      "Lshift":       float,
      "Mshift":       float,
      "Sshift":       float,
      "Lod":          float,
      "Mod":          float,
      "Sod":          float,
      "mac_density":  float,
      "lens_density": float,
      "L_template":   "Lmean" | "Lser" | "Lala" | "M-in-L",
      "M_template":   "Standard" | "L-in-M",
      "wl_min":       float,
      "wl_max":       float,
      "wl_step":      float,
      "norm_min":     float (optional),
      "norm_max":     float (optional),
      "norm_step":    float (optional)
    }

When norm_min/norm_max/norm_step are present the absorptance, quantal
and energy stages are normalized to their peak over that grid; the
absorbance stage is never normalized (the template is already unit at
its true lambda_max). Output rows cover wl_min:wl_step:wl_max.

Output CSV columns:
    nm,
    L_absorbance, M_absorbance, S_absorbance,
    L_absorptance, M_absorptance, S_absorptance,
    L_quantal,    M_quantal,    S_quantal,
    L_energy,     M_energy,     S_energy
"""

import json
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
PYCONE_DIR = os.path.join(HERE, "pycone")
sys.path.insert(0, PYCONE_DIR)

import CMFtemplates  # noqa: E402

LSER_M_LMAX_DIFF = 23.67
MAC_TEMPLATE_460 = 0.35
LENS_TEMPLATE_400 = 1.7649

LN10 = np.log(10.0)


def pow10(x):
    # Evaluate 10**x as exp(x*log(10)) to match MATLAB's 10.^x libm
    # convention. The two differ by about one unit in the last place,
    # which is amplified by the catastrophic cancellation in
    # 1 - 10**(-od*A) for the deep spectral tails; matching the
    # convention keeps the stages numerically aligned with the toolbox
    # while leaving every spectral input sourced from pycone.
    return np.exp(np.asarray(x) * LN10)


def template_lin(nm, cfg):
    l_template = cfg["L_template"]
    lshift = cfg["Lshift"]
    mshift = cfg["Mshift"]
    sshift = cfg["Sshift"]

    if l_template == "Lser":
        l_log = CMFtemplates.Lserconelog(nm, lshift)
    elif l_template == "Lala":
        l_log = CMFtemplates.Lserconelog(nm, lshift - 2.7)
    elif l_template == "Lmean":
        if lshift == 0:
            l_log = CMFtemplates.Lmeanconelog(nm)
        else:
            lser = CMFtemplates.Lserconelog(nm, lshift)
            lala = CMFtemplates.Lserconelog(nm, lshift - 2.7)
            l_log = np.log10(0.56 * pow10(lser) + 0.44 * pow10(lala))
    elif l_template == "M-in-L":
        l_log = CMFtemplates.Mconelog(nm, lshift + LSER_M_LMAX_DIFF)
    else:
        raise ValueError("unknown L template: " + repr(l_template))

    m_template = cfg.get("M_template", "Standard")
    if m_template == "Standard":
        m_log = CMFtemplates.Mconelog(nm, mshift)
    elif m_template == "L-in-M":
        m_log = CMFtemplates.Lserconelog(nm, mshift - LSER_M_LMAX_DIFF)
    else:
        raise ValueError("unknown M template: " + repr(m_template))

    s_log = CMFtemplates.Sconelog(nm, sshift)
    return np.column_stack([pow10(l_log), pow10(m_log), pow10(s_log)])


def raw_stages(nm, cfg):
    absorbance = template_lin(nm, cfg)

    od = np.array([cfg["Lod"], cfg["Mod"], cfg["Sod"]])
    absorptance = (1.0 - pow10(-od[None, :] * absorbance)) / (1.0 - pow10(-od))[None, :]

    macs = CMFtemplates.macular(nm)
    lenss = CMFtemplates.lens(nm)
    macscale = cfg["mac_density"] / MAC_TEMPLATE_460
    lensscale = cfg["lens_density"] / LENS_TEMPLATE_400
    transmission = pow10((macs * macscale)[:, None]) * pow10((lenss * lensscale)[:, None])
    quantal = absorptance / transmission

    energy = quantal * nm[:, None]

    return absorbance, absorptance, quantal, energy


def main():
    cfg = json.loads(sys.stdin.read())

    nm_min, nm_max, nm_step = cfg["wl_min"], cfg["wl_max"], cfg["wl_step"]
    n_points = int(round((nm_max - nm_min) / nm_step)) + 1
    nm = np.linspace(nm_min, nm_max, n_points)

    absorbance, absorptance, quantal, energy = raw_stages(nm, cfg)

    if "norm_min" in cfg:
        n_norm = int(round((cfg["norm_max"] - cfg["norm_min"]) / cfg["norm_step"])) + 1
        nm_norm = np.linspace(cfg["norm_min"], cfg["norm_max"], n_norm)
        _, norm_absorptance, norm_quantal, norm_energy = raw_stages(nm_norm, cfg)
        absorptance = absorptance / np.max(norm_absorptance, axis=0)[None, :]
        quantal = quantal / np.max(norm_quantal, axis=0)[None, :]
        energy = energy / np.max(norm_energy, axis=0)[None, :]

    out = np.column_stack([nm, absorbance, absorptance, quantal, energy])
    np.savetxt(
        sys.stdout, out, delimiter=",",
        header=("nm,"
                "L_absorbance,M_absorbance,S_absorbance,"
                "L_absorptance,M_absorptance,S_absorptance,"
                "L_quantal,M_quantal,S_quantal,"
                "L_energy,M_energy,S_energy"),
        comments="", fmt="%.17g",
    )


if __name__ == "__main__":
    main()

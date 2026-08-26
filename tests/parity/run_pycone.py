"""run_pycone.py - One-shot pycone evaluator for parity comparison.

Reads JSON describing a resolved set of pycone inputs from stdin, runs
the pycone pipeline, and writes the resulting LMS energy + quantal
matrix as CSV to stdout. Used by tests/parity/compare.m to drive
pycone with the exact numerical values resolved by MATLAB's
IndividualCMF, so the comparison tests the mathematical pipeline
without any input-derivation discrepancies.

Input JSON schema (one object):
    {
      "Lshift":       float,
      "Mshift":       float,
      "Sshift":       float,
      "Lod":          float,
      "Mod":          float,
      "Sod":          float,
      "mac_density":  float,   # at 460 nm
      "lens_density": float,   # at 400 nm
      "L_template":   "Lmean" | "Lser" | "Lala",
      "wl_min":       float,   # output start wavelength (nm)
      "wl_max":       float,   # output stop wavelength (nm)
      "wl_step":      float,   # 1.0 typically
      "normalize":    bool,
      "log_output":   bool
    }

Output CSV columns (all four pipeline stages plus RGB CMFs):
    nm,
    L_absorbance, M_absorbance, S_absorbance,        # stage 1 (linear)
    L_absorptance, M_absorptance, S_absorptance,     # stage 2 (retinal)
    L_quantal,    M_quantal,    S_quantal,           # stage 3 (corneal)
    L_energy,     M_energy,     S_energy,            # stage 4 (corneal)
    R_cmf, G_cmf, B_cmf                              # RGB color matching funcs

Each LMS stage is independently normalized to its own peak when
normalize=true. RGB CMFs are computed by inverting the LMS values at
the three primary wavelengths (Rnm, Gnm, Bnm) and applying the
transformation. log_output=true returns log10 of every column.
"""

import json
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
PYCONE_DIR = os.path.join(HERE, "pycone")
sys.path.insert(0, PYCONE_DIR)

import CMFcalc          # noqa: E402
import CMFtemplates     # noqa: E402

NM_FULL = np.arange(360.0, 850.0 + 1.0, 1.0)


LSER_M_LMAX_DIFF = 23.67  # L-Serine - M lambda_max difference, S&R 2023 / 2024


def build_template_array(nm, l_template, lshift, mshift, sshift, m_template="Standard"):
    # L cone variants
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
            l_log = np.log10(0.56 * 10**lser + 0.44 * 10**lala)
    elif l_template == "M-in-L":
        # MATLAB hybrid: M template positioned at the L-cone position.
        # Equivalent to Mconelog with shift = user_shift + LSER_M_LMAX_DIFF.
        l_log = CMFtemplates.Mconelog(nm, lshift + LSER_M_LMAX_DIFF)
    else:
        raise ValueError("unknown L template: " + repr(l_template))

    # M cone variants
    if m_template == "Standard":
        m_log = CMFtemplates.Mconelog(nm, mshift)
    elif m_template == "L-in-M":
        # MATLAB hybrid: L-Serine template positioned at the M-cone position.
        # Equivalent to Lserconelog with shift = user_shift - LSER_M_LMAX_DIFF.
        m_log = CMFtemplates.Lserconelog(nm, mshift - LSER_M_LMAX_DIFF)
    else:
        raise ValueError("unknown M template: " + repr(m_template))

    s_log = CMFtemplates.Sconelog(nm, sshift)
    log_abs = np.column_stack([nm, l_log, m_log, s_log])
    lin_abs = np.column_stack([nm, 10**l_log, 10**m_log, 10**s_log])
    return log_abs, lin_abs


# Direct-shift magnitude L/M template switching.
#
# Faithful transcription of pycone 1.0.3 (LMStemplateCMFs.py): the decision
# peaks and codon scales (lines 62 to 135), chooseLMtemplates() for the
# useCodons == False branch (lines 659 to 680), and the template routing
# (lines 729 to 739). Copied close to line-for-line, not tidied, so it can be
# diffed directly against the source: when a direct lambda-max shift is large
# enough, pycone swaps the L/M template, and the values here are what decide
# that. Reached only when the parity config sets "auto_lm_switch"; the standard
# configs never set it and stay on build_template_array above.

# Decision peaks (LMStemplateCMFs.py 62, 65, 67)
Lserlmax_template = 554.86
Mlmax_template = 531.19
Lser_Mlmax_diff = Lserlmax_template - Mlmax_template  # 23.67

# Codon base shifts and M->L scale (LMStemplateCMFs.py 91 to 108)
M_L_116baseshift = 0
M_L_180baseshift = 3
M_L_230baseshift = 3
M_L_233baseshift = 0
M_L_277baseshift = 7
M_L_285baseshift = 14
M_L_309baseshift = 0
M_L_allbaseshifts = (M_L_116baseshift + M_L_180baseshift + M_L_230baseshift
                     + M_L_233baseshift + M_L_277baseshift + M_L_285baseshift
                     + M_L_309baseshift)
M_L_scale = Lser_Mlmax_diff / M_L_allbaseshifts
M_L_277shift = M_L_277baseshift * M_L_scale
M_L_285shift = M_L_285baseshift * M_L_scale

# Codon base shifts and L->M scale (LMStemplateCMFs.py 114 to 135)
L_M_116baseshift = -3
L_M_180baseshift = -4
L_M_230baseshift = -3
L_M_233baseshift = 0
L_M_277baseshift = -7
L_M_285baseshift = -14
L_M_309baseshift = 0
L_M_allbaseshifts = (L_M_116baseshift + L_M_180baseshift + L_M_230baseshift
                     + L_M_233baseshift + L_M_277baseshift + L_M_285baseshift
                     + L_M_309baseshift)
L_M_scale = -Lser_Mlmax_diff / L_M_allbaseshifts
L_M_277shift = L_M_277baseshift * L_M_scale
L_M_285shift = L_M_285baseshift * L_M_scale


def choose_lm_templates(Lshift, Mshift):
    # LMStemplateCMFs.py chooseLMtemplates(), useCodons == False branch (659 to 680).
    MisL = False
    LisM = False
    MisLshift = 0.0
    LisMshift = 0.0
    if Mshift >= (M_L_277shift + M_L_285shift):  # Exon 5 = L
        MisL = True
        MisLshift = Mshift - (Lserlmax_template - Mlmax_template)
    if Lshift <= (L_M_277shift + L_M_285shift):  # Exon 5 = M
        LisM = True
        LisMshift = Lshift + (Lserlmax_template - Mlmax_template)
    return MisL, LisM, MisLshift, LisMshift


def build_template_array_lmswitch(nm, lshift, mshift, sshift):
    # Direct-shift path with magnitude switching. Mirrors pycone's routing
    # (LMStemplateCMFs.py 729 to 739) into LLS / MMS / MLS / LMSconelog. The
    # L base here is Lser, matching pycone's direct-shift LMSconelog (the
    # Lmean path, LMSconelognormal, is the separate standard-observer path).
    MisL, LisM, MisLshift, LisMshift = choose_lm_templates(lshift, mshift)
    if LisM and not MisL:  # 2 M-cone templates -> MMSconelog
        l_log = CMFtemplates.Mconelog(nm, LisMshift)
        m_log = CMFtemplates.Mconelog(nm, mshift)
    elif MisL and not LisM:  # 2 L-cone templates -> LLSconelog
        l_log = CMFtemplates.Lserconelog(nm, lshift)
        m_log = CMFtemplates.Lserconelog(nm, MisLshift)
    elif MisL and LisM:  # swapped -> MLSconelog
        l_log = CMFtemplates.Mconelog(nm, LisMshift)
        m_log = CMFtemplates.Lserconelog(nm, MisLshift)
    else:  # normal direct-shift -> LMSconelog (L is Lser)
        l_log = CMFtemplates.Lserconelog(nm, lshift)
        m_log = CMFtemplates.Mconelog(nm, mshift)
    s_log = CMFtemplates.Sconelog(nm, sshift)
    log_abs = np.column_stack([nm, l_log, m_log, s_log])
    lin_abs = np.column_stack([nm, 10**l_log, 10**m_log, 10**s_log])
    return log_abs, lin_abs


def build_template_array_for_cfg(nm, cfg):
    # Dispatch to the magnitude-switching builder when the config opts in,
    # otherwise the explicit-template builder. Default is inert: configs that
    # do not set "auto_lm_switch" take the exact path they always did.
    if cfg.get("auto_lm_switch", False):
        return build_template_array_lmswitch(
            nm, cfg["Lshift"], cfg["Mshift"], cfg["Sshift"])
    return build_template_array(
        nm, cfg["L_template"], cfg["Lshift"], cfg["Mshift"], cfg["Sshift"],
        m_template=cfg.get("M_template", "Standard"))


def main():
    cfg = json.loads(sys.stdin.read())

    # Compute templates directly on the requested grid (supports
    # arbitrary step sizes including sub-nm and wavelengths outside
    # the conventional 390-780 range). Use linspace, not arange, so
    # the endpoints land exactly - np.arange accumulates float error
    # of ~1e-11 per 1000 steps for non-binary steps like 0.1, which
    # becomes visible after np.log10 in the template formulas.
    nm_min, nm_max, nm_step = cfg["wl_min"], cfg["wl_max"], cfg["wl_step"]
    n_points = int(round((nm_max - nm_min) / nm_step)) + 1
    nm = np.linspace(nm_min, nm_max, n_points)

    _, lin_abs = build_template_array_for_cfg(nm, cfg)

    Lod, Mod, Sod = cfg["Lod"], cfg["Mod"], cfg["Sod"]
    mac_spectrum = CMFtemplates.macular(nm)
    lens_spectrum = CMFtemplates.lens(nm)

    # Stage 1: photopigment absorbance (linear)
    absorbance_lin = lin_abs

    # Stage 2: retinal absorptance (post-self-screening)
    retinal_lin = CMFcalc.absorptancefromabsorbance(absorbance_lin, Lod, Mod, Sod, "lin")

    # Stage 3: corneal quantal sensitivity (post-pre-receptoral filtering)
    corneal_quantal_lin = CMFcalc.corneafromlinabsorptance(
        retinal_lin, mac_spectrum, lens_spectrum,
        cfg["mac_density"], cfg["lens_density"], "lin",
    )

    # Stage 4: corneal energy sensitivity
    corneal_energy_lin = CMFcalc.energyfromquantalin(corneal_quantal_lin, "lin")

    stages = {
        "absorbance":  absorbance_lin,
        "absorptance": retinal_lin,
        "quantal":     corneal_quantal_lin,
        "energy":      corneal_energy_lin,
    }

    log_output = cfg.get("log_output", False)
    normalize  = cfg.get("normalize", True)

    # MATLAB convention: absorbance is the raw template output and is
    # NEVER normalized by the toolbox - the template is already
    # normalized to 1.0 at the true (sub-grid) lambda_max. Sample-grid
    # renormalization would slightly distort it.
    #
    # The other three stages (absorptance, quantal, energy) are
    # normalized in linear space when NormalizeOutput=true, then log10
    # is applied if LogOutput=true.
    NORMALIZED_STAGES = ("absorptance", "quantal", "energy")
    if normalize:
        for name in NORMALIZED_STAGES:
            s = stages[name]
            for c in range(1, s.shape[1]):
                peak = np.max(s[:, c])
                if peak > 0:
                    s[:, c] /= peak

    # RGB CMFs: linear transform of normalized LMS energy via the LMS
    # values at the three primary wavelengths.
    rgb_cmfs = compute_rgb_cmfs(cfg, stages["energy"][:, 1:], nm)

    if log_output:
        with np.errstate(divide="ignore"):
            stages = {
                name: np.column_stack([s[:, 0], np.log10(s[:, 1:])])
                for name, s in stages.items()
            }
        # RGB CMFs intentionally stay linear: they include negative
        # values (Stiles & Burch reality with real primaries) so log10
        # is undefined. MATLAB's RGB() method also never applies the
        # LogOutput transform.

    nm_col = stages["absorbance"][:, 0]
    out = np.column_stack([
        nm_col,
        stages["absorbance"][:, 1:],   # L,M,S absorbance
        stages["absorptance"][:, 1:],  # L,M,S absorptance
        stages["quantal"][:, 1:],      # L,M,S quantal
        stages["energy"][:, 1:],       # L,M,S energy
        rgb_cmfs,                      # R,G,B
    ])
    np.savetxt(
        sys.stdout, out, delimiter=",",
        header=("nm,"
                "L_absorbance,M_absorbance,S_absorbance,"
                "L_absorptance,M_absorptance,S_absorptance,"
                "L_quantal,M_quantal,S_quantal,"
                "L_energy,M_energy,S_energy,"
                "R_cmf,G_cmf,B_cmf"),
        comments="", fmt="%.16g",
    )


def compute_rgb_cmfs(cfg, lms_energy, nm):
    """Compute RGB color matching functions from normalized LMS energy.

    Replicates pycone's calcRGBCMFs: build the 3x3 LMS-at-primaries
    matrix, invert, and apply to the LMS energy spectrum.

    Parameters
    ----------
    cfg : dict
        Must contain Rnm, Gnm, Bnm primary wavelengths.
    lms_energy : (N, 3) ndarray
        Already-normalized L, M, S corneal energy at the spectrum.
    nm : (N,) ndarray
        Spectrum wavelengths.
    """
    Rnm, Gnm, Bnm = cfg["Rnm"], cfg["Gnm"], cfg["Bnm"]

    # Compute L/M/S at the three primary wavelengths separately,
    # using the same template/density/filter parameters as the spectrum.
    primary_nm = np.array([Rnm, Gnm, Bnm])
    _, primary_lin_abs = build_template_array_for_cfg(primary_nm, cfg)
    primary_retinal = CMFcalc.absorptancefromabsorbance(
        primary_lin_abs, cfg["Lod"], cfg["Mod"], cfg["Sod"], "lin"
    )
    primary_mac_spectrum = CMFtemplates.macular(primary_nm)
    primary_lens_spectrum = CMFtemplates.lens(primary_nm)
    mac_template_460 = 0.35
    lens_template_400 = 1.7649
    macscale = cfg["mac_density"] / mac_template_460
    lensscale = cfg["lens_density"] / lens_template_400

    # Apply lens/mac transmission to retinal absorptance to get raw
    # corneal quantal at the primaries (without the renormalization
    # that pycone's corneafromlinabsorptance applies; we want the
    # unnormalized values to combine consistently with the spectrum
    # arm).
    raw_corneal_q_primaries = primary_retinal[:, 1:] / (
        10 ** (primary_mac_spectrum * macscale)[:, None]
        * 10 ** (primary_lens_spectrum * lensscale)[:, None]
    )

    # Convert to corneal energy at primaries (raw_quantal * wl)
    raw_corneal_e_primaries = raw_corneal_q_primaries * primary_nm[:, None]

    # Apply the SAME normalization the spectrum used: divide each cone
    # by the spectrum's L/M/S energy peaks. Since lms_energy is already
    # normalized to peak=1 per cone, the equivalent operation is to
    # normalize the primaries by the raw spectrum-arm corneal energy
    # peaks.
    raw_corneal_q_spectrum = stages_raw_quantal(cfg, nm)
    raw_corneal_e_spectrum = raw_corneal_q_spectrum * nm[:, None]
    spectrum_peaks = np.max(raw_corneal_e_spectrum, axis=0)

    primary_lms = raw_corneal_e_primaries / spectrum_peaks[None, :]

    # 3x3: rows = primaries, cols = LMS
    M = primary_lms  # already (3, 3)
    LMSRGB = np.linalg.inv(M.T)  # transpose then invert (matches pycone's logic)

    rgb = (LMSRGB @ lms_energy.T).T
    return rgb


def stages_raw_quantal(cfg, nm):
    """Recompute the raw (un-normalized) corneal quantal LMS for nm.

    Used by compute_rgb_cmfs to normalize the primaries' values by the
    same per-cone peaks used to normalize the spectrum.
    """
    _, lin_abs = build_template_array_for_cfg(nm, cfg)
    retinal = CMFcalc.absorptancefromabsorbance(
        lin_abs, cfg["Lod"], cfg["Mod"], cfg["Sod"], "lin"
    )
    mac_spectrum = CMFtemplates.macular(nm)
    lens_spectrum = CMFtemplates.lens(nm)
    macscale = cfg["mac_density"] / 0.35
    lensscale = cfg["lens_density"] / 1.7649
    raw_corneal_q = retinal[:, 1:] / (
        10 ** (mac_spectrum * macscale)[:, None]
        * 10 ** (lens_spectrum * lensscale)[:, None]
    )
    return raw_corneal_q


if __name__ == "__main__":
    main()

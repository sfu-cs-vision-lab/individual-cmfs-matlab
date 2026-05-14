classdef IndividualCMF < handle & matlab.mixin.Copyable & matlab.mixin.CustomDisplay
    % INDIVIDUALCMF  Compute cone fundamentals for standard and individual observers
    %
    %   IndividualCMF builds an L/M/S spectral sensitivity model from
    %   biophysical inputs (opsin genotype, age, retinal field size, lens
    %   and macular optical densities, per-cone photopigment optical
    %   densities, and lambda-max shifts) by traversing a four-stage
    %   pipeline: (1) photopigment absorbance from a template positioned
    %   at the cone's lambda-max, (2) relative retinal absorptance via
    %   Beer-Lambert self-screening, (3) pre-receptoral filtering by lens and macular
    %   pigment, and (4) quantal-to-energy conversion. Each stage's model
    %   is swappable: photopigment template (Stockman & Rider 2023 or
    %   Govardovskii 2000), lens model (Stockman & Rider 2023, Pokorny
    %   1987, or van de Kraats & van Norren 2007), and macular template.
    %   Defaults reproduce the CIE 170 physiological standard observers;
    %   any input can be overridden individually to model a specific
    %   observer or to study the effect of one biophysical parameter.
    %
    %   SYNTAX:
    %       obs = IndividualCMF()
    %       obs = IndividualCMF(StandardObserver=2)
    %       obs = IndividualCMF(StandardObserver=10)
    %       obs = IndividualCMF(Name=Value, ...)
    %
    %   OPTIONAL INPUTS (Name-Value arguments):
    %       StandardObserver             - Force CIE 2006 standard observer (scalar in {2,10}) Default: 10
    %       Age                          - Observer age in years (scalar) Default: 32
    %       FieldSize                    - Field size in degrees (scalar) Default: 10
    %       Genotype                     - Opsin genotype (struct | dictionary | string | Genotype) Default: []
    %       LensDensity                  - Manual lens density at 400 nm (scalar)
    %       MacularDensity               - Manual macular density at 460 nm (scalar)
    %       Lod                          - Manual L-cone optical density (scalar)
    %       Mod                          - Manual M-cone optical density (scalar)
    %       Sod                          - Manual S-cone optical density (scalar)
    %       L_LambdaMaxShift             - L-cone peak shift, -40 to +10 nm (scalar) Default: 0
    %       M_LambdaMaxShift             - M-cone peak shift, -20 to +30 nm (scalar) Default: 0
    %       S_LambdaMaxShift             - S-cone peak shift in nm (scalar) Default: 0
    %       L_OpsinTemplate              - "Mean", "Serine", "Alanine", or "MinL" (string) Default: "Mean"
    %       M_OpsinTemplate              - "Mean", "Standard", or "LinM" (string) Default: "Mean"
    %       PhotopigmentModel            - "StockmanRider2023", "Govardovskii2000", or "Govardovskii2000A2" (string) Default: "StockmanRider2023"
    %       LensModel                    - "StockmanRider2023", "Pokorny1987", or "VanDeKraats2007" (string) Default: "StockmanRider2023"
    %       MacularModel                 - "StockmanRider2023" (string) Default: "StockmanRider2023"
    %       LensDensityAlgorithm         - "Auto" or "Custom" (string) Default: "Auto"
    %       MacularDensityAlgorithm      - "CIE170", "MorelandAlexander", or "Custom" (string)
    %       PhotopigmentDensityAlgorithm - "CIE170", "PokornySmith", or "Custom" (string)
    %       OutputFormat                 - "energy", "quantal", "absorptance", or "absorbance" (string) Default: "energy"
    %       NormalizeOutput              - Scale each cone peak to 1.0 (logical) Default: true
    %       LogOutput                    - Return log10 of output (logical) Default: false
    %       NormalizationMethod          - "Continuous", "Sampled", or config struct (string|struct) Default: "Continuous"
    %       Primaries                    - RGB primary wavelengths in nm (1x3 double) Default: [645.15 526.32 444.44]
    %
    %   OUTPUTS:
    %       obs                          - Configured observer (IndividualCMF handle)
    %
    %   IndividualCMF Properties:
    %       Age                          - Observer age in years.
    %       FieldSize                    - Visual field diameter in degrees.
    %       Type                         - "CIE 170-1:2006" or "Individualized" (read-only).
    %       StandardObserver             - 2, 10, or 0 (numeric companion to Type; settable).
    %       LensDensity                  - Peak lens optical density at 400 nm.
    %       MacularDensity               - Peak macular pigment density at 460 nm.
    %       Lod                          - L-cone photopigment optical density. Zero = absent (protanopia).
    %       Mod                          - M-cone photopigment optical density. Zero = absent (deuteranopia).
    %       Sod                          - S-cone photopigment optical density. Zero = absent (tritanopia).
    %       PhotopigmentModel            - Active photopigment template name.
    %       LensModel                    - Active lens density model name.
    %       MacularModel                 - Active macular pigment template name.
    %       LensDensityAlgorithm         - "Auto" or "Custom" mode for lens density.
    %       MacularDensityAlgorithm      - "CIE170", "MorelandAlexander", or "Custom".
    %       PhotopigmentDensityAlgorithm - "CIE170", "PokornySmith", or "Custom".
    %       L_OpsinTemplate              - "Mean", "Serine", "Alanine", or "MinL".
    %       M_OpsinTemplate              - "Mean", "Standard", or "LinM".
    %       L_LambdaMaxShift             - L-cone peak shift in nm.
    %       M_LambdaMaxShift             - M-cone peak shift in nm.
    %       S_LambdaMaxShift             - S-cone peak shift in nm.
    %       OutputFormat                 - "energy", "quantal", "absorptance", or "absorbance".
    %       NormalizeOutput              - Logical; if true, scales each cone peak to 1.
    %       LogOutput                    - Logical; if true, returns log10 values.
    %       NormalizationMethod          - "Continuous" or "Sampled" (or a config struct).
    %       NormalizationConfig          - Active normalization configuration (read-only).
    %       Primaries                    - 1x3 RGB primary wavelengths in nm.
    %
    %   IndividualCMF Methods:
    %       setGenotype            - Set one cone/position/residue and update the shift.
    %       across                 - (Static) Build an array of observers across a parameter axis.
    %       applyGenotype          - Configure observer from a "L-geno/M-geno" string.
    %       getParameters          - Snapshot current parameters as ObserverParameters.
    %       setParameters          - Restore parameters from an ObserverParameters object.
    %       evaluate               - Evaluate the model with Data and Format options.
    %       L, M, S                - Per-cone sensitivity at the given wavelengths.
    %       LMS                    - L, M, S sensitivities as an Nx3 matrix.
    %       XYZ                    - CIE XYZ CMFs (2-deg matrix below 4 deg, else 10-deg).
    %       RGB                    - RGB CMFs for the configured Primaries.
    %       Luminance              - Photopic V*(lambda) (CIE 170-2:2015 y-bar row).
    %       MacLeodBoynton         - MacLeod-Boynton chromaticity (l_MB, s_MB).
    %       lmChromaticity         - LMS-sum chromaticity (l, m).
    %       xyChromaticity         - CIE xy chromaticity (from XYZ).
    %       getPeak                - Peak sensitivity for a given cone.
    %       getLensDensitySpectrum - Lens optical density at the given wavelengths.
    %       getMacularDensitySpectrum - Macular pigment optical density at the given wavelengths.
    %       plot, plotLMS, plotXYZ, plotRGBCMFs, plotChromaticity,
    %       plotAbsorbance, plotAbsorptance, plotQuantalEnergy, plotLens,
    %       plotMacular, plotDiagnostics, compareTo - Plotting and
    %                                    comparison wrappers over CMFPlotter.
    %
    %   Behavior:
    %     Setting LensDensity, MacularDensity, or any of Lod/Mod/Sod auto-
    %     engages the corresponding *DensityAlgorithm to "Custom" and pins
    %     the value across subsequent Age/FieldSize/LensModel changes.
    %     Setting Lod/Mod/Sod to zero models a gene-deletion dichromat
    %     (the corresponding LMS column is zero, or -10 in LogOutput mode);
    %     XYZ and RGB error for dichromats. obs.StandardObserver reads as
    %     2, 10, or 0; assigning 2 or 10 snaps biophysics back to the
    %     tabulated CIE values.
    %
    %   EXAMPLE:
    %       obs = IndividualCMF();
    %       wl  = (380:1:780)';
    %       LMS = obs.LMS(wl);
    %
    %       % Age-dependent observer with the Pokorny 1987 lens model.
    %       obs = IndividualCMF(Age=70, FieldSize=4, LensModel="Pokorny1987");
    %
    %       % Genotype-driven L-cone variant.
    %       obs = IndividualCMF(Genotype=struct(L_180="Ala"));
    %
    %       % Snap back to a CIE standard at runtime after editing.
    %       obs = IndividualCMF(StandardObserver=2);
    %       disp(obs.StandardObserver);       % 2
    %       obs.Age = 70;                     % drifts out of standard
    %       disp(obs.StandardObserver);       % 0
    %       obs.StandardObserver = 2;         % snap back to 2-deg standard
    %       disp(obs.StandardObserver);       % 2
    %
    %       % Round-trip parameter snapshot.
    %       params = obs.getParameters();
    %       obs2 = IndividualCMF();
    %       obs2.setParameters(params);
    %
    %   See also Genotype, ObserverParameters, PhotopigmentTemplate,
    %       LensTemplate, MacularTemplate, CMFPlotter.
    %
    %   Primary reference: Stockman, A. & Rider, A.T. (2023). Formulae for
    %   generating standard and individual human cone spectral sensitivities.
    %   Color Research and Application, 48(6), 818-840. doi:10.1002/col.22879
    %   Additional references throughout this and the template class
    %   docstrings, and in CITATION.cff.
    %
    %   Copyright 2025-2026 Alexander Forsythe and Brian Funt. Simon Fraser University.

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada
    %
    % This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    % Licensed under AGPL-3.0-or-later. See LICENSE file for details.
    % Repository: https://github.com/sfu-cs-vision-lab/Individual-CMFs
    %
    % To cite this toolbox and its underlying scientific basis, see CITATION.cff
    % in the repository root.

    properties (Dependent)
        % Observer age in years; scales lens density.
        %   Modulates the crystalline lens optical density spectrum
        %   according to the active LensModel (Stockman & Rider 2023,
        %   Pokorny, Smith & Lutze 1987, or van de Kraats & van Norren
        %   2007). Setting Age recomputes LensDensity unless
        %   LensDensityAlgorithm is "Custom".
        Age

        % Visual field diameter (degrees); determines macular/photopigment densities.
        %   At 2 deg or 10 deg the densities use the CIE 170-1:2006
        %   tabulated values; at any other size the macular and
        %   photopigment density algorithms auto-switch to their
        %   formula variants ("MorelandAlexander", "PokornySmith").
        FieldSize

        % Compliance status ("CIE 170-1:2006" or "Individualized") (read-only).
        %   Returns "CIE 170-1:2006" only when all biophysical parameters
        %   and algorithms exactly match a CIE Standard Observer
        %   definition; otherwise returns "Individualized".
        Type

        % CIE 2006 standard observer reflected by the current configuration.
        %   Numeric companion to Type. Get-side returns:
        %     10 - the configuration matches the CIE 2006 10-deg standard
        %      2 - the configuration matches the CIE 2006  2-deg standard
        %      0 - any other configuration ("Individualized")
        %   Set-side accepts 2 or 10 and snaps every relevant biophysical
        %   parameter (Age, FieldSize, densities, opsin templates, shifts,
        %   *DensityAlgorithm modes) to the corresponding CIE tabulated
        %   values. Use this to recover a standard configuration after
        %   modifying a parameter:
        %       obs = IndividualCMF(StandardObserver=2);
        %       obs.Age = 50;            % obs.StandardObserver -> 0
        %       obs.StandardObserver = 2;% snap back to 2-deg standard
        %   Setting StandardObserver = 0 is rejected; 0 is a state you
        %   drift into by editing parameters, not one you set directly.
        %   Output-shape options (OutputFormat, NormalizeOutput, LogOutput,
        %   NormalizationMethod, Primaries, WavelengthWarning) are
        %   preserved across the snap.
        StandardObserver

        % L-cone photopigment axial optical density.
        %   Peak axial optical density of the L-cone photopigment in the
        %   outer segment. Direct assignment engages
        %   PhotopigmentDensityAlgorithm="Custom".
        Lod

        % M-cone photopigment axial optical density.
        %   Peak axial optical density of the M-cone photopigment in the
        %   outer segment. Direct assignment engages
        %   PhotopigmentDensityAlgorithm="Custom".
        Mod

        % S-cone photopigment axial optical density.
        %   Peak axial optical density of the S-cone photopigment in the
        %   outer segment. Direct assignment engages
        %   PhotopigmentDensityAlgorithm="Custom".
        Sod

        % Peak macular pigment density at 460 nm.
        %   Scales the standard macular absorbance spectrum (lutein and
        %   zeaxanthin). Direct assignment engages
        %   MacularDensityAlgorithm="Custom".
        MacularDensity

        % Photopigment template model ("StockmanRider2023",
        % "Govardovskii2000", or "Govardovskii2000A2").
        %   "StockmanRider2023"   - 8th-order Fourier polynomial templates
        %                           from Stockman & Rider (2023), Table 1
        %                           (CIE 2006 standard).
        %   "Govardovskii2000"    - Continuous A1 (11-cis retinal)
        %                           nomogram from Govardovskii et al.
        %                           (2000). Standard human chromophore.
        %   "Govardovskii2000A2"  - Continuous A2 (3,4-dehydroretinal)
        %                           nomogram from Govardovskii et al.
        %                           (2000), Eqs. 6 and 8. For
        %                           comparative-vision research
        %                           (freshwater fish, larval amphibians).
        PhotopigmentModel

        % Lens template model ("StockmanRider2023" or "Pokorny1987").
        %   Determines the spectral shape of lens absorption.
        %   "StockmanRider2023" - Age-invariant 9-term Fourier polynomial
        %                         template (Stockman & Rider 2023, Table 2).
        %                         Density at 400 nm is fixed at 1.7649 unless
        %                         set externally.
        %   "Pokorny1987"       - Age-dependent two-component template
        %                         (Pokorny, Smith & Lutze 1987, Table I)
        %                         with bilinear density growth above age 60.
        %   "VanDeKraats2007"   - Age-dependent five-component total-media
        %                         template (van de Kraats & van Norren
        %                         2007, Eq. 8) with quadratic-in-age
        %                         density coefficients.
        LensModel

        % Macular template family ("StockmanRider2023").
        %   Selects the spectral SHAPE of the macular pigment template.
        %   Currently only the Stockman & Rider 2023 / CIE 170-1:2006
        %   shape is published; the strategy slot exists so additional
        %   templates can be added without changing IndividualCMF's
        %   public surface. The peak macular density (in OD at 460 nm)
        %   is set separately via MacularDensity / MacularDensityAlgorithm.
        MacularModel

        % L-cone peak shift in nm (range -40 to +10).
        %   Spectral shift of the L-cone photopigment absorbance peak
        %   (lambda_max), applied in log-wavelength space.
        L_LambdaMaxShift

        % M-cone peak shift in nm (range -20 to +30).
        %   Spectral shift of the M-cone photopigment absorbance peak
        %   (lambda_max), applied in log-wavelength space.
        M_LambdaMaxShift

        % S-cone peak shift in nm.
        %   Spectral shift of the S-cone photopigment absorbance peak
        %   (lambda_max), applied in log-wavelength space.
        S_LambdaMaxShift

        % L-cone template shape ("Mean", "Serine", "Alanine", or "MinL").
        %   Selects the L-cone polymorphism variant or hybrid opsin curve.
        %   "Mean" is the population-weighted average of Serine (56%) and
        %   Alanine (44%) variants.
        L_OpsinTemplate

        % M-cone template shape ("Mean", "Standard", or "LinM").
        %   Selects the M-cone polymorphism variant or hybrid opsin curve.
        M_OpsinTemplate

        % Macular density strategy ("CIE170", "MorelandAlexander", or "Custom").
        %   Strategy for computing macular pigment optical density from
        %   field size.
        %   "CIE170"     - Use the CIE 170-1:2006 tabulated values
        %                         (only valid at 2 deg or 10 deg).
        %   "MorelandAlexander" - Continuous formula valid for any field
        %                         size: D_mac = 0.485*exp(-fieldSize/6.132)
        %                         (Moreland & Alexander 1997; CIEPO06).
        %   "Custom"            - Hold MacularDensity fixed; auto-engaged
        %                         when MacularDensity is assigned directly.
        MacularDensityAlgorithm

        % Photopigment density strategy ("CIE170", "PokornySmith", or "Custom").
        %   Strategy for computing per-cone photopigment optical density
        %   (Lod / Mod / Sod) from field size.
        %   "CIE170" - Use the CIE 170-1:2006 tabulated values
        %                     (only valid at 2 deg or 10 deg).
        %   "PokornySmith"  - Continuous formula valid for any field size
        %                     (Pokorny & Smith 1976).
        %   "Custom"        - Hold Lod / Mod / Sod fixed; auto-engaged
        %                     when any of Lod / Mod / Sod is assigned
        %                     directly.
        PhotopigmentDensityAlgorithm

        % Peak lens optical density at 400 nm.
        %   Linearly scales the standard lens absorbance spectrum to
        %   simulate individual or age-related variation. Direct assignment
        %   automatically engages LensDensityAlgorithm="Custom" so
        %   subsequent Age, FieldSize, or LensModel changes do not clobber
        %   the user-provided value. Must be non-negative and finite;
        %   negative values are non-physical (transmission > 1) and Inf
        %   would propagate through the normalization cache.
        LensDensity

        % Lens density strategy ("Auto" or "Custom").
        %   "Auto"   - LensDensity is recomputed from the active LensModel
        %              and Age whenever those change. This is the default.
        %   "Custom" - LensDensity is held fixed at the most recently
        %              assigned value; Age, FieldSize, and LensModel
        %              changes do not recalculate it.
        %   Auto-engages "Custom" when LensDensity is assigned directly
        %   (constructor LensDensity=, set.LensDensity, or setParameters).
        %   Re-assigning to "Auto" recalculates LensDensity from Age and
        %   emits a warning.
        LensDensityAlgorithm

        % Normalization method ("Continuous", "Sampled", or a config struct).
        %   Controls how the peak of the sensitivity curve is defined.
        %   "Continuous" (default) - Peak computed via
        %                            computePeakForFormat: an analytical
        %                            formula for Govardovskii absorptance,
        %                            fminbnd otherwise. Results are
        %                            independent of wavelength sampling.
        %   "Sampled"              - Maximum of a discretely sampled
        %                            spectrum. Shorthand for the default
        %                            config struct (380:1:780 nm).
        %   struct(...)            - Explicit Sampled configuration. Fields:
        %                              Method: "Sampled" (required)
        %                              Start:  380 (nm, default)
        %                              Stop:   780 (nm, default)
        %                              Step:   1 (nm, default)
        %                            Example matching the Pycone 5 nm grid:
        %                              obs.NormalizationMethod = struct( ...
        %                                  Method="Sampled", Start=390, ...
        %                                  Stop=830, Step=5);
        %   Sampled results depend on the grid; for reproducibility or
        %   compatibility with external tools (e.g., Pycone) specify the
        %   resolution explicitly. Evaluating at wavelengths finer than the
        %   sampled normalization grid can produce values slightly above 1.0
        %   (the true peak falls between grid points). For guaranteed
        %   unit-bounded output, use "Continuous" or evaluate only on the
        %   wavelengths used for normalization.
        NormalizationMethod

        % Active normalization configuration (read-only).
        %   Returns the full configuration struct used by the current
        %   NormalizationMethod, including resolution parameters for
        %   Sampled mode.
        NormalizationConfig
    end

    properties (SetObservable, AbortSet)
        % Pipeline stage ("energy", "quantal", "absorptance", or "absorbance").
        %   Selects the visual-pathway stage at which sensitivities are
        %   reported. Default: "energy".
        %   "absorptance" returns relative retinal absorptance
        %   (1-10^(-OD*A)) / (1-10^(-OD)) for both Stockman-Rider and
        %   Govardovskii templates (peak near 1). The raw physical
        %   fraction 1-10^(-OD*A) is available via
        %   pipeline.PhotopigmentStage.absorptanceFromAbsorbance with
        %   Normalize=false.
        OutputFormat (1,1) enums.OutputFormat = enums.OutputFormat.energy

        % If true (default), scales output so each cone peaks at 1.0.
        NormalizeOutput (1,1) logical = true

        % If true, returns log10 of the requested output. Default false.
        LogOutput (1,1) logical = false
    end

    properties
        % RGB primary wavelengths in nm.
        %   Monochromatic primary wavelengths [R, G, B] used to derive RGB
        %   color matching functions from the cone fundamentals. Default:
        %   Stiles & Burch (1959) 10-degree primaries (see CIE170).
        Primaries (1,3) double {validators.mustBeValidPrimaries} = ...
            CIE170.STILES_BURCH_10DEG_PRIMARIES_NM

        % If true (default), warn once when wavelengths fall outside the active template range.
        %   Valid ranges: 360-830 nm for Stockman-Rider templates,
        %   380-780 nm for Govardovskii. Warning is emitted once per
        %   session per template configuration.
        WavelengthWarning (1,1) logical = true
    end

    properties (Access = private)
        % Internal storage convention. Two storage strategies coexist
        % deliberately:
        %
        %   1. Strategy 1 -- p_Parameters is the source of truth:
        %      Age, FieldSize, the cone PhotopigmentParameters
        %      (optical density and lambda-max shift), and the
        %      Lens/Macular PreReceptoralFilter (density). For these,
        %      the public Dependent property getters/setters read and
        %      write through p_Parameters.X.
        %
        %   2. Strategy 2 -- a bare p_* field is the source of truth:
        %      the algorithm-mode enums (MacularDensityAlgorithm,
        %      PhotopigmentDensityAlgorithm, LensDensityAlgorithm),
        %      the L/M opsin template selectors, and the manually-set
        %      LensDensity. These quantities are observer-level
        %      metadata that does not fit the PhotopigmentParameters /
        %      PreReceptoralFilter sub-objects, so they live as bare
        %      private fields. The corresponding fields exist on
        %      ObserverParameters but are written only at
        %      getParameters/setParameters time, not on every change.
        %
        % ObserverParameters is a transfer DTO: getParameters() gathers
        % both strategies into a snapshot; setParameters() reverses
        % the operation. Treat ObserverParameters as the wire format,
        % not a live mirror of IndividualCMF state.
        %
        % The p_ prefix marks "private working state of IndividualCMF"
        % and is applied uniformly to both strategies. Several p_*
        % fields are backing storage for public Dependent properties
        % of the same root name (e.g., p_LensDensity backs LensDensity);
        % MATLAB does not allow a Dependent and a non-Dependent
        % property to share a name, so the prefix is load-bearing in
        % those cases.
        p_L_Template (1,1) enums.LOpsinTemplate = ObserverParameters.DEFAULT_L_OPSIN_TEMPLATE
        p_M_Template (1,1) enums.MOpsinTemplate = ObserverParameters.DEFAULT_M_OPSIN_TEMPLATE
        p_MacularDensityAlgorithm (1,1) enums.MacularDensityAlgorithm = ObserverParameters.DEFAULT_MACULAR_DENSITY_ALGORITHM
        p_PhotopigmentDensityAlgorithm (1,1) enums.PhotopigmentDensityAlgorithm = ObserverParameters.DEFAULT_PHOTOPIGMENT_DENSITY_ALGORITHM
        p_LensDensityAlgorithm (1,1) enums.LensDensityAlgorithm = ObserverParameters.DEFAULT_LENS_DENSITY_ALGORITHM
        p_LensDensity = CIE170.STD_LENS_DENSITY_400
        p_IsInternalUpdate = false
        p_PhotopigmentTemplate
        % Instance of LensTemplate subclass
        p_LensTemplate
        % Instance of MacularTemplate subclass
        p_MacularTemplate
        GenotypeState dictionary = configureDictionary("string", "string")

        % Normalization configuration struct
        % For Continuous: struct('Method', "Continuous")
        % For Sampled: struct('Method', "Sampled", 'Start', 380, 'Stop', 780, 'Step', 1)
        p_NormalizationConfig struct = struct('Method', "Continuous")

        % NormalizationCache instance for caching peak values
        p_NormalizationCache

        % Flag to track if wavelength range warning has been issued this session
        p_WavelengthWarningIssued (1,1) logical = false

        % Strategy 1 storage: the cone parameters, pre-receptoral
        % filters, Age, and FieldSize. Read/written directly by the
        % corresponding public Dependent property accessors.
        p_Parameters (1,1) ObserverParameters
    end

    properties (Constant, Access = private)
        DEFAULT_WL = (360:1:830)';

        % Default operating range and step used by the "Sampled"
        % normalization mode. [380, 780] nm at 1 nm is the toolbox's
        % default sampling grid for normalization, NOT the CIE 170-1:2006
        % tabulation range (which is 390-830 nm; see tests/data/cvrl/).
        DEFAULT_SAMPLED_RANGE_NM = [380, 780]
        DEFAULT_SAMPLED_STEP_NM  = 1
    end
    
    methods
        function obj = IndividualCMF(options)
            % INDIVIDUALCMF  Construct a new IndividualCMF observer.
            %
            %   obj = IndividualCMF(...) creates a new observer model. 
            %   This method accepts the same Name-Value arguments documented 
            %   in the class header.
            %
            %   See the main class documentation for the full list of inputs:
            %       >> help IndividualCMF

            arguments
                options.StandardObserver (1,1) double {mustBeMember(options.StandardObserver, [0, 2, 10])} = 0
                options.Age (1,1) double {validators.mustBePositiveOrNaN} = NaN
                options.FieldSize (1,1) double {validators.mustBePositiveOrNaN} = NaN
                options.Lod (1,1) double {validators.mustBeNonnegativeFiniteOrNaN} = NaN
                options.Mod (1,1) double {validators.mustBeNonnegativeFiniteOrNaN} = NaN
                options.Sod (1,1) double {validators.mustBeNonnegativeFiniteOrNaN} = NaN
                options.MacularDensity (1,1) double {validators.mustBeNonnegativeFiniteOrNaN} = NaN
                options.LensDensity (1,1) double {validators.mustBeNonnegativeFiniteOrNaN} = NaN
                options.L_LambdaMaxShift (1,1) double {mustBeInRange(options.L_LambdaMaxShift, -40, 10)} = 0
                options.M_LambdaMaxShift (1,1) double {mustBeInRange(options.M_LambdaMaxShift, -20, 30)} = 0
                options.S_LambdaMaxShift (1,1) double {mustBeFinite} = 0
                options.L_OpsinTemplate (1,1) string {mustBeMember(options.L_OpsinTemplate, ["Mean", "Serine", "Alanine", "MinL"])} = "Mean"
                options.M_OpsinTemplate (1,1) string {mustBeMember(options.M_OpsinTemplate, ["Mean", "Standard", "LinM"])} = "Mean"
                options.NormalizeOutput (1,1) logical = true
                options.LogOutput (1,1) logical = false
                options.OutputFormat (1,1) string = "energy"
                % String or struct
                options.NormalizationMethod = "Continuous"
                options.PhotopigmentModel (1,1) string = "StockmanRider2023"
                options.LensModel (1,1) string {mustBeMember(options.LensModel, ["StockmanRider2023", "Pokorny1987", "VanDeKraats2007"])} = "StockmanRider2023"
                options.MacularModel (1,1) string {mustBeMember(options.MacularModel, "StockmanRider2023")} = "StockmanRider2023"
                options.MacularDensityAlgorithm (1,1) string {mustBeMember(options.MacularDensityAlgorithm, ["", "CIE170", "MorelandAlexander", "Custom"])} = ""
                options.PhotopigmentDensityAlgorithm (1,1) string {mustBeMember(options.PhotopigmentDensityAlgorithm, ["", "CIE170", "PokornySmith", "Custom"])} = ""
                options.LensDensityAlgorithm (1,1) string {mustBeMember(options.LensDensityAlgorithm, ["", "Auto", "Custom"])} = ""
                options.Primaries (1,3) double {validators.mustBeValidPrimaries} = ...
                    CIE170.STILES_BURCH_10DEG_PRIMARIES_NM
                options.Genotype = []
            end

            % Initialize template first (needed for cache computations). The default
            % template uses Stockman & Rider (2023) Fourier series templates, which
            % are the most accurate representation of human cone fundamentals.
            obj.p_PhotopigmentTemplate = StockmanRiderPhotopigmentTemplate();

            % Initialize lens template (needed for pre-receptoral filtering).
            obj.p_LensTemplate = StockmanRiderLensTemplate();

            % Initialize macular template (needed for pre-receptoral filtering).
            obj.p_MacularTemplate = StockmanRider2023MacularTemplate();

            % Initialize p_Parameters with defaults. Configuration methods (applyStandardObserver,
            % applyManualConfig) will update these values. All property getters read from
            % p_Parameters, so it must be initialized before any dependent calculations.
            obj.p_Parameters = ObserverParameters();

            % 2. Initialize normalization config (before cache)
            obj.p_NormalizationConfig = struct('Method', "Continuous");

            % 3. Initialize cache (needs observer reference)
            obj.p_NormalizationCache = NormalizationCache(obj);

            % 4. Setup listeners (these will trigger cache invalidation)
            addlistener(obj, 'OutputFormat',   'PostSet', @(s,e) obj.invalidateNormalizationCache());
            addlistener(obj, 'LogOutput',      'PostSet', @(s,e) obj.invalidateNormalizationCache());
            addlistener(obj, 'NormalizeOutput','PostSet', @(s,e) obj.invalidateNormalizationCache());

            obj.GenotypeState = dictionary(string.empty, string.empty);

            % 5. Apply model selections before applying parameter overrides.
            %
            % Rationale: LensModel's setter recalculates lens density from age.
            % If LensModel is set *after* applyManualConfig applies an explicit
            % LensDensity override, the override is unintentionally overwritten.
            % Setting models first ensures explicit overrides persist.
            obj.PhotopigmentModel = options.PhotopigmentModel;
            obj.LensModel = options.LensModel;
            obj.MacularModel = options.MacularModel;

            % 6. Apply configuration (triggers setters which invalidate cache as needed)
            if options.StandardObserver > 0
                obj.applyStandardObserver(options);
            else
                obj.applyManualConfig(options);
            end

            obj.NormalizeOutput = options.NormalizeOutput;
            obj.LogOutput = options.LogOutput;
            obj.OutputFormat = options.OutputFormat;
            % Note: FieldSizeMethod is set in applyManualConfig based on density overrides
            obj.Primaries = options.Primaries;

            % 7. Set normalization method last (may override defaults)
            obj.NormalizationMethod = options.NormalizationMethod;
        end
    end

    % Property accessors
    % Paired set.* / get.* methods. Set comes first, get second (matching the
    % file-wide convention) so a reader scanning by property name lands on
    % the constraint/validation logic before the trivial getter.
    methods
        function set.Age(obj, v)
            % set.Age  Set observer age and recalculate lens density.
            %   Validates before mutating so a bad value (NaN, Inf,
            %   non-positive) throws cleanly without leaving Age and the
            %   lens filter in an inconsistent half-updated state.
            arguments
                obj
                v (1,1) double {mustBePositive, mustBeFinite}
            end
            obj.p_Parameters.Age = v;
            obj.recalcLensFromAge();
            obj.p_Parameters.Lens = PreReceptoralFilter( ...
                Type="lens", ...
                Density=obj.LensDensity / CIE170.STD_LENS_DENSITY_400, ...
                Age=v);
            obj.invalidateNormalizationCache();
        end

        function v = get.Age(obj)
            % get.Age  Get observer age in years.
            v = obj.p_Parameters.Age;
        end

        function set.FieldSize(obj, v)
            % set.FieldSize  Set field size and recalculate optical densities.
            %   If changing to a non-standard size (not 2 or 10) and algorithms are
            %   "CIE170", automatically switch to formula-based algorithms.
            %
            %   Validation runs first so a bad value (NaN, Inf, negative)
            %   throws cleanly without partially mutating algorithm state.
            arguments
                obj
                v (1,1) double {mustBePositive, mustBeFinite}
            end
            isStandardSize = (v == 2 || v == 10);

            % Auto-switch from CIE Constants to formulas for non-standard sizes
            if ~isStandardSize
                if obj.p_MacularDensityAlgorithm == "CIE170"
                    obj.p_MacularDensityAlgorithm = "MorelandAlexander";
                end
                if obj.p_PhotopigmentDensityAlgorithm == "CIE170"
                    obj.p_PhotopigmentDensityAlgorithm = "PokornySmith";
                end
            end

            obj.p_Parameters.FieldSize = v;
            obj.recalcBiophysics();
            obj.invalidateNormalizationCache();
        end

        function v = get.FieldSize(obj)
            % get.FieldSize  Get field size in degrees.
            v = obj.p_Parameters.FieldSize;
        end

        function set.MacularDensityAlgorithm(obj, val)
            % set.MacularDensityAlgorithm  Set the macular density calculation algorithm.
            arguments
                obj
                val (1,1) enums.MacularDensityAlgorithm
            end
            oldAlg = obj.p_MacularDensityAlgorithm;
            obj.p_MacularDensityAlgorithm = val;

            if oldAlg == "Custom" && val ~= "Custom"
                warning('IndividualCMF:MacularCustomOverwritten', ...
                    'Switching from Custom macular mode. MacularDensity will be recalculated.');
            end

            if val ~= "Custom"
                obj.updateMacularDensity();
            end
        end

        function v = get.MacularDensityAlgorithm(obj)
            % get.MacularDensityAlgorithm  Get the macular density calculation algorithm.
            v = obj.p_MacularDensityAlgorithm;
        end

        function set.PhotopigmentDensityAlgorithm(obj, val)
            % set.PhotopigmentDensityAlgorithm  Set the photopigment density calculation algorithm.
            arguments
                obj
                val (1,1) enums.PhotopigmentDensityAlgorithm
            end
            oldAlg = obj.p_PhotopigmentDensityAlgorithm;
            obj.p_PhotopigmentDensityAlgorithm = val;

            if oldAlg == "Custom" && val ~= "Custom"
                warning('IndividualCMF:PhotopigmentCustomOverwritten', ...
                    'Switching from Custom photopigment mode. Lod/Mod/Sod will be recalculated.');
            end

            if val ~= "Custom"
                obj.updatePhotopigmentDensities();
            end
        end

        function v = get.PhotopigmentDensityAlgorithm(obj)
            % get.PhotopigmentDensityAlgorithm  Get the photopigment density calculation algorithm.
            v = obj.p_PhotopigmentDensityAlgorithm;
        end

        function v = get.Type(obj)
            % get.Type  Return observer type based on strict biophysical criteria.
            %   Returns "CIE 170-1:2006" only if all parameters match the CIE standard.
            %   Otherwise returns "Individualized".
            %
            %   See also: isStandardConfiguration

            if obj.isStandardConfiguration()
                v = "CIE 170-1:2006";
            else
                v = "Individualized";
            end
        end

        function v = get.StandardObserver(obj)
            % get.StandardObserver  Return 0/2/10 based on current configuration.
            %   2  - configuration matches the CIE 2006 2-deg standard
            %   10 - configuration matches the CIE 2006 10-deg standard
            %   0  - any other configuration
            if obj.isStandardConfiguration() && obj.p_Parameters.FieldSize == 2
                v = 2;
            elseif obj.isStandardConfiguration() && obj.p_Parameters.FieldSize == 10
                v = 10;
            else
                v = 0;
            end
        end

        function set.StandardObserver(obj, val)
            % set.StandardObserver  Snap the observer to a CIE standard.
            %   Accepts 2 or 10. Resets every relevant biophysical
            %   parameter to the tabulated values for that field size.
            %   Output-shape options are preserved.
            %
            %   See also: snapToStandardObserver, applyStandardObserver
            arguments
                obj
                val (1,1) double {mustBeMember(val, [2, 10])}
            end
            obj.snapToStandardObserver(val);
        end

        function set.Lod(obj, v)
            % set.Lod  Set L-cone optical density.
            arguments
                obj
                v (1,1) double
            end
            obj.p_Parameters.LCone = PhotopigmentParameters( ...
                OpticalDensity=v, ...
                LambdaMaxShift=obj.p_Parameters.LCone.LambdaMaxShift);
            if ~obj.p_IsInternalUpdate
                obj.updatePhotopigmentAlgorithmFromValues();
            end
            obj.invalidateNormalizationCache();
        end

        function v = get.Lod(obj)
            % get.Lod  Get L-cone optical density.
            v = obj.p_Parameters.LCone.OpticalDensity;
        end

        function set.Mod(obj, v)
            % set.Mod  Set M-cone optical density.
            arguments
                obj
                v (1,1) double
            end
            obj.p_Parameters.MCone = PhotopigmentParameters( ...
                OpticalDensity=v, ...
                LambdaMaxShift=obj.p_Parameters.MCone.LambdaMaxShift);
            if ~obj.p_IsInternalUpdate
                obj.updatePhotopigmentAlgorithmFromValues();
            end
            obj.invalidateNormalizationCache();
        end

        function v = get.Mod(obj)
            % get.Mod  Get M-cone optical density.
            v = obj.p_Parameters.MCone.OpticalDensity;
        end

        function set.Sod(obj, v)
            % set.Sod  Set S-cone optical density.
            arguments
                obj
                v (1,1) double
            end
            obj.p_Parameters.SCone = PhotopigmentParameters( ...
                OpticalDensity=v, ...
                LambdaMaxShift=obj.p_Parameters.SCone.LambdaMaxShift);
            if ~obj.p_IsInternalUpdate
                obj.updatePhotopigmentAlgorithmFromValues();
            end
            obj.invalidateNormalizationCache();
        end

        function v = get.Sod(obj)
            % get.Sod  Get S-cone optical density.
            v = obj.p_Parameters.SCone.OpticalDensity;
        end

        function set.MacularDensity(obj, v)
            % set.MacularDensity  Set macular pigment density.
            arguments
                obj
                v (1,1) double
            end
            obj.p_Parameters.Macular = PreReceptoralFilter(Type="macular", Density=v);
            if ~obj.p_IsInternalUpdate
                % Tag the assigned value: CIE170 if it matches the standard
                % table for the current field size (2 or 10 deg only), Custom
                % otherwise. Non-standard field sizes can never be CIE170 --
                % there is no published table to match against.
                fieldSize = obj.p_Parameters.FieldSize;
                if (fieldSize == 2 || fieldSize == 10) && ...
                        v == PreReceptoralFilter.macularDensityCIEStandard(fieldSize)
                    obj.p_MacularDensityAlgorithm = "CIE170";
                else
                    obj.p_MacularDensityAlgorithm = "Custom";
                end
            end
            obj.invalidateNormalizationCache();
        end

        function v = get.MacularDensity(obj)
            % get.MacularDensity  Get macular pigment density.
            v = obj.p_Parameters.Macular.Density;
        end

        function set.L_LambdaMaxShift(obj, v)
            % set.L_LambdaMaxShift  Set L-cone peak wavelength shift.
            arguments
                obj
                v (1,1) double {mustBeInRange(v, -40, 10)}
            end
            obj.p_Parameters.LCone = PhotopigmentParameters( ...
                OpticalDensity=obj.p_Parameters.LCone.OpticalDensity, ...
                LambdaMaxShift=v);
            obj.invalidateNormalizationCache();
        end

        function v = get.L_LambdaMaxShift(obj)
            % get.L_LambdaMaxShift  Get L-cone peak wavelength shift in nm.
            v = obj.p_Parameters.LCone.LambdaMaxShift;
        end

        function set.M_LambdaMaxShift(obj, v)
            % set.M_LambdaMaxShift  Set M-cone peak wavelength shift.
            arguments
                obj
                v (1,1) double {mustBeInRange(v, -20, 30)}
            end
            obj.p_Parameters.MCone = PhotopigmentParameters( ...
                OpticalDensity=obj.p_Parameters.MCone.OpticalDensity, ...
                LambdaMaxShift=v);
            obj.invalidateNormalizationCache();
        end

        function v = get.M_LambdaMaxShift(obj)
            % get.M_LambdaMaxShift  Get M-cone peak wavelength shift in nm.
            v = obj.p_Parameters.MCone.LambdaMaxShift;
        end

        function set.S_LambdaMaxShift(obj, v)
            % set.S_LambdaMaxShift  Set S-cone peak wavelength shift.
            %   S is left otherwise unbounded (L and M shifts use
            %   mustBeInRange to clamp to the physiologically plausible
            %   window). mustBeFinite still rejects NaN/Inf, which would
            %   propagate into the fminbnd peak-search bounds and produce
            %   non-finite spectra downstream.
            arguments
                obj
                v (1,1) double {mustBeFinite}
            end
            obj.p_Parameters.SCone = PhotopigmentParameters( ...
                OpticalDensity=obj.p_Parameters.SCone.OpticalDensity, ...
                LambdaMaxShift=v);
            obj.invalidateNormalizationCache();
        end

        function v = get.S_LambdaMaxShift(obj)
            % get.S_LambdaMaxShift  Get S-cone peak wavelength shift in nm.
            v = obj.p_Parameters.SCone.LambdaMaxShift;
        end

        function set.L_OpsinTemplate(obj, v)
            % set.L_OpsinTemplate  Set L-cone opsin template shape.
            arguments
                obj
                v (1,1) enums.LOpsinTemplate
            end
            if obj.PhotopigmentModel == "Govardovskii2000" || ...
                    obj.PhotopigmentModel == "Govardovskii2000A2"
                warning('IndividualCMF:IgnoredProperty', ...
                    'L_OpsinTemplate is ignored when using the Govardovskii model.');
            end
            obj.p_L_Template = v;
            obj.invalidateNormalizationCache();
        end

        function v = get.L_OpsinTemplate(obj)
            % get.L_OpsinTemplate  Get L-cone opsin template shape.
            v = obj.p_L_Template;
        end

        function set.M_OpsinTemplate(obj, v)
            % set.M_OpsinTemplate  Set M-cone opsin template shape.
            arguments
                obj
                v (1,1) enums.MOpsinTemplate
            end
            if obj.PhotopigmentModel == "Govardovskii2000" || ...
                    obj.PhotopigmentModel == "Govardovskii2000A2"
                warning('IndividualCMF:IgnoredProperty', ...
                    'M_OpsinTemplate is ignored when using the Govardovskii model.');
            end
            obj.p_M_Template = v;
            obj.invalidateNormalizationCache();
        end

        function v = get.M_OpsinTemplate(obj)
            % get.M_OpsinTemplate  Get M-cone opsin template shape.
            v = obj.p_M_Template;
        end

        function set.PhotopigmentModel(obj, v)
            % set.PhotopigmentModel  Set the template model by name.
            %   Changing the template resets the wavelength warning flag because
            %   different templates have different valid wavelength ranges.
            arguments
                obj
                v (1,1) enums.PhotopigmentModel
            end
            % Instantiate the appropriate photopigment template based on
            % the requested model. StockmanRider2023 uses Fourier series
            % templates from Stockman & Rider (2023). Govardovskii2000
            % and Govardovskii2000A2 use the parametric A1 and A2 visual
            % pigment templates from Govardovskii et al. (2000).
            switch v
                case enums.PhotopigmentModel.StockmanRider2023
                    obj.p_PhotopigmentTemplate = StockmanRiderPhotopigmentTemplate();
                case enums.PhotopigmentModel.Govardovskii2000
                    obj.p_PhotopigmentTemplate = GovardovskiiPhotopigmentTemplate();
                case enums.PhotopigmentModel.Govardovskii2000A2
                    obj.p_PhotopigmentTemplate = ...
                        GovardovskiiPhotopigmentTemplate(Pigment="A2");
            end
            obj.p_WavelengthWarningIssued = false;
            obj.invalidateNormalizationCache();
        end

        function v = get.PhotopigmentModel(obj)
            % get.PhotopigmentModel  Get the template model name.
            if isempty(obj.p_PhotopigmentTemplate)
                v = enums.PhotopigmentModel.StockmanRider2023;
            else
                v = enums.PhotopigmentModel(obj.p_PhotopigmentTemplate.ShortName);
            end
        end

        function set.LensModel(obj, v)
            % set.LensModel  Set the lens template model by name.
            %
            %   In Auto mode (the default), switching the lens model also
            %   recalculates LensDensity using the new model's
            %   computeDensityAt400() method. In Custom mode the
            %   user-provided LensDensity is preserved.
            %
            %   StockmanRider2023: No aging - LensDensity stays at STD_LENS_DENSITY_400
            %   Pokorny1987:       Age-dependent - LensDensity varies per the 1987 model
            %   VanDeKraats2007:   Age-dependent - LensDensity varies per the 2007 model
            arguments
                obj
                v (1,1) enums.LensModel
            end
            switch v
                case enums.LensModel.StockmanRider2023
                    obj.p_LensTemplate = StockmanRiderLensTemplate();
                case enums.LensModel.Pokorny1987
                    obj.p_LensTemplate = Pokorny1987LensTemplate();
                case enums.LensModel.VanDeKraats2007
                    obj.p_LensTemplate = VanDeKraatsVanNorren2007LensTemplate();
            end
            obj.recalcLensFromAge();
            obj.invalidateNormalizationCache();
        end

        function v = get.LensModel(obj)
            % get.LensModel  Get the lens template model name.
            if isempty(obj.p_LensTemplate)
                v = enums.LensModel.StockmanRider2023;
            else
                v = enums.LensModel(obj.p_LensTemplate.ShortName);
            end
        end

        function set.MacularModel(obj, v)
            % set.MacularModel  Select the macular template strategy.
            %
            %   Switches the active MacularTemplate subclass. The peak
            %   macular density (MacularDensity, in OD at 460 nm) is
            %   independent of the spectral shape and is preserved across
            %   model changes.
            arguments
                obj
                v (1,1) enums.MacularModel
            end
            switch v
                case enums.MacularModel.StockmanRider2023
                    obj.p_MacularTemplate = StockmanRider2023MacularTemplate();
            end
            obj.invalidateNormalizationCache();
        end

        function v = get.MacularModel(obj)
            % get.MacularModel  Get the macular template model name.
            if isempty(obj.p_MacularTemplate)
                v = enums.MacularModel.StockmanRider2023;
            else
                v = enums.MacularModel(obj.p_MacularTemplate.ShortName);
            end
        end

        function set.LensDensity(obj, v)
            % set.LensDensity  Set lens optical density at 400 nm.
            %   Direct assignment auto-engages LensDensityAlgorithm="Custom"
            %   so the value is preserved across subsequent Age, FieldSize,
            %   or LensModel changes. Internal recalculations from
            %   recalcLensFromAge bypass the mode switch via the
            %   p_IsInternalUpdate flag.
            arguments
                obj
                v (1,1) double {mustBeNonnegative, mustBeFinite}
            end
            obj.p_LensDensity = v;
            if ~obj.p_IsInternalUpdate
                obj.p_LensDensityAlgorithm = "Custom";
            end
            obj.invalidateNormalizationCache();
        end

        function v = get.LensDensity(obj)
            % get.LensDensity  Get lens optical density at 400 nm.
            v = obj.p_LensDensity;
        end

        function set.LensDensityAlgorithm(obj, val)
            % set.LensDensityAlgorithm  Set the lens density mode.
            %   Switching from "Custom" to "Auto" warns and recomputes
            %   LensDensity from the active LensModel and current Age.
            arguments
                obj
                val (1,1) enums.LensDensityAlgorithm
            end
            oldAlg = obj.p_LensDensityAlgorithm;
            obj.p_LensDensityAlgorithm = val;

            if oldAlg == "Custom" && val == "Auto"
                warning('IndividualCMF:LensCustomOverwritten', ...
                    'Switching from Custom lens mode. LensDensity will be recalculated from Age.');
            end

            if val == "Auto"
                obj.recalcLensFromAge();
            end
        end

        function v = get.LensDensityAlgorithm(obj)
            % get.LensDensityAlgorithm  Get the lens density mode.
            v = obj.p_LensDensityAlgorithm;
        end

        function set.NormalizationMethod(obj, val)
            % set.NormalizationMethod  Set the normalization method.
            %
            %   Accepts:
            %     - "Continuous" string - Optimization-based peak finding (default)
            %     - "Sampled" string    - Discrete sampling with default resolution
            %     - struct with Method="Sampled" - Explicit resolution for reproducibility
            %
            %   EXAMPLE:
            %       obj.NormalizationMethod = "Continuous";
            %       obj.NormalizationMethod = "Sampled";
            %       obj.NormalizationMethod = struct('Method', "Sampled", 'Step', 5);
            if isstring(val) || ischar(val)
                val = string(val);
                switch val
                    case "Continuous"
                        obj.p_NormalizationConfig = struct('Method', "Continuous");
                    case "Sampled"
                        obj.p_NormalizationConfig = struct(...
                            'Method', "Sampled", ...
                            'Start', IndividualCMF.DEFAULT_SAMPLED_RANGE_NM(1), ...
                            'Stop',  IndividualCMF.DEFAULT_SAMPLED_RANGE_NM(2), ...
                            'Step',  IndividualCMF.DEFAULT_SAMPLED_STEP_NM);
                    otherwise
                        error('IndividualCMF:InvalidNormalizationMethod', ...
                            'NormalizationMethod must be "Continuous", "Sampled", or a struct with Method="Sampled".');
                end
            elseif isstruct(val)
                obj.p_NormalizationConfig = obj.validateSampledConfig(val);
            else
                error('IndividualCMF:InvalidNormalizationMethod', ...
                    'NormalizationMethod must be "Continuous", "Sampled", or a struct with Method="Sampled".');
            end
            obj.invalidateNormalizationCache();
        end

        function v = get.NormalizationMethod(obj)
            % get.NormalizationMethod  Get the normalization method name.
            %
            %   Returns "Continuous" or "Sampled" for clean display.
            %   Use NormalizationConfig to get the full configuration struct.
            v = obj.p_NormalizationConfig.Method;
        end

        function v = get.NormalizationConfig(obj)
            % get.NormalizationConfig  Get the full normalization configuration.
            %
            %   Returns the complete configuration struct, allowing inspection
            %   of all settings including resolution parameters for Sampled mode.
            v = obj.p_NormalizationConfig;
        end
    end

    % Public API
    % Genotype configuration, parameter transfer, and computation methods.
    % These are the primary entry points after construction.
    methods
        function setGenotype(obj, cone, position, amino_acid)
            % SETGENOTYPE  Adjusts cone peaks based on amino acid polymorphisms.
            %   Sets the genotype for a specific position and updates the lambda-max shift.
            %
            %   INPUTS:
            %       cone - Cone type: "L" or "M" (string)
            %       position - Amino acid position (e.g., 180) (int)
            %       amino_acid - Amino acid code (e.g., "Ser", "Ala") (string)
            arguments
                obj
                cone (1,1) string {mustBeMember(cone, ["L", "M"])}
                position (1,1) double {mustBeMember(position, [116, 180, 230, 233, 277, 285, 309])}
                amino_acid (1,1) string
            end

            key = sprintf("%s_%d", cone, position);
            obj.GenotypeState(key) = amino_acid;

            % Constants for scaling shifts (from Stockman & Rider)
            M_scale = Genotype.LSER_MLMAX_DIFF / Genotype.M_BASES_SUM;
            L_scale = Genotype.LSER_MLMAX_DIFF / Genotype.L_BASES_SUM;

            total = 0;
            sites = [116, 180, 230, 233, 277, 285, 309];

            if cone == "M"
                scale = M_scale;
                % Check for Hybrid Condition (L-in-M)
                if obj.hasGenotype("M_277", "Tyr") && obj.hasGenotype("M_285", "Thr")
                    obj.p_M_Template = "LinM";
                else
                    obj.p_M_Template = "Standard";
                end
            else
                scale = L_scale;
                % Check for Hybrid Condition (M-in-L)
                if obj.hasGenotype("L_277", "Phe") && obj.hasGenotype("L_285", "Ala")
                    obj.p_L_Template = "MinL";
                else
                    obj.p_L_Template = "Serine";
                end
            end

            % Calculate cumulative shift using dictionary lookup
            for site = sites
                % Construct key e.g., "L_180_Ala"
                lookupKey = sprintf("%s_%d_%s", cone, site, obj.getGenotypeAt(cone, site));
                if isKey(Genotype.GENOTYPE_SHIFTS, lookupKey)
                    shiftVal = Genotype.GENOTYPE_SHIFTS(lookupKey);
                    total = total + (shiftVal * scale);
                end
            end

            if cone == "M"
                obj.p_Parameters.MCone = PhotopigmentParameters( ...
                    OpticalDensity=obj.p_Parameters.MCone.OpticalDensity, ...
                    LambdaMaxShift=total);
            else
                obj.p_Parameters.LCone = PhotopigmentParameters( ...
                    OpticalDensity=obj.p_Parameters.LCone.OpticalDensity, ...
                    LambdaMaxShift=total);
            end
            obj.invalidateNormalizationCache();
        end

        function applyGenotype(obj, genotypeString, options)
            % APPLYGENOTYPE  Configure observer from opsin genotype string.
            %
            %   obj.applyGenotype(genotypeString) parses the genotype string
            %   and applies the computed lambda-max shifts to the observer.
            %   The genotype string uses the standard 5-letter notation format:
            %   "L-geno/M-geno" where each genotype is a 5-character string
            %   representing amino acids at positions 116, 180, 230, 277, 285.
            %
            %   By default, Age and FieldSize are preserved. Use the optional
            %   arguments to reset them to defaults when applying genotype.
            %
            %   INPUTS:
            %       genotypeString - Genotype in "L-geno/M-geno" format (string)
            %           Examples: "LSAYT/SAAFA" (normal trichromat, pycone default)
            %                     "LSAYT" (deuteranope: L-only; Mod is set to 0)
            %                     "/SAAFA" (protanope:  M-only; Lod is set to 0)
            %
            %   For one-sided genotypes the missing cone is taken to be
            %   absent. The corresponding optical density (Mod for an
            %   empty M genotype, Lod for an empty L genotype) is set to
            %   zero so the LMS column is identically zero (matches
            %   ColorVisionType from the Genotype class).
            %
            %   OPTIONAL INPUTS (Name-Value arguments):
            %       PreserveAge - If true (default), keeps current Age (logical)
            %       PreserveFieldSize - If true (default), keeps current FieldSize (logical)
            %
            %   EXAMPLE:
            %       obs = IndividualCMF();
            %       obs.applyGenotype("LSAYT/SAAFA");
            %
            %       obs.applyGenotype("LSAYT", PreserveAge=false);
            %
            %   See also: Genotype, getParameters, setParameters
            arguments
                obj
                genotypeString (1,1) string
                options.PreserveAge (1,1) logical = true
                options.PreserveFieldSize (1,1) logical = true
            end

            % Parse the genotype string using the Genotype class
            g = Genotype(genotypeString);

            % Preserve current values if requested
            if ~options.PreserveAge
                obj.Age = CIE170.STD_AGE;
            end

            if ~options.PreserveFieldSize
                obj.FieldSize = CIE170.STD_FIELD_SIZE_10DEG;
            end

            obj.applyGenotypeShifts(g);
        end
    end

    % applyGenotypeShifts is an internal mutator shared by the three
    % string-genotype entry points (applyGenotype, processGenotypeInput's
    % string branch, and Genotype.toObserverParameters). Restricting
    % access to IndividualCMF and Genotype keeps users from reaching
    % around the validated public APIs to mutate observer state directly.
    methods (Access = {?IndividualCMF, ?Genotype})

        function applyGenotypeShifts(obj, g)
            % APPLYGENOTYPESHIFTS  Internal: apply a parsed Genotype to observer state.
            %
            %   Single source of truth for the three string-genotype entry
            %   points (applyGenotype, the Genotype= constructor string
            %   branch, Genotype.toObserverParameters). Handles shift,
            %   template selection, and absent-cone optical density
            %   symmetrically.
            %
            %   One-sided genotypes mean the missing cone is absent:
            %     - empty L genotype (e.g. "/SAAFA"):  Lod = 0  (protanope)
            %     - empty M genotype (e.g. "LSAYT"):   Mod = 0  (deuteranope)
            %
            %   Round-trip: when a cone goes from absent (Lod=0 or Mod=0)
            %   back to present (its genotype is supplied), the optical
            %   density is restored to its standard value before shifts
            %   and templates are applied.
            %
            %   Template selection (per cone), standardised on the
            %   non-warning path:
            %     - L: F+A at 277/285 -> "MinL"; otherwise "Serine"
            %     - M: Y+T at 277/285 -> "LinM"; otherwise "Standard"
            %   The "Mean" template warns and silently switches to Serine
            %   when paired with a non-zero shift, so it is never selected
            %   here.
            %
            %   GenotypeState is populated for each codon so getGenotypeAt
            %   and hasGenotype report consistently across all three entry
            %   points.
            arguments
                obj
                g (1,1) Genotype
            end

            % Default optical densities for the observer's current
            % field size. Used to restore Lod/Mod when a previously
            % absent cone becomes present again, so a 2-deg observer
            % round-tripped through dichromacy gets back to ~0.5, not
            % the 10-deg constant 0.38.
            [defaultLod, defaultMod, ~] = ...
                PhotopigmentParameters.densitiesCIEStandard(obj.FieldSize);

            % L cone
            if isempty(g.LGenotype)
                % Absent cone: zero the OD AND clear shift/template/state
                % so a snapshot of the observer matches the parsed
                % genotype (LShift==0, no GenotypeState entries) rather
                % than retaining the previous cone's state.
                obj.Lod = 0;
                obj.L_LambdaMaxShift = 0;
                obj.L_OpsinTemplate = "Mean";
                clearConeGenotypeState(obj, 'L');
            else
                if obj.Lod == 0
                    obj.Lod = defaultLod;
                end
                pos = Genotype.POSITIONS;
                for i = 1:numel(pos)
                    aa = Genotype.AMINO_ACID_MAP(g.LGenotype(i));
                    obj.GenotypeState(sprintf("L_%d", pos(i))) = aa;
                end
                obj.L_LambdaMaxShift = g.LShift;
                if g.isLHybrid()
                    obj.L_OpsinTemplate = "MinL";
                else
                    obj.L_OpsinTemplate = "Serine";
                end
            end

            % M cone
            if isempty(g.MGenotype)
                obj.Mod = 0;
                obj.M_LambdaMaxShift = 0;
                obj.M_OpsinTemplate = "Mean";
                clearConeGenotypeState(obj, 'M');
            else
                if obj.Mod == 0
                    obj.Mod = defaultMod;
                end
                pos = Genotype.POSITIONS;
                for i = 1:numel(pos)
                    aa = Genotype.AMINO_ACID_MAP(g.MGenotype(i));
                    obj.GenotypeState(sprintf("M_%d", pos(i))) = aa;
                end
                obj.M_LambdaMaxShift = g.MShift;
                if g.isMHybrid()
                    obj.M_OpsinTemplate = "LinM";
                else
                    obj.M_OpsinTemplate = "Standard";
                end
            end
        end
    end

    methods

        function params = getParameters(obj)
            % GETPARAMETERS  Get copy of current observer parameters.
            %
            %   params = obj.getParameters() returns an ObserverParameters object
            %   containing a complete snapshot of the current observer:
            %     - Physiological: Age, FieldSize, cone OD/shifts, Lens.Density,
            %       Macular.Density.
            %     - Model selections: PhotopigmentModel, LensModel, L_OpsinTemplate,
            %       M_OpsinTemplate.
            %     - Algorithm modes: MacularDensityAlgorithm,
            %       PhotopigmentDensityAlgorithm, LensDensityAlgorithm.
            %
            %   The returned object is a value class, so modifying it will not
            %   affect the observer. Use setParameters() to apply a snapshot to
            %   another observer; the round-trip preserves all of the above
            %   such that obs2.setParameters(obs1.getParameters()) produces
            %   identical LMS output.
            %
            %   OUTPUTS:
            %       params - Snapshot of current parameters (ObserverParameters)
            %
            %   EXAMPLE:
            %       obs = IndividualCMF(Age=45, FieldSize=2);
            %       params = obs.getParameters();
            %       disp(params.Age);  % 45
            %       disp(params.LCone.OpticalDensity);  % Current L-cone OD
            %
            %   See also: setParameters, applyGenotype, ObserverParameters
            arguments
                obj
            end

            % Build lens filter with current density and age
            lens = PreReceptoralFilter( ...
                Type="lens", ...
                Density=obj.LensDensity / CIE170.STD_LENS_DENSITY_400, ...
                Age=obj.p_Parameters.Age);

            % Return a new ObserverParameters with current values
            % (value class semantics ensure caller gets an independent copy).
            % Model selections and algorithm modes are also captured so
            % setParameters can perform a complete round-trip -- see the
            % "Round-trip semantics" note on setParameters.
            params = ObserverParameters( ...
                LCone=obj.p_Parameters.LCone, ...
                MCone=obj.p_Parameters.MCone, ...
                SCone=obj.p_Parameters.SCone, ...
                Lens=lens, ...
                Macular=obj.p_Parameters.Macular, ...
                Age=obj.p_Parameters.Age, ...
                FieldSize=obj.p_Parameters.FieldSize, ...
                PhotopigmentModel=obj.PhotopigmentModel, ...
                LensModel=obj.LensModel, ...
                MacularModel=obj.MacularModel, ...
                L_OpsinTemplate=obj.L_OpsinTemplate, ...
                M_OpsinTemplate=obj.M_OpsinTemplate, ...
                MacularDensityAlgorithm=obj.MacularDensityAlgorithm, ...
                PhotopigmentDensityAlgorithm=obj.PhotopigmentDensityAlgorithm, ...
                LensDensityAlgorithm=obj.LensDensityAlgorithm);
        end

        function setParameters(obj, params)
            % SETPARAMETERS  Set observer parameters from ObserverParameters object.
            %
            %   obj.setParameters(params) applies all fields captured by
            %   getParameters: physiological values (Age, FieldSize, cone
            %   OD/shifts, lens/macular density), model selections
            %   (PhotopigmentModel, LensModel, L/M_OpsinTemplate), and algorithm
            %   modes (MacularDensityAlgorithm, PhotopigmentDensityAlgorithm,
            %   LensDensityAlgorithm).
            %
            %   The receiver's algorithm modes are set to match the source's,
            %   so subsequent property changes on the receiver behave the
            %   same as they would on the source. For example, if the source
            %   was in "Custom" lens mode, the receiver's LensDensity is
            %   preserved across Age changes; if the source was "CIE
            %   Constants", the receiver re-derives densities on FieldSize
            %   changes.
            %
            %   INPUTS:
            %       params - Parameters to apply (ObserverParameters)
            %
            %   EXAMPLE:
            %       % Round-trip preserves complete observer state:
            %       obs1 = IndividualCMF(LensModel="Pokorny1987", Age=70);
            %       params = obs1.getParameters();
            %       obs2 = IndividualCMF();
            %       obs2.setParameters(params);
            %       isequal(obs1.LMS(400:5:700), obs2.LMS(400:5:700))   % true
            %
            %       % Apply a CIE standard observer's parameters:
            %       obs.setParameters(ObserverParameters.standard2Deg());
            %
            %   See also: getParameters, applyGenotype, ObserverParameters
            arguments
                obj
                params (1,1) ObserverParameters
            end

            % Round-trip semantics:
            %   setParameters preserves all fields captured by getParameters.
            %   Density values are written first under temporary "Custom"
            %   modes (so model assignments and value writes do not clobber
            %   them), then the source's algorithm modes are restored at
            %   the end via private fields. Writing the modes via private
            %   fields skips the IndividualCMF:*CustomOverwritten warning
            %   that would fire on the public setter -- the warning is
            %   intended for interactive mode changes, not parameter
            %   transfers, and the values are already consistent with the
            %   source's modes (they came from the same algorithms there).
            obj.p_PhotopigmentDensityAlgorithm = "Custom";
            obj.p_MacularDensityAlgorithm = "Custom";
            obj.p_LensDensityAlgorithm = "Custom";

            % Apply model selections. In Custom mode these are no-ops for
            % density; the lens template still swaps for spectrum shape.
            obj.PhotopigmentModel = params.PhotopigmentModel;
            obj.LensModel = params.LensModel;
            obj.MacularModel = params.MacularModel;
            obj.p_L_Template = params.L_OpsinTemplate;
            obj.p_M_Template = params.M_OpsinTemplate;

            % Apply physiological parameters
            obj.p_Parameters.Age = params.Age;
            obj.p_Parameters.FieldSize = params.FieldSize;

            % Apply cone parameters
            obj.p_Parameters.LCone = PhotopigmentParameters( ...
                OpticalDensity=params.LCone.OpticalDensity, ...
                LambdaMaxShift=params.LCone.LambdaMaxShift);

            obj.p_Parameters.MCone = PhotopigmentParameters( ...
                OpticalDensity=params.MCone.OpticalDensity, ...
                LambdaMaxShift=params.MCone.LambdaMaxShift);

            obj.p_Parameters.SCone = PhotopigmentParameters( ...
                OpticalDensity=params.SCone.OpticalDensity, ...
                LambdaMaxShift=params.SCone.LambdaMaxShift);

            % Apply pre-receptoral filter parameters
            obj.p_Parameters.Macular = PreReceptoralFilter( ...
                Type="macular", ...
                Density=params.Macular.Density);
            obj.LensDensity = params.Lens.Density * CIE170.STD_LENS_DENSITY_400;

            % Restore source's algorithm modes via private fields (see
            % round-trip note above).
            obj.p_PhotopigmentDensityAlgorithm = params.PhotopigmentDensityAlgorithm;
            obj.p_MacularDensityAlgorithm = params.MacularDensityAlgorithm;
            obj.p_LensDensityAlgorithm = params.LensDensityAlgorithm;

            % Invalidate cache since parameters changed
            obj.invalidateNormalizationCache();
        end

        function val = L(obj, wl)
            % L  Calculate L-cone sensitivity.
            %   val = obj.L(wl) returns sensitivity at specified wavelengths.
            %   Returns zeros (or -10 in LogOutput mode) when Lod == 0
            %   (protanope).
            arguments
                obj
                wl double = obj.DEFAULT_WL
            end
            val = obj.calculateSensitivity(wl, 'L');
        end

        function val = M(obj, wl)
            % M  Calculate M-cone sensitivity.
            %   val = obj.M(wl) returns sensitivity at specified wavelengths.
            %   Returns zeros (or -10 in LogOutput mode) when Mod == 0
            %   (deuteranope).
            arguments
                obj
                wl double = obj.DEFAULT_WL
            end
            val = obj.calculateSensitivity(wl, 'M');
        end

        function val = S(obj, wl)
            % S  Calculate S-cone sensitivity.
            %   val = obj.S(wl) returns sensitivity at specified wavelengths.
            %   Returns zeros (or -10 in LogOutput mode) when Sod == 0
            %   (tritanope).
            arguments
                obj
                wl double = obj.DEFAULT_WL
            end
            val = obj.calculateSensitivity(wl, 'S');
        end

        function peak = getPeak(obj, coneType, options)
            % GETPEAK  Get the normalization peak for a cone type.
            %
            %   peak = obj.getPeak(coneType) returns the peak value used for
            %   normalizing the specified cone type in the current OutputFormat.
            %
            %   peak = obj.getPeak(coneType, OutputFormat=fmt) returns the peak
            %   for the specified output format.
            %
            %   This is useful for debugging, verification, and understanding
            %   the normalization behavior.
            %
            %   INPUTS:
            %       coneType - 'L', 'M', or 'S'
            %
            %   OPTIONAL INPUTS (Name-Value arguments):
            %       OutputFormat - "energy", "quantal", "absorptance", or "absorbance"
            %                      Defaults to obj.OutputFormat
            %
            %   OUTPUTS:
            %       peak - The peak sensitivity value used as the normalization divisor
            %
            %   EXAMPLE:
            %       obs = IndividualCMF();
            %       peak_L = obs.getPeak('L');
            %       peak_M_quantal = obs.getPeak('M', OutputFormat="quantal");
            arguments
                obj
                coneType (1,1) char {mustBeMember(coneType, {'L', 'M', 'S'})}
                options.OutputFormat (1,1) string = obj.OutputFormat
            end
            peak = obj.p_NormalizationCache.getPeak(coneType, options.OutputFormat);
        end

        function [result, wl] = evaluate(obj, wl, options)
            % EVALUATE  Evaluates the model to return data in specific formats.
            %   Calculates sensitivities for the provided wavelengths and formats the output
            %   as arrays, tables, or structures based on the configuration options.
            %
            %   OPTIONAL INPUTS:
            %       wl - Wavelengths in nm. Default: (380:1:780)' (vector)
            %
            %   OPTIONAL INPUTS (Name-Value arguments):
            %       Data - Type of data to return: "LMS", "RGB", "chromaticity" (string) Default: "LMS"
            %       Format - Return structure: "array" (matrix), "table", "struct" (string) Default: "array"
            %
            %   OUTPUTS:
            %       result - The calculated data in the requested format (array)
            %       wl - Wavelengths in nm (vector)
            arguments
                obj
                wl (:,1) double {validators.mustBeWavelengthVector} = (380:1:780)'
                options.Data {mustBeMember(options.Data, ...
                    {'LMS', 'L', 'M', 'S', 'RGB', 'chromaticity'})} = 'LMS'
                options.Format {mustBeMember(options.Format, ...
                    {'array', 'table', 'struct'})} = 'array'
            end

            % Ensure wl is column vector
            wl = wl(:);

            switch options.Data
                case 'LMS', data = obj.LMS(wl); var_names = {'L', 'M', 'S'};
                case 'L', data = obj.L(wl); var_names = {'L'};
                case 'M', data = obj.M(wl); var_names = {'M'};
                case 'S', data = obj.S(wl); var_names = {'S'};
                case 'RGB'
                    data = obj.RGB(wl);
                    var_names = {'R', 'G', 'B'};
                case 'chromaticity'
                    % Force the energy/normalized/non-log basis required
                    % by the projective chromaticity formula. Otherwise
                    % the result silently changes shape with the
                    % observer's OutputFormat.
                    LMS = obj.chromaticityBasisLMS(wl);
                    sum_LMS = sum(LMS, 2); sum_LMS(sum_LMS == 0) = eps;
                    data = LMS ./ sum_LMS; var_names = {'l', 'm', 's'};
            end

            switch lower(options.Format)
                case 'array'
                    % RESULT IS DATA ONLY. WL is returned as 2nd arg.
                    result = data;
                case 'table'
                    if size(data, 2) == 1
                        result = table(wl, data, 'VariableNames', {'Wavelength_nm', var_names{1}});
                    else
                        T = array2table(data, 'VariableNames', var_names);
                        result = [table(wl, 'VariableNames', {'Wavelength_nm'}), T];
                    end
                case 'struct'
                    result.Wavelength_nm = wl;
                    for i = 1:length(var_names)
                        if size(data, 2) == 1, result.(var_names{i}) = data;
                        else, result.(var_names{i}) = data(:,i); end
                    end
            end
        end

        function [RGB, wl] = RGB(obj, wl)
            % RGB  Compute RGB Color Matching Functions.
            %
            %   Transforms LMS cone fundamentals to RGB CMFs using the
            %   configured primary wavelengths. Uses the NormalizationCache
            %   for consistent peak normalization.
            %
            %   Errors with 'IndividualCMF:RGBUndefinedForDichromat' if
            %   any of Lod, Mod, or Sod is zero (the LMS-at-primaries
            %   matrix is singular with one cone absent).
            %
            %   OPTIONAL INPUTS:
            %       wl - Wavelengths in nm. Default: (380:1:780)' (vector)
            %
            %   OUTPUTS:
            %       RGB - Nx3 matrix [R, G, B] containing tristimulus values.
            %       wl  - Nx1 vector of wavelengths corresponding to the data.
            arguments
                obj
                wl (:,1) double {validators.mustBeWavelengthVector} = (380:1:780)'
            end

            % RGB CMFs require inverting a 3x3 LMS-at-primaries matrix.
            % For a dichromat (Lod, Mod, or Sod == 0) the corresponding
            % row is zero and the matrix is singular. Refuse rather than
            % return a NaN-filled result from a failed solve.
            if obj.Lod == 0 || obj.Mod == 0 || obj.Sod == 0
                missing = ["L", "M", "S"];
                missing = missing([obj.Lod, obj.Mod, obj.Sod] == 0);
                error('IndividualCMF:RGBUndefinedForDichromat', ...
                    ['RGB color matching functions are not defined ' ...
                     'for dichromat observers (absent cone(s): %s). ' ...
                     'The LMS-at-primaries matrix is singular when a ' ...
                     'cone optical density is zero.'], ...
                    strjoin(missing, ", "));
            end

            % RGB calculation always uses Energy format, normalized
            % Get peaks for consistent normalization via cache
            peakL = obj.p_NormalizationCache.getPeak('L', "energy");
            peakM = obj.p_NormalizationCache.getPeak('M', "energy");
            peakS = obj.p_NormalizationCache.getPeak('S', "energy");

            % Compute normalized LMS at spectrum wavelengths
            L_vals = obj.computeRawSensitivity(wl, 'L', "energy") ./ peakL;
            M_vals = obj.computeRawSensitivity(wl, 'M', "energy") ./ peakM;
            S_vals = obj.computeRawSensitivity(wl, 'S', "energy") ./ peakS;

            LMS_spectra = [L_vals, M_vals, S_vals]';

            % Compute normalized LMS at primary wavelengths
            L_prim = obj.computeRawSensitivity(obj.Primaries', 'L', "energy") ./ peakL;
            M_prim = obj.computeRawSensitivity(obj.Primaries', 'M', "energy") ./ peakM;
            S_prim = obj.computeRawSensitivity(obj.Primaries', 'S', "energy") ./ peakS;

            % Build transformation matrix and invert. Even with distinct
            % primary wavelengths (enforced by validators.mustBeValidPrimaries),
            % the LMS-at-primaries matrix can be near-singular when two
            % primaries fall in spectral regions where two cones agree
            % closely (e.g. both deep in the M-cone's tail). Surface a
            % clear domain error rather than letting backslash fall back
            % to the least-squares solution and emit a MATLAB warning.
            M_RGB_to_LMS = [L_prim, M_prim, S_prim]';
            % Reasonable primaries (Stiles & Burch, sRGB-like, Adobe RGB,
            % laser) all give rcond ~ 0.1. Three closely-spaced primaries
            % in one cone's response region produce rcond << 1e-6 and an
            % effectively meaningless RGB CMF. Surface a clear domain
            % error rather than letting backslash emit a MATLAB warning
            % and return inflated numbers.
            rc = rcond(M_RGB_to_LMS);
            if rc < 1e-6
                error('IndividualCMF:SingularPrimaries', ...
                    ['Primaries [%.2f, %.2f, %.2f] nm produce a ' ...
                     'near-singular LMS-at-primaries matrix ' ...
                     '(rcond = %.2e). Choose primaries that span the L, M, ' ...
                     'and S response regions more distinctly.'], ...
                    obj.Primaries(1), obj.Primaries(2), obj.Primaries(3), rc);
            end
            RGB_spectra = M_RGB_to_LMS \ LMS_spectra;

            RGB = RGB_spectra';
        end

        function [LMS, wl] = LMS(obj, wl, options)
            % LMS  Returns L, M, and S sensitivity vectors.
            %   Retrieves cone sensitivities. By default, the observer's
            %   persistent OutputFormat / LogOutput / NormalizeOutput
            %   settings determine the output. Pass any of those as Name=Value
            %   to query in a different mode without mutating the observer.
            %
            %   OPTIONAL INPUTS:
            %       wl - Wavelengths in nm. Default: (380:1:780)' (vector)
            %
            %   OPTIONAL INPUTS (Name-Value arguments):
            %       OutputFormat    - "energy" | "quantal" | "absorptance" |
            %                         "absorbance". Default: obj.OutputFormat.
            %       LogOutput       - Log10 the result. Default: obj.LogOutput.
            %       NormalizeOutput - Peak-normalize each cone. Default:
            %                         obj.NormalizeOutput.
            %
            %   OUTPUTS:
            %       LMS - Nx3 matrix [L, M, S] containing sensitivities.
            %             A column is identically zero (or -10 in LogOutput
            %             mode) when the corresponding optical density
            %             (Lod, Mod, or Sod) is zero, i.e. the cone is
            %             absent (gene-deletion dichromacy).
            %       wl  - Nx1 vector of wavelengths corresponding to the data.
            arguments
                obj
                wl (:,1) double {validators.mustBeWavelengthVector} = (380:1:780)'
                options.OutputFormat (1,1) enums.OutputFormat = obj.OutputFormat
                options.LogOutput (1,1) logical = obj.LogOutput
                options.NormalizeOutput (1,1) logical = obj.NormalizeOutput
            end
            fmt = string(options.OutputFormat);
            L = obj.computeSensitivityCore(wl, 'L', fmt, options.NormalizeOutput, options.LogOutput);
            M = obj.computeSensitivityCore(wl, 'M', fmt, options.NormalizeOutput, options.LogOutput);
            S = obj.computeSensitivityCore(wl, 'S', fmt, options.NormalizeOutput, options.LogOutput);
            LMS = [L, M, S];
        end

        function spectrum = getLensDensitySpectrum(obj, wavelengths)
            % GETLENSDENSITYSPECTRUM  Compute lens optical density spectrum.
            %
            %   spectrum = obj.getLensDensitySpectrum(wavelengths) returns the
            %   lens optical density at each wavelength for this observer.
            %   The spectrum is computed using the observer's LensModel template
            %   scaled by the observer's LensDensity property.
            %
            %   The LensDensity property is age-dependent and is recalculated
            %   automatically when the observer's Age changes.
            %
            %   INPUTS:
            %       wavelengths - Wavelengths in nanometers (vector)
            %
            %   OUTPUTS:
            %       spectrum - Lens optical density at each wavelength (vector)
            arguments
                obj
                wavelengths (:,1) double {validators.mustBeWavelengthVector}
            end

            template = obj.p_LensTemplate.computeTemplate(wavelengths, ...
                obj.p_Parameters.Age, FieldSize=obj.p_Parameters.FieldSize);
            spectrum = obj.LensDensity * template;
        end

        function spectrum = getMacularDensitySpectrum(obj, wavelengths)
            % GETMACULARDENSITYSPECTRUM  Compute macular pigment optical density spectrum.
            %
            %   spectrum = obj.getMacularDensitySpectrum(wavelengths) returns
            %   the macular pigment optical density at each wavelength for
            %   this observer. The spectrum is computed using the observer's
            %   macular template scaled by the observer's MacularDensity
            %   property.
            %
            %   The MacularDensity property is field-size dependent and is
            %   recalculated automatically when the observer's FieldSize
            %   changes (unless MacularDensityAlgorithm is "Custom").
            %
            %   INPUTS:
            %       wavelengths - Wavelengths in nanometers (vector)
            %
            %   OUTPUTS:
            %       spectrum - Macular optical density at each wavelength (vector)
            arguments
                obj
                wavelengths (:,1) double {validators.mustBeWavelengthVector}
            end

            template = obj.p_MacularTemplate.computeTemplate(wavelengths);
            spectrum = obj.MacularDensity * template;
        end

        function [XYZ, wl] = XYZ(obj, wl, options)
            % XYZ  Returns CIE 2015 XYZ Color Matching Functions.
            %   Calculates XYZ values by transforming LMS cone fundamentals.
            %   By default, this adheres to CIE 15:2004 recommendations for field size
            %   (using 2-deg for <=4 deg, 10-deg for >4 deg).
            %
            %   Errors with 'IndividualCMF:XYZUndefinedForDichromat' if
            %   any of Lod, Mod, or Sod is zero (the LMS->XYZ transform
            %   is rank-deficient with one cone absent). Pass a custom
            %   TransformationMatrix to override.
            %
            %   Warnings:
            %       - 'IndividualCMF:NonStandardFieldSize' is issued if the field size
            %         is not exactly 2 or 10 degrees (unless a custom matrix is provided).
            %       - 'IndividualCMF:NonStandardObserver' is issued if the observer
            %         parameters deviate from the standard (unless a custom matrix is provided).
            %
            %   INPUTS:
            %       wl - Wavelengths in nm. Default: (360:1:830)' (vector)
            %
            %   OPTIONAL INPUTS (Name-Value arguments):
            %       TransformationMatrix - A custom matrix M to convert (3,3 double)
            %           LMS to XYZ such that [XYZ] = M * [LMS].
            %           Providing this matrix suppresses standard observer warnings.
            %
            %   OUTPUTS:
            %       XYZ - Nx3 matrix
            %       wl  - Nx1 vector of wavelengths

            arguments
                obj
                wl (:,1) double {validators.mustBeWavelengthVector} = (360:1:830)'
                options.TransformationMatrix double {validators.mustBe3x3OrEmpty} = []
            end

            % Check if user is manually overriding the matrix
            hasCustomMatrix = ~isempty(options.TransformationMatrix);

            % CIE XYZ is not defined for dichromat observers: the
            % LMS->XYZ transform is a 3x3 matrix that assumes three
            % independent cone responses. With one cone absent (Lod,
            % Mod, or Sod == 0), the result is a rank-deficient
            % projection with no agreed-upon convention. Refuse rather
            % than silently produce something undefined. A custom
            % TransformationMatrix is accepted on the caller's authority.
            if ~hasCustomMatrix && (obj.Lod == 0 || obj.Mod == 0 || obj.Sod == 0)
                missing = ["L", "M", "S"];
                missing = missing([obj.Lod, obj.Mod, obj.Sod] == 0);
                absent = strjoin(missing, ", ");
                error('IndividualCMF:XYZUndefinedForDichromat', ...
                    ['XYZ is not defined for dichromat observers ' ...
                     '(absent cone(s): %s). The CIE LMS->XYZ ' ...
                     'transform assumes three independent cone ' ...
                     'responses; with a cone optical density of zero ' ...
                     'the projection is rank-deficient. Pass a custom ' ...
                     'TransformationMatrix to override.'], absent);
            end

            % Check for Non-Standard Field Size
            % Only warn if we are relying on the standard matrices (no custom matrix)
            if ~hasCustomMatrix && abs(obj.FieldSize - 2) > 1e-4 && abs(obj.FieldSize - 10) > 1e-4
                warning('IndividualCMF:NonStandardFieldSize', ...
                    ['Field Size is %.1f degrees. CIE 2015 XYZ matrices are strictly defined ', ...
                    'only for 2 and 10 degrees. Applying the closest standard matrix ' ...
                    'per CIE 15:2004 recommendations.'], obj.FieldSize);
            end

            % Check for Non-Standard LMS Parameters (Physiology)
            % Only warn if we are relying on the standard matrices (no custom matrix).
            % If the user provides a matrix, we assume it is optimized for this observer.
            if ~hasCustomMatrix && ~obj.isStandardConfiguration()
                warning('IndividualCMF:NonStandardObserver', ...
                    ['Calculating XYZ for a non-standard observer (Age: %.1f, L-Shift: %.1fnm, M-Shift: %.1fnm). ' ...
                    'The standard XYZ transformation matrix is derived for the CIE Standard Observer ' ...
                    '(Age %d, Standard Genotype). Resulting XYZ values represent "Individual Colorimetric" ' ...
                    'values, not standard CIE cone-fundamental-based tristimulus values.'], ...
                    obj.Age, obj.L_LambdaMaxShift, obj.M_LambdaMaxShift, CIE170.STD_AGE);
            end

            % Force LMS generation to Standard Basis (Energy, Peak-Normalized)
            % This ensures the math works even if obj.OutputFormat is 'quantal'.
            L = obj.computeSensitivityCore(wl, 'L', 'energy', true, false);
            M = obj.computeSensitivityCore(wl, 'M', 'energy', true, false);
            S = obj.computeSensitivityCore(wl, 'S', 'energy', true, false);
            LMS = [L, M, S];

            % Select Transformation Matrix
            if hasCustomMatrix
                % User provided a custom matrix
                M_transform = options.TransformationMatrix;
            else
                % CIE 15:2004 Logic (Step function at 4 degrees)
                if obj.FieldSize <= 4
                    M_transform = CIE170.M_2DEG;
                else
                    M_transform = CIE170.M_10DEG;
                end
            end

            % Apply Transformation. CIE170.M_* is stored in standard
            % color-science form (rows are output channels), so for
            % [N x 3] LMS data we multiply by the transpose.
            XYZ = LMS * M_transform.';
        end

        function lum = Luminance(obj, wl)
            % LUMINANCE  Cone-fundamental-based photopic luminous efficiency V*(lambda).
            %
            %   lum = obj.Luminance(wl) returns photopic luminance at
            %   each wavelength as a linear combination of the L and M
            %   cone sensitivities. The coefficients are the y-bar row
            %   of the CIE 170-2:2015 LMS->XYZ matrix (V*(lambda) IS the
            %   y-bar function of the cone-fundamental-based CMFs):
            %
            %       2-deg : V*(lambda) = 0.68990272*Lbar(lambda) + 0.34832189*Mbar(lambda)
            %       10-deg: V*(lambda) = 0.69283932*Lbar(lambda) + 0.34967567*Mbar(lambda)
            %
            %   These are the "physiologically relevant" coefficients of
            %   Sharpe et al. (2005), adopted by CIE 170-2:2015 as the
            %   cone-fundamental-based photopic luminous efficiency
            %   function. For the standard observer the function peaks
            %   near 1.0 at 555 nm. For an individual observer with
            %   shifted L/M cones, V*(lambda) is that observer's photopic
            %   luminance -- not the CIE standard V*(lambda).
            %
            %   LMS values are taken in energy units with each cone
            %   peak-normalized to 1 (CIE convention); the observer's
            %   current OutputFormat and NormalizeOutput settings are
            %   ignored.
            %
            %   Dichromat behaviour (Lod/Mod/Sod = 0):
            %       Lod = 0  ->  V*(lambda) = b*Mbar(lambda)
            %       Mod = 0  ->  V*(lambda) = a*Lbar(lambda)
            %       Sod = 0  ->  V*(lambda) unchanged (S not in V*)
            %
            %   INPUTS:
            %       wl - Wavelengths in nm (vector). Default: (380:1:780)'.
            %
            %   OUTPUTS:
            %       lum - Photopic luminance V*(lambda) (Nx1 column).
            %
            %   EXAMPLE:
            %       obs = IndividualCMF(StandardObserver=10);
            %       wl = (380:1:780)';
            %       plot(wl, obs.Luminance(wl));
            %
            %   References:
            %       Sharpe, L.T., Stockman, A., Jagla, W. & Jagle, H. (2005).
            %       A luminous efficiency function, V*(lambda), for daylight
            %       adaptation. Journal of Vision, 5(11):3, 948-968.
            %
            %       CIE 170-2:2015. Fundamental chromaticity diagram with
            %       physiological axes - Part 2: Spectral luminous efficiency
            %       functions and chromaticity diagrams. Vienna: CIE.
            %
            %       Stockman, A. (2019). Cone fundamentals and CIE standards.
            %       Current Opinion in Behavioral Sciences, 30, 87-93.
            %       doi:10.1016/j.cobeha.2019.06.005
            arguments
                obj
                wl (:,1) double {validators.mustBeWavelengthVector} = (380:1:780)'
            end

            % Field-size dispatch mirrors XYZ(): the 2-deg matrix is
            % applied below 4 deg, the 10-deg matrix above.
            % Row 2 = y_bar (V*(lambda)) coefficients across L, M, S.
            if obj.FieldSize <= 4
                coefs = CIE170.M_2DEG(2, :);
            else
                coefs = CIE170.M_10DEG(2, :);
            end

            LMS = obj.chromaticityBasisLMS(wl);
            lum = LMS * coefs(:);
        end

        function mb = MacLeodBoynton(obj, wl)
            % MACLEODBOYNTON  Cone-opponent MacLeod-Boynton chromaticity (l, s).
            %
            %   mb = obj.MacLeodBoynton(wl) returns the MacLeod-Boynton
            %   chromaticity coordinates at each wavelength:
            %
            %       l_MB(lambda) = a*Lbar(lambda) / [a*Lbar(lambda) + b*Mbar(lambda)]
            %       s_MB(lambda) = Sbar(lambda) / [a*Lbar(lambda) + b*Mbar(lambda)]
            %
            %   where (a, b) are the L and M coefficients of V*(lambda) --
            %   the y-bar row of the CIE 170-2:2015 LMS->XYZ matrix --
            %   so the denominator equals V*(lambda) (photopic luminance).
            %   Field-size dispatch mirrors XYZ(): 2-deg matrix below
            %   4 deg, 10-deg matrix otherwise.
            %
            %   LMS values are taken in energy units with each cone
            %   peak-normalized to 1; the observer's current
            %   OutputFormat is ignored.
            %
            %   By construction l_MB in [0, 1]. The S-cone coordinate
            %   s_MB is NOT bounded above by 1 -- it commonly exceeds
            %   1 near the S-cone peak because the convention does not
            %   renormalize S.
            %
            %   Dichromat behaviour:
            %       Lod = 0  ->  l_MB = 0
            %       Mod = 0  ->  l_MB = 1
            %       Sod = 0  ->  s_MB = 0
            %
            %   INPUTS:
            %       wl - Wavelengths in nm (vector). Default: (380:1:780)'.
            %
            %   OUTPUTS:
            %       mb - Nx2 matrix with columns [l_MB, s_MB].
            %
            %   EXAMPLE:
            %       obs = IndividualCMF();
            %       mb = obs.MacLeodBoynton((380:1:780)');
            %       plot(mb(:,1), mb(:,2));
            %
            %   References:
            %       MacLeod, D.I.A. & Boynton, R.M. (1979). Chromaticity
            %       diagram showing cone excitation by stimuli of equal
            %       luminance. Journal of the Optical Society of America,
            %       69(8), 1183-1186.
            %
            %       Smith, V.C. & Pokorny, J. (1996). The design and use
            %       of a cone chromaticity space: A tutorial. Color
            %       Research & Application, 21(5), 375-383.
            %
            %       Stockman, A. (2019). Cone fundamentals and CIE
            %       standards (Fig. 3 Panel D). Current Opinion in
            %       Behavioral Sciences, 30, 87-93.
            arguments
                obj
                wl (:,1) double {validators.mustBeWavelengthVector} = (380:1:780)'
            end

            % Row 2 = y_bar coefficients; column 1 = L contribution,
            % column 2 = M contribution.
            if obj.FieldSize <= 4
                kL = CIE170.M_2DEG(2, 1);
                kM = CIE170.M_2DEG(2, 2);
            else
                kL = CIE170.M_10DEG(2, 1);
                kM = CIE170.M_10DEG(2, 2);
            end

            LMS = obj.chromaticityBasisLMS(wl);
            Lw = kL * LMS(:,1);
            Mw = kM * LMS(:,2);
            V  = Lw + Mw;
            safeV = V;
            % Outside the photopic range V can hit zero, which would
            % produce 0/0 and NaN-propagate; mark explicitly.
            safeV(safeV == 0) = NaN;
            mb = [Lw ./ safeV, LMS(:,3) ./ safeV];
        end

        function lm = lmChromaticity(obj, wl)
            % LMCHROMATICITY  LMS-sum chromaticity coordinates (l, m).
            %
            %   lm = obj.lmChromaticity(wl) returns the projective
            %   chromaticity coordinates obtained by normalizing the L
            %   and M cone sensitivities by L + M + S:
            %
            %       l(lambda) = Lbar(lambda) / [Lbar(lambda) + Mbar(lambda) + Sbar(lambda)]
            %       m(lambda) = Mbar(lambda) / [Lbar(lambda) + Mbar(lambda) + Sbar(lambda)]
            %
            %   The third coordinate s = Sbar/sum satisfies l + m + s = 1
            %   and so is redundant.
            %
            %   LMS values are taken in energy units with each cone
            %   peak-normalized to 1 (CIE convention); the observer's
            %   current OutputFormat is ignored.
            %
            %   Dichromat behaviour:
            %       Lod = 0  ->  l = 0
            %       Mod = 0  ->  m = 0
            %       Sod = 0  ->  l + m = 1 (S contribution removed)
            %
            %   INPUTS:
            %       wl - Wavelengths in nm (vector). Default: (380:1:780)'.
            %
            %   OUTPUTS:
            %       lm - Nx2 matrix with columns [l, m].
            %
            %   EXAMPLE:
            %       obs = IndividualCMF();
            %       lm = obs.lmChromaticity((380:1:780)');
            %       plot(lm(:,1), lm(:,2));
            %
            %   Reference:
            %       Stockman, A. (2019). Cone fundamentals and CIE
            %       standards (Fig. 3 Panel A). Current Opinion in
            %       Behavioral Sciences, 30, 87-93.
            arguments
                obj
                wl (:,1) double {validators.mustBeWavelengthVector} = (380:1:780)'
            end

            LMS = obj.chromaticityBasisLMS(wl);
            total = sum(LMS, 2);
            safe = total;
            safe(safe == 0) = NaN;
            lm = [LMS(:,1) ./ safe, LMS(:,2) ./ safe];
        end

        function xy = xyChromaticity(obj, wl, options)
            % XYCHROMATICITY  CIE xy chromaticity coordinates.
            %
            %   xy = obj.xyChromaticity(wl) returns CIE chromaticity
            %   coordinates obtained by projective normalization of the
            %   observer's XYZ tristimulus values:
            %
            %       x(lambda) = X(lambda) / [X(lambda) + Y(lambda) + Z(lambda)]
            %       y(lambda) = Y(lambda) / [X(lambda) + Y(lambda) + Z(lambda)]
            %
            %   Inherits XYZ()'s dichromat behaviour: errors with
            %   IndividualCMF:XYZUndefinedForDichromat when any of
            %   Lod, Mod, or Sod is zero. Pass a TransformationMatrix
            %   Name-Value argument to override (forwarded to XYZ).
            %
            %   INPUTS:
            %       wl - Wavelengths in nm (vector). Default: (360:1:830)'.
            %
            %   OPTIONAL INPUTS (Name-Value arguments):
            %       TransformationMatrix - Forwarded to XYZ (3x3 double).
            %
            %   OUTPUTS:
            %       xy - Nx2 matrix with columns [x, y].
            %
            %   EXAMPLE:
            %       obs = IndividualCMF(StandardObserver=2);
            %       xy = obs.xyChromaticity((380:1:780)');
            %       plot(xy(:,1), xy(:,2));
            %
            %   Reference:
            %       CIE 170-2:2015. Fundamental chromaticity diagram with
            %       physiological axes - Part 2: Spectral luminous
            %       efficiency functions and chromaticity diagrams.
            %       Vienna: CIE.
            arguments
                obj
                wl (:,1) double {validators.mustBeWavelengthVector} = (360:1:830)'
                options.TransformationMatrix double {validators.mustBe3x3OrEmpty} = []
            end

            if isempty(options.TransformationMatrix)
                XYZ = obj.XYZ(wl);
            else
                XYZ = obj.XYZ(wl, TransformationMatrix=options.TransformationMatrix);
            end
            total = sum(XYZ, 2);
            safe = total;
            safe(safe == 0) = NaN;
            xy = [XYZ(:,1) ./ safe, XYZ(:,2) ./ safe];
        end
    end

    % Visualization shortcuts
    % Thin wrappers that delegate to CMFPlotter. All plotting methods:
    %   - Return [p, ax] for post-creation customization
    %   - Support lazy instantiation (auto-create CMFPlotter if not provided)
    %   - Apply consistent default styling
    %
    % For custom line styling, modify returned handles:
    %   [p, ax] = obs.plotLMS();
    %   set(p, 'LineWidth', 2);
    %   p(1).Color = 'magenta';
    methods
        function varargout = plot(obj, options)
            % PLOT  Unified plotting method for observer visualization.
            %   Flexible method that can plot various representations of the observer.
            %
            %   obj.plot() plots without returning handles (no ans pollution).
            %   p = obj.plot() returns line handle(s) for customization.
            %   Access axes via p(1).Parent if needed.
            %
            %   OPTIONAL INPUTS (Name-Value arguments):
            %       Data - Type of data to plot: (string)
            %                         "LMS" (default) - Cone fundamentals
            %                         "RGB"           - RGB Color Matching Functions
            %                         "chromaticity"  - rg-chromaticity diagram
            %                         "absorbance"    - Photopigment absorbance
            %                         "absorptance"   - Relative retinal absorptance (see OutputFormat docs)
            %       Title - Custom title. Default: auto-generated based on Data (string)
            %       Wavelength - Wavelengths in nm. Default: (360:1:830)' (vector)
            %       Log - For absorbance: plot log scale. Default: false (logical)
            %       Plotter - Existing plotter instance (lazy instantiation) (CMFPlotter)
            %
            %   Examples:
            %       obs.plot()                              % LMS cone fundamentals
            %       obs.plot(Data="RGB")                    % RGB CMFs
            %       obs.plot(Data="absorbance", Log=true)   % Log absorbance
            %       [p, ax] = obs.plot();                   % Get handles for customization
            %       set(p, 'LineWidth', 2);                 % Customize lines
            arguments
                obj
                options.Data (1,1) string {mustBeMember(options.Data, ...
                    ["LMS", "RGB", "chromaticity", "absorbance", "absorptance"])} = "LMS"
                options.Title (1,1) string = ""
                options.Wavelength (:,1) double = obj.DEFAULT_WL
                options.Log (1,1) logical = false
                options.Compare = []
                options.Parent = []
            end

            wl = options.Wavelength;
            titleStr = options.Title;

            if ~isempty(options.Compare)
                if titleStr == ""
                    switch options.Data
                        case "LMS", titleStr = "LMS Comparison";
                        case "RGB", titleStr = "RGB Comparison";
                        otherwise,  titleStr = "Comparison";
                    end
                end
                switch options.Data
                    case "LMS"
                        [p, ax] = obj.compareTo(options.Compare, ...
                            Wavelength=wl, Title=titleStr, Parent=options.Parent);
                    case "RGB"
                        ax = obj.resolvePlotAxes(options.Parent);
                        RGBref  = obj.RGB(wl);
                        RGBcomp = options.Compare.RGB(wl);
                        wasHeld = ishold(ax);
                        cla(ax);

                        ax.XLimMode = 'auto'; ax.YLimMode = 'auto';
                        ax.DataAspectRatioMode = 'auto'; ax.PlotBoxAspectRatioMode = 'auto';
                        hold(ax, 'on');
                        p = gobjects(6, 1);
                        p(1) = plot(ax, wl, RGBref(:,1),  '-',  'Color', [0.8 0 0], 'LineWidth', 2, 'DisplayName', 'R');
                        p(2) = plot(ax, wl, RGBref(:,2),  '-',  'Color', [0 0.6 0], 'LineWidth', 2, 'DisplayName', 'G');
                        p(3) = plot(ax, wl, RGBref(:,3),  '-',  'Color', [0 0 0.8], 'LineWidth', 2, 'DisplayName', 'B');
                        p(4) = plot(ax, wl, RGBcomp(:,1), '--', 'Color', [0.8 0 0], 'LineWidth', 2, 'DisplayName', "R'");
                        p(5) = plot(ax, wl, RGBcomp(:,2), '--', 'Color', [0 0.6 0], 'LineWidth', 2, 'DisplayName', "G'");
                        p(6) = plot(ax, wl, RGBcomp(:,3), '--', 'Color', [0 0 0.8], 'LineWidth', 2, 'DisplayName', "B'");
                        if ~wasHeld, hold(ax, 'off'); end
                        obj.finalizeLinePlot(ax, p, titleStr, "Tristimulus Value");
                    otherwise
                        error('IndividualCMF:UnsupportedComparison', ...
                            'Comparison not supported for Data="%s". Use "LMS" or "RGB".', options.Data);
                end
            else
                switch options.Data
                    case "LMS"
                        [p, ax] = obj.plotLMS(Wavelength=wl, Title=titleStr, ...
                            Parent=options.Parent);
                    case "RGB"
                        [p, ax] = obj.plotRGBCMFs(Wavelength=wl, Title=titleStr, ...
                            Parent=options.Parent);
                    case "chromaticity"
                        [p, ax] = obj.plotChromaticity(Wavelength=wl, Title=titleStr, ...
                            Parent=options.Parent);
                    case "absorbance"
                        [p, ax] = obj.plotAbsorbance(Wavelength=wl, Title=titleStr, ...
                            Log=options.Log, Parent=options.Parent);
                    case "absorptance"
                        [p, ax] = obj.plotAbsorptance(Wavelength=wl, Title=titleStr, ...
                            Log=options.Log, Parent=options.Parent);
                end
            end

            if nargout > 0, varargout{1} = p; end
            if nargout > 1, varargout{2} = ax; end
        end

        function varargout = plotChromaticity(obj, options)
            % PLOTCHROMATICITY  Plot the spectral locus on an lm-chromaticity diagram.
            %
            %   obj.plotChromaticity() draws into gca.
            %   p = obj.plotChromaticity() returns the line handle for the locus.
            %
            %   OPTIONAL INPUTS (Name-Value arguments):
            %       Title - Custom title. Default: "Chromaticity Diagram" (string)
            %       Wavelength - Wavelengths in nm. Default: (360:1:830)' (vector)
            %       Parent - Target axes. Default: gca (axes)
            arguments
                obj
                options.Title (1,1) string = "Chromaticity Diagram"
                options.Wavelength (:,1) double = obj.DEFAULT_WL
                options.Parent = []
            end

            ax = obj.resolvePlotAxes(options.Parent);
            wl = options.Wavelength;
            chrom = obj.lmChromaticity(wl);

            cla(ax);
            ax.XLimMode = 'auto'; ax.YLimMode = 'auto';
            ax.DataAspectRatioMode = 'auto'; ax.PlotBoxAspectRatioMode = 'auto';
            p = plot(ax, chrom(:,1), chrom(:,2), 'k-', 'LineWidth', 2, ...
                'DisplayName', 'Spectral locus');

            xlabel(ax, 'l');
            ylabel(ax, 'm');
            title(ax, options.Title);
            grid(ax, 'on');
            axis(ax, 'equal');

            if nargout > 0, varargout{1} = p; end
            if nargout > 1, varargout{2} = ax; end
        end

        function varargout = plotLMS(obj, options)
            % PLOTLMS  Plot L, M, and S cone fundamentals into the current axes.
            %
            %   obj.plotLMS() draws into gca and returns nothing.
            %   p = obj.plotLMS() returns a 3x1 array of line handles [L; M; S].
            %   Access axes via p(1).Parent if needed. Plot directly into a
            %   specific axes by passing Parent=ax. Absent cones (Lod/Mod/Sod
            %   == 0; gene-deletion dichromacy) are omitted from the plot but
            %   keep gobjects placeholders in the returned handle array.
            %
            %   OPTIONAL INPUTS (Name-Value arguments):
            %       Title - Custom title. Default: "LMS Cone Fundamentals" (string)
            %       Wavelength - Wavelengths in nm. Default: (360:1:830)' (vector)
            %       Log - Plot log10 sensitivity. Default: false (logical)
            %       Cones - Subset of cones to plot. Default: ["L" "M" "S"] (string array)
            %       Parent - Target axes. Default: gca (axes)
            arguments
                obj
                options.Title (1,1) string = "LMS Cone Fundamentals"
                options.Wavelength (:,1) double = obj.DEFAULT_WL
                options.Log (1,1) logical = false
                options.Cones (1,:) string {mustBeMember(options.Cones, ["L", "M", "S"])} = ["L", "M", "S"]
                options.Parent = []
            end

            ax = obj.resolvePlotAxes(options.Parent);
            wl = options.Wavelength;
            LMS = obj.LMS(wl, LogOutput=options.Log);

            wasHeld = ishold(ax);
            cla(ax);

            ax.XLimMode = 'auto'; ax.YLimMode = 'auto';
            ax.DataAspectRatioMode = 'auto'; ax.PlotBoxAspectRatioMode = 'auto';
            hold(ax, 'on');
            p = gobjects(3, 1);
            if obj.Lod > 0 && any(options.Cones == "L")
                p(1) = plot(ax, wl, LMS(:,1), '-', 'Color', [0.8 0 0], ...
                    'LineWidth', 2, 'DisplayName', 'L');
            end
            if obj.Mod > 0 && any(options.Cones == "M")
                p(2) = plot(ax, wl, LMS(:,2), '-', 'Color', [0 0.6 0], ...
                    'LineWidth', 2, 'DisplayName', 'M');
            end
            if obj.Sod > 0 && any(options.Cones == "S")
                p(3) = plot(ax, wl, LMS(:,3), '-', 'Color', [0 0 0.8], ...
                    'LineWidth', 2, 'DisplayName', 'S');
            end
            if ~wasHeld, hold(ax, 'off'); end

            if options.Log
                yLab = "Log_{10} Sensitivity";
            else
                yLab = "Sensitivity";
            end
            obj.finalizeLinePlot(ax, p, options.Title, yLab);

            if nargout > 0, varargout{1} = p; end
            if nargout > 1, varargout{2} = ax; end
        end

        function varargout = plotXYZ(obj, options)
            % PLOTXYZ  Plot CIE XYZ color matching functions into the current axes.
            %
            %   obj.plotXYZ() draws into gca.
            %   p = obj.plotXYZ() returns a 3x1 array of line handles [X; Y; Z].
            %
            %   For dichromat observers (any of Lod/Mod/Sod == 0), the
            %   underlying XYZ method raises IndividualCMF:XYZUndefinedForDichromat;
            %   pass TransformationMatrix to override on the caller's authority.
            %
            %   OPTIONAL INPUTS (Name-Value arguments):
            %       Title - Custom title. Default: "CIE XYZ CMFs" (string)
            %       Wavelength - Wavelengths in nm. Default: (360:1:830)' (vector)
            %       Channels - Subset of channels to plot. Default: ["X" "Y" "Z"] (string array)
            %       TransformationMatrix - 3x3 LMS->XYZ matrix override (double)
            %       Parent - Target axes. Default: gca (axes)
            arguments
                obj
                options.Title (1,1) string = "CIE XYZ CMFs"
                options.Wavelength (:,1) double = obj.DEFAULT_WL
                options.Channels (1,:) string {mustBeMember(options.Channels, ["X", "Y", "Z"])} = ["X", "Y", "Z"]
                options.TransformationMatrix double {validators.mustBe3x3OrEmpty} = []
                options.Parent = []
            end

            ax = obj.resolvePlotAxes(options.Parent);
            wl = options.Wavelength;
            XYZ = obj.XYZ(wl, TransformationMatrix=options.TransformationMatrix);

            wasHeld = ishold(ax);
            cla(ax);

            ax.XLimMode = 'auto'; ax.YLimMode = 'auto';
            ax.DataAspectRatioMode = 'auto'; ax.PlotBoxAspectRatioMode = 'auto';
            hold(ax, 'on');
            p = gobjects(3, 1);
            if any(options.Channels == "X")
                p(1) = plot(ax, wl, XYZ(:,1), '-', 'Color', [0.8 0 0], ...
                    'LineWidth', 2, 'DisplayName', 'X');
            end
            if any(options.Channels == "Y")
                p(2) = plot(ax, wl, XYZ(:,2), '-', 'Color', [0 0.6 0], ...
                    'LineWidth', 2, 'DisplayName', 'Y');
            end
            if any(options.Channels == "Z")
                p(3) = plot(ax, wl, XYZ(:,3), '-', 'Color', [0 0 0.8], ...
                    'LineWidth', 2, 'DisplayName', 'Z');
            end
            if ~wasHeld, hold(ax, 'off'); end

            obj.finalizeLinePlot(ax, p, options.Title, "Tristimulus Value");

            if nargout > 0, varargout{1} = p; end
            if nargout > 1, varargout{2} = ax; end
        end

        function varargout = plotRGBCMFs(obj, options)
            % PLOTRGBCMFS  Plot RGB color matching functions into the current axes.
            %
            %   obj.plotRGBCMFs() draws into gca.
            %   p = obj.plotRGBCMFs() returns a 3x1 array of line handles [R; G; B].
            %
            %   OPTIONAL INPUTS (Name-Value arguments):
            %       Title - Custom title. Default: "RGB CMFs" (string)
            %       Wavelength - Wavelengths in nm. Default: (360:1:830)' (vector)
            %       Parent - Target axes. Default: gca (axes)
            arguments
                obj
                options.Title (1,1) string = "RGB CMFs"
                options.Wavelength (:,1) double = obj.DEFAULT_WL
                options.Parent = []
            end

            ax = obj.resolvePlotAxes(options.Parent);
            wl = options.Wavelength;
            RGB = obj.RGB(wl);

            wasHeld = ishold(ax);
            cla(ax);

            ax.XLimMode = 'auto'; ax.YLimMode = 'auto';
            ax.DataAspectRatioMode = 'auto'; ax.PlotBoxAspectRatioMode = 'auto';
            hold(ax, 'on');
            p = gobjects(3, 1);
            p(1) = plot(ax, wl, RGB(:,1), '-', 'Color', [0.8 0 0], ...
                'LineWidth', 2, 'DisplayName', 'R');
            p(2) = plot(ax, wl, RGB(:,2), '-', 'Color', [0 0.6 0], ...
                'LineWidth', 2, 'DisplayName', 'G');
            p(3) = plot(ax, wl, RGB(:,3), '-', 'Color', [0 0 0.8], ...
                'LineWidth', 2, 'DisplayName', 'B');
            plot(ax, wl, zeros(size(wl)), 'k--', 'LineWidth', 0.5, ...
                'HandleVisibility', 'off');
            if ~wasHeld, hold(ax, 'off'); end

            obj.finalizeLinePlot(ax, p, options.Title, "Tristimulus Value");

            if nargout > 0, varargout{1} = p; end
            if nargout > 1, varargout{2} = ax; end
        end

        function varargout = plotAbsorbance(obj, options)
            % PLOTABSORBANCE  Plot L, M, S photopigment absorbance spectra into the current axes.
            %
            %   obj.plotAbsorbance() draws into gca.
            %   p = obj.plotAbsorbance() returns 3x1 line handles [L; M; S].
            %
            %   OPTIONAL INPUTS (Name-Value arguments):
            %       Title - Custom title. Default: "Photopigment Absorbance" (string)
            %       Wavelength - Wavelengths in nm. Default: (360:1:830)' (vector)
            %       Log - Plot log10 absorbance. Default: false (logical)
            %       Parent - Target axes. Default: gca (axes)
            arguments
                obj
                options.Title (1,1) string = "Photopigment Absorbance"
                options.Wavelength (:,1) double = obj.DEFAULT_WL
                options.Log (1,1) logical = false
                options.Parent = []
            end

            ax = obj.resolvePlotAxes(options.Parent);
            wl = options.Wavelength;
            A = obj.LMS(wl, OutputFormat="absorbance", LogOutput=options.Log);

            wasHeld = ishold(ax);
            cla(ax);

            ax.XLimMode = 'auto'; ax.YLimMode = 'auto';
            ax.DataAspectRatioMode = 'auto'; ax.PlotBoxAspectRatioMode = 'auto';
            hold(ax, 'on');
            p = gobjects(3, 1);
            p(1) = plot(ax, wl, A(:,1), '-', 'Color', [0.8 0 0], ...
                'LineWidth', 2, 'DisplayName', 'L');
            p(2) = plot(ax, wl, A(:,2), '-', 'Color', [0 0.6 0], ...
                'LineWidth', 2, 'DisplayName', 'M');
            p(3) = plot(ax, wl, A(:,3), '-', 'Color', [0 0 0.8], ...
                'LineWidth', 2, 'DisplayName', 'S');
            if ~wasHeld, hold(ax, 'off'); end

            if options.Log
                yLab = "Log_{10} absorbance";
            else
                yLab = "Absorbance";
            end
            obj.finalizeLinePlot(ax, p, options.Title, yLab);

            if nargout > 0, varargout{1} = p; end
            if nargout > 1, varargout{2} = ax; end
        end

        function varargout = plotAbsorptance(obj, options)
            % PLOTABSORPTANCE  Plot L, M, S relative retinal absorptance into the current axes.
            %
            %   obj.plotAbsorptance() draws into gca.
            %   p = obj.plotAbsorptance() returns 3x1 line handles [L; M; S].
            %
            %   Plots the relative retinal absorptance produced by
            %   OutputFormat="absorptance": (1-10^(-OD*A)) / (1-10^(-OD)).
            %
            %   OPTIONAL INPUTS (Name-Value arguments):
            %       Title - Custom title. Default: "Retinal Absorptance" (string)
            %       Wavelength - Wavelengths in nm. Default: (360:1:830)' (vector)
            %       Log - Plot log10 absorptance. Default: false (logical)
            %       Parent - Target axes. Default: gca (axes)
            arguments
                obj
                options.Title (1,1) string = "Retinal Absorptance"
                options.Wavelength (:,1) double = obj.DEFAULT_WL
                options.Log (1,1) logical = false
                options.Parent = []
            end

            ax = obj.resolvePlotAxes(options.Parent);
            wl = options.Wavelength;
            A = obj.LMS(wl, OutputFormat="absorptance", LogOutput=options.Log);

            wasHeld = ishold(ax);
            cla(ax);

            ax.XLimMode = 'auto'; ax.YLimMode = 'auto';
            ax.DataAspectRatioMode = 'auto'; ax.PlotBoxAspectRatioMode = 'auto';
            hold(ax, 'on');
            p = gobjects(3, 1);
            if obj.Lod > 0
                p(1) = plot(ax, wl, A(:,1), '-', 'Color', [0.8 0 0], ...
                    'LineWidth', 2, 'DisplayName', 'L');
            end
            if obj.Mod > 0
                p(2) = plot(ax, wl, A(:,2), '-', 'Color', [0 0.6 0], ...
                    'LineWidth', 2, 'DisplayName', 'M');
            end
            if obj.Sod > 0
                p(3) = plot(ax, wl, A(:,3), '-', 'Color', [0 0 0.8], ...
                    'LineWidth', 2, 'DisplayName', 'S');
            end
            if ~wasHeld, hold(ax, 'off'); end

            if options.Log
                yLab = "Log_{10} absorptance";
            else
                yLab = "Absorptance";
            end
            obj.finalizeLinePlot(ax, p, options.Title, yLab);

            if nargout > 0, varargout{1} = p; end
            if nargout > 1, varargout{2} = ax; end
        end

        function varargout = plotQuantalEnergy(obj, options)
            % PLOTQUANTALENERGY  Overlay quantal vs energy sensitivities in the current axes.
            %
            %   obj.plotQuantalEnergy() draws into gca.
            %   p = obj.plotQuantalEnergy() returns a 6x1 array of line handles
            %       [Lq; Mq; Sq; Le; Me; Se]. Quantal traces are dashed.
            %
            %   OPTIONAL INPUTS (Name-Value arguments):
            %       Title - Custom title. Default: "Quantal vs Energy" (string)
            %       Wavelength - Wavelengths in nm. Default: (360:1:830)' (vector)
            %       Parent - Target axes. Default: gca (axes)
            arguments
                obj
                options.Title (1,1) string = "Quantal vs Energy"
                options.Wavelength (:,1) double = obj.DEFAULT_WL
                options.Parent = []
            end

            ax = obj.resolvePlotAxes(options.Parent);
            wl = options.Wavelength;
            Q = obj.LMS(wl, OutputFormat="quantal");
            E = obj.LMS(wl, OutputFormat="energy");

            wasHeld = ishold(ax);
            cla(ax);

            ax.XLimMode = 'auto'; ax.YLimMode = 'auto';
            ax.DataAspectRatioMode = 'auto'; ax.PlotBoxAspectRatioMode = 'auto';
            hold(ax, 'on');
            p = gobjects(6, 1);
            p(1) = plot(ax, wl, Q(:,1), '--', 'Color', [0.8 0 0], 'LineWidth', 2, 'DisplayName', 'L (quantal)');
            p(2) = plot(ax, wl, Q(:,2), '--', 'Color', [0 0.6 0], 'LineWidth', 2, 'DisplayName', 'M (quantal)');
            p(3) = plot(ax, wl, Q(:,3), '--', 'Color', [0 0 0.8], 'LineWidth', 2, 'DisplayName', 'S (quantal)');
            p(4) = plot(ax, wl, E(:,1), '-',  'Color', [0.8 0 0], 'LineWidth', 2, 'DisplayName', 'L (energy)');
            p(5) = plot(ax, wl, E(:,2), '-',  'Color', [0 0.6 0], 'LineWidth', 2, 'DisplayName', 'M (energy)');
            p(6) = plot(ax, wl, E(:,3), '-',  'Color', [0 0 0.8], 'LineWidth', 2, 'DisplayName', 'S (energy)');
            if ~wasHeld, hold(ax, 'off'); end

            obj.finalizeLinePlot(ax, p, options.Title, "Sensitivity");

            if nargout > 0, varargout{1} = p; end
            if nargout > 1, varargout{2} = ax; end
        end

        function varargout = compareTo(obj, otherObs, options)
            % COMPARETO  Overlay this observer's LMS against another's in the current axes.
            %
            %   obj.compareTo(otherObs) draws into gca with ref solid / comp dashed.
            %   p = obj.compareTo(otherObs) returns a 6x1 array of line handles
            %       [Lref; Mref; Sref; Lcomp; Mcomp; Scomp].
            %
            %   OPTIONAL INPUTS (Name-Value arguments):
            %       Title - Custom title. Default: "Observer Comparison" (string)
            %       Wavelength - Wavelengths in nm. Default: (360:1:830)' (vector)
            %       Parent - Target axes. Default: gca (axes)
            arguments
                obj
                otherObs (1,1) IndividualCMF
                options.Title (1,1) string = "Observer Comparison"
                options.Wavelength (:,1) double = obj.DEFAULT_WL
                options.Parent = []
            end

            ax = obj.resolvePlotAxes(options.Parent);
            wl = options.Wavelength;
            LMSref  = obj.LMS(wl);
            LMScomp = otherObs.LMS(wl);

            wasHeld = ishold(ax);
            cla(ax);

            ax.XLimMode = 'auto'; ax.YLimMode = 'auto';
            ax.DataAspectRatioMode = 'auto'; ax.PlotBoxAspectRatioMode = 'auto';
            hold(ax, 'on');
            p = gobjects(6, 1);
            p(1) = plot(ax, wl, LMSref(:,1), '-', 'Color', [0.8 0 0], 'LineWidth', 2, 'DisplayName', 'L');
            p(2) = plot(ax, wl, LMSref(:,2), '-', 'Color', [0 0.6 0], 'LineWidth', 2, 'DisplayName', 'M');
            p(3) = plot(ax, wl, LMSref(:,3), '-', 'Color', [0 0 0.8], 'LineWidth', 2, 'DisplayName', 'S');
            p(4) = plot(ax, wl, LMScomp(:,1), '--', 'Color', [0.8 0 0], 'LineWidth', 2, 'DisplayName', "L'");
            p(5) = plot(ax, wl, LMScomp(:,2), '--', 'Color', [0 0.6 0], 'LineWidth', 2, 'DisplayName', "M'");
            p(6) = plot(ax, wl, LMScomp(:,3), '--', 'Color', [0 0 0.8], 'LineWidth', 2, 'DisplayName', "S'");
            if ~wasHeld, hold(ax, 'off'); end

            obj.finalizeLinePlot(ax, p, options.Title, "Sensitivity");

            if nargout > 0, varargout{1} = p; end
            if nargout > 1, varargout{2} = ax; end
        end

        function varargout = plotLens(obj, options)
            % PLOTLENS  Plot lens optical density into the current axes (optional comparison).
            %
            %   obj.plotLens() draws into gca.
            %   p = obj.plotLens(Compare=other) overlays another observer's lens density.
            %
            %   OPTIONAL INPUTS (Name-Value arguments):
            %       Compare - Comparison observer. Default: [] (IndividualCMF)
            %       Title - Custom title (string)
            %       Wavelength - Wavelengths in nm. Default: (360:1:830)' (vector)
            %       Parent - Target axes. Default: gca (axes)
            arguments
                obj
                options.Compare = []
                options.Title (1,1) string = ""
                options.Wavelength (:,1) double = obj.DEFAULT_WL
                options.Parent = []
            end

            ax = obj.resolvePlotAxes(options.Parent);
            wl = options.Wavelength;
            lens = obj.getLensDensitySpectrum(wl);

            wasHeld = ishold(ax);
            cla(ax);

            ax.XLimMode = 'auto'; ax.YLimMode = 'auto';
            ax.DataAspectRatioMode = 'auto'; ax.PlotBoxAspectRatioMode = 'auto';
            hold(ax, 'on');
            if isempty(options.Compare)
                if options.Title == "", options.Title = "Lens Density"; end
                p = plot(ax, wl, lens, '-', 'Color', [0 0 0], ...
                    'LineWidth', 2, 'DisplayName', 'Lens');
            else
                if ~isa(options.Compare, 'IndividualCMF')
                    error('IndividualCMF:InvalidInput', ...
                        'Comparison object must be an IndividualCMF instance.');
                end
                if options.Title == "", options.Title = "Lens Density Comparison"; end
                lensComp = options.Compare.getLensDensitySpectrum(wl);
                p = gobjects(2, 1);
                p(1) = plot(ax, wl, lens, '-', 'Color', [0 0 0.8], ...
                    'LineWidth', 2, 'DisplayName', 'Reference');
                p(2) = plot(ax, wl, lensComp, '--', 'Color', [0.8 0 0], ...
                    'LineWidth', 2, 'DisplayName', 'Comparison');
            end
            if ~wasHeld, hold(ax, 'off'); end

            obj.finalizeLinePlot(ax, p, options.Title, "Optical Density");

            if nargout > 0, varargout{1} = p; end
            if nargout > 1, varargout{2} = ax; end
        end

        function varargout = plotMacular(obj, options)
            % PLOTMACULAR  Plot macular pigment density into the current axes (optional comparison).
            %
            %   obj.plotMacular() draws into gca.
            %   p = obj.plotMacular(Compare=other) overlays another observer's macular density.
            %
            %   The plotted curve is the standard macular template
            %   rescaled so its peak approximates obj.MacularDensity.
            %
            %   OPTIONAL INPUTS (Name-Value arguments):
            %       Compare - Comparison observer. Default: [] (IndividualCMF)
            %       Title - Custom title (string)
            %       Wavelength - Wavelengths in nm. Default: (360:1:830)' (vector)
            %       Parent - Target axes. Default: gca (axes)
            arguments
                obj
                options.Compare = []
                options.Title (1,1) string = ""
                options.Wavelength (:,1) double = obj.DEFAULT_WL
                options.Parent = []
            end

            ax = obj.resolvePlotAxes(options.Parent);
            wl = options.Wavelength;
            % macularTemplate peaks at CIE170.STD_2DEG_MACULAR_DENSITY
            % (~0.350 OD); rescale to the observer's MacularDensity so the
            % plotted curve peaks at obs.MacularDensity, not at
            % 0.35 * obs.MacularDensity. Matches CMFPlotter.plotMacular
            % and the manual rescale in Example12.
            macTemplate = PreReceptoralFilter.macularTemplate(wl);
            macScale = obj.MacularDensity / CIE170.STD_2DEG_MACULAR_DENSITY;
            mac = macTemplate * macScale;

            wasHeld = ishold(ax);
            cla(ax);

            ax.XLimMode = 'auto'; ax.YLimMode = 'auto';
            ax.DataAspectRatioMode = 'auto'; ax.PlotBoxAspectRatioMode = 'auto';
            hold(ax, 'on');
            if isempty(options.Compare)
                if options.Title == "", options.Title = "Macular Pigment Density"; end
                p = plot(ax, wl, mac, '-', 'Color', [0 0 0], ...
                    'LineWidth', 2, 'DisplayName', 'Macular');
            else
                if ~isa(options.Compare, 'IndividualCMF')
                    error('IndividualCMF:InvalidInput', ...
                        'Comparison object must be an IndividualCMF instance.');
                end
                if options.Title == "", options.Title = "Macular Pigment Comparison"; end
                macCompScale = options.Compare.MacularDensity / CIE170.STD_2DEG_MACULAR_DENSITY;
                macComp = macTemplate * macCompScale;
                p = gobjects(2, 1);
                p(1) = plot(ax, wl, mac, '-', 'Color', [0 0 0.8], ...
                    'LineWidth', 2, 'DisplayName', 'Reference');
                p(2) = plot(ax, wl, macComp, '--', 'Color', [0.8 0 0], ...
                    'LineWidth', 2, 'DisplayName', 'Comparison');
            end
            if ~wasHeld, hold(ax, 'off'); end

            obj.finalizeLinePlot(ax, p, options.Title, "Optical Density");

            if nargout > 0, varargout{1} = p; end
            if nargout > 1, varargout{2} = ax; end
        end

        function varargout = plotDiagnostics(obj, options)
            % PLOTDIAGNOSTICS  Generates a diagnostic plot of the computational pipeline.
            %   Plots Absorbance -> Absorptance -> Corneal Sensitivity side-by-side.
            %
            %   obj.plotDiagnostics() plots without returning handles.
            %   p = obj.plotDiagnostics() returns cell array of line handles {p1, p2, p3}.
            %   [p, ax] = obj.plotDiagnostics() also returns axes array [ax1; ax2; ax3].
            %
            %   OPTIONAL INPUTS (Name-Value arguments):
            %       Wavelength - Wavelengths in nm. Default: (380:1:780)' (vector)
            %       Plotter - Existing plotter instance (must have 3+ tiles) (CMFPlotter)
            arguments
                obj
                options.Wavelength (:,1) double = (380:1:780)'
                options.Plotter CMFPlotter = CMFPlotter(1, 3, ...
                    Parent=gcf, ...
                    Title="IndividualCMF Diagnostics")
            end

            [p, ax] = options.Plotter.plotDiagnosticsPanel(obj, Wavelength=options.Wavelength);

            if nargout > 0
                varargout{1} = p;
            end
            if nargout > 1
                varargout{2} = ax;
            end
        end
    end

    % Cache-callback surface. These methods exist solely to support the
    % NormalizationCache class and white-box test access -- they are
    % computation internals, not part of the public API. Restricting
    % access keeps them out of `methods(obs)` listings and out of help
    % text. Add to the access list if a new internal collaborator needs
    % to call them.
    methods (Access = {?NormalizationCache, ?IndividualCMF, ?NormalizationTest})

        function val = computeRawSensitivity(obj, wl, coneType, outputFormat)
            % COMPUTERAWSENSITIVITY  Compute unnormalized sensitivity.
            %
            %   Returns raw (unnormalized) sensitivity values for the specified
            %   cone type and output format. Used internally by NormalizationCache.
            %
            %   INPUTS:
            %       wl - Wavelengths in nm (vector)
            %       coneType - 'L', 'M', or 'S' (char)
            %       outputFormat - 'absorbance', 'absorptance', 'quantal', 'energy' (string)
            %
            %   OUTPUTS:
            %       val - Raw sensitivity values (unnormalized) (vector)
            arguments
                obj
                wl (:,1) double {validators.mustBeWavelengthVector}
                coneType (1,1) char {mustBeMember(coneType, {'L', 'M', 'S'})}
                outputFormat (1,1) string {mustBeMember(outputFormat, ["absorbance", "absorptance", "quantal", "energy"])}
            end

            % Ensure column vector
            wl = wl(:);

            % Validate wavelengths against template's valid range.
            % Honour WavelengthWarning at both the IndividualCMF boundary
            % and inside the Nomograms layer, which has its own
            % independent warning. Restore on exit so we don't pollute
            % the caller's warning state.
            obj.validateWavelengths(wl);
            if ~obj.WavelengthWarning
                prevWarn = warning('off', 'Nomograms:WavelengthOutOfRange');
                cleanupWarn = onCleanup(@() warning(prevWarn));
            end

            % An optical density of zero represents an absent cone
            % (gene-deletion dichromacy). Every output format -- including
            % "absorbance", which would otherwise reflect the template
            % shape -- collapses to zero so downstream code can treat the
            % column as identically absent.
            if obj.getConeOD(coneType) == 0
                val = zeros(size(wl));
                return;
            end

            % Stage 1: Absorbance
            logAbs = obj.computePigmentAbsorbance(wl, coneType);

            if outputFormat == "absorbance"
                val = 10.^(logAbs);
                return;
            end

            % Stage 2: Absorptance
            absorptance = obj.computeRetinalAbsorptance(coneType, logAbs);

            if outputFormat == "absorptance"
                val = absorptance;
                return;
            end

            % Stage 3: Corneal Quantal
            quantal = obj.computeCornealQuantal(wl, absorptance);

            if outputFormat == "quantal"
                val = quantal;
                return;
            end

            % Stage 4: Energy
            val = obj.convertToEnergy(wl, quantal);
        end

        function peak = computeAnalyticalAbsorptancePeak(obj, coneType)
            arguments
                obj
                coneType (1,1) char {mustBeMember(coneType, {'L', 'M', 'S'})}
            end

            % This method should only be called for Govardovskii
            assert(obj.templateSupportsAnalyticalPeak(), ...
                'computeAnalyticalAbsorptancePeak should only be used with Govardovskii');

            shift = obj.getConeShift(coneType);
            od = obj.getConeOD(coneType);
            opts = obj.getTemplateOptions();

            % Absent cone (gene-deletion dichromacy): the cone column is
            % identically zero, so any peak value would work as the
            % cache's denominator (everything gets divided into zero).
            % Return 1 explicitly to avoid 0/0 = NaN from the relative
            % formula when od = 0 -- the cache's "peak == 0 -> 1"
            % guard would otherwise not fire because NaN ~= 0.
            if od == 0
                peak = 1;
                return;
            end

            peakAbsorbance = obj.p_PhotopigmentTemplate.computePeakAbsorbance(coneType, shift, opts);
            % Relative retinal absorptance peak: matches the helper-norm
            % convention applied by computeRetinalAbsorptance. For an
            % absorbance template whose peak is exactly 1 (Govardovskii
            % alpha-band), this reduces to (1-10^(-od))/(1-10^(-od)) = 1.
            peak = (1 - 10^(-od * peakAbsorbance)) / (1 - 10^(-od));
        end

        function peak = computePeakForFormat(obj, coneType, outputFormat)
            % COMPUTEPEAKFORFORMAT  Compute peak value for normalization.
            %
            %   Returns the peak sensitivity value for the given cone type and
            %   output format. Uses analytical formula for Govardovskii absorptance,
            %   numerical optimization (fminbnd) for everything else.

            arguments
                obj
                coneType (1,1) char {mustBeMember(coneType, {'L', 'M', 'S'})}
                outputFormat (1,1) string {mustBeMember(outputFormat, ["absorbance", "absorptance", "quantal", "energy"])}
            end

            % For Govardovskii absorptance: use analytical peak
            if outputFormat == "absorptance" && obj.templateSupportsAnalyticalPeak()
                peak = obj.computeAnalyticalAbsorptancePeak(coneType);
                return;
            end

            % For everything else: use fminbnd. The base bounds bracket
            % the unshifted peak with margin for the lambda factor in
            % energy/quantal stages. Add the cone's LambdaMaxShift so the
            % search tracks the peak when shifts move it; clamp to the
            % template's valid wavelength range so fminbnd never queries
            % outside where the template is defined. This matters for the
            % S cone because S_LambdaMaxShift is unbounded (the L/M
            % setters bound shifts to [-40, 10] / [-20, 30], but S
            % accepts any value).
            switch coneType
                case 'S', lb = 380; ub = 500;
                case 'M', lb = 480; ub = 600;
                case 'L', lb = 480; ub = 680;
            end
            shift = obj.getConeShift(coneType);
            lb = lb + shift;
            ub = ub + shift;
            validRange = obj.p_PhotopigmentTemplate.getValidRange();
            lb = max(lb, validRange(1));
            ub = min(ub, validRange(2));

            % A large finite S shift can push the shifted base window
            % entirely off one end of the template valid range, so
            % clamping both endpoints collapses to lb > ub. Fall back to
            % the full valid template range so fminbnd has a well-defined
            % interval and finds the true (off-base-window) peak.
            if lb >= ub
                lb = validRange(1);
                ub = validRange(2);
            end

            objFn = @(w) -obj.computeRawSensitivity(w, coneType, outputFormat);
            [~, negPeak] = fminbnd(objFn, lb, ub);
            peak = -negPeak;
        end
    end

    methods (Access = protected)
        function propgroups = getPropertyGroups(obj)
            if ~isscalar(obj)
                propgroups = getPropertyGroups@matlab.mixin.CustomDisplay(obj);
                return;
            end

            % Groups follow the four-stage LMS pipeline: identity ->
            % photopigment (stages 1-2) -> lens (stage 3a) -> macular
            % (stage 3b) -> output -> normalization. Within each stage
            % the model selector is listed first, followed by the
            % stage's density / algorithm / per-cone parameters.

            % Output Configuration is built from a struct rather than
            % a name list so its scalar logicals can be stringified to
            % render as "true"/"false" instead of 1/0 (matching the
            % quoted form used for properties like NormalizationMethod).
            outputCfg = struct( ...
                'OutputFormat',      obj.OutputFormat, ...
                'NormalizeOutput',   string(obj.NormalizeOutput), ...
                'LogOutput',         string(obj.LogOutput), ...
                'WavelengthWarning', string(obj.WavelengthWarning), ...
                'Primaries',         obj.Primaries);

            propgroups = [
                matlab.mixin.util.PropertyGroup({'Type', 'StandardObserver', ...
                    'Age', 'FieldSize'}, 'Observer Identity')
                matlab.mixin.util.PropertyGroup({'PhotopigmentModel', ...
                    'Lod', 'Mod', 'Sod', 'PhotopigmentDensityAlgorithm', ...
                    'L_OpsinTemplate', 'M_OpsinTemplate', ...
                    'L_LambdaMaxShift', 'M_LambdaMaxShift', 'S_LambdaMaxShift'}, ...
                    'Photopigment')
                matlab.mixin.util.PropertyGroup({'LensModel', ...
                    'LensDensity', 'LensDensityAlgorithm'}, 'Lens')
                matlab.mixin.util.PropertyGroup({'MacularModel', ...
                    'MacularDensity', 'MacularDensityAlgorithm'}, 'Macular')
                matlab.mixin.util.PropertyGroup(outputCfg, 'Output Configuration')
                matlab.mixin.util.PropertyGroup({'NormalizationMethod', ...
                    'NormalizationConfig'}, 'Normalization')
            ];
        end

        function cpObj = copyElement(obj)
            % COPYELEMENT  Create a deep copy of the IndividualCMF object.
            %   Overrides matlab.mixin.Copyable to properly copy internal state.
            %   - Creates a NEW NormalizationCache instance linked to the copy
            %   - Deep copies the GenotypeState dictionary

            % Shallow copy via parent class
            cpObj = copyElement@matlab.mixin.Copyable(obj);

            % Create a NEW NormalizationCache instance linked to the copy
            cpObj.p_NormalizationCache = NormalizationCache(cpObj);
            cpObj.p_NormalizationCache.setConfig(cpObj.p_NormalizationConfig);

            % Deep copy the GenotypeState dictionary
            if ~isempty(obj.GenotypeState) && numEntries(obj.GenotypeState) > 0
                cpObj.GenotypeState = dictionary(keys(obj.GenotypeState), values(obj.GenotypeState));
            else
                cpObj.GenotypeState = dictionary;
            end

            % Deep copy the LensTemplate (handle class requires explicit copy)
            switch obj.p_LensTemplate.ShortName
                case "StockmanRider2023"
                    cpObj.p_LensTemplate = StockmanRiderLensTemplate();
                case "Pokorny1987"
                    cpObj.p_LensTemplate = Pokorny1987LensTemplate();
                case "VanDeKraats2007"
                    cpObj.p_LensTemplate = VanDeKraatsVanNorren2007LensTemplate();
                otherwise
                    cpObj.p_LensTemplate = StockmanRiderLensTemplate();
            end

            % Deep copy the MacularTemplate (handle class requires explicit copy)
            switch obj.p_MacularTemplate.ShortName
                case "StockmanRider2023"
                    cpObj.p_MacularTemplate = StockmanRider2023MacularTemplate();
                otherwise
                    cpObj.p_MacularTemplate = StockmanRider2023MacularTemplate();
            end

            % Deep copy the ObserverParameters snapshot. Although ObserverParameters
            % is a value class, we explicitly reconstruct it to ensure complete
            % independence between the original and copied observer.
            cpObj.p_Parameters = ObserverParameters( ...
                LCone=obj.p_Parameters.LCone, ...
                MCone=obj.p_Parameters.MCone, ...
                SCone=obj.p_Parameters.SCone, ...
                Lens=obj.p_Parameters.Lens, ...
                Macular=obj.p_Parameters.Macular, ...
                Age=obj.p_Parameters.Age, ...
                FieldSize=obj.p_Parameters.FieldSize);

            % Re-add listeners (listeners are not copied by shallow copy)
            addlistener(cpObj, 'OutputFormat',   'PostSet', @(s,e) cpObj.invalidateNormalizationCache());
            addlistener(cpObj, 'LogOutput',      'PostSet', @(s,e) cpObj.invalidateNormalizationCache());
            addlistener(cpObj, 'NormalizeOutput','PostSet', @(s,e) cpObj.invalidateNormalizationCache());
        end
    end

    methods (Access = private)

        function clearConeGenotypeState(obj, cone)
            % CLEARCONEGENOTYPESTATE  Remove all GenotypeState entries
            % for one cone. Used when applyGenotypeShifts encounters an
            % absent cone to keep snapshot/display state consistent with
            % the parsed Genotype (whose absent side has empty genotype
            % and zero shift). Private because callers outside
            % applyGenotypeShifts would erase genotype state without
            % adjusting shifts or densities, leaving the observer
            % inconsistent.
            arguments
                obj
                cone (1,1) char {mustBeMember(cone, {'L', 'M'})}
            end
            for i = 1:numel(Genotype.POSITIONS)
                key = sprintf("%s_%d", cone, Genotype.POSITIONS(i));
                if isKey(obj.GenotypeState, key)
                    obj.GenotypeState = remove(obj.GenotypeState, key);
                end
            end
        end

        function LMS = chromaticityBasisLMS(obj, wl)
            % CHROMATICITYBASISLMS  Energy-unit, peak-normalized, linear LMS.
            %
            %   Returns LMS in the CIE 170-2:2015 derived-quantity basis:
            %   OutputFormat="energy", NormalizeOutput=true, LogOutput=false.
            %   This is the only basis under which the projective formulas
            %   for chromaticity coordinates and the V*(lambda) luminance
            %   recipe are well-defined, so it must be enforced regardless
            %   of the observer's current OutputFormat / LogOutput /
            %   NormalizeOutput state.
            %
            %   Used by Luminance, MacLeodBoynton, lmChromaticity, and the
            %   evaluate(Data='chromaticity') path. CMFPlotter.plotChromaticity
            %   delegates to obs.lmChromaticity, so it picks up this basis
            %   transitively.
            LMS = obj.LMS(wl, OutputFormat="energy", ...
                NormalizeOutput=true, LogOutput=false);
        end

        function ax = resolvePlotAxes(~, parent)
            % RESOLVEPLOTAXES  Pick a target axes for a shortcut plot method.
            %
            %   Returns parent if non-empty, otherwise gca. Used by the
            %   plot* shortcut methods to default to the current axes
            %   instead of creating a new figure -- this keeps the plot
            %   inline when called from a Live Script section.
            if isempty(parent)
                ax = gca;
            else
                ax = parent;
            end
        end

        function finalizeLinePlot(~, ax, p, titleStr, yLabelStr)
            % FINALIZELINEPLOT  Apply shared styling to a line plot.
            %
            %   Sets x/y labels, title, grid, and a 'best'-located legend
            %   over the supplied line handles. Drops gobjects placeholders
            %   (absent-cone slots) so the legend only lists drawn lines.
            valid = isgraphics(p);
            xlabel(ax, 'Wavelength (nm)');
            ylabel(ax, yLabelStr);
            if titleStr ~= ""
                title(ax, titleStr);
            end
            grid(ax, 'on');
            if any(valid)
                legend(ax, p(valid), 'Location', 'bestoutside', 'Box', 'off');
            end
        end

        function invalidateNormalizationCache(obj)
            % INVALIDATENORMALIZATIONCACHE  Invalidate cached peak values.
            %
            %   Called when any property affecting sensitivity calculations changes.
            if ~isempty(obj.p_NormalizationCache)
                obj.p_NormalizationCache.setConfig(obj.p_NormalizationConfig);
            end
        end

        function tf = isStandardConfiguration(obj)
            % ISSTANDARDCONFIGURATION  Check if observer matches CIE 170-1:2006 exactly.
            %   Returns true only if ALL parameters match the CIE standard:
            %   1. FieldSize is exactly 2 OR 10
            %   2. Age is exactly 32 (STD_AGE)
            %   3. MacularDensityAlgorithm is "CIE170"
            %   4. PhotopigmentDensityAlgorithm is "CIE170"
            %   5. LensDensity matches STD_LENS_DENSITY_400 (within 1e-6)
            %   6. All lambda-max shifts are exactly 0
            %   7. L_OpsinTemplate and M_OpsinTemplate are "Mean"
            %   8. PhotopigmentModel is "StockmanRider2023"

            isStandardFieldSize = (obj.p_Parameters.FieldSize == 2 || obj.p_Parameters.FieldSize == 10);
            isStandardAge = (obj.p_Parameters.Age == CIE170.STD_AGE);
            isCIEMacular = (obj.p_MacularDensityAlgorithm == "CIE170");
            isCIEPhotopigment = (obj.p_PhotopigmentDensityAlgorithm == "CIE170");
            isStandardLens = abs(obj.LensDensity - CIE170.STD_LENS_DENSITY_400) < 1e-6;
            isZeroLShift = (obj.p_Parameters.LCone.LambdaMaxShift == 0);
            isZeroMShift = (obj.p_Parameters.MCone.LambdaMaxShift == 0);
            isZeroSShift = (obj.p_Parameters.SCone.LambdaMaxShift == 0);
            isMeanLTemplate = (obj.p_L_Template == "Mean");
            isMeanMTemplate = (obj.p_M_Template == "Mean");
            isStockmanTemplate = (obj.PhotopigmentModel == "StockmanRider2023");

            tf = isStandardFieldSize && isStandardAge && isCIEMacular && isCIEPhotopigment && ...
                 isStandardLens && isZeroLShift && isZeroMShift && isZeroSShift && ...
                 isMeanLTemplate && isMeanMTemplate && isStockmanTemplate;
        end

        function validateWavelengths(obj, wl)
            % VALIDATEWAVELENGTHS  Warn if wavelengths are outside template validity range.
            %
            %   Issues a warning (once per session) if any wavelengths fall outside
            %   the current template's valid range.
            %
            %   INPUTS:
            %       wl - Wavelengths in nm to validate (vector)
            arguments
                obj
                wl (:,1) double {validators.mustBeWavelengthVector}
            end

            % Skip if warnings are disabled or already issued
            if ~obj.WavelengthWarning || obj.p_WavelengthWarningIssued
                return;
            end

            % Get valid range from template
            validRange = obj.p_PhotopigmentTemplate.getValidRange();
            minWl = validRange(1);
            maxWl = validRange(2);

            % Find out-of-range wavelengths
            belowRange = wl < minWl;
            aboveRange = wl > maxWl;
            outOfRange = belowRange | aboveRange;

            if any(outOfRange)
                % Mark that we've issued the warning
                obj.p_WavelengthWarningIssued = true;

                % Build informative message
                badWavelengths = wl(outOfRange);
                if numel(badWavelengths) <= 5
                    wlStr = sprintf('%.0f', badWavelengths(1));
                    for i = 2:numel(badWavelengths)
                        wlStr = sprintf('%s, %.0f', wlStr, badWavelengths(i));
                    end
                else
                    wlStr = sprintf('%.0f, %.0f, ... (%.0f total)', ...
                        badWavelengths(1), badWavelengths(2), numel(badWavelengths));
                end

                warning('IndividualCMF:WavelengthOutOfRange', ...
                    ['Wavelengths [%s] nm are outside the valid range [%.0f-%.0f nm] ' ...
                    'for the %s template. Results may be unreliable.'], ...
                    wlStr, minWl, maxWl, obj.p_PhotopigmentTemplate.ShortName);
            end
        end

        function cfg = validateSampledConfig(~, val)
            % VALIDATESAMPLEDCONFIG  Validate and normalize Sampled configuration struct.
            %
            %   INPUTS:
            %       val - Configuration struct with Method="Sampled" (struct)
            %
            %   OUTPUTS:
            %       cfg - Validated configuration with defaults applied (struct)
            arguments
                ~
                val (1,1) struct
            end

            if ~isfield(val, 'Method') || string(val.Method) ~= "Sampled"
                error('IndividualCMF:InvalidNormalizationConfig', ...
                    'Struct configuration requires Method="Sampled". For continuous normalization, use NormalizationMethod="Continuous".');
            end

            % Apply defaults for missing fields
            if ~isfield(val, 'Start'), val.Start = IndividualCMF.DEFAULT_SAMPLED_RANGE_NM(1); end
            if ~isfield(val, 'Stop'),  val.Stop  = IndividualCMF.DEFAULT_SAMPLED_RANGE_NM(2); end
            if ~isfield(val, 'Step'),  val.Step  = IndividualCMF.DEFAULT_SAMPLED_STEP_NM; end

            % Finite-scalar guards run BEFORE the relational checks --
            % NaN and Inf bypass `a >= b` / `a <= 0` (NaN comparisons
            % return false; Inf passes `>= Stop` only if Stop is also
            % Inf) and would otherwise be stored in the config, where
            % `Start:Step:Stop` later produces an invalid wavelength
            % vector or an accidental huge grid.
            for fieldName = ["Start", "Stop", "Step"]
                v = val.(fieldName);
                if ~(isscalar(v) && isnumeric(v) && isfinite(v))
                    error('IndividualCMF:InvalidNormalizationConfig', ...
                        '%s must be a finite numeric scalar.', fieldName);
                end
            end

            % Relational checks
            if val.Start >= val.Stop
                error('IndividualCMF:InvalidNormalizationConfig', ...
                    'Start (%.1f) must be less than Stop (%.1f).', val.Start, val.Stop);
            end
            if val.Step <= 0
                error('IndividualCMF:InvalidNormalizationConfig', ...
                    'Step must be positive.');
            end

            cfg = struct('Method', "Sampled", ...
                'Start', double(val.Start), ...
                'Stop', double(val.Stop), ...
                'Step', double(val.Step));
        end

        function logAbs = computePigmentAbsorbance(obj, wl, coneType)
            % COMPUTEPIGMENTABSORBANCE  Compute log10 photopigment absorbance.
            %
            %   This is the first stage of the pipeline. Returns the raw
            %   absorbance spectrum from the template model with wavelength
            %   shift applied.
            %
            %   INPUTS:
            %       wl - Wavelengths in nm (column vector) (vector)
            %       coneType - 'L', 'M', or 'S' (char)
            %
            %   OUTPUTS:
            %       logAbs - Log10 absorbance spectrum (vector)
            arguments
                obj
                wl (:,1) double {validators.mustBeWavelengthVector}
                coneType (1,1) char {mustBeMember(coneType, {'L', 'M', 'S'})}
            end

            shift = obj.getConeShift(coneType);
            templateOpts = obj.getTemplateOptions();
            logAbs = pipeline.PhotopigmentStage.logAbsorbance( ...
                obj.p_PhotopigmentTemplate, wl, coneType, shift, templateOpts);
        end

        function absorptance = computeRetinalAbsorptance(obj, coneType, logAbs)
            % COMPUTERETINALABSORPTANCE  Apply self-screening to get absorptance.
            %
            %   Converts pigment absorbance to retinal absorptance by applying
            %   the optical density (self-screening) of the photopigment.
            %
            %   INPUTS:
            %       coneType - 'L', 'M', or 'S' (char)
            %       logAbs - Log10 absorbance from Stage 1 (vector)
            %
            %   OUTPUTS:
            %       absorptance - Retinal absorptance spectrum (0 to 1) (vector)
            arguments
                obj
                coneType (1,1) char {mustBeMember(coneType, {'L', 'M', 'S'})}
                logAbs (:,1) double
            end

            od = obj.getConeOD(coneType);

            % Public OutputFormat="absorptance" is RELATIVE retinal
            % absorptance: (1 - 10^(-OD*A)) / (1 - 10^(-OD)), where A is
            % the linear photopigment absorbance normalised to peak 1.
            % Both template families use this convention so the user gets
            % the same physical quantity regardless of PhotopigmentModel.
            % The raw Beer-Lambert fraction 1 - 10^(-OD*A) is still
            % available through pipeline.PhotopigmentStage.absorptanceFromAbsorbance
            % with Normalize=false.
            absorptance = pipeline.PhotopigmentStage.retinalAbsorptance(logAbs, od, true);
        end

        function quantal = computeCornealQuantal(obj, wl, absorptance)
            % COMPUTECORNEALQUANTAL  Apply pre-receptoral filtering.
            %
            %   Applies macular pigment and lens filtering to get corneal
            %   (external) quantal sensitivity.
            %
            %   INPUTS:
            %       wl - Wavelengths in nm (vector)
            %       absorptance - Retinal absorptance from Stage 2 (vector)
            %
            %   OUTPUTS:
            %       quantal - Corneal quantal sensitivity (vector)
            arguments
                obj
                wl (:,1) double {validators.mustBeWavelengthVector}
                absorptance (:,1) double
            end

            quantal = pipeline.PreReceptoralStage.applyFilters( ...
                absorptance, wl, ...
                LensTemplate=obj.p_LensTemplate, ...
                LensDensity=obj.LensDensity, ...
                MacularTemplate=obj.p_MacularTemplate, ...
                MacularDensity=obj.MacularDensity, ...
                Age=obj.p_Parameters.Age, ...
                FieldSize=obj.p_Parameters.FieldSize);
        end

        function energy = convertToEnergy(~, wl, quantal)
            % CONVERTTOENERGY  Convert quantal to energy-based sensitivity.
            %
            %   Multiplies by wavelength to convert from photon-based to
            %   energy-based (Watt) sensitivity units.
            %
            %   INPUTS:
            %       wl - Wavelengths in nm (vector)
            %       quantal - Quantal sensitivity from Stage 3 (vector)
            %
            %   OUTPUTS:
            %       energy - Energy-based sensitivity (vector)
            arguments
                ~
                wl (:,1) double {validators.mustBeWavelengthVector}
                quantal (:,1) double
            end

            energy = pipeline.OutputStage.quantalToEnergy(quantal, wl);
        end

        % Internal sensitivity calculator (must bind to L/M/S properties)
        function val = calculateSensitivity(obj, nm, cone_type)
            arguments
                obj
                nm double {mustBeNumeric}
                cone_type (1,1) char
            end
            val = obj.computeSensitivityCore(nm, cone_type, obj.OutputFormat, obj.NormalizeOutput, obj.LogOutput);
        end

        function applyStandardObserver(obj, options)
            % APPLYSTANDARDOBSERVER  Configure for strict CIE 170-1:2006 Standard Observer.
            %   Forces: Age=32, Shifts=0, Templates="Mean", Lens=Standard, Algorithms="CIE170".
            arguments
                obj
                options
            end
            if ~isnan(options.Age) || ~isnan(options.FieldSize)
                error('IndividualCMF:Conflict', 'Cannot specify Age/FieldSize with StandardObserver.');
            end
            if ~isnan(options.Lod) || ~isnan(options.Mod) || ~isnan(options.Sod) || ~isnan(options.MacularDensity) || ~isnan(options.LensDensity)
                error('IndividualCMF:Conflict', 'Cannot override biophysical parameters when StandardObserver is set.');
            end
            if options.L_LambdaMaxShift ~= 0 || options.M_LambdaMaxShift ~= 0 || options.S_LambdaMaxShift ~= 0 || options.L_OpsinTemplate ~= "Mean" || options.M_OpsinTemplate ~= "Mean"
                error('IndividualCMF:Conflict', 'Standard Observer requires 0 cone shifts and "Mean" templates.');
            end
            if ~isempty(options.Genotype)
                error('IndividualCMF:Conflict', 'Standard Observer does not support custom Genotype overrides.');
            end
            if options.PhotopigmentModel ~= "StockmanRider2023"
                error('IndividualCMF:Conflict', 'Standard Observer requires PhotopigmentModel="StockmanRider2023".');
            end

            obj.snapToStandardObserver(options.StandardObserver);
        end

        function snapToStandardObserver(obj, fieldSize)
            % SNAPTOSTANDARDOBSERVER  Reset biophysics to CIE 2006 standard.
            %   fieldSize is 2 or 10. Resets all biophysical parameters,
            %   density algorithms, opsin templates, lambda-max shifts,
            %   and the genotype-residue dictionary to the CIE 2006
            %   tabulated values for the given field size.
            %
            %   Used by both the constructor (after applyStandardObserver
            %   validates conflicting options) and the StandardObserver
            %   property setter (which has no options to validate).
            %
            %   Output-shape settings (OutputFormat, NormalizeOutput,
            %   LogOutput, NormalizationMethod, Primaries,
            %   WavelengthWarning) are intentionally preserved.
            arguments
                obj
                fieldSize (1,1) double {mustBeMember(fieldSize, [2, 10])}
            end

            % Force strict Standard Observer configuration
            obj.p_Parameters.Age = CIE170.STD_AGE;
            obj.p_Parameters.FieldSize = fieldSize;
            obj.p_L_Template = "Mean";
            obj.p_M_Template = "Mean";

            % Force CIE Constants mode for both algorithms
            obj.p_MacularDensityAlgorithm = "CIE170";
            obj.p_PhotopigmentDensityAlgorithm = "CIE170";
            obj.p_LensDensityAlgorithm = "Auto";

            % Clear any genotype residue assignments left over from
            % setGenotype/applyGenotype - the standard observer uses
            % Mean templates and zero shifts, so per-position residues
            % are no longer meaningful.
            obj.GenotypeState = configureDictionary("string", "string");

            obj.recalcBiophysics();

            % Set zero shifts using public setters
            obj.L_LambdaMaxShift = 0;
            obj.M_LambdaMaxShift = 0;
            obj.S_LambdaMaxShift = 0;
        end

        function applyManualConfig(obj, options)
            % APPLYMANUALCONFIG  Configure observer with smart algorithm defaults.
            %   - FieldSize 2 or 10 (no overrides): Default to "CIE170"
            %   - Otherwise: Default to "MorelandAlexander" / "PokornySmith"
            arguments
                obj
                options
            end

            % Validate that Genotype is not combined with explicit shift or
            % opsin-template overrides. The genotype determines both, so
            % providing both is ambiguous -- error rather than silently letting
            % one win. Matches the IndividualCMF:Conflict pattern used by
            % applyStandardObserver.
            if ~isempty(options.Genotype)
                if options.L_LambdaMaxShift ~= 0 || options.M_LambdaMaxShift ~= 0 || options.S_LambdaMaxShift ~= 0
                    error('IndividualCMF:Conflict', ...
                        ['Cannot combine explicit L_/M_/S_LambdaMaxShift with Genotype. ' ...
                         'Genotype determines the shifts; specify one or the other.']);
                end
                if options.L_OpsinTemplate ~= "Mean" || options.M_OpsinTemplate ~= "Mean"
                    error('IndividualCMF:Conflict', ...
                        ['Cannot combine explicit L_/M_OpsinTemplate with Genotype. ' ...
                         'Genotype determines the templates; specify one or the other.']);
                end
            end

            if isnan(options.Age)
                obj.p_Parameters.Age = CIE170.STD_AGE;
            else
                obj.p_Parameters.Age = options.Age;
            end
            if isnan(options.FieldSize)
                obj.p_Parameters.FieldSize = 10;
            else
                obj.p_Parameters.FieldSize = options.FieldSize;
            end

            % Check if photopigment, macular, or lens densities are explicitly provided
            hasPhotopigmentOverride = ~isnan(options.Lod) || ~isnan(options.Mod) || ~isnan(options.Sod);
            hasMacularOverride = ~isnan(options.MacularDensity);
            hasLensOverride = ~isnan(options.LensDensity);

            % Check if field size is standard (2 or 10)
            isStandardFieldSize = (obj.p_Parameters.FieldSize == 2 || obj.p_Parameters.FieldSize == 10);

            % Smart algorithm defaults: density override forces Custom;
            % otherwise an explicit algorithm wins; otherwise the
            % field-size-appropriate default applies. See chooseAlgorithm.
            obj.p_PhotopigmentDensityAlgorithm = IndividualCMF.chooseAlgorithm( ...
                hasPhotopigmentOverride, options.PhotopigmentDensityAlgorithm, ...
                isStandardFieldSize, "CIE170", "PokornySmith");
            obj.p_MacularDensityAlgorithm = IndividualCMF.chooseAlgorithm( ...
                hasMacularOverride, options.MacularDensityAlgorithm, ...
                isStandardFieldSize, "CIE170", "MorelandAlexander");

            % Lens density mode does not have a field-size dispatch:
            % override -> Custom, explicit -> use it, otherwise -> Auto
            % (recompute from Age via the active LensTemplate).
            if hasLensOverride
                obj.p_LensDensityAlgorithm = "Custom";
            elseif options.LensDensityAlgorithm ~= ""
                obj.p_LensDensityAlgorithm = options.LensDensityAlgorithm;
            else
                obj.p_LensDensityAlgorithm = "Auto";
            end

            % Calculate biophysics based on the algorithms (Custom will skip recalculation)
            obj.recalcBiophysics();

            % Apply explicit density overrides (for Custom mode)
            if ~isnan(options.Lod), obj.Lod = options.Lod; end
            if ~isnan(options.Mod), obj.Mod = options.Mod; end
            if ~isnan(options.Sod), obj.Sod = options.Sod; end
            if ~isnan(options.MacularDensity), obj.MacularDensity = options.MacularDensity; end
            if ~isnan(options.LensDensity), obj.LensDensity = options.LensDensity; end

            obj.L_LambdaMaxShift = options.L_LambdaMaxShift;
            obj.M_LambdaMaxShift = options.M_LambdaMaxShift;
            obj.S_LambdaMaxShift = options.S_LambdaMaxShift;
            obj.p_L_Template = options.L_OpsinTemplate;
            obj.p_M_Template = options.M_OpsinTemplate;
            % Note: PhotopigmentModel and LensModel are set by the constructor
            % before applyManualConfig is called (see constructor step 5),
            % so they are not reassigned here. This ordering ensures that
            % explicit LensDensity overrides applied above are not clobbered
            % by LensModel's age-based recalculation.

            if ~isempty(options.Genotype)
                obj.processGenotypeInput(options.Genotype);
            end
        end

        function processGenotypeInput(obj, inputGenotype)
            arguments
                obj
                inputGenotype
            end

            % String form: Stockman/Rider 5-letter notation "L-genotype/M-genotype".
            % Routed through applyGenotypeShifts so the constructor,
            % applyGenotype, and Genotype.toObserverParameters share the
            % same semantics (dichromacy zeroing, template choice, shift,
            % GenotypeState population).
            if isstring(inputGenotype) || ischar(inputGenotype)
                g = Genotype(string(inputGenotype));
                obj.applyGenotypeShifts(g);
                return
            end

            if isstruct(inputGenotype)
                keys = string(fieldnames(inputGenotype));
                vals = string(struct2cell(inputGenotype));
                inputGenotype = dictionary(keys, vals);
            end

            if isa(inputGenotype, 'dictionary')
                k = inputGenotype.keys;
                v = inputGenotype.values;

                for i = 1:numel(k)
                    key = k(i);
                    val = v(i);
                    parts = split(key, '_');
                    if numel(parts) == 2
                        cone = parts(1);
                        pos = str2double(parts(2));
                        obj.setGenotype(cone, pos, val);
                    end
                end
            end
        end
        function aa = getGenotypeAt(obj, cone, position)
            arguments
                obj
                cone (1,1) string
                position (1,1) double
            end
            key = sprintf("%s_%d", cone, position);
            if isKey(obj.GenotypeState, key)
                aa = obj.GenotypeState(key);
            else
                aa = "Unknown";
            end
        end
        function has = hasGenotype(obj, key, val)
            arguments
                obj
                key (1,1) string
                val (1,1) string
            end
            has = false;
            if isKey(obj.GenotypeState, key)
                has = strcmp(obj.GenotypeState(key), val);
            end
        end

        function od = getConeOD(obj, cone_type)
            % GETCONEOD  Get optical density for specified cone type.
            %
            %   INPUTS:
            %       cone_type - Cone type: 'L', 'M', or 'S' (char)
            %
            %   OUTPUTS:
            %       od - Optical density value.
            arguments
                obj
                cone_type (1,1) char {mustBeMember(cone_type, {'L', 'M', 'S'})}
            end
            switch cone_type
                case 'L', od = obj.p_Parameters.LCone.OpticalDensity;
                case 'M', od = obj.p_Parameters.MCone.OpticalDensity;
                case 'S', od = obj.p_Parameters.SCone.OpticalDensity;
            end
        end

        function shift = getConeShift(obj, cone_type)
            % GETCONESHIFT  Get lambda-max shift for specified cone type.
            %
            %   INPUTS:
            %       cone_type - Cone type: 'L', 'M', or 'S' (char)
            %
            %   OUTPUTS:
            %       shift - Shift in nm.
            arguments
                obj
                cone_type (1,1) char {mustBeMember(cone_type, {'L', 'M', 'S'})}
            end
            switch cone_type
                case 'L', shift = obj.p_Parameters.LCone.LambdaMaxShift;
                case 'M', shift = obj.p_Parameters.MCone.LambdaMaxShift;
                case 'S', shift = obj.p_Parameters.SCone.LambdaMaxShift;
            end
        end

        function opts = getTemplateOptions(obj)
            % GETTEMPLATEOPTIONS  Build options struct for template methods.
            %
            %   OUTPUTS:
            %       opts - Struct with L_Template and M_Template fields.
            opts = struct();
            opts.L_Template = string(obj.p_L_Template);
            opts.M_Template = string(obj.p_M_Template);
        end

        function usesAnalyticalPeak = templateSupportsAnalyticalPeak(obj)
            % TEMPLATESUPPORTSANALYTICALPEAK  Whether the active photopigment
            % template can return its peak in closed form. Delegates to the
            % template's SupportsAnalyticalPeak constant property -- new
            % PhotopigmentTemplate subclasses declare their own truth.
            usesAnalyticalPeak = obj.p_PhotopigmentTemplate.SupportsAnalyticalPeak;
        end

        function val = computeSensitivityCore(obj, nm, cone_type, fmt, normalizeOutput, logOutput)
            % COMPUTE_SENSITIVITY_CORE  Main sensitivity computation dispatcher.
            %
            %   Orchestrates the pipeline stages and applies output transforms.
            %   All formats except absorbance flow through NormalizationCache.
            arguments
                obj
                nm double {mustBeNumeric}
                cone_type (1,1) char {mustBeMember(cone_type, {'L', 'M', 'S'})}
                fmt (1,1) string
                normalizeOutput (1,1) logical
                logOutput (1,1) logical
            end

            % Track input shape for output reshaping
            wasRow = isrow(nm);
            nm_col = nm(:);

            % An optical density of zero represents an absent cone
            % (gene-deletion dichromacy). Every output format -- including
            % "absorbance", which would otherwise reflect the template
            % shape -- collapses to zero so downstream code can treat the
            % column as identically absent. In log mode, return the
            % -10 floor used elsewhere in the toolbox for "below dynamic
            % range" rather than -Inf.
            if obj.getConeOD(cone_type) == 0
                if logOutput
                    val = -10 * ones(size(nm_col));
                else
                    val = zeros(size(nm_col));
                end
                if wasRow, val = val'; end
                return;
            end

            % Absorbance: raw template output, no normalization via cache
            if fmt == "absorbance"
                logAbs = obj.computePigmentAbsorbance(nm_col, cone_type);
                if logOutput
                    val = pipeline.OutputStage.cleanNaN(logAbs, true);
                else
                    val = pipeline.OutputStage.cleanNaN(10.^(logAbs), false);
                end
                if wasRow, val = val'; end
                return;
            end

            % Standard path: absorptance, quantal, and energy use the same flow
            val = obj.computeRawSensitivity(nm_col, cone_type, fmt);

            % Apply normalization via cache
            if normalizeOutput
                peak = obj.p_NormalizationCache.getPeak(cone_type, fmt);
                val = pipeline.OutputStage.normalize(val, peak);
            end

            % Apply log transform / NaN handling
            if logOutput
                val = pipeline.OutputStage.applyLog(val);
            else
                val = pipeline.OutputStage.cleanNaN(val, false);
            end

            % Restore input shape
            if wasRow
                val = val';
            end
        end

        function recalcBiophysics(obj)
            arguments
                obj
            end
            obj.updateMacularDensity();
            obj.updatePhotopigmentDensities();
            obj.recalcLensFromAge();
        end

        function setInternalUpdateFalse(obj)
            % SETINTERNALUPDATEFALSE  Helper to reset the internal update flag.
            obj.p_IsInternalUpdate = false;
        end

        function updateMacularDensity(obj)
            % UPDATEMACULARDENSITY  Update macular density based on MacularDensityAlgorithm.
            obj.p_IsInternalUpdate = true;
            cleanup = onCleanup(@() obj.setInternalUpdateFalse());

            fieldSize = obj.p_Parameters.FieldSize;
            switch obj.MacularDensityAlgorithm
                case "Custom"
                    % Preserve user values
                    return
                case "CIE170"
                    obj.MacularDensity = PreReceptoralFilter.macularDensityCIEStandard(fieldSize);
                case "MorelandAlexander"
                    obj.MacularDensity = PreReceptoralFilter.macularDensityAtFieldSize(fieldSize);
            end
        end

        function updatePhotopigmentDensities(obj)
            % UPDATEPHOTOPIGMENTDENSITIES  Update photopigment densities based on PhotopigmentDensityAlgorithm.
            obj.p_IsInternalUpdate = true;
            cleanup = onCleanup(@() obj.setInternalUpdateFalse());

            fieldSize = obj.p_Parameters.FieldSize;
            switch obj.PhotopigmentDensityAlgorithm
                case "Custom"
                    % Preserve user values
                    return
                case "CIE170"
                    [obj.Lod, obj.Mod, obj.Sod] = PhotopigmentParameters.densitiesCIEStandard(fieldSize);
                case "PokornySmith"
                    [obj.Lod, obj.Mod, obj.Sod] = PhotopigmentParameters.densitiesAtFieldSize(fieldSize);
            end
        end

        function updatePhotopigmentAlgorithmFromValues(obj)
            % UPDATEPHOTOPIGMENTALGORITHMFROMVALUES  Tag current densities as CIE170 vs Custom.
            %   If all three photopigment densities match the CIE standard
            %   table for the current field size (2 or 10 deg only), set
            %   algorithm to "CIE170"; otherwise "Custom". Non-standard
            %   field sizes can never be CIE170 -- there is no published
            %   table to match against.
            fieldSize = obj.p_Parameters.FieldSize;
            if fieldSize == 2 || fieldSize == 10
                [stdLod, stdMod, stdSod] = PhotopigmentParameters.densitiesCIEStandard(fieldSize);
                if obj.p_Parameters.LCone.OpticalDensity == stdLod && ...
                        obj.p_Parameters.MCone.OpticalDensity == stdMod && ...
                        obj.p_Parameters.SCone.OpticalDensity == stdSod
                    obj.p_PhotopigmentDensityAlgorithm = "CIE170";
                    return
                end
            end
            obj.p_PhotopigmentDensityAlgorithm = "Custom";
        end

        function recalcLensFromAge(obj)
            % RECALCLENSFROMAGE  Updates LensDensity based on current Age.
            %
            %   In Custom mode this is a no-op so explicit LensDensity
            %   overrides are preserved across Age, FieldSize, and LensModel
            %   changes. Otherwise delegates the age-dependent density
            %   calculation to the active LensTemplate class:
            %
            %   StockmanRider2023: Returns CIE170.STD_LENS_DENSITY_400 (1.7649)
            %                      regardless of age. No lens aging in this model.
            %
            %   Pokorny1987:       Returns age-dependent TL(400,age) per the two-component
            %                      model from Pokorny, Smith & Lutze (1987).
            %
            %   VanDeKraats2007:   Returns age-dependent total-media density at 400 nm
            %                      per the five-component model (Eq. 8) of van de Kraats
            %                      & van Norren (2007).
            %
            %   See also: LensTemplate, StockmanRiderLensTemplate, Pokorny1987LensTemplate,
            %             VanDeKraatsVanNorren2007LensTemplate
            arguments
                obj
            end

            if obj.p_LensDensityAlgorithm == "Custom"
                return
            end

            obj.p_IsInternalUpdate = true;
            cleanup = onCleanup(@() obj.setInternalUpdateFalse());
            obj.LensDensity = obj.p_LensTemplate.computeDensityAt400( ...
                obj.p_Parameters.Age, FieldSize=obj.p_Parameters.FieldSize);
        end
    end

    methods (Static)
        function observers = across(parameter, values, fixedArgs)
            % ACROSS  Construct an array of IndividualCMF observers across a parameter axis.
            %
            %   observers = IndividualCMF.across(parameter, values)
            %   constructs one IndividualCMF per element of values,
            %   varying the named parameter and leaving everything else
            %   at constructor defaults.
            %
            %   observers = IndividualCMF.across(parameter, values, Name=Value, ...)
            %   passes additional fixed name-value arguments through to
            %   every constructor call. The swept parameter cannot also
            %   appear in the fixed args (raises IndividualCMF:AcrossConflict).
            %
            %   INPUTS:
            %       parameter - Name of the constructor argument to vary (string)
            %       values - Sweep values: numeric vector, string array,
            %                or cell array (for Primaries, where each
            %                element is a 1x3 row vector).
            %
            %   OPTIONAL INPUTS (Name-Value arguments):
            %       Any IndividualCMF constructor argument other than the
            %       one named in parameter.
            %
            %   OUTPUTS:
            %       observers - 1xN array of IndividualCMF handles.
            %
            %   EXAMPLES:
            %       observers = IndividualCMF.across('Age', [25 50 75], ...
            %           LensModel="VanDeKraats2007", FieldSize=10);
            %
            %       models = IndividualCMF.across('LensModel', ...
            %           ["StockmanRider2023", "Pokorny1987", "VanDeKraats2007"], ...
            %           Age=70);
            %
            %   Copyright 2025-2026 Alexander Forsythe and Brian Funt. Simon Fraser University.
            arguments
                parameter (1,1) string {mustBeNonzeroLengthText}
                values
                fixedArgs.?IndividualCMF
                fixedArgs.Genotype
            end

            fixedNames = string(fieldnames(fixedArgs));
            if any(fixedNames == parameter)
                error('IndividualCMF:AcrossConflict', ...
                    'Parameter "%s" appears in both the sweep axis and the fixed arguments.', ...
                    parameter);
            end

            fixedNVPairs = namedargs2cell(fixedArgs);
            n = numel(values);
            observers = IndividualCMF.empty;
            for i = 1:n
                if iscell(values)
                    v = values{i};
                else
                    v = values(i);
                end
                observers(i) = IndividualCMF(parameter, v, fixedNVPairs{:});
            end
        end
    end

    methods (Static, Access = private)
        function alg = chooseAlgorithm(hasOverride, explicit, isStandardFS, fsStandardDefault, fsFormulaDefault)
            % CHOOSEALGORITHM  Pick a density algorithm name from constructor options.
            %
            %   Implements the smart-default precedence used by
            %   applyManualConfig for the Photopigment and Macular
            %   density algorithms (Lens has a different shape and is
            %   handled inline):
            %
            %       1. If a density override was provided (e.g. user
            %          passed MacularDensity=0.4 to the constructor),
            %          return "Custom" so the override is preserved.
            %       2. Else if the user explicitly named an algorithm
            %          via the corresponding *DensityAlgorithm option,
            %          return that.
            %       3. Else, at standard field sizes (2 or 10 deg),
            %          return fsStandardDefault (typically "CIE170").
            %       4. Else, return fsFormulaDefault (the appropriate
            %          continuous formula -- "PokornySmith" for
            %          photopigment, "MorelandAlexander" for macular).
            %
            %   INPUTS:
            %       hasOverride - User supplied an explicit density value (logical)
            %       explicit - Explicit algorithm name from options ("" if absent) (string)
            %       isStandardFS - true if FieldSize is 2 or 10 (logical)
            %       fsStandardDefault - Algorithm at standard FS with no override (string)
            %       fsFormulaDefault - Algorithm at non-standard FS (string)
            %
            %   OUTPUTS:
            %       alg - Selected algorithm name (string)
            arguments
                hasOverride (1,1) logical
                explicit (1,1) string
                isStandardFS (1,1) logical
                fsStandardDefault (1,1) string
                fsFormulaDefault (1,1) string
            end
            if hasOverride
                alg = "Custom";
            elseif explicit ~= ""
                alg = explicit;
            elseif isStandardFS
                alg = fsStandardDefault;
            else
                alg = fsFormulaDefault;
            end
        end
    end

end


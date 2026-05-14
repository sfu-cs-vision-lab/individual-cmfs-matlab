classdef ObserverParameters
    % OBSERVERPARAMETERS  Physiological parameters defining an individual observer.
    %
    %   This value class bundles all physiological parameters that determine
    %   an individual observer's color matching functions. It uses
    %   PhotopigmentParameters and PreReceptoralFilter as building blocks.
    %
    %   Per CIE 170-2:2015, individual observers differ in:
    %   - Photopigment optical densities (L, M, S cones)
    %   - Photopigment lambda-max shifts (spectral tuning due to polymorphisms)
    %   - Lens pigment density (age-dependent yellowing of the crystalline lens)
    %   - Macular pigment density (varies with diet, genetics, and eccentricity)
    %   - Field size (affects macular pigment contribution and optical densities)
    %
    %   ObserverParameters Properties:
    %       LCone      - Photopigment parameters for L-cones.
    %       MCone      - Photopigment parameters for M-cones.
    %       SCone      - Photopigment parameters for S-cones.
    %       Lens       - Pre-receptoral lens filter parameters.
    %       Macular    - Pre-receptoral macular pigment filter parameters.
    %       Age        - Observer age in years (affects lens density).
    %       FieldSize  - Visual field diameter in degrees (affects macular/optical densities).
    %       PhotopigmentModel              - Photopigment template family.
    %       LensModel                  - Lens template family.
    %       L_OpsinTemplate            - L-cone opsin template variant.
    %       M_OpsinTemplate            - M-cone opsin template variant.
    %       MacularDensityAlgorithm    - Macular density computation strategy.
    %       PhotopigmentDensityAlgorithm - Photopigment density computation strategy.
    %       LensDensityAlgorithm       - Lens density computation strategy.
    %
    %   Round-trip with IndividualCMF:
    %       getParameters() captures all of the above; setParameters()
    %       applies them. This means an observer's complete state -
    %       including model selections and Auto/Custom algorithm modes -
    %       survives parameter transfer. obs2.setParameters(obs1.getParameters())
    %       produces identical LMS output.
    %
    %   ObserverParameters Constant Properties:
    %       DEFAULT_L_OPSIN_TEMPLATE              - Default L-cone opsin template variant.
    %       DEFAULT_M_OPSIN_TEMPLATE              - Default M-cone opsin template variant.
    %       DEFAULT_MACULAR_DENSITY_ALGORITHM     - Default macular density algorithm.
    %       DEFAULT_PHOTOPIGMENT_DENSITY_ALGORITHM - Default photopigment density algorithm.
    %       DEFAULT_LENS_DENSITY_ALGORITHM        - Default lens density algorithm.
    %
    %   ObserverParameters Methods:
    %       ObserverParameters     - Constructor with optional Name=Value arguments.
    %       isStandardConfiguration - Check if parameters match CIE standard.
    %
    %   ObserverParameters Static Methods:
    %       standard2Deg  - Create CIE 170-1:2006 2-degree standard observer.
    %       standard10Deg - Create CIE 170-1:2006 10-degree standard observer.
    %       fromGenotype  - Create observer from opsin genotype string.
    %
    %   Syntax:
    %       params = ObserverParameters()
    %       params = ObserverParameters(Age=45)
    %       params = ObserverParameters(FieldSize=2)
    %       params = ObserverParameters(LCone=PhotopigmentParameters(OpticalDensity=0.45))
    %       params = ObserverParameters.standard2Deg()
    %       params = ObserverParameters.standard10Deg()
    %
    %   EXAMPLE:
    %       std10 = ObserverParameters.standard10Deg();
    %       std2 = ObserverParameters.standard2Deg();
    %       custom = ObserverParameters(Age=50, FieldSize=10);
    %
    %   References:
    %       CIE 170-1:2006. Fundamental chromaticity diagram with physiological
    %       axes - Part 1. Vienna: CIE.
    %
    %       CIE 170-2:2015. Fundamental chromaticity diagram with physiological
    %       axes - Part 2. Vienna: CIE.
    %
    %       Stockman, A. & Sharpe, L.T. (2000). The spectral sensitivities of
    %       the middle- and long-wavelength-sensitive cones derived from
    %       measurements in observers of known genotype. Vision Research,
    %       40(13), 1711-1737.
    %
    %       Stockman, A. & Rider, A.T. (2023). Formulae for generating standard
    %       and individual human cone spectral sensitivity functions. Color
    %       Research and Application, 48(6), 818-840.

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada
    %
    % This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    % Licensed under AGPL-3.0-or-later. See LICENSE file for details.
    % Repository: https://github.com/sfu-cs-vision-lab/Individual-CMFs

    properties (Constant)
        % Default algorithm modes and opsin template selectors. These
        % constants are the single source of truth for these defaults;
        % the property defaults below, the constructor argument defaults,
        % and IndividualCMF's private-field defaults all reference them.
        % Keeps the two classes from drifting out of sync silently.
        DEFAULT_L_OPSIN_TEMPLATE = enums.LOpsinTemplate.Mean
        DEFAULT_M_OPSIN_TEMPLATE = enums.MOpsinTemplate.Mean
        DEFAULT_MACULAR_DENSITY_ALGORITHM = enums.MacularDensityAlgorithm.CIE170
        DEFAULT_PHOTOPIGMENT_DENSITY_ALGORITHM = enums.PhotopigmentDensityAlgorithm.CIE170
        DEFAULT_LENS_DENSITY_ALGORITHM = enums.LensDensityAlgorithm.Auto
    end

    properties
        % Photopigment parameters for L-cones (long-wavelength sensitive).
        % Includes optical density and any lambda-max shift from the standard
        % template. Default values are for the CIE 10-degree standard observer.
        LCone (1,1) PhotopigmentParameters = PhotopigmentParameters.standardL()

        % Photopigment parameters for M-cones (medium-wavelength sensitive).
        % Includes optical density and any lambda-max shift from the standard
        % template. Default values are for the CIE 10-degree standard observer.
        MCone (1,1) PhotopigmentParameters = PhotopigmentParameters.standardM()

        % Photopigment parameters for S-cones (short-wavelength sensitive).
        % Includes optical density and any lambda-max shift from the standard
        % template. Default values are for the CIE 10-degree standard observer.
        SCone (1,1) PhotopigmentParameters = PhotopigmentParameters.standardS()

        % Pre-receptoral lens filter parameters. The crystalline lens absorbs
        % short-wavelength light, with absorption increasing with age due to
        % yellowing. Default is standard lens density for the 32-year-old
        % observer (Density=1.0 is the neutral scaling factor that selects
        % the model's reference density).
        Lens (1,1) PreReceptoralFilter = PreReceptoralFilter(Type="lens", Density=1.0, Age=CIE170.STD_AGE)

        % Pre-receptoral macular pigment filter parameters. Lutein and
        % zeaxanthin concentrated in the fovea absorb blue light. The effective
        % density decreases with increasing field size due to reduced macular
        % pigment concentration outside the central fovea.
        Macular (1,1) PreReceptoralFilter = PreReceptoralFilter(Type="macular", Density=CIE170.STD_10DEG_MACULAR_DENSITY)

        % Observer age in years. Affects the lens pigment density through the
        % bi-linear aging model from Pokorny et al. (1987). The standard
        % observer age is 32 years per CIE 170-1:2006.
        Age (1,1) double {mustBePositive, mustBeFinite} = CIE170.STD_AGE

        % Visual field diameter in degrees. Determines the contribution of
        % macular pigment (which is concentrated in the central 2 degrees)
        % and affects photopigment optical densities. Default is 10 degrees
        % to match the default IndividualCMF behavior.
        FieldSize (1,1) double {mustBePositive, mustBeFinite} = CIE170.STD_FIELD_SIZE_10DEG

        % Photopigment template family for L/M absorbance shape. Round-tripped
        % through getParameters/setParameters so observer model choice is
        % preserved across parameter transfers.
        PhotopigmentModel (1,1) enums.PhotopigmentModel = enums.PhotopigmentModel.StockmanRider2023

        % Lens template family. Round-tripped through getParameters/
        % setParameters so observer model choice is preserved.
        LensModel (1,1) enums.LensModel = enums.LensModel.StockmanRider2023

        % Macular template family. Round-tripped through getParameters/
        % setParameters so observer model choice is preserved. Currently
        % only the Stockman & Rider 2023 / CIE 170-1:2006 macular shape is
        % published; the field is captured for forward compatibility.
        MacularModel (1,1) enums.MacularModel = enums.MacularModel.StockmanRider2023

        % L-cone opsin template variant. Mean is the weighted Ser180/Ala180
        % standard; Serine/Alanine select a single allele; MinL is used for
        % hybrid genotypes.
        L_OpsinTemplate (1,1) enums.LOpsinTemplate = ObserverParameters.DEFAULT_L_OPSIN_TEMPLATE

        % M-cone opsin template variant. Mean/Standard are the standard
        % templates; LinM is used for hybrid genotypes.
        M_OpsinTemplate (1,1) enums.MOpsinTemplate = ObserverParameters.DEFAULT_M_OPSIN_TEMPLATE

        % Strategy for computing macular pigment density. CIE170 uses
        % the tabulated 2/10 deg standard values; MorelandAlexander uses the
        % formula for arbitrary field sizes; Custom preserves the explicit
        % Macular.Density value.
        MacularDensityAlgorithm (1,1) enums.MacularDensityAlgorithm = ObserverParameters.DEFAULT_MACULAR_DENSITY_ALGORITHM

        % Strategy for computing photopigment optical density. CIE170
        % uses the tabulated 2/10 deg standard values; PokornySmith uses the
        % formula for arbitrary field sizes; Custom preserves the explicit
        % LCone/MCone/SCone optical densities.
        PhotopigmentDensityAlgorithm (1,1) enums.PhotopigmentDensityAlgorithm = ObserverParameters.DEFAULT_PHOTOPIGMENT_DENSITY_ALGORITHM

        % Strategy for the lens density at 400 nm. Auto recomputes from
        % LensModel x Age whenever those change; Custom preserves the
        % explicit Lens.Density value.
        LensDensityAlgorithm (1,1) enums.LensDensityAlgorithm = ObserverParameters.DEFAULT_LENS_DENSITY_ALGORITHM
    end

    methods
        function obj = ObserverParameters(options)
            % OBSERVERPARAMETERS  Construct observer parameters.
            %
            %   params = ObserverParameters() creates parameters for the
            %   CIE 170-1:2006 10-degree standard observer (the default).
            %
            %   params = ObserverParameters(Name, Value) creates parameters
            %   with specified values.
            %
            %   OPTIONAL INPUTS (Name-Value arguments):
            %       LCone     - L-cone parameters (PhotopigmentParameters)
            %       MCone     - M-cone parameters (PhotopigmentParameters)
            %       SCone     - S-cone parameters (PhotopigmentParameters)
            %       Lens      - Lens filter parameters (PreReceptoralFilter)
            %       Macular   - Macular filter parameters (PreReceptoralFilter)
            %       Age       - Observer age in years (double)
            %       FieldSize - Visual field size in degrees (double)
            %
            %   OUTPUTS:
            %       params - New parameter object (ObserverParameters)
            arguments
                options.LCone (1,1) PhotopigmentParameters = PhotopigmentParameters.standardL()
                options.MCone (1,1) PhotopigmentParameters = PhotopigmentParameters.standardM()
                options.SCone (1,1) PhotopigmentParameters = PhotopigmentParameters.standardS()
                options.Lens (1,1) PreReceptoralFilter = PreReceptoralFilter(Type="lens", Density=1.0, Age=CIE170.STD_AGE)
                options.Macular (1,1) PreReceptoralFilter = PreReceptoralFilter(Type="macular", Density=CIE170.STD_10DEG_MACULAR_DENSITY)
                options.Age (1,1) double {mustBePositive, mustBeFinite} = CIE170.STD_AGE
                options.FieldSize (1,1) double {mustBePositive, mustBeFinite} = CIE170.STD_FIELD_SIZE_10DEG
                options.PhotopigmentModel (1,1) enums.PhotopigmentModel = enums.PhotopigmentModel.StockmanRider2023
                options.LensModel (1,1) enums.LensModel = enums.LensModel.StockmanRider2023
                options.MacularModel (1,1) enums.MacularModel = enums.MacularModel.StockmanRider2023
                options.L_OpsinTemplate (1,1) enums.LOpsinTemplate = ObserverParameters.DEFAULT_L_OPSIN_TEMPLATE
                options.M_OpsinTemplate (1,1) enums.MOpsinTemplate = ObserverParameters.DEFAULT_M_OPSIN_TEMPLATE
                options.MacularDensityAlgorithm (1,1) enums.MacularDensityAlgorithm = ObserverParameters.DEFAULT_MACULAR_DENSITY_ALGORITHM
                options.PhotopigmentDensityAlgorithm (1,1) enums.PhotopigmentDensityAlgorithm = ObserverParameters.DEFAULT_PHOTOPIGMENT_DENSITY_ALGORITHM
                options.LensDensityAlgorithm (1,1) enums.LensDensityAlgorithm = ObserverParameters.DEFAULT_LENS_DENSITY_ALGORITHM
            end

            obj.LCone = options.LCone;
            obj.MCone = options.MCone;
            obj.SCone = options.SCone;
            obj.Lens = options.Lens;
            obj.Macular = options.Macular;
            obj.Age = options.Age;
            obj.FieldSize = options.FieldSize;
            obj.PhotopigmentModel = options.PhotopigmentModel;
            obj.LensModel = options.LensModel;
            obj.MacularModel = options.MacularModel;
            obj.L_OpsinTemplate = options.L_OpsinTemplate;
            obj.M_OpsinTemplate = options.M_OpsinTemplate;
            obj.MacularDensityAlgorithm = options.MacularDensityAlgorithm;
            obj.PhotopigmentDensityAlgorithm = options.PhotopigmentDensityAlgorithm;
            obj.LensDensityAlgorithm = options.LensDensityAlgorithm;
        end

        function tf = isStandardConfiguration(obj)
            % ISSTANDARDCONFIGURATION  Check if parameters match CIE standard.
            %
            %   tf = params.isStandardConfiguration() returns true if all
            %   parameters exactly match either the CIE 170-1:2006 2-degree
            %   or 10-degree standard observer specification.
            %
            %   The check verifies:
            %   - Field size is exactly 2 or 10 degrees
            %   - Age is exactly 32 years
            %   - All cone optical densities match the standard for that field size
            %   - All lambda-max shifts are zero
            %   - Lens density scaling is 1.0 with standard age
            %   - Macular density matches the standard for that field size
            %
            %   OUTPUTS:
            %       tf - True if configuration matches CIE standard (logical)
            arguments
                obj
            end

            tf = obj.isStandard2Deg() || obj.isStandard10Deg();
        end
    end

    methods (Static)
        function params = standard2Deg()
            % STANDARD2DEG  Create CIE 170-1:2006 2-degree standard observer.
            %
            %   params = ObserverParameters.standard2Deg() returns an
            %   ObserverParameters object configured with the CIE 170-1:2006
            %   standard values for the 2-degree observer:
            %   - L-cone optical density: 0.50
            %   - M-cone optical density: 0.50
            %   - S-cone optical density: 0.40
            %   - Macular density at 460nm: 0.350
            %   - Age: 32 years
            %   - Field size: 2 degrees
            %
            %   OUTPUTS:
            %       params - 2-degree standard observer (ObserverParameters)
            lCone = PhotopigmentParameters( ...
                OpticalDensity=CIE170.STD_2DEG_L_OPTICAL_DENSITY, ...
                LambdaMaxShift=0);
            mCone = PhotopigmentParameters( ...
                OpticalDensity=CIE170.STD_2DEG_M_OPTICAL_DENSITY, ...
                LambdaMaxShift=0);
            sCone = PhotopigmentParameters( ...
                OpticalDensity=CIE170.STD_2DEG_S_OPTICAL_DENSITY, ...
                LambdaMaxShift=0);

            lens = PreReceptoralFilter( ...
                Type="lens", ...
                Density=1.0, ...
                Age=CIE170.STD_AGE);

            macular = PreReceptoralFilter( ...
                Type="macular", ...
                Density=CIE170.STD_2DEG_MACULAR_DENSITY);

            params = ObserverParameters( ...
                LCone=lCone, ...
                MCone=mCone, ...
                SCone=sCone, ...
                Lens=lens, ...
                Macular=macular, ...
                Age=CIE170.STD_AGE, ...
                FieldSize=CIE170.STD_FIELD_SIZE_2DEG);
        end

        function params = standard10Deg()
            % STANDARD10DEG  Create CIE 170-1:2006 10-degree standard observer.
            %
            %   params = ObserverParameters.standard10Deg() returns an
            %   ObserverParameters object configured with the CIE 170-1:2006
            %   standard values for the 10-degree observer:
            %   - L-cone optical density: 0.38
            %   - M-cone optical density: 0.38
            %   - S-cone optical density: 0.30
            %   - Macular density at 460nm: 0.095
            %   - Age: 32 years
            %   - Field size: 10 degrees
            %
            %   OUTPUTS:
            %       params - 10-degree standard observer (ObserverParameters)
            lCone = PhotopigmentParameters( ...
                OpticalDensity=CIE170.STD_10DEG_L_OPTICAL_DENSITY, ...
                LambdaMaxShift=0);
            mCone = PhotopigmentParameters( ...
                OpticalDensity=CIE170.STD_10DEG_M_OPTICAL_DENSITY, ...
                LambdaMaxShift=0);
            sCone = PhotopigmentParameters( ...
                OpticalDensity=CIE170.STD_10DEG_S_OPTICAL_DENSITY, ...
                LambdaMaxShift=0);

            lens = PreReceptoralFilter( ...
                Type="lens", ...
                Density=1.0, ...
                Age=CIE170.STD_AGE);

            macular = PreReceptoralFilter( ...
                Type="macular", ...
                Density=CIE170.STD_10DEG_MACULAR_DENSITY);

            params = ObserverParameters( ...
                LCone=lCone, ...
                MCone=mCone, ...
                SCone=sCone, ...
                Lens=lens, ...
                Macular=macular, ...
                Age=CIE170.STD_AGE, ...
                FieldSize=CIE170.STD_FIELD_SIZE_10DEG);
        end

        function params = fromGenotype(genotypeString)
            % FROMGENOTYPE  Create observer parameters from opsin genotype.
            %
            %   params = ObserverParameters.fromGenotype(genotypeString)
            %   creates an ObserverParameters value object with lambda-max
            %   shifts computed from the specified opsin genotype, using
            %   the same Stockman & Rider 2023 Table 3 dictionary as the
            %   Genotype class.
            %
            %   The genotype string is a semicolon-separated list of
            %   "Cone_Position_AminoAcid" entries (per-position partial
            %   override syntax). Unknown entries are silently ignored;
            %   absent cones are NOT zeroed (this is the partial-override
            %   convention, not a complete-genotype specification).
            %
            %   This is one of several genotype entry points. Most users
            %   should prefer:
            %     - IndividualCMF(Genotype=struct('L_180', 'Ala')) for
            %       partial overrides on a normal observer.
            %     - IndividualCMF(Genotype="LIAVA/SIAVA") /
            %       obs.applyGenotype("LIAVA/SIAVA") for complete 5-letter
            %       genotypes that can express dichromacy via empty sides.
            %   fromGenotype is kept for round-trip compatibility with
            %   parameter-object snapshots that recorded a semicolon
            %   string.
            %
            %   Key polymorphic positions:
            %   - Position 180: Ser/Ala affects L-cone lambda-max by ~4nm
            %   - Position 277: Tyr/Phe affects lambda-max by ~7nm
            %   - Position 285: Thr/Ala affects lambda-max by ~14nm
            %
            %   INPUTS:
            %       genotypeString - Genotype specification, e.g., (string)
            %           "L_180_Ser;L_277_Tyr;L_285_Thr" for serine at 180,
            %           tyrosine at 277, and threonine at 285 in L-cone opsin.
            %
            %   OUTPUTS:
            %       params - Observer with computed shifts (ObserverParameters)
            %
            %   EXAMPLE:
            %       params = ObserverParameters.fromGenotype("L_180_Ala");
            %       params = ObserverParameters.fromGenotype("L_180_Ser;M_180_Ser");
            arguments
                genotypeString (1,1) string
            end

            % Start with standard 10-degree observer as base
            params = ObserverParameters.standard10Deg();

            if strlength(genotypeString) == 0
                return
            end

            % Genotype shift lookup and scaling constants are owned by the
            % Genotype class (Stockman & Rider 2023, Table 3, with pycone
            % parity scaling). Use those directly so this older
            % semicolon-syntax path stays in sync with the rest of the
            % toolbox's genotype machinery.
            genotypeShifts = Genotype.GENOTYPE_SHIFTS;
            mScale = Genotype.LSER_MLMAX_DIFF / Genotype.M_BASES_SUM;
            lScale = Genotype.LSER_MLMAX_DIFF / Genotype.L_BASES_SUM;

            % Parse the genotype string into individual entries
            entries = strsplit(genotypeString, ";");

            % Track shifts for L and M cones
            lShift = 0;
            mShift = 0;

            % Process each genotype entry
            for i = 1:numel(entries)
                entry = strtrim(entries{i});
                if strlength(entry) == 0
                    continue
                end

                % Look up the shift value
                if isKey(genotypeShifts, entry)
                    baseShift = genotypeShifts(entry);

                    % Determine which cone this affects
                    if startsWith(entry, "L_")
                        lShift = lShift + (baseShift * lScale);
                    elseif startsWith(entry, "M_")
                        mShift = mShift + (baseShift * mScale);
                    end
                end
            end

            % Apply computed shifts to cone parameters
            params.LCone = PhotopigmentParameters( ...
                OpticalDensity=CIE170.STD_10DEG_L_OPTICAL_DENSITY, ...
                LambdaMaxShift=lShift);
            params.MCone = PhotopigmentParameters( ...
                OpticalDensity=CIE170.STD_10DEG_M_OPTICAL_DENSITY, ...
                LambdaMaxShift=mShift);
        end
    end

    methods (Access = private)
        function tf = isStandard2Deg(obj)
            % ISSTANDARD2DEG  Check if parameters match 2-degree standard.
            %
            %   Internal helper method that checks all parameters against
            %   the CIE 170-1:2006 2-degree standard observer specification.
            arguments
                obj
            end

            tf = obj.FieldSize == CIE170.STD_FIELD_SIZE_2DEG && ...
                 obj.Age == CIE170.STD_AGE && ...
                 obj.LCone.OpticalDensity == CIE170.STD_2DEG_L_OPTICAL_DENSITY && ...
                 obj.LCone.LambdaMaxShift == 0 && ...
                 obj.MCone.OpticalDensity == CIE170.STD_2DEG_M_OPTICAL_DENSITY && ...
                 obj.MCone.LambdaMaxShift == 0 && ...
                 obj.SCone.OpticalDensity == CIE170.STD_2DEG_S_OPTICAL_DENSITY && ...
                 obj.SCone.LambdaMaxShift == 0 && ...
                 obj.Lens.Density == 1.0 && ...
                 obj.Lens.Age == CIE170.STD_AGE && ...
                 obj.Macular.Density == CIE170.STD_2DEG_MACULAR_DENSITY;
        end

        function tf = isStandard10Deg(obj)
            % ISSTANDARD10DEG  Check if parameters match 10-degree standard.
            %
            %   Internal helper method that checks all parameters against
            %   the CIE 170-1:2006 10-degree standard observer specification.
            arguments
                obj
            end

            tf = obj.FieldSize == CIE170.STD_FIELD_SIZE_10DEG && ...
                 obj.Age == CIE170.STD_AGE && ...
                 obj.LCone.OpticalDensity == CIE170.STD_10DEG_L_OPTICAL_DENSITY && ...
                 obj.LCone.LambdaMaxShift == 0 && ...
                 obj.MCone.OpticalDensity == CIE170.STD_10DEG_M_OPTICAL_DENSITY && ...
                 obj.MCone.LambdaMaxShift == 0 && ...
                 obj.SCone.OpticalDensity == CIE170.STD_10DEG_S_OPTICAL_DENSITY && ...
                 obj.SCone.LambdaMaxShift == 0 && ...
                 obj.Lens.Density == 1.0 && ...
                 obj.Lens.Age == CIE170.STD_AGE && ...
                 obj.Macular.Density == CIE170.STD_10DEG_MACULAR_DENSITY;
        end
    end
end

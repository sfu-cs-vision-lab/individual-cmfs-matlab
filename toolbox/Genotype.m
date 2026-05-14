classdef Genotype
    % GENOTYPE  Parse opsin gene variant strings and compute lambda-max shifts.
    %
    %   This value class parses opsin gene variant strings in the standard
    %   notation (e.g., "LSAYT/SAAFA") and computes the corresponding
    %   lambda-max shifts for L and M cones. This enables computing
    %   individualized color matching functions from genetic data.
    %
    %   Human L and M cone opsins are encoded on the X chromosome.
    %   Polymorphisms at key amino acid positions cause spectral shifts.
    %   The 5-letter genotype notation represents amino acids at positions
    %   116, 180, 230, 277, and 285. For example, "LSAYT" means:
    %       Position 116: L (Leucine)
    %       Position 180: S (Serine)
    %       Position 230: A (Alanine)
    %       Position 277: Y (Tyrosine)
    %       Position 285: T (Threonine)
    %
    %   The shift coefficients come from Stockman & Rider (2023) Table 3
    %   and represent the spectral shift in nanometers relative to the
    %   standard template when a specific amino acid is present at a
    %   given position.
    %
    %   Genotype Properties:
    %       LGenotype      - L-cone genotype string (e.g., 'LSAYT').
    %       MGenotype      - M-cone genotype string (e.g., 'SAAFA').
    %       LShift         - Computed lambda-max shift for L-cone (nm).
    %       MShift         - Computed lambda-max shift for M-cone (nm).
    %       ColorVisionType - Classification: "trichromat", "deuteranope", or "protanope".
    %
    %   Genotype Methods:
    %       Genotype          - Constructor that parses genotype string.
    %       toObserverParameters - Convert to IndividualCMF with computed shifts.
    %
    %   Syntax:
    %       g = Genotype("LSAYT/SAAFA")     % Pycone-default normal trichromat
    %       g = Genotype("LSAYT")           % Deuteranope (L-cone only)
    %       g = Genotype("/SAAFA")          % Protanope (M-cone only)
    %
    %   EXAMPLE:
    %       g = Genotype("LSAYT/SAAFA");
    %       disp(g.LShift);         % Display L-cone shift
    %       disp(g.ColorVisionType) % "trichromat"
    %       obs = g.toObserverParameters(Age=32, FieldSize=10);
    %
    %   References:
    %       Stockman, A. & Rider, A.T. (2023). Formulae for generating standard
    %       and individual human cone spectral sensitivities. Color Research
    %       and Application, 48(6), 818-840. doi:10.1002/col.22879. (Table 3.)
    %
    %       Stockman, A. & Sharpe, L.T. (2000). The spectral sensitivities of
    %       the middle- and long-wavelength-sensitive cones derived from
    %       measurements in observers of known genotype. Vision Research,
    %       40(13), 1711-1737.

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada
    %
    % This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    % Licensed under AGPL-3.0-or-later. See LICENSE file for details.
    % Repository: https://github.com/sfu-cs-vision-lab/Individual-CMFs

    properties (SetAccess = private)
        % L-cone genotype string representing amino acids at positions
        % 116, 180, 230, 277, 285. Empty if L-cone is absent (protanopia).
        LGenotype (1,:) char

        % M-cone genotype string representing amino acids at positions
        % 116, 180, 230, 277, 285. Empty if M-cone is absent (deuteranopia).
        MGenotype (1,:) char

        % Computed lambda-max shift for L-cone in nanometers. This shift
        % is applied to the L-cone template to model the effect of the
        % specific amino acid polymorphisms encoded in LGenotype.
        LShift (1,1) double {mustBeFinite} = 0

        % Computed lambda-max shift for M-cone in nanometers. This shift
        % is applied to the M-cone template to model the effect of the
        % specific amino acid polymorphisms encoded in MGenotype.
        MShift (1,1) double {mustBeFinite} = 0

        % Color vision classification based on the genotype. Returns one
        % of: "trichromat" (normal), "deuteranope" (M-cone deficient),
        % or "protanope" (L-cone deficient).
        ColorVisionType (1,1) string = "trichromat"
    end

    properties (Constant)
        % Genotype shift coefficients. Keys are formatted as
        % "Cone_Position_AminoAcid" and values are the base shift in nanometers
        % before scaling. These shifts are then scaled by the ratio of the
        % L-Serine/L-Alanine peak difference to the sum of basis weights for
        % each cone type.
        % Source: Stockman & Rider (2023), Table 3.
        %
        % Positions 233 and 309 carry zero-shift entries for completeness with
        % the published table; the 5-letter notation parser (POSITIONS) does
        % not reach them, so they are inert under the current API.
        GENOTYPE_SHIFTS = dictionary( ...
            "M_116_Ser", 0.0, ...
            "M_180_Ser", 3.0, ...
            "M_180_Ala", 0.0, ...
            "M_230_Ile", 3.0, ...
            "M_230_Ala", 0.0, ...
            "M_233_Ala", 0.0, ...
            "M_277_Tyr", 7.0, ...
            "M_277_Phe", 0.0, ...
            "M_285_Thr", 14.0, ...
            "M_285_Ala", 0.0, ...
            "M_309_Tyr", 0.0, ...
            "L_116_Tyr", -3.0, ...
            "L_116_Leu", 0.0, ...
            "L_180_Ala", -4.0, ...
            "L_180_Ser", 0.0, ...
            "L_230_Thr", -3.0, ...
            "L_230_Ala", 0.0, ...
            "L_233_Ser", 0.0, ...
            "L_277_Phe", -7.0, ...
            "L_277_Tyr", 0.0, ...
            "L_285_Ala", -14.0, ...
            "L_285_Thr", 0.0, ...
            "L_309_Phe", 0.0 ...
        )

        % Mapping from single-letter amino acid codes to three-letter codes.
        % Standard IUPAC nomenclature for the 20 common amino acids.
        AMINO_ACID_MAP = dictionary( ...
            'A', "Ala", ...
            'C', "Cys", ...
            'D', "Asp", ...
            'E', "Glu", ...
            'F', "Phe", ...
            'G', "Gly", ...
            'H', "His", ...
            'I', "Ile", ...
            'K', "Lys", ...
            'L', "Leu", ...
            'M', "Met", ...
            'N', "Asn", ...
            'P', "Pro", ...
            'Q', "Gln", ...
            'R', "Arg", ...
            'S', "Ser", ...
            'T', "Thr", ...
            'V', "Val", ...
            'W', "Trp", ...
            'Y', "Tyr" ...
        )

        % Amino acid positions encoded in the 5-letter genotype notation.
        % These are the key spectral tuning sites identified through analysis
        % of hybrid opsin genes.
        % Source: Stockman, Sharpe, Jagle, et al. (1998); Stockman & Rider (2023).
        POSITIONS = [116, 180, 230, 277, 285]

        % L(Serine)-to-M lambda_max gap used to scale the raw shift
        % coefficients to nanometers. The 23.67 nm value is a pycone
        % parity convention (LMStemplateCMFs.py: Lser_Mlmax_diff =
        % Lserlmax_template - Mlmax_template = 554.86 - 531.19 = 23.67),
        % not a value prescribed by S&R 2023 p. 826. The toolbox's own
        % numerical L(Ser)-M gap is 23.31 nm; preserving 23.67 keeps
        % the genotype-derived shifts identical to pycone output.
        LSER_MLMAX_DIFF = 23.67

        % Sum of absolute basis weights for M-cone genotype shifts.
        % The raw shift coefficients are scaled by
        % (LSER_MLMAX_DIFF / M_BASES_SUM) so that a hypothetical M-cone
        % with every codon at its L-cone value would shift by the full
        % L-M gap. This scaling is a pycone convention
        % (LMStemplateCMFs.py: M_L_scale = Lser_Mlmax_diff /
        % M_L_allbaseshifts), not prescribed by S&R 2023 Table 3.
        M_BASES_SUM = 27

        % Sum of absolute basis weights for L-cone genotype shifts.
        % Same pycone-derived convention as M_BASES_SUM.
        % (pycone LMStemplateCMFs.py: L_M_scale = -Lser_Mlmax_diff /
        % L_M_allbaseshifts.)
        L_BASES_SUM = 31
    end

    methods
        function obj = Genotype(genotypeString)
            % GENOTYPE  Construct a Genotype object from a genotype string.
            %
            %   g = Genotype(genotypeString) parses the genotype string and
            %   computes the corresponding lambda-max shifts for L and M cones.
            %
            %   The genotype string format is "L-geno/M-geno" where each geno
            %   is a 5-character string representing amino acids at positions
            %   116, 180, 230, 277, and 285. For dichromats, one part may be
            %   empty (e.g., "/SAAFA" for protanope or "LSAYT/" for deuteranope).
            %
            %   INPUTS:
            %       genotypeString - Genotype in "L/M" format (string or char)
            %
            %   OUTPUTS:
            %       g - Genotype object with computed shifts (Genotype)
            %
            %   EXAMPLE:
            %       g = Genotype("LSAYT/SAAFA");  % Pycone-default normal trichromat
            %       g = Genotype("LSAYT");        % Deuteranope (L-cone only)
            arguments
                genotypeString (1,:) {mustBeTextScalar}
            end

            [lGeno, mGeno] = obj.parseString(genotypeString);

            obj.LGenotype = lGeno;
            obj.MGenotype = mGeno;

            if ~isempty(lGeno)
                obj.LShift = obj.computeShift(lGeno, 'L');
            end

            if ~isempty(mGeno)
                obj.MShift = obj.computeShift(mGeno, 'M');
            end

            obj.ColorVisionType = obj.determineColorVisionType();
        end

        function obs = toObserverParameters(obj, options)
            % TOOBSERVERPARAMETERS  Convert genotype to an IndividualCMF observer.
            %
            %   obs = g.toObserverParameters() creates an IndividualCMF observer
            %   with lambda-max shifts computed from the genotype. Uses default
            %   Age (32) and FieldSize (10) values.
            %
            %   obs = g.toObserverParameters(Name, Value) creates an observer
            %   with specified Age and/or FieldSize.
            %
            %   For one-sided genotypes the absent cone's optical density
            %   is set to zero, so a deuteranope (LGenotype only, MGenotype
            %   empty) returns an observer with Mod=0 and a protanope
            %   (MGenotype only, LGenotype empty) with Lod=0. This matches
            %   the ColorVisionType classification.
            %
            %   OPTIONAL INPUTS (Name-Value arguments):
            %       Age       - Observer age in years (double) Default: 32
            %       FieldSize - Visual field size in degrees (double) Default: 10
            %
            %   OUTPUTS:
            %       obs - Observer with genotype-derived shifts (IndividualCMF)
            %
            %   EXAMPLE:
            %       g = Genotype("LSAYT/SAAFA");
            %       obs = g.toObserverParameters(Age=45, FieldSize=2);
            arguments
                obj
                options.Age (1,1) double {mustBePositive, mustBeFinite} = 32
                options.FieldSize (1,1) double {mustBePositive, mustBeFinite} = 10
            end

            obs = IndividualCMF(Age=options.Age, FieldSize=options.FieldSize);
            obs.applyGenotypeShifts(obj);
        end

        function tf = isLHybrid(obj)
            % ISLHYBRID  Check if L-cone has M-in-L hybrid characteristics.
            %
            %   The L-cone is considered a hybrid (M-in-L) when it has the
            %   M-cone amino acids at positions 277 (Phe) and 285 (Ala).
            %   This combination produces an L-cone with spectral sensitivity
            %   shifted toward shorter wavelengths.
            %
            %   OUTPUTS:
            %       tf - True if L-cone is M-in-L hybrid (logical)
            tf = false;

            if isempty(obj.LGenotype)
                return;
            end

            aa277 = Genotype.AMINO_ACID_MAP(obj.LGenotype(4));
            aa285 = Genotype.AMINO_ACID_MAP(obj.LGenotype(5));

            tf = (aa277 == "Phe") && (aa285 == "Ala");
        end

        function tf = isMHybrid(obj)
            % ISMHYBRID  Check if M-cone has L-in-M hybrid characteristics.
            %
            %   The M-cone is considered a hybrid (L-in-M) when it has the
            %   L-cone amino acids at positions 277 (Tyr) and 285 (Thr).
            %   This combination produces an M-cone with spectral sensitivity
            %   shifted toward longer wavelengths.
            %
            %   OUTPUTS:
            %       tf - True if M-cone is L-in-M hybrid (logical)
            tf = false;

            if isempty(obj.MGenotype)
                return;
            end

            aa277 = Genotype.AMINO_ACID_MAP(obj.MGenotype(4));
            aa285 = Genotype.AMINO_ACID_MAP(obj.MGenotype(5));

            tf = (aa277 == "Tyr") && (aa285 == "Thr");
        end
    end

    methods (Access = private)
        function [lGeno, mGeno] = parseString(~, s)
            % PARSESTRING  Split genotype string into L and M components.
            %
            %   Parses the genotype string in "L-geno/M-geno" format. If no
            %   slash is present, the string is interpreted as an L-cone
            %   genotype only (deuteranope). Empty components indicate
            %   missing cones.
            %
            %   INPUTS:
            %       s - Genotype string to parse (string or char)
            %
            %   OUTPUTS:
            %       lGeno - L-cone genotype (empty if absent) (char)
            %       mGeno - M-cone genotype (empty if absent) (char)
            s = char(s);

            slashIdx = find(s == '/', 1);

            if isempty(slashIdx)
                lGeno = strtrim(s);
                mGeno = '';
            else
                lGeno = strtrim(s(1:slashIdx-1));
                mGeno = strtrim(s(slashIdx+1:end));
            end

            if ~isempty(lGeno) && length(lGeno) ~= 5
                error('Genotype:InvalidFormat', ...
                    'L-cone genotype must be exactly 5 characters, got %d.', length(lGeno));
            end

            if ~isempty(mGeno) && length(mGeno) ~= 5
                error('Genotype:InvalidFormat', ...
                    'M-cone genotype must be exactly 5 characters, got %d.', length(mGeno));
            end

            if ~isempty(lGeno)
                for i = 1:length(lGeno)
                    if ~isKey(Genotype.AMINO_ACID_MAP, lGeno(i))
                        error('Genotype:InvalidAminoAcid', ...
                            'Invalid amino acid code "%s" in L-cone genotype.', lGeno(i));
                    end
                end
            end

            if ~isempty(mGeno)
                for i = 1:length(mGeno)
                    if ~isKey(Genotype.AMINO_ACID_MAP, mGeno(i))
                        error('Genotype:InvalidAminoAcid', ...
                            'Invalid amino acid code "%s" in M-cone genotype.', mGeno(i));
                    end
                end
            end
        end

        function shift = computeShift(obj, geno, coneType)
            % COMPUTESHIFT  Compute lambda-max shift from genotype.
            %
            %   Iterates through the amino acids at each position and looks
            %   up the corresponding shift coefficient from GENOTYPE_SHIFTS.
            %   The raw shifts are scaled by the appropriate factor based
            %   on cone type.
            %
            %   INPUTS:
            %       geno     - 5-character genotype string (char)
            %       coneType - 'L' or 'M' (char)
            %
            %   OUTPUTS:
            %       shift - Total lambda-max shift in nanometers (double)
            arguments
                obj
                geno (1,5) char
                coneType (1,1) char {mustBeMember(coneType, {'L', 'M'})}
            end

            if coneType == 'M'
                scale = obj.LSER_MLMAX_DIFF / obj.M_BASES_SUM;
            else
                scale = obj.LSER_MLMAX_DIFF / obj.L_BASES_SUM;
            end

            total = 0;

            for i = 1:5
                pos = obj.POSITIONS(i);
                aaCode = geno(i);

                aaThreeLetter = obj.AMINO_ACID_MAP(aaCode);

                lookupKey = sprintf("%s_%d_%s", coneType, pos, aaThreeLetter);

                if isKey(obj.GENOTYPE_SHIFTS, lookupKey)
                    shiftVal = obj.GENOTYPE_SHIFTS(lookupKey);
                    total = total + (shiftVal * scale);
                end
            end

            shift = total;
        end

        function cvType = determineColorVisionType(obj)
            % DETERMINECOLORVISIONTYPE  Classify color vision type.
            %
            %   Determines whether the genotype represents a trichromat,
            %   deuteranope, or protanope based on the presence/absence
            %   of L and M cone genotypes.
            %
            %   OUTPUTS:
            %       cvType - "trichromat", "deuteranope", or "protanope" (string)
            hasL = ~isempty(obj.LGenotype);
            hasM = ~isempty(obj.MGenotype);

            if hasL && hasM
                cvType = "trichromat";
            elseif hasL && ~hasM
                cvType = "deuteranope";
            elseif ~hasL && hasM
                cvType = "protanope";
            else
                cvType = "achromat";
            end
        end

    end
end

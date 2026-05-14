classdef PreReceptoralStage
    % PRERECEPTORALSTAGE  Pure-function pipeline stage for pre-receptoral filtering.
    %
    %   Stage 2 of the LMS compute pipeline. Applies lens and macular
    %   pigment filtering to the retinal absorptance from Stage 1,
    %   yielding corneal quantal sensitivity.
    %
    %   This class has no state -- the single static method takes pure
    %   inputs (absorptance, wavelengths, lens template + density,
    %   macular template + density, observer age) and returns the
    %   filtered output. Templates are passed as arguments rather than
    %   resolved from observer state, so the stage can be tested without
    %   instantiating IndividualCMF.
    %
    %   PreReceptoralStage Methods (Static):
    %       applyFilters          - High-level: resolve template shapes from
    %                               LensTemplate/MacularTemplate, scale by
    %                               densities, apply transmission.
    %       corneaFromAbsorptance - Bare math primitive: retinal absorptance +
    %                               pre-scaled lens/macular density spectra ->
    %                               corneal quantal sensitivity.
    %
    %   See also: pipeline.PhotopigmentStage, pipeline.OutputStage,
    %             LensTemplate, MacularTemplate, IndividualCMF.

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada
    %
    % This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    % Licensed under AGPL-3.0-or-later. See LICENSE file for details.
    % Repository: https://github.com/sfu-cs-vision-lab/Individual-CMFs

    methods (Static)
        function quantal = applyFilters(absorptance, wavelengths, options)
            % APPLYFILTERS  Apply lens x macular filtering.
            %
            %   quantal = pipeline.PreReceptoralStage.applyFilters(
            %       absorptance, wavelengths, ...
            %       LensTemplate=lens, LensDensity=lensDensity, ...
            %       MacularTemplate=macular, MacularDensity=macularDensity, ...
            %       Age=age)
            %   returns corneal quantal sensitivity for the cone whose
            %   retinal absorptance is provided.
            %
            %   Templates supply normalized shapes (peak == 1) which are
            %   scaled by the observer's peak densities, then exponentiated
            %   as transmission factors and applied to the absorptance.
            %
            %   The lens and macular template + density pairs are passed as
            %   required Name=Value arguments rather than positional, so
            %   the call site is self-documenting and the signature stays
            %   under the project's six-positional-arg guideline.
            %
            %   INPUTS:
            %       absorptance - Retinal absorptance from Stage 1 (column vector)
            %       wavelengths - Wavelengths in nm (column vector)
            %
            %   REQUIRED Name-Value arguments:
            %       LensTemplate    - LensTemplate strategy instance
            %       LensDensity     - Lens optical density at 400 nm (scalar)
            %       MacularTemplate - MacularTemplate strategy instance
            %       MacularDensity  - Macular optical density at peak (scalar)
            %       Age             - Observer age in years; only consumed
            %                         by age-dependent lens templates (scalar)
            %       FieldSize       - Observer field size in degrees; only
            %                         consumed by lens templates that model
            %                         field-size-dependent scattering (van
            %                         de Kraats & van Norren 2007) (scalar)
            %
            %   OUTPUTS:
            %       quantal - Corneal quantal sensitivity (column vector)
            arguments
                absorptance (:,1) double
                wavelengths (:,1) double
                options.LensTemplate (1,1) LensTemplate
                options.LensDensity (1,1) double
                options.MacularTemplate (1,1) MacularTemplate
                options.MacularDensity (1,1) double
                options.Age (1,1) double
                options.FieldSize (1,1) double = NaN
            end

            macularShape = options.MacularTemplate.computeTemplate(wavelengths);
            lensShape = options.LensTemplate.computeTemplate(wavelengths, options.Age, ...
                FieldSize=options.FieldSize);

            macScaled = options.MacularDensity * macularShape;
            lensScaled = options.LensDensity * lensShape;

            quantal = pipeline.PreReceptoralStage.corneaFromAbsorptance(absorptance, macScaled, lensScaled);
        end

        function quantal = corneaFromAbsorptance(absorptance, mac, lens)
            % CORNEAFROMABSORPTANCE  Apply pre-receptoral filtering to retinal absorptance.
            %
            %   quantal = pipeline.PreReceptoralStage.corneaFromAbsorptance(
            %       absorptance, mac, lens) returns corneal-domain quantal
            %   sensitivity by attenuating retinal absorptance with
            %   already-scaled macular and lens density spectra:
            %
            %       quantal = absorptance .* 10^(-mac) .* 10^(-lens)
            %
            %   This is a bare math primitive: callers are expected to
            %   have already multiplied each density template by its
            %   observer-specific peak density. The higher-level
            %   applyFilters() does that template-resolution work and
            %   then calls this; prefer it for the normal pipeline path.
            %
            %   The function is exposed because the cornea-from-absorptance
            %   conversion is a recognized primitive in the cone-fundamental
            %   literature; having it as a named function makes the math
            %   directly callable from parity tests, alternative pipelines,
            %   and analyses that bypass the IndividualCMF orchestrator.
            %
            %   INPUTS:
            %       absorptance - Retinal absorptance (column vector, 0..1)
            %       mac - Pre-scaled macular density spectrum (column vector)
            %       lens - Pre-scaled lens density spectrum (column vector)
            %
            %   OUTPUTS:
            %       quantal - Corneal quantal sensitivity (column vector)
            arguments
                absorptance (:,1) double
                mac (:,1) double
                lens (:,1) double
            end

            quantal = absorptance .* 10.^(-mac) .* 10.^(-lens);
        end
    end
end

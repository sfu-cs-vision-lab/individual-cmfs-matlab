classdef (Abstract) PhotopigmentTemplate < handle
    % PHOTOPIGMENTTEMPLATE  Abstract base class for photopigment absorbance templates.
    %
    %   This class defines the interface for photopigment template strategies used
    %   in the IndividualCMF model. Subclasses implement specific template models
    %   such as Stockman & Rider (2023) or Govardovskii et al. (2000).
    %
    %   PhotopigmentTemplate Abstract Properties:
    %       Name          - Full name of the template model.
    %       ShortName     - Short identifier for the template model.
    %
    %   PhotopigmentTemplate Abstract Properties (Constant):
    %       BASE_LAMBDA_MAX_L       - Base L-cone lambda-max in nm.
    %       BASE_LAMBDA_MAX_M       - Base M-cone lambda-max in nm.
    %       BASE_LAMBDA_MAX_S       - Base S-cone lambda-max in nm.
    %       SupportsAnalyticalPeak  - True if the template can return its peak
    %                                 absorbance analytically (closed form),
    %                                 false if peak finding is numerical.
    %
    %   PhotopigmentTemplate Abstract Methods:
    %       computeAbsorbance       - Compute log10 absorbance spectrum.
    %       computePeakAbsorbance   - Compute analytical peak absorbance.
    %
    %   PhotopigmentTemplate Concrete Methods:
    %       getLambdaMax  - Get lambda-max for a cone type with shift.

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

    properties (Abstract, SetAccess = protected)
        % Name  Full descriptive name of the template model.
        Name (1,1) string

        % ShortName  Short identifier (e.g., "StockmanRider2023").
        ShortName (1,1) string
    end

    properties (Abstract, Constant)
        % Base lambda-max wavelengths in nm. Concrete subclasses provide the
        % values from their source publication; getLambdaMax dispatches on
        % cone type using these constants. One per cone, named explicitly so
        % each can carry its own citation.
        BASE_LAMBDA_MAX_L (1,1) double
        BASE_LAMBDA_MAX_M (1,1) double
        BASE_LAMBDA_MAX_S (1,1) double

        % SupportsAnalyticalPeak  Whether the peak is available in closed form.
        %
        %   True if the template's peak absorbance has a closed-form
        %   expression that computePeakAbsorbance can evaluate without
        %   numerical search; false if the consumer must locate the peak
        %   numerically (e.g. fminbnd on a wavelength grid).
        SupportsAnalyticalPeak (1,1) logical

        % ValidRange  [min_nm, max_nm] over which the template was fitted.
        %
        %   Queries outside this range may produce unreliable results due
        %   to limitations of the template's parametric formulas. Read it
        %   directly from the template instance.
        ValidRange (1,2) double
    end

    properties (Constant)
        % REGISTRY  Maps enums.PhotopigmentModel member names to constructors.
        %
        %   Govardovskii2000 and Govardovskii2000A2 share a class and are
        %   distinguished by the Pigment constructor argument, which is why
        %   the values are thunks rather than bare class handles.
        %
        %   TemplateRegistryTest keeps these keys and the enum members in
        %   agreement.
        REGISTRY = dictionary( ...
            ["StockmanRider2023", "Govardovskii2000", ...
             "Govardovskii2000A2", "StockmanRider2023Common"], ...
            {@() StockmanRiderPhotopigmentTemplate(), ...
             @() GovardovskiiPhotopigmentTemplate(), ...
             @() GovardovskiiPhotopigmentTemplate(Pigment="A2"), ...
             @() StockmanRiderCommonPhotopigmentTemplate()})
    end

    methods (Static)
        function t = create(model)
            % CREATE  Instantiate the photopigment template for a model name.
            %
            %   t = PhotopigmentTemplate.create("Govardovskii2000A2") returns
            %   a GovardovskiiPhotopigmentTemplate configured for the A2
            %   chromophore. Accepts an enums.PhotopigmentModel directly.
            %
            %   INPUTS:
            %       model - Model name or enums.PhotopigmentModel (string)
            %
            %   OUTPUTS:
            %       t - A PhotopigmentTemplate subclass instance
            arguments
                model (1,1) string
            end
            if ~isKey(PhotopigmentTemplate.REGISTRY, model)
                error("PhotopigmentTemplate:UnknownModel", ...
                    "No photopigment template registered for ""%s"". Known models: %s.", ...
                    model, strjoin(keys(PhotopigmentTemplate.REGISTRY)', ", "));
            end
            ctor = PhotopigmentTemplate.REGISTRY{model};
            t = ctor();
        end
    end

    methods (Abstract)
        % computeAbsorbance  Compute log10 absorbance spectrum.
        %
        %   INPUTS:
        %       wl - Wavelengths in nm (column vector) (vector)
        %       coneType - Cone type: 'L', 'M', or 'S' (char)
        %       shift - Wavelength shift in nm (double)
        %       options - Template-specific options (struct)
        %           For StockmanRider: options.L_Template, options.M_Template
        %           For Govardovskii: (none required)
        %
        %   OUTPUTS:
        %       logAbs - Log10 absorbance spectrum (vector)
        logAbs = computeAbsorbance(obj, wl, coneType, shift, options)

        % computePeakAbsorbance  Compute analytical peak absorbance value.
        %
        %   INPUTS:
        %       coneType - Cone type: 'L', 'M', or 'S' (char)
        %       shift - Wavelength shift in nm (double)
        %       options - Template-specific options (struct)
        %
        %   OUTPUTS:
        %       peakAbs - Peak absorbance value (linear scale) (double)
        peakAbs = computePeakAbsorbance(obj, coneType, shift, options)

    end

    methods
        function lmax = getLambdaMax(obj, coneType, shift)
            % GETLAMBDAMAX  Get lambda-max wavelength for a cone type.
            %
            %   INPUTS:
            %       coneType - Cone type: 'L', 'M', or 'S' (char)
            %       shift - Wavelength shift in nm (double)
            %
            %   OUTPUTS:
            %       lmax - Lambda-max wavelength in nm (double)
            arguments
                obj
                coneType (1,1) char {mustBeMember(coneType, {'L', 'M', 'S'})}
                shift (1,1) double = 0
            end

            switch coneType
                case 'L'
                    lmax = obj.BASE_LAMBDA_MAX_L + shift;
                case 'M'
                    lmax = obj.BASE_LAMBDA_MAX_M + shift;
                case 'S'
                    lmax = obj.BASE_LAMBDA_MAX_S + shift;
            end
        end
    end
end

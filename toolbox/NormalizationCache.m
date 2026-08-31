classdef NormalizationCache < handle
    % NORMALIZATIONCACHE  Manages cached peak values for normalization.
    %
    %   This class caches peak sensitivity values to avoid redundant
    %   computation. It stores peaks per cone type and output format,
    %   and provides methods for retrieval and invalidation.
    %
    %   The cache is linked to an IndividualCMF observer and uses the
    %   observer's computeRawSensitivity method to calculate peaks when
    %   needed. Peaks are cached by a key combining cone type and output
    %   format (e.g., "L_energy", "M_quantal").
    %
    %   Two normalization methods are supported:
    %     - "Continuous": Delegates peak computation to
    %                      IndividualCMF.computePeakForFormat, which uses
    %                      an analytical formula for Govardovskii
    %                      absorptance and fminbnd optimisation otherwise.
    %     - "Sampled":    Uses the maximum value from a discretely sampled
    %                      spectrum on a configurable grid.
    %
    %   EXAMPLE:
    %       cache = NormalizationCache(observer);
    %       cache.setConfig(enums.NormalizationMethod.Sampled, 380:5:780);
    %       peak = cache.getPeak('L', "energy");

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada
    %
    % This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    % Licensed under AGPL-3.0-or-later. See LICENSE file for details.

    properties (SetAccess = private)
        % How the peak is located: Continuous or Sampled.
        Method (1,1) enums.NormalizationMethod = enums.NormalizationMethod.Continuous

        % Wavelength grid used when Method is Sampled, in nm.
        Grid double = (380:1:780)'
    end

    properties (Access = private)
        % Keys: "L_energy", "M_quantal", etc.
        %
        % The default is explicit because a typed property with none gets a
        % 0x0 default, and dictionary is scalar-only on R2023b, where
        % defining the class then fails with MATLAB:class:emptyScalar.
        Peaks dictionary = configureDictionary("string", "double")
        % Reference to IndividualCMF for computation
        Observer
    end

    methods
        function obj = NormalizationCache(observer)
            % NORMALIZATIONCACHE  Construct cache linked to an observer.
            %
            %   cache = NormalizationCache(observer) creates a new cache
            %   instance linked to the specified IndividualCMF observer.
            %
            %   INPUTS:
            %       observer - The observer to link to (IndividualCMF)
            arguments
                observer (1,1) IndividualCMF
            end
            obj.Observer = observer;
            obj.Peaks = configureDictionary("string", "double");
        end

        function setConfig(obj, method, grid)
            % SETCONFIG  Update the normalization mode and clear the cache.
            %
            %   cache.setConfig(method) selects the peak-finding mode.
            %   cache.setConfig(method, grid) also sets the wavelength grid
            %   used in Sampled mode.
            %
            %   INPUTS:
            %       method - Continuous or Sampled (enums.NormalizationMethod)
            %       grid - Wavelength grid in nm for Sampled mode (vector)
            arguments
                obj
                method (1,1) enums.NormalizationMethod
                grid double {mustBeVector, mustBeNonempty} = (380:1:780)'
            end
            obj.Method = method;
            obj.Grid = grid;
            obj.invalidate();
        end

        function invalidate(obj)
            % INVALIDATE  Clear all cached peaks.
            %
            %   cache.invalidate() clears all cached peak values, forcing
            %   recalculation on next access.
            obj.Peaks = configureDictionary("string", "double");
        end

        function peak = getPeak(obj, coneType, outputFormat)
            % GETPEAK  Get peak for cone/format, computing if not cached.
            %
            %   peak = cache.getPeak(coneType, outputFormat) returns the
            %   peak sensitivity value for the specified cone type and
            %   output format. If not cached, computes and caches the value.
            %
            %   INPUTS:
            %       coneType - 'L', 'M', or 'S' (char)
            %       outputFormat - 'absorbance', 'absorptance', 'quantal', 'energy' (string)
            %
            %   OUTPUTS:
            %       peak - Peak sensitivity value (double)
            arguments
                obj
                coneType (1,1) char {mustBeMember(coneType, {'L', 'M', 'S'})}
                outputFormat (1,1) string
            end

            key = coneType + "_" + outputFormat;

            if isKey(obj.Peaks, key)
                peak = obj.Peaks(key);
            else
                peak = obj.computePeak(coneType, outputFormat);
                obj.Peaks(key) = peak;
            end
        end
    end

    methods (Access = private)
        function peak = computePeak(obj, coneType, outputFormat)
            % COMPUTEPEAK  Compute peak using configured method.
            %
            %   Dispatches to either computeSampledPeak or computeContinuousPeak
            %   based on the current configuration.
            if obj.Method == enums.NormalizationMethod.Sampled
                peak = obj.computeSampledPeak(coneType, outputFormat);
            else
                peak = obj.computeContinuousPeak(coneType, outputFormat);
            end

            % An absent cone (Lod/Mod/Sod == 0; gene-deletion dichromacy)
            % yields an identically zero spectrum, and therefore a peak of
            % zero. Substituting peak = 1 keeps the normalized column at
            % zero (0/1 = 0) rather than producing NaN (0/0). The same
            % branch also guards against any unexpected zero peak from
            % pathological inputs.
            if peak == 0
                peak = 1;
            end
        end

        function peak = computeSampledPeak(obj, coneType, outputFormat)
            % COMPUTESAMPLEDPEAK  Compute peak from sampled spectrum.
            %
            %   Takes the maximum over the configured wavelength grid.
            %   The grid is stored as written by the caller, so force a
            %   column here: computeRawSensitivity requires (:,1).
            wl = obj.Grid(:);
            values = obj.Observer.computeRawSensitivity(wl, coneType, outputFormat);
            peak = max(values);
        end

        function peak = computeContinuousPeak(obj, coneType, outputFormat)
            peak = obj.Observer.computePeakForFormat(coneType, outputFormat);
        end
    end
end

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
    %       cache.setConfig(struct('Method', "Sampled", 'Start', 380, 'Stop', 780, 'Step', 5));
    %       peak = cache.getPeak('L', "energy");

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada
    %
    % This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    % Licensed under AGPL-3.0-or-later. See LICENSE file for details.

    properties (SetAccess = private)
        % Active normalization configuration.
        Config struct = struct('Method', "Continuous")
    end

    properties (Access = private)
        % Keys: "L_energy", "M_quantal", etc.
        Peaks containers.Map
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
            obj.Peaks = containers.Map('KeyType', 'char', 'ValueType', 'double');
        end

        function setConfig(obj, config)
            % SETCONFIG  Update configuration and clear cache.
            %
            %   cache.setConfig(config) updates the normalization configuration
            %   and clears all cached peak values.
            %
            %   INPUTS:
            %       config - Configuration struct with Method field (struct)
            %                         For Sampled: also Start, Stop, Step fields
            arguments
                obj
                config (1,1) struct
            end
            obj.Config = config;
            obj.Peaks = containers.Map('KeyType', 'char', 'ValueType', 'double');
        end

        function invalidate(obj)
            % INVALIDATE  Clear all cached peaks.
            %
            %   cache.invalidate() clears all cached peak values, forcing
            %   recalculation on next access.
            obj.Peaks = containers.Map('KeyType', 'char', 'ValueType', 'double');
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

            key = sprintf('%s_%s', coneType, outputFormat);

            if obj.Peaks.isKey(key)
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
            if obj.Config.Method == "Sampled"
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
            %   Uses the configured Start, Stop, and Step values to create
            %   a wavelength grid and finds the maximum value.
            wl = (obj.Config.Start : obj.Config.Step : obj.Config.Stop)';
            values = obj.Observer.computeRawSensitivity(wl, coneType, outputFormat);
            peak = max(values);
        end

        function peak = computeContinuousPeak(obj, coneType, outputFormat)
            peak = obj.Observer.computePeakForFormat(coneType, outputFormat);
        end
    end
end

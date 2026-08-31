classdef TemplateRegistryTest < matlab.unittest.TestCase
    % TEMPLATEREGISTRYTEST  The enum members and the registry keys must agree.
    %
    %   These tests are the guard rail that replaces the hand-maintained
    %   switch statements in IndividualCMF. Adding an enum member without a
    %   registry entry (or vice versa) fails here rather than at runtime,
    %   where the old code silently fell through to a default template.

    % SPDX-License-Identifier: AGPL-3.0-or-later
    %
    % Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    % Simon Fraser University, Burnaby, British Columbia, Canada
    %
    % This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    % Licensed under AGPL-3.0-or-later. See LICENSE file for details.
    % Repository: https://github.com/sfu-cs-vision-lab/Individual-CMFs

    properties (TestParameter)
        % Each hierarchy carries its enum name plus handles to the registry
        % and factory. Handles rather than name strings because a Constant
        % property is not reachable through feval.
        Hierarchy = struct( ...
            photopigment = struct( ...
                Enum = "enums.PhotopigmentModel", ...
                Base = "PhotopigmentTemplate", ...
                Registry = @() PhotopigmentTemplate.REGISTRY, ...
                Create = @(n) PhotopigmentTemplate.create(n)), ...
            lens = struct( ...
                Enum = "enums.LensModel", ...
                Base = "LensTemplate", ...
                Registry = @() LensTemplate.REGISTRY, ...
                Create = @(n) LensTemplate.create(n)), ...
            macular = struct( ...
                Enum = "enums.MacularModel", ...
                Base = "MacularTemplate", ...
                Registry = @() MacularTemplate.REGISTRY, ...
                Create = @(n) MacularTemplate.create(n)))
    end

    methods (Test)

        %% Registry and enum agreement

        function testEveryEnumMemberHasARegistryEntry(testCase, Hierarchy)
            members = string(enumeration(Hierarchy.Enum))';
            registryKeys = keys(Hierarchy.Registry())';

            missing = setdiff(members, registryKeys);
            testCase.verifyEmpty(missing, sprintf( ...
                '%s members with no %s.REGISTRY entry: %s', ...
                Hierarchy.Enum, Hierarchy.Base, strjoin(missing, ', ')));
        end

        function testEveryRegistryKeyIsAnEnumMember(testCase, Hierarchy)
            members = string(enumeration(Hierarchy.Enum))';
            registryKeys = keys(Hierarchy.Registry())';

            extra = setdiff(registryKeys, members);
            testCase.verifyEmpty(extra, sprintf( ...
                '%s.REGISTRY keys that are not %s members: %s', ...
                Hierarchy.Base, Hierarchy.Enum, strjoin(extra, ', ')));
        end

        %% Factory behaviour

        function testCreateReturnsAnInstanceWithMatchingShortName(testCase, Hierarchy)
            % create(name).ShortName must round-trip back to the enum,
            % because IndividualCMF's model getters rely on exactly that to
            % report which model is active.
            members = string(enumeration(Hierarchy.Enum))';
            for m = members
                t = Hierarchy.Create(m);
                testCase.verifyInstanceOf(t, char(Hierarchy.Base));
                testCase.verifyEqual(string(t.ShortName), m, sprintf( ...
                    '%s.create("%s") returned ShortName "%s"', ...
                    Hierarchy.Base, m, t.ShortName));
            end
        end

        function testCreateRejectsAnUnknownName(testCase, Hierarchy)
            % The old copyElement switches fell through to a default
            % template on an unrecognised name. The factory must refuse.
            testCase.verifyError(@() Hierarchy.Create("NoSuchModel"), ...
                Hierarchy.Base + ":UnknownModel");
        end

        function testCreateReturnsIndependentInstances(testCase, Hierarchy)
            % Templates are handle classes, so the factory must hand back a
            % fresh object each call rather than a shared singleton.
            members = string(enumeration(Hierarchy.Enum))';
            first = Hierarchy.Create(members(1));
            second = Hierarchy.Create(members(1));
            testCase.verifyNotSameHandle(first, second);
        end

        %% Integration with IndividualCMF

        function testEveryModelIsSelectableOnAnObserver(testCase, Hierarchy)
            % Every registered model must be assignable through the
            % IndividualCMF property and read back as itself.
            propertyName = extractAfter(Hierarchy.Enum, "enums.");
            members = string(enumeration(Hierarchy.Enum))';

            for m = members
                obs = IndividualCMF();
                obs.(propertyName) = m;
                testCase.verifyEqual(string(obs.(propertyName)), m, sprintf( ...
                    'Setting %s to "%s" did not read back', propertyName, m));
            end
        end

        function testEveryModelIsSelectableThroughTheConstructor(testCase)
            % The setter path was already covered. The constructor had
            % hardcoded mustBeMember lists for LensModel and MacularModel,
            % so a newly registered model would work via obs.LensModel =
            % "New" and be rejected by IndividualCMF(LensModel="New") --
            % breaking the registry's promise that registration takes one
            % line in the template base and nothing in IndividualCMF.
            for m = string(enumeration('enums.LensModel'))'
                obs = IndividualCMF(LensModel=m);
                testCase.verifyEqual(string(obs.LensModel), m);
            end
            for m = string(enumeration('enums.MacularModel'))'
                obs = IndividualCMF(MacularModel=m);
                testCase.verifyEqual(string(obs.MacularModel), m);
            end
            for m = string(enumeration('enums.PhotopigmentModel'))'
                obs = IndividualCMF(PhotopigmentModel=m);
                testCase.verifyEqual(string(obs.PhotopigmentModel), m);
            end

            % An unregistered name must still be refused, by the enum
            % conversion rather than by a duplicated list.
            testCase.verifyError(@() IndividualCMF(LensModel="NotAModel"), ...
                'MATLAB:validation:UnableToConvert');
        end

    end
end

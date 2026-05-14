classdef PyconeParityTest < matlab.unittest.TestCase
    % PyconeParityTest  Verify IndividualCMF matches the pycone reference.
    %
    %   Runs the live pycone-vs-IndividualCMF comparison defined in
    %   tests/parity/compare.m and verifies every (configuration, output
    %   format) pair matches to machine precision.
    %
    %   The full sweep is run once in TestClassSetup and cached. Each
    %   parameterized test method (one per config in configs.json) then
    %   verifies the cached results for that specific config across all
    %   five output formats. CI / JUnit output names each failure by
    %   the failing config (e.g. PyconeParityTest[14_lensdensity_custom])
    %   so a regression points directly at the responsible configuration.
    %
    %   This test depends on the pycone reference being cloned into
    %   tests/parity/pycone/. If the clone or python3 is missing, the
    %   test is skipped via assumeTrue rather than failing - users in
    %   CI environments without Python or without the clone should not
    %   see spurious failures.
    %
    %   To enable locally:
    %       cd tests/parity
    %       git clone --depth 1 https://github.com/CVRL-IoO/Individual-CMFs.git pycone
    %
    %   See also: tests/parity/README.md, tests/parity/compare.m

    %   SPDX-License-Identifier: AGPL-3.0-or-later
    %
    %   Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
    %   Simon Fraser University, Burnaby, British Columbia, Canada
    %
    %   This file is part of the Matlab Individual Cone Fundamentals Toolbox.
    %   Licensed under AGPL-3.0-or-later. See LICENSE file for details.

    properties (TestParameter)
        % One test instance per config in tests/parity/configs.json.
        ConfigName = PyconeParityTest.allConfigNames();
    end

    properties (Access = private)
        AllResults
    end

    methods (TestClassSetup)
        function setupSweep(testCase)
            import matlab.unittest.fixtures.PathFixture

            here = fileparts(mfilename('fullpath'));
            pyconeDir = fullfile(here, 'parity', 'pycone');
            [pyStatus, ~] = system('python3 --version');

            % In CI the parity gate must run -- a silent skip would let
            % template/RGB regressions ship under the looser CIE
            % reference test (which only enforces the ~2% Stockman-Rider
            % polynomial-fit residual). Locally we still skip so a fresh
            % clone without pycone or python3 doesn't break the suite.
            isCI = ~isempty(getenv('CI')) || ~isempty(getenv('GITHUB_ACTIONS'));
            cloneInstructions = ['Required: pycone reference not ' ...
                'cloned. Run:\n' ...
                '    cd tests/parity && git clone --depth 1 ' ...
                'https://github.com/CVRL-IoO/Individual-CMFs.git pycone'];
            pythonInstructions = ['Required: python3 not on PATH; ' ...
                'pycone parity test cannot run.'];

            if isCI
                testCase.fatalAssertTrue(isfolder(pyconeDir), ...
                    cloneInstructions);
                testCase.fatalAssertEqual(pyStatus, 0, ...
                    pythonInstructions);
            else
                testCase.assumeTrue(isfolder(pyconeDir), ...
                    cloneInstructions);
                testCase.assumeEqual(pyStatus, 0, ...
                    pythonInstructions);
            end

            % Add parity folder to path for the duration of this test
            % class. The fixture restores the original path automatically.
            testCase.applyFixture(PathFixture(fullfile(here, 'parity')));

            % Run the full 28-config x 5-format = 140-comparison sweep
            % once and cache the struct array. Per-config test methods
            % below pick out the relevant rows.
            testCase.AllResults = compare(Verbose=false);
        end
    end

    methods (Test, TestTags = {'Parity', 'Slow'})
        function testConfigMatchesPycone(testCase, ConfigName)
            results = testCase.AllResults;
            mask = strcmp({results.name}, ConfigName);
            relevant = results(mask);
            testCase.verifyNotEmpty(relevant, ...
                sprintf('No results found for config %s', ConfigName));

            for k = 1:numel(relevant)
                r = relevant(k);
                testCase.verifyTrue(r.pass, ...
                    sprintf('%s/%s  abs=%.2e rel=%.2e', ...
                        r.name, r.format, r.maxAbs, r.maxRel));
            end
        end
    end

    methods (Static)
        function names = allConfigNames()
            % Read tests/parity/configs.json and return a cell array of
            % config names. Returns an empty cell if the file is
            % unavailable - the TestClassSetup will then skip via
            % assumeTrue rather than failing.
            here = fileparts(mfilename('fullpath'));
            cfgPath = fullfile(here, 'parity', 'configs.json');
            if ~isfile(cfgPath)
                names = {'unavailable'};  % single placeholder
                return
            end
            raw = jsondecode(fileread(cfgPath));
            if iscell(raw)
                names = cellfun(@(c) c.name, raw, 'UniformOutput', false);
            else
                names = {raw.name};
            end
        end
    end
end

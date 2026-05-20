function plan = buildfile
% BUILDFILE  Build configuration for individual-cmfs-matlab.
%
%   Tasks:
%       clean   - Remove generated reports and build artifacts.
%       check   - Static analysis on toolbox/ via codeIssues.
%       test    - Run unit tests, emit JUnit XML and Cobertura coverage,
%                 and refresh shields.io badge JSONs.
%       package - Build a redistributable .mltbx into dist/ using the
%                 version in VERSION and the UUID in
%                 resources/toolbox/identifier.txt.
%
%   Default tasks: ["check", "test"].
%
%   The test task depends on check; package depends on check + test.
%
%   This buildfile adds project paths itself so it can run in CI without
%   the MATLAB project file being open.
%
% SPDX-License-Identifier: AGPL-3.0-or-later
%
% Copyright 2025-2026 Alexander Forsythe and Brian Funt. Simon Fraser University.

    rootDir = fileparts(mfilename('fullpath'));
    addpath(fullfile(rootDir, 'toolbox'));
    addpath(fullfile(rootDir, 'buildUtilities'));
    addpath(fullfile(rootDir, 'examples'));

    plan = buildplan(localfunctions);

    plan("test").Dependencies = "check";
    plan("package").Dependencies = ["check", "test"];
    plan.DefaultTasks = ["check", "test"];
end

function cleanTask(~)
% Remove generated reports, badges, and the buildtool cache.
    rootDir = fileparts(mfilename('fullpath'));
    reportsDir = fullfile(rootDir, 'reports');
    if isfolder(reportsDir)
        % Preserve committed badge JSONs; remove only generated XML/HTML.
        delete(fullfile(reportsDir, '*.xml'));
        delete(fullfile(reportsDir, '*.html'));
    end
    cacheDir = fullfile(rootDir, '.buildtool');
    if isfolder(cacheDir)
        rmdir(cacheDir, 's');
    end
end

function checkTask(context)
% Static analysis on the toolbox/ source directory.
%
%   Fails the build if codeIssues reports any warning- or error-severity
%   issues. Info-severity items (stylistic suggestions, e.g. R2026a's
%   suggestion to use mustBeBetween instead of mustBeInRange) are noted
%   in the report but do not fail the build, since they are not actual
%   deprecations and may not be backward-compatible with older MATLAB
%   releases the CI matrix supports.
    rootDir = context.Plan.RootFolder;
    sourceDir = fullfile(rootDir, 'toolbox');
    issues = codeIssues(sourceDir);

    reportsDir = fullfile(rootDir, 'reports');
    if ~isfolder(reportsDir)
        mkdir(reportsDir);
    end

    badgeDir = fullfile(reportsDir, 'badge');
    if ~isfolder(badgeDir)
        mkdir(badgeDir);
    end

    blockingIssues = issues.Issues(issues.Issues.Severity ~= "info", :);
    nBlocking = height(blockingIssues);

    if isCIEnvironment()
        writeCodeIssuesBadge(fullfile(badgeDir, 'code_issues.json'), nBlocking);
    end

    if height(issues.Issues) > 0
        disp(issues.Issues);
    end

    if nBlocking > 0
        error('buildfile:CodeIssues', ...
            'Static analysis found %d warning/error issue(s) in toolbox/.', nBlocking);
    end
end

function testTask(context)
% Run the unit test suite with JUnit XML and Cobertura coverage.
    import matlab.unittest.TestSuite
    import matlab.unittest.TestRunner
    import matlab.unittest.plugins.XMLPlugin
    import matlab.unittest.plugins.CodeCoveragePlugin
    import matlab.unittest.plugins.codecoverage.CoberturaFormat

    rootDir = context.Plan.RootFolder;
    reportsDir = fullfile(rootDir, 'reports');
    if ~isfolder(reportsDir)
        mkdir(reportsDir);
    end
    badgeDir = fullfile(reportsDir, 'badge');
    if ~isfolder(badgeDir)
        mkdir(badgeDir);
    end

    coverageFile = fullfile(reportsDir, 'coverage.xml');
    junitFile = fullfile(reportsDir, 'junit.xml');
    sourceDir = fullfile(rootDir, 'toolbox');
    testDir = fullfile(rootDir, 'tests');

    % Tests reference data files by short name (e.g., 'rgb_verification.csv'),
    % so put tests/data on the path for the duration of the run.
    addpath(genpath(testDir));
    pathCleanup = onCleanup(@() rmpath(genpath(testDir))); %#ok<NASGU>

    suite = TestSuite.fromFolder(testDir);
    runner = TestRunner.withTextOutput();
    runner.addPlugin(XMLPlugin.producingJUnitFormat(junitFile));
    runner.addPlugin(CodeCoveragePlugin.forFolder(sourceDir, ...
        Producing = CoberturaFormat(coverageFile)));

    results = runner.run(suite);

    if isCIEnvironment()
        writeCoverageBadge(fullfile(badgeDir, 'coverage.json'), coverageFile);
        writeTestedWithBadge(fullfile(badgeDir, 'tested_with.json'));
    end

    nFailed = sum([results.Failed]);
    if nFailed > 0
        error('buildfile:TestFailures', ...
            'Test run reported %d failure(s).', nFailed);
    end
end


function packageTask(context)
% Build a redistributable .mltbx into dist/.
%
%   Reads version from VERSION (one line, SemVer) and the toolbox
%   identifier UUID from resources/toolbox/identifier.txt
%   (generated once via uuidgen and committed; preserves Add-On
%   identity across versions). Ships toolbox/ as the source.
    rootDir = context.Plan.RootFolder;
    versionFile = fullfile(rootDir, 'VERSION');
    identifierFile = fullfile(rootDir, 'resources', 'toolbox', 'identifier.txt');
    toolboxDir = fullfile(rootDir, 'toolbox');
    distDir = fullfile(rootDir, 'dist');

    versionString = strtrim(string(fileread(versionFile)));
    identifier = strtrim(string(fileread(identifierFile)));

    % MATLAB's ToolboxOptions requires Major.Minor.Bug.Build format and
    % rejects SemVer pre-release tags. Map "X.Y.Z-beta.N" -> "X.Y.Z.N"
    % for the toolbox version field while preserving the human-readable
    % form (with the beta suffix) in the output filename.
    matlabVersion = semverToMatlabVersion(versionString);

    if ~isfolder(distDir)
        mkdir(distDir);
    end

    outputFile = fullfile(distDir, sprintf('individual-cmfs-matlab-%s.mltbx', versionString));

    opts = matlab.addons.toolbox.ToolboxOptions(toolboxDir, identifier);
    opts.ToolboxName = "Individual CMF Toolbox";
    opts.ToolboxVersion = matlabVersion;
    opts.AuthorName = "Alexander Forsythe";
    opts.AuthorCompany = "Simon Fraser University";
    opts.Summary = "Individual cone fundamentals from biophysical parameters (genotype, age, field size, lens / macular / photopigment OD).";
    opts.Description = ...
        "MATLAB toolbox computing observer-specific LMS cone fundamentals " + ...
        "and derived quantities (RGB CMFs, CIE XYZ, V*(lambda), chromaticity) " + ...
        "from biophysical inputs. Default Stockman & Rider (2023) templates " + ...
        "reproduce the CIE 170 standard observers; Govardovskii (2000) " + ...
        "photopigment and Pokorny (1987) / van de Kraats & van Norren (2007) " + ...
        "lens models are available as alternatives." + newline + newline + ...
        "Source, examples, and issue tracker: " + ...
        "https://github.com/sfu-cs-vision-lab/individual-cmfs-matlab";
    opts.MinimumMatlabRelease = "R2023b";
    opts.MaximumMatlabRelease = "R2025b";
    opts.OutputFile = outputFile;

    matlab.addons.toolbox.packageToolbox(opts);

    fprintf('Packaged: %s\n', outputFile);
end

function v = semverToMatlabVersion(versionString)
% Map SemVer with pre-release tags to MATLAB's Major.Minor.Bug.Build.
%
%   "X.Y.Z"          -> "X.Y.Z"
%   "X.Y.Z-beta.N"   -> "X.Y.Z.N"     (Build = N)
%   "X.Y.Z-rc.N"     -> "X.Y.Z.N"     (Build = N)
%
%   Stable releases get a three-part version; pre-releases encode the
%   iteration in Build. Beta and rc collide in MATLAB version ordering,
%   which is acceptable for a beta-only workflow; revisit if alpha/beta/rc
%   need to coexist.
    versionString = string(versionString);
    tokens = regexp(versionString, '^(\d+\.\d+\.\d+)(?:-(?:beta|rc|alpha)\.(\d+))?$', 'tokens', 'once');
    if isempty(tokens)
        error('buildfile:InvalidVersion', ...
            'VERSION ("%s") must match X.Y.Z or X.Y.Z-{beta,rc,alpha}.N.', versionString);
    end
    base = tokens(1);
    if numel(tokens) >= 2 && strlength(tokens(2)) > 0
        v = base + "." + tokens(2);
    else
        v = base;
    end
end

function tf = isCIEnvironment()
% Badge JSON files at reports/badge/*.json are committed and must only
% be refreshed by CI. Skip the writers during local runs so 'buildtool
% check' / 'buildtool test' don't dirty the working tree.
tf = ~isempty(getenv('CI')) || ~isempty(getenv('GITHUB_ACTIONS'));
end

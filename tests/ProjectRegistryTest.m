classdef ProjectRegistryTest < matlab.unittest.TestCase
    % PROJECTREGISTRYTEST  The MATLAB project lists what git tracks.
    %
    %   Coverage areas:
    %     - Every tracked file is registered in the project
    %     - Every registered entry still exists on disk
    %
    %   The project file records which files belong to the project and how
    %   they are classified. Adding a source or test file without registering
    %   it, or deleting one without removing its entry, leaves the two out of
    %   step. Nothing in the build notices: the drift shows up only as a
    %   warning in the Project Issues panel, which needs the project open in
    %   the MATLAB desktop to see. It has happened twice, once from files
    %   added over several sessions and once from a single test added and not
    %   registered, so the check belongs somewhere that runs unattended.
    %
    %   Copyright 2025-2026 Alexander Forsythe and Brian Funt. Simon Fraser University.

    properties (Constant)
        % The .prj is a stub and the project file describes itself; neither
        % appears in its own file listing.
        Unregistered = ["individual-cmfs-matlab.prj"
                        "resources/project/Project.xml"]
    end

    properties
        Root string
    end

    methods (TestMethodSetup)
        function findRoot(testCase)
            testCase.Root = fileparts(fileparts(string(mfilename("fullpath"))));
        end
    end

    methods (Test)

        function testEveryTrackedFileIsInTheProject(testCase)
            tracked = testCase.trackedFiles();
            registered = testCase.registeredFiles();
            missing = setdiff(setdiff(tracked, registered), testCase.Unregistered);
            testCase.verifyEmpty(missing, ...
                "Tracked by git but not in the project: " + strjoin(missing, ", ") + ...
                ". Add them from the Project Issues panel, or with addFile.");
        end

        function testEveryProjectEntryStillExists(testCase)
            registered = testCase.registeredFiles();
            gone = strings(0);
            for f = reshape(registered, 1, [])
                if ~isfile(fullfile(testCase.Root, f)) && ~isfolder(fullfile(testCase.Root, f))
                    gone(end+1) = f; %#ok<AGROW>
                end
            end
            testCase.verifyEmpty(gone, ...
                "In the project but not on disk: " + strjoin(gone, ", ") + ...
                ". Remove them from the Project Issues panel, or with removeFile.");
        end

        function testTheListingItselfIsNotEmpty(testCase)
            % Guards the two checks above from passing because the parse
            % returned nothing, which would make both of them vacuous.
            testCase.verifyGreaterThan(numel(testCase.registeredFiles()), 100, ...
                "The project listing parsed to suspiciously few entries.");
        end

    end

    methods (Access = private)

        function files = trackedFiles(testCase)
            [status, out] = system("git -C """ + testCase.Root + """ ls-files");
            testCase.assumeEqual(status, 0, "git is not available here.");
            files = strtrim(splitlines(string(out)));
            files = files(strlength(files) > 0);
        end

        function files = registeredFiles(testCase)
            % Project.xml nests <File Location="..."> elements, so a path is
            % the Location values from the root down to that element.
            xml = string(fileread(fullfile(testCase.Root, ...
                "resources", "project", "Project.xml")));
            [matches, names] = regexp(xml, '<File Location="([^"]+)">|</File>', ...
                'match', 'tokens');
            files = strings(0);
            stack = strings(0);
            for k = 1:numel(matches)
                if startsWith(matches{k}, "<File")
                    stack(end+1) = string(names{k}{1}); %#ok<AGROW>
                    files(end+1) = strjoin(stack, "/"); %#ok<AGROW>
                elseif ~isempty(stack)
                    stack(end) = [];
                end
            end
        end

    end
end

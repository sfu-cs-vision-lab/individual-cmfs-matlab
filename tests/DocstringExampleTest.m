classdef DocstringExampleTest < matlab.unittest.TestCase
    % DOCSTRINGEXAMPLETEST  Run the EXAMPLE block of every documented method.
    %
    %   Coverage areas:
    %     - Every EXAMPLE block in the documented classes executes
    %     - Blocks are found by the same label the reference generator uses
    %
    %   An example that does not run is worse than no example, because the
    %   reference publishes it as the way to call the method. Nothing else
    %   executes these blocks, so without this test they are prose that
    %   happens to look like code.
    %
    %   Copyright 2025-2026 Alexander Forsythe and Brian Funt. Simon Fraser University.

    properties (Constant)
        % The classes whose methods the Help Browser reference publishes.
        Classes = ["IndividualCMF", "ObserverParameters", "PhotopigmentParameters", ...
                   "Genotype", "PreReceptoralFilter", "Nomograms", "CIE170"]
    end

    methods (TestMethodSetup)
        function isolateSideEffects(testCase)
            % Examples write files. The evaluate example writes cmfs.csv to
            % whatever the working directory happens to be, which is the
            % repository when the suite runs from there. A scratch folder
            % keeps the run from leaving artefacts behind.
            testCase.applyFixture( ...
                matlab.unittest.fixtures.WorkingFolderFixture);

            % Examples that plot open figures, and some raise the model-range
            % warning by design. Neither is what this test is measuring.
            testCase.applyFixture( ...
                matlab.unittest.fixtures.SuppressedWarningsFixture( ...
                    {'IndividualCMF:WavelengthOutOfRange', ...
                     'Nomograms:WavelengthOutOfRange', ...
                     'IndividualCMF:NonStandardObserver'}));
            testCase.addTeardown(@() close('all'));
        end
    end

    methods (Test)

        function testEveryDocstringExampleRuns(testCase)
            failures = strings(0);
            ran = 0;
            for className = testCase.Classes
                mc = meta.class.fromName(className);
                for m = reshape(mc.MethodList, 1, [])
                    % Access is a cell array of classes for a method with
                    % restricted access, so it needs a scalar check first.
                    isPublic = ischar(m.Access) && strcmp(m.Access, 'public');
                    if ~isPublic || m.Hidden
                        continue
                    end
                    code = DocstringExampleTest.exampleOf(string(m.DetailedDescription));
                    if strlength(code) == 0
                        continue
                    end
                    ran = ran + 1;
                    try
                        evalc(code);
                    catch err
                        failures(end+1) = className + "." + m.Name + ...
                            " -> " + err.message; %#ok<AGROW>
                    end
                    close('all');
                end
            end
            testCase.verifyGreaterThan(ran, 25, ...
                "Found suspiciously few EXAMPLE blocks to run.");
            testCase.verifyEmpty(failures, ...
                "Docstring examples that do not run: " + strjoin(failures, " | "));
        end

        function testExtractorFindsAKnownBlock(testCase)
            % Guards the test above from passing because it extracted
            % nothing. LMS carries an example, so the extractor must see it.
            mc = meta.class.fromName("IndividualCMF");
            m = mc.MethodList(strcmp({mc.MethodList.Name}, 'LMS'));
            code = DocstringExampleTest.exampleOf(string(m(1).DetailedDescription));
            testCase.verifySubstring(code, "obs.LMS(");
            testCase.verifyEmpty(regexp(code, "EXAMPLE", "once"), ...
                "The label itself should not be returned as code.");
        end

    end

    methods (Access = private, Static)

        function code = exampleOf(detail)
            % Lines under an EXAMPLE label, taken while they stay indented
            % deeper than the label itself.
            code = "";
            lines = splitlines(string(detail));
            trimmed = strtrim(lines);
            start = find(trimmed == "EXAMPLE:" | trimmed == "EXAMPLES:", 1);
            if isempty(start)
                return
            end
            labelIndent = strlength(lines(start)) - strlength(strip(lines(start), "left"));
            body = strings(0);
            for k = start+1:numel(lines)
                if strlength(trimmed(k)) == 0
                    continue
                end
                indent = strlength(lines(k)) - strlength(strip(lines(k), "left"));
                if indent <= labelIndent
                    break
                end
                body(end+1) = strtrim(lines(k)); %#ok<AGROW>
            end
            code = strjoin(body, newline);
        end

    end
end

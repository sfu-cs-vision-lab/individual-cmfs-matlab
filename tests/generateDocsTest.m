classdef generateDocsTest < matlab.unittest.TestCase
    % GENERATEDOCSTEST  Tests for the Help Browser reference generator.
    %
    %   Coverage areas:
    %     - Page and table-of-contents generation
    %     - Content drawn from class metadata rather than hand-written
    %     - HTML escaping of characters that would otherwise be markup
    %     - Link and anchor integrity within pages and from helptoc.xml
    %     - Error handling for an unknown class
    %
    %   The generator runs during "buildtool package", so a failure here would
    %   otherwise surface only at release time. The link checks matter because
    %   a renamed method leaves a dead navigation entry in helptoc.xml without
    %   producing an error anywhere.
    %
    %   Copyright 2025-2026 Alexander Forsythe and Brian Funt. Simon Fraser University.

    properties
        DocDir string
        OutDir string
    end

    methods (TestMethodSetup)
        function makeTempOutput(testCase)
            % Mirror the real layout: a doc folder holding helptoc.xml, with
            % the pages in an html subfolder beneath it. generateDocs writes
            % helptoc.xml one level above OutputDir, so the names matter.
            testCase.DocDir = string(tempname);
            testCase.OutDir = fullfile(testCase.DocDir, "html");
            mkdir(testCase.OutDir);
            testCase.addTeardown(@() rmdir(testCase.DocDir, 's'));
        end
    end

    methods (Test)

        % Basic Functionality Tests

        function testWritesAPageForEachClass(testCase)
            testCase.generate(["IndividualCMF", "Genotype"]);
            testCase.verifyTrue(isfile(fullfile(testCase.OutDir, "index.html")));
            testCase.verifyTrue(isfile(fullfile(testCase.OutDir, "IndividualCMF.html")));
            testCase.verifyTrue(isfile(fullfile(testCase.OutDir, "Genotype.html")));
        end

        function testWritesHelpToc(testCase)
            testCase.generate("Genotype");
            toc = string(fileread(testCase.tocPath()));
            testCase.verifySubstring(toc, "<toc version=""2.0"">");
            testCase.verifySubstring(toc, "html/Genotype.html");
        end

        % Content Tests

        function testPageContentComesFromMetadata(testCase)
            testCase.generate("IndividualCMF");
            page = string(fileread(fullfile(testCase.OutDir, "IndividualCMF.html")));
            mc = meta.class.fromName("IndividualCMF");
            props = mc.PropertyList;
            visible = props(strcmp({props.GetAccess}, 'public') & ~[props.Hidden]);
            for name = string({visible.Name})
                testCase.verifySubstring(page, name, ...
                    sprintf("Property %s is missing from the generated page.", name));
            end
            testCase.verifySubstring(page, "LMS");
            testCase.verifySubstring(page, "plotDiagnostics");
        end

        function testSummaryIsASentenceNotAWrappedLine(testCase)
            testCase.generate("Genotype");
            page = string(fileread(fullfile(testCase.OutDir, "Genotype.html")));
            lead = regexp(page, '<p class="lead">(.*?)</p>', 'tokens', 'once');
            testCase.verifyNotEmpty(lead);
            testCase.verifyGreaterThan(strlength(lead{1}), 40, ...
                "Summary looks like a truncated first line rather than a sentence.");
        end

        % Link Integrity Tests

        function testEveryPageLinkResolves(testCase)
            testCase.generate(["IndividualCMF", "ObserverParameters", "Genotype", ...
                               "Nomograms", "CIE170"]);
            [pages, ids] = testCase.readPages();
            names = string(fieldnames(pages));
            broken = strings(0);
            for k = 1:numel(names)
                text = pages.(names(k));
                targets = string(regexp(text, 'href="([^"]+)"', 'tokens'));
                for target = reshape(targets, 1, [])
                    broken = [broken, testCase.checkTarget(target, names(k), pages, ids)]; %#ok<AGROW>
                end
            end
            testCase.verifyEmpty(broken, ...
                "Broken links in the generated pages: " + strjoin(broken, "; "));
        end

        function testEveryHelpTocTargetResolves(testCase)
            testCase.generate(["IndividualCMF", "ObserverParameters", "Genotype", ...
                               "Nomograms", "CIE170"]);
            [pages, ids] = testCase.readPages();
            toc = string(fileread(testCase.tocPath()));
            targets = string(regexp(toc, 'target="([^"]+)"', 'tokens'));
            testCase.verifyGreaterThan(numel(targets), 40, ...
                "helptoc.xml has suspiciously few entries.");
            broken = strings(0);
            for target = reshape(targets, 1, [])
                if startsWith(target, "html/")
                    broken = [broken, ...
                        testCase.checkTarget(extractAfter(target, "html/"), ...
                                             "helptoc.xml", pages, ids)]; %#ok<AGROW>
                end
            end
            testCase.verifyEmpty(broken, ...
                "Broken helptoc.xml targets: " + strjoin(broken, "; "));
        end

        % Edge Case Tests

        function testHtmlIsEscaped(testCase)
            testCase.generate("IndividualCMF");
            page = string(fileread(fullfile(testCase.OutDir, "IndividualCMF.html")));
            body = extractAfter(page, "<body>");
            stripped = regexprep(body, '<[^>]*>', '');
            testCase.verifyEqual(count(stripped, "<"), 0, ...
                "An unescaped '<' survived into the page text.");
        end

        function testUnknownClassErrors(testCase)
            testCase.verifyError( ...
                @() generateDocs(OutputDir=testCase.OutDir, ...
                    Classes="NoSuchClassExists", BuildIndex=false, Verbose=false), ...
                "generateDocs:ClassNotFound");
        end

    end

    methods (Access = private)

        function generate(testCase, classNames)
            generateDocs(OutputDir=testCase.OutDir, Classes=classNames, ...
                BuildIndex=false, Verbose=false);
        end

        function p = tocPath(testCase)
            p = fullfile(testCase.DocDir, "helptoc.xml");
        end

        function [pages, ids] = readPages(testCase)
            % Page text and the anchor ids each page defines, keyed by a
            % struct-safe version of the file name.
            listing = dir(fullfile(testCase.OutDir, "*.html"));
            pages = struct();
            ids = struct();
            for k = 1:numel(listing)
                key = generateDocsTest.keyFor(listing(k).name);
                text = string(fileread(fullfile(listing(k).folder, listing(k).name)));
                pages.(key) = text;
                ids.(key) = string(regexp(text, 'id="([^"]+)"', 'tokens'));
            end
        end

        function problem = checkTarget(~, target, source, pages, ids)
            % Return a description if the link does not resolve, else empty.
            problem = strings(0);
            if startsWith(target, "#")
                anchor = extractAfter(target, "#");
                key = generateDocsTest.keyFor(source);
                if ~isfield(ids, key) || ~ismember(anchor, ids.(key))
                    problem = source + " -> " + target + " (anchor missing)";
                end
                return
            end
            parts = split(target, "#");
            key = generateDocsTest.keyFor(parts(1));
            if ~isfield(pages, key)
                problem = source + " -> " + target + " (file missing)";
            elseif numel(parts) > 1 && ~ismember(parts(2), ids.(key))
                problem = source + " -> " + target + " (anchor missing in target)";
            end
        end

    end

    methods (Access = private, Static)

        function key = keyFor(fileName)
            % Struct field names cannot contain a dot, so map X.html to X_html.
            key = matlab.lang.makeValidName(string(fileName));
        end

    end
end

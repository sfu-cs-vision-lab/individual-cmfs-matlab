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
            lead = regexp(page, '<p class="purpose">(.*?)</p>', 'tokens', 'once');
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
                               "Nomograms", "CIE170", "enums.LensModel"]);
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

        function testPropertySummaryStopsAtTheFirstSentence(testCase)
            % MATLAB splits property help at the first line break, so a
            % wrapped first sentence arrives in two pieces and the rest of
            % the block follows it. The table cell must show one sentence.
            % A regex escaping error made this silently emit the whole help
            % block, which the index table's length cap then hid.
            testCase.generate("IndividualCMF");
            page = string(fileread(fullfile(testCase.OutDir, "IndividualCMF.html")));
            cell = regexp(page, '<tr><td class="name">PhotopigmentModel</td>.*?</tr>', 'match', 'once');
            testCase.verifyNotEmpty(cell);
            text = strtrim(regexprep(cell, '<[^>]*>', ' '));
            testCase.verifySubstring(text, "Photopigment template model");
            testCase.verifyEqual(count(text, "."), 1, ...
                "The property cell should hold exactly one sentence.");
            testCase.verifyLessThan(strlength(text), 200, ...
                "The property cell looks like the whole help block.");
        end

        function testEachMethodGetsItsOwnPage(testCase)
            % The Help Browser loads pages in a frame, where a fragment does
            % not scroll the document. Navigating to a method therefore needs
            % a page of its own rather than an anchor.
            testCase.generate("IndividualCMF");
            testCase.verifyTrue(isfile(fullfile(testCase.OutDir, "IndividualCMF.LMS.html")));
            testCase.verifyTrue(isfile(fullfile(testCase.OutDir, "IndividualCMF.plotLMS.html")));
            toc = string(fileread(testCase.tocPath()));
            testCase.verifyEqual(count(toc, "#"), 0, ...
                "helptoc.xml still points at fragments, which do not navigate.");
        end

        function testMethodHelpIsSplitIntoSections(testCase)
            testCase.generate("IndividualCMF");
            page = string(fileread(fullfile(testCase.OutDir, "IndividualCMF.LMS.html")));
            headings = string(regexp(page, '<h2>([^<]+)</h2>', 'tokens'));
            testCase.verifyNotEmpty(headings, ...
                "Method help was not split into labelled sections.");
            testCase.verifyTrue(any(contains(headings, "Outputs")), ...
                "Expected an Outputs section for LMS.");
            testCase.verifyFalse(contains(page, "OUTPUTS:"), ...
                "A raw uppercase label survived into the rendered body.");
        end

        function testSectionBodiesAreDedentedNotJustTrimmed(testCase)
            % strtrim removes leading whitespace from the start of the whole
            % block, which is only its first line. Every later line then keeps
            % the indent it had in the source comment, so the first line sits
            % flush and the rest hang. The common indent must come off all of
            % them, and relative nesting must survive.
            testCase.generate("Nomograms");
            page = string(fileread(fullfile(testCase.OutDir, "Nomograms.stockmanRider.html")));
            block = regexp(page, '<h2>Inputs</h2>\s*<pre>(.*?)</pre>', 'tokens', 'once');
            testCase.verifyNotEmpty(block);
            lines = splitlines(replace(string(block{1}), "&quot;", """"));
            lines = lines(strlength(strtrim(lines)) > 0);
            testCase.verifyGreaterThan(numel(lines), 3);
            testCase.verifyTrue(startsWith(lines(1), "wavelengths"), ...
                "First line should be flush.");
            testCase.verifyTrue(startsWith(lines(2), "coneType"), ...
                "Second line still carries the source indent.");
            testCase.verifyTrue(startsWith(lines(4), "    "), ...
                "Nesting under options was flattened.");
        end

        function testDescriptionDoesNotRepeatTheSummary(testCase)
            % The summary line appears above as the page purpose. Rendering it
            % again opened every Description with a sentence just read.
            testCase.generate("IndividualCMF");
            page = string(fileread(fullfile(testCase.OutDir, "IndividualCMF.applyGenotype.html")));
            purpose = regexp(page, '<p class="purpose">(.*?)</p>', 'tokens', 'once');
            testCase.verifySubstring(purpose{1}, "opsin genotype string");
            description = regexp(page, '<h2>Description</h2>\s*<pre>(.*?)</pre>', ...
                'tokens', 'once');
            testCase.verifyNotEmpty(description);
            testCase.verifyFalse(contains(description{1}, purpose{1}), ...
                "The Description repeats the summary shown above it.");
        end

        function testSeeAlsoBecomesItsOwnSection(testCase)
            % The label carries its content on the same line, so it was being
            % swallowed by whichever section preceded it, usually Example.
            testCase.generate("IndividualCMF");
            page = string(fileread(fullfile(testCase.OutDir, "IndividualCMF.applyGenotype.html")));
            headings = string(regexp(page, '<h2>([^<]+)</h2>', 'tokens'));
            testCase.verifyTrue(any(headings == "See Also"));
            example = regexp(page, '<h2>Example</h2>\s*<pre>(.*?)</pre>', 'tokens', 'once');
            testCase.verifyFalse(contains(example{1}, "See also"), ...
                "The cross-reference is still inside the Example block.");
        end

        function testEnumerationPageListsValuesNotBuiltins(testCase)
            % Every enumeration inherits char, strcmp, ismember and eleven
            % more from MATLAB. A page for each would bury the values, which
            % are the only part of an enumeration a caller writes.
            testCase.generate("enums.LensModel");
            page = string(fileread(fullfile(testCase.OutDir, "enums.LensModel.html")));
            testCase.verifySubstring(page, "<h2>Values</h2>");
            for value = ["StockmanRider2023", "Pokorny1987", "VanDeKraats2007"]
                testCase.verifySubstring(page, value);
            end
            testCase.verifyFalse(contains(page, "<h2>Methods</h2>"), ...
                "Inherited enumeration builtins were documented as methods.");
            testCase.verifyFalse(isfile(fullfile(testCase.OutDir, "enums.LensModel.strcmp.html")));
            testCase.verifySubstring(page, "Lens absorption template model selector", ...
                "The summary should describe the class, not its first value.");
        end

        function testMethodsAreGroupedByTaskNotAlphabetically(testCase)
            % Alphabetical order files LMS between lmChromaticity and
            % Luminance, and scatters the twelve plotting methods through the
            % middle. Every method must appear under exactly one category, so
            % that categorising cannot quietly drop one from the reference.
            testCase.generate("IndividualCMF");
            page = string(fileread(fullfile(testCase.OutDir, "IndividualCMF.html")));
            categories = string(regexp(page, '<h3>([^<]+)</h3>', 'tokens'));
            testCase.verifyGreaterThan(numel(categories), 3, ...
                "The method table was not split into categories.");
            testCase.verifyTrue(any(categories == "Plot and Compare"));

            mc = meta.class.fromName("IndividualCMF");
            meths = mc.MethodList;
            meths = meths(strcmp({meths.Access}, 'public') & ~[meths.Hidden]);
            expected = setdiff(string({meths.Name}), ...
                ["IndividualCMF", "empty", "delete", "findobj", "findprop", ...
                 "addlistener", "notify", "listener", "eq", "ne", "lt", "le", ...
                 "gt", "ge", "isvalid", "horzcat", "vertcat", "cat"]);
            listed = string(regexp(page, '<a href="IndividualCMF\.([A-Za-z_0-9]+)\.html">', ...
                'tokens'));
            testCase.verifyEqual(sort(listed), sort(expected), ...
                "The categorised list and the class's methods disagree.");
        end

        function testExamplesAreExportedAndCrossLinksResolve(testCase)
            % Getting Started links to all twenty examples with
            % matlab:open('ExampleNN_Name.m'). Exporting drops the scheme and
            % leaves a relative link to a source file that is not in the doc
            % folder, so every one of them was dead in the Help Browser.
            % Resolved from this file rather than from the working directory,
            % which the test runner does not guarantee.
            root = fileparts(fileparts(string(mfilename("fullpath"))));
            outDir = testCase.OutDir;
            generateDocs(OutputDir=outDir, Classes="Genotype", BuildIndex=false, ...
                Verbose=false, Examples=fullfile(root, "toolbox", "examples"));
            testCase.verifyTrue(isfile(fullfile(outDir, "Example01_Basics.html")));
            testCase.verifyFalse(isfile(fullfile(outDir, "exampleDefaults.html")), ...
                "exampleDefaults is a plain function, not an example page.");

            listing = dir(fullfile(outDir, "*.html"));
            dead = strings(0);
            for item = reshape(listing, 1, [])
                text = string(fileread(fullfile(item.folder, item.name)));
                left = regexp(text, "href\s*=\s*""([^""]+\.m)""", "tokens");
                for target = reshape(left, 1, [])
                    dead(end+1) = item.name + " -> " + string(target{1}); %#ok<AGROW>
                end
            end
            testCase.verifyEmpty(dead, ...
                "Links still point at source files: " + strjoin(dead, "; "));

            toc = string(fileread(testCase.tocPath()));
            testCase.verifySubstring(toc, ">Examples");
            testCase.verifySubstring(toc, "Example 01: The Basics");
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
                GettingStarted="", Examples="", BuildIndex=false, Verbose=false);
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

function generateDocs(options)
% GENERATEDOCS  Build the Help Browser reference pages from class metadata
%
%   generateDocs() writes the HTML reference and its table of contents into
%   toolbox/doc/html, then builds the help search database so the pages are
%   findable from the MATLAB Help Browser.
%
%   Every page is derived from meta.class, so the reference cannot disagree
%   with the source. Property and method descriptions come from the help
%   comments in the class files. Nothing here is written by hand, which is
%   why there is no separate reference document to keep in step.
%
%   Each method gets its own page, as MathWorks reference pages do. Anchors
%   within one long page do not work from the Help Browser table of contents,
%   because the page is loaded inside a frame and a fragment does not move it.
%
%   OPTIONAL INPUTS:
%       OutputDir - folder to write the pages into (string).
%                   Default fullfile("toolbox", "doc", "html").
%       Classes   - classes to document, in the order they should appear
%                   (string array). Default is the public surface: the
%                   observer classes, the templates behind them, and the
%                   enumerations that name their legal settings.
%       GettingStarted - plain-text Live Script to export alongside the
%                   reference (string). Pass "" to skip it.
%       Examples  - folder of worked examples to export (string). Pass ""
%                   to skip them.
%       RunExamples - run the examples and the guide while exporting, so
%                   that their figures and printed output appear in the
%                   pages (logical). Default true.
%       BuildIndex - build the help search database (logical). Default true.
%       Verbose   - print progress (logical). Default true.
%
%   REQUIRES:
%       The toolbox folder must be on the MATLAB path.
%
%   EXAMPLE:
%       addpath("toolbox");
%       generateDocs(BuildIndex=false, Verbose=false);
%
%   Copyright 2025-2026 Alexander Forsythe and Brian Funt. Simon Fraser University.

    arguments
        options.OutputDir (1,1) string = fullfile("toolbox", "doc", "html")
        options.Classes (1,:) string = defaultClasses()
        options.GettingStarted (1,1) string = fullfile("toolbox", "doc", "GettingStarted.m")
        options.Examples (1,1) string = fullfile("toolbox", "examples")
        options.RunExamples (1,1) logical = true
        options.BuildIndex (1,1) logical = true
        options.Verbose (1,1) logical = true
    end

    outDir = options.OutputDir;
    if ~isfolder(outDir)
        mkdir(outDir);
    end

    % Group pages are named after the groups, so renaming or removing a group
    % strands its old page in a folder that the .mltbx ships whole. They are
    % entirely derived, so clearing them first costs nothing.
    stale = dir(fullfile(outDir, "group-*.html"));
    for item = reshape(stale, 1, [])
        delete(fullfile(item.folder, item.name));
    end

    lightFigures = forceLightFigures(); %#ok<NASGU>
    rootDefaults = preserveGraphicsDefaults(); %#ok<NASGU>

    % Everything derived from class metadata is read and written before a
    % single example runs. Running a script makes MATLAB reload class
    % definitions, which breaks this in both directions: meta.property
    % handles taken beforehand read as deleted, and metadata taken afterwards
    % can come back empty, which shipped a blank page for one enumeration
    % while every other class was fine. The example list is derived from the
    % filenames, so the landing page can route to pages not yet written.
    hasGuide = strlength(options.GettingStarted) > 0 && isfile(options.GettingStarted);
    examples = listExamples(options.Examples);

    classes = collectMetadata(options.Classes);
    pages = pageLookup(classes);

    pageCount = 1 + hasGuide + numel(examples);
    writeIndexPage(outDir, classes, hasGuide, examples);
    for group = unique(arrayfun(@(c) groupOf(c.Name), classes), "stable")
        if isLeafGroup(group)
            continue
        end
        writeGroupPage(outDir, group, classes, examples);
        pageCount = pageCount + 1;
    end
    for k = 1:numel(classes)
        writeClassPage(outDir, classes(k), pages);
        pageCount = pageCount + 1;
        for m = classes(k).Methods(:)'
            writeMethodPage(outDir, classes(k), m, pages);
            pageCount = pageCount + 1;
        end
    end

    % Only now, with every metadata-derived page on disk, run the scripts.
    if hasGuide
        export(options.GettingStarted, fullfile(outDir, "GettingStarted.html"), ...
            Run=options.RunExamples);
    end
    exportExamples(outDir, examples, options.RunExamples);
    relinkSources(outDir);

    docDir = fileparts(outDir);
    writeHelpToc(fullfile(docDir, "helptoc.xml"), classes, hasGuide, examples);

    if options.Verbose
        fprintf("Wrote %d pages to %s\n", pageCount, outDir);
    end

    if options.BuildIndex
        % builddocsearchdb indexes the folder holding helptoc.xml, not the
        % folder holding the pages, and it is unavailable in some restricted
        % environments. A missing database costs full-text search and nothing
        % else, so a failure here warns rather than failing the build.
        try
            builddocsearchdb(char(docDir));
            if options.Verbose
                fprintf("Built help search database\n");
            end
        catch searchError
            warning("generateDocs:SearchDatabaseUnavailable", ...
                "Reference pages were written but the help search database " + ...
                "could not be built (%s). The pages still open from the Help " + ...
                "Browser; only full-text search is affected.", searchError.message);
        end
    end
end

function classes = collectMetadata(classNames)
% Gather the public surface of each class from meta.class.
    skip = ["empty", "delete", "findobj", "findprop", "addlistener", "notify", ...
            "listener", "eq", "ne", "lt", "le", "gt", "ge", "isvalid", ...
            "horzcat", "vertcat", "cat"];
    classes = struct("Name", {}, "Summary", {}, "Detail", {}, ...
                     "Properties", {}, "Methods", {}, "MethodGroups", {}, ...
                     "Members", {});
    for name = classNames
        mc = resolveClass(name);
        entry.Name = name;
        [described, entry.Detail] = classHelp(name, mc);
        % The summary line of the class help, when there is one. Falling
        % straight to the detail picks up whatever the body happens to open
        % with, which on an enumeration is the first member rather than a
        % description of the class.
        entry.Summary = summaryOf(described);
        if strlength(entry.Summary) == 0
            entry.Summary = summaryOf(entry.Detail);
        end
        props = mc.PropertyList;
        keep = strcmp({props.GetAccess}, 'public') & ~[props.Hidden];
        entry.Properties = plainProperties(props(keep));
        entry.Members = strings(0);
        meths = mc.MethodList;
        keep = strcmp({meths.Access}, 'public') & ~[meths.Hidden];
        meths = meths(keep);
        if mc.Enumeration
            % An enumeration inherits char, strcmp, ismember and a dozen more
            % from the enumeration machinery. None of them are this toolbox's
            % API, and a page for each would bury the values that are.
            entry.Members = string({mc.EnumerationMemberList.Name});
            meths = meths(~ismember(string({meths.Name}), enumBuiltins()));
        end
        meths = meths(~ismember(string({meths.Name}), [skip, shortName(name)]));
        [meths, entry.MethodGroups] = orderMethods(name, meths);
        entry.Methods = plainMethods(meths);
        % One entry per documented class, so the array stays tiny.
        classes(end+1) = entry; %#ok<AGROW>
    end
end

function [summaryText, detailText] = classHelp(name, mc)
% Class help, read from the file when the metadata has been emptied.
%
%   Running a single example through export with Run=true empties
%   Description and DetailedDescription on every enumeration class for the
%   rest of the session, and rehash does not bring them back. Class, method
%   and property help everywhere else survives, and help() reads the file so
%   it is unaffected. Without this the build shipped an enumeration page with
%   a blank purpose and blank value descriptions, and which enumerations were
%   hit varied from run to run.
    summaryText = string(mc.Description);
    detailText = string(mc.DetailedDescription);
    if strlength(summaryText) > 0 || strlength(detailText) > 0
        return
    end
    raw = string(help(char(name)));
    lines = splitlines(raw);
    filled = find(strlength(strtrim(lines)) > 0, 1);
    if isempty(filled)
        return
    end
    % help() prints the summary as "CLASSNAME  Summary text.", the same
    % shape meta strips before reporting Description.
    summaryText = regexprep(strtrim(lines(filled)), ...
        "^" + upper(shortName(name)) + "\s+", "");
    detailText = strjoin(lines(filled+1:end), newline);
end

function out = plainProperties(props)
% Copy what the pages need out of meta.property, as plain strings.
%
%   Nothing that came from meta.class may outlive collectMetadata. The
%   examples run later in the build, and running a script makes MATLAB
%   reload class definitions, which leaves every handle taken beforehand
%   reading as a deleted object and every one taken afterwards liable to
%   come back empty. Both failures were observed: a crash in writeHelpToc,
%   and a blank page shipped for one enumeration out of ten.
    out = struct("Name", {}, "Description", {}, "DetailedDescription", {});
    for p = reshape(props, 1, [])
        out(end+1) = struct("Name", string(p.Name), ...
                            "Description", string(p.Description), ...
                            "DetailedDescription", string(p.DetailedDescription)); %#ok<AGROW>
    end
end

function out = plainMethods(meths)
% Copy what the pages need out of meta.method, as plain strings.
    out = struct("Name", {}, "Description", {}, "DetailedDescription", {}, ...
                 "DefiningClass", {});
    for m = reshape(meths, 1, [])
        out(end+1) = struct("Name", string(m.Name), ...
                            "Description", string(m.Description), ...
                            "DetailedDescription", string(m.DetailedDescription), ...
                            "DefiningClass", string(m.DefiningClass.Name)); %#ok<AGROW>
    end
end

function out = enumBuiltins()
% Methods MATLAB synthesises for every enumeration.
%
%   They are reported as defined by the enumeration itself, so there is no
%   metadata that separates them from methods the class actually declares.
%   The set is fixed, which is why naming it is safe.
    out = ["char", "cellstr", "string", "strcmp", "strncmp", "strcmpi", ...
           "strncmpi", "setdiff", "setxor", "union", "intersect", ...
           "ismember", "isequal", "isequaln"];
end

function out = shortName(name)
% Class name without its package, which is also its constructor's name.
    parts = split(string(name), ".");
    out = parts(end);
end

function restorer = preserveGraphicsDefaults()
% Put the root graphics defaults back as the build found them.
%
%   Every example opens with exampleDefaults, which sets nine defaults on
%   groot and never restores them. Running the examples to capture their
%   figures therefore leaves the session styled for this toolbox, and a
%   "buildtool doc" run from an interactive MATLAB would change the look of
%   every figure drawn afterwards, including ones unrelated to it.
%
%   The whole default set is captured rather than the nine, so this holds
%   whatever an example decides to set later.
%
%   get(groot) does not report defaults at all, only the root's own
%   properties. get(groot, 'default') is what returns the ones in force.
    % Captured now, not inside the cleanup closure, where the call would run
    % after the examples had already changed what it reads.
    before = get(groot, 'default');
    restorer = onCleanup(@() restoreGraphicsDefaults(before));
end

function restoreGraphicsDefaults(before)
% Drop defaults the build introduced, and put back the ones it overwrote.
    kept = string(fieldnames(before));
    current = string(fieldnames(get(groot, 'default')));
    for name = reshape(setdiff(current, kept), 1, [])
        set(groot, char(name), 'remove');
    end
    for name = reshape(kept, 1, [])
        set(groot, char(name), before.(name));
    end
end

function restorer = forceLightFigures()
% Pin figure output to the light theme for as long as the caller holds the
% returned object.
%
%   Figures follow the desktop theme, and IndividualCMF.neutralColor reads
%   the theme to choose black or white for its lines. Building the pages on
%   a dark desktop would therefore ship dark plots onto a light page. The
%   release build runs on a headless CI runner, whose theme is not something
%   this toolbox controls, so the theme is pinned rather than assumed.
%
%   A temporary value lasts for the session and never touches the saved
%   preference, and it is cleared when the caller releases the object.
    restorer = [];
    try
        pref = settings().matlab.appearance.figure.GraphicsTheme;
    catch
        % Figures gained a theme in R2025a. Before that the output is light.
        return
    end
    hadTemporary = hasTemporaryValue(pref);
    previous = "";
    if hadTemporary
        previous = string(pref.TemporaryValue);
    end
    pref.TemporaryValue = "light";
    restorer = onCleanup(@() restoreFigureTheme(hadTemporary, previous));
end

function restoreFigureTheme(hadTemporary, previous)
% Put the figure theme back as it was, rather than merely clearing it.
%
%   Clearing unconditionally would discard a temporary value the caller had
%   set for its own reasons, which is a session setting this function
%   borrows rather than owns.
    pref = settings().matlab.appearance.figure.GraphicsTheme;
    if hadTemporary
        pref.TemporaryValue = previous;
    else
        clearTemporaryValue(pref);
    end
end

function pages = pageLookup(classes)
% Every documented name, mapped to the page that documents it.
%
%   Used to turn the names in a See also line into links. Without it a
%   cross-reference is text the reader has to retype into the search box,
%   which is the difference between a tree and a web.
    pages = dictionary(string.empty, string.empty);
    for k = 1:numel(classes)
        name = classes(k).Name;
        pages(name) = name + ".html";
        for m = classes(k).Methods(:)'
            pages(name + "." + m.Name) = methodFile(name, m.Name);
        end
    end
end

function out = linkify(text, pages, owner)
% Link every name in a block that matches a documented page.
%
%   Rebuilt by scanning rather than by replacing, so a name inserted as link
%   text cannot be matched again by a later substitution.
    escaped = escapeHtml(text);
    [starts, ends, matches] = regexp(escaped, ...
        "[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*", "start", "end", "match");
    chars = char(escaped);
    pieces = strings(0);
    last = 0;
    for k = 1:numel(matches)
        target = pageFor(string(matches{k}), pages, owner);
        if strlength(target) == 0
            continue
        end
        pieces(end+1) = string(chars(last+1:starts(k)-1)); %#ok<AGROW>
        pieces(end+1) = sprintf("<a href=""%s"">%s</a>", target, matches{k}); %#ok<AGROW>
        last = ends(k);
    end
    pieces(end+1) = string(chars(last+1:end));
    out = strjoin(pieces, "");
end

function target = pageFor(token, pages, owner)
% Page documenting a name, resolving a bare method against its own class.
    target = "";
    if isKey(pages, token)
        target = pages(token);
    elseif strlength(owner) > 0 && isKey(pages, owner + "." + token)
        target = pages(owner + "." + token);
    end
end

function out = renderSections(text, pages, owner, leadHeading)
% Render a help block as headed sections, linking any cross-references.
    out = "";
    for section = helpSections(text)
        heading = leadHeading;
        if strlength(section.Heading) > 0
            heading = titleCase(section.Heading);
        end
        out = out + sprintf("<h2>%s</h2>\n", escapeHtml(heading));
        body = dedent(section.Body);
        if startsWith(lower(heading), "see also")
            out = out + sprintf("<p class=""seealso"">%s</p>\n", ...
                linkify(body, pages, owner));
        else
            out = out + sprintf("<pre>%s</pre>\n", escapeHtml(body));
        end
    end
end

function out = memberDescriptions(members, detail)
% Descriptions for enumeration values, taken from the class help.
%
%   The values are the only part of an enumeration a caller writes, and the
%   help describes each one as "Name - description" with wrapped
%   continuation lines. Listing bare names leaves the answer sitting in the
%   raw help block below the table.
    out = strings(size(members));
    lines = splitlines(string(detail));
    current = "";
    for k = 1:numel(lines)
        opened = regexp(strtrim(lines(k)), "^(\w+)\s+-\s+(.*)$", "tokens", "once");
        if ~isempty(opened) && ismember(opened{1}, members)
            current = opened{1};
            out(members == current) = strtrim(opened{2});
        elseif strlength(strtrim(lines(k))) == 0
            current = "";
        elseif strlength(current) > 0
            out(members == current) = strtrim(out(members == current)) + ...
                " " + strtrim(lines(k));
        end
    end
end

function examples = listExamples(folder)
% The worked examples, named and titled from their source files.
%
%   Separate from exporting them, so the contents tree and the landing page
%   can be built before any example is allowed to run.
    examples = struct("File", {}, "Title", {}, "Source", {});
    if strlength(folder) == 0 || ~isfolder(folder)
        return
    end
    listing = dir(fullfile(folder, "*.m"));
    % dir matches without regard to case on macOS and Windows, so a pattern
    % of Example*.m also picks up exampleDefaults.m, which is a plain
    % function and not something export accepts.
    listing = listing(startsWith(string({listing.name}), "Example"));
    if isempty(listing)
        return
    end
    [~, order] = sort(string({listing.name}));
    for item = reshape(listing(order), 1, [])
        source = string(fullfile(item.folder, item.name));
        [~, stem] = fileparts(item.name);
        examples(end+1) = struct("File", stem + ".html", ...
                                 "Title", exampleTitle(source), ...
                                 "Source", source); %#ok<AGROW>
    end
end

function exportExamples(outDir, examples, runThem)
% Render the worked examples so the Help Browser can show them.
%
%   The examples are the toolbox's main teaching material and were reachable
%   only by opening them in the editor. Getting Started links to all twenty
%   of them, and every one of those links pointed outside the doc folder.
    for e = reshape(examples, 1, [])
        export(e.Source, fullfile(outDir, e.File), Run=runThem);
    end
end

function out = exampleTitle(path)
% The heading a plain-text Live Script opens with, for its contents entry.
    lines = splitlines(string(fileread(path)));
    hit = find(startsWith(strtrim(lines), "%[text] # "), 1);
    if isempty(hit)
        [~, out] = fileparts(path);
        return
    end
    out = strtrim(extractAfter(strtrim(lines(hit)), "%[text] # "));
end

function relinkSources(outDir)
% Point cross-references at the exported pages rather than at source files.
%
%   The examples and Getting Started link to each other with
%   matlab:open('Example08_AgingEffects.m'). Exporting drops the scheme and
%   leaves a relative link to a source file that is not in the doc folder, so
%   every one of them is dead in the Help Browser. Rewriting the extension
%   only where the page exists leaves any other .m reference alone.
    listing = dir(fullfile(outDir, "*.html"));
    available = string({listing.name});
    for item = reshape(listing, 1, [])
        path = fullfile(item.folder, item.name);
        text = string(fileread(path));
        found = regexp(text, "href\s*=\s*""([^""]+\.m)""", "tokens");
        if isempty(found)
            continue
        end
        original = text;
        for target = unique(string([found{:}]))
            page = regexprep(target, "\.m$", ".html");
            if ismember(page, available)
                text = replace(text, """" + target + """", """" + page + """");
            end
        end
        if text ~= original
            writeText(path, text);
        end
    end
end

function spec = referenceSpec()
% The documented classes, each paired with the group it belongs to.
%
%   One table drives the default class list, the index page and the table of
%   contents, so the three cannot disagree. Groups appear in the order they
%   are first named here, and classes in the order they are listed, which is
%   also the order the Help Browser shows them in.
%
%   The grouping is by the part of the model a class belongs to, not by what
%   kind of MATLAB construct it is. A group of ten templates answers three
%   unrelated questions at once, and a reader looking for the lens models has
%   to already know which of the ten names are lens models.
%
%   Each enumeration sits with what it selects rather than in a block of its
%   own. enums.LensModel and the three lens templates are the same three
%   models named twice, once as the strings a caller assigns and once as the
%   classes behind them. Filed apart, a reader who does not know the
%   enumeration exists has no route to the list of legal values.
%
%   Within a model group the string selectors come first and the abstract
%   base last. A caller reaches a lens model by assigning
%   LensModel="Pokorny1987", so the enumeration that names the legal strings
%   is what they need; the class implementing it is the answer to a later
%   question, and the base class to a later one still.
%
%   The group column takes two special forms. An empty group puts the class
%   directly under Reference rather than inside a wrapper, which is where
%   IndividualCMF belongs, since every example uses it and it should not sit
%   as one of five peers. "Class/Heading" nests the entry inside that class's
%   own subtree, which is how the two output enumerations reach the observer
%   whose properties they set instead of forming a two-row group of their own.
    spec = [ ...
        "",                             "IndividualCMF"; ...
        "IndividualCMF/Output Settings", "enums.OutputFormat"; ...
        "IndividualCMF/Output Settings", "enums.NormalizationMethod"; ...
        "Observer Configuration",       "Genotype"; ...
        "Observer Configuration",       "ObserverParameters"; ...
        "Observer Configuration",       "PhotopigmentParameters"; ...
        "Observer Configuration",       "PreReceptoralFilter"; ...
        "Photopigment Models",          "enums.PhotopigmentModel"; ...
        "Photopigment Models",          "enums.PhotopigmentDensityAlgorithm"; ...
        "Photopigment Models",          "enums.LOpsinTemplate"; ...
        "Photopigment Models",          "enums.MOpsinTemplate"; ...
        "Photopigment Models",          "StockmanRiderPhotopigmentTemplate"; ...
        "Photopigment Models",          "StockmanRiderCommonPhotopigmentTemplate"; ...
        "Photopigment Models",          "GovardovskiiPhotopigmentTemplate"; ...
        "Photopigment Models",          "Nomograms"; ...
        "Photopigment Models",          "PhotopigmentTemplate"; ...
        "Lens Models",                  "enums.LensModel"; ...
        "Lens Models",                  "enums.LensDensityAlgorithm"; ...
        "Lens Models",                  "StockmanRiderLensTemplate"; ...
        "Lens Models",                  "Pokorny1987LensTemplate"; ...
        "Lens Models",                  "VanDeKraatsVanNorren2007LensTemplate"; ...
        "Lens Models",                  "LensTemplate"; ...
        "Macular Pigment",              "enums.MacularModel"; ...
        "Macular Pigment",              "enums.MacularDensityAlgorithm"; ...
        "Macular Pigment",              "StockmanRider2023MacularTemplate"; ...
        "Macular Pigment",              "MacularTemplate"; ...
        "",                             "CIE170"; ...
        "Advanced: Pipeline Stages",    "pipeline.PhotopigmentStage"; ...
        "Advanced: Pipeline Stages",    "pipeline.PreReceptoralStage"; ...
        "Advanced: Pipeline Stages",    "pipeline.OutputStage"];
end

function spec = methodSpec(className)
% Categories for a class's methods, or empty for alphabetical order.
%
%   Alphabetical order files LMS between lmChromaticity and Luminance, and
%   scatters the twelve plotting methods through the middle of the list. The
%   result reads as a word list rather than an API. IndividualCMF has
%   thirty-three methods and is the only class where this matters.
%
%   The plotting methods split by what they draw. Six show a finished
%   quantity and belong with compareTo, and six show a stage of the model
%   the observer passed through on the way there. Twelve in one category was
%   a third of the class under one heading.
%
%   evaluate sits with the parameter snapshot rather than with the
%   quantities. It computes none of them itself: it dispatches to the named
%   method and packages the result for writetable, which is what Example 17
%   uses it for. neutralColor is a theme-aware line colour, so it belongs
%   with the plotting rather than among the colorimetry it is not. getPeak
%   reports where normalization put the peak, which is a question about the
%   model rather than a sensitivity a caller wants back.
%
%   A method missing from this table, or named here but not defined, fails
%   the doc build rather than quietly falling out of the reference.
    spec = strings(0, 2);
    if className ~= "IndividualCMF"
        return
    end
    spec = [ ...
        "Create and Configure",     "across"; ...
        "Create and Configure",     "applyGenotype"; ...
        "Create and Configure",     "setGenotype"; ...
        "Manage and Export",        "getParameters"; ...
        "Manage and Export",        "setParameters"; ...
        "Manage and Export",        "copy"; ...
        "Manage and Export",        "evaluate"; ...
        "Cone Fundamentals",        "LMS"; ...
        "Cone Fundamentals",        "L"; ...
        "Cone Fundamentals",        "M"; ...
        "Cone Fundamentals",        "S"; ...
        "Derived Colorimetry",      "XYZ"; ...
        "Derived Colorimetry",      "RGB"; ...
        "Derived Colorimetry",      "Luminance"; ...
        "Derived Colorimetry",      "MacLeodBoynton"; ...
        "Derived Colorimetry",      "lmChromaticity"; ...
        "Derived Colorimetry",      "xyChromaticity"; ...
        "Inspect Model",            "getPeak"; ...
        "Inspect Model",            "getLensDensitySpectrum"; ...
        "Inspect Model",            "getMacularDensitySpectrum"; ...
        "Plot Results and Compare", "plot"; ...
        "Plot Results and Compare", "plotLMS"; ...
        "Plot Results and Compare", "plotXYZ"; ...
        "Plot Results and Compare", "plotRGBCMFs"; ...
        "Plot Results and Compare", "plotChromaticity"; ...
        "Plot Results and Compare", "compareTo"; ...
        "Plot Results and Compare", "neutralColor"; ...
        "Plot Model Stages",        "plotAbsorbance"; ...
        "Plot Model Stages",        "plotAbsorptance"; ...
        "Plot Model Stages",        "plotQuantalEnergy"; ...
        "Plot Model Stages",        "plotLens"; ...
        "Plot Model Stages",        "plotMacular"; ...
        "Plot Model Stages",        "plotDiagnostics"];
end

function [meths, groups] = orderMethods(className, meths)
% Put a class's methods in category order, or alphabetical if it has none.
    names = string({meths.Name});
    spec = methodSpec(className);
    if isempty(spec)
        [~, order] = sort(lower(names));
        meths = meths(order);
        groups = strings(1, numel(meths));
        return
    end
    uncategorised = setdiff(names, spec(:, 2)');
    if ~isempty(uncategorised)
        error("generateDocs:UncategorisedMethod", ...
              "%s defines %s, which the method category table in " + ...
              "generateDocs omits.", className, strjoin(uncategorised, ", "));
    end
    order = zeros(1, size(spec, 1));
    for k = 1:size(spec, 1)
        hit = find(names == spec(k, 2), 1);
        if isempty(hit)
            error("generateDocs:UnknownMethod", ...
                  "The method category table lists '%s', which %s does " + ...
                  "not define.", spec(k, 2), className);
        end
        order(k) = hit;
    end
    meths = meths(order);
    groups = spec(:, 1)';
end

function out = isLeafGroup(group)
% An empty group puts the class straight under Reference, with no wrapper.
    out = strlength(group) == 0;
end

function [parent, heading] = splitGroup(group)
% "Class/Heading" nests under that class. Otherwise there is no parent.
    parent = "";
    heading = group;
    cut = strfind(group, "/");
    if ~isempty(cut)
        parent = extractBefore(group, cut(1));
        heading = extractAfter(group, cut(1));
    end
end

function out = groupExamples(group)
% Worked examples that answer the question a group raises.
%
%   Both reviews landed on the same gap: the reference tells a reader what
%   every class is and never says which example answers their task. A reader
%   asking which lens model to use reaches an abstract class and four
%   implementations, while the decision is spelled out in Example 08.
    table = [ ...
        "Observer Configuration",    "Example16_AdvancedCustomization.html"; ...
        "Observer Configuration",    "Example09_GeneticVariants.html"; ...
        "Photopigment Models",       "Example10_PhotopigmentModels.html"; ...
        "Photopigment Models",       "Example09_GeneticVariants.html"; ...
        "Lens Models",               "Example08_AgingEffects.html"; ...
        "Macular Pigment",           "Example07_FieldSizeEffects.html"; ...
        "Advanced: Pipeline Stages", "Example04_ComputationalPipeline.html"; ...
        "Advanced: Pipeline Stages", "Example05_OutputFormats.html"; ...
        "IndividualCMF/Output Settings", "Example05_OutputFormats.html"; ...
        "IndividualCMF/Output Settings", "Example06_NormalizationMethods.html"];
    out = table(table(:, 1) == group, 2)';
end

function out = commonTasks()
% The tasks readers actually arrive with, and the example that answers each.
    out = [ ...
        "Create an observer and read its cone fundamentals", "Example01_Basics.html"; ...
        "Reproduce a CIE standard observer",                 "Example02_StandardObservers.html"; ...
        "Choose a lens model for an older observer",          "Example08_AgingEffects.html"; ...
        "Model a specific genotype",                          "Example09_GeneticVariants.html"; ...
        "Integrate a measured spectrum against an observer",  "Example19_MeasuredSpectra.html"; ...
        "Write results to CSV or MAT",                        "Example17_DataExport.html"; ...
        "Build a publication figure",                         "Example18_PublicationFigures.html"];
end

function out = exampleLinks(files, examples)
% A sentence of links to the named example pages, or "" if none are present.
    out = "";
    if isempty(files) || isempty(examples)
        return
    end
    available = string({examples.File});
    titles = string({examples.Title});
    parts = strings(0);
    for f = reshape(files, 1, [])
        hit = find(available == f, 1);
        if ~isempty(hit)
            parts(end+1) = sprintf("<a href=""%s"">%s</a>", f, escapeHtml(titles(hit))); %#ok<AGROW>
        end
    end
    if isempty(parts)
        return
    end
    out = "<p class=""routes"">Worked examples: " + strjoin(parts, ", ") + ".</p>" + newline;
end

function out = exampleName(file, examples)
% Title of an example page, for link text.
    out = file;
    hit = find(string({examples.File}) == file, 1);
    if ~isempty(hit)
        out = string(examples(hit).Title);
    end
end

function out = defaultClasses()
% Every class in the reference spec, in the order it documents them.
    spec = referenceSpec();
    out = spec(:, 2)';
end

function out = groupOf(name)
% Heading a class sits under, in the index and the table of contents.
    spec = referenceSpec();
    row = find(spec(:, 2) == name, 1);
    if isempty(row)
        out = "Other";
    else
        out = spec(row, 1);
    end
end

function mc = resolveClass(name)
% Resolve a class by name, with a clear error if it is not on the path.
    mc = meta.class.fromName(name);
    if isempty(mc)
        error("generateDocs:ClassNotFound", ...
              "Class '%s' was not found. Is the toolbox folder on the path?", name);
    end
end

function writeIndexPage(outDir, classes, hasGuide, examples)
% Landing page: what the toolbox is, and the classes it exposes.
    body = header("Individual CMF Toolbox");
    body = body + "<h1>Individual CMF Toolbox</h1>" + newline;
    body = body + "<p class=""purpose"">Observer-specific LMS cone spectral " + ...
        "sensitivities from biophysical parameters, and the quantities derived " + ...
        "from them</p>" + newline;
    routes = strings(0);
    if hasGuide
        routes(end+1) = "<a href=""GettingStarted.html"">Getting Started</a>";
    end
    if ~isempty(examples)
        routes(end+1) = sprintf("the <a href=""%s"">worked examples</a>", examples(1).File);
    end
    if ~isempty(routes)
        body = body + "<p class=""routes"">New here? Start with " + ...
            strjoin(routes, ", then ") + ".</p>" + newline;
    end
    if ~isempty(examples)
        body = body + "<h2>Common tasks</h2>" + newline + "<table>" + newline;
        available = string({examples.File});
        tasks = commonTasks();
        for k = 1:size(tasks, 1)
            if ~ismember(tasks(k, 2), available)
                continue
            end
            body = body + sprintf("<tr><td>%s</td><td><a href=""%s"">%s</a></td></tr>\n", ...
                escapeHtml(tasks(k, 1)), tasks(k, 2), ...
                escapeHtml(exampleName(tasks(k, 2), examples)));
        end
        body = body + "</table>" + newline;
    end

    % Spec order, so an ungrouped class keeps its place among the groups.
    groups = arrayfun(@(c) groupOf(c.Name), classes);
    written = strings(0);
    for k = 1:numel(classes)
        group = groups(k);
        [parent, heading] = splitGroup(group);
        if strlength(parent) > 0
            % A nested group belongs to the class it hangs from.
            continue
        end
        if isLeafGroup(group)
            body = body + sprintf("<h2><a href=""%s.html"">%s</a></h2>\n<table>\n", ...
                classes(k).Name, escapeHtml(classes(k).Name));
            body = body + classRow(classes(k)) + "</table>" + newline;
            continue
        end
        if ismember(group, written)
            continue
        end
        written(end+1) = group; %#ok<AGROW>
        body = body + sprintf("<h2><a href=""%s"">%s</a></h2>\n<table>\n", ...
            groupFile(group), escapeHtml(heading));
        for j = find(groups == group)
            body = body + classRow(classes(j));
        end
        body = body + "</table>" + newline;
    end
    body = body + footer();
    writeText(fullfile(outDir, "index.html"), body);
end

function writeGroupPage(outDir, group, classes, examples)
% One page per group, so a group heading in the contents tree lands
% somewhere. Every group tocitem otherwise targets the top of the full
% landing page, and a fragment cannot rescue it inside the Help Browser
% frame for the same reason method anchors could not.
    [~, heading] = splitGroup(group);
    body = header(heading);
    body = body + sprintf("<h1>%s</h1>\n", escapeHtml(heading));
    body = body + exampleLinks(groupExamples(group), examples);
    body = body + "<table>" + newline;
    groups = arrayfun(@(c) groupOf(c.Name), classes);
    for k = find(groups == group)
        body = body + classRow(classes(k));
    end
    body = body + "</table>" + newline;
    body = body + "<p class=""routes""><a href=""index.html"">All groups</a></p>" + newline;
    body = body + footer();
    writeText(fullfile(outDir, groupFile(group)), body);
end

function out = classRow(entry)
% One row of a class table, shared by the index and the group pages.
    out = sprintf("<tr><td class=""name""><a href=""%s.html"">%s</a></td>" + ...
        "<td>%s</td></tr>\n", entry.Name, entry.Name, ...
        escapeHtml(truncate(entry.Summary, 170)));
end

function out = groupFile(group)
% File name for a group page, from the group's own name.
%
%   Anything that is not a letter or a digit becomes a hyphen. A group named
%   "Advanced: Pipeline Stages" otherwise produced a file name containing a
%   colon, which Windows does not allow and a URL has to escape.
    slug = lower(regexprep(strtrim(string(group)), "[^A-Za-z0-9]+", "-"));
    out = "group-" + strip(slug, "-") + ".html";
end

function writeClassPage(outDir, entry, pages)
% Class page: purpose, property table, and a linked list of methods.
    body = header(entry.Name);
    body = body + sprintf("<h1>%s</h1>\n", escapeHtml(entry.Name));
    body = body + sprintf("<p class=""purpose"">%s</p>\n", escapeHtml(entry.Summary));
    group = groupOf(entry.Name);
    [~, heading] = splitGroup(group);
    if ~isLeafGroup(group)
        body = body + sprintf("<p class=""parent"">In <a href=""%s"">%s</a></p>\n", ...
            groupFile(group), escapeHtml(heading));
    end

    if ~isempty(entry.Members)
        body = body + "<h2>Values</h2>" + newline + "<table>" + newline;
        described = memberDescriptions(entry.Members, entry.Detail);
        for k = 1:numel(entry.Members)
            body = body + sprintf("<tr><td class=""name"">%s</td><td>%s</td></tr>\n", ...
                escapeHtml(entry.Members(k)), escapeHtml(described(k)));
        end
        body = body + "</table>" + newline;
    end

    if ~isempty(entry.Properties)
        body = body + "<h2>Properties</h2>" + newline + "<table>" + newline;
        for p = entry.Properties(:)'
            body = body + sprintf("<tr><td class=""name"">%s</td><td>%s</td></tr>\n", ...
                escapeHtml(p.Name), describeProperty(p));
        end
        body = body + "</table>" + newline;
    end

    if ~isempty(entry.Methods)
        body = body + "<h2>Methods</h2>" + newline;
        for group = unique(entry.MethodGroups, "stable")
            if strlength(group) > 0
                body = body + sprintf("<h3>%s</h3>\n", escapeHtml(group));
            end
            body = body + "<table>" + newline;
            for k = find(entry.MethodGroups == group)
                m = entry.Methods(k);
                summary = summaryOf(string(m.Description));
                if m.DefiningClass ~= entry.Name
                    summary = summary + " (inherited from " + ...
                        m.DefiningClass + ")";
                end
                body = body + sprintf("<tr><td class=""name""><a href=""%s"">%s</a></td>" + ...
                    "<td>%s</td></tr>\n", methodFile(entry.Name, m.Name), ...
                    escapeHtml(m.Name), escapeHtml(strtrim(summary)));
            end
            body = body + "</table>" + newline;
        end
    end

    % The class help gets the same sectioning the method pages get. For
    % IndividualCMF it runs to about 170 lines, including the constructor's
    % Name-Value table, and it was one preformatted block.
    body = body + renderSections(entry.Detail, pages, entry.Name, "Details");
    body = body + footer();
    writeText(fullfile(outDir, entry.Name + ".html"), body);
end

function writeMethodPage(outDir, entry, m, pages)
% One page per method, so the table of contents can navigate to it.
    body = header(entry.Name + "." + m.Name);
    body = body + sprintf("<h1>%s</h1>\n", escapeHtml(m.Name));
    body = body + sprintf("<p class=""purpose"">%s</p>\n", ...
        escapeHtml(summaryOf(string(m.Description))));
    body = body + sprintf("<p class=""parent"">Method of <a href=""%s.html"">%s</a></p>\n", ...
        entry.Name, escapeHtml(entry.Name));

    owner = m.DefiningClass;
    if owner ~= entry.Name
        body = body + sprintf("<p class=""inherited"">Inherited from " + ...
            "<code>%s</code>.</p>\n", escapeHtml(owner));
    end

    % Only the detail is rendered here. The summary line already appears above
    % as the page purpose, and repeating it opened every Description with a
    % sentence the reader had just read.
    detail = string(m.DetailedDescription);
    if strlength(strtrim(detail)) == 0 && strlength(strtrim(string(m.Description))) == 0
        % MATLAB seals some inherited methods, so there is nowhere to put help
        % for them. Naming the class that defines the method is not enough on
        % its own, since what a caller needs is how this class behaves under
        % it, and that is described on the class page.
        body = body + sprintf("<p class=""inherited"">MATLAB defines this method " + ...
            "on <code>%s</code> and it carries no help text of its own. See " + ...
            "<a href=""%s.html"">%s</a> for how it behaves here.</p>\n", ...
            escapeHtml(owner), entry.Name, escapeHtml(entry.Name));
    else
        body = body + renderSections(detail, pages, entry.Name, "Description");
    end
    body = body + footer();
    writeText(fullfile(outDir, methodFile(entry.Name, m.Name)), body);
end

function name = methodFile(className, methodName)
% File name for a method page, qualified by class so that two classes may
% share a method name without colliding.
    name = className + "." + methodName + ".html";
end

function text = describeProperty(p)
% One-sentence description of a property.
%
%   MATLAB splits a property help comment at the first line break, so
%   Description holds only the first line and the remainder goes to
%   DetailedDescription. A wrapped first sentence therefore arrives cut in
%   half. Rejoining them before taking the first sentence repairs that.
    joined = strtrim(string(p.Description)) + " " + ...
             strtrim(replace(string(p.DetailedDescription), newline, " "));
    text = escapeHtml(summaryOf(regexprep(joined, "\s+", " ")));
    if strlength(strtrim(text)) == 0
        text = "&nbsp;";
    end
end

function out = helpSections(text)
% Split a help block into its leading prose and any labelled sections.
%
%   Method help in this toolbox uses uppercase labels such as INPUTS:,
%   OPTIONAL INPUTS:, OUTPUTS: and EXAMPLE:. Rendering those as headings
%   rather than as one preformatted block is what makes the page read like
%   reference documentation instead of a terminal dump.
    out = struct("Heading", {}, "Body", {});
    lines = splitlines(string(text));
    heading = "";
    body = strings(0);
    for k = 1:numel(lines)
        trimmed = strtrim(lines(k));
        % A label only counts at the block's own indent. "Examples:" appears
        % nested inside an Inputs list, and "Standard observer:" is nested
        % inside the CIE170 property listing; promoting either to a heading
        % takes the rest of the block with it, which filed every CIE170
        % constant under Standard Observer.
        atBaseIndent = strlength(lines(k)) - strlength(strip(lines(k), "left")) <= 4;
        % Two standalone label styles appear in this toolbox's help.
        % Uppercase ones such as OUTPUTS: and OPTIONAL INPUTS (Name-Value
        % arguments):, and mixed case ones such as Reference: and Note:.
        isLabel = atBaseIndent && ( ...
                  ~isempty(regexp(trimmed, "^[A-Z][A-Z /-]{2,}(\s*\([^)]*\))?:$", "once")) || ...
                  ~isempty(regexp(trimmed, "^[A-Z][a-z]+(\s+[a-z]+){0,2}:$", "once")));
        % Some labels carry their content on the same line, so they open a
        % section rather than standing alone as one.
        inline = cell(0);
        if atBaseIndent
            % The colon is what separates a label from a sentence that
            % happens to open with a capitalised word. Without requiring it,
            % "IndividualCMF builds an L/M/S spectral sensitivity model"
            % becomes a heading. See also is the one label written without.
            inline = regexp(trimmed, "^(See also):?\s+(.*)$", "tokens", "once");
            if isempty(inline)
                inline = regexp(trimmed, ...
                    "^([A-Z][A-Za-z]*(?:\s+[a-z][A-Za-z]*){0,2}):\s+(\S.*)$", ...
                    "tokens", "once");
            end
        end
        if isLabel || ~isempty(inline)
            out(end+1) = struct("Heading", heading, "Body", strjoin(body, newline)); %#ok<AGROW>
            body = strings(0);
            if isempty(inline)
                heading = extractBefore(trimmed, strlength(trimmed));
            else
                heading = inline{1};
                body(end+1) = inline{2}; %#ok<AGROW>
            end
        else
            body(end+1) = lines(k); %#ok<AGROW>
        end
    end
    out(end+1) = struct("Heading", heading, "Body", strjoin(body, newline));
    keep = arrayfun(@(s) strlength(strtrim(s.Body)) > 0 || strlength(s.Heading) > 0, out);
    out = out(keep);
end

function writeHelpToc(tocPath, classes, hasGuide, examples)
% Generate helptoc.xml so the Help Browser shows the reference tree.
    lines = "<?xml version='1.0' encoding='UTF-8'?>";
    lines(end+1) = "<toc version=""2.0"">";
    lines(end+1) = "<tocitem target=""html/index.html"">Individual CMF Toolbox";
    if hasGuide
        lines(end+1) = "    <tocitem target=""html/GettingStarted.html"">Getting Started</tocitem>";
    end
    if ~isempty(examples)
        lines(end+1) = sprintf("    <tocitem target=""html/%s"">Examples", examples(1).File);
        for e = reshape(examples, 1, [])
            lines(end+1) = sprintf("        <tocitem target=""html/%s"">%s</tocitem>", ...
                e.File, escapeHtml(e.Title)); %#ok<AGROW>
        end
        lines(end+1) = "    </tocitem>";
    end
    lines(end+1) = "    <tocitem target=""html/index.html"">Reference";
    % One line per class and per method, grouped so the tree opens on the
    % entry point rather than on an alphabetical run of templates.
    % Walked in spec order rather than by unique group, so that a class with
    % no wrapper keeps its place. Collapsing the ungrouped entries into one
    % slot put CIE170 next to IndividualCMF instead of after the models.
    groups = arrayfun(@(c) groupOf(c.Name), classes);
    written = strings(0);
    for k = 1:numel(classes)
        group = groups(k);
        [parent, heading] = splitGroup(group);
        if strlength(parent) > 0
            % Emitted inside its parent class's node, not here.
            continue
        end
        if isLeafGroup(group)
            lines = [lines, classToc(classes, k, groups, 8)]; %#ok<AGROW>
            continue
        end
        if ismember(group, written)
            continue
        end
        written(end+1) = group; %#ok<AGROW>
        lines(end+1) = sprintf("        <tocitem target=""html/%s"">%s", ...
            groupFile(group), heading); %#ok<AGROW>
        for j = find(groups == group)
            lines = [lines, classToc(classes, j, groups, 12)]; %#ok<AGROW>
        end
        lines(end+1) = "        </tocitem>"; %#ok<AGROW>
    end
    lines(end+1) = "    </tocitem>";
    lines(end+1) = "</tocitem>";
    lines(end+1) = "</toc>";
    writeText(tocPath, strjoin(lines, newline));
end

function lines = classToc(classes, k, groups, indent)
% One class node: its method categories, then any group nested under it.
    pad = @(n) blanks(indent + n);
    name = classes(k).Name;
    lines = sprintf("%s<tocitem target=""html/%s.html"">%s", pad(0), name, name);
    byGroup = classes(k).MethodGroups;
    for category = unique(byGroup, "stable")
        named = strlength(category) > 0;
        if named
            lines(end+1) = sprintf("%s<tocitem target=""html/%s.html"">%s", ...
                pad(4), name, category); %#ok<AGROW>
        end
        for j = find(byGroup == category)
            lines(end+1) = sprintf("%s<tocitem target=""html/%s"">%s</tocitem>", ...
                pad(4 + 4 * named), ...
                methodFile(name, classes(k).Methods(j).Name), ...
                classes(k).Methods(j).Name); %#ok<AGROW>
        end
        if named
            lines(end+1) = sprintf("%s</tocitem>", pad(4)); %#ok<AGROW>
        end
    end
    % Groups written as "ThisClass/Heading" hang here rather than at the top
    % level, which is how the output enumerations reach the observer whose
    % properties they set.
    for nested = unique(groups(startsWith(groups, name + "/")), "stable")
        [~, heading] = splitGroup(nested);
        lines(end+1) = sprintf("%s<tocitem target=""html/%s"">%s", ...
            pad(4), groupFile(nested), heading); %#ok<AGROW>
        for j = find(groups == nested)
            lines(end+1) = sprintf("%s<tocitem target=""html/%s.html"">%s</tocitem>", ...
                pad(8), classes(j).Name, classes(j).Name); %#ok<AGROW>
        end
        lines(end+1) = sprintf("%s</tocitem>", pad(4)); %#ok<AGROW>
    end
    lines(end+1) = sprintf("%s</tocitem>", pad(0));
end

function out = header(pageTitle)
% Page preamble, with styling inlined so the pages need no other files.
%
%   The Help Browser loads these pages inside a frame and supplies its own
%   header, search and navigation. Only the content area is styled here, and
%   it follows MATLAB's documentation conventions rather than inventing a
%   look of its own.
    css = ["body{font-family:Helvetica,Arial,sans-serif;font-size:14px;margin:0 auto;" + ...
           "max-width:54em;line-height:1.55;color:#262626;padding:1.2em}", ...
           "a{color:#0071bc;text-decoration:none}", ...
           "a:visited{color:#0071bc}", ...
           "a:hover{text-decoration:underline}", ...
           "h1{font-size:1.9em;font-weight:400;margin:0 0 .2em;color:#d9730d}", ...
           "h2{font-size:1.15em;font-weight:700;margin:1.8em 0 .5em;" + ...
           "border-bottom:1px solid #ddd;padding-bottom:.25em}", ...
           "h3{font-size:.95em;font-weight:700;margin:1.4em 0 .1em;color:#404040}", ...
           "p.purpose{font-size:1em;color:#404040;margin:0 0 1.4em}", ...
           "p.parent,p.inherited{color:#666;font-size:.92em;margin:.2em 0 1em}", ...
           "p.routes{margin:.2em 0 1.6em}", ...
           "p.seealso{background:#f7f7f7;border:1px solid #e6e6e6;padding:.8em;" + ...
           "margin:.6em 0}", ...
           "table{border-collapse:collapse;width:100%;margin:.6em 0}", ...
           "td{text-align:left;vertical-align:top;padding:.45em .7em;" + ...
           "border-bottom:1px solid #e6e6e6}", ...
           "td.name{width:16em;font-family:Menlo,Consolas,monospace;font-size:.92em}", ...
           "code{font-family:Menlo,Consolas,monospace;font-size:.95em}", ...
           "pre{background:#f7f7f7;border:1px solid #e6e6e6;padding:.8em;" + ...
           "overflow-x:auto;font-family:Menlo,Consolas,monospace;font-size:.88em;" + ...
           "white-space:pre-wrap}", ...
           "footer{margin-top:3em;padding-top:1em;border-top:1px solid #ddd;" + ...
           "color:#767676;font-size:.85em}"];
    out = "<!DOCTYPE html>" + newline + "<html><head>" + newline + ...
          "<meta charset=""utf-8""/>" + newline + ...
          sprintf("<title>%s</title>\n", escapeHtml(pageTitle)) + ...
          "<style>" + strjoin(css, newline) + "</style>" + newline + ...
          "</head><body>" + newline;
end

function out = footer()
% Page close, including the note that the pages are generated.
    out = "<footer>Generated from the class metadata by " + ...
          "<code>buildtool doc</code>. Do not edit these pages: edit the help " + ...
          "comments in the class files instead." + newline + ...
          "Copyright 2025-2026 Alexander Forsythe and Brian Funt. " + ...
          "Simon Fraser University.</footer>" + newline + "</body></html>" + newline;
end

function out = dedent(text)
% Left-align a help block on its first line, keeping its relative structure.
%
%   Help comments carry two indent levels: a base level for prose and a
%   deeper one for list entries. A section that opens with a list entry and
%   later drops back to a prose paragraph therefore has its smallest indent
%   set by the paragraph, not by the entry. Removing that smallest indent
%   leaves every entry hanging while the paragraph sits flush, which is the
%   ragged look this avoids.
%
%   The first line sets the baseline instead. Deeper lines keep the
%   difference, so nesting survives, and shallower ones are pulled flush.
    lines = splitlines(string(text));
    filled = strlength(strtrim(lines)) > 0;
    if ~any(filled)
        out = "";
        return
    end
    lines = lines(find(filled, 1):find(filled, 1, "last"));
    indents = strlength(lines) - strlength(strip(lines, "left"));
    baseline = indents(1);
    for k = 1:numel(lines)
        if strlength(strtrim(lines(k))) == 0
            lines(k) = "";
        elseif indents(k) > baseline
            lines(k) = extractAfter(lines(k), baseline);
        else
            lines(k) = strip(lines(k), "left");
        end
    end
    out = strjoin(lines, newline);
end

function out = summaryOf(text)
% First sentence of a help block, used as a one-line summary.
%
%   Help text is wrapped, so the first line is usually half a sentence. This
%   joins the leading paragraph and then cuts at the first sentence end.
    out = "";
    parts = strtrim(splitlines(string(text)));
    first = find(strlength(parts) > 0, 1);
    if isempty(first)
        return
    end
    last = first;
    while last < numel(parts) && strlength(parts(last + 1)) > 0
        last = last + 1;
    end
    out = strjoin(parts(first:last), " ");
    % A sentence ends at a period followed by a capital, or by nothing. The
    % capital may be preceded by an opening quote or bracket. Cutting at any
    % period instead ends half the template summaries at "et al.".
    stop = regexp(out, "\.(\s+\W?[A-Z]|\s*$)", "once");
    if ~isempty(stop)
        out = extractBefore(out, stop + 1);
    end
end

function out = truncate(text, maxChars)
% Shorten to a word boundary, for table cells where a full sentence is too long.
    out = string(text);
    if strlength(out) <= maxChars
        return
    end
    clipped = extractBefore(out, maxChars + 1);
    lastSpace = find(char(clipped) == ' ', 1, "last");
    if ~isempty(lastSpace)
        clipped = extractBefore(clipped, lastSpace);
    end
    out = strtrim(clipped) + "...";
end

function out = titleCase(text)
% Render an uppercase help label as a heading, so OPTIONAL INPUTS: becomes
% Optional Inputs.
    chars = char(lower(strtrim(string(text))));
    capitalise = true;
    for k = 1:numel(chars)
        if capitalise && isletter(chars(k))
            chars(k) = upper(chars(k));
            capitalise = false;
        elseif any(chars(k) == ' -(')
            capitalise = true;
        end
    end
    out = string(chars);
end

function out = escapeHtml(text)
% Escape the five characters that would otherwise be markup.
    out = string(text);
    out = replace(out, "&", "&amp;");
    out = replace(out, "<", "&lt;");
    out = replace(out, ">", "&gt;");
    out = replace(out, """", "&quot;");
    out = replace(out, "'", "&#39;");
end

function writeText(path, text)
% Write a UTF-8 text file, creating the folder if needed.
    folder = fileparts(path);
    if strlength(folder) > 0 && ~isfolder(folder)
        mkdir(folder);
    end
    fid = fopen(path, "w", "n", "UTF-8");
    if fid < 0
        error("generateDocs:CannotWrite", "Could not open '%s' for writing.", path);
    end
    closer = onCleanup(@() fclose(fid));
    fwrite(fid, unicode2native(text, "UTF-8"));
end

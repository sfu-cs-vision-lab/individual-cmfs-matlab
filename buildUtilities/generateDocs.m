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
        options.BuildIndex (1,1) logical = true
        options.Verbose (1,1) logical = true
    end

    outDir = options.OutputDir;
    if ~isfolder(outDir)
        mkdir(outDir);
    end

    classes = collectMetadata(options.Classes);

    pages = pageLookup(classes);

    % The guide and the examples are exported first so that the landing page
    % can route to them, and link only to what was actually written.
    hasGuide = strlength(options.GettingStarted) > 0 && isfile(options.GettingStarted);
    if hasGuide
        export(options.GettingStarted, fullfile(outDir, "GettingStarted.html"), Run=false);
    end
    examples = exportExamples(outDir, options.Examples);

    pageCount = 1 + hasGuide + numel(examples);
    writeIndexPage(outDir, classes, hasGuide, examples);
    for group = unique(arrayfun(@(c) groupOf(c.Name), classes), "stable")
        writeGroupPage(outDir, group, classes);
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
        entry.Detail = string(mc.DetailedDescription);
        % The summary line of the class help, when there is one. Falling
        % straight to the detail picks up whatever the body happens to open
        % with, which on an enumeration is the first member rather than a
        % description of the class.
        entry.Summary = summaryOf(string(mc.Description));
        if strlength(entry.Summary) == 0
            entry.Summary = summaryOf(entry.Detail);
        end
        props = mc.PropertyList;
        keep = strcmp({props.GetAccess}, 'public') & ~[props.Hidden];
        entry.Properties = props(keep);
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
        [entry.Methods, entry.MethodGroups] = orderMethods(name, meths);
        % One entry per documented class, so the array stays tiny.
        classes(end+1) = entry; %#ok<AGROW>
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

function examples = exportExamples(outDir, folder)
% Export the worked examples so the Help Browser can show them.
%
%   The examples are the toolbox's main teaching material and were reachable
%   only by opening them in the editor. Getting Started links to all twenty
%   of them, and every one of those links pointed outside the doc folder.
    examples = struct("File", {}, "Title", {});
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
        source = fullfile(item.folder, item.name);
        [~, stem] = fileparts(item.name);
        export(source, fullfile(outDir, stem + ".html"), Run=false);
        examples(end+1) = struct("File", stem + ".html", ...
                                 "Title", exampleTitle(source)); %#ok<AGROW>
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
    spec = [ ...
        "Observers",            "IndividualCMF"; ...
        "Observers",            "ObserverParameters"; ...
        "Observers",            "PhotopigmentParameters"; ...
        "Observers",            "PreReceptoralFilter"; ...
        "Observers",            "Genotype"; ...
        "Photopigment Models",  "PhotopigmentTemplate"; ...
        "Photopigment Models",  "StockmanRiderPhotopigmentTemplate"; ...
        "Photopigment Models",  "StockmanRiderCommonPhotopigmentTemplate"; ...
        "Photopigment Models",  "GovardovskiiPhotopigmentTemplate"; ...
        "Photopigment Models",  "enums.PhotopigmentModel"; ...
        "Photopigment Models",  "enums.PhotopigmentDensityAlgorithm"; ...
        "Photopigment Models",  "enums.LOpsinTemplate"; ...
        "Photopigment Models",  "enums.MOpsinTemplate"; ...
        "Photopigment Models",  "Nomograms"; ...
        "Lens Models",          "LensTemplate"; ...
        "Lens Models",          "StockmanRiderLensTemplate"; ...
        "Lens Models",          "Pokorny1987LensTemplate"; ...
        "Lens Models",          "VanDeKraatsVanNorren2007LensTemplate"; ...
        "Lens Models",          "enums.LensModel"; ...
        "Lens Models",          "enums.LensDensityAlgorithm"; ...
        "Macular Models",       "MacularTemplate"; ...
        "Macular Models",       "StockmanRider2023MacularTemplate"; ...
        "Macular Models",       "enums.MacularModel"; ...
        "Macular Models",       "enums.MacularDensityAlgorithm"; ...
        "Output and Normalization", "enums.OutputFormat"; ...
        "Output and Normalization", "enums.NormalizationMethod"; ...
        "Pipeline Stages",      "pipeline.PhotopigmentStage"; ...
        "Pipeline Stages",      "pipeline.PreReceptoralStage"; ...
        "Pipeline Stages",      "pipeline.OutputStage"; ...
        "Reference Data",       "CIE170"];
end

function spec = methodSpec(className)
% Categories for a class's methods, or empty for alphabetical order.
%
%   Alphabetical order files LMS between lmChromaticity and Luminance, and
%   scatters the twelve plotting methods through the middle of the list. The
%   result reads as a word list rather than an API. IndividualCMF has
%   thirty-three methods and is the only class where this matters.
%
%   A method missing from this table, or named here but not defined, fails
%   the doc build rather than quietly falling out of the reference.
    spec = strings(0, 2);
    if className ~= "IndividualCMF"
        return
    end
    spec = [ ...
        "Create and Configure", "across"; ...
        "Create and Configure", "applyGenotype"; ...
        "Create and Configure", "setGenotype"; ...
        "Create and Configure", "getParameters"; ...
        "Create and Configure", "setParameters"; ...
        "Create and Configure", "copy"; ...
        "Cone Sensitivities",   "LMS"; ...
        "Cone Sensitivities",   "L"; ...
        "Cone Sensitivities",   "M"; ...
        "Cone Sensitivities",   "S"; ...
        "Cone Sensitivities",   "getPeak"; ...
        "Derived Quantities",   "XYZ"; ...
        "Derived Quantities",   "RGB"; ...
        "Derived Quantities",   "Luminance"; ...
        "Derived Quantities",   "MacLeodBoynton"; ...
        "Derived Quantities",   "lmChromaticity"; ...
        "Derived Quantities",   "xyChromaticity"; ...
        "Derived Quantities",   "neutralColor"; ...
        "Derived Quantities",   "evaluate"; ...
        "Filter Spectra",       "getLensDensitySpectrum"; ...
        "Filter Spectra",       "getMacularDensitySpectrum"; ...
        "Plot and Compare",     "plot"; ...
        "Plot and Compare",     "plotLMS"; ...
        "Plot and Compare",     "plotXYZ"; ...
        "Plot and Compare",     "plotRGBCMFs"; ...
        "Plot and Compare",     "plotChromaticity"; ...
        "Plot and Compare",     "plotAbsorbance"; ...
        "Plot and Compare",     "plotAbsorptance"; ...
        "Plot and Compare",     "plotQuantalEnergy"; ...
        "Plot and Compare",     "plotLens"; ...
        "Plot and Compare",     "plotMacular"; ...
        "Plot and Compare",     "plotDiagnostics"; ...
        "Plot and Compare",     "compareTo"];
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
    groups = arrayfun(@(c) groupOf(c.Name), classes);
    for group = unique(groups, "stable")
        body = body + sprintf("<h2><a href=""%s"">%s</a></h2>\n<table>\n", ...
            groupFile(group), escapeHtml(group));
        for k = find(groups == group)
            body = body + classRow(classes(k));
        end
        body = body + "</table>" + newline;
    end
    body = body + footer();
    writeText(fullfile(outDir, "index.html"), body);
end

function writeGroupPage(outDir, group, classes)
% One page per group, so a group heading in the contents tree lands
% somewhere. Every group tocitem otherwise targets the top of the full
% landing page, and a fragment cannot rescue it inside the Help Browser
% frame for the same reason method anchors could not.
    body = header(group);
    body = body + sprintf("<h1>%s</h1>\n", escapeHtml(group));
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
    out = "group-" + lower(replace(strtrim(string(group)), " ", "-")) + ".html";
end

function writeClassPage(outDir, entry, pages)
% Class page: purpose, property table, and a linked list of methods.
    body = header(entry.Name);
    body = body + sprintf("<h1>%s</h1>\n", escapeHtml(entry.Name));
    body = body + sprintf("<p class=""purpose"">%s</p>\n", escapeHtml(entry.Summary));
    group = groupOf(entry.Name);
    body = body + sprintf("<p class=""parent"">In <a href=""%s"">%s</a></p>\n", ...
        groupFile(group), escapeHtml(group));

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
                if string(m.DefiningClass.Name) ~= entry.Name
                    summary = summary + " (inherited from " + ...
                        string(m.DefiningClass.Name) + ")";
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

    owner = string(m.DefiningClass.Name);
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
        % Two label styles appear in this toolbox's help. Uppercase ones such
        % as OUTPUTS: and OPTIONAL INPUTS (Name-Value arguments):, and mixed
        % case ones such as Reference: and Note:. Both become headings.
        isLabel = ~isempty(regexp(trimmed, "^[A-Z][A-Z /-]{2,}(\s*\([^)]*\))?:$", "once")) || ...
                  ~isempty(regexp(trimmed, "^[A-Z][a-z]+(\s+[a-z]+){0,2}:$", "once"));
        % Some labels carry their content on the same line, so they open a
        % section rather than standing alone as one. Only at the block's own
        % indent: "Examples:" appears nested inside an Inputs list, and
        % promoting that to a heading would break the list apart.
        inline = cell(0);
        if strlength(lines(k)) - strlength(strip(lines(k), "left")) <= 4
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
    groups = arrayfun(@(c) groupOf(c.Name), classes);
    for group = unique(groups, "stable")
        lines(end+1) = sprintf("        <tocitem target=""html/%s"">%s", ...
            groupFile(group), group); %#ok<AGROW>
        for k = find(groups == group)
            lines(end+1) = sprintf("            <tocitem target=""html/%s.html"">%s", ...
                classes(k).Name, classes(k).Name); %#ok<AGROW>
            % Categories nest one level deeper so the sidebar can collapse
            % them. Twelve plotting methods otherwise sit open between the
            % class and whatever follows it.
            byGroup = classes(k).MethodGroups;
            for category = unique(byGroup, "stable")
                named = strlength(category) > 0;
                if named
                    lines(end+1) = sprintf("                <tocitem target=""html/%s.html"">%s", ...
                        classes(k).Name, category); %#ok<AGROW>
                end
                for j = find(byGroup == category)
                    lines(end+1) = sprintf("%s<tocitem target=""html/%s"">%s</tocitem>", ...
                        blanks(16 + 4 * named), ...
                        methodFile(classes(k).Name, classes(k).Methods(j).Name), ...
                        classes(k).Methods(j).Name); %#ok<AGROW>
                end
                if named
                    lines(end+1) = "                </tocitem>"; %#ok<AGROW>
                end
            end
            lines(end+1) = "            </tocitem>"; %#ok<AGROW>
        end
        lines(end+1) = "        </tocitem>"; %#ok<AGROW>
    end
    lines(end+1) = "    </tocitem>";
    lines(end+1) = "</tocitem>";
    lines(end+1) = "</toc>";
    writeText(tocPath, strjoin(lines, newline));
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

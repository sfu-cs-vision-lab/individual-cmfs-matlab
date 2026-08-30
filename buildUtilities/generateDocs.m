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
%                   (string array). Default is the five public classes.
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
        options.Classes (1,:) string = ["IndividualCMF", "ObserverParameters", ...
                                        "Genotype", "Nomograms", "CIE170"]
        options.GettingStarted (1,1) string = fullfile("toolbox", "doc", "GettingStarted.m")
        options.BuildIndex (1,1) logical = true
        options.Verbose (1,1) logical = true
    end

    outDir = options.OutputDir;
    if ~isfolder(outDir)
        mkdir(outDir);
    end

    classes = collectMetadata(options.Classes);

    pageCount = 1;
    writeIndexPage(outDir, classes);
    for k = 1:numel(classes)
        writeClassPage(outDir, classes(k));
        pageCount = pageCount + 1;
        for m = classes(k).Methods(:)'
            writeMethodPage(outDir, classes(k), m);
            pageCount = pageCount + 1;
        end
    end

    hasGuide = strlength(options.GettingStarted) > 0 && isfile(options.GettingStarted);
    if hasGuide
        export(options.GettingStarted, fullfile(outDir, "GettingStarted.html"), Run=false);
        pageCount = pageCount + 1;
    end

    docDir = fileparts(outDir);
    writeHelpToc(fullfile(docDir, "helptoc.xml"), classes, hasGuide);

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
                     "Properties", {}, "Methods", {});
    for name = classNames
        mc = resolveClass(name);
        entry.Name = name;
        entry.Detail = string(mc.DetailedDescription);
        entry.Summary = summaryOf(entry.Detail);
        props = mc.PropertyList;
        keep = strcmp({props.GetAccess}, 'public') & ~[props.Hidden];
        entry.Properties = props(keep);
        meths = mc.MethodList;
        keep = strcmp({meths.Access}, 'public') & ~[meths.Hidden];
        meths = meths(keep);
        meths = meths(~ismember(string({meths.Name}), [skip, name]));
        [~, order] = sort(lower(string({meths.Name})));
        entry.Methods = meths(order);
        % One entry per documented class, so the array stays tiny.
        classes(end+1) = entry; %#ok<AGROW>
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

function writeIndexPage(outDir, classes)
% Landing page: what the toolbox is, and the classes it exposes.
    body = header("Individual CMF Toolbox");
    body = body + "<h1>Individual CMF Toolbox</h1>" + newline;
    body = body + "<p class=""purpose"">Observer-specific LMS cone spectral " + ...
        "sensitivities from biophysical parameters, and the quantities derived " + ...
        "from them</p>" + newline;
    body = body + "<h2>Classes</h2>" + newline + "<table>" + newline;
    for k = 1:numel(classes)
        body = body + sprintf("<tr><td class=""name""><a href=""%s.html"">%s</a></td>" + ...
            "<td>%s</td></tr>\n", classes(k).Name, classes(k).Name, ...
            escapeHtml(truncate(classes(k).Summary, 170)));
    end
    body = body + "</table>" + newline + footer();
    writeText(fullfile(outDir, "index.html"), body);
end

function writeClassPage(outDir, entry)
% Class page: purpose, property table, and a linked list of methods.
    body = header(entry.Name);
    body = body + sprintf("<h1>%s</h1>\n", escapeHtml(entry.Name));
    body = body + sprintf("<p class=""purpose"">%s</p>\n", escapeHtml(entry.Summary));

    if ~isempty(entry.Properties)
        body = body + "<h2>Properties</h2>" + newline + "<table>" + newline;
        for p = entry.Properties(:)'
            body = body + sprintf("<tr><td class=""name"">%s</td><td>%s</td></tr>\n", ...
                escapeHtml(p.Name), describeProperty(p));
        end
        body = body + "</table>" + newline;
    end

    if ~isempty(entry.Methods)
        body = body + "<h2>Methods</h2>" + newline + "<table>" + newline;
        for m = entry.Methods(:)'
            summary = summaryOf(string(m.Description));
            if string(m.DefiningClass.Name) ~= entry.Name
                summary = summary + " (inherited from " + string(m.DefiningClass.Name) + ")";
            end
            body = body + sprintf("<tr><td class=""name""><a href=""%s"">%s</a></td>" + ...
                "<td>%s</td></tr>\n", methodFile(entry.Name, m.Name), ...
                escapeHtml(m.Name), escapeHtml(strtrim(summary)));
        end
        body = body + "</table>" + newline;
    end

    body = body + "<h2>Details</h2>" + newline;
    body = body + sprintf("<pre>%s</pre>\n", escapeHtml(entry.Detail));
    body = body + footer();
    writeText(fullfile(outDir, entry.Name + ".html"), body);
end

function writeMethodPage(outDir, entry, m)
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

    detail = strtrim(string(m.Description)) + newline + string(m.DetailedDescription);
    if strlength(strtrim(detail)) == 0
        body = body + sprintf("<p class=""inherited"">No help text is defined for " + ...
            "this method. See the documentation for <code>%s</code>.</p>\n", ...
            escapeHtml(owner));
    else
        for section = helpSections(detail)
            if strlength(section.Heading) > 0
                body = body + sprintf("<h2>%s</h2>\n", ...
                    escapeHtml(titleCase(section.Heading)));
            else
                body = body + "<h2>Description</h2>" + newline;
            end
            body = body + sprintf("<pre>%s</pre>\n", escapeHtml(strtrim(section.Body)));
        end
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
        isLabel = ~isempty(regexp(trimmed, "^[A-Z][A-Z /-]{2,}(\s*\([^)]*\))?:$", "once"));
        if isLabel
            out(end+1) = struct("Heading", heading, "Body", strjoin(body, newline)); %#ok<AGROW>
            heading = extractBefore(trimmed, strlength(trimmed));
            body = strings(0);
        else
            body(end+1) = lines(k); %#ok<AGROW>
        end
    end
    out(end+1) = struct("Heading", heading, "Body", strjoin(body, newline));
    keep = arrayfun(@(s) strlength(strtrim(s.Body)) > 0 || strlength(s.Heading) > 0, out);
    out = out(keep);
end

function writeHelpToc(tocPath, classes, hasGuide)
% Generate helptoc.xml so the Help Browser shows the reference tree.
    lines = "<?xml version='1.0' encoding='UTF-8'?>";
    lines(end+1) = "<toc version=""2.0"">";
    lines(end+1) = "<tocitem target=""html/index.html"">Individual CMF Toolbox";
    if hasGuide
        lines(end+1) = "    <tocitem target=""html/GettingStarted.html"">Getting Started</tocitem>";
    end
    lines(end+1) = "    <tocitem target=""html/index.html"">Reference";
    % One line per class and per method, so growth is bounded and small.
    for k = 1:numel(classes)
        lines(end+1) = sprintf("        <tocitem target=""html/%s.html"">%s", ...
            classes(k).Name, classes(k).Name); %#ok<AGROW>
        for m = classes(k).Methods(:)'
            lines(end+1) = sprintf("            <tocitem target=""html/%s"">%s</tocitem>", ...
                methodFile(classes(k).Name, m.Name), m.Name); %#ok<AGROW>
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
           "p.purpose{font-size:1em;color:#404040;margin:0 0 1.4em}", ...
           "p.parent,p.inherited{color:#666;font-size:.92em;margin:.2em 0 1em}", ...
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
    stop = regexp(out, "\.(\s|$)", "once");
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

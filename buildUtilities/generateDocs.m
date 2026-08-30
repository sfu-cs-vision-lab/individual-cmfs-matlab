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
%   OPTIONAL INPUTS:
%       OutputDir - folder to write the pages into (string).
%                   Default fullfile("toolbox", "doc", "html").
%       Classes   - classes to document, in the order they should appear
%                   (string array). Default is the five public classes.
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
        options.BuildIndex (1,1) logical = true
        options.Verbose (1,1) logical = true
    end

    outDir = options.OutputDir;
    if ~isfolder(outDir)
        mkdir(outDir);
    end

    classes = collectMetadata(options.Classes);

    writeIndexPage(outDir, classes);
    for k = 1:numel(classes)
        writeClassPage(outDir, classes(k));
    end
    docDir = fileparts(outDir);
    writeHelpToc(fullfile(docDir, "helptoc.xml"), classes);

    if options.Verbose
        fprintf("Wrote %d pages to %s\n", numel(classes) + 1, outDir);
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
    body = body + "<p class=""lead"">Observer-specific LMS cone spectral sensitivities " + ...
        "computed from biophysical parameters, and the quantities derived from them.</p>" + newline;
    body = body + "<p>Start with the <b>Getting Started</b> guide, which maps the " + ...
        "twenty worked examples. This reference documents the public classes.</p>" + newline;
    body = body + "<h2>Classes</h2>" + newline + "<table>" + newline;
    body = body + "<tr><th>Class</th><th>Summary</th><th>Properties</th><th>Methods</th></tr>" + newline;
    for k = 1:numel(classes)
        body = body + sprintf("<tr><td><a href=""%s.html""><code>%s</code></a></td>" + ...
            "<td>%s</td><td>%d</td><td>%d</td></tr>\n", classes(k).Name, classes(k).Name, ...
            escapeHtml(truncate(classes(k).Summary, 170)), ...
            numel(classes(k).Properties), numel(classes(k).Methods));
    end
    body = body + "</table>" + newline + footer();
    writeText(fullfile(outDir, "index.html"), body);
end

function writeClassPage(outDir, entry)
% One page per class: description, then properties, then methods.
    body = header(entry.Name);
    body = body + sprintf("<h1><code>%s</code></h1>\n", entry.Name);
    body = body + sprintf("<p class=""lead"">%s</p>\n", escapeHtml(entry.Summary));
    body = body + "<p><a href=""index.html"">Back to the class list</a></p>" + newline;

    if ~isempty(entry.Properties)
        body = body + "<h2>Properties</h2>" + newline + "<table>" + newline;
        body = body + "<tr><th>Name</th><th>Description</th></tr>" + newline;
        for p = entry.Properties(:)'
            body = body + sprintf("<tr><td id=""%s""><code>%s</code></td><td>%s</td></tr>\n", ...
                p.Name, p.Name, describeProperty(p));
        end
        body = body + "</table>" + newline;
    end

    if ~isempty(entry.Methods)
        body = body + "<h2>Methods</h2>" + newline + "<table>" + newline;
        body = body + "<tr><th>Name</th><th>Summary</th></tr>" + newline;
        for m = entry.Methods(:)'
            body = body + sprintf("<tr><td><a href=""#%s""><code>%s</code></a></td><td>%s</td></tr>\n", ...
                m.Name, m.Name, escapeHtml(summaryOf(string(m.Description))));
        end
        body = body + "</table>" + newline;
        for m = entry.Methods(:)'
            body = body + sprintf("<h3 id=""%s""><code>%s</code></h3>\n", m.Name, m.Name);
            detail = string(m.DetailedDescription);
            if strlength(strtrim(detail)) == 0
                detail = string(m.Description);
            end
            body = body + sprintf("<pre>%s</pre>\n", escapeHtml(detail));
        end
    end

    body = body + "<h2>Class help</h2>" + newline;
    body = body + sprintf("<pre>%s</pre>\n", escapeHtml(entry.Detail));
    body = body + footer();
    writeText(fullfile(outDir, entry.Name + ".html"), body);
end

function text = describeProperty(p)
% Prefer the one-line description, fall back to the detailed one.
    text = string(p.Description);
    if strlength(strtrim(text)) == 0
        text = summaryOf(string(p.DetailedDescription));
    end
    text = escapeHtml(text);
    if strlength(strtrim(text)) == 0
        text = "&nbsp;";
    end
end

function writeHelpToc(tocPath, classes)
% Generate helptoc.xml so the Help Browser shows the reference tree.
    lines = "<?xml version='1.0' encoding='UTF-8'?>";
    lines(end+1) = "<toc version=""2.0"">";
    lines(end+1) = "<tocitem target=""html/index.html"">Individual CMF Toolbox";
    lines(end+1) = "    <tocitem target=""GettingStarted.m"">Getting Started</tocitem>";
    lines(end+1) = "    <tocitem target=""html/index.html"">Reference";
    % One line per class and per method, so growth is bounded and small.
    for k = 1:numel(classes)
        lines(end+1) = sprintf("        <tocitem target=""html/%s.html"">%s", ...
            classes(k).Name, classes(k).Name); %#ok<AGROW>
        for m = classes(k).Methods(:)'
            lines(end+1) = sprintf("            <tocitem target=""html/%s.html#%s"">%s</tocitem>", ...
                classes(k).Name, m.Name, m.Name); %#ok<AGROW>
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
    css = ["body{font-family:Helvetica,Arial,sans-serif;margin:2em auto;max-width:52em;" + ...
           "line-height:1.5;color:#222;padding:0 1em}", ...
           "h1{font-size:1.7em;border-bottom:2px solid #333;padding-bottom:.3em}", ...
           "h2{font-size:1.25em;margin-top:1.8em;border-bottom:1px solid #ccc;padding-bottom:.2em}", ...
           "h3{font-size:1.05em;margin-top:1.6em;background:#f4f4f4;padding:.35em .5em;border-left:3px solid #666}", ...
           "p.lead{font-size:1.05em;color:#444}", ...
           "table{border-collapse:collapse;width:100%;margin:.8em 0}", ...
           "th,td{text-align:left;vertical-align:top;padding:.4em .6em;border-bottom:1px solid #ddd}", ...
           "th{background:#f4f4f4}", ...
           "code{font-family:Menlo,Consolas,monospace;font-size:.95em}", ...
           "pre{background:#f8f8f8;border:1px solid #e0e0e0;padding:.8em;overflow-x:auto;" + ...
           "font-family:Menlo,Consolas,monospace;font-size:.88em;white-space:pre-wrap}", ...
           "footer{margin-top:3em;padding-top:1em;border-top:1px solid #ccc;color:#666;font-size:.9em}"];
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
    stop = regexp(out, "\\.(\\s|$)", "once");
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

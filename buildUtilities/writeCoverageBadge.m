function writeCoverageBadge(badgeFile, coverageFile)
% WRITECOVERAGEBADGE  Write a shields.io endpoint JSON for line coverage.
%
%   writeCoverageBadge(badgeFile, coverageFile) parses a Cobertura coverage
%   report and writes a shields.io endpoint badge to BADGEFILE with the
%   overall line-rate percentage.
%
%   INPUTS:
%       badgeFile    - (1,1) string. Output JSON file path.
%       coverageFile - (1,1) string. Cobertura XML report path.
%
% SPDX-License-Identifier: AGPL-3.0-or-later
%
% Copyright 2025-2026 Alexander Forsythe and Brian Funt. Simon Fraser University.

arguments
    badgeFile (1,1) string
    coverageFile (1,1) string
end

    if ~isfile(coverageFile)
        error('writeCoverageBadge:MissingFile', ...
            'Coverage file not found: %s', coverageFile);
    end

    doc = readstruct(coverageFile, FileType = "xml");
    lineRate = double(doc.line_rateAttribute);
    pct = round(lineRate * 100);

    if pct >= 90
        color = "brightgreen";
    elseif pct >= 75
        color = "green";
    elseif pct >= 60
        color = "yellow";
    elseif pct >= 40
        color = "orange";
    else
        color = "red";
    end

    badge = struct( ...
        schemaVersion = 1, ...
        label = "coverage", ...
        message = sprintf('%d%%', pct), ...
        color = color);

    writeBadgeJson(badgeFile, badge);
end

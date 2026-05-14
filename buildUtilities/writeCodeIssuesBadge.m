function writeCodeIssuesBadge(badgeFile, nIssues)
% WRITECODEISSUESBADGE  Write a shields.io endpoint JSON for code issue count.
%
%   writeCodeIssuesBadge(badgeFile, nIssues) writes a shields.io endpoint
%   badge to BADGEFILE indicating the number of code issues. Color is
%   green if zero, yellow up to 5, orange up to 20, otherwise red.
%
%   INPUTS:
%       badgeFile - (1,1) string. Output JSON file path.
%       nIssues   - (1,1) double. Issue count.
%
% SPDX-License-Identifier: AGPL-3.0-or-later
%
% Copyright 2025-2026 Alexander Forsythe and Brian Funt. Simon Fraser University.

arguments
    badgeFile (1,1) string
    nIssues (1,1) double {mustBeInteger, mustBeNonnegative}
end

    if nIssues == 0
        color = "brightgreen";
    elseif nIssues <= 5
        color = "yellow";
    elseif nIssues <= 20
        color = "orange";
    else
        color = "red";
    end

    badge = struct( ...
        schemaVersion = 1, ...
        label = "code issues", ...
        message = sprintf('%d', nIssues), ...
        color = color);

    writeBadgeJson(badgeFile, badge);
end

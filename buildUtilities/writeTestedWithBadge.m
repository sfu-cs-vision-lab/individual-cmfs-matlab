function writeTestedWithBadge(badgeFile)
% WRITETESTEDWITHBADGE  Write a shields.io endpoint JSON for tested-with versions.
%
%   The list of MATLAB releases is the source of truth in CI matrix; this
%   helper records the current MATLAB release executing the build, which
%   the CI workflow consolidates across matrix runs.
%
%   INPUTS:
%       badgeFile - (1,1) string. Output JSON file path.
%
% SPDX-License-Identifier: AGPL-3.0-or-later
%
% Copyright 2025-2026 Alexander Forsythe and Brian Funt. Simon Fraser University.

arguments
    badgeFile (1,1) string
end

    releases = string(version('-release'));
    badge = struct( ...
        schemaVersion = 1, ...
        label = "tested with", ...
        message = "R" + releases, ...
        color = "blue");

    writeBadgeJson(badgeFile, badge);
end

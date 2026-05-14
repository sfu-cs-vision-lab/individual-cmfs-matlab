function writeBadgeJson(badgeFile, badge)
% WRITEBADGEJSON  Serialize a badge struct to a shields.io endpoint JSON file.
%
%   INPUTS:
%       badgeFile - (1,1) string. Output JSON file path.
%       badge     - (1,1) struct with fields schemaVersion, label, message, color.
%
% SPDX-License-Identifier: AGPL-3.0-or-later
%
% Copyright 2025-2026 Alexander Forsythe and Brian Funt. Simon Fraser University.

arguments
    badgeFile (1,1) string
    badge (1,1) struct
end

    [badgeDir, ~, ~] = fileparts(badgeFile);
    if ~isempty(badgeDir) && ~isfolder(badgeDir)
        mkdir(badgeDir);
    end

    fid = fopen(badgeFile, 'w');
    cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, '%s\n', jsonencode(badge, PrettyPrint = true));
end

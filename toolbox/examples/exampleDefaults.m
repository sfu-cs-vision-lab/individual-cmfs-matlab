function exampleDefaults(action)
% EXAMPLEDEFAULTS  Plotting style shared across the example scripts.
%
%   exampleDefaults() sets MATLAB graphics defaults so every example
%   figure has:
%     - axis ticks pointing outward,
%     - no enclosing axis box (only left/bottom spines visible),
%     - no frame around legends,
%     - grid on by default,
%     - line width of 2 for plotted curves,
%     - padded y limits, so a curve peaking at 1.0 gets headroom above
%       it instead of touching the top of the axes.
%
%   These are groot defaults, so they persist for the MATLAB session and
%   affect every figure you draw afterwards, including ones unrelated to
%   this toolbox. Undo them with:
%
%       exampleDefaults('reset')
%
%   OPTIONAL INPUTS:
%       action - "apply" (default) or "reset" (string)
%
%   EXAMPLE:
%       exampleDefaults();
%       plot(400:700, rand(1, 301));
%       exampleDefaults('reset');
%
%   Copyright 2025-2026 Alexander Forsythe and Brian Funt. Simon Fraser University.

    arguments
        action (1,1) string {mustBeMember(action, ["apply", "reset"])} = "apply"
    end

    % One list, used for both directions. 'remove' restores the factory
    % default, which is what makes the reset exact rather than a guess at
    % what MATLAB started with.
    settings = { ...
        'defaultAxesBox',        'off'; ...
        'defaultAxesTickDir',    'out'; ...
        'defaultAxesXGrid',      'on'; ...
        'defaultAxesYGrid',      'on'; ...
        'defaultAxesYLimitMethod', 'padded'; ...
        'defaultLegendBox',      'off'; ...
        'defaultLegendLocation', 'bestoutside'; ...
        'defaultLineLineWidth',  2};

    if action == "reset"
        for k = 1:size(settings, 1)
            set(groot, settings{k, 1}, 'remove');
        end
        return
    end

    for k = 1:size(settings, 1)
        set(groot, settings{k, 1}, settings{k, 2});
    end

    addpath(fullfile(fileparts(mfilename('fullpath')), 'utils'));
end

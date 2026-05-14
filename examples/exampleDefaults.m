function exampleDefaults()
% EXAMPLEDEFAULTS  Plotting style shared across the example scripts.
%
%   Sets MATLAB graphics defaults so every example figure has:
%     - axis ticks pointing outward,
%     - no enclosing axis box (only left/bottom spines visible),
%     - no frame around legends,
%     - grid on by default,
%     - line width of 2 for plotted curves.
%
%   The settings persist in the MATLAB session. Reset them with
%       set(groot, 'defaultAxesBox',       'remove')
%       set(groot, 'defaultAxesTickDir',   'remove')
%       set(groot, 'defaultAxesXGrid',     'remove')
%       set(groot, 'defaultAxesYGrid',     'remove')
%       set(groot, 'defaultLegendBox',     'remove')
%       set(groot, 'defaultLineLineWidth', 'remove')

set(groot, ...
    'defaultAxesBox',       'off', ...
    'defaultAxesTickDir',   'out', ...
    'defaultAxesXGrid',     'on', ...
    'defaultAxesYGrid',     'on', ...
    'defaultLegendBox',     'off', ...
    'defaultLegendLocation','bestoutside', ...
    'defaultLineLineWidth', 2);

addpath(fullfile(fileparts(mfilename('fullpath')), 'utils'));
end

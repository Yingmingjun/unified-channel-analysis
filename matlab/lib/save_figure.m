function save_figure(fig, out_dir, stem, padding)
% save_figure  Export a MATLAB figure to PNG + PDF at 300 DPI.
%
%   save_figure(fig, out_dir, stem) writes <out_dir>/<stem>.png via
%   exportgraphics (300 DPI, white background) and <out_dir>/<stem>.pdf
%   as a vector file; additionally saves a MATLAB .fig via saveas so the
%   user can re-open and tweak the plot.
%
%   save_figure(..., padding) sets the exportgraphics 'Padding' option:
%     'tight'  (default) - crop surrounding whitespace. Minimizes file
%                          bbox but causes small size drift between
%                          figures whose labels extend different amounts.
%     'figure'           - use the full figure area. Guarantees
%                          PIXEL-IDENTICAL export dimensions for any two
%                          figures that share the same figure 'Position'
%                          (e.g. [100 100 1100 600] across all Fig 3 /
%                          Fig 4 Bland-Altman panels).
%
%   out_dir is created if missing.

% Shared helper for all figXX / tableXX drivers

if nargin < 4 || isempty(padding)
    padding = 'tight';
end

if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

png_path = fullfile(out_dir, [stem '.png']);
pdf_path = fullfile(out_dir, [stem '.pdf']);
fig_path = fullfile(out_dir, [stem '.fig']);

exportgraphics(fig, png_path, 'Resolution', 300, ...
               'BackgroundColor', 'white', 'Padding', padding);
exportgraphics(fig, pdf_path, 'ContentType', 'vector', ...
               'BackgroundColor', 'white', 'Padding', padding);
saveas(fig, fig_path);
end

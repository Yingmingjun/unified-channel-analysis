function save_figure(fig, out_dir, stem, padding)
% save_figure  Export a MATLAB figure to PNG + PDF + EPS at 300 DPI.
%
%   save_figure(fig, out_dir, stem) writes <out_dir>/<stem>.png via
%   exportgraphics (300 DPI, white background), <out_dir>/<stem>.pdf
%   and <out_dir>/<stem>.eps as vector files; additionally saves a
%   MATLAB .fig via saveas so the user can re-open and tweak the plot.
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
eps_path = fullfile(out_dir, [stem '.eps']);
fig_path = fullfile(out_dir, [stem '.fig']);

exportgraphics(fig, png_path, 'Resolution', 300, ...
               'BackgroundColor', 'white', 'Padding', padding);
exportgraphics(fig, pdf_path, 'ContentType', 'vector', ...
               'BackgroundColor', 'white', 'Padding', padding);
% EPS is added for legacy publishing workflows that prefer it over PDF.
% exportgraphics supports .eps via ContentType='vector' from R2020a+;
% fall back to `print -depsc` if that fails.
try
    exportgraphics(fig, eps_path, 'ContentType', 'vector', ...
                   'BackgroundColor', 'white', 'Padding', padding);
catch
    try
        print(fig, eps_path, '-depsc', '-painters');
    catch
        % EPS not critical; .pdf is the canonical vector output
    end
end
saveas(fig, fig_path);
end

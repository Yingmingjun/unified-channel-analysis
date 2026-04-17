function save_figure(fig, out_dir, stem)
% save_figure  Export a MATLAB figure to PNG + PDF at 300 DPI.
%
%   save_figure(fig, out_dir, stem) writes <out_dir>/<stem>.png via
%   exportgraphics (300 DPI, white background) and <out_dir>/<stem>.pdf
%   as a vector file; additionally saves a MATLAB .fig via saveas so the
%   user can re-open and tweak the plot.
%
%   out_dir is created if missing.

% Shared helper for all figXX / tableXX drivers

if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

png_path = fullfile(out_dir, [stem '.png']);
pdf_path = fullfile(out_dir, [stem '.pdf']);
fig_path = fullfile(out_dir, [stem '.fig']);

exportgraphics(fig, png_path, 'Resolution', 300, 'BackgroundColor', 'white');
exportgraphics(fig, pdf_path, 'ContentType', 'vector', 'BackgroundColor', 'white');
saveas(fig, fig_path);
end

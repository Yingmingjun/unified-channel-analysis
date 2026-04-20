function plot_style()
% plot_style  Apply paper-wide default plot styling to the MATLAB root.
%
%   plot_style() sets the Times New Roman 12 pt font on all new axes/legend/
%   text, default line width 2.0, color order to NYU-blue / USC-orange /
%   pooled-gray, grid on with alpha 0.3, and enables vectorized PDF export.
%
%   Call once at the top of a driver (before creating figures). Mirrors
%   python/src/channel_analysis/styles/paper.mplstyle.

% Paper style: Section V figures; matches python mplstyle

% -- Fonts --------------------------------------------------------------------
set(groot, 'defaultAxesFontName',   'Times New Roman');
set(groot, 'defaultAxesFontSize',   12);
set(groot, 'defaultTextFontName',   'Times New Roman');
set(groot, 'defaultTextFontSize',   12);
set(groot, 'defaultLegendFontName', 'Times New Roman');
set(groot, 'defaultLegendFontSize', 10);
set(groot, 'defaultColorbarFontName', 'Times New Roman');

% -- Line widths / marker sizes ----------------------------------------------
set(groot, 'defaultLineLineWidth',  2.0);
set(groot, 'defaultAxesLineWidth',  1.0);
set(groot, 'defaultLineMarkerSize', 6);

% -- Canonical colors (RGB in [0,1]) -----------------------------------------
% Column order: NYU, USC, pooled-gray, followed by default fallbacks.
co = [0.00 0.45 0.74;   % NYU blue
      0.85 0.33 0.10;   % USC orange
      0.20 0.20 0.20;   % pooled gray
      0.47 0.67 0.19;   % reserve
      0.49 0.18 0.56];  % reserve
set(groot, 'defaultAxesColorOrder', co);

% -- Grid styling -------------------------------------------------------------
set(groot, 'defaultAxesXGrid',     'on');
set(groot, 'defaultAxesYGrid',     'on');
set(groot, 'defaultAxesGridAlpha', 0.3);
set(groot, 'defaultAxesGridLineStyle', ':');
set(groot, 'defaultAxesBox',       'on');

% -- Figure export defaults (exportgraphics honors these at 300 DPI) ---------
set(groot, 'defaultFigureColor',   'white');
set(groot, 'defaultFigurePaperPositionMode', 'auto');
set(groot, 'defaultFigureRenderer', 'painters');   % better for PDF
end

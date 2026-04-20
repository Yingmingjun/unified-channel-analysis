function fig03_bland_altman_pl_ds()
% fig03_bland_altman_pl_ds  Bland-Altman for Omni PL and Omni DS (Fig 3).
%
%   Produces FOUR separate figures, each with ONE axis that overlays N3
%   (NYU data, blue circles) and U3 (USC data, orange squares):
%
%       fig03_BA_PL   : sub-THz PL   (27 NYU + 26 USC = 53 dots)
%       fig03_BA_DS   : sub-THz DS   (53 dots)
%       fig03_BA_PL7  : 6.75 GHz PL  (18 NYU + 17 USC = 35 dots)
%       fig03_BA_DS7  : 6.75 GHz DS  (35 dots)
%
%   Diff convention: B - A where A = NYU method (pl_nyu_sum / ds_nyu_sum)
%   and B = USC method (pl_usc_pdm / ds_usc_pdm). Bias>0 means USC
%   reports a higher value than NYU on the same data.
%
%   LAYOUT (self-contained -- no legend):
%     * Bias + +/-1.96 SD lines per side with colored text() labels on
%       the left (N3) / right (U3). Uses text() instead of yline Label
%       so the label color works on MATLAB <R2023a (yline 'LabelColor'
%       only exists in R2023a+).
%     * Corner bias/1.96-SD/n boxes upper-left (blue, N3) and
%       upper-right (orange, U3) replace the legend, so no southeast
%       box is left to overlap the -1.96 SD label.
%     * Larger fonts matched to fig04 so Fig 3 and Fig 4 render at the
%       same visual scale in the paper.
%
%   DATA SOURCE:
%       load_paper_ba_source() returns the paper-parity xlsx snapshot
%       from share/data/point_data/. Its PL/DS bias numbers match the
%       paper exactly (see its docstring). If those numbers drift from
%       the live UCA Results/ .xlsx output, migrate the source to
%       P.results_nyu_142 / P.results_usc_145 / P.results_nyu_7 /
%       P.results_usc_7 as fig04 already does for AS.

% Mirrors python/src/channel_analysis/figures/fig03_bland_altman_pl_ds.py
% Paper Fig 3.

plot_style();
P = paths();
if ~exist(P.out_dir, 'dir'), mkdir(P.out_dir); end

T = load_paper_ba_source();

render_one(T, P, 'fig03_BA_PL',  'Bland-Altman: Omni PL (sub-THz)', ...
           'subTHz', 'pl_nyu_sum', 'pl_usc_pdm', 'dB', 'PL');
render_one(T, P, 'fig03_BA_DS',  'Bland-Altman: Omni DS (sub-THz)', ...
           'subTHz', 'ds_nyu_sum', 'ds_usc_pdm', 'ns', 'DS');
render_one(T, P, 'fig03_BA_PL7', 'Bland-Altman: Omni PL (6.75 GHz)', ...
           'FR1C',   'pl_nyu_sum', 'pl_usc_pdm', 'dB', 'PL');
render_one(T, P, 'fig03_BA_DS7', 'Bland-Altman: Omni DS (6.75 GHz)', ...
           'FR1C',   'ds_nyu_sum', 'ds_usc_pdm', 'ns', 'DS');
end


% ===========================================================================
function render_one(T, P, stem, ttl, band, col_a, col_b, unit, metric_lbl)
% Build one overlaid BA figure (N3 + U3 on a single axis). Same layout
% as fig04 render_one so the two figures read at identical scale.

sub_nyu = T(T.institution == "NYU" & T.band == string(band), :);
sub_usc = T(T.institution == "USC" & T.band == string(band), :);

a_n = sub_nyu.(col_a);  b_n = sub_nyu.(col_b);
a_u = sub_usc.(col_a);  b_u = sub_usc.(col_b);

% Match Plot_BlandAltman_PL_DS_AS.m filter: finite-only.
m_n = isfinite(a_n) & isfinite(b_n);
m_u = isfinite(a_u) & isfinite(b_u);
a_n = a_n(m_n);  b_n = b_n(m_n);
a_u = a_u(m_u);  b_u = b_u(m_u);

% Diff = B - A (USC method - NYU method) per paper convention.
res_n3 = bland_altman(b_n, a_n);
res_u3 = bland_altman(b_u, a_u);

% Print so the user can cross-check against Plot_BlandAltman_PL_DS_AS.m.
fprintf('  %s:\n', stem);
fprintf('    N3 (NYU data): Bias=%+.2f %s, SD=%.2f, n(NYU)=%d\n', ...
        res_n3.bias, unit, res_n3.sd, res_n3.n);
fprintf('    U3 (USC data): Bias=%+.2f %s, SD=%.2f, n(USC)=%d\n', ...
        res_u3.bias, unit, res_u3.sd, res_u3.n);

% --- Colors: NYU blue, USC orange.
c_nyu      = [0.00 0.45 0.74];
c_nyu_face = [0.60 0.78 0.92];
c_usc      = [0.85 0.33 0.10];
c_usc_face = [0.98 0.78 0.68];

fig = figure('Position', [100 100 1200 800], 'Color', 'w');
ax  = axes('Parent', fig);
hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
set(ax, 'FontSize', 26, 'LineWidth', 1.0);

% --- Scatter (with DisplayName so markers show in the legend box).
h_n3 = scatter(ax, res_n3.mean, res_n3.diff, 320, 'o', ...
        'MarkerFaceColor', c_nyu_face, ...
        'MarkerEdgeColor', c_nyu, 'LineWidth', 2.0, ...
        'DisplayName', sprintf('N3: NYU data (n=%d)', res_n3.n));
h_u3 = scatter(ax, res_u3.mean, res_u3.diff, 320, 's', ...
        'MarkerFaceColor', c_usc_face, ...
        'MarkerEdgeColor', c_usc, 'LineWidth', 2.0, ...
        'DisplayName', sprintf('U3: USC data (n=%d)', res_u3.n));

% --- Bias (solid) + +/-1.96 SD (dashed) lines per side.
% Keep yline handles out of the legend (HandleVisibility off) -- the
% legend below only carries the two marker symbols + dataset labels.
yline(ax, res_n3.bias,     '-',  'Color', c_nyu, 'LineWidth', 2.2, 'HandleVisibility', 'off');
yline(ax, res_n3.loa_high, '--', 'Color', c_nyu, 'LineWidth', 1.8, 'HandleVisibility', 'off');
yline(ax, res_n3.loa_low,  '--', 'Color', c_nyu, 'LineWidth', 1.8, 'HandleVisibility', 'off');
yline(ax, res_u3.bias,     '-',  'Color', c_usc, 'LineWidth', 2.2, 'HandleVisibility', 'off');
yline(ax, res_u3.loa_high, '--', 'Color', c_usc, 'LineWidth', 1.8, 'HandleVisibility', 'off');
yline(ax, res_u3.loa_low,  '--', 'Color', c_usc, 'LineWidth', 1.8, 'HandleVisibility', 'off');
yline(ax, 0, ':', 'Color', [0.5 0.5 0.5], 'LineWidth', 0.8, 'HandleVisibility', 'off');

xlabel(ax, sprintf('Mean of paired %s [%s]', metric_lbl, unit), 'FontSize', 30);
ylabel(ax, sprintf('USC - NYU [%s]', unit),                     'FontSize', 30);
title(ax,  ttl, 'FontSize', 32);

% --- Y-axis padding:
%   +40 %% top    : room for the two 3-line stat boxes above the
%                   highest line label (loa_high_norm <= 0.74).
%   +25 %% bottom : clears space for the legend inside the axes (south,
%                   horizontal). The -1.96 SD labels sit ABOVE the
%                   legend (the LoA lines land around y_norm = 0.20
%                   with this padding), so no collision.
drawnow;
yl = ylim(ax);  yspan = max(yl(2) - yl(1), eps);
ylim(ax, [yl(1) - 0.25*yspan, yl(2) + 0.40*yspan]);

% --- Colored in-axes line labels in DATA coords so color works on
% older MATLABs. N3 on the LEFT (ha='left'), U3 on the RIGHT ('right').
xl = xlim(ax);  dx = 0.02 * diff(xl);
xp_l = xl(1) + dx;   xp_r = xl(2) - dx;
fs_lbl = 24;

text(ax, xp_l, res_n3.bias,     'Bias (N3)',     'Color', c_nyu, ...
     'HorizontalAlignment', 'left',  'VerticalAlignment', 'bottom', ...
     'FontSize', fs_lbl, 'FontWeight', 'bold');
text(ax, xp_l, res_n3.loa_high, '+1.96 SD (N3)', 'Color', c_nyu, ...
     'HorizontalAlignment', 'left',  'VerticalAlignment', 'bottom', ...
     'FontSize', fs_lbl, 'FontWeight', 'bold');
text(ax, xp_l, res_n3.loa_low,  '-1.96 SD (N3)', 'Color', c_nyu, ...
     'HorizontalAlignment', 'left',  'VerticalAlignment', 'top', ...
     'FontSize', fs_lbl, 'FontWeight', 'bold');
text(ax, xp_r, res_u3.bias,     'Bias (U3)',     'Color', c_usc, ...
     'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', ...
     'FontSize', fs_lbl, 'FontWeight', 'bold');
text(ax, xp_r, res_u3.loa_high, '+1.96 SD (U3)', 'Color', c_usc, ...
     'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', ...
     'FontSize', fs_lbl, 'FontWeight', 'bold');
text(ax, xp_r, res_u3.loa_low,  '-1.96 SD (U3)', 'Color', c_usc, ...
     'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', ...
     'FontSize', fs_lbl, 'FontWeight', 'bold');

% --- Corner stat boxes. One line per line-in-plot so each notation
% (Bias, +1.96 SD, -1.96 SD) appears as a LABEL-TEXT entry next to
% its numeric value. The +1.96 SD / -1.96 SD values shown are the
% upper/lower limits-of-agreement (bias +/- 1.96*SD), matching the
% yline positions in the plot.
text(ax, 0.02, 0.97, ...
     sprintf(['N3 Bias = %+.2f %s\n' ...
              '+1.96 SD = %+.2f %s\n' ...
              '-1.96 SD = %+.2f %s'], ...
             res_n3.bias,     unit, ...
             res_n3.loa_high, unit, ...
             res_n3.loa_low,  unit), ...
     'Units', 'normalized', 'Color', c_nyu, ...
     'HorizontalAlignment', 'left',  'VerticalAlignment', 'top', ...
     'FontSize', 22, 'FontWeight', 'bold', ...
     'BackgroundColor', 'w', 'EdgeColor', c_nyu, 'Margin', 4);
text(ax, 0.98, 0.97, ...
     sprintf(['U3 Bias = %+.2f %s\n' ...
              '+1.96 SD = %+.2f %s\n' ...
              '-1.96 SD = %+.2f %s'], ...
             res_u3.bias,     unit, ...
             res_u3.loa_high, unit, ...
             res_u3.loa_low,  unit), ...
     'Units', 'normalized', 'Color', c_usc, ...
     'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', ...
     'FontSize', 22, 'FontWeight', 'bold', ...
     'BackgroundColor', 'w', 'EdgeColor', c_usc, 'Margin', 4);

% --- Legend INSIDE the axes, bottom-center, horizontal. ItemTokenSize
% enlarges the marker icon in the legend beyond MATLAB's default so
% the in-legend marker matches the visual weight of the scatter.
leg = legend(ax, [h_n3, h_u3], 'Location', 'south', ...
       'Orientation', 'horizontal', 'FontSize', 24, 'Box', 'on');
leg.ItemTokenSize = [60 36];

save_figure(fig, P.out_dir, stem, 'tight');
close(fig);
end

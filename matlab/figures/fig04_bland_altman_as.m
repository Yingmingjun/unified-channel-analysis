function fig04_bland_altman_as()
% fig04_bland_altman_as  Bland-Altman for Omni ASA and ASD (Fig 4).
%
%   Paper-matching values. Reads the paper's frozen per-location xlsx
%   tables via load_paper_ba_source() (the SAME source fig03 uses) so
%   the bias / SD / n numbers reproduce main_final.tex Fig 4 exactly
%   and are consistent with Fig 3 PL/DS.
%
%   (We previously tried reading the live UCA Results/*.mat directly.
%   Those files have drifted since the paper was produced and no longer
%   yield the paper's bias values, so fig04 now uses the same paper-era
%   snapshot the paper's Plot_BlandAltman_PL_DS_AS.m consumed.)
%
%   Four figures written:
%       fig04_BA_ASA   : sub-THz ASA (27 NYU + 26 USC = 53 dots)
%       fig04_BA_ASD   : sub-THz ASD (53 dots)
%       fig04_BA_ASA7  : 6.75 GHz ASA (18 NYU + 17 USC = 35 dots)
%       fig04_BA_ASD7  : 6.75 GHz ASD (35 dots)
%
%   Diff convention: B - A where A = NYU method (10 dB PAS threshold +
%   lobe expansion, asa_nyu_10 / asd_nyu_10 columns) and B = USC method
%   (no spatial threshold, asa_usc / asd_usc columns). Bias > 0 means
%   USC reports a larger value than NYU on the same data.
%
%   LAYOUT:
%     * N3 blue circles, U3 orange squares.
%     * Bias (solid) + +/-1.96 SD (dashed) lines per side with colored
%       text() labels anchored on the left (N3) / right (U3). Uses
%       text() in data coords so colors survive on MATLAB <R2023a
%       (yline 'LabelColor' is R2023a+).
%     * Corner boxes upper-left (blue, N3) and upper-right (orange, U3)
%       replace the legend. Each box spells out which point-data table
%       the group came from: "N3 (NYU data), n(NYU) = 27" etc., so the
%       attribution of n is unambiguous.

% Mirrors python/src/channel_analysis/figures/fig04_bland_altman_as.py
% Paper Fig 4.

plot_style();
P = paths();
if ~exist(P.out_dir, 'dir'), mkdir(P.out_dir); end

T = load_paper_ba_source();

render_one(T, P, 'fig04_BA_ASA',  'Bland-Altman: Omni ASA (sub-THz)',  ...
           'subTHz', 'asa_nyu_10', 'asa_usc', 'deg', 'ASA');
render_one(T, P, 'fig04_BA_ASD',  'Bland-Altman: Omni ASD (sub-THz)',  ...
           'subTHz', 'asd_nyu_10', 'asd_usc', 'deg', 'ASD');
render_one(T, P, 'fig04_BA_ASA7', 'Bland-Altman: Omni ASA (6.75 GHz)', ...
           'FR1C',   'asa_nyu_10', 'asa_usc', 'deg', 'ASA');
render_one(T, P, 'fig04_BA_ASD7', 'Bland-Altman: Omni ASD (6.75 GHz)', ...
           'FR1C',   'asd_nyu_10', 'asd_usc', 'deg', 'ASD');
end


% ===========================================================================
function render_one(T, P, stem, ttl, band, col_a, col_b, unit, metric_lbl)
% Single overlaid BA figure. Layout matches fig03 render_one so the two
% figures read at identical scale when tiled in the paper.

sub_nyu = T(T.institution == "NYU" & T.band == string(band), :);
sub_usc = T(T.institution == "USC" & T.band == string(band), :);

a_n = sub_nyu.(col_a);  b_n = sub_nyu.(col_b);
a_u = sub_usc.(col_a);  b_u = sub_usc.(col_b);

% BA_AS_Merged.m filter: drop non-finite / non-positive rows.
m_n = isfinite(a_n) & isfinite(b_n) & (a_n > 0) & (b_n > 0);
m_u = isfinite(a_u) & isfinite(b_u) & (a_u > 0) & (b_u > 0);
a_n = a_n(m_n);  b_n = b_n(m_n);
a_u = a_u(m_u);  b_u = b_u(m_u);

% Diff = USC method - NYU method (B - A) per paper convention.
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

% --- Bias (solid) + +/-1.96 SD (dashed) per side -- lines only,
% kept out of the legend (HandleVisibility off).
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

% Y-axis padding: +40 %% top (room for 3-line stat box above all line
% labels) and +25 %% bottom (leaves room for the inside-axes legend at
% 'south', so the horizontal legend strip doesn't cover the -1.96 SD
% labels or the lowest data points).
drawnow;
yl = ylim(ax);  yspan = max(yl(2) - yl(1), eps);
ylim(ax, [yl(1) - 0.25*yspan, yl(2) + 0.40*yspan]);

% --- Colored in-axes line labels in DATA coords. N3 left, U3 right.
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

% --- Corner stat boxes. One line per line-in-plot (Bias, +1.96 SD,
% -1.96 SD) so each notation appears as a label-text entry next to
% its numeric value. +1.96 SD / -1.96 SD values are the upper/lower
% limits-of-agreement (bias +/- 1.96*SD), matching the yline
% positions.
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

% --- Marker legend INSIDE the axes, bottom-center, horizontal.
% ItemTokenSize enlarges the legend's marker icon beyond MATLAB's
% default so the legend marker visually matches the scatter size.
leg = legend(ax, [h_n3, h_u3], 'Location', 'south', ...
       'Orientation', 'horizontal', 'FontSize', 24, 'Box', 'on');
leg.ItemTokenSize = [60 36];

save_figure(fig, P.out_dir, stem, 'tight');
close(fig);
end

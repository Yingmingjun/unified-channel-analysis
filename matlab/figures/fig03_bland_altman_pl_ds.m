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
%   Diff convention: B - A where A = NYU method (pl_nyu_sum / ds_nyu_sum),
%   B = USC method (pl_usc_pdm / ds_usc_pdm). Each side gets its own bias
%   solid line + +/-1.96 SD dashed lines colored to match that side's scatter.

% Mirrors python/src/channel_analysis/figures/fig03_bland_altman_pl_ds.py
% Paper Fig 3; layout taken from BA_AS_Merged.m (Codebase B).

plot_style();
P = paths();
if ~exist(P.out_dir, 'dir'), mkdir(P.out_dir); end

T = load_point_data();

render_one(T, P, 'fig03_BA_PL',  'Bland-Altman: Omni PL (sub-THz)', ...
           'subTHz', 'pl_nyu_sum', 'pl_usc_pdm', 'dB', 'PL');
render_one(T, P, 'fig03_BA_DS',  'Bland-Altman: Omni DS (sub-THz)', ...
           'subTHz', 'ds_nyu_method', 'ds_usc_method', 'ns', 'DS');
render_one(T, P, 'fig03_BA_PL7', 'Bland-Altman: Omni PL (6.75 GHz)', ...
           'FR1C',   'pl_nyu_sum', 'pl_usc_pdm', 'dB', 'PL');
render_one(T, P, 'fig03_BA_DS7', 'Bland-Altman: Omni DS (6.75 GHz)', ...
           'FR1C',   'ds_nyu_method', 'ds_usc_method', 'ns', 'DS');
end


% ===========================================================================
function render_one(T, P, stem, ttl, band, col_a, col_b, unit, metric_lbl)
% Build one overlaid BA figure (N3 + U3 on a single axis).
% Mirrors python fig03_bland_altman_pl_ds._render_one.

sub_nyu = T(T.institution == "NYU" & T.band == string(band), :);
sub_usc = T(T.institution == "USC" & T.band == string(band), :);

a_n = sub_nyu.(col_a);  b_n = sub_nyu.(col_b);
a_u = sub_usc.(col_a);  b_u = sub_usc.(col_b);

% Diff = B - A (USC method - NYU method) per paper convention.
res_n3 = bland_altman(b_n, a_n);
res_u3 = bland_altman(b_u, a_u);

% Colors: NYU blue, USC orange.
c_nyu      = [0.00 0.45 0.74];
c_nyu_face = [0.60 0.78 0.92];
c_usc      = [0.85 0.33 0.10];
c_usc_face = [0.98 0.78 0.68];

% Fonts/markers tuned for \includegraphics[width=0.49\columnwidth] (~1.7 in)
% in IEEE 2-column layout. Figure is 2x2 grid of 4 BA plots per column.
fig = figure('Position', [100 100 1100 600], 'Color', 'w');
hold on; grid on; box on;
set(gca, 'FontSize', 24, 'LineWidth', 1.0);

% Scatter N3 (NYU) blue circles
scatter(res_n3.mean, res_n3.diff, 200, 'o', ...
        'MarkerFaceColor', c_nyu_face, ...
        'MarkerEdgeColor', c_nyu, 'LineWidth', 2.0, ...
        'DisplayName', sprintf('N3: NYU data (n=%d)', res_n3.n));
% Scatter U3 (USC) orange squares
scatter(res_u3.mean, res_u3.diff, 200, 's', ...
        'MarkerFaceColor', c_usc_face, ...
        'MarkerEdgeColor', c_usc, 'LineWidth', 2.0, ...
        'DisplayName', sprintf('U3: USC data (n=%d)', res_u3.n));

% Bias line + +/-1.96 SD dashed lines per side, with inline labels
% (matches BA_AS_Merged.m). N3 labels on the LEFT, U3 labels on the RIGHT
% so the two sides don't collide in the middle of the plot.
yline(res_n3.bias,     '-',  'Bias (N3)', 'Color', c_nyu, 'LineWidth', 2.0, ...
      'HandleVisibility', 'off', 'FontSize', 18, 'FontWeight', 'bold', ...
      'LabelHorizontalAlignment', 'left', 'Interpreter', 'none');
yline(res_n3.loa_high, '--', '+1.96 SD (N3)', 'Color', c_nyu, 'LineWidth', 1.6, ...
      'HandleVisibility', 'off', 'FontSize', 16, ...
      'LabelHorizontalAlignment', 'left', 'Interpreter', 'none');
yline(res_n3.loa_low,  '--', '-1.96 SD (N3)', 'Color', c_nyu, 'LineWidth', 1.6, ...
      'HandleVisibility', 'off', 'FontSize', 16, ...
      'LabelHorizontalAlignment', 'left', 'Interpreter', 'none');
yline(res_u3.bias,     '-',  'Bias (U3)', 'Color', c_usc, 'LineWidth', 2.0, ...
      'HandleVisibility', 'off', 'FontSize', 18, 'FontWeight', 'bold', ...
      'LabelHorizontalAlignment', 'right', 'Interpreter', 'none');
yline(res_u3.loa_high, '--', '+1.96 SD (U3)', 'Color', c_usc, 'LineWidth', 1.6, ...
      'HandleVisibility', 'off', 'FontSize', 16, ...
      'LabelHorizontalAlignment', 'right', 'Interpreter', 'none');
yline(res_u3.loa_low,  '--', '-1.96 SD (U3)', 'Color', c_usc, 'LineWidth', 1.6, ...
      'HandleVisibility', 'off', 'FontSize', 16, ...
      'LabelHorizontalAlignment', 'right', 'Interpreter', 'none');
yline(0, ':', 'Color', [0.5 0.5 0.5], 'LineWidth', 0.8, ...
      'HandleVisibility', 'off');

xlabel(sprintf('Mean of paired %s [%s]', metric_lbl, unit), 'FontSize', 26);
ylabel(sprintf('Difference (USC - NYU) [%s]', unit), 'FontSize', 26);
title(ttl, 'FontSize', 28);
legend('Location', 'southeast', 'FontSize', 22);

% Per-side bias/1.96SD numeric annotation (blue upper-left, orange upper-right).
% The inline yline labels say what each line IS ("Bias / +/-1.96 SD");
% these corner boxes give the NUMERIC values of bias and the 1.96 SD limit.
text(0.02, 0.98, ...
     sprintf('N3 bias = %+.2f %s\n1.96 SD = %.2f', ...
             res_n3.bias, unit, 1.96 * res_n3.sd), ...
     'Units', 'normalized', 'Color', c_nyu, 'HorizontalAlignment', 'left', ...
     'VerticalAlignment', 'top', 'FontSize', 22, 'FontWeight', 'bold', ...
     'BackgroundColor', 'w', 'EdgeColor', c_nyu);
text(0.98, 0.98, ...
     sprintf('U3 bias = %+.2f %s\n1.96 SD = %.2f', ...
             res_u3.bias, unit, 1.96 * res_u3.sd), ...
     'Units', 'normalized', 'Color', c_usc, 'HorizontalAlignment', 'right', ...
     'VerticalAlignment', 'top', 'FontSize', 22, 'FontWeight', 'bold', ...
     'BackgroundColor', 'w', 'EdgeColor', c_usc);

save_figure(fig, P.out_dir, stem);
close(fig);
end

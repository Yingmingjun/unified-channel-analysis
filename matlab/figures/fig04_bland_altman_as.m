function fig04_bland_altman_as()
% fig04_bland_altman_as  Bland-Altman for Omni ASA and ASD (Fig 4).
%
%   Same single-axis-overlay layout as fig03 but for angular spreads.
%   Four output figures:
%       fig04_BA_ASA    : sub-THz ASA
%       fig04_BA_ASD    : sub-THz ASD
%       fig04_BA_ASA7   : 6.75 GHz ASA
%       fig04_BA_ASD7   : 6.75 GHz ASD
%
%   Comparison pair per row: asa_nyu_10 (NYU method, 10 dB PAS threshold) vs
%   asa_usc (USC method, no spatial threshold). Diff = USC method - NYU
%   method. Drops non-positive / non-finite before BA (matches BA_AS_Merged.m
%   filter: isfinite(a) & isfinite(b) & a>0 & b>0).

% Mirrors python/src/channel_analysis/figures/fig04_bland_altman_as.py
% Paper Fig 4; layout from BA_AS_Merged.m (Codebase B).

plot_style();
P = paths();
if ~exist(P.out_dir, 'dir'), mkdir(P.out_dir); end

T = load_point_data();

render_one(T, P, 'fig04_BA_ASA',  'Bland-Altman: Omni ASA (sub-THz)', ...
           'subTHz', 'asa_nyu_10', 'asa_usc',  'deg', 'ASA');
render_one(T, P, 'fig04_BA_ASD',  'Bland-Altman: Omni ASD (sub-THz)', ...
           'subTHz', 'asd_nyu_10', 'asd_usc',  'deg', 'ASD');
render_one(T, P, 'fig04_BA_ASA7', 'Bland-Altman: Omni ASA (6.75 GHz)', ...
           'FR1C',   'asa_nyu_10', 'asa_usc',  'deg', 'ASA');
render_one(T, P, 'fig04_BA_ASD7', 'Bland-Altman: Omni ASD (6.75 GHz)', ...
           'FR1C',   'asd_nyu_10', 'asd_usc',  'deg', 'ASD');
end


% ===========================================================================
function render_one(T, P, stem, ttl, band, col_a, col_b, unit, metric_lbl)
% Single overlaid BA figure for AS (drops non-positive / non-finite).

sub_nyu = T(T.institution == "NYU" & T.band == string(band), :);
sub_usc = T(T.institution == "USC" & T.band == string(band), :);

a_n = sub_nyu.(col_a);  b_n = sub_nyu.(col_b);
a_u = sub_usc.(col_a);  b_u = sub_usc.(col_b);

% Drop non-positive / non-finite per BA_AS_Merged.m filter.
m_n = isfinite(a_n) & isfinite(b_n) & (a_n > 0) & (b_n > 0);
m_u = isfinite(a_u) & isfinite(b_u) & (a_u > 0) & (b_u > 0);
a_n = a_n(m_n); b_n = b_n(m_n);
a_u = a_u(m_u); b_u = b_u(m_u);

% Diff = B - A (USC method - NYU method).
res_n3 = bland_altman(b_n, a_n);
res_u3 = bland_altman(b_u, a_u);

c_nyu      = [0.00 0.45 0.74];
c_nyu_face = [0.60 0.78 0.92];
c_usc      = [0.85 0.33 0.10];
c_usc_face = [0.98 0.78 0.68];

fig = figure('Position', [100 100 1100 600], 'Color', 'w');
hold on; grid on; box on;

scatter(res_n3.mean, res_n3.diff, 120, 'o', ...
        'MarkerFaceColor', c_nyu_face, ...
        'MarkerEdgeColor', c_nyu, 'LineWidth', 1.8, ...
        'DisplayName', sprintf('N3: NYU data (n=%d)', res_n3.n));
scatter(res_u3.mean, res_u3.diff, 120, 's', ...
        'MarkerFaceColor', c_usc_face, ...
        'MarkerEdgeColor', c_usc, 'LineWidth', 1.8, ...
        'DisplayName', sprintf('U3: USC data (n=%d)', res_u3.n));

yline(res_n3.bias,     '-',  'Color', c_nyu, 'LineWidth', 2.0, 'HandleVisibility','off');
yline(res_n3.loa_low,  '--', 'Color', c_nyu, 'LineWidth', 1.6, 'HandleVisibility','off');
yline(res_n3.loa_high, '--', 'Color', c_nyu, 'LineWidth', 1.6, 'HandleVisibility','off');
yline(res_u3.bias,     '-',  'Color', c_usc, 'LineWidth', 2.0, 'HandleVisibility','off');
yline(res_u3.loa_low,  '--', 'Color', c_usc, 'LineWidth', 1.6, 'HandleVisibility','off');
yline(res_u3.loa_high, '--', 'Color', c_usc, 'LineWidth', 1.6, 'HandleVisibility','off');
yline(0, ':', 'Color', [0.5 0.5 0.5], 'LineWidth', 0.8, 'HandleVisibility','off');

xlabel(sprintf('Mean of %s (NYU & USC methods) [%s]', metric_lbl, unit));
ylabel(sprintf('USC method - NYU method [%s]', unit));
title(ttl);
legend('Location', 'southeast', 'FontSize', 10);

text(0.02, 0.98, ...
     sprintf('N3 bias = %+.2f %s\nSD = %.2f', res_n3.bias, unit, res_n3.sd), ...
     'Units', 'normalized', 'Color', c_nyu, 'HorizontalAlignment', 'left', ...
     'VerticalAlignment', 'top', 'FontSize', 11, 'FontWeight', 'bold', ...
     'BackgroundColor', 'w', 'EdgeColor', c_nyu);
text(0.98, 0.98, ...
     sprintf('U3 bias = %+.2f %s\nSD = %.2f', res_u3.bias, unit, res_u3.sd), ...
     'Units', 'normalized', 'Color', c_usc, 'HorizontalAlignment', 'right', ...
     'VerticalAlignment', 'top', 'FontSize', 11, 'FontWeight', 'bold', ...
     'BackgroundColor', 'w', 'EdgeColor', c_usc);

save_figure(fig, P.out_dir, stem);
close(fig);
end

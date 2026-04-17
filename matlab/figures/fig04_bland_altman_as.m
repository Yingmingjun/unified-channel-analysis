function fig04_bland_altman_as()
% fig04_bland_altman_as  Bland-Altman agreement plots for ASA and ASD.
%
%   Same pairing structure as fig03 but for omni angular spreads
%   (azimuth-of-arrival and azimuth-of-departure, in degrees).
%
%   Output files:
%       figures/matlab/fig04_bland_altman_as.png
%       figures/matlab/fig04_bland_altman_as.pdf

% Mirrors python/src/channel_analysis/figures/fig04_bland_altman_as.py
% Paper Section V, Fig. 4

plot_style();
P = paths();

T = load_point_data({'N1', 'U1', 'N3', 'U3'});
T = T(T.band == "subTHz", :);

pair_nyu_asa = pair_by_link(T, 'N1',        'omni_asa_d', 'U3_nyu_thr', 'omni_asa_d');
pair_usc_asa = pair_by_link(T, 'U1',        'omni_asa_d', 'N3_usc_thr', 'omni_asa_d');
pair_nyu_asd = pair_by_link(T, 'N1',        'omni_asd_d', 'U3_nyu_thr', 'omni_asd_d');
pair_usc_asd = pair_by_link(T, 'U1',        'omni_asd_d', 'N3_usc_thr', 'omni_asd_d');

fig = figure('Position', [100 100 900 700]);

subplot(2,2,1);
draw_ba_panel(pair_nyu_asa.a, pair_nyu_asa.b, 'ASA [deg] — NYU side');

subplot(2,2,2);
draw_ba_panel(pair_usc_asa.a, pair_usc_asa.b, 'ASA [deg] — USC side');

subplot(2,2,3);
draw_ba_panel(pair_nyu_asd.a, pair_nyu_asd.b, 'ASD [deg] — NYU side');

subplot(2,2,4);
draw_ba_panel(pair_usc_asd.a, pair_usc_asd.b, 'ASD [deg] — USC side');

sgtitle('Bland-Altman: Omni ASA and ASD (sub-THz)');

save_figure(fig, P.out_dir, 'fig04_bland_altman_as');
close(fig);
end


% ============================================================================
function pr = pair_by_link(T, va, col_a, vb, col_b)
Ta = T(T.variant == string(va), :);
Tb = T(T.variant == string(vb), :);
key_a = Ta.tx + "|" + Ta.rx;
key_b = Tb.tx + "|" + Tb.rx;
[~, ia, ib] = intersect(key_a, key_b, 'stable');
pr.a = Ta.(col_a)(ia);
pr.b = Tb.(col_b)(ib);
end


function draw_ba_panel(a, b, ttl)
S = bland_altman(a, b);
scatter(S.mean, S.diff, 40, [0.85 0.33 0.10], 'filled'); hold on;
yline(S.bias,     '-',  sprintf('bias=%.2f', S.bias), 'LineWidth', 1.5);
yline(S.loa_low,  '--', sprintf('LoA_{lo}=%.2f', S.loa_low),  'LineWidth', 1.0);
yline(S.loa_high, '--', sprintf('LoA_{hi}=%.2f', S.loa_high), 'LineWidth', 1.0);
xlabel('Mean of pair');
ylabel('Difference (a - b)');
title(ttl);
grid on;
end

function fig03_bland_altman_pl_ds()
% fig03_bland_altman_pl_ds  Bland-Altman agreement plots for PL and DS.
%
%   Compares N1 (NYU original) vs U3-NYU-threshold (USC data, NYU pipeline,
%   NYU threshold) and U1 (USC original) vs N3-USC-threshold (NYU data, USC
%   pipeline, USC threshold) for both PL and RMS DS, at 142/145.5 GHz.
%
%   Output files:
%       figures/matlab/fig03_bland_altman_pl_ds.png
%       figures/matlab/fig03_bland_altman_pl_ds.pdf

% Mirrors python/src/channel_analysis/figures/fig03_bland_altman_pl_ds.py
% Paper Section V, Fig. 3

plot_style();
P = paths();

% -- Load all variants needed -------------------------------------------------
T = load_point_data({'N1', 'U1', 'N3', 'U3'});

% Sub-THz band only for this figure.
T = T(T.band == "subTHz", :);

% -- Build paired (a, b) series by (tx, rx) ---------------------------------
% PL, NYU side: N1 vs U3_nyu_thr
pair_nyu_pl = pair_by_link(T, 'N1',        'pl_db', ...
                              'U3_nyu_thr','pl_db');
% PL, USC side: U1 vs N3_usc_thr
pair_usc_pl = pair_by_link(T, 'U1',        'pl_db', ...
                              'N3_usc_thr','pl_db');
% DS, NYU side
pair_nyu_ds = pair_by_link(T, 'N1',        'omni_ds_ns', ...
                              'U3_nyu_thr','omni_ds_ns');
% DS, USC side
pair_usc_ds = pair_by_link(T, 'U1',        'omni_ds_ns', ...
                              'N3_usc_thr','omni_ds_ns');

% -- Figure layout: 2x2 subplots ---------------------------------------------
fig = figure('Position', [100 100 900 700]);

subplot(2,2,1);
draw_ba_panel(pair_nyu_pl.a, pair_nyu_pl.b, 'PL [dB] — NYU side (N1 vs U3_{NYU thr})');

subplot(2,2,2);
draw_ba_panel(pair_usc_pl.a, pair_usc_pl.b, 'PL [dB] — USC side (U1 vs N3_{USC thr})');

subplot(2,2,3);
draw_ba_panel(pair_nyu_ds.a, pair_nyu_ds.b, 'DS [ns] — NYU side');

subplot(2,2,4);
draw_ba_panel(pair_usc_ds.a, pair_usc_ds.b, 'DS [ns] — USC side');

sgtitle('Bland-Altman: PL and RMS DS (sub-THz)');

save_figure(fig, P.out_dir, 'fig03_bland_altman_pl_ds');
close(fig);
end


% ============================================================================
% Local helpers
% ============================================================================
function pr = pair_by_link(T, va, col_a, vb, col_b)
% Pair rows of variant va against variant vb keyed on (tx, rx).
Ta = T(T.variant == string(va), :);
Tb = T(T.variant == string(vb), :);
key_a = Ta.tx + "|" + Ta.rx;
key_b = Tb.tx + "|" + Tb.rx;
[~, ia, ib] = intersect(key_a, key_b, 'stable');
pr.a = Ta.(col_a)(ia);
pr.b = Tb.(col_b)(ib);
end


function draw_ba_panel(a, b, ttl)
% Draw one Bland-Altman panel: mean on x, difference on y, bias + LoA lines.
S = bland_altman(a, b);
scatter(S.mean, S.diff, 40, [0 0.45 0.74], 'filled'); hold on;
yline(S.bias,     '-',  sprintf('bias=%.2f', S.bias), 'LineWidth', 1.5);
yline(S.loa_low,  '--', sprintf('LoA_{lo}=%.2f', S.loa_low),  'LineWidth', 1.0);
yline(S.loa_high, '--', sprintf('LoA_{hi}=%.2f', S.loa_high), 'LineWidth', 1.0);
xlabel('Mean of pair');
ylabel('Difference (a - b)');
title(ttl);
grid on;
end

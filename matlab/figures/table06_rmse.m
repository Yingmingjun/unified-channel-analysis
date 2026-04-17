function table06_rmse()
% table06_rmse  RMSE between paired native and cross-processed estimates.
%
%   For each metric (PL, DS, ASA, ASD) and each institution side
%   (NYU: N1 vs U3_nyu_thr; USC: U1 vs N3_usc_thr), computes RMSE = sqrt(mean((a-b).^2))
%   on the pairwise-aligned (tx, rx) links.
%
%   Output:
%       figures/matlab/table06_rmse.csv

% Mirrors python/src/channel_analysis/figures/table06_rmse.py
% Paper Section V, Table VI

plot_style();  % harmless if no figure is made, keeps style centralized
P = paths();

T = load_point_data({'N1','U1','N3','U3'});
T = T(T.band == "subTHz", :);   % Table VI is subTHz-only in the paper

metrics = {'pl_db', 'omni_ds_ns', 'omni_asa_d', 'omni_asd_d'};
metric_labels = {'PL [dB]', 'DS [ns]', 'ASA [deg]', 'ASD [deg]'};

sides = struct('NYU', struct('a', 'N1', 'b', 'U3_nyu_thr'), ...
               'USC', struct('a', 'U1', 'b', 'N3_usc_thr'));

rows = {};
for im = 1:numel(metrics)
    col = metrics{im};
    for side_name = ["NYU", "USC"]
        sd = sides.(char(side_name));
        pr = pair_by_link(T, sd.a, col, sd.b, col);
        d  = pr.a - pr.b;
        d  = d(isfinite(d));
        rmse = sqrt(mean(d .^ 2));
        rows(end+1, :) = {metric_labels{im}, char(side_name), ...
                          sd.a, sd.b, numel(d), rmse}; %#ok<AGROW>
    end
end

out = cell2table(rows, ...
    'VariableNames', {'metric','side','variant_a','variant_b','n','rmse'});

csv_path = fullfile(P.out_dir, 'table06_rmse.csv');
if ~exist(P.out_dir, 'dir'), mkdir(P.out_dir); end
writetable(out, csv_path);
fprintf('[table06] wrote %s\n', csv_path);
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

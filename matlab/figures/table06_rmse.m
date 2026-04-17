function table06_rmse()
% table06_rmse  Cross-processing RMSE of PL / DS / ASA / ASD (paper Table VI).
%
%   Paper Table VI compares each institution's native result (N1 for NYU,
%   U1 for USC) against the partner's re-processed estimate under each of
%   the two delay-domain thresholds. Four columns per metric per band:
%
%     USC data (U3 table) under NYU thres       :  RMSE(U3_nyu_thr, U1)
%     USC data (U3 table) under USC thres       :  RMSE(U3_usc_thr, U1)
%     NYU data (N3 table) under USC thres       :  RMSE(N3_usc_thr, N1)
%     NYU data (N3 table) under NYU thres       :  RMSE(N3_nyu_thr, N1)
%
%   Both sub-THz and 6.75 GHz are reported. A single source-data typo in
%   142_UMi_N3.xlsx (TX4-RX37 ASA = 714 where 7.14 was intended) is filtered
%   out by a 50x-median-difference guard, matching the Python driver.
%
%   Output: figures/matlab/table06_rmse.csv
%
% Mirrors python/src/channel_analysis/figures/table06_rmse.py

plot_style();
P = paths();

T = load_point_data({'N1','U1','N3','U3'});

metrics       = {'pl_db', 'omni_ds_ns', 'omni_asa_d', 'omni_asd_d'};
metric_labels = {'PL [dB]', 'DS [ns]', 'ASA [deg]', 'ASD [deg]'};

% Four same-dataset comparison pairs:
comparisons = { ...
    'USC data - NYU thres',  'USC', 'U1', 'U3_nyu_thr'; ...
    'USC data - USC thres',  'USC', 'U1', 'U3_usc_thr'; ...
    'NYU data - USC thres',  'NYU', 'N1', 'N3_usc_thr'; ...
    'NYU data - NYU thres',  'NYU', 'N1', 'N3_nyu_thr'  ...
};

bands = ["subTHz", "FR1C"];
rows  = {};

for ib = 1:numel(bands)
    band = bands(ib);
    Tb = T(T.band == band, :);
    for im = 1:numel(metrics)
        col = metrics{im};
        row = {char(band), metric_labels{im}};
        for ic = 1:size(comparisons, 1)
            inst = comparisons{ic, 2};
            va   = comparisons{ic, 3};
            vb   = comparisons{ic, 4};
            pr   = pair_by_link(Tb, inst, va, vb, col);
            rmse = robust_rmse(pr.a, pr.b);
            row{end+1} = rmse;                                      %#ok<AGROW>
        end
        rows(end+1, :) = row;                                       %#ok<AGROW>
    end
end

var_names = {'band','metric','USC_data_NYU_thres','USC_data_USC_thres', ...
             'NYU_data_USC_thres','NYU_data_NYU_thres'};
out = cell2table(rows, 'VariableNames', var_names);

csv_path = fullfile(P.out_dir, 'table06_rmse.csv');
if ~exist(P.out_dir, 'dir'), mkdir(P.out_dir); end
writetable(out, csv_path);
fprintf('[table06] wrote %s\n', csv_path);
end


% ============================================================================
function pr = pair_by_link(T, inst, va, vb, col)
% Intersect TX-RX keys within a single institution and pull aligned values
% from two variants.
Ta = T((T.variant == string(va)) & (T.institution == string(inst)), :);
Tb = T((T.variant == string(vb)) & (T.institution == string(inst)), :);
key_a = Ta.tx + "|" + Ta.rx;
key_b = Tb.tx + "|" + Tb.rx;
[~, ia, ib] = intersect(key_a, key_b, 'stable');
pr.a = Ta.(col)(ia);
pr.b = Tb.(col)(ib);
end


function rmse = robust_rmse(a, b)
% RMSE with a 50x-median-of-abs-diff guard against source-data typos.
% (See docs/issues_log.md: 142_UMi_N3.xlsx TX4-RX37 ASA "NYU thres" = 714.0,
% where 7.14 was intended.)
d = a - b;
mask = isfinite(d);
if ~any(mask)
    rmse = NaN; return
end
med = median(abs(d(mask)));
clip = max(med * 50.0, 100.0);
keep = mask & (abs(d) < clip);
rmse = sqrt(mean(d(keep) .^ 2));
end

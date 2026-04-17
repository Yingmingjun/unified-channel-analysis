function table_dumps()
% table_dumps  Regenerate paper Tables 4, 8, 9, 10, 11 as CSV dumps.
%
%   These paper tables are pretty-prints of the institutional point-data
%   xlsx. We dump each as a CSV so readers can diff against the paper.
%
%     Table 4  : partial N1 @ 142 GHz
%     Table 8  : partial U3 @ 145.5 GHz (USC-thr, NYU-thr, USC-orig columns)
%     Table 9  : partial U3 @ 6.75 GHz
%     Table 10 : partial N3 @ 142 GHz (USC-thr, NYU-thr, NYU-orig columns)
%     Table 11 : partial N3 @ 6.75 GHz
%
%   Output: figures/matlab/table{04,08,09,10,11}_*.csv
%
% Mirrors python/src/channel_analysis/figures/table_dumps.py

P = paths();
if ~exist(P.out_dir, 'dir'), mkdir(P.out_dir); end

% -- Table 4 — N1 @ 142 GHz ---------------------------------------------------
df_n1 = load_point_data({'N1'});
t4    = df_n1((df_n1.variant == "N1") & (df_n1.freq_ghz == 142.0), :);
t4    = sortrows(t4, {'tx','rx'});
t4    = t4(:, {'tx','rx','loc_type','d_m','pl_db', ...
               'omni_ds_ns','omni_asa_d','omni_asd_d'});
writetable(t4, fullfile(P.out_dir, 'table04_N1_142.csv'));
fprintf('[table04] wrote table04_N1_142.csv\n');

% -- Tables 8 & 9 — U3 cross-processed ---------------------------------------
df_u3 = load_point_data({'U1','U3'});
write_wide_table(df_u3, 145.5, {'U3_nyu_thr','U3_usc_thr','U1'}, ...
                 fullfile(P.out_dir, 'table08_U3_145.csv'), '[table08]');
write_wide_table(df_u3, 6.75,  {'U3_nyu_thr','U3_usc_thr','U1'}, ...
                 fullfile(P.out_dir, 'table09_U3_7.csv'),  '[table09]');

% -- Tables 10 & 11 — N3 cross-processed -------------------------------------
df_n3 = load_point_data({'N1','N3'});
write_wide_table(df_n3, 142.0, {'N3_usc_thr','N3_nyu_thr','N1'}, ...
                 fullfile(P.out_dir, 'table10_N3_142.csv'), '[table10]');
write_wide_table(df_n3, 6.75,  {'N3_usc_thr','N3_nyu_thr','N1'}, ...
                 fullfile(P.out_dir, 'table11_N3_7.csv'),  '[table11]');
end


% ============================================================================
function write_wide_table(df, freq_ghz, variants, csv_path, tag)
% Pivot one-row-per-(TX,RX,variant) long table into wide with one row per
% (TX,RX) carrying all metric columns for each variant.
sub = df(df.freq_ghz == freq_ghz, :);
metrics = {'pl_db','omni_ds_ns','omni_asa_d','omni_asd_d'};

% Base: sorted unique (tx, rx, loc_type, d_m) from the first variant
base_mask = sub.variant == string(variants{1});
base = sub(base_mask, {'tx','rx','loc_type','d_m'});
[~, idx] = unique(base(:, {'tx','rx'}), 'rows', 'stable');
base = base(idx, :);
out = base;

for iv = 1:numel(variants)
    v = string(variants{iv});
    vsub = sub(sub.variant == v, :);
    [~, i2] = unique(vsub(:, {'tx','rx'}), 'rows', 'stable');
    vsub = vsub(i2, :);
    keys = out.tx + "|" + out.rx;
    vkeys = vsub.tx + "|" + vsub.rx;
    [~, out_idx, vsub_idx] = intersect(keys, vkeys, 'stable');
    for im = 1:numel(metrics)
        m = metrics{im};
        new_col = nan(height(out), 1);
        new_col(out_idx) = vsub.(m)(vsub_idx);
        col_name = sprintf('%s__%s', m, char(v));
        out.(col_name) = new_col;
    end
end

writetable(out, csv_path);
fprintf('%s wrote %s\n', tag, csv_path);
end

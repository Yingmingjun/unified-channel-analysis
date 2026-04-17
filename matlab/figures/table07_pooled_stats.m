function table07_pooled_stats()
% table07_pooled_stats  Pooled lognormal stats with bootstrap CFIs.
%
%   For each (band, loc_type, variant-group, metric) cell, computes the
%   lognormal-mean estimator from lognormal_stats.m and the 95% bootstrap
%   CFI on that estimator, then writes the results as a CSV.
%
%   Groups reported:
%     - NYU  = {N1}
%     - USC  = {U1}
%     - N3nt = {N3_nyu_thr}, N3ut = {N3_usc_thr}
%     - U3nt = {U3_nyu_thr}, U3ut = {U3_usc_thr}
%     - Pooled = N1 + U1 (paper uses this for the headline numbers)
%
%   Output:
%       figures/matlab/table07_pooled_stats.csv

% Mirrors python/src/channel_analysis/figures/table07_pooled_stats.py
% Paper Section V.B / V.C, Table VII; lognormal mean from Eq. 11

plot_style();
P = paths();

T = load_point_data({'N1','U1','N3','U3'});

% Use a 2-column cell array for robust dispatch (avoids the subtle
% struct() + nested-cell shape gotcha).
group_defs = { ...
    'NYU',    {'N1'};                 ...
    'USC',    {'U1'};                 ...
    'N3nt',   {'N3_nyu_thr'};         ...
    'N3ut',   {'N3_usc_thr'};         ...
    'U3nt',   {'U3_nyu_thr'};         ...
    'U3ut',   {'U3_usc_thr'};         ...
    'Pooled', {'N1', 'U1'}            ...
};
group_names  = group_defs(:, 1);
group_lists  = group_defs(:, 2);

metrics = {'omni_ds_ns', 'omni_asa_d', 'omni_asd_d'};
metric_labels = {'DS_ns', 'ASA_deg', 'ASD_deg'};

bands = ["subTHz", "FR1C"];
locs  = ["LOS", "NLOS"];

rows = {};
for ig = 1:numel(group_names)
    gname        = group_names{ig};
    variant_list = group_lists{ig};
    mask_var     = ismember(T.variant, string(variant_list));
    for ib = 1:numel(bands)
        for il = 1:numel(locs)
            mask = mask_var & (T.band == bands(ib)) & (T.loc_type == locs(il));
            Tsub = T(mask, :);
            for im = 1:numel(metrics)
                x = Tsub.(metrics{im});
                S = lognormal_stats(x, 2000, 0);
                rows(end+1, :) = { ...
                    gname, char(bands(ib)), char(locs(il)), metric_labels{im}, ...
                    S.n, S.mu_log10, S.sigma_log10, S.mean_arith, ...
                    S.mean_lognormal, S.cfi_lo, S.cfi_hi, S.cfi_width}; %#ok<AGROW>
            end
        end
    end
end

out = cell2table(rows, ...
    'VariableNames', {'group','band','loc_type','metric','n', ...
                      'mu_log10','sigma_log10','mean_arith', ...
                      'mean_lognormal','cfi_lo','cfi_hi','cfi_width'});

csv_path = fullfile(P.out_dir, 'table07_pooled_stats.csv');
if ~exist(P.out_dir, 'dir'), mkdir(P.out_dir); end
writetable(out, csv_path);
fprintf('[table07] wrote %s\n', csv_path);
end

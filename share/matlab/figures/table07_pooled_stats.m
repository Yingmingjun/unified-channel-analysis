function table07_pooled_stats()
% table07_pooled_stats  Pooled statistical summary (paper Table VII).
%
%   For each (band, dataset, loc_type) subset:
%     * CI path-loss fit -> PLE, sigma_SF (dB), 95 % PLE CFI width (bootstrap)
%     * Lognormal-expectation mean and 95 % CFI width for DS, ASA, ASD.
%
%   Dataset rows (match paper Table VII):
%       NYU only  -> NYU institution (NYU-method columns)
%       USC only  -> USC institution (USC-method columns)
%       Pooled    -> NYU + USC, institution-native method per row
%
%   Columns sourced from the main hybrid loader:
%       pl_db        -> thresholded xlsx value (fallback to per-method CSV)
%       omni_ds_ns   -> thresholded xlsx value (fallback to per-method CSV)
%       asa_nyu_10 / asa_usc   -> per institution
%       asd_nyu_10 / asd_usc   -> per institution
%
%   Output: figures/matlab/table07_pooled_stats.csv
%
% Mirrors python/src/channel_analysis/figures/table07_pooled_stats.py

plot_style();
P = paths();
if ~exist(P.out_dir, 'dir'), mkdir(P.out_dir); end

df = load_point_data();

% (band_tag, band_label, pooled_freq_ghz)
bands = { 'subTHz', 'Sub-THz (142/145.5)', 143.75; ...
          'FR1C',   '6.75 GHz',              6.75 };
% (dataset_name, institution_mask)
datasets = { 'NYU only', ["NYU"]; ...
             'USC only', ["USC"]; ...
             'Pooled',   ["NYU","USC"] };
locs = ["LOS", "NLOS"];

rows = {};
for ib = 1:size(bands, 1)
    band_tag    = bands{ib, 1};
    band_label  = bands{ib, 2};
    pooled_freq = bands{ib, 3};
    for id = 1:size(datasets, 1)
        ds_name = datasets{id, 1};
        insts   = datasets{id, 2};
        for il = 1:numel(locs)
            loc = locs(il);
            mask = (df.band == string(band_tag)) ...
                 & (df.loc_type == loc) ...
                 & ismember(df.institution, insts);
            sub = df(mask, :);
            if height(sub) == 0, continue, end

            % Freq for CI-fit intercept: pooled uses pooled_freq, per-
            % institution uses that institution's frequency (matches python
            % table07_pooled_stats.py freq selector).
            if strcmp(ds_name, 'Pooled')
                freq = pooled_freq;
            elseif isequal(insts, "NYU")
                if string(band_tag) == "subTHz", freq = 142.0; else, freq = 6.75; end
            else
                if string(band_tag) == "subTHz", freq = 145.5; else, freq = 6.75; end
            end

            S = stats_for(sub, freq);
            rows(end+1, :) = { ...
                band_label, ds_name, char(loc), S.n, ...
                S.ple, S.sigma_sf, S.ple_cfi_w, S.ple_cfi_hw, ...
                S.ds_mean,  S.ds_cfi_w,  S.ds_cfi_hw, ...
                S.asa_mean, S.asa_cfi_w, S.asa_cfi_hw, ...
                S.asd_mean, S.asd_cfi_w, S.asd_cfi_hw }; %#ok<AGROW>
        end
    end
end

% Column naming: `*_CFI_width_*`      = full 95 % CI width (hi - lo).
%                `*_CFI_halfwidth_*`  = half width; matches paper Table VII
%                                       convention for the AS columns where
%                                       paper/pipeline ratio is ~0.5.
tbl = cell2table(rows, 'VariableNames', ...
    {'Band','Dataset','LocType','n', ...
     'PLE','sigma_SF_dB','PLE_CFI_width','PLE_CFI_halfwidth', ...
     'DS_mean_ns','DS_CFI_width_ns','DS_CFI_halfwidth_ns', ...
     'ASA_mean_d','ASA_CFI_width_d','ASA_CFI_halfwidth_d', ...
     'ASD_mean_d','ASD_CFI_width_d','ASD_CFI_halfwidth_d'});
csv_path = fullfile(P.out_dir, 'table07_pooled_stats.csv');
writetable(tbl, csv_path);
fprintf('[table07] wrote %s\n', csv_path);
end


% ===========================================================================
function S = stats_for(sub, freq_ghz)
% Per-subset stats: CI fit + lognormal DS/ASA/ASD.
% Mirrors python/src/channel_analysis/figures/table07_pooled_stats.py _stats_for.

% PL: use pl_db (thresholded xlsx value, fallback to per-method CSV).
pl  = sub.pl_db;
[ple, sigma_sf, lo, hi, w, hw] = ci_pl_fit(sub.d_m, pl, freq_ghz, 2000, 0); %#ok<ASGLU>

% DS: use omni_ds_ns.
ds  = lognormal_stats(sub.omni_ds_ns, 2000, 0);

% AS: pick institution-native column for each row (NYU -> _nyu_10, USC -> _usc).
asa_vals = nan(height(sub), 1);
asa_vals(sub.institution == "NYU") = sub.asa_nyu_10(sub.institution == "NYU");
asa_vals(sub.institution == "USC") = sub.asa_usc(sub.institution == "USC");
asd_vals = nan(height(sub), 1);
asd_vals(sub.institution == "NYU") = sub.asd_nyu_10(sub.institution == "NYU");
asd_vals(sub.institution == "USC") = sub.asd_usc(sub.institution == "USC");
asa = lognormal_stats(asa_vals, 2000, 0);
asd = lognormal_stats(asd_vals, 2000, 0);

S.n           = height(sub);
S.ple         = ple;
S.sigma_sf    = sigma_sf;
S.ple_cfi_w   = w;
S.ple_cfi_hw  = hw;
S.ds_mean     = ds.mean_lognormal;
S.ds_cfi_w    = ds.cfi_width;
S.ds_cfi_hw   = ds.cfi_half_width;
S.asa_mean    = asa.mean_lognormal;
S.asa_cfi_w   = asa.cfi_width;
S.asa_cfi_hw  = asa.cfi_half_width;
S.asd_mean    = asd.mean_lognormal;
S.asd_cfi_w   = asd.cfi_width;
S.asd_cfi_hw  = asd.cfi_half_width;
end

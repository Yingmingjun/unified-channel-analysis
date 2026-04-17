function table07_pooled_stats()
% table07_pooled_stats  Pooled stats with CI-PL fit and lognormal DS/AS.
%
%   Regenerates paper Table VII:
%     * CI path-loss fit on each (band, loc_type, dataset) subset:
%         PLE, sigma_SF (dB), 95% bootstrap CFI on PLE.
%     * Lognormal-expectation mean and 95% bootstrap CFI for DS, ASA, ASD.
%
%   Groups reported (matching the paper rows):
%     - NYU only  : variant N1
%     - USC only  : variant U1
%     - Pooled    : variants {N1, U1}
%   (Additional internal groups N3_*, U3_* also dumped for diagnostics.)
%
%   Output: figures/matlab/table07_pooled_stats.csv
%
% Mirrors python/src/channel_analysis/figures/table07_pooled_stats.py

plot_style();
P = paths();

T = load_point_data({'N1','U1','N3','U3'});

% --- Group definitions ------------------------------------------------------
group_defs = { ...
    'NYU only', {'N1'};          ...
    'USC only', {'U1'};          ...
    'Pooled',   {'N1', 'U1'};    ...
    'N3_nt',    {'N3_nyu_thr'};  ...
    'N3_ut',    {'N3_usc_thr'};  ...
    'U3_nt',    {'U3_nyu_thr'};  ...
    'U3_ut',    {'U3_usc_thr'}   ...
};
group_names = group_defs(:, 1);
group_lists = group_defs(:, 2);

bands = ["subTHz", "FR1C"];
locs  = ["LOS", "NLOS"];

% Frequency used for CI-fit intercept (FSPL at 1 m) --------------------------
% Per-group frequencies: NYU uses 142 GHz in sub-THz, USC uses 145.5 GHz in
% sub-THz; for the pooled fit we use 143.75 GHz (paper convention). Both
% institutions share 6.75 GHz at FR1C.
function f = freq_for(group_name, band)
    if band == "subTHz"
        switch group_name
            case {'NYU only','N3_nt','N3_ut'}; f = 142.0;
            case {'USC only','U3_nt','U3_ut'}; f = 145.5;
            otherwise;                         f = 143.75;
        end
    else
        f = 6.75;
    end
end

rows = {};
for ig = 1:numel(group_names)
    gname        = group_names{ig};
    variant_list = group_lists{ig};
    mask_var     = ismember(T.variant, string(variant_list));
    for ib = 1:numel(bands)
        band = bands(ib);
        for il = 1:numel(locs)
            loc  = locs(il);
            mask = mask_var & (T.band == band) & (T.loc_type == loc);
            Tsub = T(mask, :);

            fghz = freq_for(gname, band);
            [ple, sigma_sf, plo, phi, pw] = ci_pl_fit( ...
                Tsub.d_m, Tsub.pl_db, fghz, 2000, 0);

            ds  = lognormal_stats(Tsub.omni_ds_ns,  2000, 0);
            asa = lognormal_stats(Tsub.omni_asa_d,  2000, 0);
            asd = lognormal_stats(Tsub.omni_asd_d,  2000, 0);

            rows(end+1, :) = { ...
                gname, char(band), char(loc), height(Tsub), ...
                ple, sigma_sf, pw, ...
                ds.mean_lognormal,  ds.cfi_width, ...
                asa.mean_lognormal, asa.cfi_width, ...
                asd.mean_lognormal, asd.cfi_width}; %#ok<AGROW>
        end
    end
end

out = cell2table(rows, ...
    'VariableNames', {'group','band','loc_type','n', ...
                      'PLE','sigma_SF_dB','PLE_CFI_width', ...
                      'DS_mean_ns','DS_CFI_width_ns', ...
                      'ASA_mean_d','ASA_CFI_width_d', ...
                      'ASD_mean_d','ASD_CFI_width_d'});

csv_path = fullfile(P.out_dir, 'table07_pooled_stats.csv');
if ~exist(P.out_dir, 'dir'), mkdir(P.out_dir); end
writetable(out, csv_path);
fprintf('[table07] wrote %s\n', csv_path);
end

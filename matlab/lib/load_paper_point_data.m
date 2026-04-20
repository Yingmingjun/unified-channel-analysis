function T = load_paper_point_data()
% load_paper_point_data  Paper-canonical per-location table for CDF / CI figs.
%
%   T = load_paper_point_data() returns a long-format MATLAB table with
%   one row per (institution, band, TX-RX link) built from the SAME
%   Results/*.mat files that the paper's CDF / CI producers consume:
%
%       paper_figures/DS_CDF_Merged.m       -> omni_ds_ns
%       paper_figures/AS_CDF_Merged.m       -> asa_*, asd_*
%       paper_figures/cdf_ci_pl_analysis*.m -> pl_db, d_m (via N3/U3 xlsx)
%
%   Using the Results/*.mat directly avoids the drift between the
%   bundled N3/U3 xlsx snapshot and the live method-comparison tables
%   (load_point_data.m docstring notes the two xlsx families do not
%   agree numerically).
%
%   Schema:
%       institution, band, freq_ghz, tx_rx_id, d_m,
%       loc_type, loc_type_raw,
%       pl_db, omni_ds_ns,
%       asa_nyu_10, asa_nyu_15, asa_nyu_20, asa_usc,
%       asd_nyu_10, asd_nyu_15, asd_nyu_20, asd_usc
%
%   Per-institution, per-band column choice (mirrors paper_figures/*.m):
%
%       band   inst  pl_db          omni_ds_ns      asa*           asd*
%       ---    ---   ------         ---------       ---            ---
%       subTHz NYU   PL_NYU         DS_NYU          ASA_NYU_10dB   ASD_NYU_10dB
%       subTHz USC   PL_USC         DS_USC          ASA_USC        ASD_USC
%       FR1C   NYU   PL_NYUthr_SUM  DS_NYUthr_SUM   ASA_NYUthr_N10 ASD_NYUthr_N10
%       FR1C   USC   PL_USC         DS_USC          ASA_USC        ASD_USC
%
%   For the AS sensitivity sweep (15 dB / 20 dB) we keep the matching
%   10/15/20 dB columns where they exist in the .mat (sub-THz), and fall
%   back to the 10 dB value at 6.75 GHz where only _N10 is published.
%
%   OLOS -> NLOS mapping is applied to loc_type; loc_type_raw preserves
%   the source label.

P = paths();

% ---- Resolve Results/*.mat paths ----------------------------------------
% paths.m anchors repo_root to <share>/; the Results live at
% <share>/matlab/processing/*/Results/ (bundled copy) or at
% <uca_root>/matlab/processing/*/Results/ when <share> is a sub-tree.
uca_root = fileparts(P.repo_root);
nyu142_path = resolve_result(P.results_nyu_142, uca_root, 'nyu_142', 'all_comparison_results.mat');
usc145_path = resolve_result(P.results_usc_145, uca_root, 'usc_145', 'USC145GHz_Full_Results.mat');
nyu7_path   = resolve_result(P.results_nyu_7,   uca_root, 'nyu_7',   'all_comparison_results.mat');
usc7_path   = resolve_result(P.results_usc_7,   uca_root, 'usc_7',   'USC7GHz_Full_Results.mat');

nyu142 = load(nyu142_path);  usc145 = load(usc145_path);
nyu7   = load(nyu7_path);    usc7   = load(usc7_path);

% ---- Build per-band, per-institution frames -----------------------------
frames = {};
frames{end+1} = build_nyu_subthz(nyu142.results); %#ok<*AGROW>
frames{end+1} = build_usc_subthz(usc145.results);
frames{end+1} = build_nyu_fr1c  (nyu7.results);
frames{end+1} = build_usc_fr1c  (usc7.results);
T = vertcat(frames{:});

% ---- OLOS -> NLOS -------------------------------------------------------
T.loc_type = T.loc_type_raw;
T.loc_type(T.loc_type_raw == "OLOS") = "NLOS";
end


% ===========================================================================
function T = build_nyu_subthz(r)
% Fields in the raw .mat struct have mixed [n,1] / [1,n] orientation;
% force every scalar field to a column via col().
n = numel(r.Environment);
T = table();
T.institution  = repmat("NYU",    n, 1);
T.band         = repmat("subTHz", n, 1);
T.freq_ghz     = repmat(142.0,    n, 1);
T.tx_rx_id     = col(string(r.TX_RX_ID));
T.d_m          = col(double(r.Distance_m));
T.loc_type_raw = col(upper(strtrim(string(r.Environment))));
T.pl_db        = col(double(r.PL_NYU));
T.omni_ds_ns   = col(double(r.DS_NYU));
T.asa_nyu_10   = col(double(r.ASA_NYU_10dB));
T.asa_nyu_15   = pick_field(r, 'ASA_NYU_15dB', T.asa_nyu_10);
T.asa_nyu_20   = pick_field(r, 'ASA_NYU_20dB', T.asa_nyu_10);
T.asa_usc      = col(double(r.ASA_USC));
T.asd_nyu_10   = col(double(r.ASD_NYU_10dB));
T.asd_nyu_15   = pick_field(r, 'ASD_NYU_15dB', T.asd_nyu_10);
T.asd_nyu_20   = pick_field(r, 'ASD_NYU_20dB', T.asd_nyu_10);
T.asd_usc      = col(double(r.ASD_USC));
end


function T = build_usc_subthz(r)
n = numel(r.Environment);
T = table();
T.institution  = repmat("USC",    n, 1);
T.band         = repmat("subTHz", n, 1);
T.freq_ghz     = repmat(145.5,    n, 1);
T.tx_rx_id     = col(string(r.Location_ID));
T.d_m          = col(double(r.Distance_m));
T.loc_type_raw = col(upper(strtrim(string(r.Environment))));
T.pl_db        = col(double(r.PL_USC));
T.omni_ds_ns   = col(double(r.DS_USC));
T.asa_nyu_10   = col(double(r.ASA_NYU_10dB));
T.asa_nyu_15   = pick_field(r, 'ASA_NYU_15dB', T.asa_nyu_10);
T.asa_nyu_20   = pick_field(r, 'ASA_NYU_20dB', T.asa_nyu_10);
T.asa_usc      = col(double(r.ASA_USC));
T.asd_nyu_10   = col(double(r.ASD_NYU_10dB));
T.asd_nyu_15   = pick_field(r, 'ASD_NYU_15dB', T.asd_nyu_10);
T.asd_nyu_20   = pick_field(r, 'ASD_NYU_20dB', T.asd_nyu_10);
T.asd_usc      = col(double(r.ASD_USC));
end


function T = build_nyu_fr1c(r)
% NYU 6.75 GHz: paper uses NYU threshold on NYU data -> NYUthr_* columns.
n = numel(r.Environment);
T = table();
T.institution  = repmat("NYU",   n, 1);
T.band         = repmat("FR1C",  n, 1);
T.freq_ghz     = repmat(6.75,    n, 1);
T.tx_rx_id     = col(string(r.TX_RX_ID));
T.d_m          = col(double(r.Distance_m));
T.loc_type_raw = col(upper(strtrim(string(r.Environment))));
T.pl_db        = col(double(r.PL_NYUthr_SUM));
T.omni_ds_ns   = col(double(r.DS_NYUthr_SUM));
T.asa_nyu_10   = col(double(r.ASA_NYUthr_N10));
T.asa_nyu_15   = pick_field(r, 'ASA_NYUthr_N15', T.asa_nyu_10);
T.asa_nyu_20   = pick_field(r, 'ASA_NYUthr_N20', T.asa_nyu_10);
T.asa_usc      = col(double(r.ASA_NYUthr_U));   % USC method, NYU thresh
T.asd_nyu_10   = col(double(r.ASD_NYUthr_N10));
T.asd_nyu_15   = pick_field(r, 'ASD_NYUthr_N15', T.asd_nyu_10);
T.asd_nyu_20   = pick_field(r, 'ASD_NYUthr_N20', T.asd_nyu_10);
T.asd_usc      = col(double(r.ASD_NYUthr_U));
end


function T = build_usc_fr1c(r)
n = numel(r.Environment);
T = table();
T.institution  = repmat("USC",   n, 1);
T.band         = repmat("FR1C",  n, 1);
T.freq_ghz     = repmat(6.75,    n, 1);
T.tx_rx_id     = col(string(r.Location_ID));
T.d_m          = col(double(r.Distance_m));
T.loc_type_raw = col(upper(strtrim(string(r.Environment))));
T.pl_db        = col(double(r.PL_USC));
T.omni_ds_ns   = col(double(r.DS_USC));
T.asa_nyu_10   = col(double(r.ASA_NYU_10dB));
T.asa_nyu_15   = pick_field(r, 'ASA_NYU_15dB', T.asa_nyu_10);
T.asa_nyu_20   = pick_field(r, 'ASA_NYU_20dB', T.asa_nyu_10);
T.asa_usc      = col(double(r.ASA_USC));
T.asd_nyu_10   = col(double(r.ASD_NYU_10dB));
T.asd_nyu_15   = pick_field(r, 'ASD_NYU_15dB', T.asd_nyu_10);
T.asd_nyu_20   = pick_field(r, 'ASD_NYU_20dB', T.asd_nyu_10);
T.asd_usc      = col(double(r.ASD_USC));
end


% ===========================================================================
function v = col(x)
% Reshape to a column vector, preserving type (string / double / cell...).
v = x(:);
end


function v = pick_field(s, name, fallback)
% Return s.(name) as a column vector if present, else the fallback column.
if isfield(s, name)
    v = col(double(s.(name)));
else
    v = fallback;
end
end


function path_out = resolve_result(share_results_dir, uca_root, subdir, filename)
% Try <share>/matlab/processing/<subdir>/Results/<filename> first (when the
% share/ tree bundles a frozen copy), then the outer live repo.
share_path = fullfile(share_results_dir, filename);
if isfile(share_path)
    path_out = share_path;
    return;
end
outer_path = fullfile(uca_root, 'matlab', 'processing', subdir, 'Results', filename);
if isfile(outer_path)
    path_out = outer_path;
    return;
end
error('load_paper_point_data:missing_data', ...
      ['Could not find UCA results file %s in either\n' ...
       '  %s\n  %s\n' ...
       'Did you run the raw-processing pipeline for %s?'], ...
      filename, share_path, outer_path, subdir);
end

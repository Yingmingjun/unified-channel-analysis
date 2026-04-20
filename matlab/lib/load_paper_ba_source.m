function T = load_paper_ba_source()
% load_paper_ba_source  UCA-pipeline source table for BA PL/DS/ASA/ASD.
%
%   T = load_paper_ba_source() returns a long-format MATLAB table with
%   one row per (institution, band, TX-RX link) built from the SAME
%   Results/*.mat files the paper's paper_figures/*.m producers read:
%
%       Plot_BlandAltman_PL_DS_AS.m  (sub-THz PL/DS)
%       BA_AS_Merged.m               (ASA/ASD at sub-THz + 6.75 GHz)
%
%   Reading the live .mat -- instead of a frozen xlsx snapshot -- keeps
%   the share/ figures exactly aligned with the outer UCA pipeline
%   output. The supplementary N1/N3/U3 UMi xlsx carry the published
%   hand-curated versions of the same numbers.
%
%   Canonical schema:
%       institution, band, freq_ghz, tx_rx_id, d_m,
%       loc_type, loc_type_raw,
%       pl_nyu_sum, pl_usc_pdm,
%       ds_nyu_sum, ds_usc_pdm,
%       asa_nyu_10, asa_nyu_15, asa_nyu_20, asa_usc,
%       asd_nyu_10, asd_nyu_15, asd_nyu_20, asd_usc
%
%   Per-band, per-institution column mapping mirrors
%   BA_AS_Merged.m / Plot_BlandAltman_PL_DS_AS.m:
%
%     sub-THz NYU (all_comparison_results.mat, nyu_142):
%         PL_NYU / PL_USC / DS_NYU / DS_USC,
%         ASA_NYU_10dB / ASA_USC, ASD_NYU_10dB / ASD_USC
%     sub-THz USC (USC145GHz_Full_Results.mat):
%         same column names as NYU 142, on USC data
%     6.75 GHz NYU (all_comparison_results.mat, nyu_7):
%         PL_NYUthr_SUM / PL_NYUthr_pDM /
%         DS_NYUthr_SUM / DS_NYUthr_pDM,
%         ASA_NYUthr_N10 / ASA_NYUthr_U, ASD_NYUthr_N10 / ASD_NYUthr_U
%     6.75 GHz USC (USC7GHz_Full_Results.mat):
%         same column names as NYU 142 / USC 145 (PL_NYU / PL_USC etc.)
%
%   OLOS -> NLOS mapping is applied to loc_type; loc_type_raw preserves
%   the source.

P = paths();

% ---- Resolve Results/*.mat paths (share/-local first, outer repo fallback).
uca_root = fileparts(P.repo_root);
nyu142_path = resolve_result(P.results_nyu_142, uca_root, 'nyu_142', 'all_comparison_results.mat');
usc145_path = resolve_result(P.results_usc_145, uca_root, 'usc_145', 'USC145GHz_Full_Results.mat');
nyu7_path   = resolve_result(P.results_nyu_7,   uca_root, 'nyu_7',   'all_comparison_results.mat');
usc7_path   = resolve_result(P.results_usc_7,   uca_root, 'usc_7',   'USC7GHz_Full_Results.mat');

nyu142 = load(nyu142_path);  usc145 = load(usc145_path);
nyu7   = load(nyu7_path);    usc7   = load(usc7_path);

frames = {};
frames{end+1} = build_nyu_subthz(nyu142.results); %#ok<*AGROW>
frames{end+1} = build_usc_subthz(usc145.results);
frames{end+1} = build_nyu_fr1c  (nyu7.results);
frames{end+1} = build_usc_fr1c  (usc7.results);
T = vertcat(frames{:});

T.loc_type = T.loc_type_raw;
T.loc_type(T.loc_type_raw == "OLOS") = "NLOS";
end


% ===========================================================================
function T = build_nyu_subthz(r)
n = numel(r.Environment);
T = table();
T.institution  = repmat("NYU",    n, 1);
T.band         = repmat("subTHz", n, 1);
T.freq_ghz     = repmat(142.0,    n, 1);
T.tx_rx_id     = col(string(r.TX_RX_ID));
T.d_m          = col(double(r.Distance_m));
T.loc_type_raw = col(upper(strtrim(string(r.Environment))));
T.pl_nyu_sum   = col(double(r.PL_NYU));
T.pl_usc_pdm   = col(double(r.PL_USC));
T.ds_nyu_sum   = col(double(r.DS_NYU));
T.ds_usc_pdm   = col(double(r.DS_USC));
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
T.pl_nyu_sum   = col(double(r.PL_NYU));
T.pl_usc_pdm   = col(double(r.PL_USC));
T.ds_nyu_sum   = col(double(r.DS_NYU));
T.ds_usc_pdm   = col(double(r.DS_USC));
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
% NYU 6.75 GHz: paper uses NYU threshold on NYU data -> NYUthr_* columns
% (matches BA_AS_Merged.m lines 95-99 and Plot_BlandAltman_PL_DS_AS.m).
n = numel(r.Environment);
T = table();
T.institution  = repmat("NYU",   n, 1);
T.band         = repmat("FR1C",  n, 1);
T.freq_ghz     = repmat(6.75,    n, 1);
T.tx_rx_id     = col(string(r.TX_RX_ID));
T.d_m          = col(double(r.Distance_m));
T.loc_type_raw = col(upper(strtrim(string(r.Environment))));
T.pl_nyu_sum   = col(double(r.PL_NYUthr_SUM));
T.pl_usc_pdm   = col(double(r.PL_NYUthr_pDM));
T.ds_nyu_sum   = col(double(r.DS_NYUthr_SUM));
T.ds_usc_pdm   = col(double(r.DS_NYUthr_pDM));
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
T.pl_nyu_sum   = col(double(r.PL_NYU));
T.pl_usc_pdm   = col(double(r.PL_USC));
T.ds_nyu_sum   = col(double(r.DS_NYU));
T.ds_usc_pdm   = col(double(r.DS_USC));
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
% Reshape to a column vector (fields in the .mat struct have mixed
% [n,1] / [1,n] orientation).
v = x(:);
end


function v = pick_field(s, name, fallback)
if isfield(s, name)
    v = col(double(s.(name)));
else
    v = fallback;
end
end


function path_out = resolve_result(share_results_dir, uca_root, subdir, filename)
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
error('load_paper_ba_source:missing_data', ...
      ['Could not find UCA results file %s in either\n' ...
       '  %s\n  %s\n' ...
       'Did you run the raw-processing pipeline for %s?'], ...
      filename, share_path, outer_path, subdir);
end

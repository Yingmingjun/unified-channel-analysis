function P = paths()
% paths  Absolute paths to all raw data, antenna patterns, point-data tables,
%        per-pipeline Results directories, and the paper-figure output folder.
%
%   P = paths() returns a struct with fields naming every canonical input
%   file / directory consumed by the raw-to-paper MATLAB pipeline, plus the
%   per-pipeline Results folders (which the raw-processing scripts write to)
%   and a single output directory for paper figures and tables.
%
%   All fields are derived from the repo root -- the file you are reading
%   lives at <repo>/matlab/config/paths.m, so <repo> is computed as the
%   parent of the parent of this file's directory. The MATLAB pipeline is
%   therefore fully relocatable: copy the repo to any disk on any machine
%   and every script that calls paths() resolves the correct absolute paths.
%
% Notes:
%   * N1 values are loaded from the "NYU orig." column of the N3 xlsx, so
%     n1_*_xlsx and n3_*_xlsx point to the same file (see docs/issues_log.md).
%   * Similarly U1 is read from the "USC orig." column of the U3 xlsx.
%   * Point-data tables are bundled under <repo>/data/point_data/. To use
%     a different drop, set the CHANNEL_DATA_ROOT environment variable.
%   * Raw-data folders are bundled under <repo>/data/raw/. About 11 GB total.
%   * paper_fig_out is an alias for out_dir so verbatim author scripts that
%     expect a "paper figures" folder just dump into our unified output dir.
%
% Mirrors python/src/channel_analysis/config.py DATA_PATHS.

% -- Resolve repo root (parents[1] of this file's directory) -----------------
this_dir  = fileparts(mfilename('fullpath'));
repo_root = fileparts(fileparts(this_dir));  % <repo>/matlab/config/.. ..

P.repo_root = repo_root;

% -- Data base root ----------------------------------------------------------
% If this share/ tree is nested inside a live UCA repo (parent directory
% exposes a populated matlab/processing/nyu_142/Results/ tree), auto-
% redirect ALL data paths (raw, Results, antenna patterns, TX-power CSVs,
% point-data xlsx) to the parent UCA repo. This lets a user re-run the
% share/ pipeline against an existing UCA data drop without duplicating
% files under share/. If share/ is unpacked standalone, DATA_BASE falls
% back to repo_root and the user stages their own data under
% share/data/raw/ per DATA_ORGANIZATION.md.
parent_root = fileparts(repo_root);
parent_has_results = isfile(fullfile(parent_root, 'matlab', 'processing', ...
    'nyu_142', 'Results', 'all_comparison_results.mat')) || ...
    isfile(fullfile(parent_root, 'matlab', 'processing', ...
    'usc_145', 'Results', 'USC145GHz_Full_Results.mat'));
if parent_has_results
    DATA_BASE = parent_root;
else
    DATA_BASE = repo_root;
end

% -- Point-data root (defaults to <DATA_BASE>/data/point_data/) --------------
env_root = getenv('CHANNEL_DATA_ROOT');
if isempty(env_root)
    DATA_ROOT = fullfile(DATA_BASE, 'data', 'point_data');
else
    DATA_ROOT = env_root;
end

P.point_data = DATA_ROOT;

% -- Canonical per-institution xlsx tables -----------------------------------
P.n1_142_xlsx = fullfile(DATA_ROOT, 'N1_142_UMi.xlsx');
P.n1_7_xlsx   = fullfile(DATA_ROOT, 'N1_7_UMi.xlsx');
P.n3_142_xlsx = fullfile(DATA_ROOT, 'N3_142_UMi.xlsx');
P.n3_7_xlsx   = fullfile(DATA_ROOT, 'N3_7_UMi.xlsx');
P.u3_142_xlsx = fullfile(DATA_ROOT, 'U3_142_UMi.xlsx');
P.u3_7_xlsx   = fullfile(DATA_ROOT, 'U3_7_UMi.xlsx');
P.u1_142_xlsx = P.u3_142_xlsx;   % U1 lives in U3 xlsx "USC orig" column
P.u1_7_xlsx   = P.u3_7_xlsx;

% -- Raw data (read-only inputs) ---------------------------------------------
P.raw_nyu_142 = fullfile(DATA_BASE, 'data', 'raw', 'nyu_142');
P.raw_nyu_7   = fullfile(DATA_BASE, 'data', 'raw', 'nyu_7');
P.raw_usc_145 = fullfile(DATA_BASE, 'data', 'raw', 'usc_145');
P.raw_usc_7   = fullfile(DATA_BASE, 'data', 'raw', 'usc_7');

% USC raw 145 GHz splits into LoS / NLoS subdirs (verbatim from the source tree)
P.raw_usc_145_LOS  = fullfile(P.raw_usc_145, 'LoS');
P.raw_usc_145_NLOS = fullfile(P.raw_usc_145, 'NLoS');

% USC raw 6.75 GHz splits into "LOS Study" / "OLOS Study" subdirs
P.raw_usc_7_LOS   = fullfile(P.raw_usc_7, 'LOS Study');
P.raw_usc_7_NLOS  = fullfile(P.raw_usc_7, 'OLOS Study');

% -- Antenna patterns & calibration files ------------------------------------
% All of these files are campaign/hardware-specific measurement or
% characterization data that share/ does NOT ship. They are resolved
% against DATA_BASE (the parent UCA repo if share/ is nested inside
% one, else repo_root for a standalone share/ tree). See
% DATA_ORGANIZATION.md for the contract.
P.nyu_142_tx_power_csv   = fullfile(DATA_BASE, 'matlab', 'processing', 'nyu_142', '140GHz_Outdoor_BaseStation.csv');
P.nyu_142_hplane_pattern = fullfile(DATA_BASE, 'matlab', 'patterns', 'HPLANE Pattern Data 261D-27.DAT');
P.nyu_142_eplane_pattern = fullfile(DATA_BASE, 'matlab', 'patterns', 'EPLANE Pattern Data 261D-27.DAT');
P.nyu_142_pattern_dir    = fullfile(DATA_BASE, 'matlab', 'patterns');

P.nyu_7_tx_power_csv     = fullfile(DATA_BASE, 'matlab', 'processing', 'nyu_7', '7GHz_Outdoor (1).csv');
P.nyu_7_phi0             = fullfile(DATA_BASE, 'matlab', 'processing', 'nyu_7', '7_phi0_pd.mat');
P.nyu_7_phi90            = fullfile(DATA_BASE, 'matlab', 'processing', 'nyu_7', '7_phi90_pd.mat');

P.usc_145_azicut         = fullfile(DATA_BASE, 'matlab', 'processing', 'usc_145', 'aziCut.mat');
P.usc_145_elevcut        = fullfile(DATA_BASE, 'matlab', 'processing', 'usc_145', 'elevCut.mat');
P.usc_145_pattern_dir    = fullfile(DATA_BASE, 'matlab', 'processing', 'usc_145');

P.usc_7_antenna_pattern  = fullfile(DATA_BASE, 'matlab', 'processing', 'usc_7', 'USC_Midband_Pattern.mat');
P.usc_7_pattern_dir      = fullfile(DATA_BASE, 'matlab', 'processing', 'usc_7');

% -- Per-pipeline Results / Figures directories ------------------------------
% Each raw-processing script writes its Results/ here. If share/ is
% nested in a live UCA repo with pre-computed Results, DATA_BASE points
% at the parent, so share/paper_figures/*.m and share/figures/fig0X_*.m
% consume the existing .mat files without duplication. If share/ is
% standalone, these paths resolve under share/matlab/processing/*/
% and the processing scripts write fresh Results there.
P.results_nyu_142 = fullfile(DATA_BASE, 'matlab', 'processing', 'nyu_142', 'Results');
P.results_nyu_7   = fullfile(DATA_BASE, 'matlab', 'processing', 'nyu_7',   'Results');
P.results_usc_145 = fullfile(DATA_BASE, 'matlab', 'processing', 'usc_145', 'Results');
P.results_usc_7   = fullfile(DATA_BASE, 'matlab', 'processing', 'usc_7',   'Results');

P.figures_nyu_142 = fullfile(DATA_BASE, 'matlab', 'processing', 'nyu_142', 'Figures');
P.figures_nyu_7   = fullfile(DATA_BASE, 'matlab', 'processing', 'nyu_7',   'Figures');
P.figures_usc_145 = fullfile(DATA_BASE, 'matlab', 'processing', 'usc_145', 'Figures');
P.figures_usc_7   = fullfile(DATA_BASE, 'matlab', 'processing', 'usc_7',   'Figures');

% -- Codebase-A 7 GHz cross-processing inputs --------------------------------
P.cb_a_root                  = fullfile(repo_root, 'data', 'raw_cb_a');
P.cb_a_nyu_format_usc_7      = fullfile(P.cb_a_root, 'NYUformatUSCdata7');
P.cb_a_usc_format_nyu_7      = fullfile(P.cb_a_root, 'USCformatNYUdata7');
P.cb_a_thresholded_root      = fullfile(P.cb_a_root, 'NYU_Data_thresholded_7');
P.cb_a_thresholded_142       = fullfile(P.cb_a_thresholded_root, '142 GHz');
P.cb_a_thresholded_7         = fullfile(P.cb_a_thresholded_root, '7 GHz');
P.cb_a_usc_antenna_root      = fullfile(P.cb_a_root, 'USC_antennaPattern');
P.cb_a_usc_3d_pattern        = fullfile(P.cb_a_usc_antenna_root, 'THz_3D_pattern_aver.mat');
P.cb_a_usc_eplane_7          = fullfile(P.cb_a_usc_antenna_root, 'EPlanePattern7.dat');
P.cb_a_usc_hplane_7          = fullfile(P.cb_a_usc_antenna_root, 'HPlanePattern7.dat');
P.cb_a_usc_azicut            = fullfile(P.cb_a_usc_antenna_root, 'aziCut.mat');
P.cb_a_usc_elevcut           = fullfile(P.cb_a_usc_antenna_root, 'elevCut.mat');

% -- Output locations for CB-A regenerated xlsx ------------------------------
% The CB-A scripts write to a "_cba_regenerated" side-by-side filename so
% they do NOT clobber the authoritative paper-typesetting xlsx snapshots.
% Compare the regenerated vs bundled values manually; if Dipankar's scripts
% now produce paper-matching values, swap the file names to reproduce
% Table VI cells for 6.75 GHz USC-data.
P.cb_a_out_u3_7_xlsx         = fullfile(repo_root, 'data', 'point_data', '7_UMi_U3_cba_regenerated.xlsx');
P.cb_a_out_n3_7_xlsx         = fullfile(repo_root, 'data', 'point_data', '7_UMi_N3_cba_regenerated.xlsx');

% -- Output directory for all paper figures and tables -----------------------
P.out_dir       = fullfile(repo_root, 'figures', 'matlab');
% Some paper-figure scripts hardcode a "paper figures" folder inside the
% paper source tree; for a standalone repo, alias it to our out_dir.
P.paper_fig_out = P.out_dir;

% -- Optional: paper-source tree paths --------------------------------------
% Set via env vars. Left empty by default so the pipeline never silently
% overwrites the paper tree. Set PAPER_TREE_DIR (or individual vars below)
% before running run_all if you want the tools/update_paper_tex,
% tools/generate_supplement_tex, and tools/stage_paper_figures helpers to
% write into the paper source tree.
%
%   PAPER_TREE_DIR   : root dir of the paper tex project (parent of main_final.tex)
%   PAPER_FIG_DIR    : overrides PAPER_TREE_DIR/figures
%   PAPER_TEX_PATH   : overrides PAPER_TREE_DIR/main_final.tex
%   PAPER_SUPP_PATH  : overrides PAPER_TREE_DIR/supplement.tex
P.paper_src_root     = getenv('PAPER_TREE_DIR');
P.paper_src_fig_dir  = getenv('PAPER_FIG_DIR');
P.paper_src_tex_path = getenv('PAPER_TEX_PATH');
P.paper_src_supp_path = getenv('PAPER_SUPP_PATH');
if isempty(P.paper_src_fig_dir) && ~isempty(P.paper_src_root)
    P.paper_src_fig_dir = fullfile(P.paper_src_root, 'figures');
end
if isempty(P.paper_src_tex_path) && ~isempty(P.paper_src_root)
    P.paper_src_tex_path = fullfile(P.paper_src_root, 'main_final.tex');
end
if isempty(P.paper_src_supp_path) && ~isempty(P.paper_src_root)
    P.paper_src_supp_path = fullfile(P.paper_src_root, 'supplement.tex');
end

% -- Analysis constants (kept in sync with python config.py) -----------------
P.D0_METERS       = 1.0;
P.CONFIDENCE      = 0.95;
P.BOOTSTRAP_ITERS = 2000;
P.RNG_SEED        = 0;
end

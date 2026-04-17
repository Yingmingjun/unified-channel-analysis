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

% -- Point-data root (defaults to bundled data/point_data/) ------------------
env_root = getenv('CHANNEL_DATA_ROOT');
if isempty(env_root)
    DATA_ROOT = fullfile(repo_root, 'data', 'point_data');
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
P.raw_nyu_142 = fullfile(repo_root, 'data', 'raw', 'nyu_142');
P.raw_nyu_7   = fullfile(repo_root, 'data', 'raw', 'nyu_7');
P.raw_usc_145 = fullfile(repo_root, 'data', 'raw', 'usc_145');
P.raw_usc_7   = fullfile(repo_root, 'data', 'raw', 'usc_7');

% USC raw 145 GHz splits into LoS / NLoS subdirs (verbatim from the source tree)
P.raw_usc_145_LOS  = fullfile(P.raw_usc_145, 'LoS');
P.raw_usc_145_NLOS = fullfile(P.raw_usc_145, 'NLoS');

% USC raw 6.75 GHz splits into "LOS Study" / "OLOS Study" subdirs
P.raw_usc_7_LOS   = fullfile(P.raw_usc_7, 'LOS Study');
P.raw_usc_7_NLOS  = fullfile(P.raw_usc_7, 'OLOS Study');

% -- Antenna patterns & calibration files ------------------------------------
P.nyu_142_tx_power_csv   = fullfile(repo_root, 'matlab', 'processing', 'nyu_142', '140GHz_Outdoor_BaseStation.csv');
P.nyu_142_hplane_pattern = fullfile(repo_root, 'matlab', 'patterns', 'HPLANE Pattern Data 261D-27.DAT');
P.nyu_142_eplane_pattern = fullfile(repo_root, 'matlab', 'patterns', 'EPLANE Pattern Data 261D-27.DAT');
P.nyu_142_pattern_dir    = fullfile(repo_root, 'matlab', 'patterns');

P.nyu_7_tx_power_csv     = fullfile(repo_root, 'matlab', 'processing', 'nyu_7', '7GHz_Outdoor (1).csv');
P.nyu_7_phi0             = fullfile(repo_root, 'matlab', 'processing', 'nyu_7', '7_phi0_pd.mat');
P.nyu_7_phi90            = fullfile(repo_root, 'matlab', 'processing', 'nyu_7', '7_phi90_pd.mat');

P.usc_145_azicut         = fullfile(repo_root, 'matlab', 'processing', 'usc_145', 'aziCut.mat');
P.usc_145_elevcut        = fullfile(repo_root, 'matlab', 'processing', 'usc_145', 'elevCut.mat');
P.usc_145_pattern_dir    = fullfile(repo_root, 'matlab', 'processing', 'usc_145');

P.usc_7_antenna_pattern  = fullfile(repo_root, 'matlab', 'processing', 'usc_7', 'USC_Midband_Pattern.mat');
P.usc_7_pattern_dir      = fullfile(repo_root, 'matlab', 'processing', 'usc_7');

% -- Per-pipeline Results / Figures directories ------------------------------
% Each raw-processing script writes its results here. Created on demand.
P.results_nyu_142 = fullfile(repo_root, 'matlab', 'processing', 'nyu_142', 'Results');
P.results_nyu_7   = fullfile(repo_root, 'matlab', 'processing', 'nyu_7',   'Results');
P.results_usc_145 = fullfile(repo_root, 'matlab', 'processing', 'usc_145', 'Results');
P.results_usc_7   = fullfile(repo_root, 'matlab', 'processing', 'usc_7',   'Results');

P.figures_nyu_142 = fullfile(repo_root, 'matlab', 'processing', 'nyu_142', 'Figures');
P.figures_nyu_7   = fullfile(repo_root, 'matlab', 'processing', 'nyu_7',   'Figures');
P.figures_usc_145 = fullfile(repo_root, 'matlab', 'processing', 'usc_145', 'Figures');
P.figures_usc_7   = fullfile(repo_root, 'matlab', 'processing', 'usc_7',   'Figures');

% -- Output directory for all paper figures and tables -----------------------
P.out_dir       = fullfile(repo_root, 'figures', 'matlab');
% Some paper-figure scripts hardcode a "paper figures" folder inside the
% paper source tree; for a standalone repo, alias it to our out_dir.
P.paper_fig_out = P.out_dir;

% -- Analysis constants (kept in sync with python config.py) -----------------
P.D0_METERS       = 1.0;
P.CONFIDENCE      = 0.95;
P.BOOTSTRAP_ITERS = 2000;
P.RNG_SEED        = 0;
end

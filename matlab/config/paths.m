function P = paths()
% paths  Absolute paths to all input xlsx tables and output directory.
%
%   P = paths() returns a struct with fields naming each canonical input
%   file and the figures output directory. These paths mirror the Python
%   reference configuration in python/src/channel_analysis/config.py.
%
% Notes:
%   * N1 values are loaded from the "NYU orig." column of the N3 xlsx, so
%     n1_*_xlsx and n3_*_xlsx point to the same file (see docs/issues_log.md).
%   * Similarly U1 is read from the "USC orig." column of the U3 xlsx.
%   * Point-data tables are bundled under <repo>/data/point_data/.  To use
%     a different drop, set the CHANNEL_DATA_ROOT environment variable or
%     edit DATA_ROOT below.

% Mirrors python/src/channel_analysis/config.py DATA_PATHS

% -- Resolve repo root (parents[1] of this file's directory) -----------------
this_dir  = fileparts(mfilename('fullpath'));
repo_root = fileparts(fileparts(this_dir));  % <repo>/matlab/config/.. ..

% -- Input data root (defaults to bundled data/point_data/) ------------------
env_root = getenv('CHANNEL_DATA_ROOT');
if isempty(env_root)
    DATA_ROOT = fullfile(repo_root, 'data', 'point_data');
else
    DATA_ROOT = env_root;
end

% -- Canonical per-institution xlsx tables -----------------------------------
P.n1_142_xlsx = fullfile(DATA_ROOT, 'N1_142_UMi.xlsx');
P.n1_7_xlsx   = fullfile(DATA_ROOT, 'N1_7_UMi.xlsx');
P.n3_142_xlsx = fullfile(DATA_ROOT, 'N3_142_UMi.xlsx');
P.n3_7_xlsx   = fullfile(DATA_ROOT, 'N3_7_UMi.xlsx');
P.u3_142_xlsx = fullfile(DATA_ROOT, 'U3_142_UMi.xlsx');
P.u3_7_xlsx   = fullfile(DATA_ROOT, 'U3_7_UMi.xlsx');
P.u1_142_xlsx = P.u3_142_xlsx;   % U1 lives in U3 xlsx "USC orig" column
P.u1_7_xlsx   = P.u3_7_xlsx;

% -- Output directory (created by run_all.m if missing) ----------------------
P.out_dir = fullfile(repo_root, 'figures', 'matlab');

% -- Analysis constants (kept in sync with python config.py) -----------------
P.D0_METERS       = 1.0;
P.CONFIDENCE      = 0.95;
P.BOOTSTRAP_ITERS = 2000;
P.RNG_SEED        = 0;
end

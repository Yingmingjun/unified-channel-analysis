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
%   * Users running the port on a different machine may need to edit this
%     function's DATA_ROOT constant.

% Mirrors python/src/channel_analysis/config.py DATA_PATHS

% -- Resolve repo root (parents[1] of this file's directory) -----------------
this_dir  = fileparts(mfilename('fullpath'));
repo_root = fileparts(this_dir);  % <repo>/matlab/..

% -- Input data root (read-only; not shipped with the repo) ------------------
DATA_ROOT = 'D:/NaveedDipankarMingjunJorgeShare/NaveedDipankarMingjunJorgeShare';

% -- Canonical per-institution xlsx tables -----------------------------------
% N1: NYU original point-data (loaded from "NYU orig." column of the N3 xlsx).
P.n1_142_xlsx = fullfile(DATA_ROOT, 'USC/USCprocessNYUdata/OriginalNYU_pointData/142_UMi_N3.xlsx');
P.n1_7_xlsx   = fullfile(DATA_ROOT, 'USC/USCprocessNYUdata/OriginalNYU_pointData/7_UMi_N3.xlsx');

% U1: USC original point-data (loaded from "USC orig." column of the U3 xlsx).
P.u1_142_xlsx = fullfile(DATA_ROOT, 'NYU/NYUprocessUSCdata/OriginalUSC-PointData/142_UMi_U3.xlsx');
P.u1_7_xlsx   = fullfile(DATA_ROOT, 'NYU/NYUprocessUSCdata/OriginalUSC-PointData/7_UMi_U3.xlsx');

% N3: NYU data cross-processed by the USC pipeline (two thresholds live inside).
P.n3_142_xlsx = P.n1_142_xlsx;   % same physical file
P.n3_7_xlsx   = P.n1_7_xlsx;

% U3: USC data cross-processed by the NYU pipeline (two thresholds live inside).
P.u3_142_xlsx = P.u1_142_xlsx;   % same physical file
P.u3_7_xlsx   = P.u1_7_xlsx;

% -- Output directory (created by run_all.m if missing) ----------------------
P.out_dir = fullfile(repo_root, 'figures', 'matlab');

% -- Analysis constants (kept in sync with python config.py) -----------------
P.D0_METERS       = 1.0;
P.CONFIDENCE      = 0.95;
P.BOOTSTRAP_ITERS = 2000;
P.RNG_SEED        = 0;
end

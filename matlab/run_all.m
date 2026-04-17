% run_all.m
% ============================================================================
% MATLAB parallel port of the unified channel-analysis package.
%
% IMPORTANT
% ---------
% The Python implementation at <repo>/python/ is the VERIFIED reference
% implementation. The MATLAB source in this directory is a parallel port
% intended to be run by the user on their own MATLAB-licensed machine. This
% code has NOT been executed inside the authoring sandbox; the user is
% expected to verify numerical parity against the Python outputs (see
% docs/numerical_parity.md).
%
% Usage (from a MATLAB prompt):
%     cd <repo>/matlab
%     run_all
%
% Each driver below writes PNG + PDF + (for tables) CSV into
%     <repo>/figures/matlab/
% The driver order mirrors python/src/channel_analysis/run_all.py.
% ============================================================================

% Mirrors python/src/channel_analysis/run_all.py

% -- Set up paths so that lib/, config/, figures/ are on the MATLAB path ------
this_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(this_dir, 'config'));
addpath(fullfile(this_dir, 'lib'));
addpath(fullfile(this_dir, 'figures'));

% -- Apply paper-wide plot styling (fonts, colors, line widths) ---------------
plot_style();

% -- Ensure output directory exists -------------------------------------------
P = paths();
if ~exist(P.out_dir, 'dir')
    mkdir(P.out_dir);
end

fprintf('[run_all] Output directory: %s\n', P.out_dir);

% -- Figure drivers (Section V of the paper) ---------------------------------
fprintf('[run_all] fig03 Bland-Altman PL/DS ...\n');
fig03_bland_altman_pl_ds();

fprintf('[run_all] fig04 Bland-Altman AS ...\n');
fig04_bland_altman_as();

fprintf('[run_all] fig05 CI PL scatter ...\n');
fig05_ci_pl_scatter();

fprintf('[run_all] fig06 RMS DS CDF ...\n');
fig06_ds_cdf();

fprintf('[run_all] fig07 Omni ASA CDF ...\n');
fig07_asa_cdf();

fprintf('[run_all] fig08 Omni ASD CDF ...\n');
fig08_asd_cdf();

% -- Table drivers ------------------------------------------------------------
fprintf('[run_all] table06 RMSE ...\n');
table06_rmse();

fprintf('[run_all] table07 Pooled stats ...\n');
table07_pooled_stats();

fprintf('[run_all] table_dumps (Tables 4, 8, 9, 10, 11) ...\n');
table_dumps();

fprintf('[run_all] paper_parity (Paper vs Python vs MATLAB) ...\n');
paper_parity();

fprintf('[run_all] DONE. See %s\n', P.out_dir);

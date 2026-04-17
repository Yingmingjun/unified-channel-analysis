function run_all(mode)
% run_all  End-to-end raw-to-paper MATLAB pipeline for the unified repo.
%
%   run_all          -- Full pipeline. Raw processing steps are SKIPPED if
%                       their canonical result file already exists.
%   run_all('rebuild') -- Force rerun of every raw-processing step, even if
%                         Results/*.mat already exists.
%   run_all('figures') -- Skip raw processing entirely; only regenerate the
%                         paper-figure scripts (requires Results/*.mat
%                         produced by a previous run).
%
% Pipeline layout:
%   STEP 1: Raw processing (may take 30-60 minutes total on first run)
%           - NYU 142 GHz        -> matlab/processing/nyu_142/Results/
%           - NYU 6.75 GHz       -> matlab/processing/nyu_7/Results/
%           - USC 145.5 GHz      -> matlab/processing/usc_145/Results/
%           - USC 6.75 GHz       -> matlab/processing/usc_7/Results/
%   STEP 2: Paper-figure scripts (verbatim authors' scripts)
%   STEP 3: Unified figure drivers (Python-parity CSVs + PDFs)
%   STEP 4: Console summary
%
% Each script call is wrapped in try/catch so that a single failure does
% not abort the remaining steps. Progress banners are printed between
% stages, and a STEP 4 summary reports what succeeded vs failed.

if nargin < 1
    mode = 'default';
end
mode = lower(string(mode));

% ----------------------------------------------------------------------------
% MATLAB path setup: expose config/, lib/, lib_tcsl/, figures/, paper_figures/,
% processing/<band>/, and the patterns dir to every called script.
% ----------------------------------------------------------------------------
this_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(this_dir, 'config'));
addpath(fullfile(this_dir, 'lib'));
addpath(genpath(fullfile(this_dir, 'lib_tcsl')));
addpath(fullfile(this_dir, 'figures'));
addpath(fullfile(this_dir, 'paper_figures'));
addpath(fullfile(this_dir, 'processing', 'nyu_142'));
addpath(fullfile(this_dir, 'processing', 'nyu_7'));
addpath(fullfile(this_dir, 'processing', 'usc_145'));
addpath(fullfile(this_dir, 'processing', 'usc_7'));
addpath(fullfile(this_dir, 'patterns'));

% ----------------------------------------------------------------------------
% Apply paper-wide plot styling (fonts, colors, line widths)
% ----------------------------------------------------------------------------
plot_style();

% ----------------------------------------------------------------------------
% Ensure output directory exists
% ----------------------------------------------------------------------------
P = paths();
if ~exist(P.out_dir, 'dir'), mkdir(P.out_dir); end

fprintf('\n');
fprintf('============================================================\n');
fprintf('  Unified channel-analysis MATLAB pipeline (%s)\n', datestr(now));
fprintf('============================================================\n');
fprintf('  Repo root     : %s\n', P.repo_root);
fprintf('  Output dir    : %s\n', P.out_dir);
fprintf('  Mode          : %s\n', mode);
fprintf('============================================================\n\n');

% Track per-stage outcomes for the final summary.
status = struct();

% ============================================================================
% STEP 1: Raw processing
% ============================================================================
banner(1, 'Raw processing (may take 30-60 minutes on first run)');

raw_steps = {
    % label,            script function/name,                result marker,                                             results dir
    'NYU 142 GHz',      'NYU142GHz_Method_Comparison',       fullfile(P.results_nyu_142, 'all_comparison_results.mat'), P.results_nyu_142;
    'NYU 6.75 GHz',     'NYU7GHz_Method_Comparison',         fullfile(P.results_nyu_7,   'all_comparison_results.mat'), P.results_nyu_7;
    'USC 145.5 GHz',    'USC142GHz_Method_Comparison_Full',  fullfile(P.results_usc_145, 'USC145GHz_Full_Results.mat'), P.results_usc_145;
    'USC 6.75 GHz',     'USC7GHz_NewData_Processing',        fullfile(P.results_usc_7,   'USC7GHz_Full_Results.mat'),   P.results_usc_7;
};

for i = 1:size(raw_steps, 1)
    label   = raw_steps{i, 1};
    script  = raw_steps{i, 2};
    marker  = raw_steps{i, 3};
    outdir  = raw_steps{i, 4};

    if ~exist(outdir, 'dir'), mkdir(outdir); end

    should_skip = (mode ~= "rebuild") && exist(marker, 'file');
    if mode == "figures"
        should_skip = true;  % figures-only mode never runs raw processing
    end

    if should_skip
        fprintf('[STEP 1.%d] %s : SKIP (found %s)\n', i, label, marker);
        status.(sanitize(label)) = "skipped";
        continue;
    end

    fprintf('\n----- [STEP 1.%d] %s : running %s.m -----\n', i, label, script);
    t0 = tic;
    try
        % Each raw-processing script is a top-level "clear; clc" script,
        % so we evalin('base', ...) to run it in the base workspace.
        evalin('base', sprintf('clear; %s;', script));
        status.(sanitize(label)) = "ok";
        fprintf('[STEP 1.%d] %s : DONE (%.1f min)\n', i, label, toc(t0)/60);
    catch ME
        status.(sanitize(label)) = "failed";
        fprintf(2, '[STEP 1.%d] %s : FAILED -- %s\n', i, label, ME.message);
        fprintf(2, '  %s\n', getReport(ME, 'basic'));
    end
end

% ============================================================================
% STEP 2: Paper-figure scripts (verbatim from authors)
% ============================================================================
banner(2, 'Paper-figure scripts (verbatim authors'' scripts)');

paper_steps = {
    'cdf_ci_pl_analysis'         , 'Fig 5 CI PL + Fig 6 DS CDF (sub-THz)';
    'cdf_ci_pl_analysis_DS_ref'  , 'Fig 6 DS CDF (6.75 GHz)';
    'AS_CDF_Merged'              , 'Figs 7 & 8 ASA/ASD CDF';
    'bland_altman_analysis'      , 'Fig 3 BA PL/DS';
    'BA_AS_Merged'               , 'Fig 4 BA ASA/ASD';
    'Plot_BlandAltman_PL_DS_AS'  , 'Alt BA generator';
    'calculate_AS_RMSE'          , 'Table VI ASA/ASD RMSE';
};

for i = 1:size(paper_steps, 1)
    script = paper_steps{i, 1};
    desc   = paper_steps{i, 2};
    fprintf('\n----- [STEP 2.%d] %-32s (%s) -----\n', i, script, desc);
    try
        evalin('base', sprintf('clear; %s;', script));
        status.(sanitize(script)) = "ok";
        fprintf('[STEP 2.%d] %s : OK\n', i, script);
    catch ME
        status.(sanitize(script)) = "failed";
        fprintf(2, '[STEP 2.%d] %s : FAILED -- %s\n', i, script, ME.message);
    end
end

% ============================================================================
% STEP 3: Unified figure drivers (Python-parity CSVs + PDFs)
% ============================================================================
banner(3, 'Unified figure drivers (Python parity)');

unified_steps = {
    'fig03_bland_altman_pl_ds',  'Fig 3 BA PL/DS';
    'fig04_bland_altman_as',     'Fig 4 BA AS';
    'fig05_ci_pl_scatter',       'Fig 5 CI PL scatter';
    'fig06_ds_cdf',              'Fig 6 DS CDF';
    'fig07_asa_cdf',             'Fig 7 ASA CDF';
    'fig08_asd_cdf',             'Fig 8 ASD CDF';
    'table06_rmse',              'Table 6 RMSE';
    'table07_pooled_stats',      'Table 7 pooled stats';
    'table_dumps',               'Tables 4, 8, 9, 10, 11';
    'paper_parity',              'Paper vs Python vs MATLAB side-by-side';
};

for i = 1:size(unified_steps, 1)
    fn = unified_steps{i, 1};
    desc = unified_steps{i, 2};
    fprintf('\n----- [STEP 3.%d] %-28s (%s) -----\n', i, fn, desc);
    try
        feval(fn);
        status.(sanitize(fn)) = "ok";
        fprintf('[STEP 3.%d] %s : OK\n', i, fn);
    catch ME
        status.(sanitize(fn)) = "failed";
        fprintf(2, '[STEP 3.%d] %s : FAILED -- %s\n', i, fn, ME.message);
    end
end

% ============================================================================
% STEP 4: Console summary
% ============================================================================
banner(4, 'Summary');

fprintf('  Raw-processing outcomes:\n');
raw_labels = {'NYU 142 GHz', 'NYU 6.75 GHz', 'USC 145.5 GHz', 'USC 6.75 GHz'};
for k = 1:numel(raw_labels)
    lbl = raw_labels{k};
    st  = getfield_default(status, sanitize(lbl), "(not run)");
    fprintf('    - %-16s : %s\n', lbl, st);
end
fprintf('\n  Output locations:\n');
fprintf('    - Per-pipeline Results : %s\n', fullfile(P.repo_root, 'matlab', 'processing', '*', 'Results'));
fprintf('    - Paper figures        : %s\n', P.out_dir);
fprintf('\n  To rerun raw processing from scratch: run_all(''rebuild'')\n');
fprintf('  To regenerate figures only           : run_all(''figures'')\n\n');

fprintf('============================================================\n');
fprintf('  Done.\n');
fprintf('============================================================\n\n');
end

% ----------------------------------------------------------------------------
% Helpers
% ----------------------------------------------------------------------------
function banner(stepNum, text)
    fprintf('\n');
    fprintf('############################################################\n');
    fprintf('#  STEP %d: %s\n', stepNum, text);
    fprintf('############################################################\n\n');
end

function name = sanitize(s)
    % Convert a human-readable label into a valid MATLAB struct field name.
    name = matlab.lang.makeValidName(char(s));
end

function v = getfield_default(s, f, def)
    if isfield(s, f)
        v = s.(f);
    else
        v = def;
    end
end

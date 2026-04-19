function run_all(mode)
% run_all  End-to-end reproducibility / bring-your-own-data driver.
%
% Two modes:
%   run_all              -- Regenerates Fig. 3--8, Tables VI/VII from the
%                           six point-data xlsx files under
%                           <repo>/data/point_data/. No raw data needed.
%                           (~1--2 min runtime.)
%
%   run_all('raw')       -- Also runs the raw-PDP processing stage
%                           (matlab/processing/) that converts raw
%                           directional PDPs into the xlsx point-data
%                           tables. You MUST place your own raw data
%                           under <repo>/data/raw/{nyu_142,nyu_7,usc_145,
%                           usc_7}/ in the expected format -- see
%                           matlab/processing/README.md. Runtime: 30--60
%                           min on first invocation; skipped if the
%                           downstream Results/*.mat already exists.
%
% Optional paper-tree sync (off unless env vars set):
%   PAPER_TREE_DIR / PAPER_FIG_DIR / PAPER_TEX_PATH / PAPER_SUPP_PATH

if nargin < 1, mode = 'default'; end
mode = lower(string(mode));

this_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(this_dir, 'config'));
addpath(fullfile(this_dir, 'lib'));
addpath(genpath(fullfile(this_dir, 'lib_tcsl')));
addpath(fullfile(this_dir, 'figures'));
addpath(fullfile(this_dir, 'paper_figures'));
addpath(fullfile(this_dir, 'tools'));
addpath(fullfile(this_dir, 'patterns'));
addpath(fullfile(this_dir, 'processing', 'nyu_142'));
addpath(fullfile(this_dir, 'processing', 'nyu_7'));
addpath(fullfile(this_dir, 'processing', 'usc_145'));
addpath(fullfile(this_dir, 'processing', 'usc_7'));

plot_style();
P = paths();
if ~exist(P.out_dir, 'dir'), mkdir(P.out_dir); end

fprintf('\n============================================================\n');
fprintf('  Reproducibility pipeline (MATLAB) -- %s\n', datestr(now));
fprintf('  Mode: %s\n', mode);
fprintf('============================================================\n\n');

% ---------------------------------------------------------------------- %
% Optional Step 0 -- raw processing (only if mode == 'raw')
% ---------------------------------------------------------------------- %
if mode == "raw"
    raw_steps = {
        'NYU 142 GHz',   'NYU142GHz_Method_Comparison',     fullfile(P.results_nyu_142, 'all_comparison_results.mat');
        'NYU 6.75 GHz',  'NYU7GHz_Method_Comparison',       fullfile(P.results_nyu_7,   'all_comparison_results.mat');
        'USC 145 GHz',   'USC142GHz_Method_Comparison_Full', fullfile(P.results_usc_145, 'USC145GHz_Full_Results.mat');
        'USC 6.75 GHz',  'USC7GHz_NewData_Processing',      fullfile(P.results_usc_7,   'USC7GHz_Full_Results.mat');
        };
    for i = 1:size(raw_steps, 1)
        label = raw_steps{i, 1}; script = raw_steps{i, 2}; marker = raw_steps{i, 3};
        if exist(marker, 'file')
            fprintf('[raw %d/4] %-18s : SKIP (cached: %s)\n', i, label, marker);
            continue
        end
        fprintf('[raw %d/4] %-18s : running %s.m\n', i, label, script);
        try
            evalin('base', sprintf('clear; %s;', script));
        catch ME
            fprintf(2, '    FAIL: %s\n', ME.message);
            fprintf(2, '    Hint: does your raw data live under %s?\n', ...
                    fullfile(P.repo_root, 'data', 'raw'));
        end
    end
end

% ---------------------------------------------------------------------- %
% Step 1 -- Paper figures (Fig. 3--8) + tables VI / VII
% ---------------------------------------------------------------------- %
steps = {
    'fig03_bland_altman_pl_ds',   'Fig. 3 BA PL/DS';
    'fig04_bland_altman_as',      'Fig. 4 BA ASA/ASD';
    'fig05_ci_pl_scatter',        'Fig. 5 CI PL scatter';
    'fig06_ds_cdf',               'Fig. 6 DS CDF';
    'fig07_asa_cdf',              'Fig. 7 ASA CDF';
    'fig08_asd_cdf',              'Fig. 8 ASD CDF';
    'table06_rmse',               'Table VI RMSE';
    'table07_pooled_stats',       'Table VII pooled stats';
    'table_dumps',                'Per-table CSV dumps';
    'paper_parity',               'Paper vs pipeline parity report';
    };

for i = 1:size(steps, 1)
    fn = steps{i, 1}; desc = steps{i, 2};
    fprintf('[%2d/%2d] %-26s -- %s\n', i, size(steps, 1), fn, desc);
    try, feval(fn); catch ME, fprintf(2, '    FAIL: %s\n', ME.message); end
end

% ---------------------------------------------------------------------- %
% Step 2 -- Optional paper-tree sync
% ---------------------------------------------------------------------- %
if ~isempty(P.paper_src_fig_dir)
    fprintf('\n[sync] staging paper figures to %s\n', P.paper_src_fig_dir);
    try, stage_paper_figures();      catch ME, fprintf(2, 'FAIL: %s\n', ME.message); end
end
if ~isempty(P.paper_src_supp_path)
    fprintf('\n[sync] regenerating supplement at %s\n', P.paper_src_supp_path);
    try, generate_supplement_tex();  catch ME, fprintf(2, 'FAIL: %s\n', ME.message); end
end

fprintf('\n============================================================\n');
fprintf('  Done. Outputs under %s\n', P.out_dir);
fprintf('============================================================\n');
end

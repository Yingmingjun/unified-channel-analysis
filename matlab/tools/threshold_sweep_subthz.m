function threshold_sweep_subthz()
% threshold_sweep_subthz  Delay-threshold sensitivity sweep at sub-THz.
%
% Reruns the NYU 142 GHz and USC 145.5 GHz raw-processing pipelines while
% sweeping the delay-domain threshold constants, harvesting the per-link
% Results CSV for each setting into <repo>/figures/matlab/sweep/:
%
%   NYU noise-margin  N in {3,5,8,10,15,20} dB  (peak-margin fixed at 25)
%   NYU peak-margin   P in {15,20,30,35} dB     (noise-margin fixed at 5)
%   USC global margin M in {6,9,12,15,18,21} dB
%
% The institutional operating points (N=5/P=25 and M=12) reproduce the
% published per-link tables, anchoring the sweep to validated settings.
% Runtime ~25 min. Analysis: revision/analysis m11 (paper repo).

this_dir = fileparts(fileparts(mfilename('fullpath')));  % <repo>/matlab
addpath(fullfile(this_dir, 'config'));
addpath(fullfile(this_dir, 'lib'));
addpath(genpath(fullfile(this_dir, 'lib_tcsl')));
addpath(fullfile(this_dir, 'processing', 'nyu_142'));
addpath(fullfile(this_dir, 'processing', 'usc_145'));
addpath(fullfile(this_dir, 'patterns'));

P = paths();
sweep_dir = fullfile(P.out_dir, 'sweep');
if ~exist(sweep_dir, 'dir'), mkdir(sweep_dir); end

nyu_csv = fullfile(P.results_nyu_142, 'NYU142GHz_Method_Comparison_Results.csv');
usc_csv = fullfile(P.results_usc_145, 'USC145GHz_Full_Results.csv');

t_all = tic;

% ---- NYU noise-margin sweep ----
for N = [3 5 8 10 15 20]
    run_one('NYU142GHz_Method_Comparison', ...
        sprintf('{"thres_above_noise":%d}', N), nyu_csv, ...
        fullfile(sweep_dir, sprintf('nyu142_N%02d_P25.csv', N)));
end
% ---- NYU peak-margin sweep ----
for Pk = [15 20 30 35]
    run_one('NYU142GHz_Method_Comparison', ...
        sprintf('{"thres_below_pk":%d}', Pk), nyu_csv, ...
        fullfile(sweep_dir, sprintf('nyu142_N05_P%02d.csv', Pk)));
end
% ---- USC margin sweep ----
for M = [6 9 12 15 18 21]
    run_one('USC142GHz_Method_Comparison_Full', ...
        sprintf('{"noise_margin_dB":%d}', M), usc_csv, ...
        fullfile(sweep_dir, sprintf('usc145_M%02d.csv', M)));
end

setenv('THRESH_OVERRIDE', '');
fprintf('[sweep] all done in %.1f min\n', toc(t_all) / 60);

% Restore the canonical operating-point Results (rerun at defaults).
fprintf('[sweep] restoring operating-point Results...\n');
evalin('base', 'clear; NYU142GHz_Method_Comparison;');
evalin('base', 'clear; USC142GHz_Method_Comparison_Full;');
fprintf('[sweep] operating point restored.\n');
end

function run_one(script_name, ovr_json, src_csv, dst_csv)
if exist(dst_csv, 'file')
    fprintf('[sweep] SKIP (exists): %s\n', dst_csv);
    return
end
fprintf('[sweep] %s  <-  %s\n', script_name, ovr_json);
setenv('THRESH_OVERRIDE', ovr_json);
t0 = tic;
try
    evalin('base', sprintf('clear; %s;', script_name));
    copyfile(src_csv, dst_csv);
    fprintf('[sweep]   ok (%.1f min) -> %s\n', toc(t0) / 60, dst_csv);
catch ME
    fprintf(2, '[sweep]   FAILED: %s\n', ME.message);
end
setenv('THRESH_OVERRIDE', '');
end

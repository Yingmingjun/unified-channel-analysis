function ok = check_parity_before_update(min_tight_vi, min_tight_vii)
% check_parity_before_update  Guard against overwriting paper tables if parity has dropped.
%
%   ok = check_parity_before_update(min_tight_vi, min_tight_vii) reads
%   docs/paper_parity_matlab.md and returns true if the MATLAB-vs-Paper
%   TIGHT counts are at or above the given baselines. Use as a pre-step
%   before calling generate_supplement_tex / generate_tex_row_blocks so
%   you don't regenerate supplement/paper tables from regressed outputs.
%
%   Defaults: require Table VI >= 20 TIGHT, Table VII >= 71 TIGHT (the
%   current baseline as of 2026-04-17 with DS_DELAY_GATE_NS = 966.67).
%
%   Example
%     if check_parity_before_update
%         generate_supplement_tex
%     end

if nargin < 1 || isempty(min_tight_vi),  min_tight_vi  = 20; end
if nargin < 2 || isempty(min_tight_vii), min_tight_vii = 71; end

U = paths();
parity_file = fullfile(U.repo_root, 'docs', 'paper_parity_matlab.md');
if ~exist(parity_file, 'file')
    warning('paper_parity_matlab.md not found; run run_all(''figures'') first.');
    ok = false; return;
end
txt = fileread(parity_file);

vi_tight  = scan(txt, 'MATLAB vs Paper - Table VI:\s*(\d+)\s*TIGHT');
vii_tight = scan(txt, 'MATLAB vs Paper - Table VII:\s*(\d+)\s*TIGHT');

fprintf('Parity: Table VI TIGHT=%d (min %d)  Table VII TIGHT=%d (min %d)\n', ...
    vi_tight, min_tight_vi, vii_tight, min_tight_vii);

ok = (vi_tight >= min_tight_vi) && (vii_tight >= min_tight_vii);
if ~ok
    warning(['Parity dropped below baseline. Refusing to regenerate tex. ' ...
        'Investigate first or lower the baseline explicitly.']);
end
end

function v = scan(txt, pat)
m = regexp(txt, pat, 'tokens', 'once');
if isempty(m), v = -1; else, v = str2double(m{1}); end
end

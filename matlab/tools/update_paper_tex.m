function update_paper_tex(paper_tex, out_tex)
% update_paper_tex  Rewrite numeric cells of main_final.tex data rows in place.
%
%   update_paper_tex(paper_tex, out_tex) reads paper_tex (defaults to
%   D:\Joint-Point-Data-format-USC-NYU-Journal\main_final.tex), finds each
%   data row in the point-data tabulars, and overwrites the numeric
%   columns with values from our Processing CSVs. Non-numeric structure
%   (\multirow, \cline, \hline, \multicolumn, column specs) is preserved
%   verbatim.
%
%   Writes to out_tex (defaults to main_final_updated.tex alongside the
%   source). Diff that against the original before overwriting.
%
%   Tables handled (all keyed by \label{tab:X}):
%     tab:LSPs       (partial N1 @ 142 GHz rows)     <- table04_N1_142.csv
%     tab:U3_145     (partial U3 @ 145.5 GHz rows)   <- table08_U3_145.csv
%     tab:U3_7       (partial U3 @ 6.75 GHz rows)    <- table09_U3_7.csv
%     tab:N3_142     (partial N3 @ 142 GHz rows)     <- table10_N3_142.csv
%     tab:N3_7       (partial N3 @ 6.75 GHz rows)    <- table11_N3_7.csv
%     tab:RMSE_th    (Table VI)                      <- table06_rmse.csv
%
%   Rows are matched by (TX, RX, Loc) from the tex row against the CSV.
%   If no CSV row matches, the tex row is left unchanged and flagged.

U = paths();
csv_dir = U.out_dir;

if nargin < 1 || isempty(paper_tex)
    if ~isempty(U.paper_src_tex_path)
        paper_tex = U.paper_src_tex_path;
    else
        error('update_paper_tex: PAPER_TEX_PATH not set. Export PAPER_TREE_DIR or PAPER_TEX_PATH before calling, or pass paper_tex explicitly.');
    end
end
if nargin < 2 || isempty(out_tex)
    [d, n, ~] = fileparts(paper_tex);
    out_tex = fullfile(d, [n, '_updated.tex']);
end

% Load CSVs once
csvs = struct();
csvs.N1  = readtable(fullfile(csv_dir, 'table04_N1_142.csv'), 'PreserveVariableNames', true);
csvs.U3a = readtable(fullfile(csv_dir, 'table08_U3_145.csv'), 'PreserveVariableNames', true);
csvs.U3b = readtable(fullfile(csv_dir, 'table09_U3_7.csv'),   'PreserveVariableNames', true);
csvs.N3a = readtable(fullfile(csv_dir, 'table10_N3_142.csv'), 'PreserveVariableNames', true);
csvs.N3b = readtable(fullfile(csv_dir, 'table11_N3_7.csv'),   'PreserveVariableNames', true);
csvs.VI  = readtable(fullfile(csv_dir, 'table06_rmse.csv'),   'PreserveVariableNames', true);

% Mapping: label -> {csv handle in csvs struct, layout kind}
label_map = { ...
    'LSPs',    'N1',  'n1'      ; ...
    'U3_145',  'U3a', 'cross'   ; ...
    'U3_7',    'U3b', 'cross'   ; ...
    'N3_142',  'N3a', 'cross'   ; ...
    'N3_7',    'N3b', 'cross'   ; ...
    'RMSE_th', 'VI',  'rmse'    ; ...
};

txt = fileread(paper_tex);

touched_rows = 0; missed_rows = {};
for k = 1:size(label_map, 1)
    lbl = label_map{k, 1};
    T = csvs.(label_map{k, 2});
    kind = label_map{k, 3};
    [txt, nTouch, nMiss] = rewrite_one_table(txt, lbl, T, kind);
    fprintf('  tab:%s  -> %d rows rewritten, %d unmatched\n', lbl, nTouch, nMiss);
    touched_rows = touched_rows + nTouch;
    missed_rows{end+1} = struct('label', lbl, 'nMiss', nMiss); %#ok<AGROW>
end

fid = fopen(out_tex, 'w');
if fid == -1, error('Cannot open %s', out_tex); end
fwrite(fid, txt);
fclose(fid);
fprintf('update_paper_tex: %d rows rewritten. Wrote %s\n', touched_rows, out_tex);
fprintf('Diff suggestion:\n  diff %s %s\n', paper_tex, out_tex);
end

% ------------------------------------------------------------------ %
function [txt, nTouch, nMiss] = rewrite_one_table(txt, label, T, kind)
nTouch = 0; nMiss = 0;
pat_label = sprintf('\\label{tab:%s}', label);
pos_label = strfind(txt, pat_label);
if isempty(pos_label)
    fprintf('  [warn] label %s not found in paper -- skipped\n', label);
    return
end
% Locate the \begin{tabular} before label and \end{tabular} after
b_positions = strfind(txt, '\begin{tabular}');
e_positions = strfind(txt, '\end{tabular}');
bs = max(b_positions(b_positions < pos_label(1)));
es = min(e_positions(e_positions > pos_label(1)));
if isempty(bs) || isempty(es)
    fprintf('  [warn] could not locate tabular for %s\n', label);
    return
end
% Some tables have \label after \end{tabular} (like tab:LSPs which has
% \label AFTER \end{tabular}). Re-scan:
if bs > es
    bs = max(b_positions(b_positions < pos_label(1)));
    % In that layout, label is really after end, but tabular above it
    % is the right one. Fallback to the last \begin{tabular} before label.
end

block = txt(bs:es-1);

switch kind
    case 'rmse'
        [new_block, nTouch, nMiss] = rewrite_rmse(block, T);
    case 'n1'
        [new_block, nTouch, nMiss] = rewrite_per_link(block, T, 'n1');
    case 'cross'
        [new_block, nTouch, nMiss] = rewrite_per_link(block, T, 'cross');
end

txt = [txt(1:bs-1), new_block, txt(es:end)];
end

% ------------------------------------------------------------------ %
function [block, nTouch, nMiss] = rewrite_rmse(block, T)
% Table VI schema: row identified by "Sub-THz" / "6.75 GHz" + metric name.
% CSV columns: Band, Metric, USC_data_NYU_thres, USC_data_USC_thres,
%              NYU_data_USC_thres, NYU_data_NYU_thres
nTouch = 0; nMiss = 0;
lines = strsplit(block, newline);
for i = 1:numel(lines)
    L = lines{i};
    m = regexp(L, '(Sub-THz|6\.75\s*GHz)\s*&\s*(PL|DS|ASA|ASD)\b[^&]*', 'tokens', 'once');
    if isempty(m), continue; end
    band = m{1}; metric = m{2};
    row = T(strcmpi(T.Band, band) & contains(T.Metric, metric), :);
    if isempty(row), nMiss = nMiss + 1; continue; end
    % Reconstruct numeric tail of the row
    cols = [row.USC_data_NYU_thres, row.USC_data_USC_thres, ...
            row.NYU_data_USC_thres, row.NYU_data_NYU_thres];
    new_tail = sprintf('%.2f & %.2f & %.2f & %.2f', cols);
    % Replace the numeric tail: everything after the metric column's closing "&"
    L2 = regexprep(L, '(&\s*)[\d\-\.,\s&]+(\\\\?)\s*$', ['$1', new_tail, ' $2'], 'once');
    if ~strcmp(L, L2)
        lines{i} = L2; nTouch = nTouch + 1;
    end
end
block = strjoin(lines, newline);
end

% ------------------------------------------------------------------ %
function [block, nTouch, nMiss] = rewrite_per_link(block, T, kind)
% Match rows like "RX7 & LOS & 35.0 & <nums> & ... \\"
% and rewrite the numeric tail from the CSV row with matching (TX, RX, Loc).
nTouch = 0; nMiss = 0;
lines = strsplit(block, newline);

% Pre-extract CSV rows keyed by RX-LOC (TX not always present in tex rows
% because of \multirow). We fall back to matching on (RX + Loc Type).
vn = T.Properties.VariableNames;
% Build ff-TX column
tx_list = cellfun(@(v) ch(v), T.(vn{2}), 'UniformOutput', false);
tx_list = fillfwd(tx_list);

for i = 1:numel(lines)
    L = lines{i};
    % Row must have a RX\d+ and LOS/NLOS/OLOS
    m = regexp(L, 'RX(\d+)\s*&\s*(LOS|NLOS|OLOS)\s*&\s*([\d\.]+)\s*&', 'tokens', 'once');
    if isempty(m), continue; end
    rx_num = m{1}; loc = m{2};
    % Find matching CSV row
    rx_vals = cellfun(@(v) extract_num(ch(v)), T.(vn{3}));
    loc_vals = cellfun(@(v) upper(strtrim(ch(v))), T.(vn{4}), 'UniformOutput', false);
    idx = find(rx_vals == str2double(rx_num) & strcmp(loc_vals, loc));
    if isempty(idx), nMiss = nMiss + 1; continue; end
    csv_row = T(idx(1), :);
    % Extract values (col 6..end)
    vals = table2array(csv_row(:, 6:end));
    % Build numeric tail with 2 decimals for cross, 1 decimal for N1
    if strcmp(kind, 'n1')
        fmt = '%.1f';
    else
        fmt = '%.2f';
    end
    vs = strjoin(arrayfun(@(v) fmt_or_dash(v, fmt), vals, 'UniformOutput', false), ' & ');
    % Replace the numeric tail after the distance-column "&"
    % Pattern: up to and including "& <dist> &" is preamble; rest is numeric tail up to "\\"
    L2 = regexprep(L, ...
        '(RX\d+\s*&\s*(?:LOS|NLOS|OLOS)\s*&\s*[\d\.]+\s*&\s*)[^\\]*(\\\\?)', ...
        ['$1', vs, ' $2'], 'once');
    if ~strcmp(L, L2)
        lines{i} = L2; nTouch = nTouch + 1;
    end
end
block = strjoin(lines, newline);
end

% -------- helpers --------
function c = ch(v)
if iscell(v), c = char(v{1});
elseif isstring(v), c = char(v);
elseif isnumeric(v)
    if isnan(v), c = ''; else, c = sprintf('%g', v); end
else, c = char(v);
end
end

function n = extract_num(s)
m = regexp(s, '\d+', 'match', 'once');
if isempty(m), n = NaN; else, n = str2double(m); end
end

function out = fillfwd(c)
last = ''; out = c;
for i = 1:numel(c)
    s = c{i};
    if isempty(s) || all(isspace(s)), out{i} = last; else, out{i} = s; last = s; end
end
end

function s = fmt_or_dash(v, fmt)
if isnan(v), s = '--'; else, s = sprintf(fmt, v); end
end

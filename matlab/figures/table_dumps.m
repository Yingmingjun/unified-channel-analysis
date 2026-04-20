function table_dumps()
% table_dumps  Regenerate paper Tables 4, 8, 9, 10, 11 as CSV dumps.
%
%   Each paper table is a pretty-print of one of the xlsx point-data files;
%   we dump them as CSV so readers can diff against the paper.
%
%       Table 4  : N1_142_UMi.xlsx   (single-row-header PL listing)
%       Table 8  : U3_142_UMi.xlsx   (two-row-header cross table @ 145.5 GHz)
%       Table 9  : U3_7_UMi.xlsx     (two-row-header @ 6.75 GHz)
%       Table 10 : N3_142_UMi.xlsx   (two-row-header @ 142 GHz)
%       Table 11 : N3_7_UMi.xlsx     (two-row-header @ 6.75 GHz)
%
%   Output: figures/matlab/table{04,08,09,10,11}_*.csv
%
% Mirrors python/src/channel_analysis/figures/table_dumps.py

plot_style();
P = paths();
if ~exist(P.out_dir, 'dir'), mkdir(P.out_dir); end

root = fileparts(P.n3_142_xlsx);

pairs = { ...
    'table04_N1_142.csv', fullfile(root, 'N1_142_UMi.xlsx'), 'single'; ...
    'table05_N1_7.csv',   fullfile(root, 'N1_7_UMi.xlsx'),   'single'; ...
    'table08_U3_145.csv', fullfile(root, 'U3_142_UMi.xlsx'), 'two_row'; ...
    'table09_U3_7.csv',   fullfile(root, 'U3_7_UMi.xlsx'),   'two_row'; ...
    'table10_N3_142.csv', fullfile(root, 'N3_142_UMi.xlsx'), 'two_row'; ...
    'table11_N3_7.csv',   fullfile(root, 'N3_7_UMi.xlsx'),   'two_row'  ...
};

for k = 1:size(pairs, 1)
    name = pairs{k, 1};
    src  = pairs{k, 2};
    kind = pairs{k, 3};
    if ~isfile(src)
        fprintf('[table_dumps] skip %s (missing)\n', src);
        continue
    end
    if strcmp(kind, 'single')
        df = readtable(src, 'Sheet', 'FinalTable', ...
                       'VariableNamingRule', 'preserve');
    else
        df = dump_two_row_header(src, 'FinalTable');
    end
    out_path = fullfile(P.out_dir, name);
    writetable(df, out_path);
    fprintf('[table_dumps] wrote %s\n', out_path);
end
end


% ===========================================================================
function T = dump_two_row_header(xlsx_path, sheet)
% Flatten a two-row-header xlsx into a single-header MATLAB table with
% column names "<section>__<metric>" (matches python table_dumps output).

cells = readcell(char(xlsx_path), 'Sheet', char(sheet));

metric_row = forward_fill_row(cells(2, :));   % metric groups (merged)
sec_row    = cells(3, :);                     % thresholds / sub-sections

metric_row = cellfun(@cell_to_string, metric_row, 'UniformOutput', false);
sec_row    = cellfun(@cell_to_string, sec_row,    'UniformOutput', false);
metric_row = string(metric_row);
sec_row    = string(sec_row);

data_rows = cells(4:end, :);
n_cols = size(data_rows, 2);

% Build flat column names.
col_names = strings(1, n_cols);
for c = 1:n_cols
    if strlength(sec_row(c)) == 0
        col_names(c) = metric_row(c);
    else
        col_names(c) = metric_row(c) + "__" + sec_row(c);
    end
    if strlength(col_names(c)) == 0
        col_names(c) = sprintf('Col%03d', c);
    end
end
col_names = matlab.lang.makeUniqueStrings( ...
    matlab.lang.makeValidName(col_names));

% Build table columns as mixed numeric / string.
T_cols = cell(1, n_cols);
for c = 1:n_cols
    col_cells = data_rows(:, c);
    numeric_attempt = nan(numel(col_cells), 1);
    all_numeric = true;
    for r = 1:numel(col_cells)
        v = col_cells{r};
        if ismissing(v)
            % leave NaN
        elseif isnumeric(v) && isscalar(v)
            numeric_attempt(r) = v;
        elseif ischar(v) || isstring(v)
            d = str2double(v);
            if isnan(d), all_numeric = false; break
            else, numeric_attempt(r) = d;
            end
        else
            all_numeric = false; break
        end
    end
    if all_numeric
        T_cols{c} = numeric_attempt;
    else
        % Fall back to strings.
        s = strings(numel(col_cells), 1);
        for r = 1:numel(col_cells)
            s(r) = cell_to_string(col_cells{r});
        end
        T_cols{c} = s;
    end
end

T = table(T_cols{:}, 'VariableNames', cellstr(col_names));

% Drop fully-empty rows (all NaN or empty) so the CSV matches python output.
is_data_row = false(height(T), 1);
for r = 1:height(T)
    for c = 1:width(T)
        v = T{r, c};
        if isnumeric(v)
            if any(isfinite(v)), is_data_row(r) = true; break, end
        else
            if strlength(string(v)) > 0, is_data_row(r) = true; break, end
        end
    end
end
T = T(is_data_row, :);
end


function row = forward_fill_row(row)
current = '';
for k = 1:numel(row)
    v = cell_to_string(row{k});
    if strlength(v) == 0
        row{k} = current;
    else
        current = char(v);
        row{k}  = current;
    end
end
end


function s = cell_to_string(v)
if ismissing(v)
    s = ""; return
end
if isnumeric(v)
    if isnan(v), s = ""; else, s = string(v); end
    return
end
s = strtrim(string(v));
end

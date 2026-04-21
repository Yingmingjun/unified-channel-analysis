function table06_rmse()
% table06_rmse  Cross-processing RMSE of PL / DS / ASA / ASD (paper Table VI).
%
%   For each (metric x band), report RMSE between paired native and cross-
%   processed estimates under the two delay-domain thresholds:
%
%       USC data (U3) under NYU thres  :  RMSE(U3_nyu_thr, U1_orig)
%       USC data (U3) under USC thres  :  RMSE(U3_usc_thr, U1_orig)
%       NYU data (N3) under USC thres  :  RMSE(N3_usc_thr, N1_orig)
%       NYU data (N3) under NYU thres  :  RMSE(N3_nyu_thr, N1_orig)
%
%   Loaded directly from the two-row-header xlsx tables (NOT through the
%   main hybrid loader), because the three threshold variants ('nyu_thr',
%   'usc_thr', 'orig') share a single xlsx and need per-variant columns.
%   USC keys include loc_type because R1..R13 repeat across LOS and NLOS.
%
%   Output: figures/matlab/table06_rmse.csv
%
% Mirrors python/src/channel_analysis/figures/table06_rmse.py

plot_style();
P = paths();
if ~exist(P.out_dir, 'dir'), mkdir(P.out_dir); end
root = fileparts(P.n3_142_xlsx);   % DATA_ROOT

% (band_label, N3 xlsx filename, U3 xlsx filename)
bands = { 'Sub-THz',  'N3_142_UMi.xlsx', 'U3_142_UMi.xlsx'; ...
          '6.75 GHz', 'N3_7_UMi.xlsx',   'U3_7_UMi.xlsx' };

metric_keys   = {'pl', 'ds', 'asa', 'asd'};
metric_labels = {'PL [dB]', 'DS [ns]', 'ASA [deg]', 'ASD [deg]'};

rows = {};

for ib = 1:size(bands, 1)
    band_label = bands{ib, 1};
    n3 = load_variants(fullfile(root, bands{ib, 2}), 'NYU orig');
    u3 = load_variants(fullfile(root, bands{ib, 3}), 'USC orig');
    for im = 1:numel(metric_keys)
        m     = metric_keys{im};
        mlabl = metric_labels{im};
        rows(end+1, :) = { ...
            band_label, mlabl, ...
            compare_pair(u3.nyu_thr, u3.orig, m), ...
            compare_pair(u3.usc_thr, u3.orig, m), ...
            compare_pair(n3.usc_thr, n3.orig, m), ...
            compare_pair(n3.nyu_thr, n3.orig, m) ... %#ok<AGROW>
        };
    end
end

var_names = {'Band','Metric', ...
             'USC_data_NYU_thres','USC_data_USC_thres', ...
             'NYU_data_USC_thres','NYU_data_NYU_thres'};
tbl = cell2table(rows, 'VariableNames', var_names);
csv_path = fullfile(P.out_dir, 'table06_rmse.csv');
writetable(tbl, csv_path);
fprintf('[table06] wrote %s\n', csv_path);
end


% ===========================================================================
function V = load_variants(xlsx_path, orig_label)
% Read FinalTable sheet with two-row header and return a struct of three
% tables keyed by 'nyu_thr', 'usc_thr', 'orig'. Each table holds:
%   key, pl, ds, asa, asd  (key = "T<i>-R<j>|LOC" for USC uniqueness).
%
% Mirrors python/src/channel_analysis/figures/table06_rmse.py _load_variants.

raw = read_two_row_header(xlsx_path, 'FinalTable');

tx_col  = find_col(raw, 'TX',       '');
rx_col  = find_col(raw, 'RX',       '');
loc_col = find_col(raw, 'Loc Type', '');
tr_col  = find_col(raw, 'TR Sep',   '');

tx_vals = ffill_strings(raw{:, tx_col});
tr_vals = to_numeric(raw{:, tr_col});
keep    = ~isnan(tr_vals);

tx_norm = regexprep(string(tx_vals(keep)), '^TX', 'T');
rx_norm = regexprep(string(raw{keep, rx_col}), '^RX', 'R');
loc_raw = upper(strtrim(string(raw{keep, loc_col})));
key = tx_norm + "-" + rx_norm + "|" + loc_raw;

% Three variants; match section substring in the two-row-header.
variants = {'nyu_thr', 'NYU thres'; ...
            'usc_thr', 'USC thres'; ...
            'orig',     orig_label};
metrics  = {'pl', 'Omni PL'; 'ds', 'Omni DS'; ...
            'asa', 'Omni ASA'; 'asd', 'Omni ASD'};

V = struct();
for iv = 1:size(variants, 1)
    tag = variants{iv, 1};
    sec = variants{iv, 2};
    frame = table();
    frame.key = key;
    for im = 1:size(metrics, 1)
        mshort = metrics{im, 1};
        mfull  = metrics{im, 2};
        c = find_col(raw, mfull, sec);
        if isempty(c)
            frame.(mshort) = nan(numel(key), 1);
        else
            vv = to_numeric(raw{:, c});
            frame.(mshort) = vv(keep);
        end
    end
    V.(tag) = frame;
end
end


function r = compare_pair(left, right, metric)
% RMSE between paired (TX-RX|loc) rows, with a 50x-median clip that guards
% against cross-processing pipeline outliers. (The specific 714 deg ASA
% value previously at N3_142 TX4-RX37 col M was fixed in the xlsx in
% 2026-04-20; guard retained as general defense against future artifacts.)
% Mirrors python table06_rmse._compare_pair / _rmse.

% Inner join on key
[~, ia, ib] = intersect(left.key, right.key, 'stable');
a = left.(metric)(ia);
b = right.(metric)(ib);
m = isfinite(a) & isfinite(b);
if ~any(m)
    r = NaN; return
end
diff = abs(a - b);
med_d = median(diff(m));
outlier = diff > max(med_d * 50.0, 100.0);
keep = m & ~outlier;
r = sqrt(mean((a(keep) - b(keep)) .^ 2));
end


% ===========================================================================
% Shared xlsx helpers (duplicated from lib/load_point_data.m to keep this
% file self-contained; the main loader keeps its own private copies).
% ===========================================================================
function raw = read_two_row_header(xlsx_path, sheet)
cells = readcell(char(xlsx_path), 'Sheet', char(sheet));
metric_row = forward_fill_row(cells(2, :));
sec_row    = cells(3, :);
sec_row    = cellfun(@cell_to_string, sec_row,    'UniformOutput', false);
metric_row = cellfun(@cell_to_string, metric_row, 'UniformOutput', false);
sec_row    = string(sec_row);
metric_row = string(metric_row);

data_rows = cells(4:end, :);
n_cols = size(data_rows, 2);
T_cols = cell(1, n_cols);
var_names = strings(1, n_cols);
var_descs = strings(1, n_cols);
for c = 1:n_cols
    T_cols{c} = data_rows(:, c);
    var_names(c) = sprintf('Col%03d', c);
    var_descs(c) = sec_row(c) + "||" + metric_row(c);
end
raw = table(T_cols{:}, 'VariableNames', cellstr(var_names));
raw.Properties.VariableDescriptions = cellstr(var_descs);
end


function col_name = find_col(raw, metric_substr, section_substr)
descs = string(raw.Properties.VariableDescriptions);
col_name = '';
for i = 1:numel(descs)
    parts = split(descs(i), "||");
    if numel(parts) < 2, continue, end
    sec = lower(parts(1));
    met = lower(parts(2));
    metric_ok = contains(met, lower(metric_substr));
    if isempty(section_substr)
        section_ok = true;
    else
        section_ok = contains(sec, lower(section_substr));
    end
    if metric_ok && section_ok
        col_name = raw.Properties.VariableNames{i};
        return
    end
end
end


function y = to_numeric(x)
if iscell(x)
    y = nan(size(x));
    for k = 1:numel(x)
        v = x{k};
        if isnumeric(v) && isscalar(v)
            y(k) = v;
        elseif ischar(v) || isstring(v)
            y(k) = str2double(v);
        end
    end
else
    y = double(x);
end
end


function s = ffill_strings(x)
s = string(x);
current = "";
for k = 1:numel(s)
    if ismissing(s(k)) || strlength(strtrim(s(k))) == 0
        s(k) = current;
    else
        current = s(k);
    end
end
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

function T = load_point_data(variants)
% load_point_data  Load canonical per-variant point-data tables.
%
%   T = load_point_data(variants) reads the requested variants from the
%   xlsx tables listed in config/paths.m and returns a single MATLAB table
%   with columns matching the Python canonical schema:
%
%       institution, band, freq_ghz, tx, rx, loc_type, loc_type_raw,
%       d_m, pl_db, omni_ds_ns, omni_asa_d, omni_asd_d, variant
%
%   variants : cell array of strings, subset of {'N1','U1','N3','U3'}.
%
%   The N3/U3 xlsx files use a two-row header structure
%       row 1 : section (e.g. "NYU orig.", "USC thres ...")
%       row 2 : metric  (e.g. "Omni PL", "Omni DS", "Omni ASA", "Omni ASD")
%   plus a top label row; we use detectImportOptions with VariableNamesRange
%   pointing at row 2 and VariableDescriptionsRange pointing at row 1 so that
%   each column is uniquely identified by the pair (section, metric).
%
%   OLOS -> NLOS relabeling: loc_type is the harmonized label, while
%   loc_type_raw preserves the original category.

% Mirrors python/src/channel_analysis/io.py load_point_data

if nargin < 1 || isempty(variants)
    variants = {'N1', 'U1'};
end
if ischar(variants) || isstring(variants)
    variants = cellstr(variants);
end
want = upper(string(variants));

P = paths();
frames = {};

if any(want == "N1")
    % Authoritative N1 values live in the "NYU orig." column of the N3 xlsx.
    frames{end+1} = load_orig_from_cross(P.n3_142_xlsx, 142.0, 'NYU');
    frames{end+1} = load_orig_from_cross(P.n3_7_xlsx,     6.75, 'NYU');
end

if any(want == "U1")
    % Authoritative U1 values live in the "USC orig." column of the U3 xlsx.
    frames{end+1} = load_orig_from_cross(P.u3_142_xlsx, 145.5, 'USC');
    frames{end+1} = load_orig_from_cross(P.u3_7_xlsx,     6.75, 'USC');
end

if any(want == "N3")
    frames{end+1} = load_cross_xlsx(P.n3_142_xlsx, 142.0, 'N3');
    frames{end+1} = load_cross_xlsx(P.n3_7_xlsx,     6.75, 'N3');
end

if any(want == "U3")
    frames{end+1} = load_cross_xlsx(P.u3_142_xlsx, 145.5, 'U3');
    frames{end+1} = load_cross_xlsx(P.u3_7_xlsx,     6.75, 'U3');
end

if isempty(frames)
    T = empty_schema();
    return;
end

T = vertcat(frames{:});

% -- OLOS -> NLOS relabeling (loc_type harmonized, loc_type_raw preserved) ---
T.loc_type = T.loc_type_raw;
T.loc_type(T.loc_type == "OLOS") = "NLOS";
end


% ============================================================================
% Local helpers
% ============================================================================
function T = load_orig_from_cross(xlsx_path, freq_ghz, inst)
% Load the "<inst> orig." column block of a two-row-header cross xlsx.
% inst is either 'NYU' (yields variant 'N1') or 'USC' (yields variant 'U1').
%
% See python io._load_n1_from_n3_orig and _load_u1_from_u3_orig.

raw = read_two_row_header(xlsx_path, 'FinalTable');
institution = inst;
variant_tag = ternary(strcmp(inst, 'NYU'), 'N1', 'U1');
section_key = [inst ' orig'];   % matches "NYU orig." / "USC orig."

T = assemble_rows(raw, freq_ghz, institution, variant_tag, section_key);
end


function T = load_cross_xlsx(xlsx_path, freq_ghz, kind)
% Load the two thresholded variant blocks ("<inst> thres ...") of a cross
% xlsx and concatenate them with variant tags '<kind>_nyu_thr' / '<kind>_usc_thr'.
%
% See python io._load_cross_xlsx.

raw = read_two_row_header(xlsx_path, 'FinalTable');
kind = upper(kind);
if strcmp(kind, 'N3')
    institution = 'NYU';
else
    institution = 'USC';
end

frames = {};
suffix_map = {'nyu_thr', 'NYU thres'; 'usc_thr', 'USC thres'};
for k = 1:size(suffix_map, 1)
    suffix_tag = suffix_map{k, 1};
    section_key = suffix_map{k, 2};
    variant_tag = sprintf('%s_%s', kind, suffix_tag);
    try
        frames{end+1} = assemble_rows(raw, freq_ghz, institution, variant_tag, section_key); %#ok<AGROW>
    catch
        % Some xlsx files contain only one of the two threshold blocks.
        continue
    end
end
T = vertcat(frames{:});
end


function T = assemble_rows(raw, freq_ghz, institution, variant_tag, section_key)
% Pull the canonical columns out of a raw two-row-header table and build a
% tall MATLAB table in the canonical schema.

tx_col  = find_col(raw, 'TX',       '');
rx_col  = find_col(raw, 'RX',       '');
loc_col = find_col(raw, 'Loc Type', '');
tr_col  = find_col(raw, 'TR Sep',   '');

pl_col  = find_col(raw, 'Omni PL',  section_key);
ds_col  = find_col(raw, 'Omni DS',  section_key);
asa_col = find_col(raw, 'Omni ASA', section_key);
asd_col = find_col(raw, 'Omni ASD', section_key);

if isempty(pl_col)
    error('assemble_rows:missingSection', 'Section "%s" not found', section_key);
end

% Forward-fill TX (merged cells look like NaN in subsequent rows).
tx_vals = ffill_strings(raw{:, tx_col});

% Keep rows with numeric TR-Sep.
d_raw = to_numeric(raw{:, tr_col});
keep  = ~isnan(d_raw);

rx_vals  = string(raw{:, rx_col});
loc_raw  = upper(strtrim(string(raw{:, loc_col})));

pl_vals  = to_numeric(raw{:, pl_col});
ds_vals  = to_numeric(raw{:, ds_col});
asa_vals = to_numeric(raw{:, asa_col});
asd_vals = to_numeric(raw{:, asd_col});

if freq_ghz >= 100
    band = "subTHz";
else
    band = "FR1C";
end

n = sum(keep);
T = table( ...
    repmat(string(institution), n, 1), ...
    repmat(band,                 n, 1), ...
    repmat(freq_ghz,             n, 1), ...
    tx_vals(keep),                     ...
    rx_vals(keep),                     ...
    strings(n, 1),                     ...   % loc_type placeholder; filled outside
    loc_raw(keep),                     ...
    d_raw(keep),                       ...
    pl_vals(keep),                     ...
    ds_vals(keep),                     ...
    asa_vals(keep),                    ...
    asd_vals(keep),                    ...
    repmat(string(variant_tag),   n, 1), ...
    'VariableNames', {'institution','band','freq_ghz','tx','rx', ...
                      'loc_type','loc_type_raw','d_m','pl_db', ...
                      'omni_ds_ns','omni_asa_d','omni_asd_d','variant'});
end


function raw = read_two_row_header(xlsx_path, sheet)
% Read an xlsx that has (top label row) + (section row) + (metric row) + data.
%
% Strategy: read the whole sheet as a cell array, use row 2 as the "section"
% label and row 3 as the "metric" label. Data begins at row 4. Column
% identity is (section, metric). Some columns have only a single label;
% the unused level is filled with an empty string.

% readcell is the modern replacement for xlsread; it preserves mixed
% numeric/text cells and correctly reports merged-cell content in the
% top-left anchor (the rest of a merged range reads as <missing>).
cells = readcell(char(xlsx_path), 'Sheet', char(sheet));

% Section row = row 2 (forward fill), Metric row = row 3.
sec_row    = forward_fill_row(cells(2, :));
metric_row = cells(3, :);

% Normalize to string arrays.
sec_row    = cellfun(@cell_to_string, sec_row,    'UniformOutput', false);
metric_row = cellfun(@cell_to_string, metric_row, 'UniformOutput', false);
sec_row    = string(sec_row);
metric_row = string(metric_row);

% Data is rows 4:end. Wrap into a table with two attributes per column:
%   VariableNames       -> unique sanitized metric+section name
%   VariableDescriptions-> section|metric original labels (for find_col)
data_rows = cells(4:end, :);
n_cols    = size(data_rows, 2);
T_cols    = cell(1, n_cols);
var_names = strings(1, n_cols);
var_descs = strings(1, n_cols);
for c = 1:n_cols
    col_cells = data_rows(:, c);
    T_cols{c} = col_cells;
    var_names(c) = sprintf('Col%03d', c);
    var_descs(c) = sec_row(c) + "||" + metric_row(c);
end
raw = table(T_cols{:}, 'VariableNames', cellstr(var_names));
raw.Properties.VariableDescriptions = cellstr(var_descs);
end


function col_name = find_col(raw, metric_substr, section_substr)
% Locate the column whose metric (second header level) contains
% metric_substr AND whose section (first header level) contains
% section_substr. Matching is case-insensitive. If section_substr is empty,
% only the metric is checked. Returns '' if no column matches.

descs = string(raw.Properties.VariableDescriptions);
col_name = '';
for i = 1:numel(descs)
    parts = split(descs(i), "||");
    if numel(parts) < 2
        continue
    end
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
% Coerce a cell/array to double, mapping non-numeric entries to NaN.
if iscell(x)
    y = nan(size(x));
    for k = 1:numel(x)
        v = x{k};
        if isnumeric(v) && isscalar(v)
            y(k) = v;
        elseif ischar(v) || isstring(v)
            d = str2double(v);
            y(k) = d;  % str2double returns NaN on failure
        end
    end
else
    y = double(x);
end
end


function s = ffill_strings(x)
% Forward-fill a column of strings (used to populate merged TX cells).
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
% Forward-fill a row cell array (for merged section headers).
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
% Convert a scalar cell value (which may be missing / NaN / numeric / text)
% to a trimmed MATLAB string.
if ismissing(v)
    s = "";
    return
end
if isnumeric(v)
    if isnan(v)
        s = "";
    else
        s = string(v);
    end
    return
end
s = strtrim(string(v));
end


function out = ternary(cond, a, b)
if cond
    out = a;
else
    out = b;
end
end


function T = empty_schema()
% Return an empty table with the canonical schema (used when no variants
% are requested).
T = table('Size', [0 13], ...
    'VariableTypes', {'string','string','double','string','string','string', ...
                      'string','double','double','double','double','double','string'}, ...
    'VariableNames', {'institution','band','freq_ghz','tx','rx', ...
                      'loc_type','loc_type_raw','d_m','pl_db', ...
                      'omni_ds_ns','omni_asa_d','omni_asd_d','variant'});
end

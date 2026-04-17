function T = load_point_data()
% load_point_data  Hybrid loader mirroring python/src/channel_analysis/io.py.
%
%   T = load_point_data() returns a single MATLAB table holding one row per
%   (institution, band, TX-RX link) with the canonical schema:
%
%       institution, band, freq_ghz, tx_rx_id, d_m, loc_type, loc_type_raw,
%       pl_db, omni_ds_ns,
%       pl_nyu_sum, pl_usc_pdm, ds_nyu_method, ds_usc_method,
%       asa_nyu_10, asa_nyu_15, asa_nyu_20, asa_usc,
%       asd_nyu_10, asd_nyu_15, asd_nyu_20, asd_usc
%
%   Loads ASA / ASD from the per-TX-RX result CSVs (these are the paper's
%   authoritative angular-spread tables):
%
%       NYU142GHz_Method_Comparison_Results.csv   (27 rows: 16 LOS + 11 NLOS)
%       NYU7GHz_Method_Comparison_Results.csv     (18 rows:  6 LOS + 12 NLOS)
%       USC145GHz_Full_Results.csv                (26 rows: 13 LOS + 13 NLOS)
%       USC7GHz_NewData_Results.csv               (17 rows:  6 LOS + 11 NLOS,
%                                                  OLOS->NLOS already applied)
%
%   Loads PL and DS from the two-row-header xlsx point-data tables
%   ("NYU orig. (N1)" / "USC orig. (U1)" columns -> the thresholded values
%   that match paper Table 7):
%
%       N3_142_UMi.xlsx / N3_7_UMi.xlsx   (NYU data)
%       U3_142_UMi.xlsx / U3_7_UMi.xlsx   (USC data)
%
%   Merge strategy:
%       * NYU: join by normalized tx_rx_id ('T1-R1' form).
%       * USC: xlsx RX labels (R1..R13) repeat across LOS and NLOS, so the
%         join key is (tx_rx_id_normalized | loc_type).
%
%   Finally applies OLOS -> NLOS relabeling in loc_type while preserving the
%   original label in loc_type_raw.

% Mirrors python/src/channel_analysis/io.py load_point_data

P = paths();
root = fileparts(P.n3_142_xlsx);   % DATA_ROOT

% -- Authoritative AS CSVs --------------------------------------------------
% One frame per file; each frame carries: institution, band, freq_ghz,
% tx_rx_id, d_m (if present in CSV), loc_type_raw and all AS/PL/DS columns.
frames = {};
frames{end+1} = load_as_nyu_142(fullfile(root, 'NYU142GHz_Method_Comparison_Results.csv')); %#ok<*AGROW>
frames{end+1} = load_as_nyu_7  (fullfile(root, 'NYU7GHz_Method_Comparison_Results.csv'));
frames{end+1} = load_as_usc    (fullfile(root, 'USC145GHz_Full_Results.csv'),       145.5);
frames{end+1} = load_as_usc    (fullfile(root, 'USC7GHz_NewData_Results.csv'),       6.75);
df = vertcat(frames{:});

% -- Attach xlsx "orig" PL/DS for each (institution, band) -------------------
% NYU xlsx uses TX/RX labels that match the CSV's TX_RX_ID (e.g. "T1-R1");
% merge by key. USC xlsx uses its own RX labels that repeat across LOS/NLOS,
% so we include loc_type in the key.
nyu_142 = attach_xlsx_pl_ds(df(df.institution == "NYU" & df.band == "subTHz", :), ...
                            fullfile(root, 'N3_142_UMi.xlsx'), 'NYU orig', 'key');
nyu_7   = attach_xlsx_pl_ds(df(df.institution == "NYU" & df.band == "FR1C",   :), ...
                            fullfile(root, 'N3_7_UMi.xlsx'),   'NYU orig', 'key');
usc_145 = attach_xlsx_pl_ds(df(df.institution == "USC" & df.band == "subTHz", :), ...
                            fullfile(root, 'U3_142_UMi.xlsx'), 'USC orig', 'position');
usc_7   = attach_xlsx_pl_ds(df(df.institution == "USC" & df.band == "FR1C",   :), ...
                            fullfile(root, 'U3_7_UMi.xlsx'),   'USC orig', 'position');

df = vertcat(nyu_142, nyu_7, usc_145, usc_7);

% -- pl_db / omni_ds_ns : prefer xlsx orig, fallback to per-method CSV ------
% (Python io.py lines 266-281: "prefer the xlsx 'orig' values; fall back to
% native per-institution method values from the CSV".)
df.pl_db      = df.pl_orig;
df.omni_ds_ns = df.ds_orig;
miss_pl = isnan(df.pl_db);
native_pl = df.pl_nyu_sum;
native_pl(df.institution == "USC") = df.pl_usc_pdm(df.institution == "USC");
df.pl_db(miss_pl) = native_pl(miss_pl);

miss_ds = isnan(df.omni_ds_ns);
native_ds = df.ds_nyu_method;
native_ds(df.institution == "USC") = df.ds_usc_method(df.institution == "USC");
df.omni_ds_ns(miss_ds) = native_ds(miss_ds);

% -- Distance: prefer CSV value (USC + NYU 7 GHz), fall back to xlsx (NYU 142)
miss_d = isnan(df.d_m);
df.d_m(miss_d) = df.d_m_xlsx(miss_d);

% -- OLOS -> NLOS relabel (USC 6.75 GHz has OLOS in loc_type_raw) -----------
df.loc_type = df.loc_type_raw;
df.loc_type(df.loc_type_raw == "OLOS") = "NLOS";

% -- Keep canonical schema, drop aux columns -------------------------------
keep = {'institution','band','freq_ghz','tx_rx_id','d_m', ...
        'loc_type','loc_type_raw', ...
        'pl_db','omni_ds_ns', ...
        'pl_nyu_sum','pl_usc_pdm','ds_nyu_method','ds_usc_method', ...
        'asa_nyu_10','asa_nyu_15','asa_nyu_20','asa_usc', ...
        'asd_nyu_10','asd_nyu_15','asd_nyu_20','asd_usc'};
T = df(:, keep);
end


% ===========================================================================
% AS CSV loaders — one frame per (institution, band)
% ===========================================================================
function T = load_as_nyu_142(csv_path)
% Mirrors python/src/channel_analysis/io.py _load_as_nyu_142
c = readtable(csv_path, 'VariableNamingRule', 'preserve');
n = height(c);
T = table();
T.institution   = repmat("NYU", n, 1);
T.band          = repmat("subTHz", n, 1);
T.freq_ghz      = repmat(142.0, n, 1);
T.tx_rx_id      = string(c.TX_RX_ID);
T.d_m           = nan(n, 1);        % NYU 142 CSV has no distance column;
                                    % filled from xlsx TR-Sep later.
T.loc_type_raw  = upper(strtrim(string(c.Environment)));
T.pl_nyu_sum    = double(c.PL_NYU_SUM_dB);
T.pl_usc_pdm    = double(c.PL_USC_perDelayMax_dB);
T.ds_nyu_method = double(c.DS_NYU_SUM_ns);
T.ds_usc_method = double(c.DS_USC_perDelayMax_ns);
T.asa_nyu_10    = double(c.ASA_NYU_10dB);
T.asa_nyu_15    = double(c.ASA_NYU_15dB);
T.asa_nyu_20    = double(c.ASA_NYU_20dB);
T.asa_usc       = double(c.ASA_USC);
T.asd_nyu_10    = double(c.ASD_NYU_10dB);
T.asd_nyu_15    = double(c.ASD_NYU_15dB);
T.asd_nyu_20    = double(c.ASD_NYU_20dB);
T.asd_usc       = double(c.ASD_USC);
end


function T = load_as_nyu_7(csv_path)
% Mirrors python/src/channel_analysis/io.py _load_as_nyu_7
c = readtable(csv_path, 'VariableNamingRule', 'preserve');
n = height(c);
T = table();
T.institution   = repmat("NYU", n, 1);
T.band          = repmat("FR1C", n, 1);
T.freq_ghz      = repmat(6.75,  n, 1);
T.tx_rx_id      = string(c.TX_RX_ID);
T.d_m           = double(c.Distance_m);
T.loc_type_raw  = upper(strtrim(string(c.Environment)));
T.pl_nyu_sum    = double(c.NYUthr_PL_SUM_dB);
T.pl_usc_pdm    = double(c.NYUthr_PL_pDM_dB);
T.ds_nyu_method = double(c.NYUthr_DS_SUM_ns);
T.ds_usc_method = double(c.NYUthr_DS_pDM_ns);
T.asa_nyu_10    = double(c.NYUthr_ASA_N10);
T.asa_nyu_15    = double(c.NYUthr_ASA_N15);
T.asa_nyu_20    = double(c.NYUthr_ASA_N20);
T.asa_usc       = double(c.NYUthr_ASA_U);
T.asd_nyu_10    = double(c.NYUthr_ASD_N10);
T.asd_nyu_15    = double(c.NYUthr_ASD_N15);
T.asd_nyu_20    = double(c.NYUthr_ASD_N20);
T.asd_usc       = double(c.NYUthr_ASD_U);
end


function T = load_as_usc(csv_path, freq_ghz)
% Mirrors python/src/channel_analysis/io.py _load_as_usc
c = readtable(csv_path, 'VariableNamingRule', 'preserve');
n = height(c);
if freq_ghz >= 100
    band = "subTHz";
else
    band = "FR1C";
end
T = table();
T.institution   = repmat("USC",    n, 1);
T.band          = repmat(band,     n, 1);
T.freq_ghz      = repmat(freq_ghz, n, 1);
T.tx_rx_id      = string(c.Location);
T.d_m           = double(c.Distance_m);
T.loc_type_raw  = upper(strtrim(string(c.Env)));
T.pl_nyu_sum    = double(c.PL_NYU_dB);
T.pl_usc_pdm    = double(c.PL_USC_dB);
T.ds_nyu_method = double(c.DS_NYU_ns);
T.ds_usc_method = double(c.DS_USC_ns);
T.asa_nyu_10    = double(c.ASA_NYU_10dB);
T.asa_nyu_15    = double(c.ASA_NYU_15dB);
T.asa_nyu_20    = double(c.ASA_NYU_20dB);
T.asa_usc       = double(c.ASA_USC);
T.asd_nyu_10    = double(c.ASD_NYU_10dB);
T.asd_nyu_15    = double(c.ASD_NYU_15dB);
T.asd_nyu_20    = double(c.ASD_NYU_20dB);
T.asd_usc       = double(c.ASD_USC);
end


% ===========================================================================
% Xlsx "<inst> orig" loader and join
% ===========================================================================
function aux = xlsx_orig_cols(xlsx_path, pick_orig)
% Read the xlsx FinalTable sheet (two-row header: row 2 = metric, row 3 =
% threshold/section). Return a table of aux columns keyed by (tx, rx,
% loc_type_raw). Mirrors python io._xlsx_orig_cols.

raw = read_two_row_header(xlsx_path, 'FinalTable');

tx_col  = find_col(raw, 'TX',       '');
rx_col  = find_col(raw, 'RX',       '');
loc_col = find_col(raw, 'Loc Type', '');
tr_col  = find_col(raw, 'TR Sep',   '');
pl_col  = find_col(raw, 'Omni PL',  pick_orig);
ds_col  = find_col(raw, 'Omni DS',  pick_orig);

% Forward-fill TX (merged cells appear as missing in later rows).
tx_vals = ffill_strings(raw{:, tx_col});
tr_vals = to_numeric(raw{:, tr_col});
keep_mask = ~isnan(tr_vals);

aux = table();
aux.tx           = regexprep(string(tx_vals(keep_mask)), '^TX', 'T');
aux.rx           = regexprep(string(raw{keep_mask, rx_col}), '^RX', 'R');
aux.loc_type_raw = upper(strtrim(string(raw{keep_mask, loc_col})));
aux.d_m_xlsx     = tr_vals(keep_mask);
aux.pl_orig      = to_numeric(raw{keep_mask, pl_col});
aux.ds_orig      = to_numeric(raw{keep_mask, ds_col});
end


function out = attach_xlsx_pl_ds(frame, xlsx_path, pick_orig, by)
% Join xlsx-derived PL/DS into an AS-csv-based frame.
%
%   by = 'key'      : match on normalized tx_rx_id (NYU scheme, keys like
%                     "T1-R1").
%   by = 'position' : align the two tables by row order within each
%                     loc_type group. Used for USC, where the CSV key
%                     ("R01", "LOS_RX1_07-12-2024") doesn't match the
%                     xlsx's "T1-R1". Both files enumerate LOS rows first,
%                     then NLOS/OLOS, in the same order.
%
% Mirrors python/src/channel_analysis/io.py _attach_xlsx_pl_ds.

out = frame;
out.pl_orig   = nan(height(frame), 1);
out.ds_orig   = nan(height(frame), 1);
out.d_m_xlsx  = nan(height(frame), 1);

if height(frame) == 0 || ~isfile(xlsx_path)
    return
end

aux = xlsx_orig_cols(xlsx_path, pick_orig);

if strcmp(by, 'key')
    aux_key = aux.tx + "-" + aux.rx;
    frame_key = regexprep(frame.tx_rx_id, 'TX', 'T');
    frame_key = regexprep(frame_key, 'RX', 'R');
    for k = 1:height(frame)
        hit = find(aux_key == frame_key(k), 1, 'first');
        if ~isempty(hit)
            out.pl_orig(k)  = aux.pl_orig(hit);
            out.ds_orig(k)  = aux.ds_orig(hit);
            out.d_m_xlsx(k) = aux.d_m_xlsx(hit);
        end
    end
    return
end

% Positional merge within loc_type groups: 0 = LOS, 1 = NLOS/OLOS.
aux_sort = zeros(height(aux), 1);
aux_sort(ismember(aux.loc_type_raw, ["NLOS","OLOS"])) = 1;
frame_sort = zeros(height(frame), 1);
frame_sort(ismember(frame.loc_type_raw, ["NLOS","OLOS"])) = 1;

for s = unique([aux_sort; frame_sort])'
    f_idx = find(frame_sort == s);
    a_idx = find(aux_sort   == s);
    n = min(numel(f_idx), numel(a_idx));
    for j = 1:n
        out.pl_orig(f_idx(j))  = aux.pl_orig(a_idx(j));
        out.ds_orig(f_idx(j))  = aux.ds_orig(a_idx(j));
        out.d_m_xlsx(f_idx(j)) = aux.d_m_xlsx(a_idx(j));
    end
end
end


% ===========================================================================
% Two-row-header xlsx reader (shared by load_point_data and table06_rmse)
% ===========================================================================
function raw = read_two_row_header(xlsx_path, sheet)
% Load an xlsx that carries:
%   row 1 : free-form title
%   row 2 : metric group ("Omni PL", "Omni DS", ...) with MERGED cells
%   row 3 : sub-section / threshold ("NYU thres", "NYU orig. (N1)", ...)
%   row 4+: data.
% We forward-fill row 2 (merged cells report as <missing> beyond anchor),
% then build a table whose VariableDescriptions encode (section, metric).

cells = readcell(char(xlsx_path), 'Sheet', char(sheet));

metric_row = forward_fill_row(cells(2, :));   % merged metric groups
sec_row    = cells(3, :);                     % threshold labels

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
% Find the column whose (section, metric) pair matches both substrings
% (case-insensitive). Empty section_substr -> metric-only match.
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
% Coerce a cell / array to double; non-numeric entries -> NaN.
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

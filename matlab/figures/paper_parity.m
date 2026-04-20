function paper_parity()
% paper_parity  Side-by-side Paper / Python / MATLAB reproduction check.
%
%   Reads the paper's Table VI and Table VII reference values from
%   <repo>/data/paper_reference/ and the regenerated port outputs from
%   figures/matlab/*.csv (this port) plus figures/python/*.csv (the verified
%   reference), then writes:
%
%       figures/matlab/paper_parity_table06.csv
%       figures/matlab/paper_parity_table07.csv
%       docs/paper_parity_matlab.md
%
%   and prints a concise TIGHT/CLOSE/MISS summary to the MATLAB console.
%
%   Tolerances (match python/src/channel_analysis/figures/paper_parity.py):
%       * Point estimates (PLE, sigma_SF, lognormal means) : <=2% relative is TIGHT.
%       * Bootstrap CFI widths (RNG-sensitive)             : <=15% relative is TIGHT.
%       * <=30% relative -> CLOSE, >30% -> MISS.
%
% Mirrors python/src/channel_analysis/figures/paper_parity.py

plot_style();
P = paths();
if ~exist(P.out_dir, 'dir'), mkdir(P.out_dir); end
repo_root = fileparts(fileparts(P.out_dir));   % <repo>/figures/matlab -> <repo>

paper_dir  = fullfile(repo_root, 'data', 'paper_reference');
py_dir     = fullfile(repo_root, 'figures', 'python');
ml_dir     = P.out_dir;
doc_out    = fullfile(repo_root, 'docs', 'paper_parity_matlab.md');

paper_t6 = readtable(fullfile(paper_dir, 'table06_paper_values.csv'), ...
                     'VariableNamingRule', 'preserve');
paper_t7 = readtable(fullfile(paper_dir, 'table07_paper_values.csv'), ...
                     'VariableNamingRule', 'preserve');

ml_t6 = try_readtable(fullfile(ml_dir, 'table06_rmse.csv'));
ml_t7 = try_readtable(fullfile(ml_dir, 'table07_pooled_stats.csv'));
py_t6 = try_readtable(fullfile(py_dir, 'table06_rmse.csv'));
py_t7 = try_readtable(fullfile(py_dir, 'table07_pooled_stats.csv'));

% --- Table VI -------------------------------------------------------------
variants = {'USC_data_NYU_thres','USC_data_USC_thres', ...
            'NYU_data_USC_thres','NYU_data_NYU_thres'};
rows6 = {};
for ir = 1:height(paper_t6)
    band   = paper_t6.Band{ir};
    metric = paper_t6.Metric{ir};
    for iv = 1:numel(variants)
        v  = variants{iv};
        pv = paper_t6.(v)(ir);
        py = lookup_t6(py_t6, band, metric, v);
        ml = lookup_t6(ml_t6, band, metric, v);
        rows6(end+1, :) = {band, metric, v, pv, py, ml, ...
                           status(pv, py, v), status(pv, ml, v)}; %#ok<AGROW>
    end
end
parity6 = cell2table(rows6, ...
    'VariableNames', {'Band','Metric','Variant', ...
                      'Paper','Python','MATLAB','PyStatus','MLStatus'});
writetable(parity6, fullfile(ml_dir, 'paper_parity_table06.csv'));

% --- Table VII ------------------------------------------------------------
t7_cols = {'PLE','sigma_SF_dB','PLE_CFI_width', ...
           'DS_mean_ns','DS_CFI_width_ns', ...
           'ASA_mean_d','ASA_CFI_width_d', ...
           'ASD_mean_d','ASD_CFI_width_d'};
% Paper uses short "Sub-THz"; port CSVs use "Sub-THz (142/145.5)".
band_map_paper_to_port = containers.Map(...
    {'Sub-THz','6.75 GHz'}, {'Sub-THz (142/145.5)','6.75 GHz'});
rows7 = {};
for ir = 1:height(paper_t7)
    band_p  = paper_t7.Band{ir};
    band_pt = band_map_paper_to_port(band_p);
    ds      = paper_t7.Dataset{ir};
    loc     = paper_t7.LocType{ir};
    for ic = 1:numel(t7_cols)
        c  = t7_cols{ic};
        pv = paper_t7.(c)(ir);
        py = lookup_t7(py_t7, band_pt, ds, loc, c);
        ml = lookup_t7(ml_t7, band_pt, ds, loc, c);
        rows7(end+1, :) = {band_p, ds, loc, c, pv, py, ml, ...
                           status(pv, py, c), status(pv, ml, c)}; %#ok<AGROW>
    end
end
parity7 = cell2table(rows7, ...
    'VariableNames', {'Band','Dataset','LocType','Metric', ...
                      'Paper','Python','MATLAB','PyStatus','MLStatus'});
writetable(parity7, fullfile(ml_dir, 'paper_parity_table07.csv'));

% --- Summary --------------------------------------------------------------
fprintf('\n==============================================================\n');
fprintf(' Paper reproduction parity (TIGHT / CLOSE / MISS)\n');
fprintf('==============================================================\n');
for port = ["Python","MATLAB"]
    for frame_name = ["Table VI","Table VII"]
        if frame_name == "Table VI"
            df = parity6;
        else
            df = parity7;
        end
        col = char(port);
        if strcmp(col, 'Python'), sc = 'PyStatus'; else, sc = 'MLStatus'; end
        tight = sum(strcmp(df.(sc), 'TIGHT'));
        close = sum(strcmp(df.(sc), 'CLOSE'));
        miss  = sum(strcmp(df.(sc), 'MISS'));
        nodata = sum(strcmp(df.(sc), '-'));
        fprintf('  %s vs Paper - %s:  %d TIGHT,  %d CLOSE,  %d MISS  (of %d)', ...
            port, frame_name, tight, close, miss, height(df) - nodata);
        if nodata > 0
            fprintf('  [%d skipped]', nodata);
        end
        fprintf('\n');
    end
end
fprintf('==============================================================\n\n');

write_md(doc_out, parity6, parity7);
fprintf('[paper_parity] wrote %s\n', doc_out);
end


% ===========================================================================
function T = try_readtable(p)
if exist(p, 'file')
    T = readtable(p, 'VariableNamingRule', 'preserve');
else
    T = table();
end
end


function v = lookup_t6(df, band, metric, variant)
if isempty(df), v = NaN; return, end
% Band and Metric are always preserved names.
row = df(strcmp(string(df.Band), band) & strcmp(string(df.Metric), metric), :);
if isempty(row), v = NaN; return, end
% Try multiple column-name spellings.
candidates = { variant, ...
               regexprep(variant, '_', ' '), ...
               strrep(variant, '_', '_'), ...
               regexprep(variant, '_', ' - ')};
v = NaN;
for k = 1:numel(candidates)
    try
        v = double(row.(candidates{k})(1));
        return
    catch
        continue
    end
end
% Fallback: normalize both sides
target = lower(regexprep(variant, '[^a-z0-9]', ''));
for vn = string(row.Properties.VariableNames)
    if strcmp(lower(regexprep(char(vn), '[^a-z0-9]', '')), target)
        v = double(row.(char(vn))(1));
        return
    end
end
end


function v = lookup_t7(df, band, ds, loc, col)
if isempty(df), v = NaN; return, end
mask = strcmp(string(df.Band), band) ...
     & strcmp(string(df.Dataset), ds) ...
     & strcmp(string(df.LocType), loc);
row = df(mask, :);
if isempty(row), v = NaN; return, end
try
    v = double(row.(col)(1));
catch
    % Try name normalization
    target = lower(regexprep(col, '[^a-z0-9]', ''));
    v = NaN;
    for vn = string(row.Properties.VariableNames)
        if strcmp(lower(regexprep(char(vn), '[^a-z0-9]', '')), target)
            v = double(row.(char(vn))(1));
            return
        end
    end
end
end


function s = status(paper, port, col)
% Mirrors python paper_parity._close.
%
% CFI-width columns in the paper's Table VII use a MIXED full/half
% convention (some cells report full 95%% width hi-lo; others report
% half-width (hi-lo)/2). Accept either convention for those columns.
ABS_TOL = 0.05;
REL_POINT = 0.02;
REL_CFI = 0.15;
WARN_REL = 0.30;
cfi_cols = {'DS_CFI_width_ns','ASA_CFI_width_d','ASD_CFI_width_d','PLE_CFI_width'};

if ~isfinite(paper) || ~isfinite(port)
    s = '-'; return
end

is_cfi = any(strcmp(col, cfi_cols));

% Candidate residuals: direct; if CFI, also accept 2*port (paper reported
% half-width against pipeline's full) and port/2 (reverse).
if is_cfi
    candidates = [abs(paper - port), abs(paper - 2*port), abs(paper - port/2)];
    d = min(candidates);
else
    d = abs(paper - port);
end
r = d / max(abs(paper), 1e-9);

if is_cfi
    tight_rel = REL_CFI;
else
    tight_rel = REL_POINT;
end

if d < ABS_TOL || r < tight_rel
    s = 'TIGHT';
elseif r < WARN_REL
    s = 'CLOSE';
else
    s = 'MISS';
end
end


function write_md(path, p6, p7)
fid = fopen(path, 'w');
if fid < 0, return, end
fprintf(fid, '# Paper reproduction parity (MATLAB view)\n\n');
fprintf(fid, 'Generated by `matlab/figures/paper_parity.m`.\n');
fprintf(fid, 'Tolerance: point-est <=2%% or CFI-width <=15%% = TIGHT; <=30%% = CLOSE; >30%% = MISS.\n\n');
for port = ["Python","MATLAB"]
    for frame_name = ["Table VI","Table VII"]
        if frame_name == "Table VI", df = p6; else, df = p7; end
        if strcmp(char(port), 'Python'), sc = 'PyStatus'; else, sc = 'MLStatus'; end
        tight = sum(strcmp(df.(sc), 'TIGHT'));
        close = sum(strcmp(df.(sc), 'CLOSE'));
        miss  = sum(strcmp(df.(sc), 'MISS'));
        nd    = sum(strcmp(df.(sc), '-'));
        fprintf(fid, '- %s vs Paper - %s: %d TIGHT, %d CLOSE, %d MISS (of %d)\n', ...
            port, frame_name, tight, close, miss, height(df) - nd);
    end
end
fclose(fid);
end

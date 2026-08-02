function table07_canonical()
% table07_canonical  Regenerate the paper's Table VI (pooled statistics)
% under the CANONICAL single-state conventions of the revised manuscript:
%
%   * links, LOS/NLOS labels, and N1/U1 values are taken from the canonical
%     point-data xlsx (the "orig." columns of N3_142/U3_142/N3_7/U3_7 --
%     identical to the released supplementary tables);
%   * OLOS is relabeled NLOS for pooled modeling;
%   * CI path-loss fit with 1 m free-space reference, no intercept,
%     sigma_SF with ddof = 0; bootstrap 95% CFI over links (B = 2000);
%   * DS/ASA/ASD lognormal means exp(mu*ln10 + (sigma*ln10)^2/2) on log10
%     values (ddof = 0), full-width bootstrap CFIs;
%   * the declared 2 ns delay-resolution floor is EXECUTED for the DS fits
%     (resolution-limited links are excluded from DS distribution fits and
%     retained everywhere else).
%
% Output: <repo>/figures/matlab/table07_canonical.csv
% This is the authoritative regeneration path for the revised Table VI; the
% legacy table07_pooled_stats (hybrid CSV/xlsx loader) is retained only for
% provenance of the previous submission.

P = paths();
out_csv = fullfile(P.out_dir, 'table07_canonical.csv');
DS_FLOOR_NS = 2.0;
B_BOOT = 2000;
rng(0);

sets = {
    % institution, band label, band GHz, xlsx path
    'NYU', 'Sub-THz',  142.0, P.n3_142_xlsx;
    'USC', 'Sub-THz',  145.5, P.u3_142_xlsx;
    'NYU', '6.75 GHz', 6.75,  P.n3_7_xlsx;
    'USC', '6.75 GHz', 6.75,  P.u3_7_xlsx;
};

% -- Load all links ---------------------------------------------------------
L = table();
for i = 1:size(sets, 1)
    T = read_canonical(sets{i, 4});
    T.institution = repmat(string(sets{i, 1}), height(T), 1);
    T.band        = repmat(string(sets{i, 2}), height(T), 1);
    T.f_ghz       = repmat(sets{i, 3}, height(T), 1);
    L = [L; T]; %#ok<AGROW>
end
L.cls = L.loc_type;
L.cls(L.cls == "OLOS") = "NLOS";

fprintf('[table07_canonical] %d valid links loaded\n', height(L));

% -- Fit every (band, dataset, class) cell ----------------------------------
rows = {};
bands = ["Sub-THz", "6.75 GHz"];
dsets = {"NYU only", "USC only", "Pooled"};
for b = bands
    for d = 1:numel(dsets)
        for cls = ["LOS", "NLOS"]
            sel = L.band == b & L.cls == cls;
            if d < 3
                inst = extractBefore(string(dsets{d}), ' ');
                sel = sel & L.institution == inst;
            end
            g = L(sel, :);

            [ple, sig] = ci_fit(g.dist_m, g.pl, g.f_ghz);
            cfi = boot_ci_fit(g.dist_m, g.pl, g.f_ghz, B_BOOT);

            ds_v  = g.ds(~isnan(g.ds) & g.ds >= DS_FLOOR_NS);
            asa_v = g.asa(~isnan(g.asa) & g.asa > 0);
            asd_v = g.asd(~isnan(g.asd) & g.asd > 0);

            [ds_m, ds_w]   = logn_mean_ci(ds_v, B_BOOT);
            [asa_m, asa_w] = logn_mean_ci(asa_v, B_BOOT);
            [asd_m, asd_w] = logn_mean_ci(asd_v, B_BOOT);

            rows(end+1, :) = {char(b), dsets{d}, char(cls), height(g), ...
                round(ple, 2), round(sig, 2), round(cfi, 2), ...
                round(ds_m, 2), round(ds_w, 2), numel(ds_v), ...
                round(asa_m, 2), round(asa_w, 2), numel(asa_v), ...
                round(asd_m, 2), round(asd_w, 2), numel(asd_v)}; %#ok<AGROW>
        end
    end
end

T = cell2table(rows, 'VariableNames', {'Band', 'Dataset', 'LocType', ...
    'n_links', 'PLE', 'sigma_SF_dB', 'PLE_CFI_width', ...
    'DS_mean', 'DS_CFI_width', 'DS_n', ...
    'ASA_mean', 'ASA_CFI_width', 'ASA_n', ...
    'ASD_mean', 'ASD_CFI_width', 'ASD_n'});
writetable(T, out_csv);
fprintf('[table07_canonical] wrote %s\n', out_csv);
end

% ===========================================================================
function T = read_canonical(xlsx_path)
% Two-row-header canonical xlsx -> table(tx, rx, loc_type, dist_m, pl, ds,
% asa, asd) using the institution-original ("orig.") columns 8/11/14/17.
c = readcell(char(xlsx_path), 'Sheet', 'FinalTable');
tx = strings(0); rx = strings(0); loc = strings(0);
dist = []; pl = []; ds = []; asa = []; asd = [];
cur_tx = "";
for r = 4:size(c, 1)
    v_tx = cellstr_or_empty(c{r, 2});
    if strlength(v_tx) > 0, cur_tx = v_tx; end
    v_rx = cellstr_or_empty(c{r, 3});
    if strlength(v_rx) == 0, continue; end
    d  = num_or_nan(c{r, 5});
    p  = num_or_nan(c{r, 8});
    s  = num_or_nan(c{r, 11});
    aa = num_or_nan(c{r, 14});
    ad = num_or_nan(c{r, 17});
    if isnan(d) || (isnan(p) && isnan(s) && isnan(aa) && isnan(ad))
        continue;  % outage row
    end
    tx(end+1, 1) = cur_tx; rx(end+1, 1) = v_rx; %#ok<AGROW>
    loc(end+1, 1) = upper(cellstr_or_empty(c{r, 4})); %#ok<AGROW>
    dist(end+1, 1) = d; pl(end+1, 1) = p; ds(end+1, 1) = s; %#ok<AGROW>
    asa(end+1, 1) = aa; asd(end+1, 1) = ad; %#ok<AGROW>
end
T = table(tx, rx, loc, dist, pl, ds, asa, asd, 'VariableNames', ...
    {'tx', 'rx', 'loc_type', 'dist_m', 'pl', 'ds', 'asa', 'asd'});
end

function s = cellstr_or_empty(v)
if ismissing(v), s = ""; return; end
if isnumeric(v), s = string(v); return; end
s = strtrim(string(v));
end

function y = num_or_nan(v)
if isnumeric(v) && isscalar(v), y = double(v);
elseif ischar(v) || isstring(v), y = str2double(v);
else, y = NaN;
end
end

function [n, sig] = ci_fit(d, pl, f)
m = ~isnan(pl);
x = 10 .* log10(d(m));
y = pl(m) - fspl1m(f(m));
n = sum(x .* y) / sum(x .^ 2);
r = y - n .* x;
sig = sqrt(mean(r .^ 2) - mean(r) ^ 2 + mean(r) ^ 2); % population std
sig = std(r, 1);
end

function w = boot_ci_fit(d, pl, f, B)
m = ~isnan(pl);
d = d(m); pl = pl(m); f = f(m);
nl = numel(d);
vals = zeros(B, 1);
for b = 1:B
    idx = randi(nl, nl, 1);
    vals(b) = ci_fit(d(idx), pl(idx), f(idx));
end
q = quantile(vals, [0.025, 0.975]);
w = q(2) - q(1);
end

function y = fspl1m(f_ghz)
y = 20 .* log10(4 * pi .* f_ghz .* 1e9 ./ 299792458);
end

function [mu_ln, w] = logn_mean_ci(x, B)
lx = log10(x);
ln10 = log(10);
mu_ln = exp(mean(lx) * ln10 + 0.5 * (std(lx, 1) * ln10) ^ 2);
nl = numel(x);
vals = zeros(B, 1);
for b = 1:B
    i = randi(nl, nl, 1);
    v = lx(i);
    vals(b) = exp(mean(v) * ln10 + 0.5 * (std(v, 1) * ln10) ^ 2);
end
q = quantile(vals, [0.025, 0.975]);
w = q(2) - q(1);
end

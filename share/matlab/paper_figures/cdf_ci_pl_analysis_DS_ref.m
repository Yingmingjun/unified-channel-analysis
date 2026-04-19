%% CDFs (DS/ASA/ASD) and CI Path Loss models for NYU vs USC datasets
clear variables;
close all;
clc;

%baseUSC = pwd;
U = paths();
% For sub-THz (142 GHz) DS reference, swap to U.n3_142_xlsx / U.u3_142_xlsx.
% This script as-shipped targets the 6.75 GHz band (Fig. 6(b)).
n3Path = U.n3_7_xlsx;
u3Path = U.u3_7_xlsx;

% Load tables with two-row headers
n3 = load_stats_table(n3Path);
u3 = load_stats_table(u3Path);

% Extract key columns
n3_loc = get_col(n3, 'Loc Type', '');
n3_d   = get_col(n3, 'TR Sep', '');
n3_pl  = get_col(n3, 'Omni PL', 'NYU orig. (N1)');
n3_ds  = get_col(n3, 'Omni DS', 'NYU orig. (N1)');
n3_asa = get_col(n3, 'Omni ASA', 'NYU orig. (N1)');
n3_asd = get_col(n3, 'Omni ASD', 'NYU orig. (N1)');

u3_loc = get_col(u3, 'Loc Type', '');
u3_d   = get_col(u3, 'TR Sep', '');
u3_pl  = get_col(u3, 'Omni PL', 'USC orig. (U1)');
u3_ds  = get_col(u3, 'Omni DS', 'USC orig. (U1)');
u3_asa = get_col(u3, 'Omni ASA', 'USC orig. (U1)');
u3_asd = get_col(u3, 'Omni ASD', 'USC orig. (U1)');

% Build dataset masks
n3_isLOS = strcmpi(string(n3_loc), 'LOS');
n3_isNLOS = strcmpi(string(n3_loc), 'NLOS');
u3_isLOS = strcmpi(string(u3_loc), 'LOS');
u3_isNLOS = strcmpi(string(u3_loc), 'NLOS');
u3_isOLOS = strcmpi(string(u3_loc), 'OLOS');

% ---------- CDFs for DS/ASA/ASD ----------
metrics = {
    'Omni DS', n3_ds, u3_ds;
    'Omni ASA', n3_asa, u3_asa;
    'Omni ASD', n3_asd, u3_asd;
};

for i = 1:size(metrics,1)
    metricName = metrics{i,1};
    n3_vals = metrics{i,2};
    u3_vals = metrics{i,3};
    if all(is_missing_num(n3_vals)) && all(is_missing_num(u3_vals))
        warning('%s is empty in both tables. Skipping CDF.', metricName);
        continue;
    end
    %plot_cdf_group(metricName, n3_vals, u3_vals, n3_isLOS, n3_isNLOS, u3_isLOS, u3_isNLOS);
    plot_cdf_group(metricName, n3_vals, u3_vals, n3_isLOS, n3_isNLOS, u3_isLOS, u3_isOLOS);
end

function tf = is_missing_num(v)
    if isstring(v)
        tf = all(ismissing(v));
    else
        tf = all(isnan(v));
    end
end

% ---------- CI Path Loss model (CI d0=1m, f=142 GHz) ----------
fGHz = 6.75;
%fGHz = 142;
d0 = 1;

plot_ci_models('NYU Data (N3)', n3_d, n3_pl, n3_isLOS, n3_isNLOS, fGHz, d0);
%plot_ci_models('USC Data (U3)', u3_d, u3_pl, u3_isLOS, u3_isNLOS, fGHz, d0);
plot_ci_models('USC Data (U3)', u3_d, u3_pl, u3_isLOS, u3_isOLOS, fGHz, d0);
% plot_ci_models('Pooled NYU+USC', [n3_d; u3_d], [n3_pl; u3_pl], ...
%     [n3_isLOS; u3_isLOS], [n3_isNLOS; u3_isNLOS], fGHz, d0);
plot_ci_models('Pooled NYU+USC', [n3_d; u3_d], [n3_pl; u3_pl], ...
    [n3_isLOS; u3_isLOS], [n3_isNLOS; u3_isOLOS], fGHz, d0);

% ---------- Bootstrap CI width (n and sigma) ----------
bootstrap_ci_summary('NYU Data (N3)', n3_d, n3_pl, n3_isLOS, n3_isNLOS, fGHz, d0);
%bootstrap_ci_summary('USC Data (U3)', u3_d, u3_pl, u3_isLOS, u3_isNLOS, fGHz, d0);
bootstrap_ci_summary('USC Data (U3)', u3_d, u3_pl, u3_isLOS, u3_isOLOS, fGHz, d0);
% bootstrap_ci_summary('Pooled NYU+USC', [n3_d; u3_d], [n3_pl; u3_pl], ...
%     [n3_isLOS; u3_isLOS], [n3_isNLOS; u3_isNLOS], fGHz, d0);
bootstrap_ci_summary('Pooled NYU+USC', [n3_d; u3_d], [n3_pl; u3_pl], ...
    [n3_isLOS; u3_isLOS], [n3_isNLOS; u3_isOLOS], fGHz, d0);

% ---------- Mean DS / AS in log10 domain (report in linear units) ----------
print_mean_log_metric('NYU Data (N3)', n3_ds, n3_asa, n3_asd, n3_isLOS, n3_isNLOS, 'ns', 'deg');
print_mean_log_metric('USC Data (U3)', u3_ds, u3_asa, u3_asd, u3_isLOS, u3_isNLOS, 'ns', 'deg');
print_mean_log_metric('USC Data (U3)', u3_ds, u3_asa, u3_asd, u3_isLOS, u3_isOLOS, 'ns', 'deg');
% print_mean_log_metric('Pooled NYU+USC', [n3_ds; u3_ds], [n3_asa; u3_asa], [n3_asd; u3_asd], ...
%     [n3_isLOS; u3_isLOS], [n3_isNLOS; u3_isNLOS], 'ns', 'deg');
print_mean_log_metric('Pooled NYU+USC', [n3_ds; u3_ds], [n3_asa; u3_asa], [n3_asd; u3_asd], ...
    [n3_isLOS; u3_isLOS], [n3_isNLOS; u3_isOLOS], 'ns', 'deg');

% ---------- Bootstrap 95% CIs / widths for DS and AS (log10-domain stats) ----------
bootstrap_logstat_summary('NYU Data (N3)', n3_ds, n3_asa, n3_asd, n3_isLOS, n3_isNLOS);
% bootstrap_logstat_summary('USC Data (U3)', u3_ds, u3_asa, u3_asd, u3_isLOS, u3_isNLOS);
% bootstrap_logstat_summary('Pooled NYU+USC', [n3_ds; u3_ds], [n3_asa; u3_asa], [n3_asd; u3_asd], ...
%     [n3_isLOS; u3_isLOS], [n3_isNLOS; u3_isNLOS]);

bootstrap_logstat_summary('USC Data (U3)', u3_ds, u3_asa, u3_asd, u3_isLOS, u3_isOLOS);
bootstrap_logstat_summary('Pooled NYU+USC', [n3_ds; u3_ds], [n3_asa; u3_asa], [n3_asd; u3_asd], ...
    [n3_isLOS; u3_isLOS], [n3_isNLOS; u3_isOLOS]);

%% ----- helpers -----
function T = load_stats_table(xlsxPath)
    raw = readcell(xlsxPath, 'Sheet', 'FinalTable');
    headerRow = find(cellfun(@(c) ischar(c) && strcmpi(c, 'Freq.'), raw(:,1)), 1, 'first');
    if isempty(headerRow)
        error('Could not find header row in %s', xlsxPath);
    end
    subHeaderRow = headerRow + 1;
    headers1 = raw(headerRow, :);
    headers2 = raw(subHeaderRow, :);
    headers1 = fill_header(headers1);
    data = raw(subHeaderRow+1:end, :);
    T.headers1 = headers1;
    T.headers2 = headers2;
    T.data = data;
end

function headers = fill_header(headers)
    headers = string(headers);
    headers = standardizeMissing(headers, ["", " ", "nan", "NaN"]);
    for i = 2:numel(headers)
        if ismissing(headers(i))
            headers(i) = headers(i-1);
        end
    end
end

function col = get_col(T, metric, method)
    h1 = string(T.headers1);
    h2 = string(T.headers2);
    if method == ""
        idx = find(strcmpi(strtrim(h1), metric), 1, 'first');
    else
        idx = find(strcmpi(strtrim(h1), metric) & strcmpi(strtrim(h2), method), 1, 'first');
    end
    if isempty(idx)
        col = nan(size(T.data,1),1);
        return;
    end
    col = to_num(T.data(:, idx));
end

function v = to_num(x)
    % Preserve non-numeric columns (e.g., Loc Type) as strings.
    if iscell(x)
        xs = string(x);
        numv = str2double(xs);
        if all(isnan(numv) & xs ~= "")
            v = xs;
        else
            v = numv;
        end
    else
        v = double(x);
    end
end

function plot_cdf_group(metricName, n3_vals, u3_vals, n3_isLOS, n3_isNLOS, u3_isLOS, u3_isNLOS)
    % Match the requested presentation: pooled points only, NYU violet, USC red.
    figure('Name', ['CDF: ' metricName], 'Position', [140, 140, 1400, 520], 'Color', [0.94 0.94 0.94]);
    
    % Colors
    cPooled = [0.10 0.15 0.90];   % blue
    cNYU    = [0.49 0.13 0.55];   % violet
    cUSC    = [0.85 0.00 0.10];   % red
    
    % LOS subplot
    subplot(1,2,1); hold on; grid on; box on;
    style_cdf_axes();
    [hP_los, hN_los, hNb_los, hU_los, hUb_los, hPb_los, pooledMu_los, pooledSd_los] = ...
        plot_cdf_panel(n3_vals(n3_isLOS), u3_vals(u3_isLOS), metricName, true, cPooled, cNYU, cUSC);
    title(['LOS ' strrep(metricName, 'Omni ', 'Omni RMS ') ' sub-THz']);
    xlabel(cdf_xlabel(metricName));
    ylabel('Probability');
    add_logstat_text(pooledMu_los, pooledSd_los, metricName);
    legend([hP_los, hN_los, hNb_los, hU_los, hUb_los, hPb_los], ...
        {'USC+NYU','NYU','NYU 95% band','USC','USC 95% band','USC+NYU 95% band'}, ...
        'Location', 'southeast');
    
    % NLOS / OLOS subplot
    subplot(1,2,2); hold on; grid on; box on;
    style_cdf_axes();
    [hP_nlos, hN_nlos, hNb_nlos, hU_nlos, hUb_nlos, hPb_nlos, pooledMu_nlos, pooledSd_nlos] = ...
        plot_cdf_panel(n3_vals(n3_isNLOS), u3_vals(u3_isNLOS), metricName, false, cPooled, cNYU, cUSC);
    title(['NLOS ' strrep(metricName, 'Omni ', 'Omni RMS ') ' sub-THz']);
    xlabel(cdf_xlabel(metricName));
    ylabel('Probability');
    add_logstat_text(pooledMu_nlos, pooledSd_nlos, metricName);
    legend([hP_nlos, hN_nlos, hNb_nlos, hU_nlos, hUb_nlos, hPb_nlos], ...
        {'USC+NYU','NYU','NYU 95% band','USC','USC 95% band','USC+NYU 95% band'}, ...
        'Location', 'southeast');
end

function [hPooled, hNYU, hNYUband, hUSC, hUSCband, hPooledBand, pooledMu, pooledSd] = ...
    plot_cdf_panel(nyuVals, uscVals, metricName, isLOS, cPooled, cNYU, cUSC)
    nyuVals = sanitize_numeric_vec(nyuVals);
    uscVals = sanitize_numeric_vec(uscVals);
    pooledVals = sanitize_numeric_vec([nyuVals; uscVals]);
    
    [xN, fN, fNlo, fNhi] = ecdf_with_dkw(nyuVals);
    [xU, fU, fUlo, fUhi] = ecdf_with_dkw(uscVals);
    [xP, fP, fPlo, fPhi] = ecdf_with_dkw(pooledVals);
    
    hNYUband = plot_band(xN, fNlo, fNhi, cNYU, 0.12);
    hUSCband = plot_band(xU, fUlo, fUhi, cUSC, 0.12);
    hPooledBand = plot_band(xP, fPlo, fPhi, cPooled, 0.10);
    
    hNYU = plot(xN, fN, 'Color', cNYU, 'LineWidth', 2.2);
    hUSC = plot(xU, fU, 'Color', cUSC, 'LineWidth', 2.2);
    
    % Pooled points only (no connecting line): circles for LOS, diamonds for NLOS/OLOS
    if isLOS
        mk = 'o';
    else
        mk = 'd';
    end
    hPooled = scatter(xP, fP, 70, mk, 'MarkerEdgeColor', cPooled, ...
        'LineWidth', 2.0, 'MarkerFaceColor', 'none');
    
    % Log10-domain pooled stats for textbox
    pooledMu = NaN;
    pooledSd = NaN;
    if ~isempty(pooledVals)
        lv = log10(pooledVals);
        pooledMu = mean(lv);
        pooledSd = std(lv);
    end
    
    % Set x-limits similar to reference style using pooled max (with margin)
    if ~isempty(pooledVals)
        xmax = max(pooledVals);
        if contains(metricName, 'DS')
            xlim([0, ceil(1.05*xmax)]);
        else
            xlim([0, ceil(1.05*xmax)]);
        end
    end
    ylim([0, 1]);
end

function h = plot_band(x, flo, fhi, color, alphaVal)
    if isempty(x)
        h = patch(NaN, NaN, color, 'FaceAlpha', alphaVal, 'EdgeColor', 'none');
        return;
    end
    h = fill([x; flipud(x)], [flo; flipud(fhi)], color, ...
        'FaceAlpha', alphaVal, 'EdgeColor', 'none');
end

function [x, f, flo, fhi] = ecdf_with_dkw(vals)
    vals = vals(isfinite(vals) & vals > 0);
    if isempty(vals)
        x = []; f = []; flo = []; fhi = [];
        return;
    end
    [f, x] = ecdf(vals);
    n = numel(vals);
    eps = sqrt(log(2/0.05) / (2*n));
    flo = max(0, f - eps);
    fhi = min(1, f + eps);
end

function vals = sanitize_numeric_vec(vals)
    if isstring(vals)
        vals = str2double(vals);
    end
    vals = vals(:);
    vals = vals(isfinite(vals) & vals > 0);
end

function s = cdf_xlabel(metricName)
    if strcmpi(metricName, 'Omni DS')
        s = 'Omni RMS DS [ns]';
    elseif strcmpi(metricName, 'Omni ASA')
        s = 'Omni RMS ASA [deg]';
    elseif strcmpi(metricName, 'Omni ASD')
        s = 'Omni RMS ASD [deg]';
    else
        s = metricName;
    end
end

function add_logstat_text(mu, sigma, metricName)
    if ~isfinite(mu) || ~isfinite(sigma)
        return;
    end
    if contains(metricName, 'DS')
        baseLabel = 'DS';
    else
        baseLabel = 'AS';
    end
    txt = sprintf('\\mu(lg(%s^{USC+NYU}_{sub-THz})) = %.2f\\n\\sigma(lg(%s^{USC+NYU}_{sub-THz})) = %.2f', ...
        baseLabel, mu, baseLabel, sigma);
    text(0.97, 0.08, txt, 'Units', 'normalized', ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', ...
        'FontSize', 11, 'BackgroundColor', 'none');
end

function style_cdf_axes()
    ax = gca;
    ax.FontSize = 14;
    ax.GridAlpha = 0.2;
    ax.LineWidth = 0.8;
end

function plot_ci_models(label, d, pl, isLOS, isNLOS, fGHz, d0)
    d = d(:);
    pl = pl(:);
    isLOS = isLOS(:);
    isNLOS = isNLOS(:);
    valid = isfinite(d) & isfinite(pl);
    figure('Name', ['CI PL Model: ' label], 'Position', [200, 200, 900, 500]);
    hold on; grid on; box on;
    [n_los, sig_los, ci_los] = plot_ci_fit(d(valid & isLOS), pl(valid & isLOS), fGHz, d0, 'LOS', 'o', [0 0.45 0.74]);
    [n_nlos, sig_nlos, ci_nlos] = plot_ci_fit(d(valid & isNLOS), pl(valid & isNLOS), fGHz, d0, 'NLOS', 's', [0.85 0.33 0.10]);
    title(label);
    xlabel('Distance (m)'); ylabel('Path Loss (dB)');
    set(gca, 'XScale', 'log');
    xlim([1, 1000]);
    legend('LOS data', 'LOS fit', 'LOS 95% band', 'NLOS data', 'NLOS fit', 'NLOS 95% band', 'Location', 'best');
    
    fprintf('%s\n', label);
    if ~isempty(n_los)
        fprintf('  LOS  n = %.3f , sigma = %.3f, (95%% CI %.3f, %.3f)\n', n_los, sig_los, ci_los(1), ci_los(2));
    end
    if ~isempty(n_nlos)
        fprintf('  NLOS n = %.3f , sigma = %.3f, (95%% CI %.3f, %.3f)\n', n_nlos, sig_nlos, ci_nlos(1), ci_nlos(2));
    end
end

function [n, sigma, n_ci] = plot_ci_fit(d, pl, fGHz, d0, tag, marker, color)
    d = d(:);
    pl = pl(:);
    d = d(isfinite(d));
    pl = pl(isfinite(pl));
    valid = d > 0 & isfinite(pl);
    d = d(valid); pl = pl(valid);
    if isempty(d)
        n = [];
        n_ci = [];
        sigma = [];
        return;
    end
    % Fit CI model with fixed intercept: PL = FSPL(d0) + 10n log10(d/d0)
    fspl0 = 32.44 + 20*log10(fGHz) + 20*log10(d0);
    D = 10*log10(d/d0);
    A = pl - fspl0;
    n = (A' * D) / (D' * D);
    yhat = fspl0 + n * D;
    sigma = sqrt(sum((pl - yhat).^2) / numel(yhat));
    
    % Bootstrap CI for line
    nboot = 1000;
    dgrid = linspace(1, 1000, 100)';
    Dg = 10*log10(dgrid/d0);
    yhat_boot = zeros(nboot, numel(dgrid));
    n_boot = zeros(nboot,1);
    for b = 1:nboot
        idx = randi(numel(d), numel(d), 1);
        Db = D(idx);
        Ab = A(idx);
        nb = (Ab' * Db) / (Db' * Db);
        n_boot(b) = nb;
        yhat_boot(b,:) = fspl0 + nb * Dg;
    end
    y_lo = prctile(yhat_boot, 2.5, 1);
    y_hi = prctile(yhat_boot, 97.5, 1);
    pl_fit = fspl0 + n * Dg;
    
    scatter(d, pl, 25, marker, 'MarkerEdgeColor', color, 'MarkerFaceColor', color, 'MarkerFaceAlpha', 0.6);
    plot(dgrid, pl_fit, 'Color', color, 'LineWidth', 1.6);
    fill([dgrid; flipud(dgrid)], [y_lo'; flipud(y_hi')], ...
        color, 'FaceAlpha', 0.15, 'EdgeColor', 'none');
    % Bootstrap CI for n
    n_ci = prctile(n_boot, [2.5 97.5]);
end

function bootstrap_ci_summary(label, d, pl, isLOS, isNLOS, fGHz, d0)
    fprintf('\n%s\n', label);
    fprintf('-----------------------------\n');
    d = d(:);
    pl = pl(:);
    isLOS = isLOS(:);
    isNLOS = isNLOS(:);
    valid = isfinite(d) & isfinite(pl);
    summarize_bootstrap(d(valid & isLOS), pl(valid & isLOS), fGHz, d0, 'LOS');
    summarize_bootstrap(d(valid & isNLOS), pl(valid & isNLOS), fGHz, d0, 'NLOS');
end

function summarize_bootstrap(d, pl, fGHz, d0, tag)
    d = d(:);
    pl = pl(:);
    d = d(isfinite(d));
    pl = pl(isfinite(pl));
    valid = d > 0 & isfinite(pl);
    d = d(valid); pl = pl(valid);
    if numel(d) < 5
        fprintf('%s: insufficient data\n', tag);
        return;
    end
    fspl0 = 32.44 + 20*log10(fGHz) + 20*log10(d0);
    D = 10*log10(d/d0);
    A = pl - fspl0;
    nboot = 1000;
    n_vals = zeros(nboot,1);
    s_vals = zeros(nboot,1);
    for b = 1:nboot
        idx = randi(numel(d), numel(d), 1);
        Db = D(idx);
        Ab = A(idx);
        nb = (Ab' * Db) / (Db' * Db);
        n_vals(b) = nb;
        yhat = fspl0 + nb * Db;
        s_vals(b) = sqrt(sum((pl(idx) - yhat).^2) / numel(Db));
    end
    n_ci = prctile(n_vals, [2.5 97.5]);
    s_ci = prctile(s_vals, [2.5 97.5]);
    fprintf('%s: n CI width = %.3f, sigma CI width = %.3f\n', tag, n_ci(2)-n_ci(1), s_ci(2)-s_ci(1));
end

function print_mean_log_metric(label, ds, asa, asd, isLOS, isNLOS, dsUnit, asUnit)
    fprintf('\n%s\n', label);
    fprintf('Mean DS/AS (log-domain mean, reported linear)\n');
    print_logmean('DS', ds, isLOS, isNLOS, dsUnit);
    print_logmean('ASA', asa, isLOS, isNLOS, asUnit);
    print_logmean('ASD', asd, isLOS, isNLOS, asUnit);
end

function bootstrap_logstat_summary(label, ds, asa, asd, isLOS, isNLOS)
    fprintf('\n%s\n', label);
    fprintf('Log10-domain 95%% CIs / widths for DS and AS\n');
    summarize_logstat_ci('DS', ds, isLOS, isNLOS);
    summarize_logstat_ci('ASA', asa, isLOS, isNLOS);
    summarize_logstat_ci('ASD', asd, isLOS, isNLOS);
end

function summarize_logstat_ci(name, vals, isLOS, isNLOS)
    vals = vals(:);
    if isstring(vals)
        vals = str2double(vals);
    end
    isLOS = isLOS(:);
    isNLOS = isNLOS(:);
    report_log_ci_for_subset(name, 'LOS', vals(isLOS));
    report_log_ci_for_subset(name, 'NLOS', vals(isNLOS));
end

function report_log_ci_for_subset(name, tag, vals)
    vals = vals(isfinite(vals) & vals > 0);
    if isempty(vals)
        fprintf('  %s %s: empty, skipped\n', name, tag);
        return;
    end
    lv = log10(vals);
    mu = mean(lv);
    sd = std(lv);
    nboot = 1000;
    muBoot = zeros(nboot,1);
    sdBoot = zeros(nboot,1);
    for b = 1:nboot
        idx = randi(numel(lv), numel(lv), 1);
        xb = lv(idx);
        muBoot(b) = mean(xb);
        sdBoot(b) = std(xb);
    end
    muCI = prctile(muBoot, [2.5 97.5]);
    sdCI = prctile(sdBoot, [2.5 97.5]);
    
    % Convert the log10-domain mean/sd pair to linear-domain mean assuming log-normal data.
    ln10 = log(10);
    linMean = exp(mu*ln10 + 0.5*(sd*ln10)^2);
    linMeanBoot = exp(muBoot*ln10 + 0.5*(sdBoot*ln10).^2);
    linCI = prctile(linMeanBoot, [2.5 97.5]);
    linWidth = linCI(2) - linCI(1);
    
    fprintf('  %s %s: mean_lin=%.3f (95%% CI [%.3f, %.3f], width %.3f) | mu_lg=%.3f, sigma_lg=%.3f\n', ...
        name, tag, linMean, linCI(1), linCI(2), linWidth, mu, sd);
end

function print_logmean(name, vals, isLOS, isNLOS, unit)
    vals = vals(:);
    isLOS = isLOS(:);
    isNLOS = isNLOS(:);
    vlos = vals(isLOS);
    vnlos = vals(isNLOS);
    if isstring(vlos)
        vlos = str2double(vlos);
    end
    if isstring(vnlos)
        vnlos = str2double(vnlos);
    end
    vlos = vlos(isfinite(vlos) & vlos > 0);
    vnlos = vnlos(isfinite(vnlos) & vnlos > 0);
    if ~isempty(vlos)
        lv = log10(vlos);
        mu = mean(lv);
        sd = std(lv);
        mlos = exp(mu*log(10) + 0.5*(sd*log(10))^2);
        fprintf('  %s LOS mean: %.3f %s\n', name, mlos, unit);
    end
    if ~isempty(vnlos)
        lv = log10(vnlos);
        mu = mean(lv);
        sd = std(lv);
        mnlos = exp(mu*log(10) + 0.5*(sd*log(10))^2);
        fprintf('  %s NLOS mean: %.3f %s\n', name, mnlos, unit);
    end
end

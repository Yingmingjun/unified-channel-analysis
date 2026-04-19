%% ========================================================================
%  DS CDF Merged: Omni RMS Delay Spread CDFs matching the AS CDF style
%  ========================================================================
%
%  PURPOSE: Generate CDF plots for Delay Spread (Omni RMS DS) at both
%           sub-THz (142/145 GHz) and FR1(C) (6.75 GHz) frequencies.
%           Visual style is a direct clone of AS_CDF_Merged.m so the DS
%           panels in the paper (OmniDS_merged*, main_final.tex L1169/1174)
%           match the ASA/ASD panels (OmniASA_merged*, OmniASD_merged*) at
%           L1186/1191/1204/1209.
%
%  OUTPUT FIGURES (saved to paths().paper_fig_out as .png + .jpg + .fig):
%    - OmniDS_merged.jpg/.png/.fig   (sub-THz DS CDF: LOS | NLOS)
%    - OmniDS_merged7.jpg/.png/.fig  (6.75 GHz DS CDF: LOS | NLOS)
%
%  STYLE (matches AS_CDF_Merged.m exactly):
%    - Violet (NYU) / Red (USC) ECDF lines + 95 % DKW bands
%    - Blue pooled scatter (circles LOS, diamonds NLOS)
%    - Lognormal mu/sigma annotation on log10(DS) for pooled data
%    - 1x2 LOS | NLOS subplots, 1400x520 figure
%
%  DATA SOURCES (columns in the raw-processing Results/*.mat tables):
%  Each dataset uses its own institution's synthesis method (per paper):
%    Sub-THz:
%      NYU 142 GHz : results.DS_NYU              (NYU SUM, NYU data)
%      USC 145 GHz : results.DS_USC              (USC perDelayMax, USC data)
%    FR1(C):
%      NYU 6.75 GHz: results.DS_NYUthr_SUM       (NYU SUM w/ NYU-thresh)
%      USC 6.75 GHz: results.DS_USC              (USC perDelayMax, USC data)
%  ========================================================================

clear variables; close all; clc;

%% ========================================================================
%  CONFIGURATION
%  ========================================================================

U = paths();
figOutputPath = U.paper_fig_out;
if ~exist(figOutputPath, 'dir'), mkdir(figOutputPath); end

% Data paths (written by the raw-processing scripts under matlab/processing/*/Results/)
nyu142Path = fullfile(U.results_nyu_142, 'all_comparison_results.mat');
usc145Path = fullfile(U.results_usc_145, 'USC145GHz_Full_Results.mat');
nyu7Path   = fullfile(U.results_nyu_7,   'all_comparison_results.mat');
usc7Path   = fullfile(U.results_usc_7,   'USC7GHz_Full_Results.mat');

% Colors matching AS_CDF_Merged.m / cdf_ci_pl_analysis_DS_ref.m
colorNYU    = [0.49 0.13 0.55];   % violet
colorUSC    = [0.85 0.00 0.10];   % red
colorPooled = [0.10 0.15 0.90];   % blue

%% ========================================================================
%  LOAD DATA
%  ========================================================================
fprintf('Loading datasets...\n');

% Sub-THz
nyu142 = load(nyu142Path); nyu142_r = nyu142.results;
usc145 = load(usc145Path); usc145_r = usc145.results;

% 6.75 GHz
nyu7 = load(nyu7Path); nyu7_r = nyu7.results;
usc7 = load(usc7Path); usc7_r = usc7.results;

%% ========================================================================
%  BUILD LOS/NLOS MASKS
%  ========================================================================

% Sub-THz NYU (142 GHz)
nyu142_isLOS  = strcmpi(string(nyu142_r.Environment), 'LOS');
nyu142_isNLOS = strcmpi(string(nyu142_r.Environment), 'NLOS');

% Sub-THz USC (145 GHz)
usc145_isLOS  = strcmpi(string(usc145_r.Environment), 'LOS');
usc145_isNLOS = strcmpi(string(usc145_r.Environment), 'NLOS');

% 6.75 GHz NYU (OLOS folded into NLOS to match load_point_data.m / AS_CDF_Merged.m)
nyu7_isLOS  = strcmpi(string(nyu7_r.Environment), 'LOS');
nyu7_isNLOS = strcmpi(string(nyu7_r.Environment), 'NLOS') | ...
              strcmpi(string(nyu7_r.Environment), 'OLOS');

% 6.75 GHz USC
usc7_isLOS  = strcmpi(string(usc7_r.Environment), 'LOS');
usc7_isNLOS = strcmpi(string(usc7_r.Environment), 'NLOS') | ...
              strcmpi(string(usc7_r.Environment), 'OLOS');

fprintf('Sub-THz: NYU %d LOS + %d NLOS, USC %d LOS + %d NLOS\n', ...
    sum(nyu142_isLOS), sum(nyu142_isNLOS), sum(usc145_isLOS), sum(usc145_isNLOS));
fprintf('6.75 GHz: NYU %d LOS + %d NLOS, USC %d LOS + %d NLOS\n', ...
    sum(nyu7_isLOS), sum(nyu7_isNLOS), sum(usc7_isLOS), sum(usc7_isNLOS));

%% ========================================================================
%  GENERATE FIGURES
%  ========================================================================

% --- Sub-THz DS ---
generate_ds_cdf_figure( ...
    'DS', 'sub-THz', 'ns', ...
    nyu142_r.DS_NYU, usc145_r.DS_USC, ...
    nyu142_isLOS, nyu142_isNLOS, usc145_isLOS, usc145_isNLOS, ...
    colorNYU, colorUSC, colorPooled, ...
    figOutputPath, 'OmniDS_merged');

% --- 6.75 GHz DS ---
generate_ds_cdf_figure( ...
    'DS', '6.75 GHz', 'ns', ...
    nyu7_r.DS_NYUthr_SUM, usc7_r.DS_USC, ...
    nyu7_isLOS, nyu7_isNLOS, usc7_isLOS, usc7_isNLOS, ...
    colorNYU, colorUSC, colorPooled, ...
    figOutputPath, 'OmniDS_merged7');

fprintf('\nAll DS CDF figures saved to: %s\n', figOutputPath);
fprintf('Done!\n');

%% ========================================================================
%  HELPER FUNCTIONS (mirror AS_CDF_Merged.m)
%  ========================================================================

function generate_ds_cdf_figure(metricName, freqLabel, unitLabel, ...
    nyu_vals, usc_vals, nyu_isLOS, nyu_isNLOS, usc_isLOS, usc_isNLOS, ...
    colorNYU, colorUSC, colorPooled, ...
    outputFolder, baseName)

    fig = figure('Position', [140, 140, 1400, 520], 'Color', 'w');

    % ===== LOS subplot =====
    subplot(1, 2, 1); hold on; grid on; box on;
    style_cdf_axes();

    nyu_los = clean_vals(nyu_vals(nyu_isLOS));
    usc_los = clean_vals(usc_vals(usc_isLOS));

    [hP_los, hN_los, hNb_los, hU_los, hUb_los, hPb_los, mu_los, sd_los] = ...
        plot_cdf_panel(nyu_los, usc_los, true, colorPooled, colorNYU, colorUSC);

    title(sprintf('LOS Omni RMS %s %s', metricName, freqLabel), 'Interpreter', 'none');
    xlabel(sprintf('Omni RMS %s [%s]', metricName, unitLabel), 'Interpreter', 'tex');
    ylabel('Probability', 'Interpreter', 'none');
    add_logstat_text(mu_los, sd_los, metricName, freqLabel);
    build_legend(hP_los, hN_los, hNb_los, hU_los, hUb_los, hPb_los);

    % ===== NLOS subplot =====
    subplot(1, 2, 2); hold on; grid on; box on;
    style_cdf_axes();

    nyu_nlos = clean_vals(nyu_vals(nyu_isNLOS));
    usc_nlos = clean_vals(usc_vals(usc_isNLOS));

    [hP_nlos, hN_nlos, hNb_nlos, hU_nlos, hUb_nlos, hPb_nlos, mu_nlos, sd_nlos] = ...
        plot_cdf_panel(nyu_nlos, usc_nlos, false, colorPooled, colorNYU, colorUSC);

    title(sprintf('NLOS Omni RMS %s %s', metricName, freqLabel), 'Interpreter', 'none');
    xlabel(sprintf('Omni RMS %s [%s]', metricName, unitLabel), 'Interpreter', 'tex');
    ylabel('Probability', 'Interpreter', 'none');
    add_logstat_text(mu_nlos, sd_nlos, metricName, freqLabel);
    build_legend(hP_nlos, hN_nlos, hNb_nlos, hU_nlos, hUb_nlos, hPb_nlos);

    % === Save .jpg ===
    jpgPath = fullfile(outputFolder, [baseName '.jpg']);
    exportgraphics(fig, jpgPath, 'Resolution', 300, 'BackgroundColor', 'white');
    fprintf('Saved: %s\n', jpgPath);

    % === Save .png (paper \includegraphics uses OmniDS_merged.jpg, but we
    %    also emit .png so sync_paper_figs can pick either) ===
    pngPath = fullfile(outputFolder, [baseName '.png']);
    exportgraphics(fig, pngPath, 'Resolution', 300, 'BackgroundColor', 'white');
    fprintf('Saved: %s\n', pngPath);

    % === Save .fig (editable) ===
    figPath = fullfile(outputFolder, [baseName '.fig']);
    saveas(fig, figPath);
    fprintf('Saved: %s\n', figPath);

    close(fig);
end

function [hPooled, hNYU, hNYUband, hUSC, hUSCband, hPooledBand, pooledMu, pooledSd] = ...
    plot_cdf_panel(nyuVals, uscVals, isLOS, cPooled, cNYU, cUSC)

    pooledVals = [nyuVals; uscVals];
    pooledVals = pooledVals(isfinite(pooledVals) & pooledVals > 0);

    [xN, fN, fNlo, fNhi] = ecdf_with_dkw(nyuVals);
    [xU, fU, fUlo, fUhi] = ecdf_with_dkw(uscVals);
    [xP, fP, fPlo, fPhi] = ecdf_with_dkw(pooledVals);

    % Bands first (behind everything)
    hNYUband    = plot_band(xN, fNlo, fNhi, cNYU, 0.12);
    hUSCband    = plot_band(xU, fUlo, fUhi, cUSC, 0.12);
    hPooledBand = plot_band(xP, fPlo, fPhi, cPooled, 0.10);

    % Dashed blue boundary lines for pooled DKW band
    if ~isempty(xP)
        hPooledBand = plot(xP, fPlo, '--', 'Color', cPooled, 'LineWidth', 1.5);
        plot(xP, fPhi, '--', 'Color', cPooled, 'LineWidth', 1.5);
    end

    % CDF lines on top
    hNYU = plot(xN, fN, 'Color', cNYU, 'LineWidth', 2.2);
    hUSC = plot(xU, fU, 'Color', cUSC, 'LineWidth', 2.2);

    % Pooled scatter on top
    if isLOS
        mk = 'o';
    else
        mk = 'd';
    end
    hPooled = scatter(xP, fP, 70, mk, 'MarkerEdgeColor', cPooled, ...
        'LineWidth', 2.0, 'MarkerFaceColor', 'none');

    if ~isempty(pooledVals)
        xlim([0, ceil(1.05 * max(pooledVals))]);
    end
    ylim([0, 1]);

    % Log10-domain pooled stats
    pooledMu = NaN;
    pooledSd = NaN;
    if ~isempty(pooledVals)
        lv = log10(pooledVals);
        pooledMu = mean(lv);
        pooledSd = std(lv);
    end
end

function style_cdf_axes()
    ax = gca;
    ax.FontSize = 19;
    ax.GridAlpha = 0.2;
    ax.LineWidth = 0.8;
end

function vals = clean_vals(vals)
    vals = vals(:);
    vals = vals(isfinite(vals) & vals > 0);
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

function add_logstat_text(mu, sigma, metricName, freqLabel)
    if ~isfinite(mu) || ~isfinite(sigma)
        return;
    end
    freqSub = strrep(freqLabel, '6.75 GHz', '6.75');
    txt = sprintf('\\mu(lg(%s^{USC+NYU}_{%s})) = %.2f\n\\sigma(lg(%s^{USC+NYU}_{%s})) = %.2f', ...
        metricName, freqSub, mu, metricName, freqSub, sigma);
    text(0.97, 0.58, txt, 'Units', 'normalized', ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', ...
        'FontSize', 17, 'FontWeight', 'bold', 'BackgroundColor', 'none', ...
        'Interpreter', 'tex');
end

function build_legend(hPooled, hNYU, hNYUband, hUSC, hUSCband, hPooledBand)
    handles = [];
    labels = {};

    if ~isempty(hPooled) && isvalid(hPooled)
        handles(end+1) = hPooled;
        labels{end+1} = 'USC+NYU';
    end
    if ~isempty(hNYU) && isvalid(hNYU)
        handles(end+1) = hNYU;
        labels{end+1} = 'NYU';
    end
    if ~isempty(hNYUband) && isvalid(hNYUband)
        handles(end+1) = hNYUband;
        labels{end+1} = 'NYU 95% band';
    end
    if ~isempty(hUSC) && isvalid(hUSC)
        handles(end+1) = hUSC;
        labels{end+1} = 'USC';
    end
    if ~isempty(hUSCband) && isvalid(hUSCband)
        handles(end+1) = hUSCband;
        labels{end+1} = 'USC 95% band';
    end
    if ~isempty(hPooledBand) && isvalid(hPooledBand)
        handles(end+1) = hPooledBand;
        labels{end+1} = 'USC+NYU 95% band';
    end

    if ~isempty(handles)
        legend(handles, labels, 'Location', 'southeast', 'FontSize', 15);
    end
end

%% ========================================================================
%  AS CDF Merged: ASA and ASD CDFs matching the DS merged figure style
%  ========================================================================
%
%  PURPOSE: Generate CDF plots for Angular Spread (ASA, ASD) at both
%           sub-THz (142/145 GHz) and FR1(C) (6.75 GHz) frequencies,
%           matching the visual style of cdf_ci_pl_analysis_DS_ref.m
%
%  OUTPUT FIGURES (saved to paper figures directory as .jpg AND .fig):
%    - OmniASA_merged.jpg/.fig   (sub-THz ASA CDF: LOS | NLOS)
%    - OmniASA_merged7.jpg/.fig  (6.75 GHz ASA CDF: LOS | NLOS)
%    - OmniASD_merged.jpg/.fig   (sub-THz ASD CDF: LOS | NLOS)
%    - OmniASD_merged7.jpg/.fig  (6.75 GHz ASD CDF: LOS | NLOS)
%
%  STYLE: Violet (NYU) / Red (USC) lines + 95% DKW bands, Blue scatter
%         (Pooled). Lognormal mu/sigma annotations for pooled data.
%         Matches cdf_ci_pl_analysis_DS_ref.m figure style exactly.
%
%  Author: Mingjun Ying
%  Date: February 2026
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

% Colors matching DS reference script (cdf_ci_pl_analysis_DS_ref.m)
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

% 6.75 GHz NYU
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

% --- Sub-THz ASA ---
generate_as_cdf_figure(...
    'ASA', 'sub-THz', ...
    nyu142_r.ASA_NYU_10dB, usc145_r.ASA_USC, ...
    nyu142_isLOS, nyu142_isNLOS, usc145_isLOS, usc145_isNLOS, ...
    colorNYU, colorUSC, colorPooled, ...
    figOutputPath, 'OmniASA_merged');

% --- Sub-THz ASD ---
generate_as_cdf_figure(...
    'ASD', 'sub-THz', ...
    nyu142_r.ASD_NYU_10dB, usc145_r.ASD_USC, ...
    nyu142_isLOS, nyu142_isNLOS, usc145_isLOS, usc145_isNLOS, ...
    colorNYU, colorUSC, colorPooled, ...
    figOutputPath, 'OmniASD_merged');

% --- 6.75 GHz ASA ---
% NYU 7 GHz: NYU method (10dB PAS) with NYU threshold on NYU data
% USC 7 GHz: USC method (no threshold) on USC data
generate_as_cdf_figure(...
    'ASA', '6.75 GHz', ...
    nyu7_r.ASA_NYUthr_N10, usc7_r.ASA_USC, ...
    nyu7_isLOS, nyu7_isNLOS, usc7_isLOS, usc7_isNLOS, ...
    colorNYU, colorUSC, colorPooled, ...
    figOutputPath, 'OmniASA_merged7');

% --- 6.75 GHz ASD ---
generate_as_cdf_figure(...
    'ASD', '6.75 GHz', ...
    nyu7_r.ASD_NYUthr_N10, usc7_r.ASD_USC, ...
    nyu7_isLOS, nyu7_isNLOS, usc7_isLOS, usc7_isNLOS, ...
    colorNYU, colorUSC, colorPooled, ...
    figOutputPath, 'OmniASD_merged7');

fprintf('\nAll figures saved to: %s\n', figOutputPath);
fprintf('Done!\n');

%% ========================================================================
%  HELPER FUNCTIONS
%  ========================================================================

function generate_as_cdf_figure(metricName, freqLabel, ...
    nyu_vals, usc_vals, nyu_isLOS, nyu_isNLOS, usc_isLOS, usc_isNLOS, ...
    colorNYU, colorUSC, colorPooled, ...
    outputFolder, baseName)
    % Generate a single AS CDF figure with LOS | NLOS subplots
    % Style matches cdf_ci_pl_analysis_DS_ref.m exactly
    % Saves both .jpg and .fig files

    fig = figure('Position', [140, 140, 1400, 520], 'Color', 'w');

    % ===== LOS subplot =====
    subplot(1, 2, 1); hold on; grid on; box on;
    style_cdf_axes();

    nyu_los = clean_vals(nyu_vals(nyu_isLOS));
    usc_los = clean_vals(usc_vals(usc_isLOS));

    [hP_los, hN_los, hNb_los, hU_los, hUb_los, hPb_los, mu_los, sd_los] = ...
        plot_cdf_panel(nyu_los, usc_los, true, colorPooled, colorNYU, colorUSC);

    title(sprintf('LOS Omni RMS %s %s', metricName, freqLabel), 'Interpreter', 'none');
    xlabel(sprintf('Omni RMS %s (%c)', metricName, char(176)), 'Interpreter', 'tex');
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
    xlabel(sprintf('Omni RMS %s (%c)', metricName, char(176)), 'Interpreter', 'tex');
    ylabel('Probability', 'Interpreter', 'none');
    add_logstat_text(mu_nlos, sd_nlos, metricName, freqLabel);
    build_legend(hP_nlos, hN_nlos, hNb_nlos, hU_nlos, hUb_nlos, hPb_nlos);

    % === Save .jpg ===
    jpgPath = fullfile(outputFolder, [baseName '.jpg']);
    exportgraphics(fig, jpgPath, 'Resolution', 300, 'BackgroundColor', 'white');
    fprintf('Saved: %s\n', jpgPath);

    % === Save .png (paper \includegraphics uses .png for OmniASA/ASD_merged) ===
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
    % Plot a single CDF panel (LOS or NLOS) matching the DS reference style

    pooledVals = [nyuVals; uscVals];
    pooledVals = pooledVals(isfinite(pooledVals) & pooledVals > 0);

    [xN, fN, fNlo, fNhi] = ecdf_with_dkw(nyuVals);
    [xU, fU, fUlo, fUhi] = ecdf_with_dkw(uscVals);
    [xP, fP, fPlo, fPhi] = ecdf_with_dkw(pooledVals);

    % Bands first (behind everything) — alpha 0.12 for individual, 0.10 for pooled
    hNYUband    = plot_band(xN, fNlo, fNhi, cNYU, 0.12);
    hUSCband    = plot_band(xU, fUlo, fUhi, cUSC, 0.12);
    hPooledBand = plot_band(xP, fPlo, fPhi, cPooled, 0.10);

    % Dashed blue boundary lines for pooled DKW band (matching DS merged style)
    if ~isempty(xP)
        hPooledBand = plot(xP, fPlo, '--', 'Color', cPooled, 'LineWidth', 1.5);
        plot(xP, fPhi, '--', 'Color', cPooled, 'LineWidth', 1.5);
    end

    % CDF lines on top — linewidth 2.2
    hNYU = plot(xN, fN, 'Color', cNYU, 'LineWidth', 2.2);
    hUSC = plot(xU, fU, 'Color', cUSC, 'LineWidth', 2.2);

    % Pooled scatter on top — circles for LOS, diamonds for NLOS
    if isLOS
        mk = 'o';
    else
        mk = 'd';
    end
    hPooled = scatter(xP, fP, 70, mk, 'MarkerEdgeColor', cPooled, ...
        'LineWidth', 2.0, 'MarkerFaceColor', 'none');

    % Set x-limits with margin
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
    % Remove NaN, Inf, and zero values
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
    % Position above the southeast legend
    text(0.97, 0.58, txt, 'Units', 'normalized', ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', ...
        'FontSize', 17, 'FontWeight', 'bold', 'BackgroundColor', 'none', ...
        'Interpreter', 'tex');
end

function build_legend(hPooled, hNYU, hNYUband, hUSC, hUSCband, hPooledBand)
    % Build legend matching DS reference style
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

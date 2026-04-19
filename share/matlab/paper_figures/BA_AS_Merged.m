%% ========================================================================
%  BA_AS_Merged: Bland-Altman plots for ASA and ASD
%  ========================================================================
%
%  PURPOSE: Generate Bland-Altman plots for Angular Spread (ASA, ASD)
%           at sub-THz (142/145 GHz) and FR1(C) (6.75/7 GHz),
%           matching the dual-axis style of BA_PL.jpg / BA_DS.jpg
%
%  For AS the difference = NYU method (10 dB PAS) - USC method
%  N3 = NYU data processed by both methods
%  U3 = USC data processed by both methods
%
%  OUTPUT FIGURES (saved to paper figures directory as .jpg AND .fig):
%    - BA_ASA.jpg/.fig     (sub-THz ASA Bland-Altman: N3 vs U3)
%    - BA_ASA7.jpg/.fig    (6.75 GHz ASA Bland-Altman: N3 vs U3)
%    - BA_ASD.jpg/.fig     (sub-THz ASD Bland-Altman: N3 vs U3)
%    - BA_ASD7.jpg/.fig    (6.75 GHz ASD Bland-Altman: N3 vs U3)
%
%  STYLE: Matches BA_PL.jpg / BA_DS.jpg exactly:
%    - Dual y-axes (yyaxis): blue left (N3), red right (U3)
%    - Blue circles for N3, salmon squares for U3
%    - Bias + 1.96 SD lines for each group
%    - White background, font size 14
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

% Data paths — sub-THz (.mat files written by the raw-processing scripts)
nyu142Path = fullfile(U.results_nyu_142, 'all_comparison_results.mat');
usc145Path = fullfile(U.results_usc_145, 'USC145GHz_Full_Results.mat');

% Data paths — 6.75 GHz (.mat files)
nyu7Path = fullfile(U.results_nyu_7, 'all_comparison_results.mat');
usc7Path = fullfile(U.results_usc_7, 'USC7GHz_Full_Results.mat');

% Colors matching BA_PL.jpg style
colorN3     = [0 0.45 0.74];       % Blue for N3 (NYU data)
colorN3fill = [0.60 0.78 0.92];    % Light blue fill
colorU3     = [0.85 0.33 0.10];    % Red/orange for U3 (USC data)
colorU3fill = [0.98 0.78 0.68];    % Light salmon fill

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

fprintf('  Sub-THz: NYU %d locations, USC %d locations\n', ...
    height(nyu142_r), height(usc145_r));
fprintf('  6.75 GHz: NYU %d locations, USC %d locations\n', ...
    height(nyu7_r), height(usc7_r));

%% ========================================================================
%  GENERATE FIGURES
%  ========================================================================

% --- Sub-THz ASA ---
% N3: NYU data — NYU method (ASA_NYU_10dB) vs USC method (ASA_USC)
% U3: USC data — NYU method (ASA_NYU_10dB) vs USC method (ASA_USC)
generate_ba_figure(...
    'ASA', '142 GHz', ...
    nyu142_r.ASA_NYU_10dB, nyu142_r.ASA_USC, ...   % N3: NYU data
    usc145_r.ASA_NYU_10dB, usc145_r.ASA_USC, ...   % U3: USC data
    'NYU 10 dB PAS', 'USC', ...
    colorN3, colorN3fill, colorU3, colorU3fill, ...
    figOutputPath, 'BA_ASA');

% --- Sub-THz ASD ---
generate_ba_figure(...
    'ASD', '142 GHz', ...
    nyu142_r.ASD_NYU_10dB, nyu142_r.ASD_USC, ...   % N3: NYU data
    usc145_r.ASD_NYU_10dB, usc145_r.ASD_USC, ...   % U3: USC data
    'NYU 10 dB PAS', 'USC', ...
    colorN3, colorN3fill, colorU3, colorU3fill, ...
    figOutputPath, 'BA_ASD');

% --- 6.75 GHz ASA ---
% N3: NYU data — NYU method (ASA_NYUthr_N10) vs USC method (ASA_NYUthr_U)
% U3: USC data — NYU method (ASA_NYU_10dB) vs USC method (ASA_USC)
generate_ba_figure(...
    'ASA', '7 GHz', ...
    nyu7_r.ASA_NYUthr_N10, nyu7_r.ASA_NYUthr_U, ...  % N3: NYU data
    usc7_r.ASA_NYU_10dB, usc7_r.ASA_USC, ...          % U3: USC data
    'NYU 10 dB PAS', 'USC', ...
    colorN3, colorN3fill, colorU3, colorU3fill, ...
    figOutputPath, 'BA_ASA7');

% --- 6.75 GHz ASD ---
generate_ba_figure(...
    'ASD', '7 GHz', ...
    nyu7_r.ASD_NYUthr_N10, nyu7_r.ASD_NYUthr_U, ...  % N3: NYU data
    usc7_r.ASD_NYU_10dB, usc7_r.ASD_USC, ...          % U3: USC data
    'NYU 10 dB PAS', 'USC', ...
    colorN3, colorN3fill, colorU3, colorU3fill, ...
    figOutputPath, 'BA_ASD7');

fprintf('\nAll figures saved to: %s\n', figOutputPath);
fprintf('Done!\n');

%% ========================================================================
%  HELPER FUNCTIONS
%  ========================================================================

function generate_ba_figure(metricName, freqLabel, ...
    n3_methodA, n3_methodB, u3_methodA, u3_methodB, ...
    methodAname, methodBname, ...
    colorN3, colorN3fill, colorU3, colorU3fill, ...
    outputFolder, baseName)
    % Generate a single Bland-Altman figure with dual y-axis labels
    % Style matches BA_PL.jpg / BA_DS.jpg exactly
    %
    % All data plotted on ONE axis (no yyaxis desync issues).
    % A second transparent axis overlaid provides the right-side
    % colored ylabel and tick marks, with identical ylim/ytick.
    %
    % N3 = NYU data processed by both methods (left label, blue)
    % U3 = USC data processed by both methods (right label, red)
    %
    % Difference = method_B - method_A  (USC method - NYU method)
    % Mean = (method_A + method_B) / 2

    % Clean data
    v1 = isfinite(n3_methodA) & isfinite(n3_methodB) & n3_methodA > 0 & n3_methodB > 0;
    n3_a = n3_methodA(v1); n3_b = n3_methodB(v1);
    diff_n3 = n3_b - n3_a;   % USC method - NYU method
    mean_n3 = (n3_a + n3_b) / 2;

    v2 = isfinite(u3_methodA) & isfinite(u3_methodB) & u3_methodA > 0 & u3_methodB > 0;
    u3_a = u3_methodA(v2); u3_b = u3_methodB(v2);
    diff_u3 = u3_b - u3_a;   % USC method - NYU method
    mean_u3 = (u3_a + u3_b) / 2;

    % Statistics
    bias_n3 = mean(diff_n3);  sd_n3 = std(diff_n3);
    upper_n3 = bias_n3 + 1.96 * sd_n3;
    lower_n3 = bias_n3 - 1.96 * sd_n3;

    bias_u3 = mean(diff_u3);  sd_u3 = std(diff_u3);
    upper_u3 = bias_u3 + 1.96 * sd_u3;
    lower_u3 = bias_u3 - 1.96 * sd_u3;

    % Determine y-axis range
    allDiff = [diff_n3; diff_u3];
    allUpper = max([upper_n3, upper_u3]);
    allLower = min([lower_n3, lower_u3]);
    yMargin = 0.15 * (allUpper - allLower);
    if yMargin == 0, yMargin = 5; end
    yRange = [min([allDiff; allLower]) - yMargin, max([allDiff; allUpper]) + yMargin];

    % X-axis range
    allMeans = [mean_n3; mean_u3];
    xMargin = 0.05 * range(allMeans);
    if xMargin == 0, xMargin = 5; end
    xRange = [min(allMeans) - xMargin, max(allMeans) + xMargin];

    % Degree symbol
    degSym = char(176);

    % Create figure
    fig = figure('Position', [140, 140, 1200, 600], 'Color', 'w');
    ax1 = axes('Parent', fig);
    hold(ax1, 'on'); grid(ax1, 'on'); box(ax1, 'on');

    % ===== Plot ALL data on this single axis =====

    % Scatter N3 (blue circles)
    hN3 = scatter(ax1, mean_n3, diff_n3, 120, 'o', ...
        'MarkerFaceColor', colorN3fill, 'MarkerEdgeColor', colorN3, ...
        'LineWidth', 1.8);

    % Scatter U3 (orange squares)
    hU3 = scatter(ax1, mean_u3, diff_u3, 120, 's', ...
        'MarkerFaceColor', colorU3fill, 'MarkerEdgeColor', colorU3, ...
        'LineWidth', 1.8);

    % --- N3 bias and limits (blue) ---
    yline(ax1, bias_n3, '-', 'Color', colorN3, 'LineWidth', 2.0);
    yline(ax1, upper_n3, '--', 'Color', colorN3, 'LineWidth', 1.8);
    yline(ax1, lower_n3, '--', 'Color', colorN3, 'LineWidth', 1.8);

    % --- U3 bias and limits (red) ---
    yline(ax1, bias_u3, '-', 'Color', colorU3, 'LineWidth', 2.0);
    yline(ax1, upper_u3, '--', 'Color', colorU3, 'LineWidth', 1.8);
    yline(ax1, lower_u3, '--', 'Color', colorU3, 'LineWidth', 1.8);

    % Set axis limits
    xlim(ax1, xRange);
    ylim(ax1, yRange);

    % --- Text labels for N3 (left side, blue) ---
    text(ax1, xRange(1) + 0.02*range(xRange), bias_n3, ...
        'Bias (N3)', ...
        'Color', colorN3, 'FontSize', 32, 'FontWeight', 'bold', ...
        'VerticalAlignment', 'bottom', 'Interpreter', 'none');
    text(ax1, xRange(1) + 0.02*range(xRange), upper_n3, ...
        '+1.96 SD (N3)', ...
        'Color', colorN3, 'FontSize', 30, ...
        'VerticalAlignment', 'bottom', 'Interpreter', 'none');
    text(ax1, xRange(1) + 0.02*range(xRange), lower_n3, ...
        '-1.96 SD (N3)', ...
        'Color', colorN3, 'FontSize', 30, ...
        'VerticalAlignment', 'top', 'Interpreter', 'none');

    % --- Text labels for U3 (right side, red) ---
    text(ax1, xRange(2) - 0.02*range(xRange), bias_u3, ...
        'Bias (U3)', ...
        'Color', colorU3, 'FontSize', 32, 'FontWeight', 'bold', ...
        'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right', ...
        'Interpreter', 'none');
    text(ax1, xRange(2) - 0.02*range(xRange), upper_u3, ...
        '+1.96 SD (U3)', ...
        'Color', colorU3, 'FontSize', 30, ...
        'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right', ...
        'Interpreter', 'none');
    text(ax1, xRange(2) - 0.02*range(xRange), lower_u3, ...
        '-1.96 SD (U3)', ...
        'Color', colorU3, 'FontSize', 30, ...
        'VerticalAlignment', 'top', 'HorizontalAlignment', 'right', ...
        'Interpreter', 'none');

    % --- Left axis label (blue) ---
    ylabel(ax1, sprintf('N3: NYU Data | %s - %s', methodBname, methodAname), ...
        'FontSize', 34, 'Color', colorN3, 'Interpreter', 'none');
    set(ax1, 'YColor', colorN3, 'FontSize', 24);

    % --- Right axis label (red) via overlaid transparent axis ---
    ax2 = axes('Parent', fig, 'Position', ax1.Position, ...
        'YAxisLocation', 'right', 'Color', 'none', ...
        'XTick', [], 'Box', 'off');
    ax2.YLim = yRange;
    ax2.YTick = ax1.YTick;  % Same ticks as left axis
    ylabel(ax2, sprintf('U3: USC Data | %s - %s', methodBname, methodAname), ...
        'FontSize', 34, 'Color', colorU3, 'Interpreter', 'none');
    set(ax2, 'YColor', colorU3, 'FontSize', 24);
    linkaxes([ax1, ax2], 'y');  % Keep them linked

    % --- Common labels ---
    xlabel(ax1, sprintf('Mean of %s [%s] ((%s + %s)/2)', ...
        metricName, degSym, methodAname, methodBname), ...
        'FontSize', 34, 'Interpreter', 'none');

    title(ax1, sprintf('Bland-Altman: Omni %s (N3 vs U3) @ %s', metricName, freqLabel), ...
        'FontSize', 36, 'FontWeight', 'bold', 'Interpreter', 'none');

    % Legend
    legend(ax1, [hN3, hU3], ...
        {sprintf('N3: NYU Data | %s - %s', methodBname, methodAname), ...
         sprintf('U3: USC Data | %s - %s', methodBname, methodAname)}, ...
        'Location', 'best', 'FontSize', 30, 'Interpreter', 'none');

    % ===== Save =====
    jpgPath = fullfile(outputFolder, [baseName '.jpg']);
    exportgraphics(fig, jpgPath, 'Resolution', 300, 'BackgroundColor', 'white');
    fprintf('Saved: %s\n', jpgPath);

    pngPath = fullfile(outputFolder, [baseName '.png']);
    exportgraphics(fig, pngPath, 'Resolution', 300, 'BackgroundColor', 'white');
    fprintf('Saved: %s\n', pngPath);

    figPath = fullfile(outputFolder, [baseName '.fig']);
    saveas(fig, figPath);
    fprintf('Saved: %s\n', figPath);

    % Print statistics
    fprintf('  %s @ %s:\n', metricName, freqLabel);
    fprintf('    N3: Bias=%+.2f, SD=%.2f, n=%d\n', bias_n3, sd_n3, length(diff_n3));
    fprintf('    U3: Bias=%+.2f, SD=%.2f, n=%d\n', bias_u3, sd_u3, length(diff_u3));

    close(fig);
end

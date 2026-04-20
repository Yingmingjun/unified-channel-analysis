%% ========================================================================
%  BA_AS_Merged: Bland-Altman plots for ASA and ASD
%  ========================================================================
%
%  PURPOSE: Generate Bland-Altman plots for Angular Spread (ASA, ASD)
%           at sub-THz (142/145 GHz) and FR1(C) (6.75/7 GHz). Visual
%           style is intentionally kept identical to
%           fig03_bland_altman_pl_ds.m so Fig 3 and Fig 4 share a
%           single look in the paper: single y-axis, inline yline
%           labels, per-side numeric corner boxes, large legible
%           markers, and matching font sizes.
%
%  For AS the difference = USC method - NYU method (10 dB PAS)
%  N3 = NYU data processed by both methods
%  U3 = USC data processed by both methods
%
%  OUTPUT FIGURES (saved to paper figures directory as .jpg/.png/.fig):
%    - BA_ASA.jpg/.png/.fig    (sub-THz ASA Bland-Altman: N3 + U3)
%    - BA_ASA7.jpg/.png/.fig   (6.75 GHz ASA)
%    - BA_ASD.jpg/.png/.fig    (sub-THz ASD)
%    - BA_ASD7.jpg/.png/.fig   (6.75 GHz ASD)
%
%  Author: Mingjun Ying
%  Date: April 2026
%  ========================================================================

clear variables; close all; clc;

%% ========================================================================
%  CONFIGURATION
%  ========================================================================

U = paths();
figOutputPath = U.paper_fig_out;
if ~exist(figOutputPath, 'dir'), mkdir(figOutputPath); end

% Data paths --- sub-THz (.mat files written by the raw-processing scripts)
nyu142Path = fullfile(U.results_nyu_142, 'all_comparison_results.mat');
usc145Path = fullfile(U.results_usc_145, 'USC145GHz_Full_Results.mat');

% Data paths --- 6.75 GHz (.mat files)
nyu7Path = fullfile(U.results_nyu_7, 'all_comparison_results.mat');
usc7Path = fullfile(U.results_usc_7, 'USC7GHz_Full_Results.mat');

% Colors --- MUST match fig03_bland_altman_pl_ds.m exactly.
colorN3     = [0.00 0.45 0.74];    % NYU blue
colorN3fill = [0.60 0.78 0.92];    % light blue fill
colorU3     = [0.85 0.33 0.10];    % USC orange
colorU3fill = [0.98 0.78 0.68];    % light salmon fill

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
% N3: NYU data --- NYU method (ASA_NYU_10dB) vs USC method (ASA_USC)
% U3: USC data --- NYU method (ASA_NYU_10dB) vs USC method (ASA_USC)
generate_ba_figure(...
    'ASA', 'sub-THz', ...
    nyu142_r.ASA_NYU_10dB, nyu142_r.ASA_USC, ...   % N3: NYU data
    usc145_r.ASA_NYU_10dB, usc145_r.ASA_USC, ...   % U3: USC data
    colorN3, colorN3fill, colorU3, colorU3fill, ...
    figOutputPath, 'BA_ASA');

% --- Sub-THz ASD ---
generate_ba_figure(...
    'ASD', 'sub-THz', ...
    nyu142_r.ASD_NYU_10dB, nyu142_r.ASD_USC, ...   % N3: NYU data
    usc145_r.ASD_NYU_10dB, usc145_r.ASD_USC, ...   % U3: USC data
    colorN3, colorN3fill, colorU3, colorU3fill, ...
    figOutputPath, 'BA_ASD');

% --- 6.75 GHz ASA ---
% N3 (NYU data) 6.75 GHz is keyed off NYU-threshold columns, since
% that is the per-institution threshold already applied upstream.
generate_ba_figure(...
    'ASA', '6.75 GHz', ...
    nyu7_r.ASA_NYUthr_N10, nyu7_r.ASA_NYUthr_U, ...  % N3: NYU data
    usc7_r.ASA_NYU_10dB, usc7_r.ASA_USC, ...          % U3: USC data
    colorN3, colorN3fill, colorU3, colorU3fill, ...
    figOutputPath, 'BA_ASA7');

% --- 6.75 GHz ASD ---
generate_ba_figure(...
    'ASD', '6.75 GHz', ...
    nyu7_r.ASD_NYUthr_N10, nyu7_r.ASD_NYUthr_U, ...  % N3: NYU data
    usc7_r.ASD_NYU_10dB, usc7_r.ASD_USC, ...          % U3: USC data
    colorN3, colorN3fill, colorU3, colorU3fill, ...
    figOutputPath, 'BA_ASD7');

fprintf('\nAll figures saved to: %s\n', figOutputPath);
fprintf('Done!\n');

%% ========================================================================
%  HELPER FUNCTIONS
%  ========================================================================

function generate_ba_figure(metricName, freqLabel, ...
    n3_methodA, n3_methodB, u3_methodA, u3_methodB, ...
    colorN3, colorN3fill, colorU3, colorU3fill, ...
    outputFolder, baseName)
    % Generate one Bland-Altman figure. Visual style matches
    % matlab/figures/fig03_bland_altman_pl_ds.m one-for-one so that
    % the 8 BA panels in the paper (4 PL/DS + 4 ASA/ASD) share a
    % single look.
    %
    % Difference convention: USC method - NYU method (per paper
    % convention; same as fig03).

    % Clean data (both finite & positive --- AS is non-negative)
    v1 = isfinite(n3_methodA) & isfinite(n3_methodB) & ...
         n3_methodA > 0 & n3_methodB > 0;
    n3_a = n3_methodA(v1); n3_b = n3_methodB(v1);
    diff_n3 = n3_b - n3_a;            % USC method - NYU method
    mean_n3 = (n3_a + n3_b) / 2;

    v2 = isfinite(u3_methodA) & isfinite(u3_methodB) & ...
         u3_methodA > 0 & u3_methodB > 0;
    u3_a = u3_methodA(v2); u3_b = u3_methodB(v2);
    diff_u3 = u3_b - u3_a;
    mean_u3 = (u3_a + u3_b) / 2;

    % Statistics
    bias_n3 = mean(diff_n3);  sd_n3 = std(diff_n3);
    upper_n3 = bias_n3 + 1.96 * sd_n3;
    lower_n3 = bias_n3 - 1.96 * sd_n3;

    bias_u3 = mean(diff_u3);  sd_u3 = std(diff_u3);
    upper_u3 = bias_u3 + 1.96 * sd_u3;
    lower_u3 = bias_u3 - 1.96 * sd_u3;

    % -----------------------------------------------------------------
    % Figure (style mirrors fig03 verbatim)
    % -----------------------------------------------------------------
    fig = figure('Position', [100 100 1100 600], 'Color', 'w');
    hold on; grid on; box on;
    set(gca, 'FontSize', 24, 'LineWidth', 1.0);

    % Scatter N3 (NYU) blue circles
    scatter(mean_n3, diff_n3, 200, 'o', ...
            'MarkerFaceColor', colorN3fill, ...
            'MarkerEdgeColor', colorN3, 'LineWidth', 2.0, ...
            'DisplayName', sprintf('N3: NYU data (n=%d)', numel(diff_n3)));
    % Scatter U3 (USC) orange squares
    scatter(mean_u3, diff_u3, 200, 's', ...
            'MarkerFaceColor', colorU3fill, ...
            'MarkerEdgeColor', colorU3, 'LineWidth', 2.0, ...
            'DisplayName', sprintf('U3: USC data (n=%d)', numel(diff_u3)));

    % N3 bias + 1.96 SD lines with inline labels on the LEFT
    yline(bias_n3,  '-',  'Bias (N3)', 'Color', colorN3, 'LineWidth', 2.0, ...
          'HandleVisibility', 'off', 'FontSize', 18, 'FontWeight', 'bold', ...
          'LabelHorizontalAlignment', 'left', 'Interpreter', 'none');
    yline(upper_n3, '--', '+1.96 SD (N3)', 'Color', colorN3, 'LineWidth', 1.6, ...
          'HandleVisibility', 'off', 'FontSize', 16, ...
          'LabelHorizontalAlignment', 'left', 'Interpreter', 'none');
    yline(lower_n3, '--', '-1.96 SD (N3)', 'Color', colorN3, 'LineWidth', 1.6, ...
          'HandleVisibility', 'off', 'FontSize', 16, ...
          'LabelHorizontalAlignment', 'left', 'Interpreter', 'none');
    % U3 bias + 1.96 SD lines with inline labels on the RIGHT
    yline(bias_u3,  '-',  'Bias (U3)', 'Color', colorU3, 'LineWidth', 2.0, ...
          'HandleVisibility', 'off', 'FontSize', 18, 'FontWeight', 'bold', ...
          'LabelHorizontalAlignment', 'right', 'Interpreter', 'none');
    yline(upper_u3, '--', '+1.96 SD (U3)', 'Color', colorU3, 'LineWidth', 1.6, ...
          'HandleVisibility', 'off', 'FontSize', 16, ...
          'LabelHorizontalAlignment', 'right', 'Interpreter', 'none');
    yline(lower_u3, '--', '-1.96 SD (U3)', 'Color', colorU3, 'LineWidth', 1.6, ...
          'HandleVisibility', 'off', 'FontSize', 16, ...
          'LabelHorizontalAlignment', 'right', 'Interpreter', 'none');
    yline(0, ':', 'Color', [0.5 0.5 0.5], 'LineWidth', 0.8, ...
          'HandleVisibility', 'off');

    xlabel(sprintf('Mean of paired %s [%s]', metricName, char(176)), ...
           'FontSize', 26);
    ylabel(sprintf('Difference (USC - NYU) [%s]', char(176)), 'FontSize', 26);
    title(sprintf('Bland-Altman: Omni %s (%s)', metricName, freqLabel), ...
          'FontSize', 28);
    legend('Location', 'southeast', 'FontSize', 22);

    % Per-side bias / 1.96 SD numeric corner boxes (same as fig03).
    text(0.02, 0.98, ...
         sprintf('N3 bias = %+.2f %s\n1.96 SD = %.2f', ...
                 bias_n3, char(176), 1.96 * sd_n3), ...
         'Units', 'normalized', 'Color', colorN3, ...
         'HorizontalAlignment', 'left', 'VerticalAlignment', 'top', ...
         'FontSize', 22, 'FontWeight', 'bold', ...
         'BackgroundColor', 'w', 'EdgeColor', colorN3);
    text(0.98, 0.98, ...
         sprintf('U3 bias = %+.2f %s\n1.96 SD = %.2f', ...
                 bias_u3, char(176), 1.96 * sd_u3), ...
         'Units', 'normalized', 'Color', colorU3, ...
         'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', ...
         'FontSize', 22, 'FontWeight', 'bold', ...
         'BackgroundColor', 'w', 'EdgeColor', colorU3);

    % ===== Save =====
    jpgPath = fullfile(outputFolder, [baseName '.jpg']);
    exportgraphics(fig, jpgPath, 'Resolution', 300, 'BackgroundColor', 'white');
    fprintf('Saved: %s\n', jpgPath);

    pngPath = fullfile(outputFolder, [baseName '.png']);
    exportgraphics(fig, pngPath, 'Resolution', 300, 'BackgroundColor', 'white');
    fprintf('Saved: %s\n', pngPath);

    pdfPath = fullfile(outputFolder, [baseName '.pdf']);
    exportgraphics(fig, pdfPath, 'ContentType', 'vector', 'BackgroundColor', 'white');
    fprintf('Saved: %s\n', pdfPath);

    figPath = fullfile(outputFolder, [baseName '.fig']);
    saveas(fig, figPath);
    fprintf('Saved: %s\n', figPath);

    % Print statistics
    fprintf('  %s @ %s:\n', metricName, freqLabel);
    fprintf('    N3: Bias=%+.2f, SD=%.2f, n=%d\n', ...
            bias_n3, sd_n3, length(diff_n3));
    fprintf('    U3: Bias=%+.2f, SD=%.2f, n=%d\n', ...
            bias_u3, sd_u3, length(diff_u3));

    close(fig);
end

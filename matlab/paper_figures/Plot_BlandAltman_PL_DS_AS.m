%% Bland-Altman analysis for NYU vs USC processing methods
% =========================================================================
% Compares NYU SUM method vs USC perDelayMax method on both datasets:
%   - NYU 142 GHz data: NYU142GHz_Method_Comparison_Results.xlsx
%   - USC 145 GHz data: USC145GHz_Full_Results.xlsx
%
% Generates Bland-Altman plots for: PL, DS, ASA (10 dB threshold), ASD
%
% For each metric, the difference is: NYU method - USC method
%   PL:  PL_NYU_SUM - PL_USC_perDelayMax  (NYU data)
%        PL_NYU     - PL_USC              (USC data)
%   DS:  DS_NYU_SUM - DS_USC_perDelayMax  (NYU data)
%        DS_NYU     - DS_USC              (USC data)
%   ASA: ASA_NYU_10dB - ASA_USC           (both datasets)
%   ASD: ASD_NYU_10dB - ASD_USC           (both datasets)
%
% Saves combined figures to: BlandAltman_Figures/ subfolder
%
% Author: Mingjun Ying
% Updated: February 2026
% =========================================================================

clear variables;
close all;
clc;

%% ===== DATA PATHS =====
U = paths();
nyuPath = fullfile(U.results_nyu_142, 'NYU142GHz_Method_Comparison_Results.xlsx');
uscPath = fullfile(U.results_usc_145, 'USC145GHz_Full_Results.xlsx');

% Output folder for saved figures (inside the unified paper-figure output dir)
saveDir = fullfile(U.paper_fig_out, 'BlandAltman_Figures');
if ~isfolder(saveDir)
    mkdir(saveDir);
    fprintf('Created output folder: %s\n', saveDir);
end

fprintf('Loading NYU data from: %s\n', nyuPath);
fprintf('Loading USC data from: %s\n', uscPath);

% Read tables
nyu = readtable(nyuPath);
usc = readtable(uscPath);

fprintf('  NYU: %d locations loaded\n', height(nyu));
fprintf('  USC: %d locations loaded\n', height(usc));

%% ===== DEFINE METRIC PAIRS =====
% Each row: {metricName, NYU_colA, NYU_colB, USC_colA, USC_colB, unitLabel, fileTag}
%   colA = NYU method value, colB = USC method value
%   unitLabel uses LaTeX-safe strings (no bare degree symbol)
%   fileTag  is used for filenames (no special characters)

metrics = {
    'Omni PL',  'PL_NYU_SUM_dB',  'PL_USC_perDelayMax_dB', ...
                'PL_NYU_dB',       'PL_USC_dB',              'dB',   'PL';
    'Omni DS',  'DS_NYU_SUM_ns',  'DS_USC_perDelayMax_ns', ...
                'DS_NYU_ns',       'DS_USC_ns',              'ns',   'DS';
    'ASA',      'ASA_NYU_10dB',   'ASA_USC', ...
                'ASA_NYU_10dB',   'ASA_USC',                 'deg',  'ASA';
    'ASD',      'ASD_NYU_10dB',   'ASD_USC', ...
                'ASD_NYU_10dB',   'ASD_USC',                 'deg',  'ASD';
};

%% ===== INDIVIDUAL BLAND-ALTMAN PLOTS =====
fprintf('\n');
fprintf('===================================================================\n');
fprintf('  INDIVIDUAL BLAND-ALTMAN PLOTS\n');
fprintf('===================================================================\n');

for m = 1:size(metrics, 1)
    metricName = metrics{m, 1};
    unitLabel  = metrics{m, 6};

    % --- NYU Data ---
    nyuColA = metrics{m, 2};
    nyuColB = metrics{m, 3};
    if ismember(nyuColA, nyu.Properties.VariableNames) && ...
       ismember(nyuColB, nyu.Properties.VariableNames)
        a = nyu.(nyuColA);
        b = nyu.(nyuColB);
        valid = isfinite(a) & isfinite(b);
        label = sprintf('NYU 142 GHz - %s [%s]', metricName, unitLabel);
        plot_bland_altman(a(valid), b(valid), label, 'NYU method', 'USC method', unitLabel);
    else
        warning('NYU columns not found for %s: %s, %s', metricName, nyuColA, nyuColB);
    end

    % --- USC Data ---
    uscColA = metrics{m, 4};
    uscColB = metrics{m, 5};
    if ismember(uscColA, usc.Properties.VariableNames) && ...
       ismember(uscColB, usc.Properties.VariableNames)
        a = usc.(uscColA);
        b = usc.(uscColB);
        valid = isfinite(a) & isfinite(b);
        label = sprintf('USC 145 GHz - %s [%s]', metricName, unitLabel);
        plot_bland_altman(a(valid), b(valid), label, 'NYU method', 'USC method', unitLabel);
    else
        warning('USC columns not found for %s: %s, %s', metricName, uscColA, uscColB);
    end
end

%% ===== COMBINED PLOTS (NYU vs USC on same axes) — SAVED =====
fprintf('\n');
fprintf('===================================================================\n');
fprintf('  COMBINED BLAND-ALTMAN PLOTS (NYU 142 GHz vs USC 145 GHz)\n');
fprintf('===================================================================\n');

for m = 1:size(metrics, 1)
    metricName = metrics{m, 1};
    unitLabel  = metrics{m, 6};
    fileTag    = metrics{m, 7};

    nyuColA = metrics{m, 2};  nyuColB = metrics{m, 3};
    uscColA = metrics{m, 4};  uscColB = metrics{m, 5};

    hasNYU = ismember(nyuColA, nyu.Properties.VariableNames) && ...
             ismember(nyuColB, nyu.Properties.VariableNames);
    hasUSC = ismember(uscColA, usc.Properties.VariableNames) && ...
             ismember(uscColB, usc.Properties.VariableNames);

    if hasNYU && hasUSC
        nA = nyu.(nyuColA); nB = nyu.(nyuColB);
        nV = isfinite(nA) & isfinite(nB);
        uA = usc.(uscColA); uB = usc.(uscColB);
        uV = isfinite(uA) & isfinite(uB);

        titleStr = sprintf('Bland-Altman: %s [%s] (NYU vs USC Data)', metricName, unitLabel);
        fig = plot_bland_altman_combined(nA(nV), nB(nV), uA(uV), uB(uV), ...
            titleStr, 'NYU 142 GHz', 'USC 145 GHz', unitLabel);

        % Save to subfolder
        baseName = sprintf('BlandAltman_%s', fileTag);
        savefig(fig, fullfile(saveDir, [baseName '.fig']));
        exportgraphics(fig, fullfile(saveDir, [baseName '.png']), 'Resolution', 300);
        exportgraphics(fig, fullfile(saveDir, [baseName '.pdf']), 'ContentType', 'vector');
        fprintf('  Saved: %s (.fig, .png, .pdf)\n', baseName);
    end
end

%% ===== PRINT SUMMARY STATISTICS =====
fprintf('\n');
fprintf('===================================================================\n');
fprintf('  BLAND-ALTMAN SUMMARY STATISTICS (NYU method - USC method)\n');
fprintf('===================================================================\n');

for m = 1:size(metrics, 1)
    metricName = metrics{m, 1};
    unitLabel  = metrics{m, 6};
    fprintf('\n--- %s [%s] ---\n', metricName, unitLabel);

    % NYU Data
    nyuColA = metrics{m, 2};  nyuColB = metrics{m, 3};
    if ismember(nyuColA, nyu.Properties.VariableNames) && ...
       ismember(nyuColB, nyu.Properties.VariableNames)
        a = nyu.(nyuColA); b = nyu.(nyuColB);
        v = isfinite(a) & isfinite(b);
        d = a(v) - b(v);
        fprintf('  NYU 142 GHz: Mean = %+.2f %s, SD = %.2f %s, RMSE = %.2f %s (n=%d)\n', ...
            mean(d), unitLabel, std(d), unitLabel, sqrt(mean(d.^2)), unitLabel, sum(v));
    end

    % USC Data
    uscColA = metrics{m, 4};  uscColB = metrics{m, 5};
    if ismember(uscColA, usc.Properties.VariableNames) && ...
       ismember(uscColB, usc.Properties.VariableNames)
        a = usc.(uscColA); b = usc.(uscColB);
        v = isfinite(a) & isfinite(b);
        d = a(v) - b(v);
        fprintf('  USC 145 GHz: Mean = %+.2f %s, SD = %.2f %s, RMSE = %.2f %s (n=%d)\n', ...
            mean(d), unitLabel, std(d), unitLabel, sqrt(mean(d.^2)), unitLabel, sum(v));
    end
end
fprintf('\n===================================================================\n');
fprintf('Figures saved to: %s\n', saveDir);

%% ========================================================================
%  HELPER FUNCTIONS
%  ========================================================================

function unit_tex = to_tex_unit(unitLabel)
    % Convert plain unit label to LaTeX-safe string for axis labels
    switch unitLabel
        case 'deg'
            unit_tex = '[$^\circ$]';
        case 'dB'
            unit_tex = '[dB]';
        case 'ns'
            unit_tex = '[ns]';
        otherwise
            unit_tex = sprintf('[%s]', unitLabel);
    end
end

function unit_plain = to_plain_unit(unitLabel)
    % Convert to plain text for annotations and fprintf
    switch unitLabel
        case 'deg'
            unit_plain = 'deg';
        otherwise
            unit_plain = unitLabel;
    end
end

function plot_bland_altman(a, b, label, methodA, methodB, unitLabel)
    % Standard Bland-Altman: scatter of mean vs difference
    meanVals = (a + b) / 2;
    diffVals = a - b;
    bias = mean(diffVals);
    sd = std(diffVals);
    loaUpper = bias + 1.96 * sd;
    loaLower = bias - 1.96 * sd;

    unitTex   = to_tex_unit(unitLabel);
    unitPlain = to_plain_unit(unitLabel);

    figure('Name', label, 'Position', [200, 200, 900, 550]);
    scatter(meanVals, diffVals, 60, 'filled', 'MarkerFaceAlpha', 0.7); hold on; grid on;
    yline(bias, 'k-', 'LineWidth', 1.5, ...
        'Label', sprintf('Bias = %+.2f %s', bias, unitPlain), ...
        'LabelHorizontalAlignment', 'left', 'FontSize', 10);
    yline(loaUpper, 'r--', 'LineWidth', 1.2, ...
        'Label', sprintf('+1.96 SD = %+.2f', loaUpper), ...
        'LabelHorizontalAlignment', 'left', 'FontSize', 9);
    yline(loaLower, 'r--', 'LineWidth', 1.2, ...
        'Label', sprintf('-1.96 SD = %+.2f', loaLower), ...
        'LabelHorizontalAlignment', 'left', 'FontSize', 9);

    xlabel(sprintf('Mean of %s and %s %s', methodA, methodB, unitTex), ...
        'FontSize', 11, 'Interpreter', 'tex');
    ylabel(sprintf('Difference (%s - %s) %s', methodA, methodB, unitTex), ...
        'FontSize', 11, 'Interpreter', 'tex');
    title(label, 'FontSize', 12, 'Interpreter', 'none');

    % Stats annotation box
    textStr = sprintf('Bias = %+.2f %s\nSD = %.2f %s\nn = %d', ...
        bias, unitPlain, sd, unitPlain, length(diffVals));
    annotation('textbox', [0.70 0.75 0.22 0.15], 'String', textStr, ...
        'FontSize', 10, 'BackgroundColor', 'w', 'EdgeColor', [0.3 0.3 0.3], ...
        'LineWidth', 1);

    fprintf('  %s: Bias = %+.2f %s, SD = %.2f %s (n=%d)\n', ...
        label, bias, unitPlain, sd, unitPlain, length(diffVals));
end

function fig = plot_bland_altman_combined(a1, b1, a2, b2, titleStr, name1, name2, unitLabel)
    % Combined Bland-Altman: two datasets on one figure with shared y-axis
    mean1 = (a1 + b1) / 2;   diff1 = a1 - b1;
    mean2 = (a2 + b2) / 2;   diff2 = a2 - b2;

    bias1 = mean(diff1);  sd1 = std(diff1);
    loa1u = bias1 + 1.96*sd1;  loa1l = bias1 - 1.96*sd1;

    bias2 = mean(diff2);  sd2 = std(diff2);
    loa2u = bias2 + 1.96*sd2;  loa2l = bias2 - 1.96*sd2;

    unitTex   = to_tex_unit(unitLabel);
    unitPlain = to_plain_unit(unitLabel);

    fig = figure('Name', titleStr, 'Position', [250, 250, 1000, 550]);

    % --- NYU data (blue) ---
    s1 = scatter(mean1, diff1, 60, 'o', ...
        'MarkerEdgeColor', [0 0.45 0.74], ...
        'MarkerFaceColor', [0.60 0.78 0.92], ...
        'LineWidth', 1); hold on;
    yline(bias1, '-', 'Color', [0 0.45 0.74], 'LineWidth', 1.5, ...
        'Label', sprintf('Bias (%s) = %+.2f', name1, bias1), ...
        'LabelHorizontalAlignment', 'left', 'FontSize', 9);
    yline(loa1u, '--', 'Color', [0 0.45 0.74], 'LineWidth', 1.0, ...
        'Label', sprintf('+1.96 SD = %+.2f', loa1u), ...
        'LabelHorizontalAlignment', 'left', 'FontSize', 8);
    yline(loa1l, '--', 'Color', [0 0.45 0.74], 'LineWidth', 1.0, ...
        'Label', sprintf('-1.96 SD = %+.2f', loa1l), ...
        'LabelHorizontalAlignment', 'left', 'FontSize', 8);

    % --- USC data (red/orange) ---
    s2 = scatter(mean2, diff2, 60, 's', ...
        'MarkerEdgeColor', [0.85 0.33 0.10], ...
        'MarkerFaceColor', [0.98 0.78 0.68], ...
        'LineWidth', 1);
    yline(bias2, '-', 'Color', [0.85 0.33 0.10], 'LineWidth', 1.5, ...
        'Label', sprintf('Bias (%s) = %+.2f', name2, bias2), ...
        'LabelHorizontalAlignment', 'right', 'FontSize', 9);
    yline(loa2u, '--', 'Color', [0.85 0.33 0.10], 'LineWidth', 1.0, ...
        'Label', sprintf('+1.96 SD = %+.2f', loa2u), ...
        'LabelHorizontalAlignment', 'right', 'FontSize', 8);
    yline(loa2l, '--', 'Color', [0.85 0.33 0.10], 'LineWidth', 1.0, ...
        'Label', sprintf('-1.96 SD = %+.2f', loa2l), ...
        'LabelHorizontalAlignment', 'right', 'FontSize', 8);

    grid on;
    xlabel(sprintf('Mean of NYU and USC methods %s', unitTex), ...
        'FontSize', 11, 'Interpreter', 'tex');
    ylabel(sprintf('Difference (NYU - USC) %s', unitTex), ...
        'FontSize', 11, 'Interpreter', 'tex');
    title(titleStr, 'FontSize', 12, 'Interpreter', 'none');
    legend([s1 s2], ...
        sprintf('%s (n=%d)', name1, length(diff1)), ...
        sprintf('%s (n=%d)', name2, length(diff2)), ...
        'Location', 'best', 'FontSize', 10);

    fprintf('  Combined %s:\n', titleStr);
    fprintf('    %s: Bias=%+.2f, SD=%.2f (n=%d)\n', name1, bias1, sd1, length(diff1));
    fprintf('    %s: Bias=%+.2f, SD=%.2f (n=%d)\n', name2, bias2, sd2, length(diff2));
end

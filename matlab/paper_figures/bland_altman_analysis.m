%% Bland-Altman analysis for NYU vs USC processing on matched datasets
% This script compares processing methods within the same dataset:
%  - NYU data: "NYU thres" (USC processing) vs "NYU orig. (N1)" (NYU processing)
%  - USC data: "USC thres" (NYU processing) vs "USC orig. (U1)" (USC processing)

clear variables;
close all;
clc;

%baseUSC = pwd;
U = paths();
n3Path = U.n3_142_xlsx;
u3Path = U.u3_142_xlsx;

% Load tables with combined two-row headers
n3 = load_ba_table(n3Path);
u3 = load_ba_table(u3Path);

% Build comparisons: [label, table, metric, methodA, methodB]
cases = {
    'NYU Data (N3) - Omni PL', n3, 'Omni PL', 'NYU thres', 'NYU orig. (N1)';
    'NYU Data (N3) - Omni DS', n3, 'Omni DS', 'NYU thres', 'NYU orig. (N1)';
    'USC Data (U3) - Omni PL', u3, 'Omni PL', 'USC thres', 'USC orig. (U1)';
    'USC Data (U3) - Omni DS', u3, 'Omni DS', 'USC thres', 'USC orig. (U1)';
};

for i = 1:size(cases,1)
    label = cases{i,1};
    T = cases{i,2};
    metric = cases{i,3};
    mA = cases{i,4};
    mB = cases{i,5};
    [x, y] = get_metric_pair(T, metric, mA, mB);
    if isempty(x)
        warning('No valid data for %s', label);
        continue;
    end
    plot_bland_altman(x, y, label, mA, mB);
end

% Combined plot for Path Loss (N3 vs U3) with distinct markers/colors.
[n3_pl_a, n3_pl_b] = get_metric_pair(n3, 'Omni PL', 'NYU thres', 'NYU orig. (N1)');
[u3_pl_a, u3_pl_b] = get_metric_pair(u3, 'Omni PL', 'USC thres', 'USC orig. (U1)');
if ~isempty(n3_pl_a) && ~isempty(u3_pl_a)
    plot_bland_altman_combined_dualaxis(n3_pl_a, n3_pl_b, u3_pl_a, u3_pl_b, ...
        'Bland-Altman: Omni PL (N3 vs U3)', 'N3: NYU thres - NYU orig.', 'U3: USC thres - USC orig.');
end

% Combined plot for Omni DS (N3 vs U3) with distinct markers/colors.
[n3_ds_a, n3_ds_b] = get_metric_pair(n3, 'Omni DS', 'NYU thres', 'NYU orig. (N1)');
[u3_ds_a, u3_ds_b] = get_metric_pair(u3, 'Omni DS', 'USC thres', 'USC orig. (U1)');
if ~isempty(n3_ds_a) && ~isempty(u3_ds_a)
    plot_bland_altman_combined_dualaxis(n3_ds_a, n3_ds_b, u3_ds_a, u3_ds_b, ...
        'Bland-Altman: Omni DS (N3 vs U3)', 'N3: NYU thres - NYU orig.', 'U3: USC thres - USC orig.');
end

%% ----- helpers -----
function T = load_ba_table(xlsxPath)
    raw = readcell(xlsxPath, 'Sheet', 'FinalTable');
    % Locate header row that starts with 'Freq.'
    headerRow = find(cellfun(@(c) ischar(c) && strcmpi(c, 'Freq.'), raw(:,1)), 1, 'first');
    if isempty(headerRow)
        error('Could not find header row in %s', xlsxPath);
    end
    subHeaderRow = headerRow + 1;
    headers1 = raw(headerRow, :);
    headers2 = raw(subHeaderRow, :);
    % Forward-fill header row so metric names apply to their subcolumns.
    headers1 = fill_header(headers1);
    data = raw(subHeaderRow+1:end, :);
    
    % Identify TX/RX columns and drop rows where both are missing.
    txCol = find(strcmpi(string(headers1), "TX"), 1, 'first');
    rxCol = find(strcmpi(string(headers1), "RX"), 1, 'first');
    if ~isempty(txCol) && ~isempty(rxCol)
        tx = string(data(:, txCol));
        rx = string(data(:, rxCol));
        tx = standardizeMissing(tx, ["", " "]);
        rx = standardizeMissing(rx, ["", " "]);
        drop = ismissing(tx) & ismissing(rx);
        data = data(~drop, :);
    end
    
    % Return a struct with headers + data for targeted column extraction.
    T.headers1 = headers1;
    T.headers2 = headers2;
    T.data = data;
end

function [a, b] = get_metric_pair(T, metric, methodA, methodB)
    headers1 = string(T.headers1);
    headers2 = string(T.headers2);
    % Find columns matching metric + method
    colA = find(strcmpi(strtrim(headers1), metric) & strcmpi(strtrim(headers2), methodA), 1, 'first');
    colB = find(strcmpi(strtrim(headers1), metric) & strcmpi(strtrim(headers2), methodB), 1, 'first');
    if isempty(colA) || isempty(colB)
        a = [];
        b = [];
        return;
    end
    a = to_num(T.data(:, colA));
    b = to_num(T.data(:, colB));
    valid = isfinite(a) & isfinite(b);
    a = a(valid);
    b = b(valid);
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

function v = to_num(x)
    if iscell(x)
        v = str2double(string(x));
    else
        v = double(x);
    end
end

function plot_bland_altman(a, b, label, methodA, methodB)
    meanVals = (a + b) / 2;
    diffVals = a - b; % methodA - methodB
    bias = mean(diffVals);
    sd = std(diffVals);
    loaUpper = bias + 1.96 * sd;
    loaLower = bias - 1.96 * sd;
    
    figure('Name', ['Bland-Altman: ' label], 'Position', [200, 200, 900, 550]);
    scatter(meanVals, diffVals, 50, 'filled'); hold on; grid on;
    yline(bias, 'k-', 'LineWidth', 1.5, 'Label', 'Bias', 'LabelHorizontalAlignment', 'left');
    yline(loaUpper, 'r--', 'LineWidth', 1.2, 'Label', '+1.96 SD', 'LabelHorizontalAlignment', 'left');
    yline(loaLower, 'r--', 'LineWidth', 1.2, 'Label', '-1.96 SD', 'LabelHorizontalAlignment', 'left');
    xlabel(sprintf('Mean of %s and %s', methodA, methodB));
    ylabel(sprintf('Difference (%s - %s)', methodA, methodB));
    title(label);
end

function plot_bland_altman_combined_dualaxis(a1, b1, a2, b2, label, name1, name2)
    mean1 = (a1 + b1) / 2;
    diff1 = a1 - b1;
    mean2 = (a2 + b2) / 2;
    diff2 = b2 - a2;
    
    bias1 = mean(diff1);
    sd1 = std(diff1);
    loa1u = bias1 + 1.96 * sd1;
    loa1l = bias1 - 1.96 * sd1;
    
    bias2 = mean(diff2);
    sd2 = std(diff2);
    loa2u = bias2 + 1.96 * sd2;
    loa2l = bias2 - 1.96 * sd2;
    
    figure('Name', label, 'Position', [250, 250, 900, 550]);
    
    yyaxis left
    s1 = scatter(mean1, diff1, 50, 'o', 'MarkerEdgeColor', [0 0.45 0.74], ...
        'MarkerFaceColor', [0.60 0.78 0.92]); hold on;
    yline(bias1, 'b-', 'LineWidth', 1.2, 'Label', 'Bias (N3)', 'LabelHorizontalAlignment', 'left');
    yline(loa1u, 'b--', 'LineWidth', 1.0, 'Label', '+1.96 SD (N3)', 'LabelHorizontalAlignment', 'left');
    yline(loa1l, 'b--', 'LineWidth', 1.0, 'Label', '-1.96 SD (N3)', 'LabelHorizontalAlignment', 'left');
    ylabel('N3: NYU thres - NYU orig.');
    
    yyaxis right
    s2 = scatter(mean2, diff2, 50, 's', 'MarkerEdgeColor', [0.85 0.33 0.10], ...
        'MarkerFaceColor', [0.98 0.78 0.68]);
    yline(bias2, 'r-', 'LineWidth', 1.2, 'Label', 'Bias (U3)', 'LabelHorizontalAlignment', 'left');
    yline(loa2u, 'r--', 'LineWidth', 1.0, 'Label', '+1.96 SD (U3)', 'LabelHorizontalAlignment', 'left');
    yline(loa2l, 'r--', 'LineWidth', 1.0, 'Label', '-1.96 SD (U3)', 'LabelHorizontalAlignment', 'left');
    ylabel('U3: USC thres - USC orig.');
    
    % Keep both y-axes on the same limits for fair visual comparison.
    allDiff = [diff1(:); diff2(:); loa1l; loa1u; loa2l; loa2u];
    yMin = min(allDiff);
    yMax = max(allDiff);
    yyaxis left; ylim([yMin yMax]);
    yyaxis right; ylim([yMin yMax]);
    grid on;
    xlabel('Mean of paired methods');
    title(label);
    legend([s1 s2], name1, name2, 'Location', 'best');
end

%% ========================================================================
%  Plot Raw PDP and PAS for TX1-RX18 and TX4-RX38
%  Purpose: Visualize WHY these locations show AS=0 (insufficient SNR)
%  ========================================================================
clear; clc; close all;

%% Configuration
params.dilation_factor = 20;       % 20 samples/ns
config.thres_below_pk = 25;        % dB below peak
config.thres_above_noise = 5;      % dB above noise floor
config.multipath_low_bound = -100; % Floor in dB

% IEEE figure settings
set(0, 'DefaultAxesFontSize', 10);
set(0, 'DefaultAxesFontName', 'Times New Roman');
set(0, 'DefaultTextFontSize', 10);
set(0, 'DefaultLineLineWidth', 1.2);
set(0, 'DefaultFigureColor', 'w');
set(0, 'DefaultAxesLineWidth', 0.8);
set(0, 'DefaultAxesBox', 'on');
set(0, 'DefaultTextInterpreter', 'latex');
set(0, 'DefaultLegendInterpreter', 'latex');
set(0, 'DefaultAxesTickLabelInterpreter', 'latex');

%% Data paths
data_path = 'D:\NYU-USC\Cross-Processing\NYU\NYU_Data\142AlignedDataset';

locations = {'T1-R18', 'T4-R38'};
files = {'142GHz_Outdoor_T1-R18.mat', '142GHz_Outdoor_T4-R38.mat'};

%% Also load a "good" NLOS location for comparison
% (pick one that has valid AS)
files_good = {'142GHz_Outdoor_T1-R14.mat'};
locations_good = {'T1-R14'};

%% ========================================================================
%  FIGURE 1: RAW PDP (Before Thresholding) — Strongest Directional PDP
%  ========================================================================
figure('Units', 'inches', 'Position', [1 1 7 8]);

for loc = 1:2
    data = load(fullfile(data_path, files{loc}));
    fnames = fieldnames(data);
    TRpdpSet = data.(fnames{1});
    nPDPs = size(TRpdpSet, 1);

    % Find the strongest directional PDP (highest peak)
    best_peak = -Inf;
    best_idx = 1;
    for i = 1:nPDPs
        pdp_dB = real(TRpdpSet{i, 1});
        pk = max(pdp_dB);
        if pk > best_peak
            best_peak = pk;
            best_idx = i;
        end
    end

    pdp_dB = real(TRpdpSet{best_idx, 1});
    pdp_len = length(pdp_dB);
    delays_ns = (0:pdp_len-1)' / params.dilation_factor;

    % Noise floor estimation (last 250 ns)
    noise_tail_samples = 250 * params.dilation_factor;
    if pdp_len > noise_tail_samples
        tail_dB = pdp_dB(end-noise_tail_samples+1:end);
    else
        tail_dB = pdp_dB(floor(0.9*pdp_len):end);
    end
    tail_lin = 10.^(tail_dB / 10);
    noise_floor_dB = 10*log10(mean(tail_lin));

    % Thresholds
    peak_dB = max(pdp_dB);
    thres_25below = peak_dB - config.thres_below_pk;
    thres_5above = noise_floor_dB + config.thres_above_noise;
    threshold_dB = max(thres_25below, thres_5above);

    % SNR
    SNR = peak_dB - noise_floor_dB;

    % Count surviving samples
    n_surviving = sum(pdp_dB > threshold_dB);

    tx_ang = TRpdpSet{best_idx, 6};
    rx_ang = TRpdpSet{best_idx, 8};

    subplot(2, 1, loc);
    plot(delays_ns, pdp_dB, 'Color', [0.3 0.3 0.8], 'LineWidth', 0.5);
    hold on;
    yline(noise_floor_dB, 'g--', 'LineWidth', 1.5);
    yline(thres_5above, 'r-', 'LineWidth', 1.5);
    yline(thres_25below, 'm--', 'LineWidth', 1.5);
    yline(threshold_dB, 'k-', 'LineWidth', 2.0);

    % Highlight surviving samples
    survive_mask = pdp_dB > threshold_dB;
    if any(survive_mask)
        plot(delays_ns(survive_mask), pdp_dB(survive_mask), 'r.', 'MarkerSize', 4);
    end

    xlabel('Excess Delay (ns)');
    ylabel('Power (dB)');
    title(sprintf('%s: Strongest Directional PDP (TX$=%d^\\circ$, RX$=%d^\\circ$)', ...
        locations{loc}, tx_ang, rx_ang));

    legend({'Raw PDP', ...
            sprintf('Noise Floor = %.1f dB', noise_floor_dB), ...
            sprintf('Noise + 5 dB = %.1f dB', thres_5above), ...
            sprintf('Peak $-$ 25 dB = %.1f dB', thres_25below), ...
            sprintf('Threshold = %.1f dB (SNR = %.1f dB)', threshold_dB, SNR), ...
            sprintf('Surviving Samples: %d', n_surviving)}, ...
        'Location', 'northeast', 'FontSize', 8);

    xlim([0 max(delays_ns)]);
    grid on;

    fprintf('\n=== %s (Strongest Dir. PDP: TX=%d°, RX=%d°) ===\n', locations{loc}, tx_ang, rx_ang);
    fprintf('  Peak power:        %.1f dB\n', peak_dB);
    fprintf('  Noise floor:       %.1f dB\n', noise_floor_dB);
    fprintf('  SNR:               %.1f dB\n', SNR);
    fprintf('  Threshold (25dB):  %.1f dB\n', thres_25below);
    fprintf('  Threshold (N+5):   %.1f dB\n', thres_5above);
    fprintf('  ACTIVE threshold:  %.1f dB  ← %s dominates\n', threshold_dB, ...
        iff(thres_5above > thres_25below, 'noise+5dB', 'peak-25dB'));
    fprintf('  Surviving samples: %d / %d (%.2f%%)\n', n_surviving, pdp_len, 100*n_surviving/pdp_len);
end

sgtitle('\textbf{Raw Directional PDP: Signal Outage Locations}', 'FontSize', 12);
saveas(gcf, fullfile('D:\NYU-USC\Cross-Processing\ProcessingNYU142GHzData\Figures', ...
    'Outage_RawPDP_StrongestDir.png'));
saveas(gcf, fullfile('D:\NYU-USC\Cross-Processing\ProcessingNYU142GHzData\Figures', ...
    'Outage_RawPDP_StrongestDir.fig'));

%% ========================================================================
%  FIGURE 2: ALL Directional PDPs overlaid (showing the full picture)
%  ========================================================================
figure('Units', 'inches', 'Position', [1 1 7 8]);

for loc = 1:2
    data = load(fullfile(data_path, files{loc}));
    fnames = fieldnames(data);
    TRpdpSet = data.(fnames{1});
    nPDPs = size(TRpdpSet, 1);

    pdp_len = length(real(TRpdpSet{1, 1}));
    delays_ns = (0:pdp_len-1)' / params.dilation_factor;

    % Collect all noise floors and peaks
    all_noise = zeros(nPDPs, 1);
    all_peaks = zeros(nPDPs, 1);
    total_surviving = 0;

    subplot(2, 1, loc);
    hold on;

    % Plot all directional PDPs with transparency
    for i = 1:nPDPs
        pdp_dB = real(TRpdpSet{i, 1});
        all_peaks(i) = max(pdp_dB);

        % Noise floor
        noise_tail_samples = 250 * params.dilation_factor;
        if length(pdp_dB) > noise_tail_samples
            tail_dB = pdp_dB(end-noise_tail_samples+1:end);
        else
            tail_dB = pdp_dB(floor(0.9*length(pdp_dB)):end);
        end
        tail_lin = 10.^(tail_dB / 10);
        all_noise(i) = 10*log10(mean(tail_lin));

        % Threshold for this PDP
        thr_i = max(all_peaks(i) - 25, all_noise(i) + 5);
        n_surv_i = sum(pdp_dB > thr_i);
        total_surviving = total_surviving + n_surv_i;

        plot(delays_ns, pdp_dB, 'Color', [0.5 0.5 0.8 0.3], 'LineWidth', 0.3);
    end

    % Draw representative noise and threshold lines
    med_noise = median(all_noise);
    med_peak = median(all_peaks);
    max_peak = max(all_peaks);
    thr_25 = max_peak - 25;
    thr_N5 = med_noise + 5;
    active_thr = max(thr_25, thr_N5);

    yline(med_noise, 'g-', 'LineWidth', 2);
    yline(thr_N5, 'r-', 'LineWidth', 2);
    yline(thr_25, 'm--', 'LineWidth', 1.5);
    yline(active_thr, 'k-', 'LineWidth', 2.0);

    xlabel('Excess Delay (ns)');
    ylabel('Power (dB)');
    title(sprintf('%s: All %d Directional PDPs Overlaid', locations{loc}, nPDPs));

    legend({sprintf('Directional PDPs (%d total)', nPDPs), ...
            sprintf('Median Noise = %.1f dB', med_noise), ...
            sprintf('Noise + 5 dB = %.1f dB', thr_N5), ...
            sprintf('Best Peak $-$ 25 dB = %.1f dB', thr_25), ...
            sprintf('Threshold = %.1f dB', active_thr)}, ...
        'Location', 'northeast', 'FontSize', 8);

    xlim([0 max(delays_ns)]);
    grid on;

    fprintf('\n=== %s: ALL %d Directional PDPs ===\n', locations{loc}, nPDPs);
    fprintf('  Peak range:     %.1f to %.1f dB\n', min(all_peaks), max(all_peaks));
    fprintf('  Noise range:    %.1f to %.1f dB\n', min(all_noise), max(all_noise));
    fprintf('  Median noise:   %.1f dB\n', med_noise);
    fprintf('  Max SNR:        %.1f dB\n', max(all_peaks) - min(all_noise));
    fprintf('  Total surviving samples (all dirs): %d\n', total_surviving);
end

sgtitle('\textbf{All Directional PDPs: Signal Outage Locations}', 'FontSize', 12);
saveas(gcf, fullfile('D:\NYU-USC\Cross-Processing\ProcessingNYU142GHzData\Figures', ...
    'Outage_AllDirPDP.png'));
saveas(gcf, fullfile('D:\NYU-USC\Cross-Processing\ProcessingNYU142GHzData\Figures', ...
    'Outage_AllDirPDP.fig'));

%% ========================================================================
%  FIGURE 3: PAS (Power Angular Spectrum) — AOA and AOD
%  ========================================================================
figure('Units', 'inches', 'Position', [1 1 7 10]);

for loc = 1:2
    data = load(fullfile(data_path, files{loc}));
    fnames = fieldnames(data);
    TRpdpSet = data.(fnames{1});
    nPDPs = size(TRpdpSet, 1);

    % ---- First apply thresholding ----
    TRpdpSet_thr = TRpdpSet;
    noise_tail_samples = 250 * params.dilation_factor;

    for i = 1:nPDPs
        pdp_dB = real(TRpdpSet{i, 1});
        pdp_len = length(pdp_dB);

        if pdp_len > noise_tail_samples
            tail_dB = pdp_dB(end-noise_tail_samples+1:end);
        else
            tail_dB = pdp_dB(floor(0.9*pdp_len):end);
        end
        tail_lin = 10.^(tail_dB / 10);
        local_noise = 10*log10(mean(tail_lin));
        local_peak = max(pdp_dB);
        threshold_dB = max(local_peak - 25, local_noise + 5);
        pdp_dB(pdp_dB < threshold_dB) = -100;
        TRpdpSet_thr{i, 1} = pdp_dB;
    end

    % ---- Generate PAS for AOA (col 8) and AOD (col 6) ----
    % Use -200 dB floor so weak signals (e.g., -105 dB) are not killed
    PAS_floor = -200;

    % Before thresholding (raw)
    [~, PAS_AOA_raw] = generate_PAS_simple(TRpdpSet, 8, PAS_floor);
    [~, PAS_AOD_raw] = generate_PAS_simple(TRpdpSet, 6, PAS_floor);

    % After thresholding
    [PAS_angles, PAS_AOA_thr] = generate_PAS_simple(TRpdpSet_thr, 8, PAS_floor);
    [~, PAS_AOD_thr] = generate_PAS_simple(TRpdpSet_thr, 6, PAS_floor);

    % Count valid angles after threshold
    n_valid_AOA = sum(PAS_AOA_thr > PAS_floor);
    n_valid_AOD = sum(PAS_AOD_thr > PAS_floor);

    % ---- Subplot: AOA ----
    subplot(4, 1, (loc-1)*2 + 1);
    bar(PAS_angles, PAS_AOA_raw, 'FaceColor', [0.7 0.7 1.0], 'EdgeColor', 'none', 'BarWidth', 1);
    hold on;
    bar(PAS_angles, max(PAS_AOA_thr, -100), 'FaceColor', [0.8 0.2 0.2], 'EdgeColor', 'none', 'BarWidth', 1);

    xlabel('AOA Azimuth ($^\circ$)');
    ylabel('Power (dB)');
    title(sprintf('%s: AOA Power Angular Spectrum (valid angles after thresh: %d)', ...
        locations{loc}, n_valid_AOA));
    legend({'Before Threshold', 'After Threshold'}, 'Location', 'northeast', 'FontSize', 8);
    xlim([0 360]);
    grid on;

    % ---- Subplot: AOD ----
    subplot(4, 1, (loc-1)*2 + 2);
    bar(PAS_angles, PAS_AOD_raw, 'FaceColor', [0.7 1.0 0.7], 'EdgeColor', 'none', 'BarWidth', 1);
    hold on;
    bar(PAS_angles, max(PAS_AOD_thr, -100), 'FaceColor', [0.2 0.6 0.2], 'EdgeColor', 'none', 'BarWidth', 1);

    xlabel('AOD Azimuth ($^\circ$)');
    ylabel('Power (dB)');
    title(sprintf('%s: AOD Power Angular Spectrum (valid angles after thresh: %d)', ...
        locations{loc}, n_valid_AOD));
    legend({'Before Threshold', 'After Threshold'}, 'Location', 'northeast', 'FontSize', 8);
    xlim([0 360]);
    grid on;

    fprintf('\n=== %s: PAS Summary ===\n', locations{loc});
    fprintf('  AOA: %d / 360 angles have power above floor BEFORE threshold\n', sum(PAS_AOA_raw > PAS_floor));
    fprintf('  AOA: %d / 360 angles have power above floor AFTER threshold\n', n_valid_AOA);
    fprintf('  AOD: %d / 360 angles have power above floor BEFORE threshold\n', sum(PAS_AOD_raw > PAS_floor));
    fprintf('  AOD: %d / 360 angles have power above floor AFTER threshold\n', n_valid_AOD);
end

sgtitle('\textbf{Power Angular Spectrum: Signal Outage Locations}', 'FontSize', 12);
saveas(gcf, fullfile('D:\NYU-USC\Cross-Processing\ProcessingNYU142GHzData\Figures', ...
    'Outage_PAS.png'));
saveas(gcf, fullfile('D:\NYU-USC\Cross-Processing\ProcessingNYU142GHzData\Figures', ...
    'Outage_PAS.fig'));

%% ========================================================================
%  FIGURE 4: COMPARISON with a good NLOS location (T1-R14)
%  ========================================================================
figure('Units', 'inches', 'Position', [1 1 7 10]);

all_files = [files, files_good];
all_labels = [locations, locations_good];
plot_colors = {[0.8 0.2 0.2], [0.2 0.2 0.8], [0.1 0.7 0.1]};

for loc = 1:3
    data = load(fullfile(data_path, all_files{loc}));
    fnames = fieldnames(data);
    TRpdpSet = data.(fnames{1});
    nPDPs = size(TRpdpSet, 1);

    % Find strongest PDP
    best_peak = -Inf;
    best_idx = 1;
    for i = 1:nPDPs
        pdp_dB = real(TRpdpSet{i, 1});
        if max(pdp_dB) > best_peak
            best_peak = max(pdp_dB);
            best_idx = i;
        end
    end

    pdp_dB = real(TRpdpSet{best_idx, 1});
    pdp_len = length(pdp_dB);
    delays_ns = (0:pdp_len-1)' / params.dilation_factor;

    % Noise
    noise_tail_samples = 250 * params.dilation_factor;
    tail_dB = pdp_dB(end-noise_tail_samples+1:end);
    tail_lin = 10.^(tail_dB / 10);
    noise_floor_dB = 10*log10(mean(tail_lin));
    peak_dB = max(pdp_dB);
    SNR = peak_dB - noise_floor_dB;

    subplot(3, 1, loc);
    plot(delays_ns, pdp_dB, 'Color', plot_colors{loc}, 'LineWidth', 0.6);
    hold on;
    yline(noise_floor_dB, 'g--', 'LineWidth', 1.5);
    yline(max(peak_dB - 25, noise_floor_dB + 5), 'k-', 'LineWidth', 2.0);

    xlabel('Excess Delay (ns)');
    ylabel('Power (dB)');

    if loc <= 2
        label_suffix = '(Insufficient SNR)';
    else
        label_suffix = '(Valid NLOS)';
    end
    title(sprintf('%s %s: Strongest Dir. PDP, SNR = %.1f dB', ...
        all_labels{loc}, label_suffix, SNR));

    legend({'PDP', sprintf('Noise = %.1f dB', noise_floor_dB), ...
            sprintf('Threshold = %.1f dB', max(peak_dB-25, noise_floor_dB+5))}, ...
        'Location', 'northeast', 'FontSize', 8);
    xlim([0 max(delays_ns)]);
    grid on;
end

sgtitle('\textbf{Comparison: Insufficient SNR vs. Valid NLOS Location}', 'FontSize', 12);
saveas(gcf, fullfile('D:\NYU-USC\Cross-Processing\ProcessingNYU142GHzData\Figures', ...
    'Outage_vs_Good_Comparison.png'));
saveas(gcf, fullfile('D:\NYU-USC\Cross-Processing\ProcessingNYU142GHzData\Figures', ...
    'Outage_vs_Good_Comparison.fig'));

%% ========================================================================
%  Print summary
%  ========================================================================
fprintf('\n');
fprintf('═══════════════════════════════════════════════════════════════════\n');
fprintf('  SUMMARY: Why TX1-RX18 and TX4-RX38 show AS = 0°\n');
fprintf('═══════════════════════════════════════════════════════════════════\n');
fprintf('  The signal arrives at the RX with moderate local SNR (~9-11 dB)\n');
fprintf('  and ~50-250 samples survive the per-directional PDP threshold.\n');
fprintf('  However, the absolute received power (peak ~ -103 to -106 dB)\n');
fprintf('  falls below the -100 dB multipath_low_bound floor used in:\n');
fprintf('    - Omni PDP synthesis (floor_threshold = -99 dB)\n');
fprintf('    - PAS generation (floor_dB = -100 dB)\n');
fprintf('  Surviving samples at -105 dB are treated as floor values and\n');
fprintf('  zeroed out, giving Omni PDP = 0 and PAS = empty.\n');
fprintf('  Fix: PAS floor changed to -200 dB to show angular distribution.\n');
fprintf('═══════════════════════════════════════════════════════════════════\n');

fprintf('\nFigures saved to: D:\\NYU-USC\\Cross-Processing\\ProcessingNYU142GHzData\\Figures\\\n');
fprintf('Done!\n');

%% ========================================================================
%  HELPER FUNCTIONS
%  ========================================================================

function [PAS_angles, PAS_powers] = generate_PAS_simple(TRpdpSet, ref_col, floor_dB)
    % Simplified PAS generation for visualization
    nPDPs = size(TRpdpSet, 1);

    all_angles = [];
    all_powers_dB = [];

    for i = 1:nPDPs
        pdp_dB = real(TRpdpSet{i, 1});
        if isempty(pdp_dB) || ~isnumeric(pdp_dB)
            continue;
        end

        angle = TRpdpSet{i, ref_col};
        if isempty(angle) || ~isnumeric(angle)
            continue;
        end

        valid_mask = pdp_dB > floor_dB;
        if any(valid_mask)
            power_lin = sum(10.^(pdp_dB(valid_mask) / 10));
            power_dB = 10*log10(power_lin + eps);
            all_angles = [all_angles; angle];
            all_powers_dB = [all_powers_dB; power_dB];
        end
    end

    % Aggregate by unique angles
    PAS_angles = (1:360)';
    PAS_powers = ones(360, 1) * floor_dB;

    if ~isempty(all_angles)
        all_angles(all_angles == 0) = 360;
        unique_angles = unique(all_angles);
        for i = 1:length(unique_angles)
            mask = all_angles == unique_angles(i);
            power_lin = sum(10.^(all_powers_dB(mask) / 10));
            ang_idx = round(unique_angles(i));
            if ang_idx >= 1 && ang_idx <= 360
                PAS_powers(ang_idx) = 10*log10(power_lin + eps);
            end
        end
    end
end

function result = iff(cond, true_val, false_val)
    if cond
        result = true_val;
    else
        result = false_val;
    end
end

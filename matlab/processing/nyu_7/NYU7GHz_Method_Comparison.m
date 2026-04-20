%% ======================================================================
%  NYU 6.75GHz (7GHz) Data: Dual-Threshold Method Comparison (NYU vs USC)
%  ========================================================================
%
%  PURPOSE: Compare NYU and USC processing methods on NYU's 6.75GHz data
%           under BOTH NYU and USC PDP thresholding approaches.
%           Quantifies differences in Omni PL, RMS DS, ASA, and ASD.
%
%  =========================================================================
%  DUAL-THRESHOLD CROSS-PROCESSING DESIGN
%  =========================================================================
%
%  This script runs the FULL processing pipeline TWICE per TX-RX pair:
%    Pipeline A: NYU PDP threshold → {NYU omni, USC omni} → {PL, DS, AS}
%    Pipeline B: USC PDP threshold → {NYU omni, USC omni} → {PL, DS, AS}
%
%  The output Excel table has TWO major column groups:
%    NYU Threshold group: PL_SUM, PL_pDM, DS_SUM, DS_pDM, ASA_N10, ASA_U, ASD_N10, ASD_U
%    USC Threshold group: PL_SUM, PL_pDM, DS_SUM, DS_pDM, ASA_N10, ASA_U, ASD_N10, ASD_U
%
%  =========================================================================
%  METHOD COMPARISON SUMMARY
%  =========================================================================
%
%  PDP THRESHOLDING:
%    NYU: Per-directional: threshold_i = max(peak_i - 25 dB, noise_i + 5 dB)
%    USC: Global: noise_floor_i = P25(sorted_dB) + 5.41 dB per direction,
%                 global_threshold = max(all noise_floor_i) + 12 dB
%
%  OMNI SYNTHESIS:
%    NYU: SUM across all directions (linear accumulation)
%    USC: perDelayMax (max per delay bin across all directions)
%
%  ANGULAR SPREAD:
%    NYU: PAS threshold (10/15/20 dB) + lobe detection (gap>HPBW) +
%         antenna pattern boundary expansion + 3GPP sqrt(-2*ln(R))
%    USC: No PAS threshold, all measured angles → 3GPP sqrt(-2*ln(R))
%
%  DATA SOURCE:
%    - Location: D:\NYU-USC\Cross-Processing\NYU\NYU_Data\7AlignedDataset\
%    - Format: 13-column cell array per TX-RX pair
%      |1. Denoised PDP|2. TX_ID|3. RX_ID|4. Meas #|5. Rot #|
%      |6. AOD Azimuth|7. AOD Elevation|8. AOA Azimuth|9. AOA Elevation|
%      |10. Pr|11. pkIdx|12. Environment|13. Raw PDP|
%    - Files: 18 .mat files (TX1-RX1 through TX5-RX3)
%
%  TX POWER INFO (from 7GHz_Outdoor.csv):
%    - TX Power: ~15.86 dBm (varies per TX-RX pair)
%    - TX Antenna Gain: 15 dBi
%    - RX Antenna Gain: 15 dBi
%    - Frequency: 6.75 GHz
%    - HPBW: 30 degrees
%
%  Author: Mingjun Ying
%  Date: February 2026
%  Version: 1.0
%
%  ========================================================================

%% SECTION 0: CLEAR ENVIRONMENT
clear; clc; close all;

%% SECTION 1: CONFIGURATION
% =========================================================================
% SYSTEM PARAMETERS (from CSV file)
% =========================================================================
params.TX_Ant_Gain_dB = 15;        % TX antenna gain (dBi)
params.RX_Ant_Gain_dB = 15;        % RX antenna gain (dBi)
params.Frequency_GHz = 6.75;       % Carrier frequency
params.HPBW = 30;                  % Half-power beamwidth in degrees
% Optional delay gate for DS computation (parity with USC pipelines).
% Set to finite value to enable USC-style gating; default Inf preserves
% historical NYU behavior (no time-domain gate).
% At 6.75 GHz, distances reach 880 m; a hardcoded 966.67 ns gate (which
% corresponds to ~290 m of delay) zeros out long-distance NLOS points.
% USC 7 now also uses no hardcoded secondary gate (Naveed's rms_delay_spread_calc
% uses only the dynamic t_gate = (d(end)-10+d_LOS)/c, already applied upstream).
% Sub-THz pipelines (NYU 142, USC 145) keep 966.67 ns since distances are short.
params.DS_DELAY_GATE_NS = Inf;

% =========================================================================
% LOAD TX POWER LOOKUP TABLE FROM CSV
% =========================================================================
U = paths();
csv_path = U.nyu_7_tx_power_csv;
TX_power_table = load_TX_power_table(csv_path);

% =========================================================================
% DETECT DILATION FACTOR FROM DATA
% =========================================================================
% The dilation factor (samples per ns) is unknown for 7 GHz data.
% Auto-detect from the first available PDP file.
data_path_temp = U.raw_nyu_7;
params.dilation_factor = detect_dilation_factor(data_path_temp);
fprintf('  Using dilation factor: %d samples/ns\n', params.dilation_factor);

% =========================================================================
% PDP THRESHOLD SETTINGS — NYU Method
% =========================================================================
config.thres_below_pk = 25;        % dB below peak
config.thres_above_noise = 5;      % dB above noise floor
config.multipath_low_bound = -200;  % Absolute floor in dB

% =========================================================================
% PDP THRESHOLD SETTINGS — USC Method
% =========================================================================
config.usc_percentile = 25;        % Percentile for noise floor estimation
config.usc_offset_dB = 5.41;       % Added to percentile value
config.usc_margin_dB = 12;         % Margin above global noise floor

% =========================================================================
% PAS THRESHOLD SETTINGS (NYU Method only)
% =========================================================================
config.PAS_threshold_1 = 10;   % Strictest: 10 dB below peak
config.PAS_threshold_2 = 15;   % Medium: 15 dB below peak
config.PAS_threshold_3 = 20;   % Relaxed: 20 dB below peak

% =========================================================================
% ANTENNA PATTERN FILES (NYU Method — for lobe boundary expansion)
% =========================================================================
% 7 GHz antenna patterns are in .mat format (not .DAT like 142 GHz)
config.azi_pattern_file = U.nyu_7_phi0;
config.elev_pattern_file = U.nyu_7_phi90;

% =========================================================================
% IEEE FIGURE SETTINGS FOR DOUBLE-COLUMN JOURNAL
% =========================================================================
IEEE_DOUBLE_COL_WIDTH = 7.0;
IEEE_SINGLE_COL_WIDTH = 3.5;

set(0, 'DefaultAxesFontSize', 9);
set(0, 'DefaultAxesFontName', 'Times New Roman');
set(0, 'DefaultTextFontSize', 9);
set(0, 'DefaultLineLineWidth', 1.2);
set(0, 'DefaultFigureColor', 'w');
set(0, 'DefaultAxesLineWidth', 0.8);
set(0, 'DefaultAxesBox', 'on');
set(0, 'DefaultTextInterpreter', 'latex');
set(0, 'DefaultLegendInterpreter', 'latex');
set(0, 'DefaultAxesTickLabelInterpreter', 'latex');
set(0, 'DefaultAxesXGrid', 'on');
set(0, 'DefaultAxesYGrid', 'on');
set(0, 'DefaultAxesGridLineStyle', ':');
set(0, 'DefaultAxesGridAlpha', 0.3);

% Colors (colorblind-friendly)
colors.NYU_10dB = [0.0000 0.4470 0.7410];  % Blue
colors.NYU_15dB = [0.8500 0.3250 0.0980];  % Orange
colors.NYU_20dB = [0.9290 0.6940 0.1250];  % Yellow/Gold
colors.USC = [0.4660 0.6740 0.1880];        % Green
colors.NYUthr = [0.0000 0.4470 0.7410];     % Blue (NYU threshold group)
colors.USCthr = [0.8500 0.3250 0.0980];     % Orange (USC threshold group)

% =========================================================================
% PATHS
% =========================================================================
paths.data = U.raw_nyu_7;
paths.output = U.figures_nyu_7;
paths.results = U.results_nyu_7;

% Create output directories if they don't exist
if ~isfolder(paths.output), mkdir(paths.output); end
if ~isfolder(paths.results), mkdir(paths.results); end

% Display configuration
fprintf('═══════════════════════════════════════════════════════════════════════\n');
fprintf('  NYU 6.75GHz Data: Dual-Threshold Method Comparison Configuration\n');
fprintf('═══════════════════════════════════════════════════════════════════════\n');
fprintf('  Frequency: %.2f GHz, HPBW: %d°, Ant Gain: TX=%d dBi, RX=%d dBi\n', ...
    params.Frequency_GHz, params.HPBW, params.TX_Ant_Gain_dB, params.RX_Ant_Gain_dB);
fprintf('  Dilation factor: %d samples/ns\n', params.dilation_factor);
fprintf('  NYU PDP Threshold: max(%d dB below peak, %d dB above noise)\n', ...
    config.thres_below_pk, config.thres_above_noise);
fprintf('  USC PDP Threshold: P%d + %.2f dB per dir, global max + %d dB\n', ...
    config.usc_percentile, config.usc_offset_dB, config.usc_margin_dB);
fprintf('  Omni Synthesis: NYU=SUM, USC=perDelayMax\n');
fprintf('  PAS Thresholds: %d dB, %d dB, %d dB (NYU only)\n', ...
    config.PAS_threshold_1, config.PAS_threshold_2, config.PAS_threshold_3);
fprintf('  TX Power: VARIES per TX-RX pair (from CSV)\n');
fprintf('  TX Power lookup table loaded: %d unique TX-RX pairs\n', height(TX_power_table));

% Load antenna patterns for NYU lobe expansion (.mat format)
antenna_azi = load_antenna_pattern_mat(config.azi_pattern_file);
antenna_elev = load_antenna_pattern_mat(config.elev_pattern_file);
fprintf('  Antenna patterns loaded: Azimuth (%d points), Elevation (%d points)\n', ...
    size(antenna_azi, 1), size(antenna_elev, 1));
fprintf('═══════════════════════════════════════════════════════════════════════\n\n');

%% SECTION 2: INITIALIZE RESULTS STORAGE
fprintf('╔═══════════════════════════════════════════════════════════════════════╗\n');
fprintf('║    Processing NYU 6.75GHz Data with Dual Thresholds × Dual Methods   ║\n');
fprintf('╚═══════════════════════════════════════════════════════════════════════╝\n\n');

% Get list of data files
data_files = dir(fullfile(paths.data, 'Data7Pack_TX*_RX*_Aligned.mat'));
nFiles = length(data_files);
fprintf('Found %d TX-RX location files\n\n', nFiles);

% Initialize results storage — Metadata
results.TX_RX_ID = cell(nFiles, 1);
results.Environment = cell(nFiles, 1);
results.TX_ID = zeros(nFiles, 1);
results.RX_ID = zeros(nFiles, 1);
results.TX_Power_dBm = zeros(nFiles, 1);
results.Distance_m = zeros(nFiles, 1);

% === NYU THRESHOLD GROUP ===
% Path Loss
results.PL_NYUthr_SUM = zeros(nFiles, 1);
results.PL_NYUthr_pDM = zeros(nFiles, 1);
% Delay Spread
results.DS_NYUthr_SUM = zeros(nFiles, 1);
results.DS_NYUthr_pDM = zeros(nFiles, 1);
% ASA — NYU AS method (10/15/20 dB PAS threshold + lobe expansion)
results.ASA_NYUthr_N10 = zeros(nFiles, 1);
results.ASA_NYUthr_N15 = zeros(nFiles, 1);
results.ASA_NYUthr_N20 = zeros(nFiles, 1);
% ASA — USC AS method (no PAS threshold)
results.ASA_NYUthr_U = zeros(nFiles, 1);
% ASD — NYU AS method
results.ASD_NYUthr_N10 = zeros(nFiles, 1);
results.ASD_NYUthr_N15 = zeros(nFiles, 1);
results.ASD_NYUthr_N20 = zeros(nFiles, 1);
% ASD — USC AS method
results.ASD_NYUthr_U = zeros(nFiles, 1);

% === USC THRESHOLD GROUP ===
% Path Loss
results.PL_USCthr_SUM = zeros(nFiles, 1);
results.PL_USCthr_pDM = zeros(nFiles, 1);
% Delay Spread
results.DS_USCthr_SUM = zeros(nFiles, 1);
results.DS_USCthr_pDM = zeros(nFiles, 1);
% ASA — NYU AS method
results.ASA_USCthr_N10 = zeros(nFiles, 1);
results.ASA_USCthr_N15 = zeros(nFiles, 1);
results.ASA_USCthr_N20 = zeros(nFiles, 1);
% ASA — USC AS method
results.ASA_USCthr_U = zeros(nFiles, 1);
% ASD — NYU AS method
results.ASD_USCthr_N10 = zeros(nFiles, 1);
results.ASD_USCthr_N15 = zeros(nFiles, 1);
results.ASD_USCthr_N20 = zeros(nFiles, 1);
% ASD — USC AS method
results.ASD_USCthr_U = zeros(nFiles, 1);

% Store PAS data for visualization (first LOS and NLOS under each threshold)
pas_store = struct();

% Load distance data from CSV for each TX-RX pair
try
    csv_data = readtable(csv_path);
catch
    csv_data = [];
end

%% SECTION 3: PROCESS EACH TX-RX PAIR (DUAL THRESHOLD)
for iFile = 1:nFiles
    fname = data_files(iFile).name;
    filepath = fullfile(paths.data, fname);

    % Parse TX-RX IDs from filename: Data7Pack_TX1_RX1_Aligned.mat
    tokens = regexp(fname, 'TX(\d+)_RX(\d+)', 'tokens');
    if ~isempty(tokens)
        TX_ID = str2double(tokens{1}{1});
        RX_ID = str2double(tokens{1}{2});
        TX_RX_ID = sprintf('TX%d-RX%d', TX_ID, RX_ID);
    else
        TX_ID = iFile;
        RX_ID = iFile;
        TX_RX_ID = fname;
    end

    results.TX_RX_ID{iFile} = TX_RX_ID;
    results.TX_ID(iFile) = TX_ID;
    results.RX_ID(iFile) = RX_ID;

    % Get TX power for this TX-RX pair from lookup table
    TX_Power_dBm = get_TX_power(TX_power_table, TX_ID, RX_ID);
    results.TX_Power_dBm(iFile) = TX_Power_dBm;

    % Get distance and Environment from CSV
    if ~isempty(csv_data)
        try
            mask_csv = (csv_data.TX_ID == TX_ID) & (csv_data.RX_ID == RX_ID);
            if any(mask_csv)
                first_idx = find(mask_csv, 1);
                results.Distance_m(iFile) = csv_data.TR_Separation(first_idx);
                % LOS/NLOS is in Environment_Setting column (not Environment which is 'Outdoor')
                env_val = csv_data.Environment_Setting{first_idx};
                if ischar(env_val) || isstring(env_val)
                    results.Environment{iFile} = char(env_val);
                else
                    results.Environment{iFile} = 'Unknown';
                end
            end
        catch
            % CSV columns might differ
        end
    end

    fprintf('Processing [%2d/%2d] %s (Ptx=%.2f dBm, d=%.1f m) ...\n', ...
        iFile, nFiles, TX_RX_ID, TX_Power_dBm, results.Distance_m(iFile));

    % Load data
    data = load(filepath);
    fnames_data = fieldnames(data);
    TRpdpSet = data.(fnames_data{1});

    % Environment (LOS/NLOS) already loaded from CSV Environment_Setting above
    % Column 12 in the .mat data stores 'Outdoor' (not LOS/NLOS)

    % =================================================================
    % PIPELINE A: NYU PDP THRESHOLD
    % =================================================================
    [TRpdpSet_NYUthr, noise_floor_NYU_dB] = apply_NYU_PDP_threshold(TRpdpSet, config, params);

    % Generate PAS (AOA col 8, AOD col 6)
    [AOA_angles_Nt, AOA_powers_Nt, ~] = generate_PAS(TRpdpSet_NYUthr, 8, 6, config.multipath_low_bound);
    [AOD_angles_Nt, AOD_powers_Nt, ~] = generate_PAS(TRpdpSet_NYUthr, 6, 8, config.multipath_low_bound);

    % Omni PDP — NYU SUM
    [OmniPDP_Nt_SUM, delays_ns] = compute_omni_NYU(TRpdpSet_NYUthr, params);
    % Omni PDP — USC perDelayMax
    [OmniPDP_Nt_pDM, ~] = compute_omni_USC(TRpdpSet_NYUthr, params);

    % Path Loss (NYU threshold)
    % Guard: if threshold killed all signal, sum(OmniPDP)≈0 → PL nonsensical → NaN
    Pr_Nt_SUM_lin = sum(OmniPDP_Nt_SUM);
    Pr_Nt_pDM_lin = sum(OmniPDP_Nt_pDM);
    if Pr_Nt_SUM_lin > 0
        results.PL_NYUthr_SUM(iFile) = TX_Power_dBm + params.TX_Ant_Gain_dB + params.RX_Ant_Gain_dB - 10*log10(Pr_Nt_SUM_lin);
    else
        results.PL_NYUthr_SUM(iFile) = NaN;
    end
    if Pr_Nt_pDM_lin > 0
        results.PL_NYUthr_pDM(iFile) = TX_Power_dBm + params.TX_Ant_Gain_dB + params.RX_Ant_Gain_dB - 10*log10(Pr_Nt_pDM_lin);
    else
        results.PL_NYUthr_pDM(iFile) = NaN;
    end

    % Delay Spread (NYU threshold) — with optional delay gate for USC-parity
    results.DS_NYUthr_SUM(iFile) = compute_RMS_DS(delays_ns, OmniPDP_Nt_SUM, params.DS_DELAY_GATE_NS);
    results.DS_NYUthr_pDM(iFile) = compute_RMS_DS(delays_ns, OmniPDP_Nt_pDM, params.DS_DELAY_GATE_NS);

    % Angular Spread — NYU AS method (NYU threshold)
    [results.ASA_NYUthr_N10(iFile), ~, ~] = compute_AS_NYU(AOA_angles_Nt, AOA_powers_Nt, config.PAS_threshold_1, config.multipath_low_bound, antenna_azi, params.HPBW);
    [results.ASA_NYUthr_N15(iFile), ~, ~] = compute_AS_NYU(AOA_angles_Nt, AOA_powers_Nt, config.PAS_threshold_2, config.multipath_low_bound, antenna_azi, params.HPBW);
    [results.ASA_NYUthr_N20(iFile), ~, ~] = compute_AS_NYU(AOA_angles_Nt, AOA_powers_Nt, config.PAS_threshold_3, config.multipath_low_bound, antenna_azi, params.HPBW);
    [results.ASD_NYUthr_N10(iFile), ~, ~] = compute_AS_NYU(AOD_angles_Nt, AOD_powers_Nt, config.PAS_threshold_1, config.multipath_low_bound, antenna_azi, params.HPBW);
    [results.ASD_NYUthr_N15(iFile), ~, ~] = compute_AS_NYU(AOD_angles_Nt, AOD_powers_Nt, config.PAS_threshold_2, config.multipath_low_bound, antenna_azi, params.HPBW);
    [results.ASD_NYUthr_N20(iFile), ~, ~] = compute_AS_NYU(AOD_angles_Nt, AOD_powers_Nt, config.PAS_threshold_3, config.multipath_low_bound, antenna_azi, params.HPBW);

    % Angular Spread — USC AS method (NYU threshold, no PAS threshold)
    results.ASA_NYUthr_U(iFile) = compute_AS_USC(AOA_angles_Nt, AOA_powers_Nt, config.multipath_low_bound);
    results.ASD_NYUthr_U(iFile) = compute_AS_USC(AOD_angles_Nt, AOD_powers_Nt, config.multipath_low_bound);

    % =================================================================
    % PIPELINE B: USC PDP THRESHOLD
    % =================================================================
    [TRpdpSet_USCthr, global_threshold_USC_dB] = apply_USC_PDP_threshold(TRpdpSet, config);

    % Generate PAS (same columns)
    [AOA_angles_Ut, AOA_powers_Ut, ~] = generate_PAS(TRpdpSet_USCthr, 8, 6, config.multipath_low_bound);
    [AOD_angles_Ut, AOD_powers_Ut, ~] = generate_PAS(TRpdpSet_USCthr, 6, 8, config.multipath_low_bound);

    % Omni PDP — NYU SUM
    [OmniPDP_Ut_SUM, ~] = compute_omni_NYU(TRpdpSet_USCthr, params);
    % Omni PDP — USC perDelayMax
    [OmniPDP_Ut_pDM, ~] = compute_omni_USC(TRpdpSet_USCthr, params);

    % Path Loss (USC threshold)
    % Guard: if threshold killed all signal, sum(OmniPDP)≈0 → PL nonsensical → NaN
    Pr_Ut_SUM_lin = sum(OmniPDP_Ut_SUM);
    Pr_Ut_pDM_lin = sum(OmniPDP_Ut_pDM);
    if Pr_Ut_SUM_lin > 0
        results.PL_USCthr_SUM(iFile) = TX_Power_dBm + params.TX_Ant_Gain_dB + params.RX_Ant_Gain_dB - 10*log10(Pr_Ut_SUM_lin);
    else
        results.PL_USCthr_SUM(iFile) = NaN;
    end
    if Pr_Ut_pDM_lin > 0
        results.PL_USCthr_pDM(iFile) = TX_Power_dBm + params.TX_Ant_Gain_dB + params.RX_Ant_Gain_dB - 10*log10(Pr_Ut_pDM_lin);
    else
        results.PL_USCthr_pDM(iFile) = NaN;
    end

    % Delay Spread (USC threshold) — with optional delay gate for USC-parity
    results.DS_USCthr_SUM(iFile) = compute_RMS_DS(delays_ns, OmniPDP_Ut_SUM, params.DS_DELAY_GATE_NS);
    results.DS_USCthr_pDM(iFile) = compute_RMS_DS(delays_ns, OmniPDP_Ut_pDM, params.DS_DELAY_GATE_NS);

    % Angular Spread — NYU AS method (USC threshold)
    [results.ASA_USCthr_N10(iFile), ~, ~] = compute_AS_NYU(AOA_angles_Ut, AOA_powers_Ut, config.PAS_threshold_1, config.multipath_low_bound, antenna_azi, params.HPBW);
    [results.ASA_USCthr_N15(iFile), ~, ~] = compute_AS_NYU(AOA_angles_Ut, AOA_powers_Ut, config.PAS_threshold_2, config.multipath_low_bound, antenna_azi, params.HPBW);
    [results.ASA_USCthr_N20(iFile), ~, ~] = compute_AS_NYU(AOA_angles_Ut, AOA_powers_Ut, config.PAS_threshold_3, config.multipath_low_bound, antenna_azi, params.HPBW);
    [results.ASD_USCthr_N10(iFile), ~, ~] = compute_AS_NYU(AOD_angles_Ut, AOD_powers_Ut, config.PAS_threshold_1, config.multipath_low_bound, antenna_azi, params.HPBW);
    [results.ASD_USCthr_N15(iFile), ~, ~] = compute_AS_NYU(AOD_angles_Ut, AOD_powers_Ut, config.PAS_threshold_2, config.multipath_low_bound, antenna_azi, params.HPBW);
    [results.ASD_USCthr_N20(iFile), ~, ~] = compute_AS_NYU(AOD_angles_Ut, AOD_powers_Ut, config.PAS_threshold_3, config.multipath_low_bound, antenna_azi, params.HPBW);

    % Angular Spread — USC AS method (USC threshold, no PAS threshold)
    results.ASA_USCthr_U(iFile) = compute_AS_USC(AOA_angles_Ut, AOA_powers_Ut, config.multipath_low_bound);
    results.ASD_USCthr_U(iFile) = compute_AS_USC(AOD_angles_Ut, AOD_powers_Ut, config.multipath_low_bound);

    % Store PAS for first LOS and NLOS locations (for visualization)
    if strcmp(results.Environment{iFile}, 'LOS') && ~isfield(pas_store, 'LOS')
        pas_store.LOS.TX_RX_ID = TX_RX_ID;
        pas_store.LOS.AOA_angles_Nt = AOA_angles_Nt;
        pas_store.LOS.AOA_powers_Nt = AOA_powers_Nt;
        pas_store.LOS.AOD_angles_Nt = AOD_angles_Nt;
        pas_store.LOS.AOD_powers_Nt = AOD_powers_Nt;
        pas_store.LOS.AOA_angles_Ut = AOA_angles_Ut;
        pas_store.LOS.AOA_powers_Ut = AOA_powers_Ut;
        pas_store.LOS.OmniPDP_Nt_SUM = OmniPDP_Nt_SUM;
        pas_store.LOS.OmniPDP_Nt_pDM = OmniPDP_Nt_pDM;
        pas_store.LOS.OmniPDP_Ut_SUM = OmniPDP_Ut_SUM;
        pas_store.LOS.OmniPDP_Ut_pDM = OmniPDP_Ut_pDM;
        pas_store.LOS.delays_ns = delays_ns;
    elseif ~strcmp(results.Environment{iFile}, 'LOS') && ~isfield(pas_store, 'NLOS')
        pas_store.NLOS.TX_RX_ID = TX_RX_ID;
        pas_store.NLOS.AOA_angles_Nt = AOA_angles_Nt;
        pas_store.NLOS.AOA_powers_Nt = AOA_powers_Nt;
        pas_store.NLOS.AOD_angles_Nt = AOD_angles_Nt;
        pas_store.NLOS.AOD_powers_Nt = AOD_powers_Nt;
        pas_store.NLOS.AOA_angles_Ut = AOA_angles_Ut;
        pas_store.NLOS.AOA_powers_Ut = AOA_powers_Ut;
        pas_store.NLOS.OmniPDP_Nt_SUM = OmniPDP_Nt_SUM;
        pas_store.NLOS.OmniPDP_Nt_pDM = OmniPDP_Nt_pDM;
        pas_store.NLOS.OmniPDP_Ut_SUM = OmniPDP_Ut_SUM;
        pas_store.NLOS.OmniPDP_Ut_pDM = OmniPDP_Ut_pDM;
        pas_store.NLOS.delays_ns = delays_ns;
    end

    fprintf('  NYU thr: PL_SUM=%.1f, PL_pDM=%.1f | DS_SUM=%.1f, DS_pDM=%.1f ns\n', ...
        results.PL_NYUthr_SUM(iFile), results.PL_NYUthr_pDM(iFile), ...
        results.DS_NYUthr_SUM(iFile), results.DS_NYUthr_pDM(iFile));
    fprintf('  USC thr: PL_SUM=%.1f, PL_pDM=%.1f | DS_SUM=%.1f, DS_pDM=%.1f ns\n', ...
        results.PL_USCthr_SUM(iFile), results.PL_USCthr_pDM(iFile), ...
        results.DS_USCthr_SUM(iFile), results.DS_USCthr_pDM(iFile));
    fprintf('  NYU thr noise=%.1f dB | USC thr global=%.1f dB | Env=%s\n\n', ...
        noise_floor_NYU_dB, global_threshold_USC_dB, results.Environment{iFile});
end

fprintf('\nProcessing complete!\n\n');

%% SECTION 4: GENERATE CONSOLE TABLES
% =========================================================================
% TABLE 1: Method Comparison Summary
% =========================================================================
fprintf('╔═══════════════════════════════════════════════════════════════════════════════════════════════════════════╗\n');
fprintf('║                               TABLE 1: METHOD COMPARISON SUMMARY                                       ║\n');
fprintf('╠════════════════════════╤═══════════════════════════════════════╤═══════════════════════════════════════════╣\n');
fprintf('║ Aspect                 │ NYU Method                            │ USC Method                                ║\n');
fprintf('╠════════════════════════╪═══════════════════════════════════════╪═══════════════════════════════════════════╣\n');
fprintf('║ PDP Threshold (NYU)    │ max(25dB below pk, 5dB abv noise)     │ SAME (per-directional)                    ║\n');
fprintf('║ PDP Threshold (USC)    │ global: P25+5.41 per dir, max+12dB    │ SAME (global)                             ║\n');
fprintf('║ Omni Synthesis         │ SUM across all directions              │ perDelayMax (max per delay)               ║\n');
fprintf('║ PAS Threshold          │ 10/15/20 dB below peak                 │ NONE                                      ║\n');
fprintf('║ Lobe Expansion         │ Antenna pattern-based (HPBW=%d°)      │ NONE                                      ║\n', params.HPBW);
fprintf('║ AS Formula             │ 3GPP: sqrt(-2*ln(R))                   │ SAME                                      ║\n');
fprintf('╚════════════════════════╧═══════════════════════════════════════╧═══════════════════════════════════════════╝\n\n');

% =========================================================================
% TABLE 2: Per TX-RX Pair Results (NYU Threshold)
% =========================================================================
fprintf('╔══════════════════════════════════════════════════════════════════════════════════════════════════════════════╗\n');
fprintf('║                        TABLE 2A: PER TX-RX RESULTS — NYU PDP THRESHOLD                                    ║\n');
fprintf('╠══════════╤═════╤═══════╤══════════════════════╤══════════════════════╤══════════════════════════════════════╣\n');
fprintf('║  TX-RX   │ Env │ d(m)  │ Path Loss (dB)       │ Delay Spread (ns)    │ Angular Spread (deg)                 ║\n');
fprintf('║          │     │       │  SUM    │  pDM        │  SUM    │  pDM        │ ASA-N10 │ ASA-U  │ ASD-N10 │ ASD-U ║\n');
fprintf('╠══════════╪═════╪═══════╪═════════╪════════════╪═════════╪════════════╪═════════╪════════╪═════════╪════════╣\n');

for i = 1:nFiles
    fprintf('║ %-8s │ %-3s │ %5.1f │ %7.1f │ %7.1f   │ %7.2f │ %7.2f   │ %6.1f  │ %5.1f  │ %6.1f  │ %5.1f ║\n', ...
        results.TX_RX_ID{i}, results.Environment{i}(1:min(3,end)), results.Distance_m(i), ...
        results.PL_NYUthr_SUM(i), results.PL_NYUthr_pDM(i), ...
        results.DS_NYUthr_SUM(i), results.DS_NYUthr_pDM(i), ...
        results.ASA_NYUthr_N10(i), results.ASA_NYUthr_U(i), ...
        results.ASD_NYUthr_N10(i), results.ASD_NYUthr_U(i));
end
fprintf('╚══════════╧═════╧═══════╧═════════╧════════════╧═════════╧════════════╧═════════╧════════╧═════════╧════════╝\n\n');

% =========================================================================
% TABLE 2B: Per TX-RX Pair Results (USC Threshold)
% =========================================================================
fprintf('╔══════════════════════════════════════════════════════════════════════════════════════════════════════════════╗\n');
fprintf('║                        TABLE 2B: PER TX-RX RESULTS — USC PDP THRESHOLD                                    ║\n');
fprintf('╠══════════╤═════╤═══════╤══════════════════════╤══════════════════════╤══════════════════════════════════════╣\n');
fprintf('║  TX-RX   │ Env │ d(m)  │ Path Loss (dB)       │ Delay Spread (ns)    │ Angular Spread (deg)                 ║\n');
fprintf('║          │     │       │  SUM    │  pDM        │  SUM    │  pDM        │ ASA-N10 │ ASA-U  │ ASD-N10 │ ASD-U ║\n');
fprintf('╠══════════╪═════╪═══════╪═════════╪════════════╪═════════╪════════════╪═════════╪════════╪═════════╪════════╣\n');

for i = 1:nFiles
    fprintf('║ %-8s │ %-3s │ %5.1f │ %7.1f │ %7.1f   │ %7.2f │ %7.2f   │ %6.1f  │ %5.1f  │ %6.1f  │ %5.1f ║\n', ...
        results.TX_RX_ID{i}, results.Environment{i}(1:min(3,end)), results.Distance_m(i), ...
        results.PL_USCthr_SUM(i), results.PL_USCthr_pDM(i), ...
        results.DS_USCthr_SUM(i), results.DS_USCthr_pDM(i), ...
        results.ASA_USCthr_N10(i), results.ASA_USCthr_U(i), ...
        results.ASD_USCthr_N10(i), results.ASD_USCthr_U(i));
end
fprintf('╚══════════╧═════╧═══════╧═════════╧════════════╧═════════╧════════════╧═════════╧════════╧═════════╧════════╝\n\n');

% =========================================================================
% TABLE 3: Statistical Summary
% =========================================================================
los_mask = strcmp(results.Environment, 'LOS');
nlos_mask = ~los_mask;

fprintf('╔═══════════════════════════════════════════════════════════════════════════════════════════════════════════════╗\n');
fprintf('║                                   TABLE 3: STATISTICAL SUMMARY                                              ║\n');
fprintf('╠══════════════════════════════════════╤═══════════════════════════════╤═════════════════════════════════════════╣\n');
fprintf('║ Metric                               │    LOS (mean ± std)           │    NLOS (mean ± std)    │    ALL       ║\n');
fprintf('╠══════════════════════════════════════╪═══════════════════════════════╪═════════════════════════════════════════╣\n');

% NYU Threshold group
fprintf('║ --- NYU PDP Threshold ---            │                               │                                         ║\n');
print_stat_row('PL-SUM (dB)', results.PL_NYUthr_SUM, los_mask, nlos_mask);
print_stat_row('PL-pDM (dB)', results.PL_NYUthr_pDM, los_mask, nlos_mask);
print_stat_row('DS-SUM (ns)', results.DS_NYUthr_SUM, los_mask, nlos_mask);
print_stat_row('DS-pDM (ns)', results.DS_NYUthr_pDM, los_mask, nlos_mask);
print_stat_row('ASA-N10 (deg)', results.ASA_NYUthr_N10, los_mask, nlos_mask);
print_stat_row('ASA-U (deg)', results.ASA_NYUthr_U, los_mask, nlos_mask);
print_stat_row('ASD-N10 (deg)', results.ASD_NYUthr_N10, los_mask, nlos_mask);
print_stat_row('ASD-U (deg)', results.ASD_NYUthr_U, los_mask, nlos_mask);
fprintf('╠══════════════════════════════════════╪═══════════════════════════════╪═════════════════════════════════════════╣\n');

% USC Threshold group
fprintf('║ --- USC PDP Threshold ---            │                               │                                         ║\n');
print_stat_row('PL-SUM (dB)', results.PL_USCthr_SUM, los_mask, nlos_mask);
print_stat_row('PL-pDM (dB)', results.PL_USCthr_pDM, los_mask, nlos_mask);
print_stat_row('DS-SUM (ns)', results.DS_USCthr_SUM, los_mask, nlos_mask);
print_stat_row('DS-pDM (ns)', results.DS_USCthr_pDM, los_mask, nlos_mask);
print_stat_row('ASA-N10 (deg)', results.ASA_USCthr_N10, los_mask, nlos_mask);
print_stat_row('ASA-U (deg)', results.ASA_USCthr_U, los_mask, nlos_mask);
print_stat_row('ASD-N10 (deg)', results.ASD_USCthr_N10, los_mask, nlos_mask);
print_stat_row('ASD-U (deg)', results.ASD_USCthr_U, los_mask, nlos_mask);
fprintf('╚══════════════════════════════════════╧═══════════════════════════════╧═════════════════════════════════════════╝\n\n');

% =========================================================================
% TABLE 4: Threshold Comparison — Δ(NYU_thr − USC_thr) per metric
% =========================================================================
fprintf('╔═══════════════════════════════════════════════════════════════════════════════╗\n');
fprintf('║         TABLE 4: THRESHOLD COMPARISON — Δ(NYU_thr − USC_thr)                ║\n');
fprintf('╠═══════════════════════════╤═══════════════════╤══════════════════════════════╣\n');
fprintf('║ Metric                    │ LOS (mean ± std)  │ NLOS (mean ± std)  │  ALL   ║\n');
fprintf('╠═══════════════════════════╪═══════════════════╪══════════════════════════════╣\n');

delta_PL_SUM = results.PL_NYUthr_SUM - results.PL_USCthr_SUM;
delta_PL_pDM = results.PL_NYUthr_pDM - results.PL_USCthr_pDM;
delta_DS_SUM = results.DS_NYUthr_SUM - results.DS_USCthr_SUM;
delta_DS_pDM = results.DS_NYUthr_pDM - results.DS_USCthr_pDM;
delta_ASA_N10 = results.ASA_NYUthr_N10 - results.ASA_USCthr_N10;
delta_ASA_U = results.ASA_NYUthr_U - results.ASA_USCthr_U;
delta_ASD_N10 = results.ASD_NYUthr_N10 - results.ASD_USCthr_N10;
delta_ASD_U = results.ASD_NYUthr_U - results.ASD_USCthr_U;

print_stat_row('ΔPL-SUM (dB)', delta_PL_SUM, los_mask, nlos_mask);
print_stat_row('ΔPL-pDM (dB)', delta_PL_pDM, los_mask, nlos_mask);
print_stat_row('ΔDS-SUM (ns)', delta_DS_SUM, los_mask, nlos_mask);
print_stat_row('ΔDS-pDM (ns)', delta_DS_pDM, los_mask, nlos_mask);
print_stat_row('ΔASA-N10 (deg)', delta_ASA_N10, los_mask, nlos_mask);
print_stat_row('ΔASA-U (deg)', delta_ASA_U, los_mask, nlos_mask);
print_stat_row('ΔASD-N10 (deg)', delta_ASD_N10, los_mask, nlos_mask);
print_stat_row('ΔASD-U (deg)', delta_ASD_U, los_mask, nlos_mask);
fprintf('╚═══════════════════════════╧═══════════════════╧══════════════════════════════╝\n\n');

%% SECTION 5: GENERATE FIGURES
% =========================================================================
% FIGURE 1: Omni PDP Comparison (NYU SUM vs USC pDM, both thresholds)
% =========================================================================
fig1 = figure('Units', 'inches', 'Position', [1 1 IEEE_DOUBLE_COL_WIDTH 5.5], 'Name', 'Fig1: Omni PDP Comparison');

envNames = {'LOS', 'NLOS'};
for eIdx = 1:2
    eName = envNames{eIdx};
    if ~isfield(pas_store, eName), continue; end
    ps = pas_store.(eName);

    % NYU threshold row
    subplot(2,2,(eIdx-1)*2 + 1);
    plot(ps.delays_ns, 10*log10(ps.OmniPDP_Nt_SUM + eps), 'Color', colors.NYU_10dB, 'LineWidth', 1.2, 'DisplayName', 'NYU (SUM)');
    hold on;
    plot(ps.delays_ns, 10*log10(ps.OmniPDP_Nt_pDM + eps), 'Color', colors.USC, 'LineWidth', 1.2, 'DisplayName', 'USC (pDM)');
    xlabel('Delay (ns)', 'FontSize', 10, 'Interpreter', 'latex');
    ylabel('Power (dB)', 'FontSize', 10, 'Interpreter', 'latex');
    title(sprintf('%s %s — NYU Thr', eName, ps.TX_RX_ID), 'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'none');
    legend('Location', 'northeast', 'FontSize', 8, 'Box', 'off', 'Interpreter', 'latex');
    grid on; set(gca, 'FontSize', 9);

    % USC threshold row
    subplot(2,2,(eIdx-1)*2 + 2);
    plot(ps.delays_ns, 10*log10(ps.OmniPDP_Ut_SUM + eps), 'Color', colors.NYU_10dB, 'LineWidth', 1.2, 'DisplayName', 'NYU (SUM)');
    hold on;
    plot(ps.delays_ns, 10*log10(ps.OmniPDP_Ut_pDM + eps), 'Color', colors.USC, 'LineWidth', 1.2, 'DisplayName', 'USC (pDM)');
    xlabel('Delay (ns)', 'FontSize', 10, 'Interpreter', 'latex');
    ylabel('Power (dB)', 'FontSize', 10, 'Interpreter', 'latex');
    title(sprintf('%s %s — USC Thr', eName, ps.TX_RX_ID), 'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'none');
    legend('Location', 'northeast', 'FontSize', 8, 'Box', 'off', 'Interpreter', 'latex');
    grid on; set(gca, 'FontSize', 9);
end

set(fig1, 'PaperPositionMode', 'auto');
savefig(fig1, fullfile(paths.output, 'Fig1_OmniPDP_Comparison.fig'));
exportgraphics(fig1, fullfile(paths.output, 'Fig1_OmniPDP_Comparison.png'), 'Resolution', 300, 'BackgroundColor', 'white');
exportgraphics(fig1, fullfile(paths.output, 'Fig1_OmniPDP_Comparison.pdf'), 'ContentType', 'vector', 'BackgroundColor', 'white');

% =========================================================================
% FIGURE 2: PAS Display with Threshold Lines (Both thresholds side by side)
% =========================================================================
fig2 = figure('Units', 'inches', 'Position', [1 1 IEEE_DOUBLE_COL_WIDTH 5.5], 'Name', 'Fig2: PAS Display');

if isfield(pas_store, 'LOS')
    ps = pas_store.LOS;
    % NYU threshold AOA
    subplot(2,2,1);
    stem(ps.AOA_angles_Nt, 10.^(ps.AOA_powers_Nt/10), 'Color', [0.7 0.7 0.7], 'LineWidth', 1, 'MarkerSize', 3);
    hold on;
    peak_lin = max(10.^(ps.AOA_powers_Nt/10));
    yline(peak_lin * 10^(-config.PAS_threshold_1/10), 'r--', 'LineWidth', 1.5, 'Label', sprintf('%ddB thr', config.PAS_threshold_1));
    xlabel('AOA Azimuth ($^\circ$)', 'FontSize', 10, 'Interpreter', 'latex');
    ylabel('Power (linear)', 'FontSize', 10, 'Interpreter', 'latex');
    title(sprintf('(a) AOA - LOS %s — NYU Thr', ps.TX_RX_ID), 'FontSize', 9, 'Interpreter', 'none');
    grid on;

    % USC threshold AOA
    subplot(2,2,2);
    stem(ps.AOA_angles_Ut, 10.^(ps.AOA_powers_Ut/10), 'Color', [0.7 0.7 0.7], 'LineWidth', 1, 'MarkerSize', 3);
    hold on;
    peak_lin = max(10.^(ps.AOA_powers_Ut/10));
    yline(peak_lin * 10^(-config.PAS_threshold_1/10), 'r--', 'LineWidth', 1.5, 'Label', sprintf('%ddB thr', config.PAS_threshold_1));
    xlabel('AOA Azimuth ($^\circ$)', 'FontSize', 10, 'Interpreter', 'latex');
    ylabel('Power (linear)', 'FontSize', 10, 'Interpreter', 'latex');
    title(sprintf('(b) AOA - LOS %s — USC Thr', ps.TX_RX_ID), 'FontSize', 9, 'Interpreter', 'none');
    grid on;
end

if isfield(pas_store, 'NLOS')
    ps = pas_store.NLOS;
    subplot(2,2,3);
    stem(ps.AOA_angles_Nt, 10.^(ps.AOA_powers_Nt/10), 'Color', [0.7 0.7 0.7], 'LineWidth', 1, 'MarkerSize', 3);
    hold on;
    peak_lin = max(10.^(ps.AOA_powers_Nt/10));
    yline(peak_lin * 10^(-config.PAS_threshold_1/10), 'r--', 'LineWidth', 1.5, 'Label', sprintf('%ddB thr', config.PAS_threshold_1));
    xlabel('AOA Azimuth ($^\circ$)', 'FontSize', 10, 'Interpreter', 'latex');
    ylabel('Power (linear)', 'FontSize', 10, 'Interpreter', 'latex');
    title(sprintf('(c) AOA - NLOS %s — NYU Thr', ps.TX_RX_ID), 'FontSize', 9, 'Interpreter', 'none');
    grid on;

    subplot(2,2,4);
    stem(ps.AOA_angles_Ut, 10.^(ps.AOA_powers_Ut/10), 'Color', [0.7 0.7 0.7], 'LineWidth', 1, 'MarkerSize', 3);
    hold on;
    peak_lin = max(10.^(ps.AOA_powers_Ut/10));
    yline(peak_lin * 10^(-config.PAS_threshold_1/10), 'r--', 'LineWidth', 1.5, 'Label', sprintf('%ddB thr', config.PAS_threshold_1));
    xlabel('AOA Azimuth ($^\circ$)', 'FontSize', 10, 'Interpreter', 'latex');
    ylabel('Power (linear)', 'FontSize', 10, 'Interpreter', 'latex');
    title(sprintf('(d) AOA - NLOS %s — USC Thr', ps.TX_RX_ID), 'FontSize', 9, 'Interpreter', 'none');
    grid on;
end

savefig(fig2, fullfile(paths.output, 'Fig2_PAS_Display.fig'));
exportgraphics(fig2, fullfile(paths.output, 'Fig2_PAS_Display.png'), 'Resolution', 300, 'BackgroundColor', 'white');
exportgraphics(fig2, fullfile(paths.output, 'Fig2_PAS_Display.pdf'), 'ContentType', 'vector', 'BackgroundColor', 'white');

% =========================================================================
% FIGURES 3a-3d: CDF Plots with DKW 95% Confidence Bands (LOS/NLOS)
% =========================================================================
% Each metric gets its own figure with 1x2 subplots (LOS, NLOS)
% Format matches cdf_ci_as_analysis.m reference

colorNYUthr = [0 0.45 0.74];      % Blue for NYU threshold
colorUSCthr = [0.85 0.33 0.10];   % Orange for USC threshold

% Define CDF metric configurations:
% {metricName, NYUthr_NYUmethod, NYUthr_USCmethod, USCthr_NYUmethod, USCthr_USCmethod, xLabel, fileTag}
cdf_metrics = {
    'Path Loss', results.PL_NYUthr_SUM, results.PL_NYUthr_pDM, ...
                 results.PL_USCthr_SUM, results.PL_USCthr_pDM, 'Path Loss [dB]', 'PL';
    'Delay Spread', results.DS_NYUthr_SUM, results.DS_NYUthr_pDM, ...
                    results.DS_USCthr_SUM, results.DS_USCthr_pDM, 'RMS Delay Spread [ns]', 'DS';
    'ASA', results.ASA_NYUthr_N10, results.ASA_NYUthr_U, ...
           results.ASA_USCthr_N10, results.ASA_USCthr_U, 'ASA [$^\circ$]', 'ASA';
    'ASD', results.ASD_NYUthr_N10, results.ASD_NYUthr_U, ...
           results.ASD_USCthr_N10, results.ASD_USCthr_U, 'ASD [$^\circ$]', 'ASD';
};

for cm = 1:size(cdf_metrics, 1)
    metricName = cdf_metrics{cm, 1};
    d_Nt_NYU = cdf_metrics{cm, 2};  % NYU thr + NYU method
    d_Nt_USC = cdf_metrics{cm, 3};  % NYU thr + USC method
    d_Ut_NYU = cdf_metrics{cm, 4};  % USC thr + NYU method
    d_Ut_USC = cdf_metrics{cm, 5};  % USC thr + USC method
    xLabel   = cdf_metrics{cm, 6};
    fileTag  = cdf_metrics{cm, 7};

    figCDF = figure('Name', ['CDF: ' metricName], 'Position', [100, 100, 1100, 450]);

    % ----- LOS subplot -----
    subplot(1, 2, 1);
    hold on; grid on; box on;

    hNtNYU = plot_cdf_with_band(d_Nt_NYU(los_mask), colorNYUthr, '-', 'NYU thr + NYU method');
    hNtUSC = plot_cdf_with_band(d_Nt_USC(los_mask), colorNYUthr, '--', 'NYU thr + USC method');
    hUtNYU = plot_cdf_with_band(d_Ut_NYU(los_mask), colorUSCthr, '-', 'USC thr + NYU method');
    hUtUSC = plot_cdf_with_band(d_Ut_USC(los_mask), colorUSCthr, '--', 'USC thr + USC method');

    title([metricName ' CDF (LOS)'], 'FontSize', 12, 'FontWeight', 'bold');
    xlabel(xLabel, 'FontSize', 11, 'Interpreter', 'tex');
    ylabel('CDF', 'FontSize', 11);
    legend([hNtNYU, hNtUSC, hUtNYU, hUtUSC], ...
        {'NYU thr + NYU method', 'NYU thr + USC method', ...
         'USC thr + NYU method', 'USC thr + USC method'}, ...
        'Location', 'southeast', 'FontSize', 8);
    set(gca, 'FontSize', 10);

    % ----- NLOS subplot -----
    subplot(1, 2, 2);
    hold on; grid on; box on;

    hNtNYU = plot_cdf_with_band(d_Nt_NYU(nlos_mask), colorNYUthr, '-', 'NYU thr + NYU method');
    hNtUSC = plot_cdf_with_band(d_Nt_USC(nlos_mask), colorNYUthr, '--', 'NYU thr + USC method');
    hUtNYU = plot_cdf_with_band(d_Ut_NYU(nlos_mask), colorUSCthr, '-', 'USC thr + NYU method');
    hUtUSC = plot_cdf_with_band(d_Ut_USC(nlos_mask), colorUSCthr, '--', 'USC thr + USC method');

    title([metricName ' CDF (NLOS)'], 'FontSize', 12, 'FontWeight', 'bold');
    xlabel(xLabel, 'FontSize', 11, 'Interpreter', 'tex');
    ylabel('CDF', 'FontSize', 11);
    legend([hNtNYU, hNtUSC, hUtNYU, hUtUSC], ...
        {'NYU thr + NYU method', 'NYU thr + USC method', ...
         'USC thr + NYU method', 'USC thr + USC method'}, ...
        'Location', 'southeast', 'FontSize', 8);
    set(gca, 'FontSize', 10);

    % Save figure
    baseName = ['CDF_' fileTag];
    savefig(figCDF, fullfile(paths.output, [baseName '.fig']));
    exportgraphics(figCDF, fullfile(paths.output, [baseName '.png']), 'Resolution', 300, 'BackgroundColor', 'white');
    exportgraphics(figCDF, fullfile(paths.output, [baseName '.pdf']), 'ContentType', 'vector', 'BackgroundColor', 'white');
    fprintf('Saved: %s.fig/png/pdf\n', baseName);
end

% =========================================================================
% FIGURE 4: Scatter/Correlation Plots (NYU method vs USC method under each thr)
% =========================================================================
fig4 = figure('Units', 'inches', 'Position', [1 1 IEEE_DOUBLE_COL_WIDTH 5.5], 'Name', 'Fig4: Scatter Correlation');

% PL scatter
subplot(2,2,1);
scatter(results.PL_NYUthr_pDM, results.PL_NYUthr_SUM, 35, colors.NYUthr, 'o', 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 0.5, 'DisplayName', 'NYU thr');
hold on;
scatter(results.PL_USCthr_pDM, results.PL_USCthr_SUM, 35, colors.USCthr, 's', 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 0.5, 'DisplayName', 'USC thr');
lims = [min([results.PL_NYUthr_pDM; results.PL_USCthr_pDM])*0.95, max([results.PL_NYUthr_SUM; results.PL_USCthr_SUM])*1.05];
plot(lims, lims, 'k--', 'LineWidth', 1.0, 'HandleVisibility', 'off');
xlabel('PL pDM (dB)', 'FontSize', 10, 'Interpreter', 'latex');
ylabel('PL SUM (dB)', 'FontSize', 10, 'Interpreter', 'latex');
title('(a) PL: SUM vs pDM', 'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'latex');
legend('Location', 'northwest', 'FontSize', 7, 'Box', 'off', 'Interpreter', 'none');
grid on; set(gca, 'FontSize', 9);

% DS scatter
subplot(2,2,2);
scatter(results.DS_NYUthr_pDM, results.DS_NYUthr_SUM, 35, colors.NYUthr, 'o', 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 0.5, 'DisplayName', 'NYU thr');
hold on;
scatter(results.DS_USCthr_pDM, results.DS_USCthr_SUM, 35, colors.USCthr, 's', 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 0.5, 'DisplayName', 'USC thr');
max_val = max([results.DS_NYUthr_SUM; results.DS_USCthr_SUM]) * 1.1;
plot([0 max_val], [0 max_val], 'k--', 'LineWidth', 1.0, 'HandleVisibility', 'off');
xlabel('DS pDM (ns)', 'FontSize', 10, 'Interpreter', 'latex');
ylabel('DS SUM (ns)', 'FontSize', 10, 'Interpreter', 'latex');
title('(b) DS: SUM vs pDM', 'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'latex');
legend('Location', 'northwest', 'FontSize', 7, 'Box', 'off', 'Interpreter', 'none');
grid on; set(gca, 'FontSize', 9);

% ASA scatter (NYU AS vs USC AS, colored by threshold)
subplot(2,2,3);
scatter(results.ASA_NYUthr_U, results.ASA_NYUthr_N10, 35, colors.NYUthr, 'o', 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 0.5, 'DisplayName', 'NYU thr');
hold on;
scatter(results.ASA_USCthr_U, results.ASA_USCthr_N10, 35, colors.USCthr, 's', 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 0.5, 'DisplayName', 'USC thr');
max_val = max([results.ASA_NYUthr_U; results.ASA_USCthr_U; results.ASA_NYUthr_N10; results.ASA_USCthr_N10]) * 1.1;
plot([0 max_val], [0 max_val], 'k--', 'LineWidth', 1.0, 'HandleVisibility', 'off');
xlabel('ASA USC-method ($^\circ$)', 'FontSize', 10, 'Interpreter', 'latex');
ylabel('ASA NYU-10dB ($^\circ$)', 'FontSize', 10, 'Interpreter', 'latex');
title('(c) ASA: NYU vs USC AS', 'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'latex');
legend('Location', 'northwest', 'FontSize', 7, 'Box', 'off', 'Interpreter', 'none');
grid on; set(gca, 'FontSize', 9);

% ASD scatter
subplot(2,2,4);
scatter(results.ASD_NYUthr_U, results.ASD_NYUthr_N10, 35, colors.NYUthr, 'o', 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 0.5, 'DisplayName', 'NYU thr');
hold on;
scatter(results.ASD_USCthr_U, results.ASD_USCthr_N10, 35, colors.USCthr, 's', 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 0.5, 'DisplayName', 'USC thr');
max_val = max([results.ASD_NYUthr_U; results.ASD_USCthr_U; results.ASD_NYUthr_N10; results.ASD_USCthr_N10]) * 1.1;
plot([0 max_val], [0 max_val], 'k--', 'LineWidth', 1.0, 'HandleVisibility', 'off');
xlabel('ASD USC-method ($^\circ$)', 'FontSize', 10, 'Interpreter', 'latex');
ylabel('ASD NYU-10dB ($^\circ$)', 'FontSize', 10, 'Interpreter', 'latex');
title('(d) ASD: NYU vs USC AS', 'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'latex');
legend('Location', 'northwest', 'FontSize', 7, 'Box', 'off', 'Interpreter', 'none');
grid on; set(gca, 'FontSize', 9);

savefig(fig4, fullfile(paths.output, 'Fig4_Scatter_Correlation.fig'));
exportgraphics(fig4, fullfile(paths.output, 'Fig4_Scatter_Correlation.png'), 'Resolution', 300, 'BackgroundColor', 'white');
exportgraphics(fig4, fullfile(paths.output, 'Fig4_Scatter_Correlation.pdf'), 'ContentType', 'vector', 'BackgroundColor', 'white');

% =========================================================================
% FIGURES 5a-5d: Bland-Altman Plots (Combined: NYU thr vs USC thr overlay)
% =========================================================================
% Each metric gets its own figure with combined overlay of both thresholds
% Format matches Plot_BlandAltman_PL_DS_AS.m reference
% Difference = NYU method - USC method

fprintf('\n===================================================================\n');
fprintf('  BLAND-ALTMAN SUMMARY (NYU method - USC method)\n');
fprintf('===================================================================\n');

% Define Bland-Altman metric configurations:
% {metricName, NYUthr_NYUmethod, NYUthr_USCmethod, USCthr_NYUmethod, USCthr_USCmethod, unitLabel, fileTag}
ba_metrics = {
    'Omni PL', results.PL_NYUthr_SUM, results.PL_NYUthr_pDM, ...
               results.PL_USCthr_SUM, results.PL_USCthr_pDM, 'dB', 'PL';
    'Omni DS', results.DS_NYUthr_SUM, results.DS_NYUthr_pDM, ...
               results.DS_USCthr_SUM, results.DS_USCthr_pDM, 'ns', 'DS';
    'ASA',     results.ASA_NYUthr_N10, results.ASA_NYUthr_U, ...
               results.ASA_USCthr_N10, results.ASA_USCthr_U, 'deg', 'ASA';
    'ASD',     results.ASD_NYUthr_N10, results.ASD_NYUthr_U, ...
               results.ASD_USCthr_N10, results.ASD_USCthr_U, 'deg', 'ASD';
};

for bm = 1:size(ba_metrics, 1)
    metricName = ba_metrics{bm, 1};
    a1 = ba_metrics{bm, 2};  % NYU thr: NYU method values
    b1 = ba_metrics{bm, 3};  % NYU thr: USC method values
    a2 = ba_metrics{bm, 4};  % USC thr: NYU method values
    b2 = ba_metrics{bm, 5};  % USC thr: USC method values
    unitLabel = ba_metrics{bm, 6};
    fileTag   = ba_metrics{bm, 7};

    titleStr = sprintf('Bland-Altman: %s [%s] (NYU thr vs USC thr)', metricName, unitLabel);
    figBA = plot_bland_altman_combined(a1, b1, a2, b2, ...
        titleStr, 'NYU threshold', 'USC threshold', unitLabel);

    % Save figure
    baseName = ['BlandAltman_' fileTag];
    savefig(figBA, fullfile(paths.output, [baseName '.fig']));
    exportgraphics(figBA, fullfile(paths.output, [baseName '.png']), 'Resolution', 300, 'BackgroundColor', 'white');
    exportgraphics(figBA, fullfile(paths.output, [baseName '.pdf']), 'ContentType', 'vector', 'BackgroundColor', 'white');
    fprintf('Saved: %s.fig/png/pdf\n', baseName);
end

% =========================================================================
% FIGURE 6: Threshold Comparison Scatter (NYU thr results vs USC thr results)
% =========================================================================
fig6 = figure('Units', 'inches', 'Position', [1 1 IEEE_DOUBLE_COL_WIDTH 5.5], 'Name', 'Fig6: Threshold Scatter');

subplot(2,2,1);
scatter(results.PL_USCthr_SUM, results.PL_NYUthr_SUM, 40, colors.NYU_10dB, 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 0.5);
hold on;
lims = [min([results.PL_USCthr_SUM; results.PL_NYUthr_SUM])*0.95, max([results.PL_USCthr_SUM; results.PL_NYUthr_SUM])*1.05];
plot(lims, lims, 'k--', 'LineWidth', 1.0);
xlabel('PL (USC thr, SUM) [dB]', 'FontSize', 10, 'Interpreter', 'latex');
ylabel('PL (NYU thr, SUM) [dB]', 'FontSize', 10, 'Interpreter', 'latex');
r = corrcoef(results.PL_USCthr_SUM, results.PL_NYUthr_SUM);
title(sprintf('(a) PL SUM: $R$=%.3f', r(1,2)), 'FontSize', 10, 'Interpreter', 'latex');
grid on; axis equal; set(gca, 'FontSize', 9);

subplot(2,2,2);
scatter(results.DS_USCthr_SUM, results.DS_NYUthr_SUM, 40, colors.NYU_10dB, 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 0.5);
hold on;
max_val = max([results.DS_USCthr_SUM; results.DS_NYUthr_SUM]) * 1.1;
plot([0 max_val], [0 max_val], 'k--', 'LineWidth', 1.0);
xlabel('DS (USC thr, SUM) [ns]', 'FontSize', 10, 'Interpreter', 'latex');
ylabel('DS (NYU thr, SUM) [ns]', 'FontSize', 10, 'Interpreter', 'latex');
r = corrcoef(results.DS_USCthr_SUM, results.DS_NYUthr_SUM);
title(sprintf('(b) DS SUM: $R$=%.3f', r(1,2)), 'FontSize', 10, 'Interpreter', 'latex');
grid on; axis equal; set(gca, 'FontSize', 9);

subplot(2,2,3);
scatter(results.ASA_USCthr_N10, results.ASA_NYUthr_N10, 40, colors.NYU_10dB, 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 0.5);
hold on;
max_val = max([results.ASA_USCthr_N10; results.ASA_NYUthr_N10]) * 1.1;
plot([0 max_val], [0 max_val], 'k--', 'LineWidth', 1.0);
xlabel('ASA-N10 (USC thr) [$^\circ$]', 'FontSize', 10, 'Interpreter', 'latex');
ylabel('ASA-N10 (NYU thr) [$^\circ$]', 'FontSize', 10, 'Interpreter', 'latex');
r = corrcoef(results.ASA_USCthr_N10, results.ASA_NYUthr_N10);
title(sprintf('(c) ASA N10: $R$=%.3f', r(1,2)), 'FontSize', 10, 'Interpreter', 'latex');
grid on; axis equal; set(gca, 'FontSize', 9);

subplot(2,2,4);
scatter(results.ASD_USCthr_N10, results.ASD_NYUthr_N10, 40, colors.NYU_10dB, 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 0.5);
hold on;
max_val = max([results.ASD_USCthr_N10; results.ASD_NYUthr_N10]) * 1.1;
plot([0 max_val], [0 max_val], 'k--', 'LineWidth', 1.0);
xlabel('ASD-N10 (USC thr) [$^\circ$]', 'FontSize', 10, 'Interpreter', 'latex');
ylabel('ASD-N10 (NYU thr) [$^\circ$]', 'FontSize', 10, 'Interpreter', 'latex');
r = corrcoef(results.ASD_USCthr_N10, results.ASD_NYUthr_N10);
title(sprintf('(d) ASD N10: $R$=%.3f', r(1,2)), 'FontSize', 10, 'Interpreter', 'latex');
grid on; axis equal; set(gca, 'FontSize', 9);

savefig(fig6, fullfile(paths.output, 'Fig6_Threshold_Scatter.fig'));
exportgraphics(fig6, fullfile(paths.output, 'Fig6_Threshold_Scatter.png'), 'Resolution', 300, 'BackgroundColor', 'white');
exportgraphics(fig6, fullfile(paths.output, 'Fig6_Threshold_Scatter.pdf'), 'ContentType', 'vector', 'BackgroundColor', 'white');

%% SECTION 6: SAVE RESULTS
save(fullfile(paths.results, 'all_comparison_results.mat'), 'results', 'pas_store', 'config', 'params');

% =========================================================================
% Build Excel Output Table — Two Major Column Groups
% =========================================================================
T_all = table( ...
    results.TX_RX_ID, results.Environment, results.Distance_m, results.TX_Power_dBm, ...
    ... % --- NYU Threshold Group ---
    results.PL_NYUthr_SUM, results.PL_NYUthr_pDM, ...
    results.DS_NYUthr_SUM, results.DS_NYUthr_pDM, ...
    results.ASA_NYUthr_N10, results.ASA_NYUthr_N15, results.ASA_NYUthr_N20, results.ASA_NYUthr_U, ...
    results.ASD_NYUthr_N10, results.ASD_NYUthr_N15, results.ASD_NYUthr_N20, results.ASD_NYUthr_U, ...
    ... % --- USC Threshold Group ---
    results.PL_USCthr_SUM, results.PL_USCthr_pDM, ...
    results.DS_USCthr_SUM, results.DS_USCthr_pDM, ...
    results.ASA_USCthr_N10, results.ASA_USCthr_N15, results.ASA_USCthr_N20, results.ASA_USCthr_U, ...
    results.ASD_USCthr_N10, results.ASD_USCthr_N15, results.ASD_USCthr_N20, results.ASD_USCthr_U, ...
    'VariableNames', { ...
        'TX_RX_ID', 'Environment', 'Distance_m', 'TX_Power_dBm', ...
        'NYUthr_PL_SUM_dB', 'NYUthr_PL_pDM_dB', ...
        'NYUthr_DS_SUM_ns', 'NYUthr_DS_pDM_ns', ...
        'NYUthr_ASA_N10', 'NYUthr_ASA_N15', 'NYUthr_ASA_N20', 'NYUthr_ASA_U', ...
        'NYUthr_ASD_N10', 'NYUthr_ASD_N15', 'NYUthr_ASD_N20', 'NYUthr_ASD_U', ...
        'USCthr_PL_SUM_dB', 'USCthr_PL_pDM_dB', ...
        'USCthr_DS_SUM_ns', 'USCthr_DS_pDM_ns', ...
        'USCthr_ASA_N10', 'USCthr_ASA_N15', 'USCthr_ASA_N20', 'USCthr_ASA_U', ...
        'USCthr_ASD_N10', 'USCthr_ASD_N15', 'USCthr_ASD_N20', 'USCthr_ASD_U'});

% Export CSV
csv_filepath = fullfile(paths.results, 'NYU7GHz_Method_Comparison_Results.csv');
writetable(T_all, csv_filepath);
fprintf('\n  CSV results exported to: %s\n', csv_filepath);

% Export Excel with Multiple Sheets
xlsx_filepath = fullfile(paths.results, 'NYU7GHz_Method_Comparison_Results.xlsx');
if exist(xlsx_filepath, 'file'), delete(xlsx_filepath); end
writetable(T_all, xlsx_filepath, 'Sheet', 'All_Results');

% LOS/NLOS Summary Statistics
metrics_list = {'PL_NYUthr_SUM', 'PL_NYUthr_pDM', 'PL_USCthr_SUM', 'PL_USCthr_pDM', ...
    'DS_NYUthr_SUM', 'DS_NYUthr_pDM', 'DS_USCthr_SUM', 'DS_USCthr_pDM', ...
    'ASA_NYUthr_N10', 'ASA_NYUthr_U', 'ASA_USCthr_N10', 'ASA_USCthr_U', ...
    'ASD_NYUthr_N10', 'ASD_NYUthr_U', 'ASD_USCthr_N10', 'ASD_USCthr_U'};
stats_names = {'Mean', 'Std', 'Min', 'Max'};

T_los = table();
T_nlos = table();
T_overall = table();
for i = 1:length(metrics_list)
    data_all = results.(metrics_list{i});
    data_los = data_all(los_mask);
    data_nlos = data_all(nlos_mask);
    T_los.(metrics_list{i}) = [mean(data_los); std(data_los); min(data_los); max(data_los)];
    T_nlos.(metrics_list{i}) = [mean(data_nlos); std(data_nlos); min(data_nlos); max(data_nlos)];
    T_overall.(metrics_list{i}) = [mean(data_all); std(data_all); min(data_all); max(data_all)];
end
T_los.Properties.RowNames = stats_names;
T_nlos.Properties.RowNames = stats_names;
T_overall.Properties.RowNames = stats_names;

writetable(T_los, xlsx_filepath, 'Sheet', 'LOS_Summary', 'WriteRowNames', true);
writetable(T_nlos, xlsx_filepath, 'Sheet', 'NLOS_Summary', 'WriteRowNames', true);
writetable(T_overall, xlsx_filepath, 'Sheet', 'Overall_Summary', 'WriteRowNames', true);
fprintf('  Excel results exported to: %s\n', xlsx_filepath);

fprintf('\n═══════════════════════════════════════════════════════════════════════\n');
fprintf('  PROCESSING COMPLETE\n');
fprintf('═══════════════════════════════════════════════════════════════════════\n');
fprintf('  Figures saved to: %s\n', paths.output);
fprintf('  Results saved to: %s\n', paths.results);
fprintf('  CSV exported to: %s\n', csv_filepath);
fprintf('  Excel exported to: %s\n', xlsx_filepath);
fprintf('═══════════════════════════════════════════════════════════════════════\n');

%% =========================================================================
%  LOCAL HELPER FUNCTIONS
%  =========================================================================

function print_stat_row(label, data, los_mask, nlos_mask)
    % Print a formatted statistics row for TABLE 3/4
    los_data = data(los_mask);
    nlos_data = data(nlos_mask);
    fprintf('║ %-36s │ %6.2f ± %5.2f               │ %6.2f ± %5.2f              │ %6.2f ± %5.2f ║\n', ...
        label, mean(los_data), std(los_data), mean(nlos_data), std(nlos_data), mean(data), std(data));
end

function h = plot_cdf_with_band(vals, color, lineStyle, displayName)
    % Plot empirical CDF with DKW 95% confidence band
    % Returns handle to the main CDF line for legend use
    %
    % Uses ecdf() for the CDF and Dvoretzky-Kiefer-Wolfowitz inequality
    % for the 95% confidence band (shaded area).

    vals = vals(:);
    vals = vals(isfinite(vals) & vals > 0);  % Remove NaN, Inf, and zero values

    if isempty(vals)
        h = plot(NaN, NaN, lineStyle, 'Color', color, 'LineWidth', 1.8, 'DisplayName', displayName);
        return;
    end

    % Compute empirical CDF
    [f, x] = ecdf(vals);

    % Plot main CDF line
    h = plot(x, f, lineStyle, 'Color', color, 'LineWidth', 1.8, 'DisplayName', displayName);

    % DKW (Dvoretzky-Kiefer-Wolfowitz) confidence band for 95% confidence
    n = numel(vals);
    epsilon = sqrt(log(2 / 0.05) / (2 * n));  % alpha = 0.05
    f_lo = max(0, f - epsilon);
    f_hi = min(1, f + epsilon);

    % Plot confidence band as shaded area
    fill([x; flipud(x)], [f_lo; flipud(f_hi)], color, ...
        'FaceAlpha', 0.15, 'EdgeColor', 'none', 'HandleVisibility', 'off');
end

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

function fig = plot_bland_altman_combined(a1, b1, a2, b2, titleStr, name1, name2, unitLabel)
    % Combined Bland-Altman: two datasets on one figure with shared y-axis
    % a1, b1: NYU-method and USC-method values for dataset 1 (e.g. NYU threshold)
    % a2, b2: NYU-method and USC-method values for dataset 2 (e.g. USC threshold)
    % Difference = a - b (NYU method - USC method)

    % Remove NaN rows
    v1 = isfinite(a1) & isfinite(b1);
    a1 = a1(v1); b1 = b1(v1);
    v2 = isfinite(a2) & isfinite(b2);
    a2 = a2(v2); b2 = b2(v2);

    mean1 = (a1 + b1) / 2;   diff1 = a1 - b1;
    mean2 = (a2 + b2) / 2;   diff2 = a2 - b2;

    bias1 = mean(diff1);  sd1 = std(diff1);
    loa1u = bias1 + 1.96*sd1;  loa1l = bias1 - 1.96*sd1;

    bias2 = mean(diff2);  sd2 = std(diff2);
    loa2u = bias2 + 1.96*sd2;  loa2l = bias2 - 1.96*sd2;

    unitTex   = to_tex_unit(unitLabel);
    unitPlain = to_plain_unit(unitLabel);

    fig = figure('Name', titleStr, 'Position', [250, 250, 1000, 550]);

    % --- Dataset 1 (blue circles) ---
    s1 = scatter(mean1, diff1, 60, 'o', ...
        'MarkerEdgeColor', [0 0.45 0.74], ...
        'MarkerFaceColor', [0.60 0.78 0.92], ...
        'LineWidth', 1); hold on;
    yline(bias1, '-', 'Color', [0 0.45 0.74], 'LineWidth', 1.5, ...
        'Label', sprintf('Bias (%s) = %+.2f %s', name1, bias1, unitPlain), ...
        'LabelHorizontalAlignment', 'left', 'FontSize', 9);
    yline(loa1u, '--', 'Color', [0 0.45 0.74], 'LineWidth', 1.0, ...
        'Label', sprintf('+1.96 SD = %+.2f', loa1u), ...
        'LabelHorizontalAlignment', 'left', 'FontSize', 8);
    yline(loa1l, '--', 'Color', [0 0.45 0.74], 'LineWidth', 1.0, ...
        'Label', sprintf('-1.96 SD = %+.2f', loa1l), ...
        'LabelHorizontalAlignment', 'left', 'FontSize', 8);

    % --- Dataset 2 (orange squares) ---
    s2 = scatter(mean2, diff2, 60, 's', ...
        'MarkerEdgeColor', [0.85 0.33 0.10], ...
        'MarkerFaceColor', [0.98 0.78 0.68], ...
        'LineWidth', 1);
    yline(bias2, '-', 'Color', [0.85 0.33 0.10], 'LineWidth', 1.5, ...
        'Label', sprintf('Bias (%s) = %+.2f %s', name2, bias2, unitPlain), ...
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
    fprintf('    %s: Bias=%+.2f %s, SD=%.2f %s (n=%d)\n', name1, bias1, unitPlain, sd1, unitPlain, length(diff1));
    fprintf('    %s: Bias=%+.2f %s, SD=%.2f %s (n=%d)\n', name2, bias2, unitPlain, sd2, unitPlain, length(diff2));
end

function dilation_factor = detect_dilation_factor(data_path)
    % Auto-detect dilation factor (samples per ns) from 7 GHz PDP data.
    % Loads first available PDP and estimates sampling rate.
    %
    % Strategy: Load first PDP, print its length, and compute expected
    %   max excess delay for candidate dilation factors.
    %   For 500 MHz PN chip rate: multipath time resolution = 2 ns
    %   Expected max PDP length ~ few thousand samples

    files = dir(fullfile(data_path, 'Data7Pack_TX*_RX*_Aligned.mat'));
    if isempty(files)
        warning('No data files found in %s. Using default dilation_factor=20.', data_path);
        dilation_factor = 20;
        return;
    end

    % Load first file
    data = load(fullfile(data_path, files(1).name));
    fnames = fieldnames(data);
    TRpdpSet = data.(fnames{1});

    % Find first non-empty PDP
    pdp_len = 0;
    for i = 1:size(TRpdpSet, 1)
        pdp = TRpdpSet{i, 1};
        if ~isempty(pdp) && isnumeric(pdp)
            pdp_len = length(pdp);
            break;
        end
    end

    if pdp_len == 0
        warning('No valid PDP found. Using default dilation_factor=20.');
        dilation_factor = 20;
        return;
    end

    fprintf('\n  ===== Dilation Factor Detection =====\n');
    fprintf('  PDP length: %d samples (from %s)\n', pdp_len, files(1).name);
    fprintf('  Candidate dilation factors and resulting max delay:\n');

    candidates = [5, 10, 20, 40];
    for c = candidates
        span_ns = pdp_len / c;
        fprintf('    %d samples/ns → %.1f ns (%.2f us) max excess delay\n', c, span_ns, span_ns/1000);
    end

    % Heuristic: For 7 GHz outdoor, we expect max excess delay ~ 500-2000 ns.
    % PN chip rate = 500 MHz → time resolution = 2 ns
    % If PDP was sampled at chip rate: dilation_factor = 1 sample per 2 ns = 0.5/ns
    % But NYU typically dilates PDPs. Common factors: 1, 2, 5, 10, 20
    %
    % Use the candidate that gives a reasonable span (500-3000 ns)
    best_factor = 20;  % default
    for c = candidates
        span_ns = pdp_len / c;
        if span_ns >= 200 && span_ns <= 5000
            best_factor = c;
            break;  % Take smallest reasonable factor
        end
    end

    fprintf('  → Auto-selected dilation factor: %d samples/ns (span=%.1f ns)\n', best_factor, pdp_len/best_factor);
    fprintf('  ====================================\n\n');

    dilation_factor = best_factor;
end

function pattern = load_antenna_pattern_mat(filepath)
    % Load antenna pattern from .mat file (7 GHz format)
    %
    % The 7 GHz .mat files contain TWO separate vectors:
    %   new_x: 1×181 vector of angles (-90 to +90 degrees)
    %   new_y: 1×181 vector of gain values (dB)
    %
    % Output:
    %   pattern - Nx2 matrix [angle_deg, gain_dB], sorted by angle

    try
        data = load(filepath);
        fnames = fieldnames(data);

        pattern = [];

        % Strategy 1: Look for 'new_x' and 'new_y' vectors (7 GHz format)
        if isfield(data, 'new_x') && isfield(data, 'new_y')
            angles = data.new_x(:);  % Force column vector
            gains = data.new_y(:);
            if length(angles) == length(gains) && length(angles) > 1
                pattern = [angles, gains];
                fprintf('  Loaded antenna pattern from %s (new_x/new_y, %d points)\n', ...
                    filepath, size(pattern, 1));
                fprintf('    Angle range: [%.1f, %.1f] deg, Peak gain: %.1f dB\n', ...
                    min(pattern(:,1)), max(pattern(:,1)), max(pattern(:,2)));
            end
        end

        % Strategy 2: Look for an Nx2 matrix (generic format)
        if isempty(pattern)
            for i = 1:length(fnames)
                var = data.(fnames{i});
                if isnumeric(var) && ismatrix(var) && min(size(var)) >= 2
                    % If it's wider than tall, transpose it
                    if size(var, 1) < size(var, 2) && size(var, 1) <= 2
                        var = var';
                    end
                    if size(var, 2) >= 2 && size(var, 1) > 2
                        pattern = var(:, 1:2);
                        fprintf('  Loaded antenna pattern from %s (var: %s, %d points)\n', ...
                            filepath, fnames{i}, size(pattern, 1));
                        fprintf('    Angle range: [%.1f, %.1f] deg, Peak gain: %.1f dB\n', ...
                            min(pattern(:,1)), max(pattern(:,1)), max(pattern(:,2)));
                        break;
                    end
                end
            end
        end

        % Strategy 3: Look for any two vectors of same length
        if isempty(pattern)
            vectors = {};
            vec_names = {};
            for i = 1:length(fnames)
                var = data.(fnames{i});
                if isnumeric(var) && isvector(var) && length(var) > 2
                    vectors{end+1} = var(:); %#ok<AGROW>
                    vec_names{end+1} = fnames{i}; %#ok<AGROW>
                end
            end
            if length(vectors) >= 2 && length(vectors{1}) == length(vectors{2})
                pattern = [vectors{1}, vectors{2}];
                fprintf('  Loaded antenna pattern from %s (%s/%s, %d points)\n', ...
                    filepath, vec_names{1}, vec_names{2}, size(pattern, 1));
                fprintf('    Angle range: [%.1f, %.1f] deg, Peak gain: %.1f dB\n', ...
                    min(pattern(:,1)), max(pattern(:,1)), max(pattern(:,2)));
            end
        end

        if isempty(pattern)
            fprintf('  WARNING: Could not parse antenna pattern from %s\n', filepath);
            fprintf('  Available variables:\n');
            for i = 1:length(fnames)
                var = data.(fnames{i});
                fprintf('    %s: size=%s, class=%s\n', fnames{i}, mat2str(size(var)), class(var));
            end
            fprintf('  Falling back to flat antenna pattern.\n');
            pattern = [(-90:90)', zeros(181, 1)];
            return;
        end

        % Sort by angle
        pattern = sortrows(pattern, 1);

    catch ME
        warning('Could not load antenna pattern from %s: %s', filepath, ME.message);
        pattern = [(-90:90)', zeros(181, 1)];
    end
end

function [TRpdpSet_thr, noise_floor_dB] = apply_NYU_PDP_threshold(TRpdpSet, config, params)
    % Apply NYU's PDP threshold: max(25dB below peak, 5dB above noise)
    %
    % PER-DIRECTIONAL-PDP THRESHOLDING (NYU's original method):
    %   Each directional PDP is thresholded using:
    %     threshold_i = max(peak_i - 25 dB, noise_i + 5 dB)
    %   where peak_i and noise_i are computed for each directional PDP.
    %
    % NOISE FLOOR ESTIMATION (NYU's original method):
    %   Average power of last ~250 ns of PDP tail in LINEAR domain, then dB.
    %   noise_tail_samples = 250 ns * params.dilation_factor
    %
    % Input:
    %   TRpdpSet - Cell array with PDP in column 1 (ALREADY IN dB)
    %   config - Configuration struct
    %   params - Parameters struct with .dilation_factor
    %
    % Output:
    %   TRpdpSet_thr - Thresholded cell array
    %   noise_floor_dB - Median noise floor estimate

    nPDPs = size(TRpdpSet, 1);
    TRpdpSet_thr = TRpdpSet;

    noise_tail_ns = 250;
    noise_tail_samples = noise_tail_ns * params.dilation_factor;

    noise_floors = zeros(nPDPs, 1);

    for i = 1:nPDPs
        pdp_dB = TRpdpSet{i, 1};
        if ~isempty(pdp_dB) && isnumeric(pdp_dB)
            pdp_dB = real(pdp_dB(:));
            pdp_len = length(pdp_dB);

            % Noise floor from last 250 ns (linear domain)
            if pdp_len > noise_tail_samples
                tail_samples_dB = pdp_dB(end-noise_tail_samples+1:end);
            else
                tail_start = max(1, floor(0.9 * pdp_len));
                tail_samples_dB = pdp_dB(tail_start:end);
            end

            tail_samples_lin = 10.^(tail_samples_dB / 10);
            local_noise = 10 * log10(mean(tail_samples_lin));
            noise_floors(i) = local_noise;

            % Peak and threshold
            local_peak_dB = max(pdp_dB);
            thres_below_peak = local_peak_dB - config.thres_below_pk;
            thres_above_noise = local_noise + config.thres_above_noise;
            threshold_dB = max(thres_below_peak, thres_above_noise);

            % Apply threshold
            pdp_dB(pdp_dB < threshold_dB) = config.multipath_low_bound;
            TRpdpSet_thr{i, 1} = pdp_dB;
        end
    end

    valid_noise = noise_floors(noise_floors ~= 0 & ~isnan(noise_floors));
    if ~isempty(valid_noise)
        noise_floor_dB = median(valid_noise);
    else
        noise_floor_dB = -200;
    end
end

function [TRpdpSet_thr, global_threshold_dB] = apply_USC_PDP_threshold(TRpdpSet, config)
    % Apply USC's global PDP threshold
    %
    % USC Method (from noise_floor_calc_v2.m):
    %   For each directional PDP (in dB):
    %     1. Remove -Inf values, sort ascending
    %     2. noise_floor_i = value_at_25th_percentile + 5.41 dB
    %   Global threshold = max(all noise_floor_i) + 12 dB
    %   Apply: PDP samples below global_threshold → multipath_low_bound (-200 dB)
    %
    % Input:
    %   TRpdpSet - Cell array with PDP in column 1 (ALREADY IN dB)
    %   config - Configuration struct with:
    %            .usc_percentile (25), .usc_offset_dB (5.41),
    %            .usc_margin_dB (12), .multipath_low_bound (-200)
    %
    % Output:
    %   TRpdpSet_thr - Thresholded cell array
    %   global_threshold_dB - The computed global threshold

    nPDPs = size(TRpdpSet, 1);
    TRpdpSet_thr = TRpdpSet;

    % Step 1: Compute noise floor for each directional PDP
    noise_floors = -Inf * ones(nPDPs, 1);

    for i = 1:nPDPs
        pdp_dB = TRpdpSet{i, 1};
        if ~isempty(pdp_dB) && isnumeric(pdp_dB)
            pdp_dB = real(pdp_dB(:));

            % Remove -Inf and very low values
            valid = pdp_dB(isfinite(pdp_dB) & pdp_dB > -190);
            if isempty(valid)
                continue;
            end

            % Sort ascending
            sorted_vals = sort(valid, 'ascend');

            % 25th percentile
            idx_25 = max(1, round(config.usc_percentile / 100 * length(sorted_vals)));
            p25_val = sorted_vals(idx_25);

            % Noise floor for this direction
            noise_floors(i) = p25_val + config.usc_offset_dB;
        end
    end

    % Step 2: Global threshold = max of all noise floors + 12 dB
    valid_nf = noise_floors(isfinite(noise_floors));
    if ~isempty(valid_nf)
        global_threshold_dB = max(valid_nf) + config.usc_margin_dB;
    else
        global_threshold_dB = -200;
        warning('USC threshold: no valid noise floors computed.');
    end

    % Step 3: Apply global threshold to all PDPs
    for i = 1:nPDPs
        pdp_dB = TRpdpSet{i, 1};
        if ~isempty(pdp_dB) && isnumeric(pdp_dB)
            pdp_dB = real(pdp_dB(:));
            pdp_dB(pdp_dB < global_threshold_dB) = config.multipath_low_bound;
            TRpdpSet_thr{i, 1} = pdp_dB;
        end
    end
end

function [PAS_angles, PAS_powers, PAS_set] = generate_PAS(TRpdpSet, ref_col, alt_col, pdp_floor_dB, pas_init_dB)
    % Generate Power Angular Spectrum (PAS) — FULL 360° spectrum
    % Based on NYU's PASgenerator.m
    %
    % Input:
    %   TRpdpSet - Cell array with thresholded PDP (in dB) in column 1
    %   ref_col - Column index for reference angle (8=AOA, 6=AOD)
    %   alt_col - Column index for alternative angle (6=AOD, 8=AOA)
    %   pdp_floor_dB - PDP threshold floor (e.g., -200 dB)
    %   pas_init_dB - (Optional) Initialization value for unmeasured angles

    if nargin < 5 || isempty(pas_init_dB)
        pas_init_dB = pdp_floor_dB;
    end

    nPDPs = size(TRpdpSet, 1);
    all_angles = [];
    all_powers_dB = [];

    for i = 1:nPDPs
        pdp_dB = TRpdpSet{i, 1};
        if isempty(pdp_dB) || ~isnumeric(pdp_dB)
            continue;
        end

        angle = TRpdpSet{i, ref_col};
        if isempty(angle) || ~isnumeric(angle)
            continue;
        end

        pdp_dB = real(pdp_dB);
        valid_mask = pdp_dB > pdp_floor_dB;
        if any(valid_mask)
            power_lin = sum(10.^(pdp_dB(valid_mask) / 10));
            power_dB = 10*log10(power_lin + eps);
            all_angles = [all_angles; angle]; %#ok<AGROW>
            all_powers_dB = [all_powers_dB; power_dB]; %#ok<AGROW>
        end
    end

    % Aggregate by unique angles
    if ~isempty(all_angles)
        unique_angles = unique(all_angles);
        unique_powers_dB = zeros(size(unique_angles));
        for i = 1:length(unique_angles)
            mask = all_angles == unique_angles(i);
            power_lin = sum(10.^(all_powers_dB(mask) / 10));
            unique_powers_dB(i) = 10*log10(power_lin + eps);
        end
    else
        unique_angles = [];
        unique_powers_dB = [];
    end

    % Create FULL 360° spectrum
    PAS_angles = (1:360)';
    PAS_powers = ones(360, 1) * pas_init_dB;

    unique_angles(unique_angles == 0) = 360;

    for i = 1:length(unique_angles)
        ang_idx = round(unique_angles(i));
        if ang_idx >= 1 && ang_idx <= 360
            PAS_powers(ang_idx) = max(PAS_powers(ang_idx), unique_powers_dB(i));
        end
    end

    % PAS_set for compatibility
    if ~isempty(unique_angles)
        PAS_set = cell(length(unique_angles), 3);
        for i = 1:length(unique_angles)
            PAS_set{i, 1} = unique_powers_dB(i);
            PAS_set{i, 2} = 10^(unique_powers_dB(i)/10);
            PAS_set{i, 3} = unique_angles(i);
        end
    else
        PAS_set = {};
    end
end

function [OmniPDP, delays_ns] = compute_omni_NYU(TRpdpSet, params)
    % Compute Omni PDP using NYU's SUM method
    % Sum power across all directions at each delay bin
    % Input PDP is ALREADY IN dB

    nPDPs = size(TRpdpSet, 1);
    pdp_len = 0;
    for i = 1:nPDPs
        pdp = TRpdpSet{i, 1};
        if ~isempty(pdp) && isnumeric(pdp)
            pdp_len = length(pdp);
            break;
        end
    end

    if pdp_len == 0
        OmniPDP = [];
        delays_ns = [];
        return;
    end

    OmniPDP_lin = zeros(pdp_len, 1);
    floor_threshold = -199;

    for i = 1:nPDPs
        pdp_dB = TRpdpSet{i, 1};
        if ~isempty(pdp_dB) && isnumeric(pdp_dB) && length(pdp_dB) == pdp_len
            pdp_dB = real(pdp_dB);
            pdp_lin = 10.^(pdp_dB / 10);
            pdp_lin(pdp_dB <= floor_threshold) = 0;
            OmniPDP_lin = OmniPDP_lin + pdp_lin;
        end
    end

    OmniPDP = OmniPDP_lin;
    delays_ns = (0:pdp_len-1)' / params.dilation_factor;
end

function [OmniPDP, delays_ns] = compute_omni_USC(TRpdpSet, params)
    % Compute Omni PDP using USC's perDelayMax method
    % Take maximum power across all directions at each delay bin

    nPDPs = size(TRpdpSet, 1);
    pdp_len = 0;
    for i = 1:nPDPs
        pdp = TRpdpSet{i, 1};
        if ~isempty(pdp) && isnumeric(pdp)
            pdp_len = length(pdp);
            break;
        end
    end

    if pdp_len == 0
        OmniPDP = [];
        delays_ns = [];
        return;
    end

    OmniPDP_lin = zeros(pdp_len, 1);
    floor_threshold = -199;

    for i = 1:nPDPs
        pdp_dB = TRpdpSet{i, 1};
        if ~isempty(pdp_dB) && isnumeric(pdp_dB) && length(pdp_dB) == pdp_len
            pdp_dB = real(pdp_dB);
            pdp_lin = 10.^(pdp_dB / 10);
            pdp_lin(pdp_dB <= floor_threshold) = 0;
            OmniPDP_lin = max(OmniPDP_lin, pdp_lin);
        end
    end

    OmniPDP = OmniPDP_lin;
    delays_ns = (0:pdp_len-1)' / params.dilation_factor;
end

function rmsDS = compute_RMS_DS(delays_ns, PDP_lin, tgate_ns)
    % Compute RMS Delay Spread (with optional delay gating)
    %
    % Optional arg `tgate_ns`: if provided, samples with delays_ns > tgate_ns
    % are excluded from the DS computation. Mirrors the USC-side
    % USCprocessUSCdata/rms_delay_spread_calc.m behavior, which the paper
    % text describes as "tau_gate = 966.67 ns" for 145.5 GHz. When tgate_ns
    % is Inf or omitted the call is backwards-compatible.

    if nargin < 3 || isempty(tgate_ns), tgate_ns = Inf; end

    if isempty(PDP_lin) || sum(PDP_lin) <= 0
        rmsDS = 0;
        return;
    end

    % Apply optional delay gate (parity with USC pipelines).
    gate_mask = (delays_ns(:) <= tgate_ns);
    PDP_lin   = PDP_lin(:) .* gate_mask;
    delays_ns = delays_ns(:);

    if sum(PDP_lin) <= 0
        rmsDS = 0;
        return;
    end

    weights = PDP_lin / sum(PDP_lin);
    mean_delay = sum(delays_ns .* weights);
    second_moment = sum((delays_ns.^2) .* weights);
    variance = second_moment - mean_delay^2;
    if variance < 0
        variance = 0;
    end
    rmsDS = sqrt(variance);
end

function [AS, selected_angles, expanded_powers] = compute_AS_NYU(angles, powers_dB, pas_threshold_dB, multipath_low_bound, antenna_pattern, HPBW)
    % NYU Angular Spread Method with Lobe Detection and Boundary Expansion
    %
    % Key steps:
    %   1. Apply PAS threshold (10/15/20 dB below peak)
    %   2. Detect contiguous lobes (gap > HPBW = new lobe)
    %   3. For each lobe boundary, expand using antenna pattern
    %   4. Compute AS using 3GPP formula on original + boundary MPCs
    %
    % Input:
    %   angles - Vector of angles (1:360)
    %   powers_dB - Power at each angle IN dB
    %   pas_threshold_dB - Threshold below peak (e.g., 10, 15, 20 dB)
    %   multipath_low_bound - Floor value in dB
    %   antenna_pattern - Nx2 matrix [angle_offset, gain_dB]
    %   HPBW - Half-power beamwidth in degrees (30 for 7 GHz)

    if nargin < 6 || isempty(HPBW)
        HPBW = 30;  % Default for 7 GHz
    end
    if nargin < 5
        antenna_pattern = [];
    end

    expanded_powers = powers_dB;
    selected_angles = [];

    peak_dB = max(powers_dB);
    if peak_dB <= multipath_low_bound + 1
        AS = 0;
        return;
    end

    threshold_dB = peak_dB - pas_threshold_dB;
    mask = powers_dB >= threshold_dB;

    if ~any(mask)
        [~, idx] = max(powers_dB);
        mask(idx) = true;
    end

    selected_angles = angles(mask);
    selected_powers_dB = powers_dB(mask);

    [selected_angles, sort_idx] = sort(selected_angles, 'ascend');
    selected_powers_dB = selected_powers_dB(sort_idx);
    Nsel = length(selected_angles);

    if Nsel == 0
        AS = 0;
        return;
    end

    % Lobe Detection (gap > HPBW → new lobe)
    if Nsel == 1
        lobe_starts = selected_angles(1);
        lobe_ends = selected_angles(1);
        lobe_start_powers_dB = selected_powers_dB(1);
        lobe_end_powers_dB = selected_powers_dB(1);
        nLobes = 1;
    else
        lobe_starts = [];
        lobe_ends = [];
        lobe_start_powers_dB = [];
        lobe_end_powers_dB = [];

        lobe_starts(1) = selected_angles(1);
        lobe_start_powers_dB(1) = selected_powers_dB(1);

        for i = 2:Nsel
            diff_ang = selected_angles(i) - selected_angles(i-1);
            if diff_ang < 0
                diff_ang = diff_ang + 360;
            end

            if diff_ang > HPBW
                lobe_ends(end+1) = selected_angles(i-1); %#ok<AGROW>
                lobe_end_powers_dB(end+1) = selected_powers_dB(i-1); %#ok<AGROW>
                lobe_starts(end+1) = selected_angles(i); %#ok<AGROW>
                lobe_start_powers_dB(end+1) = selected_powers_dB(i); %#ok<AGROW>
            end
        end

        lobe_ends(end+1) = selected_angles(end);
        lobe_end_powers_dB(end+1) = selected_powers_dB(end);
        nLobes = length(lobe_starts);
    end

    % Boundary Expansion using antenna pattern
    boundary_angles = [];
    boundary_powers_dB = [];

    if ~isempty(antenna_pattern) && size(antenna_pattern, 1) > 1
        pattern_angles = antenna_pattern(:, 1);
        pattern_gain = antenna_pattern(:, 2) - max(antenna_pattern(:, 2));

        for iLobe = 1:nLobes
            % Start boundary
            power_above_threshold_start = lobe_start_powers_dB(iLobe) - threshold_dB;
            [~, Ang_pos] = min(abs(abs(power_above_threshold_start) - abs(pattern_gain)));
            boundary_offset_start = abs(pattern_angles(Ang_pos));

            boundary_angle_start = lobe_starts(iLobe) - boundary_offset_start;
            if boundary_angle_start < 0
                boundary_angle_start = boundary_angle_start + 360;
            end
            boundary_angles(end+1) = boundary_angle_start; %#ok<AGROW>
            boundary_powers_dB(end+1) = threshold_dB; %#ok<AGROW>

            % End boundary
            power_above_threshold_end = lobe_end_powers_dB(iLobe) - threshold_dB;
            [~, Ang_pos] = min(abs(abs(power_above_threshold_end) - abs(pattern_gain)));
            boundary_offset_end = abs(pattern_angles(Ang_pos));

            boundary_angle_end = lobe_ends(iLobe) + boundary_offset_end;
            if boundary_angle_end >= 360
                boundary_angle_end = boundary_angle_end - 360;
            end
            boundary_angles(end+1) = boundary_angle_end; %#ok<AGROW>
            boundary_powers_dB(end+1) = threshold_dB; %#ok<AGROW>
        end
    end

    % Combine original + boundary MPCs
    all_angles = [selected_angles(:); boundary_angles(:)];
    all_powers_dB = [selected_powers_dB(:); boundary_powers_dB(:)];
    all_powers_lin = 10.^(all_powers_dB / 10);
    expanded_powers = all_powers_lin;
    all_powers_lin = all_powers_lin / sum(all_powers_lin);

    % 3GPP AS formula
    AS = compute_AS_3GPP(all_angles, all_powers_lin);
end

function AS = compute_AS_USC(angles, powers_dB, multipath_low_bound)
    % Compute Angular Spread — USC method (no PAS threshold)

    if nargin < 3
        multipath_low_bound = -200;
    end

    valid_mask = powers_dB > multipath_low_bound + 1;
    if ~any(valid_mask)
        AS = 0;
        return;
    end

    valid_angles = angles(valid_mask);
    valid_powers_dB = powers_dB(valid_mask);
    valid_powers_lin = 10.^(valid_powers_dB / 10);

    AS = compute_AS_3GPP(valid_angles, valid_powers_lin);
end

function AS = compute_AS_3GPP(angles, powers_lin)
    % 3GPP Angular Spread: AS = sqrt(-2 * ln(R))
    % where R = |sum(w * exp(j*theta))|

    if isempty(powers_lin) || sum(powers_lin) <= 0
        AS = 0;
        return;
    end

    weights = powers_lin(:) / sum(powers_lin(:));
    angles_rad = deg2rad(angles(:));
    R = abs(sum(weights .* exp(1j * angles_rad)));

    if R >= 1
        R = 1 - eps;
    end
    if R <= 0
        R = eps;
    end

    AS_rad = sqrt(-2 * log(R));
    AS = rad2deg(AS_rad);
end

function TX_power_table = load_TX_power_table(csv_path)
    % Load TX power lookup table from CSV file

    try
        opts = detectImportOptions(csv_path);
        data = readtable(csv_path, opts);

        TX_IDs = data.TX_ID;
        RX_IDs = data.RX_ID;
        TX_Powers = data.TX_Power;

        [unique_pairs, idx] = unique([TX_IDs, RX_IDs], 'rows');
        unique_TX_Power = TX_Powers(idx);

        TX_power_table = table(unique_pairs(:,1), unique_pairs(:,2), unique_TX_Power, ...
            'VariableNames', {'TX_ID', 'RX_ID', 'TX_Power'});

        fprintf('Loaded TX power table: %d unique TX-RX pairs\n', height(TX_power_table));

    catch ME
        warning('Could not load TX power table from CSV: %s', ME.message);
        warning('Using default TX power of 15.86 dBm for all locations');

        TX_power_table = table([1], [1], [15.86], ...
            'VariableNames', {'TX_ID', 'RX_ID', 'TX_Power'});
    end
end

function TX_Power = get_TX_power(TX_power_table, TX_ID, RX_ID)
    % Look up TX power for a specific TX-RX pair

    mask = (TX_power_table.TX_ID == TX_ID) & (TX_power_table.RX_ID == RX_ID);

    if any(mask)
        TX_Power = TX_power_table.TX_Power(mask);
        TX_Power = TX_Power(1);
    else
        tx_mask = TX_power_table.TX_ID == TX_ID;
        if any(tx_mask)
            TX_Power = mean(TX_power_table.TX_Power(tx_mask));
            warning('TX-RX pair TX%d-RX%d not found, using TX%d average: %.2f dBm', TX_ID, RX_ID, TX_ID, TX_Power);
        else
            TX_Power = 15.86;
            warning('TX-RX pair TX%d-RX%d not found, using default: %.2f dBm', TX_ID, RX_ID, TX_Power);
        end
    end
end

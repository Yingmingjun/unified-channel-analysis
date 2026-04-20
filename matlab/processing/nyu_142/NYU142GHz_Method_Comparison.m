%% ======================================================================
%  NYU 142GHz Data: Method Comparison (NYU vs USC)
%  ========================================================================
%
%  PURPOSE: Compare NYU and USC processing methods on NYU's 142GHz data
%           to quantify differences in Omni PL, RMS DS, ASA, and ASD
%
%  =========================================================================
%  METHOD COMPARISON SUMMARY
%  =========================================================================
%
%  COMMON SETTINGS (Both Methods):
%    - PDP Threshold: NYU's per-directional-PDP threshold (applied to EACH
%      directional PDP independently):
%        threshold_i = max(peak_i - 25 dB, noise_i + 5 dB)
%    - Noise Floor Estimation (NYU's original method from NYUprocessUSC145.m):
%        noise_i = 10*log10(mean(PDP_linear(end-5000:end)))
%      i.e., average of last 250 ns (5000 samples at 20 samples/ns) in LINEAR
%      domain, then converted to dB. The tail region contains pure thermal noise.
%    - AS Formula: 3GPP sqrt(-2*ln(R)) from circ_std.m
%
%  DIFFERENCES:
%    | Aspect          | NYU Method              | USC Method              |
%    |-----------------|-------------------------|-------------------------|
%    | Omni Synthesis  | SUM across directions   | perDelayMax (max/delay) |
%    | PAS Threshold   | 10/15/20 dB below peak  | NONE                    |
%    | Lobe Expansion  | Antenna pattern-based   | NONE                    |
%
%  DATA SOURCE:
%    - Location: D:\NYU-USC\Cross-Processing\NYU\NYU_Data\142AlignedDataset\
%    - Format: 10-column cell array per TX-RX pair
%    - Files: 27 .mat files (T1-R1, T1-R5, etc.)
%
%  TX POWER INFO (from 140GHz_Outdoor_BaseStation.csv):
%    - TX Power: VARIES per TX-RX pair (read from CSV)
%    - TX Antenna Gain: 27 dB
%    - RX Antenna Gain: 27 dB
%    - Frequency: 142 GHz
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
params.TX_Ant_Gain_dB = 27;        % TX antenna gain
params.RX_Ant_Gain_dB = 27;        % RX antenna gain
params.Frequency_GHz = 142;        % Carrier frequency
params.dilation_factor = 20;       % Samples per ns (NYU's standard)
% Optional delay gate for DS computation (parity with USC pipelines).
% Dynamic per-pair gate matching USC's convention: t_gate = d_LOS/c + 966.67 ns.
% The 966.67 ns is USC's "multipath horizon after LOS arrival"
% (d(end)-10 = 290 m of extra delay in USC's 1-GHz BW PDPs). Adding d_LOS/c
% shifts the gate by the LOS time-of-flight for each pair, so pairs with
% longer links get a longer gate — physically correct since late reflections
% can genuinely arrive at (d_LOS + 290)/c for any link.
% Set to Inf to disable gating entirely; set to a scalar (e.g. 966.67) to
% use a fixed (LOS-aligned assumption) gate for all pairs.
params.DS_MULTIPATH_HORIZON_NS = 966.67;  % margin beyond LOS (USC-parity)
params.DS_DELAY_GATE_NS = Inf;            % placeholder; per-pair value set in loop below

% =========================================================================
% LOAD TX POWER LOOKUP TABLE FROM CSV
% =========================================================================
% TX power varies per TX-RX pair - load from CSV file
U = paths();
csv_path = U.nyu_142_tx_power_csv;
TX_power_table = load_TX_power_table(csv_path);

% =========================================================================
% PDP THRESHOLD SETTINGS (NYU's method for BOTH)
% =========================================================================
config.thres_below_pk = 25;        % dB below peak
config.thres_above_noise = 5;      % dB above noise floor
config.multipath_low_bound = -200; % Absolute floor in dB (set low so surviving weak
                                    % signals like -105 dB are not confused with floor)

% =========================================================================
% PAS THRESHOLD SETTINGS (NYU Method only)
% =========================================================================
config.PAS_threshold_1 = 10;   % Strictest: 10 dB below peak
config.PAS_threshold_2 = 15;   % Medium: 15 dB below peak
config.PAS_threshold_3 = 20;   % Relaxed: 20 dB below peak

% =========================================================================
% ANTENNA PATTERN FILES (NYU Method - for interpolation)
% =========================================================================
config.antenna_pattern_path = U.nyu_142_pattern_dir;
config.azi_pattern_file = 'HPLANE Pattern Data 261D-27.DAT';
config.elev_pattern_file = 'EPLANE Pattern Data 261D-27.DAT';

% =========================================================================
% IEEE FIGURE SETTINGS FOR DOUBLE-COLUMN JOURNAL
% =========================================================================
% Figure dimension constants (inches)
IEEE_DOUBLE_COL_WIDTH = 7.0;   % Full page width (~7.16" max)
IEEE_SINGLE_COL_WIDTH = 3.5;   % Single column width

% Font settings optimized for IEEE double-column (no scaling needed at 1:1)
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

% Grid settings
set(0, 'DefaultAxesXGrid', 'on');
set(0, 'DefaultAxesYGrid', 'on');
set(0, 'DefaultAxesGridLineStyle', ':');
set(0, 'DefaultAxesGridAlpha', 0.3);

% Colors (colorblind-friendly)
colors.NYU_10dB = [0.0000 0.4470 0.7410];  % Blue
colors.NYU_15dB = [0.8500 0.3250 0.0980];  % Orange
colors.NYU_20dB = [0.9290 0.6940 0.1250];  % Yellow/Gold
colors.USC = [0.4660 0.6740 0.1880];       % Green

% =========================================================================
% PATHS
% =========================================================================
paths.data = U.raw_nyu_142;
paths.output = U.figures_nyu_142;
paths.results = U.results_nyu_142;
if ~exist(paths.output, 'dir'), mkdir(paths.output); end
if ~exist(paths.results, 'dir'), mkdir(paths.results); end

% Display configuration
fprintf('═══════════════════════════════════════════════════════════════════════\n');
fprintf('  NYU 142GHz Data: Method Comparison Configuration\n');
fprintf('═══════════════════════════════════════════════════════════════════════\n');
fprintf('  PDP Threshold: max(%d dB below peak, %d dB above noise) [NYU method]\n', ...
    config.thres_below_pk, config.thres_above_noise);
fprintf('  Omni Synthesis: NYU=SUM, USC=perDelayMax\n');
fprintf('  PAS Thresholds: %d dB, %d dB, %d dB (NYU only)\n', ...
    config.PAS_threshold_1, config.PAS_threshold_2, config.PAS_threshold_3);
fprintf('  TX Power: VARIES per TX-RX pair (from CSV), Ant Gain: TX=%d dB, RX=%d dB\n', ...
    params.TX_Ant_Gain_dB, params.RX_Ant_Gain_dB);
fprintf('  TX Power lookup table loaded: %d unique TX-RX pairs\n', height(TX_power_table));

% Load antenna patterns for NYU interpolation
antenna_azi = load_antenna_pattern(fullfile(config.antenna_pattern_path, config.azi_pattern_file));
antenna_elev = load_antenna_pattern(fullfile(config.antenna_pattern_path, config.elev_pattern_file));
fprintf('  Antenna patterns loaded: Azimuth (%d points), Elevation (%d points)\n', ...
    size(antenna_azi, 1), size(antenna_elev, 1));
fprintf('═══════════════════════════════════════════════════════════════════════\n\n');

%% SECTION 2: LOAD AND PROCESS ALL DATA FILES
fprintf('╔═══════════════════════════════════════════════════════════════════════╗\n');
fprintf('║         Processing NYU 142GHz Data with NYU and USC Methods          ║\n');
fprintf('╚═══════════════════════════════════════════════════════════════════════╝\n\n');

% Get list of data files
data_files = dir(fullfile(paths.data, '142GHz_Outdoor_*.mat'));
nFiles = length(data_files);
fprintf('Found %d TX-RX location files\n\n', nFiles);

% Initialize results storage
results = struct();
results.TX_RX_ID = cell(nFiles, 1);
results.Environment = cell(nFiles, 1);
results.TX_ID = zeros(nFiles, 1);
results.RX_ID = zeros(nFiles, 1);
results.TX_Power_dBm = zeros(nFiles, 1);  % TX power per location (from CSV)

% Path Loss
results.PL_NYU = zeros(nFiles, 1);      % NYU omni synthesis (SUM)
results.PL_USC = zeros(nFiles, 1);      % USC omni synthesis (perDelayMax)

% Delay Spread
results.DS_NYU = zeros(nFiles, 1);      % From NYU omni PDP
results.DS_USC = zeros(nFiles, 1);      % From USC omni PDP

% Angular Spread - ASA (Azimuth Spread of Arrival)
results.ASA_NYU_10dB = zeros(nFiles, 1);
results.ASA_NYU_15dB = zeros(nFiles, 1);
results.ASA_NYU_20dB = zeros(nFiles, 1);
results.ASA_USC = zeros(nFiles, 1);     % No PAS threshold

% Angular Spread - ASD (Azimuth Spread of Departure)
results.ASD_NYU_10dB = zeros(nFiles, 1);
results.ASD_NYU_15dB = zeros(nFiles, 1);
results.ASD_NYU_20dB = zeros(nFiles, 1);
results.ASD_USC = zeros(nFiles, 1);     % No PAS threshold

% Store PAS data for visualization
pas_store = struct();

%% SECTION 3: PROCESS EACH TX-RX PAIR
for iFile = 1:nFiles
    fname = data_files(iFile).name;
    filepath = fullfile(paths.data, fname);

    % Parse TX-RX IDs from filename
    tokens = regexp(fname, 'T(\d+)-R(\d+)', 'tokens');
    if ~isempty(tokens)
        TX_ID = str2double(tokens{1}{1});
        RX_ID = str2double(tokens{1}{2});
        TX_RX_ID = sprintf('T%d-R%d', TX_ID, RX_ID);
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

    % Look up T-R separation for per-pair dynamic DS gate (USC convention:
    % t_gate = d_LOS/c + 966.67 ns, where 966.67 is USC's "multipath
    % horizon after LOS"). Falls back to 30 m if lookup fails.
    mask = (TX_power_table.TX_ID == TX_ID) & (TX_power_table.RX_ID == RX_ID);
    if any(mask)
        d_LOS = TX_power_table.TR_sep_m(find(mask, 1));
    else
        d_LOS = 30.0;
    end
    c_light = 3e8;  % m/s
    tgate_pair_ns = (d_LOS / c_light) * 1e9 + params.DS_MULTIPATH_HORIZON_NS;
    results.Distance_m(iFile) = d_LOS;
    results.DS_Gate_ns(iFile) = tgate_pair_ns;

    fprintf('Processing [%2d/%2d] %s (Ptx=%.2f dBm) ... ', iFile, nFiles, TX_RX_ID, TX_Power_dBm);

    % Load data
    data = load(filepath);
    fnames = fieldnames(data);
    TRpdpSet = data.(fnames{1});

    % Get environment (LOS/NLOS) from column 10
    if size(TRpdpSet, 2) >= 10
        Env = TRpdpSet{1, 10};
        if ischar(Env)
            results.Environment{iFile} = Env;
        elseif isstring(Env)
            % MATLAB string type - convert to char
            results.Environment{iFile} = char(Env);
        elseif isnumeric(Env)
            if Env == 1
                results.Environment{iFile} = 'LOS';
            else
                results.Environment{iFile} = 'NLOS';
            end
        else
            results.Environment{iFile} = 'Unknown';
        end
    else
        results.Environment{iFile} = 'Unknown';
    end

    % =====================================================================
    % STEP 1: Apply NYU PDP Threshold (common for both methods)
    % =====================================================================
    [TRpdpSet_thr, noise_floor_dB] = apply_NYU_PDP_threshold(TRpdpSet, config);

    % =====================================================================
    % STEP 2: Generate PAS (Power Angular Spectrum) for AOA and AOD
    % =====================================================================
    % AOA PAS (column 8 = AOA azimuth, column 6 = AOD azimuth)
    [AOA_angles, AOA_powers, AOA_set] = generate_PAS(TRpdpSet_thr, 8, 6, config.multipath_low_bound);
    % AOD PAS
    [AOD_angles, AOD_powers, AOD_set] = generate_PAS(TRpdpSet_thr, 6, 8, config.multipath_low_bound);

    % =====================================================================
    % STEP 3: Compute Omni PDP using both methods
    % =====================================================================
    % NYU method: SUM across all directions
    [OmniPDP_NYU, delays_ns] = compute_omni_NYU(TRpdpSet_thr, params);

    % USC method: perDelayMax (max per delay bin)
    [OmniPDP_USC, ~] = compute_omni_USC(TRpdpSet_thr, params);

    % =====================================================================
    % STEP 4: Compute Path Loss
    % =====================================================================
    % PL = TX_Power + TX_Gain + RX_Gain - Pr (received power)
    % Note: TX_Power_dBm varies per TX-RX pair (from CSV lookup table)
    Pr_NYU_dB = 10*log10(max(sum(OmniPDP_NYU), 1e-30));
    Pr_USC_dB = 10*log10(max(sum(OmniPDP_USC), 1e-30));

    % Path loss (positive value) - using location-specific TX power
    results.PL_NYU(iFile) = TX_Power_dBm + params.TX_Ant_Gain_dB + params.RX_Ant_Gain_dB - Pr_NYU_dB;
    results.PL_USC(iFile) = TX_Power_dBm + params.TX_Ant_Gain_dB + params.RX_Ant_Gain_dB - Pr_USC_dB;

    % =====================================================================
    % STEP 5: Compute Delay Spread
    % =====================================================================
    % NOTE: per-pair dynamic gate (tgate_pair_ns) was tested and produced
    % identical DS values to the fixed 966.67 ns gate for NYU 142 — the
    % +12 dB noise threshold already kills power beyond ~1 us in this
    % dataset, so the incremental (d_LOS/c) gate extension adds nothing.
    % Keeping fixed 966.67 for simplicity and USC-parity; switch to
    % tgate_pair_ns if you want the principled dynamic variant.
    results.DS_NYU(iFile) = compute_RMS_DS(delays_ns, OmniPDP_NYU, params.DS_MULTIPATH_HORIZON_NS);
    results.DS_USC(iFile) = compute_RMS_DS(delays_ns, OmniPDP_USC, params.DS_MULTIPATH_HORIZON_NS);

    % =====================================================================
    % STEP 6: Compute Angular Spread - NYU Method (with PAS threshold + antenna pattern expansion)
    % =====================================================================
    % NYU method includes:
    %   1. PAS threshold application (10/15/20 dB below peak)
    %   2. Antenna pattern-based lobe expansion (accounts for HPBW)
    %   3. 3GPP AS formula: sqrt(-2*ln(R))
    %
    % The antenna pattern expansion ensures that even a single measurement
    % angle is expanded into a spatial lobe based on the antenna beamwidth,
    % avoiding the AS=0 issue when only one angle passes threshold.

    % ASA with different thresholds (using antenna pattern expansion)
    [ASA_10, ~, ~] = compute_AS_NYU(AOA_angles, AOA_powers, config.PAS_threshold_1, config.multipath_low_bound, antenna_azi);
    [ASA_15, ~, ~] = compute_AS_NYU(AOA_angles, AOA_powers, config.PAS_threshold_2, config.multipath_low_bound, antenna_azi);
    [ASA_20, ~, ~] = compute_AS_NYU(AOA_angles, AOA_powers, config.PAS_threshold_3, config.multipath_low_bound, antenna_azi);

    results.ASA_NYU_10dB(iFile) = ASA_10;
    results.ASA_NYU_15dB(iFile) = ASA_15;
    results.ASA_NYU_20dB(iFile) = ASA_20;

    % ASD with different thresholds (using antenna pattern expansion)
    [ASD_10, ~, ~] = compute_AS_NYU(AOD_angles, AOD_powers, config.PAS_threshold_1, config.multipath_low_bound, antenna_azi);
    [ASD_15, ~, ~] = compute_AS_NYU(AOD_angles, AOD_powers, config.PAS_threshold_2, config.multipath_low_bound, antenna_azi);
    [ASD_20, ~, ~] = compute_AS_NYU(AOD_angles, AOD_powers, config.PAS_threshold_3, config.multipath_low_bound, antenna_azi);

    results.ASD_NYU_10dB(iFile) = ASD_10;
    results.ASD_NYU_15dB(iFile) = ASD_15;
    results.ASD_NYU_20dB(iFile) = ASD_20;

    % =====================================================================
    % STEP 7: Compute Angular Spread - USC Method (no PAS threshold)
    % =====================================================================
    results.ASA_USC(iFile) = compute_AS_USC(AOA_angles, AOA_powers, config.multipath_low_bound);
    results.ASD_USC(iFile) = compute_AS_USC(AOD_angles, AOD_powers, config.multipath_low_bound);

    % Store PAS for first LOS and NLOS locations (for visualization)
    if strcmp(results.Environment{iFile}, 'LOS') && ~isfield(pas_store, 'LOS')
        pas_store.LOS.TX_RX_ID = TX_RX_ID;
        pas_store.LOS.AOA_angles = AOA_angles;
        pas_store.LOS.AOA_powers = AOA_powers;
        pas_store.LOS.AOD_angles = AOD_angles;
        pas_store.LOS.AOD_powers = AOD_powers;
        pas_store.LOS.OmniPDP_NYU = OmniPDP_NYU;
        pas_store.LOS.OmniPDP_USC = OmniPDP_USC;
        pas_store.LOS.delays_ns = delays_ns;
    elseif ~strcmp(results.Environment{iFile}, 'LOS') && ~isfield(pas_store, 'NLOS')
        pas_store.NLOS.TX_RX_ID = TX_RX_ID;
        pas_store.NLOS.AOA_angles = AOA_angles;
        pas_store.NLOS.AOA_powers = AOA_powers;
        pas_store.NLOS.AOD_angles = AOD_angles;
        pas_store.NLOS.AOD_powers = AOD_powers;
        pas_store.NLOS.OmniPDP_NYU = OmniPDP_NYU;
        pas_store.NLOS.OmniPDP_USC = OmniPDP_USC;
        pas_store.NLOS.delays_ns = delays_ns;
    end

    fprintf('%s | PL: NYU=%.1f, USC=%.1f | DS: NYU=%.1f, USC=%.1f ns\n', ...
        results.Environment{iFile}, results.PL_NYU(iFile), results.PL_USC(iFile), ...
        results.DS_NYU(iFile), results.DS_USC(iFile));
end

fprintf('\nProcessing complete!\n\n');

%% SECTION 4: GENERATE TABLES
% =========================================================================
% TABLE 1: Method Comparison Summary
% =========================================================================
fprintf('╔═══════════════════════════════════════════════════════════════════════════════════════════════════════╗\n');
fprintf('║                               TABLE 1: METHOD COMPARISON SUMMARY                                       ║\n');
fprintf('╠════════════════════════╤═══════════════════════════════════╤═══════════════════════════════════════════╣\n');
fprintf('║ Aspect                 │ NYU Method                        │ USC Method                                ║\n');
fprintf('╠════════════════════════╪═══════════════════════════════════╪═══════════════════════════════════════════╣\n');
fprintf('║ PDP Threshold          │ max(25dB below pk, 5dB abv noise) │ SAME (NYU method)                         ║\n');
fprintf('║ Omni Synthesis         │ SUM across all directions         │ perDelayMax (max per delay)               ║\n');
fprintf('║ PAS Threshold          │ 10/15/20 dB below peak            │ NONE                                      ║\n');
fprintf('║ Lobe Expansion         │ Antenna pattern-based (HPBW=8°)   │ NONE                                      ║\n');
fprintf('║ AS Formula             │ 3GPP: sqrt(-2*ln(R))              │ SAME                                      ║\n');
fprintf('╚════════════════════════╧═══════════════════════════════════╧═══════════════════════════════════════════╝\n\n');

% =========================================================================
% TABLE 2: Per TX-RX Results
% =========================================================================
fprintf('╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗\n');
fprintf('║                                              TABLE 2: PER TX-RX PAIR RESULTS                                                               ║\n');
fprintf('╠═════════╤═══════╤═══════════════════╤═══════════════════╤═════════════════════════════════════════════════════════════════════════════════╣\n');
fprintf('║  TX-RX  │  Env  │   Path Loss (dB)  │ Delay Spread (ns) │                    Angular Spread (degrees)                                      ║\n');
fprintf('║         │       │   NYU  │   USC    │   NYU  │   USC    │  ASA-10  │  ASA-15  │  ASA-20  │ ASA-USC │  ASD-10  │  ASD-15  │  ASD-20  │ ASD-USC║\n');
fprintf('╠═════════╪═══════╪════════╪══════════╪════════╪══════════╪══════════╪══════════╪══════════╪═════════╪══════════╪══════════╪══════════╪════════╣\n');

for i = 1:nFiles
    fprintf('║ %-7s │ %-5s │ %6.1f │ %6.1f   │ %6.2f │ %6.2f   │ %7.1f  │ %7.1f  │ %7.1f  │ %6.1f  │ %7.1f  │ %7.1f  │ %7.1f  │ %6.1f ║\n', ...
        results.TX_RX_ID{i}, results.Environment{i}, ...
        results.PL_NYU(i), results.PL_USC(i), ...
        results.DS_NYU(i), results.DS_USC(i), ...
        results.ASA_NYU_10dB(i), results.ASA_NYU_15dB(i), results.ASA_NYU_20dB(i), results.ASA_USC(i), ...
        results.ASD_NYU_10dB(i), results.ASD_NYU_15dB(i), results.ASD_NYU_20dB(i), results.ASD_USC(i));
end
fprintf('╚═════════╧═══════╧════════╧══════════╧════════╧══════════╧══════════╧══════════╧══════════╧═════════╧══════════╧══════════╧══════════╧════════╝\n\n');

% =========================================================================
% TABLE 3: Statistical Summary
% =========================================================================
los_mask = strcmp(results.Environment, 'LOS');
nlos_mask = ~los_mask;

fprintf('╔═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗\n');
fprintf('║                                              TABLE 3: STATISTICAL SUMMARY                                                      ║\n');
fprintf('╠════════════════════════════════╤═════════════════════════════════════╤═════════════════════════════════════════════════════════╣\n');
fprintf('║ Metric                         │     LOS (mean ± std)                │     NLOS (mean ± std)               │    ALL            ║\n');
fprintf('╠════════════════════════════════╪═════════════════════════════════════╪═════════════════════════════════════════════════════════╣\n');

% Path Loss
fprintf('║ PL - NYU (SUM)                 │ %6.1f ± %5.1f dB                    │ %6.1f ± %5.1f dB                    │ %6.1f ± %5.1f dB  ║\n', ...
    mean(results.PL_NYU(los_mask)), std(results.PL_NYU(los_mask)), ...
    mean(results.PL_NYU(nlos_mask)), std(results.PL_NYU(nlos_mask)), ...
    mean(results.PL_NYU), std(results.PL_NYU));
fprintf('║ PL - USC (perDelayMax)         │ %6.1f ± %5.1f dB                    │ %6.1f ± %5.1f dB                    │ %6.1f ± %5.1f dB  ║\n', ...
    mean(results.PL_USC(los_mask)), std(results.PL_USC(los_mask)), ...
    mean(results.PL_USC(nlos_mask)), std(results.PL_USC(nlos_mask)), ...
    mean(results.PL_USC), std(results.PL_USC));
fprintf('║ Δ PL (NYU - USC)               │ %6.1f ± %5.1f dB                    │ %6.1f ± %5.1f dB                    │ %6.1f ± %5.1f dB  ║\n', ...
    mean(results.PL_NYU(los_mask) - results.PL_USC(los_mask)), std(results.PL_NYU(los_mask) - results.PL_USC(los_mask)), ...
    mean(results.PL_NYU(nlos_mask) - results.PL_USC(nlos_mask)), std(results.PL_NYU(nlos_mask) - results.PL_USC(nlos_mask)), ...
    mean(results.PL_NYU - results.PL_USC), std(results.PL_NYU - results.PL_USC));
fprintf('╠════════════════════════════════╪═════════════════════════════════════╪═════════════════════════════════════════════════════════╣\n');

% Delay Spread
fprintf('║ DS - NYU (SUM)                 │ %6.2f ± %5.2f ns                    │ %6.2f ± %5.2f ns                    │ %6.2f ± %5.2f ns  ║\n', ...
    mean(results.DS_NYU(los_mask)), std(results.DS_NYU(los_mask)), ...
    mean(results.DS_NYU(nlos_mask)), std(results.DS_NYU(nlos_mask)), ...
    mean(results.DS_NYU), std(results.DS_NYU));
fprintf('║ DS - USC (perDelayMax)         │ %6.2f ± %5.2f ns                    │ %6.2f ± %5.2f ns                    │ %6.2f ± %5.2f ns  ║\n', ...
    mean(results.DS_USC(los_mask)), std(results.DS_USC(los_mask)), ...
    mean(results.DS_USC(nlos_mask)), std(results.DS_USC(nlos_mask)), ...
    mean(results.DS_USC), std(results.DS_USC));
fprintf('╠════════════════════════════════╪═════════════════════════════════════╪═════════════════════════════════════════════════════════╣\n');

% ASA
fprintf('║ ASA - NYU 10dB                 │ %6.1f ± %5.1f deg                   │ %6.1f ± %5.1f deg                   │ %6.1f ± %5.1f deg ║\n', ...
    mean(results.ASA_NYU_10dB(los_mask)), std(results.ASA_NYU_10dB(los_mask)), ...
    mean(results.ASA_NYU_10dB(nlos_mask)), std(results.ASA_NYU_10dB(nlos_mask)), ...
    mean(results.ASA_NYU_10dB), std(results.ASA_NYU_10dB));
fprintf('║ ASA - NYU 20dB                 │ %6.1f ± %5.1f deg                   │ %6.1f ± %5.1f deg                   │ %6.1f ± %5.1f deg ║\n', ...
    mean(results.ASA_NYU_20dB(los_mask)), std(results.ASA_NYU_20dB(los_mask)), ...
    mean(results.ASA_NYU_20dB(nlos_mask)), std(results.ASA_NYU_20dB(nlos_mask)), ...
    mean(results.ASA_NYU_20dB), std(results.ASA_NYU_20dB));
fprintf('║ ASA - USC (no threshold)       │ %6.1f ± %5.1f deg                   │ %6.1f ± %5.1f deg                   │ %6.1f ± %5.1f deg ║\n', ...
    mean(results.ASA_USC(los_mask)), std(results.ASA_USC(los_mask)), ...
    mean(results.ASA_USC(nlos_mask)), std(results.ASA_USC(nlos_mask)), ...
    mean(results.ASA_USC), std(results.ASA_USC));
fprintf('╚════════════════════════════════╧═════════════════════════════════════╧═════════════════════════════════════════════════════════╝\n\n');

%% SECTION 5: GENERATE FIGURES
% =========================================================================
% FIGURE 1: Omni PDP Comparison (NYU SUM vs USC perDelayMax)
% IEEE double-column: 7.0" x 2.8" for 1x2 subplot
% =========================================================================
fig1 = figure('Units', 'inches', 'Position', [1 1 IEEE_DOUBLE_COL_WIDTH 2.8], 'Name', 'Fig1: Omni PDP Comparison');

if isfield(pas_store, 'LOS')
    subplot(1,2,1);
    plot(pas_store.LOS.delays_ns, 10*log10(pas_store.LOS.OmniPDP_NYU + eps), ...
        'Color', colors.NYU_10dB, 'LineWidth', 1.2, 'DisplayName', 'NYU (SUM)');
    hold on;
    plot(pas_store.LOS.delays_ns, 10*log10(pas_store.LOS.OmniPDP_USC + eps), ...
        'Color', colors.USC, 'LineWidth', 1.2, 'DisplayName', 'USC (perDelayMax)');
    xlabel('Delay (ns)', 'FontSize', 10, 'Interpreter', 'latex');
    ylabel('Power (dB)', 'FontSize', 10, 'Interpreter', 'latex');
    title(sprintf('(a) LOS: %s', pas_store.LOS.TX_RX_ID), 'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'latex');
    legend('Location', 'northeast', 'FontSize', 8, 'Box', 'off', 'Interpreter', 'latex');
    grid on;
    xlim([0 200]);
    set(gca, 'FontSize', 9);
end

if isfield(pas_store, 'NLOS')
    subplot(1,2,2);
    plot(pas_store.NLOS.delays_ns, 10*log10(pas_store.NLOS.OmniPDP_NYU + eps), ...
        'Color', colors.NYU_10dB, 'LineWidth', 1.2, 'DisplayName', 'NYU (SUM)');
    hold on;
    plot(pas_store.NLOS.delays_ns, 10*log10(pas_store.NLOS.OmniPDP_USC + eps), ...
        'Color', colors.USC, 'LineWidth', 1.2, 'DisplayName', 'USC (perDelayMax)');
    xlabel('Delay (ns)', 'FontSize', 10, 'Interpreter', 'latex');
    ylabel('Power (dB)', 'FontSize', 10, 'Interpreter', 'latex');
    title(sprintf('(b) NLOS: %s', pas_store.NLOS.TX_RX_ID), 'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'latex');
    legend('Location', 'northeast', 'FontSize', 8, 'Box', 'off', 'Interpreter', 'latex');
    grid on;
    xlim([0 200]);
    set(gca, 'FontSize', 9);
end

% Save with tight layout
set(fig1, 'PaperPositionMode', 'auto');
if exist('exportgraphics', 'file')
    exportgraphics(fig1, fullfile(paths.output, 'Fig1_OmniPDP_Comparison.pdf'), 'ContentType', 'vector', 'BackgroundColor', 'white');
    exportgraphics(fig1, fullfile(paths.output, 'Fig1_OmniPDP_Comparison.png'), 'Resolution', 300, 'BackgroundColor', 'white');
else
    saveas(fig1, fullfile(paths.output, 'Fig1_OmniPDP_Comparison.png'));
    print(fig1, fullfile(paths.output, 'Fig1_OmniPDP_Comparison.pdf'), '-dpdf', '-r300');
end
saveas(fig1, fullfile(paths.output, 'Fig1_OmniPDP_Comparison.fig'));

% =========================================================================
% FIGURE 2: Path Loss Comparison
% IEEE double-column: 7.0" x 2.8" for 1x2 subplot
% =========================================================================
fig2 = figure('Units', 'inches', 'Position', [1 1 IEEE_DOUBLE_COL_WIDTH 2.8], 'Name', 'Fig2: Path Loss');

subplot(1,2,1);
bar_data_PL = [results.PL_NYU, results.PL_USC];
b = bar(1:nFiles, bar_data_PL, 'grouped', 'BarWidth', 0.75);
b(1).FaceColor = colors.NYU_10dB;
b(2).FaceColor = colors.USC;
ax = gca;
ax.XTick = 1:nFiles;
ax.XTickLabel = results.TX_RX_ID;
ax.XTickLabelRotation = 60;
ax.TickLabelInterpreter = 'none';
ax.FontSize = 8;
xlabel('TX-RX Location', 'FontSize', 10, 'Interpreter', 'latex');
ylabel('Path Loss (dB)', 'FontSize', 10, 'Interpreter', 'latex');
title('(a) Path Loss Comparison', 'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'latex');
legend({'NYU (SUM)', 'USC (perDelayMax)'}, 'Location', 'northwest', 'FontSize', 8, 'Box', 'off', 'Interpreter', 'latex');
grid on;

subplot(1,2,2);
boxplot_data_PL = [results.PL_NYU, results.PL_USC];
bp = boxplot(boxplot_data_PL, 'Labels', {'NYU (SUM)', 'USC (perDelayMax)'}, 'Colors', 'k', 'Widths', 0.6);
set(bp, 'LineWidth', 1.0);
h = findobj(gca, 'Tag', 'Box');
colors_box = {colors.USC, colors.NYU_10dB};
for j = 1:length(h)
    patch(get(h(j), 'XData'), get(h(j), 'YData'), colors_box{j}, 'FaceAlpha', 0.5);
end
ylabel('Path Loss (dB)', 'FontSize', 10, 'Interpreter', 'latex');
title('(b) Path Loss Distribution', 'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'latex');
set(gca, 'FontSize', 9);
grid on;

% Save with tight layout
set(fig2, 'PaperPositionMode', 'auto');
if exist('exportgraphics', 'file')
    exportgraphics(fig2, fullfile(paths.output, 'Fig2_PathLoss_Comparison.pdf'), 'ContentType', 'vector', 'BackgroundColor', 'white');
    exportgraphics(fig2, fullfile(paths.output, 'Fig2_PathLoss_Comparison.png'), 'Resolution', 300, 'BackgroundColor', 'white');
else
    saveas(fig2, fullfile(paths.output, 'Fig2_PathLoss_Comparison.png'));
    print(fig2, fullfile(paths.output, 'Fig2_PathLoss_Comparison.pdf'), '-dpdf', '-r300');
end
saveas(fig2, fullfile(paths.output, 'Fig2_PathLoss_Comparison.fig'));

% =========================================================================
% FIGURE 3: Delay Spread Comparison
% =========================================================================
fig3 = figure('Units', 'inches', 'Position', [1 1 12 5], 'Name', 'Fig3: Delay Spread');

subplot(1,2,1);
bar_data_DS = [results.DS_NYU, results.DS_USC];
b = bar(1:nFiles, bar_data_DS, 'grouped', 'BarWidth', 0.8);
b(1).FaceColor = colors.NYU_10dB;
b(2).FaceColor = colors.USC;
ax = gca;
ax.XTick = 1:nFiles;
ax.XTickLabel = results.TX_RX_ID;
ax.XTickLabelRotation = 45;
ax.TickLabelInterpreter = 'none';
xlabel('TX-RX Location', 'FontSize', 11, 'Interpreter', 'latex');
ylabel('RMS Delay Spread (ns)', 'FontSize', 11, 'Interpreter', 'latex');
title('(a) Delay Spread Comparison', 'FontSize', 12, 'Interpreter', 'latex');
legend({'NYU (SUM)', 'USC (perDelayMax)'}, 'Location', 'northwest', 'FontSize', 9, 'Interpreter', 'latex');
grid on;

subplot(1,2,2);
boxplot_data_DS = [results.DS_NYU, results.DS_USC];
bp = boxplot(boxplot_data_DS, 'Labels', {'NYU (SUM)', 'USC (perDelayMax)'}, 'Colors', 'k', 'Widths', 0.6);
set(bp, 'LineWidth', 1.2);
h = findobj(gca, 'Tag', 'Box');
for j = 1:length(h)
    patch(get(h(j), 'XData'), get(h(j), 'YData'), colors_box{j}, 'FaceAlpha', 0.5);
end
ylabel('RMS Delay Spread (ns)', 'FontSize', 11, 'Interpreter', 'latex');
title('(b) Delay Spread Distribution', 'FontSize', 12, 'Interpreter', 'latex');
grid on;

sgtitle('Figure 3: RMS Delay Spread - NYU (SUM) vs USC (perDelayMax)', 'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'latex');
saveas(fig3, fullfile(paths.output, 'Fig3_DelaySpread_Comparison.png'));
saveas(fig3, fullfile(paths.output, 'Fig3_DelaySpread_Comparison.fig'));
print(fig3, fullfile(paths.output, 'Fig3_DelaySpread_Comparison.pdf'), '-dpdf', '-r300');

% =========================================================================
% FIGURE 4: PAS Display with Threshold Lines
% =========================================================================
fig4 = figure('Units', 'inches', 'Position', [1 1 12 8], 'Name', 'Fig4: PAS Display');

if isfield(pas_store, 'LOS')
    % AOA - LOS
    subplot(2,2,1);
    stem(pas_store.LOS.AOA_angles, pas_store.LOS.AOA_powers, 'Color', [0.7 0.7 0.7], 'LineWidth', 1, 'MarkerSize', 4);
    hold on;
    peak_power = max(pas_store.LOS.AOA_powers);
    yline(peak_power * 10^(-config.PAS_threshold_1/10), 'r--', 'LineWidth', 1.5, 'Label', sprintf('%ddB thr', config.PAS_threshold_1));
    yline(peak_power * 10^(-config.PAS_threshold_2/10), 'b--', 'LineWidth', 1.5, 'Label', sprintf('%ddB thr', config.PAS_threshold_2));
    yline(peak_power * 10^(-config.PAS_threshold_3/10), 'g--', 'LineWidth', 1.5, 'Label', sprintf('%ddB thr', config.PAS_threshold_3));
    xlabel('AOA Azimuth ($^\circ$)', 'FontSize', 11, 'Interpreter', 'latex');
    ylabel('Power (linear)', 'FontSize', 11, 'Interpreter', 'latex');
    title(sprintf('(a) AOA PAS - LOS %s', pas_store.LOS.TX_RX_ID), 'FontSize', 12, 'Interpreter', 'latex');
    grid on;

    % AOD - LOS
    subplot(2,2,2);
    stem(pas_store.LOS.AOD_angles, pas_store.LOS.AOD_powers, 'Color', [0.7 0.7 0.7], 'LineWidth', 1, 'MarkerSize', 4);
    hold on;
    peak_power = max(pas_store.LOS.AOD_powers);
    yline(peak_power * 10^(-config.PAS_threshold_1/10), 'r--', 'LineWidth', 1.5, 'Label', sprintf('%ddB thr', config.PAS_threshold_1));
    yline(peak_power * 10^(-config.PAS_threshold_2/10), 'b--', 'LineWidth', 1.5, 'Label', sprintf('%ddB thr', config.PAS_threshold_2));
    yline(peak_power * 10^(-config.PAS_threshold_3/10), 'g--', 'LineWidth', 1.5, 'Label', sprintf('%ddB thr', config.PAS_threshold_3));
    xlabel('AOD Azimuth ($^\circ$)', 'FontSize', 11, 'Interpreter', 'latex');
    ylabel('Power (linear)', 'FontSize', 11, 'Interpreter', 'latex');
    title(sprintf('(b) AOD PAS - LOS %s', pas_store.LOS.TX_RX_ID), 'FontSize', 12, 'Interpreter', 'latex');
    grid on;
end

if isfield(pas_store, 'NLOS')
    % AOA - NLOS
    subplot(2,2,3);
    stem(pas_store.NLOS.AOA_angles, pas_store.NLOS.AOA_powers, 'Color', [0.7 0.7 0.7], 'LineWidth', 1, 'MarkerSize', 4);
    hold on;
    peak_power = max(pas_store.NLOS.AOA_powers);
    yline(peak_power * 10^(-config.PAS_threshold_1/10), 'r--', 'LineWidth', 1.5, 'Label', sprintf('%ddB thr', config.PAS_threshold_1));
    yline(peak_power * 10^(-config.PAS_threshold_2/10), 'b--', 'LineWidth', 1.5, 'Label', sprintf('%ddB thr', config.PAS_threshold_2));
    yline(peak_power * 10^(-config.PAS_threshold_3/10), 'g--', 'LineWidth', 1.5, 'Label', sprintf('%ddB thr', config.PAS_threshold_3));
    xlabel('AOA Azimuth ($^\circ$)', 'FontSize', 11, 'Interpreter', 'latex');
    ylabel('Power (linear)', 'FontSize', 11, 'Interpreter', 'latex');
    title(sprintf('(c) AOA PAS - NLOS %s', pas_store.NLOS.TX_RX_ID), 'FontSize', 12, 'Interpreter', 'latex');
    grid on;

    % AOD - NLOS
    subplot(2,2,4);
    stem(pas_store.NLOS.AOD_angles, pas_store.NLOS.AOD_powers, 'Color', [0.7 0.7 0.7], 'LineWidth', 1, 'MarkerSize', 4);
    hold on;
    peak_power = max(pas_store.NLOS.AOD_powers);
    yline(peak_power * 10^(-config.PAS_threshold_1/10), 'r--', 'LineWidth', 1.5, 'Label', sprintf('%ddB thr', config.PAS_threshold_1));
    yline(peak_power * 10^(-config.PAS_threshold_2/10), 'b--', 'LineWidth', 1.5, 'Label', sprintf('%ddB thr', config.PAS_threshold_2));
    yline(peak_power * 10^(-config.PAS_threshold_3/10), 'g--', 'LineWidth', 1.5, 'Label', sprintf('%ddB thr', config.PAS_threshold_3));
    xlabel('AOD Azimuth ($^\circ$)', 'FontSize', 11, 'Interpreter', 'latex');
    ylabel('Power (linear)', 'FontSize', 11, 'Interpreter', 'latex');
    title(sprintf('(d) AOD PAS - NLOS %s', pas_store.NLOS.TX_RX_ID), 'FontSize', 12, 'Interpreter', 'latex');
    grid on;
end

sgtitle('Figure 4: Power Angular Spectrum with PAS Threshold Lines', 'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'latex');
saveas(fig4, fullfile(paths.output, 'Fig4_PAS_Display.png'));
saveas(fig4, fullfile(paths.output, 'Fig4_PAS_Display.fig'));
print(fig4, fullfile(paths.output, 'Fig4_PAS_Display.pdf'), '-dpdf', '-r300');

% =========================================================================
% FIGURE 5: Polar PAS Plot
% =========================================================================
fig5 = figure('Units', 'inches', 'Position', [1 1 10 8], 'Name', 'Fig5: Polar PAS');

if isfield(pas_store, 'LOS')
    subplot(2,2,1);
    polarplot(deg2rad(pas_store.LOS.AOA_angles), pas_store.LOS.AOA_powers / max(pas_store.LOS.AOA_powers), ...
        'Color', colors.NYU_10dB, 'LineWidth', 2);
    title(sprintf('AOA - LOS %s', pas_store.LOS.TX_RX_ID), 'FontSize', 11);

    subplot(2,2,2);
    polarplot(deg2rad(pas_store.LOS.AOD_angles), pas_store.LOS.AOD_powers / max(pas_store.LOS.AOD_powers), ...
        'Color', colors.USC, 'LineWidth', 2);
    title(sprintf('AOD - LOS %s', pas_store.LOS.TX_RX_ID), 'FontSize', 11);
end

if isfield(pas_store, 'NLOS')
    subplot(2,2,3);
    polarplot(deg2rad(pas_store.NLOS.AOA_angles), pas_store.NLOS.AOA_powers / max(pas_store.NLOS.AOA_powers), ...
        'Color', colors.NYU_10dB, 'LineWidth', 2);
    title(sprintf('AOA - NLOS %s', pas_store.NLOS.TX_RX_ID), 'FontSize', 11);

    subplot(2,2,4);
    polarplot(deg2rad(pas_store.NLOS.AOD_angles), pas_store.NLOS.AOD_powers / max(pas_store.NLOS.AOD_powers), ...
        'Color', colors.USC, 'LineWidth', 2);
    title(sprintf('AOD - NLOS %s', pas_store.NLOS.TX_RX_ID), 'FontSize', 11);
end

sgtitle('Figure 5: Polar Power Angular Spectrum', 'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'latex');
saveas(fig5, fullfile(paths.output, 'Fig5_Polar_PAS.png'));
saveas(fig5, fullfile(paths.output, 'Fig5_Polar_PAS.fig'));
print(fig5, fullfile(paths.output, 'Fig5_Polar_PAS.pdf'), '-dpdf', '-r300');

% =========================================================================
% FIGURE 6: Angular Spread Bar Chart
% IEEE double-column: 7.0" x 3.0" for 1x2 subplot with dense bars
% =========================================================================
fig6 = figure('Units', 'inches', 'Position', [1 1 IEEE_DOUBLE_COL_WIDTH 3.0], 'Name', 'Fig6: AS Bar Chart');

% ASA
subplot(1,2,1);
bar_data_ASA = [results.ASA_NYU_10dB, results.ASA_NYU_15dB, results.ASA_NYU_20dB, results.ASA_USC];
b = bar(1:nFiles, bar_data_ASA, 'grouped', 'BarWidth', 0.75);
b(1).FaceColor = colors.NYU_10dB;
b(2).FaceColor = colors.NYU_15dB;
b(3).FaceColor = colors.NYU_20dB;
b(4).FaceColor = colors.USC;
ax = gca;
ax.XTick = 1:nFiles;
ax.XTickLabel = results.TX_RX_ID;
ax.XTickLabelRotation = 60;
ax.TickLabelInterpreter = 'none';
ax.FontSize = 7;
xlabel('TX-RX Location', 'FontSize', 10, 'Interpreter', 'latex');
ylabel('ASA ($^\circ$)', 'FontSize', 10, 'Interpreter', 'latex');
title('(a) Azimuth Spread of Arrival', 'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'latex');
legend({sprintf('NYU %ddB', config.PAS_threshold_1), sprintf('NYU %ddB', config.PAS_threshold_2), ...
    sprintf('NYU %ddB', config.PAS_threshold_3), 'USC (no thr)'}, 'Location', 'northwest', 'FontSize', 7, 'Box', 'off', 'Interpreter', 'none');
grid on;

% ASD
subplot(1,2,2);
bar_data_ASD = [results.ASD_NYU_10dB, results.ASD_NYU_15dB, results.ASD_NYU_20dB, results.ASD_USC];
b = bar(1:nFiles, bar_data_ASD, 'grouped', 'BarWidth', 0.75);
b(1).FaceColor = colors.NYU_10dB;
b(2).FaceColor = colors.NYU_15dB;
b(3).FaceColor = colors.NYU_20dB;
b(4).FaceColor = colors.USC;
ax = gca;
ax.XTick = 1:nFiles;
ax.XTickLabel = results.TX_RX_ID;
ax.XTickLabelRotation = 60;
ax.TickLabelInterpreter = 'none';
ax.FontSize = 7;
xlabel('TX-RX Location', 'FontSize', 10, 'Interpreter', 'latex');
ylabel('ASD ($^\circ$)', 'FontSize', 10, 'Interpreter', 'latex');
title('(b) Azimuth Spread of Departure', 'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'latex');
legend({sprintf('NYU %ddB', config.PAS_threshold_1), sprintf('NYU %ddB', config.PAS_threshold_2), ...
    sprintf('NYU %ddB', config.PAS_threshold_3), 'USC (no thr)'}, 'Location', 'northwest', 'FontSize', 7, 'Box', 'off', 'Interpreter', 'none');
grid on;

% Save with tight layout
set(fig6, 'PaperPositionMode', 'auto');
if exist('exportgraphics', 'file')
    exportgraphics(fig6, fullfile(paths.output, 'Fig6_AngularSpread_BarChart.pdf'), 'ContentType', 'vector', 'BackgroundColor', 'white');
    exportgraphics(fig6, fullfile(paths.output, 'Fig6_AngularSpread_BarChart.png'), 'Resolution', 300, 'BackgroundColor', 'white');
else
    saveas(fig6, fullfile(paths.output, 'Fig6_AngularSpread_BarChart.png'));
    print(fig6, fullfile(paths.output, 'Fig6_AngularSpread_BarChart.pdf'), '-dpdf', '-r300');
end
saveas(fig6, fullfile(paths.output, 'Fig6_AngularSpread_BarChart.fig'));

% =========================================================================
% FIGURE 7: Angular Spread Box Plot
% =========================================================================
fig7 = figure('Units', 'inches', 'Position', [1 1 10 4.5], 'Name', 'Fig7: AS Box Plot');

boxplot_labels = {sprintf('NYU %ddB', config.PAS_threshold_1), ...
                  sprintf('NYU %ddB', config.PAS_threshold_2), ...
                  sprintf('NYU %ddB', config.PAS_threshold_3), ...
                  'USC'};

% ASA
subplot(1,2,1);
boxplot_data_ASA = [results.ASA_NYU_10dB, results.ASA_NYU_15dB, results.ASA_NYU_20dB, results.ASA_USC];
bp = boxplot(boxplot_data_ASA, 'Labels', boxplot_labels, 'Colors', 'k', 'Widths', 0.6);
set(bp, 'LineWidth', 1.2);
h = findobj(gca, 'Tag', 'Box');
colors_box_4 = {colors.USC, colors.NYU_20dB, colors.NYU_15dB, colors.NYU_10dB};
for j = 1:length(h)
    patch(get(h(j), 'XData'), get(h(j), 'YData'), colors_box_4{j}, 'FaceAlpha', 0.5);
end
ylabel('ASA ($^\circ$)', 'FontSize', 11, 'Interpreter', 'latex');
xlabel('Method', 'FontSize', 11, 'Interpreter', 'latex');
title('(a) ASA Distribution', 'FontSize', 12, 'Interpreter', 'latex');
grid on;
set(gca, 'FontSize', 9, 'XTickLabelRotation', 15);

% ASD
subplot(1,2,2);
boxplot_data_ASD = [results.ASD_NYU_10dB, results.ASD_NYU_15dB, results.ASD_NYU_20dB, results.ASD_USC];
bp = boxplot(boxplot_data_ASD, 'Labels', boxplot_labels, 'Colors', 'k', 'Widths', 0.6);
set(bp, 'LineWidth', 1.2);
h = findobj(gca, 'Tag', 'Box');
for j = 1:length(h)
    patch(get(h(j), 'XData'), get(h(j), 'YData'), colors_box_4{j}, 'FaceAlpha', 0.5);
end
ylabel('ASD ($^\circ$)', 'FontSize', 11, 'Interpreter', 'latex');
xlabel('Method', 'FontSize', 11, 'Interpreter', 'latex');
title('(b) ASD Distribution', 'FontSize', 12, 'Interpreter', 'latex');
grid on;
set(gca, 'FontSize', 9, 'XTickLabelRotation', 15);

sgtitle('Figure 7: Angular Spread Distribution (Box Plot)', 'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'latex');
saveas(fig7, fullfile(paths.output, 'Fig7_AngularSpread_BoxPlot.png'));
saveas(fig7, fullfile(paths.output, 'Fig7_AngularSpread_BoxPlot.fig'));
print(fig7, fullfile(paths.output, 'Fig7_AngularSpread_BoxPlot.pdf'), '-dpdf', '-r300');

% =========================================================================
% FIGURE 8: Scatter Plot (Correlation)
% IEEE double-column: 7.0" x 5.5" for 2x2 subplot
% =========================================================================
fig8 = figure('Units', 'inches', 'Position', [1 1 IEEE_DOUBLE_COL_WIDTH 5.5], 'Name', 'Fig8: Scatter Correlation');

% PL scatter
subplot(2,2,1);
scatter(results.PL_USC, results.PL_NYU, 40, colors.NYU_10dB, 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 0.5);
hold on;
max_val = max([results.PL_USC; results.PL_NYU]) * 1.05;
min_val = min([results.PL_USC; results.PL_NYU]) * 0.95;
plot([min_val max_val], [min_val max_val], 'k--', 'LineWidth', 1.2);
xlabel('USC Path Loss (dB)', 'FontSize', 10, 'Interpreter', 'latex');
ylabel('NYU Path Loss (dB)', 'FontSize', 10, 'Interpreter', 'latex');
title('(a) Path Loss', 'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'latex');
r_PL = corrcoef(results.PL_USC, results.PL_NYU);
text(0.05, 0.95, sprintf('$R = %.3f$', r_PL(1,2)), 'Units', 'normalized', ...
    'FontSize', 9, 'Interpreter', 'latex', 'VerticalAlignment', 'top');
grid on;
axis equal;
xlim([min_val max_val]);
ylim([min_val max_val]);
set(gca, 'FontSize', 9);

% DS scatter
subplot(2,2,2);
scatter(results.DS_USC, results.DS_NYU, 40, colors.NYU_10dB, 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 0.5);
hold on;
max_val = max([results.DS_USC; results.DS_NYU]) * 1.1;
plot([0 max_val], [0 max_val], 'k--', 'LineWidth', 1.2);
xlabel('USC Delay Spread (ns)', 'FontSize', 10, 'Interpreter', 'latex');
ylabel('NYU Delay Spread (ns)', 'FontSize', 10, 'Interpreter', 'latex');
title('(b) Delay Spread', 'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'latex');
r_DS = corrcoef(results.DS_USC, results.DS_NYU);
text(0.05, 0.95, sprintf('$R = %.3f$', r_DS(1,2)), 'Units', 'normalized', ...
    'FontSize', 9, 'Interpreter', 'latex', 'VerticalAlignment', 'top');
grid on;
axis equal;
xlim([0 max_val]);
ylim([0 max_val]);
set(gca, 'FontSize', 9);

% ASA scatter
subplot(2,2,3);
scatter(results.ASA_USC, results.ASA_NYU_10dB, 35, colors.NYU_10dB, 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 0.5, 'DisplayName', sprintf('NYU %ddB', config.PAS_threshold_1));
hold on;
scatter(results.ASA_USC, results.ASA_NYU_15dB, 35, colors.NYU_15dB, 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 0.5, 'DisplayName', sprintf('NYU %ddB', config.PAS_threshold_2));
scatter(results.ASA_USC, results.ASA_NYU_20dB, 35, colors.NYU_20dB, 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 0.5, 'DisplayName', sprintf('NYU %ddB', config.PAS_threshold_3));
max_val = max([results.ASA_USC; results.ASA_NYU_20dB]) * 1.1;
plot([0 max_val], [0 max_val], 'k--', 'LineWidth', 1.2, 'DisplayName', '$y=x$');
xlabel('USC ASA ($^\circ$)', 'FontSize', 10, 'Interpreter', 'latex');
ylabel('NYU ASA ($^\circ$)', 'FontSize', 10, 'Interpreter', 'latex');
title('(c) ASA', 'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'latex');
legend('Location', 'northwest', 'FontSize', 7, 'Box', 'off', 'Interpreter', 'latex');
grid on;
xlim([0 max_val]);
ylim([0 max_val]);
set(gca, 'FontSize', 9);

% ASD scatter
subplot(2,2,4);
scatter(results.ASD_USC, results.ASD_NYU_10dB, 35, colors.NYU_10dB, 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 0.5, 'DisplayName', sprintf('NYU %ddB', config.PAS_threshold_1));
hold on;
scatter(results.ASD_USC, results.ASD_NYU_15dB, 35, colors.NYU_15dB, 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 0.5, 'DisplayName', sprintf('NYU %ddB', config.PAS_threshold_2));
scatter(results.ASD_USC, results.ASD_NYU_20dB, 35, colors.NYU_20dB, 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 0.5, 'DisplayName', sprintf('NYU %ddB', config.PAS_threshold_3));
max_val = max([results.ASD_USC; results.ASD_NYU_20dB]) * 1.1;
plot([0 max_val], [0 max_val], 'k--', 'LineWidth', 1.2, 'DisplayName', '$y=x$');
xlabel('USC ASD ($^\circ$)', 'FontSize', 10, 'Interpreter', 'latex');
ylabel('NYU ASD ($^\circ$)', 'FontSize', 10, 'Interpreter', 'latex');
title('(d) ASD', 'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'latex');
legend('Location', 'northwest', 'FontSize', 7, 'Box', 'off', 'Interpreter', 'latex');
grid on;
xlim([0 max_val]);
ylim([0 max_val]);
set(gca, 'FontSize', 9);

% Save with tight layout
set(fig8, 'PaperPositionMode', 'auto');
if exist('exportgraphics', 'file')
    exportgraphics(fig8, fullfile(paths.output, 'Fig8_Scatter_Correlation.pdf'), 'ContentType', 'vector', 'BackgroundColor', 'white');
    exportgraphics(fig8, fullfile(paths.output, 'Fig8_Scatter_Correlation.png'), 'Resolution', 300, 'BackgroundColor', 'white');
else
    saveas(fig8, fullfile(paths.output, 'Fig8_Scatter_Correlation.png'));
    print(fig8, fullfile(paths.output, 'Fig8_Scatter_Correlation.pdf'), '-dpdf', '-r300');
end
saveas(fig8, fullfile(paths.output, 'Fig8_Scatter_Correlation.fig'));

% =========================================================================
% FIGURE 9: Bland-Altman Plot
% IEEE double-column: 7.0" x 5.5" for 2x2 subplot
% =========================================================================
fig9 = figure('Units', 'inches', 'Position', [1 1 IEEE_DOUBLE_COL_WIDTH 5.5], 'Name', 'Fig9: Bland-Altman');

% PL Bland-Altman
subplot(2,2,1);
mean_PL = (results.PL_NYU + results.PL_USC) / 2;
diff_PL = results.PL_NYU - results.PL_USC;
scatter(mean_PL, diff_PL, 40, colors.NYU_10dB, 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 0.5);
hold on;
yline(mean(diff_PL), 'k-', 'LineWidth', 1.2);
yline(mean(diff_PL) + 1.96*std(diff_PL), 'r--', 'LineWidth', 1.0);
yline(mean(diff_PL) - 1.96*std(diff_PL), 'r--', 'LineWidth', 1.0);
xlabel('Mean Path Loss (dB)', 'FontSize', 10, 'Interpreter', 'latex');
ylabel('$\Delta$PL (SUM$-$perDelayMax) [dB]', 'FontSize', 10, 'Interpreter', 'latex');
title(sprintf('(a) PL: $\\mu$=%.2f, $\\sigma$=%.2f dB', mean(diff_PL), std(diff_PL)), 'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'latex');
grid on;
set(gca, 'FontSize', 9);

% DS Bland-Altman
subplot(2,2,2);
mean_DS = (results.DS_NYU + results.DS_USC) / 2;
diff_DS = results.DS_NYU - results.DS_USC;
scatter(mean_DS, diff_DS, 40, colors.NYU_10dB, 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 0.5);
hold on;
yline(mean(diff_DS), 'k-', 'LineWidth', 1.2);
yline(mean(diff_DS) + 1.96*std(diff_DS), 'r--', 'LineWidth', 1.0);
yline(mean(diff_DS) - 1.96*std(diff_DS), 'r--', 'LineWidth', 1.0);
xlabel('Mean Delay Spread (ns)', 'FontSize', 10, 'Interpreter', 'latex');
ylabel('$\Delta$DS (SUM$-$perDelayMax) [ns]', 'FontSize', 10, 'Interpreter', 'latex');
title(sprintf('(b) DS: $\\mu$=%.2f, $\\sigma$=%.2f ns', mean(diff_DS), std(diff_DS)), 'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'latex');
grid on;
set(gca, 'FontSize', 9);

% ASA Bland-Altman (10dB threshold)
subplot(2,2,3);
mean_ASA = (results.ASA_NYU_10dB + results.ASA_USC) / 2;
diff_ASA = results.ASA_NYU_10dB - results.ASA_USC;
scatter(mean_ASA, diff_ASA, 40, colors.NYU_10dB, 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 0.5);
hold on;
yline(mean(diff_ASA), 'k-', 'LineWidth', 1.2);
yline(mean(diff_ASA) + 1.96*std(diff_ASA), 'r--', 'LineWidth', 1.0);
yline(mean(diff_ASA) - 1.96*std(diff_ASA), 'r--', 'LineWidth', 1.0);
xlabel('Mean ASA ($^\circ$)', 'FontSize', 10, 'Interpreter', 'latex');
ylabel(sprintf('$\\Delta$ASA (NYU %ddB$-$USC) [$^\\circ$]', config.PAS_threshold_1), 'FontSize', 10, 'Interpreter', 'latex');
title(sprintf('(c) ASA: $\\mu$=%.1f, $\\sigma$=%.1f$^\\circ$', mean(diff_ASA), std(diff_ASA)), 'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'latex');
grid on;
set(gca, 'FontSize', 9);

% ASD Bland-Altman (10dB threshold)
subplot(2,2,4);
mean_ASD = (results.ASD_NYU_10dB + results.ASD_USC) / 2;
diff_ASD = results.ASD_NYU_10dB - results.ASD_USC;
scatter(mean_ASD, diff_ASD, 40, colors.NYU_10dB, 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 0.5);
hold on;
yline(mean(diff_ASD), 'k-', 'LineWidth', 1.2);
yline(mean(diff_ASD) + 1.96*std(diff_ASD), 'r--', 'LineWidth', 1.0);
yline(mean(diff_ASD) - 1.96*std(diff_ASD), 'r--', 'LineWidth', 1.0);
xlabel('Mean ASD ($^\circ$)', 'FontSize', 10, 'Interpreter', 'latex');
ylabel(sprintf('$\\Delta$ASD (NYU %ddB$-$USC) [$^\\circ$]', config.PAS_threshold_1), 'FontSize', 10, 'Interpreter', 'latex');
title(sprintf('(d) ASD: $\\mu$=%.1f, $\\sigma$=%.1f$^\\circ$', mean(diff_ASD), std(diff_ASD)), 'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'latex');
grid on;
set(gca, 'FontSize', 9);

% Save with tight layout
set(fig9, 'PaperPositionMode', 'auto');
if exist('exportgraphics', 'file')
    exportgraphics(fig9, fullfile(paths.output, 'Fig9_BlandAltman.pdf'), 'ContentType', 'vector', 'BackgroundColor', 'white');
    exportgraphics(fig9, fullfile(paths.output, 'Fig9_BlandAltman.png'), 'Resolution', 300, 'BackgroundColor', 'white');
else
    saveas(fig9, fullfile(paths.output, 'Fig9_BlandAltman.png'));
    print(fig9, fullfile(paths.output, 'Fig9_BlandAltman.pdf'), '-dpdf', '-r300');
end
saveas(fig9, fullfile(paths.output, 'Fig9_BlandAltman.fig'));

%% SECTION 6: SAVE RESULTS
save(fullfile(paths.results, 'all_comparison_results.mat'), 'results', 'pas_store', 'config', 'params');

% =========================================================================
% Create masks for LOS/NLOS
% =========================================================================
los_mask = strcmp(results.Environment, 'LOS');
nlos_mask = ~los_mask;

% =========================================================================
% TABLE: Per-Location Results (All_Results sheet)
% =========================================================================
T_all = table(...
    results.TX_RX_ID, ...
    results.Environment, ...
    results.TX_Power_dBm, ...
    results.PL_NYU, ...
    results.PL_USC, ...
    results.PL_NYU - results.PL_USC, ...
    results.DS_NYU, ...
    results.DS_USC, ...
    results.DS_NYU - results.DS_USC, ...
    results.ASA_NYU_10dB, ...
    results.ASA_NYU_15dB, ...
    results.ASA_NYU_20dB, ...
    results.ASA_USC, ...
    results.ASA_NYU_10dB - results.ASA_USC, ...
    results.ASD_NYU_10dB, ...
    results.ASD_NYU_15dB, ...
    results.ASD_NYU_20dB, ...
    results.ASD_USC, ...
    results.ASD_NYU_10dB - results.ASD_USC, ...
    'VariableNames', {...
        'TX_RX_ID', 'Environment', 'TX_Power_dBm', ...
        'PL_NYU_SUM_dB', 'PL_USC_perDelayMax_dB', 'Delta_PL_dB', ...
        'DS_NYU_SUM_ns', 'DS_USC_perDelayMax_ns', 'Delta_DS_ns', ...
        'ASA_NYU_10dB', 'ASA_NYU_15dB', 'ASA_NYU_20dB', 'ASA_USC', 'Delta_ASA_10dB', ...
        'ASD_NYU_10dB', 'ASD_NYU_15dB', 'ASD_NYU_20dB', 'ASD_USC', 'Delta_ASD_10dB'});

% =========================================================================
% LOS Summary Statistics
% =========================================================================
metrics = {'PL_NYU', 'PL_USC', 'DS_NYU', 'DS_USC', 'ASA_NYU_10dB', 'ASA_NYU_20dB', 'ASA_USC', 'ASD_NYU_10dB', 'ASD_USC'};
stats = {'Mean', 'Std', 'Min', 'Max'};
T_los = table();
for i = 1:length(metrics)
    data = results.(metrics{i})(los_mask);
    T_los.(metrics{i}) = [mean(data); std(data); min(data); max(data)];
end
T_los.Properties.RowNames = stats;

% =========================================================================
% NLOS Summary Statistics
% =========================================================================
T_nlos = table();
for i = 1:length(metrics)
    data = results.(metrics{i})(nlos_mask);
    T_nlos.(metrics{i}) = [mean(data); std(data); min(data); max(data)];
end
T_nlos.Properties.RowNames = stats;

% =========================================================================
% Overall Summary Statistics
% =========================================================================
T_overall = table();
for i = 1:length(metrics)
    data = results.(metrics{i});
    T_overall.(metrics{i}) = [mean(data); std(data); min(data); max(data)];
end
T_overall.Properties.RowNames = stats;

% =========================================================================
% Method Comparison Summary (Differences)
% =========================================================================
T_comparison = table();
T_comparison.Metric = {'Delta_PL_LOS'; 'Delta_PL_NLOS'; 'Delta_PL_ALL'; ...
    'Delta_DS_LOS'; 'Delta_DS_NLOS'; 'Delta_DS_ALL'; ...
    'Delta_ASA_10dB_LOS'; 'Delta_ASA_10dB_NLOS'; 'Delta_ASA_10dB_ALL'; ...
    'Delta_ASD_10dB_LOS'; 'Delta_ASD_10dB_NLOS'; 'Delta_ASD_10dB_ALL'};
T_comparison.Mean = [...
    mean(results.PL_NYU(los_mask) - results.PL_USC(los_mask)); ...
    mean(results.PL_NYU(nlos_mask) - results.PL_USC(nlos_mask)); ...
    mean(results.PL_NYU - results.PL_USC); ...
    mean(results.DS_NYU(los_mask) - results.DS_USC(los_mask)); ...
    mean(results.DS_NYU(nlos_mask) - results.DS_USC(nlos_mask)); ...
    mean(results.DS_NYU - results.DS_USC); ...
    mean(results.ASA_NYU_10dB(los_mask) - results.ASA_USC(los_mask)); ...
    mean(results.ASA_NYU_10dB(nlos_mask) - results.ASA_USC(nlos_mask)); ...
    mean(results.ASA_NYU_10dB - results.ASA_USC); ...
    mean(results.ASD_NYU_10dB(los_mask) - results.ASD_USC(los_mask)); ...
    mean(results.ASD_NYU_10dB(nlos_mask) - results.ASD_USC(nlos_mask)); ...
    mean(results.ASD_NYU_10dB - results.ASD_USC)];
T_comparison.Std = [...
    std(results.PL_NYU(los_mask) - results.PL_USC(los_mask)); ...
    std(results.PL_NYU(nlos_mask) - results.PL_USC(nlos_mask)); ...
    std(results.PL_NYU - results.PL_USC); ...
    std(results.DS_NYU(los_mask) - results.DS_USC(los_mask)); ...
    std(results.DS_NYU(nlos_mask) - results.DS_USC(nlos_mask)); ...
    std(results.DS_NYU - results.DS_USC); ...
    std(results.ASA_NYU_10dB(los_mask) - results.ASA_USC(los_mask)); ...
    std(results.ASA_NYU_10dB(nlos_mask) - results.ASA_USC(nlos_mask)); ...
    std(results.ASA_NYU_10dB - results.ASA_USC); ...
    std(results.ASD_NYU_10dB(los_mask) - results.ASD_USC(los_mask)); ...
    std(results.ASD_NYU_10dB(nlos_mask) - results.ASD_USC(nlos_mask)); ...
    std(results.ASD_NYU_10dB - results.ASD_USC)];

% =========================================================================
% EXPORT CSV
% =========================================================================
csv_filepath = fullfile(paths.results, 'NYU142GHz_Method_Comparison_Results.csv');
writetable(T_all, csv_filepath);
fprintf('\n  CSV results exported to: %s\n', csv_filepath);

% =========================================================================
% EXPORT EXCEL with Multiple Sheets
% =========================================================================
xlsx_filepath = fullfile(paths.results, 'NYU142GHz_Method_Comparison_Results.xlsx');
if exist(xlsx_filepath, 'file'), delete(xlsx_filepath); end
writetable(T_all, xlsx_filepath, 'Sheet', 'All_Results');
writetable(T_los, xlsx_filepath, 'Sheet', 'LOS_Summary', 'WriteRowNames', true);
writetable(T_nlos, xlsx_filepath, 'Sheet', 'NLOS_Summary', 'WriteRowNames', true);
writetable(T_overall, xlsx_filepath, 'Sheet', 'Overall_Summary', 'WriteRowNames', true);
writetable(T_comparison, xlsx_filepath, 'Sheet', 'Method_Comparison');
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
%  LOCAL FUNCTIONS
%  =========================================================================

function [TRpdpSet_thr, noise_floor_dB] = apply_NYU_PDP_threshold(TRpdpSet, config)
    % Apply NYU's PDP threshold: max(25dB below peak, 5dB above noise)
    %
    % PER-DIRECTIONAL-PDP THRESHOLDING (NYU's original method):
    %   Each directional PDP is thresholded using:
    %     threshold_i = max(peak_i - 25 dB, noise_i + 5 dB)
    %   where peak_i and noise_i are computed for each directional PDP.
    %
    % NOISE FLOOR ESTIMATION (NYU's original method):
    %   From NYUprocessUSC145.m line 127:
    %   - NYU uses the average power of the last ~250 ns of the PDP tail
    %   - For dilated PDPs (20 samples/ns): last 5000 samples = 250 ns
    %   - The tail region represents pure thermal noise (no multipath)
    %   - Noise floor is computed in LINEAR domain, then converted to dB
    %
    % Input:
    %   TRpdpSet - Cell array with PDP in column 1 (ALREADY IN dB for NYU data)
    %   config - Configuration struct with:
    %            .thres_below_pk (25 dB)
    %            .thres_above_noise (5 dB)
    %            .multipath_low_bound (-200 dB)
    %
    % Output:
    %   TRpdpSet_thr - Thresholded cell array (PDP in dB)
    %   noise_floor_dB - Estimated representative noise floor in dB

    nPDPs = size(TRpdpSet, 1);
    TRpdpSet_thr = TRpdpSet;

    % Parameters for noise floor estimation (matching NYU's original code)
    % NYU uses last 5000 samples for dilated PDP (= 250 ns at 20 samples/ns)
    % For undilated PDP, they use last 250 samples (= 250 ns at 1 sample/ns)
    dilation_factor = 20;           % 20 samples per ns (NYU standard)
    noise_tail_ns = 250;            % Use last 250 ns for noise estimation
    noise_tail_samples = noise_tail_ns * dilation_factor;  % 5000 samples

    % Storage for noise floors
    noise_floors = zeros(nPDPs, 1);

    % Process each directional PDP independently
    for i = 1:nPDPs
        pdp_dB = TRpdpSet{i, 1};
        if ~isempty(pdp_dB) && isnumeric(pdp_dB)
            pdp_dB = real(pdp_dB(:));
            pdp_len = length(pdp_dB);

            % =========================================================
            % STEP 1: Estimate local noise floor from last 250 ns
            % =========================================================
            % NYU's method: average power of tail samples in LINEAR domain
            % Reference: NYUprocessUSC145.m line 127
            %   thres_noisePlus5 = pow2db(mean(allPDPsLin(end-250:end,:))) + 5
            if pdp_len > noise_tail_samples
                tail_samples_dB = pdp_dB(end-noise_tail_samples+1:end);
            else
                % If PDP is shorter, use last 10% of samples
                tail_start = max(1, floor(0.9 * pdp_len));
                tail_samples_dB = pdp_dB(tail_start:end);
            end

            % Convert to linear, compute mean, convert back to dB
            % This matches NYU's: pow2db(mean(allPDPsLin(end-250:end,:)))
            tail_samples_lin = 10.^(tail_samples_dB / 10);
            local_noise = 10 * log10(mean(tail_samples_lin));
            noise_floors(i) = local_noise;

            % =========================================================
            % STEP 2: Find peak of THIS directional PDP
            % =========================================================
            local_peak_dB = max(pdp_dB);

            % =========================================================
            % STEP 3: Compute threshold for THIS PDP
            % =========================================================
            % Threshold 1: 25 dB below THIS PDP's peak
            thres_below_peak = local_peak_dB - config.thres_below_pk;

            % Threshold 2: 5 dB above THIS PDP's noise floor
            thres_above_noise = local_noise + config.thres_above_noise;

            % Final threshold: max of both (more conservative)
            threshold_dB = max(thres_below_peak, thres_above_noise);

            % =========================================================
            % STEP 4: Apply threshold
            % =========================================================
            pdp_dB(pdp_dB < threshold_dB) = config.multipath_low_bound;
            TRpdpSet_thr{i, 1} = pdp_dB;
        end
    end

    % Return median noise floor as representative value
    valid_noise = noise_floors(noise_floors ~= 0 & ~isnan(noise_floors));
    if ~isempty(valid_noise)
        noise_floor_dB = median(valid_noise);
    else
        noise_floor_dB = -200;
    end
end

function [PAS_angles, PAS_powers, PAS_set] = generate_PAS(TRpdpSet, ref_col, alt_col, pdp_floor_dB, pas_init_dB)
    % Generate Power Angular Spectrum (PAS)
    % Based on NYU's PASgenerator.m - outputs FULL 360° spectrum
    %
    % Input:
    %   TRpdpSet - Cell array with thresholded PDP (ALREADY IN dB) in column 1
    %   ref_col - Column index for reference angle (e.g., 8 for AOA)
    %   alt_col - Column index for alternative angle (e.g., 6 for AOD)
    %   pdp_floor_dB - PDP threshold floor (e.g., -200 dB) for filtering valid
    %                   PDP samples. Must match multipath_low_bound used in
    %                   apply_NYU_PDP_threshold (thresholded samples = this value).
    %   pas_init_dB  - (Optional) Initialization value for unmeasured angles in
    %                   the 360° output. Default = pdp_floor_dB. Use -200 to
    %                   distinguish unmeasured angles from thresholded-out ones.
    %
    % Output:
    %   PAS_angles - Full 360 degrees (1:360)'
    %   PAS_powers - Power at each angle in dB (pas_init_dB for unmeasured angles)
    %   PAS_set - Cell array for detailed processing (sparse, measured angles only)
    %
    % NOTE: This follows NYU's exact method from PASgenerator.m:
    %       - Output is ALWAYS 360 elements (1 degree resolution)
    %       - Powers are in dB (not linear)
    %       - Unmeasured angles get pas_init_dB value

    if nargin < 5 || isempty(pas_init_dB)
        pas_init_dB = pdp_floor_dB;  % Default: same as PDP floor
    end

    nPDPs = size(TRpdpSet, 1);

    % Collect all angle-power pairs (angles in degrees, powers in dB)
    all_angles = [];
    all_powers_dB = [];

    for i = 1:nPDPs
        pdp_dB = TRpdpSet{i, 1};
        if isempty(pdp_dB) || ~isnumeric(pdp_dB)
            continue;
        end

        % Get angle from reference column
        angle = TRpdpSet{i, ref_col};
        if isempty(angle) || ~isnumeric(angle)
            continue;
        end

        % PDP is already in dB - sum power (convert to linear, sum, back to dB)
        % Use pdp_floor_dB to filter out thresholded samples (set to -200 by threshold step)
        pdp_dB = real(pdp_dB);  % Ensure real
        valid_mask = pdp_dB > pdp_floor_dB;
        if any(valid_mask)
            power_lin = sum(10.^(pdp_dB(valid_mask) / 10));
            power_dB = 10*log10(power_lin + eps);
            all_angles = [all_angles; angle];
            all_powers_dB = [all_powers_dB; power_dB];
        end
    end

    % Aggregate by unique measured angles
    if ~isempty(all_angles)
        unique_angles = unique(all_angles);
        unique_powers_dB = zeros(size(unique_angles));
        for i = 1:length(unique_angles)
            mask = all_angles == unique_angles(i);
            % Sum powers at same angle (in linear, then back to dB)
            power_lin = sum(10.^(all_powers_dB(mask) / 10));
            unique_powers_dB(i) = 10*log10(power_lin + eps);
        end
    else
        unique_angles = [];
        unique_powers_dB = [];
    end

    % === NYU's key step: Create FULL 360° spectrum ===
    % From PASgenerator.m lines 42-46:
    %   PAS_angles=(1:360)';
    %   PAS_powers(idx)=PAS(:,1);
    %   PAS_powers(~idx)=multipath_low_bound;
    PAS_angles = (1:360)';
    PAS_powers = ones(360, 1) * pas_init_dB;  % Initialize unmeasured angles to pas_init_dB

    % Replace 0 with 360 (NYU convention)
    unique_angles(unique_angles == 0) = 360;

    % Fill in measured angles
    for i = 1:length(unique_angles)
        ang_idx = round(unique_angles(i));
        if ang_idx >= 1 && ang_idx <= 360
            % If multiple measurements at same angle, take max (or could sum)
            PAS_powers(ang_idx) = max(PAS_powers(ang_idx), unique_powers_dB(i));
        end
    end

    % Create PAS_set for compatibility (sparse version with only measured angles)
    if ~isempty(unique_angles)
        PAS_set = cell(length(unique_angles), 3);
        for i = 1:length(unique_angles)
            PAS_set{i, 1} = unique_powers_dB(i);  % Power in dB
            PAS_set{i, 2} = 10^(unique_powers_dB(i)/10);  % Power in linear
            PAS_set{i, 3} = unique_angles(i);  % Angle
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

    % Determine PDP length from first valid entry
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

    % Initialize accumulator
    OmniPDP_lin = zeros(pdp_len, 1);

    % Sum all PDPs (convert from dB to linear first)
    % Note: After thresholding, floor values are at multipath_low_bound (-200 dB)
    % We set these to zero to prevent noise accumulation
    floor_threshold = -199;  % Slightly above -200 dB floor

    for i = 1:nPDPs
        pdp_dB = TRpdpSet{i, 1};
        if ~isempty(pdp_dB) && isnumeric(pdp_dB) && length(pdp_dB) == pdp_len
            pdp_dB = real(pdp_dB);  % Ensure real
            % Only sum valid (non-floor) values
            pdp_lin = 10.^(pdp_dB / 10);
            pdp_lin(pdp_dB <= floor_threshold) = 0;  % Floor values become zero
            OmniPDP_lin = OmniPDP_lin + pdp_lin;
        end
    end

    OmniPDP = OmniPDP_lin;
    delays_ns = (0:pdp_len-1)' / params.dilation_factor;
end

function [OmniPDP, delays_ns] = compute_omni_USC(TRpdpSet, params)
    % Compute Omni PDP using USC's perDelayMax method
    % Take maximum power across all directions at each delay bin
    % Input PDP is ALREADY IN dB

    nPDPs = size(TRpdpSet, 1);

    % Determine PDP length
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

    % Initialize with very small values
    OmniPDP_lin = zeros(pdp_len, 1);

    % Take max across all PDPs at each delay
    % Note: After thresholding, floor values are at multipath_low_bound (-200 dB)
    floor_threshold = -199;  % Slightly above -200 dB floor

    for i = 1:nPDPs
        pdp_dB = TRpdpSet{i, 1};
        if ~isempty(pdp_dB) && isnumeric(pdp_dB) && length(pdp_dB) == pdp_len
            pdp_dB = real(pdp_dB);  % Ensure real
            pdp_lin = 10.^(pdp_dB / 10);
            pdp_lin(pdp_dB <= floor_threshold) = 0;  % Floor values become zero
            OmniPDP_lin = max(OmniPDP_lin, pdp_lin);
        end
    end

    OmniPDP = OmniPDP_lin;
    delays_ns = (0:pdp_len-1)' / params.dilation_factor;
end

function rmsDS = compute_RMS_DS(delays_ns, PDP_lin, tgate_ns)
    % Compute RMS Delay Spread (with optional delay gating)
    % Based on NYU's computeDSonMPC.m
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

    % Apply delay gate (NYU pipeline previously had no time-domain gate;
    % this matches the USC-side implementation for cross-processing parity).
    gate_mask = (delays_ns(:) <= tgate_ns);
    PDP_lin   = PDP_lin(:) .* gate_mask;
    delays_ns = delays_ns(:);

    if sum(PDP_lin) <= 0
        rmsDS = 0;
        return;
    end

    weights = PDP_lin / sum(PDP_lin);
    mean_delay    = sum(delays_ns    .* weights);
    second_moment = sum((delays_ns.^2) .* weights);
    variance = second_moment - mean_delay^2;
    if variance < 0
        variance = 0;  % Numerical protection
    end
    rmsDS = sqrt(variance);
end

function [AS, selected_angles, expanded_powers] = compute_AS_NYU(angles, powers_dB, pas_threshold_dB, multipath_low_bound, antenna_pattern)
    % =========================================================================
    % NYU Angular Spread Method with Lobe Detection and Boundary Expansion
    %
    % This function implements NYU's AS calculation method following:
    %   - lobeShaperCounterD.m: Detect spatial lobes based on HPBW gaps
    %   - boundaryMPCsD.m: Expand lobe boundaries using antenna pattern
    %   - circ_std.m: Compute AS using 3GPP formula sqrt(-2*ln(R))
    %
    % Key steps:
    %   1. Apply PAS threshold (e.g., 10/15/20 dB below peak)
    %   2. Detect contiguous lobes (gap > HPBW = new lobe)
    %   3. For each lobe boundary, find where antenna pattern = threshold
    %   4. Add boundary MPCs at expanded angles with power = threshold
    %   5. Compute AS using 3GPP formula on original + boundary MPCs
    %
    % Reference: boundaryMPCsD.m lines 14-15:
    %   [~, Ang_pos] = min(abs(abs(ref_power1 - SLT) - abs(azi)));
    %   mpc1_Ang = starts(iLobe) - abs(aziPatternFile(Ang_pos, 1));
    %
    % Input:
    %   angles - Vector of angles (1:360 degrees, full spectrum)
    %   powers_dB - Power at each angle IN dB (floor value for unmeasured)
    %   pas_threshold_dB - Threshold below peak (e.g., 10, 15, 20 dB)
    %   multipath_low_bound - Floor value in dB (default: -200)
    %   antenna_pattern - Nx2 matrix [angle_offset, gain_dB] for lobe expansion
    %
    % Output:
    %   AS - Angular spread in degrees
    %   selected_angles - Angles that passed threshold (before expansion)
    %   expanded_powers - Expanded power array (after antenna pattern application)
    % =========================================================================

    HPBW = 8;  % Half-power beamwidth in degrees (NYU 142GHz system)

    if nargin < 5
        antenna_pattern = [];
    end

    expanded_powers = powers_dB;
    selected_angles = [];

    % Powers are already in dB (from generate_PAS)
    peak_dB = max(powers_dB);

    if peak_dB <= multipath_low_bound + 1
        % No valid signal
        AS = 0;
        return;
    end

    threshold_dB = peak_dB - pas_threshold_dB;

    % Apply threshold
    mask = powers_dB >= threshold_dB;

    if ~any(mask)
        % If no samples pass, use only the peak
        [~, idx] = max(powers_dB);
        mask(idx) = true;
    end

    selected_angles = angles(mask);
    selected_powers_dB = powers_dB(mask);

    % Sort by angle
    [selected_angles, sort_idx] = sort(selected_angles, 'ascend');
    selected_powers_dB = selected_powers_dB(sort_idx);

    Nsel = length(selected_angles);

    if Nsel == 0
        AS = 0;
        return;
    end

    % =========================================================================
    % Step 1: Lobe Detection (based on lobeShaperCounterD.m)
    % A new lobe starts when the angular gap exceeds HPBW
    % =========================================================================
    if Nsel == 1
        % Single angle - one lobe
        lobe_starts = selected_angles(1);
        lobe_ends = selected_angles(1);
        lobe_start_powers_dB = selected_powers_dB(1);
        lobe_end_powers_dB = selected_powers_dB(1);
        nLobes = 1;
    else
        % Detect lobe boundaries
        lobe_starts = [];
        lobe_ends = [];
        lobe_start_powers_dB = [];
        lobe_end_powers_dB = [];

        lobe_starts(1) = selected_angles(1);
        lobe_start_powers_dB(1) = selected_powers_dB(1);

        for i = 2:Nsel
            % Angular difference (handle wraparound)
            diff_ang = selected_angles(i) - selected_angles(i-1);
            if diff_ang < 0
                diff_ang = diff_ang + 360;
            end

            if diff_ang > HPBW
                % Gap detected - end previous lobe, start new lobe
                lobe_ends(end+1) = selected_angles(i-1);
                lobe_end_powers_dB(end+1) = selected_powers_dB(i-1);
                lobe_starts(end+1) = selected_angles(i);
                lobe_start_powers_dB(end+1) = selected_powers_dB(i);
            end
        end

        % Close the last lobe
        lobe_ends(end+1) = selected_angles(end);
        lobe_end_powers_dB(end+1) = selected_powers_dB(end);

        nLobes = length(lobe_starts);
    end

    % =========================================================================
    % Step 2: Boundary Expansion (based on boundaryMPCsD.m)
    % For each lobe boundary, find the angle offset where antenna pattern
    % equals the threshold level, then add boundary MPCs
    % =========================================================================
    boundary_angles = [];
    boundary_powers_dB = [];

    if ~isempty(antenna_pattern) && size(antenna_pattern, 1) > 1
        % Normalize antenna pattern (peak at 0 dB)
        pattern_angles = antenna_pattern(:, 1);  % Offset angles from boresight
        pattern_gain = antenna_pattern(:, 2) - max(antenna_pattern(:, 2));  % Normalized to 0 dB peak

        for iLobe = 1:nLobes
            % --- Expand start boundary (left side) ---
            % NYU's formula: [~, Ang_pos] = min(abs(abs(ref_power1 - SLT) - abs(azi)));
            % Here ref_power1 is the power at lobe boundary, SLT is the threshold
            % The difference (ref_power1 - SLT) = how far above threshold the boundary is
            % We find where antenna pattern gain matches this difference
            %
            % Example: if boundary power = peak and threshold = peak - 10dB,
            % then ref_power1 - SLT = 10 dB, so we look for where |pattern_gain| ≈ 10 dB
            % This gives the angular offset from boresight where pattern drops by 10 dB
            power_above_threshold_start = lobe_start_powers_dB(iLobe) - threshold_dB;
            [~, Ang_pos] = min(abs(abs(power_above_threshold_start) - abs(pattern_gain)));
            boundary_offset_start = abs(pattern_angles(Ang_pos));

            % Boundary MPC at expanded angle with power = threshold
            boundary_angle_start = lobe_starts(iLobe) - boundary_offset_start;
            if boundary_angle_start < 0
                boundary_angle_start = boundary_angle_start + 360;
            end
            boundary_angles(end+1) = boundary_angle_start;
            boundary_powers_dB(end+1) = threshold_dB;

            % --- Expand end boundary (right side) ---
            power_above_threshold_end = lobe_end_powers_dB(iLobe) - threshold_dB;
            [~, Ang_pos] = min(abs(abs(power_above_threshold_end) - abs(pattern_gain)));
            boundary_offset_end = abs(pattern_angles(Ang_pos));

            boundary_angle_end = lobe_ends(iLobe) + boundary_offset_end;
            if boundary_angle_end >= 360
                boundary_angle_end = boundary_angle_end - 360;
            end
            boundary_angles(end+1) = boundary_angle_end;
            boundary_powers_dB(end+1) = threshold_dB;
        end
    end

    % =========================================================================
    % Step 3: Combine original MPCs + boundary MPCs (based on SecondaryStats_circD.m)
    % MPC_AOD_e = [MPC_AOD; boundary_angles];
    % MPCpowers_e = [MPCpowers; boundary_powers];
    % =========================================================================
    all_angles = [selected_angles(:); boundary_angles(:)];
    all_powers_dB = [selected_powers_dB(:); boundary_powers_dB(:)];

    % Convert to linear weights (as in SecondaryStats_circD.m: MPCpowersW = db2pow(MPCpowers_e))
    all_powers_lin = 10.^(all_powers_dB / 10);
    expanded_powers = all_powers_lin;

    % Normalize weights
    all_powers_lin = all_powers_lin / sum(all_powers_lin);

    % =========================================================================
    % Step 4: Compute AS using 3GPP formula (circ_std.m)
    % s0 = sqrt(-2*log(r)) where r = |sum(w * exp(j*theta))|
    % =========================================================================
    AS = compute_AS_3GPP(all_angles, all_powers_lin);
end

function AS = compute_AS_USC(angles, powers_dB, multipath_low_bound)
    % Compute Angular Spread using USC method
    % No PAS threshold - use all angles above floor
    %
    % Input:
    %   angles - Full 360° vector
    %   powers_dB - Powers in dB (floor value for unmeasured)
    %   multipath_low_bound - Floor value in dB

    if nargin < 3
        multipath_low_bound = -200;
    end

    % Filter out floor values (only use measured angles)
    valid_mask = powers_dB > multipath_low_bound + 1;

    if ~any(valid_mask)
        AS = 0;
        return;
    end

    valid_angles = angles(valid_mask);
    valid_powers_dB = powers_dB(valid_mask);

    % Convert to linear for AS computation (like NYU's db2pow)
    valid_powers_lin = 10.^(valid_powers_dB / 10);

    % Use all valid angles
    AS = compute_AS_3GPP(valid_angles, valid_powers_lin);
end

function AS = compute_AS_3GPP(angles, powers_lin)
    % Compute Angular Spread using 3GPP formula
    % AS = sqrt(-2 * ln(R)) where R = |sum(w * exp(j*theta))|
    % From circ_std.m line 54: s0 = sqrt(-2*log(r))
    %
    % Input: powers_lin - powers in LINEAR scale (already converted from dB)

    if isempty(powers_lin) || sum(powers_lin) <= 0
        AS = 0;
        return;
    end

    % Normalize weights (as in SecondaryStats_circD.m: MPCpowersW=MPCpowersW./sum(MPCpowersW))
    weights = powers_lin(:) / sum(powers_lin(:));
    angles_rad = deg2rad(angles(:));

    % Mean resultant length (as in circ_r.m: r = abs(sum(w.*exp(1i*alpha)))/sum(w))
    R = abs(sum(weights .* exp(1j * angles_rad)));

    % Handle edge cases
    % Note: NYU's circ_std.m does NOT check for R >= 1, it just computes sqrt(-2*log(r))
    % For R >= 1 (due to floating point), clamp to slightly below 1 to avoid complex result
    if R >= 1
        R = 1 - eps;  % Clamp to just below 1 (gives very small AS, not zero)
    end
    if R <= 0
        R = eps;  % Avoid log(0)
    end

    % 3GPP circular standard deviation (circ_std.m line 54: s0 = sqrt(-2*log(r)))
    AS_rad = sqrt(-2 * log(R));
    AS = rad2deg(AS_rad);
end

function TX_power_table = load_TX_power_table(csv_path)
    % Load TX power lookup table from CSV file
    % Returns a table with TX_ID, RX_ID, and TX_Power columns
    %
    % The CSV file has TX power values that vary by TX-RX pair

    try
        % Read CSV file
        opts = detectImportOptions(csv_path);
        data = readtable(csv_path, opts);

        % Extract unique TX-RX pairs with their TX power
        % Columns: TX_ID (4), RX_ID (5), TX_Power (38)
        TX_IDs = data.TX_ID;
        RX_IDs = data.RX_ID;
        TX_Powers = data.TX_Power;
        TR_seps = data.TX_RX_Separation_Distance;  % T-R separation in meters (for dynamic DS gate)

        % Get unique combinations
        [unique_pairs, idx] = unique([TX_IDs, RX_IDs], 'rows');
        unique_TX_Power = TX_Powers(idx);
        unique_TR_sep = TR_seps(idx);

        % Create lookup table (now includes TR_sep_m for dynamic DS gate)
        TX_power_table = table(unique_pairs(:,1), unique_pairs(:,2), unique_TX_Power, unique_TR_sep, ...
            'VariableNames', {'TX_ID', 'RX_ID', 'TX_Power', 'TR_sep_m'});

        fprintf('Loaded TX power table: %d unique TX-RX pairs\n', height(TX_power_table));

    catch ME
        warning('Could not load TX power table from CSV: %s', ME.message);
        warning('Using default TX power of -3.5 dBm for all locations');

        % Create default table
        TX_power_table = table([1], [1], [-3.5], [30.0], ...
            'VariableNames', {'TX_ID', 'RX_ID', 'TX_Power', 'TR_sep_m'});
    end
end

function TX_Power = get_TX_power(TX_power_table, TX_ID, RX_ID)
    % Look up TX power for a specific TX-RX pair
    %
    % Input:
    %   TX_power_table - Table with TX_ID, RX_ID, TX_Power columns
    %   TX_ID - Transmitter ID
    %   RX_ID - Receiver ID
    %
    % Output:
    %   TX_Power - TX power in dBm for this pair

    % Find matching row
    mask = (TX_power_table.TX_ID == TX_ID) & (TX_power_table.RX_ID == RX_ID);

    if any(mask)
        TX_Power = TX_power_table.TX_Power(mask);
        TX_Power = TX_Power(1);  % Take first if multiple matches
    else
        % If no match found, use default or nearest TX
        tx_mask = TX_power_table.TX_ID == TX_ID;
        if any(tx_mask)
            % Use average TX power for this TX
            TX_Power = mean(TX_power_table.TX_Power(tx_mask));
            warning('TX-RX pair T%d-R%d not found, using TX%d average: %.2f dBm', TX_ID, RX_ID, TX_ID, TX_Power);
        else
            % Use global default
            TX_Power = -3.5;
            warning('TX-RX pair T%d-R%d not found, using default: %.2f dBm', TX_ID, RX_ID, TX_Power);
        end
    end
end

function pattern = load_antenna_pattern(filepath)
    % Load antenna pattern from NYU's .DAT file
    %
    % Input:
    %   filepath - Path to antenna pattern file (HPLANE or EPLANE)
    %
    % Output:
    %   pattern - Nx2 matrix [angle_deg, gain_dB]
    %
    % File format: Each line contains "angle  gain" separated by whitespace

    try
        pattern = load(filepath);
        % Ensure it's sorted by angle
        pattern = sortrows(pattern, 1);
    catch ME
        warning('Could not load antenna pattern from %s: %s', filepath, ME.message);
        % Return a flat pattern (0 dB for all angles)
        pattern = [(-90:90)', zeros(181, 1)];
    end
end

function interp_powers = interpolate_PAS_NYU(PAS_angles, PAS_powers, multipath_low_bound)
    % Interpolate PAS to fill gaps between measurement angles
    % Based on NYU's angularSpread.m lines 14-28
    %
    % This function performs linear interpolation between adjacent measured
    % angles to create a continuous 1-360 degree PAS.
    %
    % Input:
    %   PAS_angles - Vector of measured angles (sparse, e.g., [0, 8, 16, ...])
    %   PAS_powers - Power at each measured angle (linear scale)
    %   multipath_low_bound - Floor value in dB for unmeasured angles
    %
    % Output:
    %   interp_powers - 360x1 vector of interpolated powers (linear scale)

    % Initialize full 360-degree power array with floor value
    Angles = (1:360)';
    Powers_dB = multipath_low_bound * ones(size(Angles));

    % Convert input powers to dB
    PAS_powers_dB = 10*log10(PAS_powers + eps);

    % Handle wrap-around: if first angle is not 0/360 and last is not 359/360
    if ~isempty(PAS_angles) && length(PAS_angles) > 1
        % Sort by angle
        [PAS_angles, sort_idx] = sort(PAS_angles);
        PAS_powers_dB = PAS_powers_dB(sort_idx);

        % Wrap angles to 1-360 range (replace 0 with 360)
        PAS_angles(PAS_angles == 0) = 360;

        % Fill in the wrap-around gap (from last angle back to first angle)
        if PAS_angles(1) ~= 1 && PAS_angles(end) ~= 360
            % Interpolate from last angle through 360/1 to first angle
            gap_length = 360 - PAS_angles(end) + PAS_angles(1);
            fill_powers = linspace(PAS_powers_dB(end), PAS_powers_dB(1), gap_length + 1);

            % Fill angles from last measurement to 360
            if PAS_angles(end) < 360
                n_end = 360 - PAS_angles(end);
                Powers_dB(PAS_angles(end):360) = fill_powers(1:n_end+1);
            end

            % Fill angles from 1 to first measurement
            if PAS_angles(1) > 1
                n_start = PAS_angles(1) - 1;
                Powers_dB(1:PAS_angles(1)) = fill_powers(end-n_start:end);
            end
        end

        % Interpolate between consecutive measured angles
        for iPAS = 1:length(PAS_angles)-1
            ang1 = PAS_angles(iPAS);
            ang2 = PAS_angles(iPAS + 1);

            if ang2 - ang1 > 1
                % Interpolate between these angles
                fill_vals = linspace(PAS_powers_dB(iPAS), PAS_powers_dB(iPAS+1), ang2 - ang1 + 1);
                Powers_dB(ang1:ang2) = fill_vals;
            else
                % Adjacent angles
                Powers_dB(ang1) = PAS_powers_dB(iPAS);
            end
        end

        % Set the last measured angle
        Powers_dB(PAS_angles(end)) = PAS_powers_dB(end);
    elseif length(PAS_angles) == 1
        % Single angle - set only that angle
        ang = PAS_angles(1);
        if ang == 0
            ang = 360;
        end
        Powers_dB(ang) = PAS_powers_dB(1);
    end

    % Convert back to linear
    interp_powers = 10.^(Powers_dB / 10);
end

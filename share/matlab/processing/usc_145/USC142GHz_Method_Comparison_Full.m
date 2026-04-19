%% ========================================================================
%  USC 145GHz Data: Full Method Comparison (NYU vs USC)
%  ========================================================================
%
%  PURPOSE: Unified script comparing NYU and USC processing methods on
%           USC's THz microcellular data for:
%           - Path Loss (PL)
%           - Delay Spread (DS)
%           - Angular Spread (ASA, ASD)
%
%  =========================================================================
%  PROCESSING METHOD
%  =========================================================================
%  PDP Processing (USC ground truth from Parameter_comp_THz_fullelev.mlx):
%    1. Load H matrix (frequency domain channel)
%    2. Apply Hann windowing with normalization:
%       wf = hann(Nf+1,'Periodic'); wf = wf(1:end-1);
%       wf = sqrt(mean(abs(wf).^2))^(-1)*wf;
%    3. Compute CIR via IFFT: h_delay = ifft(H.*wf_rep, [], 1)
%    4. Compute PDP: PDP_dir = |h_delay|^2
%    5. Noise threshold: 25th percentile + 5.41 dB + 12 dB margin
%    6. Omni PDP: Sum RxEl → Max RxAz → Sum TxEl → Max TxAz
%    7. Apply -1.95 dB correction for elevation summing
%    8. Apply circshift for delay offset when d_LOS >= 5m
%    9. Apply delay gating: t_gate = (d(end)-10+d_LOS)/3e8
%
%  DS Computation (Naveed-faithful, USCprocessing.m L97-114):
%    - Separate 10x zero-padded IFFT for DS (independent of PL chain)
%    - Threshold shifted by -20*log10(n_oversamp) = -20 dB to account
%      for per-bin power after oversampling
%    - Standard RMS-DS: sqrt(E[τ²] - E[τ]²) on oversampled linear PDP
%    - 966.67 ns delay gate applied (paper Eq. 9 / USC-parity convention)
%
%  =========================================================================
%  METHOD COMPARISON SUMMARY
%  =========================================================================
%
%  COMMON SETTINGS (Both Methods):
%    - PDP Threshold: USC's global noise + 12dB (applied to ALL metrics)
%    - Correction Factor: -1.95 dB (elevation summing compensation)
%    - AS Formula: 3GPP sqrt(-2*ln(R)) from circ_std.m
%
%  DIFFERENCES:
%    | Metric | Aspect          | NYU Method              | USC Method              |
%    |--------|-----------------|-------------------------|-------------------------|
%    | PL/DS  | Omni Synthesis  | SUM across directions   | perDelayMax (max/delay) |
%    | AS     | PAS Threshold   | 10/15/20 dB below peak  | NONE                    |
%    | AS     | Lobe Expansion  | Antenna pattern-based   | NONE                    |
%
%  DATA SOURCE:
%    - H matrix: D:\NYU-USC\Cross-Processing\USC\USC_Data\THz data PDP\PDP_NYU\
%    - All metrics (PL, DS, AS) computed from H matrix following USC method
%
%  Author: Mingjun Ying
%  Last updated: April 2026 (Naveed-faithful: oversampled DS chain,
%                            max-noise-across-all-dirs + 12 dB, 966.67 ns gate)
%
%  ========================================================================

%% SECTION 0: CLEAR ENVIRONMENT
clear; clc; close all;

%% SECTION 1: CONFIGURATION
% =========================================================================
% SYSTEM PARAMETERS (USC 145GHz Microcellular)
% =========================================================================
% NOTE: This script loads the H matrix and computes PDP using USC's exact
% method from Parameter_comp_THz_fullelev.mlx:
%   - Hann windowing with normalization before IFFT
%   - PDP = |ifft(H.*window)|^2
%   - Noise threshold: 25th percentile + 5.41 dB + 12 dB margin
%   - Path loss: PL = -10*log10(sum(PDP_omni))
% =========================================================================
params.Ptx_dBm = -2;              % Transmit power in dBm (for reference only)
params.TX_Ant_Gain_dB = 21;       % TX antenna gain (for reference only)
params.RX_Ant_Gain_dB = 21;       % RX antenna gain (for reference only)
params.Frequency_GHz = 145;       % Carrier frequency
% USC 145 GHz Horn Antenna HPBW (from aziCut.mat and elevCut.mat):
%   Azimuth (H-plane):   17.2 degrees
%   Elevation (E-plane): 14.0 degrees
%   Average HPBW:        15.6 degrees
% Using measurement grid step (10 deg) as effective HPBW for lobe detection
% (conservative value since grid resolution limits angular sampling)
params.HPBW = 10;                 % Half-power beamwidth in degrees (USC antenna)
params.Az_step = 10;              % Azimuth rotation step
params.El_step = 10;              % Elevation rotation step

% =========================================================================
% DATA PARAMETERS (from Parameter_comp_THz_fullelev.mlx)
% =========================================================================
params.BW = 1e9;                  % Bandwidth = 1 GHz
params.Nf = 1001;                 % Number of frequency/delay samples
params.dt = 1/params.BW;          % Time resolution = 1 ns
params.Fs = 1.5e9;                % Sampling frequency for H matrix
params.Ts = 1/params.Fs;          % Sampling period
params.delayGate_ns = 966.67;     % Max delay gate in ns
params.n_oversamp = 10;           % USC oversampling factor for RMS-DS
params.c = 3e8;                   % Speed of light [m/s]

% Distance vector (from USC ground truth code)
% d = (0:Nf-1)*3e8/1e9 where 3e8/1e9 = 0.3 m/sample
params.d_vec_m = (0:params.Nf-1) * params.c / params.BW;  % [0, 0.3, 0.6, ... 300] m
params.d2_vec_m = (0:1/params.n_oversamp:params.Nf-1/params.n_oversamp) * params.c / params.BW;  % Oversampled

% Angular grid dimensions
params.N_aztx = 13;               % TX azimuth positions
params.N_eltx = 3;                % TX elevation positions
params.N_azrx = 36;               % RX azimuth positions
params.N_elrx = 3;                % RX elevation positions
params.txAz = (-60:10:60).';      % TX azimuth angles [deg]
params.rxAz = (0:10:350).';       % RX azimuth angles [deg]

% =========================================================================
% CORRECTION FACTORS
% =========================================================================
% -1.95 dB correction for elevation summing (USC standard)
params.correction_factor_dB = -1.95;
params.correction_factor_lin = 10^(params.correction_factor_dB/10);

% =========================================================================
% THRESHOLD SETTINGS
% =========================================================================
% PDP Threshold (USC method - COMMON for all metrics)
config.noise_margin_dB = 12;      % dB above max noise floor (Naveed USCprocessing.m L60)

% PAS Threshold (NYU AS method only)
config.PAS_threshold_1 = 10;      % Strictest: 10 dB below peak
config.PAS_threshold_2 = 15;      % Medium: 15 dB below peak
config.PAS_threshold_3 = 20;      % Relaxed: 20 dB below peak
config.multipath_low_bound = -100; % Absolute floor in dB

% =========================================================================
% ANTENNA PATTERN FILES (for NYU AS lobe expansion)
% =========================================================================
% NOTE: USC's raw PDP data has antenna gain REMOVED, so we use USC's antenna
% pattern files for boundary interpolation in the NYU AS method.
U = paths();
config.antenna_pattern_path = U.usc_145_pattern_dir;
config.azi_pattern_file = 'aziCut.mat';       % USC H-plane pattern [181x2]: angle, gain_dB
config.elev_pattern_file = 'elevCut.mat';     % USC E-plane pattern [181x2]: angle, gain_dB

% =========================================================================
% IEEE FIGURE SETTINGS FOR DOUBLE-COLUMN JOURNAL
% =========================================================================
IEEE_DOUBLE_COL_WIDTH = 7.0;      % Full page width (~7.16" max)
IEEE_SINGLE_COL_WIDTH = 3.5;      % Single column width

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
colors.LOS = [0.0000 0.4470 0.7410];       % Blue for LOS
colors.NLOS = [0.8500 0.3250 0.0980];      % Orange for NLOS

% =========================================================================
% DATA PATHS
% =========================================================================
% PDP data for PL, DS, and AS (all metrics computed from same source)
paths.data_LOS = U.raw_usc_145_LOS;
paths.data_NLOS = U.raw_usc_145_NLOS;

% Output paths
paths.output = U.results_usc_145;
paths.figures = U.figures_usc_145;

% Create output directories
if ~exist(paths.output, 'dir'), mkdir(paths.output); end
if ~exist(paths.figures, 'dir'), mkdir(paths.figures); end

% =========================================================================
% FILE LISTS WITH DISTANCES
% =========================================================================
% Column 1: PDP file name (source for PL, DS, and AS)
% Column 2: Distance (m)
LOS_files = {
    'PDP_R01_64.5m LOS_Microcellular.mat', 64.5;
    'PDP_R02_82.5m LOS_Microcellular.mat', 82.5;
    'PDP_R03_32.1m LOS_Microcellular.mat', 32.1;
    'PDP_R04_40.8m LOS_Microcellular.mat', 40.8;
    'PDP_R05_49.8m LOS_Microcellular.mat', 49.8;
    'PDP_R06_72.3m LOS_Microcellular.mat', 72.3;
    'PDP_R07_20.4m LOS_Microcellular.mat', 20.4;
    'PDP_R08_33.9m LOS_Microcellular.mat', 33.9;
    'PDP_R09_45.9m LOS_Microcellular.mat', 45.9;
    'PDP_R10_54.3m LOS_Microcellular.mat', 54.3;
    'PDP_R11_36.3m LOS_Microcellular.mat', 36.3;
    'PDP_R12_57.9m LOS_Microcellular.mat', 57.9;
    'PDP_R13_65.7m LOS_Microcellular.mat', 65.7;
};

NLOS_files = {
    'PDP_R01_46m NLOS_Microcellular.mat', 46;
    'PDP_R02_73m NLOS_Microcellular.mat', 73;
    'PDP_R03_83m NLOS_Microcellular.mat', 83;
    'PDP_R04_40.66m NLOS_Microcellular.mat', 40.66;
    'PDP_R05_53.35m NLOS_Microcellular.mat', 53.35;
    'PDP_R06_62.56m NLOS_Microcellular.mat', 62.56;
    'PDP_R07_35m NLOS_Microcellular.mat', 35;
    'PDP_R08_45.47m NLOS_Microcellular.mat', 45.47;
    'PDP_R09_58.5m NLOS_Microcellular.mat', 58.5;
    'PDP_R10_65.7m NLOS_Microcellular.mat', 65.7;
    'PDP_R11_18.3m NLOS_Microcellular.mat', 18.3;
    'PDP_R12_20.8m NLOS_Microcellular.mat', 20.8;
    'PDP_R13_30m NLOS_Microcellular.mat', 30;
};

% Note: Time/delay is handled using distance vectors (d, d2) as in USC ground truth code
% d = (0:Nf-1)*c/BW in meters, which USC uses for PDP x-axis

% Display configuration
fprintf('═══════════════════════════════════════════════════════════════════════\n');
fprintf('  USC 145GHz Data: Full Method Comparison (NYU vs USC)\n');
fprintf('═══════════════════════════════════════════════════════════════════════\n');
fprintf('  PDP Threshold: Global max noise + %d dB [USC method, common]\n', config.noise_margin_dB);
fprintf('  Omni Synthesis: NYU=SUM, USC=perDelayMax\n');
fprintf('  PAS Thresholds: %d dB, %d dB, %d dB (NYU AS only)\n', ...
    config.PAS_threshold_1, config.PAS_threshold_2, config.PAS_threshold_3);
fprintf('  Correction Factor: %.2f dB (elevation summing)\n', params.correction_factor_dB);
fprintf('  TX Power: %.1f dBm, Ant Gain: TX=%d dB, RX=%d dB\n', ...
    params.Ptx_dBm, params.TX_Ant_Gain_dB, params.RX_Ant_Gain_dB);
fprintf('═══════════════════════════════════════════════════════════════════════\n\n');

%% SECTION 2: LOAD ANTENNA PATTERN AND INITIALIZE RESULTS
% =========================================================================
% Load antenna pattern for NYU AS lobe expansion
% =========================================================================
% The antenna pattern is used in NYU's method to expand each measurement
% angle into a spatial lobe based on the antenna beamwidth. This follows
% NYU's original implementation in boundaryMPCsD.m and lobeShaperCounterD.m.
antenna_azi = load_antenna_pattern(fullfile(config.antenna_pattern_path, config.azi_pattern_file));
fprintf('Antenna pattern loaded: %d points\n', size(antenna_azi, 1));

% =========================================================================
% Initialize results storage
% =========================================================================
N_LOS = size(LOS_files, 1);
N_NLOS = size(NLOS_files, 1);
nFiles = N_LOS + N_NLOS;

results = struct();
results.Location_ID = cell(nFiles, 1);
results.Environment = cell(nFiles, 1);
results.Distance_m = zeros(nFiles, 1);

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
results.ASA_USC = zeros(nFiles, 1);

% Angular Spread - ASD (Azimuth Spread of Departure)
results.ASD_NYU_10dB = zeros(nFiles, 1);
results.ASD_NYU_15dB = zeros(nFiles, 1);
results.ASD_NYU_20dB = zeros(nFiles, 1);
results.ASD_USC = zeros(nFiles, 1);

% Store noise threshold for reference
results.NoiseThresh_dB = zeros(nFiles, 1);

% Store PDP and APS data for visualization
pdp_store = struct();
aps_store = struct();

%% SECTION 3: PROCESS ALL LOCATIONS
fprintf('╔═══════════════════════════════════════════════════════════════════════╗\n');
fprintf('║    Processing USC 145GHz Data: PL, DS, and AS (NYU vs USC Methods)   ║\n');
fprintf('╚═══════════════════════════════════════════════════════════════════════╝\n\n');

% =========================================================================
% SECTION 3.1: Process LOS Locations
% =========================================================================
fprintf('Processing LOS locations...\n');
fprintf('─────────────────────────────────────────────────────────────────────────\n');

for iLoc = 1:N_LOS
    fileName_PDP = LOS_files{iLoc, 1};
    TR_distance = LOS_files{iLoc, 2};
    d_LOS = TR_distance;  % USC naming convention

    % Extract location ID
    tokens = regexp(fileName_PDP, 'R(\d+)_', 'tokens');
    if ~isempty(tokens)
        Location_ID = sprintf('R%02d', str2double(tokens{1}{1}));
    else
        Location_ID = sprintf('R%02d', iLoc);
    end

    fprintf('Processing [%2d/%2d] %s (d=%.1f m) ... ', iLoc, N_LOS, Location_ID, TR_distance);

    % =====================================================================
    % PART A: PL and DS using USC's EXACT Ground Truth Method
    % (from Parameter_comp_THz_fullelev.mlx)
    % =====================================================================
    fullPath_PDP = fullfile(paths.data_LOS, fileName_PDP);
    data = load(fullPath_PDP, 'H');  % Load H matrix
    H = data.H;

    % Get dimensions
    [Nf, N_aztx, N_eltx, N_azrx, N_elrx] = size(H);

    % Delay gating (from USC code line 102)
    d = params.d_vec_m;
    d2 = params.d2_vec_m;
    t_gate = (d(end) - 10 + d_LOS) / params.c;  % in seconds

    % --- USC Ground Truth: Hann windowing + IFFT ---
    % From Parameter_comp_THz_fullelev.mlx lines 115-122
    wf = hann(Nf+1, 'Periodic');
    wf = wf(1:end-1);
    wf = sqrt(mean(abs(wf).^2))^(-1) * wf;  % Normalize window
    wf_rep = repmat(wf, [1, N_aztx, N_eltx, N_azrx, N_elrx]);

    % Compute CIR via IFFT (line 138)
    h_delay = ifft(H .* wf_rep, [], 1);

    % Compute PDP (line 150)
    PDP_dir = abs(h_delay).^2;

    % --- Noise threshold calculation (USC method) ---
    % From lines 152-165: compute per-direction noise using 25th percentile + 5.41 dB
    noise_temp = zeros(N_aztx, N_eltx, N_azrx, N_elrx);
    for az_tx = 1:N_aztx
        for el_tx = 1:N_eltx
            for az_rx = 1:N_azrx
                for el_rx = 1:N_elrx
                    pdp_temp = squeeze(PDP_dir(:, az_tx, el_tx, az_rx, el_rx));
                    noise_temp(az_tx, el_tx, az_rx, el_rx) = noise_floor_calc_v2(pdp_temp);
                end
            end
        end
    end
    % Naveed's USCprocessing.m L58-60: noise_thresh = max noise across all
    % directions + 12 dB. (The Az_Tx/El_Tx/Az_Rx/El_Rx indices in Naveed's
    % code are the location of max *noise floor*, not max peak power, so
    % noise_temp(those_idx) == max_noise by construction.)
    max_noise = max(noise_temp, [], 'all');
    noise_thresh_dB = max_noise + config.noise_margin_dB;  % +12 dB
    noise_thresh_lin = 10^(noise_thresh_dB/10);

    % Apply threshold (line 169)
    PDP_dir_thresh = PDP_dir;
    PDP_dir_thresh(PDP_dir <= noise_thresh_lin) = 0;

    % --- NYU SUM Method (for comparison) ---
    PDP_omni_NYU = squeeze(sum(PDP_dir_thresh, [2,3,4,5])) * params.correction_factor_lin;
    if d_LOS >= 5
        PDP_omni_NYU = circshift(PDP_omni_NYU, -round((d_LOS-5)/d(2)));
    end
    PDP_omni_NYU = PDP_omni_NYU .* (((d + d_LOS - 5) / params.c) <= t_gate).';
    Pr_NYU = sum(PDP_omni_NYU);

    % --- USC perDelayMax Method (ground truth) ---
    % From lines 184-199: Sum RxEl → Max RxAz → Sum TxEl → Max TxAz
    PDP_temp1 = squeeze(sum(PDP_dir_thresh, 5));           % Sum over RxEl
    PDP_temp2 = squeeze(max(PDP_temp1, [], 4));            % Max over RxAz
    PDP_temp3 = squeeze(sum(PDP_temp2, 3));                % Sum over TxEl
    PDP_omni_USC = squeeze(max(PDP_temp3, [], 2)) * params.correction_factor_lin;  % Max over TxAz

    % Apply circshift for delay offset (lines 202-204)
    if d_LOS >= 5
        PDP_omni_USC = circshift(PDP_omni_USC, -round((d_LOS-5)/d(2)));
    end

    % Apply delay gating (line 205)
    PDP_omni_USC = PDP_omni_USC .* (((d + d_LOS - 5) / params.c) <= t_gate).';
    Pr_USC = sum(PDP_omni_USC);

    % Compute Path Loss (USC method: PL = -10*log10(PG) = -PG_dB)
    % From line 321: PG_omni = 10*log10(sum(PDP_omni))
    PL_NYU = -10*log10(Pr_NYU + eps);
    PL_USC = -10*log10(Pr_USC + eps);

    % --- RMS Delay Spread (Naveed's 10x oversampled chain, USCprocessing.m L97-114) ---
    % Separate zero-padded IFFT only for DS; PL stays on 1x chain above.
    % Threshold shifts by -20*log10(n_oversamp) dB to account for the
    % per-bin power being spread across 10x more samples.
    h_delay_over = ifft(H .* wf_rep, Nf * params.n_oversamp, 1);
    PDP_dir_over = abs(h_delay_over).^2;
    noise_thresh_lin_over = 10^((noise_thresh_dB - 20*log10(params.n_oversamp))/10);
    PDP_dir_over(PDP_dir_over <= noise_thresh_lin_over) = 0;

    % Omni synthesis on oversampled grid (both methods, for comparison)
    PDP_omni_NYU_over = squeeze(sum(PDP_dir_over, [2,3,4,5])) * params.correction_factor_lin;
    PDP_temp1_over = squeeze(sum(PDP_dir_over, 5));
    PDP_temp2_over = squeeze(max(PDP_temp1_over, [], 4));
    PDP_temp3_over = squeeze(sum(PDP_temp2_over, 3));
    PDP_omni_USC_over = squeeze(max(PDP_temp3_over, [], 2)) * params.correction_factor_lin;

    if d_LOS >= 5
        PDP_omni_NYU_over = circshift(PDP_omni_NYU_over, -round((d_LOS-5)/d2(2)));
        PDP_omni_USC_over = circshift(PDP_omni_USC_over, -round((d_LOS-5)/d2(2)));
    end
    PDP_omni_NYU_over = PDP_omni_NYU_over .* (((d2 + d_LOS - 5) / params.c) <= t_gate).';
    PDP_omni_USC_over = PDP_omni_USC_over .* (((d2 + d_LOS - 5) / params.c) <= t_gate).';

    if d_LOS >= 5
        delay_vec_ns = (d2 + d_LOS - 5) / params.c * 1e9;
    else
        delay_vec_ns = d2 / params.c * 1e9;
    end
    % IMPORTANT: use realmin (2.2e-308) not eps (2.2e-16) for the log-floor.
    % eps-clamping floors weak-but-nonzero bins at -156 dB; db2pow of that
    % inside computeDSonMPC reconstructs them as 2.5e-16 power, which can
    % be ~100x larger than their actual linear value. At late delays the
    % tau^2 weight then inflates DS by 3-4x. Using realmin avoids this.
    PDP_omni_NYU_dB = 10*log10(max(PDP_omni_NYU_over, realmin));
    PDP_omni_USC_dB = 10*log10(max(PDP_omni_USC_over, realmin));
    delay_mask = delay_vec_ns(:) <= params.delayGate_ns;
    valid_mask_NYU = (PDP_omni_NYU_over(:) > 0) & delay_mask;
    valid_mask_USC = (PDP_omni_USC_over(:) > 0) & delay_mask;

    DS_NYU = computeDSonMPC(delay_vec_ns(valid_mask_NYU), PDP_omni_NYU_dB(valid_mask_NYU));
    DS_USC = computeDSonMPC(delay_vec_ns(valid_mask_USC), PDP_omni_USC_dB(valid_mask_USC));

    % =====================================================================
    % PART B: Angular Spread from PDP Data (same thresholded PDP as PL/DS)
    % =====================================================================
    [ASA_NYU_10, ASA_NYU_15, ASA_NYU_20, ASA_USC, ...
     ASD_NYU_10, ASD_NYU_15, ASD_NYU_20, ASD_USC, aps_data] = ...
        compute_AS_from_PDP(PDP_dir_thresh, params, config, antenna_azi);

    % Store results
    results.Location_ID{iLoc} = Location_ID;
    results.Environment{iLoc} = 'LOS';
    results.Distance_m(iLoc) = TR_distance;
    results.PL_NYU(iLoc) = PL_NYU;
    results.PL_USC(iLoc) = PL_USC;
    results.DS_NYU(iLoc) = DS_NYU;
    results.DS_USC(iLoc) = DS_USC;
    results.NoiseThresh_dB(iLoc) = noise_thresh_dB;
    results.ASA_NYU_10dB(iLoc) = ASA_NYU_10;
    results.ASA_NYU_15dB(iLoc) = ASA_NYU_15;
    results.ASA_NYU_20dB(iLoc) = ASA_NYU_20;
    results.ASA_USC(iLoc) = ASA_USC;
    results.ASD_NYU_10dB(iLoc) = ASD_NYU_10;
    results.ASD_NYU_15dB(iLoc) = ASD_NYU_15;
    results.ASD_NYU_20dB(iLoc) = ASD_NYU_20;
    results.ASD_USC(iLoc) = ASD_USC;

    % Store first LOS data for visualization
    if iLoc == 1
        pdp_store.LOS.Location_ID = Location_ID;
        % Use distance axis as in USC code (d + d_LOS - 5)
        if d_LOS >= 5
            pdp_store.LOS.delays_m = d + d_LOS - 5;
        else
            pdp_store.LOS.delays_m = d;
        end
        pdp_store.LOS.OmniPDP_NYU = PDP_omni_NYU;
        pdp_store.LOS.OmniPDP_USC = PDP_omni_USC;
        aps_store.LOS = aps_data;
        aps_store.LOS.Location_ID = Location_ID;
    end

    fprintf('PL: %.1f/%.1f dB | DS: %.1f/%.1f ns | ASA: %.1f/%.1f deg\n', ...
        PL_NYU, PL_USC, DS_NYU, DS_USC, ASA_NYU_10, ASA_USC);
end

% =========================================================================
% SECTION 3.2: Process NLOS Locations
% =========================================================================
fprintf('\nProcessing NLOS locations...\n');
fprintf('─────────────────────────────────────────────────────────────────────────\n');

for iLoc = 1:N_NLOS
    fileName_PDP = NLOS_files{iLoc, 1};
    TR_distance = NLOS_files{iLoc, 2};
    d_LOS = TR_distance;  % USC naming convention
    idx = N_LOS + iLoc;

    % Extract location ID
    tokens = regexp(fileName_PDP, 'R(\d+)_', 'tokens');
    if ~isempty(tokens)
        Location_ID = sprintf('R%02d', str2double(tokens{1}{1}));
    else
        Location_ID = sprintf('R%02d', iLoc);
    end

    fprintf('Processing [%2d/%2d] %s (d=%.1f m) ... ', iLoc, N_NLOS, Location_ID, TR_distance);

    % =====================================================================
    % PART A: PL and DS using USC's EXACT Ground Truth Method
    % (from Parameter_comp_THz_fullelev.mlx)
    % =====================================================================
    fullPath_PDP = fullfile(paths.data_NLOS, fileName_PDP);
    data = load(fullPath_PDP, 'H');  % Load H matrix
    H = data.H;

    % Get dimensions
    [Nf, N_aztx, N_eltx, N_azrx, N_elrx] = size(H);

    % Delay gating
    d = params.d_vec_m;
    d2 = params.d2_vec_m;
    t_gate = (d(end) - 10 + d_LOS) / params.c;  % in seconds

    % --- USC Ground Truth: Hann windowing + IFFT ---
    wf = hann(Nf+1, 'Periodic');
    wf = wf(1:end-1);
    wf = sqrt(mean(abs(wf).^2))^(-1) * wf;  % Normalize window
    wf_rep = repmat(wf, [1, N_aztx, N_eltx, N_azrx, N_elrx]);

    % Compute CIR via IFFT
    h_delay = ifft(H .* wf_rep, [], 1);

    % Compute PDP
    PDP_dir = abs(h_delay).^2;

    % --- Noise threshold calculation (USC method) ---
    noise_temp = zeros(N_aztx, N_eltx, N_azrx, N_elrx);
    for az_tx = 1:N_aztx
        for el_tx = 1:N_eltx
            for az_rx = 1:N_azrx
                for el_rx = 1:N_elrx
                    pdp_temp = squeeze(PDP_dir(:, az_tx, el_tx, az_rx, el_rx));
                    noise_temp(az_tx, el_tx, az_rx, el_rx) = noise_floor_calc_v2(pdp_temp);
                end
            end
        end
    end
    % Naveed's USCprocessing.m L58-60: noise_thresh = max noise across all
    % directions + 12 dB. (The Az_Tx/El_Tx/Az_Rx/El_Rx indices in Naveed's
    % code are the location of max *noise floor*, not max peak power, so
    % noise_temp(those_idx) == max_noise by construction.)
    max_noise = max(noise_temp, [], 'all');
    noise_thresh_dB = max_noise + config.noise_margin_dB;  % +12 dB
    noise_thresh_lin = 10^(noise_thresh_dB/10);

    % Apply threshold
    PDP_dir_thresh = PDP_dir;
    PDP_dir_thresh(PDP_dir <= noise_thresh_lin) = 0;

    % --- NYU SUM Method (for comparison) ---
    PDP_omni_NYU = squeeze(sum(PDP_dir_thresh, [2,3,4,5])) * params.correction_factor_lin;
    if d_LOS >= 5
        PDP_omni_NYU = circshift(PDP_omni_NYU, -round((d_LOS-5)/d(2)));
    end
    PDP_omni_NYU = PDP_omni_NYU .* (((d + d_LOS - 5) / params.c) <= t_gate).';
    Pr_NYU = sum(PDP_omni_NYU);

    % --- USC perDelayMax Method (ground truth) ---
    PDP_temp1 = squeeze(sum(PDP_dir_thresh, 5));           % Sum over RxEl
    PDP_temp2 = squeeze(max(PDP_temp1, [], 4));            % Max over RxAz
    PDP_temp3 = squeeze(sum(PDP_temp2, 3));                % Sum over TxEl
    PDP_omni_USC = squeeze(max(PDP_temp3, [], 2));  % Max over TxAz

    % Apply circshift for delay offset
    if d_LOS >= 5
        PDP_omni_USC = circshift(PDP_omni_USC, -round((d_LOS-5)/d(2)));
    end

    % Apply delay gating
    PDP_omni_USC = PDP_omni_USC .* (((d + d_LOS - 5) / params.c) <= t_gate).';
    Pr_USC = sum(PDP_omni_USC);

    % Compute Path Loss
    PL_NYU = -10*log10(Pr_NYU + eps);
    PL_USC = -10*log10(Pr_USC + eps);

    % --- RMS Delay Spread (Naveed's 10x oversampled chain, USCprocessing.m L97-114) ---
    h_delay_over = ifft(H .* wf_rep, Nf * params.n_oversamp, 1);
    PDP_dir_over = abs(h_delay_over).^2;
    noise_thresh_lin_over = 10^((noise_thresh_dB - 20*log10(params.n_oversamp))/10);
    PDP_dir_over(PDP_dir_over <= noise_thresh_lin_over) = 0;

    PDP_omni_NYU_over = squeeze(sum(PDP_dir_over, [2,3,4,5])) * params.correction_factor_lin;
    PDP_temp1_over = squeeze(sum(PDP_dir_over, 5));
    PDP_temp2_over = squeeze(max(PDP_temp1_over, [], 4));
    PDP_temp3_over = squeeze(sum(PDP_temp2_over, 3));
    PDP_omni_USC_over = squeeze(max(PDP_temp3_over, [], 2)) * params.correction_factor_lin;

    if d_LOS >= 5
        PDP_omni_NYU_over = circshift(PDP_omni_NYU_over, -round((d_LOS-5)/d2(2)));
        PDP_omni_USC_over = circshift(PDP_omni_USC_over, -round((d_LOS-5)/d2(2)));
    end
    PDP_omni_NYU_over = PDP_omni_NYU_over .* (((d2 + d_LOS - 5) / params.c) <= t_gate).';
    PDP_omni_USC_over = PDP_omni_USC_over .* (((d2 + d_LOS - 5) / params.c) <= t_gate).';

    if d_LOS >= 5
        delay_vec_ns = (d2 + d_LOS - 5) / params.c * 1e9;
    else
        delay_vec_ns = d2 / params.c * 1e9;
    end
    % IMPORTANT: use realmin (2.2e-308) not eps (2.2e-16) for the log-floor.
    % eps-clamping floors weak-but-nonzero bins at -156 dB; db2pow of that
    % inside computeDSonMPC reconstructs them as 2.5e-16 power, which can
    % be ~100x larger than their actual linear value. At late delays the
    % tau^2 weight then inflates DS by 3-4x. Using realmin avoids this.
    PDP_omni_NYU_dB = 10*log10(max(PDP_omni_NYU_over, realmin));
    PDP_omni_USC_dB = 10*log10(max(PDP_omni_USC_over, realmin));
    delay_mask = delay_vec_ns(:) <= params.delayGate_ns;
    valid_mask_NYU = (PDP_omni_NYU_over(:) > 0) & delay_mask;
    valid_mask_USC = (PDP_omni_USC_over(:) > 0) & delay_mask;

    DS_NYU = computeDSonMPC(delay_vec_ns(valid_mask_NYU), PDP_omni_NYU_dB(valid_mask_NYU));
    DS_USC = computeDSonMPC(delay_vec_ns(valid_mask_USC), PDP_omni_USC_dB(valid_mask_USC));

    % =====================================================================
    % PART B: Angular Spread from PDP Data (same thresholded PDP as PL/DS)
    % =====================================================================
    [ASA_NYU_10, ASA_NYU_15, ASA_NYU_20, ASA_USC, ...
     ASD_NYU_10, ASD_NYU_15, ASD_NYU_20, ASD_USC, aps_data] = ...
        compute_AS_from_PDP(PDP_dir_thresh, params, config, antenna_azi);

    % Store results
    results.Location_ID{idx} = Location_ID;
    results.Environment{idx} = 'NLOS';
    results.Distance_m(idx) = TR_distance;
    results.PL_NYU(idx) = PL_NYU;
    results.PL_USC(idx) = PL_USC;
    results.DS_NYU(idx) = DS_NYU;
    results.DS_USC(idx) = DS_USC;
    results.NoiseThresh_dB(idx) = noise_thresh_dB;
    results.ASA_NYU_10dB(idx) = ASA_NYU_10;
    results.ASA_NYU_15dB(idx) = ASA_NYU_15;
    results.ASA_NYU_20dB(idx) = ASA_NYU_20;
    results.ASA_USC(idx) = ASA_USC;
    results.ASD_NYU_10dB(idx) = ASD_NYU_10;
    results.ASD_NYU_15dB(idx) = ASD_NYU_15;
    results.ASD_NYU_20dB(idx) = ASD_NYU_20;
    results.ASD_USC(idx) = ASD_USC;

    % Store first NLOS data for visualization
    if iLoc == 1
        pdp_store.NLOS.Location_ID = Location_ID;
        % Use distance axis as in USC code (d + d_LOS - 5)
        if d_LOS >= 5
            pdp_store.NLOS.delays_m = d + d_LOS - 5;
        else
            pdp_store.NLOS.delays_m = d;
        end
        pdp_store.NLOS.OmniPDP_NYU = PDP_omni_NYU;
        pdp_store.NLOS.OmniPDP_USC = PDP_omni_USC;
        aps_store.NLOS = aps_data;
        aps_store.NLOS.Location_ID = Location_ID;
    end

    fprintf('PL: %.1f/%.1f dB | DS: %.1f/%.1f ns | ASA: %.1f/%.1f deg\n', ...
        PL_NYU, PL_USC, DS_NYU, DS_USC, ASA_NYU_10, ASA_USC);
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
fprintf('║ PDP Threshold          │ Global noise + 12dB               │ SAME (common)                             ║\n');
fprintf('║ Omni Synthesis (PL/DS) │ SUM across all directions         │ perDelayMax (max per delay)               ║\n');
fprintf('║ PAS Threshold (AS)     │ 10/15/20 dB below peak            │ NONE                                      ║\n');
fprintf('║ Lobe Expansion (AS)    │ Antenna pattern-based (HPBW=10°)  │ NONE                                      ║\n');
fprintf('║ AS Formula             │ 3GPP: sqrt(-2*ln(R))              │ SAME                                      ║\n');
fprintf('╚════════════════════════╧═══════════════════════════════════╧═══════════════════════════════════════════╝\n\n');

% =========================================================================
% TABLE 2: Per-Location Results
% =========================================================================
fprintf('╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗\n');
fprintf('║                                                            TABLE 2: PER-LOCATION RESULTS                                                                           ║\n');
fprintf('╠═════════╤══════╤═══════════════════╤═══════════════════╤═════════════════════════════════════════╤═════════════════════════════════════════════════════════════════╣\n');
fprintf('║  Loc    │ Env  │   Path Loss (dB)  │  Delay Spread(ns) │          ASA (degrees)                  │              ASD (degrees)                                      ║\n');
fprintf('║         │      │  NYU   │   USC    │  NYU   │   USC    │ NYU-10 │ NYU-15 │ NYU-20 │  USC  │ NYU-10 │ NYU-15 │ NYU-20 │  USC  ║\n');
fprintf('╠═════════╪══════╪════════╪══════════╪════════╪══════════╪════════╪════════╪════════╪═══════╪════════╪════════╪════════╪═══════╣\n');

for i = 1:nFiles
    fprintf('║ %-7s │ %-4s │ %6.1f │ %6.1f   │ %6.1f │ %6.1f   │ %6.1f │ %6.1f │ %6.1f │ %5.1f │ %6.1f │ %6.1f │ %6.1f │ %5.1f ║\n', ...
        results.Location_ID{i}, results.Environment{i}, ...
        results.PL_NYU(i), results.PL_USC(i), ...
        results.DS_NYU(i), results.DS_USC(i), ...
        results.ASA_NYU_10dB(i), results.ASA_NYU_15dB(i), results.ASA_NYU_20dB(i), results.ASA_USC(i), ...
        results.ASD_NYU_10dB(i), results.ASD_NYU_15dB(i), results.ASD_NYU_20dB(i), results.ASD_USC(i));
end
fprintf('╚═════════╧══════╧════════╧══════════╧════════╧══════════╧════════╧════════╧════════╧═══════╧════════╧════════╧════════╧═══════╝\n\n');

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
fprintf('║ Δ PL (NYU - USC)               │ %6.2f ± %5.2f dB                    │ %6.2f ± %5.2f dB                    │ %6.2f ± %5.2f dB  ║\n', ...
    mean(results.PL_NYU(los_mask) - results.PL_USC(los_mask)), std(results.PL_NYU(los_mask) - results.PL_USC(los_mask)), ...
    mean(results.PL_NYU(nlos_mask) - results.PL_USC(nlos_mask)), std(results.PL_NYU(nlos_mask) - results.PL_USC(nlos_mask)), ...
    mean(results.PL_NYU - results.PL_USC), std(results.PL_NYU - results.PL_USC));
fprintf('╠════════════════════════════════╪═════════════════════════════════════╪═════════════════════════════════════════════════════════╣\n');

% Delay Spread
fprintf('║ DS - NYU (SUM)                 │ %6.1f ± %5.1f ns                    │ %6.1f ± %5.1f ns                    │ %6.1f ± %5.1f ns  ║\n', ...
    mean(results.DS_NYU(los_mask)), std(results.DS_NYU(los_mask)), ...
    nanmean(results.DS_NYU(nlos_mask)), nanstd(results.DS_NYU(nlos_mask)), ...
    nanmean(results.DS_NYU), nanstd(results.DS_NYU));
fprintf('║ DS - USC (perDelayMax)         │ %6.1f ± %5.1f ns                    │ %6.1f ± %5.1f ns                    │ %6.1f ± %5.1f ns  ║\n', ...
    mean(results.DS_USC(los_mask)), std(results.DS_USC(los_mask)), ...
    nanmean(results.DS_USC(nlos_mask)), nanstd(results.DS_USC(nlos_mask)), ...
    nanmean(results.DS_USC), nanstd(results.DS_USC));
fprintf('╠════════════════════════════════╪═════════════════════════════════════╪═════════════════════════════════════════════════════════╣\n');

% ASA
fprintf('║ ASA - NYU 10dB                 │ %6.1f ± %5.1f deg                   │ %6.1f ± %5.1f deg                   │ %6.1f ± %5.1f deg ║\n', ...
    nanmean(results.ASA_NYU_10dB(los_mask)), nanstd(results.ASA_NYU_10dB(los_mask)), ...
    nanmean(results.ASA_NYU_10dB(nlos_mask)), nanstd(results.ASA_NYU_10dB(nlos_mask)), ...
    nanmean(results.ASA_NYU_10dB), nanstd(results.ASA_NYU_10dB));
fprintf('║ ASA - NYU 15dB                 │ %6.1f ± %5.1f deg                   │ %6.1f ± %5.1f deg                   │ %6.1f ± %5.1f deg ║\n', ...
    nanmean(results.ASA_NYU_15dB(los_mask)), nanstd(results.ASA_NYU_15dB(los_mask)), ...
    nanmean(results.ASA_NYU_15dB(nlos_mask)), nanstd(results.ASA_NYU_15dB(nlos_mask)), ...
    nanmean(results.ASA_NYU_15dB), nanstd(results.ASA_NYU_15dB));
fprintf('║ ASA - NYU 20dB                 │ %6.1f ± %5.1f deg                   │ %6.1f ± %5.1f deg                   │ %6.1f ± %5.1f deg ║\n', ...
    nanmean(results.ASA_NYU_20dB(los_mask)), nanstd(results.ASA_NYU_20dB(los_mask)), ...
    nanmean(results.ASA_NYU_20dB(nlos_mask)), nanstd(results.ASA_NYU_20dB(nlos_mask)), ...
    nanmean(results.ASA_NYU_20dB), nanstd(results.ASA_NYU_20dB));
fprintf('║ ASA - USC (no threshold)       │ %6.1f ± %5.1f deg                   │ %6.1f ± %5.1f deg                   │ %6.1f ± %5.1f deg ║\n', ...
    nanmean(results.ASA_USC(los_mask)), nanstd(results.ASA_USC(los_mask)), ...
    nanmean(results.ASA_USC(nlos_mask)), nanstd(results.ASA_USC(nlos_mask)), ...
    nanmean(results.ASA_USC), nanstd(results.ASA_USC));
fprintf('╠════════════════════════════════╪═════════════════════════════════════╪═════════════════════════════════════════════════════════╣\n');

% ASD
fprintf('║ ASD - NYU 10dB                 │ %6.1f ± %5.1f deg                   │ %6.1f ± %5.1f deg                   │ %6.1f ± %5.1f deg ║\n', ...
    nanmean(results.ASD_NYU_10dB(los_mask)), nanstd(results.ASD_NYU_10dB(los_mask)), ...
    nanmean(results.ASD_NYU_10dB(nlos_mask)), nanstd(results.ASD_NYU_10dB(nlos_mask)), ...
    nanmean(results.ASD_NYU_10dB), nanstd(results.ASD_NYU_10dB));
fprintf('║ ASD - NYU 15dB                 │ %6.1f ± %5.1f deg                   │ %6.1f ± %5.1f deg                   │ %6.1f ± %5.1f deg ║\n', ...
    nanmean(results.ASD_NYU_15dB(los_mask)), nanstd(results.ASD_NYU_15dB(los_mask)), ...
    nanmean(results.ASD_NYU_15dB(nlos_mask)), nanstd(results.ASD_NYU_15dB(nlos_mask)), ...
    nanmean(results.ASD_NYU_15dB), nanstd(results.ASD_NYU_15dB));
fprintf('║ ASD - NYU 20dB                 │ %6.1f ± %5.1f deg                   │ %6.1f ± %5.1f deg                   │ %6.1f ± %5.1f deg ║\n', ...
    nanmean(results.ASD_NYU_20dB(los_mask)), nanstd(results.ASD_NYU_20dB(los_mask)), ...
    nanmean(results.ASD_NYU_20dB(nlos_mask)), nanstd(results.ASD_NYU_20dB(nlos_mask)), ...
    nanmean(results.ASD_NYU_20dB), nanstd(results.ASD_NYU_20dB));
fprintf('║ ASD - USC (no threshold)       │ %6.1f ± %5.1f deg                   │ %6.1f ± %5.1f deg                   │ %6.1f ± %5.1f deg ║\n', ...
    nanmean(results.ASD_USC(los_mask)), nanstd(results.ASD_USC(los_mask)), ...
    nanmean(results.ASD_USC(nlos_mask)), nanstd(results.ASD_USC(nlos_mask)), ...
    nanmean(results.ASD_USC), nanstd(results.ASD_USC));
fprintf('╚════════════════════════════════╧═════════════════════════════════════╧═════════════════════════════════════════════════════════╝\n\n');

%% SECTION 5: GENERATE FIGURES
fprintf('Generating figures...\n');

% =========================================================================
% FIGURE 1: Omni PDP Comparison (LOS vs NLOS)
% =========================================================================
fig1 = figure('Units', 'inches', 'Position', [1 1 IEEE_DOUBLE_COL_WIDTH 2.8], 'Name', 'Fig1: Omni PDP');

if isfield(pdp_store, 'LOS')
    subplot(1,2,1);
    % USC uses distance axis (meters) for PDP plots
    plot(pdp_store.LOS.delays_m, 10*log10(pdp_store.LOS.OmniPDP_NYU + eps), ...
        'Color', colors.NYU_10dB, 'LineWidth', 1.2, 'DisplayName', 'NYU (SUM)');
    hold on;
    plot(pdp_store.LOS.delays_m, 10*log10(pdp_store.LOS.OmniPDP_USC + eps), ...
        'Color', colors.USC, 'LineWidth', 1.2, 'DisplayName', 'USC (perDelayMax)');
    xlabel('Distance (m)', 'FontSize', 10, 'Interpreter', 'latex');
    ylabel('$|h(\tau)|^2$ (dB)', 'FontSize', 10, 'Interpreter', 'latex');
    title(sprintf('(a) LOS: %s', pdp_store.LOS.Location_ID), 'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'latex');
    legend('Location', 'northeast', 'FontSize', 7, 'Box', 'off');
    grid on; xlim([0 200]); set(gca, 'FontSize', 9);
end

if isfield(pdp_store, 'NLOS')
    subplot(1,2,2);
    % USC uses distance axis (meters) for PDP plots
    plot(pdp_store.NLOS.delays_m, 10*log10(pdp_store.NLOS.OmniPDP_NYU + eps), ...
        'Color', colors.NYU_10dB, 'LineWidth', 1.2, 'DisplayName', 'NYU (SUM)');
    hold on;
    plot(pdp_store.NLOS.delays_m, 10*log10(pdp_store.NLOS.OmniPDP_USC + eps), ...
        'Color', colors.USC, 'LineWidth', 1.2, 'DisplayName', 'USC (perDelayMax)');
    xlabel('Distance (m)', 'FontSize', 10, 'Interpreter', 'latex');
    ylabel('$|h(\tau)|^2$ (dB)', 'FontSize', 10, 'Interpreter', 'latex');
    title(sprintf('(b) NLOS: %s', pdp_store.NLOS.Location_ID), 'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'latex');
    legend('Location', 'northeast', 'FontSize', 7, 'Box', 'off');
    grid on; xlim([0 300]); set(gca, 'FontSize', 9);
end

saveFigure(fig1, paths.figures, 'Fig1_OmniPDP_Comparison');

% =========================================================================
% FIGURE 2: Path Loss Bar Chart
% =========================================================================
fig2 = figure('Units', 'inches', 'Position', [1 1 IEEE_DOUBLE_COL_WIDTH 2.8], 'Name', 'Fig2: Path Loss');

subplot(1,2,1);
bar_data_PL = [results.PL_NYU, results.PL_USC];
b = bar(1:nFiles, bar_data_PL, 'grouped', 'BarWidth', 0.75);
b(1).FaceColor = colors.NYU_10dB; b(2).FaceColor = colors.USC;
ax = gca; ax.XTick = 1:nFiles; ax.XTickLabel = results.Location_ID;
ax.XTickLabelRotation = 60; ax.TickLabelInterpreter = 'none'; ax.FontSize = 8;
xlabel('Location', 'FontSize', 10, 'Interpreter', 'latex');
ylabel('Path Loss (dB)', 'FontSize', 10, 'Interpreter', 'latex');
title('(a) Path Loss per Location', 'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'latex');
legend({'NYU (SUM)', 'USC (perDelayMax)'}, 'Location', 'northwest', 'FontSize', 7, 'Box', 'off');
grid on;

subplot(1,2,2);
scatter(results.PL_USC(los_mask), results.PL_NYU(los_mask), 40, colors.LOS, 'filled', 'DisplayName', 'LOS');
hold on;
scatter(results.PL_USC(nlos_mask), results.PL_NYU(nlos_mask), 40, colors.NLOS, 'filled', 'DisplayName', 'NLOS');
plot([80 140], [80 140], 'k--', 'LineWidth', 1, 'DisplayName', 'y=x');
xlabel('PL USC (dB)', 'FontSize', 10, 'Interpreter', 'latex');
ylabel('PL NYU (dB)', 'FontSize', 10, 'Interpreter', 'latex');
title('(b) PL Scatter: NYU vs USC', 'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'latex');
legend('Location', 'southeast', 'FontSize', 7, 'Box', 'off');
grid on; axis equal; set(gca, 'FontSize', 9);

saveFigure(fig2, paths.figures, 'Fig2_PathLoss_Comparison');

% =========================================================================
% FIGURE 3: Delay Spread Bar Chart
% =========================================================================
fig3 = figure('Units', 'inches', 'Position', [1 1 IEEE_DOUBLE_COL_WIDTH 2.8], 'Name', 'Fig3: Delay Spread');

subplot(1,2,1);
bar_data_DS = [results.DS_NYU, results.DS_USC];
b = bar(1:nFiles, bar_data_DS, 'grouped', 'BarWidth', 0.75);
b(1).FaceColor = colors.NYU_10dB; b(2).FaceColor = colors.USC;
ax = gca; ax.XTick = 1:nFiles; ax.XTickLabel = results.Location_ID;
ax.XTickLabelRotation = 60; ax.TickLabelInterpreter = 'none'; ax.FontSize = 8;
xlabel('Location', 'FontSize', 10, 'Interpreter', 'latex');
ylabel('RMS DS (ns)', 'FontSize', 10, 'Interpreter', 'latex');
title('(a) Delay Spread per Location', 'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'latex');
legend({'NYU (SUM)', 'USC (perDelayMax)'}, 'Location', 'northwest', 'FontSize', 7, 'Box', 'off');
grid on;

subplot(1,2,2);
scatter(results.DS_USC(los_mask), results.DS_NYU(los_mask), 40, colors.LOS, 'filled', 'DisplayName', 'LOS');
hold on;
scatter(results.DS_USC(nlos_mask), results.DS_NYU(nlos_mask), 40, colors.NLOS, 'filled', 'DisplayName', 'NLOS');
plot([0 200], [0 200], 'k--', 'LineWidth', 1, 'DisplayName', 'y=x');
xlabel('DS USC (ns)', 'FontSize', 10, 'Interpreter', 'latex');
ylabel('DS NYU (ns)', 'FontSize', 10, 'Interpreter', 'latex');
title('(b) DS Scatter: NYU vs USC', 'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'latex');
legend('Location', 'southeast', 'FontSize', 7, 'Box', 'off');
grid on; axis equal; set(gca, 'FontSize', 9);

saveFigure(fig3, paths.figures, 'Fig3_DelaySpread_Comparison');

% =========================================================================
% FIGURE 4: Method Difference (Bland-Altman style for PL and DS)
% =========================================================================
fig4 = figure('Units', 'inches', 'Position', [1 1 IEEE_DOUBLE_COL_WIDTH 2.8], 'Name', 'Fig4: Method Difference');

delta_PL = results.PL_NYU - results.PL_USC;
delta_DS = results.DS_NYU - results.DS_USC;

subplot(1,2,1);
bar_colors = repmat(colors.LOS, nFiles, 1);
bar_colors(nlos_mask, :) = repmat(colors.NLOS, sum(nlos_mask), 1);
bh = bar(1:nFiles, delta_PL, 'FaceColor', 'flat', 'EdgeColor', 'k', 'LineWidth', 0.5);
bh.CData = bar_colors;
hold on;
yline(mean(delta_PL(los_mask)), '--', 'Color', colors.LOS, 'LineWidth', 1.5);
yline(mean(delta_PL(nlos_mask)), '--', 'Color', colors.NLOS, 'LineWidth', 1.5);
yline(0, 'k-', 'LineWidth', 0.8);
ax = gca; ax.XTick = 1:nFiles; ax.XTickLabel = results.Location_ID;
ax.XTickLabelRotation = 60; ax.TickLabelInterpreter = 'none'; ax.FontSize = 8;
xlabel('Location', 'FontSize', 10, 'Interpreter', 'latex');
ylabel('$\Delta$PL (NYU $-$ USC) [dB]', 'FontSize', 10, 'Interpreter', 'latex');
title('(a) Path Loss Difference', 'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'latex');
grid on;

subplot(1,2,2);
bh2 = bar(1:nFiles, delta_DS, 'FaceColor', 'flat', 'EdgeColor', 'k', 'LineWidth', 0.5);
bh2.CData = bar_colors;
hold on;
yline(nanmean(delta_DS(los_mask)), '--', 'Color', colors.LOS, 'LineWidth', 1.5);
yline(nanmean(delta_DS(nlos_mask)), '--', 'Color', colors.NLOS, 'LineWidth', 1.5);
yline(0, 'k-', 'LineWidth', 0.8);
ax = gca; ax.XTick = 1:nFiles; ax.XTickLabel = results.Location_ID;
ax.XTickLabelRotation = 60; ax.TickLabelInterpreter = 'none'; ax.FontSize = 8;
xlabel('Location', 'FontSize', 10, 'Interpreter', 'latex');
ylabel('$\Delta$DS (NYU $-$ USC) [ns]', 'FontSize', 10, 'Interpreter', 'latex');
title('(b) Delay Spread Difference', 'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'latex');
grid on;

saveFigure(fig4, paths.figures, 'Fig4_Method_Difference');

% =========================================================================
% FIGURE 6: Angular Spread Bar Chart
% =========================================================================
fig6 = figure('Units', 'inches', 'Position', [1 1 IEEE_DOUBLE_COL_WIDTH 3.0], 'Name', 'Fig6: Angular Spread');

subplot(1,2,1);
bar_data_ASA = [results.ASA_NYU_10dB, results.ASA_NYU_15dB, results.ASA_NYU_20dB, results.ASA_USC];
b = bar(1:nFiles, bar_data_ASA, 'grouped', 'BarWidth', 0.9);
b(1).FaceColor = colors.NYU_10dB; b(2).FaceColor = colors.NYU_15dB; b(3).FaceColor = colors.NYU_20dB; b(4).FaceColor = colors.USC;
ax = gca; ax.XTick = 1:nFiles; ax.XTickLabel = results.Location_ID;
ax.XTickLabelRotation = 60; ax.TickLabelInterpreter = 'none'; ax.FontSize = 8;
xlabel('Location', 'FontSize', 10, 'Interpreter', 'latex');
ylabel('ASA (degrees)', 'FontSize', 10, 'Interpreter', 'latex');
title('(a) Azimuth Spread of Arrival', 'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'latex');
legend({'NYU-10dB', 'NYU-15dB', 'NYU-20dB', 'USC'}, 'Location', 'northwest', 'FontSize', 7, 'Box', 'off');
grid on;

subplot(1,2,2);
bar_data_ASD = [results.ASD_NYU_10dB, results.ASD_NYU_15dB, results.ASD_NYU_20dB, results.ASD_USC];
b = bar(1:nFiles, bar_data_ASD, 'grouped', 'BarWidth', 0.9);
b(1).FaceColor = colors.NYU_10dB; b(2).FaceColor = colors.NYU_15dB; b(3).FaceColor = colors.NYU_20dB; b(4).FaceColor = colors.USC;
ax = gca; ax.XTick = 1:nFiles; ax.XTickLabel = results.Location_ID;
ax.XTickLabelRotation = 60; ax.TickLabelInterpreter = 'none'; ax.FontSize = 8;
xlabel('Location', 'FontSize', 10, 'Interpreter', 'latex');
ylabel('ASD (degrees)', 'FontSize', 10, 'Interpreter', 'latex');
title('(b) Azimuth Spread of Departure', 'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'latex');
legend({'NYU-10dB', 'NYU-15dB', 'NYU-20dB', 'USC'}, 'Location', 'northwest', 'FontSize', 7, 'Box', 'off');
grid on;

saveFigure(fig6, paths.figures, 'Fig6_AngularSpread_BarChart');

% =========================================================================
% FIGURE 8: Bland-Altman for PL and DS
% =========================================================================
fig8 = figure('Units', 'inches', 'Position', [1 1 IEEE_DOUBLE_COL_WIDTH 5.5], 'Name', 'Fig8: Bland-Altman PL/DS');

mean_PL = (results.PL_NYU + results.PL_USC) / 2;
diff_PL = results.PL_NYU - results.PL_USC;
mean_DS = (results.DS_NYU + results.DS_USC) / 2;
diff_DS = results.DS_NYU - results.DS_USC;

subplot(2,2,1);
scatter(mean_PL(los_mask), diff_PL(los_mask), 40, colors.LOS, 'filled'); hold on;
scatter(mean_PL(nlos_mask), diff_PL(nlos_mask), 40, colors.NLOS, 'filled');
yline(mean(diff_PL), 'k-', 'LineWidth', 1.5);
yline(mean(diff_PL) + 1.96*std(diff_PL), 'r--', 'LineWidth', 1);
yline(mean(diff_PL) - 1.96*std(diff_PL), 'r--', 'LineWidth', 1);
xlabel('Mean PL (dB)', 'FontSize', 10, 'Interpreter', 'latex');
ylabel('$\Delta$PL (dB)', 'FontSize', 10, 'Interpreter', 'latex');
title(sprintf('(a) PL: $\\mu$=%.2f, $\\sigma$=%.2f dB', mean(diff_PL), std(diff_PL)), 'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'latex');
grid on; set(gca, 'FontSize', 9);

subplot(2,2,2);
scatter(mean_DS(los_mask), diff_DS(los_mask), 40, colors.LOS, 'filled'); hold on;
scatter(mean_DS(nlos_mask), diff_DS(nlos_mask), 40, colors.NLOS, 'filled');
yline(nanmean(diff_DS), 'k-', 'LineWidth', 1.5);
yline(nanmean(diff_DS) + 1.96*nanstd(diff_DS), 'r--', 'LineWidth', 1);
yline(nanmean(diff_DS) - 1.96*nanstd(diff_DS), 'r--', 'LineWidth', 1);
xlabel('Mean DS (ns)', 'FontSize', 10, 'Interpreter', 'latex');
ylabel('$\Delta$DS (ns)', 'FontSize', 10, 'Interpreter', 'latex');
title(sprintf('(b) DS: $\\mu$=%.2f, $\\sigma$=%.2f ns', nanmean(diff_DS), nanstd(diff_DS)), 'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'latex');
grid on; set(gca, 'FontSize', 9);

mean_ASA = (results.ASA_NYU_10dB + results.ASA_USC) / 2;
diff_ASA = results.ASA_NYU_10dB - results.ASA_USC;
mean_ASD = (results.ASD_NYU_10dB + results.ASD_USC) / 2;
diff_ASD = results.ASD_NYU_10dB - results.ASD_USC;

subplot(2,2,3);
scatter(mean_ASA(los_mask), diff_ASA(los_mask), 40, colors.LOS, 'filled'); hold on;
scatter(mean_ASA(nlos_mask), diff_ASA(nlos_mask), 40, colors.NLOS, 'filled');
yline(nanmean(diff_ASA), 'k-', 'LineWidth', 1.5);
yline(nanmean(diff_ASA) + 1.96*nanstd(diff_ASA), 'r--', 'LineWidth', 1);
yline(nanmean(diff_ASA) - 1.96*nanstd(diff_ASA), 'r--', 'LineWidth', 1);
xlabel('Mean ASA (deg)', 'FontSize', 10, 'Interpreter', 'latex');
ylabel('$\Delta$ASA (deg)', 'FontSize', 10, 'Interpreter', 'latex');
title(sprintf('(c) ASA: $\\mu$=%.2f, $\\sigma$=%.2f deg', nanmean(diff_ASA), nanstd(diff_ASA)), 'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'latex');
grid on; set(gca, 'FontSize', 9);

subplot(2,2,4);
scatter(mean_ASD(los_mask), diff_ASD(los_mask), 40, colors.LOS, 'filled'); hold on;
scatter(mean_ASD(nlos_mask), diff_ASD(nlos_mask), 40, colors.NLOS, 'filled');
yline(nanmean(diff_ASD), 'k-', 'LineWidth', 1.5);
yline(nanmean(diff_ASD) + 1.96*nanstd(diff_ASD), 'r--', 'LineWidth', 1);
yline(nanmean(diff_ASD) - 1.96*nanstd(diff_ASD), 'r--', 'LineWidth', 1);
xlabel('Mean ASD (deg)', 'FontSize', 10, 'Interpreter', 'latex');
ylabel('$\Delta$ASD (deg)', 'FontSize', 10, 'Interpreter', 'latex');
title(sprintf('(d) ASD: $\\mu$=%.2f, $\\sigma$=%.2f deg', nanmean(diff_ASD), nanstd(diff_ASD)), 'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'latex');
grid on; set(gca, 'FontSize', 9);

saveFigure(fig8, paths.figures, 'Fig8_BlandAltman');

fprintf('Figures saved to: %s\n\n', paths.figures);

%% SECTION 6: SAVE RESULTS
fprintf('Saving results...\n');


% =========================================================================
% Create results table for CSV/Excel
% =========================================================================
T_all = table(results.Location_ID, results.Environment, results.Distance_m, ...
    results.PL_NYU, results.PL_USC, results.PL_NYU - results.PL_USC, ...
    results.DS_NYU, results.DS_USC, results.DS_NYU - results.DS_USC, ...
    results.ASA_NYU_10dB, results.ASA_NYU_15dB, results.ASA_NYU_20dB, results.ASA_USC, ...
    results.ASD_NYU_10dB, results.ASD_NYU_15dB, results.ASD_NYU_20dB, results.ASD_USC, ...
    'VariableNames', {'Location', 'Env', 'Distance_m', ...
    'PL_NYU_dB', 'PL_USC_dB', 'Delta_PL_dB', ...
    'DS_NYU_ns', 'DS_USC_ns', 'Delta_DS_ns', ...
    'ASA_NYU_10dB', 'ASA_NYU_15dB', 'ASA_NYU_20dB', 'ASA_USC', ...
    'ASD_NYU_10dB', 'ASD_NYU_15dB', 'ASD_NYU_20dB', 'ASD_USC'});

% =========================================================================
% Create LOS summary table
% =========================================================================
metrics = {'PL_NYU', 'PL_USC', 'DS_NYU', 'DS_USC', 'ASA_NYU_10dB', 'ASA_NYU_15dB', 'ASA_NYU_20dB', 'ASA_USC', 'ASD_NYU_10dB', 'ASD_NYU_15dB', 'ASD_NYU_20dB', 'ASD_USC'};
stats = {'Mean', 'Std', 'Min', 'Max'};
T_los = table();
for i = 1:length(metrics)
    data = results.(metrics{i})(los_mask);
    T_los.(metrics{i}) = [nanmean(data); nanstd(data); nanmin(data); nanmax(data)];
end
T_los.Properties.RowNames = stats;

% =========================================================================
% Create NLOS summary table
% =========================================================================
T_nlos = table();
for i = 1:length(metrics)
    data = results.(metrics{i})(nlos_mask);
    T_nlos.(metrics{i}) = [nanmean(data); nanstd(data); nanmin(data); nanmax(data)];
end
T_nlos.Properties.RowNames = stats;

% =========================================================================
% Create Overall summary table
% =========================================================================
T_overall = table();
for i = 1:length(metrics)
    data = results.(metrics{i});
    T_overall.(metrics{i}) = [nanmean(data); nanstd(data); nanmin(data); nanmax(data)];
end
T_overall.Properties.RowNames = stats;

% =========================================================================
% Create Method Comparison summary table
% =========================================================================
T_comparison = table();
T_comparison.Metric = {'Delta_PL_LOS'; 'Delta_PL_NLOS'; 'Delta_PL_ALL'; ...
    'Delta_DS_LOS'; 'Delta_DS_NLOS'; 'Delta_DS_ALL'; ...
    'Delta_ASA_LOS'; 'Delta_ASA_NLOS'; 'Delta_ASA_ALL'};
T_comparison.Mean = [...
    mean(results.PL_NYU(los_mask) - results.PL_USC(los_mask)); ...
    mean(results.PL_NYU(nlos_mask) - results.PL_USC(nlos_mask)); ...
    mean(results.PL_NYU - results.PL_USC); ...
    nanmean(results.DS_NYU(los_mask) - results.DS_USC(los_mask)); ...
    nanmean(results.DS_NYU(nlos_mask) - results.DS_USC(nlos_mask)); ...
    nanmean(results.DS_NYU - results.DS_USC); ...
    nanmean(results.ASA_NYU_10dB(los_mask) - results.ASA_USC(los_mask)); ...
    nanmean(results.ASA_NYU_10dB(nlos_mask) - results.ASA_USC(nlos_mask)); ...
    nanmean(results.ASA_NYU_10dB - results.ASA_USC)];
T_comparison.Std = [...
    std(results.PL_NYU(los_mask) - results.PL_USC(los_mask)); ...
    std(results.PL_NYU(nlos_mask) - results.PL_USC(nlos_mask)); ...
    std(results.PL_NYU - results.PL_USC); ...
    nanstd(results.DS_NYU(los_mask) - results.DS_USC(los_mask)); ...
    nanstd(results.DS_NYU(nlos_mask) - results.DS_USC(nlos_mask)); ...
    nanstd(results.DS_NYU - results.DS_USC); ...
    nanstd(results.ASA_NYU_10dB(los_mask) - results.ASA_USC(los_mask)); ...
    nanstd(results.ASA_NYU_10dB(nlos_mask) - results.ASA_USC(nlos_mask)); ...
    nanstd(results.ASA_NYU_10dB - results.ASA_USC)];

% =========================================================================
% Save as CSV
% =========================================================================
writetable(T_all, fullfile(paths.output, 'USC145GHz_Full_Results.csv'));

% =========================================================================
% Save as Excel with multiple sheets
% =========================================================================
xlsx_file = fullfile(paths.output, 'USC145GHz_Full_Results.xlsx');
if exist(xlsx_file, 'file'), delete(xlsx_file); end
writetable(T_all, xlsx_file, 'Sheet', 'All_Results');
writetable(T_los, xlsx_file, 'Sheet', 'LOS_Summary', 'WriteRowNames', true);
writetable(T_nlos, xlsx_file, 'Sheet', 'NLOS_Summary', 'WriteRowNames', true);
writetable(T_overall, xlsx_file, 'Sheet', 'Overall_Summary', 'WriteRowNames', true);
writetable(T_comparison, xlsx_file, 'Sheet', 'Method_Comparison');

% =========================================================================
% Save as MAT
% =========================================================================
save(fullfile(paths.output, 'USC145GHz_Full_Results.mat'), ...
    'results', 'T_all', 'T_los', 'T_nlos', 'T_overall', 'T_comparison', ...
    'params', 'config', 'pdp_store', 'aps_store');

fprintf('\n═══════════════════════════════════════════════════════════════════════\n');
fprintf('  Results saved to: %s\n', paths.output);
fprintf('    - USC145GHz_Full_Results.csv (flat table)\n');
fprintf('    - USC145GHz_Full_Results.xlsx (5 sheets)\n');
fprintf('    - USC145GHz_Full_Results.mat (MATLAB format)\n');
fprintf('  Figures saved to: %s\n', paths.figures);
fprintf('═══════════════════════════════════════════════════════════════════════\n');
fprintf('\nDone!\n');

%% =========================================================================
%  HELPER FUNCTIONS
%  =========================================================================

function noise_floor = noise_floor_calc_v2(pdp)
    % =========================================================================
    % USC Ground Truth Noise Floor Calculation
    % (from noise_floor_calc_v2.m)
    %
    % Given the PDP (in LINEAR scale), estimate the noise floor in dB
    % Uses 25th percentile + 5.41 dB correction
    % =========================================================================
    pdp_sort2 = sort(10*log10(pdp));  % Sort energy in ascending manner (dB)
    pdp_sort = pdp_sort2(isfinite(pdp_sort2));  % Eliminate any -Inf from the PDP
    N = length(pdp_sort);
    N_noise = max(1, round(N/4));  % 25th percentile
    Noise_value = pdp_sort(N_noise);
    noise_floor = Noise_value + 5.41;  % +5.41 dB because it's 1st quartile instead of median
end

function rmsds = computeDSonMPC(delay_vec, power_vec)
    % =========================================================================
    % NYU's RMS Delay Spread Calculation (from computeDSonMPC.m)
    %
    % Inputs:
    %   delay_vec: Delay vector in ns (only valid MPCs above threshold)
    %   power_vec: Power vector in dB (only valid MPCs above threshold)
    %
    % Output:
    %   rmsds: RMS delay spread in ns
    %
    % Formula: sqrt(E[τ²] - E[τ]²) where E[] is power-weighted average
    % =========================================================================
    if isempty(delay_vec) || length(delay_vec) < 2
        rmsds = 0;
        return;
    end

    % Ensure column vectors
    delay_vec = delay_vec(:);
    power_vec = power_vec(:);

    % Convert power from dB to linear
    power_vec_linear = db2pow(power_vec);

    % Compute power-weighted mean delay
    meann = delay_vec' * power_vec_linear / sum(power_vec_linear);

    % Compute power-weighted second moment
    varr = (delay_vec.^2)' * power_vec_linear / sum(power_vec_linear);

    % RMS delay spread
    rmsds = sqrt(max(0, varr - meann^2));

    % Handle numerical issues
    if imag(rmsds) < 1e-3
        rmsds = real(rmsds);
    end
end

function pattern = load_antenna_pattern(filepath)
    % Load antenna pattern from file
    % Supports:
    %   - USC .mat files (aziCut.mat, elevCut.mat) with aziPatternFile/elevPatternFile variable
    %   - NYU .DAT files (plain text, two columns: angle, gain)
    % Output: Nx2 matrix [angle_deg, gain_dB]
    try
        [~, ~, ext] = fileparts(filepath);
        if strcmpi(ext, '.mat')
            % Load USC .mat format
            data = load(filepath);
            if isfield(data, 'aziPatternFile')
                pattern = data.aziPatternFile;
            elseif isfield(data, 'elevPatternFile')
                pattern = data.elevPatternFile;
            else
                % Get first field
                fields = fieldnames(data);
                pattern = data.(fields{1});
            end
        else
            % Load NYU .DAT format (plain text)
            pattern = load(filepath);
        end
        pattern = sortrows(pattern, 1);
    catch ME
        warning('Could not load antenna pattern from %s: %s', filepath, ME.message);
        % Return a flat pattern (0 dB for all angles)
        pattern = [(-90:90)', zeros(181, 1)];
    end
end

function [ASA_NYU_10, ASA_NYU_15, ASA_NYU_20, ASA_USC, ...
          ASD_NYU_10, ASD_NYU_15, ASD_NYU_20, ASD_USC, aps_data] = ...
        compute_AS_from_PDP(PDP_dir_lin_thresh, params, config, antenna_pattern)
    % =========================================================================
    % Compute Angular Spread from PDP data (already thresholded)
    %
    % Input:
    %   PDP_dir_lin_thresh: 5D PDP array [Nf × N_aztx × N_eltx × N_azrx × N_elrx]
    %                       Already has USC PDP threshold applied
    %   params: System parameters (txAz, rxAz, etc.)
    %   config: Configuration (PAS thresholds)
    %   antenna_pattern: Antenna pattern for NYU lobe expansion
    %
    % This function implements both NYU and USC Angular Spread methods:
    %   - NYU: PAS threshold + antenna pattern lobe expansion + 3GPP formula
    %   - USC: No PAS threshold, direct 3GPP formula
    %
    % Both use the SAME PDP threshold (global noise + 12dB) for fair comparison.
    % =========================================================================

    % =========================================================================
    % Step 1: Form Angular Power Spectrum (APS)
    % Sum over delay, then sum over elevations
    % =========================================================================
    % PDP_dir_lin_thresh is [Nf × N_aztx × N_eltx × N_azrx × N_elrx]

    % Sum over delay (dim 1)
    Power_per_antenna = squeeze(sum(PDP_dir_lin_thresh, 1));  % [N_aztx × N_eltx × N_azrx × N_elrx]

    % Sum over elevations (TX El dim=2, RX El dim=4)
    APS_Total = squeeze(sum(sum(Power_per_antenna, 4), 2));  % [N_aztx × N_azrx]

    % APS for TX (sum over RX azimuth) - Azimuth Spread of Departure (ASD)
    APS_Tx = sum(APS_Total, 2);  % [N_aztx × 1]

    % APS for RX (sum over TX azimuth) - Azimuth Spread of Arrival (ASA)
    APS_Rx = sum(APS_Total, 1).';  % [N_azrx × 1]

    % Store APS for visualization
    aps_data.APS_Tx = APS_Tx;
    aps_data.APS_Rx = APS_Rx;
    aps_data.angles_Tx = params.txAz;
    aps_data.angles_Rx = params.rxAz;

    % =========================================================================
    % Step 2: NYU AS Method - Apply PAS threshold + antenna pattern expansion
    % =========================================================================
    % Based on NYU's original code:
    %   - boundaryMPCsD.m: finds boundary angles using antenna pattern
    %   - lobeShaperCounterD.m: detects lobes in power angular spectrum
    %   - circ_std.m: computes 3GPP circular standard deviation
    %
    % The antenna pattern expansion ensures that even a single measurement
    % angle is expanded into a spatial lobe based on the antenna beamwidth,
    % avoiding the AS=0 issue when only one angle passes threshold.
    % =========================================================================

    % ASA with different thresholds
    ASA_NYU_10 = compute_AS_NYU_method(params.rxAz, APS_Rx, config.PAS_threshold_1, antenna_pattern);
    ASA_NYU_15 = compute_AS_NYU_method(params.rxAz, APS_Rx, config.PAS_threshold_2, antenna_pattern);
    ASA_NYU_20 = compute_AS_NYU_method(params.rxAz, APS_Rx, config.PAS_threshold_3, antenna_pattern);

    % ASD with different thresholds
    ASD_NYU_10 = compute_AS_NYU_method(params.txAz, APS_Tx, config.PAS_threshold_1, antenna_pattern);
    ASD_NYU_15 = compute_AS_NYU_method(params.txAz, APS_Tx, config.PAS_threshold_2, antenna_pattern);
    ASD_NYU_20 = compute_AS_NYU_method(params.txAz, APS_Tx, config.PAS_threshold_3, antenna_pattern);

    % =========================================================================
    % Step 3: USC AS Method - No PAS threshold, direct 3GPP formula
    % All angles contribute to the angular spread calculation
    % =========================================================================
    ASA_USC = compute_AS_3GPP(params.rxAz, APS_Rx);
    ASD_USC = compute_AS_3GPP(params.txAz, APS_Tx);
end

function AS = compute_AS_NYU_method(angles, powers, pas_threshold_dB, antenna_pattern)
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
    % =========================================================================

    % USC 145 GHz Horn Antenna HPBW (from aziCut.mat and elevCut.mat):
    %   Azimuth (H-plane):   17.2 degrees
    %   Elevation (E-plane): 14.0 degrees
    %   Average HPBW:        15.6 degrees
    % Using measurement grid azimuth step (10 deg) as effective HPBW for lobe detection
    % (conservative value since grid resolution limits angular sampling)
    HPBW = 10;  % degrees

    angles = angles(:);
    powers = powers(:);

    if isempty(powers) || max(powers) <= 0
        AS = 0;
        return;
    end

    % Convert to dB for threshold comparison
    powers_dB = 10*log10(powers + eps);
    peak_dB = max(powers_dB);
    threshold_dB = peak_dB - pas_threshold_dB;

    % Find angles above threshold
    mask = powers_dB >= threshold_dB;

    if ~any(mask)
        % If nothing above threshold, keep peak only
        [~, idx] = max(powers);
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
        % Compute angular differences (handle wraparound for 0-360)
        angle_step = median(diff(angles(angles > 0)));  % Typical step size
        if isempty(angle_step) || isnan(angle_step)
            angle_step = HPBW;
        end

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
            % ref_power1 = power at lobe boundary (dB)
            % SLT = threshold (dB) = peak - 10dB
            % ref_power1 - SLT = how much above threshold the boundary is
            % We find where antenna pattern gain matches this difference
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

    % Normalize weights
    all_powers_lin = all_powers_lin / sum(all_powers_lin);

    % =========================================================================
    % Step 4: Compute AS using 3GPP formula (circ_std.m)
    % s0 = sqrt(-2*log(r)) where r = |sum(w * exp(j*theta))|
    % =========================================================================
    AS = compute_AS_3GPP(all_angles, all_powers_lin);
end

function AS = compute_AS_3GPP(angles, powers)
    % =========================================================================
    % 3GPP Angular Spread Formula (Circular Standard Deviation)
    %
    % Formula: AS = sqrt(-2 * ln(R))
    % where R = |sum(w_i * exp(j*theta_i))| is the mean resultant length
    %
    % Based on NYU's circ_std.m line 54: s0 = sqrt(-2*log(r))
    % This is Zar Equation 26.21
    %
    % Reference: SecondaryStats_circD.m lines 45, 57:
    %   [~, omni_asd(iloc)] = circ_std(deg2rad(MPC_AOD_e), MPCpowersW);
    %   omni_asd(iloc) = rad2deg(omni_asd(iloc));
    % =========================================================================

    angles = angles(:);
    powers = powers(:);

    if isempty(powers) || sum(powers) <= 0
        AS = 0;
        return;
    end

    % Normalize weights
    w = powers / sum(powers);

    % Convert to radians
    ang_rad = deg2rad(angles);

    % Compute mean resultant vector length R
    R = abs(sum(w .* exp(1j * ang_rad)));

    % Handle edge cases
    if R >= 1
        AS = 0;  % Perfect alignment, no spread
        return;
    end
    if R <= 0
        AS = 180;  % Maximum spread
        return;
    end

    % 3GPP circular standard deviation
    s0_rad = sqrt(-2 * log(R));

    % Convert to degrees
    AS = rad2deg(s0_rad);
end

function saveFigure(fig, folder, name)
    % Save figure in multiple formats
    set(fig, 'PaperPositionMode', 'auto');
    if exist('exportgraphics', 'file')
        exportgraphics(fig, fullfile(folder, [name '.pdf']), 'ContentType', 'vector', 'BackgroundColor', 'white');
        exportgraphics(fig, fullfile(folder, [name '.png']), 'Resolution', 300, 'BackgroundColor', 'white');
    else
        saveas(fig, fullfile(folder, [name '.png']));
        print(fig, fullfile(folder, [name '.pdf']), '-dpdf', '-r300');
    end
    saveas(fig, fullfile(folder, [name '.fig']));
end

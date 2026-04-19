%% ========================================================================
%  USC 7GHz (FR3 Midband) Data: Full Method Comparison (NYU vs USC)
%  ========================================================================
%
%  PURPOSE: Unified script comparing NYU and USC processing methods on
%           USC's FR3 Midband (6.25-7.25 GHz) campaign data for:
%           - Path Loss (PL)
%           - Delay Spread (DS)
%           - Angular Spread (ASA, ASD)
%
%  =========================================================================
%  PROCESSING METHOD
%  =========================================================================
%  PDP Processing (USC ground truth from Parameter_eval_multielev_6_14GHz.mlx):
%    1. Load H matrix (frequency domain channel) [Nf_orig, 13, 36, 5]
%    2. Slice to 6-7 GHz band: H = H(1:1001,:,:,:)
%    3. Apply Hann windowing with normalization:
%       wf = hann(Nf+1,'Periodic'); wf = wf(1:end-1);
%       wf = sqrt(mean(abs(wf).^2))^(-1)*wf;
%    4. Compute CIR via IFFT: h_delay = ifft(H.*wf_rep, [], 1)
%    5. Compute PDP: PDP_dir = |h_delay|^2
%    6. Noise threshold: max noise + 12 dB, override with DR=22 dB cap
%    7. Flip TX azimuth: flip(PDP_dir, 2)
%    8. Omni PDP (USC): Sum RxEl -> Max RxAz -> Max TxAz
%    9. Apply circshift for delay offset when d_LOS >= 50m
%   10. Apply delay gating: t_gate = (d(end)+d_LOS-10)/3e8
%
%  DATA FORMAT: 4D matrix [Nf, N_aztx, N_azrx, N_elrx] = [1001, 13, 36, 5]
%    - NO TX elevation dimension (unlike THz 5D data)
%    - Nf = 1001 frequency points (6.25-7.25 GHz, 1 GHz BW)
%    - N_aztx = 13 TX azimuths (-60:10:60 deg)
%    - N_azrx = 36 RX azimuths (0:10:350 deg)
%    - N_elrx = 5 RX elevations (-20:10:20 deg)
%
%  =========================================================================
%  METHOD COMPARISON SUMMARY
%  =========================================================================
%
%  COMMON SETTINGS (Both Methods):
%    - PDP Threshold: USC's noise + 12dB with DR=22dB cap
%    - PDP flip: flip(PDP_dir, 2) on TX azimuth
%    - AS Formula: 3GPP sqrt(-2*ln(R)) [degrees]
%
%  DIFFERENCES:
%    | Metric | Aspect          | NYU Method              | USC Method              |
%    |--------|-----------------|-------------------------|-------------------------|
%    | PL/DS  | Omni Synthesis  | SUM across directions   | perDelayMax (max/delay) |
%    | AS     | PAS Threshold   | 10/15/20 dB below peak  | NONE                    |
%    | AS     | Lobe Expansion  | Antenna pattern-based   | NONE                    |
%
%  DATA SOURCE:
%    - H matrix: USC FR3 Midband PDP files (6.25-7.25 GHz)
%    - All 8 locations are NLOS (OLOS treated as NLOS)
%    - PL = -10*log10(sum(PDP_omni)) [calibrated H, no gain correction]
%
%  Author: Mingjun Ying
%  Date: February 2026
%  Version: 1.0 (Adapted from USC 145GHz template for 4D FR3 data)
%
%  ========================================================================

%% SECTION 0: CLEAR ENVIRONMENT
clear; clc; close all;

%% SECTION 1: CONFIGURATION
% =========================================================================
% SYSTEM PARAMETERS (USC FR3 Midband 6.25-7.25 GHz)
% =========================================================================
% NOTE: This script loads the H matrix and computes PDP using USC's exact
% method from Parameter_eval_multielev_6_14GHz.mlx:
%   - Hann windowing with normalization before IFFT
%   - PDP = |ifft(H.*window)|^2
%   - Noise threshold: max noise + 12 dB, capped at DR=22 dB
%   - PDP flip on TX azimuth
%   - Path loss: PL = -10*log10(sum(PDP_omni)) [calibrated, no gain correction]
% =========================================================================
params.Frequency_GHz = 6.75;          % Center frequency (6.25-7.25 GHz band)
% TX power and antenna gains NOT needed - PL computed from calibrated H
% USC's H matrix already has antenna gains removed

% Antenna beamwidth settings
params.HPBW = 10;                     % Grid step for lobe detection (degrees)
params.Az_step = 10;                  % Azimuth rotation step
params.El_step = 10;                  % Elevation rotation step

% =========================================================================
% DATA PARAMETERS (from Parameter_eval_multielev_6_14GHz.mlx)
% =========================================================================
params.BW = 1e9;                      % Bandwidth = 1 GHz
params.Nf = 1001;                     % Number of frequency/delay samples
params.dt = 1/params.BW;             % Time resolution = 1 ns
params.n_oversamp = 10;               % USC oversampling factor for RMS-DS
params.c = 3e8;                       % Speed of light [m/s]
params.delayGate_ns = 966.67;         % Max delay gate in ns (matches USC 145 + NYU DS_DELAY_GATE_NS)

% Distance vector (from USC ground truth code)
% d = (0:Nf-1)*3e8/BW where 3e8/1e9 = 0.3 m/sample
params.d_vec_m = (0:params.Nf-1) * params.c / params.BW;  % [0, 0.3, 0.6, ... 300] m
params.d2_vec_m = (0:1/params.n_oversamp:params.Nf-1/params.n_oversamp) * params.c / params.BW;  % Oversampled

% Angular grid dimensions (4D: NO TX elevation)
params.N_aztx = 13;                   % TX azimuth positions
params.N_azrx = 36;                   % RX azimuth positions
params.N_elrx = 5;                    % RX elevation positions
params.txAz = (-60:10:60).';          % TX azimuth angles [deg]
params.rxAz = (0:10:350).';           % RX azimuth angles [deg]
params.rxEl = (-20:10:20).';          % RX elevation angles [deg]

% =========================================================================
% CORRECTION FACTORS
% =========================================================================
% NO correction factor for FR3 — no TX elevation summing (unlike THz -1.95 dB)
params.correction_factor_dB = 0;
params.correction_factor_lin = 1;

% =========================================================================
% THRESHOLD SETTINGS
% =========================================================================
% PDP Threshold (USC FR3 method - noise + 12dB with DR=22dB cap)
config.noise_margin_dB = 12;          % dB above max noise floor
config.max_dynamic_range_dB = 22;     % Maximum dynamic range cap

% PAS Threshold (NYU AS method only)
config.PAS_threshold_1 = 10;          % Strictest: 10 dB below peak
config.PAS_threshold_2 = 15;          % Medium: 15 dB below peak
config.PAS_threshold_3 = 20;          % Relaxed: 20 dB below peak
config.multipath_low_bound = -100;    % Absolute floor in dB

% =========================================================================
% ANTENNA PATTERN FILES (for NYU AS lobe expansion)
% =========================================================================
% Using NYU's 7 GHz antenna pattern for AS lobe interpolation
config.antenna_pattern_path = 'D:\NYU-USC\Cross-Processing\ProcessingNYU7GHzData';
config.azi_pattern_file = '7_phi0_pd.mat';       % NYU 7 GHz azimuth pattern
config.elev_pattern_file = '7_phi90_pd.mat';     % NYU 7 GHz elevation pattern

% =========================================================================
% IEEE FIGURE SETTINGS FOR DOUBLE-COLUMN JOURNAL
% =========================================================================
IEEE_DOUBLE_COL_WIDTH = 7.0;          % Full page width (~7.16" max)
IEEE_SINGLE_COL_WIDTH = 3.5;          % Single column width

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
% USC FR3 Midband PDP data (8 locations, all NLOS)
paths.data = 'D:\NYU-USC\Cross-Processing\USC\USC_Data\Midband (FR3) data PDP\Midband (FR3) data PDP';

% Output paths
paths.output = 'D:\NYU-USC\Cross-Processing\ProcessingUSC7GHzData\Results';
paths.figures = 'D:\NYU-USC\Cross-Processing\ProcessingUSC7GHzData\Figures';

% Create output directories
if ~exist(paths.output, 'dir'), mkdir(paths.output); end
if ~exist(paths.figures, 'dir'), mkdir(paths.figures); end

% =========================================================================
% FILE LISTS WITH DISTANCES
% =========================================================================
% Column 1: PDP file name
% Column 2: Distance (m)
% Column 3: Original environment label
% All OLOS treated as NLOS per user decision
NLOS_files = {
    'PDP_162m_OLOS_MIDBAND_03-18-24.mat',       162,     'OLOS';
    'PDP_199.39m_NLOS_MIDBAND_06-15-24.mat',     199.39,  'NLOS';
    'PDP_201m_NLOS_MIDBAND_03-27-24.mat',        201,     'NLOS';
    'PDP_211m_OLOS_MIDBAND_03-27-24.mat',        211,     'OLOS';
    'PDP_331.8m_OLOS_MIDBAND_04-14-24.mat',      331.8,   'OLOS';
    'PDP_400m_OLOS_MIDBAND_04-14-24.mat',        400,     'OLOS';
    'PDP_443m_NLOS_MIDBAND_04-17-24.mat',        443,     'NLOS';
    'PDP_500m_NLOS_MIDBAND_04-17-24.mat',        500,     'NLOS';
};

% Display configuration
fprintf('=======================================================================\n');
fprintf('  USC 7GHz (FR3 Midband) Data: Full Method Comparison (NYU vs USC)\n');
fprintf('=======================================================================\n');
fprintf('  Frequency: %.2f GHz (6.25-7.25 GHz band)\n', params.Frequency_GHz);
fprintf('  Data Format: 4D [Nf=%d, N_aztx=%d, N_azrx=%d, N_elrx=%d]\n', ...
    params.Nf, params.N_aztx, params.N_azrx, params.N_elrx);
fprintf('  PDP Threshold: Global max noise + %d dB (DR cap = %d dB)\n', ...
    config.noise_margin_dB, config.max_dynamic_range_dB);
fprintf('  Omni Synthesis: NYU=SUM, USC=perDelayMax\n');
fprintf('  PAS Thresholds: %d dB, %d dB, %d dB (NYU AS only)\n', ...
    config.PAS_threshold_1, config.PAS_threshold_2, config.PAS_threshold_3);
fprintf('  AS Formula: 3GPP sqrt(-2*ln(R)) [degrees]\n');
fprintf('  Correction Factor: %.2f dB (no TX elev summing)\n', params.correction_factor_dB);
fprintf('  Locations: 0 LOS + 8 NLOS (OLOS -> NLOS)\n');
fprintf('=======================================================================\n\n');

%% SECTION 2: LOAD ANTENNA PATTERN AND INITIALIZE RESULTS
% =========================================================================
% Load antenna pattern for NYU AS lobe expansion
% =========================================================================
% The antenna pattern is used in NYU's method to expand each measurement
% angle into a spatial lobe based on the antenna beamwidth. This follows
% NYU's original implementation in boundaryMPCsD.m and lobeShaperCounterD.m.
antenna_azi = load_antenna_pattern_mat(fullfile(config.antenna_pattern_path, config.azi_pattern_file));
fprintf('Antenna pattern loaded: %d points\n', size(antenna_azi, 1));

% =========================================================================
% Initialize results storage
% =========================================================================
nFiles = size(NLOS_files, 1);

results = struct();
results.Location_ID = cell(nFiles, 1);
results.Environment = cell(nFiles, 1);
results.Distance_m = zeros(nFiles, 1);
results.OrigLabel = cell(nFiles, 1);

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

% Store noise threshold and path gain for reference
results.NoiseThresh_dB = zeros(nFiles, 1);
results.PG_omni_USC = zeros(nFiles, 1);  % For cross-check with USC parameters

% Store PDP and APS data for visualization
pdp_store = struct();
aps_store = struct();

%% SECTION 3: PROCESS ALL LOCATIONS
fprintf('=====================================================================\n');
fprintf('    Processing USC FR3 7GHz Data: PL, DS, and AS (NYU vs USC Methods)\n');
fprintf('=====================================================================\n\n');

fprintf('Processing NLOS locations (all 8)...\n');
fprintf('---------------------------------------------------------------------\n');

for iLoc = 1:nFiles
    fileName_PDP = NLOS_files{iLoc, 1};
    TR_distance = NLOS_files{iLoc, 2};
    d_LOS = TR_distance;  % USC naming convention
    origLabel = NLOS_files{iLoc, 3};

    % Extract location ID from filename
    tokens = regexp(fileName_PDP, '(\d+\.?\d*)m_', 'tokens');
    if ~isempty(tokens)
        Location_ID = sprintf('%.0fm_%s', str2double(tokens{1}{1}), origLabel);
    else
        Location_ID = sprintf('Loc%02d', iLoc);
    end

    fprintf('Processing [%d/%d] %s (d=%.1f m) ... ', iLoc, nFiles, Location_ID, TR_distance);

    % =====================================================================
    % STEP 1: Load H matrix and slice to 6-7 GHz
    % =====================================================================
    fullPath_PDP = fullfile(paths.data, fileName_PDP);
    data = load(fullPath_PDP);

    % Find the H matrix variable (could be H, h_delay, or PDP_dir)
    fnames = fieldnames(data);
    H_found = false;
    for fn = 1:length(fnames)
        varData = data.(fnames{fn});
        if ndims(varData) >= 4 && size(varData, 2) == params.N_aztx && ...
           size(varData, 3) == params.N_azrx && size(varData, 4) == params.N_elrx
            % Check if this is H (complex) or PDP_dir (real)
            if ~isreal(varData)
                H = varData;
                H_found = true;
                fprintf('[H from %s] ', fnames{fn});
                break;
            end
        end
    end

    if ~H_found
        % Try to find H specifically
        if isfield(data, 'H')
            H = data.H;
            H_found = true;
        else
            % If only PDP_dir is available, use it directly
            for fn = 1:length(fnames)
                varData = data.(fnames{fn});
                if ndims(varData) >= 4 && size(varData, 2) == params.N_aztx && ...
                   size(varData, 3) == params.N_azrx && size(varData, 4) == params.N_elrx
                    if strcmpi(fnames{fn}, 'PDP_dir')
                        % PDP already computed, skip IFFT
                        PDP_dir = varData(1:params.Nf, :, :, :);
                        H_found = true;
                        fprintf('[PDP_dir direct] ');
                        break;
                    end
                end
            end
        end
    end

    if ~H_found
        warning('Could not find H matrix in %s. Skipping.', fileName_PDP);
        continue;
    end

    % Slice to 6-7 GHz band (first 1001 frequency points)
    if exist('H', 'var') && ~isreal(H)
        Nf_orig = size(H, 1);
        H = H(1:params.Nf, :, :, :);  % [1001, 13, 36, 5]

        % =====================================================================
        % STEP 2: Hann windowing + IFFT -> CIR -> PDP
        % =====================================================================
        Nf = params.Nf;
        wf = hann(Nf+1, 'Periodic');
        wf = wf(1:end-1);
        wf = sqrt(mean(abs(wf).^2))^(-1) * wf;  % Normalize window
        wf_rep = repmat(wf, [1, params.N_aztx, params.N_azrx, params.N_elrx]);

        % Compute CIR via IFFT
        h_delay = ifft(H .* wf_rep, [], 1);

        % Compute PDP
        PDP_dir = abs(h_delay).^2;
        clear H h_delay;  % Free memory
    end

    % =====================================================================
    % STEP 3: Noise threshold calculation (USC FR3 method)
    % =====================================================================
    % Per-direction noise: 25th percentile + 5.41 dB
    noise_temp = zeros(params.N_aztx, params.N_azrx, params.N_elrx);
    for az_tx = 1:params.N_aztx
        for az_rx = 1:params.N_azrx
            for el_rx = 1:params.N_elrx
                pdp_temp = squeeze(PDP_dir(:, az_tx, az_rx, el_rx));
                noise_temp(az_tx, az_rx, el_rx) = noise_floor_calc_v2(pdp_temp);
            end
        end
    end

    max_noise = max(noise_temp(:));
    noise_thresh_dB = max_noise + config.noise_margin_dB;  % +12 dB

    % Dynamic range cap (from USC FR3 reference code lines 112-114)
    max_power_all_dB = 10*log10(max(PDP_dir(:)));
    DR = max_power_all_dB - noise_thresh_dB;

    % Override with DR-based threshold if dynamic range > 22 dB
    if DR > config.max_dynamic_range_dB
        noise_thresh_dB_original = noise_thresh_dB;
        noise_thresh_dB = max_power_all_dB - config.max_dynamic_range_dB;
        fprintf('[DR=%.1f>%d, thresh: %.1f->%.1f] ', ...
            DR, config.max_dynamic_range_dB, noise_thresh_dB_original, noise_thresh_dB);
    end

    noise_thresh_lin = 10^(noise_thresh_dB/10);

    % Apply threshold
    PDP_dir_thresh = PDP_dir;
    PDP_dir_thresh(PDP_dir <= noise_thresh_lin) = 0;

    % =====================================================================
    % STEP 4: Flip TX azimuth (from USC FR3 reference code line 119)
    % =====================================================================
    PDP_dir_thresh = flip(PDP_dir_thresh, 2);

    % =====================================================================
    % STEP 5: Delay gating setup
    % =====================================================================
    d = params.d_vec_m;
    d2 = params.d2_vec_m;

    if d_LOS >= 50
        t_gate = (d(end) + d_LOS - 10) / params.c;  % FR3-specific
    else
        t_gate = (d(end) - 10) / params.c;
    end

    % =====================================================================
    % STEP 6: NYU SUM Omni PDP
    % =====================================================================
    % Sum all spatial dimensions [Nf, 13, 36, 5] -> [Nf, 1]
    PDP_omni_NYU = squeeze(sum(PDP_dir_thresh, [2, 3, 4]));

    % Apply circshift + delay gating (FR3-specific: d_LOS >= 50)
    if d_LOS >= 50
        PDP_omni_NYU = circshift(PDP_omni_NYU, -round((d_LOS - 10) / d(2)));
        PDP_omni_NYU = PDP_omni_NYU .* (((d + d_LOS - 10) / params.c) <= t_gate).';
    else
        PDP_omni_NYU = PDP_omni_NYU .* ((d / params.c) <= t_gate).';
    end

    Pr_NYU = sum(PDP_omni_NYU);

    % =====================================================================
    % STEP 7: USC perDelayMax Omni PDP (4D version)
    % =====================================================================
    % Sum RxEl (dim 4) -> Max RxAz (dim 3) -> Max TxAz (dim 2)
    PDP_temp1 = squeeze(sum(PDP_dir_thresh, 4));       % Sum RxEl -> [Nf, 13, 36]
    PDP_temp2 = squeeze(max(PDP_temp1, [], 3));        % Max RxAz -> [Nf, 13]
    PDP_omni_USC = squeeze(max(PDP_temp2, [], 2));     % Max TxAz -> [Nf, 1]

    % Apply circshift + delay gating (FR3-specific)
    if d_LOS >= 50
        PDP_omni_USC = circshift(PDP_omni_USC, -round((d_LOS - 10) / d(2)));
        PDP_omni_USC = PDP_omni_USC .* (((d + d_LOS - 10) / params.c) <= t_gate).';
    else
        PDP_omni_USC = PDP_omni_USC .* ((d / params.c) <= t_gate).';
    end

    Pr_USC = sum(PDP_omni_USC);

    % =====================================================================
    % STEP 8: Path Loss (PL = -10*log10(sum(PDP_omni)))
    % =====================================================================
    % USC's H matrix is calibrated - gains already removed
    if Pr_NYU > 0
        PL_NYU = -10*log10(Pr_NYU);
    else
        PL_NYU = NaN;
        warning('NYU SUM power <= 0 for %s', Location_ID);
    end

    if Pr_USC > 0
        PL_USC = -10*log10(Pr_USC);
    else
        PL_USC = NaN;
        warning('USC perDelayMax power <= 0 for %s', Location_ID);
    end

    % Path Gain for cross-check with USC parameter files
    PG_omni = 10*log10(Pr_USC + eps);

    % =====================================================================
    % STEP 9: RMS Delay Spread using NYU's computeDSonMPC approach
    % =====================================================================
    % Build delay vector in ns (after circshift and gating)
    if d_LOS >= 50
        delay_vec_ns = (d + d_LOS - 10) / params.c * 1e9;  % Convert m to ns
    else
        delay_vec_ns = d / params.c * 1e9;
    end

    % Convert omni PDPs to dB for computeDSonMPC
    PDP_omni_NYU_dB = 10*log10(PDP_omni_NYU + eps);
    PDP_omni_USC_dB = 10*log10(PDP_omni_USC + eps);

    % Naveed's convention: directional threshold only (already applied
    % upstream). Omni DS uses only the delay gate.
    delay_mask = delay_vec_ns(:) <= params.delayGate_ns;
    valid_mask_NYU = (PDP_omni_NYU(:) > 0) & delay_mask;
    valid_mask_USC = (PDP_omni_USC(:) > 0) & delay_mask;

    % Compute DS using NYU's method (computeDSonMPC style)
    DS_NYU = computeDSonMPC(delay_vec_ns(valid_mask_NYU), PDP_omni_NYU_dB(valid_mask_NYU));
    DS_USC = computeDSonMPC(delay_vec_ns(valid_mask_USC), PDP_omni_USC_dB(valid_mask_USC));

    % =====================================================================
    % STEP 10: Angular Spread from PDP Data (4D version)
    % =====================================================================
    [ASA_NYU_10, ASA_NYU_15, ASA_NYU_20, ASA_USC_val, ...
     ASD_NYU_10, ASD_NYU_15, ASD_NYU_20, ASD_USC_val, aps_data] = ...
        compute_AS_from_PDP_4D(PDP_dir_thresh, params, config, antenna_azi);

    % =====================================================================
    % STEP 11: Store results
    % =====================================================================
    results.Location_ID{iLoc} = Location_ID;
    results.Environment{iLoc} = 'NLOS';  % All OLOS -> NLOS
    results.OrigLabel{iLoc} = origLabel;
    results.Distance_m(iLoc) = TR_distance;
    results.PL_NYU(iLoc) = PL_NYU;
    results.PL_USC(iLoc) = PL_USC;
    results.DS_NYU(iLoc) = DS_NYU;
    results.DS_USC(iLoc) = DS_USC;
    results.NoiseThresh_dB(iLoc) = noise_thresh_dB;
    results.PG_omni_USC(iLoc) = PG_omni;
    results.ASA_NYU_10dB(iLoc) = ASA_NYU_10;
    results.ASA_NYU_15dB(iLoc) = ASA_NYU_15;
    results.ASA_NYU_20dB(iLoc) = ASA_NYU_20;
    results.ASA_USC(iLoc) = ASA_USC_val;
    results.ASD_NYU_10dB(iLoc) = ASD_NYU_10;
    results.ASD_NYU_15dB(iLoc) = ASD_NYU_15;
    results.ASD_NYU_20dB(iLoc) = ASD_NYU_20;
    results.ASD_USC(iLoc) = ASD_USC_val;

    % Store first and last NLOS data for visualization
    if iLoc == 1
        pdp_store.NLOS1.Location_ID = Location_ID;
        if d_LOS >= 50
            pdp_store.NLOS1.delays_m = d + d_LOS - 10;
        else
            pdp_store.NLOS1.delays_m = d;
        end
        pdp_store.NLOS1.OmniPDP_NYU = PDP_omni_NYU;
        pdp_store.NLOS1.OmniPDP_USC = PDP_omni_USC;
        aps_store.NLOS1 = aps_data;
        aps_store.NLOS1.Location_ID = Location_ID;
    end
    if iLoc == nFiles
        pdp_store.NLOS2.Location_ID = Location_ID;
        if d_LOS >= 50
            pdp_store.NLOS2.delays_m = d + d_LOS - 10;
        else
            pdp_store.NLOS2.delays_m = d;
        end
        pdp_store.NLOS2.OmniPDP_NYU = PDP_omni_NYU;
        pdp_store.NLOS2.OmniPDP_USC = PDP_omni_USC;
        aps_store.NLOS2 = aps_data;
        aps_store.NLOS2.Location_ID = Location_ID;
    end

    fprintf('PL: %.1f/%.1f dB | DS: %.1f/%.1f ns | ASA: %.1f/%.1f deg | PG: %.1f dB\n', ...
        PL_NYU, PL_USC, DS_NYU, DS_USC, ASA_NYU_10, ASA_USC_val, PG_omni);

    clear PDP_dir PDP_dir_thresh;  % Free memory
end

fprintf('\nProcessing complete!\n\n');

%% SECTION 4: GENERATE TABLES
% =========================================================================
% TABLE 1: Method Comparison Summary
% =========================================================================
fprintf('=====================================================================\n');
fprintf('                TABLE 1: METHOD COMPARISON SUMMARY\n');
fprintf('=====================================================================\n');
fprintf(' Aspect                 | NYU Method               | USC Method\n');
fprintf('------------------------|--------------------------|---------------------------\n');
fprintf(' PDP Threshold          | noise+12dB (DR=22dB cap) | SAME (common)\n');
fprintf(' PDP Flip               | TX azimuth flipped       | SAME (common)\n');
fprintf(' Omni Synthesis (PL/DS) | SUM across all dirs      | perDelayMax (max/delay)\n');
fprintf(' PAS Threshold (AS)     | 10/15/20 dB below peak   | NONE\n');
fprintf(' Lobe Expansion (AS)    | Antenna pattern-based    | NONE\n');
fprintf(' AS Formula             | 3GPP: sqrt(-2*ln(R))     | SAME\n');
fprintf(' Correction Factor      | None (no TX elev)        | SAME\n');
fprintf('=====================================================================\n\n');

% =========================================================================
% TABLE 2: Per-Location Results
% =========================================================================
fprintf('==========================================================================================================================================\n');
fprintf('                                             TABLE 2: PER-LOCATION RESULTS\n');
fprintf('==========================================================================================================================================\n');
fprintf('  Location          | Env  | Dist(m)  | Path Loss (dB)  | Delay Spread(ns)| ASA (degrees)                    | ASD (degrees)\n');
fprintf('                    |      |          | NYU    | USC     | NYU    | USC     | NYU-10 | NYU-15 | NYU-20 | USC  | NYU-10 | USC\n');
fprintf('--------------------+------+----------+--------+---------+--------+---------+--------+--------+--------+------+--------+------\n');

for i = 1:nFiles
    fprintf(' %-18s | %-4s | %7.1f  | %6.1f | %6.1f  | %6.1f | %6.1f  | %6.1f | %6.1f | %6.1f | %4.1f | %6.1f | %4.1f\n', ...
        results.Location_ID{i}, results.Environment{i}, results.Distance_m(i), ...
        results.PL_NYU(i), results.PL_USC(i), ...
        results.DS_NYU(i), results.DS_USC(i), ...
        results.ASA_NYU_10dB(i), results.ASA_NYU_15dB(i), results.ASA_NYU_20dB(i), results.ASA_USC(i), ...
        results.ASD_NYU_10dB(i), results.ASD_USC(i));
end
fprintf('==========================================================================================================================================\n\n');

% =========================================================================
% TABLE 3: Statistical Summary (NLOS only, since all locations are NLOS)
% =========================================================================
fprintf('==========================================================================================================================================\n');
fprintf('                                         TABLE 3: STATISTICAL SUMMARY (ALL NLOS)\n');
fprintf('==========================================================================================================================================\n');
fprintf(' Metric                         | Mean +/- Std              | Min      | Max\n');
fprintf('---------------------------------+---------------------------+----------+---------\n');

% Path Loss
fprintf(' PL - NYU (SUM)                 | %6.1f +/- %5.1f dB       | %6.1f   | %6.1f\n', ...
    nanmean(results.PL_NYU), nanstd(results.PL_NYU), nanmin(results.PL_NYU), nanmax(results.PL_NYU));
fprintf(' PL - USC (perDelayMax)         | %6.1f +/- %5.1f dB       | %6.1f   | %6.1f\n', ...
    nanmean(results.PL_USC), nanstd(results.PL_USC), nanmin(results.PL_USC), nanmax(results.PL_USC));
fprintf(' Delta PL (NYU - USC)           | %6.2f +/- %5.2f dB       |\n', ...
    nanmean(results.PL_NYU - results.PL_USC), nanstd(results.PL_NYU - results.PL_USC));
fprintf('---------------------------------+---------------------------+----------+---------\n');

% Delay Spread
fprintf(' DS - NYU (SUM)                 | %6.1f +/- %5.1f ns       | %6.1f   | %6.1f\n', ...
    nanmean(results.DS_NYU), nanstd(results.DS_NYU), nanmin(results.DS_NYU), nanmax(results.DS_NYU));
fprintf(' DS - USC (perDelayMax)         | %6.1f +/- %5.1f ns       | %6.1f   | %6.1f\n', ...
    nanmean(results.DS_USC), nanstd(results.DS_USC), nanmin(results.DS_USC), nanmax(results.DS_USC));
fprintf(' Delta DS (NYU - USC)           | %6.2f +/- %5.2f ns       |\n', ...
    nanmean(results.DS_NYU - results.DS_USC), nanstd(results.DS_NYU - results.DS_USC));
fprintf('---------------------------------+---------------------------+----------+---------\n');

% ASA
fprintf(' ASA - NYU 10dB                 | %6.1f +/- %5.1f deg      | %6.1f   | %6.1f\n', ...
    nanmean(results.ASA_NYU_10dB), nanstd(results.ASA_NYU_10dB), nanmin(results.ASA_NYU_10dB), nanmax(results.ASA_NYU_10dB));
fprintf(' ASA - NYU 15dB                 | %6.1f +/- %5.1f deg      | %6.1f   | %6.1f\n', ...
    nanmean(results.ASA_NYU_15dB), nanstd(results.ASA_NYU_15dB), nanmin(results.ASA_NYU_15dB), nanmax(results.ASA_NYU_15dB));
fprintf(' ASA - NYU 20dB                 | %6.1f +/- %5.1f deg      | %6.1f   | %6.1f\n', ...
    nanmean(results.ASA_NYU_20dB), nanstd(results.ASA_NYU_20dB), nanmin(results.ASA_NYU_20dB), nanmax(results.ASA_NYU_20dB));
fprintf(' ASA - USC (no threshold)       | %6.1f +/- %5.1f deg      | %6.1f   | %6.1f\n', ...
    nanmean(results.ASA_USC), nanstd(results.ASA_USC), nanmin(results.ASA_USC), nanmax(results.ASA_USC));
fprintf('---------------------------------+---------------------------+----------+---------\n');

% ASD
fprintf(' ASD - NYU 10dB                 | %6.1f +/- %5.1f deg      | %6.1f   | %6.1f\n', ...
    nanmean(results.ASD_NYU_10dB), nanstd(results.ASD_NYU_10dB), nanmin(results.ASD_NYU_10dB), nanmax(results.ASD_NYU_10dB));
fprintf(' ASD - NYU 15dB                 | %6.1f +/- %5.1f deg      | %6.1f   | %6.1f\n', ...
    nanmean(results.ASD_NYU_15dB), nanstd(results.ASD_NYU_15dB), nanmin(results.ASD_NYU_15dB), nanmax(results.ASD_NYU_15dB));
fprintf(' ASD - NYU 20dB                 | %6.1f +/- %5.1f deg      | %6.1f   | %6.1f\n', ...
    nanmean(results.ASD_NYU_20dB), nanstd(results.ASD_NYU_20dB), nanmin(results.ASD_NYU_20dB), nanmax(results.ASD_NYU_20dB));
fprintf(' ASD - USC (no threshold)       | %6.1f +/- %5.1f deg      | %6.1f   | %6.1f\n', ...
    nanmean(results.ASD_USC), nanstd(results.ASD_USC), nanmin(results.ASD_USC), nanmax(results.ASD_USC));
fprintf('==========================================================================================================================================\n\n');

% =========================================================================
% TABLE 4: USC Parameter Cross-Check
% =========================================================================
fprintf('=====================================================================\n');
fprintf('  TABLE 4: PATH GAIN CROSS-CHECK (USC omni PG vs reference)\n');
fprintf('=====================================================================\n');
fprintf('  Location          | PG_omni (dB) | Distance (m) | Orig Label\n');
fprintf('--------------------+--------------+--------------+----------\n');
for i = 1:nFiles
    fprintf('  %-18s | %10.2f   | %10.1f   | %s\n', ...
        results.Location_ID{i}, results.PG_omni_USC(i), results.Distance_m(i), results.OrigLabel{i});
end
fprintf('=====================================================================\n');
fprintf('  Reference: 162m OLOS PG_omni should be approx -104.43 dB\n');
fprintf('=====================================================================\n\n');

%% SECTION 5: GENERATE FIGURES
fprintf('Generating figures...\n');

% =========================================================================
% FIGURE 1: Omni PDP Comparison (Two NLOS examples)
% =========================================================================
fig1 = figure('Units', 'inches', 'Position', [1 1 IEEE_DOUBLE_COL_WIDTH 2.8], 'Name', 'Fig1: Omni PDP');

if isfield(pdp_store, 'NLOS1')
    subplot(1,2,1);
    plot(pdp_store.NLOS1.delays_m, 10*log10(pdp_store.NLOS1.OmniPDP_NYU + eps), ...
        'Color', colors.NYU_10dB, 'LineWidth', 1.2, 'DisplayName', 'NYU (SUM)');
    hold on;
    plot(pdp_store.NLOS1.delays_m, 10*log10(pdp_store.NLOS1.OmniPDP_USC + eps), ...
        'Color', colors.USC, 'LineWidth', 1.2, 'DisplayName', 'USC (perDelayMax)');
    xlabel('Distance (m)', 'FontSize', 10, 'Interpreter', 'latex');
    ylabel('$|h(\tau)|^2$ (dB)', 'FontSize', 10, 'Interpreter', 'latex');
    title(sprintf('(a) NLOS: %s', pdp_store.NLOS1.Location_ID), 'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'latex');
    legend('Location', 'northeast', 'FontSize', 7, 'Box', 'off');
    grid on; set(gca, 'FontSize', 9);
end

if isfield(pdp_store, 'NLOS2')
    subplot(1,2,2);
    plot(pdp_store.NLOS2.delays_m, 10*log10(pdp_store.NLOS2.OmniPDP_NYU + eps), ...
        'Color', colors.NYU_10dB, 'LineWidth', 1.2, 'DisplayName', 'NYU (SUM)');
    hold on;
    plot(pdp_store.NLOS2.delays_m, 10*log10(pdp_store.NLOS2.OmniPDP_USC + eps), ...
        'Color', colors.USC, 'LineWidth', 1.2, 'DisplayName', 'USC (perDelayMax)');
    xlabel('Distance (m)', 'FontSize', 10, 'Interpreter', 'latex');
    ylabel('$|h(\tau)|^2$ (dB)', 'FontSize', 10, 'Interpreter', 'latex');
    title(sprintf('(b) NLOS: %s', pdp_store.NLOS2.Location_ID), 'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'latex');
    legend('Location', 'northeast', 'FontSize', 7, 'Box', 'off');
    grid on; set(gca, 'FontSize', 9);
end

saveFigure(fig1, paths.figures, 'Fig1_OmniPDP_Comparison');

% =========================================================================
% FIGURE 2: Path Loss Bar Chart + Scatter
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
scatter(results.PL_USC, results.PL_NYU, 40, colors.NLOS, 'filled', 'DisplayName', 'NLOS');
hold on;
xlims = [nanmin([results.PL_NYU; results.PL_USC])-5, nanmax([results.PL_NYU; results.PL_USC])+5];
plot(xlims, xlims, 'k--', 'LineWidth', 1, 'DisplayName', 'y=x');
xlabel('PL USC (dB)', 'FontSize', 10, 'Interpreter', 'latex');
ylabel('PL NYU (dB)', 'FontSize', 10, 'Interpreter', 'latex');
title('(b) PL Scatter: NYU vs USC', 'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'latex');
legend('Location', 'southeast', 'FontSize', 7, 'Box', 'off');
grid on; axis equal; set(gca, 'FontSize', 9);

saveFigure(fig2, paths.figures, 'Fig2_PathLoss_Comparison');

% =========================================================================
% FIGURE 3: Delay Spread Bar Chart + Scatter
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
scatter(results.DS_USC, results.DS_NYU, 40, colors.NLOS, 'filled', 'DisplayName', 'NLOS');
hold on;
ds_max = nanmax([results.DS_NYU; results.DS_USC]) + 20;
plot([0 ds_max], [0 ds_max], 'k--', 'LineWidth', 1, 'DisplayName', 'y=x');
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
bh = bar(1:nFiles, delta_PL, 'FaceColor', colors.NLOS, 'EdgeColor', 'k', 'LineWidth', 0.5);
hold on;
yline(nanmean(delta_PL), '--k', 'LineWidth', 1.5);
yline(0, 'k-', 'LineWidth', 0.8);
ax = gca; ax.XTick = 1:nFiles; ax.XTickLabel = results.Location_ID;
ax.XTickLabelRotation = 60; ax.TickLabelInterpreter = 'none'; ax.FontSize = 8;
xlabel('Location', 'FontSize', 10, 'Interpreter', 'latex');
ylabel('$\Delta$PL (NYU $-$ USC) [dB]', 'FontSize', 10, 'Interpreter', 'latex');
title(sprintf('(a) $\\Delta$PL: $\\mu$=%.2f dB', nanmean(delta_PL)), 'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'latex');
grid on;

subplot(1,2,2);
bh2 = bar(1:nFiles, delta_DS, 'FaceColor', colors.NLOS, 'EdgeColor', 'k', 'LineWidth', 0.5);
hold on;
yline(nanmean(delta_DS), '--k', 'LineWidth', 1.5);
yline(0, 'k-', 'LineWidth', 0.8);
ax = gca; ax.XTick = 1:nFiles; ax.XTickLabel = results.Location_ID;
ax.XTickLabelRotation = 60; ax.TickLabelInterpreter = 'none'; ax.FontSize = 8;
xlabel('Location', 'FontSize', 10, 'Interpreter', 'latex');
ylabel('$\Delta$DS (NYU $-$ USC) [ns]', 'FontSize', 10, 'Interpreter', 'latex');
title(sprintf('(b) $\\Delta$DS: $\\mu$=%.2f ns', nanmean(delta_DS)), 'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'latex');
grid on;

saveFigure(fig4, paths.figures, 'Fig4_Method_Difference');

% =========================================================================
% FIGURE 5: Angular Spread Bar Chart
% =========================================================================
fig5 = figure('Units', 'inches', 'Position', [1 1 IEEE_DOUBLE_COL_WIDTH 3.0], 'Name', 'Fig5: Angular Spread');

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

saveFigure(fig5, paths.figures, 'Fig5_AngularSpread_BarChart');

% =========================================================================
% FIGURE 6: Bland-Altman for PL, DS, ASA, ASD
% =========================================================================
fig6 = figure('Units', 'inches', 'Position', [1 1 IEEE_DOUBLE_COL_WIDTH 5.5], 'Name', 'Fig6: Bland-Altman');

mean_PL = (results.PL_NYU + results.PL_USC) / 2;
diff_PL = results.PL_NYU - results.PL_USC;
mean_DS = (results.DS_NYU + results.DS_USC) / 2;
diff_DS = results.DS_NYU - results.DS_USC;

subplot(2,2,1);
scatter(mean_PL, diff_PL, 40, colors.NLOS, 'filled');
hold on;
yline(nanmean(diff_PL), 'k-', 'LineWidth', 1.5);
yline(nanmean(diff_PL) + 1.96*nanstd(diff_PL), 'r--', 'LineWidth', 1);
yline(nanmean(diff_PL) - 1.96*nanstd(diff_PL), 'r--', 'LineWidth', 1);
xlabel('Mean PL (dB)', 'FontSize', 10, 'Interpreter', 'latex');
ylabel('$\Delta$PL (dB)', 'FontSize', 10, 'Interpreter', 'latex');
title(sprintf('(a) PL: $\\mu$=%.2f, $\\sigma$=%.2f dB', nanmean(diff_PL), nanstd(diff_PL)), ...
    'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'latex');
grid on; set(gca, 'FontSize', 9);

subplot(2,2,2);
scatter(mean_DS, diff_DS, 40, colors.NLOS, 'filled');
hold on;
yline(nanmean(diff_DS), 'k-', 'LineWidth', 1.5);
yline(nanmean(diff_DS) + 1.96*nanstd(diff_DS), 'r--', 'LineWidth', 1);
yline(nanmean(diff_DS) - 1.96*nanstd(diff_DS), 'r--', 'LineWidth', 1);
xlabel('Mean DS (ns)', 'FontSize', 10, 'Interpreter', 'latex');
ylabel('$\Delta$DS (ns)', 'FontSize', 10, 'Interpreter', 'latex');
title(sprintf('(b) DS: $\\mu$=%.2f, $\\sigma$=%.2f ns', nanmean(diff_DS), nanstd(diff_DS)), ...
    'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'latex');
grid on; set(gca, 'FontSize', 9);

mean_ASA = (results.ASA_NYU_10dB + results.ASA_USC) / 2;
diff_ASA = results.ASA_NYU_10dB - results.ASA_USC;
mean_ASD = (results.ASD_NYU_10dB + results.ASD_USC) / 2;
diff_ASD = results.ASD_NYU_10dB - results.ASD_USC;

subplot(2,2,3);
scatter(mean_ASA, diff_ASA, 40, colors.NLOS, 'filled');
hold on;
yline(nanmean(diff_ASA), 'k-', 'LineWidth', 1.5);
yline(nanmean(diff_ASA) + 1.96*nanstd(diff_ASA), 'r--', 'LineWidth', 1);
yline(nanmean(diff_ASA) - 1.96*nanstd(diff_ASA), 'r--', 'LineWidth', 1);
xlabel('Mean ASA (deg)', 'FontSize', 10, 'Interpreter', 'latex');
ylabel('$\Delta$ASA (deg)', 'FontSize', 10, 'Interpreter', 'latex');
title(sprintf('(c) ASA: $\\mu$=%.2f, $\\sigma$=%.2f deg', nanmean(diff_ASA), nanstd(diff_ASA)), ...
    'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'latex');
grid on; set(gca, 'FontSize', 9);

subplot(2,2,4);
scatter(mean_ASD, diff_ASD, 40, colors.NLOS, 'filled');
hold on;
yline(nanmean(diff_ASD), 'k-', 'LineWidth', 1.5);
yline(nanmean(diff_ASD) + 1.96*nanstd(diff_ASD), 'r--', 'LineWidth', 1);
yline(nanmean(diff_ASD) - 1.96*nanstd(diff_ASD), 'r--', 'LineWidth', 1);
xlabel('Mean ASD (deg)', 'FontSize', 10, 'Interpreter', 'latex');
ylabel('$\Delta$ASD (deg)', 'FontSize', 10, 'Interpreter', 'latex');
title(sprintf('(d) ASD: $\\mu$=%.2f, $\\sigma$=%.2f deg', nanmean(diff_ASD), nanstd(diff_ASD)), ...
    'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'latex');
grid on; set(gca, 'FontSize', 9);

saveFigure(fig6, paths.figures, 'Fig6_BlandAltman');

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
    results.PG_omni_USC, results.NoiseThresh_dB, ...
    'VariableNames', {'Location', 'Env', 'Distance_m', ...
    'PL_NYU_dB', 'PL_USC_dB', 'Delta_PL_dB', ...
    'DS_NYU_ns', 'DS_USC_ns', 'Delta_DS_ns', ...
    'ASA_NYU_10dB', 'ASA_NYU_15dB', 'ASA_NYU_20dB', 'ASA_USC', ...
    'ASD_NYU_10dB', 'ASD_NYU_15dB', 'ASD_NYU_20dB', 'ASD_USC', ...
    'PG_omni_USC_dB', 'NoiseThresh_dB'});

% =========================================================================
% Create NLOS summary table (all locations are NLOS)
% =========================================================================
metrics = {'PL_NYU', 'PL_USC', 'DS_NYU', 'DS_USC', ...
    'ASA_NYU_10dB', 'ASA_NYU_15dB', 'ASA_NYU_20dB', 'ASA_USC', ...
    'ASD_NYU_10dB', 'ASD_NYU_15dB', 'ASD_NYU_20dB', 'ASD_USC'};
stats_labels = {'Mean', 'Std', 'Min', 'Max'};

T_nlos = table();
for i = 1:length(metrics)
    data_vec = results.(metrics{i});
    T_nlos.(metrics{i}) = [nanmean(data_vec); nanstd(data_vec); nanmin(data_vec); nanmax(data_vec)];
end
T_nlos.Properties.RowNames = stats_labels;

% =========================================================================
% Create Method Comparison summary table
% =========================================================================
T_comparison = table();
T_comparison.Metric = {'Delta_PL_NLOS'; 'Delta_DS_NLOS'; 'Delta_ASA_NLOS'; 'Delta_ASD_NLOS'};
T_comparison.Mean = [...
    nanmean(results.PL_NYU - results.PL_USC); ...
    nanmean(results.DS_NYU - results.DS_USC); ...
    nanmean(results.ASA_NYU_10dB - results.ASA_USC); ...
    nanmean(results.ASD_NYU_10dB - results.ASD_USC)];
T_comparison.Std = [...
    nanstd(results.PL_NYU - results.PL_USC); ...
    nanstd(results.DS_NYU - results.DS_USC); ...
    nanstd(results.ASA_NYU_10dB - results.ASA_USC); ...
    nanstd(results.ASD_NYU_10dB - results.ASD_USC)];

% =========================================================================
% Save as CSV
% =========================================================================
writetable(T_all, fullfile(paths.output, 'USC7GHz_Method_Comparison_Results.csv'));

% =========================================================================
% Save as Excel with multiple sheets
% =========================================================================
xlsx_file = fullfile(paths.output, 'USC7GHz_Method_Comparison_Results.xlsx');
if exist(xlsx_file, 'file'), delete(xlsx_file); end
writetable(T_all, xlsx_file, 'Sheet', 'All_Results');
writetable(T_nlos, xlsx_file, 'Sheet', 'NLOS_Summary', 'WriteRowNames', true);
writetable(T_comparison, xlsx_file, 'Sheet', 'Method_Comparison');

% =========================================================================
% Save as MAT
% =========================================================================
save(fullfile(paths.output, 'USC7GHz_Full_Results.mat'), ...
    'results', 'T_all', 'T_nlos', 'T_comparison', ...
    'params', 'config', 'pdp_store', 'aps_store');

fprintf('\n=======================================================================\n');
fprintf('  Results saved to: %s\n', paths.output);
fprintf('    - USC7GHz_Method_Comparison_Results.csv (flat table)\n');
fprintf('    - USC7GHz_Method_Comparison_Results.xlsx (3 sheets)\n');
fprintf('    - USC7GHz_Full_Results.mat (MATLAB format)\n');
fprintf('  Figures saved to: %s\n', paths.figures);
fprintf('=======================================================================\n');
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
    % Formula: sqrt(E[tau^2] - E[tau]^2) where E[] is power-weighted average
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

function pattern = load_antenna_pattern_mat(filepath)
    % =========================================================================
    % Load antenna pattern from .mat file
    % Supports multiple formats:
    %   Strategy 1: Nx2 matrix [angle_offset_deg, gain_dB]
    %   Strategy 2: new_x (angles), new_y (gain) separate vectors
    %   Strategy 3: aziPatternFile / elevPatternFile (USC format)
    %   Fallback: flat pattern
    %
    % Output: Nx2 matrix [angle_deg, gain_dB]
    % =========================================================================
    try
        data = load(filepath);
        fnames = fieldnames(data);

        fprintf('  Loading antenna pattern from %s\n', filepath);
        for fn = 1:length(fnames)
            fprintf('    Variable: %s [%s]\n', fnames{fn}, mat2str(size(data.(fnames{fn}))));
        end

        % Strategy 1: Look for Nx2 matrix
        for fn = 1:length(fnames)
            v = data.(fnames{fn});
            if isnumeric(v) && ismatrix(v) && size(v, 2) == 2 && size(v, 1) > 10
                pattern = sortrows(v, 1);
                fprintf('  -> Using %s as [angle, gain] matrix (%d pts)\n', fnames{fn}, size(pattern, 1));
                return;
            end
        end

        % Strategy 2: Look for new_x (angles) and new_y (gain) vectors
        if isfield(data, 'new_x') && isfield(data, 'new_y')
            angles = data.new_x(:);
            gains = data.new_y(:);
            if length(angles) == length(gains) && length(angles) > 10
                pattern = sortrows([angles, gains], 1);
                fprintf('  -> Using new_x/new_y vectors (%d pts, angle range [%.1f, %.1f], peak gain %.1f dB)\n', ...
                    size(pattern, 1), min(angles), max(angles), max(gains));
                return;
            end
        end

        % Strategy 3: USC format
        if isfield(data, 'aziPatternFile')
            pattern = sortrows(data.aziPatternFile, 1);
            fprintf('  -> Using aziPatternFile (%d pts)\n', size(pattern, 1));
            return;
        end
        if isfield(data, 'elevPatternFile')
            pattern = sortrows(data.elevPatternFile, 1);
            fprintf('  -> Using elevPatternFile (%d pts)\n', size(pattern, 1));
            return;
        end

        % Fallback: flat pattern
        warning('Unrecognized antenna pattern format in %s. Using flat pattern.', filepath);
        pattern = [(-90:90)', zeros(181, 1)];

    catch ME
        warning('Could not load antenna pattern from %s: %s', filepath, ME.message);
        pattern = [(-90:90)', zeros(181, 1)];
    end
end

function [ASA_NYU_10, ASA_NYU_15, ASA_NYU_20, ASA_USC, ...
          ASD_NYU_10, ASD_NYU_15, ASD_NYU_20, ASD_USC, aps_data] = ...
        compute_AS_from_PDP_4D(PDP_dir_lin_thresh, params, config, antenna_pattern)
    % =========================================================================
    % Compute Angular Spread from 4D PDP data (already thresholded)
    %
    % Input:
    %   PDP_dir_lin_thresh: 4D PDP array [Nf x N_aztx x N_azrx x N_elrx]
    %                       Already has USC PDP threshold applied + TX flip
    %   params: System parameters (txAz, rxAz, etc.)
    %   config: Configuration (PAS thresholds)
    %   antenna_pattern: Antenna pattern for NYU lobe expansion
    %
    % This function implements both NYU and USC Angular Spread methods:
    %   - NYU: PAS threshold + antenna pattern lobe expansion + 3GPP formula
    %   - USC: No PAS threshold, direct 3GPP formula
    %
    % Both use the SAME PDP threshold for fair comparison.
    % =========================================================================

    % =========================================================================
    % Step 1: Form Angular Power Spectrum (APS)
    % Sum over delay, then sum over RX elevations
    % =========================================================================
    % PDP_dir_lin_thresh is [Nf x N_aztx x N_azrx x N_elrx]

    % Sum over delay (dim 1) -> [N_aztx x N_azrx x N_elrx]
    Power_per_antenna = squeeze(sum(PDP_dir_lin_thresh, 1));

    % Sum over RX elevations (dim 3) -> [N_aztx x N_azrx]
    Power_per_antenna_noelev = sum(Power_per_antenna, 3);

    % APS for TX (sum over RX azimuth) - Azimuth Spread of Departure (ASD)
    APS_Tx = sum(Power_per_antenna_noelev, 2);  % [N_aztx x 1]

    % APS for RX (sum over TX azimuth) - Azimuth Spread of Arrival (ASA)
    APS_Rx = sum(Power_per_antenna_noelev, 1).';  % [N_azrx x 1]

    % Store APS for visualization
    aps_data.APS_Tx = APS_Tx;
    aps_data.APS_Rx = APS_Rx;
    aps_data.angles_Tx = params.txAz;
    aps_data.angles_Rx = params.rxAz;

    % =========================================================================
    % Step 2: NYU AS Method - Apply PAS threshold + antenna pattern expansion
    % =========================================================================
    % ASA with different thresholds
    ASA_NYU_10 = compute_AS_NYU_method(params.rxAz, APS_Rx, config.PAS_threshold_1, antenna_pattern, params.HPBW);
    ASA_NYU_15 = compute_AS_NYU_method(params.rxAz, APS_Rx, config.PAS_threshold_2, antenna_pattern, params.HPBW);
    ASA_NYU_20 = compute_AS_NYU_method(params.rxAz, APS_Rx, config.PAS_threshold_3, antenna_pattern, params.HPBW);

    % ASD with different thresholds
    ASD_NYU_10 = compute_AS_NYU_method(params.txAz, APS_Tx, config.PAS_threshold_1, antenna_pattern, params.HPBW);
    ASD_NYU_15 = compute_AS_NYU_method(params.txAz, APS_Tx, config.PAS_threshold_2, antenna_pattern, params.HPBW);
    ASD_NYU_20 = compute_AS_NYU_method(params.txAz, APS_Tx, config.PAS_threshold_3, antenna_pattern, params.HPBW);

    % =========================================================================
    % Step 3: USC AS Method - No PAS threshold, direct 3GPP formula
    % All angles contribute to the angular spread calculation
    % =========================================================================
    ASA_USC = compute_AS_3GPP(params.rxAz, APS_Rx);
    ASD_USC = compute_AS_3GPP(params.txAz, APS_Tx);
end

function AS = compute_AS_NYU_method(angles, powers, pas_threshold_dB, antenna_pattern, HPBW)
    % =========================================================================
    % NYU Angular Spread Method with Lobe Detection and Boundary Expansion
    %
    % This function implements NYU's AS calculation method:
    %   1. Apply PAS threshold (10/15/20 dB below peak)
    %   2. Detect contiguous lobes (gap > HPBW = new lobe)
    %   3. Expand lobe boundaries using antenna pattern
    %   4. Compute AS using 3GPP formula on original + boundary MPCs
    % =========================================================================

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
    % Step 1: Lobe Detection
    % =========================================================================
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
                lobe_ends(end+1) = selected_angles(i-1);
                lobe_end_powers_dB(end+1) = selected_powers_dB(i-1);
                lobe_starts(end+1) = selected_angles(i);
                lobe_start_powers_dB(end+1) = selected_powers_dB(i);
            end
        end

        lobe_ends(end+1) = selected_angles(end);
        lobe_end_powers_dB(end+1) = selected_powers_dB(end);

        nLobes = length(lobe_starts);
    end

    % =========================================================================
    % Step 2: Boundary Expansion using antenna pattern
    % =========================================================================
    boundary_angles = [];
    boundary_powers_dB = [];

    if ~isempty(antenna_pattern) && size(antenna_pattern, 1) > 1
        pattern_angles = antenna_pattern(:, 1);
        pattern_gain = antenna_pattern(:, 2) - max(antenna_pattern(:, 2));

        for iLobe = 1:nLobes
            % Expand start boundary (left side)
            power_above_threshold_start = lobe_start_powers_dB(iLobe) - threshold_dB;
            [~, Ang_pos] = min(abs(abs(power_above_threshold_start) - abs(pattern_gain)));
            boundary_offset_start = abs(pattern_angles(Ang_pos));

            boundary_angle_start = lobe_starts(iLobe) - boundary_offset_start;
            if boundary_angle_start < 0
                boundary_angle_start = boundary_angle_start + 360;
            end
            boundary_angles(end+1) = boundary_angle_start;
            boundary_powers_dB(end+1) = threshold_dB;

            % Expand end boundary (right side)
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
    % Step 3: Combine original + boundary MPCs
    % =========================================================================
    all_angles = [selected_angles(:); boundary_angles(:)];
    all_powers_dB = [selected_powers_dB(:); boundary_powers_dB(:)];

    all_powers_lin = 10.^(all_powers_dB / 10);
    all_powers_lin = all_powers_lin / sum(all_powers_lin);

    % =========================================================================
    % Step 4: Compute AS using 3GPP formula
    % =========================================================================
    AS = compute_AS_3GPP(all_angles, all_powers_lin);
end

function AS = compute_AS_3GPP(angles, powers)
    % =========================================================================
    % 3GPP Angular Spread Formula (Circular Standard Deviation)
    %
    % Formula: AS = sqrt(-2 * ln(R)) [degrees]
    % where R = |sum(w_i * exp(j*theta_i))| is the mean resultant length
    %
    % Based on NYU's circ_std.m (Zar Equation 26.21)
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
        AS = 0;
        return;
    end
    if R <= 0
        AS = 180;
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

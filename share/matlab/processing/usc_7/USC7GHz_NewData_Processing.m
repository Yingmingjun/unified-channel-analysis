%% ========================================================================
%  USC 7GHz NEW DATA Processing (6 LOS + 11 NLOS)
%  ========================================================================
%
%  PURPOSE: Process the NEW USC FR3 Midband (6.25-7.25 GHz) measurement data
%           with BOTH NYU and USC methods. This replaces the old 8-point
%           NLOS-only dataset with the full 17-point (6 LOS + 11 NLOS) dataset.
%
%  NEW DATA SOURCE:
%    - LOS: 6 files (RX1-RX6) in All Points Full Band\LOS Study\
%           H shape: [12001, 13, 36, 5], freq range 6-18 GHz
%    - NLOS: 11 files (RX01-RX11) in All Points Full Band\OLOS Study\
%           H shape: [8001, 13, 36, 5], freq range 6-14 GHz
%
%  KEY CHANGES FROM OLD SCRIPT:
%    1. Uses USC antenna pattern (USC_Midband_Pattern.mat) for lobe expansion
%       instead of NYU's 7 GHz antenna pattern
%    2. HPBW for lobe gap detection = 10 deg (grid step)
%    3. Lobe boundary expansion: from USC antenna pattern -10 dB beamwidth
%    4. Frequency extraction: indices 251:1251 for 6.25-7.25 GHz (1001 pts)
%    5. Now includes 6 LOS points in addition to 11 NLOS points
%
%  DATA FORMAT: 4D matrix [Nf, N_aztx, N_azrx, N_elrx] = [1001, 13, 36, 5]
%    - N_aztx = 13 TX azimuths (-60:10:60 deg)
%    - N_azrx = 36 RX azimuths (0:10:350 deg)
%    - N_elrx = 5 RX elevations (-20:10:20 deg)
%
%  PROCESSING METHOD (Naveed-faithful, USCprocessing.m):
%    - Hann windowing + IFFT -> directional PDP (1x grid for PL)
%    - Separate 10x zero-padded IFFT -> PDP_dir_over (for DS only)
%    - Noise: max(noise_floor_calc_v2, [], 'all') + 12 dB (1x chain);
%             same - 20 dB on the 10x chain
%    - Flip TX azimuth
%    - Omni: NYU SUM vs USC perDelayMax (both chains)
%    - AS: NYU 10 dB PAS + lobe expansion (USC antenna) vs USC no threshold
%    - DS gate: dynamic t_gate = (d(end)-10+d_LOS)/c only (no hardcoded
%               gate at 6.75 GHz; distances reach 436 m)
%
%  OUTPUT:
%    - USC7GHz_NewData_Results.csv
%    - USC7GHz_NewData_Results.xlsx
%    - USC7GHz_Full_Results.mat  (overwrites old results for CDF/BA scripts)
%    - Figures: PDP, PL, DS, AS bar charts, Bland-Altman
%
%  Author: Mingjun Ying
%  Date: February 2026
%  ========================================================================

%% SECTION 0: CLEAR ENVIRONMENT
clear; clc; close all;

%% SECTION 1: CONFIGURATION
% =========================================================================
% SYSTEM PARAMETERS (USC FR3 Midband 6.25-7.25 GHz)
% =========================================================================
params.Frequency_GHz = 6.75;          % Center frequency
params.BW = 1e9;                      % Bandwidth = 1 GHz
params.Nf = 1001;                     % Frequency points in 6.25-7.25 GHz
params.dt = 1/params.BW;              % Time resolution = 1 ns
params.n_oversamp = 10;               % Oversampling factor
params.c = 3e8;                       % Speed of light [m/s]
params.delayGate_ns = 966.67;         % Max delay gate in ns (not enforced here; dynamic t_gate only)

% Frequency extraction indices (6.25-7.25 GHz from full band)
% LOS: 6-18 GHz, 12001 pts -> 1 MHz resolution -> 6.25 GHz = index 251
% OLOS: 6-14 GHz, 8001 pts -> 1 MHz resolution -> 6.25 GHz = index 251
params.freq_start_idx = 251;
params.freq_end_idx = 1251;           % 251 + 1001 - 1

% Angular grid (4D: NO TX elevation)
params.N_aztx = 13;
params.N_azrx = 36;
params.N_elrx = 5;
params.txAz = (-60:10:60).';          % TX azimuth angles [deg]
params.rxAz = (0:10:350).';           % RX azimuth angles [deg]
params.rxEl = (-20:10:20).';          % RX elevation angles [deg]

% Distance vector
params.d_vec_m = (0:params.Nf-1) * params.c / params.BW;
params.d2_vec_m = (0:1/params.n_oversamp:params.Nf-1/params.n_oversamp) * params.c / params.BW;

% Antenna beamwidth for lobe gap detection
params.HPBW = 10;                     % Grid step = lobe gap threshold

% Empirical antenna gain correction for omni PDP formation
% Sub-THz uses 1.95 dB; FR3 (6.75 GHz) uses 3.7 dB
% This is subtracted from each directional PDP before omni synthesis
params.correction_factor_dB = 3.7;
params.correction_factor_lin = 10^(params.correction_factor_dB / 10);

% =========================================================================
% THRESHOLD SETTINGS
% =========================================================================
config.noise_margin_dB = 12;          % dB above max noise floor (Naveed USCprocessing.m L60)
config.max_dynamic_range_dB = 22;     % Maximum dynamic range cap

% PAS Threshold (NYU AS method only)
config.PAS_threshold_1 = 10;          % 10 dB below peak
config.PAS_threshold_2 = 15;
config.PAS_threshold_3 = 20;
config.multipath_low_bound = -100;

% =========================================================================
% USC ANTENNA PATTERN (for NYU AS lobe expansion)
% =========================================================================
U = paths();
config.antenna_pattern_path = U.usc_7_pattern_dir;
config.antenna_pattern_file = 'USC_Midband_Pattern.mat';

% =========================================================================
% DATA PATHS
% =========================================================================
paths.new_data_base = U.raw_usc_7;
paths.los_data = U.raw_usc_7_LOS;
paths.nlos_data = U.raw_usc_7_NLOS;

% Output paths
paths.output = U.results_usc_7;
paths.figures = U.figures_usc_7;

if ~exist(paths.output, 'dir'), mkdir(paths.output); end
if ~exist(paths.figures, 'dir'), mkdir(paths.figures); end

% =========================================================================
% FILE LISTS WITH DISTANCES
% =========================================================================
% LOS files (6 locations) — distances from USC measurement log (approximate)
LOS_files = {
    'RX1_07-12-2024.mat',   184.8,   'LOS';
    'RX2_07-12-2024.mat',   161.7,   'LOS';
    'RX3_07-12-2024.mat',   132.6,   'LOS';
    'RX4_07-12-2024.mat',    83.4,   'LOS';
    'RX5_07-12-2024.mat',    63.6,   'LOS';
    'RX6_07-12-2024.mat',    59.4,   'LOS';
};

% NLOS/OLOS files (11 locations) — distances from filenames
NLOS_files = {
    'RX01_65.1m_calib.mat',    65.1,    'NLOS';
    'RX02_62.1m_calib.mat',    62.1,    'NLOS';
    'RX03_103.5m_calib.mat',  103.5,    'NLOS';
    'RX04_139.1m_calib.mat',  139.1,    'NLOS';
    'RX05_143.6m_calib.mat',  143.6,    'NLOS';
    'RX06_162.8m_calib.mat',  162.8,    'NLOS';
    'RX07_201.4m_calib.mat',  201.4,    'NLOS';
    'RX08_214.9m_calib.mat',  214.9,    'NLOS';
    'RX09_336.3m_calib.mat',  336.3,    'NLOS';
    'RX10_404.9m_calib.mat',  404.9,    'NLOS';
    'RX11_436.1m_calib.mat',  436.1,    'NLOS';
};

% Combine all files
ALL_files = [LOS_files; NLOS_files];
ALL_paths = [repmat({paths.los_data}, size(LOS_files,1), 1); ...
             repmat({paths.nlos_data}, size(NLOS_files,1), 1)];
nFiles = size(ALL_files, 1);

% Full band info for frequency extraction
% LOS: 6-18 GHz (12001 pts), NLOS: 6-14 GHz (8001 pts)
full_band_Nf = [repmat(12001, size(LOS_files,1), 1); ...
                repmat(8001, size(NLOS_files,1), 1)];

% =========================================================================
% IEEE FIGURE SETTINGS
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

colors.NYU_10dB = [0.0000 0.4470 0.7410];
colors.NYU_15dB = [0.8500 0.3250 0.0980];
colors.NYU_20dB = [0.9290 0.6940 0.1250];
colors.USC = [0.4660 0.6740 0.1880];
colors.LOS = [0.0000 0.4470 0.7410];
colors.NLOS = [0.8500 0.3250 0.0980];

%% SECTION 2: LOAD USC ANTENNA PATTERN
% =========================================================================
fprintf('=======================================================================\n');
fprintf('  USC 7GHz NEW DATA Processing (6 LOS + 11 NLOS)\n');
fprintf('=======================================================================\n');

% Load USC antenna pattern and extract azimuth cut at 0 deg elevation
antenna_azi = load_USC_antenna_pattern(...
    fullfile(config.antenna_pattern_path, config.antenna_pattern_file));
fprintf('USC antenna pattern loaded: %d points\n', size(antenna_azi, 1));
fprintf('  Peak gain: %.1f dB, -10 dB full BW: ~44 deg\n', max(antenna_azi(:,2)));

fprintf('  Data Format: 4D [Nf=%d, N_aztx=%d, N_azrx=%d, N_elrx=%d]\n', ...
    params.Nf, params.N_aztx, params.N_azrx, params.N_elrx);
fprintf('  Freq extraction: indices %d:%d (6.25-7.25 GHz)\n', ...
    params.freq_start_idx, params.freq_end_idx);
fprintf('  PDP Threshold: Global max noise + %d dB (DR cap = %d dB)\n', ...
    config.noise_margin_dB, config.max_dynamic_range_dB);
fprintf('  Lobe gap detection HPBW: %d deg (grid step)\n', params.HPBW);
fprintf('  Lobe expansion: USC antenna pattern -10 dB beamwidth\n');
fprintf('  Locations: %d LOS + %d NLOS = %d total\n', ...
    size(LOS_files,1), size(NLOS_files,1), nFiles);
fprintf('=======================================================================\n\n');

%% SECTION 3: INITIALIZE RESULTS
results = struct();
results.Location_ID = cell(nFiles, 1);
results.Environment = cell(nFiles, 1);
results.Distance_m = zeros(nFiles, 1);

% Path Loss
results.PL_NYU = zeros(nFiles, 1);
results.PL_USC = zeros(nFiles, 1);

% Delay Spread
results.DS_NYU = zeros(nFiles, 1);
results.DS_USC = zeros(nFiles, 1);

% Angular Spread - ASA
results.ASA_NYU_10dB = zeros(nFiles, 1);
results.ASA_NYU_15dB = zeros(nFiles, 1);
results.ASA_NYU_20dB = zeros(nFiles, 1);
results.ASA_USC = zeros(nFiles, 1);

% Angular Spread - ASD
results.ASD_NYU_10dB = zeros(nFiles, 1);
results.ASD_NYU_15dB = zeros(nFiles, 1);
results.ASD_NYU_20dB = zeros(nFiles, 1);
results.ASD_USC = zeros(nFiles, 1);

% Noise threshold and path gain
results.NoiseThresh_dB = zeros(nFiles, 1);
results.PG_omni_USC = zeros(nFiles, 1);

% PDP and APS storage for visualization
pdp_store = struct();
aps_store = struct();

%% SECTION 4: PROCESS ALL LOCATIONS
fprintf('=====================================================================\n');
fprintf('    Processing USC FR3 7GHz NEW Data: PL, DS, and AS\n');
fprintf('=====================================================================\n\n');

for iLoc = 1:nFiles
    fileName = ALL_files{iLoc, 1};
    TR_distance = ALL_files{iLoc, 2};
    d_LOS = TR_distance;
    envLabel = ALL_files{iLoc, 3};
    dataFolder = ALL_paths{iLoc};
    Nf_full = full_band_Nf(iLoc);

    % Build location ID
    if strcmp(envLabel, 'LOS')
        Location_ID = sprintf('LOS_%s', strrep(fileName, '.mat', ''));
    else
        tokens = regexp(fileName, '(\d+\.?\d*)m', 'tokens');
        if ~isempty(tokens)
            Location_ID = sprintf('NLOS_%.0fm', str2double(tokens{1}{1}));
        else
            Location_ID = sprintf('NLOS_%s', strrep(fileName, '.mat', ''));
        end
    end

    fprintf('Processing [%2d/%2d] %s (d=%.1f m, %s, Nf_full=%d) ... ', ...
        iLoc, nFiles, Location_ID, TR_distance, envLabel, Nf_full);

    % =====================================================================
    % STEP 1: Load H matrix and extract 6.25-7.25 GHz band
    % =====================================================================
    fullPath = fullfile(dataFolder, fileName);
    data = load(fullPath, 'H');

    H_full = data.H;

    % Verify dimensions
    [dim1, dim2, dim3, dim4] = size(H_full);
    fprintf('[H: %dx%dx%dx%d] ', dim1, dim2, dim3, dim4);

    % H should be [Nf_full, 13, 36, 5] when loaded in MATLAB
    % Verify and handle potential dimension transposition
    if dim1 == Nf_full && dim2 == params.N_aztx && dim3 == params.N_azrx && dim4 == params.N_elrx
        % Expected order: [Nf, 13, 36, 5] — no permutation needed
    elseif dim4 == Nf_full && dim3 == params.N_aztx && dim2 == params.N_azrx && dim1 == params.N_elrx
        % HDF5 stored as [5, 36, 13, Nf] and MATLAB transposed to [Nf, 13, 36, 5]
        % Actually this case means MATLAB already transposed correctly
        % But if we get [5, 36, 13, Nf], we need to permute
        H_full = permute(H_full, [4, 3, 2, 1]);
        fprintf('[permuted] ');
    else
        % Try to figure out the right order
        warning('Unexpected H dimensions: [%d, %d, %d, %d]. Attempting auto-detect.', dim1, dim2, dim3, dim4);
        % Find which dimension matches Nf_full
        dims = [dim1, dim2, dim3, dim4];
        nf_dim = find(dims == Nf_full);
        if ~isempty(nf_dim)
            % Permute so frequency is first
            perm_order = [nf_dim, setdiff(1:4, nf_dim)];
            H_full = permute(H_full, perm_order);
            fprintf('[auto-permuted: dim%d->dim1] ', nf_dim);
        else
            error('Cannot find frequency dimension (%d) in H shape.', Nf_full);
        end
    end

    % Extract 6.25-7.25 GHz band
    H = H_full(params.freq_start_idx:params.freq_end_idx, :, :, :);
    clear H_full data;

    % Verify extracted size
    assert(size(H,1) == params.Nf, 'Extracted H has %d freq points, expected %d', size(H,1), params.Nf);

    % =====================================================================
    % STEP 2: Hann windowing + IFFT -> CIR -> PDP
    % =====================================================================
    Nf = params.Nf;
    wf = hann(Nf+1, 'Periodic');
    wf = wf(1:end-1);
    wf = sqrt(mean(abs(wf).^2))^(-1) * wf;
    wf_rep = repmat(wf, [1, params.N_aztx, params.N_azrx, params.N_elrx]);

    h_delay = ifft(H .* wf_rep, [], 1);
    PDP_dir = abs(h_delay).^2;
    clear h_delay;  % keep H and wf_rep alive for oversampled DS chain below

    % =====================================================================
    % STEP 3: Noise threshold (USC FR3 method)
    % =====================================================================
    noise_temp = zeros(params.N_aztx, params.N_azrx, params.N_elrx);
    for az_tx = 1:params.N_aztx
        for az_rx = 1:params.N_azrx
            for el_rx = 1:params.N_elrx
                pdp_temp = squeeze(PDP_dir(:, az_tx, az_rx, el_rx));
                noise_temp(az_tx, az_rx, el_rx) = noise_floor_calc_v2(pdp_temp);
            end
        end
    end

    % Naveed's USCprocessing.m L58-60: max noise floor across all directions + 12 dB.
    max_noise = max(noise_temp, [], 'all');
    noise_thresh_dB = max_noise + config.noise_margin_dB;

    % Dynamic range cap
    max_power_all_dB = 10*log10(max(PDP_dir(:)));
    DR = max_power_all_dB - noise_thresh_dB;

    if DR > config.max_dynamic_range_dB
        noise_thresh_dB_orig = noise_thresh_dB;
        noise_thresh_dB = max_power_all_dB - config.max_dynamic_range_dB;
        fprintf('[DR=%.1f>%d, thresh: %.1f->%.1f] ', ...
            DR, config.max_dynamic_range_dB, noise_thresh_dB_orig, noise_thresh_dB);
    end

    noise_thresh_lin = 10^(noise_thresh_dB/10);

    % Apply threshold
    PDP_dir_thresh = PDP_dir;
    PDP_dir_thresh(PDP_dir <= noise_thresh_lin) = 0;

    % =====================================================================
    % STEP 4: Flip TX azimuth
    % =====================================================================
    PDP_dir_thresh = flip(PDP_dir_thresh, 2);

    % =====================================================================
    % STEP 5: Delay gating
    % =====================================================================
    d = params.d_vec_m;
    d2 = params.d2_vec_m;

    if d_LOS >= 50
        t_gate = (d(end) + d_LOS - 10) / params.c;
    else
        t_gate = (d(end) - 10) / params.c;
    end

    % =====================================================================
    % STEP 5b: Apply empirical gain correction for PL/DS omni synthesis
    % =====================================================================
    % Divide each directional PDP by the gain correction factor before
    % forming omni PDP. This removes the empirical antenna gain so that
    % the summed omni power reflects true received power.
    % Note: PDP_dir_thresh (uncorrected) is still used for AS computation
    % since AS depends only on relative power across directions.
    PDP_dir_corrected = PDP_dir_thresh / params.correction_factor_lin;

    % =====================================================================
    % STEP 6: NYU SUM Omni PDP
    % =====================================================================
    PDP_omni_NYU = squeeze(sum(PDP_dir_corrected, [2, 3, 4]));

    if d_LOS >= 50
        PDP_omni_NYU = circshift(PDP_omni_NYU, -round((d_LOS - 10) / d(2)));
        PDP_omni_NYU = PDP_omni_NYU .* (((d + d_LOS - 10) / params.c) <= t_gate).';
    else
        PDP_omni_NYU = PDP_omni_NYU .* ((d / params.c) <= t_gate).';
    end

    Pr_NYU = sum(PDP_omni_NYU);

    % =====================================================================
    % STEP 7: USC perDelayMax Omni PDP (4D)
    % =====================================================================
    PDP_temp1 = squeeze(sum(PDP_dir_corrected, 4));    % Sum RxEl (corrected)
    PDP_temp2 = squeeze(max(PDP_temp1, [], 3));        % Max RxAz
    PDP_omni_USC = squeeze(max(PDP_temp2, [], 2));     % Max TxAz

    if d_LOS >= 50
        PDP_omni_USC = circshift(PDP_omni_USC, -round((d_LOS - 10) / d(2)));
        PDP_omni_USC = PDP_omni_USC .* (((d + d_LOS - 10) / params.c) <= t_gate).';
    else
        PDP_omni_USC = PDP_omni_USC .* ((d / params.c) <= t_gate).';
    end

    Pr_USC = sum(PDP_omni_USC);

    % =====================================================================
    % STEP 8: Path Loss (calibrated H, 0 dBm TX, 3.7 dB gain corrected)
    % =====================================================================
    if Pr_NYU > 0
        PL_NYU = -10*log10(Pr_NYU);
    else
        PL_NYU = NaN;
    end

    if Pr_USC > 0
        PL_USC = -10*log10(Pr_USC);
    else
        PL_USC = NaN;
    end

    PG_omni = 10*log10(Pr_USC + eps);

    % =====================================================================
    % STEP 9: RMS Delay Spread (Naveed 10x oversampled chain, USCprocessing.m L97-114)
    % =====================================================================
    % Separate zero-padded IFFT for DS only; PL above stays on the 1x chain.
    h_delay_over = ifft(H .* wf_rep, Nf * params.n_oversamp, 1);
    PDP_dir_over = abs(h_delay_over).^2;
    clear h_delay_over;
    noise_thresh_lin_over = 10^((noise_thresh_dB - 20*log10(params.n_oversamp))/10);
    PDP_dir_over(PDP_dir_over <= noise_thresh_lin_over) = 0;
    PDP_dir_over = flip(PDP_dir_over, 2);                   % same TX-az flip as 1x chain (STEP 4)
    PDP_dir_over = PDP_dir_over / params.correction_factor_lin;  % same gain correction as STEP 5b

    PDP_omni_NYU_over = squeeze(sum(PDP_dir_over, [2, 3, 4]));
    PDP_temp1_over = squeeze(sum(PDP_dir_over, 4));
    PDP_temp2_over = squeeze(max(PDP_temp1_over, [], 3));
    PDP_omni_USC_over = squeeze(max(PDP_temp2_over, [], 2));

    if d_LOS >= 50
        PDP_omni_NYU_over = circshift(PDP_omni_NYU_over, -round((d_LOS - 10) / d2(2)));
        PDP_omni_USC_over = circshift(PDP_omni_USC_over, -round((d_LOS - 10) / d2(2)));
        PDP_omni_NYU_over = PDP_omni_NYU_over .* (((d2 + d_LOS - 10) / params.c) <= t_gate).';
        PDP_omni_USC_over = PDP_omni_USC_over .* (((d2 + d_LOS - 10) / params.c) <= t_gate).';
        delay_vec_ns = (d2 + d_LOS - 10) / params.c * 1e9;
    else
        PDP_omni_NYU_over = PDP_omni_NYU_over .* ((d2 / params.c) <= t_gate).';
        PDP_omni_USC_over = PDP_omni_USC_over .* ((d2 / params.c) <= t_gate).';
        delay_vec_ns = d2 / params.c * 1e9;
    end

    % Use realmin (not eps) for log-floor; eps-clamping floors weak-but-nonzero
    % bins at -156 dB, inflating DS via tau^2 weighting after db2pow. See
    % USC 145 script for the detailed diagnosis.
    PDP_omni_NYU_dB = 10*log10(max(PDP_omni_NYU_over, realmin));
    PDP_omni_USC_dB = 10*log10(max(PDP_omni_USC_over, realmin));

    % Dynamic t_gate already applied upstream at omni synthesis. At 6.75 GHz
    % with distances up to ~436 m, the hardcoded 966.67 ns gate would zero
    % out long-distance NLOS points (delays start past 1087 ns). Naveed does
    % not apply a hardcoded secondary gate -- just the dynamic t_gate.
    valid_mask_NYU = (PDP_omni_NYU_over(:) > 0);
    valid_mask_USC = (PDP_omni_USC_over(:) > 0);

    DS_NYU = computeDSonMPC(delay_vec_ns(valid_mask_NYU), PDP_omni_NYU_dB(valid_mask_NYU));
    DS_USC = computeDSonMPC(delay_vec_ns(valid_mask_USC), PDP_omni_USC_dB(valid_mask_USC));

    clear H wf_rep PDP_dir_over;

    % =====================================================================
    % STEP 10: Angular Spread (4D version)
    % =====================================================================
    [ASA_NYU_10, ASA_NYU_15, ASA_NYU_20, ASA_USC_val, ...
     ASD_NYU_10, ASD_NYU_15, ASD_NYU_20, ASD_USC_val, aps_data] = ...
        compute_AS_from_PDP_4D(PDP_dir_thresh, params, config, antenna_azi);

    % =====================================================================
    % STEP 11: Store results
    % =====================================================================
    results.Location_ID{iLoc} = Location_ID;
    results.Environment{iLoc} = envLabel;
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

    % Store first LOS and first NLOS for visualization
    if iLoc == 1
        pdp_store.LOS1.Location_ID = Location_ID;
        if d_LOS >= 50
            pdp_store.LOS1.delays_m = d + d_LOS - 10;
        else
            pdp_store.LOS1.delays_m = d;
        end
        pdp_store.LOS1.OmniPDP_NYU = PDP_omni_NYU;
        pdp_store.LOS1.OmniPDP_USC = PDP_omni_USC;
        aps_store.LOS1 = aps_data;
        aps_store.LOS1.Location_ID = Location_ID;
    end
    if iLoc == size(LOS_files,1) + 1  % First NLOS
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

    fprintf('PL: %.1f/%.1f dB | DS: %.1f/%.1f ns | ASA: %.1f/%.1f | ASD: %.1f/%.1f\n', ...
        PL_NYU, PL_USC, DS_NYU, DS_USC, ASA_NYU_10, ASA_USC_val, ASD_NYU_10, ASD_USC_val);

    clear PDP_dir PDP_dir_thresh;
end

fprintf('\nProcessing complete!\n\n');

%% SECTION 5: GENERATE TABLES
% =========================================================================
% Build LOS/NLOS masks
% =========================================================================
isLOS = strcmpi(results.Environment, 'LOS');
isNLOS = strcmpi(results.Environment, 'NLOS');

% =========================================================================
% TABLE: Per-Location Results
% =========================================================================
fprintf('==========================================================================================================================================\n');
fprintf('                                             PER-LOCATION RESULTS\n');
fprintf('==========================================================================================================================================\n');
fprintf('  Location              | Env  | Dist(m) | PL NYU | PL USC | DS NYU | DS USC | ASA-10 | ASA USC | ASD-10 | ASD USC\n');
fprintf('------------------------+------+---------+--------+--------+--------+--------+--------+---------+--------+--------\n');

for i = 1:nFiles
    fprintf(' %-22s | %-4s | %6.1f  | %6.1f | %6.1f | %6.1f | %6.1f | %6.1f | %7.1f | %6.1f | %6.1f\n', ...
        results.Location_ID{i}, results.Environment{i}, results.Distance_m(i), ...
        results.PL_NYU(i), results.PL_USC(i), ...
        results.DS_NYU(i), results.DS_USC(i), ...
        results.ASA_NYU_10dB(i), results.ASA_USC(i), ...
        results.ASD_NYU_10dB(i), results.ASD_USC(i));
end
fprintf('==========================================================================================================================================\n\n');

% =========================================================================
% Statistical Summary
% =========================================================================
fprintf('=== LOS Statistics (n=%d) ===\n', sum(isLOS));
print_stats('PL_NYU', results.PL_NYU(isLOS), 'dB');
print_stats('PL_USC', results.PL_USC(isLOS), 'dB');
print_stats('DS_NYU', results.DS_NYU(isLOS), 'ns');
print_stats('ASA_NYU_10dB', results.ASA_NYU_10dB(isLOS), 'deg');
print_stats('ASD_NYU_10dB', results.ASD_NYU_10dB(isLOS), 'deg');

fprintf('\n=== NLOS Statistics (n=%d) ===\n', sum(isNLOS));
print_stats('PL_NYU', results.PL_NYU(isNLOS), 'dB');
print_stats('PL_USC', results.PL_USC(isNLOS), 'dB');
print_stats('DS_NYU', results.DS_NYU(isNLOS), 'ns');
print_stats('ASA_NYU_10dB', results.ASA_NYU_10dB(isNLOS), 'deg');
print_stats('ASD_NYU_10dB', results.ASD_NYU_10dB(isNLOS), 'deg');

%% SECTION 6: GENERATE FIGURES

% =========================================================================
% FIGURE 1: Omni PDP Comparison (LOS + NLOS examples)
% =========================================================================
fig1 = figure('Units', 'inches', 'Position', [1 1 IEEE_DOUBLE_COL_WIDTH 2.8], 'Name', 'Fig1: Omni PDP');

if isfield(pdp_store, 'LOS1')
    subplot(1,2,1);
    plot(pdp_store.LOS1.delays_m, 10*log10(pdp_store.LOS1.OmniPDP_NYU + eps), ...
        'Color', colors.NYU_10dB, 'LineWidth', 1.2, 'DisplayName', 'NYU (SUM)');
    hold on;
    plot(pdp_store.LOS1.delays_m, 10*log10(pdp_store.LOS1.OmniPDP_USC + eps), ...
        'Color', colors.USC, 'LineWidth', 1.2, 'DisplayName', 'USC (perDelayMax)');
    xlabel('Distance (m)'); ylabel('$|h(\tau)|^2$ (dB)');
    title(sprintf('(a) LOS: %s', pdp_store.LOS1.Location_ID), 'FontWeight', 'bold');
    legend('Location', 'northeast', 'FontSize', 7, 'Box', 'off');
    grid on;
end

if isfield(pdp_store, 'NLOS1')
    subplot(1,2,2);
    plot(pdp_store.NLOS1.delays_m, 10*log10(pdp_store.NLOS1.OmniPDP_NYU + eps), ...
        'Color', colors.NYU_10dB, 'LineWidth', 1.2, 'DisplayName', 'NYU (SUM)');
    hold on;
    plot(pdp_store.NLOS1.delays_m, 10*log10(pdp_store.NLOS1.OmniPDP_USC + eps), ...
        'Color', colors.USC, 'LineWidth', 1.2, 'DisplayName', 'USC (perDelayMax)');
    xlabel('Distance (m)'); ylabel('$|h(\tau)|^2$ (dB)');
    title(sprintf('(b) NLOS: %s', pdp_store.NLOS1.Location_ID), 'FontWeight', 'bold');
    legend('Location', 'northeast', 'FontSize', 7, 'Box', 'off');
    grid on;
end

saveFigure(fig1, paths.figures, 'Fig1_OmniPDP_LOS_NLOS');

% =========================================================================
% FIGURE 2: Angular Spread Bar Chart
% =========================================================================
fig2 = figure('Units', 'inches', 'Position', [1 1 IEEE_DOUBLE_COL_WIDTH 3.0], 'Name', 'Fig2: Angular Spread');

subplot(1,2,1);
bar_data_ASA = [results.ASA_NYU_10dB, results.ASA_USC];
b = bar(1:nFiles, bar_data_ASA, 'grouped', 'BarWidth', 0.8);
b(1).FaceColor = colors.NYU_10dB; b(2).FaceColor = colors.USC;
ax = gca; ax.XTick = 1:nFiles; ax.XTickLabel = results.Location_ID;
ax.XTickLabelRotation = 70; ax.TickLabelInterpreter = 'none'; ax.FontSize = 7;
xlabel('Location'); ylabel('ASA (degrees)');
title('(a) Azimuth Spread of Arrival', 'FontWeight', 'bold');
legend({'NYU-10dB', 'USC'}, 'Location', 'northwest', 'FontSize', 7, 'Box', 'off');

subplot(1,2,2);
bar_data_ASD = [results.ASD_NYU_10dB, results.ASD_USC];
b = bar(1:nFiles, bar_data_ASD, 'grouped', 'BarWidth', 0.8);
b(1).FaceColor = colors.NYU_10dB; b(2).FaceColor = colors.USC;
ax = gca; ax.XTick = 1:nFiles; ax.XTickLabel = results.Location_ID;
ax.XTickLabelRotation = 70; ax.TickLabelInterpreter = 'none'; ax.FontSize = 7;
xlabel('Location'); ylabel('ASD (degrees)');
title('(b) Azimuth Spread of Departure', 'FontWeight', 'bold');
legend({'NYU-10dB', 'USC'}, 'Location', 'northwest', 'FontSize', 7, 'Box', 'off');

saveFigure(fig2, paths.figures, 'Fig2_AngularSpread_BarChart');

% =========================================================================
% FIGURE 3: Bland-Altman for PL, DS, ASA, ASD
% =========================================================================
fig3 = figure('Units', 'inches', 'Position', [1 1 IEEE_DOUBLE_COL_WIDTH 5.5], 'Name', 'Fig3: Bland-Altman');

% PL
subplot(2,2,1);
plot_bland_altman_subplot(results.PL_NYU, results.PL_USC, isLOS, isNLOS, ...
    '$\Delta$PL (dB)', 'Mean PL (dB)', 'PL', colors);

% DS
subplot(2,2,2);
plot_bland_altman_subplot(results.DS_NYU, results.DS_USC, isLOS, isNLOS, ...
    '$\Delta$DS (ns)', 'Mean DS (ns)', 'DS', colors);

% ASA
subplot(2,2,3);
plot_bland_altman_subplot(results.ASA_NYU_10dB, results.ASA_USC, isLOS, isNLOS, ...
    '$\Delta$ASA (deg)', 'Mean ASA (deg)', 'ASA', colors);

% ASD
subplot(2,2,4);
plot_bland_altman_subplot(results.ASD_NYU_10dB, results.ASD_USC, isLOS, isNLOS, ...
    '$\Delta$ASD (deg)', 'Mean ASD (deg)', 'ASD', colors);

saveFigure(fig3, paths.figures, 'Fig3_BlandAltman_All');

fprintf('Figures saved to: %s\n\n', paths.figures);

%% SECTION 7: SAVE RESULTS
fprintf('Saving results...\n');

% Create results table
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

% Save CSV
writetable(T_all, fullfile(paths.output, 'USC7GHz_NewData_Results.csv'));

% Save Excel with multiple sheets
xlsx_file = fullfile(paths.output, 'USC7GHz_NewData_Results.xlsx');
if exist(xlsx_file, 'file'), delete(xlsx_file); end
writetable(T_all, xlsx_file, 'Sheet', 'All_Results');

% Save MAT (compatible with AS_CDF_Merged.m and BA_AS_Merged.m)
save(fullfile(paths.output, 'USC7GHz_Full_Results.mat'), ...
    'results', 'T_all', 'params', 'config', 'pdp_store', 'aps_store');

fprintf('\n=======================================================================\n');
fprintf('  Results saved to: %s\n', paths.output);
fprintf('    - USC7GHz_NewData_Results.csv\n');
fprintf('    - USC7GHz_NewData_Results.xlsx\n');
fprintf('    - USC7GHz_Full_Results.mat (replaces old 8-pt NLOS-only results)\n');
fprintf('  Figures saved to: %s\n', paths.figures);
fprintf('=======================================================================\n');
fprintf('\nDone!\n');

%% =========================================================================
%  HELPER FUNCTIONS
%  =========================================================================

function pattern_out = load_USC_antenna_pattern(filepath)
    % =========================================================================
    % Load USC antenna pattern from USC_Midband_Pattern.mat
    % Extract azimuth cut at 0 deg elevation and convert to
    % [angle_offset_deg, normalized_gain_dB] format for lobe expansion
    %
    % The USC file contains:
    %   Az: 1x181 (0:2:360 deg)
    %   El: 1x19 (-45:5:45 deg)
    %   pattern_6_75GHz_dB: 181x19 matrix [Az x El]
    %
    % Output: Nx2 matrix [angle_offset, gain_dB] centered on boresight
    % =========================================================================
    data = load(filepath);

    Az = data.Az(:);       % [0, 2, 4, ..., 360] degrees
    El = data.El(:);       % [-45, -40, ..., 45] degrees
    pattern = data.pattern_6_75GHz_dB;  % [181 x 19]

    % Find 0 deg elevation index
    [~, el0_idx] = min(abs(El));
    fprintf('  USC Antenna: El=0 at index %d (El=%.0f deg)\n', el0_idx, El(el0_idx));

    % Extract azimuth cut at 0 deg elevation
    az_cut = pattern(:, el0_idx);  % 181 x 1

    % The measured pattern includes two horn antennas. Remove max_gain/2
    % from all angles to get the single horn pattern.
    max_gain_full = max(az_cut);
    az_cut = az_cut - max_gain_full / 2;

    % Peak gain and location
    [peak_gain, peak_idx] = max(az_cut);
    peak_az = Az(peak_idx);
    fprintf('  Peak gain (single horn): %.1f dB at Az=%.0f deg\n', peak_gain, peak_az);

    % Convert to angle offset from boresight
    % Shift so boresight is at 0 deg offset
    angle_offsets = Az - peak_az;
    % Wrap to [-180, 180]
    angle_offsets = mod(angle_offsets + 180, 360) - 180;

    % Sort by angle offset
    [angle_offsets, sort_idx] = sort(angle_offsets);
    gains_dB = az_cut(sort_idx);

    % Normalize so peak = 0 dB
    gains_dB = gains_dB - peak_gain;

    pattern_out = [angle_offsets, gains_dB];

    % Print -10 dB beamwidth
    above_m10 = gains_dB >= -10;
    if any(above_m10)
        angles_above = angle_offsets(above_m10);
        bw_10dB = max(angles_above) - min(angles_above);
        fprintf('  -10 dB beamwidth: %.0f deg (from %.0f to %.0f deg offset)\n', ...
            bw_10dB, min(angles_above), max(angles_above));
    end
end

function noise_floor = noise_floor_calc_v2(pdp)
    % USC noise floor: 25th percentile + 5.41 dB (in dB)
    pdp_sort2 = sort(10*log10(pdp));
    pdp_sort = pdp_sort2(isfinite(pdp_sort2));
    N = length(pdp_sort);
    N_noise = max(1, round(N/4));
    Noise_value = pdp_sort(N_noise);
    noise_floor = Noise_value + 5.41;
end

function rmsds = computeDSonMPC(delay_vec, power_vec)
    % RMS Delay Spread from power-weighted delay variance
    if isempty(delay_vec) || length(delay_vec) < 2
        rmsds = 0;
        return;
    end
    delay_vec = delay_vec(:);
    power_vec = power_vec(:);
    power_vec_linear = db2pow(power_vec);
    meann = delay_vec' * power_vec_linear / sum(power_vec_linear);
    varr = (delay_vec.^2)' * power_vec_linear / sum(power_vec_linear);
    rmsds = sqrt(max(0, varr - meann^2));
    if imag(rmsds) < 1e-3
        rmsds = real(rmsds);
    end
end

function [ASA_NYU_10, ASA_NYU_15, ASA_NYU_20, ASA_USC, ...
          ASD_NYU_10, ASD_NYU_15, ASD_NYU_20, ASD_USC, aps_data] = ...
        compute_AS_from_PDP_4D(PDP_dir_lin_thresh, params, config, antenna_pattern)
    % Compute Angular Spread from 4D PDP data (already thresholded)

    % Sum over delay -> power per antenna direction
    Power_per_antenna = squeeze(sum(PDP_dir_lin_thresh, 1));

    % Sum over RX elevations
    Power_per_antenna_noelev = sum(Power_per_antenna, 3);

    % APS for TX (ASD) and RX (ASA)
    APS_Tx = sum(Power_per_antenna_noelev, 2);    % [N_aztx x 1]
    APS_Rx = sum(Power_per_antenna_noelev, 1).';   % [N_azrx x 1]

    aps_data.APS_Tx = APS_Tx;
    aps_data.APS_Rx = APS_Rx;
    aps_data.angles_Tx = params.txAz;
    aps_data.angles_Rx = params.rxAz;

    % NYU AS method: PAS threshold + antenna pattern lobe expansion
    ASA_NYU_10 = compute_AS_NYU_method(params.rxAz, APS_Rx, config.PAS_threshold_1, antenna_pattern, params.HPBW);
    ASA_NYU_15 = compute_AS_NYU_method(params.rxAz, APS_Rx, config.PAS_threshold_2, antenna_pattern, params.HPBW);
    ASA_NYU_20 = compute_AS_NYU_method(params.rxAz, APS_Rx, config.PAS_threshold_3, antenna_pattern, params.HPBW);

    ASD_NYU_10 = compute_AS_NYU_method(params.txAz, APS_Tx, config.PAS_threshold_1, antenna_pattern, params.HPBW);
    ASD_NYU_15 = compute_AS_NYU_method(params.txAz, APS_Tx, config.PAS_threshold_2, antenna_pattern, params.HPBW);
    ASD_NYU_20 = compute_AS_NYU_method(params.txAz, APS_Tx, config.PAS_threshold_3, antenna_pattern, params.HPBW);

    % USC AS method: no PAS threshold
    ASA_USC = compute_AS_3GPP(params.rxAz, APS_Rx);
    ASD_USC = compute_AS_3GPP(params.txAz, APS_Tx);
end

function AS = compute_AS_NYU_method(angles, powers, pas_threshold_dB, antenna_pattern, HPBW)
    % NYU Angular Spread with lobe detection + boundary expansion
    % 1. PAS threshold (10/15/20 dB below peak)
    % 2. Lobe detection: gap > HPBW = separate lobes
    % 3. Boundary expansion using antenna pattern
    % 4. 3GPP formula on combined MPCs

    angles = angles(:);
    powers = powers(:);

    if isempty(powers) || max(powers) <= 0
        AS = 0;
        return;
    end

    powers_dB = 10*log10(powers + eps);
    peak_dB = max(powers_dB);
    threshold_dB = peak_dB - pas_threshold_dB;

    mask = powers_dB >= threshold_dB;
    if ~any(mask)
        [~, idx] = max(powers);
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

    % Lobe detection
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
            if diff_ang < 0, diff_ang = diff_ang + 360; end

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

    % Boundary expansion using USC antenna pattern
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
            boundary_angles(end+1) = boundary_angle_start; %#ok<AGROW>
            boundary_powers_dB(end+1) = threshold_dB; %#ok<AGROW>

            % Expand end boundary (right side)
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
    all_powers_lin = all_powers_lin / sum(all_powers_lin);

    % 3GPP formula
    AS = compute_AS_3GPP(all_angles, all_powers_lin);
end

function AS = compute_AS_3GPP(angles, powers)
    % 3GPP Angular Spread: AS = sqrt(-2 * ln(R)) [degrees]
    angles = angles(:);
    powers = powers(:);

    if isempty(powers) || sum(powers) <= 0
        AS = 0;
        return;
    end

    w = powers / sum(powers);
    ang_rad = deg2rad(angles);
    R = abs(sum(w .* exp(1j * ang_rad)));

    if R >= 1, AS = 0; return; end
    if R <= 0, AS = 180; return; end

    s0_rad = sqrt(-2 * log(R));
    AS = rad2deg(s0_rad);
end

function plot_bland_altman_subplot(methodA, methodB, isLOS, isNLOS, ylbl, xlbl, metricName, colors)
    % Bland-Altman subplot with LOS and NLOS markers
    diff_vals = methodA - methodB;
    mean_vals = (methodA + methodB) / 2;

    hold on; grid on; box on;

    if any(isLOS)
        scatter(mean_vals(isLOS), diff_vals(isLOS), 40, colors.LOS, 'filled', 'o', 'DisplayName', 'LOS');
    end
    if any(isNLOS)
        scatter(mean_vals(isNLOS), diff_vals(isNLOS), 40, colors.NLOS, 'filled', 's', 'DisplayName', 'NLOS');
    end

    valid = isfinite(diff_vals);
    bias = mean(diff_vals(valid));
    sd = std(diff_vals(valid));
    yline(bias, 'k-', 'LineWidth', 1.5);
    yline(bias + 1.96*sd, 'r--', 'LineWidth', 1);
    yline(bias - 1.96*sd, 'r--', 'LineWidth', 1);
    yline(0, 'k:', 'LineWidth', 0.8);

    xlabel(xlbl, 'FontSize', 9);
    ylabel(ylbl, 'FontSize', 9);
    title(sprintf('(%s) $\\mu$=%.2f, $\\sigma$=%.2f', metricName, bias, sd), ...
        'FontSize', 9, 'FontWeight', 'bold');
    legend('Location', 'best', 'FontSize', 7, 'Box', 'off');
    set(gca, 'FontSize', 8);
end

function print_stats(name, vals, unit)
    vals = vals(isfinite(vals));
    if ~isempty(vals)
        fprintf('  %-20s: mean=%7.2f, std=%6.2f, min=%7.2f, max=%7.2f %s\n', ...
            name, mean(vals), std(vals), min(vals), max(vals), unit);
    end
end

function saveFigure(fig, folder, name)
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

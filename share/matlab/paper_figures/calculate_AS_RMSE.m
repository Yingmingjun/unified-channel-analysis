%% Calculate RMSE for ASA and ASD from Tables N3 and U3
% This script extracts the AS values and computes RMSE for the paper table

clear; clc;

%% Table N3: USC perDelayMax method, NYU Data (142 GHz)
% Columns: [USC thres, NYU thres, NYU orig (N1)] for ASA and ASD
% Note: Exclude outage locations (TX2-RX14, TX1-RX18, TX4-RX38 have 0.00 for all)

% ASA values from Table N3 [USC thres, NYU thres, NYU orig (N1)]
N3_ASA = [
    9.26,   3.26,   3.26;   % TX1-RX1
    10.26,  3.26,   3.26;   % TX1-RX5
    30.82,  3.26,   3.26;   % TX1-RX9
    0.00,   3.26,   3.26;   % TX1-RX14
    21.39,  29.36,  29.36;  % TX1-RX16
    0.00,   0.00,   0.00;   % TX1-RX18 (outage - exclude)
    46.37,  51.60,  51.60;  % TX1-RX23
    3.99,   3.26,   3.26;   % TX1-RX27
    6.00,   3.26,   3.26;   % TX1-RX31
    3.52,   3.26,   3.26;   % TX2-RX1
    % TX2-RX14 is Outage - exclude
    19.05,  3.26,   3.26;   % TX2-RX35
    10.52,  3.26,   3.26;   % TX2-RX36
    0.00,   3.26,   3.26;   % TX3-RX1
    11.24,  13.32,  13.32;  % TX3-RX35
    2.23,   3.26,   3.26;   % TX3-RX36
    2.23,   3.26,   3.26;   % TX3-RX37
    0.00,   3.26,   3.26;   % TX4-RX1
    3.42,   4.91,   4.91;   % TX4-RX3
    9.84,   7.13,   7.13;   % TX4-RX37
    0.00,   0.00,   0.00;   % TX4-RX38 (outage - exclude)
    44.53,  56.49,  56.49;  % TX5-RX1
    7.25,   3.26,   3.26;   % TX5-RX3
    3.64,   5.16,   5.16;   % TX5-RX10
    2.74,   3.26,   3.26;   % TX5-RX35
    6.25,   4.68,   4.68;   % TX6-RX1
    60.53,  61.34,  61.34;  % TX6-RX39
    23.02,  32.53,  32.53;  % TX6-RX40
];

% ASD values from Table N3 [USC thres, NYU thres, NYU orig (N1)]
N3_ASD = [
    8.25,   3.26,   3.26;   % TX1-RX1
    1.96,   3.26,   3.26;   % TX1-RX5
    0.00,   3.26,   3.26;   % TX1-RX9
    0.00,   3.26,   3.26;   % TX1-RX14
    0.00,   3.26,   3.26;   % TX1-RX16
    0.00,   0.00,   0.00;   % TX1-RX18 (outage - exclude)
    4.95,   5.40,   5.40;   % TX1-RX23
    0.32,   3.26,   3.26;   % TX1-RX27
    2.98,   3.26,   3.26;   % TX1-RX31
    3.21,   3.26,   3.26;   % TX2-RX1
    % TX2-RX14 is Outage - exclude
    5.77,   3.26,   3.26;   % TX2-RX35
    3.21,   3.26,   3.26;   % TX2-RX36
    0.00,   3.26,   3.26;   % TX3-RX1
    20.21,  24.49,  24.49;  % TX3-RX35
    2.09,   3.26,   3.26;   % TX3-RX36
    1.55,   3.26,   3.26;   % TX3-RX37
    0.00,   3.26,   3.26;   % TX4-RX1
    2.13,   3.26,   3.26;   % TX4-RX3
    12.64,  13.83,  13.83;  % TX4-RX37
    0.00,   0.00,   0.00;   % TX4-RX38 (outage - exclude)
    9.04,   10.07,  10.07;  % TX5-RX1
    7.35,   3.26,   3.26;   % TX5-RX3
    3.78,   5.18,   5.18;   % TX5-RX10
    1.98,   3.26,   3.26;   % TX5-RX35
    3.72,   4.85,   4.85;   % TX6-RX1
    30.70,  31.59,  31.59;  % TX6-RX39
    18.33,  3.26,   3.26;   % TX6-RX40
];

% Remove outage rows (rows where all values are 0)
N3_ASA_valid = N3_ASA(~(N3_ASA(:,1)==0 & N3_ASA(:,2)==0 & N3_ASA(:,3)==0), :);
N3_ASD_valid = N3_ASD(~(N3_ASD(:,1)==0 & N3_ASD(:,2)==0 & N3_ASD(:,3)==0), :);

% Calculate RMSE for N3
% USC thres vs NYU orig (N1)
RMSE_N3_ASA_USC = sqrt(mean((N3_ASA_valid(:,1) - N3_ASA_valid(:,3)).^2));
RMSE_N3_ASD_USC = sqrt(mean((N3_ASD_valid(:,1) - N3_ASD_valid(:,3)).^2));

% NYU thres vs NYU orig (N1)
RMSE_N3_ASA_NYU = sqrt(mean((N3_ASA_valid(:,2) - N3_ASA_valid(:,3)).^2));
RMSE_N3_ASD_NYU = sqrt(mean((N3_ASD_valid(:,2) - N3_ASD_valid(:,3)).^2));

fprintf('=== Table N3: USC perDelayMax method, NYU Data ===\n');
fprintf('ASA RMSE (USC thres vs N1): %.2f°\n', RMSE_N3_ASA_USC);
fprintf('ASA RMSE (NYU thres vs N1): %.2f°\n', RMSE_N3_ASA_NYU);
fprintf('ASD RMSE (USC thres vs N1): %.2f°\n', RMSE_N3_ASD_USC);
fprintf('ASD RMSE (NYU thres vs N1): %.2f°\n', RMSE_N3_ASD_NYU);
fprintf('\n');

%% Table U3: NYU SUM method, USC Data (145 GHz)
% Columns: [NYU thres, USC thres, USC orig (U1)] for ASA and ASD

% ASA values from Table U3 [NYU thres, USC thres, USC orig (U1)]
U3_ASA = [
    % LOS
    27.79,  30.17,  30.17;  % RX1 LOS
    8.43,   17.70,  17.70;  % RX2 LOS
    10.74,  10.41,  10.41;  % RX3 LOS
    8.41,   13.91,  13.91;  % RX4 LOS
    8.46,   11.98,  11.98;  % RX5 LOS
    15.86,  28.97,  28.97;  % RX6 LOS
    10.78,  13.21,  13.21;  % RX7 LOS
    8.54,   10.45,  10.45;  % RX8 LOS
    10.79,  10.76,  10.76;  % RX9 LOS
    10.63,  22.22,  22.22;  % RX10 LOS
    8.40,   11.51,  11.51;  % RX11 LOS
    10.75,  11.56,  11.56;  % RX12 LOS
    12.63,  12.13,  12.13;  % RX13 LOS
    % NLOS
    11.06,  19.75,  19.75;  % RX1 NLOS
    24.92,  26.77,  26.77;  % RX2 NLOS
    29.24,  29.95,  29.95;  % RX3 NLOS
    45.05,  50.01,  50.01;  % RX4 NLOS
    79.67,  81.15,  81.15;  % RX5 NLOS
    53.35,  54.50,  54.50;  % RX6 NLOS
    8.89,   19.72,  19.72;  % RX7 NLOS
    11.07,  11.18,  11.18;  % RX8 NLOS
    18.08,  21.34,  21.34;  % RX9 NLOS
    13.49,  22.22,  22.22;  % RX10 NLOS
    20.71,  26.06,  26.06;  % RX11 NLOS
    10.95,  11.04,  11.04;  % RX12 NLOS
    15.17,  28.30,  28.30;  % RX13 NLOS
];

% ASD values from Table U3 [NYU thres, USC thres, USC orig (U1)]
U3_ASD = [
    % LOS
    11.39,  12.22,  12.22;  % RX1 LOS
    11.03,  12.30,  12.30;  % RX2 LOS
    8.88,   9.91,   9.91;   % RX3 LOS
    10.80,  11.34,  11.34;  % RX4 LOS
    8.58,   10.84,  10.84;  % RX5 LOS
    8.73,   14.26,  14.26;  % RX6 LOS
    11.23,  10.10,  10.10;  % RX7 LOS
    8.63,   9.25,   9.25;   % RX8 LOS
    8.82,   9.22,   9.22;   % RX9 LOS
    8.88,   13.28,  13.28;  % RX10 LOS
    8.78,   9.57,   9.57;   % RX11 LOS
    9.06,   9.33,   9.33;   % RX12 LOS
    12.80,  10.98,  10.98;  % RX13 LOS
    % NLOS
    47.44,  45.19,  45.19;  % RX1 NLOS
    31.84,  31.25,  31.25;  % RX2 NLOS
    28.78,  26.91,  26.91;  % RX3 NLOS
    11.22,  15.59,  15.59;  % RX4 NLOS
    24.09,  22.40,  22.40;  % RX5 NLOS
    19.78,  21.02,  21.02;  % RX6 NLOS
    11.03,  10.68,  10.68;  % RX7 NLOS
    10.75,  9.68,   9.68;   % RX8 NLOS
    26.43,  26.28,  26.28;  % RX9 NLOS
    13.15,  14.01,  14.01;  % RX10 NLOS
    18.89,  17.04,  17.04;  % RX11 NLOS
    10.91,  9.22,   9.22;   % RX12 NLOS
    28.21,  28.16,  28.16;  % RX13 NLOS
];

% Calculate RMSE for U3
% NYU thres vs USC orig (U1)
RMSE_U3_ASA_NYU = sqrt(mean((U3_ASA(:,1) - U3_ASA(:,3)).^2));
RMSE_U3_ASD_NYU = sqrt(mean((U3_ASD(:,1) - U3_ASD(:,3)).^2));

% USC thres vs USC orig (U1)
RMSE_U3_ASA_USC = sqrt(mean((U3_ASA(:,2) - U3_ASA(:,3)).^2));
RMSE_U3_ASD_USC = sqrt(mean((U3_ASD(:,2) - U3_ASD(:,3)).^2));

fprintf('=== Table U3: NYU SUM method, USC Data ===\n');
fprintf('ASA RMSE (NYU thres vs U1): %.2f°\n', RMSE_U3_ASA_NYU);
fprintf('ASA RMSE (USC thres vs U1): %.2f°\n', RMSE_U3_ASA_USC);
fprintf('ASD RMSE (NYU thres vs U1): %.2f°\n', RMSE_U3_ASD_NYU);
fprintf('ASD RMSE (USC thres vs U1): %.2f°\n', RMSE_U3_ASD_USC);
fprintf('\n');

%% Summary for Paper Table
fprintf('=====================================\n');
fprintf('SUMMARY FOR PAPER TABLE (Tab:RMSE_th)\n');
fprintf('=====================================\n');
fprintf('\n');
fprintf('                  | USC Data, NYU SUM (U3)  | NYU Data, USC perDelayMax (N3) |\n');
fprintf('                  | NYU Thr   | USC Thr     | USC Thr    | NYU Thr           |\n');
fprintf('------------------+-----------+-------------+------------+-------------------|\n');
fprintf('ASA [°]           | %.2f      | %.2f        | %.2f       | %.2f              |\n', ...
    RMSE_U3_ASA_NYU, RMSE_U3_ASA_USC, RMSE_N3_ASA_USC, RMSE_N3_ASA_NYU);
fprintf('ASD [°]           | %.2f      | %.2f        | %.2f       | %.2f              |\n', ...
    RMSE_U3_ASD_NYU, RMSE_U3_ASD_USC, RMSE_N3_ASD_USC, RMSE_N3_ASD_NYU);
fprintf('\n');

%% LaTeX formatted output
fprintf('LaTeX Table Values:\n');
fprintf('ASA [°] & %.2f & %.2f & %.2f & %.2f \\\\\n', ...
    RMSE_U3_ASA_NYU, RMSE_U3_ASA_USC, RMSE_N3_ASA_USC, RMSE_N3_ASA_NYU);
fprintf('ASD [°] & %.2f & %.2f & %.2f & %.2f \\\\\n', ...
    RMSE_U3_ASD_NYU, RMSE_U3_ASD_USC, RMSE_N3_ASD_USC, RMSE_N3_ASD_NYU);

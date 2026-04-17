%% Set up files
clear variables;
close all;
clc;
dbstop if error
tic

basePath="C:\Users\Dipankar\Documents\MATLABExperiments\NaveedDipankarMingjunJorgeShare\USC\USCformatNYUdata\";

rootDir=dir(basePath+"USCformat_142GHz*");
rootDir=rootDir(~ismember({rootDir.name},{'.','..'}));
TR_str=string(natsortfiles({rootDir.name}))';
nTR=length(TR_str);

% Extract the variables using regular expressions
pattern = 'USCformat_142GHz_(?<Env>[^_]+)_T(?<TXID>\d+)-R(?<RXID>\d+)_(?<TR_distance>[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?)m.mat';

% Extract using regexp
match = regexp(TR_str, pattern, 'names');

if ~isempty(match)
    % Extract the variables
    Env = string(cellfun(@(x) x.Env, match, 'UniformOutput', false));
    TXID = cellfun(@(x) str2double(x.TXID), match);
    RXID = cellfun(@(x) str2double(x.RXID), match);
    TR_distance = cellfun(@(x) str2double(x.TR_distance), match);
end

%% Define per-link transmit powers (dBm)
% TX1 has per-RX powers; TX2–TX6 are uniform per TX
Ptx_map = containers.Map('KeyType','char','ValueType','double');

% TX1 — individual per RX
Ptx_map('1_1')   = -3.50;
Ptx_map('1_5')   = -3.50;
Ptx_map('1_9')   = -1.50;
Ptx_map('1_14')  = -1.20;
Ptx_map('1_16')  = -1.20;
Ptx_map('1_18')  = -1.20;
Ptx_map('1_23')  = -1.50;
Ptx_map('1_27')  = -1.87;
Ptx_map('1_31')  = -1.87;

% TX2 — uniform -2 dBm
TX2_RXs = [1, 14, 35, 36];
for i = 1:length(TX2_RXs)
    Ptx_map(sprintf('%d_%d', 2, TX2_RXs(i))) = -2.00;
end

% TX3 — uniform -1.37 dBm
TX3_RXs = [1, 35, 36, 37];
for i = 1:length(TX3_RXs)
    Ptx_map(sprintf('%d_%d', 3, TX3_RXs(i))) = -1.37;
end

% TX4 — uniform -1.72 dBm
TX4_RXs = [1, 3, 37, 38];
for i = 1:length(TX4_RXs)
    Ptx_map(sprintf('%d_%d', 4, TX4_RXs(i))) = -1.72;
end

% TX5 — uniform -3 dBm
TX5_RXs = [1, 3, 10, 35];
for i = 1:length(TX5_RXs)
    Ptx_map(sprintf('%d_%d', 5, TX5_RXs(i))) = -3.00;
end

% TX6 — uniform -1.55 dBm
TX6_RXs = [1, 39, 40];
for i = 1:length(TX6_RXs)
    Ptx_map(sprintf('%d_%d', 6, TX6_RXs(i))) = -1.55;
end

%% Process all TX-RX pairs
omniRes=cell(nTR,12);
% Column layout:
% 1:TX ID | 2:RX ID | 3:TR distance | 4:Omni PDP| 
% 5:OmniPL | 6:OmniDS | 7:OmniASA | 8:OmniZSA | 9:OmniASD | 
% 10:OmniZSD | 11:OmniPDP undilated | 12:Noise Th |
%
% PL = Ptx + G_tx(27dBi) + G_rx(27dBi) - Pr_omni
thr=5; % X dB above the noise floor

for iTR=1:nTR
    % Look up the transmit power for this link
    key = sprintf('%d_%d', TXID(iTR), RXID(iTR));
    Ptx = Ptx_map(key);

    % Pass TX_RX key to match thresholded PDP metadata for noise evaluation
    [omniPDP,omniPDP_S,oPL,oDS,oASA,oZSA,oASD,oZSD,noise_thres]=USCprocessing_NYUth_Sp(basePath,TR_str(iTR),TR_distance(iTR),Ptx,thr,key);
    omniRes{iTR,1}=TXID(iTR);
    omniRes{iTR,2}=RXID(iTR);
    omniRes{iTR,3}=TR_distance(iTR);
    omniRes{iTR,4}=omniPDP;
    omniRes{iTR,5}=oPL;
    omniRes{iTR,6}=oDS;
    omniRes{iTR,7}=oASA;
    omniRes{iTR,8}=oZSA;
    omniRes{iTR,9}=oASD;
    omniRes{iTR,10}=oZSD;
    omniRes{iTR,11}=omniPDP_S;
    omniRes{iTR,12}=noise_thres;
end

save("USCprocessingResults_NYUth_Sp2.mat","omniRes");

%% ---------------------------------------------------------------
%  Path-Loss Validation & Visualization
%  Reference values from 142_UMi.xlsx → FinalTable
%  ---------------------------------------------------------------

% Reference table: [TXID, RXID, TR_distance, PL_reference]
PL_ref = [
     1,  1,  24.43, 102.638833;
     1,  5,  27.22, 102.141585;
     1,  9,  32.65, 126.495989;
     1, 14,  45.95, 129.808204;
     1, 16,  49.40, 126.950129;
     1, 18,  52.84, 137.069436;
     1, 23,  43.34, 110.835801;
     1, 27,  38.03, 104.407280;
     1, 31,  36.09, 105.059206;
     2,  1,  83.60, 112.048285;
     2, 35,  59.31, 109.245860;
     2, 36,  36.92, 105.665050;
     3,  1,  72.88, 130.637161;
     3, 35,  74.80, 116.783518;
     3, 36,  82.48, 114.669616;
     3, 37,  96.40, 120.619299;
     4,  1, 117.43, 129.968558;
     4,  3, 117.25, 115.032288;
     4, 37,  44.31, 106.820101;
     4, 38,  52.01, 139.915375;
     5,  1,  61.45, 115.429611;
     5,  3,  61.35, 107.198401;
     5, 10,  65.63, 122.648049;
     5, 35,  85.64, 109.657665;
     6,  1,  39.08, 105.584988;
     6, 39,  48.65, 114.744850;
     6, 40,  53.02, 121.685217;
];

nRef = size(PL_ref,1);

% Build arrays by matching omniRes rows to reference rows
PL_computed  = zeros(nRef,1);
PL_expected  = PL_ref(:,4);
TR_dist      = PL_ref(:,3);
linkLabels   = cell(nRef,1);
txids        = PL_ref(:,1);
rxids        = PL_ref(:,2);

for k = 1:nRef
    % Find the matching row in omniRes
    for iTR = 1:nTR
        if omniRes{iTR,1}==PL_ref(k,1) && omniRes{iTR,2}==PL_ref(k,2)
            PL_computed(k) = omniRes{iTR,5};
            break;
        end
    end
    linkLabels{k} = sprintf('T%d-R%d', PL_ref(k,1), PL_ref(k,2));
end

PL_error = PL_computed - PL_expected;   % positive → computed > expected

% Identify LOS vs NLOS from the reference table for colouring
% LOS links (from 142_UMi.xlsx)
LOS_links = [1,1; 1,5; 1,23; 1,27; 1,31; 2,1; 2,35; 2,36;
             3,35; 3,36; 3,37; 4,3; 4,37; 5,3; 5,35; 6,1];
isLOS = false(nRef,1);
for k = 1:nRef
    for m = 1:size(LOS_links,1)
        if PL_ref(k,1)==LOS_links(m,1) && PL_ref(k,2)==LOS_links(m,2)
            isLOS(k) = true;
            break;
        end
    end
end

%% --- Figure 1: Computed vs Reference PL (scatter with 1:1 line) ---
fig1 = figure('Name','PL Computed vs Reference','Position',[100,100,900,650]);
ax1 = axes(fig1);
hold(ax1, 'on');
box(ax1, 'on');
ax1.FontSize = 12;

% Scatter: LOS and NLOS in different colours
h1 = scatter(ax1, PL_expected(isLOS),  PL_computed(isLOS),  90, [0 0.45 0.74], 'o', ...
    'LineWidth',1.5, 'MarkerEdgeColor','k', 'MarkerFaceColor',[0.60 0.78 0.92]);
h2 = scatter(ax1, PL_expected(~isLOS), PL_computed(~isLOS), 90, [0.85 0.33 0.10], 's', ...
    'LineWidth',1.5, 'MarkerEdgeColor','k', 'MarkerFaceColor',[0.98 0.78 0.68]);

% 1:1 reference line (limit by reference range)
allPL = [PL_expected; PL_computed];
pmin = floor(min(PL_expected)-2);
pmax = ceil(max(PL_expected)+2);
h3 = plot(ax1, [pmin pmax], [pmin pmax], 'k--', 'LineWidth',1.2);

% ±1 dB tolerance band
h4 = fill(ax1, [pmin pmax pmax pmin], [pmin-1 pmax-1 pmax+1 pmin+1], ...
     0.85*[1 1 1], 'FaceAlpha',0.35, 'EdgeColor','none');

ax1.XLabel.String = 'Reference PL (dB)';
ax1.YLabel.String = 'Computed PL (dB)';
ax1.Title.String  = '142 GHz UMi — Path Loss: Computed vs Reference';
ax1.XLim = [pmin pmax];
ax1.YLim = [pmin pmax];
grid(ax1, 'on');
if isprop(ax1, 'GridAlpha')
    ax1.GridAlpha = 0.3;
end
axis(ax1, 'square');
legend(ax1, [h1 h2 h3 h4], {'LOS','NLOS','1:1 line','±1 dB band'}, 'Location','northwest');

%% --- Figure 2: Per-link PL error bar chart ---
fig2 = figure('Name','PL Error per Link','Position',[100,800,1200,500]);
ax2 = axes(fig2);
hold(ax2, 'on');
box(ax2, 'on');
ax2.FontSize = 11;

x = 1:nRef;
barColours = zeros(nRef,3);
barColours(isLOS,:)  = repmat([0 0.45 0.74], sum(isLOS),1);   % blue for LOS
barColours(~isLOS,:) = repmat([0.85 0.33 0.10], sum(~isLOS),1); % orange for NLOS

% ±1 dB tolerance band
yband = [-1 1];
h5 = fill(ax2, [0.5 nRef+0.5 nRef+0.5 0.5], [yband(1) yband(1) yband(2) yband(2)], ...
     [0.90 0.90 0.90], 'FaceAlpha',0.5, 'EdgeColor','none');
plot(ax2, [0.5 nRef+0.5], [0 0], 'k-', 'LineWidth',1);

% Bar chart (single object for stable colors)
b = bar(ax2, x, PL_error, 0.7, 'EdgeColor','k', 'LineWidth',0.8);
b.FaceColor = 'flat';
b.CData = barColours;

set(ax2, 'XTick', x, 'XTickLabel', linkLabels, 'XTickLabelRotation', 45);
ax2.XLabel.String = 'TX–RX Link';
ax2.YLabel.String = 'PL Error  (dB)  [Computed − Reference]';
ax2.Title.String  = '142 GHz UMi — Path Loss Error per Link';
grid(ax2, 'on');
if isprop(ax2, 'GridAlpha')
    ax2.GridAlpha = 0.3;
end
%ymax = max(1.5, max(abs(PL_error)) + 0.5);
%ax2.YLim = [-2 8];

% Legend (dummy handles for stable colors)
h6 = plot(ax2, NaN, NaN, 's', 'MarkerSize',8, 'MarkerFaceColor',[0 0.45 0.74], 'MarkerEdgeColor','k');
h7 = plot(ax2, NaN, NaN, 's', 'MarkerSize',8, 'MarkerFaceColor',[0.85 0.33 0.10], 'MarkerEdgeColor','k');
h8 = patch(ax2, NaN, NaN, [0.90 0.90 0.90], 'EdgeColor','none', 'FaceAlpha',0.5);
legend(ax2, [h6 h7 h8], {'LOS','NLOS','±1 dB band'}, 'Location','best');

%% --- Figure 3: PL vs TR distance (computed & reference, same axes) ---
fig3 = figure('Name','PL vs TR Distance','Position',[100,1500,950,600]);
ax3 = axes(fig3);
hold(ax3, 'on');
box(ax3, 'on');
ax3.FontSize = 12;

% Reference markers
h9  = scatter(ax3, TR_dist(isLOS),  PL_expected(isLOS),  80, [0 0.45 0.74],    'o', ...
    'LineWidth',1.5, 'MarkerEdgeColor','k', 'MarkerFaceColor',[0.60 0.78 0.92]);
h10 = scatter(ax3, TR_dist(~isLOS), PL_expected(~isLOS), 80, [0.85 0.33 0.10], 's', ...
    'LineWidth',1.5, 'MarkerEdgeColor','k', 'MarkerFaceColor',[0.98 0.78 0.68]);

% Computed markers (hollow, same shape)
h11 = scatter(ax3, TR_dist(isLOS),  PL_computed(isLOS),  80, [0 0.45 0.74],    'o', ...
    'LineWidth',1.8, 'MarkerFaceColor','none', 'MarkerEdgeColor',[0 0.45 0.74]);
h12 = scatter(ax3, TR_dist(~isLOS), PL_computed(~isLOS), 80, [0.85 0.33 0.10], 's', ...
    'LineWidth',1.8, 'MarkerFaceColor','none', 'MarkerEdgeColor',[0.85 0.33 0.10]);

% Free-space path loss reference (FSPL = 20log10(d) + 20log10(f) + 32.44, f in GHz, d in m)
d_fspl = linspace(min(TR_dist)-5, max(TR_dist)+5, 200);
FSPL = 20*log10(d_fspl) + 20*log10(142) + 32.44;
h13 = plot(ax3, d_fspl, FSPL, 'k:', 'LineWidth',1.2);

ax3.XLabel.String = 'TX–RX Separation (m)';
ax3.YLabel.String = 'Path Loss (dB)';
ax3.Title.String  = '142 GHz UMi — Path Loss vs Distance';
grid(ax3, 'on');
if isprop(ax3, 'GridAlpha')
    ax3.GridAlpha = 0.3;
end
legend(ax3, [h9 h10 h11 h12 h13], {'Ref LOS','Ref NLOS','Comp LOS','Comp NLOS','FSPL'}, 'Location','best');

%% --- Print summary table to console ---
fprintf('\n%s\n', repmat('=',1,75));
fprintf('  PATH LOSS VALIDATION SUMMARY — 142 GHz UMi\n');
fprintf('%s\n', repmat('=',1,75));
fprintf('%-12s %8s %10s %10s %10s %6s\n', 'Link','d (m)','PL Ref','PL Comp','Error','Type');
fprintf('%s\n', repmat('-',1,75));
for k = 1:nRef
    if isLOS(k)
        typeStr = 'LOS';
    else
        typeStr = 'NLOS';
    end
    fprintf('%-12s %8.2f %10.4f %10.4f %+10.4f %6s\n', ...
            linkLabels{k}, TR_dist(k), PL_expected(k), PL_computed(k), PL_error(k), typeStr);
end
fprintf('%s\n', repmat('-',1,75));
fprintf('  Max absolute error : %+.4f dB  (%s)\n', ...
        max(abs(PL_error)), linkLabels{find(abs(PL_error)==max(abs(PL_error)),1)});
fprintf('  Mean absolute error: %.4f dB\n', mean(abs(PL_error)));
fprintf('  RMS error          : %.4f dB\n', sqrt(mean(PL_error.^2)));
fprintf('  Links within ±1 dB : %d / %d\n', sum(abs(PL_error)<=1), nRef);
fprintf('%s\n\n', repmat('=',1,75));

toc

%% ---------------------------------------------------------------
%  Delay-Spread Validation & Visualization
%  Reference values from 142_UMi.xlsx â†’ FinalTable (FinalData if present)
%  ---------------------------------------------------------------

% Load reference table and pick the expected sheet name if it exists.
refXlsx = fullfile(pwd, 'OriginalNYU_pointData', '142_UMi.xlsx');
[~, sheetNames] = xlsfinfo(refXlsx);
sheetName = '';
if any(strcmpi(sheetNames, 'FinalData'))
    sheetName = 'FinalData';
elseif any(strcmpi(sheetNames, 'FinalTable'))
    sheetName = 'FinalTable';
else
    error('No FinalData/FinalTable sheet found in %s', refXlsx);
end
refTbl = readtable(refXlsx, 'Sheet', sheetName);

% Forward-fill TX/RX when the columns are sparse (as in FinalTable).
% Drop rows where BOTH TX and RX are missing (e.g., summary rows).
txRaw = string(refTbl.TX);
rxRaw = string(refTbl.RX);
txRaw = standardizeMissing(txRaw, ["", " "]);
rxRaw = standardizeMissing(rxRaw, ["", " "]);
dropRows = ismissing(txRaw) & ismissing(rxRaw);
refTbl = refTbl(~dropRows, :);
txRaw = txRaw(~dropRows);
rxRaw = rxRaw(~dropRows);
txRaw = fillmissing(txRaw, 'previous');
rxRaw = fillmissing(rxRaw, 'previous');

% Extract numeric TX/RX IDs from labels like "TX1"/"RX35".
TXID_ref = str2double(regexp(txRaw, '\d+', 'match', 'once'));
RXID_ref = str2double(regexp(rxRaw, '\d+', 'match', 'once'));

% Pull omni DS and TR distance, coercing to numeric.
omniDS_ref = refTbl.("OmniDS");
if iscell(omniDS_ref)
    omniDS_ref = str2double(string(omniDS_ref));
else
    omniDS_ref = double(omniDS_ref);
end
TR_sep_ref = refTbl.("TRSep");
if iscell(TR_sep_ref)
    TR_sep_ref = str2double(string(TR_sep_ref));
else
    TR_sep_ref = double(TR_sep_ref);
end

% Optional LOS/NLOS flag (if available).
isLOS_DS = false(height(refTbl), 1);
if ismember('LocType', refTbl.Properties.VariableNames)
    locType = string(refTbl.("LocType"));
    locType = fillmissing(locType, 'previous');
    isLOS_DS = strcmpi(locType, 'LOS');
end

% Keep rows with valid numeric DS + IDs.
keepDS = isfinite(TXID_ref) & isfinite(RXID_ref) & isfinite(omniDS_ref);
TXID_ref = TXID_ref(keepDS);
RXID_ref = RXID_ref(keepDS);
TR_sep_ref = TR_sep_ref(keepDS);
omniDS_ref = omniDS_ref(keepDS);
isLOS_DS = isLOS_DS(keepDS);
nRefDS = numel(omniDS_ref);

% Match computed omni DS from omniRes to reference rows.
% omniRes stores DS in dB (10*log10(seconds)); convert to seconds (linear),
% then to nanoseconds to match the reference table.
omniDS_comp = zeros(nRefDS, 1);
linkLabelsDS = cell(nRefDS, 1);
for k = 1:nRefDS
    for iTR = 1:nTR
        if omniRes{iTR,1}==TXID_ref(k) && omniRes{iTR,2}==RXID_ref(k)
            ds_db = omniRes{iTR,6};
            ds_s = 10.^(ds_db/10);
            omniDS_comp(k) = ds_s * 1e9;
            break;
        end
    end
    linkLabelsDS{k} = sprintf('T%d-R%d', TXID_ref(k), RXID_ref(k));
end
DS_error = omniDS_comp - omniDS_ref;

%% --- Figure 4: Computed vs Reference Omni DS (ns) ---
fig4 = figure('Name','Omni DS Computed vs Reference','Position',[1100,100,900,650]);
ax4 = axes(fig4);
hold(ax4, 'on');
box(ax4, 'on');
ax4.FontSize = 12;

h41 = scatter(ax4, omniDS_ref(isLOS_DS),  omniDS_comp(isLOS_DS),  90, [0 0.45 0.74], 'o', ...
    'LineWidth',1.5, 'MarkerEdgeColor','k', 'MarkerFaceColor',[0.60 0.78 0.92]);
h42 = scatter(ax4, omniDS_ref(~isLOS_DS), omniDS_comp(~isLOS_DS), 90, [0.85 0.33 0.10], 's', ...
    'LineWidth',1.5, 'MarkerEdgeColor','k', 'MarkerFaceColor',[0.98 0.78 0.68]);

allDS = [omniDS_ref; omniDS_comp];
dmin = floor(min(allDS)-0.5);
dmax = ceil(max(allDS)+0.5);
h43 = plot(ax4, [dmin dmax], [dmin dmax], 'k--', 'LineWidth',1.2);

ax4.XLabel.String = 'Reference Omni DS (ns)';
ax4.YLabel.String = 'Computed Omni DS (ns)';
ax4.Title.String  = '142 GHz UMi Omni DS: Computed vs Reference';
ax4.XLim = [dmin dmax];
ax4.YLim = [dmin dmax];
grid(ax4, 'on');
if isprop(ax4, 'GridAlpha')
    ax4.GridAlpha = 0.3;
end
axis(ax4, 'square');
legend(ax4, [h41 h42 h43], {'LOS','NLOS','1:1 line'}, 'Location','best');

%% --- Figure 5: Per-link Omni DS error ---
fig5 = figure('Name','Omni DS Error per Link','Position',[1100,800,1200,500]);
ax5 = axes(fig5);
hold(ax5, 'on');
box(ax5, 'on');
ax5.FontSize = 11;

barColoursDS = zeros(nRefDS, 3);
barColoursDS(isLOS_DS,:)  = repmat([0 0.45 0.74], sum(isLOS_DS), 1);
barColoursDS(~isLOS_DS,:) = repmat([0.85 0.33 0.10], sum(~isLOS_DS), 1);
bDS = bar(ax5, 1:nRefDS, DS_error, 0.7, 'EdgeColor','k', 'LineWidth',0.8);
bDS.FaceColor = 'flat';
bDS.CData = barColoursDS;
plot(ax5, [0.5 nRefDS+0.5], [0 0], 'k-', 'LineWidth',1);

set(ax5, 'XTick', 1:nRefDS, 'XTickLabel', linkLabelsDS, 'XTickLabelRotation', 45);
ax5.XLabel.String = 'TX-RX Link';
ax5.YLabel.String = 'Omni DS Error (ns)  [Computed - Reference]';
ax5.Title.String  = '142 GHz UMi Omni DS Error per Link';
grid(ax5, 'on');
if isprop(ax5, 'GridAlpha')
    ax5.GridAlpha = 0.3;
end
ymaxDS = max(0.5, max(abs(DS_error)) + 0.2);
ax5.YLim = [-ymaxDS ymaxDS];

% Legend (dummy handles for stable colors)
h51 = plot(ax5, NaN, NaN, 's', 'MarkerSize',8, 'MarkerFaceColor',[0 0.45 0.74], 'MarkerEdgeColor','k');
h52 = plot(ax5, NaN, NaN, 's', 'MarkerSize',8, 'MarkerFaceColor',[0.85 0.33 0.10], 'MarkerEdgeColor','k');
legend(ax5, [h51 h52], {'LOS','NLOS'}, 'Location','best');

%% --- Print DS summary table to console ---
fprintf('\n%s\n', repmat('=',1,75));
fprintf('  DELAY SPREAD VALIDATION SUMMARY 142 GHz UMi\n');
fprintf('%s\n', repmat('=',1,75));
fprintf('%-12s %8s %12s %12s %10s %6s\n', 'Link','d (m)','DS Ref(ns)','DS Comp(ns)','Error','Type');
fprintf('%s\n', repmat('-',1,75));
for k = 1:nRefDS
    if isLOS_DS(k)
        typeStr = 'LOS';
    else
        typeStr = 'NLOS';
    end
    fprintf('%-12s %8.2f %12.4f %12.4f %+10.4f %6s\n', ...
            linkLabelsDS{k}, TR_sep_ref(k), omniDS_ref(k), omniDS_comp(k), DS_error(k), typeStr);
end
fprintf('%s\n', repmat('-',1,75));
fprintf('  Max absolute error : %+.4f  (%s)\n', ...
        max(abs(DS_error)), linkLabelsDS{find(abs(DS_error)==max(abs(DS_error)),1)});
fprintf('  Mean absolute error: %.4f\n', mean(abs(DS_error)));
fprintf('  RMS error          : %.4f\n', sqrt(mean(DS_error.^2)));
fprintf('%s\n\n', repmat('=',1,75));

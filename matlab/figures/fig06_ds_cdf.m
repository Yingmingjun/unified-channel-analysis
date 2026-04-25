function fig06_ds_cdf()
% fig06_ds_cdf  Omni RMS Delay Spread CDFs, paper-canonical style.
%
%   Produces TWO figures matching main_final.tex L1169/1174
%   (OmniDS_merged, OmniDS_merged7) exactly:
%       fig06_OmniDS_merged    : sub-THz  (LOS | NLOS)
%       fig06_OmniDS_merged7   : 6.75 GHz (LOS | NLOS)
%
%   Visual style mirrors paper_figures/DS_CDF_Merged.m:
%     * Violet (NYU) / Red (USC) ECDF lines with 95 %% DKW uniform bands
%     * Blue pooled scatter on top (circles for LOS, diamonds for NLOS)
%     * Dashed blue boundary lines for the pooled DKW band
%     * Lognormal mu/sigma annotation on log10(DS) for pooled data
%     * 1x2 LOS | NLOS subplots at 1400 x 520 px, 19 pt axes
%
%   Reads paper-canonical Results/*.mat via load_paper_point_data() --
%   NYU rows carry their native SUM method, USC rows their native
%   perDelayMax method, per paper_figures/DS_CDF_Merged.m.

% Paper Fig 6.

plot_style();
P = paths();
if ~exist(P.out_dir, 'dir'), mkdir(P.out_dir); end
rng(P.RNG_SEED);

T = load_paper_point_data();

% ---- Colors (match paper figure: DS_CDF_Merged.m L49-51) -----------------
colorNYU    = [0.49 0.13 0.55];   % violet
colorUSC    = [0.85 0.00 0.10];   % red
colorPooled = [0.10 0.15 0.90];   % blue

% --- Sub-THz DS ---
render_ds_fig(T, P, 'subTHz', 'sub-THz', ...
    colorNYU, colorUSC, colorPooled, 'fig06_OmniDS_merged');

% --- 6.75 GHz DS ---
render_ds_fig(T, P, 'FR1C', '6.75 GHz', ...
    colorNYU, colorUSC, colorPooled, 'fig06_OmniDS_merged7');
end


% ===========================================================================
function render_ds_fig(T, P, band, freqLabel, ...
    colorNYU, colorUSC, colorPooled, stem)

sub = T(T.band == string(band), :);

fig = figure('Position', [140, 140, 1500, 620], 'Color', 'w');

% ===== LOS subplot =====
% Manual subplot positions [left, bottom, width, height] in normalized
% figure coords. Layout: 5.5% left margin, 40% subplot width, ~12% gap
% (enough for the NLOS panel's 'Probability' Y-label + tick labels to
% sit clear of the LOS panel's right spine), 40% subplot width again,
% 2.5% right margin.
subplot('Position', [0.055, 0.17, 0.40, 0.78]); hold on; grid on; box on;
style_cdf_axes();

nyu_los = clean_vals(sub.omni_ds_ns(sub.institution == "NYU" & sub.loc_type == "LOS"));
usc_los = clean_vals(sub.omni_ds_ns(sub.institution == "USC" & sub.loc_type == "LOS"));

[hP_los, hN_los, hNb_los, hU_los, hUb_los, hPb_los, mu_los, sd_los] = ...
    plot_cdf_panel(nyu_los, usc_los, true, colorPooled, colorNYU, colorUSC);

title(sprintf('LOS Omni RMS DS %s', freqLabel), 'Interpreter', 'none');
xlabel('Omni RMS DS [ns]', 'Interpreter', 'tex');
ylabel('Probability',      'Interpreter', 'none');
leg_los = build_legend(hP_los, hN_los, hNb_los, hU_los, hUb_los, hPb_los);
add_logstat_text(mu_los, sd_los, 'DS', freqLabel, leg_los);

% ===== NLOS subplot =====
subplot('Position', [0.575, 0.17, 0.40, 0.78]); hold on; grid on; box on;
style_cdf_axes();

nyu_nlos = clean_vals(sub.omni_ds_ns(sub.institution == "NYU" & sub.loc_type == "NLOS"));
usc_nlos = clean_vals(sub.omni_ds_ns(sub.institution == "USC" & sub.loc_type == "NLOS"));

[hP_nlos, hN_nlos, hNb_nlos, hU_nlos, hUb_nlos, hPb_nlos, mu_nlos, sd_nlos] = ...
    plot_cdf_panel(nyu_nlos, usc_nlos, false, colorPooled, colorNYU, colorUSC);

title(sprintf('NLOS Omni RMS DS %s', freqLabel), 'Interpreter', 'none');
xlabel('Omni RMS DS [ns]', 'Interpreter', 'tex');
ylabel('Probability',      'Interpreter', 'none');
leg_nlos = build_legend(hP_nlos, hN_nlos, hNb_nlos, hU_nlos, hUb_nlos, hPb_nlos);
add_logstat_text(mu_nlos, sd_nlos, 'DS', freqLabel, leg_nlos);

save_figure(fig, P.out_dir, stem);
close(fig);
end


% ===========================================================================
%  HELPERS (mirror paper_figures/DS_CDF_Merged.m exactly)
% ===========================================================================
function [hPooled, hNYU, hNYUband, hUSC, hUSCband, hPooledBand, pooledMu, pooledSd] = ...
    plot_cdf_panel(nyuVals, uscVals, isLOS, cPooled, cNYU, cUSC)

pooledVals = [nyuVals; uscVals];
pooledVals = pooledVals(isfinite(pooledVals) & pooledVals > 0);

[xN, fN, fNlo, fNhi] = ecdf_with_dkw(nyuVals);
[xU, fU, fUlo, fUhi] = ecdf_with_dkw(uscVals);
[xP, fP, fPlo, fPhi] = ecdf_with_dkw(pooledVals);

% Bands first (behind everything).
hNYUband    = plot_band(xN, fNlo, fNhi, cNYU, 0.12);
hUSCband    = plot_band(xU, fUlo, fUhi, cUSC, 0.12);
hPooledBand = plot_band(xP, fPlo, fPhi, cPooled, 0.10);

% Dashed blue boundary lines for pooled DKW band (paper style).
if ~isempty(xP)
    hPooledBand = plot(xP, fPlo, '--', 'Color', cPooled, 'LineWidth', 1.5);
    plot(xP, fPhi, '--', 'Color', cPooled, 'LineWidth', 1.5);
end

% CDF lines on top.
hNYU = plot(xN, fN, 'Color', cNYU, 'LineWidth', 2.2);
hUSC = plot(xU, fU, 'Color', cUSC, 'LineWidth', 2.2);

% Pooled scatter on top — circles for LOS, diamonds for NLOS.
if isLOS, mk = 'o'; else, mk = 'd'; end
hPooled = scatter(xP, fP, 125, mk, 'MarkerEdgeColor', cPooled, ...
    'LineWidth', 2.0, 'MarkerFaceColor', 'none');

if ~isempty(pooledVals)
    % Tight x-axis: let the CDF reach the right edge.
    xlim([0, ceil(max(pooledVals))]);
end
ylim([0, 1]);

% Log10-domain pooled stats for the mu/sigma annotation.
pooledMu = NaN;
pooledSd = NaN;
if ~isempty(pooledVals)
    lv = log10(pooledVals);
    pooledMu = mean(lv);
    pooledSd = std(lv);
end
end


function style_cdf_axes()
ax = gca;
ax.FontSize = 28;
ax.GridAlpha = 0.2;
ax.LineWidth = 0.8;
end


function vals = clean_vals(vals)
vals = vals(:);
vals = vals(isfinite(vals) & vals > 0);
end


function h = plot_band(x, flo, fhi, color, alphaVal)
if isempty(x)
    h = patch(NaN, NaN, color, 'FaceAlpha', alphaVal, 'EdgeColor', 'none');
    return;
end
h = fill([x; flipud(x)], [flo; flipud(fhi)], color, ...
    'FaceAlpha', alphaVal, 'EdgeColor', 'none');
end


function [x, f, flo, fhi] = ecdf_with_dkw(vals)
vals = vals(isfinite(vals) & vals > 0);
if isempty(vals)
    x = []; f = []; flo = []; fhi = [];
    return;
end
[f, x] = ecdf(vals);
n = numel(vals);
eps_d = sqrt(log(2/0.05) / (2*n));
flo = max(0, f - eps_d);
fhi = min(1, f + eps_d);
end


function leg = build_legend(hPooled, hNYU, hNYUband, hUSC, hUSCband, hPooledBand)
% Build the southeast legend and return its handle so the caller
% can stack the mu/sigma annotation box immediately above it.
handles = [];
labels = {};
if ~isempty(hPooled) && isvalid(hPooled)
    handles(end+1) = hPooled;   labels{end+1} = 'USC+NYU';
end
if ~isempty(hNYU) && isvalid(hNYU)
    handles(end+1) = hNYU;      labels{end+1} = 'NYU';
end
if ~isempty(hNYUband) && isvalid(hNYUband)
    handles(end+1) = hNYUband;  labels{end+1} = 'NYU 95% band';
end
if ~isempty(hUSC) && isvalid(hUSC)
    handles(end+1) = hUSC;      labels{end+1} = 'USC';
end
if ~isempty(hUSCband) && isvalid(hUSCband)
    handles(end+1) = hUSCband;  labels{end+1} = 'USC 95% band';
end
if ~isempty(hPooledBand) && isvalid(hPooledBand)
    handles(end+1) = hPooledBand; labels{end+1} = 'USC+NYU 95% band';
end
if ~isempty(handles)
    leg = legend(handles, labels, 'Location', 'southeast', 'FontSize', 24);
else
    leg = [];
end
end


function add_logstat_text(mu, sigma, metricName, freqLabel, leg)
% Put the lognormal mu/sigma into its OWN small box, anchored so its
% bottom edge sits right above the top edge of the legend box (same
% right edge, same width, no overlap with the legend). Two text
% lines kept tightly inside the box.
%
% leg : the legend handle returned by build_legend (may be empty).
if ~isfinite(mu) || ~isfinite(sigma), return, end
freqSub = strrep(freqLabel, '6.75 GHz', '6.75');
txt = sprintf( ...
    '\\mu(lg(%s^{USC+NYU}_{%s})) = %.2f\n\\sigma(lg(%s^{USC+NYU}_{%s})) = %.2f', ...
    metricName, freqSub, mu, metricName, freqSub, sigma);

% Compute the anchor: right edge and top edge of the legend box in
% axes-normalized coords, then place the text() bottom-right exactly
% there (a 1.5 %% padding lifts the text clear of the legend border).
drawnow;
ax = gca;
% Anchor: legend's top-right in axes-normalized coords, then nudge
% 2 %% left so the text sits comfortably INSIDE the axes box
% (not flush with the right spine).
if ~isempty(leg) && isvalid(leg)
    ax_pos  = ax.Position;           % figure-normalized
    leg_pos = leg.Position;           % figure-normalized
    x_right = (leg_pos(1) + leg_pos(3) - ax_pos(1)) / ax_pos(3);
    y_top   = (leg_pos(2) + leg_pos(4) - ax_pos(2)) / ax_pos(4);
    x_anchor = x_right - 0.02;
    y_anchor = y_top + 0.015;
else
    x_anchor = 0.96;
    y_anchor = 0.32;
end

text(x_anchor, y_anchor, txt, 'Units', 'normalized', ...
     'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', ...
     'Color', 'k', 'FontSize', 24, 'FontWeight', 'bold', ...
     'Interpreter', 'tex');
end

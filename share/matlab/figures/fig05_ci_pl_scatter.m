function fig05_ci_pl_scatter()
% fig05_ci_pl_scatter  CI path-loss scatter + fits, paper-canonical style.
%
%   Produces TWO figures matching main_final.tex L1030/1035
%   (PLcombinedPlot, PLcombinedPlot7) exactly:
%       fig05_PLcombinedPlot    : sub-THz (pooled NYU 142 + USC 145.5 GHz)
%       fig05_PLcombinedPlot7   : FR1(C) 6.75 GHz
%
%   Visual style mirrors paper_figures/PL_CI_Merged.m:
%     * Scatter per (institution, loc_type) with distinct symbols:
%         NYU LOS  : magenta open circle  'o'
%         USC LOS  : magenta asterisk     '*'
%         NYU NLOS : blue    open diamond 'd'
%         USC NLOS : blue    open square  's'
%     * Six CI fit lines (pooled / NYU-only / USC-only) x (LOS / NLOS):
%         pooled : thick solid (magenta LOS, blue NLOS)
%         NYU    : dotted      (dark magenta)
%         USC    : dash-dot    (orange)
%     * Shaded 95 %% bootstrap CI bands around the pooled LOS/NLOS fits
%     * Gray dashed reference PLE lines n = 1..4 anchored at FSPL(1 m)
%     * Black dashed "max measurable PL" horizontal yline per institution
%     * Legend with n and sigma per fit (LaTeX superscripts/subscripts).
%
%   Reads the supplementary N1/N3/U3 UMi xlsx via load_point_data()
%   (matches paper_figures/PL_CI_Merged.m). CI model:
%   PL(d) = FSPL(1 m) + 10 n log10(d) + X_sigma, d0 = 1 m.
%
%   Reference PLE lines drawn for n = 1, 2, 3 only; n = 4 is intentionally
%   omitted (its label falls above the axes ylim for both bands, per
%   today's fix in PL_CI_Merged.m).

% Paper Fig 5; model Eq. 13.

plot_style();
P = paths();
if ~exist(P.out_dir, 'dir'), mkdir(P.out_dir); end
rng(P.RNG_SEED);

T = load_point_data();

% ---- Colors (match paper figure) ----
cLOS      = [1.00 0.00 0.90];   % magenta
cNLOS     = [0.00 0.00 0.80];   % blue
cLOSband  = [1.00 0.65 0.85];   % light pink fill
cNLOSband = [0.60 0.70 0.95];   % light blue fill
cRef      = [0.60 0.60 0.60];   % gray (n = 1..4 reference lines)

% Sub-THz: 143.75 GHz is the mid-frequency between NYU (142) and USC (145.5),
% used as the FSPL intercept for the pooled fit.  Max measurable PL is
% institution-specific: NYU 150 dB, USC 140 dB in the 140 GHz band.
render_pl_fig(T, P, 'subTHz', 143.75, [1 200], [70 155], ...
    'Outdoor UMi Omni-Directional CI PL for V-V polarization in the 140 GHz band', ...
    struct('NYU', 150.0, 'USC', 140.0), ...
    cLOS, cNLOS, cLOSband, cNLOSband, cRef, ...
    'fig05_PLcombinedPlot');

% FR1(C) 6.75 GHz. Max measurable PL: NYU 142.7 dB, USC 140 dB.
render_pl_fig(T, P, 'FR1C', 6.75, [1 1000], [50 160], ...
    'Outdoor UMi Omni-Directional CI PL for V-V polarization at 6.75 GHz', ...
    struct('NYU', 142.7, 'USC', 140.0), ...
    cLOS, cNLOS, cLOSband, cNLOSband, cRef, ...
    'fig05_PLcombinedPlot7');
end


% ===========================================================================
function render_pl_fig(T, P, band, pooledFreqGHz, xlimM, ylimDB, titleStr, ...
    maxPL, cLOS, cNLOS, cLOSband, cNLOSband, cRef, stem)

sub = T(T.band == string(band), :);
sub = sub(isfinite(sub.d_m) & isfinite(sub.pl_db) & sub.d_m > 0, :);

fig = figure('Position', [120, 120, 1280, 720], 'Color', 'w');
hold on; grid on; box on;
set(gca, 'XScale', 'log', 'FontSize', 26, 'LineWidth', 0.8);
xlim(xlimM); ylim(ylimDB);
xlabel('T-R separation (m)', 'FontSize', 28);
ylabel('Path Loss (dB)',     'FontSize', 28);
title(titleStr, 'FontSize', 22, 'FontWeight', 'bold');

d0 = 1.0;

% -- 1) Reference PLE lines n = 1..4 (gray dashed, no legend entry) -----
plot_reference_ple_lines(pooledFreqGHz, d0, xlimM, cRef);

% -- 2) Max measurable PL horizontal yline per institution ---------------
% NYU label sits above its line; USC label below, so the two labels do not
% overlap even when the two values are only a few dB apart (e.g. 6.75 GHz
% NYU 142.7 vs USC 140).
yline(maxPL.NYU, '--', sprintf('NYU Max Measurable Path Loss = %g dB', maxPL.NYU), ...
      'Color', 'k', 'LineWidth', 1.2, 'FontSize', 16, ...
      'LabelHorizontalAlignment', 'right', ...
      'LabelVerticalAlignment', 'top', 'HandleVisibility', 'off');
yline(maxPL.USC, '--', sprintf('USC Max Measurable Path Loss = %g dB', maxPL.USC), ...
      'Color', 'k', 'LineWidth', 1.2, 'FontSize', 16, ...
      'LabelHorizontalAlignment', 'right', ...
      'LabelVerticalAlignment', 'bottom', 'HandleVisibility', 'off');

% -- 3) Shaded 95 % bootstrap CI bands around the pooled fits -----------
los  = sub(sub.loc_type == "LOS",  :);
nlos = sub(sub.loc_type == "NLOS", :);

[n_losP, sig_losP,   y_lo_los,  y_hi_los,  dgrid] = fit_and_bootstrap( ...
    los.d_m,  los.pl_db,  pooledFreqGHz, d0, xlimM);
[n_nlosP, sig_nlosP, y_lo_nlos, y_hi_nlos, ~] = fit_and_bootstrap( ...
    nlos.d_m, nlos.pl_db, pooledFreqGHz, d0, xlimM);

if ~isnan(n_losP)
    h_los_band  = fill([dgrid; flipud(dgrid)], [y_lo_los';  flipud(y_hi_los')],  ...
        cLOSband,  'FaceAlpha', 0.35, 'EdgeColor', 'none');
else
    h_los_band = [];
end
if ~isnan(n_nlosP)
    h_nlos_band = fill([dgrid; flipud(dgrid)], [y_lo_nlos'; flipud(y_hi_nlos')], ...
        cNLOSband, 'FaceAlpha', 0.35, 'EdgeColor', 'none');
else
    h_nlos_band = [];
end

% -- 4) Six fit lines: pooled / NYU / USC  x  LOS / NLOS ----------------
fspl0_pool = fspl_1m(pooledFreqGHz);
D_grid     = 10.0 * log10(dgrid / d0);

if ~isnan(n_losP)
    h_los_pool = plot(dgrid, fspl0_pool + n_losP * D_grid, '-', ...
                     'Color', cLOS, 'LineWidth', 3.0);
else
    h_los_pool = plot(nan, nan, '-', 'Color', cLOS, 'LineWidth', 3.0);
end
if ~isnan(n_nlosP)
    h_nlos_pool = plot(dgrid, fspl0_pool + n_nlosP * D_grid, '-', ...
                      'Color', cNLOS, 'LineWidth', 3.0);
else
    h_nlos_pool = plot(nan, nan, '-', 'Color', cNLOS, 'LineWidth', 3.0);
end

% NYU-only fits at its native freq.  Dotted, dark magenta.
freq_nyu = pick_inst_freq('NYU', band);
[n_losN,  sig_losN,  ~, ~, ~] = fit_and_bootstrap( ...
    los(los.institution == "NYU", :).d_m, ...
    los(los.institution == "NYU", :).pl_db, freq_nyu, d0, xlimM);
[n_nlosN, sig_nlosN, ~, ~, ~] = fit_and_bootstrap( ...
    nlos(nlos.institution == "NYU", :).d_m, ...
    nlos(nlos.institution == "NYU", :).pl_db, freq_nyu, d0, xlimM);
fspl0_nyu = fspl_1m(freq_nyu);
h_los_nyu  = plot(dgrid, fspl0_nyu + cond(n_losN,  0) * D_grid, ':',  ...
                  'Color', [0.55 0.10 0.55], 'LineWidth', 2.0);
h_nlos_nyu = plot(dgrid, fspl0_nyu + cond(n_nlosN, 0) * D_grid, ':',  ...
                  'Color', [0.55 0.10 0.55], 'LineWidth', 2.0);

% USC-only fits at its native freq.  Dash-dot, orange.
freq_usc = pick_inst_freq('USC', band);
[n_losU,  sig_losU,  ~, ~, ~] = fit_and_bootstrap( ...
    los(los.institution == "USC", :).d_m, ...
    los(los.institution == "USC", :).pl_db, freq_usc, d0, xlimM);
[n_nlosU, sig_nlosU, ~, ~, ~] = fit_and_bootstrap( ...
    nlos(nlos.institution == "USC", :).d_m, ...
    nlos(nlos.institution == "USC", :).pl_db, freq_usc, d0, xlimM);
fspl0_usc = fspl_1m(freq_usc);
h_los_usc  = plot(dgrid, fspl0_usc + cond(n_losU,  0) * D_grid, '-.', ...
                  'Color', [0.95 0.55 0.10], 'LineWidth', 2.0);
h_nlos_usc = plot(dgrid, fspl0_usc + cond(n_nlosU, 0) * D_grid, '-.', ...
                  'Color', [0.95 0.55 0.10], 'LineWidth', 2.0);

% -- 5) Scatter markers per (institution, loc_type) ---------------------
los_nyu  = los (los.institution  == "NYU", :);
los_usc  = los (los.institution  == "USC", :);
nlos_nyu = nlos(nlos.institution == "NYU", :);
nlos_usc = nlos(nlos.institution == "USC", :);

h_nyu_los  = scatter(los_nyu.d_m,  los_nyu.pl_db,  72, 'o', ...
                     'MarkerEdgeColor', cLOS,  'LineWidth', 1.4);
h_usc_los  = scatter(los_usc.d_m,  los_usc.pl_db,  80, '*', ...
                     'MarkerEdgeColor', cLOS,  'LineWidth', 1.4);
h_nyu_nlos = scatter(nlos_nyu.d_m, nlos_nyu.pl_db, 72, 'd', ...
                     'MarkerEdgeColor', cNLOS, 'LineWidth', 1.4);
h_usc_nlos = scatter(nlos_usc.d_m, nlos_usc.pl_db, 64, 's', ...
                     'MarkerEdgeColor', cNLOS, 'LineWidth', 1.4);

% -- 6) Legend (order follows the paper) -------------------------------
handles = [h_nyu_los, h_usc_los, h_nyu_nlos, h_usc_nlos, ...
           h_los_pool, h_los_nyu, h_los_usc, ...
           h_nlos_pool, h_nlos_nyu, h_nlos_usc];
labels = { ...
    'NYU LOS Path Loss', ...
    'USC LOS Path Loss', ...
    'NYU NLOS Path Loss', ...
    'USC NLOS Path Loss', ...
    sprintf('n_{LOS}^{NYU+USC}= %.2f \\sigma_{LOS}^{NYU+USC} =%.2f dB', n_losP,  sig_losP),  ...
    sprintf('n_{LOS}^{NYU}= %.2f \\sigma_{LOS}^{NYU} =%.2f dB',         cond(n_losN,nan),  cond(sig_losN,nan)), ...
    sprintf('n_{LOS}^{USC}= %.2f \\sigma_{LOS}^{USC} =%.2f dB',         cond(n_losU,nan),  cond(sig_losU,nan)), ...
    sprintf('n_{NLOS}^{NYU+USC}= %.2f \\sigma_{NLOS}^{NYU+USC} =%.2f dB', n_nlosP, sig_nlosP), ...
    sprintf('n_{NLOS}^{NYU}= %.2f \\sigma_{NLOS}^{NYU} =%.2f dB',        cond(n_nlosN,nan), cond(sig_nlosN,nan)), ...
    sprintf('n_{NLOS}^{USC}= %.2f \\sigma_{NLOS}^{USC} =%.2f dB',        cond(n_nlosU,nan), cond(sig_nlosU,nan)), ...
};
if ~isempty(h_los_band)  && isvalid(h_los_band)
    handles(end+1) = h_los_band;  labels{end+1} = 'LOS 95% band';
end
if ~isempty(h_nlos_band) && isvalid(h_nlos_band)
    handles(end+1) = h_nlos_band; labels{end+1} = 'NLOS 95% band';
end
legend(handles, labels, 'Location', 'northwest', 'FontSize', 20, ...
       'Interpreter', 'tex', 'Box', 'on');

% -- 7) Console summary -------------------------------------------------
fprintf('\n%s\n', titleStr);
fprintf('  LOS  pooled NYU+USC: n=%.3f sigma=%.3f dB (n_NYU=%.3f, n_USC=%.3f)\n', ...
        n_losP, sig_losP, cond(n_losN, NaN), cond(n_losU, NaN));
fprintf('  NLOS pooled NYU+USC: n=%.3f sigma=%.3f dB (n_NYU=%.3f, n_USC=%.3f)\n', ...
        n_nlosP, sig_nlosP, cond(n_nlosN, NaN), cond(n_nlosU, NaN));

save_figure(fig, P.out_dir, stem);
close(fig);
end


% ===========================================================================
%  HELPERS
% ===========================================================================
function [n_hat, sigma_sf, y_lo, y_hi, dgrid] = fit_and_bootstrap(d, pl, freqGHz, d0, xlimM)
d  = double(d(:));
pl = double(pl(:));
mask = isfinite(d) & isfinite(pl) & d > 0;
d  = d(mask);
pl = pl(mask);

dgrid = logspace(log10(xlimM(1)), log10(xlimM(2)), 200)';

if numel(d) < 2
    n_hat = NaN; sigma_sf = NaN;
    y_lo = nan(size(dgrid)); y_hi = nan(size(dgrid));
    return;
end

fspl0 = fspl_1m(freqGHz);
D = 10.0 * log10(d / d0);
A = pl - fspl0;
n_hat = (A' * D) / (D' * D);
yhat = fspl0 + n_hat * D;
sigma_sf = sqrt(mean((pl - yhat).^2));

n_boot = 1000;
N      = numel(d);
Dg     = 10.0 * log10(dgrid / d0);
y_boot = zeros(n_boot, numel(dgrid));
for b = 1:n_boot
    idx = randi(N, N, 1);
    Db  = D(idx);
    Ab  = A(idx);
    nb  = (Ab' * Db) / (Db' * Db);
    y_boot(b,:) = fspl0 + nb * Dg;
end
y_lo = prctile(y_boot, 2.5,  1);
y_hi = prctile(y_boot, 97.5, 1);
end

function fspl = fspl_1m(freqGHz)
c_ms     = 299792458.0;
lambda_m = c_ms / (freqGHz * 1e9);
fspl     = 20.0 * log10(4.0 * pi / lambda_m);
end

function f = pick_inst_freq(inst, band)
if strcmp(band, 'subTHz')
    if strcmp(inst, 'NYU'), f = 142.0; else, f = 145.5; end
else
    f = 6.75;
end
end

function y = cond(x, fallback)
if isempty(x) || ~isfinite(x), y = fallback; else, y = x; end
end

function plot_reference_ple_lines(freqGHz, d0, xlimM, color)
% Draw analytic PL(d) curves for PLE n = 1, 2, 3 anchored at FSPL(d0).
% n = 4 is omitted (its label lands above the axes ylim for both bands,
% matching today's fix in paper_figures/PL_CI_Merged.m).
fspl0 = fspl_1m(freqGHz);
d = logspace(log10(xlimM(1)), log10(xlimM(2)), 200)';
D = 10.0 * log10(d / d0);
for n_ref = 1:3
    y = fspl0 + n_ref * D;
    plot(d, y, '--', 'Color', color, 'LineWidth', 1.0, ...
         'HandleVisibility', 'off');
    text(xlimM(2)*0.95, y(end), sprintf('n=%d', n_ref), ...
         'Color', color, 'FontSize', 16, ...
         'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom');
end
end

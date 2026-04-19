function fig06_ds_cdf()
% fig06_ds_cdf  Omni RMS Delay Spread CDFs (Fig 6).
%
%   Produces TWO figures:
%       fig06_OmniDS_merged    : sub-THz
%       fig06_OmniDS_merged7   : 6.75 GHz
%
%   Each figure has subplot(1,2,1) LOS + subplot(1,2,2) NLOS. Each subplot
%   shows three ECDF curves (NYU, USC, Pooled) with DKW 95 % uniform
%   confidence bands shaded at alpha 0.12.

% Mirrors python/src/channel_analysis/figures/fig06_ds_cdf.py
% Paper Fig 6; CDF helper pattern from AS_CDF_Merged.m.

plot_style();
P = paths();
if ~exist(P.out_dir, 'dir'), mkdir(P.out_dir); end

T = load_point_data();

render_band(T, P, 'subTHz', 'Sub-THz (142 / 145.5 GHz)', ...
            'fig06_OmniDS_merged', 'omni_ds_ns', 'omni_ds_ns', ...
            'Omni RMS DS', 'ns');
render_band(T, P, 'FR1C',   'FR1(C) 6.75 GHz', ...
            'fig06_OmniDS_merged7', 'omni_ds_ns', 'omni_ds_ns', ...
            'Omni RMS DS', 'ns');
end


% ===========================================================================
function render_band(T, P, band, band_label, stem, nyu_col, usc_col, ...
                     metric_label, unit)
sub = T(T.band == string(band), :);
fig = figure('Position', [100 100 1300 500], 'Color', 'w');

% Subplot 1: LOS
subplot(1, 2, 1);
draw_panel(sub(sub.loc_type == "LOS", :), nyu_col, usc_col, ...
           sprintf('%s CDF (LOS) - %s', metric_label, band_label), ...
           sprintf('%s (%s)', metric_label, unit));

% Subplot 2: NLOS
subplot(1, 2, 2);
draw_panel(sub(sub.loc_type == "NLOS", :), nyu_col, usc_col, ...
           sprintf('%s CDF (NLOS) - %s', metric_label, band_label), ...
           sprintf('%s (%s)', metric_label, unit));

save_figure(fig, P.out_dir, stem);
close(fig);
end


function draw_panel(band_df, nyu_col, usc_col, ttl, xlab)
% Draw one (LOS or NLOS) panel: NYU / USC / Pooled ECDF + DKW 95 % bands.
% Mirrors python fig06_ds_cdf._panel.

nyu_vals    = band_df.(nyu_col)(band_df.institution == "NYU");
usc_vals    = band_df.(usc_col)(band_df.institution == "USC");
pooled_vals = [nyu_vals; usc_vals];

c_nyu    = [0.00 0.45 0.74];
c_usc    = [0.85 0.33 0.10];
c_pooled = [0.20 0.20 0.20];

hold on; grid on; box on;
curves = { 'NYU',    nyu_vals,    c_nyu,    '-'; ...
           'USC',    usc_vals,    c_usc,    '--'; ...
           'Pooled', pooled_vals, c_pooled, '-' };
for k = 1:size(curves, 1)
    label  = curves{k, 1};
    vals   = curves{k, 2};
    color  = curves{k, 3};
    ls     = curves{k, 4};
    draw_ecdf_with_dkw(vals, color, ls, label);
end
xlabel(xlab);
ylabel('CDF');
ylim([0 1]);
title(ttl);
legend('Location', 'southeast', 'FontSize', 9);
end


function draw_ecdf_with_dkw(x, color, ls, label)
% Draw staircase ECDF + shaded DKW band (alpha 0.12).
% Mirrors python fig06_ds_cdf._ecdf_with_dkw.
x = double(x(:));
x = x(isfinite(x) & x > 0);
n = numel(x);
if n == 0, return, end
xs  = sort(x);
fs  = (1:n)' / n;
eps_d = dkw_band(n, 0.05);
fs_lo = max(fs - eps_d, 0);
fs_hi = min(fs + eps_d, 1);

% Shaded DKW band (plot BEFORE the step line so it sits underneath).
xx = [xs; flipud(xs)];
yy = [fs_lo; flipud(fs_hi)];
fill(xx, yy, color, 'FaceAlpha', 0.12, 'EdgeColor', 'none', ...
     'HandleVisibility', 'off');
stairs(xs, fs, 'Color', color, 'LineStyle', ls, 'LineWidth', 2.0, ...
       'DisplayName', sprintf('%s (n=%d)', label, n));
end

function fig08_asd_cdf()
% fig08_asd_cdf  Omni ASD CDFs (Fig 8).
%
%   Produces TWO figures:
%       fig08_OmniASD_merged    : sub-THz
%       fig08_OmniASD_merged7   : 6.75 GHz
%
%   Same 2-subplot (LOS | NLOS) x 3-curve (NYU / USC / Pooled) layout as
%   fig07 but plotted on asd_nyu_10 and asd_usc.

% Mirrors python/src/channel_analysis/figures/fig08_asd_cdf.py
% Paper Fig 8.

plot_style();
P = paths();
if ~exist(P.out_dir, 'dir'), mkdir(P.out_dir); end

T = load_point_data();

render_band(T, P, 'subTHz', 'Sub-THz (142 / 145.5 GHz)', ...
            'fig08_OmniASD_merged', 'asd_nyu_10', 'asd_usc', ...
            'Omni RMS ASD', 'deg');
render_band(T, P, 'FR1C',   'FR1(C) 6.75 GHz', ...
            'fig08_OmniASD_merged7', 'asd_nyu_10', 'asd_usc', ...
            'Omni RMS ASD', 'deg');
end


% ===========================================================================
function render_band(T, P, band, band_label, stem, nyu_col, usc_col, ...
                     metric_label, unit)
sub = T(T.band == string(band), :);
fig = figure('Position', [100 100 1300 500], 'Color', 'w');

subplot(1, 2, 1);
draw_panel(sub(sub.loc_type == "LOS", :), nyu_col, usc_col, ...
           sprintf('%s CDF (LOS) - %s', metric_label, band_label), ...
           sprintf('%s (%s)', metric_label, unit));

subplot(1, 2, 2);
draw_panel(sub(sub.loc_type == "NLOS", :), nyu_col, usc_col, ...
           sprintf('%s CDF (NLOS) - %s', metric_label, band_label), ...
           sprintf('%s (%s)', metric_label, unit));

save_figure(fig, P.out_dir, stem);
close(fig);
end


function draw_panel(band_df, nyu_col, usc_col, ttl, xlab)
% Mirrors python fig08_asd_cdf._panel.
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
    draw_ecdf_with_dkw(curves{k, 2}, curves{k, 3}, curves{k, 4}, curves{k, 1});
end
xlabel(xlab);
ylabel('CDF');
ylim([0 1]);
title(ttl);
legend('Location', 'southeast', 'FontSize', 9);
end


function draw_ecdf_with_dkw(x, color, ls, label)
x = double(x(:));
x = x(isfinite(x) & x > 0);
n = numel(x);
if n == 0, return, end
xs  = sort(x);
fs  = (1:n)' / n;
eps_d = dkw_band(n, 0.05);
fs_lo = max(fs - eps_d, 0);
fs_hi = min(fs + eps_d, 1);

xx = [xs; flipud(xs)];
yy = [fs_lo; flipud(fs_hi)];
fill(xx, yy, color, 'FaceAlpha', 0.12, 'EdgeColor', 'none', ...
     'HandleVisibility', 'off');
stairs(xs, fs, 'Color', color, 'LineStyle', ls, 'LineWidth', 2.0, ...
       'DisplayName', sprintf('%s (n=%d)', label, n));
end

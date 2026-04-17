function fig06_ds_cdf()
% fig06_ds_cdf  Empirical CDFs of omni RMS delay spread with DKW bands.
%
%   One subplot per band, overlaying LOS vs NLOS CDFs for NYU (N1) and USC
%   (U1) variants. DKW 95% uniform confidence bands are shaded around each
%   empirical CDF (see dkw_band.m).
%
%   Output files:
%       figures/matlab/fig06_ds_cdf.png
%       figures/matlab/fig06_ds_cdf.pdf

% Mirrors python/src/channel_analysis/figures/fig06_ds_cdf.py
% Paper Section V.B, Fig. 6

plot_style();
P = paths();

T = load_point_data({'N1', 'U1'});

fig = figure('Position', [100 100 1100 500]);
bands = ["subTHz", "FR1C"];
locs  = ["LOS", "NLOS"];
colors = struct('NYU', [0 0.45 0.74], 'USC', [0.85 0.33 0.10]);
ls_loc = struct('LOS', '-', 'NLOS', '--');

for ib = 1:numel(bands)
    subplot(1, numel(bands), ib);
    hold on;
    band = bands(ib);
    for inst = ["NYU", "USC"]
        for il = 1:numel(locs)
            loc = locs(il);
            mask = T.band == band & T.institution == inst & T.loc_type == loc;
            x    = T.omni_ds_ns(mask);
            draw_ecdf_with_dkw(x, colors.(char(inst)), ls_loc.(char(loc)), ...
                               sprintf('%s %s', inst, loc));
        end
    end
    set(gca, 'XScale', 'log');
    xlabel('Omni RMS DS [ns]');
    ylabel('CDF');
    title(sprintf('%s', band));
    legend('Location', 'best', 'FontSize', 8);
    grid on;
end

sgtitle('Omni RMS Delay Spread CDFs with DKW 95% bands');

save_figure(fig, P.out_dir, 'fig06_ds_cdf');
close(fig);
end


% ============================================================================
function draw_ecdf_with_dkw(x, color, ls, label)
% Draw a staircase ECDF and shade the DKW 95% uniform band around it.
x = double(x(:));
x = x(isfinite(x) & x > 0);
n = numel(x);
if n == 0, return, end
xs  = sort(x);
fs  = (1:n)' / n;
eps = dkw_band(n, 0.05);

fs_lo = max(fs - eps, 0);
fs_hi = min(fs + eps, 1);

% Shade the band first so the main line sits on top.
xx = [xs; flipud(xs)];
yy = [fs_lo; flipud(fs_hi)];
fill(xx, yy, color, 'FaceAlpha', 0.15, 'EdgeColor', 'none', ...
     'HandleVisibility', 'off');
stairs(xs, fs, 'Color', color, 'LineStyle', ls, 'LineWidth', 2.0, ...
       'DisplayName', label);
end

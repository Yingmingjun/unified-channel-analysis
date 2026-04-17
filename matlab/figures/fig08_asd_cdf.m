function fig08_asd_cdf()
% fig08_asd_cdf  ECDFs of omni ASD (azimuth-of-departure spread) with DKW bands.
%
%   Output files:
%       figures/matlab/fig08_asd_cdf.png
%       figures/matlab/fig08_asd_cdf.pdf

% Mirrors python/src/channel_analysis/figures/fig08_asd_cdf.py
% Paper Section V.C, Fig. 8

plot_style();
P = paths();

T = load_point_data({'N1', 'U1'});
fig = figure('Position', [100 100 1100 500]);
draw_as_cdf_grid(T, 'omni_asd_d', 'Omni ASD [deg]');
sgtitle('Omni ASD CDFs with DKW 95% bands');
save_figure(fig, P.out_dir, 'fig08_asd_cdf');
close(fig);
end


% ============================================================================
function draw_as_cdf_grid(T, col, xlab)
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
            x    = T.(col)(mask);
            draw_ecdf_with_dkw(x, colors.(char(inst)), ls_loc.(char(loc)), ...
                               sprintf('%s %s', inst, loc));
        end
    end
    xlabel(xlab);
    ylabel('CDF');
    title(sprintf('%s', band));
    legend('Location', 'best', 'FontSize', 8);
    grid on;
end
end


function draw_ecdf_with_dkw(x, color, ls, label)
x = double(x(:));
x = x(isfinite(x));
n = numel(x);
if n == 0, return, end
xs  = sort(x);
fs  = (1:n)' / n;
eps = dkw_band(n, 0.05);

fs_lo = max(fs - eps, 0);
fs_hi = min(fs + eps, 1);

xx = [xs; flipud(xs)];
yy = [fs_lo; flipud(fs_hi)];
fill(xx, yy, color, 'FaceAlpha', 0.15, 'EdgeColor', 'none', ...
     'HandleVisibility', 'off');
stairs(xs, fs, 'Color', color, 'LineStyle', ls, 'LineWidth', 2.0, ...
       'DisplayName', label);
end

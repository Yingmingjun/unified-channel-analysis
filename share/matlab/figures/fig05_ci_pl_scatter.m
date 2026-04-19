function fig05_ci_pl_scatter()
% fig05_ci_pl_scatter  CI path-loss scatter, pooled per band (Fig 5).
%
%   Produces TWO figures:
%       fig05_PLcombinedPlot    : sub-THz (53 dots)
%       fig05_PLcombinedPlot7   : 6.75 GHz (35 dots)
%
%   Each figure has ONE axis with ALL pooled TX-RX scatter: LOS as circles,
%   NLOS as squares, colored by institution (NYU blue, USC orange). Six CI
%   fit lines are overlaid (NYU/USC/Pooled x LOS/NLOS). Log-x axis over
%   [10, 500] m. CI model: PL(d) = FSPL(1 m) + 10 n log10(d) + X_sigma,
%   d0 = 1 m.

% Mirrors python/src/channel_analysis/figures/fig05_ci_pl_scatter.py
% Paper Fig 5; model Eq. 13.

plot_style();
P = paths();
if ~exist(P.out_dir, 'dir'), mkdir(P.out_dir); end

T = load_point_data();

% Pooled representative freq: NYU 142 + USC 145.5 -> use mid-frequency for
% the pooled fit's FSPL intercept (matches python config choice 143.75).
render_band(T, P, 'subTHz', 'Sub-THz (142 / 145.5 GHz)', 143.75, ...
            'fig05_PLcombinedPlot',  [10 500]);
render_band(T, P, 'FR1C',   'FR1(C) 6.75 GHz',             6.75, ...
            'fig05_PLcombinedPlot7', [10 500]);
end


% ===========================================================================
function render_band(T, P, band, band_label, pooled_freq, stem, xlim_m)
% Build one pooled-scatter + six-fit-lines figure.
% Mirrors python fig05_ci_pl_scatter._render_band.

sub = T(T.band == string(band), :);
% pl_db is the paper-canonical PL (xlsx "orig" preferred; CSV fallback).
pl = sub.pl_db;
d  = sub.d_m;

c_nyu    = [0.00 0.45 0.74];
c_usc    = [0.85 0.33 0.10];
c_pooled = [0.20 0.20 0.20];

fig = figure('Position', [100 100 1000 600], 'Color', 'w');
hold on; grid on; box on;

% -- Scatter: LOS = circles, NLOS = squares, color by institution ----------
inst_colors = {'NYU', c_nyu; 'USC', c_usc};
loc_markers = {'LOS', 'o'; 'NLOS', 's'};
for ii = 1:size(inst_colors, 1)
    inst = inst_colors{ii, 1}; col = inst_colors{ii, 2};
    for jj = 1:size(loc_markers, 1)
        loc = loc_markers{jj, 1}; mk = loc_markers{jj, 2};
        mask = (sub.institution == inst) & (sub.loc_type == loc);
        if ~any(mask), continue, end
        scatter(d(mask), pl(mask), 55, mk, ...
                'MarkerFaceColor', col, 'MarkerEdgeColor', 'k', ...
                'LineWidth', 0.5, 'MarkerFaceAlpha', 0.75, ...
                'DisplayName', sprintf('%s %s data (n=%d)', inst, loc, nnz(mask)));
    end
end

% -- Six fit lines: {NYU, USC, Pooled} x {LOS, NLOS} -----------------------
% LOS solid, NLOS dashed; color by subset.
group_defs = { ...
    'NYU',    c_nyu,    @(s) s.institution == "NYU"; ...
    'USC',    c_usc,    @(s) s.institution == "USC"; ...
    'Pooled', c_pooled, @(s) true(height(s), 1) };
loc_styles = {'LOS', '-'; 'NLOS', '--'};

for ig = 1:size(group_defs, 1)
    g_name = group_defs{ig, 1};
    g_col  = group_defs{ig, 2};
    g_mask = group_defs{ig, 3};
    for il = 1:size(loc_styles, 1)
        loc = loc_styles{il, 1}; ls = loc_styles{il, 2};
        mask = g_mask(sub) & (sub.loc_type == loc);
        gsub = sub(mask, :);
        if height(gsub) < 2, continue, end

        % Per-institution FSPL (NYU -> 142, USC -> 145.5) for subset fits;
        % for pooled at sub-THz we use the mid-frequency (pooled_freq).
        if strcmp(g_name, 'NYU')
            f = 142.0; if band == "FR1C", f = 6.75; end
        elseif strcmp(g_name, 'USC')
            f = 145.5; if band == "FR1C", f = 6.75; end
        else
            f = pooled_freq;
        end
        [ple, sigma_sf, cfi_lo, cfi_hi] = ci_pl_fit( ...
            gsub.d_m, gsub.pl_db, f, 2000, 0);
        % Fit line over xlim range.
        dg = logspace(log10(xlim_m(1)), log10(xlim_m(2)), 120);
        c_ms = 299792458.0;
        lambda_m = c_ms / (f * 1e9);
        fspl_1m = 20.0 * log10(4.0 * pi / lambda_m);
        yhat = fspl_1m + 10.0 * ple * log10(dg);
        plot(dg, yhat, 'Color', g_col, 'LineStyle', ls, 'LineWidth', 1.8, ...
             'DisplayName', sprintf('%s %s fit: n=%.2f, \\sigma=%.2f dB', ...
                                    g_name, loc, ple, sigma_sf));
    end
end

set(gca, 'XScale', 'log');
xlim(xlim_m);
xlabel('TX-RX Separation d (m)');
ylabel('Omni Path Loss (dB)');
title(sprintf('CI path-loss fit - pooled NYU + USC, %s', band_label));
legend('Location', 'northwest', 'FontSize', 8, 'NumColumns', 2);

save_figure(fig, P.out_dir, stem);
close(fig);
end

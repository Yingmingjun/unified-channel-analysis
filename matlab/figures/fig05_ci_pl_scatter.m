function fig05_ci_pl_scatter()
% fig05_ci_pl_scatter  CI path-loss scatter with fitted PLE lines.
%
%   Plots PL vs distance on log-x axes, separately for LOS/NLOS, with the
%   CI-model fits for each variant overlaid. PLE +/- 95% CFI widths are
%   annotated in the legend.
%
%   Output files:
%       figures/matlab/fig05_ci_pl_scatter.png
%       figures/matlab/fig05_ci_pl_scatter.pdf

% Mirrors python/src/channel_analysis/figures/fig05_ci_pl_scatter.py
% Paper Section V.A, Fig. 5; CI model Eq. 13

plot_style();
P = paths();

T = load_point_data({'N1', 'U1'});

fig = figure('Position', [100 100 1000 700]);

bands = ["subTHz", "FR1C"];
% subTHz uses 142 / 145.5 GHz for fit; FR1C uses 6.75 GHz.
freq_by_inst = containers.Map({'NYU_subTHz','USC_subTHz','NYU_FR1C','USC_FR1C'}, ...
                              { 142.0,        145.5,        6.75,      6.75    });
locs  = ["LOS", "NLOS"];

colors = struct('NYU', [0 0.45 0.74], 'USC', [0.85 0.33 0.10]);

for ib = 1:numel(bands)
    for il = 1:numel(locs)
        subplot(numel(bands), numel(locs), (ib - 1) * numel(locs) + il);
        hold on;
        band = bands(ib);
        loc  = locs(il);
        for inst = ["NYU", "USC"]
            mask = T.band == band & T.loc_type == loc & T.institution == inst;
            if nnz(mask) < 2, continue, end
            d  = T.d_m(mask);
            pl = T.pl_db(mask);
            fghz = freq_by_inst([char(inst) '_' char(band)]);

            [ple, sigma_sf, lo, hi] = ci_pl_fit(d, pl, fghz, 2000, 0);

            % Scatter
            scatter(d, pl, 40, colors.(char(inst)), 'filled', ...
                    'DisplayName', sprintf('%s data', inst));

            % Fit line over the observed range
            dd = logspace(log10(max(min(d), 1.0)), log10(max(d)), 50);
            c_ms     = 299792458.0;
            lambda_m = c_ms / (fghz * 1e9);
            fspl_1m  = 20.0 * log10(4.0 * pi / lambda_m);
            plhat    = fspl_1m + 10.0 * ple * log10(dd);
            plot(dd, plhat, '-', 'Color', colors.(char(inst)), ...
                 'LineWidth', 2.0, ...
                 'DisplayName', sprintf('%s fit: n=%.2f, sigma=%.2f, CFI_w=%.2f', ...
                                         inst, ple, sigma_sf, hi - lo));
        end
        set(gca, 'XScale', 'log');
        xlabel('TX-RX distance [m]');
        ylabel('PL [dB]');
        title(sprintf('%s  %s', band, loc));
        legend('Location', 'best', 'FontSize', 8);
        grid on;
    end
end

sgtitle('Close-In PL fits (Eq. 13) with 95% bootstrap CFI on PLE');

save_figure(fig, P.out_dir, 'fig05_ci_pl_scatter');
close(fig);
end

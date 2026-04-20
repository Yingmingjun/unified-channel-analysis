function save_link_omni_pdp(out_dir, band_label, link_id, env_label, ...
                             delays_ns, pdp_nyu, pdp_usc, ds_nyu, ds_usc)
% save_link_omni_pdp  Save a per-link omni PDP comparison plot to
% <out_dir>/<band>_<link>_<env>.png. Called from the raw-processing loops
% (NYU142/7, USC145/7) so every TX-RX pair gets its own plot.
%
%   out_dir     e.g. fullfile(repo_root, 'figures', 'matlab', 'omni_pdps')
%   band_label  'nyu_142', 'nyu_7', 'usc_145', 'usc_7'
%   link_id     'T1-R1' (NYU) or 'R01' (USC)
%   env_label   'LOS' / 'NLOS' / 'OLOS'
%   delays_ns   vector of delay samples (ns)
%   pdp_nyu     NYU SUM synthesized omni PDP (linear)
%   pdp_usc     USC perDelayMax synthesized omni PDP (linear)
%   ds_nyu      pre-computed NYU RMS DS (ns), passed in to avoid redoing
%   ds_usc      pre-computed USC RMS DS (ns)

if nargin < 1 || isempty(out_dir)
    P = paths();
    out_dir = fullfile(P.out_dir, 'omni_pdps');
end
if ~exist(out_dir, 'dir'), mkdir(out_dir); end

% File-safe stem
safe_link = regexprep(char(link_id), '[^a-zA-Z0-9]', '_');
stem = sprintf('%s_%s_%s', band_label, safe_link, char(env_label));

% IntegerHandle='off' + HandleVisibility='off' isolate this figure from
% the main processing script's fig1..fig8 numbering so our close(fig) here
% cannot invalidate a figure the main script still uses later.
fig = figure('Position', [100 100 1000 500], 'Color', 'w', ...
             'Visible', 'off', ...
             'HandleVisibility', 'off', ...
             'IntegerHandle', 'off');
hold on; grid on; box on;

delays_ns = delays_ns(:);
pdp_nyu_lin = pdp_nyu(:);
pdp_usc_lin = pdp_usc(:);

% Normalize to peak of both methods (whichever peak is higher), in dB.
peak_ref = max(max(pdp_nyu_lin), max(pdp_usc_lin));
if ~isfinite(peak_ref) || peak_ref <= 0
    close(fig);
    return;
end

mask_n = pdp_nyu_lin > 0;
mask_u = pdp_usc_lin > 0;

plot(delays_ns(mask_n), 10*log10(pdp_nyu_lin(mask_n) / peak_ref), ...
     'Color', [0.00 0.45 0.74], 'LineWidth', 1.6, 'DisplayName', 'NYU SUM');
plot(delays_ns(mask_u), 10*log10(pdp_usc_lin(mask_u) / peak_ref), ...
     'Color', [0.85 0.33 0.10], 'LineWidth', 1.6, 'DisplayName', 'USC perDelayMax');

ylim([-40 5]);
% Zoom x-range to the support of non-zero samples with a 10 ns pad
allmask = mask_n | mask_u;
if any(allmask)
    xlim([max(0, min(delays_ns(allmask)) - 10), max(delays_ns(allmask)) + 10]);
end

xlabel('Delay \tau (ns)', 'FontSize', 14);
ylabel('Normalized Power (dB)', 'FontSize', 14);
title(sprintf('%s  %s  %s   (RMS DS: NYU=%.1f ns, USC=%.1f ns)', ...
              upper(strrep(band_label,'_','-')), link_id, env_label, ...
              ds_nyu, ds_usc), ...
      'FontSize', 13, 'FontWeight', 'bold', 'Interpreter', 'none');
legend('Location', 'northeast', 'FontSize', 12);
set(gca, 'FontSize', 13);

try
    exportgraphics(fig, fullfile(out_dir, [stem '.png']), ...
        'Resolution', 200, 'BackgroundColor', 'white');
catch
end
close(fig);
end

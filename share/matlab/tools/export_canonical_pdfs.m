function export_canonical_pdfs()
% Open each canonical-name .fig and export as .pdf (vector).
% BA_PL/DS lack canonical .fig so we fall back to fig03_*.fig.
%
% Output PDFs are placed alongside the .fig, at figures/matlab/.
P = paths();
outdir = P.out_dir;

% {source_fig_basename, output_pdf_basename}
map = {
    'fig03_BA_PL',         'BA_PL';
    'fig03_BA_PL7',        'BA_PL7';
    'fig03_BA_DS',         'BA_DS';
    'fig03_BA_DS7',        'BA_DS7';
    'BA_ASA',              'BA_ASA';
    'BA_ASA7',             'BA_ASA7';
    'BA_ASD',              'BA_ASD';
    'BA_ASD7',             'BA_ASD7';
    'PLcombinedPlot',      'PLcombinedPlot';
    'PLcombinedPlot7',     'PLcombinedPlot7';
    'OmniDS_merged',       'OmniDS_merged';
    'OmniDS_merged7',      'OmniDS_merged7';
    'OmniASA_merged',      'OmniASA_merged';
    'OmniASA_merged7',     'OmniASA_merged7';
    'OmniASD_merged',      'OmniASD_merged';
    'OmniASD_merged7',     'OmniASD_merged7';
};

for i = 1:size(map, 1)
    src = map{i, 1};
    dst = map{i, 2};
    fig_path = fullfile(outdir, [src '.fig']);
    pdf_path = fullfile(outdir, [dst '.pdf']);

    if ~isfile(fig_path)
        fprintf('  [MISS] %s.fig not found, skipping\n', src);
        continue
    end

    try
        f = openfig(fig_path, 'invisible');
        exportgraphics(f, pdf_path, 'ContentType', 'vector', 'BackgroundColor', 'white');
        close(f);
        info = dir(pdf_path);
        fprintf('  [OK]   %s.fig -> %s.pdf (%d bytes)\n', src, dst, info.bytes);
    catch ME
        fprintf(2, '  [ERR]  %s: %s\n', src, ME.message);
    end
end
end

function status = sync_paper_figs(dest_dir)
% sync_paper_figs  Copy the 16 \includegraphics-targeted figures from the
% pipeline output directory to the paper source tree, renaming figXX_-
% prefixed outputs to their canonical paper filenames and converting
% extensions where the paper's \includegraphics calls expect .jpg.
%
%   status = sync_paper_figs()            uses paths().paper_src_fig_dir
%                                          (set via PAPER_FIG_DIR env var).
%   status = sync_paper_figs(dest_dir)    writes into an explicit folder.
%
%   If the destination is empty or not a directory, the function is a no-op
%   and returns a status struct with all 16 entries marked "skipped".
%
%   Mapping (source in paths().out_dir -> destination filename in dest_dir):
%
%       fig03_BA_PL.png            -> BA_PL.png
%       fig03_BA_PL7.png           -> BA_PL7.png
%       fig03_BA_DS.png            -> BA_DS.png
%       fig03_BA_DS7.png           -> BA_DS7.png
%       BA_ASA.png                 -> BA_ASA.png
%       BA_ASA7.png                -> BA_ASA7.png
%       BA_ASD.png                 -> BA_ASD.png
%       BA_ASD7.png                -> BA_ASD7.png
%       fig05_PLcombinedPlot.png   -> PLcombinedPlot.jpg  (re-encoded)
%       fig05_PLcombinedPlot7.png  -> PLcombinedPlot7.jpg
%       fig06_OmniDS_merged.png    -> OmniDS_merged.jpg
%       fig06_OmniDS_merged7.png   -> OmniDS_merged7.jpg
%       OmniASA_merged.png         -> OmniASA_merged.png
%       OmniASA_merged7.png        -> OmniASA_merged7.png
%       OmniASD_merged.png         -> OmniASD_merged.png
%       OmniASD_merged7.png        -> OmniASD_merged7.png

P = paths();
if nargin < 1 || isempty(dest_dir)
    dest_dir = P.paper_src_fig_dir;
end

% Each row: {source candidates (first existing wins), destination filename}.
% Candidates are tried in order; the winner is copied (or re-encoded when
% the source and destination extensions differ).
map = {
    {'fig03_BA_PL.png'},                          'BA_PL.png';
    {'fig03_BA_PL7.png'},                         'BA_PL7.png';
    {'fig03_BA_DS.png'},                          'BA_DS.png';
    {'fig03_BA_DS7.png'},                         'BA_DS7.png';
    {'BA_ASA.png'},                               'BA_ASA.png';
    {'BA_ASA7.png'},                              'BA_ASA7.png';
    {'BA_ASD.png'},                               'BA_ASD.png';
    {'BA_ASD7.png'},                              'BA_ASD7.png';
    % Prefer PL_CI_Merged output (writes canonical name + .jpg directly);
    % fall back to fig05 unified driver if PL_CI_Merged hasn't been run.
    {'PLcombinedPlot.jpg',  'PLcombinedPlot.png',  'fig05_PLcombinedPlot.png'},  'PLcombinedPlot.jpg';
    {'PLcombinedPlot7.jpg', 'PLcombinedPlot7.png', 'fig05_PLcombinedPlot7.png'}, 'PLcombinedPlot7.jpg';
    % Prefer AS-styled DS_CDF_Merged output; fall back to fig06 unified
    % driver if DS_CDF_Merged hasn't been run yet.
    {'OmniDS_merged.png',  'OmniDS_merged.jpg',  'fig06_OmniDS_merged.png'},   'OmniDS_merged.jpg';
    {'OmniDS_merged7.png', 'OmniDS_merged7.jpg', 'fig06_OmniDS_merged7.png'},  'OmniDS_merged7.jpg';
    {'OmniASA_merged.png',  'OmniASA_merged.jpg'},  'OmniASA_merged.png';
    {'OmniASA_merged7.png', 'OmniASA_merged7.jpg'}, 'OmniASA_merged7.png';
    {'OmniASD_merged.png',  'OmniASD_merged.jpg'},  'OmniASD_merged.png';
    {'OmniASD_merged7.png', 'OmniASD_merged7.jpg'}, 'OmniASD_merged7.png';
};

status = struct('n_copied', 0, 'n_missing_src', 0, 'n_skipped', 0, ...
                'dest_dir', dest_dir, 'entries', {{}});

if isempty(dest_dir)
    fprintf('[sync_paper_figs] No destination set (paths().paper_src_fig_dir empty); skipping.\n');
    fprintf('[sync_paper_figs] To enable, set the PAPER_FIG_DIR environment variable before launching MATLAB.\n');
    status.n_skipped = size(map, 1);
    return
end

if ~isfolder(dest_dir)
    fprintf('[sync_paper_figs] Destination %s does not exist; skipping.\n', dest_dir);
    status.n_skipped = size(map, 1);
    return
end

fprintf('[sync_paper_figs] Target: %s\n', dest_dir);

for i = 1:size(map, 1)
    candidates = map{i, 1};
    dst_name   = map{i, 2};
    dst_path   = fullfile(dest_dir, dst_name);

    % Pick the first candidate that exists in P.out_dir.
    src_name = '';
    src_path = '';
    for c = 1:numel(candidates)
        cand_path = fullfile(P.out_dir, candidates{c});
        if isfile(cand_path)
            src_name = candidates{c};
            src_path = cand_path;
            break
        end
    end

    if isempty(src_path)
        fprintf('  [MISS]  %-32s (none of {%s} found in %s)\n', dst_name, ...
                strjoin(candidates, ', '), P.out_dir);
        status.n_missing_src = status.n_missing_src + 1;
        status.entries{end+1} = struct('src', '(none)', 'dst', dst_name, 'result', 'missing');
        continue
    end

    % If source and destination extensions match, a plain file copy.
    % Otherwise re-encode via imread/imwrite so the paper's
    % \includegraphics call (which may expect .jpg or .png) resolves.
    [~, ~, src_ext] = fileparts(src_path);
    [~, ~, dst_ext] = fileparts(dst_path);
    if strcmpi(src_ext, dst_ext)
        copyfile(src_path, dst_path);
        action = 'copied';
    else
        img = imread(src_path);
        switch lower(dst_ext)
            case {'.jpg', '.jpeg'}
                imwrite(img, dst_path, 'Quality', 95);
            otherwise
                imwrite(img, dst_path);
        end
        action = 'converted';
    end

    fprintf('  [ OK ]  %-32s -> %s (%s)\n', src_name, dst_name, action);
    status.n_copied = status.n_copied + 1;
    status.entries{end+1} = struct('src', src_name, 'dst', dst_name, 'result', action);

    % Also copy the sibling .fig file if available, so the paper folder has
    % an editable MATLAB figure next to every imported image. The .fig is
    % taken from whichever source filename was chosen (same stem). Wrap in
    % try/catch so a locked destination (e.g. .fig open in another MATLAB
    % session) does not abort the rest of the sync.
    [~, src_stem, ~] = fileparts(src_path);
    [~, dst_stem, ~] = fileparts(dst_path);
    fig_src = fullfile(P.out_dir, [src_stem '.fig']);
    fig_dst = fullfile(dest_dir, [dst_stem '.fig']);
    if isfile(fig_src)
        try
            copyfile(fig_src, fig_dst);
            fprintf('  [ OK ]  %-32s -> %s (fig copy)\n', ...
                    [src_stem '.fig'], [dst_stem '.fig']);
        catch ME
            fprintf('  [SKIP]  %-32s -> %s (fig locked: %s)\n', ...
                    [src_stem '.fig'], [dst_stem '.fig'], ME.message);
        end
    end
end

fprintf('[sync_paper_figs] %d copied, %d missing source, %d skipped.\n', ...
        status.n_copied, status.n_missing_src, status.n_skipped);
end

function stage_paper_figures(target_dir)
% stage_paper_figures  Copy MATLAB-generated figures to paper-expected names.
%
%   stage_paper_figures(target_dir) copies the unified pipeline's outputs
%   from figures/matlab/ to <target_dir>, renaming from the unified
%   fig<NN>_<name> convention to the plain names used by main_final.tex
%   (e.g. fig03_BA_PL.png -> BA_PL.png).
%
%   If target_dir is omitted, defaults to the paper source's figures/
%   folder at D:\Joint-Point-Data-format-USC-NYU-Journal\figures.
%
%   Call AFTER run_all('figures') or run_all('rebuild'). The source files
%   are produced by fig03...fig08 drivers under matlab/figures/.
%
%   Inputs
%     target_dir  (optional char) destination directory. Created if missing.
%
%   Required mappings (paper tex -> unified output stem):
%     BA_PL            <- fig03_BA_PL
%     BA_DS            <- fig03_BA_DS
%     BA_PL7           <- fig03_BA_PL7
%     BA_DS7           <- fig03_BA_DS7
%     BA_ASA           <- fig04_BA_ASA
%     BA_ASD           <- fig04_BA_ASD
%     BA_ASA7          <- fig04_BA_ASA7
%     BA_ASD7          <- fig04_BA_ASD7
%     PLcombinedPlot   <- fig05_PLcombinedPlot
%     PLcombinedPlot7  <- fig05_PLcombinedPlot7
%     OmniDS_merged    <- fig06_OmniDS_merged
%     OmniDS_merged7   <- fig06_OmniDS_merged7
%     OmniASA_merged   <- fig07_OmniASA_merged
%     OmniASA_merged7  <- fig07_OmniASA_merged7
%     OmniASD_merged   <- fig08_OmniASD_merged
%     OmniASD_merged7  <- fig08_OmniASD_merged7

U = paths();
src_dir = U.out_dir;  % figures/matlab/

if nargin < 1 || isempty(target_dir)
    if ~isempty(U.paper_src_fig_dir)
        target_dir = U.paper_src_fig_dir;
    else
        fprintf('stage_paper_figures: PAPER_FIG_DIR not set; nothing to stage. Set PAPER_TREE_DIR or PAPER_FIG_DIR to enable.\n');
        return
    end
end

if ~exist(src_dir, 'dir')
    error('Source dir not found: %s\nRun run_all(''figures'') first.', src_dir);
end
if ~exist(target_dir, 'dir')
    mkdir(target_dir);
end

mapping = {
    'fig03_BA_PL',          'BA_PL'
    'fig03_BA_DS',          'BA_DS'
    'fig03_BA_PL7',         'BA_PL7'
    'fig03_BA_DS7',         'BA_DS7'
    'fig04_BA_ASA',         'BA_ASA'
    'fig04_BA_ASD',         'BA_ASD'
    'fig04_BA_ASA7',        'BA_ASA7'
    'fig04_BA_ASD7',        'BA_ASD7'
    'fig05_PLcombinedPlot', 'PLcombinedPlot'
    'fig05_PLcombinedPlot7','PLcombinedPlot7'
    'fig06_OmniDS_merged',  'OmniDS_merged'
    'fig06_OmniDS_merged7', 'OmniDS_merged7'
    'fig07_OmniASA_merged', 'OmniASA_merged'
    'fig07_OmniASA_merged7','OmniASA_merged7'
    'fig08_OmniASD_merged', 'OmniASD_merged'
    'fig08_OmniASD_merged7','OmniASD_merged7'
};

exts = {'.png', '.jpg', '.pdf', '.fig'};

% Back up any pre-existing paper figure to figures/_paper_original/ so the
% first-time overwrite preserves the paper's original renders.
backup_dir = fullfile(target_dir, '_paper_original');
if ~exist(backup_dir, 'dir'), mkdir(backup_dir); end

copied = 0; missing = {}; backed_up = 0;
for i = 1:size(mapping, 1)
    src_stem = mapping{i, 1};
    dst_stem = mapping{i, 2};
    any_ext_found = false;
    for j = 1:numel(exts)
        src = fullfile(src_dir, [src_stem, exts{j}]);
        if exist(src, 'file')
            dst = fullfile(target_dir, [dst_stem, exts{j}]);
            bkup = fullfile(backup_dir, [dst_stem, exts{j}]);
            if exist(dst, 'file') && ~exist(bkup, 'file')
                copyfile(dst, bkup);
                backed_up = backed_up + 1;
            end
            copyfile(src, dst);
            copied = copied + 1;
            any_ext_found = true;
        end
    end
    if ~any_ext_found
        missing{end+1} = src_stem; %#ok<AGROW>
    end
end

if backed_up > 0
    fprintf('  backed up %d pre-existing paper figures to %s\n', backed_up, backup_dir);
end

fprintf('stage_paper_figures: copied %d files from %s to %s\n', ...
    copied, src_dir, target_dir);
if ~isempty(missing)
    fprintf('  Missing source stems (not yet generated):\n');
    for k = 1:numel(missing)
        fprintf('    %s\n', missing{k});
    end
    fprintf('  Run run_all(''figures'') to produce these.\n');
end
end

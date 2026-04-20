function audit_ba_values()
% Print Bland-Altman bias / SD / n for PL, DS, ASA, ASD at
% (band, institution) combinations so I can cross-check paper prose.

addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'lib'));
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'config'));

T = load_point_data();
bands = {'subTHz', 'FR1C'};
insts = {'NYU',   'USC'};

fprintf('band,institution,metric,bias,SD,n\n');
for bi = 1:2
    band = bands{bi};
    for ii = 1:2
        inst = insts{ii};
        s = T(T.institution == string(inst) & T.band == string(band), :);

        pl  = s.pl_usc_pdm  - s.pl_nyu_sum;
        ds  = s.ds_usc_method - s.ds_nyu_method;
        asa = s.asa_usc - s.asa_nyu_10;
        asd = s.asd_usc - s.asd_nyu_10;

        fprintf('%s,%s,PL,%+.2f,%.2f,%d\n',  band, inst, mean(pl,  'omitnan'), std(pl,  'omitnan'), sum(~isnan(pl)));
        fprintf('%s,%s,DS,%+.2f,%.2f,%d\n',  band, inst, mean(ds,  'omitnan'), std(ds,  'omitnan'), sum(~isnan(ds)));
        fprintf('%s,%s,ASA,%+.2f,%.2f,%d\n', band, inst, mean(asa, 'omitnan'), std(asa, 'omitnan'), sum(~isnan(asa)));
        fprintf('%s,%s,ASD,%+.2f,%.2f,%d\n', band, inst, mean(asd, 'omitnan'), std(asd, 'omitnan'), sum(~isnan(asd)));
    end
end
end

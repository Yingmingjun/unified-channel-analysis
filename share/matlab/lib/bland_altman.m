function S = bland_altman(a, b)
% bland_altman  Bland-Altman agreement statistics for paired samples.
%
%   S = bland_altman(a, b) returns a struct with fields:
%       mean     : (a + b) / 2              vector
%       diff     :  a - b                   vector
%       bias     : mean(diff)               scalar
%       sd       : std(diff, ddof = 1)      scalar
%       loa_low  : bias - 1.96 * sd         scalar
%       loa_high : bias + 1.96 * sd         scalar
%       n        : number of finite paired samples used
%
%   Non-finite entries in either a or b are dropped pairwise.

% Mirrors python/src/channel_analysis/bland_altman.py bland_altman

a = double(a(:));
b = double(b(:));
mask = isfinite(a) & isfinite(b);
a = a(mask);
b = b(mask);

m = 0.5 * (a + b);
d = a - b;

if isempty(d)
    bias = NaN;
else
    bias = mean(d);
end
if numel(d) > 1
    sd = std(d, 0);   % ddof = 1 (sample)
else
    sd = NaN;
end

S = struct('mean', m, 'diff', d, 'bias', bias, 'sd', sd, ...
           'loa_low',  bias - 1.96 * sd, ...
           'loa_high', bias + 1.96 * sd, ...
           'n', numel(d));
end

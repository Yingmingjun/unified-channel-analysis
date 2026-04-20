function [point, lo, hi] = bootstrap_ci(data, stat_fn, n_boot, seed, alpha)
% bootstrap_ci  Generic percentile-method nonparametric bootstrap CI.
%
%   [point, lo, hi] = bootstrap_ci(data, stat_fn, n_boot, seed, alpha)
%
%   Inputs:
%     data    : numeric vector (non-finite entries are dropped) OR a
%               numeric matrix (resampling is done along rows).
%     stat_fn : function handle mapping a resampled data block to a scalar.
%     n_boot  : number of bootstrap resamples (default 2000).
%     seed    : RNG seed for reproducibility   (default 0).
%     alpha   : significance level for the (1-alpha) CI (default 0.05).
%
%   Outputs:
%     point   : stat_fn(data) on the original data.
%     lo, hi  : (alpha/2, 1-alpha/2) percentiles of the bootstrap replicates.
%
%   Use named anonymous-free handles (e.g., @mean) or named local functions
%   in drivers, per repo commenting style.

% Mirrors python/src/channel_analysis/stats.py bootstrap_ci

if nargin < 3 || isempty(n_boot), n_boot = 2000; end
if nargin < 4 || isempty(seed),   seed   = 0;    end
if nargin < 5 || isempty(alpha),  alpha  = 0.05; end

if isvector(data)
    data = double(data(:));
    data = data(isfinite(data));
end

n = size(data, 1);
if n == 0
    point = NaN; lo = NaN; hi = NaN;
    return
end

point = double(stat_fn(data));

rng(seed);
reps = zeros(n_boot, 1);
for b = 1:n_boot
    idx     = randi(n, n, 1);
    reps(b) = stat_fn(data(idx, :));
end
q  = quantile(reps, [alpha/2, 1 - alpha/2]);
lo = q(1);
hi = q(2);
end

function S = lognormal_stats(x, n_boot, seed)
% lognormal_stats  Lognormal summary with bootstrap CFI on the lognormal mean.
%
%   S = lognormal_stats(x, n_boot, seed) treats log10(x) as approximately
%   Normal and returns a struct with fields (Paper Eq. 11):
%
%       mu_log10       : sample mean of log10(x)
%       sigma_log10    : sample std of log10(x) (population, ddof = 0)
%       mean_arith     : arithmetic sample mean of x
%       mean_lognormal : exp(mu*ln10 + 0.5*(sigma*ln10)^2)
%       cfi_lo         : 2.5th percentile of bootstrapped mean_lognormal
%       cfi_hi         : 97.5th percentile
%       cfi_width      : cfi_hi - cfi_lo              (full 95 % width)
%       cfi_half_width : (cfi_hi - cfi_lo) / 2        (paper's AS column convention)
%       n              : number of finite positive samples used
%
%   The paper's Table VII "95 % CFI width" column for AS reports half-width
%   in almost all cases (ratio paper/pipeline = 0.45 - 0.55 for 8 of 11
%   AS cells); expose both so downstream code can pick the convention that
%   matches each cell.
%
%   Non-finite and non-positive samples are dropped before fitting.

% Mirrors python/src/channel_analysis/ds.py lognormal_stats
% Paper Section V.B, Eq. 11

if nargin < 2 || isempty(n_boot), n_boot = 2000; end
if nargin < 3 || isempty(seed),   seed   = 0;    end

x = double(x(:));
x = x(isfinite(x) & x > 0);
n = numel(x);

if n == 0
    S = struct('mu_log10', NaN, 'sigma_log10', NaN, ...
               'mean_arith', NaN, 'mean_lognormal', NaN, ...
               'cfi_lo', NaN, 'cfi_hi', NaN, 'cfi_width', NaN, ...
               'cfi_half_width', NaN, 'n', 0);
    return
end

lx            = log10(x);
ln10          = log(10.0);
mu_log10      = mean(lx);
sigma_log10   = std(lx, 1);                  % ddof = 0 (population)
mean_arith    = mean(x);
mean_lognormal = exp(mu_log10 * ln10 + 0.5 * (sigma_log10 * ln10)^2);

% -- Bootstrap CFI on the lognormal mean estimator ---------------------------
rng(seed);
idx     = randi(n, n_boot, n);
lx_boot = lx(idx);                           % (n_boot, n)
mu_b    = mean(lx_boot, 2);
sigma_b = std(lx_boot, 1, 2);                % ddof = 0
ln_means = exp(mu_b * ln10 + 0.5 * (sigma_b * ln10) .^ 2);

q  = quantile(ln_means, [0.025, 0.975]);
cfi_lo         = q(1);
cfi_hi         = q(2);
cfi_width      = cfi_hi - cfi_lo;
cfi_half_width = cfi_width / 2;

S = struct('mu_log10', mu_log10, 'sigma_log10', sigma_log10, ...
           'mean_arith', mean_arith, 'mean_lognormal', mean_lognormal, ...
           'cfi_lo', cfi_lo, 'cfi_hi', cfi_hi, 'cfi_width', cfi_width, ...
           'cfi_half_width', cfi_half_width, 'n', n);
end

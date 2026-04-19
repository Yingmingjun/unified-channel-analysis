function [ple, sigma_sf, cfi_lo, cfi_hi, cfi_width, cfi_half_width] = ci_pl_fit(d, pl, freq_ghz, n_boot, seed)
% ci_pl_fit  Close-In path-loss fit with bootstrap 95% CFI on the PLE.
%
%   [ple, sigma_sf, cfi_lo, cfi_hi, cfi_width, cfi_half_width] = ...
%       ci_pl_fit(d, pl, freq_ghz, n_boot, seed)
%
%   cfi_width is the full 95% bootstrap CI width (cfi_hi - cfi_lo).
%   cfi_half_width = cfi_width / 2 matches the paper's Table VII AS
%   convention (see lognormal_stats.m header for details).
%
%   Implements the Close-In model (Paper Eq. 13, 3GPP TR 38.901):
%       PL(d) = FSPL(1 m) + 10 * n * log10(d) + X_sigma,     d0 = 1 m
%
%   Inputs:
%     d        : vector of TX-RX separations in meters (>0)
%     pl       : vector of path-loss values in dB (same length as d)
%     freq_ghz : carrier frequency in GHz (drives FSPL(1 m))
%     n_boot   : number of bootstrap resamples (default 2000)
%     seed     : RNG seed for reproducibility      (default 0)
%
%   Outputs:
%     ple       : point estimate of the path-loss exponent n
%     sigma_sf  : shadow-fading standard deviation in dB
%     cfi_lo    : 2.5th  percentile of bootstrapped PLEs
%     cfi_hi    : 97.5th percentile of bootstrapped PLEs
%     cfi_width : cfi_hi - cfi_lo
%
%   FSPL(1 m) is fixed analytically, so only the slope n is estimated from
%   data. Non-finite and non-positive distances are dropped.

% Mirrors python/src/channel_analysis/pl.py ci_fit

if nargin < 4 || isempty(n_boot), n_boot = 2000; end
if nargin < 5 || isempty(seed),   seed   = 0;    end

d  = double(d(:));
pl = double(pl(:));
mask = isfinite(d) & isfinite(pl) & (d > 0);
d    = d(mask);
pl   = pl(mask);

if numel(d) < 2
    ple = NaN; sigma_sf = NaN; cfi_lo = NaN; cfi_hi = NaN;
    cfi_width = NaN; cfi_half_width = NaN;
    return
end

% -- FSPL at 1 m (Friis free-space, analytic closed form) ---------------------
c_ms     = 299792458.0;
lambda_m = c_ms ./ (freq_ghz * 1e9);
fspl_1m  = 20.0 * log10(4.0 * pi * 1.0 ./ lambda_m);

% -- Point estimate: n minimizes mean((pl - fspl_1m - 10*n*log10(d))^2) ------
x = 10.0 * log10(d);
y = pl - fspl_1m;
ple      = (x' * y) / (x' * x);
resid    = y - ple * x;
sigma_sf = sqrt(mean(resid .^ 2));

% -- Bootstrap on paired (d, pl) samples, vectorized over reps ---------------
rng(seed);
N   = numel(d);
idx = randi(N, n_boot, N);
x_b = x(idx);    % (n_boot, N)
y_b = y(idx);
n_reps = sum(x_b .* y_b, 2) ./ sum(x_b .* x_b, 2);

q = quantile(n_reps, [0.025, 0.975]);
cfi_lo         = q(1);
cfi_hi         = q(2);
cfi_width      = cfi_hi - cfi_lo;
cfi_half_width = cfi_width / 2;
end

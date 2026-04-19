function eps = dkw_band(n, alpha)
% dkw_band  Dvoretzky-Kiefer-Wolfowitz uniform CDF band half-width.
%
%   eps = dkw_band(n, alpha) returns
%       eps = sqrt(log(2/alpha) / (2*n))
%   so that P(sup_x |F_emp(x) - F_true(x)| <= eps) >= 1 - alpha.
%
%   Default alpha = 0.05 (95% uniform band). Returns 0 for n <= 0.

% Mirrors python/src/channel_analysis/stats.py dkw_band

if nargin < 2 || isempty(alpha), alpha = 0.05; end
if n <= 0
    eps = 0.0;
    return
end
eps = sqrt(log(2.0 / alpha) / (2.0 * n));
end

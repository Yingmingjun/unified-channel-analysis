function sigma_tau = rms_delay_spread(tau, p)
% rms_delay_spread  RMS delay spread of a single power-delay profile.
%
%   sigma_tau = rms_delay_spread(tau, p) implements Paper Eq. 9:
%
%       mean_tau  = sum(p .* tau)      / sum(p)
%       mean_tau2 = sum(p .* tau.^2)   / sum(p)
%       sigma_tau = sqrt(mean_tau2 - mean_tau^2)
%
%   Inputs:
%     tau : vector of delay bin centers (any consistent units; ns is usual)
%     p   : vector of linear (non-dB) powers at those bins, non-negative
%
%   Returns NaN when sum(p) <= 0. The variance is floored at 0 to suppress
%   tiny negative values from floating-point subtraction.

% Mirrors python/src/channel_analysis/ds.py rms_delay_spread_from_pdp
% Paper Section IV.A, Eq. 9

tau = double(tau(:));
p   = double(p(:));
total = sum(p);

if total <= 0
    sigma_tau = NaN;
    return
end

mean_tau  = sum(p .* tau)        / total;
mean_tau2 = sum(p .* (tau .^ 2)) / total;
var_tau   = max(mean_tau2 - mean_tau^2, 0.0);
sigma_tau = sqrt(var_tau);
end

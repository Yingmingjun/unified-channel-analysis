function sigma_deg = angular_spread_3gpp(theta_deg, power, is_db)
% angular_spread_3gpp  3GPP TR 38.901 circular standard deviation.
%
%   sigma_deg = angular_spread_3gpp(theta_deg, power, is_db) implements
%   Paper Eq. 10 (3GPP TR 38.901):
%
%       R     = | sum(p .* exp(j * theta)) / sum(p) |
%       sigma = sqrt(-2 * ln(R))         (radians, then converted to degrees)
%
%   Inputs:
%     theta_deg : vector of azimuth (or elevation) angles, in degrees
%     power     : vector of powers, one per angle
%     is_db     : logical; if true, power is in dB and is converted to
%                 linear via 10.^(power/10). Default false.
%
%   Degenerate cases: returns NaN if total power is non-positive. R is
%   clipped to (0, 1] before taking the log to avoid complex results.

% Mirrors python/src/channel_analysis/angular.py angular_spread_gpp
% Paper Section IV.A, Eq. 10

if nargin < 3 || isempty(is_db)
    is_db = false;
end

theta = double(theta_deg(:));
p     = double(power(:));
if is_db
    p = 10.0 .^ (p / 10.0);
end

total = sum(p);
if total <= 0
    sigma_deg = NaN;
    return
end

phasor = sum(p .* exp(1j * deg2rad(theta))) / total;
R      = abs(phasor);

if ~isfinite(R) || R <= 0
    sigma_deg = NaN;
    return
end
R = min(R, 1.0);

sigma_deg = rad2deg(sqrt(-2.0 * log(R)));
end

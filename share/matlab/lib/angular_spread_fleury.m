function sigma = angular_spread_fleury(theta_deg, power, is_db)
% angular_spread_fleury  Fleury angular spread, unitless in [0, 1].
%
%   sigma = angular_spread_fleury(theta_deg, power, is_db) implements
%   Paper Eq. 12 (Fleury 2000 / Table 5):
%
%       mu    = sum(p .* exp(j * theta)) / sum(p)
%       sigma = sqrt(1 - |mu|^2)
%
%   The result is unitless (in [0, sqrt(2)] theoretically, practically
%   in [0, 1]). To convert to a 3GPP-style angle in degrees, pass the
%   return value through fleury_to_gpp().
%
%   Returns NaN when the total power is non-positive.

% Mirrors python/src/channel_analysis/angular.py angular_spread_fleury
% Paper Section IV.A, Eq. 12

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
    sigma = NaN;
    return
end

mu    = sum(p .* exp(1j * deg2rad(theta))) / total;
sigma = sqrt(max(1.0 - abs(mu)^2, 0.0));
end

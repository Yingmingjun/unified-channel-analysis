function sigma_deg = fleury_to_gpp(sigma_fleury)
% fleury_to_gpp  Convert a Fleury AS value to a 3GPP AS in degrees.
%
%   sigma_deg = fleury_to_gpp(sigma_fleury)
%
%   Derivation: since sigma_fleury = sqrt(1 - |R|^2), we have
%       |R|   = sqrt(1 - sigma_fleury^2)
%       sigma_3gpp_deg = rad2deg(sqrt(-2 ln |R|))
%
%   Guards: clips the computed 1 - sigma^2 to 1e-16 to avoid log(0).

% Mirrors python/src/channel_analysis/angular.py fleury_to_gpp

if ~isfinite(sigma_fleury)
    sigma_deg = NaN;
    return
end

r2 = max(1.0 - sigma_fleury^2, 1e-16);
sigma_deg = rad2deg(sqrt(-2.0 * log(sqrt(r2))));
end

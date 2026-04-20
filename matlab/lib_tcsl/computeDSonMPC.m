function [rmsds, mds] = computeDSonMPC(delay_vec,power_vec, threshold)

% RMS DS
power_vec_linear = db2pow(power_vec);
meann = delay_vec'*power_vec_linear/sum(power_vec_linear);
varr = delay_vec'.^2*power_vec_linear/sum(power_vec_linear);
rmsds = sqrt(varr - meann^2);
if imag(rmsds) < 1e-3
    rmsds = real(rmsds);
end
% Maximum DS
max_p = max(power_vec);
mds = zeros(1,length(threshold));
for i = 1:length(threshold)
    th = threshold(i);
    delay_vec_th = delay_vec(power_vec > max_p - th);
    mds(i) = max(delay_vec_th) - min(delay_vec_th);
end



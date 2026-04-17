function noise_floor = noise_floor_calc_v2(pdp)
% Given the PDP we estimate the noise floor
% We sort the PDP from smallest to biggest value
pdp_sort2=sort(pdp); % sort energy in an ascedning manner
pdp_sort=pdp_sort2(isfinite(pdp_sort2)); % we eliminate any -Inf from the PDP
N=length(pdp_sort);%Calculate the length of the vector
N_noise=round(N/4); % We take sorted value at 25% to consider it as a noise floor (Umit used 25% I used 10% before)
Noise_value=(pdp_sort(N_noise));
noise_floor=Noise_value+5.41;% Noise floor calculated, we added 5.41 dB because it is 1st quartile instead of median.
end
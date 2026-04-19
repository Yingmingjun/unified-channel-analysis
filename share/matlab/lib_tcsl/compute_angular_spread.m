function [mean_angle, var_angle] = compute_angular_spread(angle_vec,power_vec,in_format,out_format)

if strcmp(in_format,'rad')
    angle_vec = rad2deg(angle_vec);
elseif strcmp(in_format,'deg')

else
    error('Wrong angular unit.')
end
Delta = 0:359;
power_line = db2pow(power_vec);
sigma_AS = zeros(1,360);
for i = 1:360
    d = Delta(i);
    theta_delta = mod(angle_vec+d+180,360) - 180;
    mu_theta = sum(power_line.*theta_delta)/sum(power_line);
    theta_mu = mod(theta_delta - mu_theta+180,360) - 180;
    temp = sqrt(sum(power_line.*theta_mu.^2)/sum(power_line));
    sigma_AS(i) = temp;
end
[var_angle,idx] = min(sigma_AS);
mean_angle = sum(power_line.*angle_vec)/sum(power_line);

if strcmp(out_format,'rad')
    mean_angle = deg2rad(mean_angle);
    var_angle = deg2rad(var_angle);
elseif strcmp(in_format,'deg')

else
    error('Wrong angular unit.')
end

%     theta_delta = mod(aoa_vec+d+pi,2*pi) - pi;
%     theta_mu = mod(theta_delta - mu_theta+pi,2*pi) - pi;

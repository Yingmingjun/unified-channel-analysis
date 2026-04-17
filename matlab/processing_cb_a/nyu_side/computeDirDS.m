function rmsds = computeDirDS(mpc_array,pointing_dir,azi_pattern,ele_pattern,threshold)

% This function is specifically for 142 GHz antenna

delay_vec = mpc_array(:,1);
power_vec = mpc_array(:,2);
for i = 1:length(delay_vec)
    mpc_dir = mpc_array(i,3:6);
    azi_diff = abs(mpc_dir([1,3])-pointing_dir([1,3]));
    azi_diff(azi_diff>180) = 360 - azi_diff(azi_diff>180);
    ele_diff = abs(mpc_dir([2,4])-pointing_dir([2,4]));
    antenna_gain = 0;
    %% azimuth angle
    for j = 1:2
        if azi_diff(j)<=90
            [~,ang_idx] = min(abs(azi_diff(j)-azi_pattern(:,1)));
            antenna_gain = antenna_gain + azi_pattern(ang_idx,2);
        else
            antenna_gain = antenna_gain + (-200);
        end
    end
    %% elevation angle
    for k = 1:2
        if ele_diff(k)<=90
            [~,ang_idx] = min(abs(ele_diff(k)-ele_pattern(:,1)));
            antenna_gain = antenna_gain + ele_pattern(ang_idx,2);
        else
            error('Elevation angle difference is too large.')
        end
    end
    power_vec(i) = power_vec(i) + antenna_gain;
end

[rmsds,~] = computeDSonMPC(delay_vec,power_vec, threshold);
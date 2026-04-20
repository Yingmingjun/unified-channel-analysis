function rmsds = computeDirDS73(mpc_array,pointing_dir,azi_pattern_TX,ele_pattern_TX,azi_pattern_RX,ele_pattern_RX,threshold)

% This function is specifically for 142 GHz antenna

delay_vec = mpc_array(:,1);
power_vec = mpc_array(:,2);
for i = 1:length(delay_vec)
    mpc_dir = mpc_array(i,3:6);
    azi_diff = abs(mpc_dir([1,3])-pointing_dir([1,3])); % 1 corresponds to AOD, 3 corr. to AOA
    azi_diff(azi_diff>180) = 360 - azi_diff(azi_diff>180);
    ele_diff = abs(mpc_dir([2,4])-pointing_dir([2,4])); % 2 corr to ZOD, 4 corr to ZOA
    antenna_gain = 0;
    %% azimuth angle
    %for j = 1:2
    if azi_diff(1)<=90
        [~,ang_idx] = min(abs(azi_diff(1)-azi_pattern_TX(:,1)));
        antenna_gain = antenna_gain + azi_pattern_TX(ang_idx,2);
    else
        antenna_gain = antenna_gain + (-200);
    end

    if azi_diff(2)<=90
        [~,ang_idx] = min(abs(azi_diff(2)-azi_pattern_RX(:,1)));
        antenna_gain = antenna_gain + azi_pattern_RX(ang_idx,2);
    else
        antenna_gain = antenna_gain + (-200);
    end
    %end
    %% elevation angle
    %for k = 1:2
    if ele_diff(1)<=90
        [~,ang_idx] = min(abs(ele_diff(1)-ele_pattern_TX(:,1)));
        antenna_gain = antenna_gain + ele_pattern_TX(ang_idx,2);
    else
        error('Elevation angle difference is too large.')
    end

    if ele_diff(2)<=90
        [~,ang_idx] = min(abs(ele_diff(2)-ele_pattern_RX(:,1)));
        antenna_gain = antenna_gain + ele_pattern_RX(ang_idx,2);
    else
        error('Elevation angle difference is too large.')
    end
    %end
    power_vec(i) = power_vec(i) + antenna_gain;
end

[rmsds,~] = computeDSonMPC(delay_vec,power_vec, threshold);
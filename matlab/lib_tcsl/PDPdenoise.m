function power_dB_deN=PDPdenoise(power_dB,threshold)
    PDPidcs=(1:length(power_dB))';
    power_idcs=PDPidcs(power_dB>=threshold); %power_idc(1) will now be time zero reference.

    if (isempty(power_idcs))
        power_dB_deN=[];
        return;
    end
    power_dB_deN=power_dB.*(power_dB>=threshold)+(-200).*(~(power_dB>=threshold));
    % removing very small spikes above the threshold
    power_idcs_L=[power_idcs(1); power_idcs(1:end-1)]; %the indexes of points above
                                 % the threshold shifted to the left by 1
    %power_idcs_R=[power_idcs(2:end); power_idcs(end)];
    width_chk_idxL=power_idcs-power_idcs_L; % values greater than one indicate 
                        % the end of the peak and the width of the peak
                        % that ended
                        % Lets get rid of peak less than 10
    %width_chk_idxR=power_idcs-power_idcs_R;
    width_maskStart=(width_chk_idxL>1);
    peakStart=power_idcs(width_maskStart);
    peakStop=peakStart-width_chk_idxL(width_maskStart);
    peakStart=[power_idcs(1) ; peakStart(1:end)];
    peakStop=[peakStop(1:end); power_idcs(end)];
    peakWidthsMask=(peakStop-peakStart)<=20;
    peakStart=peakStart(peakWidthsMask);
    peakStop=peakStop(peakWidthsMask);
    for i=1:length(peakStart)
        power_dB_deN(peakStart(i):peakStop(i))=-200;
    end
end
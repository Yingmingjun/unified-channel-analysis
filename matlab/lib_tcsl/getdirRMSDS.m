%% Get Dir RMS DS
function dirRMSDS=getdirRMSDS(PAS_Set)
    N=height(PAS_Set);
    threshold=-200;
    dirRMSDS=zeros(N,1);
    for i=1:N
        power_dB=PAS_Set{i,1};
        power_lin=db2pow(power_dB);
        PkPwrs=power_lin(power_dB>=threshold);
        PDPidcs=(1:length(power_dB))';
        power_idcs=PDPidcs(power_dB>=threshold);
        power_idcs_tau=(power_idcs-power_idcs(1))./20; % in ns
        MED=sum(PkPwrs.*power_idcs_tau)/sum(PkPwrs);
        MED2=sum(PkPwrs.*(power_idcs_tau.^2))/sum(PkPwrs);
        dirRMSDS(i)=sqrt(MED2-MED^2);
    end
end
function [delay_spread,md] = rms_delay_spread_calc(pdp,t,noise_floor)
% Inputs:
% pdp: Power delay profile in linear scale
% t: delay vector
% noise_floor: noise floor in dBm 
Nf = length(pdp);
pdp = reshape(pdp,[Nf,1]);
pdp_Ind=(10*log10(pdp)>=noise_floor); % Apply noise floor (This point is redundant)
pdp_val=pdp.*pdp_Ind; % Apply delay gating (This point is redundant)
% pdp_val=pdp.*pdp_Ind;
tp=sum(pdp_val); % Total Power
% md=(t.*(t<=tgate)*pdp_val)/tp;
% delay_spread=10*log10(sqrt(sum(((t.*(t<=tgate)).^2)*pdp_val)./tp-(md.^2)));
md=(t*pdp_val)/tp; % Mean delay
ds_lin = sqrt(max(0,sum((t.^2)*pdp_val)./tp-(md.^2)));

delay_spread=10*log10(ds_lin); % RMS-DS in dBs scale

% figure(1)
% plot(t*3e8,10*log10(pdp),'b',t*3e8,10*log10(pdp_val),'r'),grid minor, xlabel('Distance [m]'),ylabel('Squared Magnitude [dB]'),title(['\sigma_m= ',num2str(delay_spread),'dBs']);
% legend('PDP','PDP>\sigma^2_n')
end
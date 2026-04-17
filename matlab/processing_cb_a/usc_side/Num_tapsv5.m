%% THz Number of taps calculation
% Num_taps is a function that takes a delay filtered and noise thresholded
% PDP and computes the number of taps necessary to get X% of the total
% energy. The input PDP is assume to be oversampled by a factor of 10.
% For this particular iteration we center the 2ns tap with respect to the
% strongest peak of the PDP.
function [Ntap,Nwin,SIR_tap,SIR_win] = Num_tapsv5(PDP, SIR_dB)
    Ntap = zeros(1,length(SIR_dB));
    Nwin = Ntap;
    SIR_tap = Ntap;
    SIR_win = Nwin;
    % These lines were inside the loop, but they don't change at all
    N_over = 10; % We assume an oversampling factor of 10
    tap_size = 2*N_over; % Assuming using a Hann window
    [~,PDP_max_idx] = max(PDP); % Select maximum of the PDP
    PDP_temp2 = movsum(PDP,tap_size);
    idx_start = mod(PDP_max_idx,tap_size)+1;
    PDP_temp = PDP_temp2(idx_start:tap_size:length(PDP_temp2));
    % E_total = sum(PDP);
    E_total = sum(PDP_temp);
    PDP_norm = PDP_temp./E_total;
    % PDP_sort_norm = sort(PDP_temp,'descend');
    PDP_sort_norm = sort(PDP_norm,'descend');
    E_cum = cumsum(PDP_sort_norm);
    SIR = 10.^(SIR_dB/10);
    gamma = SIR./(SIR+1);
    for jj = 1:length(Ntap)
        E_idx = find(E_cum >= gamma(jj));
        if isempty(E_idx)
            Ntap(jj) = find(round(E_cum,4) == max(round(E_cum,4)),1,'first');
        else
            Ntap(jj) = E_idx(1);
        end
        SIR_tap(jj) = 10*log10(E_cum(E_idx(1))/(1-E_cum(E_idx(1))));  
        W_vec = zeros(1,length(PDP_temp));
        E_vec = W_vec;
        for ii = 1 : length(PDP_temp)
            % E_cum_temp = cumsum(PDP_temp(ii:end));
            E_cum_temp = cumsum(PDP_norm(ii:end));
            E_idx_temp = find(E_cum_temp >= gamma(jj));
            if ~isempty(E_idx_temp)
                W_vec(ii) = E_idx_temp(1);
                E_vec(ii) = E_cum_temp(E_idx_temp(1));
            else
                W_vec(ii) = Inf;
                E_vec(ii) = 0;
            end
        end
        temp_min_win = find(W_vec == min(W_vec));
        if length(temp_min_win) == 1
            [Nwin(jj),idx_win] =  min(W_vec); % If I have more than one window fulfilling the SIR constraint, then I choose the one that gives the highest SIR
            SIR_win(jj) = 10*log10(E_vec(idx_win)/(1-E_vec(idx_win)));
        else
            W_vec_temp = W_vec(temp_min_win);
            E_vec_temp = E_vec(temp_min_win);
            [gamma_max, idx_gamma_max] = max(E_vec_temp);
            Nwin(jj) = W_vec_temp(idx_gamma_max);
            SIR_win(jj) = 10*log10(gamma_max/(1-gamma_max));
        end
    end
end
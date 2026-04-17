function [PDP_omni_over,PDP_omni,PL_omni,RMS_omniv2,AS_RX,ZS_RX,AS_TX,ZS_TX,noise_thresh]=USCprocessing(basePath,fileName,TR_distance,Ptx,thr,keyStr)
    %% Load file
    
    load(basePath+fileName);
    %PDPdir PDPs are in dB
    
    % Load thresholded NYU metadata (if available) for angle-based noise evaluation.
    % This gates noise_floor_calc_v2 to only those angle bins with matching Outdoor142 entries.
    % The thresholded files live in the working directory under NYU_Data_thresholded\142 GHz.
    thresholdBase = fullfile(pwd, 'NYU_Data_thresholded', '142 GHz');
    % Use the TX/RX key from the caller when available; fallback to filename parsing.
    thrMatch = [];
    if nargin >= 6 && (ischar(keyStr) || isstring(keyStr))
        keyStr = strtrim(char(keyStr));
        % Accept "1_1" or "T1-R1" style keys
        keyMatch = regexp(keyStr, '^(?<TXID>\d+)_(?<RXID>\d+)$', 'names');
        if isempty(keyMatch)
            keyMatch = regexp(keyStr, '^T(?<TXID>\d+)-R(?<RXID>\d+)$', 'names');
        end
        if ~isempty(keyMatch)
            thrMatch = keyMatch;
        end
    end
    if isempty(thrMatch)
        thrMatch = regexp(fileName, 'T(?<TXID>\d+)-R(?<RXID>\d+)', 'names');
    end
    Outdoor142 = [];
    if ~isempty(thrMatch)
        thrFile = fullfile(thresholdBase, sprintf('142GHz_Outdoor_T%d-R%d.mat', ...
            str2double(thrMatch.TXID), str2double(thrMatch.RXID)));
        if exist(thrFile, 'file') == 2
            thrData = load(thrFile, 'Outdoor142');
            if isfield(thrData, 'Outdoor142')
                Outdoor142 = thrData.Outdoor142;
            end
        end
    end
    if ~isempty(Outdoor142)
        % Precompute Outdoor142 angle signatures for fast matching (columns 6-9)
        OutdoorAngles = cell2mat(Outdoor142(:,6:9));
    else
        OutdoorAngles = [];
    end
    
    %% Initiaize parameters
    [Nf,N_aztx,N_eltx,N_azrx,N_elrx]=size(PDP_dir);
    n_oversamp=20;
    %n_oversamp is 20 instead of 10 for NYU. we have, 81880 sample PDP
    % where 20 samples is equivalent to 1 ns
    %PDPs are time dilated
    d=(0:(Nf/20)-1)*3e8/1e9;
    d2=(0:1/n_oversamp:(Nf/20)-1/n_oversamp)*3e8/1e9;
    d_LOS = TR_distance;
    
    %% Create non-dilated PDP
    PDP_dirS=reshape(PDP_dir,20,4094,N_aztx,N_eltx,N_azrx,N_elrx);
    PDP_dirS=pow2db(squeeze(sum(db2pow(PDP_dirS),1)));
    
    % Initialize with -Inf so unmatched bins do not influence max noise
    noise_temp = -250.*ones(N_aztx,N_eltx,N_azrx,N_elrx);
    % Precompute a match mask for all angle bins to avoid per-bin row searches.
    if ~isempty(OutdoorAngles)
        spAnglesList = reshape(spAngles, [], 1);
        spAngleRows = cell2mat(spAnglesList);
        matchMask = ismember(spAngleRows, OutdoorAngles, 'rows');
        matchMask = reshape(matchMask, [N_aztx, N_eltx, N_azrx, N_elrx]);
    else
        matchMask = false(N_aztx, N_eltx, N_azrx, N_elrx);
    end
    count=0;
    blankPDP= -250.*ones(1,size(PDP_dirS,1));
    blankPDPover= -250.*ones(1,size(PDP_dir,1));
    % Zero out unmatched bins in one vectorized pass to reduce loop work.
    if ~all(matchMask(:))
        PDP_dirS(:,~matchMask) = repmat(blankPDP.', 1, nnz(~matchMask));
        PDP_dir(:,~matchMask)  = repmat(blankPDPover.', 1, nnz(~matchMask));
    end
    for az_tx_idx=1 :N_aztx
        for el_tx_idx=1:N_eltx
            for az_rx_idx=1:N_azrx
                for el_rx_idx=1:N_elrx
                    % Skip noise evaluation when no thresholded PDP exists for this angle
                    if ~matchMask(az_tx_idx,el_tx_idx,az_rx_idx,el_rx_idx)
                        continue;
                    end
                    pdp_temp=squeeze(PDP_dirS(:,az_tx_idx,el_tx_idx,az_rx_idx,el_rx_idx));
                    % pdp_tempdB=squeeze(PDP_dir(:,az_tx_idx,el_tx_idx,az_rx_idx,el_rx_idx));
                    count=count+1;
                    %noise_temp has been modified to accommodate pdps in db
                    noise_temp(az_tx_idx,el_tx_idx,az_rx_idx,el_rx_idx)=noise_floor_calc_v2(pdp_temp);
                end
            end
        end
    end
    disp(count);
    [max_noise]=max(noise_temp,[],'all');
    if ~isfinite(max_noise)
        error('No matching Outdoor142 angle signatures found for %s', fileName);
    end
    % might need to check noise floor behavior and verify PDP calibration when
    % creating the NYU data for USC
    [Az_Tx,El_Tx,Az_Rx,El_Rx]=ind2sub(size(noise_temp),find(noise_temp==max_noise));
    noise_thresh=noise_temp(Az_Tx,El_Tx,Az_Rx,El_Rx)+thr;
    
    PDP_dirS(PDP_dirS<=noise_thresh)=-250; % Apply noise threshold to the entire capture
    
    %% APDS formation
    PDP_temp1=squeeze(sum(db2pow(PDP_dirS),5)); % We add 3 elevations in Rx %PDP_temp1 is linear
    APDS = squeeze(sum(PDP_temp1,3)); % We add 3 elevations in Tx to get APDS
    APDS_Rx = squeeze(sum(APDS,2)); % We compute the APDS_Rx by adding all the Tx azimuths
    APDS_Tx = squeeze(sum(APDS,3)); % We compute the APDS_Tx by adding all the Rx azimuths
    
    %% Omni PDP formation
    PDP_temp2=squeeze(max(PDP_temp1,[],4)); % select the max in Az Rx
    PDP_temp3=squeeze(sum(PDP_temp2,3)); % We add 3 elevations in Tx
    PDP_omni=squeeze(max(PDP_temp3,[],2)); % select the max in Az Tx (We divide it by 0.98*2=1.95dB, 3.6dB because of the extra gain when adding the multiple elevations on both sides)
    
    if d_LOS >= 5 % We perform a circhsift to minimize wrap arounds of the capture. If the d_LOS distance is < 5 we don't do anything
        PDP_omni = circshift(PDP_omni,-round((d_LOS-5)/d(2)));
    end
    
    [max_pk_omni,~] = max(PDP_omni); % peak value
    DR_omni = 10*log10(max_pk_omni)-noise_thresh; % We compute dynamic range of the capture for omni case
    

    %% max directional PDP
    pdp_lin=db2pow(PDP_dir);
    Power_per_antenna=squeeze(sum(pdp_lin,1)); % We add all delay bins to have the power per antenna direction (Tx_Az,Tx_El,Rx_Az,Rx_El)
    [max_pow]=max(Power_per_antenna,[],'all'); % We find the strongest power 
    [Az_Tx,El_Tx,Az_Rx,El_Rx]=ind2sub(size(Power_per_antenna),find(Power_per_antenna==max_pow)); % We find the corresponding antenna
    PDP_dir_max=squeeze(PDP_dir(:,Az_Tx,El_Tx,Az_Rx,El_Rx)); % Given the direction we extract the corresponding PDP
    [max_pk_md,~] = max(PDP_dir_max); % peak value
    DR_max_dir = max_pk_md-noise_thresh+54; % We compute dynamic range of the capture for max_dir case
    
    %% Dilated PDP
    PDP_dir_over=PDP_dir;
    PDP_dir_over(PDP_dir_over<=(noise_thresh-20*log10(n_oversamp)))=-250; % We apply the noise threshold
    %PDP_dir_over(PDP_dir_over<=(noise_thresh-20))=-250; % We apply the noise threshold
    PDP_temp1_over=squeeze(sum(db2pow(PDP_dir_over),5)); % sum over all elevations in Rx
    PDP_temp2_over=squeeze(max(PDP_temp1_over,[],4)); % max over all azimuth in Rx
    PDP_temp3_over=squeeze(sum(PDP_temp2_over,3)); % sum over all elevations in Tx
    PDP_omni_over=squeeze(max(PDP_temp3_over,[],2));
    if d_LOS >= 5 % We perform a circhsift to minimize wrap arounds of the capture. If the d_LOS distance is < 5 we don't do anything
        PDP_omni_over = circshift(PDP_omni_over,-round((d_LOS-5)/d2(2)));
    end

    Pr_omni=10*log10(sum(PDP_omni_over)); % Omni received power in dBm
    PL_omni=Ptx+54-Pr_omni; % PL = Ptx + G_tx(27dBi) + G_rx(27dBi) - Pr_omni
    
    %% RMS DS
    % if d_LOS >= 5
    %     [RMS_omniv2,temp_pdp_omni] = rms_delay_spread_calc(PDP_omni_over,((d2+d_LOS)/3e8),noise_thresh-20*log10(n_oversamp)); % No rotated
    % else
    %     [RMS_omniv2,temp_pdp_omni] = rms_delay_spread_calc(PDP_omni_over,((d2)/3e8),noise_thresh-20*log10(n_oversamp)); % No rotated
    % end
    [RMS_omniv2,temp_pdp_omni] = rms_delay_spread_calc(PDP_omni_over,((d2)/3e8),noise_thresh-20*log10(n_oversamp)); % No rotated
    %[RMS_omniv2,temp_pdp_omni] = rms_delay_spread_calc(PDP_omni_over,((d2)/3e8),noise_thresh-20); % No rotated
    %%% Dipankar: check if you need to circular shift the pdp such that PDP
    %%% and d2 are aligned and first MPC delay is remolved
    %%% rms DS is delay invariantl
    
    PDP_dir_max_over=squeeze(PDP_dir_over(:,Az_Tx,El_Tx,Az_Rx,El_Rx)); % Given the direction we extract the corresponding PDP
    if d_LOS >= 5
        [RMS_max_dir_v2,temp_pdp_mdir] = rms_delay_spread_calc(PDP_dir_max_over,((d2+d_LOS)/3e8),noise_thresh-20*log10(n_oversamp));
        %[RMS_max_dir_v2,temp_pdp_mdir] = rms_delay_spread_calc(PDP_dir_max_over,((d2+d_LOS)/3e8),noise_thresh-20);
    else
        [RMS_max_dir_v2,temp_pdp_mdir] = rms_delay_spread_calc(PDP_dir_max_over,(d2/3e8),noise_thresh-20*log10(n_oversamp));
        %[RMS_max_dir_v2,temp_pdp_mdir] = rms_delay_spread_calc(PDP_dir_max_over,(d2/3e8),noise_thresh-20);
    end
    
    %% Angular Spread
    ang_Tx=reshape([spAngles{:,1,1,1}],4,45); % Tx_Az vector
    ang_Tx=ang_Tx(1,:);
    ang_zTx=reshape([spAngles{1,:,1,1}],4,3); % Tx_El vector
    ang_zTx=ang_zTx(2,:);
    ang_Rx=reshape([spAngles{1,1,:,1}],4,45); % Rx_Az vector
    ang_Rx=ang_Rx(3,:);
    ang_zRx=reshape([spAngles{1,1,1,:}],4,3); % Tx_El vector
    ang_zRx=ang_zRx(4,:);
    
    %[xx,yy]=meshgrid(ang_Tx,ang_Rx); % Mesh rid for APDS
    
    APS_Total=squeeze(sum(sum(Power_per_antenna,4),2)); % Obtain the double azimuthal APS
    APS_zTotal=squeeze(sum(sum(Power_per_antenna,3),1)); % Obtain the double azimuthal APS
    APS_Tx=sum(APS_Total,2).'; % Obtain the Tx azimuthal APS
    APS_zTx=sum(APS_zTotal,2).'; % Obtain the Tx azimuthal APS
    APS_Rx=sum(APS_Total,1); % Obtain the Rx azimuthal APS
    APS_zRx=sum(APS_zTotal,1); % Obtain the Tx azimuthal APS
    
    AS_TX=ASfleury(ang_Tx,APS_Tx); % Compute TX_AS using Fleury's definition
    AS_RX=ASfleury(ang_Rx,APS_Rx); % Compute RX_AS using Fleury's definition
    ZS_TX=ASfleury(ang_zTx,APS_zTx); % Compute TX_AS using Fleury's definition
    ZS_RX=ASfleury(ang_zRx,APS_zRx); % Compute RX_AS using Fleury's definition
end

function [Sec_statTable,statTable]=SecondaryStatsD(statTable,elevPatternFile,aziPatternFile)

    Nlocs = height(statTable);
    omni_ds = zeros(Nlocs,1);
    dir_ds = [];
    cluster_ds = [];
    omni_asd = zeros(Nlocs,1);
    omni_zsd = zeros(Nlocs,1);
    omni_asa = zeros(Nlocs,1);
    omni_zsa = zeros(Nlocs,1);
    lobe_asd = [];
    lobe_zsd = [];
    lobe_asa = [];
    lobe_zsa = [];

    Sec_statTable = cell([Nlocs,11]);
    
    for iloc = 2:Nlocs
        tempDlys=vertcat(statTable{iloc,16})./20;%./16 for 28 GHz
        MPCdelays=tempDlys-min(tempDlys);
        MPCpowers=vertcat(statTable{iloc,14});
        MPC_AOA=mod(vertcat(statTable{iloc,28}),360);
        MPC_AOD=mod(vertcat(statTable{iloc,29}),360);
        MPC_ZOA=vertcat(statTable{iloc,30});
        MPC_ZOD=vertcat(statTable{iloc,31});
        MPCarray=[MPCdelays,MPCpowers,MPC_AOD,MPC_ZOD,MPC_AOA,MPC_ZOA];%[del,pow,AOD,ZOD,AOA,ZOA]
        mpc_threshold=25;

        %array_temp = sim_chann_cell{iloc,1};
        % Omni DS
        [omni_ds(iloc),~] = computeDSonMPC(MPCdelays,MPCpowers,mpc_threshold);
        % Omni ASD
        MPC_AOD_e=[MPC_AOD;cell2mat(statTable{iloc,41})];% expand with col 41
        MPCpowers_e=[MPCpowers;cell2mat(statTable{iloc,40})];% expand with col 40
        [~,omni_asd(iloc)] = compute_angular_spread(MPC_AOD_e,MPCpowers_e,'deg','deg');
        % Omni ZSD
        MPC_ZOD_e=[MPC_ZOD;cell2mat(statTable{iloc,42})];% expand with col 41
        %MPCpowers_e=[MPCpowers;cell2mat(statTable{iloc,40})];% expand with col 40
        [omni_zsd(iloc),~] = computeDSonMPC(MPC_ZOD_e+90,MPCpowers_e,mpc_threshold);
        % Omni ASA
        MPC_AOA_e=[MPC_AOA;cell2mat(statTable{iloc,38})];% expand with col 41
        MPCpowers_e=[MPCpowers;cell2mat(statTable{iloc,37})];% expand with col 40
        [~,omni_asa(iloc)] = compute_angular_spread(MPC_AOA_e,MPCpowers_e,'deg','deg');
        % Omni ZSA
        MPC_ZOA_e=[MPC_ZOA;cell2mat(statTable{iloc,39})];% expand with col 41
        %MPCpowers_e=[MPCpowers;cell2mat(statTable{iloc,37})];% expand with col 40
        [omni_zsa(iloc),~] = computeDSonMPC(MPC_ZOA_e+90,MPCpowers_e,mpc_threshold);
        % Dir DS
        nMPCs=length(MPCdelays);
        dir_ds_temp = zeros(nMPCs,1);
        
        for j = 1:nMPCs
            dir_ds_temp(j) = computeDirDS(MPCarray,MPCarray(j,3:6),...
                    aziPatternFile,elevPatternFile,mpc_threshold);
        end
        dir_ds = dir_ds_temp;
        % Cluster DS
        nTCs = statTable{iloc,8};
        TCstart = statTable{iloc,9};
        TCstop = statTable{iloc,10};
        SP_idx = statTable{iloc,16};
        cluster_ds_temp = zeros(nTCs,1);
        for j = 1:nTCs
            TCmask=(SP_idx>=TCstart(j))&(SP_idx<=TCstop(j));
            part_array = MPCarray(TCmask,:);
            [cluster_ds_temp(j),~] = computeDSonMPC(part_array(:,1),part_array(:,2),mpc_threshold);
        end
        cluster_ds = cluster_ds_temp;
    
        % Lobe ASA and ZSA
        nAOA_SL = statTable{iloc,32};
        AOA_SL_angles = statTable{iloc,33};
        lobe_asa_temp = zeros(nAOA_SL,1);
        lobe_zsa_temp = zeros(nAOA_SL,1);
        remove=0;
        rmv_idx=false(nAOA_SL,1);
        for j = 1:nAOA_SL
            SLmask = any(MPC_AOA==mod([AOA_SL_angles{j}]',360),2);
            part_array = MPCarray(SLmask,:);
            MPC_LobeAOA_e=[part_array(:,5);statTable{iloc,38}{j}];% expand with col 41
            MPC_LobeZOA_e=[part_array(:,6);statTable{iloc,39}{j}];% expand with col 41
            MPCpowers_e=[part_array(:,2);statTable{iloc,37}{j}];% expand with col 40
            if(~isempty(part_array))
                [~,lobe_asa_temp(j)] = compute_angular_spread(MPC_LobeAOA_e,MPCpowers_e,'deg','deg');
                [lobe_zsa_temp(j),~] = computeDSonMPC(MPC_LobeZOA_e+90,MPCpowers_e,mpc_threshold);
            else
                %lobe_asa_temp(j)=[];
                %lobe_zsa_temp(j)=[];
                rmv_idx(j)=true;
                remove=remove+1;
            end
        end
        
        if (remove>0)
            AOA_SL_angles(rmv_idx)=[];
            nAOA_SL = nAOA_SL-remove;
            statTable{iloc,32} = nAOA_SL;
            statTable{iloc,33} = AOA_SL_angles;
            lobe_asa_temp(rmv_idx)=[];
            lobe_zsa_temp(rmv_idx)=[];
        end
        lobe_asa = lobe_asa_temp;
        lobe_zsa = real(lobe_zsa_temp);
        % Lobe ASD and ZSD
        nAOD_SL = statTable{iloc,34};
        AOD_SL_angles = statTable{iloc,35};
        lobe_asd_temp = zeros(nAOD_SL,1);
        lobe_zsd_temp = zeros(nAOD_SL,1);
        remove=0;
        rmv_idx=false(nAOD_SL,1);
        for j = 1:nAOD_SL
            SLmask = any(MPC_AOD==mod([AOD_SL_angles{j}]',360),2);
            part_array = MPCarray(SLmask,:);
            MPC_LobeAOD_e=[part_array(:,3);statTable{iloc,41}{j}];% expand with col 41
            MPC_LobeZOD_e=[part_array(:,4);statTable{iloc,42}{j}];% expand with col 41
            MPCpowers_e=[part_array(:,2);statTable{iloc,40}{j}];% expand with col 40
            if(~isempty(part_array))
                [~,lobe_asd_temp(j)] = compute_angular_spread(MPC_LobeAOD_e,MPCpowers_e,'deg','deg');
                [lobe_zsd_temp(j),~] = computeDSonMPC(MPC_LobeZOD_e+90,MPCpowers_e,mpc_threshold);
            else
                %lobe_asd_temp(j)=[];
                %lobe_zsd_temp(j)=[];
                rmv_idx(j)=true;
                remove=remove+1;
            end
        end

        if (remove>0)
            AOD_SL_angles(rmv_idx)=[];
            nAOD_SL = nAOD_SL-remove;
            statTable{iloc,34} = nAOD_SL;
            statTable{iloc,35} = AOD_SL_angles;
            lobe_asd_temp(rmv_idx)=[];
            lobe_zsd_temp(rmv_idx)=[];
        end
        lobe_asd = lobe_asd_temp;
        lobe_zsd = real(lobe_zsd_temp);

        Sec_statTable{iloc,1}=omni_ds(iloc);
        Sec_statTable{iloc,2}=omni_asd(iloc);
        Sec_statTable{iloc,3}=omni_zsd(iloc);
        Sec_statTable{iloc,4}=omni_asa(iloc);
        Sec_statTable{iloc,5}=omni_zsa(iloc);
        Sec_statTable{iloc,6}=dir_ds;
        Sec_statTable{iloc,7}=cluster_ds;
        Sec_statTable{iloc,8}=lobe_asd;
        Sec_statTable{iloc,9}=lobe_zsd;
        Sec_statTable{iloc,10}=lobe_asa;
        Sec_statTable{iloc,11}=lobe_zsa;
        Sec_statTable{iloc,12}=statTable{iloc,25};
        Sec_statTable{iloc,13}=statTable{iloc,36};
    end
end
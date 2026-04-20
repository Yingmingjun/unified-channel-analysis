% function [Sec_statTable,statTable]=SecondaryStats_circD(statTable,elevPatternFile,aziPatternFile)
function [Sec_statTable,statTable]=SecondaryStats_circD(statTable,elevPatternFile,aziPatternFile,dilationFactor)
    if nargin < 4
        dilationFactor = 20;  % Default for NYU
    end

    


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

    Sec_statTable = cell([Nlocs,18]);
    
    for iloc = 1:Nlocs
        % tempDlys=vertcat(statTable{iloc,16})./20;%./16 for 28 GHz
        tempDlys=vertcat(statTable{iloc,16})./dilationFactor;
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
        MPC_AOD_e=[MPC_AOD;cell2mat(statTable{iloc,42})];% expand with col 41
        MPCpowers_e=[MPCpowers;cell2mat(statTable{iloc,41})];% expand with col 40
        MPCpowersW=db2pow(MPCpowers_e);
        MPCpowersW=MPCpowersW./sum(MPCpowersW);
        [~,omni_asd(iloc)] = circ_std(deg2rad(MPC_AOD_e),MPCpowersW);
        omni_asd(iloc)=rad2deg(omni_asd(iloc));
        % Omni ZSD
        MPC_ZOD_e=[MPC_ZOD;cell2mat(statTable{iloc,43})];% expand with col 41
        %MPCpowers_e=[MPCpowers;cell2mat(statTable{iloc,40})];% expand with col 40
        [~,omni_zsd(iloc)] = circ_std(deg2rad(MPC_ZOD_e+90),MPCpowersW);
        omni_zsd(iloc)=rad2deg(omni_zsd(iloc));
        % Omni ASA
        MPC_AOA_e=[MPC_AOA;cell2mat(statTable{iloc,38})];% expand with col 41
        MPCpowers_e=[MPCpowers;cell2mat(statTable{iloc,37})];% expand with col 40
        MPCpowersW=db2pow(MPCpowers_e);
        MPCpowersW=MPCpowersW./sum(MPCpowersW);
        [~,omni_asa(iloc)] = circ_std(deg2rad(MPC_AOA_e),MPCpowersW);
        omni_asa(iloc)=rad2deg(omni_asa(iloc));
        % Omni ZSA
        MPC_ZOA_e=[MPC_ZOA;cell2mat(statTable{iloc,39})];% expand with col 41
        %MPCpowers_e=[MPCpowers;cell2mat(statTable{iloc,37})];% expand with col 40
        [~,omni_zsa(iloc)] = circ_std(deg2rad(MPC_ZOA_e+90),MPCpowersW);
        omni_zsa(iloc)=rad2deg(omni_zsa(iloc));
        % Dir DS
        %Point the antenna at the direction of each MPC and find DS for
        %antenna pattern imposed
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
            MPC_LobeZOA_e=[part_array(:,6);max(part_array(:,6)+statTable{iloc,40}{j}(1))];
            MPC_LobeZOA_e=[MPC_LobeZOA_e;min(part_array(:,6)-statTable{iloc,40}{j}(2))];
            %MPC_LobeZOA_e=[part_array(:,6);statTable{iloc,39}{j}];% expand with col 41
            MPCpowers_e=[part_array(:,2);statTable{iloc,37}{j}];% expand with col 40
            if(~isempty(part_array))
                subMPCpowersW=db2pow(MPCpowers_e);
                subMPCpowersW=subMPCpowersW./sum(subMPCpowersW);
                [~,lobe_asa_temp(j)] = circ_std(deg2rad(MPC_LobeAOA_e),subMPCpowersW);
                lobe_asa_temp(j)=rad2deg(lobe_asa_temp(j));
                [~,lobe_zsa_temp(j)] = circ_std(deg2rad(MPC_LobeZOA_e+90),subMPCpowersW);
                lobe_zsa_temp(j)=rad2deg(lobe_zsa_temp(j));
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
            MPC_LobeAOD_e=[part_array(:,3);statTable{iloc,42}{j}];% expand with col 41
            MPC_LobeZOD_e=[part_array(:,4);max(part_array(:,4)+statTable{iloc,44}{j}(1))];
            MPC_LobeZOD_e=[MPC_LobeZOD_e;min(part_array(:,4)-statTable{iloc,44}{j}(2))];
            %MPC_LobeZOD_e=[part_array(:,4);statTable{iloc,42}{j}];% expand with col 41
            MPCpowers_e=[part_array(:,2);statTable{iloc,41}{j}];% expand with col 40
            if(~isempty(part_array))
                subMPCpowersW=db2pow(MPCpowers_e);
                subMPCpowersW=subMPCpowersW./sum(subMPCpowersW);
                [~,lobe_asd_temp(j)] = circ_std(deg2rad(MPC_LobeAOD_e),subMPCpowersW);
                lobe_asd_temp(j)=rad2deg(lobe_asd_temp(j));
                [~,lobe_zsd_temp(j)] = circ_std(deg2rad(MPC_LobeZOD_e+90),subMPCpowersW);
                lobe_zsd_temp(j)=rad2deg(lobe_zsd_temp(j));
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

        % | 1. Omni DS | 2. Omni ASD | 3. Omni ZSD | 4. Omni ASA | 
        % 5. Omni ZSA | 6. Dir DS | 7. Cluster DS | 8. Lobe ASD | 
        % 9. Lobe ZSD | 10. Lobe ASA | 11. Lobe ZSA | 12. Environment (LOS or NLOS) |

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
        Sec_statTable{iloc,14}=10^(mean(log10(dir_ds(dir_ds>1e-4)))+(0.5*(std(log10(dir_ds(dir_ds>1e-4)))^2)));
        Sec_statTable{iloc,15}=10^(mean(log10(lobe_asa))+(0.5*(std(log10(lobe_asa))^2)));
        Sec_statTable{iloc,16}=10^(mean(log10(lobe_asd))+(0.5*(std(log10(lobe_asd))^2)));
        Sec_statTable{iloc,17}=10^(mean(log10(lobe_zsa))+(0.5*(std(log10(lobe_zsa))^2)));
        Sec_statTable{iloc,18}=10^(mean(log10(lobe_zsd))+(0.5*(std(log10(lobe_zsd))^2)));
    end
end
function [AllSPRefAngles,AllSPZRefAngles,AllSPZAltAngles,AllSPAltAngles,SP_idx,SP_pwr]=SubPathPwrDirs(PAS_set,lobeCount,lobewidths,ends,starts,PAS_angles,multipath_low_bound)
    AllSPRefAngles=cell(lobeCount,1);
    AllSPZRefAngles=cell(lobeCount,1);
    AllSPZAltAngles=cell(lobeCount,1);
    AllSPAltAngles=cell(lobeCount,1);
    SP_idx=cell(lobeCount,1);
    SP_pwr=cell(lobeCount,1);
    %%Create semi-omni PDP
    allAngles=[PAS_set{:,3}]';
    for iLobe=1:lobeCount
        if(lobewidths(iLobe)==360)
            idx=(PAS_angles>=starts(iLobe))|(PAS_angles<=ends(iLobe));
        else
            if (starts(iLobe)>ends(iLobe))
                idx=(PAS_angles>=starts(iLobe))|(PAS_angles<=ends(iLobe));
            else
                idx=(PAS_angles>=starts(iLobe))&(PAS_angles<=ends(iLobe));
            end
        end
        
        SLangles=PAS_angles(idx);
        SLangles(SLangles==360)=0;
        SLangles=sort(SLangles,'ascend');
        Nangles=length(SLangles);
        %PAS_set breakdown:
        %sum PDP for angle| Sum Power | Angle | Constituent directions for sum power | PDPs making sum PDP
        SemiOmniIdx=any((allAngles==SLangles'),2);
        SemiOmniPDP=pow2db(sum(db2pow([PAS_set{SemiOmniIdx,1}]),2));

        SemiOmniPDP=PDPdenoise(SemiOmniPDP,multipath_low_bound);
        
        [~,SeOmSPs]=findpeaks(SemiOmniPDP,"MinPeakDistance",80);
        nSeOmSPs=length(SeOmSPs);

        IdxRng = bsxfun(@plus, SeOmSPs, -39:+40);
        if (nSeOmSPs==1)
            SP_pwrs_SL=pow2db(sum(db2pow(SemiOmniPDP(IdxRng))));
        else
            SP_pwrs_SL=pow2db(sum(db2pow(SemiOmniPDP(IdxRng)),2));
        end
        

        SP_RefAngle_SL=zeros(nSeOmSPs,1);
        SP_AltAngle_SL=zeros(nSeOmSPs,1);
        SP_ZRefAngle_SL=zeros(nSeOmSPs,1);
        SP_ZAltAngle_SL=zeros(nSeOmSPs,1);
        

        for iSP=1:nSeOmSPs
            Angle_Mat=zeros(Nangles,1);
            for jAOA=1:Nangles
                Angle_PDP=PAS_set{allAngles==SLangles(jAOA),1};
                Angle_Mat(jAOA)=Angle_PDP(SeOmSPs(iSP),1);
            end
            [~,maxAOAidx]=max(Angle_Mat);
            SP_RefAngle_SL(iSP)=SLangles(maxAOAidx);
            % we now have assigned the angle from the PAS
            %next, we try to match the constituent direction for that angle
            %in the PAS.
            SP_PDP_group=PAS_set{allAngles==SP_RefAngle_SL(iSP),5};
            Altangles_grp=PAS_set{allAngles==SP_RefAngle_SL(iSP),4};
            ZRefangles_grp=PAS_set{allAngles==SP_RefAngle_SL(iSP),6};
            ZAltangles_grp=PAS_set{allAngles==SP_RefAngle_SL(iSP),7};
            DirPDPpwrs=zeros(length(SP_PDP_group),1);
            for kPDP=1:length(SP_PDP_group)
                DirPDPforAngle = [SP_PDP_group{kPDP,1}];
                DirPDPpwrs(kPDP)= DirPDPforAngle(SeOmSPs(iSP),1);
            end
            [~,assignIdx]=max(DirPDPpwrs);
            SP_AltAngle_SL(iSP)=Altangles_grp(assignIdx);
            SP_ZRefAngle_SL(iSP)=ZRefangles_grp(assignIdx);
            SP_ZAltAngle_SL(iSP)=ZAltangles_grp(assignIdx);
        end
        AllSPRefAngles(iLobe,1)={SP_RefAngle_SL};
        AllSPZRefAngles(iLobe,1)={SP_ZRefAngle_SL};
        AllSPZAltAngles(iLobe,1)={SP_ZAltAngle_SL};
        AllSPAltAngles(iLobe,1)={SP_AltAngle_SL};
        SP_idx(iLobe,1)={SeOmSPs};
        SP_pwr(iLobe,1)={SP_pwrs_SL};
    end
    AllSPRefAngles=[cell2mat(AllSPRefAngles)];
    AllSPZRefAngles=[cell2mat(AllSPZRefAngles)];
    AllSPZAltAngles=[cell2mat(AllSPZAltAngles)];
    AllSPAltAngles=[cell2mat(AllSPAltAngles)];
    SP_idx=[cell2mat(SP_idx)];
    SP_pwr=[cell2mat(SP_pwr)];

    %IMPORTANT!
    %This step merges subpaths arriving at the same exact time or within 40
    %samples of each other
    %This might cause SP angles count to be more than the total discernible
    %SPs. 
    %Shift left by 1. Check diff. merge those with small diff
%     SP_idxUniq=unique(SP_idx);
%     SP_pwrUniq=zeros(length(SP_idxUniq),1);
% 
%     for iSP=1:length(SP_idxUniq)
%         matchIdx=(SP_idx==SP_idxUniq(iSP)');
%         SP_pwrUniq(iSP)=pow2db(sum(db2pow(SP_pwr(matchIdx))));
%     end
%     SP_idx=SP_idxUniq;
%     SP_pwr=SP_pwrUniq;
end
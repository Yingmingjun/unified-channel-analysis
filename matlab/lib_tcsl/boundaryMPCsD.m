%The function determines the boundaries of the spatial lobe based on the
%SLT. It places two MPCs at boundary location with powers equal to the 
function [mpcP,mpcA,mpcZ,mpcZO]=boundaryMPCsD(PAS_set,PAS_angles,PAS_powers,starts,ends,SLT,aziPatternFile,elevPatternFile)
    Nlobe=length(starts);
    azi=aziPatternFile(:,2)-max(aziPatternFile(:,2));%normalizing Azi pattern for AS
    elev=elevPatternFile(:,2)-max(elevPatternFile(:,2));%normalizing Elev pattern for ZS
    mpcP=cell(Nlobe,1);
    mpcA=cell(Nlobe,1);
    mpcZ=cell(Nlobe,1);
    mpcZO=cell(Nlobe,1);
    for iLobe=1:Nlobe
        ref_power1=PAS_powers(PAS_angles==starts(iLobe));
        ref_power2=PAS_powers(PAS_angles==ends(iLobe));
        [~,Ang_pos]=min(abs(abs(ref_power1-SLT)-abs(azi)));
        mpc1_Ang=starts(iLobe)-abs(aziPatternFile(Ang_pos,1));
        [~,Ang_pos]=min(abs(abs(ref_power1-SLT)-abs(elev)));
        ZAngs=vertcat(PAS_set{:,6});
        [maxZAng,~]=max(ZAngs);
        mpc1_ZAng=maxZAng+abs(elevPatternFile(Ang_pos,1));
        mpc1_ZAngOffset=abs(elevPatternFile(Ang_pos,1));
        [~,Ang_pos]=min(abs(abs(ref_power2-SLT)-abs(azi)));
        mpc2_Ang=ends(iLobe)+abs(aziPatternFile(Ang_pos,1));
        [~,Ang_pos]=min(abs(abs(ref_power2-SLT)-abs(elev)));
        [minZAng,~]=min(ZAngs);
        mpc2_ZAng=minZAng-abs(elevPatternFile(Ang_pos,1));
        mpc2_ZAngOffset=abs(elevPatternFile(Ang_pos,1));
        mpcP(iLobe)={[SLT;SLT]};
        mpcA(iLobe)={[mpc1_Ang;mpc2_Ang]};
        mpcZ(iLobe)={[mpc1_ZAng;mpc2_ZAng]};
        mpcZO(iLobe)={[mpc1_ZAngOffset;mpc2_ZAngOffset]};
    end
    
end
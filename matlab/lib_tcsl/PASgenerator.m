%% PAS Generator %%%%%%%%%%%%%%%%%%%%%%%%%%%

function [PAS_angles,PAS_powers,PAS_set]=PASgenerator(TRpdpSet,RefColforPAS,AltCol,multipath_low_bound)
%RefColforPAS refers to the column in the cell array that contains the
%angles for which the PAS is being made
%e.g. for AOD_PAS pass the AOD column number
    Angles=unique(cell2mat(TRpdpSet(:,RefColforPAS)));

    PAS=zeros(length(Angles),2);
    PAS(:,2)=Angles;
    PAS_set=cell([length(Angles), 5]); 
    % AODpdp (sum of AOA PDPs for the AOD) | AOD power | AOD | AOAs | AOA pdps | ZODs | ZOAs |
    
    for i_Angles=1:length(Angles)
        Angleidx=(cell2mat(TRpdpSet(:,RefColforPAS))==Angles(i_Angles));
        Anglepdp=TRpdpSet(Angleidx,1);%Collection of directional pdps corresponding to the AOD/AOA
        PDPgroup=[Anglepdp{:}];
        NANcheckIdx=isnan(PDPgroup);
        PDPgroup(NANcheckIdx)=-200;
        for i_fix=1:width(PDPgroup)
            Anglepdp{i_fix,1}=PDPgroup(:,i_fix);
        end
        SubAngles=TRpdpSet(Angleidx,AltCol);
        SubZAltAngles=TRpdpSet(Angleidx,AltCol+1);
        SubZRefAngles=TRpdpSet(Angleidx,RefColforPAS+1);
        PAS_set{i_Angles,4}=cell2mat(SubAngles);
        PAS_set{i_Angles,6}=cell2mat(SubZRefAngles);
        PAS_set{i_Angles,7}=cell2mat(SubZAltAngles);
        PAS_set{i_Angles,5}=Anglepdp;
        
        Anglepdp=pow2db(sum(db2pow([Anglepdp{:}]),2));
        PAS(i_Angles,1)=pow2db(sum(db2pow(Anglepdp)));
        %AOD_PAS(i_AOD,1)=pow2db(sum(db2pow(AODpdp(AODpdp>multipath_low_bound))));
        PAS_set{i_Angles,1}=Anglepdp;
        PAS_set{i_Angles,2}=pow2db(sum(db2pow(Anglepdp)));
        PAS_set{i_Angles,3}=PAS(i_Angles,2);
    end
    
    %replace 0 angle with 360
    PAS(PAS(:,2)==0,2)=360;
    PAS=sortrows(PAS,2,"ascend");
    PAS_angles=(1:360)';
    PAS_powers=zeros(length(PAS_angles),1);
    idx=any(PAS_angles==PAS(:,2)',2);
    PAS_powers(idx)=PAS(:,1);
    PAS_powers(~idx)=multipath_low_bound;
    
end
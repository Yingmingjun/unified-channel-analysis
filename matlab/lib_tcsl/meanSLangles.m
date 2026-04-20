function [meanAngle,meanZAngle,members,SL_TotalPower]=meanSLangles(PAS_set,lobecount,lobewidths,ends,starts,PASangles,PASpowers)        
    meanAngle=zeros(lobecount,1);
    meanZAngle=zeros(lobecount,1);
    SL_TotalPower=zeros(lobecount,1);
    members=cell(lobecount,1);
    for iSL=1:lobecount
        if (starts(iSL)>ends(iSL))
            idx=(PASangles>=starts(iSL))|(PASangles<=ends(iSL));
        else
            idx=(PASangles>=starts(iSL))&(PASangles<=ends(iSL));
            if((starts(iSL)==ends(iSL))&&(lobewidths(iSL)==360))
                idx=(PASangles>=starts(iSL))|(PASangles<=ends(iSL));
            end
        end
        
        SLangles=PASangles(idx);
        SLpowers=db2pow(PASpowers(idx));
        Re=(SLpowers.*cos(deg2rad(SLangles)))./sum(SLpowers);
        Im=(SLpowers.*sin(deg2rad(SLangles)))./sum(SLpowers);
        Re=sum(Re);
        Im=sum(Im);
        meanAngle(iSL)=mod(rad2deg(atan2(Im,Re)),360);
        members(iSL)={SLangles};
        SL_TotalPower(iSL)=pow2db(sum(SLpowers));

        PASidx=any([PAS_set{:,3}]'==SLangles',2);
        SLZangles=vertcat(PAS_set{PASidx,6});
        SLZangles=reshape(SLZangles,[height(SLZangles)*width(SLZangles),1]);
        SLZpowers=vertcat(PAS_set{PASidx,5});
        SLZpowers=reshape(SLZpowers,[1,height(SLZpowers)*width(SLZpowers)]);
        SLZpowers=sum(db2pow(cell2mat(SLZpowers)),1)';
        Re=(SLZpowers.*cos(deg2rad(SLZangles)))./sum(SLZpowers);
        Im=(SLZpowers.*sin(deg2rad(SLZangles)))./sum(SLZpowers);
        Re=sum(Re);
        Im=sum(Im);
        meanZAngle(iSL)=rad2deg(atan2(Im,Re));
    end
end
%% Angular Spread %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function AS=angularSpread(lobeCount,lobeWidths,ends,starts,PAS_angles,PAS_powers,varargin)
    globalAS=false;

    if(~isempty(varargin))
      if(string(varargin(1))=="Global")
        globalAS=cell2mat(varargin(2));
      end
    end
    
    %Lobe refill
    Angles=(1:360)';
    Powers=-100.*ones(size(Angles));
    if((PAS_angles(1)~=0)&&(PAS_angles(end)~=359))
        fillPowers=linspace(PAS_powers(end),PAS_powers(1),360-PAS_angles(end)+PAS_angles(1)+1);
        Powers(1:PAS_angles(1))=fillPowers(length(fillPowers)-PAS_angles(1)+1:end);
        Powers(PAS_angles(end):end)=fillPowers(1:length(fillPowers)-PAS_angles(1));
    end
    if(PAS_angles(end)==360)
        Powers(end)=PAS_powers(end);
    end
    for iPAS=1:length(PAS_angles)-1
        if(PAS_angles(iPAS+1)-PAS_angles(iPAS)~=1)
            Powers(PAS_angles(iPAS):PAS_angles(iPAS+1))=linspace(PAS_powers(iPAS),PAS_powers(iPAS+1),PAS_angles(iPAS+1)-PAS_angles(iPAS)+1);
        else
            Powers(PAS_angles(iPAS))=PAS_powers(iPAS);
        end
    end


    starts(starts==360)=0;
    if(globalAS)
        idx=(Powers>-100);
        powers=Powers(idx);
        angles=Angles(idx);
        AS=sqrt(-2.*log(abs(sum(exp(1i.*deg2rad(angles)).*db2pow(powers))./sum(db2pow(powers),'all'))));
    else
        AS=zeros(lobeCount,1);
        for iLobe=1:lobeCount
            if (starts(iLobe)>ends(iLobe))
                idx=(Angles>=starts(iLobe))|(Angles<=ends(iLobe));
            else
                idx=(Angles>=starts(iLobe))&(Angles<=ends(iLobe));
            end
            
            angles=Angles(idx);
            if (mod(ends(iLobe)-starts(iLobe),360)~=lobeWidths(iLobe))
                disp('Lobe inconsistency. Please check');
                break;
            end
            powers=Powers(idx);
            AS(iLobe)=sqrt(-2.*log(abs(sum(exp(1i.*deg2rad(angles)).*db2pow(powers))./sum(db2pow(powers),'all'))));
        end
    end
    %from: Technical Specification Group Radio Access Network; Study on Channel
    % Model for Frequencies From 0.5 to 100 GHz (Release 16), document TR
    % 38.901 V16.0.0, 3GPP, Oct. 2019. Appendix A
end
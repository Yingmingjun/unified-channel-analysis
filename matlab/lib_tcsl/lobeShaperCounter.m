%% Lobe Shaper and Counter %%%%%%%%%%%%%%%%%%%%%
% For 142 GHz outdoor we require shaping the lobes as well.
% The reason being the AODs are not necessarily eight degrees apart. The
% consistency of eight degrees is maintained for AOAs due to the automated
% recording process

function [lobeCount,lobeWidths,ends,starts,PAS_angles,PAS_powers]=lobeShaperCounter(multipath_low_bound,PAS_angles,PAS_powers,varargin)
    Thres=-500;
    HPBW=8;

    if(~isempty(varargin))
      idx=find(string(varargin)=="Threshold");
      if(~isempty(idx))
        Thres=cell2mat(varargin(idx+1));
      end

      idx=find(string(varargin)=="HPBW");
      if(~isempty(idx))
        HPBW=cell2mat(varargin(idx+1));
      end
    end

    pwr_idx=(PAS_powers>multipath_low_bound);
    
    if (Thres>-500)
      pwr_idx=pwr_idx&(PAS_powers>Thres);
    end

   ref_angles=PAS_angles(pwr_idx);
   %if(ref_angles(end)==360)
        %ref_angles(end)=0;
        %ref_angles=circshift(ref_angles,1);
   %end
   Nref=length(ref_angles);

   lobeCount=1;
   lobeWidths=zeros(Nref,1);
   starts=-1*ones(Nref,1);
   ends=-1*ones(Nref,1);
   starts(1)=ref_angles(1);
   ends(end)=ref_angles(end);

   if (Nref==1)
       lobeCount=1;
       lobeWidths=0;
       ends=ref_angles(1);
       return;
   end

   gap2last=mod(ref_angles(1)-ref_angles(end),360);
   if (gap2last<=HPBW)
       lobeWidths(lobeCount)=lobeWidths(lobeCount)+gap2last;
       PAS_angles(1:ref_angles(1)-1)=-1;
       PAS_angles(ref_angles(end)+1:end)=-1;
       starts(1)=ref_angles(end);
       ends(end)=ref_angles(end-1);
       Nref=Nref-1;
       if ((ref_angles(end)-ref_angles(Nref))<=HPBW)
            Nref=Nref+1;
            ends(end)=-1;
       end
   end

   for iRef=2:Nref
       gap2last=mod(ref_angles(iRef)-ref_angles(iRef-1),360);
        if(gap2last<=HPBW)
            lobeWidths(lobeCount)=lobeWidths(lobeCount)+gap2last;
            PAS_angles(ref_angles(iRef-1)+1:ref_angles(iRef)-1)=-1;
            %PAS_powers(ref_angles(iRef-1):ref_angles(iRef))=-500;
            if(iRef==Nref)
                ends(lobeCount+1)=ref_angles(iRef);
            end
        else
            ends(lobeCount)=ref_angles(iRef-1);
            lobeCount=lobeCount+1;
            starts(lobeCount)=ref_angles(iRef);
        end
   end

   idx=(PAS_angles>-1);
   PAS_angles=PAS_angles(idx);
   PAS_powers=PAS_powers(idx);
   starts=starts(starts>-1);
   ends=ends(ends>-1);
   if(length(ends)>=2)
       if (ends(end)==ends(end-1))
           ends=ends(1:end-1);
       end
   end
   lobeWidths=lobeWidths(1:length(starts));

end
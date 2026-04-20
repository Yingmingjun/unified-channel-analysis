%% Lobe Shaper and Counter %%%%%%%%%%%%%%%%%%%%%
% For 142 GHz outdoor we require shaping the lobes as well.
% The reason being the AODs are not necessarily eight degrees apart. The
% consistency of eight degrees is maintained for AOAs due to the automated
% recording process. Do NOT use LobeShaperCounterD for 142 GHz outdoor.

%The D in the function stands for discrete. Using this function taking
%only the PAS points from the measurements and discarding the interpolated
%points

%Naturally, HPBW is extremely critical here.

function [lobeCount,lobeWidths,ends,starts,PAS_angles,PAS_powers]=lobeShaperCounterD(multipath_low_bound,PAS_set,varargin)
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
    
   ref_angles=[PAS_set{:,3}]';
   ref_powers=[PAS_set{:,2}]';

   pwr_idx=(ref_powers>Thres);

   ref_angles=ref_angles(pwr_idx);
   ref_powers=ref_powers(pwr_idx);

   [ref_angles,srtidx]=sort(ref_angles,'ascend');
   ref_powers=ref_powers(srtidx);

   Nref=length(ref_angles);

   %lobeCount=1;
   %lobeWidths=zeros(Nref,1);
   starts=-1*ones(Nref,1);
   ends=-1*ones(Nref,1);
   starts(1)=ref_angles(1);
   ends(end)=ref_angles(end);

   if (Nref==1)
       lobeCount=1;
       lobeWidths=0;
       starts=ref_angles(1);
       ends=ref_angles(1);
       PAS_angles=ref_angles;
       PAS_powers=ref_powers;
       return;
   end

   ref_angles_A=[ref_angles; ref_angles(1)];
   ref_angles_B=[ref_angles(1); ref_angles];
   diffs=mod(ref_angles_A-ref_angles_B,360);
   Ndiff=length(diffs);

   lobeCount=sum(diffs>HPBW)+1;

   lobeWidths=-1.*ones(lobeCount,1);
   lobeWidthMultiplier=1;
   lobeTrack=1;
   for iLobe=2:Ndiff
        if(diffs(iLobe)>HPBW)
            lobeWidths(lobeTrack)=(lobeWidthMultiplier-1)*HPBW;
            ends(lobeTrack)=starts(lobeTrack)+lobeWidths(lobeTrack);
            lobeWidthMultiplier=1;
            lobeTrack=lobeTrack+1;
            starts(lobeTrack)=ref_angles_A(iLobe);
        else
            lobeWidthMultiplier=lobeWidthMultiplier+1; 
        end
   end

   lobeWidths=lobeWidths(lobeWidths>-1);
   Nlobe=length(lobeWidths);
   %For when the lobe segment extends upto the last pointing direction
   if(Nlobe<lobeTrack)
    lobeWidths=[lobeWidths;(lobeWidthMultiplier-1)*HPBW];
    Nlobe=Nlobe+1;
   end
   
   starts=starts(starts>-1);
   ends=ends(ends>-1);

   

   %For stitching lobes when the last lobe is continuous beyond 360
   %degrees
   if (Nlobe>0)
       if ((lobeWidths(end)>=HPBW)&&((diffs(2)==HPBW)||ref_angles(1)<=HPBW)&&((360-ref_angles(end))<=HPBW))
            lobeCount=lobeCount-1;
            lobeWidths(1)=lobeWidths(end)+lobeWidths(1);
            lobeWidths=lobeWidths(1:lobeCount);
            starts=starts(2:end);
            ends=ends(1:length(ends)-1);
            ends=circshift(ends,-1);
       end
   end
   %For when the lobe is continuous with all directions having power
   if((lobeWidthMultiplier>(360/HPBW))&&(lobeCount==1))
        lobeWidths=360;
        starts=0;
        ends=360;
   end

   %For when the last lobe segment doesn't reach up to 360 and 0 spread
   %lobes
   
   if(any(sum(starts==starts',2)>1))
       idx=1:Nlobe;
       idx=max(idx(sum(starts==starts',2)>1));
       %edge case when the start and end arrays end up enequal
       if(length(starts)~=length(ends))
            if(length(starts)>length(ends))
                ends=[ends;ends(end)];
            else
                starts=[starts;starts(1)];
            end
       end
       if ((idx==Nlobe)&&(starts(idx)~=ends(idx)))
           lobeCount=lobeCount-1;
           lobeWidths=lobeWidths(1:Nlobe-1);
           starts=starts(1:Nlobe-1);
           ends=ends(1:Nlobe-1);
       end
   end

   % if(any(lobeWidths==0))
   %  lobeCount=lobeCount-1;
   %  lobeWidths=lobeWidths(lobeWidths~=0);
   %  starts=starts(lobeWidths~=0);
   %  ends=ends(lobeWidths~=0);
   % end


   PAS_angles=ref_angles;
   PAS_powers=ref_powers;


end
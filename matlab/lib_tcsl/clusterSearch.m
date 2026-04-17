%% Cluster Search %%%%%%%%%%%%%%%%%%%%%%%%
function [TCs,TCstart,TCstop,TCxsDelay,Nsp,iraClXsDly,SPpwrs,ierClXsDly]=clusterSearch(PDP,multipath_low_bound,MTI)
    TCs=1;

    PDPidcs=(1:length(PDP))';    
    power_idcs=PDPidcs(PDP>multipath_low_bound);
    if(isempty(power_idcs))
        TCxsDelay=[];
        TCstart=[];
        TCstop=[];
        TCs=0;
        Nsp=0;
        
        iraClXsDly=[];
        ierClXsDly=[];
        SPpwrs=[];
        return;
    end
    % removing very small spikes above the threshold
    power_idcs_L=[power_idcs(1); power_idcs(1:end-1)]; %the indexes of points above
                                 % the threshold shifted to the left by 1
    %power_idcs_R=[power_idcs(2:end); power_idcs(end)];
    width_chk_idxL=power_idcs-power_idcs_L; % values greater than one indicate 
                        % the end of the peak and the width of the peak
                        % that ended
    %width_chk_idxR=power_idcs-power_idcs_R;
    width_maskStart=(width_chk_idxL>1);
    peakStart=power_idcs(width_maskStart);
    peakStop=peakStart-width_chk_idxL(width_maskStart);
    peakStart=[power_idcs(1) ; peakStart(1:end)];
    peakStop=[peakStop(1:end); power_idcs(end)];
    peakWidthsMask=(peakStop-peakStart)<=20; %dsicard peaks that are less than 1 ns (20 samples) wide 
    peakStart=peakStart(~peakWidthsMask);
    peakStop=peakStop(~peakWidthsMask);
    
    Nmax=length(peakStart);

    if (Nmax==0)
        TCxsDelay=[];
        TCstart=[];
        TCstop=[];
        TCs=0;
        Nsp=0;
        
        iraClXsDly=[];
        ierClXsDly=[];
        SPpwrs=[];
        return;
    end

    TCstart=zeros(Nmax,1);
    TCstop=zeros(Nmax,1);
    
    TCstart(1)=peakStart(1);
    TCstop(end)=peakStop(end);
    

    if (Nmax==1)
        TCxsDelay=0;
        [~,Allpkidcs]=findpeaks(PDP,"MinPeakDistance",80);
        pkidcs=Allpkidcs((Allpkidcs>=TCstart)&(Allpkidcs<=TCstop));
        Nsp=length(pkidcs);
        iraClXsDly={(pkidcs-pkidcs(1))./20};
        ierClXsDly=[];
        IdxRng = bsxfun(@plus, pkidcs, -39:+40);% create a range array of 40 samples around each pk index
        % The result of PDP(IdxRng) is oriented as a column vector if there
        % is only one peak. For multiple peaks PDP(IdxRng) is a collection
        % of row vectors arranged as a 2D array.
        if (length(pkidcs)==1)
            SPpwrs={pow2db(sum(db2pow(PDP(IdxRng))))};
        else
            SPpwrs={pow2db(sum(db2pow(PDP(IdxRng)),2))};
        end
        return;
    end

    for iClst=2:Nmax
        voidInterval=peakStart(iClst)-peakStop(iClst-1);
        if (voidInterval>=MTI*20) % 1ns is 20 samples 
            TCstop(iClst-1)=peakStop(iClst-1);
            TCstart(iClst)=peakStart(iClst);
            TCs=TCs+1;
        end
    end
    TCstart=TCstart(TCstart~=0);
    TCstop=TCstop(TCstop~=0);

    iraClXsDly=cell([length(TCstart) 1]);
    SPpwrs=cell([length(TCstart) 1]);
    ierClXsDly=zeros(length(TCstart)-1,1);

    %Find the subpath in each cluster
    Nsp=zeros(length(TCstart),1);
    TCpwrs=zeros(length(TCstart),1);
    [~,Allpkidcs]=findpeaks(PDP,"MinPeakDistance",80);

    TCxsDelay=TCstart-Allpkidcs(1);%%check here % Cluster excess delays based on definitions in
    %S. Ju, Y. Xing, O. Kanhere and T. S. Rappaport, "Millimeter Wave and Sub-Terahertz Spatial 
    %       Statistical Channel Model for an Indoor Office Building," in IEEE Journal on Selected Areas 
    %       in Communications, vol. 39, no. 6, pp. 1561-1575, June 2021, doi: 10.1109/JSAC.2021.3071844.
    TCxsDelay(1)= 0; %The start of the first TC would precede the first subpath peak

    for iClstSp=1:length(TCstart)
        %[~,pkidcs]=findpeaks(PDP(TCstart(iClstSp):TCstop(iClstSp)),"MinPeakDistance",80);
        if (iClstSp>1)
            lastSPinPrevCl=pkidcs(end);
        end
        pkidcs=Allpkidcs((Allpkidcs>=TCstart(iClstSp))&(Allpkidcs<TCstop(iClstSp)));
        %pkidcs may be empty as 'findpeaks' may turn out peaks that
        %survived power thresholding but are below multipath low bound
        %supplied here. However, the pkstart and pkstop will cut off based
        %on multipath low bound and pks higher than the low bound will
        %survive. findpeaks might not agree with this due to prominence of
        %peaks compared to neighbors.
        if(~isempty(pkidcs))
            Nsp(iClstSp)=length(pkidcs);
            iraClXsDly(iClstSp,1)={(pkidcs-pkidcs(1))};
            if (iClstSp>1)
                ierClXsDly(iClstSp-1,1)=pkidcs(1)-lastSPinPrevCl;
            end
            TCpwrs(iClstSp)=pow2db(sum(db2pow(PDP(TCstart(iClstSp):TCstop(iClstSp)))));
            IdxRng = bsxfun(@plus, pkidcs, -39:+40);% create a range array of 40 samples around each pk index
            % The result of PDP(IdxRng) is oriented as a column vector if there
            % is only one peak. For multiple peaks PDP(IdxRng) is a collection
            % of row vectors arranged as a 2D array.
            if (length(pkidcs)==1)
                SPpwrs(iClstSp,1)={pow2db(sum(db2pow(PDP(IdxRng))))};
            else
                SPpwrs(iClstSp,1)={pow2db(sum(db2pow(PDP(IdxRng)),2))};
            end
        else
            Nsp(iClstSp)=1;
            iraClXsDly(iClstSp,1)={0};
            TCpwrs(iClstSp)=multipath_low_bound;
            SPpwrs(iClstSp,1)={multipath_low_bound};
            pkidcs=TCstop(iClstSp);
        end
        
    end

end
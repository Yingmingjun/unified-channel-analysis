clear variables;
close all;
tic

% root_path=['C:\Users\Dipankar Shakya\Documents\' ...
%     'Desktop Work Station 2020\NYU_Wireless_Lab\Channel sounder\' ...
%     '142GHzMeasurementsCode-UMi_rev\'];

root_path=['G:\Other computers\HP\Desktop Work Station 2020\NYU_Wireless_Lab\' ...
    'Channel sounder\142GHzMeasurementsCode-UMi_rev\'];

Adata_path="2.Alignment\Aligned\142 GHz\142GHz*";

elevPatternFile = importdata('AntennaPattern\HPLANE Pattern Data 261D-27.dat');
aziPatternFile = importdata('AntennaPattern\EPLANE Pattern Data 261D-27.dat');

multipath_low_bound=-100;
thres_below_pk=25;
MTI=25;% Minimum void time interval in ns
HPBW=8;% Antenna HPBW
RXAntGain=27; % Antenna Gain
TXAntGain=27; % Antenna Gain

%Based on M. K. Samimi and T. S. Rappaport, "3-D Millimeter-Wave Statistical
%       Channel Model for 5G Wireless System Design," in IEEE Transactions 
%       on Microwave Theory and Techniques, vol. 64, no. 7, pp. 2207-2225, 
%       July 2016, doi: 10.1109/TMTT.2016.2574851. 

%Track over the T-R location combinations
rootDir=dir(strcat(root_path,Adata_path));
rootDir=rootDir(~ismember({rootDir.name},{'.','..'}));
TR_str=string(natsortfiles({rootDir.name}))';
nTR=length(TR_str);

statTable=cell([nTR 45]); 
% 1. OmniPDP | 2. AOD lobe count | 3. AOD AS | 4. AOD global AS | 
% 5. AOA lobe count | 6. AOA AS | 7. AOA global AS | 8. # of TCs | 
% 9. TCstart index | 10. TCstop index | 11. TC excess Delay | 
% 12. # of SubPaths | 13. Intra-Cluster excess Delay | 14. SP powers | 
% 15. Inter-Cluster Delay | 16. SP idcs | 17. SP AOA in lobe | 18. SP AOD in lobe | 
% 19. SP ZOA in lobe | 20. SP ZOD in lobe | 21. mean AOA SL angles | 
% 22. mean AOD SL angles | 23. mean ZOA SL angles | 24. mean ZOD SL angles | 
% 25. Environment | 26. AOA SL powers | 27. AOD SL powers | 28. SP AOA | 
% 29. SP AOD | 30. SP ZOA | 31. SP ZOD | 32. # AOA SLs | 
% 33. AOA SL angles | 34. # AOD SLs | 35. AOD SL angles | 36. Dir RMS DS
% |37. AOA PAS SL boundary powers | 38. AOA PAS SL boundary Azimuth | 
% 39. AOA PAS SL boundary Elevation | 40. AOA PAS SL boundary Elevation Offsets |
% 41. AOD PAS SL boundary powers | 42. AOD PAS SL boundary Azimuth | 
% 43. AOA PAS SL boubdary Elevation | 44. AOA PAS SL boundary Elevation Offsets |
% 45. TX-RX ID |

%% %Steps 3 and beyond %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for iTR=1:nTR
    TXid=sscanf(TR_str(iTR),"142GHz_Outdoor_T%d-R%d*.mat");
    RXid=TXid(2);
    TXid=TXid(1);
    TRpdpSet=load(strcat(rootDir(1).folder,'\',TR_str(iTR)));
    TRpdpSet=struct2cell(TRpdpSet);
    TRpdpSet=TRpdpSet{1,1}; %The current naming convention Dipankar used in saving variables.

    %Cell array Structure of Aligned PDP set
        %|1. Denoised PDP|2. TX_ID|3. RX_ID|4. Meas #|5. Rot #|
        %|6. AOD Azimuth|7. AOD Elevation|8. AOA Azimuth|9. AOA Elevation|
        %|10.  Power_Rx_aft_ant (Pr)|11. pkIdx| 12. Propagation delay|
        %|13. Environment|
    Env=TRpdpSet{1,10};
    %AOA PAS
    [AOA_PAS_angles0, AOA_PAS_powers0, AOA_PAS_set]=PASgenerator(TRpdpSet,8,6,multipath_low_bound);
    [Thres10,mPos]=max(AOA_PAS_powers0);
    Thres10=Thres10-10;
    Thres20=Thres10-10;
    
    %[~,]min(abs(Thres10-Pintp))
    [AOAlobeCountNoTh,AOAlobeWidthsNoTh,AOAendsNoTh,AOAstartsNoTh,AOA_PAS_anglesNoTh,AOA_PAS_powersNoTh]=lobeShaperCounter(multipath_low_bound, AOA_PAS_angles0, AOA_PAS_powers0,'HPBW',HPBW);
    %[AOAlobeCountNoTh,AOAlobeWidthsNoTh,AOAendsNoTh,AOAstartsNoTh,AOA_PAS_anglesNoTh,AOA_PAS_powersNoTh]=lobeShaperCounterD(multipath_low_bound, AOA_PAS_set,'HPBW',HPBW);
    PASplotter(AOA_PAS_anglesNoTh,AOA_PAS_powersNoTh-RXAntGain,'Threshold',Thres10-RXAntGain);
    hold on;
    [~,shift]=max(AOA_PAS_powers0);
    aziA=[(-180:-91)';aziPatternFile(:,1);(91:180)'];
    aziP=[-100.*ones(90,1);aziPatternFile(:,2);-100.*ones(90,1)];
    azi=[aziA,aziP];
    polarplot(deg2rad(azi(:,1)+shift),(azi(:,2)-max(azi(:,2))+max(AOA_PAS_powersNoTh-RXAntGain)));
    hold off;
    [AOAlobeCount,AOAlobeWidths,AOAends,AOAstarts,AOA_PAS_angles,AOA_PAS_powers]=lobeShaperCounterD(multipath_low_bound, AOA_PAS_set,'Threshold',Thres10,'HPBW',HPBW);
    %[AOAlobeCount,AOAlobeWidths,AOAends,AOAstarts,AOA_PAS_angles,AOA_PAS_powers]=lobeShaperCounter(multipath_low_bound, AOA_PAS_angles0, AOA_PAS_powers0,'Threshold',Thres10,'HPBW',HPBW);
    %modify/create lobeCounter for thresholding. 10 dB/ 20 dB below peak.
    
    AOAs=[AOA_PAS_set{:,3}];
    if (sum(mod(AOAstarts,360)>AOAends)==0)
        AOAspThMask=sum(((AOAs'>=mod(AOAstarts,360)')&(AOAs'<=AOAends')),2)>0;
    else
        tempStarts=AOAstarts(mod(AOAstarts,360)>AOAends);
        tempEnds=AOAends(mod(AOAstarts,360)>AOAends);
        AOAspThMask=(AOAs'>=mod(tempStarts,360)')|(AOAs'<=tempEnds')|(sum(((AOAs'>=mod(AOAstarts,360)')&(AOAs'<=AOAends')),2)>0);
    end
    AOA_PAS_set_spTh=AOA_PAS_set(AOAspThMask,:);
    [AOA_boundaryMpcP,AOA_boundaryMpcA,AOA_boundaryMpcZ,AOA_boundaryMpcZOfs]=boundaryMPCsD(AOA_PAS_set_spTh,AOA_PAS_angles,AOA_PAS_powers,AOAstarts,AOAends,Thres10,aziPatternFile,elevPatternFile); %Open function for description
   
    
    AS_AOA=compute_angular_spread([AOA_PAS_set_spTh{:,3}]',[AOA_PAS_set_spTh{:,2}]','deg','deg');
    ASglobal_AOA=compute_angular_spread(AOA_PAS_angles,AOA_PAS_powers,'deg','deg');
    dirRMSDS=getdirRMSDS(AOA_PAS_set); %change this to MPC wise processing %Done at the end
    % lets replace with computeDirDS function using antenna pattern
    %for this we need to build an MPC array
    OmniPDP1=pow2db(sum(db2pow([AOA_PAS_set{:,1}]-RXAntGain),2));%Remove ant gain
    OmniPDP1_spTh=pow2db(sum(db2pow([AOA_PAS_set_spTh{:,1}]-RXAntGain),2));% sp=spatial thresholded

    %AOD PAS
    [AOD_PAS_angles0, AOD_PAS_powers0, AOD_PAS_set]=PASgenerator(TRpdpSet,6,8,multipath_low_bound);
    [Thres10,mPos]=max(AOD_PAS_powers0);
    Thres10=Thres10-10;
    Thres20=Thres10-10;
    [AODlobeCountNoTh,AODlobeWidthsNoTh,AODendsNoTh,AODstartsNoTh,AOD_PAS_anglesNoTh,AOD_PAS_powersNoTh]=lobeShaperCounter(multipath_low_bound, AOD_PAS_angles0, AOD_PAS_powers0,'HPBW',HPBW);
    PASplotter(AOD_PAS_anglesNoTh,AOD_PAS_powersNoTh-TXAntGain,'Threshold',Thres10-TXAntGain);
    hold on;
    [~,shift]=max(AOD_PAS_powers0);
    aziA=[(-180:-91)';aziPatternFile(:,1);(91:180)'];
    aziP=[-100.*ones(90,1);aziPatternFile(:,2);-100.*ones(90,1)];
    azi=[aziA,aziP];
    polarplot(deg2rad(azi(:,1)+shift),(azi(:,2)-max(azi(:,2))+max(AOD_PAS_powersNoTh-RXAntGain)));
    hold off;
    
    %For 142 GHz outdoor use the lobeShaperCounter as the lobes need
    %shaping. AODs are not necessarily at HPBW separations.
    %[AODlobeCount,AODlobeWidths,AODends,AODstarts,AOD_PAS_angles,AOD_PAS_powers]=lobeShaperCounterD(multipath_low_bound, AOD_PAS_set,'Threshold',Thres10,'HPBW',HPBW);
    [AODlobeCount,AODlobeWidths,AODends,AODstarts,AOD_PAS_angles,AOD_PAS_powers]=lobeShaperCounter(multipath_low_bound, AOD_PAS_angles0, AOD_PAS_powers0,'Threshold',Thres10,'HPBW',HPBW);
    
    AODs=[AOD_PAS_set{:,3}];
    if (sum(mod(AODstarts,360)>AODends)==0)
        AODspThMask=sum(((AODs'>=mod(AODstarts,360)')&(AODs'<=AODends')),2)>0;
    else
        tempStarts=AODstarts(mod(AODstarts,360)>AODends);
        tempEnds=AODends(mod(AODstarts,360)>AODends);
        AODspThMask=(AODs'>=mod(tempStarts,360)')|(AODs'<=tempEnds')|(sum(((AODs'>=mod(AODstarts,360)')&(AODs'<=AODends')),2)>0);
    end
    AOD_PAS_set_spTh=AOD_PAS_set(AODspThMask,:);
    [AOD_boundaryMpcP,AOD_boundaryMpcA,AOD_boundaryMpcZ,AOD_boundaryMpcZOfs]=boundaryMPCsD(AOD_PAS_set_spTh,AOD_PAS_angles,AOD_PAS_powers,AODstarts,AODends,Thres10,aziPatternFile,elevPatternFile); %Open function for description
    
    %modify/create lobeCounter for thresholding. 10 dB/ 20 dB below peak.
    %AS_AOD=compute_angular_spread([AOD_PAS_set_spTh{:,3}]',[AOD_PAS_set_spTh{:,2}]','deg','deg');
    AS_AOD=AS_PAS(AOD_PAS_angles0, AOD_PAS_powers0, Thres10);
    ASglobal_AOD=compute_angular_spread(AOD_PAS_angles,AOD_PAS_powers,'deg','deg');
    %AS_AOD=angularSpread(AODlobeCount,AODlobeWidths,AODends,AODstarts,AOD_PAS_angles,AOD_PAS_powers);
    %ASglobal_AOD=angularSpread(AODlobeCount,AODlobeWidths,AODends,AODstarts,AOD_PAS_angles,AOD_PAS_powers,"Global",true);

    OmniPDP=pow2db(sum(db2pow([AOD_PAS_set{:,1}]-RXAntGain),2));


    [TCs,TCstart,TCstop,TCxsDelay,Nsp,iraClXsDly,SPpwrs,ierClXsDly]=clusterSearch(OmniPDP1_spTh,multipath_low_bound,MTI);

    [meanAOAangles,meanZOAangles,AOALobeAngles,AOALobePowers]=meanSLangles(AOA_PAS_set_spTh,AOAlobeCount,AOAlobeWidths,AOAends,AOAstarts,AOA_PAS_angles,AOA_PAS_powers);
    [meanAODangles,meanZODangles,AODLobeAngles,AODLobePowers]=meanSLangles(AOD_PAS_set_spTh,AODlobeCount,AODlobeWidths,AODends,AODstarts,AOD_PAS_angles,AOD_PAS_powers);
    %go lobewise to obtain angles of each SP. Using AOA PAS
    [SP_AOA,SP_ZOA,SP_ZOD,SP_AOD,SP_idx,SP_pwr]=SubPathPwrDirs(AOA_PAS_set,AOAlobeCount,AOAlobeWidths,AOAends,AOAstarts,AOA_PAS_angles,multipath_low_bound);
    
    SP_AOAnoMean=zeros(size(SP_AOA));
    SP_AODnoMean=zeros(size(SP_AOD));
    SP_ZOAnoMean=zeros(size(SP_ZOA));
    SP_ZODnoMean=zeros(size(SP_ZOD));

    for iAng=1:length(SP_AOA)
         for iSL=1:height(AOALobeAngles)
            if(ismember(SP_AOA(iAng), AOALobeAngles{iSL,1}))
                SP_AOAnoMean(iAng)=SP_AOA(iAng)-meanAOAangles(iSL);
                SP_ZOAnoMean(iAng)=SP_ZOA(iAng)-meanZOAangles(iSL);
                break;
            end
         end
    end

    for iAng=1:length(SP_AOD)
         for iSL=1:height(AODLobeAngles)
            if(ismember(SP_AOD(iAng),AODLobeAngles{iSL,1}))
                SP_AODnoMean(iAng)=SP_AOD(iAng)-meanAODangles(iSL);
                SP_ZODnoMean(iAng)=SP_ZOD(iAng)-meanZODangles(iSL);
                break;
            end
         end
    end

    % here we rely on Nsp2 as omni will combine MPCs from all directions.
    % This might result in MPCs coming from different directions but
    % falling in same time bin be ignored. The MPCs are thus undercounted.
    % Nsp2 relies on peaks counted in semiOmni or lobe PDPs
    SP_idx=sort(SP_idx,'ascend');
    Nsp2=zeros(TCs,1);% no. of SP in a cluster
    SP_pwr_sub=-500*ones(size(SP_idx));
    SP_idx_sub=-500*ones(size(SP_idx));
    SP_AOA_nm_sub=-500*ones(size(SP_idx));
    SP_AOD_nm_sub=-500*ones(size(SP_idx));
    SP_ZOA_nm_sub=-500*ones(size(SP_idx));
    SP_ZOD_nm_sub=-500*ones(size(SP_idx));
    iraClXsDly2=cell(TCs,1);
    ierClXsDly2=zeros(TCs-1,1);
    b=1;
    e=1;

    for iTC=1:TCs
        TCmask=(SP_idx>=TCstart(iTC))&(SP_idx<=TCstop(iTC));
        pkIdcs=SP_idx(TCmask);
        Nsp2(iTC)=length(pkIdcs);
        e=b+Nsp2(iTC)-1;
        SP_pwr_sub(b:e)=SP_pwr(TCmask);
        SP_idx_sub(b:e)=pkIdcs;
        SP_AOA_nm_sub(b:e)=SP_AOAnoMean(TCmask);
        SP_AOD_nm_sub(b:e)=SP_AODnoMean(TCmask);
        SP_ZOA_nm_sub(b:e)=SP_ZOAnoMean(TCmask);
        SP_ZOD_nm_sub(b:e)=SP_ZODnoMean(TCmask);
        b=e+1;
        if (iTC>1)
            ierClXsDly2(iTC-1,1)=(pkIdcs(1)-lastSPinPrevCl);
        end
        iraClXsDly2(iTC)={(pkIdcs-pkIdcs(1))};
        lastSPinPrevCl=pkIdcs(end);
    end
    SP_pwr_sub=SP_pwr_sub(SP_pwr_sub~=-500);
    SP_idx_sub=SP_idx_sub(SP_idx_sub~=-500);
    SP_AOA_nm_sub=SP_AOA_nm_sub(SP_AOA_nm_sub~=-500);
    SP_AOD_nm_sub=SP_AOD_nm_sub(SP_AOD_nm_sub~=-500);
    SP_ZOA_nm_sub=SP_ZOA_nm_sub(SP_ZOA_nm_sub~=-500);
    SP_ZOD_nm_sub=SP_ZOD_nm_sub(SP_ZOD_nm_sub~=-500);

    SP_AOA=SP_AOA(SP_pwr_sub~=-500);
    SP_AOD=SP_AOD(SP_pwr_sub~=-500);
    SP_ZOA=SP_ZOA(SP_pwr_sub~=-500);
    SP_ZOD=SP_ZOD(SP_pwr_sub~=-500);

    %Get RMS DS MPC-wise approach
    dirRMSDS_2 = zeros(size(SP_idx_sub,1),1);
    array_temp=[SP_idx_sub./20 SP_pwr_sub SP_AOA SP_ZOA SP_AOD SP_ZOD];
    for j = 1:size(SP_idx_sub,1)
        dirRMSDS_2(j) = computeDirDS(array_temp,array_temp(j,3:6),...
                aziPatternFile,elevPatternFile,thres_below_pk);
    end
    
    statTable{iTR,1} = OmniPDP1_spTh;
    statTable{iTR,2} = AODlobeCount;
    statTable{iTR,3} = AS_AOD;
    statTable{iTR,4} = ASglobal_AOD;
    statTable{iTR,5} = AOAlobeCount;
    statTable{iTR,6} = AS_AOA;
    statTable{iTR,7} = ASglobal_AOA;
    statTable{iTR,8} = TCs;
    statTable{iTR,9} = TCstart;
    statTable{iTR,10} = TCstop;
    statTable{iTR,11} = TCxsDelay;
    statTable{iTR,12} = Nsp2;
    statTable{iTR,13} = iraClXsDly2;
    statTable{iTR,14} = SP_pwr_sub;
    statTable{iTR,15} = ierClXsDly2;
    statTable{iTR,16} = SP_idx_sub;
    statTable{iTR,17} = SP_AOA_nm_sub;
    statTable{iTR,18} = SP_AOD_nm_sub;
    statTable{iTR,19} = SP_ZOA_nm_sub;
    statTable{iTR,20} = SP_ZOD_nm_sub;
    statTable{iTR,21} = meanAOAangles;
    statTable{iTR,22} = meanAODangles;
    statTable{iTR,23} = meanZOAangles;
    statTable{iTR,24} = meanZODangles;
    statTable{iTR,25} = Env;
    statTable{iTR,26} = AOALobePowers;
    statTable{iTR,27} = AODLobePowers;
    statTable{iTR,28} = mod(SP_AOA,360);
    statTable{iTR,29} = mod(SP_AOD,360);
    statTable{iTR,30} = SP_ZOA;
    statTable{iTR,31} = SP_ZOD;
    statTable{iTR,32} = AOAlobeCount;
    statTable{iTR,33} = AOALobeAngles;
    statTable{iTR,34} = AODlobeCount;
    statTable{iTR,35} = AODLobeAngles;
    statTable{iTR,36} = dirRMSDS_2;%need to get this
    statTable{iTR,37} = AOA_boundaryMpcP; %boundary MPCs col 37-42
    statTable{iTR,38} = AOA_boundaryMpcA;
    statTable{iTR,39} = AOA_boundaryMpcZ;
    statTable{iTR,40} = AOA_boundaryMpcZOfs;
    statTable{iTR,41} = AOD_boundaryMpcP; 
    statTable{iTR,42} = AOD_boundaryMpcA;
    statTable{iTR,43} = AOD_boundaryMpcZ;
    statTable{iTR,44} = AOD_boundaryMpcZOfs;
    statTable{iTR,45} = TR_str(iTR);
    %}
end

%% Secondary statistics
[Sec_statTable,statTable]=SecondaryStats_circD(statTable,elevPatternFile,aziPatternFile,1);

toc;
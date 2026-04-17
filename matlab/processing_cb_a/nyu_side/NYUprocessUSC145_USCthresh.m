clear variables;
close all;
tic

root_path='G:\My Drive\NaveedDipankarMingjunJorgeShare\NYU\';
%root_path='C:\Users\Dipankar\Documents\DipankarTempFiles\NaveedDipankarMingjunJorgeShare\NYU';
Adata_path="\NYUformatUSCdata\NYUformat_PDP_R*";

%% To extract Az and El cuts from USC pattern for first time only
% Load measured 2D pattern (power, normalized)
patternFile = 'USC_antennaPattern\THz_3D_pattern_aver.mat';
Spat = load(patternFile);
if isfield(Spat,'HS21_mea_145G_1')
    % Average power over frequency to 361 x 91 (Az x El) in linear power
    patLin = squeeze(mean(abs(Spat.HS21_mea_145G_1).^2, 1));
else
    error('Pattern variables not found in %s', patternFile);
end
patLin     = patLin / max(patLin(:));                % normalize peak to 1
patAzAxis  = -90:90;                          % 361 points
patElAxis = -90:90;  % 181 points total

patLin_shifted = zeros(size(patLin));
patLin_shifted(1:181, :) = patLin(181:361, :);    % -180° to 0°
patLin_shifted(181:361, :) = patLin(1:181, :);  % 0° to 180°

patLin = patLin_shifted;

patLin=patLin(91:271,:);

% Get indices where we have measured data
el_measured_indices = find(patElAxis >= -45 & patElAxis <= 45);

% Create new pattern matrix with expanded elevation
patLin_trimmed = zeros(length(patAzAxis), length(patElAxis));

% Copy measured data to the center of the new matrix
patLin_trimmed(:, el_measured_indices) = patLin;

% For missing values (outside -45:45), set to very low gain
min_gain_linear = 1e-4;  % -40 dB
patLin_trimmed(:, [1:(el_measured_indices(1)-1), (el_measured_indices(end)+1):end]) = min_gain_linear;

patdB_trimmed = 10*log10(patLin_trimmed);
% Azimuth cut
el0_index = find(patElAxis == 0);
az_cut = patdB_trimmed(:, el0_index);
aziPatternFile = [patAzAxis',az_cut];

%Elevation cut
az0_index = find(patAzAxis == 0);
el_cut = patdB_trimmed(az0_index, :);
elevPatternFile = [patElAxis',el_cut'];

%% Load Azi and Elev cuts
elevPatternFile = importdata('USC_antennaPattern\elevCut.mat');
aziPatternFile = importdata('USC_antennaPattern\aziCut.mat');

%% Initialize procesing params
multipath_low_bound=-200;
thres_below_pk=25;
thres_abv_noise=5;
MTI=25;% Minimum void time interval in ns
HPBW=10;% USC spatial step size is slightly lower than HPBW. 
% Need to add empirical correction factor later.
RXAntGainCorr=1.95; %Since USC PDPs already calibrate out the antenna, 
% there's only an empirical gain correction to be employed for non-HPBW steps 
% Antenna Gain need not be removed post omni-synthesis, like that for NYU.
% Therefore, variable RXAntGain -> RXAntGainCorr =1.95 dB for USC 145 GHz data
% Same thing for TXAntGain.. TXAntGain -> TXAntGainCorr =1.95 dB for USC 145 GHz data
TXAntGainCorr=1.95; % Antenna Gain

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

%% Loop over all measurements
for iTR=1:nTR
    RXid=sscanf(TR_str(iTR),"NYUformat_PDP_R%d");
    TXid=1;
    TRpdpSet=load(strcat(rootDir(1).folder,'\',TR_str(iTR)));
    TRpdpSet=struct2cell(TRpdpSet);
    TRpdpSet=TRpdpSet{1,1}; %The current naming convention Dipankar used in saving variables.

    %Cell array Structure of Aligned PDP set
        %|1. Denoised PDP|2. TX_ID|3. RX_ID|4. Meas #|5. Rot #|
        %|6. AOD Azimuth|7. AOD Elevation|8. AOA Azimuth|9. AOA Elevation|
        %|10. Environment|
    Env=TRpdpSet{1,10};

    % %%%% Run Thresholding over entire dataset (USC method)
    % Note all USC PDPs are in linear scale
    allPDPsLin=[TRpdpSet{:,1}];
    allPDPsdB=pow2db(allPDPsLin);

    % USC noise floor: 25th percentile + 5.41 dB per PDP, then take max
    noise_floor_vals = zeros(1,width(allPDPsdB));
    for iPDP=1:width(allPDPsdB)
        noise_floor_vals(iPDP)=noise_floor_calc_v2(allPDPsdB(:,iPDP));
    end
    max_noise_floor = max(noise_floor_vals);
    uniform_thresh = max_noise_floor + 12;

    noise_floor_low_bound = -250;
    allPDPsdB(allPDPsdB<uniform_thresh)=noise_floor_low_bound;

    %Next, filter across all PDPs and discard all rows in TRpdpSet that
    %have no MPC peaks above noise floor.
    selIdx=true(1,width(allPDPsdB));
    for iPDP=1:width(allPDPsdB)
        if(isempty(allPDPsdB(allPDPsdB(:,iPDP)>noise_floor_low_bound,iPDP)))
            selIdx(iPDP)=false;
        else
            TRpdpSet{iPDP,1}=allPDPsdB(:,iPDP);%change PDP to be in dB
        end
    end
    TRpdpSet=TRpdpSet(selIdx,:);
    %For USC convert -ve TX AOD angles to within 360 with mod function
    TRpdpSet(:,6)=num2cell(mod([TRpdpSet{:,6}],360));

    
    %AOA PAS
    [AOA_PAS_angles0, AOA_PAS_powers0, AOA_PAS_set]=PASgenerator(TRpdpSet,8,6,multipath_low_bound);
    [Thres10,mPos]=max(AOA_PAS_powers0);
    Thres10=Thres10-10;
    Thres20=Thres10-10;

    [AOAlobeCountNoTh,AOAlobeWidthsNoTh,AOAendsNoTh,AOAstartsNoTh,AOA_PAS_anglesNoTh,AOA_PAS_powersNoTh]=lobeShaperCounterD(multipath_low_bound, AOA_PAS_set,'HPBW',HPBW);
    %PASplotter(AOA_PAS_anglesNoTh,AOA_PAS_powersNoTh-RXAntGainCorr,'Threshold',Thres10);
    
    [AOAlobeCount,AOAlobeWidths,AOAends,AOAstarts,AOA_PAS_angles,AOA_PAS_powers]=lobeShaperCounterD(multipath_low_bound, AOA_PAS_set,'Threshold',Thres10,'HPBW',HPBW);

    AOAs=[AOA_PAS_set{:,3}];
    if (sum(mod(AOAstarts,360)>AOAends)==0)
        AOAspThMask=sum(((AOAs'>=mod(AOAstarts,360)')&(AOAs'<=AOAends')),2)>0;
    else
        tempStarts=AOAstarts(mod(AOAstarts,360)>AOAends);
        tempEnds=AOAends(mod(AOAstarts,360)>AOAends);
        AOAspThMask=(AOAs'>=mod(tempStarts,360)')|(AOAs'<=tempEnds')|(sum(((AOAs'>=mod(AOAstarts,360)')&(AOAs'<=AOAends')),2)>0);
    end
    AOA_PAS_set_spTh=AOA_PAS_set(AOAspThMask,:);
    
    if(~(AOAlobeCount==1 && AOAlobeWidths(1)==360))
        [AOA_boundaryMpcP,AOA_boundaryMpcA,AOA_boundaryMpcZ,AOA_boundaryMpcZOfs]=boundaryMPCsD(AOA_PAS_set_spTh,AOA_PAS_angles,AOA_PAS_powers,AOAstarts,AOAends,Thres10,aziPatternFile,elevPatternFile); %Open function for description
    end

    OmniPDP1=pow2db(sum(db2pow([AOA_PAS_set{:,1}]-RXAntGainCorr),2));%Remove ant gain
    OmniPDP1_spTh=pow2db(sum(db2pow([AOA_PAS_set_spTh{:,1}]-RXAntGainCorr),2));% sp=spatial thresholded
   
    %AOD PAS
    [AOD_PAS_angles0, AOD_PAS_powers0, AOD_PAS_set]=PASgenerator(TRpdpSet,6,8,multipath_low_bound);
    [Thres10,mPos]=max(AOD_PAS_powers0);
    Thres10=Thres10-10;
    Thres20=Thres10-10;
    [AODlobeCountNoTh,AODlobeWidthsNoTh,AODendsNoTh,AODstartsNoTh,AOD_PAS_anglesNoTh,AOD_PAS_powersNoTh]=lobeShaperCounter(multipath_low_bound, AOD_PAS_angles0, AOD_PAS_powers0,'HPBW',HPBW);
    %PASplotter(AOD_PAS_anglesNoTh,AOD_PAS_powersNoTh-TXAntGainCorr,'Threshold',Thres10);

    [AODlobeCount,AODlobeWidths,AODends,AODstarts,AOD_PAS_angles,AOD_PAS_powers]=lobeShaperCounterD(multipath_low_bound, AOD_PAS_set,'Threshold',Thres10,'HPBW',HPBW);
    
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
    
    OmniPDP=pow2db(sum(db2pow([AOD_PAS_set{:,1}]-RXAntGainCorr),2));
    [TCs,TCstart,TCstop,TCxsDelay,Nsp,iraClXsDly,SPpwrs,ierClXsDly]=clusterSearch(OmniPDP1_spTh,multipath_low_bound,MTI);

    [meanAOAangles,meanZOAangles,AOALobeAngles,AOALobePowers]=meanSLangles(AOA_PAS_set_spTh,AOAlobeCount,AOAlobeWidths,AOAends,AOAstarts,AOA_PAS_angles,AOA_PAS_powers);
    [meanAODangles,meanZODangles,AODLobeAngles,AODLobePowers]=meanSLangles(AOD_PAS_set_spTh,AODlobeCount,AODlobeWidths,AODends,AODstarts,AOD_PAS_angles,AOD_PAS_powers);

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
    SP_AOA_sub=-500*ones(size(SP_AOA));
    SP_AOD_sub=-500*ones(size(SP_AOD));
    SP_ZOA_sub=-500*ones(size(SP_ZOA));
    SP_ZOD_sub=-500*ones(size(SP_ZOD));
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

        SP_AOA_sub(b:e)=SP_AOA(TCmask);
        SP_AOD_sub(b:e)=SP_AOD(TCmask);
        SP_ZOA_sub(b:e)=SP_ZOA(TCmask);
        SP_ZOD_sub(b:e)=SP_ZOD(TCmask);

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

    SP_AOA=SP_AOA_sub(SP_AOA_sub~=-500);
    SP_AOD=SP_AOD_sub(SP_AOD_sub~=-500);
    SP_ZOA=SP_ZOA_sub(SP_ZOA_sub~=-500);
    SP_ZOD=SP_ZOD_sub(SP_ZOD_sub~=-500);

    %Get RMS DS MPC-wise approach
    dirRMSDS_2 = zeros(size(SP_idx_sub,1),1);
    %USC PDP undilated
    array_temp=[SP_idx_sub SP_pwr_sub SP_AOA SP_ZOA SP_AOD SP_ZOD];
    for j = 1:size(SP_idx_sub,1)
        dirRMSDS_2(j) = computeDirDS(array_temp,array_temp(j,3:6),...
                aziPatternFile,elevPatternFile,thres_below_pk);
    end

    statTable{iTR,1} = OmniPDP1;
    statTable{iTR,2} = AODlobeCount;
    %statTable{iTR,3} = AS_AOD;
    %statTable{iTR,4} = ASglobal_AOD;
    %statTable{iTR,5} = AOAlobeCount;
    %statTable{iTR,6} = AS_AOA;
    %statTable{iTR,7} = ASglobal_AOA;
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

end

%% Secondary statistics
[Sec_statTable,statTable]=SecondaryStats_circD(statTable,elevPatternFile,aziPatternFile);

%% Compare path loss vs USC original results
% USC reference uses 0 dBm Tx power and PDPs already have antenna gain removed.
% Path loss (dB) = -10*log10(sum(PDP_linear)) where PDP is omnidirectional.

% Build computed PL from omnidirectional PDPs in statTable column 1
nTR_local = height(statTable);
PL_calc_dB = nan(nTR_local,1);
RX_id = zeros(nTR_local,1);
distances = zeros(nTR_local,1);
for iTR=1:nTR_local
    TR_id_str = statTable{iTR,45};
    temp=sscanf(TR_id_str,"NYUformat_PDP_R%d_%fm");
    RX_id(iTR) = temp(1);
    distances(iTR) = temp(2);
    omniPDP_dB = statTable{iTR,1};
    if isempty(omniPDP_dB)
        continue;
    end
    validMask = omniPDP_dB > (multipath_low_bound + 1);
    if any(validMask)
        Prx_dBm = pow2db(sum(db2pow(omniPDP_dB(validMask))));
        PL_calc_dB(iTR) = -Prx_dBm + TXAntGainCorr + RXAntGainCorr; % Pt = 0 dBm
        %USC PDPs need a gain correction since antennas are not stepped in
        %HPBW steps but slightly lower
    end
end

% Load USC original results (LOS / NLOS)
uscLOS = readtable('OriginalUSC-PointData\usc_microcellular_LOS_metrics.csv');
uscNLOS = readtable('OriginalUSC-PointData\usc_microcellular_NLOS_metrics.csv');

% Extract RX ids from USC filenames (e.g., "R01_64.5m LOS_Microcellular.mat")
uscLOS.RX_id = zeros(height(uscLOS),1);
uscNLOS.RX_id = zeros(height(uscNLOS),1);
for i=1:height(uscLOS)
    tok = regexp(uscLOS.File{i},'R(\d+)','tokens','once');
    uscLOS.RX_id(i) = str2double(tok{1});
end
for i=1:height(uscNLOS)
    tok = regexp(uscNLOS.File{i},'R(\d+)','tokens','once');
    uscNLOS.RX_id(i) = str2double(tok{1});
end

% Build environment labels from TR_id_str to disambiguate same RX IDs
env_label = strings(nTR_local,1);
for iTR=1:nTR_local
    TR_id_str = statTable{iTR,45};
    if contains(TR_id_str,"NLOS","IgnoreCase",true)
        env_label(iTR)="NLOS";
    elseif contains(TR_id_str,"LOS","IgnoreCase",true)
        env_label(iTR)="LOS";
    else
        env_label(iTR)="";
    end
end

% Match computed PL to USC originals by RX ID + environment
calc_table = table(RX_id, distances, env_label, PL_calc_dB, ...
    'VariableNames', {'RX_id','Distance_m','Env','PL_NYU_dB'});

calc_LOS = calc_table(calc_table.Env=="LOS",:);
calc_NLOS = calc_table(calc_table.Env=="NLOS",:);

% Match by RX ID + distance (from TR_id_str) within tolerance
dist_tol = 0.1; % meters
los_idx_ref = nan(height(calc_LOS),1);
nlos_idx_ref = nan(height(calc_NLOS),1);

for i=1:height(calc_LOS)
    candidates = find(uscLOS.RX_id==calc_LOS.RX_id(i) & ...
        abs(uscLOS.Distance_m - calc_LOS.Distance_m(i)) < dist_tol);
    if ~isempty(candidates)
        los_idx_ref(i)=candidates(1);
    end
end
for i=1:height(calc_NLOS)
    candidates = find(uscNLOS.RX_id==calc_NLOS.RX_id(i) & ...
        abs(uscNLOS.Distance_m - calc_NLOS.Distance_m(i)) < dist_tol);
    if ~isempty(candidates)
        nlos_idx_ref(i)=candidates(1);
    end
end

valid_los = ~isnan(los_idx_ref);
valid_nlos = ~isnan(nlos_idx_ref);
los_idx_ref = los_idx_ref(valid_los);
nlos_idx_ref = nlos_idx_ref(valid_nlos);

PL_calc_LOS = calc_LOS.PL_NYU_dB(valid_los);
PL_ref_LOS = uscLOS.PL_omni_dB(los_idx_ref);
dist_LOS = uscLOS.Distance_m(los_idx_ref);

PL_calc_NLOS = calc_NLOS.PL_NYU_dB(valid_nlos);
PL_ref_NLOS = uscNLOS.PL_omni_dB(nlos_idx_ref);
dist_NLOS = uscNLOS.Distance_m(nlos_idx_ref);

% Save PL tables with TX/RX IDs for paper tabulation
TX_id_LOS = TXid*ones(size(PL_calc_LOS));
TX_id_NLOS = TXid*ones(size(PL_calc_NLOS));

pl_table_LOS = table(uscLOS.RX_id(los_idx_ref), TX_id_LOS, dist_LOS, PL_ref_LOS, PL_calc_LOS, ...
    'VariableNames', {'RX_id','TX_id','Distance_m','PL_USC_dB','PL_NYU_dB'});
pl_table_NLOS = table(uscNLOS.RX_id(nlos_idx_ref), TX_id_NLOS, dist_NLOS, PL_ref_NLOS, PL_calc_NLOS, ...
    'VariableNames', {'RX_id','TX_id','Distance_m','PL_USC_dB','PL_NYU_dB'});

writetable(pl_table_LOS, 'PL_comparison_LOS.csv');
writetable(pl_table_NLOS, 'PL_comparison_NLOS.csv');

% Plot 1: Scatter comparison with y=x line
figure('Name','Path Loss: USC Original vs NYU Processing');
hold on;
scatter(PL_ref_LOS, PL_calc_LOS, 50, 'b', 'filled');
scatter(PL_ref_NLOS, PL_calc_NLOS, 50, 'r', 'filled');
minPL = min([PL_ref_LOS; PL_calc_LOS; PL_ref_NLOS; PL_calc_NLOS],[],'omitnan');
maxPL = max([PL_ref_LOS; PL_calc_LOS; PL_ref_NLOS; PL_calc_NLOS],[],'omitnan');
plot([minPL maxPL],[minPL maxPL],'k--','LineWidth',1.5);
grid on;
xlabel('USC Original PL (dB)');
ylabel('NYU Processed PL (dB)');
legend('LOS','NLOS','y = x','Location','best');
title('Path Loss Comparison');
hold off;

% Error metrics (RMSE, MAE)
err_LOS = PL_calc_LOS - PL_ref_LOS;
err_NLOS = PL_calc_NLOS - PL_ref_NLOS;
rmse_LOS = sqrt(mean(err_LOS.^2,'omitnan'));
mae_LOS = mean(abs(err_LOS),'omitnan');
rmse_NLOS = sqrt(mean(err_NLOS.^2,'omitnan'));
mae_NLOS = mean(abs(err_NLOS),'omitnan');

fprintf('Path Loss Error Metrics (NYU processed - USC original)\\n');
fprintf('LOS  : RMSE = %.3f dB, MAE = %.3f dB (N=%d)\\n', rmse_LOS, mae_LOS, numel(err_LOS));
fprintf('NLOS : RMSE = %.3f dB, MAE = %.3f dB (N=%d)\\n', rmse_NLOS, mae_NLOS, numel(err_NLOS));

% Plot 3: Error per T-R location (bar plots)
figure('Name','Path Loss Error by Location');
subplot(2,1,1);
bar(uscLOS.RX_id(los_idx_ref), err_LOS, 'FaceColor', [0.2 0.4 0.9]);
grid on; xlabel('RX ID'); ylabel('PL Error (dB)');
title('LOS: NYU - USC');

subplot(2,1,2);
bar(uscNLOS.RX_id(nlos_idx_ref), err_NLOS, 'FaceColor', [0.9 0.3 0.3]);
grid on; xlabel('RX ID'); ylabel('PL Error (dB)');
title('NLOS: NYU - USC');

% Plot 2: PL vs Distance (LOS / NLOS)
figure('Name','Path Loss vs Distance');
subplot(1,2,1);
plot(dist_LOS, PL_ref_LOS, 'bo','MarkerFaceColor','b'); hold on;
plot(dist_LOS, PL_calc_LOS, 'bx','MarkerSize',8,'LineWidth',1.5);
grid on; xlabel('Distance (m)'); ylabel('Path Loss (dB)');
title('LOS'); legend('USC Original','NYU Processed','Location','best');

subplot(1,2,2);
plot(dist_NLOS, PL_ref_NLOS, 'ro','MarkerFaceColor','r'); hold on;
plot(dist_NLOS, PL_calc_NLOS, 'rx','MarkerSize',8,'LineWidth',1.5);
grid on; xlabel('Distance (m)'); ylabel('Path Loss (dB)');
title('NLOS'); legend('USC Original','NYU Processed','Location','best');

toc;

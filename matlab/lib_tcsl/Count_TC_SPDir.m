clear variables;
close all;
tic

set(0,'DefaultLineLinewidth',2);
set(0,'DefaultAxesFontSize',16);
set(0,'DefaultLineMarkerSize',10);

%f=16.95e9; % Change here to freq needed %%%%%%%%%%%%%
f=6.75e9; % Change here to freq needed %%%%%%%%%%%%%
%freq_DataSet=17; % Change here to freq needed %%%%%%%%%%%%%
freq_DataSet=7; % Change here to freq needed %%%%%%%%%%%%%

lambda=physconst('Lightspeed')/f;

multipath_low_bound=-130;
MTI=25;

% root_path=['C:\Users\Dipankar Shakya\Documents\' ...
%     'Desktop Work Station 2020\NYU_Wireless_Lab\Channel sounder\' ...
%     'FR3MeasurementsCode-UMi\'];
root_path=['G:\Other computers\HP\Desktop Work Station 2020\NYU_Wireless_Lab\' ...
    'Channel sounder\FR3MeasurementsCode-UMi\'];

%Adata_path="2.Alignment\NotAllAligned\17 GHz\Data17*"; %% Change here to freq needed %%%%%%%%%%%%%
%Adata_path="2.Alignment\Aligned\17 GHz\Data17*"; %% Change here to freq needed %%%%%%%%%%%%%
Adata_path="2.Alignment\Aligned\7 GHz\Data7*"; %% Change here to freq needed %%%%%%%%%%%%%
%Track over the T-R location combinations
rootDir=dir(strcat(root_path,Adata_path));
rootDir=rootDir(~ismember({rootDir.name},{'.','..'}));
TR_str=string(natsortfiles({rootDir.name}))';

%data_path="3.PathLoss\GeneratedResults\17 GHz\80nsPkSep\AllLocs.csv"; %% Change here to freq needed %%%%%%%%%%%%%
data_path="3.PathLoss\GeneratedResults\7 GHz\80nsPkSep\AllLocs.csv"; %% Change here to freq needed %%%%%%%%%%%%%

OutdoorData=readtable(strcat(root_path,data_path));

%OutdoorData17=filterTable(OutdoorData17,refined_table_path);

TX_ID=unique(OutdoorData.TXID);

tableHeadings={'TXID','RXID','OmniPwr','TRSeparation','TXPower','DeN_PDP','RotNum','Environment'};
varTypes={'double','double','double','double','double','double','double','string'};
DirPLdata=table('Size',[0 length(varTypes)],'VariableTypes',varTypes,'VariableNames',tableHeadings);
DirPLNBdata=DirPLdata;
%Here NB stands for Non-Best i.e. the directions where power is not the
%srongest

%IMPORTANT: Here the definitions are as such:
%line-of-sight indicates a clear visual path between TX and RX locations
%LOS is the boresight direction in line-of-sight locations
%NLOSB is the max-power direction in non-line-of-sight locations
%NLOS includes the non-boresight and non-best directions in line-of-sight and non-line-of-sight locations

for tx_i=1:length(TX_ID)
    RX_ID=unique(table2array(OutdoorData(OutdoorData.TXID==TX_ID(tx_i),'RXID')));
    for rx_i=1:length(RX_ID)
        %This looks at the best pointing angles
        %Not all locations have best pointing angle at rotation 0.
        subT=OutdoorData(OutdoorData.TXID==TX_ID(tx_i)&OutdoorData.RXID==RX_ID(rx_i),{'Pr','RotationNumber'});
        [~,idx]=max(subT.Pr);
        RotNum=subT.RotationNumber(idx);
        PowerRxc=table2array(subT(subT.RotationNumber==RotNum,'Pr'));
        
        %Use upper for 7 GHz data until alignment complete
        %TR_str=strcat("Data",num2str(freq_DataSet),"Pack_TX",num2str(TX_ID(tx_i)),"_RX",num2str(RX_ID(rx_i)),".mat");
        TR_str=strcat("Data",num2str(freq_DataSet),"Pack_TX",num2str(TX_ID(tx_i)),"_RX",num2str(RX_ID(rx_i)),"_Aligned.mat");
        TRpdpSet=load(strcat(rootDir(1).folder,'\',TR_str));
        TRpdpSet=struct2cell(TRpdpSet);
        TRpdpSet=TRpdpSet{1,1}; %The current naming convention Dipankar used in saving variables.
        TRpdpSet_idx=TRpdpSet([TRpdpSet{:,5}]==RotNum,[1,2,3,4,5]);

        %Cell array Structure of Aligned PDP set
            %|1. Denoised PDP|2. TX_ID|3. RX_ID|4. Meas #|5. Rot #|
            %|6. AOD Azimuth|7. AOD Elevation|8. AOA Azimuth|9. AOA Elevation|
            %|10.  Power_Rx_aft_ant (Pr)|11. pkIdx| 12. Environment|
            %|13. Raw PDP|

        RXAntGain=table2array(OutdoorData(1,'RXAntennaGain'));
        TXAntGain=table2array(OutdoorData(1,'TXAntennaGain'));
        TRsep=table2array(OutdoorData(OutdoorData.TXID==TX_ID(tx_i)&OutdoorData.RXID==RX_ID(rx_i),'TRSeparation'));
        TRsep=TRsep(1);
        Env=string(table2array(OutdoorData(OutdoorData.TXID==TX_ID(tx_i)&OutdoorData.RXID==RX_ID(rx_i),'Environment')));
        Env=Env(1);
        TXpow=table2array(OutdoorData(OutdoorData.TXID==TX_ID(tx_i)&OutdoorData.RXID==RX_ID(rx_i),'TXPower'));
        TXpow=TXpow(1);
        PowerRxc_GainRmv=PowerRxc-RXAntGain;
        DirPow=pow2db(sum(db2pow(PowerRxc_GainRmv)));% Add the powers in non-overlapping directions
                                                        %% Synthesizing Omni PDP
                                                        %S. Sun, G. R. MacCartney, Jr., M. K. Samimi, and T. S. Rappaport,
                                                        %‘‘Synthesizing omnidirectional antenna patterns, received power
                                                        %and path loss from directional antennas for 5G millimeter-wave
                                                        %communications,’’ in Proc. IEEE Global Commun. Conf. (GLOBECOM),
                                                        %Dec. 2015.
        
        DirPDP=pow2db(sum(db2pow([TRpdpSet_idx{:,1}]-RXAntGain),2)); % Here I'm not caring about accuracy of MPC power.
                                 % as I only want to count 

        T=table(TX_ID(tx_i),RX_ID(rx_i),DirPow,TRsep,TXpow,{DirPDP},RotNum,Env,'VariableNames',tableHeadings);
        DirPLdata=[DirPLdata;T];
        
        %Now we get the NLOS points 
        %(excluding the best direction and immediate adjacent directions)
        %PowerRxcNB=subT((subT.RotationNumber~=RotNum)&(subT.RotationNumber~=mod(RotNum+1,45))&(subT.RotationNumber~=mod(RotNum-1,45)),:);
        %Also attempting with only the best not-included; Ychou's
        %processing
        %if(Env=="NLOS")
            TRpdpSetNB_idx=TRpdpSet([TRpdpSet{:,5}]~=RotNum,[1,2,3,4,5]);
            PowerRxcNB=subT((subT.RotationNumber~=RotNum),:);
            Rots=unique(PowerRxcNB.RotationNumber);
            for rot_i=1:length(Rots)
                DirPwrNB=table2array(PowerRxcNB((PowerRxcNB.RotationNumber==Rots(rot_i)),'Pr'));
                DirPwrNB=pow2db(sum(db2pow(DirPwrNB-RXAntGain)));
                DirPDPNB=pow2db(sum(db2pow([TRpdpSetNB_idx{[TRpdpSetNB_idx{:,5}]==Rots(rot_i),1}]-RXAntGain),2)); % Here I'm not caring about accuracy of MPC power.
                                 % as I only want to count 
                T=table(TX_ID(tx_i),RX_ID(rx_i),DirPwrNB,TRsep,TXpow,{DirPDPNB},RotNum,Env,'VariableNames',tableHeadings);
                DirPLNBdata=[DirPLNBdata;T];
            end
        %end
    end
end

Environment=DirPLdata(:,'Environment');
Environment=string(table2array(Environment));

LOSidx=(Environment=='LOS');
nTCS_LOS=zeros(1,sum(LOSidx));
nSPs_LOS=[];
DirLOS_PDPs=DirPLdata{LOSidx,"DeN_PDP"};


for i=1:sum(LOSidx)
    [TCs,~,~,~,Nsp,~,~,~]=clusterSearch(cell2mat(DirLOS_PDPs(i,:)),multipath_low_bound,MTI);
    nTCS_LOS(i)=TCs;
    nSPs_LOS=[nSPs_LOS;Nsp];
end

NLOSBidx=(Environment=='NLOS');% B stands for Best i.e. Best pointing direction
nTCS_NLOSB=zeros(1,sum(NLOSBidx));
nSPs_NLOSB=[];
DirNLOSB_PDPs=DirPLdata{NLOSBidx,"DeN_PDP"};


for i=1:sum(LOSidx)
    [TCs,~,~,~,Nsp,~,~,~]=clusterSearch(cell2mat(DirNLOSB_PDPs(i,:)),multipath_low_bound,MTI);
    nTCS_NLOSB(i)=TCs;
    nSPs_NLOSB=[nSPs_NLOSB;Nsp];
end


DirNLOS_PDPs=DirPLNBdata{:,"DeN_PDP"};
nTCS_NLOS=zeros(1,height(DirNLOS_PDPs));
nSPs_NLOS=[];


%%
for i=1:height(DirNLOS_PDPs)
    [TCs,~,~,~,Nsp,~,~,~]=clusterSearch(cell2mat(DirNLOS_PDPs(i,:)),multipath_low_bound,MTI);
    nTCS_NLOS(i)=TCs;
    nSPs_NLOS=[nSPs_NLOS;Nsp];
end


u_nTCs_LOS=mean(nTCS_LOS(nTCS_LOS<100));
std_nTCs_LOS=std(nTCS_LOS(nTCS_LOS<100));
u_nTCs_NLOSB=mean(nTCS_NLOSB(nTCS_NLOSB<100));
std_nTCs_NLOSB=std(nTCS_NLOSB(nTCS_NLOSB<100));
u_nTCs_NLOS=mean(nTCS_NLOS(nTCS_NLOS<100));
std_nTCs_NLOS=std(nTCS_NLOS(nTCS_NLOS<100));

u_nSPs_LOS=mean(nSPs_LOS(nSPs_LOS<100));
std_nSPs_LOS=std(nSPs_LOS(nSPs_LOS<100));
u_nSPs_NLOSB=mean(nSPs_NLOSB(nSPs_NLOSB<100));
std_nSPs_NLOSB=std(nSPs_NLOSB(nSPs_NLOSB<100));
u_nSPs_NLOS=mean(nSPs_NLOS(nSPs_NLOS<100));
std_nSPs_NLOS=std(nSPs_NLOS(nSPs_NLOS<100));

toc;
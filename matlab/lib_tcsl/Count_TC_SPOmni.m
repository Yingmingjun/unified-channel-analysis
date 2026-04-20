%% Quick code to count and find mean of TCs and SPs in TCs for Omni
clear variables;
load('TCSL17_Results_ver1.mat'); %Change this dataset as required
%load('TCSL7_Results_ver1.mat'); %Change this dataset as required

statTable_LOS=statTable([statTable{:,25}]=="LOS",:);
statTable_NLOS=statTable([statTable{:,25}]=="NLOS",:);
TCs_LOS=vertcat(statTable_LOS{:,8});
TCs_NLOS=vertcat(statTable_NLOS{:,8});
SPsinTC_LOS=vertcat(statTable_LOS{:,12});
SPsinTC_NLOS=vertcat(statTable_NLOS{:,12});
u_TC_LOS=mean(TCs_LOS);
std_TC_LOS=std(TCs_LOS);
u_TC_NLOS=mean(TCs_NLOS);
std_TC_NLOS=std(TCs_NLOS);
u_SP_LOS=mean(SPsinTC_LOS);
std_SP_LOS=std(SPsinTC_LOS);
SPsinTC_NLOS=SPsinTC_NLOS(SPsinTC_NLOS<100);
u_SP_NLOS=mean(SPsinTC_NLOS);
std_SP_NLOS=std(SPsinTC_NLOS);
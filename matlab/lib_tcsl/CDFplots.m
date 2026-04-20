clear variables;
close all;

%load('TCSL17Results_check.mat');
load('TCSL7Results_f_aligned.mat');

Sec_statTableLOS=Sec_statTable([Sec_statTable{:,12}]=="LOS",:);
Sec_statTableNLOS=Sec_statTable([Sec_statTable{:,12}]=="NLOS",:);

LOS_meas_omni_ds = vertcat(Sec_statTableLOS{:,1});
LOS_meas_dir_ds = vertcat(Sec_statTableLOS{:,13});

NLOS_meas_omni_ds = vertcat(Sec_statTableNLOS{:,1});
NLOS_meas_dir_ds = vertcat(Sec_statTableNLOS{:,13});


NLOS_meas_dir_ds(NLOS_meas_dir_ds>180) = [];
LOS_meas_dir_ds(LOS_meas_dir_ds>140) = [];
%LOS_meas_omni_ds(LOS_meas_omni_ds>90) = [];



%% Omni Angular Spread
LOS_meas_omni_asd = vertcat(Sec_statTableLOS{:,2});
LOS_meas_omni_zsd = vertcat(Sec_statTableLOS{:,3});
LOS_meas_omni_asa = vertcat(Sec_statTableLOS{:,4});
LOS_meas_omni_zsa = vertcat(Sec_statTableLOS{:,5});
% Lobe Angular Spread
LOS_meas_lobe_asd = vertcat(Sec_statTableLOS{:,8});
LOS_meas_lobe_zsd = vertcat(Sec_statTableLOS{:,9});
LOS_meas_lobe_asa = vertcat(Sec_statTableLOS{:,10});
LOS_meas_lobe_zsa = vertcat(Sec_statTableLOS{:,11});

% Omni Angular Spread
NLOS_meas_omni_asd = vertcat(Sec_statTableNLOS{:,2});
NLOS_meas_omni_zsd = vertcat(Sec_statTableNLOS{:,3});
NLOS_meas_omni_asa = vertcat(Sec_statTableNLOS{:,4});
NLOS_meas_omni_zsa = vertcat(Sec_statTableNLOS{:,5});
% Lobe Angular Spread
NLOS_meas_lobe_asd = vertcat(Sec_statTableNLOS{:,8});
NLOS_meas_lobe_zsd = vertcat(Sec_statTableNLOS{:,9});
NLOS_meas_lobe_asa = vertcat(Sec_statTableNLOS{:,10});
NLOS_meas_lobe_zsa = vertcat(Sec_statTableNLOS{:,11});

%%7 GHz
  LOS_meas_lobe_asa(LOS_meas_lobe_asa==0)=[];
  LOS_meas_lobe_asa=[0;LOS_meas_lobe_asa];
%   NLOS_meas_lobe_asa(NLOS_meas_lobe_asa==0)=[];
%   LOS_meas_lobe_asa(LOS_meas_lobe_asa<1)=[];
   %NLOS_meas_lobe_asa(NLOS_meas_lobe_asa<1)=[];
  %LOS_meas_omni_asa(LOS_meas_omni_asa<1)=[];
  %NLOS_meas_omni_asa(NLOS_meas_omni_asa<1)=[];
% 
  LOS_meas_lobe_asd(LOS_meas_lobe_asd<1)=[];
  NLOS_meas_lobe_asd(NLOS_meas_lobe_asd<1)=[];
  LOS_meas_omni_asd(LOS_meas_omni_asd<1)=[];
  NLOS_meas_omni_asd(NLOS_meas_omni_asd<1)=[];


%%17 GHz
%   LOS_meas_lobe_asa(LOS_meas_lobe_asa==0)=[];
%    NLOS_meas_lobe_asa(NLOS_meas_lobe_asa==0)=[];
  %LOS_meas_lobe_asa(LOS_meas_lobe_asa<0.1)=[];
   %NLOS_meas_lobe_asa(NLOS_meas_lobe_asa<1)=[];
  %LOS_meas_omni_asa(LOS_meas_omni_asa<1)=[];
  %NLOS_meas_omni_asa(NLOS_meas_omni_asa<1)=[];
% 
%   LOS_meas_lobe_asd(LOS_meas_lobe_asd<1)=[];
%   NLOS_meas_lobe_asd(NLOS_meas_lobe_asd<1)=[];
%   LOS_meas_omni_asd(LOS_meas_omni_asd<1)=[];
%   NLOS_meas_omni_asd(NLOS_meas_omni_asd<1)=[];


%% 
mean_rmsDS_LOS=mean(LOS_meas_dir_ds(LOS_meas_dir_ds<200));
sd_rmsDS_LOS=std(LOS_meas_dir_ds(LOS_meas_dir_ds<200));
mean_rmsDS_NLOS=mean(NLOS_meas_dir_ds);
sd_rmsDS_NLOS=std(NLOS_meas_dir_ds);

figure;
L1 = cdfplot(LOS_meas_dir_ds);
set(L1,'Color','b');
hold on;
L2 = cdfplot(NLOS_meas_dir_ds);
set(L2,'Color','r');
legend('LOS Empirical','NLOS Empirical','Location','southeast');
%xlim([0 200])
title('Directional RMS DS: 16.95 GHz')
hold off;

mean_omniDS_LOS=mean(LOS_meas_omni_ds);
sd_omniDS_LOS=std(LOS_meas_omni_ds);
mean_omniDS_NLOS=mean(NLOS_meas_omni_ds);
sd_omniDS_NLOS=std(NLOS_meas_omni_ds);

figure;
L3 = cdfplot(LOS_meas_omni_ds);
set(L3,'Color','b');
hold on;
L4 = cdfplot(NLOS_meas_omni_ds);
set(L4,'Color','r');
legend('LOS Empirical','NLOS Empirical','Location','southeast');
%xlim([0 80])
title('Omni RMS DS: 16.95 GHz')
hold off;


mean_lobeASA_LOS=rad2deg(circ_mean(deg2rad(LOS_meas_lobe_asa)));
sd_lobeASA_LOS=rad2deg(circ_std(deg2rad(LOS_meas_lobe_asa)));
mean_lobeASA_NLOS=rad2deg(circ_mean(deg2rad(NLOS_meas_lobe_asa)));
sd_lobeASA_NLOS=rad2deg(circ_std(deg2rad(NLOS_meas_lobe_asa)));

figure;
L5 = cdfplot(LOS_meas_lobe_asa);
set(L1,'Color','b');
hold on;
L6 = cdfplot(NLOS_meas_lobe_asa);
set(L2,'Color','r');
legend('LOS Empirical','NLOS Empirical','Location','southeast');
%xlim([0 200])
title('Lobe RMS ASA: 16.95 GHz')
hold off;

mean_lobeASD_LOS=rad2deg(circ_mean(deg2rad(LOS_meas_lobe_asd)));
sd_lobeASD_LOS=rad2deg(circ_std(deg2rad(LOS_meas_lobe_asd)));
mean_lobeASD_NLOS=rad2deg(circ_mean(deg2rad(NLOS_meas_lobe_asd)));
sd_lobeASD_NLOS=rad2deg(circ_std(deg2rad(NLOS_meas_lobe_asd)));

figure;
L7 = cdfplot(LOS_meas_lobe_asd);
set(L1,'Color','b');
hold on;
L8 = cdfplot(NLOS_meas_lobe_asd);
set(L2,'Color','r');
legend('LOS Empirical','NLOS Empirical','Location','southeast');
%xlim([0 200])
title('Lobe RMS ASD: 16.95 GHz')
hold off;

mean_omniASA_LOS=rad2deg(circ_mean(deg2rad(LOS_meas_omni_asa)));
sd_omniASA_LOS=rad2deg(circ_std(deg2rad(LOS_meas_omni_asa)));
mean_omniASA_NLOS=rad2deg(circ_mean(deg2rad(NLOS_meas_omni_asa)));
sd_omniASA_NLOS=rad2deg(circ_std(deg2rad(NLOS_meas_omni_asa)));

figure;
L9 = cdfplot(LOS_meas_omni_asa);
set(L1,'Color','b');
hold on;
L10 = cdfplot(NLOS_meas_omni_asa);
set(L2,'Color','r');
legend('LOS Empirical','NLOS Empirical','Location','southeast');
%xlim([0 200])
title('Omni RMS ASA: 16.95 GHz')
hold off;

mean_omniASD_LOS=rad2deg(circ_mean(deg2rad(LOS_meas_omni_asd)));
sd_omniASD_LOS=rad2deg(circ_std(deg2rad(LOS_meas_omni_asd)));
mean_omniASD_NLOS=rad2deg(circ_mean(deg2rad(NLOS_meas_omni_asd)));
sd_omniASD_NLOS=rad2deg(circ_std(deg2rad(NLOS_meas_omni_asd)));

figure;
L11 = cdfplot(LOS_meas_omni_asd);
set(L1,'Color','b');
hold on;
L12 = cdfplot(NLOS_meas_omni_asd);
set(L2,'Color','r');
legend('LOS Empirical','NLOS Empirical','Location','southeast');
%xlim([0 200])
title('Omni RMS ASD: 16.95 GHz')
hold off;

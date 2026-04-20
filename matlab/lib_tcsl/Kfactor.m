%% K-factor from TCSLresults
clear variables;

%load('TCSLresults142EnvReview.mat');
%load('TCSLresults73EnvReview.mat');
load('TCSLresults28EnvReviewR.mat');


Nrows = size(statTable,1); 

Kfactor_dB = zeros(Nrows,1);
LOS_idx= false(Nrows,1);

for i=1:Nrows
    OmniPDP=statTable{i,1};
    Ptotal=sum(db2pow(OmniPDP),1);
    Visibility= statTable{i,25};
    if (strcmp(Visibility,"LOS")) 
        LOS_idx(i)= true;
    end 
    %we find K factor using the strongest MPC
    % K factor= P_highestPeak/P_allOtherPeaks
    [~,PpeakLoc]=max(OmniPDP);
    Ppeak=sum(db2pow(OmniPDP(PpeakLoc-39:PpeakLoc+40,1)),1); 
    % we consider 80 samples around the peak as an MPC due to the 2 ns 
    % resolution and with 20 samples equivalent to 1 ns.
    Kfactor_dB(i) = pow2db(Ppeak/(Ptotal-Ppeak));
end
% removing K-factors of PDPs with single MPC. For this unreasonably high
% K-factors above 100 dB are discarded.
Kfactor_dB_LOS=Kfactor_dB(LOS_idx,1);
Kfactor_dB_LOS=Kfactor_dB_LOS((Kfactor_dB_LOS<100),1);
%meanK_LOS=pow2db(mean(db2pow(Kfactor_dB_LOS),1));
meanK_LOS=mean(Kfactor_dB_LOS,1);
stdK_LOS=std(Kfactor_dB_LOS,1,1);
minK_LOS=min(Kfactor_dB_LOS);
maxK_LOS=max(Kfactor_dB_LOS);

Kfactor_dB_NLOS=Kfactor_dB(~LOS_idx,1);
Kfactor_dB_NLOS=Kfactor_dB_NLOS((Kfactor_dB_NLOS<100),1);
meanK_NLOS=pow2db(mean(db2pow(Kfactor_dB_NLOS),1));
%meanK_NLOS=mean(Kfactor_dB_NLOS,1);
stdK_NLOS=std(Kfactor_dB_NLOS,1,1);
minK_NLOS=min(Kfactor_dB_NLOS);
maxK_NLOS=max(Kfactor_dB_NLOS);
%Also checking median values since the outlier points appear quite extreme.
%142 GHz NLOS: %removed extreme point >15 dB
%28 GHz NLOS: used array size 11
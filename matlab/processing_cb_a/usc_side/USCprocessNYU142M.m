%% Set up files
clear variables;
close all;
clc;
dbstop if error
tic

basePath="G:\My Drive\NaveedDipankarMingjunJorgeShare\USC\USCformatNYUdata\";

rootDir=dir(basePath+"USCformat_142GHz*");
rootDir=rootDir(~ismember({rootDir.name},{'.','..'}));
TR_str=string(natsortfiles({rootDir.name}))';
nTR=length(TR_str);

% Extract the variables using regular expressions
pattern = 'USCformat_142GHz_(?<Env>[^_]+)_T(?<TXID>\d+)-R(?<RXID>\d+)_(?<TR_distance>[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?)m.mat';

% Extract using regexp
match = regexp(TR_str, pattern, 'names');

if ~isempty(match)
    % Extract the variables
    Env = string(cellfun(@(x) x.Env, match, 'UniformOutput', false));
    TXID = cellfun(@(x) str2double(x.TXID), match);
    RXID = cellfun(@(x) str2double(x.RXID), match);
    TR_distance = cellfun(@(x) str2double(x.TR_distance), match);
end

omniRes=cell(nTR,9);
%|TX ID|RX ID|TR distance|Omni PDP|OmniPL|OmniDS|OmniASA|OmniZSA|
%|OmniASD|OmniZSD|

%PL here requires True TX power and includes TX and RX ant gains

for iTR=1:nTR
    [omniPDP,oPL,oDS,oASA,oZSA,oASD,oZSD]=USCprocessing(basePath,TR_str(iTR),TR_distance(iTR),-2,12);
    omniRes{iTR,1}=TXID(iTR);
    omniRes{iTR,2}=RXID(iTR);
    omniRes{iTR,3}=TR_distance(iTR);
    omniRes{iTR,4}=omniPDP;
    omniRes{iTR,5}=oPL;
    omniRes{iTR,6}=oDS;
    omniRes{iTR,7}=oASA;
    omniRes{iTR,8}=oZSA;
    omniRes{iTR,9}=oASD;
    omniRes{iTR,10}=oZSD;
end

save("USCprocessingResults.mat","omniRes");

toc
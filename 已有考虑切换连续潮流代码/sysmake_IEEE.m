function [BusData] = sysmake_IEEE(mpc,Sbase)
%% 生成含发电机的母线卡
genall=mpc.gen;
nodnum=size(mpc.bus,1);
busall=mpc.bus;
Genout=[];
for i=1:nodnum
    j=floor(i);
    if ~any(genall(:, 1) == j)
        Genout(i,1:4)=0;
    else
        Genout(i,1:4)=genall(genall(:,1) == i,2:5)/Sbase;
    end
end
busall(:,3:4)=busall(:,3:4)/Sbase;
BusData=[busall,Genout];
% Sbase=100; %100MVA下标幺
% BusData(:,9)=(BusData(:,9)/360)*(2*pi);   % Converting degrees to radians
% BusData(:,3:4)=BusData(:,3:4)/Sbase;      % Converting P-Q in Per Unit
% BusData(:,14:17)=BusData(:,14:17)/Sbase;  % Converting P-Q in Per Unit
end
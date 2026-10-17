function [busall,genall,lineall,BusData] = sysmake1
%% 读节点卡
filename = '副本副本电路拓扑映射_已输入网架数据2.xlsx'; % 替换为实际文件路径
Node = readtable(filename, 'Sheet','节点卡');
node=Node(:,2:end);
node=table2array(node);
nodnum=size(node,1);
GBA=ones(nodnum,3);
GBA(:,1:2)=0;
Zmaxmin=ones(nodnum,3);
Zmaxmin(:,2)=1.1;
Zmaxmin(:,3)=0.9;
busall=[node(:,1:4),GBA,node(:,end),GBA(:,1),node(:,end-1),Zmaxmin];
busall(:,3:4)=busall(:,3:4)./1000;

%% 读发电机卡
genrow0=[1  0    0     300    -300    1        100      1       10000   -10000     0   0     0    0     0     0      0        0      0      0    0];
Gen = readtable(filename, 'Sheet','发电机卡（含控制参数）');
gen=table2array(Gen);
gennum=size(gen,1);
genall=ones(gennum,21).*genrow0;
gen(:,2:3)=gen(:,2:3)./1000;
genall(:,1:3)=gen(:,1:3);

%% 读线路卡
line0=[1       2      0       0     0    1000     1000    2500      1       0      1       -360    360];
Line = readtable(filename, 'Sheet','线路卡');
line=table2array(Line);
linenum=size(line,1);
lineall=ones(linenum,13).*line0;
lineall(:,1:5)=line(:,1:5);
Zb=230^2/100;% 230KV
lineall(:,3:5)=lineall(:,3:5)./Zb;
%% 生成含发电机的母线卡
Genout=[];
for i=1:nodnum
    j=floor(i);
    if ~any(genall(:, 1) == j)
        Genout(i,1:4)=0;
    else
        Genout(i,1:4)=genall(genall(:,1) == i,2:5);
    end
end
BusData=[busall,Genout];
Sbase=100; %100MVA下标幺
BusData(:,9)=(BusData(:,9)/360)*(2*pi);   % Converting degrees to radians
BusData(:,3:4)=BusData(:,3:4)/Sbase;      % Converting P-Q in Per Unit
BusData(:,14:17)=BusData(:,14:17)/Sbase;  % Converting P-Q in Per Unit
end
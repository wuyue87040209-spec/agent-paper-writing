%% 读节点卡
filename = '副本副本电路拓扑映射_已输入网架数据2.xlsx'; % 替换为实际文件路径
Node = readtable(filename, 'Sheet','节点卡');
node=Node(:,2:end);
node=table2array(node);
nodnum=length(node);
GBA=ones(nodnum,3);
GBA(:,1:2)=0;
Zmaxmin=ones(nodnum,3);
Zmaxmin(:,2)=1.1;
Zmaxmin(:,3)=0.9;
busall=[node(:,1:4),GBA,node(:,end),GBA(:,1),node(:,end-1),Zmaxmin];

%% 读发电机卡
genrow0=[1  0    0     300    -300    1        100      1       10000   -10000     0   0     0    0     0     0      0        0      0      0    0];
Gen = readtable(filename, 'Sheet','发电机卡（含控制参数）');
gen=table2array(Gen);
gennum=length(gen);
genall=ones(gennum,21).*genrow0;
gen(:,2:3)=gen(:,2:3)./1000;
genall(:,1:3)=gen(:,1:3);

%% 读线路卡
line0=[1       2      R5/4/Zb5*65       X5/4/Zb5*65     B5*4*Zb5*65    1000     1000    2500      1       0      1       -360    360];
Line = readtable(filename, 'Sheet','线路卡');
line=table2array(Line);
linenum=length(line);
lineall=ones(linenum,13).*line0;
lineall(:,1:5)=line(:,1:5);


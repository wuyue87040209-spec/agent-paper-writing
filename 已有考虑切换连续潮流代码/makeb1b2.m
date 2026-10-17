function [b1,b2] = makeb1b2
%UNTITLED4 此处显示有关此函数的摘要
%   此处显示详细说明
[busall,genall,lineall]=sysmake1;
lineZ=lineall(:,3)+lineall(:,4)*1i;
lineB=lineall(:,5)*1i;
linenum=size(lineall,1);
b1=[lineall(:,1:2),lineZ,lineB,ones(linenum,2)];
Vm=busall(:,8);
typetrans=[];
%节点外特性转化
for i=1:size(busall,1)
    if busall(i,2)==1
        typetrans(i,1)=2;
    elseif busall(i,2)==2
        typetrans(i,1)=3;
    else
        typetrans(i,1)=1;
    end
end
lod=(busall(:,3)+busall(:,4)*1i)/100;
busnum=size(busall,1);
%发电机功率填写
Genout=[];
for i=1:busnum
    j=floor(i);
    if ~any(genall(:, 1) == j)
        Genout(i,1)=0;
    else
        Genout(i,1)=(genall(genall(:,1) == i,2)+genall(genall(:,1) == i,3)*1i)/100;
    end
end
b2=[Genout,lod,Vm,Vm,zeros(busnum,1),typetrans];
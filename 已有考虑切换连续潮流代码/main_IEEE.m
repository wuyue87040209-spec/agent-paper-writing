% CPF
clc 
clear all
% close all
% ReadData_Sxia38;

%基准容量/100MVA
Sbase=100;
% 定义VSCdata
vscData=[];
% [~,genall,~,BusData]=sysmake1;
% gennum=size(genall,1);
maxiterations=100;
tolerance=1e-3;

% MC=runpf('Sxia38');
% 自定义表格
% MC=runpf('Sysmake');
% IEEE算例
mpc=case14;
MC=runpf('case14');
[BusData]=sysmake_IEEE(mpc,Sbase);
genall=mpc.gen;
gennum=size(genall,1);
[Ybus,YF,YT]=makeYbus(MC);

% 将初次潮流的结果赋给BusData
BusData(:,8)=MC.bus(:,8);% 电压幅值
BusData(:,9)=(MC.bus(:,9)/360)*(2*pi);% 电压相角

% BusData(1:gennum,14)=MC.gen(1:gennum,2)/Sbase; % 节点发电机有功功率
% BusData(1:gennum,15)=MC.gen(1:gennum,3)/Sbase; % 节点发电机无功功率

% % Sxia38个节点原系统
% BusData(1:gennum,14)=MC.gen(1:gennum,2)/Sbase; % 节点发电机有功功率
% BusData(1:gennum,15)=MC.gen(1:gennum,3)/Sbase; % 节点发电机无功功率

% 38个节点工况二：换流站（节点1）为负荷节点，同步机（节点2）为平衡节点
% BusData(2:17,14)=MC.gen(1:16,2)/Sbase; % 节点发电机有功功率
% BusData(2:17,15)=MC.gen(1:16,3)/Sbase; % 节点发电机无功功率

% % 39个节点
% BusData(30,14)=MC.gen(1,2)/Sbase; % 节点发电机有功功率
% BusData(30,15)=MC.gen(1,3)/Sbase; % 节点发电机无功功率
% BusData(32:39,14)=MC.gen(3:10,2)/Sbase; % 节点发电机有功功率
% BusData(32:39,15)=MC.gen(3:10,3)/Sbase; % 节点发电机无功功率

% % Sxia23
% BusData(2:11,14)=MC.gen(2:11,2)/Sbase; % 节点发电机有功功率
% BusData(2:11,15)=MC.gen(2:11,3)/Sbase; % 节点发电机无功功率

% 将节点按照 Slack → PV → PQ 的顺序重新排列，便于后续计算
posPV=BusData(:,2)==2;  % 找出PV节点
posSL=BusData(:,2)==3;  % 找出Slack节点（平衡节点）

aux1=(1-posPV-posSL);  % 找出PQ节点
aux1(aux1==1)=transpose(1:length(aux1(aux1==1)));% 对PQ节点进行重新编号。对于 aux1 中值为1的位置（即PQ节点），将其值更新为它们在该数组中的新索引。
auxPos=[transpose(1:length(posPV)) posPV+posSL  aux1];
% 将母线索引重新排列，生成一个新的数组
% 第一列为原始的节点编号（1到14）
% 第二列为PV和Slack节点的标记
% 第三列为重新编号的PQ节点

N=max(BusData(:,1));  % 总节点数
m=0;% PQ节点数
for i=1:N
    if BusData(i,2)==1
        m=m+1;
    end
end

for i=1:N
    if posSL(i)==1
        SL=i;% 平衡节点编号
    end
end

V=ones(N,1);  % 电压幅值初始化为1
d=zeros(N,1);  % 电压角度初始化为0

V(posSL+posPV==1)= BusData(posSL+posPV==1,8);  % 将Slack和PV节点的电压设为Bus矩阵中的额定值

%Scheduled Values
Psch= BusData(:,14)-BusData(:,3);  % 有功功率调度值=发电有功-负荷有功
Qsch= BusData(:,15)-BusData(:,4);  % 无功功率调度值=发电无功-负荷无功
% Bus矩阵的编号和matpower中不一样

Pschred=Psch(posSL==0);  % 去掉Slack节点的有功功率
Qschred=Qsch((posSL+posPV)==0);% 去掉Slack和PV节点的无功功率 

dred=d(posSL==0);% 去掉Slack节点的电压角度（平衡节点电角已知）
Vred=V((posSL+posPV)==0);% 去掉Slack和PV节点的电压幅值（这两种节点的电压幅值已知）

% K matrix is the column of PQscheduled values.
K=[Pschred;Qschred]; 
% Pis=PGi0-PLi0，Qis=QGi0-QLi0 给定的节点功率
% Si=Ui*Ii',Pi=real(Si),Qi=imag(Si)
% 构建潮流方程△Pi=Pis-Pi;△Qi=Qis-Qi
% 对于PQ和PV节点，△Pi=Pis-Pi，雅各布矩阵有d△P/dδ和d△P/dU
% 对于PV节点，△Qi=Qis-Qi，雅各布矩阵有d△Q/dδ和d△Q/dU
% 引入增长参数λ后，PGi=PGi0（1+λkGi）,QGi=QGi0（1+λkGi）;PLi=PLi0（1+λkLi）,QLi=QLi0（1+λkLi）
% 为简化计算，令kGi=kLi=1
% 潮流方程发生变化：△Pi=PGi-PLi-Pi=Pis-Pi+λPis;△Qi=QGi-QLi-Qi=Qis-Qi+λQis
% 对于PQ和PV节点，雅各布矩阵有d△P/dδ，d△P/dU以及d△P/dλ=Pis=Pschred
% 对于PV节点，雅各布矩阵有d△Q/dδ，d△Q/dU以及d△Q/dλ=Qis=Qschred
% 又[△P;△Q]=-J[dδ;dU;dλ],因此雅各布矩阵后面要扩一个列向量-K

tolerance=1e-3;
maxiterations=25;  % 最大迭代次数

BusForCPF=11;% 选择要观测的节点


% 变化速率 --> 用来指定母线 i 的负荷变化速率的系数为 λ

changefactor = 0.75; % 结束循环的一个标志

Y_Vph1=[];
Y_Vph2=[];
Y_Vph3=[];
% 无动态、无增广的原始雅各布矩阵
tzph1.j=[];
tzph2.j=[];
tzph3.j=[];
% 有动态、无增广的雅各布矩阵
tzph1.h=[];
tzph2.h=[];
tzph3.h=[];
% Ag矩阵
tzph1.f=[];
tzph2.f=[];
tzph3.f=[];
X_LamdaPh1=[];
X_LamdaPh2=[];
X_LamdaPh3=[];
dPdQredph1=[];
dPdQredph2=[];
dPdQredph3=[];
tempph1=[];
tempph3=[];

% PART 1 --> 使用负载变化作为连续参数
    sigma1=0.01;% 设置步长（根据实际情况调整）
    lambda=0;% 增长系数
    temp1=1;
    max_iterations_part1=500;  % 增加最大迭代次数限制，防止死循环
    fprintf('开始PART 1计算（λ参数化上升段）...\n');
    while temp1 <= max_iterations_part1
        % Predictor Step
            d_V_L=[dred;Vred;lambda];    % 状态向量，包括电压角度，电压幅值和负载变化系数
            [~,J]=Jacobian_NRLF(Ybus,V,d,posSL,posPV); % 计算雅各布矩阵
            % Jacobian_NRLF会返回WholeJ（完整的雅各布矩阵）和J（去掉与平衡节点相关的行和列的雅各布矩阵），~表示忽略这个不需要的输出
            ek=[zeros(1,size(J,2)) 1];  % size（J,2）为J矩阵的列数，选择切向量dlambda为连续变量
            K=[Pschred;Qschred];    % K matrix is the column of scheduled values.
            JKe=[J -K;ek];
            dpredict1=JKe\ek';
            d_V_L=d_V_L+sigma1*(JKe\ek');% 更新状态向量，JKe\ek'表示求解一个线性方程组Jke·x=ek'
            % 所得结果x表示通过雅可比矩阵反映的状态变量（电压和相位角）的修正值△x
            dred=d_V_L(1:length(dred));
			d(posSL==0)=dred;% 给除平衡节点外的电压角度赋值
            Vred=d_V_L(length(dred)+[1:length(Vred)]);% [1:length(Vred)]表示一个数组，从1到length(Vred)
			V(posSL+posPV==0)=Vred;
            lambda=d_V_L(end);
        % Corrector Step
        
            % 若采用lambda*Ssch的形式，则鼻点位置为lambda倍的发电功率及负荷
            % 若采用（1+lambda）*Ssch的形式，则鼻点位置为（lambda+1）倍的发电功率及负荷
            P=(lambda)*Psch;
            P(6)=Psch(6);% 新能源有功出力不增大
            P(8)=Psch(8);% 新能源有功出力不增大
            Q=(lambda)*Qsch;
            % Q(6)=Qsch(6);% 同步机容量不随VSC增大而增大

            [V, d,lambda,Pcalc,Qcalc,dP,dQ,dPred,dQred,dPdQredph1,tempph1,Jkeph1,J1,deltax1]=NRLF(V,d,lambda,Ybus,P,Q,posSL,posPV,tolerance,50,vscData,auxPos,BusData,K,ek,m,JKe,J);
            % Jkeph1为连续潮流里增广一阶的雅各布矩阵，J1为常规潮流里的雅各布矩阵
            
            if tempph1<50
                if ~isempty(vscData) % 数组为空，没有动态控制
                    % 将VSC节点由PV节点改为PQ节点
                    for i=1:length(vscData(:,1))
                        BusData(vscData(i,1),2)=1;
                    end
                    posPVv=BusData(:,2)==2;
                    aux1v=(1-posPVv-posSL);
                    aux1v(aux1v==1)=transpose(1:length(aux1v(aux1v==1)));
                    auxPosv=[transpose(1:length(posPVv)) posPVv+posSL  aux1v];
                    mv=0;% VSC节点改成PQ节点后的PQ节点数
                    for i=1:N
                        if BusData(i,2)==1
                            mv=mv+1;
                        end
                    end
                    % 计算拓展雅各布矩阵并在雅各布矩阵中加入VSC动态控制
                    [~,Jv1]=Jacobian_NRLF(Ybus,V,d,posSL,posPVv);
                    for k=1:length(vscData(:,1))
                        i=vscData(k,1);% VSC节点编号
                        if i<SL
                            Jv1(i,auxPosv(i,3)+N-1)=Jv1(i,auxPosv(i,3)+N-1)-BusData(i,14)/V(i);% 加一个PGi/Ui，此处J阵的计算是课本的-1
                            Jv1(N-1+auxPosv(i,3),N-1+auxPosv(i,3))=Jv1(N-1+auxPosv(i,3),N-1+auxPosv(i,3))-BusData(i,15)/V(i)+vscData(k,2)*V(i);% 加一个QGi/Ui-Kpi*Ui
                        else
                            Jv1(i-1,auxPosv(i,3)+N-1)=Jv1(i-1,auxPosv(i,3)+N-1)-BusData(i,14)/V(i);% 加一个PGi/Ui，此处J阵的计算是课本的-1
                            Jv1(N-1+auxPosv(i,3),N-1+auxPosv(i,3))=Jv1(N-1+auxPosv(i,3),N-1+auxPosv(i,3))-BusData(i,15)/V(i)+vscData(k,2)*V(i);% 加一个QGi/Ui-Kpi*Ui
                        end
                    end
                    % % 将VSC节点由PQ节点改回PV节点（防止其他用到pos的地方出现错误）
                    % for i=1:length(vscData(:,1))
                    %     BusData(vscData(i,1),2)=2;
                    % end
                end
                % 计算Ag
                % if ~isempty(vscData)
                %     [fx,fy,gx]=Calculate_DynamicMatrix(N,mv,SL,V,vscData,Psch,auxPosv,kpdc,kidc,kiac);
                %     Ag=fx-fy*(-Jv1\gx);
                %     tzph1(temp1).f=eig(Ag);
                % end
                Y_Vph1=[Y_Vph1 ; V(BusForCPF)]; % 将特定节点BusForCPF的电压值加到数组中
                X_LamdaPh1=[X_LamdaPh1;lambda];
                tzph1(temp1).j=eig(full(-J1));
                % tzph1(temp1).h=eig(full(-Jv1));
                Last_d=d;Last_V=V;Last_LamdaPh1=lambda;% 保存当前状态

                % 每10步输出一次进度
                if mod(temp1, 10) == 0
                    fprintf('  PART 1 - 步数: %d, λ=%.4f, V(%d)=%.4f\n', temp1, lambda, BusForCPF, V(BusForCPF));
                end

                temp1=temp1+1;
            else
                % Returning lambda, V and Angles(d) for the last converged iteration
                d=Last_d;
				V=Last_V;
				lambda=Last_LamdaPh1;
                dred=d(posSL==0);
				Vred=V((posSL+posPV)==0);
                break;  % If Newton Raphson does not converge.
            end
    end

    % 检查PART 1是否正常完成
    if temp1 > max_iterations_part1
        warning('PART 1达到最大迭代次数，可能未找到鼻点');
        fprintf('PART 1完成，共%%d步，最大λ=%.4f', temp1-1, Last_LamdaPh1);
    else
        fprintf('PART 1完成，共%%d步，最大λ=%.4f', temp1-1, Last_LamdaPh1);
    end

    % 检查PART 1是否有有效数据
    if isempty(X_LamdaPh1) || length(X_LamdaPh1) < 2
        error('PART 1未能生成有效数据，请检查系统参数或减小步长');
    end

% PART 2 --> 使用电压变化作为连续参数

    sigma=0.005;             % 这个阶段逼近极限，需要取小一点的步长
    Last_Lamda=Last_LamdaPh1;
    temp2=1;
    flag=1;  % 初始化flag变量，1表示lambda还在增长
    max_iterations_part2=500;  % 增加最大迭代次数限制
    fprintf('开始PART 2计算（电压参数化鼻点区域）');

    X_LamdaPh2(1)=X_LamdaPh1(end);
    Y_Vph2(1)=Y_Vph1(end);
    tzph2(1).j=tzph1(end).j;
    tzph2(1).h=tzph1(end).h;
    tzph2(1).f=tzph1(end).f;

    while temp2 <= max_iterations_part2
        % Predictor Step
            d_V_L=[dred;Vred;lambda];    % Column vector delta, V and lambda.
            [~,J]=Jacobian_NRLF(Ybus,V,d,posSL,posPV); % Calculating Jacobian matrix
            ek=[zeros(1,length(dred)+length(Vred)) 0]; 
            
            % if temp2==1
            %     [~,big]=max(abs(deltax1(N:end)));
            %     big=big+N-1;% big为最大切向量索引
            % else
            %     [~,big]=max(abs(dddVredL(N:end)));
            %     big=big+N-1;
            % end
            % ek(big)=1; % 将偏差值中的最大值对应的状态变量作为连续变量

            ek(length(dred)+auxPos(BusForCPF,3))=1; % 将特定母线电压作为连续变量
            JKe=[J -K;ek];
            ZerosOne=[zeros(length(dred)+length(Vred),1); -1];
            dph2=JKe\ZerosOne;

            % if flag==0
            %     if dph2(end)>0
            %         continue;
            %     end
            % end

            
            if abs(dph2(end))*sigma>0.1
                sigma=sigma*0.5;
            else
                d_V_L=d_V_L+sigma*dph2;
                dred=d_V_L(1:length(dred));d(posSL==0)=dred;
                Vred=d_V_L(length(dred)+[1:length(Vred)]);V(posSL+posPV==0)=Vred;
                lambda=d_V_L(end);
                % display('Predictor step -- [lambda value -- voltage at bus]');
   			    % [lambda V(BusForCPF)]
                % Corrector Step
                [~,J2]=Jacobian_NRLF(Ybus,V,d,posSL,posPV); % Calculating Jacobian matrix

                % 若采用lambda*Ssch的形式，则鼻点位置为lambda倍的发电功率及负荷
                % 若采用（1+lambda）*Ssch的形式，则鼻点位置为（lambda+1）倍的发电功率及负荷
                P=(lambda)*Psch;
                % P(2)=Psch(2);% 同步机容量不随VSC增大而增大
                P(6)=Psch(6);% 新能源有功出力不增大
                P(8)=Psch(8);% 新能源有功出力不增大
                Q=(lambda)*Qsch;
                % Q(2)=Qsch(2);% 同步机容量不随VSC增大而增大

                [Pcalc,Qcalc,dP,dQ,dPred,dQred,dPdQredph2]=Calculate_PcalcQcalc(V,d,Ybus,P,Q,posSL,posPV); % Calculating P and Q Injected
                RHS= [dPdQredph2 ; 0];% dPdQred=[dPred;dQred];
                Jkeph2=[J2 -K;ek];
                dddVredL = Jkeph2\RHS;    % 更新修正值

                if flag==0 % 已经达到最大值，曲线开始折回
                    if dddVredL(end)>0
                        continue;
                    end
                end

                d(posSL==0)=d(posSL==0)+dddVredL(1:N-1);
                V(posSL+posPV==0)=V(posSL+posPV==0)+dddVredL(N:length(dddVredL)-1);
                lambda=lambda+dddVredL(end);
                dred=d(posSL==0);
                Vred=V((posSL+posPV)==0);

                if ~isempty(vscData) % 数组为空，没有动态控制
                    % 将VSC节点由PV节点改为PQ节点
                    for i=1:length(vscData(:,1))
                        BusData(vscData(i,1),2)=1;
                    end
                    posPVv=BusData(:,2)==2;
                    aux1v=(1-posPVv-posSL);
                    aux1v(aux1v==1)=transpose(1:length(aux1v(aux1v==1)));
                    auxPosv=[transpose(1:length(posPVv)) posPVv+posSL  aux1v];
                    mv=0;% VSC节点改成PQ节点后的PQ节点数
                    for i=1:N
                        if BusData(i,2)==1
                            mv=mv+1;
                        end
                    end
                    % 计算拓展雅各布矩阵并在雅各布矩阵中加入VSC动态控制
                    [~,Jv2]=Jacobian_NRLF(Ybus,V,d,posSL,posPVv);
                    for k=1:length(vscData(:,1))
                        i=vscData(k,1);% VSC节点编号
                        if i<SL
                            Jv2(i,auxPosv(i,3)+N-1)=Jv2(i,auxPosv(i,3)+N-1)-BusData(i,14)/V(i);% 加一个PGi/Ui，此处J阵的计算是课本的-1
                            Jv2(N-1+auxPosv(i,3),N-1+auxPosv(i,3))=Jv2(N-1+auxPosv(i,3),N-1+auxPosv(i,3))-BusData(i,15)/V(i)+vscData(k,2)*V(i);% 加一个QGi/Ui-Kpi*Ui
                        else
                            Jv2(i-1,auxPosv(i,3)+N-1)=Jv2(i-1,auxPosv(i,3)+N-1)-BusData(i,14)/V(i);% 加一个PGi/Ui，此处J阵的计算是课本的-1
                            Jv2(N-1+auxPosv(i,3),N-1+auxPosv(i,3))=Jv2(N-1+auxPosv(i,3),N-1+auxPosv(i,3))-BusData(i,15)/V(i)+vscData(k,2)*V(i);% 加一个QGi/Ui-Kpi*Ui
                        end
                    end
                    % % 将VSC节点由PQ节点改回PV节点（防止其他用到pos的地方出现错误）
                    % for i=1:length(vscData(:,1))
                    %     BusData(vscData(i,1),2)=2;
                    % end
                end
                % 计算Ag
                % if ~isempty(vscData)
                %     [fx,fy,gx]=Calculate_DynamicMatrix(N,mv,SL,V,vscData,Psch,auxPosv,kpdc,kidc,kiac);
                %     % J2=J;
                %     Ag=fx-fy*(-Jv2\gx);
                %     tzph2(temp2+1).f=eig(Ag);
                % end
                Y_Vph2=[Y_Vph2 ; V(BusForCPF)];
                X_LamdaPh2=[X_LamdaPh2;lambda];
                tzph2(temp2+1).j=eig(full(-J2));
                % tzph2(temp2+1).h=eig(full(-Jv2));

                % 每10步输出一次进度
                if mod(temp2, 10) == 0
                    fprintf('  PART 2 - 步数: %d, λ=%.4f, V(%d)=%.4f\n', temp2, lambda, BusForCPF, V(BusForCPF));
                end

                temp2=temp2+1;

                if lambda > Last_Lamda
                    Last_Lamda=lambda;% 记录最大的Lamda
                    LastV=V(BusForCPF);% 记录最大Lamda所对应的V
                    flag=1;
                else
                    flag=0;
                end

                if lambda<=changefactor*Last_LamdaPh1
                    if abs(X_LamdaPh2(end)-X_LamdaPh2(end-1))>0.5
                        X_LamdaPh2(end)=[];
                        Y_Vph2(end)=[];
                        tzph2(end).j=[];
                        tzph2(end).h=[];
                        tzph2(end).f=[];
                    end
                    break;
                end
                sigma=0.005;
            end
    end

    % 检查PART 2是否正常完成
    if temp2 > max_iterations_part2
        warning('PART 2达到最大迭代次数');
    else
        fprintf('PART 2完成，共%d步，最大λ=%.4f\n', temp2-1, Last_Lamda);
    end


% PART 3 --> 使用负载变化作为连续参数
    sigma=0.01;
    temp3=1;
    max_iterations_part3=500;  % 增加最大迭代次数限制
    fprintf('开始PART 3计算（λ参数化下降段）...\n');

    while temp3 <= max_iterations_part3
        % Predictor Step
            d_V_L=[dred;Vred;lambda];    % Column vector delta, V and lambda.
            [~,J]=Jacobian_NRLF(Ybus,V,d,posSL,posPV); % Calculating Jacobian matrix

            % % 在雅各布矩阵中加入VSC动态控制
            % if ~isempty(vscData) % 数组为空，没有动态控制
            %     for k=1:length(vscData(:,1))
            %         i=vscData(k,1);% VSC节点编号
            %         J(i,auxPos(i,3)+N-1)=J(i,auxPos(i,3)+N-1)-BusData(i,14)/V(i);% 加一个PGi/Ui
            %         J(N-1+auxPos(i,3),m+auxPos(i,3))=J(N-1+auxPos(i,3),m+auxPos(i,3))-BusData(i,15)/V(i)+vscData(k,2)*V(i);% 加一个QGi/Ui-Kpi*Ui
            %     end
            % end

            ek=[zeros(1,size(J,2)) -1];  
            K=[Pschred;Qschred];    % K matrix is the column of scheduled values.
            JKe=[J -K;ek];
            d_V_L=d_V_L+sigma*(JKe\abs(ek)');
            dred=d_V_L(1:length(dred));d(posSL==0)=dred;
            Vred=d_V_L(length(dred)+[1:length(Vred)]);V(posSL+posPV==0)=Vred;
            lambda=d_V_L(end);

        % Corrector Step

            % 若采用lambda*Ssch的形式，则鼻点位置为lambda倍的发电功率及负荷
            % 若采用（1+lambda）*Ssch的形式，则鼻点位置为（lambda+1）倍的发电功率及负荷
            P=(lambda)*Psch;
            % P(2)=Psch(2);% 同步机容量不随VSC增大而增大
            P(6)=Psch(6);% 新能源有功出力不增大
            P(8)=Psch(8);% 新能源有功出力不增大
            Q=(lambda)*Qsch;
            % Q(2)=Qsch(2);% 同步机容量不随VSC增大而增大

            [V,d,lambda,Pcalc,Qcalc,dP,dQ,dPred,dQred,dPdQredph3,tempph3,Jkeph3,J3,deltax3]=NRLF(V,d,lambda,Ybus,P,Q,posSL,posPV,tolerance,maxiterations,vscData,auxPos,BusData,K,ek,m,JKe,J);

            if tempph3<maxiterations && lambda>=0

                
                if ~isempty(vscData) % 数组为空，没有动态控制
                    % 将VSC节点由PV节点改为PQ节点
                    for i=1:length(vscData(:,1))
                        BusData(vscData(i,1),2)=1;
                    end
                    posPVv=BusData(:,2)==2;
                    aux1v=(1-posPVv-posSL);
                    aux1v(aux1v==1)=transpose(1:length(aux1v(aux1v==1)));
                    auxPosv=[transpose(1:length(posPVv)) posPVv+posSL  aux1v];
                    mv=0;% VSC节点改成PQ节点后的PQ节点数
                    for i=1:N
                        if BusData(i,2)==1
                            mv=mv+1;
                        end
                    end
                    % 计算拓展雅各布矩阵并在雅各布矩阵中加入VSC动态控制
                    [~,Jv3]=Jacobian_NRLF(Ybus,V,d,posSL,posPVv);
                    for k=1:length(vscData(:,1))
                        i=vscData(k,1);% VSC节点编号
                        if i<SL
                            Jv3(i,auxPosv(i,3)+N-1)=Jv3(i,auxPosv(i,3)+N-1)-BusData(i,14)/V(i);% 加一个PGi/Ui，此处J阵的计算是课本的-1
                            Jv3(N-1+auxPosv(i,3),N-1+auxPosv(i,3))=Jv3(N-1+auxPosv(i,3),N-1+auxPosv(i,3))-BusData(i,15)/V(i)+vscData(k,2)*V(i);% 加一个QGi/Ui-Kpi*Ui
                        else
                            Jv3(i-1,auxPosv(i,3)+N-1)=Jv3(i-1,auxPosv(i,3)+N-1)-BusData(i,14)/V(i);% 加一个PGi/Ui，此处J阵的计算是课本的-1
                            Jv3(N-1+auxPosv(i,3),N-1+auxPosv(i,3))=Jv3(N-1+auxPosv(i,3),N-1+auxPosv(i,3))-BusData(i,15)/V(i)+vscData(k,2)*V(i);% 加一个QGi/Ui-Kpi*Ui
                        end
                    end
                    % % 将VSC节点由PQ节点改回PV节点（防止其他用到pos的地方出现错误）
                    % for i=1:length(vscData(:,1))
                    %     BusData(vscData(i,1),2)=2;
                    % end
                end
                % 计算Ag
                if ~isempty(vscData)
                    [fx,fy,gx]=Calculate_DynamicMatrix(N,mv,SL,V,vscData,Psch,auxPosv,kpdc,kidc,kiac);
                    Ag=fx-fy*(-Jv3\gx);
                    tzph3(temp3).f=eig(Ag);
                end
                Y_Vph3=[Y_Vph3 ; V(BusForCPF)];
                X_LamdaPh3=[X_LamdaPh3;lambda];
                tzph3(temp3).j=eig(full(-J3));
                % tzph3(temp3).h=eig(full(-Jv3));

                % 每10步输出一次进度
                if mod(temp3, 10) == 0
                    fprintf('  PART 3 - 步数: %d, λ=%.4f, V(%d)=%.4f\n', temp3, lambda, BusForCPF, V(BusForCPF));
                end

                temp3=temp3+1;
            else
                break; % if no convergence is reached.
            end
    end

    % 检查PART 3是否正常完成
    if temp3 > max_iterations_part3
        warning('PART 3达到最大迭代次数');
    else
        fprintf('PART 3完成，共%d步\n', temp3-1);
    end

    %% 取主导特征根（实部最大的）
    for i=1:length(tzph1)
        tzreal1j(i)=max(real(tzph1(i).j));
        % tzreal1h(i)=max(real(tzph1(i).h));
        % if ~isempty(vscData)
        %     tzreal1f(i)=max(real(tzph1(i).f));
        % end
    end
    if length(tzph2)>length(X_LamdaPh2)
        for i=1:length(tzph2)-1
            tzreal2j(i)=max(real(tzph2(i).j));
            % tzreal2h(i)=max(real(tzph2(i).h));
            % if ~isempty(vscData)
            %     tzreal2f(i)=max(real(tzph2(i).f));
            % end
        end
    else
        for i=1:length(tzph2)
            tzreal2j(i)=max(real(tzph2(i).j));
            % tzreal2h(i)=max(real(tzph2(i).h));
            % if ~isempty(vscData)
            %     tzreal2f(i)=max(real(tzph2(i).f));
            % end
        end
    end
    if temp3~=1
        for i=1:length(tzph3)
            tzreal3j(i)=max(real(tzph3(i).j));
            % tzreal3h(i)=max(real(tzph3(i).h));
            % if ~isempty(vscData)
            %     tzreal3f(i)=max(real(tzph3(i).h));
            % end
        end
    else
        tzreal3j=[];
        tzreal3h=[];
        tzreal3f=[];
    end

newX_Lamda=[X_LamdaPh1;X_LamdaPh2;X_LamdaPh3];
newY_V=[Y_Vph1;Y_Vph2;Y_Vph3];
newtzrealj=[tzreal1j,tzreal2j,tzreal3j];
% newtzrealh=[tzreal1h,tzreal2h,tzreal3h];
% if ~isempty(vscData)
% newtzrealf=[tzreal1f,tzreal2f,tzreal3f];
% end

% 输出计算完成信息
fprintf('\n========================================\n');
fprintf('连续潮流计算完成！\n');
fprintf('========================================\n');
fprintf('总计算点数: %d\n', length(newX_Lamda));
fprintf('  PART 1: %d 点\n', length(X_LamdaPh1));
fprintf('  PART 2: %d 点\n', length(X_LamdaPh2));
fprintf('  PART 3: %d 点\n', length(X_LamdaPh3));
fprintf('最大负荷增长系数 λ_max: %.4f\n', Last_Lamda);
fprintf('========================================\n\n');

% 把特征根曲线多余的部分剪掉
for i=1:length(newtzrealj)
    if newtzrealj(i)>0
        enoughj=i;
        break;
    end
end
% for i=1:length(newtzrealh)
%     if newtzrealh(i)>0
%         enoughh=i;
%         break;
%     end
% end
% if ~isempty(vscData)
%     if max(newtzrealf)>0
%         for i=1:length(newtzrealf)
%             if newtzrealf(i)>0
%                 enoughf=i;
%                 break;
%             end
%         end
%     else
%         enoughf=length(newtzrealf);
%     end
% end

% plot(newX_Lamda,newY_V)
figure_PV;
% hold on;
% plot(newX_Lamda,newtzrealj) % 完整的原始雅各布矩阵特征根曲线
% plot(newX_Lamda(1:enoughj),newtzrealh(1:enoughj)) % 去掉多余部分的原始雅各布矩阵特征根曲线
% plot(newX_Lamda,[real(tzph1(1:end).j(14)),real(tzph2(1:end).j(14)),real(tzph3(1:end).j(14))]);
% hold on;
% plot(newX_Lamda,newtzrealh) % 完整的扩展雅各布矩阵特征根曲线
% figure
% plot(newX_Lamda(1:enoughh),newtzrealh(1:enoughh)) % 去掉多余部分的扩展雅各布矩阵特征根曲线
% hold on;
% plot(newX_Lamda,newtzrealf) % 完整的Ag特征根曲线
% plot(newX_Lamda(1:enoughf),newtzrealf(1:enoughf)) % 去掉多余部分的Ag特征根曲线

% plot(X_LamdaPh1,Y_Vph1,'-og',X_LamdaPh2,Y_Vph2,'-*k',X_LamdaPh3,Y_Vph3,'-^r','LineWidth',2)
% xlabel('增长系数λ','FontSize',10)
% ylabel('电压(p.u.)','FontSize',10)
% title(strcat('Loadability Curve for Bus #',num2str(BusForCPF)),'Fontsize',12)
% grid on
% hold on;
ax = gca;                         % 获取当前坐标轴
ax.FontSize = 13;                  % 设置坐标轴刻度字体大小为13

% 保存数据
% kidc40.wholex=newX_Lamda;
% kidc40.wholey=newY_V;
% kidc40.x=newX_Lamda(1:find(newX_Lamda==Last_Lamda, 1));
% kidc40.y=newY_V(1:find(newX_Lamda==Last_Lamda, 1));
% kidc40.Ax=newX_Lamda(1:enoughf);
% kidc40.Atz=newtzrealf(1:enoughf);
% kidc40.sigma=sigma1;

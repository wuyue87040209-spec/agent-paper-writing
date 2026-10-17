% CPF with Renewable Energy Node Switching (V5 - With LVRT)
% 包含第一次切换（无功越限）和第二次切换（LVRT）
clc
clear all

%基准容量/100MVA
Sbase=100;

% ========== 初始化新能源配置 ==========
RE_config = initialize_RE_config();

% 定义VSCdata
vscData=[];
maxiterations=100;
tolerance=1e-3;

% IEEE算例
mpc=case14;
MC=runpf('case14');
[BusData]=sysmake_IEEE(mpc,Sbase);
genall=mpc.gen;
gennum=size(genall,1);
[Ybus,YF,YT]=makeYbus(MC);

% 将初次潮流的结果赋给BusData
BusData(:,8)=MC.bus(:,8);
BusData(:,9)=(MC.bus(:,9)/360)*(2*pi);

% 将节点按照 Slack → PV → PQ 的顺序重新排列
posPV=BusData(:,2)==2;
posSL=BusData(:,2)==3;

aux1=(1-posPV-posSL);
aux1(aux1==1)=transpose(1:length(aux1(aux1==1)));
auxPos=[transpose(1:length(posPV)) posPV+posSL  aux1];

N=max(BusData(:,1));
m=0;
for i=1:N
    if BusData(i,2)==1
        m=m+1;
    end
end

for i=1:N
    if posSL(i)==1
        SL=i;
    end
end

V=ones(N,1);
d=zeros(N,1);

% V(posSL+posPV==1)= BusData(posSL+posPV==1,8);
% 给V\theta赋初值
V= BusData(:,8);
d= BusData(:,9);


%Scheduled Values
Psch= BusData(:,14)-BusData(:,3);
Qsch= BusData(:,15)-BusData(:,4);

Pschred=Psch(posSL==0);
Qschred=Qsch((posSL+posPV)==0);

dred=d(posSL==0);
Vred=V((posSL+posPV)==0);

K=[Pschred;Qschred];

tolerance=1e-3;
maxiterations=25;

BusForCPF=11;
changefactor = 0.75;

% 初始化数据存储
Y_Vph1=[];
X_LamdaPh1=[];
tzph1.j=[];

% 切换记录
switch_record = struct();
switch_record.first_switch_step = [];
switch_record.first_switch_lambda = [];
switch_record.first_switch_node = [];
switch_record.second_switch_step = [];
switch_record.second_switch_lambda = [];
switch_record.second_switch_node = [];

% 新增：每个节点的越限检测次数
RE_overlimit_count = zeros(length(RE_config.nodes), 1);

% LVRT相关标志
LVRT_mode = false;  % 是否处于LVRT模式
LVRT_node = 0;      % 当前LVRT节点

% ========== PART 1 ==========
fprintf('\n========================================\n');
fprintf('开始PART 1计算（λ参数化上升段）\n');
fprintf('========================================\n');

sigma1=0.01;  % 基础步长
lambda=1;
temp1=1;
max_iterations_part1=500;
smooth_counter = 0;
sigma_reduction_active = false;  % 步长缩减激活标志
sigma_current = sigma1;  % 当前步长

% 保存上一步的状态
Last_d = d;
Last_V = V;
Last_lambda = lambda;
Last_Vred = Vred;
Last_dred = dred;

while temp1 <= max_iterations_part1
    % ===== 预测步 =====
    d_V_L=[dred;Vred;lambda];
    [~,J]=Jacobian_NRLF(Ybus,V,d,posSL,posPV);
    ek=[zeros(1,size(J,2)) 1];
    K=[Pschred;Qschred];
    JKe=[J -K;ek];
    dpredict1=JKe\ek';

    % 步长控制
    if LVRT_mode
        % LVRT模式：使用受控步长
        % sigma_current 已在LVRT检测时设置
    elseif smooth_counter > 0
        % 切换完成后的平滑期
        sigma_current = sigma1 * RE_config.sigma_reduction;
        smooth_counter = smooth_counter - 1;
        if smooth_counter == 0
            sigma_reduction_active = false;  % 平滑期结束
        end
    elseif sigma_reduction_active
        % 步长缩减期（检测到越限但未完成切换）
        % sigma_current 已经在检测越限时设置
    else
        % 正常步长
        sigma_current = sigma1;
    end

    d_V_L=d_V_L+sigma_current*dpredict1;
    dred=d_V_L(1:length(dred));
    d(posSL==0)=dred;
    Vred=d_V_L(length(dred)+1:length(dred)+length(Vred));
    V(posSL+posPV==0)=Vred;
    lambda=d_V_L(end);

    % ===== 校正步 =====
    P=(lambda)*Psch;
    P(6)=Psch(6);
    P(8)=Psch(8);
    Q=(lambda)*Qsch;

    % 如果有节点处于LVRT模式，应用LVRT控制方程
    if LVRT_mode && LVRT_node > 0
        node_idx = find(RE_config.nodes == LVRT_node);
        if ~isempty(node_idx)
            [P_LVRT, Q_LVRT] = apply_LVRT_control(LVRT_node, V, BusData, RE_config);
            P(LVRT_node) = P_LVRT - BusData(LVRT_node, 3);
            Q(LVRT_node) = Q_LVRT - BusData(LVRT_node, 4);
        end
    end

    [V, d,lambda,Pcalc,Qcalc,dP,dQ,dPred,dQred,dPdQredph1,tempph1,Jkeph1,J1,deltax1]=...
        NRLF(V,d,lambda,Ybus,P,Q,posSL,posPV,tolerance,50,vscData,auxPos,BusData,K,ek,m,JKe,J);

    if tempph1<50
        % ===== 检查第二次切换（LVRT） =====
        if ~LVRT_mode
            [second_switch_occurred, node_switched, V_current] = check_second_switch(BusData, V, RE_config, Sbase);

            if second_switch_occurred
                % 计算受控步长到达LVRT阈值
                node_idx = find(RE_config.nodes == node_switched);

                % 获取电压对步长的导数（从预测方向）
                V_node_idx = find((posSL+posPV)==0);
                V_node_idx = V_node_idx(V_node_idx == node_switched);

                if ~isempty(V_node_idx)
                    dV_dsigma = dpredict1(length(dred) + V_node_idx);
                else
                    dV_dsigma = 0;
                end

                % 计算到达LVRT阈值的步长
                sigma_LVRT = calculate_LVRT_step(Last_V(node_switched), RE_config.V_LVRT, dV_dsigma, sigma_current);

                % 回溯到上一步
                d = Last_d;
                V = Last_V;
                lambda = Last_lambda;
                Vred = Last_Vred;
                dred = Last_dred;

                % 使用受控步长重新预测
                d_V_L=[dred;Vred;lambda];
                d_V_L=d_V_L+sigma_LVRT*dpredict1;
                dred=d_V_L(1:length(dred));
                d(posSL==0)=dred;
                Vred=d_V_L(length(dred)+1:length(dred)+length(Vred));
                V(posSL+posPV==0)=Vred;
                lambda=d_V_L(end);

                % 横向校正：固定电压为LVRT阈值
                V(node_switched) = RE_config.V_LVRT;
                if any((posSL+posPV)==0 & (1:N)'==node_switched)
                    Vred_idx = sum((posSL+posPV)==0 & (1:N)'<node_switched) + 1;
                    Vred(Vred_idx) = RE_config.V_LVRT;
                end

                fprintf('  横向校正：固定节点 %d 电压为 %.4f p.u.\n', node_switched, RE_config.V_LVRT);

                % 标记第二次切换完成
                RE_config.second_switch(node_idx) = 1;

                % 记录切换
                switch_record.second_switch_step = [switch_record.second_switch_step; temp1];
                switch_record.second_switch_lambda = [switch_record.second_switch_lambda; lambda];
                switch_record.second_switch_node = [switch_record.second_switch_node; node_switched];

                % 进入LVRT模式
                LVRT_mode = true;
                LVRT_node = node_switched;

                fprintf('  → 第二次切换完成，进入LVRT控制模式\n');

                continue;  % 重新计算当前步
            end
        end

        % ===== 检查第一次切换（仅对未切换的PV节点） =====
        switch_occurred = false;

        for i = 1:length(RE_config.nodes)
            node = RE_config.nodes(i);

            % 如果已经完成切换（改为PQ节点），跳过
            if RE_config.first_switch(i) == 1
                continue;
            end

            % 检查节点类型是否为PV
            if BusData(node, 2) ~= 2
                continue;
            end

            % 获取新能源有功出力
            P_RE = BusData(node, 14);

            % 计算无功限值
            Q_max = P_RE * RE_config.Q_factor;
            Q_min = -Q_max;

            % 获取当前无功功率
            Q_current = Qcalc(node);

            % 检查是否越限
            if Q_current > Q_max || Q_current < Q_min
                % 越限检测次数+1
                RE_overlimit_count(i) = RE_overlimit_count(i) + 1;

                if Q_current > Q_max
                    limit_type = '上限';
                    Q_limit = Q_max;
                else
                    limit_type = '下限';
                    Q_limit = Q_min;
                end

                fprintf('\n【第%d次检测】节点 %d 无功越%s\n', RE_overlimit_count(i), node, limit_type);
                fprintf('  当前无功: %.4f p.u. (%.2f MVar)\n', Q_current, Q_current * Sbase);
                fprintf('  无功限值: %.4f p.u. (%.2f MVar)\n', Q_limit, Q_limit * Sbase);

                if RE_overlimit_count(i) == 1
                    % 第一次检测到越限：回溯，步长缩小为1/10
                    fprintf('  → 回溯，步长缩小为1/10 (%.5f)\n', sigma1 * 0.1);

                    d = Last_d;
                    V = Last_V;
                    lambda = Last_lambda;
                    Vred = Last_Vred;
                    dred = Last_dred;

                    sigma_current = sigma1 * 0.1;
                    sigma_reduction_active = true;
                    switch_occurred = true;
                    break;

                elseif RE_overlimit_count(i) == 2
                    % 第二次检测到越限：回溯，步长再缩小为1/10
                    fprintf('  → 回溯，步长再缩小为1/10 (%.6f)\n', sigma1 * 0.01);

                    d = Last_d;
                    V = Last_V;
                    lambda = Last_lambda;
                    Vred = Last_Vred;
                    dred = Last_dred;

                    sigma_current = sigma1 * 0.01;
                    sigma_reduction_active = true;
                    switch_occurred = true;
                    break;

                elseif RE_overlimit_count(i) >= 3
                    % 第三次检测到越限：回溯，固定为PQ节点
                    fprintf('  → 回溯，固定P和Q，改为PQ节点\n');

                    d = Last_d;
                    V = Last_V;
                    lambda = Last_lambda;
                    Vred = Last_Vred;
                    dred = Last_dred;

                    % 标记已切换
                    RE_config.first_switch(i) = 1;
                    RE_config.Q_fixed(i) = Q_limit;
                    RE_config.P_fixed(i) = P_RE;

                    % 将节点改为PQ类型，固定P和Q
                    BusData(node, 2) = 1;
                    BusData(node, 14) = P_RE;
                    BusData(node, 15) = Q_limit;

                    % 更新Psch和Qsch
                    Psch(node) = P_RE - BusData(node, 3);
                    Qsch(node) = Q_limit - BusData(node, 4);

                    % 更新节点索引
                    posPV = BusData(:,2) == 2;
                    aux1 = (1 - posPV - posSL);
                    aux1(aux1==1) = transpose(1:length(aux1(aux1==1)));
                    auxPos = [transpose(1:length(posPV)) posPV+posSL aux1];

                    % 重新计算PQ节点数
                    m = sum(BusData(:,2) == 1);

                    % 更新K矩阵
                    Pschred = Psch(posSL==0);
                    Qschred = Qsch((posSL+posPV)==0);
                    K = [Pschred; Qschred];

                    % 更新Vred和dred的维度
                    dred = d(posSL==0);
                    Vred = V((posSL+posPV)==0);

                    % 记录切换
                    switch_record.first_switch_step = [switch_record.first_switch_step; temp1];
                    switch_record.first_switch_lambda = [switch_record.first_switch_lambda; lambda];
                    switch_record.first_switch_node = [switch_record.first_switch_node; node];

                    % 恢复正常步长，启动平滑
                    sigma_current = sigma1;
                    sigma_reduction_active = false;
                    smooth_counter = RE_config.smooth_steps;

                    fprintf('  → 切换完成，恢复正常步长，启动平滑期\n');

                    switch_occurred = true;
                    break;
                end
            end
        end

        % 如果发生了越限检测，不保存数据，直接进入下一次迭代
        if switch_occurred
            continue;  % 不增加temp1，重新计算当前步
        end

        % 正常收敛，保存数据
        Y_Vph1=[Y_Vph1 ; V(BusForCPF)];
        X_LamdaPh1=[X_LamdaPh1;lambda];
        tzph1(temp1).j=eig(full(-J1));

        % 保存当前状态作为下一步的"上一步"
        Last_d = d;
        Last_V = V;
        Last_lambda = lambda;
        Last_Vred = Vred;
        Last_dred = dred;

        if mod(temp1, 10) == 0
            status_str = '';
            if LVRT_mode
                status_str = sprintf(' [LVRT模式: 节点%d]', LVRT_node);
            elseif smooth_counter > 0
                status_str = ' [平滑中]';
            elseif sigma_reduction_active
                status_str = sprintf(' [步长缩减: %.6f]', sigma_current);
            end
            fprintf('  步数: %d, λ=%.4f, V(%d)=%.4f%s\n', temp1, lambda, BusForCPF, V(BusForCPF), status_str);
        end

        temp1=temp1+1;
    else
        % 不收敛
        d=Last_d;
        V=Last_V;
        lambda=Last_lambda;
        dred=Last_dred;
        Vred=Last_Vred;
        break;
    end
end

% 检查PART 1完成情况
if temp1 > max_iterations_part1
    warning('PART 1达到最大迭代次数');
end
fprintf('PART 1完成，共%d步，最大λ=%.4f\n', temp1-1, lambda);

% 检查数据有效性
if isempty(X_LamdaPh1) || length(X_LamdaPh1) < 2
    error('PART 1未能生成有效数据');
end

% ========== 输出切换信息 ==========
if ~isempty(switch_record.first_switch_step)
    fprintf('\n========================================\n');
    fprintf('第一次切换汇总\n');
    fprintf('========================================\n');
    for i = 1:length(switch_record.first_switch_step)
        node_idx = find(RE_config.nodes == switch_record.first_switch_node(i));
        fprintf('切换 %d: 步数=%d, λ=%.4f, 节点=%d (检测%d次)\n', ...
            i, switch_record.first_switch_step(i), ...
            switch_record.first_switch_lambda(i), ...
            switch_record.first_switch_node(i), ...
            RE_overlimit_count(node_idx));
    end
    fprintf('========================================\n\n');
end

if ~isempty(switch_record.second_switch_step)
    fprintf('\n========================================\n');
    fprintf('第二次切换汇总（LVRT）\n');
    fprintf('========================================\n');
    for i = 1:length(switch_record.second_switch_step)
        fprintf('切换 %d: 步数=%d, λ=%.4f, 节点=%d\n', ...
            i, switch_record.second_switch_step(i), ...
            switch_record.second_switch_lambda(i), ...
            switch_record.second_switch_node(i));
    end
    fprintf('========================================\n\n');
end

% ========== 绘制PV曲线 ==========
figure;
plot(X_LamdaPh1, Y_Vph1, '-o', 'LineWidth', 2, 'MarkerSize', 4);
xlabel('负荷增长系数 λ', 'FontSize', 12);
ylabel('电压 (p.u.)', 'FontSize', 12);
title(sprintf('节点 %d 的PV曲线（含新能源双重切换）', BusForCPF), 'FontSize', 14);
grid on;

% 标记第一次切换点
if ~isempty(switch_record.first_switch_lambda)
    hold on;
    for i = 1:length(switch_record.first_switch_lambda)
        [~, idx] = min(abs(X_LamdaPh1 - switch_record.first_switch_lambda(i)));
        if ~isempty(idx)
            plot(X_LamdaPh1(idx), Y_Vph1(idx), 'r*', 'MarkerSize', 15, 'LineWidth', 2);
            text(X_LamdaPh1(idx), Y_Vph1(idx), ...
                sprintf('  第1次切换\n  节点%d', switch_record.first_switch_node(i)), ...
                'FontSize', 10, 'Color', 'red');
        end
    end
end

% 标记第二次切换点
if ~isempty(switch_record.second_switch_lambda)
    hold on;
    for i = 1:length(switch_record.second_switch_lambda)
        [~, idx] = min(abs(X_LamdaPh1 - switch_record.second_switch_lambda(i)));
        if ~isempty(idx)
            plot(X_LamdaPh1(idx), Y_Vph1(idx), 'b^', 'MarkerSize', 12, 'LineWidth', 2);
            text(X_LamdaPh1(idx), Y_Vph1(idx), ...
                sprintf('  第2次切换(LVRT)\n  节点%d', switch_record.second_switch_node(i)), ...
                'FontSize', 10, 'Color', 'blue');
        end
    end
    legend('PV曲线', '第1次切换', '第2次切换(LVRT)', 'Location', 'best');
elseif ~isempty(switch_record.first_switch_lambda)
    legend('PV曲线', '第1次切换', 'Location', 'best');
end

fprintf('\n✅ 计算完成！\n');
fprintf('总计算点数: %d\n', length(X_LamdaPh1));
fprintf('第一次切换次数: %d\n', length(switch_record.first_switch_step));
fprintf('第二次切换次数: %d\n', length(switch_record.second_switch_step));

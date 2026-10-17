% CPF with Renewable Energy Node Switching (V7 - Fixed PQ Power)
% 修复第一次切换后PQ节点的功率固定问题
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
mpc=case14change;
MC=runpf('case14change');
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
% 编号PQ节点
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

% 给V\theta赋初值
V= BusData(:,8);
d= BusData(:,9);

%Scheduled Values 赋初始功率，Psch、Qsch存放所有节点初始有功无功
Psch= BusData(:,14)-BusData(:,3);
Qsch= BusData(:,15)-BusData(:,4);
% PQ节点初始功率，变量仅存放PQ节点初始功率
Pschred=Psch(posSL==0);
Qschred=Qsch((posSL+posPV)==0);
% 初始电压、相角（相角PV+PQ节点，电压PQ节点）
dred=d(posSL==0);
Vred=V((posSL+posPV)==0);
% 潮流方程
K=[Pschred;Qschred];

tolerance=1e-3;
maxiterations=25;

BusForCPF=8;
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

% LVRT相关标志（支持多节点）
LVRT_nodes = [];  % 记录所有已进入LVRT的节点
skip_prediction = false;

% ========== PART 1 ==========
fprintf('\n========================================\n');
fprintf('开始PART 1计算（λ参数化上升段）\n');
fprintf('========================================\n');

sigma1=0.01;
lambda=1;
temp1=1;
max_iterations_part1=500;
smooth_counter = 0;
sigma_reduction_active = false;
sigma_current = sigma1;

% 保存上一步的状态
Last_d = d;
Last_V = V;
Last_lambda = lambda;
Last_Vred = Vred;
Last_dred = dred;
Last_posPV = posPV;  % 新增：保存posPV
Last_BusData = BusData;  % 新增：保存BusData
Last_Psch = Psch;  % 新增：保存Psch
Last_Qsch = Qsch;  % 新增：保存Qsch
Last_m = m;  % 新增：保存m

while temp1 <= max_iterations_part1
    % ===== 预测步 =====
    if ~skip_prediction
        % 每次都重新计算预测方向（因为维度可能改变）
        d_V_L=[dred;Vred;lambda];
        [~,J]=Jacobian_NRLF(Ybus,V,d,posSL,posPV);
        % 连续变量标记（theta V 拼lamda，01标记）
        ek=[zeros(1,size(J,2)) 1];

        % 构建K向量：已切换的新能源节点功率不随lambda变化
        K_Psch = Psch;
        K_Qsch = Qsch;
        for i = 1:length(RE_config.nodes)
            node = RE_config.nodes(i);
            if RE_config.first_switch(i) == 1
                % 已切换的节点，功率固定，K中对应元素为0（这一块固定为0？）
                K_Psch(node) = 0;
                K_Qsch(node) = 0;
            end
        end
        K_Pschred = K_Psch(posSL==0);
        K_Qschred = K_Qsch((posSL+posPV)==0);
        K = [K_Pschred; K_Qschred];

        % 预测步，求解斜率
        JKe=[J -K;ek];
        dpredict1=JKe\ek';

        % 步长控制
        if ~isempty(LVRT_nodes)
            % 有节点处于LVRT模式，使用较小步长
            sigma_current = sigma1 * RE_config.sigma_reduction;
        elseif smooth_counter > 0
            sigma_current = sigma1 * RE_config.sigma_reduction;
            smooth_counter = smooth_counter - 1;
            if smooth_counter == 0
                sigma_reduction_active = false;
            end
        elseif sigma_reduction_active
            % 步长缩减期
        else
            sigma_current = sigma1;
        end

        % 预测
        d_V_L=d_V_L+sigma_current*dpredict1;
        dred=d_V_L(1:length(dred));
        d(posSL==0)=dred;
        Vred=d_V_L(length(dred)+1:length(dred)+length(Vred));
        V(posSL+posPV==0)=Vred;
        lambda=d_V_L(end);
    else
        fprintf('  [跳过预测步，直接进行纵向校正]\n');
        skip_prediction = false;
    end

    % ===== 校正步：计算P和Q =====
    % 关键修复：正确处理新能源节点的功率
    P=(lambda)*Psch;
    Q=(lambda)*Qsch;

    % 处理新能源节点
    for i = 1:length(RE_config.nodes)
        node = RE_config.nodes(i);

        if RE_config.first_switch(i) == 0
            % 未完成第一次切换：仍为PV节点
            % P固定，Q自动计算（不需要特殊处理）
            P(node) = Psch(node);
        else
            % 已完成第一次切换：变为PQ节点
            % P和Q都固定为切换时的值
            P(node) = RE_config.P_fixed(i) - BusData(node, 3);
            Q(node) = RE_config.Q_fixed(i) - BusData(node, 4);
        end
    end

    % 对所有已进入LVRT的节点应用LVRT控制方程
    for lvrt_idx = 1:length(LVRT_nodes)
        lvrt_node = LVRT_nodes(lvrt_idx);
        node_idx = find(RE_config.nodes == lvrt_node);
        if ~isempty(node_idx)
            [P_LVRT, Q_LVRT] = apply_LVRT_control(lvrt_node, V, BusData, RE_config);
            P(lvrt_node) = P_LVRT - BusData(lvrt_node, 3);
            Q(lvrt_node) = Q_LVRT - BusData(lvrt_node, 4);
        end
    end

    % 校正函数
    [V, d,lambda,Pcalc,Qcalc,dP,dQ,dPred,dQred,dPdQredph1,tempph1,Jkeph1,J1,deltax1]=...
        NRLF(V,d,lambda,Ybus,P,Q,posSL,posPV,tolerance,50,vscData,auxPos,BusData,K,ek,m,JKe,J);

    % ===== 关键修复：NRLF后立即同步Vred和dred =====
    if tempph1<50
        Vred = V((posSL+posPV)==0);
        dred = d(posSL==0);

        % ===== 检查第二次切换（LVRT）- 支持多节点 =====
        [second_switch_occurred, node_switched, V_current] = check_second_switch(BusData, V, RE_config, Sbase);

        if second_switch_occurred
            node_idx = find(RE_config.nodes == node_switched);

            % 找到node_switched在Vred中的索引
            PQ_nodes = find((posSL+posPV)==0);
            Vred_idx = find(PQ_nodes == node_switched);

            if isempty(Vred_idx)
                warning('节点%d不在PQ节点列表中！', node_switched);
                continue;
            end

            % 获取电压对步长的导数
            dV_dsigma = dpredict1(length(dred) + Vred_idx);

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

            % 纵向校正：固定电压
            V(node_switched) = RE_config.V_LVRT;
            Vred(Vred_idx) = RE_config.V_LVRT;

            fprintf('  纵向校正：固定节点 %d 电压为 %.4f p.u.\n', node_switched, RE_config.V_LVRT);

            % 标记第二次切换完成
            RE_config.second_switch(node_idx) = 1;

            % 记录切换
            switch_record.second_switch_step = [switch_record.second_switch_step; temp1];
            switch_record.second_switch_lambda = [switch_record.second_switch_lambda; lambda];
            switch_record.second_switch_node = [switch_record.second_switch_node; node_switched];

            % 将节点加入LVRT节点列表
            LVRT_nodes = [LVRT_nodes; node_switched];

            fprintf('  → 第二次切换完成，节点 %d 进入LVRT控制模式\n', node_switched);
            fprintf('  → 当前LVRT节点: %s\n', mat2str(LVRT_nodes'));
            fprintf('  → 下一步将跳过预测，直接进行纵向校正\n');

            % 设置标志
            skip_prediction = true;

            % 重新计算P和Q（应用LVRT控制）
            P=(lambda)*Psch;
            Q=(lambda)*Qsch;

            % 处理新能源节点
            for i = 1:length(RE_config.nodes)
                node = RE_config.nodes(i);
                if RE_config.first_switch(i) == 0
                    P(node) = Psch(node);
                else
                    P(node) = RE_config.P_fixed(i) - BusData(node, 3);
                    Q(node) = RE_config.Q_fixed(i) - BusData(node, 4);
                end
            end

            % 对所有已进入LVRT的节点应用LVRT控制方程
            for lvrt_idx = 1:length(LVRT_nodes)
                lvrt_node = LVRT_nodes(lvrt_idx);
                [P_LVRT, Q_LVRT] = apply_LVRT_control(lvrt_node, V, BusData, RE_config);
                P(lvrt_node) = P_LVRT - BusData(lvrt_node, 3);
                Q(lvrt_node) = Q_LVRT - BusData(lvrt_node, 4);
            end

            % 进行纵向校正后的校正步
            fprintf('  → 进行纵向校正后的校正步\n');
            [V, d,lambda,Pcalc,Qcalc,dP,dQ,dPred,dQred,dPdQredph1,tempph1_lvrt,Jkeph1,J1,deltax1]=...
                NRLF(V,d,lambda,Ybus,P,Q,posSL,posPV,tolerance,50,vscData,auxPos,BusData,K,ek,m,JKe,J);

            if tempph1_lvrt >= 50
                warning('纵向校正后的校正步不收敛！');
                d = Last_d;
                V = Last_V;
                lambda = Last_lambda;
                Vred = Last_Vred;
                dred = Last_dred;
                break;
            end

            % 同步Vred和dred
            Vred = V((posSL+posPV)==0);
            dred = d(posSL==0);

            fprintf('  → 纵向校正完成，电压=%.4f p.u.\n', V(node_switched));

            % 保存当前状态
            Last_d = d;
            Last_V = V;
            Last_lambda = lambda;
            Last_Vred = Vred;
            Last_dred = dred;

            % 保存数据点
            Y_Vph1=[Y_Vph1 ; V(BusForCPF)];
            X_LamdaPh1=[X_LamdaPh1;lambda];
            tzph1(temp1).j=eig(full(-J1));

            temp1=temp1+1;
            continue;
        end

        % ===== 检查第一次切换 =====
        switch_occurred = false;

        for i = 1:length(RE_config.nodes)
            node = RE_config.nodes(i);

            if RE_config.first_switch(i) == 1
                continue;
            end

            % 是否已经切换
            if BusData(node, 2) ~= 2
                continue;
            end

            P_RE = BusData(node, 14);
            Q_max = P_RE * RE_config.Q_factor(i);
            Q_min = -Q_max;
            Q_current = Qcalc(node);

            if Q_current > Q_max || Q_current < Q_min
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
                    fprintf('  → 回溯，步长缩小为1/10 (%.5f)\n', sigma1 * 0.1);
                    d = Last_d;
                    V = Last_V;
                    lambda = Last_lambda;
                    Vred = Last_Vred;
                    dred = Last_dred;
                    posPV = Last_posPV;
                    BusData = Last_BusData;
                    Psch = Last_Psch;
                    Qsch = Last_Qsch;
                    m = Last_m;

                    % 重新计算K矩阵
                    Pschred = Psch(posSL==0);
                    Qschred = Qsch((posSL+posPV)==0);
                    K = [Pschred; Qschred];

                    sigma_current = sigma1 * 0.1;
                    sigma_reduction_active = true;
                    switch_occurred = true;
                    break;

                elseif RE_overlimit_count(i) == 2
                    fprintf('  → 回溯，步长再缩小为1/10 (%.6f)\n', sigma1 * 0.01);
                    d = Last_d;
                    V = Last_V;
                    lambda = Last_lambda;
                    Vred = Last_Vred;
                    dred = Last_dred;
                    posPV = Last_posPV;
                    BusData = Last_BusData;
                    Psch = Last_Psch;
                    Qsch = Last_Qsch;
                    m = Last_m;

                    % 重新计算K矩阵
                    Pschred = Psch(posSL==0);
                    Qschred = Qsch((posSL+posPV)==0);
                    K = [Pschred; Qschred];

                    sigma_current = sigma1 * 0.01;
                    sigma_reduction_active = true;
                    switch_occurred = true;
                    break;

                elseif RE_overlimit_count(i) >= 3
                    fprintf('  → 回溯，固定P和Q，改为PQ节点\n');

                    d = Last_d;
                    V = Last_V;
                    lambda = Last_lambda;
                    Vred = Last_Vred;
                    dred = Last_dred;
                    posPV = Last_posPV;
                    BusData = Last_BusData;
                    Psch = Last_Psch;
                    Qsch = Last_Qsch;

                    % 标记第一次切换完成，保存固定的P和Q
                    RE_config.first_switch(i) = 1;
                    RE_config.P_fixed(i) = P_RE;
                    RE_config.Q_fixed(i) = Q_limit;

                    fprintf('  → 保存固定功率: P=%.4f p.u., Q=%.4f p.u.\n', P_RE, Q_limit);

                    % 将节点改为PQ类型
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

                    m = sum(BusData(:,2) == 1);

                    Pschred = Psch(posSL==0);
                    Qschred = Qsch((posSL+posPV)==0);

                    % 构建K向量：已切换的新能源节点功率不随lambda变化
                    K_Psch = Psch;
                    K_Qsch = Qsch;
                    for j = 1:length(RE_config.nodes)
                        re_node = RE_config.nodes(j);
                        if RE_config.first_switch(j) == 1
                            K_Psch(re_node) = 0;
                            K_Qsch(re_node) = 0;
                        end
                    end
                    K_Pschred = K_Psch(posSL==0);
                    K_Qschred = K_Qsch((posSL+posPV)==0);
                    K = [K_Pschred; K_Qschred];

                    % 强制重新计算Vred和dred
                    dred = d(posSL==0);
                    Vred = V((posSL+posPV)==0);

                    switch_record.first_switch_step = [switch_record.first_switch_step; temp1];
                    switch_record.first_switch_lambda = [switch_record.first_switch_lambda; lambda];
                    switch_record.first_switch_node = [switch_record.first_switch_node; node];

                    sigma_current = sigma1;
                    sigma_reduction_active = false;
                    smooth_counter = RE_config.smooth_steps;

                    fprintf('  → 切换完成，恢复正常步长，启动平滑期\n');

                    switch_occurred = true;
                    break;
                end
            end
        end

        if switch_occurred
            continue;
        end

        % 正常收敛，保存数据
        Y_Vph1=[Y_Vph1 ; V(BusForCPF)];
        X_LamdaPh1=[X_LamdaPh1;lambda];
        tzph1(temp1).j=eig(full(-J1));

        % 保存当前状态
        Last_d = d;
        Last_V = V;
        Last_lambda = lambda;
        Last_Vred = Vred;
        Last_dred = dred;
        Last_posPV = posPV;
        Last_BusData = BusData;
        Last_Psch = Psch;
        Last_Qsch = Qsch;
        Last_m = m;

        if mod(temp1, 10) == 0
            status_str = '';
            if ~isempty(LVRT_nodes)
                status_str = sprintf(' [LVRT模式: 节点%s]', mat2str(LVRT_nodes'));
            elseif smooth_counter > 0
                status_str = ' [平滑中]';
            elseif sigma_reduction_active
                status_str = sprintf(' [步长缩减: %.6f]', sigma_current);
            end
            fprintf('  步数: %d, λ=%.4f, V(%d)=%.4f%s\n', temp1, lambda, BusForCPF, V(BusForCPF), status_str);
        end

        temp1=temp1+1;
    else
        d=Last_d;
        V=Last_V;
        lambda=Last_lambda;
        dred=Last_dred;
        Vred=Last_Vred;
        break;
    end
end

fprintf('PART 1完成，共%d步，最大λ=%.4f\n', temp1-1, lambda);

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
        fprintf('  固定功率: P=%.4f p.u., Q=%.4f p.u.\n', ...
            RE_config.P_fixed(node_idx), RE_config.Q_fixed(node_idx));
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
plot(X_LamdaPh1, Y_Vph1, 'LineWidth', 2, 'MarkerSize', 4);
xlabel('负荷增长系数 λ', 'FontSize', 12);
ylabel('电压 (p.u.)', 'FontSize', 12);
title(sprintf('节点 %d 的PV曲线（V7-修复PQ功率）', BusForCPF), 'FontSize', 14);
grid on;
yline(0.93, 'r--', 'LineWidth', 1.5, 'Label', '低穿退出阈值', 'LabelHorizontalAlignment', 'right',FontSize=10);

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
    % legend('PV曲线', '第1次切换', '第2次切换(LVRT)', 'Location', 'best');
elseif ~isempty(switch_record.first_switch_lambda)
    % legend('PV曲线', '第1次切换', 'Location', 'best');
end

fprintf('\n✅ 计算完成！\n');
fprintf('总计算点数: %d\n', length(X_LamdaPh1));
fprintf('第一次切换次数: %d\n', length(switch_record.first_switch_step));
fprintf('第二次切换次数: %d\n', length(switch_record.second_switch_step));

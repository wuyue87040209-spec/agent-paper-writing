% CPF with Renewable Energy Node Switching (V5-Debug)
% 带调试输出的版本，用于定位Vred索引问题
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

BusForCPF=6;
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
LVRT_mode = false;
LVRT_node = 0;

% ========== PART 1 ==========
fprintf('\n========================================\n');
fprintf('开始PART 1计算（λ参数化上升段）\n');
fprintf('========================================\n');

% 初始状态检查
fprintf('\n【初始状态检查】\n');
fprintf('总节点数N: %d\n', N);
fprintf('Slack节点数: %d\n', sum(posSL));
fprintf('PV节点数: %d\n', sum(posPV));
fprintf('PQ节点数: %d\n', sum((posSL+posPV)==0));
fprintf('V长度: %d\n', length(V));
fprintf('Vred长度: %d\n', length(Vred));
fprintf('dred长度: %d\n', length(dred));

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

while temp1 <= max_iterations_part1
    % ===== 循环开始时的一致性检查 =====
    PQ_count = sum((posSL+posPV)==0);
    if length(Vred) ~= PQ_count
        fprintf('\n❌ 错误：Vred长度(%d)与PQ节点数(%d)不匹配！\n', length(Vred), PQ_count);
        fprintf('当前步数: %d, lambda=%.4f\n', temp1, lambda);

        % 打印详细信息
        fprintf('\nposSL: ');
        fprintf('%d ', posSL);
        fprintf('\nposPV: ');
        fprintf('%d ', posPV);
        fprintf('\nPQ节点编号: ');
        PQ_nodes = find((posSL+posPV)==0);
        fprintf('%d ', PQ_nodes);
        fprintf('\n');

        error('Vred维度不一致，停止计算');
    end

    % ===== 预测步 =====
    d_V_L=[dred;Vred;lambda];
    [~,J]=Jacobian_NRLF(Ybus,V,d,posSL,posPV);
    ek=[zeros(1,size(J,2)) 1];
    K=[Pschred;Qschred];
    JKe=[J -K;ek];
    dpredict1=JKe\ek';

    % 检查预测方向维度
    expected_length = length(dred) + length(Vred) + 1;
    if length(dpredict1) ~= expected_length
        fprintf('\n❌ 错误：dpredict1长度(%d)与预期(%d)不匹配！\n', ...
            length(dpredict1), expected_length);
        error('预测方向维度错误');
    end

    % 步长控制
    if LVRT_mode
        % LVRT模式
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
                fprintf('\n【第二次切换调试信息】\n');
                fprintf('切换节点: %d\n', node_switched);
                fprintf('当前电压: %.4f p.u.\n', V_current);

                % 检查Vred和V的对应关系
                fprintf('\n=== Vred与V对应关系检查 ===\n');
                PQ_nodes = find((posSL+posPV)==0);
                fprintf('PQ节点编号: ');
                fprintf('%d ', PQ_nodes);
                fprintf('\n');
                fprintf('PQ节点数量: %d\n', length(PQ_nodes));
                fprintf('Vred长度: %d\n', length(Vred));

                fprintf('\n对应关系：\n');
                for i = 1:min(length(PQ_nodes), length(Vred))
                    fprintf('  节点%d: V=%.4f, Vred(%d)=%.4f', ...
                        PQ_nodes(i), V(PQ_nodes(i)), i, Vred(i));
                    if abs(V(PQ_nodes(i)) - Vred(i)) > 1e-6
                        fprintf(' ❌ 不匹配！');
                    else
                        fprintf(' ✓');
                    end
                    fprintf('\n');
                end
                fprintf('============================\n\n');

                % 计算受控步长
                node_idx = find(RE_config.nodes == node_switched);

                % 找到node_switched在Vred中的索引
                PQ_nodes = find((posSL+posPV)==0);
                Vred_idx = find(PQ_nodes == node_switched);

                if isempty(Vred_idx)
                    fprintf('❌ 错误：节点%d不在PQ节点列表中！\n', node_switched);
                    fprintf('PQ节点列表: ');
                    fprintf('%d ', PQ_nodes);
                    fprintf('\n');
                    error('LVRT节点不是PQ节点');
                end

                fprintf('节点%d在Vred中的索引: %d\n', node_switched, Vred_idx);

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

                % 横向校正：固定电压
                V(node_switched) = RE_config.V_LVRT;
                Vred(Vred_idx) = RE_config.V_LVRT;

                fprintf('  横向校正：固定节点 %d 电压为 %.4f p.u.\n', node_switched, RE_config.V_LVRT);
                fprintf('  更新V(%d) = %.4f\n', node_switched, V(node_switched));
                fprintf('  更新Vred(%d) = %.4f\n', Vred_idx, Vred(Vred_idx));

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

                continue;
            end
        end

        % ===== 检查第一次切换 =====
        switch_occurred = false;

        for i = 1:length(RE_config.nodes)
            node = RE_config.nodes(i);

            if RE_config.first_switch(i) == 1
                continue;
            end

            if BusData(node, 2) ~= 2
                continue;
            end

            P_RE = BusData(node, 14);
            Q_max = P_RE * RE_config.Q_factor;
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
                    sigma_current = sigma1 * 0.01;
                    sigma_reduction_active = true;
                    switch_occurred = true;
                    break;

                elseif RE_overlimit_count(i) >= 3
                    fprintf('  → 回溯，固定P和Q，改为PQ节点\n');

                    % 打印切换前状态
                    fprintf('\n【第一次切换调试信息】\n');
                    fprintf('切换前：\n');
                    fprintf('  节点%d类型: %d (PV)\n', node, BusData(node, 2));
                    fprintf('  posPV(%d) = %d\n', node, posPV(node));
                    fprintf('  PQ节点数: %d\n', sum((posSL+posPV)==0));
                    fprintf('  Vred长度: %d\n', length(Vred));

                    d = Last_d;
                    V = Last_V;
                    lambda = Last_lambda;
                    Vred = Last_Vred;
                    dred = Last_dred;

                    RE_config.first_switch(i) = 1;
                    RE_config.Q_fixed(i) = Q_limit;
                    RE_config.P_fixed(i) = P_RE;

                    BusData(node, 2) = 1;
                    BusData(node, 14) = P_RE;
                    BusData(node, 15) = Q_limit;

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
                    K = [Pschred; Qschred];

                    % 强制重新计算Vred和dred
                    dred = d(posSL==0);
                    Vred = V((posSL+posPV)==0);

                    % 打印切换后状态
                    fprintf('切换后：\n');
                    fprintf('  节点%d类型: %d (PQ)\n', node, BusData(node, 2));
                    fprintf('  posPV(%d) = %d\n', node, posPV(node));
                    fprintf('  PQ节点数: %d\n', sum((posSL+posPV)==0));
                    fprintf('  Vred长度: %d\n', length(Vred));

                    % 验证Vred长度
                    expected_Vred_length = sum((posSL+posPV)==0);
                    if length(Vred) ~= expected_Vred_length
                        fprintf('❌ 错误：Vred长度(%d)与PQ节点数(%d)不匹配！\n', ...
                            length(Vred), expected_Vred_length);
                        error('第一次切换后Vred维度错误');
                    else
                        fprintf('✓ Vred长度验证通过\n');
                    end
                    fprintf('============================\n\n');

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
        d=Last_d;
        V=Last_V;
        lambda=Last_lambda;
        dred=Last_dred;
        Vred=Last_Vred;
        break;
    end
end

fprintf('PART 1完成，共%d步，最大λ=%.4f\n', temp1-1, lambda);

% 输出切换信息
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

fprintf('\n✅ 计算完成！\n');
fprintf('总计算点数: %d\n', length(X_LamdaPh1));
fprintf('第一次切换次数: %d\n', length(switch_record.first_switch_step));
fprintf('第二次切换次数: %d\n', length(switch_record.second_switch_step));

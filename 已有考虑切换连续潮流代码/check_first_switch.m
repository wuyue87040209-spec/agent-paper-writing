function [switch_occurred, RE_config, BusData, switch_info] = check_first_switch(Qcalc, BusData, RE_config, Sbase)
% 检查新能源节点是否需要进行第一次切换（无功越限）
% 添加滞环带避免频繁切换
%
% 输入:
%   Qcalc - 计算得到的无功功率向量
%   BusData - 节点数据矩阵
%   RE_config - 新能源配置结构体
%   Sbase - 基准容量
%
% 输出:
%   switch_occurred - 是否发生切换
%   RE_config - 更新后的配置
%   BusData - 更新后的节点数据
%   switch_info - 切换信息结构体

    switch_occurred = false;
    switch_info = struct();
    switch_info.node = [];
    switch_info.Q_calc = [];
    switch_info.Q_limit = [];
    switch_info.type = '';

    % 滞环带宽度（避免频繁切换）
    hysteresis = 0.05;  % 5%的滞环带

    % 遍历所有新能源节点
    for i = 1:length(RE_config.nodes)
        node = RE_config.nodes(i);

        % 如果已经切换过，跳过
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

        % 添加滞环带，只有明显超限才触发切换
        Q_max_trigger = Q_max * (1 + hysteresis);
        Q_min_trigger = Q_min * (1 - hysteresis);

        % 获取当前无功功率
        Q_current = Qcalc(node);

        % 检查是否明显越限
        if Q_current > Q_max_trigger
            % 上限越限
            switch_occurred = true;
            switch_info.node = node;
            switch_info.Q_calc = Q_current;
            switch_info.Q_limit = Q_max;
            switch_info.type = 'upper';

            fprintf('\n【第一次切换】节点 %d ���功越上限\n', node);
            fprintf('  当前无功: %.4f p.u. (%.2f MVar)\n', Q_current, Q_current * Sbase);
            fprintf('  无功上限: %.4f p.u. (%.2f MVar)\n', Q_max, Q_max * Sbase);
            fprintf('  触发阈值: %.4f p.u. (含%.0f%%滞环)\n', Q_max_trigger, hysteresis*100);

            % 标记已切换
            RE_config.first_switch(i) = 1;
            RE_config.Q_fixed(i) = Q_max;
            RE_config.P_fixed(i) = P_RE;

            % 将节点改为PQ类型
            BusData(node, 2) = 1;
            BusData(node, 15) = Q_max;

            break;

        elseif Q_current < Q_min_trigger
            % 下限越限
            switch_occurred = true;
            switch_info.node = node;
            switch_info.Q_calc = Q_current;
            switch_info.Q_limit = Q_min;
            switch_info.type = 'lower';

            fprintf('\n【第一次切换】节点 %d 无功越下限\n', node);
            fprintf('  当前无功: %.4f p.u. (%.2f MVar)\n', Q_current, Q_current * Sbase);
            fprintf('  无功下限: %.4f p.u. (%.2f MVar)\n', Q_min, Q_min * Sbase);
            fprintf('  触发阈值: %.4f p.u. (含%.0f%%滞环)\n', Q_min_trigger, hysteresis*100);

            % 标记已切换
            RE_config.first_switch(i) = 1;
            RE_config.Q_fixed(i) = Q_min;
            RE_config.P_fixed(i) = P_RE;

            % 将节点改为PQ类型
            BusData(node, 2) = 1;
            BusData(node, 15) = Q_min;

            break;
        end
    end
end

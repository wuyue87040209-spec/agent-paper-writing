function [switch_occurred, node_switched, V_current] = check_second_switch(BusData, V, RE_config, Sbase)
% 检查第二次切换（LVRT - Low Voltage Ride Through）
% 仅对已完成第一次切换的节点进行检查
%
% 输入：
%   BusData - 节点数据
%   V - 电压幅值向量
%   RE_config - 新能源配置
%   Sbase - 基准容量
%
% 输出：
%   switch_occurred - 是否发生切换
%   node_switched - 切换的节点编号（如果没有切换则为0）
%   V_current - 当前电压值

switch_occurred = false;
node_switched = 0;
V_current = 0;

% 遍历所有新能源节点
for i = 1:length(RE_config.nodes)
    node = RE_config.nodes(i);

    % 只检查已完成第一次切换但未完成第二次切换的节点
    if RE_config.first_switch(i) == 0
        continue;  % 还未完成第一次切换，跳过
    end

    if RE_config.second_switch(i) == 1
        continue;  % 已完成第二次切换，跳过
    end

    % 检查节点类型是否为PQ（第一次切换后应该是PQ）
    if BusData(node, 2) ~= 1
        continue;
    end

    % 获取当前电压
    V_current = V(node);

    % 检查是否低于LVRT阈值
    if V_current < RE_config.V_LVRT
        fprintf('\n【第二次切换】节点 %d 电压低于LVRT阈值\n', node);
        fprintf('  当前电压: %.4f p.u.\n', V_current);
        fprintf('  LVRT阈值: %.4f p.u.\n', RE_config.V_LVRT);
        fprintf('  触发LVRT控制\n');

        switch_occurred = true;
        node_switched = node;
        return;
    end
end

end

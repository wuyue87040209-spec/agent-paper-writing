function [P_LVRT, Q_LVRT] = apply_LVRT_control(node, V, BusData, RE_config)
% 应用LVRT控制方程
%
% 输入：
%   node - 节点编号
%   V - 电压幅值向量
%   BusData - 节点数据
%   RE_config - 新能源配置
%
% 输出：
%   P_LVRT - LVRT控制下的有功功率
%   Q_LVRT - LVRT控制下的无功功率

% 找到节点在RE_config中的索引
node_idx = find(RE_config.nodes == node);

if isempty(node_idx)
    error('节点 %d 不在新能源配置中', node);
end

% 获取固定的有功和无功（第一次切换时固定的值）
P0 = RE_config.P_fixed(node_idx);
Q0 = RE_config.Q_fixed(node_idx);

% 获取当前电压
V_current = V(node);

% 应用LVRT控制方程
% P_LVRT = P0 * K1 + K0
P_LVRT = P0 * RE_config.K1 + RE_config.K0;
% P_LVRT = P0;

% Q_LVRT = Q0 + K2 * (Vset - V)
Q_LVRT = Q0 + RE_config.K2 * (RE_config.Vset - V_current)+RE_config.K3;
% Q_LVRT = Q0+0.09;

fprintf('  LVRT控制方程:\n');
fprintf('    P_LVRT = %.4f × %.2f + %.2f = %.4f p.u.\n', P0, RE_config.K1, RE_config.K0, P_LVRT);
fprintf('    Q_LVRT = %.4f + %.2f × (%.2f - %.4f) = %.4f p.u.\n', ...
    Q0, RE_config.K2, RE_config.Vset, V_current, Q_LVRT);

end

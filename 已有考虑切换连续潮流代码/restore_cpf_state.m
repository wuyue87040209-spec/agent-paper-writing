function [V, d, lambda, Vred, dred, BusData, posPV, RE_config] = restore_cpf_state(state)
% 恢复连续潮流状态
%
% 输入:
%   state - 保存的状态结构体
%
% 输出:
%   V, d, lambda - 恢复的状态变量
%   Vred, dred - 恢复的简化状态变量
%   BusData - 恢复的节点数据
%   posPV - 恢复的PV节点标记
%   RE_config - 恢复的新能源配置

    V = state.V;
    d = state.d;
    lambda = state.lambda;
    Vred = state.Vred;
    dred = state.dred;
    BusData = state.BusData;
    posPV = state.posPV;
    RE_config = state.RE_config;
end

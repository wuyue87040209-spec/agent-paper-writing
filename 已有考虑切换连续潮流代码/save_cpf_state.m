function state = save_cpf_state(V, d, lambda, Vred, dred, BusData, posPV, RE_config)
% 保存连续潮流当前状态
%
% 输入:
%   V, d, lambda - 当前状态变量
%   Vred, dred - 简化的状态变量
%   BusData - 节点数据
%   posPV - PV节点标记
%   RE_config - 新能源配置
%
% 输出:
%   state - 状态结构体

    state = struct();
    state.V = V;
    state.d = d;
    state.lambda = lambda;
    state.Vred = Vred;
    state.dred = dred;
    state.BusData = BusData;
    state.posPV = posPV;
    state.RE_config = RE_config;
end

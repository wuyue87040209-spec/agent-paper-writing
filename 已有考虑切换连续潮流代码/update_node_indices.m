function [posPV, posPQ, auxPos, m] = update_node_indices(BusData, posSL, N)
% 更新节点类型索引（在节点类型改变后调用）
%
% 输入:
%   BusData - 节点数据矩阵
%   posSL - Slack节点标记
%   N - 总节点数
%
% 输出:
%   posPV - 更新后的PV节点标记
%   posPQ - 更新后的PQ节点标记
%   auxPos - 更新后的辅助索引矩阵
%   m - PQ节点数量

    % 重新识别节点类型
    posPV = BusData(:, 2) == 2;  % PV节点
    posPQ = BusData(:, 2) == 1;  % PQ节点

    % 重新计算PQ节点数量
    m = sum(posPQ);

    % 重新构建auxPos矩阵
    aux1 = (1 - posPV - posSL);  % PQ节点标记
    aux1(aux1 == 1) = transpose(1:length(aux1(aux1 == 1)));  % 重新编号
    auxPos = [transpose(1:length(posPV)) posPV + posSL aux1];
end

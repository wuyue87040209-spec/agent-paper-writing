function sigma_LVRT = calculate_LVRT_step(V_current, V_target, dV_dsigma, sigma_current)
% 计算到达LVRT阈值所需的步长
%
% 输入：
%   V_current - 当前电压
%   V_target - 目标电压（LVRT阈值）
%   dV_dsigma - 电压对步长的导数（预测方向）
%   sigma_current - 当前步长
%
% 输出：
%   sigma_LVRT - 到达LVRT阈值所需的步长

% 计算电压差
dV = V_target - V_current;

% 如果导数接近0，使用当前步长
if abs(dV_dsigma) < 1e-6
    sigma_LVRT = sigma_current;
    return;
end

% 计算所需步长
sigma_LVRT = dV / dV_dsigma;

% 限制步长范围（避免过大或过小）
sigma_min = sigma_current * 0.1;
sigma_max = sigma_current * 2.0;

if sigma_LVRT < sigma_min
    sigma_LVRT = sigma_min;
elseif sigma_LVRT > sigma_max
    sigma_LVRT = sigma_max;
end

% 确保步长为正（如果是负的，说明方向相反，使用最小步长）
if sigma_LVRT < 0
    sigma_LVRT = sigma_min;
end

fprintf('  计算受控步长: %.6f (电压差=%.4f, 导数=%.4f)\n', sigma_LVRT, dV, dV_dsigma);

end

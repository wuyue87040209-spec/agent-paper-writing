function RE_config = initialize_RE_config()
% 初始化新能源节点配置参数
%
% 输出:
%   RE_config - 新能源配置结构体

    % 新能源节点编号
    % RE_config.nodes = [6];
    RE_config.nodes = [6, 8];
    % RE_config.nodes = [6, 8,2];

    % 第一次切换参数（无功越限）
    % RE_config.Q_factor = [0.5];  % 无功功率因数，Q_max = P * 0.4
    RE_config.Q_factor = [0.5, 0.3];  % 无功功率因数，Q_max = P * 0.4
    % RE_config.Q_factor = [0.5, 0.3 , 0.1];  % 无功功率因数，Q_max = P * 0.4

    % 第二次切换参数（低电压穿越LVRT）
    RE_config.V_LVRT = 0.9;     % LVRT触发电压阈值 (p.u.)
    RE_config.K1 = 1;         % 有功斜率系数
    RE_config.K0 = 0.0;         % 有功偏置
    RE_config.K2 = 0.0;         % 无功支撑系数
    RE_config.K3 = 0.05;         % 无功电流偏置
    RE_config.Vset = 0.9;       % 电压设定值 (p.u.)

    % 切换状态标记
    RE_config.first_switch = zeros(length(RE_config.nodes), 1);   % 第一次切换标记
    RE_config.second_switch = zeros(length(RE_config.nodes), 1);  % 第二次切换标记
    RE_config.Q_fixed = zeros(length(RE_config.nodes), 1);        % 固定的无功值
    RE_config.P_fixed = zeros(length(RE_config.nodes), 1);        % 固定的有功值（第一次切换后）

    % 平滑切换参数
    RE_config.smooth_steps = 5;      % 切换后的平滑步数
    RE_config.sigma_reduction = 0.5; % 切换后步长缩减因子

    fprintf('新能源节点配置初始化完成\n');
    fprintf('  节点编号: %s\n', mat2str(RE_config.nodes));
    fprintf('  无功因数: %.2f\n', RE_config.Q_factor);
    fprintf('  LVRT阈值: %.2f p.u.\n', RE_config.V_LVRT);
end

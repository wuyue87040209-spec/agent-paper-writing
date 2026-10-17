% V5与V6对比测试脚本
% 用于验证V6修复效果

clc;
fprintf('========================================\n');
fprintf('V5与V6版本对比测试\n');
fprintf('========================================\n\n');

fprintf('测试目的：验证Vred同步修复效果\n');
fprintf('预期结果：V6版本电压平滑，无突变\n\n');

% ========== 测试V5版本 ==========
fprintf('【1/2】运行V5版本（修复前）...\n');
fprintf('----------------------------------------\n');

try
    % 清除变量
    clear all except fprintf

    % 运行V5
    run('main_IEEE_with_switch_v5.m');

    % 保存V5结果
    V5_X_Lambda = X_LamdaPh1;
    V5_Y_V = Y_Vph1;
    V5_switch1 = switch_record.first_switch_step;
    V5_switch2 = switch_record.second_switch_step;

    fprintf('\n✅ V5版本运行完成\n');
    fprintf('  第一次切换: %d次\n', length(V5_switch1));
    fprintf('  第二次切换: %d次\n', length(V5_switch2));
    fprintf('  总计算点数: %d\n', length(V5_X_Lambda));

    % 保存图形
    saveas(gcf, 'V5_PV_curve.fig');
    saveas(gcf, 'V5_PV_curve.png');

catch ME
    fprintf('\n❌ V5版本运行失败\n');
    fprintf('错误: %s\n', ME.message);
    return;
end

fprintf('\n');
pause(2);

% ========== 测试V6版本 ==========
fprintf('【2/2】运行V6版本（修复后）...\n');
fprintf('----------------------------------------\n');

try
    % 清除变量
    clear all except fprintf V5_X_Lambda V5_Y_V V5_switch1 V5_switch2

    % 运行V6
    run('main_IEEE_with_switch_v6.m');

    % 保存V6结果
    V6_X_Lambda = X_LamdaPh1;
    V6_Y_V = Y_Vph1;
    V6_switch1 = switch_record.first_switch_step;
    V6_switch2 = switch_record.second_switch_step;

    fprintf('\n✅ V6版本运行完成\n');
    fprintf('  第一次切换: %d次\n', length(V6_switch1));
    fprintf('  第二次切换: %d次\n', length(V6_switch2));
    fprintf('  总计算点数: %d\n', length(V6_X_Lambda));

    % 保存图形
    saveas(gcf, 'V6_PV_curve.fig');
    saveas(gcf, 'V6_PV_curve.png');

catch ME
    fprintf('\n❌ V6版本运行失败\n');
    fprintf('错误: %s\n', ME.message);
    return;
end

fprintf('\n');

% ========== 对比分析 ==========
fprintf('========================================\n');
fprintf('对比分析\n');
fprintf('========================================\n\n');

% 1. 基本统计
fprintf('【基本统计】\n');
fprintf('  V5计算点数: %d\n', length(V5_X_Lambda));
fprintf('  V6计算点数: %d\n', length(V6_X_Lambda));
fprintf('  差异: %d点\n\n', abs(length(V6_X_Lambda) - length(V5_X_Lambda)));

% 2. 切换次数对比
fprintf('【切换次数】\n');
fprintf('  V5第一次切换: %d次\n', length(V5_switch1));
fprintf('  V6第一次切换: %d次\n', length(V6_switch1));
fprintf('  V5第二次切换: %d次\n', length(V5_switch2));
fprintf('  V6第二次切换: %d次\n\n', length(V6_switch2));

% 3. 电压平滑度分析
fprintf('【电压平滑度】\n');

% 计算电压变化率
V5_dV = diff(V5_Y_V);
V6_dV = diff(V6_Y_V);

% 最大电压跳变
V5_max_jump = max(abs(V5_dV));
V6_max_jump = max(abs(V6_dV));

fprintf('  V5最大电压跳变: %.6f p.u.\n', V5_max_jump);
fprintf('  V6最大电压跳变: %.6f p.u.\n', V6_max_jump);
fprintf('  改善: %.2f%%\n\n', (V5_max_jump - V6_max_jump) / V5_max_jump * 100);

% 平均电压变化率
V5_avg_dV = mean(abs(V5_dV));
V6_avg_dV = mean(abs(V6_dV));

fprintf('  V5平均电压变化: %.6f p.u./步\n', V5_avg_dV);
fprintf('  V6平均电压变化: %.6f p.u./步\n', V6_avg_dV);
fprintf('  改善: %.2f%%\n\n', (V5_avg_dV - V6_avg_dV) / V5_avg_dV * 100);

% 4. 绘制对比图
fprintf('【绘制对比图】\n');

figure('Name', 'V5 vs V6 对比', 'Position', [100, 100, 1200, 800]);

% 子图1：PV曲线对比
subplot(2, 2, 1);
plot(V5_X_Lambda, V5_Y_V, 'r-', 'LineWidth', 1.5, 'DisplayName', 'V5');
hold on;
plot(V6_X_Lambda, V6_Y_V, 'b-', 'LineWidth', 1.5, 'DisplayName', 'V6');
xlabel('λ');
ylabel('V (p.u.)');
title('PV曲线对比');
legend('Location', 'best');
grid on;

% 子图2：电压差异
subplot(2, 2, 2);
% 插值到相同的λ点
common_lambda = linspace(max(min(V5_X_Lambda), min(V6_X_Lambda)), ...
                         min(max(V5_X_Lambda), max(V6_X_Lambda)), 100);
V5_interp = interp1(V5_X_Lambda, V5_Y_V, common_lambda);
V6_interp = interp1(V6_X_Lambda, V6_Y_V, common_lambda);
V_diff = V5_interp - V6_interp;

plot(common_lambda, V_diff * 1000, 'k-', 'LineWidth', 1.5);
xlabel('λ');
ylabel('电压差异 (mV)');
title('V5与V6电压差异');
grid on;

% 子图3：电压变化率对比
subplot(2, 2, 3);
plot(V5_X_Lambda(1:end-1), abs(V5_dV), 'r-', 'LineWidth', 1.5, 'DisplayName', 'V5');
hold on;
plot(V6_X_Lambda(1:end-1), abs(V6_dV), 'b-', 'LineWidth', 1.5, 'DisplayName', 'V6');
xlabel('λ');
ylabel('|dV/dλ| (p.u.)');
title('电压变化率对比');
legend('Location', 'best');
grid on;

% 子图4：电压变化率直方图
subplot(2, 2, 4);
histogram(abs(V5_dV), 50, 'FaceColor', 'r', 'FaceAlpha', 0.5, 'DisplayName', 'V5');
hold on;
histogram(abs(V6_dV), 50, 'FaceColor', 'b', 'FaceAlpha', 0.5, 'DisplayName', 'V6');
xlabel('|dV/dλ| (p.u.)');
ylabel('频数');
title('电压变化率分布');
legend('Location', 'best');
grid on;

% 保存对比图
saveas(gcf, 'V5_vs_V6_comparison.fig');
saveas(gcf, 'V5_vs_V6_comparison.png');

fprintf('  对比图已保存\n\n');

% ========== 结论 ==========
fprintf('========================================\n');
fprintf('测试结论\n');
fprintf('========================================\n\n');

if V6_max_jump < V5_max_jump
    fprintf('✅ V6版本成功减小了电压跳变\n');
    fprintf('   改善幅度: %.2f%%\n\n', (V5_max_jump - V6_max_jump) / V5_max_jump * 100);
else
    fprintf('⚠️  V6版本未能减小电压跳变\n');
    fprintf('   需要进一步分析\n\n');
end

if V6_avg_dV < V5_avg_dV
    fprintf('✅ V6版本提高了整体平滑度\n');
    fprintf('   改善幅度: %.2f%%\n\n', (V5_avg_dV - V6_avg_dV) / V5_avg_dV * 100);
else
    fprintf('⚠️  V6版本未能提高整体平滑度\n');
    fprintf('   需要进一步分析\n\n');
end

fprintf('========================================\n');
fprintf('测试完成！\n');
fprintf('========================================\n');
fprintf('\n生成的文件：\n');
fprintf('  - V5_PV_curve.fig/png\n');
fprintf('  - V6_PV_curve.fig/png\n');
fprintf('  - V5_vs_V6_comparison.fig/png\n');

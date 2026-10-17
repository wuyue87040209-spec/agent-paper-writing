%% PV曲线
figure('Units','centimeters','Position',[10,5,20,12])
% plot(newX_Lamda,newY_V);
x=newX_Lamda;y=newY_V;
plot(x, y, 'b-', 'LineWidth', 1.5); % 绘制基础曲线
hold on; grid on; % 保持绘图窗口，显示网格

% 2. 横坐标5处画垂直线+标注"基地新能源全满发"
% xline(5, 'r--', 'LineWidth', 1.5, 'Label', '基地新能源全满发', 'LabelHorizontalAlignment', 'right',FontSize=15);
% 3. 找到X最大的点（y最大对应x，或直接取x最大值，根据你的需求二选一）
% 方式1：y值最大对应的x（电压崩溃通常是y极值点）
[~, max_idx] = max(x); 
x_crash = x(max_idx); 
% 方式2：直接取x数组的最大值（如果是x轴最大）
% x_crash = max(x);
% 4. 标注"静态电压崩溃临界点"（在极值点位置）
plot(x_crash, y(max_idx), 'ro', 'MarkerSize', 15, 'DisplayName', '崩溃点'); % 标记点
text(x_crash+0.2, y(max_idx), sprintf('SNB', x_crash), ...
    'FontSize', 10, 'Color', 'red', 'VerticalAlignment', 'middle');
% 5. 计算0.85倍崩溃点x值，画垂直线+标注"15%静稳裕度"
x_margin = x_crash * 0.85;
xline(x_margin, 'g--', 'LineWidth', 1.5, 'Label', '15%静稳裕度', 'LabelHorizontalAlignment', 'right',FontSize=15);
% 6. 图形美化（可选）
xlabel('增长系数',FontSize=15); ylabel('节点电压',FontSize=15);
title('电压稳定性分析曲线',FontSize=15);
% legend('基础曲线', '崩溃点', 'Location', 'best');
hold off;
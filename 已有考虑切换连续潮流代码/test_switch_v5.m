% 快速测试脚本 - 测试双重切换功能（V5）
% Quick Test Script for Dual Switch Functionality (V5)

clc;
fprintf('========================================\n');
fprintf('新能源节点双重切换功能测试（V5）\n');
fprintf('========================================\n\n');

try
    % 运行主程序
    fprintf('正在运行 main_IEEE_with_switch_v5...\n\n');
    main_IEEE_with_switch_v5;

    fprintf('\n========================================\n');
    fprintf('✅ 测试成功完成！\n');
    fprintf('========================================\n');

catch ME
    fprintf('\n========================================\n');
    fprintf('❌ 测试失败！\n');
    fprintf('========================================\n');
    fprintf('错误信息: %s\n', ME.message);
    fprintf('错误位置: %s (第%d行)\n', ME.stack(1).name, ME.stack(1).line);
    fprintf('========================================\n');

    % 显示详���错误信息
    fprintf('\n详细错误堆栈:\n');
    for i = 1:min(3, length(ME.stack))
        fprintf('  [%d] %s (第%d行)\n', i, ME.stack(i).name, ME.stack(i).line);
    end

    rethrow(ME);
end

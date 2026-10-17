% 测试连续潮流代码
clc;
clear all;

fprintf('========================================\n');
fprintf('连续潮流代码测试\n');
fprintf('========================================\n\n');

try
    % 运行主程序
    main_IEEE;

    fprintf('\n========================================\n');
    fprintf('测试成功完成！\n');
    fprintf('========================================\n');

catch ME
    fprintf('\n========================================\n');
    fprintf('测试失败！\n');
    fprintf('错误信息: %s\n', ME.message);
    fprintf('错误位置: %s (第%d行)\n', ME.stack(1).name, ME.stack(1).line);
    fprintf('========================================\n');
    rethrow(ME);
end

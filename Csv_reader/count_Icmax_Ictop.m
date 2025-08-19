function [Ictop,tIcm,Icmax] = count_Icmax_Ictop(num,time,ch3,path,dataname,ton1,toff1,cnton1,ton2,toff2)

%% 计算Ictop
current_interval = ton1 + fix(cnton1/2) : toff1;    % 定义电流峰值搜索区间
[~, max_idx] = max(ch3(current_interval));          % 快速定位峰值索引 max_idx为相对索引
tIcm = ton1 + fix(cnton1/2) + max_idx - 1;           % 转换为全局索引
window_start = max(1, tIcm - 10);                   % 窗口起始：峰值前10点（最小为1）
Ictop = mean(ch3(window_start:tIcm));               % 计算均值

%% Icmax 计算
[Icmax, Icmax_idx] = max(ch3(ton2:toff2));
Icmax_idx = ton2 + Icmax_idx - 1;

% 绘图
% figure;
plot(time(ton2:toff2), ch3(ton2:toff2), 'b');
hold on;
plot(time(Icmax_idx), Icmax, 'ro', 'MarkerFaceColor','r');
text(time(Icmax_idx)+0.02*range(time(ton2:toff2)), Icmax-0.1*range(ch3), ...
    ['Icmax=',num2str(Icmax),'V'], 'FontSize',13);
title(['Ic=',num2str(fix(Ictop)),' A Icmax']);
grid on;

save_dir = fullfile(path, 'pic', dataname, '01 Icmax');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
saveas(gcf, fullfile(save_dir, [ num,' Ic=',num2str(fix(Ictop)),'A Icmax.png']), 'png');
close(gcf);
hold off
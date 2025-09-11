function [Ictop,tIcm,Icmax] = count_Icmax_Ictop(num,time,ch3,path,dataname,ton1,toff1,cnton1,ton2,toff2)

%% 计算Ictop
nspd = (time(2)-time(1))*1e9;
current_interval = ton1 + fix(cnton1/2) : toff1;    % 定义电流峰值搜索区间
[~, max_idx] = max(ch3(current_interval));          % 快速定位峰值索引 max_idx为相对索引
tIcm = ton1 + fix(cnton1/2) + max_idx - 1;          % 转换为全局索引
window_start = max(1, tIcm - fix(30/nspd));        % 窗口起始：峰值前10点（最小为1）
Ictop = mean(ch3(window_start:tIcm));               % 计算均值

% plot(time(current_interval), ch3(current_interval), 'b');
% hold on;
% plot(time(tIcm), ch3(tIcm), 'ro', 'MarkerFaceColor','r');
% error('1')

%% Icmax 计算
[Icmax, Icmax_idx] = max(ch3(ton2:toff2));
Icmax_idx = ton2 + Icmax_idx - 1;

PicStart = fix((ton2 + toff2)/2 - 11*(toff2 - ton2)/20);
PicEnd = fix((ton2 + toff2)/2 + 11*(toff2 - ton2)/20);
PicLength = PicEnd - PicStart;
PicTop = fix(1.1*Icmax);
PicBottom = fix(-0.1*PicTop);
PicHeight = PicTop - PicBottom;

% 绘图
plot(time(ton2:toff2), ch3(ton2:toff2), 'b');
hold on;
plot(time(Icmax_idx), Icmax, 'ro', 'MarkerFaceColor','r');
text(time(Icmax_idx+fix(PicLength*0.05)),PicBottom + fix(PicHeight*0.9),['Icmax=',num2str(Icmax),'A'], 'FontSize',13);
ylim([PicBottom, PicTop]);
xlim([time(PicStart), time(PicEnd)]);
title(['Ic=',num2str(fix(Ictop)),' A Icmax']);
grid on;

save_dir = fullfile(path, 'pic', dataname, '01 Icmax');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
saveas(gcf, fullfile(save_dir, [ num,' Ic=',num2str(fix(Ictop)),'A Icmax.png']), 'png');
close(gcf);
hold off
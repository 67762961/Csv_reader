function [tdoff,tf] = count_Toff(num,nspd,time,ch1,Ic,Ictop,path,dataname,tIcm,toff1,ton2,toff90)

%% ================ 关断时间（Toff）计算与绘图 ================
% 关断时电流=90%时刻
toffIcm90_indices = find(Ic(tIcm-fix(ton2/10):min(toff1+50, length(Ic))) < Ictop*0.9, 1, 'first');
toffIcm90 = tIcm + toffIcm90_indices - 1;

% 关断时电流=10%时刻
toffIcm10_indices = find(Ic(toffIcm90:min(ton2, length(Ic))) < Ictop*0.1, 1, 'first');
toffIcm10 = toffIcm90 + toffIcm10_indices - 1;

% 动态索引边界保护
toff_bg_start = max(1, fix(toff90 * 0.997));
toff_bg_end = min(length(time), fix(toffIcm10 * 1.003));
toff_delay_range = toff90 : toffIcm90;  % 延迟阶段索引
toff_slope_range = toffIcm90 : toffIcm10;  % 斜率阶段索引

% 时间参数计算（单位：纳秒）
if (toffIcm90 - toff90 > 0)
    tdoff = (time(toffIcm90) - time(toff90)) * nspd * 1e9; 
else
    tdoff = 0;
end

if toffIcm10 - toffIcm90 > 0
    tf = (time(toffIcm10) - time(toffIcm90)) * nspd * 1e9;
else
    tf = 0;
end

% 绘图优化
% figure;
hold on;
% 背景区间（绿色）
plot(time(toff_bg_start:toff_bg_end), ch1(toff_bg_start:toff_bg_end), 'Color', [0.2 0.8 0.2]); 
% 延迟阶段（红色）
plot(time(toff_delay_range), ch1(toff_delay_range), 'r', 'LineWidth', 1.8); 
% 斜率阶段（蓝色）
plot(time(toff_slope_range), ch1(toff_slope_range), 'b', 'LineWidth', 1.8); 

text(time(toff90)*0.999,ch1(toff90)+1.5,['t(d)off=',num2str(tdoff),'ns'],'FontSize',13,'color','red');
text(time(toffIcm90)*1.0007,ch1(toffIcm90)-1,['tf=',num2str(tf),'ns'],'FontSize',13,'color','blue');

% 图形属性设置
grid on;
title(sprintf('Ic=%dA  Toff=%.1fns', fix(Ictop), tdoff + tf));
xlabel('Time (s)');
ylabel('Voltage (V)');
xlim([time(toff_bg_start),time(toff_bg_end)]);

% 路径处理标准化
save_dir = fullfile(path, 'pic', dataname, 'Toff');
if ~exist(save_dir, 'dir')
    mkdir(save_dir);draw
end
saveas(gcf, fullfile(save_dir, [ num,' Ic=',num2str(fix(Ictop)),'A Toff.png']), 'png');
close(gcf);
hold off
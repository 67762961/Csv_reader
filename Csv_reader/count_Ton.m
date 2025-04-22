function [tdon,tr] = count_Ton(num,nspd,time,ch1,Ic,Ictop,path,dataname,ton10,toff2)

%% ================ 开通时间（Ton）计算与绘图 ================
% 开通时电流=10%时刻（区间：ton2到toff2）
% 要求连续3个采样点超过阈值（抗噪声）
debounce_samples = 3;
for i = ton10:length(Ic)-debounce_samples
    if all(Ic(i:i+debounce_samples-1) > 0.1*Ictop)
        tonIcm10 = i;
        break;
    end
end

% 开通时电流=90%时刻（区间：tonIcm10到toff2）
tonIcm90_indices = find(Ic(tonIcm10:min(toff2, length(Ic))) > Ictop*0.9, 1, 'first');
tonIcm90 = tonIcm10 + tonIcm90_indices - 1;

% 索引边界保护
ton_bg_start = max(1, fix(ton10 * 0.997));
ton_bg_end = min(length(time), fix(tonIcm90 * 1.003));
ton_delay_range = ton10 : tonIcm10;  
ton_slope_range = tonIcm10 : tonIcm90;  

% 时间参数计算
tdon = (time(tonIcm10) - time(ton10)) * nspd * 1e9;  
tr = (time(tonIcm90) - time(tonIcm10)) * nspd * 1e9;

% 绘图优化（复用结构）
% figure;
hold on;
% 背景区间（绿色）
plot(time(ton_bg_start:ton_bg_end), ch1(ton_bg_start:ton_bg_end), 'Color', [0.2 0.8 0.2]);
% 延迟阶段（红色）
plot(time(ton_delay_range), ch1(ton_delay_range), 'r', 'LineWidth', 1.8);
% 斜率阶段（蓝色）
plot(time(ton_slope_range), ch1(ton_slope_range), 'b', 'LineWidth', 1.8);

text(time(ton10)*0.999,ch1(ton10)-1,['t(d)on=',num2str(tdon),'ns'],'FontSize',13,'color','red');
text(time(tonIcm10)*1.0005,ch1(tonIcm10)+1,['tr=',num2str(tr),'ns'],'FontSize',13,'color','blue');

% 图形属性
grid on;
title(sprintf('Ic=%dA  Ton=%.1fns', fix(Ictop), tr + tdon));
xlabel('Time (s)');
ylabel('Voltage (V)');
xlim([time(ton_bg_start),time(ton_bg_end)]);

% 标准化保存路径
save_dir = fullfile(path, 'pic', dataname, 'Ton');
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end
saveas(gcf, fullfile(save_dir, [ num,' Ic=',num2str(fix(Ictop)),'A Ton.png']), 'png');
close(gcf);
hold off
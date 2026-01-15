function [I2dt_on,I2dt_off] = count_i2dt(num,DPI,time,I_cap,Ictop,path,dataname,cntVge,Tdidt)

cntsw = length(cntVge);
ton1=cntVge(cntsw-3);
toff1=cntVge(cntsw-2);
toff2=cntVge(cntsw);
cnton1 = toff1-ton1;

valid_rise_start = Tdidt(1);
valid_fall_start = Tdidt(3);

I2_cap = I_cap .* I_cap;

% 开通I2dt计算
I2_on_window = valid_rise_start-fix(cnton1/5):toff2;
dt = diff(time(I2_on_window)); % 时间差分
I2dt_on = sum(I2_cap(I2_on_window(2:end)) .* dt)*1e6;
time_window_on = time(I2_on_window); % 获取开通窗口的时间向量
I2_data_on = I2_cap(I2_on_window); % 获取开通窗口的电流平方数据
I2dt_integral_on = cumtrapz(time_window_on, I2_data_on)*1e6; % 计算累积积分
max_I_cap_on = max(abs(max(I_cap(I2_on_window))), abs(min(I_cap(I2_on_window))));

I2_off_window = valid_fall_start:valid_rise_start;
dt = diff(time(I2_off_window)); % 时间差分
I2dt_off = sum(I2_cap(I2_off_window(2:end)) .* dt)*1e6;
time_window_off = time(I2_off_window); % 获取开通窗口的时间向量
I2_data_off = I2_cap(I2_off_window); % 获取开通窗口的电流平方数据
I2dt_integral_off = cumtrapz(time_window_off, I2_data_off)*1e6; % 计算累积积分
max_I_cap_off = max(abs(max(I_cap(I2_off_window))), abs(min(I_cap(I2_off_window))));


% 可视化设置
PicStart = I2_on_window(1);
PicEnd = I2_on_window(end);
PicLength = PicEnd - PicStart;

close all;
figure('Position', [320, 240, 1600/DPI/DPI, 600/DPI/DPI]);
subplot('Position', [0.05, 0.15, 0.4, 0.75]);
hold on
yyaxis left
plot(time(PicStart:PicEnd),I_cap(PicStart:PicEnd),'b');
plot(time(I2_on_window(1)), I_cap(I2_on_window(1)),'o','color','red');
plot(time(I2_on_window(end)), I_cap(I2_on_window(end)),'o','color','red');
plot(time(PicStart:PicEnd),I2_cap(PicStart:PicEnd).*2/max_I_cap_on,'g', 'LineWidth', 1.2);
ylim([-1.5*max_I_cap_on,3*max_I_cap_on]);
yyaxis right
plot(time_window_on, I2dt_integral_on, 'r', 'LineWidth', 1.2);
ylim([-0.2*I2dt_on,1.2*I2dt_on]);
xlim([time(PicStart),time(PicEnd)]);
title(sprintf('Ic=%dA 开通时电容I2dt计算', fix(Ictop)));
text(time(PicStart+fix(PicLength*0.05)),1.1*I2dt_on,['I2dt_o_n=',num2str(I2dt_on),'mA2S'],'FontSize',13);
grid on;

PicStart = I2_off_window(1)-fix(cnton1*1/5);
PicEnd = I2_off_window(end);
PicLength = PicEnd - PicStart;

subplot('Position', [0.55, 0.15, 0.4, 0.75]);
hold on
yyaxis left
plot(time(PicStart:PicEnd),I_cap(PicStart:PicEnd),'b');
plot(time(I2_off_window(1)), I_cap(I2_off_window(1)),'o','color','red');
plot(time(I2_off_window(end)), I_cap(I2_off_window(end)),'o','color','red');
plot(time(PicStart:PicEnd),I2_cap(PicStart:PicEnd).*2/max_I_cap_off,'g', 'LineWidth', 1.2);
ylim([-1.5*max_I_cap_off,3*max_I_cap_off]);
yyaxis right
plot(time_window_off, I2dt_integral_off, 'r', 'LineWidth', 1.2);
ylim([-0.2*I2dt_off,1.2*I2dt_off]);
xlim([time(PicStart),time(PicEnd)]);
title(sprintf('Ic=%dA 关断时电容I2dt计算', fix(Ictop)));
text(time(PicStart+fix(PicLength*0.05)),1.1*I2dt_off,['I2dt_o_f_f=',num2str(I2dt_off),'mA2S'],'FontSize',13);
grid on;

save_dir = fullfile(path, 'result', dataname, '09 I2dt');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
saveas(gcf, fullfile(save_dir, [ num, ' Ic=',num2str(fix(Ictop)),'A I2dt.png']), 'png');
close(gcf)
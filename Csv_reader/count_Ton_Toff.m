function [tdon,tr,tdoff,tf] = count_Ton_Toff(num,time,ch1,Ic,Ictop,path,dataname,tIcm,cntVge,ton10,toff90,tonIcm10,tonIcm90)

cntsw = length(cntVge);
toff1=cntVge(cntsw-2);
ton2=cntVge(cntsw-1);

%% ================ 开通时间（Ton）计算与绘图 ================
% 索引边界保护
% ton_bg_start = max(1, fix(ton10 * 0.997));
ton_bg_end = min(length(time), fix(tonIcm90 * 1.003));
ton_delay_range = ton10 : tonIcm10;
ton_slope_range = tonIcm10 : tonIcm90;

% 时间参数计算
if tonIcm10 - ton10 > 0
    tdon = (time(tonIcm10) - time(ton10))* 1e9;
else
    tdon = 0;
end

if tonIcm90 - tonIcm10 > 0
    tr = (time(tonIcm90) - time(tonIcm10)) * 1e9;
else
    tr = 0;
end

%% ================ 关断时间（Toff）计算与绘图 ================
% 关断时电流=90%时刻
toffIcm90_indices = find(Ic(tIcm+100:min(toff1+fix(ton2/10), length(Ic))) < Ictop*0.9, 1, 'first');
toffIcm90 = tIcm+100 + toffIcm90_indices - 1;
if isempty(toffIcm90_indices)
    print('关断时电流=90%时刻识别失败')
    error('关断时电流=90%时刻识别失败')
end

% 关断时电流=10%时刻
toffIcm10_indices = find(Ic(toffIcm90:min(ton2, length(Ic))) < Ictop*0.1, 1, 'first');
toffIcm10 = toffIcm90 + toffIcm10_indices - 1;
if isempty(toffIcm90_indices)
    print('关断时电流=10%时刻识别失败')
    error('关断时电流=10%时刻识别失败')
end

% 动态索引边界保护
toff_bg_start = max(1, fix(toff90 * 0.997));
% toff_bg_end = min(length(time), fix(toffIcm10 * 1.003));
toff_delay_range = toff90 : toffIcm90;  % 延迟阶段索引
toff_slope_range = toffIcm90 : toffIcm10;  % 斜率阶段索引

% 时间参数计算（单位：纳秒）
if (toffIcm90 - toff90 > 0)
    tdoff = (time(toffIcm90) - time(toff90)) * 1e9;
else
    tdoff = 0;
end

if toffIcm10 - toffIcm90 > 0
    tf = (time(toffIcm10) - time(toffIcm90)) * 1e9;
else
    tf = 0;
end

%% ================ 绘图 ================

PicLength = fix((ton2 - toff1)*2/11);
PicStart = toff_bg_start - PicLength;
PicEnd = ton_bg_end + PicLength;
% PicLength = PicEnd - PicStart;

hold on;
% 背景区间（绿色）
plot(time(PicStart:PicEnd), ch1(PicStart:PicEnd), 'Color', [0.2 0.8 0.2]);
% 延迟阶段（红色）
plot(time(ton_delay_range), ch1(ton_delay_range), 'r', 'LineWidth', 1.8);
% 斜率阶段（蓝色）
plot(time(ton_slope_range), ch1(ton_slope_range), 'b', 'LineWidth', 1.8);

text(time(ton10)*0.999,ch1(ton10)-1,['t(d)on=',num2str(tdon),'ns'],'FontSize',13,'color','red');
text(time(tonIcm90)*1.0005,ch1(tonIcm90)+1,['tr=',num2str(tr),'ns'],'FontSize',13,'color','blue');

% 延迟阶段（红色）
plot(time(toff_delay_range), ch1(toff_delay_range), 'r', 'LineWidth', 1.8);
% 斜率阶段（蓝色）
plot(time(toff_slope_range), ch1(toff_slope_range), 'b', 'LineWidth', 1.8);

text(time(toff90)*1.0005,ch1(toff90)+1,['t(d)off=',num2str(tdoff),'ns'],'FontSize',13,'color','red');
text(time(toffIcm10)*0.999,ch1(toffIcm10)-1,['tf=',num2str(tf),'ns'],'FontSize',13,'color','blue');

% 图形属性
grid on;
title(sprintf('Ic=%dA  Ton=%.1fns Toff=%.1fns', fix(Ictop), tr + tdon, tdoff + tf));
xlabel('Time (s)');
ylabel('Voltage (V)');
xlim([time(PicStart),time(PicEnd)]);

% 标准化保存路径
save_dir = fullfile(path, 'result', dataname, '06 Ton & Toff');
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end
saveas(gcf, fullfile(save_dir, [ num,' Ic=',num2str(fix(Ictop)),'A Ton & Toff.png']), 'png');
close(gcf);
hold off

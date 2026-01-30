function [tdon,tr,tdoff,tf,Vgetop,Vgebase] = count_Ton_Toff(num,DPI,time,ch1,ch_,Ictop,path,dataname,cntVge,Type_Td_dt,Td_dt)

cntsw = length(cntVge);
ton1=cntVge(cntsw-3);
toff1=cntVge(cntsw-2);
ton2=cntVge(cntsw-1);
toff2=cntVge(cntsw);

valid_rise_start = Td_dt(1);
valid_rise_end = Td_dt(2);
valid_fall_start = Td_dt(3);
valid_fall_end = Td_dt(4);

PicLength = fix((ton2 - toff1)*2/11);
PicStart = max(ton1 - PicLength,1);
PicEnd = min(toff2 + 2*PicLength,length(ch1));
PicLength = PicEnd - PicStart;
PicTop = 20;
PicBottom = -15;

%% ================ Vgetop计算 ================
% 计算Vge高电平电压（使用中值避免噪声干扰）
% Vgemax = max(ch1);
ch1_po = ch1(PicStart:PicEnd);
ch1_po = ch1_po(ch1_po>=0);
High_Thresh = quantile(ch1_po, 0.95);
Low_Thresh = quantile(ch1_po, 0.90);
ch1_top = ch1_po((Low_Thresh <= ch1_po)&(ch1_po <= High_Thresh));
Vgetop = median(ch1_top);

% 寻找关断时Vge=90%的时间点
% disp(ch1(toff1:-1:ton1))
toff90_indices = find(ch1(toff1:-1:ton1) > 0.9 * Vgetop, 1, 'first');
toff90 = toff1 - toff90_indices + 1; % 转换为原始索引
if isempty(toff90_indices)
    print('关断时Vge=90%的时间点识别失败')
    error('关断时Vge=90%的时间点识别失败')
end

% Vgemin = min(ch1(toff1:ton2));
ch1_ne = ch1(PicStart:PicEnd);
ch1_ne = ch1_ne(ch1_ne<=0);
High_Thresh = quantile(ch1_ne, 0.50);
Low_Thresh = quantile(ch1_ne, 0.10);
ch1_base = ch1_ne((Low_Thresh <= ch1_ne)&(ch1_ne <= High_Thresh));
Vgebase = median(ch1_base);
% 寻找开通时Vge=10%的时间点
% disp(ch1(ton2:-1:toff1))
ton10_indices = find(ch1(ton2:-1:toff1) < 0.8 * Vgebase, 1, 'first');
ton10 = ton2 - ton10_indices + 1;
if isempty(ton10_indices)
    print('开通时Vge=10%的时间点识别失败')
    error('开通时Vge=10%的时间点识别失败')
end

%% ================ 开通时间（Ton）计算与绘图 ================
% 索引边界保护
ton_delay_range = ton10 : valid_rise_start;
ton_slope_range = valid_rise_start : valid_rise_end;

% 时间参数计算
if  valid_rise_start - ton10 > 0
    tdon = (time(valid_rise_start) - time(ton10))* 1e9;
else
    tdon = 0;
end

if valid_rise_end - valid_rise_start > 0
    tr = (time(valid_rise_end) - time( valid_rise_start)) * 1e9;
else
    tr = 0;
end

%% ================ 关断时间（Toff）计算与绘图 ================
% 关断时电流=90%时刻
toff_delay_range = toff90 : valid_fall_start;  % 延迟阶段索引
toff_slope_range = valid_fall_start : valid_fall_end;  % 斜率阶段索引

% 时间参数计算（单位：纳秒）
if (valid_fall_start - toff90 > 0)
    tdoff = (time(valid_fall_start) - time(toff90)) * 1e9;
else
    tdoff = 0;
end

if valid_fall_end - valid_fall_start > 0
    tf = (time(valid_fall_end) - time(valid_fall_start)) * 1e9;
else
    tf = 0;
end

%% ================ 绘图 ================

close all;
figure('Position', [320, 240, 1600/DPI/DPI, 600/DPI/DPI]);
hold on;
% 背景区间（绿色）
plot(time(PicStart:PicEnd), ch1(PicStart:PicEnd), 'Color', [0.2 0.8 0.2]);
% 延迟阶段（红色）
plot(time(ton_delay_range), ch1(ton_delay_range), 'r', 'LineWidth', 1.8);
% 斜率阶段（蓝色）
plot(time(ton_slope_range), ch1(ton_slope_range), 'b', 'LineWidth', 1.8);

plot(time(ton10), ch1(ton10),'o','color','red');
plot(time(toff90), ch1(toff90),'o','color','red');

line([time(PicStart),time(PicEnd)],[Vgetop, Vgetop], 'Color', [0.7 0.7 0.7]);
text(time(PicStart+fix(PicLength*0.35)),Vgetop+1,['Vgetop=',num2str(Vgetop),'V'],'FontSize',13,'color',[0.7 0.7 0.7]);

line([time(PicStart),time(PicEnd)],[Vgebase, Vgebase], 'Color', [0.7 0.7 0.7]);
text(time(PicStart+fix(PicLength*0.3)),Vgebase-1.2,['Vgebase=',num2str(Vgebase),'V'],'FontSize',13,'color',[0.7 0.7 0.7]);

text(time(ton10+fix(0.03*PicLength)),ch1(ton10),['t(d)on=',num2str(tdon),'ns'],'FontSize',13,'color','red');
text(time(valid_rise_end+fix(0.03*PicLength)),ch1(valid_rise_end)+1,['tr=',num2str(tr),'ns'],'FontSize',13,'color','blue');

% 延迟阶段（红色）
plot(time(toff_delay_range), ch1(toff_delay_range), 'r', 'LineWidth', 1.8);
% 斜率阶段（蓝色）
plot(time(toff_slope_range), ch1(toff_slope_range), 'b', 'LineWidth', 1.8);

text(time(toff90+fix(0.03*PicLength)),ch1(toff90),['t(d)off=',num2str(tdoff),'ns'],'FontSize',13,'color','red');
text(time(valid_fall_end+fix(0.03*PicLength)),ch1(valid_fall_end),['tf=',num2str(tf),'ns'],'FontSize',13,'color','blue');

ch_Max = max(ch_(PicStart:PicEnd));
ch_Min = min(ch_(PicStart:PicEnd));
range = (ch_Max - ch_Min)/5;
ch_ = ch_/range - 12;

plot(time(PicStart:PicEnd), ch_(PicStart:PicEnd), 'g', 'LineWidth', 0.5);
plot(time(ton_slope_range), ch_(ton_slope_range), 'b', 'LineWidth', 0.5);
plot(time(ton_delay_range), ch_(ton_delay_range), 'r', 'LineWidth', 0.5);
plot(time(toff_slope_range), ch_(toff_slope_range), 'b', 'LineWidth', 0.5);
plot(time(toff_delay_range), ch_(toff_delay_range), 'r', 'LineWidth', 0.5);

% 图形属性
grid on;
switch Type_Td_dt
    case 'Tdidt'
        title(sprintf('Ic=%dA Ton=%.1fns Toff=%.1fns (didt)', fix(Ictop), tr + tdon, tdoff + tf));
    case 'Tdvdt'
        title(sprintf('Ic=%dA Ton=%.1fns Toff=%.1fns (dvdt)', fix(Ictop), tr + tdon, tdoff + tf));
    otherwise
        title(sprintf('Ic=%dA Ton=%.1fns Toff=%.1fns', fix(Ictop), tr + tdon, tdoff + tf));
end
xlabel('Time (s)');
ylabel('Voltage (V)');
xlim([time(PicStart),time(PicEnd)]);
ylim([PicBottom, PicTop]);

% 标准化保存路径
save_dir = fullfile(path, 'result', dataname, '06 Ton & Toff');
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end
saveas(gcf, fullfile(save_dir, [ num,' Ic=',num2str(fix(Ictop)),'A Ton & Toff.png']), 'png');
close(gcf);
hold off

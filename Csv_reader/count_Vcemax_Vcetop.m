function [Vcemax,Vcetop,ton10,toff90] = count_Vcemax_Vcetop(num,time,Vge,ch2,Ictop,path,dataname,ton1,toff1,cnton1,cntoff1,ton2,toff2)

%% Vcetop Ictop 计算
% 计算Vge高电平电压（使用中值避免噪声干扰）
[Vgemax,T_Vgemax] = max(Vge(ton1:ton2));
T_Vgemax = ton1 + T_Vgemax - 1; % 转换为全局索引
vge_high_interval = fix(T_Vgemax - cnton1/10) : fix(T_Vgemax);
meanVgetop = median(Vge(vge_high_interval)); % 中值滤波
if (meanVgetop < 0.9*Vgemax)
    fprintf('Vgetop检测:\n')
    fprintf('       Vgetop(%03f) 小于0.9倍 Vgemax(%03f), 将用 0.9Vgemax 代替 Vgetop \n',meanVgetop,Vgemax)
    meanVgetop = 0.9*Vgemax;
end
% 寻找关断时Vge=90%的时间点
toff90_indices = find(Vge(toff1:-1:ton1) > 0.9 * meanVgetop, 1, 'first');
toff90 = toff1 - toff90_indices + 1; % 转换为原始索引
if isempty(toff90_indices)
    print('关断时Vge=90%的时间点识别失败')
    error('关断时Vge=90%的时间点识别失败')
end

% 寻找开通时Vge=10%的时间点
ton10_indices = find(Vge(ton2:toff2) > 0.1 * meanVgetop, 1, 'first');
ton10 = ton2 + ton10_indices - 1;
if isempty(ton10_indices)
    print('开通时Vge=10%的时间点识别失败')
    error('开通时Vge=10%的时间点识别失败')
end

% 计算Vcetop
start_idx = fix(toff1 + cntoff1/20);         % 起始索引：关断后1/20周期
end_idx = fix(ton2 - 3*cntoff1/20);          % 结束索引：下一次导通前1/20周期
Vcetop = mean(ch2(start_idx:end_idx));       % 使用均值

%% Vcemax计算
% 找出最大值
cnton2 = toff2 - ton2;
[Vcemax, cemax_idx] = max(ch2(toff90-cnton2:fix(toff90+cnton2)));
cemax_idx = toff90 - cnton2 + cemax_idx - 1;  % 转换为全局索引

% 绘图

PicStart = fix(cemax_idx - cnton2/2);
PicEnd = fix(cemax_idx + cnton2);
PicLength = PicEnd - PicStart;
PicTop = fix(1.15*Vcemax);
PicBottom = fix(-0.1*PicTop);
PicHeight = PicTop - PicBottom;

plot(time(PicStart:PicEnd), ch2(PicStart:PicEnd), 'b');
hold on;
plot(time(cemax_idx), Vcemax, 'ro', 'MarkerFaceColor','r');
text((time(fix(cemax_idx+0.05*PicLength))), Vcemax + 0.05*PicHeight, ['Vcemax=',num2str(Vcemax),'V'], 'FontSize',13);
ylim([PicBottom, PicTop]);
xlim([time(PicStart), time(PicEnd)]);
title(['Ic=',num2str(fix(Ictop)),'A Vcemax']);
grid on;

% 路径构建优化
save_dir = fullfile(path, 'pic', dataname, '02 Vcemax');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
saveas(gcf, fullfile(save_dir, [ num, ' Ic=',num2str(fix(Ictop)),'A Vcemax.png']), 'png');
close(gcf);
hold off


function [Eoff,SWoff_start,SWoff_stop] = count_Eoff(num,time,Ic,Vce,Ictop,Vcetop,path,dataname,ton2,ton1,cnton1)

%% ====================== 关断损耗计算（Eoff） ======================
%关断起始时刻寻找
valid_range = (ton1+fix(0.7*cnton1)):min(ton2, length(Vce));
SWoff_start_indices = find(Vce(valid_range) >= Vcetop*0.1, 1, 'first');
SWoff_start = valid_range(1) + SWoff_start_indices - 1;
if isempty(SWoff_start_indices)
    print('Eoff计算起点识别失败')
    error('Eoff计算起点识别失败')
end

%关断结束时刻寻找
valid_range = SWoff_start:min(ton2, length(Ic));
SWoff_stop_indices = find(Ic(valid_range) <= Ictop*0.02, 1, 'first');
SWoff_stop = valid_range(1) + SWoff_stop_indices - 1;
for i = 1:18
    if ~isempty(SWoff_stop_indices)
        break;
    end
    SWoff_stop_indices = find(Ic(valid_range) <= Ictop*(0.02+i/100), 1, 'first');
    SWoff_stop = valid_range(1) + SWoff_stop_indices - 1;
    if i == 1
        fprintf('Eon计算:\n')
    end
    fprintf('       未找到 0.02 Ictop 作为 Eoff 计算结束点 放宽至 %0.2f Ictop \n', (0.02+i/100));
end
if isempty(SWoff_stop_indices)
    print('Eoff计算终点识别失败')
    error('Eoff计算终点识别失败')
end

% 初始化并计算关断损耗能量
Poff = zeros(size(time));
Window_width = SWoff_stop - SWoff_start;
Window_extend = fix(Window_width/10);
windowEoff = (SWoff_start : SWoff_stop);

% 向量化计算
Poff(windowEoff) = Vce(windowEoff) .* Ic(windowEoff) * 1000;
dt_off = diff(time(windowEoff));
Eoff = sum(Poff(windowEoff(2:end)) .* dt_off);

% 归一化处理
Poffmax = max(Poff(windowEoff));
Poff_normalized = Poff(windowEoff) / Poffmax / 2;

% 可视化

PicStart = SWoff_start - 2*Window_extend;
PicEnd = SWoff_stop + 2*Window_extend;
PicLength = PicEnd - PicStart;
PicTop = 1.2;
PicBottom = -0.2;
PicHeight = PicTop - PicBottom;

plot(time(windowEoff), Poff_normalized, 'r', 'LineWidth',1.2);
hold on
plot(time,Vce/Vcetop,'g');
plot(time,Ic/Ictop,'b');
xlim([time(PicStart),time(PicEnd)]);
ylim([PicBottom,PicTop]);

% 标注
text(time(PicStart+fix(PicLength*0.05)),PicBottom+PicHeight*0.93,['Eoff=',num2str(Eoff),'mJ'],'FontSize',13);
text(time(SWoff_start),0.45,'Poff','color','red','FontSize',13);
text(time(SWoff_stop),0.95,'Vce','color','green','FontSize',13);
text(time(SWoff_start),0.95,'Ic','color','blue','FontSize',13);
legend('P_{off}','V_{ce}','I_c', 'Location','northeast');
legend('boxoff');
title(sprintf('Ic=%dA 关断损耗分析（归一化）', fix(Ictop)));
grid on;

save_dir = fullfile(path, 'pic', dataname, '04 Eon & Eoff');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
saveas(gcf, fullfile(save_dir, [ num, ' Ic=',num2str(fix(Ictop)),'A Eoff.png']), 'png');
close(gcf);
hold off
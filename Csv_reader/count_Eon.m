function [Eon,SWon_start,SWon_stop] = count_Eon(num,time,Ic,Vce,Ictop,Vcetop,path,dataname,ton2,toff2,cntoff1)

%% ====================== 开通损耗计算（Eon） ======================
% 初始化并计算开通损耗能量
%开通起始时刻寻找
cnton2 = toff2 - ton2;
search_start = max(fix(ton2 - cntoff1/4), 1);  % 防止负索引
valid_range = search_start:min(toff2+cnton2, length(Ic));
SWon_start_indices = find(Ic(valid_range) >= max(0.1*Ictop, 3), 1, 'first');
SWon_start = valid_range(1) + SWon_start_indices - 1;
if isempty(SWon_start_indices)
    print('Eon计算起点识别失败')
    error('Eon计算起点识别失败')
end

%开通结束时刻寻找
SWon_stop_indices = find(Vce(valid_range) <= Vcetop*0.02, 1, 'first');
SWon_stop = valid_range(1) + SWon_stop_indices - 1;
for i = 1:18
    if ~isempty(SWon_stop_indices)
        if(i~=1)
            fprintf('       未找到 0.02 Vcetop 作为 Eon 计算结束点 放宽至 %0.2f Vcetop \n', (0.02+(i-1)/100));
        end
        break;
    end
    SWon_stop_indices = find(Vce(valid_range) <= Vcetop*(0.02+i/100), 1, 'first');
    SWon_stop = valid_range(1) + SWon_stop_indices - 1;
    if i == 1
        fprintf('Eon计算:\n')
    end
end
if isempty(SWon_stop_indices)
    print('Eon计算终点识别失败')
    error('Eon计算终点识别失败')
end

Window_width = SWon_stop - SWon_start;
Window_extend = fix(Window_width/10);
Pon = zeros(size(time)); % 预分配内存
windowEon = (SWon_start-3*Window_extend):(SWon_stop); % 定义计算窗口

% 向量化计算功率和能量
Pon(windowEon) = Vce(windowEon) .* Ic(windowEon) * 1000; % 功率计算（mW）
Pon_full = Vce .* Ic * 1000; % 功率计算（mW）
dt = diff(time(windowEon)); % 时间差分
Eon = sum(Pon(windowEon(2:end)) .* dt); % 梯形积分法（mJ）

% 归一化处理
Ponmax = max(Pon(windowEon));
Pon_normalized = Pon(windowEon) / Ponmax / 2; % 归一化到[-0.5, 0.5]范围
Pon_full_normalized=Pon_full / Ponmax / 2;
[Pon_max,Pon_max_t]=max(Pon_normalized);
Pon_max_t = Pon_max_t+SWon_start-1;

% 可视化设置
PicStart = windowEon(1) - 2*Window_extend;
PicEnd = SWon_stop + 2*Window_extend;
PicLength = PicEnd - PicStart;
PicTop = 1.2;
PicBottom = -0.2;
PicHeight = PicTop - PicBottom;

plot(time(windowEon),Pon_normalized,'r', 'LineWidth',1.2);
hold on
plot(time,Vce/Vcetop,'g');
plot(time,Ic/max(Ic),'b');
plot(time(windowEon(1)), Pon_full_normalized(windowEon(1)),'o','color','red');
plot(time(windowEon(end)), Pon_full_normalized(windowEon(end)),'o','color','red');
plot(time(PicStart:PicEnd),Pon_full_normalized(PicStart:PicEnd),'r--','LineWidth',0.5);
xlim([time(PicStart),time(PicEnd)]);
ylim([PicBottom,PicTop]);

% 标注和格式设置
text(time(PicStart+fix(PicLength*0.05)),PicBottom+PicHeight*0.93,['Eon=',num2str(Eon),'mJ'],'FontSize',13);
text(time(Pon_max_t-fix(PicLength/30)),Pon_max+fix(PicHeight)/20,'Pon','color','red','FontSize',13);
text(time(SWon_start),0.9,'Vce','color','green','FontSize',13);
text(time(SWon_stop),0.9,'Ic','color','blue','FontSize',13);
legend('P_{on}','V_{ce}','I_c', 'Location','northeast');
legend('boxoff');
title(sprintf('Ic=%dA 开通损耗分析（归一化）', fix(Ictop)));
grid on;

save_dir = fullfile(path, 'result', dataname, '03 Eon & Eoff');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
saveas(gcf, fullfile(save_dir, [ num, ' Ic=',num2str(fix(Ictop)),'A Eon.png']), 'png');
close(gcf)
hold off
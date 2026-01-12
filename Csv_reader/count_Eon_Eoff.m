function [Eon,SWon_start,SWon_stop,Eoff,SWoff_start,SWoff_stop] = count_Eon_Eoff(num,DPI,time,Ic,Vce,Ictop,Vcetop,path,dataname,cntVge,Eonmode,Eoffmode)

cntsw = length(cntVge);
toff1=cntVge(cntsw-2);
ton2=cntVge(cntsw-1);
toff2=cntVge(cntsw);
cntoff1 = ton2-toff1;

%% ====================== 开通损耗计算（Eon） ======================
% 初始化并计算开通损耗能量
%开通起始时刻寻找
cnton2 = toff2 - ton2;
search_start = max(fix(ton2 - cntoff1/4), 1);  % 防止负索引
valid_range = search_start:min(toff2+cnton2, length(Ic));
SWon_start_indices = find(Ic(valid_range) >= max(Eonmode(1)*Ictop, 3), 1, 'first');
SWon_start = valid_range(1) + SWon_start_indices - 1;
if isempty(SWon_start_indices)
    print('Eon计算起点识别失败')
    error('Eon计算起点识别失败')
end

%开通结束时刻寻找
SWon_stop_indices = find(Vce(valid_range) <= Vcetop*Eonmode(2), 1, 'first');
SWon_stop = valid_range(1) + SWon_stop_indices - 1;
for i = 1:18
    if ~isempty(SWon_stop_indices)
        if(i~=1)
            fprintf('       未找到 %0.2f Vcetop 作为 Eon 计算结束点 放宽至 %0.2f Vcetop \n', Eonmode(2), (0.02+(i-1)/100));
        end
        break;
    end
    SWon_stop_indices = find(Vce(valid_range) <= Vcetop*(Eonmode(2)+i/100), 1, 'first');
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
Window_extend = Window_width;
Pon = zeros(size(time)); % 预分配内存
windowEon = (SWon_start-fix(Eonmode(3)*Window_extend)):(SWon_stop+fix(Eonmode(4)*Window_extend)); % 定义计算窗口

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

close all;
figure('Position', [320, 240, 1600/DPI/DPI, 600/DPI/DPI]);
subplot('Position', [0.05, 0.15, 0.4, 0.75]);
plot(time(windowEon),Pon_normalized,'r', 'LineWidth',1.2);
hold on
plot(time,Vce/Vcetop,'g');
plot(time,Ic/max(Ic),'b');
plot(time(SWon_start), Pon_full_normalized(SWon_start),'o','color','red');
plot(time(SWon_stop), Pon_full_normalized(SWon_stop),'o','color','red');
plot(time(windowEon(1)), Pon_full_normalized(windowEon(1)),'ro', 'MarkerFaceColor','r');
plot(time(windowEon(end)), Pon_full_normalized(windowEon(end)),'ro', 'MarkerFaceColor','r');
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

cntsw = length(cntVge);
ton1=cntVge(cntsw-3);
toff1=cntVge(cntsw-2);
ton2=cntVge(cntsw-1);
cnton1 = toff1-ton1;

%% ====================== 关断损耗计算（Eoff） ======================
%关断起始时刻寻找
valid_range = (ton1+fix(0.7*cnton1)):min(ton2, length(Vce));
SWoff_start_indices = find(Vce(valid_range) >= Vcetop*Eoffmode(1), 1, 'first');
SWoff_start = valid_range(1) + SWoff_start_indices - 1;
if isempty(SWoff_start_indices)
    print('Eoff计算起点识别失败')
    error('Eoff计算起点识别失败')
end

%关断结束时刻寻找
valid_range = SWoff_start:min(ton2, length(Ic));
SWoff_stop_indices = find(Ic(valid_range) <= Ictop*Eoffmode(2), 1, 'first');
SWoff_stop = valid_range(1) + SWoff_stop_indices - 1;
for i = 1:18
    if ~isempty(SWoff_stop_indices)
        if(i~=1)
            fprintf('       未找到 %0.2f Ictop 作为 Eoff 计算结束点 放宽至 %0.2f Ictop \n',Eoffmode(2),(0.02+(i-1)/100));
        end
        break;
    end
    SWoff_stop_indices = find(Ic(valid_range) <= Ictop*(Eoffmode(2)+i/100), 1, 'first');
    SWoff_stop = valid_range(1) + SWoff_stop_indices - 1;
    if i == 1
        fprintf('Eoff计算:\n')
    end
end
if isempty(SWoff_stop_indices)
    print('Eoff计算终点识别失败')
    error('Eoff计算终点识别失败')
end

% 初始化并计算关断损耗能量
Poff = zeros(size(time));
Window_width = SWoff_stop - SWoff_start;
Window_extend = fix(Window_width);
windowEoff = (SWoff_start-fix(Eoffmode(3)*Window_extend)):(SWoff_stop+fix(Eoffmode(4)*Window_extend)); % 定义计算窗口

% 向量化计算
Poff(windowEoff) = Vce(windowEoff) .* Ic(windowEoff) * 1000;
Poff_full = Vce .* Ic * 1000; % 功率计算（mW）
dt_off = diff(time(windowEoff));
Eoff = sum(Poff(windowEoff(2:end)) .* dt_off);

% 归一化处理
Poffmax = max(Poff(windowEoff));
Poff_normalized = Poff(windowEoff) / Poffmax / 2;
Poff_full_normalized = Poff_full / Poffmax / 2;
[Poff_max,Poff_max_t]=max(Poff_normalized);
Poff_max_t = Poff_max_t+SWoff_start-1;

% 可视化

PicStart = windowEoff(1) - 2*Window_extend;
PicEnd = SWoff_stop + 2*Window_extend;
PicLength = PicEnd - PicStart;
PicTop = 1.2;
PicBottom = -0.2;
PicHeight = PicTop - PicBottom;

subplot('Position', [0.55, 0.15, 0.4, 0.75]);
plot(time(windowEoff), Poff_normalized, 'r', 'LineWidth',1.2);
hold on
plot(time,Vce/Vcetop,'g');
plot(time,Ic/Ictop,'b');
plot(time(SWoff_start), Poff_full_normalized(SWoff_start),'o','color','red');
plot(time(SWoff_stop), Poff_full_normalized(SWoff_stop),'o','color','red');
plot(time(windowEoff(1)), Poff_full_normalized(windowEoff(1)),'ro', 'MarkerFaceColor','r');
plot(time(windowEoff(end)), Poff_full_normalized(windowEoff(end)),'ro', 'MarkerFaceColor','r');
plot(time(PicStart:PicEnd),Poff_full_normalized(PicStart:PicEnd),'r--','LineWidth',0.5);
xlim([time(PicStart),time(PicEnd)]);
ylim([PicBottom,PicTop]);

% 标注
text(time(PicStart+fix(PicLength*0.05)),PicBottom+PicHeight*0.93,['Eoff=',num2str(Eoff),'mJ'],'FontSize',13);
text(time(Poff_max_t-fix(PicLength/50)),Poff_max+fix(PicHeight)/20,'Poff','color','red','FontSize',13);
text(time(SWoff_stop),0.95,'Vce','color','green','FontSize',13);
text(time(SWoff_start),0.95,'Ic','color','blue','FontSize',13);
legend('P_{off}','V_{ce}','I_c', 'Location','northeast');
legend('boxoff');
title(sprintf('Ic=%dA 关断损耗分析（归一化）', fix(Ictop)));
grid on;

save_dir = fullfile(path, 'result', dataname, '03 Eon & Eoff');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
saveas(gcf, fullfile(save_dir, [ num, ' Ic=',num2str(fix(Ictop)),'A Eon & Eoff.png']), 'png');
close(gcf);
hold off
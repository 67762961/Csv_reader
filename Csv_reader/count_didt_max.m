function [didton_max,didtoff_min] = count_didt_max(num,DPI,didt_step,time,ch3,I_on,I_off,path,dataname,cntVge,Wave_count,Pic_win)

% ====================== 开通时刻 di/dt计算模块 ======================
switch Wave_count(1)
    case 1
        Posedge = cntVge(1):cntVge(2);
    case 2
        Posedge = cntVge(3):cntVge(4);
    case 3
        Posedge = cntVge(5):cntVge(6);
end

switch Wave_count(2)
    case 1
        Negedge = cntVge(2):cntVge(3);
    case 2
        Negedge = cntVge(4):cntVge(5);
    case 3
        Negedge = cntVge(6):length(time);
end

% 窗口计算
nspd = time(2) - time(1); % 采样间隔
didt_step_dot = fix(didt_step/nspd*1e-9+0.5); % 采样点数
fprintf('极限didt窗口长度:\n');
fprintf('       采样点间隔为: %.1f ns\n',nspd*1e9);
fprintf('       窗口长度近似为: %.1f ns\n',didt_step_dot*nspd*1e9);

% 动态窗口生成
% max_search_length = fix(2*min(cnton1,cnton2));
Window_Start = Posedge(1);
Window_Stop = Posedge(end);
window_di = Window_Start : Window_Stop;
[~,T_Icmax] = max(ch3(window_di));
Window_Stop_count = fix(T_Icmax + Window_Start - 1); % 重新定义窗口结束点为Icmax点
window_di = Window_Start : Window_Stop_count;
didton_max = 0;

for i = window_di
    delta_time = time(i + didt_step_dot) - time(i); % 时间差(ns转秒)
    didton_temp = (ch3(i + didt_step_dot) - ch3(i)) / delta_time * 1e-6;
    % fprintf('采样点time = %fus 当前didt = %f\n',time(i)*1e6,didton_temp)
    if didton_temp > didton_max
        % fprintf('采样点time = %fus 当前didt = %f 超过最大didt = %f 触发替换最大值\n',time(i)*1e6,didton_temp,didton_max)
        didton_max = didton_temp;
        valid_rise_start = i;
        valid_rise_end = i + didt_step_dot;
    end
end
% fprintf('最大didt = %f\n',didton_max)

if isempty(didton_max)
    didton_max = 0;
end

% 绘图
% [~, max_idx] = max(ch3(window_di));          % 快速定位峰值索引 max_idx为相对索引
% tIcm = Window_Start + max_idx - 1;          % 转换为全局索引

PicStart = Pic_win(3);
PicEnd = Pic_win(4);
PicLength = PicEnd - PicStart;
PicTop = Pic_win(1);
PicBottom = Pic_win(2);
PicHeight = PicTop - PicBottom;

close all;
figure('Position', [320, 240, 1600/DPI, 600/DPI]);
subplot('Position', [0.05, 0.15, 0.4, 0.75]);
plot(time(PicStart:PicEnd), ch3(PicStart:PicEnd), 'b');
hold on;
plot(time(valid_rise_start:valid_rise_end), ch3(valid_rise_start:valid_rise_end), 'r', 'LineWidth',1.5);
% plot(time(Window_Start:Window_Stop), zeros(Window_Stop-Window_Start+1), 'Black');
plot(time(valid_rise_start), ch3(valid_rise_start), 'ro', 'MarkerFaceColor','r');
plot(time(valid_rise_end), ch3(valid_rise_end), 'ro', 'MarkerFaceColor','r');

% 动态标注
text(time(fix(valid_rise_start+0.03*PicLength)),ch3(fix(valid_rise_start-PicHeight*0.01)),['Ic','=',num2str(ch3(valid_rise_start)),'A'],'FontSize',13);
text(time(fix(valid_rise_end+0.03*PicLength)),ch3(fix(valid_rise_end+PicHeight*0.05)),['Ic','=',num2str(ch3(valid_rise_end)),'A'],'FontSize',13);
text(time(PicStart+fix(PicLength*0.05)),PicBottom+PicHeight*0.9,['Ictop = ',num2str(fix(I_on)),'A'],'FontSize',13);
text(time(PicStart+fix(PicLength*0.05)),PicBottom+PicHeight*0.8,['di/dtMAX = ',num2str(fix(didton_max+0.5)),'A/us'],'FontSize',13);
plot(time(Window_Start), ch3(Window_Start),'o','color','blue');
plot(time(Window_Stop), ch3(Window_Stop),'o','color','blue');
text(time(valid_rise_start),PicBottom+PicHeight*0.03,[num2str(time(valid_rise_start)*1e6),'us'],'FontSize',8,'color','r');
text(time(valid_rise_end),PicBottom+PicHeight*0.07,[num2str(time(valid_rise_end)*1e6),'us'],'FontSize',8,'color','r');
line([time(valid_rise_start),time(valid_rise_start)],[PicBottom+PicHeight*0.03,ch3(valid_rise_start)],'Color', 'r','LineStyle','--');
line([time(valid_rise_end),time(valid_rise_end)],[PicBottom+PicHeight*0.07,ch3(valid_rise_end)],'Color', 'r','LineStyle','--');

ylim([PicBottom, PicTop]);
xlim([time(PicStart), time(PicEnd)]);
title(['Ic=',num2str(fix(I_on)),'A di/dtMAX(on) 计算']);
grid on;

% ====================== 关断时刻 di/dt计算模块 ======================
% 动态窗口生成
Window_Start = Negedge(1);
Window_Stop = Negedge(end);
window_di = Window_Start : Window_Stop;

didtoff_min = 0;

for i = window_di
    delta_time = time(i + didt_step_dot) - time(i); % 时间差(ns转秒)
    didtoff_temp = (ch3(i + didt_step_dot) - ch3(i)) / delta_time * 1e-6;
    if didtoff_temp < didtoff_min
        didtoff_min = didtoff_temp;
        valid_fall_start = i;
        valid_fall_end = i + didt_step_dot;
    end
end

if isempty(didtoff_min)
    didtoff_min = 0;
end

PicStart = Pic_win(7);
PicEnd = Pic_win(8);
PicLength = PicEnd - PicStart;
PicTop = Pic_win(5);
PicBottom = Pic_win(6);
PicHeight = PicTop - PicBottom;

subplot('Position', [0.55, 0.15, 0.4, 0.75]);
plot(time(PicStart:PicEnd), ch3(PicStart:PicEnd), 'b');
hold on;
plot(time(valid_fall_start:valid_fall_end), ch3(valid_fall_start:valid_fall_end), 'r', 'LineWidth',1.5);
plot(time(valid_fall_start), ch3(valid_fall_start), 'ro', 'MarkerFaceColor','r');
plot(time(valid_fall_end), ch3(valid_fall_end), 'ro', 'MarkerFaceColor','r');
plot(time(Window_Start), ch3(Window_Start),'o','color','blue');
plot(time(Window_Stop), ch3(Window_Stop),'o','color','blue');

% 动态标注
text(time(fix(valid_fall_start+0.05*PicLength)),ch3(fix(valid_fall_start+PicHeight*0.05)),['Ic','=',num2str(ch3(valid_fall_start)),'A'],'FontSize',13);
text(time(fix(valid_fall_end+0.05*PicLength)),ch3(fix(valid_fall_end-PicHeight*0.05)),['Ic','=',num2str(ch3(valid_fall_end)),'A'],'FontSize',13);
text(time(PicStart+fix(PicLength*0.05)),PicBottom+PicHeight*0.9,['Ictop = ',num2str(fix(I_off+0.5)),'A'],'FontSize',13);
text(time(PicStart+fix(PicLength*0.05)),PicBottom+PicHeight*0.8,['di/dtMIN = ',num2str(fix(didtoff_min+0.5)),'A/us'],'FontSize',13);
text(time(valid_fall_start),PicBottom+PicHeight*0.03,[num2str(time(valid_fall_start)*1e6),'us'],'FontSize',8,'color','r');
text(time(valid_fall_end),PicBottom+PicHeight*0.07,[num2str(time(valid_fall_end)*1e6),'us'],'FontSize',8,'color','r');
line([time(valid_fall_start),time(valid_fall_start)],[PicBottom+PicHeight*0.03,ch3(valid_fall_start)],'Color', 'r','LineStyle','--');
line([time(valid_fall_end),time(valid_fall_end)],[PicBottom+PicHeight*0.07,ch3(valid_fall_end)],'Color', 'r','LineStyle','--');

ylim([PicBottom, PicTop]);
xlim([time(PicStart), time(PicEnd)]);
title(['Ic=',num2str(fix(I_off)),'A di/dtMIN(off) 计算']);
grid on;

% 保存处理
save_dir = fullfile(path, 'result', dataname, '05 didt');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
saveas(gcf, fullfile(save_dir, [ num,' Ic=',num2str(fix(I_off)),'A didtmax.png']), 'png');
close(gcf);
hold off

% Tdidtmax = [valid_rise_start,valid_rise_end,valid_fall_start,valid_fall_end];
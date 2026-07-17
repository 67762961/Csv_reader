function [dvdtoff_max,dvdton_min] = count_dvdt_max(num,DPI,dvdt_step,time,Vce,Ictop,Vcetop,path,dataname,cntVge,Wave_count,Pic_win)
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

%% 关断dv/dt计算模块
% 窗口计算
nspd = time(2) - time(1); % 采样间隔
dvdt_step_dot = fix(dvdt_step/nspd*1e-9+0.5); % 采样点数
fprintf('极限dvdt窗口长度:\n');
fprintf('       采样点间隔为: %.1f ns\n',nspd*1e9);
fprintf('       窗口长度近似为: %.1f ns\n',dvdt_step_dot*nspd*1e9);

% 动态窗口生成
% max_search_length = fix(2*min(cnton1,cnton2));
Window_Start = Negedge(1);
Window_Stop = Negedge(end);
window_dv = Window_Start : Window_Stop;
[~,T_Icmax] = max(Vce(window_dv));
Window_Stop_count = fix(T_Icmax + Window_Start - 1); % 重新定义窗口结束点为Icmax点
window_dv = Window_Start : Window_Stop_count;
dvdtoff_max = 0;

for i = window_dv
    delta_time = time(i + dvdt_step_dot) - time(i); % 时间差(ns转秒)
    dvdton_temp = (Vce(i + dvdt_step_dot) - Vce(i)) / delta_time * 1e-6;
    % fprintf('采样点time = %fus 当前dvdt = %f\n',time(i)*1e6,dvdton_temp)
    if dvdton_temp > dvdtoff_max
        % fprintf('采样点time = %fus 当前dvdt = %f 超过最大dvdt = %f 触发替换最大值\n',time(i)*1e6,dvdton_temp,dvdtoff_max)
        dvdtoff_max = dvdton_temp;
        rise_start_idx_a = i;
        rise_end_idx_b = i + dvdt_step_dot;
    end
end
% fprintf('最大dvdt = %f\n',dvdtoff_max)

if isempty(dvdtoff_max)
    dvdtoff_max = 0;
end

PicStart = Pic_win(3);
PicEnd = Pic_win(4);
PicLength = PicEnd - PicStart;
PicTop = Pic_win(1);
PicBottom = Pic_win(2);
PicHeight = PicTop - PicBottom;

close all;
figure('Position', [320, 240, 1600/DPI, 600/DPI]);
subplot('Position', [0.55, 0.15, 0.4, 0.75]);
plot(time(PicStart:PicEnd), Vce(PicStart:PicEnd), 'b');
hold on;
plot(time(rise_start_idx_a:rise_end_idx_b ), Vce(rise_start_idx_a:rise_end_idx_b ), 'r', 'LineWidth',1.5);
plot(time(rise_start_idx_a), Vce(rise_start_idx_a), 'ro', 'MarkerFaceColor','r');
plot(time(rise_end_idx_b ), Vce(rise_end_idx_b ), 'ro', 'MarkerFaceColor','r');
plot(time(window_dv(1)), Vce(window_dv(1)),'o','color','blue');
plot(time(window_dv(end)), Vce(window_dv(end)),'o','color','blue');
text(time(fix(rise_start_idx_a+0.03*PicLength)),Vce(rise_start_idx_a)-0.02*PicHeight,['Vce =',num2str(Vce(rise_start_idx_a)),'V',],'FontSize',13);
text(time(fix(rise_end_idx_b+0.03*PicLength)),Vce(rise_end_idx_b)+0.02*PicHeight,['Vce =',num2str(Vce(rise_end_idx_b )),'V'],'FontSize',13);
text(time(PicStart+fix(PicLength*0.05)),PicBottom+PicHeight*0.9,['Vcetop = ',num2str(fix(Vcetop+0.5)),'V'],'FontSize',13);
text(time(PicStart+fix(PicLength*0.05)),PicBottom+PicHeight*0.8,['dv/dtMAX = ',num2str(fix(dvdtoff_max+0.5)),'V/us'],'FontSize',13);
text(time(rise_start_idx_a),PicBottom+PicHeight*0.03,[num2str(time(rise_start_idx_a)*1e6),'us'],'FontSize',8,'color','r');
text(time(rise_end_idx_b),PicBottom+PicHeight*0.07,[num2str(time(rise_end_idx_b)*1e6),'us'],'FontSize',8,'color','r');
line([time(rise_start_idx_a),time(rise_start_idx_a)],[PicBottom+PicHeight*0.03,Vce(rise_start_idx_a)],'Color', 'r','LineStyle','--');
line([time(rise_end_idx_b),time(rise_end_idx_b)],[PicBottom+PicHeight*0.07,Vce(rise_end_idx_b)],'Color', 'r','LineStyle','--');

% 坐标轴设置
ylim([PicBottom, PicTop]);
xlim([time(PicStart), time(PicEnd)]);
title(['Ic=',num2str(fix(Ictop)),'A dv/dtMAX(off)计算']);
grid on;

%% 开通dv/dt计算模块
% 动态窗口生成
Window_Start = Posedge(1);
Window_Stop = Posedge(end);
window_di = Window_Start : Window_Stop;

dvdton_min = 0;

for i = window_di
    delta_time = time(i + dvdt_step_dot) - time(i); % 时间差(ns转秒)
    dvdtoff_temp = (Vce(i + dvdt_step_dot) - Vce(i)) / delta_time * 1e-6;
    if dvdtoff_temp < dvdton_min
        dvdton_min = dvdtoff_temp;
        fall_start_idx_c = i;
        fall_end_idx_d = i + dvdt_step_dot;
    end
end

if isempty(dvdton_min)
    dvdton_min = 0;
end

PicStart = Pic_win(7);
PicEnd = Pic_win(8);
PicLength = PicEnd - PicStart;
PicTop = Pic_win(5);
PicBottom = Pic_win(6);
PicHeight = PicTop - PicBottom;

subplot('Position', [0.05, 0.15, 0.4, 0.75]);
plot(time(PicStart:PicEnd), Vce(PicStart:PicEnd), 'b');
hold on;
plot(time(fall_start_idx_c:fall_end_idx_d ), Vce(fall_start_idx_c:fall_end_idx_d ), 'r', 'LineWidth',1.5);
plot(time(fall_start_idx_c), Vce(fall_start_idx_c), 'ro', 'MarkerFaceColor','r');
text(time(fix(fall_start_idx_c+0.03*PicLength)),Vce(fall_start_idx_c)+0.02*PicHeight,['Vce =',num2str(Vce(fall_start_idx_c)),'V',],'FontSize',13);
plot(time(fall_end_idx_d), Vce(fall_end_idx_d), 'ro', 'MarkerFaceColor','r');
text(time(fix(fall_end_idx_d+0.03*PicLength)),Vce(fall_end_idx_d)-0.02*PicHeight,['Vce =',num2str(Vce(fall_end_idx_d)),'V',],'FontSize',13);
plot(time(window_dv(1)), Vce(window_dv(1)),'o','color','blue');
plot(time(window_dv(end)), Vce(window_dv(end)),'o','color','blue');
text(time(PicStart+fix(PicLength*0.05)),PicBottom+PicHeight*0.9,['Vcetop = ',num2str(fix(Vcetop+0.5)),'V'],'FontSize',13);
text(time(PicStart+fix(PicLength*0.05)),PicBottom+PicHeight*0.8,['dv/dtMAX = ',num2str(fix(dvdton_min+0.5)),'V/us'],'FontSize',13);
text(time(fall_start_idx_c),PicBottom+PicHeight*0.03,[num2str(time(fall_start_idx_c)*1e6),'us'],'FontSize',8,'color','r');
text(time(fall_end_idx_d),PicBottom+PicHeight*0.07,[num2str(time(fall_end_idx_d)*1e6),'us'],'FontSize',8,'color','r');
line([time(fall_start_idx_c),time(fall_start_idx_c)],[PicBottom+PicHeight*0.03,Vce(fall_start_idx_c)],'Color', 'r','LineStyle','--');
line([time(fall_end_idx_d),time(fall_end_idx_d)],[PicBottom+PicHeight*0.07,Vce(fall_end_idx_d)],'Color', 'r','LineStyle','--');

% 坐标轴设置
ylim([PicBottom, PicTop]);
xlim([time(PicStart), time(PicEnd)]);
title(['Ic=',num2str(fix(Ictop)),'A dv/dtMIN(on)计算']);
grid on;

% 保存路径处理
save_dir = fullfile(path, 'result', dataname, '04 dvdt');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
saveas(gcf, fullfile(save_dir, [ num,' Ic=',num2str(fix(Ictop)),'A dvdtmax.png']), 'png');
close(gcf);
hold off

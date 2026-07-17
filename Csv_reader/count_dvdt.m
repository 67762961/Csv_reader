function [dvdt_on,dvdt_off,Tdvdt,Pic_win] = count_dvdt(num,DPI,dvdtmode,time,Vce,Ictop,Vcetop,Vcemax,path,dataname,VceRange)


posedge = VceRange(1):VceRange(2);
negedge = VceRange(3):VceRange(4);
% disp(VceRange)

%% 关断dv/dt计算模块
% 阈值定义
V_a  = Vcetop * dvdtmode(3)/100;
V_b  = Vcetop * dvdtmode(4)/100;
V_c  = Vcetop * dvdtmode(1)/100;
V_d  = Vcetop * dvdtmode(2)/100;

% 电压上升沿阈值检测
window_dv = negedge;

rise_start_idx_a = find(Vce(window_dv) >= V_a, 1, 'first') + window_dv(1) - 1;
if isempty(rise_start_idx_a)
    warning('dvdt_off起始点识别失败')
    rise_start_idx_a = window_dv(1);
end
Diff1 = abs(Vce(rise_start_idx_a) - V_a);
Diff2 = abs(Vce(rise_start_idx_a - 1) - V_a);
if Diff1 > Diff2
    rise_start_idx_a = rise_start_idx_a - 1;
    % fprintf('前一采样点 %f 与阈值差异更小 %f < %f回退一个采样点\n',Vce(rise_start_idx_a),Diff2,Diff1);
end

rise_end_idx_b  = find(Vce(rise_start_idx_a:window_dv(end)) >= V_b, 1, 'first') + rise_start_idx_a - 1;
if isempty(rise_end_idx_b)
    warning('dvdt_off结束点识别失败')
    rise_end_idx_b = window_dv(end);
end
Diff1 = abs(Vce(rise_end_idx_b) - V_b);
Diff2 = abs(Vce(rise_end_idx_b - 1) - V_b);
if Diff1 > Diff2
    rise_end_idx_b = rise_end_idx_b - 1;
    % fprintf('前一采样点 %f 与阈值差异更小 %f < %f回退一个采样点\n',Vce(rise_end_idx_b),Diff2,Diff1);
end

delta_time_a_b = time(rise_end_idx_b) - time(rise_start_idx_a); % 时间差(ns转秒)

if (rise_end_idx_b - rise_start_idx_a)>0
    dvdt_a_b = (Vce(rise_end_idx_b) - Vce(rise_start_idx_a)) / delta_time_a_b * 1e-6;
else
    dvdt_a_b = 0;
    warning('dvdt_off段落识别出现异常')
end

% 保持原始绘图逻辑
Riselength = fix((rise_end_idx_b - rise_start_idx_a));
Half_PicLength = fix(Riselength/abs(dvdtmode(3)-dvdtmode(4))*100);
PicStart = rise_start_idx_a - Half_PicLength;
PicEnd = rise_end_idx_b + Half_PicLength;
PicLength = PicEnd - PicStart;
PicTop = fix(1.05*Vcemax);
PicBottom = fix(-0.1*PicTop);
PicHeight = PicTop - PicBottom;
Pic_win(1:4) = [PicTop,PicBottom,PicStart,PicEnd];

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
text(time(fix(rise_start_idx_a+0.03*PicLength)),Vce(rise_start_idx_a),['Vce{10}=',num2str(Vce(rise_start_idx_a)),'V',],'FontSize',13);
text(time(fix(rise_end_idx_b+0.03*PicLength)),Vce(rise_end_idx_b),['Vce{90}=',num2str(Vce(rise_end_idx_b )),'V'],'FontSize',13);
text(time(PicStart+fix(PicLength*0.05)),PicBottom+PicHeight*0.9,['Vcetop = ',num2str(fix(Vcetop+0.5)),'V'],'FontSize',13);
text(time(PicStart+fix(PicLength*0.05)),PicBottom+PicHeight*0.8,['dv/dt = ',num2str(fix(dvdt_a_b+0.5)),'V/us'],'FontSize',13);
text(time(rise_start_idx_a),PicBottom+PicHeight*0.03,[num2str(time(rise_start_idx_a)*1e6),'us'],'FontSize',8,'color','r');
text(time(rise_end_idx_b),PicBottom+PicHeight*0.07,[num2str(time(rise_end_idx_b)*1e6),'us'],'FontSize',8,'color','r');
line([time(rise_start_idx_a),time(rise_start_idx_a)],[PicBottom+PicHeight*0.03,Vce(rise_start_idx_a)],'Color', 'r','LineStyle','--');
line([time(rise_end_idx_b),time(rise_end_idx_b)],[PicBottom+PicHeight*0.07,Vce(rise_end_idx_b)],'Color', 'r','LineStyle','--');

% 坐标轴设置
ylim([PicBottom, PicTop]);
xlim([time(PicStart), time(PicEnd)]);
title(['Ic=',num2str(fix(Ictop)),'A dv/dt(off)计算']);
grid on;

dvdt_off = dvdt_a_b;

%% 开通dv/dt计算模块
window_dv = posedge;

fall_start_idx_c = find(Vce(window_dv) <= V_c, 1, 'first') + window_dv(1) - 1;
if isempty(fall_start_idx_c)
    warning('dvdt_on起始点识别失败')
    fall_start_idx_c = window_dv(1);
end
Diff1 = abs(Vce(fall_start_idx_c) - V_c);
Diff2 = abs(Vce(fall_start_idx_c - 1) - V_c);
if Diff1 > Diff2
    fall_start_idx_c = fall_start_idx_c - 1;
    % fprintf('前一采样点 %f 与阈值差异更小 %f < %f回退一个采样点\n',Vce(fall_start_idx_c),Diff2,Diff1);
end

fall_end_idx_d  = find(Vce(fall_start_idx_c:window_dv(end)) <= V_d, 1, 'first') + fall_start_idx_c - 1;
if isempty(fall_end_idx_d)
    warning('dvdt_on结束点识别失败')
    fall_end_idx_d = window_dv(end);
end
Diff1 = abs(Vce(fall_end_idx_d) - V_d);
Diff2 = abs(Vce(fall_end_idx_d - 1) - V_d);
if Diff1 > Diff2
    fall_end_idx_d = fall_end_idx_d - 1;
    % fprintf('前一采样点 %f 与阈值差异更小 %f < %f回退一个采样点\n',Vce(fall_end_idx_d),Diff2,Diff1);
end

delta_time_c_d = time(fall_end_idx_d) - time(fall_start_idx_c); % 时间差(ns转秒)

if (fall_end_idx_d - fall_start_idx_c)>0
    dvdt_c_d = (Vce(fall_end_idx_d) - Vce(fall_start_idx_c)) / delta_time_c_d * 1e-6;
else
    dvdt_c_d = 0;
    warning('dvdt_on段落识别出现异常')
end

Falllength = abs(fix((fall_end_idx_d - fall_start_idx_c)));
Half_PicLength = fix(Falllength/abs(dvdtmode(2)-dvdtmode(1))*200);
PicStart = fall_start_idx_c - Half_PicLength;
PicEnd = fall_end_idx_d + Half_PicLength;
PicLength = PicEnd - PicStart;
PicTop = fix(1.05*Vcemax);
PicBottom = fix(-0.1*PicTop);
PicHeight = PicTop - PicBottom;
Pic_win(5:8) = [PicTop,PicBottom,PicStart,PicEnd];

subplot('Position', [0.05, 0.15, 0.4, 0.75]);
plot(time(PicStart:PicEnd), Vce(PicStart:PicEnd), 'b');
hold on;
plot(time(fall_start_idx_c:fall_end_idx_d ), Vce(fall_start_idx_c:fall_end_idx_d ), 'r', 'LineWidth',1.5);
plot(time(fall_start_idx_c), Vce(fall_start_idx_c), 'ro', 'MarkerFaceColor','r');
text(time(fix(fall_start_idx_c+0.03*PicLength)),Vce(fall_start_idx_c),['Vce{',num2str(dvdtmode(1)),'}=',num2str(Vce(fall_start_idx_c)),'V',],'FontSize',13);
plot(time(fall_end_idx_d), Vce(fall_end_idx_d), 'ro', 'MarkerFaceColor','r');
text(time(fix(fall_end_idx_d+0.03*PicLength)),Vce(fall_end_idx_d),['Vce{',num2str(dvdtmode(2)),'}=',num2str(Vce(fall_end_idx_d)),'V',],'FontSize',13);
plot(time(window_dv(1)), Vce(window_dv(1)),'o','color','blue');
plot(time(window_dv(end)), Vce(window_dv(end)),'o','color','blue');
text(time(PicStart+fix(PicLength*0.05)),PicBottom+PicHeight*0.9,['Vcetop = ',num2str(fix(Vcetop+0.5)),'V'],'FontSize',13);
text(time(PicStart+fix(PicLength*0.05)),PicBottom+PicHeight*0.8,['dv/dt = ',num2str(fix(dvdt_c_d+0.5)),'V/us'],'FontSize',13);
text(time(fall_start_idx_c),PicBottom+PicHeight*0.03,[num2str(time(fall_start_idx_c)*1e6),'us'],'FontSize',8,'color','r');
text(time(fall_end_idx_d),PicBottom+PicHeight*0.07,[num2str(time(fall_end_idx_d)*1e6),'us'],'FontSize',8,'color','r');
line([time(fall_start_idx_c),time(fall_start_idx_c)],[PicBottom+PicHeight*0.03,Vce(fall_start_idx_c)],'Color', 'r','LineStyle','--');
line([time(fall_end_idx_d),time(fall_end_idx_d)],[PicBottom+PicHeight*0.07,Vce(fall_end_idx_d)],'Color', 'r','LineStyle','--');

% 坐标轴设置
ylim([PicBottom, PicTop]);
xlim([time(PicStart), time(PicEnd)]);
title(['Ic=',num2str(fix(Ictop)),'A dv/dt(on)计算']);
grid on;

% 保存路径处理
save_dir = fullfile(path, 'result', dataname, '04 dvdt');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
saveas(gcf, fullfile(save_dir, [ num,' Ic=',num2str(fix(Ictop)),'A dvdt.png']), 'png');
close(gcf);
hold off

dvdt_on = dvdt_c_d;

Tdvdt = [fall_start_idx_c,fall_end_idx_d,rise_start_idx_a,rise_end_idx_b];

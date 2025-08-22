function [dvdt,dvdt_a_b] = count_dvdt(num,nspd,dvdtmode,time,Vce,Ictop,Vcetop,Vcemax,path,dataname,SWoff_start,SWoff_stop)

%% dv/dt计算模块
% 阈值定义
V_10 = Vcetop * 0.1;
V_90 = Vcetop * 0.9;
V_a  = Vcetop * dvdtmode(1)/100;
V_b  = Vcetop * dvdtmode(2)/100;

% 电压上升沿阈值检测
window_dv_start = max(1, SWoff_start-500);  % 起始索引不低于1
window_dv_end = min(length(Vce), SWoff_stop+50);  % 终止索引不超过数组长度
window_dv = window_dv_start : window_dv_end;

rise_start_idx = find(Vce(window_dv) >= V_10, 1, 'first') + window_dv(1) - 1;
rise_end_idx  = find(Vce(rise_start_idx:window_dv(end)) >= V_90, 1, 'first') + rise_start_idx - 1;
delta_time = (rise_end_idx  - rise_start_idx) * nspd * 1e-9;      % 时间差(ns转秒)
if (rise_end_idx - rise_start_idx)>0
    dvdt = (Vce(rise_end_idx ) - Vce(rise_start_idx)) / delta_time * 1e-6;
else
    dvdt = 0;
    warning('dvdt段落识别出现异常')
end

rise_start_idx_a = find(Vce(window_dv) >= V_a, 1, 'first') + window_dv(1) - 1;
rise_end_idx_b  = find(Vce(rise_start_idx:window_dv(end)) >= V_b, 1, 'first') + rise_start_idx - 1;
delta_time_a_b = (rise_end_idx_b  - rise_start_idx_a) * nspd * 1e-9;      % 时间差(ns转秒)
if (rise_end_idx - rise_start_idx)>0
    dvdt_a_b = (Vce(rise_end_idx_b) - Vce(rise_start_idx_a)) / delta_time_a_b * 1e-6;
else
    dvdt_a_b = 0;
    warning('dvdt_a_b段落识别出现异常')
end

% 保持原始绘图逻辑
% figure;
Riselength = fix((SWoff_stop - SWoff_start));

PicStart = rise_start_idx - fix(Riselength*2/3);
PicEnd = rise_end_idx + Riselength;
PicLength = PicEnd - PicStart;
PicTop = fix(1.05*Vcemax);
PicBottom = fix(-0.05*Vcemax);
PicHeight = PicTop - PicBottom;

plot(time(rise_start_idx-Riselength:rise_end_idx +Riselength), Vce(rise_start_idx-Riselength:rise_end_idx +Riselength), 'b');
hold on;
plot(time(rise_start_idx:rise_end_idx ), Vce(rise_start_idx:rise_end_idx ), 'r', 'LineWidth',1.5);
plot(time(rise_start_idx), Vce(rise_start_idx), 'ro', 'MarkerFaceColor','r');
plot(time(rise_end_idx ), Vce(rise_end_idx ), 'ro', 'MarkerFaceColor','r');

text(time(fix(rise_start_idx+0.03*PicLength)),Vce(rise_start_idx),['Vce{10}=',num2str(Vce(rise_start_idx)),'V',],'FontSize',13);
text(time(fix(rise_end_idx +0.03*PicLength)),Vce(rise_end_idx),['Vce{90}=',num2str(Vce(rise_end_idx )),'V'],'FontSize',13);
text(time(PicStart+fix(PicLength*0.05)),PicBottom+PicHeight*0.9,['Vcetop=',num2str(Vcetop),'V'],'FontSize',13);
text(time(PicStart+fix(PicLength*0.05)),PicBottom+PicHeight*0.8,['dv/dt=',num2str(dvdt),'V/us'],'FontSize',13);
if dvdtmode(1) ~= 10 || dvdtmode(2) ~= 90
    plot(time(rise_start_idx_a:rise_end_idx_b ), Vce(rise_start_idx_a:rise_end_idx_b ), 'g', 'LineWidth',1.5);
    plot(time(rise_start_idx_a), Vce(rise_start_idx_a), 'ro', 'MarkerFaceColor','g');
    text(time(rise_start_idx_a+3),Vce(rise_start_idx_a),['Vce{',num2str(dvdtmode(1)),'}=',num2str(Vce(rise_start_idx_a)),'V',],'FontSize',13);
    plot(time(rise_end_idx_b), Vce(rise_end_idx_b), 'ro', 'MarkerFaceColor','g');
    text(time(rise_end_idx_b+3),Vce(rise_end_idx_b),['Vce{',num2str(dvdtmode(2)),'}=',num2str(Vce(rise_end_idx_b)),'V',],'FontSize',13);
    text(time(rise_start_idx-fix(Riselength*0.9)),Vcemax*0.7,['dv/dt(',num2str(dvdtmode(1)),'-',num2str(dvdtmode(2)),')=',num2str(dvdt_a_b),'V/us'],'FontSize',13);
end
% 坐标轴设置
ylim([PicBottom, PicTop]);
xlim([time(PicStart), time(PicEnd)]);
title(['Ic=',num2str(fix(Ictop)),'A dv/dt计算']);
grid on;

% 保存路径处理
save_dir = fullfile(path, 'pic', dataname, '05 dvdt');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
saveas(gcf, fullfile(save_dir, [ num,' Ic=',num2str(fix(Ictop)),'A dvdt-Vcetop=',num2str(fix(Vcetop)),'.png']), 'png');
close(gcf);
hold off
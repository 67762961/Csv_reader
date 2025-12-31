function [dvdt_on,dvdt_off,Tdvdt] = count_dvdt(num,dvdtmode,time,Vce,Ictop,Vcetop,Vcemax,path,dataname,cntSW)

SWon_start = cntSW(1);
SWon_stop = cntSW(2);
SWoff_start = cntSW(3);
SWoff_stop = cntSW(4);

%% 关断dv/dt计算模块
% 阈值定义
V_10 = Vcetop * 0.1;
V_90 = Vcetop * 0.9;
V_a  = Vcetop * dvdtmode(3)/100;
V_b  = Vcetop * dvdtmode(4)/100;
V_c  = Vcetop * dvdtmode(1)/100;
V_d  = Vcetop * dvdtmode(2)/100;

% 电压上升沿阈值检测
max_search_length = fix((SWoff_stop - SWoff_start)/5);
window_dv_start = max(1, SWoff_start-max_search_length);  % 起始索引不低于1
window_dv_end = min(length(Vce), SWoff_stop+max_search_length);  % 终止索引不超过数组长度
window_dv = window_dv_start : window_dv_end;

rise_start_idx = find(Vce(window_dv) >= V_10, 1, 'first') + window_dv(1) - 1;
if isempty(rise_start_idx)
    print('dvdt起始点识别失败')
    error('dvdt起始点识别失败')
end
rise_end_idx  = find(Vce(rise_start_idx:window_dv(end)) >= V_90, 1, 'first') + rise_start_idx - 1;
if isempty(rise_end_idx)
    print('dvdt结束点识别失败')
    error('dvdt结束点识别失败')
end
delta_time = time(rise_end_idx) - time(rise_start_idx); % 时间差(ns转秒)


if (rise_end_idx - rise_start_idx)>0
    dvdt = (Vce(rise_end_idx ) - Vce(rise_start_idx)) / delta_time * 1e-6;
else
    dvdt = 0;
    warning('dvdt段落识别出现异常')
end

if dvdtmode(3) ~= 10 || dvdtmode(4) ~= 90
    rise_start_idx_a = find(Vce(window_dv) >= V_a, 1, 'first') + window_dv(1) - 1;
    if isempty(rise_start_idx_a)
        print('dvdt起始点识别失败')
        error('dvdt起始点识别失败')
    end
    rise_end_idx_b  = find(Vce(rise_start_idx:window_dv(end)) >= V_b, 1, 'first') + rise_start_idx - 1;
    if isempty(rise_end_idx_b)
        print('dvdt结束点识别失败')
        error('dvdt结束点识别失败')
    end
    delta_time_a_b = time(rise_end_idx_b) - time(rise_start_idx_a); % 时间差(ns转秒)
    
    if (rise_end_idx - rise_start_idx)>0
        dvdt_a_b = (Vce(rise_end_idx_b) - Vce(rise_start_idx_a)) / delta_time_a_b * 1e-6;
    else
        dvdt_a_b = 0;
        warning('dvdt_a_b段落识别出现异常')
    end
else
    dvdt_a_b = 0;
end

% 保持原始绘图逻辑
Riselength = fix((rise_end_idx - rise_start_idx));

PicStart = rise_start_idx - Riselength;
PicEnd = rise_end_idx + 2*Riselength;
PicLength = PicEnd - PicStart;
PicTop = fix(1.05*Vcemax);
PicBottom = fix(-0.05*Vcemax);
PicHeight = PicTop - PicBottom;

plot(time(PicStart:PicEnd), Vce(PicStart:PicEnd), 'b');
hold on;
plot(time(rise_start_idx:rise_end_idx ), Vce(rise_start_idx:rise_end_idx ), 'r', 'LineWidth',1.5);
plot(time(rise_start_idx), Vce(rise_start_idx), 'ro', 'MarkerFaceColor','r');
plot(time(rise_end_idx ), Vce(rise_end_idx ), 'ro', 'MarkerFaceColor','r');
plot(time(window_dv_start), Vce(window_dv_start),'o','color','blue');
plot(time(window_dv_end), Vce(window_dv_end),'o','color','blue');
text(time(fix(rise_start_idx+0.03*PicLength)),Vce(rise_start_idx),['Vce{10}=',num2str(Vce(rise_start_idx)),'V',],'FontSize',13);
text(time(fix(rise_end_idx+0.03*PicLength)),Vce(rise_end_idx),['Vce{90}=',num2str(Vce(rise_end_idx )),'V'],'FontSize',13);
text(time(PicStart+fix(PicLength*0.05)),PicBottom+PicHeight*0.9,['Vcetop = ',num2str(fix(Vcetop+0.5)),'V'],'FontSize',13);
text(time(PicStart+fix(PicLength*0.05)),PicBottom+PicHeight*0.8,['dv/dt = ',num2str(fix(dvdt+0.5)),'V/us'],'FontSize',13);
if dvdtmode(3) ~= 10 || dvdtmode(4) ~= 90
    plot(time(rise_start_idx_a:rise_end_idx_b ), Vce(rise_start_idx_a:rise_end_idx_b ), 'g', 'LineWidth',1.5);
    plot(time(rise_start_idx_a), Vce(rise_start_idx_a), 'ro', 'MarkerFaceColor','g');
    text(time(rise_start_idx_a+3),Vce(rise_start_idx_a),['Vce{',num2str(dvdtmode(3)),'}=',num2str(Vce(rise_start_idx_a)),'V',],'FontSize',13);
    plot(time(rise_end_idx_b), Vce(rise_end_idx_b), 'ro', 'MarkerFaceColor','g');
    text(time(rise_end_idx_b+3),Vce(rise_end_idx_b),['Vce{',num2str(dvdtmode(4)),'}=',num2str(Vce(rise_end_idx_b)),'V',],'FontSize',13);
    text(time(rise_start_idx-fix(Riselength*0.9)),Vcemax*0.7,['dv/dt(',num2str(dvdtmode(3)),'-',num2str(dvdtmode(4)),') = ',num2str(fix(dvdt_a_b+0.5)),'V/us'],'FontSize',13);
end
% 坐标轴设置
ylim([PicBottom, PicTop]);
xlim([time(PicStart), time(PicEnd)]);
title(['Ic=',num2str(fix(Ictop)),'A dv/dt(off)计算']);
grid on;

% 保存路径处理
save_dir = fullfile(path, 'result', dataname, '04 dvdt');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
saveas(gcf, fullfile(save_dir, [ num,' Ic=',num2str(fix(Ictop)),'A dvdt(off).png']), 'png');
close(gcf);
hold off

% 若启动额外dvdt计算 则dvdt表格输出按照手动设置组输出
dvdt_off = (dvdtmode(3) ~= 10 || dvdtmode(4) ~= 90) * dvdt_a_b + (dvdtmode(3) == 10 && dvdtmode(4) == 90) * dvdt;

%% 开通dv/dt计算模块
max_search_length = fix((SWon_stop - SWon_start)/5);
window_dv_start = max(1, SWon_start-max_search_length);  % 起始索引不低于1
window_dv_end = min(length(Vce), SWon_stop+max_search_length);  % 终止索引不超过数组长度
window_dv = window_dv_start : window_dv_end;

fall_start_idx_c = find(Vce(window_dv) <= V_c, 1, 'first') + window_dv(1) - 1;
if isempty(fall_start_idx_c)
    print('dvdt起始点识别失败')
    error('dvdt起始点识别失败')
end
fall_end_idx_d  = find(Vce(fall_start_idx_c:window_dv(end)) <= V_d, 1, 'first') + fall_start_idx_c - 1;
if isempty(fall_end_idx_d)
    print('dvdt结束点识别失败')
    error('dvdt结束点识别失败')
end
delta_time_c_d = time(fall_end_idx_d) - time(fall_start_idx_c); % 时间差(ns转秒)

if (fall_end_idx_d - fall_start_idx_c)>0
    dvdt_c_d = (Vce(fall_end_idx_d) - Vce(fall_start_idx_c)) / delta_time_c_d * 1e-6;
else
    dvdt_c_d = 0;
    warning('dvdt_c_d段落识别出现异常')
end

Falllength = abs(fix((fall_end_idx_d - fall_start_idx_c)));
PicStart = fall_start_idx_c - 2*Falllength;
PicEnd = fall_end_idx_d + 2*Falllength;
PicLength = PicEnd - PicStart;
PicTop = fix(1.05*Vcemax);
PicBottom = fix(-0.05*Vcemax);
PicHeight = PicTop - PicBottom;

plot(time(PicStart:PicEnd), Vce(PicStart:PicEnd), 'b');
hold on;
plot(time(fall_start_idx_c:fall_end_idx_d ), Vce(fall_start_idx_c:fall_end_idx_d ), 'r', 'LineWidth',1.5);
plot(time(fall_start_idx_c), Vce(fall_start_idx_c), 'ro', 'MarkerFaceColor','r');
text(time(fix(fall_start_idx_c+0.03*PicLength)),Vce(fall_start_idx_c),['Vce{',num2str(dvdtmode(1)),'}=',num2str(Vce(fall_start_idx_c)),'V',],'FontSize',13);
plot(time(fall_end_idx_d), Vce(fall_end_idx_d), 'ro', 'MarkerFaceColor','r');
text(time(fix(fall_end_idx_d+0.03*PicLength)),Vce(fall_end_idx_d),['Vce{',num2str(dvdtmode(2)),'}=',num2str(Vce(fall_end_idx_d)),'V',],'FontSize',13);
plot(time(window_dv_start), Vce(window_dv_start),'o','color','blue');
plot(time(window_dv_end), Vce(window_dv_end),'o','color','blue');
text(time(PicStart+fix(PicLength*0.05)),PicBottom+PicHeight*0.8,['Vcetop = ',num2str(fix(Vcetop+0.5)),'V'],'FontSize',13);
text(time(PicStart+fix(PicLength*0.05)),PicBottom+PicHeight*0.7,['dv/dt = ',num2str(fix(dvdt_c_d+0.5)),'V/us'],'FontSize',13);

% 坐标轴设置
ylim([PicBottom, PicTop]);
xlim([time(PicStart), time(PicEnd)]);
title(['Ic=',num2str(fix(Ictop)),'A dv/dt(on)计算']);
grid on;

% 保存路径处理
save_dir = fullfile(path, 'result', dataname, '04 dvdt');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
saveas(gcf, fullfile(save_dir, [ num,' Ic=',num2str(fix(Ictop)),'A dvdt(on).png']), 'png');
close(gcf);
hold off

dvdt_on = dvdt_c_d;
if dvdtmode(3) ~= 10 || dvdtmode(4) ~= 90
    Tdvdt = [fall_start_idx_c,fall_end_idx_d,rise_start_idx_a,rise_end_idx_b];
else
    Tdvdt = [fall_start_idx_c,fall_end_idx_d,rise_start_idx,rise_end_idx];
end
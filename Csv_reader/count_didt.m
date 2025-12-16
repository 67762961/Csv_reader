function [didt_on,didt_off,Tdidt_on_Start,Tdidt_on_Stop] = count_didt(num,didtmode,gate_didt,time,ch3,Ictop,path,dataname,cntSW)

% ====================== 开通时刻 di/dt计算模块 ======================

SWon_start = cntSW(1);
SWon_stop = cntSW(2);
SWoff_start = cntSW(3);
SWoff_stop = cntSW(4);

% 阈值定义
Ic_a  = Ictop * didtmode(1)/100;
Ic_b  = Ictop * didtmode(2)/100;

% 状态机参数初始化
state = 0; % 0:等待触发 1:低阈值触发 2:完成检测
valid_rise_start = [];
valid_rise_end = [];

% 动态窗口生成
max_search_length = fix((SWon_stop - SWon_start)/3);
Window_Start = fix(SWon_start - max_search_length);
Window_Stop = fix(SWon_stop + max_search_length);
window_di = Window_Start : Window_Stop;

% 状态机主循环
for i = window_di
    % if ch3(i) >= 0
    %     fprintf('采样点 %f\n',ch3(i))
    % end
    switch state
        case 0 % 等待触发
            if ch3(i) >= Ic_a
                valid_rise_start = i;
                % fprintf('触发值 %f\n',ch3(valid_rise_start))
                state = 1;
            end
            
        case 1 % 低阈值触发
            if max(ch3(i:i+gate_didt(1))) < ch3(i-1)
                % fprintf('因为 %f < %f 触发回落\n',min(ch3(i:i+10)), ch3(i-1))
                state = 0; % 发现回落重置
                valid_rise_start = [];
            else
                if ch3(i) >= Ic_b
                    valid_rise_end = i;
                    % 完成检测
                    break;
                end
            end
    end
end

% 带保护的计算逻辑
if time(valid_rise_end) == time(valid_rise_start)
    didt_on = 0;
else
    delta_time = time(valid_rise_end) - time(valid_rise_start); % 时间差(ns转秒)
    didt_on = (ch3(valid_rise_end) - ch3(valid_rise_start)) / delta_time * 1e-6;
end

if isempty(didt_on)
    didt_on = 0;
end

% 绘图
% [~, max_idx] = max(ch3(window_di));          % 快速定位峰值索引 max_idx为相对索引
% tIcm = Window_Start + max_idx - 1;          % 转换为全局索引

SWonlength = fix((Window_Stop - Window_Start)/5);
PicStart = Window_Start - SWonlength;
PicEnd = Window_Stop + SWonlength;
PicLength = PicEnd - PicStart;
PicTop = fix(1.05*max(abs(ch3(PicStart:PicEnd))));
PicBottom = fix(-0.05*PicTop);
PicHeight = PicTop - PicBottom;

plot(time(PicStart:PicEnd), ch3(PicStart:PicEnd), 'b');
hold on;
plot(time(valid_rise_start:valid_rise_end), ch3(valid_rise_start:valid_rise_end), 'r', 'LineWidth',1.5);
% plot(time(Window_Start:Window_Stop), zeros(Window_Stop-Window_Start+1), 'Black');
plot(time(valid_rise_start), ch3(valid_rise_start), 'ro', 'MarkerFaceColor','r');
plot(time(valid_rise_end), ch3(valid_rise_end), 'ro', 'MarkerFaceColor','r');

% 动态标注
text(time(fix(valid_rise_start+0.03*PicLength)),ch3(valid_rise_start),['Ic',num2str(didtmode(1)),'=',num2str(ch3(valid_rise_start)),'A'],'FontSize',13);
text(time(fix(valid_rise_end+0.03*PicLength)),ch3(valid_rise_end),['Ic',num2str(didtmode(2)),'=',num2str(ch3(valid_rise_end)),'A'],'FontSize',13);
text(time(PicStart+fix(PicLength*0.05)),PicBottom+PicHeight*0.9,['Ictop=',num2str(fix(Ictop)),'A'],'FontSize',13);
text(time(PicStart+fix(PicLength*0.05)),PicBottom+PicHeight*0.8,['di/dt=',num2str(fix(didt_on+0.5)),'A/us'],'FontSize',13);
plot(time(Window_Start), ch3(Window_Start),'o','color','blue');
plot(time(Window_Stop), ch3(Window_Stop),'o','color','blue');
ylim([PicBottom, PicTop]);
xlim([time(PicStart), time(PicEnd)]);
title(['Ic=',num2str(fix(Ictop)),'A di/dt(on) 计算']);
grid on;

% 保存处理
save_dir = fullfile(path, 'result', dataname, '05 didt');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
saveas(gcf, fullfile(save_dir, [ num,' Ic=',num2str(fix(Ictop)),'A didt(on).png']), 'png');
close(gcf);
hold off

Tdidt_on_Start = valid_rise_start;
Tdidt_on_Stop = valid_rise_end;


% ====================== 关断时刻 di/dt计算模块 ======================
% 动态窗口生成
max_search_length = fix((SWoff_stop - SWoff_start)/3);
Window_Start = fix(SWoff_start - max_search_length);
Window_Stop = fix(SWoff_stop + max_search_length);
window_di = Window_Start : Window_Stop;

valid_fall_start = [];
valid_fall_end = [];
state = 0;

% 状态机主循环
for i = window_di
    switch state
        case 0 % 等待触发
            if ch3(i) <= Ic_b
                valid_fall_start = i;
                % fprintf('触发值 %f\n',ch3(valid_fall_start))
                state = 1;
            end
            
        case 1 % 低阈值触发
            if min(ch3(i:i+gate_didt(2))) > ch3(i-1)
                % fprintf('因为 %f > %f 触发回落\n',min(ch3(i:i+10)), ch3(i-1))
                state = 0; % 发现回落重置
                valid_fall_start = [];
            else
                if ch3(i) <= Ic_a
                    valid_fall_end = i;
                    % 完成检测
                    break;
                end
            end
    end
end

% 带保护的计算逻辑
if time(valid_fall_end) == time(valid_fall_start)
    didt_off = 0;
else
    delta_time = time(valid_fall_end) - time(valid_fall_start); % 时间差(ns转秒)
    didt_off = (ch3(valid_fall_end) - ch3(valid_fall_start)) / delta_time * 1e-6;
end

if isempty(didt_off)
    didt_off = 0;
end

PicLength = Window_Stop - Window_Start;
PicStart = Window_Start-PicLength;
PicEnd = Window_Stop+PicLength;
PicLength = PicEnd - PicStart;
PicTop = fix(1.5*max(abs(ch3(PicStart:PicEnd))));
PicBottom = fix(-0.1*PicTop);
PicHeight = PicTop - PicBottom;


plot(time(PicStart:PicEnd), ch3(PicStart:PicEnd), 'b');
hold on;
plot(time(valid_fall_start:valid_fall_end), ch3(valid_fall_start:valid_fall_end), 'r', 'LineWidth',1.5);
plot(time(valid_fall_start), ch3(valid_fall_start), 'ro', 'MarkerFaceColor','r');
plot(time(valid_fall_end), ch3(valid_fall_end), 'ro', 'MarkerFaceColor','r');
plot(time(Window_Start), ch3(Window_Start),'o','color','blue');
plot(time(Window_Stop), ch3(Window_Stop),'o','color','blue');

% 动态标注
text(time(fix(valid_fall_start+0.05*PicLength)),ch3(valid_fall_start),['Ic',num2str(didtmode(2)),'=',num2str(ch3(valid_fall_start)),'A'],'FontSize',13);
text(time(fix(valid_fall_end+0.05*PicLength)),ch3(valid_fall_end),['Ic',num2str(didtmode(1)),'=',num2str(ch3(valid_fall_end)),'A'],'FontSize',13);
text(time(PicStart+fix(PicLength*0.05)),PicBottom+PicHeight*0.9,['Ictop=',num2str(fix(Ictop+0.5)),'A'],'FontSize',13);
text(time(PicStart+fix(PicLength*0.05)),PicBottom+PicHeight*0.8,['di/dt=',num2str(fix(didt_off+0.5)),'A/us'],'FontSize',13);

ylim([PicBottom, PicTop]);
xlim([time(PicStart), time(PicEnd)]);
title(['Ic=',num2str(fix(Ictop)),'A di/dt(off) 计算']);
grid on;

% 保存处理
save_dir = fullfile(path, 'result', dataname, '05 didt');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
saveas(gcf, fullfile(save_dir, [ num,' Ic=',num2str(fix(Ictop)),'A didt(off).png']), 'png');
close(gcf);
hold off
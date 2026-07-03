function [didt_on,didt_off,Tdidt,Pic_win] = count_didt(num,DPI,didtmode,gate_didt,time,ch3,I_on,I_off,path,dataname,cntVge,Wave_count)

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

% 阈值定义
Ic_a  = I_on * didtmode(1)/100;
Ic_b  = I_on * didtmode(2)/100;
Ic_c  = I_off * didtmode(3)/100;
Ic_d  = I_off * didtmode(4)/100;

% 状态机参数初始化
state = 0; % 0:等待触发 1:低阈值触发 2:完成检测
valid_rise_start = [];
valid_rise_end = [];

% 动态窗口生成
% max_search_length = fix(2*min(cnton1,cnton2));
Window_Start = Posedge(1);
Window_Stop = Posedge(end);
window_di = Window_Start : Window_Stop;

% 状态机主循环
for i = window_di
    % fprintf('采样点 %f\n',ch3(i))
    switch state
        case 0 % 等待触发
            if ch3(i) >= Ic_a
                valid_rise_start = i;
                % fprintf('起始点 %f 大于 %.2f Ictop = %f 触发\n',ch3(valid_rise_start),didtmode(1)/100,didtmode(1)/100*I_on)
                state = 1;
                Diff1 = abs(ch3(valid_rise_start) - didtmode(1)/100*I_on);
                Diff2 = abs(ch3(valid_rise_start - 1) - didtmode(1)/100*I_on);
                if Diff1 > Diff2
                    valid_rise_start = valid_rise_start - 1;
                    % fprintf('前一采样点 %f 与阈值差异更小 %f < %f回退一个采样点\n',ch3(valid_rise_start),Diff2,Diff1);
                end
            end
            
        case 1 % 低阈值触发
            if max(ch3(i:i+gate_didt(1))) < ch3(i-1)
                % fprintf('因为 %f < %f 触发回落\n',min(ch3(i:i+gate_didt(1))), ch3(i-1))
                state = 0; % 发现回落重置
                valid_rise_start = [];
            else
                if ch3(i) >= Ic_b
                    valid_rise_end = i;
                    % 完成检测
                    % fprintf('结束点 %f 大于 %.2f Ictop = %f 触发 \n',ch3(valid_rise_end),didtmode(2)/100,didtmode(2)/100*I_on)
                    Diff1 = abs(ch3(valid_rise_end) - didtmode(2)/100*I_on);
                    Diff2 = abs(ch3(valid_rise_end - 1) - didtmode(2)/100*I_on);
                    if Diff1 > Diff2
                        valid_rise_start = valid_rise_start - 1;
                        % fprintf('前一采样点 %f 与阈值差异更小 %f < %f回退一个采样点\n',ch3(valid_rise_end),Diff2,Diff1);
                    end
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

SWonlength = 5*fix(valid_rise_end - valid_rise_start);
Half_PicLength = fix(SWonlength/abs(didtmode(2)-didtmode(1))*200);
PicStart = valid_rise_start - Half_PicLength;
PicEnd = valid_rise_end + Half_PicLength;
PicLength = PicEnd - PicStart;
PicTop = abs(fix(1.05*max(abs(ch3(PicStart:PicEnd)))));
PicBottom = fix(-0.2*PicTop);
PicHeight = PicTop - PicBottom;
Pic_win(1:4) = [PicTop,PicBottom,PicStart,PicEnd];

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
text(time(fix(valid_rise_start+0.03*PicLength)),ch3(valid_rise_start),['Ic',num2str(didtmode(1)),'=',num2str(ch3(valid_rise_start)),'A'],'FontSize',13);
text(time(fix(valid_rise_end+0.03*PicLength)),ch3(valid_rise_end),['Ic',num2str(didtmode(2)),'=',num2str(ch3(valid_rise_end)),'A'],'FontSize',13);
text(time(PicStart+fix(PicLength*0.05)),PicBottom+PicHeight*0.9,['Ictop = ',num2str(fix(I_on)),'A'],'FontSize',13);
text(time(PicStart+fix(PicLength*0.05)),PicBottom+PicHeight*0.8,['di/dt = ',num2str(fix(didt_on+0.5)),'A/us'],'FontSize',13);
plot(time(Window_Start), ch3(Window_Start),'o','color','blue');
plot(time(Window_Stop), ch3(Window_Stop),'o','color','blue');
text(time(valid_rise_start),PicBottom+PicHeight*0.03,[num2str(time(valid_rise_start)*1e6),'us'],'FontSize',8,'color','r');
text(time(valid_rise_end),PicBottom+PicHeight*0.07,[num2str(time(valid_rise_end)*1e6),'us'],'FontSize',8,'color','r');
line([time(valid_rise_start),time(valid_rise_start)],[PicBottom+PicHeight*0.03,ch3(valid_rise_start)],'Color', 'r','LineStyle','--');
line([time(valid_rise_end),time(valid_rise_end)],[PicBottom+PicHeight*0.07,ch3(valid_rise_end)],'Color', 'r','LineStyle','--');

ylim([PicBottom, PicTop]);
xlim([time(PicStart), time(PicEnd)]);
title(['Ic=',num2str(fix(I_on)),'A di/dt(on) 计算']);
grid on;

% ====================== 关断时刻 di/dt计算模块 ======================
% 动态窗口生成
Window_Start = Negedge(1);
Window_Stop = Negedge(end);
window_di = Window_Start : Window_Stop;

valid_fall_start = [];
valid_fall_end = [];
state = 0;

% 状态机主循环
for i = window_di
    % fprintf('采样点 %f\n',ch3(i))
    switch state
        case 0 % 等待触发
            if ch3(i) <= Ic_c
                valid_fall_start = i;
                % fprintf('起始点 %f 小于 %.2f Ictop = %f 触发\n',ch3(valid_fall_start),didtmode(3)/100,didtmode(3)/100*I_off)
                state = 1;
                Diff1 = abs(ch3(valid_fall_start) - didtmode(3)/100*I_off);
                Diff2 = abs(ch3(valid_fall_start - 1) - didtmode(3)/100*I_off);
                if Diff1 > Diff2
                    valid_fall_start = valid_fall_start - 1;
                    % fprintf('前一采样点 %f 与阈值差异更小 %f < %f回退一个采样点\n',ch3(valid_fall_start),Diff2,Diff1);
                end
            end
            
        case 1 % 低阈值触发
            if min(ch3(i:i+gate_didt(2))) > ch3(i-1)
                % fprintf('因为 %f > %f 触发回落\n',min(ch3(i:i+10)), ch3(i-1))
                state = 0; % 发现回落重置
                valid_fall_start = [];
            else
                if ch3(i) <= Ic_d
                    valid_fall_end = i;
                    % 完成检测
                    % fprintf('结束点 %f 小于 %.2f Ictop = %f 触发 \n',ch3(valid_fall_end),didtmode(4)/100,didtmode(4)/100*I_off)
                    Diff1 = abs(ch3(valid_fall_end) - didtmode(4)/100*I_off);
                    Diff2 = abs(ch3(valid_fall_end - 1) - didtmode(4)/100*I_off);
                    if Diff1 > Diff2
                        valid_fall_end = valid_fall_end - 1;
                        % fprintf('前一采样点 %f 与阈值差异更小 %f < %f回退一个采样点\n',ch3(valid_fall_end),Diff2,Diff1);
                    end
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

SWonlength = 5*fix(valid_fall_end - valid_fall_start);
Half_PicLength = fix(SWonlength/abs(didtmode(4)-didtmode(3))*100);
PicStart = valid_fall_start - Half_PicLength;
PicEnd = valid_fall_end + Half_PicLength;
PicLength = PicEnd - PicStart;
PicTop = fix(1.5*max(abs(ch3(PicStart:PicEnd))));
PicBottom = fix(-0.2*PicTop);
PicHeight = PicTop - PicBottom;
Pic_win(5:8) = [PicTop,PicBottom,PicStart,PicEnd];

subplot('Position', [0.55, 0.15, 0.4, 0.75]);
plot(time(PicStart:PicEnd), ch3(PicStart:PicEnd), 'b');
hold on;
plot(time(valid_fall_start:valid_fall_end), ch3(valid_fall_start:valid_fall_end), 'r', 'LineWidth',1.5);
plot(time(valid_fall_start), ch3(valid_fall_start), 'ro', 'MarkerFaceColor','r');
plot(time(valid_fall_end), ch3(valid_fall_end), 'ro', 'MarkerFaceColor','r');
plot(time(Window_Start), ch3(Window_Start),'o','color','blue');
plot(time(Window_Stop), ch3(Window_Stop),'o','color','blue');

% 动态标注
text(time(fix(valid_fall_start+0.05*PicLength)),ch3(valid_fall_start),['Ic',num2str(didtmode(3)),'=',num2str(ch3(valid_fall_start)),'A'],'FontSize',13);
text(time(fix(valid_fall_end+0.05*PicLength)),ch3(valid_fall_end),['Ic',num2str(didtmode(4)),'=',num2str(ch3(valid_fall_end)),'A'],'FontSize',13);
text(time(PicStart+fix(PicLength*0.05)),PicBottom+PicHeight*0.9,['Ictop = ',num2str(fix(I_off+0.5)),'A'],'FontSize',13);
text(time(PicStart+fix(PicLength*0.05)),PicBottom+PicHeight*0.8,['di/dt = ',num2str(fix(didt_off+0.5)),'A/us'],'FontSize',13);
text(time(valid_fall_start),PicBottom+PicHeight*0.03,[num2str(time(valid_fall_start)*1e6),'us'],'FontSize',8,'color','r');
text(time(valid_fall_end),PicBottom+PicHeight*0.07,[num2str(time(valid_fall_end)*1e6),'us'],'FontSize',8,'color','r');
line([time(valid_fall_start),time(valid_fall_start)],[PicBottom+PicHeight*0.03,ch3(valid_fall_start)],'Color', 'r','LineStyle','--');
line([time(valid_fall_end),time(valid_fall_end)],[PicBottom+PicHeight*0.07,ch3(valid_fall_end)],'Color', 'r','LineStyle','--');

ylim([PicBottom, PicTop]);
xlim([time(PicStart), time(PicEnd)]);
title(['Ic=',num2str(fix(I_off)),'A di/dt(off) 计算']);
grid on;

% 保存处理
save_dir = fullfile(path, 'result', dataname, '05 didt');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
saveas(gcf, fullfile(save_dir, [ num,' Ic=',num2str(fix(I_off)),'A didt.png']), 'png');
close(gcf);
hold off

Tdidt = [valid_rise_start,valid_rise_end,valid_fall_start,valid_fall_end];
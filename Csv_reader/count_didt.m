function [didt,tonIcm10,tonIcm90] = count_didt(num,nspd,didtmode,gate_didt,time,ch3,Ictop,path,dataname,SWon_start,SWon_stop)

% ====================== di/dt计算模块 ======================

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
            if max(ch3(i:i+gate_didt)) < ch3(i-1)
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
    didt = 0;
else
    delta_time = (valid_rise_end  - valid_rise_start) * nspd * 1e-9;      % 时间差(ns转秒)
    didt = (ch3(valid_rise_end) - ch3(valid_rise_start)) / delta_time * 1e-6;
end

if isempty(didt)
    didt = 0;
end

% 绘图
% figure;
SWonlength = fix((SWon_stop - SWon_start));

PicStart = valid_rise_start - SWonlength;
PicEnd = valid_rise_end + SWonlength;
PicLength = PicEnd - PicStart;
PicTop = fix(1.05*max(abs(ch3(PicStart:PicEnd))));
PicBottom = fix(-0.05*PicTop);
% PicHeight = PicTop - PicBottom;

plot(time(PicStart:valid_rise_end + SWonlength), ch3(PicStart:valid_rise_end + SWonlength), 'b');
hold on;
plot(time(valid_rise_start:valid_rise_end), ch3(valid_rise_start:valid_rise_end), 'r', 'LineWidth',1.5);
% plot(time(Window_Start:Window_Stop), zeros(Window_Stop-Window_Start+1), 'Black');
plot(time(valid_rise_start), ch3(valid_rise_start), 'ro', 'MarkerFaceColor','r');
plot(time(valid_rise_end), ch3(valid_rise_end), 'ro', 'MarkerFaceColor','r');

% 动态标注
text(time(valid_rise_start+3),ch3(valid_rise_start),['Ic',num2str(didtmode(1)),'=',num2str(ch3(valid_rise_start)),'A'],'FontSize',13);
text(time(valid_rise_end+3),ch3(valid_rise_end),['Ic',num2str(didtmode(2)),'=',num2str(ch3(valid_rise_end)),'A'],'FontSize',13);
text(time(PicStart+fix(PicLength*0.05)),PicTop*0.9,['Ictop=',num2str(Ictop),'A'],'FontSize',13);
text(time(PicStart+fix(PicLength*0.05)),PicTop*0.8,['di/dt=',num2str(didt),'A/us'],'FontSize',13);

ylim([PicBottom, PicTop]);
xlim([time(PicStart), time(PicEnd)]);
title(['Ic=',num2str(fix(Ictop)),'A di/dt计算']);
grid on;

% 保存处理
save_dir = fullfile(path, 'pic', dataname, 'didt');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
saveas(gcf, fullfile(save_dir, [ num,' Ic=',num2str(fix(Ictop)),'A didt.png']), 'png');
close(gcf);
hold off

tonIcm10 = valid_rise_start;
tonIcm90 = valid_rise_end;
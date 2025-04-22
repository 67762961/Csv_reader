function [didt] = count_didt(num,nspd,didtmode,gate_didt,time,ch3,Ictop,path,dataname,tdon,SWon_start,SWon_stop)

% ====================== di/dt计算模块 ======================

% 阈值定义
Ic_a  = Ictop * didtmode(1)/100;
Ic_b  = Ictop * didtmode(2)/100;

% 状态机参数初始化
state = 0; % 0:等待触发 1:低阈值触发 2:完成检测
valid_rise_start = [];
valid_rise_end = [];

% 动态窗口生成
time_step = nspd * 1e-9; 
max_search_length = fix(2e-9 * tdon / time_step);
window_di = fix(SWon_start - max_search_length): fix(SWon_stop + max_search_length);

% 状态机主循环
for i = window_di
    if ch3(i) >= 0
        % fprintf('采样点 %f\n',ch3(i))
    end
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
                    state = 2;
                end
            end
            
        case 2 % 完成检测
            break;
    end
end

valid_rise_length = valid_rise_end - valid_rise_start; 

% fprintf('valid_rise_start = %f\nvalid_rise_end = %f\n',ch3(valid_rise_start),ch3(valid_rise_end));

% 带保护的计算逻辑
if time(valid_rise_end) == time(valid_rise_start)
    didt = 0;
else
    didt = (ch3(valid_rise_end) - ch3(valid_rise_start)) / (time(valid_rise_end)-time(valid_rise_start)) / 1e6;
end

if isempty(didt)
    didt = 0;
end

% 绘图
% figure;
plot(time(SWon_start-50:SWon_stop+50), ch3(SWon_start-50:SWon_stop+50), 'b');
hold on;
plot(time(valid_rise_start:valid_rise_end), ch3(valid_rise_start:valid_rise_end), 'r', 'LineWidth',1.5);
plot(time(valid_rise_start), ch3(valid_rise_start), 'ro', 'MarkerFaceColor','r');
plot(time(valid_rise_end), ch3(valid_rise_end), 'ro', 'MarkerFaceColor','r');

% 动态标注
text(time(valid_rise_start+3),ch3(valid_rise_start),['Ic',num2str(didtmode(1)),'=',num2str(ch3(valid_rise_start)),'A'],'FontSize',13);
text(time(valid_rise_end+3),ch3(valid_rise_end),['Ic',num2str(didtmode(2)),'=',num2str(ch3(valid_rise_end)),'A'],'FontSize',13);
text(time(valid_rise_start-3*valid_rise_length+fix(valid_rise_length/10)),max(ch3(SWon_start-50:SWon_stop))*0.9,['Ictop=',num2str(Ictop),'A'],'FontSize',13);
text(time(valid_rise_start-3*valid_rise_length+fix(valid_rise_length/10)),max(ch3(SWon_start-50:SWon_stop))*0.8,['di/dt=',num2str(didt),'A/us'],'FontSize',13);

% 坐标轴设置
ylim([-5, max(ch3(SWon_start-50:SWon_stop+50))*1.1]);
xlim([time(valid_rise_start-3*valid_rise_length), time(valid_rise_end+3*valid_rise_length)]);
title(['Ic=',num2str(fix(Ictop)),'A di/dt计算']);
grid on;

% 保存处理
save_dir = fullfile(path, 'pic', dataname, 'didt');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
saveas(gcf, fullfile(save_dir, [ num,' Ic=',num2str(fix(Ictop)),'A didt.png']), 'png');
close(gcf);
hold off
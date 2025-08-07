function [Eon,SWon_start,SWon_stop] = count_Eon(num,time,Ic,Vce,Ictop,Vcetop,path,dataname,ton2,toff2,cntoff1)

%% ====================== 开通损耗计算（Eon） ======================
% 初始化并计算开通损耗能量
%开通起始时刻寻找
search_start = max(fix(ton2 - cntoff1/4), 1);  % 防止负索引
valid_range = search_start:min(toff2, length(Ic));
SWon_start_indices = find(Ic(valid_range) >= max(0.15*Ictop, 3), 1, 'first');
SWon_start = valid_range(1) + SWon_start_indices - 1;

%开通结束时刻寻找 
SWon_stop_indices = find(Vce(valid_range) <= Vcetop*0.1, 1, 'first');
SWon_stop = valid_range(1) + SWon_stop_indices - 1;

Window_width = SWon_stop - SWon_start;
Window_extend = fix(Window_width/6);
Pon = zeros(size(time)); % 预分配内存
windowEon = (SWon_start - Window_extend):(SWon_stop + Window_extend); % 定义计算窗口

% 向量化计算功率和能量
Pon(windowEon) = Vce(windowEon) .* Ic(windowEon) * 1000; % 功率计算（mW）
dt = diff(time(windowEon)); % 时间差分
Eon = sum(Pon(windowEon(2:end)) .* dt); % 梯形积分法（mJ）

% 归一化处理
Ponmax = max(Pon(windowEon));
Pon_normalized = Pon(windowEon) / Ponmax / 2; % 归一化到[-0.5, 0.5]范围

% 可视化设置
% figure;
plot(time(windowEon),Pon_normalized,'r', 'LineWidth',1.2);
hold on
plot(time,Vce/Vcetop,'g');
plot(time,Ic/max(Ic),'b');
xlim([time(SWon_start-100),time(SWon_stop+100)]);
ylim([-0.2,1.2]);

% 标注和格式设置
text(time(SWon_start-80),1.1,['Eon=',num2str(Eon),'mJ'],'FontSize',13);
text(time(SWon_start-30),0.4,'Pon','color','red','FontSize',13);
text(time(SWon_start),0.9,'Vce','color','green','FontSize',13);
text(time(SWon_stop),0.9,'Ic','color','blue','FontSize',13);
legend('P_{on}','V_{ce}','I_c', 'Location','northeast');
legend('boxoff');
title(sprintf('Ic=%dA 开通损耗分析（归一化）', fix(Ictop)));
grid on;

saveas(gcf,[[path,'.\pic\',dataname,'\Eigbt\'],[num,' Ic=',num2str(fix(Ictop)),'A Eon'],'.png'])
close(gcf)
hold off
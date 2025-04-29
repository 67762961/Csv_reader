function [Eoff,SWoff_start,SWoff_stop] = count_Eoff(num,time,Ic,Vce,Ictop,Vcetop,path,dataname,ton2,toff90)

%% ====================== 关断损耗计算（Eoff） ======================
%关断起始时刻寻找
valid_range = toff90:min(ton2, length(Vce));
SWoff_start_indices = find(Vce(valid_range) >= Vcetop*0.1, 1, 'first');
SWoff_start = valid_range(1) + SWoff_start_indices - 1;

%关断结束时刻寻找
valid_range = SWoff_start:min(ton2, length(Ic));
SWoff_stop_indices = find(Ic(valid_range) <= Ictop*0.02, 1, 'first');
SWoff_stop = valid_range(1) + SWoff_stop_indices - 1;

% 初始化并计算关断损耗能量
Poff = zeros(size(time));
windowEoff = SWoff_start:SWoff_stop;

% 向量化计算
Poff(windowEoff) = Vce(windowEoff) .* Ic(windowEoff) * 1000;
dt_off = diff(time(windowEoff));
Eoff = sum(Poff(windowEoff(2:end)) .* dt_off);

% 归一化处理
Poffmax = max(Poff(windowEoff));
Poff_normalized = Poff(windowEoff) / Poffmax / 2;

% 可视化
% figure;
plot(time(windowEoff), Poff_normalized, 'r', 'LineWidth',1.2);
hold on
plot(time,Vce/Vcetop,'g');
plot(time,Ic/Ictop,'b');
xlim([time(SWoff_start-100),time(SWoff_stop+100)]);
ylim([-0.2,1.5]);

% 标注
text(time(SWoff_start-80),1.1,['Eoff=',num2str(Eoff),'mJ'],'FontSize',13);
text(time(SWoff_start),0.45,'Poff','color','red','FontSize',13);
text(time(SWoff_stop),0.95,'Vce','color','green','FontSize',13);
text(time(SWoff_start),0.95,'Ic','color','blue','FontSize',13);
legend('P_{off}','V_{ce}','I_c', 'Location','northeast');
title(sprintf('Ic=%dA 关断损耗分析（归一化）', fix(Ictop)));
grid on;

% 保存
saveas(gcf,[[path,'.\pic\',dataname,'\Eigbt\'],[num,' Ic=',num2str(fix(Ictop)),'A Eoff'],'.png'])
close(gcf);
hold off
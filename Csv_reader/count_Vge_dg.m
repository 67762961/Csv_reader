function [Vge_dg_mean,Vge_dg_max,Vge_dg_min] = count_Vge_dg(num,time,ch6,Vge_dg,Ictop,path,dataname,cnton2)

%% 对管门极监测
% 找出全局最大值
[Vge_dg_max, cemax_idx_max] = max(ch6);


% 找出全局最小值
[Vge_dg_min, cemax_idx_min] = min(ch6);

Vge_dg_mean = mean(Vge_dg); 

% 最大值绘图
Win_Width = fix(cnton2/4);
Hlim = abs(Vge_dg_max - Vge_dg_min);
Pic_start_max = cemax_idx_max - Win_Width;
Pic_stop_max = cemax_idx_max + Win_Width;

plot(time(Pic_start_max:Pic_stop_max), ch6(Pic_start_max:Pic_stop_max), 'b');
hold on;
plot(time(cemax_idx_max), Vge_dg_max, 'ro', 'MarkerFaceColor','r');
text(time(Pic_start_max), Vge_dg_mean + Hlim*0.85, ['V_g_e对管mean=',num2str(Vge_dg_mean),'V'], 'FontSize',13);
text(time(Pic_start_max), Vge_dg_mean + Hlim*0.7, ['V_g_e对管max=',num2str(Vge_dg_max),'V'], 'FontSize',13);
ylim([Vge_dg_mean - fix(0.7*Hlim), Vge_dg_mean + Hlim]);
title(['Ic=',num2str(fix(Ictop)),'A Vge-dg-max']);
grid on;

% 路径构建优化
save_dir = fullfile(path, 'pic', dataname, 'Vge_dg');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
saveas(gcf, fullfile(save_dir, [ num, ' Ic=',num2str(fix(Ictop)),'A Vge_dg_max.png']), 'png');
close(gcf);
hold off


% 最小值绘图
Pic_start_min = cemax_idx_min - Win_Width;
Pic_stop_min= cemax_idx_min + Win_Width;

plot(time(Pic_start_min:Pic_stop_min), ch6(Pic_start_min:Pic_stop_min), 'b');
hold on;
plot(time(cemax_idx_min), Vge_dg_min, 'ro', 'MarkerFaceColor','r');
text(time(Pic_start_min), Vge_dg_mean + Hlim*0.85, ['V_g_e对管mean=',num2str(Vge_dg_mean),'V'], 'FontSize',13);
text(time(Pic_start_min), Vge_dg_mean + Hlim*0.7, ['V_g_e对管min =',num2str(Vge_dg_min),'V'], 'FontSize',13);
ylim([Vge_dg_mean - fix(0.7*Hlim), Vge_dg_mean + Hlim]);
title(['Ic=',num2str(fix(Ictop)),'A Vge-dg-min']);
grid on;

% 路径构建优化
save_dir = fullfile(path, 'pic', dataname, 'Vge_dg');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
saveas(gcf, fullfile(save_dir, [ num, ' Ic=',num2str(fix(Ictop)),'A Vge_dg_min.png']), 'png');
close(gcf);
hold off
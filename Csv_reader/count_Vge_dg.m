function [Vge_dg_mean,Vge_dg_max,Vge_dg_min] = count_Vge_dg(num,time,Vge_dg,Ictop,path,dataname,cnton2,gd_num)

%% 对管门极监测
% 找出全局最大值
[Vge_dg_max, cemax_idx_max] = max(Vge_dg);


% 找出全局最小值
[Vge_dg_min, cemax_idx_min] = min(Vge_dg);

Vge_dg_mean = mean(Vge_dg);

% 最大值绘图
PicLength = fix(cnton2/2);
PicStart = cemax_idx_max - fix(PicLength/2);
PicEnd =  cemax_idx_max + fix(PicLength/2);
PicHeight = 2*abs(Vge_dg_max - Vge_dg_min);
PicTop = Vge_dg_mean + PicHeight*2/3;
PicBottom = Vge_dg_mean - PicHeight/3;

plot(time(PicStart:PicEnd), Vge_dg(PicStart:PicEnd), 'b');
hold on;
plot(time(cemax_idx_max), Vge_dg_max, 'ro', 'MarkerFaceColor','r');
text(time(PicStart+fix(PicLength*0.05)), PicBottom+PicHeight*0.9, ['V_g_e对管mean=',num2str(Vge_dg_mean),'V'], 'FontSize',13);
text(time(PicStart+fix(PicLength*0.05)), PicBottom+PicHeight*0.8, ['V_g_e对管max=',num2str(Vge_dg_max),'V'], 'FontSize',13);

nspd = time(2)-time(1);
barlength = fix(cnton2/50);
bartimelength = barlength * nspd * 1e-9;
barheight = 0.01*PicHeight;
line([time(cemax_idx_max-barlength),time(cemax_idx_max+barlength)],[Vge_dg_max,Vge_dg_max],'Color', [0.5 0.5 0.5]);
line([time(cemax_idx_max-barlength),time(cemax_idx_max-barlength)],[Vge_dg_max-barheight, Vge_dg_max+barheight], 'Color', [0.5 0.5 0.5]);
line([time(cemax_idx_max+barlength),time(cemax_idx_max+barlength)],[Vge_dg_max-barheight, Vge_dg_max+barheight], 'Color', [0.5 0.5 0.5]);
text(time(cemax_idx_max+barlength+5), Vge_dg_max, [num2str(2*bartimelength),'ns'], 'FontSize', 9,'Color', [0.5 0.5 0.5]);

ylim([PicBottom, PicTop]);
xlim([time(PicStart), time(PicEnd)]);
title(['Ic=',num2str(fix(Ictop)),'A Vge-dg-max']);
grid on;

% 路径构建优化
save_dir = fullfile(path, 'pic', dataname, '08 Vge_dg');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
saveas(gcf, fullfile(save_dir, [ num, ' Ic=',num2str(fix(Ictop)),'A Vge_dg_',num2str(gd_num),'_max.png']), 'png');
close(gcf);
hold off


% 最小值绘图
PicStart = cemax_idx_min - fix(PicLength/2);
PicEnd =  cemax_idx_min + fix(PicLength/2);
PicHeight = 2*abs(Vge_dg_max - Vge_dg_min);

plot(time(PicStart:PicEnd), Vge_dg(PicStart:PicEnd), 'b');
hold on;
plot(time(cemax_idx_min), Vge_dg_min, 'ro', 'MarkerFaceColor','r');
text(time(PicStart+fix(PicLength*0.05)), PicBottom+PicHeight*0.9, ['V_g_e对管mean=',num2str(Vge_dg_mean),'V'], 'FontSize',13);
text(time(PicStart+fix(PicLength*0.05)), PicBottom+PicHeight*0.8, ['V_g_e对管min =',num2str(Vge_dg_min),'V'], 'FontSize',13);
ylim([PicBottom, PicTop]);
xlim([time(PicStart), time(PicEnd)]);
title(['Ic=',num2str(fix(Ictop)),'A Vge-dg-min']);
grid on;

% 路径构建优化
save_dir = fullfile(path, 'pic', dataname, '08 Vge_dg');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
saveas(gcf, fullfile(save_dir, [ num, ' Ic=',num2str(fix(Ictop)),'A Vge_dg_',num2str(gd_num),'min.png']), 'png');
close(gcf);
hold off
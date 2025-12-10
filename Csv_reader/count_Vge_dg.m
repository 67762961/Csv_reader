function [Vge_dg_mean,Vge_dg_max,Vge_dg_min] = count_Vge_dg(num,time,Vge_dg,Ictop,path,dataname,cnton2,toff1,ton2,gd_num)

%% 对管门极监测
Vge_dg_mean = mean(Vge_dg);

% 找出全局最大值
Vge_dg_max = max(Vge_dg);

% 找出全局最小值
Vge_dg_min = min(Vge_dg);

% 开通段绘图
PicLength = fix(cnton2/2);
PicStart = ton2 - fix(PicLength/3);
PicEnd =  ton2 + fix(2*PicLength/3);

[Vge_dg_on_max , cemax_idx_on_max]= max(Vge_dg(PicStart:PicEnd));
[Vge_dg_on_min , cemax_idx_on_min]= min(Vge_dg(PicStart:PicEnd));

PicHeight = abs(Vge_dg_max - Vge_dg_min);
PicTop = Vge_dg_on_max + PicHeight/3;
PicBottom = Vge_dg_on_min - PicHeight/6;
PicHeight = PicTop - PicBottom;

cemax_idx_on_max = cemax_idx_on_max + PicStart -1;
cemax_idx_on_min = cemax_idx_on_min + PicStart -1;

plot(time(PicStart:PicEnd), Vge_dg(PicStart:PicEnd), 'b');
hold on;
plot(time(cemax_idx_on_max), Vge_dg_on_max, 'ro', 'MarkerFaceColor','r');
plot(time(cemax_idx_on_min), Vge_dg_on_min, 'ro', 'MarkerFaceColor','r');
text(time(PicStart+fix(PicLength*0.03)), PicBottom+PicHeight*0.94, ['V_g_e对管mean=',num2str(Vge_dg_mean),'V'], 'FontSize',13);
text(time(PicStart+fix(PicLength*0.03)), PicBottom+PicHeight*0.87, ['V_g_e对管onmax=',num2str(Vge_dg_on_max),'V'], 'FontSize',13);
text(time(PicStart+fix(PicLength*0.03)), PicBottom+PicHeight*0.80, ['V_g_e对管onmin=',num2str(Vge_dg_on_min),'V'], 'FontSize',13);

nspd = (time(2)-time(1))*1e9;
barlength = fix(cnton2/50);
bartimelength = barlength * nspd;
barheight = 0.01*PicHeight;
line([time(cemax_idx_on_max-barlength),time(cemax_idx_on_max+barlength)],[Vge_dg_on_max,Vge_dg_on_max],'Color', [0.5 0.5 0.5]);
line([time(cemax_idx_on_max-barlength),time(cemax_idx_on_max-barlength)],[Vge_dg_on_max-barheight, Vge_dg_on_max+barheight], 'Color', [0.5 0.5 0.5]);
line([time(cemax_idx_on_max+barlength),time(cemax_idx_on_max+barlength)],[Vge_dg_on_max-barheight, Vge_dg_on_max+barheight], 'Color', [0.5 0.5 0.5]);
text(time(cemax_idx_on_max+barlength+5), Vge_dg_on_max, [num2str(2*bartimelength),'ns'], 'FontSize', 9,'Color', [0.5 0.5 0.5]);

ylim([PicBottom, PicTop]);
xlim([time(PicStart), time(PicEnd)]);
title(['Ic=',num2str(fix(Ictop)),'A Vge-dg-on']);
grid on;

% 路径构建优化
save_dir = fullfile(path, 'result', dataname, '07 Vge_dg');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
saveas(gcf, fullfile(save_dir, [ num, ' Ic=',num2str(fix(Ictop)),'A Vge_dg_on_T',num2str(gd_num),'.png']), 'png');
close(gcf);
hold off

% 关断段绘图
PicStart = toff1 - fix(PicLength/3);
PicEnd =  toff1 + fix(2*PicLength/3);

[Vge_dg_off_max , cemax_idx_off_max]= max(Vge_dg(PicStart:PicEnd));
[Vge_dg_off_min , cemax_idx_off_min]= min(Vge_dg(PicStart:PicEnd));
PicTop = Vge_dg_off_max + PicHeight/3;
PicBottom = Vge_dg_off_min - PicHeight/6;
PicHeight = PicTop - PicBottom;

cemax_idx_off_max = cemax_idx_off_max + PicStart -1;
cemax_idx_off_min = cemax_idx_off_min + PicStart -1;

plot(time(PicStart:PicEnd), Vge_dg(PicStart:PicEnd), 'b');
hold on;
plot(time(cemax_idx_off_max), Vge_dg_off_max, 'ro', 'MarkerFaceColor','r');
plot(time(cemax_idx_off_min), Vge_dg_off_min, 'ro', 'MarkerFaceColor','r');
text(time(PicStart+fix(PicLength*0.03)), PicBottom+PicHeight*0.94, ['V_g_e对管mean=',num2str(Vge_dg_mean),'V'], 'FontSize',13);
text(time(PicStart+fix(PicLength*0.03)), PicBottom+PicHeight*0.87, ['V_g_e对管offmax =',num2str(Vge_dg_off_max),'V'], 'FontSize',13);
text(time(PicStart+fix(PicLength*0.03)), PicBottom+PicHeight*0.80, ['V_g_e对管offmin =',num2str(Vge_dg_off_min),'V'], 'FontSize',13);
ylim([PicBottom, PicTop]);
xlim([time(PicStart), time(PicEnd)]);
title(['Ic=',num2str(fix(Ictop)),'A Vge-dg-off']);
grid on;

% 路径构建优化
save_dir = fullfile(path, 'result', dataname, '07 Vge_dg');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
saveas(gcf, fullfile(save_dir, [ num, ' Ic=',num2str(fix(Ictop)),'A Vge_dg_off_T',num2str(gd_num),'.png']), 'png');
close(gcf);
hold off
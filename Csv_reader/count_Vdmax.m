function [Vdmax] = count_Vdmax(num,time,ch4,Ictop,path,dataname,ton2,toff2)

%% ================ Vdmax计算 ================
cnton2 = toff2 - ton2;
[Vdmax, dmax_idx] = max(ch4(ton2 - cnton2:toff2));
dmax_idx = ton2 - cnton2 + dmax_idx - 1;

% 绘图

PicStart = fix(dmax_idx - cnton2/4);
PicEnd = fix(dmax_idx + cnton2/2);
PicLength = PicEnd - PicStart;
PicTop = fix(1.2*Vdmax);
PicBottom = fix(-0.1*PicTop);
PicHeight = PicTop - PicBottom;

plot(time(PicStart:PicEnd), ch4(PicStart:PicEnd), 'b');
hold on;
plot(time(dmax_idx), Vdmax, 'ro', 'MarkerFaceColor','r');
text(time(fix(dmax_idx+0.05*PicLength)), Vdmax + 0.05*PicHeight,['Vdmax=',num2str(Vdmax),'V'], 'FontSize',13);
ylim([PicBottom, PicTop]);
xlim([time(PicStart), time(PicEnd)]);
title(['Ic=',num2str(fix(Ictop)),' A Vdmax']);
grid on;

save_dir = fullfile(path, 'result', dataname, '03 Vdmax');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
saveas(gcf, fullfile(save_dir, [ num,' Ic=',num2str(fix(Ictop)),'A Vdmax.png']), 'png');
close(gcf);
hold off
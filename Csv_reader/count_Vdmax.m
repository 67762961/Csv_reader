function [Vdmax] = count_Vdmax(num,time,ch4,Ictop,path,dataname,ton2,toff2)

%% ================ Vdmax计算 ================
[Vdmax, dmax_idx] = max(ch4(ton2:toff2));
dmax_idx = ton2 + dmax_idx - 1;

% 绘图
% figure;
plot(time(ton2:toff2), ch4(ton2:toff2), 'b');
hold on;
plot(time(dmax_idx), Vdmax, 'ro', 'MarkerFaceColor','r');
text(time(dmax_idx)+0.02*range(time(ton2:toff2)), Vdmax-0.1*range(ch4), ...
    ['Vdmax=',num2str(Vdmax),'V'], 'FontSize',13);
title(['Ic=',num2str(fix(Ictop)),' A Vdmax']);
grid on;

save_dir = fullfile(path, 'pic', dataname, '03 Vdmax');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
saveas(gcf, fullfile(save_dir, [ num,' Ic=',num2str(fix(Ictop)),'A Vdmax.png']), 'png');
close(gcf);
hold off
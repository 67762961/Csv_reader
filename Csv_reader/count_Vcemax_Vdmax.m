function [Vcemax,Vdmax] = count_Vcemax_Vdmax(num,time,ch2,ch4,Ictop,path,dataname,toff90,cntoff1,ton2,toff2)

%% Vcemax Vdmax 计算
% ================ Vcemax计算 ================
% 找出最大值
[Vcemax, cemax_idx] = max(ch2(toff90:fix(toff90+cntoff1)));
cemax_idx = toff90 + cemax_idx - 1;  % 转换为全局索引

% 绘图
% figure;
plot(time(toff90:ton2), ch2(toff90:ton2), 'b');
hold on;
plot(time(cemax_idx), Vcemax, 'ro', 'MarkerFaceColor','r');
text(time(cemax_idx)+0.02*range(time(toff90:ton2)), Vcemax-0.1*range(ch2), ...
    ['Vcemax=',num2str(Vcemax),'V'], 'FontSize',13);
title(['Ic=',num2str(fix(Ictop)),'A Vcemax']);
grid on;

% 路径构建优化
save_dir = fullfile(path, 'pic', dataname, 'Vce');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
saveas(gcf, fullfile(save_dir, [ num, ' Ic=',num2str(fix(Ictop)),'A Vcemax.png']), 'png');
close(gcf);
hold off

% ================ Vdmax计算 ================
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

save_dir = fullfile(path, 'pic', dataname, 'Vd');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
saveas(gcf, fullfile(save_dir, [ num,' Ic=',num2str(fix(Ictop)),'A Vdmax.png']), 'png');
close(gcf);
hold off
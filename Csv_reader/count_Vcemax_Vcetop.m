function [Vcemax,Vcetop,Vdmax] = count_Vcemax_Vcetop(num,DPI,time,ch2,Vd_flag,ch4,Ictop,path,dataname,cntVge)

cntsw = length(cntVge);
ton1=cntVge(cntsw-3);
toff1=cntVge(cntsw-2);
ton2=cntVge(cntsw-1);
toff2=cntVge(cntsw);
cntoff1 = ton2-toff1;
cnton2 = toff2 - ton2;

%% Vcetop Ictop 计算
% 计算Vcetop
start_idx = fix(toff1 + cntoff1/4);         % 起始索引：关断后1/20周期
end_idx = fix(ton2 - cntoff1/4);          % 结束索引：下一次导通前1/20周期
Vcetop = mean(ch2(start_idx:end_idx));       % 使用均值

%% Vcemax计算
% 找出最大值
[Vcemax, cemax_idx] = max(ch2(toff1 - cnton2:fix(ton2)));
cemax_idx = toff1 - cnton2 + cemax_idx - 1;  % 转换为全局索引


%% ================ Vdmax计算 ================
if 0 ~= Vd_flag
    [Vdmax, dmax_idx] = max(ch4(ton2 - cnton2:toff2));
    dmax_idx = ton2 - cnton2 + dmax_idx - 1;
else
    Vdmax = "   ";
end

% 绘图
PicLength = toff2 - ton1;
PicStart = max(ton1-fix(1*PicLength/5),1);
PicEnd = min(toff2+fix(1*PicLength/5),length(time));
PicLength = abs(toff2 - ton1);
PicTop = fix(1.1*max(ch2(PicStart:PicEnd)));
PicBottom = -fix(0.1*PicTop);
PicHeight = PicTop - PicBottom;

close all;
figure('Position', [320, 240, 1600/DPI/DPI, 600/DPI/DPI]);
% Vcetop校准线及标注
barStart = start_idx;
barEnd = end_idx;
barheight = 0.02*PicHeight;
line([time(barStart),time(barEnd)],[Vcetop,Vcetop],'Color', [0.5 0.5 0.5],'LineStyle','--');
hold on;
line([time(barStart),time(barStart)],[Vcetop-barheight, Vcetop+barheight], 'Color', [0.5 0.5 0.5]);
line([time(barEnd),time(barEnd)],[Vcetop-barheight, Vcetop+barheight], 'Color', [0.5 0.5 0.5]);
text(time(PicStart+fix(PicLength*2/5)),Vcetop - fix(PicHeight*0.1),['Vcetop =',num2str(Vcetop),'V'], 'FontSize',13,'Color','b');

% Vcemax绘图
plot(time(PicStart:PicEnd), ch2(PicStart:PicEnd), 'b');
if 0 ~= Vd_flag
    plot(time(PicStart:PicEnd), ch4(PicStart:PicEnd), 'g');
    plot(time(dmax_idx), Vdmax, 'ro', 'MarkerFaceColor','r');
    text(time(fix(dmax_idx-0.1*PicLength)), Vdmax + 0.05*PicHeight,['Vdmax=',num2str(Vdmax),'V'], 'FontSize',13,'Color','g');
end
plot(time(cemax_idx), Vcemax, 'ro', 'MarkerFaceColor','r');
text(time(fix(cemax_idx-0.3*PicLength)), Vcemax + 0.05*PicHeight, ['Vcemax=',num2str(Vcemax),'V'], 'FontSize',13,'Color','b');
ylim([PicBottom, PicTop]);
xlim([time(PicStart), time(PicEnd)]);
title(['Ic=',num2str(fix(Ictop)),'A Vcemax']);
grid on;

% 路径构建优化
save_dir = fullfile(path, 'result', dataname, '02 Vcemax & Vcetop');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
saveas(gcf, fullfile(save_dir, [ num, ' Ic=',num2str(fix(Ictop)),'A Vcemax.png']), 'png');
close(gcf);
hold off


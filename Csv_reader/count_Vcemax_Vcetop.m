function [Vcemax,Vcetop,Vdmax,T_Vcemax,T_Vdmax] = count_Vcemax_Vcetop(num,DPI,time,ch2,Vd_flag,ch4,Ictop,path,dataname,cntVge,Wave_count)

switch Wave_count(1)
    case 1
        Posedge = cntVge(1):cntVge(2);
    case 2
        Posedge = cntVge(3):cntVge(4);
    case 3
        Posedge = cntVge(5):cntVge(6);
end

switch Wave_count(2)
    case 1
        Negedge = cntVge(2):cntVge(3);
    case 2
        Negedge = cntVge(4):cntVge(5);
    case 3
        Negedge = cntVge(6):length(time);
end

%% Vcetop Ictop 计算
% 计算Vcetop
start_idx = fix(Negedge(1) + length(Negedge)/4);         % 起始索引：关断后1/20周期
end_idx = fix(Negedge(end) - length(Negedge)/4);          % 结束索引：下一次导通前1/20周期
Vcetop = median(ch2(start_idx:end_idx));       % 使用均值

%% Vcemax计算
% 找出最大值
[Vcemax, cemax_idx] = max(ch2(Negedge));
cemax_idx = Negedge(1) + cemax_idx - 1;  % 转换为全局索引
T_Vcemax = time(cemax_idx);

%% ================ Vdmax计算 ================
if 0 ~= Vd_flag
    [Vdmax, dmax_idx] = max(ch4(Posedge));
    dmax_idx = Posedge(1) + dmax_idx - 1;
    T_Vdmax = time(dmax_idx);
else
    Vdmax = "   ";
    T_Vdmax = "   ";
end

% 绘图
PicLength = cntVge(end) - cntVge(1);
PicStart = max(cntVge(1)-fix(1*PicLength/5),1);
PicEnd = min(cntVge(end)+fix(1*PicLength/5),length(time));
% PicLength = abs(PicEnd - PicStart);
PicTop = fix(1.1*max(ch2(PicStart:PicEnd)));
PicBottom = -fix(0.1*PicTop);
PicHeight = PicTop - PicBottom;

close all;
figure('Position', [320, 240, 1600/DPI, 600/DPI]);
% Vcetop校准线及标注
barStart = start_idx;
barEnd = end_idx;
barheight = 0.02*PicHeight;
line([time(barStart),time(barEnd)],[Vcetop,Vcetop],'Color', [0.5 0.5 0.5],'LineStyle','--');
hold on;
line([time(barStart),time(barStart)],[Vcetop-barheight, Vcetop+barheight], 'Color', [0.5 0.5 0.5]);
line([time(barEnd),time(barEnd)],[Vcetop-barheight, Vcetop+barheight], 'Color', [0.5 0.5 0.5]);
text(time(barStart),Vcetop - fix(PicHeight*0.1),['Vcetop =',num2str(Vcetop),'V'], 'FontSize',13,'Color','b');

% Vcemax绘图
plot(time(PicStart:PicEnd), ch2(PicStart:PicEnd), 'b');
if 0 ~= Vd_flag
    plot(time(PicStart:PicEnd), ch4(PicStart:PicEnd), 'g');
    plot(time(dmax_idx), Vdmax, 'ro', 'MarkerFaceColor','r');
    text(time(fix(dmax_idx)), Vdmax + 0.05*PicHeight,['Vdmax=',num2str(Vdmax),'V'], 'FontSize',13,'Color','g');
end
plot(time(cemax_idx), Vcemax, 'ro', 'MarkerFaceColor','r');
text(time(fix(cemax_idx)), Vcemax + 0.15*PicHeight, ['Vcemax=',num2str(Vcemax),'V'], 'FontSize',13,'Color','b');
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


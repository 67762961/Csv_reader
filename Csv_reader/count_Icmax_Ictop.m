function [Ictop_out,Icmax] = count_Icmax_Ictop(num,DPI,time,ch3,Id_flag,ch5,path,dataname,I_meature,cntVge)

cntsw = length(cntVge);
ton1=cntVge(cntsw-3);
toff1=cntVge(cntsw-2);
ton2=cntVge(cntsw-1);
toff2=cntVge(cntsw);
cnton1 = toff1-ton1;

%% 计算Ictop
nspd = (time(2)-time(1))*1e9;
cntoff1 = ton2-toff1;

% 传统计算法Ictop
current_interval = ton1 + fix(cnton1/2) : toff1;    % 定义电流峰值搜索区间
[~, max_idx] = max(ch3(current_interval));          % 快速定位峰值索引 max_idx为相对索引
tIcm = ton1 + fix(cnton1/2) + max_idx - 1;          % 转换为全局索引
window_start = max(1, tIcm - fix(30/nspd));        % 窗口起始：峰值前10点（最小为1）
Ictop = mean(ch3(window_start:tIcm));               % 计算均值

% plot(time(current_interval), ch3(current_interval), 'b');
% hold on;
% plot(time(tIcm), ch3(tIcm), 'ro', 'MarkerFaceColor','r');
% error('1')

PicLength = abs(toff2 - ton1);
PicStart = max(ton1-fix(1*PicLength/5),1);
PicEnd = min(toff2+fix(1*PicLength/5),length(time));
PicLength = abs(PicEnd - PicStart);
PicTop = fix(1.1*max(ch3(PicStart:PicEnd)));
PicBottom = min(fix(1.5*min(ch5(PicStart:PicEnd))),-0.1*PicTop);
PicHeight = PicTop - PicBottom;

barheight = 0.02*PicHeight;
barStart =fix(toff1 + cntoff1/4);
barEnd = fix(ton2 - cntoff1/4);

close all;
figure('Position', [560, 240, 800/DPI/DPI, 600/DPI/DPI]);
% 若有Id输入 则以静态区Id值作为Ictop
if Id_flag~=0
    static_id_interval = fix(toff1 + cntoff1/4) : fix(ton2 - cntoff1/4);
    Idbase =  mean(ch5(static_id_interval)); % 关断时平均Id作为Ictop
    
    % Idbase水平线及标注
    line([time(barStart),time(barEnd)],[Idbase,Idbase],'Color', [0.5 0.5 0.5],'LineStyle','--');
    hold on;
    line([time(barStart),time(barStart)],[Idbase-barheight, Idbase+barheight], 'Color', [0.5 0.5 0.5]);
    line([time(barEnd),time(barEnd)],[Idbase-barheight, Idbase+barheight], 'Color', [0.5 0.5 0.5]);
    text(time(fix(toff1)),Idbase - fix(PicHeight*0.05),['Idbase =',num2str(Idbase),'A'], 'FontSize',13,'Color','b');
    
    % Id校准线及标注
    barStart = fix(ton1 + cnton1/2);
    barEnd = fix(toff1 - cnton1/4);
    line([time(barStart),time(barEnd)],[0,0],'Color', [0.5 0.5 0.5],'LineStyle','--');
    line([time(barStart),time(barStart)],[0-barheight, 0+barheight], 'Color', [0.5 0.5 0.5]);
    line([time(barEnd),time(barEnd)],[0-barheight, 0+barheight], 'Color', [0.5 0.5 0.5]);
    
    plot(time(PicStart:PicEnd), ch5(PicStart:PicEnd), 'Color','b');
end
% Ic校准线及标注
barStart = fix(toff1 + cntoff1/4);
barEnd = fix(ton2 - cntoff1/4);
line([time(barStart),time(barEnd)],[0,0],'Color', [0.5 0.5 0.5],'LineStyle','--');
line([time(barStart),time(barStart)],[0-barheight, 0+barheight], 'Color', [0.5 0.5 0.5]);
line([time(barEnd),time(barEnd)],[0-barheight, 0+barheight], 'Color', [0.5 0.5 0.5]);
% Ic绘图
plot(time(PicStart:PicEnd), ch3(PicStart:PicEnd), 'Color','r');
hold on;
plot(time(tIcm), Ictop, 'ro', 'MarkerFaceColor','r');
text(time(tIcm),Ictop + fix(PicHeight*0.05),['Ictop =',num2str(Ictop),'A'], 'FontSize',13,'Color','r');

%% Icmax 计算
[Icmax, Icmax_idx] = max(ch3(ton2:toff2));
Icmax_idx = ton2 + Icmax_idx - 1;

%% 电流采信选择
if Id_flag==0
    I_meature = "Ic";
end
switch I_meature
    case "Ic"
        Ictop_out = Ictop;
    case "Id"
        Ictop_out = -1*Idbase;
    otherwise
        error('I_meature参数错误 请检查');
end

% 绘图
plot(time(Icmax_idx), Icmax, 'ro', 'MarkerFaceColor','r');
text(time(Icmax_idx+fix(PicLength*0.05)),Icmax,['Icmax=',num2str(Icmax),'A'], 'FontSize',13,'Color','r');
ylim([PicBottom, PicTop]);
xlim([time(PicStart), time(PicEnd)]);
title(['Ic=',num2str(fix(Ictop_out)),' A Icmax']);
grid on;

save_dir = fullfile(path, 'result', dataname, '01 Icmax & Ictop');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
saveas(gcf, fullfile(save_dir, [ num,' Ic=',num2str(fix(Ictop_out)),'A Icmax.png']), 'png');
close(gcf);
hold off
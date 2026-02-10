function [Ictop_out,Icmax,I_Fuizai_on,I_Fuizai_off] = count_Icmax_Ictop(num,DPI,time,Ch_labels,Fuzaimode,ch3,ch5,I_fuzai,path,dataname,I_meature,cntVge)

cntsw = length(cntVge);
ton1=cntVge(cntsw-3);
toff1=cntVge(cntsw-2);
ton2=cntVge(cntsw-1);
toff2=cntVge(cntsw);
cnton1 = toff1-ton1;
cntoff1 = ton2-toff1;

Id_flag = Ch_labels(5);

%% 计算Ictop
nspd = (time(2)-time(1))*1e9;

% 传统计算法Ictop
current_interval = toff1 : ton2;    % 定义电流峰值搜索区间
[~, max_idx] = max(ch3(current_interval));          % 快速定位峰值索引 max_idx为相对索引
tIcm = toff1 + max_idx - 1;          % 转换为全局索引
window_start = max(1, tIcm - fix(30/nspd));        % 窗口起始：峰值前30ns（最小为1）
Ictop = mean(ch3(window_start:tIcm));               % 计算均值

% plot(time(current_interval), ch3(current_interval), 'b');
% hold on;
% plot(time(tIcm), ch3(tIcm), 'ro', 'MarkerFaceColor','r');
% error('1')

PicLength = abs(toff2 - ton1);
PicStart = max(ton1-fix(1*PicLength/5),1);
PicEnd = min(toff2+fix(1*PicLength/5),length(time));
PicLength = abs(PicEnd - PicStart);
Max = max(max(ch3(PicStart:PicEnd)),max(ch5(PicStart:PicEnd)));
PicTop = fix(1.1*Max);
Min = min(min(ch3(PicStart:PicEnd)),min(ch5(PicStart:PicEnd)));
PicBottom = fix(min(1.3*Min,-0.1*PicTop));
PicHeight = PicTop - PicBottom;

barheight = 0.02*PicHeight;
barStart =fix(toff1 + cntoff1/4);
barEnd = fix(ton2 - cntoff1/4);

close all;
figure('Position', [320, 240, 1600/DPI/DPI, 600/DPI/DPI]);

% 若有Id输入 则以静态区Id值作为Ictop
if Id_flag~=0
    static_id_interval = fix(toff1 + cntoff1/4) : fix(ton2 - cntoff1/4);
    Idbase =  mean(ch5(static_id_interval)); % 关断时平均Id作为Ictop
    
    % Idbase水平线及标注
    line([time(barStart),time(barEnd)],[Idbase,Idbase],'Color', [0.5 0.5 0.5],'LineStyle','--');
    hold on;
    line([time(barStart),time(barStart)],[Idbase-barheight, Idbase+barheight], 'Color', [0.5 0.5 0.5]);
    line([time(barEnd),time(barEnd)],[Idbase-barheight, Idbase+barheight], 'Color', [0.5 0.5 0.5]);
    text(time(barStart),Idbase - fix(PicHeight*0.05),['Idbase =',num2str(Idbase),'A'], 'FontSize',13,'Color','b');
    
    % Id校准线及标注
    barStart = fix(ton1 + cnton1/2);
    barEnd = fix(toff1 - cnton1/4);
    line([time(barStart),time(barEnd)],[0,0],'Color', [0.5 0.5 0.5],'LineStyle','--');
    line([time(barStart),time(barStart)],[0-barheight, 0+barheight], 'Color', [0.5 0.5 0.5]);
    line([time(barEnd),time(barEnd)],[0-barheight, 0+barheight], 'Color', [0.5 0.5 0.5]);
    
    plot(time(PicStart:PicEnd), ch5(PicStart:PicEnd), 'Color','b');
end

% 若有I_Fuzai输入 则以静态区I_Fuzai值作为
if Fuzaimode~=0
    static_Fuzai_interval = fix(toff1 + cntoff1/4) : fix(ton2 - cntoff1/4);
    FuzaiTop =  mean(I_fuzai(static_Fuzai_interval)); % 关断时平均Ifuzai作为Ictop
    
    % FuzaiTop水平线及标注
    barStart =fix(toff1 + cntoff1/4);
    barEnd = fix(ton2 - cntoff1/4);
    line([time(barStart),time(barEnd)],[FuzaiTop,FuzaiTop],'Color', [0.5 0.5 0.5],'LineStyle','--');
    line([time(barStart),time(barStart)],[FuzaiTop-barheight, FuzaiTop+barheight], 'Color', [0.5 0.5 0.5]);
    line([time(barEnd),time(barEnd)],[FuzaiTop-barheight, FuzaiTop+barheight], 'Color', [0.5 0.5 0.5]);
    text(time(barStart),FuzaiTop - fix(PicHeight*0.05),['FuzaiTop =',num2str(FuzaiTop),'A'], 'FontSize',13,'Color','g');
    
    line([time(barStart),time(barEnd)],[FuzaiTop,FuzaiTop],'Color', [0.5 0.5 0.5],'LineStyle','--');
    hold on;
    line([time(barStart),time(barStart)],[FuzaiTop-barheight, FuzaiTop+barheight], 'Color', [0.5 0.5 0.5]);
    line([time(barEnd),time(barEnd)],[FuzaiTop-barheight, FuzaiTop+barheight], 'Color', [0.5 0.5 0.5]);
    
    
    plot(time(PicStart:PicEnd), I_fuzai(PicStart:PicEnd), 'Color','g');
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

if Ch_labels(3) ==0
    Ictop = FuzaiTop;
end

if Fuzaimode ~= 0
    I_Fuizai_on  = mean(I_fuzai(ton2-fix(30/nspd):ton2+fix(30/nspd)));
    I_Fuizai_off = mean(I_fuzai(toff1-fix(30/nspd):toff1+fix(30/nspd)));
    plot(time(ton2), I_Fuizai_on, 'go');
    text(time(ton2),I_Fuizai_on - fix(PicHeight*0.1),['I_on =',num2str(I_Fuizai_on),'A'], 'FontSize',10,'Color','g');
    plot(time(toff1), I_Fuizai_off, 'go');
    text(time(toff1),I_Fuizai_off - fix(PicHeight*0.1),['I_off =',num2str(I_Fuizai_off),'A'], 'FontSize',10,'Color','g');
else
    I_Fuizai_on = Ictop;
    I_Fuizai_off = Ictop;
end

switch I_meature
    case "Ic"
        Ictop_out = Ictop;
    case "Id"
        Ictop_out = -1*Idbase;
    case "I_fuzai"
        Ictop_out = FuzaiTop;
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
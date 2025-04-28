function draw(data1,dataname,path,Dflag,Vmax)
% 整组数据对比图像绘制函数
%   本函数用于生成IGBT双脉冲测试的多维度特性曲线，包含开关损耗、电压应力、
%   电流变化率等核心指标的可视化分析
%
%   Inputs:
%       data1    : N×10 矩阵 (double)
%           测试数据矩阵，各列含义如下：
%           第1列 - IGBT电流 Ic (单位：A)
%           第2列 - 开通损耗 Eon (单位：mJ)
%           第3列 - 关断损耗 Eoff (单位：mJ)
%           第4列 - 集射极峰值电压 Vcemax (单位：V)
%           第5列 - 二极管峰值电压 Vdmax (单位：V)
%           第6列 - 电压变化率 dv/dt (单位：V/μs)
%           第7列 - 电流变化率 di/dt (单位：A/μs)
%           第8列 - 集射极平台电压 Vcetop (单位：V)
%           第9列 - 反向恢复能量 Erec (单位：mJ)
%           第10列 - 最大反向恢复功率 Prrmax (单位：kW)
%       dataname : 字符串 (char)
%           测试案例名称，用于图表标题和文件命名
%       path     : 字符串 (char)
%           结果保存路径，需包含完整目录结构
%       Vmax     : 标量 (double)
%           电压安全阈值，用于绘制参考警戒线(单位：V)
%
%   Outputs:
%       无直接返回值，生成以下图像文件：
%       - Ic-Eigbt.png : 开关损耗特性曲线
%       - Ic-Vcemax.png: 集射极电压峰值分析
%       - Ic-Vdmax.png : 二极管电压峰值分析
%       - Ic-Delta_Vce.png: 集射极电压差分析 
%       - Ic-didt.png  : 电流变化率特性
%       - Ic-dvdt.png  : 电压变化率特性
%       - Ic-Erec.png  : 反向恢复能量特性
%       - Ic-Prrmax.png: 反向恢复功率峰值

data1(data1==0)=NaN;
% 参数表传递
Ic=data1(:,1);
Eon=data1(:,2);
Eoff=data1(:,3);
Vcemax=data1(:,4);
Vdmax=data1(:,5);
dvdt=data1(:,6);
didt=data1(:,7);
Vcetop=data1(:,8);
Erec=data1(:,9);
Prrmax=data1(:,10);

% 横坐标范围计算
maxIc = max(Ic);
if maxIc >= 100 && maxIc <= 140
    plotend = 120;
else
    plotend = 800;
end


% 绘制IGBT开关损耗
plot(Ic,Eon,'color','#A2142F','LineWidth',2);
hold on;
plot(Ic,Eoff,'color','#0072BD','LineWidth',2);
xlabel('Ic(A)');
ylabel('Eon/Eoff(mJ)');
legend('Eon','Eoff','location','northwest');
legend('boxoff')
xlim([0,plotend])
set(gca,'FontSize',12)
title(strcat(dataname,' E-IGBT'),'FontSize',14);
grid on
saveas(gcf,[[path,'.\pic\',dataname,'\Draw\'],['Ic','-Eigbt'],'.png'])
close(gcf);
hold off

%% 绘制Vcemax
plot(Ic,Vcemax,'color','#0072BD','LineWidth',2);
hold on
plot([0,plotend],[Vmax,Vmax],'color','red','LineWidth',2);
xlabel('Ic(A)');
ylabel('Vcemax(V)');
legend('Vcemax',[num2str(Vmax),'V'],'location','southwest');
legend('boxoff')
xlim([0,plotend])
ylim([0,Vmax+100]);
set(gca,'FontSize',12)
title(strcat(dataname,' Vcemax'),'FontSize',14);
grid on
saveas(gcf,[[path,'.\pic\',dataname,'\Draw\'],['Ic','-Vcemax'],'.png'])
close(gcf);
hold off

%% 绘制Vdmax
plot(Ic,Vdmax,'color','#0072BD','LineWidth',2);
hold on
plot([0,plotend],[Vmax,Vmax],'color','red','LineWidth',2);
xlabel('Ic(A)');
ylabel('Vdmax(V)');
legend('Vdmax',[num2str(Vmax),'V'],'location','southwest');
legend('boxoff')
xlim([0,plotend])
ylim([0,Vmax+100]);
set(gca,'FontSize',12)
title(strcat(dataname,' Vdmax'),'FontSize',14);
grid on
saveas(gcf,[[path,'.\pic\',dataname,'\Draw\'],['Ic','-Vdmax'],'.png'])
close(gcf);
hold off

%% 绘制Delta-Vce
plot(Ic,Vcemax-Vcetop,'color','#0072BD','LineWidth',2);
hold on
xlabel('Ic(A)');
ylabel('Delta-Vce(V)');
legend('Delta-Vce','location','southwest');
legend('boxoff')
set(gca,'FontSize',12)
title(strcat(dataname,' Delta-Vce'),'FontSize',14);
grid on
saveas(gcf,[[path,'.\pic\',dataname,'\Draw\'],['Ic','-Delta_Vce'],'.png'])
close(gcf);
hold off

%% 绘制di/dt
plot(Ic,didt,'color','#0072BD','LineWidth',2);
hold on
xlabel('Ic(A)');
ylabel('di/dt(A/us)');
legend('di/dt','location','southwest');
legend('boxoff')
xlim([0,plotend])
ylim([0,max(didt)+500]);
set(gca,'FontSize',12)
title(strcat(dataname,' di/dt'),'FontSize',14);
grid on
saveas(gcf,[[path,'.\pic\',dataname,'\Draw\'],['Ic','-didt'],'.png'])
close(gcf);
hold off

%% 绘制dv/dt
plot(Ic,dvdt,'color','#0072BD','LineWidth',2);
hold on
xlabel('Ic(A)');
ylabel('dv/dt(V/us)');
legend('dv/dt','location','southwest');
legend('boxoff')
xlim([0,plotend])
ylim([0,max(dvdt)+500]);
set(gca,'FontSize',12)
title(strcat(dataname,' dv/dt'),'FontSize',14);
grid on
saveas(gcf,[[path,'.\pic\',dataname,'\Draw\'],['Ic','-dvdt'],'.png'])
close(gcf);



%%二极管反向回复数据绘图
if Dflag
    % 绘制Erec
    plot(Ic,Erec,'color','#0072BD','LineWidth',2);
    hold on
    xlabel('Ic(A)');
    ylabel('Erec(mJ)');
    legend('Erec','location','southwest');
    legend('boxoff')
    ylim([0,abs(max(Erec)*1.2)]);
    set(gca,'FontSize',12)
    title(strcat(dataname,' Erec'),'FontSize',14);
    grid on
    saveas(gcf,[[path,'.\pic\',dataname,'\Draw\'],['Ic','-Erec'],'.png'])
    close(gcf);

    % 绘制Prrmax
    plot(Ic,Prrmax,'color','#0072BD','LineWidth',2);
    hold on
    xlabel('Ic(A)');
    ylabel('Prrmax(kW)');
    legend('Prrmax','location','southwest');
    legend('boxoff')
    xlim([0,plotend])
    ylim([0,max(Prrmax)*1.2]);
    set(gca,'FontSize',12)
    title(strcat(dataname,' Prrmax'),'FontSize',14);
    grid on
    saveas(gcf,[[path,'.\pic\',dataname,'\Draw\'],['Ic','-Prrmax'],'.png'])
    close(gcf);

end
end


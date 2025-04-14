function output = draw1(data1,dataname,path,Vmax)
data1(data1==0)=NaN;
Vcetop=data1(:,1);
Ic=data1(:,2);
Eon=data1(:,3);
Eoff=data1(:,4);
Vcemax=data1(:,5);
Vdmax=data1(:,6);
dvdt=data1(:,7);
didt=data1(:,8);
Erec=data1(:,15);
Prrmax=data1(:,16);
% 绘制IGBT开关损耗
plot(Ic,Eon,'color','#A2142F','LineWidth',2);
hold on
plot(Ic,Eoff,'color','#0072BD','LineWidth',2);
hold on
xlabel('Ic(A)');
ylabel('Eon/Eoff(mJ)');
legend('Eon','Eoff','location','northwest');
legend('boxoff')
set(gca,'FontSize',12)
title(strcat(dataname,' E-IGBT'),'FontSize',14);
grid on
saveas(gcf,[[path,'.\pic\',dataname,'\Draw\'],['Ic','-Eigbt'],'.png'])
close(gcf);
hold off

%% 绘制Vcemax
plot(Ic,Vcemax,'color','#0072BD','LineWidth',2);
hold on
plot([0,1200],[Vmax,Vmax],'color','red','LineWidth',2);
hold on
xlabel('Ic(A)');
ylabel('Vcemax(V)');
legend('Vcemax',[num2str(Vmax),'V'],'location','southwest');
legend('boxoff')
xlim([0,max(Ic)+50]);
ylim([0,Vmax+100]);
hold on
set(gca,'FontSize',12)
title(strcat(dataname,' Vcemax'),'FontSize',14);
grid on
saveas(gcf,[[path,'.\pic\',dataname,'\Draw\'],['Ic','-Vcemax'],'.png'])
close(gcf);
hold off
%% 绘制Vdmax
plot(Ic,Vdmax,'color','#0072BD','LineWidth',2);
hold on
plot([0,1200],[Vmax,Vmax],'color','red','LineWidth',2);
hold on
xlabel('Ic(A)');
ylabel('Vdmax(V)');
legend('Vdmax',[num2str(Vmax),'V'],'location','southwest');
legend('boxoff')
xlim([0,max(Ic)+50]);
ylim([0,Vmax+100]);
hold on
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
xlim([0,max(Ic)+50]);
ylim([0,500]);
hold on
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
xlim([0,max(Ic)+50]);
ylim([0,max(didt)+500]);
hold on
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
xlim([0,max(Ic)+50]);
ylim([0,max(dvdt)+500]);
hold on
set(gca,'FontSize',12)
title(strcat(dataname,' dv/dt'),'FontSize',14);
grid on
saveas(gcf,[[path,'.\pic\',dataname,'\Draw\'],['Ic','-dvdt'],'.png'])
close(gcf);
%% 绘制Erec
% plot(Ic,Erec,'color','#0072BD','LineWidth',2);
% hold on
% xlabel('Ic(A)');
% ylabel('Erec(mJ)');
% legend('Erec','location','southwest');
% legend('boxoff')
% xlim([0,max(Ic)+50]);
% ylim([0,max(Erec)*1.2]);
% hold on
% set(gca,'FontSize',12)
% title(strcat(dataname,' Erec'),'FontSize',14);
% grid on
% saveas(gcf,[[path,'.\pic\',dataname,'\Draw\'],['Ic','-Erec'],'.png'])
% close(gcf);
%% 绘制Prrmax
% plot(Ic,Prrmax,'color','#0072BD','LineWidth',2);
% hold on
% xlabel('Ic(A)');
% ylabel('Prrmax(kW)');
% legend('Prrmax','location','southwest');
% legend('boxoff')
% xlim([0,max(Ic)+50]);
% ylim([0,max(Prrmax)*1.2]);
% hold on
% set(gca,'FontSize',12)
% title(strcat(dataname,' Prrmax'),'FontSize',14);
% grid on
% saveas(gcf,[[path,'.\pic\',dataname,'\Draw\'],['Ic','-Prrmax'],'.png'])
% close(gcf);
end


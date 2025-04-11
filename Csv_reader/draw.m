function draw(data1,dataname,path,Vmax)
data1(data1==0)=NaN;

% ��ȡ������
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

%% ����IGBT�������
plot(Ic,Eon,'color','#A2142F','LineWidth',2);
hold on;
plot(Ic,Eoff,'color','#0072BD','LineWidth',2);
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

%% ����Vcemax
plot(Ic,Vcemax,'color','#0072BD','LineWidth',2);
hold on
plot([0,fix(max(Ic)/50+0.5)*50],[Vmax,Vmax],'color','red','LineWidth',2);
xlabel('Ic(A)');
ylabel('Vcemax(V)');
legend('Vcemax',[num2str(Vmax),'V'],'location','southwest');
legend('boxoff')
ylim([0,Vmax+100]);
set(gca,'FontSize',12)
title(strcat(dataname,' Vcemax'),'FontSize',14);
grid on
saveas(gcf,[[path,'.\pic\',dataname,'\Draw\'],['Ic','-Vcemax'],'.png'])
close(gcf);
hold off

%% ����Vdmax
plot(Ic,Vdmax,'color','#0072BD','LineWidth',2);
hold on
plot([0,fix(max(Ic)/50+0.5)*50],[Vmax,Vmax],'color','red','LineWidth',2);
xlabel('Ic(A)');
ylabel('Vdmax(V)');
legend('Vdmax',[num2str(Vmax),'V'],'location','southwest');
legend('boxoff')
ylim([0,Vmax+100]);
set(gca,'FontSize',12)
title(strcat(dataname,' Vdmax'),'FontSize',14);
grid on
saveas(gcf,[[path,'.\pic\',dataname,'\Draw\'],['Ic','-Vdmax'],'.png'])
close(gcf);
hold off

%% ����Delta-Vce
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

%% ����di/dt
plot(Ic,didt,'color','#0072BD','LineWidth',2);
hold on
xlabel('Ic(A)');
ylabel('di/dt(A/us)');
legend('di/dt','location','southwest');
legend('boxoff')
xlim([0,max(Ic)]);
ylim([0,max(didt)+500]);
set(gca,'FontSize',12)
title(strcat(dataname,' di/dt'),'FontSize',14);
grid on
saveas(gcf,[[path,'.\pic\',dataname,'\Draw\'],['Ic','-didt'],'.png'])
close(gcf);
hold off

%% ����dv/dt
plot(Ic,dvdt,'color','#0072BD','LineWidth',2);
hold on
xlabel('Ic(A)');
ylabel('dv/dt(V/us)');
legend('dv/dt','location','southwest');
legend('boxoff')
xlim([0,max(Ic)]);
ylim([0,max(dvdt)+500]);
set(gca,'FontSize',12)
title(strcat(dataname,' dv/dt'),'FontSize',14);
grid on
saveas(gcf,[[path,'.\pic\',dataname,'\Draw\'],['Ic','-dvdt'],'.png'])
close(gcf);

%% ����Erec
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

%% ����Prrmax
plot(Ic,Prrmax,'color','#0072BD','LineWidth',2);
hold on
xlabel('Ic(A)');
ylabel('Prrmax(kW)');
legend('Prrmax','location','southwest');
legend('boxoff')
ylim([0,max(Prrmax)*1.2]);
set(gca,'FontSize',12)
title(strcat(dataname,' Prrmax'),'FontSize',14);
grid on
saveas(gcf,[[path,'.\pic\',dataname,'\Draw\'],['Ic','-Prrmax'],'.png'])
close(gcf);
end


function output = countE1(locate,tablename,tablenum,Ic_c,Vce_c,path,dataname,Vgeth)

% %%%%%%%%%debug%%%%%%%%%
% dataname=0;
% filename='E:\20230704\Inv-A_080_ALL.csv';
% Ic_c=5;
% Vce_c=50;
% %%%%%%%%%%%%%%%%%%%%%%%%

if tablenum<10
    num=num2str(tablenum);
    filename=strcat(locate,'\',tablename,'_00',num,'_ALL.csv');
elseif tablenum>=10 && tablenum<=99
    num=num2str(tablenum);
    filename=strcat(locate,'\',tablename,'_0',num,'_ALL.csv');
else
    num=num2str(tablenum);
    filename=strcat(locate,'\',tablename,'_',num,'_ALL.csv');
end
data0 = csvread(filename,30,0);  %读取数据表格
if mean(data0(:,6)==0)
    data = data0;
else
data = findch(data0);
end
[m,n] = size(data);
time = data(:,1);
ch1 = data(:,2);
Vge = smoothdata(ch1,'movmedia',60);
ch2 = data(:,3);
Vce = smoothdata(data(:,3),'movmean',10);        %%%%%%%%%%%%
ch33 = data(:,4);
ch3 = data(:,4);
Ic = smoothdata(data(:,4),'movmean',30);        %%%%%%%%%%%%
ch4=data(:,5);
ch5=data(:,6);
Id=ch5;
Prr=Id.*ch4;
cntVge = indzer(Vge,Vgeth); %Vge过零点位置记录
cntsw = length(cntVge); %Vge过零点次数记录
ton1=cntVge(cntsw-3);  %第一次开通时间点
ton2=cntVge(cntsw-1);  %第二次开通时间点
toff1=cntVge(cntsw-2);  %第一次关断时间点
toff2=cntVge(cntsw);    %第二次关断时间点
cnton1=toff1-ton1; %计算第一次开通时长
cntoff1=ton2-toff1; %计算第一次关断时长
cnton2=toff2-ton2; %计算第二次开通时长
meanVgetop=mean(Vge(fix(ton1+cnton1/4):fix(toff1-cnton1/4))); %Vge高电平电压值读取
toff90=0;
ton10=0;
for i=toff1:-1:ton1  %寻找关断时Vge=90%的点
    if ch1(i)>0.9*meanVgetop
        toff90=i;
        break;
    end
end
for i=ton2:toff2 %寻找开通时Vge=10%的点
    if ch1(i)>0.1*meanVgetop
        ton10=i;
        break;
    end
end
meanIc=mean(Ic(fix(toff1+cntoff1/4):fix(ton2-cntoff1/4))); %计算Ic电流探头偏置
meanVce=mean(Vce(fix(ton1+cnton1/4):fix(toff1-cnton1/4)));  %计算Vce电压探头偏置
Vcetop=zeros(length(Ic),1); %定义数组并置零
Ictop=Vcetop; %定义数组并置零
Vcetop=mean(Vce(fix(toff1+cntoff1/5):fix(ton2-3*cntoff1/4)));%定义数组并置零
[~,cc]=sort(Ic(ton1+fix(cnton1/2):toff1),'descend'); %找开关电流值1
tIcm=ton1+fix(cnton1/2)+cc(1)-1;  %找开关电流值2
Ictop=mean(Ic(tIcm-10):Ic(tIcm)); %找开关电流值3
toffIcm90=0;
toffIcm10=0;
tonIcm10=0;
tonIcm90=0;
for i=tIcm:toff1+100     %找关断时电流值=90%时刻
    if Ic(i)<Ictop*0.9
        toffIcm90=i;
        break;
    end
end
for i=toffIcm90:ton2  %找关断时电流值=10%时刻
    if Ic(i)<Ictop*0.1
        toffIcm10=i;
        break;
    end
end
for i=ton2:toff2  %找开通时电流值=10%时刻
    if Ic(i)>Ictop*0.1
        tonIcm10=i;
        break;
    end
end
for i=tonIcm10:toff2  %找开通时电流值=90%时刻
    if Ic(i)>Ictop*0.9
        tonIcm90=i;
        break;
    end
end
% ch2=Ic-meanIc;
Ic=Ic-meanIc; %Ic电流探头较零
% ch3=Vce-meanVce;
Vce=Vce-meanVce;  %Vce电压探头较零


SWon_start=0;
SWon_stop=0;
SWoff_start=0;
SWoff_stop=0;
Erec_start=0;
Erec_stop=0;
%% （1）
for i=toff90:1:ton2  %关断起始时刻寻找
    if Vce(i)>=Vce_c
        SWoff_start=i;
        break;
    end
end
for i=SWoff_start:1:ton2  %关断结束时刻寻找
    if Ic(i)<=Ictop*0.02
        SWoff_stop=i;
        break;
    end
end
for i=fix(ton2-cntoff1/4):1:toff2  %开通起始时刻寻找
    if Ic(i)>=Ic_c
        SWon_start=i;
        break;
    end
end
for i=SWon_start:1:toff2  %开通结束时刻寻找
    if Vce(i)<=Vce_c
        SWon_stop=i;
        break;
    end
end
for i=ton2:toff2  %二极管反向恢复时间寻找
    if Id(i)>=0
        Erec_start=i;
        break;
    end
end
for i=Erec_start+10:toff2  %二极管反向恢复时间寻找
    if Id(i)<=0
        Erec_stop=i;
        break;
    end
end

% % Prr/Erec
% [~,trrmax]=sort(Prr(ton2:fix(ton2+cnton2/4)),'descend');
% t_Prrmax=ton2+trrmax(1)-1;
% Prrmax=Prr(t_Prrmax)/1000;
% Erec=0;
% for i=Erec_start:Erec_stop
%     Erec=Erec+Prr(i)*(time(i)-time(i-1))*1000;
% end
% plot(time(Erec_start-100:Erec_stop+100),Prr(Erec_start-100:Erec_stop+100)/Prrmax/1000,'c');
% hold on
% plot(time(Erec_start:Erec_stop),Prr(Erec_start:Erec_stop)/Prrmax/1000,'r');
% hold on
% plot(time(Erec_start-100:Erec_stop+100),Id(Erec_start-100:Erec_stop+100)./Ictop,'b');
% hold on
% plot(time(Erec_start-100:Erec_stop+100),ch4(Erec_start-100:Erec_stop+100)./Vcetop,'g');
% hold on
% plot(time(t_Prrmax),1,'o','color','red')
% text(time(t_Prrmax+30),0.8,['Prrmax=',num2str(Prrmax),'kW'],'FontSize',13);
% text(time(t_Prrmax+30),1,['Erec=',num2str(Erec),'mJ'],'FontSize',13);
% text(time(t_Prrmax),0.5,'Prr','color','red','FontSize',13);
% hold on
% grid on
% title(strcat('Ic=',num2str(fix(Ictop)),' Prr-Erec(归1化)'));
% saveas(gcf,[[path,'.\pic\',dataname,'\Prr\'],['Ic=',num2str(fix(Ictop)),'-Prr'],'.png'])
% close(gcf)
% hold off

%% （2）
Pon=zeros(length(Ic),1);
Poff=Pon;
Eon=0;
Eoff=0;
for i=SWon_start-20:SWon_stop+20
    Pon(i)=ch2(i)*ch3(i)*1000;
    Eon=Eon+Pon(i)*(time(i)-time(i-1));
end
Ponmax=max(Pon(SWon_start-20:SWon_stop+20));
plot(time(SWon_start-20:SWon_stop+20),Pon(SWon_start-20:SWon_stop+20)/Ponmax/2,'r');
hold on
plot(time(SWon_start-100:SWon_stop+100),ch2(SWon_start-100:SWon_stop+100)/Vcetop,'g');
hold on
plot(time(SWon_start-100:SWon_stop+100),ch3(SWon_start-100:SWon_stop+100)/Ictop,'b');
xlim([time(SWon_start-100),time(SWon_stop+100)]);
ylim([-0.2,1.3]);
text(time(SWon_start-80),1.1,['Eon=',num2str(Eon),'mJ'],'FontSize',13);
text(time(SWon_start),0.4,'Pon','color','red','FontSize',13);
text(time(SWon_start-50),0.9,'Vce','color','green','FontSize',13);
text(time(SWon_start+70),0.9,'Ic','color','blue','FontSize',13);
hold on
grid on;
title(strcat('Ic=',num2str(fix(Ictop)),' 开通损耗计算(归1化)'));
saveas(gcf,[[path,'.\pic\',dataname,'\Eigbt\'],['Ic=',num2str(fix(Ictop)),'-Eon'],'.png'])
close(gcf)
hold off

for i=SWoff_start-20:SWoff_stop
    Poff(i)=ch2(i)*ch3(i)*1000;
    Eoff=Eoff+Poff(i)*(time(i)-time(i-1));
end
Poffmax=max(Poff(SWoff_start-20:SWoff_stop));
plot(time(SWoff_start-20:SWoff_stop),Poff(SWoff_start-20:SWoff_stop)/Poffmax/2,'r');
hold on
plot(time(SWoff_start-100:SWoff_stop+100),ch2(SWoff_start-100:SWoff_stop+100)/Vcetop,'g');
hold on
plot(time(SWoff_start-100:SWoff_stop+100),ch3(SWoff_start-100:SWoff_stop+100)/Ictop,'b');
hold on
xlim([time(SWoff_start-100),time(SWoff_stop+100)]);
ylim([-0.2,1.3]);
text(time(SWoff_start-80),1.1,['Eoff=',num2str(Eoff),'mJ'],'FontSize',13);
text(time(SWoff_start),0.45,'Poff','color','red','FontSize',13);
text(time(SWoff_start+160),0.95,'Vce','color','green','FontSize',13);
text(time(SWoff_start-30),0.95,'Ic','color','blue','FontSize',13);
title(strcat('Ic=',num2str(fix(Ictop)),' 关断损耗计算(归1化)'));
hold on
grid on;
saveas(gcf,[[path,'.\pic\',dataname,'\Eigbt\'],['Ic=',num2str(fix(Ictop)),'-Eoff'],'.png'])
close(gcf);
hold off;
%% （3）
[~,cemax]=sort(ch2(toff90:fix(toff90+cntoff1/3)),'descend');
Vcemax=ch2(toff90+cemax(1)-1);
[~,dmax]=sort(ch4(ton2:toff2),'descend');
Vdmax=ch4(ton2+dmax(1)-1);
plot(time(toff90:ton2),ch2(toff90:ton2),'b');
hold on
plot(time(toff90+cemax(1)-1),ch2(toff90+cemax(1)-1),'o','color','red');
text(time(toff90+cemax(1)+200),ch2(toff90+cemax(1)-1)-20,['Vcemax=',num2str(Vcemax),'V'],'FontSize',13);
title(strcat('Ic=',num2str(fix(Ictop)),' Vcemax'));
hold on
grid on
saveas(gcf,[[path,'.\pic\',dataname,'\Vce\'],['Ic=',num2str(fix(Ictop)),'-Vcemax'],'.png'])
close(gcf);
hold off

plot(time(ton2:toff2),ch4(ton2:toff2),'b');
hold on
plot(time(ton2+dmax(1)-1),ch4(ton2+dmax(1)-1),'o','color','red');
text(time(ton2+dmax(1)+50),ch4(ton2+dmax(1)-1)-20,['Vdmax=',num2str(Vdmax),'V'],'FontSize',13);
title(strcat('Ic=',num2str(fix(Ictop)),' Vdmax'));
hold on
grid on
saveas(gcf,[[path,'.\pic\',dataname,'\Vd\'],['Ic=',num2str(fix(Ictop)),'-Vdmax'],'.png'])
close(gcf);
hold off
%% （4）
V_10=Vcetop*0.1;
V_90=Vcetop*0.9;
I_10=Ictop*0.1;
I_90=Ictop*0.9;
Vceoff=zeros(length(Ic),1);
Icon=Vceoff;
[~,Icmax]=sort(ch3(SWon_start:SWon_stop),'descend');
% Vceoff(SWoff_start-50:toff90+cemax(1)-1)=ch2(SWoff_start-50:toff90+cemax(1)-1);
% Icon(SWon_start-50:SWon_start+Icmax(1)-1)=ch3(SWon_start-50:SWon_start+Icmax(1)-1);
% [~,vv] = min(abs(Vceoff(:)-V_10));
% ab=ind2sub(size(Vceoff),vv);
% [~,vv] = min(abs(Vceoff(:)-V_90));
% ba=ind2sub(size(Vceoff),vv);
for i = SWoff_start-50:toff90+cemax(1)-1
    if ch2(i)>=V_10
        ab=i;
        break;
    end
end
for i = ab:toff90+cemax(1)-1
    if ch2(i)>=V_90
        ba=i;
        break;
    end
end
dvdt=(ch2(ba)-ch2(ab))/(time(ba)-time(ab))/1000000;
% [~,ii] = min(abs(Icon(:)-I_10));
% aa=ind2sub(size(Icon),ii);
% [~,ii] = min(abs(Icon(:)-I_90));
% bb=ind2sub(size(Icon),ii);
for i = SWon_start-50:SWon_start+Icmax(1)-1
    if ch3(i)>=I_10
        aa=i;
        break;
    end
end
for i = aa:SWon_start+Icmax(1)-1
    if ch3(i)>=I_90
        bb=i;
        break;
    end
end
didt=(ch3(bb)-ch3(aa))/(time(bb)-time(aa))/1000000;
plot(time(ab-50:ba+50),ch2(ab-50:ba+50),'b');
hold on
plot(time(ab:ba),ch2(ab:ba),'r');
hold on
ylim([0,Vcemax]);
xlim([time(ab-50),time(ba+50)]);
plot(time(ab),ch2(ab),'o','color','red');
plot(time(ba),ch2(ba),'o','color','red');
text(time(ab+3),ch2(ab),['Vce=',num2str(ch2(ab)),'V',],'FontSize',13);
text(time(ba+3),ch2(ba),['Vce=',num2str(ch2(ba)),'V'],'FontSize',13);
text(time(ab-40),Vcemax*0.9,['Vcetop=',num2str(Vcetop),'V'],'FontSize',13);
text(time(ab-40),Vcemax*0.8,['dv/dt=',num2str(dvdt),'V/us'],'FontSize',13);
title(strcat('Ic=',num2str(fix(Ictop)),' dv/dt计算'));
grid on
saveas(gcf,[[path,'.\pic\',dataname,'\dvdt\'],['Ic=',num2str(fix(Ictop)),'-dvdt','-Vcetop=',num2str(fix(Vcetop))],'.png'])
close(gcf);
hold off

plot(time(SWon_start-50:SWon_stop+50),ch3(SWon_start-50:SWon_stop+50),'b');
hold on
plot(time(aa:bb),ch3(aa:bb),'r');
hold on
ylim([0,max(ch3(SWon_start-50:SWon_stop))]);
xlim([time(SWon_start-50),time(SWon_stop+50)]);
plot(time(aa),ch3(aa),'o','color','red');
plot(time(bb),ch3(bb),'o','color','red');
text(time(aa+3),ch3(aa),['Ic=',num2str(ch3(aa)),'A'],'FontSize',13);
text(time(bb+3),ch3(bb),['Ic=',num2str(ch3(bb)),'A'],'FontSize',13);
text(time(SWon_start-40),max(ch3(SWon_start-50:SWon_stop))*0.9,['Ictop=',num2str(Ictop),'A'],'FontSize',13);
text(time(SWon_start-40),max(ch3(SWon_start-50:SWon_stop))*0.8,['di/dt=',num2str(didt),'A/us'],'FontSize',13);
title(strcat('Ic=',num2str(fix(Ictop)),' di/dt计算'));
grid on
saveas(gcf,[[path,'.\pic\',dataname,'\didt\'],['Ic=',num2str(fix(Ictop)),'-didt'],'.png'])
close(gcf);
%% （5）
tdoff=(time(toffIcm90)-time(toff90))*10^9;
tf=(time(toffIcm10)-time(toffIcm90))*10^9;
plot(time(toff90*0.997:toffIcm10*1.003),ch1(toff90*0.997:toffIcm10*1.003),'g')
hold on
plot(time(toff90:toffIcm90),ch1(toff90:toffIcm90),'r')
hold on
plot(time(toffIcm90:toffIcm10),ch1(toffIcm90:toffIcm10),'b')
hold on
text(time(toff90)*1.0005,ch1(toff90),['t(d)off=',num2str(tdoff),'ns'],'FontSize',13,'color','red');
text(time(toffIcm90)*1.0005,ch1(toffIcm90),['tf=',num2str(tf),'ns'],'FontSize',13,'color','blue');
grid on
title(strcat('Ic=',num2str(fix(Ictop)),'  Toff=',num2str(tf+tdoff),'ns'));
saveas(gcf,[[path,'.\pic\',dataname,'\Toff\'],['Ic=',num2str(fix(Ictop)),'-Toff'],'.png'])
close(gcf);
tdon=(time(tonIcm10)-time(ton10))*10^9;
tr=(time(tonIcm90)-time(tonIcm10))*10^9;
plot(time(ton10*0.997:tonIcm90*1.003),ch1(ton10*0.997:tonIcm90*1.003),'g')
hold on
plot(time(ton10:tonIcm10),ch1(ton10:tonIcm10),'r')
hold on
plot(time(tonIcm10:tonIcm90),ch1(tonIcm10:tonIcm90),'b')
hold on
text(time(ton10)*1.0005,ch1(ton10),['t(d)on=',num2str(tdon),'ns'],'FontSize',13,'color','red');
text(time(tonIcm10)*1.0005,ch1(tonIcm10),['tr=',num2str(tr),'ns'],'FontSize',13,'color','blue');
grid on
title(strcat('Ic=',num2str(fix(Ictop)),'  Ton=',num2str(tr+tdon),'ns'));
saveas(gcf,[[path,'.\pic\',dataname,'\Ton\'],['Ic=',num2str(fix(Ictop)),'-Ton'],'.png'])
close(gcf);
%% （6）
output=zeros(16,1);
output(1)=Vcetop;
output(2)=Ictop;
output(3)=Eon;
output(4)=Eoff;
output(5)=Vcemax;
output(6)=Vdmax;
output(7)=dvdt;
output(8)=didt;
output(9)=tdon;
output(10)=tr;
output(11)=tr+tdon;
output(12)=tdoff;
output(13)=tf;
output(14)=tdoff+tf;
% output(15)=Erec;
% output(16)=Prrmax;
end
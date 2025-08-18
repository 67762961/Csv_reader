function output = countE(locate,tablename,tablenum,nspd,path,dataname,Chmode,dvdtmode,didtmode,Fuzaimode,Ch_labels,Vgeth,gate_didt,gate_Eerc,Smooth_Win)

%% 数据读取与预处理
% fprintf('%s',Chmode);
num = num2str(tablenum, '%03d');  
filename = fullfile(locate, [tablename, '_', num, '_ALL.csv']);     % 修正路径拼接
data0 = readmatrix(filename, 'NumHeaderLines', 20);                 % 跳过CSV头部元数据
fprintf('%s\n',filename);
% 通道修正
if strcmp(Chmode,'findch')
    data = findch(data0,0);
elseif strcmp(Chmode,'setch')
    data = setch(data0,Ch_labels);
else
    error('通道分配模式参数填写错误')
end

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% % % % findch1函数调试块
% % % outputtable=strcat(['D:\_Du_chengzhi\Matlab\CSV读取程序\TestLib\3','\result\','通道修复结果.xlsx']);
% % % writematrix(data,outputtable,'sheet',[tablename, '_', num, '_ALL.csv'],'range','A2');
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

% Ch_labels(5) = Dflag * Ch_labels(5);
if Fuzaimode ~= 0 
    Ch_labels(3) = 0;
    ch3 = data(:,4);
end

% 提取原始信号（假设数据列顺序已校准）
time = data(:,1);       % 时间序列（单位s）
ch1 = data(:,2);        % Vge（门极电压）
ch2 = data(:,3);        % Vce（集射极电压）

if (Fuzaimode == 0)
    ch3 = data(:,4);        % Ic（集电极电流）
end

ch4 = data(:,5);        % Vd（二极管电压）

if (Ch_labels(5)~=0)
    ch5 = Ch_labels(5)/abs(Ch_labels(5))*data(:,6);        % Id（二极管电流）
end

if (Ch_labels(6)~=0)
    ch6 = data(:,7);        % Id（二极管电流）
end

% 信号滤波（抑制噪声）
% 门极电压：移动中值滤波
Vge = smoothdata(ch1, 'movmedian', Smooth_Win(1));  

% 集射电压：移动中值滤波
Vce = smoothdata(ch2, 'movmedian', Smooth_Win(2), 'omitnan');

% 集电极电流：移动平均滤波
if (Ch_labels(3)~=0)
    Ic = smoothdata(ch3, 'movmean', Smooth_Win(3));    
end

Vd = smoothdata(ch4, 'movmedian', Smooth_Win(4), 'omitnan');

if (Ch_labels(5)~=0)
    Id = smoothdata(ch5, 'movmean', Smooth_Win(5));  
end

if (Ch_labels(6)~=0)
    Vge_dg = smoothdata(ch6, 'movmean', Smooth_Win(6));  
end


%% 开通关断区块划分

% Vge过零点位置记录
cntVge = indzer(Vge,Vgeth);
% Vge过零点次数记录
cntsw = length(cntVge); 
if cntsw ~= 6
    warning('Vge过零点位置不等于六处 可能出现开关状态判断异常')
end
% fprintf('%d\n',cntsw);
% 第0次开通时间点
ton0=cntVge(cntsw-5);
% 第0次关断时间点
toff0=cntVge(cntsw-4); 
% 第一次开通时间点
ton1=cntVge(cntsw-3);
% 第一次关断时间点
toff1=cntVge(cntsw-2); 
% 第二次开通时间点
ton2=cntVge(cntsw-1); 
% 第二次关断时间点
toff2=cntVge(cntsw); 

% 计算第0开通时长
cnton0 = toff0-ton0; 
% 计算第一开通时长
cnton1 = toff1-ton1; 
% 计算两次脉冲间关断时长
cntoff1 = ton2-toff1; 
% 计算第二个脉冲开通时长
cnton2 = toff2-ton2; 

%% 探头偏置校正（静态区间均值）
if (Ch_labels(3)~=0)
    static_ic_interval = fix(toff1 + cntoff1/4) : fix(ton2 - cntoff1/4);
    meanIc = mean(Ic(static_ic_interval)); % 关断时平均电流视为参考0电流
    Ic = Ic - meanIc; % 电流探头较零
    ch3 = ch3 - meanIc;
    fprintf('探头自动较零:\n');
    fprintf('       Ic偏移量:%03fA\n',meanIc);
end

if (Ch_labels(5)~=0)
    static_id_interval = fix(ton0 + cnton0/4) : fix(toff0 - cnton0/4);
    meanId = mean(Id(static_id_interval)); 
    Id = Id - meanId;% 电流探头较零
    ch5 = ch5 - meanId;
    fprintf('       Id偏移量:%03fA\n',meanId);
end

%% 各项数据计算
% ====================== Vcetop Vcemax Ictop Icmax Vdmax 计算 ======================
[Ictop,tIcm,Icmax] = count_Icmax_Ictop(num,time,ch3,path,dataname,ton1,toff1,cnton1,ton2,toff2);
[Vcemax,Vcetop,ton10,toff90] = count_Vcemax_Vcetop(num,time,Vge,ch2,Ictop,path,dataname,ton1,toff1,cnton1,cntoff1,ton2,toff2);
[Vdmax] = count_Vdmax(num,time,ch4,Ictop,path,dataname,ton2,toff2);

if (Ch_labels(3)~=0)
    % ====================== 开通损耗计算（Eon） ======================
    [Eon,SWon_start,SWon_stop] = count_Eon(num,time,Ic,Vce,Ictop,Vcetop,path,dataname,ton2,toff2,cntoff1);


    % ====================== 关断损耗计算（Eoff） ======================
    [Eoff,SWoff_start,SWoff_stop] = count_Eoff(num,time,Ic,Vce,Ictop,Vcetop,path,dataname,ton2,toff90);
else
    Eon = " ";
    Eoff = " ";
end


if (Ch_labels(3)~=0)
    % ====================== dv/dt计算模块 ======================
    [dvdt,dvdt_a_b] = count_dvdt(num,nspd,dvdtmode,time,Vce,Ictop,Vcetop,Vcemax,path,dataname,SWoff_start,SWoff_stop);
    % 若启动额外dvdt计算 则dvdt表格输出按照手动设置组输出
    dvdtoutput = (dvdtmode(1) ~= 10 || dvdtmode(2) ~= 90) * dvdt_a_b + (dvdtmode(1) == 10 && dvdtmode(2) == 90) * dvdt;

    % ====================== di/dt计算模块 ======================
    [didt,tonIcm10,tonIcm90] = count_didt(num,nspd,didtmode,gate_didt,time,ch3,Ictop,path,dataname,SWon_start,SWon_stop);

    % ====================== 开通时间（Ton）计算 ======================
    [tdon,tr] = count_Ton(num,nspd,time,ch1,Ictop,path,dataname,ton10,tonIcm10,tonIcm90);

    % ====================== 关断时间（Toff）计算与绘图 ======================
    [tdoff,tf] = count_Toff(num,nspd,time,ch1,Ic,Ictop,path,dataname,tIcm,toff1,ton2,toff90);
else
    dvdtoutput = " ";
    didt = " ";
    tdon = " ";
    tr = " "; 
    tdoff = " ";
    tf = " ";
end

% ====================== 对管门极监测 Vge_dg ======================
if (Ch_labels(6)~=0)
    [Vge_dg_mean,Vge_dg_max,Vge_dg_min] = count_Vge_dg(num,time,ch6,Vge_dg,Ictop,path,dataname,cnton2);
else
    Vge_dg_mean = " ";
    Vge_dg_max = " ";
    Vge_dg_min = " ";
end

% ====================== Prr/Erec计算 ======================
if (Ch_labels(5)~=0) && (Ch_labels(4)~=0) && (Ch_labels(3)~=0)
    [Prrmax,Erec] = count_Prr_Erec(num,gate_Eerc,time,Id,Vd,ch4,ch5,Ictop,Vcetop,path,dataname,ton2,toff2);
else
    Prrmax = " ";
    Erec = " ";
end


%% 输出表
output=zeros(20,1);

output(1)=Ictop;
output(2)=Eon;
output(3)=Eoff;
output(4)=Vcemax;
output(5)=Vdmax;
output(6)=Vcetop;
output(7)=dvdtoutput;
output(8)=didt;
output(9)=Erec;
output(10)=Prrmax;
output(11)=Vge_dg_max;
output(12)=Vge_dg_min;
output(13)=tdon;
output(14)=tdoff;
output(15)=" ";
output(16)=Icmax;
output(17)=tr;
output(18)=tf;
output(19)=Vge_dg_mean;


fprintf('\n');
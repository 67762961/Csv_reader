function [output,output_backup] = countE(locate,tablename,tablenum,path,dataname,title,Chmode,dvdtmode,didtmode,DuiguanMARK,DuiguanCH,Fuzaimode,Ch_labels,Vgeth,gate_didt,gate_Erec,Smooth_Win,I_Fix,I_meature)

%% 数据读取与预处理
% fprintf('%s',Chmode);
num = num2str(tablenum, '%03d');
filename = fullfile(locate, [tablename, '_', num, '_ALL.csv']);     % 修正路径拼接
data0 = readmatrix(filename, 'NumHeaderLines', 20);                 % 跳过CSV头部元数据
fprintf('%s\n',filename);

if Fuzaimode ~= 0
    Ch_labels(4) = 0;
    Ch_labels(5) = 0;
end

% 通道修正
if strcmp(Chmode,'findch')
    data = findch(data0,0);
elseif strcmp(Chmode,'setch')
    data = setch(data0,Ch_labels,DuiguanCH,Fuzaimode);
else
    fprintf('\n 通道分配模式参数填写错误 \n')
    error('通道分配异常')
end

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% % % % findch1函数调试块
% % % outputtable=strcat(['D:\_Du_chengzhi\Matlab\CSV读取程序\TestLib\3','\result\','通道修复结果.xlsx']);
% % % writematrix(data,outputtable,'sheet',[tablename, '_', num, '_ALL.csv'],'range','A2');
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

% Ch_labels(5) = Dflag * Ch_labels(5);

% 提取原始信号（假设数据列顺序已校准）
time = data(:,1);       % 时间序列（单位s）
ch1 = data(:,2);        % Vge（门极电压）
ch2 = data(:,3);        % Vce（集射极电压）

if Fuzaimode ~= 0
    I_fuzai = data(:,10);
end

if (Ch_labels(3)~=0)
    ch3 = Ch_labels(3)/abs(Ch_labels(3))*data(:,4);       % Ic（集电极电流）
end

ch4 = data(:,5);        % Vd（二极管电压）


if (Ch_labels(5)~=0)
    ch5 = Ch_labels(5)/abs(Ch_labels(5))*data(:,6);        % Id（二极管电流）
end

Vge_dg = zeros(length(data(:,1)),length(DuiguanCH));
for j = 1:length(DuiguanCH)
    if (DuiguanCH(j)~=0)
        Vge_dg(:,j) = data(:,6+j); % 对管门极电压
    end
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

%% 开通关断区块划分

% Vge过零点位置记录
cntVge = indzer(Vge,Vgeth);
% Vge过零点次数记录
cntsw = length(cntVge);
if cntsw ~= 6
    fprintf('\n Vge开通阈值位置有%d处 可能出现开关状态判断异常 \n',cntsw)
    error('过零点判断异常')
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
if (I_Fix(1) == 1) || (I_Fix(2) == 1)
    fprintf('探头自动较零:\n');
end
if (Ch_labels(3)~=0) && (I_Fix(1) == 1)
    static_ic_interval = fix(toff1 + cntoff1/4) : fix(ton2 - cntoff1/4);
    meanIc = mean(Ic(static_ic_interval)); % 关断时平均电流视为参考0电流
    Ic = Ic - meanIc; % 电流探头较零
    ch3 = ch3 - meanIc;
    fprintf('       Ic偏移量:%03fA\n',meanIc);
end

if (Ch_labels(5)~=0) && (I_Fix(2) == 1)
    static_id_interval = fix(ton1 + cnton1/2) : fix(toff1 - cnton1/4);
    meanId = mean(Id(static_id_interval));
    Id = Id - meanId;% 电流探头较零
    ch5 = ch5 - meanId;
    fprintf('       Id偏移量:%03fA\n',meanId);
end

%% 各项数据计算
% ====================== Vcetop Vcemax Ictop Icmax Vdmax 计算 ======================
if (Fuzaimode == 0)
    [Ictop,tIcm,Icmax] = count_Icmax_Ictop(num,time,ch3,Ch_labels(5),ch5,path,dataname,I_meature,ton1,toff1,cnton1,ton2,toff2);
else
    [Ictop,tIcm,Icmax] = count_Icmax_Ictop(num,time,I_fuzai,Ch_labels(5),ch5,path,dataname,I_meature,ton1,toff1,cnton1,ton2,toff2);
end

[Vcemax,Vcetop,ton10,toff90] = count_Vcemax_Vcetop(num,time,Vge,ch2,Ch_labels(4),ch4,Ictop,path,dataname,ton1,toff1,cnton1,cntoff1,ton2,toff2);

if (Ch_labels(4)~=0)
    [Vdmax] = count_Vdmax(num,time,ch4,Ictop,path,dataname,ton2,toff2);
else
    Vdmax = "   ";
end

if (Ch_labels(3)~=0)
    % ====================== 开通损耗计算（Eon） ======================
    [Eon,SWon_start,SWon_stop] = count_Eon(num,time,Ic,Vce,Ictop,Vcetop,path,dataname,ton2,toff2,cntoff1);
    
    
    % ====================== 关断损耗计算（Eoff） ======================
    [Eoff,SWoff_start,SWoff_stop] = count_Eoff(num,time,Ic,Vce,Ictop,Vcetop,path,dataname,ton2,ton1,cnton1);
else
    Eon = " ";
    Eoff = " ";
end


if (Ch_labels(3)~=0)
    % ====================== dv/dt计算模块 ======================
    [dvdt,dvdt_a_b] = count_dvdt(num,dvdtmode,time,Vce,Ictop,Vcetop,Vcemax,path,dataname,SWoff_start,SWoff_stop);
    % 若启动额外dvdt计算 则dvdt表格输出按照手动设置组输出
    dvdtoutput = (dvdtmode(1) ~= 10 || dvdtmode(2) ~= 90) * dvdt_a_b + (dvdtmode(1) == 10 && dvdtmode(2) == 90) * dvdt;
    
    % ====================== di/dt计算模块 ======================
    [didt,tonIcm10,tonIcm90] = count_didt(num,didtmode,gate_didt,time,ch3,Ictop,path,dataname,SWon_start,SWon_stop);
    
    % ====================== 开通时间（Ton）计算 ======================
    [tdon,tr] = count_Ton(num,time,ch1,Ictop,path,dataname,ton10,tonIcm10,tonIcm90);
    
    % ====================== 关断时间（Toff）计算与绘图 ======================
    [tdoff,tf] = count_Toff(num,time,ch1,Ic,Ictop,path,dataname,tIcm,toff1,ton2,toff90);
else
    dvdtoutput = " ";
    didt = " ";
    tdon = " ";
    tr = " ";
    tdoff = " ";
    tf = " ";
end

% ====================== 对管门极监测 Vge_dg ======================
Vge_dg_mean = strings(1,length(DuiguanCH));
Vge_dg_max = strings(1,length(DuiguanCH));
Vge_dg_min = strings(1,length(DuiguanCH));

for gd_num = 1:length(DuiguanCH)
    if (DuiguanCH(gd_num)~=0)
        [Vge_dg_mean(gd_num),Vge_dg_max(gd_num),Vge_dg_min(gd_num)] = count_Vge_dg(num,time,Vge_dg(:,gd_num),Ictop,path,dataname,cnton2,toff1,ton2,DuiguanMARK(gd_num));
    else
        Vge_dg_mean(gd_num) = " ";
        Vge_dg_max(gd_num) = " ";
        Vge_dg_min(gd_num) = " ";
    end
end

% ====================== Prr/Erec计算 ======================
if (Ch_labels(5)~=0) && (Ch_labels(4)~=0) && (Ch_labels(3)~=0)
    [Prrmax,Erec] = count_Prr_Erec(num,gate_Erec,time,Id,Vd,ch4,ch5,Ictop,Vcetop,path,dataname,ton2,toff2);
else
    Prrmax = " ";
    Erec = " ";
end

% ====================== 脉宽长度计算 ======================
nspd = (time(2)-time(1))*1e9;
if(Ch_labels(3)~=0)
    Length_ton0 = 2*fix((cnton0+(tdon-tdoff)/nspd) /(2000/nspd) + 0.5);
else
    Length_ton0 = 2*fix((cnton0/nspd) /(2000/nspd) + 0.5);
end

% ====================== 反向恢复极限功率 ======================
if (Ch_labels(5)~=0) && (Ch_labels(4)~=0) && (Ch_labels(3)~=0)
    Delta_Ic = Icmax - Ictop;
    PrrPROMAX = Delta_Ic * Vdmax / 1000; % 单位kW
else
    PrrPROMAX = " ";
end

% 创建datamap数据字典
dataMap = containers.Map;
dataMap('脉宽长(us)') = Length_ton0;
dataMap('  CSV  ') = tablenum;
dataMap('Ic(A)') = Ictop;
dataMap('Icmax(A)') = Icmax;
dataMap('Eon(mJ)') = Eon;
dataMap('Eoff(mJ)') = Eoff;
dataMap('VceMAX(V)') = Vcemax;
dataMap('VdMAX(V)') = Vdmax;
dataMap('Vcetop(V)') = Vcetop;
dataMap('dv/dt(V/us)') = dvdtoutput;
dataMap('di/dt(A/us)') = didt;
dataMap('Erec(mJ)') = Erec;
dataMap('Prrmax(kW)') = Prrmax;
dataMap('PrrPROMAX(kW)') = PrrPROMAX;
dataMap('Vgedg1max(V)') = Vge_dg_max(1);
dataMap('Vgedg1min(V)') = Vge_dg_min(1);
dataMap('Vgedg1mean(V)') = Vge_dg_mean(1);
dataMap('Vgedg2max(V)') = Vge_dg_max(2);
dataMap('Vgedg2min(V)') = Vge_dg_min(2);
dataMap('Vgedg2mean(V)') = Vge_dg_mean(2);
dataMap('Tdon(ns)') = tdon;
dataMap('Trise(ns)') = tr;
dataMap('Tdoff(ns)') = tdoff;
dataMap('Tfall(ns)') = tf;
dataMap('    ') = " ";


%% 输出表
output=zeros(length(title),1);
for i = 1:length(title)
    currentKey = title{i};
    currentValue = dataMap(currentKey);
    output(i) = currentValue;
end

Full_title = {'脉宽长(us)', '  CSV  ', 'Ic(A)', 'Icmax(A)', 'Eon(mJ)', 'Eoff(mJ)', 'VceMAX(V)', 'VdMAX(V)', 'Vcetop(V)', 'dv/dt(V/us)', 'di/dt(A/us)', 'Erec(mJ)', 'Prrmax(kW)', 'PrrPROMAX(kW)', 'Vgedg1max(V)', 'Vgedg1min(V)', 'Vgedg1mean(V)', 'Vgedg2max(V)', 'Vgedg2min(V)', 'Vgedg2mean(V)', 'Tdon(ns)', 'Trise(ns)', 'Tdoff(ns)', 'Tfall(ns)'};
output_backup = zeros(length(Full_title),1);
for i = 1:length(Full_title)
    currentKey = Full_title{i};
    currentValue = dataMap(currentKey);
    output_backup(i) = currentValue;
end
fprintf('\n');
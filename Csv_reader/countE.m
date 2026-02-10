function [output,output_backup] = countE(filename,num,path,dataname,DPI,title,Full_title,Para_mode)

% 模式配置参数
Chmode      = Para_mode.Chmode   ;       %% 通道分配模式
Ch_labels   = Para_mode.Ch_labels;       %% 通道分配
Smooth_Win  = Para_mode.Smooth_Win;      %% 通道滤波窗口长度
Eonmode     = Para_mode.Eonmode;         %% 开通损耗配置
Eoffmode    = Para_mode.Eoffmode;        %% 关断损耗配置
dvdtmode    = Para_mode.dvdtmode ;       %% dvdt模式
didtmode    = Para_mode.didtmode ;       %% didt模式
Fuzaimode   = Para_mode.Fuzaimode;
INTG_I2t    = Para_mode.INTG_I2t;
DuiguanMARK = Para_mode.DuiguanMARK;
DuiguanCH   = Para_mode.DuiguanCH;
I_Fix       = Para_mode.I_Fix;           %% 是否对电流进行校正     1-校正 0-不校正
I_meature   = Para_mode.I_meature;       %% 以Ic或Id计算的实际测试电流值
gate_didt   = Para_mode.gate_didt;       %% didt上升沿检测允许回落阈值
gate_Erec   = Para_mode.gate_Erec;       %% Erec下降沿检测允许抬升阈值
Vgeth       = Para_mode.Vgeth    ;       %% 门极开关门槛值 依据器件手册提供 一般为0

%% 数据读取与预处理
% fprintf('%s',Chmode);
data0 = readmatrix(filename, 'NumHeaderLines', 20);                 % 跳过CSV头部元数据
fprintf('%s\n',filename);

% if Fuzaimode ~= 0
%     Ch_labels(3) = 0;
%     I_Fix(1) = 0;
%     I_Fix(2) = 0;
% end

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
    I_fuzai = Fuzaimode/abs(Fuzaimode)*data(:,10);
else
    I_fuzai = time*0;
end

if (Ch_labels(3)~=0)
    ch3 = Ch_labels(3)/abs(Ch_labels(3))*data(:,4);       % Ic（集电极电流）
else
    ch3 = time*0;
end

if (Ch_labels(4)~=0)
    ch4 = data(:,5);        % Vd（二极管电压）
else
    ch4 = time*0;
end

if (Ch_labels(5)~=0)
    ch5 = Ch_labels(5)/abs(Ch_labels(5))*data(:,6);        % Id（二极管电流）
else
    ch5 = time*0;
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
if (cntsw ~= 6) && (cntsw ~= 4)
    fprintf('\n Vge开通阈值位置有%d处 可能出现开关状态判断异常 \n',cntsw)
    cntVge_time=zeros(1,cntsw);
    for i=1:cntsw
        cntVge_time(i) = time(cntVge(i))*1e6;
    end
    disp(cntVge_time)
    error('过零点判断异常')
end

[Vgetop,Vgebase,cntVge] = count_Vge(ch1,cntVge);

% 第一次开通时间点
ton1=cntVge(cntsw-3);
% 第一次关断时间点
toff1=cntVge(cntsw-2);
% 第二次开通时间点
ton2=cntVge(cntsw-1);

% 计算第一开通时长
cnton1 = toff1-ton1;
% 计算两次脉冲间关断时长
cntoff1 = ton2-toff1;

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
[Ictop,Icmax,I_Fuizai_on,I_Fuizai_off] = count_Icmax_Ictop(num,DPI,time,Ch_labels,Fuzaimode,ch3,ch5,I_fuzai,path,dataname,I_meature,cntVge);

[Vcemax,Vcetop,Vdmax] = count_Vcemax_Vcetop(num,DPI,time,ch2,Ch_labels(4),ch4,Ictop,path,dataname,cntVge);

if (Ch_labels(3)~=0)
    % ====================== 开关损耗计算（Eon&Eoff） ======================
    [Eon,SWon_start,SWon_stop,Eoff,SWoff_start,SWoff_stop] = count_Eon_Eoff(num,DPI,time,Ic,Vce,Ictop,Vcetop,path,dataname,cntVge,Eonmode,Eoffmode);
    
    cntSW = [SWon_start,SWon_stop,SWoff_start,SWoff_stop];
else
    Eon = " ";
    Eoff = " ";
    cntSW = [ton2-fix(cnton1/5),ton2+fix(cnton1/5),toff1-fix(cnton1/5),toff1+fix(cnton1/5)];
end

if (Ch_labels(3)~=0)
    % ====================== dv/dt计算模块 ======================
    [dvdt_on,dvdt_off,~] = count_dvdt(num,DPI,dvdtmode,time,Vce,Ictop,Vcetop,Vcemax,path,dataname,cntSW);
    
    % ====================== di/dt计算模块 ======================
    [didt_on,didt_off,Tdidt] = count_didt(num,DPI,didtmode,gate_didt,time,ch3,I_Fuizai_on,I_Fuizai_off,path,dataname,cntVge);
    
    % ====================== 开通关断时间（Ton&Toff）计算 ======================
    [tdon,tr,tdoff,tf] = count_Ton_Toff(num,DPI,time,ch1,ch3,Vgetop,Vgebase,Ictop,path,dataname,cntVge,'Tdidt',Tdidt);
    
elseif (Fuzaimode ~= 0)
    % ====================== dv/dt计算模块 ======================
    [dvdt_on,dvdt_off,Tdvdt] = count_dvdt(num,DPI,dvdtmode,time,Vce,Ictop,Vcetop,Vcemax,path,dataname,cntSW);
    
    % ====================== 开通关断时间（Ton&Toff）计算 ======================
    [tdon,tr,tdoff,tf] = count_Ton_Toff(num,DPI,time,ch1,ch2,Vgetop,Vgebase,Ictop,path,dataname,cntVge,'Tdvdt',Tdvdt);
    
    didt_on = " ";
    didt_off = " ";
else
    dvdt_on = " ";
    dvdt_off = " ";
    didt_on = " ";
    didt_off = " ";
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
        [Vge_dg_mean(gd_num),Vge_dg_max(gd_num),Vge_dg_min(gd_num)] = count_Vge_dg(num,DPI,time,Vge_dg(:,gd_num),Ictop,path,dataname,cntVge,DuiguanMARK(gd_num));
    else
        Vge_dg_mean(gd_num) = " ";
        Vge_dg_max(gd_num) = " ";
        Vge_dg_min(gd_num) = " ";
    end
end

if (Ch_labels(5)~=0) && (Ch_labels(4)~=0) && (Ch_labels(3)~=0)
    % ====================== Prr/Erec计算 ======================
    [Prrmax,Erec] = count_Prr_Erec(num,DPI,gate_Erec,time,Id,Vd,ch4,ch5,Ictop,Vcetop,path,dataname,cntVge);
    
    % ====================== 反向恢复极限功率 ======================
    Delta_Ic = Icmax - Ictop;
    PrrPROMAX = Delta_Ic * Vdmax / 1000; % 单位kW
else
    Prrmax = " ";
    Erec = " ";
    PrrPROMAX = " ";
end

% ====================== 脉宽长度计算 ======================
nspd = (time(2)-time(1))*1e9;
Length_ton0 = 2*fix(((cntVge(2)-cntVge(1))/nspd) /(2000/nspd) + 0.5);

% ====================== 纯C方案的Irms辅助计算 ======================
if (INTG_I2t~=0)
    I_cap = data0(:,INTG_I2t+1);        % 电容电流
    static_ic_interval = fix(ton2 - cntoff1*3/10) : fix(ton2 - cntoff1/10);
    meanI_cap = mean(I_cap(static_ic_interval)); % 关断时平均电流视为参考0电流
    I_cap = I_cap - meanI_cap; % 电流探头较零
    fprintf('       I_cap:%03fA\n',meanI_cap);
    [I2dt_on,I2dt_off] = count_i2dt(num,DPI,time,I_cap,Ictop,path,dataname,cntVge,Tdidt);
else
    I2dt_on = " ";
    I2dt_off = " ";
end


% 创建datamap数据字典
dataMap = containers.Map;
dataMap('脉宽长(us)') = Length_ton0;
dataMap('  CSV  ') = str2double(num);
dataMap('Ic(A)') = Ictop;
dataMap('Icmax(A)') = Icmax;
dataMap('Eon(mJ)') = Eon;
dataMap('Eoff(mJ)') = Eoff;
dataMap('VceMAX(V)') = Vcemax;
dataMap('VdMAX(V)') = Vdmax;
dataMap('Vcetop(V)') = Vcetop;
dataMap('dv/dton(V/us)') = dvdt_on;
dataMap('dv/dtoff(V/us)') = dvdt_off;
dataMap('di/dton(A/us)') = didt_on;
dataMap('di/dtoff(A/us)') = didt_off;
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
dataMap('Vgetop(V)') = Vgetop;
dataMap('Vgebase(V)') = Vgebase;
dataMap('I2dt_on') = I2dt_on;
dataMap('I2dt_off') = I2dt_off;
dataMap('I_Fuizai_on') = I_Fuizai_on;
dataMap('I_Fuizai_off') = I_Fuizai_off;
dataMap('    ') = " ";


%% 输出表
output=zeros(length(title),1);
for i = 1:length(title)
    currentKey = title{i};
    currentValue = dataMap(currentKey);
    output(i) = currentValue;
end

output_backup = zeros(length(Full_title),1);
for i = 1:length(Full_title)
    currentKey = Full_title{i};
    currentValue = dataMap(currentKey);
    output_backup(i) = currentValue;
end
fprintf('\n');
function [output,output_backup] = countE(filename,num,path,dataname,DPI,title,Full_title,Para_mode,Wave_count)

% 模式配置参数
Chmode      = Para_mode.Chmode   ;       %% 通道分配模式
Ch_labels   = Para_mode.Ch_labels;       %% 通道分配
Smooth_Win  = Para_mode.Smooth_Win;      %% 通道滤波窗口长度
Eonmode     = Para_mode.Eonmode;         %% 开通损耗配置
Eoffmode    = Para_mode.Eoffmode;        %% 关断损耗配置
dvdtmode    = Para_mode.dvdtmode ;       %% dvdt模式
didtmode    = Para_mode.didtmode ;       %% didt模式
didt_step   = Para_mode.d_dtstep(1);
dvdt_step   = Para_mode.d_dtstep(2);
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
Vge = smoothdata(ch1, 'movmean', Smooth_Win(1));

% 集射电压：移动中值滤波
Vce = smoothdata(ch2, 'movmedian', Smooth_Win(2), 'omitnan');

% 集电极电流：移动平均滤波
if (Ch_labels(3)~=0)
    Ic = smoothdata(ch3, 'movmean', Smooth_Win(3));
else
    Ic = time*0;
end

Vd = smoothdata(ch4, 'movmedian', Smooth_Win(4), 'omitnan');

if (Ch_labels(5)~=0)
    Id = smoothdata(ch5, 'movmean', Smooth_Win(5));
else
    Id = time*0;
end

%% 开通关断区块划分

% Vge过零点位置记录
nspd = time(2)-time(1); % 时间分辨率
cntVge = indzer(Vge,Vgeth,fix(200/nspd*1e-9)); % 过零点索引及时间间隔过滤

%% 修正门极控制时间
[Vgetop,Vgebase,cntVge] = count_Cnt_Vge(time,DPI,Vge,cntVge);
cntsw = length(cntVge);

[cntVce,VceRange,PicRange] = count_Cnt_Vce(time,ch2,cntVge,DPI,Wave_count);

%% 探头偏置校正（静态区间均值）
[ch3,Ic,ch5,Id,I_FixBar,Icfix,Idfix] = count_I_Fix(time,ch3,Ic,ch5,Id,Ch_labels,I_Fix,cntVce,Wave_count);

%% 各项数据计算
% ====================== Vcetop Vcemax Ictop Icmax Vdmax 计算 ======================
[Ictop,Icmax,I_on,I_off,Idmax] = count_Icmax_Ictop(num,DPI,time,Ch_labels,Fuzaimode,ch3,ch5,I_fuzai,path,dataname,I_meature,cntVge,cntVce,PicRange,I_FixBar,Wave_count);

Vd_flag = Ch_labels(4);

[Vcemax,Vcemax_fix,Vcetop,Vcetop_fix,Vdmax,Vdmax_fix,T_Vcemax,T_Vdmax] = count_Vcemax_Vcetop(num,DPI,time,ch2,Vd_flag,ch4,Ictop,path,dataname,cntVce,PicRange,Wave_count);

if (Ch_labels(3)~=0)
    % ====================== 开关损耗计算（Eon&Eoff） ======================
    [Eon,Eoff] = count_Eon_Eoff(num,DPI,time,Ic,Vce,Ictop,Vcetop,path,dataname,cntVge,Eonmode,Eoffmode,Wave_count);
else
    Eon = " ";
    Eoff = " ";
end
% ====================== dv/dt计算模块 ======================
[dvdt_on,dvdt_off,Tdvdt,Pic_win] = count_dvdt(num,DPI,dvdtmode,time,Vce,Ictop,Vcetop,Vcemax,path,dataname,VceRange);
Tdvdt_fall_start = time(Tdvdt(1));
Tdvdt_fall_end = time(Tdvdt(2));
Tdvdt_rise_start = time(Tdvdt(3));
Tdvdt_rise_end = time(Tdvdt(4));

if (dvdt_step~=0)
    [dvdtoff_max,dvdton_min] = count_dvdt_max(num,DPI,dvdt_step,time,Vce,Ictop,Vcetop,path,dataname,cntVge,Wave_count,Pic_win);
else
    dvdtoff_max = " ";
    dvdton_min = " ";
end

if (Ch_labels(3)~=0)
    % ====================== di/dt计算模块 ======================
    [didt_on,didt_off,Tdidt,Picwin] = count_didt(num,DPI,didtmode,gate_didt,time,ch3,I_on,I_off,path,dataname,cntVge,Wave_count);
    if (didt_step~=0)
        [didton_max,didtoff_min] = count_didt_max(num,DPI,didt_step,time,ch3,I_on,I_off,path,dataname,cntVge,Wave_count,Picwin);
    else
        didton_max = " ";
        didtoff_min = " ";
    end
    % ====================== 开通关断时间（Ton&Toff）计算 ======================
    [tdon,tr,tdoff,tf] = count_Ton_Toff(num,DPI,time,ch1,ch3,Vgetop,Vgebase,Ictop,path,dataname,cntVge,cntVce,'Tdidt',Tdidt,Wave_count);
    
    Tdidt_rise_start = time(Tdidt(1));
    Tdidt_rise_end = time(Tdidt(2));
    Tdidt_fall_start = time(Tdidt(3));
    Tdidt_fall_end = time(Tdidt(4));
else
    Tdidt_rise_start = " ";
    Tdidt_rise_end = " ";
    Tdidt_fall_start = " ";
    Tdidt_fall_end = " ";
    tdon = " ";
    tr = " ";
    tdoff = " ";
    tf = " ";
    didt_on = " ";
    didt_off = " ";
    didton_max = " ";
    didtoff_min = " ";
end

% ====================== 对管门极监测 Vge_dg ======================
Vge_dg_mean = strings(1,length(DuiguanCH));
Vge_dg_max = strings(1,length(DuiguanCH));
Vge_dg_min = strings(1,length(DuiguanCH));

for gd_num = 1:length(DuiguanCH)
    if (DuiguanCH(gd_num)~=0)
        [Vge_dg_mean(gd_num),Vge_dg_max(gd_num),Vge_dg_min(gd_num)] = count_Vge_dg(num,DPI,time,Vge_dg(:,gd_num),Ictop,path,dataname,cntVce,DuiguanMARK(gd_num),Wave_count);
    else
        Vge_dg_mean(gd_num) = " ";
        Vge_dg_max(gd_num) = " ";
        Vge_dg_min(gd_num) = " ";
    end
end

if (Ch_labels(5)~=0) && (Ch_labels(4)~=0)
    % ====================== Prr/Erec计算 ======================
    [Prrmax,Erec] = count_Prr_Erec(num,DPI,gate_Erec,time,Id,Vd,ch4,ch5,Ictop,Vcetop,path,dataname,cntVge,Wave_count);
else
    Prrmax = " ";
    Erec = " ";
end

% ====================== 反向恢复极限功率 ======================
if (Ch_labels(3)~=0) && (Ch_labels(4)~=0)
    Delta_Ic = Icmax - Ictop;
    PrrPROMAX = Delta_Ic * Vdmax / 1000; % 单位kW
else
    PrrPROMAX = " ";
end

% ====================== 脉宽长度计算 ======================
if Wave_count(1) == 3 && Wave_count(2) == 2
    Length_ton0 = fix((time(cntVge(2))-time(cntVge(1)))*1e7 + 0.5)/10;
else
    Length_ton0 = fix(abs(time(cntVge(Wave_count(1)*2-1))-time(cntVge(Wave_count(2)*2)))*1e7 + 0.5)/10;
end
% ====================== 纯C方案的Irms辅助计算 ======================
if (INTG_I2t~=0)
    I_cap = data0(:,INTG_I2t+1);        % 电容电流
    [I2dt_on,I2dt_off] = count_i2dt(num,DPI,time,I_cap,Ictop,path,dataname,cntVge,Tdidt);
else
    I2dt_on = " ";
    I2dt_off = " ";
end

if (Fuzaimode == 0)
    I_on = " ";
    I_off = " ";
end

if (cntsw>4)
    ton0=cntVge(cntsw-5);
    Ton0 = time(ton0);
    toff0=cntVge(cntsw-4);
    Toff0 = time(toff0);
else
    Ton0 = "  ";
    Toff0 = "  ";
end

% 创建datamap数据字典
dataMap = containers.Map;
dataMap('脉宽长(us)') = Length_ton0;
dataMap('  CSV  ') = str2double(num);
dataMap('Ic(A)') = Ictop;
dataMap('Icmax(A)') = Icmax;
dataMap('Idmax(A)') = Idmax;
dataMap('Icfix(A)') = Icfix;
dataMap('Idfix(A)') = Idfix;
dataMap('Eon(mJ)') = Eon;
dataMap('Eoff(mJ)') = Eoff;
dataMap('VceMAX(V)') = Vcemax;
dataMap('VceMAX_fix(V)') = Vcemax_fix;
dataMap('VdMAX(V)') = Vdmax;
dataMap('VdMAX_fix(V)') = Vdmax_fix;
dataMap('Vcetop(V)') = Vcetop;
dataMap('Vcetop_fix(V)') = Vcetop_fix;
dataMap('dv/dton(V/us)') = dvdt_on;
dataMap('dv/dtoff(V/us)') = dvdt_off;
dataMap('dv/dtoffMAX(A/us)') = dvdtoff_max;
dataMap('dv/dtonMIN(A/us)') = dvdton_min;
dataMap('di/dton(A/us)') = didt_on;
dataMap('di/dtoff(A/us)') = didt_off;
dataMap('di/dtonMAX(A/us)') = didton_max;
dataMap('di/dtoffMIN(A/us)') = didtoff_min;
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
dataMap('I_on') = I_on;
dataMap('I_off') = I_off;
dataMap('    ') = " ";
dataMap('Ton0') = Ton0;
dataMap('Toff0') = Toff0;
dataMap('Ton1') = time(cntVge(cntsw-3));
dataMap('Toff1') = time(cntVge(cntsw-2));
dataMap('Ton2') = time(cntVge(cntsw-1));
dataMap('Toff2') = time(cntVge(cntsw));
dataMap('T_Vcemax') = T_Vcemax;
dataMap('T_Vdmax') = T_Vdmax;
dataMap('Tdvdt_fs') = Tdvdt_fall_start;
dataMap('Tdvdt_fe') = Tdvdt_fall_end;
dataMap('Tdvdt_rs') = Tdvdt_rise_start;
dataMap('Tdvdt_re') = Tdvdt_rise_end;
dataMap('Tdidt_rs') = Tdidt_rise_start;
dataMap('Tdidt_re') = Tdidt_rise_end;
dataMap('Tdidt_fs') = Tdidt_fall_start;
dataMap('Tdidt_fe') = Tdidt_fall_end;

%% 输出表
output=zeros(length(title),1);
for i = 1:length(title)
    currentKey = title{i};
    if ~isKey(dataMap, currentKey)
        error('键 "%s" 不存在', currentKey);
    else
        currentValue = dataMap(currentKey);
        output(i) = currentValue;
    end
end

output_backup = zeros(length(Full_title),1);
for i = 1:length(Full_title)
    currentKey = Full_title{i};
    % disp(currentKey);
    currentValue = dataMap(currentKey);
    output_backup(i) = currentValue;
end
fprintf('\n');
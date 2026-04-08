Output_Path = "D:\_TOOLS\Csv_reader_TestLib\test";
dataname = '测试文件名';
Title_1 = '测试大标题';
Title_2 = '测试二标题';
Title_3 = '测试三标题';
Title_4 = '测试四标题';

File_Path_1 =  "D:\_TOOLS\Csv_reader_TestLib\test";
filename_1 = fullfile(File_Path_1, "INVB_001_ALL.csv");
Back_name_1 = "111";
VarNames_CSV1 =["Ch1_高温", "Ch1_Current", "Ch1_Power", "Ch1_Status", "Ch1_Temp"];

File_Path_2 =  "D:\_TOOLS\Csv_reader_TestLib\test";
filename_2 = fullfile(File_Path_2, "INVB_000_ALL.csv");
Back_name_2 = "222";
VarNames_CSV2 =["Ch2_常温", "Ch2_Current", "Ch2_Power", "Ch2_Status", "Ch2_Temp"];

target_1 = 'Ton2';
target_2 = 'Ton1';

% 模式配置参数
Para_mode.Chmode        = 'setch';
Para_mode.Ch_labels     = [1, 2, 3, 4, 5];
Para_mode.Smooth_Win    = [1, 1, 1, 1, 1];
Para_mode.Eonmode       = [0.1, 0.02, 0.2, 0];
Para_mode.Eoffmode      = [0.1, 0.02, 0.2, 0];
Para_mode.dvdtmode      = [80, 20, 10, 90];
Para_mode.didtmode      = [10, 90, 80, 20];
Para_mode.DuiguanMARK   = [0, 0];
Para_mode.DuiguanCH     = [0, 0];
Para_mode.Fuzaimode     = 0;
Para_mode.INTG_I2t      = 0;
Para_mode.I_Fix         = [1, 1];
Para_mode.I_meature     = "Id";
Para_mode.gate_didt     = [3,30];
Para_mode.gate_Erec     = 30;
Para_mode.Vgeth         = 3;

% --- 第一部分：计算时延 ---
Full_title = {'脉宽长(us)', '  CSV  ', 'Ic(A)', 'Icfix(A)', 'Idfix(A)' ,'Icmax(A)', 'Eon(mJ)', 'Eoff(mJ)', 'VceMAX(V)', 'VdMAX(V)', 'Vcetop(V)', 'dv/dton(V/us)', 'dv/dtoff(V/us)', 'di/dton(A/us)','di/dtoff(A/us)', 'Erec(mJ)', 'Prrmax(kW)', 'PrrPROMAX(kW)', 'Vgetop(V)','Vgebase(V)','Tdon(ns)', 'Trise(ns)', 'Tdoff(ns)', 'Tfall(ns)', 'I2dt_on','I2dt_off','Vgedg1max(V)', 'Vgedg1min(V)', 'Vgedg1mean(V)', 'Vgedg2max(V)', 'Vgedg2min(V)', 'Vgedg2mean(V)','I_Fuizai_on','I_Fuizai_off','Ton0', 'Toff0','Ton1', 'Toff1','Ton2', 'Toff2','T_Vcemax','T_Vdmax','Tdvdt_fs','Tdvdt_fe','Tdvdt_rs','Tdvdt_re','Tdidt_rs','Tdidt_re','Tdidt_fs','Tdidt_fe'};
title = Full_title;

dpiValue = winqueryreg('HKEY_CURRENT_USER', 'Control Panel\Desktop\WindowMetrics', 'AppliedDPI');
dpiValue = double(dpiValue);
DPI = dpiValue/96;

num = '000';
Out_name = [dataname, '.csv'];

% --- 计算文件 1 时延 ---
[~,output_backup] = countE(filename_1, num, Output_Path, dataname, DPI, title, Full_title, Para_mode);
idx1 = strcmp(Full_title, target_1);
Time_fix_1 = output_backup(idx1);

% --- 计算文件 2 时延 ---
[~,output_backup] = countE(filename_2, num, Output_Path, dataname, DPI, title, Full_title, Para_mode);
idx2 = strcmp(Full_title, target_2);
Time_fix_2 = output_backup(idx2);

disp(['时延计算完成 - 文件1: ', num2str(Time_fix_1*1e6), ' us']);
disp(['时延计算完成 - 文件2: ', num2str(Time_fix_2*1e6), ' us']);

% --- 第三部分：读取与对齐 ---
CSV_1 = readtable(filename_1, 'NumHeaderLines', 20);
CSV_2 = readtable(filename_2, 'NumHeaderLines', 20);

% 提取时间并应用时延校正（保持为数值秒）
Time_1 = double(CSV_1{:, 1}) - Time_fix_1;
Time_2 = double(CSV_2{:, 1}) - Time_fix_2;

% 确保时间列为列向量
Time_1 = Time_1(:);
Time_2 = Time_2(:);

% --- 4. 确定统一的时间轴范围 ---
t_start = min([Time_1(1), Time_2(1)]);
t_end   = max([Time_1(end), Time_2(end)]);

% --- 5. 确定最大采样率 ---
dt1 = mean(diff(Time_1));
dt2 = mean(diff(Time_2));
dt_min = min(dt1, dt2); % 取精度最高的间隔

% 生成统一的高精度时间轴
t_uniform = (t_start : dt_min : t_end)';

% --- 6. 数据插值对齐 ---
data1 = double(CSV_1{:, 2:end});
data2 = double(CSV_2{:, 2:end});

% 预分配插值结果数组
numPoints = length(t_uniform);
numCols1 = size(data1, 2);
numCols2 = size(data2, 2);

% 提取数据列
data1_interp = zeros(numPoints, numCols1);
data2_interp = zeros(numPoints, numCols2);

% 对每个数据列进行插值
for i = 1:numCols1
    data1_interp(:, i) = interp1(Time_1, data1(:, i), t_uniform, 'nearest', 'extrap');
end

for i = 1:numCols2
    data2_interp(:, i) = interp1(Time_2, data2(:, i), t_uniform, 'nearest', 'extrap');
end

% --- 7. 准备输出 ---
New_VarNames_1 = VarNames_CSV1 + "-" + Back_name_1;
New_VarNames_2 = VarNames_CSV2 + "-" + Back_name_2;

% 将插值后的矩阵转换为表格（自动处理多列）
data1_table = array2table(data1_interp, 'VariableNames', New_VarNames_1);
data2_table = array2table(data2_interp, 'VariableNames', New_VarNames_2);

% 创建包含时间轴和数据的完整表格
t_table = table(t_uniform, 'VariableNames', {'Time_s'});

% 水平拼接表格
T_out = [t_table, data1_table, data2_table];

% --- 8. 写入文件 ---
OutFile = fullfile(Output_Path, Out_name);

HeaderLines = {    Title_1;    Title_2;    Title_3;    Title_4;};

close all

writecell(HeaderLines, OutFile, 'Delimiter', 'comma', 'Encoding', 'GBK');

writetable(T_out, OutFile, ...
    'WriteMode', 'append', ...      % 追加模式
    'WriteVariableNames', true, ... % 写入变量名（作为第 5 行）
    'Delimiter', 'comma', ...
    'Encoding', 'GBK');

fprintf('\n数据对齐完成 %s 已生成\n', Out_name);
winopen(Output_Path);
function main(Para_file,Para_mode,Para_out,Prra_draw)
% 编码修改为UTF-8
feature('DefaultCharacterSet','UTF8');
% 代码版本号
Ver = "V2.4.0";
% 运行开始提示
fprintf('开始读取\n\n');
fprintf('代码版本: %s\n\n', Ver);

%% 初始化参数配置
% 文件路径配置参数
location    = Para_file.location ;      %% 路径
tablename   = Para_file.tablename;      %% csv文件名
Dataname    = Para_file.dataname ;      %% 数据标签
datstart    = Para_file.datstart ;      %% csv文件序号起始点
datnum      = Para_file.datnum   ;      %% csv文件序号组数
datend      = datstart + datnum-1;      %% csv文件序号终止点

% 模式配置参数
Chmode      = Para_mode.Chmode   ;      %% 通道分配模式
Ch_labels   = Para_mode.Ch_labels;      %% 通道分配
Smooth_Win  = Para_mode.Smooth_Win;     %% 通道滤波窗口长度
Eonmode     = Para_mode.Eonmode;        %% 开通损耗配置
Eoffmode    = Para_mode.Eoffmode;       %% 关断损耗配置
dvdtmode    = Para_mode.dvdtmode ;      %% dvdt模式
didtmode    = Para_mode.didtmode ;      %% didt模式
Fuzaimode   = Para_mode.Fuzaimode;      %% 负载电流模式
INTG_I2t    = Para_mode.INTG_I2t;       %% 对电动电流的I2t积分计算
DuiguanMARK = Para_mode.DuiguanMARK;    %% 对管门极监测标记
DuiguanCH   = Para_mode.DuiguanCH;      %% 对管门极监测对应通道
I_Fix       = Para_mode.I_Fix;          %% 是否对电流进行校正     1-校正 0-不校正
I_meature   = Para_mode.I_meature;      %% 以Ic或Id计算的实际测试电流值
gate_didt   = Para_mode.gate_didt;      %% didt上升沿检测允许回落阈值
gate_Erec   = Para_mode.gate_Erec;      %% Erec下降沿检测允许抬升阈值
Vgeth       = Para_mode.Vgeth    ;      %% 门极开关门槛值 依据器件手册提供 一般为0
NameStyle   = Para_mode.NameStyle;      %% 文件命名风格     横河 或 泰克

% 输出数据配置
titlemode   = Para_out.titlemode;
title_Manual= Para_out.title_Manual;

% 绘图配置参数
Vmax      =  Prra_draw.Vmax     ;       %% 器件最大耐压值
Drawflag  =  Prra_draw.Drawflag ;       %% 是否需要绘图分析

%% 文件夹建立
path=location;
[~,Floder,~] = fileparts(location);
dataname = [num2str(datstart, '%03d'), '-', Dataname];
clipboard('copy', dataname);

if ~exist(strcat(path,'\result\'), 'dir')  % 存在性检测方法
    try
        mkdir(strcat(path,'\result\'));
        fprintf('成功创建: %s\n\n', strcat(path,'\result\'));
    catch ME
        error('路径创建失败: %s\n错误信息: %s', strcat(path,'\result\'), ME.message);
    end
end

Eonmode_Str = [num2str(Eonmode(1)),num2str(Eonmode(2)),num2str(Eonmode(3)),num2str(Eonmode(4))];
Eoffmode_Str = [num2str(Eoffmode(1)),num2str(Eoffmode(2)),num2str(Eoffmode(3)),num2str(Eoffmode(4))];
%% 表头设定
datetime = datestr(now, 'yyyymmdd');
time = datestr(now, 'HH:MM:SS');

Paratable1 = {'代码版本', '日期', '时间', '文件夹', '器件', '起始数', '总数', '终点数'};
Paradata1 = {Ver,datetime,time,Floder,tablename,num2str(datstart),num2str(datnum),num2str(datend)};

Paratable2 = {'通道设置', '通道分配', '滤波窗口', 'Eon模式', 'Eoff模式', 'dvdt模式', 'didt模式', '对管标记', '对管通道'};
Paradata2 = {num2str(Chmode), num2str(Ch_labels), num2str(Smooth_Win), Eonmode_Str, Eoffmode_Str,num2str(dvdtmode), num2str(didtmode), num2str(DuiguanMARK),num2str(DuiguanCH)};

Paratable3 = {'负载电流','Irms模式','电流校准','电流采信','didt阈值', 'Erec阈值', '门极阈值', '芯片耐压', '整体绘图'};
Paradata3 = {num2str(Fuzaimode),num2str(INTG_I2t),num2str(I_Fix),I_meature,num2str(gate_didt), num2str(gate_Erec), num2str(Vgeth), num2str(Vmax), num2str(Drawflag)};

titleMap = containers.Map;
Full_title = {'脉宽长(us)', '  CSV  ', 'Ic(A)', 'Icmax(A)', 'Eon(mJ)', 'Eoff(mJ)', 'VceMAX(V)', 'VdMAX(V)', 'Vcetop(V)', 'dv/dton(V/us)', 'dv/dtoff(V/us)', 'di/dton(A/us)','di/dtoff(A/us)', 'Erec(mJ)', 'Prrmax(kW)', 'PrrPROMAX(kW)', 'Vgetop(V)','Vgebase(V)','Tdon(ns)', 'Trise(ns)', 'Tdoff(ns)', 'Tfall(ns)', 'I2dt_on','I2dt_off','Vgedg1max(V)', 'Vgedg1min(V)', 'Vgedg1mean(V)', 'Vgedg2max(V)', 'Vgedg2min(V)', 'Vgedg2mean(V)'};
titleMap('Standard') = {'脉宽长(us)', '  CSV  ', 'Ic(A)', 'Eon(mJ)', 'Eoff(mJ)', 'VceMAX(V)', 'VdMAX(V)', 'Vcetop(V)', 'dv/dton(V/us)', 'dv/dtoff(V/us)', 'di/dton(A/us)', 'di/dtoff(A/us)', 'Erec(mJ)', 'Prrmax(kW)', 'Tdon(ns)', 'Tdoff(ns)', 'Vgedg1max(V)', 'Vgedg1min(V)', 'Vgedg1mean(V)','    ','    ','    ','    ','    ','    ','    '};
titleMap('2Duiguan') = {'脉宽长(us)', '  CSV  ', 'Ic(A)', 'Eon(mJ)', 'Eoff(mJ)', 'VceMAX(V)', 'Vcetop(V)', 'dv/dtoff(V/us)', 'di/dton(A/us)', 'Tdon(ns)', 'Tdoff(ns)', 'Vgedg1max(V)', 'Vgedg1min(V)', 'Vgedg1mean(V)', 'Vgedg2max(V)', 'Vgedg2min(V)', 'Vgedg2mean(V)','    ','    ','    ','    ','    '};
titleMap('Manual') = title_Manual;
titleMap('Full') = Full_title;
defaultMode = 'Full';
% 检查 titlemode 是否是 titleMap 的键
if titleMap.isKey(titlemode)
    title = titleMap(titlemode);
else
    fprintf('表头定义:\n')
    fprintf('       titlemode "%s" 无效，已使用默认模式 "%s"\n' , titlemode, defaultMode); % 输出
    title = titleMap(defaultMode);
end

dpiValue = winqueryreg('HKEY_CURRENT_USER', 'Control Panel\Desktop\WindowMetrics', 'AppliedDPI');
dpiValue = double(dpiValue);
DPI = dpiValue/96;

Data_num = length(title);
%% 数据读取与计算
cnt=1;
data1=zeros(datend-datstart+1,Data_num);
data_backup=zeros(datend-datstart+1,length(titleMap('Full')));

EndFile = (fullfile(location, [tablename, '_', num2str(datend, '%03d'), '_ALL.csv']));
if ~exist(EndFile,'file') % 存在性检测方法
    fprintf('未找到%s文件 请检查文件数量和输入参数\n', EndFile);
    error('文件数量错误')
end

for tablenum=datstart:datend
    % 拼接名称
    num = num2str(tablenum, '%03d');
    switch NameStyle
        case '横河'
            filename = fullfile(location, [tablename, num, '_00000.csv']);        % 修正路径拼接
        case '泰克'
            filename = fullfile(location, [tablename, '_', num, '_ALL.csv']);     % 修正路径拼接
        otherwise
            error('未识别的文件命名风格 请检查NameStyle参数 仅支持 横河 、 泰克 两种');
    end
    
    [data1(cnt,:),data_backup(cnt,:)]=countE(filename,num,location,dataname,DPI,title,Full_title,Para_mode);
    cnt=cnt+1;
end
% 表头修正
title_fix = strrep(title    , 'Vgedg1max(V)', ['VgemaxT',num2str(DuiguanMARK(1)),'(V)']);
title_fix = strrep(title_fix, 'Vgedg1min(V)', ['VgeminT',num2str(DuiguanMARK(1)),'(V)']);
title_fix = strrep(title_fix, 'Vgedg1mean(V)',['VgemeanT',num2str(DuiguanMARK(1)),'(V)']);
title_fix = strrep(title_fix, 'Vgedg2max(V)', ['VgemaxT',num2str(DuiguanMARK(2)),'(V)']);
title_fix = strrep(title_fix, 'Vgedg2min(V)', ['VgeminT',num2str(DuiguanMARK(2)),'(V)']);
title_fix = strrep(title_fix, 'Vgedg2mean(V)',['VgemeanT',num2str(DuiguanMARK(2)),'(V)']);


%% 数据写入
totalRows = 10 + size(data1, 1);
% 总列数: 取所有单元格数组和数值矩阵中最大的列数
maxCols = max([length(Paratable1), length(Paradata1), ...
    length(Paratable2), length(Paradata2), ...
    length(Paratable3), length(Paradata3), ...
    length(title), size(data1, 2), size(data_backup, 2)]);

% 创建一个足够大的空单元格数组，用于存放所有数据
combinedCell = cell(totalRows, maxCols);

% 将数据按原布局依次放入 combinedCell 的指定行
combinedCell(1, 1:length(Paratable1)) = Paratable1; % A1
combinedCell(2, 1:length(Paradata1)) = Paradata1;   % A2
combinedCell(3, 1:length(Paratable2)) = Paratable2; % A3
combinedCell(4, 1:length(Paradata2)) = Paradata2;    % A4
combinedCell(5, 1:length(Paratable3)) = Paratable3;  % A5
combinedCell(6, 1:length(Paradata3)) = Paradata3;    % A6
% 第7,8,9行保持为空 (A7-A9)
combinedCell(10, 1:length(title)) = title_fix;          % A10
% 将数值矩阵 data1 转换为单元格数组，并放入第11行及后续行
combinedCell(11:size(data1,1)+10, 1:size(data1,2)) = num2cell(data1); % A11开始

combinedCell(21+datnum, 1:length(titleMap('Full'))) = titleMap('Full');
combinedCell(22+datnum:size(data_backup,1)+21+datnum, 1:size(data_backup,2)) = num2cell(data_backup);

% 使用 writecell 一次性写入整个单元格数组到
% ouput_table = dataname ;      %% 输出文件名
% outputtable=strcat([path,'\result\',ouput_table,'.xlsx']);
% writecell(combinedCell, outputtable, 'Sheet', dataname, 'Range', 'A1', 'UseExcel', false);
outputtable_backup = strcat([path,'\result\',dataname,'\',dataname,'.xlsx']);
writecell(combinedCell, outputtable_backup, 'Sheet', dataname, 'Range', 'A1', 'UseExcel', false);

%% 复制参数表到文件路径
% 获取调用堆栈信息
stack = dbstack('-completenames');

% 检查堆栈深度，确保有调用者
if length(stack) < 2
    warning('未在函数调用环境中执行，无法复制调用文件。');
    return;
end

% stack(1) 是当前函数（yourFunction）本身
% stack(2) 是调用当前函数的文件（调用者）的信息
callerInfo = stack(2);
callerFullPath = callerInfo.file; % 调用者文件的完整路径

% 指定目标目录 - 请修改为你的实际路径，例如 'D:\Backups\'
targetDirectory = strcat([path,'\result\',dataname]);

% 确保目标目录存在
if ~exist(targetDirectory, 'dir')
    mkdir(targetDirectory);
end

% 从完整路径中获取调用者的文件名和扩展名
[~, callerName, callerExt] = fileparts(callerFullPath);

% (可选)生成时间戳字符串 (格式: 年月日_时分秒)
% timeStamp = datestr(now, 'yyyymmdd_HHMMSS');
% 构建新文件名 (可选: 原文件名_时间戳.扩展名)
% newFileName = [callerName, '_', timeStamp, callerExt]; % 包含时间戳
newFileName = [callerName, callerExt]; % 不包含时间戳

% 构建新文件的完整保存路径
newFileFullPath = fullfile(targetDirectory, newFileName);

% 执行复制操作
[copySuccess, message] = copyfile(callerFullPath, newFileFullPath);

% 检查复制操作是否成功
if copySuccess
    fprintf('调用文件已成功复制至: %s\n\n', newFileFullPath);
else
    warning('文件复制失败: %s', message);
end

%% 绘图
if(Drawflag)
    draw(data1,dataname,path,Ch_labels(5),Vmax);
end

%% 曲线拟合

% fit_Eon=polyfit(data1(:,2),data1(:,2),5);
% fit_Eoff=polyfit(data1(:,2),data1(:,3),5);
% fit_Erec=polyfit(data1(:,2),data1(:,9),5);
% writematrix("5阶拟合结果",[path,'\result\fitans.xlsx'],'sheet',dataname,'range','A1','UseExcel',0);
% writematrix(["K5","K4","K3","K2","K1","K0"],[path,'\result\fitans.xlsx'],'sheet',dataname,'range','B1');
% writematrix("Eon拟合结果",[path,'\result\fitans.xlsx'],'sheet',dataname,'range','A2');
% writematrix("Eoff拟合结果",[path,'\result\fitans.xlsx'],'sheet',dataname,'range','A3');
% writematrix("Erec拟合结果",[path,'\result\fitans.xlsx'],'sheet',dataname,'range','A4');
% writematrix(fit_Eon,[path,'\result\fitans.xlsx'],'sheet',dataname,'range','B2');
% writematrix(fit_Eoff,[path,'\result\fitans.xlsx'],'sheet',dataname,'range','B3');
% writematrix(fit_Erec,[path,'\result\fitans.xlsx'],'sheet',dataname,'range','B4');

%% 状态完成提示
% 关闭所有图像
allFigs = findall(0, 'Type', 'figure');
if ~isempty(allFigs)
    close(allFigs);
end
fprintf('数据读取完成');
winopen(strcat([path,'\result\',dataname]));
% system(['explorer.exe ',strrep(strcat([path,'\result\',dataname]), '/', '\')]);
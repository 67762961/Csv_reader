function main(Para_file,Para_mode,Para_data,Para_out,Prra_draw)

Ver = "V2.2.1";

fprintf('开始读取\n\n')

%% 初始化参数配置
% 文件路径配置参数
ouput_table = '数据读取结果.xlsx' ;      %% 输出文件名
location    = Para_file.location ;      %% 路径
tablename   = Para_file.tablename;      %% csv文件名
Dataname    = Para_file.dataname ;      %% 数据标签
datstart    = Para_file.datstart ;      %% csv文件序号起始点
datnum      = Para_file.datnum   ;      %% csv文件序号组数
datend      = datstart + datnum-1;      %% csv文件序号终止点

% 模式配置参
% nspd       = Para_mode.nspd     ;       %% csv采样率 ns per dot
Chmode      = Para_mode.Chmode   ;       %% 通道分配模式
Ch_labels   = Para_mode.Ch_labels;       %% 通道分配
Smooth_Win  = Para_mode.Smooth_Win;      %% 通道滤波窗口长度
dvdtmode    = Para_mode.dvdtmode ;       %% dvdt模式
didtmode    = Para_mode.didtmode ;       %% didt模式
Fuzaimode   = Para_mode.Fuzaimode;
DuiguanMARK = Para_mode.DuiguanMARK;
DuiguanCH   = Para_mode.DuiguanCH;
% Dflag      = Para_mode.Dflag    ;       %% 是否有二极管反向恢复测试
Drawflag    = Para_mode.Drawflag ;       %% 是否需要绘图分析

% 数据配置
gate_didt  = Para_data.gate_didt;       %% didt上升沿检测允许回落阈值
gate_Erec  = Para_data.gate_Erec;       %% Erec下降沿检测允许抬升阈值

% 输出数据配置
titlemode   = Para_out.titlemode;
title_Manual= Para_out.title_Manual;

% 绘图配置参
Vgeth     =  Prra_draw.Vgeth    ;       %% 门极开关门槛值 依据器件手册提供 一般为0
Vmax      =  Prra_draw.Vmax     ;       %% 器件最大耐压值

%% 文件夹建立
path=location;
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

%% 表头设定
outputtable=strcat([path,'\result\',ouput_table]);
datetime = datestr(now, 'yyyymmdd');
time = datestr(now, 'HH:MM:SS');

Paratable1 = {'代码版本', '日期', '时间', '路径', '器件', '起始数', '总数', '终点数'};
Paradata1 = {Ver,datetime,time,location,tablename,num2str(datstart),num2str(datnum),num2str(datend)};

Paratable2 = {'通道设置', '通道分配', '滤波窗口', 'dvdt模式', 'didt模式', '对管标记', '对管通道', '负载电流'};
Paradata2 = {num2str(Chmode), num2str(Ch_labels), num2str(Smooth_Win), num2str(dvdtmode), num2str(didtmode), num2str(DuiguanMARK),num2str(DuiguanCH), num2str(Fuzaimode)};

Paratable3 = {'didt阈值', 'Erec阈值', '门极阈值', '芯片耐压', '整体绘图'};
Paradata3 = {num2str(gate_didt), num2str(gate_Erec), num2str(Vgeth), num2str(Vmax), num2str(Drawflag)};

titleMap = containers.Map;
titleMap('Full') = {'脉宽长(us)', '  CSV  ', 'Ic(A)', 'Icmax(A)', 'Eon(mJ)', 'Eoff(mJ)', 'VceMAX(V)', 'VdMAX(V)', 'Vcetop(V)', 'dv/dt(V/us)', 'di/dt(A/us)', 'Erec(mJ)', 'Prrmax(kW)', 'PrrPROMAX(kW)', 'Vgedg1max(V)', 'Vgedg1min(V)', 'Vgedg1mean(V)', 'Vgedg2max(V)', 'Vgedg2min(V)', 'Vgedg2mean(V)', 'Tdon(ns)', 'Trise(ns)', 'Tdoff(ns)', 'Tfall(ns)'};
titleMap('Standard') = {'脉宽长(us)', '  CSV  ', 'Ic(A)', 'Eon(mJ)', 'Eoff(mJ)', 'VceMAX(V)', 'VdMAX(V)', 'Vcetop(V)', 'dv/dt(V/us)', 'di/dt(A/us)', 'Erec(mJ)', 'Prrmax(kW)', 'Vgedg1max(V)', 'Vgedg1min(V)',  'Tdon(ns)', 'Tdoff(ns)','    ','    ','    ','    ','    ','    ','    ','    '};
titleMap('2Duiguan') = {'脉宽长(us)', '  CSV  ', 'Ic(A)', 'Icmax(A)', 'Eon(mJ)', 'Eoff(mJ)', 'VceMAX(V)', 'Vcetop(V)', 'dv/dt(V/us)', 'di/dt(A/us)', 'Tdon(ns)', 'Tdoff(ns)', 'Vgedg1max(V)', 'Vgedg1min(V)', 'Vgedg1mean(V)', 'Vgedg2max(V)', 'Vgedg2min(V)', 'Vgedg2mean(V)','    ','    ','    ','    ','    ','    '};
titleMap('Manual') = title_Manual;

defaultMode = 'Full';
% 检查 titlemode 是否是 titleMap 的键
if titleMap.isKey(titlemode)
    title = titleMap(titlemode);
else
    fprintf('表头定义:\n')
    fprintf('       titlemode "%s" 无效，已使用默认模式 "%s"\n' , titlemode, defaultMode); % 输出
    title = titleMap(defaultMode);
end

Data_num    = length(title);
%% 数据读取与计算
cnt=1;
data1=zeros(datend-datstart+1,Data_num);
for tablenum=datstart:datend
    data1(cnt,:)=countE(location,tablename,tablenum,location,dataname,title,Chmode,dvdtmode,didtmode,DuiguanCH,Fuzaimode,Ch_labels,Vgeth,gate_didt,gate_Erec,Smooth_Win);
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
    length(title), size(data1, 2)]);

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

% 使用 writecell 一次性写入整个单元格数组到Excel[1,3,6](@ref)
outputtable_backup = strcat([path,'\pic\',dataname,'\',dataname,'.xlsx']);
writecell(combinedCell, outputtable, 'Sheet', dataname, 'Range', 'A1', 'UseExcel', false);
writecell(combinedCell, outputtable_backup, 'Sheet', dataname, 'Range', 'A1', 'UseExcel', false);

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
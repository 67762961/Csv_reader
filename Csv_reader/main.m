function main(Para_file,Para_mode,Para_data,Prra_draw)

fprintf('开始读取\n\n')

%% 初始化参数配置
% 文件路径配置参数
ouput_table = '数据读取结果.xlsx' ;      %% 输出文件名
location    = Para_file.location ;      %% 路径
tablename   = Para_file.tablename;      %% csv文件名   
dataname    = Para_file.dataname ;      %% 数据标签 
datstart    = Para_file.datstart ;      %% csv文件序号起始点  
datnum      = Para_file.datnum   ;      %% csv文件序号组数
datend      = datstart + datnum-1;      %% csv文件序号终止点

% 模式配置参
nspd       = Para_mode.nspd     ;       %% csv采样率 ns per dot
Chmode     = Para_mode.Chmode   ;       %% 通道分配模式
Ch_labels  = Para_mode.Ch_labels;       %% 通道分配
Smooth_Win = Para_mode.Smooth_Win;      %% 通道滤波窗口长度
dvdtmode   = Para_mode.dvdtmode ;       %% dvdt模式
didtmode   = Para_mode.didtmode ;       %% didt模式
Dflag      = Para_mode.Dflag    ;       %% 是否有二极管反向恢复测试
Drawflag   = Para_mode.Drawflag ;       %% 是否需要绘图分析

% 数据配置
gate_didt  = Para_data.gate_didt;       %% didt上升沿检测允许回落阈值
gate_Erec  = Para_data.gate_Erec;       %% Erec下降沿检测允许抬升阈值

% 绘图配置参
Vgeth     =  Prra_draw.Vgeth    ;       %% 门极开关门槛值 依据器件手册提供 一般为0
Vmax      =  Prra_draw.Vmax     ;       %% 器件最大耐压值

path=location;
dataname = [num2str(datstart, '%03d'), '-', dataname];
clipboard('copy', dataname);

% 定义基础路径结构
if(Drawflag)
    subfolders = {'Eigbt';'dvdt';'didt';'Vce';'Vd';'Ton';'Toff';'Draw';'Prr'};
    folders_length = length(subfolders) - 1 + Dflag;
else
    subfolders = {'Eigbt';'dvdt';'didt';'Vce';'Vd';'Ton';'Toff';'Prr'};
    folders_length = length(subfolders) - 1 + Dflag;
end

% 批量创建路径
for i = 1:folders_length
    target_path = fullfile(path, 'pic', dataname, subfolders{i});
    if ~exist(target_path, 'dir')  % 存在性检测方法
        try
            mkdir(target_path);    % MATLAB自动创建多级目录
            fprintf('成功创建: %s\n', target_path);
        catch ME
            error('路径创建失败: %s\n错误信息: %s', target_path, ME.message);
        end
    end
end

if ~exist(strcat(path,'\result\'), 'dir')  % 存在性检测方法
    try
        mkdir(strcat(path,'\result\'));
        fprintf('成功创建: %s\n', strcat(path,'\result\'));
    catch ME
        error('路径创建失败: %s\n错误信息: %s', strcat(path,'\result\'), ME.message);
    end
end

%% 表头设定
outputtable=strcat([path,'\result\',ouput_table]);

datetime = datestr(now, 'yyyymmdd');
Paratable1 = char(["日期","路径","器件","表名","起始数","总数","终点数"]);
Paratable2 = char(["采样率","通道设置","通道分配","滤波窗口","dvdt模式","didt模式","二极管分析","画图分析"]);
Paratable3 = char(["didt阈值","Erec阈值","门极阈值","芯片耐压"]);
writematrix(Paratable1,outputtable,'sheet',dataname,'range','A1','UseExcel',0)
writematrix(Paratable2,outputtable,'sheet',dataname,'range','A3','UseExcel',0)
writematrix(Paratable3,outputtable,'sheet',dataname,'range','A5','UseExcel',0)

Para1 = [datstart,datnum,datend];
writematrix(datetime,outputtable,'sheet',dataname,'range','A2','UseExcel',0)
writematrix(location,outputtable,'sheet',dataname,'range','B2','UseExcel',0)
writematrix(tablename,outputtable,'sheet',dataname,'range','C2','UseExcel',0)
writematrix(dataname,outputtable,'sheet',dataname,'range','D2','UseExcel',0)
writematrix(Para1,outputtable,'sheet',dataname,'range','E2','UseExcel',0)

Para2 = [Dflag,Drawflag];
writematrix(nspd,outputtable,'sheet',dataname,'range','A4','UseExcel',0)
writematrix(num2str(Chmode),outputtable,'sheet',dataname,'range','B4','UseExcel',0)
writematrix(num2str(Ch_labels),outputtable,'sheet',dataname,'range','C4','UseExcel',0)
writematrix(num2str(Smooth_Win),outputtable,'sheet',dataname,'range','D4','UseExcel',0)
writematrix(num2str(dvdtmode),outputtable,'sheet',dataname,'range','E4','UseExcel',0)
writematrix(num2str(didtmode),outputtable,'sheet',dataname,'range','F4','UseExcel',0)
writematrix(Para2,outputtable,'sheet',dataname,'range','G4','UseExcel',0)

Para3 = [gate_didt,gate_Erec,Vgeth,Vmax];
writematrix(Para3,outputtable,'sheet',dataname,'range','A6','UseExcel',0)

title=char(["Ic(A)","Eon(mJ)","Eoff(mJ)","VceMAX(V)","VdMAX(V)","dv/dt(V/us)","di/dt(A/us)","Vcetop(V)","Erec(mJ)","Prrmax(kW)","T(d)on(ns)", ...
    "T-rise(ns)","Ton(ns)","T(d)off(ns)","T-fall(ns)","Toff(ns)"]);  %%定义表头
writematrix(title,outputtable,'sheet',dataname,'range','A10','UseExcel',0)

%% 数据读取与写入
cnt=1;
data1=zeros(datend-datstart+1,16);
for tablenum=datstart:datend
    data1(cnt,:)=countE(location,tablename,tablenum,nspd,location,dataname,Chmode,dvdtmode,didtmode,Ch_labels,Vgeth,gate_didt,gate_Erec,Dflag,Smooth_Win);
    cnt=cnt+1;
end
writematrix(data1,outputtable,'sheet',dataname,'range','A11');

%% 绘图
if(Drawflag)
    draw(data1,dataname,path,Dflag,Vmax);
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
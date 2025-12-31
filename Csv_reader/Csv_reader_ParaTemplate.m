%% 初始化
clear;
clc;

%% 参数配置
Para_file.location   = 'D:\_TOOLS\Csv_reader_TestLib\20250805';     %% 读取文件夹       文件夹以八位日期命名
Para_file.tablename  = 'INVC';                                      %% csv文件名        一般为BOOSTH(L) 或 INVA(BC)
Para_file.dataname   = '赤霄-CT2-1150V-33nF';                       %% 输出数据标签     (机型)-(器件)-(温度)-(电压)-(Ron)-(Roff)
Para_file.datstart   = 180;                                         %% csv序号起始点    该工况的首个CSV文件序号
Para_file.datnum     = 16;                                          %% 本组csv文件      该工况一共测试组数 BOOST 12 INV 16

% 模式配置参数
Para_mode.Chmode        = 'setch';                                     %% 通道分配模式     'setch'或'findch'
Para_mode.Ch_labels     = [1, 2, 3, 4, 5];                             %% 通道分配         Vge Vce Ic Vd Id对应通道
Para_mode.Smooth_Win    = [1, 1, 1, 1, 1];                             %% 通道滤波窗口长度 Vge Vce Ic Vd Id对应数据滤波参数
Para_mode.Eonmode       = [0.1, 0.02, 0.2, 0];                         %% 开通损耗配置
Para_mode.Eoffmode      = [0.1, 0.02, 0.2, 0];                         %% 关断损耗配置
Para_mode.dvdtmode      = [80, 20, 10, 90];                            %% dvdt模式选择     额外的dvdt计算起始和结束百分比
Para_mode.didtmode      = [10, 90, 80, 20];                            %% didt模式选择     新设定didt计算起始和结束百分比
Para_mode.DuiguanMARK   = [5, 0];                                      %% 对管门极监测标记 最多两个通道
Para_mode.DuiguanCH     = [6, 0];                                      %% 对管门极监测对应通道
Para_mode.Fuzaimode     = 0;                                           %% 负载电流模式     开启后将只读取尖峰数据 Ic通道处填负载电流通道
Para_mode.Drawflag      = 0;                                           %% 是否需要绘图分析
Para_mode.I_Fix         = [1, 1];                                      %% 是否对电流进行校正     1-校正 0-不校正
Para_mode.I_meature     = "Ic";                                        %% 以Ic或Id计算的实际测试电流值

% 数据配置参数
Para_data.gate_didt  = [3,15];                                         %% didt回落容错     didt计算中上升沿过滤毛刺阈值
Para_data.gate_Erec  = 20;                                             %% Erec抬升容错     Erec计算中下降沿过滤毛刺阈值

% 输出数据配置
Para_out.titlemode = 'Standard';                                          %% Full Standard 2Duiguan Manual
Para_out.title_Manual = {'脉宽长(us)', '  CSV  ', 'Ic(A)', 'Eon(mJ)', 'Eoff(mJ)', 'VceMAX(V)', 'VdMAX(V)', 'Vcetop(V)', 'dv/dt(V/us)', 'di/dton(A/us)', 'Erec(mJ)', 'Prrmax(kW)', 'Tdon(ns)', 'Tdoff(ns)', 'Vgedg1max(V)', 'Vgedg1min(V)', '    ','    ','    '};

% 绘图配置参数
Prra_draw.Vgeth      = 3;                                           %% 门极开关阈值     Vge开通阈值 器件手册提供 一般为0
Prra_draw.Vmax       = 1350 ;                                       %% IGBT极限电压     Vce最大耐压值 器件手册提供

%% 主函数运行
main(Para_file,Para_mode,Para_data,Para_out,Prra_draw)
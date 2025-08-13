%% 初次拉取后将本文件直接复制到 Csv_reader.m 中

%% 初始化
clear;
clc;

%% 参数配置
Para_file.location   = 'D:\_TOOLS\Csv_reader\TestLib\20250805';     %% 读取文件夹       文件夹以八位日期命名
Para_file.tablename  = 'INVC';                                      %% csv文件名        一般为BOOSTH(L) 或 INVA(BC)
Para_file.dataname   = '赤霄-CT2-1150V-33nF';                       %% 输出数据标签     (机型)-(器件)-(温度)-(电压)-(Ron)-(Roff)
Para_file.datstart   = 180;                                         %% csv序号起始点    该工况的首个CSV文件序号
Para_file.datnum     = 16;                                          %% 本组csv文件      该工况一共测试组数 BOOST 12 INV 16
    
% 模式配置参数    
Para_mode.nspd       = 1.6;                                         %% csv采样率        CSV保存时示波器设置ns/pt
Para_mode.Chmode     = 'setch';                                     %% 通道分配模式     'setch'或'findch'
Para_mode.Ch_labels  = [1, 2, 3, 4, 5, 6];                          %% 通道分配         Vge Vce Ic Vd Id对应通道
Para_mode.Smooth_Win = [1, 1, 1, 1, 1, 1];                          %% 通道滤波窗口长度 Vge Vce Ic Vd Id对应数据滤波参数
Para_mode.dvdtmode   = [10, 90];                                    %% dvdt模式选择     额外的dvdt计算起始和结束百分比
Para_mode.didtmode   = [10, 90];                                    %% didt模式选择     新设定didt计算起始和结束百分比
Para_mode.Drawflag   = 0;                                           %% 是否需要绘图分析
% Para_mode.Dflag      = 1;                                         %% 二极管反向恢复   (已经于2.0.3版本弃用)
    
% 数据配置参数    
Para_data.gate_didt  = 3;                                           %% didt回落容错     didt计算中上升沿过滤毛刺阈值
Para_data.gate_Erec  = 20;                                          %% Erec抬升容错     Erec计算中下降沿过滤毛刺阈值
    
% 绘图配置参数
Prra_draw.Vgeth      = 3;                                           %% 门极开关阈值     Vge开通阈值 器件手册提供 一般为0
Prra_draw.Vmax       = 1350 ;                                       %% IGBT极限电压     Vce最大耐压值 器件手册提供

%% 主函数运行
main(Para_file,Para_mode,Para_data,Prra_draw)
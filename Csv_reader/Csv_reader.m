%% 初始化
clear;
clc;

%% 参数配置
Para_file.location   = uigetdir();                           %% 数据读取文件夹
Para_file.location   = 'E:\20250409';                        %% 直接复制路径
Para_file.tablename  = 'INVA';                               %% csv文件名        
Para_file.dataname   = '320全斯达-AT4-高温-600-2.0-9.4';     %% 数据标签
Para_file.datstart   = 48;                                   %% csv文件序号起始点
Para_file.datnum     = 16;                                   %% 本组csv文件
    
% 模式配置参数    
Para_mode.nspd       = 1.6;                                  %% csv采样率 ns per dot
Para_mode.Chmode     = 'setch';                              %% 通道分配模式
Para_mode.Ch_labels  = {1, 2, 3, 4, 5};                      %% 通道分配
Para_mode.dvdtmode   = 1;                                    %% dvdt模式
    
% 数据配置参数    
Para_data.gate_didt  = 3;                                    %% didt上升沿检测允许回落阈值
Para_data.gate_Erec  = 10;                                   %% Erec下降沿检测允许抬升阈值
    
% 绘图配置参数    
Prra_draw.Dflag      = 1;                                    %%是否有二极管反向恢复测试
Prra_draw.Vgeth      = 0;                                    %%门极开关门槛值 依据器件手册提供 一般为0
Prra_draw.Vmax       = 1000;   

%% 主函数运行
main(Para_file,Para_mode,Para_data,Prra_draw)
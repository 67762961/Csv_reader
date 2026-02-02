function [data_out] = setch(data_in, Ch_labels, DuiguanCH, Fuzaimode)
% 双脉冲测试信号通道重组函数
%   Inputs:
%       data_in   : N×6 矩阵 (double)
%           原始采集数据矩阵
%       Ch_labels : 1×5 数组 (int)
%           通道索引数组，取值范围[1,5]，定义各物理量的原始通道位置：
%           元素1 - Vge门极电压的原始通道号
%           元素2 - Vce集射极电压的原始通道号
%           元素3 - Ic IGBT电流的原始通道号
%           元素4 - Vd二极管电压的原始通道号
%           元素5 - Id负载电流的原始通道号
%   Outputs:
%       data_out : N×6 矩阵 (double)
%           标准化排列数据矩阵，各列定义符合IEC 60747-9标准：
%           第1列 - 时间轴（直接继承输入）
%           第2列 - 门极驱动电压 Vge (单位：V)
%           第3列 - 集射极电压 Vce (单位：V)
%           第4列 - IGBT导通电流 Ic (单位：A)
%           第5列 - 续流二极管电压 Vd (单位：V)
%           第6列 - 负载回路电流 Id (单位：A)

data_out = zeros(size(data_in));
data_out(:,1) = data_in(:,1);           % 保留时间轴

if(Fuzaimode ~=  0)
    if isempty(data_in(:,abs(Fuzaimode)+1))
        fprintf('参数填写错误\n请仔细检查csv文件第 %d 列是否有数据\n',  abs(Fuzaimode)+1);
        error('参数填写错误');
    end
    data_out(:,10) = data_in(:,abs(Fuzaimode)+1);
end


for j = 1:length(Ch_labels)
    if(Ch_labels(j))
        if isempty(data_in(:,abs(Ch_labels(j))+1))
            fprintf('参数填写错误\n请仔细检查csv文件第 %d 列是否有数据\n',  abs(Ch_labels(j))+1);
            error('参数填写错误');
        else
            data_out(:,j+1) = data_in(:,abs(Ch_labels(j))+1);
        end
    end
end

for j = 1:length(DuiguanCH)
    if(DuiguanCH(j) ~= 0)
        if isempty(data_in(:,DuiguanCH(j)+1))
            fprintf('参数填写错误\n请仔细检查csv文件第 %d 列是否有数据\n', DuiguanCH(j)+1);
            error('参数填写错误');
        else
            data_out(:,6+j) = data_in(:,DuiguanCH(j)+1);
        end
    end
end

signal_labels = ["Vge", "Vce", "Ic", "Vd", "Id"];
fprintf('通道分配结果:\n');
fprintf('    ');
for i = 1:length(Ch_labels)
    if Ch_labels(i) ~= 0
        fprintf('    %s(通道%d)', signal_labels(i), abs(Ch_labels(i)));
    end
    if i >= length(Ch_labels)
        if (Fuzaimode ~= 0)
            fprintf('    %s(通道%d)', "I_fuzai", abs(Fuzaimode));
        end
        if (DuiguanCH(1) ~= 0)
            fprintf('    %s(通道%d)', "Vge_dg", DuiguanCH(1));
        end
        if (DuiguanCH(2) ~= 0)
            fprintf('    %s(通道%d)', "Vge_dg", DuiguanCH(2));
        end
        fprintf('\n');
    end
end
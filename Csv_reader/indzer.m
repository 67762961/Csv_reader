function zer = indzer(Vge, t, min_interval)
%INDZER 检测信号在减去阈值后的零点交叉位置，并控制相邻零点的最小间隔
%   Inputs:
%       Vge : 一维数组 (double)
%           输入信号向量，支持实数信号。
%       t : 标量 (double)
%           阈值，用于偏移信号（Vge = Vge - t）。
%       min_interval : 正整数，可选 (默认600)
%           相邻零点的最小间隔（单位：样本点数），若未指定则默认600。
%   Outputs:
%       zer : 1×N 数组 (double)
%           记录的零点交叉索引位置，按升序排列。


% 参数默认值设置
if nargin < 3
    min_interval = 600;  % 若未输入min_interval，则默认600
end

Vge = Vge - t;          % 信号偏移
len = length(Vge);
zer = zeros(1, len);    % 预分配数组
cnt = 1;                % 零点计数器

% 主循环：遍历信号检测零点交叉
for i = 1:len-1
    % 跳过已检测点后的min_interval个样本
    if cnt > 1 && i <= zer(cnt-1) + min_interval
        continue;
    end
    
    % 检测相邻样本的符号变化（含过零点情况）
    if Vge(i) * Vge(i+1) <= 0
        zer(cnt) = i;    % 记录零点位置
        cnt = cnt + 1;   % 计数器递增
    end
end

% 处理信号末尾可能的零点（当最后一个点正好为0时）
if Vge(end) == 0
    zer(cnt) = len;
    cnt = cnt + 1;
end

% 裁剪未使用的预分配空间
zer = zer(1:cnt-1);
end


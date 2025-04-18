function [Vcetop,Ictop,ton10,toff90,tIcm] = count_Vcetop_Ictop(Vge,ch2,ch3,ton1,toff1,ton2,toff2,cnton1,cntoff1)

%% Vcetop Ictop 计算
% 计算Vge高电平电压（使用中值避免噪声干扰）
vge_high_interval = fix(ton1 + cnton1/4) : fix(toff1 - cnton1/4);
meanVgetop = median(Vge(vge_high_interval)); % 中值滤波

% 寻找关断时Vge=90%的时间点
toff90_indices = find(Vge(toff1:-1:ton1) > 0.9 * meanVgetop, 1, 'first');
toff90 = toff1 - toff90_indices + 1; % 转换为原始索引

% 寻找开通时Vge=10%的时间点
ton10_indices = find(Vge(ton2:toff2) > 0.1 * meanVgetop, 1, 'first');
ton10 = ton2 + ton10_indices - 1;

% 计算Vcetop
start_idx = fix(toff1 + cntoff1/5);         % 起始索引：关断后1/5周期
end_idx = fix(ton2 - 3*cntoff1/4);          % 结束索引：下一次导通前3/4周期
Vcetop = mean(ch2(start_idx:end_idx));      % 使用均值

% 计算Ictop
current_interval = ton1 + fix(cnton1/2) : toff1;    % 定义电流峰值搜索区间
[~, max_idx] = max(ch3(current_interval));           % 快速定位峰值索引 max_idx为相对索引
tIcm = current_interval(1) + max_idx - 1;           % 转换为全局索引
window_start = max(1, tIcm - 10);                   % 窗口起始：峰值前10点（最小为1）
Ictop = mean(ch3(window_start:tIcm));               % 计算均值
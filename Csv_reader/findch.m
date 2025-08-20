function [data_out] = findch(data_in,Print)
% 双脉冲测试信号通道识别与极性校正
%   本函数用于从原始数据中识别电力电子器件（如IGBT）的关键信号通道，包括：
%   门极电压（Vge）、集电极电压（Vce）、二极管电压（Vd）、IGBT电流（Iigbt）、负载电流（Id），并进行极性校正。
%
%   Inputs:
%       data_in : N×6 矩阵 (double)
%           原始数据矩阵，各列含义如下：
%           第1列 - 时间轴（单位：秒）
%           第2-6列 - 5个信号通道的原始数据（需包含Vge、Vce、Vd、Iigbt、Id）
%       Print : 0或者1 (int)
%           为1时则会输出通道分配详细信息
%   Outputs:
%       data_out : N×6 矩阵 (double)
%           处理后的数据矩阵，各列含义：
%           第1列 - 时间轴（与输入一致）
%           第2列 - 门极电压 Vge（已识别）
%           第3列 - 集电极电压 Vce（已识别）
%           第4列 - IGBT电流 Iigbt（已识别）
%           第5列 - 二极管电压 Vd（已识别）
%           第6列 - 负载电流 Id（已校正极性）


%% 初始化输出矩阵
data_out = zeros(size(data_in));
data_out(:,1) = data_in(:,1);  % 保留时间轴
data_in(:,1) = NaN;
raw_columns = 2:6;  % 原始数据中待分组的信号列（列2-6）
CH = zeros(1,5);  % 通道记录数组 [Vge, Vce, Ic, Vd, Id]

%% ==================== 第一阶段：信号分组 ====================
% 1.1 门极信号识别
max_vals = max(abs(data_in(:, raw_columns)), [], 1);  % 仅处理列2-6
[~, min_idx] = min(max_vals);
vge_col_raw = raw_columns(min_idx);  % 直接映射到原始列号（无需+1）
data_out(:,2) = data_in(:, vge_col_raw);
CH(1) = vge_col_raw - 1;  % 输出物理通道号（CH2→1，CH3→2等）
if Print
    fprintf('门极通道（原始列%d → CH%d）\n', vge_col_raw, CH(1));
end
data_in(:, vge_col_raw) = NaN;

% 1.2 高压组识别
valid_columns = raw_columns(~isnan(data_in(1, raw_columns)));  % 排除已标记为NaN的列
max_vals = max(data_in(:, valid_columns));
min_vals = min(data_in(:, valid_columns));
diff_vals = max_vals - min_vals;
[~, sorted_idx] = sort(diff_vals, 'descend');
high_voltage_cols_raw = valid_columns(sorted_idx(1:2));  % 直接取原始列号
high_voltage_cols = high_voltage_cols_raw - 1;  % 转换为物理通道号
if Print
    fprintf('高压通道（原始列%s → CH%s）\n', mat2str(high_voltage_cols_raw), mat2str(high_voltage_cols));
end

% 1.3 电流组识别
current_cols_raw = setdiff(raw_columns, [vge_col_raw, high_voltage_cols_raw]);
current_cols = current_cols_raw - 1; % 转换为物理通道号
assert(numel(current_cols_raw)==2, '电流通道异常：实际=%d', numel(current_cols_raw));
if Print
    fprintf('电流通道（原始列%s → CH%s）\n', mat2str(current_cols_raw), mat2str(current_cols));
end

% 开通关断区块划分
% Vge过零点位置记录
cntVge = indzer(data_out(:,2),0);
% Vge过零点次数记录
cntsw = length(cntVge);
%第一次开通时间点
ton1=cntVge(cntsw-3);
%第一次关断时间点
toff1=cntVge(cntsw-2);
%第二次开通时间点
ton2=cntVge(cntsw-1);
%计算第一开通时长
cnton1 = toff1-ton1;
%计算两次脉冲间关断时长
cntoff1 = ton2-toff1;


%% ==================== 第二阶段：高压信号处理 ====================
% 定义特征检测区间（避开开关瞬态）
t_on_steady = [ton1 + round(cnton1/4), toff1 - round(cnton1/4)];  % 导通稳态期
t_off_steady = [toff1 + round(cntoff1/4), ton2 - round(cntoff1/4)];% 关断稳态期

% --- 高压通道原始列号定义（数据列2-6对应CH1-CH5） ---
high_voltage_cols_raw = valid_columns(sorted_idx(1:2));  % 原始列号（2-6）

% --- Vce特征检测（基于稳态电压差） ---
max_diff = -inf;
for v_col_raw = high_voltage_cols_raw  % 遍历原始列号
    % 导通期电压（避开开关瞬态）
    V_on = median(data_in(t_on_steady(1):t_on_steady(2), v_col_raw));
    
    % 关断期电压（高压稳态特征）
    V_off = median(data_in(t_off_steady(1):t_off_steady(2), v_col_raw));
    
    % 选择电压差最大的通道作为Vce[2](@ref)
    voltage_diff = V_off - V_on;
    if voltage_diff > max_diff
        max_diff = voltage_diff;
        vce_candidate_raw = v_col_raw;  % 记录原始列号
    end
end

% 映射到物理通道号（列号-1）
CH(2) = vce_candidate_raw - 1;  % 例如：数据列3 → CH2
if Print
    fprintf('Vce → 数据列%d → 物理通道CH%d\n', vce_candidate_raw, CH(2));
end
data_out(:,3) = data_in(:,vce_candidate_raw);
data_in(:,vce_candidate_raw) = NaN;  % 标记已分配

% --- 剩余高压通道处理 ---
remaining_voltage_raw = setdiff(high_voltage_cols_raw, vce_candidate_raw);
assert(~isempty(remaining_voltage_raw), '未找到有效Vd通道');

% 直接分配剩余高压通道（数据列号优先）[3](@ref)
vd_candidate_raw = remaining_voltage_raw(1);
CH(4) = vd_candidate_raw - 1;  % 例如：数据列5 → CH4
if Print
    fprintf('Vd → 数据列%d → 物理通道CH%d\n', vd_candidate_raw, CH(4));
end

% 输出处理与极性验证
data_out(:,5) = data_in(:,vd_candidate_raw);
data_in(:,vd_candidate_raw) = NaN;
%% ==================== 第三阶段：电流信号处理 ====================
% 3.1 Ic识别（基于导通态电流特征）
% 数据列2-6对应物理通道CH1-CH5（列号-1）


% --- 导通/关断期电流特征检测 ---
max_current_ratio = 0;
for i_raw = current_cols_raw  % 遍历原始列号（数据列2-6）
    % 静态电流检测（Vge关断时，对应电感续流阶段）
    I_off = median(data_in(t_off_steady(1):t_off_steady(2), i_raw));
    
    % 动态电流检测（Vge导通稳态时，对应电感充电阶段）
    I_on = median(data_in(t_on_steady(1):t_on_steady(2), i_raw));
    
    % 特征比计算（动态电流差异显著者优先）
    current_ratio = abs(I_on / I_off);
    
    if current_ratio > max_current_ratio
        max_current_ratio = current_ratio;
        ic_candidate_raw = i_raw;  % 记录原始列号
    end
end

% 映射到物理通道号
CH(3) = ic_candidate_raw - 1;
if Print
    fprintf('Ic → 数据列%d → 物理通道CH%d\n', ic_candidate_raw, CH(3));
end
data_out(:,4) = data_in(:,ic_candidate_raw);
data_in(:,ic_candidate_raw) = NaN;  % 标记已分配

% 2.2 Id识别（直接分配）
% --- 剩余电流通道分配 ---
remaining_current_raw = setdiff(current_cols_raw, ic_candidate_raw);
assert(numel(remaining_current_raw)==1, 'Id通道异常：剩余通道数量=%d', numel(remaining_current_raw));
id_candidate_raw = remaining_current_raw(1);
CH(5) = id_candidate_raw - 1;  % 转换为物理通道号

% --- 续流期方向判断（二极管导通方向应为负） ---
% 定义续流期：Vce高压期（二极管导通）且Vd低压期（二极管导通）
t_vd_off = find(data_out(:,3) > 0.8*max(data_out(:,3)) & data_out(:,5) < 0.2*max(data_out(:,5)));
if ~isempty(t_vd_off)
    % 续流期电流极性校验
    if mean(data_in(t_vd_off, id_candidate_raw)) > mean(data_in( : , id_candidate_raw))
        data_out(:,6) = -data_in(:,id_candidate_raw);  % 强制反向
        warning('通道%d续流期方向异常：均值=%.1fA   已反向校正', CH(5), mean(data_in(t_vd_off, id_candidate_raw)));
    else
        data_out(:,6) = data_in(:,id_candidate_raw);
    end
    
    %     % 二次验证（续流期电流均值应<0）
    %     if mean(data_out(t_vd_off,6)) > -0.001 * max(abs(data_out(:,6)))
    %         warning('通道%d续流期方向异常：均值=%.1fA     %.0f', CH(5), mean(data_out(t_vd_off,6)),-0.1 * max(abs(data_out(:,6))));
    %     end
else
    error('未检测到续流期，请检查Vce/Vd信号识别');
end

if Print
    fprintf('Id → 数据列%d → 物理通道CH%d\n', id_candidate_raw, CH(5));
end

%% ==================== 结果输出 ====================
signal_labels = {'Vge', 'Vce', 'Ic', 'Vd', 'Id'};
fprintf('通道识别结果:\n');
fprintf('       ');
for i = 1:5
    fprintf('%s（通道%d）', signal_labels{i}, CH(i));
    if i < 5, fprintf('   '); else, fprintf('\n'); end
end

end
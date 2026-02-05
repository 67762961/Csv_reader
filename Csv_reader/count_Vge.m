function [Vgetop,Vgebase,cntVge] = count_Vge(ch1,cntVge)

cntsw = length(cntVge);
ton1=cntVge(cntsw-3);
toff1=cntVge(cntsw-2);
ton2=cntVge(cntsw-1);
toff2=cntVge(cntsw);

%% ================ Vgetop计算 ================
% 计算Vge高电平电压（使用中值避免噪声干扰）
ch1_po = ch1(ch1>=0);
High_Thresh = quantile(ch1_po, 0.95);
Low_Thresh = quantile(ch1_po, 0.90);
ch1_top = ch1_po((Low_Thresh <= ch1_po)&(ch1_po <= High_Thresh));
Vgetop = median(ch1_top);

toff90_1_indices = find(ch1(toff1:-1:ton1) > 0.9 * Vgetop, 1, 'first');
toff90_1 = toff1 - toff90_1_indices + 1; % 转换为原始索引
if isempty(toff90_1_indices)
    error('第一关断时间点识别失败')
end

toff90_2_indices = find(ch1(toff2:-1:ton2) > 0.9 * Vgetop, 1, 'first');
toff90_2 = toff2 - toff90_2_indices + 1; % 转换为原始索引
if isempty(toff90_2_indices)
    error('第二关断时间点识别失败')
end

%% ================ Vgebase计算 ================
% 计算Vge低电平电压（使用中值避免噪声干扰）
ch1_ne = ch1(ch1<=0);
High_Thresh = quantile(ch1_ne, 0.10);
Low_Thresh = quantile(ch1_ne, 0.05);
ch1_base = ch1_ne((Low_Thresh <= ch1_ne)&(ch1_ne <= High_Thresh));
Vgebase = median(ch1_base);

ton10_2_indices = find(ch1(ton2:-1:toff1) < 0.8 * Vgebase, 1, 'first');
ton10_2 = ton2 - ton10_2_indices + 1;
if isempty(ton10_2_indices)
    error('第二开通时间点识别失败')
end

ton10_1_indices = find(ch1(ton1:-1:1) < 0.8 * Vgebase, 1, 'first');
ton10_1 = ton1 - ton10_1_indices + 1;
if isempty(ton10_1_indices)
    error('第一开通时间点识别失败')
end

cntVge(cntsw-3) = ton10_1;
cntVge(cntsw-2) = toff90_1;
cntVge(cntsw-1) = ton10_2;
cntVge(cntsw)   = toff90_2;
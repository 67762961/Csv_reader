function [Vgetop,Vgebase,cntVge] = count_Vge(ch1,cntVge)

cntsw = length(cntVge);
ton1=cntVge(cntsw-3);
toff1=cntVge(cntsw-2);
ton2=cntVge(cntsw-1);
toff2=cntVge(cntsw);

%% ================ Vgetop计算 ================
% 计算Vge高电平电压（使用中值避免噪声干扰）
PicLength = fix((ton2 - toff1)*2/11);
PicStart = max(ton1 - PicLength,1);
PicEnd = min(toff2 + 2*PicLength,length(ch1));

ch1_count = ch1(PicStart:PicEnd);
ch1_po = ch1_count(ch1_count>=0);
High_Thresh = quantile(ch1_po, 0.97);
Low_Thresh = quantile(ch1_po, 0.93);
ch1_top = ch1_po((Low_Thresh <= ch1_po)&(ch1_po <= High_Thresh));
Vgetop = median(ch1_top);

Print_Flag = 0;

for gate = 0.90:-0.01:0.5
    toff90_1_indices = find(ch1(toff1:-1:ton1) > gate * Vgetop, 1, 'first');
    toff90_1 = toff1 - toff90_1_indices + 1; % 转换为原始索引
    if isempty(toff90_1_indices)
        % fprintf('第一关断时间门极电压阈值降低到 %.2f Vgetop = %.2f\n', gate, gate * Vgetop);
    else
        if gate < 0.9
            if Print_Flag == 0
                fprintf('门极判断点阈值调整:\n');
                Print_Flag = 1;
            end
            fprintf('       第一关断时间门极电压阈值降低到 %.2f Vgetop = %.2f\n', gate, gate * Vgetop);
        end
        break;
    end
end

if isempty(toff90_1_indices)
    print('门极1次关断点识别失败')
    error('门极1次关断点识别失败')
end

for gate = 0.90:-0.01:0.5
    toff90_2_indices = find(ch1(toff2:-1:ton2) > gate * Vgetop, 1, 'first');
    toff90_2 = toff2 - toff90_2_indices + 1; % 转换为原始索引
    if isempty(toff90_2_indices)
        % fprintf('第二关断时间门极电压阈值降低到 %.2f Vgetop = %.2f\n', gate, gate * Vgetop);
    else
        if gate < 0.9
            if Print_Flag == 0
                fprintf('门极判断点阈值调整:\n');
                Print_Flag = 1;
            end
            fprintf('       第二关断时间门极电压阈值降低到 %.2f Vgetop = %.2f\n', gate, gate * Vgetop);
        end
        break;
    end
end

if isempty(toff90_2_indices)
    print('门极2次关断点识别失败')
    error('门极2次关断点识别失败')
end

%% ================ Vgebase计算 ================
% 计算Vge低电平电压（使用中值避免噪声干扰）
ch1_ne = ch1_count(ch1_count<=0);
High_Thresh = quantile(ch1_ne, 0.07);
Low_Thresh = quantile(ch1_ne, 0.03);
ch1_base = ch1_ne((Low_Thresh <= ch1_ne)&(ch1_ne <= High_Thresh));
Vgebase = median(ch1_base);

% disp(['Vge高电平电压Vgetop = ', num2str(Vgetop), ' V']);
% disp(['Vge低电平电压Vgebase = ', num2str(Vgebase), ' V']);

for gate = 0.90:-0.01:0.5
    ton10_2_indices = find(ch1(ton2:-1:toff1) < gate * Vgebase, 1, 'first');
    ton10_2 = ton2 - ton10_2_indices + 1;
    if isempty(ton10_2_indices)
        % fprintf('第二开通时间门极电压阈值降低到 %.2f Vgebase = %.2f\n', gate, gate * Vgebase);
    else
        if gate < 0.9
            if Print_Flag == 0
                fprintf('门极判断点阈值调整:\n');
                Print_Flag = 1;
            end
            fprintf('       第二开通时间门极电压阈值降低到 %.2f Vgebase = %.2f\n', gate, gate * Vgebase);
        end
        break;
    end
end

if isempty(ton10_2_indices)
    print('门极2次开通点识别失败')
    error('门极2次开通点识别失败')
end

for gate = 0.90:-0.01:0.5
    ton10_1_indices = find(ch1(ton1:-1:1) < gate * Vgebase, 1, 'first');
    ton10_1 = ton1 - ton10_1_indices + 1;
    if isempty(ton10_1_indices)
        % fprintf('第一开通时间门极电压阈值降低到 %.2f Vgebase = %.2f\n', gate, gate * Vgebase);
    else
        if gate < 0.9
            if Print_Flag == 0
                fprintf('门极判断点阈值调整:\n');
                Print_Flag = 1;
            end
            fprintf('       第一开通时间门极电压阈值降低到 %.2f Vgebase = %.2f\n', gate, gate * Vgebase);
        end
        break;
    end
end

if isempty(ton10_1_indices)
    print('门极1次开通点识别失败')
    error('门极1次开通点识别失败')
end

if length(cntVge) > 4
    ton0=cntVge(1);
    toff0=cntVge(2);
    for gate = 0.90:-0.01:0.5
        ton10_0_indices = find(ch1(ton0:-1:1) < gate * Vgebase, 1, 'first');
        ton10_0 = ton0 - ton10_0_indices + 1;
        if isempty(ton10_0_indices)
            % fprintf('第零开通时间门极电压阈值降低到 %.2f Vgebase = %.2f\n', gate, gate * Vgebase);
        else
            if gate < 0.9
                if Print_Flag == 0
                    fprintf('门极判断点阈值调整:\n');
                    Print_Flag = 1;
                end
                fprintf('       第零开通时间门极电压阈值降低到 %.2f Vgebase = %.2f\n', gate, gate * Vgebase);
            end
            break;
        end
    end
    
    for gate = 0.90:-0.01:0.5
        toff90_0_indices = find(ch1(toff0:-1:ton0) > gate * Vgetop, 1, 'first');
        toff90_0 = toff0 - toff90_0_indices + 1; % 转换为原始索引
        if isempty(toff90_0_indices)
            % fprintf('第零关断时间门极电压阈值降低到 %.2f Vgetop = %.2f\n', gate, gate * Vgetop);
        else
            if gate < 0.9
                if Print_Flag == 0
                    fprintf('门极判断点阈值调整:\n');
                end
                fprintf('       第零关断时间门极电压阈值降低到 %.2f Vgetop = %.2f\n', gate, gate * Vgetop);
            end
            break;
        end
    end
    cntVge(cntsw-5) = ton10_0;
    cntVge(cntsw-4) = toff90_0;
end

%% ================ 更新cntVge ================
% disp(ton10_1);
% disp(toff90_1);
% disp(ton10_2);
% disp(toff90_2);
cntVge(cntsw-3) = ton10_1;
cntVge(cntsw-2) = toff90_1;
cntVge(cntsw-1) = ton10_2;
cntVge(cntsw)   = toff90_2;

if (cntsw == 4)
    cntVge(5) = length(ch1);
    cntVge(6) = length(ch1);
end
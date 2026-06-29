function [Vgetop,Vgebase,cntVge] = count_Cnt_Vge(Vge,cntVge)

cntsw = length(cntVge);
ton1=cntVge(cntsw-3);
toff1=cntVge(cntsw-2);
ton2=cntVge(cntsw-1);
toff2=cntVge(cntsw);

%% ================ Vgetop计算 ================
% 计算Vge高电平电压（使用中值避免噪声干扰）
PicLength = fix((ton2 - toff1)*2/11);
PicStart = max(ton1 - PicLength,1);
PicEnd = min(toff2 + 2*PicLength,length(Vge));

Vge_count = Vge(PicStart:PicEnd);
Vge_po = Vge_count(Vge_count>=0);
High_Thresh = quantile(Vge_po, 0.97);
Low_Thresh = quantile(Vge_po, 0.93);
Vge_top = Vge_po((Low_Thresh <= Vge_po)&(Vge_po <= High_Thresh));
Vgetop = median(Vge_top);

Print_Flag = 0;

for gate = 0.90:-0.01:0.5
    toff90_1_indices = find(Vge(toff1:-1:ton1) > gate * Vgetop, 1, 'first');
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
    toff90_2_indices = find(Vge(toff2:-1:ton2) > gate * Vgetop, 1, 'first');
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
Vge_count = Vge(toff90_1:toff90_2);
Vge_ne = Vge_count(Vge_count<=0);
High_Thresh = quantile(Vge_ne, 0.07);
Low_Thresh = quantile(Vge_ne, 0.03);
Vge_base = Vge_ne((Low_Thresh <= Vge_ne)&(Vge_ne <= High_Thresh));
Vgebase = median(Vge_base);

% disp(['Vge高电平电压Vgetop = ', num2str(Vgetop), ' V']);
% disp(['Vge低电平电压Vgebase = ', num2str(Vgebase), ' V']);

for gate = 0.1:0.01:2
    ton10_2_indices = find(Vge(ton2:-1:toff1) < Vgebase - gate*Vgebase, 1, 'first');
    ton10_2 = ton2 - ton10_2_indices + 1;
    if isempty(ton10_2_indices)
        % fprintf('第二开通时间门极电压补偿 %.2f 阈值提高到 Vgebase = %.2f\n', gate, Vgebase - gate*Vgebase);
    else
        if gate > 0.1
            if Print_Flag == 0
                fprintf('门极判断点阈值调整:\n');
                Print_Flag = 1;
            end
            fprintf('       第二开通时间门极电压补偿 %.2f 阈值提高到 Vgebase = %.2f\n', gate, Vgebase - gate*Vgebase);
        end
        break;
    end
end

if isempty(ton10_2_indices)
    print('门极2次开通点识别失败')
    error('门极2次开通点识别失败')
end

for gate = 0.1:0.01:2
    ton10_1_indices = find(Vge(ton1:-1:1) <  Vgebase - gate*Vgebase, 1, 'first');
    ton10_1 = ton1 - ton10_1_indices + 1;
    if isempty(ton10_1_indices)
        % fprintf('第一开通时间门极电压补偿 %.2f 阈值提高到 Vgebase = %.2f\n', gate, Vgebase - gate*Vgebase);
    else
        if gate > 0.1
            if Print_Flag == 0
                fprintf('门极判断点阈值调整:\n');
                Print_Flag = 1;
            end
            fprintf('       第一开通时间门极电压补偿 %.2f 阈值提高到 Vgebase = %.2f\n', gate, Vgebase - gate*Vgebase);
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
    for gate = 0.1:0.01:2
        ton10_0_indices = find(Vge(ton0:-1:1) <  Vgebase - gate*Vgebase, 1, 'first');
        ton10_0 = ton0 - ton10_0_indices + 1;
        if isempty(ton10_0_indices)
            % fprintf('第零开通时间门极电压补偿 %.2f 阈值提高到 Vgebase = %.2f\n', gate, Vgebase - gate*Vgebase);
        else
            if gate > 0.1
                if Print_Flag == 0
                    fprintf('门极判断点阈值调整:\n');
                    Print_Flag = 1;
                end
                fprintf('       第零开通时间门极电压补偿 %.2f 阈值提高到 Vgebase = %.2f\n', gate, Vgebase - gate*Vgebase);
            end
            break;
        end
    end
    
    for gate = 0.90:-0.01:0.5
        toff90_0_indices = find(Vge(toff0:-1:ton0) > gate * Vgetop, 1, 'first');
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
    cntVge(5) = length(Vge);
    cntVge(6) = length(Vge);
end
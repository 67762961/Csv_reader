function [cntVce,VceRange,PicRange] = count_Cnt_Vce(time,ch2,cntVge,DPI,Wave_count)

% Diff_ch2 = diff(ch2);
% Diff_Vce = smoothdata(Diff_ch2, 'movmean',30);
% Diff_Vce = abs(Diff_Vce);

Vce = smoothdata(ch2, 'movmean',100);
Vcemax = max(Vce);
nspd = time(2)-time(1); % 时间分辨率
cntVce = indzer(Vce,fix(Vcemax/2),fix(100/nspd*1e-9)); % 过零点索引及时间间隔过滤

% nspd = time(2)-time(1); % 时间分辨率
% [~, cntVce] = findpeaks(Diff_Vce, ...
%     'MinPeakProminence', 3, ...      % 这里填入你观察得出的合适阈值
%     'MinPeakDistance', fix(200/nspd*1e-9));

% disp(['检测到Vce跳变点数量: ', num2str(length(cntVce))]);
% disp(cntVce);

if (length(cntVce) ~= 4) && (cntVge(5) == length(time)) || (length(cntVce) ~= 6) && (cntVge(5) ~= length(time))
    close all;
    figure('Position', [320, 240, 1600/DPI, 600/DPI]);
    hold on;
    % Vce跳变点绘图
    plot(time, Vce, 'b');
    plot(time(cntVce), Vce(cntVce), 'ro', 'MarkerFaceColor','r');
    
    %Vce分段绘图
    % plot(time, ch2, 'b');
    % plot(time(cntVce), ch2(cntVce), 'ro', 'MarkerFaceColor','r');
    % plot(time(PicRange), 0, 'ro', 'MarkerFaceColor','r');
    grid on;
    
    disp('Vce跳变点数量与门极过零点数量不匹配 请检查数据或调整参数');
    error('Vce跳变点数量与门极过零点数量不匹配 请检查数据或调整参数');
end

if (length(cntVce) == 4)
    cntVce(5) = length(ch2);
    cntVce(6) = length(ch2);
end

Range(1) = max(min(Wave_count(1)*2-1,Wave_count(2)*2) - 1,1);
Range(2) = min(max(Wave_count(1)*2-1,Wave_count(2)*2) + 1,length(cntVge));

PicLength = fix(abs(cntVce(Range(2)) - cntVce(Range(1)))*1.4);
PicStart = max(cntVce(Range(1)) - fix(PicLength/5),1);
PicEnd = min(cntVce(Range(2)) + fix(PicLength/5),length(time));

PicRange = [PicStart, PicEnd];

% disp(PicRange);
Vcemax_temp = max(ch2);
Vcetop_temp = median(ch2(ch2 >= Vcemax_temp/2));
% disp(['Vcetop_temp = ', num2str(Vcetop_temp)]);

switch Wave_count(1)
    case 1
        Range_on_95 = cntVce(1):-1:1;
        Range_on_05 = cntVce(1):cntVce(2);
    case 2
        Range_on_95 = cntVce(3):-1:cntVce(2);
        Range_on_05 = cntVce(3):cntVce(4);
    case 3
        Range_on_95 = cntVce(5):-1:cntVce(4);
        Range_on_05 = cntVce(5):cntVce(6);
end

switch Wave_count(2)
    case 1
        Range_off_95 = cntVce(2):cntVce(3);
        Range_off_05 = cntVce(2):-1:cntVce(1);
    case 2
        Range_off_95 = cntVce(4):cntVce(5);
        Range_off_05 = cntVce(4):-1:cntVce(3);
    case 3
        Range_off_95 = cntVce(6):length(time);
        Range_off_05 = cntVce(6):-1:cntVce(5);
end

Print_Flag = 0;
for gate = 0.95:-0.01:0.1
    cntVce_on_95_indices = find(Vce(Range_on_95) > gate * Vcetop_temp, 1, 'first');
    cntVce_on_95 = Range_on_95(1) - cntVce_on_95_indices + 1; % 转换为原始索引
    if isempty(cntVce_on_95)
        % fprintf('       cntVce_on_95电压开通起始时间阈值降低到 %.2f Vcetop_temp = %.2f\n', gate, gate * Vcetop_temp);
    else
        if gate < 0.95
            if Print_Flag == 0
                fprintf('电压判断点阈值调整:\n');
                Print_Flag = 1;
            end
            fprintf('       cntVce_on_95电压开通起始时间阈值降低到 %.2f Vcetop_temp = %.2f\n', gate, gate * Vcetop_temp);
        end
        break;
    end
end

if isempty(cntVce_on_95)
    error('cntVce_on_95 识别失败')
end

for gate = 0.05:0.01:0.9
    cntVce_on_05_indices = find(Vce(Range_on_05) < gate * Vcetop_temp, 1, 'first');
    cntVce_on_05 = Range_on_05(1) + cntVce_on_05_indices + 1; % 转换为原始索引
    if isempty(cntVce_on_05)
        % fprintf('       cntVce_on_05电压开通起始时间阈值抬升到 %.2f Vcetop_temp = %.2f\n', gate, gate * Vcetop_temp);
    else
        if gate > 0.05
            if Print_Flag == 0
                fprintf('电压判断点阈值调整:\n');
                Print_Flag = 1;
            end
            fprintf('       cntVce_on_05电压开通起始时间阈值抬升到 %.2f Vcetop_temp = %.2f\n', gate, gate * Vcetop_temp);
        end
        break;
    end
end
if isempty(cntVce_on_05)
    error('cntVce_on_05 识别失败')
end

for gate = 0.05:0.01:0.9
    cntVce_off_05_indices = find(Vce(Range_off_05) < gate * Vcetop_temp, 1, 'first');
    cntVce_off_05 = Range_off_05(1) - cntVce_off_05_indices + 1; % 转换为原始索引
    if isempty(cntVce_off_05)
        % fprintf('       cntVce_off_05电压开通起始时间阈值抬升到 %.2f Vcetop_temp = %.2f\n', gate, gate * Vcetop_temp);
    else
        if gate > 0.05
            if Print_Flag == 0
                fprintf('电压判断点阈值调整:\n');
                Print_Flag = 1;
            end
            fprintf('       cntVce_off_05电压开通起始时间阈值抬升到 %.2f Vcetop_temp = %.2f\n', gate, gate * Vcetop_temp);
        end
        break;
    end
end
if isempty(cntVce_off_05)
    error('cntVce_off_05 识别失败')
end

for gate = 0.95:-0.01:0.1
    cntVce_off_95_indices = find(Vce(Range_off_95) > gate * Vcetop_temp, 1, 'first');
    cntVce_off_95 = Range_off_95(1) + cntVce_off_95_indices + 1; % 转换为原始索引
    if isempty(cntVce_off_95)
        % fprintf('       cntVce_off_95电压开通起始时间阈值降低到 %.2f Vcetop_temp = %.2f\n', gate, gate * Vcetop_temp);
    else
        if gate < 0.95
            if Print_Flag == 0
                fprintf('电压判断点阈值调整:\n');
                % Print_Flag = 1;
            end
            fprintf('       cntVce_off_95电压开通起始时间阈值降低到 %.2f Vcetop_temp = %.2f\n', gate, gate * Vcetop_temp);
        end
        break;
    end
end
if isempty(cntVce_off_95)
    error('cntVce_off_95 识别失败')
end

VceRange(1) = cntVce_on_95;
VceRange(2) = cntVce_on_05;
VceRange(3) = cntVce_off_05;
VceRange(4) = cntVce_off_95;

% disp(VceRange);

% %Vce分段绘图
% close all;
% figure('Position', [320, 240, 1600/DPI, 600/DPI]);
% hold on;
% plot(time, ch2, 'b');
% plot(time(cntVce), ch2(cntVce), 'ro', 'MarkerFaceColor','r');
% plot(time(cntVce_off_95), ch2(cntVce_off_95), 'go', 'MarkerFaceColor','g');
% plot(time(cntVce_off_05), ch2(cntVce_off_05), 'go', 'MarkerFaceColor','g');
% plot(time(cntVce_on_05), ch2(cntVce_on_05), 'go', 'MarkerFaceColor','b');
% plot(time(cntVce_on_95), ch2(cntVce_on_95), 'go', 'MarkerFaceColor','b');
% grid on;

% error('Vce过零点识别完成')
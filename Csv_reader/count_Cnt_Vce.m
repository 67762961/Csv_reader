function [cntVce,RangeVce] = count_Cnt_Vce(time,ch2,cntVge,DPI,Wave_count)

% Diff_ch2 = diff(ch2);
% Diff_Vce = smoothdata(Diff_ch2, 'movmean',30);
% Diff_Vce = abs(Diff_Vce);

Vce = smoothdata(ch2, 'movmean',100);
Vcemax = max(Vce);
nspd = time(2)-time(1); % 时间分辨率
cntVce = indzer(Vce,fix(Vcemax/2),fix(200/nspd*1e-9)); % 过零点索引及时间间隔过滤

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
    plot(time(1:end-1), Vce(1:end), 'b');
    plot(time(cntVce), Vce(cntVce), 'ro', 'MarkerFaceColor','r');
    
    %Vce分段绘图
    % plot(time, ch2, 'b');
    % plot(time(cntVce), ch2(cntVce), 'ro', 'MarkerFaceColor','r');
    % plot(time(RangeVce), 0, 'ro', 'MarkerFaceColor','r');
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

RangeVce = [PicStart, PicEnd];

% disp(RangeVce);
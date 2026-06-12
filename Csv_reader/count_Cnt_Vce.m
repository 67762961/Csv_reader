function [cntVce,RangeVce] = count_Cnt_Vce(time,ch2,cntVge,DPI,Wave_count)

Diff_ch2 = diff(ch2);
Diff_Vce = smoothdata(Diff_ch2, 'movmean',10);
Diff_Vce = abs(Diff_Vce);

nspd = time(2)-time(1); % 时间分辨率
[~, cntVce] = findpeaks(Diff_Vce, ...
    'MinPeakProminence', 5, ...      % 这里填入你观察得出的合适阈值
    'MinPeakDistance', fix(200/nspd*1e-9));

% disp(['检测到Vce跳变点数量: ', num2str(length(cntVce))]);
% disp(cntVce);

Range(1) = min(Wave_count(1)*2-1,Wave_count(2)*2) - 1;
Range(2) = max(Wave_count(1)*2-1,Wave_count(2)*2) + 1;

PicLength = abs(cntVce(Range(2)) - cntVce(Range(1)))*1.5;
PicStart = max(cntVce(Range(1)) - fix(PicLength/4),1);
PicEnd = min(cntVce(Range(2)) + fix(PicLength/4),length(time));

RangeVce = [PicStart, PicEnd];

if length(cntVce) ~= length(cntVge)
    close all;
    figure('Position', [320, 240, 1600/DPI, 600/DPI]);
    hold on;
    % Vce跳变点绘图
    % plot(time(PicStart:PicEnd-1), Diff_Vce(PicStart:PicEnd-1), 'b');
    % plot(time(cntVce), Diff_Vce(cntVce), 'ro', 'MarkerFaceColor','r');
    
    %Vce分段绘图
    plot(time, ch2, 'b');
    plot(time(cntVce), ch2(cntVce), 'ro', 'MarkerFaceColor','r');
    plot(time(RangeVce), 0, 'ro', 'MarkerFaceColor','r');
    grid on;
    
    disp('Vce跳变点数量与门极过零点数量不匹配 请检查数据或调整参数');
    error('Vce跳变点数量与门极过零点数量不匹配 请检查数据或调整参数');
    
end


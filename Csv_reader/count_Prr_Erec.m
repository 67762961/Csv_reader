function [Prrmax,Erec] = count_Prr_Erec(num,gate_Erec,time,Id,Vd,ch4,ch5,Ictop,Vcetop,path,dataname,cntVge)

cntsw = length(cntVge);
ton2=cntVge(cntsw-1);
toff2=cntVge(cntsw);
cnt2 = toff2 - ton2;

%% ====================== Prr/Erec计算 ======================
% 峰值功率计算
Prr_start_indices = find(ch5(ton2:toff2) > 0, 1, 'first');
Prr_start = ton2 + Prr_start_indices - 1;

Prr_end_indices = find(ch4(Prr_start:toff2) > Vcetop*0.9, 1, 'first');
Prr_end = Prr_start + Prr_end_indices - 1 + fix(cnt2/5);

% fprintf('%f\n%f\n%f\n',ton2,Prr_start_indices,Prr_end_indices);

% 恢复起始点：首次从负到正跨越零点的位置
Erec_start = Prr_start;
Erec_stop = [];

[~, peak_idx] = max(Id(Erec_start:end));
threshold = 0.1 * Id(Erec_start + peak_idx - 1);

Prr =  Id.* Vd;

[Prrmax_value, max_idx] = max(Prr(Prr_start:Prr_end));
t_Prrmax = Prr_start + max_idx - 1;
Prrmax = Prrmax_value / 1000;  % 单位kW

% 动态窗口生成
window_di = t_Prrmax: fix(toff2)+gate_Erec;

for i = window_di
    % fprintf('采样点 %f\n',Prr(i))
    if Prr(i) < threshold
        Erec_stop = i;
        break;
    else
        if min(Prr(i+1:i+gate_Erec)) > Prr(i)
            % disp(Prr(i+1:i+gate_Erec));
            % fprintf('因为 窗内最小值 %f > 当前值 %f 结束判断\n',min(Prr(i+1:i+gate_Erec)), Prr(i));
            Erec_stop = i;
            break;
        end
    end
end

% 有效性验证
assert(~isempty(Prr_start), '反向恢复时间Prr起始点检测失败');
assert(~isempty(Prr_end), '反向恢复时间Prr结束点检测失败');
assert(~isempty(Erec_start), '反向恢复时间Erec起始点检测失败');
assert(~isempty(Erec_stop), '反向恢复时间Erec结束点检测失败');

% 反向恢复能量计算（向量化优化）
valid_indices = Erec_start:Erec_stop;
Erec = sum(Prr(valid_indices(2:end)) .* diff(time(valid_indices))) * 1000; % 单位mJ

valid_time = time(Erec_start:Prr_end);       % 时间向量 [s]
valid_Prr = Prr(Erec_start:Prr_end);         % 瞬时功率向量 [W]
Erec_t = [zeros(Erec_start-1,1); cumtrapz(valid_time, valid_Prr) * 1e3];

% 可视化
PrrLength = fix((Erec_stop - Erec_start));
PicStart = Erec_start - fix(PrrLength/3);
PicEnd = Erec_stop + fix(PrrLength/2);
PicLength = PicEnd - PicStart;
PicTop = 2;
PicBottom = -1;
PicHeight = PicTop - PicBottom;

plot(time(PicStart:PicEnd),Id(PicStart:PicEnd)./max(Id(PicStart:PicEnd))*1.5,'b');
hold on
plot(time(PicStart:PicEnd),Vd(PicStart:PicEnd)./Vcetop,'g');
plot(time(Erec_start:Prr_end),1.5*Erec_t(Erec_start:Prr_end)/max(Erec_t(Erec_start:Prr_end)),'c--');
plot(time(Erec_start:Erec_stop),Prr(Erec_start:Erec_stop)/Prrmax/1000,'r',LineWidth=1.5);
plot(time(Prr_start:Erec_start),Prr(Prr_start:Erec_start)/Prrmax/1000,'r--');
plot(time(Erec_stop:Prr_end),Prr(Erec_stop:Prr_end)/Prrmax/1000,'r--');
plot(time(t_Prrmax),1,'o','color','red');

plot(time(Prr_start),Id(Prr_start)./max(Id)*1.5,'o','color','blue');
plot(time(Prr_end),Vd(Prr_end)./Vcetop,'o','color','green');
plot(time(Erec_stop),Prr(Erec_stop)/Prrmax/1000,'o','color','red');

line([time(Erec_stop-gate_Erec),time(Erec_stop+gate_Erec)],[Prr(Erec_stop)/Prrmax/1000,Prr(Erec_stop)/Prrmax/1000],'Color', [0.5 0.5 0.5]);
line([time(Erec_stop-gate_Erec),time(Erec_stop-gate_Erec)],[Prr(Erec_stop)/Prrmax/1000-0.05, Prr(Erec_stop)/Prrmax/1000+0.05], 'Color', [0.5 0.5 0.5]);
line([time(Erec_stop+gate_Erec),time(Erec_stop+gate_Erec)],[Prr(Erec_stop)/Prrmax/1000-0.05, Prr(Erec_stop)/Prrmax/1000+0.05], 'Color', [0.5 0.5 0.5]);

text(time(PicStart+fix(PicLength*0.05)),PicBottom+PicHeight*0.95,['Prrmax=',num2str(Prrmax),'kW'],'FontSize',13);
text(time(PicStart+fix(PicLength*0.05)),PicBottom+PicHeight*0.87,['Erec=',num2str(Erec),'mJ'],'FontSize',13);
text(time(PicStart+fix(PicLength*0.05)),PicBottom+PicHeight*0.80, num2str(2*gate_Erec), 'FontSize', 9,'Color', [0.5 0.5 0.5]);
text(time(t_Prrmax+5),1.3,'Prrmax','color','red','FontSize',13);

xlim([time(PicStart),time(PicEnd)]);
ylim([PicBottom,PicTop]);
legend('I_{d}','V_{d}','E_{rec}(t)','P_{rr}', 'Location','southeast');
legend('boxoff');
title(strcat('Ic=',num2str(fix(Ictop)),'A Prr-Erec(归一化)'));
grid on

% 保存
save_dir = fullfile(path, 'result', dataname, '08 Prr & Erec');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
saveas(gcf, fullfile(save_dir,[ num,' Ic=',num2str(fix(Ictop)),'A Prr.png']));
close(gcf);
hold off

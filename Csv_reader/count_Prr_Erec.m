function [Prrmax,Erec] = count_Prr_Erec(num,nspd,gate_Eerc,time,Id,Vd,ch4,ch5,Ictop,Vcetop,path,dataname,ton2,toff2,tdoff)

%% ====================== Prr/Erec计算 ======================
% 峰值功率计算
Prr_start_indices = find(ch5(ton2:toff2) > min(ch5)*0.1, 1, 'first');
Prr_start = ton2 + Prr_start_indices - 1;

Prr_end_indices = find(ch4(Prr_start:toff2) > max(ch4)*0.80, 1, 'first');
Prr_end = Prr_start + Prr_end_indices - 1 + 100;

Prr_length = abs(Prr_end -Prr_start);
% fprintf('%f\n%f\n%f\n',ton2,Prr_start_indices,Prr_end_indices);

% 恢复起始点：首次从负到正跨越零点的位置
Erec_start = find(diff(ch5(Prr_start-fix(Prr_length*0.01):Prr_end) >= 0) == 1, 1) + Prr_start;
Erec_stop = [];
   
[~, peak_idx] = max(Id(Erec_start:end));
threshold = 0.1 * Id(Erec_start + peak_idx - 1);

Prr =  Id.* Vd;

[Prrmax_value, max_idx] = max(Prr(Prr_start:Prr_end));
t_Prrmax = Prr_start + max_idx - 1;
Prrmax = Prrmax_value / 1000;  % 单位kW

time_step = nspd * 1e-9; 

% 动态窗口生成
max_search_length = fix(2e-9 * tdoff / time_step);
window_di = t_Prrmax: fix(t_Prrmax + 2* max_search_length);

for i = window_di
    % fprintf('采样点 %f\n',Prr(i))
    if Prr(i) < threshold
            Erec_stop = i;
            break;
    else
        if min(Prr(i+1:i+gate_Eerc)) > Prr(i)
            % fprintf('因为 %f > %f 结束判断\n',Prr(i+1), Prr(i))
            Erec_stop = i;
            break;
        end
    end
end

% fprintf('Prr起始点 %f\n',Prr_start)
% fprintf('Prrmax %f\n',t_Prrmax)
% fprintf('Prr结束点 %f\n',Prr_end)
% fprintf('反向恢复起始点 %f\n',Erec_start)
% fprintf('反向恢复结束点 %f\n',Erec_stop)

% 有效性验证
assert(~isempty(Prr_start), '反向恢复时间Prr起始点检测失败');
assert(~isempty(Prr_end), '反向恢复时间Prr结束点检测失败');
assert(~isempty(Erec_start), '反向恢复时间Erec起始点检测失败');
assert(~isempty(Erec_stop), '反向恢复时间Erec结束点检测失败');

% 反向恢复能量计算（向量化优化）
valid_indices = Erec_start:Erec_stop;
Erec = sum(Prr(valid_indices(2:end)) .* diff(time(valid_indices))) * 1000; % 单位mJ

valid_time = time(Erec_start:end);       % 时间向量 [s]
valid_Prr = Prr(Erec_start:end);         % 瞬时功率向量 [W]
Erec_t = [zeros(Erec_start-1,1); cumtrapz(valid_time, valid_Prr) * 1e3];

% 可视化
% figure;
plot(time,Id./max(Id)*1.5,'b');
hold on
plot(time,Vd./Vcetop,'g');
plot(time,Erec_t,'c:');
plot(time(Erec_start:Erec_stop),Prr(Erec_start:Erec_stop)/Prrmax/1000,'r',LineWidth=1.5);
plot(time(Erec_start-100:Erec_start),Prr(Erec_start-100:Erec_start)/Prrmax/1000,'r--');
plot(time(Erec_stop:Erec_stop+100),Prr(Erec_stop:Erec_stop+100)/Prrmax/1000,'r--');
plot(time(t_Prrmax),1,'o','color','red');

% plot(time(Prr_start),1,'o','color','blue');
% plot(time(Erec_start),1,'o','color','green');

text(time(t_Prrmax+30),0.8,['Prrmax=',num2str(Prrmax),'kW'],'FontSize',13);
text(time(t_Prrmax+30),1,['Erec=',num2str(Erec),'mJ'],'FontSize',13);
text(time(t_Prrmax+5),1.3,'Prrmax','color','red','FontSize',13);

xlim([time(Erec_start-100),time(Erec_stop+100)]);
ylim([-1.2,2]);
legend('I_{d}','V_{d}','E_{rec}(t)','P_{rr}', 'Location','northwest');
legend('boxoff');
title(strcat('Ic=',num2str(fix(Ictop)),'A Prr-Erec(归一化)'));
grid on

% 保存
if ~exist(fullfile(path,'pic',dataname,'Prr'), 'dir')
    mkdir(fullfile(path,'pic',dataname,'Prr')); 
end
saveas(gcf, fullfile(path,'pic',dataname,'Prr',[ num,' Ic=',num2str(fix(Ictop)),'A Prr.png']));
close(gcf);
hold off

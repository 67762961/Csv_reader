function output = countE(locate,tablename,tablenum,nspd,path,dataname,Chmode,dvdtmode,didtmode,Ch_labels,Vgeth,gate_didt,gate_Eerc)

%% 数据读取与预处理
% fprintf('%s',Chmode);
num = num2str(tablenum, '%03d');  
filename = fullfile(locate, [tablename, '_', num, '_ALL.csv']);     % 修正路径拼接
data0 = readmatrix(filename, 'NumHeaderLines', 20);                 % 跳过CSV头部元数据
fprintf('%s\n',filename);
% 通道修正
if strcmp(Chmode,'findch')
    data = findch(data0,0);
elseif strcmp(Chmode,'setch')
    data = setch(data0,Ch_labels);
else
    error('通道分配模式参数填写错误')
end

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% % % % findch1函数调试块
% % % outputtable=strcat(['D:\_Du_chengzhi\Matlab\CSV读取程序\TestLib\3','\result\','通道修复结果.xlsx']);
% % % writematrix(data,outputtable,'sheet',[tablename, '_', num, '_ALL.csv'],'range','A2');
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

% 提取原始信号（假设数据列顺序已校准）
time = data(:,1);       % 时间序列（单位s）
ch1 = data(:,2);        % Vge（门极电压）
ch2 = data(:,3);        % Vce（集射极电压）
ch3 = data(:,4);        % Ic（集电极电流）
ch4 = data(:,5);        % Vd（二极管电压）
ch5 = data(:,6);        % Id（二极管电流）

% 信号滤波（抑制噪声）
% 门极电压：移动中值滤波
Vge = smoothdata(ch1, 'movmedian', 60);  
% 集射电压：移动中值滤波
Vce = smoothdata(ch2, 'movmedian', 10, 'omitnan');
% 集电极电流：移动平均滤波
Ic = smoothdata(ch3, 'movmean', 10);  
Vd = smoothdata(ch4, 'movmedian', 5, 'omitnan');
Id = smoothdata(ch5, 'movmean', 5);  

%% 开通关断区块划分

% Vge过零点位置记录
cntVge = indzer(Vge,Vgeth);
% Vge过零点次数记录
cntsw = length(cntVge); 
if cntsw ~= 6
    warning('Vge过零点位置不等于六处 可能出现开关状态判断异常')
end
% fprintf('%d\n',cntsw);
% 第0次开通时间点
ton0=cntVge(cntsw-5);
% 第0次关断时间点
toff0=cntVge(cntsw-4); 
% 第一次开通时间点
ton1=cntVge(cntsw-3);
% 第一次关断时间点
toff1=cntVge(cntsw-2); 
% 第二次开通时间点
ton2=cntVge(cntsw-1); 
% 第二次关断时间点
toff2=cntVge(cntsw); 

% 计算第0开通时长
cnton0 = toff0-ton0; 
% 计算第一开通时长
cnton1 = toff1-ton1; 
% 计算两次脉冲间关断时长
cntoff1 = ton2-toff1; 
% 计算第二个脉冲开通时长
% cnton2 = toff2-ton2; 

%% 探头偏置校正（静态区间均值）
static_ic_interval = fix(toff1 + cntoff1/4) : fix(ton2 - cntoff1/4);
meanIc = mean(Ic(static_ic_interval)); % 关断时平均电流视为参考0电流
Ic = Ic - meanIc; % 电流探头较零
ch3 = ch3 - meanIc;
fprintf('探头自动较零:\n');
fprintf('       Ic偏移量:%03fA\n',meanIc);

% static_vce_interval = fix(ton1 + cnton1/4) : fix(toff1 - cnton1/4);
% meanVce = mean(Vce(static_vce_interval));  %开通时平均电压视为参考0电压
% Vce = Vce - meanVce; % 电压探头较零
% ch2 = ch2 - meanVce;
% fprintf('       Vce偏移量:%03fV\n',meanVce);

% static_vd_interval = fix(toff1 + cntoff1/4) : fix(ton2 - cntoff1/4);
% meanVd = mean(Vd(static_vd_interval)); 
% Vd = Vd - meanVd; % 电压探头较零
% ch4 = ch4 - meanVd;
% fprintf('       Vd偏移量:%03fV\n',meanVd);

static_id_interval = fix(ton0 + cnton0/4) : fix(toff0 - cnton0/4);
meanId = mean(Id(static_id_interval)); 
Id = Id - meanId;% 电流探头较零
ch5 = ch5 - meanId;
fprintf('       Id偏移量:%03fA\n',meanId);

% % % % % % % % % %
% % % % 调零调试
% % % data(:,1) = time;        % 时间序列（单位s）
% % % data(:,2) = ch1 ;        % Vge（门极电压）
% % % data(:,3) = ch2 ;        % Vce（集射极电压）
% % % data(:,4) = ch3 ;        % Ic（集电极电流）
% % % data(:,5) = ch4 ;        % Vd（二极管电压）
% % % data(:,6) = ch5 ;        % Id（二极管电流）
% % % outputtable = strcat(['D:\_Du_chengzhi\Matlab\CSV读取程序\TestLib','\result\','调零结果.xlsx']);
% % % writematrix(data,outputtable,'sheet',tablename,'range','A2');
% % % % % % % % % %

% ====================== Vcetop Ictop 计算 ======================
[Vcetop,Ictop,ton10,toff90,tIcm] = count_Vcetop_Ictop(Vge,ch2,ch3,ton1,toff1,ton2,toff2,cnton1,cntoff1);

% ====================== 开通损耗计算（Eon） ======================
[Eon,SWon_start,SWon_stop] = count_Eon(num,time,Ic,Vce,Ictop,Vcetop,path,dataname,ton2,toff2,cntoff1);

% ====================== 关断损耗计算（Eoff） ======================
[Eoff,SWoff_start,SWoff_stop] = count_Eoff(num,time,Ic,Vce,Ictop,Vcetop,path,dataname,ton2,toff90);

%% ================ Vcemax计算 ================
% 找出最大值
[Vcemax, cemax_idx] = max(ch2(toff90:fix(toff90+cntoff1)));
cemax_idx = toff90 + cemax_idx - 1;  % 转换为全局索引

% 绘图
% figure;
plot(time(toff90:ton2), ch2(toff90:ton2), 'b');
hold on;
plot(time(cemax_idx), Vcemax, 'ro', 'MarkerFaceColor','r');
text(time(cemax_idx)+0.02*range(time(toff90:ton2)), Vcemax-0.1*range(ch2), ...
    ['Vcemax=',num2str(Vcemax),'V'], 'FontSize',13);
title(['Ic=',num2str(fix(Ictop)),'A Vcemax']);
grid on;

% 路径构建优化
save_dir = fullfile(path, 'pic', dataname, 'Vce');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
saveas(gcf, fullfile(save_dir, [ num, ' Ic=',num2str(fix(Ictop)),'A Vcemax.png']), 'png');
close(gcf);
hold off

%% ================ Vdmax计算 ================
[Vdmax, dmax_idx] = max(ch4(ton2:toff2));
dmax_idx = ton2 + dmax_idx - 1;

% 绘图
% figure;
plot(time(ton2:toff2), ch4(ton2:toff2), 'b');
hold on;
plot(time(dmax_idx), Vdmax, 'ro', 'MarkerFaceColor','r');
text(time(dmax_idx)+0.02*range(time(ton2:toff2)), Vdmax-0.1*range(ch4), ...
    ['Vdmax=',num2str(Vdmax),'V'], 'FontSize',13);
title(['Ic=',num2str(fix(Ictop)),' A Vdmax']);
grid on;

save_dir = fullfile(path, 'pic', dataname, 'Vd');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
saveas(gcf, fullfile(save_dir, [ num,' Ic=',num2str(fix(Ictop)),'A Vdmax.png']), 'png');
close(gcf);
hold off

%% ================ 开通时间（Ton）计算与绘图 ================
% 开通时电流=10%时刻（区间：ton2到toff2）
% 要求连续3个采样点超过阈值（抗噪声）
debounce_samples = 3;
for i = ton10:length(Ic)-debounce_samples
    if all(Ic(i:i+debounce_samples-1) > 0.1*Ictop)
        tonIcm10 = i;
        break;
    end
end

% 开通时电流=90%时刻（区间：tonIcm10到toff2）
tonIcm90_indices = find(Ic(tonIcm10:min(toff2, length(Ic))) > Ictop*0.9, 1, 'first');
tonIcm90 = tonIcm10 + tonIcm90_indices - 1;

% 索引边界保护
ton_bg_start = max(1, fix(ton10 * 0.997));
ton_bg_end = min(length(time), fix(tonIcm90 * 1.003));
ton_delay_range = ton10 : tonIcm10;  
ton_slope_range = tonIcm10 : tonIcm90;  

% 时间参数计算
tdon = (time(tonIcm10) - time(ton10)) * nspd * 1e9;  
tr = (time(tonIcm90) - time(tonIcm10)) * nspd * 1e9;

% 绘图优化（复用结构）
% figure;
hold on;
plot(time(ton_bg_start:ton_bg_end), ch1(ton_bg_start:ton_bg_end), 'Color', [0.2 0.8 0.2]);
plot(time(ton_delay_range), ch1(ton_delay_range), 'r', 'LineWidth', 1.8);
plot(time(ton_slope_range), ch1(ton_slope_range), 'b', 'LineWidth', 1.8);

text(time(ton10)*0.999,Vge(ton10),['t(d)on=',num2str(tdon),'ns'],'FontSize',13,'color','red');
text(time(tonIcm10)*1.0005,Vge(tonIcm10),['tr=',num2str(tr),'ns'],'FontSize',13,'color','blue');

% 图形属性
grid on;
title(sprintf('Ic=%dA  Ton=%.1fns', fix(Ictop), tr + tdon));
xlabel('Time (s)');
ylabel('Voltage (V)');

% 标准化保存路径
save_dir = fullfile(path, 'pic', dataname, 'Ton');
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end
saveas(gcf, fullfile(save_dir, [ num,' Ic=',num2str(fix(Ictop)),'A Ton.png']), 'png');
close(gcf);
hold off

%% ================ 关断时间（Toff）计算与绘图 ================
% 关断时电流=90%时刻
toffIcm90_indices = find(Ic(tIcm:min(toff1+50, length(Ic))) < Ictop*0.9, 1, 'first');
toffIcm90 = tIcm + toffIcm90_indices - 1;

% 关断时电流=10%时刻
toffIcm10_indices = find(Ic(toffIcm90:min(ton2, length(Ic))) < Ictop*0.1, 1, 'first');
toffIcm10 = toffIcm90 + toffIcm10_indices - 1;

% 动态索引边界保护
toff_bg_start = max(1, fix(toff90 * 0.997));
toff_bg_end = min(length(time), fix(toffIcm10 * 1.003));
toff_delay_range = toff90 : toffIcm90;  % 延迟阶段索引
toff_slope_range = toffIcm90 : toffIcm10;  % 斜率阶段索引

% 时间参数计算（单位：纳秒）
tdoff = (time(toffIcm90) - time(toff90)) * nspd * 1e9;  
tf = (time(toffIcm10) - time(toffIcm90)) * nspd * 1e9;

% 绘图优化
% figure;
hold on;
% 背景区间（绿色）
plot(time(toff_bg_start:toff_bg_end), ch1(toff_bg_start:toff_bg_end), 'Color', [0.2 0.8 0.2]); 
% 延迟阶段（红色）
plot(time(toff_delay_range), ch1(toff_delay_range), 'r', 'LineWidth', 1.8); 
% 斜率阶段（蓝色）
plot(time(toff_slope_range), ch1(toff_slope_range), 'b', 'LineWidth', 1.8); 

text(time(toff90)*0.999,Vge(toff90),['t(d)off=',num2str(tdoff),'ns'],'FontSize',13,'color','red');
text(time(toffIcm90)*1.0005,Vge(toffIcm90),['tf=',num2str(tf),'ns'],'FontSize',13,'color','blue');

% 图形属性设置
grid on;
title(sprintf('Ic=%dA  Toff=%.1fns', fix(Ictop), tdoff + tf));
xlabel('Time (s)');
ylabel('Voltage (V)');

% 路径处理标准化
save_dir = fullfile(path, 'pic', dataname, 'Toff');
if ~exist(save_dir, 'dir')
    mkdir(save_dir);draw
end
saveas(gcf, fullfile(save_dir, [ num,' Ic=',num2str(fix(Ictop)),'A Toff.png']), 'png');
close(gcf);
hold off

%% ====================== Prr/Erec计算 ======================
% 峰值功率计算
Prr_start_indices = find(ch5(ton2:toff2) > min(ch5)*0.1, 1, 'first');
Prr_start = ton2 + Prr_start_indices - 1;

Prr_end_indices = find(ch4(Prr_start:toff2) < max(ch4)*0.95, 1, 'first');
Prr_end = Prr_start + Prr_end_indices - 1 + 100;

Prr_length = abs(Prr_end -Prr_start);
% fprintf('%f\n%f\n%f\n',ton2,Prr_start_indices,Prr_end_indices);

% 恢复起始点：首次从负到正跨越零点的位置
Erec_start = find(diff(ch5(Prr_start-fix(Prr_length*0.05):Prr_end) >= 0) == 1, 1) + Prr_start;
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
assert(~isempty(Erec_start) && ~isempty(Erec_stop), '反向恢复时间检测失败');

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
title(strcat('Ic=',num2str(fix(Ictop)),'A Prr-Erec(归一化)'));
grid on

% 保存
if ~exist(fullfile(path,'pic',dataname,'Prr'), 'dir')
    mkdir(fullfile(path,'pic',dataname,'Prr')); 
end
saveas(gcf, fullfile(path,'pic',dataname,'Prr',[ num,' Ic=',num2str(fix(Ictop)),'A Prr.png']));
close(gcf);
hold off

%% dv/dt计算模块
% 阈值定义
V_10 = Vcetop * 0.1;
V_90 = Vcetop * 0.9;
V_a  = Vcetop * dvdtmode(1)/100;
V_b  = Vcetop * dvdtmode(2)/100;

% 电压上升沿阈值检测
window_dv_start = max(1, SWoff_start-50);  % 起始索引不低于1
window_dv_end = min(length(Vce), SWoff_stop+50);  % 终止索引不超过数组长度
window_dv = window_dv_start : window_dv_end;

rise_start_idx = find(Vce(window_dv) >= V_10, 1, 'first') + window_dv(1) - 1;
rise_end_idx  = find(Vce(rise_start_idx:window_dv(end)) >= V_90, 1, 'first') + rise_start_idx - 1;
delta_time = (rise_end_idx  - rise_start_idx) * nspd * 1e-9;      % 时间差(ns转秒)
dvdt = (Vce(rise_end_idx ) - Vce(rise_start_idx)) / delta_time * 1e-6;

rise_start_idx_a = find(Vce(window_dv) >= V_a, 1, 'first') + window_dv(1) - 1;
rise_end_idx_b  = find(Vce(rise_start_idx:window_dv(end)) >= V_b, 1, 'first') + rise_start_idx - 1;
delta_time_a_b = (rise_end_idx_b  - rise_start_idx_a) * nspd * 1e-9;      % 时间差(ns转秒)
dvdt_a_b = (Vce(rise_end_idx_b) - Vce(rise_start_idx_a)) / delta_time_a_b * 1e-6;

% 保持原始绘图逻辑
% figure;
plot(time(rise_start_idx-50:rise_end_idx +50), Vce(rise_start_idx-50:rise_end_idx +50), 'b');
hold on;
plot(time(rise_start_idx:rise_end_idx ), Vce(rise_start_idx:rise_end_idx ), 'r', 'LineWidth',1.5);
plot(time(rise_start_idx), Vce(rise_start_idx), 'ro', 'MarkerFaceColor','r');
plot(time(rise_end_idx ), Vce(rise_end_idx ), 'ro', 'MarkerFaceColor','r');

text(time(rise_start_idx+3),Vce(rise_start_idx),['Vce{10}=',num2str(Vce(rise_start_idx)),'V',],'FontSize',13);
text(time(rise_end_idx +3),Vce(rise_end_idx ),['Vce{90}=',num2str(Vce(rise_end_idx )),'V'],'FontSize',13);
text(time(rise_start_idx-40),Vcemax*0.9,['Vcetop=',num2str(Vcetop),'V'],'FontSize',13);
text(time(rise_start_idx-40),Vcemax*0.8,['dv/dt=',num2str(dvdt),'V/us'],'FontSize',13);
if dvdtmode(1) ~= 10 || dvdtmode(2) ~= 90
    plot(time(rise_start_idx_a:rise_end_idx_b ), Vce(rise_start_idx_a:rise_end_idx_b ), 'g', 'LineWidth',1.5);
    plot(time(rise_start_idx_a), Vce(rise_start_idx_a), 'ro', 'MarkerFaceColor','g');
    text(time(rise_start_idx_a+3),Vce(rise_start_idx_a),['Vce{',num2str(dvdtmode(1)),'}=',num2str(Vce(rise_start_idx_a)),'V',],'FontSize',13);
    plot(time(rise_end_idx_b), Vce(rise_end_idx_b), 'ro', 'MarkerFaceColor','g');
    text(time(rise_end_idx_b+3),Vce(rise_end_idx_b),['Vce{',num2str(dvdtmode(2)),'}=',num2str(Vce(rise_end_idx_b)),'V',],'FontSize',13);
    text(time(rise_start_idx-40),Vcemax*0.7,['dv/dt(',num2str(dvdtmode(1)),'-',num2str(dvdtmode(2)),')=',num2str(dvdt_a_b),'V/us'],'FontSize',13);
    % 若启动额外dvdt计算 则dvdt表格输出按照手动设置组输出
    dvdt = dvdt_a_b;
end
% 坐标轴设置
ylim([0, Vcemax*1.1]);
xlim([time(rise_start_idx-50), time(rise_end_idx +50)]);
title(['Ic=',num2str(fix(Ictop)),'A dv/dt计算']);
grid on;

% 保存路径处理
save_dir = fullfile(path, 'pic', dataname, 'dvdt');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
saveas(gcf, fullfile(save_dir, [ num,' Ic=',num2str(fix(Ictop)),'A dvdt-Vcetop=',num2str(fix(Vcetop)),'.png']), 'png');
close(gcf);
hold off

%% di/dt计算模块

% 阈值定义
Ic_a  = Ictop * didtmode(1)/100;
Ic_b  = Ictop * didtmode(2)/100;

% 状态机参数初始化
state = 0; % 0:等待触发 1:低阈值触发 2:完成检测
valid_rise_start = [];
valid_rise_end = [];

% 动态窗口生成
time_step = nspd * 1e-9; 
max_search_length = fix(2e-9 * tdon / time_step);
window_di = fix(SWon_start - max_search_length): fix(SWon_stop + max_search_length);

% 状态机主循环
for i = window_di
    if ch3(i) >= 0
        % fprintf('采样点 %f\n',ch3(i))
    end
    switch state
        case 0 % 等待触发
            if ch3(i) >= Ic_a
                valid_rise_start = i;
                % fprintf('触发值 %f\n',ch3(valid_rise_start))
                state = 1;
            end
            
        case 1 % 低阈值触发
            if max(ch3(i:i+gate_didt)) < ch3(i-1)
                % fprintf('因为 %f < %f 触发回落\n',min(ch3(i:i+10)), ch3(i-1))
                state = 0; % 发现回落重置
                valid_rise_start = [];
            else
                if ch3(i) >= Ic_b
                    valid_rise_end = i;
                    state = 2;
                end
            end
            
        case 2 % 完成检测
            break;
    end
end

% fprintf('valid_rise_start = %f\nvalid_rise_end = %f\n',ch3(valid_rise_start),ch3(valid_rise_end));

% 带保护的计算逻辑
if time(valid_rise_end) == time(valid_rise_start)
    didt = 0;
else
    didt = (ch3(valid_rise_end) - ch3(valid_rise_start)) / (time(valid_rise_end)-time(valid_rise_start)) / 1e6;
end

if isempty(didt)
    didt = 0;
end

% 绘图
% figure;
plot(time(SWon_start-50:SWon_stop+50), ch3(SWon_start-50:SWon_stop+50), 'b');
hold on;
plot(time(valid_rise_start:valid_rise_end), ch3(valid_rise_start:valid_rise_end), 'r', 'LineWidth',1.5);
plot(time(valid_rise_start), ch3(valid_rise_start), 'ro', 'MarkerFaceColor','r');
plot(time(valid_rise_end), ch3(valid_rise_end), 'ro', 'MarkerFaceColor','r');

% 动态标注
text(time(valid_rise_start+3),ch3(valid_rise_start),['Ic',num2str(didtmode(1)),'=',num2str(ch3(valid_rise_start)),'A'],'FontSize',13);
text(time(valid_rise_end+3),ch3(valid_rise_end),['Ic',num2str(didtmode(2)),'=',num2str(ch3(valid_rise_end)),'A'],'FontSize',13);
text(time(SWon_start-40),max(ch3(SWon_start-50:SWon_stop))*0.9,['Ictop=',num2str(Ictop),'A'],'FontSize',13);
text(time(SWon_start-40),max(ch3(SWon_start-50:SWon_stop))*0.8,['di/dt=',num2str(didt),'A/us'],'FontSize',13);

% 坐标轴设置
ylim([-5, max(ch3(SWon_start-50:SWon_stop+50))*1.1]);
xlim([time(SWon_start-50), time(SWon_stop+50)]);
title(['Ic=',num2str(fix(Ictop)),'A di/dt计算']);
grid on;

% 保存处理
save_dir = fullfile(path, 'pic', dataname, 'didt');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
saveas(gcf, fullfile(save_dir, [ num,' Ic=',num2str(fix(Ictop)),'A didt.png']), 'png');
close(gcf);
hold off

%% 输出表
output=zeros(16,1);

output(1)=Ictop;
output(2)=Eon;
output(3)=Eoff;
output(4)=Vcemax;
output(5)=Vdmax;
output(6)=dvdt;
output(7)=didt;
output(8)=Vcetop;
output(9)=Erec;
output(10)=Prrmax;
output(11)=tdon;
output(12)=tr;
output(13)=tr+tdon;
output(14)=tdoff;
output(15)=tf;
output(16)=tdoff+tf;

fprintf('\n');
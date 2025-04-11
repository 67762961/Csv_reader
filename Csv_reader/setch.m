function [data_out] = setch(data_in,Ch_labels)
% 双脉冲测试信号通道设置函数

data_out = zeros(size(data_in));
data_out(:,1) = data_in(:,1);           % 保留时间轴
data_out(:,Ch_labels{1}+1) = data_in(:,2);
data_out(:,Ch_labels{2}+1) = data_in(:,3);
data_out(:,Ch_labels{3}+1) = data_in(:,4);
data_out(:,Ch_labels{4}+1) = data_in(:,5);
data_out(:,Ch_labels{5}+1) = data_in(:,6);

signal_labels = {'Vge', 'Vce', 'Ic', 'Vd', 'Id'};
fprintf('通道分配结果:\n');
fprintf('       ');
for i = 1:5
    fprintf('%s（通道%d）', signal_labels{i}, Ch_labels{i});
    if i < 5, fprintf('   '); else, fprintf('\n'); end
end
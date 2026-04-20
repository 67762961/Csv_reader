function TemplateCopy(Output_Path, dataname)
%% 复制参数表到文件路径
% 获取调用堆栈信息
stack = dbstack('-completenames');

% 检查堆栈深度，确保有调用者
if length(stack) < 2
    warning('未在函数调用环境中执行，无法复制调用文件。');
    return;
end

% stack(1) 是当前函数（yourFunction）本身
% stack(2) 是调用当前函数的文件（调用者）的信息
callerInfo = stack(2);
callerFullPath = callerInfo.file; % 调用者文件的完整路径

% 指定目标目录
targetDirectory = strcat([Output_Path,'\result\',dataname]);

% 确保目标目录存在
if ~exist(targetDirectory, 'dir')
    mkdir(targetDirectory);
end

% 从完整路径中获取调用者的文件名和扩展名
[~, callerName, callerExt] = fileparts(callerFullPath);

newFileName = [callerName, callerExt]; % 不包含时间戳

% 构建新文件的完整保存路径
newFileFullPath = fullfile(targetDirectory, newFileName);

% 执行复制操作
[copySuccess, message] = copyfile(callerFullPath, newFileFullPath);

% 检查复制操作是否成功
if copySuccess
    fprintf('\n调用文件已成功复制至: %s\n', newFileFullPath);
else
    warning('文件复制失败: %s', message);
end

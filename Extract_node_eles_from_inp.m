function contentStruct = Extract_node_eles_from_inp(filename)
tic

% 读取inp文件, 并创建关键词的检索
fileContent = fileread(filename);
keywords = extractKeywordsFromInp(fileContent);

% 通过对话框, 选择感兴趣的关键字
selectedKeywords = selectKeywords(keywords);

% 显示所选的关键字及其行号
disp('请选择关键字(按ctrl可多选)：');
for select_i = 1:length(selectedKeywords)
    fprintf('关键字: %s, 行号: %d\n', selectedKeywords(select_i).keyword, selectedKeywords(select_i).lineNumber);
end

% 提取内容
contentStruct = extractContentBetweenKeywords(fileContent, keywords, selectedKeywords);


% 输出时间消耗
toc




% -------------------子程序-----------------------------

function selectedKeywords = selectKeywords(keywords)
    keywordList = {keywords.keyword};
    % 弹出多选对话框
    [selected, ok] = listdlg('ListString', keywordList, ...
                             'SelectionMode', 'multiple', ...
                             'PromptString', '选择感兴趣的关键字:', ...
                             'ListSize', [300, 300]);
    % 如果用户点击了“OK”
    if ok
        % 获取所选关键字及其行号
        selectedKeywords = keywords(selected);
    else
        selectedKeywords = [];  % 用户取消选择
    end
end

% 提取关键字的函数
function keywords = extractKeywordsFromInp(fileContent)
    % extractKeywordsFromInp 从指定的 .inp 文件内容提取关键字及其行号
    %
    % 输入:
    %   fileContent - .inp 文件的内容字符串
    %
    % 输出:
    %   keywords - 结构体数组，包含关键字及其行号

    % 初始化存储关键字和行号的结构体数组
    keywords = struct('keyword', {}, 'lineNumber', {});

    % 按行分割内容
    lines = strsplit(fileContent, '\n');  % 按行分割内容

    % 遍历每一行
    for lineNumber = 1:length(lines)
        line = strtrim(lines{lineNumber});  % 去掉前后的空格
        
        % 检查行是否包含关键字
        if startsWith(line, '*') && length(line) > 1 && isstrprop(line(2), 'upper')
            keyword = strtrim(line);  % 去掉前后的空格
            
            % 存储关键字及其行号
            keywords(end + 1) = struct('keyword', keyword, 'lineNumber', lineNumber);
        end
    end
end

% 提取内容的函数
function contentStruct = extractContentBetweenKeywords(fileContent, keywords, selectedKeywords)
    % extractContentBetweenKeywords 提取指定多个关键字与下一个关键字之间的所有内容
    %
    % 输入:
    %   fileContent - .inp 文件的内容字符串
    %   keywords - 结构体数组，包含所有关键字及其行号
    %   selectedKeywords - 结构体数组，包含用户选择的关键字及行号
    %
    % 输出:
    %   contentStruct - 结构体数组，用于保存提取的关键字之间的内容

    contentStruct = struct('keyword', {}, 'content', {});
    
    % 按行分割内容
    lines = strsplit(fileContent, '\n');  % 按行分割内容

    % 遍历所选关键字
    for i = 1:length(selectedKeywords)
        targetKeyword = selectedKeywords(i).keyword;

        %提取不同单元类型中的节点数

        if contains(targetKeyword, 'Element')

            Ele_type = regexp(targetKeyword, 'type=([\w\d]+)', 'tokens');
            Ele_type = Ele_type{1};
            % 判断单元类型共有几个节点
            node_number = extractElementTypeNumber(Ele_type)+1;
        else
            node_number = 4;
        end

        %             node_number = extractElementTypeNumber(Ele_type)+1;
        %
        %         else
        %             node_number = 4; % for *Node
        %
        %         end
        % 行号，起始关键字的
        targetIndex = selectedKeywords(i).lineNumber;

        % 为了确定selectedKeywords(i)下一个关键字的行号
        % 先在inp文件的所有的keyords中，查找到selectedKeywords(i)的位置
        targetIndices = find(strcmp({keywords.keyword}, targetKeyword));

        if ~isempty(targetIndices) && targetIndices(1) < length(keywords)
            nextKeywordLine = keywords(targetIndices(1) + 1).lineNumber - 1;  % 下一个关键字的前一行
        else
            nextKeywordLine = length(lines);  % 如果没有下一个关键字，设置为文件末尾
        end

        % 提取指定行范围的内容
        content = strtrim(lines(targetIndex + 1 : nextKeywordLine))';  % 提取行号之间的内容
        % 将所有的内容中的逗号替换为空格，这样可以使用 str2num
        contentWithoutCommas = strrep(content, ',', ' ');  % 将逗号替换为空格

        % 将 cell 数组中的字符串直接转换为数值矩阵
        numericArray = cellfun(@(x) str2num(x), contentWithoutCommas, 'UniformOutput', false);
        num_node_one_line = size(numericArray{1,1},2);
        num_node_one_two_line = size(numericArray{2,1},2)+num_node_one_line;

        if (num_node_one_line < node_number) && (num_node_one_two_line == node_number)

            % 每两行合并为1行
            % 假设 numericArray 是已转换的数值单元格数组
            % 确定 numericArray 的行数
            numRows = size(numericArray, 1);

            % 初始化一个新的 cell 数组用于存储合并后的行
            combinedArray = cell(numRows / 2, 1);

            % 遍历每个奇数行并将其与后面的偶数行合并
            for row_i = 1:2:numRows
                % 奇数行数据
                oddRow = numericArray{row_i, 1};

                % 偶数行数据
                if row_i + 1 <= numRows
                    evenRow = numericArray{row_i + 1, 1};
                else
                    evenRow = [];  % 如果没有偶数行
                end

                % 合并奇数行和偶数行的数据
                combinedRow = [oddRow, evenRow];  % 水平拼接行数据

                % 存储合并后的数据
                combinedArray{(row_i + 1) / 2, 1} = combinedRow;
            end

            % 将 cell 数组转换为矩阵
            numericMatrix = cell2mat(combinedArray);


        elseif num_node_one_line == node_number
            numericMatrix = cell2mat(numericArray);
        else
            disp('每个单元包含的节点数量，发生错误')
            break;
        end

        % 转换后的 numericArray 是一个 cell 数组，我们可以直接将其展开为矩阵

 

        % 添加到结构体
        contentStruct(end + 1) = struct('keyword', targetKeyword, ...
                                         'content', numericMatrix);  % 使用表格作为内容
    end
end


function node_number = extractElementTypeNumber(Ele_type)
    % 根据单元类型名称提取节点数目

    % 判断单元类型是否以 'C' 开头（固体单元）
    
    if startsWith(Ele_type, 'C')
        switch Ele_type{1}
            case {'C3D8', 'C3D8R'}
                node_number = 8;  % 8节点的固体单元
            case {'C3D20', 'C3D20R'}
                node_number = 20; % 20节点的固体单元
            case 'C3D15'
                node_number = 15; % 15节点的固体单元
            otherwise
                error('未知的固体单元类型: %s', Ele_type);
        end
        
    % 判断单元类型是否以 'S' 开头（板壳单元）
    elseif startsWith(Ele_type, 'S')
        switch Ele_type{1}
            case {'S4', 'S4R'}
                node_number = 4;  % 4节点的板壳单元
            case {'S8', 'S8R', 'SC8R'}
                node_number = 8;  % 8节点的板壳单元
            case 'S3'
                node_number = 3;  % 3节点的板壳单元
            otherwise
                error('未知的板壳单元类型: %s', Ele_type);
        end
        
    % 判断单元类型是否以 'B' 开头（梁单元）
    elseif startsWith(Ele_type, 'B')
        switch Ele_type{1}
            case 'B32'
                node_number = 3;  % 3节点的梁单元
            otherwise
                error('未知的梁单元类型: %s', Ele_type);
        end
        
    else
        error('未知的单元类型: %s', Ele_type);
    end
end


end

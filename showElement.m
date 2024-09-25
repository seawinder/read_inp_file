function showElement(node, elem, elem_type)
    % showElement 根据 elem_type 自动选择合适的显示函数
    
    if contains(elem_type, 'C3D8') || contains(elem_type, 'C3D20') || contains(elem_type, 'SC8')
        showSolidElements(node, elem);  % 调用固体单元的显示函数
    elseif contains(elem_type, 'S4') || contains(elem_type, 'S8')
        showShellElements(node, elem);  % 调用板壳单元的显示函数
    else
        error('未知的单元类型: %s', elem_type);
    end
end



function showSolidElements(node, elem)
    % show_C3D8_C3D20_WithoutInnerFaces 绘制六面体单元，并隐藏重复面
    % node: n x 3 节点坐标矩阵 (x, y, z)
    % elem: m x 8 或 m x 20 六面体单元的节点连接
    tic
    % 定义六面体的 6 个面
    faces = [
        1 2 3 4;  % 面 1: 节点 1-2-3-4
        5 8 7 6;  % 面 2: 节点 5-8-7-6
        1 5 6 2;  % 面 3: 节点 1-5-6-2
        2 6 7 3;  % 面 4: 节点 2-6-7-3
        3 7 8 4;  % 面 5: 节点 3-7-8-4
        4 8 5 1   % 面 6: 节点 4-8-5-1
    ];

    % 如果是 C3D20 单元，只使用前8个节点
    if size(elem, 2) == 20
        elem = elem(:, 1:8);
    end

    % 初始化存储所有面的数组
    allFaces = [];

    % 遍历每个单元，获取单元的所有面
    for i = 1:size(elem, 1)
        nodesOfElem = elem(i, :);
        elemFaces = nodesOfElem(faces);  % 获取当前单元的所有面
        allFaces = [allFaces; elemFaces];  % 将面存入数组中
    end

    % 对所有面的节点进行排序，以便识别重复面（与顺序无关）
    sortedFaces = sort(allFaces, 2);

    % 使用 unique 找出唯一的面和重复的面
    [uniqueFaces, ~, idx] = unique(sortedFaces, 'rows', 'stable');
    faceCounts = accumarray(idx, 1);  % 计算每个面的出现次数

    % 找到重复的面，出现次数大于 1 的即为重复面
    duplicateFaces = uniqueFaces(faceCounts > 1, :);

    % 找到所有非重复面的索引
    nonDuplicateFaceIdx = ~ismember(sortedFaces, duplicateFaces, 'rows');

    % 准备用于绘制的非重复面
    visibleFaces = allFaces(nonDuplicateFaceIdx, :);

    % 使用 patch 一次性绘制所有非重复的面（无边界线，提升性能）
    figure;
    hold on;

    % 使用 patch 绘制四边形面，不显示边界线
    patch('Vertices', node, 'Faces', visibleFaces, ...
          'FaceColor', '[0.5 0.9 0.45]', 'EdgeColor', 'black', 'FaceAlpha', 0.5);

    hold off;
    axis equal;
    axis off;
    view(3);  % 3D 视图
    grid off;
    toc;
end



function showShellElements(node, elem)
    % showShellElements 绘制板壳单元 (S4R, S8R)
    % node: n x 3 节点坐标矩阵 (x, y, z)
    % elem: m x n 单元的节点连接

    % 检查 elem 中的节点编号是否超出 node 的范围
    maxNodeIndex = size(node, 1);
    if any(elem(:) > maxNodeIndex)
        error('elem 中的节点编号超出了 node 的范围');
    end

    % 绘制所有板壳单元的面
    figure;
    hold on;

    % 使用 patch 函数绘制板壳单元的面
    patch('Vertices', node, 'Faces', elem, ...
          'EdgeColor', 'black', 'FaceColor', 'cyan');  % 显示面，并将边设为黑色

    hold off;
    axis equal;
    axis off;
    view(3);  % 3D 视图
    grid off;
end

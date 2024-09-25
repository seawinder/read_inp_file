clc;clear;
close all;
Inp_filename = 'Job-2023-09-25.inp'; 

% 读取inp信息
node_eles_struct = Extract_node_eles_from_inp(Inp_filename);

% 节点坐标  和  单元节点连接
node = node_eles_struct(1).content(:,2:4);
elem = node_eles_struct(2).content(:,2:end);


% 提取单元类型
Ele_type = regexp(node_eles_struct(2).keyword, 'type=([\w\d]+)', 'tokens');
Ele_type = Ele_type{1};

% 绘制单元几何
showElement(node,elem,Ele_type)



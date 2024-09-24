function contentStruct = Extract_node_eles_from_inp(filename)
tic
% filename = 'Job-20231013.inp';  % Replace with your filename

% Read file content and create keywords for searching
fileContent = fileread(filename);
keywords = extractKeywordsFromInp(fileContent);

% Select keywords of interest through a dialog
selectedKeywords = selectKeywords(keywords);

% Display selected keywords and their line numbers
disp('用户选择的关键字及行号(按ctrl可多选)：');
arrayfun(@(x) fprintf('关键字: %s, 行号: %d\n', x.keyword, x.lineNumber), selectedKeywords);

% Extract content
contentStruct = extractContentBetweenKeywords(fileContent, keywords, selectedKeywords);


toc





function selectedKeywords = selectKeywords(keywords)
    keywordList = {keywords.keyword};
    
    % Popup multi-selection dialog
    [selected, ok] = listdlg('ListString', keywordList, ...
                             'SelectionMode', 'multiple', ...
                             'PromptString', '选择感兴趣的关键字:', ...
                             'ListSize', [300, 300]);
    
    if ok
        selectedKeywords = keywords(selected);  % Select only if 'OK' was pressed
    else
        selectedKeywords = [];  % Return empty if cancelled
    end
end


function keywords = extractKeywordsFromInp(fileContent)
    lines = strsplit(fileContent, '\n');  % Split content by lines
    isKeywordLine = startsWith(lines, '*') & cellfun(@(x) length(x) > 1 && isstrprop(x(2), 'upper'), lines);
    
    % Create a structured array for keywords
    lineNumbers = find(isKeywordLine);
    keywords = struct('keyword', strtrim(lines(isKeywordLine)), 'lineNumber', num2cell(lineNumbers));
end

function contentStruct = extractContentBetweenKeywords(fileContent, keywords, selectedKeywords)
    lines = strsplit(fileContent, '\n');
    numLines = length(lines);
    contentStruct = struct('keyword', {}, 'content', {});
    
    for i = 1:length(selectedKeywords)
        targetKeyword = selectedKeywords(i).keyword;
        targetIndex = selectedKeywords(i).lineNumber;
        
        % Determine node number based on the target keyword
        if contains(targetKeyword, 'Element')
            Ele_type = regexp(targetKeyword, 'type=([\w\d]+)', 'tokens');
            Ele_type = Ele_type{1};
            node_number = extractElementTypeNumber(Ele_type) + 1;
        else
            node_number = 4; % for *Node
        end
        
        % Find next keyword line number
        targetIndices = find(strcmp({keywords.keyword}, targetKeyword));
        nextKeywordLine = (isempty(targetIndices) || targetIndices(1) == length(keywords)) ...
                          * numLines + (targetIndices(1) < length(keywords)) * (keywords(targetIndices(1) + 1).lineNumber - 1);
        
        % Extract content between lines
        content = strtrim(lines(targetIndex + 1 : nextKeywordLine))';  
        contentWithoutCommas = strrep(content, ',', ' ');  
        
        % Convert to numeric array
        numericArray = cellfun(@str2num, contentWithoutCommas, 'UniformOutput', false);
        
        % Merge lines if necessary
        numericMatrix = mergeNumericLines(numericArray, node_number);
        
        % Add to the struct
        contentStruct(end + 1) = struct('keyword', targetKeyword, 'content', numericMatrix);
    end
end

function numericMatrix = mergeNumericLines(numericArray, node_number)
    numRows = length(numericArray);
    
    if numRows == 0
        numericMatrix = [];
        return;
    end
    
    if size(numericArray{1}, 2) < node_number && (numRows > 1 && size(numericArray{2}, 2) + size(numericArray{1}, 2) == node_number)
        % Combine odd and even rows
        combinedRows = arrayfun(@(row) [numericArray{row}, numericArray{row + 1}], 1:2:numRows-1, 'UniformOutput', false);
        numericMatrix = cell2mat(combinedRows);
    else
        numericMatrix = cell2mat(numericArray);
    end
end

function extractedNumbers = extractElementTypeNumber(elementTypes)
    extractedNumbers = zeros(size(elementTypes));
    for i = 1:length(elementTypes)
        matches = regexp(elementTypes{i}, '\d+', 'match');
        extractedNumbers(i) = str2double(matches{min(2, end)});
    end
end


end
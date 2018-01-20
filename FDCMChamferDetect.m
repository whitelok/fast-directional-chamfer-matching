function wins = FDCMChamferDetect(templateImgPath, matchingTargetImgPath, saveImgPath)
    if ~exist('templateImgPath','var')
        templateImgPath = 'DemoImg/template.png';
    end
    if ~exist('matchingTargetImgPath','var')
        matchingTargetImgPath = 'DemoImg/matching_target.jpg';
    end
    if ~exist('saveImgPath','var')
        saveImgPath = 'DemoImg/result.png';
    end
    
    disp('Fast Directional Chamfer Matching');
    
    templateImg = rgb2gray(imread(templateImgPath));
    matchingTargetImg = imread(matchingTargetImgPath);
    templateImgCannyEdge = edge(templateImg,'Canny',0.4);
    matchingTargetImgCannyEdge = edge(rgb2gray(matchingTargetImg),'Canny');

    saveImgName = saveImgPath;

    %//==================================================================
    %// Basic Configuration
    %//==================================================================
    templateEdgeMap = templateImgCannyEdge;

    query = matchingTargetImgCannyEdge;
    queryColor = matchingTargetImg;

    threshold = 0.12;
    lineMatchingPara = struct(...
        'NUMBER_DIRECTION',60,...
        'DIRECTIONAL_COST',0.5,...
        'MAXIMUM_EDGE_COST',30,...
        'MATCHING_SCALE',1.0,...
        'TEMPLATE_SCALE',0.6761,...
        'BASE_SEARCH_SCALE',1.20,...
        'MIN_SEARCH_SCALE',-7,...
        'MAX_SEARCH_SCALE',0,...
        'BASE_SEARCH_ASPECT',1.1,...
        'MIN_SEARCH_ASPECT',-1,...
        'MAX_SEARCH_ASPECT',1,...    
        'SEARCH_STEP_SIZE',2,...
        'SEARCH_BOUNDARY_SIZE',2,...
        'MIN_COST_RATIO',1.0...    
        );

    %//==================================================================
    %// Convert edge map into line representation
    %//==================================================================
    % Set the parameter for line fitting function
    lineFittingPara = struct(...
        'SIGMA_FIT_A_LINE',0.5,...
        'SIGMA_FIND_SUPPORT',0.5,...
        'MAX_GAP',2.0,...
        'N_LINES_TO_FIT_IN_STAGE_1',300,...
        'N_TRIALS_PER_LINE_IN_STAGE_1',100,...
        'N_LINES_TO_FIT_IN_STAGE_2',100000,...
        'N_TRIALS_PER_LINE_IN_STAGE_2',1);

    % convert the template edge map into a line representation
    [lineRep, lineMap] = mex_fitline(double(templateEdgeMap),lineFittingPara);

    % display the top few line segments to illustrate the representation
    nLine = size(lineRep,1);

    %//==================================================================
    %// FDCM detection
    %//==================================================================

    resultF = figure('visible', 'off');
    %hold on;
    %imshow(queryColor,[]);
    %title('Original image');

    % Set the parameter for line fitting function
    lineFittingPara2 = struct(...
        'SIGMA_FIT_A_LINE',0.5,...
        'SIGMA_FIND_SUPPORT',0.5,...
        'MAX_GAP',2.0,...
        'N_LINES_TO_FIT_IN_STAGE_1',0,...
        'N_TRIALS_PER_LINE_IN_STAGE_1',0,...
        'N_LINES_TO_FIT_IN_STAGE_2',100000,...
        'N_TRIALS_PER_LINE_IN_STAGE_2',1);

    template = cell(1);
    tempate{1} = lineRep;

    disp('Processing');

    [detWinds] = mex_fdcm_detect(double(query),tempate,threshold,...
        lineFittingPara2,lineMatchingPara);

    nDetection = size(detWinds,1);

    wins = double(zeros(min(nDetection,2), 6));

    disp('Wind ID (  x0 ,  y0 , width , height, cost, count )');
    for i=1:min(nDetection,2)
         wins(i, :) = [detWinds(i,1),detWinds(i,2),detWinds(i,3),detWinds(i,4),detWinds(i,5),detWinds(i,6)];
    end

    disp(wins);

    color = [0 1 0];
    lineWidth = 3;
    for i=1:size(detWinds)
        sx = detWinds(i,1);
        ex = sx + detWinds(i,3);
        sy = detWinds(i,2);
        ey = sy + detWinds(i,4);
        line([sx ex],[sy sy],'Color',color,'LineWidth',lineWidth);
        line([sx ex],[ey ey],'Color',color,'LineWidth',lineWidth);
        line([sx sx],[sy ey],'Color',color,'LineWidth',lineWidth);
        line([ex ex],[sy ey],'Color',color,'LineWidth',lineWidth);
    end

    print(resultF, '-djpeg', saveImgName);
    close(resultF);
    disp('Done.');
end

function varargout = PrecipitateTrend(varargin)
% PRECIPITATETREND MATLAB code for PrecipitateTrend.fig
%      PRECIPITATETREND, by itself, creates a new PRECIPITATETREND or raises the existing
%      singleton*.
%
%      H = PRECIPITATETREND returns the handle to a new PRECIPITATETREND or the handle to
%      the existing singleton*.
%
%      PRECIPITATETREND('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PRECIPITATETREND.M with the given input arguments.
%
%      PRECIPITATETREND('Property','Value',...) creates a new PRECIPITATETREND or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before PrecipitateTrend_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to PrecipitateTrend_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help PrecipitateTrend

% Last Modified by GUIDE v2.5 05-May-2015 10:30:34

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @PrecipitateTrend_OpeningFcn, ...
                   'gui_OutputFcn',  @PrecipitateTrend_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before PrecipitateTrend is made visible.
function PrecipitateTrend_OpeningFcn(hObject, eventdata, handles, varargin)
% Choose default command line output for PrecipitateTrend
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

handles.Barcode = varargin{1};
handles.TextonFeatures = varargin{2}; % data file
handles.Screen = varargin{3};
CondOccMats = varargin{4};
handles.CondOccL1 = CondOccMats{1};
handles.CondOccL2 = CondOccMats{2};
handles.CondOccL3 = CondOccMats{3};
handles.CondDict = varargin{5};
handles.DropRankingViewerHandles = varargin{6};
% handles.WellDrop = handles.DropRankingViewerHandles.WellDrop;
handles.ClearChangeTrend = [];
handles.ClearChangeMagnitude = [];
handles.ClearDrops = [];
handles.TimeChange = [];



% Popup and levels
handles.Level1 = [];
handles.Method = [];
handles.Summary = [];
handles.LabelsShort = [];

% default analysis: clear drops, Trend
handles.AnalyseThis = 'Clear'; %default
handles.ChosenSubwell = 'Trend'; % default, always start a Subwell A, 
handles.ClearDropThreshold = 0.5;
handles.TimeChangeThreshold = 0.5;
set(handles.BarcodeTxt, 'String', handles.Barcode);
handles.LastPopUpLevel = 1; % to keep track of which level



fh=get(0,'userdata');
handles.BarcodeInputCallback = fh.BarcodeInput;
axes(handles.axes2); % just to force the figure to pop up. 
set(handles.PleaseWait, 'String', 'Calculating change. Please wait...');
drawnow();

[scores, handles.EarliestFilepaths, handles.CurrentFilepaths] = CalculatePrecTrendScores(handles.TextonFeatures, handles.DropRankingViewerHandles);
ClearChangeTrend = scores(:,1);
Magnitude = scores(:,2);
clear data;
handles.ClearChangeTrend = ClearChangeTrend;
handles.ClearChangeMagnitude = Magnitude;
handles.ClearDrops = scores(:,3:5);
% Time change NOT IN OFFLINE VERSION
% handles.TimeChange = scores(:,6:8);


UpdatePlateOverview(handles);
set(handles.PleaseWait, 'String', '');


set(handles.popupmenu1, 'Value', 1);
guidata(hObject, handles);
popupmenu1_Callback(hObject, eventdata, handles);


% Update handles structure
guidata(hObject, handles);

function [PrecTrend, EarliestCalculatedFilepaths, CurrentFilepaths] = CalculatePrecTrendScores(TextonFeatures, DRVHandles)

PresentFeatures = TextonFeatures{2};
ClearScores = TextonFeatures{4};


% crudely: TextonLabel == 1:50 are for clear.
thres = 0.1;
ClearIdx = 1:50;
PresentFeatures_ClearProp = sum(PresentFeatures(:,ClearIdx),2)./sum(PresentFeatures,2);
PresentFeatures_ClearProp = reshape(PresentFeatures_ClearProp, 3, 96);
PresentFeatures_ClearProp = PresentFeatures_ClearProp';
FeatVecDiffAll = diff(PresentFeatures_ClearProp,1,2);
FeatVecDiff1_3 = diff(PresentFeatures_ClearProp(:,[1 3]),1,2);

Kink = FeatVecDiffAll(:,1) > thres & -FeatVecDiffAll(:,2) > thres;
DecreasePrec = FeatVecDiff1_3 > thres; %FeatVec4(:,1) > thres | FeatVec4(:,2) > thres;
IncreasePrec = -FeatVecDiff1_3 > thres;
Const = abs(FeatVecDiff1_3) < thres; %abs(FeatVec4(:,1)) < thres & abs(FeatVec4(:,2)) < thres;
temp = double([Kink DecreasePrec IncreasePrec Const]);

% Trend labels: Kink = '1', Decrease p. = '2', Increase p. = '3',
% ConstPrec = '4', ConstClear = '5'
for i = 1:size(temp,1)
    idx = find(temp(i,1:4) == 1, 1 );
    if ~isempty(idx)
        temp(i,5) = idx;
    else
        temp(i,5) = 0;
    end
end
%magnitude
temp(temp(:,5)==1,6) = max(abs(FeatVecDiffAll(temp(:,5)==1,:)),[],2); %kink
temp(temp(:,5)==2,6) = max(FeatVecDiffAll(temp(:,5)==2,:),[],2); %decrease prec
temp(temp(:,5)==3,6) = max(-FeatVecDiffAll(temp(:,5)==3,:),[],2); %increase prec
temp(temp(:,5)==4,6) = mean(PresentFeatures_ClearProp(temp(:,5)==4,:),2); %const
temp(temp(:,5)==4 & temp(:,6)>0.9, 5) = 5; %change const clear labels to 5.
temp(temp(:,5)==4,6) = 1 - temp(temp(:,5)==4,6); % invert magnitude for const precipitate. Larger for more precipitate.
PrecTrend = temp(:,5:6);
PrecTrend(isnan(PrecTrend)) = -1;
PrecTrend(:,3) = ClearScores(1:3:end);
PrecTrend(:,4) = ClearScores(2:3:end);
PrecTrend(:,5) = ClearScores(3:3:end);

EarliestCalculatedFilepaths = repmat({'MatFiles\Dummy.jpg'}, 288,1);
CurrentFilepaths = TextonFeatures{1};

% TIME CHANGE: NOT FOR OFFLINE VERSION
% if BarcodeAndInspection{2}-1 < 1
%     % first inspection selected
%     EarliestCalculatedInspection = 1;
%     EarliestCalculatedInspectionFeatures = getDataFromCRYSTAL({BarcodeAndInspection{1}, 1}, 'Features');
% else
%     for i = 1:BarcodeAndInspection{2}-1
% %         if BarcodeAndInspection{2}-1 == i
% %             EarliestCalculatedInspection = i;
% %             EarliestCalculatedInspectionFeatures = getDataFromCRYSTAL({BarcodeAndInspection{1}, i}, 'Features');
% %             % no prec change to show.
% %         else
%             EarliestCalculatedInspectionFeatures = getDataFromCRYSTAL({BarcodeAndInspection{1}, i}, 'Features');
%             if strcmp(EarliestCalculatedInspectionFeatures{1,1}, 'No Data')
%                 % move on
%             else
%                 EarliestCalculatedInspection = i;
%                 break;
%             end
% %         end
%     end
% end
% 
% if EarliestCalculatedInspection == BarcodeAndInspection{2}
%     % no trend to calculate.
%     PrecTrend(:,6:8) = 0.75;
%     FolderPath = ['\\minstrel3\pub\images\' BarcodeAndInspection{1} '\' num2str(BarcodeAndInspection{2})];
%     Filepaths = dir(FolderPath);
%     if isempty(Filepaths)
%         % Files not found on Minstrell 3
%         % Filepath to dummy file. 
%         CurrentFilepaths = repmat({'MatFiles_FUSCreens\BlankImage.jpg'}, 288,1);
%     else
%         %use SortFilesNoBarcode to make sure images are ordered properly -
%         %sometimes they do jumble up at the SGC.
%         CurrentFilepaths = cellfun(@(x) [FolderPath '\' x], SortFilesNoBarcode(Filepaths), 'UniformOutput', 0);
%     end
%     EarliestCalculatedFilepaths = repmat({'MatFiles_FUSCreens\BlankImage.jpg'}, 288,1);
% else
%     
%     FolderPath = ['\\minstrel3\pub\images\' BarcodeAndInspection{1} '\' num2str(EarliestCalculatedInspection)];
%     Filepaths = dir(FolderPath);
%     if isempty(Filepaths)
%         % Files not found on Minstrell 3
%         % Filepath to dummy file. 
%         EarliestCalculatedFilepaths = repmat({'MatFiles_FUSCreens\BlankImage.jpg'}, 288,1);
%     else
%         %Get file paths of images - earliest calculated
%         %use SortFilesNoBarcode to make sure images are ordered properly -
%         %sometimes they do jumble up at the SGC.
%         EarliestCalculatedFilepaths = cellfun(@(x) [FolderPath '\' x], SortFilesNoBarcode(Filepaths), 'UniformOutput', 0);
%     end
%     
%     FolderPath = ['\\minstrel3\pub\images\' BarcodeAndInspection{1} '\' num2str(BarcodeAndInspection{2})];
%     Filepaths = dir(FolderPath);
%     if isempty(Filepaths)
%         % Files not found on Minstrell 3
%         % Filepath to dummy file. 
%         CurrentFilepaths = repmat({'MatFiles_FUSCreens\BlankImage.jpg'}, 288,1);
%     else
%         %use SortFilesNoBarcode to make sure images are ordered properly -
%         %sometimes they do jumble up at the SGC.
%         CurrentFilepaths = cellfun(@(x) [FolderPath '\' x], SortFilesNoBarcode(Filepaths), 'UniformOutput', 0);
%     end
%    
%     EarliestCalculatedInspectionFeatures = ConvertFeatureStringToMatrix(EarliestCalculatedInspectionFeatures(:,1));
%     EarliestCalculatedInspectionFeatures = EarliestCalculatedInspectionFeatures + 10e-6;
%     PresentFeatures = getDataFromCRYSTAL(BarcodeAndInspection, 'Features'); % redo - add noise this time
%     PresentFeatures = ConvertFeatureStringToMatrix(PresentFeatures(:,1));
%     PresentFeatures = PresentFeatures + 10e-6;
%     
%     DropletDistances = Plate2PlateDist(PresentFeatures,EarliestCalculatedInspectionFeatures, 'Hellinger');
%     PrecTrend(:,6) = DropletDistances(1:3:end);
%     PrecTrend(:,7) = DropletDistances(2:3:end);
%     PrecTrend(:,8) = DropletDistances(3:3:end);
% %     PrecTrend(isnan(PrecTrend(:,2)),1) = 0;
% %     PrecTrend(isnan(PrecTrend(:,2)),2) = 0.75;

% end


function FeatureMatrix = ConvertFeatureStringToMatrix(FeatureString)
FeatureMatrix = zeros(size(FeatureString,1),300);
SplittableRows = cellfun(@(x) length(x) == 900, FeatureString); 
FeatureString = FeatureString(SplittableRows,:);

if isempty(FeatureString)
    FeatureMatrix = []; 
else
    FeatureString = cellfun(@(x) mat2cell(x,1,3*ones(300,1)), FeatureString, 'UniformOutput', 0);
    FeatureString = cellfun(@(x) base2dec(x,36)', FeatureString, 'UniformOutput', 0);
    FeatureMatrix(SplittableRows,:) = cell2mat(FeatureString);
end

function UpdatePlateOverview(handles)
switch handles.AnalyseThis
    case 'Clear'
        LegendText = sprintf(['Green: Clear \n'...
            'Red: Not clear \n\n'...
            'Click on squares to see the change in the droplet \n']);
        
        switch handles.ChosenSubwell
           
            case 'A'
                ColorCode = handles.ClearDrops(:,1);
                ColorCode(handles.ClearDrops(:,1) >= handles.ClearDropThreshold) = 2; %green
                ColorCode(handles.ClearDrops(:,1) < handles.ClearDropThreshold) = 3;% red
                Magnitude = repmat(0.75, length(ColorCode),1);
            case 'C'
                ColorCode = handles.ClearDrops(:,2);
                ColorCode(handles.ClearDrops(:,2) >= handles.ClearDropThreshold) = 2; %green
                ColorCode(handles.ClearDrops(:,2) < handles.ClearDropThreshold) = 3;% red
                Magnitude = repmat(0.75, length(ColorCode),1);
            case 'D'
                ColorCode = handles.ClearDrops(:,3);
                ColorCode(handles.ClearDrops(:,3) >= handles.ClearDropThreshold) = 2; %green
                ColorCode(handles.ClearDrops(:,3) < handles.ClearDropThreshold) = 3;% red
                Magnitude = repmat(0.75, length(ColorCode),1);
            case 'Trend'
                ColorCode = handles.ClearChangeTrend;
                Magnitude = handles.ClearChangeMagnitude;
                LegendText = sprintf(['See figure legend for colour code. \n\n'...
                    'Size of squares indicate magnitude of change of precipitation \n'...
                    'across the three subwells. \n'...
                    'Click on squares to see the change in the droplet \n']);
                
        end
    case 'Change'
        LegendText = sprintf(['Green: Change \n'...
            'Red: No Change \n\n'...
            'Size of squares indicate magnitude of change for the drop \n'...
            'from this inspection to earliest calculated inspection. \n'...
            'Click on squares to see the change in the droplet \n']);
        switch handles.ChosenSubwell
            case 'A'
                ColorCode = handles.TimeChange(:,1);
                ColorCode(handles.TimeChange(:,1) >= handles.TimeChangeThreshold) = 2; %green
                ColorCode(handles.TimeChange(:,1) < handles.TimeChangeThreshold) = 3;% red
                Magnitude = handles.TimeChange(:,1);
            case 'C'
                ColorCode = handles.TimeChange(:,2);
                ColorCode(handles.TimeChange(:,2) >= handles.TimeChangeThreshold) = 2; %green
                ColorCode(handles.TimeChange(:,2) < handles.TimeChangeThreshold) = 3;% red
                Magnitude = handles.TimeChange(:,2);
            case 'D'
                ColorCode = handles.TimeChange(:,3);
                ColorCode(handles.TimeChange(:,3) >= handles.TimeChangeThreshold) = 2; %green
                ColorCode(handles.TimeChange(:,3) < handles.TimeChangeThreshold) = 3;% red
                Magnitude = handles.TimeChange(:,3);
        end

end



c = [51 51 204; % blue - kink
    75 250 75; % green - decrease prec
    224 51 51; % red - increase prec
    0 0 0; % black - const prec
    224 224 0; % yellow - const clear
    224 224 224]/255; % white - unkwown

    ColorCode(ColorCode == 0) = 6;
    ColorCode = reshape(ColorCode, 8,12);
    Magnitude = reshape(Magnitude,8,12);
    Magnitude(Magnitude == 0 | Magnitude == -1) = 0.05;
     
    cla(handles.axes2);
    axes(handles.axes2);
    set(handles.axes2, 'ButtonDownFcn', {@axes2_ButtonDownFcn, handles});
        
    axis equal; axis tight;
    set(gca, 'XLim', [1 13]);
    set(gca, 'XTick',1:12);
    set(gca, 'XTickLabel',{'1';'2';'3';'4';'5';'6';'7';...
        '8';'9';'10';'11';'12'});
    set(gca, 'YLim', [1 9]);
    set(gca, 'YTick', 1:8);
    set(gca, 'YTickLabel', {'H';  'G';  'F';  'E';  'D'; ...
        'C';  'B';  'A'});

    for j = 1:12
        for i = 1:8
            h = rectangle('Position', [j,9-i,Magnitude(i,j), Magnitude(i,j)], 'Curvature', [0,0], 'FaceColor', c(ColorCode(i,j),:));
            set(h, 'HitTest', 'off');
            hold on;
        end
    end
    hold off;
    set(handles.text1, 'String', LegendText);

% --- Outputs from this function are returned to the command line.
function varargout = PrecipitateTrend_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;

% --- Executes on mouse press over axes background.
function axes2_ButtonDownFcn(hObject, eventdata, handles)
handles =guidata(hObject);
coordinates = get(hObject, 'CurrentPoint');
coordinates = coordinates(1,1:2);
Col = floor(coordinates(1));
Row = 9-floor(coordinates(2));
if strcmp(handles.AnalyseThis, 'Clear') && strcmp(handles.ChosenSubwell, 'Trend')
    % different show
    axes(handles.axes3); axis off; set(allchild(handles.axes3),'visible', 'off');
    axes(handles.axes4); axis off; set(allchild(handles.axes4),'visible', 'off');
    set(allchild(handles.AxA), 'Visible', 'on');
    set(allchild(handles.AxC), 'Visible', 'on');
    set(allchild(handles.AxD), 'Visible', 'on');
    Idx = (Col-1)*24 + (Row-1)*3 + 1; % subwell A
    axes(handles.AxA); imshow(permute(imread(handles.CurrentFilepaths{Idx}), [2 1 3]));
    axes(handles.AxC); imshow(permute(imread(handles.CurrentFilepaths{Idx+1}), [2 1 3]));
    axes(handles.AxD); imshow(permute(imread(handles.CurrentFilepaths{Idx+2}), [2 1 3]));
else
    axes(handles.AxA); axis off; set(allchild(handles.AxA), 'visible', 'off');
    axes(handles.AxC); axis off; set(allchild(handles.AxC), 'visible', 'off');
    axes(handles.AxD); axis off; set(allchild(handles.AxD), 'visible', 'off');
    set(allchild(handles.axes3), 'Visible', 'on');
    set(allchild(handles.axes4), 'Visible', 'on');
    
    switch handles.ChosenSubwell
            case 'A'
                Subwell = 1;
            case 'C'
                Subwell = 2;
            case 'D'
                Subwell = 3;
    end
    Idx = (Col-1)*24 + (Row-1)*3 + Subwell;
    axes(handles.axes3); imshow(imread(handles.EarliestFilepaths{Idx}));
    axes(handles.axes4); imshow(imread(handles.CurrentFilepaths{Idx}));
end


% --- Executes on selection change in popupmenu1.
function popupmenu1_Callback(hObject, eventdata, handles)
handles.LastPopUpLevel = 1;
switch handles.AnalyseThis
    case 'Clear'
        switch handles.ChosenSubwell
            case 'A'
                Input = handles.ClearDrops(:,1);
                Input(handles.ClearDrops(:,1) >= handles.ClearDropThreshold) = 2; %green
                Input(handles.ClearDrops(:,1) < handles.ClearDropThreshold) = 3;% red
            case 'C'
                Input = handles.ClearDrops(:,2);
                Input(handles.ClearDrops(:,2) >= handles.ClearDropThreshold) = 2; %green
                Input(handles.ClearDrops(:,2) < handles.ClearDropThreshold) = 3;% red
            case 'D'
                Input = handles.ClearDrops(:,3);
                Input(handles.ClearDrops(:,3) >= handles.ClearDropThreshold) = 2; %green
                Input(handles.ClearDrops(:,3) < handles.ClearDropThreshold) = 3;% red
            case 'Trend'
                Input = handles.ClearChangeTrend;
        end
    case 'Change'
        switch handles.ChosenSubwell
            case 'A'
                Input = handles.TimeChange(:,1);
                Input(handles.TimeChange(:,1) >= handles.TimeChangeThreshold) = 2; %green
                Input(handles.TimeChange(:,1) < handles.TimeChangeThreshold) = 3;% red
            case 'C'
                Input = handles.TimeChange(:,2);
                Input(handles.TimeChange(:,2) >= handles.TimeChangeThreshold) = 2; %green
                Input(handles.TimeChange(:,2) < handles.TimeChangeThreshold) = 3;% red
            case 'D'
                Input = handles.TimeChange(:,3);
                Input(handles.TimeChange(:,3) >= handles.TimeChangeThreshold) = 2; %green
                Input(handles.TimeChange(:,3) < handles.TimeChangeThreshold) = 3;% red
        end

end


handles.Level1 = get(handles.popupmenu1, 'Value');
switch handles.Level1
    case 1 %pH
        AnalyseConditions(hObject, eventdata, handles, Input, 1, 'pH');
        set(handles.MethodList, 'Enable', 'off');
        set(handles.MethodList, 'value', 1);
        set(handles.MethodList, 'string', {''});
        set(handles.Level3List, 'Enable', 'off');
        set(handles.Level3List, 'string', {''});
        set(handles.Level3List, 'value', 1);
    case 2 %Polymer
        Labels = AnalyseConditions(hObject, eventdata, handles, Input, 1, 'Polymer');
        set(handles.MethodList, 'Enable', 'on');
        set(handles.MethodList, 'value', 1);
        set(handles.MethodList, 'string', Labels);
        set(handles.Level3List, 'Enable', 'off');
        set(handles.Level3List, 'string', {''});
        set(handles.Level3List, 'value', 1);
    case 3 % Organic
        AnalyseConditions(hObject, eventdata, handles, Input, 2, 'Organic');
        set(handles.MethodList, 'Enable', 'on');
        set(handles.MethodList, 'value', 1);
        set(handles.MethodList, 'string', handles.CondOccL3('OrganicLabels'));
        set(handles.Level3List, 'Enable', 'off');
        set(handles.Level3List, 'string', {''});
        set(handles.Level3List, 'value', 1);
    case 4 %Salt
        AnalyseConditions(hObject, eventdata, handles, Input, 1, 'Salt');
        set(handles.MethodList, 'Enable', 'on');
        set(handles.MethodList, 'value', 1);
        Labels = {'Cation'; 'Anion'; 'Salt'};
        set(handles.MethodList, 'string', Labels);
        set(handles.Level3List, 'Enable', 'off');
        set(handles.Level3List, 'string', {''});
        set(handles.Level3List, 'value', 1);
    case 5 %Buffer
        Labels = AnalyseConditions(hObject, eventdata, handles, Input, 2, 'Buffer');
        set(handles.MethodList, 'Enable', 'on');
        set(handles.MethodList, 'value', 1);
        set(handles.MethodList, 'string', Labels);
        set(handles.Level3List, 'Enable', 'off');
        set(handles.Level3List, 'string', {''});
        set(handles.Level3List, 'value', 1);
%         load handles.PrecTrend/JCSGhandles.CondDict.mat;
end
guidata(hObject, handles);


% --- Executes on selection change in MethodList.
function MethodList_Callback(hObject, eventdata, handles)
handles.LastPopUpLevel = 2;
contents = cellstr(get(handles.MethodList,'String')); 
ChosenIndex = get(handles.MethodList,'Value');
handles.Method = contents{ChosenIndex};
switch handles.AnalyseThis
    case 'Clear'
        switch handles.ChosenSubwell
            case 'A'
                Input = handles.ClearDrops(:,1);
                Input(handles.ClearDrops(:,1) >= handles.ClearDropThreshold) = 2; %green
                Input(handles.ClearDrops(:,1) < handles.ClearDropThreshold) = 3;% red
            case 'C'
                Input = handles.ClearDrops(:,2);
                Input(handles.ClearDrops(:,2) >= handles.ClearDropThreshold) = 2; %green
                Input(handles.ClearDrops(:,2) < handles.ClearDropThreshold) = 3;% red
            case 'D'
                Input = handles.ClearDrops(:,3);
                Input(handles.ClearDrops(:,3) >= handles.ClearDropThreshold) = 2; %green
                Input(handles.ClearDrops(:,3) < handles.ClearDropThreshold) = 3;% red
            case 'Trend'
                Input = handles.ClearChangeTrend;
        end
    case 'Change'
        switch handles.ChosenSubwell
            case 'A'
                Input = handles.TimeChange(:,1);
                Input(handles.TimeChange(:,1) >= handles.TimeChangeThreshold) = 2; %green
                Input(handles.TimeChange(:,1) < handles.TimeChangeThreshold) = 3;% red
            case 'C'
                Input = handles.TimeChange(:,2);
                Input(handles.TimeChange(:,2) >= handles.TimeChangeThreshold) = 2; %green
                Input(handles.TimeChange(:,2) < handles.TimeChangeThreshold) = 3;% red
            case 'D'
                Input = handles.TimeChange(:,3);
                Input(handles.TimeChange(:,3) >= handles.TimeChangeThreshold) = 2; %green
                Input(handles.TimeChange(:,3) < handles.TimeChangeThreshold) = 3;% red
        end

end
switch handles.Level1
    case 2 %Polymer
        if ChosenIndex < length(contents)  % Do nothing if it's NoPolymer
            Labels = AnalyseConditions(hObject, eventdata, handles, Input, 2, handles.Method);
            set(handles.Level3List, 'Enable', 'on');
            set(handles.Level3List, 'value', 1);
            set(handles.Level3List, 'string', Labels);
        else
            set(handles.Level3List, 'Enable', 'off');
            set(handles.Level3List, 'value', 1);
            set(handles.Level3List, 'string', {''});
        end
    case 3 % Organic
        AnalyseConditions(hObject, eventdata, handles, Input, 3, 'Organic', handles.Method);
        set(handles.Level3List, 'Enable', 'off');
        set(handles.Level3List, 'value', 1);
        set(handles.Level3List, 'string', {''});
    case 4 %Salt
        if ChosenIndex < length(contents)  % Do nothing if it's No Salt
            Labels = AnalyseConditions(hObject, eventdata, handles, Input, 2, handles.Method);
            set(handles.Level3List, 'Enable', 'on');
            set(handles.Level3List, 'value', 1);
            set(handles.Level3List, 'string', Labels);
        else
            set(handles.Level3List, 'Enable', 'on');
            set(handles.Level3List, 'value', 1);
            set(handles.Level3List, 'String', handles.CondOccL3([handles.Method 'Labels']));
        end
    case 5 %Buffer
        AnalyseConditions(hObject, eventdata, handles, Input, 3, 'Buffer', handles.Method);
        set(handles.Level3List, 'Enable', 'off');
        set(handles.Level3List, 'value', 1);
        set(handles.Level3List, 'string', {''});
end
guidata(hObject, handles);


% --- Executes on selection change in Level3List.
function Level3List_Callback(hObject, eventdata, handles)
handles.LastPopUpLevel = 3;
contents = cellstr(get(handles.Level3List,'String')); 
Chem = contents{get(handles.Level3List,'Value')};
switch handles.AnalyseThis
    case 'Clear'
        switch handles.ChosenSubwell
            case 'A'
                Input = handles.ClearDrops(:,1);
                Input(handles.ClearDrops(:,1) >= handles.ClearDropThreshold) = 2; %green
                Input(handles.ClearDrops(:,1) < handles.ClearDropThreshold) = 3;% red
            case 'C'
                Input = handles.ClearDrops(:,2);
                Input(handles.ClearDrops(:,2) >= handles.ClearDropThreshold) = 2; %green
                Input(handles.ClearDrops(:,2) < handles.ClearDropThreshold) = 3;% red
            case 'D'
                Input = handles.ClearDrops(:,3);
                Input(handles.ClearDrops(:,3) >= handles.ClearDropThreshold) = 2; %green
                Input(handles.ClearDrops(:,3) < handles.ClearDropThreshold) = 3;% red
            case 'Trend'
                Input = handles.ClearChangeTrend;
        end
    case 'Change'
        switch handles.ChosenSubwell
            case 'A'
                Input = handles.TimeChange(:,1);
                Input(handles.TimeChange(:,1) >= handles.TimeChangeThreshold) = 2; %green
                Input(handles.TimeChange(:,1) < handles.TimeChangeThreshold) = 3;% red
            case 'C'
                Input = handles.TimeChange(:,2);
                Input(handles.TimeChange(:,2) >= handles.TimeChangeThreshold) = 2; %green
                Input(handles.TimeChange(:,2) < handles.TimeChangeThreshold) = 3;% red
            case 'D'
                Input = handles.TimeChange(:,3);
                Input(handles.TimeChange(:,3) >= handles.TimeChangeThreshold) = 2; %green
                Input(handles.TimeChange(:,3) < handles.TimeChangeThreshold) = 3;% red
        end

end
switch handles.Level1
    case 2 %Polymer
        AnalyseConditions(hObject, eventdata, handles, Input, 3, 'Polymer', Chem);
        
    case 4 %Salt
        if strcmp(handles.Method, 'Anion') || strcmp(handles.Method, 'Cation')
            AnalyseConditions(hObject, eventdata, handles, Input, 3, 'Ion', Chem);
        else
            AnalyseConditions(hObject, eventdata, handles, Input, 3, 'Salt', Chem);
        end
end
guidata(hObject, handles);

function Labels = AnalyseConditions(hObject, eventdata, handles, PrecTrend, Level, method, Chem, DrawPlot)
if nargin < 8
    DrawPlot = 1;
end

if Level == 1
    switch method
        case 'pH'
            Labels = handles.CondOccL1('pHLabels');
        case 'Polymer'
            Labels = handles.CondOccL1('PolymerLabels');
        case 'Organic'
            Labels = handles.CondOccL1('OrganicLabels');
        case 'Salt'
            Labels = handles.CondOccL1('SaltLabels');
    end
    if DrawPlot
        PlotHistograms(hObject, eventdata, handles, Labels, handles.CondOccL1, PrecTrend);
        %Fill up tables
%         set(handles.ClearRB,'Value',0);
%         set(handles.ClearAllRB,'Value', 0);
%         set(handles.ClearTotalRB, 'Value', 0);
%         set(handles.MultipliedRB, 'Value', 0);
%         set(handles.uitable2, 'data', Summary{1});
%         set(handles.uitable2, 'RowName', LabelsShort);
%         set(handles.uitable3, 'data', Summary{2});
%         set(handles.uitable3, 'RowName', LabelsShort);
%         set(handles.uitable4, 'data', Summary{3});
%         set(handles.uitable4, 'RowName', LabelsShort);
    else
%         [Summary LabelsShort] = Summarize(hObject, eventdata, handles, Labels, handles.CondOccL1, PrecTrend);
    end
    
    
elseif Level == 2
    switch method
        case 'PEG'
            Labels = handles.CondOccL2('PEGLabels');
        case 'NotPEG'
            Labels = handles.CondOccL2('NotPEGLabels');
        case 'Organic'
            Labels = handles.CondOccL2('OrganicLabels');
        case 'Cation'
            Labels = handles.CondOccL2('CationLabels');
        case 'Anion'
            Labels = handles.CondOccL2('AnionLabels');
        case 'Buffer'
            Labels = handles.CondOccL2('BufferLabels');
        
    end
    if DrawPlot
        PlotHistograms(hObject, eventdata, handles, Labels, handles.CondOccL2, PrecTrend);
%         set(handles.ClearRB,'Value',0);
%         set(handles.ClearAllRB,'Value', 0);
%         set(handles.ClearTotalRB, 'Value', 0);
%         set(handles.MultipliedRB, 'Value', 0);
%         set(handles.uitable2, 'data', Summary{1});
%         set(handles.uitable2, 'RowName', LabelsShort);
%         set(handles.uitable3, 'data', Summary{2});
%         set(handles.uitable3, 'RowName', LabelsShort);
%         set(handles.uitable4, 'data', Summary{3});
%         set(handles.uitable4, 'RowName', LabelsShort);
    else
%         [Summary LabelsShort] = Summarize(hObject, eventdata, handles, Labels, handles.CondOccL2, PrecTrend);
    end
   
    
elseif Level == 3
    if strcmp(method, 'Ion')
        ChemGroup = {handles.CondDict.Salt};
    else
        ChemGroup = {handles.CondDict.(method)}';
    end
    
    if strcmp(method, 'Buffer')
        ChemGroupUnits = {handles.CondDict.pH}';
        ChemGroupUnits = cellfun(@num2str, ChemGroupUnits, 'UniformOutput', false);
    elseif strcmp(method, 'Ion')
        ChemGroupUnits = {handles.CondDict.Salt}';
    else
        GroupUnit = [method 'Unit'];
        ChemGroupUnits = {handles.CondDict.(GroupUnit)}';
        ChemGroupUnits = cellfun(@num2str, ChemGroupUnits, 'UniformOutput', false);
    end
    
    if ~strcmp(method, 'Ion')
        ChemIdx = strcmp(ChemGroup, Chem);
        ChemIdx2 = ~cellfun(@isempty, regexp(ChemGroup, [', ' Chem '|' Chem ', ']));
        ChemIdx = ChemIdx | ChemIdx2;
        InList = ChemGroupUnits(ChemIdx);
        InList = DeCommaChemGroupUnits(InList, ChemGroup(ChemIdx), Chem);
    else
        ChemIdx = ~cellfun(@isempty, strfind(ChemGroup, Chem));
        InList = ChemGroupUnits(ChemIdx);
    end
    
    
    
    temp = FindChemInScreen(InList, InList, Chem);
%     ChemIdx = ExpandChemIdx(ChemIdx); %expand 96 conditions to cover all 3 subwells
    if ~strcmp(method, 'Ion') && DrawPlot
        PlotHistograms(hObject, eventdata, handles, temp(Chem),temp, PrecTrend(ChemIdx));
    elseif strcmp(method, 'Ion') && DrawPlot 
        % Clear off any labels without the ion involved
        tempLabels = temp(Chem);
        idx = ~cellfun(@isempty, strfind(tempLabels, Chem));
        PlotHistograms(hObject, eventdata, handles, tempLabels(idx),temp, PrecTrend(ChemIdx));
    end
    %     end
    
end

function Decommaed = DeCommaChemGroupUnits(InList, ConditionsWithChem, Chem)
commaidx = cellfun(@isempty, strfind(InList, ','), 'UniformOutput', false);
commaidx = cell2mat(commaidx);
commaidx = ~commaidx;
if ~sum(commaidx) % nothing to separate
    Decommaed = InList;
else
    SplitChem = cellfun(@(x) regexp(x, ',', 'split'), ConditionsWithChem(commaidx), 'UniformOutput', false);
    SplitUnits = cellfun(@(x) regexp(x, ',', 'split'), InList(commaidx), 'UniformOutput', false);
    SplitChem = cellfun(@strtrim, SplitChem,'UniformOutput', false);
    SplitUnits = cellfun(@strtrim, SplitUnits, 'UniformOutput', false);
    for i = 1:length(SplitChem)
        ChemIdx = ~cellfun(@isempty, strfind(SplitChem{i}, Chem));
        if sum(ChemIdx)> 1  % If more than 2 copies found - ie PEG10000 and PEG1000, be more stringent
            ChemIdx = cellfun(@(x) strcmp(x, Chem), SplitChem{i});
        end
        SplitUnits{i} = strtrim(SplitUnits{i}{ChemIdx});
    end
    Decommaed = InList;
    Decommaed(commaidx) = SplitUnits;
end

function LabelsShort = PlotHistograms(hObject, eventdata, handles, Labels, CondOcc, Idxes, ProduceFigure)
%uses xticklabel_rotate, downloaded from
%'http://www.mathworks.com/matlabcentral/fileexchange/3486-xticklabelrotate/
% content/xticklabel_rotate.m'
if nargin<7
    ProduceFigure = 1;
end
switch handles.AnalyseThis
    case 'Clear'
        if strcmp(handles.ChosenSubwell, 'Trend')
            LegendLabels = {'ConstClear', 'Decrease P', 'Increase P', 'ConstPrec', 'Kinks', 'Unknown'};
        else
            LegendLabels = {'Clear', 'Not Clear', 'Unknown'};
        end
    case 'Change'
        LegendLabels = {'Change', 'No Change', 'Unknown'};
end

LabelsShort = Labels;
LabelsLength = cellfun('length', Labels);
LabelsLength = LabelsLength > 10;
for i = 1:length(Labels)
    if LabelsLength(i)
        LabelsShort{i} = Labels{i}(1:10);
    end
end

if ~strcmp(handles.ChosenSubwell, 'Trend')
    Kinks = (Idxes == 1)';
    Decrease = (Idxes == 2)';
    Increase = (Idxes == 3)';
    ConstPrec = (Idxes == 4)';
    ConstClear = (Idxes == 5)';
    Unknowns = (Idxes == 0)';
    
    yKinks = zeros(length(Labels),1);
    yDecrease = yKinks; TotalInCategory = yKinks;
    yIncrease = yKinks; yConstPrec = yKinks; yConstClear = yKinks; yUnknowns = yKinks;
    
    
    for i = 1:length(Labels)
        yDecrease(i,:) = sum(Decrease & CondOcc(Labels{i})',2)';
        yIncrease(i,:) = sum(Increase & CondOcc(Labels{i})',2)';
        yUnknowns(i,:) = sum(Unknowns & CondOcc(Labels{i})',2)';
        TotalInCategory(i,:) = repmat(sum(CondOcc(Labels{i})), 1, 1);
    end
    
  
    
    if ProduceFigure
        if length(Labels) > 1
            bar(handles.axes1, [yDecrease yIncrease yUnknowns]);
            set(handles.axes1,'Xtick',1:length(Labels),'XTickLabel',Labels);
            rotateXLabels(handles.axes1, 30);
            legend(handles.axes1, LegendLabels);
            
            
        else
            bar(handles.axes1, [yConstClear yDecrease yIncrease yConstPrec yKinks yUnknowns; 0 0 0 0 0 0]); % Pad with zeros to give grouping effect on bar chart
            set(handles.axes1,'Xtick',1:length(Labels),'XTickLabel',Labels);
            rotateXLabels(handles.axes1, 30);
            legend(handles.axes1,LegendLabels);
            
        end
    end
    
    c = [%1 1 0; ...Const Clear - yellow
        75 250 75; ...Decrease p. - green
        224 51 51; ...Increase p. - red
        %0 0 0; ...Const P. - black
        %0 0 1; ...blue - kink
        224 224 224] / 255; ...unknonw - white
        
    colormap(c);
else
    Kinks = (Idxes == 1)';
    Decrease = (Idxes == 2)';
    Increase = (Idxes == 3)';
    ConstPrec = (Idxes == 4)';
    ConstClear = (Idxes == 5)';
    Unknowns = (Idxes == 0)';
    
    yKinks = zeros(length(Labels),1);
    yDecrease = yKinks; TotalInCategory = yKinks;
    yIncrease = yKinks; yConstPrec = yKinks; yConstClear = yKinks; yUnknowns = yKinks;
    
    
    for i = 1:length(Labels)
        yKinks(i,:) = sum(Kinks & CondOcc(Labels{i})',2)';
        yDecrease(i,:) = sum(Decrease & CondOcc(Labels{i})',2)';
        yIncrease(i,:) = sum(Increase & CondOcc(Labels{i})',2)';
        yConstPrec(i,:) = sum(ConstPrec & CondOcc(Labels{i})',2)';
        yConstClear(i,:) = sum(ConstClear & CondOcc(Labels{i})',2)';
        yUnknowns(i,:) = sum(Unknowns & CondOcc(Labels{i})',2)';
        TotalInCategory(i,:) = repmat(sum(CondOcc(Labels{i})), 1, 1);
    end
   
    
    if ProduceFigure
        if length(Labels) > 1
            bar(handles.axes1, [yConstClear yDecrease yIncrease yConstPrec yKinks yUnknowns]);
            set(handles.axes1,'Xtick',1:length(Labels),'XTickLabel',Labels);
            rotateXLabels(handles.axes1, 30);
            legend(handles.axes1, LegendLabels);

        else
            bar(handles.axes1, [yConstClear yDecrease yIncrease yConstPrec yKinks yUnknowns; 0 0 0 0 0 0]); % Pad with zeros to give grouping effect on bar chart
            set(handles.axes1,'Xtick',1:length(Labels),'XTickLabel',Labels);
            rotateXLabels(handles.axes1, 30);
            legend(handles.axes1,LegendLabels);
        end
    end
        
    c = [224 224 0; ...Const Clear - yellow
        75 250 75; ...Decrease p. - green
        224 51 51; ...Increase p. - red
        0 0 0; ...Const P. - black
        51 51 204; ...blue - kink
        224 224 224] / 255; ...unknonw - white
        
    colormap(c);
end

function IdxOut = ExpandChemIdx(IdxIn)
if size(IdxIn,1) ~= 1
    IdxIn = IdxIn'; %make sure it's a row vector
end
IdxOut = repmat(IdxIn, 3, 1);
IdxOut = IdxOut(:);


% --- Executes when selected object is changed in ConditionFunction.
function ConditionFunction_SelectionChangeFcn(hObject, eventdata, handles)
switch get(eventdata.NewValue, 'Tag')
    case 'RadioClear'
        handles.AnalyseThis = 'Clear';
        set(handles.Trend, 'Enable', 'on');
    case 'RadioChange'
        handles.AnalyseThis = 'Change';
        % if previously Trend was chosen, default to subwell A
        if strcmp(handles.ChosenSubwell, 'Trend')
            set(handles.SubwellA, 'Value', 1);
            handles.ChosenSubwell = 'A';
        end
        % hide trend button
        set(handles.Trend, 'Enable', 'off');
end
% set(handles.popupmenu1, 'Value', 1);
guidata(hObject, handles);
UpdatePlateOverview(handles);
switch handles.LastPopUpLevel 
    case 1
        popupmenu1_Callback(hObject, eventdata, handles);
    case 2
        MethodList_Callback(hObject, eventdata, handles)
    case 3
        Level3List_Callback(hObject, eventdata, handles)
end
% popupmenu1_Callback(hObject, eventdata, handles);

% --- Executes when selected object is changed in SubwellSelection.
function SubwellSelection_SelectionChangeFcn(hObject, eventdata, handles)
switch get(eventdata.NewValue, 'Tag')
    case 'SubwellA'
        handles.ChosenSubwell = 'A';
    case 'SubwellC'
        handles.ChosenSubwell = 'C';
    case 'SubwellD'
        handles.ChosenSubwell = 'D';
    case 'Trend'
        handles.ChosenSubwell = 'Trend';
end
guidata(hObject, handles);
UpdatePlateOverview(handles);
switch handles.LastPopUpLevel 
    case 1
        popupmenu1_Callback(hObject, eventdata, handles);
    case 2
        MethodList_Callback(hObject, eventdata, handles)
    case 3
        Level3List_Callback(hObject, eventdata, handles)
end




% ------------Create functions --------------------------------------- %
% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function MethodList_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function Level3List_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on mouse press over axes background.
function axes1_ButtonDownFcn(hObject, eventdata, handles)

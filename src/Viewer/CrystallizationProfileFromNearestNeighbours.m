function varargout = CrystallizationProfileFromNearestNeighbours(varargin)
% Last Modified by GUIDE v2.5 03-Jun-2015 11:40:00

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @CrystallizationProfileFromNearestNeighbours_OpeningFcn, ...
                   'gui_OutputFcn',  @CrystallizationProfileFromNearestNeighbours_OutputFcn, ...
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


% --- Executes just before CrystallizationProfileFromNearestNeighbours is made visible.
function CrystallizationProfileFromNearestNeighbours_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
handles.DropRankingViewerHandles = varargin{1};
% handles.Username = handles.DropRankingViewerHandles.Username;
% handles.Conn = handles.DropRankingViewerHandles.Conn;
% handles.CrystalConn = handles.DropRankingViewerHandles.CrystalConn;
handles.Barcode = handles.DropRankingViewerHandles.Barcode;
% handles.Inspection = handles.DropRankingViewerHandles.Inspection;
% handles.WellDrop = handles.DropRankingViewerHandles.WellDrop;
% color codes
handles.ConcentrationColours = [170 45 45; ... red
                                35 140 35]; % green
handles.TopTenConditionsTableSummary = cell(10,5);
handles.Profile = [];
handles.NavigateBarListener = [];

% Condition Tree
handles.Cockatoo_ClusterID = [];
load('MatFiles\RawConditions_Condensed.mat');
handles.RawConditions = RawConditions;
handles.RepeatConditionsID = [];
handles.OtherScreensSetUp = {};% NOT FOR OFFLINE VERSION

load('MatFiles\z_4Screens.mat');%z
load('MatFiles\ClusterIdx_4Screens_CockatooArrangement.mat'); % Cockatoo_ClusterID
load('MatFiles\RepeatConditionsID.mat'); %RepeatConditionsID
handles.Cockatoo_ClusterID = Cockatoo_ClusterID;
handles.RepeatConditionsID = RepeatConditionsID;
axes(handles.ConditionsTree);
h = dendrogram(z, 0, 'colorthreshold', 1.27, 'labels', repmat({''}, size(z,1)+1,1), ...
    'orientation', 'bottom');
set(h, 'LineWidth', 2);
set(handles.ConditionsTree, 'XTick', []);

% clear drop analysis
handles.CondOccL1 = [];
handles.CondOccL2 = [];
handles.CondOccL3 = [];
handles.CondDict = [];
handles.CondDictFull = [];
handles.ClearDropScores = [];


% Group conditions
handles.GroupConditions = 0;  % for now, two levels. 0 = none, 1 = group PEG conditions
handles.SummaryTableSelectedCell = [];
% handles.Iteration_ID = [];

fh=get(0,'userdata');
handles.BarcodeInputCallback = fh.BarcodeInput;
handles.UpdateDisplay = fh.UpdateDisplay;


% IndividualPLate profile
handles.NumNeighbours = 10; % by default
handles.CountLine = [];
load('MatFiles\ConditionPerm.mat');
load('MatFiles\IdenticalConditions.mat');
handles.ConditionPerm = ConditionPerm;
handles.IdenticalConditions = IdenticalConditions;
handles.DistancesToReferences = [];
handles.Top50Profiles = [];

handles.KeyPressFlag = 1; % to prevent UI from crashing when someone holds down a key.

if isempty(handles.NavigateBarListener)
    handles.NavigateBarListener = addlistener(handles.NeighboursToIncludeSlider, 'ContinuousValueChange', @(hObject, edata) UpdateSliderNumber(hObject, eventdata, handles));
else 
    try
        delete(handles.NavigateBarListener);
    catch err
        % do nothing
    end
    handles.NavigateBarListener = addlistener(handles.NeighboursToIncludeSlider, 'ContinuousValueChange', @(hObject, edata) UpdateSliderNumber(hObject, eventdata, handles));
end
set(handles.ScreenOfBarcode, 'String', sprintf('Select screen type of %s:', handles.Barcode));
drawnow();
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = CrystallizationProfileFromNearestNeighbours_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;

% ----------------------- Main Buttons ---------------------------------- %
% --- Executes on button press in GenerateProfile.
function GenerateProfile_Callback(hObject, eventdata, handles)
% (1) Loads TextonDist file produced by Ranker
% (2) Load library as specified by user
% (3) Calculate distance between new plate and plates in library
% (4) Plots profile for conditions that gave diffracting crystals
set(handles.ProfileFromNN, 'Pointer', 'watch');

NumNearestNeighbours = 100; % num neighbours to consider

% Get data from user input
ScreenID = get(handles.ScreenID, 'String');
ScreenID = ScreenID{get(handles.ScreenID, 'Value')};
if strcmp(ScreenID, 'Please Select:')
    errordlg('Please select one of these screens.', 'Select Screen');
end
Subwell1 = get(handles.Subwell1, 'String');
Subwell1 = Subwell1{get(handles.Subwell1, 'Value')};
if strcmp(Subwell1, 'Please Select:')
    errordlg('Please select ratio for Subwell 1.', 'Select Subwell Ratio');
end
Subwell2 = get(handles.Subwell1, 'String');
Subwell2 = Subwell2{get(handles.Subwell2, 'Value')};
if strcmp(Subwell2, 'Please Select:')
    errordlg('Please select ratio for Subwell 2.', 'Select Subwell Ratio');
end
Subwell3 = get(handles.Subwell1, 'String');
Subwell3 = Subwell3{get(handles.Subwell3, 'Value')};
if strcmp(Subwell3, 'Please Select:')
    errordlg('Please select ratio for Subwell 3.', 'Select Subwell Ratio');
end

% load data file
load(['Data\' handles.Barcode '.mat']); % variable name: TextonFeatures, generated by Ranker.exe
CalculatedFeatures = TextonFeatures{1,2};
set(handles.Status, 'String', 'Loading calculated features');
drawnow();
if mod(size(CalculatedFeatures,1), 96) ~= 0
    errdlg('Images are not in multiples of 96. Please check your calculated file', 'File Number Error');
    return;
else
    NumSubwells = size(CalculatedFeatures,1)/96;
    % rearrange Features to have 2:1, 1:1, 1:2 arrangement for each well.
    FeaturesRearranged = nan(288, 300);
    ClearScores = NaN(288,1);
    FaultyScores = NaN(288,1);
    FilePaths = repmat({'MatFiles\Dummy.jpg'}, 288,1);
    % find subwell with 2:1
    SubwellWith2To1Ratio = find(strcmp({Subwell1; Subwell2; Subwell3}, '2:1'));
    SubwellWith1To1Ratio = find(strcmp({Subwell1; Subwell2; Subwell3}, '1:1'));
    SubwellWith1To2Ratio = find(strcmp({Subwell1; Subwell2; Subwell3}, '1:2'));
    % rearrange file to keep to the standard 2:1, 1:1, 1:2 prot:prec ratio
    % arrangement. 
    if ~isempty(SubwellWith2To1Ratio)
        FeaturesRearranged(1:3:end,:) = CalculatedFeatures(SubwellWith2To1Ratio:NumSubwells:end,:);
        ClearScores(1:3:end) = TextonFeatures{5}(SubwellWith2To1Ratio:NumSubwells:end);
        FaultyScores(1:3:end) = TextonFeatures{4}(SubwellWith2To1Ratio:NumSubwells:end);
        FilePaths(1:3:end) = TextonFeatures{1}(SubwellWith2To1Ratio:NumSubwells:end);
    end
    if ~isempty(SubwellWith1To1Ratio)
        FeaturesRearranged(2:3:end,:) = CalculatedFeatures(SubwellWith1To1Ratio:NumSubwells:end,:);
        ClearScores(2:3:end) = TextonFeatures{5}(SubwellWith1To1Ratio:NumSubwells:end);
        FaultyScores(2:3:end) = TextonFeatures{4}(SubwellWith1To1Ratio:NumSubwells:end);
        FilePaths(2:3:end) = TextonFeatures{1}(SubwellWith1To1Ratio:NumSubwells:end);
    end
    if ~isempty(SubwellWith1To2Ratio)
        FeaturesRearranged(3:3:end,:) = CalculatedFeatures(SubwellWith1To2Ratio:NumSubwells:end,:);
        ClearScores(3:3:end) = TextonFeatures{5}(SubwellWith2To1Ratio:NumSubwells:end);
        FaultyScores(3:3:end) = TextonFeatures{4}(SubwellWith2To1Ratio:NumSubwells:end);
        FilePaths(3:3:end) = TextonFeatures{1}(SubwellWith2To1Ratio:NumSubwells:end); 
    end
    % to be used later
    handles.TextonFeatures = {FilePaths, FeaturesRearranged, FaultyScores, ClearScores};
    % Load appropriate library
    switch ScreenID
        case 'JCSG+'
            handles.SelectedScreen = 'JCSG';
        case 'LFS'
            handles.SelectedScreen = 'LFS';
        case 'Hampton Crystal Screen'
            handles.SelectedScreen = 'HCS';
        case 'Hampton Index'
            handles.SelectedScreen = 'HIN';
    end
    
    
    set(handles.Status, 'String', 'Loading reference libraries...');
    drawnow();
    if strcmp(handles.SelectedScreen, 'JCSG')
        load(['PrecPatternLibrary\' handles.SelectedScreen '_4_Hellinger_TextonFeatures1.mat']);
        load(['PrecPatternLibrary\' handles.SelectedScreen '_4_Hellinger_TextonFeatures2.mat']);
        ReferenceFeatures = [TextonFeatures1; TextonFeatures2];
        clear TextonFeatures1 TextonFeatures2;
    else
        load(['PrecPatternLibrary\' handles.SelectedScreen '_4_Hellinger_TextonFeature.mat']);
        ReferenceFeatures = TextonFeatures;
        clear TextonFeatures;
    end
    
    FeaturesRearranged = FeaturesRearranged + 10e-6;
                    
    % get clear scores from database
    ClearScore = handles.TextonFeatures{4};
    ClearDropProp = sum(ClearScore >0.6)/length(ClearScore);
    

    % faulty wells
    FeaturesRearranged(sum(FeaturesRearranged,2)<10000 | sum(FeaturesRearranged,2) > 60000,:) = NaN;
    FaultyWells =  sum(isnan(FeaturesRearranged(:,1)))/size(FeaturesRearranged,1);
    set(handles.PlateStats, 'String', sprintf('Clear drops in plate: %d%%; Faulty Wells: %d%%. (Calculated over 288 droplets).\n Num plates in library: %d', ...
        round(ClearDropProp*100), round(FaultyWells*100), size(ReferenceFeatures,1)));
    
    
    
    % PlateFeatures = ReplaceNaNSubwells({PlateFeatures},1,1); % don't replace
    % anymore. -> use average instead.
    set(handles.Status, 'String', 'Calculating distance to references');
    drawnow();
    d = zeros(size(ReferenceFeatures,1),1);
    for k = 1:length(ReferenceFeatures)
        Plate2 = ReferenceFeatures{k} + 10e-6;
        [~, temp] = Plate2PlateDist(FeaturesRearranged, Plate2, 'Hellinger', 1);
        d(k) = temp.Average;
    end
    
    [~, id] = sort(d);
    
    handles.NNIDs = id(1:NumNearestNeighbours);
    handles.DistancesToReferences = d(id(1:NumNearestNeighbours));
    
    % plot profile
    load(['IndividualProfiles\' handles.SelectedScreen '_4_Individual_XQual_TreeOrder.mat']); % variable name:Profiles
    handles.Top50Profiles = Profiles(handles.NNIDs,:); clear IndividualProfiles;
   
    % by default, look at 10 closest neighbours
    % use dummy for now.
    handles.NumNeighbours = 10;
    set(handles.NeighboursToIncludeSlider, 'Max', length(handles.DistancesToReferences));
    axes(handles.DistanceFromNeighbour);
    h = plot(handles.DistancesToReferences);
    set(h, 'HitTest', 'off', 'Color', [0.2 0.2 0.72], 'LineWidth', 2);
    set(handles.DistanceFromNeighbour, 'ButtonDownFcn', @DistanceFromNeighbour_ButtonDownFcn, ...
        'xlim', [1 length(handles.DistancesToReferences)], ...
        'YLim', [min(handles.DistancesToReferences)-0.01, max(handles.DistancesToReferences)+0.01]);
    hold on;
    ProfilesWithoutRepeats = handles.Top50Profiles(:,sum(handles.Top50Profiles,1) > -1);
    ProfilesWithoutRepeats = cumsum(sum( ProfilesWithoutRepeats,2));
    if ProfilesWithoutRepeats(1) ~= 0
        idx = find(diff(ProfilesWithoutRepeats)~= 0);
        idx = [1; idx+1];
    else
        idx = find(diff(ProfilesWithoutRepeats)~= 0) + 1;
    end
    h = plot(idx, handles.DistancesToReferences(idx), '.', 'MarkerEdgeColor', [0.72, 0.2 0.2], 'markersize', 15);
    set(h, 'HitTest', 'off');
    %Mean and std for JCSG, LFS, HCS and HIN - precalculated
    Averages = [0.42093 0.42551 0.43514 0.42200];
    StandardDevs = [0.047809 0.06375 0.051347 0.057088];
    if ~isempty(strfind(handles.SelectedScreen, 'JCSG'))
        ScreenIdx = 1;
    elseif ~isempty(strfind(handles.SelectedScreen, 'LFS'))
        ScreenIdx = 2;
    elseif ~isempty(strfind(handles.SelectedScreen, 'HCS'))
        ScreenIdx = 3;
    elseif ~isempty(strfind(handles.SelectedScreen, 'HIN'))
        ScreenIdx = 4;
    end
            
    plot(1:length(handles.NNIDs), Averages(ScreenIdx)*ones(length(handles.NNIDs),1), 'k');
    plot(1:length(handles.NNIDs), (Averages(ScreenIdx)-StandardDevs(ScreenIdx))*ones(length(handles.NNIDs),1), 'k-.');
    set(handles.MeanStdTxt, 'String', sprintf('Mean: %.4f, Mean-1*Std: %.4f', Averages(ScreenIdx),Averages(ScreenIdx)-StandardDevs(ScreenIdx)));
    
    h = stem(handles.NumNeighbours,handles.DistancesToReferences(handles.NumNeighbours), 'Color', [0.7 0.12 0.12], 'LineWidth', 1.5);
    set(h, 'HitTest', 'off');
    hold off;
    
    if isempty(handles.CountLine)
        handles.CountLine = h;
        %     handles.PlotLeft =  hLeft; handles.PlotRight = hRight;
    else
        try
            delete(handles.CountLine); %delete(handles.PlotLeft); delete(handles.PlotRight);
        catch err
        end
        handles.CountLine = h;
        %     handles.PlotLeft =  hLeft; handles.PlotRight = hRight;
    end
    
    set(handles.NeighboursToIncludeSlider, 'Value', handles.NumNeighbours);
    set(handles.NumNeighIncludedTxt, 'string', ...
        sprintf('%d (%.4f)',handles.NumNeighbours,handles.DistancesToReferences(handles.NumNeighbours)));
    
    % Suggestion on whether this is worth working on.
    % Work on it if success was found in the first 25 plates, 
    % AND at least 3 successful plates are found in under 1 standard deviation line, 
    if isempty(idx)
        SuccessFoundInFirst25Plates = false;
        AtLeast3SuccessfulPlatesUnder1StandarDev = false;
    else
        SuccessFoundInFirst25Plates = idx(1) < 25;
        AtLeast3SuccessfulPlatesUnder1StandarDev = sum(handles.DistancesToReferences(idx) < Averages(ScreenIdx)-StandardDevs(ScreenIdx)) > 3;
    end
    WorkOnThis = SuccessFoundInFirst25Plates & AtLeast3SuccessfulPlatesUnder1StandarDev;
    if WorkOnThis
        RecString = sprintf(['Looks like it''s worth following up on this!!!\n'...
            'We usually have success with cases where\n(1) successes were found in the first 25 neighbours '...
            'and\n(2) at least 3 successes from plates under 1 std. \n ']);
    else
        RecString = sprintf(['We have had little success with cases where\n(1) no successes were found in the first 25 neighbours '...
            'or\n(2) at least 3 successes from plates under 1 std. \nTry if you have an abundance of protein, and let us know if it works!']);
    end
    set(handles.WorkOnThisTxt, 'String', RecString);
    
    % condense profile in 340, in tree order. 
    Profile = sum(handles.Top50Profiles(1:handles.NumNeighbours,:),1);
    Profile = Profile(Profile > -1);
    
    if sum(Profile) == 0 % no data available/bad success rate
        axes(handles.ProfilePlot);
        h = plot(zeros(1,384), 'b', 'LineWidth', 2);
        set(handles.ProfilePlot, 'XLim', [1 length(Profile)], 'YLim', [0 1], ...
            'XTick', []);
        set(h, 'HitTest', 'off');
        set(handles.ProfilePlot, 'ButtonDownFcn', {@ProfilePlot_ButtonDownFcn, handles});
        handles.Profile = Profile;
        set(handles.ConditionsTable, 'Data', '');
        set(handles.SummaryTableDescTxt, 'String', 'Hits from nearest neighbours');
            
        set(handles.Status, 'String', 'Done');
        
        set(handles.ProfileFromNN, 'Pointer', 'arrow');
        drawnow();
%         % Find experiments that have been set up. - not for offline version
%             qry = ['select * from (select T1."BARCODE" "Xtal Plate Barcode", T2."SCREENNAME" "Xtalln Screen ID" from '...
%                 'DUAL ONE_ROW_TAB_ inner join "SGC"."XTAL_SCREENID" T2 on upper(T2."SCREENTYPE") = ''1.COARSE'' '...
%                 'inner join "SGC"."XTAL_SCREENBATCH" T3 on T2."PKEY" = T3."SGCXTALSCREENID_PKEY" inner join '...
%                 '"SGC"."XTAL_PLATES" T1 on T3."PKEY" = T1."SGCXTALSCREENBATCH_PKEY" and T1."CONCENTRATRION" '...
%                 '> ' num2str(str2double(data{SelectedCell(1),8})-0.1) ' and T1."CONCENTRATRION" < ' num2str(str2double(data{SelectedCell(1),8})+0.1) ' and '...
%                 'T1."TEMPERATURE" = ' data{SelectedCell(1),5} ' inner join "SGC"."PURIFICATION" T6 on T6."PKEY" '...
%                 '= T1."SGCPURIFICATION_PKEY" and upper(T6."PURIFICATIONID") = ''' upper(data{SelectedCell(1),4}) ''' inner join '...
%                 '"SGC"."V_COMPOUND_XTALPLATE2" T4 on T4."PKEY" = T1."SGCCOMPOUND_PKEY2" and upper(T4."COMPOUND_ID") '...
%                 '= ''' upper(data{SelectedCell(1),7}) ''' inner join "SGC"."V_COMPOUND_XTALPLATE" T5 on T5."PKEY" = '...
%                 'T1."SGCCOMPOUND_PKEY" and upper(T5."COMPOUND_ID") = ''' upper(data{SelectedCell(1),6}) ''')'];
%             OtherScreensSetUp = getDataFromBEEHIVE(qry, 'Custom', handles.Conn);
%             OtherScreensSetUp = OtherScreensSetUp(~cellfun(@isempty, strfind(OtherScreensSetUp(:,1), 'CI')),:);
%             % Screen names in conditions list
%             ScreensInIteration = {'JCSG', 'LFS', 'HCS', 'HIN'};
%             for i = 1:length(ScreensInIteration)
%                 temp = ~cellfun(@isempty, strfind(OtherScreensSetUp(:,2), ScreensInIteration{i}));
%                 if sum(temp)
%                     OtherScreensSetUp(temp,2) = repmat(ScreensInIteration(i), sum(temp),1);
%                 end
%             end
%             handles.OtherScreensSetUp = OtherScreensSetUp;
        handles.OtherScreensSetUp = {};

    else
        if handles.GroupConditions
            ExtendedProfile = zeros(length(Profile) + length(handles.RepeatConditionsID),1);
            ExtendedProfile(~ismember(1:length(ExtendedProfile),handles.RepeatConditionsID)) = Profile;
            if handles.GroupConditions
                
                CombinePositions = {231:236, 240:245, 246:251, 252:257, 302:313, 314:319, ...
                    320:324, 327:334, 338:349, 350:360, 361:373, 374:379, 382:384};
                
                for i = 1:length(CombinePositions)
                    ExtendedProfile(CombinePositions{i}(end)) = sum(ExtendedProfile(CombinePositions{i}));
                    ExtendedProfile(CombinePositions{i}(1:end-1)) = -1;
                end
            end
            ExtendedConditions = cell(length(ExtendedProfile),4);
            ExtendedConditions(~ismember(1:length(ExtendedProfile),handles.RepeatConditionsID),:) = handles.RawConditions;
            CombinedConditionSummary = {...
                '20% PEG6000 -- 10% ethylene glycol -- 0.1M MES pH 6.0 -- chloride salts *';
                '20% PEG6000 -- 10% ethylene glycol -- 0.1M HEPES pH 7.0 -- chloride salts *';
                '20% PEG6000 -- 10% ethylene glycol -- chloride salts *';
                '20% PEG6000 -- 10% ethylene glycol -- 0.1M tris pH 7.5 -- chloride salts *';
                '20% PEG3350 -- 10% ethylene glycol -- 0.1M bis-tris-propane pH 6.5 -- salts *';
                '25% PEG3350 -- 0.1M bis-tris pH 6.5 -- salts *';
                '8-30% PEG4000 -- 0.1M acetate pH 4.5 -- salts *';
                '25% PEG3350 -- 0.1M HEPES pH 7.5 -- salts *';
                '20% PEG3350 -- 10% ethylene glycol -- 0.1M bis-tris-propane pH 7.5 -- salts *';
                '20% PEG3350 -- 10% ethylene glycol -- salts *';
                '20% PEG3350 -- 10% ethylene glycol -- 0.1M bis-tris-propane pH 8.5 -- salts *';
                '25% PEG3350 -- 0.1M tris pH 8.5 -- salts *';
                '30% PEG4000 -- 0.1M tris pH 8.5 -- salts *'};
            ExtendedConditions(cellfun(@(x) x(end), CombinePositions), 4) = CombinedConditionSummary;
            ExtendedConditions(cellfun(@(x) x(end), CombinePositions), 1:3) = {''};
            %            ExtendedConditions(cellfun(@(x) x(1:end-1), CombinedConditionSummary), 4) = {''};
            [sortedProfile, sortedIdx] = sort(ExtendedProfile, 'descend');
            StopShowing = find(sortedProfile == 0, 1, 'first')-1;
            TopTenConditions = [ExtendedConditions(sortedIdx(1:StopShowing),:), num2cell(sortedProfile(1:StopShowing))];
        else
            [sortedProfile, sortedIdx] = sort(Profile, 'descend');
            StopShowing = find(sortedProfile == 0, 1, 'first')-1;
            TopTenConditions = [handles.RawConditions(sortedIdx(1:StopShowing),:), num2cell(sortedProfile(1:StopShowing)')];
            ExtendedProfile = zeros(length(Profile) + length(handles.RepeatConditionsID),1);
            ExtendedProfile(~ismember(1:length(ExtendedProfile),handles.RepeatConditionsID)) = Profile;
        end
        
        handles.TopTenConditionsTableSummary = TopTenConditions;
        set(handles.ConditionsTable, 'Data', handles.TopTenConditionsTableSummary);
        drawnow();
        
%         % Find experiments that have been set up. - Not for Offline version
%         qry = ['select * from (select T1."BARCODE" "Xtal Plate Barcode", T2."SCREENNAME" "Xtalln Screen ID" from '...
%             'DUAL ONE_ROW_TAB_ inner join "SGC"."XTAL_SCREENID" T2 on upper(T2."SCREENTYPE") = ''1.COARSE'' '...
%             'inner join "SGC"."XTAL_SCREENBATCH" T3 on T2."PKEY" = T3."SGCXTALSCREENID_PKEY" inner join '...
%             '"SGC"."XTAL_PLATES" T1 on T3."PKEY" = T1."SGCXTALSCREENBATCH_PKEY" and T1."CONCENTRATRION" '...
%             '> ' num2str(str2double(data{SelectedCell(1),8})-0.1) ' and T1."CONCENTRATRION" < ' num2str(str2double(data{SelectedCell(1),8})+0.1) ' and '...
%             'T1."TEMPERATURE" = ' data{SelectedCell(1),5} ' inner join "SGC"."PURIFICATION" T6 on T6."PKEY" '...
%             '= T1."SGCPURIFICATION_PKEY" and upper(T6."PURIFICATIONID") = ''' upper(data{SelectedCell(1),4}) ''' inner join '...
%             '"SGC"."V_COMPOUND_XTALPLATE2" T4 on T4."PKEY" = T1."SGCCOMPOUND_PKEY2" and upper(T4."COMPOUND_ID") '...
%             '= ''' upper(data{SelectedCell(1),7}) ''' inner join "SGC"."V_COMPOUND_XTALPLATE" T5 on T5."PKEY" = '...
%             'T1."SGCCOMPOUND_PKEY" and upper(T5."COMPOUND_ID") = ''' upper(data{SelectedCell(1),6}) ''')'];
%         OtherScreensSetUp = getDataFromBEEHIVE(qry, 'Custom', handles.Conn);
%         OtherScreensSetUp = OtherScreensSetUp(~cellfun(@isempty, strfind(OtherScreensSetUp(:,1), 'CI')),:);
%         
%         % Screen names in conditions list
%         ScreensInIteration = {'JCSG', 'LFS', 'HCS', 'HIN'};
%         for i = 1:length(ScreensInIteration)
%             temp = ~cellfun(@isempty, strfind(OtherScreensSetUp(:,2), ScreensInIteration{i}));
%             if sum(temp)
%                 OtherScreensSetUp(temp,2) = repmat(ScreensInIteration(i), sum(temp),1);
%             end
%         end
%         handles.OtherScreensSetUp = OtherScreensSetUp;
% 
%         for i = 1:size(OtherScreensSetUp,1)
%             temp = ~cellfun(@isempty, strfind(TopTenConditions(:,1), OtherScreensSetUp{i,2}));
%             handles.TopTenConditionsTableSummary(temp,6) = OtherScreensSetUp(i,1);
%         end
        handles.OtherScreensSetUp = {};
        
        set(handles.ConditionsTable, 'Data', handles.TopTenConditionsTableSummary);
        set(handles.SummaryTableDescTxt, 'String', 'Hits from nearest neighbours');
   
        % plot profile
        axes(handles.ProfilePlot);
        h = plot(ExtendedProfile, 'b', 'LineWidth', 2);
        set(handles.ProfilePlot, 'XLim', [1 length(ExtendedProfile)], 'YLim', [0 max(ExtendedProfile)+1], ...
            'XTick', []);
        set(h, 'HitTest', 'off');
        hold on;
        
        if handles.GroupConditions
            for i = 1:length(CombinePositions)
                h = plot(CombinePositions{i}(1:end-1), zeros(length(CombinePositions{i}(1:end-1)),1), 'r', 'LineWidth', 6);
                set(h, 'HitTest', 'off');
            end
        end
        
        set(handles.ProfilePlot, 'ButtonDownFcn', {@ProfilePlot_ButtonDownFcn, handles});
        hold off;
        handles.Profile = Profile;
        set(handles.Status, 'String', 'Done');
        set(handles.ProfileFromNN, 'Pointer', 'arrow');
        drawnow();
    end
end
guidata(hObject, handles);
set(handles.GenerateProfile, 'Enable', 'off');
drawnow;
set(handles.GenerateProfile, 'Enable', 'on');

% --- Executes on button press in ClearDropAnalysis.
function ClearDropAnalysis_Callback(hObject, eventdata, handles)
set(handles.ProfileFromNN, 'Pointer', 'watch');

NumNearestNeighbours = 100; % num neighbours to consider

% Get data from user input
ScreenID = get(handles.ScreenID, 'String');
ScreenID = ScreenID{get(handles.ScreenID, 'Value')};
if strcmp(ScreenID, 'Please Select:')
    errordlg('Please select one of these screens.', 'Select Screen');
end
Subwell1 = get(handles.Subwell1, 'String');
Subwell1 = Subwell1{get(handles.Subwell1, 'Value')};
if strcmp(Subwell1, 'Please Select:')
    errordlg('Please select ratio for Subwell 1.', 'Select Subwell Ratio');
end
Subwell2 = get(handles.Subwell1, 'String');
Subwell2 = Subwell2{get(handles.Subwell2, 'Value')};
if strcmp(Subwell2, 'Please Select:')
    errordlg('Please select ratio for Subwell 2.', 'Select Subwell Ratio');
end
Subwell3 = get(handles.Subwell1, 'String');
Subwell3 = Subwell3{get(handles.Subwell3, 'Value')};
if strcmp(Subwell3, 'Please Select:')
    errordlg('Please select ratio for Subwell 3.', 'Select Subwell Ratio');
end

% load data file
load(['Data\' handles.Barcode '.mat']); % variable name: TextonFeatures, generated by Ranker.exe
CalculatedFeatures = TextonFeatures{1,2};
set(handles.Status, 'String', 'Loading calculated features');
drawnow();
if mod(size(CalculatedFeatures,1), 96) ~= 0
    errdlg('Images are not in multiples of 96. Please check your calculated file', 'File Number Error');
    return;
else
    NumSubwells = size(CalculatedFeatures,1)/96;
    % rearrange Features to have 2:1, 1:1, 1:2 arrangement for each well.
    FeaturesRearranged = nan(288, 300);
    ClearScores = NaN(288,1);
    FaultyScores = NaN(288,1);
    FilePaths = repmat({'MatFiles\Dummy.jpg'}, 288,1);
    % find subwell with 2:1
    SubwellWith2To1Ratio = find(strcmp({Subwell1; Subwell2; Subwell3}, '2:1'));
    SubwellWith1To1Ratio = find(strcmp({Subwell1; Subwell2; Subwell3}, '1:1'));
    SubwellWith1To2Ratio = find(strcmp({Subwell1; Subwell2; Subwell3}, '1:2'));
    % rearrange file to keep to the standard 2:1, 1:1, 1:2 prot:prec ratio
    % arrangement. 
    if ~isempty(SubwellWith2To1Ratio)
        FeaturesRearranged(1:3:end,:) = CalculatedFeatures(SubwellWith2To1Ratio:NumSubwells:end,:);
        ClearScores(1:3:end) = TextonFeatures{5}(SubwellWith2To1Ratio:NumSubwells:end);
        FaultyScores(1:3:end) = TextonFeatures{4}(SubwellWith2To1Ratio:NumSubwells:end);
        FilePaths(1:3:end) = TextonFeatures{1}(SubwellWith2To1Ratio:NumSubwells:end);
    end
    if ~isempty(SubwellWith1To1Ratio)
        FeaturesRearranged(2:3:end,:) = CalculatedFeatures(SubwellWith1To1Ratio:NumSubwells:end,:);
        ClearScores(2:3:end) = TextonFeatures{5}(SubwellWith1To1Ratio:NumSubwells:end);
        FaultyScores(2:3:end) = TextonFeatures{4}(SubwellWith1To1Ratio:NumSubwells:end);
        FilePaths(2:3:end) = TextonFeatures{1}(SubwellWith1To1Ratio:NumSubwells:end);
    end
    if ~isempty(SubwellWith1To2Ratio)
        FeaturesRearranged(3:3:end,:) = CalculatedFeatures(SubwellWith1To2Ratio:NumSubwells:end,:);
        ClearScores(3:3:end) = TextonFeatures{5}(SubwellWith2To1Ratio:NumSubwells:end);
        FaultyScores(3:3:end) = TextonFeatures{4}(SubwellWith2To1Ratio:NumSubwells:end);
        FilePaths(3:3:end) = TextonFeatures{1}(SubwellWith2To1Ratio:NumSubwells:end); 
    end
    % to be used later
    handles.TextonFeatures = {FilePaths, FeaturesRearranged, FaultyScores, ClearScores};
    % Load appropriate library
    switch ScreenID
        case 'JCSG+'
            handles.SelectedScreen = 'JCSG';
        case 'LFS'
            handles.SelectedScreen = 'LFS';
        case 'Hampton Crystal Screen'
            handles.SelectedScreen = 'HCS';
        case 'Hampton Index'
            handles.SelectedScreen = 'HIN';
    end
end
handles = LoadLibraries(handles.SelectedScreen, handles);
CondOccs = {handles.CondOccL1, handles.CondOccL2, handles.CondOccL3};%for legacy code
PrecipitateTrend(handles.Barcode, handles.TextonFeatures, handles.SelectedScreen, CondOccs, handles.CondDict, handles.DropRankingViewerHandles);
guidata(hObject, handles);




function handles = LoadLibraries(Screen, handles)

% load dictionaries
switch Screen
    case 'JCSG'
        CondOccL1 = load('CondDicts/JCSG6CondOccL1.mat');
        handles.CondOccL1 = CondOccL1.CondOccL1;
        CondOccL2 = load('CondDicts/JCSG6CondOccL2.mat');
        handles.CondOccL2 = CondOccL2.CondOccL2;
        CondOccL3 = load('CondDicts/JCSG6CondOccL3.mat');
        handles.CondOccL3 = CondOccL3.CondOccL3;
        CondDict = load('CondDicts/JCSG6CondDict.mat');
        handles.CondDict = CondDict.JCSG6CondDict;
        CondDictFull = load('CondDicts/JCSG6CondDictFull.mat');
        handles.CondDictFull = CondDictFull.CondDictFull;
    
    case 'HCS'
        CondOccL1 = load('CondDicts/HCSCondOccL1.mat');
        handles.CondOccL1 = CondOccL1.CondOccL1;
        CondOccL2 = load('CondDicts/HCSCondOccL2.mat');
        handles.CondOccL2 = CondOccL2.CondOccL2;
        CondOccL3 = load('CondDicts/HCSCondOccL3.mat');
        handles.CondOccL3 = CondOccL3.CondOccL3;
        CondDict = load('CondDicts/HCSCondDict.mat');
        handles.CondDict = CondDict.HCSCondDict;
        CondDictFull = load('CondDicts/HCSCondDictFull.mat');
        handles.CondDictFull = CondDictFull.CondDictFull;
    case 'LFS'
        CondOccL1 = load('CondDicts/LFS4CondOccL1.mat');
        handles.CondOccL1 = CondOccL1.CondOccL1;
        CondOccL2 = load('CondDicts/LFS4CondOccL2.mat');
        handles.CondOccL2 = CondOccL2.CondOccL2;
        CondOccL3 = load('CondDicts/LFS4CondOccL3.mat');
        handles.CondOccL3 = CondOccL3.CondOccL3;
        CondDict = load('CondDicts/LFS4CondDict.mat');
        handles.CondDict = CondDict.LFS4CondDict;
        CondDictFull = load('CondDicts/LFS4CondDictFull.mat');
        handles.CondDictFull = CondDictFull.CondDictFull;
    case 'HIN'
        CondOccL1 = load('CondDicts/HIN1CondOccL1.mat');
        handles.CondOccL1 = CondOccL1.CondOccL1;
        CondOccL2 = load('CondDicts/HIN1CondOccL2.mat');
        handles.CondOccL2 = CondOccL2.CondOccL2;
        CondOccL3 = load('CondDicts/HIN1CondOccL3.mat');
        handles.CondOccL3 = CondOccL3.CondOccL3;
        CondDict = load('CondDicts/HIN1CondDict.mat');
        handles.CondDict = CondDict.HIN1CondDict;
        CondDictFull = load('CondDicts/HIN1CondDictFull.mat');
        handles.CondDictFull = CondDictFull.CondDictFull;

end


function UpdateProfile(hObject, eventdata, handles)

    
    % update stem
    axes(handles.DistanceFromNeighbour);
    set(handles.CountLine, 'XData', handles.NumNeighbours, 'YData', handles.DistancesToReferences(handles.NumNeighbours));
   
    set(handles.NeighboursToIncludeSlider, 'Value', handles.NumNeighbours);
    set(handles.NumNeighIncludedTxt, 'string', ...
        sprintf('%d (%.4f)',handles.NumNeighbours,handles.DistancesToReferences(handles.NumNeighbours)));
    
    
    % condense profile in 340, in tree order. 

    Profile = sum(handles.Top50Profiles(1:handles.NumNeighbours,:),1);
    Profile = Profile(Profile > -1);

    
    if sum(Profile) == 0 % no data available/bad success rate
            axes(handles.ProfilePlot);
            h = plot(zeros(1,384), 'b', 'LineWidth', 2);
            set(handles.ProfilePlot, 'XLim', [1 length(Profile)], 'YLim', [0 1], ...
                'XTick', []);
            set(h, 'HitTest', 'off');
            set(handles.ProfilePlot, 'ButtonDownFcn', {@ProfilePlot_ButtonDownFcn, handles});
            handles.Profile = Profile;
            set(handles.ConditionsTable, 'Data', '');
            set(handles.SummaryTableDescTxt, 'String', 'Top 10 ''hit producers''');
            ExtendedProfile = zeros(length(Profile) + length(handles.RepeatConditionsID),1);
    else
        if handles.GroupConditions
            ExtendedProfile = zeros(length(Profile) + length(handles.RepeatConditionsID),1);
            ExtendedProfile(~ismember(1:length(ExtendedProfile),handles.RepeatConditionsID)) = Profile;
            if handles.GroupConditions
                
                CombinePositions = {231:236, 240:245, 246:251, 252:257, 302:313, 314:319, ...
                    320:324, 327:334, 338:349, 350:360, 361:373, 374:379, 382:384};
                
                for i = 1:length(CombinePositions)
                    ExtendedProfile(CombinePositions{i}(end)) = sum(ExtendedProfile(CombinePositions{i}));
                    ExtendedProfile(CombinePositions{i}(1:end-1)) = -1;
                end
            end
            ExtendedConditions = cell(length(ExtendedProfile),4);
            ExtendedConditions(~ismember(1:length(ExtendedProfile),handles.RepeatConditionsID),:) = handles.RawConditions;
            CombinedConditionSummary = {...
                '20% PEG6000 -- 10% ethylene glycol -- 0.1M MES pH 6.0 -- chloride salts *';
                '20% PEG6000 -- 10% ethylene glycol -- 0.1M HEPES pH 7.0 -- chloride salts *';
                '20% PEG6000 -- 10% ethylene glycol -- chloride salts *';
                '20% PEG6000 -- 10% ethylene glycol -- 0.1M tris pH 7.5 -- chloride salts *';
                '20% PEG3350 -- 10% ethylene glycol -- 0.1M bis-tris-propane pH 6.5 -- salts *';
                '25% PEG3350 -- 0.1M bis-tris pH 6.5 -- salts *';
                '8-30% PEG4000 -- 0.1M acetate pH 4.5 -- salts *';
                '25% PEG3350 -- 0.1M HEPES pH 7.5 -- salts *';
                '20% PEG3350 -- 10% ethylene glycol -- 0.1M bis-tris-propane pH 7.5 -- salts *';
                '20% PEG3350 -- 10% ethylene glycol -- salts *';
                '20% PEG3350 -- 10% ethylene glycol -- 0.1M bis-tris-propane pH 8.5 -- salts *';
                '25% PEG3350 -- 0.1M tris pH 8.5 -- salts *';
                '30% PEG4000 -- 0.1M tris pH 8.5 -- salts *'};
            ExtendedConditions(cellfun(@(x) x(end), CombinePositions), 4) = CombinedConditionSummary;
            ExtendedConditions(cellfun(@(x) x(end), CombinePositions), 1:3) = {''};
            %            ExtendedConditions(cellfun(@(x) x(1:end-1), CombinedConditionSummary), 4) = {''};
            [sortedProfile, sortedIdx] = sort(ExtendedProfile, 'descend');
            StopShowing = find(sortedProfile == 0, 1, 'first')-1;
            TopTenConditions = [ExtendedConditions(sortedIdx(1:StopShowing),:), num2cell(sortedProfile(1:StopShowing))];
        else
            [sortedProfile, sortedIdx] = sort(Profile, 'descend');
            StopShowing = find(sortedProfile == 0, 1, 'first')-1;
            TopTenConditions = [handles.RawConditions(sortedIdx(1:StopShowing),:), num2cell(sortedProfile(1:StopShowing)')];
            ExtendedProfile = zeros(length(Profile) + length(handles.RepeatConditionsID),1);
            ExtendedProfile(~ismember(1:length(ExtendedProfile),handles.RepeatConditionsID)) = Profile;
        end
        
        handles.TopTenConditionsTableSummary = TopTenConditions;
        % NOT FOR OFFLINE VERSION
%         for i = 1:size(handles.OtherScreensSetUp,1)
%             temp = ~cellfun(@isempty, strfind(TopTenConditions(:,1), handles.OtherScreensSetUp{i,2}));
%             handles.TopTenConditionsTableSummary(temp,6) = handles.OtherScreensSetUp(i,1);
%         end
        
        set(handles.ConditionsTable, 'Data', handles.TopTenConditionsTableSummary);
        drawnow();
        
        set(handles.ConditionsTable, 'Data', handles.TopTenConditionsTableSummary);
        set(handles.SummaryTableDescTxt, 'String', 'Conditions from nearest neighbours');
        
        % plot profile
        axes(handles.ProfilePlot);
        h = plot(ExtendedProfile, 'b', 'LineWidth', 2);
        set(handles.ProfilePlot, 'XLim', [1 length(ExtendedProfile)], 'YLim', [0 max(ExtendedProfile)+1], ...
            'XTick', []);
        set(h, 'HitTest', 'off');
        hold on;
        
        if handles.GroupConditions
            for i = 1:length(CombinePositions)
                h = plot(CombinePositions{i}(1:end-1), zeros(length(CombinePositions{i}(1:end-1)),1), 'r', 'LineWidth', 6);
                set(h, 'HitTest', 'off');
            end
        end
        
        set(handles.ProfilePlot, 'ButtonDownFcn', {@ProfilePlot_ButtonDownFcn, handles});
        hold off;
        handles.Profile = Profile;
        
        drawnow();
        guidata(hObject, handles);
    end
guidata(hObject, handles);


% --- Executes on selection change in ScreenID.
function ScreenID_Callback(hObject, eventdata, handles)


% --- Executes on selection change in Subwell1.
function Subwell1_Callback(hObject, eventdata, handles)
set(handles.Subwell2, 'Enable', 'On');


% --- Executes on selection change in Subwell2.
function Subwell2_Callback(hObject, eventdata, handles)
set(handles.Subwell3, 'Enable', 'On');


% --- Executes on selection change in Subwell3.
function Subwell3_Callback(hObject, eventdata, handles)
set(handles.GenerateProfile, 'Enable', 'On');
set(handles.ClearDropAnalysis, 'Enable', 'On');


% ----------------------- Navigation ------------------------------------ %
% --- Executes on mouse press over axes background.
function ProfilePlot_ButtonDownFcn(hObject, eventdata, handles)
handles = guidata(hObject);
coordinates = get(hObject, 'CurrentPoint');
x = round(coordinates(1));

% Extend Profile and ClusterID to ExtendedProfile to fit for repeat conditions
ExtendedClusterID = zeros(length(handles.Profile)+length(handles.RepeatConditionsID),1);
ExtendedClusterID(~ismember(1:length(ExtendedClusterID), handles.RepeatConditionsID)) = handles.Cockatoo_ClusterID;
ExtendedClusterID(handles.RepeatConditionsID) = ExtendedClusterID((handles.RepeatConditionsID+1));
ExtendedClusterID(ExtendedClusterID == 0) = ExtendedClusterID(find(ExtendedClusterID==0)+2);

ConditionsToShow = handles.RawConditions(handles.Cockatoo_ClusterID==ExtendedClusterID(x),:);
ConditionCount = handles.Profile(handles.Cockatoo_ClusterID==ExtendedClusterID(x));
Data = [ConditionsToShow num2cell(ConditionCount')];

for i = 1:size(handles.OtherScreensSetUp,1)
    temp = ~cellfun(@isempty, strfind(Data(:,1), handles.OtherScreensSetUp{i,2}));
    Data(temp,6) = handles.OtherScreensSetUp(i,1);
end


set(handles.SummaryTableDescTxt, 'String', 'Successful conditions:');
set(handles.ConditionsTable, 'Data', Data);


% --- Executes on mouse press over axes background.
function DistanceFromNeighbour_ButtonDownFcn(hObject, eventdata, handles)
coordinates = get(hObject, 'CurrentPoint');
x = round(coordinates(1));
handles = guidata(hObject);
handles.NumNeighbours = x;
guidata(hObject, handles);
UpdateProfile(hObject, eventdata, handles);


% --- Executes on slider movement.
function NeighboursToIncludeSlider_Callback(hObject, eventdata, handles)
handles.NumNeighbours = round(get(hObject, 'Value'));
if handles.NumNeighbours > length(handles.DistancesToReferences);
    handles.NumNeighbours = 1; % Go back
end

UpdateProfile(hObject, eventdata, handles);
guidata(hObject,handles);
set(handles.NeighboursToIncludeSlider, 'Enable', 'off');
drawnow;
set(handles.NeighboursToIncludeSlider, 'Enable', 'on');


function UpdateSliderNumber(src, eventdata, handles)
handles = guidata(src);
handles.NumNeighbours = round(get(handles.NeighboursToIncludeSlider, 'Value'));
set(handles.NumNeighIncludedTxt, 'String', num2str(handles.NumNeighbours));
set(handles.CountLine, 'XData', handles.NumNeighbours, 'YData', handles.DistancesToReferences(handles.NumNeighbours));


% --- Executes on key press with focus on ProfileFromNN and none of its controls.
function ProfileFromNN_KeyPressFcn(hObject, eventdata, handles)
if handles.KeyPressFlag
    handles.KeyPressFlag = 0;
    guidata(hObject, handles);
    switch eventdata.Key
        case 'leftarrow'
            handles.NumNeighbours = handles.NumNeighbours-1;
            if handles.NumNeighbours < 1;
                handles.NumNeighbours = length(handles.DistancesToReferences); % Loop
            end
            UpdateProfile(hObject, eventdata, handles);
        case 'rightarrow'
            handles.NumNeighbours = handles.NumNeighbours+1;
            if handles.NumNeighbours > length(handles.DistancesToReferences);
                handles.NumNeighbours = 1; % Go back
            end
            UpdateProfile(hObject, eventdata, handles);
    end
    handles = guidata(handles.ProfileFromNN);
    handles.KeyPressFlag = 1;
    guidata(hObject, handles);
end




% ----------------------------- CreateFcn -------------------------------%
% Auto generated by MATLAB. 
% --- Executes during object creation, after setting all properties.
function NeighboursToIncludeSlider_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes during object creation, after setting all properties.
function Subwell3_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function ScreenID_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function Subwell1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function Subwell2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% ------------------ For ONLINE version - here for ref -------------------%
function outHTML = colText(inText, inColor)
% NOT FOR OFFLINE VERSION
% % return a HTML string with colored font
% if ~iscell(inText)
%     outHTML = ['<html><font color="', ...
%         inColor, ...
%         '">', ...
%         inText, ...
%         '</font></html>'];
% else
%     % convert all to string
%     temp = cellfun(@isstr, inText);
%     inText(~temp) = cellfun(@num2str, inText(~temp), 'UniformOutput', 0);
%     inColor = num2cell(inColor);
%     inColor = cellfun(@(x,y,z) [num2str(x) ',' num2str(y) ',' num2str(z)], inColor(:,1), inColor(:,2), inColor(:,3), 'UniformOutput', 0);
%     outHTML = cellfun(@(x,y) ['<html><font color="rgb(' x ')">' y '</font></html>'], inColor, inText, 'UniformOutput', 0);
%     
% end


% --- Executes when selected cell(s) is changed in ConditionsTable.
function ConditionsTable_CellSelectionCallback(hObject, eventdata, handles)
% NOT FOR OFFLINE VERSION
% try
% SelectedCell = eventdata.Indices;
% data = get(handles.ConditionsTable, 'Data');
% if SelectedCell(2) == 6  % Open the plate if barcode available. 
%     Barcode = data{SelectedCell(1), 6};
%     if ~isempty(Barcode) 
%         Row = data{SelectedCell(1),2};
%         Col = num2str((data{SelectedCell(1),3}));
%         
%         set(handles.DropRankingViewerHandles.BarcodeInput, 'String', Barcode);
%         %     guidata(handles.DropRankingViewerHandles.figure1, handles.DropRankingViewerHandles);
%         
%         
% %             handles.DropRankingViewerHandles = guidata(handles.DropRankingViewerHandles.figure1);
%         set(handles.DropRankingViewerHandles.WellDisplay, 'String', [Row Col 'a']);
%         handles.DropRankingViewerHandles.LoadAndJumpToSubwell = 1;
% %             set(handles.DropRankingViewerHandles.SubwellInput, 'String', [Row Col 'a']);
% %             handles.DropRankingViewerHandles.Count = find(handles.DropRankingViewerHandles.RankingIndex == Index);
%         guidata(handles.DropRankingViewerHandles.figure1, handles.DropRankingViewerHandles);
%         fh = handles.BarcodeInputCallback;
%         fh(hObject, eventdata, handles.DropRankingViewerHandles)
%         %     guidata(handles.DropRankingViewerHandles.figure1, handles.DropRankingViewerHandles);
%         
%         %     fh = handles.UpdateDisplay;
%         %     fh(handles.DropRankingViewerHandles.figure1, eventdata, handles.DropRankingViewerHandles);
%         %     UpdateDisplay(handles.DropRankingViewerHandles.figure1, eventdata, handles.DropRankingViewerHandles);
%         guidata(hObject, handles);
%     end
% elseif SelectedCell(2) == 4 && handles.GroupConditions  % Show conditions
%     CombinePositions = {231:236, 240:245, 246:251, 252:257, 302:313, 314:319, ...
%         320:324, 327:334, 338:349, 350:360, 361:373, 374:379, 382:384};
%     CombinedConditionSummary = {...
%         '20% PEG6000 -- 10% ethylene glycol -- 0.1M MES pH 6.0 -- chloride salts *';
%         '20% PEG6000 -- 10% ethylene glycol -- 0.1M HEPES pH 7.0 -- chloride salts *';
%         '20% PEG6000 -- 10% ethylene glycol -- chloride salts *';
%         '20% PEG6000 -- 10% ethylene glycol -- 0.1M tris pH 7.5 -- chloride salts *';
%         '20% PEG3350 -- 10% ethylene glycol -- 0.1M bis-tris-propane pH 6.5 -- salts *';
%         '25% PEG3350 -- 0.1M bis-tris pH 6.5 -- salts *';
%         '8-30% PEG4000 -- 0.1M acetate pH 4.5 -- salts *';
%         '25% PEG3350 -- 0.1M HEPES pH 7.5 -- salts *';
%         '20% PEG3350 -- 10% ethylene glycol -- 0.1M bis-tris-propane pH 7.5 -- salts *';
%         '20% PEG3350 -- 10% ethylene glycol -- salts *';
%         '20% PEG3350 -- 10% ethylene glycol -- 0.1M bis-tris-propane pH 8.5 -- salts *';
%         '25% PEG3350 -- 0.1M tris pH 8.5 -- salts *';
%         '30% PEG4000 -- 0.1M tris pH 8.5 -- salts *'};
%     SelectedCondition = data{SelectedCell(1), 4};
%     if strcmp(SelectedCondition, 'Back')
%         % go back to previous grouped condition
%         eventdata.Indices = handles.SummaryTableSelectedCell;
%         SummaryTable_CellSelectionCallback(hObject, eventdata, handles)
%         
%     elseif sum(strcmp(SelectedCondition, CombinedConditionSummary)) % a grouped condition
%         
%         ConditionsToShow = CombinePositions{strcmp(SelectedCondition, CombinedConditionSummary)};
%         % expand handles.RawConditions to include repeat conditions first
%         ExtendedProfile = zeros(length(handles.Profile) + length(handles.RepeatConditionsID),1);
%         ExtendedProfile(~ismember(1:length(ExtendedProfile),handles.RepeatConditionsID)) = handles.Profile;
%         ExtendedConditions = cell(length(ExtendedProfile),4);
%         ExtendedConditions(~ismember(1:length(ExtendedConditions),handles.RepeatConditionsID),:) = handles.RawConditions;
%         ConditionsToShow = [ExtendedConditions(ConditionsToShow, :), num2cell(ExtendedProfile(ConditionsToShow))];
%         
%         % check if experiments done.
%         SummaryData = get(handles.SummaryTable, 'data');
%         SummaryData = SummaryData(handles.SummaryTableSelectedCell(1), :);
%         
%         qry = ['select * from (select T1."BARCODE" "Xtal Plate Barcode", T2."SCREENNAME" "Xtalln Screen ID" from '...
%             'DUAL ONE_ROW_TAB_ inner join "SGC"."XTAL_SCREENID" T2 on upper(T2."SCREENTYPE") = ''1.COARSE'' '...
%             'inner join "SGC"."XTAL_SCREENBATCH" T3 on T2."PKEY" = T3."SGCXTALSCREENID_PKEY" inner join '...
%             '"SGC"."XTAL_PLATES" T1 on T3."PKEY" = T1."SGCXTALSCREENBATCH_PKEY" and T1."CONCENTRATRION" '...
%             '> ' num2str(str2double(SummaryData{8})-0.1) ' and T1."CONCENTRATRION" < ' num2str(str2double(SummaryData{8})+0.1) ' and '...
%             'T1."TEMPERATURE" = ' SummaryData{5} ' inner join "SGC"."PURIFICATION" T6 on T6."PKEY" '...
%             '= T1."SGCPURIFICATION_PKEY" and upper(T6."PURIFICATIONID") = ''' upper(SummaryData{4}) ''' inner join '...
%             '"SGC"."V_COMPOUND_XTALPLATE2" T4 on T4."PKEY" = T1."SGCCOMPOUND_PKEY2" and upper(T4."COMPOUND_ID") '...
%             '= ''' upper(SummaryData{7}) ''' inner join "SGC"."V_COMPOUND_XTALPLATE" T5 on T5."PKEY" = '...
%             'T1."SGCCOMPOUND_PKEY" and upper(T5."COMPOUND_ID") = ''' upper(SummaryData{6}) ''')'];
%         OtherScreensSetUp = getDataFromBEEHIVE(qry, 'Custom', handles.Conn);
%         OtherScreensSetUp = OtherScreensSetUp(~cellfun(@isempty, strfind(OtherScreensSetUp(:,1), 'CI')),:);
%         
%         % Find template names of screens in iteration, replace screen names
%         % for other plates for simplicity.
%         qry = ['select screens_used from cluster_iteration where iteration_id = ' num2str(handles.Iteration_ID)];
%         ScreensInIteration = getDataFromCRYSTAL(qry, 'Custom', handles.CrystalConn);
%         ScreensInIteration = regexp(ScreensInIteration{1}, '-','split');
%         
%         for i = 1:length(ScreensInIteration)
%             temp = ~cellfun(@isempty, strfind(OtherScreensSetUp(:,2), ScreensInIteration{i}));
%             if sum(temp)
%                 OtherScreensSetUp(temp,2) = repmat(ScreensInIteration(i), sum(temp),1);
%             end
%         end
%         handles.OtherScreensSetUp = OtherScreensSetUp;
%         
%         for i = 1:size(OtherScreensSetUp,1)
%             temp = ~cellfun(@isempty, strfind(ConditionsToShow(:,1), OtherScreensSetUp{i,2}));
%             ConditionsToShow(temp,6) = OtherScreensSetUp(i,1);
%         end
%         ConditionsToShow{end+1,4} = 'Back';
%         
%         
%         
%         set(handles.SummaryTableDescTxt, 'String', sprintf('Combined conditions of %s', CombinedConditionSummary{strcmp(SelectedCondition, CombinedConditionSummary)}));
%         set(handles.ConditionsTable, 'Data', ConditionsToShow);
%     end
%         
% end
% catch
%     % do nothing. 
% end



% --- Executes on button press in GroupConditionsChkBx.
function GroupConditionsChkBx_Callback(hObject, eventdata, handles)
% %NOT FOR OFFLINE VERSION
% handles.GroupConditions = get(handles.GroupConditionsChkBx, 'Value');
% guidata(hObject, handles);
% eventdata.Indices = handles.SummaryTableSelectedCell;
% SummaryTable_CellSelectionCallback(hObject, eventdata, handles)



% --- Executes during object creation, after setting all properties.
function BarcodeInput_CreateFcn(hObject, eventdata, handles)
%NOT FOR OFFLINE VERSION
% if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor','white');
% end

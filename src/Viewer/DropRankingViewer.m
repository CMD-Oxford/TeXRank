function varargout = DropRankingViewer(varargin)
% DROPRANKINGVIEWER MATLAB code for DropRankingViewer.fig
%      DROPRANKINGVIEWER, by itself, creates a new DROPRANKINGVIEWER or raises the existing
%      singleton*.
%
%      H = DROPRANKINGVIEWER returns the handle to a new DROPRANKINGVIEWER or the handle to
%      the existing singleton*.
%
%      DROPRANKINGVIEWER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DROPRANKINGVIEWER.M with the given input arguments.
%
%      DROPRANKINGVIEWER('Property','Value',...) creates a new DROPRANKINGVIEWER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before DropRankingViewer_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to DropRankingViewer_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help DropRankingViewer

% Last Modified by GUIDE v2.5 26-Jul-2014 17:06:05

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @DropRankingViewer_OpeningFcn, ...
                   'gui_OutputFcn',  @DropRankingViewer_OutputFcn, ...
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

% ----------------------------------------------------------------------- %
% For readability, functions are grouped according to their role in
% TeXRank according to the following sections:
%
% 1: Workflow of TeXRank (Viewer) - how users would use TeXRank
%  a. Initialization of the UI. 
%     Initialize variables (all in figure handles). 
%     Establish connection with database(s) and user verification.
%  b. Select plate (either by typing it to BarcodeInput or
%     selecting a plate from 'Projects'. 
%  c. Load all images, history images, calculate ranking order, display. 
%
% 2: UI Button callbacks
%  a. Navigation 
%  b. UI Functionality 
%  c. Scoring buttons
%  d. Figure properties
%  e. Axes button down functions
%
% 3: Helper functions - some common calculations
%
% 4: ___CreateFunctions (matlab generated - boring ones)
%
% 5: Phased out sections - no longer used but may come in handy(?)
%


% ----------------------------------------------------------------------- %
% ----------------------------------------------------------------------- %
% 1: Workflow: -> initialize, verify -> select plate -> load and display  %
%
% *** a. Initialization of UI *** %
% --- Executes just before DropRankingViewer is made visible.
function DropRankingViewer_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to DropRankingViewer (see VARARGIN)

% Choose default command line output for DropRankingViewer
handles.output = hObject;

%%%%%%%%%%%%%%%%%% Section for splash screen %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isdeployed
    if ~isempty(varargin)
         [pathToFile,nameOfFile,fileExt] = fileparts(varargin{1});
         nameOfExe=[nameOfFile,fileExt];
         dosCmd = ['taskkill /f /im "' nameOfExe '"'];
         dos(dosCmd); 
    end
 
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Add path to database connector.
% Change as necessary. 
javaaddpath('ojdbc5.jar');

% Initialize handle structure - holds most variables used by the UI.
% Plate/inspection information
handles.Barcode = '';
handles.Inspection = ''; % Inspection number
handles.Count = 1; % Rank count
handles.TargetName = ''; % Target protein in plate - to find projects.

handles.ScreenConditions = {}; % cell array of strings for conditions for each well.
handles.Filepaths = {}; % File paths to images of the plate. n-by-1 cell array of strings.
temp = load('Subwelltext.mat'); %Load library of subwell text and store.
handles.Subwelltext = temp.Subwelltext;

% writing scores to datbase
handles.InspectID = {}; % unique identifier for each image - used for writing to database. 
handles.ImageName = {}; % filename of image - required for writing scores to database
handles.ColNames = {'scoreid', 'inspectid', 'score', 'scoredate', 'imagename', 'scoredby'};
handles.TableName = 'i_scores';

% Ranking and scores.
handles.Scores = zeros(288,1); % Ranking scores. Change according to number of images per plate. 
handles.RankingIndex = []; % Rearranged index according to rank - from [~,RankingIndex] = sort(handles.Scores)
handles.ManualScore = cell(288,1); % Manual scores retrieved from the database
% add colours and their corresponding label from database 
handles.ScoringColours = [255 255 255; ... c
                          2 0 158; ... d
                          255 128 253; ... 1
                          255 128 172; ... 2
                          255 128 128; ... 3
                          255 128 64; ... 4
                          255 128 0; ... 5
                          255 102 0; ... 6
                          255 68 0; ... 7
                          255 38 0; ... 8
                          247 0 0; ... 9
                          255 0 0; ... 0
                          0 0 255; ... h
                          196 196 196; ... g
                          155 255 155; ... e
                          128 255 0; ... s
                          154 233 239; ... l
                          1 1 1]; % Unknown
handles.DatabaseLabelsOfCorrespondingColours = [1 15 36:45 13 16 32 33 11 999];


% Variables for profile plot
handles.CountLine = []; % For drawing line on score plot.
handles.PlotLeft = []; % index of left subwell
handles.PlotRight = []; % index of right subwell

% displaying images
handles.Highlighted = ones(2,2); % red bar.
handles.NotHighlighted = zeros(2,2); % no bar
handles.ColorMap = [255 250 240; 153 0 0]./255; % Colormaps for the red bar at the bottom. 
handles.ViewMethod = 3; % default: view all three subwells. 
handles.HistoryToShow = []; % Historical inspections to show
handles.HistoryFilepaths = {}; % filepaths of historical image
handles.ShowHistoryFlag = 0; % 0 = don't show. 1 = show.

% Other information
handles.SynchrotronTrip = '';

% UI-related
handles.FigureSize = get(hObject, 'Position');
handles.NavigateBarListener = [];
handles.KeyPressFlag = 1; % 1 => allow key press, 0 block keypress function. 
handles.SwitchInspections = 0; %flag: 0 for loading new barcode, 1 for just switching inspeections

               


% Get users to log on. See LogOnScreen.
uiwait(LogOnScreen);
close(LogOnScreen);

temp = getappdata(0, 'ConnAndUserName');
if isempty(temp)
    errordlg('Connection Error. Try again.');
    handles.closeFigure = 1;

elseif isconnection(temp{1})
    handles.Conn = temp{1}; % Database connection to SCARAB
    handles.Username = temp{2}; % Username
    
    % set up CRYSTAL connection - Change accordingly.
    % The SGC uses 2 database. SCARAB contains all information of the
    % pipeline. CRYSTAL mainly supports our Minstrel HT system - image
    % capture and scoring. All users access CRYSTAL with the same login, so
    % no need for verification.
    
    host = 'YourHost.Domain';
    dbName = 'DatabaseName';
    user = 'UserName';
    password = 'Password';
    %# JDBC parameters
    jdbcString = sprintf('jdbc:oracle:thin:@%s:1521:', host);
    jdbcDriver = 'oracle.jdbc.driver.OracleDriver';
    
    %# Create the database connection object
    conn = database(dbName, user , password, jdbcDriver, jdbcString);
    if isconnection(conn)
        handles.CrystalConn = conn;
        set(handles.HelloText,'string',sprintf('Hello %s!', handles.Username));
    else
        errordlg('Could not connect to minstrel3.sgc.ox.ac.uk, please try again later');
    end
    
else
    errordlg('Connection Error. Try again.');
    handles.closeFigure = 1;
end

% get list of projects. 
handles.ListOfProjects = getDataFromCRYSTAL('', 'ListOfProjects', handles.CrystalConn);
set(handles.ProjectList, 'string', handles.ListOfProjects);

% move focus to BarcodeInput (somehow doing this twice works!)
uicontrol(handles.BarcodeInput);
uicontrol(handles.BarcodeInput);
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = DropRankingViewer_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;
if (isfield(handles,'closeFigure') && handles.closeFigure)
      figure1_CloseRequestFcn(hObject, eventdata, handles)
end


% *********************************************************************** %
% *** b. Selection of plate *** %
%
% --- Executes when the cursor leaves BarcodeInput
function BarcodeInput_Callback(hObject, eventdata, handles)
handles.Barcode = get(handles.BarcodeInput, 'String');
% get imaged inspections.
data = getDataFromCRYSTAL(handles.Barcode, 'InspectionsForABarcode',handles.CrystalConn);
if ~strcmp(data{1}, 'No Data')
    [~,idx] = sort(cell2mat(data(:,1)), 'descend'); % by default, last inspection goes on top.
    data = cellfun(@(x,y) [num2str(x) ' | ' num2str(y)], data(:,1), data(:,2), 'UniformOutput', 0);
    set(handles.InspectionsPopUp, 'String', data(idx));
    set(handles.InspectionsPopUp, 'Value', 1);
    set(handles.NotRankedString, 'String', '');
else
    errordlg('Barcode not found. Please check', 'Inspection Not Found');
    guidata(hObject, handles);
end

% --- When users hit 'Enter'
function BarcodeInput_KeyPressFcn(hObject, eventdata, handles)
if strcmp(eventdata.Key, 'return')
    pause(0.1);
    BarcodeInput_Callback(handles.figure1, eventdata, handles);
    handles = guidata(handles.figure1);
    handles.SwitchInspections = 0;
    handles.KeyPressFlag = 1;
    guidata(hObject, handles);
    PlateAndInspectionGo_Callback(handles.figure1, eventdata, handles);
    set(handles.BarcodeInput, 'Enable', 'off');
    drawnow;
    set(handles.BarcodeInput, 'Enable', 'on')
end

% --- Executes on selection change in ProjectList.
function ProjectList_Callback(hObject, eventdata, handles)
SelectedProject = handles.ListOfProjects{get(handles.ProjectList,'Value')};
% Populate BarcodeListBox
ListOfBarcodes = getDataFromCRYSTAL(SelectedProject, 'ListOfBarcodesForGivenProject', handles.CrystalConn);
DropViewCount = cell2mat(getDataFromCRYSTAL(SelectedProject, 'ListOfBarcodesForGivenProject_MaxDropViewCount', handles.CrystalConn));
if size(ListOfBarcodes,2) > 1
    handles.ListOfBarcodes = ListOfBarcodes(:,1);
    temp = regexp(ListOfBarcodes(:,2), '-', 'split');
    temp = cellfun(@(x) x{2}, temp, 'UniformOutput', 0);
    % add asterisk for plates that have not been viewed at all, empty space
    % for plates that have been viewed at least once.
    ListOfBarcodes(DropViewCount==0,1) = cellfun(@(x) [x '*'], ListOfBarcodes(DropViewCount==0,1), 'UniformOutput', 0);
    ListOfBarcodes(DropViewCount>0,1) = cellfun(@(x) [x ' '], ListOfBarcodes(DropViewCount>0,1), 'UniformOutput', 0);
    ListOfBarcodes(:,2) = temp;
    ListOfBarcodes(:,3) = cellfun(@(x) datestr(x, 'dd-mm-yy'), ListOfBarcodes(:,3), 'UniformOutput', 0);
    ListOfBarcodes = cellfun(@(x1, x2, x3, x4,  x5) [x1 ' | ' x2 ' | ' x3 ' | ' sprintf('%3d', x4) ' | ' x5], ListOfBarcodes(:,1), ListOfBarcodes(:,2), ListOfBarcodes(:,3),  ListOfBarcodes(:,4), ListOfBarcodes(:,5), 'UniformOutput', 0);
    set(handles.BarcodeListBox, 'string', ListOfBarcodes);
    guidata(hObject, handles);
    if get(handles.SortByLastInspection, 'Value');
        SortByLastInspection_Callback(hObject, eventdata, handles)
    end
else
    set(handles.BarcodeListBox, 'string', '');
end

% --- Executes on selection change in BarcodeListBox.
function BarcodeListBox_Callback(hObject, eventdata, handles)
% double click on a row == selecting plate.
if get(hObject, 'UserData') == get(hObject, 'Value')
    ProjectList_Callback(hObject, eventdata, handles); %update list.
    pause(0.3);
    SelectedBarcode = get(handles.BarcodeListBox, 'string');
    handles.Barcode = SelectedBarcode{get(handles.BarcodeListBox, 'Value')}(1:8);
    set(handles.BarcodeInput, 'string', handles.Barcode);
    guidata(hObject, handles);
    BarcodeInput_Callback(handles.figure1, eventdata, handles);
    PlateAndInspectionGo_Callback(handles.figure1, eventdata, handles);
    set(handles.BarcodeListBox, 'Enable', 'off');
    drawnow;
    set(handles.BarcodeListBox, 'Enable', 'on'); 
else 
    % For single clicks - not used for now.
%     ProjectList_Callback(hObject, eventdata, handles);
%     SelectedBarcode = get(handles.BarcodeListBox, 'string');
%     data = getDataFromCRYSTAL(SelectedBarcode{get(handles.BarcodeListBox, 'Value')}(1:8), 'LastInspectionAndViewCount');
%     set(handles.LastInspectionTxt, 'String', [num2str(data{1}) ' (' datestr(data{2}, 'dd-mm-yyyy') ')']);
%     set(handles.ViewCountTxt, 'String', num2str(data{3}));
%     set(handles.BarcodeListBox, 'Enable', 'off');
%     drawnow;
%     set(handles.BarcodeListBox, 'Enable', 'on'); 

end
set(hObject, 'UserData', get(hObject, 'Value'));

% --- Executes on selection change in InspectionsPopUp.
function InspectionsPopUp_Callback(hObject, eventdata, handles)
handles.SwitchInspections = 1;
PlateAndInspectionGo_Callback(hObject, eventdata, handles);
set(handles.InspectionsPopUp, 'Enable', 'off');
drawnow;
set(handles.InspectionsPopUp, 'Enable', 'on');


% *********************************************************************** %
% *** c. load, calculate, display *** %
%
% --- Main function that, given barcode and inspection, loads the plate and
% initializes display. 
function PlateAndInspectionGo_Callback(hObject, eventdata, handles)
set(handles.figure1, 'Pointer', 'watch'); % Indicate it's thinking!

close(figure(1)); % just in case - figure(1) is used for other display

handles.Barcode = get(handles.BarcodeInput, 'string');
% get selected inspection
contents = cellfun(@(x) x(1), cellstr(get(handles.InspectionsPopUp,'String')), 'UniformOutput', 0);
handles.Inspection = str2double(contents{get(handles.InspectionsPopUp,'Value')}); 
handles.KeyPressFlag = 1; % Allow keypress function. 


% read from I_AUTOSCORES - identify if it has been scored (rank-able)
data = getDataFromCRYSTAL({handles.Barcode, handles.Inspection}, 'AutoScores', handles.CrystalConn);
Scores = cell2mat(data(:,1));
if strcmp(Scores, 'No Data') || isempty(Scores)
    % no ranking - still allow viewing, but as it is - A1 to H12. 
    ImageNames = getDataFromCRYSTAL({handles.Barcode, handles.Inspection}, 'ImageNamesForPlateAndInspection', handles.CrystalConn);
    handles.InspectID = ImageNames(:,2);
    handles.ImageName = ImageNames(:,1);
    handles.Scores = 0.5*ones(288,1); % flat score for all. 
    DropQualScore = 0; % see below for description
    PptScore = 0;
    handles.RankingIndex = 1:288; % unranked. 
    set(handles.NotRankedString, 'String', 'Inspection not ranked!');
    InspectDate = ImageNames{1,3}(1:10);
else
    set(handles.NotRankedString, 'String', '');
    handles.InspectID = data(:,2);
    handles.ImageName = data(:,3);
    handles.Scores = Scores; % Scores = probability output from RF classifier used to rank. 
    InspectDate = data{1,6}(1:10);
    
    %ppt score and drop qual scores
    % DropQualScore = % of good droplets. (Good droplets == 0, empty
    % droplets == 1, faulty droplets == 2)
    DropQualScore = sum(cell2mat(data(:,5)) == 0)/288;
    % PptScore = % drops (only good droplets) that are not clear.
    % Use cutoff of 0.5 (default classification)
    ClearScoresToConsider = cell2mat(data((cell2mat(data(:,5)) == 0),4));
    PptScore = sum(ClearScoresToConsider < 0.5)/length(ClearScoresToConsider);
    
    %Rank droplets by scores, save index.
    [~,handles.RankingIndex] = sort(handles.Scores, 'descend');
end

if handles.SwitchInspections %change inspection, keep to same well/subwell in focus.
    SubwellString = get(handles.WellDisplay, 'string');
    Row = upper(SubwellString(1));
    SubWell = lower(SubwellString(end));
    Col = str2double(SubwellString(2:end-1));
    Index = FindIndex(Row, Col, SubWell);
    handles.Count = find(handles.RankingIndex == Index);
    handles.SwitchInspections = 0; %reset switch inspections
else % otherwise, start from top of rank. 
    handles.Count = 1;
end

set(handles.DropQualTxt, 'string', num2str(round(DropQualScore*10)));
set(handles.PptScoreTxt, 'string', num2str(round(PptScore*10)));

%Get other information: Purification ID, Compound IDs
try
    PlateInfo = getDataFromBEEHIVE(handles.Barcode, 'PurificationIdAndCompoundIdByPlate', handles.Conn);
    if length(PlateInfo) == 1
        PlateInfo(1:5) = {'Unknown.'};
    else % work out dates
        NumDaysElapsedSinceSetup = daysact(PlateInfo{6}(1:10), InspectDate);
        % change: no longer displaying barcode, use this to display date
        % of inspection.
        set(handles.BarcodeDisplay, 'string', [InspectDate ', +' num2str(NumDaysElapsedSinceSetup) 'd']);
        set(handles.DatePlateCreatedDisplay, 'string', PlateInfo{6}(1:10));
    end
catch err
    set(handles.ConditionsDisplay, 'string', err.message);
end


% show information
handles.TargetName = PlateInfo{1}(1:end-5);
set(handles.PurificationDisplay, 'string', PlateInfo{1});
set(handles.Compound1Display, 'string', PlateInfo{2});
set(handles.Compound2Display, 'string', PlateInfo{3});
set(handles.ConcentrationDisplay, 'string', PlateInfo{4});
set(handles.TemperatureDisplay, 'string', PlateInfo{5});
SynchrotronTrip = getDataFromBEEHIVE('', 'SynchrotronTrip', handles.Conn);
if strcmp(SynchrotronTrip{1}, 'No Data')
    handles.SynchrotronTrip = 'Next trip details unavailable';
else
    handles.SynchrotronTrip = SynchrotronTrip{1};
end
set(handles.SynchrotronTripDisplay, 'string', handles.SynchrotronTrip);

% set scroll bar
set(handles.NavigateThroughPlate, 'Min', 1);
set(handles.NavigateThroughPlate, 'Value', 1);

set(handles.ThumbnailBtn, 'enable', 'on');

% get screen conditions database
ScreenConditions = getDataFromBEEHIVE(handles.Barcode,'ScreenConditionsGivenPlate', handles.Conn);
if size(ScreenConditions,1) == 1
    handles.ScreenConditions = cell(96,1);
    handles.ScreenConditions(:) = {'Error - Conditions cannot be identified. Check Scarab for more information'};
    set(handles.ScreenIdTxt, 'string', 'Error');
else
    handles.ScreenConditions = ScreenConditions(:,5);
    ScreenID = ScreenConditions{1,2};
    set(handles.ScreenIdTxt, 'string', ScreenID);
end

clear ScreenConditions;
    

%Get file paths of images.
% replace with what you use!!!
FolderPath = ['\\minstrel3\pub\images\' handles.Barcode '\' num2str(handles.Inspection)];
Filepaths = dir(FolderPath);
if isempty(Filepaths)
    % Files not found
    if get(handles.WellSubwellToggle, 'Value')
        axes(handles.axes11); imagesc(uint8(zeros(4,4,3))); axis off;
    else
        axes(handles.axes1); imagesc(uint8(zeros(4,4,3)));axis off;
        axes(handles.axes3); imagesc(uint8(zeros(4,4,3)));axis off;
        axes(handles.axes4); imagesc(uint8(zeros(4,4,3)));axis off;
    end
    errordlg('Images not found', 'Plate Not Found');
else
    %use SortFilesNoBarcode to make sure images are ordered properly -
    %sometimes they do jumble up at the SGC. 
    handles.Filepaths = cellfun(@(x) [FolderPath '\' x], SortFilesNoBarcode(Filepaths), 'UniformOutput', 0);

    %Get filepaths for historical view - select only 3 inspections.
    contents = str2double((contents));
    switch length(contents)
        case 1
            HistoryToShow = [];
        case 2
            HistoryToShow = setdiff(contents,handles.Inspection);
        case 3
            HistoryToShow = setdiff(contents,handles.Inspection);
        case 4
            HistoryToShow = setdiff(contents,handles.Inspection);
        case 5
            HistoryToShow = setdiff(contents,handles.Inspection);
            HistoryToShow = HistoryToShow([1 3 4]);
        case 6
            HistoryToShow = setdiff(contents,handles.Inspection);
            HistoryToShow = HistoryToShow([1 3 5]);
        case 7
            HistoryToShow = setdiff(contents,handles.Inspection);
            HistoryToShow = HistoryToShow([1 3 5]);
        case 8
            HistoryToShow = setdiff(contents, handles.Inspection);
            HistoryToShow = HistoryToShow([1 3 6]);
        case 9
            HistoryToShow = setdiff(contents, handles.Inspection);
            HistoryToShow = HistoryToShow([1 3 7]);
    end
    
    handles.HistoryFilepaths = {}; %clear History paths.
    for i = 1:length(HistoryToShow)
        % replace with what you use!!!
        FolderPath = ['\\minstrel3\pub\images\' handles.Barcode '\' num2str(HistoryToShow(i))];
        Filepaths = dir(FolderPath);
        handles.HistoryFilepaths{i} = cellfun(@(x) [FolderPath '\' x], SortFilesNoBarcode(Filepaths), 'UniformOutput', 0);
    end
    handles.HistoryToShow = HistoryToShow;
    clear contents;
    
    
    % Manual scores: get data from CRYSTAL.
    PastScores =  getDataFromCRYSTAL(handles.Barcode, 'ManualScores', handles.CrystalConn);

    if size(PastScores,2) > 1
        % scores across all inspections returned. Take max (already arranged!)
        [~,ia] = unique(cell2mat(PastScores(:,2:4)), 'rows');
        PastScores = PastScores(ia,:);
        Coord = cell2mat(PastScores(:,2:4));
        Index = (Coord(:,1)-1)*24 + (Coord(:,2)-1)*3 + max(Coord(:,3)-1,1);
        handles.ManualScore = cell(288,1);
        handles.ManualScore(Index) = PastScores(:,5);
        temp = handles.ManualScore(handles.RankingIndex);
    else
        % no scores prior to this
        handles.ManualScore = cell(288,1); %clear and reset all manual scores
        temp = {};
    end

       
    %Profile Plot
    axes(handles.axes2);
    y = handles.Scores(handles.RankingIndex);
    h = plot(y,'b');
    set(h, 'HitTest', 'off');
    set(handles.axes2, 'ButtonDownFcn', @axes2_ButtonDownFcn, 'xlim', [1 288], 'ylim', [0 1]);

    hold on;
    % plot manual scores: draw diamonds with colour of score 
    x = 1:288;
    if ~isempty(temp)
        Colours = handles.ScoringColours./255;
        BorderColours = Colours;
        BorderColours(1,:) = [0 0 0];
        ScoreNumbers = handles.DatabaseLabelsOfCorrespondingColours;

        for Colour = 1:length(Colours) 
            colIdx = cellfun(@(x) str2double(x) == ScoreNumbers(Colour), temp);
            hManualPlot = plot(x(colIdx), y(colIdx), 'd', 'Color', BorderColours(Colour,:), 'MarkerFaceColor',Colours(Colour,:), 'MarkerSize', 7);
            set(hManualPlot, 'HitTest', 'Off');
        end
    else
        handles.ScoreThumbnail = uint8(zeros(1056, 1584,3));

    end
    
    % stem current location. plot rank of left and right subwells
    h = stem(1,handles.Scores(handles.RankingIndex(1)), 'r');
    set(h, 'HitTest', 'off'); hold on;
    hLeft = plot(0,0, '<', 'color', [0 0.7 0], 'MarkerFaceColor', [0 0.7 0]);
    set(hLeft, 'HitTest', 'off');
    hRight = plot(0,0,'k>', 'MarkerFaceColor', [0 0 0]);
    set(hRight, 'HitTest', 'off');
    
    
    hold off;
    
    if isempty(handles.CountLine)
        handles.CountLine = h;
        handles.PlotLeft =  hLeft; handles.PlotRight = hRight;
    else
        try
            delete(handles.CountLine); delete(handles.PlotLeft); delete(handles.PlotRight);
        catch err
        end
        handles.CountLine = h;
        handles.PlotLeft =  hLeft; handles.PlotRight = hRight;
    end
    
    % update viewcount, refresh display on inspection list.
    qry = ['update CRYSTAL.I_PLATE_INSPECTIONS set DROPVIEWCOUNT = DROPVIEWCOUNT + 1 where barcodeid = ''' handles.Barcode ''' and inspectnumber = ' num2str(handles.Inspection)];
    tempcurs = exec(handles.CrystalConn, qry);
    close(tempcurs);
    qry = ['select DROPVIEWCOUNT from CRYSTAL.I_PLATE_INSPECTIONS where barcodeid = ''' handles.Barcode ''' and inspectnumber = ' num2str(handles.Inspection)];
    UpdatedViewCount = getDataFromCRYSTAL(qry, 'Custom', handles.CrystalConn);
    contents = get(handles.InspectionsPopUp,'String');
    contents{get(handles.InspectionsPopUp,'Value')} = [contents{get(handles.InspectionsPopUp,'Value')}(1:4) num2str(UpdatedViewCount{1})];
    set(handles.InspectionsPopUp, 'String', contents);
    
    %Display Top ranking image
    UpdateDisplay(hObject, eventdata, handles);
    
end



guidata(hObject, handles);
if isempty(handles.NavigateBarListener)
    handles.NavigateBarListener = addlistener(handles.NavigateThroughPlate, 'ContinuousValueChange', @(hObject, edata) UpdateSliderNumber(hObject, eventdata, handles));
else 
    try
        delete(handles.NavigateBarListener);
    catch err
        % do nothing
    end
    handles.NavigateBarListener = addlistener(handles.NavigateThroughPlate, 'ContinuousValueChange', @(hObject, edata) UpdateSliderNumber(hObject, eventdata, handles));
end



set(handles.figure1, 'Pointer', 'arrow');
guidata(hObject,handles);
set(handles.PlateAndInspectionGo, 'Enable', 'off');
drawnow;
set(handles.PlateAndInspectionGo, 'Enable', 'on');

% ---- Refreshes images on display + other information. 
function UpdateDisplay(hObject, eventdata, handles)
% index of Count'th ranked image
IndexToAccess = handles.RankingIndex(handles.Count);

% set rim of image to colour of their score, if it's scored
if ~isempty(handles.ManualScore{IndexToAccess})
    if ismember(str2double(handles.ManualScore{IndexToAccess}), handles.DatabaseLabelsOfCorrespondingColours)
        ImRim(1,1,1:3) = uint8(handles.ScoringColours(handles.DatabaseLabelsOfCorrespondingColours==str2double(handles.ManualScore{IndexToAccess}),:));
    else % colour not supported (yet), set as (almost) black. 
        ImRim(1,1,1:3) =  uint8([1 1 1]);
    end
end
% get human-sensible score. 
ScoreToDisplay = DatabaseScore2HumanScore(handles.ManualScore{IndexToAccess});
% update stem.
axes(handles.axes2);
set(handles.CountLine, 'XData', handles.Count, 'YData', handles.Scores(IndexToAccess)); 

% 3 drop viewing method without play on. (when play is on, side subwells
% are not shown.
if handles.ViewMethod == 3 && ~get(handles.PlayPause, 'Value')
    switch mod(IndexToAccess,3) % identify sub-well type
        case 1 % Subwell A
            axes(handles.axes1);
            if isempty(ScoreToDisplay)
                h = imagesc(permute(imread(handles.Filepaths{IndexToAccess}), [2 1 3]));
            else
                temp = permute(imread(handles.Filepaths{IndexToAccess}), [2 1 3]);
                temp([1:30 end-29:end], :,:) = repmat(ImRim, [size(temp([1:30 end-29:end],:,1)),1]);
                temp(:, [1:30 end-29:end],:) = repmat(ImRim, [size(temp(:,[1:30 end-29:end],1)),1]);
                h = imagesc(temp);
            end
            
            set(h, 'HitTest', 'off');
            set(handles.axes1, 'ButtonDownFcn', {@BlowUpImage, handles, handles.Filepaths{IndexToAccess}}, 'xtick', [], 'ytick', []); 
            axes(handles.axes8); imagesc(handles.Highlighted, [0 1]); colormap(handles.ColorMap); axis off;
            axes(handles.axes3); imagesc(handles.NotHighlighted, [0 1]); colormap(handles.ColorMap); axis off;
            axes(handles.axes4); imagesc(handles.NotHighlighted, [0 1]); colormap(handles.ColorMap); axis off;
            axes(handles.axes9); imagesc(handles.NotHighlighted, [0 1]); colormap(handles.ColorMap); axis off;
            axes(handles.axes10); imagesc(handles.NotHighlighted, [0 1]); colormap(handles.ColorMap); axis off;
            
            % find where the other subwells are ranked
            IndexToAccessLeft = IndexToAccess + 1;
            IndexToAccessRight = IndexToAccess + 2;
            RankLeft = find(handles.RankingIndex ==  IndexToAccessLeft);
            RankRight = find(handles.RankingIndex ==  IndexToAccessRight);
            

            if ismember(IndexToAccess+1, handles.RankingIndex(1:handles.Count))
                % make image darker if it has already been seen
                ImLeft = permute(imread(handles.Filepaths{IndexToAccessLeft}), [2 1 3])-50; 
            else
                ImLeft = permute(imread(handles.Filepaths{IndexToAccessLeft}), [2 1 3]);
            end
            if ismember(IndexToAccess+2, handles.RankingIndex(1:handles.Count))
               ImRight = permute(imread(handles.Filepaths{IndexToAccessRight}), [2 1 3])-50; 
            else
               ImRight = permute(imread(handles.Filepaths{IndexToAccessRight}), [2 1 3]); 
            end
            
            axes(handles.axes3);
            h = imagesc(ImLeft);
            set(h, 'HitTest', 'off');
            set(handles.axes3, 'ButtonDownFcn', {@FocusSubwell, handles, RankLeft}, 'xtick', [], 'ytick', []);
            
            axes(handles.axes4);
            h = imagesc(ImRight);
            set(h, 'HitTest', 'off');
            set(handles.axes4, 'ButtonDownFcn', {@FocusSubwell, handles, RankRight}, 'xtick', [], 'ytick', []);
         
        case 2 % Subwell C
     
            axes(handles.axes3);
            if isempty(ScoreToDisplay)
                h = imagesc(permute(imread(handles.Filepaths{IndexToAccess}), [2 1 3]));
            else
                temp = permute(imread(handles.Filepaths{IndexToAccess}), [2 1 3]);
                temp([1:30 end-29:end], :,:) = repmat(ImRim, [size(temp([1:30 end-29:end],:,1)),1]);
                temp(:, [1:30 end-29:end],:) = repmat(ImRim, [size(temp(:,[1:30 end-29:end],1)),1]);
                h = imagesc(temp);
            end
            set(h, 'HitTest', 'off');
            set(handles.axes3, 'ButtonDownFcn', {@BlowUpImage, handles, handles.Filepaths{IndexToAccess}}, 'xtick', [], 'ytick', []);
            axes(handles.axes9); imagesc(handles.Highlighted, [0 1]);colormap(handles.ColorMap); axis off;
            axes(handles.axes1); imagesc(handles.NotHighlighted, [0 1]); colormap(handles.ColorMap); axis off;
            axes(handles.axes4); imagesc(handles.NotHighlighted, [0 1]); colormap(handles.ColorMap); axis off;
            axes(handles.axes8); imagesc(handles.NotHighlighted, [0 1]); colormap(handles.ColorMap); axis off;
            axes(handles.axes10); imagesc(handles.NotHighlighted, [0 1]); colormap(handles.ColorMap); axis off;
           
            % find where the other subwells are ranked
            IndexToAccessLeft = IndexToAccess-1;
            IndexToAccessRight = IndexToAccess+1;
            RankLeft = find(handles.RankingIndex == IndexToAccessLeft);
            RankRight = find(handles.RankingIndex == IndexToAccessRight);
           
            
            if ismember(IndexToAccess-1, handles.RankingIndex(1:handles.Count))
                ImLeft = permute(imread(handles.Filepaths{IndexToAccessLeft}), [2 1 3])-50; 
            else
                ImLeft = permute(imread(handles.Filepaths{IndexToAccessLeft}), [2 1 3]); 
            end
            if ismember(IndexToAccess+1, handles.RankingIndex(1:handles.Count))
                ImRight = permute(imread(handles.Filepaths{IndexToAccessRight}), [2 1 3])-50;
            else
                ImRight = permute(imread(handles.Filepaths{IndexToAccessRight}), [2 1 3]); 
            end
            
            axes(handles.axes1);
            h = imagesc(ImLeft);
            set(h, 'HitTest', 'off');
            set(handles.axes1, 'ButtonDownFcn', {@FocusSubwell, handles, RankLeft}, 'xtick', [], 'ytick', []);
            
            axes(handles.axes4);
            h = imagesc(ImRight);
            set(h, 'HitTest', 'off');
            set(handles.axes4, 'ButtonDownFcn', {@FocusSubwell, handles, RankRight}, 'xtick', [], 'ytick', []);
            
            
        case 0 % Subwell D
            axes(handles.axes4);
            if isempty(ScoreToDisplay)
                h = imagesc(permute(imread(handles.Filepaths{IndexToAccess}), [2 1 3]));
            else
                temp = permute(imread(handles.Filepaths{IndexToAccess}), [2 1 3]);
                temp([1:30 end-29:end], :,:) = repmat(ImRim, [size(temp([1:30 end-29:end],:,1)),1]);
                temp(:, [1:30 end-29:end],:) = repmat(ImRim, [size(temp(:,[1:30 end-29:end],1)),1]);
                h = imagesc(temp);
            end
            set(h, 'HitTest', 'off');
            set(handles.axes4, 'ButtonDownFcn', {@BlowUpImage, handles, handles.Filepaths{IndexToAccess}}, 'xtick', [], 'ytick', []);
            axes(handles.axes10); imagesc(handles.Highlighted, [0 1]);colormap(handles.ColorMap); axis off;
            axes(handles.axes1); imagesc(handles.NotHighlighted, [0 1]); colormap(handles.ColorMap); axis off; 
            axes(handles.axes3); imagesc(handles.NotHighlighted, [0 1]); colormap(handles.ColorMap); axis off;
            axes(handles.axes8); imagesc(handles.NotHighlighted, [0 1]); colormap(handles.ColorMap); axis off;
            axes(handles.axes9); imagesc(handles.NotHighlighted, [0 1]); colormap(handles.ColorMap); axis off;
                        
            % find where the other subwells are ranked
            IndexToAccessLeft = IndexToAccess-2;
            IndexToAccessRight = IndexToAccess-1;
            RankLeft = find(handles.RankingIndex == IndexToAccessLeft);
            RankRight = find(handles.RankingIndex == IndexToAccessRight);
            
            if ismember(IndexToAccess-2, handles.RankingIndex(1:handles.Count))
                ImLeft = permute(imread(handles.Filepaths{IndexToAccessLeft}), [2 1 3])-50; 
            else
                ImLeft = permute(imread(handles.Filepaths{IndexToAccessLeft}), [2 1 3]); 
            end
            if ismember(IndexToAccess-1, handles.RankingIndex(1:handles.Count))
                ImRight = permute(imread(handles.Filepaths{IndexToAccessRight}), [2 1 3])-50; 
            else
                ImRight = permute(imread(handles.Filepaths{IndexToAccessRight}), [2 1 3]);
            end
            
            axes(handles.axes1);
            h = imagesc(ImLeft);
            set(h, 'HitTest', 'off');
            set(handles.axes1, 'ButtonDownFcn', {@FocusSubwell, handles, RankLeft}, 'xtick', [], 'ytick', []);
            
            axes(handles.axes3);
            h = imagesc(ImRight);
            set(h, 'HitTest', 'off');
            set(handles.axes3, 'ButtonDownFcn', {@FocusSubwell, handles, RankRight}, 'xtick', [], 'ytick', []);
            
            
    end
% when play is on, only show one subwell for fast loading.    
elseif handles.ViewMethod == 3 && get(handles.PlayPause, 'Value')
    axes(handles.axes3)
    if isempty(ScoreToDisplay)
        imagesc(permute(imread(handles.Filepaths{IndexToAccess}), [2 1 3])); axis off;
    else
        temp = permute(imread(handles.Filepaths{IndexToAccess}), [2 1 3]);
        temp([1:30 end-29:end], :,:) = repmat(ImRim, [size(temp([1:30 end-29:end],:,1)),1]);
        temp(:, [1:30 end-29:end],:) = repmat(ImRim, [size(temp(:,[1:30 end-29:end],1)),1]);
        imagesc(temp); axis off;
    end
    
% 1 subwell view    
elseif handles.ViewMethod == 1
    axes(handles.axes11);
    if isempty(ScoreToDisplay)
        h = imagesc(imread(handles.Filepaths{IndexToAccess}));
    else
        temp = imread(handles.Filepaths{IndexToAccess}); 
        temp([1:30 end-29:end], :,:) = repmat(ImRim, [size(temp([1:30 end-29:end],:,1)),1]);
        temp(:, [1:30 end-29:end],:) = repmat(ImRim, [size(temp(:,[1:30 end-29:end],1)),1]);
        h = imagesc(temp);
    end
    set(h, 'HitTest', 'off');
    set(handles.axes11, 'ButtonDownFcn', {@ShrinkImage, handles,handles.Filepaths{IndexToAccess}}, 'xtick', [], 'ytick', []);
    
    if handles.ShowHistoryFlag
        switch length(handles.HistoryFilepaths)
            case 1
                axes(handles.History1);
                h = imagesc(imread(handles.HistoryFilepaths{1}{IndexToAccess})); 
                set(h, 'HitTest', 'off');
                set(handles.History1, 'ButtonDownFcn', {@OpenHistoryImage, handles, handles.History1,handles.Filepaths{IndexToAccess},handles.HistoryFilepaths{1}{IndexToAccess}}, 'xtick', [], 'ytick', []); 
                set(handles.History1Text, 'String', ['Insp: ' num2str(handles.HistoryToShow(1))]);
            case 2
                axes(handles.History1);
                h = imagesc(imread(handles.HistoryFilepaths{1}{IndexToAccess}));
                set(h, 'HitTest', 'off');
                set(handles.History1, 'ButtonDownFcn', {@OpenHistoryImage, handles, handles.History1,handles.Filepaths{IndexToAccess},handles.HistoryFilepaths{1}{IndexToAccess}}, 'xtick', [], 'ytick', []); 
                set(handles.History1Text, 'String', ['Insp: ' num2str(handles.HistoryToShow(1))]);
                
                axes(handles.History2);
                h = imagesc(imread(handles.HistoryFilepaths{2}{IndexToAccess}));
                set(h, 'HitTest', 'off');
                set(handles.History2, 'ButtonDownFcn', {@OpenHistoryImage, handles, handles.History2,handles.Filepaths{IndexToAccess},handles.HistoryFilepaths{2}{IndexToAccess}}, 'xtick', [], 'ytick', []); 
                set(handles.History2Text, 'String', ['Insp: ' num2str(handles.HistoryToShow(2))]);
            case 3
                axes(handles.History1);
                h = imagesc(imread(handles.HistoryFilepaths{1}{IndexToAccess})); 
                set(h, 'HitTest', 'off');
                set(handles.History1, 'ButtonDownFcn', {@OpenHistoryImage, handles, handles.History1,handles.Filepaths{IndexToAccess},handles.HistoryFilepaths{1}{IndexToAccess}}, 'xtick', [], 'ytick', []); 
                set(handles.History1Text, 'String', ['Insp: ' num2str(handles.HistoryToShow(1))]);
                
                axes(handles.History2);
                h = imagesc(imread(handles.HistoryFilepaths{2}{IndexToAccess}));
                set(h, 'HitTest', 'off');
                set(handles.History2, 'ButtonDownFcn', {@OpenHistoryImage, handles, handles.History2,handles.Filepaths{IndexToAccess},handles.HistoryFilepaths{2}{IndexToAccess}}, 'xtick', [], 'ytick', []); 
                set(handles.History2Text, 'String', ['Insp: ' num2str(handles.HistoryToShow(2))]);
                
                axes(handles.History3);
                h = imagesc(imread(handles.HistoryFilepaths{3}{IndexToAccess}));
                set(h, 'HitTest', 'off');
                set(handles.History3, 'ButtonDownFcn', {@OpenHistoryImage, handles, handles.History3,handles.Filepaths{IndexToAccess},handles.HistoryFilepaths{3}{IndexToAccess}}, 'xtick', [], 'ytick', []); 
                set(handles.History3Text, 'String', ['Insp: ' num2str(handles.HistoryToShow(3))]);
        end
    end
end

% update information display
set(handles.WellDisplay, 'string', handles.Subwelltext{IndexToAccess});
set(handles.ConditionsDisplay, 'string', handles.ScreenConditions{ceil(IndexToAccess/3)});
set(handles.ScoreDisplay, 'string', num2str(handles.Scores(IndexToAccess)));
set(handles.ManualScoreDisplay, 'string', ScoreToDisplay);
axes(handles.axes2);

if get(handles.PlayPause, 'Value') || handles.ViewMethod == 1
    % do not plot
else
    set(handles.PlotLeft, 'XData', RankLeft, 'YData', handles.Scores(IndexToAccessLeft));
    set(handles.PlotRight, 'XData', RankRight, 'YData', handles.Scores(IndexToAccessRight));
end
set(handles.NavigateThroughPlate, 'Value', handles.Count);
set(handles.SliderCount, 'string', num2str(handles.Count));

% Simimilar function to UpdateDisplay, except for changing subwell focus,
% don't turn off and on the side subwells - keep them as they are
function UpdateDisplay_ChangeSubwellFocus(hObject, eventdata, handles)

IndexToAccess = handles.RankingIndex(handles.Count);

% set rim of image to colour of their score, if it's scored
if ~isempty(handles.ManualScore{IndexToAccess})
    if ismember(str2double(handles.ManualScore{IndexToAccess}), handles.DatabaseLabelsOfCorrespondingColours)
        ImRim(1,1,1:3) = uint8(handles.ScoringColours(handles.DatabaseLabelsOfCorrespondingColours==str2double(handles.ManualScore{IndexToAccess}),:));
    else % colour not supported (yet), set as (almost) black. 
        ImRim(1,1,1:3) =  uint8([1 1 1]);
    end
end
% get human-sensible score. 
ScoreToDisplay = DatabaseScore2HumanScore(handles.ManualScore{IndexToAccess});
    
if handles.ViewMethod == 3 && ~get(handles.PlayPause, 'Value')
    switch mod(IndexToAccess,3)
        case 1 % Subwell A
            axes(handles.axes1);
            if isempty(ScoreToDisplay)
                h = imagesc(permute(imread(handles.Filepaths{IndexToAccess}), [2 1 3]));
            else
                temp = permute(imread(handles.Filepaths{IndexToAccess}), [2 1 3]);
                temp([1:30 end-29:end], :,:) = repmat(ImRim, [size(temp([1:30 end-29:end],:,1)),1]);
                temp(:, [1:30 end-29:end],:) = repmat(ImRim, [size(temp(:,[1:30 end-29:end],1)),1]);
                h = imagesc(temp);
            end
            
            set(h, 'HitTest', 'off');
            set(handles.axes1, 'ButtonDownFcn', {@BlowUpImage, handles,handles.Filepaths{IndexToAccess}}, 'xtick', [], 'ytick', []); 
            axes(handles.axes8); imagesc(handles.Highlighted, [0 1]); colormap(handles.ColorMap); axis off;
            axes(handles.axes9); imagesc(handles.NotHighlighted, [0 1]); colormap(handles.ColorMap); axis off;
            axes(handles.axes10); imagesc(handles.NotHighlighted, [0 1]); colormap(handles.ColorMap); axis off;
            
            % find where the other subwells are ranked
            IndexToAccessLeft = IndexToAccess + 1;
            IndexToAccessRight = IndexToAccess + 2;
            RankLeft = find(handles.RankingIndex ==  IndexToAccessLeft);
            RankRight = find(handles.RankingIndex ==  IndexToAccessRight);
            
            if ismember(IndexToAccess+1, handles.RankingIndex(1:handles.Count))
                ImLeft = permute(imread(handles.Filepaths{IndexToAccessLeft}), [2 1 3])-50;
            else
                ImLeft = permute(imread(handles.Filepaths{IndexToAccessLeft}), [2 1 3]);
            end
            if ismember(IndexToAccess+2, handles.RankingIndex(1:handles.Count))
               ImRight = permute(imread(handles.Filepaths{IndexToAccessRight}), [2 1 3])-50; 
            else
               ImRight = permute(imread(handles.Filepaths{IndexToAccessRight}), [2 1 3]); 
            end
            
            axes(handles.axes3);
            h = imagesc(ImLeft);
            set(h, 'HitTest', 'off');
            set(handles.axes3, 'ButtonDownFcn', {@FocusSubwell, handles, RankLeft}, 'xtick', [], 'ytick', []);
            
            axes(handles.axes4);
            h = imagesc(ImRight);
            set(h, 'HitTest', 'off');
            set(handles.axes4, 'ButtonDownFcn', {@FocusSubwell, handles, RankRight}, 'xtick', [], 'ytick', []);
         
        case 2 % Subwell C
            axes(handles.axes3);
            if isempty(ScoreToDisplay)
                h = imagesc(permute(imread(handles.Filepaths{IndexToAccess}), [2 1 3]));
            else
                temp = permute(imread(handles.Filepaths{IndexToAccess}), [2 1 3]);
                temp([1:30 end-29:end], :,:) = repmat(ImRim, [size(temp([1:30 end-29:end],:,1)),1]);
                temp(:, [1:30 end-29:end],:) = repmat(ImRim, [size(temp(:,[1:30 end-29:end],1)),1]);
                h = imagesc(temp);
            end
            set(h, 'HitTest', 'off');
            set(handles.axes3, 'ButtonDownFcn', {@BlowUpImage, handles, handles.Filepaths{IndexToAccess}}, 'xtick', [], 'ytick', []);
            axes(handles.axes9); imagesc(handles.Highlighted, [0 1]);colormap(handles.ColorMap); axis off;
            axes(handles.axes8); imagesc(handles.NotHighlighted, [0 1]); colormap(handles.ColorMap); axis off;
            axes(handles.axes10); imagesc(handles.NotHighlighted, [0 1]); colormap(handles.ColorMap); axis off;
           
            % find where the other subwells are ranked
            IndexToAccessLeft = IndexToAccess-1;
            IndexToAccessRight = IndexToAccess+1;
            RankLeft = find(handles.RankingIndex == IndexToAccessLeft);
            RankRight = find(handles.RankingIndex == IndexToAccessRight);
 
            if ismember(IndexToAccess-1, handles.RankingIndex(1:handles.Count))
                ImLeft = permute(imread(handles.Filepaths{IndexToAccessLeft}), [2 1 3])-50; 
            else
                ImLeft = permute(imread(handles.Filepaths{IndexToAccessLeft}), [2 1 3]); 
            end
            if ismember(IndexToAccess+1, handles.RankingIndex(1:handles.Count))
                ImRight = permute(imread(handles.Filepaths{IndexToAccessRight}), [2 1 3])-50;
            else
                ImRight = permute(imread(handles.Filepaths{IndexToAccessRight}), [2 1 3]); 
            end
            
            axes(handles.axes1);
            h = imagesc(ImLeft);
            set(h, 'HitTest', 'off');
            set(handles.axes1, 'ButtonDownFcn', {@FocusSubwell, handles, RankLeft}, 'xtick', [], 'ytick', []);
            
            axes(handles.axes4);
            h = imagesc(ImRight);
            set(h, 'HitTest', 'off');
            set(handles.axes4, 'ButtonDownFcn', {@FocusSubwell, handles, RankRight}, 'xtick', [], 'ytick', []);
            
            
        case 0 % Subwell D
            axes(handles.axes4);
            if isempty(ScoreToDisplay)
                h = imagesc(permute(imread(handles.Filepaths{IndexToAccess}), [2 1 3]));
            else
                temp = permute(imread(handles.Filepaths{IndexToAccess}), [2 1 3]);
                temp([1:30 end-29:end], :,:) = repmat(ImRim, [size(temp([1:30 end-29:end],:,1)),1]);
                temp(:, [1:30 end-29:end],:) = repmat(ImRim, [size(temp(:,[1:30 end-29:end],1)),1]);
                h = imagesc(temp);
            end
            set(h, 'HitTest', 'off');
            set(handles.axes4, 'ButtonDownFcn', {@BlowUpImage, handles, handles.Filepaths{IndexToAccess}}, 'xtick', [], 'ytick', []);
            axes(handles.axes10); imagesc(handles.Highlighted, [0 1]);colormap(handles.ColorMap); axis off;
            axes(handles.axes8); imagesc(handles.NotHighlighted, [0 1]); colormap(handles.ColorMap); axis off;
            axes(handles.axes9); imagesc(handles.NotHighlighted, [0 1]); colormap(handles.ColorMap); axis off;
            
            % find where the other subwells are ranked
            IndexToAccessLeft = IndexToAccess-2;
            IndexToAccessRight = IndexToAccess-1;
            RankLeft = find(handles.RankingIndex == IndexToAccessLeft);
            RankRight = find(handles.RankingIndex == IndexToAccessRight);
            
            if ismember(IndexToAccess-2, handles.RankingIndex(1:handles.Count))
                ImLeft = permute(imread(handles.Filepaths{IndexToAccessLeft}), [2 1 3])-50; 
            else
                ImLeft = permute(imread(handles.Filepaths{IndexToAccessLeft}), [2 1 3]); 
            end
            if ismember(IndexToAccess-1, handles.RankingIndex(1:handles.Count))
                ImRight = permute(imread(handles.Filepaths{IndexToAccessRight}), [2 1 3])-50; 
            else
                ImRight = permute(imread(handles.Filepaths{IndexToAccessRight}), [2 1 3]);
            end
            
            axes(handles.axes1);
            h = imagesc(ImLeft);
            set(h, 'HitTest', 'off');
            set(handles.axes1, 'ButtonDownFcn', {@FocusSubwell, handles, RankLeft}, 'xtick', [], 'ytick', []);
            
            axes(handles.axes3);
            h = imagesc(ImRight);
            set(h, 'HitTest', 'off');
            set(handles.axes3, 'ButtonDownFcn', {@FocusSubwell, handles, RankRight}, 'xtick', [], 'ytick', []);
            
            
    end

end

set(handles.WellDisplay, 'string', handles.Subwelltext{IndexToAccess});
set(handles.ScoreDisplay, 'string', num2str(handles.Scores(IndexToAccess)));
set(handles.ManualScoreDisplay, 'string', ScoreToDisplay);
% set(handles.ImageCountDisplay, 'string', handles.Count);
axes(handles.axes2);
% set(handles.CountLine, 'XData', handles.Count, 'YData', handles.Scores(IndexToAccess)); 
if get(handles.PlayPause, 'Value') || handles.ViewMethod == 1
    % do not plot
else
    set(handles.PlotLeft, 'XData', RankLeft, 'YData', handles.Scores(IndexToAccessLeft));
    set(handles.PlotRight, 'XData', RankRight, 'YData', handles.Scores(IndexToAccessRight));
end
set(handles.NavigateThroughPlate, 'Value', handles.Count);
set(handles.SliderCount, 'string', num2str(handles.Count));

% --- Executes on button press in SortByLastInspection.
function SortByLastInspection_Callback(hObject, eventdata, handles)
% sort plates for a project by last inspection date (default sorted by set
% up date).
SelectedProject = handles.ListOfProjects{get(handles.ProjectList,'Value')};
if get(handles.SortByLastInspection, 'Value')
    SortedList = getDataFromCRYSTAL(SelectedProject, 'ListOfBarcodesOrderByLastInspection', handles.CrystalConn);
    OldList = get(handles.BarcodeListBox, 'string');
    OldListBarcodeOnly = cellfun(@(x) x(1:8), OldList, 'UniformOutput', 0);
    NewList = cellfun(@(x) find(strcmp(x, SortedList(:,1))==1),OldListBarcodeOnly);
    NewList = OldList(NewList);
    %swap dates to last inspection date
    LastInspDate = cellfun(@(x) datestr(x, 'dd-mm-yyyy'), SortedList(:,2), 'UniformOutput', 0);
    NewList = cellfun(@(x, y) [x(1:18) y x(29:end)], NewList, LastInspDate, 'UniformOutput', 0);
    set(handles.BarcodeListBox, 'string', NewList);
    guidata(hObject, handles);
    set(handles.SortByLastInspection, 'Enable', 'off');
    drawnow;
    set(handles.SortByLastInspection, 'Enable', 'on'); 
else
    ProjectList_Callback(hObject, eventdata, handles);
end

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
delete(hObject);



% ----------------------------------------------------------------------- %
% ----------------------------------------------------------------------- %
% 2: UI Button Callbacks
% ***  a. Navigations  *** %

% --- Executes on button press in BackButton.
function BackButton_Callback(hObject, eventdata, handles)
% hObject    handle to BackButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.Count = handles.Count-1;
if handles.Count < 1
    handles.Count = 288; % Go back
end
UpdateDisplay(hObject, eventdata, handles);
guidata(hObject,handles)
set(handles.BackButton, 'Enable', 'off');
drawnow;
set(handles.BackButton, 'Enable', 'on');

% --- Executes on button press in ForwardButton.
function ForwardButton_Callback(hObject, eventdata, handles)
% hObject    handle to ForwardButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.Count = handles.Count+1;
if handles.Count > 288
    handles.Count = 1; % Go back
end
UpdateDisplay(hObject, eventdata, handles);
guidata(hObject,handles);
set(handles.ForwardButton, 'Enable', 'off');
drawnow;
set(handles.ForwardButton, 'Enable', 'on');

% --- Executes on slider movement.
function NavigateThroughPlate_Callback(hObject, eventdata, handles)
% navigate to droplets using the scroll bar.
handles.Count = round(get(hObject, 'Value'));
set(handles.SliderCount, 'String', num2str(handles.Count));
if handles.Count > 288
    handles.Count = 1; % Go back
end
UpdateDisplay(hObject, eventdata, handles);
guidata(hObject,handles);
set(handles.NavigateThroughPlate, 'Enable', 'off');
drawnow;
set(handles.NavigateThroughPlate, 'Enable', 'on');

% --- for continuous update of slider number
function UpdateSliderNumber(src, eventdata, handles)
handles.Count = round(get(handles.NavigateThroughPlate, 'Value'));
set(handles.SliderCount, 'String', num2str(handles.Count));
set(handles.CountLine, 'XData', handles.Count, 'YData', handles.Scores(handles.RankingIndex(handles.Count)));

% --- Allow users to jump to a specific subwell.
function SubwellInput_Callback(hObject, eventdata, handles)

% --- When users hit enter on SubwellInput
function SubwellInput_KeyPressFcn(hObject, eventdata, handles)
if strcmp(eventdata.Key, 'return')
    pause(0.1);
    SubwellString = get(handles.SubwellInput, 'String');
    SubwellString = regexprep(SubwellString,'[^\w'']','');
    Row = upper(SubwellString(1));
    SubWell = lower(SubwellString(end));
    Col = str2double(SubwellString(2:end-1));
    Index = FindIndex(Row, Col, SubWell);
    if Index
        handles.Count = find(handles.RankingIndex == Index);
        guidata(hObject, handles);
        UpdateDisplay(handles.figure1, eventdata, handles);
        set(handles.SubwellInput, 'Enable', 'off');
        drawnow;
        set(handles.SubwellInput, 'Enable', 'on');
    end
end


% *********************************************************************** %
% *** b. UI Functionality *** %

% --- Keyboard shortcuts
function figure1_KeyPressFcn(hObject, eventdata, handles)
if handles.KeyPressFlag
    handles.KeyPressFlag = 0;
    guidata(hObject, handles);
    switch eventdata.Key
        case 'leftarrow'
            BackButton_Callback(hObject, eventdata, handles);
        case 'rightarrow'
            ForwardButton_Callback(hObject, eventdata, handles);
        case 'space'
            handles.KeyPressFlag = 1;
            guidata(hObject, handles);
            set(handles.PlayPause, 'Value', ~get(handles.PlayPause, 'Value'));
            PlayPause_Callback(hObject, eventdata, handles);
        case 'z'
            set(handles.WellSubwellToggle, 'Value', 1);
            WellSubwellToggle_Callback(hObject, '', handles);
            handles.ViewMethod = 1;
            guidata(hObject, handles);
            set(handles.ShowHistoryChkBox, 'Value', 1);
            ShowHistoryChkBox_Callback(hObject, '', handles);
        case 'escape'
            set(handles.WellSubwellToggle, 'Value', 0);
            set(handles.ShowHistoryChkBox, 'Value', 0);
            handles.ViewMethod = 3;
            guidata(hObject, handles);
            WellSubwellToggle_Callback(hObject, '', handles);
        case 'c'
            ClearBtn_Callback(hObject, eventdata, handles);
        case 'd'
            DenaturedBtn_Callback(hObject, eventdata, handles);
        case {'1' 'numpad1'}
            Score1Btn_Callback(hObject, eventdata, handles);
        case {'2' 'numpad2'}
            Score2Btn_Callback(hObject, eventdata, handles);
        case {'3' 'numpad3'}
            Score3Btn_Callback(hObject, eventdata, handles);
        case {'4' 'numpad4'}
            Score4Btn_Callback(hObject, eventdata, handles);
        case {'5' 'numpad5'}
            Score5Btn_Callback(hObject, eventdata, handles);
        case {'6' 'numpad6'}
            Score6Btn_Callback(hObject, eventdata, handles);
        case {'7' 'numpad7'}
            Score7Btn_Callback(hObject, eventdata, handles);
        case {'8' 'numpad8'}
            Score8Btn_Callback(hObject, eventdata, handles);
        case {'9' 'numpad9'}
            Score9Btn_Callback(hObject, eventdata, handles);
        case {'0' 'numpad0'}
            Score10Btn_Callback(hObject, eventdata, handles);
        case 'h'
            HeavyPBtn_Callback(hObject, eventdata, handles);
        case 'g'
            DetXtalsBtn_Callback(hObject, eventdata, handles);
        case 'e'
            PhaseSepBtn_Callback(hObject, eventdata, handles);
        case 's'
            SpherolitesBtn_Callback(hObject, eventdata, handles);
        case 'l'
            LightPBtn_Callback(hObject, eventdata, handles);
        case 'home'
            handles.Count = 1;
            guidata(hObject,handles);
            UpdateDisplay(hObject, '', handles);
    end
    handles = guidata(handles.figure1);
    handles.KeyPressFlag = 1;
    guidata(hObject, handles);
else % key hold , just wait!

   
end

% --- Toggle between 3 <-> 1 subwell view
function WellSubwellToggle_Callback(hObject, eventdata, handles)
SubWellOnly = get(handles.WellSubwellToggle, 'Value');
if SubWellOnly
    axes(handles.axes1); axis off;set(allchild(handles.axes1),'visible','off'); 
    axes(handles.axes3); axis off;set(allchild(handles.axes3),'visible','off'); 
    axes(handles.axes4); axis off;set(allchild(handles.axes4),'visible','off'); 
    set(allchild(handles.axes8),'visible','off'); 
    set(allchild(handles.axes9),'visible','off'); 
    set(allchild(handles.axes10),'visible','off'); 
    set(allchild(handles.axes11),'Visible', 'on');
    
    handles.ShowHistoryFlag = 0; %default - don't show!
    set(handles.ShowHistoryChkBox, 'visible', 'on', 'Value', 0);
    set(allchild(handles.History1),'visible', 'off');
    set(allchild(handles.History2),'visible', 'off');
    set(allchild(handles.History3),'visible', 'off');
    set(allchild(handles.History1Text),'visible', 'off');
    set(allchild(handles.History2Text),'visible', 'off');
    set(allchild(handles.History3Text),'visible', 'off');

    handles.ViewMethod = 1;
    set(handles.WellSubwellToggle, 'string', '3 Subwells', 'BackgroundColor', [0.96 0.92 0.92]);
else
    set(handles.ShowHistoryChkBox, 'Value', 0);
    ShowHistoryChkBox_Callback(hObject, eventdata, handles)
    set(allchild(handles.axes1),'visible','on'); 
    set(allchild(handles.axes3),'visible','on'); 
    set(allchild(handles.axes4),'visible','on'); 
    set(allchild(handles.axes8),'visible','on'); 
    set(allchild(handles.axes9),'visible','on'); 
    set(allchild(handles.axes10),'visible','on'); 
    axes(handles.axes11);axis off;set(allchild(handles.axes11),'visible', 'off');
    set(handles.ShowHistoryChkBox, 'visible', 'off');
    axes(handles.History1);axis off;set(allchild(handles.History1),'visible', 'off');
    axes(handles.History2);axis off;set(allchild(handles.History2),'visible', 'off');
    axes(handles.History3);axis off;set(allchild(handles.History3),'visible', 'off');
    set(allchild(handles.History1Text),'visible', 'off');
    set(allchild(handles.History2Text),'visible', 'off');
    set(allchild(handles.History3Text),'visible', 'off');
    handles.ViewMethod = 3;
    set(handles.WellSubwellToggle, 'string', '1 Subwell', 'BackgroundColor', [0.94 0.94 0.94]);
end
guidata(hObject,handles);
UpdateDisplay(hObject, eventdata, handles);
set(handles.WellSubwellToggle, 'Enable', 'off');
drawnow;
set(handles.WellSubwellToggle, 'Enable', 'on');

% --- Toggle between play or pause. 
function PlayPause_Callback(hObject, eventdata, handles)
if ~get(handles.PlayPause, 'Value')
    set(handles.PlayPause, 'string', 'Play');
    set(handles.ShowHistoryChkBox, 'enable', 'on', 'Value', 1);
    set(handles.WellSubwellToggle, 'enable', 'on');
    handles.ShowHistoryFlag = 1;
  
    guidata(hObject, handles);
    UpdateDisplay(hObject, eventdata, handles)
    set(handles.PlayPause, 'Enable', 'off');
    drawnow;
    set(handles.PlayPause, 'Enable', 'on');
end

if get(handles.PlayPause, 'Value') && handles.ViewMethod ~= 1
    axes(handles.axes1); imagesc(handles.NotHighlighted, [0 1]); colormap(handles.ColorMap); axis off;
    axes(handles.axes4); imagesc(handles.NotHighlighted, [0 1]); colormap(handles.ColorMap); axis off;
    axes(handles.axes8); imagesc(handles.NotHighlighted, [0 1]); colormap(handles.ColorMap); axis off;
    axes(handles.axes9); imagesc(handles.NotHighlighted, [0 1]); colormap(handles.ColorMap); axis off;
    axes(handles.axes10); imagesc(handles.NotHighlighted, [0 1]); colormap(handles.ColorMap); axis off;
end

while get(handles.PlayPause, 'Value');
    set(handles.PlayPause, 'string', 'Pause');
    set(handles.ShowHistoryChkBox, 'enable', 'off');
    set(handles.WellSubwellToggle, 'enable', 'off');
    handles.ShowHistoryFlag = 0;
    handles.Count = handles.Count + 1;
    if handles.Count > 288
        handles.Count = 1; % Go back
    end
    guidata(hObject, handles);
    UpdateDisplay(hObject, eventdata, handles);
    
    if get(handles.FastPlay, 'Value')
        pause(0.05);
    else
        pause(0.3);
    end
    
end
if ~get(handles.PlayPause, 'Value')
    set(handles.PlayPause, 'string', 'Play');
    set(handles.ShowHistoryChkBox, 'enable', 'on', 'Value', 1);
    handles.ShowHistoryFlag = 1;
    guidata(hObject, handles);

end

% --- Executes on button press in FastPlay.
function FastPlay_Callback(hObject, eventdata, handles)
set(handles.FastPlay, 'Enable', 'off');
drawnow;
set(handles.FastPlay, 'Enable', 'on');

% --- Executes on button press in ShowHistoryChkBox.
function ShowHistoryChkBox_Callback(hObject, eventdata, handles)

if get(handles.ShowHistoryChkBox, 'Value')
    handles.ShowHistoryFlag = 1;
    set(allchild(handles.History1),'visible', 'on');
    set(allchild(handles.History2),'visible', 'on');
    set(allchild(handles.History3),'visible', 'on');
    set((handles.History1Text),'visible', 'on');
    set((handles.History2Text),'visible', 'on');
    set((handles.History3Text),'visible', 'on');
    
    IndexToAccess = handles.RankingIndex(handles.Count);

    switch length(handles.HistoryFilepaths)
        case 0
            set(allchild(handles.History1),'visible', 'off');
            set(allchild(handles.History2),'visible', 'off');
            set(allchild(handles.History3),'visible', 'off');
            set((handles.History1Text),'visible', 'off');
            set((handles.History2Text),'visible', 'off');
            set((handles.History3Text),'visible', 'off');
            
        case 1
            axes(handles.History1);
            h = imagesc(imread(handles.HistoryFilepaths{1}{IndexToAccess}));
            set(h, 'HitTest', 'off');
            set(handles.History1, 'ButtonDownFcn', {@OpenHistoryImage, handles, handles.History1,handles.Filepaths{IndexToAccess},handles.HistoryFilepaths{1}{IndexToAccess}}, 'xtick', [], 'ytick', []);
            set(handles.History1Text, 'String', ['Insp: ' num2str(handles.HistoryToShow(1))]);
        case 2
            axes(handles.History1);
            h = imagesc(imread(handles.HistoryFilepaths{1}{IndexToAccess}));
            set(h, 'HitTest', 'off');
            set(handles.History1, 'ButtonDownFcn', {@OpenHistoryImage, handles, handles.History1,handles.Filepaths{IndexToAccess},handles.HistoryFilepaths{1}{IndexToAccess}}, 'xtick', [], 'ytick', []);
            set(handles.History1Text, 'String', ['Insp: ' num2str(handles.HistoryToShow(1))]);
            
            axes(handles.History2);
            h = imagesc(imread(handles.HistoryFilepaths{2}{IndexToAccess}));
            set(h, 'HitTest', 'off');
            set(handles.History2, 'ButtonDownFcn', {@OpenHistoryImage, handles, handles.History2,handles.Filepaths{IndexToAccess},handles.HistoryFilepaths{2}{IndexToAccess}}, 'xtick', [], 'ytick', []);
            set(handles.History2Text, 'String', ['Insp: ' num2str(handles.HistoryToShow(2))]);
        case 3
            axes(handles.History1);
            h = imagesc(imread(handles.HistoryFilepaths{1}{IndexToAccess}));
            set(h, 'HitTest', 'off');
            set(handles.History1, 'ButtonDownFcn', {@OpenHistoryImage, handles, handles.History1,handles.Filepaths{IndexToAccess},handles.HistoryFilepaths{1}{IndexToAccess}}, 'xtick', [], 'ytick', []);
            set(handles.History1Text, 'String', ['Insp: ' num2str(handles.HistoryToShow(1))]);
            
            axes(handles.History2);
            h = imagesc(imread(handles.HistoryFilepaths{2}{IndexToAccess}));
            set(h, 'HitTest', 'off');
            set(handles.History2, 'ButtonDownFcn', {@OpenHistoryImage, handles, handles.History2,handles.Filepaths{IndexToAccess},handles.HistoryFilepaths{2}{IndexToAccess}}, 'xtick', [], 'ytick', []);
            set(handles.History2Text, 'String', ['Insp: ' num2str(handles.HistoryToShow(2))]);
            
            axes(handles.History3);
            h = imagesc(imread(handles.HistoryFilepaths{3}{IndexToAccess}));
            set(h, 'HitTest', 'off');
            set(handles.History3, 'ButtonDownFcn', {@OpenHistoryImage, handles, handles.History3,handles.Filepaths{IndexToAccess},handles.HistoryFilepaths{3}{IndexToAccess}}, 'xtick', [], 'ytick', []);
            set(handles.History3Text, 'String', ['Insp: ' num2str(handles.HistoryToShow(3))]);
    end
else
    handles.ShowHistoryFlag = 0;
    set(allchild(handles.History1),'visible', 'off');
    set(allchild(handles.History2),'visible', 'off');
    set(allchild(handles.History3),'visible', 'off');
    set((handles.History1Text),'visible', 'off');
    set((handles.History2Text),'visible', 'off');
    set((handles.History3Text),'visible', 'off');
end
guidata(hObject, handles);
set(handles.ShowHistoryChkBox, 'Enable', 'off');
drawnow;
set(handles.ShowHistoryChkBox, 'Enable', 'on');
    
% --- Bring up thumbnail.
function ThumbnailBtn_Callback(hObject, eventdata, handles)

filepath = ['\\hestia\work\thumbnails\' handles.Barcode '-1.jpg'];

% draw coloured boxes on scored images(max Manual score)
Colours = uint8(handles.ScoringColours);
ScoreNumbers = handles.DatabaseLabelsOfCorrespondingColours; 

% retrieve scores
ScoredId = ~cellfun(@isempty, handles.ManualScore);
ScoredId = find(ScoredId==1);
PastScores = handles.ManualScore(ScoredId);

SubwellCol = ceil(ScoredId/24);
SubwellRow = ceil((ScoredId - (SubwellCol-1)*24)/3);
Subwell = mod(ScoredId,3);
SubWellTemp = Subwell;
SubWellTemp(Subwell == 1) = 1;
SubWellTemp(Subwell == 2) = 3;
SubWellTemp(Subwell == 0) = 4;
Subwell = SubWellTemp;
Coord = [SubwellCol SubwellRow Subwell];

ScoreThumbnail = uint8(zeros(1056, 1584,3));
Colours = permute(Colours,[3,1,2]);

for BoxToDraw = 1:size(Coord,1)
    Y = (1056 - (Coord(BoxToDraw,1)*88))+1:(1056 - (Coord(BoxToDraw,1)*88)+20);
    X = (Coord(BoxToDraw,2)-1)*198 + (max(Coord(BoxToDraw,3)-1,1)-1)*66 + 11: ...
        (Coord(BoxToDraw,2)-1)*198 + (max(Coord(BoxToDraw,3)-1,1))*66-10;
    try
        ScoreThumbnail(Y,X,:) = repmat(Colours(:,ScoreNumbers == str2double(PastScores{BoxToDraw}),:),[20 46 1]);
    catch er %Un-supported score. black.
        ScoreThumbnail(Y,X,:) = repmat(Colours(:,ScoreNumbers == 999,:),[20 46 1]);
    end
    
end

h = figure(1);
Thumbnail = imread(filepath);
TempMask = repmat(logical(sum(ScoreThumbnail,3)), [1 1 3]);
Thumbnail(TempMask) = ScoreThumbnail(TempMask);
hThumbnail = imshow(Thumbnail);

% iptsetpref('ImshowBorder','tight');
movegui(h, 'north');

% Set button down function : allow users to navigate to a droplet through
% this
set(hThumbnail, 'HitTest', 'off');
set(hThumbnail, 'ButtonDownFcn', {@Thumbnail_ButtonDownFcn, handles});
set(hThumbnail, 'HitTest', 'on');

set(handles.ThumbnailBtn, 'Enable', 'off');
drawnow;
set(handles.ThumbnailBtn, 'Enable', 'on');


% *********************************************************************** %
% *** c. Scoring *** %

% --- Executes on button press in ClearBtn.
function ClearBtn_Callback(hObject, eventdata, handles)
% hObject    handle to ClearBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.ManualScore{handles.RankingIndex(handles.Count)} = '01';
guidata(hObject,handles);
WriteScores(handles);
axes(handles.axes2); hold on; 
h = plot(handles.Count, handles.Scores(handles.RankingIndex(handles.Count)), 'd', 'color', [0 0 0]/255, 'MarkerFaceColor', [255 255 255]/255, 'MarkerSize',7); 
set(h, 'HitTest', 'off'); hold off;
ForwardButton_Callback(hObject, eventdata, handles);
set(handles.ClearBtn, 'Enable', 'off');
drawnow;
set(handles.ClearBtn, 'Enable', 'on');

% --- Executes on button press in DenaturedBtn.
function DenaturedBtn_Callback(hObject, eventdata, handles)
% hObject    handle to DenaturedBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.ManualScore{handles.RankingIndex(handles.Count)} = '15';
guidata(hObject,handles);
WriteScores(handles);
axes(handles.axes2); hold on; 
h = plot(handles.Count, handles.Scores(handles.RankingIndex(handles.Count)), 'd', 'color', [2 0 158]/255, 'MarkerFaceColor', [2 0 158]/255, 'MarkerSize',7); 
set(h, 'HitTest', 'off'); hold off;
ForwardButton_Callback(hObject, eventdata, handles);
set(handles.DenaturedBtn, 'Enable', 'off');
drawnow;
set(handles.DenaturedBtn, 'Enable', 'on');

% --- Executes on button press in Score1Btn.
function Score1Btn_Callback(hObject, eventdata, handles)
% hObject    handle to Score1Btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.ManualScore{handles.RankingIndex(handles.Count)} = '36';
guidata(hObject,handles);
WriteScores(handles);
axes(handles.axes2); hold on; 
h = plot(handles.Count, handles.Scores(handles.RankingIndex(handles.Count)), 'd', 'color', [255 128 253]/255, 'MarkerFaceColor', [255 128 253]/255, 'MarkerSize',7); 
set(h, 'HitTest', 'off'); hold off;
ForwardButton_Callback(hObject, eventdata, handles);
set(handles.Score1Btn, 'Enable', 'off');
drawnow;
set(handles.Score1Btn, 'Enable', 'on');

% --- Executes on button press in Score2Btn.
function Score2Btn_Callback(hObject, eventdata, handles)
% hObject    handle to Score2Btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.ManualScore{handles.RankingIndex(handles.Count)} = '37';
guidata(hObject,handles);
WriteScores(handles);
axes(handles.axes2); hold on; 
h = plot(handles.Count, handles.Scores(handles.RankingIndex(handles.Count)), 'd', 'color', [255 128 172]/255, 'MarkerFaceColor', [255 128 172]/255, 'MarkerSize',7); 
set(h, 'HitTest', 'off'); hold off;
ForwardButton_Callback(hObject, eventdata, handles);
set(handles.Score2Btn, 'Enable', 'off');
drawnow;
set(handles.Score2Btn, 'Enable', 'on');

% --- Executes on button press in Score3Btn.
function Score3Btn_Callback(hObject, eventdata, handles)
% hObject    handle to Score3Btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.ManualScore{handles.RankingIndex(handles.Count)} = '38';
guidata(hObject,handles);
WriteScores(handles);
axes(handles.axes2); hold on; 
h = plot(handles.Count, handles.Scores(handles.RankingIndex(handles.Count)), 'd',  'Color',[255 128 128]/255, 'MarkerFaceColor', [255 128 128]/255, 'MarkerSize',7);
set(h, 'HitTest', 'off'); hold off;
ForwardButton_Callback(hObject, eventdata, handles);
set(handles.Score3Btn, 'Enable', 'off');
drawnow;
set(handles.Score3Btn, 'Enable', 'on');

% --- Executes on button press in Score4Btn.
function Score4Btn_Callback(hObject, eventdata, handles)
% hObject    handle to Score4Btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.ManualScore{handles.RankingIndex(handles.Count)} = '39';
guidata(hObject,handles);
WriteScores(handles);
axes(handles.axes2); hold on; 
h = plot(handles.Count, handles.Scores(handles.RankingIndex(handles.Count)), 'd', 'color', [255 128 64]/255,'MarkerFaceColor', [255 128 64]/255,'MarkerSize',7 ); 
set(h, 'HitTest', 'off'); hold off;
ForwardButton_Callback(hObject, eventdata, handles);
set(handles.Score4Btn, 'Enable', 'off');
drawnow;
set(handles.Score4Btn, 'Enable', 'on');

% --- Executes on button press in Score5Btn.
function Score5Btn_Callback(hObject, eventdata, handles)
% hObject    handle to Score5Btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.ManualScore{handles.RankingIndex(handles.Count)} = '40';
guidata(hObject,handles);
WriteScores(handles);
axes(handles.axes2); hold on; 
h = plot(handles.Count, handles.Scores(handles.RankingIndex(handles.Count)), 'd', 'color', [255 128 0]/255,'MarkerFaceColor', [255 128 0]/255,'MarkerSize',7 ); 
set(h, 'HitTest', 'off'); hold off;
ForwardButton_Callback(hObject, eventdata, handles);
set(handles.Score5Btn, 'Enable', 'off');
drawnow;
set(handles.Score5Btn, 'Enable', 'on');

% --- Executes on button press in Score6Btn.
function Score6Btn_Callback(hObject, eventdata, handles)
% hObject    handle to Score6Btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.ManualScore{handles.RankingIndex(handles.Count)} = '41';
guidata(hObject,handles);
WriteScores(handles);
axes(handles.axes2); hold on; 
h = plot(handles.Count, handles.Scores(handles.RankingIndex(handles.Count)), 'd', 'color', [255 102 0]/255, 'MarkerFaceColor', [255 102 0]/255, 'MarkerSize',7); 
set(h, 'HitTest', 'off'); hold off;
ForwardButton_Callback(hObject, eventdata, handles);
set(handles.Score6Btn, 'Enable', 'off');
drawnow;
set(handles.Score6Btn, 'Enable', 'on');

% --- Executes on button press in Score7Btn.
function Score7Btn_Callback(hObject, eventdata, handles)
% hObject    handle to Score7Btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.ManualScore{handles.RankingIndex(handles.Count)} = '42';
guidata(hObject,handles);
WriteScores(handles);
axes(handles.axes2); hold on; 
h = plot(handles.Count, handles.Scores(handles.RankingIndex(handles.Count)), 'd', 'color', [255 68 0]/255, 'MarkerFaceColor', [255 68 0]/255, 'MarkerSize',7); 
set(h, 'HitTest', 'off'); hold off;
ForwardButton_Callback(hObject, eventdata, handles);
set(handles.Score7Btn, 'Enable', 'off');
drawnow;
set(handles.Score7Btn, 'Enable', 'on');

% --- Executes on button press in Score8Btn.
function Score8Btn_Callback(hObject, eventdata, handles)
% hObject    handle to Score8Btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.ManualScore{handles.RankingIndex(handles.Count)} = '43';
guidata(hObject,handles);
WriteScores(handles);
axes(handles.axes2); hold on;
h = plot(handles.Count, handles.Scores(handles.RankingIndex(handles.Count)), 'd', 'color', [255 38 0]/255, 'MarkerFaceColor', [255 38 0]/255, 'MarkerSize',7); 
set(h, 'HitTest', 'off'); hold off;
ForwardButton_Callback(hObject, eventdata, handles);
set(handles.Score8Btn, 'Enable', 'off');
drawnow;
set(handles.Score8Btn, 'Enable', 'on');

% --- Executes on button press in Score9Btn.
function Score9Btn_Callback(hObject, eventdata, handles)
% hObject    handle to Score9Btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.ManualScore{handles.RankingIndex(handles.Count)} = '44';
guidata(hObject,handles);
WriteScores(handles);
axes(handles.axes2); hold on; 
h = plot(handles.Count, handles.Scores(handles.RankingIndex(handles.Count)), 'd', 'color', [247 0 0]/255, 'MarkerFaceColor', [247 0 0]/255, 'MarkerSize',7); 
set(h, 'HitTest', 'off'); hold off;
ForwardButton_Callback(hObject, eventdata, handles);
set(handles.Score9Btn, 'Enable', 'off');
drawnow;
set(handles.Score9Btn, 'Enable', 'on');

% --- Executes on button press in Score10Btn.
function Score10Btn_Callback(hObject, eventdata, handles)
% hObject    handle to Score10Btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.ManualScore{handles.RankingIndex(handles.Count)} = '45';
guidata(hObject,handles);
WriteScores(handles);
axes(handles.axes2); hold on; 
h = plot(handles.Count, handles.Scores(handles.RankingIndex(handles.Count)), 'd', 'color', [255 0 0]/255, 'MarkerFaceColor', [255 0 0]/255, 'MarkerSize',7); 
set(h, 'HitTest', 'off'); hold off;
ForwardButton_Callback(hObject, eventdata, handles);
set(handles.Score10Btn, 'Enable', 'off');
drawnow;
set(handles.Score10Btn, 'Enable', 'on');

% --- Executes on button press in LightPBtn.
function LightPBtn_Callback(hObject, eventdata, handles)
% hObject    handle to LightPBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.ManualScore{handles.RankingIndex(handles.Count)} = '11';
guidata(hObject,handles);
WriteScores(handles);
axes(handles.axes2); hold on; 
h = plot(handles.Count, handles.Scores(handles.RankingIndex(handles.Count)), 'd', 'color', [154 233 239]/255, 'MarkerFaceColor', [154 233 239]/255, 'MarkerSize',7); 
set(h, 'HitTest', 'off'); hold off;
ForwardButton_Callback(hObject, eventdata, handles);
set(handles.HeavyPBtn, 'Enable', 'off');
drawnow;
set(handles.HeavyPBtn, 'Enable', 'on');

% --- Executes on button press in HeavyPBtn.
function HeavyPBtn_Callback(hObject, eventdata, handles)
% hObject    handle to HeavyPBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.ManualScore{handles.RankingIndex(handles.Count)} = '13';
guidata(hObject,handles);
WriteScores(handles);
axes(handles.axes2); hold on; 
h = plot(handles.Count, handles.Scores(handles.RankingIndex(handles.Count)), 'd', 'color', [0 0 255]/255, 'MarkerFaceColor', [0 0 255]/255, 'MarkerSize',7); 
set(h, 'HitTest', 'off'); hold off;
ForwardButton_Callback(hObject, eventdata, handles);
set(handles.HeavyPBtn, 'Enable', 'off');
drawnow;
set(handles.HeavyPBtn, 'Enable', 'on');

% --- Executes on button press in PhaseSepBtn.
function PhaseSepBtn_Callback(hObject, eventdata, handles)
% hObject    handle to PhaseSepBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.ManualScore{handles.RankingIndex(handles.Count)} = '32';
guidata(hObject,handles);
WriteScores(handles);
axes(handles.axes2); hold on; 
h = plot(handles.Count, handles.Scores(handles.RankingIndex(handles.Count)), 'd', 'color', [155 255 155]/255, 'MarkerFaceColor', [155 255 155]/255, 'MarkerSize',7); 
set(h, 'HitTest', 'off'); hold off;
ForwardButton_Callback(hObject, eventdata, handles);
set(handles.PhaseSepBtn, 'Enable', 'off');
drawnow;
set(handles.PhaseSepBtn, 'Enable', 'on');

% --- Executes on button press in DetXtalsBtn.
function DetXtalsBtn_Callback(hObject, eventdata, handles)
% hObject    handle to DetXtalsBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.ManualScore{handles.RankingIndex(handles.Count)} = '16';
guidata(hObject,handles);
WriteScores(handles);
axes(handles.axes2); hold on; 
h = plot(handles.Count, handles.Scores(handles.RankingIndex(handles.Count)), 'd', 'color', [196 196 196]/255, 'MarkerFaceColor', [196 196 196]/255, 'MarkerSize',7); 
set(h, 'HitTest', 'off'); hold off;
ForwardButton_Callback(hObject, eventdata, handles);
set(handles.DetXtalsBtn, 'Enable', 'off');
drawnow;
set(handles.DetXtalsBtn, 'Enable', 'on');

% --- Executes on button press in SpherolitesBtn.
function SpherolitesBtn_Callback(hObject, eventdata, handles)
% hObject    handle to SpherolitesBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.ManualScore{handles.RankingIndex(handles.Count)} = '33';
guidata(hObject,handles);
WriteScores(handles);
axes(handles.axes2); hold on; 
h = plot(handles.Count, handles.Scores(handles.RankingIndex(handles.Count)), 'd', 'color', [128 255 0]/255, 'MarkerFaceColor', [128 255 0]/255, 'MarkerSize',7); 
set(h, 'HitTest', 'off'); hold off;
ForwardButton_Callback(hObject, eventdata, handles);
set(handles.SpherolitesBtn, 'Enable', 'off');
drawnow;
set(handles.SpherolitesBtn, 'Enable', 'on');

% --- Write scores to database.
function WriteScores(handles)
%get scoreid - generate from sequence, ensure it does not clash with
%CrystalTrak.
curs = fetch(exec(handles.CrystalConn, 'select CRYSTAL.SEQ_JTNG_SCORE_ID.nextval from dual'));
scoreid = get(curs, 'Data');
close(curs);
scoreid = num2str(scoreid{1});

%get inspectid
inspectid = handles.InspectID{handles.RankingIndex(handles.Count)};
score = handles.ManualScore{handles.RankingIndex(handles.Count)};
scoredate = datestr(now);
imagename = handles.ImageName{handles.RankingIndex(handles.Count)};
scoredby = handles.Username;
exdata = {scoreid, inspectid, score, scoredate, imagename, scoredby};
fastinsert(handles.CrystalConn, ['CRYSTAL.' handles.TableName], handles.ColNames, exdata); %with AutoCommit. 
% update I_PLATE_INSPECTIONS.DROPSCORECOUNT
qry = ['update CRYSTAL.I_PLATE_INSPECTIONS set DROPSCORECOUNT = DROPSCORECOUNT + 1 where barcodeid = ''' handles.Barcode ''' and inspectnumber = ' num2str(handles.Inspection)];
tempcurs = exec(handles.CrystalConn, qry);
close(tempcurs);


% *********************************************************************** %
% *** d. Figure properties *** %

% --- Executes when figure1 is resized.
function figure1_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
XMarginLeft = 0;
XMarginRight = 2;
YMarginTop = 0.5;
YMarginBottom = 0;
ScreenSize = get(0, 'ScreenSize'); %start maximised
if isfield(handles, 'Username')
    NewFigureSize = get(hObject, 'Position');
    if NewFigureSize(1) == 0
        NewFigureSize(1) = 1;
        NewFigureSize(2) = 3.5;
    end
    NewWidth = NewFigureSize(3)-1;
    NewHeight = NewFigureSize(4)-1;
else
    set(0, 'Units', 'characters');
    ScreenSize = get(0, 'ScreenSize'); %start maximised
    NewFigureSize(1) = 1; NewFigureSize(2) = 3.5;
    NewWidth = ScreenSize(3)-1;
    NewHeight = ScreenSize(4)-1;
end
%minimum size
if NewHeight < 64.3
    NewHeight = 64.3;
end
if NewWidth < 323
    NewWidth = 323;
end

OldImagePos1 = get(handles.axes1, 'Position');

MaxNewImageWidth = (NewWidth - 60.16 - XMarginLeft - XMarginRight- 2.4 - 2.4)/3;
MaxNewImageHeight = NewHeight - 13.176 - YMarginTop - YMarginBottom;

if MaxNewImageWidth/MaxNewImageHeight > 1.9677
    %too wide
    MaxNewImageWidth = MaxNewImageHeight * 1.9677;
elseif MaxNewImageWidth/MaxNewImageHeight < 1.9677
    % too tall
    MaxNewImageHeight = MaxNewImageWidth / 1.9677;
else 
    % do nothing. accept.
end

NewImagePos1 = [OldImagePos1(1) OldImagePos1(2) MaxNewImageWidth MaxNewImageHeight];
NewImagePos2 = [OldImagePos1(1)+MaxNewImageWidth+2.4 OldImagePos1(2) MaxNewImageWidth MaxNewImageHeight];
NewImagePos3 = [NewImagePos2(1)+MaxNewImageWidth+2.4 OldImagePos1(2) MaxNewImageWidth MaxNewImageHeight];
set(handles.axes1, 'Position', NewImagePos1);
set(handles.axes3, 'Position', NewImagePos2);
set(handles.axes4, 'Position', NewImagePos3);

%move color bars
ColorBarPos = get(handles.axes8, 'Position');
set(handles.axes8, 'Position', [NewImagePos1(1) ColorBarPos(2) MaxNewImageWidth, ColorBarPos(4)]);
set(handles.axes9, 'Position', [NewImagePos2(1) ColorBarPos(2) MaxNewImageWidth, ColorBarPos(4)]);
set(handles.axes10, 'Position', [NewImagePos3(1) ColorBarPos(2) MaxNewImageWidth, ColorBarPos(4)]);

% move one subwell view
OneSubwellMainX = 79.6; OneSubwellMainY = 23.84615;
NewMainHeight = NewHeight - OneSubwellMainY - 0.4; %0.4 = margin on top
NewMainWidth = 0.6717*(NewWidth - OneSubwellMainX);
if NewMainWidth/NewMainHeight > 3.45
    NewMainWidth = NewMainHeight * 3.45;
else
    NewMainHeight = NewMainWidth/3.45;
end


set(handles.axes11, 'Position', [OneSubwellMainX, OneSubwellMainY, NewMainWidth, NewMainHeight]);
% move history images and texts
HistX = OneSubwellMainX + NewMainWidth + 18; %18 = space between main and hist ims.
NewHistHeight = (NewMainHeight/3) - 1.306; %1.306 = space between history ims
NewHistWidth = NewHistHeight *3.45;
HistTextPos = get(handles.History3Text, 'Position'); %fixed, not moving this one
set(handles.History3Text, 'Position', [HistX, HistTextPos(2:4)]);
set(handles.History3, 'Position', [HistX, HistTextPos(2)+1.306, NewHistWidth, NewHistHeight]);
set(handles.History2Text, 'Position', [HistX, HistTextPos(2)+1.306+NewHistHeight+0.2, HistTextPos(3), HistTextPos(4)]);
set(handles.History2, 'Position', [HistX, HistTextPos(2)+1.306+NewHistHeight+0.2+1.306, NewHistWidth, NewHistHeight]);
set(handles.History1Text, 'Position', [HistX, HistTextPos(2)+2*(1.306+NewHistHeight+0.2), HistTextPos(3), HistTextPos(4)]);
set(handles.History1, 'Position', [HistX, HistTextPos(2)+2*(1.306+NewHistHeight+0.2)+1.306, NewHistWidth, NewHistHeight]);


% snap it to min height and width.
if isfield(handles, 'Username')
    if get(handles.WellSubwellToggle, 'Value');
        MaxImHeight = OneSubwellMainY+NewMainHeight;
        MaxPanelHeight = 62.77;
        MinWidth = max(NewWidth, HistX+NewHistWidth+10)-1;
        set(handles.figure1, 'Position', [1, ScreenSize(4)-(max(MaxPanelHeight, MaxImHeight)+YMarginTop)-4.5, MinWidth, max(MaxPanelHeight, MaxImHeight)+YMarginTop]);
    else
        MaxImHeight = NewImagePos1(2)+MaxNewImageHeight;
        MaxPanelHeight = 62.77;
        MinWidth = max(NewWidth, NewImagePos3(1)+NewImagePos3(3))-1;
        set(handles.figure1, 'Position', [1, ScreenSize(4)-(max(MaxPanelHeight, MaxImHeight)+YMarginTop)-4.5, MinWidth, max(MaxPanelHeight, MaxImHeight)+YMarginTop]);
    
    end
else
    %start maximised
    MaxImHeight = NewImagePos1(2)+MaxNewImageHeight;
    MaxPanelHeight = 62.77;
    MinWidth = max(NewWidth, NewImagePos3(1)+NewImagePos3(3));
    set(handles.figure1, 'Position', [1, ScreenSize(4)-(max(MaxPanelHeight, MaxImHeight)+YMarginTop)-4.5, MinWidth, max(MaxPanelHeight, MaxImHeight)+YMarginTop]);
    
end

guidata(hObject, handles);
catch
%     do nothing
end
% proportions:  19% (60)                      
%               _____________________________
%              |      |                     |
%              |      |                     |
%              |      |      image area     | 
%              |      |    2.4 in btw images|
%              |      |_____________________|
%              |      |(60, 26.15)          | ~40% (26.15)
%              |______|_____________________|
% resize image area accordingly, keep everything else the same. 


% *********************************************************************** %
% *** e. Axes button down functions *** %

% --- click on subwell in focus in 3-subwell view:
% single click -> toggle to 1 subwell view
% double click -> bring up high res image with ruler. 
function BlowUpImage(src, eventdata, handles, filepath)
persistent chk
if isempty(chk) % single click
    chk = 1;
    pause(0.3);
    if chk == 1
      
        set(handles.WellSubwellToggle, 'Value', 1);
        handles.ViewMethod = 1;
        handles.KeyPressFlag = 1;
        guidata(src, handles);
        WellSubwellToggle_Callback(src, '', handles);
        set(handles.ShowHistoryChkBox, 'Value', 1);
        ShowHistoryChkBox_Callback(src, '', handles);
        chk = [];
    end
else % double click
    chk = [];
    h = figure(1);
    imshow(imread(filepath));
    iptsetpref('ImshowBorder','tight');
    movegui(h, 'north');
    set(h, 'KeyPressFcn', @HighResKeyPressFcn)
    hline = imdistline;
    api = iptgetapi(hline);
    api.setPosition([1000 1300;1221.04 1300]);
    api.setLabelTextFormatter(sprintf('%d um', round(api.getDistance()*1.131)));
    fcn = @(x) api.setLabelTextFormatter(sprintf('%d um', round(pdist(x)*1.131)));
    api.addNewPositionCallback(fcn);
end

% --- KeyPressFcn for high res image
function HighResKeyPressFcn(src, eventdata)
switch eventdata.Key
    case 'escape'
        close figure 1;
end

% --- Click on subwell not in focus in 3 subwell view
% single or double click -> subwell comes into focus
function FocusSubwell(src, eventdata, handles, Rank)
persistent chk;
if isempty(chk)
    chk = 1;
    pause(0.3);
    if chk == 1
        handles.Count = Rank;
        guidata(src, handles);
        UpdateDisplay_ChangeSubwellFocus(src, eventdata, handles);
        chk = [];
    end
else
    chk = [];
    handles.Count = Rank;
    guidata(src, handles);
    UpdateDisplay_ChangeSubwellFocus(src, eventdata, handles);
end

% --- Click on subwell in 1 subwell view.
% single click -> toggle to 3 subwell view
% double click -> bring up high res image with ruler. 
function ShrinkImage(src, eventdata, handles, filepath)
persistent chk

if isempty(chk) % single click
    chk = 1;
    pause(0.3);
    if chk == 1 
        set(handles.WellSubwellToggle, 'Value', 0);
        set(handles.ShowHistoryChkBox, 'Value', 0);
        handles.ViewMethod = 3;
        handles.KeyPressFlag = 1;
        guidata(src, handles);
        WellSubwellToggle_Callback(src, '', handles);
        chk = [];
    end
else % double click
    chk = [];
    h = figure(1);
    imshow(imread(filepath));
    iptsetpref('ImshowBorder','tight');
    movegui(h, 'north');
    hline = imdistline;
    api = iptgetapi(hline);
    api.setPosition([1000 1300;1221.04 1300]);
    api.setLabelTextFormatter(sprintf('%d um', round(api.getDistance()*1.131)));
    fcn = @(x) api.setLabelTextFormatter(sprintf('%d um', round(pdist(x)*1.131)));
    api.addNewPositionCallback(fcn);
end

% --- click on history image in 1 subwell view.
% single click -> do nothing
% double click -> bring up high res image with ruler. 
function OpenHistoryImage(src, eventdata, handles,AxesHandle, MainFilePath,HistoryFilePath)
persistent chk
if isempty(chk)
    chk = 1;
    pause(0.3);
    if chk == 1 
        %do nothing
    end
else % double click
    filepath = HistoryFilePath;
    % winopen(filepath);
    h = figure(1);
    imshow(imread(filepath));
    iptsetpref('ImshowBorder','tight');
    movegui(h, 'north');
    hline = imdistline;
    api = iptgetapi(hline);
    api.setPosition([1000 1300;1221.04 1300]);
    api.setLabelTextFormatter(sprintf('%d um', round(api.getDistance()*1.131)));
    fcn = @(x) api.setLabelTextFormatter(sprintf('%d um', round(pdist(x)*1.131)));
    api.addNewPositionCallback(fcn);

end

% --- click on profile plot
% jump to that droplet.
function axes2_ButtonDownFcn(hObject, eventdata, handles)
coordinates = get(hObject, 'CurrentPoint');
x = round(coordinates(1));
handles = guidata(hObject);
handles.Count = x;
guidata(hObject, handles); 
UpdateDisplay(hObject, eventdata, handles);

% --- click on thumbnail
% brings up ginput to allow users to select a subwell to view. 
function Thumbnail_ButtonDownFcn(hObject, eventdata, handles)
[x,y] = ginput(1);
Coordinates = round([x y]);
Row = floor(Coordinates(1)/198)+1;
SubWell = floor(mod(Coordinates(1), 198)/66)+1;
Col = floor((1056-Coordinates(2))/88)+1;
Index = FindIndex(Row, Col, SubWell);
if Index
    handles.Count = find(handles.RankingIndex == Index);
    guidata(handles.figure1, handles);
    UpdateDisplay(handles.figure1, eventdata, handles);
%     guidata(hObject, handles);
end



% ----------------------------------------------------------------------- %
% ----------------------------------------------------------------------- %
% 3: helper functions:
%
% ---- converting database entries to what users see
function HumanScore = DatabaseScore2HumanScore(DatabaseScore)
if isempty(DatabaseScore)
    HumanScore = '';
else
    switch DatabaseScore
        case '01'
            HumanScore = 'c';
        case '15'
            HumanScore = 'd';
        case '36'
            HumanScore = '1';
        case '37'
            HumanScore = '2';
        case '38'
            HumanScore = '3';
        case '39'
            HumanScore = '4';
        case '40'
            HumanScore = '5';
        case '41'
            HumanScore = '6';
        case '42'
            HumanScore = '7';
        case '43'
            HumanScore = '8';
        case '44'
            HumanScore = '9';
        case '45'
            HumanScore = '10';
        case '13'
            HumanScore = 'h';
        case '11'
            HumanScore = 'l';
        case '22'
            HumanScore = 'a';
        case '21'
            HumanScore = 'x';
        case '51'
            HumanScore = 'u';
        case '91'
            HumanScore = 'b';
        case '12'
            HumanScore = 'p';
        case '52'
            HumanScore = 'i';
        case '53'
            HumanScore = 'f';
        case '16'
            HumanScore = 'g';
        case '32'
            HumanScore = 'e';
        case '33'
            HumanScore = 's';
    end     
end
        
% --- Find index of subwell given row, col, subwell.
function Idx = FindIndex(Row, Col, SubWell)
switch Row
    case 'A'
        Row = 1;
    case 'B'
        Row = 2;
    case 'C'
        Row = 3;
    case 'D'
        Row = 4;
    case 'E'
        Row = 5;
    case 'F'
        Row = 6;
    case 'G'
        Row = 7;
    case 'H'
        Row = 8;
    otherwise
        if Row < 1 || Row > 8 || ischar (Row)
            errordlg('Error: Use the following format: A1a, H12c etc');
            Idx = 0; return;
        end
end


switch SubWell
    case 'a'
        SubWell = 1;
    case 'c'
        SubWell = 2;
    case 'd'
        SubWell = 3;
    otherwise 
        if SubWell < 1 || SubWell > 3 || ischar(SubWell)
            errordlg('Error: Use the following format: A1a, H12d etc.');
            Idx = 0; return;
        end
end
if Col < 0 || Col > 12
    errordlg('Error: Use the following format: A1a, H12d etc.');
    Idx = 0; return;
end
Idx = (Col-1)*24 + (Row-1)*3 + SubWell;



% ----------------------------------------------------------------------- %
% ----------------------------------------------------------------------- %
% 4: All the 'CreateFcn's
function BarcodeInput_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function InspectionsPopUp_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function ProjectList_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ProjectList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function BarcodeListBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BarcodeListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function NavigateThroughPlate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to NavigateThroughPlate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function ThumbnailBtn_CreateFcn(hObject, eventdata, handles)

function SubwellInput_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% ----------------------------------------------------------------------- %
% ----------------------------------------------------------------------- %
% 5: Phased out sections
% --- Executes on button press in SearchByProjectBtn.
function SearchByProjectBtn_Callback(hObject, eventdata, handles)
% hObject    handle to SearchByProjectBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uiwait(SearchByProjectUI(handles.CrystalConn, handles.TargetName));
handles.Barcode = getappdata(0, 'SelectedBarcode');
close(SearchByProjectUI);
set(handles.BarcodeInput, 'string', handles.Barcode);
guidata(hObject, handles);
BarcodeInput_Callback(handles.figure1, eventdata, handles);
PlateAndInspectionGo_Callback(handles.figure1, eventdata, handles);
set(handles.SearchByProjectBtn, 'Enable', 'off');
drawnow;
set(handles.SearchByProjectBtn, 'Enable', 'on');



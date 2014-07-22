function varargout = GenerateBackgroundIm(varargin)
% GENERATEBACKGROUNDIM MATLAB code for GenerateBackgroundIm.fig
%      GENERATEBACKGROUNDIM, by itself, creates a new GENERATEBACKGROUNDIM or raises the existing
%      singleton*.
%
%      H = GENERATEBACKGROUNDIM returns the handle to a new GENERATEBACKGROUNDIM or the handle to
%      the existing singleton*.
%
%      GENERATEBACKGROUNDIM('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GENERATEBACKGROUNDIM.M with the given input arguments.
%
%      GENERATEBACKGROUNDIM('Property','Value',...) creates a new GENERATEBACKGROUNDIM or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GenerateBackgroundIm_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GenerateBackgroundIm_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GenerateBackgroundIm

% Last Modified by GUIDE v2.5 10-Jul-2014 16:05:09

% AUTHOR: Jia Tsing Ng (jiatsing.ng@dtc.ox.ac.uk)
% Last modified  22 July 2014
% Function: GUI to generate background image and mask required for Ranker.
% 
% 



% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GenerateBackgroundIm_OpeningFcn, ...
                   'gui_OutputFcn',  @GenerateBackgroundIm_OutputFcn, ...
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


% --- Executes just before GenerateBackgroundIm is made visible.
function GenerateBackgroundIm_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GenerateBackgroundIm (see VARARGIN)

% Choose default command line output for GenerateBackgroundIm
handles.output = hObject;
%initialize variables;
handles.FileName = {};
handles.PathName = '';
handles.ImAve = [];
handles.ImBW = [];
handles.NumObjects = [];
handles.PixelIdxList = {};
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes GenerateBackgroundIm wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = GenerateBackgroundIm_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in SelectFilesBtn.
function SelectFilesBtn_Callback(hObject, eventdata, handles)
% hObject    handle to SelectFilesBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[FileName,PathName] = uigetfile('*.*', 'MultiSelect', 'on');
NumFiles = length(FileName);
if NumFiles == 1
    set(handles.NumFilesSelected, 'string', '1 file selected -> PLEASE SELECT MORE!');
elseif NumFiles > 1
    set(handles.NumFilesSelected, 'string', sprintf('%d files selected.', NumFiles));
    set(handles.CalculateBtn, 'Enable', 'on');
    handles.FileName = FileName;
    handles.PathName = PathName;
    guidata(hObject, handles);
end



% --- Executes on button press in CalculateBtn.
function CalculateBtn_Callback(hObject, eventdata, handles)
% hObject    handle to CalculateBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
NumFiles = length(handles.FileName);
% read first file to get im size.
FirstIm = imadjust(rgb2gray(imread([handles.PathName handles.FileName{1}])));
set(handles.LoadingTxt, 'String', 'Loading image 1');
ImStack = zeros([size(FirstIm) 3]);
ImStack(:,:,1) = FirstIm;
for i = 2:NumFiles
    set(handles.LoadingTxt, 'String', sprintf('Loading image %d', i));
    drawnow;
    im = imadjust(rgb2gray(imread([handles.PathName handles.FileName{i}])));
    ImStack(:,:,i) = im;
end
ImAve = uint8(imresize(mean(ImStack,3), [96 128]));
ImBW = im2bw(ImAve);
handles.ImAve = ImAve;
handles.ImBW = ImBW;
colormap gray;
axes(handles.ImAveAx);
imagesc(ImAve);
axis off;
axes(handles.ImBWAx);
imagesc(ImBW); 
axis off;

set(handles.FixMaskBtn, 'Enable', 'on');
set(handles.SaveBtn, 'Enable', 'on');

CC = bwconncomp(handles.ImBW,8);
CCNegative = bwconncomp(~handles.ImBW,8);
handles.NumObjects = CC.NumObjects + CCNegative.NumObjects;
handles.PixelIdxList = horzcat(CC.PixelIdxList, CCNegative.PixelIdxList);


guidata(hObject, handles);


% --- Executes on button press in FixMaskBtn.
function FixMaskBtn_Callback(hObject, eventdata, handles)
% hObject    handle to FixMaskBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
axes(handles.ImBWAx);


[x y] = ginput(1);
Index = sub2ind(size(handles.ImBW), round(y), round(x));
for i = 1:handles.NumObjects
    if ismember(Index, handles.PixelIdxList{i})
        handles.ImBW(handles.PixelIdxList{i}) = ~handles.ImBW(handles.PixelIdxList{i});
        break;
    end
end
imagesc(handles.ImBW);
axis off;
guidata(hObject, handles);


% --- Executes on button press in SaveBtn.
function SaveBtn_Callback(hObject, eventdata, handles)
% hObject    handle to SaveBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
BackgroundIm{1} = handles.ImAve;
BackgroundIm{2} = handles.ImBW;
uisave('BackgroundIm');

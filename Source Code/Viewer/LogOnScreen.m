function varargout = LogOnScreen(varargin)
% LOGONSCREEN MATLAB code for LogOnScreen.fig
%      LOGONSCREEN, by itself, creates a new LOGONSCREEN or raises the existing
%      singleton*.
%
%      H = LOGONSCREEN returns the handle to a new LOGONSCREEN or the handle to
%      the existing singleton*.
%
%      LOGONSCREEN('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LOGONSCREEN.M with the given input arguments.
%
%      LOGONSCREEN('Property','Value',...) creates a new LOGONSCREEN or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before LogOnScreen_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to LogOnScreen_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help LogOnScreen

% Last Modified by GUIDE v2.5 25-Jan-2014 13:40:57

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @LogOnScreen_OpeningFcn, ...
                   'gui_OutputFcn',  @LogOnScreen_OutputFcn, ...
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


% --- Executes just before LogOnScreen is made visible.
function LogOnScreen_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to LogOnScreen (see VARARGIN)

% Choose default command line output for LogOnScreen
handles.output = hObject;

% initialize
handles.Username = [];
handles.Password = [];

% Update handles structure
guidata(hObject, handles);
uicontrol(handles.UsernameTxt);
uicontrol(handles.UsernameTxt);



% UIWAIT makes LogOnScreen wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = LogOnScreen_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;



function UsernameTxt_Callback(hObject, eventdata, handles)



% --- Executes during object creation, after setting all properties.
function UsernameTxt_CreateFcn(hObject, eventdata, handles)
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function PasswordTxt_Callback(hObject, eventdata, handles)



% --- Executes during object creation, after setting all properties.
function PasswordTxt_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in LogOn.
function LogOn_Callback(hObject, eventdata, handles)
% hObject    handle to LogOn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Authenticate user with BEEHIVE 
host = 'sgcdata.sgc.ox.ac.uk';
dbName = 'eln';
handles.Username = get(handles.UsernameTxt, 'string');
user = upper(handles.Username);
password = handles.Password;

%# JDBC parameters
jdbcString = sprintf('jdbc:oracle:thin:@%s/%s', host, dbName);
jdbcDriver = 'oracle.jdbc.driver.OracleDriver';
 
%# Create the database connection object
conn = database(dbName, user , password, jdbcDriver, jdbcString);
 
if isconnection(conn)
    
    ConnAndUserName = {conn, user};
    setappdata(0, 'ConnAndUserName', ConnAndUserName);
    uiresume;

else
    errordlg(sprintf('%s', conn.Message));
end
% close(ClearDropConditionGetBarcode);



% --- Executes on key press with focus on PasswordTxt and none of its controls.
function PasswordTxt_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to PasswordTxt (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
switch eventdata.Key
    case 'backspace'
        try
            handles.Password = handles.Password(1:end-1);
        catch
            handles.Password = [];
        end
    case 'delete'
        try
            handles.Password = handles.Password(1:end-1);
        catch
            handles.Password = [];
        end
    case 'return'
        LogOn_Callback(hObject, eventdata, handles);
    otherwise
        handles.Password = [handles.Password eventdata.Character];
end
Asterisks = repmat('*', 1,length(handles.Password));
set(handles.PasswordTxt, 'string', Asterisks);
guidata(hObject, handles);


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
delete(hObject);
uiresume;

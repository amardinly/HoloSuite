function varargout = ListenerForHoloRequest(varargin)
% LISTENERFORHOLOREQUEST MATLAB code for ListenerForHoloRequest.fig
%      LISTENERFORHOLOREQUEST, by itself, creates a new LISTENERFORHOLOREQUEST or raises the existing
%      singleton*.
%
%      H = LISTENERFORHOLOREQUEST returns the handle to a new LISTENERFORHOLOREQUEST or the handle to
%      the existing singleton*.
%
%      LISTENERFORHOLOREQUEST('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LISTENERFORHOLOREQUEST.M with the given input arguments.
%
%      LISTENERFORHOLOREQUEST('Property','Value',...) creates a new LISTENERFORHOLOREQUEST or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ListenerForHoloRequest_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ListenerForHoloRequest_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ListenerForHoloRequest

% Last Modified by GUIDE v2.5 19-Aug-2015 13:40:43

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ListenerForHoloRequest_OpeningFcn, ...
                   'gui_OutputFcn',  @ListenerForHoloRequest_OutputFcn, ...
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


% --- Executes just before ListenerForHoloRequest is made visible.
function ListenerForHoloRequest_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ListenerForHoloRequest (see VARARGIN)

% Choose default command line output for ListenerForHoloRequest
locations=SatsumaRigFile();
handles.output = hObject;
handles.DoHandshake = 1;
handles.save=0;
handles.writeROIsON = 0;
handles.defaultDir = locations.saveSequence;
handles.currentDir = handles.defaultDir;
handles.saveName = [];
handles.useLoad = 1;
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ListenerForHoloRequest wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = ListenerForHoloRequest_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in start.
function start_Callback(hObject, eventdata, handles)
% hObject    handle to start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.listening,'Value',1);  %set listening checkbox to listen
handles.abort=0;
set(handles.abortToggle,'Value',0)
RUNME_Listener_ARM(handles);

%handles.output = START THE LISTENERFORHOLOREQUEST!!!!!!!!!!!!!!!!!!(handles.output)
%check handles.output.DoHandshake to determine if yoiu're writing current
%ROI

% --- Executes on button press in abort.
function abort_Callback(hObject, eventdata, handles)
% hObject    handle to abort (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%set listenering to check if abort = 1.  If so, stop everything and reset
%abort to 0. 

% --- Executes on button press in handshake.
function handshake_Callback(hObject, eventdata, handles)
% hObject    handle to handshake (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
v=get(hObject,'Value');
if v ==1  
	handles.DoHandshake = 1;
else
	handles.DoHandshake = 0;
end
guidata(hObject, handles);
% Hint: get(hObject,'Value') returns toggle state of handshake


% --- Executes on button press in listening.
function listening_Callback(hObject, eventdata, handles)
% hObject    handle to listening (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of listening


% --- Executes on button press in abortToggle.
function abortToggle_Callback(hObject, eventdata, handles)
% hObject    handle to abortToggle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.listening,'Value',0);
set(handles.statusText,'String','aborted - doing nothing'); 
handles.abort = 1;

% Hint: get(hObject,'Value') returns toggle state of abortToggle


% --- Executes on button press in saveSeq.
function saveSeq_Callback(hObject, eventdata, handles)
% hObject    handle to saveSeq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
s=get(hObject,'Value');
if s == 1;
    handles.save = 1;
else
    handles.save=0;
end;
guidata(hObject,handles)
% Hint: get(hObject,'Value') returns toggle state of saveSeq



function seqName_Callback(hObject, eventdata, handles)
% hObject    handle to seqName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.saveName = get(hObject,'String');
guidata(hObject,handles);
% Hints: get(hObject,'String') returns contents of seqName as text
%        str2double(get(hObject,'String')) returns contents of seqName as a double


% --- Executes during object creation, after setting all properties.
function seqName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to seqName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in loadSeq.
function loadSeq_Callback(hObject, eventdata, handles)
% hObject    handle to loadSeq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[handles.LoadedSequenceName handles.LoadedPathName] = uigetfile(handles.defaultDir);

guidata(hObject,handles);

% --- Executes on button press in setSaveDir.
function setSaveDir_Callback(hObject, eventdata, handles)
% hObject    handle to setSaveDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.currentDir = uigetdir(handles.defaultDir);
guidata(hObject,handles)


% --- Executes on button press in useLoad.
function useLoad_Callback(hObject, eventdata, handles)
% hObject    handle to useLoad (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
s=get(hObject,'Value');
if s == 1;
    handles.useLoad = 1;
else
    handles.useLoad=0;
end;
guidata(hObject,handles)
% Hint: get(hObject,'Value') returns toggle state of useLoad

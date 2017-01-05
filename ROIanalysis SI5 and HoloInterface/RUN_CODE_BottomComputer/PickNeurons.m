function varargout = PickNeurons(varargin)
%PICKNEURONS M-file for PickNeurons.fig
%      PICKNEURONS, by itself, creates a new PICKNEURONS or raises the existing
%      singleton*.
%
%      H = PICKNEURONS returns the handle to a new PICKNEURONS or the handle to
%      the existing singleton*.
%
%      PICKNEURONS('Property','Value',...) creates a new PICKNEURONS using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to PickNeurons_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      PICKNEURONS('CALLBACK') and PICKNEURONS('CALLBACK',hObject,...) call the
%      local function named CALLBACK in PICKNEURONS.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help PickNeurons

% Last Modified by GUIDE v2.5 10-Dec-2014 16:20:06

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @PickNeurons_OpeningFcn, ...
    'gui_OutputFcn',  @PickNeurons_OutputFcn, ...
    'gui_LayoutFcn',  [], ...
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


% --- Executes just before PickNeurons is made visible.
function PickNeurons_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

% Choose default command line output for PickNeurons
% clear all
% close all
% clc
[ Setup, SLM, NiDaq ] = Load_Parameters(0)
handles.output = hObject;
handles.path = strcat(Setup.ResultsFolder,'\');
addpath(handles.path);
addpath(pwd)
handles.logScale=1;
handles.singleImage=1;
handles.Experiment.ImageID=2;
handles.Experiment.name = [];
handles.Experiment.X = linspace(0,0);
handles.Experiment.Y = linspace(0,0);
handles.Experiment.Ellipses = 0;
handles.stopPicking = 0;
handles.i=1;
handles.log=1;
handles.currentImage=1;
%handles.setup=load(strcat(handles.path,'CalibrationFiles\SetupAlignment.mat'));     %Alignment Matrix from Previous File
%handles.engrave=load(strcat(handles.path,'CalibrationFiles\AlignmentEngraveProperties.mat'));
handles.Zplane=[]; 
handles.Zspacing=5;
handles.Experiment.Masks = [];
handles.Experiment.NeuronPositions=[];
handles.Experiment.NeuronHologramPositions=[];
handles.color='green';
[ Setup, SLM, NiDaq ] = Load_Parameters(0);    
handles.Setup=Setup;
handles.SLM=SLM;
handles.NiDaq=NiDaq;


% Update handles structure
guidata(hObject, handles);

% UIWAIT makes PickNeurons wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = PickNeurons_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function pathET_Callback(hObject, eventdata, handles)
% hObject    handle to pathET (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of pathET as text
%        str2double(get(hObject,'String')) returns contents of pathET as a double


% --- Executes during object creation, after setting all properties.
function pathET_CreateFcn(hObject, eventdata, handles)
% % % % hObject    handle to pathET (see GCBO)
% % % % eventdata  reserved - to be defined in a future version of MATLAB
% % % % handles    empty - handles not created until after all CreateFcns called
% % %
% % % % Hint: edit controls usually have a white background on Windows.
% % % %       See ISPC and COMPUTER.
% % % if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
% % %     set(hObject,'BackgroundColor','white');
% % % end
% % %

% --- Executes on button press in saveAndExitPB.
function saveAndExitPB_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndExitPB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%save('PickNeuronHandles','handles');

ROI=handles.ROI;
Ellipse=handles.Ellipse;
counter=handles.i;
SLM=handles.SLM;
Setup=handles.Setup;
TrueDepth=handles.TrueDepth;

NeuronData.ROI=ROI;
NeuronData.EllipseZplane=handles.EllipseZplane;

NeuronData.ROI=handles.ROI;
%NeuronData.Depth=handles.TrueDepth;

%load(strcat('CalibrationFiles/Calibration_Depth.mat'));

NeuronData.StackSpacing = handles.Zspacing;
ImageOutput = handles.TwoPhotonImage;


save(strcat(handles.path,'\NeuronData'),'NeuronData');
save(strcat(handles.path,handles.Experiment.name,'_NeuronData'),'NeuronData');
save(strcat(handles.path,handles.Experiment.name,'_StackImage'),'ImageOutput');
save(strcat(handles.path,handles.Experiment.name,'_ROIhandles'), 'handles')
savefig(handles.figure1,strcat(handles.path,handles.Experiment.name,'_ROIScreenshot.fig'));
saveas(handles.figure1,strcat(handles.path,handles.Experiment.name,'_ROI_Screenshot.jpg'));


close(PickNeurons)





% --- Executes on button press in MaxIRB.
function MaxIRB_Callback(hObject, eventdata, handles)
% hObject    handle to MaxIRB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of MaxIRB


% --- Executes on button press in MeanIRB.
function MeanIRB_Callback(hObject, eventdata, handles)
% hObject    handle to MeanIRB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of MeanIRB


% --- Executes on button press in singleImageRB.
function singleImageRB_Callback(hObject, eventdata, ~)
% hObject    handle to singleImageRB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of singleImageRB


% --- Executes on button press in logscaleCB.
function logscaleCB_Callback(hObject, eventdata, handles)
% hObject    handle to logscaleCB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (get(hObject,'Value') == get(hObject,'Max'))
    handles.log=1;
    display('log scale on')
else
    handles.log=0;
    display('log scale off')
end;
run('updateImage.m')
guidata(PickNeurons,handles);
% Hint: get(hObject,'Value') returns toggle state of logscaleCB


% --- Executes on button press in selectImageDownPB.
function selectImageDownPB_Callback(hObject, eventdata, handles)
% hObject    handle to selectImageDownPB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
%handles    structure with handles and user data (see GUIDATA)
  pause(0.01)
Z=handles.Zplane;
Z=Z-1;

if Z==0
    Z=handles.Zlevel.Slices;
end;
set(handles.ImageFrameST,'String',strcat('Image ',num2str(Z)))
handles.Zplane=Z;

run('updateImage.m')


guidata(PickNeurons,handles);







% --- Executes on button press in selectImageUpPB.
function selectImageUpPB_Callback(hObject, eventdata, handles)
pause(0.01)
Z=handles.Zplane;


if  Z==handles.Zlevel.Slices
    Z=1;
    handles.Zplane=Z;
   
else
     Z=Z+1;
     handles.Zplane=Z; 
end;


set(handles.ImageFrameST,'String',strcat('Image ',num2str(Z)))

run('updateImage.m')
%Z=Z+1;
%handles.Zplane=Z;
guidata(PickNeurons,handles);


% hObject    handle to selectImageUpPB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pickNeuronsPB.
function pickNeuronsPB_Callback(hObject, eventdata, handles)
% hObject    handle to pickNeuronsPB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%SLM=handles.SLM;
stopPicking=0;
Zlevel=handles.Zlevel;
Zvector=Zlevel.Vector;

while stopPicking ~= 1;
    
    z=handles.Zplane;
    e = imellipse;
    hold on
    Ellipse= wait(e);
    
    
    [LA LB] = size(Ellipse);
    Zvalue = Zvector(z)*ones(1,LA)';
    Ellipse = [Ellipse Zvalue];
    ROI = Ellipse;
    TrueDepth = Zvector(z);
    
 
    text(max(Ellipse(:,1)),max(Ellipse(:,2)),num2str(handles.i),'Color',[0,1,0],'FontSize',16);
    
    handles.EllipseZplane{handles.i}=handles.Zplane;
    handles.Ellipse{handles.i}=Ellipse; 
    handles.ROI{handles.i}=ROI;
    handles.TrueDepth{handles.i}=TrueDepth;
    handles.i=handles.i+1;
    guidata(PickNeurons,handles)
    waitforbuttonpress;
    
    if get(handles.donePickingTB,'Value') == get(handles.donePickingTB,'Max');
        stopPicking = 1;
    end;
    
    
    
    
end;



function loadImageET_Callback(hObject, eventdata, handles)
% hObject    handle to loadImageET (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.Experiment.name = get(hObject,'String');
guidata(PickNeurons,handles)
% Hints: get(hObject,'String') returns contents of loadImageET as text
%        str2double(get(hObject,'String')) returns contents of loadImageET as a double

% --- Executes during object creation, after setting all properties.
function loadImageET_CreateFcn(hObject, eventdata, handles)
% hObject    handle to loadImageET (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in donePickingNeuronsPB.
function donePickingNeuronsPB_Callback(hObject, eventdata, handles)
% hObject    handle to donePickingNeuronsPB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in loadimagePB.
function loadimagePB_Callback(hObject, eventdata, handles)
% hObject    handle to loadimagePB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isempty(handles.Experiment.name)==1;
    display('Please enter image name')
else
    Zlevel.spacing = handles.Zspacing;
    TwoPhotonFile = strcat(handles.Experiment.name,'.tif'); %Get Frame of Interest with visible neurons
    a=strcat(handles.path,TwoPhotonFile);
    TwoPhotonImage=function_loadtiff(a);
    TwoPhotonImage=double(TwoPhotonImage);
    LF = size(TwoPhotonImage);
    handles.TwoPhotonImage=flipud(TwoPhotonImage);
    Zlevel.Slices = LF(3)/2;
    Zlevel.Vector = Zlevel.spacing*linspace(-(Zlevel.Slices-1)/2,(Zlevel.Slices-1)/2,Zlevel.Slices);
 
    u = linspace(1,LF(3)/2,LF(3)/2);
    ugreen = 2*u;
    ured = 2*u-1;
    
    TwoPhotonImageGreen = TwoPhotonImage(:,:,ugreen);
    TwoPhotonImageRed = TwoPhotonImage(:,:,ured);
    
    for i = 1:Zlevel.Slices
    TwoPhotonImageGreen(:,:,i) = flipud(squeeze(TwoPhotonImageGreen(:,:,i)));
    TwoPhotonImageRed(:,:,i) = flipud(squeeze(TwoPhotonImageRed(:,:,i)));
    end
    

 
    %f = figure()
    if Zlevel.Slices>1
    pcolor(squeeze(TwoPhotonImageGreen(:,:,floor(Zlevel.Slices/2))));
    else
        pcolor(squeeze(TwoPhotonImageGreen(:,:)));
    end
    
    
    xlabel('x pixels')
    ylabel('y pixels')
    shading flat
    axis image
    colormap gray(256)
    title(strcat('Two Photon image 256 by 256 (z = 1 microns )'));
    
    handles.TwoPhotonImageRed=TwoPhotonImageRed;
    handles.TwoPhotonImageGreen=TwoPhotonImageGreen;
    handles.Zlevel=Zlevel;
    handles.Zplane=floor(Zlevel.Slices/2);
    set(handles.ImageFrameST,'String',strcat('Image ',num2str(handles.Zplane)))
    guidata(PickNeurons,handles)
end;


% --- Executes on button press in greenRB.
function greenRB_Callback(hObject, eventdata, handles)
% hObject    handle to greenRB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of greenRB



function loadCalibrationET_Callback(hObject, eventdata, handles)
% hObject    handle to loadCalibrationET (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of loadCalibrationET as text
%        str2double(get(hObject,'String')) returns contents of loadCalibrationET as a double


% --- Executes during object creation, after setting all properties.
function loadCalibrationET_CreateFcn(hObject, eventdata, handles)
% hObject    handle to loadCalibrationET (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton13.
function pushbutton13_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes when selected object is changed in selectChannelBG.
function selectChannelBG_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in selectChannelBG
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch get(eventdata.NewValue,'Tag') % Get Tag of selected object.
    case 'greenRB'
        display('green')
        handles.color='red';
    case 'redRB'
        display('red')
        handles.color='green'    ; 
end


run('updateImage.m')
guidata(PickNeurons,handles);












% --- Executes during object deletion, before destroying properties.
function pathET_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to pathET (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object deletion, before destroying properties.
function loadImageET_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to loadImageET (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object deletion, before destroying properties.
function loadCalibrationET_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to loadCalibrationET (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function saveET_Callback(hObject, eventdata, handles)
% hObject    handle to saveET (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of saveET as text
%        str2double(get(hObject,'String')) returns contents of saveET as a double


% --- Executes during object creation, after setting all properties.
function saveET_CreateFcn(hObject, eventdata, handles)
% hObject    handle to saveET (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in donePickingTB.
function donePickingTB_Callback(hObject, eventdata, handles)
% hObject    handle to donePickingTB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject,'Value')==get(hObject,'Max')
    
    display('Stopped')
    guidata(PickNeurons,handles);
    
  
end;
% Hint: get(hObject,'Value') returns toggle state of donePickingTB


% --- Executes during object creation, after setting all properties.
function logscaleCB_CreateFcn(hObject, eventdata, handles)
set(hObject,'Value',1)
% hObject    handle to logscaleCB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes when selected object is changed in displayBG.
function displayBG_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in displayBG
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
 
%run('C:\Users\Alan\Documents\MATLAB\calcium\GUI\updateImage.m')
%end plot ellipse


% --- Executes on button press in Z_downPB.
function Z_downPB_Callback(hObject, eventdata, handles)
% hObject    handle to Z_downPB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in Zup_PB.
function Zup_PB_Callback(hObject, eventdata, handles)
% hObject    handle to Zup_PB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function ZspacingET_Callback(hObject, eventdata, handles)
% hObject    handle to ZspacingET (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.Zspacing  = str2double(get(hObject,'String'));
  guidata(PickNeurons,handles)
% Hints: get(hObject,'String') returns contents of ZspacingET as text
%        str2double(get(hObject,'String')) returns contents of ZspacingET as a double


% --- Executes during object creation, after setting all properties.
function ZspacingET_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ZspacingET (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

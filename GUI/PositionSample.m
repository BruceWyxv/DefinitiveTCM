function varargout = PositionSample(varargin)
%POSITIONSAMPLE M-file for PositionSample.fig
%      POSITIONSAMPLE, by itself, creates a new POSITIONSAMPLE or raises the existing
%      singleton*.
%
%      H = POSITIONSAMPLE returns the handle to a new POSITIONSAMPLE or the handle to
%      the existing singleton*.
%
%      POSITIONSAMPLE('Property','Value',...) creates a new POSITIONSAMPLE using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to PositionSample_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      POSITIONSAMPLE('CALLBACK') and POSITIONSAMPLE('CALLBACK',hObject,...) call the
%      local function named CALLBACK in POSITIONSAMPLE.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help PositionSample

% Last Modified by GUIDE v2.5 23-Feb-2016 18:02:38

  % Begin initialization code - DO NOT EDIT
  gui_Singleton = 1;
  gui_State = struct('gui_Name',       mfilename, ...
                     'gui_Singleton',  gui_Singleton, ...
                     'gui_OpeningFcn', @PositionSample_OpeningFcn, ...
                     'gui_OutputFcn',  @PositionSample_OutputFcn, ...
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
end


% --- Executes just before PositionSample is made visible.
function PositionSample_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

  % Choose default command line output for PositionSample
  handles.output = hObject;
  
  % Set some parameters
  % TODO Detect where the sample is and choose the appropriate camera
  set(handles.SampleLoadingCamera, 'Value', 1);
  handles.CameraPosition = 'SampleLoading';
  handles.StagePosition = handles.CameraPosition;
  set(handles.AutoMoveStage, 'Value', 1);
  handles = UpdateCameraSelectionGroup(handles);
  set(handles.Moderate, 'Value', 1);
  handles.MotorSpeed = 'Moderate';
  handles.Speeds = [0.01, 0.05;...
                    0.02, 0.1;...
                    0.04, 0.2];
  handles = UpdateMotorSpeedGroup(handles);

  % Update handles structure
  movegui(hObject, 'center');
  guidata(hObject, handles);
end


% --- Outputs from this function are returned to the command line.
function varargout = PositionSample_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
  varargout{1} = handles.output;
end


% --- Executes when selected object is changed in CameraSelectionGroup.
function CameraSelectionGroup_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in CameraSelectionGroup 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  handles = UpdateCameraSelectionGroup(handles, eventdata);
  guidata(hObject, handles);
end


% --- Executes on button press in Done.
function Done_Callback(hObject, eventdata, handles)
% hObject    handle to Done (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  close(handles.PositionSampleWindow);
end


% --- Executes on button press in AutoMoveStage.
function AutoMoveStage_Callback(hObject, eventdata, handles)
% hObject    handle to AutoMoveStage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of AutoMoveStage
  UpdateCameraSelectionGroup(handles);
end


% --- Executes when selected object is changed in MotorSpeedGroup.
function MotorSpeedGroup_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in MotorSpeedGroup 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  handles = UpdateMotorSpeedGroup(handles, eventdata);
  guidata(hObject, handles);
end

function handles = MoveStage(handles)
  % First, open a modal progress bar while we are moving the stage. We
  % don't want the user to be able to change anything until the stage
  % movement is complete. Also, disable the close functionality (a user
  % should not be able to prematurely close the window while the process is
  % still completing.
  waitForStage = waitbar(0, 'Please wait while the sample is repositioned...', 'WindowStyle', 'modal', 'CloseRequestFcn', '');
  set(waitForStage, 'Pointer', 'watch');
  
  % TODO Move the stage and update wait bar with status
  pause(2);
  
  % Delete the handle to the progress bar. We cannot call the close function
  % since we overode that functionality to disable the user's ability to
  % close the window.
  delete(waitForStage);

  % The stage should now be in the camera's field-of-view
  handles.StagePosition = handles.CameraPosition;
end


% --- Executes on button press in RepositionStageButton.
function RepositionStageButton_Callback(hObject, eventdata, handles)
% hObject    handle to RepositionStageButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  % Move the stage to the camera position
  handles = MoveStage(handles);
end


function XEdit_Callback(hObject, eventdata, handles)
% hObject    handle to XEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of XEdit as text
%        str2double(get(hObject,'String')) returns contents of XEdit as a double
end


function YEdit_Callback(hObject, eventdata, handles)
% hObject    handle to YEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of YEdit as text
%        str2double(get(hObject,'String')) returns contents of YEdit as a double
end


function ZEdit_Callback(hObject, eventdata, handles)
% hObject    handle to ZEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ZEdit as text
%        str2double(get(hObject,'String')) returns contents of ZEdit as a double
end


% --- Executes on slider movement.
function XSlider_Callback(hObject, eventdata, handles)
% hObject    handle to XSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
end


% --- Executes on slider movement.
function YSlider_Callback(hObject, eventdata, handles)
% hObject    handle to YSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
end


% --- Executes on slider movement.
function ZSlider_Callback(hObject, eventdata, handles)
% hObject    handle to ZSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
end


function handles = UpdateCameraSelectionGroup(handles, eventdata)
% Processes all the commands associated with the camera selection group
  % Check to see if a radio button selection triggered the event. If so,
  % then select the camera to show in the viewer
  if nargin == 2
    % Select the camera
    switch get(eventdata.NewValue, 'Tag')
      case 'SampleLoadingCamera'
        handles.CameraPosition = 'SampleLoading';

      case 'CoarsePositioningCamera'
        handles.CameraPosition = 'CoarsePositioning';

      case 'ScanningObjectiveCamera'
        handles.CameraPosition = 'ScanningObjective';
    end
    
    % Check to see if we need to reposition the stage
    if get(handles.AutoMoveStage, 'Value') == 1 && ~strcmp(handles.CameraPosition, 'SampleLoading') && ~strcmp(handles.CameraPosition, handles.StagePosition)
      handles = MoveStage(handles);
    end
  else
    % The checkbox state was changed
    if get(handles.AutoMoveStage, 'Value') == 1
      set(handles.RepositionStageButton, 'Enable', 'off');
    else
      set(handles.RepositionStageButton, 'Enable', 'on');
    end
  end
end


function handles = UpdateMotorSpeedGroup(handles, eventdata)
% Update the controls related to the motor speed

  % Check to see if a radio button selection triggered the event. If so,
  % then update the motor speed choice
  if nargin == 2
    % Sets the relative size of a single step
    switch get(eventdata.NewValue, 'Tag')
      case 'Slow'
        handles.MotorSpeed = 'Slow';

      case 'Moderate'
        handles.MotorSpeed = 'Moderate';

      case 'Fast'
        handles.MotorSpeed = 'Fast';
    end
  end
  
  switch handles.MotorSpeed
    case 'Slow'
      sliderStep = handles.Speeds(1,:);
      
    case 'Moderate'
      sliderStep = handles.Speeds(2,:);
      
    case 'Fast'
      sliderStep = handles.Speeds(3,:);
  end
  
  set(handles.XSlider, 'SliderStep', sliderStep);
  set(handles.YSlider, 'SliderStep', sliderStep);
  set(handles.ZSlider, 'SliderStep', sliderStep);
end

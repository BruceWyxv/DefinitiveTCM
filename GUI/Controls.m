function varargout = Controls(varargin)
%CONTROLS M-file for Controls.fig
%      CONTROLS, by itself, creates a new CONTROLS or raises the existing
%      singleton*.
%
%      H = CONTROLS returns the handle to a new CONTROLS or the handle to
%      the existing singleton*.
%
%      CONTROLS('Property','Value',...) creates a new CONTROLS using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to Controls_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      CONTROLS('CALLBACK') and CONTROLS('CALLBACK',hObject,...) call the
%      local function named CALLBACK in CONTROLS.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help PositionSample

% Last Modified by GUIDE v2.5 15-Mar-2016 12:29:38

  % Begin initialization code - DO NOT EDIT
  gui_Singleton = 1;
  gui_State = struct('gui_Name',       mfilename, ...
                     'gui_Singleton',  gui_Singleton, ...
                     'gui_OpeningFcn', @Controls_OpeningFcn, ...
                     'gui_OutputFcn',  @Controls_OutputFcn, ...
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
function Controls_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<INUSL>
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

  % Choose default command line output for PositionSample
  handles.output = hObject;
  movegui(hObject, 'center');
  
  % Check the input arguments
  if ~isempty(varargin)
    parser = inputParser;
    parser.addParameter('cameras', '', @isstruct);
    parser.addParameter('stageController', '', @(x) isa(x, 'ESP300_Control'));
    parser.addParameter('settings', '', @isstruct);
    % Parse the input arguments
    parser.KeepUnmatched = true;
    try
      parser.parse(varargin{:});
    catch me
      error('Error when trying to parse input arguments:   %s', me.message);
    end
    % Assigned values
    handles.cameras = parser.Results.cameras;
    handles.stageController = parser.Results.stageController;
    handles.settings = parser.Results.settings;
    handles.settings
  end
  
  % Set some parameters
  axes(handles.CameraView)
  handles.CameraView = image(zeros(640, 480, 3));
  preview(handles.cameras.load, handles.CameraView);
  axis image; % Preserve the aspect ratio
  % TODO Detect where the sample is and choose the appropriate camera - BEGIN
  set(handles.SampleLoadingCamera, 'Value', 1);
  handles.CameraPosition = 'SampleLoading';
  handles.StagePosition = handles.CameraPosition;
  % TODO Detect where the sample is and choose the appropriate camera - END
  set(handles.AutoMoveStage, 'Value', 1);
  handles = UpdateCameraSelectionGroup(handles);
  handles.StageRanges = [-10, 10;...
                         -10, 10;...
                         -2, 2];
  set(handles.XEdit, 'String', '0');
  set(handles.YEdit, 'String', '0');
  set(handles.ZEdit, 'String', '0');
  UpdateEdit2Slider(handles.XEdit, handles.settings.xAxisID, handles.XSlider, handles.StageRanges(1,:), handles);
  UpdateEdit2Slider(handles.YEdit, handles.settings.yAxisID, handles.YSlider, handles.StageRanges(2,:), handles);
  UpdateEdit2Slider(handles.ZEdit, handles.settings.zAxisID, handles.ZSlider, handles.StageRanges(3,:), handles);
  
  % Add listners so that dragging the sliders also updates the edit boxes,
  % but do not move the stages yet. Wait until the user has released the
  % cursor before actually moving the stages.
  addlistener(handles.XSlider, 'Value', 'PreSet',...
    @(~, ~) UpdateEdit2Slider(handles.XEdit, handles.settings.xAxisID, handles.XSlider, handles.StageRanges(1,:), handles));
  addlistener(handles.YSlider, 'Value', 'PreSet',...
    @(~, ~) UpdateEdit2Slider(handles.YEdit, handles.settings.yAxisID, handles.YSlider, handles.StageRanges(2,:), handles));
  addlistener(handles.ZSlider, 'Value', 'PreSet',...
    @(~, ~) UpdateEdit2Slider(handles.ZEdit, handles.settings.zAxisID, handles.ZSlider, handles.StageRanges(3,:), handles));
  
  % Set the speeds and motor controls
  set(handles.Medium, 'Value', 1);
  handles.StepSize = 'Moderate';
  handles.StepSizeArray = [0.01, 0.05;...
                           0.02, 0.1;...
                           0.04, 0.2];
  set(handles.ComputerControl, 'Value', 1);
  handles.ComputerControl = true;
  UpdateControlSystem(handles);
  handles = UpdateStepSizeGroup(handles);

  % Update handles structure
  guidata(hObject, handles);
end


% --- Outputs from this function are returned to the command line.
function varargout = Controls_OutputFcn(hObject, eventdata, handles) %#ok<INUSL>
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

  % Get default command line output from handles structure
  varargout{1} = handles.output;
end


% --- Executes when selected object is changed in CameraSelectionGroup.
function CameraSelectionGroup_SelectionChangedFcn(hObject, eventdata, handles) %#ok<DEFNU>
% hObject    handle to the selected object in CameraSelectionGroup 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  handles = UpdateCameraSelectionGroup(handles, eventdata);
  guidata(hObject, handles);
end


% --- Executes when selected object is changed in ControlSystem.
function ControlSystem_SelectionChangedFcn(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to the selected object in ControlSystem 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end


% --- Executes on button press in Done.
function Done_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to Done (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  close(handles.ControlsWindow);
end


% --- Executes on button press in AutoMoveStage.
function AutoMoveStage_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to AutoMoveStage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of AutoMoveStage
  UpdateCameraSelectionGroup(handles);
end


% --- Executes when selected object is changed in StepSizeGroup.
function StepSizeGroup_SelectionChangedFcn(hObject, eventdata, handles) %#ok<DEFNU>
% hObject    handle to the selected object in StepSizeGroup 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  handles = UpdateStepSizeGroup(handles, eventdata);
  guidata(hObject, handles);
end


% --- Executes on button press in RepositionStageButton.
function RepositionStageButton_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to RepositionStageButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  % Move the stage to the camera position
  handles = MoveStageToCamera(handles);
  guidata(hObject, handles);
end


function XEdit_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to XEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of XEdit as text
%        str2double(get(hObject,'String')) returns contents of XEdit as a double
  UpdateEdit2Slider(hObject, handles.settings.xAxisID, handles.XSlider, handles.StageRanges(1,:), handles);
end


function YEdit_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to YEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of YEdit as text
%        str2double(get(hObject,'String')) returns contents of YEdit as a double
  UpdateEdit2Slider(hObject, handles.settings.yAxisID, handles.YSlider, handles.StageRanges(2,:), handles);
end


function ZEdit_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to ZEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ZEdit as text
%        str2double(get(hObject,'String')) returns contents of ZEdit as a double
  UpdateEdit2Slider(hObject, handles.settings.zAxisID, handles.ZSlider, handles.StageRanges(3,:), handles);
end


% --- Executes on slider movement.
function XSlider_Callback(hObject, eventdata, handles) %#ok<INUSL>
% hObject    handle to XSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
  UpdateSlider2Edit(hObject, handles.settings.xAxisID, handles.XEdit, handles.StageRanges(1,:), handles);
end


% --- Executes on slider movement.
function YSlider_Callback(hObject, eventdata, handles) %#ok<INUSL>
% hObject    handle to YSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
  UpdateSlider2Edit(hObject, handles.settings.yAxisID, handles.YEdit, handles.StageRanges(2,:), handles);
end


% --- Executes on slider movement.
function ZSlider_Callback(hObject, eventdata, handles) %#ok<INUSL>
% hObject    handle to ZSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
  UpdateSlider2Edit(hObject, handles.settings.zAxisID, handles.ZEdit, handles.StageRanges(3,:), handles);
end


% --- Executes on button press in XLeftFast.
function XLeftFast_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to XLeftFast (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   JogLeftFast(handles.XSlider, eventdata, handles, @XSlider_Callback);
end


% --- Executes on button press in XLeftModerate.
function XLeftModerate_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to XLeftModerate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   JogLeftModerate(handles.XSlider, eventdata, handles, @XSlider_Callback);
end


% --- Executes on button press in XLeftSlow.
function XLeftSlow_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to XLeftSlow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   JogLeftSlow(handles.XSlider, eventdata, handles, @XSlider_Callback);
end


% --- Executes on button press in ZLeftFast.
function ZLeftFast_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to ZLeftFast (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   JogLeftFast(handles.ZSlider, eventdata, handles, @ZSlider_Callback);
end


% --- Executes on button press in ZLeftModerate.
function ZLeftModerate_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to ZLeftModerate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   JogLeftModerate(handles.ZSlider, eventdata, handles, @ZSlider_Callback);
end


% --- Executes on button press in ZLeftSlow.
function ZLeftSlow_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to ZLeftSlow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   JogLeftSlow(handles.ZSlider, eventdata, handles, @ZSlider_Callback);
end


% --- Executes on button press in ZRightFast.
function ZRightFast_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to ZRightFast (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   JogRightFast(handles.ZSlider, eventdata, handles, @ZSlider_Callback);
end


% --- Executes on button press in ZRightModerate.
function ZRightModerate_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to ZRightModerate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   JogRightModerate(handles.ZSlider, eventdata, handles, @ZSlider_Callback);
end


% --- Executes on button press in ZRightSlow.
function ZRightSlow_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to ZRightSlow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   JogRightSlow(handles.ZSlider, eventdata, handles, @ZSlider_Callback);
end


% --- Executes on button press in YLeftFast.
function YLeftFast_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to YLeftFast (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   JogLeftFast(handles.YSlider, eventdata, handles, @YSlider_Callback);
end


% --- Executes on button press in YLeftModerate.
function YLeftModerate_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to YLeftModerate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   JogLeftModerate(handles.YSlider, eventdata, handles, @YSlider_Callback);
end


% --- Executes on button press in YLeftSlow.
function YLeftSlow_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to YLeftSlow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   JogLeftSlow(handles.YSlider, eventdata, handles, @YSlider_Callback);
end


% --- Executes on button press in YRightFast.
function YRightFast_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to YRightFast (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   JogRightFast(handles.YSlider, eventdata, handles, @YSlider_Callback);
end


% --- Executes on button press in YRightModerate.
function YRightModerate_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to YRightModerate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   JogRightModerate(handles.YSlider, eventdata, handles, @YSlider_Callback);
end


% --- Executes on button press in YRightSlow.
function YRightSlow_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to YRightSlow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   JogRightSlow(handles.YSlider, eventdata, handles, @YSlider_Callback);
end


% --- Executes on button press in XRightFast.
function XRightFast_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to XRightFast (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   JogRightFast(handles.XSlider, eventdata, handles, @XSlider_Callback);
end


% --- Executes on button press in XRightModerate.
function XRightModerate_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to XRightModerate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   JogRightModerate(handles.XSlider, eventdata, handles, @XSlider_Callback);
end


% --- Executes on button press in XRightSlow.
function XRightSlow_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to XRightSlow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   JogRightSlow(handles.XSlider, eventdata, handles, @XSlider_Callback);
end


% --- Executes on button press in ComputerControl.
function ComputerControl_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to ComputerControl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ComputerControl
  handles.ComputerControl = true;
  UpdateControlSystem(handles);
end


% --- Executes on button press in JoystickControl.
function JoystickControl_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to JoystickControl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of JoystickControl
  handles.ComputerControl = false;
  UpdateControlSystem(handles);
end


% --------------------------------------------------------------------
function SaveImage_Callback(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to SaveImage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end


function RecordVideo_Callback(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to RecordVideo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end


function CameraViewContextMenu_Callback(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to CameraViewContextMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end


% --------------------------------------------------------------------
function SanitizeAndSetValue(slider, eventdata, handles, newValue, Slider_Callback)
% Check the range of the new value and sanitize if it is out of bounds
  min = get(slider, 'Min');
  max = get(slider, 'Max');
  if newValue < min
    beep();
    newValue = min;
  elseif newValue > max
    beep();
    newValue = max;
  end
  set(slider, 'Value', newValue);
  Slider_Callback(slider, eventdata, handles);
end


function JogLeftFast(slider, eventdata, handles, Slider_Callback)
% Jog the stage left as if the slider had moved a full thumb's distance
  newValue = get(slider, 'Value') - GetFastJog(slider, handles);
  SanitizeAndSetValue(slider, eventdata, handles, newValue, Slider_Callback);
end


function JogLeftModerate(slider, eventdata, handles, Slider_Callback)
% Jog the stage left as if the slider had moved a tick's distance
  newValue = get(slider, 'Value') - GetModerateJog(slider, handles);
  SanitizeAndSetValue(slider, eventdata, handles, newValue, Slider_Callback);
end


function JogLeftSlow(slider, eventdata, handles, Slider_Callback)
% Jog the stage left as if the slider had moved a fraction of a tick
  newValue = get(slider, 'Value') - GetSlowJog(slider, handles);
  SanitizeAndSetValue(slider, eventdata, handles, newValue, Slider_Callback);
end


function JogRightFast(slider, eventdata, handles, Slider_Callback)
% Jog the stage right as if the slider had moved a full thumb's distance
  newValue = get(slider, 'Value') + GetFastJog(slider, handles);
  SanitizeAndSetValue(slider, eventdata, handles, newValue, Slider_Callback);
end


function JogRightModerate(slider, eventdata, handles, Slider_Callback)
% Jog the stage right as if the slider had moved a tick's distance
  newValue = get(slider, 'Value') + GetModerateJog(slider, handles);
  SanitizeAndSetValue(slider, eventdata, handles, newValue, Slider_Callback);
end


function JogRightSlow(slider, eventdata, handles, Slider_Callback)
% Jog the stage right as if the slider had moved a fraction of a tick
  newValue = get(slider, 'Value') + GetSlowJog(slider, handles);
  SanitizeAndSetValue(slider, eventdata, handles, newValue, Slider_Callback);
end


function jog = GetFastJog(slider, handles)
% Jog the stage left as if the slider had moved a full thumb's distance
  % Calculate the jog distance
  switch handles.StepSize
    case 'Slow'
      sliderStep = handles.StepSizeArray(1,:);

    case 'Moderate'
      sliderStep = handles.StepSizeArray(2,:);

    case 'Fast'
      sliderStep = handles.StepSizeArray(3,:);
  end
  speed = sliderStep(2);
  range = get(slider, 'Max') - get(slider, 'Min');
  jog = range * speed;
end


function jog = GetModerateJog(slider, handles)
% Jog the stage left as if the slider had moved a full thumb's distance
  % Calculate the jog distance
  switch handles.StepSize
    case 'Slow'
      sliderStep = handles.StepSizeArray(1,:);

    case 'Moderate'
      sliderStep = handles.StepSizeArray(2,:);

    case 'Fast'
      sliderStep = handles.StepSizeArray(3,:);
  end
  speed = sliderStep(1);
  range = get(slider, 'Max') - get(slider, 'Min');
  jog = range * speed;
end


function jog = GetSlowJog(slider, handles)
% Jog the stage left as if the slider had moved a full thumb's distance
  % Calculate the jog distance
  switch handles.StepSize
    case 'Slow'
      sliderStep = handles.StepSizeArray(1,:);

    case 'Moderate'
      sliderStep = handles.StepSizeArray(2,:);

    case 'Fast'
      sliderStep = handles.StepSizeArray(3,:);
  end
  speed = sliderStep(1) / 5.0;
  range = get(slider, 'Max') - get(slider, 'Min');
  jog = range * speed;
end


function MoveStageToSliderPosition(axis, slider, handles)
% Moves the provided axis to the position specified by the slider control
  position = get(slider, 'Value') / 1000; % The stage controller uses the units of 'm', while the GUI uses 'mm'
  switch axis
    case 1 % X axis
      
    case 2 % Y axis
      
    case 3 % Z axis
      
  end
  handles.stageController.MoveAxis(axis, position);
end


function handles = MoveStageToCamera(handles)
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


function [value, clean] = SanitizeEdit(edit, stageRange)
% Checks a user's input and sanitizes it
  entry = get(edit, 'String');
  
  % Convert to one number and back to a string, ensuring something valid is
  % extracted
  value = sscanf(entry, '%g', 1);
  if isempty(value)
    warning('GUI:InvalidEntry', '''%s'' does not contain a valid number. Setting to ''%g''', value, stageRange(1));
    value = stageRange(1);
  elseif value < stageRange(1)
    warning('GUI:InvalidEntry', '''%g'' is below the accepted stage range. Setting to ''%g''', value, stageRange(1));
    value = stageRange(1);
  elseif value > stageRange(2)
    warning('GUI:InvalidEntry', '''%g'' is above the accepted stage range. Setting to ''%g''', value, stageRange(2));
    value = stageRange(2);
  end
  clean = sprintf('%g', value);
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
      handles = MoveStageToCamera(handles);
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


function UpdateControlSystem(handles)
% Updates the control system to what the user selected
  if handles.ComputerControl
    state = 'on';
  else
    state = 'off';
  end
  set(findall([handles.XAxisGroup, handles.YAxisGroup, handles.ZAxisGroup], '-property', 'Enable'), 'Enable', state);
end


function UpdateEdit2Slider(edit, axis, slider, stageRange, handles)
% Updates the values of the sliders according to the values entered in the
% edit boxes. Also sanitizes the input
  [value, clean] = SanitizeEdit(edit, stageRange);
  
  stageMin = stageRange(1);
  stageMax = stageRange(2);
  sliderMin = get(slider, 'Min');
  sliderMax = get(slider, 'Max');
  stageRatio = (value - stageMin) / (stageMax - stageMin);
  sliderValue = stageRatio * (sliderMax - sliderMin) + sliderMin;
  set(slider, 'Value', sliderValue);
  set(edit, 'String', clean);
  
  MoveStageToSliderPosition(axis, slider, handles);
end


function handles = UpdateStepSizeGroup(handles, eventdata)
% Update the controls related to the motor speed

  % Check to see if a radio button selection triggered the event. If so,
  % then update the motor speed choice
  if nargin == 2
    % Sets the relative size of a single step
    switch get(eventdata.NewValue, 'Tag')
      case 'Small'
        handles.StepSize = 'Small';

      case 'Medium'
        handles.StepSize = 'Medium';

      case 'Large'
        handles.StepSize = 'Large';
    end
  end
  
  switch handles.StepSize
    case 'Small'
      sliderStep = handles.StepSizeArray(1,:);
      
    case 'Medium'
      sliderStep = handles.StepSizeArray(2,:);
      
    case 'Large'
      sliderStep = handles.StepSizeArray(3,:);
  end
  
  set(handles.XSlider, 'SliderStep', sliderStep);
  set(handles.YSlider, 'SliderStep', sliderStep);
  set(handles.ZSlider, 'SliderStep', sliderStep);
end


function UpdateSlider2Edit(slider, axis, edit, stageRange, handles)
% Updates the values of the edit boxes according to the values entered in
% the sliders.
  value = get(slider, 'Value');
  stageMin = stageRange(1);
  stageMax = stageRange(2);
  sliderMin = get(slider, 'Min');
  sliderMax = get(slider, 'Max');
  sliderRatio = (value - sliderMin) / (sliderMax - sliderMin);
  value = sliderRatio * (stageMax - stageMin) + stageMin;
  set(edit, 'String', sprintf('%g', value));
  
  MoveStageToSliderPosition(axis, slider, handles);
end

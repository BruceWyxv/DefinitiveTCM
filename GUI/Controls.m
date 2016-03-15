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

% Last Modified by GUIDE v2.5 15-Mar-2016 15:32:49

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
    parser.addParameter('addOn', open('Controls_Template.fig'), @ishandle);
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
    handles.addOn = parser.Results.addOn;
  end
  
  % Load the add-on
  handles = LoadAddOn(hObject, handles);
  
  % Set some parameters
  axes(handles.CameraView)
  handles.CameraView = image(zeros(640, 480, 3));
  preview(handles.cameras.load, handles.CameraView);
  axis image; % Preserve the aspect ratio
  handles.StageRanges = [handles.settings.SampleBoundaries.x ...
                         handles.settings.SampleBoundaries.y ...
                         handles.settings.SampleBoundaries.z];
  set(handles.XEdit, 'String', '0');
  set(handles.YEdit, 'String', '0');
  set(handles.ZEdit, 'String', '0');
  UpdateEdit2Slider(handles.XEdit, 1, handles.XSlider, handles.StageRanges(1), handles);
  UpdateEdit2Slider(handles.YEdit, 2, handles.YSlider, handles.StageRanges(2), handles);
  UpdateEdit2Slider(handles.ZEdit, 3, handles.ZSlider, handles.StageRanges(3), handles);
  
  % Add listners so that dragging the sliders also updates the edit boxes,
  % but do not move the stages yet. Wait until the user has released the
  % cursor before actually moving the stages.
  addlistener(handles.XSlider, 'Value', 'PreSet',...
    @(~, ~) TrackSlider2Edit(handles.XSlider, handles.XEdit, handles.StageRanges(1)));
  addlistener(handles.YSlider, 'Value', 'PreSet',...
    @(~, ~) TrackSlider2Edit(handles.YSlider, handles.YEdit, handles.StageRanges(2)));
  addlistener(handles.ZSlider, 'Value', 'PreSet',...
    @(~, ~) TrackSlider2Edit(handles.ZSlider, handles.ZEdit, handles.StageRanges(3)));
  
  % Set the speeds and motor controls
  set(handles.Medium, 'Value', 1);
  handles.StepSize = 'Medium';
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


% --------------------------------------------------------------------
% --------------------------------------------------------------------
% --------------------------------------------------------------------
function CameraViewContextMenu_Callback(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to CameraViewContextMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end


function ComputerControl_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to ComputerControl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ComputerControl
  handles.ComputerControl = true;
  UpdateControlSystem(handles);
end


function ControlSystem_SelectionChangedFcn(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to the selected object in ControlSystem 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end


function Done_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to Done (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  close(handles.ControlsWindow);
end


function JoystickControl_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to JoystickControl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of JoystickControl
  handles.ComputerControl = false;
  UpdateControlSystem(handles);
end


function RecordVideo_Callback(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to RecordVideo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end


function SaveImage_Callback(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to SaveImage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end


function StepSizeGroup_SelectionChangedFcn(hObject, eventdata, handles) %#ok<DEFNU>
% hObject    handle to the selected object in StepSizeGroup 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  handles = UpdateStepSizeGroup(handles, eventdata);
  guidata(hObject, handles);
end


function XEdit_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to XEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of XEdit as text
%        str2double(get(hObject,'String')) returns contents of XEdit as a double
  UpdateEdit2Slider(hObject, 1, handles.XSlider, handles.StageRanges(1), handles);
end


function XLeftFast_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to XLeftFast (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   StepLeftLarge(handles.XSlider, eventdata, handles, @XSlider_Callback);
end


function XLeftModerate_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to XLeftModerate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   StepLeftMedium(handles.XSlider, eventdata, handles, @XSlider_Callback);
end


function XLeftSlow_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to XLeftSlow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   StepLeftSmall(handles.XSlider, eventdata, handles, @XSlider_Callback);
end


function XRightFast_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to XRightFast (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   StepRightLarge(handles.XSlider, eventdata, handles, @XSlider_Callback);
end


function XRightModerate_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to XRightModerate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   StepRightMedium(handles.XSlider, eventdata, handles, @XSlider_Callback);
end


function XRightSlow_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to XRightSlow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   StepRightSmall(handles.XSlider, eventdata, handles, @XSlider_Callback);
end


function XSlider_Callback(hObject, eventdata, handles) %#ok<INUSL>
% hObject    handle to XSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
  UpdateSlider2Edit(hObject, 1, handles.XEdit, handles.StageRanges(1), handles);
end


function YEdit_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to YEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of YEdit as text
%        str2double(get(hObject,'String')) returns contents of YEdit as a double
  UpdateEdit2Slider(hObject, 2, handles.YSlider, handles.StageRanges(2), handles);
end


function YLeftFast_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to YLeftFast (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   StepLeftLarge(handles.YSlider, eventdata, handles, @YSlider_Callback);
end


function YLeftModerate_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to YLeftModerate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   StepLeftMedium(handles.YSlider, eventdata, handles, @YSlider_Callback);
end


function YLeftSlow_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to YLeftSlow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   StepLeftSmall(handles.YSlider, eventdata, handles, @YSlider_Callback);
end


function YRightFast_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to YRightFast (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   StepRightLarge(handles.YSlider, eventdata, handles, @YSlider_Callback);
end


function YRightModerate_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to YRightModerate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   StepRightMedium(handles.YSlider, eventdata, handles, @YSlider_Callback);
end


function YRightSlow_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to YRightSlow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   StepRightSmall(handles.YSlider, eventdata, handles, @YSlider_Callback);
end


function YSlider_Callback(hObject, eventdata, handles) %#ok<INUSL>
% hObject    handle to YSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
  UpdateSlider2Edit(hObject, 2, handles.YEdit, handles.StageRanges(2), handles);
end


function ZEdit_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to ZEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ZEdit as text
%        str2double(get(hObject,'String')) returns contents of ZEdit as a double
  UpdateEdit2Slider(hObject, 3, handles.ZSlider, handles.StageRanges(3), handles);
end


function ZLeftFast_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to ZLeftFast (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   StepLeftLarge(handles.ZSlider, eventdata, handles, @ZSlider_Callback);
end


function ZLeftModerate_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to ZLeftModerate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   StepLeftMedium(handles.ZSlider, eventdata, handles, @ZSlider_Callback);
end


function ZLeftSlow_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to ZLeftSlow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   StepLeftSmall(handles.ZSlider, eventdata, handles, @ZSlider_Callback);
end


function ZRightFast_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to ZRightFast (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   StepRightLarge(handles.ZSlider, eventdata, handles, @ZSlider_Callback);
end


function ZRightModerate_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to ZRightModerate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   StepRightMedium(handles.ZSlider, eventdata, handles, @ZSlider_Callback);
end


function ZRightSlow_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to ZRightSlow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   StepRightSmall(handles.ZSlider, eventdata, handles, @ZSlider_Callback);
end


function ZSlider_Callback(hObject, eventdata, handles) %#ok<INUSL>
% hObject    handle to ZSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
  UpdateSlider2Edit(hObject, 3, handles.ZEdit, handles.StageRanges(3), handles);
end


% --------------------------------------------------------------------
% --------------------------------------------------------------------
% --------------------------------------------------------------------
function stagePosition = ConvertSlider2Position(slider, stageRange)
% Converts the slider position to stage position
  sliderPosition = get(slider, 'Value');
  sliderMin = get(slider, 'Min');
  sliderMax = get(slider, 'Max');
  sliderRatio = (sliderPosition - sliderMin) / (sliderMax - sliderMin);
  stagePosition = sliderRatio * stageRange;
end


function step = GetLargeStep(slider, handles)
% Jog the stage left as if the slider had moved a full thumb's distance
  % Calculate the jog distance
  switch handles.StepSize
    case 'Small'
      sliderStep = handles.StepSizeArray(1,:);

    case 'Medium'
      sliderStep = handles.StepSizeArray(2,:);

    case 'Large'
      sliderStep = handles.StepSizeArray(3,:);
  end
  speed = sliderStep(2);
  range = get(slider, 'Max') - get(slider, 'Min');
  step = range * speed;
end


function step = GetMediumStep(slider, handles)
% Jog the stage left as if the slider had moved a full thumb's distance
  % Calculate the jog distance
  switch handles.StepSize
    case 'Small'
      sliderStep = handles.StepSizeArray(1,:);

    case 'Medium'
      sliderStep = handles.StepSizeArray(2,:);

    case 'Large'
      sliderStep = handles.StepSizeArray(3,:);
  end
  speed = sliderStep(1);
  range = get(slider, 'Max') - get(slider, 'Min');
  step = range * speed;
end


function origin = GetOrigin(position, positionLocations)
% Fetches the origin of the position
  switch position
    case 'SampleLoading';
      origin = positionLocations.load;
      
    case 'CoarsePositioning';
      origin = positionLocations.wide;

    case 'ScanningObjective';
      origin = positionLocations.scan;
  end
end


function step = GetSmallStep(slider, handles)
% Jog the stage left as if the slider had moved a full thumb's distance
  % Calculate the jog distance
  switch handles.StepSize
    case 'Small'
      sliderStep = handles.StepSizeArray(1,:);

    case 'Medium'
      sliderStep = handles.StepSizeArray(2,:);

    case 'Large'
      sliderStep = handles.StepSizeArray(3,:);
  end
  speed = sliderStep(1) / 5.0;
  range = get(slider, 'Max') - get(slider, 'Min');
  step = range * speed;
end

function handles = LoadAddOn(figure, handles)
% Load the add on specified by handles.addOn
  controls = handles.addOn.Children;
  for i = 1:length(controls)
    % Get the properties
    control = controls(i);
    children = control.Children;
    type = control.Type;
    % Remove fields that will cause errors
    controlStruct = PurgeControlStruct(get(control));
    switch type
      case 'uibuttongroup'
        group = uibuttongroup(figure, controlStruct);
        handles.(controlStruct.Tag) = group;
        handles = LoadControls(handles, group, children);
        
      case 'uicontrol'
        handles.(controlStruct.Tag) = LoadControls(handles, figure, controlStruct);
    end
  end
  
  % Extract and set the name
  name = handles.addOn.Name;
  set(figure, 'Name', name);
  
  % TODO Detect where the sample is and choose the appropriate camera - BEGIN
  set(handles.SampleLoadPositionRadio, 'Value', 1);
  handles.CameraPosition = 'SampleLoading';
  handles.StagePosition = handles.CameraPosition;
  % TODO Detect where the sample is and choose the appropriate camera - END
  set(handles.LinkStageToCameraCheckbox, 'Value', 1);
  handles = UpdateCameraSelectionGroup(handles);
end

  function handles = LoadControls(handles, parent, controls)
  % Load an array of controls
    for i = 1:length(controls)
      controlStruct = PurgeControlStruct(get(controls(i)));
      handles.(controlStruct.Tag) = uicontrol(parent, controlStruct);
    end
  end


function MoveStageToSliderPosition(axis, slider, handles)
% Moves the provided axis to the position specified by the slider control
  switch handles.CameraPosition
    case 'SampleLoading';
      origin = handles.settings.PositionLocations.load(axis);
      
    case 'CoarsePositioning';
      origin = handles.settings.PositionLocations.wide(axis);

    case 'ScanningObjective';
      origin = handles.settings.PositionLocations.scan(axis);
  end
  
  relativePosition = ConvertSlider2Position(slider, stageRange);
  absolutePosition = origin + relativePosition;
  switch axis
    case 1
      relativeAxis = handles.settings.xAxisID;
      
    case 2
      relativeAxis = handles.settings.yAxisID;
      
    case 3
      relativeAxis = handles.settings.zAxisID;
  end
  handles.stageController.MoveAxis(relativeAxis, absolutePosition);
end


function controlStruct = PurgeControlStruct(controlStruct)
% Purge write-only fields from the struct
  badFields = {'BeingDeleted',...
               'Children',...
               'Extent',...
               'Parent',...
               'SelectedObject',...
               'Type'};
  for i = 1:length(badFields)
    if isfield(controlStruct, badFields{i})
      controlStruct = rmfield(controlStruct, badFields{i});
    end
  end
end


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


function StepLeftLarge(slider, eventdata, handles, Slider_Callback)
% Step the stage left as if the slider had moved a full thumb's distance
  newValue = get(slider, 'Value') - GetLargeStep(slider, handles);
  SanitizeAndSetValue(slider, eventdata, handles, newValue, Slider_Callback);
end


function StepLeftMedium(slider, eventdata, handles, Slider_Callback)
% Step the stage left as if the slider had moved a tick's distance
  newValue = get(slider, 'Value') - GetMediumStep(slider, handles);
  SanitizeAndSetValue(slider, eventdata, handles, newValue, Slider_Callback);
end


function StepLeftSmall(slider, eventdata, handles, Slider_Callback)
% Step the stage left as if the slider had moved a fraction of a tick
  newValue = get(slider, 'Value') - GetSmallStep(slider, handles);
  SanitizeAndSetValue(slider, eventdata, handles, newValue, Slider_Callback);
end


function StepRightLarge(slider, eventdata, handles, Slider_Callback)
% Step the stage right as if the slider had moved a full thumb's distance
  newValue = get(slider, 'Value') + GetLargeStep(slider, handles);
  SanitizeAndSetValue(slider, eventdata, handles, newValue, Slider_Callback);
end


function StepRightMedium(slider, eventdata, handles, Slider_Callback)
% Step the stage right as if the slider had moved a tick's distance
  newValue = get(slider, 'Value') + GetMediumStep(slider, handles);
  SanitizeAndSetValue(slider, eventdata, handles, newValue, Slider_Callback);
end


function StepRightSmall(slider, eventdata, handles, Slider_Callback)
% Step the stage right as if the slider had moved a fraction of a tick
  newValue = get(slider, 'Value') + GetSmallStep(slider, handles);
  SanitizeAndSetValue(slider, eventdata, handles, newValue, Slider_Callback);
end


function TrackSlider2Edit(slider, edit, stageRange)
% Updates the values of the edit boxes according to the values entered in
% the sliders.
  value = ConvertSlider2Position(slider, stageRange);
  set(edit, 'String', sprintf('%g', value));
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
% edit boxes. Also sanitizes the input.
  [value, clean] = SanitizeEdit(edit, stageRange);
  
  stageRatio = value / stageRange;
  sliderMin = get(slider, 'Min');
  sliderMax = get(slider, 'Max');
  sliderValue = stageRatio * (sliderMax - sliderMin) + sliderMin;
  set(slider, 'Value', sliderValue);
  set(edit, 'String', clean);
  
  MoveStageToSliderPosition(axis, slider, stageRange, handles);
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
  TrackSlider2Edit(slider, edit, stageRange)
  
  MoveStageToSliderPosition(axis, slider, stageRange, handles);
end
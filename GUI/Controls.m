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

% Last Modified by GUIDE v2.5 07-Apr-2016 10:00:37

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


function Controls_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<INUSL>
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

  % Choose default command line output for Controls
  handles.output = hObject;
  
  % Check the input arguments
  if ~isempty(varargin)
    parser = inputParser;
    parser.addParameter('addOn', '', @ishandle);
    parser.addParameter('cameras', '', @isstruct);
    parser.addParameter('mainWindow', '', @ishandle);
    parser.addParameter('preferences', '', @(x) isa(x, 'ConfigurationFile'));
    parser.addParameter('settings', '', @(x) isa(x, 'ConfigurationFile'));
    parser.addParameter('stageController', '', @(x) isa(x, 'ESP300_Control'));
    parser.addOptional('interfaceController', '');
    parser.addOptional('laserScanController', '');
    parser.addOptional('lockInAmpController', '');
    parser.addOptional('probeLaserController', '');
    parser.addOptional('pumpLaserController', '');
    % Parse the input arguments
    parser.KeepUnmatched = true;
    try
      parser.parse(varargin{:});
    catch me
      error('Error when trying to parse input arguments:   %s', me.message);
    end
    % Assigned values
    handles.addOn = parser.Results.addOn;
    handles.cameras = parser.Results.cameras;
    handles.laserScanController = parser.Results.laserScanController;
    handles.lockInAmpController = parser.Results.lockInAmpController;
    handles.mainWindow = parser.Results.mainWindow;
    handles.preferences = parser.Results.preferences;
    handles.interfaceController = parser.Results.interfaceController;
    handles.probeLaserController = parser.Results.probeLaserController;
    handles.pumpLaserController = parser.Results.pumpLaserController;
    handles.settings = parser.Results.settings;
    handles.stageController = parser.Results.stageController;
  end
  
  % Set the window position
  movegui(hObject, handles.preferences.current.WindowPositions.controls);
  movegui(hObject, 'onscreen');
  
  % Initialize the camera view
  axes(handles.CameraView)
  handles.CameraView = image(zeros(640, 480, 3));
  handles.CameraView.UIContextMenu = handles.CameraViewContextMenu;
  handles.currentCameraFeed = '';
  handles.CameraPosition = 'SampleLoading';
  handles = SwitchCamera(handles);
  handles.StagePosition = '';
  
  % Set some parameters
  handles.positionRanges = [handles.settings.current.PositionRanges.x; ...
                            handles.settings.current.PositionRanges.y; ...
                            handles.settings.current.PositionRanges.z];
  set(handles.XEdit, 'String', '0');
  set(handles.YEdit, 'String', '0');
  set(handles.ZEdit, 'String', '0');
  
  % Show only controls for available stages
  if handles.stageController.IsValidAxes(handles.settings.current.StageController.xAxisID)
    xState = 'on';
  else
    xState = 'off';
  end
  if handles.stageController.IsValidAxes(handles.settings.current.StageController.yAxisID)
    yState = 'on';
  else
    yState = 'off';
  end
  if handles.stageController.IsValidAxes(handles.settings.current.StageController.zAxisID)
    zState = 'on';
  else
    zState = 'off';
  end
  set(handles.XAxisGroup, 'Visible', xState);
  set(handles.YAxisGroup, 'Visible', yState);
  set(handles.ZAxisGroup, 'Visible', zState);
  
  % Set the currents states
  handles.IsBusy = false;
  handles.EnableMotors = true;
  
  % Load the add-on
  handles = LoadAddOn(hObject, handles);
  
  % Ensure the sliders are updated
  UpdateEdit2Slider(handles.XEdit, handles.XSlider, handles.positionRanges(1,:));
  UpdateEdit2Slider(handles.YEdit, handles.YSlider, handles.positionRanges(2,:));
  UpdateEdit2Slider(handles.ZEdit, handles.ZSlider, handles.positionRanges(3,:));
  
  % Add listners so that dragging the sliders also updates the edit boxes,
  % but do not move the stages yet. Wait until the user has released the
  % cursor before actually moving the stages.
  addlistener(handles.XSlider, 'Value', 'PreSet',...
    @(~, ~) TrackSlider2Edit(handles.XSlider, handles.XEdit, handles, 1));
  addlistener(handles.YSlider, 'Value', 'PreSet',...
    @(~, ~) TrackSlider2Edit(handles.YSlider, handles.YEdit, handles, 2));
  addlistener(handles.ZSlider, 'Value', 'PreSet',...
    @(~, ~) TrackSlider2Edit(handles.ZSlider, handles.ZEdit, handles, 3));
  
  % Set the motor controls and relative speeds
  set(handles.Small, 'Value', 1);
  handles.stepSize = 'Small';
  handles.stepSizeArray = [handles.settings.current.StageController.smallStepSize; ...
                           handles.settings.current.StageController.mediumStepSize; ...
                           handles.settings.current.StageController.largeStepSize];
  set(handles.ComputerControl, 'Value', 1);
  handles = UpdateStepSizeGroup(handles);
  
  % Update the GUI controls
  SetControlState(handles);

  % Update handles structure
  guidata(hObject, handles);
end


function ControlsWindow_CloseRequestFcn(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to ControlsWindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  % Check to see if the user moved the window at all
  currentPosition = getpixelposition(hObject);
  if currentPosition(1:2) ~= handles.preferences.current.WindowPositions.controls
    handles.preferences.current.WindowPositions.controls = currentPosition(1:2);
  end
  
  % We don't need any hardware, so close down shop for the time being
  handles.interfaceController.ConfigureForNothing();
  
  % Allow the add-on window to close its elements properly
  addOnHandle = str2func(handles.addOn.Tag);
  addOnHandle('CleanUpForClose', handles);
  
  delete(hObject);
end


function varargout = Controls_OutputFcn(hObject, eventdata, handles) %#ok<INUSL>
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  varargout{1} = handles.output;
end


% --------------------------------------------------------------------
% --------------------------------------------------------------------
% --------------------------------------------------------------------
function ControlSystem_SelectionChangedFcn(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to the selected object in ControlSystem 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  SetControlState(handles);
end


function Done_Callback(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to Done (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  close(hObject.Parent);
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
  UpdateEdit2Slider(hObject, handles.XSlider, handles.positionRanges(1,:));
  MoveStageToSliderPosition(1, handles.XSlider, handles);
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
  UpdateSlider2Edit(hObject, 1, handles.XEdit, handles);
end


function YEdit_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to YEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of YEdit as text
%        str2double(get(hObject,'String')) returns contents of YEdit as a double
  UpdateEdit2Slider(hObject, handles.YSlider, handles.positionRanges(2,:));
  MoveStageToSliderPosition(2, handles.YSlider, handles);
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
  UpdateSlider2Edit(hObject, 2, handles.YEdit, handles);
end


function ZEdit_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to ZEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ZEdit as text
%        str2double(get(hObject,'String')) returns contents of ZEdit as a double
  UpdateEdit2Slider(hObject, handles.ZSlider, handles.positionRanges(3,:));
  MoveStageToSliderPosition(3, handles.ZSlider, handles);
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
  UpdateSlider2Edit(hObject, 3, handles.ZEdit, handles);
end


% --------------------------------------------------------------------
% --------------------------------------------------------------------
% --------------------------------------------------------------------
function stagePosition = ConvertSlider2Position(slider, boundaries)
% Converts the slider position to stage position
  sliderPosition = get(slider, 'Value');
  sliderMin = get(slider, 'Min');
  sliderMax = get(slider, 'Max');
  sliderRatio = (sliderPosition - sliderMin) / (sliderMax - sliderMin);
  % Map ratio [0 1] to position [boundaries(1) boundaries(2)]
  range = boundaries(2) - boundaries(1);
  stagePosition = sliderRatio * range + boundaries(1);
end


function [stagePosition, x, y, z] = DetermineStagePosition(handles)
% Attempts to determine the current stage position from the absolute
% coordinates of the stages
  % Get the current coordinates
  coordinates = handles.stageController.GetAbsoluteCoordinates([handles.settings.current.StageController.xAxisID, ...
                                                                handles.settings.current.StageController.yAxisID, ...
                                                                handles.settings.current.StageController.zAxisID]);
  locations = handles.settings.current.PositionOrigins;
  ranges = handles.settings.current.PositionRanges;
  fields = fieldnames(locations);
  position = -1;
  stagePosition = '';
  
  % Determined the stage position
  found = false;
  for i = 1:length(fields)
    location = locations.(fields{i});
    x = coordinates(1) - location(1);
    y = coordinates(2) - location(2);
    z = coordinates(3) - location(3);
    if x >= ranges.x(1) && x <= ranges.x(2) && y >= ranges.y(1) && y <= ranges.y(2) && z >= ranges.z(1) && z <= ranges.z(2)
      position = i;
      found = true;
      break;
    else
      x = 0;
      y = 0;
      z = 0;
    end
  end
  
  % Are we in a location?
  if found
    % Convert to the internal system
    switch fields{position}
      case 'load'
        stagePosition = 'SampleLoading';
        handles.interfaceController.ConfigureForPositionSampleLoad();

      case 'wide'
        stagePosition = 'WideImage';
        handles.interfaceController.ConfigureForPositionWideImage();

      case 'scan'
        stagePosition = 'ScanningObjective';
        handles.interfaceController.ConfigureForPositionScan();
    end
  else
    stagePosition = 'SampleLoading';
    handles.interfaceController.ConfigureForPositionSampleLoad();
    LocateStageAtSampleLoading(handles, GetOrigin(stagePosition, locations));
  end
end


function step = GetLargeStep(slider, handles)
% Jog the stage left as if the slider had moved a full thumb's distance
  % Calculate the jog distance
  switch handles.stepSize
    case 'Small'
      sliderStep = handles.stepSizeArray(1,:);

    case 'Medium'
      sliderStep = handles.stepSizeArray(2,:);

    case 'Large'
      sliderStep = handles.stepSizeArray(3,:);
  end
  speed = sliderStep(2);
  range = get(slider, 'Max') - get(slider, 'Min');
  step = range * speed;
end


function step = GetMediumStep(slider, handles)
% Jog the stage left as if the slider had moved a full thumb's distance
  % Calculate the jog distance
  switch handles.stepSize
    case 'Small'
      sliderStep = handles.stepSizeArray(1,:);

    case 'Medium'
      sliderStep = handles.stepSizeArray(2,:);

    case 'Large'
      sliderStep = handles.stepSizeArray(3,:);
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
      
    case 'WideImage';
      origin = positionLocations.wide;

    case 'ScanningObjective';
      origin = positionLocations.scan;
  end
end


function step = GetSmallStep(slider, handles)
% Jog the stage left as if the slider had moved a full thumb's distance
  % Calculate the jog distance
  switch handles.stepSize
    case 'Small'
      sliderStep = handles.stepSizeArray(1,:);

    case 'Medium'
      sliderStep = handles.stepSizeArray(2,:);

    case 'Large'
      sliderStep = handles.stepSizeArray(3,:);
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
    type = control.Type;
    % Remove fields that will cause errors
    controlStruct = PurgeControlStruct(get(control));
    switch type
      case 'uibuttongroup'
        group = uibuttongroup(figure, controlStruct);
        handles.(controlStruct.Tag) = group;
        children = control.Children;
        handles = LoadControls(handles, group, children);
        
      case 'uicontrol'
        handles = LoadControls(handles, figure, controlStruct);
    end
  end
  
  % Extract and set the name
  name = handles.addOn.Name;
  set(figure, 'Name', name);
  
  % Attempt to determine the stage position if it is currently unknown
  handles = UpdateCurrentPositionToControls(handles);
  
  % Initialize any controls created
  addOnHandle = str2func(handles.addOn.Tag);
  handles = addOnHandle('InitializeChildren', handles);
end

function handles = LoadControls(handles, parent, controls)
% Load an array of controls
  if length(controls) == 1
    controlStruct = PurgeControlStruct(controls);
    handles.(controlStruct.Tag) = uicontrol(parent, controlStruct);
  else
    for i = 1:length(controls)
      controlStruct = PurgeControlStruct(get(controls(i)));
      handles.(controlStruct.Tag) = uicontrol(parent, controlStruct);
    end
  end
end


function LocateStageAtSampleLoading(handles, loadPosition)
% The stage is in an invalid position, meaning that it is not within one of
% the defined volumes. For now we will just move the stage to the Sample
% loading position, but we may modify the code in the future
  
  % Move the axis, showing a progress bar
  % Make sure to drop the Z axis down first, second move the X and Y axes,
  % then finally move the Z axis to its final position
  handles.stageController.UseFastSpeed();
  handles.stageController.MoveAxis(handles.settings.current.StageController.zAxisID, handles.settings.current.SoftStageBoundaries.z(1), true);
  handles.stageController.MoveAxis([handles.settings.current.StageController.xAxisID, handles.settings.current.StageController.yAxisID], loadPosition(1:2), true);
  handles.stageController.MoveAxis(handles.settings.current.StageController.zAxisID, loadPosition(3), true);
  handles.stageController.UseSlowSpeed();
end


function [handles, returnToSampleLoadingPosition] = MoveStageToCamera(handles)  %#ok<DEFNU>
  % First, open a modal progress bar while we are moving the stage. We
  % don't want the user to be able to change anything until the stage
  % movement is complete. Also, disable the close functionality (a user
  % should not be able to prematurely close the window while the process is
  % still completing.
  returnToSampleLoadingPosition = false;
  
  % Only move the stages if we are not at the same location
  if ~strcmp(handles.StagePosition, handles.CameraPosition)
    % Temporarily disable the controls while the stage is moving
    handles.IsBusy = true;
    SetControlState(handles);
    
    % Increase the axes speed
    handles.stageController.UseFastSpeed();
    
    % Check if the sample loading position is involved
    fromSampleLoading = strcmp('SampleLoading', handles.StagePosition);
    toSampleLoading = strcmp('SampleLoading', handles.CameraPosition);

    % Get the current stage positions
    if fromSampleLoading
      % Perform crash prevention
      handles.interfaceController.ConfigureForSampleHeightMeasurement();
      returnToSampleLoadingPosition = PerformCrashPrevention(handles);
      
      if returnToSampleLoadingPosition
        handles.IsBusy = false;
        SetControlState(handles);
        return;
      end
      
      % Update the position ranges
      positionRangeZ = [handles.settings.cache.zStageLimits(1) - handles.settings.cache.sampleTop, ...
                        handles.settings.cache.sampleTop - handles.settings.cache.zStageLimits(2)];
      handles.positionRanges = [handles.settings.current.PositionRanges.x; ...
                                handles.settings.current.PositionRanges.y; ...
                                positionRangeZ];
      
      % Set the coordinates
      current = [handles.preferences.current.CurrentCoordinates.x, ...
                 handles.preferences.current.CurrentCoordinates.y, ...
                 handles.preferences.current.CurrentCoordinates.z];
      handles.EnableMotors = true;
    else
      current = [str2double(get(handles.XEdit, 'String')) ...
                 str2double(get(handles.YEdit, 'String')) ...
                 str2double(get(handles.ZEdit, 'String'))];
      
      if toSampleLoading
        handles.preferences.current.CurrentCooridnates.x = current(1);
        handles.preferences.current.CurrentCooridnates.y = current(2);
        handles.preferences.current.CurrentCooridnates.z = current(3);
        
        handles.EnableMotors = false;
      end
    end
    
    % Update interface
    switch handles.CameraPosition
      case 'SampleLoading'
        handles.interfaceController.ConfigureForPositionSampleLoad();
        
      case 'WideImage'
        handles.interfaceController.ConfigureForPositionWideImage();
        
      case 'ScanningObjective'
        handles.interfaceController.ConfigureForPositionScan();
    end
    
    % Get the new origin and calculate the new position
    cameraOrigin = GetOrigin(handles.CameraPosition, handles.settings.current.PositionOrigins);
    new = current + cameraOrigin;
    % Move the axis, showing a progress bar
    % Make sure to drop the Z axis down first, second move the X and Y axes,
    % then finally move the Z axis to its final position
    handles.stageController.MoveAxis(handles.settings.current.StageController.zAxisID, handles.settings.current.SafeTraverseHeight.z, true);
    handles.stageController.MoveAxis([handles.settings.current.StageController.xAxisID, handles.settings.current.StageController.yAxisID], new(1:2), true);
    handles.stageController.MoveAxis(handles.settings.current.StageController.zAxisID, new(3), true);
    handles = UpdateCurrentPositionToControls(handles);

    % The stage should now be in the camera's field-of-view
    handles.StagePosition = handles.CameraPosition;

    % Return to the slow speed
    handles.stageController.UseSlowSpeed();
    
    handles.IsBusy = false;
    SetControlState(handles)
  end
end


function MoveStageToSliderPosition(axis, slider, handles)
% Moves the provided axis to the position specified by the slider control
  switch handles.CameraPosition
    case 'SampleLoading';
      origin = handles.settings.current.PositionOrigins.load(axis);
      
    case 'WideImage';
      origin = handles.settings.current.PositionOrigins.wide(axis);

    case 'ScanningObjective';
      origin = handles.settings.current.PositionOrigins.scan(axis);
  end
  
  relativePosition = ConvertSlider2Position(slider, handles.positionRanges(axis,:));
  switch axis
    case 1
      relativeAxis = handles.settings.current.StageController.xAxisID;
      if handles.settings.current.ReverseTravel.x ~= 0
        relativePosition = -relativePosition;
      end
      handles.preferences.current.CurrentCoordinates.x = relativePosition;
      
    case 2
      relativeAxis = handles.settings.current.StageController.yAxisID;
      if handles.settings.current.ReverseTravel.y ~= 0
        relativePosition = -relativePosition;
      end
      handles.preferences.current.CurrentCoordinates.y = relativePosition;
      
    case 3
      relativeAxis = handles.settings.current.StageController.zAxisID;
      if handles.settings.current.ReverseTravel.z ~= 0
        relativePosition = -relativePosition;
      end
      handles.preferences.current.CurrentCoordinates.z = relativePosition;
  end
  
  absolutePosition = origin + relativePosition;
  handles.stageController.MoveAxis(relativeAxis, absolutePosition);
end


function returnToSampleLoadingPosition = PerformCrashPrevention(handles)
% Perform the crash prevention routine
  % Open the window to track the progress
  profileHandle = CrashPrevention('Settings', handles.settings);
  
  done = false;
  returnToSampleLoadingPosition = false;
  x = handles.settings.current.CrashPrevention.stageEdge;
  scanWidth = handles.settings.current.CrashPrevention.scanWidth;
  startX = x;
  endX = startX - scanWidth;
  centerX = (startX + endX) / 2;
  y = handles.settings.current.CrashPrevention.stageHeight - 1;
  softVerticalLimits = handles.settings.original.SoftStageBoundaries.z;
  endY = softVerticalLimits(1);
  step = handles.settings.current.CrashPrevention.stepSize;
  trace = (handles.settings.current.CrashPrevention.trace == 1);
  stageHeightAtHighestTracePoint = softVerticalLimits(2);
  firstEdge = 0;
  while ~done
    % Strangely enough, the axis mappings for the profiling are:
    %   x -> Y stage
    %   y -> Z stage
    isBlocked = IsLocationBlocked(handles, x, y);
    returnToSampleLoadingPosition = CrashPrevention('Update', profileHandle, x - centerX, y, isBlocked);
    
    if isBlocked % Move up
      % Set the value to the highest found point
      if y < stageHeightAtHighestTracePoint && firstEdge > 5
        stageHeightAtHighestTracePoint = y;
      end
      
      y = y - step;
      if y < softVerticalLimits(1)
        % This could indicate that the sample height may exceed the limits
        % of the TCM. Throw and error/warning message here instead?
        y = softVerticalLimits(1);
        x = x - step;
      end
    else % Move across
      x = x - step;
      firstEdge = firstEdge + 1;
      
      if trace
        while ~isBlocked && ~returnToSampleLoadingPosition 
          y = y + step;
          % Break the loop if it will exceed the soft stage limits
          if y > softVerticalLimits(2)
            break
          end
          
          isBlocked = IsLocationBlocked(handles, x, y);
          returnToSampleLoadingPosition = CrashPrevention('Update', profileHandle, x - centerX, y, isBlocked);
        end
        y = y - step;
      end
    end
    
    % Check to see if we've scanned the breadth of the stage
    xDone = x < endX;
    yDone = y < endY;
    done = xDone || yDone || returnToSampleLoadingPosition;
  end
  
  CrashPrevention('Close', profileHandle);
  
  % Update the soft limits on the stage controller
  softVerticalLimits(2) = stageHeightAtHighestTracePoint ... The lowest value that the stage had to be at to clear the beam
                          + handles.settings.current.CrashPrevention.wiggleRoom ... Some space to breath
                          - handles.settings.current.CrashPrevention.offset... The vertical distance between the slot detector beam and the objective working distance
                          + handles.settings.current.CrashPrevention.heaterOffset; % Allow the heated stage to move up so that the microscope objective is inside of it a certain distance
  handles.settings.cache.zStageLimits = softVerticalLimits;
  handles.settings.cache.sampleTop = stageHeightAtHighestTracePoint;
  
  % Adjust the current coordinate height so that it will match the 0 point
  % of the wide and scan positions
  handles.settings.current.PositionOrigins.scan(3) = stageHeightAtHighestTracePoint - handles.settings.current.CrashPrevention.offset;
  handles.settings.current.PositionOrigins.wide(3) = handles.settings.current.PositionOrigins.scan(3) +  handles.settings.current.CrashPrevention.wideOffsetToScan;
  
  % Set the limits
  handles.stageController.SetLimits(handles.settings.current.StageController.zAxisID, softVerticalLimits); 
end


function isBlocked = IsLocationBlocked(handles, x, y)
% Determines if a point is blocking the slot detector beam
  handles.stageController.MoveAxis([handles.settings.current.StageController.yAxisID, handles.settings.current.StageController.zAxisID], [x, y]);
  value = handles.lockInAmpController.GetAuxInputValue(handles.settings.current.CrashPrevention.inputChannel);
  isBlocked = value > handles.settings.current.CrashPrevention.blockedCutoffVoltage;
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


function [value, clean] = SanitizeEdit(edit, boundaries)
% Checks a user's input and sanitizes it
  entry = get(edit, 'String');
  
  % Convert to one number and back to a string, ensuring something valid is
  % extracted
  value = sscanf(entry, '%g', 1);
  if isempty(value)
    warning('GUI:InvalidEntry', '''%s'' does not contain a valid number. Setting to ''0''', value);
    value = 0;
  elseif value < boundaries(1)
    if ~isFloatEqual(value, boundaries(1), 1e-3)
      warning('GUI:InvalidEntry', '''%g'' is below the accepted stage range. Setting to ''%g''', boundaries(1));
    end
    value = boundaries(1);
  elseif value > boundaries(2)
    if ~isFloatEqual(value, boundaries(2), 1e-3)
      warning('GUI:InvalidEntry', '''%g'' is above the accepted stage range. Setting to ''%g''', value, boundaries(2));
    end
    value = boundaries(2);
  end
  clean = sprintf('%g', value);
end


function SetControlState(handles)
% Disables all controls on this window
  % First evaluate non-motor controls
  state = 'On';
  controls = [handles.StepSizeGroup,...
              handles.ControlSystem];
  if handles.IsBusy == true || strcmp('SampleLoading', handles.StagePosition)
    state = 'Off';
  end
  set(findall(controls, '-property', 'Enable'), 'Enable', state);
  % Also evaluate for child window controls
  addOnHandle = str2func(handles.addOn.Tag);
  addOnHandle('SetControlState', handles, state);
  
  % Now evaluate state for motor controls
  state = 'On';
  controls = [handles.XAxisGroup,...
              handles.YAxisGroup,...
              handles.ZAxisGroup];
  if handles.IsBusy || get(handles.ComputerControl, 'Value') == 0 || strcmp('SampleLoading', handles.StagePosition)
    % Change the state if the joystick is enabled
    state = 'off';
  end
  set(findall(controls, '-property', 'Enable'), 'Enable', state);
  
  % Evaluate the 'Done' button for closing the window
  state = 'On';
  if handles.IsBusy == true
    state = 'Off';
  end
  set(handles.Done, 'Enable', state);
  
  % Disable the computer/joystick toggle since that code is not yet
  % implemented
  set(findall(handles.ControlSystem, '-property', 'Enable'), 'Enable', 'Off');
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


function TrackSlider2Edit(slider, edit, handles, axis)
% Updates the values of the edit boxes according to the values entered in
% the sliders.
  value = ConvertSlider2Position(slider, handles.positionRanges(axis,:));
  set(edit, 'String', sprintf('%g', value));
end

function handles = SwitchCamera(handles) %#ok<DEFNU>
% Selects a new camera for the video feed
  switch handles.CameraPosition
    case 'SampleLoading'
      newCamera = handles.cameras.load;
      
    case 'WideImage'
      newCamera = handles.cameras.wide;
      
    case 'ScanningObjective'
      newCamera = handles.cameras.scan;
  end

  % Start the camera video feed
  if ~isempty(handles.currentCameraFeed)
    closepreview(handles.currentCameraFeed);
  end
  preview(newCamera, handles.CameraView);
  axis image; % Preserve the aspect ratio
  handles.currentCameraFeed = newCamera;
end


function handles = UpdateCurrentPositionToControls(handles)
% Update the values of the edit boxes with the current values from the
% stages themselves
  [stagePosition, x, y, z] = DetermineStagePosition(handles);
  handles.StagePosition = stagePosition;
  if ~isempty(handles.StagePosition)
    set(handles.XEdit, 'String', num2str(x));
    set(handles.YEdit, 'String', num2str(y));
    set(handles.ZEdit, 'String', num2str(z));

    UpdateEdit2Slider(handles.XEdit, handles.XSlider, handles.positionRanges(1,:));
    UpdateEdit2Slider(handles.YEdit, handles.YSlider, handles.positionRanges(2,:));
    UpdateEdit2Slider(handles.ZEdit, handles.ZSlider, handles.positionRanges(3,:));
  end
end


function UpdateFocusPosition(handles, focusPosition) %#ok<DEFNU>
% Update the position of the Z Axis based on the best focus position
  set(handles.ZEdit, 'String', num2str(focusPosition));
  UpdateEdit2Slider(handles.ZEdit, handles.ZSlider, handles.positionRanges(3,:));
end


function UpdateEdit2Slider(edit, slider, boundaries)
% Updates the values of the sliders according to the values entered in the
% edit boxes. Also sanitizes the input.
  [value, clean] = SanitizeEdit(edit, boundaries);
  
  % Map value from [boundaries(1) boundaries(2)] to [0 1]
  range = boundaries(2) - boundaries(1);
  stageRatio = (value - boundaries(1)) / range;
  sliderMin = get(slider, 'Min');
  sliderMax = get(slider, 'Max');
  sliderValue = stageRatio * (sliderMax - sliderMin) + sliderMin;
  set(slider, 'Value', sliderValue);
  set(edit, 'String', clean);
end


function handles = UpdateStepSizeGroup(handles, eventdata)
% Update the controls related to the motor speed

  % Check to see if a radio button selection triggered the event. If so,
  % then update the motor speed choice
  if nargin == 2
    % Sets the relative size of a single step
    switch get(eventdata.NewValue, 'Tag')
      case 'Small'
        handles.stepSize = 'Small';

      case 'Medium'
        handles.stepSize = 'Medium';

      case 'Large'
        handles.stepSize = 'Large';
    end
  end
  
  switch handles.stepSize
    case 'Small'
      sliderStep = handles.stepSizeArray(1,:);
      
    case 'Medium'
      sliderStep = handles.stepSizeArray(2,:);
      
    case 'Large'
      sliderStep = handles.stepSizeArray(3,:);
  end
  
  set(handles.XSlider, 'SliderStep', sliderStep);
  set(handles.YSlider, 'SliderStep', sliderStep);
  set(handles.ZSlider, 'SliderStep', sliderStep);
end


function UpdateSlider2Edit(slider, axis, edit, handles)
% Updates the values of the edit boxes according to the values of the
% sliders.
  TrackSlider2Edit(slider, edit, handles, axis)
  
  MoveStageToSliderPosition(axis, slider, handles);
end

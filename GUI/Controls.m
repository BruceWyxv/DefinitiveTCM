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
  handles.StagePosition = '';
  
  % Set some parameters
  handles.positionRanges = [handles.settings.current.PositionRanges.x; ...
                            handles.settings.current.PositionRanges.y; ...
                            GetDynamicVerticalPositionBounds(handles, handles.CameraPosition)];
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
  
  % Load the add-on and start the camera
  handles = LoadAddOn(hObject, handles);
  handles = SwitchCamera(handles);
  
  % Ensure the sliders are updated
  handles = UpdateListeners(handles);
  UpdateEdit2Slider(handles.XEdit, handles.XSlider, handles.positionRanges(1,:));
  UpdateEdit2Slider(handles.YEdit, handles.YSlider, handles.positionRanges(2,:));
  UpdateEdit2Slider(handles.ZEdit, handles.ZSlider, handles.positionRanges(3,:));
  
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
  
  % Check to see if 'handles' is in a valid state
  if isfield(handles, 'preferences')
    if currentPosition(1:2) ~= handles.preferences.current.WindowPositions.controls
      handles.preferences.current.WindowPositions.controls = currentPosition(1:2);
    end
    
    % We don't need any hardware, so close down shop for the time being
    handles.interfaceController.ConfigureForNothing();

    % Allow the add-on window to close its elements properly
    addOnHandle = str2func(handles.addOn.Tag);
    addOnHandle('CleanUpForClose', handles);
  end
  
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
  MoveStageToEditPosition(1, hObject, handles);
  UpdateEdit2Slider(hObject, handles.XSlider, handles.positionRanges(1,:));
  guidata(hObject, handles);
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
  MoveStageToSliderPosition(1, hObject, handles);
  UpdateSlider2Edit(hObject, handles.XEdit, handles, 1)
end


function YEdit_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to YEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of YEdit as text
%        str2double(get(hObject,'String')) returns contents of YEdit as a double
  MoveStageToEditPosition(2, hObject, handles);
  UpdateEdit2Slider(hObject, handles.YSlider, handles.positionRanges(2,:));
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
  MoveStageToSliderPosition(2, hObject, handles);
  UpdateSlider2Edit(hObject, handles.YEdit, handles, 2)
end


function ZEdit_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to ZEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ZEdit as text
%        str2double(get(hObject,'String')) returns contents of ZEdit as a double
  MoveStageToEditPosition(3, hObject, handles);
  UpdateEdit2Slider(hObject, handles.ZSlider, handles.positionRanges(3,:));
  guidata(hObject, handles);
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
  MoveStageToSliderPosition(3, hObject, handles);
  UpdateSlider2Edit(hObject, handles.ZEdit, handles, 3)
end


% --------------------------------------------------------------------
% --------------------------------------------------------------------
% --------------------------------------------------------------------
function stageCoordinates = ConvertPositions2StageCoordinates(handles, stagePosition, positionCoordinates)
% Converts the provided relative coordinates to actual stage coordinates
  origins = GetOrigin(stagePosition, handles);

  if handles.settings.current.ReverseTravel.x == 1
    positionCoordinates(1) = -positionCoordinates(1);
  end
  if handles.settings.current.ReverseTravel.y == 1
    positionCoordinates(2) = -positionCoordinates(2);
  end
  if handles.settings.current.ReverseTravel.z == 1
    positionCoordinates(3) = -positionCoordinates(3);
  end
  
  % Use the sample top as the '0' value for 'z'
  stageCoordinates = origins + positionCoordinates;
end

function positionCoordinates = ConvertStages2PositionCoordinates(handles, stagePosition, stageCoordinates)
% Converts the provided absolute stage coordinates to the relative
% coordinate system of the provided stage position
  origins = GetOrigin(stagePosition, handles);
  
  % Set the sample top as the '0' value for 'z'
  positionCoordinates = stageCoordinates - origins;
                       
  if handles.settings.current.ReverseTravel.x == 1
    positionCoordinates(1) = -positionCoordinates(1);
  end
  if handles.settings.current.ReverseTravel.y == 1
    positionCoordinates(2) = -positionCoordinates(2);
  end
  if handles.settings.current.ReverseTravel.z == 1
    positionCoordinates(3) = -positionCoordinates(3);
  end
end

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


function [stagePosition, x, y, z] = DetermineStagePositionAndPositionCoordinates(handles)
% Attempts to determine the current stage position from the absolute
% coordinates of the stages
  % Get the current coordinates
  stageCoordinates = handles.stageController.GetAbsoluteCoordinates([handles.settings.current.StageController.xAxisID, ...
                                                                     handles.settings.current.StageController.yAxisID, ...
                                                                     handles.settings.current.StageController.zAxisID]);
  locations = handles.settings.current.PositionOrigins;
  fields = fieldnames(locations);
  
  x = 0;
  y = 0;
  z = 0;
  
  % Determined the stage position
  found = false;
  for i = 1:length(fields)
    % Convert to the internal system
    switch fields{i}
      case 'load'
        stagePosition = 'SampleLoading';
        handles.interfaceController.ConfigureForPositionSampleLoad();

      case 'wide'
        stagePosition = 'WideImage';
        handles.interfaceController.ConfigureForPositionWideImage();

      case 'scan'
        stagePosition = 'ScanningObjective';
        handles.interfaceController.ConfigureForPositionScan();
        
      otherwise
        continue
    end
    
    if IsInStageBounds(handles, stagePosition, stageCoordinates)
      found = true;
      positionCoordinates = ConvertStages2PositionCoordinates(handles, stagePosition, stageCoordinates);
      x = positionCoordinates(1);
      y = positionCoordinates(2);
      z = positionCoordinates(3);
      break;
    end
  end
  
  % Are we in a location?
  if found
    switch stagePosition
      case 'SampleLoading';
        handles.interfaceController.ConfigureForPositionSampleLoad();

      case 'WideImage';
        handles.interfaceController.ConfigureForPositionWideImage();

      case 'ScanningObjective';
        handles.interfaceController.ConfigureForPositionScan();
    end
  else
    stagePosition = 'SampleLoading';
    handles.interfaceController.ConfigureForPositionSampleLoad();
    LocateStageAtSampleLoading(handles, GetOrigin(stagePosition, handles));
    ReadCurrentPositionAndUpdateControls(handles);
  end
end


function [stageCoordinates, modified] = GetClosestInBoundStageCoordinates(handles, stagePosition, stageCoordinates)
% Returns the closest in-bounds position coordinates possible
  modified = [false, false, false];
  verticalBounds = GetDynamicVerticalStageBounds(handles, stagePosition);
  
  % The z-axis can be evaluated for both the heated and regular stages
  if stageCoordinates(3) < verticalBounds(1)
    stageCoordinates(3) = verticalBounds(1);
    modified(3) = true;
  elseif stageCoordinates(3) > verticalBounds(2)
    stageCoordinates(3) = verticalBounds(2);
    modified(3) = true;
  end
  
  origins = GetOrigin(stagePosition, handles);
  
  if handles.settings.cache.isHeatedStage
    % Use a disc coordinate system and return a location on the cylinder
    % surface if the points are outside the volume
    x = stageCoordinates(1) - origins(1);
    y = stageCoordinates(2) - origins(2);
    r = sqrt(x*x + y*y);
    R = handles.settings.current.CrashPrevention.heatedStageInnerRadius;
    if r > R
      scale = R / r;
      stageCoordinates(1) = x * scale + origins(1);
      stageCoordinates(2) = y * scale + origins(2);
      modified(1) = true;
      modified(2) = true;
    end
  else % Regular stage
    xRange = handles.settings.current.PositionRanges.x + origins(1);
    if stageCoordinates(1) < xRange(1)
      stageCoordinates(1) = xRange(1);
      modified(1) = true;
    elseif stageCoordinates(1) > xRange(2)
      stageCoordinates(1) = xRange(2);
      modified(1) = true;
    end
    
    yRange = handles.settings.current.PositionRanges.y + origins(2);
    if stageCoordinates(2) < yRange(1)
      stageCoordinates(2) = yRange(1);
      modified(2) = true;
    elseif stageCoordinates(2) > yRange(2)
      stageCoordinates(2) = yRange(2);
      modified(2) = true;
    end
  end
end


function verticalBounds = GetDynamicVerticalPositionBounds(handles, stagePosition)
% Gets the dynamic vertical bounds at the provided stage position
  stageBounds = GetDynamicVerticalStageBounds(handles, stagePosition);
  
  if handles.settings.cache.isHeatedStage
    additionalOffset = handles.settings.current.CrashPrevention.heatedStageBasketDepth;
  else % Regular stage
    additionalOffset = 0.0;
  end
  
  verticalBounds = stageBounds - handles.settings.cache.sampleTop;
  
  if verticalBounds(2) > handles.settings.current.CrashPrevention.wiggleRoom + additionalOffset
    verticalBounds(2) = handles.settings.current.CrashPrevention.wiggleRoom + additionalOffset;
  end
end


function verticalBounds = GetDynamicVerticalStageBounds(handles, stagePosition)
% Gets the dynamic vertical bounds at the provided stage position
  verticalBounds = handles.settings.current.SoftStageBoundaries.z;
  
  if handles.settings.cache.isHeatedStage
    additionalOffset = handles.settings.current.CrashPrevention.heatedStageBasketDepth;
  else % Regular stage
    additionalOffset = 0.0;
  end
  
  sampleTop = handles.settings.cache.sampleTop + additionalOffset;
  slot2WideOffset = handles.settings.current.CrashPrevention.slotOffsetToWide;
  wide2ScanOffset = handles.settings.current.CrashPrevention.wideOffsetToScan;
  wiggleRoom = handles.settings.current.CrashPrevention.wiggleRoom;

  switch stagePosition
    case 'SampleLoading';
      % Nothing changes

    case 'WideImage';
      verticalBounds(2) = (sampleTop - slot2WideOffset) + wiggleRoom;

    case 'ScanningObjective';
      verticalBounds(2) = (sampleTop - (slot2WideOffset + wide2ScanOffset)) + wiggleRoom;
  end
  
  % Check to see if we have move beyond the stage limits
  if verticalBounds(2) > handles.settings.current.SoftStageBoundaries.z(2)
    verticalBounds(2) = handles.settings.current.SoftStageBoundaries.z(2);
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


function origin = GetOrigin(position, handles)
% Fetches the origin of the position
  switch position
    case 'SampleLoading';
      origin = handles.settings.current.PositionOrigins.load;
      origin(3) = 0.0;
      
    case 'WideImage';
      origin = handles.settings.current.PositionOrigins.wide;
      origin(3) = handles.settings.cache.sampleTop ...
                  - handles.settings.current.CrashPrevention.slotOffsetToWide;

    case 'ScanningObjective';
      origin = handles.settings.current.PositionOrigins.scan;
      origin(3) = handles.settings.cache.sampleTop ...
                  - handles.settings.current.CrashPrevention.slotOffsetToWide ...
                  - handles.settings.current.CrashPrevention.wideOffsetToScan;
      
    otherwise
      error('Cannot get origin when the position is undefined.');
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


function inBounds = IsInStageBounds(handles, stagePosition, stageCoordinates)
% Determines if the provided stage positions are in bounds
  inBounds = true;
  verticalBounds = GetDynamicVerticalStageBounds(handles, stagePosition);
  
  % The z-axis can be evaluated for both the heated and regular stages
  if stageCoordinates(3) < verticalBounds(1) || stageCoordinates(3) > verticalBounds(2)
    inBounds = false;
    return;
  end
  
  origins = GetOrigin(stagePosition, handles);
  
  if handles.settings.cache.isHeatedStage
    % Use a disc coordinate system and see if the points are within
    % the volume
    x = stageCoordinates(1) - origins(1);
    y = stageCoordinates(2) - origins(2);
    r = sqrt(x*x + y*y);
    if r > handles.settings.current.CrashPrevention.heatedStageInnerRadius;
      inBounds = false;
      return;
    end
  else % Regular stage
    xRange = handles.settings.current.PositionRanges.x + origins(1);
    if stageCoordinates(1) < xRange(1) || stageCoordinates(1) > xRange(2)
      inBounds = false;
      return;
    end
    
    yRange = handles.settings.current.PositionRanges.y + origins(2);
    if stageCoordinates(2) < yRange(1) || stageCoordinates(2) > yRange(2)
      inBounds = false;
      return;
    end
  end
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
  handles = ReadCurrentPositionAndUpdateControls(handles);
  
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
      
    % Get the coordinates
    current = [handles.preferences.current.CurrentCoordinates.x, ...
               handles.preferences.current.CurrentCoordinates.y, ...
               handles.preferences.current.CurrentCoordinates.z];

    % Get the current stage positions
    if fromSampleLoading
      % Perform crash prevention
      handles.interfaceController.ConfigureForSampleHeightMeasurement();
      returnToSampleLoadingPosition = PerformCrashPrevention(handles);
      
      % Update the bounds
      handles = UpdateBounds(handles);
      
      if returnToSampleLoadingPosition
        handles.IsBusy = false;
        SetControlState(handles);
        return;
      end
      
      handles.EnableMotors = true;
    else
      if toSampleLoading
        current = [0.0, 0.0, 0.0];
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
    % Move the axis, showing a progress bar
    % Make sure to drop the Z axis down first, second move the X and Y axes,
    % then finally move the Z axis to its final position
    new = ConvertPositions2StageCoordinates(handles, handles.CameraPosition, current);
    handles.stageController.MoveAxis(handles.settings.current.StageController.zAxisID, handles.settings.current.SafeTraverseHeight.z, true);
    handles.stageController.MoveAxis([handles.settings.current.StageController.xAxisID, handles.settings.current.StageController.yAxisID], new(1:2), true);
    handles.stageController.MoveAxis(handles.settings.current.StageController.zAxisID, new(3), true);
    handles = ReadCurrentPositionAndUpdateControls(handles);
    
    % Update the sliders to track appropriately for the new position
    handles = UpdateListeners(handles);

    % The stage should now be in the camera's field-of-view
    handles.StagePosition = handles.CameraPosition;

    % Return to the slow speed
    handles.stageController.UseSlowSpeed();
    
    handles.IsBusy = false;
    SetControlState(handles)
  end
end


function MoveStageToEditPosition(axis, edit, handles)
% Moves the provided axis to the position specified by the edit control
  [relativePosition, ~] = SanitizeEdit(edit, handles.positionRanges(axis,:));
  
  MoveStageToRelativePosition(handles, axis, relativePosition);
end


function MoveStageToRelativePosition(handles, axis, relativePosition)
% Moves the provided axis to the position specified
  stagePosition = handles.StagePosition;
  
  switch axis
    case 1
      relativeAxis = handles.settings.current.StageController.xAxisID;
      handles.preferences.current.CurrentCoordinates.x = relativePosition;
      
    case 2
      relativeAxis = handles.settings.current.StageController.yAxisID;
      handles.preferences.current.CurrentCoordinates.y = relativePosition;
      
    case 3
      relativeAxis = handles.settings.current.StageController.zAxisID;
      handles.preferences.current.CurrentCoordinates.z = relativePosition;
  end
  
  positionCoordinates = [handles.preferences.current.CurrentCoordinates.x, ...
                         handles.preferences.current.CurrentCoordinates.y, ...
                         handles.preferences.current.CurrentCoordinates.z];
  stageCoordinates = ConvertPositions2StageCoordinates(handles, stagePosition, positionCoordinates);
  
  if ~IsInStageBounds(handles, stagePosition, stageCoordinates)
    [stageCoordinates, modified] = GetClosestInBoundStageCoordinates(handles, stagePosition, stageCoordinates);
    if any(modified)
      positionCoordinates = ConvertStages2PositionCoordinates(handles, stagePosition, stageCoordinates);
      
      handles.preferences.current.CurrentCoordinates.x = positionCoordinates(1);
      handles.preferences.current.CurrentCoordinates.y = positionCoordinates(2);
      handles.preferences.current.CurrentCoordinates.z = positionCoordinates(3);
    end
  end
  
  handles.stageController.MoveAxis(relativeAxis, stageCoordinates(axis));
end


function MoveStageToSliderPosition(axis, slider, handles)
% Moves the provided axis to the position specified by the slider control
  relativePosition = ConvertSlider2Position(slider, handles.positionRanges(axis,:));
  
  MoveStageToRelativePosition(handles, axis, relativePosition);
end


function returnToSampleLoadingPosition = PerformCrashPrevention(handles)
% Perform the crash prevention routine
  % Note that the axis mappings for the profiling are:
  %   x -> Y stage
  %   y -> Z stage
  horizontalStage = handles.settings.current.StageController.yAxisID;
  verticalStage = handles.settings.current.StageController.zAxisID;
  
  % Reset the stage limits
  softVerticalLimits = handles.settings.current.SoftStageBoundaries.z;
  handles.stageController.SetLimits(handles.settings.current.StageController.zAxisID, softVerticalLimits); 
  handles.settings.cache.isHeatedStage = false;
  additionalOffset = 0.0;
  
  % Set the crash prevention parameters
  scanWidth = handles.settings.current.CrashPrevention.scanWidth;
  startX = handles.settings.current.CrashPrevention.scanStart;
  endX = startX - scanWidth;
  centerX = (startX + endX) / 2;
  endY = softVerticalLimits(1);
  startY = softVerticalLimits(2);
  stageHeightAtHighestTracePoint = softVerticalLimits(2);
  
  % Open the window to track the progress
  profileHandle = CrashPrevention('Settings', handles.settings, 'Preferences', handles.preferences);
  
  % Move the stage to the start position, then SLOOOOW down for the scan
  handles.stageController.MoveAxis(verticalStage, handles.settings.current.SafeTraverseHeight.z, true);
  handles.stageController.MoveAxis(horizontalStage, startX, true);
  handles.stageController.MoveAxis(verticalStage, startY, true);
  handles.stageController.UseSuperSlowSpeed([horizontalStage, verticalStage]);
  
  % Start the stan
  done = false;
  returnToSampleLoadingPosition = false;
  inflectionPoints = 0;
  handles.settings.cache.regularStageVerification = 0;
  handles.settings.cache.heatedStageVerification = 0;
  isBlocked = PerformCrashPrevention_IsLocationBlocked(handles);
  oldIsBlocked = ~isBlocked;
  handles.stageController.MoveAxis(horizontalStage, endX);
  direction = horizontalStage;
  while ~done
    % Is the beam broken?
    isBlocked = PerformCrashPrevention_IsLocationBlocked(handles);
    currentPositions = handles.stageController.GetCurrentCoordinates([horizontalStage, verticalStage]);
    x = currentPositions(1);
    y = currentPositions(2);
    returnToSampleLoadingPosition = CrashPrevention('Update', profileHandle, x - centerX, y, isBlocked == oldIsBlocked);
    oldIsBlocked = isBlocked;
    
    if returnToSampleLoadingPosition
      % Stop all motion if the user has cancelled the operation
      handles.stageController.StopMotion([horizontalStage, verticalStage]);
    else
      if isBlocked
        if direction == verticalStage
          % We are still moving up, update the maximum height (note that the
          % directions are reversed, i.e. a lower 'y' value corresponds to a
          % taller sample height)
          stageHeightAtHighestTracePoint = y;
        else
          % We are moving horizontally and have found an edge
          handles.stageController.StopMotion(horizontalStage);
          inflectionPoints = inflectionPoints + 1;
          fprintf('Horizontal inflection point at: (%f, %f)\n', x, y);

          % Check to see if this is a stage edge
          if inflectionPoints == 1
            if abs(x - handles.settings.current.CrashPrevention.regularStageEdgeH) < handles.settings.current.CrashPrevention.tolerance
              handles.settings.cache.regularStageVerification = 1;
              fprintf('Regular stage detected! (1/2)\n');
            elseif abs(x - handles.settings.current.CrashPrevention.heatedStageEdgeH) < handles.settings.current.CrashPrevention.tolerance
              % Handle other cases here as they may arise
              handles.settings.cache.heatedStageVerification = 1;
              fprintf('Heated stage detected! (1/2)\n');
            else
              message = 'Unknown stage type detected. Please verify that the stage is seated properly.\nNow exiting the crash prevention scan and returning to the Sample Loading Position.';
              uiwait(errordlg(message, 'Stage Configuration Error', 'modal'));
              returnToSampleLoadingPosition = true;
            end
          end

          % Start moving in the vertical direction
          handles.stageController.MoveAxis(verticalStage, endY);
          direction = verticalStage;
        end
      else % isBlocked == false
        if direction == verticalStage
          % We are moving vertically and have found an edge
          stageHeightAtHighestTracePoint = y;
          handles.stageController.StopMotion(verticalStage);
          inflectionPoints = inflectionPoints + 1;
          fprintf('Vertical inflection point at: (%f, %f)\n', x, y);
          
          % Check to see if this is a stage edge
          if inflectionPoints == 2
            if abs(y - handles.settings.current.CrashPrevention.regularStageEdgeV) < handles.settings.current.CrashPrevention.tolerance
              handles.settings.cache.regularStageVerification = 2;
              fprintf('Regular stage detected! (2/2)\n');
            elseif abs(y - handles.settings.current.CrashPrevention.heatedStageEdgeV) < handles.settings.current.CrashPrevention.tolerance
              % Handle other cases here as they may arise
              handles.settings.cache.heatedStageVerification = 2;
              fprintf('Heated stage detected! (2/2)\n');
            else
              message = 'Unknown stage type detected. Please verify that the stage is seated properly.\nNow exiting the crash prevention scan and returning to the Sample Loading Position.';
              uiwait(errordlg(message, 'Stage Configuration Error', 'modal'));
              returnToSampleLoadingPosition = true;
            end
          end

          % Start moving in the horizontal direction
          handles.stageController.MoveAxis(horizontalStage, endX);
          direction = horizontalStage;
        else
          % Traveling in the horizontal direction, nothing to do
        end
      end
    end
    
    % Check to see if we've scanned the breadth of the stage
    done = handles.stageController.IsMotionDone([horizontalStage, verticalStage]) || returnToSampleLoadingPosition;
  end
  
  % The value we've been seeking
  handles.settings.cache.sampleTop = stageHeightAtHighestTracePoint;
  
  % Close the scan window
  CrashPrevention('Close', profileHandle);
  
  % Verify the crash prevention findings
  if handles.settings.cache.regularStageVerification > 0 && handles.settings.cache.heatedStageVerification > 0
    % Somehow both stage types were triggered. This is an ambiguous
    % situation, so return to the sample loading position.
    message = 'Unknown stage type detected. Please verify that the stage is seated properly.\nNow exiting the crash prevention scan and returning to the Sample Loading Position.';
    uiwait(errordlg(message, 'Stage Configuration Error', 'modal'));
    returnToSampleLoadingPosition = true;
  elseif handles.settings.cache.regularStageVerification == 2
    % Just in case
    handles.settings.cache.isHeatedStage = false;
    % No further vertical offsets required
    additionalOffset = 0.0;
  elseif handles.settings.cache.heatedStageVerification == 2
    if abs(stageHeightAtHighestTracePoint - handles.settings.current.CrashPrevention.heatedStageTop) > handles.settings.current.CrashPrevention.tolerance
      message = sprintf('There appears to be a problem with the heated stage. The top was expected to be at %f mm, but was actually at %f mm.\nNow exiting the crash prevention scan and returning to the Sample Loading Position.', handles.settings.current.CrashPrevention.heatedStageTop, stageHeightAtHighestTracePoint);
      uiwait(errordlg(message, 'Heated Stage Configuration Error', 'modal'));
      returnToSampleLoadingPosition = true;
    else
      handles.settings.cache.isHeatedStage = true;
      % Allow the heated stage to move up so that the microscope objective
      % can be inside of the sample basket a small distance
      additionalOffset = handles.settings.current.CrashPrevention.heatedStageBasketDepth;
      
      % Ensure the current coordinates are valid for the heated stage
      stagePosition = handles.CameraPosition;
      positionCoordinates = [handles.preferences.current.CurrentCoordinates.x,...
                             handles.preferences.current.CurrentCoordinates.y,...
                             handles.preferences.current.CurrentCoordinates.z];
      stageCoordinates = ConvertPositions2StageCoordinates(handles, stagePosition, positionCoordinates);
      if ~IsInStageBounds(handles, stagePosition, stageCoordinates)
        handles.preferences.current.CurrentCoordinates.x = 0.0;
        handles.preferences.current.CurrentCoordinates.y = 0.0;
%         [stageCoordinates, modified] = GetClosestInBoundStageCoordinates(handles, stagePosition, stageCoordinates);
%         positionCoordinates = ConvertStages2PositionCoordinates(handles, stagePosition, stageCoordinates);
%         if modified(1)
%           handles.preferences.current.CurrentCoordinates.x = 0;
%         end
%         if modified(2)
%           handles.preferences.current.CurrentCoordinates.y = 0);
%         end
      end
    end
  end
  
  % Update the soft limits on the stage controller
  minPossible = min([handles.settings.current.CrashPrevention.slotOffsetToWide, ...
                     handles.settings.current.CrashPrevention.slotOffsetToWide + handles.settings.current.CrashPrevention.wideOffsetToScan]);
  softVerticalLimits(2) = stageHeightAtHighestTracePoint ... The lowest value that the stage had to be at to clear the beam
                           + additionalOffset ... Compensate for stage differences
                           - (minPossible ... The vertical distance between the slot detector beam and the highest working distance
                              - handles.settings.current.CrashPrevention.wiggleRoom); % Some space to breath
  if softVerticalLimits(2) > handles.settings.current.SoftStageBoundaries.z(2)
    softVerticalLimits(2) = handles.settings.current.SoftStageBoundaries.z(2);
  end
  handles.stageController.SetLimits(handles.settings.current.StageController.zAxisID, softVerticalLimits);
  
  % Adjust the current coordinate height so that the working distances will
  % be in focus at the highest sample point
  handles.preferences.current.CurrentCoordinates.z = 0.0;
  
  % Reset the speed
  handles.stageController.UseFastSpeed();
end


function isBlocked = PerformCrashPrevention_IsLocationBlocked(handles)
% Determines if a point is blocking the slot detector beam
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
      warning('GUI:InvalidEntry', '''%g'' is below the accepted stage range. Setting to ''%g''', value, boundaries(1));
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


function UpdateSlider2Edit(slider, edit, handles, axis)
% Updates the values of the edit boxes according to the values entered in
% the sliders.
  value = ConvertSlider2Position(slider, handles.positionRanges(axis,:));
  set(edit, 'String', sprintf('%g', value));
end

function handles = SwitchCamera(handles) 
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
    % Return if we are already using this camera feed, nothing to do
    if newCamera == handles.currentCameraFeed
      return;
    end
    
    closepreview(handles.currentCameraFeed);
  end
  retry = 3;
  while retry > 0
    try
      preview(newCamera, handles.CameraView);
      axis image; % Preserve the aspect ratio
      handles.currentCameraFeed = newCamera;
      
      retry = -100;
    catch
      retry = retry - 1;
    end
  end
  
  if retry == 0
    uiwait(errordlg(['Unable to start camera feed after 3 attempts.' ...
                     'Please check to ensure everything is connected properly'], ...
                    'modal'));
  end
end


function handles = UpdateBounds(handles)
% Update the bounds
  verticalBounds = GetDynamicVerticalPositionBounds(handles, handles.StagePosition);
  handles.positionRanges(3,:) = verticalBounds;
  fuzz = 1e-4;
  
  if handles.settings.cache.isHeatedStage
    % Get the dynamic range of the heated stage based on the current
    % horizontal and vertical positions
    x = handles.preferences.current.CurrentCoordinates.x;
    y = handles.preferences.current.CurrentCoordinates.y;
    r = sqrt(x*x + y*y);
    R = handles.settings.current.CrashPrevention.heatedStageInnerRadius;
    
    xRange = R;
    yRange = R;
    if r > fuzz % If r is away from the origin...
      if R - abs(x) < fuzz % We are on the x axis near the edge of the disc
        yRange = 0.0;
      else % Somewhere in the middle of the disc, adjust the y range
        yRange = sqrt(R*R - x*x);
      end
      if R - abs(y) < fuzz % We are on the y axis near the edge of the disc
        xRange = 0.0;
      else % Somewhere in the middle of the disc, adjust the x range
        xRange = sqrt(R*R - y*y);
      end
    end
    
    handles.positionRanges(1,:) = [-xRange, xRange];
    handles.positionRanges(2,:) = [-yRange, yRange];
  end
end


function handles = ReadCurrentPositionAndUpdateControls(handles)
% Update the values of the edit boxes with the current values from the
% stages themselves
  [stagePosition, x, y, z] = DetermineStagePositionAndPositionCoordinates(handles);
  handles.StagePosition = stagePosition;
  if ~isempty(handles.StagePosition)
    UpdateControls(handles, [x, y, z]);
  end
end


function UpdateControls(handles, positionCoordinates)
% Update the values on the control to the provided positionCoordinates
  set(handles.XEdit, 'String', num2str(positionCoordinates(1)));
  set(handles.YEdit, 'String', num2str(positionCoordinates(2)));
  set(handles.ZEdit, 'String', num2str(positionCoordinates(3)));

  UpdateEdit2Slider(handles.XEdit, handles.XSlider, handles.positionRanges(1,:));
  UpdateEdit2Slider(handles.YEdit, handles.YSlider, handles.positionRanges(2,:));
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


function UpdateFocusPosition(handles, focusPosition) %#ok<DEFNU>
% Update the position of the Z Axis based on the best focus position
  set(handles.ZEdit, 'String', num2str(focusPosition));
  UpdateEdit2Slider(handles.ZEdit, handles.ZSlider, handles.positionRanges(3,:));
end


function handles = UpdateListeners(handles)
% Updates the listeners for the sliders
  if isfield(handles, 'Listeners')
    delete(handles.Listeners.XSlider);
    delete(handles.Listeners.YSlider);
    delete(handles.Listeners.ZSlider);
  end
  
  handles.Listeners.XSlider = addlistener(handles.XSlider, 'Value', 'PreSet',...
    @(~, ~) UpdateSlider2Edit(handles.XSlider, handles.XEdit, handles, 1));
  handles.Listeners.YSlider = addlistener(handles.YSlider, 'Value', 'PreSet',...
    @(~, ~) UpdateSlider2Edit(handles.YSlider, handles.YEdit, handles, 2));
  handles.Listeners.ZSlider = addlistener(handles.ZSlider, 'Value', 'PreSet',...
    @(~, ~) UpdateSlider2Edit(handles.ZSlider, handles.ZEdit, handles, 3));
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

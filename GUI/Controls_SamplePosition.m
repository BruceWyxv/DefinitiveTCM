function varargout = Controls_SamplePosition(varargin)
%CONTROLS_SAMPLEPOSITION M-file for Controls_SamplePosition.fig
%      CONTROLS_SAMPLEPOSITION, by itself, creates a new CONTROLS_SAMPLEPOSITION or raises the existing
%      singleton*.
%
%      H = CONTROLS_SAMPLEPOSITION returns the handle to a new CONTROLS_SAMPLEPOSITION or the handle to
%      the existing singleton*.
%
%      CONTROLS_SAMPLEPOSITION('Property','Value',...) creates a new CONTROLS_SAMPLEPOSITION using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to Controls_SamplePosition_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      CONTROLS_SAMPLEPOSITION('CALLBACK') and CONTROLS_SAMPLEPOSITION('CALLBACK',hObject,...) call the
%      local function named CALLBACK in CONTROLS_SAMPLEPOSITION.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Controls_SamplePosition

% Last Modified by GUIDE v2.5 15-Mar-2016 13:00:01

  % Begin initialization code - DO NOT EDIT
  gui_Singleton = 1;
  gui_State = struct('gui_Name',       mfilename, ...
                     'gui_Singleton',  gui_Singleton, ...
                     'gui_OpeningFcn', @Controls_SamplePosition_OpeningFcn, ...
                     'gui_OutputFcn',  @Controls_SamplePosition_OutputFcn, ...
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


function Controls_SamplePosition_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<INUSD>
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)
end


function varargout = Controls_SamplePosition_OutputFcn(hObject, eventdata, handles) %#ok<*INUSL>
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
function CameraSelectionGroup_SelectionChangedFcn(hObject, eventdata, handles) %#ok<DEFNU>
% hObject    handle to the selected object in CameraSelectionGroup 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  handles = UpdateCameraSelectionGroup(handles, eventdata);
  guidata(hObject, handles);
end


function LinkStageToCameraCheckbox_Callback(hObject, eventdata, handles) %#ok<DEFNU>
% hObject    handle to LinkStageToCameraCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

  % Hint: get(hObject,'Value') returns toggle state of LinkStageToCameraCheckbox
  handles = UpdateLinkCheckbox(handles);
  guidata(hObject, handles);
end


function MoveStageToCameraButton_Callback(hObject, eventdata, handles) %#ok<DEFNU>
% hObject    handle to MoveStageToCameraButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  handles = Controls('MoveStageToCamera', handles);
  handles = UpdateLinkCheckbox(handles);
  guidata(hObject, handles);
end


% --------------------------------------------------------------------
% --------------------------------------------------------------------
% --------------------------------------------------------------------
function CleanUpForClose(handles) %#ok<INUSD,DEFNU>
end


function handles = InitializeChildren(handles) %#ok<DEFNU>
% Initializes the states of any child controls, called by the main
% ControlsGUI
  % Set the stage <-> camera link checkbox from the stored preference value
  set(handles.LinkStageToCameraCheckbox, 'Value', handles.preferences.PositionSample.linkStageToCamera);

  % Default the camera position to the Sample Loading position
  handles.CameraPosition = 'SampleLoading';
  
  % Initialize the position controls
  if isempty(handles.StagePosition);
    % The stage is in an invalid state, deselect all positions radio
    % buttons
    set(findall(handles.CameraSelectionGroup, '-property', 'Value'), 'Value', 0);
  else
    % We are linked, so use the stage position
    handles.CameraPosition = handles.StagePosition;
    switch handles.CameraPosition
      case 'SampleLoading'
        set(handles.SampleLoadPositionRadio, 'Value', 1);
        
      case 'WideImage'
        set(handles.WideImagePositionRadio, 'Value', 1);
        
      case 'ScanningObjective'
        set(handles.ScanObjectivePositionRadio, 'Value', 1);
    end
  end
  
  % Update the system
  handles = UpdateCameraSelectionGroup(handles);
end


function handles = UpdateCameraSelectionGroup(handles, data)
% Processes all the commands associated with the camera selection group
  % Check to see if the camera view needs to change
  if nargin == 2
    if ischar(data)
      handles.CameraPosition = data;
    else
      % Select the camera
      switch get(data.NewValue, 'Tag');
        case 'SampleLoadPositionRadio'
          handles.CameraPosition = 'SampleLoading';

        case 'WideImagePositionRadio'
          handles.CameraPosition = 'WideImage';

        case 'ScanObjectivePositionRadio'
          handles.CameraPosition = 'ScanningObjective';
      end
    end
  end
  
  handles = Controls('SwitchCamera', handles);
  
  % Check if we need to reposition the stage
  if get(handles.LinkStageToCameraCheckbox, 'Value') == 1 && ~strcmp(handles.CameraPosition, handles.StagePosition)
    % The stage position and camera view are different, and the stage
    % position is linked to the camera view, so move the stage
    handles = Controls('MoveStageToCamera', handles);
  end
  
  % Set the link checkbox to a valid state
  handles = UpdateLinkCheckbox(handles);
end


function handles = UpdateLinkCheckbox(handles)
% Update GUI based on the state of the LinkStageToCamera checkbox
  value = get(handles.LinkStageToCameraCheckbox, 'Value');
  if value == 1
    state = 'off';
  else
    state = 'on';
  end
  set(handles.MoveStageToCameraButton, 'Enable', state);
  
  % Check if the stage can be linked to the camera
  if strcmp(handles.CameraPosition, handles.StagePosition)
    % The stage position and camera view are at the same location, ensure
    % that the link checkbox is enabled
    set(handles.LinkStageToCameraCheckbox, 'Enable', 'on');
  else
    % The stage position and camera view are at different locations, so
    % disable the link ability
    set(handles.LinkStageToCameraCheckbox, 'Enable', 'off');
  end
  
  % Update the preferences
  handles.preferences.PositionSample.linkStageToCamera = value;
end

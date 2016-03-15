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


function Controls_SamplePosition_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

  % Choose default command line output for Controls_SamplePosition
  handles.output = hObject;

  % Update handles structure
  guidata(hObject, handles);
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
  handles = UpdateCameraSelectionGroup(eventdata, handles);
  guidata(hObject, handles);
end


function LinkStageToCameraCheckbox_Callback(hObject, eventdata, handles) %#ok<DEFNU>
% hObject    handle to LinkStageToCameraCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

  % Hint: get(hObject,'Value') returns toggle state of LinkStageToCameraCheckbox
  UpdateCameraSelectionGroup(handles);
end


function MoveStageToCameraButton_Callback(hObject, eventdata, handles) %#ok<DEFNU>
% hObject    handle to MoveStageToCameraButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  handles = MoveStageToCamera(handles);
  guidata(hObject, handles);
end


% --------------------------------------------------------------------
% --------------------------------------------------------------------
% --------------------------------------------------------------------
function handles = MoveStageToCamera(handles)
  % First, open a modal progress bar while we are moving the stage. We
  % don't want the user to be able to change anything until the stage
  % movement is complete. Also, disable the close functionality (a user
  % should not be able to prematurely close the window while the process is
  % still completing.
  
  % Get the current stage positions
  current = [str2double(get(handles.XEdit, 'String')) ...
             str2double(get(handles.YEdit, 'String')) ...
             str2double(get(handles.ZEdit, 'String'))];
  % Get the new origin and calculate the new position
  cameraOrigin = GetOrigin(handles.CameraPosition, handles.settings.PositionLocations);
  new = current + cameraOrigin;
  % Move the axis, showing a progress bar
  handles.stageController.MoveAxis(handles.settings.xAxisID, new(1), true);
  handles.stageController.MoveAxis(handles.settings.yAxisID, new(2), true);
  handles.stageController.MoveAxis(handles.settings.zAxisID, new(3), true);

  % The stage should now be in the camera's field-of-view
  handles.StagePosition = handles.CameraPosition;
end


function handles = UpdateCameraSelectionGroup(handles, eventdata)
% Processes all the commands associated with the camera selection group
  % Check to see if a radio button selection triggered the event. If so,
  % then select the camera to show in the viewer
  if nargin == 2
    % Select the camera
    switch get(eventdata.NewValue, 'Tag')
      case 'SampleLoadPositionRadio'
        handles.CameraPosition = 'SampleLoading';

      case 'WideImagePositionRadio'
        handles.CameraPosition = 'WideImage';

      case 'ScanObjectivePositionRadio'
        handles.CameraPosition = 'ScanningObjective';
    end
    
    % Check to see if we need to reposition the stage
    if get(handles.MoveStageToCameraButton, 'Value') == 1 && ~strcmp(handles.CameraPosition, 'SampleLoading') && ~strcmp(handles.CameraPosition, handles.StagePosition)
      handles = MoveStageToCamera(handles);
    end
  else
    % The checkbox state was changed
    if get(handles.LinkStageToCameraCheckbox, 'Value') == 1
      state = 'off';
    else
      state = 'on';
    end
    set(handles.MoveStageToCameraButton, 'Enable', state);
  end
end

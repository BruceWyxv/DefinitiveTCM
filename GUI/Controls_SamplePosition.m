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


% --- Executes just before Controls_SamplePosition is made visible.
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


% --- Outputs from this function are returned to the command line.
function varargout = Controls_SamplePosition_OutputFcn(hObject, eventdata, handles)
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
end


% --- Executes on button press in LinkStageToCamera.
function LinkStageToCamera_Callback(hObject, eventdata, handles)
% hObject    handle to LinkStageToCamera (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

  % Hint: get(hObject,'Value') returns toggle state of LinkStageToCamera
end


% --- Executes on button press in MoveStageToCamera.
function MoveStageToCamera_Callback(hObject, eventdata, handles)
% hObject    handle to MoveStageToCamera (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end


% --- Executes when selected object is changed in StageOptionsGroup.
function StageOptionsGroup_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in StageOptionsGroup 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end


% --- Executes on button press in LinkStageToCameraCheckbox.
function LinkStageToCameraCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to LinkStageToCameraCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

  % Hint: get(hObject,'Value') returns toggle state of LinkStageToCameraCheckbox
end


% --- Executes on button press in MoveStageToCameraButton.
function MoveStageToCameraButton_Callback(hObject, eventdata, handles)
% hObject    handle to MoveStageToCameraButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end

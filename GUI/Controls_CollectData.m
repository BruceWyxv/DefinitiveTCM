function varargout = Controls_CollectData(varargin)
%CONTROLS_COLLECTDATA M-file for Controls_CollectData.fig
%      CONTROLS_COLLECTDATA, by itself, creates a new CONTROLS_COLLECTDATA or raises the existing
%      singleton*.
%
%      H = CONTROLS_COLLECTDATA returns the handle to a new CONTROLS_COLLECTDATA or the handle to
%      the existing singleton*.
%
%      CONTROLS_COLLECTDATA('Property','Value',...) creates a new CONTROLS_COLLECTDATA using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to Controls_CollectData_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      CONTROLS_COLLECTDATA('CALLBACK') and CONTROLS_COLLECTDATA('CALLBACK',hObject,...) call the
%      local function named CALLBACK in CONTROLS_COLLECTDATA.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Controls_CollectData

% Last Modified by GUIDE v2.5 22-Mar-2016 13:56:16

  % Begin initialization code - DO NOT EDIT
  gui_Singleton = 1;
  gui_State = struct('gui_Name',       mfilename, ...
                     'gui_Singleton',  gui_Singleton, ...
                     'gui_OpeningFcn', @Controls_CollectData_OpeningFcn, ...
                     'gui_OutputFcn',  @Controls_CollectData_OutputFcn, ...
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


function Controls_CollectData_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<INUSD>
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)
end


function varargout = Controls_CollectData_OutputFcn(hObject, eventdata, handles) %#ok<INUSL>
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
function AdvancedSettingsButton_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to AdvancedSettingsButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  settingsWindow = Controls_CollectData_Settings('Settings', handles.settings);
  uiwait(settingsWindow);
end


% --- Executes on button press in ProbeLaserButton.
function ProbeLaserButton_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to ProbeLaserButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  handles = ToggleProbeLaser(handles);
  guidata(hObject, handles);
end


% --- Executes on button press in PumpLaserButton.
function PumpLaserButton_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to PumpLaserButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  handles = TogglePumpLaser(handles);
  guidata(hObject, handles);
end


function RunScanButton_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to RunScanButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  % Disable all the controls
  Controls('SetControlState', handles, 'off');
  success = false;
  
  % Get the information for the data collection
  savePath = CheckPath(handles);
  sampleInfo = SampleInfoArray2Linear(handles.sampleInfo);
  
  try
    % Create the run window
    run = Run('LaserScanController', handles.laserScanController,...
              'LockInAmpController', handles.lockInAmpController,...
              'MainWindow', handles.mainWindow,...
              'Preferences', handles.preferences,...
              'PumpLaserController', handles.pumpLaserController,...
              'Settings', handles.settings,...
              'StageController', handles.stageController);

    try
      % Run a centering scan if the user has not requested to skip it
      centered = (handles.settings.current.DataScan.skipCenterScan == 1);
      goodToGo = true;
      while ~centered && goodToGo
        [centered, goodToGo] = Run('Center', guidata(run));
      end
      
      % Run a focusing scan if the user has not requested to skip it
      focused = (handles.settings.current.DataScan.skipFocusScan == 1);
      while ~focused && goodToGo
        [focused, goodToGo, relativeFocusPosition] = Run('Focus', guidata(run));
        
        % Update the controls panel with the new Z-axis position
        if focused && goodToGo
          Controls('UpdateFocusPosition', handles, relativeFocusPosition);
        end
      end

      % Perform the measurements
      if centered && focused && goodToGo
        [data, success] = Run('Data', guidata(run));

        if success
          % Save the data
          data.sampleInfo = sampleInfo;
          data.sampleName = handles.sampleName;
          data.savepath = savePath;
          save(savePath, '-struct', 'data');
          CheckPath(handles); % Update the file name state

          % Update the preferences (only when successfully collected)
          handles.preferences.current.CollectData.savePath = savePath;
          handles.preferences.current.CollectData.sampleInfo = sampleInfo;
          guidata(hObject,handles);
        end
      end
    catch myError
      disp(getReport(myError));
    end
    
    if isvalid(run)
      Run('Finalize', run, guidata(run), success, true);
    end
  catch myError
    disp(getReport(myError));
  end
  
  % Enable all the controls
  Controls('SetControlState', handles, 'on');
end


function SampleNameEdit_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to SampleNameEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SampleNameEdit as text
%        str2double(get(hObject,'String')) returns contents of SampleNameEdit as a double
  handles.sampleName = get(hObject,'String');
  guidata(hObject,handles);
  
  CheckPath(handles);
end


function SampleNameEdit_CreateFcn(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to SampleNameEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

  % Hint: edit controls usually have a white background on Windows.
  %       See ISPC and COMPUTER.
  if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
  end
end


function SaveFolderEdit_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to SaveFolderEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SaveFolderEdit as text
%        str2double(get(hObject,'String')) returns contents of SaveFolderEdit as a double
  handles.saveFolder = get(hObject, 'String');
  guidata(hObject,handles);
  
  CheckPath(handles);
end


function SaveFolderEdit_CreateFcn(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to SaveFolderEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

  % Hint: edit controls usually have a white background on Windows.
  %       See ISPC and COMPUTER.
  if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
  end
end


function SaveFolderBrowseButton_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to SaveFolderBrowseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  saveFolder = uigetdir(handles.saveFolder, 'TCM Save Directory:');
  
  if saveFolder ~= 0
    handles.saveFolder = saveFolder;
    set(handles.SaveFolderEdit, 'String', handles.saveFolder);
  
    CheckPath(handles);

    guidata(hObject,handles);
  end
end


function SampleInfoButton_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to SampleInfoButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  sampleInfo = inputdlg({'Enter sample details:'}, 'Sample Information', 8, {handles.sampleInfo});
  if ~isempty(sampleInfo)
    handles.sampleInfo = sampleInfo{1};
  end
  
  guidata(hObject,handles);
end


% --------------------------------------------------------------------
% --------------------------------------------------------------------
% --------------------------------------------------------------------
function [fullPath, folderExists, fileExists] = CheckPath(handles)
% Checks the current path of the save file. If there is an error then the
% appropriate edit box is given a light red background. Otherwise the edit
% boxes are set to a white background.
  fullPath = fullfile(handles.saveFolder, strcat(handles.sampleName, '.mat'));
  
  folderExists = false;
  fileExists = false;
  if exist(handles.saveFolder, 'dir') ~= 7
    % The folder does not exist, change the background color of the
    % SaveFolder edit box to indicate an error
    set(handles.SaveFolderEdit, 'BackgroundColor', [1, 0.4, 0.4]);
    set(handles.SampleNameEdit, 'BackgroundColor', [0.7, 0.7, 0.7]);
    set(handles.SaveFolderEdit, 'TooltipString', 'Save folder does not exist!');
    set(handles.SampleNameEdit, 'TooltipString', 'Save folder does not exist!');
  else
    % All clear
    set(handles.SaveFolderEdit, 'BackgroundColor', 'white');
    set(handles.SaveFolderEdit, 'TooltipString', handles.tooltips.saveFolderEdit);
    set(handles.SampleNameEdit, 'TooltipString', handles.tooltips.sampleNameEdit);
    folderExists = true;
    
    if exist(fullPath, 'file')
      % The file already exists, change the background color of the
      % SampleName edit box to indicate a warning
      set(handles.SampleNameEdit, 'BackgroundColor', [1, 1, 0.1]);
      set(handles.SampleNameEdit, 'TooltipString', 'The file already exists! The data will be overwritten unless you change the save folder or save name.');
    else
      % All clear
      set(handles.SampleNameEdit, 'BackgroundColor', 'white');
      set(handles.SampleNameEdit, 'TooltipString', handles.tooltips.sampleNameEdit);
      fileExists = true;
    end
  end
end


function CleanUpForClose(handles) %#ok<INUSD,DEFNU>
% Do not turn off lasers automatically - we want them to be warm, even if
% the user exits the CollectData dialog
end


function handles = InitializeChildren(handles) %#ok<DEFNU>
% Initializes the states of any child controls, called by the main
% ControlsGUI
  % Record the default tooltips for any windows that may have dynamic
  % tooltips
  handles.tooltips.saveFolderEdit = get(handles.SaveFolderEdit, 'TooltipString');
  handles.tooltips.sampleNameEdit = get(handles.SampleNameEdit, 'TooltipString');
  
  % Sets the values of the save path and sample name
  if ~isempty(handles.preferences.current.CollectData.savePath)
    [handles.saveFolder, handles.sampleName, ~] = fileparts(handles.preferences.current.CollectData.savePath);
  else
    handles.saveFolder = system_dependent('getuserworkfolder');
    handles.sampleName = 'Sample1';
  end
  set(handles.SaveFolderEdit, 'String', handles.saveFolder);
  set(handles.SampleNameEdit, 'String', handles.sampleName);
  CheckPath(handles);
  
  % Load the previously recorded sample info
  if ~isfield(handles, 'sampleInfo')
    handles.sampleInfo = SampleInfoLinear2Array(handles.preferences.current.CollectData.sampleInfo);
  end
  
  % Get the laser states
  if ~isa(handles.probeLaserController, 'ProbeLaser_Control')
    error('Invalid handle for probe laser controller!');
  end
  if ~isa(handles.pumpLaserController, 'DS345_Control')
    error('Invalid handle for pump laser controller!');
  end
  handles.probeLaserPower = handles.probeLaserController.isOn;
  handles.pumpLaserPower = handles.pumpLaserController.isOn;
  
  % Create the LED controls
  handles.ProbeLaserOffLED = ImageToggle(handles.ProbeLaserOffLED, handles.settings.current.LEDImages.redOn, handles.settings.current.LEDImages.redOff);
  handles.ProbeLaserOnLED = ImageToggle(handles.ProbeLaserOnLED, handles.settings.current.LEDImages.greenOn, handles.settings.current.LEDImages.greenOff);
  handles.PumpLaserOffLED = ImageToggle(handles.PumpLaserOffLED, handles.settings.current.LEDImages.redOn, handles.settings.current.LEDImages.redOff);
  handles.PumpLaserOnLED = ImageToggle(handles.PumpLaserOnLED, handles.settings.current.LEDImages.greenOn, handles.settings.current.LEDImages.greenOff);
  ToggleProbeLaser(handles, handles.probeLaserPower);
  TogglePumpLaser(handles, handles.pumpLaserPower);
  
  % Move the stage and camera to the scanning position; this is performed
  % last since it takes the longest and we want the GUI window to show the
  % inital state correctly
  handles.CameraPosition = 'ScanningObjective';
  handles = Controls('SwitchCamera', handles);
  handles = Controls('MoveStageToCamera', handles);
end


function linear = SampleInfoArray2Linear(array)
% Convert a cell array into a linear string with literal newline characters
  linear = '';
  for i = 1:size(array, 1)
    trimmed = strtrim(array(i,:));
    if i > 1
      linear = strcat(linear, '\n', trimmed);
    else
      linear = trimmed;
    end
  end
end


function array = SampleInfoLinear2Array(linear)
% Convert a string with literal newline characters into a cell array
  array = char(strtrim(strsplit(linear, {'\\n'})));
end


function SetControlState(handles, state) %#ok<DEFNU>
% Disables all controls on this window
  allControls = [handles.SaveFolderEdit,...
                 handles.SampleNameEdit,...
                 handles.SaveFolderBrowseButton,...
                 handles.SampleInfoButton,...
                 handles.PumpLaserButton,...
                 handles.ProbeLaserButton,...
                 handles.RunScanButton];
  set(findall(allControls, '-property', 'Enable'), 'Enable', state);
end


function handles = ToggleProbeLaser(handles, setPowerState)
% Change the power state of the probe laser
  if nargin == 2
    handles.probeLaserPower = setPowerState;
  else
    handles.probeLaserPower = ~handles.probeLaserPower;
  end
  
  if handles.probeLaserPower
    state = 'On';
    antistate = 'Off';
    handles.ProbeLaserOffLED.SetState(false);
    handles.ProbeLaserOnLED.SetState(true);
    handles.probeLaserController.TurnOn();
  else
    state = 'Off';
    antistate = 'On';
    handles.ProbeLaserOffLED.SetState(true);
    handles.ProbeLaserOnLED.SetState(false);
    handles.probeLaserController.TurnOff();
  end
  
  set(handles.ProbeLaserOffText, 'Enable', antistate);
  set(handles.ProbeLaserOnText, 'Enable', state);
  
  UpdateRun(handles);
end


function handles = TogglePumpLaser(handles, setPowerState)
% Change the power state of the probe laser
  if nargin == 2
    handles.pumpLaserPower = setPowerState;
  else
    handles.pumpLaserPower = ~handles.pumpLaserPower;
  end
  
  if handles.pumpLaserPower
    state = 'On';
    antistate = 'Off';
    handles.PumpLaserOffLED.SetState(false);
    handles.PumpLaserOnLED.SetState(true);
    handles.pumpLaserController.TurnOn();
  else
    state = 'Off';
    antistate = 'On';
    handles.PumpLaserOffLED.SetState(true);
    handles.PumpLaserOnLED.SetState(false);
    handles.pumpLaserController.TurnOff();
  end
  
  set(handles.PumpLaserOffText, 'Enable', antistate);
  set(handles.PumpLaserOnText, 'Enable', state);
  
  UpdateRun(handles);
end


function UpdateRun(handles)
% Enable/disable the "Run" button depending on the laser states
  if handles.probeLaserPower && handles.pumpLaserPower
    state = 'On';
  else
    state = 'Off';
  end
  
  set(handles.RunScanButton, 'Enable', state);
end

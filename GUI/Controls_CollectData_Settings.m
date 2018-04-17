function varargout = Controls_CollectData_Settings(varargin)
% CONTROLS_COLLECTDATA_SETTINGS MATLAB code for Controls_CollectData_Settings.fig
%      CONTROLS_COLLECTDATA_SETTINGS, by itself, creates a new CONTROLS_COLLECTDATA_SETTINGS or raises the existing
%      singleton*.
%
%      H = CONTROLS_COLLECTDATA_SETTINGS returns the handle to a new CONTROLS_COLLECTDATA_SETTINGS or the handle to
%      the existing singleton*.
%
%      CONTROLS_COLLECTDATA_SETTINGS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CONTROLS_COLLECTDATA_SETTINGS.M with the given input arguments.
%
%      CONTROLS_COLLECTDATA_SETTINGS('Property','Value',...) creates a new CONTROLS_COLLECTDATA_SETTINGS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Controls_CollectData_Settings_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Controls_CollectData_Settings_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Controls_CollectData_Settings

% Last Modified by GUIDE v2.5 16-Apr-2018 12:03:55

  % Begin initialization code - DO NOT EDIT
  gui_Singleton = 1;
  gui_State = struct('gui_Name',       mfilename, ...
                     'gui_Singleton',  gui_Singleton, ...
                     'gui_OpeningFcn', @Controls_CollectData_Settings_OpeningFcn, ...
                     'gui_OutputFcn',  @Controls_CollectData_Settings_OutputFcn, ...
                     'gui_LayoutFcn',  [] , ...
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


function Controls_CollectData_Settings_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<INUSL>
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Controls_CollectData_Settings (see VARARGIN)

  % Choose default command line output for Controls_CollectData_Settings
  handles.output = hObject;
  
  % Define the input arguments
  parser = inputParser;
  parser.addParameter('settings', '');
  parser.addParameter('interfaceController', '');
  parser.addParameter('lockInAmpController', '');
  parser.addParameter('probeLaserController', '');
  
  % Check the input arguments
  parser.KeepUnmatched = true;
  try
    parser.parse(varargin{:});
  catch me
    error('Error when trying to parse input arguments:   %s', me.message);
  end
  if ~isempty(fieldnames(parser.Unmatched))
    warning('MATLAB:unknownArgument', 'Some arguments were not recognized:');
    disp(parser.Unmatched);
  end

  % Assign additional parameters
  handles.originalSettings = parser.Results.settings;
  handles.settings = handles.originalSettings.current;
  handles.database = Database();
  
  % Get the required hardware controls
  handles.interfaceController = parser.Results.interfaceController;
  handles.lockInAmpController = parser.Results.lockInAmpController;
  handles.probeLaserController = parser.Results.probeLaserController;
  
  % Initialize the controls and handle values
  set(handles.SkipCenterScanCheckbox, 'Value', handles.settings.DataScan.skipCenterScan);
  set(handles.SkipFocusScanCheckbox, 'Value', handles.settings.DataScan.skipFocusScan);
  set(handles.ScanDirectionEdit, 'String', sprintf('%g', handles.settings.DataScan.scanDirection));
  set(handles.ScanDistanceEdit, 'String', sprintf('%g', handles.settings.DataScan.scanDistance * handles.settings.Analysis.scanScaling));
  set(handles.StepsEdit, 'String', sprintf('%i', handles.settings.DataScan.steps));
  set(handles.LaserPowerEdit, 'String', sprintf('%g', handles.settings.FunctionGenerator.power));
  set(handles.DetectorDCSignalEdit, 'String', '--');

  % Update handles structure
  guidata(hObject, handles);

  % UIWAIT makes Controls_CollectData_Settings wait for user response (see UIRESUME)
  % uiwait(handles.SettingsWindow);
end


function varargout = Controls_CollectData_Settings_OutputFcn(hObject, eventdata, handles)  %#ok<INUSL>
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

  % Get default command line output from handles structure
  varargout{1} = handles.output;
end


function DetectorDCSignalEdit_CreateFcn(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to DetectorDCSignalEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

  % Hint: edit controls usually have a white background on Windows.
  %       See ISPC and COMPUTER.
  if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
  end
end


function ScanDirectionEdit_CreateFcn(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to ScanDirectionEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

  % Hint: edit controls usually have a white background on Windows.
  %       See ISPC and COMPUTER.
  if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
  end
end


function StepsEdit_CreateFcn(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to StepsEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

  % Hint: edit controls usually have a white background on Windows.
  %       See ISPC and COMPUTER.
  if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
  end
end


function LaserPowerEdit_CreateFcn(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to LaserPowerEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

  % Hint: edit controls usually have a white background on Windows.
  %       See ISPC and COMPUTER.
  if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
  end
end


function ScanDistanceEdit_CreateFcn(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to ScanDistanceEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

  % Hint: edit controls usually have a white background on Windows.
  %       See ISPC and COMPUTER.
  if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
  end
end


% --------------------------------------------------------------------
% --------------------------------------------------------------------
% --------------------------------------------------------------------
function CancelButton_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to CancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  Close(hObject.Parent, handles, false);
end


function CollectDetectorDCSignalButton_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to CollectDetectorDCSignalButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  text = get(hObject, 'String');
  set(hObject, 'String', 'Reading...');
  set(hObject, 'Enable', 'Off');
  if handles.probeLaserController.isOn
    % Configure for reading the probe power CD signal
    handles.interfaceController.ConfigureForProbePowerDiagnostic();
    
    % Get the value and set the text in the edit box
    pause(10.0);
    value = handles.lockInAmpController.GetAuxInputValue(handles.settings.DataScan.inputChannelDCSignal);
    set(handles.DetectorDCSignalEdit, 'String', sprintf('%g', value));
    
    % Return to the data scan configuration
    handles.interfaceController.ConfigureForPositionScan();
  else
    uiwait(errordlg(...
            ['The probe laser is not on! No measurement can be taken.' ...
             '\nPlease exit the "Advanced Settings" dialog and turn ' ...
             'the probe laser on first.', 'Probe Laser Off', 'modal']));
  end
  set(hObject, 'String', text);
  set(hObject, 'Enable', 'On');
end


function OKButton_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to OKButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  Close(hObject.Parent, handles, true);
end


function LaserPowerEdit_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to LaserPowerEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

  % Hints: get(hObject,'String') returns contents of LaserPowerEdit as text
  %        str2double(get(hObject,'String')) returns contents of LaserPowerEdit as a double
  % Get the value, tha valid range is 1 to 100
  window = [1, 100];
  entry = get(hObject, 'String');
  value = sscanf(entry, '%g', 1);
  
  % Sanitize the output
  if value < window(1)
    value = window(1);
  elseif value > window(2)
    value = window(2);
  end
  
  % Set the clean value
  handles.settings.FunctionGenerator.power = value;
  clean = num2str(value);
  set(hObject, 'String', clean);
  
  % Save the update
  guidata(hObject.Parent, handles);
end


function ScanDirectionEdit_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to ScanDirectionEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  % The valid values are [0, 180)
  window = [0, 180];
  entry = get(hObject, 'String');
  value = sscanf(entry, '%g', 1);
  
  % Modify the value as needed
  if isFloatEqual(value, window(1), 1e-4) || isFloatEqual(value, window(2))
    value = 0;
  else
    while value < window(1)
      value = value + window(2);
    end
    while value > window(2)
      value = value - window(2);
    end
  end
  
  % Set the clean value
  handles.settings.DataScan.scanDirection = value;
  clean = num2str(value);
  set(hObject, 'String', clean);
  
  % Save the update
  guidata(hObject.Parent, handles);
end


function ScanDistanceEdit_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to ScanDistanceEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

  % Hints: get(hObject,'String') returns contents of ScanDistanceEdit as text
  %        str2double(get(hObject,'String')) returns contents of ScanDistanceEdit as a double
  window = [1.5 50.0];
  value = str2double(get(hObject,'String'));
  
  if value < window(1)
    value = window(1);
  elseif value > window(2)
    value = window(2);
  end
  
  % Ensure the input is sanitized
  clean = num2str(value);
  set(hObject, 'String', clean);
  
  % Convert from ?m to mm that corresponds to the scan stage movement
  handles.settings.DataScan.scanDistance = value / handles.settings.Analysis.scanScaling;
  
  % Save the update
  guidata(hObject.Parent, handles);
end


function SkipCenterScanCheckbox_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to SkipCenterScanCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  handles.settings.DataScan.skipCenterScan = get(hObject, 'Value');
  
  % Save the update
  guidata(hObject.Parent, handles);
end


function SkipFocusScanCheckbox_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to SkipFocusScanCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  handles.settings.DataScan.skipFocusScan = get(hObject, 'Value');
  
  % Save the update
  guidata(hObject.Parent, handles);
end


function StepsEdit_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to StepsEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  % The value must be an integer
  entry = get(hObject, 'String');
  value = round(sscanf(entry, '%g', 1));
  
  % Modify the value as needed, the valid range is odd numbers in [3, 99]
  if value < 3
    value = 3;
  elseif value > 99
    value = 99;
  elseif mod(value, 2) == 0
    value = value - 1;
  end
  
  % Set the clean value
  handles.settings.DataScan.steps = value;
  clean = num2str(value);
  set(hObject, 'String', clean);
  
  % Save the update
  guidata(hObject.Parent, handles);
end


% --------------------------------------------------------------------
% --------------------------------------------------------------------
% --------------------------------------------------------------------
function SettingsWindow_CloseRequestFcn(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to SettingsWindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

  % Hint: delete(hObject) closes the figure
  Close(hObject, handles, false);
end


function Close(myself, handles, saveSettings)
% Close the window, saving the settings if requested
  if saveSettings
    handles.originalSettings.current = handles.settings;
  end
  
  delete(myself);
end

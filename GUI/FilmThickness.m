function varargout = FilmThickness(varargin)
%FILMTHICKNESS M-file for FilmThickness.fig
%      FILMTHICKNESS, by itself, creates a new FILMTHICKNESS or raises the existing
%      singleton*.
%
%      H = FILMTHICKNESS returns the handle to a new FILMTHICKNESS or the handle to
%      the existing singleton*.
%
%      FILMTHICKNESS('Property','Value',...) creates a new FILMTHICKNESS using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to FilmThickness_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      FILMTHICKNESS('CALLBACK') and FILMTHICKNESS('CALLBACK',hObject,...) call the
%      local function named CALLBACK in FILMTHICKNESS.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

  % Edit the above text to modify the response to help FilmThickness

  % Last Modified by GUIDE v2.5 11-May-2017 14:38:32

  % Begin initialization code - DO NOT EDIT
  gui_Singleton = 1;
  gui_State = struct('gui_Name',       mfilename, ...
                     'gui_Singleton',  gui_Singleton, ...
                     'gui_OpeningFcn', @FilmThickness_OpeningFcn, ...
                     'gui_OutputFcn',  @FilmThickness_OutputFcn, ...
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


% --- Executes just before FilmThickness is made visible.
function FilmThickness_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<INUSL>
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

  % Choose default command line output for FilmThickness
  handles.output = hObject;
  
  % Check the input arguments
  if ~isempty(varargin)
    parser = inputParser;
    parser.addParameter('preferences', '', @(x) isa(x, 'ConfigurationFile'));
    parser.addParameter('interfaceController', '', @(x) isa(x, 'InterfaceChassis_Control'));
    parser.addParameter('lockInAmpController', '', @(x) isa(x, 'SR830_Control'));
    parser.addParameter('pumpLaserController', '', @(x) isa(x, 'DS345_Control'));
    parser.addParameter('settings', '', @(x) isa(x, 'ConfigurationFile'));
    % Parse the input arguments
    parser.KeepUnmatched = true;
    try
      parser.parse(varargin{:});
    catch me
      error('Error when trying to parse input arguments:   %s', me.message);
    end
    % Assigned values
    handles.lockInAmpController = parser.Results.lockInAmpController;
    handles.originalPreferences = parser.Results.preferences;
    handles.preferences = handles.originalPreferences.current;
    handles.interfaceController = parser.Results.interfaceController;
    handles.pumpLaserController = parser.Results.pumpLaserController;
    handles.settings = parser.Results.settings.current;
  end
  
  % Set some variables
  handles.emptyPower = -1.0;
  handles.samplePower = -1.0;
  handles.transmissivity = -1.0;
  handles.filmThickness = -1.0;
  
  % Set the window position
  movegui(hObject, handles.preferences.WindowPositions.filmThickness);
  movegui(hObject, 'onscreen');
  handles.cancel = false;
  
  % Set the interface controller to film thickness mode
  handles.pumpLaserController.TurnOn();
  handles.interfaceController.ConfigureForFilmThickness();
  handles.pumpLaserController.SetFrequency(handles.preferences.FilmThickness.laserFrequency);
  handles.pumpLaserController.SetPowerSetpoint(handles.preferences.FilmThickness.laserPower);
  
  % Initialize the frequency controls
  value = handles.preferences.FilmThickness.laserFrequency;
  valueString = Num2Engr(value);
  set(handles.LaserFrequencyEdit, 'String', valueString);
  set(handles.LaserFrequencySlider, 'Min', handles.settings.FilmThickness.laserFrequencyMin);
  set(handles.LaserFrequencySlider, 'Max', handles.settings.FilmThickness.laserFrequencyMax);
  set(handles.LaserFrequencySlider, 'Value', value);
  
  % Initialize the power controls
  value = handles.preferences.FilmThickness.laserPower;
  valueString = Num2Engr(value);
  set(handles.LaserPowerEdit, 'String', valueString);
  set(handles.LaserPowerSlider, 'Min', 0);
  set(handles.LaserPowerSlider, 'Max', 100);
  set(handles.LaserPowerSlider, 'Value', value);
  
  % Create fields for empty/sample value logic vs. laser power and
  % frequency
  handles.laserFrequencyEmpty = handles.preferences.FilmThickness.laserFrequency;
  handles.laserFrequencySample = handles.laserFrequencyEmpty;
  handles.laserPowerEmpty = handles.preferences.FilmThickness.laserPower;
  handles.laserPowerSample = handles.laserPowerEmpty;
  
  % Configure the plot
  pause(2);
  handles.maxNumberOfHistories = handles.preferences.FilmThickness.numberOfHistories;
  handles.updateFrequency = handles.preferences.FilmThickness.updateFrequency;
  handles.histories = handles.lockInAmpController.GetAmplitudeSingle();
  handles.powerHistory = plot(handles.PowerChart, handles.updateFrequency, handles.histories, 'LineStyle', 'none', 'Marker', '.');
  set(handles.PowerChart, 'YScale', 'log');
  
  % Set a timer to update the plot on a regular basis
  handles.timer = timer('TimerFcn', {@UpdatePlot, hObject, handles}, 'ExecutionMode', 'FixedRate');
  start(handles.timer);

  % Update handles structure
  guidata(hObject, handles);
end


function varargout = FilmThickness_OutputFcn(hObject, eventdata, handles) %#ok<INUSL>
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  varargout{1} = handles.output;
end


function FilmThicknessWindow_CloseRequestFcn(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to FilmThicknessWindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  % Stop the timer
  stop(handles.timer);
  delete(handles.timer);
  
  % Check to see if the user moved the window at all
  if ~handles.cancel
    currentPosition = getpixelposition(hObject);
    if currentPosition(1:2) ~= handles.preferences.WindowPositions.controls
      handles.preferences.WindowPositions.controls = currentPosition(1:2);
    end
  end
  
  handles.pumpLaserController.TurnOff();
  handles.interfaceController.ConfigureForNothing();    

  delete(hObject);
end


% --------------------------------------------------------------------
% --------------------------------------------------------------------
% --------------------------------------------------------------------
function CollectEmptyButton_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to CollectEmptyButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  % Collect 10 samples from the lock-in amplifier
  handles.emptyPower = handles.lockInAmpController.GetAmplitude(10) * 1e3;
  valueString = num2str(handles.emptyPower);
  set(handles.EmptyValueEdit, 'String', valueString);
  handles.laserFrequencyEmpty = handles.preferences.FilmThickness.laserFrequency;
  handles.laserPowerEmpty = handles.preferences.FilmThickness.laserPower;
  handles = UpdateTransmissionAndFilmThickness(handles);
  
  % Update handles structure
  guidata(hObject, handles);
end


function CollectSampleButton_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to CollectSampleButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  % Collect 10 samples from the lock-in amplifier
  handles.samplePower = handles.lockInAmpController.GetAmplitude(10) * 1e3;
  valueString = num2str(handles.samplePower);
  set(handles.SampleValueEdit, 'String', valueString);
  handles.laserFrequencySample = handles.preferences.FilmThickness.laserFrequency;
  handles.laserPowerSample = handles.preferences.FilmThickness.laserPower;
  handles = UpdateTransmissionAndFilmThickness(handles);
  
  % Update handles structure
  guidata(hObject, handles);
end


function LaserFrequencyEdit_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to LaserFrequencyEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

  % Hints: get(hObject,'String') returns contents of LaserFrequencyEdit as text
  %        str2double(get(hObject,'String')) returns contents of LaserFrequencyEdit as a double
  handles = UpdateLaserFrequency(handles, true);
  
  % Update handles structure
  guidata(hObject, handles);
end


function LaserFrequencySlider_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to LaserFrequencySlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

  % Hints: get(hObject,'Value') returns position of slider
  %        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
  handles = UpdateLaserFrequency(handles, false);
  
  % Update handles structure
  guidata(hObject, handles);
end


function LaserPowerEdit_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to LaserPowerEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of LaserPowerEdit as text
%        str2double(get(hObject,'String')) returns contents of LaserPowerEdit as a double
  handles = UpdateLaserPower(handles, true);
  
  % Update handles structure
  guidata(hObject, handles);
end


function LaserPowerSlider_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to LaserPowerSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
  handles = UpdateLaserPower(handles, false);
  
  % Update handles structure
  guidata(hObject, handles);
end


function SaveButton_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to SaveButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  % Saves the film thickness to a plain text file
  extension = 'txt';
  filters = {strcat('*.',  extension), 'Text File';...
             '*.*', 'All Files'};
  [file, directory, ~] = uiputfile(filters, 'Save Data File...');
  
  if file ~= 0
    textFile = fullfile(directory, file);
    Labels = {'Film Thickness'; 'Date'};
    Values = {get(handles.FilmThicknessEdit, 'String'); datetime()};
    data = table(Labels, Values);
    writetable(data, textFile);
  end
end


function DoneButton_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to DoneButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  if handles.filmThickness > 0
    handles.preferences.Analysis.filmThickness = handles.filmThickness;
  end
  
  % Update the preferences
  handles.originalPreferences.current = handles.preferences;
  
  close(hObject.Parent);
end


function CancelButton_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to CancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  handles.cancel = true;
  
  guidata(hObject, handles);
  close(hObject.Parent);
end


% --------------------------------------------------------------------
% --------------------------------------------------------------------
% --------------------------------------------------------------------
function handles = CheckEmptySampleValidity(handles)
% Checks to see if the recorded values are valid for the current frequency
% and power
  if handles.laserFrequencyEmpty ~= handles.preferences.FilmThickness.laserFrequency ||...
     handles.laserPowerEmpty ~= handles.preferences.FilmThickness.laserPower ||...
     handles.emptyPower < 0
    set(handles.EmptyValueEdit, 'String', '--');
  else
    valueString = num2str(handles.emptyPower);
    set(handles.EmptyValueEdit, 'String', valueString);
  end
  
  if handles.laserFrequencySample ~= handles.preferences.FilmThickness.laserFrequency ||...
     handles.laserPowerSample ~= handles.preferences.FilmThickness.laserPower ||...
     handles.samplePower < 0
    set(handles.SampleValueEdit, 'String', '--');
  else
    valueString = num2str(handles.samplePower);
    set(handles.SampleValueEdit, 'String', valueString);
  end
  
  % Update the transmissiona and film values as needed
  handles = UpdateTransmissionAndFilmThickness(handles);
end


function handles = UpdateLaserFrequency(handles, isEditControl)
% Update the slider and edit box for the laser frequency
  if isEditControl
    valueString = get(handles.LaserFrequencyEdit, 'String');
    value = str2double(valueString);
    if value < handles.settings.FilmThickness.laserFrequencyMin
      value = handles.settings.FilmThickness.laserFrequencyMin;
    elseif value > handles.settings.FilmThickness.laserFrequencyMax
      value = handles.settings.FilmThickness.laserFrequencyMax;
    end
    set(handles.LaserFrequencySlider, 'Value', value);
  else
    value = get(handles.LaserFrequencySlider, 'Value');
    valueString = Num2Engr(value);
    set(handles.LaserFrequencyEdit, 'String', valueString);
  end
  
  handles.pumpLaserController.SetFrequency(value);
  handles.preferences.FilmThickness.laserFrequency = value;
  
  handles = CheckEmptySampleValidity(handles);
end


function handles = UpdateLaserPower(handles, isEditControl)
% Update the slider and edit box for the laser power
  if isEditControl
    valueString = get(handles.LaserPowerEdit, 'String');
    value = str2double(valueString);
    if value < 0
      value = 0;
    elseif value > 100
      value = 100;
    end
    set(handles.LaserPowerSlider, 'Value', value);
  else
    value = get(handles.LaserPowerSlider, 'Value');
    valueString = Num2Engr(value);
    set(handles.LaserPowerEdit, 'String', valueString);
  end
  
  handles.pumpLaserController.SetPowerSetpoint(value);
  handles.preferences.FilmThickness.laserPower = value;
  
  handles = CheckEmptySampleValidity(handles);
end


function UpdatePlot(obj, event, hObject, handles) %#ok<INUSL>
  oldIterations = get(handles.powerHistory, 'XData');
  oldHistories = get(handles.powerHistory, 'YData');

  nextValue = handles.lockInAmpController.GetAmplitudeSingle() * 1e3;
  valueString = ['Current Value: ' Num2Engr(nextValue) ' mV'];
  title(handles.PowerChart, valueString);

  iterations = length(oldIterations);
  newIterations = [oldIterations, (iterations + 1)];
  newHistories = [oldHistories, nextValue];

  if iterations <= handles.maxNumberOfHistories
    startIteration = 1;
    endIteration = handles.maxNumberOfHistories;
  else
    endIteration = iterations;
    startIteration = endIteration - handles.maxNumberOfHistories;
  end
  set(handles.powerHistory, 'XData', newIterations, 'YData', newHistories);
  handles.PowerChart.XLim = [(startIteration - 2), (endIteration + 2)];
end

function handles = UpdateTransmissionAndFilmThickness(handles)
% Update the fields for the transmission ratio and film thickness if the
% appropriate values have been read
  if (handles.laserFrequencyEmpty == handles.preferences.FilmThickness.laserFrequency &&...
      handles.laserPowerEmpty == handles.preferences.FilmThickness.laserPower &&...
      handles.laserFrequencySample == handles.preferences.FilmThickness.laserFrequency &&...
      handles.laserPowerSample == handles.preferences.FilmThickness.laserPower &&...
      handles.emptyPower > 0 &&...
      handles.samplePower > 0)
    handles.transmissivity = handles.samplePower / handles.emptyPower;
    valueString = num2str(handles.transmissivity * 100);
    set(handles.TransmissivityEdit, 'String', valueString);

    [index, filmThicknesses] = CalculateFilmThickness(handles.transmissivity);
    valueString = num2str(filmThicknesses(index) * 1e9);
    set(handles.FilmThicknessEdit, 'String', valueString);
  else
    set(handles.TransmissivityEdit, 'String', '--');
    set(handles.FilmThicknessEdit, 'String', '--');
  end
end

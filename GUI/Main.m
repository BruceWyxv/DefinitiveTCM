function varargout = Main(varargin)
% MAIN MATLAB code for Main.fig
%      MAIN, by itself, creates a new MAIN or raises the existing
%      singleton*.
%
%      H = MAIN returns the handle to a new MAIN or the handle to
%      the existing singleton*.
%
%      MAIN('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MAIN.M with the given input arguments.
%
%      MAIN('Property','Value',...) creates a new MAIN or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Main_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Main_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Main

% Last Modified by GUIDE v2.5 27-Apr-2017 10:53:57

  % Begin initialization code - DO NOT EDIT
  gui_Singleton = 1;
  gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @Main_OpeningFcn, ...
    'gui_OutputFcn',  @Main_OutputFcn, ...
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


function Main_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<INUSL>
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Main (see VARARGIN)

% Choose default command line output for Main
  handles.output = hObject;
  
  % Common files
  handles.settingsFile = 'Resources/Settings.ini';
  handles.preferencesFile = 'Resources/Preferences.ini';
  
  % Get the settings and user preferences
  configManager = ConfigurationFileManager.GetInstance();
  handles.settings = configManager.GetConfigurationFile(handles.settingsFile);
  handles.preferences = configManager.GetConfigurationFile(handles.preferencesFile);
  
  % Set the window position
  movegui(hObject, handles.preferences.current.WindowPositions.main);
  movegui(hObject, 'onscreen');
  
  % Get the GUI add-ons
  handles.PositionSampleGUIAddOn = open('Controls_SamplePosition.fig');
  handles.CollectDataGUIAddOn = open('Controls_CollectData.fig');
  
  % Configure the power status LEDs; actually replace the control handle
  % with a handle to the controlling class
  %   TODO: Figure out how to get the LEDOff and LEDOn elements to not
  %   receive keyboard focus when tabbing to select
  handles.LEDOn = ImageToggle(handles.LEDOn, handles.settings.current.LEDImages.greenOn, handles.settings.current.LEDImages.greenOff);
  handles.LEDOff = ImageToggle(handles.LEDOff, handles.settings.current.LEDImages.redOn, handles.settings.current.LEDImages.redOff);

  % Set initial states
  handles = CascadeActionPower(handles, false);
  imshow(handles.settings.current.TCMLogo);
  
  % Create cache values
  handles.settings.cache.isHeatedStage = false;
  handles.settings.cache.sampleTop = 0.0;

  % Update handles structure
  guidata(hObject, handles);
end


function varargout = Main_OutputFcn(hObject, eventdata, handles) %#ok<INUSL>
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

  % Get default command line output from handles structure
  varargout{1} = handles.output;
end


function MainWindow_CloseRequestFcn(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to MainWindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  % Delete the invisible figures
  delete(handles.PositionSampleGUIAddOn);
  delete(handles.CollectDataGUIAddOn);
  if isfield(handles, 'ControlGUI')
    delete(handles.ControlGUI);
  end
  
  % Check to see if the user moved the window at all
  currentPosition = getpixelposition(hObject);
  if currentPosition(1:2) ~= handles.preferences.current.WindowPositions.main
    handles.preferences.current.WindowPositions.main = currentPosition(1:2);
  end

  % Hint: delete(hObject) closes the figure
  delete(hObject);
end


% --------------------------------------------------------------------
% --------------------------------------------------------------------
% --------------------------------------------------------------------
function CollectData_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to CollectData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  if ~SwitchIfOpen(handles, handles.CollectDataGUIAddOn);
    handles.ControlGUI =...
      Controls('AddOn', handles.CollectDataGUIAddOn,...
               'Cameras', handles.cameras,...
               'InterfaceController', handles.interfaceController,...
               'LaserScanController', handles.laserScanController,...
               'LockInAmpController', handles.lockInAmpController,...
               'MainWindow', handles.output,...
               'Preferences', handles.preferences,...
               'ProbeLaserController', handles.probeLaserController,...
               'PumpLaserController', handles.pumpLaserController,...
               'Settings', handles.settings,...
               'StageController', handles.stageController);

    % Update handles structure
    guidata(hObject, handles);
  end
end


function FilmThickness_Callback(hObject, eventdata, handles) %#ok<DEFNU,INUSL>
% hObject    handle to FilmThickness (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  handles.filmThicknessGUI = ...
    FilmThickness('InterfaceController', handles.interfaceController,...
                  'LockInAmpController', handles.lockInAmpController,...
                  'Preferences', handles.preferences,...
                  'PumpLaserController', handles.pumpLaserController,...
                  'Settings', handles.settings);
end


function PositionSample_Callback(hObject, eventdata, handles) %#ok<DEFNU,INUSL>
% hObject    handle to PositionSample (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  % Open the Controls window with the PositionSample add-on
  % Controls is modal, which means that Main will be blocked until
  % Controls closes.
  if ~SwitchIfOpen(handles, handles.PositionSampleGUIAddOn);
    handles.ControlGUI =...
      Controls('AddOn', handles.PositionSampleGUIAddOn,...
               'Cameras', handles.cameras,...
               'LockInAmpController', handles.lockInAmpController,...
               'InterfaceController', handles.interfaceController,...
               'MainWindow', handles.output,...
               'Preferences', handles.preferences,...
               'Settings', handles.settings,...
               'StageController', handles.stageController);

    % Update handles structure
    guidata(hObject, handles);
  end
end


function RunAnalysis_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to RunAnalysis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  handles.analysisGUI = StartAnalysis('Preferences', handles.preferences,...
                                      'Settings', handles.settings);
end


function SystemPower_Callback(hObject, eventdata, handles) %#ok<DEFNU,INUSL>
% hObject    handle to SystemPower (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

  % Check the current power status and take the appropriate action
  if handles.power
    powerOn = false;
  else
    powerOn = true;
  end
  handles = CascadeActionPower(handles, powerOn);
  
  % Update handles structure
  guidata(hObject, handles);
end


function ToolsAndUtilities_Callback(hObject, eventdata, handles) %#ok<DEFNU,INUSD>
% hObject    handle to ToolsAndUtilities (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end


% --------------------------------------------------------------------
% --------------------------------------------------------------------
% --------------------------------------------------------------------
function handles = CascadeActionPower(handles, powerOn)
% This function changes the states of GUI elements as needed by the current
% power state.
  % Let the user know that we are connecting and disable other buttons
  set(handles.SystemPower, 'Visible', 'Off');
  set(handles.RunAnalysis, 'Enable', 'Off');
  set(handles.Connecting, 'Visible', 'On');
  
  % Connect to, or disconnect, from the hardware
  if powerOn
    try
      handles = ConnectHardware(handles);
    catch me
      warning('Main:PowerOn', me.message);
      handles = DisconnectHardware(handles);
      set(handles.SystemPower, 'Visible', 'On');
      set(handles.Connecting, 'Visible', 'Off');
      set(handles.RunAnalysis, 'Enable', 'On');
      return;
    end
  else
    handles = DisconnectHardware(handles);
  end

  % Set the GUI state
  if powerOn
    state = 'On';
    antistate = 'Off';
    handles.LEDOff.SetState(false);
    handles.LEDOn.SetState(true);
  else
    state = 'Off';
    antistate = 'On';
    handles.LEDOff.SetState(true);
    handles.LEDOn.SetState(false);
  end

  % Set the states of the GUI elements
  set(handles.TextOff, 'Enable', antistate);
  set(handles.TextOn, 'Enable', state);
  set(handles.ToolsAndUtilities, 'Enable', 'Off'); % Not yet implemented
  set(handles.ToolsAndUtilities, 'Visible', 'Off'); % Not yet implemented
  set(handles.PositionSample, 'Enable', state);
  set(handles.CollectData, 'Enable', state);
  set(handles.FilmThickness, 'Enable', state);
  set(handles.SystemPower, 'Visible', 'On');
  set(handles.Connecting, 'Visible', 'Off');
  set(handles.RunAnalysis, 'Enable', 'On');

  % Set the global power state
  handles.power = powerOn;
end

function handles = ConnectHardware(handles)
% Connect to the hardware. Anything added here MUST have a corresponding
% disconnect statement in DisconnectHardware()
  % Configure the interface controller and set it to an empty state
  handles.interfaceController = InterfaceChassis_Control('Majordomo');
  handles.interfaceController.ConfigureForNothing();
  
  % Set up the cameras and Matrox device
  handles.cameras.load = videoinput('matrox', handles.settings.current.ImageAcquisition.loadDigitizer);
  handles.cameras.wide = videoinput('matrox', handles.settings.current.ImageAcquisition.wideDigitizer);
  handles.cameras.scan = videoinput('matrox', handles.settings.current.ImageAcquisition.scanDigitizer);
  handles.cameras.load.SelectedSource = handles.settings.current.ImageAcquisition.loadChannel;
  handles.cameras.wide.SelectedSource = handles.settings.current.ImageAcquisition.wideChannel;
  handles.cameras.scan.SelectedSource = handles.settings.current.ImageAcquisition.scanChannel;

  % Connect to GPIB devices
  handles.laserScanController =...
    ESP300_Control(handles.settings.current.LaserController,...
                   'Laser Controller');
  handles.laserScanController.UseFastSpeed();
  handles.lockInAmpController =...
    SR830_Control(handles.settings.current.LockInAmp.address,...
                  'Lock-in Amplifier');
  handles.lockInAmpController.SetSensitivityConstantValue(handles.settings.current.LockInAmp.sensitivityConstant);
  handles.probeLaserController =...
    ProbeLaser_Control(handles.lockInAmpController,...
                       handles.settings.current.LockInAmp.probePowerChannel);
  handles.pumpLaserController =...
    DS345_Control(handles.settings.current.FunctionGenerator.address,...
                  'Function Generator');
  handles.stageController =...
    ESP300_Control(handles.settings.current.StageController,...
                   'Stage Controller');
  
  % Home the stages
  HomeSampleStages(handles);

  % Set the maximum travel ranges of the sample stages
  stageIDs = [handles.settings.current.StageController.xAxisID, ...
              handles.settings.current.StageController.yAxisID, ...
              handles.settings.current.StageController.zAxisID];
  handles.stageController.SetLimits(stageIDs, [handles.settings.current.SoftStageBoundaries.x; ...
                                               handles.settings.current.SoftStageBoundaries.y; ...
                                               handles.settings.current.SoftStageBoundaries.z]);
                                             
  % Set the travel velocities of the stages to use slow by default
  handles.stageController.UseSlowSpeed();
  
  % Set the power setpoint for the pump laser
  handles.pumpLaserController.SetPowerSetpoint(handles.settings.current.FunctionGenerator.power);
end


function handles = DisconnectHardware(handles)
% Disconnect the hardware by setting the handles to empty. The individual
% classes will automtically disconnect from the hardware when deleted.
  handles.cameras.load = '';
  handles.cameras.wide = '';
  handles.cameras.scan = '';
  handles.laserScanController = '';
  handles.lockInAmpController = '';
  handles.probeLaserController = '';
  handles.pumpLaserController = '';
  handles.stageController = '';
  handles.interfaceController = '';
end


function HomeSampleStages(handles)
% Home the sample stages
  xAxis = handles.settings.current.StageController.xAxisID;
  yAxis = handles.settings.current.StageController.yAxisID;
  zAxis = handles.settings.current.StageController.zAxisID;
  
  options.yes = 'Yes';
  options.homeAndReturn = 'Home and Return';
  options.abort = 'Abort';
  answer = questdlg('Preparing to home the sample stages. Is this OK?', 'Warning', ...
                    options.yes, options.homeAndReturn, options.abort, ...
                    options.homeAndReturn);
  if strcmp(answer, options.abort)
    handles.stageController = [];
    error('Stages will not be homed. Connection to the stage controller failed.');
  else
    uiwait(warndlg({'Ensure it is safe to home the stages.'; 'Click ''OK'' to proceed.'}, 'Check sample', 'modal'));
    
    % Turn on the LED lights
    handles.interfaceController.SetIllumination(true);
    
    % Home the Z axis first so that we can drop it all the way to 0 and
    % ensure the safe movement of the X and Y axes without fear of crashing
    % the equipment
    handles.stageController.UseFastSpeed();
    handles.stageController.SetLimits(zAxis, [-1000, 1000]);
    handles.stageController.SetToZero([xAxis, yAxis, zAxis]);
    originalPositions.z = handles.stageController.HomeAxis(zAxis);
    handles.stageController.MoveAxis(handles.settings.current.StageController.zAxisID, handles.settings.current.SafeTraverseHeight.z, true);
    originalPositions.x = handles.stageController.HomeAxis(xAxis);
    originalPositions.y = handles.stageController.HomeAxis(yAxis);
    
    if strcmp(answer, options.homeAndReturn)
      % Determine the best location from the homing process that represents
      % the original location
      originalPositions.x = originalPositions.x(end - 5);
      originalPositions.y = originalPositions.y(end - 5);
      zMask = abs(originalPositions.z) > 0.05;
      originalPositions.z = originalPositions.z(zMask);
      originalPositions.z = originalPositions.z(end - 5);
      
      % Return the sample to it's original position, don't forget to invert
      % the value since we are now traveling back the opposite direction
      handles.stageController.MoveAxis([xAxis, yAxis], [-originalPositions.x, -originalPositions.y]);
      handles.stageController.WaitForAction([xAxis, yAxis], 'Message', 'Please wait while the X and Y axes are returned to their original location...');
      handles.stageController.MoveAxis(zAxis, -originalPositions.z);
      handles.stageController.WaitForAction(zAxis, 'Message', 'Please wait while the Z axis is returned to its original location...');
    end
    
    handles.stageController.SetLimits(zAxis, handles.settings.current.SoftStageBoundaries.z);
    handles.stageController.UseSlowSpeed();
    
    % Turn off the LED lights
    handles.interfaceController.SetIllumination(false);
  end
end


function isOpen = SwitchIfOpen(handles, addOn)
% Makes the ControlsGUI context if the window is already open
  isOpen = false;
  if isfield(handles, 'ControlGUI');
    if isvalid(handles.ControlGUI)
      % Get the currently loaded addOn
      controlHandles = guidata(handles.ControlGUI);
      
      if controlHandles.addOn == addOn
        % The current add on is already loaded and displayed, make it the
        % primary figure
        figure(handles.ControlGUI);
        isOpen = true;
      else
        % Another add on is loaded, so close it
        close(handles.ControlGUI);
      end
    end
  end
end

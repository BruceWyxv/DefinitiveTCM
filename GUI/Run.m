function varargout = Run(varargin)
% RUN MATLAB code for Run.fig
%      RUN, by itself, creates a new RUN or raises the existing
%      singleton*.
%
%      H = RUN returns the handle to a new RUN or the handle to
%      the existing singleton*.
%
%      RUN('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RUN.M with the given input arguments.
%
%      RUN('Property','Value',...) creates a new RUN or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Run_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Run_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Run

% Last Modified by GUIDE v2.5 29-Mar-2016 17:10:05

  % Begin initialization code - DO NOT EDIT
  gui_Singleton = 1;
  gui_State = struct('gui_Name',       mfilename, ...
                     'gui_Singleton',  gui_Singleton, ...
                     'gui_OpeningFcn', @Run_OpeningFcn, ...
                     'gui_OutputFcn',  @Run_OutputFcn, ...
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


function Run_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<INUSL>
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Run (see VARARGIN)

  % Choose default command line output for Run
  handles.output = hObject;
  
  % Check the input arguments
  parser = inputParser;
  parser.addParameter('laserScanController', '', @(x) isa(x, 'ESP300_Control'));
  parser.addParameter('lockInAmpController', '', @(x) isa(x, 'SR830_Control'));
  parser.addParameter('pumpLaserController', '', @(x) isa(x, 'DS345_Control'));
  parser.addParameter('settings', '', @isstruct);
  parser.addParameter('stageController', '', @(x) isa(x, 'ESP300_Control'));
  % Parse the input arguments
  parser.KeepUnmatched = true;
  try
    parser.parse(varargin{:});
  catch me
    error('Error when trying to parse input arguments:   %s', me.message);
  end
  handles.laserScanController = parser.Results.laserScanController;
  handles.lockInAmpController = parser.Results.lockInAmpController;
  handles.pumpLaserController = parser.Results.pumpLaserController;
  handles.settings = parser.Results.settings;
  handles.stageController = parser.Results.stageController;
  
  % Create the progress bar
  position = getpixelposition(handles.ProgressBarPlaceholder);
  handles.ProgressBar = uiwaitbar(position);
  
  % Ensure the window is hidden
  set(hObject, 'Visible', 'Off');

  % Update handles structure
  guidata(hObject, handles);
end


function varargout = Run_OutputFcn(hObject, eventdata, handles)  %#ok<INUSL>
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
function CancelButton_Callback(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to CancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
 set(hObject, 'CData', true);
 set(hObject, 'Enable', 'Off');
 set(hObject, 'String', 'Cancelling...');
end


% --------------------------------------------------------------------
% --------------------------------------------------------------------
% --------------------------------------------------------------------
function Center(runWindow, handles) %#ok<DEFNU>
% Centers the pump laser to the probe laser
  % Set up the window
  uiwaitbar(handles.ProgressBar, 0);
  set(runWindow, 'Visible', 'On');
  
  steps = handles.settings.CenterScan.steps;
  position = zeros(1, steps);
  for i = 1:steps
    % Check to see if the user has pressed the cancel button
    if get(handles.CancelButton, 'CData') == true
      break;
    end
  end
  
  % Hide the window to prepare for the next process to run
  set(runWindow, 'Visible', 'Off');
end


function data = Data(runWindow, handles) %#ok<DEFNU>
% Performs a scan of the sample
  % Set up the window
  uiwaitbar(handles.ProgressBar, 0);
  set(runWindow, 'Visible', 'On');
  
  steps = handles.settings.DataScan.steps;
  position = zeros(1, steps);
  for i = 1:steps
    % Check to see if the user has pressed the cancel button
    if get(handles.CancelButton, 'CData') == true
      break;
    end
  end
  
  % Hide the window to prepare for the next process to run
  set(runWindow, 'Visible', 'Off');
end


function Focus(runWindow, handles) %#ok<DEFNU>
% Moves the Z stage to focus the lasers
  % Set up the window
  uiwaitbar(handles.ProgressBar, 0);
  set(runWindow, 'Visible', 'On');
  
  % Calculate the positions
  zAxisID = handles.settings.StageController.zAxisID;
  steps = handles.settings.FocusScan.steps;
  stepSize = handles.settings.FocusScan.scanDistance / (steps - 1);
  halfPosition = handles.settings.FocusScan.scanDistance / 2;
  currentPosition = handles.stageController.GetAbsoluteCoordinates(zAxisID);
  positions = (currentPosition - halfPosition):stepSize:(currentPosition + halfPosition);
  
  % Set the lock-in amplifier settings
  timeConstant = handles.settings.FocusScan.lockInAmpTimeConstant;
  handles.lockInAmpController.SetTimeConstantValue(timeConstant);
  
  % Create the data structures
  amplitude = zeros(1, steps);
  phase = zeros(1, steps);
  
  % Peform the scan
  for i = 1:steps
    % Check to see if the user has pressed the cancel button
    if get(handles.CancelButton, 'CData') == true
      break;
    end
    
    % Move to the scan position
    handles.stageController.MoveAxis(zAxisID, positions(i));
    handles.stageController.WaitForAction(zAxisID);
    
    % Give the lock-in amp time to stabilize
    pause(timeConstant * 6);
    
    % Read the data
    amplitude(i) = handles.lockInAmpController.GetAmplitude();
    phase(i) = handles.lockInAmpController.GetPhase();
    
    % TODO plot the data here
  end
  
  % Hide the window to prepare for the next process to run
  set(runWindow, 'Visible', 'Off');
end

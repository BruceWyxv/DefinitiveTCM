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
  parser.addParameter('preferences', '', @isstruct);
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
  handles.preferences = parser.Results.preferences;
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
function centered = Center(runWindow, handles) %#ok<DEFNU>
% Centers the pump laser to the probe laser
  % Calculate the positions
  scanAxes = [handles.settings.LaserController.xAxisID, handles.settings.LaserController.yAxisID];
  steps = handles.settings.CenterScan.steps;
  if steps <=1
    steps = 2;
  end
  stepSize = handles.settings.CenterScan.scanDistance / (steps - 1);
  fineStepSize = stepSize / 25;
  halfPosition = handles.settings.CenterScan.scanDistance / 2;
  currentPosition = handles.laserController.GetAbsoluteCoordinates(scanAxes);
  positions = [(currentPosition(1) - halfPosition):stepSize:(currentPosition(1) + halfPosition);...
               (currentPosition(2) - halfPosition):stepSize:(currentPosition(2) + halfPosition)];
  finePosition = [(currentPosition(1) - halfPosition):fineStepSize:(currentPosition(1) + halfPosition);...
                  (currentPosition(2) - halfPosition):fineStepSize:(currentPosition(2) + halfPosition)];
  
  % Set the controller settings
  handles.pumpLaserController.SetFrequency(handles.settings.CenterScan.frequency);
  timeConstant = handles.settings.CenterScan.lockInAmpTimeConstant;
  handles.lockInAmpController.SetTimeConstantValue(timeConstant);
  handles.lockInAmpController.Chill();
  
  % Create the data structures
  amplitude = NaN(2, steps);
  amplitudeLine(2) = '';
  phase = NaN(2, steps);
  phaseLine(2) = '';

  % Set up the window and prepare the plots
  uiwaitbar(handles.ProgressBar, 0);
  set(handles.ProgressText, 'String', '');
  centerColormap = GetColormap(handles.settings.PlotSettings.centerColomap, 2);
  clf(handles.AmplitudePlot, 'reset');
  clf(handles.PhasePlot, 'reset');
  hold(handles.AmplitudePlot, 'on');
  hold(handles.PhasePlot, 'on');
  legendItems = {'X Axis - Data', 'X Axis - Fit', 'Y Axis - Data', 'Y Axis - Fit'};
  set(runWindow, 'Visible', 'On');
  
  % Peform the scan
  for a = 1:2
    % Scan over both the x and the y axis
    % Check to see if the user has pressed the cancel button
    if get(handles.CancelButton, 'CData') == true
      break;
    end

    % Set up the plots for the next scan
    amplitudeLine(a) = plot(handles.AmplitudePlot, positions(a,:), amplitude(a,:), 'Color', centerColormap(a), 'Line', 'none', 'Marker', handles.settings.PlotSettings.centerXSymbol);
    phaseLine(a) = plot(handles.PhasePlot, positions(a,:), phase(a,:), 'Color', centerColormap(a), 'Line', 'none', 'Marker', handles.settings.PlotSettings.centerYSymbol);
    switch a
      case 1
        axisName = 'X';
        legend(handles.AmplitudePlot, legendItems{1});
        legend(handles.PhasePlot, legendItems{1});
        
      case 2
        axisName = 'Y';
        legend(handles.AmplitudePlot, legendItems{1:3});
        legend(handles.PhasePlot, legendItems{1}, legendItems{3});
    end
    set(handles.ProgressText, 'String', sprintf('Centering the lasers...  Axis: %s (%i of 2)', axisName, a));
    
    % Account for hysteresis of the stage
    handles.stageController.MinimizeHysteresis(scanAxes(a), positions(a,1:2));
    
    for i = 1:steps
      % Check to see if the user has pressed the cancel button
      if get(handles.CancelButton, 'CData') == true
        break;
      end

      % Move to the scan position
      handles.laserController.MoveAxis(scanAxes(a), positions(a,i));
      handles.laserController.WaitForAction(scanAxes(a));

      % Give the lock-in amp time to stabilize
      handles.lockInAmpController.Chill();

      % Read the data
      amplitude(a,i) = handles.lockInAmpController.GetAmplitude();
      phase(a,i) = handles.lockInAmpController.GetPhase();

      % Update the plots
      set(amplitudeLine(a), 'YData', amplitude(a,:));
      set(phaseLine(a), 'YData', phase(a,:));

      % Update the progress bar
      uiwaitbar(handles.ProgressBar, (i + ((a - 1) * steps)) / (steps * 2));
    end

    % Fit the data and look for a maximum in the amplitude
    [coefficients, ~, mu] = polyfit(positions(a,:), amplitude(a,:), 5);
    derivative = polyder(coefficients);
    maxPosition = roots(derivative);

    % Plot the fit
    evaluatedFit = polyval(coefficients, finePosition, [], mu);
    plot(handles.AmplitudePlot, finePositions, evaluatedFit, handles.settings.PlotSettings.focusFitLineStyle, 'Color', centerColormap(a));

    % Move the stage to the ideal position
    handles.stageController.MinimizeHysteresis(scanAxes(a), positions(a,1:2));
    handles.stageController.MoveAxis(scanAxes(a), maxPosition);
    handles.stageController.WaitForAction(scanAxes(a));
  end
  
  % Some final plotting items
  legend(handles.AmplitudePlot, legendItems);
  hold(handles.AmplitudePlot, 'off');
  hold(handles.PhasePlot, 'off');
  
  % Check with the user to make sure everything looks good
  choices.Again = 'No, Center Again';
  choices.Good = 'Yes';
  response = questdlg({'Do the centering results look good?'},...
                      'Check results from centering',...
                      choices.Again, choices.Good, choices.Good);
  switch response
    case choices.Again
      centered = false;

    case choices.Good
      centered = true;
  end

  % Hide the window to prepare for the next process to run
  set(runWindow, 'Visible', 'Off');
end


function [data, success] = Data(runWindow, handles) %#ok<DEFNU>
% Performs a scan of the sample
  data = '';
  success = false;
  
  % Calculate the positions
  xAxisID = handles.settings.LaserController.xAxisID;
  steps = handles.settings.DataScan.steps;
  if steps <=1
    steps = 2;
  end
  stepSize = handles.settings.DataScan.scanDistance / (steps - 1);
  halfPosition = handles.settings.DataScan.scanDistance / 2;
  currentPosition = handles.laserController.GetAbsoluteCoordinates(xAxisID);
  positions = (currentPosition - halfPosition):stepSize:(currentPosition + halfPosition);
  
  % Create the data structures
  frequencies = handles.settings.DataScan.frequencies;
  numberOfFrequencies = length(frequencies);
  amplitude = NaN(numberOfFrequencies, steps);
  phase = NaN(numberOfFrequencies, steps);
  redoTest = true;

  % Set up the window and prepare the plots
  uiwaitbar(handles.ProgressBar, 0);
  set(handles.ProgressText, 'String', '');
  centerColormap = GetColormap(handles.settings.PlotSettings.centerColomap, numberOfFrequencies);
  clf(handles.AmplitudePlot, 'reset');
  clf(handles.PhasePlot, 'reset');
  colormap(handles.AmplitudePlot, centerColormap);
  colormap(handles.PhasePlot, centerColormap);
  legendItems = cell(1, numberOfFrequencies);
  set(runWindow, 'Visible', 'On');
  
  % Peform the scan
  f = 1;
  while f <= numberOfFrequencies % Don't use a for loop - we might need to repeat a frequency
    % Scan over both the x and the y axis
    % Check to see if the user has pressed the cancel button
    if get(handles.CancelButton, 'CData') == true
      break;
    end
    
    % Account for hysteresis of the stage
    handles.stageController.MinimizeHysteresis(xAxisID, positions);
    
    % Check for performing a test run
    if handles.preferences.CollectData.textRun == 1 && redoTest
      % Set up for a test of the current location
      frequency = handles.settings.DataScan.testFrequency;
      timeConstant = handles.settings.DataScan.testLockInAmpTimeConstant;
      baseProgressString = sprintf('Data Scan Test... Frequency: %g kHz', handles.settings.DataScan.testFrequency / 1000);
      legendItems{1} = sprintf('Test Run @ %g kHz', frequency);
    else
      % Set up for a full scan
      hold(handles.AmplitudePlot, 'on');
      hold(handles.PhasePlot, 'on');
      frequency = frequencies(f);
      timeConstant = handles.settings.DataScan.lockInAmpTimeConstant;
      baseProgressString = sprintf('Data Scan... Frequency: %g kHz (%i of %i)', frequencies(f) / 1000, f, numberOfFrequencies);
      legendItems{f} = sprintf('%g kHz', frequencies(f) / 1000);
    end

    % Set up the plots for the next scan
    amplitudeLine = plot(handles.AmplitudePlot, positions, amplitude(f,:), 'Line', handles.settings.PlotSettings.amplitudeLineStyle, 'Marker', handles.settings.PlotSettings.amplitudeMarker);
    phaseLine = plot(handles.PhasePlot, positions, phase(f,:), 'Line', handles.settings.PlotSettings.phaseLineStyle, 'Marker', handles.settings.PlotSettings.phaseMarker);
    legend(handles.AmplitudePlot, legendItems);
    legend(handles.PhasePlot, legendItems);
    
    % Set up the equipment
    handles.pumpLaserController.SetFrequency(frequency);
    handles.lockInAmpController.SetTimeConstantValue(timeConstant);
    handles.lockInAmpController.Chill();
    
    for i = 1:steps
      set(handles.ProgressText, 'String', sprintf('%s - Postion: %i of %i', baseProgressString, i, steps));
      % Check to see if the user has pressed the cancel button
      if get(handles.CancelButton, 'CData') == true
        break;
      end

      % Move to the scan position
      handles.stageController.MoveAxis(scanAxes(a), positions(a,i));
      handles.stageController.WaitForAction(scanAxes(a));

      % Give the lock-in amp time to stabilize
      handles.lockInAmpController.Chill();

      % Read the data
      amplitude(f,i) = handles.lockInAmpController.GetAmplitude();
      phase(f,i) = handles.lockInAmpController.GetPhase();

      % Update the plots
      set(amplitudeLine(f), 'YData', amplitude(f,:));
      set(phaseLine(f), 'YData', phase(f,:));

      % Update the progress bar
      uiwaitbar(handles.ProgressBar, (i + ((f - 1) * steps)) / (numberOfFrequencies * steps));
    end
    
    if handles.preferences.CollectData.textRun == 1 && redoTest
      userResponse = questdlg('Do the test measurements look good?', 'Good location?', 'Yes', 'No', 'Abort', 'Yes');
      switch userResponse
        case 'Yes'
          redoTest = false;
          
        case 'No'
          uiwait(msgbox('I will perform another test at the same location.'));
          
        case 'Abort'
          return;
      end
    end
  end
  
  % Set the data
  data.frequencies = frequencies;
  data.timeConstant = timeConstant;
  data.positions = positions;
  data.amplitudes = amplitude;
  data.phase = phase;

  % Hide the window to prepare for the next process to run
  set(runWindow, 'Visible', 'Off');
end


function [focused, maxPosition] = Focus(runWindow, handles) %#ok<DEFNU>
% Moves the Z stage to focus the lasers
  % Calculate the positions
  zAxisID = handles.settings.StageController.zAxisID;
  steps = handles.settings.FocusScan.steps;
  if steps <=1
    steps = 2;
  end
  stepSize = handles.settings.FocusScan.scanDistance / (steps - 1);
  fineStepSize = stepSize / 25;
  halfPosition = handles.settings.FocusScan.scanDistance / 2;
  currentPosition = handles.stageController.GetAbsoluteCoordinates(zAxisID);
  positions = (currentPosition - halfPosition):stepSize:(currentPosition + halfPosition);
  finePosition = (currentPosition - halfPosition):fineStepSize:(currentPosition + halfPosition);
  
  % Set the controller settings
  handles.pumpLaserController.SetFrequency(handles.settings.FocusScan.frequency);
  timeConstant = handles.settings.FocusScan.lockInAmpTimeConstant;
  handles.lockInAmpController.SetTimeConstantValue(timeConstant);
  handles.lockInAmpController.Chill();
  
  % Create the data structures
  amplitude = NaN(1, steps);
  phase = NaN(1, steps);

  % Set up the window and prepare the plots
  uiwaitbar(handles.ProgressBar, 0);
  set(handles.ProgressText, 'String', '');
  clf(handles.AmplitudePlot, 'reset');
  clf(handles.PhasePlot, 'reset');
  amplitudeLine = plot(handles.AmplitudePlot, positions, amplitude, handles.settings.PlotSettings.amplitude, 'Line', 'none', 'Marker', handles.settings.PlotSettings.focusMarker);
  phaseLine = plot(handles.PhasePlot, positions, phase, handles.settings.PlotSettings.phase, 'Line', 'none', 'Marker', handles.settings.PlotSettings.focusMarker);
  hold(handles.AmplitudePlot, 'on');
  set(runWindow, 'Visible', 'On');
  
  % Account for hysteresis of the stage
  handles.stageController.MinimizeHysteresis(zAxisID, positions(1:2));
  
  % Peform the scan
  for i = 1:steps
    % Check to see if the user has pressed the cancel button
    if get(handles.CancelButton, 'CData') == true
      break;
    end
    
    % Move to the scan position
    set(handles.ProgressText, 'String', sprintf('Focusing the lasers...  Step (%i of %i)', i, steps));
    handles.stageController.MoveAxis(zAxisID, positions(i));
    handles.stageController.WaitForAction(zAxisID);
    
    % Give the lock-in amp time to stabilize
    handles.lockInAmpController.Chill();
    
    % Read the data
    amplitude(i) = handles.lockInAmpController.GetAmplitude();
    phase(i) = handles.lockInAmpController.GetPhase();
    
    % Update the plots
    set(amplitudeLine, 'YData', amplitude);
    set(phaseLine, 'YData', phase);
    
    % Update the progress bar
    uiwaitbar(handles.ProgressBar, i / steps);
  end
  
  % Fit the data and look for a maximum in the amplitude
  [coefficients, ~, mu] = polyfit(positions, amplitude, 5);
  derivative = polyder(coefficients);
  maxPosition = roots(derivative);
  
  % Plot the fit
  figure(handles.AmplitudePlot)
  evaluatedFit = polyval(coefficients, finePosition, [], mu);
  plot(handles.amplitudePlot, finePositions, evaluatedFit, handles.settings.PlotSettings.focusFitLineSpec);
  if maxPosition >= positions(1) && maxPosition <= positions(steps)
    % The maximum was within the scan range
    focused = true;
  else
    % It appears that the maximum was outside the scan range
    [~, maxPosition] = max(evaluatedFit);
    choices.Again = 'Focus Again';
    choices.Ignore = 'Ignore and Continue';
    response = questdlg({'It appears that the optimal focus distance is outside the scanned range.'...
                         ''...
                         'What would you like to do?'},...
                        'Addition Focus Recommended',...
                        choices.Again, choices.Ignore, choices.Again);
    switch response
      case choices.Again
        focused = false;
        
      case choices.Ignore
        focused = true;
    end
  end
  
  % Move the stage to the ideal position
  handles.stageController.MinimizeHysteresis(zAxisID, positions(1:2));
  handles.stageController.MoveAxis(zAxisID, maxPosition);
  handles.stageController.WaitForAction(zAxisID);
  
  % Hide the window to prepare for the next process to run
  hold(handles.AmplitudePlot, 'off');
  set(runWindow, 'Visible', 'Off');
end


function colormap = GetColormap(mapName, steps)
% Gets the color map corresponding the the string
  try
    % Interpret the colomap name as a function (see colormap)
    colormapFunction = str2func(mapName);
    colormap = colormapFunction(steps);
  catch
    % Default to the jet colormap if an error occurs
    colormap = jet(steps);
  end
end

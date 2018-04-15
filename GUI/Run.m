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

% Last Modified by GUIDE v2.5 26-Apr-2016 12:36:20

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
  parser.addParameter('mainWindow', '', @ishandle);
  parser.addParameter('preferences', '', @(x) isa(x, 'ConfigurationFile'));
  parser.addParameter('pumpLaserController', '', @(x) isa(x, 'DS345_Control'));
  parser.addParameter('settings', '', @(x) isa(x, 'ConfigurationFile'));
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
  handles.mainWindow = parser.Results.mainWindow;
  handles.preferences = parser.Results.preferences;
  handles.pumpLaserController = parser.Results.pumpLaserController;
  handles.settings = parser.Results.settings;
  handles.stageController = parser.Results.stageController;
  
  % Set the window position
  setpixelposition(hObject, handles.preferences.current.WindowPositions.run);
  movegui(hObject, 'onscreen');
  
  % Create the progress bar
  position = getpixelposition(handles.ProgressBarPlaceholder);
  handles.ProgressBar = uiwaitbar('Create', hObject, position);
  
  % Ensure the window is hidden
  set(hObject, 'Visible', 'Off');
  
  % Set the current statuses
  set(handles.CancelButton, 'Enable', 'On');
  set(handles.CancelButton, 'String', 'Cancel');
  set(handles.IsClosing, 'Value', 0);
  set(handles.IsRunning, 'Value', 0);
  
  % Create the amplitude and phase plots
  handles.AmplitudePlot = subplot(1, 2, 2, 'Parent', handles.PlotsPlaceholder);
  handles.PhasePlot = subplot(1, 2, 1, 'Parent', handles.PlotsPlaceholder);
  title(handles.AmplitudePlot, 'Amplitude');
  title(handles.PhasePlot, 'Phase');
  %TODO Add context menu to plots for toggling grid lines or other options

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


function RunWindow_CloseRequestFcn(hObject, eventdata, handles) %#ok<DEFNU>
% hObject    handle to RunWindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  if isfield(handles, 'preferences') && isvalid(handles.preferences)
    currentPosition = getpixelposition(hObject);
    if ~isequal(currentPosition, handles.preferences.current.WindowPositions.run)
      handles.preferences.current.WindowPositions.run = currentPosition;
    end
  end
  
  set(handles.IsClosing, 'Value', 1);
  CancelButton_Callback(handles.CancelButton, eventdata, handles);
end


function RunWindow_SizeChangedFcn(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to RunWindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  position = getpixelposition(handles.ProgressBarPlaceholder);
  setpixelposition(handles.ProgressBar, position);
end


% --------------------------------------------------------------------
% --------------------------------------------------------------------
% --------------------------------------------------------------------
function CancelButton_Callback(hObject, eventdata, handles) %#ok<INUSL>
% hObject    handle to CancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  if IsRunning(handles)
    set(hObject, 'Enable', 'Off');
    set(hObject, 'String', 'Cancelling...');
  else
    % The 'Cancel' button has become a 'Close' button, so close the window
    CloseMe(hObject.Parent);
  end
end


% --------------------------------------------------------------------
% --------------------------------------------------------------------
% --------------------------------------------------------------------
function CloseMe(myself)
% Close and delete this window
  delete(myself);
end

function [centered, goodToGo] = Center(handles) %#ok<DEFNU>
% Centers the pump laser to the probe laser
  set(handles.IsRunning, 'Value', 1);
  
  % Calculate the positions
  scanAxes = [handles.settings.current.LaserController.xAxisID, handles.settings.current.LaserController.yAxisID];
  steps = handles.settings.current.CenterScan.steps;
  if steps <= 7
    steps = 7;
  end
  stepSize = handles.settings.current.CenterScan.scanDistance / (steps - 1);
  fineStepSize = stepSize / 25;
  halfPosition = handles.settings.current.CenterScan.scanDistance / 2;
  currentPosition = handles.laserScanController.GetAbsoluteCoordinates(scanAxes);
  positions = [(currentPosition - halfPosition):stepSize:(currentPosition + halfPosition);
               (currentPosition - halfPosition):stepSize:(currentPosition + halfPosition)];
  finePositions = [(currentPosition - halfPosition):fineStepSize:(currentPosition + halfPosition);
                   (currentPosition - halfPosition):fineStepSize:(currentPosition + halfPosition)];
  
  % Set the controller settings
  handles.pumpLaserController.SetFrequency(handles.settings.current.CenterScan.frequency);
  timeConstant = handles.settings.current.CenterScan.lockInAmpTimeConstant;
  handles.lockInAmpController.SetTimeConstantValue(timeConstant);
  handles.lockInAmpController.Chill();
  handles.lockInAmpController.AdaptSensitivity();
  
  % Create the data structures
  amplitude = NaN(2, steps);
  phase = NaN(2, steps);
  amplitudeLine = zeros(2);
  phaseLine = zeros(2);

  % Set up the window and prepare the plots
  uiwaitbar(handles.ProgressBar, 0);
  set(handles.ProgressText, 'String', '');
  centerColormap = GetColormap(handles.settings.current.PlotSettings.centerColormap, 2);
  cla(handles.AmplitudePlot);
  cla(handles.PhasePlot);
  handles.AmplitudePlot.XLim = [(min(positions(:)) - stepSize), (max(positions(:)) + stepSize)];
  handles.PhasePlot.XLim = [(min(positions(:)) - stepSize), (max(positions(:)) + stepSize)];
  hold(handles.AmplitudePlot, 'on');
  hold(handles.PhasePlot, 'on');
  legendItems = {'X Axis - Data', 'X Axis - Fit', 'X Axis - Best', 'Y Axis - Data', 'Y Axis - Fit', 'Y Axis - Best'};
  
  % Peform the scan
  centered = false;
  goodToGo = true;
  recommendAgain = false;
  for a = 1:2
    % Scan over both the x and the y axis
    % Check to see if the user has pressed the cancel button
    if IsCancelling(handles);
      goodToGo = false;
      break;
    end

    % Set up the plots for the next scan
    if a == 1
      marker = handles.settings.current.PlotSettings.centerXSymbol;
    else
      marker = handles.settings.current.PlotSettings.centerYSymbol;
    end
    amplitudeLine(a) = plot(handles.AmplitudePlot, positions(a,:), amplitude(a,:), 'Color', centerColormap(a,:), 'LineStyle', 'none', 'Marker', marker);
    phaseLine(a) = plot(handles.PhasePlot, positions(a,:), phase(a,:), 'Color', centerColormap(a,:), 'LineStyle', 'none', 'Marker', marker);
    switch a
      case 1
        axisName = 'X';
        legend(handles.AmplitudePlot, legendItems{1}, 'Location', 'South');
        legend(handles.PhasePlot, legendItems{1}, 'Location', 'South');
        
      case 2
        axisName = 'Y';
        legend(handles.AmplitudePlot, legendItems{1:4}, 'Location', 'South');
        legend(handles.PhasePlot, legendItems{1}, legendItems{4}, 'Location', 'South');
    end
    set(handles.ProgressText, 'String', sprintf('Centering the lasers...  Axis: %s (%i of 2)', axisName, a));
    
    % Correlate the directionality of the positions to the user-percieved
    % directions
    if ReverseDirectionality(scanAxes(a), handles.settings)
      scanPositions = -positions(a,:);
    else
      scanPositions = positions(a,:);
    end
  
    % Account for hysteresis of the stage
    handles.laserScanController.MinimizeHysteresis(scanAxes(a), scanPositions(1:2));
    
    for i = 1:steps
      % Check to see if the user has pressed the cancel button
      if IsCancelling(handles)
        goodToGo = false;
        break;
      end

      % Move to the scan position
      handles.laserScanController.MoveAxis(scanAxes(a), scanPositions(i));
      handles.laserScanController.WaitForAction(scanAxes(a));

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
    
    if ~goodToGo
      break;
    end

    % Fit the data and look for a maximum in the amplitude
    [mu, sigma, scale] = FitGaussian(positions(a,:), amplitude(a,:) - min(amplitude(a,:)));

    % Plot the fit
    evaluatedFit = gaussian(finePositions(a,:), mu, sigma, scale) + min(amplitude(a,:));
    [~, maxPositionIndex] = max(evaluatedFit);
    maxPosition = finePositions(a,maxPositionIndex);
    plot(handles.AmplitudePlot, finePositions(a,:), evaluatedFit, 'LineStyle', handles.settings.current.PlotSettings.fitLineStyle, 'Color', centerColormap(a,:));
    plot(handles.AmplitudePlot, [maxPosition, maxPosition], get(handles.AmplitudePlot, 'YLim'), 'Color', centerColormap(a,:));

    % Move the stage to the ideal position
    if maxPosition > positions(a,end-2) || maxPosition < positions(a,3)
      recommendAgain = recommendAgain | true;
    else
      recommendAgain = recommendAgain | false;
    end
    handles.laserScanController.MinimizeHysteresis(scanAxes(a), scanPositions(1:2));
    % Correlate the directionality of the positions to the user-percieved
    % directions
    if ReverseDirectionality(scanAxes(a), handles.settings)
      handles.laserScanController.MoveAxis(scanAxes(a), -maxPosition);
    else
      handles.laserScanController.MoveAxis(scanAxes(a), maxPosition);
    end
    handles.laserScanController.WaitForAction(scanAxes(a));
    handles.laserScanController.SetToZero(scanAxes(a));
  end
  
  if goodToGo
    % Some final plotting items
    legend(handles.AmplitudePlot, legendItems, 'Location', 'South');
    hold(handles.AmplitudePlot, 'off');
    hold(handles.PhasePlot, 'off');

    % Check with the user to make sure everything looks good
    choices.Again = 'No, Center Again';
    choices.Good = 'Yes';
    if recommendAgain
      choices.Recommended = choices.Again;
    else
      choices.Recommended = choices.Good;
    end
    response = questdlg({'Do the centering results look good?'},...
                        'Check results from centering',...
                        choices.Again, choices.Good, choices.Recommended);
    switch response
      case choices.Again
        centered = false;

      case choices.Good
        centered = true;
    end
  else
    % Move the stages back to their original positions
    handles.laserScanController.MoveAxis(scanAxes, currentPosition);
  end
  
  set(handles.IsRunning, 'Value', 0);
end


function [data, success] = Data(handles) %#ok<DEFNU>
% Performs a scan of the sample
  data = '';
  set(handles.IsRunning, 'Value', 1);
  
  % Set up the scan positions
  scanAxes = [handles.settings.current.LaserController.xAxisID, ...
              handles.settings.current.LaserController.yAxisID];
  steps = handles.settings.current.DataScan.steps;
  direction = handles.settings.current.DataScan.scanDirection;
  stepSize = handles.settings.current.DataScan.scanDistance / (steps - 1);
  halfPosition = handles.settings.current.DataScan.scanDistance / 2;
  currentPositions = handles.laserScanController.GetAbsoluteCoordinates(scanAxes);
  distances = -halfPosition:stepSize:halfPosition;
  positions = zeros(2, steps);
  positions(1,:) = (cosd(direction) * distances) - currentPositions(1);
  positions(2,:) = (sind(direction) * distances) - currentPositions(2);
  
  % Correlate the directionality of the positions to the user-percieved
  % directions
  scanPositions = zeros(size(positions));
  for a = 1:length(scanAxes)
    if ReverseDirectionality(scanAxes(a), handles.settings)
      scanPositions(a,:) = -positions(a,:);
    else
      scanPositions(a,:) = positions(a,:);
    end
  end
  
  % Create the data structures
  frequencies = handles.settings.current.DataScan.frequencies;
  numberOfFrequencies = length(frequencies);
  amplitude = NaN(numberOfFrequencies, steps);
  amplitudePoints = NaN(numberOfFrequencies, 1);
  phases = NaN(numberOfFrequencies, steps);
  phasePoints = NaN(numberOfFrequencies, 1);
  redoTest = true;
  % Newer settings files will have a slow scan frequency cut-off value.
  % Detect if it is there and use it if so to perform slower scans at lower
  % frequencues.
  if isfield(handles.settings.current.DataScan, 'slowScanFrequencyCutoff')
    slowScanFrequencyCutoff = handles.settings.current.DataScan.slowScanFrequencyCutoff;
    slowScanLockInAmpTimeConstant = handles.settings.current.DataScan.slowScanLockInAmpTimeConstant;
  else
    slowScanFrequencyCutoff = -1;
  end

  % Set up the window and prepare the plots
  uiwaitbar(handles.ProgressBar, 0);
  set(handles.ProgressText, 'String', '');
  dataColormap = GetColormap(handles.settings.current.PlotSettings.dataColormap, numberOfFrequencies);
  cla(handles.AmplitudePlot);
  cla(handles.PhasePlot);
  hold(handles.AmplitudePlot, 'on');
  hold(handles.PhasePlot, 'on');
  colormap(handles.AmplitudePlot, dataColormap);
  colormap(handles.PhasePlot, dataColormap);
  legendItems = cell(1, numberOfFrequencies);
  
  % Peform the scan
  f = 1;
  success = true;
  while success == true && f <= numberOfFrequencies  % Don't use a for loop - we might need to repeat a frequency
    % Check to see if the user has pressed the cancel button
    if IsCancelling(handles)
      success = false;
      break;
    end
    
    % Check for performing a test run
    if handles.preferences.current.CollectData.testRun == 1 && redoTest
      % Set up for a test of the current location
      frequency = handles.settings.current.DataScan.testFrequency;
      timeConstant = handles.settings.current.DataScan.testLockInAmpTimeConstant;
      baseProgressString = sprintf('Data Scan Test... Frequency: %g kHz', handles.settings.current.DataScan.testFrequency / 1000);
      legendItems{1} = sprintf('Test Run @ %g kHz', frequency / 1000);
    else
      % Set up for a full scan
      frequency = frequencies(f);
      timeConstant = handles.settings.current.DataScan.lockInAmpTimeConstant;
      baseProgressString = sprintf('Data Scan... Frequency: %g kHz (%i of %i)', frequencies(f) / 1000, f, numberOfFrequencies);
      legendItems{f} = sprintf('%g kHz', frequencies(f) / 1000);
    end

    % Set up the plots for the next scan
    if isnan(amplitudePoints(f))
      amplitudePoints(f) = plot(handles.AmplitudePlot, distances, amplitude(f,:), 'LineStyle', 'none', 'Marker', handles.settings.current.PlotSettings.amplitudeMarker);
      phasePoints(f) = plot(handles.PhasePlot, distances, phases(f,:), 'LineStyle', 'none', 'Marker', handles.settings.current.PlotSettings.phaseMarker);
      handles.AmplitudePlot.XLim = [(distances(1) - stepSize), (distances(end) + stepSize)];
      handles.PhasePlot.XLim = [(distances(1) - stepSize), (distances(end) + stepSize)];
    end
    legend(handles.AmplitudePlot, legendItems{1:f}, 'Location', 'South');
    legend(handles.PhasePlot, legendItems{1:f}, 'Location', 'South');
    
    % Set up the equipment
    handles.pumpLaserController.SetFrequency(frequency);
    if frequency <= slowScanFrequencyCutoff
      handles.lockInAmpController.SetTimeConstantValue(slowScanLockInAmpTimeConstant);
    else
      handles.lockInAmpController.SetTimeConstantValue(timeConstant);
    end
    
    % Adapt to the best sensitivity for the current frequency with the
    % lasers on top of each other
    handles.laserScanController.MoveAxis(scanAxes, currentPositions);
    handles.lockInAmpController.Chill();
    handles.lockInAmpController.AdaptSensitivity();

    % Account for hysteresis of the stage
    handles.laserScanController.MinimizeHysteresis(scanAxes, scanPositions(:,1:2));
    
    for i = 1:steps
      set(handles.ProgressText, 'String', sprintf('%s - Position: %i of %i', baseProgressString, i, steps));
      % Check to see if the user has pressed the cancel button
      if IsCancelling(handles)
        success = false;
        break;
      end

      % Move to the scan position
      handles.laserScanController.MoveAxis(scanAxes, scanPositions(:,i));
      handles.laserScanController.WaitForAction(scanAxes);

      % Give the lock-in amp time to stabilize
      handles.lockInAmpController.Chill();

      % Read the data
      amplitude(f,i) = handles.lockInAmpController.GetAmplitude();
      phases(f,i) = handles.lockInAmpController.GetPhase();

      % Update the plots
      set(amplitudePoints(f), 'YData', amplitude(f,:));
      set(phasePoints(f), 'YData', phases(f,:));

      % Update the progress bar
      if handles.preferences.current.CollectData.testRun == 1 && redoTest
        uiwaitbar(handles.ProgressBar, i / steps);
      else
        uiwaitbar(handles.ProgressBar, (i + ((f - 1) * steps)) / (numberOfFrequencies * steps));
      end
    end
    
    if handles.preferences.current.CollectData.testRun == 1 && redoTest && success == true
      userResponse = questdlg('Do the test measurements look good?', 'Good location?', 'Yes', 'No', 'Abort', 'Yes');
      switch userResponse
        case 'Yes'
          f = f - 1;
          redoTest = false;
          % Reset the plots
          amplitude(1,:) = NaN(1, steps);
          set(amplitudePoints(1), 'YData', amplitude(1,:));
          phases(1,:) = NaN(1, steps);
          set(phasePoints(1), 'YData', phases(1,:));
          
        case 'No'
          uiwait(msgbox('I will perform another test at the same location.'));
          
        case 'Abort'
          success = false;
      end
    end
    
    if ~redoTest
      f = f + 1;
    end
  end
  
  % Clean up
  hold(handles.AmplitudePlot, 'off');
  hold(handles.PhasePlot, 'off');
  
  % Move the stages back to their original positions
  handles.laserScanController.MoveAxis(scanAxes, currentPositions);
  
  if success
    % Set the data
    data.frequencies = frequencies;
    data.timeConstant = timeConstant;
    data.positions = distances;
    data.amplitudes = amplitude;
    data.direction = direction;
    data.phases = phases;
  end
  
  set(handles.IsRunning, 'Value', 0);
end


function Finalize(myself, handles, success, showMessage) %#ok<DEFNU>
% Called when the analysis is over, used to clean things up
  % Set the statuses
  set(handles.IsRunning, 'Value', 0);
  set(handles.CancelButton, 'Enable', 'On');
  set(handles.CancelButton, 'String', 'Close');
  
  % Show a message
  if showMessage
    if success
      message = 'The data collection completed succesfully! Click ''OK'' to continue...';
    else
      message = 'The data collection terminated! Click ''OK'' to continue...';
    end
    
    uiwait(msgbox(message, 'Run', 'modal'));
  end
  
  if IsClosing(handles)
    CloseMe(myself);
  end
end


function [focused, goodToGo, relativeFocusPosition] = Focus(handles) %#ok<DEFNU>
% Moves the Z stage to focus the lasers
  set(handles.IsRunning, 'Value', 1);
  
  % Calculate the positions
  zAxisID = handles.settings.current.StageController.zAxisID;
  steps = handles.settings.current.FocusScan.steps;
  if steps <= 7
    steps = 7;
  end
  stepSize = handles.settings.current.FocusScan.scanDistance / (steps - 1);
  halfPosition = handles.settings.current.FocusScan.scanDistance / 2;
  stagePosition = handles.stageController.GetAbsoluteCoordinates(zAxisID);
  relativePositions = Controls('ConvertStages2PositionCoordinates', handles, 'ScanningObjective', [0, 0, stagePosition]);
  relativeZPosition = relativePositions(3);
  positions = (stagePosition - halfPosition):stepSize:(stagePosition + halfPosition);
  relativePositions = (relativeZPosition - halfPosition):stepSize:(relativeZPosition + halfPosition);
  
  % Set the controller settings
  handles.pumpLaserController.SetFrequency(handles.settings.current.FocusScan.frequency);
  timeConstant = handles.settings.current.FocusScan.lockInAmpTimeConstant;
  handles.lockInAmpController.SetTimeConstantValue(timeConstant);
  handles.lockInAmpController.Chill();
  handles.lockInAmpController.AdaptSensitivity();
  
  % Create the data structures
  amplitude = NaN(1, steps);
  phase = NaN(1, steps);

  % Set up the window and prepare the plots
  uiwaitbar(handles.ProgressBar, 0);
  set(handles.ProgressText, 'String', '');
  cla(handles.AmplitudePlot);
  cla(handles.PhasePlot);
  handles.AmplitudePlot.XLim = [(relativePositions(1) - stepSize), (relativePositions(end) + stepSize)];
  handles.PhasePlot.XLim = [(relativePositions(1) - stepSize), (relativePositions(end) + stepSize)];
  hold(handles.AmplitudePlot, 'on');
  hold(handles.PhasePlot, 'on');
  amplitudeLine = plot(handles.AmplitudePlot, relativePositions, amplitude, 'LineStyle', 'none', 'Marker', handles.settings.current.PlotSettings.amplitudeMarker);
  phaseLine = plot(handles.PhasePlot, relativePositions, phase, 'LineStyle', 'none', 'Marker', handles.settings.current.PlotSettings.phaseMarker);
  legendItems = {'Data', 'Fit', 'Best'};
  legend(handles.AmplitudePlot, legendItems{1}, 'Location', 'South');
  legend(handles.PhasePlot, legendItems{1}, 'Location', 'South');
  
  % Account for hysteresis of the stage
  handles.stageController.MinimizeHysteresis(zAxisID, positions(1:2));
  
  % Peform the scan
  focused = false;
  goodToGo = true;
  relativeFocusPosition = relativeZPosition;
  for i = 1:steps
    % Check to see if the user has pressed the cancel button
    if IsCancelling(handles)
      goodToGo = false;
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
  
  if goodToGo
    % Fit the data and look for a maximum in the amplitude
    [coefficients, ~, mu] = polyfit(positions, amplitude, 5);
    fineStepSize = stepSize / 25;
    finePositions = (stagePosition - halfPosition):fineStepSize:(stagePosition + halfPosition);
    fineRelativePositions = (relativeZPosition - halfPosition):fineStepSize:(relativeZPosition + halfPosition);
    evaluatedFit = polyval(coefficients, finePositions, [], mu);
    [~, maxPositionIndex] = max(evaluatedFit);
    maxPosition = finePositions(maxPositionIndex);
    relativeFocusPosition = fineRelativePositions(maxPositionIndex);

    % Move the stage to the ideal position
    if maxPosition > positions(end-2)
      recommendAgain = true;
    elseif maxPosition < positions(3)
      recommendAgain = true;
    else
      recommendAgain = false;
    end

    % Plot the fit
    plot(handles.AmplitudePlot, fineRelativePositions, evaluatedFit, 'LineStyle', handles.settings.current.PlotSettings.fitLineStyle);
    plot(handles.AmplitudePlot, [relativeFocusPosition, relativeFocusPosition], get(handles.AmplitudePlot, 'YLim'));
    legend(handles.AmplitudePlot, legendItems, 'Location', 'South');
    
    % Check with the user to make sure everything looks good
    choices.Again = 'No, Focus Again';
    choices.Good = 'Yes';
    if recommendAgain
      choices.Recommended = choices.Again;
    else
      choices.Recommended = choices.Good;
    end
    response = questdlg({'Do the focus results look good?'},...
                        'Check results from focusing',...
                        choices.Again, choices.Good, choices.Recommended);
    switch response
      case choices.Again
        focused = false;

      case choices.Good
        focused = true;
    end

    % Move the stage to the ideal position
    handles.stageController.MinimizeHysteresis(zAxisID, positions(1:2));
    handles.stageController.MoveAxis(zAxisID, maxPosition);
    handles.stageController.WaitForAction(zAxisID);
  else
    % Move the stages back to their original positions
    handles.stageController.MoveAxis(zAxisID, stagePosition);
  end
  
  % Prepare for the next process to run
  hold(handles.AmplitudePlot, 'off');
  hold(handles.PhasePlot, 'off');
  
  set(handles.IsRunning, 'Value', 0);
end


function isCancelling = IsCancelling(handles)
% Checks to see if the user has requested a cancel operation
 isCancelling = strcmp(get(handles.CancelButton, 'Enable'), 'off');
end


function isClosing = IsClosing(handles)
% Checks to see if the user has requested a close
  isClosing = (get(handles.IsClosing, 'Value') == 1);
end


function isRunning = IsRunning(handles)
% Checks to see if data is being analyzed
  isRunning = (get(handles.IsRunning, 'Value') == 1);
end


function reverse = ReverseDirectionality(axisID, settings)
% Detects whether the user-percieved directions are opposite of the stage
% directions
  reverse = false;
  switch axisID
    case settings.current.LaserController.xAxisID
      reverse = (settings.current.LaserController.reverseX == 1);
      
    case settings.current.LaserController.yAxisID
      reverse = (settings.current.LaserController.reverseY == 1);
  end
end

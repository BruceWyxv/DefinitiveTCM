function varargout = AnalysisProgress(varargin)
%ANALYSISPROGRESS MATLAB code file for Analyze.fig
%      ANALYSISPROGRESS, by itself, creates a new ANALYSISPROGRESS or raises the existing
%      singleton*.
%
%      H = ANALYSISPROGRESS returns the handle to a new ANALYSISPROGRESS or the handle to
%      the existing singleton*.
%
%      ANALYSISPROGRESS('Property','Value',...) creates a new ANALYSISPROGRESS using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to Analyze_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      ANALYSISPROGRESS('CALLBACK') and ANALYSISPROGRESS('CALLBACK',hObject,...) call the
%      local function named CALLBACK in ANALYZE.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Analyze

% Last Modified by GUIDE v2.5 19-Apr-2016 13:36:45

% Begin initialization code - DO NOT EDIT
  gui_Singleton = 1;
  gui_State = struct('gui_Name',       mfilename, ...
                     'gui_Singleton',  gui_Singleton, ...
                     'gui_OpeningFcn', @AnalysisProgress_OpeningFcn, ...
                     'gui_OutputFcn',  @AnalysisProgress_OutputFcn, ...
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


function AnalysisProgress_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<INUSL>
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

  % Choose default command line output for Analyze
  handles.output = hObject;

  % Check the input arguments
  parser = inputParser;
  parser.addParameter('data', '', @isstruct);
  parser.addParameter('preferences', '', @(x) isa(x, 'ConfigurationFile'));
  parser.addParameter('settings', '', @(x) isa(x, 'ConfigurationFile'));
  % Parse the input arguments
  parser.KeepUnmatched = true;
  try
    parser.parse(varargin{:});
  catch me
    error('Error when trying to parse input arguments:   %s', me.message);
  end
  handles.data = parser.Results.data;
  handles.preferences = parser.Results.preferences;
  handles.settings = parser.Results.settings;

  % Set the window position
  setpixelposition(hObject, handles.preferences.current.WindowPositions.analyze);
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

  % Create and initialize the plots
  handles = InitializePlots(handles);

  % Update handles structure
  guidata(hObject, handles);
end


function varargout = AnalysisProgress_OutputFcn(hObject, eventdata, handles) %#ok<INUSL>
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

  % Get default command line output from handles structure
  varargout{1} = handles.output;
end


function AnalysisProgress_CloseRequestFcn(hObject, eventdata, handles) %#ok<DEFNU>
% hObject    handle to AnalysisProgress (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  if isfield(handles, 'preferences') && isvalid(handles.preferences)
    currentPosition = getpixelposition(hObject);
    if ~isequal(currentPosition, handles.preferences.current.WindowPositions.analyze)
      handles.preferences.current.WindowPositions.analyze = currentPosition;
    end
  end
  
  set(handles.IsClosing, 'Value', 1);
  CancelButton_Callback(handles.CancelButton, eventdata, handles);
end


function AnalysisProgress_SizeChangedFcn(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to AnalysisProgress (see GCBO)
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
    % The 'Cancel' button has become a 'Close' buttone, so close the window
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


function Finalize(myself, handles, solutionClass, success, showMessage) %#ok<DEFNU>
% Called when the analysis is over, used to clean things up
  % One final refresh on the plots
  Update(handles, solutionClass);
  uiwaitbar(handles.ProgressBar, 1.0);
  set(handles.ProgressText, 'String', 'Analysis Complete!');
  
  % Set the statuses
  set(handles.IsRunning, 'Value', 0);
  set(handles.CancelButton, 'Enable', 'On');
  set(handles.CancelButton, 'String', 'Close');
  
  % Turn the hold on the plots off
  hold(handles.AmplitudePlot, 'off');
  hold(handles.MinimizationPlot, 'off');
  hold(handles.PhasePlot, 'off');
  
  % Show a message
  if showMessage
    if success
      message = 'The analysis completed succesfully! Click ''OK'' to continue...';
    else
      message = 'The analysis failed! Click ''OK'' to continue...';
    end
    
    uiwait(msgbox(message, 'Analysis', 'modal'));
  end
  
  if IsClosing(handles)
    CloseMe(myself);
  end
end


function handles = InitializePlots(handles)
% Initialize the plots
  % Create the subplots
  handles.AmplitudePlot = subplot(1, 3, 2, 'Parent', handles.PlotsPlaceholder);
  handles.MinimizationPlot = subplot(1, 3, 3, 'Parent', handles.PlotsPlaceholder);
  handles.PhasePlot = subplot(1, 3, 1, 'Parent', handles.PlotsPlaceholder);
  cla(handles.AmplitudePlot);
  cla(handles.MinimizationPlot);
  cla(handles.PhasePlot);
  title(handles.AmplitudePlot, 'Amplitude');
  title(handles.MinimizationPlot, 'Minimization Value');
  title(handles.PhasePlot, 'Phase');
  
  % Increase the size of plots for better use of space
  set(handles.PhasePlot, 'OuterPosition', [0, 0, 1/3, 1.0]);
  set(handles.AmplitudePlot, 'OuterPosition', [1/3, 0, 1/3, 1.0]);
  set(handles.MinimizationPlot, 'OuterPosition', [2/3, 0, 1/3, 1.0]);
  
  % Create the data structures
  [numberOfFrequencies, numberOfSteps] = size(handles.data.positions);
  handles.legendItems = cell(1, numberOfFrequencies * 2);
  handles.amplitudeLines = NaN(numberOfFrequencies, 1);
  handles.phaseLines = NaN(numberOfFrequencies, 1);
  empty = nan(1, numberOfSteps);
  
  % We don't need to do anything else to the minimization plot = it will be
  % dynamically updated as the minimization progresses. However, there are
  % a few things we can do for stabilizing the amplitude and phase plots
  uiwaitbar(handles.ProgressBar, 0);
  set(handles.ProgressText, 'String', '');
  dataColormap = GetColormap(handles.settings.current.PlotSettings.dataColormap, numberOfFrequencies);
  hold(handles.AmplitudePlot, 'on');
  hold(handles.MinimizationPlot, 'on');
  hold(handles.PhasePlot, 'on');
  stepSize = handles.data.positions(1,2) - handles.data.positions(1,1);
  maxPosition = max(max(handles.data.positions));
  minPosition = min(min(handles.data.positions));
  handles.AmplitudePlot.XLim = [(minPosition - stepSize), (maxPosition + stepSize)];
  handles.PhasePlot.XLim = [(minPosition - stepSize), (maxPosition + stepSize)];
  
  % Create all the plots
  handles.minimizationHistory = plot(handles.MinimizationPlot, 1, nan, 'LineStyle', 'none', 'Marker', handles.settings.current.PlotSettings.amplitudeMarker);
  set(handles.MinimizationPlot, 'YScale', 'log');
  legendItems = cell(1, numberOfFrequencies);
  for f = 1:numberOfFrequencies
    plot(handles.AmplitudePlot, handles.data.positions(f,:), handles.data.amplitudes(f,:), 'LineStyle', 'none', 'Marker', handles.settings.current.PlotSettings.amplitudeMarker, 'Color', dataColormap(f,:));
    handles.amplitudeLines(f) = plot(handles.AmplitudePlot, handles.data.positions(f,:), empty, 'LineStyle', handles.settings.current.PlotSettings.fitLineStyle, 'Color', dataColormap(f,:));
    plot(handles.PhasePlot, handles.data.positions(f,:), handles.data.phases(f,:), 'LineStyle', 'none', 'Marker', handles.settings.current.PlotSettings.phaseMarker, 'Color', dataColormap(f,:));
    handles.phaseLines(f) = plot(handles.PhasePlot, handles.data.positions(f,:), empty, 'LineStyle', handles.settings.current.PlotSettings.fitLineStyle, 'Color', dataColormap(f,:));
    legendItems{f} = sprintf('%g kHz', handles.data.frequencies(f) / 1000);
  end
  legend(handles.phaseLines, legendItems{1:f}, 'Location', 'South');
  
  % Set the status
  set(handles.IsRunning, 'Value', 1);
  set(handles.ProgressText, 'String', 'Initializing...');
end


function halt = Update(handles, solutionClass)
% Updates the dialog based on the results of the current iteration
  oldIterations = get(handles.minimizationHistory, 'XData');
  oldGoodnesses = get(handles.minimizationHistory, 'YData');
  iterationHistories = handles.preferences.current.Analysis.iterationHistories;
  iterationHistoryCull = handles.preferences.current.Analysis.iterationHistoryCull;
  iterations = length(oldIterations);
  endIteration = iterations;
  
  if iterations <= iterationHistories
    startIteration = 1;
    endIteration = iterationHistories;
  elseif iterations <= iterationHistories + iterationHistoryCull
    startIteration = iterations - iterationHistories;
  else
    startIteration = iterationHistoryCull;
  end
  if isnan(oldGoodnesses(1))
    newIterations = oldIterations;
    newGoodnesses = solutionClass.chiSquared;
  else
    newIterations = [oldIterations, (iterations + 1)];
    newGoodnesses = [oldGoodnesses, solutionClass.chiSquared];
  end
  set(handles.minimizationHistory, 'XData', newIterations, 'YData', newGoodnesses);
  handles.MinimizationPlot.XLim = [(startIteration - 1), (endIteration + 1)];

  % Update the phase and amplitude plots
  [numberOfFrequencies, ~] = size(handles.data.positions);
  solution = solutionClass.analyticalSolution;
  for f = 1:numberOfFrequencies
    set(handles.amplitudeLines(f), 'YData', solution.amplitudes(f,:));
    set(handles.phaseLines(f), 'YData', solution.phases(f,:));
  end

  % Update, but only at a scheduled rate
  if iterations < 10 ...
     || (iterations < 40 && mod(iterations, 2) == 0) ...
     || (iterations < 100 && mod(iterations, 5) == 0) ...
     || (mod(iterations, 10) == 0)
    % Draw the updates
    drawnow limitrate;
  end
    
  % Update the progress bar
  if iterations > handles.preferences.current.Analysis.initializationHistories
    largestDifference = max(abs([(solutionClass.currentValues - solutionClass.previousValues), (newGoodnesses(end) - newGoodnesses(end - 1))]));
    bottom = log10(handles.settings.current.Analysis.tolerance);
    spread = log10(newGoodnesses(10)) - bottom;
    logProgress = log10(largestDifference);
    linearProgress = (1 - abs(logProgress - bottom) / spread);
    barProgress = uiwaitbar('get', handles.ProgressBar);
    progress = max([linearProgress, barProgress]) + .5 / handles.settings.current.Analysis.maxEvaluations;
    if progress > .999
      progress = .999;
    end
    uiwaitbar(handles.ProgressBar, progress);
    set(handles.ProgressText, 'String', sprintf('%0.1f%% Complete...', progress * 100));
  else
    handles.progressHistory(1) = solutionClass.chiSquared;
    % The 'initialization' phase is worth 25% of the progress
    uiwaitbar(handles.ProgressBar, iterations / (handles.preferences.current.Analysis.initializationHistories * 4));
  end
  guidata(handles.output, handles);
  
  halt = IsCancelling(handles);
end

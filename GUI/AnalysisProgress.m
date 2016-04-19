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
  parser.addParameter('preferences', '', @isstruct);
  parser.addParameter('settings', '', @isstruct);
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
  handles.cancelling = false;

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
  if isfield(handles, 'preferences')
    currentPosition = getpixelposition(hObject);
    if ~isequal(currentPosition, handles.preferences.current.WindowPositions.analyze)
      handles.preferences.current.WindowPositions.analyze = currentPosition;
    end
  end
  
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
 handles.cancelling = true;
 set(hObject, 'Enable', 'Off');
 set(hObject, 'String', 'Cancelling...');
 
 guidata(hObject.Parent, handles);
end


% --------------------------------------------------------------------
% --------------------------------------------------------------------
% --------------------------------------------------------------------
function isCancelling = IsCancelling(handles)
% Checks to see if the user has requested a cancel operation
 isCancelling = strcmp(get(handles.CancelButton, 'Enable'), 'off');
end


function Finalize(handles, solutionClass, iterations, goodnessValues) %#ok<DEFNU>
  Update(handles, solutionClass, iterations, goodnessValues);
  
  hold(handles.AmplitudePlot, 'off');
  hold(handles.PhasePlot, 'off');
end


function handles = InitializePlots(handles)
% Initialize the plots
  % Create the subplots
  handles.AmplitudePlot = subplot(1, 3, 2, 'Parent', handles.PlotsPlaceholder);
  handles.MinimizationPlot = subplot(1, 3, 3, 'Parent', handles.PlotsPlaceholder);
  handles.PhasePlot = subplot(1, 3, 1, 'Parent', handles.PlotsPlaceholder);
  title(handles.AmplitudePlot, 'Amplitude');
  title(handles.MinimizationPlot, 'Minimization Value');
  title(handles.PhasePlot, 'Phase');
  
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
  hold(handles.PhasePlot, 'on');
  stepSize = handles.data.positions(1,2) - handles.data.positions(1,1);
  maxPosition = max(max(handles.data.positions));
  minPosition = min(min(handles.data.positions));
  handles.AmplitudePlot.XLim = [(minPosition - stepSize), (maxPosition + stepSize)];
  handles.PhasePlot.XLim = [(minPosition - stepSize), (maxPosition + stepSize)];
  
  % Create all the plots
  for f = 1:numberOfFrequencies
    plot(handles.AmplitudePlot, handles.data.positions(f,:), handles.data.amplitudes(f,:), 'LineStyle', 'none', 'Marker', handles.settings.current.PlotSettings.amplitudeMarker, 'Color', dataColormap(f));
    handles.amplitudeLines(f) = plot(handles.AmplitudePlot, handles.data.positions(f,:), empty, 'LineStyle', handles.settings.current.PlotSettings.fitLineStyle, 'Color', dataColormap(f));
    plot(handles.PhasePlot, handles.data.positions(f,:), handles.data.phase(f,:), 'LineStyle', 'none', 'Marker', handles.settings.current.PlotSettings.phaseMarker, 'Color', dataColormap(f));
    handles.phaseLines(f) = plot(handles.PhasePlot, handles.data.positions(f,:), empty, 'LineStyle', handles.settings.current.PlotSettings.fitLineStyle, 'Color', dataColormap(f));
  end
end


function halt = Update(handles, solutionClass, iterations, goodnessValues)
% Updates the dialog based on the results of the current iteration
  % TODO update the plots
  
  halt = IsCancelling(handles);
end

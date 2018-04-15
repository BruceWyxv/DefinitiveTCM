function varargout = CrashPrevention(varargin)
% CRASHPREVENTION MATLAB code for CrashPrevention.fig
%      CRASHPREVENTION, by itself, creates a new CRASHPREVENTION or raises the existing
%      singleton*.
%
%      H = CRASHPREVENTION returns the handle to a new CRASHPREVENTION or the handle to
%      the existing singleton*.
%
%      CRASHPREVENTION('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CRASHPREVENTION.M with the given input arguments.
%
%      CRASHPREVENTION('Property','Value',...) creates a new CRASHPREVENTION or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before CrashPrevention_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to CrashPrevention_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help CrashPrevention

% Last Modified by GUIDE v2.5 11-May-2017 19:53:45

  % Begin initialization code - DO NOT EDIT
  gui_Singleton = 1;
  gui_State = struct('gui_Name',       mfilename, ...
                     'gui_Singleton',  gui_Singleton, ...
                     'gui_OpeningFcn', @CrashPrevention_OpeningFcn, ...
                     'gui_OutputFcn',  @CrashPrevention_OutputFcn, ...
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


% --- Executes just before CrashPrevention is made visible.
function CrashPrevention_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<INUSL>
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to CrashPrevention (see VARARGIN)

  % Choose default command line output for CrashPrevention
  handles.output = hObject;

  % Check the input arguments
  parser = inputParser;
  parser.addParameter('preferences', '', @(x) isa(x, 'ConfigurationFile'));
  parser.addParameter('settings', '', @(x) isa(x, 'ConfigurationFile'));
  % Parse the input arguments
  parser.KeepUnmatched = true;
  try
    parser.parse(varargin{:});
  catch me
    error('Error when trying to parse input arguments:   %s', me.message);
  end
  handles.preferences = parser.Results.preferences.current;
  handles.settings = parser.Results.settings.current;
  
  % Set the window position
  movegui(hObject, handles.preferences.WindowPositions.crashPrevention);
  movegui(hObject, 'onscreen');
  
  % Initialize the plot
  handles.profile = plot(handles.Profile, 1, nan, 'LineStyle', '-', 'Marker', 'none');
  xLimits = handles.settings.CrashPrevention.scanWidth / 2.0;
  yLimits = handles.settings.SoftStageBoundaries.z + [-1.0, 1.0];
  set(handles.Profile, 'XLim', [-xLimits, xLimits]);
  set(handles.Profile, 'YLim', yLimits);
  set(handles.Profile, 'YDir', 'reverse');

  % Update handles structure
  guidata(hObject, handles);

  % UIWAIT makes CrashPrevention wait for user response (see UIRESUME)
  % uiwait(handles.CrashPreventionWindow);
end


function varargout = CrashPrevention_OutputFcn(hObject, eventdata, handles)  %#ok<INUSL>
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

  % Get default command line output from handles structure
  varargout{1} = handles.output;
end


function CrashPreventionWindow_CloseRequestFcn(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to CrashPreventionWindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  currentPosition = getpixelposition(hObject);
  
  % Check to see if 'handles' is in a valid state
  if isfield(handles, 'preferences')
    if currentPosition(1:2) ~= handles.preferences.WindowPositions.crashPrevention
      handles.preferences.current.WindowPositions.crashPrevention = currentPosition(1:2);
    end
  end
  
  if IsCancelling(handles)
    delete(hObject);
  end
end



% --------------------------------------------------------------------
% --------------------------------------------------------------------
% --------------------------------------------------------------------
function HaltButton_Callback(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to HaltButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  set(hObject, 'Enable', 'Off');
end



% --------------------------------------------------------------------
% --------------------------------------------------------------------
% --------------------------------------------------------------------
function Close(hObject) %#ok<DEFNU>
% Close the window
  handles = guidata(hObject);
  set(handles.HaltButton, 'Enable', 'Off');
  
  currentPosition = getpixelposition(hObject);
  
  % Check to see if 'handles' is in a valid state
  if isfield(handles, 'preferences')
    if currentPosition(1:2) ~= handles.preferences.WindowPositions.crashPrevention
      handles.preferences.current.WindowPositions.crashPrevention = currentPosition(1:2);
    end
  end
  
  delete(hObject);
end


function isCancelling = IsCancelling(handles)
% Checks to see if the user has requested a cancel operation
 isCancelling = strcmp(get(handles.HaltButton, 'Enable'), 'off');
end


function halt = Update(hObject, x, y, change) %#ok<DEFNU>
% Updates the dialog based on the results of the current iteration
  handles = guidata(hObject);
  
  oldX = get(handles.profile, 'XData');
  oldY = get(handles.profile, 'YData');
  if isnan(oldY)
    newX = [x, x];
    newY = [y, y];
  else
    if change
      newX = [oldX, x];
      newY = [oldY, y];
    else
      newX = oldX;
      newY = oldY;
      index = length(newX);
      newX(index) = x;
    end
  end
  
  set(handles.profile, 'XData', newX, 'YData', newY);
  
  halt = IsCancelling(handles);
end

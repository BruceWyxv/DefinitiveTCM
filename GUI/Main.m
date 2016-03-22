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

% Last Modified by GUIDE v2.5 08-Mar-2016 17:38:07

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


% --- Executes just before Main is made visible.
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
  
  % Get the settings
  handles.settings = ini2struct(handles.settingsFile);
  handles.old.Settings = handles.settings;
  
  % Get user preferences
  handles.preferences = ini2struct(handles.preferencesFile);
  handles.old.Preferences = handles.preferences;
  
  % Get the GUI add-ons
  handles.PositionSampleGUIAddOn = open('Controls_SamplePosition.fig');
  handles.CollectDataGUIAddOn = open('Controls_CollectData.fig');
  
  % Set some defaults
  [rawLED.RedOn, throwaway.map, rawLED.alpha] = imread('Resources/Images/LED-Red-On.png');
  rawLED.RedOff = imread('Resources/Images/LED-Red-Off.png');
  rawLED.GreenOn = imread('Resources/Images/LED-Green-On.png');
  rawLED.GreenOff = imread('Resources/Images/LED-Green-Off.png');
  TCMLogo = 'Resources/Images/TCMLogo.jpg';

  % Make the utilities available throughout this GUI
  handles.images = Images();

  % Load the ON/OFF LED images
  % Composite the alpha channel with the background color, then resize
  backgroundColorRGB = uint8(get(hObject, 'color') * 255);
  handles.LargeLED.RedOn = handles.images.CompositeAlphaOverSolid(rawLED.RedOn, rawLED.alpha, backgroundColorRGB);
  handles.LargeLED.RedOff = handles.images.CompositeAlphaOverSolid(rawLED.RedOff, rawLED.alpha, backgroundColorRGB);
  handles.LargeLED.GreenOn = handles.images.CompositeAlphaOverSolid(rawLED.GreenOn, rawLED.alpha, backgroundColorRGB);
  handles.LargeLED.GreenOff = handles.images.CompositeAlphaOverSolid(rawLED.GreenOff, rawLED.alpha, backgroundColorRGB);
  % Resize the images
  handles.ScaledLED.PositionOn = getpixelposition(handles.LEDOn);
  handles.ScaledLED.PositionOff = getpixelposition(handles.LEDOff);
  if handles.ScaledLED.PositionOn(3) < handles.ScaledLED.PositionOn(4)
    handles.ScaledLED.PositionOn(3) = floor(handles.ScaledLED.PositionOn(3));
    handles.ScaledLED.PositionOn(4) = handles.ScaledLED.PositionOn(3);
    handles.ScaledLED.PositionOff(3) = handles.ScaledLED.PositionOn(3);
    handles.ScaledLED.PositionOff(4) = handles.ScaledLED.PositionOn(3);
  else
    handles.ScaledLED.PositionOn(4) = floor(handles.ScaledLED.PositionOn(4));
    handles.ScaledLED.PositionOn(3) = handles.ScaledLED.PositionOn(4);
    handles.ScaledLED.PositionOff(3) = handles.ScaledLED.PositionOn(4);
    handles.ScaledLED.PositionOff(4) = handles.ScaledLED.PositionOn(4);
  end
  handles.ScaledLED.RedOn = handles.images.Resize(handles.LargeLED.RedOn, 'width', handles.ScaledLED.PositionOn(3), 'height', handles.ScaledLED.PositionOn(4));
  handles.ScaledLED.RedOff = handles.images.Resize(handles.LargeLED.RedOff, 'width', handles.ScaledLED.PositionOff(3), 'height', handles.ScaledLED.PositionOff(4));
  handles.ScaledLED.GreenOn = handles.images.Resize(handles.LargeLED.GreenOn, 'width', handles.ScaledLED.PositionOn(3), 'height', handles.ScaledLED.PositionOn(4));
  handles.ScaledLED.GreenOff = handles.images.Resize(handles.LargeLED.GreenOff, 'width', handles.ScaledLED.PositionOff(3), 'height', handles.ScaledLED.PositionOff(4));

  % Set initial states
  handles.power = false;
  handles = CascadeActionPower(handles);
  imshow(TCMLogo);
%   TODO: Figure out how to get the LEDOff and LEDOn elements to not
%   receive keyboard focus when tabbing to select

  % Update handles structure
  movegui(hObject, 'center');
  guidata(hObject, handles);
end


% --- Outputs from this function are returned to the command line.
function varargout = Main_OutputFcn(hObject, eventdata, handles) %#ok<INUSL>
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

  % Get default command line output from handles structure
  varargout{1} = handles.output;
end


% --- Executes on button press in SystemPower.
function SystemPower_Callback(hObject, eventdata, handles) %#ok<DEFNU,INUSL>
% hObject    handle to SystemPower (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

  % Check the current power status and take the appropriate action
  if handles.power
    handles.power = false;
  else
    handles.power = true;
  end
  handles = CascadeActionPower(handles);
  
  % Update handles structure
  guidata(hObject, handles);
end


% --- Executes on button press in PositionSample.
function PositionSample_Callback(hObject, eventdata, handles) %#ok<DEFNU,INUSL>
% hObject    handle to PositionSample (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  % Open the Controls window with the PositionSample add-on
  % Controls is modal, which means that Main will be blocked until
  % Controls closes.
  [handles.settings, handles.preferences]...
    = Controls('AddOn', handles.PositionSampleGUIAddOn,...
               'Cameras', handles.cameras,...
               'Preferences', handles.preferences,...
               'Settings', handles.settings,...
               'StageController', handles.stageController);
  
  UpdateInitializationFiles(handles);
  
  % Update handles structure
  guidata(hObject, handles);
end


% --- Executes on button press in ToolsAndUtilities.
function ToolsAndUtilities_Callback(hObject, eventdata, handles) %#ok<DEFNU,INUSD>
% hObject    handle to ToolsAndUtilities (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end


% --- Executes on button press in CollectData.
function CollectData_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to CollectData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  [handles.settings, handles.preferences]...
    = Controls('AddOn', handles.CollectDataGUIAddOn,...
               'Cameras', handles.cameras,...
               'Preferences', handles.preferences,...
               'Settings', handles.settings,...
               'StageController', handles.stageController);
  
  UpdateInitializationFiles(handles);
  
  % Update handles structure
  guidata(hObject, handles);
end


% --- Executes on button press in RunAnalysis.
function RunAnalysis_Callback(hObject, eventdata, handles) %#ok<DEFNU,INUSD>
% hObject    handle to RunAnalysis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end


% --- Executes when user attempts to close MainWindow.
function MainWindow_CloseRequestFcn(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to MainWindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  % Check to see if the settings have been modified
  UpdateInitializationFiles(handles);

% Hint: delete(hObject) closes the figure
  delete(hObject);
end

function handles = CascadeActionPower(handles)
% This function changes the states of GUI elements as needed by the current
% power state.
  % Connect to, or disconnect, from the hardware
  try
    if handles.power
      handles.cameras.load = videoinput('matrox', handles.settings.ImageAcquisition.loadDigitizer);
      handles.cameras.wide = videoinput('matrox', handles.settings.ImageAcquisition.wideDigitizer);
      handles.cameras.scan = videoinput('matrox', handles.settings.ImageAcquisition.scanDigitizer);
      handles.cameras.load.SelectedSource = handles.settings.ImageAcquisition.loadChannel;
      handles.cameras.wide.SelectedSource = handles.settings.ImageAcquisition.wideChannel;
      handles.cameras.scan.SelectedSource = handles.settings.ImageAcquisition.scanChannel;
      handles.stageController = ESP300_Control(16, 'Stage Controller');
    else
      handles.cameras.load = '';
      handles.cameras.wide = '';
      handles.cameras.scan = '';
      handles.stageController = '';
    end
  catch me
    warning('Main:PowerOn', me.message);
  end

  % Set the GUI state
  try
    % Get the power state
    if handles.power
      state = 'On';
      antistate = 'Off';
      set(handles.LEDOff, 'CData', handles.ScaledLED.RedOff);
      set(handles.LEDOn, 'CData', handles.ScaledLED.GreenOn);
    else
      state = 'Off';
      antistate = 'On';
      set(handles.LEDOff, 'CData', handles.ScaledLED.RedOn);
      set(handles.LEDOn, 'CData', handles.ScaledLED.GreenOff);
    end
  
    % Set the states of the GUI elements
    set(handles.TextOff, 'Enable', antistate);
    set(handles.TextOn, 'Enable', state);
    set(handles.ToolsAndUtilities, 'Enable', state);
    set(handles.PositionSample, 'Enable', state);
    set(handles.CollectData, 'Enable', state);
    set(handles.RunAnalysis, 'Enable', state);
  catch me
    warning('Main:PowerOn', me.message);
  end
end

function UpdateInitializationFiles(handles)
  % Check to see if the settings have been modified
  if ~isequal(handles.settings, handles.old.Settings);
    struct2ini(handles.settingsFile, handles.settings);
    fprintf('Modified settings detected. Changes have been saved to ''%s''\n', handles.settingsFile);
  end
  
  % Check to see if the preferences have been modified
  if ~isequal(handles.preferences, handles.old.Preferences);
    struct2ini(handles.preferencesFile, handles.preferences);
    fprintf('Modified preferences detected. Changes have been saved to ''%s''\n', handles.preferencesFile);
  end
end

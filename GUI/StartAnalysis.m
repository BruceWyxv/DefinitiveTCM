function varargout = StartAnalysis(varargin)
%STARTANALYSIS MATLAB code file for StartAnalysis.fig
%      STARTANALYSIS, by itself, creates a new STARTANALYSIS or raises the existing
%      singleton*.
%
%      H = STARTANALYSIS returns the handle to a new STARTANALYSIS or the handle to
%      the existing singleton*.
%
%      STARTANALYSIS('Property','Value',...) creates a new STARTANALYSIS using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to StartAnalysis_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      STARTANALYSIS('CALLBACK') and STARTANALYSIS('CALLBACK',hObject,...) call the
%      local function named CALLBACK in STARTANALYSIS.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help StartAnalysis

% Last Modified by GUIDE v2.5 26-Apr-2016 17:30:26

  % Begin initialization code - DO NOT EDIT
  gui_Singleton = 1;
  gui_State = struct('gui_Name',       mfilename, ...
                     'gui_Singleton',  gui_Singleton, ...
                     'gui_OpeningFcn', @StartAnalysis_OpeningFcn, ...
                     'gui_OutputFcn',  @StartAnalysis_OutputFcn, ...
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


% --- Executes just before StartAnalysis is made visible.
function StartAnalysis_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<INUSL>
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

  % Choose default command line output for StartAnalysis
  handles.output = hObject;
  
  % Define the input arguments
  parser = inputParser;
  parser.addParameter('preferences', '');
  parser.addParameter('settings', '');
  
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
  handles.preferences = parser.Results.preferences;
  handles.settings = parser.Results.settings;
  handles.file = handles.preferences.current.CollectData.savePath;
  handles = LoadDatabase(handles, false);
  
  % Initialize the controls and handle values
  % File
  set(handles.FileEdit, 'String', handles.file);
  FileEdit_Callback(handles.FileEdit, [], handles);
  % Film thickness
  handles.filmThickness = handles.preferences.current.Analysis.filmThickness;
  set(handles.FilmThicknessEdit, 'String', sprintf('%g', handles.filmThickness));
  % Set the film material to gold
  handles.filmMaterial = 'filmgold';
  % Model
  handles.models = get(handles.ModelPopup, 'String');
  handles.model = handles.models{handles.preferences.current.Analysis.model};
  index = find(strcmp(handles.models, handles.model), 1);
  set(handles.ModelPopup, 'Value', index);
  % Try and be clever with the sample name to generate the substrate
  [~, handles.substrateName, ~] = fileparts(handles.file);
  % Amplitude weight
  handles.amplitudeWeight = handles.preferences.current.Analysis.amplitudeWeight;
  set(handles.AmplitudeWeightEdit, 'String', sprintf('%g', handles.amplitudeWeight));
  % Magnification
  handles.magnification = handles.preferences.current.Analysis.magnification;
  handles = Refresh(handles);
  
  % Store the tooltip initial states
  handles.tooltips.fileEdit = get(handles.FileEdit, 'TooltipString');

  % Update handles structure
  guidata(hObject, handles);

  % UIWAIT makes StartAnalysis wait for user response (see UIRESUME)
  % uiwait(handles.figure1);
end


% --- Outputs from this function are returned to the command line.
function varargout = StartAnalysis_OutputFcn(hObject, eventdata, handles) %#ok<INUSL>
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

  % Get default command line output from handles structure
  varargout{1} = handles.output;
end



function FileEdit_Callback(hObject, eventdata, handles) %#ok<INUSL>
% hObject    handle to FileEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

  % Hints: get(hObject,'String') returns contents of FileEdit as text
  %        str2double(get(hObject,'String')) returns contents of FileEdit as a double
  handles.file = get(hObject, 'String');
  
  if exist(handles.file, 'file')
    set(handles.FileEdit, 'BackgroundColor', 'white');
    set(handles.StartAnalysisButton, 'Enable', 'On');
    set(handles.FileEdit, 'TooltipString', handles.tooltips.fileEdit);
  else
    set(handles.FileEdit, 'BackgroundColor', [1, 0.4, 0.4]);
    set(handles.StartAnalysisButton, 'Enable', 'Off');
    set(handles.FileEdit, 'TooltipString', 'File does not exist!');
  end
  
  guidata(hObject.Parent, handles);
end


% --- Executes during object creation, after setting all properties.
function FileEdit_CreateFcn(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to FileEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

  % Hint: edit controls usually have a white background on Windows.
  %       See ISPC and COMPUTER.
  if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
  end
end


% --- Executes on button press in BrowseButton.
function BrowseButton_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to BrowseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  filters = {'*.mat', 'Data Files';...
             '*.*', 'All Files'};
  [file, directory, ~] = uigetfile(filters, 'Select Data File...', handles.file);
  file = fullfile(directory, file);
  
  if file ~= 0
    handles.file = file;
    set(handles.FileEdit, 'String', file);
    FileEdit_Callback(handles.FileEdit, [], handles);
    
    guidata(hObject.Parent, handles);
  end
end


% --- Executes on selection change in ModelPopup.
function ModelPopup_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to ModelPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ModelPopup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ModelPopup
  contents = cellstr(get(hObject, 'String'));
  selection = contents{get(hObject, 'Value')};
  handles.model = selection;
  substrate = 'Off';
  
  switch lower(selection)
    case 'film'
      substrate = 'On';
  end
  
  set(handles.SubstratePopup, 'Visible', substrate);
  set(handles.SubstrateText, 'Visible', substrate);
  
  guidata(hObject.Parent, handles);
end


% --- Executes during object creation, after setting all properties.
function ModelPopup_CreateFcn(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to ModelPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

  % Hint: popupmenu controls usually have a white background on Windows.
  %       See ISPC and COMPUTER.
  if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
      set(hObject, 'BackgroundColor', 'white');
  end
end


% --- Executes on selection change in SubstratePopup.
function SubstratePopup_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to SubstratePopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

  % Hints: contents = cellstr(get(hObject,'String')) returns SubstratePopup contents as cell array
  %        contents{get(hObject,'Value')} returns selected item from SubstratePopup
  contents = cellstr(get(hObject, 'String'));
  handles.substrateName = contents{get(hObject, 'Value')};
  
  guidata(hObject.Parent, handles);
end


% --- Executes during object creation, after setting all properties.
function SubstratePopup_CreateFcn(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to SubstratePopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

  % Hint: popupmenu controls usually have a white background on Windows.
  %       See ISPC and COMPUTER.
  if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
  end
end



function AmplitudeWeightEdit_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to AmplitudeWeightEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

  % Hints: get(hObject,'String') returns contents of AmplitudeWeightEdit as text
  %        str2double(get(hObject,'String')) returns contents of AmplitudeWeightEdit as a double
  entry = get(hObject, 'String');
  value = sscanf(entry, '%g', 1);
  clean = sprintf('%g', value);
  set(hObject, 'String', clean);
  
  % Set the data
  handles.amplitudeWeight = value;
  guidata(hObject.Parent, handles);
end


% --- Executes during object creation, after setting all properties.
function AmplitudeWeightEdit_CreateFcn(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to AmplitudeWeightEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

  % Hint: edit controls usually have a white background on Windows.
  %       See ISPC and COMPUTER.
  if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
  end
end


% --- Executes on selection change in MagnificationPopup.
function MagnificationPopup_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to MagnificationPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

  % Hints: contents = cellstr(get(hObject,'String')) returns MagnificationPopup contents as cell array
  %        contents{get(hObject,'Value')} returns selected item from MagnificationPopup'
  handles.magnification = handles.magnifications(get(hObject, 'Value'));
  
  guidata(hObject.Parent, handles);
end


% --- Executes during object creation, after setting all properties.
function MagnificationPopup_CreateFcn(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to MagnificationPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

  % Hint: popupmenu controls usually have a white background on Windows.
  %       See ISPC and COMPUTER.
  if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
  end
end


% --- Executes on button press in RefreshDatabaseButton.
function RefreshDatabaseButton_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to RefreshDatabaseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  handles = LoadDatabase(handles, true);
  handles = Refresh(handles);
  guidata(hObject.Parent, handles);
end


% --- Executes on button press in EditDatabaseButton.
function EditDatabaseButton_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to EditDatabaseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  handles.database.Edit();
end


% --- Executes on button press in StartAnalysisButton.
function StartAnalysisButton_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to StartAnalysisButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  % Disable all controls
  elements = findall(hObject.Parent, '-property', 'Enable');
  set(elements, 'Enable', 'Off');
  
  % Perform an analysis
  results = FitTCMData(handles.file,...
                       handles.filmMaterial,...
                       handles.filmThickness,...
                       'AnalysisModel', handles.model,...
                       'AmplitudeWeight', handles.amplitudeWeight,...
                       'Magnification', handles.magnification,...
                       'Preferences', handles.preferences,...
                       'Settings', handles.settings,...
                       'SubstrateName', handles.substrateName);
  
  % Enable all controls
  set(elements, 'Enable', 'On')
end



function FilmThicknessEdit_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to FilmThicknessEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

  % Hints: get(hObject,'String') returns contents of FilmThicknessEdit as text
  %        str2double(get(hObject,'String')) returns contents of FilmThicknessEdit as a double
  % Sanitize the contents
  entry = get(hObject, 'String');
  value = sscanf(entry, '%g', 1);
  clean = sprintf('%g', value);
  set(hObject, 'String', clean);
  
  % Set the data
  handles.filmThickness = value;
  guidata(hObject.Parent, handles);
end


% --- Executes during object creation, after setting all properties.
function FilmThicknessEdit_CreateFcn(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to FilmThicknessEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

  % Hint: edit controls usually have a white background on Windows.
  %       See ISPC and COMPUTER.
  if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
  end
end


% --- Executes on selection change in FilmMaterialPopup.
function FilmMaterialPopup_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to FilmMaterialPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

  % Hints: contents = cellstr(get(hObject,'String')) returns FilmMaterialPopup contents as cell array
  %        contents{get(hObject,'Value')} returns selected item from FilmMaterialPopup
  contents = cellstr(get(hObject,'String'));
  handles.filmMaterial = contents{get(hObject,'Value')};
  
  guidata(hObject.Parent, handles);
end


% --- Executes during object creation, after setting all properties.
function FilmMaterialPopup_CreateFcn(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to FilmMaterialPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

  % Hint: popupmenu controls usually have a white background on Windows.
  %       See ISPC and COMPUTER.
  if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
  end
end


% --------------------------------------------------------------------
% --------------------------------------------------------------------
% --------------------------------------------------------------------
function handles = LoadDatabase(handles, forceRefresh)
% Loads the database
  handles.database = Database();
  
  if forceRefresh
    handles.database.ReloadMagnifications();
    handles.database.ReloadMaterials();
  end
  
  handles.materials = handles.database.ListMaterials();
end


function handles = Refresh(handles)
% Refreshes the contents of the popup controls
  % Film material
  set(handles.FilmMaterialPopup, 'String', handles.materials);
  index = find(strcmp(handles.materials, handles.filmMaterial), 1);
  set(handles.FilmMaterialPopup, 'Value', index);
  
  % Substrate material
  set(handles.SubstratePopup, 'String', handles.materials);
  index = find(strcmp(handles.materials, handles.substrateName), 1);
  if isempty(index)
    handles.substrateName = 'pyrex';
    index = find(strcmp(handles.materials, handles.substrateName), 1);
  end
  set(handles.SubstratePopup, 'Value', index);
  
  % Magnifications
  handles.magnifications = handles.database.ListMagnifications();
  set(handles.MagnificationPopup, 'String', arrayfun(@num2str, handles.magnifications, 'unif', 0));
  index = find(handles.magnifications == handles.magnifications, 1);
  set(handles.MagnificationPopup, 'Value', index);
end

function varargout = Controls_CollectData(varargin)
%CONTROLS_COLLECTDATA M-file for Controls_CollectData.fig
%      CONTROLS_COLLECTDATA, by itself, creates a new CONTROLS_COLLECTDATA or raises the existing
%      singleton*.
%
%      H = CONTROLS_COLLECTDATA returns the handle to a new CONTROLS_COLLECTDATA or the handle to
%      the existing singleton*.
%
%      CONTROLS_COLLECTDATA('Property','Value',...) creates a new CONTROLS_COLLECTDATA using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to Controls_CollectData_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      CONTROLS_COLLECTDATA('CALLBACK') and CONTROLS_COLLECTDATA('CALLBACK',hObject,...) call the
%      local function named CALLBACK in CONTROLS_COLLECTDATA.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Controls_CollectData

% Last Modified by GUIDE v2.5 17-Mar-2016 10:35:49

  % Begin initialization code - DO NOT EDIT
  gui_Singleton = 1;
  gui_State = struct('gui_Name',       mfilename, ...
                     'gui_Singleton',  gui_Singleton, ...
                     'gui_OpeningFcn', @Controls_CollectData_OpeningFcn, ...
                     'gui_OutputFcn',  @Controls_CollectData_OutputFcn, ...
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


function Controls_CollectData_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<INUSD>
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)
end


function varargout = Controls_CollectData_OutputFcn(hObject, eventdata, handles) %#ok<INUSL>
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
function SampleNameEdit_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to SampleNameEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SampleNameEdit as text
%        str2double(get(hObject,'String')) returns contents of SampleNameEdit as a double
  CheckPath(handles);
end


function SampleNameEdit_CreateFcn(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to SampleNameEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

  % Hint: edit controls usually have a white background on Windows.
  %       See ISPC and COMPUTER.
  if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
  end
end


function SaveFolderEdit_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to SaveFolderEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SaveFolderEdit as text
%        str2double(get(hObject,'String')) returns contents of SaveFolderEdit as a double
  handles.saveFolder = get(hObject, 'String');
  guidata(hObject,handles);
  
  CheckPath(handles);
end


function SaveFolderEdit_CreateFcn(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to SaveFolderEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

  % Hint: edit controls usually have a white background on Windows.
  %       See ISPC and COMPUTER.
  if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
  end
end


function RunScanButton_Callback(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to RunScanButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end


function SaveFolderBrowseButton_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to SaveFolderBrowseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  saveFolder = uigetdir(handles.saveFolder, 'TCM Save Directory:');
  
  if saveFolder ~= 0
    handles.saveFolder = saveFolder;
    set(handles.SaveFolderEdit, 'String', handles.saveFolder);
  
    CheckPath(handles);

    guidata(hObject,handles);
  end
end


function SampleInfoButton_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to SampleInfoButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  sampleInfo = inputdlg({'Enter sample details:'}, 'Sample Information', 8, handles.sampleInfo);
  if ~isempty(sampleInfo)
    handles.sampleInfo = sampleInfo;
  end
  
  guidata(hObject,handles);
end


% --------------------------------------------------------------------
% --------------------------------------------------------------------
% --------------------------------------------------------------------
function CheckPath(handles)
% Checks the current path of the save file. If there is an error then the
% appropriate edit box is given a light red background. Otherwise the edit
% boxes are set to a white background.
  persistent fileUtilities;
  
  if isempty(fileUtilities)
    fileUtilities = Files();
  end
  
  if exist(handles.saveFolder, 'dir') ~= 7
    % The folder does not exist, change the background color of the
    % SaveFolder edit box to indicate an error
    set(handles.SaveFolderEdit, 'BackgroundColor', [1, 0.4, 0.6]);
  else
    % All clear
    set(handles.SaveFolderEdit, 'BackgroundColor', 'white');
    
    if exist(files.GetFileName(handles.saveFolder, handles.sampleName), 'file')
      % The file already exists, change the background color of the
      % SampleName edit box to indicate an error
      set(handles.SampleNameEdit, 'BackgroundColor', [1, 0.4, 0.6]);
    else
      % All clear
      set(handles.SampleNameEdit, 'BackgroundColor', 'white');
    end
  end
end

function InitializeChildren(hObject, handles) %#ok<DEFNU>
% Initializes the states of any child controls, called by the main
% ControlsGUI
  [handles.saveFolder, handles.sampleName, ~] = fileparts(handles.preferences.CollectData.savePath);
  set(handles.SaveFolderEdit, 'String', handles.saveFolder);
  set(handles.SampleNameEdit, 'String', handles.sampleName);
  
  CheckPath(handles);
  
  guidata(hObject, handles);
end

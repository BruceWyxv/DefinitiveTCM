function varargout = StartAnalysis_Settings(varargin)
%STARTANALYSIS_SETTINGS MATLAB code file for StartAnalysis_Settings.fig
%      STARTANALYSIS_SETTINGS, by itself, creates a new STARTANALYSIS_SETTINGS or raises the existing
%      singleton*.
%
%      H = STARTANALYSIS_SETTINGS returns the handle to a new STARTANALYSIS_SETTINGS or the handle to
%      the existing singleton*.
%
%      STARTANALYSIS_SETTINGS('Property','Value',...) creates a new STARTANALYSIS_SETTINGS using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to StartAnalysis_Settings_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      STARTANALYSIS_SETTINGS('CALLBACK') and STARTANALYSIS_SETTINGS('CALLBACK',hObject,...) call the
%      local function named CALLBACK in STARTANALYSIS_SETTINGS.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help StartAnalysis_Settings

% Last Modified by GUIDE v2.5 16-May-2016 14:53:05

  % Begin initialization code - DO NOT EDIT
  gui_Singleton = 1;
  gui_State = struct('gui_Name',       mfilename, ...
                     'gui_Singleton',  gui_Singleton, ...
                     'gui_OpeningFcn', @StartAnalysis_Settings_OpeningFcn, ...
                     'gui_OutputFcn',  @StartAnalysis_Settings_OutputFcn, ...
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


function StartAnalysis_Settings_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<INUSL>
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

  % Choose default command line output for StartAnalysis_Settings
  handles.output = hObject;
  
  % Define the input arguments
  parser = inputParser;
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
  handles.originalSettings = parser.Results.settings;
  handles.settings = handles.originalSettings.current.Analysis;
  
  % Initialize the values
  set(handles.IntegrationStepsEdit, 'String', Num2Engr(handles.settings.integrationSteps));
  set(handles.IntegrationWidthEdit, 'String', Num2Engr(handles.settings.integrationWidth));
  set(handles.MaximumEvaluationsEdit, 'String', Num2Engr(handles.settings.maximumEvaluations));
  set(handles.OffsetLimitEdit, 'String', Num2Engr(handles.settings.frequencyOffsetLimit));
  set(handles.ScanScaleEdit, 'String', Num2Engr(handles.settings.scanScaling));
  set(handles.SkipErrorAnalysisCheckbox, 'Value', handles.settings.skipErrorAnalysis);
  set(handles.ToleranceEdit, 'String', Num2Engr(handles.settings.tolerance));

  % Update handles structure
  guidata(hObject, handles);

  % UIWAIT makes StartAnalysis_Settings wait for user response (see UIRESUME)
  % uiwait(handles.figure1);
end


function varargout = StartAnalysis_Settings_OutputFcn(hObject, eventdata, handles) %#ok<INUSL>
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
  close(hObject.Parent);
end


function IntegrationStepsEdit_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to IntegrationStepsEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

  % Hints: get(hObject,'String') returns contents of IntegrationStepsEdit as text
  %        str2double(get(hObject,'String')) returns contents of IntegrationStepsEdit as a double
  [clean, value] = CleanNumberString(get(hObject, 'String'));
  set(hObject, 'String', clean);
  
  % Save the changes
  handles.settings.integrationSteps = value;
  guidata(hObject.Parent, handles);
end


function IntegrationStepsEdit_CreateFcn(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to IntegrationStepsEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

  % Hint: edit controls usually have a white background on Windows.
  %       See ISPC and COMPUTER.
  if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
  end
end


function IntegrationWidthEdit_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to IntegrationWidthEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

  % Hints: get(hObject,'String') returns contents of IntegrationWidthEdit as text
  %        str2double(get(hObject,'String')) returns contents of IntegrationWidthEdit as a double
  [clean, value] = CleanNumberString(get(hObject, 'String'));
  set(hObject, 'String', clean);
  
  % Save the changes
  handles.settings.integrationWidth = value;
  guidata(hObject.Parent, handles);
end


function IntegrationWidthEdit_CreateFcn(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to IntegrationWidthEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

  % Hint: edit controls usually have a white background on Windows.
  %       See ISPC and COMPUTER.
  if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
  end
end


function MaximumEvaluationsEdit_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to MaximumEvaluationsEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

  % Hints: get(hObject,'String') returns contents of MaximumEvaluationsEdit as text
  %        str2double(get(hObject,'String')) returns contents of MaximumEvaluationsEdit as a double
  [clean, value] = CleanNumberString(get(hObject, 'String'));
  set(hObject, 'String', clean);
  
  % Save the changes
  handles.settings.maximumEvaluations = value;
  guidata(hObject.Parent, handles);
end


function MaximumEvaluationsEdit_CreateFcn(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to MaximumEvaluationsEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

  % Hint: edit controls usually have a white background on Windows.
  %       See ISPC and COMPUTER.
  if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
  end
end


function OffsetLimitEdit_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to OffsetLimitEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

  % Hints: get(hObject,'String') returns contents of OffsetLimitEdit as text
  %        str2double(get(hObject,'String')) returns contents of OffsetLimitEdit as a double
  [clean, value] = CleanNumberString(get(hObject, 'String'));
  set(hObject, 'String', clean);
  
  % Save the changes
  handles.settings.frequencyOffsetLimit = value;
  guidata(hObject.Parent, handles);
end


function OffsetLimitEdit_CreateFcn(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to OffsetLimitEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

  % Hint: edit controls usually have a white background on Windows.
  %       See ISPC and COMPUTER.
  if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
  end
end


function OKButton_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to OKButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  handles.originalSettings.current.Analysis = handles.settings;
  close(hObject.Parent);
end


function ScanScaleEdit_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to ScanScaleEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

  % Hints: get(hObject,'String') returns contents of ScanScaleEdit as text
  %        str2double(get(hObject,'String')) returns contents of ScanScaleEdit as a double
  [clean, value] = CleanNumberString(get(hObject, 'String'));
  set(hObject, 'String', clean);
  
  % Save the changes
  handles.settings.scanScaling = value;
  guidata(hObject.Parent, handles);
end


function ScanScaleEdit_CreateFcn(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to ScanScaleEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

  % Hint: edit controls usually have a white background on Windows.
  %       See ISPC and COMPUTER.
  if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white')
  end
end


function SkipErrorAnalysisCheckbox_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to SkipErrorAnalysisCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

  % Hint: get(hObject,'Value') returns toggle state of SkipErrorAnalysisCheckbox
  handles.settings.skipErrorAnalysis = get(hObject, 'Value');
  
  % Save the changes
  guidata(hObject.Parent, handles);
end


function SkipErrorAnalysisCheckbox_CreateFcn(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to SkipErrorAnalysisCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
end


function ToleranceEdit_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
% hObject    handle to ToleranceEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

  % Hints: get(hObject,'String') returns contents of ToleranceEdit as text
  %        str2double(get(hObject,'String')) returns contents of ToleranceEdit as a double
  [clean, value] = CleanNumberString(get(hObject, 'String'));
  set(hObject, 'String', clean);
  
  % Save the changes
  handles.settings.tolerance = value;
  guidata(hObject.Parent, handles);
end


function ToleranceEdit_CreateFcn(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to ToleranceEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

  % Hint: edit controls usually have a white background on Windows.
  %       See ISPC and COMPUTER.
  if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
  end
end

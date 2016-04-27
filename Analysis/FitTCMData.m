function results = FitTCMData(dataFilePath, filmName, filmThickness, varargin)
% Syntax:       results = FitTCMData(<inputs>)
%
% Description:  This function is adapted from the sequence of files used to
%               fit data generated by the TCM to extract thermal properties
%               of the sample material. The author of these original files
%               is Dave Hurley (david.hurley@inl.gov):
%                   parmerror2.m loaddata.m TWM.m
%
%               The purpose is to develop a computational method, using 2D
%               Fourier transforms, that will perform a minimization on the
%               data for an isotropic or anisotropic material.
%
%               The data are taken from a '.mat' file, generated by the
%               DefinitiveTCM package. This file contains a single
%               structure that stores all the data and experiment
%               parameters.
%
% Inputs:
%   * Indicates a key-value argument
%               1) Path to the data file
%               2) Name of film material, as it appears in Database.m
%               3) Film thickness, in m
%               * AnalysisModel     (default = 'Fast')
%                   Specifies which parameters should be minimized and
%                   included in the output:
%                       Fast = ks, Ds, Re
%                       Film = kf, Df, Re, Rth
%                       Full = ks, Ds, Re, Rth
%                   Notes:
%                       1) 'Fast' will cap the maximum frequency at 50 kHz
%                       2) Only 'Full' will perform any anisotropic fits
%               * AmplitudeWeight   (default = <value from settings>)
%                   Weight, relative to the phase, that will be applied for
%                   fitting the amplitude. A value of 0 will not use any
%                   weighting on the amplitude at all. A value of 1 will
%                   give the amplitude just as much weight as the phase.
%                   Note that this requires a scaling of the
%                   goodness-of-fit on the amplitude values, as the
%                   amplitudes are normalized. A value larger than 1 may be
%                   used, but recognize that it will give undue emphasis to
%                   fitting the amplitude. Values less than zero will be
%                   assumed to be zero.
%               * Magnification     (default = <value in data>)
%                   Magnification of the objective used when collecting
%                   data
%               * Preferences       (default: load 'Resources/Preferences.ini')
%                   Handle to preferences configuration class
%               * Settings          (default: load 'Resources/Settings.ini')
%                   Handle to settings configuration class
%               **** Note: If the defaults are used for both Preferences
%                    and Settings, then FitTCMData will assume that it has
%                    been started in independent mode and will force a save
%                    and close of these files when it has finished.
%               * SubstrateName     (default = <data file name>)
%
% Outputs:      results
%               A structure containing the following fields, depending on
%               the input arguments and requested analysis modes:
%                 ks:     thermal conductivity of the substrate
%                 ds:     thermal diffusivity of the substrate
%                 rth:    thermal (Kapitza) resistance at the
%                         film-substrate interface
%                 spot:   convolved spotsize of the pump and probe lasers
%                 kf:     thermal conductivity of the film
%                 df:     thermal diffusivity of the film
%                 ks2D:   anisotropic thermal conductivity of the substrate
%                         in the second direction
%                 ds2D:   anisotropic thermal diffusivity of the substrate
%                         in the second direction
%
% File:         FitThermalAnisotropy.m Author:       Brycen Wendt
% (brycen.wendt@inl.gov; wendbryc@isu.edu) Date Created: 09/30/2015
  % Get the databases and utilities
  database = Database();

  % Define the input arguments
  parser = inputParser;
  parser.addRequired('dataFilePath', @(x) ischar(x) && exist(x, 'file'));
  parser.addRequired('filmName', @ischar);
  parser.addRequired('filmThickness', @isnumeric);
  parser.addParameter('analysisModel', 'Fast', @ischar);
  parser.addParameter('amplitudeWeight', -1, @isnumeric);
  parser.addParameter('magnification', -1, @isnumeric);
  parser.addParameter('preferences', '');
  parser.addParameter('settings', '');
  parser.addParameter('substrateName', '', @ischar);

  % Check the input arguments
  parser.KeepUnmatched = true;
  try
    parser.parse(dataFilePath, filmName, filmThickness, varargin{:});
  catch me
    error('Error when trying to parse input arguments:   %s', me.message);
  end
  if ~isempty(fieldnames(parser.Unmatched))
    warning('MATLAB:unknownArgument', 'Some arguments were not recognized:');
    disp(parser.Unmatched);
  end

  % Assign additional values
  analysisModel = parser.Results.analysisModel;
  amplitudeWeight = parser.Results.amplitudeWeight;
  magnification = parser.Results.magnification;
  configManager = ConfigurationFileManager.GetInstance();
  if isempty(parser.Results.preferences)
    preferencesProvided = false;
    preferences = configManager.GetConfigurationFile('Resources/Preferences.ini');
  else
    preferencesProvided = true;
    preferences = parser.Results.preferences;
  end
  if isempty(parser.Results.settings)
    settingsProvided = false;
    settings = configManager.GetConfigurationFile('Resources/Settings.ini');
  else
    settingsProvided = true;
    settings = parser.Results.settings;
  end
  substrateName = parser.Results.substrateName;
  
  % Check for the default amplitude weight
  if amplitudeWeight == -1
    amplitudeWeight = settings.current.Analysis.amplitudeWeight;
  end
  % Ensure that we always have a non-negative value
  if amplitudeWeight < 0
    amplitudeWeight = 0;
  end

  % Ensure the file is valid
  [directory, fileName, ~] = fileparts(dataFilePath);
  % Validate the directory
  if ~exist(directory, 'dir');
    error('Specified data directory ''%s'' does not exist!', directory);
  end
  % Validate the file
  if ~exist(dataFilePath, 'file')
    error('Specified scan data file ''%s'' does not exist!', fileName);
  end
  
  % Load the data
  data = load(dataFilePath);
  
  % Provide backwards-compatibility
  if ~isfield(data, 'anisotropic') || data.anisotropic == true
    data.anisotropic = false;
  end
  if ~isfield(data, 'magnification')
    if magnification > 0
      data.magnification = magnification;
    else
      data.magnification = preferences.current.Analysis.magnification;
    end
  end

  % Get the initial properties
  filmProperties = database.GetThermalProperties(filmName);
  if isempty(substrateName)
    substrateName = fileName;
  end
  substrateFound = false;
  try
    % Try to get the substrate properties based on the provided name
    substrateProperties = database.GetThermalProperties(substrateName);
    substrateFound = true;
  catch
    % Nothing found so seed the properties with the values for pyrex, a
    % good middle-of-the-road material for the range of the TCm
    substrateProperties = database.GetThermalProperties('pyrex');
  end
  
  % Define the parameters. Not all will be required for each fitting
  % routine
  initialValues = zeros(1,8);
  initialValues(FitProperties.SubstrateConductivity) = substrateProperties.k;
  initialValues(FitProperties.SubstrateDiffusivity) = substrateProperties.d;
  initialValues(FitProperties.FilmConductivity) = filmProperties.k;
  initialValues(FitProperties.FilmDiffusivity) = filmProperties.d;
  initialValues(FitProperties.KapitzaResistance) = preferences.current.Analysis.kapitzaResistance;
  initialValues(FitProperties.SpotSize) = database.GetSpotSizeFromMagnification(data.magnification);
  fitMask = false(1,8);
  fitMask(FitProperties.SpotSize) = true; % We always fit the spot size
  
  % Select the requested fit, and identify which seed values will be fit
  switch lower(analysisModel)
    case 'fast'
      fitMask(FitProperties.SubstrateConductivity) = true;
      fitMask(FitProperties.SubstrateDiffusivity) = true;
      % Cull the data
      allowedFrequencies = data.frequencies <= 50e3;
      data.frequencies = data.frequencies(allowedFrequencies);
      data.amplitudes = data.amplitudes(allowedFrequencies,:);
      data.phases = data.phases(allowedFrequencies,:);
      
    case 'film'
      if ~substrateFound
        error('The substrate material must be defined in the materials database in order to perform an analysis of the film material');
      end
      fitMask(FitProperties.FilmConductivity) = true;
      fitMask(FitProperties.FilmDiffusivity) = true;
      fitMask(FitProperties.KapitzaResistance) = true;
      
    case 'full'
      fitMask(FitProperties.SubstrateConductivity) = true;
      fitMask(FitProperties.SubstrateDiffusivity) = true;
      fitMask(FitProperties.KapitzaResistance) = true;

      % Are we running an anisotropic fit?
      if data.anisotropic
        % Enable the fit on the anisotropic parameters and set the initial
        % values
        fitMask(FitProperties.SubstrateAnisoConductivity) = true;
        fitMask(FitProperties.SubstrateAnisoDiffusivity) = true;
        initialValues(FitProperties.SubstrateAnisoConductivity) = substrateProperties.k;
        initialValues(FitProperties.SubstrateAnisoDiffusivity) = substrateProperties.d;
      end
      
    otherwise
      error('The analysis model ''%s'' does not exists.', analysisModel);
  end
  
  % Set up and run the analysis
  analyzer = ThermalWaveNumbers(data,...
                                filmThickness,...
                                amplitudeWeight,...
                                fitMask,...
                                preferences,...
                                settings,...
                                initialValues);
  [allProperties, fittedPropertiesMask, chiSquared, fminsearchOutput] = analyzer.Run();
  results.allProperties = allProperties;
  results.fittedPropertiesMask = fittedPropertiesMask;
  results.chiSquared = chiSquared;
  results.fminsearchOutput = fminsearchOutput;
  
  % Clean up
  if preferencesProvided == false && settingsProvided == false
    configManager.delete();
  end
end

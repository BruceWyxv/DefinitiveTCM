% File:         Database.m
% Author:       Brycen Wendt (brycen.wendt@inl.gov; wendbryc@isu.edu)
% Date Created: 09/??/2015
%
% Usage:        handle        = Database()
%               spotSize      = <handle>.GetSpotSizeFromMagnification(<mag>)
%               thermalProps  = <handle>.GetThermalProperties(<material>)
%               materials     = <handle>.ListMaterials()
% Inputs:       <handle>        Object handle to the database object
%               <mag>           Magnification of the optical lens
%               <material>      String name of material
%               <thermalProps>  Structure of material, k, d, and rho
% Outputs:      handle          Object handle to the database object
%               materials       A cell array of material names
%               spotSize        Size of the focused laser beam
%               thermalProps    Structure of material, k, d, and rho
%
% Description:  This file is used to gather and organize any types of data that
%               lend themselves to being stored and retrieved from a single
%               location. These include often-used values, tabluated data,
%               etc...
%
%               A database handle can be used to help make any utilizing code
%               more readable. However, the database access functions can be
%               called either with or without the database handle.
%
%               The format of the data should be straightforward. Thus, adding
%               and future values to the database should likewise be simple.
%

function handle = Database()
% Assign the function handles
  handle.GetDatabaseFile = @GetDatabaseFile;
  handle.GetSpotSizeFromMagnification = @GetSpotSizeFromMagnification;
  handle.GetThermalProperties = @GetThermalProperties;
  handle.ListMaterials = @ListMaterials;
end


function databaseFile = GetDatabaseFile()
% Name/path of the file containing the database
  databaseFile = 'Database.xlsx';
end


function spotSize = GetSpotSizeFromMagnification(magnification)
% Return the minimal laser spot size as a function of the optical lens
% magnification
  
  % Ensure the data is loaded
  ReadMagnificationsToGlobal();
  globalDatabase = GlobalDatabase();
  database = globalDatabase.magnifications;

  % Ensure the input argument is valid
  if ~isnumeric(magnification)
    error('Incorrect input type: %s\nInput must be a number!\n', class(material));
  end

  % Search for the requested value
  spotSize = database.spotsize(database.magnification == magnification);

  % Check search results
  if isempty(spotSize)
    error('Magnification ''%0.2f'' not found in database.\nPlease try another magnification.\nAlternatively, add ''%0.2f'' and its correlated spot size to "%s"\n', magnification, magnification, GetDatabaseFile());
  end
end


function thermalProperties = GetThermalProperties(materialName)
% Return the thermal properties of the specified material
%
% The database uses the minimum number of characters required to uniquely
% identify a material. For example, for the set {Au, Ag, Pb} the minimum
% unique character length is 2 since a length of 1 cannot determine if
% 'Au' or 'Ag' is intended. However, the set {James, Billy, Rodger} has a
% minimum character length of 1 since all the items begin with a unique
% character.
%
% The database will return a values for any input argument that matches a
% material in the database. However, the behavior may be undefined if the
% length of the input argument is less than the unique character string. For
% example, if the database were to contain items {Howard, Homer, Hobbs} and
% the input argument were 'Ho' then a value would definitely be returned.
% However, no guarantee is made as to which item will be selected. All
% three are valid options, and it merely depends on which element is found
% first.

  % Do not reinitialize the data if unneeded
  uniqueLength = ReadMaterialsToGlobal();
  globalDatabase = GlobalDatabase();
  properties = Properties();
  database = globalDatabase.materials;

  % Validate the input
  if ~ischar(materialName)
    error('Incorrect input type: %s\nInput must be a string!\n', class(materialName));
  end

  % Search the database for the requested material
  compareLength = length(materialName);
  match = table2struct(database(strncmpi(database.material, materialName, compareLength),:));

  % Check search results
  if isempty(match)
    error('Material ''%s'' not found in database.\nPlease try another material name.\nAlternatively, add ''%s'' and its properties to "%s"\n', materialName, materialName, GetDatabaseFile());
  elseif length(materialName) < uniqueLength
    warning('MATLAB:ambiguousSyntax', 'Length of provided material name is smaller that the minimum length required to uniquely identify a material.');
    if (length(match) > 1)
      match = match(1);
      warning('MATLAB:ambiguousSyntax', 'Uniqueness check: %s selected', match.name);
    end
  end
  
  % Caclualte some additional properties
  thermalProperties = match;
  thermalProperties.specificHeat = properties.GetSpecificHeat(thermalProperties);
end


function materials = ListMaterials()
% Lists all the materials stored in the database
  ReadMaterialsToGlobal();
  globalDatabase = GlobalDatabase();
  database = globalDatabase.materials;
  
  materials = database.material;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Private functions not exposed outside this .m file %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function getDatabase = GlobalDatabase(varargin)
% Create a global database that everything accesses
  persistent globalDatabase;
  
  if nargin && nargout
    error('Cannot both set and get the global database!');
  elseif nargin == 1
    globalDatabase = varargin{1};
  elseif nargout == 1
    getDatabase = globalDatabase;
  elseif ~nargin && ~nargout
    warning('MATLAB:ambiguousSyntax', 'Nothing to do.');
  elseif nargin > 1
    error('Only one input argument accepted!');
  elseif nargout > 1
    warning('MATLAB:ambiguousSyntax', 'Only one output argument provided!');
  end
end


function ReadMagnificationsToGlobal()
% Reads the magnifications to the global database
  globalDatabase = GlobalDatabase();
  
  % Do not reinitialze the data if unneeded
  if ~isfield(globalDatabase, 'magnifications')
    % Read the data and set the global database
    magnifications = readtable(GetDatabaseFile(), 'Sheet', 'Magnification');
    globalDatabase.magnifications = magnifications;
    GlobalDatabase(globalDatabase);
    
    % Process the database
    fprintf('Magnification database loaded from "%s"\n', GetDatabaseFile());
    fprintf('\tNumber of correlations found:   \t%i\n', height(magnifications));
  end
end


function uniqueLength = ReadMaterialsToGlobal()
% Read the materials to the global database
  globalDatabase = GlobalDatabase();
  
  % Do not reinitialze the data if unneeded
  if ~isfield(globalDatabase, 'materials')
    % Read the data
    materials = readtable(GetDatabaseFile(), 'Sheet', 'Materials');

    % Process the database
    strings = Strings();
    [uniqueLength, shortestLength] = strings.GetSmallestUniqueIdentifier(materials.material);
    fprintf('Materials database loaded from "%s"\n', GetDatabaseFile());
    fprintf('\tNumber of materials found:   \t%i\n', height(materials));
    fprintf('\tMinimum name shortcut length:\t%i\n', uniqueLength);
    if uniqueLength > shortestLength
      % The shortest possible string to identify all materials is longer than
      % the shortest material name
      warning('MATLAB:ambiguousNames', 'The smallest material name is shorter than the smallest string required for accurate material selection.');
      uniqueLength = shortestLength;
    end
    
    % Set the values of the globalDatabase
    globalDatabase.materials = materials;
    globalDatabase.materialsUniqueLength = uniqueLength;
    GlobalDatabase(globalDatabase);
  end
  
  uniqueLength = globalDatabase.materialsUniqueLength;
end

% File:         Database.m
% Author:       Brycen Wendt (brycen.wendt@inl.gov; wendbryc@isu.edu)
% Date Created: 09/??/2015
%
% Usage:        handle        = Database()
%               spotSize      = <handle>.GetSpotSizeFromMagnification(<mag>)
%               thermalProps  = <handle>.GetThermalProperties(<material>)
% Inputs:       <handle>        Object handle to the database object
%               <mag>           Magnification of the optical lens
%               <material>      String name of material
%               <thermalProps>  Structure of material, k, d, and rho
% Outputs:      spotSize        Size of the focused laser beam
%               handle          Object handle to the database object
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
  handle.GetSpotSizeFromMagnification = @GetSpotSizeFromMagnification;
  handle.GetThermalProperties = @GetThermalProperties;
end

function spotSize = GetSpotSizeFromMagnification(magnification)
% Return the minimal laser spot size as a function of the optical lens
% magnification

  % Do not reinitialze the data if unneeded
  persistent database;
  if isempty(database)
    database = {{'magnification'    'spot size'}...
      {50                 2E-6}...
      {20                 5E-6}...
      {10                 10E-6}...
      {5                  20E-6}};
  end

  % Ensure the input argument is valid
  if ~isnumeric(magnification)
    error('Incorrect input type: %s\nInput must be a number!\n', class(material));
  end

  % Search for the requested value
  found = false;
  m = 2;
  while m < length(database)
    if database{m}{1} == magnification
      found = true;
      spotSize = database{m}{2};
      break;
    else
      m = m + 1;
    end
  end

  % Check search results
  if ~found
    error('Magnification ''%f'' not found in database.\nPlease try again or add it yourself.\n', magnification);
  end
end

function thermalProperties = GetThermalProperties(material)
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
% However, no guarantee is made as to which item will be selected.

  % Do not reinitialize the data if unneeded
  persistent database uniqueChar utilities;
  if isempty(database)
    % Read the data
    [throwaway.values, throwaway.text, database] = xlsread('Database.xlsx', 'Materials');

    % Smallest length by which any material may be uniquely identified
    uniqueChar = 1;

    % Reform to make it easier to work with
    database = cell2struct(database(3:end,1:end), database(2,:), 2);
    disp(database)

    % Get a handle to the utilities
    utilities = Utilities();
  end

  % Run some checks and cast the input argument to lower case
  if ~ischar(material)
    error('Incorrect input type: %s\nInput must be a string!\n', class(material));
  end
  uniqueWarning = (length(material) < uniqueChar);
  if uniqueWarning
    warning('MATLAB:ambiguousSyntax', 'Length of input string smaller that the minimum length required to uniquely identify a material.');
  end
  material = lower(material);

  % Search the database for the requested material
  found = false;
  compareLength = length(material);
  for m = 1:length(database)
    maxLength = min(compareLength, length(database(m).material));
    if strcmp(database(m).material(1:maxLength), material(1:maxLength)) == true
      found = true;
      thermalProperties = database(m);
      thermalProperties.specificHeat = utilities.GetSpecificHeat(thermalProperties);
      break;
    end
  end

  % Check search results
  if ~found
    error('Material ''%s'' not found in database.\nPlease try again or add it yourself.\n', material);
  elseif uniqueWarning
    warning('MATLAB:ambiguousSyntax',...
      'Uniqueness check: %s selected', database{m}{1});
  end
end

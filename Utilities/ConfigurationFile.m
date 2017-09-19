classdef ConfigurationFile < handle
% Manages the contents of a *.ini file
  
  properties (SetAccess = immutable, GetAccess = public)
    fileName; % File name
    original; % Original settings at open
  end
  
  properties (SetAccess = public, GetAccess = public)
    cache; % Runtime settings not to be put in a file
    current; % Current settings
  end
  
  methods (Access = ?ConfigurationFileManager)
    function myself = ConfigurationFile(fileName)
    % Opens the settings file and creates the class
      if ischar(fileName) && exist(fileName, 'file');
        myself.fileName = fileName;
        myself.original = ConfigurationFile.ParseINI(fileName);
        myself.current = myself.original;
      else
        error('''%s'' does not exist!', fileName);
      end
    end
  end
  
  methods (Static)
    function [name, previous] = GenerateName(name, previous)
      name = matlab.lang.makeValidName(name);
      name = matlab.lang.makeUniqueStrings(name, previous, namelengthmax);
      previous = [previous name];
    end
    
    function OutputINI(fileName, settingsStructure)
    % Converts a structure into an ini-type file.
    % Modified from: http://www.mathworks.com/matlabcentral/fileexchange/22079-struct2ini
      % Open file, or create new file, for writing
      iniFile = fopen(fileName, 'w');

      listOfSections = fieldnames(settingsStructure);

      for i = 1:length(listOfSections)
        % Get the section name
        section = char(listOfSections(i));

        % Get the field for the section
        member = settingsStructure.(section);
        % Check if member is a struct or value
        if isstruct(member)
          % We found a section, print the section header
          ConfigurationFile.PrintSection(iniFile, section);

          % Get a list of the section fields and print each one
          listOfFields = fieldnames(member);
          for j = 1:length(listOfFields)
            name = char(listOfFields(j));
            value = settingsStructure.(section).(name);
            ConfigurationFile.PrintKeyValue(iniFile, name, value);
          end
        else
          % This is just a value, so print it as-is
          value = member;
          name = section;
          ConfigurationFile.PrintKeyValue(iniFile, name, value);
        end
      end

      fclose(iniFile);
    end
    
    function settingsStructure = ParseINI(fileName)
    % Parses .ini file and returns a structure with section names and keys as
    % fields.
      % Modified from: http://www.mathworks.com/matlabcentral/fileexchange/45725-ini2struct

      commentFields = cell(0);
      previousFields = cell(0);
      sectionFields = cell(0);
      f = fopen(fileName,'r');
      while ~feof(f)
        s = strtrim(fgetl(f));

        % Check for empty lines
        if isempty(s)
          [field, previousFields] = ConfigurationFile.GenerateName('TCMSpace', previousFields);
          value = '';
        % Check for a section header
        elseif s(1) == '['
          [section, sectionFields] = ConfigurationFile.GenerateName(strtok(s(2:end), ']'), sectionFields);
          settingsStructure.(section) = [];
          previousFields = cell(0);
          continue;
        % Check for a comment
        elseif s(1) == ';' || s(1) == '#'
          [field, commentFields] = ConfigurationFile.GenerateName('TCMComment', commentFields);
          value = s;
        % Process a key-value pair
        else
          % Generate the key-value pair
          [key, value] = strtok(s, '=');
          value = strtrim(value(2:end));

          if isempty(value) || value(1) == ';' || value(1) == '#'
            value = [];
          elseif value(1) == '"'
            value = strtok(value, '"');
          elseif value(1) == ''''
            value = strtok(value, '''');
          elseif isempty(regexp(value, '[^\d\.eE\+\-\s]*', 'once'))
            % The regex expression should filter out everything that may cause
            % undesireable behavior with str2num()
            [tempValue, status] = str2num(value); %#ok<ST2NM>
            if status
              value = tempValue;
            end
          end

          % Generate the field name
          [field, previousFields] = ConfigurationFile.GenerateName(key, previousFields);
        end

        % Check to see if we are in a section
        if exist('section', 'var')
          % Add a field to the current section
          settingsStructure.(section).(field) = value;
        else
          % Add a field to the main structure
          settingsStructure.(field) = value;
        end
      end

      fclose(f);
    end

    function PrintKeyValue(iniFile, name, value)
      % Check for a comment or space fields
      if length(name) >= 10 && strcmp(name(1:10), 'TCMComment')
        % This is a comment
        string = sprintf('%s\r\n', value);
      elseif length(name) >= 8 && strcmp(name(1:8), 'TCMSpace')
        % This is an empty line
        string = sprintf('\r\n');
      else
        % Check for a numeric
        if isnumeric(value)
          if length(value) == 1
            value = Num2Engr(value);
          else
            strings = Num2Engr(value);
            value = '';
            for i = 1:length(strings);
              value = [value, ' ', strings{i}]; %#ok<AGROW>
            end
            value = strtrim(value);
          end
        else
          % Perform some final string modifications
          % Convert the ASCII characters to a literal equivalent
          value = strrep(value, '\', '\\');
        end

        string = sprintf('%s=%s\r\n', name, value);
      end

      % Print the line
      fprintf(iniFile, string);
    end
    
    function PrintSection(iniFile, section)
      fprintf(iniFile, '[%s]\r\n', section);
    end
  end
  
  methods (Access = ?ConfigurationFileManager)
    function delete(myself)
      if ~isequal(myself.original, myself.current)
        fprintf('Modified configuration detected. Changes have been saved to ''%s''\n', myself.fileName);
        ConfigurationFile.OutputINI(myself.fileName, myself.current);
      end
    end
  end
end


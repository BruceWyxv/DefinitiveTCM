function struct = ini2struct(FileName)
% Parses .ini file and returns a structure with section names and keys as
% fields.
%
% Modified from: http://www.mathworks.com/matlabcentral/fileexchange/45725-ini2struct

  commentFields = cell(0);
  previousFields = cell(0);
  sectionFields = cell(0);
  f = fopen(FileName,'r');
  while ~feof(f)
    s = strtrim(fgetl(f));

    % Check for empty lines
    if isempty(s)
      [field, previousFields] = GenerateName('TCMSpace', previousFields);
      value = '';
    % Check for a section header
    elseif s(1) == '['
      [section, sectionFields] = GenerateName(strtok(s(2:end), ']'), sectionFields);
      struct.(section) = [];
      previousFields = cell(0);
      continue;
    % Check for a comment
    elseif s(1) == ';' || s(1) == '#'
      [field, commentFields] = GenerateName('TCMComment', commentFields);
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
      else
        % Assume it is a number
        [tempValue, status] = str2num(value); %#ok<ST2NM>
        if status
          value = tempValue;
        end
      end
      
      % Generate the field name
      [field, previousFields] = GenerateName(key, previousFields);
    end

    % Check to see if we are in a section
    if exist('section', 'var')
      % Add a field to the current section
      struct.(section).(field) = value;
    else
      % Add a field to the main structure
      struct.(field) = value;
    end
  end
  
  fclose(f);
end

function [name, previous] = GenerateName(name, previous)
  name = matlab.lang.makeValidName(name);
  name = matlab.lang.makeUniqueStrings(name, previous, namelengthmax);
  previous = [previous name];
end


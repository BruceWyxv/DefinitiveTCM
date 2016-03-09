function Struct = ini2struct(FileName)
% Parses .ini file and returns a structure with section names and keys as
% fields.
%
% Modified from: http://www.mathworks.com/matlabcentral/fileexchange/45725-ini2struct

  currentComment = '';
  f = fopen(FileName,'r');
  while ~feof(f)
    s = strtrim(fgetl(f));

    % Skip empty lines
    if isempty(s)
      continue;
    end
    
    % Check for a comment
    if s(1)==';' || s(1)=='#'
      currentComment = GenerateName('Comment', currentComment);
      if ~exist('Section', 'var')
        Struct.(currentComment) = s(2:end);
      else
        Struct.(Section).(currentComment) = s(2:end);
      end
      continue;
    end
    
    % Check for a section header
    if s(1)=='['
      Section = GenerateName(strtok(s(2:end), ']'));
      Struct.(Section) = [];
      continue;
    end

    % Generate the key-value pair
    [Key,Val] = strtok(s, '=');
    Val = strtrim(Val(2:end));

    if isempty(Val) || Val(1)==';' || Val(1)=='#'
      Val = [];
    elseif Val(1)=='"'
      Val = strtok(Val, '"');
    elseif Val(1)==''''
      Val = strtok(Val, '''');
    else
      % Assume it is a number
      [val, status] = str2num(Val); %#ok<ST2NM>
      if status
        Val = val;
      end
    end

    % Check to see if we are in a section
    if ~exist('Section', 'var')
      % Add a field to the main structure
      Struct.(GenerateName(Key)) = Val;
    else
      % Add a field to the current section
      Struct.(Section).(GenerateName(Key)) = Val;
    end
  end
  
  fclose(f);
end

function name = GenerateName(name, previous)
  if nargin < 2
    previous = {};
  end
  name = matlab.lang.makeValidName(name);
  name = matlab.lang.makeUniqueStrings(name, previous, namelengthmax);
end


function struct2ini(filename, structure)
% converts a given structure into an ini-file.

% Modified from: http://www.mathworks.com/matlabcentral/fileexchange/22079-struct2ini

  % Open file, or create new file, for writing
  % discard existing contents, if any.
  iniFile = fopen(filename, 'w');

  listOfSections = fieldnames(structure);

  for i = 1:length(listOfSections)
    % Get the section name
    section = char(listOfSections(i));

    % Get the field for the section
    member = structure.(section);
    % Check if member is a struct or value
    if isstruct(member)
      % We found a section, print the section header
      PrintSection(iniFile, section);

      % Get a list of the section fields and print each one
      listOfFields = fieldnames(member);
      for j = 1:length(listOfFields)
        name = char(listOfFields(j));
        value = structure.(section).(name);
        PrintKeyValue(iniFile, name, value);
      end
    else
      % This is just a value, so print it as-is
      value = member;
      name = section;
      PrintKeyValue(iniFile, name, value);
    end
  end

  fclose(iniFile);
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
      value = num2str(value);
    end
    
    string = sprintf('%s=%s\r\n', name, value);
  end
  
  % Print the line
  fprintf(iniFile, string);
end

function PrintSection(iniFile, section)
  fprintf(iniFile, '[%s]\r\n', section);
end

function struct2ini(filename, Structure)
% converts a given structure into an ini-file.

% Modified from: http://www.mathworks.com/matlabcentral/fileexchange/22079-struct2ini

  % Open file, or create new file, for writing
  % discard existing contents, if any.
  iniFile = fopen(filename, 'w');
  line = 1;

  listOfSections = fieldnames(Structure);

  for i = 1:length(listOfSections)
    % Get the section name
    section = char(listOfSections(i));

    % Get the field for the section
    member = Structure.(section);
    if ~isempty(member)
      % Check if member is a struct or value
      if isstruct(member)
        % We found a section, print the section header
        line = printSection(iniFile, line, section);

        % Get a list of the section fields and print each one
        listOfFields = fieldnames(member);
        for j = 1:length(listOfFields)
          name = char(listOfFields(j));
          value = Structure.(section).(name);
          line = printLine(iniFile, line, name, value, true);
        end
      else
        % This is just a value, so print it as-is
        value = member;
        name = section;
        line = printLine(iniFile, line, name, value, false);
      end
    end
  end

  fclose(iniFile);
end

function line = printLine(iniFile, line, name, value, inSection)
  line = line + 1;
  % Check for a comment field
  if length(name) >= 7 && strcmp(name(1:7), 'Comment')
    % This is a comment. Print and return.
    if line > 2 && ~inSection
      fprintf(iniFile, '\r\n');
    end
    fprintf(iniFile, '#%s\r\n', value);
    return;
  end
  
  % Check for a numeric
  if isnumeric(value)
    value = num2str(value);
  end
  
  % Print the line
  fprintf(iniFile, '%s=%s\r\n', name, value);
end

function line = printSection(iniFile, line, sectionName)
  line = line + 1;
  fprintf(iniFile, '\r\n[%s]\r\n', sectionName);
end

function [cleanString, cleanValue] = CleanNumberString(string)
% Processes a string hopefully containing a number, cleans it up, and
% returns a cleansed string in engineering format, as well as the sanitized
% value representation
  if iscell(string)
    string = string{1};
  end
  cleanValue = sscanf(string, '%g', 1);
  cleanString = Num2Engr(cleanValue);
end


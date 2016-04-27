function string = Num2Engr(number)
% Num2Engr converts doubles to a engineering formatted string
%   Num2Engr takes a number and converts it to a string, formatted using
%   engineering notation. A cell array is returned if number is an array of
%   doubles.
  if length(number) == 1
    string = Convert(number);
  else
    string = cell(size(number));

    for i = 1:numel(number)
      string{i} = Convert(number(i));
    end
  end
end


function string = Convert(number)
% Performs the actual conversion
  if number == 0
    string = '0';
  else
    exponent = 3 * floor(log10(number) / 3);
    base = number / (10 ^ exponent);

    if exponent == 0
      string = sprintf('%g', base);
    else
      string = sprintf('%ge%d', base, exponent);
    end
  end
end

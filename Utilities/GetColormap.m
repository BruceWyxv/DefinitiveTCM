function colormap = GetColormap(mapName, steps)
% Gets the color map corresponding the the string
  try
    % Interpret the colomap name as a function (see colormap)
    colormapFunction = str2func(mapName);
    colormap = colormapFunction(steps);
  catch
    % Default to the jet colormap if an error occurs
    colormap = jet(steps);
  end
end

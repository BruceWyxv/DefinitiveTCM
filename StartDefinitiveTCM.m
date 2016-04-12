function StartDefinitiveTCM
% Opens the DefinitiveTCM GUI
  % Get the path of this function and change the path accordingly
  mainPath = fileparts(mfilename('fullpath'));
  oldPath = cd(mainPath);

  % Open the main GUI
  addpath('GUI');
  mainWindow = Main;
  uiwait(mainWindow);

  % Done, change back to the original path
  cd(oldPath)
end


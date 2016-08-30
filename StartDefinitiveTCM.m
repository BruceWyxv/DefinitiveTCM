function StartDefinitiveTCM
% Opens the DefinitiveTCM GUI
  % Get the path of this function and change the directory accordingly
  programDirectory = fileparts(mfilename('fullpath'));
  originalDirectory = cd(programDirectory);
  
    % Create the managers
    ConfigurationFileManager.GetInstance();

    % Ensure that the GUI elements are in path
    oldPath = addpath('Analysis', 'GPIB', 'GUI','Utilities');
    
      % Configure the look and feel of the GUI
      LookAndFeel();
      
      % Start the program and wait until it completes
      mainWindow = Main();
      uiwait(mainWindow);
    
    % Reset the original path
    path(oldPath);

    % Delete the managers
    ConfigurationFileManager.GetInstance().delete();

  % Done, change back to the original directory
  cd(originalDirectory)
end


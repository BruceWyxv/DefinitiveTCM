function StartDefinitiveTCM
% Opens the DefinitiveTCM GUI
  executable = isdeployed;
  
  % Get the path of this function and change the directory accordingly
  programDirectory = fileparts(mfilename('fullpath'));
  originalDirectory = cd(programDirectory);
  fprintf('Program directory: %s\r\n', programDirectory);
  
    % Create the managers
    ConfigurationFileManager.GetInstance();

    if executable
      % Configure the look and feel of the GUI
      LookAndFeel();
    else
      % Ensure that the GUI elements are in path
      oldPath = addpath('Analysis', 'GUI', 'HardwareInterfaces', 'Utilities');
    end
      
    % Start the program and wait until it completes
    mainWindow = Main();
    uiwait(mainWindow);
    
    if ~executable
      % Reset the original path
      path(oldPath);
    end

    % Delete the managers
    ConfigurationFileManager.GetInstance().delete();

  % Done, change back to the original directory
  cd(originalDirectory)
end


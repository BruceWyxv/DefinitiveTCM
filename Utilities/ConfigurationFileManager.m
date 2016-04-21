classdef ConfigurationFileManager < handle
% Manages instances of ConfigurationFile
  
  properties (SetAccess = private, GetAccess = private)
    configurationFiles; % A map of configuration files currently open
  end
  
  methods (Access = private)
    function myself = ConfigurationFileManager()
    % Create an instance of this class
      myself.configurationFiles = containers.Map;
    end
  end
  
  methods (Access = public)
    function configurationFile = GetConfigurationFile(myself, fileName)
    % Returns the ConfigurationFile object for fileName
      % Search the files already opened
      if myself.configurationFiles.isKey(fileName)
        configurationFile = myself.configurationFiles(fileName);
      else
        configurationFile = ConfigurationFile(fileName);
        myself.configurationFiles(fileName) = configurationFile;
      end
    end
  end
  
  methods (Static)
    function myself = GetInstance()
    % Get the instance of this manager class
      persistent instance;
      
      if isempty(instance) || ~isvalid(instance)
        instance = ConfigurationFileManager();
      end
      
      myself = instance;
    end
  end
  
  methods
    function delete(myself)
    % Manually delete the configuration files, forcing a save of current
    % values
      configurationFileSet = myself.configurationFiles.keys();
      
      for i = 1:length(configurationFileSet)
        configurationFile = myself.configurationFiles(configurationFileSet{1});
        delete(configurationFile);
      end
    end
  end
end

